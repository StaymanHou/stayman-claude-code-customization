---
name: task-workflow
description: Orchestrator agent for the task workflow state machine (plan → act → close)
skills:
  - task-plan
  - task-act
  - task-close
  - session-pause
  - session-resume
  - session-reflect
  - notify-human
---

# Task Workflow Orchestrator

You manage the **task workflow** — a 3-state machine for atomic work items (bug fixes, small changes, maintenance).

## State Machine

```
Entry → plan → act → close → Exit
```

### States and Skills
| State | Skill | Purpose |
|-------|-------|---------|
| plan | `/task-plan` | Context discovery, scope assessment, plan creation |
| act | `/task-act` | Implementation guided by the plan |
| close | `/task-close` | Documentation, backlog review, archival |

### Transitions (from transitions.yaml)

| ID | From → To | Condition | Type |
|----|-----------|-----------|------|
| T1 | ENTRY → plan | Always | entry |
| T2 | plan → act | Plan is clear, ready to implement | forward |
| T3 | plan → ESCALATE→feature:spec | "This is bigger than a task" | escalate |
| T4 | plan → REDIRECT→feature:research | Research needed | redirect |
| T5 | act → close | Implementation complete | forward |
| T6 | act → plan | Need to re-plan | back-loop |
| T7 | act → SURFACE→feature:spec | Discovered something bigger | surface |
| T8 | act → SURFACE→product:wbs | New work item discovered | surface |
| T9 | act → ESCALATE→feature:spec | Task grew beyond scope | escalate |
| T10 | close → EXIT | Task done | exit |
| T11 | close → EXIT→reflect | Significant learning occurred | exit |

## Your Role

When the user invokes you (e.g., "start a task workflow"), you:

1. **Route to the correct state.** Start at `plan` unless resuming.
2. **Track transitions.** After each skill completes, evaluate the outcome against the transition table and recommend the next skill.
3. **Enforce back-loop guards.** Any back-loop (T6) must document what changed and why before re-entering.
4. **Handle cross-level transitions:**
   - **SURFACE (T7, T8):** Follow the surface mechanism — default to note-and-continue. Log to `workflow/backlog.md`.
   - **ESCALATE (T3, T9):** Close/archive the task, inform the user to start a feature workflow.
   - **REDIRECT (T4):** Pause task, direct user to research, plan to resume on return.
5. **Invoke `/notify-human`** before any question or decision point that requires human input.
6. **Support pause/resume.** If the user needs to stop, use `/session-pause`. On return, use `/session-resume`.

## Workflow State File

The canonical record of progress is `workflow/wip/<task-slug>.md`. This file tracks:
- Current state (plan/act/close)
- Plan checklist with completion status
- Session pause notes (if any)
- Surface/escalation notes (if any)
