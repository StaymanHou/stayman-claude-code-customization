# Backlog

## SURFACE-2026-05-06-S12-AUTOCHAIN-LEAK-IN-AUTOPILOT
- **Source:** feature:verify-auto (full-autopilot dual-identity + strict feature, S12 strict assertion)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S12 ("session:autopilot (mode 3) pauses at verify-human") FAILs strict mode because the model emits "auto-chain" in its prose despite Mode 3 explicitly stating verify-human is the only pause point. The structured TRANSITION emission is correct (S12); the prose is contradicting the assertion. Discovered when `not_contains_strict: true` was added to surface this kind of contradiction.
- **Context:** run-2026-05-06-143839-combined.json. The model output structurally matches but text-content-leaks "auto-chain" while describing the autopilot pause. Likely the model is reasoning about what it WOULDN'T do and the negation slips. session-start/SKILL.md "Drive modes" section may need wording that suppresses prose mention of auto-chain when discussing pause points.
- **Suggested action:** Investigate session-start/SKILL.md "Mode 3" guidance. Consider adding "When describing Mode 3's behavior, do not use 'auto-chain' even in negation — say 'pauses at verify-human' affirmatively." Test with `--id S12` after edit.
- **Priority:** medium
- **Status:** pending — discovered by strict-mode harness; surfaces a wording/clarity issue, not a structural one.

## SURFACE-2026-05-06-S9-S11-S14-DUAL-IDENTITY
- **Source:** feature:verify-auto (document-session-transitions, Phase 2)
- **Target level:** product:wbs
- **Type:** tech-debt
- **Summary:** During mid-orchestration steps, session-start emits the F-ID of the workflow it's driving instead of the S-ID. Harness only had `transition_id` (single).
- **Suggested action:** Add `transition_id_any: [...]` to harness; update affected scenarios.
- **Priority:** medium
- **Status:** RESOLVED 2026-05-06 — `transition_id_any` added to `tests/lib/verify.sh`; S9, S11, S12, S13, S14 updated to use it. S9 now PASSes via S9|F19 union. S12 strict-mode caught a real prose bug (logged separately as SURFACE-2026-05-06-S12-AUTOCHAIN-LEAK-IN-AUTOPILOT).

## SURFACE-2026-05-06-S10-S13-ROUTING-OVERRIDES-DRIVE-MODE
- **Source:** feature:verify-auto (document-session-transitions, Phase 2)
- **Target level:** feature:spec
- **Type:** tech-debt
- **Summary:** S10/S13 emit routing ID S3 instead of drive-mode IDs. Content is correct.
- **Suggested action:** Add `transition_id_any: [S10, S3]` and `[S13, F8]`.
- **Priority:** low
- **Status:** RESOLVED 2026-05-06 — `transition_id_any` applied: S10 accepts [S10, S3]; S13 accepts [S13, F8]. Some haiku-noise SOFT_PASS shape remains, but the routing-vs-drive-mode dual identity is now expressible in the harness.

## SURFACE-2026-05-05-D2
- **Source:** task:act (integration-boundary-verify-rules)
- **Target level:** product:wbs
- **Type:** tech-debt
- **Summary:** `verify_result()` returned PASS even when `not_contains` term was present. Negative-hits string was recorded but did not flip the return code.
- **Suggested action:** Add `not_contains_strict: true` opt-in.
- **Priority:** low
- **Status:** RESOLVED 2026-05-06 — `not_contains_strict` added to `tests/lib/verify.sh`. Default behavior (lenient) preserved for existing scenarios; opt-in strict mode applied to S12 and S14. Strict mode caught a real prose-leak bug in S12 (logged separately).

## SURFACE-2026-05-05-HIDDEN-FAIL-F4
- **Status:** RESOLVED 2026-05-06 — `model: sonnet` added; PASSes via tests/run-all.sh sonnet pass.

## SURFACE-2026-05-05-HIDDEN-FAIL-S3
- **Status:** RESOLVED 2026-05-06 — Valid transitions section added to session-start/SKILL.md; S3 also tagged `model: sonnet`. Sonnet PASSes consistently.

## SURFACE-2026-05-05-HIDDEN-FAIL-S6
- **Status:** RESOLVED 2026-05-06 — Valid transitions section added to session-resume/SKILL.md; S6 PASSes on haiku.

## SURFACE-2026-05-05-F22-FLAKY-REGRESSED-TO-FAIL
- **Status:** RESOLVED 2026-05-06 — `model: sonnet` added; PASSes via tests/run-all.sh sonnet pass.

## SURFACE-2026-05-05-HIDDEN-FAIL-S10
- **Status:** RESOLVED 2026-05-06 — `transition_id_any: [S10, S3]` applied. See SURFACE-2026-05-06-S10-S13-ROUTING-OVERRIDES-DRIVE-MODE.

## SURFACE-2026-05-05-HIDDEN-FAIL-S13
- **Status:** RESOLVED 2026-05-06 — `transition_id_any: [S13, F8]` applied. See SURFACE-2026-05-06-S10-S13-ROUTING-OVERRIDES-DRIVE-MODE.
