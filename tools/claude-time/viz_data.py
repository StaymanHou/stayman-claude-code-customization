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


# Segment kinds enumerated for the deltas computation. `total_active_subagent`
# is synthesised (sum of active + subagent) because the headline-stats card
# (WP10) wants it as a primary number — pre-computing it here saves the
# consumer from duplicating the sum logic.
_DELTA_KINDS = (KIND_ACTIVE, KIND_READING, KIND_THINKING, KIND_AWAY, KIND_SUBAGENT)
_DELTA_SYNTH_TOTAL = "total_active_subagent"


def _project_kind_minutes(project: dict) -> dict[str, int]:
    """Sum per-segment-kind minutes across all sessions of one project.

    Returns a dict with one entry per kind in _DELTA_KINDS plus the synthesised
    `total_active_subagent`. Missing kinds default to 0.
    """
    totals: dict[str, int] = {k: 0 for k in _DELTA_KINDS}
    for s in project.get("sessions", []):
        for seg in s.get("segs", []):
            kind = seg.get("kind")
            if kind in totals:
                totals[kind] += seg["end"] - seg["start"]
    totals[_DELTA_SYNTH_TOTAL] = totals[KIND_ACTIVE] + totals[KIND_SUBAGENT]
    return totals


def _compute_deltas(a_payload: dict, b_payload: dict) -> dict[str, dict[str, dict]]:
    """Join A and B by alias, compute per-segment-kind {abs_min, rel_pct} deltas.

    For each (alias, kind):
      abs_min = b_min - a_min  (positive = B has more)
      rel_pct = (b_min - a_min) / a_min * 100  if a_min > 0  else None
        - a_min == 0 with b_min > 0 → None (no baseline; consumer renders as N/A)
        - a_min == 0 with b_min == 0 → None (no change to express)
        - a_min > 0 with b_min == 0 → -100.0 (full regression)

    Aliases present in only one side: deltas include them with the other side's
    minutes treated as 0.
    """
    a_by_alias: dict[str, dict] = {p["alias"]: p for p in a_payload.get("projects", [])}
    b_by_alias: dict[str, dict] = {p["alias"]: p for p in b_payload.get("projects", [])}
    all_aliases = set(a_by_alias) | set(b_by_alias)

    deltas: dict[str, dict[str, dict]] = {}
    for alias in sorted(all_aliases):
        a_proj = a_by_alias.get(alias, {"sessions": []})
        b_proj = b_by_alias.get(alias, {"sessions": []})
        a_mins = _project_kind_minutes(a_proj)
        b_mins = _project_kind_minutes(b_proj)
        per_kind: dict[str, dict] = {}
        for kind in (*_DELTA_KINDS, _DELTA_SYNTH_TOTAL):
            a_m = a_mins[kind]
            b_m = b_mins[kind]
            abs_min = b_m - a_m
            rel_pct = (abs_min / a_m * 100) if a_m > 0 else None
            per_kind[kind] = {"abs_min": abs_min, "rel_pct": rel_pct}
        deltas[alias] = per_kind
    return deltas


def build_comparison_data(
    start_a_iso: str,
    end_a_iso: str,
    start_b_iso: str,
    end_b_iso: str,
    *,
    events_by_day_a: dict[str, list[dict]],
    events_by_day_b: dict[str, list[dict]],
    cfg: dict,
    auto_alias_fn,
) -> dict:
    """Build a side-by-side payload for two windows with pre-computed deltas.

    Coordinator pattern: two `build_range_data` calls (A and B) + a deltas
    computation joining the two payloads by alias. The data layer is
    policy-free — both `abs_min` (raw difference) and `rel_pct` (percentage
    change) are emitted; the UI decides which lens to render.

    Inputs:
      start_a_iso, end_a_iso  — A-window inclusive day bounds
      start_b_iso, end_b_iso  — B-window inclusive day bounds (can be any
                                length relative to A — comparing a 1-day B to
                                a 7-day A is valid and intended for
                                day-vs-trailing-window comparisons)
      events_by_day_a / _b    — separate per-window event dicts; the helpers
                                in this module partition a single
                                `events_by_day` into these two sub-dicts
      cfg, auto_alias_fn      — same semantics as `build_range_data` / `build_day_data`

    Returns:
      {
        a: <range_payload for A>,
        b: <range_payload for B>,
        deltas: {alias: {kind: {abs_min, rel_pct}}}  # kind ∈ {active, reading,
                                                     # thinking, away, subagent,
                                                     # total_active_subagent}
        meta: {a_start, a_end, b_start, b_end, a_day_count, b_day_count},
      }

    `rel_pct` is `None` when `a_min == 0` for that (alias, kind) — the consumer
    renders this as N/A rather than showing a misleading percentage.
    """
    a_payload = build_range_data(
        start_a_iso, end_a_iso,
        events_by_day=events_by_day_a, cfg=cfg, auto_alias_fn=auto_alias_fn,
    )
    b_payload = build_range_data(
        start_b_iso, end_b_iso,
        events_by_day=events_by_day_b, cfg=cfg, auto_alias_fn=auto_alias_fn,
    )
    deltas = _compute_deltas(a_payload, b_payload)
    return {
        "a": a_payload,
        "b": b_payload,
        "deltas": deltas,
        "meta": {
            "a_start": start_a_iso,
            "a_end": end_a_iso,
            "b_start": start_b_iso,
            "b_end": end_b_iso,
            "a_day_count": a_payload["meta"]["day_count"],
            "b_day_count": b_payload["meta"]["day_count"],
        },
    }


def _partition_events_by_day(
    events_by_day: dict[str, list[dict]],
    start_iso: str,
    end_iso: str,
) -> dict[str, list[dict]]:
    """Extract the subset of `events_by_day` falling within [start_iso, end_iso].

    Days inside the window but missing from `events_by_day` are not synthesised
    (build_range_data treats missing days as empty already).
    """
    start = date.fromisoformat(start_iso)
    end = date.fromisoformat(end_iso)
    out: dict[str, list[dict]] = {}
    for iso, evts in events_by_day.items():
        d = date.fromisoformat(iso)
        if start <= d <= end:
            out[iso] = evts
    return out


def compare_week_over_week(
    this_monday_iso: str,
    *,
    events_by_day: dict[str, list[dict]],
    cfg: dict,
    auto_alias_fn,
) -> dict:
    """Compare last week vs this week — both anchored to ISO-Monday weeks.

    A = [this_monday - 7 days, this_monday - 1 day]  (the prior 7 days)
    B = [this_monday, this_monday + 6 days]          (the current 7 days)

    Single `events_by_day` is partitioned internally; the caller doesn't need
    to know the window boundaries.
    """
    this_monday = date.fromisoformat(this_monday_iso)
    prev_monday = this_monday - timedelta(days=7)
    prev_sunday = this_monday - timedelta(days=1)
    this_sunday = this_monday + timedelta(days=6)

    a_start_iso = prev_monday.isoformat()
    a_end_iso = prev_sunday.isoformat()
    b_start_iso = this_monday.isoformat()
    b_end_iso = this_sunday.isoformat()

    return build_comparison_data(
        a_start_iso, a_end_iso, b_start_iso, b_end_iso,
        events_by_day_a=_partition_events_by_day(events_by_day, a_start_iso, a_end_iso),
        events_by_day_b=_partition_events_by_day(events_by_day, b_start_iso, b_end_iso),
        cfg=cfg, auto_alias_fn=auto_alias_fn,
    )


def compare_day_vs_trailing_window(
    target_day_iso: str,
    *,
    window_days: int = 7,
    events_by_day: dict[str, list[dict]],
    cfg: dict,
    auto_alias_fn,
) -> dict:
    """Compare one day against a trailing window (baseline).

    A = [target - window_days, target - 1 day]  (the baseline window)
    B = [target, target]                        (the single target day)

    Note on naming: WBS task 4.4 called this `compare_day_vs_median`, but
    the data layer just emits the baseline window's per-day payloads — the
    actual median-vs-mean-vs-sum aggregation is a UI-side rendering choice
    deferred to WP10 (headline-stats card). Renamed at build time to be
    truthful about what this helper produces.
    """
    if window_days < 1:
        raise ValueError(f"window_days must be >= 1, got {window_days}")
    target = date.fromisoformat(target_day_iso)
    a_start = target - timedelta(days=window_days)
    a_end = target - timedelta(days=1)

    a_start_iso = a_start.isoformat()
    a_end_iso = a_end.isoformat()
    b_start_iso = target_day_iso
    b_end_iso = target_day_iso

    return build_comparison_data(
        a_start_iso, a_end_iso, b_start_iso, b_end_iso,
        events_by_day_a=_partition_events_by_day(events_by_day, a_start_iso, a_end_iso),
        events_by_day_b=_partition_events_by_day(events_by_day, b_start_iso, b_end_iso),
        cfg=cfg, auto_alias_fn=auto_alias_fn,
    )


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


# ============================================================================
# WP10: Metrics aggregator — wall-clock vs effort-time over trailing 7 days.
#
# Public entry point: `build_metrics(events, window_start_dt, window_end_dt)`.
# Emits a metric tree consumed by HeadlineCard + MetricsPanel in dashboard.jsx.
# Reference implementation: /tmp/usage_analysis_v3.py (user-recreated 2026-05-24).
#
# Terminology:
#   wall-clock = real elapsed time. Overlapping activities collapse via merge.
#   effort-time = plain sum of all durations. 2 parallel 1h activities = 2h.
#   ×multiplier = effort-time ÷ wall-clock.
#
# Engaged session = burst-spanning windows with away-classified gaps EXCLUDED.
# The existing `_build_viz_sessions` includes away-gaps inside its session
# window (sensible for rendering — keeps the session visually intact); the
# metrics layer needs the engaged definition to avoid inflating "session
# duration" with away time. Per Q5 of the spec: engaged definition lives in
# the metrics aggregator only; `_build_viz_sessions` is unchanged.
# ============================================================================


def _merge_intervals(intervals: list[tuple[int, int]]) -> list[tuple[int, int]]:
    """Merge overlapping (start, end) intervals into a sorted disjoint list.

    Sort by start; for each subsequent interval, if it overlaps or touches
    the rightmost merged interval, extend its end; otherwise append.
    Drops zero-width / inverted intervals (end <= start).
    """
    if not intervals:
        return []
    sorted_iv = sorted(intervals)
    merged: list[list[int]] = []
    for s, e in sorted_iv:
        if e <= s:
            continue
        if merged and s <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], e)
        else:
            merged.append([s, e])
    return [(s, e) for s, e in merged]


def _sum_intervals(intervals: list[tuple[int, int]]) -> int:
    """Plain sum of (end - start) over each interval. No merge."""
    return sum(e - s for s, e in intervals)


def _build_engaged_intervals(
    bursts_by_sid: dict[str, list[dict]],
    gaps_by_sid_keyed: dict[str, dict[tuple[int, int], object]],
) -> tuple[list[tuple[int, int]], dict[str, int]]:
    """Per-session engaged intervals: bursts joined by non-away gaps, split by
    away gaps.

    For each session's burst sequence, walk pairwise: if the gap between
    burst[i].end and burst[i+1].start is classified "away", finalize the
    current engaged interval and start a new one at burst[i+1]. Otherwise,
    extend the current interval through burst[i+1].

    Returns:
        (all_intervals, per_session_effort_ms)
        all_intervals: flat list of (start_ms, end_ms) across all sessions
                       (un-merged — caller merges for wall-clock or sums for
                       effort-time).
        per_session_effort_ms: {session_id: effort_ms} sum of intervals per
                               session (used by `engaged_session.session_count`
                               and reconciliation tests).

    Reference: /tmp/usage_analysis_v3.py lines 84–107.
    """
    all_intervals: list[tuple[int, int]] = []
    per_session_ms: dict[str, int] = {}

    for sid, bursts in bursts_by_sid.items():
        if not bursts:
            continue
        sess_gaps = gaps_by_sid_keyed.get(sid, {})
        cur_start = bursts[0]["start_ts"]
        cur_end = bursts[0]["end_ts"]
        iv_for_sess: list[tuple[int, int]] = []
        for i in range(len(bursts) - 1):
            this_end = bursts[i]["end_ts"]
            next_start = bursts[i + 1]["start_ts"]
            g = sess_gaps.get((this_end, next_start))
            if g is not None and getattr(g, "bucket", None) == "away":
                iv_for_sess.append((cur_start, cur_end))
                cur_start = next_start
                cur_end = bursts[i + 1]["end_ts"]
            else:
                cur_end = bursts[i + 1]["end_ts"]
        iv_for_sess.append((cur_start, cur_end))
        per_session_ms[sid] = _sum_intervals(iv_for_sess)
        all_intervals.extend(iv_for_sess)

    return all_intervals, per_session_ms


def _multiplier(wallclock_ms: int, effort_ms: int) -> float:
    """Effort ÷ wall-clock guarded against div-by-zero."""
    return (effort_ms / wallclock_ms) if wallclock_ms > 0 else 0.0


def _empty_metrics(window_start_iso: str, window_end_iso: str,
                   day_count: int) -> dict:
    """Fully-shaped zero tree for empty-events guard."""
    return {
        "window": {"start": window_start_iso, "end": window_end_iso,
                   "day_count": day_count},
        "engaged_session": {"wallclock_ms": 0, "effort_ms": 0,
                            "multiplier": 0.0, "session_count": 0},
        "ai_agent": {
            "wallclock_ms": 0, "effort_ms": 0, "multiplier": 0.0,
            "subagent": {"wallclock_ms": 0, "effort_ms": 0, "multiplier": 0.0},
        },
        "tool_call": {
            "wallclock_ms": 0, "effort_ms": 0, "multiplier": 0.0,
            "top": [],
        },
        "human": {
            "wallclock_ms": 0, "effort_ms": 0, "multiplier": 1.0,
            "typing_ms": 0, "reading_ms": 0, "thinking_ms": 0,
        },
        "concurrency": [
            {"k": 1, "wallclock_ms": 0, "effort_ms": 0},
            {"k": 2, "wallclock_ms": 0, "effort_ms": 0},
            {"k": 3, "wallclock_ms": 0, "effort_ms": 0},
            {"k": 4, "wallclock_ms": 0, "effort_ms": 0, "is_plus": True},
        ],
        "blocking": {
            "human_blocking_agent_ms": 0,
            "agent_blocking_human_ms": 0,
        },
    }


def build_metrics(events: list[dict],
                  window_start_dt: datetime | None,
                  window_end_dt: datetime | None) -> dict:
    """Aggregate wall-clock vs effort-time metrics over a window of events.

    Args:
        events: chronologically-sorted event-dicts within [window_start_dt,
                window_end_dt]. Caller is responsible for filtering events
                to the window — `build_metrics` does not re-filter.
        window_start_dt / window_end_dt: window endpoints used only for the
                output's `window` sub-key. Pass `None` when events is empty
                (e.g., placeholder emit) — the empty-events guard fires
                first and uses ISO "" for window dates.

    Returns metric tree per the spec/plan; see `_empty_metrics` for shape.
    """
    if not events:
        if window_start_dt is None or window_end_dt is None:
            return _empty_metrics("", "", 0)
        return _empty_metrics(window_start_dt.date().isoformat(),
                              window_end_dt.date().isoformat(),
                              (window_end_dt.date() - window_start_dt.date()).days + 1)

    window_start_iso = window_start_dt.date().isoformat()
    window_end_iso = window_end_dt.date().isoformat()
    day_count = (window_end_dt.date() - window_start_dt.date()).days + 1

    # ---- Bursts and gaps ----
    bursts_by_sid = reclassify.active_bursts(events)
    gaps = reclassify.gap_buckets(events)
    # Key gaps by (start_ts, end_ts) within each session so engaged-interval
    # construction can look them up by burst boundaries.
    gaps_by_sid_keyed: dict[str, dict[tuple[int, int], object]] = defaultdict(dict)
    for g in gaps:
        gaps_by_sid_keyed[g.session_id][(g.start_ts, g.end_ts)] = g

    # ---- Engaged sessions ----
    engaged_intervals, per_session_engaged_ms = _build_engaged_intervals(
        bursts_by_sid, gaps_by_sid_keyed,
    )
    engaged_wallclock = _sum_intervals(_merge_intervals(engaged_intervals))
    engaged_effort = sum(per_session_engaged_ms.values())
    session_count = sum(1 for v in per_session_engaged_ms.values() if v > 0)

    # ---- AI agent (bursts) ----
    burst_intervals: list[tuple[int, int]] = []
    for bursts in bursts_by_sid.values():
        for b in bursts:
            if b["end_ts"] > b["start_ts"]:
                burst_intervals.append((b["start_ts"], b["end_ts"]))
    agent_wallclock = _sum_intervals(_merge_intervals(burst_intervals))
    agent_effort = _sum_intervals(burst_intervals)

    # ---- Subagent (intervals, not just durations) ----
    sa_intervals = reclassify.subagent_intervals(events)
    subagent_wallclock = _sum_intervals(_merge_intervals(sa_intervals))
    subagent_effort = _sum_intervals(sa_intervals)

    # ---- Tool calls ----
    tool_iv_by_name = reclassify.tool_intervals(events)
    all_tool_iv: list[tuple[int, int]] = []
    for iv_list in tool_iv_by_name.values():
        all_tool_iv.extend(iv_list)
    tool_wallclock = _sum_intervals(_merge_intervals(all_tool_iv))
    tool_effort = _sum_intervals(all_tool_iv)

    # Top 5 tools by effort-time desc.
    per_tool_summary: list[dict] = []
    for tool, iv_list in tool_iv_by_name.items():
        eff = _sum_intervals(iv_list)
        wc = _sum_intervals(_merge_intervals(iv_list))
        per_tool_summary.append({
            "name": tool,
            "wallclock_ms": wc,
            "effort_ms": eff,
            "multiplier": _multiplier(wc, eff),
        })
    per_tool_summary.sort(key=lambda x: -x["effort_ms"])
    top_tools = per_tool_summary[:5]

    # ---- Human activity (one-brain — no parallelism) ----
    reading_ms = sum(g.effective_ms for g in gaps if g.bucket == "reading")
    thinking_ms = sum(g.effective_ms for g in gaps if g.bucket == "thinking")
    typing_ms = sum(g.typing_debit_ms for g in gaps)
    human_total = reading_ms + thinking_ms + typing_ms

    # ---- Concurrency stratification (engaged sessions sweep-line) ----
    sweep: list[tuple[int, int]] = []
    for s, e in engaged_intervals:
        sweep.append((s, +1))
        sweep.append((e, -1))
    sweep.sort()
    by_concurrency_ms: dict[int, int] = defaultdict(int)
    active_count = 0
    prev_ts: int | None = None
    for ts, delta in sweep:
        if prev_ts is not None and active_count > 0:
            by_concurrency_ms[active_count] += ts - prev_ts
        active_count += delta
        prev_ts = ts

    c1 = by_concurrency_ms.get(1, 0)
    c2 = by_concurrency_ms.get(2, 0)
    c3 = by_concurrency_ms.get(3, 0)
    c4plus = sum(v for k, v in by_concurrency_ms.items() if k >= 4)
    concurrency = [
        {"k": 1, "wallclock_ms": c1, "effort_ms": c1},
        {"k": 2, "wallclock_ms": c2, "effort_ms": c2 * 2},
        {"k": 3, "wallclock_ms": c3, "effort_ms": c3 * 3},
        {"k": 4, "wallclock_ms": c4plus, "effort_ms": c4plus * 4, "is_plus": True},
    ]

    # ---- Blocking metrics ----
    human_blocking_agent_ms = reading_ms + thinking_ms
    agent_blocking_human_ms = agent_wallclock

    return {
        "window": {
            "start": window_start_iso,
            "end": window_end_iso,
            "day_count": day_count,
        },
        "engaged_session": {
            "wallclock_ms": engaged_wallclock,
            "effort_ms": engaged_effort,
            "multiplier": _multiplier(engaged_wallclock, engaged_effort),
            "session_count": session_count,
        },
        "ai_agent": {
            "wallclock_ms": agent_wallclock,
            "effort_ms": agent_effort,
            "multiplier": _multiplier(agent_wallclock, agent_effort),
            "subagent": {
                "wallclock_ms": subagent_wallclock,
                "effort_ms": subagent_effort,
                "multiplier": _multiplier(subagent_wallclock, subagent_effort),
            },
        },
        "tool_call": {
            "wallclock_ms": tool_wallclock,
            "effort_ms": tool_effort,
            "multiplier": _multiplier(tool_wallclock, tool_effort),
            "top": top_tools,
        },
        "human": {
            "wallclock_ms": human_total,
            "effort_ms": human_total,
            "multiplier": 1.0,
            "typing_ms": typing_ms,
            "reading_ms": reading_ms,
            "thinking_ms": thinking_ms,
        },
        "concurrency": concurrency,
        "blocking": {
            "human_blocking_agent_ms": human_blocking_agent_ms,
            "agent_blocking_human_ms": agent_blocking_human_ms,
        },
    }
