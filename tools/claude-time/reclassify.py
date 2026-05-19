"""Pure reclassification functions for claude-time.

Operates on lists of event-dicts (one dict per row in the events table).
No DB I/O — the CLI script (claude-time) handles SQLite reads and feeds
parsed rows to these functions. This keeps the module unit-testable
without fixtures.

Spec algorithm (locked):
  For each (Stop, next UserPromptSubmit) pair in a session:
    gap_wall_clock = next.ts - stop.ts                       (ms)
    typing_debit   = next.prompt_length_chars / chars_per_sec * 1000  (ms)
    cross_session  = sum of typing_debits for UserPromptSubmit
                     events in OTHER sessions where
                     stop.ts <= e.ts <= next.ts              (ms)
    effective_gap  = max(0, gap_wall_clock - typing_debit - cross_session)
    bucket:
      effective_gap <= reading_threshold        → "reading"
      reading < effective_gap <= thinking_thresh → "thinking"
      effective_gap > thinking_threshold        → "away"
"""

from __future__ import annotations

import json
from collections import defaultdict
from dataclasses import dataclass


@dataclass
class Gap:
    """One Stop → next UserPromptSubmit interval within a session."""

    session_id: str
    start_ts: int  # ms
    end_ts: int  # ms
    wall_clock_ms: int
    typing_debit_ms: int
    cross_session_ms: int
    effective_ms: int
    bucket: str  # "reading" | "thinking" | "away"


def _meta_get(row, key, default=None):
    """Extract a JSON-encoded meta field from an event row."""
    meta = row.get("meta")
    if not meta:
        return default
    try:
        return json.loads(meta).get(key, default)
    except (json.JSONDecodeError, TypeError):
        return default


def typing_debit_ms(prompt_length_chars: int, chars_per_sec: float) -> int:
    """How many ms the user spent typing a prompt of N chars at CPS speed.

    Returns 0 for zero-length prompts. Rounds to nearest ms.
    """
    if prompt_length_chars <= 0 or chars_per_sec <= 0:
        return 0
    return int(round((prompt_length_chars / chars_per_sec) * 1000))


def cross_session_overlap_ms(
    gap_start_ms: int,
    gap_end_ms: int,
    own_session_id: str,
    all_events: list[dict],
    chars_per_sec: float,
) -> int:
    """Sum the typing-debit-equivalent of OTHER sessions' prompts that
    fired during this session's gap.

    Point-event subtraction per spec: each UserPromptSubmit in another
    session occurring within [gap_start_ms, gap_end_ms] contributes its
    own typing_debit_ms to the overlap.
    """
    total = 0
    for e in all_events:
        if e.get("event") != "UserPromptSubmit":
            continue
        if e.get("session_id") == own_session_id:
            continue
        ts = e.get("ts", 0)
        if ts < gap_start_ms or ts > gap_end_ms:
            continue
        length = _meta_get(e, "prompt_length_chars", 0) or 0
        total += typing_debit_ms(length, chars_per_sec)
    return total


def gap_buckets(
    events: list[dict],
    *,
    chars_per_sec: float = 6.0,
    reading_threshold_sec: int = 120,
    thinking_threshold_sec: int = 300,
) -> list[Gap]:
    """Compute the list of gaps (Stop → next UserPromptSubmit pairs)
    across all sessions, with bucketing and cross-session reattribution.

    Returns a flat list of Gap objects. Caller can group by session_id.
    """
    reading_ms = reading_threshold_sec * 1000
    thinking_ms = thinking_threshold_sec * 1000

    # Group events by session for the per-session Stop → UPS pairing.
    by_session: dict[str, list[dict]] = defaultdict(list)
    for e in events:
        sid = e.get("session_id")
        if sid:
            by_session[sid].append(e)

    # Sort each session's events by ts (defensive — caller may not have).
    for sid_events in by_session.values():
        sid_events.sort(key=lambda r: r.get("ts", 0))

    gaps: list[Gap] = []
    for sid, sid_events in by_session.items():
        # Pair each Stop with the next UserPromptSubmit in the same session.
        for i, ev in enumerate(sid_events):
            if ev.get("event") != "Stop":
                continue
            stop_ts = ev.get("ts", 0)
            next_ups = None
            for later in sid_events[i + 1 :]:
                if later.get("event") == "UserPromptSubmit":
                    next_ups = later
                    break
            if next_ups is None:
                continue  # session ended without a follow-up prompt
            ups_ts = next_ups.get("ts", 0)
            wall = max(0, ups_ts - stop_ts)
            length = _meta_get(next_ups, "prompt_length_chars", 0) or 0
            debit = typing_debit_ms(length, chars_per_sec)
            cross = cross_session_overlap_ms(
                stop_ts, ups_ts, sid, events, chars_per_sec
            )
            effective = max(0, wall - debit - cross)
            if effective <= reading_ms:
                bucket = "reading"
            elif effective <= thinking_ms:
                bucket = "thinking"
            else:
                bucket = "away"
            gaps.append(
                Gap(
                    session_id=sid,
                    start_ts=stop_ts,
                    end_ts=ups_ts,
                    wall_clock_ms=wall,
                    typing_debit_ms=debit,
                    cross_session_ms=cross,
                    effective_ms=effective,
                    bucket=bucket,
                )
            )
    return gaps


def tool_durations_ms(events: list[dict]) -> dict[str, int]:
    """Sum per-tool wall-clock durations across all sessions.

    Pairs PreToolUse with the next PostToolUse / PostToolUseFailure that
    shares the same tool_use_id. Skips Pre events without a matching Post
    (tool still running or session ended mid-tool).

    Returns dict {tool_name: total_ms}.
    """
    totals: dict[str, int] = defaultdict(int)

    # Build a lookup of Post events by tool_use_id for quick pairing.
    post_by_tuid: dict[str, dict] = {}
    for e in events:
        if e.get("event") in ("PostToolUse", "PostToolUseFailure"):
            tuid = _meta_get(e, "tool_use_id")
            if tuid:
                post_by_tuid[tuid] = e

    for e in events:
        if e.get("event") != "PreToolUse":
            continue
        tuid = _meta_get(e, "tool_use_id")
        if not tuid:
            continue
        post = post_by_tuid.get(tuid)
        if not post:
            continue
        tool = e.get("tool_name") or "<unknown>"
        duration = max(0, post.get("ts", 0) - e.get("ts", 0))
        totals[tool] += duration

    return dict(totals)


def subagent_durations_ms(events: list[dict]) -> dict[str, int]:
    """Sum per-agent-type subagent wall-clock durations across all sessions.

    Pairs SubagentStart with the next SubagentStop in the same session,
    matching by agent_type (no tool_use_id-style key is documented for
    subagent events in the spec; we use agent_type + chronological pairing
    within a session as the join key).
    """
    totals: dict[str, int] = defaultdict(int)

    by_session: dict[str, list[dict]] = defaultdict(list)
    for e in events:
        if e.get("event") in ("SubagentStart", "SubagentStop"):
            sid = e.get("session_id")
            if sid:
                by_session[sid].append(e)
    for sid_events in by_session.values():
        sid_events.sort(key=lambda r: r.get("ts", 0))

    for sid_events in by_session.values():
        open_starts: dict[str, list[dict]] = defaultdict(list)
        for e in sid_events:
            atype = e.get("agent_type") or "<unknown>"
            if e.get("event") == "SubagentStart":
                open_starts[atype].append(e)
            elif e.get("event") == "SubagentStop":
                if open_starts[atype]:
                    start = open_starts[atype].pop(0)
                    duration = max(0, e.get("ts", 0) - start.get("ts", 0))
                    totals[atype] += duration

    return dict(totals)


def active_bursts(events: list[dict]) -> dict[str, list[dict]]:
    """Per-session list of active-burst windows.

    A burst is one (UserPromptSubmit, next Stop) window. When multiple UPS
    events arrive before a Stop closes the open burst (mid-turn interrupts),
    the LATEST UPS is the burst's anchor — earlier UPSes are recorded as
    `interrupts` on the burst and do NOT open new bursts. This is the
    "narrow" definition of engaged-with-agent time: the user's last
    keypress before the agent's Stop is the engagement anchor.

    Returns:
        {session_id: [{start_ts, end_ts, interrupts}, ...]}
        where `interrupts` is a list of UPS timestamps that were superseded
        by a later UPS within the same open burst.
    """
    by_session: dict[str, list[dict]] = defaultdict(list)
    for e in events:
        sid = e.get("session_id")
        if sid:
            by_session[sid].append(e)
    for sid_events in by_session.values():
        sid_events.sort(key=lambda r: r.get("ts", 0))

    out: dict[str, list[dict]] = {}
    for sid, sid_events in by_session.items():
        bursts: list[dict] = []
        last_ups_ts: int | None = None
        interrupts: list[int] = []
        for e in sid_events:
            evt = e.get("event")
            ts = e.get("ts", 0)
            if evt == "UserPromptSubmit":
                if last_ups_ts is not None:
                    # Mid-turn UPS — record the previous one as an interrupt,
                    # advance the anchor to the new one.
                    interrupts.append(last_ups_ts)
                last_ups_ts = ts
            elif evt == "Stop" and last_ups_ts is not None:
                bursts.append({
                    "start_ts": last_ups_ts,
                    "end_ts": ts,
                    "interrupts": interrupts,
                })
                last_ups_ts = None
                interrupts = []
        out[sid] = bursts
    return out


def session_active_ms(events: list[dict]) -> dict[str, int]:
    """Per-session sum of (last_UPS → next Stop) windows.

    "Active in this session" per the spec (acceptance #5). Distinct from
    gap analysis: this is the sum of "while the user was engaged" windows.
    Uses the narrow definition (consecutive UPSes overwrite — only the
    last one before a Stop anchors the burst). See `active_bursts` for the
    shared burst-pairing logic both this and viz_data consume.
    """
    totals: dict[str, int] = {}
    for sid, bursts in active_bursts(events).items():
        totals[sid] = sum(max(0, b["end_ts"] - b["start_ts"]) for b in bursts)
    return totals
