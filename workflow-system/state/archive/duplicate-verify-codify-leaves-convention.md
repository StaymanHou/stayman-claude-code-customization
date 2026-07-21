---
workflow: task
state: close (complete)
created: 2026-06-12
completed: 2026-06-12
docs-only: true
---

# Task: Document duplicate-verify-codify-leaves hygiene gap as CLAUDE.md convention

**Workflow:** task
**State:** Completed
**Created:** 2026-06-12
**Completed:** 2026-06-12

## Problem Statement

A WIP-file hygiene gap was caught by the code-quality reviewer subagent (`verify-self-and-review-quality-subagent-dispatch`, 2026-06-12): when a phase completes `verify-codify`, the completion note can be **appended above** the original `- [ ] verify-codify` NOT-STARTED line instead of **replacing** it — leaving two `verify-codify` leaves under one phase, one `[x]` and one `[ ]`. Per the global Work-Tree-format rule ("a parent's checkbox may only be `[x]` when ALL children are `[x]`"), this means the phase is technically not cleanly closed even though everything else is. Option (a) — doc-only — was chosen over Option (b) (structural pin scanning WIP archives).

## Context

- **Backlog item:** `SURFACE-2026-06-12-QUALITY-WIP-DUPLICATE-VERIFY-CODIFY-LEAVES` in `workflow/backlog.md` (lines ~9-18, P-quality)
- **Pattern source:** `workflow/archive/verify-self-and-review-quality-subagent-dispatch.md` Phases 2 and 3 (each carried a duplicate `verify-codify` leaf at ship time, lines 259-260 and 285-286 of the WIP at ship time)
- **Convention surface to edit:** `CLAUDE.md` → `## Conventions` block (currently 247 lines into the file; orphan L1 + L2 already appended at lines 248-249)
- **Related conventions already present:** Work Tree status vocabulary and "parent completion" rule under `### Rules` in `CLAUDE.snippet.md` (injected globally into `~/.claude/CLAUDE.md` by `install.sh`); plan-time downstream-contract-impacts discipline; build-time selector-emission discipline — all of these are operator-grep-or-eye disciplines that the structural pins don't enforce, so this new bullet fits the existing pattern of "things to check by hand because mechanically pinning them is heavier than the bite warrants."

## Work Tree

- [x] T1 Verify orphan L1 + L2 bullets are already at end of CLAUDE.md `## Conventions` block (confirm presence; no edit if intact)  <!-- confirmed via git diff: L1+L2 at lines 248-249, intact -->
- [x] T2 Append new convention bullet after L2: "Verify-codify leaf substitution discipline" — operator-check pattern at verify-codify completion time, plus the 2026-06-12 empirical anchor  <!-- appended at CLAUDE.md line 250 -->
- [x] T3 Commit the 3 CLAUDE.md edits + the resolved-backlog cleanup (already staged in workflow/backlog.md) as one doc-commit  <!-- commit d4be9c6 -->

## Current Node

- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none

## Verification

Verification skipped: docs-only declared at plan time. No runtime surface to verify.

## Discoveries

<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect

- **What changed in our understanding:** Nothing new — the failure mode was already well-understood from the code-quality-reviewer's MAJOR finding. The task was pure transcription of a known pattern into the conventions doc.
- **Assumptions that held:** docs-only + bundled commit + auto-skip verify gate is the right shape for a 3-bullet CLAUDE.md task. Three task steps was enough; no back-loops needed.
- **Assumptions that were wrong:** None.
- **Approach delta:** Implementation matched plan exactly. T1 was a no-op (orphan bullets already on disk from prior session), T2 was a single Edit append, T3 was one commit bundling 3 files.
