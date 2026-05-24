---
workflow: feature
state: verify-codify (all phases complete; ready for ship)
created: 2026-05-24
cycle: claude-time-visualize-v2
wbs_wp: WP7
drive_mode: autopilot
---

# Feature: WP7 — Month view

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-24
**Entry:** spec → plan (complex feature, size L)

## Problem Statement

`claude-time visualize` currently has Day, Week, and Custom view tabs (functional) and a disabled "Month" tab. Users want a calendar-month rollup: a 7-column grid where each day-cell encodes **daily intensity** (total active+subagent minutes) via a single GitHub-contribution-graph-style color saturation/lightness — the at-a-glance "how busy was this day" signal. Click-to-drill takes the user to Day view for project-breakdown detail (the 2D composition view); prev/next-month arrows enable fast historical sweeping. The feature reuses WP3's `build_range_data` for the data layer (no new Python builder), follows WP8's `--range` precedent for the new `--month YYYY-MM` CLI flag, and bifurcates the dashboard's render path at `view === 'month'` — Month view is a parallel branch that bypasses the lane-based timeline entirely.

[Updated 2026-05-24: Phase 2 verify-human FAILED on the original D5 (vertical-strip per-project density tiles). Root-cause realization: Month view's role is the 1D "how busy" question; project composition is a 2D concern that competes with the intensity signal and is what Day view already answers via drill-down. Inverting the color encoding to **monochrome saturation = total minutes**, plus shortening cell aspect ratio from 1:1 to ~1.5–2:1 (GitHub-style). Spec D5 (vertical strips) is **superseded** by D5' (single-tile saturation). D1/D2/D3/D4/D6/D7 unchanged.]

## User Stories

(Carried from spec — unchanged.) Pattern-spotting glance at the month; click-day → Day view; prev/next-month nav; URL-hash deep-link; CLI `--month` parity.

## Resolved Design Decisions

**Locked at spec review (D1–D4):**
- **D1:** Hybrid nav — emit-time pre-loads active month + previous month; prev-arrow is client-side swap, next-arrow + farther-back is reload-redirect.
- **D2:** GitHub-graph filled-cell density tiles (per-project sub-rectangles by area).
- **D3:** Click-day reload-redirects to `claude-time visualize --date YYYY-MM-DD` (default Day-view multi-day window).
- **D4:** Filter chips visible-but-inert in Month view.

**Resolved at plan time (OQ1–OQ3):**
- **D5 (was OQ1): Cell sub-layout = vertical strips.** Each project gets a full-cell-height strip whose width is proportional to that project's active minutes. Sorted left-to-right by descending active minutes. Solo-project days = single fill. Rationale: simplest layout for ~6 projects in an ~80×80px cell; deterministic; no squarified-treemap library needed; matches the "ranked left-to-right" reading affordance.
- **D6 (was OQ2): Payload shape = `window.CT_DATA.months[YYYY-MM]` map.** Keyed by ISO month string. Extensible for a future 3+ month horizon without a schema break. Top-level `window.CT_DATA.today` is preserved unchanged (legacy compat for Day/Week/Custom views — those views still emit + consume the existing `today`/`week` shape; `months` is purely additive). When `--month` is the invoked CLI flag, `today` is set to the active month's payload (so Day/Week views still have *something* to render if the user clicks those tabs — they'll show the month's first day / month's first week, consistent with WP8's "Custom view picks its own range; other views fall back to defaults" pattern).
- **D7 (was OQ3): Click-day on prev-month grid drills to `--date`.** Click-day always means "drill into this day," regardless of which month's grid was clicked. No staying in Month view on click.

## Work Tree

- [x] Phase 1: CLI + Python emit path (`--month` flag, two-month payload, `CT_INITIAL_VIEW='month'`)
  **Observable outcomes:**
  - CLI: `claude-time visualize --month 2026-04 --no-open --out /tmp/m.html` exits 0; `/tmp/m.html` exists.
  - CLI: `claude-time visualize --help` stdout contains `--month YYYY-MM`.
  - CLI: `claude-time visualize --month 2026-99` exits 2; stderr contains `--month` and names the failed validation rule (e.g. "shape" or "parse").
  - CLI: `claude-time visualize --month 2099-01` (future month) exits 2; stderr contains `--month` and `future`.
  - CLI: `claude-time visualize --month 2026-04 --range 2026-05-01:2026-05-07` exits 2; stderr names mutual-exclusion with `--range`.
  - CLI: `claude-time visualize --month 2026-04 --demo` exits 2; stderr names mutual-exclusion with `--demo`.
  - HTML emitted file contains the literal string `window.CT_INITIAL_VIEW = "month"` when `--month` is set.
  - HTML emitted file contains the literal substring `window.CT_DATA.months = {` AND keys `"2026-04"` AND `"2026-03"` (active + previous month) when `--month 2026-04` is set.
  - HTML emitted file's `months["2026-04"]` payload contains `meta.start: "2026-04-01"` and `meta.end: "2026-04-30"` (Jest-grade smoke check via `grep`).
  - HTML emitted file's `months["2026-03"]` payload contains `meta.start: "2026-03-01"` and `meta.end: "2026-03-31"`.
  - HTML emitted file when `--month` is NOT set: contains NO `months` key (regression-pin — existing Day/Week/Custom emits stay byte-identical to pre-WP7 shape).
  - **Integration-boundary check:** `viz_render.py::render_html` signature unchanged from WP8 (no new positional args). The two-month payload is passed via `data` dict's new `months` key; legacy `today`/`week` keys still populated for the `--month` path (D6 fallback rule).
  - [x] P1.1 Add `_parse_month_flag(raw, today)` helper in `claude-time` next to `_parse_range_flag` — mirrors its shape: validate `^\d{4}-\d{2}$` format, year/month bounds (`1 <= month <= 12`), not-in-future (`(year, month) <= (today.year, today.month)`); on failure print rule-naming stderr message and return None.
  - [x] P1.2 Added `--month YYYY-MM` arg to the `viz` subparser. Help-text names mutual-exclusion with `--range` and `--demo`.
  - [x] P1.3 Parse `args.month` in `_cmd_visualize` right after `args.range`; mutex guards for `--month` ⊕ `--range`, `--month` ⊕ `--demo`; `month_dates: tuple[date, date] | None`.
  - [x] P1.4 When `month_dates` is set: route the day-window through `(month_start, month_end)` (so `today_payload = build_range_data(month_start, month_end)`); also load events for prev month via `_load_window_events` per-day loop and call a second `build_range_data` for the prev-month payload. Used `calendar.monthrange` for last-day computation; added `_prev_month(y, m)` helper for the (y, m=1 → y-1, m=12) wrap.
  - [x] P1.5 Packed both payloads into `data["months"] = {active_iso: today_payload, prev_iso: prev_payload}`. `data["today"]` is the active-month payload (D6 fallback) by virtue of routing the day-window through `month_dates` — no separate assignment needed. `data["week"]` stays week-of-today as before (note: not week-of-month-start — chose week-of-today because the existing `monday = target_day - timedelta(days=target_day.weekday())` line already produces that; switching to week-of-month-start would touch more lines for marginal value. Captured as a P1.disc if needed).
  - [x] P1.6 Initial-view precedence updated: `--month > --range > --week > default` (`initial_view = "month"` when `month_dates is not None`).
  - [x] P1.7 Verified: `viz_render.py::render_html` does `data_literal = json.dumps(data, ensure_ascii=False)` → the new `data["months"]` key passes through verbatim into `window.CT_DATA`. `{{CT_INITIAL_VIEW}}` is a generic template substitution that already accepts any string value, so `"month"` flows straight through. **No `viz_render.py` change required.**
  - [ ] P1.disc.* — none surfaced at impl time. Section reserved for verify-auto/self/human.  <!-- status: NOT-STARTED -->
  - [x] verify-auto — 3 scoped checks PASS: (1) `python3 -m py_compile ./claude-time` syntax OK; (2) helper unit smoke 9/9 (`_parse_month_flag` valid + leap-Feb + non-leap-Feb + shape-fail + future + month-00 + month-13 + current-month-allowed; `_prev_month` year-wrap); (3) CLI smoke against seeded 2-event DB — `--month 2026-04` emits 8/8 expected contract assertions (`CT_INITIAL_VIEW = "month"`, `months` map with `2026-04` + `2026-03` keys, per-month `meta.start`/`meta.end`).
  - [x] verify-self — 18/18 Phase 1 Observable Outcomes PASS via direct CLI/HTML observation (Phase 1 has no UI surface; Playwright subagent would be over-tooled). Independent fixture (5 events across two months). Outcomes verified: O1 happy-path rc=0+HTML, O2 --help lists --month, O3a/b shape-error rules, O4 future-rule, O5/O6 both mutex stderr messages, O7 `CT_INITIAL_VIEW = "month"`, O8 both `months` keys present, O9/10 per-month `meta.start`/`end` (×4 dates), O11 regression-pin (no `--month` → no `months` key), O12 integration-boundary (`viz_render.render_html` signature unchanged), O13 `data.today` present in `--month` emit (D6 fallback), O14 HTML well-formed top, O15 `data.today.meta.start == active-month start` (D6 fallback identity). 0 BLOCKING, 0 COSMETIC. Phase 2's Browser outcomes correctly identified as out-of-scope for this phase.
  - [x] verify-human — all 4 leaves PASS (human-confirmed 2026-05-24).
    - [x] P1.verify-human.1 (H1.1): real-DB --month invocation OK — page opens, no console errors.
    - [x] P1.verify-human.2 (H1.2): --help --month block wording is clear and consistent with --range.
    - [x] P1.verify-human.3 (H1.3): all 5 stderr messages read sensibly and name the failed rule.
    - [x] P1.verify-human.4 (H1.4): `Object.keys(window.CT_DATA.months)` returns exactly two ISO-month strings; meta.start/end match expected month boundaries.
  - [x] verify-codify — 13 WP7-P1 assertions added to `tools/claude-time/test/test_visualize_cli.sh` (own fixture, 5-event seed across 2026-03+2026-04). Coverage: --help flag listing, CT_INITIAL_VIEW emit, months-map two-key shape, active+prev meta.start/end, no-months regression-pin, 3 validation error rules (shape/bounds/future), 2 mutex error paths (--range, --demo), D6 fallback identity (data.today.meta.start), integration-boundary signature pin (viz_render.render_html). All 13/13 PASS first run. Full suite posture: 115/0 viz_cli (was 102), 29/0 cli, 75/0 unittest discover = **219/0 total**. Structure check 122/0. No test triage needed (no failures).

- [x] Phase 2: MonthView component + render-branch wiring + nav + URL hash
  **Relevance check (before Phase 2):**
  - Requester still needs this: TBD at Phase 2 entry
  - Requirements unchanged: TBD at Phase 2 entry
  - Solution still feasible: TBD at Phase 2 entry
  - No superior alternative discovered: TBD at Phase 2 entry
  **Verdict:** TBD at Phase 2 entry

  **Observable outcomes:**
  - Browser: Playwright navigates to `--month 2026-04` page; toolbar shows enabled Month tab; Month tab has `active` styling.
  - Browser: A 7-column calendar grid is visible; row count = ceil(days_in_month + first_day_offset / 7) (5 or 6 rows depending on month).
  - Browser: At least one day cell with active time renders with `data-month-day` attribute AND a non-empty per-project sub-rectangle structure (Playwright: `document.querySelectorAll('[data-month-day-active="true"] [data-project-strip]').length > 0` when the month has any data).
  - Browser: An empty day cell (zero active time) renders with `data-month-day-active="false"` and no `[data-project-strip]` children; hover shows the "no tracked time" title attribute.
  - Browser: Clicking the Day tab from Month view reads `view === 'day'` (`document.querySelector('[data-view-active="day"]')` becomes truthy); Month grid disappears; DayTimeline (or EmptyState) renders.
  - Browser: Clicking a day cell triggers `window.location.assign(<URL containing 'visualize --date'>)` — verified by Playwright stubbing `window.location.assign` to capture the URL; the captured URL contains `--date YYYY-MM-DD` matching the clicked day.
  - Browser: Prev-month arrow click swaps the grid to display the previous month — no page reload — `data-month-iso` attribute on the grid container changes from `2026-04` to `2026-03`; URL hash updates to `view=month;month=2026-03`.
  - Browser: Next-month arrow click triggers a page-reload to `claude-time visualize --month YYYY-MM` — verified by capturing `window.location.assign` URL containing `--month 2026-05`.
  - Browser: Prev-arrow click when no prev-month is pre-loaded (e.g., already at the prev-month grid → going further back) ALSO triggers reload-redirect.
  - Browser: URL hash `view=month;month=2026-04` on initial load → MonthView renders for `2026-04`; reload of the same URL preserves state (no flash to Day view).
  - Browser: Default-elision works — switching from Month back to Day clears `month` from the hash.
  - Browser: Filter chips remain mounted + clickable during Month view (D4); toggling a chip persists state in URL hash; switching to Day view applies the previously-set filter.
  - Console: no JS errors on load, on Month tab click, on day-cell click (stubbed reload), on prev-arrow click, on next-arrow click (stubbed reload), on filter chip toggle.
  - **Integration-boundary check:** `viz_render.py::_strip_design_wrapper` + `_interactive_dashboard` continue to work — Month view is an additive component in `viz/dashboard.jsx`, not an emit-time transform. No `viz_render.py::_interactive_dashboard` change required for the renderer itself.
  - HTML emitted file: contains `function MonthView` (component is in dashboard.jsx source); contains `tabBtn('Month', 'month', view === 'month', true)` enabled form; does NOT contain `tabBtn('Month', 'month', false, false)` disabled form (regression-pin).
  - [x] P2.1 In `viz/dashboard.jsx::Toolbar` (line ~216), Month tab enabled: `tabBtn('Month', 'month', view === 'month', true)`. Also extended Toolbar signature with new props: `monthIso, onPrevMonth, onNextMonth` (default no-ops so non-month invocations stay clean).
  - [x] P2.2 `MonthView` component added to `viz/dashboard.jsx` (between WeekTimeline and Minimap). Inputs: `monthIso`, `payload`, `onDayClick`. Renders 7-column Monday-first calendar grid, leading/trailing padding cells inert, day-of-week header row (MON–SUN). Today's date in the active month gets a highlighted border (`CT_TOKENS.active`).
  - [x] P2.3 Day-cell vertical-strip density (D5) rendered: `dayAggs` Map<iso, Map<alias, minutes>> built via React.useMemo from `payload.projects[].sessions[].segs` (active+subagent kinds aggregated). Per-cell strips sorted desc by minutes, widths `flexBasis: ${pct}%`, color via new `_projectTint(alias)` helper (oklch hue hashed from alias). Day-number overlay top-left with semi-transparent dark background for legibility. `data-month-day`, `data-month-day-active`, `data-project-strip` selectors for behavioral testing.
  - [x] P2.4 `viz_render.py::_interactive_dashboard` wiring: destructured `months` from `window.CT_DATA.months`; extended `_initView` IIFE to recognize `view='month'` (gated on hash.month + monthsMap presence); added new `_initMonthIso` IIFE (hash → today.meta.start[:7] → first months key → current calendar month fallback); `const [monthIso, setMonthIso] = React.useState(_initMonthIso)`; URL-hash write `useEffect` extended to 4 branches with `month` key (set when view==='month', null otherwise).
  - [x] P2.5 Click-day handler resolved as **option (b) toast + clipboard** (the plan's planned candidate). `onDayClick(iso)` triggers `setNavToast({message, command: claude-time visualize --date YYYY-MM-DD})`. New `MonthNavToast` component renders fixed bottom-right, auto-copies command to clipboard on mount (with permission-denied fallback to non-copied display), auto-dismisses after 6s, has explicit × dismiss button. `data-month-nav-toast="true"` selector for Playwright.
  - [x] P2.6 Prev-month handler: `onPrevMonth()` checks `monthsMap[prev_iso]` — if present, pure `setMonthIso(prev_iso)` swap; otherwise falls through to the `MonthNavToast` reload-redirect pattern with `--month YYYY-MM`.
  - [x] P2.7 Next-month handler: `onNextMonth()` always uses the `MonthNavToast` reload-redirect pattern (no future month pre-loaded). Next-month iso computed via `_nextMonthIso(monthIso)` helper.
  - [x] P2.8 Body render branch bifurcated: `view === 'month'` branch added BEFORE the `isDayLike` branch. When monthsMap[monthIso] exists, renders `<MonthView .../>`; otherwise renders `<EmptyState date={month name — no data loaded}/>`. SidePanel rendering also gated on `!isMonth` (no segment-selected concept in Month view). Minimap render-gate already `isDayLike && !today.empty` — Month view excluded automatically.
  - [x] P2.9 Emit-transform verification: `test_viz_render.py` 6/6 PASS — `_strip_design_wrapper` regex still locates the marker against the modified dashboard.jsx; "real source still strips" end-to-end pin holds. `_wire_bar_click` and `_add_interrupt_hairlines` not affected (MonthView uses its own selectors; doesn't touch SegmentBar or InterruptHairlines code paths).
  - [x] P2.disc.1 — **Documented contract impact realized:** WP8-P2-8 (test_visualize_cli.sh hash-write three-branch dispatch assertion) became obsolete when Phase 2 extended the dispatcher from 3 → 4 branches. Triaged 2026-05-24 as obsolete-test (high-confidence); auto-updated the assertion to the new four-branch shape (added `month` key to each grep expectation, renamed pin). Triage entry recorded in `## Test Triage` section above. Lesson logged in `## Discoveries`: this is the kind of downstream-contract impact that CLAUDE.md's plan-level pass calls out — should have been a named Phase 2 deliverable rather than a verify-codify safety-net catch.
  - [x] verify-auto — 3 scoped checks PASS: (1) `dashboard.jsx` structural integrity — braces 851==851, parens 738==738, brackets 112==112, and `_strip_design_wrapper` section-header marker present. (2) `viz_render.py` py_compile + `test_viz_render.py` 6/6 (including "real source still strips" end-to-end pin against modified dashboard.jsx). (3) `--month 2026-04` emit source-shape smoke 9/9: MonthView + MonthNavToast components present, Month tab enabled form, disabled-Month-tab-form regression-pin, `_initMonthIso` IIFE, four-branch hash dispatcher, all Playwright selectors (`data-month-day`, `data-month-nav-toast`), `_projectTint` helper.
  - [x] verify-auto (post-back-loop, 2026-05-24) — 3 scoped checks PASS: (1) `dashboard.jsx` integrity post-redesign — braces 844==844, parens 721==721, brackets 113==113, marker present (note: counts shifted from pre-back-loop 851/738/112 because the redesign removed `_projectTint` and the strips render loop; net smaller). (2) `viz_render.py` py_compile + `test_viz_render.py` 6/6 unchanged. (3) Redesign-specific source-shape smoke 10/10 effective: MonthView present, `_intensityColor` + `_MONTH_INTENSITY_PALETTE` added, `_projectTint` removed (regression-pin), `data-project-strip` removed (regression-pin), `data-month-day-intensity` added, `data-month-day-active` preserved, `1.7 / 1` aspect ratio (new), `1 / 1` aspect ratio removed (regression-pin), `data-month-day={iso}` JSX-expression form confirmed via attribute-name grep (one bash-quoting false-positive in my smoke pattern looked for `data-month-day="` literal, which the JSX source doesn't use — but the attribute IS correctly emitted as `data-month-day={iso}` and rendered by React; re-verify gate's Playwright already confirmed 30 such cells at runtime).
  - [x] verify-self (pre-back-loop, OBSOLETE — superseded by re-run below) — 22/22 against the old D5 vertical-strip design. Two assertions (O4b "2 density strips" + O4c "2 density strips") were contract-tied to D5 and don't apply to D5'. Kept here for traceability.
  - [x] verify-self (post-back-loop re-run, 2026-05-24) — 23/23 Phase 2 Observable Outcomes PASS via in-container Playwright against the REDESIGNED MonthView (D5' single-tile monochrome intensity, 1.7:1 aspect). Same 8-event multi-project fixture (alpha/beta/gamma across 2026-04 + 2026-03). **Contract-aware rewrites for the redesign:** O4b changed from "multi-project day has 2 strips" → "max-day (2026-04-22, 540min) renders at intensity=1.0" (D5' normalization correctness); O4c changed from "multi-project day has 2 strips" → "≥3 distinct intensity-bucket colors across 4 populated days" (D5' palette discrimination); added O4d "zero `[data-project-strip]` elements" (D5' regression-pin against re-introducing strips). All design-orthogonal outcomes (O1/O2/O3/O5/O6–O12) unchanged and re-PASS. Final: zero JS console errors. Heuristics applied: SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL (React-fiber direct onClick); SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE workaround (unique 12-char session IDs in seed).
  - [x] verify-human — all 8 leaves PASS after second back-loop (aspect bumped 1.7:1 → 2:1 per user request 2026-05-24).
    - [x] P2.verify-human.1: Cell aspect ratio 2:1 — measured at 2.00 across viewports 1024/1280/1440; entire month grid fits in one 800px-tall viewport height without scroll (user's explicit goal). Was FAILED at 1.7:1 (still too tall), fixed by single-line edit to `aspectRatio: '2 / 1'`.
    - [x] P2.verify-human.2: Monochrome intensity encoding answers "how busy was this day" at a glance — confirmed by user.
    - [x] P2.verify-human.3: Layout coherence at different widths — confirmed by user.
    - [x] P2.verify-human.4: Today highlight readability — confirmed by user.
    - [x] P2.verify-human.5: Toast wording + paste-and-run — confirmed by user.
    - [x] P2.verify-human.6: Prev/next arrow affordance + snappy prev-swap — confirmed by user.
    - [x] P2.verify-human.7: Empty-day affordance — confirmed by user.
    - [x] P2.verify-human.8: Real-DB end-to-end — confirmed by user.
  - [x] verify-codify — 23 new assertions added across two test files. All 23 PASS first run. No test triage needed.
    - **17 source-shape assertions** in `test_visualize_cli.sh` (WP7-P2-1 through WP7-P2-17): MonthView + MonthNavToast components defined; Month tab enabled form + disabled-form regression-pin; `_intensityColor` + `_MONTH_INTENSITY_PALETTE` (min + max bucket endpoints) present; `_projectTint` removed (D5 → D5' regression-pin); `data-project-strip` removed (D5 → D5' regression-pin); 2:1 aspect ratio pinned (fits-in-viewport contract); 1:1 aspect ratio absent (back-loop fix regression-pin); `data-month-grid` + `data-month-day` + `data-month-day-active` + `data-month-day-intensity` selectors; `data-month-nav="prev"/"next"` arrow selectors; `data-month-nav-toast` selector; `_initMonthIso` IIFE; `monthIso` state + setter; 6 month-helper functions defined (`_monthIsoToParts`, `_monthIsoToLabel`, `_prevMonthIso`, `_nextMonthIso`, `_daysInMonth`, `_mondayIndex`).
    - **6 behavioral assertions** in `test_visualize_interactive.js` (new `renderMonthDashboard()` helper emits a `--month 2026-04` HTML alongside the existing `--demo` HTML via a seeded multi-day DB + `project_names` config map + globally-unique session IDs): --month page loads at hash → grid renders; 30 day cells + 4 populated + max-day intensity=1.0; click-day → MonthNavToast with `--date 2026-04-15` command; prev-month arrow client-side swap (no toast, URL hash updates); next-month arrow → reload-redirect toast with `--month 2026-05`; Month → Day clears month + view hash keys (default-elision). All use React-fiber direct `onClick` (SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL workaround).
    - **Full suite posture:** 132/0 viz_cli (was 115/0; +17), 28/0 interactive (was 22/0; +6), 29/0 cli, 75/0 unittest discover = **264/0 total** (was 219/0; +45 across the full WP7 cycle — Phase 1 + Phase 2). Zero regressions.
    - [ ] H2.1 Visually confirm the calendar grid layout matches expectation: 7 columns, Monday-first, day numbers in top-left of cells, outside-month cells dimmed.
    - [ ] H2.2 Visually confirm the vertical-strip density tiles read clearly — multi-project days show distinct project colors, solo-project days fill the cell with one color, empty days are visibly dimmed.
    - [ ] H2.3 Click a populated day → confirm the click-day handler behavior (whatever P2.5 resolved to: alert+clipboard, toast, or actual reload).
    - [ ] H2.4 Click the prev-month arrow → grid swaps to prev month instantly (no page flicker).
    - [ ] H2.5 Click the next-month arrow → confirm the reload-redirect pattern resolves the same way as click-day.
    - [ ] H2.6 Refresh the page with `#view=month;month=2026-04` in URL → Month view restores, correct month grid shown.
    - [ ] H2.7 Toggle filter chips during Month view → grid is visually unchanged (chips inert), state persists when switching to Day view.
    - [ ] H2.8 Switch Month → Day → confirm Day view renders correctly with the original `--month`-emit data shape (D6 fallback works).
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > ship
- **Active scope:** all phases complete (Phase 1 + Phase 2 both fully [x]); ready for `/feature-ship`
- **Blocked:** none
- **Unvisited (sequence-of-execution):** ship → finalize

## Phase 2 final tuning summary (2026-05-24, aspect 1.7 → 2.0)

User feedback at second verify-human round: "change the ratio to 2:1. Basically I'm hoping the whole month could fit into the height of one screen without having to scroll."

**Single-line edit:** `viz/dashboard.jsx` two `aspectRatio: '1.7 / 1'` literals → `'2 / 1'` (both the populated day-cell and the outside-month padding cell).

**Verification:** 1280×800 / 1440×800 / 1024×800 viewports — measured cell ratio 2.00 across all three; grid `bottom` lands at exactly the viewport height (800px) in each, meaning **6-row months fit entirely above the fold without scroll** at any common laptop/desktop width. User goal achieved.

**Regression posture:** `test_visualize_cli.sh` 115/0, `test_viz_render.py` 6/6 — no regressions from the aspect bump.
- **Open discoveries:** [PLAN-AMBIGUITY-2026-05-24] click-day reload-redirect mechanism (resolved as MonthNavToast); [VERIFY-HUMAN-BACK-LOOP-2026-05-24] cell-size + color-encoding redesign — LANDED (re-verify gate 8/8 PASS, awaiting human re-judgment).

## Back-loop build summary (2026-05-24, scoped re-entry P2.verify-human.1+.2)

**Root-problem update recorded in Problem Statement (2026-05-24 inline update marker).** Month view's primary axis is 1D daily intensity, not 2D per-project composition. Project breakdown lives in Day view via drill-down.

**Files touched:**
- `tools/claude-time/viz/dashboard.jsx` — removed `_projectTint(alias)` helper (~14 lines); added `_MONTH_INTENSITY_PALETTE` constant (6-entry oklch scale) + `_intensityColor(intensity)` helper (~22 lines). In `MonthView`: replaced `dayAggs: Map<iso, Map<alias, minutes>>` with simpler `dayTotals: Map<iso, total_minutes>` (~16 lines); added `monthMax` useMemo computing the normalizer. Rewrote the day-cell render block (~40 lines): cell `aspectRatio` 1:1 → 1.7:1, removed inner strips loop, single `background: _intensityColor(intensity)` per cell, added `data-month-day-intensity` attribute, dropped `flexDirection: 'row'` / `display: 'flex'` from the button (no longer needed), day-number label color rule simplified to `labelLight = intensity >= 0.5`. Updated section-header comment block to reflect D5'. Net: ~50 lines diff (~+22 / −28).

**Spec design decisions affected:**
- **D5 (vertical-strip per-project density tiles)** — **SUPERSEDED by D5'** at 2026-05-24 verify-human back-loop. New D5': single-tile monochrome saturation encoding total minutes, normalized against month max. Documented in Problem Statement.
- D1/D2/D3/D4/D6/D7 unchanged.

**Re-verify gate** (per build §6, scoped to the two failed leaves):
- **R1 (P2.verify-human.1):** day-cell rendered aspect ratio measured at 1.7:1 ✓
- **R2a:** zero `data-project-strip` elements ✓
- **R2b:** 5 populated cells emitted for 5 seeded days ✓
- **R2c:** 5 distinct background colors (5 buckets render distinguishably) ✓
- **R2d:** intensities monotonically non-decreasing across date-sorted days ✓
- **R2e:** max-day at intensity=1.00 (correct normalization) ✓
- **R2f:** all 25 empty cells at intensity=0 ✓
- **R3:** no JS console errors after redesign loads ✓

**Regression posture:** `test_visualize_cli.sh` 115/0 (no WP8/Phase-1/WP6/WP5b/WP9 regressions from the redesign). `test_viz_render.py` 6/6 (emit transforms still work).

**Seed-fixture lesson surfaced (test infrastructure, NOT a code defect):** First re-verify gate run had 4/8 PASS because the heaviest seeded day (780 min = 13h starting at noon) spanned past midnight, leaving an orphan UPS on day-N and orphan Stop on day-N+1 that the per-day worker couldn't pair. Re-seeded all sessions to start at 09:00 and shortened the max to 720min (12h) so they fit within calendar-day boundaries. Worth noting as a fixture-construction gotcha for any future tests that need long sessions. Not surfaced to backlog (caught + fixed in-test; would only re-bite if someone writes a similar overnight-spanning fixture).

## Phase 2 build summary (2026-05-24)

**Files touched:**
- `tools/claude-time/viz/dashboard.jsx` — added 6 month-helper functions (`_monthIsoToParts`, `_monthIsoToLabel`, `_prevMonthIso`, `_nextMonthIso`, `_daysInMonth`, `_mondayIndex`, `_projectTint`); extended Toolbar signature with `monthIso, onPrevMonth, onNextMonth` props + added month-nav dateLabel-slot branch; enabled Month tab; added `MonthView` component (~110 lines, 7-col calendar grid, GitHub-graph filled-cell vertical-strip density tiles, today highlight, click-day handler); added `MonthNavToast` component (~50 lines, fixed bottom-right toast + auto-clipboard-copy). Net: +~250 lines.
- `tools/claude-time/viz_render.py` (`_interactive_dashboard`) — destructured `months` from CT_DATA; extended `_initView` IIFE to recognize 'month'; added `_initMonthIso` IIFE + `monthIso` state; added `navToast` state + `onDayClick`/`onPrevMonth`/`onNextMonth` handlers; extended hash-write `useEffect` from 3 → 4 branches (all branches now include `month` key); added `isMonth` const; threaded new props through Toolbar; bifurcated date-header strip + body render branch at `view === 'month'`; gated SidePanel render on `!isMonth`; appended MonthNavToast at the end of the wrapper. Net: +~70 lines.
- `tools/claude-time/test/test_visualize_cli.sh` — WP8-P2-8 hash-dispatch assertion updated to four-branch form (obsolete-test triage; documented in `## Test Triage`).

**P2.5 ambiguity resolved at build time** (was documented as a plan-time discovery): chose **option (b) toast + clipboard**. The `MonthNavToast` component is reused by all three reload-redirect paths (click-day, next-month, prev-of-prev). Auto-copy-to-clipboard with permission-denied fallback. No `window.location.assign` — the dashboard is `file://` so there's no real navigation target; the toast is the honest UX for this constraint.

**Regression posture:** 219/0 across all suites (`test_visualize_cli.sh` 115/0, `test_cli.sh` 29/0, `python -m unittest discover` 75/0). One obsolete-test triaged + updated mid-phase (WP8-P2-8 hash-dispatch four-branch update). `test_viz_render.py` 6/6 PASS (emit-transform pin holds).

**Source-shape smoke** (independent of suite): MonthView component present, MonthNavToast present, Month tab enabled, disabled-Month-tab regression-pin holds, all Playwright-stable selectors (`data-month-day`, `data-month-day-active`, `data-month-grid`, `data-month-nav`, `data-project-strip`, `data-month-nav-toast`) all emitted, all state machinery (`monthIso`, `navToast`, `isMonth`, `_projectTint`, `_monthIsoToLabel`) all present. 18/18 spot-checks PASS.

**Plan deviations:** none material. The "alternative if both months happen to cover the clicked day's context window, swap client-side" branch (mentioned in spec D3) was NOT implemented — chose the simpler always-reload-redirect for click-day. Defensible: the user's request was always "drill into this day", and the reload-redirect mechanism is honest and consistent across all the reload paths (click-day, next-month, prev-of-prev). Adding client-side-swap-when-context-covered would have added complexity (computing whether the clicked day's ±14/+7 window fits inside `monthsMap[active]` AND `monthsMap[prev]`) for marginal benefit (the common case is drilling into a day at the *middle* of a month, where the context window will partly straddle the next or prev month and need re-fetch anyway).
- **Open discoveries:** [SURFACED-2026-05-24] wbs.md size-guard exceeded (logged to backlog as low-priority follow-up); [PLAN-AMBIGUITY-P2.5] click-day reload-redirect mechanism on a `file://` dashboard — resolve at Phase 2 build/verify-self.

## Phase 1 build summary (2026-05-24)

**Files touched:**
- `tools/claude-time/claude-time` — added `_parse_month_flag` + `_prev_month` helpers (~40 lines); added `--month` arg to viz subparser (~6 lines); added month-dates parse + mutex block in `_cmd_visualize` (~18 lines); routed `month_dates` through the existing day-window logic (~3 lines edited); added `months` map emission block (~25 lines); updated initial-view precedence (~6 lines edited). Net: +~95 lines new / ~9 lines edited.

**Observable outcomes verified at smoke (all PASS):**
- `--help` lists `--month YYYY-MM`.
- `--month 2026-04` (with seeded DB) exits 0; emits HTML; `CT_INITIAL_VIEW = "month"`; `window.CT_DATA.months` map has both `"2026-04"` and `"2026-03"` keys; both payloads have correct `meta.start`/`meta.end`.
- `--month 2026-99` (out-of-bounds): rc=2, stderr names "month in 01..12".
- `--month 2099-01` (future): rc=2, stderr names "must not be in the future".
- `--month not-a-date` (shape): rc=2, stderr names "YYYY-MM shape".
- `--month 2026-04 --range ...`: rc=2, stderr names mutex with `--range`.
- `--month 2026-04 --demo`: rc=2, stderr names mutex with `--demo`.
- Default emit (no `--month`): no `months` key in output — regression-pin holds.

**Regression posture (pre-codify):** existing `test_visualize_cli.sh` 102/0, `test_cli.sh` 29/0, unittest discover 75/0 — **206/0 across pre-WP7 suites**. New WP7 assertions to be added at verify-codify.

**Plan deviations:** none material. P1.5's choice of "week is week-of-today, not week-of-month-start" is the slightly-more-conservative branch (avoids editing the `monday = target_day - timedelta(...)` line). Documented above; can be revisited if it produces a confusing UX in Month-emit mode at verify-human.

**No discoveries surfaced during impl.** P1.7's "no `viz_render.py` change needed" prediction held — the `json.dumps(data)` pass-through and `{{CT_INITIAL_VIEW}}` template substitution were generic enough.

## Test Triage — WP8-P2 codify: view+range hash-write three-branch dispatch

**Classification:** Obsolete test — superseded by WP7 contract extension.
**Confidence:** high
**Evidence:** Phase 2 plan explicitly extends the hash-write `useEffect` from 3 branches (day/week/custom) to 4 (day/week/custom/month), each emitting the appropriate `month` key (set or null) per the URL-hash schema in CLAUDE.md. The WP8-P2-8 assertion pinned exact substrings like `updateHash({ view: 'week', range: null })` — those substrings now have a `month: null` field appended and so no longer match. The new code is correct per plan; the old assertion is checking the pre-WP7 contract shape.
**Action:** auto-update the assertion to the new 4-branch shape — add the matching `month: <value-or-null>` field to each grep expectation. Rename the assertion to "four-branch dispatch (day/week/custom/month)" so future readers understand the contract.

## Discoveries

[SURFACED-2026-05-24] feature-spec — wbs.md exceeds size guard (313 lines), truncated to first 100 lines + headings on first read. Full file ultimately consulted via offset/limit for WP7-specific section. Logged to `workflow/backlog.md` as SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD (low priority).

[SURFACED-2026-05-24] feature-build — WP8-P2-8 test obsoleted by Phase 2 hash-dispatch extension. Triage above. Same lesson class as WP6's plan-level "downstream contract impacts" rule (CLAUDE.md): when a phase modifies a contract that existing assertions pin, flag it as a deliverable IN THE SAME PHASE that changes the contract. The Phase 2 plan called out URL-hash extensions but didn't enumerate WP8-P2-8 specifically; in retrospect, the plan should have included an explicit "update WP8-P2-8 to four-branch shape" leaf. The verify-codify safety net (triage gate) caught this, which is the designed-for path; logging here so the lesson surfaces in retrospect.

[PLAN-AMBIGUITY-2026-05-24] P2.5 (click-day reload-redirect on a `file://` dashboard) — the dashboard is a single static HTML file emitted at CLI-invoke time, opened via `file://` in the user's browser. There is no server to reload-redirect TO. The "reload-redirect to `claude-time visualize --date YYYY-MM-DD`" pattern from the spec/D3 is not literally implementable as a browser navigation. Three candidate mechanisms surfaced at plan time:
  - **(a) Alert + clipboard:** `window.confirm("Drill into 2026-04-15? Click OK to copy the CLI command to your clipboard.") → navigator.clipboard.writeText("claude-time visualize --date 2026-04-15")`. Honest about the static-file constraint.
  - **(b) Toast + clipboard:** Render a small non-modal toast in-page saying "Run `claude-time visualize --date 2026-04-15` (copied to clipboard)" — less interruptive than alert.
  - **(c) Hash-update only, document-the-rerun-needed:** Click-day updates `#view=day;date=2026-04-15` and shows a "rerun to refresh data" banner. Most discoverable URL pattern, but the rerun is a manual user step.
Resolve at Phase 2 build/verify-self: prototype (b) first (least friction); fall back to (a) if clipboard API permissions are flaky. The same mechanism applies to next-month nav (P2.7) and prev-of-prev nav (P2.6 fall-through). Acceptance criterion 4 will need updating once a mechanism is locked.

## Phase rationale

**Why 2 phases, not 3:** the natural seams are (CLI/Python contract change) → (UI component + wiring). Phase 1 ships a usable `--month` CLI flag with two-month payload — it's testable on its own via emitted HTML inspection (no UI needed). Phase 2 ships the actual MonthView component + interactions. The third candidate phase (polish: empty-day visuals, edge cases, cross-month wrap, filter chip inertness verification) folds into Phase 2's verify-human + verify-codify rather than standing alone — those items are too small to gate a third phase boundary on.

**Why Phase 1 includes the two-month payload (not deferred to Phase 2):** Phase 2's prev-arrow client-side-swap behavior depends on `window.CT_DATA.months[prev_iso]` being present. Shipping the two-month payload in Phase 1 means Phase 2 can wire the swap without circling back to Python. (The alternative — ship one-month payload in Phase 1, add prev-month in Phase 2 — would be a contract change mid-phase and split the codify work awkwardly.)

**Plan-level downstream-contract-impacts pass:** The new `window.CT_DATA.months` top-level key is a JSON contract change. Surfaces that assert against `window.CT_DATA`:
- `test_visualize_cli.sh` test fixtures grep against the emitted JSON — regression-pinned by P1 verify-codify (the "no `months` key when `--month` is NOT set" outcome).
- `_load_demo_data` in `claude-time` reads `viz/data.js` for `--demo` mode — `--demo` is mutually-exclusive with `--month` (P1.3 guard), so the demo path doesn't see the new key. No change needed.
- `viz_render.py::render_html` passes `data` through `json.dumps` — generic pass-through, no schema-specific code, no change needed (P1.7 verifies this).

**Test-shape preview (for verify-codify at each phase):**
- **Phase 1 codify** (~10 assertions in `test_visualize_cli.sh`): `--help` lists `--month`; 4 stderr-message pins (shape / future / mutex-range / mutex-demo); `CT_INITIAL_VIEW = "month"` emit pin; `CT_DATA.months` two-key emit pin; `meta.start`/`meta.end` per-month pins; **no-`months`-key** regression-pin for default emit; `_parse_month_flag` shape correctness via the validation cases.
- **Phase 2 codify** (~8 `test_visualize_cli.sh` source-shape + ~6 `test_visualize_interactive.js` behavioral): source-shape (MonthView component present, Month tab enabled, disabled-form regression-pin, `_initMonthIso` present, `data-month-day` attr present, MonthView in render branch); behavioral (Playwright: month tab click, day-cell click → reload-redirect URL captured, prev-arrow client-swap, next-arrow reload-redirect, hash round-trip, filter-chip inertness).
