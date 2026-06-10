# Bug: Worker `processQueue()` sometimes processes the same job twice

**Workflow:** feature
**State:** build (Phase 2 — fix attempt)
**Created:** 2026-06-10

## Problem Statement
The background worker `processQueue()` occasionally processes the same job ID twice — duplicate side effects appear in downstream systems (charges billed twice, emails sent twice). The failure is rare: about 1 in 30 runs against the same workload. The dequeue logic uses an `UPDATE ... RETURNING ... WHERE locked_at IS NULL` pattern that should be atomic, and reading the SQL there shows nothing obviously wrong.

## Investigation State

Straight-line debug attempts so far (3 — all failed to converge on a cause):
1. Read the dequeue query carefully — confirmed it uses `UPDATE ... RETURNING ... WHERE locked_at IS NULL FOR UPDATE SKIP LOCKED`. Looks correctly atomic on paper.
2. Read the `release_lock()` path — confirmed it sets `locked_at = NULL` only after the job's side-effect handler returns. Looks correct.
3. Stared at the surrounding queue-worker loop for half an hour — couldn't see any obvious re-enqueue or release-before-handle path.

No converging hypothesis. The race is not visible in static reading of the code.

## Bug-shape

The bug appears to be a **timing/race condition** that only manifests under concurrent worker processes hitting the same queue table. The static-readable code looks correct; the actual interleaving of two workers' transactions against the same row at the boundary of `release_lock()` and the next dequeue is not derivable from reading either function in isolation.

Specifically, the cause cannot be found by reading the code alone — it requires observing what each worker thread is doing at the moment a duplicate fires: which transaction holds which lock, when `locked_at` is being cleared relative to when the side-effect handler commits, and whether two workers can both see the row as available between those moments.

## Next Step

This matches the empirical-telemetry trigger profile:
- **Gate 1 — straight-line debug stalled:** 3 failed static-reasoning attempts, no converging hypothesis.
- **Gate 2 — bug-shape requires runtime evidence:** timing/race condition; cannot be derived by reading the code.

Consider `/debug-empirical-telemetry` to instrument the dequeue/release boundary with per-transaction timing + worker-ID logging, then run under load to capture the actual interleaving.
