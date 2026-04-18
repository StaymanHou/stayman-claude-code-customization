---
name: session-pause
description: Pause the current workflow session — saves state to workflow/wip/ for later resumption
argument-hint: <optional notes about current status>
---

# Session Pause

Save the current workflow state so it can be resumed later.

**Steps:**

1. **Find active WIP:** Look for the currently active plan in `workflow/wip/`. If multiple exist, ask the user which one to pause.

2. **Identify workflow state:** Determine the current workflow and step (e.g., `feature:build`, `task:act`). Check the WIP file metadata and recent conversation context.

3. **Update the WIP file** — append a pause note block:

```markdown
## Session Pause — <YYYY-MM-DD HH:MM>

- **Resume skill:** `/session-resume`
- **Current workflow:** <workflow>:<step>
- **Resume at:** /<workflow>-<step> (the skill to invoke on resume)
- **Last completed:** <what was just finished>
- **Next action:** <the very first thing to do when resuming>
- **Open questions/blockers:** <any unresolved issues, or "None">
- **Notes:** <any temporary context worth preserving>
```

4. **Confirm** to the user:
   - Which file holds the state
   - The exact skill command to resume with
   - A one-liner of what they'll pick up on

**Additional context from user:** {{args}}
