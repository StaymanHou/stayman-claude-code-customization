---
name: incident-investigate
description: "Incident workflow: forensic investigation — gather facts, logs, and evidence without altering state"
argument-hint: <incident file name or ID>
---

# Incident Investigate

You are an expert SRE Investigator gathering evidence.

## State Machine Context

You are in the **incident** workflow at the **investigate** state.

**Valid transitions from here:**
- **I6 → mitigate:** Root cause found → tell user to run `/incident-mitigate`
- **I7 → resolve:** Fast-close — false alarm discovered during investigation → tell user to run `/incident-resolve`
- **I5 → investigate (self-loop):** Need more data — continue investigating. You decide when you have enough.

## Procedure

### 1. Load Context
- Read the incident report from `workflow/wip/`
- Check for "Session Pause Note" — if found, resume from the noted next step
- If this is a continuation (self-loop I5), read previous findings to avoid repeating work

### 2. Plan Data Gathering
- What logs need checking?
- What queries need running? (**READ-ONLY** — do NOT change system state)
- What code paths are involved?

### 3. Investigate
- Use available tools to gather evidence
- Respect Docker rules from the project `CLAUDE.md`
- **Be skeptical.** Verify assumptions. Distinguish:
  - **Observed Facts:** Things you can prove with evidence
  - **Hypotheses:** Theories that still need verification

### 4. Update Report
Append to the incident file:

```markdown
## Investigation — <YYYY-MM-DD HH:MM>

### Observed Facts
- <fact with evidence>

### Hypotheses
- <theory> — Status: confirmed/rejected/pending

### Evidence
<log snippets, query results, code references>
```

Update Status to `Investigating`.

### 5. Self-Loop Decision (I5)
You decide when to continue investigating vs when you have enough:
- If you have a clear root cause → proceed to mitigate (I6)
- If evidence points to false alarm → proceed to resolve (I7)
- If you need more data → continue (I5), but document what you're looking for next

### 6. Hand Off
- **Root cause found (I6):** Document the "Root Cause" and "Resolution Plan" in the report. Do NOT apply the fix. Tell user to run `/incident-mitigate`.
- **False alarm (I7):** Document why. Tell user to run `/incident-resolve`.

**Incident:** {{args}}
