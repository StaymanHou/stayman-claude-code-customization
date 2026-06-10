---
name: feature-finalize
description: "Feature workflow: finalize documentation, review backlog, archive WIP, assess tech debt"
argument-hint: <optional feature name>
---

# Feature Finalize

You are an expert Software Engineer wrapping up a completed feature.

## State Machine Context

You are in the **feature** workflow at the **finalize** state.

**Valid transitions from here:**
- **F18 → refactor:** Tech debt identified during this feature → tell user to run `/feature-refactor`
- **F19 → EXIT + reflect:** No tech debt, feature done → auto-trigger reflect
- **F30 → product-finalize:** No tech debt AND `docs/product/wbs.md` exists with all WPs `[x]` → tell user to run `/product-finalize`

## Procedure

### 0. Precondition — has ship happened?

Read the WIP file's `## Current Node`. If `**Path:**` contains `verify-codify` AND `**Unvisited:**` contains `feature-ship`, STOP — do not modify any files. Tell the user: "Run `/feature-ship` first, then re-invoke `/feature-finalize`." See `SURFACE-2026-05-06-FINALIZE-BEFORE-SHIP-ORDER-FLIP`.

### 1. Update Documentation
- Update relevant docs to reflect the new feature (API docs, setup guides, etc.)
- Update the project `CLAUDE.md` (root) if new patterns or critical rules were discovered
- Update `docs/product/wbs.md` and `docs/product/roadmap.md` to reflect the completed feature (check off milestones, mark WPs done). Bump `updated:` in frontmatter.
- **WBS per-task checkbox tick (required):** when marking a WP done in `docs/product/wbs.md`, after appending the `✅ SHIPPED <date> (commit <sha>)` tag to the WP heading, ALSO convert every `- [ ]` to `- [x]` **within that WP's section only** (between the WP's heading and the next WP heading, or EOF if it's the last WP). The WP being shipped means by definition all its tasks landed — leaving unticked task checkboxes underneath a `✅ SHIPPED` heading makes WBS a partially-trustworthy state surface for downstream planning skills. Do **not** use a global `replace_all` across the whole file — that would mistakenly tick checkboxes in other WPs that are still in-progress. If a task genuinely did not land, the WP should be re-scoped explicitly in WBS rather than silently shipped with hidden gaps.

### 2. Full Backlog Review
Scan `workflow/backlog.md` for ALL unresolved items:
- Items surfaced during this feature's development
- Items from other workflows that may be affected
- Update status of items resolved by this feature's work
- Present the full backlog summary to the user

### 3. Archive
- Mark the WIP plan as "Completed" with completion date
- Move to `workflow/archive/` (create directory if needed)
- Clean up `workflow/wip/`

### 3b. Retrospect + Communicate (required — two separate outputs)

These two steps are mandatory before the tech debt assessment, regardless of whether learnings occurred.

**Output A — Retrospect artifact:** Write a short retrospect in the WIP file before archiving it:

```markdown
## Retrospect
- **What changed in our understanding:** <what we learned that we didn't know at the start>
- **Assumptions that held:** <what we got right>
- **Assumptions that were wrong:** <what surprised us>
- **Approach delta:** <how the actual implementation differed from the plan, if at all>
```

If the feature was delivered exactly as planned with no surprises, record that explicitly ("No surprises — implementation matched plan exactly"). Do not skip this section.

**Output B — Communicate step:** Confirm that the requester knows the feature is done and what it does. Produce a brief closure message suitable for sharing:

> **Feature complete:** [Feature name] has shipped. [One sentence: what it does]. [One sentence: how to verify or where to see it in action, if applicable.]

If the requester is the same person running the agent (solo developer), note it as: "Requester = operator — closure notice for self-record."

### 3c. Append to CHANGELOG (required)

Append closure entries to `<proj_root>/CHANGELOG.md` per the **CHANGELOG.md convention** in `~/.claude/CLAUDE.md` (injected from `CLAUDE.snippet.md`). Read that section for the canonical rules — file shape, heading case, same-day grouping, entry-kind vocabulary, append-before-`git mv` discipline.

For this skill, the entries to emit under today's `## YYYY-MM-DD` heading are:

1. **One `**Feature shipped:**` bullet** — composed from the feature's title and one-sentence problem statement.
2. **Zero or more `**Backlog resolved:**` bullets** — one per backlog item that step 2 (Full Backlog Review) marked as resolved by this feature's work. Each bullet leads with the SURFACE ID (e.g. `**Backlog resolved:** SURFACE-2026-05-11-FOO — closed by <feature name>`).
3. **Zero or one `**Milestone:**` bullet** — emit only if this feature completed a WBS work package. Compose from the WP name in `docs/product/wbs.md`.

**Operational sequence (must be in this order to avoid the SURFACE-2026-05-10-FINALIZE-RETROSPECT-LOST-IN-GIT-MV failure mode):**

The §3 "Archive" step lists the `git mv` action but the actual execution order is: write retrospect (§3b) → append to CHANGELOG (§3c) → archive move (§3). Carry out the move as the last on-disk action:

1. Retrospect already written into the WIP file by §3b.
2. Edit `<proj_root>/CHANGELOG.md` per the convention above.
3. `git add CHANGELOG.md <wip-file>` — stage CHANGELOG + the WIP file with retrospect together.
4. `git mv <wip-file> workflow/archive/<wip-file>` — perform the move now (the §3 action).
5. Single commit captures retrospect edit + CHANGELOG append + archive move.

**Idempotency:** if the WIP file is already inside `workflow/archive/`, the append is a no-op — skip it. (Re-running finalize on an already-archived item should not double-write the changelog.)

### 4. Tech Debt Assessment
Review the implementation for tech debt:
- Code that works but could be cleaner
- Patterns that should be standardized
- Performance improvements deferred during build

**If tech debt exists (F18):**
- List the specific items
- Tell user to run `/feature-refactor` to address them

**If no tech debt — check WBS completion (F19 vs F30):**

Check whether `docs/product/wbs.md` exists and all work packages are marked `[x]`:
- **WBS exists and all WPs `[x]` (F30):** The entire product cycle is complete. Tell user: "Feature complete and WBS fully done. Run `/product-finalize` to resync architecture docs, sweep the backlog, and archive the completed product cycle."
- **No WBS, or WBS has incomplete WPs (F19):** Feature is done but product cycle continues. Tell user: "Feature complete. Running reflection..." and recommend `/session-reflect`

**Feature Name:** {{args}}
