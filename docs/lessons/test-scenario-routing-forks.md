# Test scenario design — routing-fork patterns

Three sub-patterns matter when designing scenarios that test how a skill chooses between branches:

## 1. Variant routing needs dedicated fixtures

When testing "branch A vs branch B from the same parent state" (e.g., I3 / I13 / I4 all exit from triage), each scenario needs its own fixture framing the parent state with the specific branch's signal — not a shared fixture. Sharing makes the model's choice noisy.

**Instance:** Observed in I13 SOFT_PASS (2026-05-09): shared `incident-report-filed.md` caused the model to default to `TRANSITION: I2` instead of I13.

## 2. Entry-state transitions need a different test shape than exit transitions

`transition_id: <X>` + `not_contains: [<downstream paths>]` is structurally fragile when the skill stays *in* a state — the model describes what it won't do, mentioning downstream paths in negation (prose-leak family of S12, F31). Use `transition_id_any: [<entry>, <fallback-exit>]` and avoid aggressive `not_contains` constraints for entry-state scenarios.

## 3. "Default-skip on ambiguous" rules need unambiguous inputs

A scenario asserting "this should fire X" must pick an input where X is the clearly correct answer, not a borderline case. Borderline inputs test calibration, not existence — they will SOFT_PASS or FAIL when the model picks the simpler path.

**Instance:** Observed in S18 redesign (2026-05-09): order-flip-bug input was bug-shape AND small/simple → model correctly chose small/simple path. Redesigned input to be unambiguously complex (multiple components, requires investigation) → PASS strictly.
