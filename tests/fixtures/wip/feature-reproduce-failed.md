# Feature: Intermittent dashboard load failure

**Workflow:** feature
**State:** reproduce
**Created:** 2026-05-08
**Entry:** reproduce (bug-fix feature)

## Problem Statement
Users occasionally report the dashboard fails to load with a blank screen. Reported intermittently — no consistent reproducer. Browser console shows no errors when reproduced locally. Telemetry shows occasional 504 spikes from a downstream service.

## Reproduction Attempt
**Surface chosen:** failing test (attempted)
**Outcome:** could-not-reproduce
**Artifact:** Attempted to write a Playwright test exercising dashboard load 50 times — all 50 passed locally. Tried with throttled network (Slow 3G) and CPU throttling — all 50 still passed.
**Determinism:** could-not-reproduce locally
**Notes:** Bug appears tied to prod conditions (downstream service flakiness, real user data shape) that local testing cannot capture. Telemetry signature: HTTP 504 from `/api/dashboard/widgets` at p99 latency. Local repro is not feasible.
