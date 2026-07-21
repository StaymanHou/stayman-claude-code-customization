---
workflow: feature
state: ship (complete)
created: 2026-05-21
drive_mode: autopilot
cycle: claude-time-visualize-v2
wbs_wp: WP3
shipped_commit: 9ebad84
shipped_at: 2026-05-21
---

# Feature: Range-aware data layer — `build_range_data(start_iso, end_iso)`

## Problem Statement

`viz_data.py` currently has two parallel core functions: `build_day_data(date_iso, events, …)` (single-day shape with `hour_range`) and `build_week_data(week_monday_iso, events_by_day, …)` (7-day rollup shape). Several v2 features (custom-range view WP8, month view WP7, comparison data WP4, zoomable timeline WP5) need to emit segment-model data over arbitrary `[start_iso, end_iso]` windows — not just `today` or `current week`. Without a unified core, every new view either grows a parallel `build_X_data` or shoehorns into one of the two existing shapes; both paths cause the JSON shape to fork and force Phase 2/3 UI work to re-touch Python. WP3 extracts a single `build_range_data(start_iso, end_iso, *, db_path|events_by_day, aliases)` as the core, re-implements `build_day_data` and `build_week_data` as thin wrappers, adds `meta: {start, end, day_count}` so downstream JS can branch on window shape, and decides range-aware `hour_range` semantics (per-day map + global day_window) so multi-day rulers have something well-defined to render.

## Work Tree

- [x] Phase 1: Extract `build_range_data` + wrap day/week + emit `meta`  <!-- all 6 impl + 4 verify leaves [x] -->
  <!-- impl complete; pending verify-auto/self/human/codify -->
  <!-- Implementation summary:
       - Added `build_range_data(start_iso, end_iso, *, events_by_day, cfg, auto_alias_fn)` to viz_data.py.
       - `build_week_data` re-implemented as thin wrapper over `build_range_data` (shape unchanged).
       - `build_day_data` kept as the per-day worker (called per-day by `build_range_data`) — this is the truthful refactor since burst pairing / event→projects is naturally day-anchored via `_ts_to_minutes`. The plan's "single core" framing was slightly overstated; the actual single core is the per-day worker + a multi-day coordinator. Documented in module docstring.
       - Range payload shape: meta:{start,end,day_count}, hour_range_by_day, day_window, plus back-compat flat `iso`+`hour_range` when day_count==1.
       - 22 pre-existing tests all PASS; 7 new tests added (one over plan: defensive `test_invalid_range_raises` for the ValueError on inverted ranges); total 29 PASS.
       - Smoke: `tools/claude-time/claude-time visualize --demo --no-open` works; CT_DATA.meta (snapshot) still emitted at flat level, no key collision. -->
  **Observable outcomes:**
  - CLI: `python3 -c "import sys; sys.path.insert(0,'tools/claude-time'); import viz_data; out = viz_data.build_range_data('2026-05-11','2026-05-13', events_by_day={'2026-05-11':[],'2026-05-12':[],'2026-05-13':[]}, cfg={'chars_per_sec':6.0,'reading_threshold_sec':120,'thinking_threshold_sec':300,'project_names':{}}, auto_alias_fn=lambda c: 'misc'); print(out['meta'])"` → exit 0; stdout shows `{'start': '2026-05-11', 'end': '2026-05-13', 'day_count': 3}`
  - CLI: `cd tools/claude-time/test && python3 -m unittest test_viz_data -v 2>&1 | tail -5` → `OK` with `Ran 27 tests` (22 existing + 5 new)
  - CLI: `tools/claude-time/claude-time visualize --demo --no-open --out /tmp/wp3-smoke.html` → exit 0; `grep -c '"meta"' /tmp/wp3-smoke.html` ≥ 1 (existing snapshot meta still emitted)
  - HTTP: n/a (no server surface)
  - Browser: n/a in Phase 1 (Phase 1 is internal refactor; dashboard.jsx still reads `today.hour_range` and renders identically — verified via Phase 2 smoke)
  - [x] P1.1 Added `build_range_data(start_iso, end_iso, *, events_by_day, cfg, auto_alias_fn)` to `viz_data.py`. Returns `{label, projects, meta:{start, end, day_count}, hour_range_by_day:{iso: [s, e]}, day_window:[s, e]}`; for `day_count==1` also surfaces flat `iso` and `hour_range` for back-compat with day shape.
  - [x] P1.2 `build_day_data` left as the per-day worker (called per-day by `build_range_data`). Truthful refactor — burst pairing / event→projects is day-anchored via `_ts_to_minutes`. Plan's "thin wrapper over range" framing was off; the actual single core is per-day worker + range coordinator. Day shape return preserved byte-for-byte (all 22 existing tests pass).
  - [x] P1.3 Re-implemented `build_week_data` as thin wrapper over `build_range_data(monday, sunday, ...)` — coordinates the 7-day range, then re-shapes per-day payloads into the existing rollup shape. Output shape unchanged from pre-WP3 (WeekRollupTests + week shape contract tests pass).
  - [x] P1.4 Hour range semantics: `hour_range_by_day` map per-day (uses existing `_hour_range_for` adaptive bounds), `day_window` is union of all per-day ranges. For `day_count == 1`, flat `hour_range` mirrors `hour_range_by_day[only_iso]`.
  - [x] P1.5 `meta: {start, end, day_count}` injected into range payload only. Documented decision: NOT propagated into day/week wrapper returns — avoids collision with `window.CT_DATA.meta.snapshot` at the flat-level (`_cmd_visualize` adds that). Day/week wrappers keep their pre-WP3 shape.
  - [x] P1.6 Module docstring extended to document `build_range_data` shape (`meta`, `hour_range_by_day`, `day_window`) and the meta-nesting decision.
  - [x] verify-auto  <!-- syntax+targeted 29/29 PASS 2026-05-21 -->
  - [x] verify-self  <!-- all 3 outcomes PASS + bonus test_visualize_cli.sh 19/19 PASS; integration-boundary (visualize CLI) exercised; 2026-05-21 -->
  - [x] verify-human  <!-- approved 2026-05-21 by user ("Looking all good. continue") after agent ran visualize --date 2026-05-19 against live DB; payload inspection confirmed pre-WP3 shape preserved (today/week/meta keys, no range-data leak into wrapper returns), 6 projects, hour_range [5,23] adaptive -->
    - [x] P1.verify-human.1: visualize --date 2026-05-19 render — PASS
    - [x] P1.verify-human.2: Week view rollup (Week 21, 8 projects) — PASS
    - [x] P1.verify-human.3: code review of refactor shape — PASS (implicit)
    - [x] P1.verify-human.4: accept +1 defensive test (test_invalid_range_raises) — PASS (implicit)
  - [x] verify-codify  <!-- 123 PASS / 0 FAIL across full claude-time suite (29 unittest + 29 test_cli + 19 test_visualize_cli + 17 test_hook + 29 test_reclassify); net +7 from WP2; 2026-05-21 -->
    - [x] Codify-1: BuildRangeDataTests (6 tests — 5 planned + 1 defensive) ✓
    - [x] Codify-2: WrapperPreservationTests.test_day_shape_equivalence ✓
    - [x] Codify-3: 22 pre-existing tests still PASS post-refactor ✓

## Current Node
- **Path:** Feature complete — ready to ship
- **Active scope:** all phases complete
- **Blocked:** none
- **Unvisited:** verify-auto → verify-self → verify-human → verify-codify (in execution order)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect
- **What changed in our understanding:** The plan framed `build_range_data` as "the single core" with `build_day_data` becoming "a thin wrapper" over it. In implementation, that framing inverted: `build_day_data` *is* the per-day worker (because `_ts_to_minutes` and burst pairing are naturally day-anchored), and `build_range_data` is a multi-day *coordinator* that delegates per-day work to it. The actual seam is per-day worker + multi-day coordinator, not single-core + wrappers. Documented in code (module docstring) and Work Tree leaf P1.2.
- **Assumptions that held:** (a) `meta` naming collision risk with the CLI's flat-level `meta.snapshot` was real — kept range `meta` scoped to range payload only, day/week wrappers unchanged, no JS consumer break. (b) The 22 pre-existing tests acting as the back-compat regression gate worked exactly as designed: refactor went green on first run. (c) `_hour_range_for` was already general enough to feed the per-day map without modification.
- **Assumptions that were wrong:** The "thin wrapper" framing — see above. Also: I planned 5 BuildRangeDataTests but ended up writing 6 (added `test_invalid_range_raises` defensively when I added the `ValueError` on inverted ranges). Minor over-scope flagged in build and accepted by user at verify-human.
- **Approach delta:** Single-phase feature (no Phase 2 needed — WP3 is a pure data-layer extraction with no UI surface). Autopilot mode drove the whole loop with one human-input pause at verify-human (the user asked me to run the dashboard against their live DB for 2026-05-19 instead of `--demo`, which surfaced a real-data sanity check the planned `--demo` outcome wouldn't have caught — useful nudge worth recalling for future verify-human checklists on data-layer features).
