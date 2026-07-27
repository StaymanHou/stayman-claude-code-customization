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

### The tour hosts the workflow — a close inside the tour is NOT the session's boundary

This tour drives a **real** unit of work on the user's **real** repo through to a **real** terminal
close. When that close lands — `feature-finalize` / `feature-refactor` / `task-close` → `session-reflect` — the state
machine correctly sees a **clean workflow boundary**, and the modeled session-boundary exit chain
(**`S22`** on the no-learning arm, **`S23`** after a `session-capture` save) is **AUTO in all four
drive modes**. Left alone, it will pull toward writing a session handoff.

**Inside a tour run, do not take that exit, and do not offer it.** The tour is the host; the
in-tour close is a *beat inside it*, not the end of the session. Concretely, when the in-tour close
reaches `session-reflect`:

- **Run reflect normally** — it is a real beat and part of what the tour is showing.
- **Then continue to the next tour step.** Do **not** invoke `/session-handoff`, do **not** write
  `workflow-system/state/.session.md` on the strength of `S22`/`S23`, and do **not** present a
  "continue the tour, or hand off now?" choice. The user came here for the tour; asking them to
  re-choose it mid-run is friction, and the answer is always "continue."
- **This holds in every drive mode**, including autopilot and FSD. It is a narrow, tour-scoped
  precondition on an existing edge — **not** a new transition, and **not** a change to `S22`/`S23`
  for real work outside a tour.

The one handoff this tour *does* perform is its **own staged one in Step 7**, which the tour scripts
deliberately as a teaching beat. That is the tour's boundary, not the state machine's — see Step 7,
which draws the distinction explicitly.

> **Why this guard exists (a real misfire, 2026-07-25).** In the operator's live walkthrough of the
> sibling greenfield arm, the in-tour feature closed, reflect had nothing to persist, and the agent —
> reading `S22` correctly — noticed tour beats remained and *offered a fork*: "Continue the tour" vs.
> "Hand off now." The operator had to type "continue the tour" to proceed. The reasoning was sound;
> the ambiguity was real (two different "boundary" notions coexist in a tour run). This arm carries
> the same guard because it hosts a real workflow the same way.

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

> **Two different "boundaries" — keep them straight (they are easy to conflate).** This step's
> `/session-handoff` → `/exit` → `/session-restore` is the tour's **own STAGED boundary**: you script
> it, here, on purpose, as the teaching beat. It is the **only** handoff this tour performs. It is
> *not* the same thing as the **state machine's real boundary** — the one the in-tour close
> (`feature-finalize` → `session-reflect`) produces, which the exit chain (`S22`/`S23`) would
> otherwise auto-take. That one is **suppressed for the whole tour run** (see "The tour hosts the
> workflow" under `## Category`). So: the in-tour close does **not** hand off and does **not** offer
> to; *this* step does, because the tour says so and because there is now real accumulated state to
> lose and recover. If you find yourself about to write `.session.md` anywhere other than Step 7
> Scene 1, you are following the wrong boundary.

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
