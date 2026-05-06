# Backlog

## SURFACE-2026-05-06-S9-S11-S14-DUAL-IDENTITY
- **Source:** feature:verify-auto (document-session-transitions, Phase 2)
- **Target level:** product:wbs (touches test harness)
- **Type:** tech-debt
- **Summary:** During mid-orchestration steps, session-start emits the F-ID of the workflow it's driving (e.g., F19 at finalize, F8 at build, F11/F13 at verify-human-skip) instead of the S-ID labeling its own decision. S9 (pause-at-finalize), S11 (mode-4 chain past plan), S14 (mode-4 skip verify-human) are content-correct but transition-mislabeled. The harness has only `transition_id` (single match); a `transition_id_any: [...]` would let scenarios accept the dual identity honestly.
- **Suggested action:** Add `transition_id_any` support to `tests/lib/verify.sh` (~5-10 lines) — accepts either S-ID or its companion F-ID. Then update S9 (`[S9, F19]`), S11 (`[S11, F7]`), S14 (`[S14, F11, F13]`).
- **Priority:** medium
- **Status:** pending — improves test signal precision; no behavior bug.

## SURFACE-2026-05-06-S10-S13-ROUTING-OVERRIDES-DRIVE-MODE
- **Source:** feature:verify-auto (document-session-transitions, Phase 2)
- **Target level:** feature:spec
- **Type:** tech-debt
- **Summary:** S10 (drive-mode menu shown) and S13 (mode 1 step-by-step pause) emit routing ID S3 instead of their own drive-mode IDs. Content is correct (drive-mode menu IS shown; step-by-step pause messaging IS produced) — model classifies the underlying request as routing first, then drive-mode is secondary signal. Wording iteration on session-start/SKILL.md could push the model to label the drive-mode output as primary, but oscillation risk is high (precedent: integration-boundary feature Phase 4 took 3 wording iterations).
- **Suggested action:** Either (a) one careful wording iteration anchoring "when both routing and drive-mode classifications apply, label as the drive-mode ID", or (b) accept SOFT_PASS as the natural shape and add `transition_id_any: [S10, S3]` etc. once that harness support exists (see SURFACE-2026-05-06-S9-S11-S14-DUAL-IDENTITY). Option (b) is lower risk.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-05-05-HIDDEN-FAIL-F4
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug (haiku noise)
- **Summary:** F4 ("feature:spec → plan when spec is clear") FAILs on haiku — emits TRANSITION: F2/F3 instead of expected F4. Confirmed haiku-only via 2026-05-06 recon (sonnet PASSes consistently).
- **Suggested action:** Tag scenario `model: sonnet`.
- **Priority:** medium
- **Status:** RESOLVED 2026-05-06 — `model: sonnet` added to F4 in tests/scenarios/feature.yaml; PASSes via tests/run-all.sh sonnet pass.

## SURFACE-2026-05-05-HIDDEN-FAIL-S3
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S3 ("session:start routes simple feature to feature:plan") FAILs on haiku — model lacked S-ID anchors (only F-IDs in scope from agents/feature-workflow/AGENTS.md), fabricated "CLASSIFY" / "T1" / similar.
- **Suggested action:** Document S-IDs in transitions.md + add Valid transitions section to session-start/SKILL.md (three-places invariant restoration).
- **Priority:** medium
- **Status:** RESOLVED 2026-05-06 — Valid transitions section added to session-start/SKILL.md; S3 also tagged `model: sonnet` because haiku continued to FLAKY/FAIL even after the doc fix; sonnet FLAKY-passes consistently.

## SURFACE-2026-05-05-HIDDEN-FAIL-S6
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S6 ("session:resume deletes .session.md after restoring context") FAILs on haiku — emits T10 (task:close) instead of S6. Same root cause as S3: SKILL.md had no S-ID anchors.
- **Suggested action:** Add Valid transitions section to session-resume/SKILL.md.
- **Priority:** medium
- **Status:** RESOLVED 2026-05-06 — Valid transitions section added to session-resume/SKILL.md (S6, S15, S16); S6 PASSes solidly on haiku.

## SURFACE-2026-05-05-F22-FLAKY-REGRESSED-TO-FAIL
- **Source:** feature:verify-auto (integration-boundary-verify-rules, Phase 5 final regression sweep)
- **Target level:** feature:spec
- **Type:** bug (haiku noise)
- **Summary:** F22 ("feature:build redirects to research on unknown") emits "BLOCKED" (status vocabulary, not transition id) on haiku. Confirmed haiku-only via 2026-05-06 recon (sonnet PASSes).
- **Suggested action:** Tag scenario `model: sonnet`.
- **Priority:** medium
- **Status:** RESOLVED 2026-05-06 — `model: sonnet` added to F22; PASSes via tests/run-all.sh sonnet pass.

## SURFACE-2026-05-05-HIDDEN-FAIL-S10
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S10 ("session:start regression — stops after plan when user says 'drive it end-to-end'") FAILed on haiku — emitted F8 instead of S10.
- **Status:** PARTIALLY RESOLVED 2026-05-06 — moved from FAIL to SOFT_PASS (content correct: drive-mode menu shown, "Autopilot" present; transition mislabeled as routing S3). Remaining work tracked in SURFACE-2026-05-06-S10-S13-ROUTING-OVERRIDES-DRIVE-MODE.

## SURFACE-2026-05-05-HIDDEN-FAIL-S13
- **Source:** task:act (harness-rc-bug-fix T6 baseline sweep)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S13 ("session:step-by-step (mode 1) pauses after every skill") FAILed on haiku — emitted F10 instead of S13.
- **Status:** PARTIALLY RESOLVED 2026-05-06 — moved from FAIL to SOFT_PASS (content correct: "/feature-verify-auto" present; transition mislabeled). Remaining work tracked in SURFACE-2026-05-06-S10-S13-ROUTING-OVERRIDES-DRIVE-MODE.

## SURFACE-2026-05-05-D2
- **Source:** task:act (integration-boundary-verify-rules)
- **Target level:** product:wbs
- **Type:** tech-debt
- **Summary:** `tests/lib/verify.sh` `verify_result()` returns PASS when `TRANSITION:` id matches even if a `not_contains` term is present in the output. The negative-hits string is recorded in VERIFY_DETAIL but does not flip the return code. Also surfaced in document-session-transitions Phase 2: S12 omitted the TRANSITION line entirely but matched on content → SOFT_PASS via lenient path; arguably should be FAIL.
- **Context:** Discovered while writing scenarios where the *content* of the response (e.g. presence/absence of "skip") matters as much as the transition id. The current harness can't enforce a content-level negative assertion alongside a transition match. Comment at lines 32–38 calls this intentional ("structured match is authoritative") — but it does limit how precisely scenarios can express expected behavior.
- **Suggested action:** Consider a `not_contains_strict: true` opt-in flag on a per-scenario basis, or split into `not_contains_warn` (current behavior) vs `not_contains_fail` (returns FAIL). Don't change the default — would risk flapping existing scenarios.
- **Priority:** low
- **Status:** pending
