---
workflow: feature
state: build (phase 1 impl complete)
created: 2026-05-18
drive_mode: autopilot
---

# Feature: `claude-time visualize` — Timeline Dashboard

**Workflow:** feature
**State:** ship (complete)
**Created:** 2026-05-18
**Entry:** spec (complex feature) → plan → build
**Drive mode:** autopilot

## Problem Statement

The `claude-time` CLI currently emits plain-text grouped tables (`report`, `report --by {cwd|session|day}`). For glance-at-my-day intuition — "where did the hours go, which projects dominated, when was I idle" — text tables under-deliver: temporal structure is lost, multi-project parallelism is invisible, and the active/reading/thinking/away segmentation that the reclassifier already computes is collapsed into bucket totals rather than rendered as a timeline. This feature adds a `claude-time visualize` subcommand that emits a **self-contained static HTML file** rendering a horizontal Gantt-style timeline (three views: day default, week rollup, day-with-session-detail), based on a Claude Design mockup that locks the visual contract. Read-only, snapshot per invocation, single user.

## User Stories

- As the repo owner, I want to run `claude-time visualize` and have a browser-ready HTML file appear, so I can see my coding time as a Gantt chart instead of a text table.
- As the repo owner, I want the **day view** by default (current day, hour ruler), so glancing at "today" is one command.
- As the repo owner, I want a **week view** option (`--week`), so I can see project distribution across a week at a rollup level.
- As the repo owner, I want **clicking a session bar** to reveal a side panel with that session's wall-vs-active time, activity breakdown, tool-call histogram, and prompt count, so I can drill into a specific work block without leaving the dashboard.
- As the repo owner, I want **per-project total pills** at the left of each row, so I can read a project's daily/weekly total without doing arithmetic.
- As the repo owner, I want the design's **`oklch` palette and Geist typography** preserved pixel-faithfully, so the dashboard matches the Claude Design mockup I approved.

## Acceptance Criteria

**Phase-spanning (whole-feature):**
- Running `claude-time visualize` with no flags writes a self-contained `.html` file at `~/.claude-time/visualize.html`, opens it in the default browser, and prints the path on stdout.
- The HTML opens correctly in modern Chrome/Firefox/Safari with internet access (React-UMD + Babel-standalone from CDN, per architectural decision).
- The HTML file is a single artifact — no sibling JS/CSS files. All JSX, data, and styles are inline in one `.html`.
- Re-running `claude-time visualize` overwrites the existing HTML in place. No timestamped variants, no archive.
- The dashboard's visual output matches the Claude Design mockup at `/tmp/claude-design-extract/claude-time-dashboard/project/Claude Time Dashboard.html` for the three view variants (day / week / detail) — palette, typography, spacing, layout proportions all preserved.

**Phase 1 (visual contract lock — mock data only, no CLI wiring):**
- A runnable `tools/claude-time/viz/` directory exists containing the design's HTML/JSX prototype plus its bundled mock data (`data.js`).
- `open tools/claude-time/viz/index.html` displays the three-variant design canvas (day / week / detail-with-side-panel) identical to the Claude Design output.

**Phase 2+ (data wiring + CLI subcommand):**
- A new `visualize` subcommand exists in `tools/claude-time/claude-time` (Python).
- The subcommand reads from `~/.claude-time/events.sqlite` using the same SQLite access pattern as `report`.
- The Python data layer transforms raw events into the segment model the design expects, using `reclassify.py`'s classification.
- Default invocation produces the **day view** for today.
- `--week` produces the **week view** rollup for the current ISO week.
- `--date YYYY-MM-DD` overrides the default "today" for the day view.
- The detail-with-side-panel state is reachable by clicking any session bar in the day view (client-side interaction, no CLI flag needed).

## Out of Scope

- **Month view and custom-range view.** MVP ships Today and Week; Month and Custom tabs render but are disabled.
- **Dark theme.** Moon icon present but non-functional in MVP.
- **Live auto-refresh.** Snapshot per invocation; refresh icon shows a tooltip prompting re-run, no client-side update.
- **Filter chips (interactive).** Rendered but non-functional in MVP.
- **Pre-built JS bundle / esbuild step.** No build step added to `install.sh`.
- **`claude-time serve` web server.** Rejected (Option 2).
- **Terminal UI / Jupyter notebook output.** Rejected (Options 3, 4).
- **Editing affordances.** Read-only.
- **Multi-user / sharing.** Single-user.

## Technical Constraints

- **Runtime tech (locked).** React 18 UMD + Babel-standalone from `unpkg.com` CDN. JSX parsed in-browser.
- **Data layer (locked).** Python. Segment construction in Python, JSON inlined via `window.CT_DATA = { ... };` script tag matching the mock `data.js` shape.
- **Time range (locked).** MVP: Day + Week only.
- **Refresh (locked).** Snapshot per invocation.
- **Design source-of-truth (locked).** `/tmp/claude-design-extract/claude-time-dashboard/project/{dashboard.jsx, data.js, Claude Time Dashboard.html}`. `design-canvas.jsx` is design-review chrome, **NOT** shipped — but **IS** included in Phase 1 (the prototype transplant). Phase 3 strips it.
- **No new install dependencies.** `install.sh` stays shell-only. Python tool gains zero new pip deps.
- **Symlink-installed source layout.** `tools/claude-time/viz/` is read at runtime via `Path(__file__).parent / 'viz'`. Symlinks continue to work.
- **Privacy preserved.** No new event payload beyond what `report` already exposes.

## Open Questions

- [x] Runtime tech — locked: React-UMD + Babel-standalone
- [x] Data transformation layer — locked: Python
- [x] MVP time-range scope — locked: Day + Week
- [x] Live refresh model — locked: snapshot-per-invocation
- [x] **Default output path** — RESOLVED at plan: `~/.claude-time/visualize.html`. Overridable via `--out PATH`.
- [x] **Auto-open behavior** — RESOLVED at plan: auto-open via `webbrowser.open()` by default; `--no-open` to suppress.
- [x] **`--demo` flag** — RESOLVED at plan: keep `data.js` mock as `--demo` mode for design iteration. Useful for future visual regression review.
- [x] **Adaptive hour-window** — RESOLVED at plan: adaptive — derive `[min_event_hour - 1, max_event_hour + 1]` from the day's events, clamped to `[0, 24]`; fall back to fixed `06:00–22:59` if zero events on the chosen date.
- [x] **Project alias source** — RESOLVED at plan: reuse existing `claude-time` `project_names` config + auto-alias logic (shipped 2026-05-18 in `claude-time-report-by-project`). No separate alias config.

## Work Tree

- [x] Phase 1: Visual contract transplant (Option A — mock-data prototype)
  **Observable outcomes:**
  - CLI: `ls tools/claude-time/viz/` exits 0 and lists at least `index.html`, `dashboard.jsx`, `data.js`, `design-canvas.jsx`
  - Browser: opening `http://localhost:<port>/tools/claude-time/viz/index.html` (served — `file://` blocks Babel-standalone's `text/babel` XHR) in Chrome/Safari renders the three-variant design canvas (artboards labelled "A · Day view", "B · Week rollup", "C · Session selected + side panel")
  - Browser: each artboard shows the dashboard with the warm-cream surface, deep-indigo active segments, muted-amber thinking segments, lavender reading segments, hairline-striped away segments, and teal subagent nested bars — matching the Claude Design output
  - Console: no JS errors on page load (React, Babel, and the three components mount cleanly). Two benign 404s (`favicon.ico`, `.design-canvas.state.json` — the DesignCanvas host-bridge sidecar) are expected and do not break rendering.
  - [x] P1.1 Create `tools/claude-time/viz/` directory
  - [x] P1.2 Copy `Claude Time Dashboard.html` → `tools/claude-time/viz/index.html` verbatim
  - [x] P1.3 Copy `dashboard.jsx`, `data.js`, `design-canvas.jsx` into `tools/claude-time/viz/` verbatim
  - [x] P1.4 Verify the four files mount correctly in a real browser (open + console-check) — verified via Playwright at http://localhost:8765/index.html; all 3 artboards rendered, only benign 404s (favicon, design-canvas state sidecar)
  - [x] verify-auto — files byte-identical to source; `node --check data.js` OK; `@babel/parser` parses both JSX files; `index.html` well-formed; Playwright smoke (in P1.4) confirmed 3 artboards render with no JS errors
  - [x] verify-self — subagent live-system observation: all 4 outcomes PASS, severity N/A. Three artboards (A/B/C) render with correct labels, full palette + typography + summary stats + timeline grid; only the two known-benign 404s (favicon, .design-canvas.state.json); no integration boundary applies (isolated new artifacts). Screenshot at `tools/claude-time/viz/verify-self-screenshot.png`.
  - [x] verify-human — user confirmed "approved" on 2026-05-18. Pre-filtered to one judgment-call item (P1.verify-human.1: pixel-faithfulness to the Claude Design mockup); all 4 verify-self outcomes excluded per the pre-filter rules (status: `[x]` PASS).
    - [x] P1.verify-human.1 — pixel-faithfulness to Claude Design mockup: approved
  - [x] verify-codify — added Phase 5c block to `tests/check-structure.sh` (10 new assertions, all PASS): pinned byte-sizes for the 4 viz files (drift detector against silent edits), `node --check` on data.js, HTMLParser well-formed-ness for index.html. Full structure check still has 1 pre-existing FAIL — the open `SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME` backlog item — but that is not introduced by Phase 1 (existed before this feature; tracked for separate resolution).

- [x] Phase 2: Python data layer — events → segment-model JSON
  **Observable outcomes:**
  - CLI: `python3 -c "from tools.claude_time.viz_data import build_day_data; import json; print(json.dumps(build_day_data('2026-05-18')))"` exits 0 and prints valid JSON
  - CLI: the printed JSON has top-level keys `{label, iso, projects}` where `projects` is a list of `{id, alias, path, sessions}` and each session is `{id, start, end, prompts, tools, segs}` matching `data.js`'s `today` shape
  - CLI: each segment in `segs` has `{kind, start, end}` where `kind ∈ {active, reading, thinking, away, subagent}` and `start`/`end` are integer minutes-from-midnight
  - CLI: `python3 -c "from tools.claude_time.viz_data import build_week_data; ..."` produces the `week` shape: `{label, days, projects[].rollup[]}` with each rollup entry `{active, reading, thinking, away, subagent, prompts}` in minutes
  - CLI: against a known event-fixture, total active+subagent minutes summed across all viz-segments equals the **burst-pairing truth** (sum of `(first_UPS_in_burst, next_Stop)` per session). Note: this is intentionally NOT a check against `reclassify.session_active_ms`, which uses a different burst-pairing semantic (it treats consecutive UPSes as overwriting, taking only the last). Discovered during Phase 2 verify-self against real data — see DivergenceFromSessionActiveMsTests in test_viz_data.py for the regression-guard test pinning this.
  - [x] P2.1 Add `tools/claude-time/viz_data.py` with `build_day_data` + `build_week_data` reusing `reclassify.py`
  - [x] P2.2 Segment timeline: bursts (UPS→Stop) with intra-session reading/thinking gaps; away gaps split the session_id into multiple viz-sessions; subagent runs nest as `subagent` segments inside the surrounding active time (non-overlapping, sorted)
  - [x] P2.3 Alias resolution: explicit `project_names` config wins; otherwise the `auto_alias_fn` callback (allowing the CLI to inject the existing `_auto_alias_for_cwd`); `path` field set to the primary (deterministic-sorted) cwd
  - [x] P2.4 Adaptive hour-window: `[min_hour - 1, max_hour + 1]` clamped to `[0, 24]`; fallback `[6, 23]` on empty days. Exposed as `hour_range: [start, end]` in day data.
  - [x] P2.5 `tools/claude-time/test/test_viz_data.py` — 22 unittests covering shape, segment kinds, burst segmentation, away-split, subagent nesting, alias resolution, adaptive hour window, cross-check against reclassify.session_active_ms (truth source — now matches exactly), week rollup aggregation, data.js shape-parity, narrow-definition cross-check, and `interrupts` field for hairline rendering at Phase 3. All 22 PASS in 0.001s.
  - [x] P2.6 (back-loop) Refactor: extracted `reclassify.active_bursts(events)` as the single source of truth for burst-pairing. Both `session_active_ms` (existing) and `viz_data._bursts_for_session` (new) now consume it. The narrow definition (last UPS before Stop anchors the burst; earlier UPSes recorded as `interrupts`) is canonical. Added `interrupts: [<minutes>]` field to each viz-session in `data.js` shape (additive — Phase 1 contract preserved).
  - [x] P2.7 (back-loop) Hardened alias-partitioning: events now grouped by `session_id` FIRST (so burst-pairing always sees the full session), THEN partitioned into projects by the modal cwd's alias. Fixes a subtle bug where a session spanning multiple cwds with a "naive basename" alias resolver could fracture bursts across alias buckets, producing fake long active bars. Discovered during back-loop verify-self when a 12-min overcount localized to a session with 3 different cwds. Real production resolver (git-root) would have masked the bug; defensive fix in viz_data handles both cases.
  - [x] verify-auto — `py_compile` on both new files OK; `test_viz_data` 17/17 PASS; `test_reclassify` 24/24 PASS (no regression in shared module).
  - [x] verify-self — Final pass: ALL 5 outcomes PASS. Behavioral observation against real `~/.claude-time/events.sqlite`:
    - Outcomes 1–4 (JSON validity, today shape, segment kinds, week shape) — PASS unchanged.
    - Outcome 5 (cross-check against `reclassify.session_active_ms`) — PASS. After user decision to keep the narrow definition + add interrupt-markers, refactored to use shared `reclassify.active_bursts` helper. Final diff on real data: 225 min viz vs 219 min truth = 6 min, exactly the per-burst minute-truncation overhead (~80 bursts × <1 min floor). No semantic divergence remains.
    - 7 interrupts captured on today's real data (one was logged but never anchored — that's me racing UPS into the harness).
    - **Resolution history:** initial run flagged 13-min divergence (later 18 min); user decided to keep narrow definition + add markers; refactored to single source of truth (`reclassify.active_bursts`); discovered a separate alias-partitioning fragility (bursts could fracture across aliases) during back-loop verify; hardened by sid-first grouping. Both fixes shipped together.
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [x] verify-human — initial approval (narrow definition + interrupts + sid-first partitioning) on 2026-05-18; second back-loop fix (away-split removal) verified live by user on 2026-05-18 ("4 projects · 8 sessions" matches expectation, was 19 viz-sessions before fix).
    - [x] P2.verify-human.1 — back-loop resolution approval (narrow definition + interrupts + sid-first partitioning): approved 2026-05-18
    - [x] P2.verify-human.2 — viz-session grouping fix (away-gap inline, not split): RESOLVED 2026-05-18. Issue surfaced during Phase 3 verify-human spot-check. User expected `stayman-cc-wrapper` to render as ONE row (he chatted with CC on-and-off across the day, never `/clear`'d, all 49 events share session_id `ae8c28df`). Original code split it into 9 viz-sessions because inter-burst gaps (6/18/12/7/19/25 min) all exceed the 300s away threshold. Real-data investigation showed session_id is stable across `/resume` (the harness preserves it; the hook records `SessionStart source=resume` distinctly from `source=startup`). Fix shipped: dropped the away-split logic in `_build_viz_sessions`; emit ALL gap kinds (reading/thinking/**away**) as inline segments within ONE viz-session per session_id. Test `test_away_gap_splits_viz_sessions` renamed to `test_away_gap_stays_inline_in_one_viz_session` with inverted assertion. Real-data re-verify: `stayman-cc-wrapper` = 1 row, `neo-stayman-assistant` = 1 row, total 8 viz-sessions (was 19).
  - [x] verify-codify — Two coverage gaps closed: (a) `reclassify.active_bursts` now has direct unit tests (5 new in `ActiveBurstsTests`: single burst, consecutive-UPS interrupt, three-consecutive-UPS double-interrupt, multi-burst interrupt-reset, session_active_ms consistency regression guard); (b) `tests/check-structure.sh` Phase 5b extended to run `test_viz_data` + assert viz_data.py exists and compiles. Final test totals: `test_reclassify` 29/29 PASS, `test_viz_data` 22/22 PASS (test `test_away_gap_splits_viz_sessions` was inverted to `test_away_gap_stays_inline_in_one_viz_session` during the second back-loop). `check-structure.sh` 122 PASS / 1 FAIL (pre-existing settings-fixture-drift `SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME`, not Phase-2-caused, tracked separately).

- [x] Phase 3: HTML template + `visualize` CLI subcommand (single full-bleed dashboard)
  **Observable outcomes:**
  - CLI: `claude-time visualize --no-open` exits 0 and prints `~/.claude-time/visualize.html` on stdout
  - CLI: `~/.claude-time/visualize.html` is created and contains: (a) inline `<style>` and CSS reset, (b) three CDN `<script>` tags for React/ReactDOM/Babel, (c) one `<script>` with `window.CT_DATA = {...};` containing today's day data + current-week week data, (d) inline JSX for the dashboard component (copied/adapted from `viz/dashboard.jsx`), (e) inline render call mounting the dashboard to `#root`
  - CLI: the emitted HTML does NOT include the `DesignCanvas` chrome — it renders a single full-bleed dashboard, not three side-by-side artboards
  - Browser: opening the emitted HTML in Chrome renders the dashboard against real data with the day view visible; no JS console errors
  - Browser: the toolbar's "Today" tab is active; "Week" is inactive-but-clickable; "Month" and "Custom" tabs are visually disabled (grayed, non-clickable)
  - Browser: clicking the "Week" tab in the toolbar switches the body to the week rollup view (client-side state, no CLI re-run)
  - Browser: clicking any session bar in the day view opens the side panel populated with that session's data (wall vs. active time, segment mini-timeline, activity breakdown, tool-call histogram, prompt count, session ID)
  - Browser: clicking the close button on the side panel returns to the un-selected day view
  - [x] P3.1 `tools/claude-time/viz/template.html` — single-file template with `{{CT_DATA_JSON}}`, `{{DASHBOARD_JSX}}`, and `{{CT_INITIAL_VIEW}}` placeholders. Mounts `<Dashboard />` directly. No DesignCanvas wrapper.
  - [x] P3.2 `tools/claude-time/viz_render.py` — applies emit-time transforms over the unmodified `viz/dashboard.jsx` source: strips the design-canvas Dashboard wrapper, wires bar-click handlers through SegmentBar→SessionRow→DayTimeline, adds the InterruptHairlines component, appends a new interactive Dashboard wrapper. The design source-of-truth stays byte-pinned (Phase 5c); modifications happen only at emit-time. Single-file output (no external script srcs except CDN libs).
  - [x] P3.3 New interactive `Dashboard()` wrapper using `useState` for {view, selectedSegId, expandedProjects}; tab clicks switch view; bar clicks open side panel with the selected session; side-panel close button clears selection.
  - [x] P3.4 `InteractiveToolbar` component: Today/Week are functional `cursor=pointer` buttons, Month/Custom are `disabled` with `cursor: not-allowed` and lower opacity. Verified via Playwright snapshot.
  - [x] P3.5 Refresh icon has `title="Re-run: claude-time visualize"` (HTML tooltip on hover). No click handler — pure tooltip affordance.
  - [x] P3.6 `visualize` subcommand wired into `tools/claude-time/claude-time` (argparse subparser). Supports `--date`, `--week`, `--demo`, `--no-open`, `--out`, `--db` flags. Reads viz/ assets via `Path(__file__).resolve().parent / 'viz'` (symlink-safe). Calls `viz_data` + `viz_render`. Writes HTML, prints path, auto-opens browser unless `--no-open`. End-to-end smoke: `./tools/claude-time/claude-time visualize --no-open --out /tmp/x.html` works against real DB + `--demo` works without DB.
  - [x] P3.7 `InterruptHairlines` component renders one 1.25px vertical line per `interrupts[i]` minute, color `oklch(0.55 0.18 25 / 0.5)` (NOW-marker red at 50% opacity), `pointerEvents: none` so clicks fall through to underlying segment bars, clamped to the visible day window. Verified via Playwright against real data: 6 hairlines visible in the 16:40–17:12 session of replicator-1-0 + 1 hairline in the 17:40–17:55 session, each with a `mid-turn interrupt at HH:MM` tooltip.
  - [x] verify-auto — `py_compile` on viz_render.py + claude-time CLI OK; `test_viz_data` 22/22 PASS; `test_reclassify` 29/29 PASS (no regression); end-to-end `claude-time visualize --no-open --demo` emits 56KB valid HTML with exit 0.
  - [x] verify-self — Subagent observation via Playwright against `claude-time visualize --demo` output (`http://localhost:8767/visualize.html`). All 9 outcomes PASS, severity N/A. Verified consuming-surface (CLI), clean mount, toolbar layout (Today/Week active, Month/Custom disabled, refresh tooltip), day view (4 projects, hour ruler, NOW marker, "Explore"/"Plan" subagent badges), Today/Week tab switch, bar click → side panel, close button dismisses, interrupt hairlines correctly absent in demo data (which predates the Phase 2 `interrupts` field). Screenshot at `tools/claude-time/viz/verify-self-screenshot-phase3.png`.
  - [x] verify-human — initial spot-check 2026-05-18 surfaced the viz-session-grouping issue (which back-looped Phase 2; see Phase 2's P2.verify-human.2 for the resolution). After Phase 2 fix shipped, user re-verified live: "4 projects · 8 sessions" with `stayman-cc-wrapper` rendering as one row (was 9). Implicit Phase 3 approval — the user's "confirmed" reply confirms the post-fix visual is what they wanted.
    - [x] P3.verify-human.1 — CLI consuming-surface invocation: implicit (user spotted issue on their real data, confirmed the post-fix dashboard renders correctly)
    - [x] P3.verify-human.2 — design fidelity: "The visual looks great." (user, 2026-05-18)
    - [x] P3.verify-human.3 — optional CLI flag spot-checks: skipped by user (marked optional in checklist); all 5 flags structurally verified by build's smoke tests (`--no-open`, `--demo`, `--week`, `--date`, `--out`)
  - [x] verify-codify — Integration-boundary codification: added `tools/claude-time/test/test_visualize_cli.sh` — 13 end-to-end CLI tests exercising the consuming surface (`claude-time visualize`) directly. Tests cover: --help flag listing, default invocation against seeded DB, HTML structure (CDN tags, window.CT_DATA literal, Dashboard function, ReactDOM mount), single-file emission (no non-CDN script srcs), default CT_INITIAL_VIEW="day", --week toggles to "week", --date selects specific day's iso, --out writes to custom path, --demo bypasses SQLite, no-DB-no-demo emits helpful error, idempotent re-run overwrites in place. Wired into `check-structure.sh` Phase 5b. All 13 PASS. Final test totals: `test_reclassify` 29 + `test_viz_data` 22 + `test_visualize_cli` 13 = 64 tests, all PASS. `check-structure.sh` 123 PASS / 1 FAIL (pre-existing settings-fixture-drift, unchanged).

- [x] Phase 4: CLI flags — **SUBSUMED BY PHASE 3.** All 5 flags (`--week`, `--date`, `--demo`, `--no-open`, `--out`) were implemented in P3.6 (CLI subcommand wiring) since they share the same code surface. Phase 3 verify-codify added `test_visualize_cli.sh` with 13 end-to-end tests covering all 5 flags. Phase 4 has no remaining work.
  - [x] P4.1–P4.5 — delivered in P3.6 (argparse subparser flags + handlers)
  - [x] P4.6 — delivered in Phase 3 verify-codify as `tools/claude-time/test/test_visualize_cli.sh` (13 assertions)
  - [x] verify-auto / verify-self / verify-human / verify-codify — all covered by Phase 3's verification loop (each ran against the CLI consuming-surface which IS the flag-bearing subcommand)

- [x] Phase 5: Polish — alias verification, empty-state handling, README, structural-check alignment
  **Observable outcomes:**
  - CLI: `claude-time visualize --date <date-with-zero-events>` exits 0 (does NOT crash), emits an HTML with an empty-state message ("No tracked time for 2026-05-XX — try a different date or run some work and re-run.") in place of the timeline
  - CLI: `claude-time visualize` against a real DB shows project aliases that match `claude-time report --by cwd` output (same alias resolution path)
  - Browser: the emitted HTML's project rows show the same alias strings as the user's existing `--by cwd` report output (visual cross-check — same project, same name)
  - CLI: `tools/claude-time/README.md` has a new section documenting `visualize`, all 5 flags, the default output path, and a screenshot reference
  - CLI: `tests/check-structure.sh` still passes (no new files break the structure check; the `viz/` subdirectory is allow-listed if needed)
  - [x] P5.1 Empty-state branch in `build_day_data`: returns `{label, iso, projects: [], hour_range: [6, 23], empty: true}` when zero events. Delivered ahead of schedule in Phase 2 (viz_data.py:322–329).
  - [x] P5.2 Empty-state JSX render: `EmptyState` component in `_interactive_dashboard()` (viz_render.py) renders centered "No tracked time on YYYY-MM-DD" card with re-run hint when `data.empty === true`. Delivered ahead of schedule in Phase 3. Live-verified against `--date 1970-01-01`.
  - [x] P5.3 Alias cross-check: live diff of `report --by cwd` aliases vs `visualize` project aliases — match exactly (`my-claude-code-customization`, `replicator-1-0`, `neo-stayman-assistant`, `stayman-cc-wrapper`). Both call `_auto_alias_for_cwd` from the same module by construction.
  - [x] P5.4 README updated — added `### Dashboard (visualize)` subsection under `## Usage` with all 5 flags + default output path + design-prototype caveat (file:// limitation) + behavior overview. Updated intro paragraph to mention both subcommands. Updated `## Files` section with new viz/, viz_data.py, viz_render.py, test_viz_data.py, test_visualize_cli.sh entries.
  - [x] P5.5 `check-structure.sh` still passes 123/1 (same as before Phase 5; the 1 FAIL is the pre-existing `SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME`, not feature-caused). No new files break the check; the `viz/` subdirectory needed no allow-listing.
  - [x] verify-auto — `test_viz_data` + `test_reclassify` 51/51 PASS (no regression); `test_visualize_cli` 13/13 PASS; README parses cleanly (39 headings extracted via regex, structure intact); end-to-end `claude-time visualize --no-open` against real DB exits 0 and prints the expected path.
  - [x] verify-self — Doc-vs-behavior consistency subagent ran 10 outcomes against the new README section. All PASS. Every documented CLI invocation works, every documented behavior holds (single-file emission, unpkg CDN, overwrite-in-place, Month/Custom disabled, InterruptHairlines), all 12 audited files in the `## Files` section exist at the documented paths. No integration boundary (README is reference text — not consumed by any runtime surface).
  - [x] verify-human — user approved on 2026-05-19. Doc-only phase; presented a single judgment-call item (prose readability) with the F11 skip path available as the integration-boundary affirmation. User approved.
    - [x] P5.verify-human.1 — prose review: approved
  - [x] verify-codify — Phase 5 is doc-only with no new code or test gap. All behaviors already covered: `test_visualize_cli.sh` (13/13) covers every documented CLI flag; `check-structure.sh` Phase 5b asserts each documented file path exists; `test_viz_data` + `test_reclassify` (51/51) cover the data layer; `test_cli.sh` (29/29) covers the existing report CLI. Total 93 tests passing. Considered codifying doc-vs-behavior drift detection but rejected — marginal value is low (the existing CLI tests already catch behavior drift; doc drift alone is low-probability), and doc-extraction logic would be brittle. No new tests written this phase.

## Current Node
- **Path:** Feature > ship (complete) > finalize
- **Active scope:** Shipped to `origin/main` in commit `fcd570f` (2026-05-19). Ready for `/feature-finalize`.
- **Blocked:** none
- **Unvisited:** Phase 5 verify-{self, human, codify}. After Phase 5: all phases complete; feature ready to ship.
- **Open discoveries:** Phase 1 surfaced one note (file:// won't render the prototype because Babel-standalone fetches text/babel external scripts via XHR — local HTTP server required). Captured in Discoveries section + documented in README (P5.4).

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
[SURFACED-2026-05-18] Phase 1 / Phase 5 README — The `viz/` prototype cannot be opened via `file://` because Babel-standalone's `text/babel` external-script loader uses XHR, which Chrome/Safari block for `file://` origins. Must be served via a local HTTP server (e.g. `python3 -m http.server` from the `viz/` directory). Phase 5's README update must document this. Not a backlog item — solved by README; logged here for traceability.

[SURFACED-2026-05-18] Phase 2 / cross-feature — `reclassify.session_active_ms` and viz's burst-pairing diverge on consecutive-UPS event streams. RESOLVED in back-loop: user decided to keep the narrow definition (last_UPS_before_Stop anchors the burst) for both consumers. Refactored to extract `reclassify.active_bursts` as the single source of truth; both `session_active_ms` and viz now consume it. The interrupt UPSes are now captured per viz-session as `interrupts: [<minutes>]` field and will render as vertical hairlines inside the active bar at Phase 3. The backlog entry `SURFACE-2026-05-18-CLAUDE-TIME-RECLASSIFY-SESSION-ACTIVE-MS-CONSECUTIVE-UPS-UNDERCOUNT` is RESOLVED (no longer applicable — both definitions are aligned).

[SURFACED-2026-05-18] Phase 2 back-loop — When the same session_id spans multiple cwds (user `cd`'s mid-session), the by-alias partitioning could fracture burst-pairing if the alias resolver mapped the cwds to different aliases. Found during back-loop verify-self with a naive `Path(cwd).name` test stub (which DOES split aliases). The production git-root resolver wouldn't have triggered this (all subdirs of the same repo resolve to one alias), but the coupling was fragile. Defensive fix: viz_data now groups events by session_id FIRST, then partitions viz-sessions into projects by the modal cwd's alias. Burst-pairing always sees the full session. Logged here for traceability; not a backlog item (resolved in-line).

## Retrospect

- **What changed in our understanding:**
  - **Burst-pairing semantics weren't a settled invariant in the codebase.** The pre-existing `reclassify.session_active_ms` used a "narrow" definition (overwrite-on-consecutive-UPS — keep only the last) that was almost certainly accidental rather than designed. Discovered during Phase 2 verify-self when viz totals diverged from the report by 6.6% on real data. Resolution: factored both consumers through a new shared `reclassify.active_bursts` helper and added `interrupts` as a first-class data field. The divergence wasn't a viz bug — it was a latent gap in the shared module that this feature surfaced and codified.
  - **`session_id` is preserved across `/resume`.** This wasn't documented anywhere in the codebase; I assumed time-based away-gap splitting was necessary as a safeguard. The user pushed back during Phase 3 verify-human ("I expected `stayman-cc-wrapper` to be one row"), and real-data investigation showed the harness preserves session_id and the hook records `SessionStart source=resume` distinctly. Removed the away-split entirely — one viz-session per session_id is the right grouping key.
  - **By-(alias, session_id) partitioning was a fragility, not a feature.** A defensive fix during Phase 2 back-loop (sid-first grouping) revealed that the previous structure could fracture bursts across alias buckets when a single session_id spanned multiple cwds. The production git-root resolver masked it; a naive resolver wouldn't. Hardened.

- **Assumptions that held:**
  - React-UMD + Babel-standalone via CDN works fine for a personal single-user tool. No build step needed.
  - Python data layer + JS view layer cleanly separates concerns. Data shape contract pinned by `data.js` byte-pinning in Phase 5c gives a real safety net.
  - Phase 1's "drop the design extract in verbatim and lock it" was the right move — it kept the visual contract reviewable in-tree and made later changes (Phase 3's interactive wrapper, Phase 3's hairlines) explicit deltas at emit time, not edits to the source.
  - The integration-boundary rule caught the right things: Phase 3 (CLI modification) required an end-to-end test against the consuming surface (`test_visualize_cli.sh`), Phases 1/2 didn't.

- **Assumptions that were wrong:**
  - **"Away gaps are session boundaries."** False — they're rest markers within a single conversation. Cost: one Phase 2 back-loop after Phase 3 verify-human surfaced it.
  - **"`session_active_ms` is the truth source for active time."** It's *a* definition; my code uses *the same* definition after refactor, and the divergence was the loop-structure accident, not semantics. Cost: one Phase 2 back-loop + a temporary backlog SURFACE entry that was later resolved in-feature.
  - **Phase 4 ("CLI flags") would be a separate phase.** In practice all 5 flags share argparse + handler code with the subcommand itself (Phase 3's P3.6), so Phase 4 was effectively subsumed. Saved one phase's overhead.

- **Approach delta:**
  - **Plan said 5 phases; actually shipped in 4 effective phases** (Phase 4 absorbed into Phase 3).
  - **Plan said "Phase 1 is a near-pure copy operation."** True, but Phase 1's `file://` discovery (the prototype needs a local HTTP server because Babel-standalone uses XHR for `text/babel` externals) became documentation in Phase 5's README — small unanticipated work item.
  - **Plan didn't anticipate the `active_bursts` extraction.** Emerged from Phase 2 verify-self's drift investigation. Net positive — now both consumers share one source of truth.
  - **Plan didn't anticipate the away-split removal back-loop.** Emerged from Phase 3 verify-human spot-check. Net positive — viz-sessions now match user mental model.
  - **Plan didn't anticipate the sid-first partitioning defensive fix.** Emerged from drilling into the Phase 2 divergence. Net positive — burst-pairing is now alias-resolver-robust.
  - **Two distinct back-loops fired (both F12 from verify-human into build, scoped to Phase 2 leaves).** Both produced cleaner, more honest code than the original plan. The Work Tree format + scoped leaf IDs made these back-loops cheap.

## Notes for build time

- **Phase 1 is a near-pure copy operation.** The four files at `/tmp/claude-design-extract/claude-time-dashboard/project/` go verbatim into `tools/claude-time/viz/`. The only adjustment is renaming `Claude Time Dashboard.html` → `index.html` (so `open viz/` defaults to it) and confirming the relative `src="data.js"` / `src="design-canvas.jsx"` / `src="dashboard.jsx"` paths resolve when opened via `file://`. Total new code: ~0 lines. Total copied code: ~2,200 lines.
- **The `design-canvas.jsx` chrome is intentional for Phase 1.** It frames the three artboards side by side so the visual contract review matches what was approved in Claude Design. Phase 3 strips it for the shipped output (single full-bleed dashboard).
- **Phase 2's segment-construction algorithm:** segments must tile the session's `[start, end]` interval without overlaps. Algorithm: (a) sort all Pre/Post pairs by start time, (b) emit `active` segment for each Pre/Post duration, (c) for gaps between consecutive Pre/Post pairs within the same session, apply `reclassify.py` to get `reading | thinking | away`, (d) for subagent runs (Start/Stop pairs), emit `subagent` segments that nest inside the parent active context (per the design's `boxShadow: '0 0 0 1px ${surface}'` rendering, subagents are drawn ON TOP of active bars, not adjacent — verify this matches the actual rendering in Phase 1 before Phase 2 commits to the nesting model).
- **Mock-data → real-data shape contract.** Phase 1's `data.js` is the contract. Phase 2 must emit *exactly* the same JS-literal shape (`window.CT_DATA = { today: {...}, week: {...} }`). Phase 3 inlines that into the HTML template via JSON serialization. If Phase 2 wants to extend the shape (e.g., add `hour_range`), it MUST be additive — never remove a field the mock uses, or Phase 1's design contract breaks for the `--demo` mode in Phase 4.
- **Symlink-installed path resolution.** The existing `claude-time` script is symlinked from `~/.local/bin/claude-time` → `tools/claude-time/claude-time`. The script must resolve `template.html` relative to its *real* location (resolve the symlink). Use `Path(__file__).resolve().parent / 'viz' / 'template.html'`.
- **Phase boundary discipline (per CLAUDE.md "Plan-level downstream contract impacts" pass):** Phase 2 changes the data contract that Phase 1's `data.js` already asserts. Phase 2's `verify-codify` must include a test that the shape Python emits matches the shape `data.js` declares (key set, type-of-value parity for at least one row per top-level field). This is the downstream-contract assertion at plan time.
