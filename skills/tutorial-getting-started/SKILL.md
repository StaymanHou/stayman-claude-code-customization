---
name: tutorial-getting-started
description: "First-run entry point for a brand-new user. Recommends auto permission mode (if available), asks new-project vs. existing-code, gets the user into the right directory, then points them to the matching tour arm skill to run directly in a fresh session (it does not run the walkthrough itself). The tour is a chain of session boundaries; a narrated real run (~10-15 min), not a demo reel."
argument-hint: "(no arguments — just run it)"
---

# Getting Started — the workflow-system tutorial

You are guiding a **brand-new user** through their first hands-on experience of the workflow
system. This skill is the **single entry point** for onboarding: it sets up permissions, asks one
question (new project or existing code), gets the user into the right working directory, and then
**points them at the matching tour skill to run in a fresh session** — it does **not** drive the
tour itself.

> **Flow authority.** The onboarding tour is a **chain of real session boundaries**, not one
> continuous dispatched session. The authoritative flow is
> `docs/lessons/tutorial-tour-session-chain-flow.md` — **read it before editing this skill.** In
> short: this skill (session A) sets up and hands the user off across a `/exit` → new session, where
> they run the tour **arm skill directly**; the arm runs in stepping first, then (after a
> handoff→restore→graduate cycle) the user replays it directly in a faster gear. This skill NEVER
> invokes the arm skill inline.

## Category

**`tutorial-*` — a standalone, user-invoked onboarding skill family.** This skill (and its two
sibling arm skills) is **NOT part of any workflow state machine**:

- It **owns no workflow state** and **emits no transition** — no `F`/`I`/`T`/`P`/`S` token, no
  `DEBUG-*` token, no `RETURN-TO:`. It is an entry point itself, not a workflow state and not a
  pulled sidebar.
- It **points the user to** one of two arm skills — `tutorial-greenfield-workflow-tour` or
  `tutorial-brownfield-workflow-tour` — which the user runs **directly, in a fresh session** after
  `/exit`ing this one. This skill does **NOT** invoke the arm inline (that would collapse the
  session-boundary chain the tour is built to teach — see the Flow authority note above). Handing
  the user off across a session boundary — telling them the exact skill to run next session — is the
  last thing this skill does.
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

The tour runs **in a fresh session that you'll start after this one** (see the Flow authority note
above — this skill hands you off across a session boundary; it does not run the tour itself). So the
job of this pre-flight is to get the user into the **right working directory** so that, when they
`/exit` and start the next session, they start it in the right place. This branches by which path
the user is about to take, so ask the new-vs-existing question (Step 1's fork) informally here first,
or cover both:

- **New project (greenfield):** pick a **working directory** for the tour to happen in — a new,
  empty folder is ideal (nothing of yours is nearby). The tour's arm skill will stamp its **own
  throwaway sample project** into a fresh disposable copy and work inside that, so nothing real is at
  risk — but the user should still be *somewhere deliberate* when the next session starts, not in
  their home dir or an unrelated repo. Have them `cd` there before they `/exit`:
  > *"Let's pick a spot for this. Make (or choose) an empty folder to work in and `cd` into it —
  > something like `mkdir ~/workflow-tour && cd ~/workflow-tour`. Don't worry about putting anything
  > in it: when you start the tour, it'll create its own small throwaway sample project there for us
  > to work on, so there's genuinely nothing of yours to lose. We just want you standing in a clean,
  > deliberate directory before we begin."*

- **Existing code (brownfield):** the tour must run **inside your real project's root directory** so
  the workflow operates on the right code. Have the user `cd` there before they `/exit`:
  > *"Since we'll work in your real repo: `cd` into your project's root directory now, so that when
  > you start the tour in a fresh session it's pointed at your actual codebase from the start."*

  **Git-safety pre-flight (brownfield only — the tour will make real edits to this repo).** Before
  sending the user off, protect their work. Check the repo's git state and act on it:
  - **If the directory is a git repo** (`git rev-parse --git-dir` succeeds): run `git status --short`.
    If there are **uncommitted or unstaged changes**, tell the user to deal with them first — the tour
    does real work on this repo, and unexpected changes could get tangled with theirs:
    > *"Quick safety check before we touch your real repo: you've got some uncommitted changes. I'd
    > **commit them first** (or `git stash` them) so the tour starts from a clean, recoverable point —
    > that's also what makes the replay-in-a-faster-gear trick at the end work cleanly. If you'd rather
    > not run the tour on this repo at all, a **safe copy** (`cp -r` / a fresh clone) or a **different,
    > less precious project** are both fine. Either way: don't run it on top of uncommitted work you'd
    > hate to lose."*
    If the working tree is **clean**, say so and proceed: *"Your repo's clean — good, the tour can run
    and you can always `git diff` / `git stash` to undo anything it does."*
  - **If the directory is NOT a git repo** (`git rev-parse` fails): recommend initializing one first,
    so there's an undo path:
    > *"This folder isn't under git yet. I'd **`git init` and make one commit** before we start, so the
    > tour's changes are easy to review and undo. It only takes a second and it's the safety net that
    > makes the rest comfortable."*

  (Both paths converge on the same next move: you'll `/exit` and **relaunch in this directory in
  `auto` mode** — see Step 2's handoff for the exact command. Greenfield needs no git-safety check —
  it works in a disposable throwaway copy, so there's nothing of the user's to protect.)

**About `auto` mode (why the relaunch below uses it).** Recommend the user relaunch the tour session
in **`auto`** permission mode: the tour really *runs* things (executes the sample, writes files, hands
off and restores), and in a stricter mode Claude Code prompts on every shell command, drowning the
beats the tour is built to show. `auto` is **low-friction AND safe** — file edits, shell commands, and
network calls run without routine prompts, but a **classifier still blocks anything genuinely
dangerous** (force-push, deploys, mass deletion, sending secrets out), so "you can trust it here,
nothing bad escapes" stays honestly true (unlike bypass-permissions, which has *no* guardrails — do
not substitute it). **The recommendation is acted on at relaunch (Step 2), not here** — this session
doesn't run anything, so there's nothing to gate yet. If `auto` isn't available to the user (it needs
a recent model — Opus 4.6+/Sonnet 4.6+/Fable 5 — and an allowing account), that's fine: they take the
tour in whatever mode they have and just click **Yes** a few more times; the tour works identically.

### Step 1 — Ask: new project, or existing code?

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

**The first run of the tour is in `stepping` drive mode — but the ARM skill sets that, not this
dispatcher.** Because this skill hands the user off to a fresh session (it does not drive the tour),
the drive mode is established by the arm skill *when the user runs it next session*: the arm asks
"first time through, or replaying?" on entry, and a first run defaults to stepping silently. So your
job here is **not** to set the mode — it's to make sure you don't spoil it:

- **Do NOT present a drive-mode menu here, and do NOT mention that drive modes (autopilot/FSD) even
  exist.** The whole point of the first run is that the user *sees* the workflow pause and ask them
  (beat B) — the tunable-pauses reveal is saved for the Step-8 graduation, and naming faster gears
  now would spoil it. Drive mode (a numbered menu the workflow itself presents) is the arm skill's
  concern on entry, not this dispatcher's.

(Stepping is the **workflow drive mode** — how the *workflow* chains its steps — which is distinct
from the **permission mode** (`auto`) the user relaunches into at Step 2 — how *Claude Code* gates
tool calls. The two are independent and both apply. This distinction matters, but you don't act on
drive mode here; you just avoid raising it.)

### Step 2 — Point the user to the matching arm skill, then hand off across a session boundary

You do **NOT** invoke the arm skill inline. Based on the user's choice, tell them the **exact arm
skill to run**, then walk them across the session boundary: `/exit` this session, start a fresh one
**in the working directory from Step 0**, and run that arm skill **directly**. This is the first link
in the session-boundary chain the tour teaches (see the Flow authority note at the top).

- **New project → point them to `/tutorial-greenfield-workflow-tour`.** It stamps its own tiny
  runnable sample (the *agent* does this automatically — the user never runs a scaffolder) and drives
  the greenfield walkthrough: structure on a blank page — hierarchy taste, the state file, the verify
  pause, the grounding beat, the SURFACE beat, then the handoff→restore bookend and the drive-modes
  graduation reveal.
- **Existing code → point them to `/tutorial-brownfield-workflow-tour`.** It drives the brownfield
  walkthrough on the user's real repo (`/init` if the project isn't set up yet, product-workflow
  reconstructs the strategic layer from the code, then one small real unit of work through the verify
  pause, closing with the same handoff→restore bookend and drive-modes reveal). **Brownfield only:
  make sure you already ran the git-safety pre-flight in Step 0's brownfield branch** (clean/commit the
  repo, or `git init` if it's not under git) before sending the user off — the tour makes real edits.

**The handoff (deliver close to verbatim, filling in the chosen arm skill + the Step-0 directory):**

> *"That's the setup done. The tour itself runs in a fresh session — same clean-slate move the
> workflow uses everywhere, and you'll feel why later. So:*
> 1. ***`/exit` this session.***
> 2. ***Relaunch in that folder, in `auto` mode*** *(`cd` there first if you're not already, then
>    `claude --permission-mode auto` — that's the low-friction-but-safe mode I mentioned, so the tour
>    runs without a prompt on every step; if `auto` isn't available to you, just launch normally —
>    the tour works the same, you'll click Yes a bit more).*
> 3. ***Run `<the chosen arm skill>` directly*** *— it takes over from here and walks you through the
>    whole thing.*
> *See you on the other side."*

Once you've delivered the handoff, **this skill is done.** You do not run the arm, and you do not
continue past this point — the user's next session, running the arm skill directly, is the rest of
the tour.

## Transitions

**None.** This skill emits **no** workflow transition (no `F`/`I`/`T`/`P`/`S` ID), no `DEBUG-*`
token, and no `RETURN-TO:`. It is a `tutorial-*` entry point: it runs Steps 0–2, points the user at
the matching arm skill, hands off across a session boundary, and ends (it does **not** invoke the arm
inline — see the Flow authority note at the top). The state-machine "three places in sync" rule does
not apply here — there is no transition to keep in sync. (Behavioral scenarios and the
`tutorial-`-prefix structural pin are added by WP7e, separately.)
