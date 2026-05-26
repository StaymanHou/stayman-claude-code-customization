---
drive_mode: autopilot
---

# Task: Promote subagent re-verification heuristic into feature-verify-self SKILL.md

**Workflow:** task
**State:** Completed
**Created:** 2026-05-26
**Completed:** 2026-05-26

## Problem Statement
Backlog item SURFACE-2026-05-22-LEARNING-VERIFY-SELF-SUBAGENT-JIT-FALSE-FAIL is overdue: a recurring agent behavior (subagent reports BLOCKING FAIL on JIT-compiled / async-rendered pages, mechanically contradicted by sibling PASSes; orchestrator re-verifying directly always confirms PASS) has been observed 5-of-5 times across the claude-time-visualize-v2 cycle (WP5 P3, WP7 P2, WP8 P2, WP9, WP10) but the heuristic lives only in a gitignored local draft. Promote it into `skills/feature-verify-self/SKILL.md` so future feature-verify-self invocations have it in their loaded context.

## Context
- **Target file:** `skills/feature-verify-self/SKILL.md` — add a new `## Subagent Re-Verification Heuristic` section between the existing `## Severity Taxonomy` and `## Integration-boundary rule` sections.
- **Backlog entry:** `workflow/backlog.md` lines 59-68 (SURFACE-2026-05-22-LEARNING-VERIFY-SELF-SUBAGENT-JIT-FALSE-FAIL).
- **Rule text (source of truth, copy verbatim into the section body):**
  > "If N-1 of N outcomes PASS and the Nth FAIL is mechanically implied by the PASSes, suspect snapshot timing before back-looping; re-run the same Playwright assertions directly from the orchestrator before invoking `/feature-build` with scoped leaves."
- **Triggers documented in backlog:** JIT-compiled in-browser code (Babel-standalone), lazy-mount React, async data fetches before initial render. Practical workaround pattern that consistently worked: React-fiber direct invocation via `reactProps[fiberKey].onClick()` (also recorded as the 5th-instance pattern under `SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL`).
- **Procedural integration:** §3 (Parse subagent results) currently treats a FAIL/BLOCKING straightforwardly. The heuristic adds a pre-back-loop checkpoint: when the FAIL pattern matches mechanical implication, re-verify directly before classifying as F9b.
- **No state-machine changes.** No new transitions. The heuristic is a refinement of *how* the orchestrator parses §3 results, not *what* transitions exist.
- **No test impact expected.** Test scenarios in `tests/scenarios/feature.yaml` assert transition IDs, not SKILL.md prose. Will confirm during act by grepping scenarios for any verify-self prose pins.
- **Project repo ships via commit + push to main** (per memory `project_ship_process.md`); no PR review step.

## Work Tree

- [x] T1 Read current `skills/feature-verify-self/SKILL.md` to confirm exact insertion point + adjacent section boundaries (no surprises since last read).  <!-- status: complete -->
- [x] T2 Author the new `## Subagent Re-Verification Heuristic` section. Sections to include: rule statement (verbatim), trigger conditions (JIT-compiled / lazy-mount / async-fetch), procedure (re-run assertions directly from orchestrator; common workaround = React-fiber `reactProps[fiberKey].onClick()` direct invocation), and what to do based on the re-verification result.  <!-- status: complete -->
- [x] T3 Add a short pointer from §3 (Parse subagent results) to the new heuristic so the orchestrator sees the gate at result-parse time, not just at section-read time.  <!-- status: complete -->
- [x] T4 Edit `skills/feature-verify-self/SKILL.md` with both changes (T2 + T3).  <!-- status: complete -->
- [x] T5 Quick check: `tests/check-structure.sh` still passes (122/0 expected); grep `tests/scenarios/feature.yaml` for any verify-self prose pins that might assert on existing section structure.  <!-- status: complete — 122/0 PASS; scenarios assert on transition IDs and back-loop/cosmetic/passing prose, not on Severity-Taxonomy section structure; safe -->
- [x] T6 Close backlog item SURFACE-2026-05-22-LEARNING-VERIFY-SELF-SUBAGENT-JIT-FALSE-FAIL with a one-line closure note (status → RESOLVED 2026-05-26, mechanism: prose addition to feature-verify-self SKILL.md).  <!-- status: complete -->

## Post-completion note
- Local learning draft at `.claude/learnings/2026-05-22-verify-self-subagent-jit-false-fail.md` (project-local, gitignored) confirmed the promoted section matches the draft's "Suggested change" rule statement and "if N-1 PASSes imply the Nth outcome should hold" framing. Draft carries an additional session-log excerpt (the original WP5 P3 subagent FAIL on `#viewport=720:780` with regex `/^\d\d:\d\d$/`) that is concrete evidence not transcribed into the SKILL.md section — left in place as a historical reference. Removal is a separate decision not in this task's scope.

## Retrospect
- **What changed in our understanding:** Nothing substantive — the heuristic, trigger pattern, and workaround mechanism were already fully articulated across the backlog entry, the local learning draft, and the WP10-pause-note's "third instance, definitely promote" framing. This task was a pure promotion / codification, not discovery.
- **Assumptions that held:** (1) `tests/scenarios/feature.yaml` asserts on transition IDs and back-loop/cosmetic/passing prose, not on SKILL.md section structure → confirmed by grep; (2) `tests/check-structure.sh` is structure-only (frontmatter, symlinks, pause-policy presence) → 122/0 PASS post-edit; (3) the SKILL.md insertion point (between Severity Taxonomy and Integration-boundary rule) is the right home → matched the draft's "Suggested change" placement guidance.
- **Assumptions that were wrong:** Initially assumed the local learning draft was at `~/.claude/learnings/` (the global path mentioned in the backlog reference line). It is actually at the project-local `.claude/learnings/` path. Operator caught this. The mistake was inconsequential to the task outcome — the rule statement and trigger pattern I composed from the backlog entry matched the draft once read.
- **Approach delta:** None. Plan T1–T6 executed in order with no scope changes, no back-loops, no surprises. Mid-task interruption to read the local draft confirmed the heuristic-as-written aligns with the draft.

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
