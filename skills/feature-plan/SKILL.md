---
name: feature-plan
description: "Feature workflow: create a phased implementation plan for the feature"
argument-hint: <feature name or notes>
---

# Feature Plan

You are an expert Software Architect creating an implementation plan.

## State Machine Context

You are in the **feature** workflow at the **plan** state.

This is the entry point for **small/simple** features (F2) or follows spec/research for complex ones.

**Valid transitions from here:**
- **F7 → build (phase 1):** Plan created with phases → tell user to run `/feature-build`

Also entered via:
- **F20 (refactor → plan):** CONSTRAINT — plan must be scoped to cleanup only, no new features
- **F23 (build → plan back-loop):** Plan was wrong/incomplete — revise it

## Procedure

### 1. Backlog Check
Scan `workflow/backlog.md` (if it exists) for:
- `high` priority items matching this feature area
- Conflicts with what's about to be planned
Mention any relevant items to the user.

### 2. Context Review
- Read the spec in `workflow/wip/` (if complex feature)
- Review research findings (if any)
- Examine existing codebase structure and patterns
- Read the project `CLAUDE.md` at the root for project rules (also `.claude/CLAUDE.md` if present)

### 3. Create Phased Plan

**If entering for a new feature** (F2 or F4→F7), create or update `workflow/wip/<feature-name>.md` using the **Work Tree format** (see `## Work Tree Format (GLOBAL)` in your system context):

```markdown
# Feature: <Name>

**Workflow:** feature
**State:** plan (complete)
**Created:** <YYYY-MM-DD>

## Problem Statement
<One paragraph. Will be re-examined on every back-loop entry — not static.>

## Work Tree

- [ ] Phase 1: <title>  <!-- status: NOT-STARTED -->
  **Observable outcomes:**
  - Browser: <declarative outcome — what a user/curl/Playwright would observe>
  - HTTP: <e.g. GET /endpoint → 200, body contains {field: type}>
  - CLI: <e.g. command exits 0, stdout matches pattern>
  - Console: <e.g. no JS errors on page load>
  - [ ] P1.1 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] P1.2 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: <title>  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - <...>
  - [ ] P2.1 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > P1.1
- **Active scope:** P1.1 (first task)
- **Blocked:** none
- **Unvisited:** <list phases beyond Phase 1>
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
```

**Rules for this template:**
- **Observable outcomes** are written NOW at plan time — not at verify time. They describe what must be true about the *running system* from the outside (HTTP responses, browser state, CLI output). They are the agent's verification target in `feature-verify-self`.
- **All 5 verification group nodes** (`verify-auto`, `verify-self`, `verify-human`, `verify-codify`) must be pre-populated as `NOT-STARTED` under every phase. Do not omit any.
- **`## Current Node`** must be initialized pointing to Phase 1's first impl task. This is the position pointer every subsequent skill reads first.
- **No depth cap** — nest as needed, but prefer splitting wide phases into sibling phases over excessive nesting.

Each phase should be a coherent unit that can go through the `build → verify-auto → verify-self → verify-human → verify-codify` loop independently.

**If entering from refactor (F20):**
- CONSTRAINT: Scope to cleanup only — no new features, no scope expansion
- Plan should address specific tech debt items identified in finalize

**If entering from build back-loop (F23):**
- Revise the existing plan, document what was wrong and why

### 4. Update WIP State
Set state to `plan (complete)` in the WIP file.

### 5. Hand Off
Tell the user to run `/feature-build` to start Phase 1.

**STOP** — do NOT start implementing.

**User Request:** {{args}}
