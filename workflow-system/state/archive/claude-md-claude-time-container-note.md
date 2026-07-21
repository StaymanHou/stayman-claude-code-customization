---
workflow: task
state: act-complete
drive_mode: autopilot
created: 2026-06-10
surface_id: SURFACE-2026-05-22-CLAUDE-MD-MISSING-CLAUDE-TIME-CONTAINER-NOTE
---

# Task: CLAUDE.md missing claude-time container note

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-06-10

## Problem Statement
Project root `CLAUDE.md` § Commands lists the workflow-system test runner but doesn't mention that `tools/claude-time/` tests run inside a Docker container via `tools/claude-time/test/run-in-container.sh`; a contributor reading the project-root file would assume host-side tests are supported.

## Context
- Target file: `CLAUDE.md` (project root) — insertion point right after the workflow-system test runner block ending at line 27, before `## Architecture` at line 29
- Wrapper: `tools/claude-time/test/run-in-container.sh` — subcommands: start, stop, restart, status, exec, logs, help
- Canonical invocations live in: `tools/claude-time/README.md` → `## Running tests` (line 331)
- Backlog item: P3 = `SURFACE-2026-05-22-CLAUDE-MD-MISSING-CLAUDE-TIME-CONTAINER-NOTE` in `workflow/backlog.md`

## Work Tree

- [x] T1 Edit `CLAUDE.md` — append a single paragraph after line 27 (the existing test-runner narrative) and before line 29 (`## Architecture`). Content: container is the canonical test path for `tools/claude-time/`; lifecycle wrapper at `tools/claude-time/test/run-in-container.sh` with `start|stop|restart|status|exec|logs|help` subcommands; image bundles Python 3.12 + Perl + sqlite3 + jq + Node + Playwright + Chromium; project root bind-mounts at `/work` rw; see `tools/claude-time/README.md` → "Running tests" for canonical invocations.
- [x] T2 Verify: `./tests/check-structure.sh` returns 141/141 PASS (confirmed — PASS: 141 | FAIL: 0).

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect
- **What changed in our understanding:** Nothing — the backlog entry's `**Suggested action:**` field already prescribed the exact paragraph content + insertion location. The pickup window (post-WP5, no cross-feature dirty-tree contention) was the only thing that needed waiting.
- **Assumptions that held:** Single paragraph + single Edit + zero new structural pins. Check-structure stayed at 141/141, runtime unchanged at 17s.
- **Assumptions that were wrong:** None.
- **Approach delta:** None — implementation matched plan exactly. No surprises.
