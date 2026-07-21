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

The problem primarily surfaces at `verify-codify`, which runs the full test suite. Earlier verification steps (`verify-auto`, `verify-self`) run scoped checks and rarely hit unexpected failures. `verify-codify` is the highest-stakes moment: a silent misclassification here removes a specification artifact from the permanent suite.

The fix belongs in `verify-codify`: a hard triage gate before the agent takes any action on a failing test.

### Classification and auto/pause policy

When a test fails at `verify-codify`, the agent must classify it before acting. Spell out the classification in full — do not use shorthand labels.

| Classification | Confidence | Action |
|---|---|---|
| Code regression (test is correct, new code broke it) | High | Auto-fix code |
| Code regression | Low / ambiguous | Pause for human |
| Obsolete test (new feature intentionally supersedes what the test checked) | High | Auto-update or delete test |
| Obsolete test | Low / ambiguous | Pause for human |
| Both sides valid — contract conflict requiring product judgment | Any | Always pause |
| Flaky test (failure unrelated to new code; timing or environment) | — | Auto re-run up to 2 retries; if failing after 3 total runs, pause |

**High confidence** means: the agent can point to a specific line in the new code or the test that unambiguously explains the failure, with no plausible alternative reading.

### Artifact requirement

Before taking any action on a failing test, the agent must write a `## Test Triage` entry to the WIP file:

```
## Test Triage — <test name>
Classification: <spelled out>
Confidence: high / low / ambiguous
Evidence: <one sentence pointing to the specific cause>
Action: <what the agent did or is waiting for human approval to do>
```

This creates an audit trail. If the classification was wrong, the record shows the agent's reasoning at the time.

---

## Pain Point 5: Agent Stops and Waits After `feature-build` Instead of Auto-Advancing Through Verification

### What was observed

After completing `feature-build`, the agent ends its turn with a prompt like:

> "Run `/feature-verify-auto` to proceed to verification."

The user must manually invoke `/feature-verify-auto`. After that passes, the agent ends with:

> "Run `/feature-verify-self` to do live browser verification."

Again the user must invoke it manually. The agent treated each step as a full stop requiring a user command, even though the user had no decision to make — all checks passed, there was nothing to confirm.

The user's actual response: "Just go ahead."

### Root causes

**RC5-1: Skill prompts end with a transition instruction addressed to the user, not to the orchestrator.** Each skill's SKILL.md tells the model to "Run `/feature-verify-auto`" or "Run `/feature-verify-self`" — phrased as a user command. In single-step invocation mode this is correct: the user is driving. But in orchestrated mode (via `/session-start`), the orchestrator should be receiving that signal and auto-advancing, not the user.

**RC5-2: The orchestrator's Orchestration Procedure does not distinguish auto-advance steps from human-pause steps.** The `feature-workflow/AGENTS.md` procedure lists each step, but does not explicitly flag which steps require a human pause vs. which should be auto-chained by the orchestrator. The orchestrator defaults to pausing after every step because the procedure is ambiguous.

**RC5-3: No mechanism for the skill to signal "auto-advance" vs. "pause for human."** Skills end with a transition ID (e.g., `TRANSITION: F5`) but carry no metadata indicating whether the next step needs human input. The orchestrator has no machine-readable signal to act on — it must infer from context or procedure prose, which it does not reliably do.

**RC5-4: `verify-auto` and `verify-self` have no decision points that require human input when they pass.** When both pass cleanly, the correct behavior is: finish verify-auto → immediately start verify-self → immediately proceed to verify-human. A human pause only makes sense if a step *fails* (back-loop decision) or explicitly requires human input (verify-human by definition). Clean passes should be transparent.

### Where the fix should live

**In `agents/feature-workflow/AGENTS.md` (Orchestration Procedure):** Each step in the procedure should be annotated with its pause policy:
- `AUTO` — orchestrator advances immediately on a passing transition (no user prompt)
- `PAUSE` — orchestrator stops and waits for human input before advancing

`verify-auto` → `AUTO` when passing (back-loop to build if failing)
`verify-self` → `AUTO` when passing (back-loop to build if BLOCKING failure found)
`verify-human` → always `PAUSE` (human must confirm before codify)
`verify-codify` → `AUTO` when passing
`build` → `AUTO` to verify-auto (no human confirmation needed to start verification)
`feature-ship` → `AUTO` (human already confirmed at verify-human; ship immediately)
`feature-finalize` → `PAUSE` (human reviews backlog before close)

**In skill SKILL.md transition language:** Distinguish between transitions addressed to the orchestrator vs. the user. A skill running in orchestrated context should communicate "advance to X" as a machine signal, not a human instruction. One approach: keep the `TRANSITION: <id>` token as the machine signal; the prose "Run `/x`" remains for single-step users but the orchestrator acts on the token, not the prose.

**Critical constraint:** The fix must not break single-step invocation. A user directly invoking `/feature-verify-auto` should still see clear guidance on what to run next. The AUTO/PAUSE distinction is an orchestrator-layer concern; individual skills should remain agnostic about whether they're running in orchestrated or single-step mode.