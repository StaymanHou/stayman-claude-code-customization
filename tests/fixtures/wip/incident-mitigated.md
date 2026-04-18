# Incident: API 500 errors on /api/v2/users

**Workflow:** incident
**State:** mitigate
**Severity:** P1
**Status:** Monitoring

## Mitigation
- Added default empty string for `profile_image_url` in serializer
- Deployed hotfix at 15:00
- Error rate dropped to 0% by 15:05
- Monitoring for 30 minutes — no regressions
