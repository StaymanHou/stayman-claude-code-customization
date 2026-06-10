# Feature: Inventory Race Condition Fix

**Workflow:** feature
**State:** build (Phase 2 — P2.2 in progress)
**Created:** 2026-06-09
**Entry:** plan (small/simple feature — entered at /feature-plan, NOT via /feature-reproduce)

## Problem Statement

InventoryService.reserveStock() under high-concurrency load is reportedly allowing two simultaneous requests to reserve the same item, producing a double-reservation race. Originally reported as "occasionally we get two orders for the last unit." The fix being applied is a row-level lock around the stock check + decrement.

## Work Tree

- [x] Phase 1: Add row-level lock to InventoryService.reserveStock()  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `pytest tests/inventory/test_reserve_stock.py::test_lock_acquired` PASS
  - [x] P1.1 Add SELECT FOR UPDATE to reserveStock query
  - [x] P1.2 Update transaction boundary
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [x] verify-codify

- [ ] Phase 2: Refactor reserveStock callers to handle lock-wait timeouts  <!-- status: in-progress -->
  **Observable outcomes:**
  - HTTP: POST /api/orders with valid items → 200, no double-reservation observed under 100 concurrent reqs
  - CLI: load-test script `bin/load-test-orders.sh --concurrency 100` exits 0
  - [x] P2.1 Add lock-wait timeout config to InventoryService  <!-- status: complete -->
  - [ ] P2.2 Wrap callers with timeout handler  <!-- status: in-progress -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 2 > P2.2
- **Active scope:** P2.2 (Wrap callers with timeout handler) — mid-implementation
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries

## Mid-build realization (the trigger for F36)

While implementing P2.2 (wrapping callers with the timeout handler), I realized: I have been applying this fix and the verify-auto/verify-self steps for Phase 1 PASSed — but I never actually confirmed the bug exists. The original report was "occasionally we get two orders for the last unit" — no failing test was written, no reproduction was captured, no telemetry signature was recorded. My Phase 1 verify-codify only asserts that the lock IS acquired, not that the race ACTUALLY fires without it. If I ship this fix now, I cannot distinguish "the lock is preventing the bug" from "the bug was never reproducing in our environment to begin with."

This is exactly the F36 REDIRECT condition: I need to pause build, run /feature-reproduce to capture a pre-fix failing test (red-green discipline), then return to build with the artifact in hand. F36 was added to the workflow specifically for this case.
