---
workflow: task
state: ESCALATED to feature:spec
created: 2026-06-12
escalated: 2026-06-12
docs-only: true
---

# Task: Close-commit discipline — amend learnings to HEAD; codify no-auto-push

**Workflow:** task
**State:** ESCALATED to feature:spec (2026-06-12)
**Created:** 2026-06-12

## Escalation note

Escalated mid-verify because the original task framing was wrong:

- The `docs-only: true` declaration was incorrect. SKILL.md prose IS the runtime surface for skill behavior — the next time any close skill runs, the model executes the new prose. Pure prose ≠ docs-only; that flag is for backlog edits, README touches, CLAUDE.md prose where no skill consumes the text at runtime.
- The change touches 5 SKILL.md files across 4 terminal-close skills + 1 meta skill — that's a workflow-system contract change, properly scoped to feature, not task.
- The five SKILL.md edits **remain in the working tree** (uncommitted). The feature spec/plan should adopt them as Phase 1 implementation output and design verification (behavioral scenarios + structural pins) in subsequent phases.
- Verification design needed: (a) behavioral test scenarios in `tests/scenarios/*.yaml` exercising each close skill's new prose; (b) structural pins in `tests/check-structure.sh` for the new clauses (note: per the existing `SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT` harness limitation, behavioral scenarios can only soft-assert content — structural pins are the hard-assert path).
- The original `SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH` (P1) does NOT resolve via this escalation — it resolves when the feature ships.

## Problem Statement

`SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH` keeps re-surfacing despite the rule being "acknowledged — no action": uncommitted learning files between feature ship and the next session are exactly the kind of cross-feature-pause loose state that gets destroyed by `git checkout HEAD --` or stash-replay errors. Fix the failure mode at its narrowest source — `session-store-learning` — by amending project-scope learnings into the just-completed HEAD commit, AND codify the existing (already-correct) no-auto-push behavior across all four terminal-close skills so future drift can't reintroduce a destructive push.

## Context

- **Five SKILL.md files to edit:**
  - `skills/session-store-learning/SKILL.md` — §5 "Execute" path for project-scope writes; add `git commit --amend --no-edit` after the file write. Global-scope path (gitignored `.claude/learnings/`) does NOT amend.
  - `skills/feature-finalize/SKILL.md` — §3c step 5 "Single commit captures …" — append no-auto-push clause.
  - `skills/task-close/SKILL.md` — §6 step 5 "Single commit captures …" — append no-auto-push clause.
  - `skills/incident-resolve/SKILL.md` — §4b step 4 "Single commit captures …" — append no-auto-push clause.
  - `skills/product-finalize/SKILL.md` — §6b operational-sequence note — append no-auto-push clause.

- **Empirical finding from context discovery:** None of the four close skills currently emit a `git push` instruction (grep on `push|commit|amend` against `arch.md` returns no matches; grep across the five SKILL.md files shows current text says "commit" and "git mv" only — no push). The Change-2 work is therefore **codification of existing behavior** as a load-bearing contract, not a behavior reversal. This matters for retrospect — we're not fixing a bug, we're preventing future drift.

- **Why amend-to-HEAD (not detect-finalize-commit):** Per operator confirmation in this session — simple wins. The procedure surface in `session-store-learning` runs after `/session-reflect`, which runs after a close skill, so HEAD will almost always be the close commit. If a user runs `/session-store-learning` outside that cadence and HEAD is something else (e.g., user committed manually in between), amend-to-HEAD still lands the learning into a sensible local commit rather than leaving it uncommitted. The "uncommitted = loseable" failure mode is what we're closing; the "amended into a non-finalize commit" outcome is benign (and reversible via `git reset --soft HEAD~1` / `git rebase -i`).

- **Global-scope learnings (`.claude/learnings/<date>-<slug>.md`):** these are gitignored. The amend instruction must NOT fire for global-scope — `git add` of a gitignored file would silently no-op (or worse, require `-f` and stage something the user explicitly didn't want tracked). Procedure must branch on scope: project-scope → amend; global-scope → skip amend, keep existing local-file behavior.

- **Backlog state:** TODO contains P1 (this item) and P2 (`SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT`). No conflict — P2 is a separate harness limitation, unrelated to commit discipline.

- **Original SURFACE description's two angles are obviated by this approach:**
  - Angle (a) — porting the "commit before branching workflows" rule to global CLAUDE.md — becomes unnecessary because the failure mode it tried to prevent (uncommitted learning files between sessions) is now mechanically prevented by amend-to-HEAD.
  - Angle (b) — re-surfacing dampener in session-reflect — also unnecessary because the rule itself is now structurally embedded in skill procedure rather than living as a "remember to do this" convention.
  - The original SURFACE can be resolved-by-this-task in the post-close backlog sweep.

## Work Tree

- [x] T1 Edit `skills/session-store-learning/SKILL.md` §5 — add amend-to-HEAD step for project-scope path; explicit no-amend for global-scope path  <!-- done -->
- [x] T2 Edit `skills/feature-finalize/SKILL.md` §3c step 5 — append no-auto-push clause  <!-- done -->
- [x] T3 Edit `skills/task-close/SKILL.md` §6 step 5 — append no-auto-push clause  <!-- done -->
- [x] T4 Edit `skills/incident-resolve/SKILL.md` §4b step 4 — append no-auto-push clause  <!-- done -->
- [x] T5 Edit `skills/product-finalize/SKILL.md` §6b operational-sequence — append no-auto-push clause  <!-- done -->

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
