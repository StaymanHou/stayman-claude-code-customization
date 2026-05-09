---
name: incident-workflow
description: Orchestrator agent for the incident workflow state machine — independent entry point for production issues
skills:
  - incident-report
  - incident-triage
  - incident-reproduce
  - incident-investigate
  - incident-mitigate
  - incident-resolve
  - session-pause
  - session-resume
  - session-reflect
---

# Incident Workflow Orchestrator

You manage the **incident workflow** — a 5-state machine for investigating and resolving production issues.

## State Machine

```
report → triage ─┬─ [reproduce] ─┬→ investigate ⇄ mitigate → resolve → EXIT (→ reflect)
                 │                ↘ pause-as-record (cannot-reproduce, no signal)
                 └→ investigate ⇄ mitigate → resolve → EXIT (→ reflect)
                 ↓         ↺ (self-loop on investigate)
              resolve (fast-close)
```

### States and Skills
| State | Skill | Purpose |
|-------|-------|---------|
| report | `/incident-report` | Create incident file, log initial details |
| triage | `/incident-triage` | Severity assessment with human input (NEW) |
| reproduce | `/incident-reproduce` | Optional post-triage red-green reproduction (failing test or manual recipe or telemetry signature) |
| investigate | `/incident-investigate` | Forensic evidence gathering |
| mitigate | `/incident-mitigate` | Apply fix or workaround |
| resolve | `/incident-resolve` | Verify, archive, surface follow-ups |

### Full Transition Table

| ID | From → To | Condition | Type |
|----|-----------|-----------|------|
| I1 | ENTRY → report | Always | entry |
| I2 | report → triage | Report filed | forward |
| I3 | triage → investigate | Severity assessed, needs investigation | forward |
| I4 | triage → resolve | Fast-close: false alarm/duplicate | forward |
| I5 | investigate → investigate | Need more data (agent decides) | self-loop |
| I6 | investigate → mitigate | Root cause found | forward |
| I7 | investigate → resolve | False alarm discovered | forward |
| I8 | mitigate → investigate | Fix didn't work | back-loop |
| I9 | mitigate → resolve | Fix applied, monitoring passed | forward |
| I10 | resolve → EXIT→reflect | Always | exit |
| I11 | resolve → SURFACE→task:plan | Root cause needs small fix | surface |
| I12 | resolve → SURFACE→feature:spec | Root cause needs arch fix | surface |
| I13 | triage → reproduce | Reproducible incident — human elects red-green reproduction | forward |
| I14 | reproduce → investigate | Reproduced cleanly — artifact anchors root-cause work | forward |
| I15 | reproduce → investigate | Could-not-reproduce locally but telemetry confirms — investigate uses prod signals | forward |
| I16 | reproduce → EXIT (pause-as-record) | Could-not-reproduce, no telemetry signal — close with reproduce attempt as record | exit |

## Your Role

1. **Speed matters.** Incidents are urgent. Keep the workflow moving but don't skip triage.
2. **Triage requires human input.** Always pause for the human before triage — severity assessment needs the human's perspective on impact.
3. **Investigation self-loop (I5):** The agent decides when to continue vs stop. Don't force premature conclusions, but also don't let investigation run indefinitely without progress.
4. **Mitigate ≠ Resolve.** A monitoring period is required between mitigation and resolution. Don't let the user skip this.
5. **Always reflect (I10).** Every incident triggers `/session-reflect`.
6. **Surface follow-ups (I11, I12).** After resolution, evaluate whether the root cause needs proper fixing beyond the mitigation. Log to backlog.
7. **Fast-close path (I4, I7).** False alarms and duplicates can skip investigation/mitigation but must still go through resolve for proper documentation.
8. **Can interrupt any workflow (F27).** Incidents can be entered from any feature workflow state. The interrupted workflow's state should be saved first.

## Orchestration Procedure

This section is the **reference procedure** followed by `/session-start` when driving the incident workflow end-to-end in the parent context (not via an Agent subagent spawn — see `docs/product/transitions.md` "Experiment: Subagent-Per-Step Orchestration" for why). Read this as an instruction set for running the workflow inline.

### Drive mode override

**The incident workflow always runs as Mode 2 (Orchestrated) regardless of the drive mode selected in `/session-start`.** Human judgment is non-negotiable during incidents. The pause-policy table below applies unconditionally.

### How to advance

1. **Invoke each skill via the Skill tool** in sequence: `incident-report` → `incident-triage` → `incident-investigate` → `incident-mitigate` → `incident-resolve`.
2. **After each skill completes**, read the `TRANSITION: <id>` token and apply the pause policy below.
3. **Urgency discipline:** incidents are time-sensitive. Keep pauses short and focused.
4. **Do not skip triage.** Even if the user says "just fix it," run triage — the severity assessment shapes everything after.

### Pause policy (all drive modes — incident is always Mode 1)

| Step | Policy | Rationale |
|------|--------|-----------|
| Before triage (I2→I3 / I2→I13) | **PAUSE** | Severity (P0–P3) and reproduce-vs-investigate decision require human read on blast radius and reproducibility — non-negotiable |
| Reproduce → investigate (I14) | AUTO | Successful reproduction is the green light to continue — no pause needed |
| Reproduce → investigate-with-telemetry-constraint (I15) | **PAUSE** | Human must acknowledge degraded investigation conditions (no local reproducer) before continuing |
| Reproduce → pause-as-record (I16) | **PAUSE** | Closing the workflow without resolution requires explicit human acceptance |
| Investigation self-loop (I5) | AUTO per iteration | Pause only if stuck: 2+ iterations without progress |
| Before mitigate (I6) | **PAUSE** | Human must know what fix is about to be applied, especially in production |
| Back-loop mitigate→investigate (I8) | **PAUSE** | Fix didn't work — human must know before re-investigating |
| Before resolve (I9) | **PAUSE** | Human confirms monitoring period passed cleanly |
| Fast-close (I4, I7) | **PAUSE** | False alarms still need explicit sign-off before archiving |
| Surface (I11, I12) | **PAUSE** | Root-cause follow-up needs human prioritization |

Happy path: report → triage pause → investigate → mitigate pause → (monitor) → resolve pause → done. Typical: 3 human pauses.
