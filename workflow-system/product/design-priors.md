---
stage: design-priors
state: in-progress
updated: 2026-11-04
---

# Design Priors — my-claude-code-customization

<!-- Schema: workflow-system/product/arch.md → "File Schema: Design Priors Format".
     This repo's OWN dogfood priors (operator decision 2026-11-04). It is state for this repo's planning
     skills, not a shipped default for consuming projects. -->

## P-LIVE-SETTING — live host setting vs. recorded snapshot
- **axis:** when the environment reports an operator setting live (e.g. Claudesk's per-workspace drive mode) and the workflow also holds a recorded value (handoff pointer, WIP field), which one governs
- **lean:** the live setting governs; recorded copies defer to it (e.g. `drive_mode: from-claudesk`) instead of competing. Does not override an explicit in-conversation instruction, a tour run's pinned mode, or the incident Mode-2 rule.
- **inferred-why:** the operator changes the live setting deliberately and at any time; a recorded value is a snapshot from an earlier moment, so obeying it silently overrides the operator's latest intent
- **date:** 2026-11-04 (decided 2026-11-03 at drive-mode-picker-select-ui P1.verify-human.2 + the handoff-marker extension; operator confirmed the inferred-why)
