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
- **Status:** resolved 2026-07-13 (backlog-paydown WP1). Resolved via option (b) NOT (a): renaming would erase the intentional util-*/debug-* category distinction (`## Category Context` is a *pinned debug-* requirement*; util-* has no pinned heading). Instead documented the intentional divergence in `docs/product/arch.md` util-* subsection.

## SURFACE-2026-06-13-QUALITY-LESSON-FILE-SCHEMA-AMBIGUOUS
- **Source:** feature-review-quality (claude-md-compaction ship a96384a)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** With 9 files in `docs/lessons/` now using 3 different heading structures (precedent 3-file shape `## Practical application` + `## Instance`; this feature's new shape `## Mechanical recipe` + `## Discipline 1` + `## Discipline 2` in `debug-skill-template.md`; `## 1.` / `## 2.` / `## 3.` in `test-scenario-routing-forks.md`; `## Practical impact` + `## Discipline at plan time` in `harness-bootstrap-skip.md`), a future "what's the lesson-file schema?" reader has to derive it from N files rather than read it once.
- **Context:** Content shape may justify the variance, but the schema is now ambiguous. Two acceptable fixes: (a) conform new files to the precedent two-section shape, or (b) write a single-line schema statement at `docs/lessons/README.md` declaring "h1 title + topical sections, no YAML frontmatter, no strict schema".
- **Suggested action:** Pick (b) — write `docs/lessons/README.md` with the open schema statement. Closes the ambiguity with minimal disruption to existing files.
- **Priority:** low
- **Status:** resolved 2026-07-13 (backlog-paydown WP1). Wrote `docs/lessons/README.md` with the open-schema statement (h1 title + topical sections, no frontmatter, no strict schema).

## SURFACE-2026-06-13-QUALITY-ARCH-INLINE-COMMENT-REDUNDANT
- **Source:** feature-review-quality (claude-md-compaction ship a96384a)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** `docs/product/arch.md:6` has an inline HTML comment `<!-- 2026-06-13 second edit (same day): added \`### util-* skill category\` subsection under Revision 2026-06-13. updated: unchanged (same calendar day). -->` documenting a same-day second edit. Adjacent same-day edits in other features have not adopted this convention; the Revision-section discipline already provides a date-stamped narrative anchor.
- **Context:** The audit-trail intent is fine, but the inline comment is redundant signal — any further same-day edit either has to nest or be removed. Weak signal.
- **Suggested action:** Remove the line. 1-line deletion. Captures the convention going forward: "if you need to mark a same-day re-edit, use the Revision section itself, not file-top HTML comments."
- **Priority:** low
- **Status:** resolved 2026-07-13 (backlog-paydown WP1). Deleted the redundant same-day-edit HTML comment at `docs/product/arch.md:6`.

## SURFACE-2026-06-13-QUALITY-YAML-PIN-PLACEMENT-NOTE
- **Source:** feature-review-quality (claude-md-compaction ship a96384a)
- **Target level:** workflow:task
- **Type:** gap (refinement of SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN)
- **Summary:** The existing SURFACE for the YAML-parse pin in `workflow/backlog.md` suggests "Add a new Phase to `tests/check-structure.sh`", but a Phase N+1 addition at the current tail would conflict with the close-commit discipline pin block (current Phase 11). The pin should land between existing phases (e.g., as a Phase 3a addition to the existing frontmatter-validation pass), not as a tail phase.
- **Context:** Note for when the operator picks up SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN — placement matters for the structural-test PASS count sequence and for not visually orphaning the close-commit Phase 11 block.
- **Suggested action:** Cross-reference this note inside the parent SURFACE's "Suggested action" field, or merge this finding into the parent SURFACE as a placement-detail addendum.
- **Priority:** low
- **Status:** resolved 2026-07-13 (backlog-paydown WP3). Honored — the YAML-parse check landed as `[Phase 3a]` (between Phase 3 and 3b), NOT a tail phase, so the Phase-11 close-commit block and PASS-count sequence stay undisturbed.

# docker-daemon-vs-container-distinction — 2026-06-19

## SURFACE-2026-06-19-QUALITY-CONTAINER-DOWN-PIN-OVER-BROAD
- **Source:** feature-review-quality (docker-daemon-vs-container-distinction ship aef35a2)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** The container-down structural pin at `tests/check-structure.sh:176` matches `containers are down|docker compose up`, but `docker compose up` may also appear in unrelated allowed-list/bootstrap prose in the same Variant-A template. The OR-branch means the pin could pass on the wrong line if the new self-start clause is ever deleted while a stray `docker compose up` survives — a slightly leaky regression net.
- **Context:** The pin's value is catching accidental removal of the new container-down branch specifically; the broad alternation weakens that guarantee. Low-stakes because the sibling daemon-unreachable pin still anchors the section's presence.
- **Suggested action:** Tighten the pin to a more distinctive anchor such as `start the container\(s\) yourself`, tying it to the actual new clause. 1-line edit to the grep_check pattern.
- **Priority:** low
- **Status:** resolved 2026-07-13 (backlog-paydown WP2). Tightened line-178 pin `"containers are down|docker compose up"` → `"[Ss]tart the container\(s\) yourself"` (matches the actual clause at product-context SKILL.md:73; the suggested lowercase anchor didn't literally exist — clause starts capital S).

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
- **Status:** resolved 2026-07-13 (backlog-paydown WP1). Added the two-different-purposes note (3-round = inconclusive-escalation, 5-round = optional traceability) to `skills/debug-minimal-harness/SKILL.md`.

# design-priors — 2026-06-26

## SURFACE-2026-06-26-QUALITY-CONSULT-SCENARIOS-PROMPT-LEAKAGE
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Target level:** workflow:task (test-harness coverage)
- **Type:** tech-debt (test coverage)
- **Summary:** The DP-consult-* scenarios in `tests/scenarios/product.yaml` encode the expected answer in `system_prompt_extra` (e.g. "do NOT cite or stretch an audience prior onto a copy-tone decision"; "surface this as a PROPOSAL ... do NOT silently add ... do NOT silently drop"). This tests "does the model obey an instruction just handed to it" more than "does the consult contract in the SKILL.md produce the behavior." The over-infer guard is the feature's headline anti-overfit claim; a scenario that pre-states the guard's conclusion could pass even if the skill prose were deleted.
- **Context:** Residual signal survives — the model must still emit/withhold the `PRIOR: P` disclosure correctly and strict `not_contains` catches over-firing — so this is a coverage weakness, not a broken test. NOTE: the operator independently raised this exact concern at P2 verify-human ("scenarios are what really matters rather than me eyeballing"); the prompt-leakage limits how much the scenarios deliver on that.
- **Suggested action:** Strengthen the consult scenarios to present the decision context *neutrally* (state the open product-design question + that a design-priors.md exists, WITHOUT pre-stating whether/how a prior should fire) and let the loaded SKILL.md consult contract drive the outcome. Pairs naturally with the `SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE` harness work. Property-test per docs/lessons/test-harness-primitives.md.
- **Priority:** medium
- **Status:** RESOLVED 2026-07-14 — WP6 of backlog-paydown-2026-07-13 (ship e2494f9). All 4 DP-consult-* scenarios rewritten neutrally; verified 4/4 PASS on haiku (attempts:1) driven by the loaded SKILL.md consult contract. See CHANGELOG.

## SURFACE-2026-06-26-QUALITY-STEP0-ON-NON-ENTRY-SKILLS
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Target level:** workflow:task
- **Type:** tech-debt (doc-surface consistency)
- **Summary:** `product-roadmap` and `product-wbs` gained `## Step 0: Available product context` sections, but neither is an entry-point skill — the `transitions.md` entry-point list and the `check-structure.sh` Phase-3 Step-0-presence pins enumerate only `task-plan, feature-spec, feature-plan, feature-reproduce, incident-report, product-vision`. The new Step-0 headings are unguarded by the Step-0-presence pin and overload the "Step 0 = entry-point product-context load" convention to also mean "any consult point." The CLAUDE.snippet.md per-skill mapping now lists product-roadmap/product-wbs as eager-read consulters without the transitions.md entry-point prose being updated to match.
- **Context:** Phase 13 pins the `design-priors.md` substring in both files, so the consult block won't silently vanish; the gap is narrowly the `## Step 0` heading-convention overload + the transitions.md/snippet mapping mismatch. Two fixes: (a) rename the design-priors consult block in roadmap/wbs to a non-"Step 0" heading (e.g. `## Design-priors consult`), keeping "Step 0" reserved for entry points; or (b) broaden the documented "Step 0" convention in transitions.md + CLAUDE.snippet.md to explicitly include mid-workflow consult points.
- **Suggested action:** Prefer (a) for minimal convention disruption — rename to a distinct heading; update the Phase-13 pins to match. Small task.
- **Priority:** medium
- **Status:** resolved 2026-07-13 (backlog-paydown WP4, option a). Renamed the heading SUFFIX in product-roadmap + product-wbs → `## Step 0: Product context + design-priors consult` (the block does BOTH doc-listing AND the consult, so a pure `## Design-priors consult` would mislabel it — operator-clarified). Entry-point `## Step 0: Available product context` now unique to the 6 entry-point skills. NB the suggested "update the Phase-13 pins to match" was NOT needed — Phase-13 anchors on the `design-priors.md` substring, not the heading; Phase-3 pins only assert the entry-point string for the 6 entry points (both verified, suite 401/0). Fixed transitions.md:238 phrasing. Separate follow-up logged: SURFACE-2026-07-13-STEP0-PREAMBLE-VS-PROCEDURE-RENUMBER (the awkward Step-0-preamble-vs-procedure numbering).

## SURFACE-2026-06-26-QUALITY-PROPOSE-PIN-TOO-LOOSE
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Type:** tech-debt (cosmetic / pin precision)
- **Summary:** The Phase-13 `propose` pins in `tests/check-structure.sh` grep the bare lowercased substring `propose` (min_count 1), firing on any occurrence — so they cannot detect a capture block that kept the word but lost the `never-auto-write` qualifier. The adjacent comment calls it "the load-bearing over-capture guard," which the pin under-delivers on.
- **Suggested action:** Pin `propose-never-auto-write` (the actual contract phrase, present in all 6 capture skills) instead of bare `propose`. 6 one-line pattern edits.
- **Priority:** low
- **Status:** resolved 2026-07-13 (backlog-paydown WP2). Correction to the suggested action: the phrase is NOT present in all 6 skills as the hyphenated token — `product-vision` uses the comma-form "Propose, never auto-write." So pinned a both-forms-tolerant pattern `[Pp]ropose.{0,6}never.{0,6}auto-write` (single loop pattern, not 6 edits) that requires the full contract phrase while tolerating both surface forms. product-vision prose left unchanged (already correct).

## SURFACE-2026-06-26-QUALITY-CORPUS-OPEN-QUESTIONS-STALE
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Type:** tech-debt (cosmetic doc)
- **Summary:** `docs/lessons/design-priors-corpus.md` ships its "Open questions for Stayman" section with Q1/Q2 as open prompts ("My lean: …") even though the curated preamble states Q1/Q2 were resolved by the operator. A future reader sees questions the doc's own header says are closed.
- **Suggested action:** Mark Q1 (arch-boundary → ARCH) and Q2 (preserve why-gap → yes) RESOLVED inline. Trivial edit.
- **Priority:** low
- **Status:** resolved 2026-07-13 (backlog-paydown WP1). Marked Q1/Q2 RESOLVED inline in `docs/lessons/design-priors-corpus.md`.

## SURFACE-2026-06-26-QUALITY-FIXTURE-USES-PHASE-ALIAS
- **Source:** feature:review-quality (design-priors, ship commit 6542e57)
- **Type:** tech-debt (cosmetic)
- **Summary:** `tests/fixtures/product/design-priors-consult/roadmap.md` uses "Phase 1/2/3" (the backward-compat read-alias) for the roadmap unit rather than the current "Milestone" terminology. Cosmetic and consistent with the pre-existing `roadmap-done` fixture it was copied from (so not new drift), but new fixtures could model current terminology.
- **Suggested action:** Optionally rename to "Milestone" in the new fixture; or bundle with a broader fixture-terminology refresh. Lowest priority.
- **Priority:** low
- **Status:** resolved 2026-07-13 (backlog-paydown WP1). Renamed "Phase 1/2/3" → "Milestone 1/2/3" in `tests/fixtures/product/design-priors-consult/roadmap.md` (no scenario asserts on those strings — verified).

# util-backlog-paydown — 2026-06-30

## SURFACE-2026-06-30-QUALITY-UTIL-PAYDOWN-GRAMMAR-AN-A
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship aa5c831)
- **Finding:** `skills/util-backlog-paydown/SKILL.md` Rule-1 parenthetical reads `An "carve out an exception…"` — should be `A "carve out…"`. Cosmetic; sits on the load-bearing Rule-1-no-exception why.
- **Pickup shape:** one-word edit.
- **Status:** resolved 2026-07-13 (backlog-paydown WP1). `An` → `A` fixed.

## SURFACE-2026-06-30-QUALITY-UTIL-PAYDOWN-ORDERING-NESTING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship aa5c831)
- **Finding:** `skills/util-backlog-paydown/SKILL.md` ordering-rules list nests the cross-cutting "Risk outranks impact in ordering" clarification under rule 5 ("Effort is NOT an ordering key"). Faithful to the learning doc's structure but a literal reader may be momentarily confused. Consider promoting to a top-level note (would also be worth fixing in `docs/lessons/between-milestone-debt-paydown-sweep.md` for consistency).
- **Pickup shape:** restructure the ordering list (skill + lesson).
- **Status:** resolved 2026-07-13 (backlog-paydown WP1). Promoted "risk outranks impact in ordering" to a top-level cross-cutting note (out from under rule 5) in BOTH the skill and the lesson.

# memory-location-symlink — 2026-07-03

## SURFACE-2026-07-03-QUALITY-DRYRUN-STRAY-CD-ERROR
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship d173bd7)
- **Finding:** `tools/memory-link/ensure-memory-link.sh:64` — under `--dry-run`, when the repo target dir does not yet exist (its `mkdir -p` was only echoed) and the harness path is already a symlink, the symlink-target comparison's RHS `cd "$REPO_MEM"` emits a stray `cd: No such file or directory` on stderr. Behavior is still correct (exits 0, correct verdict); non-dry-run always has REPO_MEM present by line 64. Diagnostic noise only.
- **Pickup shape:** guard the comparison's `cd` on `[ -d "$REPO_MEM" ]` in dry-run, or route the compare through the already-computed paths. ~2-line fix.

## SURFACE-2026-07-03-QUALITY-SCOPE-RULE-PROSE-ONLY
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship d173bd7)
- **Finding:** The migration scope rule ("any project with a `docs/product/` dir") is stated in prose only (`tools/memory-link/README.md` + `migrate-memory.sh` header); neither script enforces or checks it — `migrate-memory.sh` runs against any dir it's pointed at. Acceptable given the operator-confirmation gate (P2.2 hard checkpoint), but the prose implies a mechanical guard that doesn't exist.
- **Pickup shape:** either add an optional `--require-product-dir` guard to `migrate-memory.sh`, or soften the README prose to "scope is operator-enforced at the confirmation gate, not by the script." Prefer the prose fix (the enumeration/confirmation already lives in the workflow, not the tool).

# wp6-per-scenario-claude-md-fixture-and-neutral-consult — 2026-07-14

## SURFACE-2026-07-14-QUALITY-PROPTEST-MIRRORS-RUNNER
- **Source:** feature-review-quality (WP6 ship e2494f9)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** `tests/check-structure.sh` [Phase 3f]'s `_resolve_claude_md` is a hand-transcribed COPY of the runner's `claude_md` honor-else-fallback branch, not the runner logic itself. The two can drift independently; the grep_check drift-pins only assert the runner's source line still EXISTS, not that the copy still MATCHES it.
- **Context:** Shell can't easily source a mid-function fragment, so a mirror is a reasonable tradeoff — but the coupling is weak. A future runner-branch change that preserves the `if`-line text but alters fallback behavior would leave the property-test passing against stale semantics.
- **Suggested action:** Add a comment in Phase 3f noting the mirror must be updated in lockstep with run-tests.sh's branch. (Verify against the actual code before applying — per the "review-finding suggested-actions are hypotheses" Context Rule.) Cheap + safe.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-14-QUALITY-PROPTEST-LINE-NUMBER-ROT
- **Source:** feature-review-quality (WP6 ship e2494f9)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** Phase 3f comments cite `run-tests.sh:176-181` (claude_md) and `:236` (budget) for the mirrored one-liners; the reviewer flagged the claude_md branch as having shifted to ~183-187. Line-number references in comments rot on any edit above them.
- **Context:** A future reader chasing "the exact one-liners" lands on the wrong lines. NB: the specific line numbers the reviewer cited were read off a diff, not the committed file — VERIFY the actual current line numbers before editing (per the "review-finding suggested-actions are hypotheses" Context Rule; the fix is real regardless, the exact numbers are the hypothesis).
- **Suggested action:** Replace line-number refs in the Phase 3f comments with a stable string anchor (e.g. "the `fixture_claude_md` honor-else-fallback branch"). Cheap + safe.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-14-QUALITY-PROPTEST-GREP-UNANCHORED
- **Source:** feature-review-quality (WP6 ship e2494f9)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** Phase 3f's `_pt_claude` uses `grep -q "$want"` with an unanchored, unescaped pattern. Fine for the current all-caps marker strings (`NAMED-FIXTURE-MARKER`, `DEFAULT-FIXTURE-MARKER`), but a future `want` value containing a regex metacharacter would misfire silently.
- **Context:** Purely defensive hardening; no current bug.
- **Suggested action:** Change `grep -q` → `grep -qF` (fixed-string match) in `_pt_claude`. 1-char edit, cheap + safe.
- **Priority:** low
- **Status:** pending
