# Bug: Worker `processQueue()` sometimes processes the same job twice (3 telemetry rounds exhausted)

**Workflow:** feature
**State:** build (Phase 2 — fix attempt; debug-empirical-telemetry on round 4)
**Created:** 2026-06-10

## Problem Statement
The background worker `processQueue()` occasionally processes the same job ID twice — duplicate side effects appear in downstream systems. The failure is rare (~1 in 30 runs). Static-reasoning attempts and 3 prior rounds of empirical telemetry have NOT located a cause. The discriminating-observable space appears exhausted.

## Static-Reasoning State (pre-telemetry)

Three static-reasoning attempts were made and recorded; none converged on a cause. Summary: dequeue uses `UPDATE ... RETURNING ... WHERE locked_at IS NULL FOR UPDATE SKIP LOCKED` (looks atomic on paper); release_lock clears `locked_at` only after the side-effect handler returns; queue-worker loop reads correctly. The race is not visible in static reading.

The empirical-telemetry gates BOTH held cleanly:
- Gate 1 — straight-line debug stalled: 3 failed static attempts, no converging hypothesis
- Gate 2 — bug-shape requires runtime evidence: timing/race condition; cannot be derived from reading the code

## Telemetry Rounds Already Run (3 rounds — all inconclusive)

### Round 1 — Instrumented the dequeue/release boundary

**Hypothesis:** Two workers race on the `locked_at IS NULL` predicate when the row is briefly readable between transaction commit boundaries.

**Smallest discriminating observable:** Worker ID + transaction timestamp at the moment of each dequeue, captured for 1000 jobs under concurrent load.

**Observation:** Captured 1037 dequeue events across 4 workers. No two workers ever showed overlapping dequeue timestamps for the same job ID. The SKIP LOCKED clause appears to be doing its job at the SQL level. Duplicate still fired twice during the run, but the dequeue telemetry showed each duplicate-job dequeue happening only ONCE.

**Discriminates which hypothesis?** H1 ruled out — the race is not at dequeue.

### Round 2 — Instrumented `release_lock()` ordering vs side-effect handler return

**Hypothesis:** The side-effect handler is being invoked twice within a single worker after release_lock fires too early. Possibly an async/await ordering bug in the side-effect callback chain.

**Smallest discriminating observable:** Wrap the side-effect handler in a per-invocation UUID + timestamp log; wrap `release_lock` in a matching log; observe the interleaving for duplicate jobs.

**Observation:** Captured 50 duplicate events across 6 hours of load. In every case, the side-effect handler was invoked EXACTLY ONCE per dequeue. release_lock fires AFTER the handler returns, never before. The handler's per-invocation UUID was unique on every call. The duplicate manifests AFTER both invocations have completed — the row appears in the side-effect downstream system twice with two distinct UUIDs.

**Discriminates which hypothesis?** H2 ruled out — the handler is not double-invoked within a single worker.

### Round 3 — Instrumented the downstream side-effect sink

**Hypothesis:** The duplicate is happening at the downstream sink (the billing/email service), not at the worker. Maybe an at-least-once delivery from the message bus between worker and sink.

**Smallest discriminating observable:** Capture the full request payload + worker UUID at the worker→sink boundary, and the full received payload + dedupe-key at the sink. Correlate by dedupe-key.

**Observation:** Captured 12 duplicate events at the sink during a 4-hour load run. Every duplicate has TWO distinct worker UUIDs and TWO distinct dequeue timestamps separated by 15-30 minutes. The sink is receiving them legitimately as two different events. The duplicate is NOT a sink-side replay.

**Discriminates which hypothesis?** H3 ruled out — the sink correctly dedupes within its own scope; the worker is genuinely emitting twice from two distinct dequeues separated by time.

## Where We Are Now

After 3 rounds, all 3 initial hypotheses are ruled out:
- NOT a dequeue race
- NOT a per-worker handler double-invocation
- NOT a sink-side replay

The observable telemetry shows the same job ID being legitimately dequeued TWICE by TWO distinct workers separated by 15-30 minutes — but the dequeue protocol's SKIP LOCKED clause is preventing concurrent access. The cause must lie in some path that allows a job's `locked_at` to be NULL again after a successful side-effect — but the release_lock code path is the only path that sets `locked_at = NULL`, and the round-2 telemetry showed it firing ONLY ONCE per dequeue.

The discriminating-observable space is exhausted for the current hypothesis set. Each round's observation was discriminating (it ruled out a hypothesis) but did not localize the cause. The cost-to-signal ratio is now poor for further telemetry rounds — the visible observables have been instrumented.

This is the **inconclusive** outcome documented in `debug-empirical-telemetry/SKILL.md` §7. The procedure recommends ending telemetry, running cleanup, and surfacing alternatives.

## Next Step

Per the SKILL.md inconclusive escalation procedure:
- Acknowledge that empirical telemetry has not converged after 3 rounds
- Run §6 Cleanup steps anyway (instrumentation should not be left behind on any exit)
- Emit `TRANSITION: DEBUG-TELEMETRY-INCONCLUSIVE` with `RETURN-TO: feature-build`
- Suggest alternatives (e.g., git bisect across recent changes to the queue worker; reproduce in isolated environment with debugger attached; check for external triggers like cron jobs or admin re-queue endpoints that bypass the lock)
- Log a SURFACE entry to `workflow/backlog.md`

**Do not run a fourth telemetry round.** The signal-to-cost ratio has tipped. The bug exists but the available observables do not discriminate further.
