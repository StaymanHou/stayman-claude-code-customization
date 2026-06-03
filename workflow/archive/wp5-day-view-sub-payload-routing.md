---
workflow: feature
state: ship (complete)
created: 2026-06-03
shipped: 2026-06-03 (commit 820cba7, pushed to origin/main)
cycle: claude-time-visualize-v3
wp: WP5
drive_mode: autopilot
---

# Feature: WP5 — Day view sub-payload routing

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-03
**Entry:** spec (F4) → plan
**Cycle:** claude-time-visualize-v3 — Phase 2 (Frontend state-routing refactor)
**WBS:** WP5 (lines 122–133 of `docs/product/wbs.md`)

## Problem Statement

The v3 Day view still reads `window.CT_DATA.today` — the v2 legacy alias key — instead of the pre-rendered map `window.CT_DATA.day_payloads_by_iso[iso]` that the v3 emit (`build_window_data` in `viz_data.py`) populates for every ISO day in the window. This locks the Day view to a single day (the window's `end_iso`, aliased as `today`), prevents client-side Day-arrow nav, and gives the URL hash no way to pin a specific day. WP5 wires the Day-view render path to the v3 sub-payload map, adds client-side ‹/› nav between pre-rendered days, and introduces the `date=YYYY-MM-DD` URL hash key. This is the **first frontend WP of v3 Phase 2** — it establishes the sub-payload routing pattern that WP6 (Week), WP7 (Month), WP8 (Compare), WP9 (Custom-range) will copy.

## Work Tree

- [x] Phase 1: Day-view data plumbing — sub-payload routing + `date=` hash + ‹/› nav  <!-- status: complete 2026-06-03 — all 11 impl tasks + all 5 verify groups done; full regression sweep green -->
  **Observable outcomes:**
  - CLI: `./tools/claude-time/claude-time visualize --window 30d > /tmp/wp5_out.html; rc=$?; [ $rc -eq 0 ]` — exits 0, produces non-empty HTML.
  - CLI: `grep -c 'day_payloads_by_iso\[' /tmp/wp5_out.html` — emitted HTML contains at least one `day_payloads_by_iso[<key>]` consumer reference (the new lookup wiring), `≥ 1`.
  - CLI: `grep -c 'data-day-nav="prev"' /tmp/wp5_out.html && grep -c 'data-day-nav="next"' /tmp/wp5_out.html` — both Day-nav buttons emitted, each `== 1`.
  - CLI: `grep -c 'data-day-iso=' /tmp/wp5_out.html` — `data-day-iso` selector emitted, `≥ 1`.
  - CLI: `grep -c 'date:' /tmp/wp5_out.html` (within the `updateHash` patch dispatcher region) — the `date` key appears in at least one hash-write patch object, `≥ 1`.
  - Browser (Playwright): navigate to `file:///tmp/wp5_out.html`, no JS console errors on page load, default page renders Day view at the window's most-recent day (window.end). `[data-day-iso]` attribute equals `window.end_iso`. URL fragment is empty (default-elision active).
  - Browser (Playwright): click `[data-day-nav="prev"]` → `[data-day-iso]` attribute changes to `end_iso - 1 day`, URL fragment gains `date=<prior-iso>` within ~200ms, DayTimeline segments differ (segment count OR aria/title attributes change).
  - Browser (Playwright): with hash `#date=<earliest-iso-in-window>`, reload page → `[data-day-iso]` reflects the hash value, `[data-day-nav="prev"]` is `disabled` (boundary).
  - HTTP: N/A (no server endpoint changes).
  - Console: no React key-warning, no missing-prop warning, no "Cannot read properties of undefined" on any day-iso swap.
  - [x] P1.1 In `viz_render.py::_interactive_dashboard`: added `dayPayloadsByIso`, `dayIsoKeys`, `windowEndIso` sibling vars + `dayIso` state + `dayPayload` `useMemo` lookup + `stepDay/onPrevDay/onNextDay/prevDayDisabled/nextDayDisabled` helpers. The `const { today, week }` destructure stays per spec decision 2.
  - [x] P1.2 In `_interactive_dashboard`, extended the hash-write `useEffect` to include `date: <dayIso-or-null>` in every patch branch. Default-elision: emit `date: dayIso` when `view === 'day' && dayIso !== windowEndIso`; emit `date: null` otherwise.
  - [x] P1.3 `dateLabel` calc for Day view changed to `isDay ? dayPayload.label : week.label`. (No defensive fallback needed — `dayPayload` is `today` when lookup misses, per useMemo.)
  - [x] P1.4 In `_interactive_dashboard`, passed new props to `<Toolbar>`: `dayIso`, `onPrevDay`, `onNextDay`, `prevDayDisabled`, `nextDayDisabled`. The `stepDay(delta)` helper sorts dayIsoKeys ascending and bounds-checks the index.
  - [x] P1.5 In `dashboard.jsx::Toolbar`: accepted new props with safe defaults. Added `view === 'day'` branch as the FIRST ternary arm — renders ‹ button + IconCalendar+dateLabel span + › button, mirroring the month-nav visual treatment. Disabled state applies `cursor: not-allowed` + `opacity: 0.4` + native `disabled` attribute.
  - [x] P1.6 In `dashboard.jsx::Toolbar`, added `data-day-iso="<dayIso>"` attribute to the Day-nav container `<div>` (parent of the two buttons + label span).
  - [x] P1.7 Static design-canvas `Dashboard({variant})` at `dashboard.jsx:3198` left unchanged per spec decision 5. Verification-only no-op, confirmed.
  - [x] P1.8 All Day-view `today.X` reads inside `_interactive_dashboard` migrated to `dayPayload.X`: selected-session resolution, dayTotals computation, dateLabel calc, date-header-strip label + project/sessions count, ProjectFilterPopover projects prop, body timeline branch (DayTimeline `data` + EmptyState date), Minimap render-gate + data prop.
  - [x] P1.9 Added 4 new pins in the `# ── v3 WP5 codify` block of `test/test_visualize_cli.sh`: (a) Day-nav buttons emitted; (b) `day_payloads_by_iso[]` consumer wiring + `dayPayloadsByIso[` lookup-variable present; (c) `date: dateForHash|null` in updateHash patches; (d) `data-day-iso=` selector emitted. CLI suite ran 178 → 182 (+4 net new pins; +1 triage'd existing pin).
  - [x] P1.10 Added a WP5 behavioral test block in `test/test_visualize_interactive.js` reusing `MONTH_DASH_HTML` (--window 2026-03-01:2026-04-30): (1a-d) default-landing assertions (dayIso=window.end, hash empty, next-disabled, prev-enabled); (2a-b) prev-click → dayIso swap + hash gains `date=`; (3a-c) hash-restore at window-start (#date=2026-03-01) → dayIso reflects + prev-disabled + next-enabled. Test runs in container (verify-self).
  - [x] P1.11 Added `| v3 WP5 (day iso) | \`date\` | \`2026-05-29\` (YYYY-MM-DD) | \`dayIso === window.CT_DATA.window.end\` ... |` row to CLAUDE.md "Per-consumer key reservations" table. Prefixed with `v3 WP5` to disambiguate from the v2 cycle's WP5 (viewport) row.
  - [x] verify-auto  <!-- 2026-06-03: JSX parse OK; JS parse OK; Python imports OK; --window 7d emit rc=0 + all 5 WP5 source-shape markers present (data-day-nav=prev/next, data-day-iso, dayPayloadsByIso[ ×3, date: in updateHash ×5). -->
  - [x] verify-self  <!-- 2026-06-03: Live Playwright observation against /tmp/wp5_dash/dash.html (--window 7d, days 2026-05-28..2026-06-03). All 12 observable outcomes PASS, 0 BLOCKING: (1) no JS errors on load; (2) default landing data-day-iso=2026-06-03; (3) hash empty on default; (4) next-arrow disabled at end; (5) prev enabled; (6) prev click swaps to 2026-06-02; (7) hash gains date=2026-06-02; (8) date label re-renders ("WED·JUN 03"→"TUE·JUN 02"); (9) hash-restore #date=2026-05-28 → prev-disabled, next-enabled; (10) malformed #date=abc → fallback to default; (11) Day↔Week tab switch clean; (12) zero new errors across all interactions. One benign favicon 404 (resource error, not JS error). -->
  - [x] verify-human  <!-- 2026-06-03: All 7 leaves passed (visual polish of ‹/› buttons, snappy swap feel, clear disabled state, hash semantics for sharing, hash-restore reliability, no regression in Week/Month/Custom/Compare smoke, container suite optional+deferred to verify-codify). The 10 originally-planned mechanical leaves were pre-filtered out per the verify-self PASS rule. -->
    - [x] P1.verify-human.1 ‹/› buttons visually consistent with existing toolbar nav  <!-- 2026-06-03: human PASS -->
    - [x] P1.verify-human.2 Prev-click swap feels snappy + timeline re-renders  <!-- 2026-06-03: human PASS -->
    - [x] P1.verify-human.3 Boundary-disabled state visually clear  <!-- 2026-06-03: human PASS -->
    - [x] P1.verify-human.4 URL hash semantics behave like sharable URL pattern  <!-- 2026-06-03: human PASS -->
    - [x] P1.verify-human.5 Hash-restore in fresh tab reliable + fast  <!-- 2026-06-03: human PASS -->
    - [x] P1.verify-human.6 No regression in Week/Month/Custom/Compare tabs  <!-- 2026-06-03: human PASS -->
    - [x] P1.verify-human.7 Container suite — optional, deferred to verify-codify  <!-- 2026-06-03: human accepted defer -->
  - [x] verify-codify  <!-- 2026-06-03: Full regression sweep green — CLI 182/0, Python 131/0 (79+10+42), structure 125/0, interactive container 55/0 (+9 new WP5 pins). One Test Triage entry (WP5 behavioral 3a/3b): obsolete-test high-confidence — page.goto(#hash) is same-document nav, doesn't re-mount; added page.reload() to force fresh mount. Code behavior was correct (verify-self + verify-human already proved it); test mechanic was wrong. Fix landed in same phase; suite re-runs 55/0. No additional codification needed beyond P1.9 + P1.10 — verified behaviors are all covered by the source-shape CLI pins + behavioral container pins. -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** WP5 shipped 2026-06-03 in commit `820cba7` (pushed to origin/main). Ready for `feature-finalize` to retrospect, update CHANGELOG, mark WBS WP5 ✅ SHIPPED, archive WIP.
- **Blocked:** none
- **Unvisited:** finalize
- **Open discoveries:** 2 SURFACED at build/codify — both auto-handled in-phase

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-06-03] Phase 1 verify-auto — Build P1.2 (hash-write extension) broke one existing test scenario: `test_visualize_cli.sh:988-996` "WP8-P2+WP7-P2+WP11-P2 codify: hash-write five-branch dispatch". The scenario greps for literal patch-object strings `updateHash({ view: 'X', ... ranges: null })` — adding the WP5 `date:` key changed the suffix of every patch. Triaged as **obsolete test (high confidence)** per CLAUDE.md Test Triage convention: failure has exactly one plausible explanation, stateable in one sentence ("the new `date:` key is the WP5 contract; the literal-string assertion is now obsolete"). Updated the 4 grep strings inline to expect the new five-key shape; CLI suite re-runs 182/0. **Plan-time miss:** the plan's downstream-contract-impacts grep listed test pins but missed this specific five-branch dispatch pin because it asserts against the *patch object literal*, not against the `date` key. Reinforces `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` (medium) — fourth instance of the pattern.

Backlog entry NOT added — this discovery is self-contained (build-time triage caught it, fix landed in the same phase, the underlying CLAUDE.md convention already exists). Cross-reference to the existing WP3-PLAN-DOWNSTREAM-CONTRACT-MISS backlog item suffices.

## Retrospect

- **What changed in our understanding:**
  - The `dayPayload` useMemo's "default to `today`" fallback turned out more load-bearing than the spec implied. The plan said it was a defensive fallback ("dayPayload is `today` when lookup misses"); in practice it became the *correctness mechanism* that lets Custom view share the same `isDayLike` reads without WP5 having to fork the code path. Without that fallback, Custom view would have broken silently — `dayPayload` would be undefined on a Custom-view emit's `today.meta.{start,end}` reads. Worth flagging in the WP6 plan that the same pattern applies (Week's `dayPayload`-equivalent variable can be a fallback to `week`).
  - The verify-self subagent's manual workaround for the `page.goto(#hash)` same-document nav issue was visible in the result block ("browser_navigate did not re-mount due to same-document hash-only navigation") but I missed it when writing the container test in build P1.10. **Catching this earlier would have saved a verify-codify back-loop.** Lesson: when copy-pasting test logic from a subagent's transcript, scan the subagent's commentary for "I had to do X because Y" patterns and import those workarounds.

- **Assumptions that held:**
  - `today` alias key staying populated through WP9 is the right coexistence call — every existing test pin against `today` survived (lines 676–685 of `test_visualize_cli.sh`, line 572 of `test_visualize_interactive.js`).
  - The Toolbar's individual-props pattern (mirroring `monthIso`/`onPrevMonth`/`onNextMonth`) was the right call — the resulting `<Toolbar>` JSX call site reads naturally and the props slot cleanly into the existing month-nav structure.
  - Single-phase scope decision was correct — 2-phase split would have produced a half-finished UX (data layer migrated but no nav buttons) that verify-human would have correctly rejected.
  - The `isDayLike → dayPayload` substitution at the six render sites was safe for Custom view (`dayPayload === today` when `isCustom` because the useMemo's fallback resolves to the alias). User confirmed in verify-human leaf 6 ("no regression in Week/Month/Custom/Compare").

- **Assumptions that were wrong:**
  - **The plan-time downstream-contract-impacts grep missed two test scenarios.** (a) `test_visualize_cli.sh:988-996` greps for the literal hash-write patch-object strings — adding `date:` broke 4 of the 5 grep checks. (b) `test_visualize_interactive.js` "hash-restore via page.goto(#hash)" was a stale pattern from the verify-self subagent that didn't actually exercise re-mount. Both surfaced at verify-codify, not at plan time. **This is the 4th instance** of `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` — pattern is now well-established: the convention exists in CLAUDE.md but planning skills don't yet execute it as a mechanical step.
  - The static design-canvas Dashboard wrapper at `dashboard.jsx:3198` (`function Dashboard({ variant })`) ALSO has `const { today, week } = window.CT_DATA;` — the spec correctly identified this and decided to leave it (it's stripped at emit by `_strip_design_wrapper`), but during verify-self I worried briefly that JSX parser checks could trip on inconsistency between the two destructures. They didn't. Spec was right.

- **Approach delta:**
  - The plan called for `const day_payloads_by_iso = window.CT_DATA.day_payloads_by_iso || {};` (snake-case for consistency with the JSON key); actual implementation used `dayPayloadsByIso` (camelCase) since it's the JS-side binding, with the JSON key kept as the lookup path. Cosmetic — not a deviation worth annotating.
  - `_initView` IIFE was *not* touched (per spec decision 2) — it still reads `today` for the Custom-view fallback. Plan correctly anticipated this.
  - **One mid-flight scope decision:** the container interactive test was written during build P1.10 but I deferred actually *running* it (verify-human leaf 7) until verify-codify. That deferral was correct — verify-codify is where regression sweeps belong, and the suite caught the page.goto(#hash) test-mechanic bug that would have masked itself in verify-self (where the subagent did its own workaround).

## Communicate

> **Feature complete:** WP5 (Day view sub-payload routing) has shipped on `origin/main` (commit `820cba7`). The Day view now reads pre-rendered day payloads from `window.CT_DATA.day_payloads_by_iso[dayIso]` instead of the v2 `today` alias key, adds ‹/› client-side day-nav arrows to the toolbar, and persists current-day state as a `date=YYYY-MM-DD` URL hash key (sharable URLs round-trip correctly). To verify: run `claude-time visualize --window 7d` and exercise the toolbar's new ‹/› buttons — they swap between pre-rendered days instantly without reload.
>
> Requester = operator — closure notice for self-record.

## Test Triage — WP5 behavioral 3a/3b (hash-restore at window-start)

**Classification:** obsolete test (test-mechanic bug, code behavior correct)
**Confidence:** high
**Evidence:** Container suite reported `WP5 behavioral 3a/3b` FAIL with observed state `{"iso":"2026-04-29","prevDisabled":false,"nextDisabled":false}` — i.e., the page retained the prior-click test state (dayIso=2026-04-29 from step 2a) rather than reflecting the requested `#date=2026-03-01`. Single explanation: `page.goto(URL + '#date=X')` against a URL where only the fragment differs is **same-document navigation** in Chromium — no full page reload, the `useState(_initDayIso)` hash-reading initializer does NOT re-execute. The verify-self subagent observed and worked around this exact behavior during its outcome-9 check (recorded in its result block: "browser_navigate did not re-mount due to same-document hash-only navigation"). The test code carried the goto pattern from the manual subagent attempt without the workaround. Underlying WP5 code behavior — hash-restore on a real page mount — is verified correct: verify-self outcome 9 PASS (real fresh mount via subagent), verify-human leaves 4 and 5 PASS (user confirmed sharable-URL pattern works in a fresh tab).
**Action:** Auto-fixed the test by adding `await page.reload()` after the `page.goto(...#date=...)` call. The reload forces a full re-mount, which re-runs the hash-reading initializer — matching the "user pastes URL in fresh tab" flow the test claims to simulate. Re-running container suite to confirm 55/0.

---

## Phase boundaries — decision and rationale

**Single phase** (not two). The original spec floated 2 phases (data + state + hash → nav UI + tests + CLAUDE.md). On close inspection, the impl tasks form one tightly coupled unit:

- The data-source migration (P1.1, P1.3, P1.8) and the state + hash wiring (P1.2, P1.4) are not testable independently — the `dayIso` state is the bridge between them.
- The nav UI (P1.5, P1.6) is the only way to *exercise* the state, so the verify-self / verify-human checks for either half need the other half to be present.
- The CLAUDE.md update (P1.11) is one line of documentation; splitting it into its own phase would be procedural overhead, not value.
- Test pins (P1.9, P1.10) are tightly coupled to the new source-shape / behavioral surfaces — they ride with the implementation, not as a separate phase.

A two-phase split would force a verify-self pass where Day-view *renders* off the new map but the nav buttons aren't wired yet — a half-finished UX that the human reviewer would correctly bounce. Single phase is the right grain.

## Downstream-contract-impacts grep (per CLAUDE.md convention)

Spec already did this pass. Re-confirming at plan time:

| Surface | What changes | Affected? |
|---|---|---|
| `viz_render.py::_interactive_dashboard` | New `dayIso` state, `dayPayload` lookup, `Toolbar` props, hash-write patch | Yes — primary touch site (P1.1, P1.2, P1.3, P1.4, P1.8) |
| `dashboard.jsx::Toolbar` (line 212) | New props + button source | Yes (P1.5, P1.6) |
| `dashboard.jsx::Dashboard` static wrapper (line 3198) | Reference rendering only — stripped at emit | No (P1.7 = verify-only no-op) |
| `test_visualize_cli.sh:676–685` ("WP6 codify: data-layer .today key") | Asserts `window.CT_DATA.today` populated | **Not affected** — `today` alias key still attached by CLI (spec decision 1) |
| `test_visualize_interactive.js:572` (reads `window.CT_DATA.today.projects.length`) | Same as above | **Not affected** — alias survives until WP9 |
| `claude-time` CLI alias-attachment at lines 665–681 | Attaches `today`/`week`/etc. aliases | Not touched in WP5 |
| `build_window_data` in `viz_data.py` | Sub-payload map producer | Not touched in WP5 (its output contract is already locked by WP1) |
| CLAUDE.md per-consumer URL-hash key table | New `date=` entry | Yes (P1.11) — additive, not a contract break |

**Net:** 0 broken assertions in existing tests. New tests are additive. The Test Triage gate at verify-codify should see 0 failures from the WP5 change set. Baseline (CLI 178/0, Python 131/0, interactive 46/0, structure 125/0) must stay green.

## Spec decisions carried forward to build

1. `today` alias key stays through WP9 — no CLI changes in WP5.
2. `_initView` IIFE keeps reading `today` for non-day fallbacks — only Day-view *render path* migrates.
3. Default-elision: `dayIso === window.CT_DATA.window.end` (most-recent pre-rendered day).
4. Individual props on Toolbar (`dayIso`, `onPrevDay`, `onNextDay`, `prevDayDisabled`, `nextDayDisabled`) — mirrors the existing `monthIso`/`onPrevMonth`/`onNextMonth` precedent.
5. Static design-canvas Dashboard (`dashboard.jsx:3198`) unchanged — reference rendering only.

## Backlog context

No high-priority backlog item conflicts with WP5. Two medium items from WP4 (`SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER`, reinforced `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS`) and one from WP3 (`SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING`) are conceptually relevant but don't block WP5; their lessons (destructure-grep + plan-time contract-impacts grep) are already applied above. `SURFACE-2026-05-29-FEATURE-FINALIZE-MISSES-WBS-TASK-CHECKBOXES` will bite at WP5 finalize unless explicitly handled — flag at finalize time, not now.
