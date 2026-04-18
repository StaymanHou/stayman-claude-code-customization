---
stage: vision
state: complete
updated: 2026-04-18
---

# Vision — Claude Code Workflow System

## Vision

**Core Problem:** Agent-assisted software work drifts. Without structure, a single conversation can oscillate between planning, implementation, research, and debugging — losing context at each pivot, producing half-finished artifacts, and leaving no durable record of *why* a decision was made. Existing agent tooling optimizes for single-turn competence; it does not impose the discipline of a development lifecycle. The result: rework, inconsistent quality, and a constant cost of re-establishing context across sessions.

**Proposed Solution:** A state-machine-driven workflow system, delivered as Claude Code skills and orchestrator agents, that encodes the shape of real software work — strategic decomposition (product), implementation cycles (feature), atomic changes (task), and incident response — as explicit, inspectable states with defined transitions. Each state has its own skill with narrow scope; each workflow group has an orchestrator agent that owns the state machine. State lives on disk (`workflow/wip/` for execution state, `docs/product/` for strategic docs) so it survives session boundaries and is legible to both human and agent. Cross-level mechanisms (SURFACE, ESCALATE, REDIRECT) formalize the discoveries that real work generates, rather than pretending plans are static.

The system is **advisory, not coercive**: transitions are encoded in prompts, not enforced by hooks. This preserves agent judgment while giving the work legible structure.

## Target Audience

- **Primary:** The author — a solo developer using Claude Code across multiple personal projects, seeking consistent process without re-teaching the agent every session.
- **Secondary:** Other Claude Code users who want a ported, refined version of the Gemini CLI workflow system and are comfortable editing skill prompts to fit their habits.
- **Not the target:** Teams needing multi-user orchestration, ticketing integrations, or CI-gated workflow enforcement. This is a single-operator tool.

## Success Metrics

- **Adoption friction:** A new project picks up the system in one `install.sh` run plus a few lines of `settings.json`. Re-running install is always safe.
- **Coverage:** Every meaningful state in real development — from fuzzy product vision to post-incident reflection — has a dedicated skill. Currently 30 skills, 4 agents, 63 transitions.
- **Correctness:** Automated transition tests (`tests/run-tests.sh`) pass consistently on `haiku` and above; flaky tests get rewritten, not retried.
- **Context survival:** The user can `session-pause` mid-feature, return days later via `session-resume`, and continue without re-explanation. The active WIP file plus `workflow/.session.md` is sufficient context.
- **Cross-level fidelity:** Discoveries during lower-level work reliably surface to `workflow/backlog.md` rather than getting lost or derailing the current state.
- **Human-in-the-loop alerting:** When the agent needs the user, `notify-human` fires. The user is never left guessing whether the agent is waiting on them.

## Core Principles

1. **State is a file, not a memory.** The canonical record of any in-progress work is a markdown file on disk — inspectable, diffable, git-trackable, recoverable. If it only exists in conversation context, it does not exist.
2. **Advisory enforcement over hard blocks.** Encode the state machine in prompts so agents can exercise judgment at edges. Hooks are reserved for truly dangerous actions, not for process conformance.
3. **One concern per skill.** Each skill owns a single state. It declares its valid exits and hands off. No skill does "a little planning and a little building" — that erodes the machine.
4. **Surface, don't swallow.** Real work uncovers work. When a task reveals a feature, or a feature reveals an architectural gap, the system has a named mechanism (SURFACE / ESCALATE / REDIRECT) to route it — never silent TODO comments or dropped threads.
5. **Source lives here; `~/.claude/` is a symlink.** The repo is the source of truth. Edits are live. There is no build step and no duplication.
6. **Per-project state stays per-project.** Workflow artifacts (`workflow/wip/`, `workflow/backlog.md`, `workflow/.session.md`) and strategic docs (`docs/product/`) live in the project the user is working on, not in the skill repo. The skill repo ships behavior, not state.
7. **Human interruptibility is a feature.** Telegram notifications via `notify-human` are mandatory before any substantive question. The agent must never silently block on the user.
8. **Ported, not reinvented.** This system is a deliberate port of the Gemini CLI workflow — refined and restructured around skills/agents, but preserving the hard-won shape of the original lifecycle.

---

**Next:** Run `/product-roadmap` to decompose this vision into phased milestones.
