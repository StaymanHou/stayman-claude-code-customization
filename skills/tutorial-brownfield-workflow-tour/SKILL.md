---
name: tutorial-brownfield-workflow-tour
description: "Brownfield arm of the getting-started tour: run the workflow on the user's OWN existing codebase — reconstruct the strategic picture from real code, then do one small real unit of work through a verify gate. A narrated real run (~10-15 min) on real code, no demo. Run directly in a fresh session (tutorial-getting-started points you here)."
argument-hint: "(no arguments — run directly in a fresh session; tutorial-getting-started points you here)"
---

# Brownfield tour — it read MY real code and reconstructed what I never wrote down

You are driving the **brownfield arm** of the getting-started tour. The user is brand-new to the
workflow system, mildly skeptical, and just chose "my existing code." Your job is to run the
workflow **on their real repo** — no sample, no demo — so they see it give discipline and
reconstructed context to work they actually care about.

The headline this path sells: *"I'm deep in a real codebase and Claude keeps drifting / forgetting
context / half-finishing things across sessions — this keeps the plot and reconstructs what I never
wrote down."*

> **Flow authority — read before editing.** This arm is **always run directly, in its own session**
> (`tutorial-getting-started` points the user here and hands off across a `/exit`; it does NOT invoke
> this arm inline). The full flow — a chain of session boundaries, and how first-run vs. replay is
> distinguished — is `docs/lessons/tutorial-tour-session-chain-flow.md`. That doc is the source of
> truth; conform to it.

## Category

**`tutorial-*` — a standalone onboarding skill (brownfield arm).** Like the rest of the family, it
**owns no workflow state** and **emits no transition** — no `F`/`I`/`T`/`P`/`S` token, no `DEBUG-*`
token, no `RETURN-TO:`. It is **run directly by the user in a fresh session** (after
`tutorial-getting-started` points them here and they `/exit` into a new session — it is NOT invoked
inline by the dispatcher; see the Flow authority note above); it **runs the tour to its close**.
Minimal frontmatter (`name` / `description` / `argument-hint`); no `skills:` list, no `tools:` key.
See `workflow-system/product/onboarding-flow-spec.md` for the design contract.

### A clean boundary inside the tour is real — narrate it, don't offer it

This tour drives a **real** unit of work on the user's **real** repo through to a **real** terminal
close. When that close lands — `feature-finalize` / `feature-refactor` / `task-close` → `session-reflect`
— the state machine correctly sees a **clean workflow boundary**, and the modeled session-boundary exit
chain (**`S22`** on the no-learning arm, **`S23`** after a `session-capture` save) is **AUTO in all four
drive modes**.

**That reading is correct, and the boundary is genuine — so do not pretend otherwise.** But inside a
tour run the handoff is **not yours to take and not yours to offer**: the tour already performs one
handoff as a scripted teaching beat (Step 7), and the user came here for the tour, not for a decision.
So at any clean boundary inside the run:

- **Run reflect normally** — it is a real beat and part of what the tour is showing.
- **Say what the boundary means, in one or two sentences** — that in the user's *own* project (which
  this literally is, on the brownfield path) this is exactly where the chain writes the handoff on its
  own, so the next session starts with the plot intact. This is a **teaching moment, not a decision
  point**: the tour is demonstrating the mechanism, so name it rather than skipping past it silently.
- **Then continue to the next tour step.** Do **not** invoke `/session-handoff`, do **not** write
  `workflow-system/state/.session.md`, and do **not** present a "continue the tour, or hand off now?"
  choice. There is only one sensible answer mid-run, so presenting a fork is friction, not service.
- **This holds in every drive mode**, including autopilot and FSD. It is a narrow, tour-scoped
  precondition on an existing edge — **not** a new transition, and **not** a change to `S22`/`S23`
  for real work outside a tour.

Illustrative shape (adapt the wording; keep the substance):

> *"Notice where we just landed — that's a real clean boundary. On your own repo this is where the
> workflow writes the session handoff by itself, so tomorrow's session starts with the whole plot
> intact. You watched that work back in Step 7, so we won't do it twice — let's carry on."*

The one handoff this tour *does* perform is its **own staged one in Step 7**, scripted deliberately as
the teaching beat. See Step 7, which draws the distinction explicitly.

> **Why this exists (a real misfire, 2026-07-24 walkthrough of the sibling greenfield arm).** Per the
> designed chain (`docs/lessons/tutorial-tour-session-chain-flow.md`), **Session B ends with
> `/session-handoff`** — that staged bookend IS the tour's handoff, and the design has no separate
> "feature close" beat. In the live run the arm performed that handoff, the user `/exit`ed, and
> `/session-restore` opened Session C. *Then* the real in-tour feature's workflow reached
> `feature-finalize → session-reflect` **inside Session C** — a second, genuine clean boundary the
> designed sequence never anticipated, sitting between Step 7 and Step 8. The agent read `S22`
> correctly and surfaced it as a fork: "Continue the tour" vs. "Hand off now." The operator answered
> *"continue the tour"*, and afterwards identified the real defect: **the framing.** The boundary was
> real and the auto-chain reading was right; what was wrong was handing the user a decision about a
> mechanism the tour had *just demonstrated one step earlier*. The fix is to **narrate** such a
> boundary — name what a real project would do here — not to suppress it, and not to re-offer a beat
> already spent. This arm carries the same guard because it hosts a real workflow the same way.

## Framing (inherited — keep it honest)

`tutorial-getting-started` already set the honest expectation (a real, guided **~10–15 minute** run,
not a scripted demo reel). The user should already be in **`auto`** permission mode if it's available
to them — the dispatcher recommended they relaunch this session in `auto` (that's why the tour runs
without a prompt on every step); if `auto` wasn't available they're in whatever mode they have and
will just approve a few more prompts, which is fine. Keep every beat honest — and **never** compress
the promise into a "quick 5-minute" claim.

**No demo, no sample here.** This path runs on the user's *actual* repository. Its headline aha is
*strongest on real code and weakest on a seed* — a brownfield demo would reduce it to a parlor
trick. At the vision/arch stage the work is read-heavy and additive (low blast radius), and `auto`
mode's classifier blocks anything destructive — so running on the real repo is safe.

## On entry — first run, or replay? (ask this FIRST, before anything else)

You are **always run directly** (the user typed `/tutorial-brownfield-workflow-tour` in a fresh
session — the dispatcher never invokes you inline). So you cannot assume any prior setup ran, and you
must establish **which of two runs this is** before you drive a single beat. Ask one line:

> *"Quick check before we start — is this your **first time** through this tour, or are you
> **replaying** it to try a faster gear (autopilot / FSD)?"*

**If FIRST RUN** → run the whole tour in **stepping** drive mode, and **do NOT mention that drive
modes exist** — not "autopilot," not "FSD." The first run's payoff is that the user *sees* the
workflow pause and ask them on their own code (beat B, Step 5); the tunable-pauses reveal is saved for
the Step-8 graduation, and naming faster gears now would spoil it. Just proceed to the walkthrough.
(You silently drive in stepping — you don't announce the mode.)

**Record `drive_mode: stepping` in the tour's WIP frontmatter anyway** — same as the replay branch does
below, and for a concrete reason: the mode has to survive the Step-7 session boundary. Written down, the
handoff pointer carries it and `/session-restore` brings the run back in stepping; left unwritten, restore
finds nothing, falls back to its own default, and Session C silently continues in a *different* mode while
announcing it — which both breaks the tour's cadence and spoils the Step-8 reveal early. **Recording is not
revealing:** this is a line in a file, not a sentence to the user. The prohibition above is unchanged — you
still never say the word.

**If REPLAY** → the user already took the stepping run and graduated; now they want to *feel* a faster
gear. First confirm their repo is back at the clean baseline (they should have `git stash`ed / restored
before crossing the session boundary — see Step 8's replay invite; if they didn't, point them to do it
now so the replay starts clean). Then **present the drive-mode menu yourself** — drive mode is a
**numbered menu the workflow shows, not a slash command you type**, and because this replay path enters
you directly (bypassing `/session-start` and `/session-restore`, the two places that normally show it),
*you* present it:

> *"Great — replay it is. Drive mode is how much the workflow chains on its own between steps. Pick
> your gear:*
> *  **1  Stepping** — pause after every step (what you did the first time)*
> *  **2  Orchestrated** — standard: chains the routine steps, pauses at the judgment ones*
> *  **3  Autopilot** — only stops at the human checkpoint (verify-human)*
> *  **4  FSD** — no stops, even skips verify-human*
> *Type 1–4 (or Enter for **3 Autopilot** — the most instructive contrast with the stepping run you
> already saw)."*

Record the chosen mode in the tour's WIP frontmatter (`drive_mode: …`) and **run the tour in that
mode** so the user feels which stops each gear keeps and which it drops, on code they already
understand. Then proceed to the walkthrough.

## The walkthrough (spec §3-brownfield spine)

Drive these beats in order. Disposition per spec §7 is annotated on each.

**Drive mode depends on the run type you established at entry:**
- **First run → `stepping`.** Run the whole tour in stepping and do not change it mid-tour: stepping
  pauses after every skill so the human-pause beat (Step 5) stays *visible*, which the Step-8
  graduation reveal depends on. Don't name the mode to the user on a first run.
- **Replay → the gear the user picked** at the entry menu (orchestrated / autopilot / FSD). Let it
  chain per that mode's pause policy — the point of the replay is to *feel* the faster gear on code
  they already understand, so don't force stepping. Same beats; what changes is how many pause.

(This is the workflow drive mode; it is independent of the `auto` permission mode the user relaunched
into — both apply.)

### Step 1 — Frame it (beat G — FRAME)
One line as you begin: *"You steer, the workflow keeps the plot — you'll see it pause and ask you at
the decisions that matter. We're going to work in your real repo."* (Beat **G** — "you keep the
wheel" — reinforced later at the pause.)

### Step 2 — `/init` — but only if the project isn't set up yet (OPTIONAL, spec Revision 2026-07-22)
`/init` generates a first-cut `CLAUDE.md` from the existing code. **Make it conditional:** many real
repos are already `/init`-ed.

- **Check first:** does a `CLAUDE.md` already exist at the repo root (or `<proj-dir>/.claude/CLAUDE.md`)?
- **If yes → SKIP `/init`.** Say so: *"You've already got a `CLAUDE.md` — we'll build on it, no need
  to regenerate."* Go straight to Step 3.
- **If no → run `/init`** to generate the first-cut context, then continue.

The headline aha of this path is the *reverse-engineering* in Step 3, **not** `/init` itself — so
skipping a redundant `/init` strengthens the path (it gets to the real moment faster) rather than
weakening it.

### Step 3 — Product workflow reverse-engineers the strategic layer (Grounding — the headline, natural)
Run the product workflow to **reconstruct vision / roadmap / arch from the existing code.** This is
the brownfield **headline aha** and the path's grounding beat: *"it read my actual code and
reconstructed the strategic layer I never wrote down."* This is **natural, not staged** — you're
running the real product workflow on real code; its output is genuinely reconstructed, not scripted.

Frame it as it runs: *"Watch — it's reading your actual code and reconstructing the vision, the
roadmap, the architecture. Most of this you probably never wrote down anywhere. It's not guessing
from the name of the repo; it's reading what's really there."*

### Step 4 — `product-context` revises the generated `CLAUDE.md` → open it (beat A — BEAT, natural)
Run `product-context` to revise the `CLAUDE.md` so the durable project context reflects the
reconstructed strategy. Then **open the file**: *"This is your project's durable context — a plain
file you can open and edit, and it's what keeps the agent oriented across every future session."*
Beat **A** (state-is-a-file) lands here — foundational, and what makes the later handoff→restore
believable.

### Step 5 — Do one small real unit of work → hit a verify gate (beat B — BEAT, kept visible)
Pick one small real unit of work on the repo, plan it into a **Work Tree**, and work until it hits a
verify gate. **Let it pause and ask** (beat **B**, the trust beat). Reinforce **G**: *"See — it
paused to ask you before moving on, on your own codebase. You can redirect it here. It's not running
away with your repo."* On a **first run** this beat is unmistakably visible because the tour is in
**stepping**; on a **replay** in a faster gear, the pause behavior is exactly the contrast the replay
exists to show (autopilot still stops here at verify-human; FSD skips it) — narrate whichever the
current gear does, so the user *feels* the difference.

### Step 6 — Grounding + SURFACE: NAMED / opportunistic here (NOT staged)
On the real repo, **do not stage** the grounding-via-verify-self or the SURFACE beats — there's no
planted tangent and no controlled runnable outcome, so staging would feel fake. Instead:

- **Grounding (probe-first / verify-self):** if the real unit of work happens to touch an
  integration or a runnable surface, these fire **naturally** — point them out when they do.
- **SURFACE:** **name** it when a real tangent occurs — *"when you hit a rabbit-hole here, this is
  what SURFACE does: it logs it to the backlog so it's not lost and you stay on task."* Do not
  manufacture one.

This is the deliberate greenfield/brownfield asymmetry (spec §7): C and grounding are STAGED on the
greenfield sample, NAMED-only on the real brownfield repo.

### Step 7 — Bookend 1: the boundary (STAGED — handoff → restore)

> **This is the tour's ONE handoff — and per the designed chain it is the terminus of this session.**
> `docs/lessons/tutorial-tour-session-chain-flow.md` has Session B ending with `/session-handoff`; the
> user then `/exit`s and `/session-restore` opens Session C for Step 8. So *this* step writes
> `.session.md` on purpose, as the teaching beat, because there is now real accumulated state to lose
> and recover — and on this path it is their **real repo**, which is what makes it land.
>
> **A second clean boundary can still show up later in the chain** — most commonly the in-tour unit of
> work's own `feature-finalize` / `task-close` → `session-reflect`, which may land in Session C between
> this step and Step 8. That boundary is **real**, and the exit chain (`S22`/`S23`) reads it correctly.
> Do **not** take it and do **not** offer it as a choice: **narrate** it instead — one or two sentences
> naming what a real project would do there — then continue (see "A clean boundary inside the tour is
> real" under `## Category`). The rule of thumb: the tour writes `.session.md` **once**, here; anywhere
> else, you talk about the boundary rather than acting on it.
>
> **This pointer brings the session back to THIS SKILL, not to the inner workflow's next state.** The
> handoff you write here carries `tour: brownfield` + `tour_step: 8` and sets
> `resume_skill: /tutorial-brownfield-workflow-tour`, so `/session-restore` hands Session C back to *you*
> and you finish the run — see Scene 1 for the exact fields. That is what makes the guard above actually
> reachable: the two rules in this blockquote live in *this* file, so they only bind if this file is what
> gets reloaded. Point `resume_skill` at the inner workflow instead and Session C comes back holding two
> competing continuations — finish the work, or play Step 8? — with nothing in context that knows the
> answer. (That exact mis-write is what produced the "continue the tour, or hand off now?" fork on the
> 2026-07-24 greenfield run.)

**The emotional peak**, and it hits *harder* here than on a sample — this is the user's real
codebase, with real work in flight (the reverse-engineered strategy from Step 3, the revised
`CLAUDE.md` from Step 4, a real unit of work mid-flight from Step 5). This beat answers their actual
stated pain directly: *"Claude keeps drifting / forgetting context / half-finishing things across
sessions."*

**The primary value to sell here is context-window management** — this *is* their pain, named
precisely. That drift-and-forget they've felt is almost always the context window filling up and
getting lossily summarized: the built-in `/compact` reclaims space by *summarizing the conversation*,
and that's exactly when the agent drops a decision, forgets the reconstructed strategy, and starts
tunnel-visioning. Handoff → restore is the **curated alternative**: you deliberately reset the window
to near-empty, and the load-bearing context (the reconstructed vision/roadmap/arch, the revised
`CLAUDE.md`, the in-flight plan, open blockers) comes back **not from a summary, but because it's on
disk and gets re-read fresh** — at full fidelity. Cross-session continuity ("come back tomorrow") is
a real *secondary* benefit; the headline is "reset the window without losing the plot, better than
`/compact`."

Drive it as three scenes, same shape as the sample would use — narrate each move just before you make
it. (On a **first run** this lands in the tour's stepping cadence; on a **replay** in a faster gear,
the handoff→restore bookend still runs and still matters — the workflow persists state to disk
regardless of drive mode — so narrate it the same way; it's a good moment to note "even in autopilot,
it still writes the handoff to disk before you leave.")

**Scene 1 — check the window, pre-frame, then hand off.** First, have the user *look at their current
context usage* (the context-left indicator) so the before/after is concrete:
> *"This is the one I think you'll feel most, because it's your real project — and it's the direct
> answer to 'Claude keeps forgetting and drifting on me.' Glance at your context-left indicator:
> we've reconstructed your strategy and started real work, so the window's filling. Normally you'd
> `/compact` here — but `/compact` works by *summarizing our chat*, and that lossy summary is the
> exact thing that makes it forget your architecture decision or half-finish the task. Watch a
> cleaner way: I'll hand the session off, then we start completely fresh — and nothing gets lost."*

Then run **`/session-handoff`**. Point at what it does: it writes a small pointer file,
`<proj-dir>/workflow-system/state/.session.md`, recording the workflow, the step, and the next
action — and drops a one-line marker into the WIP state file. *"One tiny pointer, plus your context
doc that's already on disk. It doesn't copy your plan into itself — it points at the files that hold
it. Everything needed to bring you back is in your repo, not in the model's memory of this chat."*

**Supply these four fields to the handoff** (it treats the tour ones as optional and writes them only when
a `tutorial-*` skill asks — see `session-handoff` SKILL.md §2, "Tour-driven handoffs"):

| Field | Value | Why |
|---|---|---|
| `tour:` | `brownfield` | Marks the pointer as belonging to a tour run, so the general session skills narrate a later boundary instead of offering it as a choice. |
| `tour_step:` | `8` | The step to resume **at** — Step 7 is finishing, Step 8 is next. |
| `resume_skill:` | `/tutorial-brownfield-workflow-tour` | Session C comes back to **this skill**, so you finish the run. **Not** the inner workflow's next state. |
| `drive_mode:` | the mode this run is in (`stepping` on a first run) | Required on a tour pointer — without it restore falls back to its own default and silently changes gear mid-run. |

**Also write `tour: brownfield` into the in-tour WIP's own frontmatter, next to `drive_mode`.** This is
belt-and-braces and the reason is specific: `/session-restore` **deletes** `.session.md` once it has consumed it,
so by the time a later in-tour boundary comes round in Session C the pointer is gone. The general session skills'
guards look for `tour:` in the pointer **or the active WIP** — the WIP copy is the one still on disk at that
moment, so without it those guards silently never fire and the only thing holding the line is this file's own
prose. Cheap to write, and it makes the backstop real rather than decorative.

`state_file:` still points at the inner WIP, so the work content stays reachable. Don't narrate this table
to the user — the *pointer* is the teaching beat, not its field list. If the user opens the file and asks
about `tour:`, a one-liner is plenty: it's how the next session knows the tour is still running.

**Scene 2 — reset the window (the real point).** Make it real if you can:
> *"Now the part that matters: we throw the context window away. `/exit` and start a brand-new
> session on this repo — a genuinely empty window, none of today's conversation in memory. This is
> what you reach for instead of `/compact` when the window's heavy and you don't want a lossy summary
> quietly dropping your context."*

(The user can actually `/exit` and relaunch for the full effect — and since restore reads off disk,
it genuinely works on their real repo. Narrating the reset makes the point too: the claim is that
nothing depends on this conversation surviving.)

**Scene 3 — restore, then check the window again.** Run **`/session-restore`**. Narrate what it pulls
off disk: it reads that `.session.md` pointer, re-opens the WIP state file, and reconstructs where
you were — the workflow, step, next action, any blockers — *without* replaying the conversation. Then
land the beat two ways — the window, then the plot:
> *"Look at your context-left now — reclaimed, nearly empty again. And yet the plan, the state, the
> next step, the reconstructed strategy — all back on your real repo. Notice where it came from: your
> project's own context file, the one you opened in Step 4, plus that little pointer. It didn't
> remember you from our chat, and it didn't summarize anything — it re-read your work off disk, at
> full detail, not a lossy compression. **That** is why it stops drifting and forgetting across
> sessions: the context was never trapped in the window — it's in your repo, so resetting the window
> costs you nothing. (Same reason you can close the laptop mid-task and pick up tomorrow.)"*

This is the payoff for beat A (state-is-a-file, Step 4): because the durable context lives in real
files, resetting the window — or coming back cold tomorrow — is just re-reading them. For the target
user who's lost real work to a compacted or crashed session, don't rush this — it's usually the beat
that converts.

**You are the one restore hands back to — so carry the run to its end from here, as one thread.** Because
the pointer set `resume_skill` to this skill, `/session-restore` returns control *here*, in whatever mode this run
has been in, with no drive-mode menu shown (restore suppresses it on a tour pointer precisely so Step 8 keeps the
reveal — on a replay you already have your gear, so there is nothing to ask). If the
inner feature or task still has states left to run — a ship, a close, a reflect — **drive them yourself as
part of the narration**, then go on to Step 8. There is exactly one thread: finish the work, then graduate.

**When one of those inner states reaches a clean terminal boundary, narrate it — don't act on it and don't
put it to the user.** The tour already wrote its one handoff back in Scene 1, so a second one is noise. Name
what a real project would do and keep moving:

> *"Notice where we just landed — that's a real clean boundary. On this repo, from here on, that's the moment
> the workflow writes the handoff by itself, so tomorrow's session opens with the whole plot intact. You watched
> that happen a step ago, so we won't do it twice — let's finish up."*

Asking "continue the tour, or hand off now?" here is the specific defect this wording exists to prevent: it
hands the user a decision about the mechanism they just watched, and there is only one sensible answer mid-run.

### Step 8 — Bookend 2: the graduation, LAST + un-pushed (STAGED reveal) → close

**This step is MODE-AWARE — branch on the drive mode the tour actually ran in** (the one established
at the "On entry" question). The two branches are mutually exclusive; deliver exactly one.

#### Branch A — FIRST RUN (stepping): reveal the faster gears
Use this when the tour ran in **stepping** (the first run). **Deliberately last, deliberately not
pushed.** The whole tour ran in stepping so the user *saw* the pause in Step 5. Only now — after
they've watched it reconstruct their strategy, pause and ask on their own code, and survive a
walk-away — reveal that the pauses are tunable:

> *"One last thing, now that you've watched it work on your own codebase. You saw it stop and ask you
> back in Step 5 — that pause is a setting, not a law. There are faster gears: **autopilot** chains
> the safe steps and only stops at the human checkpoints; **FSD** skips even those. They're real, and
> once you trust the workflow on your repo they're worth reaching for."*

Then immediately **un-push it** — the honest counterweight is why this goes last:

> *"But I'd genuinely leave those alone for now. The pause you just saw — where it checked with you
> before moving on, on your real code — is the single most valuable thing here while this is new to
> you. Earn the trust first, then shift gears. **Not recommended yet.**"*

(Do **not** demonstrate autopilot/FSD live in the tour — showing it in action would hide the very
beat B the tour is built around. This is a *named* reveal, not a staged run.) Then plant the replay in
one line (below), and let the `Next Step:` block at the very end carry the actual how — starting with
getting the repo back to a clean baseline.

#### Branch B — REPLAY (already in a faster gear): acknowledge, don't re-reveal
Use this when the tour ran in **autopilot / FSD** (a replay — the user already saw the stepping run
and this graduation once). Do **NOT** re-deliver the "pauses are tunable" reveal (they know) and do
**NOT** re-invite a replay (they're already doing it). Instead, name what they just *felt* on their
real repo:

> *"So — that's the same tour you did in stepping, but this time in <the gear they picked>, on your
> real repo. Notice the difference: it chained the routine steps on its own instead of stopping at
> each one, and <if autopilot:> it still stopped at the human checkpoint — the verify step — because
> that's the one pause worth keeping, even on your own code. <if FSD:> it didn't even stop there —
> that's FSD: full speed, no checkpoints, which is a lot to trust on a real repo. Now you've felt both
> ends. Most people settle somewhere in between: stepping while a workflow is new, a faster gear once
> they trust it on their codebase. You've got the whole range."*

Then **close** — no un-push, no replay invite (both are first-run moves). A short "you've now seen it
both ways; use whichever gear fits the work" is the right note. Skip the Branch-A replay-motivation line
below and go straight to the "what we did NOT demo" close (it applies to both branches), then Branch B's
own `Next Step:` block — which has **no replay option**, since they are already in one.

**Then (Branch A only) plant the replay in one line** — the honest way to let the user *feel* the faster
gears without demoing them live here (which would hide beat B). The tour stays stepping to its end; the
faster gears are something they go try **on a fresh run from the same starting point**, now that they
know what the pauses are protecting. Keep this to a sentence or two of *motivation* — the actionable
form (clean baseline first, and the rest of the mechanics) is **option 1 of the `Next Step:` block
below**, so do not spell the whole procedure out twice:

> *"If you want to feel the difference, the fastest way is to run this again in a faster gear — same
> repo, same starting point, but you'll watch it move. On code you already understand, that contrast is
> the quickest way to find where you're comfortable handing over the wheel. I'll put the how at the
> end — it starts with getting your repo back to the clean baseline."*

(This is a *named* invitation, not a live demo — the user drives the faster run themselves from a clean
baseline in a new session, so this run's beat B stays intact. Frame it as "go try it," never "watch me
autopilot." The four load-bearing replay mechanics — **clean baseline first** (why the Step-0 git-safety
pre-flight mattered: a clean, committed starting point is what makes "get back to start and replay"
safe), direct arm re-entry, session-boundary crossing, and gear-from-the-arm's-own-menu — live in the
`Next Step:` block's option 1 and its mechanics note; they are compressed there, not dropped.)

**Then close by naming what you did NOT demo** *(BOTH branches land here — Branch A after its replay
invite, Branch B directly after acknowledging the gear)* — framed as "here's what's here when you're
ready," never staged:

> *"Two things we didn't get into, so you know they're there:*
> - *the full **hierarchy** — product → feature → task all live in this same kind of on-disk record.
>   We only touched a slice of it today; on a real codebase the whole thing is more than you'd feel
>   in one run, but it's there when a big initiative needs it;*
> - *and it **learns you** — a reflect/capture step at the end of sessions quietly records your
>   preferences and corrections, so it fits your project and your habits better next session than it
>   did today.*
>
> *That's the tour — on your own code, which is the real test. You steered, it kept the plot and
> reconstructed what you'd never written down, and it's all in files you own."*

Then show **the artifacts as proof** — the real files this run touched or produced on their repo (the
revised `CLAUDE.md`, the WIP/archive record, the backlog entry, any commit). This is the evidence behind
"files you own," so it stays *before* the decision block.

### The close's last block — `Next Step:` (structure this deliberately)

**Everything above is narrative; the last thing on screen is a short, scannable decision block.** Same
rule as the greenfield arm (operator feedback, 2026-07-25): the actionable choice must not be buried
mid-prose. **Details above it, options in it, nothing after it.** Keep each option to **≤3 sentences**,
make it **per-branch**, and **name** options — never auto-run them.

**Branch A (first run) — two options:**

> **Next Step:**
>
> **1 — Run it again in a faster gear.** Set your repo back to the clean baseline (`git stash`, or
> `git restore .`), `/exit`, then run `/tutorial-brownfield-workflow-tour` directly in a fresh session
> and say yes when it asks if you're replaying. You'll feel exactly which stops autopilot keeps and
> which FSD drops — on your own code.
>
> **2 — Just start working.** You've seen the whole loop on this repo, so pick a real piece of work and
> run `/session-start`. That's the tour's actual payoff: this isn't a mode you enter, it's how you work
> from here.

**Branch B (replay) — one option** (no replay option — they're already in one):

> **Next Step:**
>
> **1 — Just start working.** You've now seen it both ways on your own code. Pick a real piece of work
> and run `/session-start` — you already know where it'll stop and why.

**Mechanics that must stay correct in the block** (compressed, not dropped):
- **Option 1/Branch A is the replay** with all four constraints: **clean baseline first**
  (`git stash` / `git restore .` — this is why the Step-0 git-safety pre-flight exists), `/exit` to a
  **fresh session** (a real session-boundary crossing), re-entry at **the arm skill directly — NOT
  `/tutorial-getting-started`** (the dispatcher would re-force stepping and re-ask the path fork), and
  the **gear chosen from the arm's own on-entry menu** (it asks "replaying?" then presents 1–4).
- **No cleanup offer on this arm** — unlike greenfield, nothing here is a throwaway sample; it's the
  user's real repo. Never offer to delete anything. (`git stash`/`git restore` is the user's own undo
  path, already covered by Step 0 and option 1.)
- **No deep-dive pointer on this arm** — `/tutorial-product-cycle-tour` is pointed at from the
  *greenfield* close (it pairs with greenfield's light hierarchy taste). Do not add it here.

The close reinforces beat **G** one final time (you kept the wheel) and hands the user back
to their real work — which is the whole value prop. **The tour ends here** — once you've delivered the
narrative close, the artifacts, and the `Next Step:` block, there is nothing further to invoke and no
transition to emit; the run is complete (see `## Transitions`). **The `Next Step:` block is the last
thing on screen** — if the user picks an option, they act on it themselves. (Note: the full hierarchy is
**CUT** as a felt beat on brownfield — too big to land in run one — so it is *named* at close, never
staged.)

## "Don't force it" (spec §7 — binding)

In this brownfield arm, **only** these beats are guaranteed **STAGED**: A (state-is-a-file, on the
revised `CLAUDE.md`), B (human pause), the **handoff→restore** bookend, and the **drive-modes**
reveal. The **grounding** headline (`/init`→reverse-engineer) is *natural, not staged*; **SURFACE**
and probe-first/verify-self grounding are **NAMED/opportunistic only**; **Hierarchy** is **CUT**
(named at close); **reflect/capture** is **NAMED** at close. Bring-your-own real code means no
manufactured beats — staging one on a real repo costs this skeptical audience more trust than the
aha earns.

## Transitions

**None.** This skill emits **no** workflow transition (no `F`/`I`/`T`/`P`/`S` ID), no `DEBUG-*`
token, no `RETURN-TO:`. It is the brownfield arm of the `tutorial-*` family: **run directly by the
user in a fresh session** (`tutorial-getting-started` points them here across a `/exit` — it does
NOT invoke this arm inline; see the Flow authority note at the top), it drives the walkthrough to its
close and ends. The state-machine
"three places in sync" rule does not apply (no transition to sync). Behavioral scenarios and the
`tutorial-`-prefix structural pin are added by WP7e.
