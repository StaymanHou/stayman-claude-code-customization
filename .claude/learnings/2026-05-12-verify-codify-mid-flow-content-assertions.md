---
date: 2026-05-12
scope: global
type: Context Rule
session-ref: session-start-suggest-from-backlog feature, verify-codify phase
---

# Verify-codify scenarios for mid-skill-flow behavior should use content-only assertions

## Summary
When a verify-codify scenario tests a path where the skill pauses for user input mid-flow (e.g., session-start at the drive-mode menu, or any skill that surfaces a list and waits for selection), the model does NOT emit a `TRANSITION:` token — because no transition has fired yet; the skill is stopped waiting on the user. Asserting `transition_id` on such scenarios produces false FAILs. The correct shape is `contains_any` / `not_contains` (with `not_contains_strict: true` if needed) and **no transition assertion**. The harness's SOFT_PASS status is the *intended* result for these scenarios, not a degradation.

## Suggested change
CLAUDE.md rule (in `my-claude-code-customization`, under the `## Conventions` section's bullet list near the existing "Test scenario design — routing-fork patterns:" bullet):

> **Test scenario design — mid-flow scenarios:** When a scenario exercises a skill path that pauses for user input *before* classification or before any transition fires, do not assert `transition_id`. Use `contains_any` (and `not_contains` / `not_contains_strict` for negative checks) and accept SOFT_PASS as the intended status. Examples: session-start under empty-args (stops at backlog-surfacing or drive-mode menu), any skill that surfaces a pickable list and waits for selection. The `TRANSITION: <id>` token is only emitted *after* the skill has decided on a next state; mid-flow scenarios cannot satisfy that contract.

## Session-log excerpt
S22 + S23 (session-start backlog-surfacing) — both SOFT_PASS because the empty-args path stops mid-flow at the drive-mode menu before any classification. Content match confirms behavior correctness; no transition is emitted because none has fired.
