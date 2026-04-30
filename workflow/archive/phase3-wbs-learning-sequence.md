# Feature: Phase 3 — WBS Decomposition by Learning Sequence

**Workflow:** feature
**State:** complete
**Completed:** 2026-04-30
**Created:** 2026-04-29

## Problem Statement

The `product-wbs` skill produces a WBS ordered by build dependencies, not by learning dependencies. Riskiest unknowns (3rd-party API shapes, infrastructure compatibility, frontend feasibility) are deferred to late phases when they are cheapest to discover early. The fix is to make learning-sequence ordering a first-class constraint in the WBS skill, add a spike/probe WP class for structured uncertainty reduction, and add a downstream check in `feature-spec`/`feature-plan` that flags missing probes before any dependent feature gets planned.

## Work Tree

- [x] Phase 1: Update `product-wbs` skill — learning-sequence ordering + probe WP class  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -i "learning.sequence\|learning sequence" skills/product-wbs/SKILL.md` exits 0
  - CLI: `grep -i "Learning objective\|Timebox\|Success criterion" skills/product-wbs/SKILL.md` exits 0 (probe WP fields present)
  - CLI: `grep -i "probe\|spike" skills/product-wbs/SKILL.md` matches ≥ 3 lines
  - CLI: `grep -i "why this.*before\|rationale\|risk reduction" skills/product-wbs/SKILL.md` exits 0
  - CLI: `grep -i "3rd.party\|third.party\|integration.*blocker\|blocker.*integration" skills/product-wbs/SKILL.md` exits 0
  - [x] P1.1 Update `skills/product-wbs/SKILL.md` — add learning-sequence ordering requirement: assert the standard phase pattern (Docker/env → 3rd-party probes → UI mockups → backend synchronous path → orchestration/async); require written "why this before that" rationale per phase in terms of risk reduction  <!-- status: complete -->
  - [x] P1.2 Add spike/probe WP class to the WBS template with distinct fields: `Learning objective`, `Timebox`, `Success criterion` (what do we now know?); contrast with standard build WPs  <!-- status: complete -->
  - [x] P1.3 Add instruction: 3rd-party integrations must have a completed probe WP before any WP that assumes known API shapes; if no probe WP exists, one must be created; probe must document I/O shapes before downstream WPs are unblocked  <!-- status: complete -->
  - [x] P1.4 Add instruction: orchestration layers (queues, workers, async) must appear in a later phase than the synchronous path they will wrap — deviations require written rationale  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete — skipped: prompt-only change, all CLI outcomes confirmed by verify-self -->
  - [x] verify-codify  <!-- status: complete — P9b scenario added and passes -->

- [x] Phase 2: Add probe check to `feature-spec` and `feature-plan`  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -i "probe\|spike\|3rd.party\|third.party" skills/feature-spec/SKILL.md` exits 0
  - CLI: `grep -i "probe\|spike\|3rd.party\|third.party" skills/feature-plan/SKILL.md` exits 0
  - CLI: `grep -i "known unknown\|flag\|recommend.*spike\|recommend.*probe" skills/feature-spec/SKILL.md` exits 0
  - CLI: `grep -i "known unknown\|flag\|recommend.*spike\|recommend.*probe" skills/feature-plan/SKILL.md` exits 0
  - [x] P2.1 Update `skills/feature-spec/SKILL.md` — add a pre-planning probe check step: if the feature description mentions a 3rd-party service/API/SDK, check whether a completed probe WP exists (by asking the user or checking `docs/product/wbs.md`); if none exists, flag as a known unknown and recommend redirecting to a spike task before planning  <!-- status: complete -->
  - [x] P2.2 Apply the same probe check to `skills/feature-plan/SKILL.md`  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete — skipped: prompt-only change, all CLI outcomes confirmed by verify-self -->
  - [x] verify-codify  <!-- status: complete — F29 scenario added and passes -->

- [x] Phase 3: Transition test scenario for probe check  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id P13 --dry-run` exits 0 (scenario recognized)
  - CLI: `./tests/run-tests.sh --id P13 --model haiku` passes (green)
  - CLI: `grep "P13" tests/scenarios/product.yaml` exits 0
  - [x] P3.1 Add fixture `tests/fixtures/wip/feature-spec-3rdparty-no-probe.md` — a spec-state WIP file describing a feature that integrates with a 3rd-party API (e.g. Stripe), no probe WP present  <!-- status: complete -->
  - [x] P3.2 Add scenario `P13` to `tests/scenarios/product.yaml` — invoke `product-wbs` with a system_prompt_extra establishing a project with a Stripe integration; assert output contains a probe WP and ordering rationale  <!-- status: complete -->
  - [x] P3.3 Run scenario to confirm PASS on haiku  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete — all 3 CLI outcomes confirmed -->
  - [x] verify-human  <!-- status: complete — skipped: CLI-only phase, all outcomes confirmed by verify-self -->
  - [x] verify-codify  <!-- status: complete — full product suite 13/13 PASS, no regressions -->

## Current Node
- **Path:** Feature > complete
- **Active scope:** all phases complete
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Session Pause — 2026-04-29 16:00
Paused. See `workflow/.session.md` to resume.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
