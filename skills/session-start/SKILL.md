---
name: session-start
description: Start a new workflow session — classify the work, confirm with the user, then drive the matching workflow end-to-end in this context
argument-hint: <optional context about what the user wants to work on>
---

# Session Start

You are a workflow dispatcher AND orchestrator. Your job is to **classify** the work, get a single **confirmation**, and then **drive the workflow end-to-end** by invoking each skill via the `Skill` tool — all in this conversation. You do **not** spawn a subagent.

## Available workflows

| Workflow | Entry skill | Orchestrator procedure | When to use |
|----------|-------------|------------------------|-------------|
| **Product** | `product-vision` | `agents/product-workflow/AGENTS.md` | New product initiative, strategic planning |
| **Feature** | `feature-spec` (complex) or `feature-plan` (small/simple) | `agents/feature-workflow/AGENTS.md` | Multi-step implementation |
| **Task** | `task-plan` | `agents/task-workflow/AGENTS.md` | Atomic work: bug fix, small change |
| **Incident** | `incident-report` | `agents/incident-workflow/AGENTS.md` | Production issue |
| **Resume** | — (run `/session-resume` directly) | — | Continue a previously paused session |

**Small/simple feature criteria** (skip spec, go straight to plan):
All must hold: (1) no new data models or API endpoints, (2) no architectural decisions required, (3) describable in ≤ 4 sentences, (4) estimated < 4 hours of agent work, (5) estimated ≤ ~200 lines of new/changed code.

## Procedure

### 1. Check for active work
Briefly check for any active work and mention it if found:
- `workflow/.session.md` — an explicitly paused session → strongly recommend `/session-resume` over starting fresh
- `workflow/wip/` — any active feature/task/incident files
- `docs/product/` — any product doc with frontmatter `state: in-progress`

If active work exists, ask whether the user wants to resume or start something new.

### 2. Classify the work
If the user provided context via `{{args}}`, classify immediately. Otherwise, ask one brief question: "What are you tackling?" — then classify.

Classification outputs:
- **Workflow:** product | feature | task | incident | resume
- **Entry skill:** the specific skill name from the table above
- **For features:** evaluate small/simple criteria to pick `feature-spec` vs `feature-plan`

### 3. Confirm once
State your classification (1–2 sentences), then invoke `notify-human` and ask **exactly one** question:

> "I'll drive the `<workflow>` workflow end-to-end from here — invoking each skill in sequence and pausing only at real decision points. Sound good? (yes to continue, no if you'd rather run each skill manually.)"

**On "no"** — tell the user which entry skill to run manually (e.g. `/product-vision`). Stop. You're done.

**On "yes"** — proceed to step 4.

### 4. Drive the workflow (in THIS context)

You are now the orchestrator for the classified workflow. You do **NOT** spawn an Agent subagent. You run the entire workflow in the current conversation.

**Load the orchestration procedure.** Read `agents/<workflow>-workflow/AGENTS.md` (the matching orchestrator file for the classified workflow). Its `## Orchestration Procedure` section tells you:
- The happy-path sequence of skills
- Which transitions are back-loops and what triggers them
- Which cross-level transitions to expect (SURFACE, ESCALATE, REDIRECT)
- **Which moments require a human pause** (with `notify-human`) vs. which should auto-chain

**Run the loop.** For each step:
1. Invoke the current skill via the `Skill` tool.
2. Read the skill's transition recommendation at the end of its output.
3. Pick the matching transition from the orchestrator's transition table.
4. If the next state requires human input per the orchestrator's pause points, invoke `notify-human` and wait for the user. Otherwise, invoke the next skill immediately — do **not** ask the user to retype a slash command.
5. Repeat until the workflow reaches a terminal state or the user explicitly pauses.

**Persist progress.** After each completed step, update the active state file on disk (the skill itself writes this — you just trust it) and optionally touch `workflow/.session.md` if the user steps away.

### 5. Cross-workflow handoff (EXIT→<other-workflow> transitions)

Some terminal transitions exit into *another* workflow (e.g., `P10: context → EXIT→feature:plan`). When you hit one:

1. **Do not stop.** The user already opted into end-to-end driving — there's no need to re-classify or re-confirm.
2. **Read the next orchestrator's AGENTS.md.** For `EXIT→feature:plan`, that's `agents/feature-workflow/AGENTS.md`. Load its Orchestration Procedure.
3. **Pick the entry skill.** For feature handoffs, evaluate the small/simple criteria against the work item being entered (e.g., the first WP from the WBS). Use `feature-plan` for small/simple, `feature-spec` for complex.
4. **Drive the next workflow in the same dialogue.** Apply that orchestrator's pause points, not the previous one's.
5. **Scope of one handoff = one unit of the next workflow.** After one feature workflow completes (through `finalize` or `refactor`), **pause and ask**: "Next WP or stop?" Do **not** auto-chain into a second feature. Each feature is a natural stopping point because:
   - The verify-human pauses and ship confirmation in feature workflow already impose structure.
   - The user should see a shipped increment before committing to the next one.
6. **If the user says "next WP"**, loop back into step 2 of cross-workflow handoff with the next work item. Don't re-ask classification.

Cross-workflow examples you may hit:
- **P10** (product → feature:plan) — product exit, first WP starts
- **T3 / T9 / F28** (task ESCALATE → feature:spec) — task grew too big; close the task, open a feature
- **F25 / F26 / P11 / P12** — SURFACE, not EXIT: these edit backlog or jump back to product during a feature; they return to the original workflow automatically.

Non-EXIT terminal states (e.g., `F19` finalize → reflect, `T10` close → EXIT): the workflow simply ends. Do not auto-chain into a new one.

### 6. Resume path
If the work classifies as a resume, do NOT start driving. Tell the user to run `/session-resume`. That skill reads `workflow/.session.md` and restores context before any workflow driving would make sense.

## What success looks like

User runs `/session-start <short description>`. You classify, confirm once (one `notify-human`). User says yes. You then run every skill in the matching workflow inline, pausing only when the orchestrator's procedure says a human decision is required (e.g., spec/plan review, verify-human, triage severity, back-loops). User never retypes a slash command to move forward.

If a terminal transition exits into another workflow (e.g., product → feature), you continue driving in the same dialogue under the new orchestrator's procedure — one unit deep (one feature, one task). After that unit finishes, pause and ask whether to continue with another.

## What this skill is NOT

- **Not an Agent spawner.** Do not invoke `Agent({subagent_type: "..."})`. The orchestrator files live at `agents/<workflow>-workflow/AGENTS.md`, but you read them as reference material and run the workflow yourself.
- **Not a single-skill runner.** Direct slash commands like `/product-vision` still exist for one-step invocations. `/session-start` is specifically for end-to-end driving.
