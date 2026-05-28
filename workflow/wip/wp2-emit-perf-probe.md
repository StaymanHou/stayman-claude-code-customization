---
workflow: feature
state: verify-codify (all phases complete; ready to ship)
drive_mode: autopilot
cycle: claude-time-visualize-v3
wp: WP2
size: S
type: probe
timebox: half-day
created: 2026-05-28
updated: 2026-05-28
---

# Feature: v3 WP2 — Emit-time perf probe + 90-day Go/No-Go

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-28

## Problem Statement

v3 WP1 shipped `build_window_data` (commit `4dd8d6d`) — the top-level coordinator that pre-renders day/week/month/compare-preset sub-payloads + window-level metrics over a `(start_iso, end_iso)` window. The v3 WBS locks **90 days (MTD + 2 prior months)** as the default emit window, but the cost of that choice against the user's real DB is unmeasured. Phase 0's job is to either confirm the default fits the user's "slightly longer load time and larger file size is acceptable" tolerance, or counter-propose a smaller default (WBS's fallback is 60 days). WP2 is the probe that closes Phase 0 and unblocks Phase 1 (WP3/WP4 CLI surface) and Phase 2 (WP5–WP9 frontend routing) — both of which would otherwise be built on an emit cost the user could later reject, forcing a Phase-0 rework mid-cycle.

**Probe — not a build artifact.** WP2's deliverable is a *decision* recorded in the retrospect at `workflow/archive/wp2-emit-perf-probe.md`, backed by a measurement script that produces reproducible numbers. The script itself is permanent (pinned into `tools/claude-time/test/perf_window_data.py` for future re-measurement) but its initial finding is the load-bearing output.

## Success Criterion (from WBS)

Documented timing measurement (5 runs, min/avg/max) + emit-size measurement (bytes) + **Go/No-Go decision** on the 90-day default OR a counter-proposal (e.g., 60 days). Rationale captured in retrospect.

## Budget thresholds (the test the measurement is against)

- **Wall-clock per emit:** target ≤ ~2s (within v2's perceived "slightly longer" tolerance); hard ceiling ~4s before a counter-proposal is warranted.
- **Emit-size per window:** target ≤ ~500KB; hard ceiling ~1MB before counter-proposal.
- **Window-size scan:** 30, 60, 90, 120 days. 30/60 establish the trend; 90 is the candidate default; 120 confirms the curve (if 120 is sublinear in cost, the 90 budget is comfortable; if superlinear, 90 may be near a knee).

## Work Tree

- [x] Phase 1: Perf script + measurement + 90-day Go/No-Go decision  <!-- status: [x] complete 2026-05-28 — all impl tasks (P1.1-P1.4) + all 5 verify nodes complete. Decision: 90-day default CONFIRMED. -->
  **Observable outcomes:**
  - CLI: `CLAUDE_TIME_DIR=<user's real ct_dir> python3 tools/claude-time/test/perf_window_data.py` exits 0 and prints a Markdown-formatted results table to stdout containing 4 window rows (30/60/90/120 days) × columns (min_ms, avg_ms, max_ms, emit_bytes_min, emit_bytes_avg, emit_bytes_max).
  - CLI: Re-running the same command (5 trials per window already built in) produces stable numbers (avg_ms within ±25% across two consecutive script runs, allowing for SQLite warm/cold cache variance).
  - CLI: The script accepts `--runs N` (default 5), `--windows 30,60,90,120` (default), and `--db-path PATH` (default `$CLAUDE_TIME_DIR/events.sqlite`) — verifiable via `--help` exit 0 listing all three flags.
  - File: `tools/claude-time/test/perf_window_data.py` exists, has a docstring referencing WP2 and the 90-day default decision, and imports cleanly (`python3 -c "import importlib.util; s=importlib.util.spec_from_file_location('p', 'tools/claude-time/test/perf_window_data.py'); m=importlib.util.module_from_spec(s); s.loader.exec_module(m); assert hasattr(m, 'main')"` exits 0).
  - Decision artifact: At verify-codify time, the WIP file's `## Decision` section is populated with one of: `(a) 90-day default CONFIRMED — measurements within budget`; `(b) 90-day default REJECTED — counter-proposal: <N>-day window, rationale: <reason>`. The decision is reflected back into `docs/product/wbs.md` Phase 0 section + Decisions-locked list item #1.
  - [x] P1.1 Create `tools/claude-time/test/perf_window_data.py` — mirrors `seed_perf_dataset.py` shell (argparse + `CLAUDE_TIME_DIR` env read + docstring header). New: imports `build_window_data` from `viz_data`, also `_load_events_by_day` (or whichever helper `_cmd_visualize` uses to materialize `events_by_day` — verify the exact name at impl time), and `cfg`/`auto_alias_fn` constructors. For each window size in `[30, 60, 90, 120]`: compute `(start_iso, end_iso)` rolling back from `date.today()`; load events; run `build_window_data` N times under `time.perf_counter`; serialize the payload to JSON and measure `len(json.dumps(...))` once per run. Report stdout as a Markdown table.  <!-- status: [x] complete — script created at tools/claude-time/test/perf_window_data.py. Uses importlib to load the hyphenated `claude-time` entrypoint as a module (giving real `_load_window_events`, `_auto_alias_for_cwd`, `load_config`). Importability + --help smoke tests pass. -->
  - [x] P1.2 Run the script against the user's real DB (`CLAUDE_TIME_DIR=<user's actual dir>`). Capture the stdout table verbatim into a `## Results` block at the top of the script's docstring AND into this WIP file's `## Results` section below.  <!-- status: [x] complete — ran against ~/.claude-time/events.sqlite 2026-05-28; first attempt failed due to importlib loader-inference for hyphen-named entrypoint, fixed by using SourceFileLoader explicitly; re-ran successfully. Results captured in both script docstring and WIP. -->
  - [x] P1.3 Apply the budget thresholds (above) to the measured 90-day row. Write the `## Decision` section: either CONFIRMED with brief rationale, or REJECTED with counter-proposal (which N-day) + rationale grounded in the measurement.  <!-- status: [x] complete — decision = CONFIRMED; see ## Decision section below for rationale grounded in measurement. -->
  - [x] P1.4 If decision is REJECTED, update `docs/product/wbs.md`:
        (a) Phase 0 WP2 section — append a `**Result:**` line stating the new default
        (b) "Decisions locked at WBS approval" #1 — flip the locked value
        (c) WP3 task 3.4 — update the default-window reference
        If decision is CONFIRMED, append only the `**Result:**` line to WP2 to mark it as measured (no other wbs.md changes needed).  <!-- status: [x] complete — decision = CONFIRMED, so only WP2 section in wbs.md got the **Result:** line + 🟢 IN-PROGRESS heading flag. Decisions-locked #1 and WP3 task 3.4 untouched (90-day default unchanged). -->
  - [x] verify-auto  <!-- status: [x] complete 2026-05-28 — 4 scoped checks PASS: py_compile, --help exit 0, importability/main symbol present, --runs 1 --windows 30 smoke run produces well-formed Markdown row. No regressions. -->
  - [x] verify-self  <!-- status: [x] complete 2026-05-28 — 5/5 observable outcomes PASS, 0 BLOCKING, 0 COSMETIC. Direct verification (no subagent — phase has no browser surface, all outcomes are CLI/file-shape mechanically checkable from orchestrator). No integration boundary (phase adds isolated new artifacts only). Stability check: re-run avg_ms deltas 4-9%, all within ±25% target. -->
  - [x] verify-human  <!-- status: [x] complete 2026-05-28 — user ACK'd ("confirmed") the 90-day default. No integration boundary (isolated new artifacts: perf script + WIP sections + wbs.md result-line). F11 skip avoided because the probe's load-bearing deliverable IS the human's decision ACK. -->
    - [x] P1.verify-human.1 Decision review: user reads `## Results` + `## Decision` blocks and either ACK's the 90-day default CONFIRMED call, or asks for a counter-decision / re-measurement. (This is the load-bearing review for a probe — not a UI sanity check.)  <!-- status: [x] confirmed 2026-05-28 — user response: "confirmed" -->
  - [x] verify-codify  <!-- status: [x] complete 2026-05-28 — added 3 durable pins to tests/check-structure.sh Phase 5b (existence, py_compile, --help exit 0). No numeric thresholds pinned per the plan (flaky-CI risk). Structure: 122 → 125 pins, 0 FAIL. Python suite: 130 / 0 FAIL (no regressions). -->

## Current Node
- **Path:** Feature complete (all phases [x])
- **Active scope:** ship
- **Blocked:** none
- **Unvisited:** (none — all phases complete; F16 → ship → finalize)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Results

Measured 2026-05-28 against `~/.claude-time/events.sqlite`, default args (`--runs 5 --windows 30,60,90,120`):

```
# build_window_data perf probe
# db: /Users/stayman/.claude-time/events.sqlite
# runs per window: 5
# windows: [30, 60, 90, 120]
# today: 2026-05-28

| window_days | start_iso  | end_iso    | min_ms | avg_ms | max_ms | emit_bytes_min | emit_bytes_avg | emit_bytes_max |
|-------------|------------|------------|--------|--------|--------|----------------|----------------|----------------|
|          30 | 2026-04-29 | 2026-05-28 |    990 |   1037 |   1194 |         421579 |         421579 |         421579 |
|          60 | 2026-03-30 | 2026-05-28 |    989 |   1001 |   1014 |         426200 |         426200 |         426200 |
|          90 | 2026-02-28 | 2026-05-28 |   1003 |   1012 |   1026 |         431016 |         431016 |         431016 |
|         120 | 2026-01-29 | 2026-05-28 |   1018 |   1045 |   1142 |         435586 |         435586 |         435586 |
```

**Observations:**
- 30→120 day wall-clock spans 990ms to 1194ms — essentially flat. Cost is dominated by fixed overhead (SQLite open, module import, compare-preset compute), not per-day work.
- Emit-size grows ~4.6KB per 30 days — linear, but small slope. 90→120 day emit growth is ~4.6KB / ~1% — negligible.
- Variance per window is ~150ms peak-to-trough, OS-jitter level, well under the ±25% stability target.
- Emit-size is deterministic (min == avg == max per window — JSON serialization of the same payload).


## Decision

**90-day default CONFIRMED.**

- **90-day wall-clock:** avg 1012ms — 50% of the 2000ms target budget, 25% of the 4000ms hard ceiling. PASS.
- **90-day emit-size:** 431KB — 86% of the 500KB target budget, 43% of the 1MB hard ceiling. PASS.
- **Trend across 30/60/90/120:** approximately flat in wall-clock (990→1018ms min, 1037→1045ms avg) and linear-with-small-slope in emit-size (~4.6KB per 30 days). The cost is dominated by **fixed overhead** — SQLite connection setup, module import, and compare-preset compute (WoW / today-vs-trailing / MoM all run independent of window size). Per-day work (day_payloads_by_iso build, events read) is a small fraction of total cost. **This finding is more important than the 90-day specific result:** it means the window-size knob is approximately free within this range — shrinking to 60 days saves ~5KB and 10ms; expanding to 180 days would cost ~14KB and stay well under budget.
- **No counter-proposal.** 90 days is well within budget on both dimensions.

**Downstream implication:** WP3's `--window` flag default stays at 90 days (per the WBS lock at "Decisions locked at WBS approval" #1). No wbs.md edits needed — P1.4 reduces to appending a `**Result:**` line to the WP2 section.


## Verify-codify scope (for the probe — written at plan time, executed later)

Codify's normal regression-securing role is awkward for a probe. The script IS the artifact; there's no "behavior" to regression-pin in the usual sense. So:

- **Pin the script's importability** in `tests/check-structure.sh` or as a one-line smoke (whichever the project convention favors at codify time — likely structure.sh given the existing 122 pins).
- **Pin the script's `--help` exit 0** as a smoke (small, durable, catches argparse breakage).
- **Do NOT** pin specific numeric thresholds — the script measures, it does not assert. Thresholds are documented in the decision, not enforced in code. If `build_window_data` later regresses 10x, the next re-run of the perf script will surface it; pinning a numeric threshold would create a flaky CI dependency on the host's wall-clock variance.
- **Document the re-run procedure** in the script docstring: how to re-measure if `build_window_data` materially changes (any WP that touches `viz_data.py` internals: WP3 indirectly, future cycle WPs more directly).

## Out of scope (explicit)

- **Flag-name decision** (`--window 90d` vs `MTD-2` vs explicit range) — deferred to WP3 feature-spec, not WP2. The probe runs against `build_window_data` directly, not through a CLI flag.
- **Frontend perf measurements** (paint time, hydration cost) — not Phase 0's concern; if the emit-size budget holds, downstream paint cost is the same as v2 plus the new sub-payload reads (which are O(1) hash lookups, not work).
- **Test-DB seeding** — the probe runs against the *user's real DB*, which is what the v3 default will face in practice. Synthetic data (e.g., `seed_perf_dataset.py`-style) would test scaling but not the actual operating point. If the real DB is too small to be representative (e.g., <30 days of events), surface that at P1.2 and decide whether to seed up or just accept the small-DB measurement (which would confirm a lower bound and be conservative for the 90-day Go decision).
- **Cold vs warm SQLite cache differentiation** — measure as-is; report variance. If the variance is wider than the budget margin, surface at verify-self.
