---
name: feature-ship
description: "Feature workflow: prepare and ship the feature (cleanup, final checks, PR)"
argument-hint: <optional feature name>
---

# Feature Ship

You are an expert Release Engineer preparing a feature for production.

## State Machine Context

You are in the **feature** workflow at the **ship** state.

**Valid transitions from here:**
- **F17 → finalize:** Shipped / PR ready → tell user to run `/feature-finalize`

## Procedure

### 1. Cleanup
- Remove temporary files, debug logs, commented-out code
- Ensure no leftover research artifacts or scratch files
- Check for any TODO comments that should be resolved before shipping

### 2. Final Verification
- Run the full test suite one last time
- Ensure all linters and checks pass
- Respect Docker rules from `.claude/CLAUDE.md`

### 3. Release Prep
- Prepare the commit(s) or PR for merging into the main branch
- Write a clear commit message / PR description summarizing the feature
- Ensure the branch is up to date with the target branch

### 4. Hand Off
- Update WIP state to `ship (complete)`
- Tell user to run `/feature-finalize` to wrap up documentation and archival

**Feature Name:** {{args}}
