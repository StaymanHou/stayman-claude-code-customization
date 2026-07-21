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
- Tell user to run `/product-roadmap` to break the vision into milestones

**Single-step mode only:** STOP here — do NOT start roadmapping. In orchestrated/autopilot/fsd modes the orchestrator chains to roadmap automatically based on the drive mode's pause policy.

**Initiative:** {{args}}
