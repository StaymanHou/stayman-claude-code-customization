---
name: feature-finalize
description: "Feature workflow: finalize documentation, review backlog, archive WIP, assess tech debt"
argument-hint: <optional feature name>
---

# Feature Finalize

You are an expert Software Engineer wrapping up a completed feature.

## State Machine Context

You are in the **feature** workflow at the **finalize** state.

**Entered from:**
- **F39** — `feature-review-quality` exit, clean review (no findings, MINOR auto-backlogged, or Mode-3 MAJOR auto-backlogged)
- **F41** — `feature-review-quality` exit, Mode-2 MAJOR after operator pause-and-ask
- **F17b** — `feature-ship` direct hand-off in Mode 4 (fsd), where review-quality is skipped entirely
- (Also re-entered from `feature-refactor` cycles via F40 → refactor → … → finalize, if CRITICAL refactor completed during this feature)

**Valid transitions from here:**
- **F18 → refactor:** Tech debt identified during this feature → tell user to run `/feature-refactor`
- **F19 → EXIT + reflect:** No tech debt, feature done → auto-trigger reflect
- **F30 → product-finalize:** No tech debt AND `workflow-system/product/wbs.md` exists with all WPs `[x]` → tell user to run `/product-finalize`

## Procedure

### 0. Precondition — has ship happened?

Read the WIP file's `## Current Node`. If `**Path:**` contains `verify-codify` AND `**Unvisited:**` contains `feature-ship`, STOP — do not modify any files. Tell the user: "Run `/feature-ship` first, then re-invoke `/feature-finalize`." See `SURFACE-2026-05-06-FINALIZE-BEFORE-SHIP-ORDER-FLIP`.

### 1. Update Documentation
- Update relevant docs to reflect the new feature (API docs, setup guides, etc.)
- Update the project `CLAUDE.md` (root) if new patterns or critical rules were discovered
- Update `workflow-system/product/wbs.md` and `workflow-system/product/roadmap.md` to reflect the completed feature (check off milestones, mark WPs done). Bump `updated:` in frontmatter.
- **WBS per-task checkbox tick (required):** when marking a WP done in `workflow-system/product/wbs.md`, after appending the `✅ SHIPPED <date> (commit <sha>)` tag to the WP heading, ALSO convert every `- [ ]` to `- [x]` **within that WP's section only** (between the WP's heading and the next WP heading, or EOF if it's the last WP). The WP being shipped means by definition all its tasks landed — leaving unticked task checkboxes underneath a `✅ SHIPPED` heading makes WBS a partially-trustworthy state surface for downstream planning skills. Do **not** use a global `replace_all` across the whole file — that would mistakenly tick checkboxes in other WPs that are still in-progress. If a task genuinely did not land, the WP should be re-scoped explicitly in WBS rather than silently shipped with hidden gaps.

### 2. Full Backlog Review
Scan `workflow-system/state/backlog.md` for ALL unresolved items:
- Items surfaced during this feature's development
- Items from other workflows that may be affected
- **Identify items this feature's work resolved.** Per the **delete-on-resolve** rule (`CLAUDE.snippet.md` → `## CHANGELOG.md convention` → `### Append discipline`), a resolved item is **deleted** from the backlog — not marked `Status: resolved`. Note which items are resolved here; the actual deletion happens in §3c under the CHANGELOG-then-delete invariant (delete staged in the same commit as the `**Backlog resolved:**` CHANGELOG line). **Fully-resolved** items are deleted; **partially-resolved** items (open work remains) are **rewritten** to the remaining open work, not deleted. Buried/deferred items are a different lifecycle — never deleted here.
- Present the full backlog summary to the user

### 3. Archive
- Mark the WIP plan as "Completed" with completion date
- Move to `workflow-system/state/archive/` (create directory if needed)
- Clean up `workflow-system/state/wip/`

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
2. **Zero or more `**Backlog resolved:**` bullets** — one per backlog item that step 2 (Full Backlog Review) identified as resolved by this feature's work. Each bullet leads with the SURFACE ID (e.g. `**Backlog resolved:** SURFACE-2026-05-11-FOO — closed by <feature name>`).
3. **Zero or one `**Milestone:**` bullet** — emit only if this feature completed a WBS work package. Compose from the WP name in `workflow-system/product/wbs.md`.

**Delete-on-resolve (CHANGELOG-then-delete hard invariant):** for each `**Backlog resolved:**` bullet you emit, you must also **delete** that item's entry from `workflow-system/state/backlog.md` in the **same commit** (for a code-quality finding, also delete the full body from `workflow-system/state/backlog-quality-findings.md` and its pointer stub in `backlog.md`). No backlog delete without the matching CHANGELOG line landing in that commit. **Partial resolutions** are **rewritten** to remaining open work, not deleted (the resolved sub-part still emits a `**Backlog resolved:**` line). See `CLAUDE.snippet.md` → `### Append discipline` for the full rule.

**Operational sequence (must be in this order to avoid the SURFACE-2026-05-10-FINALIZE-RETROSPECT-LOST-IN-GIT-MV failure mode):**

The §3 "Archive" step lists the `git mv` action but the actual execution order is: write retrospect (§3b) → append to CHANGELOG (§3c) → delete/rewrite resolved backlog entries → archive move (§3). Carry out the move as the last on-disk action:

1. Retrospect already written into the WIP file by §3b.
2. Edit `<proj_root>/CHANGELOG.md` per the convention above (write the `**Backlog resolved:**` line(s) **first**).
3. **Delete each resolved item's entry** from `workflow-system/state/backlog.md` (+ `workflow-system/state/backlog-quality-findings.md` body & stub for a code-quality finding); rewrite any partially-resolved entry to its remaining open work. This is the delete-on-resolve step — it happens *after* the CHANGELOG line is written, satisfying the hard invariant.
4. `git add CHANGELOG.md <wip-file> workflow-system/state/backlog.md workflow-system/state/backlog-quality-findings.md` — stage CHANGELOG + the WIP file with retrospect + the backlog edits together (so the delete and its CHANGELOG record land in the same commit).
5. `git mv <wip-file> workflow-system/state/archive/<wip-file>` — perform the move now (the §3 action).
6. Single commit captures retrospect edit + CHANGELOG append + backlog delete/rewrite + archive move.
7. **Do NOT `git push`.** The close commit lands locally only. Pushing is the operator's call — they may want to review, squash with sibling work, or amend a follow-up learning (via `/session-store-learning`) before publishing. Auto-pushing here forecloses those options. If the operator explicitly requests a push, do it then; otherwise leave HEAD local.

**Idempotency:** if the WIP file is already inside `workflow-system/state/archive/`, the append is a no-op — skip it. (Re-running finalize on an already-archived item should not double-write the changelog.)

### 4. Tech Debt Assessment
Review the implementation for tech debt:
- Code that works but could be cleaner
- Patterns that should be standardized
- Performance improvements deferred during build

**If tech debt exists (F18):**
- List the specific items
- Tell user to run `/feature-refactor` to address them

**If no tech debt — check WBS completion (F19 vs F30):**

Check whether `workflow-system/product/wbs.md` exists and all work packages are marked `[x]`:
- **WBS exists and all WPs `[x]` (F30):** The entire product cycle is complete. Tell user: "Feature complete and WBS fully done. Run `/product-finalize` to resync architecture docs, sweep the backlog, and archive the completed product cycle."
- **No WBS, or WBS has incomplete WPs (F19):** Feature is done but product cycle continues. Tell user: "Feature complete. Running reflection..." and recommend `/session-reflect`

**Feature Name:** {{args}}
