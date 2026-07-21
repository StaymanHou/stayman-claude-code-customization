---
workflow: task
state: close (complete)
created: 2026-06-13
completed: 2026-06-13
docs-only: false
drive_mode: autopilot
---

# Task: Phase 3d regex_test should mirror production tr -d '*' | sed pipeline

**Workflow:** task
**State:** close (complete) — Completed 2026-06-13
**Created:** 2026-06-13

## Problem Statement
`tests/check-structure.sh` Phase 3d's `regex_test` helper pipes input through `sed -n` only, but production `tests/lib/verify.sh:59` runs `tr -d '*' | sed -n ...` — so the property test under-asserts and reports 2 perpetual FAILs on the two markdown-bold cases, even though the production pipeline handles them correctly.

## Context
- Source: SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX in `workflow/backlog.md:21-29`
- Production pipeline (correct): `tests/lib/verify.sh:59` — `echo "$result_text" | tr -d '*' | sed -n '...' | tail -1`
- Property test (out of sync): `tests/check-structure.sh:331` — `actual=$(echo "$input" | sed -n "$REGEX_PATTERN")`
- Two cases that currently FAIL but should PASS once aligned:
  - `tests/check-structure.sh:342` — markdown bold (F1): `**TRANSITION:** F1 (entry → spec)` → `F1`
  - `tests/check-structure.sh:347` — hyphenated debug token with markdown bold (SKIP): `**TRANSITION:** DEBUG-BISECT-SKIP` → `DEBUG-BISECT-SKIP`
- Pre-fix baseline check count (per SURFACE note): 228 with 2 FAIL; post-fix expectation: 226/226 PASS (the 2 FAILs convert to PASS, count drops by 2 because the property is no longer split into "regex alone" + "pipeline" — irrelevant — or stays 228 with 226 PASS + 2 PASS. Re-verify after fix.)

## Work Tree

- [x] T1 Edit `tests/check-structure.sh:331` so `regex_test` pipes input through `tr -d '*' | sed -n "$REGEX_PATTERN"` (mirroring `tests/lib/verify.sh:59`)  <!-- applied replace_all to also fix the identical line in regex_test_negative at :355; no-op for current negative cases (no asterisks) but keeps both helpers pipeline-faithful -->
- [x] T2 Run `./tests/check-structure.sh` and confirm the two previously-failing markdown-bold cases now PASS, and the overall summary shows zero FAILs  <!-- both cases now [PASS]; final summary: PASS 251 / FAIL 0 -->

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none

## Verification Observable

**Observable:** Running `./tests/check-structure.sh` reports zero FAILs in Phase 3d's regex property test, with the two markdown-bold cases (`markdown bold (F1)` and `hyphenated debug token with markdown bold (SKIP)`) now PASSing.
**Verification command:** `./tests/check-structure.sh 2>&1 | grep -E '^\[Phase 3d\]|FAIL|PASS' | head -40 ; ./tests/check-structure.sh 2>&1 | tail -5`
**Expected result:** Both `regex: markdown bold (F1)` and `regex: hyphenated debug token with markdown bold (SKIP)` show PASS (not FAIL); script's final summary line reports 0 failed assertions.

## Verification Result

**Status:** PASS
**Date:** 2026-06-13
**Evidence:** Both targeted cases emit `[PASS]` lines: `regex: markdown bold (F1)` and `regex: hyphenated debug token with markdown bold (SKIP)`. Final summary: `PASS: 251 | FAIL: 0 — All structural checks passed.` (Total grew from baseline 228 → 251 due to unrelated structural checks added since SURFACE was filed; the load-bearing fact is the 2 markdown-bold FAILs converted to PASS.)
**Notes:** Fix is the 1-line `tr -d '*'` insertion at `tests/check-structure.sh:331` (positive helper) + the same insertion at `:355` (negative helper, applied for pipeline-symmetry; no-op for current negative cases that contain no asterisks).

## Retrospect

- **What changed in our understanding:** Nothing meaningful — the SURFACE entry already pinpointed the exact line (`tests/check-structure.sh:331`), the exact missing pipe segment (`tr -d '*'`), and the production reference (`tests/lib/verify.sh:59`). One nuance the SURFACE didn't enumerate but the file did: the same asymmetry exists in `regex_test_negative` at `:355`. Applied `replace_all` to keep both helpers symmetric (no-op for current negative cases that contain no asterisks, but defensive against future negative cases that include markdown decoration).
- **Assumptions that held:** Production pipeline is correct; only the property test was misaligned. PASS count delta prediction (2 FAILs convert to PASS) was correct. Single-line fix scope was correct.
- **Assumptions that were wrong:** The SURFACE projected post-fix baseline at 226/226. Actual: 251/0. The +23 PASS delta vs SURFACE's projection is from unrelated structural checks added between when the SURFACE was filed (2026-06-12) and now — not a planning error, just SURFACE-staleness on a 1-day-old item.
- **Approach delta:** None of substance. Plan was 2 steps (edit + verify); both executed verbatim.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
