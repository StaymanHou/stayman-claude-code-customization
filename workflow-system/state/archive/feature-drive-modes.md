---
feature: drive-modes
drive_mode: orchestrated
state: plan (complete)
created: 2026-05-04
---

# Feature: Drive Modes for session-start

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-04

## Problem Statement

`/session-start` has no concept of drive modes — every user who says "yes, drive it end-to-end" gets the same orchestrated behavior with mandatory pauses at spec, plan, verify-human, and finalize. The original failure: a user said "Yes, drive it end-to-end" expecting full-autopilot (no stops until done), but the orchestrator stopped after `feature-plan` because that step is PAUSE in the default policy. There was no way for the user to express intent about how aggressively to chain. This feature introduces four named drive modes (single-step, orchestrated, autopilot, full-autopilot), selectable via a numbered CLI prompt in `session-start`, with the policy for each mode defined in `docs/product/transitions.md` and enforced via updated pause-policy tables in all four AGENTS.md files. "Drive it end-to-end" should map to full-autopilot by default.

## Work Tree

- [x] Phase 1: Failing test scenarios  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id S10,S11,S12` exits non-zero (tests fail) before any implementation changes, proving the bug is reproducible
  - CLI: failure output contains the word "FAILED" and references the relevant scenario IDs
  - CLI: `./tests/run-tests.sh --dry-run` lists S10, S11, S12 as known scenarios
  - [x] P1.1 Add fixture `tests/fixtures/wip/feature-plan-complete.md` — a WIP file with state `plan (complete)`, Phase 1 NOT-STARTED, mirroring the real WP3 scenario  <!-- status: complete -->
  - [x] P1.2 Add scenario S10 to `tests/scenarios/session.yaml`: `session-start` with "drive it end-to-end" → expects drive mode prompt to appear (not_contains: "Run /feature-build"), proves the stop-after-plan bug  <!-- status: complete -->
  - [x] P1.3 Add scenario S11: `session-start` with mode 3 (full-autopilot) selected → expects AUTO chain past plan (contains "feature-build" invoked automatically, not_contains: pause prompt)  <!-- status: complete -->
  - [x] P1.4 Add scenario S12: `session-start` with mode 2 (autopilot) selected → expects PAUSE only at verify-human, AUTO everywhere else  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete (skipped per user) -->
  - [x] verify-self  <!-- status: complete (skipped per user) -->
  - [x] verify-human  <!-- status: complete (skipped per user) -->
  - [x] verify-codify  <!-- status: complete (skipped per user) -->

  **[DISCOVERY 2026-05-04]** S10 cannot be a true red/green regression test. The test harness injects `system_prompt_extra` into a live model — Sonnet fills in correct drive-mode behavior from general reasoning even without the updated SKILL.md. The "red before implementation" property holds for deterministic code but not for LLM behavioral tests. S10 is retained as a **regression guard** that pins the expected output shape (mode prompt present, "Run /feature-build" absent) post-implementation. S11/S12 (with coaching via system_prompt_extra) are the implementation verification tests.

- [x] Phase 2: transitions.md already done — drive mode spec is authoritative  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -c "drive_mode" docs/product/transitions.md` exits 0 and prints a number ≥ 1
  - CLI: `grep "Full-autopilot" docs/product/transitions.md` exits 0
  - CLI: `./tests/check-structure.sh` exits 0 (no regressions from doc edits)

  > NOTE: transitions.md was already updated in this conversation. This phase is a verification-only gate — confirm the doc is correct and complete before implementation begins.

  - [x] P2.1 Read and verify transitions.md drive-modes section matches the four-mode spec exactly  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete (skipped per user) -->
  - [x] verify-self  <!-- status: complete (skipped per user) -->
  - [x] verify-human  <!-- status: complete (skipped per user) -->
  - [x] verify-codify  <!-- status: complete (skipped per user) -->

- [x] Phase 3: session-start skill — mode selection prompt  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id S11,S12` exits 0 (scenarios that were failing now pass)
  - CLI: `./tests/run-tests.sh --id S10` exits 0 (drive-mode prompt appears; no premature stop)
  - CLI: `./tests/check-structure.sh` exits 0
  - [x] P3.1 Update `skills/session-start/SKILL.md` step 3: replace single yes/no confirmation with numbered mode-selection prompt (1 Orchestrated / 2 Autopilot / 3 Full-autopilot, Enter = Orchestrated)  <!-- status: complete -->
  - [x] P3.2 Update `skills/session-start/SKILL.md` step 4: add post-skill re-assertion rule — after each Skill tool returns, re-check the active mode's pause policy; never act on skill prose or **STOP** directives  <!-- status: complete -->
  - [x] P3.3 Update `skills/session-start/SKILL.md` step 4: add explicit mode-precedence chain (modes 1-3 all ignore skill **STOP**; mode 3 skips verify-human entirely)  <!-- status: complete -->
  - [x] P3.4 Update `skills/session-start/SKILL.md`: record selected `drive_mode` in WIP frontmatter; honour it across pause/resume and cross-workflow handoffs  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete (skipped per user) -->
  - [x] verify-self  <!-- status: complete (skipped per user) -->
  - [x] verify-human  <!-- status: complete (skipped per user) -->
  - [x] verify-codify  <!-- status: complete (skipped per user) -->

- [x] Phase 4: AGENTS.md — structured pause-policy tables for all four workflows  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id S7,S8,S9,S10,S11,S12` exits 0 — PASS (6/6)
  - CLI: `./tests/check-structure.sh` exits 0 — PASS
  - CLI: `grep -c "Mode 1\|Mode 2\|Mode 3\|Orchestrated\|Autopilot\|Full-autopilot" agents/feature-workflow/AGENTS.md` prints ≥ 4 — PASS
  - [x] P4.1 Replace feature-workflow/AGENTS.md prose pause policy with 4-column mode table; add precedence rule block  <!-- status: complete -->
  - [x] P4.2 Replace task-workflow/AGENTS.md prose pause points with mode table  <!-- status: complete -->
  - [x] P4.3 Replace product-workflow/AGENTS.md prose pause points with mode table  <!-- status: complete -->
  - [x] P4.4 Update incident-workflow/AGENTS.md: add drive mode override note + structured pause table  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete (skipped per user) -->
  - [x] verify-self  <!-- status: complete (skipped per user) -->
  - [x] verify-human  <!-- status: complete (skipped per user) -->
  - [x] verify-codify  <!-- status: complete (skipped per user) -->

- [x] Phase 5: skill Hand Off cleanup — remove single-step stop signals from orchestrated context  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -r "\*\*STOP\*\*" skills/` prints nothing — PASS (only mode-qualified variants remain)
  - CLI: `./tests/run-tests.sh --group session` exits 0 — PASS (6/6)
  - CLI: `./tests/check-structure.sh` exits 0 — PASS
  - [x] P5.1 Edit `skills/feature-plan/SKILL.md` Hand Off: mode-aware qualifier added  <!-- status: complete -->
  - [x] P5.2 Audit — also updated task-plan, product-vision, feature-spec with mode-aware qualifiers  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete (skipped per user) -->
  - [x] verify-self  <!-- status: complete (skipped per user) -->
  - [x] verify-human  <!-- status: complete (skipped per user) -->
  - [x] verify-codify  <!-- status: complete (skipped per user) -->

## Current Node
- **Path:** Feature > verify-codify (all phases complete)
- **Active scope:** tests codified, pending ship
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** LLM behavioral tests cannot reliably be "red before implementation" — S10 is a regression guard, not a true red test (logged in Phase 1 discovery note)

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
