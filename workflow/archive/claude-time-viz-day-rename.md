---
feature: claude-time-viz-day-rename
workflow: feature
state: ship (complete)
created: 2026-05-23
drive_mode: autopilot
wbs_ref: WP6 (claude-time-visualize-v2 cycle)
size: XS
---

# Feature: `claude-time visualize` — "Today" → "Day" rename (WP6)

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-23
**WBS:** WP6, size XS, no dependencies

## Problem Statement

The `claude-time visualize` toolbar still shows a "Today" tab even though WP5b extended the Day view's data window to render trailing+leading days (default 14+7). The label is now actively misleading — users see "Today" but the timeline shows three weeks of context. WP6 renames the user-visible label from "Today" to "Day" to match the new semantics, and decides what to do with the data-layer key `window.CT_DATA.today` that five WP5b consumers depend on.

**Rename-scope decision (made at plan time):** Keep `window.CT_DATA.today` as the data-layer key; rename only UI-visible surfaces (toolbar tab text, `activeRange` token value, README usage prose). Rationale: WP5b just stabilized six call sites (`_initialViewport`, `SessionRow`, `DayTimeline.dwCtx`, `Minimap.allSegs`, `viz_render.py` wrapper, `claude-time:586` payload assembly) on the `.today.*` shape. Renaming the key would touch all six with no functional benefit — the user-facing rename motivation is satisfied entirely by the label. The contract-key/label mismatch is a documented trade-off; WP3's `meta.start/end` escape hatch keeps future renames cheap. WBS task 6.2's "decide" prompt resolves to: **keep `.today`, rename label**.

**Problem statement unchanged (F9 back-loop, 2026-05-23):** F9 corrected which file holds the shipped toolbar (`viz_render.py::InteractiveToolbar`, not `viz/dashboard.jsx::Toolbar`); user-facing rename motivation is untouched. Plan-defect was an impl-mapping miss, not a goal change.

## Work Tree

- [x] Phase 1: Rename user-visible "Today" → "Day"  <!-- All impl + verify nodes complete; 62/62 CLI tests pass -->
  **Observable outcomes:**
  - Browser: Playwright snapshot of emitted HTML's toolbar tab list contains text "Day" and does NOT contain text "Today" in the same `segGroup` row.
  - CLI: `./tools/claude-time/claude-time visualize --no-open --out /tmp/wp6.html` exits 0 and the produced HTML satisfies: `grep -c '>Day<' /tmp/wp6.html >= 1` and the first `segGroup` tuple list contains `['Day','day']` rather than `['Today','today']`.
  - CLI: `./tools/claude-time/claude-time visualize --no-open --out /tmp/wp6.html` exits 0 and `grep -q "activeRange={isDay ? 'day' : 'week'}" /tmp/wp6.html` succeeds (proves the Dashboard wrapper passes `'day'` not `'today'`).
  - CLI: Existing test suite still passes — `./tools/claude-time/test/test_visualize_cli.sh` exits 0 (no regression on the WP5b `target_iso` assertion at line 158–167 which keys off the data-layer `today` shape — that shape is unchanged).
  - HTTP: N/A (no server surface).
  - Console: Loading the emitted HTML in a browser produces no new JS errors compared to baseline (`_initialViewport`, `SessionRow`, `dwCtx`, `Minimap`, NOW-marker logic all continue to read `window.CT_DATA.today.*` unchanged).
  - [x] P1.1 Update `viz/dashboard.jsx::Toolbar` default param (line 107): `activeRange = 'today'` → `activeRange = 'day'` <!-- NOTE: edit is in design-canvas static prototype; viz_render.py strips this section at emit-time. Confirmed-dead from shipped-UI perspective but kept for consistency with the design-canvas reference artifact. -->
  - [x] P1.2 Update `viz/dashboard.jsx::Toolbar` segGroup tuple (line 165): `['Today','today']` → `['Day','day']` <!-- Same note as P1.1 — design-canvas-only -->
  - [x] P1.3 Update `viz/dashboard.jsx::Dashboard` Toolbar prop (line 1635): `activeRange={isDay ? 'today' : 'week'}` → `activeRange={isDay ? 'day' : 'week'}` <!-- Same note — design-canvas-only; InteractiveToolbar uses `view === 'day'` activation, not an `activeRange` prop -->
  - [x] P1.4 Update `README.md` line 157: "The `Today` and `Week` toolbar tabs are interactive" → "The `Day` and `Week` toolbar tabs are interactive". Lines 81 and 134 (CLI-side `report`/default `visualize` prose) intentionally left untouched.
  - [x] P1.5 Trade-off comment placed at line 165 above the segGroup (design-canvas-only — needs migration to `InteractiveToolbar` via P1.6).
  - [x] P1.6 Edit `viz_render.py::InteractiveToolbar`: `tabBtn('Today', 'day', ...)` → `tabBtn('Day', 'day', ...)` + section comment `Today/Week` → `Day/Week`. Confirmed in fresh emit (re-verify gate (a)–(c) PASS).
  - [x] P1.7 Trade-off comment placed in `viz_render.py` above the `View tabs` section in InteractiveToolbar. Confirmed in emit (re-verify gate (d) PASS).
  - [x] verify-auto — Re-verify gate 6/6 PASS (run in build): shipped toolbar emits `Day` (a), no `Today` button (b), section comment updated (c), trade-off comment present (d), data-layer `.today` preserved (e), `window.CT_DATA.today` consumer preserved (f). Plus `test_visualize_cli.sh` 59/59 PASS (run in verify-auto): zero regression on WP5b data-layer assertions. **Outcome-3 retired:** the plan's CLI outcome 3 (`activeRange={isDay ? 'day' : 'week'}` in emitted HTML) is unreachable by design — `viz_render.py::InteractiveToolbar` uses `view === 'day'` activation, not an `activeRange` prop. The outcome was a plan-time confabulation from reading the design-canvas `Dashboard`'s wrapper, not the shipped wrapper. Retired here rather than letting it noise verify-self.

  **Verify-auto failure (2026-05-23):** The shipped toolbar's `Today` label was missed because the 5 original leaves edited only `viz/dashboard.jsx::Toolbar` (the design-canvas static prototype). The actual user-facing toolbar is `InteractiveToolbar` in `viz_render.py`, appended at emit-time per the byte-pin + emit-time-transform pattern. WBS task 6.1 explicitly named "the emit-time-appended interactive Dashboard wrapper, not the byte-pinned source" — plan read the instruction but mis-mapped which file. F9 back-loop to build adds P1.6 + P1.7 to remediate. Outcomes unchanged; previous PASSes on data-layer `.today` shape (59/59 test_visualize_cli.sh, grep assertions 1+3–6) remain valid.
  - [x] verify-self — Playwright subagent verified emitted dashboard at `file:///Users/stayman/Personal/projects/my-claude-code-customization/tmp/wp6-verify-self.html`:
    - **Outcome 1 (toolbar "Day", no "Today" button):** PASS. Toolbar contains buttons `Day | Week | Month(disabled) | Custom(disabled)`, no "Today" button. (Context-note: "Today" string appears in a non-toolbar filter chip below the toolbar — `date Today` pill, WP9 territory, not WP6's surface.)
    - **Outcome 2 (no JS console errors):** PASS. Only a `favicon.ico` 404 (network, not JS) — pre-existing `file://` infrastructure noise, not WP6-introduced.
    - **Outcome 3 (data-layer `.today` shape):** PASS at the load-bearing level. `window.CT_DATA.today` exists with `{label: "WED · MAY 13", iso, hour_range, projects}` — the WP6 rename was UI-only, `.today` is preserved. The subagent reported a COSMETIC FAIL on a sub-assertion (`hasMeta` inside `.today`) but that was a verify-self spec error on my part: `meta` actually lives at `window.CT_DATA.meta` (root-level, per `claude-time:586`), never inside `.today`. The sub-assertion was a spec confabulation, not a code defect. COSMETIC FAIL retired here for the same reason as outcome 3 of the plan (unreachable-by-design).
  - [x] verify-human — Human-approved all 4 leaves (2026-05-23):
    - [x] P1.verify-human.1 — Toolbar first tab reads "Day" in user's real browser.
    - [x] P1.verify-human.2 — Day↔Week tab switching feels correct; no flash of "Today".
    - [x] P1.verify-human.3 — README line 157 reads "The `Day` and `Week` toolbar tabs are interactive"; lines 81/134 (CLI prose) intentionally unchanged.
    - [x] P1.verify-human.4 — Context-note acknowledged: "Today" string in filter-chip below toolbar is WP9 territory, deferred (not a WP6 regression).
  - [x] verify-codify — Added 3 assertions to `test_visualize_cli.sh` (59 → 62 PASS; zero regression; triage gate not triggered):
    - **WP6 codify: InteractiveToolbar emits Day tab (shipped consuming surface)** — positive end-to-end pin via `grep "tabBtn('Day', 'day', view === 'day', true)"` on emitted HTML.
    - **WP6 codify: no legacy Today tabBtn in shipped toolbar (regression-pin)** — negative pin that catches the exact F9-back-loop regression class (editing the design-canvas Toolbar without propagating to InteractiveToolbar).
    - **WP6 codify: data-layer .today key preserved (rename-scope decision pin)** — pins the WP6 decision that the rename was UI-only; partially redundant with WP5b assertions but acts as a forcing function for future renames.
    - **Integration boundary satisfied:** the positive assertion exercises the consuming surface (the shipped toolbar in emitted HTML), not just an internal artifact.
    - **No triage artifact written** — no failing tests.

## Current Node
- **Path:** Feature > ship (complete)
- **Active scope:** finalize
- **Blocked:** none
- **Unvisited:** finalize
- **Open discoveries:** none

## Retrospect

- **What changed in our understanding:** WBS task 6.1 explicitly named "the emit-time-appended interactive Dashboard wrapper, not the byte-pinned source", but the original plan (and the agent's implementation) mis-mapped this to `viz/dashboard.jsx::Toolbar` rather than `viz_render.py::InteractiveToolbar`. The two co-exist by design — `dashboard.jsx::Toolbar` is the design-canvas static prototype (historically byte-pinned reference), `viz_render.py::InteractiveToolbar` is the actual shipped toolbar appended at emit time. Caught at verify-auto via grep miss on `activeRange={isDay ? 'day' : 'week'}` (a plan outcome that, as it turned out, was actually unreachable-by-design since `InteractiveToolbar` uses `view === 'day'` activation rather than an `activeRange` prop). F9 back-loop added P1.6 + P1.7 to edit the real shipped toolbar, took one tool round.
- **Assumptions that held:** (a) the rename-scope decision at plan time — keep `window.CT_DATA.today` data-layer key, rename only UI surfaces — was correct and held through all verify gates; (b) WP6 was genuinely XS (single-phase, one logical edit + 3 codify pins); (c) the existing 59-assertion `test_visualize_cli.sh` pattern (grep-against-emit-output) extended naturally to 62 assertions; (d) verify-human had nothing BLOCKING to find since verify-self covered the load-bearing assertions.
- **Assumptions that were wrong:** (a) the assumption that editing `viz/dashboard.jsx::Toolbar` would propagate to the shipped UI — see above; (b) the verify-self spec's `hasMeta` sub-assertion inside `.today` — `meta` lives at `window.CT_DATA.meta` (root-level), not inside `.today`. That was a verify-self prompt confabulation by the agent. COSMETIC FAIL retired transparently rather than back-looped.
- **Approach delta:** Plan had 5 leaves (P1.1–P1.5). Actual implementation needed 7 (P1.6 + P1.7 added at F9 back-loop). The 4 design-canvas edits in `dashboard.jsx` were retained for design-canvas reference consistency rather than reverted — net cost was small (~5 lines) and they document the rename intent in the prototype too. Net result: WP6 size estimate XS held, but only because the back-loop was a single small edit rather than a re-plan.

## Communicate

> **Feature complete:** "Today" → "Day" toolbar tab rename (WP6 of the claude-time-visualize-v2 cycle) has shipped (commit `217cfe3` on `main`). The shipped dashboard's first toolbar tab now reads "Day" to match the multi-day data window WP5b introduced; the data-layer key `window.CT_DATA.today` is preserved unchanged for back-compat. Verify by running `tools/claude-time/claude-time visualize --no-open --demo --out /tmp/wp6.html && open /tmp/wp6.html` and confirming the first toolbar tab reads "Day".

Requester = operator — closure notice for self-record.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
