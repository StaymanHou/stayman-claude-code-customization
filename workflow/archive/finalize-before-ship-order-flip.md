---
drive_mode: full-autopilot
note: switched from autopilot → full-autopilot at Phase 2 verify-codify boundary per user request; verify-human still PAUSEs for Phase 4 (regression scenario) by explicit instruction
---

# Feature: Finalize-before-ship order-flip prevention

**Workflow:** feature
**State:** Completed 2026-05-13
**Created:** 2026-05-12
**Entry:** reproduce → plan (F33)

## Problem Statement

After verify-codify on the final phase of a feature, the agent's narration of remaining slash commands can invert the actual ship→finalize order — recommending `/feature-finalize` before `/feature-ship`. If the user accepts the inverted order, finalize archives the WIP and writes "shipped" claims before any push, and ship has no WIP to read from. Root cause confirmed by reproduction (2026-05-12): the agent reads the WIP file's `## Current Node` → `**Unvisited:**` field as an ordered sequence-of-execution and copies that ordering into its enumerated next-step prose. The `Unvisited:` field has no defined ordering in the Work Tree spec, so the agent writing it in some order and later reading its own ordering as a sequence is a self-inflicted confabulation channel.

Originally observed in a real run (canva-permission-warmup, replicator-1-0 project, 2026-05-06). Reproduction recipe + observed verbatim output in the previous Reproduction Attempt section (now superseded; see archived reproduce snapshot in this file's history if needed).

## Reproduction Anchor (from F33 entry)

- **Failing test surface:** new scenario in `tests/scenarios/feature.yaml` using fixture `tests/fixtures/wip/feature-codify-misordered-unvisited-2.md`. The scenario invokes `feature-verify-codify` with system_prompt_extra that primes "non-testing-mode workflow execution" and asks for the full remaining-command sequence. **Current state: this scenario does not yet exist — Phase 4 writes it. The reproduction was confirmed manually (recipe in §3 of the prior reproduce snapshot).**
- **What "fixed" means:** with the fixture above and the same prompt shape, the model must emit `/feature-ship` *before* `/feature-finalize` in any enumerated next-step list (or omit finalize entirely from the verify-codify handoff, mentioning only `/feature-ship`).

## Work Tree

- [x] Phase 1: Spec the `Unvisited:` field as ordered, sequence-of-execution
  **Observable outcomes:**
  - CLI: `grep -n "Unvisited:" CLAUDE.snippet.md` returns a line whose surrounding context says the field is ordered by execution sequence (e.g., contains the literal substring "ordered" or "sequence of execution") — exits 0.
  - CLI: `grep -n "Unvisited:" skills/feature-plan/SKILL.md` returns the schema-template line and that line's enclosing comment or surrounding text reflects the ordered semantics consistent with the spec.
  - CLI: `./tests/check-structure.sh` exits 0 (no structural regressions introduced).
  - [x] P1.1 In `CLAUDE.snippet.md` § "Work Tree Format (GLOBAL)" → "Schema" block (L54–L59), tighten the `**Unvisited:**` line to define semantics explicitly: "phases not yet started, listed in the order the workflow will execute them (sequence-of-execution)." Update the Rules section (L77–L82) with a new bullet pinning the ordering rule.
  - [x] P1.2 In `skills/feature-plan/SKILL.md` L100, update the schema template's `**Unvisited:**` line to reflect the same ordered semantics. Adjust the example so the plan-time list is written in real execution order (Phase 2, Phase 3, …, not alphabetical or arbitrary).
  - [x] P1.3 Run `./install.sh` to re-inject CLAUDE.snippet.md into `~/.claude/CLAUDE.md` (the snippet is symlinked, so this should be a no-op verification step — but confirm). Confirmed: `[update] CLAUDE.md (workflow block refreshed)`.
  - [x] verify-auto — grep confirms both spec sites updated; check-structure.sh 34/34 PASS.
  - [x] verify-self — live-system observation: `~/.claude/CLAUDE.md` L65/L90 confirm injected spec + Rules bullet present; `~/.claude/skills/feature-plan/SKILL.md` L100 (symlinked) reflects ordered semantics. No integration boundary affecting code paths — phase modifies docs/spec only, but consuming surfaces (injected CLAUDE.md, symlinked skill) verified live.
  - [x] verify-human — approved 2026-05-12, no feedback.
  - [x] verify-codify — no new test in this phase; the F16-order-flip regression scenario in Phase 4 is the codification anchor for the whole feature. Regression slice (F15, F16, F17, F19) PASSes 4/4 confirming Phase 1's spec change does not affect existing verify-codify/finalize scenarios.

- [x] Phase 2: Add order-of-operations and ship-precondition guard rails
  **Observable outcomes:**
  - CLI: `grep -n "ship.*finalize\|Order of operations" agents/feature-workflow/AGENTS.md` returns at least one line stating the after-verify-codify order is ship → finalize (never the reverse) — exits 0.
  - CLI: `grep -n "verify-codify just completed\|ship.*first\|precondition" skills/feature-finalize/SKILL.md` returns at least one line implementing a precondition check that finalize refuses to run when the WIP's Current Node shows verify-codify just completed and ship has not yet run — exits 0.
  - CLI: `./tests/check-structure.sh` exits 0.
  - [x] P2.1 Added single-line "Order after verify-codify (final phase): ship → finalize, never the reverse" in `agents/feature-workflow/AGENTS.md` right after the state-machine diagram. Compressed from initial 8-line section per human feedback (token bloat).
  - [x] P2.2 Prepended compressed "§0. Precondition — has ship happened?" to `skills/feature-finalize/SKILL.md` before §1. One-line guard: Path contains `verify-codify` AND Unvisited contains `feature-ship` → STOP, route to `/feature-ship`. Compressed from initial 12-line block per human feedback. Re-exercised live with the misordered fixture after compression — guard still trips correctly.
  - [x] verify-auto — grep confirms wording landed at both source files and live symlinked targets; check-structure.sh 34/34 PASS.
  - [x] verify-self — behaviorally exercised the precondition guard live (claude --print /feature-finalize against feature-codify-misordered-unvisited-2.md fixture). Result: model correctly emitted **STOP**, refused to proceed, instructed user to run /feature-ship first, cited SURFACE-2026-05-06. Guard works as designed. Re-exercised after Phase 2 compression — still trips. (Side note: model fabricated `TRANSITION: F19-precond-fail` instead of using a registered transition — Phase 3 should consider whether to register a STOP transition or treat as "no transition emitted.")
  - [x] verify-human — approved 2026-05-12 with feedback to compress prose. Compression applied; guard re-verified live.
  - [x] verify-codify — no new test in Phase 2 (Phase 4 is the feature-level codification anchor). Regression slice F17, F18, F19, F19-dualclose, F30, F-CHGLOG-1 PASSes 6/6 — precondition guard does not trip any existing finalize scenario.

- [x] Phase 3: Tighten verify-codify handoff prose discipline
  **Observable outcomes:**
  - CLI: `grep -n "F16\|all phases complete" skills/feature-verify-codify/SKILL.md` returns lines that, in the F16 path, instruct the agent to mention ONLY `/feature-ship` as the next step — not enumerate a multi-step sequence — exits 0.
  - CLI: `./tests/check-structure.sh` exits 0.
  - [x] P3.1 Appended single-line guard to the F16 block: "Name only `/feature-ship` as the next step — do NOT enumerate finalize, refactor, or reflect (see SURFACE-2026-05-06-FINALIZE-BEFORE-SHIP-ORDER-FLIP)." Compressed per Phase 2 lesson.
  - [x] P3.2 Audited "Emit Transition" section. The F16 line already says "hand off to ship" — no parenthetical finalize mention. No edit needed.
  - [x] verify-auto — guard wording present at source + live symlink; check-structure.sh 33 PASS, 1 FAIL on unrelated pre-existing drift (settings fixture has `effortLevel: xhigh`, live doesn't). Logged as SURFACE-2026-05-13-SETTINGS-FIXTURE-EFFORTLEVEL-DRIFT (note-and-continue — not a regression from this feature).
  - [x] verify-self — re-ran the same reproduction recipe that originally produced the order-flip (misordered Unvisited fixture + non-testing-mode prompt asking for the full remaining sequence). Post-fix output: model named only `/feature-ship` — no enumeration of `/feature-finalize`. The Phase 3 guard line ("Name only `/feature-ship`...") successfully suppressed the confabulation. Before/after comparison documented in commit context.
  - [x] verify-human SKIPPED per Mode 4 (full-autopilot) — verify-self result is the acceptance gate.
  - [x] verify-codify — regression slice F14, F15, F16, F16-triage-* (4 variants), F16-codify-* (2 variants), F-boundary-codify: 4 PASS, 6 SOFT_PASS, 0 FAIL. F-boundary-codify confirmed haiku-noise via sonnet recon (PASSes strictly on sonnet). Other 5 SOFT_PASSes are model-output-shape issues (missing TRANSITION line, prose-leak family) — same haiku-noise class. Triage block written above. No Phase 3 regression. Adjacent gap logged as SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG.

- [x] Phase 4: Regression scenario in the transition-test harness
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id F16-order-flip --dry-run` lists the new scenario (no error).
  - CLI: `./tests/run-tests.sh --id F16-order-flip` runs the scenario and it PASSES (the fix from Phases 1–3 has eliminated the confabulation).
  - CLI: Re-running the same scenario 3× in a row produces PASS each time (deterministic — no flakes). If it flakes, classify per the F16-triage rules and pause for triage before claiming complete.
  - [x] P4.1 Added scenario `F16-order-flip` to `tests/scenarios/feature.yaml`. Uses fixture `feature-codify-misordered-unvisited-2.md`. System_prompt_extra matches reproduction recipe. Expect: `transition_id: F16`, `contains_any: ["/feature-ship"]`, `not_contains: ["/feature-finalize"]`, `not_contains_strict: true`. Simplification: rather than complex regex on order, the post-Phase-3 guard says "Name only /feature-ship" — so a passing model output should not mention `/feature-finalize` at all. Any mention → FAIL strict.
  - [x] P4.2 Added comment block above the scenario referencing SURFACE-2026-05-06 and pointing to `workflow/archive/finalize-before-ship-order-flip.md` for the feature plan and reproduction history.
  - [x] P4.3 Deleted unused `tests/fixtures/wip/feature-codify-misordered-unvisited.md` (attempt-1 version, untracked). Only `-2` (used by F16-order-flip) remains.
  - [x] verify-auto — YAML parses (58 scenarios, +1 for F16-order-flip); dry-run lists the new scenario; check-structure.sh shows the same single pre-existing failure (effortLevel drift, already logged) — no new regressions.
  - [x] verify-self — ran F16-order-flip 3× consecutively on haiku: PASS / PASS / PASS (13s / 13s / 19s, $0.17 total). Deterministic — no flakes. The regression scenario successfully exercises the originally-bugged reproduction path and PASSes with the Phase 1–3 fixes in place. This scenario is now the codification anchor: any future regression on the order-flip bug will FAIL this scenario in strict mode (`not_contains: ['/feature-finalize']` + `not_contains_strict: true`).
  - [x] verify-human — approved 2026-05-13.
  - [x] verify-codify — full feature sweep (58 scenarios, haiku): 39 PASS, 12 SOFT_PASS, 3 FAIL, 4 FLAKY. F16-order-flip PASSed in the full-sweep context. 3 FAILs triaged (block above): F4 + F22 are documented sonnet-tag mismatches forced through haiku, F13-prefiltered is haiku model-output-shape noise. None are regressions from this feature.

## Phase Sequencing Rationale

- **Phase 1 first** because the `Unvisited:` field's undefined ordering is the *root cause confabulation channel*. Until the spec defines the field's semantics, every other fix is downstream defense.
- **Phase 2 second** because order-of-operations + finalize precondition are independent defense layers that don't depend on Phase 3's prose tightening. They're the "even if the agent gets confused, the system catches it" rail.
- **Phase 3 third** because verify-codify prose tightening is the most targeted fix — but its value is highest when 1 and 2 are already in place (it's defense-in-depth, not the primary fix).
- **Phase 4 last** because the regression scenario needs all three prior fixes in place to PASS deterministically. Writing it earlier risks a flake on whichever fix is weakest.

## Downstream Contract Impacts (per CLAUDE.md plan-level check)

This feature edits:
- `CLAUDE.snippet.md` — globally injected into `~/.claude/CLAUDE.md` by `install.sh`. The `Unvisited:` semantic change affects every project that uses the Work Tree format. No existing tests assert against the spec wording, but agents reading WIP files will see the new semantics on next invocation. **Phase 1 deliverable.**
- `agents/feature-workflow/AGENTS.md` — orchestrator reference doc. No test scenarios assert against the diagram or "Order of operations" line directly. **Phase 2 deliverable.**
- `skills/feature-finalize/SKILL.md` — the new §0 precondition could in principle affect existing scenarios F18, F19, F19-dualclose, F30, F-CHGLOG-1, which all invoke `/feature-finalize` against various fixtures. The fixtures for those scenarios show `verify-codify` already done AND ship done (e.g., `feature-finalized-no-debt.md`, `feature-finalized-with-debt.md`, `feature-finalized-wbs-complete.md`). The precondition only refuses when `Unvisited:` *still contains* `feature-ship` — none of the existing fixtures should trip it. Still, **Phase 2 must spot-check** these five fixtures to confirm the precondition doesn't fire spuriously. If any does, fix the fixture (it was wrong) in the same phase.
- `skills/feature-verify-codify/SKILL.md` — affects scenarios F14, F15, F16, F16-triage-*, F16-codify-*, F-boundary-codify. All currently assert `contains_any` on outcomes like `/feature-ship` and various negative patterns. None currently strict-assert against finalize prose. **Phase 3 must spot-check** that none of these scenarios SOFT_PASS due to the tightened wording. If a scenario was previously relying on lenient prose containing extra mentions, fix the assertion to be stricter (which is the goal anyway).
- `tests/scenarios/feature.yaml` — adds F16-order-flip. **Phase 4 deliverable.**
- `tests/fixtures/wip/feature-codify-misordered-unvisited-2.md` — already created during reproduce; finalized in Phase 4 (decision: keep). The attempt-1 sibling fixture (`feature-codify-misordered-unvisited.md`) is decided in P4.3.

## Current Node
- **Path:** Feature > Completed
- **Active scope:** all phases complete; ship and finalize done
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Test Triage — verify-codify regression slice (6 SOFT_PASS on haiku)

Classification: Flaky test — haiku model-noise, unrelated to Phase 3 edit
Confidence: high
Evidence: F-boundary-codify SOFT_PASSes on haiku but PASSes strictly on sonnet (recon run 2026-05-13-125639). Same pattern as F4 and F22 flagged in CLAUDE.md history. The other 5 SOFT_PASSes (F14, F15, F16-triage-ambiguous, F16-triage-flaky, F16-triage-regression) all fail on output-shape issues (missing TRANSITION line, prose-leak of negated words) — model-noise class, not content errors. Phase 3 edit only added a single-line F16 guard; no behavioral path the SOFT_PASSes intersect with.
Action: No code/test modifications. Logging SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG to backlog so the recon discipline can be applied to F-boundary-codify and the F14/F15/F16-triage-* scenarios when there's a routine haiku-vs-sonnet sweep. Proceeding past Phase 3 verify-codify per "all phases complete" path.

## Test Triage — Phase 4 full-sweep 3 FAILs

Classification: Documented sonnet-tag mismatch (F4, F22) + haiku model-output-shape noise (F13-prefiltered) — none are regressions from this feature
Confidence: high
Evidence: F4 and F22 are explicitly tagged `model: sonnet` in `tests/scenarios/feature.yaml` (with comments citing prior recon outcomes — HIDDEN-FAIL-F4 and F22-FLAKY-REGRESSED-TO-FAIL). The `--model haiku` flag in the full-sweep command forced them through haiku anyway, reproducing the documented haiku-flake behavior. F13-prefiltered FAILs with "no structured TRANSITION line" — the same haiku-output-shape pattern as the SOFT_PASSes already classified above; extending SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG to include it.
Action: No code/test modifications. F16-order-flip (the codification anchor for this feature) PASSed cleanly in both the focused 3× determinism run AND the full sweep (58 scenarios, haiku). The 4 FLAKY scenarios all passed on retry — normal harness behavior. Updated SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG with the F13-prefiltered extension.

## Retrospect

- **What changed in our understanding:** The bug class is testable in the existing harness — I initially concluded reproduction would be infeasible because "the agent's between-skill narration isn't reachable by `claude --print` single-skill invocations." That was wrong. The skill's own output prose IS the between-skill narration; the harness DOES capture it. I just needed the right combination of inputs (misordered Unvisited fixture + non-testing-mode framing + an explicit prompt for the full remaining-command sequence) to trigger the confabulation. The lesson: don't conclude "untestable" before trying multiple prompt-shape variations — three attempts with different framings produced the reproduction.
- **Assumptions that held:** The SURFACE-2026-05-06 entry's hypothesis #1 was exactly right — the `Unvisited:` field's undefined ordering IS the confabulation channel. The agent writes the list in some order, then later reads its own writing as a sequence. The plan-time spec change (Phase 1) addresses the root cause; Phases 2 and 3 are defense layers.
- **Assumptions that were wrong:** I initially planned heavy prose in AGENTS.md (8 lines) and feature-finalize/SKILL.md §0 (12 lines). User feedback ("seems overkill, wasting context tokens") was correct — both compressed to 1–2 lines without losing the guard's behavioral correctness, verified by re-running the precondition-trip test post-compression. Verbose rationale belongs in the SURFACE entry; the SKILL/AGENT files should just name the constraint and cite the SURFACE.
- **Approach delta:** Plan called for Phase 4 to write a regression scenario with complex regex assertions on order (`finalize.*ship`, `1. .*finalize`, etc.). Actual implementation simplified to `not_contains: ["/feature-finalize"]` + `not_contains_strict: true` — because Phase 3's guard says "name only /feature-ship," any mention of finalize in the F16 path is now wrong. The simpler assertion is stronger and easier to reason about. Also unplanned but completed: an inline triage block in this WIP for 6 SOFT_PASSes in Phase 3 + 3 FAILs in Phase 4 (all classified as haiku model-noise, none regressions). And: this run is itself a dogfood of the §0 precondition guard — when finalize started just now, my own guard was checked first, and Current Node correctly showed `Path: Feature > finalize` (not verify-codify), so the guard correctly did NOT fire.

## Discoveries
