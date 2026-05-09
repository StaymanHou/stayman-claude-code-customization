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

**Bug-fix discoverability:** If `{{args}}` describes an undesirable behavior (bug, regression, broken state, wrong output) and you have not been entered via F32/F34 from `feature-reproduce`, surface a one-line suggestion to the user: "If this describes a bug-fix or regression and you haven't run reproduction, consider running `/feature-reproduce` first to capture a failing test before specifying the fix." Then proceed with spec — this is a soft pointer, not a gate.

## Procedure

### 1. Elicit Requirements
- Ask the user questions to clarify scope, user persona, and success criteria
- Identify technical and business constraints
- If this came from a SURFACE-IN (F28: task escalated to feature), read the source task's WIP file for context

### 2. 3rd-Party Probe Check

Before writing the spec, check whether this feature depends on any 3rd-party service, external API, or SDK (e.g. Stripe, Twilio, SendGrid, AWS, Google Maps, an OAuth provider, any API you don't own).

**If a 3rd-party dependency is present:**
1. Check `docs/product/wbs.md` (if it exists) for a completed Probe WP covering that integration.
2. If no probe WP exists or none is marked complete — this is a **known unknown**. Flag it explicitly:

> ⚠️ **Known unknown — probe required before planning**
> This feature depends on [service/API name], but no completed probe WP exists for it. The API's request/response shapes, auth model, rate limits, and error codes are unverified assumptions.
> **Recommended action:** Run a spike task first to document the integration's I/O shapes. Then return to `/feature-spec` with that knowledge in hand.
> If you want to proceed anyway, note that the plan may need significant revision once the probe is complete.

3. If a completed probe WP exists — note it in the spec under **Technical Constraints** and proceed.

**If no 3rd-party dependency is present:** skip this step and continue.

### 3. Create Specification
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

### 4. Evaluate Next Step
- If there are open questions or unknowns → recommend `/feature-research` (F3)
- If the spec is clear and complete → recommend `/feature-plan` (F4)

**Single-step mode only:** STOP after creating the spec — do NOT start planning or implementing. In orchestrated/autopilot/full-autopilot modes the orchestrator chains to the next step automatically based on the drive mode's pause policy.

**User Request:** {{args}}
