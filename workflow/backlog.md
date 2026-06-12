# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention).

---

## TODO

## SURFACE-2026-06-12-QUALITY-NO-PUSH-CLAUSE-DUPLICATED-4X
- **Source:** feature:review-quality (close-commit-discipline, 2026-06-12) — MINOR auto-backlogged.
- **Target level:** task:plan (small — extract shared snippet OR keep as-is)
- **Type:** tech-debt / DRY judgment call
- **Summary:** The four "Do NOT `git push`" paragraphs in `skills/feature-finalize/SKILL.md:91`, `skills/task-close/SKILL.md:83`, `skills/incident-resolve/SKILL.md:67`, `skills/product-finalize/SKILL.md:106` are nearly identical word-for-word (varying only by "close"/"resolve"/"cycle-close"). If the contract evolves (add an opt-in flag, expand rationale), all four sites must be updated in lockstep. The repo already solved an analogous duplication problem by extracting the CHANGELOG convention into `CLAUDE.snippet.md` — the four-skill no-push clause is a candidate for the same treatment, though four sites is borderline for the snippet pattern.
- **Suggested action:** Either (a) leave as-is — Phase 11 structural pins guarantee the contract holds in all 4 sites mechanically; or (b) extract a shared `## No-auto-push contract` block in `CLAUDE.snippet.md` and have each close skill reference it. Operator's call when the no-push contract is next touched.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-12-QUALITY-PRODUCT-FINALIZE-NO-PUSH-FORMAT-ASYMMETRY
- **Source:** feature:review-quality (close-commit-discipline, 2026-06-12) — MINOR auto-backlogged.
- **Target level:** task:plan (very small — formatting fix only)
- **Type:** consistency / stylistic
- **Summary:** In `skills/product-finalize/SKILL.md:106`, the no-push paragraph is formatted as a standalone bolded paragraph between two unrelated paragraphs, while the other three close skills place the clause as a numbered list item (step 5 or step 6) inside the operational-sequence list. Cosmetic but visually breaks the "four close skills carry the same contract" mental model.
- **Suggested action:** Restructure product-finalize §6b operational sequence into a numbered list and move the no-push clause into it as a list item, matching the other three.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-12-QUALITY-PHASE-11-GREP-PATTERN-LOOSE
- **Source:** feature:review-quality (close-commit-discipline, 2026-06-12) — MINOR auto-backlogged.
- **Target level:** task:plan (very small — regex tightening)
- **Type:** test-scaffolding precision
- **Summary:** In `tests/check-structure.sh:1614-1617`, the grep pattern `Do NOT.*git push` is loose enough to match arbitrary intervening text. A tighter literal like `Do NOT \`git push\`` (with the backticks) would document intent more clearly and reject hypothetical inverted constructions (e.g. "Do NOT skip the git push step").
- **Suggested action:** Update the 4 grep_check patterns to `Do NOT \`git push\`` (escaped backticks). Bite-verify still works the same way.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-12-QUALITY-S20-CONTAINS-ANY-REDUNDANT-ANCHOR
- **Source:** feature:review-quality (close-commit-discipline, 2026-06-12) — MINOR auto-backlogged.
- **Target level:** task:plan (trivial — one-line YAML edit)
- **Type:** test authoring duplication
- **Summary:** In `tests/scenarios/session.yaml` S20-amend-head, `contains_any` lists both `"--amend"` and `"git commit --amend"` — any string containing the latter also contains the former, so the second entry is redundant matching-wise.
- **Suggested action:** Drop `"--amend"` from `contains_any` (keep the more specific `"git commit --amend"`).
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-12-QUALITY-NO-PUSH-SCENARIO-FAMILY-COMMENT
- **Source:** feature:review-quality (close-commit-discipline, 2026-06-12) — MINOR auto-backlogged.
- **Target level:** task:plan (trivial — comment addition)
- **Type:** maintainability / discoverability
- **Summary:** The four `*-no-auto-push` scenarios in `feature.yaml:1858-1862`, `task.yaml:387-389`, `incident.yaml:507-509`, `product.yaml:364-366` share the same `contains_any: ["Do NOT", "do not push", "operator", "land locally"]` shape with mostly-identical `system_prompt_extra` framing. A trailing comment block on each (e.g. `# Part of the no-push family — keep contains_any in sync across F19/T10/I10/P13-no-auto-push`) would help future maintainers spot the family at a glance.
- **Suggested action:** Add a one-line YAML comment to each of the four scenarios naming them as a family.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX
- **Source:** feature:verify-codify (close-commit-discipline Phase 1, 2026-06-12) — surfaced during `check-structure.sh` baseline run after Phase 1's `git commit`.
- **Target level:** task:plan (small — 1-line test-scaffolding fix in `tests/check-structure.sh:320`).
- **Type:** obsolete test / harness scaffolding drift
- **Summary:** `tests/check-structure.sh` Phase 3d ("TRANSITION-line regex" property test) extracts ONLY the sed regex from `tests/lib/verify.sh:51` via `grep -oE 's/\.\*TRANSITION:[^/]*/\\1/p'` and runs each test case through `sed -n "$REGEX_PATTERN"` directly. But verify.sh's actual production pipeline is `tr -d '*' | sed -n '...'` — the `tr -d '*'` strip is what handles markdown-bold tolerance. The property test asserts the sed regex alone handles markdown bold; it doesn't (and wasn't designed to — the strip handles it). Result: 2 perpetual FAILs on `**TRANSITION:** F1` and `**TRANSITION:** DEBUG-BISECT-SKIP`. The production code is CORRECT; the property test is obsolete vis-à-vis the pipeline-not-regex fix that landed in commit `7e1b71c` (debug-telemetry-inconclusive-strict-pass close).
- **Confirmed at:** HEAD~1 (before close-commit-discipline Phase 1 commit) — same 2 FAILs reproduce. Not introduced by this feature; baseline-pre-existing.
- **Suggested action:** In `tests/check-structure.sh:326-336`, change `regex_test` to mirror the production pipeline: `actual=$(echo "$input" | tr -d '*' | sed -n "$REGEX_PATTERN")`. Re-run; both markdown-bold cases should PASS. Single-line fix in test scaffolding only.
- **Priority:** low — production behavior is correct, only the property test is misaligned. Baseline check-structure.sh count drifts from 228 to 226 — interpret 226/226 as "all PASS" post-fix.
- **Status:** pending

## SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT
- **Order:** P1 (was P2; P1 resolved by close-commit-discipline feature 2026-06-12; this item promoted to next pickup)
- **Source:** task:act (codify-randomize-host-ports-test-coverage, 2026-06-06) — discovered during T5 bite-verification while trying to add a behavioral content-presence assertion (P10b).
- **Target level:** feature:spec (small/medium — adds a new assertion shape to the test harness; touches `tests/lib/verify.sh`, scenarios, and the doc-side `## Conventions` block).
- **Type:** harness limitation / missing primitive
- **Summary:** `tests/lib/verify.sh::verify_result` (lines 70-82) treats a matching `transition_id` as **authoritative PASS** and never re-examines `contains_any` once that match fires. `contains_any` is only consulted as a SOFT_PASS fallback when no `transition_id` match was found. Net effect: no scenario in the current harness can hard-assert content presence. If you write `transition_id: X` + `contains_any: [Y, Z]` intending "must contain Y or Z AND emit X," you actually get "emit X (Y and Z are checked only if X fails)." Confirmed by 2x bite-verification (2026-06-06): mutated SKILL.md to remove the randomize-host-ports bullet, ran the candidate P10b scenario with `contains_any` set to literal SKILL.md prose anchors (first weak: `ephemeral|49152|randomize`; then strong: `lsof -nP -iTCP|random.randint(49152, 65535)|58329:5173`) — both passed because the model still emitted `TRANSITION: P10` correctly, and the harness short-circuited.
- **Why it matters:** Several conventions in CLAUDE.md (e.g. the integration-boundary rule's "verify-codify must include a test on the consuming surface") presuppose that scenarios can test *content* of the surface, not just transitions. Today they can't — only structural `grep_check` pins in `tests/check-structure.sh` actually hard-assert content, and those don't exercise the model. The P10b case landed cleanly on the structural-pin side (see the same task), but a future feature whose only verifiable surface is "the model emits the right downstream prose under a real skill invocation" has no harness primitive available.
- **Suggested action:** Add a new `contains_required` (or `must_contain_all` / `contains_required_any`) field to the scenario schema. Semantics: when set, even on a `transition_id` match, ALL (or ANY) of the listed strings must appear in `result_text` or the scenario FAILs. Implementation is small: a new check between lines 71 and 82 of verify.sh. Update `## Conventions` block in `CLAUDE.md` (the bullet about `expect:` fields) to document the new field. Pilot use: re-introduce a P10b-equivalent scenario with `contains_required: [<SKILL.md-prose anchor>]` once the primitive lands.
- **Priority:** medium — current workaround (structural `grep_check` pins) covers most prose-presence regressions, but the gap will bite the moment a feature ships prose that's only meaningful when the model is actually invoking the skill (not just whether the file contains it).
- **Status:** pending

---

## MAYBE

_(empty — both prior MAYBE items promoted to TODO 2026-06-12; SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE buried same day)_

---

## Buried

The following items were buried by user decision. Full content preserved in [`workflow/backlog-deferred-2026-05.md`](backlog-deferred-2026-05.md).

Buried 2026-06-07:
- `SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER` — bulk-delete safety pattern (CLAUDE.md convention proposal).
- `SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING` — audit-method gap; destructuring patterns require their own grep.
- `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` — codify plan-time downstream-contract grep into `feature-plan` SKILL.md.
- `SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD` — `docs/product/wbs.md` exceeds 300-line size guard.
- `SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG` — `--db` silently overrides `$CLAUDE_TIME_DIR` for config lookup.
- `SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE` — `session_id[:8]` truncation can collide in synthetic test data.
- `SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL-DOESNT-REACH-REACT` — synthetic `WheelEvent` dispatch doesn't reach React's `onWheel`.
- `SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT` — structural check missing; frontmatter `name:` vs. parent dir.

Buried 2026-06-12:
- `SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE` — borrow obra/superpowers' behavioral pressure tests for skill rationalization-resistance.
