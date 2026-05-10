# Incident: API 500 errors on /api/v2/users

**Workflow:** incident
**State:** codify
**Severity:** P1
**Status:** Monitoring

## Reproduction Attempt
**Surface chosen:** failing test
**Outcome:** reproduced
**Artifact:** `tests/test_users_api.py::test_get_users_with_null_profile_image_returns_200` — this test was written during /incident-reproduce and asserts that GET /api/v2/users returns 200 when a user record has null profile_image_url. Test was failing before mitigation (NoneType serializer error).
**Determinism:** every-run
**Notes:** Pre-mitigation state of the test: FAIL with NoneType. Post-mitigation expected state: PASS.

## Root Cause
The 14:15 deployment introduced a new serializer that expects a `profile_image_url`
field, but existing users created before the migration don't have this field.
NoneType error when serializing.

## Mitigation
- Added default empty string for `profile_image_url` in serializer (`src/serializers/user.py:42`)
- Deployed hotfix at 15:00
- Error rate dropped to 0% by 15:05
- Monitoring for 30 minutes — no regressions

## Codify
*Pending — to be filled in by /incident-codify.*
