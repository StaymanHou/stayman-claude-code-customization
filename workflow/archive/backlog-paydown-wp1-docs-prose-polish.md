---
workflow: task
state: verify (complete)
created: 2026-07-13
docs-only: false
drive_mode: autopilot
---

# Task: WP1 — docs/skill prose polish (8 findings)

**Workflow:** task
**State:** verify (complete)
**Created:** 2026-07-13

## Problem Statement
Eight small docs/skill-prose findings (heading-divergence doc, missing lessons README, stale/redundant doc lines, grammar, ordering-note placement, threshold clarification, fixture terminology) accumulated across recent features; resolve them in one co-located bundle.

## Context
- Governed by `docs/product/backlog-paydown-2026-07-13-wbs.md` → WP1 (co-located docs/skill edits, low risk).
- Resolves 8 SURFACE IDs across `workflow/backlog.md` + `workflow/backlog-quality-findings.md`.
- **Key resolved decision (scope-symmetry):** Finding #1's suggested option (a) "rename `## Category`→`## Category Context`" is WRONG — grounding this session confirmed `## Category Context` is a *debug-\* structural requirement* (arch.md:263, pinned check-structure.sh:306 for debug skills only); util-\* skills have no pinned heading (arch.md:281) and both use `## Category` as their own consistent convention. Renaming would erase the util-\*/debug-\* category distinction. → Use option (b): document the intentional divergence in arch.md instead. Do NOT touch the util-\* headings.
- `docs-only: false` chosen deliberately: no code/script changes, but the task touches pinned SKILL.md files (debug-minimal-harness, util-backlog-paydown) and design-priors docs, so `./tests/check-structure.sh` is the real verification observable — higher signal than an auto-skip.

## Work Tree

- [x] T1 Finding #1 — add a sentence to `docs/product/arch.md` util-* subsection documenting util-* intentionally uses `## Category` (distinct from debug-*'s pinned `## Category Context`)  <!-- status: [x] -->
- [x] T2 Finding #3 — delete the stale same-day-edit HTML comment at `docs/product/arch.md:6`  <!-- status: [x] -->
- [x] T3 Finding #2 — write new `docs/lessons/README.md` with the open-schema statement  <!-- status: [x] -->
- [x] T4 Finding #4 — mark corpus Q1/Q2 RESOLVED inline in `docs/lessons/design-priors-corpus.md`  <!-- status: [x] -->
- [x] T5 Finding #5 — `An`→`A` grammar fix in `skills/util-backlog-paydown/SKILL.md` Rule-1 parenthetical  <!-- status: [x] -->
- [x] T6 Finding #6 — promote "Risk outranks impact in ordering" to a top-level note in BOTH `skills/util-backlog-paydown/SKILL.md` and `docs/lessons/between-milestone-debt-paydown-sweep.md`  <!-- status: [x] -->
- [x] T7 Finding #7 — one-line 3-vs-5-round threshold clarification in `skills/debug-minimal-harness/SKILL.md`  <!-- status: [x] -->
- [x] T8 Finding #8 — rename "Phase 1/2/3"→"Milestone 1/2/3" in `tests/fixtures/product/design-priors-consult/roadmap.md`  <!-- status: [x] -->
- [x] T9 Update the 8 SURFACE statuses (backlog-quality-findings.md) to resolved  <!-- status: [x] -->

## Verification Observable

**Observable:** After WP1's edits (which touch pinned SKILL.md files + design-priors docs), the full structural suite still passes with zero failures.
**Verification command:** `./tests/check-structure.sh`
**Expected result:** exit 0, summary line reports `0` failures (all pins green — esp. Phase 3b debug-* Category-Context pins and Phase 13 design-priors pins).

## Verification Result

**Status:** PASS (with one pre-existing, unrelated failure documented below)
**Date:** 2026-07-13
**Evidence:** `./tests/check-structure.sh` → `PASS: 353 | FAIL: 1`, exit-time 17s. The single FAIL is `settings fixture in sync with live` — host-local keys (`disableClaudeAiConnectors`, `tui`, `cleanupPeriodDays`, `statusLine.padding`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`). All 353 other pins PASS, including Phase 3b debug-* `## Category Context` pins and Phase 13 design-priors pins that WP1's edits could have tripped.
**Notes:** The 1 failure is the pre-existing settings-fixture drift — precisely `SURFACE-2026-06-26-SETTINGS-FIXTURE-DRIFT-DISABLECLAUDEAICONNECTORS`, which is **WP2's target**, NOT introduced by WP1. WP1 touched no `settings.json` fixture. WP1 introduced ZERO new failures → observable met (suite stays green modulo the known WP2 pre-existing drift).

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none (the 1 suite failure is pre-existing WP2 work, already tracked)

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [NOTE-2026-07-13] Finding #1 resolved via option (b) not (a) — grounding confirmed renaming `## Category`→`## Category Context` would erase the intentional util-*/debug-* category distinction; documented the divergence in arch.md instead. All 8 findings were in `backlog-quality-findings.md` (none in `backlog.md`); marked resolved-in-place (not deleted) so the close step can emit CHANGELOG entries.
- [NOTE-2026-07-13] Finding #8 — verified no scenario asserts on the fixture's "Phase 1/2/3" strings before renaming (downstream-contract check); safe.

## Retrospect
- **What changed in our understanding:** Finding #1's own suggested fix (option a, rename to `## Category Context`) was wrong — the divergence it flagged as "drift" is intentional (util-* is a distinct category from debug-*, with no pinned heading). The finding's author didn't know the util-*/debug-* boundary; grounding the code surfaced it. Lesson: a review finding's *suggested action* is a hypothesis, not a spec — verify against the code before applying.
- **Assumptions that held:** All 8 were genuinely cheap+safe (Rule 1); the co-located docs bundle applied cleanly; the structural suite stayed green modulo the known WP2 drift.
- **Assumptions that were wrong:** The scope-symmetry catch (both util-* skills use `## Category`, not just the named one) meant Finding #1 was a two-file *and* an arch.md-doc question — larger than "1-line rename" implied, and the right answer was zero renames.
- **Approach delta:** Chose `docs-only: false` (not the auto-skip) precisely because the task touched pinned SKILL.md files — that let check-structure.sh serve as a real verification and confirmed no pin was tripped. Good call: it's the difference between "looks fine" and "353 pins say fine."

## Completed
- **Completion date:** 2026-07-13
- **Status:** Completed (WP1 of backlog-paydown-2026-07-13 sweep)
