---
workflow: feature
state: ship (complete)
created: 2026-05-23
shipped: 2026-05-23
ship_commit: f5a1123
cycle: claude-time-visualize-v2
wbs_row: WP9
size: S
drive_mode: autopilot
---

# Feature: WP9 — Interactive filter chips (+ duality collapse)

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-23

## Problem Statement

WBS WP9 makes the toolbar filter chips ("active", "reading", "thinking", "away", "subagent") functional toggles — off-state hides that segment kind across all consumers (timeline bars, per-row totals, headline stats once WP10/11 ship). State persists in the URL hash (`filters=active,subagent`). A per-project filter popover toggles individual projects on/off.

The user-selected resolution for `SURFACE-2026-05-23-CLAUDE-TIME-VIZ-DESIGN-CANVAS-INTERACTIVE-TOOLBAR-DUALITY` is **option (a) — collapse the duality**: merge `viz_render.py::InteractiveToolbar` and supporting transforms into `viz/dashboard.jsx::Toolbar`, delete the static design-canvas Toolbar prototype, and simplify the emit path. This sits as Phase 1 *before* the filter-chip implementation so Phase 2 can land filter logic in one canonical Toolbar instead of perpetuating the two-file split. After Phase 1, all toolbar-touching WPs (WP9 here, WP10/12 next) edit one file.

**Scope locks:**
- Phase 1 is mechanical refactor only — no UI changes, no new features. Emitted HTML must be byte-identical (or trivially equivalent — whitespace/comment-level diffs only) to pre-Phase-1 emit. This is the safety harness for the move.
- Phase 1 does **not** touch `viz/design-canvas.jsx` (still byte-pinned by `tests/check-structure.sh` Phase 5c, remains a reference artifact). Only `viz/dashboard.jsx::Toolbar` and `viz_render.py::InteractiveToolbar` are in scope.
- The `viz_render.py::_strip_design_wrapper` transform continues to strip the design-canvas `Dashboard({variant})` wrapper at the bottom of `dashboard.jsx` (lines ~1569–1695). The shipped `Dashboard()` wrapper still appends from `_interactive_dashboard()`. Phase 1 only collapses the *Toolbar* component, not the entire Dashboard transform stack.

## Work Tree

- [x] Phase 1: Collapse Toolbar duality (option a)  <!-- status: [x] — all leaves complete -->
  **Observable outcomes:**
  - CLI: `tools/claude-time/claude-time visualize --demo --no-open --out /tmp/wp9-p1.html` exits 0 and writes file
  - HTML: emitted `/tmp/wp9-p1.html` contains exactly one Toolbar function definition (grep `^function Toolbar\b|^function InteractiveToolbar\b` returns exactly one match)
  - HTML: emitted file's shipped Dashboard wrapper renders `<Toolbar ...>` (not `<InteractiveToolbar ...>`)
  - HTML: emitted file contains `View tabs` Day/Week button labels, `snapshot:` caption when applicable, refresh tooltip — same visible toolbar surface as pre-Phase-1
  - CLI: `bash tools/claude-time/test/test_visualize_cli.sh` passes 62/62 (no regression vs WP6 baseline)
  - CLI: `bash tests/check-structure.sh` passes (Phase 5c byte-pin on `index.html` + `design-canvas.jsx` still holds; `dashboard.jsx` editable check still passes)
  - [x] P1.1 Replaced the static `Toolbar({activeRange, activeZoom, dateLabel, dark})` in `viz/dashboard.jsx` (lines 107–199) with the interactive variant (props: `{view, onViewChange, dateLabel, snapshot}`). Body moved verbatim from `viz_render.py::InteractiveToolbar`. Header comment block records WP9 history.  <!-- status: [x] -->
  - [x] P1.2 Updated the design-canvas `Dashboard({variant})` wrapper's `<Toolbar ...>` call (dashboard.jsx ~1635) to the new prop shape: `<Toolbar view={isDay ? 'day' : 'week'} onViewChange={() => {}} dateLabel={...} />`. Design-canvas page still works as a no-op pass-through reference.  <!-- status: [x] -->
  - [x] P1.3 Deleted `_interactive_dashboard()`'s embedded `function InteractiveToolbar(...)` block from `viz_render.py`. Rewired shipped Dashboard wrapper JSX to render `<Toolbar view={view} onViewChange={setView} dateLabel={...} snapshot={...} />`. `_strip_design_wrapper` + `_wire_bar_click` + `_add_interrupt_hairlines` transforms unchanged.  <!-- status: [x] -->
  - [x] P1.4 Updated `viz_render.py` module docstring: removed the toolbar-transform bullet (no longer a transform; it's a `dashboard.jsx` consumer). Added WP9 collapse note at the end of the historical-context paragraph.  <!-- status: [x] -->
  - [x] P1.5 Appended WP9 postscript to CLAUDE.md "Design-as-data" convention bullet, recording the collapse rationale and the remaining design-canvas pass-through.  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — viz_render.py py_compile PASS; check-structure.sh 121/1 (FAIL = pre-existing settings-fixture drift SURFACE-2026-05-18, confirmed baseline-identical); emit smoke: 1 Toolbar fn / 1 <Toolbar> usage / 0 <InteractiveToolbar> / snapshot+tabs+refresh-tooltip all present -->
  - [x] verify-self  <!-- status: [x] — 8/8 browser outcomes PASS via Playwright subagent on file:///tmp/wp9-p1-verify.html: dashboard loads, wordmark+icon present, Day/Week/Month/Custom tabs with correct active/disabled states, date label, snapshot caption ("snapshot: 16:43"), refresh button with correct tooltip, Day↔Week tab switching works with full body content change, zero JS console errors (favicon 404 ignored as non-runtime static asset) -->
  - [x] verify-human  <!-- status: [x] — user-approved 2026-05-23 -->
    - [x] P1.verify-human.1 Visual fidelity vs. pre-WP9 shipped dashboard — user confirmed indistinguishable. (Originally specced as "Toolbar renders identically" + "Week tab click switches view"; both subsumed by verify-self subagent's 8/8 PASS, so reduced to single visual-fidelity judgment call per pre-filter rule.)  <!-- status: [x] -->
  - [x] verify-codify  <!-- status: [x] — added 2 regression-pins to test_visualize_cli.sh (62→64 PASS): (1) exactly 1 Toolbar function in emitted HTML (positive structural pin); (2) zero <InteractiveToolbar> JSX usages (negative pin). Both PASS. Cross-suite: test_viz_data.py 40/40, test_cli.sh 29/29, test_visualize_cli.sh 64/64 — total 133/133, no regression. -->

- [x] Phase 2: Filter chip state + segment gating  <!-- status: [x] — all leaves complete -->
  **Observable outcomes:**
  - Browser: emitted dashboard has clickable filter chips for each kind (active, reading, thinking, away, subagent). Click toggles chip visual state (active ↔ dimmed-with-strikethrough or similar).
  - Browser: clicking "reading" chip OFF hides reading-kind segments in all `SegmentBar` instances across visible sessions (Playwright snapshot: `.seg-bar[data-kind="reading"]` count goes from N>0 to 0 after click).
  - Browser: per-row totals in `SessionRow` recompute when filter changes (the small "Nh Mm" label per session reflects only enabled kinds).
  - HTML: emitted JS contains `useState` for filter state, default = all kinds enabled.
  - CLI: `test_visualize_cli.sh` passes (no regression).
  - [x] P2.1 Added `data-kind={seg.kind}` attribute to `SegmentBar`'s root div in `viz/dashboard.jsx`. Stable Playwright selector for filter assertions.  <!-- status: [x] -->
  - [x] P2.2 Added `FilterContext` next to `ViewportContext`/`DataWindowContext` in `dashboard.jsx` (default: all kinds ON, no-op setter — design-canvas page still renders as before). Added `filterKinds`/`filterProjects` useState pair to the shipped Dashboard wrapper in `viz_render.py::_interactive_dashboard()`, plus a memoized `filterCtxValue` and a `<FilterContext.Provider>` wrapping the existing `<ViewportContext.Provider>` tree. Phase-3 URL-hash restore deferred to Phase 3 as planned.  <!-- status: [x] -->
  - [x] P2.3 **Plan deviation (documented):** The plan said "in Toolbar" but the canonical surface for kind-chip toggling is the existing `<Legend />` component (already in the date-header strip with all 5 kinds + color swatches in the right order). Upgraded Legend in-place to functional clickable chips with `data-filter-kind=<kind>` + `data-filter-on=true|false` attrs, reduced-opacity + strikethrough on OFF state, title-tooltip "Hide X" / "Show X". Toolbar untouched (kept clean for date controls + view tabs).  <!-- status: [x] -->
  - [x] P2.4 `SegmentBar` reads `useFilter()` hook; if `filterKinds[seg.kind] === false` → returns null. Per-segment hide preserves layout stability (other kinds' positions unchanged).  <!-- status: [x] -->
  - [x] P2.5 `SessionRow.totalActive` made filter-aware: passes `session.segs.filter(s => filterKinds[s.kind] !== false)` to `sumActive`. When user toggles active/subagent OFF, the visible per-session total label drops accordingly. (Note: design-canvas `Dashboard({variant})` wrapper has its own `totalActive` at line ~1485, unchanged — it's stripped at emit.)  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — py_compile viz_render.py PASS; emit smoke: data-kind=1, data-filter-kind=1, FilterContext=7 refs, useFilter()=4 calls, filterKinds=9 mentions, Phase 1 regression-pins still hold (1 Toolbar fn, 0 <InteractiveToolbar>); test_visualize_cli.sh 64/64 PASS unchanged from Phase 1 baseline -->
  - [ ] **DISCOVERY** P2.disc.1 `viz_render.py::_strip_design_wrapper` had a latent fragility — its strict marker (literal `/* ── Dashboard wrapper ──...── */` with hardcoded dash-count) didn't match the source (whose dash-count had drifted historically), so it always fell through to a naive `find("Dashboard wrapper")` substring match. My P2.3 Legend comment legitimately mentioned "Dashboard wrapper" in prose, producing a false-first match that stripped the whole file body. Fixed in-phase: strict matcher rewritten as a regex `/\* ─{2,} Dashboard wrapper ─{2,} \*/` (dash-count tolerant); fallback removed; rationale captured inline. No backlog SURFACE needed — self-contained mitigation with regression coverage at verify-codify (P5.1's structural Toolbar-count pin would catch the strip-misfire as a side effect).  <!-- status: [x] -->
  - [x] verify-self  <!-- status: [x] — 10/10 PASS via Playwright subagent on file:///tmp/wp9-p2-verify.html: 5 chips present, all start ON, click reading OFF → chip data-filter-on='false' + opacity 0.45 + strikethrough + 6 reading segments hidden (others unchanged at active=16/thinking=4/subagent=2), toggle ON restores fully. Per-row totals: toggling subagent OFF dropped row[5] by 24m (segment 734-758) and row[9] by 12m (segment 920-932), all other rows unchanged. Week/Day tab switching unaffected. Zero JS errors (favicon 404 only). -->
  - [x] verify-human  <!-- status: [x] — user-approved 2026-05-23 ("looks good") -->
    - [x] P2.verify-human.1 Chip discoverability (UX judgment) — approved.  <!-- status: [x] — All 3 mechanical claims from plan (reading OFF, reading ON, away OFF no-shift) subsumed by verify-self subagent's 10/10 PASS; reduced to 3 UX judgment calls per pre-filter rule. -->
    - [x] P2.verify-human.2 Toggle feedback intensity (UX judgment) — approved.  <!-- status: [x] -->
    - [x] P2.verify-human.3 Per-row total subtlety (UX judgment) — approved.  <!-- status: [x] -->
  - [x] verify-codify  <!-- status: [x] — added 3 new test_visualize_cli.sh assertions (64→67 PASS): data-kind on SegmentBar, Legend lists all 5 kinds, FilterContext+filterKinds state machine present. Plus 6 new Python unit tests in new test_viz_render.py for the P2.disc.1 strip-marker regex (short/long/drifted dash counts, prose-mention false-match guard, real-source-still-strips integration). One triage entry (above) for an initial assertion that checked the wrong layer — fixed in-phase. test_viz_data.py 40/40 still PASS. -->

- [x] Phase 3: URL-hash persistence (`filters=...`)  <!-- status: [x] — all leaves complete -->
  **Observable outcomes:**
  - Browser: with default (all-on) filter state, URL hash does NOT contain a `filters=` key (default-elision rule from CLAUDE.md → Claude-time visualize URL-hash state).
  - Browser: toggling a chip OFF updates URL fragment to `#filters=<kinds>` where `<kinds>` is comma-separated list of the kinds that are currently ON (preserving the documented `filters=active,subagent` example shape).
  - Browser: reload page with `#filters=active,subagent` in URL → filter state restores to {active:T, reading:F, thinking:F, away:F, subagent:T}.
  - Browser: hash uses `history.replaceState` not `pushState` (verify via single back-button press not navigating away).
  - HTML: emitted JS contains a serialized representation of the filter key in `parseHash`/`updateHash` consumer code.
  - CLI: `test_visualize_cli.sh` passes.
  - [x] P3.1 Replaced the placeholder filterKinds initializer with hash-restore: reads `parseHash().filters`, parses comma-separated kinds via a `Set`, sets each kind to its presence/absence in that set. Sanity guard: if no recognized kind matches (malformed hash), fall back to all-ON rather than render an empty dashboard.  <!-- status: [x] -->
  - [x] P3.2 Added `useEffect([filterKinds])` hash-writer: debounced 100ms, replaceState (history-clean), default-elision when all kinds are ON (sets `filters: null` so updateHash drops the key), otherwise serializes ON-kinds in canonical order `FILTER_KINDS = ['active', 'reading', 'thinking', 'subagent', 'away']` — same order as Legend chips, hash deterministic regardless of click sequence.  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — py_compile viz_render.py PASS; emit-smoke: hash.filters reads x2, updateHash({filters:...}) writes x2, default-elision (filters: null) x1, canonical-order const x1, 2 setTimeout debounce calls in emit (one for viewport one for filter); P1+P2 pins all hold; test_visualize_cli.sh 67/67 PASS no regressions -->
  - [x] verify-self  <!-- status: [x] — 7/7 PASS via Playwright subagent on file:///tmp/wp9-p3-verify.html: initial hash empty (default-elision), click reading OFF → hash=#filters=active,thinking,subagent,away (canonical order, URL-encoded commas), toggle back ON → hash empties (default-elision re-applies), reload with #filters=active,subagent → chips restore to {active:T, reading:F, thinking:F, subagent:T, away:F} and segments correctly filtered (reading=0, thinking=0, away=0, active=16, subagent=2), malformed hash sanitized to all-ON via fallback, history.length unchanged across 3 toggles (replaceState confirmed), zero JS errors. Same-document navigation does not re-mount React — true contract is "reload restores", which works. -->
  - [x] verify-human  <!-- status: [x] — user-approved 2026-05-23 ("approve") -->
    - [x] P3.verify-human.1 URL aesthetic — approved.  <!-- status: [x] — Plan's original mechanical claim (toggle OFF → exact hash format, reload → state restores, toggle back ON → key disappears) fully subsumed by verify-self subagent's 7/7 PASS; reduced to a single URL-shareability judgment call per pre-filter rule. -->
  - [x] verify-codify  <!-- status: [x] — 4 new static-emit pins in test_visualize_cli.sh (67→71): hash.filters read, updateHash({filters:...}) writer, default-elision (filters: null) branch, FILTER_KINDS canonical-order const. PLUS 6 new behavioral assertions in test_visualize_interactive.js Outcomes 9-11 (Playwright, container-only) covering: default-state hash-empty, reading OFF → canonical hash, reading ON → default-elision drops key, reload with #filters=active,subagent restores chip state, restored state filters timeline DOM, malformed hash → all-on fallback. Interactive suite 16/16 PASS (was 10). Cross-suite still green: test_viz_data 40/40, test_viz_render 6/6. -->

- [x] Phase 4: Per-project filter popover  <!-- status: [x] — all leaves complete -->
  **Observable outcomes:**
  - Browser: a "Projects" chip (or `+ Filter` button extension) opens a popover listing all projects in current view with on/off toggles. Default = all projects ON.
  - Browser: toggling project X OFF removes its row entirely from `DayTimeline` (per-project hide, not per-segment). Per-row visual layout reflows.
  - Browser: chip count reflects number of projects currently filtered out (e.g., "Projects (2 hidden)").
  - HTML: emitted JS contains `projectFilter` state and popover open/close state.
  - CLI: `test_visualize_cli.sh` passes.
  - [x] P4.1 `filterProjects` state already added in P2.2 (paired with filterKinds). Default `{}` = all ON; explicit `false` entries hide that project. Plumbed via FilterContext alongside kind filter.  <!-- status: [x] -->
  - [x] P4.2 **Plan deviation (documented):** Added `ProjectFilterPopover` component next to `<Legend />` in the date-header strip (NOT in the toolbar — same reasoning as Phase 2: toolbar stays for view + date controls; filter affordances cluster near Legend). Trigger button shows IconFilter + "Projects" label + count badge when projects are hidden. Floating panel opens below, contains checkbox list of `projects.map(p => ({id, alias}))` with strikethrough + dim styling for hidden entries.  <!-- status: [x] -->
  - [x] P4.3 `DayTimeline` derives `visibleProjects = data.projects.filter(p => projectFilter[p.id] !== false)` via `React.useMemo`, then maps over that. Hidden projects skip both their `ProjectHeaderRow` and `SessionRow`s — layout reflows naturally. Scope: Day view only (per plan). WeekTimeline untouched (different aggregation; deferred decision for a future WP).  <!-- status: [x] -->
  - [x] P4.4 Outside-click dismiss via `useEffect([open])` that adds a `document.mousedown` listener when open, checks `rootRef.current.contains(e.target)`, calls `setOpen(false)` on outside hits. Cleanup removes the listener on close or unmount.  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — py_compile viz_render.py PASS; emit-smoke: ProjectFilterPopover defined+rendered (1+1), data-project-filter-trigger present, outside-click mousedown listener present (1), visibleProjects filter refs (2); P1+P2+P3 pins all hold; test_visualize_cli.sh 71/71 PASS, no regressions -->
  - [x] verify-self  <!-- status: [x] — 10/10 PASS via Playwright subagent on file:///tmp/wp9-p4-verify.html: trigger present, starts closed (panel absent from DOM), demo data has N=4 projects, click opens panel with 4 correct project IDs (claude-time, agent-handoff-protocol, om-design-system, weekend-tinkering), all initially checked, unchecking claude-time → data-project-filter-on='false' on that item + hidden-count badge showing '1' + segment count drops from 28 to 15 (claude-time's segments removed), re-check restores all 28 segments and clears badge, outside-click on a segment correctly dismisses (data-project-filter-open='false', panel removed), zero JS console errors. -->
  - [x] verify-human  <!-- status: [x] — user-approved 2026-05-23 ("approve") -->
    - [x] P4.verify-human.1 Trigger discoverability (UX judgment) — approved.  <!-- status: [x] — Plan's original mechanical claims (uncheck → row disappears, re-check → reappears, outside-click dismiss) all PASSed by verify-self with concrete DOM evidence (28→15→28 segment counts, panel removed on outside-click); reduced to 3 UX judgment calls per pre-filter rule. -->
    - [x] P4.verify-human.2 Popover positioning & polish (UX judgment) — approved.  <!-- status: [x] -->
    - [x] P4.verify-human.3 Filter composition (kinds × projects) — approved.  <!-- status: [x] -->
  - [x] verify-codify  <!-- status: [x] — 5 new static-emit pins in test_visualize_cli.sh (71→76): ProjectFilterPopover defined+rendered, data-project-filter-trigger, data-project-filter-item, addEventListener('mousedown'). PLUS 6 new behavioral Playwright assertions in test_visualize_interactive.js Outcomes 12-13 covering: trigger starts closed, click opens panel, N projects rendered as checkboxes, uncheck → data-project-filter-on=false + badge='1' + segments decrease, re-check restores all + clears badge, outside-click dismisses. Interactive suite 22/22 PASS (was 16). Cross-suite still green: test_viz_data 40/40, test_viz_render 6/6. -->

- [x] Phase 5: Codify regression coverage + cleanup  <!-- status: [x] — entirely superseded by per-phase verify-codify pins, see Phase 5 triage below -->
  **Observable outcomes (all achieved in earlier phases):**
  - CLI: `test_visualize_cli.sh` 76/76 PASS (was 62 baseline; +14 WP9-specific pins distributed across P1/P2/P3/P4 codify).
  - CLI: `test_visualize_interactive.js` 22/22 PASS (was 10; +12 WP9 behavioral pins in P3/P4 codify).
  - Cross-suite green: test_viz_data 40/40, test_viz_render 6/6.
  - Phase 5c byte-pins (index.html + design-canvas.jsx) untouched and PASSING.
  - [x] P5.1 → superseded by `WP9-P1 codify: exactly one Toolbar function (duality collapsed)` + `WP9-P1 codify: no <InteractiveToolbar> JSX usage (regression-pin)` in test_visualize_cli.sh.  <!-- status: [x] -->
  - [x] P5.2 → superseded by `WP9-P2 codify: FilterContext + filterKinds state machine present` in test_visualize_cli.sh. Plan said `filterState`; code uses `filterKinds` — equivalent state-machine concept.  <!-- status: [x] -->
  - [x] P5.3 → superseded by `WP9-P2 codify: SegmentBar emits data-kind attribute (selector contract)` in test_visualize_cli.sh.  <!-- status: [x] -->
  - [x] P5.4 → superseded by `WP9-P4 codify: data-project-filter-item attribute (per-project checkbox contract)` + `WP9-P4 codify: ProjectFilterPopover component defined` in test_visualize_cli.sh.  <!-- status: [x] -->
  - [x] P5.5 → superseded by `WP9-P3 codify: hash.filters read at init` + `WP9-P3 codify: updateHash({ filters: ... }) writer present` in test_visualize_cli.sh.  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — implicit, each pin verified at its source phase -->
  - [x] verify-self  <!-- status: [x] — implicit, each pin verified at its source phase -->
  - [x] verify-human  <!-- status: [x] — user already approved phases 1-4 -->
    - [x] P5.verify-human.1 → superseded — full suite already verified each phase: test_visualize_cli.sh 76/76, test_visualize_interactive.js 22/22, test_viz_data.py 40/40, test_viz_render.py 6/6.  <!-- status: [x] -->
  - [x] verify-codify  <!-- status: [x] — superseded by per-phase verify-codify -->

## Current Node
- **Path:** Feature > SHIPPED (commit f5a1123) → finalize
- **Active scope:** All 5 phases [x]. WP9 shipped to main. Next: /feature-finalize.
- **Blocked:** none
- **Unvisited:** finalize (retrospect, CHANGELOG, WBS row → SHIPPED, archive WIP)
- **State:** ship (complete) — commit f5a1123, pushed to main 2026-05-23
- **Open discoveries:** P2.disc.1 resolved with regression coverage (test_viz_render.py); Phase 5 superseded with triage entry documenting the codify-discipline lesson.

## Test Triage — WP9-P2 codify: filter chip count
Classification: Obsolete test (initial draft, not yet committed) — assertion checked the wrong layer (raw JSX source `grep` instead of runtime DOM count)
Confidence: high
Evidence: `data-filter-kind={it.kind}` lives inside a React `.map()` callback in Legend; the literal source string occurs once, runtime expands to 5 DOM buttons. verify-self subagent counted 5 via `document.querySelectorAll('[data-filter-kind]')` at runtime — that's the right layer for the "5 chips render" contract; static emit only sees the source.
Action: Updated assertion to grep for the 5 literal `kind: '<name>'` entries in Legend's `items` array (one per kind). Same regression coverage (drop one kind → assertion fails) without the runtime/static layer confusion. Re-ran: 67/67 PASS.

## Phase 5 Triage — entire phase superseded
Classification: Obsolete phase — every Phase 5 codify leaf has a direct equivalent assertion already PASSING in test_visualize_cli.sh, landed during the relevant earlier phase's verify-codify node.
Confidence: high
Evidence: Phase 5's 5 codify leaves map 1:1 to the WP9-P1/P2/P3/P4 codify assertions documented in the WIP tree above. test_visualize_cli.sh runs all 14 WP9 pins and PASSES 76/76. test_visualize_interactive.js runs 12 behavioral pins and PASSES 22/22. Re-running these assertions in a "Phase 5 verify-codify" cycle is exact duplication, not new coverage.
Action: Marked Phase 5 leaves `[x] — superseded by Phase N codify` with citations to the equivalent assertion's name. Marked Phase 5 verify nodes `[x]` (implicit — each pin verified at its source phase). Phase node `[x]`. WP9 is structurally complete. Per WBS planning discipline (consuming-surface pins land with their consuming code, not in a separate "codify everything" phase), this is the correct outcome — the plan's Phase 5 was sensible-but-pessimistic centralization that execution improved upon. Going forward, plans for similar features can omit a dedicated "codify cleanup" phase when per-phase codify discipline is followed.

## Retrospect

- **What changed in our understanding:** Two plan-time placements turned out to be slightly wrong at implementation time, and both moved to the same alternate surface (`<Legend />`, not `<Toolbar />`). Phase 2 was specified as "functional chips in Toolbar"; Phase 4 specified "popover trigger in Toolbar." In execution, both landed next to `<Legend />` in the date-header strip — the Toolbar stays clean for view + date controls, while filter affordances cluster with the existing color-key legend. This is documented as a deliberate deviation in both phase nodes. **Lesson:** when a plan specifies a placement, validate it against the existing UI surface during build; if the natural surface differs from the plan's, deviate and document — don't force the plan's placement when a better one exists in code.
- **Assumptions that held:**
  - The viewport-state hash-restore/write pattern from WP5 was the right template for the filters= hash key — replication was mechanical and the conventions doc (CLAUDE.md "Claude-time visualize URL-hash state") had pre-reserved the key, so Phase 3 was the smoothest phase.
  - Per-phase verify-codify discipline (codify-pins land with their consuming code) is the right pattern. The plan's Phase 5 "centralize codify" approach turned out to be sensible-but-pessimistic — by the time Phase 5 came up, every assertion it intended to add had already landed in P1-P4 codify. Triage marked Phase 5 superseded, captured the discipline lesson in the WIP.
  - The integration-boundary rule for verify-self/verify-human held cleanly across all 4 phases — each had a clear consuming surface (CLI emit, browser DOM, URL hash), each was verified end-to-end by Playwright subagent + cited concrete numeric evidence (segment counts, hash strings, history.length deltas).
- **Assumptions that were wrong:**
  - **Plan said "5 chip count in emit"; reality was "1 chip count in static emit, 5 at runtime DOM."** First Phase 2 codify assertion grepped the wrong layer (static source has 1 literal `data-filter-kind=` inside a React `.map()`; runtime expands to 5 DOM buttons). Caught at codify-time, triaged as "obsolete test, high confidence," replaced with a 5-kind-completeness pin on Legend's `items` array — same regression coverage without the layer confusion. **Lesson:** when codifying behavior verified by a runtime tool (Playwright DOM count), pick an assertion in the same layer; if the static-emit equivalent is awkward, leave the runtime assertion as the canonical one and add only structural-completeness pins to static-emit.
  - **In-phase discovery (P2.disc.1):** the `_strip_design_wrapper` strict marker had drifted from the source (33 dashes in source vs hardcoded ~30 in regex), silently falling through to a naive `find("Dashboard wrapper")` fallback. My new P2.3 Legend comment mentioned "Dashboard wrapper" in prose → false-first match stripped the whole file body. Fixed in-phase: replaced the strict matcher with a dash-count-tolerant regex that requires the `/* ── ... ── */` section-header context. Added 6 unit tests in new `test_viz_render.py` covering the failure mode + the drift-tolerance contract.
- **Approach delta:**
  - Plan had 5 phases; execution shipped 4 phases of new code + 1 superseded phase (Phase 5 codify-cleanup). Net work: same regression coverage as planned, achieved via per-phase codify discipline rather than a centralized codify-everything phase.
  - Plan said "5 chips in Toolbar"; execution placed them in `<Legend />` (existing component, already in the right position with the right kinds in the right order, just made interactive).
  - One in-phase discovery + fix (`_strip_design_wrapper` regex hardening) added a new test file (`test_viz_render.py`) that wasn't planned.
  - Test count delta vs plan estimate ("62 → ~67, +5 new"): actual was **62 → 76 (+14 static)**, plus **+12 behavioral**, plus **+6 unit** — substantially more coverage than the plan budgeted, primarily because per-phase codify can absorb more pins than a single Phase 5 codify pass could without becoming unwieldy.

## Communicate

> **Feature complete:** WP9 — interactive filter chips + Toolbar duality collapse — has shipped (commit `f5a1123`, on `main`). Five kind chips (active/reading/thinking/subagent/away) and a per-project popover let you hide segment kinds and individual projects from the timeline; filter state persists in the URL hash (`#filters=active,subagent`) for shareable filtered views. Bundled bonus: the design-canvas/InteractiveToolbar duality is gone — future toolbar-touching WPs (WP10 headline-stats, WP12 multi-instance overlap) edit a single file. To see it in action: `tools/claude-time/claude-time visualize` and click the kind labels in the date-header strip, or the "Projects" button next to them.
>
> Requester = operator — closure notice for self-record.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->

## Plan-level "downstream contract impacts" pass

Per CLAUDE.md "Plan-level downstream contract impacts" rule: flag phases that change a contract other artifacts already assert against.

- **Phase 1 (duality collapse) — contract changes:**
  - `viz_render.py` module docstring (line 1–29) describes the toolbar transform as a `_strip_design_wrapper` + `_interactive_dashboard()` step pair. Phase 1 removes the InteractiveToolbar portion; docstring updated in P1.4 (same phase, not deferred).
  - CLAUDE.md "Design-as-data" convention references "emit-time-appended toolbar" — postscript appended in P1.5 (same phase).
  - `test_visualize_cli.sh` has no assertion currently grepping for `InteractiveToolbar` (verified by absence in grep). No test fixture needs updating in Phase 1.
  - `tests/check-structure.sh` Phase 5c byte-pins `index.html` + `design-canvas.jsx` only — neither changes in Phase 1. No byte-pin update needed.
- **Phase 2 (filter state) — contract changes:**
  - Adds `data-kind=` attribute to `SegmentBar` root div. No existing test references this attribute (verified by grep). New attribute is additive; safe.
- **Phase 3 (URL hash) — contract changes:**
  - Adds `filters` key to the URL-hash schema documented in CLAUDE.md "Claude-time visualize URL-hash state". The convention table already lists this reservation (WP9 row, `filters=active,subagent` example). The convention doc was written ahead of time; no update needed.
- **Phase 4 (per-project popover) — contract changes:**
  - No URL-hash key reserved for project filter in CLAUDE.md convention table. Decision: scope WP9 to in-session state only (no `projects=` hash key). Document in CLAUDE.md convention table at codify time if state persistence is desired later (mark "deferred — in-session only in WP9"). This avoids hash-schema sprawl for a feature that may benefit from WP13 (collapsible project rows) interaction first.
- **Phase 5 (codify) — contract changes:**
  - Adds ~5 assertions to `test_visualize_cli.sh`. Assertion count moves from 62 → ~67. Not a contract change to any other artifact.

## Pause Policy

Drive mode: autopilot (Mode 3). Per `agents/feature-workflow/AGENTS.md`:
- Skill entry (this skill): PAUSE in Modes 1–2, AUTO in Modes 3–4. Mode is autopilot → no entry pause.
- F7 (plan → build): AUTO in Modes 3–4. Chain immediately to `/feature-build`.
- Per-phase `verify-human`: PAUSE in Modes 1–3. User reviews each phase before codify. Autopilot does pause at verify-human (this is the only autopilot pause point).
- Back-loops (F23, F9): AUTO in all modes 2–4.
