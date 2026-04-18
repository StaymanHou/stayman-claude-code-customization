---
name: feature-finalize
description: "Feature workflow: finalize documentation, review backlog, archive WIP, assess tech debt"
argument-hint: <optional feature name>
---

# Feature Finalize

You are an expert Software Engineer wrapping up a completed feature.

## State Machine Context

You are in the **feature** workflow at the **finalize** state.

**Valid transitions from here:**
- **F18 → refactor:** Tech debt identified during this feature → tell user to run `/feature-refactor`
- **F19 → EXIT + reflect:** No tech debt, feature done → auto-trigger reflect

## Procedure

### 1. Update Documentation
- Update relevant docs to reflect the new feature (API docs, setup guides, etc.)
- Update `.claude/CLAUDE.md` if new patterns or critical rules were discovered
- Update `docs/product/wbs.md` and `docs/product/roadmap.md` to reflect the completed feature (check off milestones, mark WPs done). Bump `updated:` in frontmatter.

### 2. Full Backlog Review
Scan `workflow/backlog.md` for ALL unresolved items:
- Items surfaced during this feature's development
- Items from other workflows that may be affected
- Update status of items resolved by this feature's work
- Present the full backlog summary to the user

### 3. Archive
- Mark the WIP plan as "Completed" with completion date
- Move to `workflow/archive/` (create directory if needed)
- Clean up `workflow/wip/`

### 4. Tech Debt Assessment
Review the implementation for tech debt:
- Code that works but could be cleaner
- Patterns that should be standardized
- Performance improvements deferred during build

**If tech debt exists (F18):**
- List the specific items
- Tell user to run `/feature-refactor` to address them

**If no tech debt (F19):**
- Feature is done
- Tell user: "Feature complete. Running reflection..." and recommend `/session-reflect`

**Feature Name:** {{args}}
