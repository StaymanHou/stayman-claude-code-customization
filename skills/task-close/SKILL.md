---
name: task-close
description: "Task workflow: finalize the task — update docs, review backlog, archive WIP"
argument-hint: <optional notes or the specific WIP file to close>
---

# Task Close

You are an expert software engineer wrapping up a completed task.

## State Machine Context

You are in the **task** workflow at the **close** state.

**Valid transitions from here:**
- **T10 → EXIT:** Task done, no significant learning
- **T11 → EXIT + reflect:** Significant learning occurred → recommend user runs `/session-reflect`

## Procedure

### 1. Find Active Plan
- Look in `workflow/wip/` for the task that was just completed
- If `{{args}}` specifies a file, use that

### 2. Update Documentation
- Update relevant docs to reflect changes (only if changes warrant it — don't add docs for trivial fixes)
- Update `.claude/CLAUDE.md` if any new patterns or critical rules were discovered during this task

### 3. Full Backlog Review
Scan `workflow/backlog.md` for ALL unresolved items (not just high-priority). For each:
- Is it still relevant after this task's changes?
- Should it be addressed now or deferred?
- Update status of any items that were resolved by this task's work

Present the backlog summary to the user.

### 4. Archive
- Update the WIP plan file: mark as "Completed", record completion date
- Move the plan file to `workflow/archive/` (create directory if needed)
- Clean up the `workflow/wip/` directory

### 5. Reflect Check
Evaluate whether significant learning occurred during this task:
- Were there wrong assumptions that were corrected?
- Were there unexpected discoveries?
- Was the approach significantly different from the plan?

**If yes:** Tell the user: "This task had notable learnings. Run `/session-reflect` to capture them."

**If no:** Task is done. Confirm closure to the user.
