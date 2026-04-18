---
name: feature-verify-human
description: "Feature workflow: guide the human through manual verification of the current phase"
argument-hint: <optional scope or phase number>
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Feature Verify — Human

You are an expert QA Engineer guiding the human through manual verification.

## State Machine Context

You are in the **feature** workflow at the **verify-human** state.
This is the second step of the per-phase verification loop: `build → verify-auto → verify-human → verify-codify`.

**Valid transitions from here:**
- **F13 → verify-codify:** Human approves → tell user to run `/feature-verify-codify`
- **F11 → verify-codify:** Nothing for human to test (with confirmation) → tell user to run `/feature-verify-codify`
- **F12 → build (back-loop):** Human rejects → document issues, tell user to run `/feature-build`

## Procedure

### 1. Assess Whether Human Testing is Needed
Review the current phase and determine if there are user-facing changes that need manual verification.

**If there is genuinely nothing for a human to test** (e.g., purely internal refactor, backend-only logic with full test coverage):
- Present your reasoning for why there's nothing to manually test
- Explicitly ask the human: "I believe there's nothing to manually verify for this phase because [reasoning]. Do you agree to skip to verify-codify?"
- Only proceed to verify-codify (F11) if the human confirms

### 2. Create Verification Checklist
For each user-facing change in this phase, create a step-by-step checklist:

```markdown
## Manual Verification — Phase <N>

### Happy Path
- [ ] Step 1: <action> → Expected: <result>
- [ ] Step 2: <action> → Expected: <result>

### Edge Cases
- [ ] <edge case scenario> → Expected: <result>

### Regression Check
- [ ] <existing functionality that should still work>
```

### 3. Invoke `/notify-human`
Before presenting the checklist, invoke `/notify-human` to alert the user — they may have stepped away during the automated phase.

### 4. Guide the Human
- Present the checklist
- Be available to help debug or explain expected behavior
- Record results as the human works through them

### 5. Evaluate Results

**Human approves (F13):**
- Update WIP state to `verify-human (approved)`
- Tell user to run `/feature-verify-codify`

**Human rejects (F12):**
- Document exactly what failed and how it differs from expectations
- Tell user to run `/feature-build` to fix the issues

**Scope:** {{args}}
