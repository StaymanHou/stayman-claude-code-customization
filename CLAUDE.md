# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

This is the **source** repository for a Claude Code workflow system — a collection of skills and orchestrator agents that implement a state-machine-driven workflow hierarchy (Product → Feature → Task, plus Incident and Session meta-operations).

The skills and agents here are **symlinked into `~/.claude/`** by `install.sh`. Editing a file here immediately affects the live Claude Code configuration on this machine — there is no build step. Conversely, the repo is not self-contained software: the skills only run when invoked through Claude Code.

## Commands

```bash
./install.sh                          # Idempotent — creates per-skill and per-agent symlinks from this repo to ~/.claude/
./tests/run-tests.sh                  # Run all transition tests (invokes `claude --print` per scenario)
./tests/run-tests.sh --group task     # Run one workflow group (task|feature|product|incident|session)
./tests/run-tests.sh --id T2,T3,F9    # Run specific transitions by ID
./tests/run-tests.sh --dry-run        # List scenarios without executing
./tests/run-tests.sh --model sonnet   # Override test model (default: haiku)
```

Test runner requires `claude` CLI, `jq`, and `bc` on PATH. Results are written to `tests/results/run-<timestamp>.json` (gitignored). Each test spins up a temp project directory, copies `tests/fixtures/` into it, runs the skill in `--print` mode with a system prompt that forces the model to emit `TRANSITION: <id>` at the end, then verifies the output.

## Architecture

### Two kinds of artifacts

- **Skills** (`skills/<name>/SKILL.md`) — one per workflow step. Each skill's prompt encodes the **valid transitions** out of the corresponding state. The model is expected to pick a transition at the end of the skill and tell the user which slash command to invoke next.
- **Agents** (`agents/<name>/AGENTS.md`) — one orchestrator per workflow group (product, feature, task, incident). Each agent holds the full state-machine view and an **Orchestration Procedure** section that `/session-start` reads as an instruction set. These files are reference documents, not Agent-spawned subagents.

### Two invocation paths — single-step vs end-to-end

- **Direct slash command** (e.g., `/product-vision`) — runs exactly one skill, then tells the user the next slash command. Single-step, no chaining. Use when you want to invoke a specific state or resume work.
- **`/session-start`** — classifies the work, gets one confirmation, then **drives the workflow in the current conversation** by loading the matching orchestrator's Orchestration Procedure and invoking each skill via the Skill tool. Pauses only at human-input points defined by the procedure. Use when you want to drive a full workflow end-to-end.

Why in-context and not via Agent spawn: the `Agent` tool is one-shot — a subagent that pauses for human input can't be resumed, which forced each human pause to respawn a fresh subagent and lose mid-step state. Running orchestration in the parent keeps the user dialogue continuous. An experimental subagent-per-step design is documented in `docs/product/transitions.md` → "Experiment: Subagent-Per-Step Orchestration" if context growth ever becomes a problem.

Keep both paths working: never bake auto-chain logic into individual skill prompts (that would break single-step invocation). Orchestration behavior lives in the orchestrator AGENTS.md files, invoked by reference from `/session-start`.

### The state machine lives in three places — keep them in sync

1. `docs/product/transitions.md` — authoritative definition (65 transitions, IDs like `P1`, `F8`, `T2`, `I3`) plus architecture narrative and cross-level mechanism docs.
2. Per-skill `SKILL.md` — each skill lists the transitions *out of its state* in prose, referencing the same IDs.
3. `tests/scenarios/*.yaml` — scenarios assert a specific transition ID fires for a given input.

If you add, remove, or reword a transition, update all three. The tests use the IDs as the source of truth for pass/fail.

### State persistence is per-project, not here

Skills read and write state **in whatever project the user is currently in** — not in this repo. This repo's own `workflow/` directory holds no WIP files.

Two locations, different purposes:

- **`docs/product/`** — strategic, long-lived product docs. Flat layout, one file per product-workflow stage: `vision.md`, `roadmap.md`, `research.md`, `arch.md`, `wbs.md`, `context.md`. Each file carries YAML frontmatter with `stage`, `state` (`in-progress` / `complete`), and `updated`. **Assume one product per codebase.** Files are never archived — they are durable reference.
- **`workflow/`** — transient execution state for feature/task/incident workflows.
  - `workflow/wip/<item>.md` — the active work item for a feature, task, or incident
  - `workflow/backlog.md` — SURFACE discoveries
  - `workflow/archive/` — completed feature/task/incident items
  - `workflow/.session.md` — single-file session pointer written by `/session-pause` and read by `/session-resume`. Only one active pause per repo; overwritten by subsequent pauses.

Back-loops in the product workflow (P4, P6, P8) edit an earlier stage's file in place — bump `updated:`, set `state: in-progress`, append a `## Revision <date>` section. Files are not deleted on back-loops.

This repo itself dogfoods the system: `docs/product/vision.md` is the vision for the workflow system. The repo's own `workflow/` directory holds no WIP files — all strategic and architectural docs live in `docs/product/`.

### Enforcement model

State transitions are **advisory**, not hard-blocked. The skill prompts tell the model what the valid next states are; there are no hooks that prevent invalid transitions. This is intentional — see `docs/product/transitions.md` → "Design Principles" for rationale. Back-loops (`type: back-loop`) require the model to document *what changed and why* before re-entering an earlier state.

### Cross-level mechanisms

Three ways one workflow interacts with another — understand the distinction before editing transitions:

- **SURFACE** (lower → higher): discovery is logged to `workflow/backlog.md`. Mode is either `note-and-continue` (non-blocker) or `pause-and-escalate` (blocker).
- **ESCALATE** (task → feature, etc.): current item is closed/archived; work is absorbed into a higher-level item. No resume.
- **REDIRECT** (e.g., `build → research`): current workflow pauses, other workflow runs, original resumes — possibly with re-planning.

### Telegram notify-human

The `notify-human` skill sends Telegram messages before the model asks the user a question. The global `~/.claude/CLAUDE.md` mandates calling it before any substantive human input. Requires `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` env vars in `~/.claude/settings.json`; skip silently if unset.

## Product Workflow Notes

This repo dogfoods the product workflow but **skips `/product-context`** — the project already has a hand-maintained `CLAUDE.md` (this file) that serves the same purpose. The product workflow is considered complete after `/product-wbs`.

## Conventions

- `install.sh` is idempotent. Re-run after adding or renaming a skill/agent directory — it will create new symlinks and update any whose target has changed.
- Skill frontmatter fields: `name` (matches the directory), `description`, optional `argument-hint`.
- Agent frontmatter includes a `skills:` list — this must match the directories that exist under `skills/`.
- When the PR description references a transition, use the ID from `docs/product/transitions.md` (e.g. "Fixes F12 back-loop wording"), not the state names alone.
