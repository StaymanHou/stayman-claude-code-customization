---
workflow: feature
state: ship (complete)
created: 2026-06-06
drive_mode: autopilot
wbs_wp: WP10
resolves: SURFACE-2026-05-26-CLAUDE-TIME-VIZ-DAY-VIEW-ROW-DENSITY
ship_commit: c719e1b
---

# Feature: WP10 — Day-view row-density mitigation

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-06
**Entry:** spec (complex feature — non-mechanical strategy decision; spec→plan F4)

## Problem Statement

After ~1 week of tracking with `claude-time visualize`, the Day view accumulates too many project rows to comfortably read on a single screen. The row-per-project default works for the first few days but at steady-state multi-week activity history it becomes a visual scan-bottleneck — most rows are inactive long-tail projects the user hasn't touched in days, drowning out the projects with current activity.

Strategy decision (locked at spec): **(a) viewport-aware auto-hide of zero-activity rows** + **(c) recency-descending sort of surviving rows** + **escape hatch** ("N projects hidden — show all", session-local toggle) + **Day-only scope** (no behavior change in Week / Month / Compare / Custom views).

## Spec Q1–Q4 Resolutions (from plan-time code inspection)

- **Q1 — Segment data:** Per-project segments are nested at `data.projects[i].sessions[j].segs[k]`, each `{kind, start, end}` with `start`/`end` as minute-of-day (or absolute minute in multi-day mode, where `session.day_iso + dayOffsetMin(day_iso, windowStartIso)` shifts segments into the window's absolute minute space). The same flatten pattern is already used by `DayTimeline` at dashboard.jsx:2470 (`p.sessions.flatMap(s => s.segs)`) and by the minimap at dashboard.jsx:3066-3072 (multi-day day_iso offset). **WP10 reuses this exact pattern** — flatten per-project segs, apply day_iso offset if multi-day, intersect with viewport `[visible_start_min, visible_end_min]`.
- **Q2 — Recency definition:** Use **segment END** of the latest viewport-overlapping segment, per spec default. End-time captures "most-recently-active-as-of-now" intuition. Clamped to viewport — if a segment ends after viewport's end, treat its viewport-effective end as `min(seg.end, viewport.visible_end_min)`.
- **Q3 — Empty viewport:** If the viewport contains zero project activity (e.g., 3am window), the project rows area renders the escape-hatch chip (`N projects hidden — show all`) **only**. No additional inline empty state. The escape hatch chip already implies "click to see what's hidden", which subsumes "no activity here".
- **Q4 — Sort tiebreaker:** Ties on segment-end-minute resolved by project `alias` alphabetical ascending (stable). Deterministic across renders.

## Day-only enforcement (plan-time scope decision)

`DayTimeline` is invoked by `_interactive_dashboard()` in `viz_render.py:986` for both `isDay` AND `isCustom` (Custom view shares `DayTimeline` for its timeline body, per `isDayLike = isDay || isCustom` at dashboard.jsx:669). **WP10's auto-hide + recency-sort must fire only for Day view, not Custom.**

**Mechanism:** Add a `view` prop (or `enableRowDensityMitigation: boolean`) to `DayTimeline`. The `_interactive_dashboard()` callsite passes `view="day"` when `isDay && !isCustom`, otherwise `view="custom"` (or omits the prop, defaulting to off). Internally, `DayTimeline` gates the auto-hide + recency-sort transform on `view === "day"`. When `view !== "day"`, projects render in CLI emit order with no auto-hide (current behavior preserved exactly).

The static design-canvas Dashboard wrapper (`dashboard.jsx:3416-3424`) is stripped at emit by `_strip_design_wrapper` — but it still needs an updated prop in source to satisfy the byte-pin assertions; the canvas call site already implies Day view by `variant === 'day'`, so adding `view="day"` there is safe and stays stripped at emit.

## Work Tree

- [x] Phase 1: Viewport-aware auto-hide + recency-sort + escape-hatch (Day view only)  <!-- status: complete -->
  **Observable outcomes:**
  - Browser (Playwright): On Day view at a viewport containing activity, `[data-row-density-mitigation="on"]` is present on the project-rows container and one or more `[data-project-row]` elements are absent versus the full project count, with a chip `[data-row-density-chip]` containing text matching `/\d+ projects? hidden — show all/`.
  - Browser (Playwright): On Day view at a viewport containing activity, the rendered project-row order has `[data-project-row]` `data-project-alias` values matching the recency-descending order: clicking pan/zoom controls then re-snapshotting shows the order changes when the viewport changes (recency re-resolves).
  - Browser (Playwright): Clicking `[data-row-density-chip] [data-show-all]` causes all previously-hidden `[data-project-row]` to appear and the chip text to update to `0 projects hidden` (or the chip disappears).
  - Browser (Playwright): On Week view (`view=week`), Month view (`view=month`), Compare view (`view=compare`), and Custom view (`view=custom`), the project-rows area renders all projects in CLI emit order — no `[data-row-density-mitigation="on"]` marker, no `[data-row-density-chip]` chip.
  - Browser (Playwright): With WP9 per-project filter chip OFF for project X, project X stays hidden regardless of escape-hatch state (filter precedence preserved).
  - Console: no React warnings (no duplicate-key, no missing-key) introduced by the filter/sort transform.
  - CLI: `test/test_visualize_cli.sh` continues to pass (no CLI emit change in WP10).
  - [x] P1.1 Add `view: string` prop to `DayTimeline` (default `"day"` for back-compat at design-canvas callsite); update `_interactive_dashboard()` callsite at viz_render.py:986 to pass `view="custom"` when `isCustom` else `view="day"`. The static design-canvas `<DayTimeline data={today} ... />` at dashboard.jsx:3416 gains `view="day"` for symmetry (stripped at emit anyway). **Done.** Also updated `_wire_bar_click` transform in viz_render.py:1122 to match the new source signature (literal-string match — would have broken emit silently otherwise; caught by test_visualize_cli.sh first-emit assertion).
  - [x] P1.2 Inside `DayTimeline`, add a `useState(true)` for `autoHideOn` (session-local; no URL hash, no localStorage per spec). **Done.**
  - [x] P1.3 Compute `mitigatedProjects` from `visibleProjects`. **Done** via `React.useMemo` keyed on `[view, autoHideOn, visibleProjects, viewport, dwCtx]`.
  - [x] P1.4 Implement helper `_applyRowDensityMitigation(projects, viewport, dwCtx)` near `dayOffsetMin`. **Done.** Flatten sessions×segs, apply per-session day_iso offset, viewport-intersect, max(effectiveEnd), sort by latestEnd desc + alias asc tiebreak.
  - [x] P1.5 Escape-hatch chip rendered with `data-row-density-chip`, "show all" / "re-enable auto-hide" toggle buttons. **Done.** Always-render path when `view==='day'` AND (`droppedCount>0` OR `!autoHideOn`).
  - [x] P1.6 `data-row-density-mitigation` and `data-row-density-dropped` attrs on project-rows container; `data-project-row` + `data-project-alias` on each row. **Done.** (React.Fragment → div wrapper to carry the data-attrs.)
  - [x] P1.7 `mitigatedProjects.map(...)` loop wired in place of `visibleProjects.map(...)`. `totalsByProject` correctly still uses `data.projects` (verified — line dashboard.jsx:2467 iterates `data.projects` unchanged).
  - [x] verify-auto  <!-- status: complete: py_compile + source-marker grep + test_visualize_cli.sh 205/0 -->
  - [x] verify-self  <!-- status: complete: direct Playwright observation against --demo render. ✓ data-row-density-mitigation="on" + data-project-row markers present on Day. ✓ Recency-sort applied (weekend-tinkering first in wide viewport; claude-time first in narrow 10:00-12:00 viewport). ✓ Narrow viewport: chip="2 projects hidden—show all", dropped=2, visibleRows=[claude-time, agent-handoff-protocol]. ✓ [data-show-all] click: mitigation→off, dropped→0, chip→"Showing all projects—re-enable auto-hide", 4 rows visible. ✓ Week-view tab switch: no mitigation marker, no chip, no data-project-row (Day-only scope). ✓ Day-tab return: marker restored. Container interactive 89/0 (was 89/0). No regressions. -->
  - [x] verify-human  <!-- status: complete: all 7 leaves PASS per user 2026-06-06 -->
    - [x] P1.verify-human.1 Row count feels right + top-of-list is most-recently-active  <!-- status: complete -->
    - [x] P1.verify-human.2 Pan/zoom: row set + order re-resolve, no flicker, no console errors  <!-- status: complete -->
    - [x] P1.verify-human.3 "show all" click: all hidden rows return in CLI order, chip text updates  <!-- status: complete -->
    - [x] P1.verify-human.4 "re-enable auto-hide" click: rows re-hide, chip resets, sort restored  <!-- status: complete -->
    - [x] P1.verify-human.5 WP9 per-project filter precedence: filter-OFF stays hidden across both auto-hide states  <!-- status: complete -->
    - [x] P1.verify-human.6 Custom view: no chip, no auto-hide, no recency-sort (Day-only scope confirmed)  <!-- status: complete -->
    - [x] P1.verify-human.7 Chip visual/cosmetic: unobtrusive  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete: +7 CLI source-shape pins (test_visualize_cli.sh 205→212/0) + 6 container interactive behavioral pins (test_visualize_interactive.js 89→95/0). All Python suites unchanged (viz_data 79/0, viz_render 10/0, reclassify 42/0). One Test Triage entry resolved in-skill (code regression, high confidence): behavioral 2-6 needed `page.reload()` after hash-only `goto` to force React state re-init from new hash — pre-existing pattern from earlier v3 pins (e.g. WP9 P2 line 1862). -->

## Single-phase rationale

This is a Size-M feature with a tight, cohesive scope: one frontend transform layer added on top of an existing component, gated by view-mode, with one session-local UI affordance. Splitting into multiple phases would mean either (a) splitting auto-hide vs sort vs escape-hatch — but all three share the same `_applyRowDensityMitigation` helper and ship together as one observable user-facing change, or (b) splitting by surface (component vs tests) — which the verify-codify step already handles. The 7 impl tasks are small and inter-dependent enough that a single build → verify-loop is the right granularity.

## Current Node
- **Path:** Feature > (all phases complete)
- **Active scope:** ready for /feature-ship
- **Blocked:** none
- **Unvisited:** ship → finalize
- **Open discoveries:** see Discoveries below
- **Blocked:** none
- **Unvisited:** verify-auto → verify-self → verify-human → verify-codify (sequence-of-execution)
- **Open discoveries:** (1) P1.1 surfaced a hidden coupling: `viz_render.py::_wire_bar_click` does a literal-string match on the `DayTimeline` signature, which would have silently broken emit. The transform anchor was updated; the existence-of-this-coupling is a known and well-managed pattern (the byte-pin-relaxed dashboard.jsx still has a thin contract surface in viz_render.py). Not surfacing to backlog — this is normal transform-anchor maintenance, not new debt. (2) verify-self surfaced that `test_visualize_interactive.js` "WP9-P4: outside-click dismisses popover" test depended on DOM-order assumption (first `[data-seg-id]` not being under the popover panel at `right: 0`). Post-WP10 recency-sort changes which project is first → first segment shifts to a different geographic position which happens to land under the popover panel. Updated the test to dispatch `mousedown` on a segment with `start < 720` (noon) to land on the timeline's left half, clear of the popover. **Triage classification: obsolete test, high confidence** — test assertion behavior unchanged; only the fixture-selection method changed. Single explanation: test depended on an implicit ordering assumption that WP10 intentionally invalidates. Not blocking; preserves test semantics.

## Retrospect

- **What changed in our understanding:**
  - The hash-only `page.goto(URL + '#view=X')` pattern does NOT trigger React state re-derivation from the new hash when the previous page is the same dashboard.html (browser sees only a fragment change, no reload). Behavioral test pins that navigate between hash states need an explicit `page.reload()` after `goto`. This pattern was already used in earlier v3 tests (e.g., WP9 P2 behavioral 3 at line 1862) but I didn't catch it at codify-write time — first three tests in the WP10 block failed before I noticed.
  - `viz_render.py::_wire_bar_click` does a literal-string match on the `DayTimeline` signature in dashboard.jsx (anchored at `function DayTimeline({ data, expandedProjects, selectedSegId, showNow = true })`). Adding ANY prop to that signature breaks the transform silently — and would have silently broken the entire visualize emit if not caught by `test_visualize_cli.sh` first-emit check. Anchor was updated; the existence of this thin contract surface in viz_render.py is well-managed and tested.
  - The static design-canvas Dashboard wrapper invokes `<DayTimeline data={today} ... />` (dashboard.jsx:3416) which is stripped at emit. Updating it for symmetry is cheap (one prop addition) but easy to forget — caught by structural integrity checks.
  - The popover panel (`right: 0`, ~280px tall, `zIndex: 50`) geometrically overlaps the right half of project rows when open. The pre-WP10 WP9-P4 "outside-click dismisses popover" test happened to PASS because the first DOM project (`claude-time`) had its first segment at left position (08:42). Post-WP10 recency-sort puts `weekend-tinkering` first, whose first segment is at 19:20 — RIGHT side, directly under the popover panel → Playwright's actionability check intercepts. The test depended on an *implicit* DOM-order assumption that WP10 intentionally invalidates. Migration to mousedown-dispatch on a `start < 720` segment makes the test order-agnostic.

- **Assumptions that held:**
  - Strategy (a)+(c) per spec was the right call. User confirmed all 7 verify-human leaves on first pass — no rejection cycle. The "cheapest user-impact win" heuristic in the WBS held.
  - `_applyRowDensityMitigation` as a pure function over `(projects, viewport, dwCtx)` made testing straightforward. The single useMemo gate `if (view !== 'day' || !autoHideOn) return passthrough` cleanly handles all four bypass cases (Custom view, escape-hatch off, Week/Month/Compare via different paths).
  - The session-local "no URL hash" decision for the auto-hide toggle was correct. Default-elision discipline (CLAUDE.md URL-hash convention) — toggling auto-hide off is rare + non-persistent in user intent, no need to pollute hash.
  - The integration-boundary affirmation drove the right verification depth. F11 skip would have been wrong; verify-self via direct Playwright + verify-human walkthrough caught the behavior in the user's actual usage context.

- **Assumptions that were wrong:**
  - Plan estimated 7 impl tasks (P1.1–P1.7) but P1.1 expanded to include the `viz_render.py::_wire_bar_click` transform anchor update — caught at first emit. Plan-time grep should have included "what literal-string matches in `viz_render.py` reference the DayTimeline signature?" as a downstream-contract-impacts question. This is the **5th observed instance of `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS`** (cross-layer contract migration miss); the pattern is now firmly established. Documenting in retrospect; will surface as a learning candidate in reflect.
  - Behavioral test pins 2–6 in `test_visualize_interactive.js` initially didn't include `page.reload()` after hash-only navigation. Triage classified correctly (code regression, high confidence) and fixed in-skill, but with foresight I would have lifted the `goto + reload + waitForFunction(__dashboardViewport)` pattern verbatim from WP9 P2 line 1862 at write time, not after the first failed run.

- **Approach delta:**
  - Plan said "split build → verify-auto → verify-self → verify-human → verify-codify" — actual execution followed this exactly for a single phase. No back-loops. No F23 plan revisions. No F22 research redirects.
  - One in-flight test fix during verify-self (WP9-P4 fixture-selection migration to mousedown-dispatch) was absorbed without a back-loop — triage-classified as obsolete-test-high-confidence, fix applied in the same skill invocation. Single-explanation: WP10 changes DOM project order, which the test's first-DOM-position click implicitly relied on.

## Test Triage — v3 WP10 behavioral 2 (verify-codify first-run failure)

- **Classification:** Code regression — test is correct, new code wait-condition insufficient
- **Confidence:** High — single explanation: `waitForFunction` polled only for `[data-row-density-mitigation]` presence (set at first React render, BEFORE hash-restore useEffect fires). The 300ms `waitForTimeout` is too short on the served dashboard to catch the post-hash-restore viewport state.
- **Evidence:** Behavioral 2 captured `{mitigation:"on", dropped:"0", chipText:null, visibleRows:4}` — full default-viewport state, no hash applied. Manual verify-self at `file:///` URL with `waitForTimeout(1500)` produced `dropped:"2"` correctly. The test code under test (WP10 mitigation logic) is working; the test harness's wait condition was wrong.
- **Action:** Auto-fix — changed `waitForFunction` to poll on `window.__dashboardViewport.visible_start_min === 600` (the existing test-only Playwright introspection hook, used by earlier v3 pins). Applied same fix to behavioral 6 (two viewport transitions).

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

---

**Plan complete.** WP10 ships as a single phase (P1.1–P1.7) targeting `tools/claude-time/viz/dashboard.jsx` + one prop wire-up at `viz_render.py:986`. No CLI data-layer changes, no new URL-hash keys, no contract migration. Test pin coverage handled in verify-codify. Hand off to `/feature-build` (F7).
