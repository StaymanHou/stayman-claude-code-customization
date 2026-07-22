---
name: tutorial-getting-started
description: "First-run guided tour of the workflow system for a brand-new user. Recommends accept-edits mode, asks new-project vs. existing-code, then runs the matching hands-on walkthrough of one small real unit of work end-to-end. A narrated real run (~10-15 min), not a demo reel."
argument-hint: "(no arguments — just run it)"
---

# Getting Started — the workflow-system tutorial

You are guiding a **brand-new user** through their first hands-on experience of the workflow
system. This skill is the **single entry point** for onboarding: it sets up permissions, asks one
question (new project or existing code), then hands off **inline** to the matching walkthrough.

## Category

**`tutorial-*` — a standalone, user-invoked onboarding skill family.** This skill (and its two
sibling arm skills) is **NOT part of any workflow state machine**:

- It **owns no workflow state** and **emits no transition** — no `F`/`I`/`T`/`P`/`S` token, no
  `DEBUG-*` token, no `RETURN-TO:`. It is an entry point itself, not a workflow state and not a
  pulled sidebar.
- It **dispatches inline** to one of two arm skills — `tutorial-greenfield-workflow-tour` or
  `tutorial-brownfield-workflow-tour` — by invoking that skill in the same conversation (a
  `session-start`-like experience). The arm you dispatch to **runs the tour to its close** — you do
  not resume this dispatcher afterward or run any further steps here; entering an arm is the last
  thing this skill does.
- Frontmatter is the minimal shape: `name` / `description` / `argument-hint`. No `skills:` list
  (it is not an orchestrator) and no `tools:` key (it is not an executable subagent).

The three `tutorial-` skills are their own concept; the `tutorial-` name prefix is the
self-documenting signal that they sit outside the state machine. See
`workflow-system/product/onboarding-flow-spec.md` for the full design contract.

## What this is (read this framing to the user)

This is a **real, guided run** of the workflow system on a small piece of work — **not** a scripted
demo reel. The agent drives *real* skills with *real* reasoning: when the tour says "watch it check
the running code," it actually runs and checks it. That honesty is the whole point — the moments
worth seeing (it grounds itself in reality, it catches a rabbit-hole, it survives you walking away
mid-task) only land if they're genuine.

**Set expectations honestly, up front:**

> *"This is a guided **~10–15 minute** run on a small piece of work — real, so you actually watch
> it work. Some steps are near-instant; a couple take a minute because the agent is really doing
> the thing, not faking it."*

**Never** promise a "quick 5-minute tour" or a "5-minute demo" — that is false advertising for a
real agent run, and a user who feels misled trusts the system less, not more. Keep the label honest.

## Procedure

### Step 1 — Recommend `accept edits` mode (universal, both paths)

Before anything else, get the user into **accept-edits** mode so the tour can make its file changes
without a permission prompt on every single step — while still asking before it runs any shell
command or touches the network.

Say to the user (this is the settled reassurance copy — deliver it close to verbatim):

> *"First, press **Shift+Tab** until Claude Code shows **'accept edits'** mode — that lets the tour
> make its file changes without a prompt on every step, while still asking you before it runs any
> shell command or touches the network. It's safe here: all work stays inside this one project
> directory, nothing is pushed or published, and **you keep the wheel** (the workflow still pauses
> to ask you at the decisions that matter)."*

**Recommend `accept edits`, NOT bypass-permissions.** These are two different modes:
`accept edits` auto-accepts file edits but **still gates arbitrary shell commands and network
calls**, so the "stays local" promise is honestly true. Bypass-permissions skips *all* checks and
is meant for isolated containers — it's overkill for a tour and trains the wrong mental model. If
the user asks, explain the distinction, but the recommendation is always `accept edits`.

Wait for the user to confirm they've switched (or to say they'd rather leave permissions as-is —
that's fine, the tour just prompts more often).

### Step 2 — Ask: new project, or existing code?

Ask the user which situation fits them, and frame the two paths as **peers** — greenfield is the
recommended default for a true first-timer because every beat lands cleanly on a controlled sample,
but brownfield is **one keystroke away, not gated behind the tutorial**:

> *"Two ways to take the tour — pick whichever fits you right now:*
>
> ***1. New project (recommended for a first look)** — I'll spin up a tiny sample and we'll build
> one small thing end-to-end. It's the cleanest way to see every moment the workflow is good at,
> with nothing real to lose.*
>
> ***2. Your existing code** — got a real repo you're working in? Point the tour at that instead.
> Same tour, but on your actual codebase — and the best moment (watching it reconstruct the
> strategic picture from code you never documented) is strongest on real code.*
>
> *Which one — new project, or your existing code?"*

**This is a default, not a funnel.** Do not push the user toward greenfield if they have real code
they'd rather use — brownfield is a first-class peer. Recommend greenfield only as the reliable
first-timer default.

**Do NOT present a drive-mode menu here.** The tour deliberately runs in the default
stepping/orchestrated cadence so the human-in-the-loop pause is *visible* later. Drive modes
(autopilot / FSD) are revealed only at the very end, as a graduation — surfacing them now would
invite the user to autopilot past the exact beat the tour exists to show.

### Step 3 — Dispatch inline to the matching arm

Based on the user's choice, **invoke the matching arm skill inline** (in this same conversation)
and let it drive the rest of the tour. The two paths **diverge and stay diverged**: the arm runs the
tour through to its close, and you do not come back here to run more steps or pick up a second path —
whatever the arm does *is* the rest of the run.

- **New project → invoke `tutorial-greenfield-workflow-tour`.** It sets up the tiny runnable sample
  and drives the greenfield walkthrough (structure on a blank page: hierarchy taste, the state file,
  the verify pause, the grounding beat, the SURFACE beat, then the handoff→restore bookend and the
  drive-modes graduation reveal).
- **Existing code → invoke `tutorial-brownfield-workflow-tour`.** It drives the brownfield
  walkthrough on the user's real repo (`/init` if the project isn't set up yet, product-workflow
  reconstructs the strategic layer from the code, then one small real unit of work through the
  verify pause, closing with the same handoff→restore bookend and drive-modes reveal).

Use the `Skill` tool to invoke the chosen arm. Once dispatched, the arm skill owns the rest of the
run.

## Transitions

**None.** This skill emits **no** workflow transition (no `F`/`I`/`T`/`P`/`S` ID), no `DEBUG-*`
token, and no `RETURN-TO:`. It is a `tutorial-*` entry point: it runs Steps 1–3, dispatches inline
to an arm skill, and ends. The state-machine "three places in sync" rule does not apply here —
there is no transition to keep in sync. (Behavioral scenarios and the `tutorial-`-prefix structural
pin are added by WP7e, separately.)
