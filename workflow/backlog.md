# Backlog

## SURFACE-2026-05-05-F22-FLAKY-REGRESSED-TO-FAIL
- **Source:** feature:verify-auto (integration-boundary-verify-rules, Phase 5 final regression sweep)
- **Target level:** feature:spec
- **Type:** bug (haiku noise; not caused by integration-boundary feature)
- **Summary:** F22 ("feature:build redirects to research on unknown") was FLAKY-pass-on-retry in baseline (run-2026-05-05-183932.json); FAIL in post-feature sweep (run-2026-05-05-203944.json) with `transition_found: BLOCKED` (not a valid transition id — BLOCKED is status vocabulary). Model is conflating transition with status.
- **Context:** F22 tests the feature-build SKILL, which the integration-boundary feature did NOT modify. Almost certainly haiku noise on a scenario that was already on the edge (FLAKY in baseline). Worth investigating whether the SKILL prompt accidentally invites the model to emit "BLOCKED" as a TRANSITION id, or whether sonnet override is needed for this scenario.
- **Suggested action:** Re-run F22 a few times to confirm it's flake-rather-than-deterministic-fail. If consistent, investigate feature-build SKILL prompt for BLOCKED/transition-id confusion. Consider --model sonnet override.
- **Priority:** medium
- **Status:** pending — not blocking integration-boundary feature ship since cause is unrelated.

## SURFACE-2026-05-05-F13-PREFILTERED-AUTO-RESOLVED
- **Source:** feature:verify-auto (integration-boundary-verify-rules, Phase 5 final regression sweep)
- **Target level:** feature:spec
- **Type:** positive side-effect
- **Summary:** F13-prefiltered ("verify-human excludes verify-self [x] items from checklist") moved from FAIL/F11 in baseline (run-2026-05-05-183932.json) to PASS in post-feature sweep (run-2026-05-05-203944.json). Baseline F11 emission was caused by the verify-human "nothing to manually test" skip path; the integration-boundary feature replaced that path with affirmation-gated skip, which the model now reasons through correctly.
- **Suggested action:** Mark HIDDEN-FAIL-F13-prefiltered RESOLVED below.
- **Priority:** low (already resolved)
- **Status:** RESOLVED 2026-05-05 — auto-resolved by integration-boundary-verify-rules feature.

## SURFACE-2026-05-05-HIDDEN-FAIL-F4
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** F4 ("feature:spec → plan when spec is clear") FAILs on haiku — emits TRANSITION: F2 instead of expected F4.
- **Context:** Hidden by the run-tests.sh `|| true` bug until 2026-05-05. tests/results/run-2026-05-05-183932.json has full JSON.
- **Suggested action:** Investigate whether F2 is genuinely a valid alternative, the SKILL prompt is misleading on haiku, or the scenario fixture is ambiguous. Consider --model sonnet override or scenario fixture clarification.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-05-05-HIDDEN-FAIL-F13-prefiltered
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** F13-prefiltered ("verify-human excludes verify-self [x] items from checklist") FAILs on haiku — emits TRANSITION: F11 (skip path) instead of expected F13 (approve).
- **Context:** Hidden by the run-tests.sh `|| true` bug until 2026-05-05. The model is taking the F11 skip path (the same skip path the integration-boundary feature is closing) on a fixture that should produce F13.
- **Suggested action:** Worth coordinating with the integration-boundary feature — once that ships, F13-prefiltered may resolve naturally because the skip path will be gated by the affirmation. Investigate after integration-boundary feature lands.
- **Priority:** medium
- **Status:** RESOLVED 2026-05-05 — auto-resolved by integration-boundary-verify-rules feature. Confirmed in run-2026-05-05-203944.json (Phase 5 final regression sweep).

## SURFACE-2026-05-05-HIDDEN-FAIL-S3
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S3 ("session:start routes simple feature to feature:plan") FAILs on haiku — emits TRANSITION: CLASSIFY instead of expected S3.
- **Context:** Hidden by harness bug. CLASSIFY is not in the documented transition vocabulary (docs/product/transitions.md) — the model is making it up.
- **Suggested action:** Investigate session-start SKILL prompt. CLASSIFY may be leaking from older skill text. Check --model sonnet stability.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-05-05-HIDDEN-FAIL-S10
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S10 ("session:start regression — stops after plan when user says 'drive it end-to-end'") FAILs on haiku — emits TRANSITION: F8 instead of expected S10.
- **Context:** Hidden by harness bug. Concerning — this scenario tests one of the recent WP14/WP15 hardening fixes (orchestrator auto-advance). F8 is feature:build → verify-auto, which suggests the model is in the right ballpark but mis-naming the transition or running into a SKILL-vs-orchestrator tension.
- **Suggested action:** High-priority investigation — touches drive-mode regression hardening. May indicate the orchestrator AGENTS.md doesn't survive the test harness's TRANSITION enforcement.
- **Priority:** high
- **Status:** pending

## SURFACE-2026-05-05-HIDDEN-FAIL-S13
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S13 ("session:step-by-step (mode 1) pauses after every skill") FAILs on haiku — emits TRANSITION: F10 instead of expected S13.
- **Context:** Hidden by harness bug. Tests step-by-step drive mode. F10 is feature:verify-auto → verify-self.
- **Suggested action:** Likely related to S10 (orchestrator/drive-mode area). Investigate together.
- **Priority:** high
- **Status:** pending

## SURFACE-2026-05-05-HIDDEN-FAIL-S6
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S6 ("session:resume deletes .session.md after restoring context") FAILs on haiku — emits TRANSITION: T10 instead of expected S6.
- **Context:** Hidden by harness bug. T10 is task:close. The model may be conflating "resume + immediate exit" with task close.
- **Suggested action:** Investigate session-resume SKILL prompt. Possibly the post-restore-and-cleanup transition is unclear in the prompt.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-05-05-F15-REGRESSION-FROM-CODIFY-WORDING
- **Source:** feature:build (integration-boundary-verify-rules, Phase 4 verify-auto)
- **Target level:** feature:spec
- **Type:** tech-debt
- **Summary:** F15 ("verify-codify → build next phase when more phases") regressed from PASS/F15 to SOFT_PASS/F14 (back-loop to verify-human) after Phase 4 added the "Integration-boundary requirement" sub-section to feature-verify-codify/SKILL.md. The model is now over-cautious — on the notification-preferences fixture (genuinely no integration boundary), it's flagging codify as needing a back-loop instead of advancing.
- **Context:** run-2026-05-05-200320.json. F15's `details` shows "Contains '/feature-build' (no structured TRANSITION line)" with transition_found=F14. The model output mentions `/feature-build` (correct content — it knows next phase is needed) but frames it as F14 back-loop rather than F15 advance. SOFT_PASS, not FAIL — content-correct, transition-mislabeled. F-boundary-codify on the same run cites `/distribution/match` (the content flip we wanted) but emits F16 (ship) instead of F15. Both scenarios suggest the new wording makes the model treat any "still need a test" or "boundary applies" reasoning as terminal-state reasoning rather than per-phase reasoning.
- **Suggested action:** Soften the codify sub-section wording to make the per-phase nature clearer — e.g., add "This requirement applies to the current phase only; if satisfied, codify advances normally per §4." Or split the requirement into a "checklist" framing. Re-run F15 and F-boundary-codify with the softer wording. Don't fix in this feature — feature is otherwise complete and ships fine; this is a tuning task.
- **Priority:** medium
- **Status:** RESOLVED 2026-05-05 — fixed by P4.1 iteration 3 wording (skills/feature-verify-codify/SKILL.md lines 43-48). Iterated through 3 wording attempts: gating ("MUST") → over-affirmative ("proceed to §3 normally") → balanced ("when planning the test set above ... shapes which tests you write ... §3/§4 still own all advance / back-loop / ship decisions"). Verified across runs run-2026-05-05-201827.json (6/6 PASS) and run-2026-05-05-202247.json (F-boundary-codify SOFT_PASS via `/distribution/match` content match, force preserved).

## SURFACE-2026-05-05-HARNESS-RC-BUG
- **Source:** feature:build (integration-boundary-verify-rules, Phase 1 verify-auto)
- **Target level:** product:wbs (touches the test harness, which is product-level infra)
- **Type:** bug
- **Summary:** `tests/run-tests.sh` line 183 uses `verify_result ... || true; rc=$?` — the `|| true` clears the return code, so `$?` is always 0 (from `true`) when verify_result returned non-zero. Every FAIL (rc=2) and SOFT_PASS (rc=1) is misreported as PASS.
- **Context:** Discovered when reproduction scenarios for the integration-boundary feature reported PASS while the JSON `details` field said "Wrong transition: found F10b, expected F9b" — two facts that are contradictory under intended verify.sh logic. Bash semantics confirmed: `fn(){ return 2; }; fn || true; echo $?` prints `0`. Affects all 108 scenarios across all groups; historical PASS results may include hidden FAILs.
- **Suggested action:** Replace line 183 with `set +e; verify_result "$result_text" "$expect_id" "$contains_any" "$not_contains"; local rc=$?; set -e` (preserves the script's `set -e` while capturing the return code), or simpler: drop the `|| true` and accept that `set -e` doesn't trigger inside command substitution / on the LHS of `&&`/`||`. Verify with a known-bad scenario.
- **Priority:** high
- **Status:** RESOLVED 2026-05-05 — fix applied at tests/run-tests.sh:182-187 (set +e/-e wrap); verified via synthetic test (run-2026-05-05-183023.json) and baseline sweep (run-2026-05-05-183932.json) which surfaced 6 hidden FAILs that had been masked by the bug. See HIDDEN-FAIL-* entries above for those.

## SURFACE-2026-05-05-D2
- **Source:** task:act (integration-boundary-verify-rules)
- **Target level:** product:wbs
- **Type:** tech-debt
- **Summary:** `tests/lib/verify.sh` `verify_result()` returns PASS when `TRANSITION:` id matches even if a `not_contains` term is present in the output. The negative-hits string is recorded in VERIFY_DETAIL but does not flip the return code.
- **Context:** Discovered while writing scenarios where the *content* of the response (e.g. presence/absence of "skip") matters as much as the transition id. The current harness can't enforce a content-level negative assertion alongside a transition match. Comment at lines 32–38 calls this intentional ("structured match is authoritative") — but it does limit how precisely scenarios can express expected behavior. Existing scenarios (~50) all rely on transition id alone, so this hasn't bitten us before.
- **Suggested action:** Consider a `not_contains_strict: true` opt-in flag on a per-scenario basis, or split into `not_contains_warn` (current behavior) vs `not_contains_fail` (returns FAIL). Don't change the default — would risk flapping existing scenarios.
- **Priority:** low
- **Status:** pending
