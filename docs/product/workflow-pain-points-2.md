# Workflow Pain Points — Diagnostic Reference (Vol. 2)

*Captured: 2026-04-30. Raw diagnosis only — no fixes proposed here. Use this as input when designing improvements to skills and the WIP format.*

---

## Pain Point 4: Agent Cannot Reliably Triage a Failed Test

### What was observed

- A test that previously passed begins failing after new code is introduced.
- The agent, under pressure to keep things green, silently updates the test to match the new behavior.
- The test was correct — it encoded a business rule that the new code violated. The rule is now gone, unannounced.

Or the mirror image:

- A test fails, the agent correctly identifies the code as broken, and fixes it.
- But the test was actually encoding an old requirement that the new feature intentionally supersedes.
- The fix reverts new behavior to satisfy a stale expectation, undoing the intended change.

In both cases the agent made a call — "fix the code" or "update the test" — that was not unambiguously correct, and made it silently without escalating to the human.

### Three hypotheses when a test fails

When a test fails, exactly one of three things is true:

**H1 — Code regression:** The test is correct and the intended behavior is unchanged. The new code introduced a regression. Fix the code.

**H2 — Logic reconciliation required:** The test is correct and the new feature is correct, but they conflict because the new feature changes a contract that the test was guarding. Neither side is simply "wrong." A human must decide which contract wins — the old guarantee or the new behavior.

**H3 — Test is now obsolete:** The new feature intentionally changes the behavior the test was checking. The test no longer reflects a desired invariant. The test should be updated or deleted — but only after a human confirms the old behavior is no longer required.

### Root causes

**RC4-1: The agent has no decision procedure for test failure triage.** The `feature-verify-auto` skill instructs the agent to run tests and report results. It does not instruct the agent to classify a failure as H1, H2, or H3, or to distinguish which classification requires human approval before acting.

**RC4-2: The agent treats test modification as equivalent to code modification.** Changing a test is a higher-stakes action than changing implementation code — it removes a specification artifact, not just an implementation detail. The current workflow applies no asymmetric scrutiny to test changes.

**RC4-3: H1 is distinguishable by inspection; H2 and H3 require human judgment.** H1 can often be resolved by the agent alone: read the test, read the code, identify the regression, fix it. H2 and H3 both involve a conflict between two valid views of what the system should do — a question the agent cannot answer without knowing the product intent. The workflow currently has no gate that routes H2 and H3 to the human before the agent acts.

**RC4-4: No classification artifact is produced.** When the agent decides which hypothesis applies, that decision is implicit in whatever action it takes next. There is no artifact — in the WIP file, the verify output, or the commit message — that records "I classified this as H1, here is my reasoning." If the classification was wrong, there is no trail.

**RC4-5: Confidence is not represented.** Sometimes H1 is obvious (a null-pointer in new code breaks an unrelated test). Sometimes the signal is ambiguous (a behavior test now fails, but it's unclear whether the new feature was supposed to change that behavior). The agent has no vocabulary for "I'm 90% confident this is H1" vs. "this could be H2 or H3, I'm not sure." Without a confidence signal, the agent can't self-escalate on ambiguous cases.

**RC4-6: The verify→build loop provides no friction for test modifications.** When the agent re-enters `build` from `verify-auto`, it can change tests and code with equal freedom. There is no prompt instruction that says "changing a test requires you to state your hypothesis and, for H2/H3, pause for human confirmation before proceeding."

### Where the fix should live

The triage decision can surface at any verification step, not only at `verify-auto`. As the agent iterates through the loop and accumulates new information, a previously green test may become relevant again at a later step:

- **`verify-auto`** — first encounter; the agent runs scoped checks and may hit an obvious H1 regression or an ambiguous H2/H3 conflict.
- **`verify-self`** — live-system observation may reveal a behavioral discrepancy that re-opens a test classification question.
- **`verify-human`** — human feedback may reveal that a passing test was guarding a contract the human considers superseded (H3) or still required (H2).
- **`verify-codify`** — the most consequential moment. Codify is the step that ensures all regression checks pass and are permanently committed. If a test fails here, the stakes are highest: a silent H3 misclassification at this step removes a specification artifact from the permanent suite.

The decision procedure and human-approval gate for H2/H3 must therefore be present in every verification skill, not just `verify-auto`. The `feature-build` re-entry rules must also enforce it when the agent returns from any failed verify step. Confidence thresholds (when H1 is obvious vs. ambiguous) should be part of each triage prompt so the agent can self-escalate on ambiguous cases regardless of which step surfaces the failure.