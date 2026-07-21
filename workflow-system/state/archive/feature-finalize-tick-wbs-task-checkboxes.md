---
drive_mode: autopilot
---

# Task: feature-finalize should tick WBS per-task checkboxes when shipping a WP

**Workflow:** task
**State:** act (complete)
**Created:** 2026-06-10

## Problem Statement
`skills/feature-finalize/SKILL.md` §1 updates `docs/product/wbs.md` to tag the shipped WP heading with `✅ SHIPPED <date> (commit <sha>)` but does NOT tick the per-task checkboxes (1.1, 1.2, …) underneath — every WP finalize since v3 cycle start (12-of-12 confirmed, per `SURFACE-2026-05-29-FEATURE-FINALIZE-MISSES-WBS-TASK-CHECKBOXES`) produces a `✅ SHIPPED` heading sitting above unticked `- [ ]` task list items, leaving WBS as a partially-trustworthy state surface for downstream planning skills.

## Context
- Backlog source: `SURFACE-2026-05-29-FEATURE-FINALIZE-MISSES-WBS-TASK-CHECKBOXES` (P3, `workflow/backlog.md`) — 12 documented recurrences in NeoStayman + this repo's own v3 cycle; recommends "for the WP being finalized, `replace_all` `- [ ]` → `- [x]` within that WP's section only."
- Skill to patch: `skills/feature-finalize/SKILL.md` §1 "Update Documentation" (line 29 — the bullet that mentions `docs/product/wbs.md` heading update). `install.sh` symlinks `skills/feature-finalize/` into `~/.claude/skills/feature-finalize/` so single-source edit propagates immediately.
- WBS task-list shape: per-WP sections in `docs/product/wbs.md` use markdown checkbox lists `- [ ] N.M description` under each WP heading (verified by recent precedent — the deferred backlog item summary mentions "checkboxes underneath" without prescribing a specific format beyond standard markdown).
- Scope-of-replacement: "within that WP's section only" means between the WP's heading and the next WP heading (or EOF). The skill prose needs to be precise about this — a global `- [ ]` → `- [x]` would mistakenly tick checkboxes in OTHER WPs that are still in-progress, which is the exact opposite of the desired discipline.
- Structural pin precedent: `tests/check-structure.sh` Phase 3 line 96 already pins `skills/feature-finalize/SKILL.md` for the CHANGELOG convention reference. A sibling pin for the new "tick task checkboxes within the WP" directive sits naturally next to it — same skill file, same regression mechanism (silent removal during future edits to §1).

## Scope assessment
- Task-level. Single SKILL.md edit (~3-line procedure addition to §1's existing wbs.md bullet). No state-machine change, no new transition (F18/F19/F30 unchanged — sub-procedural refinement of §1 only), no AGENTS.md edit, no transitions.md edit.
- One structural pin in `tests/check-structure.sh` Phase 3 to anchor the new directive + prevent silent regression — mirroring the shape used by the `session-resume-strip-pause-footer` task that shipped this morning.

## Work Tree

- [x] T1 Edited `skills/feature-finalize/SKILL.md` §1: extended the `docs/product/wbs.md` bullet (line 29) with a new sub-bullet "**WBS per-task checkbox tick (required):**" that directs the agent to convert `- [ ]` → `- [x]` **within that WP's section only** (between this WP's heading and the next WP heading or EOF), with a one-line rationale ("the WP being shipped means by definition all its tasks landed") AND an explicit anti-pattern callout ("Do **not** use a global `replace_all` across the whole file — that would mistakenly tick checkboxes in other WPs that are still in-progress").
- [x] T2 Added structural `grep_check` pin in `tests/check-structure.sh` Phase 3, immediately after the existing line-96 pin (`feature-finalize references CHANGELOG convention`). Pin anchor: `"WBS per-task checkbox tick"` (the literal sub-bullet header from T1, naturally robust to surrounding prose edits). Comment block explains the §1 origin + the 12-of-12 v3-cycle recurrences from `SURFACE-2026-05-29-FEATURE-FINALIZE-MISSES-WBS-TASK-CHECKBOXES` to motivate why the pin is load-bearing.
- [x] T3 `./tests/check-structure.sh` → **141/141 PASS, FAIL: 0** (was 140/140; clean +1 from the new pin, no triage needed). Wall-clock 17s; runtime registry updated to `**Last:** 17s (2026-06-10)` + `**Use timeout:** 87000`.
- [x] T4 Live symlink check: `grep -c "WBS per-task checkbox tick" ~/.claude/skills/feature-finalize/SKILL.md` returns `1`. Edit is live in the harness via the directory symlink — no `install.sh` re-run needed.

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete — ready for /task-close
- **Blocked:** none
- **Unvisited:** (none)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect
- **What changed in our understanding:** Nothing new — this task was a near-perfect structural twin of `session-resume-strip-pause-footer` (the previous task in this session): same shape (one SKILL.md edit + one Phase 3 pin), same precedent location, same harness symlink reachability. The pattern of "one-edit-plus-one-pin task targeting a workflow-skill discipline gap" continues to be the cleanest task shape in this repo.
- **Assumptions that held:** (1) The §1 WBS-update bullet was the right slot — adding a `**WBS per-task checkbox tick (required):**` sub-bullet immediately under the existing `docs/product/wbs.md` line kept the prose grouped with its sibling. (2) The Phase 3 pin location adjacent to line-96 `feature-finalize references CHANGELOG convention` was the right precedent — same target SKILL.md, same regression mechanism (silent removal during future edits), same `grep_check` shape. (3) Anchor phrase `"WBS per-task checkbox tick"` is robust — it's the literal sub-bullet header so any future prose-restructuring that drops the discipline would also drop the header. (4) `install.sh` re-run not needed because the skill directory is symlinked.
- **Assumptions that were wrong:** None. The plan's 4-step shape (T1 edit → T2 pin → T3 check-structure → T4 live-symlink) executed exactly as designed, with the same `141/141 PASS, +1 from prior` outcome anticipated at plan-time.
- **Approach delta:** None. The plan and execution were identical down to the count expectation. Worth noting: the anti-pattern callout in the SKILL.md edit ("Do **not** use a global `replace_all` across the whole file") was added during T1 as a small enhancement over the strict minimum scope — the backlog entry's risk note flagged the global-replacement failure mode, and capturing it in the SKILL.md prose itself (not just in the surrounding rationale) makes the discipline harder to misread under autopilot. Did not change the task structure — just slightly thicker prose in the same single edit.
