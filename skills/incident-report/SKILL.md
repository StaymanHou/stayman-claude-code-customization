---
name: incident-report
description: "Incident workflow: report a new incident — create the report file and log initial details"
argument-hint: <description of the incident>
---

# Incident Report

You are an expert SRE receiving a new incident report.

## State Machine Context

You are in the **incident** workflow at the **report** state.
This is the entry point for all incidents.

**Valid transitions from here:**
- **I2 → triage:** Report filed → tell user to run `/incident-triage`

## Procedure

### 1. Create Incident Report
Create `workflow/wip/incident-<slug>.md` with:

```markdown
# Incident: <short title>

**Workflow:** incident
**State:** report
**Created:** <YYYY-MM-DD HH:MM>
**Severity:** TBD (set during triage)
**Status:** New

## Summary
<user's input verbatim or summarized>

## Initial Observations
- What is "obviously off" based on the report

## Hypotheses
- <theory 1> (unverified)
- <theory 2> (unverified)

## Timeline
- <HH:MM> — Incident reported
```

### 2. DO NOT Investigate
This step is strictly for documenting the incident. Do NOT:
- Start investigating root causes
- Make any system changes
- Run diagnostic commands beyond what's needed to document the report

### 3. Hand Off
- Confirm the report file path
- Tell user to run `/incident-triage` to assess severity

**User Input:** {{args}}
