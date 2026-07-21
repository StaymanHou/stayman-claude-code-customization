---
name: session-handoff
description: Hand off the current workflow session — writes a resumable handoff pointer to workflow-system/state/.session.md so a future session can pick the work back up. NOT a turn-level interrupt (bare "pause"/"stop"/"hold" mean course-correct the current turn, no handoff). Never write the handoff on ambiguous intent without confirming.
argument-hint: <optional notes about current status>
---

# Session Handoff

Hand off the current workflow state — write a resumable handoff pointer so a future session can `/session-restore` it.

## Intent disambiguation (READ FIRST — turn-level vs session boundary)

"Pause" is overloaded. This skill is the **session-boundary handoff** — it writes a durable artifact (`workflow-system/state/.session.md`) and a full handoff, which is expensive and *wrong* when the operator only meant "stop for a moment." Two distinct intents:

| Operator intent | Words they use | Correct response |
|---|---|---|
| **Turn-level** (cheap, no artifact) — interrupt / course-correct the current work right now, keep the session live | bare **"pause"**, **"stop"**, **"hold"**, "pause the turn", "pause your task", "hold the turn", "stop for a moment", "pause now"; **AND the going-offline family: "I need to go", "I'll `/resume` later", "hold, I'm shutting down / disconnecting / turning off the machine", "stop so I can `/exit`"** | **Do NOT invoke this skill.** Just stop **immediately** so the operator can safely `/exit`. Write **nothing** to `.session.md`. The operator will `/resume` (the built-in, which pairs with turn-level HOLD) to continue *this same turn* when back online. |
| **Session boundary** (expensive, writes handoff) — we're done for now, save a handoff so a *future* session can restore it | **"hand off the session"**, "session handoff", **"pause the session"**, "pause here, <X> next session", "wrap up and pause", explicit `/session-handoff` | Invoke this skill — write `.session.md` + the handoff. Resume next session with `/session-restore`. |

> **`/resume` vs `/session-restore` — do not conflate (this is the exact misfire this skill guards against).** `/resume` is the **built-in** that continues the *current turn* after a turn-level HOLD (operator stepped away / went offline). `/session-restore` is **this system's** IN skill that restores a *written handoff* across sessions. So **"I'll /resume later" is a TURN-LEVEL signal — it means HOLD, NOT hand off.** Treating "resume later / going offline" as session-boundary intent and writing `.session.md` is a false-positive misfire (it happened: an agent wrote a handoff when the operator only wanted to disconnect and continue the turn later).

**Agent-side guard (context-dependent — the confirm is NOT universal).** Whether to write `workflow-system/state/.session.md` depends on *where in the workflow you are*:

- **At a clean workflow boundary — auto-chain, no confirm.** A session handoff is the *natural, expected* next step once the current work has reached a terminal boundary: after `feature-finalize`/`task-close`/`incident-resolve`/`product-finalize` → `session-reflect` with **nothing to persist**, or after `session-capture` once a learning is **confirmed-saved**. At these points the session is genuinely done and the operator expects the handoff to just happen — writing `.session.md` here is correct and needs no "are you sure?". (This is how the mccc workflow is used in practice: the boundary handoff is almost always the right auto-chain.)
- **Mid-workflow or on an ambiguous word — DO fire the guard.** The confirm exists for the *mid-flight* case: the operator says bare **"pause"**, **"defer"**, **"wrap up"**, **"hold"** in the *middle* of a phase, where it's genuinely unclear whether they mean a turn-level interrupt or a session boundary. There, do **not** write `.session.md` on the ambiguous word alone — **ask one line** ("Turn-level hold, or write a session handoff for next time?") before writing. The failure mode is bidirectional and mid-workflow: an adjacent instruction like "defer that check" can pull you toward a handoff no one asked for (a real misfire: an agent read "defer" mid-verify as a session handoff, wrote `.session.md`, and had to `rm` it after correction).
  - **Anti-trigger — "I'll `/resume` later / I need to go / shutting down" is NOT a handoff cue.** These read *superficially* like session-boundary intent ("later" implies a future session) but are **turn-level HOLD**: the operator wants you to stop NOW so they can safely `/exit` / go offline, then `/resume` the *same turn*. Do **not** write `.session.md` on them — just stop. (This is the second confirmed misfire of this exact skill: an agent read "hold, I need to go, I'll /resume later" as a session boundary and wrote a handoff. If genuinely unsure whether the operator wants a cross-session handoff too, ask — but default to HOLD.)

The discriminator is **workflow position**, not the trigger word: terminal boundary → handoff is natural (chain it, even in autopilot); mid-workflow ambiguity → confirm before writing.

## Valid transitions

When you finish, label your output with this ID:

- **S17** — `.session.md` written (with `drive_mode:` if present in WIP frontmatter), state-file annotated, user told to use `/session-restore`

**Steps:**

1. **Identify the active work.** Determine the current workflow and step (e.g., `feature:build`, `task:act`, `product:roadmap`). Check recent conversation context plus:
   - `workflow-system/state/wip/` for feature/task/incident WIP files
   - `workflow-system/product/` for product docs whose frontmatter shows `state: in-progress`

   If multiple active items exist, ask the user which one to pause.

2. **Write `workflow-system/state/.session.md`** — this is a single-file session pointer (one active session per repo). Overwrite it each time:

   Before writing, read the active WIP file's YAML frontmatter. If it contains a `drive_mode:` field, include it in the session pointer. If no `drive_mode` is present, omit the field entirely (do not default it).

```markdown
---
paused: <YYYY-MM-DD HH:MM>
workflow: <product|feature|task|incident>
step: <current step name>
resume_skill: /<workflow>-<step>
state_file: <path to the active state file, e.g. workflow-system/state/wip/<feature>.md or workflow-system/product/roadmap.md>
drive_mode: <stepping|orchestrated|autopilot|fsd>  # omit if WIP has no drive_mode
---

# Session Handoff

- **Last completed:** <what was just finished>
- **Next action:** <the very first thing to do when resuming>
- **Open questions/blockers:** <any unresolved issues, or "None">
- **Notes:** <any temporary context worth preserving>
```

3. **Annotate the state file.** Append a short marker to the file referenced in `state_file:` so the context is visible when someone opens that file directly:

```markdown
## Session Handoff — <YYYY-MM-DD HH:MM>
Handed off. See `workflow-system/state/.session.md` to restore.
```

4. **Confirm** to the user:
   - The restore command (always `/session-restore`)
   - A one-liner of what they'll pick up on

**Additional context from user:** {{args}}
