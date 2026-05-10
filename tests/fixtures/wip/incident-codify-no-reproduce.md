# Incident: API 500 errors on /api/v2/users

**Workflow:** incident
**State:** codify
**Severity:** P2
**Status:** Monitoring

## Root Cause
The 14:15 deployment introduced a new serializer that expects a `profile_image_url`
field, but existing users created before the migration don't have this field.
NoneType error when serializing. Investigation jumped straight from triage to
investigate (skipped reproduce) because the bug was first seen via prod telemetry
rather than as a reproducible local case.

## Mitigation
- Added default empty string for `profile_image_url` in serializer (`src/serializers/user.py:42`)
- Deployed hotfix at 15:00
- Error rate dropped to 0% by 15:05
- Monitoring for 30 minutes — no regressions

## Codify
*Pending — to be filled in by /incident-codify. No prior reproduce artifact; this is Path B (write coverage from scratch).*
