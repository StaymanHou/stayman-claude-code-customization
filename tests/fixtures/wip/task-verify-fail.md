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

**Status:** FAIL
**Date:** 2026-06-11
**Evidence:** `./tests/run-all.sh --group debug` exited with code 2 and stderr: `./tests/run-all.sh: line 43: pipefail: SIGPIPE signal received`. The original unbound-variable bug on line 42 is fixed, but a previously-masked sibling bug on line 43 is now exposed — `set -o pipefail` interacts with the SIGPIPE from `head -1` in the same pipeline.
**Notes:** The original observable is FAILING. The script still doesn't run end-to-end. This is NOT a SURFACED-sibling-bug auto-absorb candidate — the failure mode shifted but the original observable is unsatisfied. Back-loop to /task-act with scope-restriction: "verify the script runs end-to-end against ./tests/run-all.sh --group debug".

## Current Node
- **Path:** Task > verify (FAILED — back-loop pending)
- **Active scope:** the failed observable — back-loop to act
- **Blocked:** none
- **Open discoveries:** SIGPIPE bug on line 43 surfaced by verify; not in original task scope but blocks the observable from PASSing

## Discoveries
[SURFACED-2026-06-11] verify — SIGPIPE bug on line 43 masked by original line-42 bug; back-loop scope = same observable
