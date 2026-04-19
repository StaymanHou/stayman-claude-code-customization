---
name: product-context
description: "Product workflow: generate the project's CLAUDE.md context file and transition to feature workflow"
argument-hint: <optional additional instructions>
---

# Product Context

You are an expert Technical Writer and Software Architect generating the project context file.

## State Machine Context

You are in the **product** workflow at the **context** state.
This is the **terminal state** of the product workflow.

**Valid transitions from here:**
- **P10 → EXIT → feature:plan:** Always. Start the first milestone from the roadmap.

## Procedure

### 1. Gather Inputs
Read the product docs from `docs/product/`:
- `vision.md` (purpose, audience, metrics)
- `roadmap.md` (phases, milestones)
- `research.md` (tech stack, trade-offs)
- `arch.md` (system design, data flow)
- `wbs.md` (work packages, dependencies)

### 2. Generate Project CLAUDE.md
Create or update **`CLAUDE.md` at the project root** with the content below. This file is project documentation — it's checked in, visible in the file tree, and read by both humans and Claude Code. Do NOT write it to `.claude/CLAUDE.md` (that path is reserved for agent-only overrides a user may add separately).

If a `CLAUDE.md` already exists at the project root, preserve any user-authored sections and merge — don't overwrite.

```markdown
# <Project Name>

## Project Overview
<Summary from vision>

## Tech Stack
<Key technologies from architecture>

## Project Structure
<Generated directory tree of key directories>

## Getting Started
### Prerequisites
<What needs to be installed>

### Setup
<Configuration steps>

### Docker Instructions (if applicable)
<Standard Docker commands>

## Development Conventions
<Code style, testing conventions, Docker rules if applicable>

## Current Phase
<Active roadmap phase and its goals>

## Key Decisions
<Important architectural and product decisions with rationale>
```

### 3. Finalize Product Docs
- Product docs stay in place under `docs/product/` — they are durable reference material, not ephemeral WIP, so they are **not** archived.
- Create `docs/product/context.md` summarizing the generated root `CLAUDE.md` and noting the active roadmap phase:

```markdown
---
stage: context
state: complete
updated: <YYYY-MM-DD>
---

# Context

Project CLAUDE.md generated at `CLAUDE.md` (project root).

**Active phase:** <current roadmap phase>
**First feature:** <first milestone to pick up>
```
- Set `state: complete` on every other file in `docs/product/` that is still `in-progress`.

### 4. Transition to Feature Workflow
- Identify the first milestone from the roadmap
- Tell the user: "Product planning is complete. Start the first feature from the roadmap by running `/feature-spec` (or `/feature-plan` if it's small/simple)."
- Evaluate the first milestone against the small/simple criteria to recommend the right entry point

**Additional Instructions:** {{args}}
