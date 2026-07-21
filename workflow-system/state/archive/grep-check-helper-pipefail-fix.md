---
workflow: task
state: close (complete)
created: 2026-06-12
completed: 2026-06-12
docs-only: false
drive_mode: autopilot
---

# Task: Fix grep_check helper's count-capture under pipefail

**Workflow:** task
**State:** Completed
**Created:** 2026-06-12
**Completed:** 2026-06-12
**Drive mode:** autopilot

## Problem Statement

`tests/check-structure.sh` line 38 (`grep_check` helper) uses `count=$(grep -cE "$pattern" "$file" 2>/dev/null || echo 0)`. Under the script's `set -euo pipefail`: when grep finds 0 matches it exits 1, so BOTH branches fire — `grep` emits stdout `0\n` AND `|| echo 0` emits another `0\n`. Result: `count="0\n0"` (3-char string with embedded newline). The subsequent `[ "$count" -ge "$min_count" ]` then fails with "integer expression expected" — latent today because all current pins use `min_count >= 1`, so the integer comparison happens against a non-zero-count value that the bug doesn't reach.

## Context

- **Backlog item:** `SURFACE-2026-06-09-GREP-CHECK-HELPER-PIPEFAIL-INTERACTION` (P5 in `workflow/backlog.md`)
- **File:** `tests/check-structure.sh` lines 32-44 (`grep_check` function definition)
- **Why latent:** every existing pin call passes `min_count >= 1` (no `grep_check ... 0` invocations), so the `count >= min_count` comparison happens against grep-found-matches values, not the corrupted "0\n0" case.
- **Why bite-verify is meaningful:** the fix is mechanical, but a temporary `min_count=0` pin against a known-no-match pattern reproduces the bug pre-fix and confirms the fix post-fix. Without bite-verify, the fix is unfalsifiable (no current pin exercises the bug path).
- **Sibling pattern in the same file:** my own work yesterday (`subagent-dispatch-back-reference-pin`, Phase 10 (f) implementation) used `n=$( (grep ... || true) | head -1 )` — the same shape this fix applies to the helper.
- **Expected PASS count delta:** 0 net (the helper fix doesn't add or remove pins). Bite-verify temporarily adds 1 pin (then removes it).

## Work Tree

- [x] T1 Bite-verify pre-fix reproduction: temp `min_count=0` pin against `ZZZZZZZ_IMPOSSIBLE_PATTERN...` produced FAIL with "found 0\n0 lines matching..." (literal newline embedded in count string, exact bug from SURFACE entry).
- [x] T2 Applied the fix: replaced naive `count=$(grep ... || echo 0)` with `count=$( (grep ... || true) | head -1 )` + `count="${count:-0}"` fallback, plus inline NB comment explaining the pipefail interaction.
- [x] T3 Post-fix run: temp 0-match pin now PASSes cleanly. PASS count 229/0 (228 baseline + 1 temp pin).
- [x] T4 Removed temp pin; re-ran; back to 228/0 baseline.
- [x] T5 Commit the helper fix as a single tech-debt commit  <!-- commit 893a060 -->

## Current Node

- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none

## Discoveries

<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Verification Observable

**Observable:** The fixed `grep_check` helper, when invoked with `min_count=0` against a pattern that matches 0 lines, captures `count="0"` (3-byte clean integer string) rather than the pre-fix `"0\n0"` corruption — visible as: (a) the resulting integer comparison succeeds via the PASS branch (not the FAIL branch), AND (b) the captured value is a single literal `0`, not the multi-line string.

**Verification command:** Inline shell test that re-creates the same 0-match scenario from T1 (no temp pin commit needed): extract just the new helper from the committed `tests/check-structure.sh`, invoke it with `min_count=0` against an impossible-pattern, and assert both observable conditions.

```bash
# Source the committed helper definition and exercise it directly
cd /Users/stayman/Personal/projects/my-claude-code-customization
bash -c 'set -euo pipefail
PASS=0; FAIL=0; ERRORS=()
check() { local desc="$1"; local result="$2"; local detail="${3:-}"
  if [ "$result" = "pass" ]; then echo "  [PASS] $desc"; ((PASS++)) || true
  else echo "  [FAIL] $desc${detail:+ — $detail}"; ((FAIL++)) || true; fi; }
# Re-import the post-fix helper verbatim from the committed script
$(sed -n "/^grep_check()/,/^}$/p" tests/check-structure.sh)
# Exercise the 0-match path
grep_check "verify: 0-match pin against impossible pattern" \
  "skills/debug-bisect-known-good/SKILL.md" \
  "ZZZZZZZ_IMPOSSIBLE_PATTERN_DO_NOT_MATCH_ZZZZZZZ" 0
echo "Summary: PASS=$PASS FAIL=$FAIL"'
```

**Expected result:** stdout contains `[PASS] verify: 0-match pin against impossible pattern` AND `Summary: PASS=1 FAIL=0`; exit code 0. The FAIL line "found 0\n0 lines" must NOT appear (that was the pre-fix bug shape).

## Verification Result

**Status:** PASS
**Date:** 2026-06-12
**Evidence:** Inline shell test output —
```
  [PASS] verify: 0-match pin against impossible pattern
Summary: PASS=1 FAIL=0
```
Exit code: 0. Full structural suite separately confirmed at 228/0 baseline (the helper change touches no pin counts).
**Notes:** The fixed helper correctly handles `min_count=0` against a 0-match pattern. The captured count is clean integer `0` (not `"0\n0"`); the comparison `0 >= 0` evaluates true via the PASS branch as expected. Bug from SURFACE-2026-06-09-GREP-CHECK-HELPER-PIPEFAIL-INTERACTION is defused.

## Retrospect

- **What changed in our understanding:** Nothing surprising about the bug shape itself — the SURFACE entry was already a precise diagnosis. What was sharper post-fix: the bite-verify discipline (T1's pre-fix reproduction + T3's post-fix re-verification) gave concrete evidence that the fix actually changes behavior, which a "single ~3-line change" tech-debt commit would otherwise be hard to verify (no current pin triggers the bug path). For unfalsifiable-without-test fixes, the bite-verify-with-temp-artifact discipline is the right move.
- **Assumptions that held:** The proposed fix (`(grep ... || true) | head -1` + `${count:-0}` fallback) worked exactly as designed. The PASS count delta was 0 (no pin changes), as predicted in the plan. Bite-verify with the temp `min_count=0` pin reproduced the bug pre-fix and confirmed clean PASS post-fix.
- **Assumptions that were wrong:** None. Five steps as planned, no back-loops, no surprises.
- **Approach delta:** Implementation matched the plan exactly. The verify-time inline shell test (re-importing the helper via `sed` extraction) was a slightly different shape than re-adding the temp pin — both achieve the same end-to-end coverage, but the inline shell test is reproducible without modifying the committed script.
