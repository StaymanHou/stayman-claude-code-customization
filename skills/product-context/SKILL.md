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
- `roadmap.md` (milestones; older roadmaps may say "phases" — read-alias)
- `research.md` (tech stack, trade-offs)
- `arch.md` (system design, data flow)
- `wbs.md` (work packages, dependencies)

### 2. Generate Project CLAUDE.md
Create or update **`CLAUDE.md` at the project root** with the content below. This file is project documentation — it's checked in, visible in the file tree, and read by both humans and Claude Code. Do NOT write it to `.claude/CLAUDE.md` (that path is reserved for agent-only overrides a user may add separately).

If a `CLAUDE.md` already exists at the project root, preserve any user-authored sections and merge — don't overwrite.

This generated `CLAUDE.md` is the **primary enforcement mechanism** for the Dev Environment decision recorded in `docs/product/arch.md`. Every skill that runs commands reads this file and respects its rules. The Dev Environment section below is **required** — pick the Docker Mandate variant or the Host-based variant to match arch.md. Do not omit it, do not soften the language.

```markdown
# <Project Name>

## Project Overview
<Summary from vision>

## Tech Stack
<Key technologies from architecture>

## Project Structure
<Generated directory tree of key directories>

## Dev Environment

<Pick ONE variant, matching the `Dev Environment` section in `docs/product/arch.md`.>

### Variant A — Docker Mandate (use if arch.md declared Docker-based)

**This project uses Docker for all development.** Every command during development — build, run, test, lint, type-check, database migrations, seed scripts, CLI tools, language REPLs, package installs, code generators, any project-specific tooling — MUST run inside the appropriate container via the command prefix below. The ONLY exceptions are:

- `git` and other VCS operations
- Read-only file and directory operations (`ls`, `cat`, `grep`, editor commands, etc.)
- `docker` / `docker compose` commands themselves

**Command prefix:** `<e.g., docker compose exec app>`

**Services:** <list from arch.md>

**First-run bootstrap:** `<e.g., docker compose build && docker compose up -d>`

**Randomize host ports.** In `docker-compose.yml`, randomize every `host:container` left-hand port from the ephemeral range (49152-65535) rather than using the service's well-known default. The container-internal (right-hand) port stays canonical (postgres 5432, redis 6379, vite 5173, etc.); only the host side is randomized. Pick with `python3 -c "import random; print(random.randint(49152, 65535))"`; confirm free with `lsof -nP -iTCP:<port> -sTCP:LISTEN`. Add a one-line comment next to each mapping so future readers don't "fix" it back: `- "58329:5173"  # host port randomized to avoid collisions`. Rationale: well-known defaults collide when multiple project checkouts share one host — a `5173:5173` mapping will land on whichever Vite-like project booted first, and tests against `http://localhost:5173` may silently hit the wrong app. Applies to dev compose only; prod compose files can keep defaults. **Maintenance:** this rule applies on every future change too — when adding a new service or any new `ports:` entry to `docker-compose.yml`, pick a random ephemeral host port the same way. Never reach for a service's well-known default just because the project is past the initial setup.

**Rule for agents and humans alike:** if you catch yourself about to run `pytest`, `npm test`, `pip install`, `python manage.py …`, `cargo …`, etc. directly on the host, STOP and prefix it with the command above. Running on the host bypasses the project environment and the results are not trustworthy. There is no "just this once" exception.

**Docker down — two cases, two responses.** Before assuming a hard-block, check the daemon and the containers separately:

- **Daemon unreachable** (`docker ps` errors / cannot connect): this is the hard-blocker. STOP and ask the user to start Docker. Do **not** fall back to the host OS.
- **Daemon reachable but the project's containers are down** (`docker ps` exits 0 but the service you need isn't running): do **not** pause and do **not** ask. Start the container(s) yourself (`docker compose up -d`, or `up --build` if images need building), wait for them to be healthy, then resume the task. `docker` / `docker compose` commands are on the allowed list above — starting containers is the correct unblock, not a host-OS fallback.

### Variant B — Host-based (use ONLY if arch.md explicitly opted out)

**Rationale for host-based dev env (copied from arch.md):** <the written justification>

Commands run directly on the host. Standard setup and tooling apply.

## Getting Started
### Prerequisites
<What needs to be installed — for Variant A this is just Docker + Docker Compose; for Variant B, the full host toolchain>

### Setup
<Configuration steps>

## Development Conventions
<Code style, testing conventions, etc. Do NOT restate Docker rules here — they live in Dev Environment above.>

## Current Milestone
<Active roadmap milestone and its goals>

## Key Decisions
<Important architectural and product decisions with rationale>
```

### 3. Finalize Product Docs
- Product docs stay in place under `docs/product/` — they are durable reference material, not ephemeral WIP, so they are **not** archived.
- Create `docs/product/context.md` summarizing the generated root `CLAUDE.md` and noting the active roadmap milestone:

```markdown
---
stage: context
state: complete
updated: <YYYY-MM-DD>
---

# Context

Project CLAUDE.md generated at `CLAUDE.md` (project root).

**Active milestone:** <current roadmap milestone>
**First feature:** <first milestone to pick up>
```
- Set `state: complete` on every other file in `docs/product/` that is still `in-progress`.

### 4. Transition to Feature Workflow
- Identify the first milestone from the roadmap
- Tell the user: "Product planning is complete. Start the first feature from the roadmap by running `/feature-spec` (or `/feature-plan` if it's small/simple)."
- Evaluate the first milestone against the small/simple criteria to recommend the right entry point

**Additional Instructions:** {{args}}
