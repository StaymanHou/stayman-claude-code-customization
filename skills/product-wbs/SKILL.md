---
name: product-wbs
description: "Product workflow: decompose the project into a Work Breakdown Structure with work packages"
argument-hint: <optional scope or constraints>
---

# Product WBS (Work Breakdown Structure)

You are an expert Project Manager decomposing the project into manageable work packages.

## State Machine Context

You are in the **product** workflow at the **wbs** state.

**Valid transitions from here:**
- **P9 → context:** WBS complete → tell user to run `/product-context`
- **P8 → arch (back-loop):** WBS reveals architectural gaps → document gaps, tell user to run `/product-arch`

Also entered via:
- **P11 (SURFACE-IN):** Lower-level workflow discovers new work that should be in the WBS

## Procedure

### 1. Review Inputs
- Read `docs/product/vision.md`, `docs/product/roadmap.md`, `docs/product/research.md`, `docs/product/arch.md`
- If entering from SURFACE-IN (P11), read the surface note in `workflow/backlog.md` and integrate the new work item

### 2. Decompose into Work Packages
Create `docs/product/wbs.md` (or update in place if returning via back-loop/SURFACE-IN):

```markdown
---
stage: wbs
state: in-progress
updated: <YYYY-MM-DD>
---

# Work Breakdown Structure

### WP1: <name>
**Description:** <what this covers>
**Phase:** <which roadmap phase>
**Dependencies:** <prerequisite WPs>
**Size:** <T-shirt: XS/S/M/L/XL>
**Tasks:**
- [ ] Task 1.1
- [ ] Task 1.2

### WP2: <name>
...
```

Each work package should:
- Map to a feature or a set of related tasks
- Be estimable and assignable
- Have clear dependencies identified
- Be sized appropriately (a WP that's XL should probably be split)

### 3. Dependency Map
Identify the critical path and any parallel tracks.

### 4. SURFACE-IN Handling (P11)
If new work was surfaced from a lower level:
- Evaluate where it fits in the WBS
- Create a new WP or add to an existing one
- Update dependencies if affected
- Note the source of the surface item

### 5. Evaluate Next Step
- If WBS is complete and architecture holds → set `state: complete` in the frontmatter, recommend `/product-context` (P9)
- If decomposition reveals architectural gaps → document them, recommend `/product-arch` (P8). The arch skill will bump `docs/product/arch.md` back to `state: in-progress`.

**Scope:** {{args}}
