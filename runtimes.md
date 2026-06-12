---
shape: runtime-registry
updated: 2026-06-12
---


<!-- Bookkeeping: `./tests/run-tests.sh --id <8-batch> --model sonnet` observed at 197s (2026-06-09 verify-codify-scenarios-need-sonnet-tag task). Per-scenario sonnet ≈ 25s. Useful estimator for future `--id <N-batch> --model sonnet` calls: `timeout_ms = ceil(N * 25 * 1.5 + 60) * 1000`. Below 384000ms (~6.4 min) for N ≤ 8 scenarios. -->

# Runtime Registry

Per-project record of last-observed wall-clock runtimes for tracked long-running commands. Read before invoking a tracked command (use `**Use timeout:**`), update after completion or kill. See `~/.claude/CLAUDE.md` → `## Long-running commands (GLOBAL)` → `### Runtime registry` for the read+update discipline.

## ./tests/check-structure.sh
- **Last:** 43s (2026-06-12)
- **Use timeout:** 125000
- **History:**
  - 43s — 2026-06-12  <!-- post-subagent-dispatch-back-reference-pin task; 214/214 PASS, 0 FAIL (was 210/210; +4 from new Phase 10 (f) back-reference pin: 2 references × 2 dispatch-aware skills). Bump from 31s → 43s likely due to the new inner while-read loop per skill iterating subagent_type matches + per-match agent file read. -->
  - 31s — 2026-06-12  <!-- verify-self-and-review-quality-subagent-dispatch Phase 1 verify-auto; 200/200 PASS no FAILs (baseline unchanged — Phase 1 only adds new agent dirs, no pin changes yet). Bump from 18s → 31s likely due to 2 new agents/* entries iterating through Phase 3c structural pins. -->
  - 18s — 2026-06-10  <!-- mid reproduce-as-redirect-from-build Phase 3 complete; 178/178 PASS, 0 FAIL (was 175 → +3: F36 row on feature-build, F37+F37b rows on feature-reproduce) -->
  - 18s — 2026-06-10  <!-- mid reproduce-as-redirect-from-build Phase 2 complete; 175 PASS + 1 expected FAIL (ROW_MAPPING gap, resolved in Phase 3) -->
  - 18s — 2026-06-10  <!-- mid reproduce-as-redirect-from-build Phase 1; 175/175 PASS, no FAILs (docs/AGENTS.md only, no SKILL.md changes yet) -->
  - 18s — 2026-06-10  <!-- post-cheat-sheet-agents-drift; 175/175 PASS, no FAILs (was 150/150; +25 from Phase 9b drift assertions: 1 AGENTS.md-table-parse + 24 per-row matches across 8 SKILL files) -->
  - 17s — 2026-06-10  <!-- post-feature-finalize-tick-wbs-task-checkboxes; 141/141 PASS, no FAILs (was 140/140; +1 from new pin) -->
  - 16s — 2026-06-10  <!-- post-I20-scenario-add; 139/139 PASS, no FAILs -->
  - 17s — 2026-06-09  <!-- post-settings-fixture-model-drift task; 139/139 PASS, no FAILs -->
  - ~16s — 2026-06-09  <!-- post-dry-run-bypass; subprocess invocation replaced with inlined python YAML count (see check-structure-sigterm-propagation feature, archived 2026-06-09); the >5min runtime is gone -->
  - ~240s — 2026-06-09  <!-- foreground run under 408s timeout, no auto-bg; wall time not exactly measured but consistent with prior 232s observation -->
  - 232s — 2026-06-07
  - 360s — 2026-06-07  <!-- inflated by orphaned-process concurrency hang; see SURFACE-2026-06-07-CHECK-STRUCTURE-DRY-RUN-CONCURRENCY-FRAGILE -->

## ./tests/run-tests.sh
- **Last:** 3097s (2026-06-07)
- **Use timeout:** 600000
- **Note:** computed timeout (`ceil(3097 * 1.5 + 60) * 1000 = 4706000 ms`) exceeds Bash tool hard cap of 600000 ms (10 min). Clamped to 600000. **This command WILL auto-background** when invoked via Bash; the agent MUST wait for the `BashOutput` completion notification per Rule 2 — do not re-invoke. Use `--group <name>` or `--filter-model default` partitions to keep individual invocations under the 10-min cap when possible.
- **History:**
  - 3097s — 2026-06-07
