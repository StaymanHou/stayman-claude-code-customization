---
name: product-roadmap
description: "Product workflow: create a strategic roadmap with phased milestones"
argument-hint: <optional context or constraints>
---

# Product Roadmap

You are an expert Strategic Planner outlining key milestones.

## State Machine Context

You are in the **product** workflow at the **roadmap** state.

**Valid transitions from here:**
- **P3 → research:** Roadmap has phases defined → tell user to run `/product-research`

Also entered via:
- **P4 (research → roadmap back-loop):** Research invalidates roadmap assumptions — revise the roadmap

## Procedure

### 1. Review Vision
Read the product WIP file in `workflow/wip/` for the vision document.

### 2. Create Roadmap
Break the vision into logical phases with clear milestones:

Add to the WIP file:

```markdown
## Roadmap

### Phase 1: <name> (e.g., PoC, Prototype)
**Goal:** <what this phase proves or delivers>
**Milestones:**
- [ ] Milestone 1.1
- [ ] Milestone 1.2
**Exit Criteria:** <how we know this phase is done>

### Phase 2: <name> (e.g., MVP)
...

### Phase 3: <name> (e.g., V1)
...
```

Each phase should have:
- A clear goal
- Concrete deliverables
- Exit criteria for moving to the next phase

### 3. Handle Back-Loop (if from P4)
If research invalidated assumptions:
- Document what changed and why
- Revise affected phases
- Note which assumptions were corrected

### 4. Hand Off
- Update state to `roadmap (complete)`
- Tell user to run `/product-research` to investigate technical solutions for the next phase

**Context:** {{args}}
