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

This arm runs inside a **tiny, shipped, runnable sample project** (built by WP7c — forward
touchpoint; wire the drop-in when that scaffold lands). Two properties of the sample are
load-bearing, and this arm depends on both:

- It is **runnable with at least one observable outcome**, so the staged **grounding** beat
  (verify-self) has something *real* to observe (agent runs it, reports PASS/FAIL).
- It contains a **planted, authentic-feeling tangent** (a small mess the user will plausibly want
  to chase), so the staged **SURFACE** beat fires *reliably* without feeling manufactured.

Drop the user into a fresh copy of the sample (nothing real to lose) before Step 1.

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
what's actually there, not inventing an API it hopes exists") — grounding is *named* here, *staged*
later at verify-self.

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

**Pre-frame it:**
> *"Here's a thing that would normally derail me for an hour. Watch what it does — instead of
> chasing it, it writes it down in the backlog so it's not lost, and stays on the task we're
> actually doing. That backlog is where your good-but-not-now ideas go to survive."*

### Step 7 — Bookend 1: the boundary (STAGED — handoff → restore)
**The emotional peak** — placed near the end so there's real state to lose and recover.
`/session-handoff` → the user "leaves" (simulate stepping away) → `/session-restore` → full context
comes back. *"You just walked away mid-task and came back to exactly where you were — nothing
reconstructed from memory, it's all in that file you opened earlier."*

> **WP7d wiring touchpoint (forward-declared).** The full scene-by-scene choreography of this
> bookend — how the "leave" is enacted, the exact narration — is authored by **WP7d**
> (staged-beats-wiring). This arm marks the beat and its position; WP7d writes the scene copy.

### Step 8 — Bookend 2: the graduation, LAST + un-pushed (STAGED reveal) → close
**Deliberately the last thing, deliberately not pushed.** Only now reveal drive modes:
> *"One more thing, now that you've seen it work: you can let it chain the safe steps automatically
> (autopilot), or even skip the human checks entirely (FSD). Powerful once you trust it — but
> **not recommended yet**. The pause you saw earlier is the point; keep it for a while."*

Then **close** by *naming* what you did NOT demo — full **Hierarchy** (product→feature→task as one
record) and **Reflect/Capture** ("the system learns your preferences over sessions") — as "here's
what's here when you're ready," never as staged beats (they're delayed-gratification and would feel
fake if forced).

> **WP7d wiring touchpoint (forward-declared).** The drive-modes graduation reveal copy and the
> named-at-close pointers are authored by **WP7d**. This arm fixes their position (LAST, un-pushed)
> and disposition (STAGED reveal + NAMED close); WP7d writes the scene copy.

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
