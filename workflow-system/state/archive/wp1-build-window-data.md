---
workflow: feature
state: ship (complete)
created: 2026-05-28
shipped: 2026-05-28
ship_commit: 4dd8d6d
cycle: claude-time-visualize-v3
wbs_wp: WP1
drive_mode: autopilot
---

# Feature: WP1 — Unified emit-window coordinator (`build_window_data`)

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-28

## Problem Statement

v3's emit model inverts v2's one-CLI-invocation-emits-one-view design: a single CLI invocation must produce a pre-rendered 90-day window with all sub-payloads (per-day, per-week, per-month, per-compare-preset) materialised, so the frontend can swap views entirely client-side. This requires a new top-level coordinator in `viz_data.py` that wraps the existing workers (`build_day_data`, `build_range_data`, `build_week_data`, `build_comparison_data`, `build_metrics`) and emits the canonical pre-rendered shape. WP1 is THE Phase 0 entry point — every downstream UI WP in the v3 cycle depends on the shape contract this WP locks.

The structural pattern is established by v2's `build_comparison_data` (viz_data.py:605) — a top-level coordinator that delegates to existing workers and assembles their outputs under canonical keys. WP1 follows the same shape but with five worker types instead of two, and a window-level metrics roll-up.

## Work Tree

- [x] Phase 1: Coordinator core (signature + per-day/week/month/compare loops + metrics)  <!-- complete 2026-05-28: all impl tasks + all 4 verify nodes [x] -->
  **Observable outcomes:**
  - CLI: `python3 -c "import sys; sys.path.insert(0, 'tools/claude-time'); from viz_data import build_window_data; out = build_window_data('2026-05-26', '2026-05-28', events_by_day={}, cfg={'project_names': {}}, auto_alias_fn=lambda c: c); print(sorted(out.keys()))"` exits 0 and prints `['compare_payloads_by_preset', 'day_payloads_by_iso', 'metrics', 'month_payloads_by_iso', 'week_payloads_by_monday', 'window']`
  - CLI: same invocation with empty events — `out['window'] == {'start': '2026-05-26', 'end': '2026-05-28', 'day_count': 3}`; `set(out['day_payloads_by_iso'].keys()) == {'2026-05-26', '2026-05-27', '2026-05-28'}`; `out['compare_payloads_by_preset']` has keys `{'wow', 'today-vs-trailing', 'mom'}`
  - CLI: `cd tools/claude-time && python3 -m unittest test.test_viz_data -v` exits 0 (existing 124 tests still pass — no regression)
  - [x] P1.1 Add `build_window_data(start_iso, end_iso, *, events_by_day, cfg, auto_alias_fn) -> dict` to `viz_data.py`. Skeleton + window meta sub-dict + day_count validation (mirrors `build_range_data`'s `end < start` guard).
  - [x] P1.2 Per-day loop: iterate ISO days `[start..end]` inclusive; call `build_day_data(day_iso, events_by_day.get(day_iso, []), cfg, auto_alias_fn)` for each; attach to `day_payloads_by_iso` keyed by ISO date.
  - [x] P1.3 Per-week loop: enumerate Monday-anchored ISO weeks intersecting `[start, end]`; call `build_week_data(monday_iso, events_by_day, cfg, auto_alias_fn)` for each; attach to `week_payloads_by_monday` keyed by Monday ISO date. Implemented via first-Monday-on-or-before-start + 7-day stride while monday <= end.
  - [x] P1.4 Per-month loop: enumerate calendar months intersecting the window; for each, compute `(month_first_day_iso, month_last_day_iso)` clipped to the window bounds (a month at the window edge may be partial); call `build_range_data` over that range; attach to `month_payloads_by_iso` keyed by `YYYY-MM`.
  - [x] P1.5 Compare-preset loop: derive `today_iso = end_iso`; compute `today_monday_iso` (Monday of end_iso's ISO week) and `today_month_iso` (end_iso's `YYYY-MM`); call `compare_week_over_week`, `compare_day_vs_trailing_window` (window_days=7), `compare_month_over_month`. Attach to `compare_payloads_by_preset` under keys `wow`, `today-vs-trailing`, `mom`.
  - [x] P1.6 Window-level metrics: flatten `events_by_day` to a single sorted event list keyed by `ts`; compute `window_start_dt`/`window_end_dt` from start/end ISO dates; call `build_metrics`. Always pass real window dts (not `None`) so the empty-events path still reflects the actual window in `metrics.window`.
  - [x] verify-auto  <!-- parse + import smoke + 72 targeted tests pass -->
  - [x] verify-self  <!-- all 3 observable outcomes PASS via direct CLI execution (no UI surface, no Playwright needed); 124-test baseline preserved -->
  - [x] verify-human  <!-- F11 skipped 2026-05-28: no integration boundary (isolated new artifact, no existing consumer); human-confirmed -->
  - [x] verify-codify  <!-- 124/124 Python tests pass; comprehensive new tests are Phase 2's deliverable (BuildWindowDataTests, P2.1–P2.7) -->

- [x] Phase 2: `BuildWindowDataTests` suite  <!-- complete 2026-05-28: 6 tests landed + all 4 verify nodes [x]; 130-test Python suite + 122-pin structure check both green -->
  **Observable outcomes:**
  - CLI: `cd tools/claude-time && python3 -m unittest test.test_viz_data.BuildWindowDataTests -v` exits 0 with at least 5 tests run
  - CLI: full suite still passes — `cd tools/claude-time && python3 -m unittest test.test_viz_data` exits 0 (124 existing + new BuildWindowDataTests count)
  - [x] P2.1 Add `class BuildWindowDataTests(unittest.TestCase)` to `test/test_viz_data.py`. Placed at end-of-file before `unittest.main()` (after all worker-class tests, since the coordinator depends on every other helper — structurally cleaner than the WBS-suggested "after BuildComparisonDataTests" position).
  - [x] P2.2 `test_empty_window_three_day_shape` — top-level keys, window meta (3 days), day-key set (3 ISO dates), week-key set ({2026-05-25}: window 2026-05-26..28 is Tue–Thu of one ISO week), month-key set ({2026-05}), compare keys, empty-window metrics (engaged_session.wallclock_ms == 0).
  - [x] P2.3 `test_single_day_window_shape` — start==end with one 60-min burst; day_count==1, day/week/month maps each have exactly 1 entry.
  - [x] P2.4 `test_compare_preset_anchors_on_window_end` — window 2026-05-07..2026-05-13; assert WoW `b_start=2026-05-11`, today-vs-trailing `b_start=b_end=2026-05-13`, MoM `b_start=2026-05-01`/`b_end=2026-05-31`. Pins anchor = end_iso, not real-world today. (Note: used `b_start` instead of `b_end` per the WBS hint, because `b_end` for WoW is the containing-week Sunday — `b_start` is the cleaner anchor pin.)
  - [x] P2.5 `test_metrics_cross_check_against_direct_call` — small populated window; assert top-level metrics (engaged_session, ai_agent, tool_call wallclock_ms) equal what `build_metrics` returns when called directly with the same flattened+sorted event list and window dts. Proves no double-counting / partitioning bug.
  - [x] P2.6 `test_end_before_start_raises` — `build_window_data('2026-05-28', '2026-05-26', ...)` raises ValueError.
  - [x] P2.7 `test_90_day_window_smoke` — 2026-03-01..2026-05-29 (90 days, empty events); assert 90 day-entries, 14 Mondays (2026-02-23 through 2026-05-25), and {2026-03, 2026-04, 2026-05} month keys.
  - [x] verify-auto  <!-- parse ok + targeted BuildWindowDataTests 6/6 pass -->
  - [x] verify-self  <!-- both observable outcomes PASS: BuildWindowDataTests 6/6, full Python suite 130/130; no integration boundary (test-harness-only change) -->
  - [x] verify-human  <!-- F11 skipped 2026-05-28: no integration boundary (test-harness-only change); human-confirmed -->
  - [x] verify-codify  <!-- the phase IS the codify — 6 tests landed in P2.1–P2.7; 130/130 Python suite + 122/122 structure check green; no additional tests needed (WP3 will own end-to-end CLI coverage of build_window_data) -->

## Current Node
- **Path:** Feature > Phase 2 > complete — ready to ship
- **Active scope:** WP1 feature complete. Phase 1 [x] + Phase 2 [x]. All 4 verify nodes [x] on both phases.
- **Blocked:** none
- **Unvisited:** none (all phases complete; F16 → ship)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect

- **What changed in our understanding:** The `build_metrics` empty-events path takes `None` window dts but returns a placeholder `_empty_metrics("", "", 0)` that loses the window context — i.e., the empty case zeroes out the window's start/end ISO and day_count. Fix during implementation: always pass real `window_start_dt`/`window_end_dt` (computed from `start_iso`/`end_iso`) even when `all_events` is empty, so the empty-window response still reflects the actual window in `metrics.window`. This was a small but load-bearing deviation from the WBS's "let build_metrics handle the empty case" assumption.
- **Assumptions that held:** The structural pattern reference from the WBS pause-note (v2's `build_comparison_data` at `viz_data.py:605–668`) was spot-on — the coordinator-delegates-to-workers shape transferred 1:1. The compare helpers' "self-partition `events_by_day` internally" claim was correct — passed the full dict and they did the right thing. End-to-end implementation matched the WBS task list (1.1 → 1.6) without re-planning.
- **Assumptions that were wrong:** The WBS task 1.7 ("compare-preset cross-reference: top-level metrics.engaged_session.wallclock_ms should equal sum of day_payloads_by_iso[*].today_total modulo merge semantics") couldn't be cleanly written as a P2 test — `today_total` is not a top-level key in `build_day_data`'s output, and even if computable, "modulo merge semantics" makes the equality hand-wavy. P2.5 substituted a cleaner cross-check: assert top-level `metrics.engaged_session.wallclock_ms` equals `build_metrics(all_events, window_dts)` called directly with the same flattened+sorted event list. This proves no double-counting / no partitioning bug, which was the WBS's actual intent.
- **Approach delta:** Two phase-level deltas from the plan. (1) Placement of `BuildWindowDataTests`: plan said "immediately after `BuildComparisonDataTests`"; shipped at end-of-file before `unittest.main()` since the coordinator depends on every other helper in the file and the structural sort is "workers first, then top-level coordinator." (2) P2.4's anchor pin: plan said assert on `b_end`; shipped using `b_start` because for WoW the `b_end` is the containing-week Sunday (an extra week of arithmetic), whereas `b_start` directly equals `today_monday_iso` — cleaner pin. (3) Mid-stream WBS edit: per user direction during resume, WP4 was revised from "advisory aliases" to "legacy flag removal." Folded into this commit since the WBS already pointed at WP1 as the cycle's entry point and the WP4 revision had no impact on Phase 1 / Phase 2 work.

## Communicate

**Feature complete:** v3 WP1 `build_window_data` has shipped (commit `4dd8d6d`, origin/main). Adds a new top-level coordinator in `viz_data.py` that pre-renders day/week/month/compare-preset sub-payloads + window-level metrics over an arbitrary `(start_iso, end_iso)` window — the data-layer foundation that the rest of the v3 cycle (WP3's `--window` CLI flag through WP12's multi-instance overlap viz) will depend on. Verify by running `python3 -m unittest test.test_viz_data.BuildWindowDataTests -v` from `tools/claude-time/` — should report 6 tests passing.

Requester = operator — closure notice for self-record.

## Notes

- **Structural reference:** v2 `build_comparison_data` (viz_data.py:605–668) is the canonical coordinator pattern in this codebase. WP1's coordinator should mirror its style — delegate to workers, assemble under canonical keys, no business logic in the coordinator itself.
- **Integration-boundary rule:** WP1 is pure data-layer with no consuming UI surface in this WP. The CLI surface arrives in WP3; frontend consumers in Phase 2 of the cycle (WP5–WP9). verify-self for both phases uses CLI smoke tests (the `python3 -c` invocations in observable outcomes). verify-human can use the F11 skip path (no user-facing surface yet) UNLESS Phase 2 surfaces shape questions that need human review.
- **Compare-preset anchor decision:** WBS task 1.5 says "today" as the anchor. Decoded as: `today_iso = end_iso` (the most-recent day in the window). This means a window ending on a historical date generates compare-presets anchored on that date, not on real-world today — which is the right semantic for a pre-rendered payload (otherwise re-emit would be needed every day to refresh the comparison anchor). Pinned by P2.4.
- **Performance is WP2's concern, not WP1's.** WP1 may produce a slow coordinator if naively implemented (90 days × per-day workers + 13 weeks × per-week workers + 3 months × per-month workers + 3 compares). That's WP2's measurement and decision point. WP1 should be correct first; WP2 may direct WP1 changes if perf is unacceptable.
