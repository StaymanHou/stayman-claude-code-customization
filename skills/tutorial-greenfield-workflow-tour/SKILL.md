---
name: tutorial-greenfield-workflow-tour
description: "Greenfield arm of the getting-started tour: drive one small real unit of work end-to-end on a tiny sample project, so a brand-new user sees the workflow give structure to a blank page. A narrated real run (~10-15 min), not a demo reel. Run directly in a fresh session (tutorial-getting-started points you here)."
argument-hint: "(no arguments — run directly in a fresh session; tutorial-getting-started points you here)"
---

# Greenfield tour — structure on a blank page

You are driving the **greenfield arm** of the getting-started tour. The user is brand-new to the
workflow system, mildly skeptical, and just chose "new project." Your job is to walk them through
**one small real unit of work end-to-end** on a tiny sample, narrating each beat so they *see* what
the workflow is good at — without it ever feeling like a canned demo.

> **Flow authority — read before editing.** This arm is **always run directly, in its own session**
> (`tutorial-getting-started` points the user here and hands off across a `/exit`; it does NOT invoke
> this arm inline). The full flow — a chain of session boundaries, and how first-run vs. replay is
> distinguished — is `docs/lessons/tutorial-tour-session-chain-flow.md`. That doc is the source of
> truth; conform to it.

The headline this path sells: *"I have an idea but I always devolve into unstructured vibe-coding
and lose the plot — this gives me structure on a blank page."*

## Category

**`tutorial-*` — a standalone onboarding skill (greenfield arm).** Like the rest of the family, it
**owns no workflow state** and **emits no transition** — no `F`/`I`/`T`/`P`/`S` token, no `DEBUG-*`
token, no `RETURN-TO:`. It is **run directly by the user in a fresh session** (after
`tutorial-getting-started` points them here and they `/exit` into a new session — it is NOT invoked
inline by the dispatcher; see the Flow authority note above); it **runs the tour to its close**.
Minimal frontmatter (`name` / `description` / `argument-hint`); no `skills:` list, no `tools:` key.
See `workflow-system/product/onboarding-flow-spec.md` for the design contract.

## Framing (inherited — keep it honest)

`tutorial-getting-started` already set the honest expectation (a real, guided **~10–15 minute** run,
not a scripted demo reel). The user should already be in **`auto`** permission mode if it's available
to them — the dispatcher recommended they relaunch this session in `auto` (that's why the tour runs
without a prompt on every step); if `auto` wasn't available they're in whatever mode they have and
will just approve a few more prompts, which is fine. You don't need to repeat all of it — but keep
every beat honest: when you say "watch it check the running code," **actually run and check it**.
**Never** compress the promise into a "quick 5-minute" claim.

## On entry — first run, or replay? (ask this FIRST, before anything else)

You are **always run directly** (the user typed `/tutorial-greenfield-workflow-tour` in a fresh
session — the dispatcher never invokes you inline). So you cannot assume any prior setup ran, and you
must establish **which of two runs this is** before you stamp the sample or drive a single beat. Ask
one line:

> *"Quick check before we start — is this your **first time** through this tour, or are you
> **replaying** it to try a faster gear (autopilot / FSD)?"*

**If FIRST RUN** → run the whole tour in **stepping** drive mode, and **do NOT mention that drive
modes exist** — not the word "autopilot," not "FSD," not "stepping is a setting." The first run's
entire payoff is that the user *sees* the workflow pause and ask them (beat B, Step 4); the
tunable-pauses reveal is saved for the Step-8 graduation, and naming faster gears now would spoil it.
Just proceed to the environment setup below. (You silently drive in stepping — you don't announce the
mode.)

**If REPLAY** → the user already took the stepping run and graduated; now they want to *feel* a faster
gear. **Present the drive-mode menu yourself** — drive mode is a **numbered menu the workflow shows,
not a slash command you type**, and because this replay path enters you directly (bypassing
`/session-start` and `/session-restore`, the two places that normally show it), *you* are the one who
must present it:

> *"Great — replay it is. Drive mode is how much the workflow chains on its own between steps. Pick
> your gear:*
> *  **1  Stepping** — pause after every step (what you did the first time)*
> *  **2  Orchestrated** — standard: chains the routine steps, pauses at the judgment ones*
> *  **3  Autopilot** — only stops at the human checkpoint (verify-human)*
> *  **4  FSD** — no stops, even skips verify-human*
> *Type 1–4 (or Enter for **3 Autopilot** — the most instructive contrast with the stepping run you
> already saw)."*

Record the chosen mode in the tour's WIP frontmatter (`drive_mode: stepping | orchestrated |
autopilot | fsd`) and **run the tour in that mode** — let it chain per the mode's pause policy so the
user feels exactly which stops each gear keeps and which it drops. Then proceed to the environment
setup below (the sample is stamped the same way on a replay — a fresh throwaway copy, nothing carries
over).

## The environment — a tiny runnable sample (from WP7c; redesigned in WP7i)

This arm runs inside a **tiny, shipped, runnable sample project** that ships **inside this skill's own
directory** at `scripts/sample/` (so it travels with the skill wherever it's installed — see the
portability note below) — a small **command-line `todo` list** (a dispatcher plus one module per
subcommand: `add` / `list` / `done`, over a plain-text store). It's deliberately more than a one-liner:
a couple of real modules and a visible data file give planning, verify-self, and SURFACE something real
to bite on. **You (the agent) stamp a fresh copy before Step 1 — the human never runs the scaffolder
themselves.** Run it yourself; it stamps a throwaway copy so the user's real edits, the SURFACE, and
the handoff/restore all happen against something disposable, never the shipped source. The scaffolder
lives beside this skill — invoke it by its installed path:

```bash
~/.claude/skills/tutorial-greenfield-workflow-tour/scripts/new-sample.sh   # you run this; prints the fresh copy's path + a run hint
```

(It resolves its own sibling `scripts/sample/` from the script's own location, so it works from
wherever the skill is installed — the repo checkout or a `~/.claude/` symlink.)

Then `cd` into the printed path yourself and drive the tour from there (nothing real to lose) — the
user doesn't type this; you do it and tell them where you've set things up. Two properties of the
sample are load-bearing, and the two staged beats below depend on them directly:

- **Runnable with one observable outcome** — `./todo add "buy milk" && ./todo list` prints exactly
  `1. [ ] buy milk` and exits 0. This is what the staged **grounding** beat (Step 5) has the agent
  *run and check* (PASS/FAIL against that exact line).
- **A planted, authentic-feeling tangent** — `./todo done <index>` doesn't range-check the index, so
  `./todo done 99` on a short list reports success and changes nothing; `sample/README.md` and
  `lib/done.sh` both flag it under a `TODO`. It is a *real* small bug (not a fake breadcrumb), so the
  staged **SURFACE** beat (Step 6) has a reliable, honest rabbit-hole to catch.

See `scripts/README.md` (in this skill's own directory) for the scaffold's shape and canonical
invocations.

### Say what the project is, upfront (before Step 1 — WP7i)

Right after you stamp the fresh copy and `cd` in — **before** the Step 1 framing line — tell the
user in a sentence or two *what this sample project is and what you're about to build on it*, so the
run doesn't open on an unexplained pile of files. Keep it concrete and short:

> *"Here's your sandbox: a tiny command-line to-do list — a `todo` script that routes three
> subcommands (`add`, `list`, `done`) over a plain-text file, `todos.txt`. It already runs. We're
> going to add one small thing to it end-to-end — nothing you can break matters here, it's a
> throwaway copy — and you'll watch the workflow give that little bit of work real structure. Take a
> quick look: `ls` and `cat todos.txt` if you like, then we'll start."*

This grounds the user in the *what* before the walkthrough shows them the *how*. It is framing copy
(beat **G**'s neighbor), not a staged beat — one short orientation, then move into Step 1.

## The walkthrough (spec §3-greenfield spine)

Drive these beats in order. Beat disposition per spec §7 is annotated on each — **STAGED** beats are
guaranteed and you engineer them; **BEAT** beats occur naturally along the work thread (just don't
skip them); **FRAME** is a one-line reframe, not a scene.

**Drive mode depends on the run type you established at entry:**
- **First run → `stepping`.** Run the whole tour in stepping and do not change it mid-tour: stepping
  pauses after every skill so the human-pause beat (Step 4) stays *visible*, which the Step-8
  graduation reveal depends on. Don't name the mode to the user on a first run.
- **Replay → the gear the user picked** at the entry menu (orchestrated / autopilot / FSD). Let it
  chain per that mode's pause policy — the whole point of the replay is to *feel* the faster gear, so
  don't force stepping. The beats are the same; what changes is how many of them pause.

(This is the workflow drive mode; it is independent of the `auto` permission mode the user relaunched
into — both apply.)

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
And even here, you can redirect it. You're not watching it run away with your codebase."* On a **first
run** the tour is in **stepping**, so this pause is unmistakably *visible* — do not autopilot past it.
On a **replay** in a faster gear, this gate is exactly the contrast the replay exists to show
(autopilot still stops here; FSD skips it) — narrate whichever the current gear does so the user feels
the difference.

### Step 5 — Grounding (STAGED — verify-self on the runnable sample)
**This is a staged beat — engineer it.** Have the agent run the sample and observe it via
`verify-self`: it actually executes the runnable outcome and reports **PASS/FAIL** against a real
observable. The user watches it **check reality instead of guessing**.

**The concrete check:** run `./todo add "buy milk" && ./todo list` in the sample copy and confirm
`list`'s stdout is exactly the one line `1. [ ] buy milk` (exit 0). That single, checkable line *is*
the observable outcome — the agent runs it, compares the real output to the claim, and reports
**PASS** (or **FAIL**, and back-loops) rather than just asserting "done." (`sample/README.md` states
this expected output, so the check is against a documented contract, not an invented one.)

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

**The concrete tangent:** the sample's `todo done` doesn't range-check its index — `./todo done 99`
on a short list reports `marked item 99 as done` and exits 0, but changes nothing (there is no item
99). `sample/README.md` and `lib/done.sh` already flag it under a `TODO`. It's a genuine small bug
that's *tempting* to fix right now but isn't the thing we set out to build. That is exactly the
rabbit-hole: the agent notices it, runs **SURFACE** to write it to the backlog so it survives, and
stays on the actual task. (It's a real defect, not a staged breadcrumb — which is what keeps this
beat honest for a skeptic.)

**Pre-frame it:**
> *"Here's a thing that would normally derail me for an hour. Watch what it does — instead of
> chasing it, it writes it down in the backlog so it's not lost, and stays on the task we're
> actually doing. That backlog is where your good-but-not-now ideas go to survive."*

### Step 7 — Bookend 1: the boundary (STAGED — handoff → restore)
**The emotional peak** — placed near the end so there's real state to lose and recover. By now the
user has a WIP state file (from Step 3), a real check that ran (Step 5), and a backlog entry (Step
6). That accumulated state is what makes this beat land: there is genuinely something to reset the
context window around and get back intact.

**The primary value to sell here is context-window management** — NOT "close the laptop till
tomorrow." The real pain this solves: a long session fills the context window, and the built-in
`/compact` squeezes it by *summarizing the conversation* — which is exactly when the agent loses the
plot (drops a decision, forgets the plan, starts tunnel-visioning on the last thing it saw). Handoff
→ restore is the **curated alternative**: you deliberately reset the window to near-empty, and the
load-bearing context (the plan, the WBS, progress, open blockers, the backlog note) comes back **not
because it was crammed into a summary, but because it was written to disk and gets re-read fresh**.
Cross-session continuity ("come back tomorrow") is a real *secondary* benefit — but the headline is
"free up the window without losing the plot, better than `/compact`."

Drive it as three scenes, narrating each move just before you make it so the user follows what's
happening. (On a **first run** this lands in the tour's stepping cadence; on a **replay** in a faster
gear, the handoff→restore bookend still runs and still matters — the workflow persists state to disk
regardless of drive mode — so narrate it the same way; if anything, it's a good moment to note "even
in autopilot, it still writes the handoff to disk before you leave.")

**Scene 1 — check the window, pre-frame, then hand off.** First, have the user *look at their current
context usage* (the context-left indicator in the Claude Code UI) so the before/after is concrete:
> *"Here's the moment that sold me — and it's not really about walking away, it's about your context
> window. Glance at how much context you've got left right now; we've done real work, so it's filled
> up. Normally you'd `/compact` to reclaim it — but `/compact` works by *summarizing our chat*, and
> that's the exact moment the agent quietly forgets a decision or loses the thread. Watch a cleaner
> way. I'll hand the session off, then we start completely fresh — and nothing gets lost."*

Then run **`/session-handoff`**. Point at exactly what it does as it does it: it writes a small
pointer file, `<proj-dir>/workflow-system/state/.session.md`, that records the workflow, the step,
and the next action — and it drops a one-line marker into your WIP state file too. *"That's it —
one tiny pointer. It doesn't copy your whole plan into itself; it points at the files on disk that
already hold it. Everything needed to bring you back is in your project, not in the model's head."*

**Scene 2 — reset the window (the real point).** This is the beat, so make it real if you can:
> *"Now the part that matters: we throw the context window away. `/exit` this session and start a
> brand-new one — a genuinely empty window, none of our conversation in memory. This is what you'd
> reach for instead of `/compact` when the window's getting heavy and you don't want to risk a lossy
> summary."*

(The user *can* actually `/exit` and relaunch here for the full effect — and since restore reads off
disk, it genuinely works. If they'd rather not break the tour flow, narrating the reset makes the
point too: the claim is that nothing depends on this conversation surviving.)

**Scene 3 — restore, then check the window again.** Run **`/session-restore`**. Narrate what it
pulls off disk: it reads that `.session.md` pointer, re-opens the WIP state file, and reconstructs
where you were — the workflow, the step, the next action, any open blockers — *without* replaying the
conversation. Then land the beat two ways — the window, then the plot:
> *"Look at your context usage now — nearly empty again, the whole window reclaimed. And yet:
> the plan, the state, the next step, the backlog note — all back. Notice **where** it came from:
> that same plain file you opened earlier in the tour. It didn't remember you from our chat, and it
> didn't summarize anything — it re-read your work off disk. So it comes back with the *full* detail,
> not a lossy compression. That's the difference from `/compact`: you reset the window to keep working
> fast, and the agent doesn't tunnel-vision or lose the big picture, because the big picture was never
> in the window — it's in your repo. (Same reason you can close the laptop mid-task and pick up
> tomorrow: it's just re-reading the files.)"*

This is the payoff for beat A (state-is-a-file, Step 3): because the state was always a real file,
resetting the window — or walking away and coming back — is just re-reading it. Don't rush the
reveal — for the target user who's watched a compacted session lose the thread, this is often the
beat that converts.

### Step 8 — Bookend 2: the graduation, LAST + un-pushed (STAGED reveal) → close

**This step is MODE-AWARE — branch on the drive mode the tour actually ran in** (the one established
at the "On entry" question). The two branches are mutually exclusive; deliver exactly one.

#### Branch A — FIRST RUN (stepping): reveal the faster gears
Use this when the tour ran in **stepping** (the first run). **Deliberately the last thing, deliberately
not pushed.** The whole tour ran in stepping precisely so the user *saw* the pause in Step 4. Only now
— after they've watched it pause, ask, check reality, and survive a walk-away — reveal that the pauses
are tunable:

> *"One last thing, now that you've seen it actually work. You watched it stop and ask you back in
> Step 4 — that pause is a setting, not a law. There are faster gears: **autopilot** chains the safe
> steps for you and only stops at the human checkpoints; **FSD** skips even those. They're real, and
> once you trust the workflow they're worth it."*

Then immediately **un-push it** — the honest counterweight is the point of putting this last:

> *"But I'd genuinely leave those alone for now. The pause you just saw — where it asked before
> moving on — is the single most valuable thing here while the workflow is still new to you. Earn
> the trust first, then shift gears. **Not recommended yet.**"*

(Do **not** demonstrate autopilot/FSD live in the tour — showing it in action would hide the very
beat B the tour is built around. This is a *named* reveal, not a staged run.) Then extend the replay
invitation below (Branch A's close), which sends the user to *feel* a faster gear on a fresh run.

#### Branch B — REPLAY (already in a faster gear): acknowledge, don't re-reveal
Use this when the tour ran in **autopilot / FSD** (a replay — the user already saw the stepping run
and this graduation once). Do **NOT** re-deliver the "pauses are tunable" reveal (they know) and do
**NOT** re-invite a replay (they're already doing it). Instead, name what they just *felt* — the whole
point of the replay:

> *"So — that's the same tour you did in stepping, but this time in <the gear they picked>. Notice the
> difference: it chained the routine steps on its own instead of stopping at each one, and <if
> autopilot:> it still stopped at the human checkpoint — the verify step — because that's the one
> pause worth keeping. <if FSD:> it didn't even stop there — that's FSD: full speed, no checkpoints.
> Now you've felt both ends. Most people settle somewhere in between: stepping while a workflow is new,
> a faster gear once they trust it. You've got the whole range."*

Then **close** — no un-push, no replay invite (both are first-run moves). A short "you've now seen it
both ways; use whichever gear fits the work" is the right note. Skip straight to the "what we did NOT
demo" close below (it applies to both branches).

**Then (Branch A only) extend a highlighted replay invitation** — the honest way to let the user
*feel* those faster
gears without demoing them live here (which would hide beat B). The tour stays stepping to its end;
the faster gears are something they go try **on a fresh run**, now that they know what the pauses are
protecting:

> **▶ Want to feel the difference? Take this exact tour again in a faster gear.**
> *"You just did the whole thing in stepping mode — pausing at every step so you could watch. Now
> that you've seen where it stops and why, run it once more and let it move — and do it the way you'd
> start any fresh piece of work: cross a real session boundary. `/exit` this session and open a
> brand-new one (the same clean reset you just watched restore recover from). In that new session,
> run **`/tutorial-greenfield-workflow-tour`** directly — the tour skill itself, not the
> getting-started intro. It'll ask whether you're replaying, and when you say yes it'll show you a
> little menu of gears — pick **autopilot** (chains the safe steps, still stops at the human
> checkpoint) or **FSD** (skips even that). I'll spin up a fresh throwaway sample for you again
> automatically — nothing you did carries over. Same tour, same kind of sample — you'll feel exactly
> which stops autopilot keeps and which FSD drops. That contrast, on work you already understand, is
> the fastest way to learn where you're comfortable handing over the wheel."*

(This is still a *named* invitation, not a live demo — the user drives the faster run themselves in a
new session, so this run's beat B stays intact. Frame it as "go try it," never "watch me autopilot."
Three mechanics that must stay correct: **(1)** the replay re-enters at the arm skill
`/tutorial-greenfield-workflow-tour` **directly, NOT `/tutorial-getting-started`** — the dispatcher
would re-force stepping and re-ask the path fork, both of which a faster-gear replay is moving past;
**(2)** it's a **session-boundary crossing** (`/exit` → new session), echoing the handoff→restore
beat the tour just taught — do NOT frame it as "skip the intro and keep going in this session," there
IS no dispatcher in the replay session; **(3)** the **gear is chosen from the arm's own on-entry
menu** (the arm asks "replaying?" then presents the 1–4 drive-mode menu — see this skill's "On entry"
section), not pre-set by the user, and **the human never runs `new-sample.sh` themselves** — the arm
stamps the fresh copy on entry, exactly as it did for this run.)

**Then close by naming what you did NOT demo** *(BOTH branches land here — Branch A after its replay
invite, Branch B directly after acknowledging the gear)* — one or two lines, framed as "here's what's
here when you're ready," never staged (these are delayed-gratification and would feel fake if forced):

> *"Two things we didn't get into, so you know they're there:*
> - *the full **hierarchy** — product → feature → task all live in this same kind of on-disk record,
>   so a big initiative and a one-line fix use the one system;*
> - *and it **learns you** — a reflect/capture step at the end of sessions quietly records your
>   preferences and corrections, so it fits you better next time than it did today.*
>
> *That's the tour. You steered, it kept the plot, and it's all sitting in files you own. Go build
> something real — point it at your own repo next time with the existing-code path."*

That closing line reinforces beat **G** one final time (you kept the wheel) and hands the user back
to their real work — which is the whole value prop. **The tour ends here** — once you've delivered
the close, there is nothing further to invoke and no transition to emit; the run is complete (see
`## Transitions`).

## "Don't force it" (spec §7 — binding)

In this greenfield arm, **only** these beats are guaranteed **STAGED**: A (state-is-a-file),
B (human pause), the **grounding** beat (verify-self on the sample), the **SURFACE** beat (planted
tangent), the **handoff→restore** bookend, and the **drive-modes** reveal. Everything else — the
hierarchy taste, grounding-as-named-in-Step-2, reflect/capture — is **framed or named, never
staged**. Staging a beat that can't be staged authentically costs this skeptical audience more trust
than the aha earns.

## Transitions

**None.** This skill emits **no** workflow transition (no `F`/`I`/`T`/`P`/`S` ID), no `DEBUG-*`
token, no `RETURN-TO:`. It is the greenfield arm of the `tutorial-*` family: **run directly by the
user in a fresh session** (`tutorial-getting-started` points them here across a `/exit` — it does
NOT invoke this arm inline; see the Flow authority note at the top), it drives the walkthrough to its
close and ends. The state-machine
"three places in sync" rule does not apply (no transition to sync). Behavioral scenarios and the
`tutorial-`-prefix structural pin are added by WP7e.
