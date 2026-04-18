---
name: session-resume
description: Resume a previously paused workflow session — restores context from workflow/.session.md
argument-hint: <optional override — ignored if workflow/.session.md exists>
---

# Session Resume

Get the user back into flow as quickly as possible.

**Steps:**

1. **Read `workflow/.session.md`.** If it does not exist, tell the user there's nothing to resume and suggest `/session-start`.

2. **Parse the pointer.** The frontmatter tells you:
   - `workflow` and `step` — where the user left off
   - `resume_skill` — the exact slash command to invoke next
   - `state_file` — the canonical WIP/doc file holding the work content

3. **Open `state_file`** and read the latest content, including any "Session Pause" marker.

4. **Restore context.** In 2–3 sentences:
   - Summarize where work left off
   - State the current workflow and step
   - State the immediate next action
   - Mention any open questions/blockers from the pause note

5. **Hand off.** Tell the user the exact skill to invoke to continue, e.g.: "Run `/feature-build` to continue where you left off." (This should match `resume_skill` from the pointer.)

6. **Backlog check.** Quickly scan `workflow/backlog.md` (if it exists) for any `high` priority items that relate to the current work. Mention them if found.

7. **Clean up.** Once the user has resumed, `workflow/.session.md` stays in place — it will be overwritten by the next `/session-pause` or deleted by the workflow's terminal state.
