---
stage: wbs
state: in-progress
updated: 2026-05-19
cycle: claude-time-visualize-v2
---

# WBS — `claude-time visualize` v2

## Context

`claude-time visualize` shipped its MVP on 2026-05-19 (day view + week view, snapshot per invocation, single full-bleed dashboard, click-bar-for-side-panel). Real-data usage immediately surfaced a cluster of gaps that map cleanly to (a) the spec's deliberately-deferred "Out of Scope" items, (b) UX affordances the snapshot model doesn't satisfy, and (c) one critical timeline-navigation feature missing from v1 (zoomable / draggable multi-track timeline, audio-editor style).

This WBS bundles those gaps into a single cycle. It is **not** a continuation of the workflow-system roadmap (which is a separate product) — it's a new product cycle for the `claude-time` tool that lives in this repo.

## Scope

**Included (11 work packages):**
- Adaptive hour-ruler (consume existing `hour_range` field)
- Zoomable + draggable multi-track timeline ⭐ **critical / foundational**
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

### WP3: Range-aware data layer — `build_range_data(start_iso, end_iso)`
**Description:** Extract a single `build_range_data(start, end)` from the current `build_day_data` / `build_week_data`. The new function emits the same project/session/segment shape over any arbitrary `[start, end]` window. Day / week / custom / month all become thin wrappers that compute `(start, end)` and call this.
**Phase:** 0
**Dependencies:** —
**Size:** M
**Tasks:**
- [ ] 3.1 Refactor `viz_data.py`: extract `build_range_data(start_iso, end_iso, *, db_path, aliases)` as the single core
- [ ] 3.2 Re-implement `build_day_data` and `build_week_data` as wrappers
- [ ] 3.3 Decide range-aware `hour_range` semantics for multi-day ranges (likely: emit per-day `hour_range` map + a global `day_window` for the overall ruler)
- [ ] 3.4 Add `meta: {start, end, day_count}` to the emitted JSON so the JS layer knows the window shape
- [ ] 3.5 Update `test_viz_data.py` — keep existing 22 assertions PASSing (no regression), add ~5 new `BuildRangeDataTests` for cross-day windows

### WP4: Comparison data layer — `build_comparison_data(window_a, window_b)`
**Description:** Emit a side-by-side data payload for two windows (e.g., this-week vs last-week, today vs trailing-7-day median, this-month vs last-month). Per-project totals + per-segment-kind totals for both windows, ready to render as a delta lens.
**Phase:** 0
**Dependencies:** WP3
**Size:** S
**Tasks:**
- [ ] 4.1 `build_comparison_data(a_start, a_end, b_start, b_end, *, kind={absolute|relative})` returning `{a: {...}, b: {...}, deltas: {project: {kind: {abs_min, rel_pct}}}}`
- [ ] 4.2 Helper builders for common comparisons: `compare_week_over_week()`, `compare_day_vs_median(window_days=7)`
- [ ] 4.3 Unit tests for comparison math (empty-A, empty-B, identical, regression cases) in `test_viz_data.py`

**Phase 0 → Phase 1 rationale:** Once the data layer can emit any window + comparisons, the UI work in Phases 1–3 doesn't have to re-touch Python. This is the standard "backend before frontend wraps" ordering applied at the v2 boundary.

---

## Phase 1: Critical UX foundation — zoomable / draggable timeline

**Phase rationale:** This is the user-designated **critical feature** for v2 ("the UX that matters most"). It is also load-bearing for custom-range, month view, and the renamed Day tab. Land it before adding more views so each view inherits the same interaction model rather than each phase reinventing pan/zoom.

### WP5: Zoomable + draggable multi-track timeline ⭐
**Description:** Reshape the timeline component into a horizontally-scrollable, zoomable canvas — audio/video-editor metaphor. Drag the ruler to pan; mouse-wheel / pinch / keyboard `+/-` to zoom in/out on the time axis (project rows stay vertically stationary). Visible window is independent of the underlying data window — load the broadest reasonable range, then pan/zoom within it. Replaces the current "fit the day to the available width" approach.
**Phase:** 1
**Dependencies:** WP1 (adaptive ruler math), WP3 (data layer can emit broader-than-day windows)
**Size:** XL
**Tasks:**
- [ ] 5.1 Introduce `ViewportState` ({visible_start_min, visible_end_min, zoom_level}) in the Dashboard wrapper; bind to URL hash so a zoom-in survives reload
- [ ] 5.2 Replace `pct()` math: segments compute pixel positions from the *viewport*, not the *day window*. Off-viewport segments are clipped or absent.
- [ ] 5.3 Pan: drag-on-ruler / drag-on-empty-row updates `visible_start_min` while preserving `visible_end_min - visible_start_min` (the zoom level). Cursor-affordance: `grab` / `grabbing`.
- [ ] 5.4 Zoom: mouse-wheel + ctrl/cmd, pinch gesture, keyboard `+`/`-`/`0` (reset). Zoom-anchored at cursor x-position (audio-editor convention).
- [ ] 5.5 Ruler tick density adapts to zoom: 1h ticks at full-day view, 30m → 10m → 5m → 1m as user zooms in.
- [ ] 5.6 Performance budget: 60fps pan/zoom with a 1-month range loaded and all segments visible. Throttle to `requestAnimationFrame`; consider canvas-render fallback if DOM-per-segment hits a ceiling.
- [ ] 5.7 Minimap / overview-bar at the bottom showing the full data window + a draggable "what's visible" rectangle. Standard audio-editor affordance for re-orienting after deep zoom.
- [ ] 5.8 Keyboard shortcuts: arrow-left/right to pan by 10% of visible width, `Home`/`End` to jump to data start/end, `0` to reset zoom.
- [ ] 5.9 `test_visualize_cli.sh` smoke assertions: emitted HTML contains viewport-state code paths (`ViewportState`, `visible_start_min`, wheel-event handlers)
- [ ] 5.10 Playwright behavioral test (new `test_visualize_interactive.sh` or extension): click ruler, drag, assert visible window changed; mouse-wheel, assert zoom changed.

**Why XL:** This is genuinely large — viewport state, pixel-from-viewport math touching every segment renderer, gesture handling across mouse + trackpad + keyboard, ruler adaptive ticks, minimap, performance work, plus testing infrastructure for interactive behavior. Splitting into smaller WPs would be possible (pan, zoom, minimap, keyboard as 4 separate WPs) but the integration risk is in the *interaction* between them — single WP keeps that owned.

**Phase 1 → Phase 2 rationale:** Once the timeline is zoomable/draggable, the view-mode buttons (Day / Week / Month / Custom) become "presets that set initial viewport range," and the navigation primitive is shared. Building those views first then retrofitting them to use a viewport would be wasted work.

---

## Phase 2: View modes and navigation

**Phase rationale:** Build out the four view modes on the now-shared viewport infrastructure. "Today" is renamed to "Day" here too. Filter chips become functional in the same phase because they share the per-view re-render path.

### WP6: "Today" → "Day" rename
**Description:** Toolbar tab label rename + any internal references (the data layer's `today` key in `window.CT_DATA` is fine to keep as a stable contract or rename to `day` — decide in WP3 and propagate). Touch the README usage section too.
**Phase:** 2
**Dependencies:** —
**Size:** XS
**Tasks:**
- [ ] 6.1 Update toolbar tab label in `viz_render.py`'s `InteractiveToolbar` block (the emit-time-appended interactive Dashboard wrapper, not the byte-pinned source)
- [ ] 6.2 Decide: rename `window.CT_DATA.today` → `window.CT_DATA.day` or keep for stability. Update WP3's `meta.start/end` so the view layer can read window-bounds without depending on the key name.
- [ ] 6.3 Update `README.md` usage examples
- [ ] 6.4 `test_visualize_cli.sh` assertion: emitted HTML contains the "Day" toolbar label and not "Today"

### WP7: Month view
**Description:** Renders a calendar-month rollup — likely a 5-week or 6-week grid where each cell is a day-mini-bar showing per-project segment proportions (color blocks summing to that day's active time). Click a day → zoom-in to that day in Day view. Reuses WP3's range-aware data layer (one call for the whole month).
**Phase:** 2
**Dependencies:** WP3, WP5 (so click-to-zoom uses the viewport mechanic)
**Size:** L
**Tasks:**
- [ ] 7.1 New `MonthView` component: 7-column calendar grid, weeks as rows, day-cell renders mini-stacked-bar of active-time-by-project
- [ ] 7.2 Click-day handler: switches to Day view + sets viewport to that day's range
- [ ] 7.3 Toolbar: "Month" tab becomes active button (was `disabled` in v1); URL hash carries `view=month&month=YYYY-MM`
- [ ] 7.4 Empty-day rendering: dim cell, "no tracked time" tooltip on hover
- [ ] 7.5 Cross-month nav: previous-month / next-month arrows in toolbar
- [ ] 7.6 `test_visualize_cli.sh` assertion: emitted HTML contains MonthView code + "Month" toolbar label is no longer `disabled`

### WP8: Custom-range view
**Description:** "Pick a start date and end date" tab. With WP5's viewport already supporting pan/zoom over arbitrary ranges, this is mostly UI: a date-range picker and toolbar tab.
**Phase:** 2
**Dependencies:** WP3, WP5
**Size:** M
**Tasks:**
- [ ] 8.1 Date-range picker UI component (two `<input type=date>` for MVP, no fancy popover; fancy can come later)
- [ ] 8.2 Toolbar: "Custom" tab becomes active button; URL hash carries `view=custom&start=YYYY-MM-DD&end=YYYY-MM-DD`
- [ ] 8.3 Range validation: end >= start, end <= today (no future), reasonable max (90 days?) to avoid renderer brownouts at low zoom
- [ ] 8.4 Empty-range message: "No tracked time in 2026-05-01 to 2026-05-07."
- [ ] 8.5 CLI parity: `claude-time visualize --range 2026-05-01:2026-05-07` flag matching the UI's custom-range
- [ ] 8.6 `test_visualize_cli.sh` assertions: emitted HTML contains range-picker, --range CLI flag works end-to-end

### WP9: Interactive filter chips
**Description:** Toolbar filter chips ("active", "reading", "thinking", "away", "subagent") become functional toggles. Off-state hides that segment kind across all rows. Bonus: per-project filter chip popover (toggle individual projects on/off).
**Phase:** 2
**Dependencies:** WP3, WP5 (viewport-aware render path)
**Size:** S
**Tasks:**
- [ ] 9.1 Wire chip click handlers in the appended interactive Dashboard wrapper; state lives in `useState`
- [ ] 9.2 Segments + per-row totals + headline stats (WP11) all consume the filter state when rendering
- [ ] 9.3 URL hash carries `filters=active,subagent` for sharable filtered views
- [ ] 9.4 Per-project filter popover: collapsible chip listing all projects with on/off toggles
- [ ] 9.5 `test_visualize_cli.sh` assertion: emitted HTML contains the filter state machine

**Phase 2 → Phase 3 rationale:** Once Day/Week/Month/Custom + filters all share the same viewport and data layer, the value-add features (headline stats, comparison view, multi-instance overlap, away totals, project pills, collapsible rows) layer cleanly on top without depending on view-specific code.

---

## Phase 3: Self-awareness — headline, comparison, density

### WP10: Headline-stats card
**Description:** A small card pinned above the timeline that answers "how much real work today" in one number — primary metric (active+subagent time), with secondary metrics (#sessions, #projects touched, longest streak, away total). Card adapts to view: day shows "today vs your trailing-7-day median"; week shows weekly aggregate; custom shows range total.
**Phase:** 3
**Dependencies:** WP4 (comparison helpers for the trailing-median delta)
**Size:** M
**Tasks:**
- [ ] 10.1 `HeadlineStats` component above the timeline; layout: big number left, secondary metrics + sparkline right
- [ ] 10.2 Per-view config: Day default shows "vs trailing-7-day median" delta; Week shows "vs last week" delta; Custom shows range total without delta
- [ ] 10.3 Sparkline mini-chart (7-day active-time history): inline SVG, ~120px wide
- [ ] 10.4 Filter-state aware: headline numbers reflect active filter chips (WP9)
- [ ] 10.5 `test_visualize_cli.sh` assertion: emitted HTML contains HeadlineStats; sparkline svg present

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
| 1     | WP5 | XL | one large WP (gated milestone) |
| 2     | WP6–9 | XS, L, M, S | medium phase, 4 WPs |
| 3     | WP10–13 | M, L, M, M | medium phase, 4 WPs |

13 work packages total. No probe WPs needed — no new 3rd-party integrations; React/Babel/SQLite/Python are all already in use.

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
