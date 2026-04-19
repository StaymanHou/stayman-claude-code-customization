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

**If entering for a new feature** (F2 or F4→F7), create or update `workflow/wip/<feature-name>.md`:

```markdown
## Architecture
- System changes, data models, API endpoints (if applicable)

## Implementation Phases

### Phase 1: <title>
- [ ] Step 1.1
- [ ] Step 1.2
- ...

### Phase 2: <title>
- [ ] Step 2.1
- ...

## Testing Strategy
- How each phase will be verified

## Migration Plan
- Database or data migrations (if needed)
```

Each phase should be a coherent unit that can go through the `build → verify-auto → verify-human → verify-codify` loop independently.

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
