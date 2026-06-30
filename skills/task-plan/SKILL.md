---
name: task-plan
description: "Task workflow: analyze request, discover context, and create an implementation plan in workflow/wip/"
argument-hint: <description of the task to plan>
---

# Task Plan

You are an expert software engineer starting a new task.

**User Request:** {{args}}

## State Machine Context

You are in the **task** workflow at the **plan** state.

**Valid transitions from here:**
- **T2 → act:** Plan is clear, ready to implement → tell user to run `/task-act`
- **T3 → ESCALATE to feature:spec:** "This is bigger than a task" — close the task plan, update docs, tell user to run `/feature-spec`
- **T4 → REDIRECT to feature:research:** Research needed before acting — pause task, tell user to run the research, then return

## Step 0: Available product context

Before planning, check whether the project has strategic product docs that should inform the task plan. Run `ls docs/product/` (silently no-op if the directory is absent). The docs you may find:

- `docs/product/arch.md` — architectural decisions and system design
- `docs/product/wbs.md` — active work breakdown structure (current cycle)
- `docs/product/vision.md` — high-level product vision
- `docs/product/roadmap.md` — strategic roadmap

**Conditional read — `arch.md` only:** if the task description appears to touch architectural decisions — renaming a public API, changing a data shape, modifying a cross-module boundary, altering a workflow state machine — read `docs/product/arch.md` and reflect any constraint in the plan. If the trigger doesn't apply, skip the read; the pointer above is sufficient.

**`wbs.md`, `vision.md`, `roadmap.md`:** pointer-only. Don't read these for task-level work — they're too coarse for atomic changes. If the task surprisingly needs WBS context, the user will paste it into args.

**Size guard:** if `arch.md` exceeds ~300 lines, read only the first 100 lines (via the `Read` tool's `limit:` parameter) plus a `Grep` for `^#+ ` headings. Append one line to the WIP file's `## Discoveries` section noting the truncation.

**Absent files:** silent no-op. No warning, no prompt.

See `CLAUDE.snippet.md` → "Entry-skill product-context loading (GLOBAL)" for the canonical mapping these rules follow.

## Procedure

### 1. Backlog Check
Before planning, scan `workflow/backlog.md` (if it exists) for:
- `high` priority items matching this task area
- Items whose target is `task` level
- Conflicts with what's about to be planned

Mention any relevant backlog items to the user.

### 2. Context Discovery
- Read the project `CLAUDE.md` at the root for project-specific rules (also check `<proj-dir>/.claude/CLAUDE.md` if present — that path is for agent-only overrides)
- Search for relevant files, existing patterns, documentation
- Understand the scope and constraints

### 3. Scope Assessment
Evaluate whether this is truly a task or should be escalated:
- If it requires new data models, API endpoints, or architectural decisions → recommend ESCALATE (T3)
- If there are unknowns that need research first → recommend REDIRECT (T4)
- Otherwise → proceed with planning

### 4. Plan Creation
Create a markdown file in `workflow/wip/<task-slug>.md` using the **Work Tree format** (task variant — no Observable Outcomes, no verify loop):

```markdown
---
workflow: task
state: plan (complete)
created: <YYYY-MM-DD>
docs-only: false  # set to `true` only for pure-docs tasks (CLAUDE.md prose edits, backlog status updates, README touches) — enables task-verify auto-skip
---

# Task: <title>

**Workflow:** task
**State:** plan (complete)
**Created:** <YYYY-MM-DD>

## Problem Statement
<One sentence. Will be re-examined on back-loop re-entry.>

## Context
- Links to relevant files discovered above

## Work Tree

- [ ] T1 <step>  <!-- status: NOT-STARTED -->
- [ ] T2 <step>  <!-- status: NOT-STARTED -->
- [ ] T3 <step>  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Task > T1
- **Active scope:** T1 (first step)
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
```

Note: Task Work Tree has no Observable Outcomes and no verify loop — tasks are atomic. The `## Current Node` section is still required so that re-entry after a back-loop carries precise scope.

**About `docs-only:`** — the `docs-only: true` frontmatter declaration enables `/task-verify` to auto-skip the verification gate, emitting T5b (PASS) immediately without running a verification command. Set to `true` ONLY when the task touches no runtime surface — pure markdown edits, backlog updates, retrospect-only changes, CLAUDE.md prose touches. If the task changes any code, shell script, config file, or anything with a runtime effect, set `docs-only: false` (or omit — default is `false`). Misdeclaring a code task as `docs-only: true` bypasses the verification that exists to catch latent bugs (see `skills/task-verify/SKILL.md` → "When the gate auto-skips" for the rationale).

### 5. Stop and Hand Off
After creating the plan:
- Present a high-level summary
- Tell the user to run `/task-act` to begin implementation
- **Single-step mode only:** STOP here — do NOT start implementing. In orchestrated/autopilot/fsd modes the orchestrator chains to act automatically based on the drive mode's pause policy.
