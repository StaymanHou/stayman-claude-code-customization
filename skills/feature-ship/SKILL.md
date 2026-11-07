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
- **Full test suite: run it, or reuse the last phase's run.** Read the `Test scope:` line that `feature-verify-codify` recorded under the last phase's `verify-codify` leaf in the WIP:
  - **`Test scope: full — …`, and nothing but §1's cleanup changed since that run** (removed scratch files, comments, docs; no source or test edit) → do **not** run the suite again. Cite the run instead: `Full suite: reused the last-phase codify run (<the scope line>, <its result>)`. On a slow suite this is the difference between one full run per feature and two.
  - **Anything else** → run the full test suite now: the line says `nearby`, the line is missing (an older WIP), or code or tests changed after that run (including §1 removing debug code). **A line you have not actually read counts as missing.** Reuse rests on the recorded run, so never reuse on a guess about what the line says.
- Ensure all linters and checks pass. These are fast; always run them.
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
