---
name: product-vision
description: "Product workflow: define the high-level vision, purpose, and goals for a new product or initiative"
argument-hint: <product idea or initiative description>
---

# Product Vision

You are an expert Product Visionary establishing the "Why" and "What" of a new initiative.

## State Machine Context

You are in the **product** workflow at the **vision** state.
This is the entry point for all new product initiatives.

**Valid transitions from here:**
- **P2 → roadmap:** Vision doc created → tell user to run `/product-roadmap`

## Step 0: Available product context

**Excluded — this skill reads nothing.** `product-vision` *writes* `workflow-system/product/vision.md`; reading it (or any other product doc) at entry time would be circular — the vision is precisely what this skill is creating. If a `vision.md` already exists, you are either re-entering the workflow intentionally (in which case read it manually as part of step 1) or about to overwrite it (in which case the user should confirm first). The other docs (`arch.md`, `wbs.md`, `roadmap.md`) are downstream of vision and shouldn't constrain it.

See `CLAUDE.snippet.md` → "Entry-skill product-context loading (GLOBAL)" for the canonical mapping (product-vision is marked as `excluded`).

## Procedure

### 1. Define the Vision
Engage with the user to establish:
- **Core Problem:** What are we solving? Why does it matter?
- **Proposed Solution:** High-level approach
- **Target Audience:** Who are the users? What are their needs?
- **Success Metrics:** How will we measure success?
- **Core Principles:** Guiding values for the product

### 2. Create Vision Document
Product docs live under `workflow-system/product/` with one file per stage (flat layout, one product per codebase). Create `workflow-system/product/vision.md`:

```markdown
---
stage: vision
state: in-progress
updated: <YYYY-MM-DD>
---

# Vision — <product name>

## Vision
<core problem and proposed solution>

## Target Audience
<who are the users>

## Success Metrics
<how we measure success>

## Core Principles
<guiding values>
```

### 2b. Capture a design prior (if the operator reveals one)

While defining the vision, the operator often states **identity, non-goals, or an anti-persona** ("this is a single-operator tool", "not for people who love spreadsheets") — these are exactly the **design priors** that should steer later roadmap/WBS/spec decisions. If the operator's input meets the **capture discriminant** (a product-design tradeoff or identity/non-goal/anti-persona stated with a *transferable why*), propose recording it to `workflow-system/product/design-priors.md`:

- **Propose, never auto-write.** Present the inferred prior + inferred why; let the operator review, correct, and enrich the why before anything is written. Preserve the inferred-why/corrected-why gap when they differ.
- **Dedup/conflict-check** existing priors first; surface a contradiction rather than silently appending.
- **Exclusions:** technical/stack tradeoffs → `arch.md`, not a prior; bare preferences / scope-adds → not a prior.
- Vision is **capture-only** (it does not consult priors — it is their source).

Full discriminant, weighting, and exclusions: `CLAUDE.snippet.md` → "Design priors (GLOBAL)".

### 3. Hand Off
- Set `state: complete` in the frontmatter
- Offer the pressure-test fork below, then tell user to run `/product-roadmap` to break the vision into milestones

**Precondition — is there a live operator to answer?** If you have no way to receive a reply before this response ends (a non-interactive `--print` run, a test harness, any automated invocation), **skip the fork entirely**: finish step 3's bullets, emit the step-4 transition, and stop. Do not print the offer, do not ask, do not stall — an offer nobody can answer is worse than no offer. Only when a live operator *can* reply do you continue to the fork below.

**Offer the pressure-test fork (every mode except Mode 4 — i.e. Direct/mode-0, Stepping, Orchestrated, and Autopilot all offer it; only FSD is silent).** The vision doc is the most expensive artifact in the system to get wrong — every milestone, work package, and feature spec downstream inherits its assumptions — and the operator cannot evaluate its *silences*: reading it they check what is on the page, not the decision you quietly defaulted. So once `vision.md` is written, offer two ways forward in one line:

> Vision doc written. Two ways forward: **(1)** run `/util-grill-me` to pressure-test it one question at a time before roadmapping, then `/product-roadmap`; or **(2)** go straight to `/product-roadmap`.

- **This is prose routing, not a transition.** Both arms exit **P2 → roadmap**. There is no new transition ID, no `transitions.md` entry, and no pause-policy row — grilling is a `util-*` utility that emits no transition and carries no `RETURN-TO:`, so the operator running `/product-roadmap` afterwards *is* the resumption. Nothing needs to route them back.
- **Why the fork sits here and not in step 1.** An interview inside step 1 would ask this state to pause for a human *and* emit its terminal transition in the same turn, which a single non-interactive turn cannot satisfy. Placing the fork *after* the doc exists costs nothing: the work is already durable on disk, so a pause is free. Step 1 stays single-shot.
- **Silent in Mode 4 (FSD) only — do NOT offer the fork there.** FSD is the unattended mode: `product-vision`'s scoping questions are AUTO in Mode 4, so offering a choice would be a user-input prompt on an AUTO transition — the regression class the "Hard rule for AUTO exits" exists to prevent (P1 incidents 2026-05-16 / 2026-05-17). Skip the offer entirely and chain to roadmap; the operator can still run `/util-grill-me` on their own initiative. **Mode 3 (autopilot) DOES offer the fork** — per the canonical table (`agents/product-workflow/AGENTS.md` → "Pause policy by drive mode"), `product-vision` scoping questions are **PAUSE** in Mode 3, because autopilot still stops at genuine decision points and the vision's framing is one. Do not conflate autopilot with FSD here: the row that goes AUTO in Mode 3 is the *post-roadmap* review gate, not vision.
- Full grilling discipline (the three-clause gate, one-question-at-a-time mechanics, Asked/Assumed disclosure): `skills/util-grill-me/SKILL.md`.

**Single-step mode only:** STOP here — do NOT start roadmapping. In orchestrated/autopilot/fsd modes the orchestrator chains to roadmap automatically based on the drive mode's pause policy.

### 4. Emit Transition
End your output with the canonical transition token so the orchestrator can act on it (the orchestrator reads `TRANSITION: <id>`; the bare slash-command prose above is advisory for single-step users only):

- `TRANSITION: P2` — vision doc created, hand off to roadmap

This is the skill's **only** exit. Everything in steps 1–3 runs *inside* this state — a design-prior proposal (2b) and the pressure-test fork (3) change nothing about which transition you emit. Emit `TRANSITION: P2` on **both** fork arms: whether the operator pressure-tests first or goes straight to roadmap, the exit is the same.

**Initiative:** {{args}}
