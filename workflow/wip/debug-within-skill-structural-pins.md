---
workflow: task
state: plan (complete)
created: 2026-06-12
docs-only: false
drive_mode: autopilot
---

# Task: Debug-* within-skill structural pins (Phase 3b extension)

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-06-12
**Drive mode:** autopilot

## Problem Statement

`tests/check-structure.sh` Phase 3b currently asserts only 2 of the 6 required SKILL.md sections per `debug-*` skill (gate-boundary headings `## When to use` + `## When NOT to use`). The other 4 required sections (`## Category Context`, `## Procedure`, `## Pitfalls`, `## Termination`), the `argument-hint:` frontmatter field, Gate Check as the first `### 1.` under Procedure, and the termination-token regex are NOT structurally pinned — meaning a future edit that deletes/breaks any of these properties would not be caught by `check-structure.sh`.

## Context

- **Backlog item:** `SURFACE-2026-06-10-DEBUG-WITHIN-SKILL-STRUCTURAL-PINS` (P2 in `workflow/backlog.md`)
- **Existing Phase 3b loop:** `tests/check-structure.sh:229-234` (iterates `skills/debug-*/SKILL.md`, asserts 2 gate-boundary headings)
- **Convention source:** `CLAUDE.md` → Architecture → "`debug-*` Skill Category" lists 6 required sections + frontmatter requirements
- **Current debug-* skills:** `debug-bisect-known-good` + `debug-empirical-telemetry` — confirmed via Grep that both satisfy all 5 to-be-pinned properties:
  - 6 sections present in both (lines 11, 17/19, 29/34, 37/42, 183/179, 191/188)
  - Gate Check is the first `### 1.` under Procedure in both (line 39/44)
  - `argument-hint:` present in both (line 4 of frontmatter)
  - 4 DEBUG-<TECHNIQUE>-<OUTCOME> tokens present in both (bisect: START/SKIP/COMPLETE/NO-CONVERGE; telemetry: START/SKIP/COMPLETE/INCONCLUSIVE)
- **Expected PASS delta:** +5 pins × 2 skills = **+10 PASS, 214 → 224** (matches the backlog entry's projection)
- **grep_check helper safety:** new pins all use `min_count=1` (positive pins), so the latent P5 `|| echo 0` bug does NOT bite — fix for P5 remains scoped to its own future task

## Work Tree

- [x] T1 Read current Phase 3b block context (`tests/check-structure.sh:218-236`) and confirm insertion point for new pins inside the existing `for debug_skill in skills/debug-*/SKILL.md` loop  <!-- confirmed: lines 229-234, loop body insertion after the 2 existing gate-boundary pins -->
- [x] T2 Extend the loop with 7 new `grep_check` calls per skill (revised from plan's 5):  <!-- 7 pins, not 5: ## Termination heading split from token regex; argument-hint split from Gate-Check -->
  - [x] T2.1 `## Category Context` heading present
  - [x] T2.2 `## Procedure` heading present
  - [x] T2.3 `## Pitfalls` heading present (parenthetical-suffix tolerant — pattern: `^## Pitfalls`)
  - [x] T2.4 `## Termination` heading present + termination-token regex `DEBUG-[A-Z]+(-[A-Z]+)+` count ≥ 4 (split into 2 pins for clearer FAIL messages)
  - [x] T2.5 `argument-hint:` frontmatter field present + Gate Check is first `### 1.` subheading under Procedure (split into 2 pins)
- [x] T3 Run `./tests/check-structure.sh`: 228/0 (vs planned 224). Bite-verify by mutating `## Category Context` → `## Category Contextual` in debug-bisect-known-good: 1 informative FAIL naming both the offending skill and the pin description. Reverted; back to 228/0.  <!-- delta +14 = 7 pins × 2 skills, exceeds plan's +10 by 4 -->
- [x] T4 Updated `runtimes.md`: 31s observed today (baseline unchanged — grep_check adds negligible overhead), timeout recomputed via `ceil(31 * 1.5 + 60) * 1000 = 107000ms`  <!-- prior entry's 43s was inflated by yesterday's run including bite-verify; today's clean wall time is back to baseline -->
- [ ] T5 Commit the change as a single doc-test addition  <!-- status: in-progress -->

## Current Node

- **Path:** Task > T5
- **Active scope:** T5 (commit)
- **Blocked:** none
- **Open discoveries:** Plan estimated +5 pins per skill = +10 PASS; actual implementation split 2 pins into 4 for clearer FAIL messages (split `## Termination` heading from token regex; split `argument-hint:` from Gate-Check), yielding +14 PASS (214 → 228). Not a back-loop — same scope, finer granularity. Captured for future plan-estimation calibration.

## Discoveries

<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-06-12] T2 — Plan's "+5 pins × 2 skills = +10 PASS" estimate was 2 conceptual buckets per skill that decomposed into 7 separate grep_check calls at implementation time (the `## Termination` heading + ≥4 token regex are naturally separate pins; same for `argument-hint:` frontmatter + Gate-Check-first-subheading). Future plan-time discipline: when a bucket combines a heading-presence pin with a content-regex pin under that heading, count them as 2 pins, not 1. Not surfacing as backlog item — minor estimation calibration, captured in retrospect.
