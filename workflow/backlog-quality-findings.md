# Backlog — Code-Quality Review Findings

This file holds MINOR findings auto-backlogged by `feature-review-quality` runs. The parent `workflow/backlog.md` keeps **one pointer entry per feature** referencing this file. Convention adopted 2026-06-12 to avoid backlog volume noise — see `SURFACE-2026-06-12-ADJUST-QUALITY-AGENT-USE-DEDICATED-FILE` in `backlog.md` for the agent-config followup that codifies this shape.

Items are grouped by source feature. Within each group, each finding keeps the full SURFACE block produced by the reviewer subagent.

---

# close-commit-discipline — 2026-06-12

5 MINOR findings auto-backlogged at `feature-review-quality` post-ship pass. None block; each is a 1-3 line edit when picked up.

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
