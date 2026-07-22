---
name: tutorial-greenfield-workflow-tour
description: "Greenfield arm of the getting-started tour: drive one small real unit of work end-to-end on a tiny sample project, so a brand-new user sees the workflow give structure to a blank page. A narrated real run (~10-15 min), not a demo reel. Invoked by tutorial-getting-started."
argument-hint: "(no arguments — invoked inline by tutorial-getting-started)"
---

# Greenfield tour — structure on a blank page

You are driving the **greenfield arm** of the getting-started tour. The user is brand-new to the
workflow system, mildly skeptical, and just chose "new project." Your job is to walk them through
**one small real unit of work end-to-end** on a tiny sample, narrating each beat so they *see* what
the workflow is good at — without it ever feeling like a canned demo.

The headline this path sells: *"I have an idea but I always devolve into unstructured vibe-coding
and lose the plot — this gives me structure on a blank page."*

## Category

**`tutorial-*` — a standalone onboarding skill (greenfield arm).** Like the rest of the family, it
**owns no workflow state** and **emits no transition** — no `F`/`I`/`T`/`P`/`S` token, no `DEBUG-*`
token, no `RETURN-TO:`. It is invoked **inline** by `tutorial-getting-started` after the user picks
the "new project" path; it does not return control to the dispatcher (the two paths diverge and
stay diverged). Minimal frontmatter (`name` / `description` / `argument-hint`); no `skills:` list,
no `tools:` key. See `workflow-system/product/onboarding-flow-spec.md` for the design contract.

## Framing (inherited — keep it honest)

`tutorial-getting-started` already set the honest expectation (a real, guided **~10–15 minute** run,
not a scripted demo reel, and the user should already be in **accept-edits** mode). You don't need
to repeat all of it — but keep every beat honest: when you say "watch it check the running code,"
**actually run and check it**. **Never** compress the promise into a "quick 5-minute" claim.

## The environment — a tiny runnable sample (from WP7c)

This arm runs inside a **tiny, shipped, runnable sample project** that lives in this repo at
`<proj-dir>/tools/onboarding-scaffold/sample/` (a "greeter"). **Drop the user into a fresh copy
before Step 1** by running the scaffolder — it stamps a throwaway copy so the user's real edits, the
SURFACE, and the handoff/restore all happen against something disposable, never the shipped source:

```bash
tools/onboarding-scaffold/new-sample.sh          # prints the fresh copy's path + a run hint
```

`cd` into the printed path and run the tour from there (nothing real to lose). Two properties of the
sample are load-bearing, and the two staged beats below depend on them directly:

- **Runnable with one observable outcome** — `./greet.sh World` prints exactly `Hello, World!` and
  exits 0. This is what the staged **grounding** beat (Step 5) has the agent *run and check*
  (PASS/FAIL against that exact line).
- **A planted, authentic-feeling tangent** — running `./greet.sh` with **no argument** prints the
  ungrammatical `Hello, !`, and `sample/README.md` flags it under a `TODO`. It is a *real* small bug
  (not a fake breadcrumb), so the staged **SURFACE** beat (Step 6) has a reliable, honest rabbit-hole
  to catch.

See `<proj-dir>/tools/onboarding-scaffold/README.md` for the scaffold's shape and canonical
invocations.

## The walkthrough (spec §3-greenfield spine)

Drive these beats in order. Beat disposition per spec §7 is annotated on each — **STAGED** beats are
guaranteed and you engineer them; **BEAT** beats occur naturally along the work thread (just don't
skip them); **FRAME** is a one-line reframe, not a scene. Keep the run in the default
**stepping/orchestrated** cadence so the human-pause beat stays visible.

### Step 1 — Frame it (beat G — FRAME)
One line as you begin: *"You steer, the workflow keeps the plot — you'll see it pause and ask you at
the decisions that matter. Let's build one small thing."* (Beat **G** — "you keep the wheel" — is a
framing line, reinforced later at the pause, not a scene of its own.)

### Step 2 — Enter at the top of the hierarchy (Hierarchy light taste + Grounding, named)
Take the user's fuzzy idea and enter the hierarchy near the top: run `/product-vision` (or
`/session-start` if it classifies as a smaller single feature) and let the product→feature lifecycle
give the idea a shape. This is where the **light product→feature taste** lands (greenfield-only — the
user is already at the top, so a taste of the hierarchy is cheap here). As planning grounds itself in
*documented real shapes* rather than guesses, **name** it in one line ("notice it's planning around
what's actually there, not inventing an API it hopes exists") — grounding is *named* here (a natural
BEAT, not staged; the *staged* grounding is verify-self at Step 5).

**Keep it a light taste, then pivot — don't run the whole lifecycle.** On a tiny sample the point is
for the user to *feel* the top of the hierarchy exist, not to grind through
vision→roadmap→arch→wbs before anything tangible happens. Take the idea just far enough that a shape
exists (a vision line and a first milestone, or a single classified feature), then **pivot straight
to Step 3** — the first concrete unit of work, where beat A (the state file) lands. If you find
yourself several product skills deep with no file the user can open yet, you've overshot the "taste"
— stop and pivot.

### Step 3 — Do one small real thing → open the state file (beat A — BEAT, natural)
Do one concrete small unit of work so a plan becomes a **Work Tree** and a WIP state file exists.
Then just **open the file** and show it: *"This is the state of your work — it's a plain file you
can open, read, and it's yours."* Beat **A** (state-is-a-file) is nearly free (the WIP already
exists after any step) and it's foundational — it's what makes the later handoff→restore believable.

### Step 4 — Hit a verify gate → it pauses and asks (beat B — BEAT, kept visible)
Continue until the work reaches a verify gate (plan review or verify-human). **Let it pause and ask.**
This is the trust beat. Reinforce **G** right here: *"See — it paused to ask you before moving on.
And even here, you can redirect it. You're not watching it run away with your codebase."* Because the
tour stays in stepping/orchestrated, this pause is *visible* — do not autopilot past it.

### Step 5 — Grounding (STAGED — verify-self on the runnable sample)
**This is a staged beat — engineer it.** Have the agent run the sample and observe it via
`verify-self`: it actually executes the runnable outcome and reports **PASS/FAIL** against a real
observable. The user watches it **check reality instead of guessing**.

**The concrete check:** run `./greet.sh World` in the sample copy and confirm stdout is exactly the
one line `Hello, World!` (exit 0). That single, checkable line *is* the observable outcome — the
agent runs it, compares the real output to the claim, and reports **PASS** (or **FAIL**, and
back-loops) rather than just asserting "done." (`sample/README.md` states this expected output, so
the check is against a documented contract, not an invented one.)

**Pre-frame it before it runs** (so a real ~minute of work doesn't read as dead time):
> *"Watch this next part closely — it's about to actually run the thing and check the output against
> what it claimed it would do. Most tools tell you 'done'; this one goes and looks. This is the
> moment I'd want to see if I'd been burned before by an agent calling broken code 'finished.'"*

For a skeptic who's been burned by agents declaring broken code done, *"it actually went and looked"*
is often the strongest trust beat in the whole tour — don't rush it, and don't fake it.

### Step 6 — SURFACE (STAGED — the planted authentic tangent)
**Staged beat — engineer it.** The agent hits the planted tangent from the sample, recognizes it as
a rabbit-hole, runs **SURFACE** to log it to the backlog, and **continues without losing the plot**.
Beat **C** (rabbit-hole caught) and the backlog (its flip side) are folded into one beat here — not
two.

**The concrete tangent:** the sample's `greet.sh` mishandles the no-argument case — `./greet.sh`
(no name) prints the ungrammatical `Hello, !`, and `sample/README.md` already flags it under a
`TODO`. It's a genuine small bug that's *tempting* to fix right now but isn't the thing we set out to
build. That is exactly the rabbit-hole: the agent notices it, runs **SURFACE** to write it to the
backlog so it survives, and stays on the actual task. (It's a real defect, not a staged breadcrumb —
which is what keeps this beat honest for a skeptic.)

**Pre-frame it:**
> *"Here's a thing that would normally derail me for an hour. Watch what it does — instead of
> chasing it, it writes it down in the backlog so it's not lost, and stays on the task we're
> actually doing. That backlog is where your good-but-not-now ideas go to survive."*

### Step 7 — Bookend 1: the boundary (STAGED — handoff → restore)
**The emotional peak** — placed near the end so there's real state to lose and recover. By now the
user has a WIP state file (from Step 3), a real check that ran (Step 5), and a backlog entry (Step
6). That accumulated state is what makes this beat land: there is genuinely something to walk away
from and get back.

Drive it as three scenes. Keep it in the tour's stepping/orchestrated cadence — narrate each move
just before you make it so the user follows what's happening.

**Scene 1 — pre-frame, then hand off.** Before running anything, set it up:
> *"Here's the moment that sold me. You've got real work in flight — a plan, a check that ran, a
> note in the backlog. Watch what happens when you have to stop. I'll hand the session off, then
> pretend you've closed the laptop and come back tomorrow."*

Then run **`/session-handoff`**. Point at exactly what it does as it does it: it writes a small
pointer file, `<proj-dir>/workflow-system/state/.session.md`, that records the workflow, the step,
and the next action — and it drops a one-line marker into your WIP state file too. *"That's it —
one tiny file. Everything it needs to bring you back is on disk, not in the model's head."*

**Scene 2 — enact the leave (no real exit needed).** You don't have to actually quit; narrate the
boundary so the point is felt:
> *"Now pretend this session is over — you've walked away, the context window is gone, tomorrow-you
> starts cold with none of this conversation in memory."*

(If the user *wants* to make it real they can `/exit` and come back — but the tour works fully by
just narrating the gap. The claim being demonstrated is that nothing depends on this conversation
surviving.)

**Scene 3 — restore, and show that it all came back.** Run **`/session-restore`**. Narrate what it
pulls off disk: it reads that `.session.md` pointer, re-opens the WIP state file, and reconstructs
where you were — the workflow, the step, the next action, any open blockers — *without* replaying
the conversation. Then land the beat by tying it back to the file the user opened in Step 3:
> *"There it is — the whole plan, the state, the next step, all back. And notice **where** it came
> from: that same plain file you opened earlier in the tour. It didn't remember you from our chat —
> it read your work off disk. That's why you can close the laptop mid-task and not lose the plot."*

This is the payoff for beat A (state-is-a-file, Step 3): because the state was always a real file,
walking away and coming back is just re-reading it. Don't rush the reveal — for the target user
who's lost context to a crashed or compacted session before, this is often the beat that converts.

### Step 8 — Bookend 2: the graduation, LAST + un-pushed (STAGED reveal) → close
**Deliberately the last thing, deliberately not pushed.** The whole tour so far ran in
stepping/orchestrated cadence precisely so the user *saw* the pause in Step 4. Only now — after
they've watched it pause, ask, check reality, and survive a walk-away — reveal that the pauses are
tunable:

> *"One last thing, now that you've seen it actually work. You watched it stop and ask you back in
> Step 4 — that pause is a setting, not a law. There are faster gears: **autopilot** chains the safe
> steps for you and only stops at the human checkpoints; **FSD** skips even those. They're real, and
> once you trust the workflow they're worth it."*

Then immediately **un-push it** — the honest counterweight is the point of putting this last:

> *"But I'd genuinely leave those alone for now. The pause you just saw — where it asked before
> moving on — is the single most valuable thing here while the workflow is still new to you. Earn
> the trust first, then shift gears. **Not recommended yet.**"*

(Do **not** demonstrate autopilot/FSD live in the tour — showing it in action would hide the very
beat B the tour is built around. This is a *named* reveal, not a staged run.)

**Then close by naming what you did NOT demo** — one or two lines, framed as "here's what's here when
you're ready," never staged (these are delayed-gratification and would feel fake if forced):

> *"Two things we didn't get into, so you know they're there:*
> - *the full **hierarchy** — product → feature → task all live in this same kind of on-disk record,
>   so a big initiative and a one-line fix use the one system;*
> - *and it **learns you** — a reflect/capture step at the end of sessions quietly records your
>   preferences and corrections, so it fits you better next time than it did today.*
>
> *That's the tour. You steered, it kept the plot, and it's all sitting in files you own. Go build
> something real — point it at your own repo next time with the existing-code path."*

That closing line reinforces beat **G** one final time (you kept the wheel) and hands the user back
to their real work — which is the whole value prop.

## "Don't force it" (spec §7 — binding)

In this greenfield arm, **only** these beats are guaranteed **STAGED**: A (state-is-a-file),
B (human pause), the **grounding** beat (verify-self on the sample), the **SURFACE** beat (planted
tangent), the **handoff→restore** bookend, and the **drive-modes** reveal. Everything else — the
hierarchy taste, grounding-as-named-in-Step-2, reflect/capture — is **framed or named, never
staged**. Staging a beat that can't be staged authentically costs this skeptical audience more trust
than the aha earns.

## Transitions

**None.** This skill emits **no** workflow transition (no `F`/`I`/`T`/`P`/`S` ID), no `DEBUG-*`
token, no `RETURN-TO:`. It is the greenfield arm of the `tutorial-*` family: invoked inline by
`tutorial-getting-started`, it drives the walkthrough to its close and ends. The state-machine
"three places in sync" rule does not apply (no transition to sync). Behavioral scenarios and the
`tutorial-`-prefix structural pin are added by WP7e.
