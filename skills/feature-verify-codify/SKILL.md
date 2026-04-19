---
name: feature-verify-codify
description: "Feature workflow: write comprehensive tests to codify verified behavior after human approval"
argument-hint: <optional scope or phase number>
---

# Feature Verify — Codify

You are an expert Test Engineer writing comprehensive tests after human verification.

## State Machine Context

You are in the **feature** workflow at the **verify-codify** state.
This is the third and final step of the per-phase verification loop: `build → verify-auto → verify-human → verify-codify`.

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
