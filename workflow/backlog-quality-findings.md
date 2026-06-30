# Backlog — Code-Quality Review Findings

This file holds MINOR findings auto-backlogged by `feature-review-quality` runs. The parent `workflow/backlog.md` keeps **one pointer entry per feature** referencing this file. Convention adopted 2026-06-12 to avoid backlog volume noise — see `SURFACE-2026-06-12-ADJUST-QUALITY-AGENT-USE-DEDICATED-FILE` in `backlog.md` for the agent-config followup that codifies this shape.

Items are grouped by source feature. Within each group, each finding keeps the full SURFACE block produced by the reviewer subagent.

---

_(empty — all queued findings resolved by the sweep-quality-findings-2026-06-13 task; see `CHANGELOG.md` for the per-SURFACE-ID resolution entries. Future `feature-review-quality` runs append new sections below.)_

# claude-md-compaction — 2026-06-13

## SURFACE-2026-06-13-QUALITY-CATEGORY-HEADING-DRIFT
- **Source:** feature-review-quality (claude-md-compaction ship a96384a)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** `skills/util-prune-claude-md/SKILL.md:11` uses heading `## Category` while the `debug-*` precedent skills (`skills/debug-bisect-known-good/SKILL.md:11`, `skills/debug-empirical-telemetry/SKILL.md:11`) use `## Category Context`. Cross-category heading drift makes future grep-based audits ("show me every skill's category statement") miss this one.
- **Context:** The new util-* subsection in `docs/product/arch.md:224` doesn't formally require either shape; the drift is silent until a maintainer tries to grep across categories. Two acceptable fixes: (a) rename to `## Category Context` to match precedent, or (b) document the intentional difference in arch.md's util-* subsection.
- **Suggested action:** Pick option (a) — rename to `## Category Context` for grep-symmetry. 1-line edit.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-13-QUALITY-LESSON-FILE-SCHEMA-AMBIGUOUS
- **Source:** feature-review-quality (claude-md-compaction ship a96384a)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** With 9 files in `docs/lessons/` now using 3 different heading structures (precedent 3-file shape `## Practical application` + `## Instance`; this feature's new shape `## Mechanical recipe` + `## Discipline 1` + `## Discipline 2` in `debug-skill-template.md`; `## 1.` / `## 2.` / `## 3.` in `test-scenario-routing-forks.md`; `## Practical impact` + `## Discipline at plan time` in `harness-bootstrap-skip.md`), a future "what's the lesson-file schema?" reader has to derive it from N files rather than read it once.
- **Context:** Content shape may justify the variance, but the schema is now ambiguous. Two acceptable fixes: (a) conform new files to the precedent two-section shape, or (b) write a single-line schema statement at `docs/lessons/README.md` declaring "h1 title + topical sections, no YAML frontmatter, no strict schema".
- **Suggested action:** Pick (b) — write `docs/lessons/README.md` with the open schema statement. Closes the ambiguity with minimal disruption to existing files.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-13-QUALITY-ARCH-INLINE-COMMENT-REDUNDANT
- **Source:** feature-review-quality (claude-md-compaction ship a96384a)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** `docs/product/arch.md:6` has an inline HTML comment `<!-- 2026-06-13 second edit (same day): added \`### util-* skill category\` subsection under Revision 2026-06-13. updated: unchanged (same calendar day). -->` documenting a same-day second edit. Adjacent same-day edits in other features have not adopted this convention; the Revision-section discipline already provides a date-stamped narrative anchor.
- **Context:** The audit-trail intent is fine, but the inline comment is redundant signal — any further same-day edit either has to nest or be removed. Weak signal.
- **Suggested action:** Remove the line. 1-line deletion. Captures the convention going forward: "if you need to mark a same-day re-edit, use the Revision section itself, not file-top HTML comments."
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-13-QUALITY-YAML-PIN-PLACEMENT-NOTE
- **Source:** feature-review-quality (claude-md-compaction ship a96384a)
- **Target level:** workflow:task
- **Type:** gap (refinement of SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN)
- **Summary:** The existing SURFACE for the YAML-parse pin in `workflow/backlog.md` suggests "Add a new Phase to `tests/check-structure.sh`", but a Phase N+1 addition at the current tail would conflict with the close-commit discipline pin block (current Phase 11). The pin should land between existing phases (e.g., as a Phase 3a addition to the existing frontmatter-validation pass), not as a tail phase.
- **Context:** Note for when the operator picks up SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN — placement matters for the structural-test PASS count sequence and for not visually orphaning the close-commit Phase 11 block.
- **Suggested action:** Cross-reference this note inside the parent SURFACE's "Suggested action" field, or merge this finding into the parent SURFACE as a placement-detail addendum.
- **Priority:** low
- **Status:** pending

# docker-daemon-vs-container-distinction — 2026-06-19

## SURFACE-2026-06-19-QUALITY-CONTAINER-DOWN-PIN-OVER-BROAD
- **Source:** feature-review-quality (docker-daemon-vs-container-distinction ship aef35a2)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** The container-down structural pin at `tests/check-structure.sh:176` matches `containers are down|docker compose up`, but `docker compose up` may also appear in unrelated allowed-list/bootstrap prose in the same Variant-A template. The OR-branch means the pin could pass on the wrong line if the new self-start clause is ever deleted while a stray `docker compose up` survives — a slightly leaky regression net.
- **Context:** The pin's value is catching accidental removal of the new container-down branch specifically; the broad alternation weakens that guarantee. Low-stakes because the sibling daemon-unreachable pin still anchors the section's presence.
- **Suggested action:** Tighten the pin to a more distinctive anchor such as `start the container\(s\) yourself`, tying it to the actual new clause. 1-line edit to the grep_check pattern.
- **Priority:** low
- **Status:** pending

# debug-minimal-harness — 2026-06-23

## SURFACE-2026-06-23-QUALITY-MINHARNESS-GATEMET-IDIOM-DIVERGENCE
- **Source:** feature:review-quality (debug-minimal-harness, ship commit efba0ca)
- **Type:** tech-debt (idiom divergence)
- **Summary:** `DEBUG-MINHARNESS-GATE-MET` in tests/scenarios/debug.yaml uses `transition_id_any: [START, COMPLETE]` while both sibling GATE-MET scenarios (DEBUG-TELEMETRY-GATE-MET, DEBUG-BISECT-GATE-MET) assert a strict single `*-START`. Justified + inline-commented, but a maintainer normalizing the three GATE-MET scenarios might not notice this one is intentionally looser.
- **Suggested action:** Consider whether the two sibling GATE-MET scenarios should ALSO widen to `transition_id_any` (a capable model runs any of the three techniques to COMPLETE on a gates-met fixture) — would unify the idiom. Or leave as-is; the inline comment is the safeguard.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-23-QUALITY-MINHARNESS-ROUND-THRESHOLD-NOTE
- **Source:** feature:review-quality (debug-minimal-harness, ship commit efba0ca)
- **Type:** tech-debt (cosmetic prose)
- **Summary:** skills/debug-minimal-harness/SKILL.md Termination note says "5+ rounds" for optional WIP traceability notes while §6/inconclusive keys on "≥3 rounds" — internally consistent with sibling precedent (telemetry uses the same 3-vs-5 split) but a reader may briefly trip on the differing thresholds.
- **Suggested action:** Optional one-line clarification that the 3-round threshold is for inconclusive-escalation and the 5-round threshold is for optional traceability notes (two different purposes). Matches sibling precedent, so low value.
- **Priority:** low
- **Status:** pending

# design-priors — 2026-06-26

## SURFACE-2026-06-26-QUALITY-CONSULT-SCENARIOS-PROMPT-LEAKAGE
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Target level:** workflow:task (test-harness coverage)
- **Type:** tech-debt (test coverage)
- **Summary:** The DP-consult-* scenarios in `tests/scenarios/product.yaml` encode the expected answer in `system_prompt_extra` (e.g. "do NOT cite or stretch an audience prior onto a copy-tone decision"; "surface this as a PROPOSAL ... do NOT silently add ... do NOT silently drop"). This tests "does the model obey an instruction just handed to it" more than "does the consult contract in the SKILL.md produce the behavior." The over-infer guard is the feature's headline anti-overfit claim; a scenario that pre-states the guard's conclusion could pass even if the skill prose were deleted.
- **Context:** Residual signal survives — the model must still emit/withhold the `PRIOR: P` disclosure correctly and strict `not_contains` catches over-firing — so this is a coverage weakness, not a broken test. NOTE: the operator independently raised this exact concern at P2 verify-human ("scenarios are what really matters rather than me eyeballing"); the prompt-leakage limits how much the scenarios deliver on that.
- **Suggested action:** Strengthen the consult scenarios to present the decision context *neutrally* (state the open product-design question + that a design-priors.md exists, WITHOUT pre-stating whether/how a prior should fire) and let the loaded SKILL.md consult contract drive the outcome. Pairs naturally with the `SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE` harness work. Property-test per docs/lessons/test-harness-primitives.md.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-06-26-QUALITY-STEP0-ON-NON-ENTRY-SKILLS
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Target level:** workflow:task
- **Type:** tech-debt (doc-surface consistency)
- **Summary:** `product-roadmap` and `product-wbs` gained `## Step 0: Available product context` sections, but neither is an entry-point skill — the `transitions.md` entry-point list and the `check-structure.sh` Phase-3 Step-0-presence pins enumerate only `task-plan, feature-spec, feature-plan, feature-reproduce, incident-report, product-vision`. The new Step-0 headings are unguarded by the Step-0-presence pin and overload the "Step 0 = entry-point product-context load" convention to also mean "any consult point." The CLAUDE.snippet.md per-skill mapping now lists product-roadmap/product-wbs as eager-read consulters without the transitions.md entry-point prose being updated to match.
- **Context:** Phase 13 pins the `design-priors.md` substring in both files, so the consult block won't silently vanish; the gap is narrowly the `## Step 0` heading-convention overload + the transitions.md/snippet mapping mismatch. Two fixes: (a) rename the design-priors consult block in roadmap/wbs to a non-"Step 0" heading (e.g. `## Design-priors consult`), keeping "Step 0" reserved for entry points; or (b) broaden the documented "Step 0" convention in transitions.md + CLAUDE.snippet.md to explicitly include mid-workflow consult points.
- **Suggested action:** Prefer (a) for minimal convention disruption — rename to a distinct heading; update the Phase-13 pins to match. Small task.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-06-26-QUALITY-PROPOSE-PIN-TOO-LOOSE
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Type:** tech-debt (cosmetic / pin precision)
- **Summary:** The Phase-13 `propose` pins in `tests/check-structure.sh` grep the bare lowercased substring `propose` (min_count 1), firing on any occurrence — so they cannot detect a capture block that kept the word but lost the `never-auto-write` qualifier. The adjacent comment calls it "the load-bearing over-capture guard," which the pin under-delivers on.
- **Suggested action:** Pin `propose-never-auto-write` (the actual contract phrase, present in all 6 capture skills) instead of bare `propose`. 6 one-line pattern edits.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-26-QUALITY-CORPUS-OPEN-QUESTIONS-STALE
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Type:** tech-debt (cosmetic doc)
- **Summary:** `docs/lessons/design-priors-corpus.md` ships its "Open questions for Stayman" section with Q1/Q2 as open prompts ("My lean: …") even though the curated preamble states Q1/Q2 were resolved by the operator. A future reader sees questions the doc's own header says are closed.
- **Suggested action:** Mark Q1 (arch-boundary → ARCH) and Q2 (preserve why-gap → yes) RESOLVED inline. Trivial edit.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-26-QUALITY-FIXTURE-USES-PHASE-ALIAS
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Type:** tech-debt (cosmetic)
- **Summary:** `tests/fixtures/product/design-priors-consult/roadmap.md` uses "Phase 1/2/3" (the backward-compat read-alias) for the roadmap unit rather than the current "Milestone" terminology. Cosmetic and consistent with the pre-existing `roadmap-done` fixture it was copied from (so not new drift), but new fixtures could model current terminology.
- **Suggested action:** Optionally rename to "Milestone" in the new fixture; or bundle with a broader fixture-terminology refresh. Lowest priority.
- **Priority:** low
- **Status:** pending

# util-backlog-paydown — 2026-06-30

## SURFACE-2026-06-30-QUALITY-UTIL-PAYDOWN-BURY-SCENARIO-MISSING
- **Priority:** medium
- **Severity:** MAJOR (feature-review-quality, ship aa5c831)
- **Finding:** `tests/scenarios/util.yaml` covers Sweep / Discuss / Defer / Delete but not **Bury** (the 5th action), despite the fixture `tests/fixtures/backlog/sweep-mixed.md` authoring `MEH-1` (`impact: low · effort: medium · risk: low`) as the exact canonical Bury case. Bury is the most-confabulated "meh middle" disposition and has zero behavioral coverage.
- **Pickup shape:** add one scenario `UTIL-PAYDOWN-MEH-BURY` to `tests/scenarios/util.yaml` focusing the disposition on `MEH-1`, `contains_any: [Bury, meh, archived backlog]`. Fixture item already exists — ~5 min. Run `./tests/run-tests.sh --group util`.

## SURFACE-2026-06-30-QUALITY-UTIL-PAYDOWN-GRAMMAR-AN-A
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship aa5c831)
- **Finding:** `skills/util-backlog-paydown/SKILL.md` Rule-1 parenthetical reads `An "carve out an exception…"` — should be `A "carve out…"`. Cosmetic; sits on the load-bearing Rule-1-no-exception why.
- **Pickup shape:** one-word edit.

## SURFACE-2026-06-30-QUALITY-UTIL-PAYDOWN-ORDERING-NESTING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship aa5c831)
- **Finding:** `skills/util-backlog-paydown/SKILL.md` ordering-rules list nests the cross-cutting "Risk outranks impact in ordering" clarification under rule 5 ("Effort is NOT an ordering key"). Faithful to the learning doc's structure but a literal reader may be momentarily confused. Consider promoting to a top-level note (would also be worth fixing in `docs/lessons/between-milestone-debt-paydown-sweep.md` for consistency).
- **Pickup shape:** restructure the ordering list (skill + lesson).
