# Design-as-data: byte-pin + emit-time transforms (claude-time viz/ pattern)

**Status:** Historical / partially superseded by v2.

## Historical origin (2026-05-19, claude-time-visualize v1)

The files in `tools/claude-time/viz/` were originally treated as the **Claude Design extract** — immutable source-of-truth for the dashboard's visual contract — and **byte-pinned** by `tests/check-structure.sh` Phase 5c. `tools/claude-time/viz_render.py` applied **emit-time text-replacement transforms** (strip DesignCanvas, wire interactive state, add InterruptHairlines, append interactive Dashboard wrapper) over the unmodified source to produce the shipped HTML.

The trade-off: text-replace transforms are brittle, but the byte-pin enforced immutability so the brittleness couldn't bite.

## Current state (2026-05-19, claude-time-visualize-v2 cycle starts)

The v2 cycle's UX evolution (zoomable timeline, collapsible rows, view-mode expansion) exceeds what additive emit-time transforms can reasonably support. The byte-pin is **relaxed for editable files** (`dashboard.jsx`, `data.js`) — direct source edits are permitted; integrity is now guarded by `node --check` / `@babel/parser` + downstream `test_visualize_cli.sh` behavioral assertions. `index.html` and `design-canvas.jsx` stay byte-pinned (the design-canvas prototype remains a reference artifact). The Claude Design extract is **reference-only** going forward — re-import from it if a specific asset is needed, but don't treat the in-tree source as immutable.

## Lesson encoded

When introducing a structural lock-in (byte-pin, signed-hash, immutability assertion) to guard a brittle pattern, also budget for the unlock condition — write down how and when it gets relaxed. Otherwise the lock fights the natural evolution of the artifact it's protecting.

## WP9 postscript (2026-05-23)

The design-canvas/InteractiveToolbar duality was collapsed (option a from `SURFACE-2026-05-23-CLAUDE-TIME-VIZ-DESIGN-CANVAS-INTERACTIVE-TOOLBAR-DUALITY`): `viz_render.py::InteractiveToolbar` was deleted and its body moved into `viz/dashboard.jsx::Toolbar` (now the single canonical Toolbar). The emit-time transforms in `viz_render.py` no longer touch the toolbar — `_strip_design_wrapper` + `_wire_bar_click` + `_add_interrupt_hairlines` remain.

Future toolbar-touching WPs (WP10 headline-stats card, WP12 multi-instance overlap viz) edit a single file. The static design-canvas `Dashboard({variant})` wrapper still uses `<Toolbar view={...} onViewChange={() => {}} ...>` as a no-op pass-through for reference-rendering purposes; the wrapper itself is still stripped at emit by `_strip_design_wrapper`.

## v3 sub-payload routing pattern: useMemo with v2-alias fallback

**Status:** Retired at WP9 Phase 2 (v3 cycle close, 2026-06-03).

The v2 alias keys (`today`, `week`, `comparison`, `months`, `meta`) have been stripped from the CLI emit; each useMemo is now primary-only (e.g. `dayPayload = dayPayloadsByIso[dayIso] || <empty Day-like shape>`). Custom view's `customPayload` useMemo (the bridging case) now returns an empty Day-like payload for out-of-window ranges and `onRangeChange` surfaces a reload-redirect toast.

### Pattern history (kept for context)

`viz_render.py::_interactive_dashboard` reads data sources keyed by view (Day/Week/Month/Compare/Custom). v3 routes each view's data through its sub-payload map (`day_payloads_by_iso`, `week_payloads_by_monday`, `month_payloads_by_iso`, `compare_payloads_by_preset`). During WP5–WP9-P1 the useMemo had a v2-alias fallback (`return today;` etc.) to let shared render code paths (like `isDayLike` which Day + Custom share) stay un-forked while WPs migrated their consumer surfaces one at a time. The fallback turned out to be the correctness mechanism for Custom-view coexistence; WP9 Phase 1 made `customPayload` (the cross-day union over `day_payloads_by_iso`) the load-bearing primary path, and WP9 Phase 2 stripped the alias keys + pruned the now-dead fallbacks.

Applied to 5 of 5 sub-payload views (Day/Week/Month/Compare/Custom). Future WPs in any new transition cycle can copy this approach — bridging useMemo + per-WP migration + cycle-close strip — as a template for safely retiring a contract surface.
