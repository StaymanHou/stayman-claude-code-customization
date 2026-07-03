---
name: session-reflect
description: "Session operation: post-session reflection — identify wrong assumptions, lessons learned, and prompt store-learning"
argument-hint: <optional context about what to reflect on>
---

# Session Reflect

You are conducting a post-session reflection to identify assumption errors and improvement areas.

## Context

This is a **session meta-operation**, not a state in a workflow state machine.

**Triggers:**
- **Auto-trigger** after: `feature:finalize`, `feature:refactor`, `incident:resolve`
- **Optional** after: `task:close` (if significant learning occurred)
- **Manual** invocation by the user at any time

## Procedure

### 1. Gather Session Context
Review the conversation and workflow history:
- What was the original goal?
- What was the plan?
- What actually happened?

### 2. Reflection Analysis
Identify and present:

**Wrong Assumptions:**
- What did you (the agent) assume that turned out to be incorrect?
- What did the human assume that needed correction?
- What information was missing that would have changed the approach?

**Approach Evaluation:**
- Was the approach optimal, or would a different path have been faster/better?
- Were there unnecessary detours or wasted effort?
- What went unexpectedly well?

**Key Learnings:**
- Technical insights (patterns, APIs, gotchas)
- Process insights (what workflow steps helped or hindered)
- Domain insights (business logic, user behavior)

### 2a. Candidate filter — apply BEFORE presenting (this is the load-bearing step)

The job of this skill is to surface the *few* learnings worth a store decision, not to enumerate everything that happened. Reflection has historically over-proposed ~3–4× what the operator keeps, forcing manual pruning every session. Do the pruning here.

Run every candidate Key Learning through the gates below and sort it into one of three tiers. **Only tier-1 (store candidate) costs the operator a decision** — tiers 2 and 3 are read-only.

**DROP gates — a candidate is *suppressed* (tier 3) if ANY of these is true:**

1. **Workflow/process commentary.** The candidate is an observation *about the workflow system itself* — how verify-self/verify-human/autopilot/pause-policy/plan-time-grep behaved, whether a phase split was right, estimation ratios (test-LOC multipliers, plan-vs-actual LOC), "N options works best," "probe-before-build worked again." These are almost never stored. Suppress **unless** it is a concrete, novel, reusable rule change that *also* clears the `[GLOBAL]` gate in §2b — a rare, high-bar exception. *(Carve-out: in this repo — `my-claude-code-customization` — the workflow system IS the domain, so these are legitimately common; do NOT suppress them here.)*
2. **Single-observation generalization.** The candidate generalizes from one instance ("this pattern generalizes," "these coefficients transfer," "this approach works"). One data point is not a durable learning. Suppress unless the mechanism is independently verifiable, not merely "it worked once."
3. **Self-documenting restatement.** The candidate restates what the code, config, plan, or an existing doc already plainly says ("container X publishes no host port," "module lives in package Y"). Suppress — reading the artifact is faster than reading a memory about it.

**Already-persisted gate — a candidate is *tier 2 (already-persisted)*, NOT a store candidate, when:**

- The insight is already written where a future session would find it — the project root `CLAUDE.md`, `arch.md`, `wbs.md`, a code comment at the relevant site, the WIP file, or an existing backlog `SURFACE` entry — **AND you can cite the specific location.** Before claiming a learning is novel, assume it is probably already captured and look.
- **You MUST cite the location** (file + section/line) to place a candidate in tier 2. If you believe it's covered but cannot cite where, it stays a **tier-1 store candidate** — never silently drop a genuine learning on an uncited hunch. (Fail-safe: an uncited dismissal is the invisible failure mode this rule prevents.)

**STORE bar — a tier-1 store candidate must survive the DROP gates AND match one of these three kept shapes** (these are what actually get stored, historically):

- **Empirical external-tool/API/framework gotcha** — a non-obvious behavior of a library, CLI, service, or platform, learned by observation, costly to rediscover (rendering quirks, API field semantics, dependency-version pins, host/port/env behaviors, framework binding rules). → almost always a `[PROJECT]` **Memory**.
- **Standing code-contract / convention for THIS repo** — a constraint that must hold across future edits (a two-axis guard, a plan-time grep obligation, a naming rule). → a `[PROJECT]` **Context Rule** (project root `<proj-dir>/CLAUDE.md`).
- **Genuine cross-project workflow-mechanism change** — a rare insight that changes how the *workflow system itself* should work across all projects. → `[GLOBAL]` (must clear the §2b gate).

A candidate that survives the DROP gates but fits none of these shapes is borderline → suppress into tier 3 rather than presenting it in full.

**Design priors (backstop sweep):**
- Did any decision this session reveal a durable **design prior** — a transferable product-design lean (focus-vs-breadth, perf-vs-ship, defaults-vs-config, an anti-persona, …) with a *why* that will recur on future decisions? This is the catch-all for capture checkpoints the in-the-moment capture missed (the "less-likely" steps).
- If yes, **propose** recording it to `docs/product/design-priors.md` (propose-never-auto-write; the operator reviews/enriches the why; dedup/conflict-check existing priors first). **Exclusions:** technical/stack tradeoffs → `arch.md`, not a prior; bare facts / one-off fixes → not a prior. See `CLAUDE.snippet.md` → "Design priors (GLOBAL)".

### 2b. Scope default — lean PROJECT; `[GLOBAL]` must earn it

Historically the agent systematically over-labels `[GLOBAL]`: of every learning the operator re-scoped at store time, **all were `[GLOBAL]`→`[PROJECT]`, none the other way** (15→0 directional). Correct for it — default down, and make global earn its label.

- **Default every tier-1 store candidate to `[PROJECT]`.** A concrete gotcha, convention, or fix discovered while working in this repo is project-scope by default — even when it *feels* like it might generalize. "Could apply elsewhere" is NOT sufficient for global; the operator consistently prefers to keep such things project-local and hand-port later if a second project ever hits it.
- **Label `[GLOBAL]` only when ALL THREE hold:** (a) the learning is about the *workflow system / agent-operation itself*, not any one codebase's domain, tools, or stack; AND (b) it would change behavior in an unrelated project with a different stack; AND (c) you can name the specific cross-project mechanism it changes. Absent all three, it is `[PROJECT]`.
- **Even then, `[GLOBAL]` is a draft, not an install** (see `session-store-learning` — it lands in `<proj-dir>/.claude/learnings/` for the operator to hand-port). So the bar is "worth the operator's time to review and carry to the source repo," which is high. When in doubt, `[PROJECT]`.

**Carve-out — this repo (`my-claude-code-customization`):** here the workflow system IS the domain, so `[GLOBAL]`-flavored workflow-mechanism learnings are legitimately common and are tracked first-class (per this repo's `## Artifact tracking overrides`). The lean-project default still applies to repo-specific *authoring* conventions (those go to this repo's root `<proj-dir>/CLAUDE.md`).

### 3. Present Reflection
Format as:

Present the learnings in **three tiers**, in this order. The tiers come directly from the §2a filter — do not re-derive them here.

```markdown
## Session Reflection — <YYYY-MM-DD>

### Wrong Assumptions
- <assumption> → <reality>

### What Went Well
- <positive outcome>

### What Could Improve
- <improvement area>

### Key Learnings — store candidates
<!-- Tier 1: survived the DROP gates + met the STORE bar. These are the ONLY items that cost a store decision. -->
1. [PROJECT] <learning> — <one-line why it clears the STORE bar>
2. [GLOBAL] <learning> — <names the cross-project mechanism it changes (required for the [GLOBAL] label)>

### Already persisted (no action needed)
<!-- Tier 2: real learnings already captured elsewhere. Each MUST cite where. Not offered for storage. -->
- <learning> — already in `<file>` <section/line>
<!-- Omit this whole section if empty. -->

### Considered and dropped
<!-- Tier 3: one line, collapsed. Suppressed by a DROP gate. Kept visible so a mis-suppression is recoverable at a glance. -->
- <candidate A>, <candidate B>, <candidate C> (<reason: process-commentary / single-observation / self-documenting>)
<!-- Omit this line if empty. -->
```

**Tier discipline:**
- **Scope label leads on tier-1 items.** Each store candidate starts with a bracketed `[GLOBAL]` or `[PROJECT]` label (uppercased, matching the `[SHORTCUT-...]` / `[SURFACED-...]` audit-marker style used elsewhere) so scope is visible at a glance. `[GLOBAL]` = reusable across all projects (cleared the §2b 3-part gate); `[PROJECT]` = this repo only (the default). This is the same scope vocabulary `session-store-learning` consumes when routing.
- **Tier 2 requires a citation.** No cited location → the item is tier 1, not tier 2 (per §2a fail-safe).
- **Tier 3 is one line.** Never expand a dropped candidate into full prose; the collapsed list is the entire tier. Its purpose is an auditable veto surface, not a discussion.
- **Default to fewer.** If §2a leaves zero tier-1 candidates, say so plainly ("No store candidates this session") — that is the common, correct outcome, not a failure.

### 4. Prompt Store-Learning

**Only tier-1 store candidates** are offered for persistence — tiers 2 and 3 are read-only and never routed to `session-store-learning`.

- **If there are tier-1 candidates:** recommend "Run `/session-store-learning <the specific tier-1 learnings>` to persist them." Pass them pre-scoped (the `[PROJECT]`/`[GLOBAL]` labels from §2b) so store-learning routes without re-deciding.
- **If there are no tier-1 candidates:** do NOT recommend `/session-store-learning`. State "Nothing to persist this session" and stop.

**Context:** {{args}}
