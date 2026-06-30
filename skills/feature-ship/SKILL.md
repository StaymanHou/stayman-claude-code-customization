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
- **F38 → review-quality (default):** Shipped → invoke per-feature code-quality review against the ship commit baseline before finalize. Tell user to run `/feature-review-quality`.
- **F17b → finalize (Mode 4 SKIP path):** When `drive_mode: fsd` in the WIP frontmatter, the review-quality step is skipped entirely — ship hands off directly to finalize. Tell user to run `/feature-finalize`.

**Mode detection:** Read `drive_mode` from the WIP file's YAML frontmatter. If `drive_mode: fsd`, emit F17b. Otherwise (any other value, missing, or `drive_mode: autopilot` / `orchestrated` / `stepping`), emit F38.

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
- Read `drive_mode` from the WIP file's YAML frontmatter:
  - **`drive_mode: fsd`** → tell user to run `/feature-finalize` (skipping review-quality); emit `TRANSITION: F17b`.
  - **All other modes (autopilot / orchestrated / stepping / missing)** → tell user to run `/feature-review-quality` to run per-feature code-quality review against the ship commit before finalize; emit `TRANSITION: F38`.

### 5. Emit Transition

End your output with the canonical transition token so the orchestrator can act on it (the orchestrator reads `TRANSITION: <id>`; the bare slash-command prose above is advisory for single-step users only):

- `TRANSITION: F38` — default ship → review-quality path (Modes 1, 2, 3, or missing drive_mode)
- `TRANSITION: F17b` — Mode 4 (fsd) ship → finalize direct path, skipping review-quality

**Feature Name:** {{args}}
