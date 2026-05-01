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
- **F30 → product-finalize:** No tech debt AND `docs/product/wbs.md` exists with all WPs `[x]` → tell user to run `/product-finalize`

## Procedure

### 1. Update Documentation
- Update relevant docs to reflect the new feature (API docs, setup guides, etc.)
- Update the project `CLAUDE.md` (root) if new patterns or critical rules were discovered
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

### 3b. Retrospect + Communicate (required — two separate outputs)

These two steps are mandatory before the tech debt assessment, regardless of whether learnings occurred.

**Output A — Retrospect artifact:** Write a short retrospect in the WIP file before archiving it:

```markdown
## Retrospect
- **What changed in our understanding:** <what we learned that we didn't know at the start>
- **Assumptions that held:** <what we got right>
- **Assumptions that were wrong:** <what surprised us>
- **Approach delta:** <how the actual implementation differed from the plan, if at all>
```

If the feature was delivered exactly as planned with no surprises, record that explicitly ("No surprises — implementation matched plan exactly"). Do not skip this section.

**Output B — Communicate step:** Confirm that the requester knows the feature is done and what it does. Produce a brief closure message suitable for sharing:

> **Feature complete:** [Feature name] has shipped. [One sentence: what it does]. [One sentence: how to verify or where to see it in action, if applicable.]

If the requester is the same person running the agent (solo developer), note it as: "Requester = operator — closure notice for self-record."

### 4. Tech Debt Assessment
Review the implementation for tech debt:
- Code that works but could be cleaner
- Patterns that should be standardized
- Performance improvements deferred during build

**If tech debt exists (F18):**
- List the specific items
- Tell user to run `/feature-refactor` to address them

**If no tech debt — check WBS completion (F19 vs F30):**

Check whether `docs/product/wbs.md` exists and all work packages are marked `[x]`:
- **WBS exists and all WPs `[x]` (F30):** The entire product cycle is complete. Tell user: "Feature complete and WBS fully done. Run `/product-finalize` to resync architecture docs, sweep the backlog, and archive the completed product cycle."
- **No WBS, or WBS has incomplete WPs (F19):** Feature is done but product cycle continues. Tell user: "Feature complete. Running reflection..." and recommend `/session-reflect`

**Feature Name:** {{args}}
