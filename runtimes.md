---
shape: runtime-registry
updated: 2026-07-13
---


<!-- Bookkeeping: `./tests/run-tests.sh --id <8-batch> --model sonnet` observed at 197s (2026-06-09 verify-codify-scenarios-need-sonnet-tag task). Per-scenario sonnet ≈ 25s. Useful estimator for future `--id <N-batch> --model sonnet` calls: `timeout_ms = ceil(N * 25 * 1.5 + 60) * 1000`. Below 384000ms (~6.4 min) for N ≤ 8 scenarios. -->

# Runtime Registry

Per-project record of last-observed wall-clock runtimes for tracked long-running commands. Read before invoking a tracked command (use `**Use timeout:**`), update after completion or kill. See `~/.claude/CLAUDE.md` → `## Long-running commands (GLOBAL)` → `### Runtime registry` for the read+update discipline.

## ./tests/check-structure.sh
- **Last:** 17s (2026-07-13)
- **Use timeout:** 90000
- **History:**
  - 17s — 2026-07-13  <!-- backlog-paydown WP1 verify; 353 PASS / 1 FAIL. The 1 FAIL is the SAME pre-existing host settings-fixture drift (now 5 keys: disableClaudeAiConnectors, tui, cleanupPeriodDays=99999, statusLine.padding, env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC — SURFACE-2026-06-26, WP2's target). WP1 was docs/skill-prose only; touched no settings fixture. All Phase 3b debug-* Category-Context + Phase 13 design-priors pins green after the edits. PASS count flat vs Phase-3's 353 (no pins added/removed by WP1). -->
  - 17s — 2026-07-03  <!-- memory-location-symlink Phase 3 verify-auto; 353 PASS / 1 FAIL (+13 from Phase-2's 340: new [Phase 14] — 6 primitive-existence/exec + 1 realpath-slug-footgun guard + 3 snippet-convention + 2 both-hosts-wire-ensure-link + 1 store-learning-convergence). The 1 FAIL is the SAME pre-existing host settings-fixture drift (3 keys). Caught+fixed a self-introduced Phase-12 path-qualification regression mid-verify (2 bare .claude/ in the new snippet subsection → qualified <proj-dir>/). -->
  - 17s — 2026-07-03  <!-- memory-location-symlink Phase 2 verify-codify; 340 PASS / 1 FAIL (SAME pre-existing host settings-fixture drift — now 3 keys: disableClaudeAiConnectors + cleanupPeriodDays=99999 + statusLine.padding; SURFACE-2026-06-26/06-30. Unrelated to this feature — Phase 2 was a migration run + tools/memory-link/ scripts, never touched tests/fixtures/settings.json). PASS jumped 334→340 vs 2026-06-30 baseline: likely env/host settings-check counting; no NEW structure pins added by Phase 2 (pins land in Phase 3). -->
  - ~22s — 2026-06-30  <!-- incident store-learning-wrong-project-claude-md mitigate verify; 334 PASS / 1 FAIL (same pre-existing settings-fixture drift, SURFACE-2026-06-30-SETTINGS-FIXTURE-DISABLECLAUDEAICONNECTORS-DRIFT — unrelated to the SKILL.md prose fix; path-qualification Phase 12 PASS). No new structure pins (behavioral fix covered by scenario S25). -->
  - ~22s — 2026-06-30  <!-- util-backlog-paydown Phase 3; 334 PASS / 1 FAIL (pre-existing host settings-fixture drift `disableClaudeAiConnectors`, unrelated — SURFACE-2026-06-30-SETTINGS-FIXTURE-DISABLECLAUDEAICONNECTORS-DRIFT). No new pins added (B1: util-* keeps documented no-pin status quo). -->
  - 21s — 2026-06-25  <!-- artifact-tracking-policy Phase 4 verify-auto; 302/0 PASS (+4 from 298: Phase 12 gained reflect leading-label + no-trailing-form + CLAUDE.md override-section + no-stale-gitignored-claim pins). -->
  - 20s — 2026-06-25  <!-- artifact-tracking-policy Phase 3 verify-auto; 298/0 PASS (+4 from 294: Phase 12 gained 4 skill-reconciliation pins — session-store-learning canonical-path + policy-keyed git + forbids-gitignore-inspection + product-context reconcile-owner). -->
  - 20s — 2026-06-25  <!-- artifact-tracking-policy Phase 2 verify-auto; 294/0 PASS (+3 from 291: Phase 12 gained 3 artifact-tracking-policy pins — GLOBAL section exists + track-by-default rule + override mechanism. Phase 1 pin also refined to strip fences/allow notation token). -->
  - 20s — 2026-06-25  <!-- artifact-tracking-policy Phase 1 verify-auto; 291/0 PASS (+1 from prior 290: new Phase 12 path-qualification pin — no bare .claude/ in prompts). -->
  - 17s — 2026-06-25  <!-- incident autopilot-askuserquestion-pauses resolve (I18); 290/0 PASS, fully green. Confirmed the codify-era "1 baseline FAIL" caveat is stale (fixed 2026-06-24 commit 93677f0). No pins added at resolve. -->
  - 17s — 2026-06-24  <!-- phase7-filter-claudesk follow-on; 290/0 PASS. Phase 7 now strips claudesk hooks from both sides via strip_host_specific() before diffing (replaced the stopgap that parked all 3 events in INTENTIONAL_DIFFS); UserPromptSubmit fully drift-checked again, only Notification/Stop remain documented diffs. Negative test verified (broken claude-time cmd → Phase 7 FAIL). PASS count unchanged. -->
  - 17s — 2026-06-24  <!-- remove-telegram-hook task; 290/0 PASS (was 289/1 — the prior baseline FAIL was the live-settings claudesk-hook drift, now resolved by adding hooks.UserPromptSubmit to INTENTIONAL_DIFFS + removing the telegram permission from the fixture). Phase 5 telegram hook-integrity block (~8 assertions) removed; net PASS count near-flat. -->
  - 17s — 2026-06-23  <!-- incident autopilot-askuserquestion-pauses codify; 281 PASS / 1 baseline FAIL (unrelated live-settings claudesk-hook drift). +13 from prior 268: Phase 9 (4) AskUserQuestion-on-AUTO prohibition pin × 9 feature skills + Phase 9 (3b) AUTO-exit rule × 4 orchestrators. -->
  - 18s — 2026-06-19  <!-- docker-daemon-vs-container-distinction verify-codify; 269/0 PASS (+2 from prior 267: two new grep_check pins on skills/product-context/SKILL.md — daemon-unreachable hard-blocker + container-down self-start). -->
  - 17s — 2026-06-19  <!-- docker-daemon-vs-container-distinction verify-auto; 267/0 PASS. No pins added (prose-only edit to skills/product-context/SKILL.md:70 daemon-vs-container clause). Faster wall-clock than prior runs (warm fs cache). -->
  - 33s — 2026-06-13  <!-- verify-sh-contains-required Phase 2 verify-codify; 249/251 PASS, 2 baseline FAILs (unchanged). +4 PASS from prior 245: Phase 1 scenario YAML integrity got 4 new grep_check pins (P10b exists + contains_required_any used + CLAUDE.md documents both new fields). -->
  - 33s — 2026-06-13  <!-- verify-sh-contains-required Phase 1 verify-codify; 245/247 PASS, 2 baseline FAILs (unchanged). +13 PASS from prior 232: Phase 3e added 13 vr_check unit cases (A-M) covering verify_result backward-compat + new contains_required/contains_required_any AND/ANY behavior. -->
  - 31s — 2026-06-13  <!-- verify-sh-contains-required Phase 1 verify-auto; 232/234 PASS, 2 baseline FAILs (SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX, unchanged). +4 PASS from prior 228; likely the iterating cheat-sheet Phase 9 loop counting feature-* rows. No pins added by this feature. -->
  - 31s — 2026-06-12  <!-- post-debug-within-skill-structural-pins task; 228/228 PASS, 0 FAIL (was 214/214; +14 from Phase 3b extension: 7 new pins × 2 debug-* skills covering 6-required-sections, argument-hint frontmatter, Gate-Check-first-subheading, termination-token regex). Runtime unchanged from baseline — the new pins are all `grep_check` calls (no subprocess/loop overhead added). -->
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
