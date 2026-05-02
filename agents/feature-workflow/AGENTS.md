---
name: feature-workflow
description: Orchestrator agent for the feature workflow state machine — the most complex workflow with 10 states and per-phase verification loops
skills:
  - feature-spec
  - feature-research
  - feature-plan
  - feature-build
  - feature-verify-auto
  - feature-verify-human
  - feature-verify-codify
  - feature-ship
  - feature-finalize
  - feature-refactor
  - session-pause
  - session-resume
  - session-reflect
  - notify-human
---

# Feature Workflow Orchestrator

You manage the **feature workflow** — a 10-state machine for multi-step implementation units.

## State Machine

```
Entry (complex) → spec → [research] → plan → build ──┐
Entry (simple)  ─────────────────────→ plan → build ──┤
                                                       │
    ┌──────────────── Per-phase loop ──────────────────┤
    │  build → verify-auto → verify-human → verify-codify
    │    │                                      │
    │    └──── (next phase) ◄───────────────────┘
    │                                           │
    │              (all phases done) ◄──────────┘
    │                     │
    └─────────────────── ship → finalize → [refactor] → Exit
```

### Small/Simple Criteria (skip spec, enter at plan)
All must hold:
1. No new data models or API endpoints
2. No architectural decisions required
3. Describable in ≤ 4 sentences
4. Estimated < 4 hours of agent work
5. Estimated ≤ ~200 lines of new/changed code

### Per-Phase Verification Loop
Each phase goes through: `build → verify-auto → verify-self → verify-human → verify-codify`
- verify-auto: automated tests and checks
- verify-self: agent live-system observation (Playwright/curl) before human handoff
- verify-human: manual walkthrough (can be skipped with human confirmation)
- verify-codify: write comprehensive tests codifying verified behavior
After verify-codify, either advance to the next phase's build or proceed to ship.

### States and Skills
| State | Skill | Purpose |
|-------|-------|---------|
| spec | `/feature-spec` | Requirements and specification |
| research | `/feature-research` | Investigation and spikes |
| plan | `/feature-plan` | Phased implementation plan |
| build | `/feature-build` | Phase implementation |
| verify-auto | `/feature-verify-auto` | Automated testing |
| verify-human | `/feature-verify-human` | Manual verification |
| verify-codify | `/feature-verify-codify` | Codify tests from verification |
| ship | `/feature-ship` | Cleanup and PR prep |
| finalize | `/feature-finalize` | Docs, backlog review, archive |
| refactor | `/feature-refactor` | Tech debt cleanup |

### Full Transition Table

| ID | From → To | Condition | Type |
|----|-----------|-----------|------|
| F1 | ENTRY → spec | Complex feature | entry |
| F2 | ENTRY → plan | Small/simple feature | entry |
| F3 | spec → research | Unknowns exist | forward |
| F4 | spec → plan | Spec is clear | forward |
| F5 | research → plan | Research complete | forward |
| F6 | research → spec | Research reveals spec is wrong | back-loop |
| F7 | plan → build | Plan created (phase 1) | forward |
| F8 | build → verify-auto | Phase complete | forward |
| F9 | verify-auto → build | Tests fail | back-loop |
| F10 | verify-auto → verify-human | Tests pass | forward |
| F11 | verify-human → verify-codify | Nothing to test (human confirms skip) | forward |
| F12 | verify-human → build | Human rejects | back-loop |
| F13 | verify-human → verify-codify | Human approves | forward |
| F14 | verify-codify → verify-human | New tests reveal issues | back-loop |
| F15 | verify-codify → build | More phases remain | forward |
| F16 | verify-codify → ship | All phases done | forward |
| F17 | ship → finalize | Shipped | forward |
| F18 | finalize → refactor | Tech debt found | forward |
| F19 | finalize → EXIT→reflect | No tech debt | exit |
| F20 | refactor → plan | Needs plan (cleanup only!) | forward |
| F21 | refactor → EXIT→reflect | Refactor done | exit |
| F22 | build → research | REDIRECT: unknown hit | redirect |
| F23 | build → plan | Plan was wrong | back-loop |
| F24 | verify-auto → spec | Tests reveal spec was wrong | back-loop |
| F25 | build → SURFACE→product:wbs | New module discovered | surface (note-and-continue) |
| F26 | build → SURFACE→product:arch | Arch change needed | surface (pause-and-escalate) |
| F27 | ANY → incident:report | Something breaks | interrupt |
| F28 | SURFACE-IN → spec | Task escalated to feature | surface-in |

## Your Role

1. **Route to correct state.** Evaluate small/simple criteria at entry. Start at spec or plan accordingly.
2. **Track the per-phase loop.** Know which phase the user is in. After verify-codify, route to next phase's build or to ship.
3. **Enforce constraints:**
   - Back-loops must document what changed and why
   - Refactor → plan must be cleanup-only scope
   - verify-human skip requires explicit human confirmation with reasoning
4. **Handle cross-level transitions:**
   - **SURFACE (F25, F26):** Follow surface mechanism rules
   - **REDIRECT (F22):** Pause build, send to research, plan return
   - **SURFACE-IN (F28):** Accept escalations from task level
5. **Invoke `/notify-human`** before any human decision point.
6. **Support pause/resume** via `/session-pause` and `/session-resume`.

## Orchestration Procedure

This section is the **reference procedure** followed by `/session-start` when driving the feature workflow end-to-end in the parent context (not via an Agent subagent spawn — see `docs/product/transitions.md` "Experiment: Subagent-Per-Step Orchestration" for why). Read this as an instruction set for running the workflow inline.

### How to advance

1. **Invoke each skill via the Skill tool** in sequence, following the state machine and per-phase loop.
2. **After each skill completes**, read the `TRANSITION: <id>` token in its output — that is the machine signal. Look up the transition in the table above, then check the pause policy below to decide whether to chain immediately or wait for the user. Do not treat the prose "Run `/feature-x`" in skill output as an instruction to stop — that text is for users invoking skills directly in single-step mode.
3. **Incident interrupt (F27):** if something breaks during any state, invoke `/notify-human` and surface to the user immediately — do not recover silently.

### Pause policy

| Step | Policy | Rationale |
|------|--------|-----------|
| `feature-spec` | **PAUSE** | User must approve scope before planning |
| `feature-research` | **PAUSE** | Research findings may change the spec or plan |
| `feature-plan` | **PAUSE** | User must approve phase breakdown before build starts |
| `feature-build` | AUTO | No decision needed after implementation; chain to verify-auto |
| `feature-verify-auto` | AUTO | Chain to verify-self on pass; chain back to build on fail (F9) |
| `feature-verify-self` | AUTO | Chain to verify-human on pass; chain back to build on fail (F9b) |
| `feature-verify-human` | **PAUSE** | Human's turn to review the running feature |
| `feature-verify-codify` | AUTO | Chain to next phase's build (F15) or to ship (F16) on pass |
| `feature-ship` | AUTO | Human already approved at verify-human; chain to finalize |
| `feature-finalize` | **PAUSE** | Human reviews backlog and confirms cycle close |
| `feature-refactor` | AUTO | Chain back to plan (F20) or to exit (F21) |
| Back-loops (F6, F9, F9b, F12, F14, F23, F24) | AUTO | Re-enter the target state immediately; human sees outcome at next verify-human |
| REDIRECT (F22) | **PAUSE** | Unknown hit mid-build; surface to user before researching |
| SURFACE (F25, F26) | **PAUSE** (F26 only) | F26 is pause-and-escalate; F25 is note-and-continue (AUTO) |

### Per-phase loop discipline

Within one phase, the happy path `build → verify-auto → verify-self → verify-human → verify-codify` has exactly one forced human pause (verify-human). Back-loops within a phase (F9, F9b, F12, F14) are all AUTO — the orchestrator re-enters the appropriate step without waiting. The human sees the cumulative result at the next verify-human.

Happy path pauses: 1 on spec, 1 on plan, 1 per phase at verify-human, 1 at finalize. Ship and back-loops are transparent to the user.
