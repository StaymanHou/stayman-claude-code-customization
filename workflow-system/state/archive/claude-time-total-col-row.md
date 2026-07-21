---
drive_mode: autopilot
---

# Feature: claude-time --by report per-row TOTAL column + grand-total cell

**Workflow:** feature
**State:** ship (complete)
**Created:** 2026-05-18
**Shipped:** 2026-05-18 (commit 3c605f0 on branch feature/claude-code-time-tracking-phase-1, local-only)
**Entry:** plan (small/simple feature — F2)
**Source:** SURFACE-2026-05-18-CLAUDE-TIME-TOTAL-COL-ROW (backlog, high priority, user-designated)
**Drive mode:** autopilot

## Problem Statement

`claude-time report --by <dim>` renders a grouped table with five metric columns (tool, active, reading, thinking, away) plus a bottom TOTAL row that sums each column. The orthogonal complement — a per-row TOTAL that sums those five metrics for a single group — is missing, so the user has to mentally add five cells across each row to answer "how much time did this project consume in total?" The bottom-right cell (grand total = sum of all per-row totals = sum-down of any single column) is also a free sanity check: if the two diagonals don't agree, something is broken.

This is a single-function change to `render_grouped` in `tools/claude-time/claude-time` (lines 208–301). No schema change, no hook change, no reclassifier change, no behavior change to the default (non-`--by`) report. Bounded scope: one new column added to the grouped header, one new cell per row, one bottom-right corner cell. Estimated ≤ 30 LOC of diff.

## Acceptance Criteria

1. **Per-row TOTAL column rendered.** `claude-time report --by <dim>` output (for any `<dim>` in `cwd | session | day`) shows a `total` column header at the rightmost position of the column header row, and each data row shows that row's total = `tool_ms + active_ms + reading_ms + thinking_ms + away_ms`, formatted via `fmt_ms` like the other cells.

2. **Grand-total corner cell rendered.** The bottom TOTAL row (already present) gains a rightmost cell equal to `sum_of_per_row_totals` = `tot_tool + tot_active + tot_reading + tot_thinking + tot_away`. This value equals the sum-down of any single column would yield only if the table were a square — it's actually the sum of *all* cells in the body, which is the same as the sum of all per-row totals OR the sum of all column totals (cross-check).

3. **Default (non-`--by`) report unchanged.** `claude-time report` (no `--by`) produces byte-identical output to before this feature. The change is scoped to `render_grouped` only; `render_report` is untouched.

4. **Column alignment preserved.** The new `total` column uses a consistent right-aligned width matching `fmt_ms` output (likely 8 chars, matching `tool` / `active` / `reading`). Header and data rows align column-wise — no ragged edges.

5. **Empty-window message preserved.** `--by cwd --date 1970-01-01` still prints `(no events in window: ...)` with no table rendered. The render_grouped early-return at the top of the function handles this.

6. **All existing test_cli.sh assertions still PASS.** The 25 assertions added in the prior two features (cwd filter, session filter, config override, --by cwd/session/day, project_names aliasing, auto-alias) continue to PASS with no modification. New assertions are *added*, not substituted.

7. **Sanity-check cross-pivot.** For any non-empty grouped report, `sum_of_per_row_totals == sum_of_column_totals`. The new bottom-right cell IS this value (either path produces it), so the assertion is "the cell exists and equals both diagonals" — codified as a test that constructs a known-input table and asserts equality.

## Out of Scope

- Schema migration (none needed).
- Hook changes (none needed).
- Reclassifier changes (none needed).
- Changes to `render_report` (the default non-grouped report). The bottom TOTAL row in `render_report` is for the per-session gap buckets only and is a different shape.
- Color, bolding, or any styling change to mark the TOTAL column/cell as "totals" vs body cells. Plain text only.
- A separate `--total-only` flag or any new CLI surface. The new column always renders in `--by` mode; there is no opt-out.
- Multi-dimension grouping or sub-totals (out of scope of the parent `--by` feature too).

## Work Tree

- [x] Phase 1: per-row TOTAL column + grand-total cell  <!-- status: [x] -->
  **Observable outcomes:**
  - CLI: `claude-time report --by cwd` against a DB with ≥ 2 cwd rows exits 0; stdout column-header line ends with `total` (rightmost token); each data row has 6 metric cells (was 5); bottom TOTAL row has 6 metric cells (was 5).
  - CLI: For a constructed DB with known per-event durations, the bottom-right cell value equals both (a) the sum of all per-row totals and (b) the sum of all column totals. Verifiable by piping output through a `grep`+`awk` one-liner in `test_cli.sh`.
  - CLI: `claude-time report` (no `--by`) produces byte-identical output to a snapshot captured before the change — verified by `diff` against a pre-feature recording of one fixed-input run.
  - CLI: `claude-time report --by cwd --date 1970-01-01` exits 0 and prints `(no events in window: ...)` with no table.
  - [x] P1.1 Extended `render_grouped` in `tools/claude-time/claude-time`: added `'total':>8` to header f-string, computed `row_total` on-the-fly in render loop (no tuple change — value isn't needed for sort), computed `grand_total = tot_tool + tot_active + tot_reading + tot_thinking + tot_away` for bottom row. ~6 LOC diff total. Smoke-tested on a 2-cwd 6-event DB: header rightmost token is `total`, per-row totals match expected sums, grand total cross-checks against both column-sum-down and row-sum-across.  <!-- status: [x] -->
  - [x] verify-auto — py_compile clean; test_cli.sh 25/25 PASS (full regression guard for existing --by behavior held).  <!-- status: [x] -->
  - [x] verify-self — all 4 observable outcomes PASS. (1) `--by cwd` exit 0, header rightmost = `total`, each data row + TOTAL row has 6 metric cells. (2) Integer-ms cross-check: sum-of-col-totals == sum-of-per-row-totals == grand_total cell value (131300ms in test scenario). Note: display-string reconstruction shows minor discrepancies due to `fmt_ms` truncation (e.g., 119800ms → `1m59s` → reparses as 119000ms) — pre-existing CLI rendering behavior, not a feature regression. (3) Default report (no `--by`) renders 4 `──` section headers, no `Grouped by` line. (4) `--by cwd --date 1970-01-01` exits 0 with empty-window message.  <!-- status: [x] -->
  - [x] verify-human — all 4 leaves approved by user on live data.  <!-- status: [x] -->
    - [x] P1.verify-human.1: `--by cwd` on today's data — live data spot-check approved
    - [x] P1.verify-human.2: `--by cwd --weekly` — approved
    - [x] P1.verify-human.3: `--by session` + `--by day` — approved
    - [x] P1.verify-human.4: column placement, header alignment, value formatting acceptable — approved
  - [x] verify-codify — added 4 new assertions to test_cli.sh (header rightmost token, 6-cell count, integer-ms grand-total math cross-check, empty-window regression). test_cli.sh 25→29 PASS; full claude-time suite 70/70 (test_cli 29 + test_reclassify 24 + test_hook 17). No regressions.  <!-- status: [x] -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** finalize (shipped at commit 3c605f0; transitioning to finalize)
- **Blocked:** none
- **Unvisited:** finalize
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->

## Retrospect

- **What changed in our understanding:** Nothing major. One small subtlety surfaced during verify-self: a string-level cross-check of `bottom-right cell == sum-of-row-totals == sum-of-col-totals` *can* show a small discrepancy because `fmt_ms` is lossy (e.g., 119800ms → `1m59s` → reparses as 119000ms). The cross-check holds at the integer-ms level (where it must), so the test was written at that level via direct `reclassify` imports rather than via output-string parsing.
- **Assumptions that held:** All plan assumptions held. Single-function diff in `render_grouped`; ≤30 LOC of source (actual: 6 LOC effective); existing 25 test_cli.sh assertions PASS untouched; default (non-`--by`) report byte-identical (regression guard already in assertion #17).
- **Assumptions that were wrong:** None.
- **Approach delta:** None. Implemented compute-on-the-fly per row (vs. extending the `rows` tuple to 7-wide) exactly as the plan's "decide at impl time — prefer compute-on-the-fly" guidance suggested. Test codification level (integer-ms via direct `reclassify` import, not display-string parsing) was a small decision made during verify-codify based on the verify-self lossiness observation.

## Communicate

> **Feature complete:** `claude-time-total-col-row` has shipped. `claude-time report --by <dim>` now renders a rightmost `total` column on the grouped output — each row shows its 5-metric sum, and the bottom-right cell shows the grand total (with cross-pivot sanity: sum-of-cols == sum-of-rows at integer-ms). Verify with `claude-time report --by cwd` on real data. Requester = operator — closure notice for self-record.
