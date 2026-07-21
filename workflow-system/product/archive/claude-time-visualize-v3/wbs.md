---
stage: wbs
state: complete
updated: 2026-06-06
cycle: claude-time-visualize-v3
last_wp_shipped: WP12 (2026-06-06) — v3 cycle complete
---

# WBS — `claude-time visualize` v3

## Context

The v2 cycle shipped 11/14 WPs across 2026-05-19 through 2026-05-26, delivering: adaptive ruler, NOW marker, range-aware data layer, comparison data layer, zoomable timeline, multi-day Day view, Day-rename, Month view, Custom-range view, filter chips, metrics surface, and Compare view (effectiveness lens). v2 archived to `docs/product/archive/claude-time-visualize-v2/`.

v3 begins from a user-confirmed pivot surfaced at WP11 verify-human (2026-05-26): the existing **one-CLI-invocation-emits-one-window** model forces re-emit for every sub-view switch and produces a UX surprise where preset sub-tabs don't refresh content. v3 inverts the model: **one CLI invocation emits a 90-day default window with ALL sub-payloads pre-rendered**, and the frontend handles every Day/Week/Month/Compare slice as client-side state swaps. The `--compare`, `--month`, `--range`, `--week`, `--date` flags become advisory (URL-hash dispatched) rather than load-bearing on the emit model.

This unlocks instant Day-arrow nav, instant Week-arrow nav, accurate hash-restore for shareable URLs, and content-refresh on every preset sub-tab click. The trade-off is +~500ms emit time (90-day vs current ~22-day load) and +~200-400KB emit size — both user-confirmed acceptable.

v3 also folds in two v2-deferred WPs (WP12 multi-instance overlap + WP13 collapsible rows / pills / away total) and one v2-surfaced UX problem (`SURFACE-2026-05-26-CLAUDE-TIME-VIZ-DAY-VIEW-ROW-DENSITY` — too many project rows after a week of tracking).

## Scope

**Included (10 work packages, 4 phases):**
- Range-aware emit refactor: 90-day default window, all sub-payloads pre-rendered
- Unified time-range CLI arg (`--window` or similar — decided at spec time)
- Legacy flag removal (`--date` / `--week` / `--month` / `--range` / `--compare*` deleted; `--window` + URL hash cover all use cases)
- URL hash schema extension (back-compat for v2 hash keys + new keys for sub-view state)
- Frontend state-routing refactor: CompareView, MonthView, WeekTimeline, DayTimeline all read pre-rendered sub-payloads instead of `window.CT_DATA.today`
- Instant Day-arrow nav (←/→ between pre-rendered days)
- Instant Week-arrow nav (←/→ between pre-rendered weeks)
- Multi-instance overlap visualization (v2 WP12 carry-over)
- Collapsible project rows (default collapsed) + per-project pills + away-total visibility (v2 WP13 carry-over)
- Row-density mitigation (`SURFACE-2026-05-26-CLAUDE-TIME-VIZ-DAY-VIEW-ROW-DENSITY`)

**Not included (explicitly deferred):**
- Dark theme (still out-of-scope hold from v2; revisit after v3 ships)
- Live auto-refresh / filesystem watcher (out-of-scope hold)
- Pre-transpile JSX / drop unpkg CDN (engineering polish; revisit if v3 page-load gets noticeably slow)
- Export-as-PNG / share affordances (single-user constraint stands)
- Eye-tracking / typing-detection improvements (not viz-side concerns)
- Configurable window size beyond default 90-day (user can use --window for arbitrary; no UI affordance to tune the default)

---

## Phase 0: Data-layer refactor (range expansion + pre-render coordination)

**Phase rationale (learning-sequence):** The v3 emit model is the load-bearing change. Every UI WP downstream depends on the new payload shape. Build the data-layer refactor first; verify shape contracts under unit tests; only then touch the UI. Failure to lock the shape early would force re-render of every UI WP if the shape shifts mid-cycle.

This phase is also the riskiest in terms of emit-time performance (90-day SQLite load + N sub-payload builds). Doing it first quantifies the actual cost and lets us decide whether the 90-day default needs adjustment before downstream WPs accumulate dependencies on it.

### WP1: Unified emit-window coordinator (`build_window_data`) ✅ SHIPPED 2026-05-28 (commit `4dd8d6d`)
**Description:** New top-level coordinator in `viz_data.py` that takes `(window_start_iso, window_end_iso)` and produces the full pre-rendered payload: `{window, day_payloads_by_iso, week_payloads_by_monday, month_payloads_by_iso, compare_payloads_by_preset, metrics}`. Reuses existing `build_day_data`, `build_range_data`, `build_week_data`, `build_comparison_data`, `build_metrics` as worker functions. The coordinator is responsible for: (1) computing which days/weeks/months/compares fall within the window; (2) calling each worker once; (3) attaching results under the canonical sub-payload keys.
**Phase:** 0
**Dependencies:** —
**Size:** M
**Tasks:**
- [x] 1.1 Define `build_window_data(start_iso, end_iso, *, events_by_day, cfg, auto_alias_fn) -> dict` signature in `viz_data.py`. Return shape: `{window: {start, end, day_count}, day_payloads_by_iso: {iso: <build_day_data output>}, week_payloads_by_monday: {monday_iso: <build_week_data output>}, month_payloads_by_iso: {month_iso: <build_range_data output>}, compare_payloads_by_preset: {wow: <build_comparison_data output>, today-vs-trailing: <...>, mom: <...>}, metrics: <build_metrics output for the full window>}`
- [x] 1.2 Per-day loop: for each ISO day in `[start_iso..end_iso]`, call `build_day_data` with that day's events. Attach to `day_payloads_by_iso`.
- [x] 1.3 Per-week loop: for each Monday-anchored week intersecting the window, call `build_week_data`. Attach to `week_payloads_by_monday`.
- [x] 1.4 Per-month loop: for each calendar month intersecting the window, call `build_range_data` over that month's days. Attach to `month_payloads_by_iso` keyed by `YYYY-MM`.
- [x] 1.5 Compare-preset loop: call `compare_week_over_week(today_monday_iso)`, `compare_day_vs_trailing_window(today_iso, 7)`, `compare_month_over_month(today_month_iso)` — using "today" as the anchor (the most-recent day in the window). Attach to `compare_payloads_by_preset` keyed by preset name.
- [x] 1.6 Window-level metrics: `build_metrics(all_events, window_start_dt, window_end_dt)` over the entire 90-day window. Attach as top-level `metrics`. (Per-window-slice metrics for compare presets live inside their `compare_payloads_by_preset[preset].{a,b}.metrics` per v2 WP11 Phase 1.B.)
- [x] 1.7 Add `BuildWindowDataTests` to `test_viz_data.py` — at minimum: empty window, single-day window, full 90-day shape sanity (all 4 sub-payload maps populated, key sets correct), compare-preset cross-reference (top-level `metrics.engaged_session.wallclock_ms` should equal sum of `day_payloads_by_iso[*].today_total` modulo merge semantics).

### WP2: Emit-time perf budget + 90-day default ✅ SHIPPED 2026-05-28 (commit `64fb865`)
**Result:** 90-day default **CONFIRMED**. Measured against `~/.claude-time/events.sqlite`: 90-day window emits in avg 1012ms (target ≤2000ms) at 431KB (target ≤500KB). Cost is approximately flat across 30→120 day windows (dominated by fixed overhead, not per-day work) — window size is approximately free within this range. See `workflow/archive/wp2-emit-perf-probe.md` `## Decision` for full rationale; permanent perf script lives at `tools/claude-time/test/perf_window_data.py` for re-measurement if `viz_data.py` materially changes.

**Description:** Measure the actual emit cost (SQLite load + `build_window_data` total) for a 90-day window against the user's real DB. If within ~2s wall-clock + ~500KB JSON, lock the default. If over, decide between (a) reducing the default window, (b) lazy-loading sub-payloads, (c) deferring compare-preset pre-render.
**Phase:** 0
**Dependencies:** WP1
**Size:** S
**Type:** probe (learning, not a build artifact)
**Learning objective:** Confirm the 90-day default fits the user's "slightly longer load time and larger file size is acceptable" tolerance, OR identify the smaller default that does.
**Timebox:** half-day
**Success criterion:** Documented timing measurement (5 runs, min/avg/max) + emit-size measurement (bytes) + Go/No-Go decision on the 90-day default OR a counter-proposal (e.g., 60 days).
**Tasks:**
- [x] 2.1 Add a perf script `tools/claude-time/test/perf_window_data.py` that runs `build_window_data` over the user's real DB 5 times with varying window sizes (30, 60, 90, 120 days) and reports wall-clock + output JSON byte count.
- [x] 2.2 Run the perf script; record results in a comment block at the top of the script + summarize in the WP retrospect.
- [x] 2.3 Decision: confirm 90-day default OR propose alternative + rationale.

**Phase 0 → Phase 1 rationale:** Once `build_window_data` is shape-locked and perf-validated, every UI WP can rely on the pre-rendered payload existing. Skipping the perf probe risks downstream WPs being built on an emit cost the user later rejects, forcing a Phase-0 rework mid-cycle.

---

## Phase 1: CLI surface refactor (unified time-range + legacy flag removal)

**Phase rationale:** The CLI surface change is downstream of the data layer (the new flag has to produce a `build_window_data` payload to be testable) but upstream of the frontend refactor (the frontend needs the new payload structure to consume). Doing it second isolates the CLI change from frontend state-routing complexity.

### WP3: Unified `--window` flag ✅ SHIPPED 2026-05-29 (commit `b7718ae`)
**Result:** `--window` flag landed with three forms — `MTD-N`, `Nd`, `YYYY-MM-DD:YYYY-MM-DD`. Default is `MTD-2` (current calendar month + 2 priors, calendar-anchored, not rolling-90 — chosen at spec time so Month-view payloads contain full prior months). New config key `viz_window_max_days` default 365 caps explicit ranges. `--window` + `--demo` is rc=2; bare `--demo` preserved. Legacy v2 flags silently no-op'd (WP4 deletes them). `build_window_data` populates legacy alias keys (`today`, `week`, `comparison`, `metrics`, `meta`, `months`) so the v2 frontend keeps rendering until WP5–WP9 wire the sub-payload maps. Final test baseline: `test_visualize_cli.sh` 175/0, Python 130/0, structure pins 125/0.

**Description:** New CLI flag that takes a time-range arg (e.g., `--window 90d`, `--window MTD-2`, `--window 2026-04-01:2026-05-26`) and produces a single-emit pre-rendered 90-day-default dashboard. WP3 introduces `--window` only; WP4 removes the legacy flags (`--date`, `--week`, `--month`, `--range`, `--compare`, `--compare-range`).
**Phase:** 1
**Dependencies:** WP1
**Size:** M
**Tasks:**
- [x] 3.1 Spec the unified time-range arg syntax at feature-spec time. Candidates: `--window 90d` (rolling N days back from today), `--window MTD-2` (month-to-date plus 2 prior months), `--window 2026-04-01:2026-05-26` (explicit range), or a combination. Decision recorded in the feature spec.
- [x] 3.2 Add the new flag to the `viz` subparser. Validation: must produce a `(start_iso, end_iso)` pair with `end >= start` and `end <= today` and `day_count <= viz_window_max_days` (new config key, default 365).
- [x] 3.3 In `_cmd_visualize`, when the new flag is set: load events for the window, call `build_window_data`, emit. The output becomes `window.CT_DATA` with the new shape (sub-payload maps).
- [x] 3.4 Default behavior: when `--window` is not set, default to the 90-day window (or whatever WP2 confirms). Legacy flags are removed in WP4 — WP3 does not need to preserve them.
- [x] 3.5 `test_visualize_cli.sh` pins: `--window 30d` produces a payload with `day_payloads_by_iso` keys covering 30 days; `--window 2026-04-01:2026-05-26` matches explicit bounds; default invocation produces the WP2-confirmed default; mutex with `--demo` (demo data is single-day).

### WP4: Legacy flag removal ✅ SHIPPED 2026-05-29 (commit `04386d9`)
**Result:** v2 flags (`--date`, `--week`, `--month`, `--range`, `--compare`, `--compare-range`, `--context-days-prior`, `--context-days-after`) deleted from `viz` subparser; ~600 LOC of legacy handler branch + helper functions removed; `--demo` absorbed into v3 branch. Net commit: -360 LOC. Two mid-flight discoveries auto-fixed: (a) bulk-delete by line-range accidentally caught a WP3 helper `_parse_window_arg`, recovered from git HEAD; (b) Phase 1 silently dropped `comparison.{a,b}.metrics` on real-DB emit (v2's CLI-layer attachment was deleted; `build_window_data` didn't replace it), caught at Phase 3 codify and fixed by attaching metrics at the data-layer (right architectural home). Final test baseline: CLI 178/0, Python 131/0, interactive 46/0, structure 125/0. Backlog discoveries `SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER` (filed at Phase 1 build) + Test Triage entries in archived WIP.

**Description:** Existing v2 flags (`--date`, `--week`, `--month`, `--range`, `--compare`, `--compare-range`) are removed from the `viz` subparser entirely. The unified `--window` flag (WP3) plus URL-hash dispatch (Phase 2) cover every use case. Single-user tool, no external consumers — clean removal is preferable to a deprecation-alias surface.
**Phase:** 1
**Dependencies:** WP3
**Size:** S
**Tasks:**
- [x] 4.1 Delete the legacy flag definitions from the `viz` subparser. Remove their handler branches in `_cmd_visualize`.
- [x] 4.2 Update `--help` text and any in-tree usage docs (README sections, comments) to reference only `--window`.
- [x] 4.3 `test_visualize_cli.sh`: delete the legacy-flag scenarios; replace with `--window`-based equivalents where the underlying behavior is still in scope. Removed flags should produce an argparse error (rc=2) — pin one such case to confirm.

**Phase 1 → Phase 2 rationale:** Once the CLI surface stably produces the new payload shape via `--window`, the frontend can be refactored to consume it. Doing the frontend refactor in Phase 1 would force the CLI surface to be designed against an unstable consumer.

---

## Phase 2: Frontend state-routing refactor

**Phase rationale:** The dashboard currently dispatches on `window.CT_INITIAL_VIEW` + `window.CT_INITIAL_PRESET` to pick a single view from a single payload. v3 changes this to: hash dispatches to a view + sub-view-state, and each view reads the appropriate pre-rendered sub-payload from `window.CT_DATA.<sub_payload_map>[<key>]`. This phase touches every view component (Day, Week, Month, Custom, Compare) but leaves their internal rendering largely unchanged — only the **data-source plumbing** changes.

### WP5: Day view sub-payload routing ✅ SHIPPED 2026-06-03 (commit `820cba7`)
**Result:** Day view migrated off the v2 `today` alias key onto `day_payloads_by_iso[dayIso]`. New ‹/› buttons in the toolbar's date strip drive client-side swaps between pre-rendered days, disabled at window boundaries. New `date=YYYY-MM-DD` URL hash key with default-elision when `dayIso === window.end`. The `today` alias key stays populated by the CLI for v2-frontend coexistence through WP9. Test baselines at ship: CLI 178 → 182 (+4 source-shape pins), interactive container 46 → 55 (+9 behavioral pins), Python 131/0, structure 125/0. Two Test Triage entries handled in-phase: (a) existing five-branch hash-dispatch pin obsolete due to new `date:` key — updated to six-key shape; (b) WP5 behavioral 3a/3b initially failed because `page.goto(#hash)` is same-document nav — added `page.reload()` to force re-mount of the hash-reading `useState` initializer. First frontend WP of v3 Phase 2 — establishes the routing pattern WP6–WP9 will copy.

**Description:** `DayTimeline` reads `window.CT_DATA.day_payloads_by_iso[currentDayIso]` instead of `window.CT_DATA.today`. Day-iso state lives in `useState` initialized from URL hash (`date=2026-05-26` key). Day-arrow ←/→ nav becomes a client-side state swap (pre-rendered payloads available for every iso in the window).
**Phase:** 2
**Dependencies:** WP1, WP3
**Size:** M
**Tasks:**
- [x] 5.1 In the interactive Dashboard wrapper (`viz_render.py::_interactive_dashboard`): replace direct `today` reads with a `dayIso` state + memoized lookup into `day_payloads_by_iso`.
- [x] 5.2 Add Day-arrow nav UI (`‹` / `›` buttons in the date header strip, adjacent to the date label). Disable when at window boundary.
- [x] 5.3 URL hash: add `date=YYYY-MM-DD` key under the consumer-reservation table. Default-elision when `dayIso === todayIso` (the most-recent day in the window).
- [x] 5.4 `test_visualize_cli.sh` source-shape pins: `day_payloads_by_iso` consumer wiring; day-arrow nav buttons; `date=` hash dispatcher.
- [x] 5.5 `test_visualize_interactive.js` behavioral: Day-arrow click → DayTimeline re-renders with new day's segments; URL hash updates; data-day-iso selector reflects current day.

### WP6: Week view sub-payload routing + Week-arrow nav ✅ SHIPPED 2026-06-03 (commit `36ad7a6`)
**Result:** Week view migrated off the v2 `week` alias key onto `week_payloads_by_monday[mondayIso]`. New ‹/› buttons in the toolbar's date strip drive client-side swaps between pre-rendered weeks, disabled at window boundaries. New `week=YYYY-MM-DD` URL hash key (Monday-anchored) with default-elision when `mondayIso === current_week_monday` (the Monday of the ISO-week containing `window.CT_DATA.window.end`). The `week` alias key stays populated by the CLI for v2-frontend coexistence through WP9. Second frontend WP of v3 Phase 2 — mechanical analog of WP5. Test baselines at ship: CLI 182 → 186 (+4 source-shape pins; the existing five-branch hash-dispatch pin updated in-place to the new seven-key shape per the plan-time literal-payload-object grep pre-empt), container interactive 55 → 64 (+9 behavioral pins, all PASS on first run — `page.reload()` workaround baked in via the WP5 verify-codify lesson), Python 131/0, structure 125/0. **Zero Test Triage entries** — both plan-time conventions persisted by WP5 (literal-payload-object grep + useMemo v2-alias fallback) held cleanly through WP6.

**Description:** `WeekTimeline` reads `window.CT_DATA.week_payloads_by_monday[currentMondayIso]`. Same pattern as WP5 for Day. Week-arrow ←/→ nav between pre-rendered weeks.
**Phase:** 2
**Dependencies:** WP1, WP3
**Size:** S
**Tasks:**
- [x] 6.1 Week-iso state + memoized lookup into `week_payloads_by_monday`.
- [x] 6.2 Week-arrow nav UI in the date header strip.
- [x] 6.3 URL hash: add `week=YYYY-MM-DD` key (Monday-anchored). Default-elision when `mondayIso === current_week_monday`.
- [x] 6.4 Test pins.

### WP7: Month view sub-payload routing ✅ SHIPPED 2026-06-03 (commit 51d2393)
**Description:** `MonthView` reads `window.CT_DATA.month_payloads_by_iso[currentMonthIso]`. The existing `MonthNavToast` reload-redirect (v2 WP7) becomes obsolete for months *inside* the pre-rendered window — instant client-side swap. For months *outside* the window, the toast remains.
**Phase:** 2
**Dependencies:** WP1, WP3
**Size:** S
**Tasks:**
- [x] 7.1 Month-iso state + memoized lookup into `month_payloads_by_iso`.
- [x] 7.2 Month-arrow ←/→: instant swap when target month is in the pre-rendered window; reload-redirect toast otherwise (v2 WP7 behavior preserved for the edge case).
- [x] 7.3 Test pins for both paths.

### WP8: Compare view sub-payload routing (resolves v2 WP11 known limitation) ✅ SHIPPED 2026-06-03 (commit ab65a26)
**Description:** `CompareView` reads `window.CT_DATA.compare_payloads_by_preset[currentPreset]` instead of `window.CT_DATA.comparison`. Preset sub-tab click becomes an instant content swap (NOT just a hash + label swap as in v2). **Resolves the v2 Phase 2.A verify-human PARTIAL finding** (preset content-not-refreshing).
**Phase:** 2
**Dependencies:** WP1, WP3
**Size:** S
**Tasks:**
- [x] 8.1 `comparePayload` useMemo with v2-alias fallback added at viz_render.py:343; JSX consumer swapped from `window.CT_DATA.comparison` to `comparePayload` at viz_render.py:886. Internal CompareView prop name `comparison` kept (still receives same shape).
- [x] 8.2 PresetSelector onClick refreshes content reactively via the useMemo's `preset`-keyed lookup.
- [x] 8.3 Custom preset preserved as-is — useMemo's fallback to `window.CT_DATA.comparison` (= wow alias) keeps CompareView rendering current preset content while RangePicker pair handles the user-picked-range case (v2 reload-redirect-toast flow unchanged).
- [x] 8.4 v2 archive annotation updated in `docs/product/archive/claude-time-visualize-v2/wbs.md` — see "WP8 archive annotation" section in retrospect for the exact edit location.
- [x] 8.5 Test pins added: CLI test_visualize_cli.sh +4 source-shape (sibling-var, useMemo+fallback, routed consumer, legacy regression-pin); test_visualize_interactive.js +6 behavioral (WP8 1a-1f covering content-differs-on-preset-click via the `[data-compare-row="engaged-session"] [data-compare-col="a"]` selector — switched from `parallelism-multiplier` after verify-auto discovered it collapses to 1.00× on low-density fixtures).

### WP9: Custom-range view sub-payload routing ✅ SHIPPED 2026-06-03 (commit `98546b2`)
**Result:** Two-phase Size-S→M feature. **Phase 1** (Custom-view routing): new `_aggregateDayPayloads` JS helper does cross-day union over `day_payloads_by_iso` for `[range.start..range.end]`, tagging sessions with `day_iso`; new `customPayload` useMemo with `dayLikePayload = isCustom ? customPayload : dayPayload` routing slot substituted at all 6 `isDayLike` consumer surfaces; `onRangeChange` out-of-window detection triggers `setNavToast` with the reload command; `data-custom-range` selector added. **Phase 2** (v2 alias-key strip): removed `today`/`week`/`comparison`/`months`/`meta` from CLI emit (`_cmd_visualize` + demo path), kept `snapshot` as top-level 1-field replacement; pruned all 4 useMemo v2-alias fallbacks in `_interactive_dashboard`; migrated 7 init paths (`_initView`, `_initCompareRanges`, `_initMonthIso`, `range`, `expandedProjects`, `_defaultViewport`, `onPrev/NextMonth`) off `today.meta`/`window.CT_DATA.comparison`/`monthsMap` onto canonical sub-payload maps; `dashboard.jsx::_initialViewport` migrated from `window.CT_DATA.today` reads to `day_payloads_by_iso[window.end]` (dead v2 `target_iso` multi-day branch pruned); Toolbar `snapshot` prop sourced from `window.CT_DATA.snapshot`. **Closes the WP5–WP9 sub-payload routing convention** at v3 cycle close — applied to 5/5 sub-payload views (Day/Week/Month/Compare/Custom); CLAUDE.md convention note retired as HISTORICAL. Final test baselines: `test_visualize_cli.sh` 199 → 205 (+6 P2 source-shape pins, 9 obsolete-test flips), container interactive 78 → 89 (+11 net: 5 WP9-P1 + 6 WP9-P2), Python 89/0 unchanged, structure 92/0 clean. Single Test Triage entry: 9 obsolete-test flips at Phase 2 build as single contract-migration triage (high confidence, handled in-phase).

**Description:** Custom-range view (v2 WP8) currently reads `window.CT_DATA.today` (the multi-day Day-view-like payload). v3 routes it through `day_payloads_by_iso[*]` for ranges inside the pre-rendered window. For ranges OUTSIDE the pre-rendered window, the RangePicker still triggers a reload-redirect.
**Phase:** 2
**Dependencies:** WP1, WP3, WP5
**Size:** S
**Tasks:**
- [x] 9.1 Custom-range render path: when `[range.start..range.end]` ⊆ pre-rendered window, render directly from `day_payloads_by_iso` union. Otherwise, reload-redirect toast.
- [x] 9.2 RangePicker onChange detects in-window vs out-of-window and swaps between instant-render and reload-redirect.
- [x] 9.3 Test pins.
- [x] 9.4 v2 alias-key strip + useMemo fallback cleanup (Phase 2; folded into WP9 per plan-time decision B — see WIP plan): CLI emit + frontend useMemos + 7 init paths migrated.
- [x] 9.5 CLAUDE.md "v3 sub-payload routing pattern" convention retired as HISTORICAL.

**Phase 2 → Phase 3 rationale:** Once the frontend state-routing refactor is done, ALL the v2 view-mode infrastructure is intact AND consuming pre-rendered sub-payloads. The remaining v2-deferred UX work (overlap viz, collapsible rows, row density) can now build on the stable v3 substrate without worrying about emit-model surprises.

---

## Phase 3: UX polish (v2-deferred + v3-surfaced)

**Phase rationale:** These three WPs are UI features that the v3 substrate (pre-rendered window, frontend state-routing) unlocks more naturally than v2 could have shipped them. WP12-carry can now correctly visualize overlaps across day boundaries (pre-rendered window contains multi-day data). WP13-carry's collapsible rows + pills + away-total benefits from the row-density work being holistic. WP10 (row-density) is the user's explicit week-of-tracking pain point.

### WP10: Day-view row-density mitigation (resolves SURFACE-2026-05-26-CLAUDE-TIME-VIZ-DAY-VIEW-ROW-DENSITY) ✅ SHIPPED 2026-06-06 (commit c719e1b)
**Description:** After ~1 week of tracking, Day view has too many project rows to read comfortably. Options to evaluate at feature-spec time: (a) auto-hide rows with no activity in the visible viewport (data-driven filtering); (b) min-activity-threshold filter chip (e.g., "show only projects with >15m active"); (c) auto-sort rows by recent activity descending; (d) virtualization. Likely a combination of (a) + (c) is the cheapest user-impact win.
**Phase:** 3
**Dependencies:** WP5
**Size:** M
**Tasks:**
- [x] 10.1 At feature-spec time: pick the mitigation strategy (a/b/c/d combination). Record decision rationale. **Chosen: (a)+(c), viewport-aware, with session-local escape hatch, Day-only.** Rationale captured in `workflow/archive/wp10-day-view-row-density.md` § Spec.
- [x] 10.2 Implement chosen strategy in `DayTimeline` (Day-only — Custom view also renders via DayTimeline but is gated via new `view` prop set to `'custom'` by `_interactive_dashboard`). WeekTimeline unchanged.
- [x] 10.3 URL hash: no new keys reserved. The escape-hatch toggle is session-local per spec (default-elision discipline — no URL pollution for non-default user state).
- [x] 10.4 Test pins: +7 CLI source-shape (test_visualize_cli.sh 205→212/0) + 6 container behavioral (test_visualize_interactive.js 89→95/0). One WP9-P4 test fixture-selection migrated for order-agnostic robustness.

### WP11: Collapsible project rows + per-project pills + away-total visibility (carry from v2 WP13) ✅ SHIPPED 2026-06-06 (commit f8f6b3a)
**Description:** Three small UX wins, originally bundled in v2 WP13 (SUPERSEDED 2026-05-26):
(1) Project rows default to **collapsed** (one row per project, sessions merged into one track). Click chevron to expand to per-session rows.
(2) Per-project **total pill** at the row label (active+subagent time, monospace).
(3) **Idle/away total** rendered next to headline stats and per-project pills — the counterweight to active time.
**Phase:** 3
**Dependencies:** WP5, WP10 (row-density mitigation may inform how pills display)
**Size:** M
**Tasks:**
- [x] 11.1 Collapsed-row segment merging: `_mergeProjectIntervalsByKind` helper + `CollapsedTrackRow` component (Q4=B merge-by-kind union); multi-day-aware via `dayOffsetForSession`.
- [x] 11.2 Per-row chevron + expand/collapse state. URL hash `expanded=alias1,alias2` round-trips with default-elision; hash-restore initializer + debounced hash-write effect in `_interactive_dashboard`.
- [x] 11.3 Project total pill on row label — `[data-active-pill]` on both ProjectHeaderRow + CollapsedTrackRow; renders filter-aware `activePlusSub`.
- [x] 11.4 Away-total in two places: per-project row (`[data-away-pill]` beside active pill, Q5=A) + HeadlineCard 4th tile (Q3=A). `_computeAwayMsForWindow` (ms, headline) + `_computeProjectAwayMin` (minutes, row pill); both gate on `filterKinds.away !== false`.
- [x] 11.5 Filter-state aware: per-kind chip toggles project through `totalsByProject` (DayTimeline) AND `_computeAwayMsForWindow` (HeadlineCard) — single source of truth.
- [x] 11.6 Test pins: CLI 212→230/0 (+18 source-shape pins across P1 + P2), behavioral 95→106/0 (+11 net WP11 pins; 2 obsolete-test migrations: WP9-P4 outside-click to union selector, WP10-P2 HeadlineCard tile count to ≥3).

### WP12: Multi-instance overlap visualization (carry from v2 WP12) ✅ SHIPPED 2026-06-06 (commit 1bfb96f)
**Result:** Client-side session-interval overlap detector (`_detectSessionOverlaps`, O(N²) pairwise, day_iso-aware, filter-gated) + `OverlapsContext` (carries detector output + `sessionToProject` map for marker scope filtering) + 3 render layers: `OverlapOverlayLayer` (expanded-row bottom-half translucent strip with peer id, `data-overlap-peer`), `OverlapMarkerLayer` (collapsed-row 2px hairline at overlap interval, `data-overlap-marker`, **within-project peers ONLY** per user direction at P2 verify-human), HeadlineCard 5th tile `data-metric-tile="parallel"` (filter-gated `_computeOverlapMsForWindow` summing pair-overlaps ÷ 2). SidePanel gained `[data-side-panel-overlaps]` section listing per-peer overlap ranges (cross-project peers included — only collapsed-row marker scoped to within-project). Demo data extended with s8 (claude-time 22:00-23:00) + s9 (agent-handoff-protocol 22:30-23:30, cross-project pair) + s10 (claude-time 22:15-22:45, within-project pair with s8) so `--demo` smoke-renders both overlap types end-to-end. 2-phase Size-M feature with 1 F12 verify-human back-loop (within-project marker scope refinement) + 8 Test Triage entries (5 obsolete-tests auto-fixed + 1 real semantic code regression in HeadlineCard empty-caption + 1 own-test regex + 1 pre-existing future-proof). Final test baselines: CLI 230 → **248/0** (+18 source-shape pins), behavioral 106 → **112/0** (+6 behavioral pins), Python 131/0 unchanged.
**Phase:** 3
**Dependencies:** WP5, WP11 (collapsed-row semantics define how overlap renders in the collapsed lane)
**Size:** M
**Tasks:**
- [x] 12.1 Detect overlapping sessions at render time within the visible viewport — `_detectSessionOverlaps` helper at viz/dashboard.jsx, O(N²) pairwise across all visible projects' sessions, day_iso-aware predicate for cross-day Custom-view aggregation, filter-gated (returns `{}` when both active+subagent off).
- [x] 12.2 Visual: half-height vertical stagger on overlapping segments + tooltip — implemented as additive `OverlapOverlayLayer` (bottom-half translucent strip with `data-overlap-peer`, `data-overlap-start`, `data-overlap-end` selectors + tooltip "Overlaps with X · HH:MM–HH:MM") inside SessionRow.
- [x] 12.3 Side panel: "Overlaps with" section when applicable — `[data-side-panel-overlaps]` section in SidePanel, conditionally rendered when peers exist; one `[data-overlap-peer-row]` per peer; cross-project peers included (project-agnostic per user direction).
- [x] 12.4 Headline stat: "X minutes of parallel work" when overlaps exist — 5th HeadlineCard tile `data-metric-tile="parallel"` (filter-gated `_computeOverlapMsForWindow`, single source of truth mirroring `_computeAwayMsForWindow` shape). Also: collapsed-row marker via `OverlapMarkerLayer` (within-project scope per user direction at P2 verify-human).
- [x] 12.5 Test pins — CLI source-shape +18 across both phases; container behavioral +6 (5-tile HeadlineCard with parallel=75m, within-project marker scope, expanded overlay 3-peer set, SidePanel section both presence and omission paths, filter-gating to zero). Demo fixture extended (s8/s9/s10) provides synthetic overlap end-to-end smoke without requiring a real DB.

**Phase 3 → cycle close rationale:** Once these three UX WPs ship, the v3 cycle has delivered everything v2 deferred (overlap viz, collapsible rows, pills, away total) plus the v2-surfaced user pain (row density) plus the architectural fix (preset content-refresh, instant nav within window). Cycle close on `/product-finalize`.

---

## Dependency Map

```
WP1 (build_window_data) ───┬─→ WP2 (perf probe)
                           ├─→ WP3 (unified --window flag)
                           │     │
                           │     └─→ WP4 (legacy flag removal)
                           │
                           └─→ WP5/6/7/8/9 (view sub-payload routing, parallelizable)
                                                                          │
                                                                          ▼
                                                            WP10 (row density)
                                                                          │
                                                                          ▼
                                                            WP11 (collapsible rows + pills)
                                                                          │
                                                                          ▼
                                                            WP12 (overlap viz)
```

**Critical path:** WP1 → WP2 (decision gate) → WP3 → WP5 → WP10 → WP11 → WP12.

**Parallelizable:** WP6, WP7, WP8, WP9 (all depend on WP1 + WP3 but not on each other). WP4 depends only on WP3.

## Sizing summary

| Phase | WPs | Sizes |
|---|---|---|
| Phase 0 | WP1, WP2 | M + S(probe) |
| Phase 1 | WP3, WP4 | M + S |
| Phase 2 | WP5, WP6, WP7, WP8, WP9 | M + S + S + S + S |
| Phase 3 | WP10, WP11, WP12 | M + M + M |

**10 WPs total.** Roughly 3 M's + 6 S's + 1 probe — somewhat smaller than v2 (14 WPs) because much of the v2 infrastructure (data layer helpers, MetricsPanel, CompareView core) is being *reorganized*, not rebuilt.

## Decisions locked at WBS approval (2026-05-26)

1. **Default window: 90 days (MTD + 2 prior months)** — user-confirmed; WP2 probe confirms or counter-proposes.
2. **Legacy v2 flags are removed outright** (revised 2026-05-28). Single-user tool, no external consumers — `--window` plus URL hash cover every use case.
3. **Cycle-name convention preserved:** `claude-time-visualize-v3` follows v2's naming.
4. **Existing CLAUDE.md hash-schema table is carried forward verbatim.** New keys (`date`, `week`) get added per the consumer-reservation convention.
5. **No new external dependencies.** v3 is a pure-refactor + UX-additions cycle.

## Notes / open questions

- **Unified flag name decision deferred to WP3 feature-spec.** Candidates noted above (`--window 90d` vs `MTD-2` vs explicit range or combined). Each has trade-offs; spec elicitation is the right venue.
- **Compare custom-preset** still requires re-emit for arbitrary user-picked ranges (no way to pre-render an infinite space of custom ranges). WP8 preserves the v2 reload-redirect-toast for this case.
- **The 90-day default's relationship to `viz_context_days_*` config** (v2 WP5b) — WP3 should clarify whether the new flag supersedes those, makes them advisory, or aliases them.

## Next step

Run `/product-context` (P9) to refresh the project's `CLAUDE.md` — or skip if the existing CLAUDE.md already covers the new conventions adequately (this project intentionally maintains its own CLAUDE.md per the doc-loading rules). Most likely action: minimal CLAUDE.md updates at WP3 + WP5 / WP6 ship times to add new hash keys, not a separate /product-context invocation.

After CLAUDE.md updates land, individual WPs are entered via `/feature-spec` or `/feature-plan` from the WBS task list, one at a time.
