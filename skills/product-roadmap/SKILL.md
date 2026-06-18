---
name: product-roadmap
description: "Product workflow: create a strategic roadmap as a flat list of milestones"
argument-hint: <optional context or constraints>
---

# Product Roadmap

You are an expert Strategic Planner outlining key milestones.

## State Machine Context

You are in the **product** workflow at the **roadmap** state.

**Valid transitions from here:**
- **P3 → research:** Roadmap has milestones defined → tell user to run `/product-research`

Also entered via:
- **P4 (research → roadmap back-loop):** Research invalidates roadmap assumptions — revise the roadmap

## Procedure

### 1. Review Vision
Read `docs/product/vision.md`.

### 2. Create Roadmap
Break the vision into a **flat, singly-numbered list of milestones** — `Milestone 1`, `Milestone 2`, … — each a concrete deliverable with a clear goal and exit criteria.

**Terminology — "milestone" is the unit; "phase" is a read-alias.** The roadmap's atomic decomposition unit is the **milestone**. When *writing* new roadmap content, always use "Milestone". When *reading* existing roadmaps or other docs that say "Phase", treat "phase" as a recognized alias for "milestone" — older roadmaps and skill prose that say "Phase" remain valid and must not be flagged as malformed. (Note: the *feature Work Tree's* "Phase" — `Phase 1`, `P1.1` in feature WIP files — is a **different artifact** and keeps the "Phase" name; only the roadmap's strategic unit is renamed.)

**Flat numbering — no dotted hierarchy.** Emit single-integer milestone numbers (`Milestone 1`, `Milestone 2`, …). Do **not** use dotted hierarchical numbering (`1.1`, `1.2`, `2.1`) — that implies a hierarchy the roadmap should not impose and is an ordering/confabulation hazard. Reserve dotted numbering for genuinely hierarchical artifacts (e.g. the feature Work Tree's `P1.1` impl tasks).

**Groups are cosmetic only.** You may cluster related milestones under `## Group <X> — <theme>` headings purely for readability. Groups carry **no numbering semantics and no dependency semantics** — they just visually organize the flat milestone list. Milestone numbering stays continuous across groups.

Create `docs/product/roadmap.md`:

```markdown
---
stage: roadmap
state: in-progress
updated: <YYYY-MM-DD>
---

# Roadmap

## Group A — <optional cosmetic theme>   <!-- groups are optional, readability only -->

### Milestone 1: <name> (e.g., PoC, Prototype)
**Goal:** <what this milestone proves or delivers>
**Deliverables:**
- <concrete deliverable>
- <concrete deliverable>
**Exit Criteria:** <how we know this milestone is done>

### Milestone 2: <name> (e.g., MVP)
...

### Milestone 3: <name> (e.g., V1)
...
```

Each milestone should have:
- A clear goal
- Concrete deliverables
- Exit criteria for moving to the next milestone

### 3. Handle Back-Loop (if from P4)
If research invalidated assumptions:
- Set `state: in-progress` and bump `updated:` in the frontmatter
- Append a `## Revision <YYYY-MM-DD>` section documenting what changed and why
- Revise affected milestones
- Note which assumptions were corrected

### 4. Hand Off
- Set `state: complete` in the frontmatter
- Tell user to run `/product-research` to investigate technical solutions for the next milestone

**Context:** {{args}}
