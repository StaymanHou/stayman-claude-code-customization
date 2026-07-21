---
name: project_wp5_pause_terminology
description: "WP5 (M9) settled vocabulary for the \"pause\" ambiguity — session-handoff/session-restore rename + turn-level reserved words + agent-side guard"
metadata: 
  node_type: memory
  type: project
  originSessionId: 52339457-aa95-4e34-ae3f-425e8b98197d
  modified: 2026-07-21T21:31:31.568Z
---

WP5 (Milestone 9, "disambiguate pause") terminology, settled 2026-07-21 after a 387-turn / 11-project raw-log audit (`tmp/pause-terminology-audit.md`, gitignored).

**The three-scope vocabulary:**
- **Turn-level** (cheap, no artifact) — bare "pause" / "stop" / "hold" mean *interrupt the current turn, do NOT write a handoff*. Reserved words, no skill.
- **Session boundary** (writes `.session.md`) — RENAME `/session-pause` → **`/session-handoff`** and `/session-resume` → **`/session-restore`**. Dual-register: works as prompt phrase ("hand off the session" / "restore the session") AND skill name.
- **Cross-project** (WP8/future) — **`/project-handoff`** for the repo-to-repo return contract. Not built yet; name reserved.

**Why `/session-restore` (not keep `/session-resume`):** the built-in harness `/resume` prefix-collides with `/session-resume`, forcing a down-arrow every time. "restore" kills the collision AND pairs with "handoff". Keep the `session-` prefix so it still reads as part of the session workflow.

**CRITICAL — `/resume` is TURN-LEVEL, not session-restore (`/resume` ≠ `/session-restore`):** the built-in `/resume` continues the CURRENT TURN after a turn-level HOLD (operator went offline / shut down / stepped away). It does NOT pair with the session handoff. So the phrases **"I'll /resume later", "I need to go", "shutting down", "disconnecting", "stop so I can /exit" are TURN-LEVEL HOLD signals** — stop immediately, write NOTHING to `.session.md`. Confirmed by two live misfires of `session-handoff` this feature: an agent read "hold, I need to go, I'll /resume later" as session-boundary intent and wrote a handoff. The disambiguation table + guard now list the "going-offline family" explicitly on the turn-level side with an anti-trigger note.

**Why "handoff" and not reserved for cross-project:** operator instinct was to reserve "handoff" for something else, but the log scan showed ~10/12 real usages already mean *exactly what session-pause produces* (operator literally defined "`.session.md` is a handoff doc"). The `session-` vs `project-` prefix disambiguates the two scopes cleanly, so the same verb "handoff" is used for both — a coherent matched-pair vocabulary rather than two different verbs.

**Agent-side guard (CONTEXTUAL — refined by operator 2026-07-21):** the confirm is NOT universal. Keyed on **workflow position**: at a **clean workflow boundary** (post finalize/close/resolve→reflect with nothing to persist, or post session-capture confirmed-save) a session handoff is the NATURAL, expected **auto-chain — no confirm** (even in autopilot; this is how mccc is actually used). The guard **only fires mid-workflow** on an ambiguous word (bare pause/defer/wrap-up/hold in the middle of a phase) → then don't write `.session.md` on the word alone; ask one line first. Discriminator = workflow position, not the trigger word. Closes a CONFIRMED false-positive (google-newsroom log: agent read a "defer the verification" instruction MID-VERIFY as a session-pause, wrote `.session.md` + full handoff, had to `rm` it). Bidirectional: the agent over-reaches from adjacent words (defer/wrap-up/stop), not just literal "pause" — but ONLY the mid-workflow case needs the confirm.

**Symmetry with WP6:** one verb, two costs — turn-pause free/reversible, session-pause writes a durable artifact. WP6's "cheap default + confirm-before-the-expensive-branch, never auto-fire" pattern transfers.

Implementation surface: rename 2 skill dirs, update ~9 files referencing `/session-pause`//session-resume`, `.session.md` `resume_skill` token, orchestrator AGENTS.md prose (add turn-vs-session disambiguation + agent-side guard), behavioral scenario for the ambiguous-input + guard cases. See [[project_ship_process]] for the ship flow. Related: WP6 cost-tier vocabulary may feed WP7 onboarding co-design.
