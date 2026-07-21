---
workflow: task
state: verify (complete)
created: 2026-06-13
docs-only: false
drive_mode: autopilot
---

# Task: Sweep 8 MINOR code-quality findings (close-commit-discipline + verify-sh-contains-required)

**Workflow:** task
**State:** verify (complete)
**Created:** 2026-06-13

## Problem Statement
Eight MINOR findings auto-backlogged by `feature-review-quality` across two features (close-commit-discipline, 2026-06-12 — 5 findings; verify-sh-contains-required, 2026-06-13 — 3 findings) are accumulating in `workflow/backlog-quality-findings.md`. Each is a documentation-polish / cosmetic edit; none load-bearing. Sweeping them in one combined task drains the queue before it accrues further volume noise.

## Context
- Findings file: `workflow/backlog-quality-findings.md` (8 SURFACE blocks across 2 sections)
- Parent backlog pointer entries: `workflow/backlog.md:9-19` (two pointer entries — close-commit-discipline + verify-sh-contains-required)
- Target files to edit (impl scope):
  - `skills/feature-finalize/SKILL.md:91` (no-push paragraph — leave as-is, finding A is "judgment call, leave as-is" per suggested action)
  - `skills/task-close/SKILL.md:83`
  - `skills/incident-resolve/SKILL.md:67`
  - `skills/product-finalize/SKILL.md:106` (format asymmetry — finding B)
  - `tests/check-structure.sh:1725-1728` (4 grep pins — finding C, tighter pattern)
  - `tests/check-structure.sh:378` (Phase 3e header range G-K → G-M — finding F)
  - `tests/check-structure.sh:1040-1043` (CLAUDE.md grep pins — finding H, simplify alternation)
  - `tests/scenarios/session.yaml:772` (S20 contains_any redundant `--amend` — finding D)
  - `tests/scenarios/feature.yaml:1858-1863`, `task.yaml:386-392`, `incident.yaml:506-512`, `product.yaml:388+` (4 no-push scenarios — finding E, add family-marker comment)
  - `tests/lib/verify.sh:5,15-16` (4 arg-name docstring entries — finding G, `_csv` → `_list` rename OR parenthetical)
- Convention: Close-commit close emits `**Backlog resolved:**` lines per CHANGELOG.md convention (one per SURFACE ID). Two parent-backlog pointer entries get removed after sweep.

**Finding-A decision:** SURFACE-2026-06-12-QUALITY-NO-PUSH-CLAUSE-DUPLICATED-4X explicitly offers "leave as-is" as suggested action (a); the four-skill duplication is borderline for snippet extraction and Phase 11 structural pins already enforce contract presence in all 4 sites. Pick (a) — close without code change, log decision in retrospect. The cost of extracting now (touching 4 SKILL.md files + CLAUDE.snippet.md + install.sh injection logic for borderline DRY benefit) exceeds the maintenance cost of keeping 4 nearly-identical paragraphs in sync.

**Finding-G decision:** SURFACE-2026-06-13-QUALITY-VERIFY-RESULT-CSV-SUFFIX-MISLEADING offers (a) full rename `_csv` → `_list` across 4 new args + 2 pre-existing args (`contains_any_csv`, `not_contains_csv`) OR (b) parenthetical "(pipe-separated, despite name)". Pick (b) — the pre-existing args (`contains_any_csv`, `not_contains_csv`) are referenced elsewhere as local-variable names inside `verify.sh`; renaming them changes the function-body code, not just the docstring, and touches the `verify_result` signature. The parenthetical is a 1-line docstring touch-up that closes the documentation hazard without code change. The full rename is a larger refactor — leave as a future option if the convention is next touched at a deeper level.

## Work Tree

- [x] T1 Phase-3e header range fix (`tests/check-structure.sh:378`: `G-K` → `G-M`)
- [x] T2 S20 contains_any redundant anchor drop (`tests/scenarios/session.yaml`: removed `"--amend"`, kept `"git commit --amend"`)
- [x] T3 verify.sh docstring parenthetical (`tests/lib/verify.sh:5`: added clarifying line "(The `_csv` suffix on multi-value args is historical — separator is the pipe `|`, not comma.)" — covers all 4 new `_csv` args plus the 2 pre-existing ones in one annotation)
- [x] T4 CLAUDE.md grep pin simplification (`tests/check-structure.sh:1040-1043`: dropped alternation + colon anchor; simplified to `"contains_required.*AND-fanout"` and `"contains_required_any.*OR-fanout"` — both pins still PASS)
- [x] T5 Phase-11 grep pattern tighten (`tests/check-structure.sh:1725-1728`: tightened all 4 pins to `"Do NOT \`git push\`"`; SKILL.md prose already uses literal form so all 4 pins continue to PASS)
- [x] T6 Product-finalize §6b format symmetry (`skills/product-finalize/SKILL.md:104+`: restructured the "Operational sequence" paragraph into a 4-step numbered list with no-push as step 4 — matches the other 3 close skills' numbered-list shape)
- [x] T7 No-push scenario family-marker comments (added `# Part of the no-push family — keep contains_any in sync across F19/T10/I10/P13-no-auto-push` trailing comment to all 4 scenarios: feature.yaml, task.yaml, incident.yaml, product.yaml)
- [x] T8 Verify: ran `./tests/check-structure.sh` — 251 PASS / 0 FAIL preserved (matches baseline at commit `e991406`)
- [x] T9 Backlog removal: removed the two Code-quality findings pointer entries from `workflow/backlog.md`; TODO section now reads "_(empty)_" with pointer to CHANGELOG
- [x] T10 Backlog-findings file: cleared the two finished sections from `workflow/backlog-quality-findings.md`; file header + top paragraph preserved; left "_(empty)_" stub for future findings
- [x] T11 8 `**Backlog resolved:**` entries staged via the Findings → Tasks Mapping table below — task-close will read this and emit one CHANGELOG line per SURFACE ID

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Findings → Tasks Mapping (for verify and CHANGELOG)

For the `task-close` `**Backlog resolved:**` emit (T11) and operator audit:

| Finding (SURFACE ID) | Task | Resolution |
|---|---|---|
| SURFACE-2026-06-12-QUALITY-NO-PUSH-CLAUSE-DUPLICATED-4X | (none) | Closed as "leave as-is" — Phase 11 pins enforce contract; 4-site duplication acceptable until snippet pattern is justified |
| SURFACE-2026-06-12-QUALITY-PRODUCT-FINALIZE-NO-PUSH-FORMAT-ASYMMETRY | T6 | Restructured §6b into numbered list |
| SURFACE-2026-06-12-QUALITY-PHASE-11-GREP-PATTERN-LOOSE | T5 | Tightened to `"Do NOT \`git push\`"` |
| SURFACE-2026-06-12-QUALITY-S20-CONTAINS-ANY-REDUNDANT-ANCHOR | T2 | Dropped `"--amend"` |
| SURFACE-2026-06-12-QUALITY-NO-PUSH-SCENARIO-FAMILY-COMMENT | T7 | Added family-marker comments to 4 scenarios |
| SURFACE-2026-06-13-QUALITY-PHASE-3E-HEADER-CASE-RANGE-STALE | T1 | Updated `G-K` → `G-M` |
| SURFACE-2026-06-13-QUALITY-VERIFY-RESULT-CSV-SUFFIX-MISLEADING | T3 | Added "(pipe-separated, despite name)" parenthetical (option b — full rename deferred) |
| SURFACE-2026-06-13-QUALITY-CLAUDE-MD-GREP-ALTERNATION-OVERSPECIFIED | T4 | Simplified to drop alternation + colon anchor |

## Verification Strategy

T8 is the verification gate. Success criteria:
1. `./tests/check-structure.sh` exits 0 with 251 PASS / 0 FAIL (matches pre-sweep baseline at commit `e991406`).
2. The 4 Phase 11 no-push pins continue to PASS with the tighter `"Do NOT \`git push\`"` pattern (T5 must update the SKILL.md prose to ensure all 4 still contain the literal "Do NOT \`git push\`" string — they should already, since current prose is `"**Do NOT \`git push\`.**"` per the read of feature-finalize:91, task-close:83, incident-resolve:67, product-finalize:106).
3. The 2 Phase 6/whatever CLAUDE.md pins continue to PASS with the simplified `"contains_required.*AND-fanout"` and `"contains_required_any.*OR-fanout"` patterns (T4).
4. No new FAIL anywhere in check-structure.sh output.

If T8 reports FAIL: task-verify will back-loop to act (T5c) with the failing pin IDs as scope; otherwise T8 PASS → ready to close.

## Estimated effort
~40 min total (per the operator pickup-shape estimate: ~30 min for close-commit-discipline group + ~10 min for verify-sh-contains-required group). Each individual task is a 1-5 line edit; T6 is the largest (paragraph → numbered list restructure ~10 lines).

## Verification Observable

**Observable:** Running the project's full structural test suite exits 0 with the 251 PASS / 0 FAIL baseline preserved (matches pre-sweep state at commit `e991406`) — meaning the 4 tightened Phase 11 grep pins, the 2 simplified CLAUDE.md grep pins, and all other modified pins still pin their respective contracts, and no other structural assertion was incidentally broken by the sweep.
**Verification command:** `./tests/check-structure.sh`
**Expected result:** Exit code 0; final line is `PASS: 251 | FAIL: 0`; final line above summary is `All structural checks passed.`

## Verification Result

**Status:** PASS
**Date:** 2026-06-13
**Evidence:**
```
[Phase 11] Close-commit discipline (no auto-push + amend learnings to HEAD)
  [PASS] feature-finalize forbids git push from close commit
  [PASS] task-close forbids git push from close commit
  [PASS] incident-resolve forbids git push from resolve commit
  [PASS] product-finalize forbids git push from cycle-close commit
  [PASS] session-store-learning folds learning into HEAD via amend
  [PASS] session-store-learning stages the learning file before amend

=== Summary ===
PASS: 251 | FAIL: 0
All structural checks passed.
```
**Notes:** 251 PASS / 0 FAIL — matches pre-sweep baseline at commit `e991406`. Tightened Phase 11 backtick pins (T5) and simplified CLAUDE.md alternation pins (T4) both PASS, confirming neither edit silently broke its contract. No sibling-bug surfaced during verification.

## Retrospect
- **What changed in our understanding:** Two findings (A — 4-way no-push prose duplication; G — `_csv` arg-suffix rename) suggested two-way action options at SURFACE time, and the right call only became visible during act. For A, the snippet-extraction cost (`CLAUDE.snippet.md` + `install.sh` injection logic) exceeds the maintenance cost of 4-way prose with Phase 11 pin coverage — confirms the SURFACE's own "leave as-is" suggestion (a). For G, the suggested option (a) "full `_csv` → `_list` rename" would have touched the `verify_result` function body's local variable names, not just docstrings — a much larger blast radius than the SURFACE characterized; option (b) parenthetical was strictly cheaper for the same documentation-hazard outcome. Both reinforce: when a SURFACE offers (a)/(b) options, the deeper-cost option needs a fresh read at act time, not a reflex pick of the "more thorough" one.
- **Assumptions that held:** Each finding was indeed a 1-5 line edit; total time within the ~40 min budget; no finding required re-planning. The structural-test baseline (251 PASS / 0 FAIL at `e991406`) held through all 6 substantive edits — the Phase 11 grep-pattern tightening (T5) preserved PASS only because the SKILL.md prose already used literal `Do NOT \`git push\`` form (verified up-front at T5 via grep before editing the pattern). T4's simplified alternation pins also preserved PASS because the current CLAUDE.md bullet text places `contains_required` and `AND-fanout` on the same line. Both edits were structurally guarded by their own contracts.
- **Assumptions that were wrong:** None of substance. The plan correctly identified that T6 (product-finalize §6b restructure) was the largest task; in practice it was indeed the only one requiring more than a single Edit call. The "8 SURFACE IDs → 8 CHANGELOG `**Backlog resolved:**` lines" mapping (including the 2 leave-as-is/parenthetical decisions) held through close without question — these still count as resolutions because they close the SURFACE entry, regardless of whether the resolution involved code change.
- **Approach delta:** Implementation matched the plan exactly. No back-loop. No discoveries surfaced. The act → verify → close chain ran clean in autopilot mode. One operational decision worth recording for future combined-sweep tasks: I committed the 10 modified files mid-task between act and verify (operator-instructed), then ran the verify gate's `check-structure.sh` at the post-commit HEAD (`6ee10b8`) rather than at the working-tree-uncommitted state. This is the inverse of the close-commit-discipline sequence (`feature-finalize` §3c stages CHANGELOG + WIP together with archive move in one commit) but the same idea applies — the verify gate's mechanically-verifiable observable should run against the exact commit state that will be archived, not against an intermediate dirty tree.

## Closure Notice

**Closure notice:** Sweep of 8 MINOR code-quality findings is complete. All 8 SURFACE entries are resolved (6 via code/doc edits, 2 via documented leave-as-is decisions); `tests/check-structure.sh` preserves the 251 PASS / 0 FAIL baseline at HEAD `6ee10b8`. Resolution detail per SURFACE ID is in `CHANGELOG.md` under `## 2026-06-13`; the 2 backlog pointer entries are removed and `workflow/backlog-quality-findings.md` is empty pending the next `feature-review-quality` pass. Requester = operator — closure notice for self-record.
