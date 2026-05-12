---
workflow: feature
state: plan (complete)
created: 2026-05-12
drive_mode: autopilot
surface_id: SURFACE-2026-05-11-SESSION-START-SUGGEST-FROM-BACKLOG
---

# Feature: session-start suggest from backlog

## Problem Statement

When `/session-start` finds no paused session and no active WIP, it asks "What are you tackling?" with no context — even though `workflow/backlog.md` typically contains open candidate work the user has already curated. The user has to switch context, open the backlog file, scan it, then come back. The skill should volunteer the top-priority open items as candidates *before* the open-ended question, turning the backlog into a useful starting menu. Resolves SURFACE-2026-05-11-SESSION-START-SUGGEST-FROM-BACKLOG (medium priority, user-confirmed live in the 2026-05-12 session that filed this WIP).

## Design Decisions (resolved from the SURFACE's open questions)

1. **Trigger:** Only when no other active work is found in step 1. If a paused session, active WIP, or in-progress product doc exists, surface that as today — do not add backlog noise on top.
2. **Ranking:** By `**Priority:**` field tier (`high` → `medium-high` → `medium` → `low`), then by SURFACE date descending (newest first) within each tier. Priority is the field humans already curate.
3. **Show top-3** with a "more" affordance ("…and N more — say 'more backlog' to see the full list"). Hard cap on initial display to avoid overwhelming the user; the volume can grow.
4. **Numbering discipline (anti-bug, learned from SURFACE-2026-05-12-STORE-LEARNING-WRONG-ITEM-SELECTED):** Each candidate is shown with its full SURFACE-ID alongside a local "1./2./3." index, and the skill explicitly tells the user *both* are valid references. When the user picks, the skill confirms by ID before routing. Numbering refers to the displayed top-3, not the full backlog.
5. **Output placement:** Candidates are shown immediately *before* "What are you tackling?", as a "By the way, the backlog has these open items —" preface. The user can pick a candidate or describe new work and the backlog suggestion is ignored.
6. **Parsing rules:** Read `workflow/backlog.md`, extract each `## SURFACE-…` block, take its `**Priority:**` line tier and `**Summary:**` first sentence (or first 80 chars if no summary heading). Include entries whose `**Status:**` line is `open` *or* missing (defensive — old entries may lack a status line). Skip entries with `**Status:** resolved`. Backlog file absent → silent no-op.

## Work Tree

- [x] Phase 1: Add backlog-surfacing to session-start step 1  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: In a project with no `.session.md`, empty `workflow/wip/`, no in-progress `docs/product/*.md`, and a `workflow/backlog.md` containing ≥1 open `## SURFACE-…` block, running `/session-start` (no args) produces output containing all three of: (a) the literal string "the backlog has" or "Open backlog items", (b) at least one `SURFACE-` identifier from the file, (c) the prompt "What are you tackling?" — and these appear in *that* order (backlog block first, question after).
  - CLI: In a project with no `.session.md`, empty `workflow/wip/`, no in-progress product doc, and *no* `workflow/backlog.md` at all, running `/session-start` (no args) produces output that does NOT contain "the backlog" or "Open backlog" but DOES contain "What are you tackling?" — i.e., silent no-op when the file is missing.
  - CLI: In a project with an existing active WIP file (e.g., `workflow/wip/example.md`), running `/session-start` produces output mentioning the active WIP and does NOT show the backlog suggestion block — backlog is suppressed when other work is present.
  - File: `skills/session-start/SKILL.md` step 1 contains an explicit instruction to read `workflow/backlog.md` when no other active work was found, including the parsing rules, ranking, top-3 cap, and numbering anchor described in Design Decisions.
  - [x] P1.1 Update `skills/session-start/SKILL.md` step 1 with the backlog-read instructions, ranking rule, top-3 cap, numbering anchor, and silent-no-op-on-missing rule  <!-- status: complete -->
  - [x] P1.2 Update `skills/session-start/SKILL.md` step 2 ("Classify the work") to recognize when the user replies with a SURFACE-ID or local 1/2/3 reference and treat it as the classification input (lift the summary text from the matched backlog entry as `{{args}}`)  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete: check-structure.sh 34/34 PASS; markdown frontmatter + 6 ### sections intact; dry-run of 20 session scenarios registered cleanly -->
  - [x] verify-self  <!-- status: complete: subagent walkthrough of SKILL.md steps 1-2 against 3 fixture project dirs (backlog-only, no-backlog, active-wip-with-backlog) — all 4 Observable outcomes PASS, no BLOCKING or COSMETIC; subagent confirmed by quoting SKILL.md lines 73/77/79/80 -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [x] verify-codify  <!-- status: complete: S22 + S23 added (SOFT_PASS — expected, empty-args path emits no transition); new fixture tests/fixtures/backlog/with-three-open.md; runner gained `fixtures.backlog` key (5 lines); S1 PASS regression check; check-structure 34/34 PASS, 130 scenarios registered (up from 128) -->

## Current Node
- **Path:** Feature > ship
- **Active scope:** ship
- **Blocked:** none
- **Unvisited:** finalize
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry also logged to workflow/backlog.md -->

## Notes for downstream skills

- **Integration-boundary check (feature-plan rule):** Phase 1 modifies `skills/session-start/SKILL.md`. The consuming surface is the `session-start` skill invocation flow (entry point both for `/session-start` direct and for the `init` flow when classifying). Verify-self must observe the skill running with backlog present *and* with backlog absent. Verify-codify should add a test scenario covering "session-start surfaces backlog candidates when no other active work."
- **Downstream contract impacts (plan-level pass):** No downstream artifacts assert against the current step-1 wording. The skill is invoked by the user, not by other skills. No test scenario currently asserts on the absence of backlog mention. CLAUDE.md and AGENTS.md don't quote step 1 verbatim. Safe to change without coordinated edits elsewhere. *However:* the feature adds a new optional input shape to step 2 (user replies with SURFACE-ID instead of free-form description) — this should be documented in the SKILL itself, not silently relied upon.
- **No new transition IDs needed.** The skill stays within its existing routing transitions (S1–S5, S18). Picking a candidate from the backlog still classifies into the same routing space; the only change is *where the args came from* (backlog summary vs typed input).
