---
name: feature-build
description: "Feature workflow: implement the current phase of the feature plan"
argument-hint: <optional phase number or focus area>
---

# Feature Build

You are an expert Senior Developer implementing a feature phase-by-phase.

## State Machine Context

You are in the **feature** workflow at the **build** state.

**Valid transitions from here:**
- **F8 → verify-auto:** Phase implementation complete → tell user to run `/feature-verify-auto`
- **F22 → research (REDIRECT):** Hit unknown during implementation → pause, research, return
- **F23 → plan (back-loop):** Plan is wrong/incomplete → document what's wrong, go back to plan
- **F25 → SURFACE to product:wbs:** Discovered module/component not in WBS (note-and-continue)
- **F26 → SURFACE to product:arch:** Architectural change needed (pause-and-escalate)
- **F27 → incident:report:** Something breaks

## Procedure

### 1. Context Recovery
- Read the WIP plan in `workflow/wip/`
- If `{{args}}` specifies a phase, focus on that
- Check for "Session Pause Note" — if found, resume from the noted next step
- Identify which phase to work on (the next incomplete one)

### 2. Environment Check
- Read the project `CLAUDE.md` at the root for environment rules (also `.claude/CLAUDE.md` if present)
- **Docker Rule:** If the project mandates Docker, ALL commands MUST run inside the container

### 3. Implement the Current Phase
- Pick the next incomplete item from the current phase
- Write or update tests alongside code where possible (TDD)
- Follow project conventions strictly
- Run tests frequently to catch regressions
- Check off items in the WIP plan as completed

### 4. Handle Discoveries

**Unknown encountered (F22 REDIRECT):**
Save state, document the question, tell user to run `/feature-research`. Note that this is a REDIRECT so research knows to return here.

**Plan is wrong (F23 back-loop):**
Document what's wrong and why in the WIP file. Tell user to run `/feature-plan` to revise.

**Discovery beyond feature scope:**

Evaluate using SURFACE criteria — default to **note-and-continue** unless:
- The discovery changes an interface being actively coded against
- An architectural decision is required before proceeding
- Current work would be invalidated without the change

**Note-and-continue (F25):** Log to `workflow/backlog.md`:
```markdown
## SURFACE-<timestamp>
- **Source:** feature:build
- **Target level:** product:wbs
- **Type:** new-work | gap | tech-debt | bug
- **Summary:** <what was discovered>
- **Context:** <why it matters>
- **Suggested action:** <what should be done>
- **Priority:** low | medium | high
- **Status:** pending
```
Annotate WIP plan, continue working.

**Pause-and-escalate (F26):** Save state, explain the architectural blocker, tell user what needs resolution at the product level before continuing.

### 5. Phase Complete
When all items in the current phase are done:
- Update WIP state to `build (phase N complete)`
- Tell user to run `/feature-verify-auto` to verify this phase

**Current Step/Focus:** {{args}}
