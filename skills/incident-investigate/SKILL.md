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

### 3b. Debug-technique Sidebar (optional)

If straight-line investigation has stalled (≥3 self-loop iterations without converging on a root cause, or repeated hypothesis-rejected cycles) AND a structurally similar known-good path exists in the same environment (e.g. a working customer/tenant/region exhibiting the same workload), consider invoking `/debug-bisect-known-good` as a sidebar before continuing. The sidebar runs to completion, emits a `RETURN-TO: incident-investigate` token, and resumes this state with the cause in hand. This is a same-state round-trip — no new transition ID.

If instead the incident-shape demands runtime evidence (timing/race, intermittent failure, DB query plan or timing, perf regression, env-dependent state, "wrong value at this line in production") and static reasoning across the available logs and code has stalled, consider `/debug-empirical-telemetry` as the sidebar. It walks the agent through smallest-discriminating-observable → instrument → run → read → cleanup, and emits a `RETURN-TO: incident-investigate` token on completion. Same same-state round-trip discipline — no transition ID. See `agents/incident-workflow/AGENTS.md` → "Debug techniques (agent-pulled sidebars)" for the full list.

If instead the incident centers on a **behavioral** symptom (a drag/click/focus/keyboard interaction, a CLI under real argv/stdin, an HTTP endpoint under a real client, a race under real concurrency) and you've **handed a candidate fix back untested ≥2 times** on the same behavior, AND that behavior is drivable in a surface you control — even when production runs in a native/closed shell you can't attach to, the same DOM/CLI/HTTP logic usually runs in a browser/process you *can* drive — consider `/debug-minimal-harness`. It has you build a minimal standalone reproduction and drive it yourself with **real input** (`page.mouse`, real argv, a real request) rather than synthetic dispatch, until the behavior is understood, before re-presenting. Emits a `RETURN-TO: incident-investigate` token on completion. Same same-state round-trip discipline — no transition ID.

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
