# Task: Migrate session storage from cookies to Redis

**Workflow:** task
**State:** act (complete)
**Created:** 2026-04-14

## Problem Statement
Session storage uses cookies which have a race condition under concurrent requests.

## Context
- Session middleware: `src/middleware/session.py`
- Redis config: `config/redis.yml`

## Work Tree

- [x] T1 Replace cookie-based session store with Redis adapter
- [x] T2 Update session TTL to use centralized config value
- [x] T3 Verify session persistence under concurrent requests

## Current Node
- **Path:** Task > complete
- **Active scope:** all steps complete
- **Blocked:** none
- **Open discoveries:** see Discoveries

## Discoveries
- [ ] Redis connection pool config is undocumented — reverse-engineered from production  <!-- status: SURFACED: tech debt — document Redis pool config -->
- [ ] Session TTL hardcoded in 3 places — should be centralized  <!-- status: SURFACED: tech debt — TTL centralization -->
- [ ] Cookie-based sessions had a race condition under concurrent requests — fixed here  <!-- status: SURFACED: bug — fixed in this task -->
