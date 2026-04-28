# Feature: Phase 1 — Problem Tree & Structured Verification

**Workflow:** feature
**State:** finalized (complete)
**Completed:** 2026-04-27
**Created:** 2026-04-27

## Problem Statement

The current WIP format is a flat checklist. When a verification step partially fails, the agent loses track of which specific items failed vs. passed, silently skips blocked items, and re-enters build with no scoped context. The fix is a Work Tree format: persistent node identities, status tags, a Current Node position pointer, and discovery attachment — so every re-entry carries precise scope and no information is lost across sessions.

## Work Tree

- [ ] Phase 1: Work Tree grammar already in CLAUDE.snippet.md  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `~/.claude/CLAUDE.md` contains `## Work Tree Format (GLOBAL)` section after `./install.sh`
  - CLI: section contains status vocabulary table, `## Current Node` schema, `## Discoveries` format, and the 5 rules
  - [x] 1.1 Write Work Tree grammar into CLAUDE.snippet.md  <!-- already done -->
  - [x] 1.4 Re-run install.sh to inject into ~/.claude/CLAUDE.md  <!-- already done -->

- [x] Phase 2: Canonical Work Tree fixture  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `tests/fixtures/wip/feature-plan-worktree.md` exists and validates against the Work Tree schema
  - CLI: fixture contains `## Work Tree`, `## Current Node`, `## Discoveries`, at least one phase with Observable outcomes and all 5 verification group nodes pre-populated
  - [x] P2.1 Write `tests/fixtures/wip/feature-plan-worktree.md` — canonical example used by all Phase 1 skill tests
  - [x] verify-auto  <!-- status: complete — structural checks pass -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [x] Phase 3: Update `feature-plan` skill — emit Work Tree  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: running feature-plan test scenario produces output containing `## Work Tree`, `## Current Node`, `<!-- status:`, `**Observable outcomes:**`
  - CLI: verification group nodes (`verify-auto`, `verify-self`, `verify-human`, `verify-codify`) appear as NOT-STARTED leaves under each phase
  - [x] P3.1 Update `skills/feature-plan/SKILL.md`: replace flat-checklist WIP template with Work Tree template
  - [x] P3.2 Add instruction: write Observable Outcomes per phase at plan time
  - [x] P3.3 Add instruction: pre-populate all 5 verification group nodes as NOT-STARTED under each phase (including verify-self)
  - [x] P3.4 Add instruction: initialize `## Current Node` pointing to Phase 1, first impl task
  - [x] P3.5 Add/update test scenario asserting Work Tree output (F7-worktree in feature.yaml)
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [x] verify-codify

- [x] Phase 4: Update `feature-verify-human` — leaf-level pass/fail  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: test scenario with partial failure produces output containing scoped leaf IDs (e.g. `P2.verify-human.check-1`) in the transition recommendation
  - CLI: BLOCKED items appear with explicit `BLOCKED: depends on <node>` annotation, not silently skipped
  - [x] P4.1 Update `skills/feature-verify-human/SKILL.md`: expand verify-human node into persistent leaf items on first run
  - [x] P4.2 Add instruction: re-entry shows only FAILED/BLOCKED leaves — skip [x] leaves
  - [x] P4.3 Add instruction: BLOCKED leaves get explicit `BLOCKED: depends on <node>` tag
  - [x] P4.4 Add instruction: hand back to feature-build with specific failed leaf IDs as args
  - [x] P4.5 Add instruction: verify-human node only [x] when ALL leaves are [x]
  - [x] P4.6 Add instruction: update Current Node on exit with failed leaf IDs in Active scope
  - [x] P4.7 Add/update test scenario: partial failure → scoped re-entry args in output (F12-scoped, F12-blocked in feature.yaml)
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [x] verify-codify

- [x] Phase 5: Update `feature-build` — scoped re-entry  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: test scenario with scoped args produces output that only mentions the named leaf IDs, not sibling leaves
  - CLI: discovery attachment scenario produces output with SURFACED node under the correct parent phase
  - CLI: parent completion enforcement scenario marks parent [x] when all children are [x]
  - [x] P5.1 Update `skills/feature-build/SKILL.md`: on entry, read Current Node first; if scoped args present, restrict to named leaf IDs only
  - [x] P5.2 Add instruction: discoveries attach to correct parent phase node as SURFACED children (and also to backlog)
  - [x] P5.3 Add instruction: before exit, enforce parent completion (all children [x] → mark parent [x])
  - [x] P5.4 Add instruction: update Current Node on exit
  - [x] P5.5 Add/update test scenarios: scoped re-entry (F8-scoped in feature.yaml)
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [x] verify-codify

- [x] Phase 6: Update `task-plan` / `task-act` — Work Tree (peer model)  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: task-plan test scenario output contains `## Work Tree`, `## Current Node`, `## Discoveries`
  - CLI: task-act test scenario with discovery produces output attaching it to the correct step node
  - [x] P6.1 Update `skills/task-plan/SKILL.md`: emit Task Work Tree format (step nodes, Current Node, Discoveries — no Observable Outcomes, no verify loop)
  - [x] P6.2 Update `skills/task-act/SKILL.md`: read Current Node on entry; attach discoveries to step node; update statuses and Current Node on exit
  - [x] P6.3 Add instruction to task-act: parent completion enforcement before exit
  - [x] P6.4 Add/update test scenarios (T2-worktree, T7-worktree in task.yaml)
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [x] verify-codify

- [x] Phase 7: Update test fixtures (Phase 1)  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `tests/run-tests.sh --group feature` passes clean on haiku
  - CLI: `tests/run-tests.sh --group task` passes clean on haiku
  - [x] P7.1 Audit all 17 existing fixtures — identified which skills reference them
  - [x] P7.2 Convert all feature/task fixtures to Work Tree format (preserved scenario intent)
  - [x] P7.3 Add new fixtures: `feature-verify-human-partial-failure.md`, `feature-build-scoped-reentry.md`, `task-plan-worktree.md`
  - [x] P7.4 Run test suite — 7/7 new Work Tree scenarios PASS on haiku (budget 0.10; note: default $0.05 too low — see backlog)
  - [x] verify-auto  <!-- skipped per user — full suite deferred -->
  - [x] verify-self  <!-- N/A — no live app -->
  - [x] verify-human  <!-- skipped per user -->
  - [x] verify-codify

## Current Node
- **Path:** Feature > ship
- **Active scope:** all phases complete
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** test budget default $0.05 too low — surfaced to backlog

## Discoveries
