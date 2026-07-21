# Task: Fix `|| true` bug in test harness that masks all FAILs as PASS

**Workflow:** task
**State:** Completed 2026-05-05
**Created:** 2026-05-05
**Drive mode:** autopilot
**Blocks:** integration-boundary-verify-rules feature (paused at workflow/.session.md)

## Problem Statement

`tests/run-tests.sh:183` reads `verify_result "$result_text" ... || true` followed by `local rc=$?` on line 184. The `|| true` runs whenever `verify_result` returns non-zero (FAIL=2, SOFT_PASS=1), and resets `$?` to 0 — so `rc=$?` always captures `0` from `true`, never the original return code. Every FAIL across all 108 scenarios is recorded as PASS.

## Context

- **Bug location:** `tests/run-tests.sh:183` (inside the `run_test()` function, lines 85–237).
- **Original intent (line 182 comment):** "`|| true` prevents set -e from killing the script on non-zero return". The author was right that bare `verify_result` followed by `local rc=$?` would trip `set -e` (line 13). They were wrong that `|| true` is the right way to suppress it.
- **Empirical confirmation of the abort behaviour:** `bash -c 'set -e; fn(){ return 2; }; fn; rc=$?; echo "rc=$rc"'` exits 2 before reaching the echo. So Option B (just drop `|| true`) is incorrect — it would re-introduce the abort the author originally guarded against.
- **Empirical confirmation of the bug itself:** `bash -c 'fn(){ return 2; }; fn || true; echo "rc=$?"'` prints `rc=0`.
- **Empirical confirmation of impact in this repo:** `tests/results/run-2026-05-05-165143.json` shows F-boundary-self with `status=PASS` but `details="Wrong transition: found F10b, expected F9b"` — those two facts are contradictory under verify.sh's intended logic.
- **Related files:**
  - `tests/lib/verify.sh:8–63` (`verify_result` — return-code semantics: 0=PASS, 1=SOFT_PASS, 2=FAIL).
  - `tests/run-tests.sh:13` (the `set -e` we must preserve elsewhere in the script).
- **Backlog item:** workflow/backlog.md → `SURFACE-2026-05-05-HARNESS-RC-BUG` (high priority).
- **Paused feature:** workflow/.session.md → resumes via `/session-resume` once this task closes.

## The fix

Replace `tests/run-tests.sh:182–184` (3 lines):

```bash
    # Verify (|| true prevents set -e from killing the script on non-zero return)
    verify_result "$result_text" "$expect_id" "$contains_any" "$not_contains" || true
    local rc=$?
```

with:

```bash
    # Verify — wrap with set +e/-e so verify_result's non-zero return doesn't
    # trip set -e, while still capturing the real return code into rc.
    set +e
    verify_result "$result_text" "$expect_id" "$contains_any" "$not_contains"
    local rc=$?
    set -e
```

Reasoning recorded above (Option B was empirically tested and rejected).

## Work Tree

- [x] T1 Apply the fix to `tests/run-tests.sh:182–184` (3 lines → 5 lines, set +e/-e wrap)
- [x] T2 Sanity-check: `./tests/run-tests.sh --group feature --dry-run` exit 0, 51 scenarios listed
- [x] T3 Reproduce the bug pre-fix: noted only — already empirically proven during diagnosis (workflow/archive/integration-boundary-verify-rules-task-escalated.md → D1 Discoveries; bash semantics: `fn(){ return 2; }; fn || true; echo $?` prints 0)
- [x] T4 Synthetic post-fix test: F-boundary-self `expect.transition_id` temporarily set to `BOGUS_ID` + `contains_any: ZZZ_NEVER_MATCHES_ZZZ`. Result: status=FAIL, FAILURES list populated with "Wrong transition: found F10b, expected BOGUS_ID". Reverted cleanly. tests/results/run-2026-05-05-183023.json
- [x] T5 Real-world post-fix test (tests/results/run-2026-05-05-183425.json):
  - F-boundary-self: status=**FAIL** (wrong transition F10b; reproduction signal exposed)
  - F-boundary-human: status=**FLAKY** (attempt 1 produced no structured TRANSITION; attempt 2 retried and matched contains_any on `/distribution/match` → SOFT_PASS). Model is unstable on this scenario at haiku — paused feature must account for this.
  - F-boundary-codify: status=PASS (TRANSITION F15 matches expected F15 — R1 from paused feature plan, undistinguishable on transition alone — known limitation)
- [x] T6 Baseline sweep complete — tests/results/run-2026-05-05-183932.json. 108 scenarios, $5.40, 35 min. Result: PASS=63 SOFT=32 FAIL=6 FLAKY=7 (exit 6). **6 hidden FAILs surfaced** to backlog: F4, F13-prefiltered, S3, S10, S13, S6. None fixed in this task (out of scope). High-priority entries: HIDDEN-FAIL-S10 and HIDDEN-FAIL-S13 (both touch drive-mode/orchestrator area; investigate together).
- [x] T7 Update comment on modified line — folded into T1 (new comment: "Verify — wrap with set +e/-e so verify_result's non-zero return doesn't trip set -e, while still capturing the real return code into rc.")

## Verification protocol details

**T4 synthetic test** is the conclusive proof the fix works — it deliberately constructs a known-bad scenario:
- Pre-fix this scenario reports `status=PASS` with `details="Wrong transition"` (contradiction visible in JSON).
- Post-fix this scenario reports `status=FAIL`, runner exit 1, FAILURES list populated.
- Revert the YAML change immediately after — do not commit it.

**T5 real-world test** confirms in-flight reproduction signals from the paused feature surface correctly. We don't need to repair the paused feature here, just confirm the harness now exposes the truth those scenarios were already producing.

**T6 baseline sweep** is exploratory. The full suite is 108 scenarios at ~$0.05 each on haiku — call it ~$5.40 worst case. This is acceptable per the user's prior willingness to spend on real model calls. Each hidden-FAIL goes to backlog as a separate item; this task does NOT fix them. If the user prefers a cheaper recon, run `--group feature` first (~$2.55 for 51 scenarios) and decide whether to expand from there based on what's hiding.

## Risks

- **R1 — bash strict-mode interactions elsewhere.** The fix only changes one block; nothing else in run-tests.sh changes. But if some downstream caller depends on `set -e` being active during the verify call (it shouldn't — `verify_result` is the only call inside the wrapped region and we explicitly want its non-zero to be captured), that would be exposed. Mitigation: T2 dry-run + T4/T5 real runs catch any surprise.
- **R2 — baseline sweep cost.** Already accounted for above. If the user wants to skip T6 entirely and just unblock the feature, T1–T5 are sufficient and T6 can be deferred to a later "test-suite hygiene" task. Default plan keeps T6 because hidden-FAIL discovery is the second-most valuable output of fixing this bug.
- **R3 — flakiness on baseline sweep.** Some scenarios may be naturally flaky on haiku. The runner has retry logic (per-scenario `max_retries`). Treat any `FLAKY` status in T6 as informational, not a hidden-FAIL.

## Out of scope (per user instruction)

- Fixing any hidden-FAILs surfaced by T6 — they go to backlog as separate items.
- Changes to `verify_result` itself — including the documented `not_contains` lenience (D2 in the paused feature). Separate concern.
- Re-design of how the runner reports SOFT_PASS in the summary tally.

## Current Node
- **Path:** Task > all complete → ready for /task-close
- **Active scope:** all complete
- **Blocked:** none
- **Open discoveries:** 6 hidden-FAIL backlog entries (HIDDEN-FAIL-F4, -F13-prefiltered, -S3, -S10, -S13, -S6) — not fixed in this task per explicit out-of-scope instruction

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-05-05] T6 — 6 hidden FAILs uncovered by the baseline sweep. Logged individually as HIDDEN-FAIL-{F4, F13-prefiltered, S3, S10, S13, S6} in workflow/backlog.md. Two are HIGH priority (S10, S13 — touch drive-mode/orchestrator hardening from WP14/WP15 and warrant investigation before further session-related work). One (F13-prefiltered) may auto-resolve once the integration-boundary feature ships, since it triggers on the same F11 skip path that feature is closing.

[SURFACED-2026-05-05] T5 — F-boundary-human is FLAKY on haiku (passed only on retry). The integration-boundary feature plan should account for this when designing post-revision assertions; recorded in the paused feature WIP for visibility on resume.

## Retrospect
- **What changed in our understanding:** A subtle bash trap — `cmd || true; rc=$?` always captures `0` from `true`, defeating return-code inspection — had silently corrupted the project's entire test signal for an unknown amount of time. Until the integration-boundary feature pushed verify-auto into territory where the JSON `details` field obviously contradicted the `status` field, the bug was invisible. Lesson: tests are an inference layer; a bug in the layer is far more dangerous than a bug below it because it makes failures stop being failures.
- **Assumptions that held:** The `set +e` / `set -e` wrap was correctly identified as the right fix at plan time. Empirical pre-flight sanity check on Option B (drop `|| true`, rely on bash quirks) proved it would re-trigger `set -e` — that pre-flight saved a wasted iteration. T4's synthetic-mutation strategy (BOGUS_ID + ZZZ_NEVER_MATCHES_ZZZ) cleanly produced FAIL post-fix; the verification ladder design held.
- **Assumptions that were wrong:** Estimated baseline sweep at $5.40 and 10–15 min — cost was exactly $5.40 (lucky), but duration was 35 min, more than 2× the estimate (per-scenario time ~20s, not 10s; haiku retries amplified this). Estimated 0–2 hidden FAILs; actually 6 — the project had been silently regressing without anyone noticing.
- **Approach delta:** None — implementation matched the plan exactly. T1–T7 ran in order, no back-loops, no scope changes. The only deviation was that T7 (refresh comment) was folded into T1 since they touched the same lines.
