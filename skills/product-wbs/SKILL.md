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

## Terminology — "milestone" is the roadmap unit; "phase" is a read-alias

The roadmap decomposes the product into **milestones** (`Milestone 1`, `Milestone 2`, …). When *reading* an existing `roadmap.md` that uses "Phase", treat "phase" as a recognized alias for "milestone" — older roadmaps remain valid. When *writing* WBS content that references a roadmap unit, use "Milestone". (Note: the *feature Work Tree's* "Phase" — `Phase 1`, `P1.1` in feature WIP files — is a **different artifact** that keeps the "Phase" name; do not confuse it with the roadmap's milestone.)

## Scope — decompose ONLY the immediate next milestone

**The WBS details work packages for the immediate next milestone in the roadmap — not the whole roadmap.** Decomposing all future milestones up front is speculative waste: later milestones are contingent (gated, pivot-on-failure), depend on knowledge that does not exist yet, and re-planning is cheap precisely because you did not over-commit.

- Detail WPs (probe + build, with tasks) for the **next milestone only**.
- Future milestones are **already tracked in `roadmap.md`** — do NOT re-list them as decomposed WPs. At most keep a single-line pointer ("future milestones tracked in roadmap.md"), and only if a stub is genuinely useful.
- On milestone completion the workflow loops back here (or to the next feature) to decompose the *next* milestone **just-in-time** — not all-at-once.

This extends the learning-sequence-ordering discipline below ("resolve riskiest unknowns first, cheaply") with: *and don't decompose what you're not about to build.*

## Procedure

### 1. Review Inputs
- Read `docs/product/vision.md`, `docs/product/roadmap.md`, `docs/product/research.md`, `docs/product/arch.md`
- Identify the **immediate next milestone** in `roadmap.md` (the earliest milestone not yet complete) — this milestone is the entire scope of this WBS pass
- If entering from SURFACE-IN (P11), read the surface note in `workflow/backlog.md` and integrate the new work item

### 2. Decompose into Work Packages

Create `docs/product/wbs.md` (or update in place if returning via back-loop/SURFACE-IN). **Decompose only the immediate next milestone** (see "Scope" above).

**Two kinds of work packages exist — use the right template for each:**

#### Standard (Build) WP

```markdown
### WP<N>: <name>
**Description:** <what this covers>
**Milestone:** <which roadmap milestone>
**Dependencies:** <prerequisite WPs>
**Size:** <T-shirt: XS/S/M/L/XL>
**Tasks:**
- [ ] Task N.1
- [ ] Task N.2
```

#### Spike / Probe WP

Use this type when a WP's primary output is *knowledge*, not working software — e.g., verifying a 3rd-party API's shape, confirming infrastructure compatibility, validating a technical assumption.

```markdown
### WP<N>: Probe — <what is being investigated>
**Type:** probe
**Milestone:** <should appear BEFORE any WP that depends on this knowledge>
**Dependencies:** <prerequisite WPs>
**Size:** <T-shirt: XS/S/M/L/XL>
**Learning objective:** <what question are we answering? e.g. "What are the exact request/response shapes for Stripe's PaymentIntent API?">
**Timebox:** <e.g. 2h, half-day>
**Success criterion:** <what we will know when done — e.g. "A documented summary of PaymentIntent create/confirm/cancel endpoints with field types and error codes">
**Tasks:**
- [ ] Task N.1
- [ ] Task N.2
```

Each standard work package should:
- Map to a feature or a set of related tasks
- Be estimable and assignable
- Have clear dependencies identified
- Be sized appropriately (a WP that's XL should probably be split)

### 3. Learning-Sequence Ordering

**Order WPs (within the milestone) by learning dependencies, not just build dependencies.** The riskiest unknowns should be resolved first, when the cost of discovery is lowest and the cost of re-planning is cheapest.

**Standard ordering sequence (deviate only with written rationale):**
1. **Environment / Docker** — prove the dev environment works before writing any application code
2. **3rd-party probes** — one probe WP per external API/service/SDK before any build WP that assumes known shapes
3. **UI mockups / frontend prototypes** — validate UX assumptions before building the backend that serves them
4. **Backend synchronous path** — implement the core feature without async complexity
5. **Orchestration / async as refactor** — add queues, workers, event systems on top of a working synchronous path

**For each ordering transition, write a brief rationale:**
```markdown
**WP N → WP N+1 rationale:** <why this WP before the next, in terms of risk reduction — e.g. "Stripe probe before payments WP so we don't design the data model around assumed API shapes">
```

### 4. 3rd-Party Integration Rules

**Any WP that calls an external API, uses a 3rd-party SDK, or depends on an external service must have a preceding probe WP that:**
- Documents the integration's I/O shapes (request fields, response fields, error codes)
- Completes before the dependent WP begins

**If no probe WP exists for a required 3rd-party integration, create one.** A WP that assumes known API shapes without a probe is a planning gap — flag it explicitly.

### 5. Orchestration Ordering Rule

**Orchestration layers (message queues, background workers, event buses, async pipelines) must be ordered after the synchronous path they will wrap.** If you find yourself planning async infrastructure in the same WP as the core synchronous logic, split them: implement the synchronous path first, then add the async wrapper in a subsequent WP (and, if the async layer belongs to a later milestone, defer it there).

Deviations from this rule require written rationale (e.g., "async is load-bearing from day 1 because the core operation is inherently unbounded in duration").

### 6. Dependency Map
Identify the critical path and any parallel tracks.

### 7. SURFACE-IN Handling (P11)
If new work was surfaced from a lower level:
- Evaluate where it fits in the WBS
- Create a new WP or add to an existing one
- Update dependencies if affected
- Note the source of the surface item

### 8. Evaluate Next Step
- If WBS is complete and architecture holds → set `state: complete` in the frontmatter, recommend `/product-context` (P9)
- If decomposition reveals architectural gaps → document them, recommend `/product-arch` (P8). The arch skill will bump `docs/product/arch.md` back to `state: in-progress`.

**Note on cycle close:** When all WPs in this WBS are eventually marked `[x]` by `feature-finalize` runs, `feature-finalize` will detect the complete WBS and surface `/product-finalize` (F30). That skill resyncs durable docs, sweeps the backlog, and archives cycle-scoped docs (`wbs.md`, `research.md`, diagnostics) to `docs/product/archive/<cycle-name>/`.

**Scope:** {{args}}
