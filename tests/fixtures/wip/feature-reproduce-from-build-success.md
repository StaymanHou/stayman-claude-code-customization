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
- **Blocked:** P2.2 (paused pending reproduce artifact)
- **Unvisited:** none
- **Open discoveries:** none
- **Redirect source:** build (F36 — Phase 2)

## Reproduction Artifact (mid-build, from F36)

<placeholder — to be filled by /feature-reproduce on F37/F37b exit>

## Reproduction (this run — succeeded)

- **Surface chosen:** failing test
- **Outcome:** reproduced
- **Artifact:** `tests/inventory/test_reserve_stock.py::test_double_reserve_under_concurrent_request` — uses pytest-asyncio + 50 concurrent reserveStock calls against a single SKU with stock=1. Without the Phase 1 lock, the test FAILS — 2 of 50 calls succeed reserving stock=1, producing 2 reservations for 1 unit. With the lock (current code), the test PASSES — exactly 1 reservation succeeds, 49 fail with InsufficientStockError. The bug is reproduced cleanly on the pre-Phase-1 commit.
- **Determinism:** every-run (50 trials × 10 runs = 500/500 reproduces on pre-Phase-1; 0/500 on current code)
- **Notes:** This is the verify-codify anchor for Phase 2 — "fixed means this test no longer fails on the post-Phase-2 code under high-concurrency timeout-handler conditions."

## Discoveries
