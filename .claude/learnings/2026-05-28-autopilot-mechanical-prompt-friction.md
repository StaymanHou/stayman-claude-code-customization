---
date: 2026-05-28
scope: global
type: Context Rule
session-ref: claude-time-visualize-v3 WP1 ship (commit 4dd8d6d → 98e390e)
---

# Autopilot: structurally eliminate mechanical user prompts whose answer is determined by an objective gate

## Summary
Observed during v3 WP1 (2026-05-28): in autopilot mode, both Phase 1 and Phase 2 hit `feature-verify-human`, where the skill's §2 integration-boundary check had objectively determined "no boundary applies." The skill still paused and presented an affirmation block asking "do you agree to skip to verify-codify?" — and both times the user typed "skip." The "skip" answer was mechanical (determined by the objective gate plus drive_mode = autopilot), not a judgment call. At v3's expected ~10 WPs × 2–4 phases each, that's 30+ mechanical prompts per cycle. The meta-rule: **in autopilot, when a user-facing decision is fully determined by gates already encoded in the skill procedure, auto-resolve it instead of surfacing.** Surface the decision *in chat* for read-time veto, but don't hold the workflow waiting on a predictable one-word reply.

## Suggested change

CLAUDE.md rule (global, harness — `~/.claude/CLAUDE.md` under the "Workflow System" section or as a sibling block):

> **Autopilot decision auto-resolution rule.** When a workflow skill in autopilot or full-autopilot mode reaches a user-pause point whose answer is fully determined by an objective gate the skill has already evaluated (e.g. integration-boundary check, verify-self all-PASS, no failure-triage entries), the skill MUST auto-resolve the pause along the gate-determined path. The skill should still emit the affirmation or summary block in chat for the user's read-time veto, but MUST NOT wait for a reply. Mode 1 (step-by-step) and Mode 2 (orchestrated) retain the user-pause; Modes 3 and 4 auto-resolve.

A canonical instance — feature-verify-human's F11 skip in Modes 3–4 when (a) no integration boundary applies AND (b) verify-self had no FAILED, FAILED-cosmetic, or UNVERIFIED leaves — should auto-fire without a "do you agree?" prompt.

## Session-log excerpt
"## Phase 1 — Integration-boundary affirmation. This phase does NOT wire into any existing HTTP endpoint, route, UI page, CLI command, scheduled job, or external-system call. It only adds isolated new artifacts: [...] Given that affirmation, do you agree to skip Phase 1's verify-human to verify-codify?" — user: "skip". Repeated verbatim for Phase 2.

## Related
Backlog: `SURFACE-2026-05-28-VERIFY-HUMAN-AUTO-SKIP-WHEN-NO-INTEGRATION-BOUNDARY` (medium, this repo's backlog) is the concrete fix proposal for the F11 case. This learning generalizes the principle so other autopilot-pause surfaces can be audited against the same rule.
