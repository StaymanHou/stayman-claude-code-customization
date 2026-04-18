---
name: session-pause
description: Pause the current workflow session — saves state to workflow/.session.md for later resumption
argument-hint: <optional notes about current status>
---

# Session Pause

Save the current workflow state so it can be resumed later.

**Steps:**

1. **Identify the active work.** Determine the current workflow and step (e.g., `feature:build`, `task:act`, `product:roadmap`). Check recent conversation context plus:
   - `workflow/wip/` for feature/task/incident WIP files
   - `docs/product/` for product docs whose frontmatter shows `state: in-progress`

   If multiple active items exist, ask the user which one to pause.

2. **Write `workflow/.session.md`** — this is a single-file session pointer (one active session per repo). Overwrite it each time:

```markdown
---
paused: <YYYY-MM-DD HH:MM>
workflow: <product|feature|task|incident>
step: <current step name>
resume_skill: /<workflow>-<step>
state_file: <path to the active state file, e.g. workflow/wip/<feature>.md or docs/product/roadmap.md>
---

# Session Pause

- **Last completed:** <what was just finished>
- **Next action:** <the very first thing to do when resuming>
- **Open questions/blockers:** <any unresolved issues, or "None">
- **Notes:** <any temporary context worth preserving>
```

3. **Annotate the state file.** Append a short marker to the file referenced in `state_file:` so the context is visible when someone opens that file directly:

```markdown
## Session Pause — <YYYY-MM-DD HH:MM>
Paused. See `workflow/.session.md` to resume.
```

4. **Confirm** to the user:
   - The resume command (always `/session-resume`)
   - A one-liner of what they'll pick up on

**Additional context from user:** {{args}}
