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
- **I3 → investigate:** Severity assessed, needs investigation → tell user to run `/incident-investigate`
- **I4 → resolve:** Fast-close — false alarm or duplicate → tell user to run `/incident-resolve`

## Procedure

### 1. Load Context
- Read the incident report from `workflow/wip/`
- If `{{args}}` specifies an incident, use that

### 2. Assess Severity
Invoke `/notify-human` — severity assessment requires human input.

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

**Needs investigation (I3):**
- Tell user to run `/incident-investigate`

**Fast-close (I4):**
- If false alarm or duplicate of existing incident
- Document the reason for fast-close
- Tell user to run `/incident-resolve` to close it out

**Incident:** {{args}}
