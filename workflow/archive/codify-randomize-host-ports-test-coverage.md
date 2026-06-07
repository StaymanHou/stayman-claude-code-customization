---
task: codify-randomize-host-ports-test-coverage
state: act (complete)
drive_mode: autopilot
created: 2026-06-06
source: docker-init-randomize-host-ports finalize retrospect — bullet shipped without test coverage
---

# Task: Codify randomize-host-ports guidance with test coverage

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-06-06

## Problem Statement
The `docker-init-randomize-host-ports` feature shipped a "Randomize host ports" bullet to `skills/product-context/SKILL.md` Variant A (commit `5872554`) but landed with no regression net — the WIP verify-codify note declared "no new tests needed (pure prose, no executable behavior)." Two regressions are currently undetected: (a) accidental bullet deletion in a future product-context edit, (b) the model under `/product-context` ceasing to emit the randomize guidance even when the SKILL.md still contains it.

## Context
- Shipped bullet location: `skills/product-context/SKILL.md` (lines ~66; inside Variant A block, between "First-run bootstrap" and "Rule for agents and humans alike"). Key anchor strings: `Randomize host ports`, `ephemeral range`, `49152`.
- Existing structural-pin harness: `tests/check-structure.sh` — uses `grep_check <desc> <file> <pattern> <min_count>` helper at `tests/check-structure.sh:32-44`. Adds to PASS/FAIL counters. Currently 124 PASS / 1 FAIL (the unrelated SETTINGS-FIXTURE-MODEL-DRIFT pre-existing item).
- Existing behavioral-scenario harness: `tests/scenarios/product.yaml` — P10 is the only product-context scenario, asserts transition only. Harness (`tests/run-tests.sh`) runs `claude --print` with `--disallowed-tools Edit,Write,NotebookEdit` and a `SHARED_PROMPT` "Do NOT actually create or modify any files" — model describes what it WOULD write. `contains_any` is case-insensitive substring grep against `result_text`.
- P10 uses fixture `tests/fixtures/product/wbs-done/` (arch.md is minimal — Python/Click/CLI, no Dev Env variant declared) + `tests/fixtures/CLAUDE.md` (already mentions "Docker Compose" in tech stack and "docker compose exec app" in conventions — predisposes the model toward Variant A).
- Verify discipline: `tests/run-all.sh` is the two-pass haiku→sonnet sweep; new scenarios start untagged (haiku). Per `CLAUDE.md` test discipline: tag `model: sonnet` only after observing haiku noise.

## Work Tree

- [x] T1 Add `grep_check` for randomize-host-ports bullet presence to `tests/check-structure.sh`
- [x] T2 ~~Add new P10b behavioral scenario to `tests/scenarios/product.yaml`~~ → reverted at T5 — the harness's `verify_result` short-circuits on `transition_id` match; `contains_any` only fires as SOFT_PASS fallback. P10b couldn't bite. Surfaced harness limitation as SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT.
- [x] T3 Run `./tests/check-structure.sh` — confirmed: 126 PASS / 1 FAIL (the +2 grep_checks both passed; lone FAIL is the pre-existing unrelated settings-fixture drift, unchanged)
- [x] T4 Run `./tests/run-all.sh` (two-pass sweep) — `run-all.sh` wrapper crashed on pre-existing unbound-variable bug (SURFACED to backlog). Worked around by invoking `run-tests.sh` twice manually. Pass 1 (haiku, 134 untagged scenarios): 83 PASS, 33 SOFT_PASS, 4 FAIL, 14 FLAKY — all 4 FAILs unrelated/pre-existing (P2 transition flake, S10/S12/S14 session-orchestrator prose). P10b PASSed cleanly on haiku in suite context. Pass 2 (sonnet, 3 tagged scenarios): 2 PASS / 1 FLAKY-now-pass / 0 FAIL.
- [x] T5 Bite-verification:
  - **Structural pins:** ✅ BITES. Removed the bullet from SKILL.md, ran `check-structure.sh` → 124 PASS / 3 FAIL (both new grep_checks fired correctly + the unrelated fixture drift). Restored SKILL.md, suite returns to 126 PASS / 1 FAIL.
  - **Behavioral scenario (P10b):** ❌ DOES NOT BITE. Removed the bullet from SKILL.md, ran P10b with weak `contains_any` anchors (`ephemeral|49152|randomize`) → PASSed. Strengthened anchors to SKILL.md-prose-specific (`lsof -nP -iTCP|random.randint(49152, 65535)|58329:5173`) → still PASSed. Root cause: verify.sh treats `transition_id` match as authoritative PASS; `contains_any` is only consulted as SOFT_PASS fallback when transition match fails. Harness limitation, not a P10b design fix-up. **Action:** removed P10b from product.yaml, surfaced limitation as SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT.
- [x] T6 (added mid-task) — Persist the randomize-port rule for future service additions. The bullet originally read as init-time guidance only; appended a "Maintenance:" sentence so when a future agent adds a new service / new `ports:` entry to an existing `docker-compose.yml`, it applies the same rule. Anchors unchanged → structural grep_check still PASSes.

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete — ready for /task-close
- **Blocked:** none
- **Open discoveries:** 2 SURFACEd to backlog (RUN-ALL-UNBOUND-FORWARD-ARGS, VERIFY-SH-NO-HARD-CONTENT-ASSERT)

## Implementation notes

### T1 — grep_check pattern
Pin the bullet's distinctive anchor — "ephemeral range" plus the literal numeric `49152` — both in the same file. Patterns chosen so that **the file content has to keep the substantive guidance**, not just the heading. Add two grep_checks (small, deterministic):
```bash
grep_check "product-context SKILL.md retains 'Randomize host ports' bullet" "skills/product-context/SKILL.md" "Randomize host ports" 1
grep_check "product-context SKILL.md cites ephemeral-port range 49152" "skills/product-context/SKILL.md" "ephemeral range.*49152|49152.*ephemeral" 1
```
Placement: under `## Phase 3` (CLAUDE.md docs content section) is fine — these are documentation-content pins, same shape as the existing CHANGELOG convention pins at lines 95-99.

### T2 — P10b scenario shape
```yaml
- id: P10b
  name: "product:context Variant A output includes randomize-host-ports guidance"
  skill: product-context
  fixtures:
    claude_md: fixtures/CLAUDE.md
    product_dir: fixtures/product/wbs-done
  system_prompt_extra: |
    The architecture decision is Docker Mandate (Variant A). Generate the
    project's CLAUDE.md Dev Environment section using Variant A. Show the
    full Variant A content you would write, including all bullets and rules.
  expect:
    transition_id: P10
    contains_any:
      - "ephemeral"
      - "49152"
      - "randomize"
  max_retries: 2
```
Rationale for `contains_any` (not `transition_id` alone): we already have P10 asserting the transition. P10b's job is to assert the *content* gets emitted. Three keywords, OR-joined — robust to phrasing variation. `transition_id: P10` retained so the scenario also exercises the same transition (any of the contains_any matches counts as PASS via the verify.sh soft-pass-becomes-pass path when `transition_id` also matches).

### T3 — expected check-structure baseline
Pre-task: 124 PASS / 1 FAIL (settings-fixture drift, unrelated, expected). Post-T1: 126 PASS / 1 FAIL (added two grep_checks).

### T4 — full suite expectations
- Haiku pass: P10b should PASS (model reading the actual symlinked SKILL.md sees the bullet and naturally surfaces it given the Docker Mandate system_prompt_extra).
- If haiku SOFT_PASS (says "I would include randomize host ports" but doesn't drop one of the three keywords): widen `contains_any` (e.g., add "host port") OR escalate to sonnet per the test discipline.
- If haiku FAILs entirely (doesn't mention the randomize content): real signal — investigate whether the SKILL.md prose is clear enough for haiku to surface it. This itself is valuable feedback.

### T5 — bite-verification
After both nets PASS, run a "does it actually catch regressions" check by temporarily removing the "Randomize host ports" bullet from `skills/product-context/SKILL.md` (in a stash), running both `check-structure.sh` (must show 2 new FAILs) and the P10b scenario (must FAIL), then restoring. This protects against the failure mode where a test passes trivially because its anchor pattern is wrong.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
[SURFACED-2026-06-06] T4 — `tests/run-all.sh` has unbound-variable bug at line 42 (empty FORWARD_ARGS under set -u). Pre-existing, not introduced by this task. Working around T4 by invoking the two passes manually via `run-tests.sh`. Logged as SURFACE-2026-06-06-RUN-ALL-UNBOUND-FORWARD-ARGS in workflow/backlog.md.
[SURFACED-2026-06-06] T5 — `tests/lib/verify.sh::verify_result` short-circuits on `transition_id` match; `contains_any` only fires as SOFT_PASS fallback. No way to hard-assert content presence in current harness. Caused the P10b behavioral net to be unfalsifiable. Logged as SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT in workflow/backlog.md.

## Out of scope (deferred — addressed after this task closes)
- `SURFACE-2026-05-29-VERIFY-SELF-IN-PLACE-FIX-SHORTCUT-POLICY` — next candidate per session intent. Separate task plan after this closes.

## Retrospect
- **What changed in our understanding:** The harness's behavioral-scenario primitive (`tests/lib/verify.sh::verify_result`) cannot hard-assert content presence — `transition_id` match short-circuits to PASS regardless of `contains_any`. This is the structural reason "no scenario covers the docker-init feature's content" was a real gap, not a planning oversight on the prior feature's part. We also learned via bite-verification that the model's prior knowledge of "randomize ports" is strong enough to surface even very specific anchors (`lsof -nP -iTCP`, `random.randint(49152, 65535)`, `58329:5173`) from priors alone, so even if the harness *did* hard-assert content, a SKILL.md-prose-specific assertion would still be model-noise-prone. The defensible regression net for prose features in this harness is structural (`grep_check` in `check-structure.sh`), not behavioral.
- **Assumptions that held:** (a) Structural grep_check pins do bite — bite-verified at T5, 124→3-FAIL when bullet removed. (b) Adding scenarios + grep_checks is purely additive to existing harness primitives — no contract changes, no surprise downstream impacts. (c) Pre-existing FAILs in the suite (P2, S10, S12, S14, settings-fixture drift) were unaffected by this task's edits.
- **Assumptions that were wrong:** (a) That `contains_any` was a hard content gate — it's a SOFT_PASS fallback only. Caught at T5 bite-verification before commit; would have shipped a false-positive regression net if T5 had been skipped. (b) That strengthening the `contains_any` anchors would make P10b bite — even SKILL.md-verbatim literal strings (`lsof -nP -iTCP`) surface from model priors when the topic is primed. (c) That `tests/run-all.sh` would actually run — pre-existing unbound-variable bug under `set -u` blocked it; worked around with manual two-pass invocation.
- **Approach delta:** Plan had 5 steps (T1-T5) with one regression net per side (structural + behavioral). Actual outcome: structural net landed and bites; behavioral net was attempted twice (weak + strong anchors), both failed bite-verification, removed entirely. Added T6 mid-task per user request to extend the SKILL.md bullet's Maintenance scope to future service additions (not just init-time). Two harness limitations surfaced to backlog: `verify_result` short-circuit and `run-all.sh` unbound-variable bug. The bite-verification step (T5) saved the task from shipping confidence theater — it was the highest-value step in the plan despite being the smallest.
