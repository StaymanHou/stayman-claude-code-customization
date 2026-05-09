# Feature: Order-flip regression in feature workflow

**Workflow:** feature
**State:** reproduce
**Created:** 2026-05-08
**Entry:** reproduce (bug-fix feature)

## Problem Statement
After verify-codify on the final phase of a feature, the agent's closing prose inverted the ship/finalize order — claiming "Ready for feature-finalize → feature-ship" when the correct order is ship → finalize. The state machine is correct (F16, F17); the bug is in agent prose.

## Reproduction Attempt
**Surface chosen:** failing test
**Outcome:** reproduced
**Artifact:** `tests/scenarios/feature.yaml::F16-order` — new scenario asserting verify-codify output mentions `/feature-ship` BEFORE any mention of `/feature-finalize`. Currently fails on haiku in 2 of 3 runs.
**Determinism:** flaky (2 of 3) — tightened by adding `not_contains_strict: true` on the inverted-order phrase
**Notes:** The failing test is the verify-codify anchor for this feature. Once the fix lands, this test must pass deterministically.
