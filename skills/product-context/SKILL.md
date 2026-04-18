---
name: product-context
description: "Product workflow: generate the project's .claude/CLAUDE.md context file and transition to feature workflow"
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
Read the WIP file for all product artifacts:
- Vision (purpose, audience, metrics)
- Roadmap (phases, milestones)
- Research (tech stack, trade-offs)
- Architecture (system design, data flow)
- WBS (work packages, dependencies)

### 2. Generate Project CLAUDE.md
Create or update `.claude/CLAUDE.md` in the project root with:

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

### 3. Archive Product Artifacts
- Update the WIP file state to `context (complete)`
- Move to `workflow/archive/`
- Ensure the WBS and roadmap remain accessible (copy key sections into CLAUDE.md or keep in `docs/`)

### 4. Transition to Feature Workflow
- Identify the first milestone from the roadmap
- Tell the user: "Product planning is complete. Start the first feature from the roadmap by running `/feature-spec` (or `/feature-plan` if it's small/simple)."
- Evaluate the first milestone against the small/simple criteria to recommend the right entry point

**Additional Instructions:** {{args}}
