# Feature: PP5 — Orchestrator Auto-Advance

**Workflow:** feature
**State:** verify-codify (all phases complete)
**Created:** 2026-05-02
**Entry:** spec (complex feature)

## Problem Statement

When running a feature end-to-end via `/session-start`, the orchestrator halts after steps that pass cleanly and require no human decision. The Orchestration Procedure in `agents/feature-workflow/AGENTS.md` has inconsistent pause logic: it partially auto-chains some steps but still pauses before ship and uses ambiguous "brief pause" conditions for phase advances. The fix is a single, explicit AUTO/PAUSE policy table applied consistently to every step, with the `TRANSITION: <id>` token as the machine signal and the prose "Run `/x`" preserved for single-step users only.

## Work Tree

- [x] Phase 1: Update Orchestration Procedure with explicit AUTO/PAUSE policy  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -A 60 "Orchestration Procedure" agents/feature-workflow/AGENTS.md` shows a pause-policy table listing every step as AUTO or PAUSE with rationale
  - CLI: `grep "Before ship" agents/feature-workflow/AGENTS.md` returns no match (that pause is removed)
  - CLI: `grep "brief pause" agents/feature-workflow/AGENTS.md` returns no match (ambiguous language removed)
  - CLI: `grep "AUTO" agents/feature-workflow/AGENTS.md` returns matches for all relevant steps
  - [x] P1.1 Write the AUTO/PAUSE policy table in the Orchestration Procedure  <!-- status: complete -->
  - [x] P1.2 Rewrite step-by-step pause rules using the table — replace all prose conditions with explicit AUTO/PAUSE labels  <!-- status: complete -->
  - [x] P1.3 Remove the "pause before ship" rule and "brief pause between phases" ambiguity  <!-- status: complete -->
  - [x] P1.4 Back-loop transitions are AUTO — orchestrator re-enters build without pausing; human sees the outcome at the next verify-human  <!-- status: complete -->
  - [x] P1.5 Clarify that `TRANSITION: <id>` is the machine signal; prose "Run `/x`" is for single-step human readers and must not cause orchestrator to pause  <!-- status: complete -->
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

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
