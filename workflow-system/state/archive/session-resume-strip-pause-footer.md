---
drive_mode: full-autopilot
---

# Task: Add §6b "strip stale Pause footer" step to session-resume SKILL.md

**Workflow:** task
**State:** act (complete)
**Created:** 2026-06-10

## Problem Statement
`/session-resume` deletes `workflow/.session.md` (§7) but does NOT strip the orphan `## Session Pause — <timestamp>\nPaused. See workflow/.session.md to resume.` block that `/session-pause` injected at the END of `state_file` — every paused-then-resumed item accrues a 10–30s cleanup tax at finalize/close time (NeoStayman observed 18+ recurrences across WP4–WP30; this repo has hit it on `workflow/backlog.md` this very session and on `workflow/archive/verify-human-auto-skip-when-no-integration-boundary.md` prior).

## Context
- Backlog source: `SURFACE-2026-06-07-SESSION-RESUME-LEAVES-PAUSE-FOOTER` (now P3, `workflow/backlog.md` after this morning's renumber)
- Skill to patch: `skills/session-resume/SKILL.md` (which `install.sh` symlinks into `~/.claude/skills/session-resume/SKILL.md` — single-source-of-truth edit propagates immediately to the live harness)
- Sibling skill that creates the footer: `skills/session-pause/SKILL.md` §3 (lines 47–52) — always appends to EOF, exact shape:
  ```
  ## Session Pause — <YYYY-MM-DD HH:MM>
  Paused. See `workflow/.session.md` to resume.
  ```
- Insertion point in resume: between current §6 (Backlog check) and §7 (Delete `.session.md`). The backlog entry's suggested action explicitly named §6b as the slot.
- Match shape: a single trailing block. Since `/session-pause` always appends to EOF and there's no documented mid-document inject variant, the match is unambiguous — strip the `## Session Pause — ` heading + following body up to EOF. Idempotent (no-op if marker absent).
- This task itself dogfoods the gap: this morning I stripped the orphan footer from `workflow/backlog.md` manually as part of session-resume cleanup. After this task ships, that manual step becomes unnecessary in future resumes.

## Scope assessment
- Task-level. Single SKILL.md edit (~6 lines of procedure text). No state-machine change, no new transition, no AGENTS.md edit, no transitions.md edit (S6/S15/S16 unchanged — §6b is sub-procedural, not a new transition).
- One structural pin in `tests/check-structure.sh` to anchor the new step + prevent silent regression: `grep_check` that `skills/session-resume/SKILL.md` contains a `Session Pause` strip directive.

## Work Tree

- [x] T1 Edited `skills/session-resume/SKILL.md`: inserted §6b "Strip the stale Pause footer from `state_file`" between §6 and §7. Procedure cites `session-pause` SKILL.md §3 as the always-appends-to-EOF authority; idempotent; documents the forward-compatible "until next `## ` or EOF" extension for any future mid-document `/session-pause` variant.
- [x] T2 Added structural `grep_check` pin in `tests/check-structure.sh` Phase 3 (right after the In-place fix shortcut pin which is the closest precedent — both anchor a skill-prose subsection). Comment block explains the §6b origin + the 18+ recurrences observed in NeoStayman to motivate why the pin is load-bearing.
- [x] T3 `./tests/check-structure.sh` → **140/140 PASS, FAIL: 0** (was 139/139; +1 from the new pin landed cleanly, no triage needed).
- [x] T4 Live symlink check: `~/.claude/skills/session-resume` is a directory symlink (Apr 18) pointing at `skills/session-resume/` in this repo — `grep -c "Strip the stale Pause footer" ~/.claude/skills/session-resume/SKILL.md` returns 1. Edit is live, no `install.sh` re-run needed.

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete — ready for /task-close
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->

## Retrospect
- **What changed in our understanding:** One brief detour: `readlink ~/.claude/skills/session-resume/SKILL.md` returned empty in T4, momentarily suggesting the symlink was stale (and the live skill wouldn't see the edit). Resolution: `~/.claude/skills/session-resume` is a **directory** symlink (one level higher than I queried), not a file symlink — `readlink` on the inner `SKILL.md` correctly returned empty because that path is a regular file inside the symlinked directory. The edit was live all along; `grep -c` on the same path confirmed `1` match. Minor self-confusion, but worth recording because the same pattern will recur on any future structural check involving the install.sh symlink layout.
- **Assumptions that held:** (1) §6b was the right slot (between current §6 backlog-check and §7 .session.md delete) — the backlog entry's suggested action named the exact placement. (2) The single trailing block is the only shape `/session-pause` produces (verified by reading the pause skill before patching). (3) `tests/check-structure.sh` Phase 3 with a sibling `grep_check` next to the In-place fix shortcut pin was the right precedent — both are skill-prose subsection anchors with the same regression mechanism (silent removal during future edits). (4) `install.sh` re-run not needed because skill directories are symlinked, not files copied.
- **Assumptions that were wrong:** None substantive. The momentary `readlink` confusion in T4 was operator error, not an actual symlink failure.
- **Approach delta:** None. T1 (SKILL.md edit) → T2 (structural pin in check-structure.sh Phase 3) → T3 (140/140 PASS clean, +1 vs prior 139) → T4 (live-symlink reachability confirmed). Four steps, four green checkpoints, no back-loops.

