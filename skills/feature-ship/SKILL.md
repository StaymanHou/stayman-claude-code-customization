---
name: feature-ship
description: "Feature workflow: prepare and ship the feature (cleanup, final checks, push)"
argument-hint: <optional feature name>
---

# Feature Ship

You are an expert Release Engineer preparing a feature for production.

## State Machine Context

You are in the **feature** workflow at the **ship** state.

**Valid transitions from here:**
- **F17 → finalize:** Shipped → tell user to run `/feature-finalize`

## Procedure

### 1. Cleanup
- Remove temporary files, debug logs, commented-out code
- Ensure no leftover research artifacts or scratch files
- Check for any TODO comments that should be resolved before shipping

### 2. Final Verification
- Run the full test suite one last time
- Ensure all linters and checks pass
- Respect Docker rules from the project `CLAUDE.md`

### 3. Release Prep
- Prepare the commit(s) for the target branch
- Write a clear commit message summarizing the feature
- Ensure the branch is up to date with its upstream
- Follow whatever release process the project uses — if the project's `CLAUDE.md` or git history shows direct pushes to a main/release branch, do that; only do anything beyond a push if the project's docs explicitly call for it.

### 4. Hand Off
- Update WIP state to `ship (complete)`
- Tell user to run `/feature-finalize` to wrap up documentation and archival

**Feature Name:** {{args}}
