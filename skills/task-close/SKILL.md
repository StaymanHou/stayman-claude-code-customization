---
name: task-close
description: "Task workflow: finalize the task — update docs, review backlog, archive WIP"
argument-hint: <optional notes or the specific WIP file to close>
---

# Task Close

You are an expert software engineer wrapping up a completed task.

## State Machine Context

You are in the **task** workflow at the **close** state. Reached via T5b (task-verify PASSed) — every task path runs through the verify gate before reaching close.

**Valid transitions from here:**
- **T10 → EXIT:** Task done, no significant learning
- **T11 → EXIT + reflect:** Significant learning occurred → recommend user runs `/session-reflect`

## Procedure

### 1. Find Active Plan
- Look in `workflow/wip/` for the task that was just completed
- If `{{args}}` specifies a file, use that
- **Precondition advisory:** task-verify should have PASSed before close runs. If the WIP file's `state:` is still `act (complete)` (not `verify (complete)`), or if no `## Verification Observable` / `## Verification Result` sections exist, the workflow is mid-stream — recommend running `/task-verify` first. This is an advisory note, not a hard gate (per the workflow system's advisory-enforcement convention); proceed if the user explicitly directs close-without-verify (e.g., emergency cleanup of an aborted task).

### 2. Update Documentation
- Update relevant docs to reflect changes (only if changes warrant it — don't add docs for trivial fixes)
- Update the project `CLAUDE.md` (root) if any new patterns or critical rules were discovered during this task

### 3. Full Backlog Review
Scan `workflow/backlog.md` for ALL unresolved items (not just high-priority). For each:
- Is it still relevant after this task's changes?
- Should it be addressed now or deferred?
- **Identify items this task's work resolved.** Per the **delete-on-resolve** rule (`CLAUDE.snippet.md` → `## CHANGELOG.md convention` → `### Append discipline`), a resolved item is **deleted** from the backlog — not marked `Status: resolved`. Note which items are resolved here; the deletion happens in §6 under the CHANGELOG-then-delete invariant. **Fully-resolved** items are deleted; **partially-resolved** items are **rewritten** to remaining open work. Buried/deferred items are never deleted here.

Present the backlog summary to the user.

### 4. Retrospect + Communicate (required — two separate outputs)

These two steps are mandatory before closing, regardless of whether learnings occurred. **Order matches `feature-finalize` so the canonical close sequence is consistent across the workflow system: Retrospect → CHANGELOG append → Archive.**

**Output A — Retrospect artifact:** Write a short retrospect in the WIP file before archiving it:

```markdown
## Retrospect
- **What changed in our understanding:** <what we learned that we didn't know at the start>
- **Assumptions that held:** <what we got right>
- **Assumptions that were wrong:** <what surprised us>
- **Approach delta:** <how the actual implementation differed from the plan, if at all>
```

If the task was exactly as planned with no surprises, record that explicitly ("No surprises — implementation matched plan exactly"). Do not skip this section.

**Output B — Communicate step:** Confirm that the requester knows the work is done and what it does. This is a prompted action — produce a brief closure message suitable for sharing:

> **Closure notice:** [Task name] is complete. [One sentence: what was done]. [One sentence: how to verify or where to see the result, if applicable.]

If the requester is the same person running the agent (solo developer), note it as: "Requester = operator — closure notice for self-record."

### 5. Append to CHANGELOG (required)

Append closure entries to `<proj_root>/CHANGELOG.md` per the **CHANGELOG.md convention** in `~/.claude/CLAUDE.md` (injected from `CLAUDE.snippet.md`). Read that section for the canonical rules — file shape, heading case, same-day grouping, entry-kind vocabulary, append-before-`git mv` discipline.

For this skill, the entries to emit under today's `## YYYY-MM-DD` heading are:

1. **One `**Task closed:**` bullet** — composed from the task's title and one-sentence summary of what was done.
2. **Zero or more `**Backlog resolved:**` bullets** — one per backlog item that step 3 (Full Backlog Review) identified as resolved by this task's work. Each bullet leads with the SURFACE ID.

**Delete-on-resolve (CHANGELOG-then-delete hard invariant):** for each `**Backlog resolved:**` bullet you emit, also **delete** that item's entry from `workflow/backlog.md` in the **same commit** (+ `workflow/backlog-quality-findings.md` body & stub for a code-quality finding). No backlog delete without the matching CHANGELOG line landing in that commit. **Partial resolutions** are **rewritten** to remaining open work, not deleted. See `CLAUDE.snippet.md` → `### Append discipline`.

**Idempotency:** if the WIP file is already inside `workflow/archive/`, skip the append.

### 6. Archive
- Update the WIP plan file: mark as "Completed", record completion date
- Move the plan file to `workflow/archive/` (create directory if needed)
- Clean up the `workflow/wip/` directory

**Operational sequence (must be in this order to avoid the SURFACE-2026-05-10-FINALIZE-RETROSPECT-LOST-IN-GIT-MV failure mode):**

1. Retrospect already written into the WIP file by §4.
2. CHANGELOG already edited by §5 (the `**Backlog resolved:**` line(s) written **first**).
3. **Delete each resolved item's entry** from `workflow/backlog.md` (+ `workflow/backlog-quality-findings.md` body & stub for a code-quality finding); rewrite any partially-resolved entry to its remaining open work. Delete-on-resolve step — happens *after* the CHANGELOG line, satisfying the hard invariant.
4. `git add CHANGELOG.md <wip-file> workflow/backlog.md workflow/backlog-quality-findings.md` — stage CHANGELOG + the WIP file with retrospect + the backlog edits together.
5. `git mv <wip-file> workflow/archive/<wip-file>` — perform the archive move now.
6. Single commit captures retrospect edit + CHANGELOG append + backlog delete/rewrite + archive move.
7. **Do NOT `git push`.** The close commit lands locally only. Pushing is the operator's call — they may want to review, squash with sibling work, or amend a follow-up learning (via `/session-store-learning`) before publishing. Auto-pushing here forecloses those options. If the operator explicitly requests a push, do it then; otherwise leave HEAD local.

### 7. Reflect Check
Evaluate whether significant learning occurred during this task (beyond what was captured in the retrospect):
- Were there wrong assumptions that were corrected?
- Were there unexpected discoveries?
- Was the approach significantly different from the plan?

**If yes:** Tell the user: "This task had notable learnings. Run `/session-reflect` to capture them."

**If no:** Task is done. Confirm closure to the user.
