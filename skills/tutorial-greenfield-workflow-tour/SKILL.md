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

### A clean boundary inside the tour is real — narrate it, don't offer it

This tour drives a **real** feature (or task) workflow to a **real** terminal close. When that close
lands — `feature-finalize` / `feature-refactor` / `task-close` → `session-reflect` — the state machine
correctly sees a **clean workflow boundary**, and the modeled session-boundary exit chain (**`S22`** on
the no-learning arm, **`S23`** after a `session-capture` save) is **AUTO in all four drive modes**.

**That reading is correct, and the boundary is genuine — so do not pretend otherwise.** But inside a
tour run the handoff is **not yours to take and not yours to offer**: the tour already performs one
handoff as a scripted teaching beat (Step 7), and the user came here for the tour, not for a decision.
So at any clean boundary inside the run:

- **Run reflect normally** — it is a real beat and part of what the tour is showing.
- **Say what the boundary means, in one or two sentences** — that in the user's *own* project this is
  exactly where the chain writes the handoff on its own, so the next session starts with the plot
  intact. This is a **teaching moment, not a decision point**: the tour is demonstrating the mechanism,
  so name it rather than skipping past it silently.
- **Then continue to the next tour step.** Do **not** invoke `/session-handoff`, do **not** write
  `workflow-system/state/.session.md`, and do **not** present a "continue the tour, or hand off now?"
  choice. There is only one sensible answer mid-run, so presenting a fork is friction, not service.
- **This holds in every drive mode**, including autopilot and FSD. It is a narrow, tour-scoped
  precondition on an existing edge — **not** a new transition, and **not** a change to `S22`/`S23`
  for real work outside a tour.

Illustrative shape (adapt the wording; keep the substance):

> *"Notice where we just landed — that's a real clean boundary. In your own project this is where the
> workflow writes the session handoff by itself, so tomorrow's session starts with the whole plot
> intact. You watched that work back in Step 7, so we won't do it twice — let's carry on."*

The one handoff this tour *does* perform is its **own staged one in Step 7**, scripted deliberately as
the teaching beat. See Step 7, which draws the distinction explicitly.

> **Why this exists (a real misfire, 2026-07-24 walkthrough).** Per the designed chain
> (`docs/lessons/tutorial-tour-session-chain-flow.md`), **Session B ends with `/session-handoff`** —
> that staged bookend IS the tour's handoff, and the design has no separate "feature close" beat. In
> the live run the arm performed that handoff, the user `/exit`ed, and `/session-restore` opened
> Session C. *Then* the real in-tour feature's workflow reached `feature-finalize → session-reflect`
> **inside Session C** — a second, genuine clean boundary the designed sequence never anticipated,
> sitting between Step 7 and Step 8. The agent read `S22` correctly and surfaced it as a fork:
> "Continue the tour" vs. "Hand off now." The operator answered *"continue the tour"*, and afterwards
> identified the real defect: **the framing.** The boundary was real and the auto-chain reading was
> right; what was wrong was handing the user a decision about a mechanism the tour had *just
> demonstrated one step earlier*. The fix is to **narrate** such a boundary — name what a real project
> would do here — not to suppress it, and not to re-offer a beat already spent.

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

**Record `drive_mode: stepping` in the tour's WIP frontmatter anyway** — same as the replay branch does
below, and for a concrete reason: the mode has to survive the Step-7 session boundary. Written down, the
handoff pointer carries it and `/session-restore` brings the run back in stepping; left unwritten, restore
finds nothing, falls back to its own default, and Session C silently continues in a *different* mode while
announcing it — which both breaks the tour's cadence and spoils the Step-8 reveal early. **Recording is not
revealing:** this is a line in a file, not a sentence to the user. The prohibition above is unchanged — you
still never say the word.

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
setup below (the sample is stamped the same way on a replay — a fresh copy, nothing carries over).
**On a replay, expect the empty-cwd guard to fire:** the user is most likely standing in the directory
from their previous run, which now holds that run's sample and workflow files. That's the normal case,
not an error — ask them for a fresh empty directory exactly as the environment section describes, and
mention *why* ("so this run starts clean and nothing from last time bleeds in"). Never `--force` over
their previous run's work.

## The environment — a tiny runnable sample (from WP7c; redesigned in WP7i)

This arm runs inside a **tiny, shipped, runnable sample project** that ships **inside this skill's own
directory** at `scripts/sample/` (so it travels with the skill wherever it's installed — see the
portability note below) — a small **command-line `todo` list** (a dispatcher plus one module per
subcommand: `add` / `list` / `done`, over a plain-text store). It's deliberately more than a one-liner:
a couple of real modules and a visible data file give planning, verify-self, and SURFACE something real
to bite on. **You (the agent) stamp a fresh copy before Step 1 — the human never runs the scaffolder
themselves.** Run it yourself; it stamps a fresh copy so the user's real edits, the SURFACE, and
the handoff/restore all happen against something disposable, never the shipped source.

**Stamp it into the user's current working directory — do NOT stamp into a temp dir and `cd` away.**
The user was told in the pre-flight to `cd` into an empty folder precisely so the tour's files land
*where they're standing*. Files they can see with a plain `ls`, in a directory they chose, are part of
the value prop (beat A — "your state is a real file you own"); a path under `/var/folders/…` that you
`cd`'d into on their behalf undercuts it and leaves them unsure where their work lives. The scaffolder
lives beside this skill — invoke it by its installed path, targeting the cwd:

```bash
~/.claude/skills/tutorial-greenfield-workflow-tour/scripts/new-sample.sh --dest .   # you run this, in the user's cwd
```

(It resolves its own sibling `scripts/sample/` from the script's own location, so it works from
wherever the skill is installed — the repo checkout or a `~/.claude/` symlink. `--dest .` stamps the
sample's contents **flat** into the current directory — `todo`, `lib/`, `todos.txt`, `README.md` at the
top level — so there's no nested folder to `cd` into and no path for the user to memorize.)

**The cwd must be empty — and the scaffolder enforces it.** `new-sample.sh` refuses a non-empty
destination and **writes nothing** when it refuses (exit 1, message naming the destination). That guard
is deliberate: it's what makes "the tour never clobbers your files" true rather than merely promised.
If it fires, **do not** reach for `--force` and do not silently fall back to a temp directory. Stop, **show the
user exactly what is in the way**, and offer them two equally-good ways forward.

**Two things happen before you ask anything.** First, **run `ls -A` and put the real list on screen** — the user
cannot make this decision from a description; they need to see the actual filenames. Second, **run
`git rev-parse --is-inside-work-tree` — if it prints `true`, do NOT offer to clear the directory at all.** That
is a pre-check, not a veto you apply afterwards: a repository must never see the delete offer in the first place
(full rule under "Two absolute limits" below). In that case skip the two-option script entirely and say this
instead — don't improvise a one-option variant of it:

> *"Before I set up the sample — this directory isn't empty, and it's also a git repository, so I'm not going to
> clear it. Let's use a fresh folder instead: `mkdir ~/workflow-tour && cd ~/workflow-tour` (any empty directory
> works), then tell me when you're in and I'll stamp the sample."*

With both checks done, offer both options:

> *"Before I set up the sample — this directory isn't empty, and I won't write on top of what's here. This is
> what's in it:"*
>
> ```
> <the real `ls -A` output>
> ```
>
> *"Two ways forward, both fine:*
> *  **1** — I clear this directory out (everything listed above is deleted) and stamp the sample here.*
> *  **2** — You point me at a different empty folder, e.g. `mkdir ~/workflow-tour && cd ~/workflow-tour`, and
>   tell me when you're in.*
>
> *Which would you like? If you want option 1, say so explicitly — I won't delete anything on a maybe."*

**The clearing option is destructive, so it is governed by four hard rules. Do not soften any of them.**

1. **Show before asking.** The `ls -A` listing goes on screen *before* the question. Never ask "shall I clear
   it?" without the user seeing what "it" contains.
2. **Explicit confirmation only.** A bare "go", "proceed", "ok", "continue", "yes do it", or silence is **not**
   consent to delete — those are answers to the tour's general forward motion, not to this. You need the user to
   choose option 1 (or say "clear it" / "delete them") **in response to this question**. If their reply is
   ambiguous, ask once more; do not resolve ambiguity toward deletion.
3. **Option 2 is an equal, not a fallback.** Present it as a genuine peer choice. Many people will prefer a new
   folder, and nothing about the tour is worse for it.
4. **Never `--force`, never auto-delete, never a temp dir.** Do not pass `--force` to `new-sample.sh` under any
   circumstances — the refusal is the safety property, not an obstacle. Do not delete anything before the user
   picks option 1. Do not silently relocate to `$TMPDIR` (that breaks the "your state is a real file you own"
   beat this whole path depends on).

**Two absolute limits on what "clear the directory" may touch:**

- **If the cwd is a git working tree, refuse to clear it — take option 2 instead.** Check with
  `git rev-parse --is-inside-work-tree` before offering option 1 at all; if it says `true`, don't offer it. Say
  *"this folder is a git repository, so I'm not going to clear it — let's use a fresh folder instead"* and go to
  option 2. Someone's repository is never disposable, and this tour has no business deleting one.
- **Delete only the *contents* of the cwd, and nothing above it.** No `..`, no `~` expansion, no absolute paths
  outside the directory you are standing in. If you cannot express the deletion as "remove the entries `ls -A`
  just listed, in this directory," stop and take option 2.

**On decline — or on any ambiguity — nothing is touched.** If the user picks option 2, changes their mind, gives
an unclear answer, or just starts talking about something else, every file stays exactly where it was. Then
re-run the stamp once they're in an empty folder.

This whole branch should be uncommon on a **first** run — the Step-0 pre-flight in `tutorial-getting-started`
already asks them to be standing in an empty directory. It is a routine branch on a **replay**, though: the user
is usually standing in their previous run's folder, which is full of the last sample. That is exactly the case
option 1 exists for, and it is why the option is worth offering rather than just refusing. Note you do **not**
need to `cd` anywhere after a successful stamp: the
files are already in the working directory you're both in. Tell the user that plainly ("everything's
right here in this folder") and let them `ls`.

Two properties of the sample are load-bearing, and the two staged beats below depend on them directly:

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

Right after you stamp the fresh copy — **before** the Step 1 framing line — tell the
user in a sentence or two *what this sample project is and what you're about to build on it*, so the
run doesn't open on an unexplained pile of files. Say plainly that it's **right here in this folder**
(that's the point of stamping into their cwd — they can see it without going anywhere). Keep it
concrete and short:

> *"Here's your sandbox, and it's right here in the folder you're standing in — a tiny command-line
> to-do list: a `todo` script that routes three subcommands (`add`, `list`, `done`) over a plain-text
> file, `todos.txt`. It already runs. We're going to add one small thing to it end-to-end — nothing you
> can break matters here, it's a throwaway copy — and you'll watch the workflow give that little bit of
> work real structure. Take a quick look: `ls` and `cat todos.txt` if you like, then we'll start."*

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

> **This is the tour's ONE handoff — and per the designed chain it is the terminus of this session.**
> `docs/lessons/tutorial-tour-session-chain-flow.md` has Session B ending with `/session-handoff`; the
> user then `/exit`s and `/session-restore` opens Session C for Step 8. So *this* step writes
> `.session.md` on purpose, as the teaching beat, because there is now real accumulated state to lose
> and recover.
>
> **A second clean boundary can still show up later in the chain** — most commonly the in-tour
> feature's own `feature-finalize → session-reflect`, which may land in Session C between this step and
> Step 8. That boundary is **real**, and the exit chain (`S22`/`S23`) reads it correctly. Do **not**
> take it and do **not** offer it as a choice: **narrate** it instead — one or two sentences naming
> what a real project would do there — then continue (see "A clean boundary inside the tour is real"
> under `## Category`). The rule of thumb: the tour writes `.session.md` **once**, here; anywhere else,
> you talk about the boundary rather than acting on it.
>
> **This pointer brings the session back to THIS SKILL, not to the inner workflow's next state.** The
> handoff you write here carries `tour: greenfield` + `tour_step: 8` and sets
> `resume_skill: /tutorial-greenfield-workflow-tour`, so `/session-restore` hands Session C back to *you*
> and you finish the run — see Scene 1 for the exact fields. That is what makes the guard above actually
> reachable: the two rules in this blockquote live in *this* file, so they only bind if this file is what
> gets reloaded. Point `resume_skill` at the inner workflow instead and Session C comes back holding two
> competing continuations — finish the feature, or play Step 8? — with nothing in context that knows the
> answer. (That exact mis-write is what produced the "continue the tour, or hand off now?" fork on the
> 2026-07-24 run.)

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

**Supply these four fields to the handoff** (it treats the tour ones as optional and writes them only when
a `tutorial-*` skill asks — see `session-handoff` SKILL.md §2, "Tour-driven handoffs"):

| Field | Value | Why |
|---|---|---|
| `tour:` | `greenfield` | Marks the pointer as belonging to a tour run, so the general session skills narrate a later boundary instead of offering it as a choice. |
| `tour_step:` | `8` | The step to resume **at** — Step 7 is finishing, Step 8 is next. |
| `resume_skill:` | `/tutorial-greenfield-workflow-tour` | Session C comes back to **this skill**, so you finish the run. **Not** the inner workflow's next state. |
| `drive_mode:` | the mode this run is in (`stepping` on a first run) | Required on a tour pointer — without it restore falls back to its own default and silently changes gear mid-run. |

**Also write `tour: greenfield` into the in-tour WIP's own frontmatter, next to `drive_mode`.** This is
belt-and-braces and the reason is specific: `/session-restore` **deletes** `.session.md` once it has consumed it,
so by the time a later in-tour boundary comes round in Session C the pointer is gone. The general session skills'
guards look for `tour:` in the pointer **or the active WIP** — the WIP copy is the one still on disk at that
moment, so without it those guards silently never fire and the only thing holding the line is this file's own
prose. Cheap to write, and it makes the backstop real rather than decorative.

`state_file:` still points at the inner WIP, so the work content stays reachable. Don't narrate this table
to the user — the *pointer* is the teaching beat, not its field list. If the user opens the file and asks
about `tour:`, a one-liner is plenty: it's how the next session knows the tour is still running.

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

**You are the one restore hands back to — so carry the run to its end from here, as one thread.** Because
the pointer set `resume_skill` to this skill, `/session-restore` returns control *here*, in whatever mode this run
has been in, with no drive-mode menu shown (restore suppresses it on a tour pointer precisely so Step 8 keeps the
reveal — on a replay you already have your gear, so there is nothing to ask). If the
inner feature or task still has states left to run — a ship, a close, a reflect — **drive them yourself as
part of the narration**, then go on to Step 8. There is exactly one thread: finish the work, then graduate.

**When one of those inner states reaches a clean terminal boundary, narrate it — don't act on it and don't
put it to the user.** The tour already wrote its one handoff back in Scene 1, so a second one is noise. Name
what a real project would do and keep moving:

> *"Notice where we just landed — that's a real clean boundary. In your own project this is the moment the
> workflow writes the handoff by itself, so tomorrow's session opens with the whole plot intact. You watched
> that happen a step ago, so we won't do it twice — let's finish up."*

Asking "continue the tour, or hand off now?" here is the specific defect this wording exists to prevent: it
hands the user a decision about the mechanism they just watched, and there is only one sensible answer mid-run.

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
beat B the tour is built around. This is a *named* reveal, not a staged run.) Then plant the replay in
one line (below), and let the `Next Step:` block at the very end carry the actual how.

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
both ways; use whichever gear fits the work" is the right note. Skip the Branch-A replay-motivation line
below and go straight to the "what we did NOT demo" close (it applies to both branches), then Branch B's
own `Next Step:` block — which has **no replay option**, since they are already in one.

**Then (Branch A only) plant the replay in one line** — the honest way to let the user *feel* those
faster gears without demoing them live here (which would hide beat B). The tour stays stepping to its
end; the faster gears are something they go try **on a fresh run**, now that they know what the pauses
are protecting. Keep this to a sentence or two of *motivation* — the actionable form (with its
mechanics) is **option 1 of the `Next Step:` block below**, so do not spell the whole procedure out
twice:

> *"If you want to feel the difference, the fastest way is to take this exact tour again in a faster
> gear — same work, but you'll watch it move. On work you already understand end-to-end, that contrast
> is the quickest way to find where you're comfortable handing over the wheel. I'll put the how at the
> end."*

(This is a *named* invitation, not a live demo — the user drives the faster run themselves in a new
session, so this run's beat B stays intact. Frame it as "go try it," never "watch me autopilot." The
three load-bearing replay mechanics — direct arm re-entry, session-boundary crossing, gear from the
arm's own menu — plus the empty-folder requirement live in the `Next Step:` block's option 1 and its
mechanics note; they are compressed there, not dropped.)

**Then close by naming what you did NOT demo** *(BOTH branches land here — Branch A after its replay
invite, Branch B directly after acknowledging the gear)* — one or two lines, framed as "here's what's
here when you're ready," never staged (these are delayed-gratification and would feel fake if forced):

> *"Two things we didn't get into, so you know they're there:*
> - *the full **hierarchy** — product → feature → task all live in this same kind of on-disk record,
>   so a big initiative and a one-line fix use the one system;*
> - *and it **learns you** — a reflect/capture step at the end of sessions quietly records your
>   preferences and corrections, so it fits you better next time than it did today.*
>
> *That's the tour. You steered, it kept the plot, and it's all sitting in files you own."*

Then show **the artifacts as proof** — the real files this run produced, drawn from the actual run (the
archived feature record, the backlog, `CHANGELOG.md`, the tests, the un-pushed commits). This is the
evidence behind "files you own," so it stays *before* anything transactional.

### The close's last block — `Next Step:` (structure this deliberately)

**Everything above is narrative; the last thing on screen is a short, scannable decision block.** The
operator's live-run feedback was explicit: the actionable choice must not be buried in the middle of a
wall of prose. So the close ends with a compact `Next Step:` block — **details go above it, options go
in it, and nothing follows it.**

Rules for the block:
- **Keep each option to ≤3 sentences.** The reasoning already happened above; here you are only naming
  the choice and its one-line why. Resist re-explaining.
- **It is the last thing you emit.** No further prose, no sign-off paragraph, no extra pointer after it.
- **It is per-branch** — Branch A and Branch B offer different options (below). Never show Branch A's
  replay option on a replay run.
- **Options are named, never auto-run.** You are ending the tour; do not start any of these yourself.

**Branch A (first run) — three options plus the cleanup offer:**

> **Next Step:**
>
> **1 — Take it again in a faster gear.** `/exit`, `mkdir` a new empty folder and `cd` into it, then run
> `/tutorial-greenfield-workflow-tour` directly in a fresh session and say yes when it asks if you're
> replaying. You'll feel exactly which stops autopilot keeps and which FSD drops.
>
> **2 — Point it at your own code.** Run `/tutorial-getting-started` in your real repo and take the
> existing-code path. Same workflow, your codebase, nothing staged.
>
> **3 — Go deep on the planning layer.** Run `/tutorial-product-cycle-tour` in a fresh session to watch
> a fuzzy idea become a feature-ready plan. It's longer (~30–45 min) and it's real, so save it for when
> you've got the time.
>
> *Housekeeping: this sample was a throwaway copy — want me to delete it, or would you rather keep it
> to poke at? (Your commits and the workflow files live in here too, so it's yours either way.)*

**Branch B (replay) — two options plus the cleanup offer** (no replay option — they're already in one):

> **Next Step:**
>
> **1 — Point it at your own code.** Run `/tutorial-getting-started` in your real repo and take the
> existing-code path. Same workflow, your codebase, nothing staged.
>
> **2 — Go deep on the planning layer.** Run `/tutorial-product-cycle-tour` in a fresh session to watch
> a fuzzy idea become a feature-ready plan. It's longer (~30–45 min) and it's real.
>
> *Housekeeping: this sample was a throwaway copy — want me to delete it, or keep it to poke at?*

**Mechanics that must stay correct in the block** (they are compressed here, but they are the same
mechanics spelled out above — do not let compression break them):
- **Option 1/Branch A is the replay** and it carries all four of its constraints: a **new empty folder**
  (the scaffolder refuses a non-empty one), `/exit` to a **fresh session** (a real session-boundary
  crossing), re-entry at **the arm skill directly — NOT `/tutorial-getting-started`** (the dispatcher
  would re-force stepping and re-ask the path fork), and the **gear chosen from the arm's own on-entry
  menu** (it asks "replaying?" then presents 1–4). The human never runs the scaffolder themselves.
- **The deep-dive option** is `/tutorial-product-cycle-tour`, **run directly in a fresh session** — it
  is NOT reached through `/tutorial-getting-started`'s first-timer fork (a full product cycle is a poor
  cold-open), it keeps its honest **~30–45 min** label, and it is a *named* pointer — never start
  driving `/product-vision` here. This option holds on **both** branches.
- **The cleanup offer is an offer, not an action.** Ask; do not delete anything unless the user says
  yes. If they decline (or don't answer), leave everything in place — the files are the proof you just
  showed them, and they chose the directory. It comes **last, after the artifacts list**, so the tour
  never asks to remove the evidence before showing it.

The close reinforces beat **G** one final time (you kept the wheel) and hands the user back
to their real work — which is the whole value prop. **The tour ends here** — once you've delivered the
narrative close, the artifacts, and the `Next Step:` block, there is nothing further to invoke and no
transition to emit; the run is complete (see `## Transitions`). **The `Next Step:` block is the last
thing on screen** — if the user picks an option, they act on it themselves (or in a new session); you do
not chain into it. The one exception is the cleanup offer: if they say yes, delete the sample, then stop.

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
