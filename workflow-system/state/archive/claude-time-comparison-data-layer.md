---
feature: claude-time-comparison-data-layer
workflow: feature
state: ship (complete)
shipped_commit: 4f61904
created: 2026-05-21
drive_mode: autopilot
wbs_ref: WP4 — claude-time-visualize-v2 cycle
size: S
---

# Feature: claude-time comparison data layer (WP4)

## Problem Statement

`claude-time visualize` v2 will offer comparison views (week-over-week, day-vs-trailing-median, this-month vs last-month — see WP11 in `docs/product/wbs.md`). The UI work in Phase 3 cannot land without a Python-side data layer that emits a side-by-side payload for two arbitrary windows with pre-computed per-project deltas. WP3 just shipped `build_range_data(start_iso, end_iso)` as the per-window primitive; WP4 builds the comparison coordinator on top of it. Size **S** — this is one new module-level function (`build_comparison_data`), two thin helper builders (`compare_week_over_week`, `compare_day_vs_median`), and a unit-test class. No CLI surface in this WP — the consuming `--compare` flag lands in WP11.

**Seam from WP3 lesson:** WP3 flipped from the plan's "single core" framing to "per-day worker + multi-day coordinator" mid-build. WP4 has a similar shape — the natural primitive is `build_range_data` (just shipped), and `build_comparison_data` is the thin coordinator that calls it twice and computes deltas. Unlike WP3 the seam matches the plan, so no re-architecting expected. **Watchout:** if I find the deltas computation has shared state with the per-window aggregation (e.g. cross-window project-id normalisation that needs the raw events, not the aggregated payload), the seam might tilt back toward "single core building both sides + deltas in one pass." Stay open to that at build time.

**WBS-pseudocode reconciliation:** WBS task 4.1 writes the signature as `build_comparison_data(..., *, kind={absolute|relative})` returning `{a, b, deltas: {project: {kind: {abs_min, rel_pct}}}}`. The `kind` key in the result is the **segment kind** (active / reading / thinking / away / subagent), not the comparison mode. The `kind={absolute|relative}` parameter is therefore ambiguous in the WBS — it could be (a) a mode controlling whether `b` is scale-normalised when comparing windows of different length, or (b) vestigial. **Decision (locked at plan time, can revisit at build):** treat `kind` as the per-segment-kind axis in the result only; drop the `kind=` parameter from the signature. If the same project ran for 5 days in A and 7 days in B, the consumer (WP11 UI) can decide whether to scale or show raw — the data layer just emits both `abs_min` and `rel_pct` and lets the renderer choose. This keeps the data layer policy-free, which matches `build_range_data`'s philosophy.

## Work Tree

- [x] Phase 1: `build_comparison_data` + deltas math + unit tests  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `cd tools/claude-time && python3 -c "from viz_data import build_comparison_data; r = build_comparison_data('2026-05-14', '2026-05-14', '2026-05-21', '2026-05-21', events_by_day_a={}, events_by_day_b={}, cfg={'chars_per_sec': 5.0, 'reading_threshold_sec': 60, 'thinking_threshold_sec': 300, 'project_names': {}}, auto_alias_fn=lambda c: 'misc'); assert set(r.keys()) == {'a', 'b', 'deltas', 'meta'}; print('ok')"` exits 0 and prints `ok`.
  - CLI: `cd tools/claude-time/test && python3 -m unittest test_viz_data.BuildComparisonDataTests -v` exits 0 with ≥5 tests run (currently 9). Note: must run from within `test/` because that dir has no `__init__.py`.
  - CLI: `cd tools/claude-time/test && python3 -m unittest discover && bash test_cli.sh && bash test_visualize_cli.sh && bash test_hook.sh` all exit 0 with zero net regressions vs WP3 baseline. Pre-WP4: 58 unittest + 29 cli + 19 visualize + 17 hook = 123 PASS. Expected post-WP4: 67 unittest (net +9 from new BuildComparisonDataTests) + 29 + 19 + 17 = 132 PASS / 0 FAIL.
  - [x] P1.1 Added `build_comparison_data(start_a_iso, end_a_iso, start_b_iso, end_b_iso, *, events_by_day_a, events_by_day_b, cfg, auto_alias_fn)` to `tools/claude-time/viz_data.py`. Two `build_range_data` calls + `_compute_deltas` join. Returns `{a, b, deltas, meta}` with `meta: {a_start, a_end, b_start, b_end, a_day_count, b_day_count}`. WBS `kind=` parameter dropped per plan reconciliation.  <!-- status: complete -->
  - [x] P1.2 Deltas math implemented as `_compute_deltas` + `_project_kind_minutes` module helpers. Per (alias, kind) emits `{abs_min, rel_pct}`. `rel_pct` is `None` when `a_min == 0` (zero baseline). Synthesised `total_active_subagent` key included (sum of active + subagent). Aliases present in only one side handled via the sorted-union loop.  <!-- status: complete -->
  - [x] P1.3 `compare_week_over_week(this_monday_iso, *, events_by_day, ...)` wraps `build_comparison_data` with A = `[prev_monday, prev_sunday]`, B = `[this_monday, this_sunday]`. Internal `_partition_events_by_day` splits the single `events_by_day` dict into the two sub-dicts.  <!-- status: complete -->
  - [x] P1.4 `compare_day_vs_trailing_window(target_day_iso, *, window_days=7, ...)` (renamed from `compare_day_vs_median` per build-time decision — the data layer emits raw per-day payloads, not a median; the consumer chooses the aggregate). A = `[target - window_days, target - 1]`, B = `[target, target]`. Raises `ValueError` on `window_days < 1`.  <!-- status: complete -->
  - [x] P1.5 `BuildComparisonDataTests` added with 9 methods (1 extra over plan because the helper-smoke split into two methods, one per helper). All passing. Test helper `_one_burst_events` made sid-optional (sid derives from date) so A-side and B-side bursts don't collide when both go through comparison helpers.  <!-- status: complete -->
    Tests: `test_empty_both_windows`, `test_empty_a_only`, `test_empty_b_only`, `test_identical_windows`, `test_regression_case`, `test_meta_shape_exact_keys`, `test_total_active_subagent_synthesised`, `test_compare_week_over_week_window_math`, `test_compare_day_vs_trailing_window_math`.
  - [x] verify-auto  <!-- status: complete — syntax OK; imports OK; scoped unit run 16/16 PASS (BuildComparisonDataTests 9 + BuildRangeDataTests 6 + WrapperPreservationTests 1) -->
  - [x] verify-self  <!-- status: complete — 3/3 observable outcomes PASS. No integration boundary (phase adds isolated new artifacts only). Outcome strings cosmetically updated to working invocations (test dir lacks __init__.py; project uses individual test_*.sh scripts, not a wrapper). -->
  - [x] verify-human  <!-- status: complete via F11 skip — human affirmed no integration boundary; phase adds isolated new artifacts (build_comparison_data + 2 helpers + 3 private helpers + 9 unit tests); no existing endpoint/UI/CLI consumes them yet (first consumer lands in WP11). -->
  - [x] verify-codify  <!-- status: complete — 2 coverage-gap tests added (test_compare_day_vs_trailing_window_invalid_window_raises + test_helpers_partition_events_by_day_across_windows). Full suite 134/134 PASS (69 unittest + 29 cli + 19 viz_cli + 17 hook), zero regressions vs WP3 baseline 123 (net +11 from WP4: 9 build + 2 codify). No integration boundary, no test triage needed. -->

## Current Node
- **Path:** Feature > complete (ready to ship)
- **Active scope:** none — all phase nodes [x], all verify nodes [x]
- **Blocked:** none
- **Unvisited:** none (single-phase feature, Phase 1 complete)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect

- **What changed in our understanding:** Two micro-corrections during build, no large reframings. (1) WBS pseudocode said `compare_day_vs_median` but the data layer just emits per-day payloads — the actual median-vs-mean choice belongs to the UI; renamed to `compare_day_vs_trailing_window` for honesty. (2) The WBS `kind={absolute|relative}` parameter was ambiguous against `kind` already being the segment-kind axis in the result dict; dropped it at plan time and let the consumer choose between `abs_min` and `rel_pct` per its rendering needs.
- **Assumptions that held:** The WP3 seam-flip lesson held — for WP4 the truthful primitive really *was* "two `build_range_data` calls + deltas join," exactly as the plan framed it. No re-architecting at build time. The S-size estimate was accurate (single phase, 6 leaves, ~460 lines of net change including tests).
- **Assumptions that were wrong:** The Observable outcome strings I wrote at plan time were technically wrong in two cosmetic ways (the dotted `test.test_viz_data...` unittest path doesn't work because `test/` has no `__init__.py`; the project doesn't have a `tests/run-all.sh` wrapper script, only the individual `test_*.sh` scripts). Implementation was correct; the outcome strings just needed to match the actual project layout. Fixed in the WIP outcomes block at verify-self time so verify-codify and re-runs use the working invocations. Worth carrying as a habit: when writing CLI outcomes, **run the exact command at plan time** to confirm it works rather than reconstructing it from memory of similar past WPs.
- **Approach delta:** Implementation matched the plan exactly modulo the two micro-corrections above. The "watchout" about deltas computation possibly needing raw events (and therefore tilting the seam back toward a single-core design) did not materialize — aggregated payloads were sufficient because the join key is just `alias`, which is preserved across both calls.

## Communicate

> **Feature complete:** `claude-time` comparison data layer (WP4 of v2 cycle) has shipped. `viz_data.py` now exports `build_comparison_data(a_start, a_end, b_start, b_end)` returning side-by-side range payloads + per-(alias, segment-kind) `{abs_min, rel_pct}` deltas, with helper builders for week-over-week and day-vs-trailing-window comparisons. Verify locally: `cd tools/claude-time/test && python3 -m unittest test_viz_data.BuildComparisonDataTests -v` (11 tests). Phase 0 of the v2 cycle is now complete — Phase 1 begins with WP5, the zoomable-timeline XL milestone. Requester = operator — closure notice for self-record.
