# Bug: Single-tenant data export job hangs after ~30 minutes

**Workflow:** feature
**State:** build (Phase 1 — fix attempt)
**Created:** 2026-05-13

## Problem Statement
The nightly data-export job for tenant `acme-corp` hangs around the 30-minute mark and never completes. The job runs in a dedicated worker process; there is no other tenant on the same job-type with a comparable workload — `acme-corp` is the only customer using the bulk-export feature in production. We do not have a sibling job that exercises the same code path successfully.

## Investigation State

Straight-line debug attempts so far:
1. Increased the job timeout → job still hangs, just later
2. Added verbose logging around the export loop → logs stop mid-iteration with no error
3. Checked DB connection pool for exhaustion → all connections healthy at hang time
4. Ran the export query in isolation against a copy of acme-corp's data → query completes cleanly in ~12 seconds

No converging hypothesis. The hang appears only inside the worker process, not in isolated query execution.

## Known-good pair

**There is no known-good sibling path.** The bulk-export feature was built specifically for acme-corp; no other tenant or job-type exercises the same `BulkExportWorker.run_for_tenant()` entry point in production. The closest analogs are unrelated jobs (incremental sync, report-pdf-generation) that share only the worker-framework scaffolding, not the export logic.

## Next Step

Without a structurally similar working sibling to bisect from, the known-good-bisection technique cannot be applied. Other techniques worth considering: instrument the export loop with per-iteration timing; run the export under py-spy / strace; try the export against a smaller subset of acme-corp's data to narrow the hang window.
