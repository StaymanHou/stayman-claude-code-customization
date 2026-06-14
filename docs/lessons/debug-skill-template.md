# Adding a new `debug-*` sibling skill — reusable template (and the category-level convention discipline behind it)

When introducing a new `debug-*` skill (the third, fourth, Nth after `debug-bisect-known-good` codified 2026-05-13 and `debug-empirical-telemetry` shipped 2026-06-10), mirror the precedent's shape across four artifact kinds. Beyond that mechanical recipe, this lesson also captures the two underlying disciplines that every *category-level* convention rollout needs.

## Mechanical recipe for a new `debug-*` skill

1. **SKILL.md scaffold.**
   - Frontmatter: `name`, `description`, `argument-hint`.
   - Six required sections in order: `## Category Context`, `## When to use` (conjunctive gates marked "AND, not OR"), `## When NOT to use` (explicit non-applicability), `## Procedure` (with `### 1. Gate Check` as the first subheading), `## Pitfalls (load-bearing — read before <verb>)` (parenthetical-suffix heading convention), `## Termination` (table with `DEBUG-<TECHNIQUE>-<OUTCOME>` tokens + `RETURN-TO: <caller>` on every termination).

2. **3 fixtures under `tests/fixtures/wip/`.**
   - One **gates-met** fixture (clearly hits both conjunctive gates).
   - One **gate1-fails** fixture (first gate's SKIP path).
   - One **gate2-fails** fixture (second gate's SKIP path).

3. **3 scenarios in `tests/scenarios/debug.yaml`.**
   - Entry-state `<TECHNIQUE>-GATE-MET` asserting `transition_id: DEBUG-<TECHNIQUE>-START` + `contains_any` for procedure-anchor phrases. **NO aggressive `not_contains`** per the existing "Entry-state transitions need a different test shape than exit transitions" guidance.
   - 2 SKIP-exit scenarios asserting `transition_id: DEBUG-<TECHNIQUE>-SKIP` + `contains_any` for the failing-gate phrase + `not_contains: [DEBUG-<TECHNIQUE>-START, DEBUG-<TECHNIQUE>-COMPLETE]`.

4. **`tests/check-structure.sh` Phase 3c extension.**
   - 7 new `grep_check` calls: 3 caller-prose pins in `skills/feature-build|incident-investigate|task-act/SKILL.md` + 3 orchestrator-row pins in `agents/feature-workflow|incident-workflow|task-workflow/AGENTS.md` + 1 mention in `docs/product/transitions.md`. Caller-prose mentions are sibling paragraphs added inside each caller skill's existing `### Xb. Debug-technique Sidebar (optional)` section — not new sections.

**PASS count projection.** Phase 3b's iterating `for debug_skill in skills/debug-*/SKILL.md` loop auto-adds 9 PASSes per new skill (post-2026-06-12 extension: 2 gate-boundary headings + 4 other required sections + `argument-hint:` frontmatter + Gate-Check-first-subheading + ≥4 DEBUG-token regex). Post-feature delta = 9 (auto-iterate) + 7 (Phase 3c explicit pins) = **+16 PASS per new debug-* skill** — useful for projecting post-ship structural-test counts at plan time.

## Discipline 1 — A new skill category needs three structurally-enforced discoverability surfaces, not one

When introducing a category-level convention (the `debug-*` category, or any future `<prefix>-*` family), the agent that ultimately invokes the skill reads only:
(a) its own SKILL.md, (b) the orchestrator's AGENTS.md, (c) the caller-skill's prose.

It does **NOT** read `CLAUDE.md` or `docs/product/transitions.md` at invocation time. So a category convention documented only in `CLAUDE.md` will not be discovered by the agent in practice. Structurally enforce all three surfaces and codify via `tests/check-structure.sh` so regression on any one is caught. The `CLAUDE.md` convention doc is the *author-facing* reference; the three structural surfaces are the *agent-facing* discoverability. Caught 2026-05-14 during the `debug-*` category feature.

## Discipline 2 — Category-level conventions need the harness's own marker, not just a documentation marker

Documentation in `CLAUDE.md` (e.g., "these are reference documents, not Agent-spawned subagents") doesn't constrain runtime invocation. The Claude Code harness registers entries under `~/.claude/agents/` and `~/.claude/skills/` by directory presence — frontmatter shape is invisible to it.

Concrete instance: until 2026-06-12, the 4 `agents/*-workflow/AGENTS.md` files were documented as reference-only, but the harness happily listed them as invokable `subagent_type` values, so any skill could have called `Agent({subagent_type: 'feature-workflow', ...})` and gotten an unexpected spawn.

The mitigation is dual: (a) a structural marker in a place the harness or `tests/check-structure.sh` can consult — typically frontmatter shape (e.g. `tools:` vs `skills:`) — AND (b) a `check-structure.sh` pin that enforces the marker. Without both, the convention is enforced only by social discipline.

The `verify-self-and-review-quality-subagent-dispatch` feature (2026-06-12) introduced `tools:` as the executable-subagent marker + the Phase 10 "Subagent dispatch wiring" pin block. **Discipline:** when introducing a category-level convention, ask "does the marker live where the harness or check-structure.sh can see it?" If not, the convention is doc-only and will erode. Also: enforce the marker **symmetrically** — both "agents with `tools:` must be referenced" AND "skill `subagent_type:` references must point to a `tools:`-marked agent" (see `SURFACE-2026-06-12-QUALITY-SUBAGENT-DISPATCH-PIN-ASYMMETRIC` for the symmetric back-reference that was omitted at first ship).
