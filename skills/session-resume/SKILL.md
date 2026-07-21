---
name: session-resume
description: Resume a previously paused workflow session — restores context from workflow-system/state/.session.md
argument-hint: <optional override — ignored if workflow-system/state/.session.md exists>
---

# Session Resume

Get the user back into flow as quickly as possible.

## Valid transitions

When you finish, label your output with one of these IDs:

- **S6** — Standard resume: context restored, `.session.md` deleted, hand off to `resume_skill`
- **S15** — Surfaced `drive_mode` from `.session.md` and presented the change-mode menu
- **S16** — User selected a different drive mode on resume; updated WIP frontmatter accordingly

**Steps:**

1. **Read `workflow-system/state/.session.md`.** If it does not exist, tell the user there's nothing to resume and suggest `/session-start`.

2. **Parse the pointer.** The frontmatter tells you:
   - `workflow` and `step` — where the user left off
   - `resume_skill` — the exact slash command to invoke next
   - `state_file` — the canonical WIP/doc file holding the work content
   - `drive_mode` — the active drive mode when paused (may be absent for sessions paused before this feature)

3. **Open `state_file`** and read the latest content, including any "Session Pause" marker.

4. **Restore context.** In 2–3 sentences:
   - Summarize where work left off
   - State the current workflow and step
   - State the immediate next action
   - Mention any open questions/blockers from the pause note

   **Determine the active drive mode** using this priority order:
   1. `drive_mode` from `.session.md` frontmatter (most authoritative — set at pause time)
   2. `drive_mode` from `state_file` frontmatter (fallback for older sessions)
   3. Default to `orchestrated` (Mode 2) if neither source has it

   Include the active mode in the context summary, e.g.: "Resuming in **Autopilot** mode."

4b. **Offer a mode change.** Present the numbered menu so the user can keep or switch modes before diving back in:

   ```
   Drive mode — press Enter to keep current, or pick a new one:
     1  Stepping      pause after every skill, I'll tell you the next command
     2  Orchestrated  standard policy
     3  Autopilot     only pause at verify-human (default)
     4  FSD           no stops, verify-human skipped
   Current: <mode name>  [Enter = keep]
   ```

   - If the user presses Enter or types nothing → keep the current mode, no file changes needed.
   - If the user selects a different mode → update the `drive_mode:` field in `state_file`'s YAML frontmatter to the new value before handing off.

5. **Hand off.** Tell the user the exact skill to invoke to continue, e.g.: "Run `/feature-build` to continue where you left off." (This should match `resume_skill` from the pointer.)

6. **Backlog check.** Quickly scan `workflow-system/state/backlog.md` (if it exists) for any `high` priority items that relate to the current work. Mention them if found.

6b. **Strip the stale Pause footer from `state_file`.** The `## Session Pause — <timestamp>\nPaused. See …` block that `/session-pause` injected (per `session-pause` SKILL.md §3) must be removed from the `state_file` body now — otherwise it lingers and accrues a cleanup tax at finalize/close time on every paused-then-resumed item. Idempotent — no-op if the marker isn't there. Match pattern: the trailing `## Session Pause — ` heading + all following lines up to EOF (current `/session-pause` always appends to EOF). If a future `/session-pause` variant inserts mid-document, extend the match to "until next `## ` heading or EOF." Edit `state_file` in place to remove the matched block.

7. **Clean up.** Delete `workflow-system/state/.session.md` now — its purpose is consumed. The next `/session-pause` will recreate it if needed.
