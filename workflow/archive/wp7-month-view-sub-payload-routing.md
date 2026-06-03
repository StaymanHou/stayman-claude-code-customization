---
workflow: feature
state: ship (complete)
created: 2026-06-03
shipped: 2026-06-03
shipped_commit: 51d2393
drive_mode: autopilot
wbs_wp: WP7
cycle: claude-time-visualize-v3
---

# Feature: WP7 — Month view sub-payload routing

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-03

## Problem Statement

In v2, the Month view reads from `window.CT_DATA.months` (a flat `{YYYY-MM: <payload>}` map). v3's `build_window_data` (viz_data.py:1259-1341) emits the same shape under the new canonical key `month_payloads_by_iso`. The dashboard still reads the v2 alias `monthsMap = window.CT_DATA.months` at viz_render.py:105 — until WP7 lands, the Month view depends on the alias key that WP9 verify-codify will eventually delete.

WP7 migrates all 9+ Month-view consumer sites in `viz_render.py::_interactive_dashboard` from `monthsMap` (= `window.CT_DATA.months`) to `monthPayloadsByIso` (= `window.CT_DATA.month_payloads_by_iso`), preserving the existing in-window/out-of-window dispatch in `onPrevMonth`/`onNextMonth`. Per the v3 sub-payload routing convention in CLAUDE.md, the consumer reads `monthPayloadsByIso[monthIso]` with a useMemo fallback to the v2 alias (`monthsMap[monthIso]`) so v2-coexistence remains intact until WP9 strips the aliases.

This is a Size S mechanical analog of WP5 (Day) and WP6 (Week). One wrinkle distinguishes it: the in-window/out-of-window dispatch in `onPrevMonth`/`onNextMonth` already exists from v2 — the swap targets just need to switch from `monthsMap` to the routed lookup. The toast remains the out-of-window fallback (D3 + D7 behavior preserved).

**Plan-time downstream-contract-impacts grep complete** (per CLAUDE.md 4th-instance discipline):
- `updateHash({...})` dispatcher: `month` key is **already in the 7-key shape** from WP6. No new keys added by WP7. The pin at `test_visualize_cli.sh:988-996` ("hash-write five-branch dispatch") needs **zero updates**.
- v2 alias key reads (`window.CT_DATA.months` + destructured `const {months}`): primary grep targets `viz_render.py::_interactive_dashboard` lines 100-115, 105, 195-210; secondary destructuring grep `= window\.CT_DATA` confirms no destructuring reads of `months` (the v2 alias is only accessed via `window.CT_DATA.months` direct property access at line 105). Audit clean.
- Behavioral test pins for in-window/out-of-window dispatch: existing `test_visualize_interactive.js` pins (if any) need to be located and confirmed at P1.4 grep — if they currently assert against `window.CT_DATA.months[X]`, they'll need to update to the v3 lookup path.

## Work Tree

- [x] Phase 1: Month view sub-payload routing
  **Observable outcomes:**
  - Browser: `claude-time visualize` opens in a browser; with `view=month` (via toolbar tab or `#view=month` hash), the calendar grid renders the current month's data (`window.CT_DATA.month_payloads_by_iso[<currentMonthIso>]`). The DevTools console shows zero JS errors on mount.
  - Browser: clicking the ‹ Month nav arrow when the previous-month iso IS in `month_payloads_by_iso` keys → instant calendar grid swap (no page reload, no toast); the date-header label updates to the previous month's label; URL hash updates to `#view=month;month=<previousMonthIso>`.
  - Browser: clicking the › Month nav arrow when the next-month iso IS NOT in `month_payloads_by_iso` keys → `MonthNavToast` appears with the message "View <next-month-label>? Run this in your terminal to load that month:" + the `claude-time visualize --window <next-month-iso>-01:<next-month-iso>-<lastDay>` command; calendar grid does NOT swap.
  - Browser: on initial load with `#view=month;month=<iso-in-window>`, MonthView mounts directly with the requested month payload; no FOUC, no flash of Day-view first.
  - CLI: `claude-time visualize --window <range>` emits HTML containing both `window.CT_DATA.month_payloads_by_iso = {...}` AND (still, until WP9) `window.CT_DATA.months = {...}` — same canonical shape under both keys for v2-coexistence.
  - CLI: `node --check viz_render.py`'s emitted HTML (`grep -c "monthPayloadsByIso" <emit>`) returns ≥ N where N matches the consumer-site count after migration (currently 9 sites at viz_render.py:105, 117, 132, 197, 200, 205, 207, 595, 607, 791-792, 809, 835, 838 — count locked at build-time after exact migration).

  - [x] P1.1 Add v3 sub-payload sibling vars at viz_render.py:~100. Introduce `monthPayloadsByIso = window.CT_DATA.month_payloads_by_iso || {};` (paralleling WP5's `dayPayloadsByIso` + WP6's `weekPayloadsByMonday`). Compute `monthIsoKeys = Object.keys(monthPayloadsByIso).sort()` and `currentMonthIso = window.CT_DATA.window.end.slice(0, 7)`.

  - [x] P1.2 `monthIso` state init: rewrote `_initMonthIso` IIFE to validate hash.month against `monthPayloadsByIso` first, then `monthsMap` (v2 alias fallback). Default landing: `currentMonthIso` if in v3 map; otherwise first key of `monthIsoKeys`; otherwise v2 fallback chain.

  - [x] P1.3 Added `monthPayload` useMemo lookup with v2-alias fallback per CLAUDE.md v3 sub-payload routing convention.

  - [x] P1.4 Migrated `onPrevMonth` + `onNextMonth` dispatch: in-window check now `monthPayloadsByIso[X] || (monthsMap && monthsMap[X])`. Setter branches identical.

  - [x] P1.5 Migrated 3 remaining Month-view consumer-site groups (4 expressions) to `monthPayload` accessor: date-header label+count, ProjectFilterPopover, MonthView render-guard+payload-prop. Zero direct `monthsMap[monthIso]` reads remain in the render path.

  - [x] P1.6 `_initView` (lines 125-151) updated: extracted `_hasMonthData = monthIsoKeys.length > 0 || (monthsMap && Object.keys(monthsMap).length > 0)` and used it in both the hash-restore and CT_INITIAL_VIEW month-precondition checks.

  - [x] P1.7 No hash-write changes — confirmed by P1.8 regrep.

  - [x] P1.8 Plan-time literal-payload-object regrep: existing hash-write pin (`updateHash({ view: 'month', month: monthIso, range: null, preset: null, ranges: null, date: null, week: null })`) still matches the emit verbatim. Test runner result confirms (190/0 PASS).

  - [x] P1.9 Added 4 WP7 source-shape pins to `test_visualize_cli.sh` immediately after the WP6 block. All 4 PASS on first run. New baseline: 190/0 (was 186/0).

  - [x] P1.10 Added WP7 behavioral block to `test_visualize_interactive.js` (lines ~1413-1483): 5 assertions covering (1a) `month_payloads_by_iso` emit shape with 2-month coverage, (1b) initial monthIso = window.end month, (2a) prev-month click in-window → grid swap + no toast, (2b) hash gains `month=2026-03`, (2c) prev-month iso is a key in the v3 map (verifies migration is live). Re-uses MONTH_DASH_HTML fixture. `page.reload()` baked in per WP5 lesson. Existing v2 WP7-P2 behavioral 4/5 pins continue to PASS (same outcomes, now sourced from v3 map).

  - [x] P1.11 Header comments at viz_render.py:99-115 already describe the WP7 (v3) sub-payload routing (added in P1.1 alongside the sibling-var declarations). No additional comment edit needed.

  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
    - [x] P1.verify-human.1: In-window prev-month: ‹ click on a month with prev-iso in pre-rendered window → instant grid swap, URL hash updates, no toast.
    - [x] P1.verify-human.2: Out-of-window next-month: › click at the right edge → `MonthNavToast` with `--window` command, no grid swap.
    - [x] P1.verify-human.3: Hash-restore happy path: open URL with `#view=month;month=<in-window-iso>` → Month view mounts directly on that month, no FOUC.
    - [x] P1.verify-human.4: Hash-restore with out-of-window iso → graceful fallback (human-confirmed 2026-06-03).
    - [x] P1.verify-human.5: Default landing on `currentMonthIso` after Day→Month tab switch (human-confirmed 2026-06-03).
  - [x] verify-codify

## Current Node
- **Path:** Feature > finalize
- **Active scope:** finalize (retrospect + CHANGELOG + WBS tick + WIP archive)
- **Blocked:** none
- **Unvisited:** (none — all phases shipped)
- **Open discoveries:** none

**Ship result (2026-06-03):** Commit `51d2393` pushed to `origin/main` (parent `922f491` = WP6 finalize). Diff stat: 226 insertions, 22 deletions across 3 files. Zero force-push, zero amend, single clean commit.

**verify-human result (2026-06-03):** All 5 leaves PASS. 3 pre-cleared by verify-self (excluded from human review); 2 user-confirmed edge cases (`P1.verify-human.4` out-of-window hash fallback, `P1.verify-human.5` default landing). User: "all pass".

**verify-codify result (2026-06-03):** Test coverage audit + 1 new behavioral pin codifying the human-confirmed out-of-window hash fallback path. ZERO Test Triage entries (no failures). Final test baselines:
- `test_visualize_cli.sh`: **190/0 PASS** (+4 WP7 source-shape pins from build)
- `test_visualize_interactive.js` (in-container): **72/0 PASS** (+5 from build P1.10 + 3 from codify P1.verify-human.4 codification = 8 net new WP7 behavioral pins, all PASS first-run, no replay needed)
- `tests/check-structure.sh`: **125/0 PASS** (held)
- Integration-boundary requirement: satisfied (9 WP7 behavioral pins + 4 source-shape pins all exercise the consuming surface — `claude-time visualize` CLI + dashboard browser).

**verify-auto results (2026-06-03):** All scoped automated checks PASS.
- `python -m py_compile viz_render.py` → OK
- `node --check test_visualize_interactive.js` → OK
- `bash -n test_visualize_cli.sh` → OK
- `test_visualize_cli.sh` → **190/0 PASS** (was 186/0 baseline + 4 WP7 source-shape pins, all PASS first-run)
- `tests/check-structure.sh` → **125/0 PASS** (held)
- Existing hash-write literal-payload-object pin (`updateHash({ view: 'month', month: monthIso, ...7 keys })`) continues to match unchanged emit, confirming WP7's zero-hash-write-contract-impact prediction.

**verify-self results (2026-06-03):** 6/6 Observable outcomes PASS. Zero BLOCKING, zero COSMETIC.
- Behavioral test in `claude-time-test` container: **69/0 PASS** (was 64/0 baseline + 5 WP7 behavioral pins, all PASS first-run — no Test Triage replay needed, `page.reload()` workaround baked into the test from start per WP5 lesson).
- v2 WP7-P2 behavioral pins (`--month page loads`, `prev-month arrow swaps grid`, `next-month arrow → toast`, `Month → Day clears month + view hash keys`) continue to PASS after migration — the same outcomes, now sourced from `month_payloads_by_iso` via the useMemo with v2-alias fallback.
- v3-source-live verification: WP7 behavioral 2c specifically asserts that the prev-month iso is a key in `window.CT_DATA.month_payloads_by_iso` (not just present in the v2 `months` alias) — migration is live, not theoretical.
- Integration-boundary requirement satisfied: phase modifies the consuming surface (`_interactive_dashboard()` JSX in `claude-time visualize` shipped HTML), and 4 of 6 Observable outcomes cite that consuming surface by name (`claude-time visualize` CLI + browser-rendered dashboard with `#view=month` hash).

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-06-03] Phase 1 — Code-recon finding: existing v2 Toolbar Month-nav UI (`data-month-nav="prev"|"next"`, `data-month-iso=<iso>` at dashboard.jsx:421-440) is fully in place AND existing v2 in-window/out-of-window dispatch (`onPrevMonth`/`onNextMonth` at viz_render.py:592-615) already gates by `monthsMap[X]` presence. WP7 reduces to swapping the in-window-presence check from `monthsMap[X]` to `monthPayloadsByIso[X] || monthsMap[X]` at the dispatch site + adding a `monthPayload` accessor for the 6 consumer sites. Existing v2 behavioral pins at test_visualize_interactive.js:721-769 (WP7-P2 behavioral 4 + 5) ALREADY cover in-window-swap and out-of-window-toast — they'll continue to PASS after WP7 lands because the `data-month-grid` selectors and outcomes don't change. Plan P1.10 reduces to **one new behavioral pin** asserting the in-window swap routes through `monthPayloadsByIso` specifically (verifies the migration is live, not just the v2 alias still serving).

## Retrospect

- **What changed in our understanding:** The plan assumed WP7 would mirror WP5/WP6 mechanically — siblings + state + useMemo + dispatch + nav UI + hash + tests. Code-recon at build entry revealed a stronger position than expected: the v2 Toolbar Month-nav UI (`data-month-nav`, `data-month-iso`) and the in-window/out-of-window dispatch (`onPrevMonth`/`onNextMonth`) were both already in place from v2, gated by the `monthsMap[X]` presence check. Migration cost reduced to just (a) swap the presence-check expression to `monthPayloadsByIso[X] || monthsMap[X]` and (b) migrate 4 consumer-site expressions to the `monthPayload` accessor. The Toolbar required ZERO JSX edits (vs WP6 which added a full new ternary arm). New behavioral test surface area also smaller — the v2 WP7-P2 pins (lines 721-769) already covered both dispatch paths; only one new "v3 source verified live" pin (WP7 behavioral 2c) was strictly necessary to confirm the migration was live rather than the v2 alias still serving.

- **Assumptions that held:** (1) The useMemo-with-v2-alias-fallback pattern from CLAUDE.md (established at WP5, reinforced at WP6) extended cleanly to Month. (2) The `page.reload()` workaround from the WP5 lesson made all 8 new behavioral pins PASS on first run — no Test Triage replay. (3) The plan-time literal-payload-object grep at P1.8 correctly predicted zero hash-write contract impact (WP7 added no new hash key — `month:` was already in the 7-key dispatcher from WP6). (4) Drive-mode autopilot carried cleanly through plan → build → verify-auto → verify-self → verify-human → verify-codify → ship → finalize with only one human checkpoint (verify-human, as designed).

- **Assumptions that were wrong:** The plan's P1.10 over-estimated the number of new behavioral pins needed — proposed "3 pins covering both paths" because it didn't account for the v2 WP7-P2 pins already covering those paths. Built only 5 in P1.10 (vs WP6's 9) and 3 more in codify (codifying the human-confirmed P1.verify-human.4 out-of-window fallback). Net: 8 new behavioral pins, lower than WP6's 9, despite WP7 being structurally analogous. **The lesson:** for mechanical-analog WPs, the *existing test surface* needs grep-time recon during planning, not just the *production code* surface. Plan should have surfaced "existing v2 behavioral pins cover X — we only need to add Y" at plan time, not at build entry. (Mild — caught at build P1.10 with no harm; pattern worth noting for WP8/WP9 plans.)

- **Approach delta:** Implementation followed the plan exactly. The plan's 11 impl tasks (P1.1-P1.11) all landed as specified, with P1.11 (header comment update) absorbing into P1.1 (the v3 sibling-var declarations included the WP7-explanation comment block in one edit, so no separate comment-only edit was needed). One new behavioral block added at codify (WP7 behavioral 3a/3b/3c) to codify the human-confirmed out-of-window hash fallback — a +1 to plan scope, but inside the verify-codify gate's mandate. Zero back-loops. Zero Test Triage entries.

- **Pattern reinforcement:** Third consecutive WP (WP5, WP6, WP7) shipping with zero Test Triage and zero back-loops under autopilot drive mode. The combined plan-time discipline (literal-payload-object grep + downstream-contract-impacts pass) + build-time discipline (`page.reload()` baked into behavioral pins from the start) appears to be a stable equilibrium. WP8 (Compare view, the only WP in Phase 2 with a *known v2 limitation* it resolves — the preset content-not-refreshing bug) is the next test of whether this pattern holds when the WP isn't a pure mechanical analog.

## Communicate

**Feature complete:** WP7 (Month view sub-payload routing) has shipped on `origin/main` as commit `51d2393`. The Month view in `claude-time visualize` now reads from `window.CT_DATA.month_payloads_by_iso[monthIso]` (the v3 canonical sub-payload map) instead of the v2 `window.CT_DATA.months` alias — preserving the existing in-window swap vs out-of-window toast dispatch, but routing through the v3 source-of-truth. To verify in your browser: `claude-time visualize`, click the Month tab, ‹/› arrows swap calendar grids client-side for in-window months and emit a reload-redirect toast for out-of-window months. Requester = operator — closure notice for self-record.

