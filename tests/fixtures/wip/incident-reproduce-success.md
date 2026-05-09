# Incident: API 500 on /api/v2/users for users without profile_image_url

**Workflow:** incident
**State:** reproduce
**Severity:** P1
**Status:** Triaged → reproducing

## Summary
500 errors on /api/v2/users after deployment. 15% error rate. Severity P1.
Triage decision: REPRODUCIBLE — issue is deterministic for any user record missing profile_image_url. Proceeding to red-green reproduction.

## Reproduction Attempt
**Surface chosen:** failing test
**Outcome:** reproduced
**Artifact:** `tests/test_user_api.py::test_get_users_returns_200_with_null_profile_image` — asserts /api/v2/users returns 200 with `profile_image_url: null` when user record's image field is null. Currently fails: returns 500 with NoneType serializer error.
**Determinism:** every-run (100% reproducible against test fixture user_with_null_image)
**Notes:** Failing test is the verify gate for mitigate. The serializer in `app/serializers/user.py` line 47 calls `.lower()` on profile_image_url without null check.
