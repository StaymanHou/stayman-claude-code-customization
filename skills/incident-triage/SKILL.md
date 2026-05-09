---
name: incident-triage
description: "Incident workflow (NEW): assess severity, determine impact, and decide investigation vs fast-close"
argument-hint: <incident file name or ID>
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Incident Triage

You are an expert SRE triaging an incident to determine its severity and next steps.

## State Machine Context

You are in the **incident** workflow at the **triage** state.
This is a **new state** not present in the original Gemini workflow — added to ensure severity assessment before investigation.

**Valid transitions from here:**
- **I3 → investigate:** Severity assessed, needs investigation, NOT reproducible locally (prod-data-only or telemetry-only) → tell user to run `/incident-investigate`
- **I13 → reproduce:** Severity assessed, incident IS reproducible locally → tell user to run `/incident-reproduce` for red-green discipline before investigation
- **I4 → resolve:** Fast-close — false alarm or duplicate → tell user to run `/incident-resolve`

**Decision rule for I3 vs I13:** After severity is assessed, ask the human (or evaluate from the report): *can this incident be exercised in a test environment, or with a deterministic local recipe?* If yes → I13 (reproduce first; the failing test or recipe becomes the anchor for investigation and the regression gate for mitigation). If no — incidents tied to prod data shape, real concurrency, external service state, or telemetry-only signals — go to I3 (investigate directly using prod signals). Reproduce is optional; defaulting to I3 is always valid when reproducibility is unclear.

## Procedure

### 1. Load Context
- Read the incident report from `workflow/wip/`
- If `{{args}}` specifies an incident, use that

### 2. Assess Severity
Severity assessment requires human input — pause for the user (the harness's Notification hook will alert them via Telegram automatically).

Present the incident summary and ask the human to assess impact:

**Severity Levels:**
| Level | Description | Response |
|-------|-------------|----------|
| **P0** | Service down, data loss, security breach | Drop everything |
| **P1** | Major feature broken, many users affected | Investigate immediately |
| **P2** | Minor feature broken, workaround exists | Investigate when possible |
| **P3** | Cosmetic, edge case, low impact | Schedule fix |

Ask the human:
- What is the user-facing impact?
- How many users/systems are affected?
- Is there a workaround?
- Is this a duplicate of a known issue?

### 3. Record Assessment
Update the incident report:
- Set **Severity** to the agreed level
- Update **Status** to `Triaged`
- Add impact assessment notes

### 4. Evaluate Next Step

**Needs investigation, reproducible locally (I13):**
- Tell user to run `/incident-reproduce` to capture a failing test, deterministic recipe, or telemetry signature before investigating

**Needs investigation, NOT reproducible locally (I3):**
- Tell user to run `/incident-investigate` — investigation will rely on prod signals (telemetry, traces, logs)

**Fast-close (I4):**
- If false alarm or duplicate of existing incident
- Document the reason for fast-close
- Tell user to run `/incident-resolve` to close it out

**Incident:** {{args}}
