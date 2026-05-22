"""Build the segment-model JSON shape consumed by the claude-time dashboard.

The dashboard's JS contract is defined by `viz/data.js`:

  window.CT_DATA = {
    today: {
      label, iso, projects: [
        {id, alias, path, sessions: [
          {id, start, end, prompts, tools, segs: [
            {kind, start, end, label?}
          ]}
        ]}
      ],
      hour_range: [start, end],
      empty?: bool,
    },
    week: {
      label, days: [...7 strings],
      projects: [
        {id, alias, rollup: [...7 day-totals]}
      ],
    }
  }

This module produces dict-of-dicts in that shape. No I/O — the caller
(the `visualize` subcommand) is responsible for SQLite reads and writing the
emitted dict into the HTML template.

Time semantics in the output:
  - `start` / `end` on sessions and segments are integer
    minutes-from-local-midnight (matches the design's coordinate system).
  - `hour_range` is `[start_hour, end_hour_exclusive]` adapted to the day's
    data, with one-hour padding, clamped to [0, 24], falling back to [6, 23]
    on an empty day.

WP3 (claude-time-visualize-v2): added `build_range_data(start_iso, end_iso, ...)`
as a multi-day aggregator that coordinates per-day work. Range payload shape:

  {
    label, projects (cross-day union, sessions tagged with day_iso),
    meta: {start, end, day_count},
    hour_range_by_day: {iso: [start, end]},
    day_window: [global_start, global_end],
    # For day_count == 1: also includes top-level `iso` and `hour_range`
    # so callers get back-compat day shape from a 1-day range.
  }

`build_day_data` and `build_week_data` are now thin wrappers — they preserve
their pre-WP3 return shapes byte-for-byte (dashboard.jsx + the 22 pre-existing
unit tests keep passing unchanged). The range `meta` field is intentionally
NOT propagated into the day/week wrapper returns — the CLI's `_cmd_visualize`
already injects a flat-level `meta: {snapshot, snapshot_iso}` at
`window.CT_DATA.meta`, and surfacing a second `meta` inside `today` / `week`
would invite key-collision confusion in JS consumers. Range `meta` is only
visible to direct callers of `build_range_data`.
"""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from datetime import date, datetime, time, timedelta
from pathlib import Path

# Make sibling reclassify module importable when imported standalone
# (the `claude-time` CLI already does this, but `viz_data` is also imported
# directly from the test harness).
_HERE = Path(__file__).resolve().parent
if str(_HERE) not in sys.path:
    sys.path.insert(0, str(_HERE))
import reclassify  # noqa: E402


# Segment kinds — match the design's `data.js` vocabulary.
KIND_ACTIVE = "active"
KIND_READING = "reading"
KIND_THINKING = "thinking"
KIND_AWAY = "away"
KIND_SUBAGENT = "subagent"


def _meta_get(row: dict, key: str, default=None):
    """Mirror reclassify._meta_get — pull a key from the JSON-encoded meta field."""
    meta = row.get("meta")
    if not meta:
        return default
    try:
        return json.loads(meta).get(key, default)
    except (json.JSONDecodeError, TypeError):
        return default


def _ts_to_minutes(ts_ms: int, day_start_dt: datetime) -> int:
    """Convert a unix-ms timestamp to integer minutes-from-day-start (local time).

    Clamps to [0, 1440) so a timestamp slightly outside the day window doesn't
    produce out-of-grid coordinates.
    """
    day_start_ms = int(day_start_dt.timestamp() * 1000)
    rel_ms = ts_ms - day_start_ms
    minutes = rel_ms // 60_000
    if minutes < 0:
        return 0
    if minutes > 1440:
        return 1440
    return int(minutes)


def _resolve_alias(cwd: str, project_names: dict[str, list[str]], auto_alias_fn) -> str:
    """Apply the same alias-resolution rules as `claude-time report --by cwd`:
    1. Explicit project_names entry → that name
    2. cwd inside a git repo → basename(repo_root)
    3. Otherwise → MISC_LABEL ("misc")

    `auto_alias_fn` is passed in (rather than imported) so the caller can
    inject a fast in-memory stub during tests.
    """
    for name, paths in project_names.items():
        if cwd in paths:
            return name
    return auto_alias_fn(cwd)


def _split_active_with_subagents(
    burst_start_min: int,
    burst_end_min: int,
    subagent_segs: list[dict],
) -> list[dict]:
    """Given an active burst [start, end] in minutes, emit alternating
    'active' / 'subagent' segments such that subagent runs are interleaved.

    Subagent_segs is a list of {start, end, label} all within the burst.
    Returns segments tiling the burst with no gaps and no overlaps.
    """
    if not subagent_segs:
        return [{"kind": KIND_ACTIVE, "start": burst_start_min, "end": burst_end_min}]
    # Sort and clip subagents to within the burst.
    clipped = []
    for sa in subagent_segs:
        s = max(sa["start"], burst_start_min)
        e = min(sa["end"], burst_end_min)
        if e > s:
            clipped.append({"start": s, "end": e, "label": sa.get("label", "agent")})
    clipped.sort(key=lambda x: x["start"])
    # Walk the burst, emitting active and subagent segments.
    segs: list[dict] = []
    cursor = burst_start_min
    for sa in clipped:
        if sa["start"] > cursor:
            segs.append({"kind": KIND_ACTIVE, "start": cursor, "end": sa["start"]})
        segs.append({"kind": KIND_SUBAGENT, "start": sa["start"], "end": sa["end"], "label": sa["label"]})
        cursor = sa["end"]
    if cursor < burst_end_min:
        segs.append({"kind": KIND_ACTIVE, "start": cursor, "end": burst_end_min})
    return segs


def _bursts_for_session(events: list[dict]) -> list[dict]:
    """Burst windows for one session, delegating to `reclassify.active_bursts`.

    Wrapper kept to preserve the call site below; `active_bursts` is the
    single source of truth (also consumed by `session_active_ms`). The
    "narrow" definition is used: consecutive UPSes overwrite, with earlier
    ones recorded as `interrupts` on the resulting burst.

    Returns the per-session list directly. The caller passes events from
    one session at a time, so we extract that session's bursts from the
    returned dict.
    """
    if not events:
        return []
    bursts_by_sid = reclassify.active_bursts(events)
    # Caller passes one session's events; flatten the single dict entry.
    all_bursts: list[dict] = []
    for sid_bursts in bursts_by_sid.values():
        all_bursts.extend(sid_bursts)
    return all_bursts


def _subagents_for_session(events: list[dict]) -> list[tuple[int, int, str]]:
    """Pair SubagentStart with the next SubagentStop in the same session.

    Returns a list of (start_ts_ms, end_ts_ms, agent_type) tuples.
    """
    sorted_ev = sorted(events, key=lambda r: r.get("ts", 0))
    opens: dict[str, list[dict]] = defaultdict(list)
    pairs: list[tuple[int, int, str]] = []
    for e in sorted_ev:
        ev_kind = e.get("event")
        atype = e.get("agent_type") or "agent"
        if ev_kind == "SubagentStart":
            opens[atype].append(e)
        elif ev_kind == "SubagentStop":
            if opens[atype]:
                start = opens[atype].pop(0)
                pairs.append((start.get("ts", 0), e.get("ts", 0), atype))
    return pairs


def _build_viz_sessions(
    events_in_session: list[dict],
    day_start_dt: datetime,
    gaps: list,
    chars_per_sec: float,
) -> list[dict]:
    """Convert one session_id's events into one or more dashboard "sessions".

    A session_id splits into multiple viz-sessions whenever an 'away' gap
    separates two bursts within it — that's the user-mental-model of
    distinct work blocks.

    Each viz-session has tile-able segments: active (with nested subagents)
    + intra-session reading/thinking gaps between bursts.
    """
    bursts = _bursts_for_session(events_in_session)
    if not bursts:
        return []

    sa_pairs = _subagents_for_session(events_in_session)

    # Index gaps by (start_ts, end_ts) for quick lookup; gaps are emitted by
    # reclassify.gap_buckets per Stop→next-UPS pair, so each gap aligns with
    # the boundary between consecutive bursts.
    gap_by_boundary: dict[tuple[int, int], object] = {
        (g.start_ts, g.end_ts): g for g in gaps
    }

    # One viz-session per session_id — no time-based splitting. The harness
    # preserves session_id across /resume, so an away gap inside a session is
    # "I stepped away and came back," not "this is a new chat." It belongs in
    # one row, rendered with the away segment inline. See
    # SURFACE-2026-05-18 (Phase 3 verify-human spot-check) for the rationale.
    s_start_ts = bursts[0]["start_ts"]
    s_end_ts = bursts[-1]["end_ts"]
    s_start_min = _ts_to_minutes(s_start_ts, day_start_dt)
    s_end_min = _ts_to_minutes(s_end_ts, day_start_dt)

    # Build segments for each burst (with subagent splits) + all gap kinds
    # (reading / thinking / away) as inline segments between bursts.
    segs: list[dict] = []
    interrupts_min: list[int] = []
    for burst_idx, burst in enumerate(bursts):
        ups_ts = burst["start_ts"]
        stop_ts = burst["end_ts"]
        b_start_min = _ts_to_minutes(ups_ts, day_start_dt)
        b_end_min = _ts_to_minutes(stop_ts, day_start_dt)
        # Interrupt UPSes for this burst (superseded by a later UPS).
        for itr_ts in burst.get("interrupts", []):
            interrupts_min.append(_ts_to_minutes(itr_ts, day_start_dt))
        # Subagents that fall within this burst.
        burst_sa = []
        for sa_start, sa_end, sa_label in sa_pairs:
            if sa_start >= ups_ts and sa_end <= stop_ts:
                burst_sa.append({
                    "start": _ts_to_minutes(sa_start, day_start_dt),
                    "end": _ts_to_minutes(sa_end, day_start_dt),
                    "label": sa_label,
                })
        segs.extend(_split_active_with_subagents(b_start_min, b_end_min, burst_sa))

        # Gap to the next burst — emit whatever kind gap_buckets classified
        # it as (reading / thinking / away).
        if burst_idx < len(bursts) - 1:
            next_ups_ts = bursts[burst_idx + 1]["start_ts"]
            g = gap_by_boundary.get((stop_ts, next_ups_ts))
            if g is not None and g.bucket in (KIND_READING, KIND_THINKING, KIND_AWAY):
                segs.append({
                    "kind": g.bucket,
                    "start": _ts_to_minutes(stop_ts, day_start_dt),
                    "end": _ts_to_minutes(next_ups_ts, day_start_dt),
                })

    # Tool-call tally for this viz-session.
    tool_counts: dict[str, int] = defaultdict(int)
    for e in events_in_session:
        if e.get("event") == "PreToolUse" and s_start_ts <= e.get("ts", 0) <= s_end_ts:
            tool = e.get("tool_name") or "unknown"
            tool_counts[tool] += 1

    # Prompt count = UPS events in this viz-session window.
    prompts = sum(1 for e in events_in_session
                  if e.get("event") == "UserPromptSubmit"
                  and s_start_ts <= e.get("ts", 0) <= s_end_ts)

    underlying_sid = events_in_session[0].get("session_id", "unknown") if events_in_session else "unknown"
    return [{
        "id": underlying_sid[:8],
        "start": s_start_min,
        "end": s_end_min,
        "prompts": prompts,
        "tools": dict(tool_counts),
        "segs": segs,
        "interrupts": interrupts_min,
    }]


def _hour_range_for(projects: list[dict], default: tuple[int, int] = (6, 23)) -> list[int]:
    """Adaptive hour-window: derive [min_event_hour - 1, max_event_hour + 1]
    from session boundaries across all projects, clamped to [0, 24].

    Returns [start_hour, end_hour] suitable for the design's hour ruler.
    Falls back to default on empty input.
    """
    has_data = False
    min_min = 24 * 60
    max_min = 0
    for p in projects:
        for s in p["sessions"]:
            has_data = True
            if s["start"] < min_min:
                min_min = s["start"]
            if s["end"] > max_min:
                max_min = s["end"]
    if not has_data:
        return [default[0], default[1]]
    start_hour = max(0, (min_min // 60) - 1)
    end_hour = min(24, ((max_min + 59) // 60) + 1)
    return [start_hour, end_hour]


def build_day_data(
    date_iso: str,
    events: list[dict],
    cfg: dict,
    auto_alias_fn,
) -> dict:
    """Construct the dashboard's `today` payload for a single date.

    Inputs:
      date_iso        — "YYYY-MM-DD" (local-tz day to render)
      events          — pre-filtered events from that day's window (caller
                        owns SQLite filtering); shape is one dict per row
      cfg             — config dict (chars_per_sec, project_names, gap thresholds)
      auto_alias_fn   — function(cwd) -> alias for the git-basename fallback path
                        (passed in to avoid coupling viz_data to subprocess)

    Output shape matches `data.js`'s `today` literal.
    """
    day = date.fromisoformat(date_iso)
    day_start_dt = datetime.combine(day, time.min)

    if not events:
        return {
            "label": day.strftime("%a · %b %d").upper(),
            "iso": date_iso,
            "projects": [],
            "hour_range": [6, 23],
            "empty": True,
        }

    # Compute gaps once for the whole window (reclassify's gap_buckets handles
    # cross-session reattribution internally).
    gaps_all = reclassify.gap_buckets(
        events,
        chars_per_sec=cfg["chars_per_sec"],
        reading_threshold_sec=cfg["reading_threshold_sec"],
        thinking_threshold_sec=cfg["thinking_threshold_sec"],
    )
    gaps_by_sid: dict[str, list] = defaultdict(list)
    for g in gaps_all:
        gaps_by_sid[g.session_id].append(g)

    # Group events by session_id FIRST so burst-pairing always sees the full
    # session's event stream (a session may span multiple cwds when the user
    # `cd`s mid-session, but it remains one logical engagement window).
    # THEN partition the resulting viz-sessions into projects by alias —
    # using the modal cwd of each session as the alias-anchor (the cwd most
    # events in that session occurred in).
    project_names_cfg = cfg.get("project_names", {}) or {}
    events_by_sid: dict[str, list[dict]] = defaultdict(list)
    for e in events:
        sid = e.get("session_id") or "<unknown>"
        events_by_sid[sid].append(e)

    # Map (alias) → {cwd_paths: set, viz_sessions: list[viz-session-dict]}.
    by_alias: dict[str, dict] = defaultdict(lambda: {"cwds": set(), "viz_sessions": []})
    for sid, sid_events in events_by_sid.items():
        # Modal cwd for this session — pick the cwd appearing in the most
        # events. Ties broken alphabetically for determinism.
        cwd_counts: dict[str, int] = defaultdict(int)
        for e in sid_events:
            cwd_counts[e.get("cwd") or "<unknown>"] += 1
        modal_cwd = max(cwd_counts.items(), key=lambda kv: (kv[1], -ord(kv[0][0]) if kv[0] else 0))[0]
        alias = _resolve_alias(modal_cwd, project_names_cfg, auto_alias_fn)
        viz_sess = _build_viz_sessions(
            sid_events,
            day_start_dt,
            gaps_by_sid.get(sid, []),
            cfg["chars_per_sec"],
        )
        if not viz_sess:
            continue
        by_alias[alias]["cwds"].update(cwd_counts.keys())
        by_alias[alias]["viz_sessions"].extend(viz_sess)

    projects_out: list[dict] = []
    for alias, bucket in by_alias.items():
        viz_sessions = bucket["viz_sessions"]
        # Skip projects with no complete bursts on this day.
        if not viz_sessions:
            continue
        viz_sessions.sort(key=lambda s: s["start"])
        # Pick a "primary" cwd for the `path` field — the first one encountered
        # (deterministic via sorted set iteration).
        primary_path = sorted(bucket["cwds"])[0] if bucket["cwds"] else ""
        projects_out.append({
            "id": alias,
            "alias": alias,
            "path": primary_path,
            "sessions": viz_sessions,
        })

    # Sort projects by total active minutes desc (matches `--by` ergonomics).
    def _project_active_min(p: dict) -> int:
        total = 0
        for s in p["sessions"]:
            for seg in s["segs"]:
                if seg["kind"] in (KIND_ACTIVE, KIND_SUBAGENT):
                    total += seg["end"] - seg["start"]
        return total
    projects_out.sort(key=lambda p: (-_project_active_min(p), p["alias"]))

    return {
        "label": day.strftime("%a · %b %d").upper(),
        "iso": date_iso,
        "projects": projects_out,
        "hour_range": _hour_range_for(projects_out),
    }


def build_range_data(
    start_iso: str,
    end_iso: str,
    *,
    events_by_day: dict[str, list[dict]],
    cfg: dict,
    auto_alias_fn,
) -> dict:
    """Construct a segment-model payload over an arbitrary [start, end] window.

    Inputs:
      start_iso, end_iso  — "YYYY-MM-DD" inclusive day bounds (end >= start)
      events_by_day       — dict mapping "YYYY-MM-DD" → list of that day's events.
                            Days missing from the dict are treated as empty.
      cfg, auto_alias_fn  — same semantics as `build_day_data`

    Returns:
      {
        label,
        projects: [{id, alias, path, sessions: [...with day_iso tag]}],
        meta: {start, end, day_count},
        hour_range_by_day: {iso: [start_hour, end_hour]},
        day_window: [global_start_hour, global_end_hour],
        # For day_count == 1: also `iso` and `hour_range` for back-compat with
        # the day shape — `build_day_data` is a thin wrapper that returns this
        # unchanged.
      }

    Per-day work delegates to `build_day_data`'s body (via the internal
    `_build_day_payload` helper). Cross-day project aggregation unions sessions
    from the same alias across days, tagging each session with its `day_iso`
    so multi-day renderers can place it on the correct row.
    """
    start = date.fromisoformat(start_iso)
    end = date.fromisoformat(end_iso)
    if end < start:
        raise ValueError(f"end_iso {end_iso} precedes start_iso {start_iso}")
    day_count = (end - start).days + 1
    days_iso = [(start + timedelta(days=i)).isoformat() for i in range(day_count)]

    # Per-day payloads — reuse `build_day_data`'s body for each day in range.
    per_day_payloads: dict[str, dict] = {}
    for day_iso in days_iso:
        day_events = events_by_day.get(day_iso, [])
        per_day_payloads[day_iso] = build_day_data(day_iso, day_events, cfg, auto_alias_fn)

    # Cross-day project aggregation: union sessions by alias, tagging each
    # with the day_iso it belongs to so multi-day renderers can place it.
    by_alias: dict[str, dict] = defaultdict(lambda: {"path": "", "sessions": []})
    for day_iso, payload in per_day_payloads.items():
        for proj in payload["projects"]:
            bucket = by_alias[proj["alias"]]
            if not bucket["path"]:
                bucket["path"] = proj.get("path", "")
            for s in proj["sessions"]:
                tagged = dict(s)
                tagged["day_iso"] = day_iso
                bucket["sessions"].append(tagged)

    projects_out: list[dict] = []
    for alias, bucket in by_alias.items():
        sessions = bucket["sessions"]
        sessions.sort(key=lambda s: (s["day_iso"], s["start"]))
        projects_out.append({
            "id": alias,
            "alias": alias,
            "path": bucket["path"],
            "sessions": sessions,
        })

    # Sort cross-day projects by total active+subagent minutes desc.
    def _project_active_min(p: dict) -> int:
        total = 0
        for s in p["sessions"]:
            for seg in s["segs"]:
                if seg["kind"] in (KIND_ACTIVE, KIND_SUBAGENT):
                    total += seg["end"] - seg["start"]
        return total
    projects_out.sort(key=lambda p: (-_project_active_min(p), p["alias"]))

    # Per-day hour ranges (read from each day payload — already adaptive,
    # default [6, 23] on empty days).
    hour_range_by_day = {
        day_iso: per_day_payloads[day_iso]["hour_range"]
        for day_iso in days_iso
    }
    # Global day_window — union of all per-day adaptive ranges.
    starts = [hr[0] for hr in hour_range_by_day.values()]
    ends = [hr[1] for hr in hour_range_by_day.values()]
    day_window = [min(starts), max(ends)] if starts else [6, 23]

    label = (
        per_day_payloads[start_iso]["label"]
        if day_count == 1
        else f"{start.strftime('%b %d').upper()} — {end.strftime('%b %d').upper()}"
    )

    out: dict = {
        "label": label,
        "projects": projects_out,
        "meta": {"start": start_iso, "end": end_iso, "day_count": day_count},
        "hour_range_by_day": hour_range_by_day,
        "day_window": day_window,
    }
    # Back-compat: for day_count == 1, surface flat `iso` and `hour_range` so
    # the same payload can be consumed as a day shape if needed.
    if day_count == 1:
        out["iso"] = start_iso
        out["hour_range"] = hour_range_by_day[start_iso]
        # Propagate `empty` flag from the single day's payload.
        if per_day_payloads[start_iso].get("empty"):
            out["empty"] = True
    return out


def build_week_data(
    week_monday_iso: str,
    events_by_day: dict[str, list[dict]],
    cfg: dict,
    auto_alias_fn,
) -> dict:
    """Construct the dashboard's `week` rollup payload.

    Inputs:
      week_monday_iso  — "YYYY-MM-DD" for the Monday anchoring the ISO week
      events_by_day    — dict mapping "YYYY-MM-DD" → list of that day's events
      cfg, auto_alias_fn — same semantics as `build_day_data`

    For each project (resolved across the whole week), produce a 7-entry
    rollup with per-day {active, reading, thinking, away, subagent, prompts}
    minute totals.

    Implementation (WP3): thin wrapper over `build_range_data` — coordinates
    the 7-day window, then re-shapes the per-day payloads into the rollup
    shape this function has always returned. Output shape unchanged from pre-WP3.
    """
    monday = date.fromisoformat(week_monday_iso)
    sunday = monday + timedelta(days=6)
    days_iso = [(monday + timedelta(days=i)).isoformat() for i in range(7)]
    days_labels = [(monday + timedelta(days=i)).strftime("%a %d").upper() for i in range(7)]

    # alias → 7-entry rollup, initialised with zeros.
    def _empty_rollup() -> list[dict]:
        return [{"active": 0, "reading": 0, "thinking": 0, "away": 0,
                 "subagent": 0, "prompts": 0} for _ in range(7)]

    rollups: dict[str, list[dict]] = defaultdict(_empty_rollup)

    # Re-use build_range_data per-day payloads (it calls build_day_data
    # internally and tags sessions with day_iso). Then re-aggregate into the
    # week rollup shape.
    range_payload = build_range_data(
        days_iso[0], days_iso[-1],
        events_by_day=events_by_day, cfg=cfg, auto_alias_fn=auto_alias_fn,
    )
    day_iso_to_index = {iso: i for i, iso in enumerate(days_iso)}
    for proj in range_payload["projects"]:
        for s in proj["sessions"]:
            i = day_iso_to_index.get(s["day_iso"])
            if i is None:
                continue
            cell = rollups[proj["alias"]][i]
            cell["prompts"] += s["prompts"]
            for seg in s["segs"]:
                dur = seg["end"] - seg["start"]
                if seg["kind"] == KIND_ACTIVE:
                    cell["active"] += dur
                elif seg["kind"] == KIND_READING:
                    cell["reading"] += dur
                elif seg["kind"] == KIND_THINKING:
                    cell["thinking"] += dur
                elif seg["kind"] == KIND_SUBAGENT:
                    cell["subagent"] += dur
                elif seg["kind"] == KIND_AWAY:
                    cell["away"] += dur

    # Build the projects list ordered by total active+subagent across the week.
    projects_out = []
    for alias, rollup in rollups.items():
        total = sum(c["active"] + c["subagent"] for c in rollup)
        projects_out.append({
            "id": alias,
            "alias": alias,
            "rollup": rollup,
            "_total": total,
        })
    projects_out.sort(key=lambda p: (-p["_total"], p["alias"]))
    for p in projects_out:
        del p["_total"]

    return {
        "label": f"WEEK {monday.isocalendar()[1]} · {monday.strftime('%b %d').upper()} — {sunday.strftime('%b %d').upper()}",
        "days": days_labels,
        "projects": projects_out,
    }
