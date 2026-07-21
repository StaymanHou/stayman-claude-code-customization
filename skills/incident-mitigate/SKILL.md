---
name: incident-mitigate
description: "Incident workflow: apply fixes or workarounds to restore service"
argument-hint: <incident file name or ID>
---

# Incident Mitigate

You are a Systems Engineer applying a fix based on the investigation findings.

## State Machine Context

You are in the **incident** workflow at the **mitigate** state.

**Valid transitions from here:**
- **I17 → codify (default):** Fix applied, monitoring period passed → tell user to run `/incident-codify` to lock regression coverage before resolve
- **I9 → resolve (skip-codify defer path):** Fix applied, monitoring passed, but codify is being explicitly deferred (e.g., active P0 where writing coverage now would delay all-clear). Requires: human-written `## Codify — Deferred` reasoning in the WIP file AND a SURFACE→task:plan entry in `workflow-system/state/backlog.md` to own the coverage debt. Then tell user to run `/incident-resolve`
- **I8 → investigate (back-loop):** Fix didn't work, need more data → document what failed, tell user to run `/incident-investigate`

## Procedure

### 1. Load Context
- Read the incident report, focusing on Root Cause and Resolution Plan
- Understand what was investigated and confirmed

### 2. Plan Fix
- Propose the code change, config change, or workaround
- Get user confirmation before applying if the fix has significant risk

### 3. Implement
- Apply the fix using standard development tools
- Respect Docker rules and deployment workflows from the project `CLAUDE.md`
- Make changes atomic and reversible where possible

### 4. Verify
- Confirm the immediate issue is resolved
- Check for regression risks
- Run relevant tests

### 5. Update Report
- Add mitigation details to the incident file
- Update Status to `Monitoring`
- **Do NOT mark as Resolved yet** — a monitoring period is required

### 6. Evaluate Outcome

**Fix works — default path (I17):**
- Note the monitoring start time
- Tell user: "Fix applied and verified. Monitor for stability, then run `/incident-codify` to lock regression coverage before resolve."

**Fix works — defer-codify path (I9, exceptional):**
- Only use when active incident pressure makes writing coverage now infeasible (P0 with customer escalation, etc.)
- Write a `## Codify — Deferred` section to the WIP file with: reasoning, severity at defer time, and what makes you confident the bug is gone without a regression test
- Append a `SURFACE-<YYYY-MM-DD>-CODIFY-DEFERRED-<incident-name>` entry to `workflow-system/state/backlog.md` targeting `task:plan`
- Tell user: "Fix applied. Codify deferred — see WIP file for reasoning and SURFACE entry. Run `/incident-resolve` to close."

**Fix didn't work (I8):**
- Document what was tried and why it failed
- Revert if appropriate
- Tell user to run `/incident-investigate` for further analysis

**Incident:** {{args}}
