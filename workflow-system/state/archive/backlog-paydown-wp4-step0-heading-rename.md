---
workflow: task
state: verify (complete)
created: 2026-07-13
docs-only: false
drive_mode: autopilot
---

# Task: WP4 — rename design-priors consult heading (Step-0 disambiguation)

**Workflow:** task
**State:** verify (complete)
**Created:** 2026-07-13

## Problem Statement
`product-roadmap` and `product-wbs` (non-entry-point skills) borrowed the structurally-pinned entry-point heading `## Step 0: Available product context`, overloading that convention; rename their heading's suffix so `## Step 0: Available product context` stays unique to the 6 entry-point skills.

## Context
- Governed by `docs/product/backlog-paydown-2026-07-13-wbs.md` → WP4 (DISC1: rename, not broaden). Resolves `SURFACE-2026-06-26-QUALITY-STEP0-ON-NON-ENTRY-SKILLS`.
- **Operator-clarified decision (2026-07-13):** the block does TWO things (lists available product docs AND the design-priors consult), so a literal `## Design-priors consult` would mislabel it. Chosen fix = keep the "Step 0" ordinal (it genuinely is the zeroth pre-procedure step) but change the **suffix** → `## Step 0: Product context + design-priors consult`. Content stays as-is; no restructure.
- **NOT in scope (separate task):** renumbering the awkward "Step 0 preamble + `### 1/2/3` procedure" scheme — logged as `SURFACE-2026-07-13-STEP0-PREAMBLE-VS-PROCEDURE-RENUMBER` (low, own task, must sync with Phase-3 pins). WP4 does the disambiguation rename ONLY.
- **Grounding (this session):** only product-roadmap:21 + product-wbs:36 carry the non-entry-point `## Step 0`. Phase-3 pins assert the literal `## Step 0: Available product context` for 6 entry-point skills only (roadmap/wbs not among them). Phase-13 pins anchor on `design-priors\.md` substring, NOT the heading. CLAUDE.snippet.md references Step-0 only for entry points. → No pin edit, no snippet edit; only `transitions.md:238` phrasing needs a touch.
- `docs-only: false` — edits pinned-adjacent SKILL.md prose; run check-structure as verify.

## Work Tree

- [x] T1 `skills/product-roadmap/SKILL.md` — renamed → `## Step 0: Product context + design-priors consult`. Body unchanged.  <!-- status: [x] -->
- [x] T2 `skills/product-wbs/SKILL.md` — same suffix rename. Body unchanged.  <!-- status: [x] -->
- [x] T3 `docs/product/transitions.md:238` — updated to name both headings accurately (feature-spec entry-point Step-0 vs roadmap/wbs distinct-suffix Step-0).  <!-- status: [x] -->
- [x] T4 Ran `./tests/check-structure.sh` — `401/0`. Entry-point string now 0 in roadmap/wbs; the 6 entry-point Step-0 pins all PASS; no pin broke.  <!-- status: [x] -->
- [x] T5 Marked `SURFACE-2026-06-26-QUALITY-STEP0-ON-NON-ENTRY-SKILLS` resolved (with the correction that no Phase-13 pin edit was needed).  <!-- status: [x] -->

## Verification Observable

**Observable:** The full structural suite passes, and the entry-point heading `## Step 0: Available product context` no longer appears in product-roadmap/product-wbs (disambiguation holds) while the 6 entry-point skills still carry it.
**Verification command:** `./tests/check-structure.sh` (suite) + `grep -c "^## Step 0: Available product context" skills/product-roadmap/SKILL.md skills/product-wbs/SKILL.md` (disambiguation, expect 0 each)
**Expected result:** suite `PASS: 401 | FAIL: 0`; roadmap/wbs grep = 0 each; the 6 entry-point `[PASS] … has Step 0 section` lines present.

## Verification Result

**Status:** PASS
**Date:** 2026-07-13
**Evidence:** `grep -c "^## Step 0: Available product context"` → 0 for both product-roadmap and product-wbs (disambiguation holds). `./tests/check-structure.sh` → `PASS: 401 | FAIL: 0`, "All structural checks passed" (the 6 entry-point Step-0 pins still match their skills).
**Notes:** Observable met exactly. Confirms the finding's worried-about "Phase-13 pins need updating" was a non-issue — the pins never anchored on the heading.

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [SURFACED-2026-07-13] (out of WP4 scope, logged to backlog) SURFACE-2026-07-13-STEP0-PREAMBLE-VS-PROCEDURE-RENUMBER — the Step-0-preamble-vs-`### 1/2/3`-procedure numbering is awkward; renumber as its own task, synced with Phase-3 pins.

## Retrospect
- **What changed in our understanding:** The finding assumed the roadmap/wbs `## Step 0` block was purely the design-priors consult (so "rename to `## Design-priors consult`" would fit). Opening the block showed it's DUAL-purpose (product-doc-listing + consult) → the literal rename would mislabel it. Also: the finding predicted "update the Phase-13 pins to match" — but the pins never anchored on the heading, so no pin edit was needed. Third consecutive WP where the finding's suggested action didn't survive contact with the code (WP1 #1, WP2 ×2, now WP4).
- **Assumptions that held:** The disambiguation goal (reserve `## Step 0: Available product context` for entry points) was exactly right and cheap to achieve.
- **Assumptions that were wrong:** "It's a simple heading rename" — the dual-purpose content made the *name* a real (if small) judgment call, which is why it went to the operator rather than being auto-applied.
- **Approach delta:** Paused to ask the operator on the heading name (block was dual-purpose; the DISC1 ruling's example name would've been inaccurate). Operator reframed + also spun off the numbering cleanup as a separate task. Good outcome: WP4 stayed atomic, the broader renumber is captured, and the name is honest.

## Completed
- **Completion date:** 2026-07-13
- **Status:** Completed (WP4 of backlog-paydown-2026-07-13 sweep)
