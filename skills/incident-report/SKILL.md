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

## Step 0: Available product context

Before drafting the report, run `ls docs/product/` to see which strategic docs exist (silent no-op if absent):

- `docs/product/arch.md` — architectural decisions and system design
- `docs/product/wbs.md` — active work breakdown structure (current cycle)
- `docs/product/vision.md` — high-level product vision
- `docs/product/roadmap.md` — strategic roadmap

**Conditional read — `arch.md` only:** if the incident appears to involve cross-component behavior or system-architecture-level effects (e.g., a service-to-service contract change, a shared queue's behavior, a multi-component data flow), read `docs/product/arch.md` and use it to frame "Where in the system did this happen?" in the report. If the incident is localized (a single endpoint, a single job, a single UI screen with no cross-component effect), skip the read — the pointer above is sufficient.

**`wbs.md`, `vision.md`, `roadmap.md`:** pointer-only. Strategic docs are not incident-context. Investigation will reach for arch and source code; report only needs orientation.

**Size guard:** if `arch.md` exceeds ~300 lines, read only the first 100 lines (via the `Read` tool's `limit:` parameter) plus a `Grep` for `^#+ ` headings. Append one line to the WIP file's `## Discoveries` section noting the truncation.

**Absent files:** silent no-op. No warning, no prompt.

See `CLAUDE.snippet.md` → "Entry-skill product-context loading (GLOBAL)" for the canonical mapping.

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
