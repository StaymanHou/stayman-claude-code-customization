---
name: session-restore
description: Restore a previously handed-off workflow session — restores context from workflow-system/state/.session.md. Paired with /session-handoff (the OUT skill). Named "restore" (not "resume") to avoid colliding with the built-in /resume command.
argument-hint: <optional override — ignored if workflow-system/state/.session.md exists>
---

# Session Restore

Get the user back into flow as quickly as possible — restore the session that `/session-handoff` handed off.

## Valid transitions

When you finish, label your output with one of these IDs:

- **S6** — Standard restore: context restored, `.session.md` deleted, hand off to `resume_skill`
- **S15** — Surfaced `drive_mode` from `.session.md` and presented the change-mode menu
- **S16** — User selected a different drive mode on restore; updated WIP frontmatter accordingly

**Steps:**

1. **Read `workflow-system/state/.session.md`.** If it does not exist, tell the user there's nothing to restore and suggest `/session-start`.

2. **Parse the pointer.** The frontmatter tells you:
   - `workflow` and `step` — where the user left off
   - `resume_skill` — the exact slash command to invoke next
   - `state_file` — the canonical WIP/doc file holding the work content
   - `drive_mode` — the active drive mode when handed off (may be absent for sessions handed off before this feature)

3. **Open `state_file`** and read the latest content, including any "Session Handoff" (or legacy "Session Pause") marker.

4. **Restore context.** In 2–3 sentences:
   - Summarize where work left off
   - State the current workflow and step
   - State the immediate next action
   - Mention any open questions/blockers from the handoff note

   **Determine the active drive mode** using this priority order:
   1. `drive_mode` from `.session.md` frontmatter (most authoritative — set at handoff time)
   2. `drive_mode` from `state_file` frontmatter (fallback for older sessions)
   3. Default to `orchestrated` (Mode 2) if neither source has it

   Include the active mode in the context summary, e.g.: "Restoring in **Autopilot** mode."

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

6b. **Strip the stale Handoff footer from `state_file`.** The `## Session Handoff — <timestamp>\nHanded off. See …` block that `/session-handoff` injected (per `session-handoff` SKILL.md §3) must be removed from the `state_file` body now — otherwise it lingers and accrues a cleanup tax at finalize/close time on every handed-off-then-restored item. Idempotent — no-op if the marker isn't there. Match pattern: the trailing `## Session Handoff — ` heading (or the legacy `## Session Pause — ` heading, for items handed off before the WP5 rename) + all following lines up to EOF (`/session-handoff` always appends to EOF). If a future `/session-handoff` variant inserts mid-document, extend the match to "until next `## ` heading or EOF." Edit `state_file` in place to remove the matched block.

7. **Clean up.** Delete `workflow-system/state/.session.md` now — its purpose is consumed. The next `/session-handoff` will recreate it if needed.
