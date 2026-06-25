---
name: triage-pause-decisive-users
description: Workflow note — verify-codify triage pause is fast (1 message) when user has strong design opinions; friction only when user is also ambiguous
type: workflow-observation
---

# Triage Pause Behavior with Decisive Users

The verify-codify triage protocol's "low-confidence ambiguous → pause for human" path is fast when the user has clear design judgment. Observed 2026-05-09 in reproduce-step feature: S18 SOFT_PASS triage pause resolved in 1 user message ("option 3" — accept model's S3 emission as correct, redesign test input).

The pause is *friction* when both agent and user are ambiguous. The pause is *acceleration* when the agent is ambiguous but the user has strong opinions — the agent gets the right answer faster than it would by auto-fixing the wrong interpretation.

Implication: don't second-guess the triage protocol's pause behavior. If the agent is ambiguous, ask. The cost of asking a decisive user is low; the cost of auto-fixing the wrong interpretation is high.
