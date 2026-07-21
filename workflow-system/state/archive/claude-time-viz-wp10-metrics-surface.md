---
workflow: feature
state: ship (complete)
drive_mode: autopilot
ship_commit: fc4fe2a
created: 2026-05-24
cycle: claude-time-visualize-v2
wbs_wp: WP10
bundled_surfaces:
  - SURFACE-2026-05-24-CLAUDE-TIME-VIZ-AGGREGATE-METRICS-PANEL
---

# Feature: Metrics surface — headline card + expandable aggregate metrics panel

**Workflow:** feature
**State:** spec
**Created:** 2026-05-24
**Entry:** spec (complex feature — new aggregator, new component, view-mode interactions, 6 metric trees + reconciliation properties, est. ≥4h agent work)

## Problem Statement

[Updated 2026-05-24 — back-loop from P2.verify-human.2: problem unchanged, UX delta only. User wants window/date-range visible without expanding the panel.]

Problem statement unchanged — the rejection at P2.verify-human.2 is a placement preference (window context should be on the collapsed card, not buried in the expanded panel header), not a shift in what the feature solves.

`claude-time visualize` renders the segment-model (timeline view) but exposes no aggregate quantitative summaries. Users (incl. the project owner) repeatedly ask "how much time did I spend / how much agent activity / how much parallelism / where is time going" — none of which the timeline answers at a glance. Worse, the existing `_build_viz_sessions` includes away-gaps inside its session window, inflating "session duration" to implausible totals (116h in a 168h week) — so even a naive "sum sessions" overlay would mislead. This feature adds a metrics surface that:

1. Surfaces three above-the-fold headline numbers ("how much real work today" without scrolling).
2. Expands to a six-metric aggregate panel with wall-clock / effort-time / parallelism-multiplier columns — exposing the gap between elapsed time and effort time, which is the load-bearing insight for the user's "where is time going" question.

The metrics layer introduces an **engaged-session** definition (burst-spanning windows with away-gaps excluded) used **only** for the metrics layer; the existing timeline rendering (`_build_viz_sessions`) is unchanged. The metrics window is **always a trailing 7 days including today**, independent of the dashboard view-mode below — this stabilizes parallelism multipliers and matches the user's primary mental model ("the past week of my work").

## User Stories

- **As the dashboard owner, I want** three above-the-fold numbers (active session wall-clock, human activity wall-clock, AI effort hours) **so that** I can answer "how much real work this past week" in <2 seconds without scrolling or interacting.
- **As the dashboard owner, I want** to expand the headline card into a full metrics panel **so that** I can see the wall-clock vs effort-time gap (parallelism multiplier) for each metric and identify which axes have hidden parallelism.
- **As the dashboard owner, I want** "engaged session duration" to exclude away-gaps **so that** the number reflects actual work and not "117h logged this week" inflation.
- **As the dashboard owner, I want** top-5 tools by effort-time **so that** I can see which tool kinds are driving parallelism (e.g., WebSearch 1.80× vs Bash 1.04×).
- **As the dashboard owner, I want** concurrency stratification (1 / 2 / 3 / 4+ engaged sessions) **so that** I can see whether parallelism is real or theoretical (4+ concurrency was 46 sec/week — kills the "optimize for high parallelism" intuition).
- **As the dashboard owner, I want** the metrics window to be the trailing 7 days regardless of the view-mode below **so that** the numbers don't shrink to noise when I click into a single Day view.

## Acceptance Criteria

The feature is done when:

1. **Headline card** renders above the timeline in all view modes (Day / Week / Month / Custom) with three numbers:
   - **Active session wall-clock** (engaged-session wall-clock over the trailing 7 days)
   - **Human activity wall-clock** (typing + reading + thinking, summed; one-brain so wall-clock ≡ effort-time)
   - **AI effort hours** (agent burst effort-time over the trailing 7 days — single source, no tool/subagent double-counting)
2. **Card collapsed by default** — clicking a chevron expands to the full MetricsPanel.
3. **Headline numbers are a projection of the MetricsPanel data tree** — same aggregator call, headline reads the relevant cells. Reconciliation test asserts headline number == panel cell.
4. **MetricsPanel (expanded)** shows six metric trees as three-column rows (Wall-clock | Effort-time | ×Multiplier):
   - Engaged session duration
   - AI agent activity (bursts)
     - sub-row: subagent time
   - Tool call duration
     - sub-table: top 5 tools by effort-time
   - Human active duration (wall-clock column only; effort-time = wall-clock for symmetry; ×1.00 by construction)
     - sub-rows: typing, reading, thinking
   - Concurrency stratification (4 rows: 1 / 2 / 3 / 4+ engaged sessions; wall-clock per row, effort-time = wall-clock × concurrency-count)
   - Blocking metrics (2 rows, wall-clock only): human-blocking-agent (reading+thinking), agent-blocking-human (burst wall-clock)
5. **Reconciliation invariants hold** (tested in unit tests):
   - Concurrency rows sum (wall-clock col) ≡ engaged-session wall-clock
   - Concurrency rows sum (effort-time col, with 4+ row as lower-bound `×4`) ≤ engaged-session effort-time
   - Subagent ≤ AI agent activity (subagent is a subset)
6. **Engaged-session definition is implemented in the new aggregator only** — `_build_viz_sessions` (timeline renderer) is unchanged. Existing tests pass byte-for-byte.
7. **Trailing 7-day window** is computed independently of the dashboard view's window. Day / Week / Month / Custom all show the same metrics surface.
8. **Hash state** — collapsed/expanded state persists in URL hash per the claude-time URL-hash convention (key reservation TBD at plan time; candidate: `metrics=expanded`).
9. **Filter chips (WP9)** apply to the metrics surface? **DEFERRED to plan-time decision** — the SURFACE doesn't address this; if including, the headline numbers update on filter chip toggle. See Open Questions.
10. **Test posture at ship:**
    - New unittest cases in `test_viz_data.py` covering `build_metrics()` (engaged-session interval construction with away-gap exclusion, concurrency sweep, reconciliation properties, empty-window guard).
    - New `test_visualize_cli.sh` source-shape pins (HeadlineCard / MetricsPanel component presence, three headline numbers, six metric rows).
    - New behavioral pins in `test_visualize_interactive.js` (collapsed default, click-to-expand, headline cells match panel cells).
    - Full claude-time suite stays at 100% PASS (currently 264/0).

## Out of Scope

- **Per-project breakdown** ("same metrics sliced by cwd alias") — explicitly declined by user; defer to follow-up WP. WP13 covers per-project pills on row labels separately.
- **View-adaptive deltas** ("today vs trailing-7-median", "this week vs last week") — original WP10 spec included these; the trailing-7-day-fixed window from Q3 removes the need for view-adaptive deltas. Comparison-axis work moves to WP11.
- **Sparkline mini-chart** — original WP10 included; deferred. The MetricsPanel's wall-clock vs effort-time table is the new primary "trend" surface; sparkline can land in WP11 or a follow-up if useful.
- **Refactoring `_build_viz_sessions`** — engaged definition is metrics-layer-only per Q5. Timeline-renderer behavior unchanged.
- **Tooltips explaining each metric inline** — initial scope is panel header legend ("Wall-clock = elapsed; Effort-time = sum of durations; ×Multiplier = effort ÷ wall-clock"). Per-row tooltips deferred unless they emerge as load-bearing during verify-human.
- **Alternative metric windows** (e.g., trailing 30 days, all-time). Trailing 7 days is the only window in v1 of this feature.

## Technical Constraints

- **No 3rd-party API dependency** — pure local SQLite data, existing `reclassify` primitives, React component.
- **Reuse `reclassify.active_bursts`, `reclassify.gap_buckets`** for burst and gap data — already in use by the existing data layer. Tool intervals computed from PreToolUse → PostToolUse pairing (same logic as `/tmp/usage_analysis_v3.py` lines 120–145).
- **Subagent intervals** computed from SubagentStart / SubagentStop pairing per session_id + agent_type (v3 script lines 152–176). New helper likely needed in `reclassify.py` or co-located in `viz_data.py`.
- **Interval-merge helper** (`merge_intervals`, `sum_intervals`) — small pure functions, can be co-located in `viz_data.py`. The v3 script lines 44–60 are the canonical reference.
- **Engaged-session interval construction** — v3 script lines 84–107 is the canonical reference (bursts within session, away-gaps split the engaged interval, non-away gaps keep it joined).
- **CLAUDE.md "Claude-time visualize URL-hash state" convention** applies for collapsed/expanded persistence (semicolon separator, default-elision when collapsed).
- **Single source of truth for the aggregator** — `build_metrics(events, trailing_7_start_dt, trailing_7_end_dt) -> dict` returns the full metric tree; both HeadlineCard and MetricsPanel read from it. The Python aggregator emits the full tree on the data payload; React reads `window.CT_DATA.metrics`.
- **Trailing 7 days is computed at emit time** by Python, NOT at React render time. This avoids client-server clock drift and keeps the metric data consistent with the snapshot model.
- **Existing claude-time suite (264/0) must stay green** — engaged-session is a new code path, not a modification of an existing one. No byte-pin regressions in `tests/check-structure.sh`.
- **Reference script:** `/tmp/usage_analysis_v3.py` (user-recreated 2026-05-24, 263 lines) — implementation reference for interval-merge, engaged-session construction, concurrency sweep, blocking metrics. Not in repo; this WIP file embeds the load-bearing definitions in the constraints + acceptance criteria so the script's absence doesn't block plan/build.

## Plan-time Decisions Locked at Spec

(Captured from the 2026-05-24 spec dialog — see session transcript for rationale.)

| ID | Decision | Locked at spec |
|---|---|---|
| Q1 | Headline = three numbers, projection of MetricsPanel aggregator | Yes |
| Q2 | Collapsible card above timeline (default collapsed) | Yes |
| Q3 | Window = trailing 7 days (today included), view-mode-independent | Yes |
| Q4 | Wall-clock + Effort-time + ×Multiplier always shown (3 cols) | Yes |
| Q5 | Engaged definition in new aggregator only; `_build_viz_sessions` unchanged | Yes |
| Q6 | Reference script `/tmp/usage_analysis_v3.py` recreated; treat as implementation reference | Yes |
| Q7 | Per-project drill out of scope | Yes |
| Q8 | Top-5 tools sub-table included | Yes |
| Q3-prime | Headline #3 = `agent_effort_ms` only (no tool/subagent double-counting) | Yes |

## Plan-time Open Questions — RESOLVED at plan

| Q | Resolution | Why |
|---|---|---|
| WP9 filter-chip interaction | **Filter-aware** — kind + project chips both apply to headline + panel | WP9's established contract is that filter state is the canonical "what counts as work" axis; metrics that ignore filters would diverge from the timeline below. Implementation: aggregator runs unfiltered (emits full metric tree); JS reads `window.CT_DATA.metrics` + applies `filterKinds` / `filterProjects` at render time. Trailing-7-day window and filter axes are orthogonal. |
| Hash key name | `metrics=expanded`; default-elision when collapsed | Matches semantic naming of other keys (`view=month`, `filters=active,subagent` — value carries meaning, not just truthiness). Future: if a 3rd state lands ("pinned-open"), no migration needed. |
| Empty-window behavior | Three zeros + caption `No tracked activity in the past 7 days` | Honest signal for fresh-install / week-off case. Caption is also surfaced when filter state hides everything (`(filtered — adjust chips to see data)` variant). |

## Plan-time Discoveries (architectural)

- **`reclassify.py` already has the four primitives the aggregator needs:** `active_bursts()` (returns per-session burst windows with `start_ts`/`end_ts`/`interrupts`), `gap_buckets()` (returns `Gap` objects with `start_ts`/`end_ts`/`bucket`/`effective_ms`/`typing_debit_ms`/`session_id`), `tool_durations_ms()` (returns `{tool_name: effort_ms}` — effort-time only, NOT intervals), `subagent_durations_ms()` (returns `{agent_type: effort_ms}` — effort-time only, NOT intervals). **Gap:** tool + subagent effort-time-only helpers don't expose intervals, so we cannot compute wall-clock (merged) for tools or subagents using existing primitives. **Decision:** add two sibling helpers in `reclassify.py` that return intervals — `tool_intervals(events) -> dict[str, list[tuple[int, int]]]` and `subagent_intervals(events) -> list[tuple[int, int]]`. Existing effort-time helpers stay (they're already in use); intervals helpers are net-new. This is a clean additive change.
- **`build_metrics(events, start_dt, end_dt)` lives in `viz_data.py`** alongside `build_range_data` / `build_comparison_data` (precedent: pure-aggregator coordinator functions live in viz_data.py; reclassify.py owns primitives).
- **Wiring into `_cmd_visualize`:** the trailing-7-day window is **always today's date + the prior 6 days**, computed at emit time (snapshot semantics — matches the existing `meta.snapshot` discipline). Emitted on the payload as a flat `window.CT_DATA.metrics` key (sibling of `today` / `week` / `months` / `meta`). View-mode-independent: same `metrics` payload regardless of `--demo` / `--week` / `--month` / `--range` / `--date`. **Demo path:** the demo bundled `viz/data.js` is single-day; the metrics aggregator on the demo path runs over the demo's events (which yields small but non-zero numbers — honest demo signal).
- **`SubagentStart`/`SubagentStop` pairing key**: the v3 reference script uses `(session_id, agent_type)` chronological pairing — same as `reclassify.subagent_durations_ms()` already does. New `subagent_intervals` helper mirrors that pairing logic exactly.
- **Interval-merge helper location:** small pure functions (`_merge_intervals`, `_sum_intervals`) co-located in `viz_data.py` as module-private. Not promoted to `reclassify.py` because they're aggregator-shape-specific (list of (start, end) tuples in ms).
- **Engaged-session interval construction** lives in `build_metrics`. The v3 script's lines 84–107 is the canonical reference; we transcribe + add a `_build_engaged_intervals(bursts_by_sid, gaps_by_sid_keyed)` private helper inside `viz_data.py` for testability.
- **CLAUDE.md URL-hash table** — adds one row: `WP10 (metrics) | metrics | expanded | metrics is collapsed (default)`. Phase 2 task.
- **No `viz_render.py` interactive-dashboard transforms needed** beyond template variable wiring — the metric components are pure React in `viz/dashboard.jsx`. The hash dispatcher in `_interactive_dashboard` extends to add a 5th branch for `metrics=expanded` (sibling of view / month / range / filters).
- **Three zeros + caption empty-window state** is the React component's job — aggregator always emits a fully-shaped tree, even when all metrics are zero. Caption is JSX-side conditional on `metrics.engaged_session.wallclock_ms === 0 && metrics.human.wallclock_ms === 0 && metrics.ai_agent.effort_ms === 0`.
- **Container note:** the `claude-time-test` container is already running per session-resume context. Phase 1 unit tests + Phase 2 behavioral tests both leverage the existing test harness — no new container setup.

## Work Tree

- [x] Phase 1: Aggregator + emit wiring (Python-only, no UI)  <!-- status: complete; build_metrics aggregator + 38 unittests + 9 CLI source-shape pins (7 emit + 2 codify integration-boundary) + 4 verify-human leaves PASS; full claude-time suite 311/0 -->
  **Observable outcomes:**
  - CLI: `tools/claude-time/claude-time visualize --demo` exits 0, emitted HTML contains a `window.CT_DATA.metrics = {...}` object with all 6 top-level metric keys (`engaged_session`, `ai_agent`, `tool_call`, `human`, `concurrency`, `blocking`) + `window` sub-key with `start`/`end`/`day_count: 7`.
  - CLI: `python -c "import sys; sys.path.insert(0, 'tools/claude-time'); from viz_data import build_metrics; r = build_metrics([], None, None); assert set(r.keys()) >= {'engaged_session', 'ai_agent', 'tool_call', 'human', 'concurrency', 'blocking', 'window'}; print('ok')"` prints `ok` (empty-events guard returns fully-shaped zeros).
  - CLI: Full claude-time suite passes 100% (currently 264/0 — Phase 1 expects net +N unittest additions, zero regressions). `test_viz_data.py BuildMetricsTests` includes reconciliation invariants (concurrency wall-clock sum ≡ engaged wall-clock; subagent ≤ ai_agent; ×multiplier = effort ÷ wall-clock for the 3 metrics that have multipliers).
  - HTTP: N/A (Python-only phase).
  - Browser: N/A (Phase 1 doesn't render anything; Phase 2 owns UI).
  - [x] P1.1 Add `tool_intervals(events) -> dict[str, list[tuple[int, int]]]` and `subagent_intervals(events) -> list[tuple[int, int]]` to `reclassify.py`. Mirror the pairing logic of the existing `tool_durations_ms` and `subagent_durations_ms` exactly — same join keys, same skip-unpaired discipline. Add unittest cases in `test_reclassify.py` for both helpers (empty, single pair, unpaired Pre, overlapping pairs across sessions). **Done:** 13 new unittests (7 tool_intervals + 6 subagent_intervals) all PASS.  <!-- status: complete -->
  - [x] P1.2 Add `_merge_intervals(intervals: list[tuple[int, int]]) -> list[tuple[int, int]]` and `_sum_intervals(intervals) -> int` as module-private helpers in `viz_data.py`. Transcribe from `/tmp/usage_analysis_v3.py` lines 44–60 (sort by start, merge overlapping by extending rightmost end). Unittest with `BuildMetricsTests.test_merge_intervals_*` (empty, single, non-overlapping, overlapping, touching-at-boundary, zero-width). **Done:** 7 helper unittests PASS.  <!-- status: complete -->
  - [x] P1.3 Add `_build_engaged_intervals(bursts_by_sid, gaps_by_sid_keyed) -> list[tuple[int, int]]` private helper in `viz_data.py`. Transcribe from v3 script lines 84–107: per-session bursts walk, away-gap splits the engaged window, non-away gaps keep it joined. Returns flat list of (start_ms, end_ms) intervals across all sessions (un-merged — caller decides whether to merge for wall-clock or sum for effort-time). **Done:** returns `(all_intervals, per_session_effort_ms)` tuple so callers can also compute session_count. Verified via `test_two_burst_session_away_gap_splits_engaged` + `test_two_burst_session_reading_gap_keeps_engaged_joined`.  <!-- status: complete -->
  - [ ] P1.4 Add `build_metrics(events: list[dict], window_start_dt: datetime, window_end_dt: datetime) -> dict` to `viz_data.py`. Returns the 7-key metric tree shape:
    ```python
    {
      "window": {"start": "<ISO>", "end": "<ISO>", "day_count": 7},
      "engaged_session": {"wallclock_ms": int, "effort_ms": int, "multiplier": float, "session_count": int},
      "ai_agent": {
        "wallclock_ms": int, "effort_ms": int, "multiplier": float,
        "subagent": {"wallclock_ms": int, "effort_ms": int, "multiplier": float},
      },
      "tool_call": {
        "wallclock_ms": int, "effort_ms": int, "multiplier": float,
        "top": [{"name": str, "wallclock_ms": int, "effort_ms": int, "multiplier": float}, ...],  # top 5 by effort_ms desc
      },
      "human": {
        "wallclock_ms": int,    # typing + reading + thinking
        "effort_ms": int,       # equals wallclock_ms (single-human; no parallelism)
        "multiplier": 1.0,      # always 1.0 by construction
        "typing_ms": int, "reading_ms": int, "thinking_ms": int,
      },
      "concurrency": [
        {"k": 1, "wallclock_ms": int, "effort_ms": int},   # effort = wallclock × k
        {"k": 2, "wallclock_ms": int, "effort_ms": int},
        {"k": 3, "wallclock_ms": int, "effort_ms": int},
        {"k": 4, "wallclock_ms": int, "effort_ms": int, "is_plus": True},  # 4+ bucket; effort lower-bound = wallclock × 4
      ],
      "blocking": {
        "human_blocking_agent_ms": int,  # reading_ms + thinking_ms (wall-clock; one-human)
        "agent_blocking_human_ms": int,  # ai_agent.wallclock_ms (merged bursts)
      },
    }
    ```
    Empty-events guard: if `events == []`, return fully-shaped zeros (all `*_ms = 0`, `multiplier = 0` for the three metrics that have it, `top = []`, `concurrency = [{k:1..4, wallclock_ms:0, effort_ms:0}]`). Multiplier = `effort / wallclock` when `wallclock > 0` else `0.0`. Critical reconciliation invariants tested in unit tests:
    - `sum(c["wallclock_ms"] for c in concurrency) == engaged_session["wallclock_ms"]` (the sweep partitions engaged wall-clock by concurrency-level)
    - `subagent["wallclock_ms"] <= ai_agent["wallclock_ms"]` (subagent intervals are a subset of agent bursts)
    - `subagent["effort_ms"] <= ai_agent["effort_ms"]`
    - `human["multiplier"] == 1.0` exactly
    - `concurrency[i]["effort_ms"] == concurrency[i]["wallclock_ms"] * (i + 1)` for i in 0..3 (last is lower-bound when `is_plus`)
    - `blocking["agent_blocking_human_ms"] == ai_agent["wallclock_ms"]`
    - `len(tool_call["top"]) <= 5`
  **Done:** `build_metrics()` implemented per spec; 18 `BuildMetricsTests` PASS + 7 `BuildMetricsReconciliationTests` PASS = 25/25. All 7 reconciliation invariants verified over a 7-day multi-session fixture.  <!-- status: complete -->
  - [x] P1.5 Wire `build_metrics` into `_cmd_visualize` in `claude-time` CLI: compute `metrics_window_end = snapshot_dt`, `metrics_window_start = snapshot_dt - timedelta(days=6)` (today inclusive = 7 days). Load events across the 7-day window via `_load_window_events` (per-day, same pattern as the existing month payload loader). Concatenate all events into a single chronologically-sorted list and call `build_metrics(events, metrics_window_start, metrics_window_end)`. Attach result as `data["metrics"]`. **Demo path:** emits an empty-shape metrics tree (not over the demo's JS events — extracting `viz/data.js` JS into event-dicts is non-trivial; left as Phase 2 enrichment or follow-up). HeadlineCard will render the empty-window caption on demo. This is a planned simplification, captured in [SURFACED-2026-05-24] below. **Plan-level downstream-contract-impacts** — additive top-level `metrics` key, no existing consumer reads it; but **two existing assertions surfaced** (WP5b-2 + WP5b-4) that used `! grep -q '"day_count"'` as a single-day-shape proxy — fixed in P1.7 by scoping to "exactly ONE `day_count` hit (the metrics one)". This is exactly the plan-level downstream-contract-impacts pass surfacing the issue at the changing phase. **Done.**  <!-- status: complete -->
  - [x] P1.6 Unittest additions: 18 `BuildMetricsTests` + 7 `BuildMetricsReconciliationTests` + 13 reclassify interval-helper tests = 38 new unittests. All PASS. Suite went 75 → 113 unittest, 28 → 28 interactive (untouched), 29 → 29 cli (untouched).  <!-- status: complete -->
  - [x] P1.7 `test_visualize_cli.sh`: 7 source-shape pins (WP10-P1-1 through -7): metrics top-level key present, 7 metric sub-keys present, window.day_count == 7, is_plus:true present, human.multiplier==1.0, ai_agent.subagent nested object present, tool_call.top list present. Plus contract-impact mitigation: scoped WP5b-2 + WP5b-4 to use `grep -c day_count == 1` instead of `! grep day_count` (the metrics tree always emits its own day_count=7). visualize_cli suite: 132 → 139 PASS (+7 WP10-P1; 2 fixed in-place).  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; 38 scoped unit tests + 7 WP10-P1 source-shape pins PASS; py_compile clean; import smoke clean -->
  - [x] verify-self  <!-- status: complete; CLI outcomes verified live in container: --demo exits 0 with all 7 metric keys + day_count=7; empty-events guard returns fully-shaped tree; full suite 309/0 PASS (113 unittest + 29 cli + 139 visualize_cli + 28 interactive); integration-boundary rule satisfied (consuming surface = `claude-time visualize` CLI command, cited in O1). No BLOCKING or COSMETIC failures. -->
  - [x] verify-human  <!-- status: complete; all 4 leaves PASS via agent-run mechanical verification (user delegated with "try do these yourself. And skip the rest verification if any"); cross-check vs /tmp/usage_analysis_v3.py matched on every metric (22 numeric assertions); window=2026-05-18..2026-05-24 day_count=7 correct; demo path emits empty tree as planned; no-regression proven by suite (28 interactive tests PASS) -->
  - [x] verify-codify  <!-- status: complete; +2 codify pins for integration-boundary (WP10-P1 codify-8: real-DB path emits metrics with seeded burst+tool values; codify-9: trailing-7-day window math). Suite 311/0 PASS (was 309). No test triage needed. -->
    - [x] P1.verify-human.1 (real-DB cross-check vs v3): **PASS** — agent ran `python3 /tmp/usage_analysis_v3.py` and `claude-time visualize` real-DB emit, compared every metric. 22 numeric assertions matched exactly: engaged_session wall=33h22m / effort=49h34m / ×1.49 / session_count=47; ai_agent wall=18h30m / effort=27h55m / ×1.51; subagent wall=2h15m / ×1.09; tool wall=5h48m / ×1.11; typing=2h19m / reading=2h49m / thinking=6h07m; concurrency k=1/2/3/4+ = 21h48m / 6h57m / 4h35m / 46s; top-5 tools (Bash, Agent, playwright_wait_for, WebSearch, playwright_evaluate) in identical order with identical values; blocking metrics agent=18h30m / human=8h56m. Floats matched to 4 decimal places.  <!-- status: complete -->
    - [x] P1.verify-human.2 (--demo path emits empty metrics tree, planned simplification): **PASS** — verified in verify-self (`O2 PASS: empty-events guard returns fully-shaped tree`); planned simplification per [SURFACED-2026-05-24] discovery is the expected behavior.  <!-- status: complete -->
    - [x] P1.verify-human.3 (no regressions in Day/Week/Month/Custom views): **PASS** — Phase 1 only added a sibling `metrics` payload; no view-rendering code touched. Proof by test suite: 28 interactive behavioral tests covering Day/Week/Month/Custom all PASS in verify-self (full suite 309/0).  <!-- status: complete -->
    - [x] P1.verify-human.4 (consuming-surface CLI invocation captured, integration-boundary rule): **PASS** — agent ran the CLI invocation; output: `{"start": "2026-05-18", "end": "2026-05-24", "day_count": 7}`. Today is 2026-05-24, 6 days back is 2026-05-18, day_count is 7 (inclusive). Trailing-7-day window correct.  <!-- status: complete -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [x] Phase 2: HeadlineCard + MetricsPanel UI (React, hash persistence, filter-state)  <!-- status: complete; P2.1–P2.7 impl + 15 source-shape pins + 9 behavioral pins; verify-auto/self/human/codify all PASS; 1 back-loop (P2.verify-human.2 cosmetic, fixed in-phase). Full claude-time suite 335/0 + structure 122/0 PASS. -->
  **Observable outcomes:**
  - Browser: Page loads (`tools/claude-time/claude-time visualize --demo`); above the timeline + below the toolbar, a `[data-metrics-card]` element is rendered. Initial state collapsed; visible children are three primary metric tiles (`[data-metric-tile=engaged-session]`, `[data-metric-tile=human]`, `[data-metric-tile=ai-effort]`) plus a `[data-metric-expand-toggle]` chevron button.
  - Browser: Clicking `[data-metric-expand-toggle]` expands the card; the expanded panel `[data-metrics-panel]` becomes visible containing 6 metric sections (`[data-metric-section=engaged-session]`, `[data-metric-section=ai-agent]`, `[data-metric-section=tool-call]`, `[data-metric-section=human]`, `[data-metric-section=concurrency]`, `[data-metric-section=blocking]`). URL hash updates to include `metrics=expanded`.
  - Browser: Clicking `[data-metric-expand-toggle]` again collapses the panel; hash drops the `metrics` key (default-elision).
  - Browser: Reloading the page with `#metrics=expanded` in the URL → panel is expanded on initial render (no flicker; hash-restore on init).
  - Browser: Toggling kind filter chips (WP9) updates the headline numbers + panel cells — e.g., toggling off `subagent` reduces `[data-metric-tile=ai-effort]`'s value by the subagent contribution.
  - Browser: No JS errors in console on page load (`mcp__playwright__browser_console_messages` returns empty error array).
  - Browser: Empty-window edge case — Day view with `--date 1970-01-01` (no events in trailing 7 days from that date — though real-DB events make this hard; alternative: temporarily seed an empty window or use --demo with stripped metrics): three zeros visible, caption `No tracked activity in the past 7 days` present.
  - HTTP: N/A (static file emit).
  - CLI: `tools/claude-time/claude-time visualize --demo` exits 0 (regression check).
  - CLI: Full claude-time suite 100% PASS (currently 264/0 + Phase 1 additions; Phase 2 expects ~10 net source-shape pins + ~6 net behavioral pins).
  - [x] P2.1 `HeadlineCard` component shipped in `viz/dashboard.jsx`. Three tiles (engaged-session/human/ai-effort) with mono-font values + uppercase labels matching SummaryStrip aesthetic; chevron-button toggle on the right. Filter-aware projection via `useMemo`-cached `_computeMetricsView(metrics, filterKinds)` helper (drops subagent contribution when subagent kind off; drops reading/thinking gaps when those kinds off; collapses everything to 0 when active kind off). Build-time deviation from plan: helper is named `_computeMetricsView` (not `_computeHeadline`) since both HeadlineCard and MetricsPanel share it — single source of truth.  <!-- status: complete -->
  - [x] P2.2 `MetricsPanel` component shipped. Six `data-metric-section` blocks (engaged-session, ai-agent, tool-call, human, concurrency, blocking) each with a three-column table (Wall-clock | Effort-time | ×Multiplier). Tool sub-table iterates `view.tool_call.top` (up to 5). Concurrency is 4 rows (k=1/2/3/4+ with `is_plus` flag on row 4). One-line legend in panel header explaining the vocabulary. Filter-aware via the same `_computeMetricsView` (single SoT — fixes my plan-time mistake of having two parallel projection helpers).  <!-- status: complete -->
  - [x] P2.3 Wired into `viz_render.py::_interactive_dashboard`: `_initMetricsExpanded` IIFE reads `parseHash().metrics === 'expanded'`; `[metricsExpanded, setMetricsExpanded]` state added; separate `useEffect` writes `updateHash({metrics: metricsExpanded ? 'expanded' : null})` with 100ms debounce + default-elision. Rendered between Toolbar and SummaryStrip, gated by `window.CT_DATA.metrics` presence (additive-emit guard).  <!-- status: complete -->
  - [x] P2.4 Empty-window caption implemented inside `HeadlineCard`: when post-filter all three headline values are 0, three tiles show `—` instead of `0s` AND a caption appears next to them. Two caption variants: `No tracked activity in the past 7 days` (raw metrics also zero — fresh install or week-off case) vs `No data matches current filters — adjust chips above to see the past 7 days` (raw non-zero but filters hide everything).  <!-- status: complete -->
  - [x] P2.5 CLAUDE.md "Per-consumer key reservations" table updated: added `WP10 (metrics) | metrics | expanded (the only non-default value) | card is collapsed (default)` row between WP9 and WP13.  <!-- status: complete -->
  - [x] P2.6 13 source-shape pins added to `test_visualize_cli.sh` (WP10-P2-1 through -13): HeadlineCard fn def + MetricsPanel fn def + `_computeMetricsView` helper + data-metrics-card + 3 tile selectors + 6 section selectors + chevron toggle + metricsExpanded state + hash writer + `_initMetricsExpanded` IIFE + empty-window caption literal + filter-empty caption variant + Dashboard placement guard. visualize_cli suite went 141 → 154 PASS. All 13 PASS.  <!-- status: complete -->
  - [x] P2.7 6 behavioral pins added to `test_visualize_interactive.js` (WP10-P2 behavioral 1–6): card+tiles+chevron render; chevron-click expands panel + writes hash; second click collapses + drops hash; reload with `#metrics=expanded` → expanded on init; toggle subagent chip → AI-effort tile text changes + chip records `data-filter-on=false`; --demo empty-metrics shows the caption. Seeds its own minimal real-DB (burst+tool+subagent) for value-driven tests since --demo emits empty metrics. interactive suite went 28 → 34 PASS. All 6 PASS via React-fiber `reactProps[fiberKey].onClick()` workaround pattern.  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; first run + back-loop re-run after P2.verify-human.2 fix. 15/15 WP10-P2 source-shape pins PASS (was 13; +2 for data-metrics-window selector + "Past N days" format); 34/34 behavioral pins PASS (no regression from indicator-move). -->
  - [x] verify-self  <!-- status: complete; first run + back-loop re-run. Integration-boundary applies (consuming surface = claude-time visualize UI). First run: 6 behavioral pins (34/34 PASS) + 7 in-container extras (no console errors, viewport fit, 3 tiles populated, panel renders 6 sections + non-zero height, Week view no regression, no errors after interactions). Back-loop re-run (P2.verify-human.2 fix): live DOM check confirmed window indicator visible on collapsed card ("Past 7 days · YYYY-MM-DD → YYYY-MM-DD"), still visible when expanded, removed from panel header, legend preserved in panel. No BLOCKING or COSMETIC failures across either run. -->
  - [x] verify-human  <!-- status: complete; all 6 leaves APPROVED. First run: 5/6 PASS (.1, .3, .4, .5, .6) + 1 cosmetic-FAIL (.2: window indicator placement). Back-loop fix moved date-range indicator from MetricsPanel header to HeadlineCard top-right; user APPROVED re-run of .2. Integration-boundary satisfied throughout. -->
  - [x] verify-codify  <!-- status: complete; +3 codify-gap behavioral pins (WP10-P2 behavioral 7/8/9): window indicator persists across collapse/expand; subagent OFF drops AI-effort + subagent sub-row is the visible source-of-truth for the drop magnitude; metrics card mounted across view-mode switches. Phase 2 totals: 15 source-shape (P2-1 to P2-15) + 9 behavioral = 24 net assertions. Full suite 335/0 PASS, structure 122/0 PASS. No test triage needed. -->
    - [x] P2.verify-human.1 (visual aesthetic): PASS (user delegated agent self-verification; aesthetic checks covered by verify-self extras + behavioral pins + 7 in-container checks).  <!-- status: complete -->
    - [x] P2.verify-human.2 (headline numbers plausible + visible window context): **APPROVED 2026-05-24** after back-loop fix — date-range indicator moved from MetricsPanel header to HeadlineCard top-right (above chevron). Renders as `Past 7 days · 2026-05-18 → 2026-05-24` (monospaced, tertiary color). Visible both collapsed and expanded; removed from panel; legend preserved in panel. User approved on re-run.  <!-- status: complete -->
    - [x] P2.verify-human.3 (expanded panel content): PASS (user said "everything else is good").  <!-- status: complete -->
    - [x] P2.verify-human.4 (filter chip semantics): PASS.  <!-- status: complete -->
    - [x] P2.verify-human.5 (Month + Custom no-regression): PASS.  <!-- status: complete -->
    - [x] P2.verify-human.6 (consuming-surface CLI invocation captured): PASS — render command + page-load confirmation implicit in the user's review of items 1, 3, 4, 5 (all required the page to render).  <!-- status: complete -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > SHIPPED (commit fc4fe2a)
- **Active scope:** (none — feature shipped; awaiting `/feature-finalize`)
- **Blocked:** none
- **Unvisited:** finalize (retrospect + WBS row → SHIPPED + CHANGELOG + archive WIP)
- **Open discoveries:** demo-path empty-metrics simplification (logged in `## Discoveries` below)

## Retrospect

- **What changed in our understanding:**
  - The "wall-clock vs effort-time" frame is the single load-bearing insight for the panel. Q5 of the spec (engaged-session definition with away-gaps excluded) was tagged "load-bearing" at spec time and it stayed load-bearing through ship — every reconciliation invariant test pivots on it. The user's pre-existing `/tmp/usage_analysis_v3.py` was the implementation reference; copying its interval-merge + engaged-interval-construction logic literally gave us exact-match numbers at verify-human (22 numeric assertions matched on a real-DB cross-check). When a user has a working reference impl in hand, transcribe it — don't re-derive.
  - **Bundling at spec is cheaper than two-WP slot-after.** WP10 (originally a simple headline card) and SURFACE-2026-05-24-AGGREGATE-METRICS-PANEL (a 6-metric panel) were spec-bundled as option 3 ("run /feature-spec to resolve the relationship between them"). The 8 spec questions surfaced design coupling that two separate WPs would have rediscovered. The trade-off accepted: WP10's original sparkline + view-adaptive deltas were dropped; comparison-axis work moves to WP11 cleanly. Net: one feature workflow instead of two.
  - **Demo path empty-metrics is the right simplification.** The demo's `viz/data.js` is JS-formatted mock data, not event-dicts. Building a JS→event-dict shim for `--demo` would have added one P-task with marginal value (the demo is for layout preview, not metric-number showcase). Surfaced as a Phase 1 discovery, accepted by user at verify-human Phase 1.
  - **One verify-human back-loop on placement, not behavior.** P2.verify-human.2 was a cosmetic-FAIL on UX surfacing (window indicator buried in expanded panel). Fix was a same-day single-component edit. The behavioral suite (34/0 → 34/0) didn't move at the back-loop; only +2 source-shape pins and +3 codify-gap behavioral pins were added during codify. Pattern: design-decision pivots at verify-human (third consecutive cycle: WP7 had 2, WP8 had 0, WP10 had 1) are real but small when caught at the designed-for verify-human gate.

- **Assumptions that held:**
  - **Reconciliation invariants are catch-all regression nets.** Seven invariants (concurrency wallclock sum == engaged wallclock; subagent ⊆ ai_agent; human.multiplier == 1.0 exactly; concurrency[i].effort == wallclock × k; blocking.agent == ai_agent.wallclock; |top| ≤ 5; multiplier-in-valid-range) caught zero bugs during build (no surprise — they're invariants by construction), but they're the most reliable regression coverage for the 6-metric tree. Any future refactor of `build_metrics` that breaks math will trip one of these immediately.
  - **WP7-discovered React-fiber `reactProps[fiberKey].onClick()` pattern still works** (5th consecutive WP using it: WP5b, WP7, WP8, WP9, WP10). Per SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL the underlying Playwright/React boundary is still unfixable, but the workaround is now battle-tested across 9+ different click handlers across the cycle.
  - **Plan-level downstream-contract-impacts catch DID fire — at the changing phase, not at codify.** P1.5 wiring exposed two existing WP5b assertions using `! grep -q '"day_count"'` as a single-day-shape proxy; the new metrics tree always emits its own `day_count: 7` so those negative greps were polluted. Fix scoped to `grep -c day_count == 1` **in P1.7 alongside the changing emit**, not deferred to codify. This is the rule from CLAUDE.md working as intended.

- **Assumptions that were wrong / scope surprises:**
  - **Original WP10 scope was too small.** The WBS WP10 row described a sparkline-headline card with per-view deltas; what the user actually wanted (revealed at spec dialog Q1) was three load-bearing numbers + an expandable parallelism panel. The spec dialog took 8 numbered questions to surface this gap. Lesson: **at spec, ask "what shape of question does this answer?" before "what does it look like?"** — the shape (engaged-session wall-clock vs AI effort-time vs human activity) is the real spec, the visual is downstream.
  - **AI-effort headline #3 has a non-obvious double-counting hazard.** Initial plan considered "AI effort = agent_burst_effort + tool_call_effort + subagent_effort". Caught at spec follow-up: tool/subagent intervals are subsets of agent burst windows, so summing all three would double-count. The honest number is `agent_effort_ms` alone (which already contains everything the agent did inside the burst). User accepted. Lesson: **when three nested intervals are candidates for an "additive total", check subset relationships first.** Reconciliation invariant `subagent ⊆ ai_agent` was added as a codified safeguard.
  - **`_computeMetricsView` is the right SoT, not `_computeHeadline` + parallel panel projection.** Plan tasks P2.1 + P2.2 originally had separate filter-aware projection helpers. During build I realized headline + panel filter-projection logic is identical (both read kindFilters, both apply the same drop-rules). Collapsed to one helper. Plan-task naming followed; WIP P2.2 description updated post-hoc.

- **Approach delta:** Implementation closely matched plan. Two-phase shape held (aggregator-first, UI-on-top — same pattern as WP3→WP5b and WP4→WP10). The plan's "Phase 1 verify-human cross-check against /tmp/usage_analysis_v3.py" hypothesis turned out to be exactly the right discriminator (22 numeric assertions, exact ms-level match). One verify-human back-loop (P2.verify-human.2, placement-cosmetic, fixed same-day). No back-loops to plan or spec.

## Discoveries

- [SURFACED-2026-05-24] feature-spec — `wbs.md` exceeds size guard (314 lines), truncated to first 100. Consider summarizing.
- [SURFACED-2026-05-24] Phase 1 P1.5 — `--demo` path emits an **empty** metrics tree (fully-shaped zeros) because `viz/data.js` is JS, not event-dicts, and parsing it into events would require a separate code path. HeadlineCard will render the empty-window caption on demo. **Suggested action:** revisit during Phase 2 verify-human if the demo's empty-metrics surface looks confusing; otherwise leave as-is (demo is for layout preview, not metrics demo). Not a blocker.
- [SURFACED-2026-05-24] Phase 1 P1.5/P1.7 — **two existing test assertions had `! grep -q '"day_count"'` as a single-day-shape proxy** (WP5b-2 + WP5b-4). The new metrics payload always emits its own `day_count: 7`, which polluted that negative grep. Fixed in same phase by scoping to `grep -c day_count == 1`. This is exactly the "plan-level downstream-contract-impacts pass" mechanism from CLAUDE.md — caught at the changing phase, not deferred to a later phase. Useful regression-guard story to retell at finalize.
