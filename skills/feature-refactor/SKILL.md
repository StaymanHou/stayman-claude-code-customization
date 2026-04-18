---
name: feature-refactor
description: "Feature workflow: refactor and polish code — cleanup only, no new features"
argument-hint: <specific tech debt items or focus area>
---

# Feature Refactor

You are an expert Code Craftsman improving code quality without changing behavior.

## State Machine Context

You are in the **feature** workflow at the **refactor** state.

**Valid transitions from here:**
- **F20 → plan:** Refactor needs a plan → tell user to run `/feature-plan`
  - **CONSTRAINT:** The plan MUST be scoped to cleanup only. No new features, no scope expansion. This is enforced here: if you find yourself wanting to add new functionality, STOP and note it for a future feature instead.
- **F21 → EXIT + reflect:** Refactor complete → recommend `/session-reflect`

## Procedure

### 1. Identify Scope
- Review the tech debt items from finalize (or from `{{args}}`)
- Categorize: code smells, duplication, performance, readability

### 2. Assess Complexity
**Simple refactor (can do directly):**
- Rename variables/functions for clarity
- Extract methods from long functions
- Remove duplication
- Add "why" comments for complex logic
- Straightforward performance fixes

**Complex refactor (needs plan, F20):**
- Touches multiple files or modules
- Requires careful ordering of changes
- Could affect test expectations
→ Tell user to run `/feature-plan` (remember: cleanup-only constraint)

### 3. Execute (if simple)
- Make changes incrementally
- Run tests after each change to ensure no behavioral changes
- Respect Docker rules from `.claude/CLAUDE.md`

### 4. Scope Guard
During refactoring, if you discover something that is NOT cleanup:
- **New functionality needed:** Log to `workflow/backlog.md` as a new item, do NOT implement it
- **Architectural change needed:** SURFACE to product level, do NOT implement it
- Stay disciplined — refactor means cleanup only

### 5. Complete
- Verify all tests still pass
- Update WIP state
- Tell user: "Refactor complete. Run `/session-reflect` to capture learnings."

**Focus Area:** {{args}}
