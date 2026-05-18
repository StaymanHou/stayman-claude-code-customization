---
drive_mode: autopilot
---

# Feature: claude-time report --by grouping dimension

**Workflow:** feature
**State:** ship (complete)
**Created:** 2026-05-18
**Entry:** plan (small/simple feature — F2)
**Source:** SURFACE-2026-05-18-CLAUDE-TIME-REPORT-BY-PROJECT (backlog)
**Drive mode:** autopilot

## Problem Statement

`claude-time report` currently supports `--cwd` only as a **filter** — pick one project, see its totals. The user request from Phase 3 verify-human of the parent feature was for a **grouping dimension**: show all projects side-by-side with their tool / active / gap-bucket totals so the user can see "where my time goes" across the whole machine without running N filtered reports.

The data is already captured (`cwd` is a column on every event row, `session_id` likewise, the timestamp gives day-of-week trivially). This is a CLI-side change only — no schema migration, no hook changes, no reclassifier algorithm changes. The existing per-session breakdown in the `Reclassified gap buckets` section already proves the rendering pattern; this generalizes it to three group-by axes.

A follow-up enhancement (Phase 2) adds optional `~/.claude-time/config.json` `project_names` map for human-readable cwd aliasing (e.g., grouping a main repo + worktree under one logical project name).

## Acceptance Criteria

1. **`--by cwd` groups events by working directory.** `claude-time report --by cwd` produces a table where each row is one distinct `cwd` value, with columns for tool time (total), active time, and gap buckets (reading/thinking/away). Rows are sorted by total time descending.

2. **`--by session` groups by session_id.** Replaces the existing per-session breakdown's inline placement with a top-level grouped report when the flag is given. Same column layout as `--by cwd`.

3. **`--by day` groups by calendar date (local TZ).** Each row is one YYYY-MM-DD; especially useful with `--weekly` to see daily distribution.

4. **`--by` composes with existing filters.** `--by cwd --weekly` shows per-cwd totals over the last 7 days. `--by cwd --session sX` is permitted but degenerate (one row); document as supported but not useful.

5. **Default behavior unchanged.** When `--by` is absent, output is byte-identical to the current report shape — no whitespace, ordering, or header changes. Existing `test_cli.sh` (10 assertions) continues to PASS unmodified.

6. **Invalid `--by` value errors clearly.** `--by foo` exits non-zero with a message listing valid dimensions; argparse `choices=` is sufficient.

7. **Empty-window message respected.** `--by cwd` on a date with no events prints the same `(no events in window: ...)` message as the default report.

8. **Optional config aliasing (Phase 2).** `~/.claude-time/config.json` may carry an optional `project_names` map: `{"my-thing": ["/Users/me/repo", "/Users/me/repo-worktree"]}`. When present and `--by cwd` is used, multiple cwds that map to the same project name are summed into one row labeled with that name. Cwds not in the map are rendered with their full path. Absent map = current per-cwd behavior.

## Out of Scope

- Schema migration (none needed — `cwd`, `session_id`, `ts` all already columns).
- Hook changes (none needed).
- Grouping by tool_name or agent_type (existing report already breaks these down per-row; not what the user asked for).
- Multi-dimension grouping (`--by cwd,day` for a 2-D matrix) — possible v3, not requested.
- Removing `--cwd` filter — both modes (filter and group) coexist.

## Work Tree

- [x] Phase 1: --by grouping dimension (cwd | session | day)  <!-- All impl + verify leaves [x]. -->
  **Observable outcomes:**
  - CLI: `claude-time report --by cwd` exits 0 against a seeded DB with events in 2 distinct cwds; stdout contains both cwd values as row labels and one totals column per metric (tool time, active, reading, thinking, away).
  - CLI: `claude-time report --by session` exits 0 against a seeded DB with 2 sessions; stdout contains both short session IDs as row labels.
  - CLI: `claude-time report --by day --weekly` exits 0 against a DB with events on 3 different days within the last 7; stdout contains exactly 3 date-labeled rows in YYYY-MM-DD format.
  - CLI: `claude-time report` (no `--by`) produces output byte-identical to the pre-change baseline — verified by capturing baseline before Phase 1 and diffing after.
  - CLI: `claude-time report --by foo` exits non-zero and stderr contains the string `cwd`, `session`, and `day` (argparse choices listing).
  - CLI: `claude-time report --by cwd --date 1970-01-01` exits 0 and stdout contains `(no events in window`.
  - [x] P1.1 Refactor `render_report` to extract a `_render_grouped(events, group_by, cfg)` helper that produces the per-group totals row layout. The existing default render becomes the no-grouping path. Pure refactor — no behavior change yet. <!-- Adjustment during build: chose to add a new `render_grouped` function alongside the existing `render_report` (which stayed byte-identical) rather than threading a `group_by` arg through the existing renderer. Cleaner separation: the default report has a 4-section layout (Tool/Subagent/Active/Gaps) that doesn't generalize to a row-per-group table. Two functions, dispatched from main(). Baseline byte-diff verified clean. -->
  - [x] P1.2 Add `--by {cwd,session,day}` argparse flag with `choices=` validation.
  - [x] P1.3 Implement the grouped table renderer: group events by the chosen dimension, compute tool_durations_ms / session_active_ms / gap_buckets per group, format as a single aligned table with sorted-by-total rows.
  - [x] P1.4 Wire `--by` through `main()` to call the grouped renderer when set; default unchanged.
  - [x] P1.5 Update `README.md` Usage section: add `--by` examples and one example output block showing a 3-row per-cwd table.
  - [x] verify-auto  <!-- py_compile + import smoke (GROUP_DIMS, render_grouped, _group_key present) + test_cli.sh 10/10 PASS (default-report invariant confirmed) -->
  - [x] verify-self  <!-- All 6 observable outcomes PASS via direct CLI verification (no browser surface; Playwright N/A). Integration boundary satisfied (consuming surface = `claude-time report` CLI; outcomes cite it). -->
  - [x] verify-human  <!-- All 5 leaves approved by human 2026-05-18 ("all good"). Integration-boundary capture satisfied. -->
    - [x] P1.verify-human.1 Run `claude-time report --by cwd` on real recent data; grouped table reads well at a glance.
    - [x] P1.verify-human.2 Run `claude-time report --by session --weekly` on real recent data; session IDs readable, ordering correct.
    - [x] P1.verify-human.3 Run `claude-time report --by day --weekly`; date-by-date breakdown answers "which day most time?" directly.
    - [x] P1.verify-human.4 README Usage `--by` examples + example output block accurate against CLI behavior.
    - [x] P1.verify-human.5 Grouped view answers the original "where does my time go across projects?" question better than N filtered reports.
  - [x] verify-codify  <!-- test_cli.sh extended from 10 to 17 assertions covering --by cwd/session/day, --by foo error, --by empty-window, sort order, and default-report-unchanged regression guard. Full claude-time suite: test_cli.sh 17/17, test_reclassify.py 24/24, test_hook.sh 17/17. Structure check 109/1 FAIL is pre-existing settings-fixture drift unrelated to this feature (see Test Triage below + Discoveries SURFACE). -->

- [x] Phase 2: project_names aliasing in config.json  <!-- All impl + verify leaves [x]. Scope expanded in-phase to include P2.4 auto-alias (git-repo basename + misc bucket) per user request. -->
  **Observable outcomes:**
  - CLI: With `~/.claude-time/config.json` containing `{"project_names": {"my-thing": ["/a", "/b"]}}` and a DB containing events under both `/a` and `/b`, `claude-time report --by cwd` produces a row labeled `my-thing` whose totals equal the sum of `/a` and `/b` events (and `/a` / `/b` no longer appear as separate rows).
  - CLI: With no `project_names` key in config (or no config at all), `--by cwd` behavior is identical to Phase 1 (one row per distinct cwd, full path label).
  - CLI: With `project_names` set but events from a cwd not in any alias list, that cwd appears with its full path as its own row (unaliased cwds passed through).
  - CLI: Malformed `project_names` (e.g., string instead of list) is silently ignored — falls back to no-aliasing behavior, exit 0. (Consistent with existing config-malformed handling in `load_config`.)
  - [x] P2.1 Extend `load_config` to accept `project_names` as an optional dict-of-list-of-strings; validate shape (drop on malformed). <!-- Added `project_names: {}` to DEFAULT_CONFIG so it has a default. Refactored load_config to handle project_names via a dedicated `_validate_project_names` helper (silent-drop on malformed at the per-entry level too — e.g. {"oops": "not-a-list"} drops "oops" but keeps any valid entries). -->
  - [x] P2.2 In the `--by cwd` grouped renderer, apply the alias map: build reverse-index `{cwd_path: project_name}`, group by mapped name (or raw cwd if unmapped). <!-- Reverse-index built inside render_grouped before the partition loop. Only consulted when dim == "cwd"; --by session/day ignore it. -->
  - [x] P2.3 Update `README.md` Tuning section: document `project_names` shape, semantics, and the worktree use-case example. <!-- Bullet added to Tuning section; example JSON shows the worktree alias pattern. -->
  - [x] P2.4 Auto-alias unconfigured cwds. Precedence: explicit `project_names` map wins; otherwise if cwd is inside a git repo, use `basename(repo_root)`; otherwise label as `misc`. Cwd existence is a precondition — gracefully treat missing-cwd as `misc`. <!-- Implemented `_auto_alias_for_cwd` with mutable-default-arg cache (process-scoped LRU; module is short-lived). Uses `git -C <cwd> rev-parse --show-toplevel` with 2s timeout. End-to-end verified on real DB: 3 project basenames + misc bucket (Step 1), explicit config still wins (Step 2). README updated with "Auto-alias for --by cwd" section. -->

  **Scope expansion 2026-05-18 (in-phase, no F23 back-loop):** During verify-human, captured-output showed friendly aliases work but still require manual config for every project. User requested auto-alias by `basename` for project cwds + `misc` bucket for non-project cwds (e.g. `/Users/stayman` where Claude Code was used for one-off `ffmpeg` work). Confirmed as a "single dev cycle" expansion rather than a back-loop. Adds P2.4 + 2 new observable outcomes; verify-self/human/codify will re-cover the expanded surface.

  **Added observable outcomes (P2.4):**
  - CLI: Without any `project_names` config, `claude-time report --by cwd` on a DB containing events under a git-repo cwd (e.g. `/Users/me/projects/foo`) renders that row labeled `foo` (the basename of the repo root), not the full path.
  - CLI: Without any `project_names` config, `claude-time report --by cwd` on a DB containing events under a non-git cwd (e.g. `/Users/me` itself) renders that row labeled `misc`. Multiple distinct non-git cwds aggregate into a single `misc` row.
  - CLI: With explicit `project_names` config naming a cwd, the explicit name wins over the auto-derived one (existing Phase 2 P2.2 behavior preserved).

  ### Phase-Advance Relevance Check (before Phase 2):
  - Requester still needs this: yes — SURFACE explicitly listed project_names as optional follow-up; same user request.
  - Requirements unchanged: yes — config-side aliasing only, semantics unchanged from plan.
  - Solution still feasible: yes — load_config dict-merge pattern extended cleanly; no architectural drift.
  - No superior alternative discovered: yes — alternatives (CLI flag, env var, separate file) all worse ergonomics than reusing config.json.
  **Verdict:** proceed.
  - [x] verify-auto  <!-- py_compile OK + import smoke (_validate_project_names callable, DEFAULT_CONFIG project_names default {}) + validator property check across 4 shapes (top-level non-dict, value-not-list, non-string in list, valid) all silent-drop correctly + test_cli.sh 17/17 PASS (Phase 1 invariants intact) -->
  - [x] verify-self  <!-- All 8 observable outcomes PASS via direct CLI verification: 4 from original Phase 2 (P2.1-P2.3) plus 4 new from P2.4 (git-repo basename, misc bucket, explicit precedence, misc aggregation). Real-data capture confirmed against user's actual DB. -->
  - [x] verify-human  <!-- All 5 leaves approved by user 2026-05-18. P2.verify-human.{1,3} confirmed during initial captured-output. P2.verify-human.{2,4,5} accepted via real-data capture in conversation (auto-alias produced project basenames + misc bucket on user's actual DB). Integration-boundary capture: see "Step 1" capture earlier in build/verify-human exchange. -->
    - [x] P2.verify-human.1 Captured-output: alias config produces expected before/after on real data. Agent capture, user confirmation.
    - [x] P2.verify-human.2 README Tuning section + new "Auto-alias for --by cwd" subsection accepted by user.
    - [x] P2.verify-human.3 Subjective: aliasing solves the multi-cwd/worktree problem. User confirmed.
    - [x] P2.verify-human.4 Auto-basename alias works without any config — verified against real DB (3 project basenames rendered).
    - [x] P2.verify-human.5 Misc bucket: /Users/stayman (non-git, ffmpeg work) collapsed under `misc`.
  - [x] verify-codify  <!-- test_cli.sh extended from 17 to 25 assertions (8 new for Phase 2): project_names alias collapse + sum, project_names malformed silent-drop (entry-level + top-level), auto-alias git-repo basename, auto-alias nested cwd, auto-alias non-git → misc, auto-alias misc aggregation across multiple non-git cwds, explicit precedence over auto. Full claude-time suite: 25 + 24 + 17 = 66/66. Structure check 109/1 same pre-existing settings-fixture-drift FAIL as Phase 1 codify (same triage applies — out of scope; carried-over SURFACE). -->

## Current Node
- **Path:** Feature > ship
- **Active scope:** Feature complete. All Phase 1 + Phase 2 (incl. P2.4 scope expansion) leaves [x]. Next: /feature-ship.
- **Blocked:** none
- **Unvisited:** none (all phases complete; ship → finalize → reflect remain)
- **Open discoveries:** SURFACE-2026-05-18-CLAUDE-TIME-TOTAL-COL-ROW (next feature per user, high priority), SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME (carried from Phase 1, separate task)
- **Open discoveries:** SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME (separate task — fixture out of sync with documented install end-state)

## Test Triage — `settings fixture in sync with live (modulo documented diffs)`
**Classification:** Obsolete test (fixture stale; doesn't know about claude-time hooks the previous shipped feature's README documents as the install end-state).
**Confidence:** high — the failure has exactly one plausible explanation: the user followed the install instructions in `tools/claude-time/README.md` (steps 2 and 3), and the structure-check fixture `tests/fixtures/settings.json` hasn't been updated to match. Every drift line maps 1:1 to the documented install block (10 hook entries + 1 env var).
**Evidence:** All 9 drift lines are claude-time-hook references or `CLAUDE_TIME_TRACKING` env. None of this feature's changes (`tools/claude-time/claude-time`, `tools/claude-time/README.md` Usage section only, `tools/claude-time/test/test_cli.sh`) touched fixtures, install.sh, or settings. `git diff --name-only HEAD` shows only the three feature files + a pre-existing workflow/archive file from before this session.
**Action:** Out of scope for this feature. Surfaced as `SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME` in `workflow/backlog.md`; should be resolved with a small task that either (a) adds the claude-time hooks to `tests/fixtures/settings.json` or (b) adds them to `INTENTIONAL_DIFFS` in `tests/check-structure.sh` since they're per-machine install state.

## Discoveries
- [SURFACED-2026-05-18] Phase 1 verify-codify — settings-fixture drift in `tests/check-structure.sh` is pre-existing (caused by prior claude-time feature's install instructions being followed). Logged as `SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME`.
- [SURFACED-2026-05-18] Phase 2 verify-human — User requested per-row "total" column + per-column "TOTAL" row for the grouped table. Logged as `SURFACE-2026-05-18-CLAUDE-TIME-TOTAL-COL-ROW` at high priority (designated as the next feature).
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect

- **What changed in our understanding:** Phase 2 originally scoped only the `project_names` config — explicit, opt-in aliasing. The verify-human exchange revealed the user actually wanted the alias to be the *default behavior* (`basename` for git repos, `misc` for non-projects). The plan's mental model — "alias is an opt-in escape hatch" — was inverted by the lived experience of looking at the actual report output. The user's "where does my time go" question is fundamentally project-shaped, not cwd-path-shaped.
- **Assumptions that held:**
  - The CLI surface was the right place to add this — no schema migration needed, no hook changes, no reclassifier changes. Single-file impact + extending test_cli.sh was right-sized.
  - Existing `load_config` dict-merge + silent-fallback pattern extended cleanly to `project_names`; no architectural drift.
  - The verify-codify test set's "exercise the consuming surface end-to-end" rule paid off again: codify caught the Phase 1 `--by cwd` fixture regression (test asserted on `/foo` and `/bar` raw paths which Phase 2 P2.4 collapses into `misc`). Without that, the regression would have shipped silently.
- **Assumptions that were wrong:**
  - Plan assumed `project_names` was the load-bearing UX win. It's actually a fallback for power users; auto-alias is the load-bearing default. Almost everyone with claude-time enabled is using it from project dirs that ARE git repos.
  - Plan listed only one Observable Outcome for the aliasing behavior. Sum-vs-relabel distinction was implicit but not stated — verify-self's sum-check ("5.5s = 5.0s + 500ms") was added on the fly because the agent noticed the gap, not because the plan required it. Plans should explicitly require sum-checks when "merge multiple things into one row" is part of an outcome.
  - The empty-string edge case in `_auto_alias_for_cwd` ("" → resolved to current process CWD's basename via `git -C`) was caught only after the verify-auto property check. Plan didn't enumerate this input shape; the property-test discipline did the catching.
- **Approach delta:**
  - **Mid-Phase-2 in-phase scope expansion (P2.4 added):** Not a back-loop to plan (F23) — user explicitly framed it as "single dev cycle". Tracked in the WIP under the existing Phase 2 node with new observable outcomes appended. Verify-self + verify-human re-ran on the expanded surface. This pattern (in-phase expansion without F23 ceremony) worked, but only because the addition was tightly scoped and aligned with the original problem. Riskier expansions should still take the F23 ceremony for the problem-statement re-check.
  - **Test fix-up on the fly:** When P2.4 caused two Phase 1 `--by cwd` assertions to fail (`/foo` and `/bar` no longer survive as row labels), the fix was to add an explicit `project_names` config in the test fixture rather than restructure the test environment. This kept the test's narrative scope ("verify --by cwd grouping behavior") intact rather than rewriting it for Phase 2's new defaults.
  - **Agent-self-captured boundary check:** verify-human's integration-boundary capture requirement was originally "user pastes the output back". User asked "can you capture the output yourself, right?" — yes, agent can read user's real DB. This is a faster + lower-friction path for CLI-only features where the agent has the same read access as the user. Worth considering as the default for CLI feature verify-human steps; not a regression.

## Notes for build

- **Tech contract:** Python 3 stdlib only (matches existing CLI). No new deps. Renderer stays in the single `claude-time` script — don't split into modules; the file is ~270 lines and one more renderer fits comfortably.
- **Render symmetry:** the existing default report has 4 sections (Tool / Subagent / Active / Gaps). The grouped view collapses these into a single wide table with rows = groups, columns = metric totals. This is intentional — the default view is "what kind of time" (axis = metric), the grouped view is "where the time went" (axis = group). Don't try to render four sub-tables per group.
- **Column choice for grouped view:** suggested columns are: `tool_total | active | reading | thinking | away`. Subagent total is rare and noisy at the per-row level — leave it out of the grouped table (it's still in the default view). If a user wants per-group subagent totals later, that's a v3 ask.
- **Sort order:** sort rows by `tool_total + active` descending (the "engagement total"). Tie-break alphabetically on the label.
- **Day grouping TZ:** use the same `date.today()` local-TZ logic the `window_ms` helper already uses. Don't introduce UTC — would create an off-by-one display issue at midnight-local for the user.
- **Phase 2 aliasing is independent.** If anything goes wrong in Phase 1 verify-human, Phase 2 can be dropped (or back-burnered) without affecting the primary `--by` value. Don't couple them.
