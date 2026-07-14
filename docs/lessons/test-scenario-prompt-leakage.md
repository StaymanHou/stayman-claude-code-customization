# A scenario that tests SKILL.md prose must not recite the answer in its prompt

When a test scenario's purpose is to verify that a skill's *prose* carries a behavior
(the design-priors consult contract, an over-infer guard, a triage discipline), its
`system_prompt_extra` must present the decision context **neutrally** — state the open
question and the relevant environmental facts, then let the loaded SKILL.md drive the
outcome. It must NOT recite the expected answer or the rule the skill is supposed to
supply.

A prompt that says "apply the consult-weighting rules; disclose the firing prior" or
"per the over-infer guard, a prior only fires on the axis it governs" tests whether the
model *obeys an instruction just handed to it* — not whether the skill prose produces the
behavior. Such a scenario would keep passing even if the skill prose were deleted, so it
gives false confidence in exactly the property it claims to protect.

## Practical application

Before writing a `system_prompt_extra` for a prose-behavior scenario, ask: "would this
still pass if the SKILL.md section under test were removed?" If yes, the prompt is leaking
the answer — strip it down to the open question + environmental facts. Assertions
(`contains_required_any`, `not_contains`) stay; they observe the outcome without dictating it.

## Instance

Caught 2026-06-26 (SURFACE-2026-06-26-QUALITY-CONSULT-SCENARIOS-PROMPT-LEAKAGE), fixed in
WP6 of the backlog-paydown-2026-07-13 sweep (2026-07-14). The 4 `DP-consult-*` scenarios
recited their own answers ("disclose the firing prior", "do NOT cite or stretch",
"surface as a PROPOSAL"). Rewritten to pose only the open product-design question + note
that a `design-priors.md` is present; all 4 then passed 4/4 on haiku, first attempt —
confirming the loaded `product-wbs`/`product-roadmap` consult contract genuinely carries
the behavior. Distinct from `test-scenario-strict-mode.md` (about `not_contains` fragility)
and `test-scenario-routing-forks.md` (about fixture/routing shape).
