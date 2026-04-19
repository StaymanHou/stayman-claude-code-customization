---
name: task-plan
description: "Task workflow: analyze request, discover context, and create an implementation plan in workflow/wip/"
argument-hint: <description of the task to plan>
---

# Task Plan

You are an expert software engineer starting a new task.

**User Request:** {{args}}

## State Machine Context

You are in the **task** workflow at the **plan** state.

**Valid transitions from here:**
- **T2 → act:** Plan is clear, ready to implement → tell user to run `/task-act`
- **T3 → ESCALATE to feature:spec:** "This is bigger than a task" — close the task plan, update docs, tell user to run `/feature-spec`
- **T4 → REDIRECT to feature:research:** Research needed before acting — pause task, tell user to run the research, then return

## Procedure

### 1. Backlog Check
Before planning, scan `workflow/backlog.md` (if it exists) for:
- `high` priority items matching this task area
- Items whose target is `task` level
- Conflicts with what's about to be planned

Mention any relevant backlog items to the user.

### 2. Context Discovery
- Read the project `CLAUDE.md` at the root for project-specific rules (also check `.claude/CLAUDE.md` if present — that path is for agent-only overrides)
- Search for relevant files, existing patterns, documentation
- Understand the scope and constraints

### 3. Scope Assessment
Evaluate whether this is truly a task or should be escalated:
- If it requires new data models, API endpoints, or architectural decisions → recommend ESCALATE (T3)
- If there are unknowns that need research first → recommend REDIRECT (T4)
- Otherwise → proceed with planning

### 4. Plan Creation
Create a markdown file in `workflow/wip/<task-slug>.md` with this structure:

```markdown
# Task: <title>

**Workflow:** task
**State:** plan
**Created:** <YYYY-MM-DD>

## Requirements
- Clear goals and constraints

## Context
- Links to relevant files discovered above

## Implementation Plan
- [ ] Step 1
- [ ] Step 2
- [ ] ...

## Verification
- How to verify the changes (tests, commands)
```

### 5. Stop and Hand Off
After creating the plan:
- Present a high-level summary
- **STOP** — do NOT start implementing
- Tell the user to run `/task-act` to begin implementation
