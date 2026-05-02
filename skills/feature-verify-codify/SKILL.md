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

### 2. Write Comprehensive Tests
For each verified behavior, write tests that codify it:
- **Unit tests** for individual components/functions
- **Integration tests** for interactions between components
- **Edge case tests** based on the edge cases from the human verification checklist
- Follow the project's testing conventions and framework

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
