---
workflow: feature
state: verify-codify (complete)
created: 2026-05-19
drive_mode: autopilot
wbs_wp: WP1
---

# Feature: claude-time visualize — adaptive hour-ruler

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-19
**Entry:** F2 (small/simple feature) — single phase, ~30–50 LOC
**Drive mode:** autopilot
**WBS:** WP1 of `claude-time-visualize-v2` cycle (docs/product/wbs.md)

## Problem Statement

`viz_data.build_day_data` emits `today.hour_range: [start, end]` (adaptive to the day's actual event window — `[min_event_hour - 1, max_event_hour + 1]` clamped to `[0, 24]`, default `[6, 23]` on empty days). The Python side already computes this correctly; three unit tests in `test_viz_data.py:HourRangeTests` pin it. But `dashboard.jsx` ignores the field — `const DAY_HOURS = [6..22]` is a module-level constant and `DAY_START_MIN` / `DAY_END_MIN` / `DAY_RANGE_MIN` derive from it. Result: every dashboard renders a 06:00–22:59 ruler regardless of the actual day. A day with events 14:00–21:00 wastes 8 hours of horizontal grid on empty morning; a late-night session past 23:00 clips at the right edge.

Per the WBS approval decision (2026-05-19): direct source edits to `viz/dashboard.jsx` are now permitted (the Claude Design extract is reference-only from this cycle forward). The existing byte-pin in `tests/check-structure.sh` Phase 5c is **superseded** and will be relaxed in this WP. The `CLAUDE.md` "design-as-data byte-pin" convention will be updated to reflect the v2 shift.

## Work Tree

- [x] Phase 1: Adaptive hour-ruler + relax byte-pin + update convention  <!-- status: [x] complete -->
  **Observable outcomes:**
  - CLI: `claude-time visualize --no-open --demo --out /tmp/wp1-demo.html` exits 0; the emitted HTML's `DAY_HOURS` / `DAY_START_MIN` / `DAY_END_MIN` / `DAY_RANGE_MIN` are computed from `data.today.hour_range` rather than the literal `[6..22]` (grep emitted HTML: no module-level `const DAY_HOURS = [6, 7, 8, ...22]` array literal; instead a derivation from `today.hour_range`)
  - CLI: against a seeded SQLite DB whose events are confined to 14:00–15:00 on 2026-05-01, `claude-time visualize --no-open --date 2026-05-01 --out <out>` exits 0 and the emitted HTML's `today.hour_range` = `[13, 16]` (adaptive: min-1=13, max+1=16). Codified in `test_visualize_cli.sh` assertion #14.
  - CLI: `claude-time visualize --no-open --demo` (mock-data path) falls back to the `[6, 23]` ruler — no regression from Phase 1's design-fidelity contract on the demo-mode visual. Verified: emitted HTML contains `"hour_range": [6, 23]`.
  - CLI: `tests/check-structure.sh` PASS count: 123 → 121 (delta = -2, exactly the two byte-pin assertions removed for `dashboard.jsx` and `data.js`); the 1 pre-existing FAIL (settings-fixture-drift) is unchanged.
  - CLI: `cd tools/claude-time && python3 -m unittest discover -s test -p 'test_*.py'` — 51/51 PASS (no regression in the data layer).
  - CLI: `cd tools/claude-time && bash test/test_visualize_cli.sh` — 14/14 PASS (was 13; one new assertion added).
  - [x] P1.1 Edited `viz/dashboard.jsx` lines 279–285: replaced module-level `const DAY_HOURS = [6, 7, 8, ..., 22]` literal with `const _CT_HR = (window.CT_DATA?.today?.hour_range) ?? [6, 23]` + `DAY_HOURS = Array.from(...)` derivation. `DAY_START_MIN` / `DAY_END_MIN` / `DAY_RANGE_MIN` derive from `_CT_HR`. All downstream components (`HourRuler`, `HourGridBackground`, `pct`, `SegmentBar`, `InterruptHairlines`) read from these derived values unchanged. Defensive fallback to `[6, 23]` when CT_DATA is absent (keeps design-canvas prototype loadable standalone).  <!-- status: [x] complete -->
  - [x] P1.2 Added `hour_range: [6, 23]` to `viz/data.js` `today` object. Confirmed --demo emit produces `"hour_range": [6, 23]` and the ruler renders identically to v1's mockup.  <!-- status: [x] complete -->
  - [x] P1.3 Relaxed `tests/check-structure.sh` Phase 5c byte-pin: removed `dashboard.jsx:42262` and `data.js:9160` from `VIZ_FILES`; added existence-only loop for the two editable files. `node --check data.js` + JSX parses retained as the v2 integrity check. Phase 5c header comment updated to document the v1→v2 transition.  <!-- status: [x] complete -->
  - [x] P1.4 Updated three convention surfaces: (a) `CLAUDE.md` "Design-as-data" bullet rewritten to historical-origin + current-state form with the unlock lesson explicit, (b) `tools/claude-time/viz_render.py` module docstring updated to drop the "immutable" framing and reference the CLAUDE.md history, (c) `tools/claude-time/README.md` `## Files` section: `dashboard.jsx` description now says "editable; integrity via JSX-parse + behavioral tests".  <!-- status: [x] complete -->
  - [x] P1.5 Added assertion #14 to `test_visualize_cli.sh`: seeds a narrow-window DB (events 14:00–15:00 on 2026-05-01) in an isolated CLAUDE_TIME_DIR, runs `visualize --date 2026-05-01`, asserts emitted HTML contains `"hour_range": [13, 16]`. PASSes locally. test count: 13 → 14.  <!-- status: [x] complete -->
  - [x] verify-auto — scoped checks PASS. `node --check viz/data.js` OK; `py_compile viz_render.py` OK; `bash -n` on both edited shell scripts OK; `test_visualize_cli.sh` 14/14 PASS (incl. new adaptive-ruler assertion #14). JSX parse for dashboard.jsx already verified by check-structure.sh Phase 5c in build. No regressions; no failures.  <!-- status: [x] complete -->
  - [x] verify-self — all 4 observable outcomes PASS. Browser observation via Playwright against three emitted dashboards served from a local HTTP server (port 8770). Real-data (`hour_range = [5, 12]` → ruler 05:00–11:00, 7 ticks), narrow-window seed at 14:00–15:00 (`hour_range = [13, 16]` → ruler 13:00–15:00, 3 ticks), and demo fallback (`hour_range = [6, 23]` → 17 ticks 06:00–22:00 identical to v1 mockup). 0 substantive console errors across all three (1 benign favicon 404 + 1 benign Babel-standalone in-browser warning, expected since Phase 1 of v1). Screenshots saved at `.playwright-mcp/wp1-verify-self-{demo,narrow}.png`. Integration boundary (CLI → emitted HTML → browser render) verified end-to-end. Severity: N/A.  <!-- status: [x] complete -->
  - [x] verify-human — user approved 2026-05-19 ("Looking good. Proceed"). Pre-filter: all 4 verify-self leaves EXCLUDED (agent confirmed). Presented 2 judgment-call items: P1.verify-human.1 (live CLI invocation against today's data — integration boundary affirmation) and P1.verify-human.2 (visual subjective comparison vs v1's fixed window). Both approved.  <!-- status: [x] complete -->
    - [x] P1.verify-human.1 — live `claude-time visualize` against today's data, ruler reflects today's event window: approved
    - [x] P1.verify-human.2 — visual judgment vs v1's fixed window: approved
  - [x] verify-codify — coverage assessment: all 4 verified behaviors already have regression-catching tests; no new tests needed. Integration-boundary requirement satisfied via `test_visualize_cli.sh` assertion #14 (consuming surface, end-to-end, narrow-window seed → emitted `hour_range [13, 16]`). Full test sweep: `test_viz_data` 22/22 + `test_reclassify` 29/29 + `test_visualize_cli.sh` 14/14 + `test_cli.sh` 29/29 + `test_hook.sh` 17/17 + `privacy_check.sh` PASS. `tests/check-structure.sh` 121/1 (1 pre-existing FAIL: SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME — unchanged from baseline). No triage artifact required (no test failures).  <!-- status: [x] complete -->

## Current Node
- **Path:** Feature > ship
- **Active scope:** all phases complete (Phase 1 [x]); ready for /feature-ship
- **Blocked:** none
- **Unvisited:** ship → finalize
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
(none yet)

## Notes for build time

- **Integration boundary:** This phase modifies code inside an existing consuming surface (`claude-time visualize` CLI emits the dashboard HTML; users render the HTML in a browser). Per the per-phase verify loop "Integration-boundary rule" in CLAUDE.md: verify-self MUST include outcomes citing the consuming surface (the emitted HTML + browser render via Playwright), verify-human CANNOT use the F11 skip path, and verify-codify MUST include a test on the consuming surface (already planned in P1.5 — assertion on the emitted HTML).

- **Edit, don't transform.** P1.1 is the first source-edit of `viz/dashboard.jsx` since the design-pin was introduced. Edit the source directly rather than adding emit-time text-replace transforms in `viz_render.py`. Rationale (per the WBS v2 decision): emit-time transforms are brittle and the byte-pin (which made them safe) is being relaxed in this same WP. Direct edits are now the cleaner pattern; adding more transforms would compound future maintenance cost.

- **Derivation pattern (P1.1):** the cleanest approach is to keep `DAY_HOURS` etc. as module-level constants but compute them once at module-init from `window.CT_DATA.today.hour_range`. Concretely:
  ```javascript
  const _HR = (window.CT_DATA && window.CT_DATA.today && window.CT_DATA.today.hour_range) || [6, 23];
  const DAY_HOURS = Array.from({length: _HR[1] - _HR[0]}, (_, i) => _HR[0] + i);
  const DAY_START_MIN = _HR[0] * 60;
  const DAY_END_MIN   = _HR[1] * 60;
  const DAY_RANGE_MIN = DAY_END_MIN - DAY_START_MIN;
  ```
  Note `hour_range[1]` is **exclusive** (per `viz_data.py:14`'s "`[start, end]`" doc and the `[6, 23]` default which gives 17 hour ticks). The original `DAY_HOURS = [6..22]` produced 17 entries (6 through 22 inclusive) and `DAY_END_MIN = (DAY_HOURS[last]+1)*60 = 23*60 = 1380`. The new derivation must produce the same 17-hour default-ruler output when `hour_range = [6, 23]` — confirm with grep on the demo HTML.

- **Why module-level vs runtime:** A future WP (WP5, zoomable timeline) will likely need to recompute these per render. For WP1, keep them module-level — it's the minimum change to get adaptive behavior. WP5 will reshape this into props or context if/when needed.

- **`data.js` and `hour_range`:** check whether `data.js` already exports `today.hour_range`. If not, add `[6, 23]` (matching the original design-mockup ruler). The `--demo` path must continue producing the design-mockup visual.

- **Existing tests to keep passing:**
  - `test_viz_data.py` (22) — unaffected; data layer doesn't change
  - `test_reclassify.py` (29) — unaffected; reclassifier doesn't change
  - `test_visualize_cli.sh` (13) — must continue passing; one new assertion added in P1.5 → 14
  - `tests/check-structure.sh` — Phase 5c assertion count changes (drops 2 byte-pin checks for `dashboard.jsx` and `data.js`); net delta = -2 PASS, but the 1 pre-existing FAIL (`SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME`) is unchanged

- **CLAUDE.md update — preserve history.** The byte-pin convention was added in commit `6e00ea2` (2026-05-19) — *yesterday*. Don't just delete it; document the v2 reversal explicitly. Future readers should understand both *why* it was introduced (brittle text-replace transforms over an immutable source) and *why* it's being relaxed (the design extract was always a starting point; v2 requires substantial source-level evolution that emit-time transforms can't reasonably support).
