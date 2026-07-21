# Feature: Product Doc Archival on WBS Completion [COMPLETED 2026-05-01]

**Workflow:** feature
**State:** ship (complete)
**Created:** 2026-05-01

## Problem Statement

When a WBS is fully completed, `research.md`, `wbs.md`, and cycle-scoped diagnostic docs remain in `docs/product/` indefinitely. There is no convention for archiving them, unlike feature WIP files which move to `workflow/archive/`. This creates clutter and ambiguity. Additionally, `arch.md` and related durable docs may have drifted from reality during the implementation phase — decisions made in features rarely flow back up to the product-level architecture doc. The fix: a new `product-finalize` skill that (1) resyncs `arch.md` and durable docs against what was actually built, then (2) archives cycle-scoped docs to `docs/product/archive/<cycle-name>/`, with `feature-finalize` updated to surface/invoke it when the WBS is fully complete.

## Work Tree

- [x] Phase 1: Create `product-finalize` skill  <!-- status: in-progress -->
  **Observable outcomes:**
  - CLI: `ls skills/product-finalize/SKILL.md` exits 0
  - CLI: `./install.sh` exits 0 and output contains `[new] skills/product-finalize` or `[ok] skills/product-finalize`
  - CLI: `ls ~/.claude/skills/product-finalize` resolves to this repo
  - [x] P1.1 Create `skills/product-finalize/SKILL.md` with full skill procedure: (a) resync arch.md + durable docs against what was actually built, (b) roadmap milestone check — confirm completed WBS maps to a marked-done roadmap phase, (c) backlog sweep — resolve/defer/escalate unresolved SURFACEs in workflow/backlog.md, (d) archive cycle-scoped docs to `docs/product/archive/<cycle-name>/`  <!-- status: in-progress -->
  - [x] P1.2 Add new transitions P13/P14 to `docs/product/transitions.md` and F30 to Feature Workflow table  <!-- status: in-progress -->
  - [x] P1.3 Update `agents/product-workflow/AGENTS.md`: add `product-finalize` to skills list and state machine diagram  <!-- status: in-progress -->
  - [x] verify-auto  <!-- status: in-progress -->
  - [x] verify-self  <!-- status: in-progress -->
  - [x] verify-human  <!-- status: in-progress — F11: skipped, no user-facing surface -->
  - [x] verify-codify  <!-- status: in-progress — F30/P13b/P14 scenarios pass; check-structure 13/13 -->

- [x] Phase 2: Update `feature-finalize` — WBS completion check  <!-- status: in-progress -->
  **Observable outcomes:**
  - CLI: `grep -c "product-finalize\|WBS" skills/feature-finalize/SKILL.md` returns ≥ 2
  - CLI: `grep "F30\|product-finalize" skills/feature-finalize/SKILL.md` exits 0 (transition referenced)
  - [x] P2.1 Add WBS-completion check step to `feature-finalize` procedure  <!-- status: in-progress — done in Phase 1 codify -->
  - [x] P2.2 Add new transition F30 (`finalize → product-finalize`) to `docs/product/transitions.md`  <!-- status: in-progress — done in Phase 1 codify -->
  - [x] verify-auto  <!-- status: in-progress — confirmed via grep checks above -->
  - [x] verify-self  <!-- status: in-progress — no live surface, CLI-only -->
  - [x] verify-human  <!-- status: in-progress — F11: no user-facing surface -->
  - [x] verify-codify  <!-- status: in-progress — F30 scenario covers this -->

- [x] Phase 3: Update conventions and docs  <!-- status: in-progress -->
  **Observable outcomes:**
  - CLI: `grep -c "archive" docs/product/transitions.md` returns ≥ 1 (archival documented)
  - CLI: `grep "product-finalize\|docs/product/archive" CLAUDE.md` exits 0
  - CLI: `grep "durable reference" CLAUDE.md` — should NOT appear (old convention removed)
  - CLI: `grep -i "resync\|arch.*drift\|drift" skills/product-finalize/SKILL.md` exits 0 (resync step present in skill)
  - CLI: `./tests/check-structure.sh` exits 0
  - [x] P3.1 Update `CLAUDE.md` (project): remove "never archived" convention; add `docs/product/archive/<cycle-name>/` as the product doc archive location; add `product-finalize` to the workflow overview  <!-- status: in-progress -->
  - [x] P3.2 Update `CLAUDE.snippet.md` (global): same convention update; run `./install.sh` to inject  <!-- status: in-progress -->
  - [x] P3.3 Update `skills/product-wbs/SKILL.md`: note that WBS completion triggers `product-finalize` via `feature-finalize`  <!-- status: in-progress -->
  - [x] P3.4 Archive current cycle docs: move `docs/product/research.md`, `wbs.md`, `workflow-pain-points.md` to `docs/product/archive/workflow-system-v1/`  <!-- status: in-progress -->
  - [x] verify-auto  <!-- status: in-progress -->
  - [x] verify-self  <!-- status: in-progress — CLI-only, all checks pass -->
  - [x] verify-human  <!-- status: in-progress — F11: no user-facing surface -->
  - [x] verify-codify  <!-- status: in-progress — check-structure 13/13 -->

- [x] Phase 4: Test coverage  <!-- status: in-progress — completed during Phase 1 codify -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --dry-run 2>/dev/null | grep "^TOTAL" | grep -oE "[0-9]+" | tail -1` ≥ 88 (3 new scenarios)
  - CLI: `./tests/run-tests.sh --id P13b,P14,F30` — all 3 pass
  - CLI: `./tests/check-structure.sh` exits 0
  - [x] P4.1 Add scenario F30: `feature-finalize` detects complete WBS → surfaces `product-finalize`  <!-- status: in-progress -->
  - [x] P4.2 Add scenario P13b: `product-finalize` runs full procedure → archives, emits P13  <!-- status: in-progress -->
  - [x] P4.3 Add scenario P14: `product-finalize` detects arch drift → back-loops to `/product-arch`  <!-- status: in-progress -->
  - [x] P4.4 Update `tests/check-structure.sh` scenario count floor to 88  <!-- status: in-progress -->
  - [x] verify-auto  <!-- status: in-progress -->
  - [x] verify-self  <!-- status: in-progress -->
  - [x] verify-human  <!-- status: in-progress — F11 -->
  - [x] verify-codify  <!-- status: in-progress — all 3 new scenarios pass; check-structure 13/13 -->

## Current Node
- **Path:** Feature > verify-codify (all phases complete)
- **Active scope:** all phases [x] — ready for ship
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect
- **What changed in our understanding:** The transition ID space had conflicts (P13, F29 were taken); used P13b and F30 instead. Phase 2 and Phase 4 were largely pre-completed during Phase 1's verify-codify, making those phases trivial to close.
- **Assumptions that held:** Archive location `docs/product/archive/<cycle-name>/` was the right call — clean separation, mirrors `workflow/archive/` pattern. The 4-phase decomposition was accurate.
- **Assumptions that were wrong:** Planned 3 scenarios (P13/P14/F29) but two IDs were taken; adapted to P13b/P14/F30 without issue.
- **Approach delta:** verify-codify for Phase 1 ended up doing Phase 2 and Phase 4's work (feature-finalize update + test scenarios) since they were tightly coupled. The explicit phase boundaries were still useful for tracking.
