# Bug: API request to `/api/users/:id` returns 500 for one specific user ID

**Workflow:** feature
**State:** build (Phase 1 — initial investigation)
**Created:** 2026-06-10

## Problem Statement
`GET /api/users/12345` returns a 500 Internal Server Error. Other user IDs work fine. The stack trace points at a `KeyError: 'preferences'` in the serializer at line 87. This looks like a runtime-state issue (one user record is missing the `preferences` key), and the bug almost certainly involves observing what that user's record looks like in the database vs. other users' records.

## Investigation State

Straight-line debug attempts so far:
1. Read the serializer code — confirmed it does `user_dict["preferences"]` unconditionally on line 87. If the key is missing on the user record, it raises `KeyError`.

That's it — only **one** straight-line debug attempt so far. Have not yet checked: whether user 12345's database row actually has the `preferences` field; whether other working user IDs have it; whether the serializer should be using `.get()` instead of `[]`; whether there's a migration that left some user rows without the field.

## Bug-shape

The bug shape MAY require runtime evidence (Gate 2 might hold — checking the actual DB row would help). But Gate 1 (≥2–3 failed static-reasoning attempts) clearly does NOT hold yet — only one static read has been attempted. The natural next steps are cheap static-reasoning extensions: examine the schema, run a SELECT on user 12345's row, compare it to a working user's row, look for recent migrations affecting `preferences`.

## Next Step

Continue static-reasoning debug for at least 2 more iterations before considering `/debug-empirical-telemetry`. The cheap path (SQL query against the user row + serializer rewrite to use `.get()`) likely localizes the cause faster than instrumenting a running worker.
