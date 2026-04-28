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
- **Read `## Current Node` first** — this is the authoritative position pointer; resume from where it points

### 2. Environment Check
- Read the project `CLAUDE.md` at the root for environment rules (also `.claude/CLAUDE.md` if present)
- **Docker Rule:** If the project mandates Docker, ALL commands (pip, python, npm, etc.) MUST run inside the container. Only git commands and basic file operations run on the host.

### 3. Implement
- Work only on the step(s) named in `## Current Node` Active scope
- Make atomic, logical changes
- Verify syntax after editing files
- Mark each step `[x]` in the Work Tree as it completes
- Before using project-specific CLI tools, verify their syntax (e.g., `--help`)

### 4. Attach Discoveries to the Tree

When you discover something new while working on a step:
- Add a `SURFACED` child node under the relevant step in the Work Tree: `- [ ] <summary>  <!-- status: SURFACED: <summary> -->`
- Also log to `workflow/backlog.md`:

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

**If you discover the plan needs changing (T6):**
Document what changed and why in the WIP file. Tell user to run `/task-plan` to revise.

**Pause-and-escalate (T7 blocker variant):** If discovery IS a blocker, save state and tell the user what needs to happen at the higher level before this task can continue.

**ESCALATE (T9):** If the task has grown beyond task scope entirely, close/archive the WIP plan as "Escalated to feature:spec", and tell the user to run `/feature-spec`.

### 5. Parent Completion Enforcement
Before exiting, scan the Work Tree:
- If ALL children of a step are `[x]` but the step itself is not `[x]` → mark the step `[x]` now

### 6. Update Current Node and Exit
Always update `## Current Node` before handing off:
- Advance Path and Active scope to the next incomplete step
- If all steps complete, set Active scope to "all complete"

### 7. Completion
When all steps are `[x]`:
- Mark all complete in the Work Tree
- Update the WIP file state to `act (complete)`
- Tell the user to run `/task-close`
