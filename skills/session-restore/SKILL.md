---
name: session-restore
description: Restore a previously handed-off workflow session — restores context from workflow-system/state/.session.md. Paired with /session-handoff (the OUT skill). Named "restore" (not "resume") to avoid colliding with the built-in /resume command.
argument-hint: <optional override — ignored if workflow-system/state/.session.md exists>
---

# Session Restore

Get the user back into flow as quickly as possible — restore the session that `/session-handoff` handed off.

## Valid transitions

When you finish, label your output with one of these IDs:

- **S6** — Standard restore: context restored, `.session.md` deleted, hand off to `resume_skill`. Also the exit when no mode pick was presented because a `tour:` pointer or the Claudesk line decided the mode (step 4b skipped).
- **S15** — Surfaced the active drive mode and presented the change-mode pick (`AskUserQuestion`, or its numbered-list fallback). Bare terminal only.
- **S16** — User selected a different drive mode on restore; updated WIP frontmatter accordingly

**Steps:**

1. **Read `workflow-system/state/.session.md`.** If it does not exist, tell the user there's nothing to restore and suggest `/session-start`.

2. **Parse the pointer.** The frontmatter tells you:
   - `workflow` and `step` — where the user left off
   - `resume_skill` — the exact slash command to invoke next
   - `state_file` — the canonical WIP/doc file holding the work content
   - `drive_mode` — the active drive mode when handed off (may be absent for sessions handed off before this feature), or the deferral marker `from-claudesk` (see step 4, rung 3)
   - `tour:` — **usually absent.** Present only when a `tutorial-*` skill wrote this pointer as one of its own beats. When present, `resume_skill` is that tour skill (step 5 hands control back to it, and it resumes any inner workflow itself), the mode comes from the pointer (step 4, outranking even the Claudesk line), and the mode pick is skipped (step 4b). When absent, every step below takes its ordinary path. The **schema of record** for this field is `skills/session-handoff/SKILL.md` §2 → "Tour-driven handoffs" — consult it rather than inferring the contract from this line; note in particular that resume is **arm-addressed, not step-addressed** (there is no `tour_step:` field).

3. **Open `state_file`** and read the latest content, including any "Session Handoff" (or legacy "Session Pause") marker.

4. **Restore context.** In 2–3 sentences:
   - Summarize where work left off
   - State the current workflow and step
   - State the immediate next action
   - Mention any open questions/blockers from the handoff note

   **Determine the active drive mode.** Take the first rung that applies:
   1. **`tour:` field present → the pointer's `drive_mode`, and stop.** A `tutorial-*` skill set that mode deliberately for its run, so letting anything below override it silently changes the mode mid-run. This rung outranks the Claudesk rung too. If a `tour:` pointer somehow has no `drive_mode`, treat that as a defect in the writing skill and say so rather than substituting a mode of your own.
   2. **Claudesk line present → that mode.** When Claudesk spawns the session, its hook puts this line into your context on every user turn:
      `Claudesk reports the drive mode for this workspace as <mode>.`
      Use the **most recent** such line, and only when `<mode>` is one of the wire strings `stepping` / `orchestrated` / `autopilot` / `fsd`. Ignore any other value and fall through. The line is the operator's **live** per-workspace setting, so it outranks the rungs below, which only record the mode at handoff time. Reading it for its value is not enough: **this rung decides the mode, and step 4b then presents no pick.**
   3. `drive_mode` from `.session.md` frontmatter (set at handoff time). **The value `from-claudesk` is not a mode.** It is the deferral marker `/session-handoff` writes under a Claudesk line, and it means "use the live Claudesk line". If the line is present, rung 2 has already decided. If it is absent (e.g. restoring in a bare terminal), skip this rung and go to rung 4. Never report the marker as a defect or as the mode.
   4. `drive_mode` from `state_file` frontmatter (fallback for older sessions).
   5. Default to `orchestrated` (Mode 2).

   **Incident override:** if the pointer's `workflow` is `incident`, the mode is `orchestrated` whatever rungs 2–5 found. Human judgment is non-negotiable during incidents.

   **Name the mode in the context summary**, e.g. "Restoring in **Autopilot** mode." When rung 2 decided it, say where it came from in the same one line: "Restoring in **Autopilot**, the mode Claudesk reports for this workspace." If that differs from the `drive_mode:` in `state_file`'s frontmatter, rewrite the field to the Claudesk mode (so `feature-verify-human` and the orchestrator read the live mode, not a stale one) and add it to the same line: "(the handoff recorded **Stepping**; `drive_mode:` updated)". Under the incident override, say both: "Claudesk reports **Autopilot**; incidents always run **Orchestrated**."
   **Exception — omit the mode entirely when the pointer carries a `tour:` field:** restore in that mode silently and name no mode at all, not even the one you are restoring in. The same reason step 4b skips the pick applies here: a `tutorial-*` run reveals the modes at its own scripted moment, and naming even one pre-empts it.

4b. **Offer a mode change** — *unless rung 1 (`tour:`) or rung 2 (Claudesk line) decided the mode.*

   **Skip this whole step when `tour:` is present.** Present no pick, and do not name the modes or list the gears
   at all: a `tutorial-*` run reveals them at a specific scripted moment, and showing them here pre-empts it.
   Restore silently in the pointer's mode and let the driving skill handle mode changes on its own schedule.
   Go straight to step 5.

   **Skip it too when the Claudesk line decided the mode** (rung 2), and under the incident override. The one line
   from step 4 is all the operator sees about the mode: no pick, no list of the other modes. The operator changes
   the mode in Claudesk's workspace header, not here. Go straight to step 5.

   Otherwise (a bare terminal), let the operator keep or switch modes with the **`AskUserQuestion`** tool: one
   question, header `Drive mode`, four options, the **current mode first** and labelled `<Mode> (current)` so
   keeping it is one click, then the other three in 1→4 order:

   | Label | Description |
   |---|---|
   | Stepping | Pause after every skill; I tell you the next command |
   | Orchestrated | Standard policy |
   | Autopilot | Only pause at verify-human |
   | FSD | No stops; verify-human skipped |

   **Fallback, when `AskUserQuestion` is not available** (a non-interactive `claude --print` run has no such tool):
   print the same choice as a numbered text list instead:

   ```
   Drive mode — press Enter to keep current, or pick a new one:
     1  Stepping      pause after every skill, I'll tell you the next command
     2  Orchestrated  standard policy
     3  Autopilot     only pause at verify-human
     4  FSD           no stops, verify-human skipped
   Current: <mode name>  [Enter = keep]
   ```

   - The current mode picked (or Enter / nothing typed) → keep it, no file changes needed.
   - A different mode picked → update the `drive_mode:` field in `state_file`'s YAML frontmatter to its wire string (`stepping` / `orchestrated` / `autopilot` / `fsd`) before handing off.

5. **Hand off.** Tell the user the exact skill to invoke to continue, e.g.: "Run `/feature-build` to continue where you left off." (This should match `resume_skill` from the pointer.)

6. **Backlog check.** Quickly scan `workflow-system/state/backlog.md` (if it exists) for any `high` priority items that relate to the current work. Mention them if found.

6b. **Strip the stale Handoff footer from `state_file`.** The `## Session Handoff — <timestamp>\nHanded off. See …` block that `/session-handoff` injected (per `session-handoff` SKILL.md §3) must be removed from the `state_file` body now — otherwise it lingers and accrues a cleanup tax at finalize/close time on every handed-off-then-restored item. Idempotent — no-op if the marker isn't there. Match pattern: the trailing `## Session Handoff — ` heading (or the legacy `## Session Pause — ` heading, for items handed off before the WP5 rename) + all following lines up to EOF (`/session-handoff` always appends to EOF). If a future `/session-handoff` variant inserts mid-document, extend the match to "until next `## ` heading or EOF." Edit `state_file` in place to remove the matched block.

7. **Clean up.** Delete `workflow-system/state/.session.md` now — its purpose is consumed. The next `/session-handoff` will recreate it if needed.
