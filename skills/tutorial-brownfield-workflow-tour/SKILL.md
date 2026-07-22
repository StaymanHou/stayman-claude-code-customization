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
**The emotional peak**, on the real repo. `/session-handoff` → the user "leaves" → `/session-restore`
→ full context comes back. *"You just walked away mid-task on your real codebase and came back to
exactly where you were — the plan, the state, all of it, from that context file, not reconstructed
from memory."*

> **WP7d wiring touchpoint (forward-declared).** The full scene-by-scene choreography of this
> bookend is authored by **WP7d** (staged-beats-wiring). This arm marks the beat + position; WP7d
> writes the scene copy.

### Step 8 — Bookend 2: the graduation, LAST + un-pushed (STAGED reveal) → close
**Deliberately last, deliberately not pushed.** Only now reveal drive modes:
> *"Now that you've seen it work on your own code: you can let it chain the safe steps automatically
> (autopilot), or skip the human checks entirely (FSD). Powerful once you trust it — but **not
> recommended yet**. Keep the pauses for a while."*

Then **close** by *naming* what you did NOT demo: the full **Hierarchy** (product→feature→task as one
record — **CUT** on brownfield: too big to *feel* in run one) and **Reflect/Capture** ("the system
learns your preferences over sessions") — as "here's what's here when you're ready," never staged.

> **WP7d wiring touchpoint (forward-declared).** The drive-modes reveal copy + named-at-close
> pointers are authored by **WP7d**. This arm fixes their position (LAST, un-pushed) and disposition;
> WP7d writes the scene copy.

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
