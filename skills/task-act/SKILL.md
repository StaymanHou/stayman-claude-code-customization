---
name: task-act
description: "Task workflow: execute the implementation plan from workflow/wip/"
argument-hint: <optional notes or the specific WIP file to work on>
---

# Task Act

You are an expert software engineer implementing a planned task.

## State Machine Context

You are in the **task** workflow at the **act** state.

**Valid transitions from here:**
- **T5 → close:** Implementation complete, no issues → tell user to run `/task-close`
- **T6 → plan (back-loop):** Need to re-plan — update the WIP file with what changed and why, then re-plan
- **T7 → SURFACE to feature:spec:** Discovered something bigger — see SURFACE rules below
- **T8 → SURFACE to product:wbs:** New work item discovered — see SURFACE rules below
- **T9 → ESCALATE to feature:spec:** Task grew beyond task scope — close task, tell user to run `/feature-spec`

## Procedure

### 1. Find Active Plan
- Look in `workflow/wip/` for the active task plan
- If `{{args}}` specifies a file, use that
- If multiple exist, ask the user which one
- Check for any "Session Pause Note" — if found, resume from the noted next step

### 2. Environment Check
- Read `.claude/CLAUDE.md` for environment rules
- **Docker Rule:** If the project mandates Docker, ALL commands (pip, python, npm, etc.) MUST run inside the container. Only git commands and basic file operations run on the host.

### 3. Implement
- Execute the plan steps in order
- Make atomic, logical changes
- Verify syntax after editing files
- Check off items in the WIP plan as completed
- Before using project-specific CLI tools, verify their syntax (e.g., `--help`)

### 4. Handle Discoveries

**If you discover the plan needs changing (T6):**
Back-loop to plan. Document what changed and why in the WIP file, then re-plan the remaining steps.

**If you discover something beyond task scope:**

Evaluate using SURFACE criteria — default to **note-and-continue** unless:
- The discovery changes an interface being actively coded against
- An architectural decision is required before proceeding
- Current work would be invalidated without the change

**Note-and-continue (T7, T8):** Log to `workflow/backlog.md` using this format:

```markdown
## SURFACE-<timestamp>
- **Source:** task:act
- **Target level:** <feature:spec | product:wbs>
- **Type:** new-work | gap | tech-debt | bug
- **Summary:** <what was discovered>
- **Context:** <why it matters>
- **Suggested action:** <what should be done>
- **Priority:** low | medium | high
- **Status:** pending
```

Then annotate the WIP plan and continue working.

**Pause-and-escalate (T7 blocker variant):** If it IS a blocker, save state and tell the user what needs to happen at the higher level before this task can continue.

**ESCALATE (T9):** If the task has grown beyond task scope entirely, close/archive the WIP plan as "Escalated to feature:spec", and tell the user to run `/feature-spec`.

### 5. Completion
When all plan steps are done:
- Update the WIP file state to `act (complete)`
- Tell the user to run `/task-close`
