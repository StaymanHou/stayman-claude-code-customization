---
name: tutorial-getting-started
description: "First-run guided tour of the workflow system for a brand-new user. Recommends auto permission mode (if available), asks new-project vs. existing-code, then runs the matching hands-on walkthrough of one small real unit of work end-to-end in stepping mode. A narrated real run (~10-15 min), not a demo reel."
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

### Step 0 — Where to run this (pre-flight, before anything else)

Make sure the tour runs in the *right directory* before you set the mode — this branches by which
path the user is about to take, so ask the new-vs-existing question (Step 2's fork) informally here
first, or just cover both:

- **New project (greenfield):** **you don't need to `cd` anywhere or make an empty folder.** The
  tour spins up its **own throwaway sample project** (a fresh disposable copy) and works inside that,
  so nothing you do touches your real files. Just run the tour from wherever you are. Say so, so the
  user isn't confused about "where is this happening":
  > *"You don't need to set anything up or pick a folder — I'll create a small throwaway sample
  > project for us to work in, so there's genuinely nothing of yours to lose."*

- **Existing code (brownfield):** the tour must run **inside your real project's root directory** so
  the workflow operates on the right code. If this Claude Code session isn't already at your repo
  root, have the user do this first:
  > *"Since we'll work in your real repo: **`/exit` this session, `cd` into your project's root
  > directory, relaunch `claude` there** (in auto mode — see the next step — e.g.
  > `claude --permission-mode auto`), then run `/tutorial-getting-started` again. That way the tour
  > operates on your actual codebase from the start."*

  (If the session is already at the repo root, skip the exit/relaunch — just note that's where
  we're working.)

### Step 1 — Recommend `auto` mode (universal, both paths)

Before anything else, get the user into **auto** mode so the tour runs without a permission prompt
on every single step — the tour really *runs* things (it executes the sample, writes files, hands
off and restores), and in a more restrictive mode the user gets prompted on every shell command,
which drowns the beats the tour is built to show.

**`auto` mode is low-friction AND safe.** It lets file edits, shell commands, and network calls run
without routine prompts, but a **classifier reviews every action** and blocks anything dangerous
(downloading-and-running code, force-push, production deploys, mass deletion, sending secrets out,
destructive resets). So the "you can trust it here, nothing bad escapes" reassurance stays
**honestly true** — unlike bypass-permissions, which has *no* guardrails at all (it's for isolated
containers, and it's the wrong mental model for a first run).

Say to the user (deliver this close to verbatim):

> *"First, let's put Claude Code in **auto** mode so the tour can actually run — execute the sample,
> write files, hand off and restore — without stopping to ask you on every single step. Auto mode
> isn't a free-for-all: a safety classifier still checks each action and blocks anything genuinely
> dangerous (nothing gets force-pushed, deployed, or deleted out from under you). It's safe here —
> all work stays inside this one project directory — and **you keep the wheel**: the workflow itself
> still pauses to ask you at the decisions that matter."*

**How to switch into `auto`:**
- If your Claude Code shows **auto** in the `Shift+Tab` cycle, press **Shift+Tab** until you see it.
- Otherwise, the reliable way is to **launch a session in auto mode**:
  ```bash
  claude --permission-mode auto
  ```
  (or set `"permissions": { "defaultMode": "auto" }` in `~/.claude/settings.json`).

> **If auto mode isn't available to you** (it needs a recent model — Opus 4.6+/Sonnet 4.6+/Fable 5 —
> and an account/provider that allows it), that's fine: just take the tour in whatever mode you have.
> It simply means Claude Code will ask permission more often as we go — the tour still works exactly
> the same, you'll just click **Yes** a few more times. Do **not** reach for bypass-permissions as a
> substitute; a few extra prompts is the right tradeoff over turning off all the guardrails.

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

**The tour runs in `stepping` drive mode — set it, name it, do not change it.** This is the
**workflow drive mode** (how the *workflow* chains its steps), which is distinct from the **permission
mode** (`auto`) set in Step 1 (how *Claude Code* gates tool calls) — the two are independent and both
apply. Stepping mode makes the workflow **pause after every skill** so the human-in-the-loop pause
(beat B) is unmistakably *visible*. This is load-bearing: the Step-8 graduation reveal only works if
the user actually *saw* the workflow stop and ask them.

- **Do NOT present a drive-mode menu here**, and do **NOT** run the tour in orchestrated/autopilot/FSD
  — those auto-chain steps and would skip past the exact pause the tour exists to show.
- Drive the whole tour in **stepping** mode from here through Step 8. Drive modes (autopilot / FSD)
  are revealed only at the very end, as a graduation.

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
