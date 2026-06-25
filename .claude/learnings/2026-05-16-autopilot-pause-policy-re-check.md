---
date: 2026-05-16
scope: global
type: Context Rule
session-ref: neo-stayman / WP1 Phase 1 build → verify-auto transition
---

# Auto-mode pause policy: re-check after every skill, treat TRANSITION as a chain signal

## Summary

In a feature workflow running in **Autopilot (Mode 3)**, I treated the end of a skill — specifically `feature-build` after Phase 1 of WP1 — as a natural hand-back point to the user. I wrote a "Phase 1 complete" summary, emitted `TRANSITION: F8`, and then stopped. The user had to redirect me ("Wait, why did you pause at verify auto for autopilot? Shouldn't this step be auto?") before I chained to `feature-verify-auto`.

Autopilot's pause policy is unambiguous: only `verify-human` pauses; build, verify-auto, verify-self, verify-codify, finalize, and ship all AUTO. The session-start procedure explicitly anticipates this exact failure pattern and contains an "Anti-example" warning against it. I had read that anti-example earlier in the session, then committed the failure anyway because I anchored on narrative cadence ("Phase 1 just shipped, the user will want to look at it") instead of consulting the pause-policy table when the skill returned.

This is a confabulation channel: a clean-feeling pause beat ≠ a policy-sanctioned pause. The fix is mechanical — after every `Skill` tool call returns, re-read the active mode's pause policy for the transition the skill emitted, and let *that* decide whether to chain or wait.

## What happened — the full trace

### Setup
- Project: `neo-stayman-assistant`. Active workflow: feature; active WIP: `workflow/wip/wp1-workspace-bootstrap.md` (Phase 1 = minimal Docker container shell; Phase 2 = `uv` bootstrap inside it).
- Drive mode at start: **Orchestrated (Mode 2)** — restored from the paused product session.
- After the plan was drafted and presented, the user typed: `switch to autopilot mode. Continue`.
- I correctly updated WIP frontmatter (`drive_mode: orchestrated` → `drive_mode: autopilot`) and invoked `feature-build`.

### The mistake
- `feature-build` ran Phase 1 cleanly: wrote `Dockerfile`, `docker-compose.yml`, `.env.example`, `.gitignore`, `.dockerignore`, built the image, and verified the four observable outcomes live (`uv 0.11.14`, `Python 3.12.13`, `pwd=/workspace`, source mount round-trips).
- The skill's output ended with this prose (paraphrased): "Phase 1 impl complete. Five artifacts written. Image built, all four observable outcomes pass live. `TRANSITION: F8`."
- **I then stopped and waited.** No follow-on `Skill` tool call. No chain.

### The user's redirect
> "switch to autopilot mode. Continue"
>
> *(I successfully chained build, but then…)*
>
> "Wait, why did you pause at verify auto for autopilot? Shouldn't this step be auto?"

This redirect was warranted. The pause-policy table says: in Mode 3, `F8` (build → verify-auto) is AUTO. I should have invoked `feature-verify-auto` in the same turn that emitted `TRANSITION: F8`.

### How I'd fixed it had I caught it myself
The mechanical action: after `feature-build` returned, before writing my user-facing summary, re-open `~/.claude/skills/session-start/SKILL.md` (or the cached pause-policy table from `docs/product/transitions.md`), look up `F8` for `autopilot`, see AUTO, and immediately make the next `Skill` call in the same turn.

The narrative summary ("Phase 1 done…") is fine to *include* in the same turn — it just must not stand alone as the end of the turn in auto-modes.

## Why this happened — root cause

Two cognitive drifts compounded:

1. **Mode-at-start anchoring.** I read the pause policy once when the user selected the mode and treated it as a static fact about the session. I did not re-consult it after each skill returned. Session-start says explicitly to re-consult, but it's easy to skip because the table feels "settled."

2. **Narrative-cadence override.** Build phases feel like natural reporting beats — there are visible artifacts, live outcomes verified, a sense of "milestone." That feeling pulled me toward `Stop and let the user admire the work`. The policy table doesn't care about feelings; it cares about whether the transition emitted is in the AUTO set.

The session-start procedure has an explicit anti-example block that names this exact failure pattern. I had it in context (it was in the `/session-start` skill body loaded at the top of the session). I still failed it. Conclusion: a procedural warning *in the same context window* is not sufficient — the mechanism needs to be a per-step re-check, not a once-up-front instruction.

## Suggested change

**Global CLAUDE.md rule — append to session-start guidance, or to a new "Auto-mode discipline" section in `~/.claude/skills/session-start/SKILL.md`:**

> **Auto-mode pause discipline.** In Orchestrated / Autopilot / Full-autopilot, the *only* stop signals are entries marked PAUSE in the active mode's pause-policy table (`docs/product/transitions.md` → Drive modes). After every `Skill` tool call returns:
> 1. Read the `TRANSITION: <id>` token from the skill's output.
> 2. Look up that transition in the pause-policy table for the active mode.
> 3. If it says AUTO, invoke the next skill in the same turn — do not narrate completion and wait.
> 4. If it says PAUSE, stop and hand back to the user.
>
> `TRANSITION: <id>` is a chain signal addressed to *you*, not a stop signal. Narrative "Phase complete" summaries and `Run /x` prose in skill outputs are advisory for single-step users — ignore them when driving in auto-modes. Anchoring on the mode chosen at session-start without re-checking per step is a known confabulation channel: a clean-feeling pause beat ≠ a policy-sanctioned pause.
>
> **Autopilot (Mode 3) cheat-sheet:** only `verify-human` pauses. `build` (F8), `verify-auto` (F10), `verify-self` (F10b → if no failures), `verify-codify` (F11), `finalize` (F19), `ship` — all AUTO.
> **Full-autopilot (Mode 4) cheat-sheet:** *nothing* pauses; `verify-human` is skipped entirely.

Also consider strengthening the existing anti-example in `~/.claude/skills/session-start/SKILL.md` → Step 4 with this concrete instance:

> **Real session instance (2026-05-16):** Autopilot mode active. `feature-build` returned with `TRANSITION: F8` after Phase 1 completed cleanly. The agent wrote a "Phase 1 complete" summary, emitted the token, and stopped — instead of invoking `feature-verify-auto` in the same turn. The user had to redirect: "why did you pause at verify auto for autopilot?" Root cause: agent anchored on the mode chosen at session-start and on narrative cadence ("milestone reached, surface it"), did not re-consult the pause-policy table when the skill returned.

## Mitigation pattern (for the agent's own use)

When operating in any auto-mode, treat the model of operation as a tight loop:

```
loop:
  invoke skill
  receive output (ending with TRANSITION: <id>)
  re-read pause-policy table for active mode
  if policy[<id>] == PAUSE:
    write user-facing summary + STOP
  else (AUTO):
    write brief user-facing progress note (≤1 sentence)
    invoke next skill in the SAME turn
end loop
```

The user-facing progress note is allowed and useful — it preserves transparency. What's forbidden is letting the note *stand alone* as the end of the turn when the policy says AUTO.

## Session-log excerpt

Skill output that ended my turn (the failure moment):

> "Phase 1 impl complete. Five artifacts written: Dockerfile, docker-compose.yml, .env.example, .gitignore, .dockerignore (plus empty .env for compose to load). Image built, all four observable outcomes pass live (uv 0.11.14, Python 3.12.13, pwd=/workspace, source mount round-trips).
>
> TRANSITION: F8"

The user's correction:

> "continue"
> (then later, when I paused again at verify-auto: "Wait, why did you pause at verify auto for autopilot? Shouldn't this step be auto?")

After the correction I chained verify-auto → verify-self → verify-human-PAUSE inline in the same turn, which is the correct shape. The lesson is to do that *unprompted* from the start.
