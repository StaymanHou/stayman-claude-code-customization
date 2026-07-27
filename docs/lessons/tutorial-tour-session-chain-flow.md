# Tutorial tour — the session-chain flow (AUTHORITATIVE)

**Read this before touching any `tutorial-*` skill.** This is the operator-specified
experience flow for the M11 onboarding tour. It was specified in the raw session log
(session `fd4a9b17`, 2026-07-22, human turns 49–55) and is the source of truth — the
`onboarding-flow-spec.md` and the three `tutorial-*/SKILL.md` files must conform to it,
not the other way around.

Origin quote (operator, verbatim):

> "Also do you still have the context of the flow? getting-started, exit the session,
> new session, `***-tour` skill, walkthrough, handoff, exit session, new session,
> restore, graduate, clean up, exit session, new session, `***-tour`, autopilot/fsd
> mode, go through whole thing again."

## The flow is a CHAIN OF SESSION BOUNDARIES — not one continuous session

The whole pedagogical point is that the user *actually crosses real session boundaries*
(`/exit` → new session), because that is how the tour teaches handoff→restore: by making
the user do it for real, not by narrating it.

| # | Session | What the user runs | Drive mode | Ends with |
|---|---------|--------------------|------------|-----------|
| A | Session A | `/tutorial-getting-started` — recommends `auto` permission mode; asks new-project vs. existing-code; **`cd`s the user to the target dir** (a new dir for greenfield, or their existing repo for brownfield); **points the user to the right `***-tour` skill**; tells them to `/exit` | (sets up only — does NOT drive the tour) | user `cd`s + `/exit` |
| B | **new session** | user runs the `***-tour` skill **DIRECTLY** (`/tutorial-greenfield-workflow-tour` or `/tutorial-brownfield-workflow-tour`) → walkthrough → `/session-handoff` | **stepping** (modes NEVER mentioned) | `/session-handoff` → `/exit` |
| C | **new session** | user runs `/session-restore`, which **hands control back to the ARM** (the Step-7 pointer set `resume_skill` to the arm, not to the inner workflow's next state); the arm drives any remaining inner-workflow states itself, then plays graduation (Step-8 reveal) → clean up | stepping (restored **from the pointer**, and the 1–4 menu is suppressed) | `/exit` |
| D | **new session** | user runs the `***-tour` skill **DIRECTLY** again → this time in **autopilot/FSD** → goes through the whole thing again | **autopilot/FSD** | (replay complete) |

## The load-bearing invariants (do NOT regress)

1. **getting-started NEVER dispatches the arm skill inline.** It is a *pointer/setup* step,
   not a driver. It recommends the permission mode, asks the fork, `cd`s the user to the
   target directory, points them at the correct `***-tour` skill, and tells them to `/exit`
   and start a new session. The historical "dispatches inline to the arm" language (in the
   old spec §2/§4/§5 and the dispatcher's Step 3) is **WRONG against this flow** and must be
   corrected.

2. **The arm skill is ALWAYS entered directly, in its own session.** There is no
   "dispatched vs. direct" fork — the arm is *only ever* run directly by the user. The only
   distinction is **first run vs. replay**, and both are direct entries (just in different
   drive modes).

3. **Session A must `cd` the user to the target directory before `/exit`.** New dir for
   greenfield; the user's existing repo for brownfield. This is what makes the new session
   (B) start in the right working directory. (Operator addition, 2026-07-22.)

4. **First run vs. replay discriminator = the arm asks ONE line on entry.** On entry the arm
   skill asks: *"First time through, or replaying to try a faster gear?"*
   - **First run** → default to **stepping**, and **NEVER mention that drive modes exist**
     until the Step-8 graduation reveal (revealing them early would spoil beat B — the
     visible human pause the whole tour is built around).
   - **Replay** → present the standard **1–4 drive-mode menu** (same shape as
     `/session-start`) and let the user pick autopilot/FSD.
   (Chosen over disk-state / marker-file discriminators for robustness — the tour is a
   deliberate narrated experience, so one question fits. Operator decision, 2026-07-22.)

5. **Greenfield: the AGENT auto-stamps the fresh sample — the human NEVER runs
   `new-sample.sh`.** On both first run and replay, the arm skill stamps the throwaway
   sample itself. Brownfield: the user `git stash`/restores to the clean baseline first
   (undo the tour's real-repo edits) — which is why the Step-0 git-safety pre-flight is
   load-bearing.

6. **The replay is a session-boundary crossing** (`/exit` → new session), re-entering at the
   **arm skill directly**, NOT the dispatcher (the dispatcher would re-force stepping +
   re-ask the fork, both of which a faster-gear replay is moving past).

7. **The tour's state is written to DISK, not held in the conversation** (WP7o, 2026-07-27).
   The Step-7 handoff writes `tour: greenfield|brownfield` + `tour_step: <n>` into
   `workflow-system/state/.session.md` (optional fields, tour-only), and sets
   **`resume_skill` to the arm skill** so Session C comes back to the arm rather than to the
   inner workflow's next state. That is what makes Session C **one thread** — the arm finishes
   the in-tour work and then graduates. Pointing `resume_skill` at the inner workflow instead
   leaves the next session holding two competing continuations, which is exactly the defect
   the 2026-07-27 run hit. The arms also stamp `tour:` into the in-tour **WIP** frontmatter,
   because `/session-restore` deletes the pointer once consumed.

8. **A first run RECORDS its drive mode silently — recording is not revealing** (WP7o).
   The first-run branch writes `drive_mode: stepping` to the tour WIP even though it must
   never *say* the word. The mode has to survive the Step-7 boundary: unwritten, restore falls
   through to its own default and Session C silently continues in a different mode *while
   announcing it* — which both breaks the tour's cadence and spoils invariant 4's
   modes-hidden-until-graduation rule one step early. On a `tour:` pointer, `/session-restore`
   takes the mode from the pointer and **suppresses the 1–4 menu entirely** (it names no mode
   at all), leaving the reveal to Step 8 where it belongs.

## Mode-switching, explained for the user

Drive mode is **not a slash command** the user types — it is a **numbered menu the workflow
presents** (`1 Stepping / 2 Orchestrated / 3 Autopilot / 4 FSD`; type 1–4 or Enter for the
default). The two canonical places it is presented are `/session-start` (new work) and
`/session-restore` (on restore). Because the tour's replay path enters the arm skill
directly (bypassing both), **the arm skill itself must present that menu on the replay run**
(invariant 4). The first run never shows it (modes stay hidden until graduation).

## Why this doc exists

An agent (this one, 2026-07-23) re-derived the flow from scratch instead of reading the
origin session log, got the premise backwards (assumed getting-started dispatches the arm
inline), and burned operator patience. The standing rule — *read the origin session's raw
log before planning session-spawned work* (`~/.claude/CLAUDE.md` → last convention bullet) —
applies here. This doc is the compression so future sessions don't have to re-mine the log:
**start here, then verify against the current SKILL.md files.**
