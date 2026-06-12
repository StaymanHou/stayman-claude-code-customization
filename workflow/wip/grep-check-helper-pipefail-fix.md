---
workflow: task
state: plan (complete)
created: 2026-06-12
docs-only: false
drive_mode: autopilot
---

# Task: Fix grep_check helper's count-capture under pipefail

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-06-12
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
- [ ] T5 Commit the helper fix as a single tech-debt commit  <!-- status: in-progress -->

## Current Node

- **Path:** Task > T5
- **Active scope:** T5 (commit)
- **Blocked:** none
- **Open discoveries:** none

## Discoveries

<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
