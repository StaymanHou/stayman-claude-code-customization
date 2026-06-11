---
workflow: task
state: verify
created: 2026-06-11
docs-only: false
---

# Task: Fix unbound variable in run-all.sh when FORWARD_ARGS is empty

**Workflow:** task
**State:** verify
**Created:** 2026-06-11

## Problem Statement
`./tests/run-all.sh` crashes with "unbound variable" on lines 42 and 49 when invoked without forwarded args (because `"${FORWARD_ARGS[@]}"` under `set -u` is unbound when the array is empty).

## Context
- Script: `tests/run-all.sh`
- Bug surface: lines 42, 49 (FORWARD_ARGS array dereference)

## Work Tree

- [x] T1 Replace `"${FORWARD_ARGS[@]}"` with `${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}` on lines 42 and 49

## Verification Observable

**Observable:** `./tests/run-all.sh --group debug` runs end-to-end without crashing on the FORWARD_ARGS unbound-variable error.
**Verification command:** `./tests/run-all.sh --group debug 2>&1 | tail -5`
**Expected result:** Exit code 0 OR exit code 1 with normal test output (test results summary visible) — NOT "unbound variable" error from bash.

## Verification Result

**Status:** PASS
**Date:** 2026-06-11
**Evidence:** `./tests/run-all.sh --group debug` ran end-to-end. Output ended with `=== Summary ===` block showing test results. No "unbound variable" error. Exit code: 0.
**Notes:** Fix confirmed working. The `${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}` pattern correctly expands to nothing when the array is empty, satisfying `set -u`.

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
