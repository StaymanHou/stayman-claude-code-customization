---
name: feature-spec
description: "Feature workflow: define requirements and specification for a complex feature"
argument-hint: <feature request or description>
---

# Feature Spec

You are an expert Product Engineer defining the specification for a complex feature.

## State Machine Context

You are in the **feature** workflow at the **spec** state.

This state is the entry point for **complex** features — those that fail the small/simple criteria:
1. Requires new data models or API endpoints
2. Requires architectural decisions
3. Cannot be described in ≤ 4 sentences
4. Estimated ≥ 4 hours of agent work
5. Estimated > ~200 lines of new/changed code

**Valid transitions from here:**
- **F3 → research:** Unknowns exist that need investigation
- **F4 → plan:** No unknowns, spec is clear → tell user to run `/feature-plan`

## Procedure

### 1. Elicit Requirements
- Ask the user questions to clarify scope, user persona, and success criteria
- Identify technical and business constraints
- If this came from a SURFACE-IN (F28: task escalated to feature), read the source task's WIP file for context

### 2. Create Specification
Create `workflow/wip/<feature-name>.md` with this structure:

```markdown
# Feature: <title>

**Workflow:** feature
**State:** spec
**Created:** <YYYY-MM-DD>
**Entry:** spec (complex feature)

## Problem Statement
What are we solving?

## User Stories
- As a <role>, I want <feature> so that <value>

## Acceptance Criteria
- The feature is done when...

## Out of Scope
- What we are NOT doing

## Technical Constraints
- Known constraints and dependencies

## Open Questions
- [ ] Any unknowns that need research
```

### 3. Evaluate Next Step
- If there are open questions or unknowns → recommend `/feature-research` (F3)
- If the spec is clear and complete → recommend `/feature-plan` (F4)

**STOP** after creating the spec. Do NOT start planning or implementing.

**User Request:** {{args}}
