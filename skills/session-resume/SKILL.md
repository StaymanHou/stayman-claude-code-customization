---
name: session-resume
description: Resume a previously paused workflow session — restores context from workflow/wip/
argument-hint: <optional name of the WIP item to resume>
---

# Session Resume

Get the user back into flow as quickly as possible.

**Steps:**

1. **Find WIP files:** List `workflow/wip/` contents. If empty, tell the user there's nothing to resume and suggest `/session-start`.

2. **Select:** If multiple WIP files exist, present them and ask which to resume. If the user specified one via `{{args}}`, use that.

3. **Read context:** Open the selected WIP file. Look for the most recent "Session Pause" note or the latest status update.

4. **Restore context:**
   - Summarize where work left off (2-3 sentences max).
   - State the current workflow and step.
   - State the immediate next action.
   - Mention any open questions/blockers from the pause note.

5. **Hand off:** Tell the user the exact skill to invoke to continue, e.g.: "Run `/feature-build` to continue where you left off."

6. **Backlog check:** Quickly scan `workflow/backlog.md` (if it exists) for any `high` priority items that relate to the current work. Mention them if found.
