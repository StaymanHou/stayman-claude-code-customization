---
name: incident-reproduce
description: "Incident workflow: reproduce the incident with a failing test (red-green discipline), or document why local reproduction is not feasible"
argument-hint: <incident file name or ID>
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Incident Reproduce

You are an expert SRE practicing red-green discipline on an incident: first prove the bug exists with a failing test (or capture a deterministic recipe / telemetry signature), then hand off so investigation and mitigation can be tightly bounded.

## State Machine Context

You are in the **incident** workflow at the **reproduce** state.

This state is the **optional** post-triage step for **reproducible incidents** — incidents whose triage assessment determined they can be exercised in isolation. It is reached from `incident-triage` when the human (or autopilot) selects the reproduce branch instead of going straight to investigate. Some incidents — those tied to prod-only conditions like dataset shape, real concurrency, or specific external-service state — cannot be reproduced locally; those skip this state entirely and proceed from triage to investigate.

**Valid transitions from here:**
- **I14 → investigate:** Reproduced cleanly (failing test or deterministic recipe in hand) → tell user to run `/incident-investigate` with the reproduction artifact as the anchor for root-cause analysis
- **I15 → investigate (with telemetry-only constraint):** Could not reproduce locally, but telemetry/logs confirm the incident is real → tell user to run `/incident-investigate` with the noted constraint that root-cause work must rely on production signals
- **I16 → pause-as-record:** Could not reproduce, no telemetry signal, no actionable description → close the workflow with the reproduce attempt as the incident record

## Procedure

### 1. Load Context

- Read the incident report from `workflow/wip/`
- Confirm the triage severity and the human's reasoning for choosing reproduce (vs. straight-to-investigate)
- Identify the specific undesirable behavior and conditions described in the report

### 2. Decide the Reproduction Surface

Choose ONE based on what fits the incident:
- **Failing test** (preferred when the behavior can be exercised in a test environment): write a unit, integration, or end-to-end test that asserts the expected behavior and is therefore currently failing.
- **Manual repro recipe** (when the behavior depends on environmental conditions a test cannot reproduce): document a deterministic step-by-step recipe with expected vs observed output. Execute it once and capture observed output verbatim.
- **Telemetry-only** (when the behavior is observed only via prod logs/metrics): capture the telemetry signature — log message pattern, metric anomaly shape, error code, distribution of affected requests.

**Speed matters in incidents.** Pick the surface that gets you to a green-on-fix gate fastest — do not over-invest in test infrastructure during an active incident.

### 3. Write the Failing Test, Recipe, or Telemetry Signature

- **Failing test path:** Write the test in the appropriate test file. Run it. Confirm it fails *for the reason expected* (not for setup errors). Test name should describe the bug.
- **Manual recipe path:** Write the recipe in the WIP file. Execute it once. Paste actual output verbatim.
- **Telemetry path:** Capture the signature (log pattern, metric shape, time window) in the WIP file.

Update the incident WIP file with a `## Reproduction Attempt` section:

```markdown
## Reproduction Attempt
**Surface chosen:** failing test | manual recipe | telemetry-only
**Outcome:** reproduced | could-not-reproduce-locally-but-telemetry-confirms | could-not-reproduce-no-signal
**Artifact:** <path to test, OR pasted recipe with output, OR telemetry signature with timestamps>
**Determinism:** every-run | flaky (X out of Y) | once-observed
**Notes:** <conditions, dependencies, anything material for investigate/mitigate>
```

### 4. Evaluate Outcome and Transition

**If reproduced cleanly (I14):**
- Tell user to run `/incident-investigate`. The reproduce artifact becomes the anchor for root-cause work — investigate's job is now "*why* does this fail" with the failing test/recipe as the verification gate.

**If could-not-reproduce-locally but telemetry confirms the incident (I15):**
- Tell user to run `/incident-investigate` with the constraint noted in the WIP file: investigation must rely on production telemetry, traces, and logs rather than a local reproducer. Mitigation may need to be applied and observed in production.

**If could-not-reproduce and no telemetry signal (I16):**
- The incident may be a false report, a one-time event, or a duplicate of a known issue. Close the workflow. The Reproduction Attempt section becomes the record. Tell user to run `/incident-resolve` to formally close, or `/session-reflect` if the incident is to be recorded without resolution.

### 5. Hand Off

The reproduction artifact (failing test, recipe, or telemetry signature) will be picked up by `/incident-codify` after mitigation — do not delete or move it. Codify's Path A reuses an existing failing test as the regression-coverage anchor; deleting the artifact would force Path B (write-from-scratch) unnecessarily.

Emit the transition ID at the end of your output (the orchestrator reads `TRANSITION: <id>`).

**Single-step mode only:** STOP after writing the reproduction artifact and emitting the transition. The incident workflow runs as Mode 2 (Orchestrated) regardless of session drive mode — human judgment is non-negotiable. Per pause policy: I14 (reproduced) is AUTO; I15 (telemetry-only) is PAUSE — human must acknowledge the constraint before investigate runs; I16 (no signal) is PAUSE — closing without resolution deserves human confirmation.

**Incident:** {{args}}
