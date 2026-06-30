---
date: 2026-06-30
scope: global
type: Context Rule
session-ref: util-backlog-paydown feature (skill-codification)
---

# Cross-validate a proposed model/rule against prior REAL sessions before codifying it

## Summary
When codifying any recurring operator process into a skill or rule (adding or changing a workflow
skill, a disposition model, a scoring rubric, a triage heuristic), do not ship the model on
plausibility alone. **Locate the operator's actual past instances of the process across the whole
machine** — `~/.claude/projects/*/*.jsonl` session transcripts AND archived artifacts
(`docs/product/*-wbs.md`, `workflow/archive/`, CHANGELOG entries) across **all** projects, not just
the current one — and check whether the proposed model **predicts** the real include/exclude/disposition
choices those sessions actually made. Where it diverges, the model is wrong or incomplete → refine
before shipping. The located prior sessions become the model's **regression suite**: encode
generalized/redacted cases as behavioral test scenarios.

Emerged 2026-06-30 codifying `util-backlog-paydown`. The hand-off doc explicitly directed finding a
second real session; the search surfaced replicator-1-0's *five-sweep family* (the doc said "two
sessions"). The disposition model predicted ~100% of the real dispositions across ~16 items — strong
confidence it wasn't just a nice-sounding model. The one divergence (a "Defer" the operator actually
Swept) revealed that the model's predictive power was *conditional on a human-supplied impact reframe* —
a real refinement the raw cross-check exposed that plausibility-checking would have missed.

## Suggested change
**CLAUDE.md rule (global), or a discipline added to the skill-add recipe (`docs/lessons/debug-skill-template.md`
and any future skill-codification recipe):**

> **Cross-validate against prior real sessions before codifying a model/rule.** Before shipping a skill
> or rule that encodes a recurring operator process, search the machine's session transcripts
> (`~/.claude/projects/*/*.jsonl`) and archived artifacts across ALL projects for the operator's actual
> past instances of that process. Verify the proposed model *predicts* their real choices; refine where
> it diverges; encode the located cases (generalized/redacted) as the regression-test suite. A model
> that has never been checked against real prior behavior is unvalidated.

Two attached nuances:
1. **Generalize/redact** when turning a real prior session into a test fixture — strip real file paths,
   component names, SURFACE IDs, project identifiers (done here: `tests/fixtures/backlog/sweep-mixed.md`).
2. **Surface the cross-validation result to the operator for an eyeball, don't self-certify.** Even a
   "clean" cross-check should be shown — the one divergence in this session (the conditional-impact
   reframe) is exactly the kind of thing the operator should rule on, not the agent. In this session the
   raw result was summarized but not presented for a ruling until the operator asked; surface it
   proactively next time.

## Session-log excerpt (optional)
Operator at wrap-up: "you haven't let me eyeball the cross-validation result for the current skill being
developed. That was all good and nothing needed my attention?" — confirming the surface-for-ruling nuance
above is a real gap worth codifying, not a hypothetical.
