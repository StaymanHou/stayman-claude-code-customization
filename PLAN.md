# Claude Code Workflow System — Master Plan

## Overview

Port the Gemini CLI workflow system (27 TOML commands across 5 workflow groups) to Claude Code, refactoring from linear command chains into a state machine architecture with conditional transitions, cross-level surfacing, and hierarchical workflow composition.

**Source:** `~/Personal/projects/my-gemini-customization/commands/workflow/`
**Target:** `~/Personal/projects/my-claude-code-customization/` → symlinked to `~/.claude/`

---

## Architecture Decisions

### Mapping: Skills + Per-Workflow Agents (Hybrid)
- **Each workflow step** is a **skill** (`.claude/skills/<name>/SKILL.md`)
- **Each workflow group** has an **orchestrator agent** (`.claude/agents/<name>/AGENTS.md`) that owns the state machine for that group
- Agents have the transition logic preloaded via `skills:` frontmatter
- State machine enforcement is **advisory with guardrails**: skill prompts define valid transitions, a lightweight hook warns on unusual transitions, hard blocks only for truly dangerous cases

### State Management: Hybrid
- **File-based state** (`workflow/wip/<item>.md`) is the canonical record — persistent, inspectable, git-trackable
- **Skill prompts** encode transition logic and conditions
- **Auto memory** provides cross-session recovery backup
- Claude Code's native session persistence is the primary session mechanism; explicit pause/resume files are backup

### Permissions & Portability
- Source repo at `~/Personal/projects/my-claude-code-customization/`
- Symlinked to `~/.claude/` via setup script (per-skill, per-agent symlinks)
- `~/.claude/settings.json` permissions allow both symlink and source paths
- Workflow state files (`workflow/wip/`, `workflow/backlog.md`) are per-project, not symlinked

### Telegram Notifications
- A `notify-human` skill sends Telegram messages before requesting human input
- All workflow skills that need human input must invoke `/notify-human` first
- Configured via `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` environment variables
- Global `~/.claude/CLAUDE.md` instructs Claude to use this skill across all projects

---

## Workflow Hierarchy

```
Product (strategic decomposition)
  └── Feature (multi-step implementation units, per-milestone)
        └── Task (atomic work items)

Incident (independent entry point, can surface tasks/features)
Session (cross-cutting meta-operations at any level)
```

Lower-level workflows can **surface** discoveries upward. Higher-level workflows decompose into lower-level ones.

---

## State Machines

### Product Workflow

```
States: vision, roadmap, research, arch, wbs, context
Entry: vision
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
| P10 | context | EXIT→feature:plan | Always. Start first milestone from roadmap. |
| P11 | SURFACE-IN | wbs | Lower-level workflow discovers new work |
| P12 | SURFACE-IN | arch | Lower-level workflow discovers architectural gap |

**Back-loop guard:** Any back-loop must document *what changed and why* before re-entering the earlier state. Prevents infinite loops.

**Note:** Vision revision loop deferred to future phase.

### Feature Workflow

```
States: spec, research, plan, build, verify-auto, verify-human,
        verify-codify, ship, finalize, refactor
Entry: spec (complex) or plan (small/simple)
Terminal: finalize or refactor (both → auto-trigger reflect)
```

**Per-phase loop:** `plan` decomposes a milestone into phases. The loop `build → verify-auto → verify-human → verify-codify` executes per phase. After all phases → ship.

**Small/simple criteria (skip spec, go straight to plan):**
All must hold:
1. No new data models or API endpoints
2. No architectural decisions required
3. Can be described in ≤ 4 sentences
4. Estimated implementation < 4 hours of agent work
5. Estimated ≤ ~200 lines of new/changed code

| ID | From | To | Condition |
|----|------|----|-----------|
| F1 | ENTRY | spec | Feature is complex (fails small/simple criteria) |
| F2 | ENTRY | plan | Feature is small/simple |
| F3 | spec | research | Unknowns exist |
| F4 | spec | plan | No unknowns, spec is clear |
| F5 | research | plan | Research complete |
| F6 | research | spec | Back-loop: research reveals spec is wrong |
| F7 | plan | build (phase 1) | Plan created with phases |
| F8 | build | verify-auto | Phase implementation complete |
| F9 | verify-auto | build | Back-loop: tests fail |
| F10 | verify-auto | verify-human | Tests pass |
| F11 | verify-human | verify-codify | Nothing for human to test (agent must present reasoning and get human confirmation to skip) |
| F12 | verify-human | build | Back-loop: human rejects |
| F13 | verify-human | verify-codify | Human approves happy path |
| F14 | verify-codify | verify-human | Back-loop: new tests reveal issues human missed |
| F15 | verify-codify | build (next phase) | Tests written, more phases remain |
| F16 | verify-codify | ship | Tests written, all phases complete |
| F17 | ship | finalize | Shipped / PR ready |
| F18 | finalize | refactor | Tech debt identified |
| F19 | finalize | EXIT→reflect | No tech debt, feature done |
| F20 | refactor | plan | Refactor needs a plan (CONSTRAINT: scoped to cleanup only, no new features — enforced via skill prompt) |
| F21 | refactor | EXIT→reflect | Refactor complete |
| F22 | build | research | Hit unknown during implementation (REDIRECT: pause, research, return) |
| F23 | build | plan | Plan is wrong/incomplete |
| F24 | verify-auto | spec | Tests reveal spec was wrong |
| F25 | build | SURFACE→product:wbs | Discovered module/component not in WBS (note-and-continue) |
| F26 | build | SURFACE→product:arch | Architectural change needed (pause-and-escalate) |
| F27 | ANY | incident:report | Something breaks |
| F28 | SURFACE-IN | spec | Task escalated to feature |

### Task Workflow

```
States: plan, act, close
Entry: plan
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
| T7 | act | SURFACE→feature:spec | Discovered something bigger (note-and-continue or pause-and-escalate depending on whether it's a blocker) |
| T8 | act | SURFACE→product:wbs | New work item discovered (note-and-continue) |
| T9 | act | ESCALATE→feature:spec | Task grew beyond task scope — close task, open feature |
| T10 | close | EXIT | Always |
| T11 | close | EXIT→reflect | Significant learning occurred (optional auto-trigger) |

### Incident Workflow

```
States: report, triage, investigate, mitigate, resolve
Entry: report
Terminal: resolve
```

| ID | From | To | Condition |
|----|------|----|-----------|
| I1 | ENTRY | report | Always |
| I2 | report | triage | Report filed |
| I3 | triage | investigate | Severity assessed, needs investigation (ask human for impact, set P0-P3) |
| I4 | triage | resolve | Fast-close: false alarm / duplicate |
| I5 | investigate | investigate | Self-loop: need more data (agent decides when to stop) |
| I6 | investigate | mitigate | Root cause found |
| I7 | investigate | resolve | Fast-close: false alarm discovered during investigation |
| I8 | mitigate | investigate | Back-loop: fix didn't work, need more data |
| I9 | mitigate | resolve | Fix applied, monitoring period passed |
| I10 | resolve | EXIT→reflect | Always (auto-trigger) |
| I11 | resolve | SURFACE→task:plan | Root cause needs proper fix (small) |
| I12 | resolve | SURFACE→feature:spec | Root cause needs architectural fix (large) |

### Session Operations (Cross-Cutting)

Not a state machine — meta-operations that attach to any workflow state.

| Operation | Trigger | Behavior |
|-----------|---------|----------|
| **start** | Manual | Routes user to correct workflow entry point |
| **pause** | Manual | Save current workflow + state + step to `workflow/wip/` file. Record resume command. |
| **resume** | Manual | Read state file, summarize where left off, suggest resume command |
| **reflect** | Auto: after feature:finalize, feature:refactor, incident:resolve. Optional: after task:close if significant. | Analyze session for wrong assumptions. Strongly prompt user to run store-learning. |
| **store-learning** | Manual (prompted by reflect) | Classify learning (global vs project), propose storage location, execute after human confirmation. Can write to `~/.claude/` or `.claude/`. |

---

## SURFACE Mechanism

### Two Modes

| Mode | When | Behavior |
|------|------|----------|
| **Note-and-continue** | Discovery is NOT a blocker | Log to `workflow/backlog.md`, annotate current WIP plan, continue working |
| **Pause-and-escalate** | Discovery IS a blocker (can't continue without higher-level change) | Pause current workflow, create higher-level item, address it, resume |

### Decision Criteria

Default to note-and-continue unless:
- The discovery changes an interface being actively coded against
- An architectural decision is required before proceeding
- Current work would be invalidated without the change

### Note-and-Continue Entry Format

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

### Backlog Review Timing
- **During `plan`** (any workflow): lightweight scan for `high` priority items or items whose target matches the current workflow level. Check for conflicts with what's about to be planned.
- **During `finalize`/`close`**: full backlog review. Surface unresolved items to user.

### ESCALATE (One-Way Surface)

Used when current work item should be abandoned in favor of higher-level one:
1. Update all docs to reflect escalation
2. Mark current item as "Escalated to [target]", close/archive it
3. Create higher-level item, enter that workflow
4. No resume of original — it's been absorbed

### REDIRECT (Round-Trip)

Used when current work needs something from another level but will resume:
1. Pause current workflow (save state)
2. Enter the other workflow/step (e.g., feature:research)
3. On return, agent evaluates: did findings change the plan?
   - If **no**: auto-flow results into plan, annotate, continue
   - If **yes**: re-plan before resuming act

---

## Directory Structure

### Source Repository

```
~/Personal/projects/my-claude-code-customization/
├── README.md
├── PLAN.md                            # This document
├── install.sh                         # Setup script (symlinks + permissions)
├── skills/
│   ├── product-vision/SKILL.md
│   ├── product-roadmap/SKILL.md
│   ├── product-research/SKILL.md
│   ├── product-arch/SKILL.md
│   ├── product-wbs/SKILL.md
│   ├── product-context/SKILL.md
│   ├── feature-spec/SKILL.md
│   ├── feature-research/SKILL.md
│   ├── feature-plan/SKILL.md
│   ├── feature-build/SKILL.md
│   ├── feature-verify-auto/SKILL.md
│   ├── feature-verify-human/SKILL.md
│   ├── feature-verify-codify/SKILL.md
│   ├── feature-ship/SKILL.md
│   ├── feature-finalize/SKILL.md
│   ├── feature-refactor/SKILL.md
│   ├── task-plan/SKILL.md
│   ├── task-act/SKILL.md
│   ├── task-close/SKILL.md
│   ├── incident-report/SKILL.md
│   ├── incident-triage/SKILL.md
│   ├── incident-investigate/SKILL.md
│   ├── incident-mitigate/SKILL.md
│   ├── incident-resolve/SKILL.md
│   ├── session-start/SKILL.md
│   ├── session-pause/SKILL.md
│   ├── session-resume/SKILL.md
│   ├── session-reflect/SKILL.md
│   ├── session-store-learning/SKILL.md
│   └── notify-human/SKILL.md         # Telegram notification (cross-cutting)
├── agents/
│   ├── product-workflow/AGENTS.md
│   ├── feature-workflow/AGENTS.md
│   ├── task-workflow/AGENTS.md
│   └── incident-workflow/AGENTS.md
├── workflow/
│   └── transitions.yaml              # State machine definitions (all workflows)
├── hooks/
│   └── check-workflow-state.sh        # Lightweight state guardrail
└── settings/
    └── user-settings-template.json    # Template for ~/.claude/settings.json
```

### Symlink Targets (managed by install.sh)

```
~/.claude/skills/product-vision    → source/skills/product-vision
~/.claude/skills/product-roadmap   → source/skills/product-roadmap
... (one symlink per skill)

~/.claude/agents/product-workflow  → source/agents/product-workflow
~/.claude/agents/feature-workflow  → source/agents/feature-workflow
... (one symlink per agent)
```

### Per-Project Workflow State (not symlinked)

```
<project-root>/
├── .claude/
│   └── CLAUDE.md                  # Project-specific context
└── workflow/
    ├── backlog.md                 # SURFACE notes
    └── wip/
        └── <active-item>.md       # Current WIP plan with state
```

### Permission Settings (~/.claude/settings.json)

```json
{
  "permissions": {
    "allow": [
      "Read(~/.claude/**)",
      "Edit(~/.claude/**)",
      "Read(~/Personal/projects/my-claude-code-customization/**)",
      "Edit(~/Personal/projects/my-claude-code-customization/**)"
    ]
  }
}
```

Both symlink and source paths needed — symlink resolution behavior is undocumented, so we cover both.

---

## Step Delta from Gemini Original

### Added Steps
| Step | Workflow | Reason |
|------|----------|--------|
| verify-auto | Feature | Split from verify: automated tests first |
| verify-human | Feature | Split from verify: human walkthrough of happy path |
| verify-codify | Feature | Split from verify: write comprehensive tests after human approval |
| triage | Incident | Severity assessment with human input before investigation |

### Removed Steps (at this level)
| Step | Workflow | Reason |
|------|----------|--------|
| verify | Task | Verification happens at feature level, not task level |

### Changed Steps
| Step | Change | Reason |
|------|--------|--------|
| spec | Now skippable | Small/simple features go straight to plan |
| research | Now skippable | Only when unknowns exist |
| refactor→plan | Constrained | Plan must be cleanup-only, no new features (enforced via prompt) |
| reflect | Now auto-triggered | Fires after feature completion, incident resolution |
| pause/resume | Lighter | Lean on Claude Code native session persistence |
| context | Now terminal | Always drops to feature workflow for first milestone |

### Added Transitions (not in Gemini)
| Transition | Type | Reason |
|------------|------|--------|
| build → research | Redirect | Hit unknown during implementation |
| build → plan | Back-loop | Plan was wrong/incomplete |
| verify-auto → spec | Back-loop | Tests reveal spec was wrong |
| verify-codify → verify-human | Back-loop | New tests reveal issues |
| mitigate → investigate | Back-loop | Fix didn't work |
| task:plan → feature:research | Redirect | Need research before acting |
| Any → SURFACE | Cross-level | Discoveries bubble up to higher workflows |
| Any → ESCALATE | Cross-level | Work item absorbed into higher level |

---

## Future Phase: Hierarchy of Facts

Deferred to next phase. Document the requirement here for tracking:

Establish a priority ordering for information sources that the agent should follow when facts conflict:

1. **Human input** (highest) — overrides all other sources in most cases
2. **Raw error logs / runtime output** — overrides inference and model knowledge
3. **Online official references and documentation** — overrides model knowledge
4. **Current codebase state** (reading actual files) — overrides memory and assumptions
5. **Model's trained knowledge** (lowest) — default when no other source available

This hierarchy should be encoded in CLAUDE.md or a dedicated rule file and referenced by all workflow skills.

Also deferred: vision revision loop, reflect after product:context completion.

---

## Implementation Order (Incremental)

### Phase 0: Prerequisites
1. Create a Telegram bot via @BotFather, obtain `TELEGRAM_BOT_TOKEN`
2. Get your `TELEGRAM_CHAT_ID` (message the bot, then query `getUpdates`)
3. Add both to environment (e.g., `~/.zshrc` or `~/.claude/.env`)

### Phase 1: Foundation ✅ (complete)
1. Create project structure and `install.sh` ✅
2. Set up permissions in `~/.claude/settings.json` ✅
3. Set up `~/.claude/CLAUDE.md` with global rules ✅
4. Create `notify-human` skill ✅
5. Port `session-start`, `session-pause`, `session-resume` ✅
6. Create `transitions.yaml` with all state definitions ✅

### Phase 2: Task Workflow (simplest, 3 states) ✅ (complete)
1. Port `task-plan`, `task-act`, `task-close` ✅
2. Implement SURFACE mechanism (backlog.md format in task-act skill) ✅
3. Create `task-workflow` agent ✅
4. Test end-to-end on a real task — deferred to real usage

### Phase 3: Feature Workflow (most complex) ✅ (complete)
1. Port `feature-spec`, `feature-research`, `feature-plan` ✅
2. Port `feature-build` with per-phase loop ✅
3. Create `feature-verify-auto`, `feature-verify-human`, `feature-verify-codify` (new) ✅
4. Port `feature-ship`, `feature-finalize`, `feature-refactor` ✅
5. Create `feature-workflow` agent ✅
6. Test with a real multi-phase feature — deferred to real usage

### Phase 4: Product Workflow ✅ (complete)
1. Port `product-vision`, `product-roadmap`, `product-research` ✅
2. Port `product-arch`, `product-wbs`, `product-context` ✅
3. Create `product-workflow` agent ✅
4. Test full hierarchy: product → feature → task — deferred to real usage

### Phase 5: Incident Workflow ✅ (complete)
1. Port `incident-report`, create `incident-triage` (new) ✅
2. Port `incident-investigate`, `incident-mitigate`, `incident-resolve` ✅
3. Create `incident-workflow` agent ✅
4. Test incident → surface → task/feature — deferred to real usage

### Phase 6: Session & Polish ✅ (skills complete, hooks/testing deferred)
1. Port `session-reflect` with auto-trigger hooks ✅ (skill done; hooks deferred to real usage tuning)
2. Port `session-store-learning` with `~/.claude/` write support ✅
3. Add lightweight workflow state hook — deferred to real usage tuning
4. End-to-end testing across all workflows — deferred to real usage
5. Write README.md — deferred

### Future Phases
- Hierarchy of facts system
- Vision revision loop
- Reflect after product:context
- Relaxed verify-human rules based on usage patterns
