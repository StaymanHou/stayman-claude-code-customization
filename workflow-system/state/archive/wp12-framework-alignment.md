# Feature: WP12 Framework Alignment — Iterative Re-Identification + Exit Conditions

**Workflow:** feature
**State:** finalize (complete)
**Completed:** 2026-04-30
**Created:** 2026-04-30

## Problem Statement

Three framework gaps (F1, F4, F5) identified in the workflow pain points analysis remain unaddressed: (F1) agents re-entering back-loops don't re-examine whether the root problem has changed; (F4) agents advancing between phases don't run a relevance check to confirm the work is still warranted; (F5) task-close and feature-finalize don't require both a retrospect artifact and an explicit communicate step — so closures can silently succeed without the requester knowing. This feature adds these three behavioral requirements as explicit prompts in the relevant skill files, plus test scenarios that assert the behaviors fire.

## Work Tree

- [x] Phase 1: Back-loop problem re-check (feature-build + task-act)  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id F23-recheck` exits 0 and reports PASS — feature-build back-loop output contains problem re-check record
  - CLI: `./tests/run-tests.sh --id T6-recheck` exits 0 and reports PASS — task-act back-loop output contains problem re-check record
  - CLI: `grep -n "problem statement re-check\|root problem" skills/feature-build/SKILL.md` returns matches
  - CLI: `grep -n "problem statement re-check\|root problem" skills/task-act/SKILL.md` returns matches
  - [x] P1.1 Add problem-statement re-check section to `feature-build/SKILL.md` back-loop entry (step 1 or new step before implement): agent must answer "has the root problem changed?" and record the answer in the WIP Problem Statement section  <!-- status: complete -->
  - [x] P1.2 Add same re-check to `task-act/SKILL.md` back-loop entry (T6 path)  <!-- status: complete -->
  - [x] P1.3 Add test scenario F23-recheck to `tests/scenarios/feature.yaml`: back-loop re-entry with a changed problem context → output contains updated problem statement and re-check record  <!-- status: complete -->
  - [x] P1.4 Add test scenario T6-recheck to `tests/scenarios/task.yaml`: back-loop re-entry with a changed problem context → output contains problem re-check record  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete (skipped by user) -->
  - [x] verify-codify  <!-- status: complete (F23-recheck + T6-recheck scenarios are codification) -->

- [x] Phase 2: Phase-advance relevance gate (feature-plan)  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -n "relevance\|relevance gate\|still warranted" skills/feature-plan/SKILL.md` returns matches
  - CLI: `./tests/run-tests.sh --id F7-relevance` exits 0 and reports PASS — feature-plan advancing to phase 2 records the relevance check
  - [x] P2.1 Add relevance gate to `feature-plan/SKILL.md` phase-advance logic: before starting each new phase (after Phase 1), agent must check four signals (requester still needs it, requirements unchanged, solution still feasible, no superior alternative discovered) and record the check result in the WIP file  <!-- status: complete -->
  - [x] P2.2 Add test scenario F7-relevance to `tests/scenarios/feature.yaml`: feature-plan advancing a multi-phase feature → output contains relevance check for the second phase  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete (skipped by user) -->
  - [x] verify-codify  <!-- status: complete (F7-relevance scenario is codification) -->

- [x] Phase 3: Dual-output close (task-close + feature-finalize)  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -n "retrospect\|communicate\|requester" skills/task-close/SKILL.md` returns matches for both a retrospect step and a communicate step
  - CLI: `grep -n "retrospect\|communicate\|requester" skills/feature-finalize/SKILL.md` returns matches for both
  - CLI: `./tests/run-tests.sh --id T10-dualclose` exits 0 and reports PASS — task-close output contains both a retrospect artifact and a communicate step
  - [x] P3.1 Update `task-close/SKILL.md`: replace/augment the reflect check with two separate required outputs — (a) a retrospect artifact ("what changed in our understanding") recorded in the WIP file before archiving, and (b) a communicate step ("confirmation that the requester knows the work is done and what it does") as a prompted action  <!-- status: complete -->
  - [x] P3.2 Update `feature-finalize/SKILL.md`: add the same two-output requirement before the tech debt assessment  <!-- status: complete -->
  - [x] P3.3 Add test scenario T10-dualclose to `tests/scenarios/task.yaml`: task-close on a completed task → output contains both retrospect language and communicate/notify language  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete (skipped by user) -->
  - [x] verify-codify  <!-- status: complete (T10-dualclose scenario is codification) -->

## Current Node
- **Path:** Feature > complete
- **Active scope:** all phases complete — ready to ship
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
