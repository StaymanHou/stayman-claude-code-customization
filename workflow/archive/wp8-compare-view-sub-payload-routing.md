---
workflow: feature
state: ship (complete)
drive_mode: autopilot
created: 2026-06-03
shipped: 2026-06-03
ship_commit: ab65a26
cycle: claude-time-visualize-v3
wp: WP8
---

# Feature: v3 WP8 — Compare view sub-payload routing

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-03

## Problem Statement

In v2, `CompareView` reads `window.CT_DATA.comparison.{a,b}.metrics` — a single pre-computed comparison window. The `PresetSelector` sub-tabs (WoW / Today-vs-trailing / MoM / Custom) update the `preset` state and URL hash on click, but the underlying `comparison` data is the same regardless of preset — so all three pre-rendered preset tabs render *identical content*. This was surfaced at v2 WP11 Phase 2.A verify-human as a PARTIAL finding (preset content-not-refreshing). v3 already emits `window.CT_DATA.compare_payloads_by_preset = {wow, today-vs-trailing, mom}` (each with its own `.a`/`.b`/`.deltas`/`.meta`), with the top-level `comparison` aliased to `.wow` for v2-frontend compatibility. WP8 routes `CompareView` to read the preset-specific sub-payload, making the preset click produce an instant content swap. The Custom-preset path (user-picked ranges, not pre-rendered) preserves v2's RangePicker pair + reload-redirect-toast behavior.

## Scope

Single phase, Size S, mechanical-style routing change with one wrinkle: 4-preset state where 3 presets are pre-rendered (instant swap) and `custom` falls back to v2's re-emit path. Follows the established v3 WP5–WP9 useMemo-with-v2-alias-fallback pattern.

Out of scope: changing the rendered row set or column layout; renaming the `comparison` v2-alias key (WP9 verify-codify removes it); modifying the PresetSelector UI or RangePicker UX.

## Work Tree

- [x] Phase 1: Route `CompareView` through `compare_payloads_by_preset[preset]`  <!-- all leaves complete -->
  **Observable outcomes:**
  - Browser: Playwright loads dashboard with `#view=compare;preset=wow`, finds `[data-compare-view="true"]` mounted with `[data-compare-row="parallelism-multiplier"]` containing non-empty A and B column text.
  - Browser: Clicking `button[data-compare-preset='today-vs-trailing']` updates `[data-compare-preset][data-active="true"]` AND changes the text content of `[data-compare-row="parallelism-multiplier"] [data-compare-col="a"]` between WoW and MoM presets (the WP8 acceptance criterion — content, not just hash, refreshes).
  - Browser: Clicking `button[data-compare-preset='custom']` activates Custom — RangePicker pair renders, no JS console errors. (Custom-path data behavior unchanged from v2.)
  - Browser: No JS console errors during a wow → today-vs-trailing → mom → wow round-trip click sequence.
  - HTTP: N/A (frontend-only routing change).
  - CLI: `python -c "import json; d=json.load(open('out.json')); cpbp=d['compare_payloads_by_preset']; assert set(cpbp) == {'wow','today-vs-trailing','mom'}; assert d['comparison'] is cpbp['wow']"` exits 0 (existing WP11-P1 contract — codify-anchor, no new CLI behavior).
  - [x] P1.1 In `viz_render.py::_interactive_dashboard`, add `compare_payloads_by_preset` and `comparison` references to the `window.CT_DATA` reads (already present — verify the JSX consumer can see them).
  - [x] P1.2 Add a `comparePayload` `useMemo` in `Dashboard` (or directly in CompareView via prop drilling — pick at build time) that prefers `compare_payloads_by_preset[preset]` and falls back to `comparison` for v2-alias compatibility. Mirror the WP5/WP6/WP7 pattern (`dayPayload`/`weekPayload`/`monthPayload`).
  - [x] P1.3 In the JSX site at viz/dashboard.jsx:869, replace `<CompareView comparison={window.CT_DATA.comparison} />` with `<CompareView comparison={comparePayload} />` (passes the routed sub-payload, keeping the prop name to minimize CompareView internal churn).
  - [x] P1.4 Plan-time test-surface grep audit: confirmed the literal-payload-object hash-write pin at `test_visualize_cli.sh:988-996` does NOT need updates — WP8 adds zero new hash keys (the `preset:` and `ranges:` keys were already in the compare branch from v2 WP11). The pin's grep targets only the four NON-compare branches' literals (month/custom/week/day) — the compare branch's literal at `viz_render.py:393-403` is not pinned by that test.
  - [x] P1.5 Update v2 archive annotation — DEFERRED to finalize (doc-update step, not build-phase deliverable). Tracked in finalize backlog sweep.
  - [x] P1.6 Test pin (CLI source-shape): added 4 new pins in `test_visualize_cli.sh` (after WP7 block, before summary): comparePayloadsByPreset sibling var defined; comparePayload useMemo with v2-alias fallback; JSX consumer routes via comparePayload; legacy direct read of `window.CT_DATA.comparison` GONE (regression-pin).
  - [x] P1.7 Test pins (behavioral, container): added 6 new pins in `test_visualize_interactive.js` (inserted after WP11-P2A block) — WP8 behavioral 1a..1f covering: wow baseline non-empty; mom click → content differs from wow; today-vs-trailing click → distinct from BOTH; round-trip back to wow → matches baseline; custom click → RangePicker mounts (v2 path preserved); no JS console errors across full sequence.
  - [x] P1.8 No `page.reload()` needed — all 6 WP8 behavioral pins exercise client-side state swaps within a single page session (no hash-restore round-trips). The WP5-lesson `page.reload()` workaround targets hash-restore correctness, not click-driven state changes; not applicable here. Documented to explain the deviation.
  - [x] verify-auto — CLI 194/0 (+4 WP8 pins), interactive 78/0 (+6 WP8 pins). Two iterations to find the right metric row: parallelism-multiplier → human → engaged-session (the only row whose composite cell content reliably differs across wow/tvt/mom on the existing 14-day compare_real fixture). Test-design lesson documented in the WP8 1a header comment.
  - [x] verify-self — Spawned subagent observed 6 outcomes against locally-served compare_real.html (host port 8770). Outcomes 1-4, 6 PASS in subagent run. Outcome 5 (fresh-load hash-restore #view=compare;preset=mom) FAILed BLOCKING in subagent run — re-verified directly from orchestrator in fresh browser session: PASS (active=mom, all 4 buttons correctly toggled). Subagent's FAIL was Playwright session state-carryover noise (a SPA-style hash-only nav after outcome 4's custom-preset hash didn't re-mount React). Documented per Subagent Re-Verification Heuristic — no back-loop needed.
  - [x] verify-human — human PASSed P1.verify-human.5 (subjective preset-click UX feels reactive) and P1.verify-human.6 (Custom-preset layout + reload-redirect-toast v2 behavior preserved). Leaves 1-4 excluded per verify-self pre-filter (PASSed there).
    - [x] P1.verify-human.1 — verify-self PASS (excluded from human checklist).
    - [x] P1.verify-human.2 — verify-self PASS (mechanical part excluded; subjective re-check via P1.verify-human.5).
    - [x] P1.verify-human.3 — verify-self PASS (mechanical mount excluded; subjective re-check via P1.verify-human.6).
    - [x] P1.verify-human.4 — verify-self PASS (re-verified directly by orchestrator after subagent false-positive).
    - [x] P1.verify-human.5 — human confirmed preset click → content swap feels reactive (the WP8 resolution of v2 WP11 PARTIAL).
    - [x] P1.verify-human.6 — human confirmed Custom-preset RangePicker layout + v2 reload-redirect-toast behavior preserved.
  - [x] verify-codify — Full test sweep green: CLI 194/0, interactive 78/0, Python 131/0, structure 125/0. Downstream-contract grep confirmed clean — no other test files assert against the v2 wiring (only the new WP8 regression-pins, which intentionally match the v2 form to catch reverts). WP8 acceptance criterion codified by P1.7's behavioral pins written at build time. **Zero Test Triage entries — fourth consecutive WP** (WP5, WP6, WP7, WP8).

## Current Node
- **Path:** Feature > ship
- **Active scope:** ship (all phases complete; verify-codify green)
- **Blocked:** none
- **Unvisited:** finalize, reflect
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect

- **What changed in our understanding:**
  - The "convention-validation-lap" pattern (parked at 2 confirmations after WP6/WP7) earns out on WP8 — the third application produced a working ship in a single phase with no plan revisions. WP8 was the **first non-mechanical-analog Phase 2 WP** (resolves a real v2 limitation; has 4-preset state with mixed pre-rendered vs re-emit semantics), and the WP5-WP9 sub-payload routing convention (useMemo with v2-alias fallback) applied cleanly anyway. The "mixed semantics" worry at plan time was overstated — the useMemo's null-fallback handles Custom-preset's no-preset-payload case naturally, and the v2 RangePicker reload-redirect flow needed zero code changes.
  - The plan-time-test-surface-grep learning (parked unwritten after WP7 reflection) was applied here and paid off: P1.4's regrep confirmed zero impact on the literal-payload-object hash-write pin BEFORE writing any code. Saved a verify-codify Test Triage round-trip that would have happened the moment a stale `<CompareView comparison={window.CT_DATA.comparison}>` literal would have shifted.
  - **New finding: behavioral-test row-choice has fixture-density coupling.** Two iterations at verify-auto to find the right metric row (parallelism-multiplier → human → engaged-session) revealed that low-density seeded fixtures collapse certain derived metrics (multiplier=1.00× when each window has at most one session per day; human=0m when seeded sessions classify as ai_agent not human). The `engaged-session` row's composite cell (wallclock + effort + multiplier + session_count) was the only row whose text content reliably differed across the three A-windows on the existing 14-day compare_real fixture. **Lesson for future content-differs assertions:** check the metric row's *derivation chain against the fixture seed* before writing the pin. If the seed has N sessions in window X and 1 session per day, multipliers collapse to 1.00× regardless of window length.

- **Assumptions that held:**
  - Zero new hash keys — WP8 reused the compare branch's existing `preset` + `ranges` keys from v2 WP11. Plan-time regrep confirmed this in advance.
  - The useMemo pattern from WP5/WP6/WP7 ports directly to WP8 with one change (preset key instead of iso key).
  - Custom-preset path needed zero changes — v2's `compareRanges` state + RangePicker + reload-redirect-toast were all preserved by the useMemo's fallback to `window.CT_DATA.comparison` (which itself is the wow alias).

- **Assumptions that were wrong:**
  - **Plan P1.7's test row choice (`parallelism-multiplier`) was naive.** The plan picked the first row in DOM-order without sanity-checking whether the fixture would produce distinct values for that row. Two verify-auto iterations to recover. Cheap cost (verify-auto did its job — caught it before verify-self), but the **plan should have grepped the fixture seed against the row's metric derivation at plan time**. Filed as a candidate global learning at reflect time (if user opts to persist).
  - **The verify-self subagent's BLOCKING FAIL on outcome 5 (`#preset=mom` hash-restore)** was Playwright session state-carryover, not a real bug. The Subagent Re-Verification Heuristic at verify-self caught and resolved this correctly — direct orchestrator-side re-verification PASSed in a fresh browser context. Estimated time saved by the heuristic: one back-loop to build (would have hunted a non-bug in `_initPreset` and burned ~10 minutes before realizing the bug wasn't there). The heuristic is load-bearing.

- **Approach delta:** No code-level deviation from the plan. Three text-only deviations: (1) the parallelism-multiplier → engaged-session row switch at verify-auto (test design, not impl); (2) plan P1.4 anticipated potential test-surface impacts that turned out to be zero (good — regrep is now confidently zero-cost-when-zero-impact); (3) verify-human leaves 1-4 were pre-filtered out per the verify-self exclusion rule and two new subjective UX leaves (5, 6) added to satisfy the integration-boundary requirement — this was correct procedure, not a deviation.

## v3 sub-payload routing pattern — 4 of 4 application now in place

The WP5–WP9 useMemo-with-v2-alias-fallback pattern (codified in CLAUDE.md after WP5) has now been applied to all four pre-rendered sub-payload views. Status snapshot at WP8 finalize:

| WP | Sub-payload var | Primary lookup | v2-alias fallback | Status |
|---|---|---|---|---|
| WP5 | `dayPayload` | `dayPayloadsByIso[dayIso]` | `today` | ✅ |
| WP6 | `weekPayload` | `weekPayloadsByMonday[mondayIso]` | `week` | ✅ |
| WP7 | `monthPayload` | `monthPayloadsByIso[monthIso]` | `monthsMap[monthIso]` | ✅ |
| WP8 | `comparePayload` | `comparePayloadsByPreset[preset]` | `window.CT_DATA.comparison` | ✅ |

**WP9 (Custom-range)** is the bridging case — it shares Day's `isDayLike` reads and currently relies on the `today` alias key via WP5's `dayPayload` useMemo fallback. WP9 will either fork `isDayLike` into `isDay` + `isCustom` or introduce a `customPayload` with the same pattern. After WP9 verify-codify removes the v2 alias keys (`today`, `week`, `comparison`, `months`), the useMemo fallbacks become dead code — at that point the convention's bridging purpose is consumed and the comment headers can be simplified.

## Plan-time context notes

- **Existing v2 WP11-P2A behavioral pins:** 11 total, lines 1125–1224 in `test_visualize_interactive.js`. Cover preset-click → hash update + `data-active` attr swap, plus 8-row layout invariants. They do NOT assert content-differs-between-presets (the WP8 acceptance criterion gap). WP8 new pins extend the existing block, do not replace it.
- **`compare_payloads_by_preset` data layer:** already shipped in v3 WP4 (`viz_data.py:1281`, `claude-time:620,681`). `comparison` is a v2-alias for `compare_payloads_by_preset.wow` (top-level alias key, set at `claude-time:681`). WP8 changes the *consumer*, not the data layer.
- **Hash-write dispatcher:** the compare branch at `viz_render.py:390-403` already emits `preset` (always when in compare view) and `ranges` (only when `preset === 'custom'`). WP8 adds ZERO new hash keys. The literal-payload-object hash-write pin at `test_visualize_cli.sh:988-996` is unaffected.
- **WBS task 8.4 (v2 archive annotation):** moved out of build phase into finalize sweep — it's a doc-update step, not part of the routing change. Documented as P1.5 placeholder in this plan but with no actual task body; finalize will handle.
- **Custom-preset path:** preserved as-is from v2. The RangePicker pair onChange already triggers a hash update; reload-redirect for actual data re-emit was the v2 behavior and remains so. WP8 does NOT make Custom render instantly — that's the WP9 (Custom-range view) concern.
