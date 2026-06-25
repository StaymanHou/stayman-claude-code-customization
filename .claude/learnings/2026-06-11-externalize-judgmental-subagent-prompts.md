---
date: 2026-06-11
scope: global
type: Context Rule
session-ref: code-quality-reviewer-subagent feature ship
---

# Externalize reviewer-style / judgmental subagent prompts at ~50+ lines

## Summary

When a subagent prompt's job is *judgment* (criteria + calibration anchors + grounding context — teaching the subagent how to think about a domain) rather than *procedure* (tool-by-tool recipe + structured output), the prompt scales past inline-comfortable quickly. Inline-shaped prompts run 20–50 lines (e.g. `feature-verify-self`'s ~30-line Playwright observation procedure); externalized-shaped prompts run 100–200+ lines once criteria + output format + calibration are codified. The practical heuristic is **"does the prompt include calibration examples?"** — if yes, externalize from the start; do not try to inline-then-extract later.

Externalization unlocks two free downstream benefits: (a) the prompt becomes a discrete pressure-testable artifact (planted-bug fixtures can feed the externalized prompt directly without invoking the SKILL.md procedure); (b) prompt iterations show in git history distinctly from procedure iterations.

## Suggested change

**CLAUDE.md rule (global), under "Using your tools" or a new "Subagent prompt conventions" section:**

> **Externalize judgmental subagent prompts.** Subagent prompts whose job is *judgment* — criteria-list + calibration anchors + grounding context — externalize at ~50+ lines (especially when calibration examples are present). Procedural subagent prompts (tool-by-tool execution recipe + structured output template) stay inline. Pattern precedent: `skills/feature-review-quality/reviewer-prompt.md` (148 lines, 2026-06-11). Comparative reference: superpowers' `skills/subagent-driven-development/code-quality-reviewer-prompt.md` (~200 lines).
>
> **Heuristic:** "Does the prompt include calibration examples (good/bad/wrong-severity findings)?" If yes, externalize. Calibration anchors are the load-bearing content that pushes prompts past inline-comfortable; they're also the content that benefits most from independent pressure-testing.
>
> **Not yet enforced structurally** — no check-structure.sh pin for "skill X requires sibling reviewer-prompt.md". When a second judgmental-subagent skill ships (rule-of-two), consider codifying.

## Session-log excerpt

Initial OQ-3 recommendation at spec time was "inline the reviewer prompt like verify-self does" — convention consistency. The flip came from a focused superpowers deep-read finding the equivalent prompt at ~200 lines externalized as a separate `.md` file. The verify-self comparison made the threshold concrete: a 200-line block dwarfs SKILL.md procedure; ~30 lines doesn't. Threshold: ~50 lines (or first calibration example, whichever comes first).
