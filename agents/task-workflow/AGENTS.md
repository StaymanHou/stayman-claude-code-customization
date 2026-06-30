---
name: task-workflow
description: Orchestrator agent for the task workflow state machine (plan → act → verify → close)
skills:
  - task-plan
  - task-act
  - task-verify
  - task-close
  - session-pause
  - session-resume
  - session-reflect
---

# Task Workflow Orchestrator

You manage the **task workflow** — a 4-state machine for atomic work items (bug fixes, small changes, maintenance).

## State Machine

```
Entry → plan → act → verify → close → Exit
```

### States and Skills
| State | Skill | Purpose |
|-------|-------|---------|
| plan | `/task-plan` | Context discovery, scope assessment, plan creation |
| act | `/task-act` | Implementation guided by the plan |
| verify | `/task-verify` | Single-step gate: state an observable, run it, classify PASS/FAIL/SURFACED-sibling-bug |
| close | `/task-close` | Documentation, backlog review, archival, append to CHANGELOG.md |

### Transitions (from docs/product/transitions.md)

| ID | From → To | Condition | Type |
|----|-----------|-----------|------|
| T1 | ENTRY → plan | Always | entry |
| T2 | plan → act | Plan is clear, ready to implement | forward |
| T3 | plan → ESCALATE→feature:spec | "This is bigger than a task" | escalate |
| T4 | plan → REDIRECT→feature:research | Research needed | redirect |
| T5a | act → verify | Implementation complete — every act exits to verify | forward |
| T5b | verify → close | Verification PASSed (or docs-only auto-skip) | forward |
| T5c | verify → act | Verification FAILed — back-loop with failed observable as scope | back-loop |
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
5. **Support pause/resume.** If the user needs to stop, use `/session-pause`. On return, use `/session-resume`.

## Orchestration Procedure

This section is the **reference procedure** followed by `/session-start` when driving the task workflow end-to-end in the parent context (not via an Agent subagent spawn — see `docs/product/transitions.md` "Experiment: Subagent-Per-Step Orchestration" for why). Read this as an instruction set for running the workflow inline.

### Precedence rule

**Skill-level `**STOP**` directives and `"Run /x"` prose are never authoritative in orchestrated mode.** The only machine signal the orchestrator acts on is the `TRANSITION: <id>` token at the end of a skill's output. After every `Skill` tool call, re-read the active drive mode and apply the pause-policy table below. **AUTO transitions may not invoke `AskUserQuestion` or any user-input tool** — the next action at an AUTO step is a `Skill` invocation, never an inline confirmation; pause only where the table marks `PAUSE` (see `agents/feature-workflow/AGENTS.md` → Precedence rule for the canonical statement, P1 incident 2026-06-23).

### How to advance

1. **Invoke each skill via the Skill tool** in sequence, following the state machine above.
2. **After each skill completes**, read the `TRANSITION: <id>` token and re-check the pause-policy table for the active drive mode. Do not act on `"Run /x"` prose.
3. **If you hit a blocker you can't resolve** (tests failing, environment broken, unclear instruction), pause and surface it to the user — don't thrash.

### Pause policy by drive mode

Full policy tables are in `docs/product/transitions.md` → "Drive modes". Summary for task workflow:

| Step | Mode 1 — Stepping | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — FSD |
|------|-----------------------|-----------------------|--------------------|------------------------|
| `task-plan` (T2 gate) | PAUSE | **PAUSE** | AUTO | AUTO |
| `task-act` | PAUSE | AUTO | AUTO | AUTO |
| `task-verify` (T5b/T5c gate) | PAUSE | AUTO | AUTO | AUTO |
| `task-close` (T10/T11 gate) | PAUSE | **PAUSE** | AUTO | AUTO |
| ESCALATE (T3, T9) | PAUSE | **PAUSE** | **PAUSE** | **PAUSE** |
| REDIRECT (T4) | PAUSE | **PAUSE** | **PAUSE** | **PAUSE** |

ESCALATE and REDIRECT always pause in all modes — scope changes require human acknowledgment.

Mode 1 pauses: every step.
Mode 2 happy-path pauses: plan confirm + close confirm (2 total — task-verify is AUTO).
Mode 3/4 happy-path pauses: none (ESCALATE/REDIRECT excepted).

### Debug techniques (agent-pulled sidebars)

The following `debug-*` skills are available as sidebars from within task workflow states. They are **NOT** workflow states (no entry in the pause-policy table above, no T-ID transition), but the orchestrator (or user) may invoke them inline when their trigger conditions are met. Each sidebar runs to completion and emits a `RETURN-TO:` token so this orchestrator resumes the caller state.

| Sidebar | Caller state(s) | Trigger summary |
|---------|-----------------|-----------------|
| `/debug-bisect-known-good` | `task-act` | Straight-line debugging during act has stalled (≥3 failed attempts) AND a structurally similar known-good path exists in the same environment |
| `/debug-empirical-telemetry` | `task-act` | Static-reasoning debugging during act has stalled (≥2–3 failed attempts) AND the bug-shape requires runtime evidence (timing/race, intermittent, DB query plan or timing, perf regression, env-dependent state, "wrong value at this line") |
| `/debug-minimal-harness` | `task-act` | A behavioral fix (drag/click/focus/keyboard, CLI, HTTP, race) has been handed back untested ≥2× on the same behavior AND that behavior is drivable in a surface the agent controls (browser/DOM, CLI, HTTP client, real concurrency) — even when the shipping target is native — so build a minimal standalone repro and drive it with real input before re-presenting |

See `~/.claude/CLAUDE.md` → "`debug-*` Skill Category" (or this repo's `CLAUDE.md`) for the category convention. The full procedure and gate-check for each sidebar lives in its own `SKILL.md`. New `debug-*` skills are added to this table when they ship.

## Workflow State File

The canonical record of progress is `workflow/wip/<task-slug>.md`. This file tracks:
- Current state (plan/act/close)
- Plan checklist with completion status
- Session pause notes (if any)
- Surface/escalation notes (if any)
