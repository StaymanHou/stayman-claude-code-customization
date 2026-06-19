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
