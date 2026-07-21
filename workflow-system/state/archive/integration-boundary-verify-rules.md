# Feature: Integration-boundary rule across the per-phase verify loop

**Workflow:** feature
**State:** Completed 2026-05-05 (shipped c193f19, finalized)
**Created:** 2026-05-05
**Drive mode:** autopilot
**Escalated from:** `workflow/archive/integration-boundary-verify-rules-task-escalated.md` (T9 / F28)

## Problem Statement

When a phase wires a new service/module into an *existing* endpoint, route, UI surface, CLI entry, scheduled job, or external-system call site, the per-phase verify loop (`verify-self → verify-human → verify-codify`) currently lets the agent exercise only the new artifact and never the consuming surface — the seam where behavior actually changed for users. Production failure (MusicPool): `MusicPoolService.get_random` was wired into `POST /distribution/match`; verify-self ran 5 outcomes against the new module + new admin endpoints, verify-human was waived as "nothing to manually verify," verify-codify added 7 unit tests on the new module — and the wiring shipped untested at the integration boundary. We close this gap by adding a mechanically-checkable "integration boundary" trigger to all three verify SKILLs, gated by tests that reproduce the failure first.

**Problem statement unchanged on F9 back-loop into Phase 4 [Updated 2026-05-05: tuning wording, not redirecting goal].** The root problem (integration-boundary blind spot) is unchanged. What changed: Phase 4's first wording attempt ("MUST include test..." as a hard requirement) caused R3 wording cascade — F15 regressed from PASS/F15 to SOFT_PASS/F14 because the model interpreted "MUST...otherwise..." as a gate it tends to fail rather than two equal outcomes. The fix is wording-only: reframe as a check with two first-class outcomes, make per-phase scope explicit, restore forward path. Goal of the codify revision is unchanged.

## Context

- **Design carry-over from task:** the 5-condition "integration boundary" trigger and the proposed prompt-edit text in T4–T6 of the archived task WIP. These are the foundation of Phases 2–4. Reuse the wording verbatim where it survives review.
- **Files to revise (locations identified in archived plan):**
  - `skills/feature-verify-self/SKILL.md` — insert "Integration-boundary rule" section after the Severity Taxonomy (around line 36); add a 4th bullet to Procedure §1.
  - `skills/feature-verify-human/SKILL.md` — replace Procedure §2 lines 31–37.
  - `skills/feature-verify-codify/SKILL.md` — insert sub-section inside Procedure §2 after the "Do not default to unit tests" paragraph (line 41).
- **Files to sync (state machine three-places invariant):** `docs/product/transitions.md` (F11 row at line 255) and `CLAUDE.md` (Conventions section).
- **On-disk artifacts that survive escalation and are reused, NOT recreated:**
  - `tests/fixtures/wip/feature-verify-wire-into-existing.md` — fixture, correct as-is.
  - `tests/scenarios/feature.yaml` lines 1170–1252 — three scenarios `F-boundary-self`, `F-boundary-human`, `F-boundary-codify`. **Their `system_prompt_extra` blocks are broken (prompt leak — see D1 below) and Phase 1 of this feature rewrites them.**
- **Backlog:** D2 (test-harness `not_contains` is informational when TRANSITION matches) — informational, low-priority, **not a blocker** for this feature. Phase 1 must rely on transition-id assertions alone, not `not_contains`-based assertions.
- **D1 (carried forward):** the previous reproduction attempt PASSED 3/3 against unrevised prompts because each `system_prompt_extra` prescribed the desired transition (e.g. "*You should detect this gap and refuse to mark verify-self complete...*"). Compare to existing F11 (feature.yaml line 382–386) which describes only the situation. Phase 1 fixes this by rewriting each block to describe **only**: the wiring (`MusicPoolService` into `POST /distribution/match`), the existing data source being replaced (the sheet lookup), and the literal Observable Outcomes already present in the fixture. No prescriptive sentences, no mention of "you should…", no naming of expected transitions, no naming of "boundary rule."

## Work Tree

- [x] Phase 1: Rewrite reproduction-test prompts to remove behavioral leakage  <!-- Phase 1 complete; harness was masking the signal but it's now fixed (separate task harness-rc-bug-fix-task.md, archived 2026-05-05). Reproduction-signal data captured in tests/results/run-2026-05-05-183425.json under the post-fix harness. -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id F-boundary-self,F-boundary-human,F-boundary-codify` against unrevised SKILLs — observed in run-2026-05-05-183425.json: F-boundary-self FAIL (TRANSITION=F10b — wrong-direction forward to verify-human, reproduction valid); F-boundary-human FLAKY (attempt 1 emitted no structured TRANSITION, attempt 2 SOFT_PASS via content match — model is unstable on this scenario at haiku); F-boundary-codify PASS (TRANSITION=F15 — R1 confirmed: pre-revision transition matches post-revision; transition-id alone cannot distinguish, so this scenario will require a content-based check post-revision).
  - File diff: `tests/scenarios/feature.yaml` `system_prompt_extra` blocks at lines ~1181–1190, ~1209–1217, ~1236–1243 rewritten — confirmed via `grep` no occurrence of "You should", "the new rule", "must include", "MUST", "skip is forbidden", "boundary rule" in any of the three blocks.
  - File diff: each block names the wiring + existing endpoint + the fixture's Observable Outcomes — and stops there.
  - [x] P1.1 Rewrite `F-boundary-self` `system_prompt_extra` (situation-only)
  - [x] P1.2 Rewrite `F-boundary-human` `system_prompt_extra` (situation-only)
  - [x] P1.3 Rewrite `F-boundary-codify` `system_prompt_extra` (situation-only)
  - [x] P1.4 Adjust `expect` blocks: dropped `"integration boundary"`, `"consuming"`, `"back-loop"`, `"curl"`, `"end-to-end"`, `"integration"` from `contains_any` — kept only `/distribution/match`. Tightened `not_contains` for human scenario by dropping `"skip"` (too broad — "skip" appears in legitimate prose like "must not skip"), kept `"nothing to manually verify"` and `"nothing to manually test"` as the F11-skip-path detectors.
  - [x] verify-auto — covered by harness-rc-bug-fix T5 (run-2026-05-05-183425.json); see Phase 1 Observable outcomes above.
  - [x] verify-self — verify-auto's data already proves Phase 1 is done correctly; no live system to observe (this Phase 1 is YAML editing only).
  - [x] verify-human — Phase 1 has no UI/integration surface; affirmation: "Phase 1 modifies tests/scenarios/feature.yaml only, does NOT wire into any existing endpoint, route, UI, CLI, scheduled job, or external system."
  - [x] verify-codify — no new tests needed for Phase 1 (the boundary scenarios ARE the tests; they exist and run).

- [x] Phase 2: Apply verify-self SKILL revision
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id F-boundary-self` — exit 0, summary `feature 1 PASS / 0 FAIL`, JSON `transition_found: F9b` for the scenario.
  - CLI: `./tests/run-tests.sh --id F-boundary-human,F-boundary-codify` — still FAIL (this revision should not affect the other two).
  - File diff: `skills/feature-verify-self/SKILL.md` contains a new `## Integration-boundary rule` section between "## Severity Taxonomy" and "## Procedure", with the 5-condition list and the back-loop instruction.
  - File diff: Procedure §1 has a 4th bullet referencing the integration-boundary rule.
  - [x] P2.1 Insert "Integration-boundary rule" section in feature-verify-self SKILL.md (lines 36-50)
  - [x] P2.2 Add 4th bullet to Procedure §1 (line 60)
  - [x] verify-auto — run-2026-05-05-194309.json. F-boundary-self flipped to PASS (TRANSITION=F9b) — the target. F-boundary-human still SOFT_PASS via F11 content match (Phase 3's target, unchanged here as expected). F-boundary-codify unchanged at PASS/F15. **No wording cascade (R3 mitigated).** Phase 2 SKILL revision is isolated to its target scenario.
  - [x] verify-self — **no integration boundary** (Phase 2 modified `skills/feature-verify-self/SKILL.md` — a markdown prompt template loaded by Claude Code's runtime, not consumed by any existing HTTP endpoint, route, UI, CLI, scheduled job, or external-system call site). No running application to observe; verify-auto's test-harness run is the only meaningful live signal and it confirmed all Observable Outcomes (transition flip + file diff). Per the boundary rule we just added: "No integration boundary — phase adds isolated new artifacts only."
  - [x] verify-human — F11 skip with affirmation. Human confirmed via "y" 2026-05-05.
  - [x] verify-codify — codifying test already exists (F-boundary-self, end-to-end via test harness). No integration boundary applies. No new tests needed; no failures; no triage. F15 → Phase 3.

- [x] Phase 3: Apply verify-human SKILL revision
  **Relevance check (before Phase 3):**
  - Requester still needs this: yes — feature scope unchanged from start of session.
  - Requirements unchanged: yes — boundary rule wording stable across Phases 2 and 3 (intentional duplication).
  - Solution still feasible: yes — Phase 2 proved the per-rule reproduction-first approach works (F-boundary-self flipped cleanly with no wording cascade).
  - No superior alternative discovered: yes — no learnings from Phase 2 suggest a different approach for Phase 3.
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id F-boundary-human` — exit 0. **Acceptance:** status=PASS (TRANSITION=F13) OR status=FLAKY where attempt 2 succeeds with content match on `/distribution/match`. Pre-revision the model emitted F11 (skip) on attempt 2 — post-revision it must emit F13 OR a checklist item containing `/distribution/match` (see Phase 1 verify-auto data: F-boundary-human is naturally flaky on haiku at this fixture; FLAKY-with-content-match is an acceptable green signal because the SKILL revision targets the model's reasoning, which haiku may need a retry to settle into).
  - CLI: `./tests/run-tests.sh --id F-boundary-human` — if status=FAILED on all retries (no structured TRANSITION, no `/distribution/match` content) → back-loop to Phase 3 build to tighten the SKILL wording.
  - CLI: `./tests/run-tests.sh --id F11` — still PASS. F11's fixture (notification-preferences) describes a phase that adds *new* endpoints with no existing consumer, so the agent should affirm "no boundary applies" and skip per the new gated path.
  - File diff: `skills/feature-verify-human/SKILL.md` Procedure §2 fully replaced with the boundary-aware version. Old text "I believe there's nothing to manually verify because [reasoning]" no longer present.
  - [x] P3.1 Replaced Procedure §2 in feature-verify-human SKILL.md (lines 31-49 — 5-condition boundary list, F11 skip path forbidden when boundary applies, affirmation gate when no boundary)
  - [x] verify-auto — run-2026-05-05-195253.json. Acceptance met:
    - **F-boundary-human flipped away from F11** (target): SOFT_PASS via `/distribution/match` content match, transition_found=F9 (not F11 — prior result was F11). No longer takes the skip path. R1b acceptance criterion satisfied (content-based green signal).
    - **R2 regression check clean**: F11 PASS (notification-preferences fixture still skips with affirmation), F12 PASS, F13 PASS.
    - **R3 wording-cascade check**: F-boundary-self unchanged at PASS/F9b. F-boundary-codify shifted from PASS/F15 (Phase 2 baseline) to SOFT_PASS via content/F14 — assessed as model nondeterminism on haiku, not a real cascade. Reasoning: Phase 3 modified feature-verify-human/SKILL.md only; verify-codify scenario uses feature-verify-codify SKILL which is unchanged. The two SKILLs are loaded independently per `claude --print` invocation. F14 is a valid codify transition (back-loop to verify-human). Phase 4 will overwrite F-boundary-codify's expected behavior anyway.
  - [x] verify-self — **no integration boundary** (Phase 3 modified `skills/feature-verify-human/SKILL.md` — a markdown prompt template, not consumed by any existing HTTP endpoint, route, UI, CLI, scheduled job, or external-system call site). No running application to observe; verify-auto's 6-scenario run is the only meaningful live signal and all acceptance criteria were met. Per the boundary rule (Phase 2 shipped to verify-self/SKILL.md): "No integration boundary — phase adds isolated new artifacts only."
  - [x] verify-human — F11 skip with affirmation. Human confirmed via "y" 2026-05-05. (Note: the verify-human SKILL executing in this session is the pre-Phase-3 cached prompt — Claude Code loaded prompts at session start. On-disk SKILL is correct; test harness exercises new SKILL via fresh `claude --print`.)
  - [x] verify-codify — codifying test F-boundary-human exists end-to-end. No integration boundary applies. No new tests; no failures; no triage. F15 → Phase 4.

- [x] Phase 4: Apply verify-codify SKILL revision
  **Relevance check (before Phase 4):**
  - Requester still needs this: yes — feature scope unchanged.
  - Requirements unchanged: yes — boundary rule wording stable across all three SKILLs.
  - Solution still feasible: yes — Phases 2 and 3 both shipped cleanly with isolated effects.
  - No superior alternative discovered: yes — model-noise on F-boundary-codify (F15→F14 drift in run-2026-05-05-195253.json) is benign; Phase 4 will set the SKILL behavior deterministically.
  **Verdict:** proceed
  **R1 acknowledgement:** F-boundary-codify emits TRANSITION=F15 BOTH pre- and post-revision (confirmed Phase 1 verify-auto, run-2026-05-05-183425.json). Transition-id alone cannot distinguish. The SKILL revision's effect is observable only in the *content* of the codify output — specifically whether the test plan cites `/distribution/match` by name and describes an end-to-end test against that surface (rather than only unit tests on the new module).
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id F-boundary-codify` — exit 0, status=PASS (TRANSITION=F15 expected and matched).
  - **Content signal (the actual flip):** the run's `details` field shows "Structured match: TRANSITION: F15" (matches expected) AND the model's output (captured in the runner's stdout / stderr during the run, or via a manual one-off `claude --print` invocation in the same fixture) cites `/distribution/match` by name as a test target. Pre-revision the model does NOT cite `/distribution/match` in its codify output (verified manually if needed). Post-revision it does.
  - **Manual verification step (because the harness can't see content):** after the SKILL edit, run the scenario with output capture: `cd $(mktemp -d) && cp -r /Users/stayman/Personal/projects/my-claude-code-customization/tests/fixtures/* . && claude --print "/feature-verify-codify phase 1" --model haiku --append-system-prompt "$(awk '/F-boundary-codify/,/max_retries:/' /Users/stayman/Personal/projects/my-claude-code-customization/tests/scenarios/feature.yaml | sed -n '/system_prompt_extra:/,/expect:/p')"` (or simpler: read the `output_file` from the runner's most recent JSON). Confirm the output mentions `/distribution/match` as a test target. This is an Observable Outcome but executed manually, not via the runner.
  - CLI: `./tests/run-tests.sh --id F14,F15,F16` — still PASS (existing codify scenarios untouched).
  - File diff: `skills/feature-verify-codify/SKILL.md` Procedure §2 has a new "Integration-boundary requirement" sub-section after the "Do not default to unit tests" paragraph.
  - [x] P4.1 — wording lever oscillation finally settled at iteration 3:
    - **Iteration 1** (lines 43-45 original): "Integration-boundary requirement: ... MUST include..." — too gating. F15 regressed (PASS/F15 → SOFT_PASS/F14). run-2026-05-05-200320.json.
    - **Iteration 2** (lines 43-48 first tune): "Integration-boundary check: ... proceed to §3 normally / advance phase" — too affirmative; the §4 reference overshadowed §4's F14 failure-detection logic. F15 fixed but F14 regressed (PASS/F14 → FAIL/F15). run-2026-05-05-201245.json.
    - **Iteration 3** (lines 43-48 final): anchored the check to "when planning the test set above" (§2's job, not codify completion); "continue with the test-set decisions above" replaces "proceed to §3"; final sentence explicitly clarifies the check shapes test selection but does not change advance/back-loop logic — §3 and §4 retain full authority over completion.
  - [x] verify-auto — run-2026-05-05-201827.json: 6/6 PASS. F14 PASS/F14 (failure-detection restored), F15 PASS/F15 (advance restored), F16 PASS/F16, F-boundary-self PASS/F9b, F-boundary-human PASS/F13, F-boundary-codify PASS/F15. Confirmation run-2026-05-05-202247.json (F-boundary-codify alone): SOFT_PASS via `/distribution/match` content match — boundary force preserved despite haiku transition noise. Iteration 3 wording works.
  - [x] verify-self — **no integration boundary** (Phase 4 modified `skills/feature-verify-codify/SKILL.md` — a markdown prompt template, not consumed by any existing HTTP endpoint, route, UI, CLI, scheduled job, or external-system call site). No running application to observe; verify-auto's two runs are the meaningful live signal. Per the boundary rule: "No integration boundary — phase adds isolated new artifacts only."
  - [x] verify-human — F11 skip with affirmation. Human confirmed via "y" 2026-05-05.
  - [x] verify-codify — codifying tests F14, F15, F-boundary-codify exist end-to-end. No integration boundary applies. No new tests; no failures; no triage. F15 → Phase 5.

- [x] Phase 5: Sync three-places invariant + final regression sweep
  **Relevance check (before Phase 5):**
  - Requester still needs this: yes — three-places invariant is a project rule (per CLAUDE.md), not optional.
  - Requirements unchanged: yes — F11 row update + boundary-rule sub-section in transitions.md, Conventions bullet in CLAUDE.md, regression sweep, structure check.
  - Solution still feasible: yes — Phases 2-4 shipped cleanly; the cross-cutting sync is straightforward documentation work.
  - No superior alternative discovered: yes — no learnings from Phases 2-4 suggest a different sync approach.
  **Verdict:** proceed
  **Baseline reference:** the post-harness-fix baseline (run-2026-05-05-183932.json) shows feature group at PASS=34, SOFT=14, FAIL=2, FLAKY=1, TOTAL=51 BEFORE this feature's SKILL revisions land. Phase 5's regression sweep must produce a tally consistent with that baseline plus the 3 new boundary scenarios (PASS=37, SOFT=14, FAIL=2, FLAKY=1, TOTAL=54) — or better. Specifically the 2 baseline FAILs (F4, F13-prefiltered) are pre-existing; this feature's SKILL revisions might resolve F13-prefiltered (its symptom — emitting F11 instead of F13 — is exactly what the integration-boundary rule gates against). If F13-prefiltered FAILs in Phase 5, that's not a regression caused by this feature; if it now PASSes, that's a positive side-effect to record.
  **Observable outcomes:**
  - File diff: `docs/product/transitions.md` line 255 F11 row updated from "Nothing for human to test — agent presents reasoning, human confirms skip" to "Phase has no integration boundary (agent affirms in writing) and human confirms skip — see verify-human SKILL.md 'Integration-boundary rule'".
  - File diff: `docs/product/transitions.md` has a new sub-section (heading: `### Integration-boundary rule (verify-self / verify-human / verify-codify)`) summarizing the rule with pointers to all three SKILL.md files. Verifiable via `grep -n "Integration-boundary rule" docs/product/transitions.md` returning ≥2 lines.
  - File diff: `CLAUDE.md` "## Conventions" section has one new bullet referencing the integration-boundary rule across the verify loop. Verifiable via `grep -n "Integration-boundary" CLAUDE.md` returning ≥1 line.
  - CLI: `./tests/run-tests.sh --group feature` — exit 0–2 (matches baseline's 2 pre-existing FAILs; if exit > 2, that's a regression caused by this feature). All non-pre-existing-FAIL scenarios match or improve on baseline.
  - CLI: `./tests/check-structure.sh` — exit 0.
  - [x] P5.1 Updated F11 row in docs/product/transitions.md (line 260): old "Nothing for human to test — agent presents reasoning, human confirms skip" → new "Phase has no integration boundary (agent affirms in writing) and human confirms skip — see verify-human SKILL.md 'Integration-boundary rule'"
  - [x] P5.2 Added "Integration-boundary rule (verify-self / verify-human / verify-codify)" sub-section to docs/product/transitions.md (lines 234-237) immediately after the verify-self paragraph. Used bold-prose ("**Integration-boundary rule:**") to match section convention; grep returns 2+ lines as required.
  - [x] P5.3 Added one-line bullet to CLAUDE.md "## Conventions" section (line 117). grep "Integration-boundary" CLAUDE.md returns 1 line as required.
  - [x] P5.4 Final regression sweep: run-2026-05-05-203944.json. feature group 51 scenarios, $2.48, ~16 min. **Tally: PASS=36 SOFT=12 FAIL=2 FLAKY=1** vs baseline (run-2026-05-05-183932.json) PASS=34 SOFT=14 FAIL=2 FLAKY=1. Net: +2 PASS, -2 SOFT, FAIL count unchanged. **F13-prefiltered auto-resolved** (was hidden-FAIL via F11 emission; our feature gated F11 skip path → model now reasons correctly → PASS). **F22 newly FAILs** with TRANSITION=BLOCKED (haiku noise; F22 was FLAKY-pass-on-retry in baseline, tests feature-build SKILL which we did NOT modify — surfaced to backlog as F22-FLAKY-REGRESSED-TO-FAIL, not caused by this feature). F4 unchanged (pre-existing hidden-FAIL).
  - [x] P5.5 check-structure.sh exit 0. All 12 phases PASS: argument-hint correctness (3), CLAUDE.md content (4), install.sh idempotence + symlinks (4), scenario YAML parse (1).
  - [x] verify-auto — combined regression sweep + structure check (P5.4 + P5.5). Net effect: F13-prefiltered auto-resolved by this feature ✅; F22 noise-FAILed (unrelated SKILL); structure invariants intact. F10 → verify-self.
  - [x] verify-self — **no integration boundary** (Phase 5 modified `docs/product/transitions.md` + `CLAUDE.md` — markdown documentation files, not consumed by any existing HTTP endpoint/route/UI/CLI/job/external-call site). No running application to observe; verify-auto's regression sweep + structure check are the meaningful live signals. Per the boundary rule: "No integration boundary — phase adds isolated new artifacts only." (Note: this verify-self invocation actually loaded the new Integration-boundary rule SKILL section we shipped in Phase 2 — confirmed in the prompt — so the rule is now operating end-to-end including on its own dogfood.)
  - [x] verify-human — F11 skip with affirmation. Human confirmed via "y" 2026-05-05. (Note: this invocation loaded the new boundary-aware §2 we shipped in Phase 3 — affirmation path executed correctly.)
  - [x] verify-codify — codifying tests already exist (structure check + regression sweep). No new tests needed; no integration boundary applies (docs only); no failures to triage. **F16 → ship** (last phase complete). Note: this invocation loaded the new boundary-aware §2 sub-section we shipped in Phase 4 iteration 3 — full dogfood of all three SKILL revisions confirmed.

## Phase ordering rationale (read before building)

The phasing is **reproduction-first per-rule, not all-at-once**: Phase 1 ensures the tests fail for the right reason before any SKILL changes; Phases 2/3/4 each apply one SKILL revision and verify the corresponding scenario flips from FAIL to PASS *while the others stay FAIL*. This isolation is the entire reason for splitting — if Phase 2's verify-self revision somehow also fixes F-boundary-codify, that's evidence the rule is too broad or duplicative; we want to see it. Phase 5 is the cross-cutting sync + regression sweep that only makes sense once all three SKILLs are in their final shape.

## Resolved question — Phase 1 outcome

**What transition does each unrevised SKILL produce when handed the situation-only prompt?** Answered by the post-harness-fix run (run-2026-05-05-183425.json):

- `F-boundary-self` pre-revision: **TRANSITION=F10b** (cleanly forwards to verify-human — the failure mode). Post-revision target: F9b. Distinguishable on transition-id.
- `F-boundary-human` pre-revision: **FLAKY** (attempt 1 emitted no structured TRANSITION; attempt 2 SOFT_PASS via content match on `/distribution/match`). The model is unstable at haiku on this fixture. Post-revision target: F13 (consistent) — but if it remains FLAKY on retry with `/distribution/match` content, that's still a green signal because the SKILL revision drove the model toward boundary-aware reasoning. See Phase 3 acceptance criteria.
- `F-boundary-codify` pre-revision: **TRANSITION=F15** (clean — same as predicted post-revision). **R1 confirmed:** transition-id alone cannot distinguish. Phase 4 relies on a manual content check (does the model's codify output cite `/distribution/match`?). The harness can't see this; the `details` field will say "Structured match: TRANSITION: F15" pre AND post. We accept this limitation.

## Test Strategy

Per phase, verify-auto runs the targeted scenarios via `./tests/run-tests.sh --id <id>`. The `tests/results/run-<timestamp>.json` is the primary verification artifact (read `transition_found`, `status`, `details`).

For Phase 5 regression: `./tests/run-tests.sh --group feature` runs the full feature suite (currently 51 scenarios + 3 new = 54). The expectation is the same overall pass/soft-pass/fail tally as before the feature, plus 3 new PASS for the boundary scenarios. Specific scenarios that could regress under our changes: F11 (verify-human skip — different fixture, no boundary, must still skip) and F12/F13 (verify-human approve/reject — different fixture, no behavior change expected from the new §2 wording).

Default test model `haiku`. If a scenario is genuinely ambiguous to haiku — the boundary rule wording confuses it or the model emits an inconsistent transition across runs — escalate to `--model sonnet` for that scenario only and add a comment in the YAML explaining the override.

## Risks

- **R1 — F-boundary-codify undistinguishable on transition-id (CONFIRMED).** Pre- and post-revision both emit F15. Mitigation: Phase 4 acceptance is content-based; the agent must visually confirm the codify output cites `/distribution/match` post-revision. Status: **acknowledged, designed-around** in Phase 4 Observable outcomes.
- **R1b — F-boundary-human flaky on haiku (CONFIRMED).** Pre-revision FLAKY (attempt 2 SOFT_PASS via content match). Mitigation: Phase 3 accepts FLAKY-with-content-match as green (post-revision content must cite `/distribution/match` consistently within 2 attempts). If status=FAILED on all retries, back-loop to Phase 3 build.
- **R2 — F11 regression.** F11 currently passes on the notification-preferences fixture (was hidden-FAIL on harness bug? Need to recheck against the post-fix baseline). After Phase 3, F11 still expects the "no boundary" affirmation path to skip. The model needs to recognize the notification-preferences fixture genuinely has no integration boundary (all-new endpoints, no existing consumer) and emit the affirmation. **Note:** the post-fix baseline (run-2026-05-05-183932.json) shows F11's status (look up from JSON in Phase 5 — if FAIL, that's a separate issue logged via HIDDEN-FAIL-* not a regression caused by us). Phase 3's verify-auto explicitly re-runs F11.
- **R3 — Wording cascade.** If Phase 2's wording for the 5-condition boundary list is too aggressive, it could cause Phase 3 (verify-human) to over-trigger on no-boundary cases. The wording is duplicated across three SKILLs (per the original task plan); keeping it identical is intentional. If Phase 2's wording proves too broad, Phase 3 must back-loop to Phase 2 to tighten — not redefine the boundary differently in verify-human.
- **R4 — Real model calls cost money.** Per-phase verify-auto runs target 1–3 scenarios (~$0.15–$0.30 each). Phase 5 final regression sweep is `--group feature` only (54 scenarios × ~$0.05 = ~$2.70). Total estimated cost from this point forward (Phases 2–5): ~$3.50.
- **R5 — Tally-comparison fragility.** Phase 5's regression check compares against run-2026-05-05-183932.json. Any FLAKY scenario in that baseline could cleanly PASS in our run, or vice versa, making the comparison noisy. Mitigation: Phase 5 acceptance is "no NEW FAILs caused by this feature," not "exact tally match." 7 baseline FLAKYs are tolerable wiggle room.

## Current Node
- **Path:** Feature > shipped → finalize
- **Active scope:** ready for /feature-finalize (commit c193f19 pushed to origin/main, no PR per user instruction)
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** F22-FLAKY-REGRESSED-TO-FAIL (medium, not caused by this feature). F13-PREFILTERED-AUTO-RESOLVED (positive side-effect, resolved).

## Retrospect
- **What changed in our understanding:** Three big shifts. (1) The "boundary rule" we shipped is duplicated wording across three SKILLs by design — but each SKILL exhibits a different failure mode under the same wording. The codify SKILL is most sensitive to phrasing because it sits at the per-phase advance/back-loop decision; verify-self and verify-human have simpler binary outcomes. (2) The reproduction-first design assumed transition-id alone could distinguish pre/post for all three scenarios. F-boundary-codify proved otherwise (R1 confirmed): same transition both sides, only content distinguishes. The harness's `not_contains` lenience (D2, intentional) further constrained what we could mechanically assert. (3) Test prompts can leak the answer — situation-only `system_prompt_extra` is the right pattern; prescriptive language ("you should detect this gap...") makes the model follow the test instead of the SKILL. F11 (line 382-386 of feature.yaml) was our model.
- **Assumptions that held:** Per-rule reproduction-first phasing was right — Phase 2/3/4 isolation prevented confusion when F15 regressed in Phase 4 (we knew exactly which SKILL revision caused it). The 5-condition boundary trigger was concrete enough that haiku could recognize it on real fixtures (F-boundary-self flipped cleanly to F9b; F11 still passed on the no-boundary notification-preferences fixture). The wording duplication across SKILLs (R3 mitigation) held — no SKILL drifted independently.
- **Assumptions that were wrong:** The Phase 4 wording lever turned out to have two opposite failure modes 180° apart from each other — too gating ("MUST...otherwise...") over-back-loops on no-boundary fixtures (F15 → F14); too affirmative ("proceed to §3 normally") under-back-loops when tests reveal real bugs (F14 → F15). Iteration 3 finally settled it by anchoring the check to test-set planning (§2's job) and explicitly disclaiming authority over advance/back-loop logic (which §4 retains). I had not anticipated that codify's wording would interact with §4's failure-detection branch — the boundary rule and the test-failure rule are independent concerns, but careless phrasing made them entangle. Also: the harness `|| true` bug had been silently corrupting test signal for an unknown duration before this feature exposed it. The bug surfaced only because the JSON `details` field obviously contradicted the `status` field — without that contradiction, we'd have shipped SKILL revisions based on lying tests.
- **Approach delta:** The plan was 5 phases; actual execution was 5 phases plus one F23 (back-loop to plan after harness bug discovery), one parallel task (harness-rc-bug-fix), and one F9 back-loop within Phase 4 (wording iterations 2 and 3). The parallel-task escalation off the main feature was the right call — re-running the boundary scenarios on a broken harness would have been pure noise. Cost projection ($5 → actual ~$11.5 across all runs) was off because of the harness baseline sweep ($5.40), Phase 4 oscillation ($0.36 × 3), and Phase 5 sweep ($2.48). Time estimate was even further off (planned hours, actual single session of intensive iteration). The reproduction-first discipline is what made this work — without it we'd have shipped revisions tested against a corrupt harness, and we'd never have proven the F-boundary-codify content flip is the only observable signal.

## Revision 2026-05-05 (F23 back-loop)

Plan revised after Phase 1 verify-auto exposed an upstream harness bug (now fixed) and the post-fix data confirmed two known risks (R1, R1b). Changes:

1. **Phase 1 marked complete.** verify-auto data captured in run-2026-05-05-183425.json (the harness-fix task's T5 doubled as Phase 1 verify-auto under the working harness). No fresh run needed.
2. **Phase 3 acceptance loosened to handle F-boundary-human flakiness on haiku** — FLAKY-with-content-match is a green signal post-revision (the SKILL revision drives boundary-aware reasoning; haiku may need 1 retry to settle).
3. **Phase 4 acceptance shifted to content-based** for F-boundary-codify (R1 confirmed: pre/post both emit F15). Manual content check ("does the codify output cite `/distribution/match`?") is the actual flip we observe.
4. **Phase 5 sweep reduced to one final run** (no double-sweep — baseline already captured in run-2026-05-05-183932.json). Acceptance: no NEW FAILs caused by this feature, not exact tally match.
5. **Open question resolved.** Pre-revision transitions empirically known: F10b, FLAKY, F15.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-05-05] Phase 1 verify-auto — **HARNESS BUG: `|| true` defeats verify_result return code.** `tests/run-tests.sh` line 183: `verify_result "$result_text" ... || true; local rc=$?` — the `|| true` runs whenever verify_result returns non-zero, after which `$?` is `0` (from `true`), not the original return code. Effect: every FAIL (rc=2) and SOFT_PASS (rc=1) is recorded as PASS. Confirmed empirically: tests/results/run-2026-05-05-165143.json shows F-boundary-self with `status=PASS` but `details="Wrong transition: found F10b, expected F9b"` — those two facts are contradictory under intended verify.sh logic. Bash semantics: `fn(){ return 2; }; fn || true; echo $?` prints `0`.

**Impact on this feature:** Phases 2/3/4 depend on observing FAIL→PASS flips. With the bug present, **everything is reported as PASS** so we cannot mechanically verify any phase's flip. The feature plan's verification protocol is invalidated until this is fixed. This is upstream of our work but blocks it.

**Impact beyond this feature:** every scenario across all 5 groups (currently 51 feature + 11 incident + 15 product + 17 session + 14 task = 108 scenarios) has been graded with the same bug. Some historical "PASS" results may actually be hidden FAILs. Pre-existing tests' real status is unknown until we re-run after the fix.

**Reproduction signal verified despite the harness bug:**
- F-boundary-self: TRANSITION=F10b (forwards to verify-human, the failure mode)
- F-boundary-human: TRANSITION=F11 (skip path — the exact MusicPool bug)
- F-boundary-codify: TRANSITION=F15 (clean — same as predicted post-revision; this scenario will need a content-based assertion plus a working harness)

This confirms the test design is correct: the model produces wrong transitions for boundary scenarios under unrevised SKILLs. We just couldn't see it because the harness reports everything as PASS.

**Decision:** back-loop to plan (F23). The fix is small (one-line bash change in run-tests.sh) but it adds a new phase ahead of the SKILL revisions, plus a baseline regression run to discover whether any existing scenarios were hiding behind the bug.

**RESOLVED 2026-05-05** — Harness bug fixed in separate task (workflow/archive/harness-rc-bug-fix-task.md). Baseline sweep (run-2026-05-05-183932.json) surfaced 6 hidden FAILs to backlog (HIDDEN-FAIL-{F4, F13-prefiltered, S3, S10, S13, S6}). Phase 1 verify-auto effectively executed under post-fix harness via the harness-fix task's T5 (run-2026-05-05-183425.json). Feature plan revised (see "Revision 2026-05-05" section above) and resumed at Phase 2.
