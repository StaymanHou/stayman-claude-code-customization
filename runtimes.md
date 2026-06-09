---
shape: runtime-registry
updated: 2026-06-09
---

# Runtime Registry

Per-project record of last-observed wall-clock runtimes for tracked long-running commands. Read before invoking a tracked command (use `**Use timeout:**`), update after completion or kill. See `~/.claude/CLAUDE.md` → `## Long-running commands (GLOBAL)` → `### Runtime registry` for the read+update discipline.

## ./tests/check-structure.sh
- **Last:** ~240s (2026-06-09)
- **Use timeout:** 408000
- **History:**
  - ~240s — 2026-06-09  <!-- foreground run under 408s timeout, no auto-bg; wall time not exactly measured but consistent with prior 232s observation -->
  - 232s — 2026-06-07
  - 360s — 2026-06-07  <!-- inflated by orphaned-process concurrency hang; see SURFACE-2026-06-07-CHECK-STRUCTURE-DRY-RUN-CONCURRENCY-FRAGILE -->

## ./tests/run-tests.sh
- **Last:** 3097s (2026-06-07)
- **Use timeout:** 600000
- **Note:** computed timeout (`ceil(3097 * 1.5 + 60) * 1000 = 4706000 ms`) exceeds Bash tool hard cap of 600000 ms (10 min). Clamped to 600000. **This command WILL auto-background** when invoked via Bash; the agent MUST wait for the `BashOutput` completion notification per Rule 2 — do not re-invoke. Use `--group <name>` or `--filter-model default` partitions to keep individual invocations under the 10-min cap when possible.
- **History:**
  - 3097s — 2026-06-07
