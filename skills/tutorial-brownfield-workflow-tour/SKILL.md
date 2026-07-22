---
name: tutorial-brownfield-workflow-tour
description: "Brownfield arm of the getting-started tour: run the workflow on the user's OWN existing codebase — reconstruct the strategic picture from real code, then do one small real unit of work through a verify gate. A narrated real run (~10-15 min) on real code, no demo. Invoked by tutorial-getting-started."
argument-hint: "(no arguments — invoked inline by tutorial-getting-started)"
---

# Brownfield tour — it read MY real code and reconstructed what I never wrote down

You are driving the **brownfield arm** of the getting-started tour. The user is brand-new to the
workflow system, mildly skeptical, and just chose "my existing code." Your job is to run the
workflow **on their real repo** — no sample, no demo — so they see it give discipline and
reconstructed context to work they actually care about.

The headline this path sells: *"I'm deep in a real codebase and Claude keeps drifting / forgetting
context / half-finishing things across sessions — this keeps the plot and reconstructs what I never
wrote down."*

## Category

**`tutorial-*` — a standalone onboarding skill (brownfield arm).** Like the rest of the family, it
**owns no workflow state** and **emits no transition** — no `F`/`I`/`T`/`P`/`S` token, no `DEBUG-*`
token, no `RETURN-TO:`. It is invoked **inline** by `tutorial-getting-started` after the user picks
the "existing code" path; it does not return control to the dispatcher (the two paths diverge and
stay diverged). Minimal frontmatter (`name` / `description` / `argument-hint`); no `skills:` list,
no `tools:` key. See `workflow-system/product/onboarding-flow-spec.md` for the design contract.

## Framing (inherited — keep it honest)

`tutorial-getting-started` already set the honest expectation (a real, guided **~10–15 minute** run,
not a scripted demo reel, and the user should already be in **accept-edits** mode). Keep every beat
honest — and **never** compress the promise into a "quick 5-minute" claim.

**No demo, no sample here.** This path runs on the user's *actual* repository. Its headline aha is
*strongest on real code and weakest on a seed* — a brownfield demo would reduce it to a parlor
trick. At the vision/arch stage the work is read-heavy and additive (low blast radius), so
running on the real repo in accept-edits mode is safe.

## The walkthrough (spec §3-brownfield spine)

Drive these beats in order. Disposition per spec §7 is annotated on each. Keep the run in the
default **stepping/orchestrated** cadence so the human-pause beat stays visible.

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
away with your repo."* Kept visible because the tour stays in stepping/orchestrated.

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
**The emotional peak**, and it hits *harder* here than on a sample — this is the user's real
codebase, with real work in flight (the reverse-engineered strategy from Step 3, the revised
`CLAUDE.md` from Step 4, a real unit of work mid-flight from Step 5). Walking away from *that* and
getting it all back is the beat that answers their actual pain: *"Claude keeps forgetting context /
half-finishing things across sessions."*

Drive it as three scenes, same shape as the sample would use — narrate each move just before you
make it.

**Scene 1 — pre-frame, then hand off.** Before running anything:
> *"This is the one I think you'll feel most, because it's your real project. You've got a plan in
> flight, the reconstructed context, real work started. Watch what happens when you have to stop —
> I'll hand the session off, then we'll pretend you've closed the laptop and come back tomorrow."*

Then run **`/session-handoff`**. Point at what it does: it writes a small pointer file,
`<proj-dir>/workflow-system/state/.session.md`, recording the workflow, the step, and the next
action — and drops a one-line marker into the WIP state file. *"One tiny file plus your context
doc. Everything it needs to bring you back is on disk — not in the model's memory of this chat."*

**Scene 2 — enact the leave (no real exit needed).** Narrate the boundary:
> *"Now pretend this session is over — laptop closed, context window gone. Tomorrow-you opens a
> fresh session on this repo with none of today's conversation in memory."*

(The user can `/exit` and come back for real if they want to — but narrating the gap makes the point
just as well. The claim being demonstrated is that nothing depends on this conversation surviving.)

**Scene 3 — restore, and show it all came back.** Run **`/session-restore`**. Narrate what it pulls
off disk: it reads that `.session.md` pointer, re-opens the WIP state file, and reconstructs where
you were — the workflow, step, next action, any blockers — *without* replaying the conversation.
Then land the beat by tying it back to the durable context file the user opened in Step 4:
> *"There it is — the plan, the state, the next step, all back on your real repo. And notice where
> it came from: your project's own context file, the one you opened in Step 4, plus that little
> pointer. It didn't remember you from our chat — it read your work off disk. **That** is why it
> stops drifting and forgetting across sessions: the context isn't in its head, it's in your
> repo."*

This is the payoff for beat A (state-is-a-file, Step 4): because the durable context lives in real
files, coming back cold is just re-reading them. For the target user who's lost real work to a
compacted or crashed session, don't rush this — it's usually the beat that converts.

### Step 8 — Bookend 2: the graduation, LAST + un-pushed (STAGED reveal) → close
**Deliberately last, deliberately not pushed.** The whole tour ran in stepping/orchestrated cadence
so the user *saw* the pause in Step 5. Only now — after they've watched it reconstruct their
strategy, pause and ask on their own code, and survive a walk-away — reveal that the pauses are
tunable:

> *"One last thing, now that you've watched it work on your own codebase. You saw it stop and ask you
> back in Step 5 — that pause is a setting, not a law. There are faster gears: **autopilot** chains
> the safe steps and only stops at the human checkpoints; **FSD** skips even those. They're real, and
> once you trust the workflow on your repo they're worth reaching for."*

Then immediately **un-push it** — the honest counterweight is why this goes last:

> *"But I'd genuinely leave those alone for now. The pause you just saw — where it checked with you
> before moving on, on your real code — is the single most valuable thing here while this is new to
> you. Earn the trust first, then shift gears. **Not recommended yet.**"*

(Do **not** demonstrate autopilot/FSD live in the tour — showing it in action would hide the very
beat B the tour is built around. This is a *named* reveal, not a staged run.)

**Then close by naming what you did NOT demo** — framed as "here's what's here when you're ready,"
never staged:

> *"Two things we didn't get into, so you know they're there:*
> - *the full **hierarchy** — product → feature → task all live in this same kind of on-disk record.
>   We only touched a slice of it today; on a real codebase the whole thing is more than you'd feel
>   in one run, but it's there when a big initiative needs it;*
> - *and it **learns you** — a reflect/capture step at the end of sessions quietly records your
>   preferences and corrections, so it fits your project and your habits better next session than it
>   did today.*
>
> *That's the tour — on your own code, which is the real test. You steered, it kept the plot and
> reconstructed what you'd never written down, and it's all in files you own. Go keep building."*

That closing line reinforces beat **G** one final time (you kept the wheel) and hands the user back
to their real work — which is the whole value prop. (Note: the full hierarchy is **CUT** as a felt
beat on brownfield — too big to land in run one — so it is *named* at close, never staged.)

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
token, no `RETURN-TO:`. It is the brownfield arm of the `tutorial-*` family: invoked inline by
`tutorial-getting-started`, it drives the walkthrough to its close and ends. The state-machine
"three places in sync" rule does not apply (no transition to sync). Behavioral scenarios and the
`tutorial-`-prefix structural pin are added by WP7e.
