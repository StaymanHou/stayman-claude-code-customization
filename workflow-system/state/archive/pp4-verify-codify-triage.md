# Feature: PP4 — verify-codify Test Triage Gate

**Workflow:** feature
**State:** ship (complete)
**Created:** 2026-05-02
**Entry:** spec (complex feature)

## Problem Statement

`feature-verify-codify` runs the full test suite and acts on failures without a decision procedure. The agent silently chooses to fix code, update tests, or re-run — with no written reasoning and no human gate for ambiguous cases. Test modifications at this step remove specification artifacts permanently. The fix: a mandatory triage classification before any file is touched, with a written artifact in the WIP file, escalating all but high-confidence obvious cases to the human.

## Work Tree

- [x] Phase 1: Add triage protocol to `feature-verify-codify` + test scenarios  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -A 5 "Test Failure Triage" skills/feature-verify-codify/SKILL.md` returns the classification table header
  - CLI: `grep "Triage artifact" skills/feature-verify-codify/SKILL.md` returns a match (artifact requirement present)
  - CLI: `grep "flaky" skills/feature-verify-codify/SKILL.md` returns a match (flaky detection present)
  - CLI: `./tests/run-tests.sh --id F16-triage-regression,F16-triage-ambiguous,F16-triage-flaky,F16-triage-contract --model haiku` exits 0 with all 4 PASS
  - [x] P1.1 Add "Test Failure Triage" section to `skills/feature-verify-codify/SKILL.md` with classification table, high-confidence definition, artifact requirement, hard rule, and flaky detection  <!-- status: complete -->
  - [x] P1.2 Add 4 triage test scenarios to `tests/scenarios/feature.yaml` (regression, ambiguous, flaky, contract-conflict)  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete -->

## Current Node
- **Path:** Feature > Phase 1 > verify-codify (complete)
- **Active scope:** none — all phases complete
- **Blocked:** none
- **Unvisited:** none (single-phase feature)
- **Open discoveries:** none

## Retrospect
- **What changed in our understanding:** The original "high confidence" definition required pointing to a specific line, which was too narrow — missing obvious cases like deleted functions or config changes spanning multiple lines. Revised during verify-human to: "the failure has exactly one plausible explanation, stateable in one sentence without hedging."
- **Assumptions that held:** Six cases covers the full classification space. Scoping the fix to `verify-codify` only (not verify-auto/verify-self) was correct — earlier steps run scoped checks and rarely hit unexpected failures.
- **Assumptions that were wrong:** None structural. The single definition refinement was caught early at verify-human.
- **Approach delta:** Implementation matched plan exactly. One definition wording change before codify.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
