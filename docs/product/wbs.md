---
stage: wbs
state: in-progress
updated: 2026-05-24
cycle: claude-time-visualize-v2
---

# WBS — `claude-time visualize` v2

## Context

`claude-time visualize` shipped its MVP on 2026-05-19 (day view + week view, snapshot per invocation, single full-bleed dashboard, click-bar-for-side-panel). Real-data usage immediately surfaced a cluster of gaps that map cleanly to (a) the spec's deliberately-deferred "Out of Scope" items, (b) UX affordances the snapshot model doesn't satisfy, and (c) one critical timeline-navigation feature missing from v1 (zoomable / draggable multi-track timeline, audio-editor style).

This WBS bundles those gaps into a single cycle. It is **not** a continuation of the workflow-system roadmap (which is a separate product) — it's a new product cycle for the `claude-time` tool that lives in this repo.

## Scope

**Included (12 work packages):**
- Adaptive hour-ruler (consume existing `hour_range` field)
- Zoomable + draggable multi-track timeline ⭐ **critical / foundational**
- Multi-day data window for Day view (extends WP5 to render trailing+leading context days — user-prioritized, added at WP5 finalize 2026-05-22)
- "Today" → "Day" rename
- Month view
- Custom-range view
- Interactive filter chips
- Comparison view (delta lens — week-over-week, day-vs-median)
- Headline-stats card (above-the-fold "how much real work today")
- Multi-instance overlap visualization
- Idle/away total visibility
- Project total pills on the row label
- NOW marker bug fix (currently stuck at emit-time)
- Collapsible project rows (default-collapsed, expand for per-session detail)

**Not included (explicitly deferred):**
- Dark theme (out-of-scope hold; revisit after this cycle ships)
- Live auto-refresh / filesystem watcher (out-of-scope hold)
- Pre-transpile JSX / drop unpkg CDN (engineering polish; revisit if v2 makes the page noticeably slow)
- Export-as-PNG / share affordances (single-user constraint stands)
- Eye-tracking / typing-detection improvements (not viz-side concerns)

---

## Phase 0: Data-layer foundations (range + comparison)

**Phase rationale:** Several v2 features (custom-range, month, comparison, zoomable timeline) all need the data layer to emit arbitrary `[start, end]` windows, not just `today` / `current week`. Build the range-aware data path **before** any UI consumes it; otherwise we'd retrofit JSON shape mid-cycle and rework Phase 5c byte pins.

### WP1: Adaptive hour-ruler (consume existing `hour_range`) — [x] SHIPPED 2026-05-19 (commit 2760c6b)
**Description:** Wire the already-emitted `today.hour_range: [start, end]` field into `dashboard.jsx`'s ruler / segment-positioning math. Replaces the hardcoded `DAY_HOURS = [6..22]`. Resolves the deleted backlog item `SURFACE-2026-05-19-CLAUDE-TIME-VIZ-DAY-HOURS-NOT-ADAPTIVE`.
**Phase:** 0
**Dependencies:** —
**Size:** XS
**Why first:** smallest possible change, exercises the byte-pin + emit-time-transform pattern under low risk, validates the dev loop end-to-end before larger phases. Also unblocks: zoomable timeline needs flexible ruler math anyway.
**Tasks:**
- [x] 1.1 Edit `viz/dashboard.jsx` source directly: derive `DAY_HOURS` / `DAY_START_MIN` / `DAY_END_MIN` / `DAY_RANGE_MIN` from `window.CT_DATA.today.hour_range` at runtime (with `[6, 23]` fallback). v2 cycle's first source edit; emit-time-transform pattern replaced by direct edit since byte-pin is relaxed in this same WP.
- [x] 1.2 Verified `--demo` path: `data.js` now includes `hour_range: [6, 23]`; derivation produces v1-identical 17-tick ruler.
- [x] 1.3 No SegmentBar `pct()` math changes needed — it already reads from the module-level `DAY_*` constants which now derive adaptively. Single source change propagates.
- [x] 1.4 `test_visualize_cli.sh` assertion #14: seeds 14:00–15:00 narrow-window DB, asserts emitted HTML contains `"hour_range": [13, 16]`.
- [x] **Plus** byte-pin relaxation in `tests/check-structure.sh` Phase 5c + CLAUDE.md "Design-as-data" convention rewrite (historical-origin + current-state form, encoding the unlock-condition lesson).

### WP2: NOW marker — client-side `Date.now()` + staleness indicator — [x] SHIPPED 2026-05-19
**Description:** v1 emits the NOW marker position at HTML-generation time, so it freezes on every page. Move NOW computation to the client (`useEffect` + `setInterval(60s)`). Add a small "data snapshot: HH:MM (re-run for latest)" caption to communicate that the underlying *data* is still a snapshot.
**Phase:** 0
**Dependencies:** —
**Size:** S
**Tasks:**
- [x] 2.1 Stripped emit-time `NOW_MIN` constant; `useNowMin()` hook in `viz/dashboard.jsx` returns `{nowMin, todayISO}` from `Date.now()` via `React.useState` + `React.useEffect` with `setInterval(60_000)` and `clearInterval` cleanup.
- [x] 2.2 NOW marker hidden when `data.iso !== todayISO` (e.g., `--date 2026-05-01` or any non-today date) — plus an `inWindow` guard so the marker also hides when clock is outside the adaptive ruler range.
- [x] 2.3 `snapshot: HH:MM` caption rendered in `InteractiveToolbar` (`viz_render.py`), reading `window.CT_DATA.meta.snapshot` populated by `_cmd_visualize` at emit time. Hover tooltip explains the live-cursor + snapshot-data duality.
- [x] 2.4 `test_visualize_cli.sh` extended 14 → 19 assertions: emitted HTML lacks `NOW_MIN = 17 * 60 + 22`; lacks `NOW · 17:22`; contains `Date.now()`/`new Date(`; contains `"snapshot"` key; contains `clearInterval` cleanup.

### WP3: Range-aware data layer — `build_range_data(start_iso, end_iso)` — [x] SHIPPED 2026-05-21 (commit 9ebad84)
**Description:** Extract a single `build_range_data(start, end)` from the current `build_day_data` / `build_week_data`. The new function emits the same project/session/segment shape over any arbitrary `[start, end]` window. Day / week / custom / month all become thin wrappers that compute `(start, end)` and call this.
**Phase:** 0
**Dependencies:** —
**Size:** M
**Tasks:**
- [x] 3.1 Added `build_range_data(start_iso, end_iso, *, events_by_day, cfg, auto_alias_fn)` to `viz_data.py` as the multi-day coordinator. (Note: the plan's "single core" framing was off — the truthful seam is per-day worker + multi-day coordinator; `build_day_data` remains the per-day worker because `_ts_to_minutes` / burst pairing is naturally day-anchored.)
- [x] 3.2 `build_week_data` re-implemented as a thin wrapper over `build_range_data` (output shape unchanged from pre-WP3). `build_day_data` kept as per-day worker (called per-day by `build_range_data`); same day shape preserved byte-for-byte.
- [x] 3.3 `hour_range_by_day: {iso: [start, end]}` per-day adaptive map + `day_window: [global_start, global_end]` union of all per-day ranges. For `day_count == 1`, flat `hour_range` mirrors `hour_range_by_day[only_iso]` for back-compat.
- [x] 3.4 `meta: {start, end, day_count}` emitted on the range payload only — intentionally NOT propagated into day/week wrapper returns to avoid collision with `_cmd_visualize`'s flat-level `window.CT_DATA.meta.snapshot` key.
- [x] 3.5 22 pre-existing tests PASS unchanged; 7 new added (6 `BuildRangeDataTests` covering empty-range default per-day, single-day back-compat, `day_window` union of adaptive ranges, cross-day project aggregation, `meta` exact-keys, defensive `ValueError` on inverted ranges; 1 `WrapperPreservationTests.test_day_shape_equivalence`).

### WP4: Comparison data layer — `build_comparison_data(window_a, window_b)` — [x] SHIPPED 2026-05-21 (commit 4f61904)
**Description:** Emit a side-by-side data payload for two windows (e.g., this-week vs last-week, today vs trailing-7-day median, this-month vs last-month). Per-project totals + per-segment-kind totals for both windows, ready to render as a delta lens.
**Phase:** 0
**Dependencies:** WP3
**Size:** S
**Tasks:**
- [x] 4.1 `build_comparison_data(start_a_iso, end_a_iso, start_b_iso, end_b_iso, *, events_by_day_a, events_by_day_b, cfg, auto_alias_fn)` in `viz_data.py` — coordinator pattern (two `build_range_data` calls + `_compute_deltas` join). Returns `{a, b, deltas: {alias: {kind: {abs_min, rel_pct}}}, meta: {a_start, a_end, b_start, b_end, a_day_count, b_day_count}}`. Plan-time decision: dropped the WBS-pseudocode `kind={absolute|relative}` parameter — `kind` in the result is the segment-kind axis (active/reading/thinking/away/subagent), not a comparison mode; emitting both `abs_min` and `rel_pct` keeps the data layer policy-free.
- [x] 4.2 Helpers `compare_week_over_week(this_monday_iso)` and `compare_day_vs_trailing_window(target_day_iso, window_days=7)` (build-time rename from `compare_day_vs_median` — the data layer emits raw per-day payloads, so the median-vs-mean-vs-sum aggregate is a UI rendering choice deferred to WP10). Both helpers partition a single `events_by_day` into A/B sub-dicts internally.
- [x] 4.3 `BuildComparisonDataTests` in `test_viz_data.py` with 11 methods (empty-both, empty-A, empty-B, identical, regression, meta shape, synthesised `total_active_subagent`, both helpers' window math, `ValueError` guard, cross-window partition correctness). Full claude-time suite 134/134 PASS (69 unittest + 29 cli + 19 viz_cli + 17 hook), net +11 vs WP3 baseline 123. Zero regressions; no integration boundary.

**Phase 0 → Phase 1 rationale:** Once the data layer can emit any window + comparisons, the UI work in Phases 1–3 doesn't have to re-touch Python. This is the standard "backend before frontend wraps" ordering applied at the v2 boundary.

---

## Phase 1: Critical UX foundation — zoomable / draggable timeline

**Phase rationale:** This is the user-designated **critical feature** for v2 ("the UX that matters most"). It is also load-bearing for custom-range, month view, and the renamed Day tab. Land it before adding more views so each view inherits the same interaction model rather than each phase reinventing pan/zoom.

### WP5: Zoomable + draggable multi-track timeline ⭐ — [x] SHIPPED 2026-05-22 (commit 140de22)
**Description:** Reshape the timeline component into a horizontally-scrollable, zoomable canvas — audio/video-editor metaphor. Drag the ruler to pan; mouse-wheel / pinch / keyboard `+/-` to zoom in/out on the time axis (project rows stay vertically stationary). Visible window is independent of the underlying data window — load the broadest reasonable range, then pan/zoom within it. Replaces the current "fit the day to the available width" approach.
**Phase:** 1
**Dependencies:** WP1 (adaptive ruler math), WP3 (data layer can emit broader-than-day windows)
**Size:** XL
**Tasks:**
- [x] 5.1 `useViewport()` Context-plumbed state (`{visible_start_min, visible_end_min}`); URL-hash read on mount + debounced write via shared `parseHash`/`updateHash`/`serializeHash` helpers; default-elision rule. (Phases 1 + 3)
- [x] 5.2 `viewportPct(start, end, viewport)` replaces module-level `pct()`; module-level `DAY_START_MIN/DAY_END_MIN/DAY_RANGE_MIN` removed from segment-positioning path; `overflow: hidden` row containers clip off-viewport segments. (Phase 1)
- [x] 5.3 Drag-on-ruler / drag-on-empty-row pan via `useTimelineGestures`; cursor-anchor invariant (data minute under cursor stays under cursor); `grab`/`grabbing` cursor; gutter-excluded. (Phase 2)
- [x] 5.4 Wheel-zoom with `ctrlKey || metaKey` (covers Safari/Chrome trackpad pinch); keyboard `+`/`-` at viewport center; `0` reset; cursor-anchored zoom. Clamped to `[1, dataWindowRange]` minutes. (Phase 2)
- [x] 5.5 Adaptive ruler density via `pickTickInterval(viewport)` (picks densest interval from `[60, 30, 15, 10, 5, 1]` producing 8–30 ticks); `ticksInViewport(viewport, intervalMin)` generator; labels `HH:00` for hour intervals, `HH:MM` for finer. (Phase 2)
- [x] 5.6 Performance budget: rAF-throttled `scheduleSet` for all viewport mutations; measured **60.2 fps avg / 59.5 fps min** at 1-month / 1800-segment dataset across three independent runs. **DOM-per-segment stays; canvas fallback NOT needed.** (Phase 4 P4.4)
- [x] 5.7 Minimap (single combined ~80px track) with draggable visible-window rectangle: `data-minimap-mode="rect"` pans, `edge-left`/`edge-right` zoom via endpoint drag, click-elsewhere re-centers viewport. (Phase 3)
- [x] 5.8 Keyboard shortcuts: ArrowLeft/Right pan ±10% range; `+`/`=` and `-`/`_` zoom 1.5x at center; `0` reset; `Home`/`End` jump to data start/end (zoom preserved). Filtered against INPUT/TEXTAREA/contentEditable targets. (Phase 2)
- [x] 5.9 `test_visualize_cli.sh` 22 source-shape assertions added across Phase 1/2/3 + 1 hardening regression-pin (catches future orphaned `DAY_*_MIN` consumers after the InterruptHairlines fix). Test count 19 → 41. (Phases 1–3 + verify-human fix)
- [x] 5.10 `test_visualize_interactive.{js,sh}` Playwright behavioral test inside the test-environment container: 10 PASS + 1 documented SKIP (synthetic `WheelEvent` doesn't propagate to React handler). Picks up the deferred WP5-P1 codify "17 HH:00 ruler labels" runtime assertion + Phase 2 gesture-math + Phase 3 hash-round-trip behavioral coverage. (Phase 4 P4.2)
- [x] **Plus** opportunistic P2.7 fold-in: `flipNowLeft` branch in HourRuler resolves `SURFACE-2026-05-19-CLAUDE-TIME-VIZ-NOW-LABEL-OVERLAPS-RULER-TICK`. **Plus** Phase 3 verify-human caught + fixed a BLOCKING runtime regression: `InterruptHairlines` orphan-referenced the deleted `DAY_START_MIN` (3-line fix in `viz_render.py` + regression-pin in `test_visualize_cli.sh`).

### WP5b: Multi-day data window for Day view — [x] SHIPPED 2026-05-23 (commit 02d6237)
**Description:** Day view loads trailing+leading context days into the data window. Current day is default-viewport center; pan reveals neighbors. Resolves `SURFACE-2026-05-22-CLAUDE-TIME-VIZ-DAY-VIEW-MULTI-DAY-DATA-WINDOW`.
**Phase:** 2 (sits with view-modes phase as a Day-view extension)
**Dependencies:** WP3 (range-aware data layer — shipped), WP5 (viewport mechanic + URL hash — shipped 2026-05-22)
**Size:** Actual M (planned S–M). Plan-time scope hidden two double-path bugs (viz_render.py wrapper had its own viewport-init; Minimap density bars also needed day-offset) — both caught at verify-self and verify-human, both fixed in-flight.
**Tasks:**
- [x] 5b.1 `_cmd_visualize` calls `build_range_data(start, end)` when ctx_prior + ctx_after > 0; computes `[date − N_prior, date + N_after]`; defaults `prior=14, after=7` (locked at backlog-grooming).
- [x] 5b.2 New CLI flags `--context-days-prior N` + `--context-days-after M` added to the `viz` subparser (compact `--context PRIOR:AFTER` form not implemented — separate flags were sufficient and easier to document).
- [x] 5b.3 New config keys `viz_context_days_prior` (14) + `viz_context_days_after` (7) added to `DEFAULT_CONFIG` with non-negative-int validator + silent fallback. Precedence: CLI flag > config > built-in default.
- [x] 5b.4 ISO-day-aware label formatter via `_formatDayLabel(dayIx, windowStartIso)` helper. `ticksInViewport(viewport, intervalMin, windowStartIso)` emits `MMM DD` for day-level ticks and on midnight-crossing tick boundaries; `HH:00` / `HH:MM` within a single day.
- [x] 5b.5 `pickTickInterval` scale set extended to `[1440, 360, 60, 30, 15, 10, 5, 1]`. At 21-day default-window zoom-out → 21 ticks (in 8–30 band).
- [x] 5b.6 Initial viewport centered on requested day via `_initialViewport` reading `data.target_iso + meta.start + hour_range_by_day[target_iso]` with day-offset applied. Default-hash regression-pinned (single-day path: `--context-days 0/0` produces byte-identical pre-WP5b shape).
- [x] 5b.7 9 new Phase 2 codify assertions in `test_visualize_cli.sh` (incl. 3 explicit regression-pins for the in-flight double-path bug fixes); 6 new Phase 1 codify assertions. Full claude-time suite: 174/174 (was 165 pre-WP5b).
- [x] **Plus** opportunistic plumbing not in plan: `DataWindowContext` (cleaner than prop-drill), `SegmentBar` `dayOffset` prop, `InterruptHairlines` `dayOffset`, `Minimap.allSegs` pre-shift, `SessionRow` `key={s.day_iso}:${s.id}` to prevent React duplicate-key warnings, `viz_render.py` wrapper consolidated to call `_initialViewport()` (eliminates double-path drift).

**Why XL:** This is genuinely large — viewport state, pixel-from-viewport math touching every segment renderer, gesture handling across mouse + trackpad + keyboard, ruler adaptive ticks, minimap, performance work, plus testing infrastructure for interactive behavior. Splitting into smaller WPs would be possible (pan, zoom, minimap, keyboard as 4 separate WPs) but the integration risk is in the *interaction* between them — single WP keeps that owned.

**Phase 1 → Phase 2 rationale:** Once the timeline is zoomable/draggable, the view-mode buttons (Day / Week / Month / Custom) become "presets that set initial viewport range," and the navigation primitive is shared. Building those views first then retrofitting them to use a viewport would be wasted work.

---

## Phase 2: View modes and navigation

**Phase rationale:** Build out the four view modes on the now-shared viewport infrastructure. "Today" is renamed to "Day" here too. Filter chips become functional in the same phase because they share the per-view re-render path.

### WP6: "Today" → "Day" rename — [x] SHIPPED 2026-05-23 (commit 217cfe3)
**Description:** Toolbar tab label rename + any internal references (the data layer's `today` key in `window.CT_DATA` is fine to keep as a stable contract or rename to `day` — decide in WP3 and propagate). Touch the README usage section too.
**Phase:** 2
**Dependencies:** —
**Size:** XS
**Tasks:**
- [x] 6.1 Updated toolbar tab label in `viz_render.py::InteractiveToolbar` (line 414): `tabBtn('Today', 'day', ...)` → `tabBtn('Day', 'day', ...)`, plus the section comment.
- [x] 6.2 **Decision: keep `window.CT_DATA.today`** as the data-layer key (UI-only rename). Rationale: WP5b stabilized six consumers (`_initialViewport`, `SessionRow`, `DayTimeline.dwCtx`, `Minimap.allSegs`, `viz_render.py` wrapper, `claude-time:586`) on the `.today.*` shape. Renaming the key would touch all six with no functional benefit; WP3's `meta.start/end` escape hatch keeps a future data-key rename cheap if needed. Documented as inline comment in `viz_render.py` above the View tabs section.
- [x] 6.3 Updated `README.md` line 157 ("The `Day` and `Week` toolbar tabs are interactive"). Lines 81/134 (CLI-side `report`/default `visualize` prose) intentionally left untouched.
- [x] 6.4 Added 3 WP6 codify assertions to `test_visualize_cli.sh` (59 → 62 PASS): positive consuming-surface pin on the shipped `tabBtn('Day', 'day', view === 'day', true)`, negative regression-pin against the legacy `tabBtn('Today',...)` form, and a data-layer `.today` preservation pin.
- **Plan-defect caught at F9 back-loop:** initial 5 leaves edited only `viz/dashboard.jsx::Toolbar` (design-canvas static prototype, dead from shipped-UI perspective — `viz_render.py` strips it at emit). Verify-auto caught it via grep miss on `activeRange={isDay ? 'day' : 'week'}`. F9 added P1.6 + P1.7 to edit the actual shipped `InteractiveToolbar`. Lesson: the WBS task 6.1 text "the emit-time-appended interactive Dashboard wrapper, not the byte-pinned source" was correct but the plan mis-mapped it.

### WP7: Month view — [x] SHIPPED 2026-05-24 (commit ce1c7ec)
**Description:** Calendar-month rollup — 7-column Mon-first grid where each day-cell is a GitHub-contribution-graph-style single-tile encoding daily intensity via monochrome saturation (active-blue 268° hue, 5 buckets + empty). Click-day → reload-redirect toast with `claude-time visualize --date YYYY-MM-DD` (file:// dashboard has no server to navigate to). Reuses WP3's `build_range_data` for the data layer; emit-time pre-loads two months (active + prev) so prev-arrow nav is a pure client-side state swap.
**Phase:** 2
**Dependencies:** WP3, WP5 (both shipped)
**Size:** L (2 phases shipped: CLI `--month` flag + two-month payload emit; MonthView UI + nav + URL hash + toast reload-redirect)
**Tasks:**
- [x] 7.1 `MonthView` component in `viz/dashboard.jsx`: 7-column Monday-first calendar grid, leading/trailing padding cells inert, day-of-week header row (MON–SUN), today highlighted with `CT_TOKENS.active` border. Cell rendering = single-tile monochrome `_intensityColor(intensity)` via 6-entry `_MONTH_INTENSITY_PALETTE` (empty + 5 oklch buckets in 268° hue), `aspectRatio: '2 / 1'` (fits-in-viewport-height contract — user-tuned at verify-human from initial 1.7:1). **Design-decision pivot:** initial spec D5 was per-project vertical-strip density; rejected at verify-human in favor of D5' single-tile monochrome — Month view's primary axis is 1D "how busy was this day", not 2D project composition (Day view answers that via drill-down).
- [x] 7.2 Click-day handler: `onDayClick(iso)` → `MonthNavToast` with `claude-time visualize --date YYYY-MM-DD` command + auto-clipboard-copy (P2.5 resolution — file:// dashboard can't navigate-redirect, so non-modal toast + clipboard is the honest UX). Same reload-redirect mechanism for next-month and prev-of-prev nav.
- [x] 7.3 Month toolbar tab enabled (`tabBtn('Month', 'month', view === 'month', true)`; was `false, false`). URL hash carries `view=month;month=YYYY-MM` per CLAUDE.md hash schema. Four-branch hash dispatcher (day/week/custom/month) with default-elision — `month` key dropped when `view !== 'month'`.
- [x] 7.4 Empty-day rendering: `data-month-day-active="false"` + bucket-0 background (`oklch(0.965 0.005 268)` — barely-tinted) + `title="no tracked time"` tooltip. Visually distinct from even the lowest non-zero bucket.
- [x] 7.5 Cross-month nav: prev-month arrow does client-side state swap (D1, instant — reads from pre-loaded `window.CT_DATA.months[prev_iso]`); next-month + prev-of-prev trigger `MonthNavToast` reload-redirect with `--month YYYY-MM` command. `‹` `›` arrows in the month-name pill inside the dateLabel slot when `view === 'month'`.
- [x] 7.6 Test coverage: 17 source-shape pins in `test_visualize_cli.sh` (WP7-P2-1 through -17) + 6 behavioral pins in `test_visualize_interactive.js` via new `renderMonthDashboard()` helper. Plus Phase 1: 13 source-shape pins (WP7-P1-1 through -13). Net +36 assertions across the WP7 cycle; 264/0 full claude-time suite at ship.
- **Plus** opportunistic in-flight: one obsolete-test triaged + updated mid-codify (WP8-P2-8 three-branch hash dispatch → four-branch); one stale session-pause marker removed from `wbs.md`; D6 fallback (when `--month` is set, `data.today` is the active-month payload so Day/Week tabs in Month-emit mode have a coherent payload to render).

### WP8: Custom-range view — [x] SHIPPED 2026-05-24 (commit 14a1cfc)
**Description:** "Pick a start date and end date" tab. With WP5's viewport already supporting pan/zoom over arbitrary ranges, this is mostly UI: a date-range picker and toolbar tab.
**Phase:** 2
**Dependencies:** WP3, WP5 (both shipped)
**Size:** M (2 phases shipped: CLI `--range` flag + range-aware emit; UI Custom tab + date-range picker + URL-hash round-trip)
**Tasks:**
- [x] 8.1 Date-range picker UI component — `RangePicker` in `viz/dashboard.jsx` (two `<input type=date>` controls + "→" separator, `data-range-picker="start"|"end"` Playwright-stable selectors, buffer-then-commit on blur/Enter, native browser date-picker behavior).
- [x] 8.2 Toolbar: Custom tab enabled (`tabBtn('Custom', 'custom', view === 'custom', true)`), URL hash carries `view=custom;range=YYYY-MM-DD:YYYY-MM-DD` per the CLAUDE.md hash schema (semicolon separator, `range` key value is colon-joined start:end, default-elision drops both keys when view==='day').
- [x] 8.3 Range validation: client-side `validateRange` helper mirrors Python's `_parse_range_flag` rules (shape, end>=start, end<=today, days<=`window.CT_MAX_RANGE_DAYS`). Invalid input gets red border (`#c84a4a`) + tooltip naming the rule. `viz_custom_range_max_days` config key (default 90) is single-sourced from Python via `{{CT_MAX_RANGE_DAYS}}` template placeholder.
- [x] 8.4 Empty-range message: `EmptyState` component reused with custom date string (`${range.start} to ${range.end}`). Produces "No tracked time on 2026-05-20 to 2026-05-22" for empty Custom view.
- [x] 8.5 CLI parity: `claude-time visualize --range 2026-05-01:2026-05-07` flag wired through `_cmd_visualize` to `build_range_data`. Sets `initial_view = "custom"` in the emitted HTML. Mutual-exclusion with `--demo`; warning when combined with `--context-days-*`. New `_parse_range_flag` helper with rule-naming stderr messages on rc=2 failures.
- [x] 8.6 `test_visualize_cli.sh` assertions: 25 new WP8 pins (14 Phase 1 + 11 Phase 2; suite went 76 → 102) covering --help flag listing, validation paths, mutual-exclusion + warning, config cap override, CT_INITIAL_VIEW="custom" emit + opt-in regression, range-shape vs single-day distinction, RangePicker presence + data-range-picker selectors, validateRange + 4 rule messages, isCustom/isDayLike constants, Toolbar range-props handshake, _initView IIFE hash priority, range state hash-restore, view+range three-branch hash-write, isDayLike consumer surfaces (9), EmptyState range-string format. Plus P1.disc.1: hardened the flag-count regex in test #1 against wrapped help-text false-matches (column-3 + EOL/space anchor).

### WP9: Interactive filter chips — [x] SHIPPED 2026-05-23 (commit f5a1123)
**Description:** Toolbar filter chips ("active", "reading", "thinking", "away", "subagent") become functional toggles. Off-state hides that segment kind across all rows. Bonus: per-project filter chip popover (toggle individual projects on/off). Bundled bonus: Phase 1 collapsed the design-canvas/InteractiveToolbar duality (resolves `SURFACE-2026-05-23-CLAUDE-TIME-VIZ-DESIGN-CANVAS-INTERACTIVE-TOOLBAR-DUALITY`) — viz_render.py::InteractiveToolbar deleted; the canonical Toolbar now lives in viz/dashboard.jsx. Future toolbar-touching WPs (WP10, WP12) edit a single file.
**Phase:** 2
**Dependencies:** WP3, WP5 (viewport-aware render path)
**Size:** S (5 phases shipped: duality collapse + functional chips + URL-hash persistence + per-project popover + codify-cleanup-superseded)
**Tasks:**
- [x] 9.1 Wire chip click handlers in the appended interactive Dashboard wrapper; state lives in `useState`. **Surface:** the static `<Legend />` was upgraded into clickable kind-chips (`data-filter-kind=<kind>` + `data-filter-on=true|false`) — not Toolbar, per documented plan deviation (Toolbar stays clean for view + date controls; filter affordances cluster near the Legend).
- [x] 9.2 Segments + per-row totals consume filter state when rendering. `SegmentBar` returns null when its kind is OFF (per-segment hide preserves layout stability). `SessionRow.totalActive` is filter-aware via `session.segs.filter(s => filterKinds[s.kind] !== false)`. **Note:** headline stats (WP10/WP11) will consume `useFilter()` when they ship — wiring is in place.
- [x] 9.3 URL hash carries `filters=active,subagent` (canonical-order serialization: `active,reading,thinking,subagent,away`) per CLAUDE.md "Claude-time visualize URL-hash state" schema. Default-elision drops the key when all kinds are ON. Hash-restore on init + debounced 100ms write on change + replaceState (no history pollution) + malformed-hash fallback to all-ON.
- [x] 9.4 Per-project filter popover: new `ProjectFilterPopover` component next to Legend chips, IconFilter + "Projects" trigger button with hidden-count badge, floating panel with checkbox list, outside-click dismiss via document mousedown listener. Scope: Day view only (WeekTimeline's rollup aggregation deferred to a future WP).
- [x] 9.5 `test_visualize_cli.sh` assertion: emitted HTML contains the filter state machine. Landed as **14 WP9-prefixed assertions** (62 → 76 PASS) distributed across per-phase verify-codify: P1 (2 — Toolbar duality), P2 (3 — data-kind + Legend kinds + FilterContext+filterKinds), P3 (4 — hash.filters + updateHash + default-elision + canonical-order), P4 (5 — ProjectFilterPopover + trigger + item + mousedown listener). Plus **12 behavioral Playwright assertions** in `test_visualize_interactive.js` (10 → 22 PASS) covering hash round-trip + popover open/uncheck/restore/outside-click. Plus **6 NEW unit tests** in `test_viz_render.py` for the in-phase `_strip_design_wrapper` regex fix (dash-count drift + prose-mention false-match guard).

**Phase 2 → Phase 3 rationale:** Once Day/Week/Month/Custom + filters all share the same viewport and data layer, the value-add features (headline stats, comparison view, multi-instance overlap, away totals, project pills, collapsible rows) layer cleanly on top without depending on view-specific code.

---

## Phase 3: Self-awareness — headline, comparison, density

### WP10: Headline-stats card → Metrics surface — [x] SHIPPED 2026-05-24 (commit fc4fe2a)
**Description:** A small card pinned above the timeline that answers "how much real work today" in one number — primary metric (active+subagent time), with secondary metrics (#sessions, #projects touched, longest streak, away total). Card adapts to view: day shows "today vs your trailing-7-day median"; week shows weekly aggregate; custom shows range total. **At spec, bundled with `SURFACE-2026-05-24-CLAUDE-TIME-VIZ-AGGREGATE-METRICS-PANEL`** — what shipped is a **metrics surface** (headline card + expandable 6-metric panel with wall-clock/effort-time/×multiplier columns), not the simpler sparkline-headline originally planned. The trailing-7-day window is view-mode-independent (not per-view-adaptive deltas as originally specced) — comparison-axis work moves to WP11. Sparkline deferred (the wall-clock vs effort-time table replaces it as the primary trend surface).
**Phase:** 3
**Dependencies:** WP4 (comparison helpers for the trailing-median delta) — note: trailing-median delta dropped at spec; window became fixed trailing-7-days
**Size:** M (delivered as 2 phases — aggregator + UI)
**Tasks:**
- [x] 10.1 `HeadlineCard` component above the timeline with three primary tiles (active session wall-clock, human activity wall-clock, AI effort) + chevron toggle + date-range indicator "Past 7 days · YYYY-MM-DD → YYYY-MM-DD" (moved to card via P2.verify-human.2 back-loop).
- [x] 10.2 Trailing-7-day window: today + prior 6 days, computed at emit time from `snapshot_dt`, view-mode-independent (Day/Week/Month/Custom all show same metrics). View-adaptive deltas dropped at spec; comparison axis moves to WP11.
- [x] 10.3 ~Sparkline mini-chart~ → Replaced by `MetricsPanel` (expanded) with 6-section table: engaged_session, ai_agent (+ subagent sub-row), tool_call (+ top-5 tools sub-table), human (+ typing/reading/thinking sub-rows), concurrency (k=1/2/3/4+ stratification), blocking (human-blocking-agent + agent-blocking-human). Each row shows wall-clock | effort-time | ×multiplier.
- [x] 10.4 Filter-state aware via `_computeMetricsView(metrics, filterKinds)` projection helper. Kind chips affect both headline + panel cells; `subagent` OFF drops AI-effort by the subagent contribution; `reading`/`thinking` OFF drop human activity. `active` OFF collapses everything to 0.
- [x] 10.5 `test_visualize_cli.sh` + `test_visualize_interactive.js` assertions: 15 source-shape pins (WP10-P2-1..15) covering component definitions, data-metrics-card / data-metric-tile=* / data-metric-section=* selectors, hash dispatcher, empty-window caption, window indicator; 9 behavioral pins covering chevron expand/collapse + hash round-trip + filter chip → AI-effort tile change + window indicator persists across collapse/expand + card mounted across view-mode switches. Plus 2 codify integration-boundary pins on Phase 1 (real-DB events → aggregator → emit pipeline with seeded burst+tool, trailing-7-day window math). Plus 38 Python unittests (13 reclassify interval-helpers + 18 BuildMetricsTests + 7 BuildMetricsReconciliationTests). Full claude-time suite 335/0 PASS at ship; structure check 122/0 PASS.

### WP11: Comparison view (delta lens)
**Description:** Dedicated view (toolbar tab or modal) showing two windows side-by-side: per-project deltas, per-kind deltas, "you spent 2h more on `replicator-1-0` this week" callouts. Initial form: a stacked bar chart per project comparing A and B + a delta column.
**Phase:** 3
**Dependencies:** WP4, WP9 (filter chips apply to both sides)
**Size:** L
**Tasks:**
- [ ] 11.1 `CompareView` component — accepts `{a, b, deltas}` from `build_comparison_data`
- [ ] 11.2 Three layout slots: per-project comparison rows (one per project, A bar above B bar), per-kind aggregate (active vs away vs reading deltas across whole window), top-shifts callouts ("`my-thing`: +2h 15m vs trailing week median")
- [ ] 11.3 Comparison-preset toolbar: "Week over week" / "Today vs trailing week" / "This month vs last month" / "Custom A vs B" (custom uses two range pickers)
- [ ] 11.4 CLI flag: `claude-time visualize --compare wow` (week-over-week), `--compare today-vs-median`, `--compare-range A:B`
- [ ] 11.5 `test_visualize_cli.sh` assertions: emitted HTML contains CompareView when invoked with `--compare`; CLI flags work end-to-end

### WP12: Multi-instance overlap visualization
**Description:** When two sessions ran in parallel on the same wall-clock minute (you had two Claude Code instances open), the dashboard currently renders them on separate session rows but doesn't visually distinguish "parallel" from "sequential." Add an explicit overlap rendering: in expanded-project (per-session) view, overlapping bars are visually layered with a slight vertical offset + an "overlap" badge in the side panel. The reclassifier's cross-session typing-debit attribution already handles the data correctly — this is a visualization layer only.
**Phase:** 3
**Dependencies:** WP3 (so multi-day ranges can show overlaps that span days), WP13 (collapsed-row overlap semantics)
**Size:** M
**Tasks:**
- [ ] 12.1 Detect overlapping sessions at render time: two session windows overlapping in time within the visible viewport
- [ ] 12.2 Visual: overlapping segments get a slight vertical offset (half-height stagger) so both are visible; tooltip says "overlapping with session XXX"
- [ ] 12.3 Side panel: when a session overlaps with one or more others, add an "Overlaps with" section listing the other sessions
- [ ] 12.4 Headline stats: "X minutes of parallel work" stat when overlaps exist in the current view
- [ ] 12.5 `test_visualize_cli.sh` assertion against a seeded DB with synthetic overlapping sessions: emitted HTML renders the overlap indicator

### WP13: Collapsible project rows + idle/away total visibility + project pills
**Description:** Three small UX wins bundled because they touch the same layout primitives:
(1) Project rows default to **collapsed** (one row per project, segments from all that project's sessions merged into one track via overlay/blend). Click chevron to expand to per-session rows. Multi-instance overlap (WP12) handles the overlapping-segment case by rendering parallel session segments at slight vertical offsets even within the collapsed row.
(2) Per-project **total pill** at the left of each row (active+subagent time, in monospace), per spec user story #5. Confirms the "where did the hours go" question at a glance.
(3) **Idle/away total** rendered next to the headline stats and per-project pills — the counterweight to active time. "Away: 3h 12m" makes the day total honest.
**Phase:** 3
**Dependencies:** WP1, WP9 (filter state)
**Size:** M
**Tasks:**
- [ ] 13.1 Collapsed-row segment merging: union of all session segments within a project, rendered as a single track (segments may overlap visually when multi-instance — handled in WP12 via vertical offset semantics within the lane)
- [ ] 13.2 Per-row chevron + expand/collapse state (`useState`, defaults to collapsed); URL hash carries `expanded=project1,project2`
- [ ] 13.3 Project total pill on row label: monospace `1h 23m` cell + project name + chevron
- [ ] 13.4 Away-total surfaced in two places: (a) per-project row label as a secondary stat under the active total, (b) headline-stats card alongside the main active number
- [ ] 13.5 Filter-state aware: pills and totals reflect active filter chips
- [ ] 13.6 `test_visualize_cli.sh` assertions: collapsed-row default, expand-on-click, pill content, away-total presence

**Phase 3 → cycle close rationale:** Once these are in, the v2 UX answers all the questions v1 left implicit: how much active vs idle, what changed week over week, where did parallel instances overlap, where are the per-project totals at a glance.

---

## Dependency Map

```
WP1 (adaptive ruler) ─┬─→ WP5 (zoomable timeline) ─┬─→ WP7 (month view)
                      │                            ├─→ WP8 (custom range)
                      │                            └─→ WP9 (filter chips)
WP2 (NOW marker)      │                                    │
                      │                                    ▼
WP3 (range data) ─────┴─→ WP4 (comparison data) ─→ WP11 (compare view)
                                                  └─→ WP10 (headline stats)

WP6 (Day rename) ────────────────────────────────────→ (no deps; can land any time in Phase 2)
                                                       │
WP12 (multi-instance overlap) ←──────── WP13 (collapsible rows + pills + away total)
                              └─ depends on WP3 + WP9
```

**Critical path:** WP3 → WP5 → WP7/8/9 → WP11/13 → WP12.

**Parallelizable:** WP1, WP2, WP6 (each independent, small).

**Highest-risk WP:** WP5 (XL, performance-sensitive, interaction-heavy). Recommend tackling it early in Phase 1 and budgeting time for one feature-build → verify-self → back-loop cycle on the gesture/perf surface specifically.

---

## Sizing summary

| Phase | WPs | Size mix | Rough magnitude |
|-------|-----|---------------|-----------------|
| 0     | WP1–4 | XS, S, M, S | small-to-medium foundation |
| 1     | WP5 | XL | one large WP (gated milestone) — SHIPPED 2026-05-22 |
| 2     | WP5b, WP6–9 | S–M, XS, L, M, S | medium phase, 5 WPs (WP5b added 2026-05-22 — user-prioritized Day-view extension) |
| 3     | WP10–13 | M, L, M, M | medium phase, 4 WPs |

14 work packages total (was 13; +1 for WP5b — multi-day data window for Day view, added at WP5 finalize). No probe WPs needed — no new 3rd-party integrations; React/Babel/SQLite/Python are all already in use.

---

## Decisions locked at WBS approval (2026-05-19)

- **Claude Design extract is now reference-only.** Source edits to `viz/dashboard.jsx`, `viz/data.js`, etc. are permitted starting with WP1. The byte-pin design-as-data convention (introduced 2026-05-19 in `CLAUDE.md`, enforced by `tests/check-structure.sh` Phase 5c) is **superseded** by this cycle. WP1's build will (a) remove or relax the Phase 5c byte-size pinning, (b) update the `CLAUDE.md` convention to document the v2 shift and the rationale, (c) re-import additional assets from the design extract if and only if a downstream WP genuinely needs them.
- **URL-hash state convention.** WP5's first task drafts the URL-hash-state spec (key shape, merge semantics for multi-WP state coexistence, reload behavior), codifies it in `CLAUDE.md`, and downstream WPs (filters, view tabs, expanded projects, viewport) follow it.
- **Drive mode for this cycle:** Autopilot (pause only at verify-human per the standard policy).

## Notes / open questions

- **Performance ceiling.** WP5's 60fps pan/zoom with a 1-month range may push the DOM-per-segment approach to its limit. If `requestAnimationFrame` throttling isn't enough, fall back to canvas-rendering for the timeline (DOM stays for tooltips + side panel). Decide at WP5 verify-self time, not at plan time — measure first.

---

## Next step

Per the project's convention: this repo skips `/product-context` (the project has a hand-maintained `CLAUDE.md` that serves the equivalent purpose). After WBS review, this cycle transitions directly to **feature workflows** — start with WP1 (smallest, validates the dev loop) via `/feature-plan`, then WP2 and WP6 in parallel, then tackle WP5 as the gated milestone.

When all 13 WPs are marked `[x]` by `feature-finalize` runs, `/product-finalize` will resync durable docs, sweep backlog, and archive this WBS to `docs/product/archive/claude-time-visualize-v2/`.
