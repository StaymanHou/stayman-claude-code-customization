---
stage: wbs
state: in-progress
updated: 2026-05-28
cycle: claude-time-visualize-v3
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

### WP1: Unified emit-window coordinator (`build_window_data`)
**Description:** New top-level coordinator in `viz_data.py` that takes `(window_start_iso, window_end_iso)` and produces the full pre-rendered payload: `{window, day_payloads_by_iso, week_payloads_by_monday, month_payloads_by_iso, compare_payloads_by_preset, metrics}`. Reuses existing `build_day_data`, `build_range_data`, `build_week_data`, `build_comparison_data`, `build_metrics` as worker functions. The coordinator is responsible for: (1) computing which days/weeks/months/compares fall within the window; (2) calling each worker once; (3) attaching results under the canonical sub-payload keys.
**Phase:** 0
**Dependencies:** —
**Size:** M
**Tasks:**
- [ ] 1.1 Define `build_window_data(start_iso, end_iso, *, events_by_day, cfg, auto_alias_fn) -> dict` signature in `viz_data.py`. Return shape: `{window: {start, end, day_count}, day_payloads_by_iso: {iso: <build_day_data output>}, week_payloads_by_monday: {monday_iso: <build_week_data output>}, month_payloads_by_iso: {month_iso: <build_range_data output>}, compare_payloads_by_preset: {wow: <build_comparison_data output>, today-vs-trailing: <...>, mom: <...>}, metrics: <build_metrics output for the full window>}`
- [ ] 1.2 Per-day loop: for each ISO day in `[start_iso..end_iso]`, call `build_day_data` with that day's events. Attach to `day_payloads_by_iso`.
- [ ] 1.3 Per-week loop: for each Monday-anchored week intersecting the window, call `build_week_data`. Attach to `week_payloads_by_monday`.
- [ ] 1.4 Per-month loop: for each calendar month intersecting the window, call `build_range_data` over that month's days. Attach to `month_payloads_by_iso` keyed by `YYYY-MM`.
- [ ] 1.5 Compare-preset loop: call `compare_week_over_week(today_monday_iso)`, `compare_day_vs_trailing_window(today_iso, 7)`, `compare_month_over_month(today_month_iso)` — using "today" as the anchor (the most-recent day in the window). Attach to `compare_payloads_by_preset` keyed by preset name.
- [ ] 1.6 Window-level metrics: `build_metrics(all_events, window_start_dt, window_end_dt)` over the entire 90-day window. Attach as top-level `metrics`. (Per-window-slice metrics for compare presets live inside their `compare_payloads_by_preset[preset].{a,b}.metrics` per v2 WP11 Phase 1.B.)
- [ ] 1.7 Add `BuildWindowDataTests` to `test_viz_data.py` — at minimum: empty window, single-day window, full 90-day shape sanity (all 4 sub-payload maps populated, key sets correct), compare-preset cross-reference (top-level `metrics.engaged_session.wallclock_ms` should equal sum of `day_payloads_by_iso[*].today_total` modulo merge semantics).

### WP2: Emit-time perf budget + 90-day default
**Description:** Measure the actual emit cost (SQLite load + `build_window_data` total) for a 90-day window against the user's real DB. If within ~2s wall-clock + ~500KB JSON, lock the default. If over, decide between (a) reducing the default window, (b) lazy-loading sub-payloads, (c) deferring compare-preset pre-render.
**Phase:** 0
**Dependencies:** WP1
**Size:** S
**Type:** probe (learning, not a build artifact)
**Learning objective:** Confirm the 90-day default fits the user's "slightly longer load time and larger file size is acceptable" tolerance, OR identify the smaller default that does.
**Timebox:** half-day
**Success criterion:** Documented timing measurement (5 runs, min/avg/max) + emit-size measurement (bytes) + Go/No-Go decision on the 90-day default OR a counter-proposal (e.g., 60 days).
**Tasks:**
- [ ] 2.1 Add a perf script `tools/claude-time/test/perf_window_data.py` that runs `build_window_data` over the user's real DB 5 times with varying window sizes (30, 60, 90, 120 days) and reports wall-clock + output JSON byte count.
- [ ] 2.2 Run the perf script; record results in a comment block at the top of the script + summarize in the WP retrospect.
- [ ] 2.3 Decision: confirm 90-day default OR propose alternative + rationale.

**Phase 0 → Phase 1 rationale:** Once `build_window_data` is shape-locked and perf-validated, every UI WP can rely on the pre-rendered payload existing. Skipping the perf probe risks downstream WPs being built on an emit cost the user later rejects, forcing a Phase-0 rework mid-cycle.

---

## Phase 1: CLI surface refactor (unified time-range + legacy flag removal)

**Phase rationale:** The CLI surface change is downstream of the data layer (the new flag has to produce a `build_window_data` payload to be testable) but upstream of the frontend refactor (the frontend needs the new payload structure to consume). Doing it second isolates the CLI change from frontend state-routing complexity.

### WP3: Unified `--window` flag (or chosen name)
**Description:** New CLI flag that takes a time-range arg (e.g., `--window 90d`, `--window MTD-2`, `--window 2026-04-01:2026-05-26`) and produces a single-emit pre-rendered 90-day-default dashboard. WP3 introduces `--window` only; WP4 removes the legacy flags (`--date`, `--week`, `--month`, `--range`, `--compare`, `--compare-range`).
**Phase:** 1
**Dependencies:** WP1
**Size:** M
**Tasks:**
- [ ] 3.1 Spec the unified time-range arg syntax at feature-spec time. Candidates: `--window 90d` (rolling N days back from today), `--window MTD-2` (month-to-date plus 2 prior months), `--window 2026-04-01:2026-05-26` (explicit range), or a combination. Decision recorded in the feature spec.
- [ ] 3.2 Add the new flag to the `viz` subparser. Validation: must produce a `(start_iso, end_iso)` pair with `end >= start` and `end <= today` and `day_count <= viz_window_max_days` (new config key, default 365).
- [ ] 3.3 In `_cmd_visualize`, when the new flag is set: load events for the window, call `build_window_data`, emit. The output becomes `window.CT_DATA` with the new shape (sub-payload maps).
- [ ] 3.4 Default behavior: when `--window` is not set, default to the 90-day window (or whatever WP2 confirms). Legacy flags are removed in WP4 — WP3 does not need to preserve them.
- [ ] 3.5 `test_visualize_cli.sh` pins: `--window 30d` produces a payload with `day_payloads_by_iso` keys covering 30 days; `--window 2026-04-01:2026-05-26` matches explicit bounds; default invocation produces the WP2-confirmed default; mutex with `--demo` (demo data is single-day).

### WP4: Legacy flag removal
**Description:** Existing v2 flags (`--date`, `--week`, `--month`, `--range`, `--compare`, `--compare-range`) are removed from the `viz` subparser entirely. The unified `--window` flag (WP3) plus URL-hash dispatch (Phase 2) cover every use case. Single-user tool, no external consumers — clean removal is preferable to a deprecation-alias surface.
**Phase:** 1
**Dependencies:** WP3
**Size:** S
**Tasks:**
- [ ] 4.1 Delete the legacy flag definitions from the `viz` subparser. Remove their handler branches in `_cmd_visualize`.
- [ ] 4.2 Update `--help` text and any in-tree usage docs (README sections, comments) to reference only `--window`.
- [ ] 4.3 `test_visualize_cli.sh`: delete the legacy-flag scenarios; replace with `--window`-based equivalents where the underlying behavior is still in scope. Removed flags should produce an argparse error (rc=2) — pin one such case to confirm.

**Phase 1 → Phase 2 rationale:** Once the CLI surface stably produces the new payload shape via `--window`, the frontend can be refactored to consume it. Doing the frontend refactor in Phase 1 would force the CLI surface to be designed against an unstable consumer.

---

## Phase 2: Frontend state-routing refactor

**Phase rationale:** The dashboard currently dispatches on `window.CT_INITIAL_VIEW` + `window.CT_INITIAL_PRESET` to pick a single view from a single payload. v3 changes this to: hash dispatches to a view + sub-view-state, and each view reads the appropriate pre-rendered sub-payload from `window.CT_DATA.<sub_payload_map>[<key>]`. This phase touches every view component (Day, Week, Month, Custom, Compare) but leaves their internal rendering largely unchanged — only the **data-source plumbing** changes.

### WP5: Day view sub-payload routing
**Description:** `DayTimeline` reads `window.CT_DATA.day_payloads_by_iso[currentDayIso]` instead of `window.CT_DATA.today`. Day-iso state lives in `useState` initialized from URL hash (`date=2026-05-26` key). Day-arrow ←/→ nav becomes a client-side state swap (pre-rendered payloads available for every iso in the window).
**Phase:** 2
**Dependencies:** WP1, WP3
**Size:** M
**Tasks:**
- [ ] 5.1 In the interactive Dashboard wrapper (`viz_render.py::_interactive_dashboard`): replace direct `today` reads with a `dayIso` state + memoized lookup into `day_payloads_by_iso`.
- [ ] 5.2 Add Day-arrow nav UI (`‹` / `›` buttons in the date header strip, adjacent to the date label). Disable when at window boundary.
- [ ] 5.3 URL hash: add `date=YYYY-MM-DD` key under the consumer-reservation table. Default-elision when `dayIso === todayIso` (the most-recent day in the window).
- [ ] 5.4 `test_visualize_cli.sh` source-shape pins: `day_payloads_by_iso` consumer wiring; day-arrow nav buttons; `date=` hash dispatcher.
- [ ] 5.5 `test_visualize_interactive.js` behavioral: Day-arrow click → DayTimeline re-renders with new day's segments; URL hash updates; data-day-iso selector reflects current day.

### WP6: Week view sub-payload routing + Week-arrow nav
**Description:** `WeekTimeline` reads `window.CT_DATA.week_payloads_by_monday[currentMondayIso]`. Same pattern as WP5 for Day. Week-arrow ←/→ nav between pre-rendered weeks.
**Phase:** 2
**Dependencies:** WP1, WP3
**Size:** S
**Tasks:**
- [ ] 6.1 Week-iso state + memoized lookup into `week_payloads_by_monday`.
- [ ] 6.2 Week-arrow nav UI in the date header strip.
- [ ] 6.3 URL hash: add `week=YYYY-MM-DD` key (Monday-anchored). Default-elision when `mondayIso === current_week_monday`.
- [ ] 6.4 Test pins.

### WP7: Month view sub-payload routing
**Description:** `MonthView` reads `window.CT_DATA.month_payloads_by_iso[currentMonthIso]`. The existing `MonthNavToast` reload-redirect (v2 WP7) becomes obsolete for months *inside* the pre-rendered window — instant client-side swap. For months *outside* the window, the toast remains.
**Phase:** 2
**Dependencies:** WP1, WP3
**Size:** S
**Tasks:**
- [ ] 7.1 Month-iso state + memoized lookup into `month_payloads_by_iso`.
- [ ] 7.2 Month-arrow ←/→: instant swap when target month is in the pre-rendered window; reload-redirect toast otherwise (v2 WP7 behavior preserved for the edge case).
- [ ] 7.3 Test pins for both paths.

### WP8: Compare view sub-payload routing (resolves v2 WP11 known limitation)
**Description:** `CompareView` reads `window.CT_DATA.compare_payloads_by_preset[currentPreset]` instead of `window.CT_DATA.comparison`. Preset sub-tab click becomes an instant content swap (NOT just a hash + label swap as in v2). **Resolves the v2 Phase 2.A verify-human PARTIAL finding** (preset content-not-refreshing).
**Phase:** 2
**Dependencies:** WP1, WP3
**Size:** S
**Tasks:**
- [ ] 8.1 Replace `_computeMetricsView(comparison?.a?.metrics, ...)` with `_computeMetricsView(compare_payloads_by_preset[preset]?.a?.metrics, ...)`. Same for `b.metrics`.
- [ ] 8.2 PresetSelector onClick now actually refreshes content because the sub-payload swap is reactive.
- [ ] 8.3 Custom preset (preset === 'custom') still requires re-emit since user-picked ranges aren't pre-rendered — preserve v2's behavior (RangePicker pair + reload-redirect-toast).
- [ ] 8.4 Update v2 WP11 P2A.verify-human.3 PARTIAL annotation in the v2 archive: link to v3 WP8 ship as the resolution.
- [ ] 8.5 Test pins: preset switch via real mouse-click → content (not just hash) changes; `test_visualize_interactive.js` adds a behavioral pin asserting `[data-compare-row="parallelism-multiplier"] [data-compare-col="a"]` text content differs between WoW and MoM preset selections.

### WP9: Custom-range view sub-payload routing
**Description:** Custom-range view (v2 WP8) currently reads `window.CT_DATA.today` (the multi-day Day-view-like payload). v3 routes it through `day_payloads_by_iso[*]` for ranges inside the pre-rendered window. For ranges OUTSIDE the pre-rendered window, the RangePicker still triggers a reload-redirect.
**Phase:** 2
**Dependencies:** WP1, WP3, WP5
**Size:** S
**Tasks:**
- [ ] 9.1 Custom-range render path: when `[range.start..range.end]` ⊆ pre-rendered window, render directly from `day_payloads_by_iso` union. Otherwise, reload-redirect toast.
- [ ] 9.2 RangePicker onChange detects in-window vs out-of-window and swaps between instant-render and reload-redirect.
- [ ] 9.3 Test pins.

**Phase 2 → Phase 3 rationale:** Once the frontend state-routing refactor is done, ALL the v2 view-mode infrastructure is intact AND consuming pre-rendered sub-payloads. The remaining v2-deferred UX work (overlap viz, collapsible rows, row density) can now build on the stable v3 substrate without worrying about emit-model surprises.

---

## Phase 3: UX polish (v2-deferred + v3-surfaced)

**Phase rationale:** These three WPs are UI features that the v3 substrate (pre-rendered window, frontend state-routing) unlocks more naturally than v2 could have shipped them. WP12-carry can now correctly visualize overlaps across day boundaries (pre-rendered window contains multi-day data). WP13-carry's collapsible rows + pills + away-total benefits from the row-density work being holistic. WP10 (row-density) is the user's explicit week-of-tracking pain point.

### WP10: Day-view row-density mitigation (resolves SURFACE-2026-05-26-CLAUDE-TIME-VIZ-DAY-VIEW-ROW-DENSITY)
**Description:** After ~1 week of tracking, Day view has too many project rows to read comfortably. Options to evaluate at feature-spec time: (a) auto-hide rows with no activity in the visible viewport (data-driven filtering); (b) min-activity-threshold filter chip (e.g., "show only projects with >15m active"); (c) auto-sort rows by recent activity descending; (d) virtualization. Likely a combination of (a) + (c) is the cheapest user-impact win.
**Phase:** 3
**Dependencies:** WP5
**Size:** M
**Tasks:**
- [ ] 10.1 At feature-spec time: pick the mitigation strategy (a/b/c/d combination). Record decision rationale.
- [ ] 10.2 Implement chosen strategy in `DayTimeline` (and `WeekTimeline` if applicable).
- [ ] 10.3 URL hash: any new state (e.g., min-activity threshold) gets a hash key per the consumer-reservation table.
- [ ] 10.4 Test pins.

### WP11: Collapsible project rows + per-project pills + away-total visibility (carry from v2 WP13)
**Description:** Three small UX wins, originally bundled in v2 WP13 (SUPERSEDED 2026-05-26):
(1) Project rows default to **collapsed** (one row per project, sessions merged into one track). Click chevron to expand to per-session rows.
(2) Per-project **total pill** at the row label (active+subagent time, monospace).
(3) **Idle/away total** rendered next to headline stats and per-project pills — the counterweight to active time.
**Phase:** 3
**Dependencies:** WP5, WP10 (row-density mitigation may inform how pills display)
**Size:** M
**Tasks:**
- [ ] 11.1 Collapsed-row segment merging: union of all session segments within a project, rendered as a single track.
- [ ] 11.2 Per-row chevron + expand/collapse state (`useState`, defaults to collapsed). URL hash: `expanded=projectA,projectB` per existing CLAUDE.md reservation (originally WP13 reserved).
- [ ] 11.3 Project total pill on row label.
- [ ] 11.4 Away-total in two places: per-project row + headline-stats card.
- [ ] 11.5 Filter-state aware (pills + totals reflect active filter chips).
- [ ] 11.6 Test pins.

### WP12: Multi-instance overlap visualization (carry from v2 WP12)
**Description:** When two sessions ran in parallel on the same wall-clock minute, render the overlap visually (slight vertical offset + "overlap" badge in side panel). The reclassifier handles the data correctly; this is a visualization-only layer.
**Phase:** 3
**Dependencies:** WP5, WP11 (collapsed-row semantics define how overlap renders in the collapsed lane)
**Size:** M
**Tasks:**
- [ ] 12.1 Detect overlapping sessions at render time within the visible viewport.
- [ ] 12.2 Visual: half-height vertical stagger on overlapping segments + tooltip.
- [ ] 12.3 Side panel: "Overlaps with" section when applicable.
- [ ] 12.4 Headline stat: "X minutes of parallel work" when overlaps exist.
- [ ] 12.5 Test pins against a seeded DB with synthetic overlapping sessions.

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
