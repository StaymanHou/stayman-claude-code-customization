---
workflow: feature
state: ship (complete)
created: 2026-05-19
drive_mode: autopilot
cycle: claude-time-visualize-v2
wbs_wp: WP2
---

# Feature: claude-time visualize — NOW marker client-side + staleness caption (WP2)

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-19

## Problem Statement

v1 of `claude-time visualize` emits a frozen NOW marker because the `NOW_MIN = 17 * 60 + 22` constant in `viz/dashboard.jsx:297` is set at HTML-generation time and never updates after page load. The companion text label `NOW · 17:22` at `viz/dashboard.jsx:337` is even worse — it's a hardcoded string from the design-canvas prototype that survived into the shipped HTML. Real users observe the marker stuck at 17:22 regardless of when they re-open the dashboard, which conflicts with the visual mental model the marker creates ("this is the current moment").

WP2 moves the NOW computation to the client: `useState` initialized from `Date.now()`, advanced by a 60-second `setInterval` ticker in `useEffect`, formatted into both the fractional position and the text label. The marker hides when viewing a non-today date (e.g., `--date 2026-05-01`) since "now" is undefined in that context. A small "snapshot: HH:MM" caption near the toolbar communicates that the *underlying data* is still snapshot-at-emit-time even though the NOW line is live — closing the comprehension gap between a moving cursor and static bars.

**Scope:** v1's design-canvas vestige `NOW · 17:22` text + frozen position. Out of scope: live data refresh (separate WBS item; explicitly deferred in v2 cycle).

## Work Tree

- [x] Phase 1: NOW marker → client-side + staleness caption
  **Observable outcomes:**
  - Browser: With `claude-time visualize --demo` open in browser, the NOW line position and label re-render every minute. Probed via Playwright: snapshot at T+0 captures label text matching `/NOW · \d{2}:\d{2}/` where the time equals the system clock's HH:MM (within ±1 minute). Then `browser_evaluate` advances `Date` (or we wait 65s — but for test speed, simulate by re-rendering with mocked `Date.now`) and assert the label updated.
  - Browser: With `claude-time visualize --date 2026-05-01 --demo` (or any non-today date), the NOW vertical line element (the absolute-positioned div with `background: oklch(0.55 0.18 25)` inside `HourRuler`) is absent from the DOM. Playwright `browser_snapshot` shows no element matching the NOW marker's distinctive color/structure.
  - Browser: A "snapshot: HH:MM" caption is visible in the toolbar area (or directly below it), rendered in mono font matching the existing `CT_TOKENS.mono`. The HH:MM equals the emit-time wall clock from the Python `claude-time visualize` invocation (read via `window.CT_DATA.meta.snapshot` or equivalent).
  - HTTP: N/A — pure-frontend artifact; no endpoint.
  - CLI: `claude-time visualize --demo --out /tmp/wp2-out.html` exits 0; emitted HTML does **NOT** contain the literal substring `NOW_MIN = 17 * 60 + 22` (the v1 hardcoded constant) and does **NOT** contain the literal substring `NOW · 17:22` (the v1 hardcoded label). Emitted HTML **DOES** contain a reference to `Date.now()` or `new Date(` (the client-side timestamp source) and **DOES** contain a snapshot-time field in the JSON literal (e.g., `"snapshot":` or `"emitted_at":`).
  - Console: Page load produces zero JavaScript errors. The 60s `setInterval` is correctly cleaned up on unmount (verify by reading the `useEffect` source — must return a cleanup function calling `clearInterval`).
  - [x] P1.1 Added `useNowMin()` hook + `_nowMinFromDate`/`_todayISO` helpers in `dashboard.jsx` (after the helpers block, ~line 56). Hook uses `React.useState` initialized to `new Date()` + `React.useEffect` with `setInterval(60_000)` and a `clearInterval` cleanup. Returns `{nowMin, todayISO}`.
  - [x] P1.2 `HourRuler` now accepts `nowLabel` prop; the `NOW · 17:22` hardcoded string was replaced with `NOW · {nowLabel}`. Parent (`DayTimeline`) computes the label.
  - [x] P1.3 `DayTimeline` now calls `useNowMin()`, gates `nowFrac` on `(showNow && isToday && inWindow)` where `isToday = data.iso === todayISO` and `inWindow = nowMin >= DAY_START_MIN && nowMin < DAY_END_MIN`. The static module-level `NOW_MIN = 17 * 60 + 22` was removed entirely (replaced by a comment explaining the WP2 transition).
  - [x] P1.4 `_cmd_visualize` in `tools/claude-time/claude-time` now constructs `meta = {snapshot: "HH:MM", snapshot_iso: ISO}` from `datetime.now()` at emit time. Both code paths (`--demo` and live DB) inject `data["meta"] = meta` into the dict before render. The data.js standalone file was NOT changed — meta is injected at the Python layer, so the design-canvas standalone load gracefully has no caption (defensive fallback in InteractiveToolbar handles missing meta).
  - [x] P1.5 `InteractiveToolbar` in `viz_render.py` now accepts a `snapshot` prop and conditionally renders a `snapshot: HH:MM` caption in mono font (fontSize 11, `CT_TOKENS.textTertiary`), placed between the date label and the right-side flex spacer. Caption has a help tooltip explaining the live-cursor + static-bars duality. Defensive fallback: `(window.CT_DATA.meta && window.CT_DATA.meta.snapshot) || null` — if meta is absent (design-canvas standalone), nothing renders.
  - [x] P1.6 Updated `viz_render.py` module docstring (added transform #7 explaining the caption) and `tools/claude-time/README.md` (added "Live NOW marker, snapshot data" paragraph explaining the dual communication: live cursor + snapshot caption + non-today hide).
  - [x] verify-auto — py_compile OK; render smoke OK (52KB HTML, useNowMin present, NOW_MIN/`NOW · 17:22` absent, Date.now/new Date present, snapshot key present); test_visualize_cli.sh 14/14 PASS; unittests 51/51 PASS; test_cli.sh 29/29 PASS; check-structure 121/1 (1 pre-existing settings-fixture FAIL, unchanged).
  - [x] verify-self — Live Playwright observation against 3 dashboards.
    - **Outcome 1 (NOW marker tracks system clock):** PASS. Populated fixture `/tmp/wp2-livetoday-populated.html` (iso=2026-05-19) rendered `NOW · 11:52` while system clock read 11:52 (delta 0min, ≤±1min tolerance). Screenshot at `.playwright-mcp/wp2-livetoday-populated-marker.png`. (Initial attempt FAILED due to `empty: true` test fixture short-circuiting to `<EmptyState>` — fixture was the bug, not the feature; re-ran with populated payload.)
    - **Outcome 2 (NOW hidden on non-today):** PASS. Both `wp2-today.html` and `wp2-nontoday.html` (demo iso=2026-05-13) rendered populated timeline with NO `NOW · DD:DD` label.
    - **Outcome 3 (snapshot caption):** PASS. `snapshot: HH:MM` rendered in toolbar on all three dashboards.
    - **Outcome 4 (no v1 hardcoded values):** PASS. `NOW_MIN = 17 * 60 + 22`: 0 occurrences; `NOW · 17:22`: 0; `Date.now()|new Date(`: 2; `"snapshot"`: 1.
    - **Outcome 5 (no JS errors + clearInterval cleanup):** PASS. 0 JS errors across all three pages; `clearInterval` present 1× per file.
    - **Cosmetic-only note (not blocking):** at clock times near a top-of-hour tick (e.g., 11:52 vs 12:00 tick), the `NOW · 11:52` label visually overlaps the next-hour ruler label. Marker placement is correct; only the text overlay. Logged below for verify-human awareness; not a back-loop.
  - [x] verify-human — Approved 2026-05-19. All 4 leaves PASS.
    - [x] P1.verify-human.1: Real-data smoke (today) — marker matches wall clock, caption matches emit time.
    - [x] P1.verify-human.2: Marker advances ~1min while tab idle; snapshot caption stays stale (correct).
    - [x] P1.verify-human.3: `--date 2026-05-15` shows past day's data, NOW marker absent, snapshot caption still reads emit time.
    - [x] P1.verify-human.4 (cosmetic): top-of-hour label-overlap accepted as-is; logged to backlog as polish item for later.
  - [x] verify-codify — Added 5 WP2 assertions to `tools/claude-time/test/test_visualize_cli.sh` (block "── 13. WP2"): emitted HTML lacks `NOW_MIN = 17 * 60 + 22` constant; lacks `NOW · 17:22` label; contains `Date.now()`/`new Date(`; contains `"snapshot"` key (meta.snapshot); contains `clearInterval` cleanup. All assertions exercise the end-to-end consuming surface (`claude-time visualize` CLI) against a seeded today-iso DB — satisfies integration-boundary rule.
    - **Test sweep:** test_visualize_cli.sh 19/19 PASS (was 14/14, net +5). Full claude-time suite: 51 unittests + 19 viz CLI + 29 report CLI + 17 hook = **116/0 PASS** (no regressions; +5 from WP1 baseline).
    - **Integration-boundary post-check:** As predicted at plan time, `meta.snapshot` was added at the CLI layer in `_cmd_visualize` (not in `build_day_data`), so `test_viz_data.py` is unaffected. Confirmed via running the suite — all 51 unittests still PASS.

## Current Node
- **Path:** Feature > (all phases complete) > ship
- **Active scope:** ship (Phase 1 is the only phase; all 10 leaves [x]; verify-codify added 5 WP2 assertions to test_visualize_cli.sh)
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** cosmetic label-overlap accepted by user, logged as `SURFACE-2026-05-19-CLAUDE-TIME-VIZ-NOW-LABEL-OVERLAPS-RULER-TICK` in `workflow/backlog.md` (priority: low, status: open)

## Retrospect

- **What changed in our understanding:** The `data.iso` field (already emitted by `build_day_data`) is the natural primary key for "is this dashboard showing today?" — no new metadata needed for that gating. The `meta` namespace at the data-payload top level is a cheap extension point we hadn't planned to introduce, but it landed cleanly and gives Phase 3+ a place to attach future emit-time facts (snapshot, cycle id, future "data freshness" indicators) without modifying `build_day_data`'s contract.
- **Assumptions that held:** (1) Direct-edit pattern from WP1's byte-pin relaxation worked smoothly again — no need to rebuild the emit-time-transform layer for this change. (2) `React.useState`/`React.useEffect` are in scope thanks to the v1 interactive Dashboard wrapper that already uses them. (3) Plan-time integration-boundary identification meant verify-codify's 5 assertions all targeted the right consuming surface (test_visualize_cli.sh) without scrambling at codify time.
- **Assumptions that were wrong:** First verify-self pass FAILed Outcome 1 because I synthesized the live-today fixture with `empty: true` to keep the payload minimal. The dashboard's `today.empty ? <EmptyState> : <DayTimeline>` branch short-circuited before the `iso === todayISO` gating could even fire, so the marker code path was structurally unreachable in the test. **Fixture, not feature** — recovered by synthesizing a populated payload and re-running. Surfaceable lesson: when verifying a gated UI feature, the fixture must traverse the gate predicates in order to reach the gated branch — minimal-payload shortcuts can hide branches that would never execute under the test.
- **Approach delta:** None substantive. The plan's 6 impl tasks landed in the order planned with task-level scope unchanged. The only minor delta: `_todayISO()` ended up as a helper function rather than baked into `useNowMin`'s return, because both `nowMin` and `todayISO` are needed by `DayTimeline`'s gating, so returning `{nowMin, todayISO}` from the hook is cleaner than calling two helpers.

## Communicate

**Feature complete:** WP2 of the `claude-time-visualize-v2` cycle — NOW marker client-side + snapshot caption — has shipped (commit `3a3f42c` on `origin/main`). The dashboard's NOW vertical line now tracks the system clock and ticks every 60s instead of freezing at HTML-emit time; it hides when viewing a past day (`--date 2026-05-15`); a `snapshot: HH:MM` mono-font caption near the toolbar tells the user how stale the bars are relative to the moving cursor. Verify by running `claude-time visualize` and leaving the tab open for a minute — the cursor advances; the snapshot caption does not.

Requester = operator — closure notice for self-record.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
- [SURFACED-2026-05-19] verify-human (cosmetic, accepted) — `NOW · HH:MM` label overlaps top-of-hour ruler tick label when wall-clock is within ~10min of the next tick. Logged as `SURFACE-2026-05-19-CLAUDE-TIME-VIZ-NOW-LABEL-OVERLAPS-RULER-TICK` in backlog (priority: low).
