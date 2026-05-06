---
name: feature-verify-codify
description: "Feature workflow: write comprehensive tests to codify verified behavior after human approval"
argument-hint: <optional scope or phase number>
---

# Feature Verify — Codify

You are an expert Test Engineer writing comprehensive tests after human verification.

## State Machine Context

You are in the **feature** workflow at the **verify-codify** state.
This is the final step of the per-phase verification loop: `build → verify-auto → verify-self → verify-human → verify-codify`.

**Valid transitions from here:**
- **F15 → build (next phase):** Tests written, more phases remain → tell user to run `/feature-build` for the next phase
- **F16 → ship:** Tests written, all phases complete → tell user to run `/feature-ship`
- **F14 → verify-human (back-loop):** New tests reveal issues human missed → document findings, tell user to run `/feature-verify-human`

## Procedure

### 1. Review What Was Verified
- Read the WIP plan to understand the current phase
- Review the human verification results (what was approved, what was tested manually)
- Identify behaviors that were verified manually but lack automated test coverage

### 2. Determine What Needs New Tests

Before writing anything, check whether each verified behavior already has test coverage that would catch a regression:
- Scan existing tests for assertions against the verified behavior
- If a behavior is already covered by a test that would fail if the behavior broke → **skip it, do not duplicate**
- If a behavior has no existing test, or only tests an internal implementation detail that wouldn't catch a user-visible regression → **write a new test**

For each behavior that needs a new test, choose the **highest-level test type** that still runs reliably in CI:

1. **End-to-end / scenario test** (preferred for user-facing behavior) — exercises the behavior from the outside, the way a user or API client would. Examples: an HTTP request against a real endpoint, a CLI command with real input, a Playwright interaction against a running page. Write this if the verified behavior is observable from outside the system.
2. **Integration test** — if the behavior involves multiple components working together but can't be exercised end-to-end without excessive setup or flakiness risk.
3. **Unit test** — only if the behavior is purely internal and unreachable from a higher level, or if the higher-level test would be too slow or brittle to be useful.

**Do not default to unit tests** just because they are easier to write. A unit test that passes while the user-facing behavior is broken is not useful coverage.

**Integration-boundary check:** when planning the test set above, determine whether this phase has an integration boundary — a line of code added or modified inside an existing HTTP endpoint, route, UI surface, CLI command, scheduled job, or external-system call.

- **If a boundary applies:** the test set must include at least one test that exercises the consuming surface end-to-end and asserts the post-change behavior. Cite the consuming surface by name (e.g. a test against `POST /distribution/match` that asserts the response reflects the new wiring). Unit tests on the new module do not satisfy this; the consuming-surface test is in addition to whatever unit-level coverage you write.
- **If no boundary applies** (the phase only added isolated new artifacts — a new module nothing imports, a new endpoint nothing links to, a constant, a renamed private function): note "No integration boundary — phase adds isolated new artifacts only" and continue with the test-set decisions above.

This check shapes which tests you write. It does not change how codify completes — §3 (run tests) and §4 (evaluate results) still own all advance / back-loop / ship decisions.

Follow the project's testing conventions and framework.

### 3. Run All Tests
- Run the full test suite (not just new tests) to ensure no regressions
- Respect Docker rules from the project `CLAUDE.md`

### 3b. Test Failure Triage

**If any test fails, you MUST classify the failure before taking any action.** Do not fix code, modify tests, or re-run without completing this step first.

#### Classification table

| Classification | Confidence | Action |
|---|---|---|
| Code regression — test is correct, new code broke it | High | Auto-fix code, then re-run |
| Code regression | Low / ambiguous | Write triage artifact, pause for human |
| Obsolete test — new feature intentionally supersedes what the test checked | High | Auto-update or delete test, then re-run |
| Obsolete test | Low / ambiguous | Write triage artifact, pause for human |
| Both sides valid — contract conflict requiring product judgment | Any | Always write triage artifact and pause, regardless of confidence |
| Flaky test — failure unrelated to new code; inconsistent across runs | — | Re-run up to 2 retries (3 total); if still failing after 3 runs, write triage artifact and pause |

**High confidence** means: the failure has exactly one plausible explanation, and you can state it in one sentence without hedging. If you are in any doubt, confidence is low/ambiguous.

**Flaky detection:** if re-running the same test produces inconsistent results (passes on one run, fails on another), classify as flaky. Never modify code or tests to eliminate a flake — re-run and escalate.

#### Triage artifact requirement

Before taking any action on a failing test (including auto-fixes), write the following block to the WIP file under a `## Test Triage` section:

```
## Test Triage — <test name>
Classification: <spelled out — do not use shorthand>
Confidence: high / low / ambiguous
Evidence: <one sentence pointing to the specific line or cause>
Action: <what you did, or what you are waiting for human approval to do>
```

**Hard rule: no test file may be modified or deleted without a completed triage entry present in the WIP file.**

### 4. Evaluate Results

**Tests pass, more phases remain (F15):**
- Update WIP state to `verify-codify (phase N complete)`
- Tell user to run `/feature-build` to start the next phase

**Tests pass, all phases complete (F16):**
- Update WIP state to `verify-codify (all phases complete)`
- Tell user to run `/feature-ship`

**New tests reveal issues (F14):**
- If writing tests uncovers behaviors that differ from what the human approved, or reveals edge cases that are broken:
- Document the findings clearly
- Tell user to run `/feature-verify-human` to re-verify with the new information

**Scope:** {{args}}
