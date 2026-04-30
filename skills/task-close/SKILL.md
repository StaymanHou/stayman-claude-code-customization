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
- Update the project `CLAUDE.md` (root) if any new patterns or critical rules were discovered during this task

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

### 5. Retrospect + Communicate (required — two separate outputs)

These two steps are mandatory before closing, regardless of whether learnings occurred.

**Output A — Retrospect artifact:** Write a short retrospect in the WIP file before archiving it:

```markdown
## Retrospect
- **What changed in our understanding:** <what we learned that we didn't know at the start>
- **Assumptions that held:** <what we got right>
- **Assumptions that were wrong:** <what surprised us>
- **Approach delta:** <how the actual implementation differed from the plan, if at all>
```

If the task was exactly as planned with no surprises, record that explicitly ("No surprises — implementation matched plan exactly"). Do not skip this section.

**Output B — Communicate step:** Confirm that the requester knows the work is done and what it does. This is a prompted action — produce a brief closure message suitable for sharing:

> **Closure notice:** [Task name] is complete. [One sentence: what was done]. [One sentence: how to verify or where to see the result, if applicable.]

If the requester is the same person running the agent (solo developer), note it as: "Requester = operator — closure notice for self-record."

### 6. Reflect Check
Evaluate whether significant learning occurred during this task (beyond what was captured in the retrospect):
- Were there wrong assumptions that were corrected?
- Were there unexpected discoveries?
- Was the approach significantly different from the plan?

**If yes:** Tell the user: "This task had notable learnings. Run `/session-reflect` to capture them."

**If no:** Task is done. Confirm closure to the user.
