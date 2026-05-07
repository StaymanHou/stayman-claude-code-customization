# Claude Code Workflow System

A state machine-driven workflow system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), ported and refactored from the Gemini CLI workflow system. Provides structured workflows for product planning, feature development, task execution, and incident management — all orchestrated through Claude Code skills and agents.

## Workflow Hierarchy

```
Product (strategic decomposition: vision → roadmap → research → arch → wbs → context)
  └── Feature (multi-step: spec → research → plan → [build → verify] loop → ship → finalize)
        └── Task (atomic: plan → act → close)

Incident (independent: report → triage → investigate → mitigate → resolve)
Session  (cross-cutting: start, pause, resume, reflect, store-learning)
```

Lower-level workflows can **surface** discoveries upward (e.g., a task discovers an architectural gap). Higher-level workflows decompose into lower-level ones (e.g., product WBS → features → tasks).

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| **Skills** | 31 | One per workflow step |
| **Agents** | 4 | Orchestrators: product, feature, task, incident |
| **Hooks** | 1 | `notify-telegram.sh` — fires on Notification + Stop events |
| **Transitions** | 63 | Defined in `docs/product/transitions.md` |
| **Install script** | 1 | Idempotent symlink setup |

### Skills by Workflow

- **Product (6):** vision, roadmap, research, arch, wbs, context
- **Feature (11):** spec, research, plan, build, verify-auto, verify-self, verify-human, verify-codify, ship, finalize, refactor
- **Task (3):** plan, act, close
- **Incident (5):** report, triage, investigate, mitigate, resolve
- **Session (5):** start, pause, resume, reflect, store-learning
- **Telegram notifications:** wired via the `hooks/notify-telegram.sh` harness hook (no skill — fires automatically on Notification + Stop events)

## Installation

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed
- A Telegram bot token (create via [@BotFather](https://t.me/BotFather)) and your chat ID

### Setup

```bash
# Clone the repo
git clone git@github.com:StaymanHou/stayman-claude-code-customization.git ~/Personal/projects/my-claude-code-customization

# Run the install script (creates symlinks to ~/.claude/)
cd ~/Personal/projects/my-claude-code-customization
./install.sh
```

The install script:
- Creates per-skill, per-agent, and per-hook symlinks from this repo to `~/.claude/skills/`, `~/.claude/agents/`, and `~/.claude/hooks/`.
- Injects the contents of [`CLAUDE.snippet.md`](CLAUDE.snippet.md) into `~/.claude/CLAUDE.md` between `<!-- BEGIN/END claude-workflow-system -->` markers. This primes every Claude Code session with the workflow entry points and orchestrator subagents. A one-time `.bak` is written on first modification.

It's idempotent — safe to re-run: subsequent runs refresh the block between markers rather than appending again. **To opt out of the injected block, don't re-run `install.sh`** — the block you already have is yours to edit or delete. Any `install.sh` invocation will reassert the canonical block.

### Configuration

Add to `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_TELEGRAM_BOT_TOKEN": "<your-bot-token>",
    "CLAUDE_TELEGRAM_CHAT_ID": "<your-chat-id>"
  },
  "permissions": {
    "allow": [
      "Read(~/.claude/**)",
      "Edit(~/.claude/**)",
      "Read(~/Personal/projects/my-claude-code-customization/**)",
      "Edit(~/Personal/projects/my-claude-code-customization/**)",
      "Bash(curl -s -X POST https://api.telegram.org/*)"
    ]
  }
}
```

Both symlink and source paths are needed in permissions — symlink resolution behavior is undocumented.

## Usage

### Starting a Workflow

Two invocation modes:

**Single-step** — invoke a skill directly. The agent runs that one step, tells you the next command, and stops. You invoke each step manually.

```
/product-vision    # New product initiative
/feature-spec      # Complex feature (needs spec)
/feature-plan      # Simple feature (skip spec)
/task-plan         # Atomic task (bug fix, small change)
/incident-report   # Production issue
/session-resume    # Resume a paused session
```

**End-to-end orchestration** — use `/session-start` when you want the agent to drive the entire workflow without you invoking each step. The agent classifies the work, confirms once, then chains through all steps automatically — pausing only at real decision points (spec/plan review, human verification, finalize).

```
/session-start
```

### During a Workflow

In single-step mode, each skill tells you the valid next step. Invoke it manually:

```
/feature-build          # Implement current phase
/feature-verify-auto    # Run automated checks
/feature-verify-self    # Agent live-system observation
/feature-verify-human   # Manual verification
/feature-verify-codify  # Write comprehensive tests
```

### Pausing and Resuming

```
/session-pause     # Save state to workflow/wip/
/session-resume    # Restore context and continue
```

### Cross-Level Surfacing

During any workflow, if you discover something that belongs at a higher level:
- **Note-and-continue:** Logged to `workflow/backlog.md`, work continues
- **Pause-and-escalate:** Current work pauses until the higher-level issue is resolved
- **ESCALATE:** Current work is closed and absorbed into a higher-level workflow

## Key Design Decisions

- **Advisory enforcement:** State machines are encoded in skill prompts, not hard-blocked by hooks. This allows flexibility while maintaining structure.
- **Per-phase verification loop:** Features go through `build → verify-auto → verify-self → verify-human → verify-codify` for each implementation phase.
- **File-based state:** `workflow/wip/` files are the canonical record — inspectable, git-trackable, and persistent across sessions.
- **Telegram notifications:** The `notify-telegram.sh` hook fires automatically on `Notification` (Claude is blocked, awaiting input) and `Stop` (turn ended) events — deterministic, not model-driven.

## Per-Project State

Each project using this workflow system has its own state (not symlinked):

```
<project-root>/
├── CLAUDE.md                  # Project overview + rules (generated by /product-context, visible to humans & agent)
├── .claude/CLAUDE.md          # Optional: agent-only overrides (not required)
│
├── docs/product/              # Strategic, long-lived product docs (one product per repo)
│   ├── vision.md              # Each file has frontmatter: stage, state, updated
│   ├── roadmap.md
│   ├── research.md
│   ├── arch.md
│   ├── wbs.md
│   └── context.md
│
└── workflow/                  # Transient execution state
    ├── backlog.md             # SURFACE notes
    ├── .session.md            # Single-file session pointer for /session-pause and /session-resume
    ├── wip/                   # Active feature/task/incident items
    └── archive/               # Completed feature/task/incident items
```

Product docs stay in `docs/product/` for the life of the project — they are reference material, not WIP. Back-loops in the product workflow edit the earlier stage's file in place (bumping `state` back to `in-progress` and appending a revision section).

## Reference

See [docs/product/transitions.md](docs/product/transitions.md) for all 63 state machine transitions, the SURFACE/ESCALATE/REDIRECT mechanism details, and the subagent-per-step experiment.
