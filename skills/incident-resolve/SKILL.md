---
name: incident-resolve
description: "Incident workflow: finalize the incident — verify resolution, archive, surface follow-up work"
argument-hint: <incident file name or ID>
---

# Incident Resolve

You are finalizing the incident lifecycle.

## State Machine Context

You are in the **incident** workflow at the **resolve** state.
This is the **terminal state** of the incident workflow.

**Valid transitions from here:**
- **I10 → EXIT + reflect:** Always auto-trigger reflect
- **I11 → SURFACE to task:plan:** Root cause needs a proper fix (small) — note-and-continue
- **I12 → SURFACE to feature:spec:** Root cause needs architectural fix (large) — note-and-continue

## Procedure

### 1. Verify Resolution
- Confirm with the user that the issue is fully fixed
- Ensure the incident was in `Monitoring` status with no regressions before closing
- If coming from fast-close (I4 or I7), confirm the reason

### 2. Data Correction (if needed)
- If the incident corrupted data, propose and execute a correction plan
- Get user confirmation before modifying production data

### 3. Finalize Report
- Clean up the incident report (formatting, timestamps)
- Ensure all sections are complete
- Update Status to `Resolved`

### 4. Archive
- Move the incident report to `workflow/archive/`
- Update any incident index if one exists

### 5. Surface Follow-Up Work
Evaluate whether the root cause needs a proper fix beyond the mitigation:

**Small fix needed (I11):**
Log to `workflow/backlog.md` targeting `task:plan`:
```markdown
## SURFACE-<timestamp>
- **Source:** incident:resolve
- **Target level:** task:plan
- **Type:** bug
- **Summary:** <proper fix needed for incident root cause>
- **Context:** <reference incident report>
- **Priority:** <based on severity>
- **Status:** pending
```

**Architectural fix needed (I12):**
Log to `workflow/backlog.md` targeting `feature:spec` with similar format.

### 6. Trigger Reflect
Incidents always trigger reflection:
- Tell user: "Incident resolved. Run `/session-reflect` to capture learnings from this incident."

**Incident:** {{args}}
