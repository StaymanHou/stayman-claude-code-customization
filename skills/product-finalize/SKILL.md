---
name: product-finalize
description: "Product workflow: resync durable docs, check roadmap milestones, sweep backlog, and archive cycle-scoped docs on WBS completion"
argument-hint: <optional cycle name for the archive directory, e.g. "my-product-v1" — defaults to wbs.md title slug>
---

# Product Finalize

You are an expert Technical Lead closing out a completed product cycle.

## State Machine Context

You are in the **product** workflow at the **product-finalize** state.
This state is triggered when `feature-finalize` detects that all WBS items are complete.

**Valid transitions from here:**
- **P13 → EXIT:** Cycle closed, docs archived → product cycle is done
- **P14 → arch (back-loop):** Resync reveals a significant architectural drift that must be documented in arch.md before archiving → tell user to run `/product-arch`

## Procedure

### 1. Confirm WBS Completion

Read `docs/product/wbs.md`. Verify that ALL work packages are marked `[x]`.

- If any WP is not `[x]`: stop. Do not proceed. Tell the user which WPs are incomplete and why product-finalize cannot run yet.
- If all WPs are `[x]`: proceed.

### 2. Resync Durable Docs Against Reality

Read `docs/product/arch.md` (and `docs/product/transitions.md` if it exists). Then read the completed WBS and the feature archive in `workflow/archive/` to understand what was actually built.

For each durable doc, ask: **does this still accurately describe the system as built?**

Common drift patterns to look for:
- Skills, states, or transitions added/renamed during implementation that aren't reflected in arch.md
- Design decisions made during features that changed the architecture (e.g., "we decided not to use X, used Y instead")
- New conventions codified in CLAUDE.md or CLAUDE.snippet.md that aren't reflected in arch.md
- Sections of arch.md that describe planned behavior that was never built or was built differently

**For each drift found:**
- Minor drift (wording, naming, small additions): update arch.md in place, note the change
- Significant drift (a design decision was reversed, a component is fundamentally different): flag it explicitly and consider P14 back-loop to `/product-arch` for a proper revision

Update `docs/product/arch.md` with any corrections. Bump `updated:` in its frontmatter.

### 3. Roadmap Milestone Check

Read `docs/product/roadmap.md`. For each milestone defined there (older roadmaps may label these "Phase" — treat "phase" as a read-alias for "milestone"):
- Is it covered by completed WPs in the WBS? Mark it done.
- Are there roadmap exit criteria? Confirm they are satisfied.
- Are there any roadmap milestones that remain incomplete?

If all roadmap milestones map to completed WBS work: confirm this in a brief note and continue.

If a roadmap milestone is incomplete or its exit criteria are unmet: surface this to the user. Do not silently archive — an incomplete milestone is a gap that needs acknowledgment.

Update `docs/product/roadmap.md` to reflect completion status. Bump `updated:` in frontmatter.

### 4. Backlog Sweep

Read `workflow/backlog.md`. For every item with `**Status:** pending`:

Evaluate each against one of three outcomes:
- **Resolved** — the completed WBS work addressed it. Per the **delete-on-resolve** rule (`CLAUDE.snippet.md` → `## CHANGELOG.md convention` → `### Append discipline`), **delete** the item's entry from `workflow/backlog.md` (+ `workflow/backlog-quality-findings.md` body & stub for a code-quality finding) — do **not** mark it `resolved — closed by …`. The deletion is committed in §6b under the CHANGELOG-then-delete invariant (delete staged in the same commit as the `**Backlog resolved:**` CHANGELOG line). **Fully-resolved** items are deleted; a **partially-resolved** item is **rewritten** to its remaining open work.
- **Deferred** — valid but not in scope for this cycle. Update status to `deferred — carry to next cycle`. (Deferred is a different lifecycle — NOT delete-on-resolve; the entry stays.)
- **Escalated** — requires immediate attention before archiving. Surface to user; do not archive until addressed.

Present a summary of all backlog items and their disposition before proceeding.

**Advisory pointer (not a gate, not a transition):** if this sweep leaves a sizable pile of `deferred`
code-quality / refactor / hygiene items — the rolled-forward `/feature-refactor` batch that never ran —
consider invoking `/util-backlog-paydown` to actually pay it down in a focused between-milestone sweep.
`product-finalize` *records* dispositions; `/util-backlog-paydown` *does* the deferred work. This is a soft
suggestion surfaced to the operator only — it emits no transition and does not auto-chain into the sweep.

### 5. Determine Archive Name

If `{{args}}` provides a cycle name, use it as the archive directory name (slugified).

If no args: derive the cycle name from the WBS title (first `#` heading in wbs.md), slugified — e.g., "Claude Code Workflow System" → `claude-code-workflow-system`.

Archive path: `docs/product/archive/<cycle-name>/`

### 6. Archive Cycle-Scoped Docs

Move the following to `docs/product/archive/<cycle-name>/`:
- `docs/product/wbs.md`
- `docs/product/research.md` (if present)
- Any cycle-scoped diagnostic or scratch docs — files that were created for this specific WBS cycle and are no longer active reference material (e.g., `workflow-pain-points.md`, `spike-results.md`)

**Do NOT move:**
- `docs/product/vision.md` — spans multiple cycles
- `docs/product/arch.md` — durable architecture reference (just resynced in step 2)
- `docs/product/transitions.md` — durable architecture reference
- `docs/product/roadmap.md` — durable strategic reference
- Any doc the user has explicitly indicated should stay

Before moving each file, confirm it is not referenced by any currently active workflow item in `workflow/wip/`.

### 6b. Append to CHANGELOG (required)

Append closure entries to `<proj_root>/CHANGELOG.md` per the **CHANGELOG.md convention** in `~/.claude/CLAUDE.md` (injected from `CLAUDE.snippet.md`). Read that section for the canonical rules — file shape, heading case, same-day grouping, entry-kind vocabulary, append-before-`git mv` discipline.

For this skill, the entries to emit under today's `## YYYY-MM-DD` heading are:

1. **One `**Product cycle complete:**` summary bullet** — composed from the cycle name and one-sentence summary of what the cycle delivered. Per-WP `**Milestone:**` lines are emitted by `feature-finalize` at WP-completion time and are not re-emitted here.
2. **Zero or more `**Backlog resolved:**` bullets** — one per item that step 4 (Backlog Sweep) identified as resolved by this cycle's work. Each bullet leads with the SURFACE ID.

**Delete-on-resolve (CHANGELOG-then-delete hard invariant):** for each `**Backlog resolved:**` bullet you emit, also **delete** that item's entry from `workflow/backlog.md` in the **same commit** (+ `workflow/backlog-quality-findings.md` body & stub for a code-quality finding). No backlog delete without the matching CHANGELOG line landing in that commit. **Partial resolutions** are **rewritten** to remaining open work, not deleted; deferred items (the other §4 outcome) keep their entries. See `CLAUDE.snippet.md` → `### Append discipline`.

**Operational sequence:**

1. Edit `CHANGELOG.md` per the convention above (one `**Product cycle complete:**` bullet + zero-or-more `**Backlog resolved:**` bullets under today's date — write the `**Backlog resolved:**` lines **first**).
2. **Delete each resolved item's entry** from `workflow/backlog.md` (+ `workflow/backlog-quality-findings.md` body & stub for a code-quality finding); rewrite any partially-resolved entry to its remaining open work. Delete-on-resolve step — after the CHANGELOG lines, satisfying the hard invariant.
3. `git add CHANGELOG.md workflow/backlog.md workflow/backlog-quality-findings.md` together with the step-6 archive moves — stage them in one go so the entire cycle-close (CHANGELOG + backlog delete/rewrite + archive moves) lands in one commit (or a tightly grouped commit pair if step 6 already commits separately).
4. Commit. Single commit captures the CHANGELOG append + backlog delete/rewrite + archive moves + any resynced durable docs.
5. **Do NOT `git push`.** The cycle-close commit(s) land locally only. Pushing is the operator's call — they may want to review the resynced durable docs, squash with sibling work, or amend a follow-up learning (via `/session-store-learning`) before publishing. Auto-pushing here forecloses those options. If the operator explicitly requests a push, do it then; otherwise leave HEAD local.

**Idempotency:** if a `**Product cycle complete:**` bullet for this cycle name already exists in CHANGELOG.md, skip the append (re-running product-finalize on an already-closed cycle is a no-op).

### 7. Confirm and Exit

After archiving:
- Confirm to the user what was archived and what was left in place.
- State the archive path.
- If the backlog had any escalated items, remind the user they need attention.

**Transition P13 — product cycle complete.**

The product cycle is closed. `docs/product/` now contains only durable cross-cycle reference material. To start a new product cycle, run `/product-vision`.

**Cycle name:** {{args}}
