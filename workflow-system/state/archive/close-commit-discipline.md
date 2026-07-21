---
workflow: feature
state: ship (complete)
created: 2026-06-12
drive_mode: autopilot
ship_commit: d1c0bb9
phase1_commit: 40ef434
---

# Feature: Close-commit discipline — amend learnings to HEAD + codify no-auto-push

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-12

## Problem Statement

`SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH` (backlog P1) keeps re-surfacing despite being "acknowledged — no action." The friction is real: between a close skill running (`feature-finalize`, `task-close`, `incident-resolve`, `product-finalize`) and the next session, uncommitted learning files drafted by `session-store-learning` are exactly the kind of cross-feature-pause loose state that gets destroyed by `git checkout HEAD --`, stash-replay errors, or scaffolder overwrites. Two paired fixes close the failure mode mechanically: (1) `session-store-learning` amends project-scope learnings into HEAD (the close commit, in the typical post-reflect cadence) so they live in the same commit as the work they describe — no separate uncommitted artifact to lose; (2) all four terminal-close skills codify the existing (already-correct) no-auto-push behavior as a load-bearing contract so future drift can't reintroduce a destructive push. Phase 1 implementation (5 SKILL.md edits) is **already in the working tree, uncommitted** — escalated mid-verify from the task workflow because the `docs-only: true` auto-skip was wrong (SKILL.md prose IS a runtime surface). This feature scope is therefore predominantly verification: commit the drafted edits, add behavioral scenarios, add structural pins.

## Context

- **Escalated-from artifact:** `workflow/archive/close-commit-discipline-amend-and-no-auto-push.md` — original task WIP, contains full per-file edit summary and rationale. The 5 SKILL.md edits remain in the working tree (uncommitted, unchanged since task-act).
- **Drafted Phase 1 edits already on disk** (verified at plan time via `git status`):
  - `skills/session-store-learning/SKILL.md` — §5 project-scope path: `git add` + `git commit --amend --no-edit`; global-scope path: explicit no-amend (gitignored)
  - `skills/feature-finalize/SKILL.md` — §3c step 6: "Do NOT `git push`" clause
  - `skills/task-close/SKILL.md` — §6 step 6: same no-push clause
  - `skills/incident-resolve/SKILL.md` — §4b step 5: same no-push clause
  - `skills/product-finalize/SKILL.md` — §6b: same no-push clause inline
- **Test harness facts (relevant to verification phases):**
  - `tests/scenarios/*.yaml` group files cover each close skill (3 task-close scenarios, 5 feature-finalize scenarios, 4 incident-resolve scenarios, 3 product-finalize scenarios, 1 session-store-learning scenario)
  - `contains_any` is soft-assert only per `SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT` (P2) — a matching `transition_id` short-circuits content check. Scenarios will still surface the new prose when the model invokes the skill afresh (the prose flows out naturally as part of step descriptions), but a FAILing `contains_any` won't fail the scenario if the transition matches. **Lean on structural pins (Phase 3) for the hard contract; behavioral scenarios (Phase 2) are confirmatory signal that the model surfaces the new instructions in practice.**
  - `tests/check-structure.sh` has a `grep_check` primitive at line 32 that asserts ≥N matches of a regex in a file. This is the hard-assert path for prose contracts.
- **No `docs/product/wbs.md` active** — between cycles (last finalized: Workflow System v2, per CLAUDE.md "Current Phase" block).
- **No 3rd-party probe needed** — all surfaces are local (git, bash, test harness).
- **Empirical baseline (already established, do not re-discover):** none of the four close skills currently emit a `git push` instruction. Phase 1 Change-2 is codification of existing behavior as a load-bearing contract, not a behavior reversal.

## Work Tree

- [x] Phase 1: Commit the drafted SKILL.md edits  <!-- done: commit 40ef434 (5 SKILL.md files, 14 insertions); 4/4 verify-self PASS; verify-human AUTO-SKIPPED (autopilot, no integration boundary); verify-codify deferred to P2+P3 with SURFACE for pre-existing test scaffolding issue -->
  **Observable outcomes:**
  - CLI: `git log --oneline -1` shows a single commit titled with the feature name, touching exactly 5 files: `skills/{session-store-learning,feature-finalize,task-close,incident-resolve,product-finalize}/SKILL.md`. Exit 0.
  - CLI: `git status --porcelain skills/` returns empty (no remaining uncommitted edits to skills/).
  - CLI: `grep -c "Do NOT \`git push\`" skills/feature-finalize/SKILL.md skills/task-close/SKILL.md skills/incident-resolve/SKILL.md skills/product-finalize/SKILL.md` returns ≥1 for each (all four close skills have the no-push clause landed).
  - CLI: `grep -c "git commit --amend --no-edit" skills/session-store-learning/SKILL.md` returns ≥1 (amend clause landed).
  - [x] P1.1 Stage the 5 SKILL.md files via `git add`  <!-- done -->
  - [x] P1.2 Commit with a descriptive title referencing the SURFACE ID being resolved  <!-- done: commit 40ef434 -->
  - [x] verify-auto  <!-- done: 5/5 YAML frontmatter valid; 5/5 symlinks resolve; 5/5 SKILL.md have ## Procedure + context section -->
  - [x] verify-self  <!-- done: 4/4 outcomes PASS via subagent (commit 40ef434 lands 5 expected files; clean skills/ tree; no-push clause ≥1 in each of 4 close skills; amend clause ≥1 in session-store-learning) -->
  - [x] verify-human  <!-- AUTO-SKIPPED: drive_mode=autopilot, no integration boundary (P1 deliverable is git-state; runtime SKILL.md consumption is verified in Phase 2 + Phase 3), verify-self all-PASS, no outcome cites consuming surface -->
  - [x] verify-codify  <!-- done: check-structure.sh baseline 226 PASS / 2 FAIL (FAILs pre-existing per HEAD~1 reproduce; SURFACED-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX); Phase 1's behavior (commit state + file content) is codified by Phase 2 behavioral scenarios + Phase 3 grep_check pins, not duplicated here -->

- [x] Phase 2: Add behavioral test scenarios for the new prose  <!-- done: 5 new scenarios added (F19/T10/I10/P13-no-auto-push + S20-amend-head); all 5 PASS strict end-to-end through harness (95s, $0.35); check-structure.sh baseline unchanged -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id F19-no-auto-push,T11-no-auto-push,I10-no-auto-push,P13-no-auto-push,S20-amend-head --dry-run` lists 5 new scenarios (the dry-run primitive enumerates without running).
  - CLI: `./tests/run-tests.sh --id F19-no-auto-push,T11-no-auto-push,I10-no-auto-push,P13-no-auto-push,S20-amend-head` runs all 5 to completion. PASS or SOFT_PASS acceptable per the harness limitation; FAIL on transition-id is a real bug. (Scenarios run on haiku by default unless one fails repeatedly and gets sonnet-tagged per recon discipline.)
  - CLI: each scenario's `expect.contains_any:` references at least one literal-prose anchor from the new clauses (e.g. `"Do NOT"`, `"--amend"`, `"operator's call"`) — sanity that the test was authored correctly even if the harness can't hard-fail on it.
  - [x] P2.1 Add scenario `F19-no-auto-push` to `tests/scenarios/feature.yaml`: invoke `feature-finalize` on `fixtures/wip/feature-finalized-no-debt.md`, assert `transition_id: F19` + `contains_any: ["Do NOT", "operator", "push"]` (soft).  <!-- done: appended; feature.yaml 70 scenarios (was 69) -->
  - [x] P2.2 Add scenario `T10-no-auto-push` to `tests/scenarios/task.yaml`: invoke `task-close` on `fixtures/wip/task-act-complete.md`, assert `transition_id_any: [T10, T11]` + `contains_any` for no-push prose.  <!-- done: appended; task.yaml 18 scenarios (was 17) -->
  - [x] P2.3 Add scenario `I10-no-auto-push` to `tests/scenarios/incident.yaml`: invoke `incident-resolve` on `fixtures/wip/incident-mitigated.md`, assert `transition_id: I10` + `contains_any` for no-push prose.  <!-- done: appended; incident.yaml 22 scenarios (was 21) -->
  - [x] P2.4 Add scenario `P13-no-auto-push` to `tests/scenarios/product.yaml`: invoke `product-finalize` on `fixtures/product/wbs-complete`, assert `transition_id: P13` + `contains_any` for no-push prose.  <!-- done: appended; product.yaml 17 scenarios (was 16) -->
  - [x] P2.5 Add scenario `S20-amend-head` to `tests/scenarios/session.yaml`: invoke `session-store-learning` on a project-scope-shaped args input, assert `transition_id: S20` + `contains_any: ["--amend", "git add", "HEAD"]` for the amend clause.  <!-- done: appended; session.yaml 25 scenarios (was 24) -->
  - [x] verify-auto  <!-- done: 5/5 YAML parse OK (total 152 scenarios); 5/5 scenario IDs present at expected file paths; 5/5 have all required keys (id, name, skill, fixtures, expect, max_retries); 5/5 reference correct skill. Note: `run-tests.sh --dry-run` invocation hung at ~2min (per-scenario Python YAML re-parse across 152 scenarios — known harness slow-path, unrelated to our 5 additions); killed. -->
  - [x] verify-self  <!-- done: 3/3 outcomes PASS via subagent: (1) S20-amend-head runs end-to-end in 5s with harness PASS — model emitted TRANSITION: S20, structured match authoritative; (2) all 5 new scenarios carry literal-prose anchors in contains_any; (3) all 5 wire to correct skill. -->
  - [x] verify-human  <!-- done: operator requested full 5-scenario harness run; all 5 PASS strict (haiku, 95s, $0.35): F19-no-auto-push PASS, T10-no-auto-push PASS, I10-no-auto-push PASS, P13-no-auto-push PASS, S20-amend-head PASS. 5/5/5/5/5/5 PASS SOFT FAIL FLAKY breakdown clean. -->
  - [x] verify-codify  <!-- done: the 5 new scenarios ARE the codification — they are the regression guard for the SKILL.md prose changes. check-structure.sh post-Phase 2 baseline: 226 PASS / 2 FAIL (identical to Phase 1; same 2 pre-existing markdown-bold regex-test FAILs already SURFACED). No regression from Phase 2 additions. -->

- [x] Phase 3: Add structural pins to check-structure.sh  <!-- done: 6 new pins under new [Phase 11] block in check-structure.sh; baseline 226 PASS → 232 PASS; bite-verify confirmed mutation→FAIL→restore→baseline-restored; operator-approved at verify-human -->
  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` runs end-to-end, exit 0. Total PASS count increases by exactly 5 (4 no-push pins + 1 amend pin); FAIL count unchanged from prior baseline.
  - CLI: `grep -n 'Do NOT \`git push\`' tests/check-structure.sh` returns ≥4 lines (one grep_check per close skill).
  - CLI: `grep -n 'git commit --amend --no-edit' tests/check-structure.sh` returns ≥1 line (amend pin for session-store-learning).
  - CLI: temporarily mutate `skills/feature-finalize/SKILL.md` to remove the no-push clause and re-run `./tests/check-structure.sh` — must FAIL with a clear error citing the missing clause. Restore the file before commit. (This is the "test the test" bite-verify discipline.)
  - [x] P3.1 Identify the right Phase block in `check-structure.sh` to add the new pins — chose new Phase 11 block at end of file (before Summary), since existing Phases 3/3b/3c/9 are dedicated to other categories (CLAUDE.md content, debug-* skills, orchestrator cheat-sheets).  <!-- done -->
  - [x] P3.2 Add 4 `grep_check` calls — one per close skill SKILL.md asserting `Do NOT.*git push` matches ≥1 time. (Regex .* between matches the literal backtick in `Do NOT \`git push\``, tolerant of formatting drift.)  <!-- done -->
  - [x] P3.3 Add 2 `grep_check` calls for `session-store-learning/SKILL.md`: one for `git commit --amend --no-edit`, one for `git add <file-path` (the staging step that precedes the amend).  <!-- done -->
  - [x] P3.4 Bite-verify the pins fire on mutation: `sed -i '' '/Do NOT.*git push/d' skills/feature-finalize/SKILL.md` → check-structure.sh FAILs with `[FAIL] feature-finalize forbids git push from close commit — found 0 lines matching 'Do NOT.*git push' in skills/feature-finalize/SKILL.md (need ≥1)`. Restore → baseline 232 PASS / 2 FAIL restored.  <!-- done -->
  - [x] verify-auto  <!-- done: 3/3 scoped checks PASS: bash -n syntax OK; [Phase 11] block at line 1612; all 6 grep_check calls present at lines 1614-1619 -->
  - [x] verify-self  <!-- done: 4/4 outcomes PASS via subagent. (1) check-structure.sh 232 PASS / 2 FAIL — exact +6 delta (226→232); (2) grep -c 'Do NOT.*git push' = 4 (≥4 required); (3) grep -c 'git commit --amend --no-edit' = 1 (≥1 required); (4) bite-verify-the-bite-verify: mutated feature-finalize SKILL.md to remove no-push clause → [FAIL] pin fired with clear error + PASS dropped to 231 / FAIL rose to 3 → restored from backup → PASS 232 / FAIL 2 baseline restored. Subagent also noted a prompt-injection attempt (MCP instructions embedded in tool output) and correctly disregarded it. -->
  - [x] verify-human  <!-- done: operator approved the captured check-structure.sh end-to-end response (6 new PASS lines under [Phase 11], 2 baseline FAILs are pre-existing markdown-bold regex issues per SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX, bite-verify mutation correctly produced FAIL and restoration brought baseline back). -->
  - [x] verify-codify  <!-- done: the 6 new grep_check pins ARE the codification — they are the regression guard for the SKILL.md prose. check-structure.sh post-verify-human: 232 PASS / 2 FAIL (same baseline). No additional tests needed (would be infinite regress — meta-tests-about-the-pins). -->

## Current Node
- **Path:** Feature > review-quality (complete) > finalize
- **Active scope:** Ship + review-quality both complete; 5 MINOR findings auto-backlogged per drive_mode=autopilot; ready for /feature-finalize
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** 5 new MINOR SURFACE entries (SURFACE-2026-06-12-QUALITY-*) + SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX (all logged to backlog; none block this feature)

## Retrospect

- **What changed in our understanding:** Two non-obvious things surfaced mid-feature. (1) The original task framing's `docs-only: true` declaration was wrong — SKILL.md prose IS a runtime surface (the harness consumes it at skill invocation time, which is functionally indistinguishable from code consumption). This was caught at verify-self after the original task already passed verify-codify on the auto-skip path. It's a reusable lesson: *any artifact the harness loads at runtime is not docs-only, even if the artifact is markdown prose.* (2) None of the four close skills currently emit `git push` — the Change-2 work was codification of existing behavior as a load-bearing contract, not behavior reversal. The empirical baseline (`grep` showed no push instructions) reframed the work from "fix a bug" to "prevent future drift."
- **Assumptions that held:** (a) Phase 1's 5 SKILL.md edits could ride from the escalated task into the feature unchanged — they did, no edits were revised in the feature scope. (b) The structural-pin layer (Phase 3 grep_check) would be the hard-assert path while behavioral scenarios (Phase 2) would be soft signal — confirmed; the bite-verify-the-bite-verify test in Phase 3 produced a clear actionable error message when mutated. (c) The amend-to-HEAD mechanism would close the original SURFACE failure mode mechanically without needing the originally-proposed angles (a) port-rule-to-global-CLAUDE.md or (b) re-surfacing-dampener — confirmed at finalize-time backlog review.
- **Assumptions that were wrong:** (a) The original task scoping. A 5-SKILL.md-file edit across 4 terminal-close skills + 1 meta skill is workflow-system contract scope, not atomic-task scope. The escalation mid-verify was the correction. (b) `./tests/run-tests.sh --dry-run` would be a fast pre-flight check (~seconds). It actually takes 2+ minutes due to per-scenario Python YAML re-parsing across 152 scenarios — known harness slow-path. Worked around by running a single scenario end-to-end at verify-self (5s) and the full 5-scenario sweep at verify-human (95s, $0.35).
- **Approach delta:** (a) Plan said Phase 3 would add 5 pins (4 no-push + 1 amend); impl added 6 (4 no-push + 2 amend — including the `git add <file-path` staging step that precedes the amend). Plan undercounted by 1; impl was correct. (b) The `docs-only: true` misclassification on the original task forced the escalation, which is the structural correction. (c) The CLAUDE.md `## Conventions` bullet added at finalize-time codifies the close-commit-discipline contract for future readers — not in the original plan, but standard finalize-time documentation hygiene per recent close skills.

## Code-Quality Review — close-commit-discipline

### Strengths
- Bite-verify discipline applied at Phase 3 (mutate the SKILL.md, confirm the new pin fires with a clear actionable error, restore) — exactly the "test the test" practice CLAUDE.md asks for; the WIP records the FAIL message verbatim.
- The amend rationale in `skills/session-store-learning/SKILL.md` is exemplary: it names the failure mode being closed, names the SURFACE ID, AND documents the off-path case (non-close HEAD) and reversibility — future readers will understand WHY without spelunking through backlog history.
- Symmetric structural-pin coverage: every prose contract added in Phase 1 has a corresponding `grep_check` in Phase 11. No "documented but unenforced" gaps.
- Behavioral scenarios honor the established harness limitation (soft `contains_any` per SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT) by hard-asserting transition_id and softly anchoring on literal prose — the WIP explicitly calls this division of labor out.
- Global-scope opt-out is documented explicitly with rationale (`.claude/learnings/` is gitignored, `git add` would no-op) rather than silently skipping — prevents a future maintainer from "fixing" the asymmetry.

### Issues
**CRITICAL**
- (none)

**MAJOR**
- (none)

**MINOR**
- [skills/feature-finalize/SKILL.md:91, skills/task-close/SKILL.md:83, skills/incident-resolve/SKILL.md:67, skills/product-finalize/SKILL.md:106] The four "Do NOT `git push`" paragraphs are nearly identical word-for-word (varying only by "close"/"resolve"/"cycle-close"). If the contract ever evolves — e.g., add an opt-in flag or expand the rationale — all four sites must be updated in lockstep. The repo already solved an analogous duplication problem by extracting the CHANGELOG convention into `CLAUDE.snippet.md`; the four-skill no-push clause is a candidate for the same treatment, though four sites is borderline for the snippet pattern.
- [skills/product-finalize/SKILL.md:106] The product-finalize no-push paragraph is formatted as a standalone bolded paragraph between two unrelated paragraphs, while the other three close skills place the clause as a numbered list item (step 5 or step 6) inside the operational-sequence list. The asymmetry is cosmetic but visually breaks the "four close skills carry the same contract" mental model — a reader scanning all four for the contract will notice the product-finalize one looks different. Minor stylistic inconsistency.
- [tests/check-structure.sh:1614-1617] The grep pattern `Do NOT.*git push` is loose enough to match arbitrary intervening text. A tighter literal like `Do NOT \`git push\`` (with the backticks) would document intent more clearly and reject hypothetical inverted constructions. Low-risk in the current prose body but worth tightening when the pin is touched next.
- [tests/scenarios/session.yaml:773-774] `contains_any` lists both `"--amend"` and `"git commit --amend"` — the latter contains the former so the second entry is redundant matching-wise (any string containing `git commit --amend` also contains `--amend`). Trim one for cleanliness.
- [tests/scenarios/feature.yaml:1858-1862, task.yaml:387-389, incident.yaml:507-509, product.yaml:364-366] The four `*-no-auto-push` scenarios share the same `contains_any: ["Do NOT", "do not push", "operator", "land locally"]` shape with mostly-identical `system_prompt_extra` framing. A single trailing comment block (or scenario-naming convention note) explaining "these four share the no-push prose contract; keep `contains_any` in sync" would help future maintainers spot the family at a glance.

### Assessment
This is a tight, well-built feature: two paired prose changes, five behavioral scenarios, six structural pins, all symmetric and all bite-verified. The amend-into-HEAD mechanism is the load-bearing change and is documented at the right granularity — rationale, off-path case, and reversibility all present without ceremony. The "Do NOT git push" codification of existing behavior as a contract is the right move and the four pins make accidental drift impossible. Future readers will find the WIP retrospect, the SKILL.md prose, and the structural pins all reinforcing the same story, which is the ideal shape for a small ship like this. The only meaningful improvement opportunity is the four-way prose duplication, which is genuinely borderline — extracting into a snippet would add an indirection in exchange for single-source maintenance, and either choice is defensible at this scope. Net: advances the codebase, no debt accrued.

### If you disagree
Operator: dismiss any finding by editing this section in the WIP file and marking the line `[DISMISSED]` before `feature-finalize` archives the WIP. The finding will be skipped by the orchestrator's severity-tier action matrix.

## Test Triage — Phase 3d regex property test (2026-06-12)

Classification: Obsolete test
Confidence: high
Evidence: `tests/check-structure.sh:320` extracts only the sed regex from `tests/lib/verify.sh:51` but ignores the `tr -d '*'` pipeline prefix that handles markdown-bold tolerance. The 2 failing cases (`**TRANSITION:** F1` and `**TRANSITION:** DEBUG-BISECT-SKIP`) PASS through the production pipeline; they only FAIL in the property test's pipeline-less invocation. Same 2 FAILs reproduce at HEAD~1 (verified) — pre-existing, NOT introduced by close-commit-discipline Phase 1.
Action: No action in this feature (Phase 1 commit is not the cause; modifying the unrelated test file would extend scope). SURFACED to `workflow/backlog.md` as `SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX` (task-scoped, 1-line fix). Phase 1 codify proceeds on the basis that all SKILL.md edits committed correctly (4/4 verify-self PASS) and the 2 pre-existing FAILs are baseline noise.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
[SURFACED-2026-06-12] Phase 1 verify-codify — SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX. Pre-existing 2 FAILs in `check-structure.sh` Phase 3d regex property test (markdown-bold cases) — test scaffolding ignores production pipeline's `tr -d '*'` prefix. Confirmed pre-existing at HEAD~1. Logged to backlog as low-pri task-scoped 1-line fix.
