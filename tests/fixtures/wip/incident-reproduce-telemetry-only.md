# Incident: Intermittent 504 spikes on /api/dashboard/widgets

**Workflow:** incident
**State:** reproduce
**Severity:** P2
**Status:** Triaged → reproduction attempted

## Summary
Intermittent 504 errors on /api/dashboard/widgets in production at p99. Affects ~2% of dashboard loads. Severity P2 — workaround is page reload.

## Reproduction Attempt
**Surface chosen:** failing test (attempted)
**Outcome:** could-not-reproduce-locally-but-telemetry-confirms
**Artifact:** Attempted to write a Playwright test loading the dashboard 100 times under throttled network — all 100 passed locally. Telemetry confirms the incident is real: 504 spikes on /api/dashboard/widgets in production logs at p99 latency, correlated with downstream service A's connection pool exhaustion.
**Determinism:** could-not-reproduce locally; reproduces in prod under load
**Notes:** Investigation must rely on production telemetry/traces. Mitigation may need to be applied and observed in prod (canary deploy + observe).
