---
name: tutorial-product-cycle-tour
description: "Guided tour of the full product lifecycle for a brand-new user: watch a fuzzy idea become a milestone-ordered, dependency-mapped, feature-ready plan (vision → roadmap → arch → wbs). The deep-dive graduation tour (~30-45 min, real), reached from the greenfield tour's close. Run directly in a fresh session."
argument-hint: "(no arguments — the deep-dive graduation tour; run directly in a fresh session, reached from the greenfield tour's close)"
---

# Full product-cycle tour — a fuzzy idea becomes a whole plan

You are driving the **full product-cycle tour** — the deep-dive, graduation-destination member of the
`tutorial-*` family. The user is not brand-new anymore: they have already taken the ~10–15 min
greenfield tour, they trust the system, and they came here **on purpose** to feel the workflow carry a
whole **initiative** end-to-end. Your job is to walk them through the *entire* product lifecycle —
vision → roadmap → research → arch → wbs — on a controlled sample idea, narrating each stage so they
watch a **shapeless want turn into a milestone-ordered, dependency-mapped, feature-ready plan**.

The headline this tour sells: *"I have a big idea but I never turn it into a real plan — I just start
coding and lose the shape of the whole thing. This carries the whole initiative, not one unit of
work."*

> **Flow authority — read before editing.** This tour is **always run directly, in its own session**
> — like the arms, but it is reached from the **greenfield arm's Step-8 close** (a pointer), NOT from
> `tutorial-getting-started`'s first-timer fork (a full product cycle is a poor *first* impression).
> The family flow doc is `docs/lessons/tutorial-tour-session-chain-flow.md`. **This tour deliberately
> does NOT carry the arms' replay / drive-mode-menu / mode-aware-graduation machinery** — see
> "On entry" and "Why no replay / no mode menu" below. It is settled in
> `workflow-system/product/full-product-cycle-tour-design.md` (the design contract); conform to it.

## Category

**`tutorial-*` — a standalone onboarding skill (the full product-cycle deep-dive).** Like the rest of
the family, it **owns no workflow state** and **emits no transition** — no `F`/`I`/`T`/`P`/`S` token,
no `DEBUG-*` token, no `RETURN-TO:`. It is **run directly by the user in a fresh session** (reached
from the greenfield arm's Step-8 pointer — it is NOT invoked inline by any other skill); it **runs the
tour to its close**. Minimal frontmatter (`name` / `description` / `argument-hint`); no `skills:` list,
no `tools:` key. See `workflow-system/product/full-product-cycle-tour-design.md` for the design
contract and `workflow-system/product/onboarding-flow-spec.md` for the family invariants it extends.

## Framing (keep it honest — a LONG tour)

This is a genuinely long run: it drives the real product skills (`/product-vision`, `/product-roadmap`,
`/product-research`, `/product-arch`, `/product-wbs`) with real reasoning and real token spend — **not**
a scripted demo reel, and **not** a compressed narrate-and-skip summary. The honest label is a
**filter, not a warning**: the audience has already taken the short greenfield tour and self-selected
into the deep dive.

- **Honest long label — REQUIRED, say it up front:** *"This is the full product lifecycle on a sample
  idea — real skills, real reasoning, roughly ~30–45 minutes. This is the deep-dive; take it when
  you're ready to go deep."*
- **FORBIDDEN:** any "quick" or "5-minute" claim (same never-fake-it rule as the arms). This tour is
  long *on purpose*; the honest ~30–45 min framing is what makes the length acceptable — never fake
  speed.
- **NO narrate-and-skip compression.** Do NOT "run wbs but summarize the output to save time." Run the
  real skills; the honest label, not faked speed, is what earns the length.
- **Per-stage pre-framing:** introduce each stage so a real product-skill run doesn't read as dead
  time — same discipline as the arms' per-beat pre-framing (each stage below carries its framing line).

## On entry — run stepping; NO mode menu, NO replay question

You are run directly, in a fresh session. Unlike the greenfield/brownfield arms, **do NOT ask
"first run or replay?" and do NOT present the 1–4 drive-mode menu.** Just start the tour in the
workflow's normal **stepping** cadence and go. (You silently drive stepping — you don't announce a
"mode" to the user.)

### Why no replay / no mode menu (do not regress this)

The arms carry a first-run/replay question, a drive-mode menu, and a mode-aware Step-8 graduation
**because their whole lesson is "the pauses are tunable — go try a faster gear."** That lesson **does
not apply here.** In a product cycle, the workflow **pauses at *every* stage**, and that recurring
pause **IS** the human-in-the-loop trust beat — *you steer, it keeps the plot*, restated at each
stage. The pauses are the point; they are not meant to be skipped. So this tour has:

- **NO** first-run/replay entry question, **NO** 1–4 drive-mode menu, **NO** mode-aware graduation,
  **NO** replay invitation. (Teaching "go faster" would contradict the whole shape of the cycle.)
- **NO** staged verify-self grounding beat and **NO** staged SURFACE beat. Those are greenfield-only —
  they need a runnable scaffold + a planted tangent, which this planning-only tour doesn't have.
  Grounding here is **NAMED** at the arch stage, not staged.

The only speed note the tour makes is the honest **FSD-for-rare-cases caveat** at the close (Step 8)
— named as a counterweight, explicitly *not* an invite.

## The environment — a written product brief (design §2, Option A)

This tour runs against a **controlled written subject**, not the user's own idea (BYO would overlap
the brownfield arm, can't guarantee the staged beats, and makes length unbounded) and not a runnable
sample (there is no verify-self beat here that needs runnable code — so a brief is the lower-rot
choice). The subject is a short, fuzzy product brief that ships **inside this skill's own directory**
so it travels with the skill wherever it's installed:

```
~/.claude/skills/tutorial-product-cycle-tour/scripts/brief.md
```

(It lives beside this skill — not under repo-root `tools/` — so it rides the skill's whole-directory
symlink on any install, exactly like the greenfield scaffold. See the arms' scaffold-in-skill note.)

**Open it and read the fuzzy idea aloud to the user at Step 1** — it's the "trailhead" for the whole
run. The brief is deliberately shapeless (a paragraph a real person might scribble); the *workflow* is
what sharpens it. Do **not** pre-solve it in your framing — the decomposition aha depends on the user
watching a plan fall out of a ramble, not being handed a spec.

> **Where to run this.** You are already in a fresh session for the tour. The product docs the tour
> produces (`vision.md`, `roadmap.md`, `arch.md`, `wbs.md`) get written under
> `<proj-dir>/workflow-system/product/` in **whatever directory this session is in**. If that matters
> to the user (they don't want tour output in a real project), have them `/exit`, make or `cd` into a
> throwaway directory, and relaunch before you begin. The tour output is real files on disk (that's
> the whole point of beat A at Step 6) — so put them somewhere the user is happy to keep or delete.

## The walkthrough (design §3 spine)

Drive these stages in order. Disposition per the design is annotated on each — **STAGED** beats are
guaranteed and you engineer them; **NAMED** beats are pointed-at in one line, never staged; the
**recurring step-pause** is the human-in-the-loop trust beat, narrated at *every* stage.

**The recurring pause IS beat B (do not skip it).** After each stage, the workflow pauses for the
user to steer. Narrate it every time — *"see, it stopped and handed the decision back to you"* — the
first time explicitly, then briefly at each subsequent stage. This step-by-step pausing is the whole
human-in-the-loop story here, and it is stronger than one engineered pause: the user feels the
they-keep-the-wheel property (beat **G**) reinforced at every single stage.

### Step 1 — Fuzzy idea → vision (Decomposition beat #1 — STAGED; the headline starts)
Open `~/.claude/skills/tutorial-product-cycle-tour/scripts/brief.md` and read the fuzzy idea to the
user. Frame it:
> *"Here's our starting point — a ramble, the kind of thing you'd scribble in a notes app: someone
> wants to build a little self-hosted app but 'doesn't know where to start.' Watch what the workflow
> does with a shapeless want like that. This is the thing I always skip — I just start coding and
> lose the shape. Let's not."*

Run **`/product-vision`** on the brief. Let it turn the ramble into a crisp purpose, scope, and
non-goal / anti-persona. **This is where the decomposition headline begins** — narrate the sharpening:
*"notice it pulled a real purpose and an explicit non-goal out of a paragraph that had neither."*
Then let it **pause** and hand the vision back for the user to steer — narrate beat B/G explicitly
here (the first pause): *"and there — it stopped and gave you the wheel. You steer the vision; it just
did the structuring."*

### Step 2 — Vision → roadmap (Decomposition continues — STAGED)
Frame it:
> *"A vision is still just a direction. Watch it become an *ordered* plan — milestones, in the order
> that actually makes sense to build them."*

Run **`/product-roadmap`**. The payoff to narrate: the natural **dependency ordering** falls out — a
walking skeleton before the enrichment before the ranking that depends on both. *"See how it didn't
just list features — it sequenced them by what has to exist first? That ordering is the thing I never
get right on my own."* Let it pause; briefly re-note the steer.

### Step 3 — Research scout (NAMED / light — not a full spike)
Frame it:
> *"Before committing to a design, it scouts the real unknowns — quickly, not a research project."*

Run **`/product-research`** as a *light* scout (not a heavyweight spike). The honest beat here: it
**names a real known-unknown** rather than pretending certainty — e.g. "the weather data has a clean
public source, but trail-status might not have a real feed at all." *"Notice it flagged what it
*doesn't* know instead of bluffing — that honesty is what keeps the plan from being fiction."* Keep it
light; pause and steer.

### Step 4 — arch — system design (Grounding NAMED — STAGED pause)
Frame it:
> *"Now the shape of the thing — where data lives, how the external stuff gets fetched. And watch
> where it grounds the design."*

Run **`/product-arch`**. **NAME the grounding** in one line as it plans around *documented real
shapes* rather than inventing them: *"see — it's planning around what a real weather API actually
returns, not an endpoint it hopes exists. It checks reality instead of guessing."* (Grounding is
**NAMED** here, not staged — there's no runnable subject to observe, so we point at it honestly rather
than fake a verify-self run.) Let it pause and steer.

### Step 5 — wbs — decompose into work packages (Decomposition PAYOFF — STAGED)
**This is the payoff of the whole tour — engineer it and land it.** Frame it:
> *"Here's the moment. Watch the whole fuzzy idea from Step 1 turn into a *list of buildable things* —
> each one a unit a feature workflow could pick up tomorrow."*

Run **`/product-wbs`**. When it produces the work-package list, **hold on it and connect it back to
the ramble**: *"Look at where we started — 'I don't know where to start' — and where we are now: a
dependency-mapped list of feature-ready work packages. That's the thing. The workflow just carried a
whole initiative from a paragraph to a plan. That's what it does that vibe-coding never will — it
keeps the shape of the *whole thing*, not just the next file."* This is the DECOMPOSITION aha fully
delivered (the light-taste greenfield arm only *hints* at it).

### Step 6 — Open the strategic docs (beat A at the STRATEGIC layer — STAGED)
The greenfield tour stages beat A on a single WIP file. Here beat A lands **bigger** — on the whole
strategic record. The stages above wrote real files. Open them and show the user:

- `<proj-dir>/workflow-system/product/vision.md`
- `<proj-dir>/workflow-system/product/roadmap.md`
- `<proj-dir>/workflow-system/product/arch.md`
- `<proj-dir>/workflow-system/product/wbs.md`

> *"Everything we just did is sitting right here — four plain files you own. The whole plan for your
> initiative isn't locked in a tool and it isn't in the model's head — it's on your disk, in files
> you can open, read, edit, and commit. This is the durable memory of the whole initiative."*

This is the **durable-strategic-memory** aha, and it is exactly what makes the next step
(handoff/restore of the *whole plan*) believable — the user has just *seen* the plan is real files.

### Step 7 — Bookend: handoff → restore of a WHOLE plan (STAGED — the emotional peak)
**Mechanically identical to the greenfield arm's Step 7 — reuse that proven choreography, do not
re-derive it.** The difference here is **scale**: there is a whole roadmap + WBS to lose and recover,
so the "reset the window, nothing important is lost" payoff lands *harder*.

**The primary value to sell is context-window management** — NOT "close the laptop till tomorrow." The
real pain: a long session (and this one *was* long) fills the context window, and the built-in
`/compact` squeezes it by *summarizing the conversation* — exactly when the agent loses the plot
(drops a milestone, forgets a dependency, tunnel-visions on the last stage). Handoff → restore is the
**curated alternative**: you deliberately reset the window to near-empty, and the load-bearing context
(the vision, the roadmap, the WBS, where you are) comes back **not from a lossy summary, but because it
was written to disk and gets re-read fresh**. Cross-session continuity ("come back tomorrow") is a real
*secondary* benefit — but the headline is "free up the window without losing the whole plan, better
than `/compact`." Drive it as three scenes, narrating each move just before you make it:

**Scene 1 — check the window, pre-frame, then hand off.** Have the user *look at their current context
usage* (the context-left indicator in the Claude Code UI) so the before/after is concrete:
> *"Here's the moment that sold me — and it's not about walking away, it's about your context window.
> Glance at how much context you've got left; we just ran a whole product cycle, so it's filled up.
> Normally you'd `/compact` to reclaim it — but `/compact` works by *summarizing our chat*, and on a
> plan this big that's exactly when the agent quietly drops a milestone or forgets a dependency. Watch
> a cleaner way. I'll hand the session off, then we start completely fresh — and the whole plan
> survives."*

Then run **`/session-handoff`**. Point at exactly what it does: it writes a small pointer file,
`<proj-dir>/workflow-system/state/.session.md`, that records the workflow, the step, and the next
action — and drops a one-line marker into the relevant doc. *"That's it — one tiny pointer. It doesn't
copy your whole roadmap and WBS into itself; it points at the files on disk that already hold them.
Everything needed to bring the whole plan back is in your project, not in the model's head."*

**Scene 2 — reset the window (the real point).** Make it real if you can:
> *"Now the part that matters: we throw the context window away. `/exit` this session and start a
> brand-new one — a genuinely empty window, none of this conversation in memory. This is what you'd
> reach for instead of `/compact` when the window's heavy and you don't want to risk a lossy summary
> eating part of your plan."*

(The user *can* actually `/exit` and relaunch here for the full effect — and since restore reads off
disk, it genuinely works. If they'd rather not break the tour flow, narrating the reset makes the
point too: the claim is that nothing depends on this conversation surviving.)

**Scene 3 — restore, then check the window again.** Run **`/session-restore`**. Narrate what it pulls
off disk: it reads that `.session.md` pointer, re-opens the strategic docs, and reconstructs where you
were — the workflow, the stage, the next action — *without* replaying the conversation. Then land the
beat two ways — the window, then the plan:
> *"Look at your context usage now — nearly empty again, the whole window reclaimed. And yet: the
> vision, the roadmap, the WBS, where we were — all back. Notice **where** it came from: those same
> four plain files you opened a minute ago. It didn't remember you from our chat, and it didn't
> summarize anything — it re-read your plan off disk. So the *whole* initiative comes back in full
> detail, not a lossy compression. That's the difference from `/compact`: you reset the window to keep
> working fast, and the agent doesn't drop a milestone or lose the big picture, because the big
> picture was never in the window — it's in your repo. (Same reason you can close the laptop and pick
> the whole plan up next week.)"*

This is the payoff for beat A (Step 6): because the plan was always real files, resetting the window —
or walking away and coming back — is just re-reading it. Don't rush the reveal — on a plan this big,
this is the beat that converts.

### Step 8 — Close (NO graduation reveal; FSD-caveat NAMED, not an invite)
Because there is no replay here and the pauses are not meant to be skipped, the close **drops the
drive-modes graduation reveal** the arms carry. Deliver these three, in order:

**1. FSD-for-rare-cases caveat (NAMED — an honest counterweight, NOT an invite).**
> *"One note on speed, so you know it exists. There's an FSD mode that would run a whole product cycle
> like this with no stops at all. It's genuinely only for the rare case — a simple, clear vision on a
> low-stakes, experimental, or throwaway project. For real work you want the stops you just saw:
> steering the plan at each stage is the whole value here. Don't reach for FSD on a real initiative
> yet."*

(This is a *named* caveat, not a staged run — do NOT demonstrate FSD live. Naming it once, un-pushed,
is the honest counterweight; inviting a faster replay would contradict the whole point of this tour.)

**2. Point at real work.**
> *"Now go run your own product cycle — start with `/product-vision` (or `/session-start`) on a real
> initiative of yours. Same flow you just watched, your idea instead of the sample."*

**3. What we did NOT demo (NAMED, delayed-gratification).**
> *"Two things we didn't get into, so you know they're there:*
> - *the **feature and task levels** of the hierarchy — this WBS you just built feeds straight into
>   them; each work package becomes a `/feature-*` or `/task-*` run, all in the same on-disk system
>   (the greenfield tour showed you one of those up close);*
> - *and it **learns you** — a reflect/capture step at the end of sessions quietly records your
>   preferences and corrections, so it fits you better next time than it did today.*
>
> *That's the full cycle. You started with a ramble and ended with a plan you own, in files on your
> disk — and you steered it the whole way. Go carry a real initiative through it."*

That closing line reinforces beat **G** one final time (you kept the wheel) and hands the user back to
their own real initiative — which is the whole value prop. **The tour ends here** — once you've
delivered the close, there is nothing further to invoke and no transition to emit; the run is complete
(see `## Transitions`).

## "Don't force it" (design §4 / spec §7 — binding)

Only these beats are **GUARANTEED STAGED** here, because only these can be staged **authentically**:
**Decomposition** (Steps 1–2 + the Step 5 payoff), **A at the strategic layer** (Step 6), and
**handoff → restore** (Step 7). Everything else — grounding (NAMED at Step 4), the FSD caveat (NAMED
at close), the hierarchy's feature/task levels (NAMED at close), reflect/capture (NAMED at close) — is
**NAMED, never staged**. Grounding and SURFACE are **CUT/NAMED** here on purpose: staging them without
a runnable subject would be faking it, which for this audience costs more trust than the aha earns.
The recurring step-pause (beat B) is not "staged" — it happens naturally at every stage; your job is
just to narrate it, never to skip it.

## Transitions

**None.** This skill emits **no** workflow transition (no `F`/`I`/`T`/`P`/`S` ID), no `DEBUG-*` token,
no `RETURN-TO:`. It is the full product-cycle member of the `tutorial-*` family: **run directly by the
user in a fresh session** (reached from the greenfield arm's Step-8 pointer — it is NOT invoked inline
by any other skill; see the Flow authority note at the top), it drives the walkthrough to its close
and ends. The state-machine "three places in sync" rule does not apply (no transition to sync).
Behavioral scenarios and the `tutorial-`-prefix structural pin (extended to this fourth skill) are
added by WP7e.
