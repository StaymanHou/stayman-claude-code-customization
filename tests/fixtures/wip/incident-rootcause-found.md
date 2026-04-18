# Incident: API 500 errors on /api/v2/users

**Workflow:** incident
**State:** investigate
**Severity:** P1
**Status:** Investigating

## Root Cause
The 14:15 deployment introduced a new serializer that expects a `profile_image_url`
field, but existing users created before the migration don't have this field.
NoneType error when serializing users without profile images.

## Resolution Plan
Add a default value fallback in the serializer for `profile_image_url`.
