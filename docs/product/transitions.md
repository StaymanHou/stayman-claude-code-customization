# State Machine Architecture

This document is the authoritative reference for the workflow state machine: all transitions, the enforcement model, cross-level mechanisms, and implementation notes. It replaces the former `transitions.yaml` (machine-readable) and `PLAN.md` (design narrative) — both are now consolidated here.

---

## Design Principles

### Enforcement model

State transitions are **advisory**, not hard-blocked. Skill prompts tell the model what the valid next states are; there are no hooks that prevent invalid transitions. This is intentional — the overhead of hard enforcement is higher than the cost of the occasional out-of-order invocation, and the system is designed to be used by a capable agent that can self-correct. Back-loops (`type: back-loop`) require the model to document *what changed and why* before re-entering an earlier state.

### Two invocation paths

- **Direct slash command** (e.g., `/product-vision`) — runs exactly one skill, then tells the user the next slash command. Single-step, no chaining.
- **`/session-start`** — drives the workflow end-to-end in the current conversation by reading the matching orchestrator's Orchestration Procedure and invoking each skill via the Skill tool. Pauses only at human-input points.

Keep both paths working: never bake auto-chain logic into individual skill prompts. Orchestration behavior lives in `agents/<workflow>-workflow/AGENTS.md`.

### Back-loop guard

Any back-loop transition must document *what changed and why* before re-entering the earlier state. This prevents infinite loops and creates an audit trail in the WIP file.

---

## Cross-Level Mechanisms

Three ways workflows interact with each other:

### SURFACE (lower → higher)

A discovery in a lower-level workflow is logged upstream. Two modes:

| Mode | When | Behavior |
|------|------|----------|
| `note-and-continue` | Discovery is NOT a blocker | Log to `workflow/backlog.md`, annotate current WIP plan, continue working |
| `pause-and-escalate` | Discovery IS a blocker | Pause current workflow, create higher-level item, address it, resume |

**Escalate criteria** (default is note-and-continue unless one of these holds):
- The discovery changes an interface being actively coded against
- An architectural decision is required before proceeding
- Current work would be invalidated without the change

**Backlog entry format:**
```markdown
## SURFACE-<timestamp>
- **Source:** <current workflow>:<current step>
- **Target level:** <product|feature>:<suggested step>
- **Type:** new-work | gap | tech-debt | bug
- **Summary:** <what was discovered>
- **Context:** <why it matters>
- **Suggested action:** <what should be done>
- **Priority:** low | medium | high
- **Status:** pending
```

**Backlog review timing:**
- During `plan` (any workflow): lightweight scan for `high` priority items or items whose target matches the current workflow level
- During `finalize`/`close`: full backlog review, surface unresolved items to user

### ESCALATE (one-way absorption)

Current work item is abandoned in favor of a higher-level one:
1. Update all docs to reflect escalation
2. Mark current item as "Escalated to [target]", close/archive it
3. Create higher-level item, enter that workflow
4. No resume of original — it's been absorbed

### REDIRECT (round-trip)

Current workflow pauses, another workflow/step runs, original resumes:
1. Pause current workflow (save state)
2. Enter the other workflow/step
3. On return, evaluate: did findings change the plan?
   - If **no**: auto-flow results into plan, annotate, continue
   - If **yes**: re-plan before resuming

---

## Product Workflow

```
States:  vision → roadmap → research → arch → wbs → context
Entry:   vision
Terminal: context (→ drops to feature:plan for first milestone)
```

| ID | From | To | Condition |
|----|------|----|-----------|
| P1 | ENTRY | vision | Always |
| P2 | vision | roadmap | Vision doc created |
| P3 | roadmap | research | Roadmap has phases defined |
| P4 | research | roadmap | Back-loop: research invalidates roadmap assumptions |
| P5 | research | arch | Research complete, no roadmap changes needed |
| P6 | arch | research | Back-loop: architecture reveals unknowns |
| P7 | arch | wbs | Architecture defined |
| P8 | wbs | arch | Back-loop: WBS reveals architectural gaps |
| P9 | wbs | context | WBS complete |
| P10 | context | EXIT→feature:plan | Always — start first milestone from roadmap |
| P11 | SURFACE-IN | wbs | Lower-level workflow discovers new work |
| P12 | SURFACE-IN | arch | Lower-level workflow discovers architectural gap |

Back-loop guard applies to: P4, P6, P8.

**Back-loop behavior:** Edit the earlier stage's file in place — bump `updated:`, set `state: in-progress`, append a `## Revision <date>` section. Files are never deleted on back-loops.

---

## Feature Workflow

```
States:  spec, research, plan, build, verify-auto, verify-human,
         verify-codify, ship, finalize, refactor
Entry:   spec (complex) or plan (small/simple)
Terminal: finalize or refactor (both → auto-trigger reflect)
```

**Per-phase loop:** `plan` decomposes a milestone into phases. The loop `build → verify-auto → verify-human → verify-codify` executes once per phase. After all phases complete → ship.

**Small/simple criteria** (all must hold to skip spec and go straight to plan):
1. No new data models or API endpoints
2. No architectural decisions required
3. Describable in ≤ 4 sentences
4. Estimated < 4 hours of agent work
5. Estimated ≤ ~200 lines of new/changed code

| ID | From | To | Condition |
|----|------|----|-----------|
| F1 | ENTRY | spec | Feature is complex (fails small/simple criteria) |
| F2 | ENTRY | plan | Feature is small/simple (all criteria met) |
| F3 | spec | research | Unknowns exist |
| F4 | spec | plan | No unknowns, spec is clear |
| F5 | research | plan | Research complete |
| F6 | research | spec | Back-loop: research reveals spec is wrong |
| F7 | plan | build | Plan created with phases (starts phase 1) |
| F8 | build | verify-auto | Phase implementation complete |
| F9 | verify-auto | build | Back-loop: tests fail |
| F10 | verify-auto | verify-human | Tests pass |
| F11 | verify-human | verify-codify | Nothing for human to test — agent presents reasoning, human confirms skip |
| F12 | verify-human | build | Back-loop: human rejects |
| F13 | verify-human | verify-codify | Human approves happy path |
| F14 | verify-codify | verify-human | Back-loop: new tests reveal issues human missed |
| F15 | verify-codify | build | Tests written, more phases remain (advance to next phase) |
| F16 | verify-codify | ship | Tests written, all phases complete |
| F17 | ship | finalize | Shipped / PR ready |
| F18 | finalize | refactor | Tech debt identified |
| F19 | finalize | EXIT→reflect | No tech debt, feature done |
| F20 | refactor | plan | Refactor needs a plan — CONSTRAINT: scoped to cleanup only, no new features |
| F21 | refactor | EXIT→reflect | Refactor complete |
| F22 | build | research | REDIRECT: hit unknown during implementation — pause, research, return |
| F23 | build | plan | Back-loop: plan is wrong/incomplete |
| F24 | verify-auto | spec | Back-loop: tests reveal spec was wrong |
| F25 | build | SURFACE→product:wbs | Discovered module/component not in WBS (note-and-continue) |
| F26 | build | SURFACE→product:arch | Architectural change needed (pause-and-escalate) |
| F27 | ANY | incident:report | Something breaks |
| F28 | SURFACE-IN | spec | Task escalated to feature |

---

## Task Workflow

```
States:  plan → act → close
Entry:   plan
Terminal: close
```

| ID | From | To | Condition |
|----|------|----|-----------|
| T1 | ENTRY | plan | Always |
| T2 | plan | act | Plan is clear, ready to implement |
| T3 | plan | ESCALATE→feature:spec | "This is bigger than a task" — close task, update docs, open feature |
| T4 | plan | REDIRECT→feature:research | Research needed — pause task, research, return |
| T5 | act | close | Implementation complete, no issues |
| T6 | act | plan | Back-loop: need to re-plan |
| T7 | act | SURFACE→feature:spec | Discovered something bigger (note-and-continue or pause-and-escalate depending on blocker status) |
| T8 | act | SURFACE→product:wbs | New work item discovered (note-and-continue) |
| T9 | act | ESCALATE→feature:spec | Task grew beyond task scope — close task, open feature |
| T10 | close | EXIT | Always |
| T11 | close | EXIT→reflect | Significant learning occurred (optional auto-trigger) |

---

## Incident Workflow

```
States:  report → triage → investigate → mitigate → resolve
Entry:   report
Terminal: resolve
```

| ID | From | To | Condition |
|----|------|----|-----------|
| I1 | ENTRY | report | Always |
| I2 | report | triage | Report filed |
| I3 | triage | investigate | Severity assessed (P0–P3 via human input), needs investigation |
| I4 | triage | resolve | Fast-close: false alarm or duplicate |
| I5 | investigate | investigate | Self-loop: need more data (agent decides when to stop) |
| I6 | investigate | mitigate | Root cause found |
| I7 | investigate | resolve | Fast-close: false alarm discovered during investigation |
| I8 | mitigate | investigate | Back-loop: fix didn't work, need more data |
| I9 | mitigate | resolve | Fix applied, monitoring period passed |
| I10 | resolve | EXIT→reflect | Always (auto-trigger) |
| I11 | resolve | SURFACE→task:plan | Root cause needs proper fix (small) |
| I12 | resolve | SURFACE→feature:spec | Root cause needs architectural fix (large) |

---

## Session Operations (Cross-Cutting)

Not a state machine — meta-operations that attach to any workflow state.

| Operation | Trigger | Behavior |
|-----------|---------|----------|
| `start` | Manual | Routes user to correct workflow entry point |
| `pause` | Manual | Save current workflow + state + step to `workflow/wip/` file |
| `resume` | Manual | Read state file, summarize where left off, suggest resume command |
| `reflect` | Auto: after feature:finalize, feature:refactor, incident:resolve. Optional: after task:close. | Analyze session for wrong assumptions. Strongly prompt user to run store-learning. |
| `store-learning` | Manual (prompted by reflect) | Classify learning (global vs project), propose storage location, execute after human confirmation |

---

## Experiment: Subagent-Per-Step Orchestration (Parked)

The current orchestration approach runs in the **parent context** via `/session-start`. This works but grows the main context over long workflows.

If context bloat becomes a real problem, revisit this design: each workflow step runs inside its own short-lived subagent spawn. Parent owns only the orchestration loop.

### Why it's hard

`Agent` is a one-shot tool. A subagent that pauses for human input can't be resumed — it just returns. The parent then has to spawn a *new* subagent with the user's answer, rebuilding context each time. Live testing showed: subagent asked scoping questions, returned, parent got answer, had to respawn from scratch with the same skill — which re-ran `product-vision` and lost mid-step state.

### Minimum viable design

**One subagent = one skill invocation.** No chaining inside a subagent. The parent `/session-start` runs a dispatcher loop that spawns one step, parses a structured return, collects any needed human input, then spawns the next step.

**Structured return protocol.** Subagents emit a fenced `orchestration` JSON block as the last content of their response:

```json
{
  "transition_id": "P2",
  "next_skill": "product-roadmap",
  "state_file_path": "docs/product/vision.md",
  "needs_human_input": false,
  "question_to_user": null,
  "summary": "Drafted vision doc covering audience, physics scope, mission types, WWII setting.",
  "done": false
}
```

Fields: `transition_id`, `next_skill` (null iff done/paused), `state_file_path`, `needs_human_input`, `question_to_user` (required iff needs_human_input), `summary` (1–2 sentences), `done`.

**Parent loop (pseudocode):**
```
state = { workflow, next_skill, context_summary, pending_answers, state_file_path, history }
persist to workflow/.session.md

loop:
  spawn Agent(subagent_type=<workflow>-workflow,
              prompt=spawn_prompt(state))
  parse orchestration block from output
  if malformed: retry once with stricter prompt, then pause + notify-human
  if needs_human_input: notify-human, collect answer, append to pending_answers
  append summary to history
  if done: break, clean up .session.md
  state.next_skill = next_skill; persist
```

**Spawn prompt skeleton:**
```
You are running ONE step of the <workflow> workflow in single-step orchestration mode.
STEP TO RUN: <skill-name>
WORKFLOW: <product|feature|task|incident>
STATE FILE: <path>
PRIOR CONTEXT SUMMARY: <short paragraph>
RECENT HUMAN ANSWERS: <verbatim replies, or "none">

Procedure:
1. Read the state file(s) you need.
2. Run the <skill-name> skill via the Skill tool.
3. Emit the orchestration JSON block described in docs/product/transitions.md (tagged `orchestration`).
4. STOP. Do not invoke the next skill.
```

**Cross-level transitions under this model:**
- **SURFACE note-and-continue:** next_skill stays in same workflow; no pause
- **SURFACE pause-and-escalate:** next_skill=null, done=false, needs_human_input=true
- **ESCALATE:** next_skill=null, done=true, summary describes handoff
- **REDIRECT:** next_skill is a skill in a different workflow; parent tracks "return workflow"
- **Back-loops:** next_skill points at the earlier skill; parent spawns it with the back-loop reason in RECENT HUMAN ANSWERS

**Failure modes:**

| Symptom | Handling |
|---------|----------|
| Missing orchestration block | Retry once with strict prompt prefix. Then pause. |
| Multiple blocks emitted | Parse last one. |
| Invalid transition_id | Pause, surface to user. |
| `next_skill` mismatches transition | Prefer next_skill; log hint into next spawn. |
| done=true with pending SURFACE | Process surface first, then terminate. |

**Trade-offs vs current approach:**

| | Option 1 (current — in-context) | Option 2 (experiment — subagent-per-step) |
|--|--|--|
| Parent context growth | Linear with workflow length | Small — only summaries |
| Spawn count | 0 | 1 per step (6 for product, 3+ per phase for feature) |
| Wall time | Faster | Slower (spawn overhead per step) |
| Implementation complexity | Low | High — JSON protocol, retry logic, resume hydration |
| Resume semantics | Per-skill boundary | Orchestration-loop boundary (finer-grained) |

**When to revisit:**
- If a full product + feature workflow regularly hits `/compact` boundaries mid-run
- If long feature workflows (4+ phases) visibly slow down the main agent
- If we want finer-grained resume (mid-orchestration, not just mid-skill)

---

## Future Transitions

Deferred items not yet in the state machine:

- **Vision revision loop** — back-loop from roadmap to vision if scope changes fundamentally
- **Reflect after product:context** — auto-trigger reflect after P10
- **Auto-trigger hook for reflect** — `settings.json` hook that detects completion of feature:finalize, feature:refactor, or incident:resolve and auto-prompts `/session-reflect`. Currently skills only suggest it.
- **Lightweight workflow state hook** — PreToolUse hook that reads `workflow/wip/` state and warns (or blocks via exit code 2) when a skill invocation doesn't match the current state. Best tuned after real usage.
- **Hierarchy of facts** — explicit priority ordering for information sources when they conflict: (1) human input, (2) raw error logs/runtime output, (3) online official references, (4) current codebase state, (5) model's trained knowledge.
