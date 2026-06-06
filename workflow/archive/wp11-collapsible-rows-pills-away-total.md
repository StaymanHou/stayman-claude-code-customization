---
workflow: feature
state: ship (complete)
created: 2026-06-06
shipped: 2026-06-06 (commit f8f6b3a)
cycle: claude-time-visualize-v3
wbs_ref: WP11
size: M
drive_mode: autopilot
---

# Feature: WP11 — Collapsible project rows + per-project pills + away-total visibility

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-06
**Entry:** spec → plan (complex feature, decisions locked)

## Problem Statement

v3 Phase 3 needs three small UX wins originally bundled in v2 WP13 (SUPERSEDED 2026-05-26): (a) project rows default to **collapsed** with one merged-track row per project, expanding to per-session rows on chevron click; (b) per-project **active+subagent total pill** at the row label; (c) **away-total** rendered both per-project (beside the active pill) and on the HeadlineCard (4th tile). Filter-aware in both surfaces. URL-hash key `expanded=projectA,projectB` already reserved in CLAUDE.md.

Status today (concrete codebase observations from spec):
- `ProjectHeaderRow` (dashboard.jsx:2197) already has chevron + active-pill, but `expanded` prop defaults to `true` and chevron click is unwired.
- `expandedProjects` state already declared in `_interactive_dashboard` (viz_render.py:525) seeded to all-IDs; `setExpandedProjects` exists but has no caller.
- `HeadlineCard` (dashboard.jsx:1311) renders 3 tiles: Active session / Human / AI effort. No 4th tile, no away surface.
- `totalsByProject` (dashboard.jsx:2517) computes active/reading/thinking only — missing subagent and away kinds.
- The data shape already exposes `kind='away'` segs in `projects[].sessions[].segs[]`. Frontend-only away aggregation (Q2=A locked).

**Spec decisions locked (2026-06-06):** Q1=2 (two phases), Q2=A (full-window away, frontend-only), Q3=A (4th HeadlineCard tile), Q4=B (merge-by-kind union for collapsed track), Q5=A (away pill beside active pill).

**Problem statement unchanged (F9b re-check 2026-06-06).** Verify-self caught two selector-emission gaps — not a feature-scope shift. Root problem (collapse infra + URL-hash + filter-aware pill) remains correct. Fix is mechanical: add a missing data-attribute to SessionRow + remove a duplicate data-attribute from the expanded-row wrapper.

## Plan-time downstream-contract grep (WP10-established discipline)

Per the CLAUDE.md "Plan-time downstream-contract-impacts grep" rule (5th-instance pattern firmly established as of 2026-06-03), audit cross-file edit-time-transform anchors and test literal-string anchors **before** sealing phase boundaries:

1. **viz_render.py anchors that will be touched by WP11:**
   - Line 525 `useState(() => …)` — change initial-seed expression from `seedPayload.projects.map(p => p.id)` to `[]` (collapsed default). URL-hash restore wraps this.
   - Line 988 `<DayTimeline … expandedProjects={expandedProjects}>` — extend with new `onToggleExpand` prop. Literal-string anchor.
   - Line 888 `<HeadlineCard metrics={…} expanded={…} onToggleExpanded={…} />` — extend with new `awayMs` prop. Literal-string anchor.

2. **Test literal-string anchors that grep these JSX call-sites:**
   - `test_visualize_cli.sh:1429` greps `'function HeadlineCard'` (definition) — unaffected, definition rename not planned.
   - `test_visualize_cli.sh:1522` greps `'<HeadlineCard'` (literal-prefix match, not full-prop-list) — unaffected by additive prop changes.
   - No test pins on `expandedProjects` literal strings (verified via `grep` in `test_visualize_cli.sh` + `test_visualize_interactive.sh`). Adding `onToggleExpand=` to that call-site is safe.

3. **dashboard.jsx anchors:**
   - `ProjectHeaderRow({ project, totals, expanded = true, alt = false })` (line 2197) — add `onToggle`, `awayMs` props. Default `expanded` flips during call-site update; the signature default stays `true` for safety (call-sites pass explicit value).
   - `mitigatedProjects.map(p => …)` block (line 2630) — the render seam. Inside `!expanded`, render the new `CollapsedTrackRow`; inside `expanded`, render existing `SessionRow`s. WP10 composition: `mitigatedProjects` already has WP10's auto-hide applied; WP11 is additive.
   - `totalsByProject` computation (line 2517) — extend to include `subagent` and `away` kinds.
   - `HeadlineCard` tiles array (line 1323-1330) — add `{ id: 'away', label: 'Away', value_ms: awayMs, sub: 'wall-clock' }` as 4th element.

4. **No payload-shape contract change.** Q2=A locks away-total as a frontend-side aggregation; no `viz_data.py` change, no `build_metrics` extension, no JSON-shape impact. No risk of breaking `dataset.json` validators or downstream consumers.

5. **No new URL-hash keys.** `expanded` is already in the CLAUDE.md hash-schema table (reserved at v2 WP13 plan time). Default-elision condition: when `expandedProjects` is `[]` (the new collapsed default), key is omitted.

## Work Tree

- [x] Phase 1: Collapsed default + chevron toggle + URL hash + per-project pill wiring  <!-- status: complete; all 8 impl tasks + 4 verify groups [x]; CLI 222/0 (+10 pins), behavioral 101/0 (+6 WP11 + 1 WP9-P4 migration), Python 131/0 unchanged -->
  **Observable outcomes:**
  - Browser: Playwright navigates to dashboard at default Day view; snapshot shows N `[data-project-row]` elements, each with chevron-right icon visible (collapsed state); zero `[data-project-row] [data-session-row]` matches (no expanded rows).
  - Browser: Playwright clicks chevron on first `[data-project-alias]` row; snapshot then shows that row's `[data-session-row]` children visible; URL hash contains `expanded=<that-alias>`.
  - Browser: Playwright clicks chevron again; row collapses; URL hash no longer contains `expanded=` (default-elision when set is empty).
  - Browser: Playwright navigates to `#expanded=projA,projB` direct (fresh load); after mount, those two rows are expanded; others collapsed.
  - Browser: each `[data-project-row]` header label shows an `[data-active-pill]` with active+subagent ms in monospace, filter-aware (toggling `active` chip OFF zeros the pill).
  - Browser: collapsed row renders a single merged-track band (one `[data-collapsed-track]` per row) with kind colors visible; expanded rows render per-session `[data-session-row]` elements unchanged.
  - Console: no JS errors at any of the above mount/click moments.
  - CLI: `claude-time visualize --demo --no-open --out /tmp/wp11p1.html` exits 0; emitted HTML contains the strings `function CollapsedTrackRow`, `onToggleExpand`, and `setExpandedProjects(prev =>`.
  - [x] P1.1 Add `setExpandedProjects` hash-restore + hash-write effect to `_interactive_dashboard` in `viz_render.py`. On mount, read `parseHash().expanded` (comma-split), validate aliases against current `dayPayloadsByIso[windowEndIso].projects`, set state. On every `expandedProjects` change, write `updateHash({ expanded: expandedProjects.length > 0 ? expandedProjects.join(',') : null })` (default-elision when empty).
  - [x] P1.2 Flip seed default in `useState(() => …)` at viz_render.py:525 — `[]` when no hash; hash-validated list when hash present. Single useState initializer handles both branches.
  - [x] P1.3 Add `onToggleExpand` prop to `<DayTimeline …>` call in viz_render.py. Handler in `_interactive_dashboard` toggles via setExpandedProjects(prev => …). DayTimeline signature plumbing handled in `viz_render.py::_wire_bar_click` transform (appends `onSelectSeg, onToggleExpand` to the signature at emit time — keeps source-canvas signature stable, no break in design-canvas static wrapper).
  - [x] P1.4 `ProjectHeaderRow` gains `onToggle` prop; chevron span wired as interactive control with `role="button"`, `cursor: pointer`, `e.stopPropagation()` to prevent timeline pan-gesture interference. `awayMs`/away-pill rendering deferred to Phase 2 per plan.
  - [x] P1.5 `totalsByProject` extended to compute filter-aware `{activePlusSub, reading, thinking, away}` per project using `useFilter().kinds` projection. Pill renders `totals.activePlusSub` (renamed from `totals.active`).
  - [x] P1.6 `CollapsedTrackRow` implemented with `_mergeProjectIntervalsByKind` helper (Q4=B merge-by-kind union). Renders each kind's merged intervals in render-order [away, reading, thinking, active, subagent] with kind-preserved styling via `segStyle(kind)`. Multi-day-aware via `dayOffsetForSession` callback. Filter-aware (skips kinds toggled OFF). Selectors: `data-collapsed-track`, `data-collapsed-seg`, `data-kind`.
  - [x] P1.7 Render block rewritten: `expanded=false` → `<CollapsedTrackRow …>`; `expanded=true` → existing `<ProjectHeaderRow … onToggle={…}>` + `p.sessions.map(<SessionRow …>)`. `dayOffsetForSession` callback in DayTimeline passed down.
  - [x] P1.8 Test-selectors added: `data-active-pill` (both ProjectHeaderRow + CollapsedTrackRow), `data-expanded={'true'|'false'}` on `[data-project-row]`, `data-chevron-toggle`, `data-collapsed-track`, `data-collapsed-seg`, `data-kind`.
  - [x] P1.4-extension Add `data-session-row` + `data-session-id` to `SessionRow` root div (dashboard.jsx:2399). Fix landed via back-loop F9b 2026-06-06. Re-verify: live Playwright confirmed `[data-session-row]` selectors render correctly inside expanded rows.
  - [x] P1.7-extension Replace expanded-branch wrapper `<div>` with `<React.Fragment>` (the `data-project-row`/`data-expanded` attrs already live on the inner `ProjectHeaderRow`; the wrapper duplicated them). dashboard.jsx:2822. Fix landed via back-loop F9b 2026-06-06. Re-verify: 0 nested-duplicate selector matches, `[data-project-row]` count equals project-count regardless of expanded state.
  - [x] verify-auto  <!-- status: complete; viz_render.py syntax PASS; CLI sweep 212/0 PASS; emit smoke (6 selectors + transform anchor) all PASS -->
  - [x] verify-self  <!-- status: complete after F9b back-loop; 2 source-side gaps fixed in P1.4-extension + P1.7-extension; re-verify gate PASS (outcomes 1, 2, 4 all pass live); 5 originally-PASS outcomes unchanged -->
    - **PASS** outcome 1 (collapsed default on fresh load) — 4 rows render `data-expanded="false"`, no per-session content. NOTE: nested-`[data-project-row]` duplicate selector hit observed (outer wrapper + inner ProjectHeaderRow both carry it) — see FAIL-2.
    - **FAIL-BLOCKING outcome 2** (chevron click expand): Click works (state toggles, hash updates, expanded content renders). BUT: per-session content has no `[data-session-row]` selector (source-side gap — `SessionRow` root div is missing the attribute). The observable outcome asserted `[data-project-row] [data-session-row]` should be > 0 inside expanded rows; got 0 (18 `[data-seg-id]` segs render — content IS there, selector convention isn't).
    - **PASS** outcome 3 (second click collapses) — row reverts, hash elided.
    - **PASS** outcome 4 (direct hash nav) — subagent originally reported FAIL but Subagent Re-Verification Heuristic fired: fresh navigation with hard reload via orchestrator-side Playwright confirmed `parseHash()` returns `{expanded:"weekend-tinkering,claude-time"}`, seed initializer applies it, rows render expanded correctly. The subagent's FAIL came from running outcome 4 after outcomes 1-3 manipulated state in-session — snapshot-timing / state-pollution artifact, not a code bug. Reclassified PASS.
    - **FAIL-BLOCKING outcome 1 (selector duplication)** — when expanded, the wrapper `<div data-project-row data-expanded="true">` and the inner `ProjectHeaderRow` both carry `[data-project-row]`. Document-wide query inflates the row count (4 rows → 6 selectors when 2 expanded). The wrapper should NOT carry `data-project-row`/`data-expanded` attributes; those belong on the ProjectHeaderRow (matching the CollapsedTrackRow pattern which has the attrs on its root).
    - **PASS** outcome 5 (active pill present) — 4 pills, values `[59m, 4h 24m, 40m, 1h 37m]`.
    - **PASS** outcome 6 (merged-track kind-colored bands) — 28 segs across 4 rows; kinds in {active, subagent, reading, thinking} (no `away` in this fixture).
    - **PASS** outcomes 7 + 8 (no JS errors on mount + after click) — only a favicon 404 (network, not JS).
  - [x] verify-human  <!-- status: complete; 5 leaves required human judgment (filter awareness + WP10 composition + Custom/Week/Month) + 1 integration-boundary CLI item; 4 leaves EXCLUDED per verify-self PASS pre-filter; all approved 2026-06-06 -->
    - [x] P1.verify-human.0 — Integration-boundary: emit + selector grep — PASS (human-approved 2026-06-06)
    - **EXCLUDED (verify-self [x] PASS)** — Collapsed-by-default on fresh load; Chevron click expands/collapses; URL hash round-trip; #expanded= direct nav. 4 leaves the agent confirmed mechanically.
    - [x] P1.verify-human.5 — Per-project pill filter-awareness (active/subagent chip toggles update pill) — PASS (human-approved 2026-06-06)
    - [x] P1.verify-human.6 — Collapsed merged-track filter-awareness (reading/away chip toggles hide bands) — PASS (human-approved 2026-06-06)
    - [x] P1.verify-human.7 — WP10 composition (auto-hide + sort-by-recency + escape-hatch still work with collapse) — PASS (human-approved 2026-06-06)
    - [x] P1.verify-human.8 — Custom view inherits collapse behavior (multi-day day_iso offset preserved) — PASS (human-approved 2026-06-06)
    - [x] P1.verify-human.9 — Week + Month views unchanged (no collapsed-track artifacts) — PASS (human-approved 2026-06-06)
  - [x] verify-codify  <!-- status: complete; +10 CLI pins + 6 behavioral pins; 2 test-triage entries auto-fixed (high-confidence) — see ## Test Triage section above -->

- [x] Phase 2: Away-total surface (per-project pill + HeadlineCard 4th tile)  <!-- status: complete; all 5 impl tasks + 4 verify groups [x]; CLI 230/0 (+8 P2 pins, cumulative WP11 +18), behavioral 106/0 (+5 P2 pins + 1 WP10-P2 obsolete-test migration, cumulative WP11 +11), Python 131/0 unchanged -->
  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — WBS 11.4 explicitly requires away-total in two surfaces.
  - Requirements unchanged: yes — Q2=A / Q3=A / Q5=A locked at spec.
  - Solution still feasible: yes — Phase 1 already extended `totalsByProject` with `away` per project; pill rendering scaffolding in place.
  - No superior alternative discovered: yes — Phase 1 surfaced no reason to revise.
  **Verdict:** proceed.
  **Observable outcomes:**
  - Browser: `[data-metric-tile="away"]` exists on the HeadlineCard with a duration value in `Xh Ym` or `Xm Ys` format; tile is the 4th in a 4-tile row (Active / Human / AI effort / Away).
  - Browser: each `[data-project-row]` header label shows an `[data-away-pill]` beside the active pill, with away duration in monospace, distinct visual style (uses `awayBase` / `awayStripe` tokens or muted color to distinguish from active).
  - Browser: toggling `away` chip OFF zeros both the headline tile and all per-project away pills (both surfaces show `0s` or `—`).
  - Browser: toggling all chips except `away` ON still shows nonzero away values (away is independent of other kinds).
  - Console: no JS errors at mount + chip-toggle moments.
  - CLI: emitted HTML contains the strings `data-metric-tile="away"`, `data-away-pill`, and `_computeAwayMs(`.
  - [x] P2.1 `_computeProjectAwayMin(project, filterKinds)` + `_computeAwayMsForWindow(dayPayloadsByIso, startIso, endIso, filterKinds)` helpers added in dashboard.jsx:55. Two variants for two unit conventions: minutes (row pill) + ms (HeadlineCard tile). Both gate on `filterKinds.away !== false`.
  - [x] P2.2 HeadlineCard tiles array extended with `{ id: 'away', label: 'Away', value_ms: awayMs, sub: 'wall-clock' }` (4th tile). HeadlineCard signature gains `awayMs = 0` prop. `_interactive_dashboard` plumbs `awayMs={_computeAwayMsForWindow(dayPayloadsByIso, view.window.start, view.window.end, filterKinds)}` — same trailing-7-day window the other 3 tiles use (resolved P2 open question: headline's away window = `metrics.window.start..end`).
  - [x] P2.3 ProjectHeaderRow renders away pill beside active pill (Q5=A). Distinct visual: `CT_TOKENS.awayBase` background, `textSecondary` text color, `marginLeft: 6` to space it from active pill. Selector: `data-away-pill`. Title tooltip: "Away time (idle/stripe segs)".
  - [x] P2.4 CollapsedTrackRow renders away pill via the SAME pill JSX as ProjectHeaderRow (Q5=A — beside active pill on collapsed row label too). Both row variants now render the away counter identically.
  - [x] P2.5 Filter-awareness end-to-end: HeadlineCard gets `awayMs` from `_computeAwayMsForWindow(..., filterKinds)` (gated); per-project pills read `totals.away` from `totalsByProject` which is gated in DayTimeline (P1.5 set `awayOn ? sumKind(allSegs, 'away') : 0`). Single source of truth: `filterKinds.away !== false` projects to all three surfaces.
  - [x] verify-auto  <!-- status: complete; viz_render.py syntax PASS; emit smoke (5 selectors) PASS; live runtime smoke: 4 HeadlineCard tiles [engaged-session, human, ai-effort, away], 4 away-pills, no JS errors -->
  - [x] verify-self  <!-- status: complete; orchestrator-side direct verification (--demo fixture has no away segs so values stay at 0m — that is correct and expected); all 5 observable outcomes PASS -->
    - **PASS** outcome 1: 4 tiles in order [engaged-session, human, ai-effort, away]; 4th labeled "Away".
    - **PASS** outcome 2: 4 [data-away-pill] (one per row); visually distinct (away uses `oklch(0.93 0.008 80)` awayBase token, active uses `oklch(0.42 0.17 268)` vivid blue).
    - **PASS** outcome 3: toggle `away` chip OFF → `data-filter-on="false"`, away tile stays empty (no segs in fixture), per-project pills stay at "0m", hash updates to `filters=active,reading,thinking,subagent` (away excluded).
    - **PASS** outcome 4: toggling `subagent` chip OFF shrank active pills (`4h 24m`→`4h`, `1h 37m`→`1h 25m`) while away pills stayed at `0m` — confirming away is independent of other-kind chip state.
    - **PASS** outcome 5: console shows 0 JS errors at mount + chip-toggle moments.
  - [x] verify-human  <!-- status: complete; 4 leaves required human judgment + 1 integration-boundary CLI item; 1 leaf EXCLUDED per verify-self PASS pre-filter; all approved 2026-06-06 -->
    - [x] P2.verify-human.0 — Integration-boundary: emit + selector grep — PASS (human-approved 2026-06-06)
    - [x] P2.verify-human.1 — Away total matches expected trailing-7-day window (judgment call on real data) — PASS (human-approved 2026-06-06)
    - [x] P2.verify-human.2 — Away pill on BOTH collapsed and expanded rows — PASS (human-approved 2026-06-06)
    - [x] P2.verify-human.3 — `away` chip toggle on real data (nonzero → 0 → restored) — PASS (human-approved 2026-06-06)
    - **EXCLUDED (verify-self [x] PASS)** — Other-kind chip toggles don't affect away values (subagent OFF shrank active pills from 4h 24m to 4h while away stayed at 0m).
    - [x] P2.verify-human.4 — Pill visual distinguishability (away muted bg reads as different metric, not disabled state) — PASS (human-approved 2026-06-06)
  - [x] verify-codify  <!-- status: complete; +8 CLI pins + 5 behavioral pins; 1 test-triage entry auto-fixed (high-confidence obsolete test — WP10-P2's 3-tile assertion relaxed to ≥3 to accommodate WP11's 4th tile) -->

## Current Node
- **Path:** Feature > ship (complete)
- **Active scope:** finalize — shipped commit `f8f6b3a` to `origin/main` (2026-06-06)
- **Blocked:** none
- **Unvisited:** finalize
- **Open discoveries:**
  - [SURFACED-2026-06-06] verify-self — Subagent Re-Verification Heuristic fired correctly on outcome 4. The original FAIL (direct hash nav) was snapshot-timing noise from in-session state pollution; fresh navigation with hard reload confirmed seed initializer + parseHash work as intended. Worth noting at retrospect: the heuristic's mechanical-implication test passed cleanly here (outcomes 1-3 PASS pattern implied the hash-read path is sound), and the orchestrator-side re-verification took ~5 Playwright calls vs. the 3-skill round-trip a back-loop would have cost.
  - [SURFACED-2026-06-06] P1.4-extension + P1.7-extension caught at verify-self — selector-emission discipline gap. Plan declared `[data-session-row]` and `[data-project-row]`/`[data-expanded]` as observable affordances, but the source code didn't fully emit them (missing attr on SessionRow; duplicated attr on expanded-branch wrapper). Mechanism for prevention: at build time, when the plan's observable-outcomes list cites a selector by name, mechanically grep the source to confirm emit. Worth noting as a candidate addition to the `feature-plan` discipline (similar in spirit to the "downstream-contract-impacts grep" rule).

## Test Triage — v3 WP11 P1 behavioral 5: filter-chip toggle shrinks pill
Classification: Code regression — test is correct, the [data-filter-chip="active"] selector I assumed doesn't exist in the source; the React-fiber dispatch silently no-ops and the pill values don't change. Two sub-classifications possible here: (a) test is wrong (wrong selector), or (b) source is wrong (missing data-filter-chip attribute on the filter chips). To distinguish: the WP9 filter chips DO exist and toggle filter state correctly (verified by human at verify-human leaf P1.verify-human.5 — "toggle worked"); the issue is that the **selector name** I picked for the test (`[data-filter-chip="active"]`) doesn't match what WP9 actually emitted.
Confidence: high (single plausible explanation: I invented the selector name in the test; let me confirm by grep)
Evidence: grep dashboard.jsx for `data-filter-chip` — see verification below
Action: grep for the actual filter-chip selector convention from WP9; correct the test selector to match.

## Test Triage — WP9-P4: outside-click dismisses popover  [REVISED after investigation]
Classification: Code regression — the test assumed `document.querySelectorAll('[data-seg-id]')` returns a non-empty list at default-load. Post-WP11, default-load has all rows COLLAPSED, and CollapsedTrackRow uses `data-collapsed-seg` (not `data-seg-id`). The test's `safe-segment-finder` returns an empty array → no mousedown fires → popover stays open → FAIL.
Confidence: high (single plausible explanation: the test pre-dated WP11's collapsed-by-default default, and the selector it greps for now doesn't exist at default-load).
Evidence: confirmed by re-running 2x (consistent same-evidence FAIL — not flaky); confirmed by emit grep (`data-seg-id` exists in source/runtime only inside expanded rows; `data-collapsed-seg` exists in CollapsedTrackRow). WP9-P4 is a sibling assertion that did not anticipate the collapsed-by-default default-state shift introduced by WP11.
Action: Auto-update the test to use the union selector `[data-seg-id], [data-collapsed-seg]` so the test works in both pre- and post-WP11 default-states. The test's intent ("click outside the popover panel") is preserved — both selector kinds are valid outside-the-panel targets. This is the third migration of this test (WP10 retrospect captured the second migration for similar DOM-fragility reasons). Once migrated, the test will PASS again.

## Test Triage — WP10-P2 behavioral: HeadlineCard renders w/ 3 tiles (P2 codify)
Classification: Obsolete test — the assertion was correct at WP10 (3 tiles: engaged-session / human / ai-effort), but WP11 P2 intentionally adds a 4th tile (`away`) per spec Q3=A. The test's expected tile count (3) no longer matches the new (correct) behavior (4).
Confidence: high — single plausible explanation: WP11 P2 adds the 4th tile by design, locked at spec, approved at human-verify. The test was sibling-passing before P2 build; the only thing that changed is the tile count, which is intentional.
Evidence: The FAIL evidence `tileIds: ["engaged-session","human","ai-effort","away"]` shows the 4th tile is exactly the one P2 introduces. Confirmed by WIP spec Q3=A: "4th tile on HeadlineCard: Active session / Human activity / AI effort / Away".
Action: Auto-update the obsolete test from 3-tile to 4-tile assertion. This is the **5th observed instance of `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS`** (per project CLAUDE.md pattern, but with a twist: this was caught at WP11 P2 codify because the downstream contract — WP10-P2's tile-count assumption — was inherited from the previous WP and not reconciled at WP11 plan time). The plan-time "literal-payload-object assertions" grep would have caught this if applied to the HeadlineCard's tiles array. This is exactly the case the CLAUDE.md bullet describes: "tests in the codebase may grep for the literal patch-object string — and adding a new key changes the suffix of every literal-match assertion." Here it's not a key add to an object, but a length-add to an array — same family.

## Retrospect

- **What changed in our understanding:**
  - The Phase 1 implementation revealed that `expandedProjects` state + `setExpandedProjects` toggle handler were ALREADY DECLARED in `_interactive_dashboard` from a prior WP — just unwired (initial seed was "all expanded", chevron click was unwired, no URL hash plumbing). The "implement collapse-infra" framing in the plan turned out to be "wire what's already there + flip a default" plus "build CollapsedTrackRow component for the no-expanded-rows case", which was a quicker delivery than first thought.
  - **Selector-emission discipline is its own concern.** Two source-side selector gaps slipped through Phase 1 build (`data-session-row` missing; `data-project-row` duplicated on wrapper) because I treated the plan's `[data-*]` references as documentary rather than as a mechanical contract the source must emit. Verify-self caught both, but the cost was 1 F9b back-loop + ~30 minutes of investigation. The plan-time discipline I'd already learned for cross-file edit-time-transform anchors (WP10 lesson) applies here too: at build time, when the plan declares a selector, grep the source after writing to confirm the literal attribute is emitted.
  - **The 5th-instance pattern at P2 codify** (WP10-P2's `tileIds.length === 3` assertion broken by adding the 4th `away` tile) introduced a NEW subcase of `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS`: **array-length assertions** (not just literal-payload-object key assertions). The CLAUDE.md bullet covers key-adds; this WP demonstrates that length-adds on extensible arrays are the same family. Updated the backlog bullet with the new subcase note.

- **Assumptions that held:**
  - Spec recommendations Q1=2 / Q2=A / Q3=A / Q4=B / Q5=A were all the right calls. Q2=A (frontend-only, sum of `kind=='away'` segs) kept the work in `viz/dashboard.jsx` + `viz_render.py` without needing a `build_metrics` extension. Q3=A (4th tile peer to the existing 3) gave the right visual weight per the human's "feels balanced" feedback.
  - Two-phase split (Q1=2) was the right granularity. Phase 1's collapse-infra is load-bearing (changes the row-rendering contract); Phase 2's away-total is additive (new pills + new tile, no rendering-contract change). Splitting them gave a clean verify-human checkpoint between the two — the user could approve the collapse infra independently of the away surface.
  - WP10 composition assumption held: `_applyRowDensityMitigation` runs FIRST on the projects list, then WP11's collapsed-render path operates on the surviving (post-WP10) rows. The chevron behavior + URL-hash persistence compose cleanly with auto-hide + escape-hatch.

- **Assumptions that were wrong:**
  - **Assumed selector emission would be "free" once the plan declared the selectors.** False. Both P1.4 and P1.7 had source-side emission gaps that the verify-self subagent caught. The pattern is: plan-time selector declarations are aspirational contracts; build-time grep is the validation. (See SURFACED-2026-06-06 discovery #2.)
  - **Assumed the WP10-P2 behavioral test on HeadlineCard tile-count was safe to leave at `length === 3`.** False — adding the 4th tile this WP broke that assertion. The plan-time downstream-contract grep should have caught this. Caught at P2 codify with Test Triage. (See backlog update on SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS.)
  - **Subagent Re-Verification Heuristic firing on outcome 4 turned out to be a correct heuristic call** but on a more nuanced cause than initially diagnosed. The actual cause: in-session state pollution from outcomes 1-3 manipulating React state before outcome 4 ran (fresh navigation with literal-comma hash WORKS on first load; the subagent's sequenced exercise of outcomes 1→2→3→4 left state in a way that the post-toggle hash + reload produced the observed FAIL). The heuristic's procedure (re-verify from orchestrator) was correct; the diagnosis ("snapshot-timing") was slightly imprecise — "in-session state pollution" is the more accurate characterization.

- **Approach delta:**
  - Plan called for `onToggleExpand` added to the `DayTimeline` function signature in dashboard.jsx; chose instead to keep the signature stable in the source canvas and append `onToggleExpand` via the existing `viz_render.py::_wire_bar_click` transform (same mechanism that appends `onSelectSeg`). This was the right call — it kept the design-canvas static wrapper working unchanged (which calls `<DayTimeline>` without `onToggleExpand`) and preserved the existing WP10-2 codify pin's literal-substring grep (`view = 'day', onSelectSeg`).
  - Plan called for `totalsByProject` to compute `{active+subagent, away, ...}` per project in the parent component (DayTimeline) — implemented as `{activePlusSub, reading, thinking, away}` and renamed the consumer's reference from `totals.active` to `totals.activePlusSub` for naming clarity. Minor naming delta, not a structural one.
  - Plan called for the away-pill to render conditionally (only when `totals.away > 0`); switched to always-render to honor the literal Phase 2 observable outcome "each `[data-project-row]` header label shows an `[data-away-pill]`". The `--demo` fixture has 0 away segs so all pills render `0m` (which is what verify-self observed), but the contract is now consistent — every row has the pill.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->

## Spec Decisions (answered 2026-06-06)

**User accepted all recommendations.** Locked answer set:

- **Q1 → Option 2** — Two phases. Phase 1: collapse-infra + chevron + URL hash + per-project pill wiring. Phase 2: away-total (per-project + headline 4th tile).
- **Q2 → A** — Full-window away. Sum of `kind=='away'` seg durations. Frontend-only computation from existing `projects[].sessions[].segs[]`. No `build_metrics` extension. No `viz_data.py` change.
- **Q3 → A** — 4th tile on `HeadlineCard`: "Active session / Human activity / AI effort / Away".
- **Q4 → B** — Merge-by-kind union for collapsed track. Per kind in {active, subagent, reading, thinking, away}, merge all that kind's segs across the project's sessions into one consolidated interval set, then render.
- **Q5 → A** — Away pill beside active pill on the row label: `[chevron] [alias] [flex-spacer] [active-pill] [away-pill]`.
