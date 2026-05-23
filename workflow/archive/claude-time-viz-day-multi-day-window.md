---
feature: claude-time-viz-day-multi-day-window
workflow: feature
state: ship (complete)
created: 2026-05-23
cycle: claude-time-visualize-v2
wbs_wp: WP5b
drive_mode: autopilot
---

# Feature: WP5b — Multi-day data window for Day view

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-23

## Problem Statement

`claude-time visualize`'s Day view today calls `build_day_data(target_day)` and emits exactly one day of events. WP5 made the timeline pannable/zoomable, but panning past the day boundary reveals empty time because no data exists outside `[00:00, 24:00)` of the target day. Users want to pan past the current day (both directions) and see actual events. This was user-prioritized at WP5 verify-human ("this feature really matters to me!", `SURFACE-2026-05-22-CLAUDE-TIME-VIZ-DAY-VIEW-MULTI-DAY-DATA-WINDOW`).

Resolution: load a multi-day window (`[date − prior, date + after]`, defaults `prior=14, after=7`) via the already-shipped `build_range_data`, then teach the renderer to lay out segments using `day_iso + seg.start` as an **absolute minute-since-window-start** instead of treating `seg.start` as a single day's minute-of-day. The viewport stays centered on the requested day so the default-hash experience is unchanged.

**Problem statement unchanged on F9b re-entry (2026-05-23)** — root problem is still multi-day rendering on the Day view. What verify-self revealed: (a) the viewport-init logic is duplicated across `dashboard.jsx._initialViewport` and `viz_render.py` Dashboard wrapper's `_defaultViewport + useState`, and only the JSX side was updated; (b) cross-day session aggregation produces duplicate React keys because `build_range_data` unions sessions across days without renamespacing session_ids. Both are implementation gaps within the same problem scope.

## Downstream contract impacts

WP5b changes the **shape of `window.CT_DATA.today`** in the multi-day case (`day_count > 1`). `build_range_data` already returns a back-compat single-day shape when `day_count == 1`, so the default-hash path (no CLI flags, no config) is byte-identical to today's output. The multi-day-case shape additions:

- `meta.start`, `meta.end`, `meta.day_count` — already emitted by `build_range_data`.
- `hour_range_by_day: {iso: [start_hr, end_hr]}`, `day_window: [global_start_hr, global_end_hr]` — already emitted.
- Sessions carry `day_iso: "YYYY-MM-DD"` — already emitted by `build_range_data`.
- New on the multi-day payload (Phase 1): `target_iso: "YYYY-MM-DD"` (the day the user passed via `--date`/today). Renderer uses this to center the initial viewport.

Artifacts that assert against the day-payload shape (must be considered in this same feature, NOT deferred to verify-codify):
- `tests/test_visualize_cli.sh` — emitted-HTML assertions (e.g., `hour_range`, NOW marker hidden when `data.iso !== todayISO`)
- `test_viz_data.py` — `build_range_data` already covered; new `day_count > 1` via `_cmd_visualize` integration is new surface
- `dashboard.jsx` — consumes `today.projects`, `today.hour_range`, `today.iso`; the per-day day_iso tagging is new

## Work Tree

- [x] Phase 1: Data plumbing — wire build_range_data, CLI flags, config keys  <!-- status: -->
  **Observable outcomes:**
  - CLI: `claude-time visualize --date 2026-05-23 --context-days-prior 14 --context-days-after 7 --no-open --demo` exits 0 and writes HTML to stdout's reported path; emitted HTML contains `window.CT_DATA.today.meta.day_count` equal to `22` (or whatever the user-configured prior+after+1 sums to); `window.CT_DATA.today.target_iso === "2026-05-23"`.
  - CLI (back-compat / default-hash path): `claude-time visualize --no-open --demo` produces a `window.CT_DATA.today` whose shape is identical to pre-WP5b output (single-day shape — `hour_range`, `iso`, `projects` with sessions lacking `day_iso`, no `meta.day_count`, no `target_iso`) OR matches single-day back-compat from `build_range_data` (already passes `day_count == 1` → emits `iso` + `hour_range`). Tests pin which variant.
  - CLI (config path): writing `{"viz_context_days_prior": 3, "viz_context_days_after": 1}` to a temp `CLAUDE_TIME_DIR/config.json`, running `claude-time visualize --date 2026-05-23 --no-open --demo` (no CLI flag) — emitted HTML has `meta.day_count === 5`.
  - CLI (flag overrides config): same config set; running with `--context-days-prior 0 --context-days-after 0` — `meta.day_count === 1` and emitted shape matches single-day back-compat.
  - [x] P1.1 Add `--context-days-prior N` (`int`, default `None`) and `--context-days-after M` (`int`, default `None`) to the `viz` subparser argparse block in `claude-time` (CLI script).  <!-- status: -->
  - [x] P1.2 Add `viz_context_days_prior: int (default 14)` and `viz_context_days_after: int (default 7)` keys to `DEFAULT_CONFIG` in `claude-time`. Extend `load_config` validation to accept non-negative integers; silent fallback on invalid values.  <!-- status: -->
  - [x] P1.3 Resolve effective prior/after in `_cmd_visualize`: CLI flag overrides config overrides default. If both resolved values are `0`, take the existing single-day code path (`build_day_data`).  <!-- status: -->
  - [x] P1.4 Call `build_range_data(start_iso, end_iso, events_by_day=..., cfg=..., auto_alias_fn=...)` in `_cmd_visualize` when ctx_prior+ctx_after > 0. Attach `target_iso = target_day.isoformat()` to the returned dict before assigning to `data["today"]`.  <!-- status: -->
  - [x] P1.5 `--demo` path forces ctx_prior=ctx_after=0 (demo fixture is single-day). Help string documents this.  <!-- status: -->
  - [x] P1.6 (Hardening) Week payload independence verified: `week_payload = build_week_data(monday, week_events_by_day, ...)` continues to be emitted as `data["week"]` unchanged. New `week_events_by_day` is built independently from the Day-window's `day_events_by_day`.  <!-- status: -->
  - [x] verify-auto  <!-- status: -->
  - [x] verify-self  <!-- status: PASS — all 4 CLI observable outcomes verified live; integration boundary (claude-time visualize subcommand) cited in outcomes -->
  - [x] verify-human  <!-- status: PASS — all 4 leaves run against real DB; agent executed on user's behalf, user reviewing output -->
    - [x] P1.verify-human.1 default multi-day flow — day_count=22, target_iso=2026-05-23, 9 projects / 31 sessions  <!-- status: -->
    - [x] P1.verify-human.2 single-day back-compat (0/0) — flat iso/hour_range, no target_iso, no meta.day_count  <!-- status: -->
    - [x] P1.verify-human.3 --help legibility — new flags present with metavars; --demo text updated  <!-- status: -->
    - [x] P1.verify-human.4 custom config (30/0) — day_count=31, window 2026-04-23 → 2026-05-23  <!-- status: -->
  - [x] verify-codify  <!-- status: PASS — 7 new codify tests in test_visualize_cli.sh; integration boundary covered; 1 test-side triage (help-text wrap-tolerance), auto-fixed; full suite 165/165; surfaced SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG -->

- [x] Phase 2: Renderer multi-day support — day-offset math + adaptive ruler + label formatter  <!-- status: -->
  **Observable outcomes:**
  - Browser: Playwright loads `visualize.html` emitted with `--context-days-prior 14 --context-days-after 7 --date 2026-05-23`; takes a snapshot of the timeline. Initial viewport centers on `2026-05-23` (the requested day) — the horizontal center of the visible window corresponds to 12:00 of that day's data. Default-hash (no `#viewport=...`) and `data.target_iso === "2026-05-23"` together drive the centering.
  - Browser: After pan-left by `dragRulerBy(-720px)` (≈ 1 viewport-range left), the visible ruler contains tick labels of the form `MMM DD HH:MM` (e.g., `May 22 12:00`) because the viewport now spans across midnight. Within a single day, labels stay `HH:MM`.
  - Browser: Zoom out via repeated `keyboard.press("-")` until the visible range exceeds ~2 days; the ruler tick interval auto-picks from the extended scale set `[1440, 360, 60, 30, 15, 10, 5, 1]` to keep tick count in the 8–30 band. At 21-day zoom-out (full default window), the ruler shows 21 day-level ticks.
  - Browser: A session originally on `2026-05-22` (day before `target_iso`) renders to the LEFT of the day-boundary line; its segment-bar `left%` and `width%` reflect `(day_offset_min + seg.start) / viewport_range`, NOT just `seg.start / viewport_range`. Verified via `data-seg-id` selector + computed `style.left` matching expected percentage.
  - Browser: NOW marker visible only when `target_iso === todayISO` AND `nowMin` (live wall clock minute-of-day, plus target-day offset) lies inside the viewport. Existing isToday + inWindow logic must be extended to handle the day-offset case.
  - Console: no JS errors on initial render or after pan/zoom.
  - [x] P2.1 `dayOffsetMin(day_iso, window_start_iso)` helper added — UTC-anchored, returns minutes-since-window-start, robust to malformed input.  <!-- status: -->
  - [x] P2.2 `SegmentBar` accepts `dayOffset` prop (default 0); `SessionRow` computes `dayOffsetMin(session.day_iso, dw.windowStartIso)` once and passes it to each `SegmentBar`. `InterruptHairlines` also takes `dayOffset` for the per-session interrupt minutes (transform `viz_render.py` updated to match new shape).  <!-- status: -->
  - [x] P2.3 `_initialViewport()` extended: when `target_iso + meta.start` both present, center on target day's `hour_range_by_day[target_iso]` with day-offset applied; falls back to single-day flat `hour_range` and finally `[6, 23]` defensively.  <!-- status: -->
  - [x] P2.4 `pickTickInterval` scale set extended to `[1440, 360, 60, 30, 15, 10, 5, 1]`. Default-window 21-day → 21 ticks (in-band).  <!-- status: -->
  - [x] P2.5 `ticksInViewport` label formatter: `MMM DD` at intervalMin >= 1440; `MMM DD` on midnight-crossing ticks when viewport spans midnight; `HH:00` / `HH:MM` within a single day. New `_formatDayLabel` helper handles ISO-day → "MMM DD" conversion via UTC.  <!-- status: -->
  - [x] P2.6 `DayTimeline.dataWindow` extended: when `meta.day_count` present, `[0, day_count * 1440]`; otherwise legacy `hour_range`. `Minimap.dataWindow` follows the same rule.  <!-- status: -->
  - [x] P2.7 NOW marker: `isToday` now checks `meta.start <= todayISO <= meta.end` in multi-day mode (was `data.iso === todayISO`); `effectiveNowMin = nowMin + dayOffsetMin(todayISO, meta.start)` shifts the marker into minute-of-window. Hide marker if outside viewport.  <!-- status: -->
  - [x] verify-auto  <!-- status: PASS (post-F9b re-check) — py_compile viz_render OK; --demo render exit 0; targeted viz_cli suite 50/50; dashboard.jsx + viz_render.py both transform-pin-compatible after fix -->
  - [x] verify-self  <!-- status: PASS after F9b back-loop fix — initial FAIL on viewport-init double-path + duplicate React keys; both root-caused and resolved; re-verify gate confirmed via direct Playwright (viewport=[20580,20760], 12 visible segs, 0 console errors, NOW marker at 09:06 on target day) -->
    - [x] P2.verify-self.1 Initial viewport centers on requested day  <!-- status: PASS after F9b fix — viz_render.py Dashboard wrapper now delegates to _initialViewport() (single source of truth, eliminates double-path drift). Re-verified: viewport=[20580, 20760] matches expected target-day centering. -->
    - [x] P2.verify-self.2 Scale-set includes 1440  <!-- status: PASS -->
    - [x] P2.verify-self.3 No JS console errors  <!-- status: PASS after F9b fix — SessionRow key now `${s.day_iso}:${s.id}` when multi-day, falls back to `s.id` single-day. transform pin updated. Re-verified: 0 console errors (was 8 duplicate-key warnings). -->
    - [x] P2.verify-self.4 Ruler shows ticks  <!-- status: PASS — 17 hour-marks (06:00…22:00 cleared after fix; now 07:00…09:45 inside target day) -->
    - [x] P2.verify-self.5 Sessions render off-center  <!-- status: PASS after F9b fix (consequence of .1): with viewport correctly centered at [20580, 20760], 12 of 535 DOM segs visible (those falling in 07:00–10:00 of 2026-05-23), rest correctly positioned off-screen with left% > 100 awaiting pan. -->
  - [x] verify-human  <!-- status: PASS — 6/6 leaves approved; minimap-density fix (P2.verify-human.5) added as in-flight fix when user observed density bars bunched at left (third double-path bug surfaced: Minimap's allSegs flatMap wasn't day-offsetting either). All other leaves confirmed visually. -->
    - [x] P2.verify-human.1 Initial centered on today — date range MAY 09–30, NOW marker at 09:06 on target day, visible ~07:00–10:00 window  <!-- status: -->
    - [x] P2.verify-human.2 Pan across day boundaries shows MAY DD labels  <!-- status: -->
    - [x] P2.verify-human.3 Zoom-out switches to day-level ticks  <!-- status: -->
    - [x] P2.verify-human.4 Zoom-in smooths through scale-set  <!-- status: -->
    - [x] P2.verify-human.5 Minimap shows correct density distribution  <!-- status: FIXED in-flight — density bars no longer bunched at left; spread 43.6%–65.3% reflecting real activity days MAY 18–23. Root cause: Minimap.allSegs flatMap (line 1325) flattened segs WITHOUT day-offset. Third double-path bug in same class as P2.verify-self.1 (viz_render.py wrapper) and SessionRow.key. Fix: wrap flatMap to pre-shift seg.start/end by dayOffsetMin(s.day_iso, meta.start). -->
    - [x] P2.verify-human.6 NOW marker positioned on target day  <!-- status: -->
  - [x] verify-codify  <!-- status: PASS — 9 new Phase 2 codify tests added to test_visualize_cli.sh; 3 regression-pins for the in-flight bug fixes (viewport-init consolidation, SessionRow day_iso key, Minimap day-offset). Full suite 59/59 viz_cli + 29 cli + 40 viz_data + 29 reclassify + 17 hook = 174/174. Zero triages (clean pass). -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** Shipped 2026-05-23 as commit `02d6237` (pushed to origin/main, fast-forward). Next: /feature-finalize for CHANGELOG, WBS update, backlog sweep, archive WIP.
- **Blocked:** none
- **Unvisited:** Phase 2 (verify-codify), feature finalize
- **Open discoveries:**
  - `SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG` (pre-existing CLI quirk, logged to backlog, low priority — not blocking)
  - **3 double-path bugs found during Phase 2 verification** (all fixed in-flight). All three are the same symmetry-check class: when extending a renderer-state mechanism for multi-day, audit all parallel paths.
    1. `viz_render.py` Dashboard wrapper had its own `_defaultViewport + useState` initializer mirroring `dashboard.jsx::_initialViewport` — only JSX side was updated. Fixed by consolidating: wrapper now delegates to `_initialViewport()`.
    2. `SessionRow.key={s.id}` collided when `build_range_data` unions sessions across days with same session_id. Fixed: `key={s.day_iso ? \`${s.day_iso}:${s.id}\` : s.id}`. Related: `SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE` (yesterday "synthetic-only" — but cross-day union upstream is itself the trigger).
    3. `Minimap.allSegs.flatMap` flattened segs without day-offset, bunching density bars at left. Fixed: wrap flatMap to pre-shift `seg.start/end` by `dayOffsetMin(s.day_iso, meta.start)`.

## Phase 2 Build Notes (2026-05-23)
- Renderer-side changes: added `dayOffsetMin` helper, `DataWindowContext` plumbed to `HourRuler`/`HourGridBackground`/`SessionRow`, `SegmentBar` accepts `dayOffset` prop, `_initialViewport` centers on `target_iso`, `pickTickInterval` scale set extended to `[1440, 360, 60, ...]`, `ticksInViewport` emits ISO-day-aware labels, `DayTimeline + Minimap` extend `dataWindow` to `[0, day_count*1440]`, NOW marker handles day-offset.
- Transform-side: `viz_render.py` updated to match new `SegmentBar` signature pin (`dayOffset = 0`) and new `SessionRow.segs.map` shape (passes `dayOffset={dayOffset}`). `InterruptHairlines` accepts `dayOffset` and shifts its minute-of-day inputs.
- **2 test triages** (both auto-fixed, both obsolete tests with high confidence — see ## Test Triage section). One was a pre-Phase-2 wrap-issue caught in Phase 1 codify; one was a viewportPct pin that needed loosening for the new call shape.
- **Single-day back-compat preserved:** when `data.meta` is absent (`--context-days 0/0` or `--demo`), `DataWindowContext` defaults `windowStartIso=null`, `dayCount=1`. All consumers fall back to pre-WP5b behavior. Verified by `WP5b codify: target_iso path-divergence` assertion plus `single-day back-compat (0/0)` assertion.

## Phase 1 Build Notes (2026-05-23)
- Container test suite results (all green):
  - `test_visualize_cli.sh`: 43/43 PASS (up from 41 — added assertion 9b "WP5b single-day back-compat" and 14b "single-day flat hour_range preserved")
  - `test_cli.sh`: 29/29 PASS, `test_viz_data.py`: 40/40, `test_reclassify.py`: 29/29, `test_hook.sh`: 17/17
- **Contract change confirmed:** default `claude-time visualize --date <iso>` (no context-days flag) now emits the multi-day shape (`target_iso`, `meta.day_count`, `hour_range_by_day`). To preserve the legacy flat-`iso` + flat-`hour_range` shape, pass `--context-days-prior 0 --context-days-after 0`. Test assertions 9/14 were updated to expect the new shape; 9b/14b were added to pin the single-day back-compat path.
- **`--demo` path**: forced to single-day (ctx_prior=ctx_after=0). Help string documents this.
- **Week payload**: independent of Day's context-days window — new `week_events_by_day` is loaded separately from the Monday-anchored 7-day window. Verified via `test_week_payload_unchanged` (smoke test, since cleaned up).

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Test Triage — WP5b: --help new flags + demo text
Classification: obsolete test
Confidence: high
Evidence: The regex `'forces context-days-prior/after to 0'` requires the phrase on a single line. argparse `--help` wraps long help-strings at terminal width (~78 chars in container), splitting the phrase across two lines. The behavior is correct (the text is present in --help output, just wrapped); the assertion regex is wrong.
Action: Auto-fix the assertion to use a wrap-tolerant match (grep `-c` with no anchors, or `tr` newlines to spaces before grepping). Re-run.

## Test Triage — WP5-P1 codify: viewportPct is consumed
Classification: obsolete test
Confidence: high
Evidence: The pinned string `viewportPct(seg.start, seg.end` no longer appears verbatim — Phase 2 of WP5b changed the SegmentBar call to `viewportPct(seg.start + dayOffset, seg.end + dayOffset, viewport)` so multi-day sessions can shift their segments by day-offset. The behavior the test was guarding (viewportPct being called from a segment renderer, vs being dead code) is still correct — only the call shape changed.
Action: Auto-update the assertion's grep pattern from `viewportPct(seg.start, seg.end` to `viewportPct(seg.start` (drops the seg.end anchor, which is no longer adjacent to seg.start in the new shape). Still asserts the function is called from inside a SegmentBar / segment context.

## Plan Notes

**Departure from WBS row scope.** The WBS WP5b row lists 7 tasks under a single phase with implied size S–M. During plan-time codebase reading, the `seg.start`/`seg.end` minute-of-day anchoring (segments are positioned via `viewportPct(seg.start, seg.end, viewport)` where `seg.start ∈ [0, 1440)` per `_ts_to_minutes`) means multi-day rendering needs **per-segment day-offset math** at the renderer level — bigger than the WBS row implies. Split into two phases:
- **Phase 1** — pure data/CLI plumbing (no renderer changes; emitted single-day shape stays byte-identical on default-hash path).
- **Phase 2** — renderer multi-day support (day-offset math, adaptive ruler scale-set, ISO-day labels, initial-viewport centering, NOW marker).

This preserves the "default-hash unchanged" regression-pin from WP5 verify-human (the renderer changes are additive — when `day_iso`/`target_iso`/`meta.day_count` are absent, the legacy single-day path remains).

**Risk surface (carried from WBS).** Extending `pickTickInterval`'s scale set with `[1440, 360]` may produce surprising tick density at edge cases (e.g., 8-hour window: `480/360 = 1.3 → 2 ticks` — out-of-band, falls through to 60m → 8 ticks; safe). P2.4 includes a smoke-test of the full transition table to confirm in-band coverage.

**Test infra reminder.** The container `claude-time-test` is still running from the previous session. P1 verify-auto and P2 verify-auto run via `tools/claude-time/test/run-in-container.sh exec <suite>`.

## Retrospect

- **What changed in our understanding:** The renderer's "single source of truth for viewport-init" was actually **three** places, not one. `dashboard.jsx::_initialViewport`, `viz_render.py` Dashboard wrapper's `_defaultViewport` (useMemo), and the same wrapper's `useState` initializer all independently computed an initial viewport. Phase 2 plan addressed only the JSX side; the Python-transform side drifted into a single-day-only fallback. Similar pattern hit the `SessionRow` key (Source vs transform pin) and `Minimap.allSegs` (a third independent segment-iteration path that mirrored DayTimeline without sharing code). Lesson: **multi-day extension is a symmetry-check across every parallel renderer-state path**, not a single-file edit.

- **Assumptions that held:** (a) `build_range_data` already in place from WP3 meant Phase 1 was thin and low-risk. (b) `day_count == 1` back-compat in `build_range_data` made the single-day path a structural fact, not a code path I had to maintain — the codify tests pinning `target_iso path-divergence` capture this contract. (c) `pickTickInterval`'s scale-set extension produced clean 8–30 band coverage across all relevant window sizes (verified via plan-time arithmetic; confirmed at runtime).

- **Assumptions that were wrong:** (a) Plan assumed a "single phase, single source edit" for the renderer changes (WBS row implied size S–M, 7 tasks). Actual: 2 phases, 3 double-path bugs found during verification. (b) Plan assumed `seg.start` being minute-of-day was the only renderer touch-point. Reality: `Minimap.allSegs` had its own flat-map pipeline that also needed day-offset; `InterruptHairlines` accepted segs without offset; `SessionRow` key collided. (c) Plan assumed `--demo` path testing would expose viewport-init issues during Phase 2 verify-auto. Reality: `--demo` forces single-day so it exercised the back-compat path, NOT the multi-day path where the bug lived. Verify-self's live multi-day render caught it.

- **Approach delta:** Plan split into 2 phases (data plumbing + renderer) — matched actual execution. Phase 2 took **3 back-loops** instead of zero: verify-self (viewport-init + duplicate-key), verify-human (minimap density). Each was caught at the right gate; none escaped to production. The codify regression-pins (3 of the 9 new assertions explicitly guard against re-introduction of these bugs) are the lasting structural improvement from this feature — the "double-path" failure mode is now grep-able and CI-detectable.

## Closure Notice

**Feature complete:** `claude-time visualize` multi-day data window for Day view has shipped (WP5b, commit `02d6237`). Day view now loads ±21 days of context around the requested day (defaults `prior=14, after=7`); pan across midnight to see neighboring days' activity. Verify in your terminal: `tools/claude-time/claude-time visualize` — initial view centers on today, drag left/right to reveal trailing/leading days, ruler labels switch to `MMM DD` at multi-day zoom-out.

Requester = operator — closure notice for self-record.
