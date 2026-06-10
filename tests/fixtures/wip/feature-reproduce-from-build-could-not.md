# Feature: Inventory Race Condition Fix

**Workflow:** feature
**State:** reproduce (F36-redirect from build, Phase 2)
**Created:** 2026-06-09
**Entry:** plan → build (paused mid-Phase-2 via F36 REDIRECT)

## Problem Statement

InventoryService.reserveStock() under high-concurrency load is reportedly allowing two simultaneous requests to reserve the same item, producing a double-reservation race. Mid-build at Phase 2, realized no pre-fix failing-test anchor exists; F36-redirected to reproduce.

## Work Tree

- [x] Phase 1: Add row-level lock to InventoryService.reserveStock()  <!-- status: complete -->

- [ ] Phase 2: Refactor reserveStock callers to handle lock-wait timeouts  <!-- status: paused (F36 REDIRECT) -->
  - [x] P2.1 Add lock-wait timeout config
  - [ ] P2.2 Wrap callers with timeout handler  <!-- status: paused — F36 REDIRECT in flight -->

## Current Node
- **Path:** Feature > Phase 2 > reproduce (F36 REDIRECT)
- **Active scope:** reproduce
- **Blocked:** P2.2 (paused pending reproduce outcome)
- **Unvisited:** none
- **Open discoveries:** none
- **Redirect source:** build (F36 — Phase 2)

## Reproduction Artifact (mid-build, from F36)

<placeholder — to be filled by /feature-reproduce on F37/F37b exit>

## Reproduction (this run — could-not-reproduce)

- **Surface chosen:** failing test
- **Outcome:** could-not-reproduce
- **Attempted artifact:** `tests/inventory/test_reserve_stock_race.py` — pytest-asyncio test issuing 50 concurrent reserveStock calls against a single SKU with stock=1. Ran on pre-Phase-1 commit (without the lock). After 200 trial runs, the race **never fires** in the test environment — exactly 1 reservation succeeds in every run.
- **Why it didn't fire:** asyncio in the test environment uses deterministic single-thread scheduling. The DB driver's connection pool serializes the SELECT-then-UPDATE under the test harness, so the interleave window the bug exploits in production (multi-process gunicorn workers hitting a real Postgres) doesn't open under pytest-asyncio. Reproducing in test would require either a real multi-process load test against a real Postgres (out of scope for unit/integration) or a synthetic race injector that monkey-patches the DB driver to force the interleave (fragile).
- **Determinism:** 0 reproduces / 200 trials. The bug is real in production (telemetry shows 12 duplicate-reservation incidents in the last 30 days), but not capturable in the local test environment.
- **Notes:** The fix may still be correct — the Phase 1 lock + Phase 2 timeout handler is the standard mitigation for this race shape. Verify-codify for Phase 2 will need to rely on the production-telemetry-monitoring path (no duplicate-reservation alerts post-deploy for N days) rather than a local failing-test anchor.

## Discoveries
