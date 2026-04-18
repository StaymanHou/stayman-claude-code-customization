# Task: Migrate session storage from cookies to Redis

**Workflow:** task
**State:** act (complete)
**Created:** 2026-04-14

## Notes
- Discovered that the cookie-based sessions had a race condition under concurrent requests
- The Redis connection pool configuration was undocumented — had to reverse-engineer from production config
- Found that the session TTL was hardcoded in 3 different places — this is tech debt worth noting
