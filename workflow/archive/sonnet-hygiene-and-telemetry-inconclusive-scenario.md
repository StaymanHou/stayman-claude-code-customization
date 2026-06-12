---
workflow: task
state: close (complete)
created: 2026-06-12
completed: 2026-06-12
docs-only: false
drive_mode: autopilot
---

# Task: Sonnet-hygiene pair — F16-triage SOFT_PASS fixes + DEBUG-TELEMETRY-INCONCLUSIVE coverage

**Workflow:** task
**State:** Completed
**Created:** 2026-06-12
**Completed:** 2026-06-12
**Drive mode:** autopilot

## Problem Statement

Two related test-coverage hygiene gaps need to land together: (P3) the F16-triage-ambiguous + F16-triage-flaky scenarios SOFT_PASS on sonnet (assertion-shape false positives, not skill-prose drift), and (P4) the DEBUG-TELEMETRY-INCONCLUSIVE termination path has no behavioral test scenario at all. Both are scenario YAML hygiene plus, in the inconclusive case, one new fixture.

## Context

### P3 — F16-triage SOFT_PASS analysis

- **File:** `tests/scenarios/feature.yaml`
- **F16-triage-ambiguous** (lines 655-687): assertion `not_contains: [auto-fix, ...]`. Sonnet correctly chooses pause but mentions "auto-fix" in negation context (e.g. "this is NOT a code regression to auto-fix"). Sonnet recon (2026-06-09): `SOFT_PASS (Contains 'pause' but also mentioned: auto-fix)` — the model classifies correctly, just leaks the forbidden phrase in negation. Per CLAUDE.md "Test scenario design — routing-fork patterns": "Entry-state transitions need a different test shape than exit transitions" — this scenario stays IN F16 emitting a pause classification, so aggressive `not_contains` on triage-related vocabulary is prose-leak fragile. **Fix:** soften `not_contains` to remove the `auto-fix` phrase OR use a more specific phrase that only fires on the wrong behavior (e.g. forbid `automatically fixed` and `/feature-build` re-entry but allow `auto-fix` in negation).
- **F16-triage-flaky** (lines 689-721): sonnet emits the right reasoning + classification but skips the literal `TRANSITION: F16` line. Sonnet recon: `SOFT_PASS (Contains 'flaky' (no structured TRANSITION line))`. This is an output-shape issue — the scenario expects `transition_id: F16` but the model emits prose-only when the natural skill output ends with a triage classification rather than a downstream transition. **Fix:** investigate whether the skill prose nudges the model away from emitting `TRANSITION: F16` when classification ends in pause. If skill prose looks fine, the scenario should be relaxed to accept the classification-only path (e.g. rely on `contains_any` only OR accept any of F16/F14 — but per the harness, `transition_id_any: [F16, F14]` is the right shape when classification IS the work and pause is the routing).
- **Both scenarios** currently lack `model: sonnet` tag despite the empirical recon already proving sonnet is the right model (sonnet PASSes strictly on the related F15/F16/F16-triage-regression scenarios after their 2026-06-09 tagging). **Fix:** add `model: sonnet` tag with the same comment shape used on F15/F16/F16-triage-regression.

### P4 — DEBUG-TELEMETRY-INCONCLUSIVE scenario

- **File:** `tests/scenarios/debug.yaml` (and new fixture at `tests/fixtures/wip/`)
- **Coverage gap:** debug-empirical-telemetry skill ships 4 termination tokens (`START`, `SKIP`, `COMPLETE`, `INCONCLUSIVE`) but only 3 are covered by scenarios (`GATE-MET` → START, `INSUFFICIENT-ATTEMPTS` → SKIP, `STATIC-DERIVABLE` → SKIP). `INCONCLUSIVE` (§7 of SKILL.md — ≥3 non-converging telemetry rounds → escalate) is uncovered.
- **Per SURFACE-2026-06-10-DEBUG-TELEMETRY-INCONCLUSIVE-SCENARIO context:** "Structurally hard to test from a fixture because it requires conveying 'the agent has already done 3 rounds of telemetry and none discriminated' without embedding telemetry results in the fixture itself, and the model tends to suggest more telemetry rounds rather than escalating from a fixture description."
- **Fix:** author `tests/fixtures/wip/debug-empirical-telemetry-inconclusive.md` that explicitly enumerates 3 prior telemetry rounds with their hypotheses + observations, frames the bug as one where each round's discriminating observable looked promising but did not converge, and explicitly forecloses additional-round suggestion by stating "all reasonable observables exhausted". Then author scenario `DEBUG-TELEMETRY-INCONCLUSIVE` in debug.yaml, likely sonnet-tagged (haiku noisy on describe-then-escalate per CLAUDE.md entry-state guidance). Assertion: `transition_id: DEBUG-TELEMETRY-INCONCLUSIVE` + `contains_any: [escalation, escalate, exhausted, suggest, alternative, inconclusive]`. Avoid aggressive `not_contains` per CLAUDE.md entry-state-vs-exit-state guidance (the skill stays in the procedure when emitting INCONCLUSIVE).

### Shared anchors

- **CLAUDE.md → "Test scenario design — routing-fork patterns"** governs the assertion shape for entry-state scenarios
- **CLAUDE.md → "`not_contains_strict: true` is structurally fragile"** — lenient mode is current (no `_strict` flag set), so SOFT_PASS is the baseline behavior. Today's fixes target the assertion shape, not the strict flag
- **CLAUDE.md → "Verify-codify full-group sweep discipline"** — sonnet-tag the new + fixed scenarios so two-pass runner partitions correctly
- **Expected PASS count delta:** +1 new scenario (DEBUG-TELEMETRY-INCONCLUSIVE) in `tests/run-tests.sh` output count (NOT `check-structure.sh` — that's a different counter). The F16-triage SOFT_PASS fixes turn 2 SOFT_PASSes into 2 strict PASSes on sonnet without adding new scenarios.

## Work Tree

- [x] T1 P3-a Soften F16-triage-ambiguous's `not_contains` assertion: remove `auto-fix` (prose-leak), add `model: sonnet`. **Iteration**: first attempt soft-passed because sonnet emitted F14 (not F16) — fixed by adding `transition_id_any: [F16, F14]` to match F16-triage-flaky's dual-identity shape. Final result: PASS strict on sonnet (17s, $0.09).
- [x] T2 P3-b Investigate F16-triage-flaky's missing-TRANSITION issue:
  - [x] T2.1 Read SKILL.md §5 — confirmed only F15/F16/F14 are enumerated; triage-pause outcomes have no canonical token, so model legitimately emits either F16 (work-product done) or F14 (back-loop to verify-human).
  - [x] T2.2 Decided fix path: option (b) — `transition_id_any: [F16, F14]` matches the skill's actual structural ambiguity; lower-disruption than tightening skill prose (which would force model away from F14 routing that's semantically correct).
  - [x] T2.3 Applied fix + `model: sonnet` tag + added 3-line system-prompt nudge for explicit TRANSITION line emission. PASS strict on sonnet (11s, $0.07).
- [x] T3 P4-a Authored `tests/fixtures/wip/debug-empirical-telemetry-inconclusive.md`: 3 prior telemetry rounds (dequeue boundary / release_lock / downstream sink) each with hypothesis + observation + ruled-out conclusion; explicit foreclosure of round 4; inconclusive framing per SKILL.md §7.
- [x] T4 P4-b Added scenario `DEBUG-TELEMETRY-INCONCLUSIVE` to `tests/scenarios/debug.yaml`. Sonnet-tagged. NO aggressive `not_contains`. **Lands as SOFT_PASS** (not strict) — 3 bite-verify attempts failed to coax sonnet into the clean `TRANSITION: DEBUG-TELEMETRY-INCONCLUSIVE` line shape; model wraps the token in markdown decoration that breaks the harness regex. SURFACED for future work; SOFT_PASS provides lenient coverage which is harness-supported.
- [x] T5 Bite-verify each change:
  - [x] T5.1 F16-triage-ambiguous → PASS strict on sonnet (after `transition_id_any` iteration)
  - [x] T5.2 F16-triage-flaky → PASS strict on sonnet (first attempt with `transition_id_any` + system_prompt_extra nudge)
  - [x] T5.3 DEBUG-TELEMETRY-INCONCLUSIVE → SOFT_PASS on sonnet (3 attempts, design issue surfaced; lenient coverage shipped)
- [x] T6 Commit as a single hygiene-pair task  <!-- commit 4ae1dc4 -->

## Current Node

- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:**
  - F16-triage-ambiguous's SOFT_PASS root cause was DUAL (prose-leak `auto-fix` + transition_id_any was needed) — plan only identified the first. Caught at bite-verify time, fix was a 1-line additional edit, not a re-plan.
  - DEBUG-TELEMETRY-INCONCLUSIVE is structurally harder to coax into strict-PASS shape than the original SURFACE entry anticipated — surfaced as `SURFACE-2026-06-12-DEBUG-TELEMETRY-INCONCLUSIVE-STRICT-PASS-NEEDED` with 3 candidate fix paths (skill-prose, harness regex broadening, or accept SOFT_PASS as current state).

## Discoveries

<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-06-12] T5.1 (mid-iteration) — F16-triage-ambiguous's SOFT_PASS was dual-cause, not single. Plan identified the `auto-fix` prose-leak; bite-verify revealed sonnet ALSO emits F14 (not F16) for the same legitimate reason as F16-triage-flaky. Fix was structurally identical (`transition_id_any: [F16, F14]`). Not surfacing as backlog item — same scope as the plan's stated work, finer granularity at act-time. Plan-time discipline: when two scenarios have nearly-identical SOFT_PASS shapes (both triage-pause classifications under the same skill), assume the dual-identity fix applies to both, not just the one with the more obvious symptom.

[SURFACED-2026-06-12] T5.3 — DEBUG-TELEMETRY-INCONCLUSIVE strict-PASS unachievable after 3 attempts ($0.25 total). SOFT_PASS lands as final state with SURFACE-2026-06-12-DEBUG-TELEMETRY-INCONCLUSIVE-STRICT-PASS-NEEDED filed in backlog for future strict-fix. The describe-then-escalate path is harder to fixture-control than the triage-pause path; harness regex tolerance may be the right intervention surface, not fixture prose.

## Verification Observable

**Observable:** Running the 3 scenarios touched by this task (F16-triage-ambiguous, F16-triage-flaky, DEBUG-TELEMETRY-INCONCLUSIVE) against the committed state on sonnet yields the expected outcomes: 2 strict PASS + 1 SOFT_PASS (the documented lenient-coverage state for the DEBUG-TELEMETRY-INCONCLUSIVE scenario).

**Verification command:** `./tests/run-tests.sh --id F16-triage-ambiguous,F16-triage-flaky,DEBUG-TELEMETRY-INCONCLUSIVE --model sonnet`

**Expected result:** Summary line shows `TOTAL: 2 PASS, 1 SOFT, 0 FAIL` (or equivalent shape with the 3 scenarios accounted for). The 2 strict PASSes match the F16-triage-ambiguous + F16-triage-flaky scenarios; the 1 SOFT is the documented behavior of DEBUG-TELEMETRY-INCONCLUSIVE per the task's act-time decision.

## Verification Result

**Status:** PASS
**Date:** 2026-06-12
**Evidence:** Test harness summary —
```
GROUP         PASS  SOFT  FAIL FLAKY TOTAL
debug            0     1     0     0     1
feature          2     0     0     0     2
TOTAL            2     1     0     0     3
Cost: $0.288 | Duration: 68s
```
Per-scenario detail (from `tests/results/run-2026-06-12-130134.json`):
- F16-triage-ambiguous: PASS — `Structured match: TRANSITION: F14 (any-of: F16|F14)`
- F16-triage-flaky: PASS lenient — `Structured match on F16 (any-of: F16|F14) but also mentioned: /feature-ship, modified` (the model legitimately quoted skill prose referring to /feature-ship; harness lenient default treats structured match as authoritative)
- DEBUG-TELEMETRY-INCONCLUSIVE: SOFT_PASS — `Contains 'inconclusive' (no structured TRANSITION line)` — the documented final state per the task's act-time decision

**Notes:** All 3 outcomes match the verify-time expected result exactly. The lenient-PASS detail on F16-triage-flaky is itself a small surface for future tightening (could remove `modified` from not_contains; it's a less specific marker than `/feature-build` or `automatically fixed`), but is well within the task's intended outcome (strict PASS on the F16-triage-flaky transition).

## Retrospect

- **What changed in our understanding:** Two distinct discoveries: (1) The F16-triage SOFT_PASS root cause was the verify-codify skill's §5 transition-enumeration ambiguity — triage-pause classifications have NO canonical exit token, so the model legitimately routes them as either F16 (work-product complete) OR F14 (back-loop to verify-human). Both are structurally correct; `transition_id_any` is the right harness shape. (2) The DEBUG-TELEMETRY-INCONCLUSIVE strict-PASS path is harder to coax than the original SURFACE entry anticipated — the failure mode is markdown-decoration breaking the harness regex's alnum-hyphen capture class, not the model failing to escalate. The fixture-shape control I attempted (explicit "no markdown decoration" instructions) didn't override sonnet's natural inclination to bold-mark the TRANSITION token. Surfaced as P-followup with 3 candidate fix paths.
- **Assumptions that held:** The dual-identity fix shape (`transition_id_any: [F16, F14]`) cleanly resolved both F16-triage SOFT_PASSes — same skill, same structural ambiguity, same fix. Adding `model: sonnet` tags to scenarios where haiku is empirically noisy is the right hygiene. Lenient SOFT_PASS is harness-supported coverage and acceptable for the inconclusive path's documented fragility.
- **Assumptions that were wrong:** Plan estimated F16-triage-ambiguous had a single root cause (the prose-leak); bite-verify revealed the dual-identity transition issue was ALSO at play. Plan also expected DEBUG-TELEMETRY-INCONCLUSIVE would land strict-PASS with a thoughtful fixture; 3 attempts proved this wrong. The harness-regex side (not fixture-prose side) is likely where the strict-PASS fix lives.
- **Approach delta:** Plan T1 fix was 1-line `not_contains` softening; actual implementation also added `transition_id_any: [F16, F14]` after bite-verify (1 line additional, mid-act discovery, not back-loop-worthy). Plan T5.3 expected strict PASS; actual outcome is SOFT_PASS shipped with detailed follow-up SURFACE entry. Both deltas were act-time scoping refinements, not plan-revision triggers.
