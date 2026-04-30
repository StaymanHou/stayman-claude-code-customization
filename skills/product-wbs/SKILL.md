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

Create `docs/product/wbs.md` (or update in place if returning via back-loop/SURFACE-IN).

**Two kinds of work packages exist — use the right template for each:**

#### Standard (Build) WP

```markdown
### WP<N>: <name>
**Description:** <what this covers>
**Phase:** <which roadmap phase>
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
**Phase:** <should appear BEFORE any WP that depends on this knowledge>
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

**Order phases by learning dependencies, not just build dependencies.** The riskiest unknowns should be resolved first, when the cost of discovery is lowest and the cost of re-planning is cheapest.

**Standard phase sequence (deviate only with written rationale):**
1. **Environment / Docker** — prove the dev environment works before writing any application code
2. **3rd-party probes** — one probe WP per external API/service/SDK before any build WP that assumes known shapes
3. **UI mockups / frontend prototypes** — validate UX assumptions before building the backend that serves them
4. **Backend synchronous path** — implement the core feature without async complexity
5. **Orchestration / async as refactor** — add queues, workers, event systems on top of a working synchronous path

**For each phase transition, write a brief ordering rationale:**
```markdown
**Phase N → Phase N+1 rationale:** <why this phase before the next, in terms of risk reduction — e.g. "Stripe probe before payments WP so we don't design the data model around assumed API shapes">
```

### 4. 3rd-Party Integration Rules

**Any WP that calls an external API, uses a 3rd-party SDK, or depends on an external service must have a preceding probe WP that:**
- Documents the integration's I/O shapes (request fields, response fields, error codes)
- Completes before the dependent WP begins

**If no probe WP exists for a required 3rd-party integration, create one.** A WP that assumes known API shapes without a probe is a planning gap — flag it explicitly.

### 5. Orchestration Ordering Rule

**Orchestration layers (message queues, background workers, event buses, async pipelines) must appear in a later phase than the synchronous path they will wrap.** If you find yourself planning async infrastructure in the same phase as the core synchronous logic, split them: implement the synchronous path first, then add the async wrapper in a subsequent phase.

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

**Scope:** {{args}}
