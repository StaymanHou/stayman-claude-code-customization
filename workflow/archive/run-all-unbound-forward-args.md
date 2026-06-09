---
slug: run-all-unbound-forward-args
workflow: task
state: act (complete)
created: 2026-06-09
drive_mode: autopilot
---

# Task: Fix `tests/run-all.sh` unbound-variable crash when invoked with no args

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-06-09

## Problem Statement
`tests/run-all.sh:42` and `:49` expand `"${FORWARD_ARGS[@]}"` under `set -euo pipefail`; on bash 3.2 (macOS default) an empty array `[@]` expansion triggers `unbound variable` and aborts the whole two-pass sweep before Pass 1 runs, breaking the documented end-to-end harness invocation (`./tests/run-all.sh` with no args).

## Context
- Target file: `tests/run-all.sh` (lines 42 and 49)
- Backlog entry: `workflow/backlog.md` → `SURFACE-2026-06-06-RUN-ALL-UNBOUND-FORWARD-ARGS` (P3)
- Bug confirmed empirically: `bash -c 'set -euo pipefail; FORWARD_ARGS=(); printf "%s\n" "${FORWARD_ARGS[@]}"'` → `bash: FORWARD_ARGS[@]: unbound variable`.
- Fix idiom verified empirically: `${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}` expands to nothing when empty, expands to quoted args when populated. Bash 3.2-compatible.
- Pre-existing: the bug has been latent since the file's creation. `git log -p tests/run-all.sh` shows no recent changes.
- Per CLAUDE.md: this repo ships via commit + push to main, no PR workflow.

## Work Tree

- [x] T1 Apply the conditional-expansion fix to `tests/run-all.sh:42` and `:49` (replace `"${FORWARD_ARGS[@]}"` with `${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}` on both lines)  <!-- status: complete -->
- [x] T1b Fix the pipefail/SIGPIPE bug at `tests/run-all.sh:43` and `:50` (sibling bug exposed by T1; pre-existing). Replace `P1_FILE=$(ls -1t "$RESULTS_DIR"/run-*.json 2>/dev/null | grep -v combined | head -1)` with `P1_FILE=$({ ls -1t "$RESULTS_DIR"/run-*.json 2>/dev/null | grep -v combined | head -1; } || true)`. Same shape for `P2_FILE=` on line 50.  <!-- status: complete -->
- [x] T2 Verify the fix end-to-end: invoke `./tests/run-all.sh --group debug` (real run, 3 scenarios × 2 passes ≈ 1-2 min real model cost). Confirm: both passes complete, combined-result JSON file written, "=== Combined Summary ===" line prints, exit code 0. Then invoke `./tests/run-all.sh --dry-run` (populated-FORWARD_ARGS path) to confirm no regression.  <!-- status: complete; real run exit 0, both passes ran, combined merge wrote /tests/results/run-2026-06-09-191951-combined.json; dry-run + populated FORWARD_ARGS regression check also exit 0 -->
- [x] T3 Resolve the P3 backlog entry: mark `SURFACE-2026-06-06-RUN-ALL-UNBOUND-FORWARD-ARGS` as `**Status:** resolved 2026-06-09 — <one-line>` in `workflow/backlog.md`. `/task-close` will then append the corresponding `**Backlog resolved:**` line to `CHANGELOG.md` and archive the WIP.  <!-- status: complete -->

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete — ready for /task-close
- **Blocked:** none
- **Open discoveries:** T1b added mid-act and completed in-line (trivial extension; same file, same bug-family). End-to-end verified with real model calls per user instruction.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
[SURFACED-2026-06-09] T2 — Sibling bug: `tests/run-all.sh:43` and `:50` use the pipeline `ls -1t … | grep -v combined | head -1`. Under `set -o pipefail`, `head -1` closes the pipe early after one line; `ls` then receives SIGPIPE and exits 141; `pipefail` propagates 141; `set -e` kills the script before Pass 2. Empirically verified: post-T1 `./tests/run-all.sh --group debug` runs Pass 1 successfully then dies with exit 141 right after `P1_FILE=...`. Pre-T1 the script crashed earlier (at line 42 unbound-variable) so never reached the pipefail path. The two are the same family of bug (`set -euo pipefail` semantics interactions with common shell idioms) in the same file blocking the same end-to-end test, so absorbed into T1b rather than spun out to its own backlog item. Fix: `P1_FILE=$({ ls … | grep … | head -1; } || true)` (subshell + `|| true` swallows the SIGPIPE pipefail propagation).

## Retrospect
- **What changed in our understanding:** Bug #1 (the planned one) was a one-line `set -u` empty-array expansion crash. Bug #2 (discovered during verification) was a sibling `set -o pipefail` + SIGPIPE-from-`head` crash in the same file, exposed only because fixing #1 let the script reach line 43 for the first time. Two distinct `set -euo pipefail` interactions, same file, same end-to-end test surface, same script-aborts-silently failure mode.
- **Assumptions that held:** The `${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}` idiom (suggested in the backlog) is the right fix for bug #1, works on bash 3.2, and survives both empty and populated arrays. Verified empirically before applying.
- **Assumptions that were wrong:** The plan assumed `--dry-run` was sufficient verification. The user's explicit "verify the test still works after the change before closing" instruction directly contradicted the plan's T2 verbiage ("--dry-run path... without burning real model cost") and was the correct call — only a real end-to-end run with both passes + the JSON-merge step surfaced the pipefail/SIGPIPE bug. Plan's verification step was too narrow; user's correction caught a real defect.
- **Approach delta:** Plan was 3 steps (T1, T2, T3) for a one-line fix + dry-run verify + backlog resolve. Actual was 4 steps (T1, T1b added mid-act, T2 expanded to real-run verification, T3) for two-line-pair fix + real-run verify + backlog resolve. T1b was a true T6 back-loop in shape but handled in-line within the same act session because (a) trivial extension of the same file with the same bug-family idiom, (b) same end-to-end test surface, (c) the audit-trail entry above captures the deviation. The shape parallels the now-codified verify-self in-place fix shortcut (skills/feature-verify-self/SKILL.md §3), suggesting the same pattern may be applicable at task-act for trivial intra-file sibling-bug discoveries — but rule-of-three not reached, so not codifying yet.

## Closure notice
Task `run-all-unbound-forward-args` is complete. Fixed two pre-existing `set -euo pipefail` interaction bugs in `tests/run-all.sh` that broke the documented end-to-end harness invocation: (1) `${FORWARD_ARGS[@]}` unbound-variable crash on empty arrays (lines 42 + 49), (2) `ls | grep | head` SIGPIPE-via-pipefail crash between Pass 1 and Pass 2 (lines 43 + 50). Verified by real `./tests/run-all.sh --group debug` run: both passes complete, JSON merge succeeds, exit 0. Requester = operator — closure notice for self-record.
