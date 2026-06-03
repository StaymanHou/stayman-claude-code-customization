"""Render the claude-time dashboard to a self-contained HTML file.

Reads `viz/template.html` + `viz/dashboard.jsx`, applies transforms that:
  1. Strip the Phase 1 design-canvas-style `Dashboard({variant})` wrapper
     and replace it with an interactive `Dashboard()` (no props) that uses
     `useState` for current view (day|week) and selected session segment.
  2. Wire bar clicks to set the selected segment + show side panel.
  3. Render `interrupts: [<minutes>]` as vertical hairlines inside the
     active bar (Phase 2 added the data; Phase 3 renders it).
  4. Render a `snapshot: HH:MM` caption in the toolbar (WP2). The caption
     reads `window.CT_DATA.meta.snapshot`, populated by `_cmd_visualize`
     in `claude-time` at emit time. Coexists with the live NOW marker
     (computed client-side via `useNowMin()` in `dashboard.jsx`): the
     cursor moves, the bars don't — the caption is how the user is told.

Historically (v1) `viz/dashboard.jsx` was treated as immutable and Phase 5c
byte-pinned it. Starting with the v2 cycle (claude-time-visualize-v2,
2026-05-19), direct source edits to `dashboard.jsx` and `data.js` are
permitted — the byte-pin is relaxed for those two files. The emit-time
transforms below remain as the *additive* layer that wires interactivity
on top of the (now-editable) design source.

WP9 (2026-05-23) further collapsed the design-canvas/InteractiveToolbar
duality: the Toolbar component is now defined directly in `dashboard.jsx`
and consumed by the shipped Dashboard wrapper here as `<Toolbar ...>`.
The emit-time-appended InteractiveToolbar variant is gone. See `CLAUDE.md`
→ "Design-as-data" convention for the full history.

Public API:
  render_html(template_path, dashboard_jsx_path, data, initial_view) -> str
"""

from __future__ import annotations

import json
import re
from pathlib import Path


def _strip_design_wrapper(jsx: str) -> str:
    """Remove the design-canvas-era Dashboard wrapper at the bottom of
    dashboard.jsx. We replace it with an interactive version in
    `_interactive_dashboard()` below.

    Matches the literal section-header comment `/* ── Dashboard wrapper ──...── */`
    with any number of trailing ─ characters (the source line's dash-count has
    drifted historically). The naive `find("Dashboard wrapper")` fallback was
    removed because new code can legitimately mention "Dashboard wrapper" in
    prose comments without intending to be the strip marker (WP9 Phase 2,
    2026-05-23: hit this on a `FilterContext` comment that mentioned "shipped
    Dashboard wrapper" — false-first match stripped the whole file body).
    """
    import re as _re
    m = _re.search(r'/\*\s*\u2500{2,}\s*Dashboard wrapper\s*\u2500{2,}\s*\*/', jsx)
    if not m:
        raise ValueError("dashboard.jsx: cannot locate the /* ── Dashboard wrapper ── */ section-header marker")
    return jsx[:m.start()]


def _interactive_dashboard() -> str:
    """The replacement Dashboard wrapper for the shipped HTML.

    Uses useState to switch between day/week views, manage selected segment
    (for side panel), and track which projects are expanded.
    """
    return r"""
/* ── Dashboard wrapper (interactive, shipped variant) ───────── */
function Dashboard() {
  const { today, week } = window.CT_DATA;
  // WP5 (v3): Day-view sub-payload routing. The interactive Dashboard reads
  // the active day's payload from `day_payloads_by_iso[dayIso]`. The `today`
  // alias above is still populated by the CLI for v2-frontend coexistence
  // (Custom view's `today.meta.{start,end}` reads, the `_initView` IIFE's
  // 'custom' fallback) — WP9 removes the alias at v3 cycle close. For the
  // Day-view *render path* below, `dayPayload` is the single source of truth.
  const dayPayloadsByIso = window.CT_DATA.day_payloads_by_iso || {};
  const dayIsoKeys = Object.keys(dayPayloadsByIso).sort();
  const windowEndIso = (window.CT_DATA.window && window.CT_DATA.window.end) || null;
  // WP6 (v3): Week-view sub-payload routing. The interactive Dashboard reads
  // the active week's payload from `week_payloads_by_monday[mondayIso]`. The
  // `week` alias above is still populated by the CLI for v2-frontend
  // coexistence (WP9 removes the alias at v3 cycle close). For the Week-view
  // *render path* below, `weekPayload` is the single source of truth.
  // `currentWeekMondayIso` = the Monday of the ISO-week containing windowEndIso
  // (always a valid key in week_payloads_by_monday — build_window_data emits a
  // payload for every Monday-anchored week intersecting the window). Computed
  // in UTC to avoid timezone surprises.
  const weekPayloadsByMonday = window.CT_DATA.week_payloads_by_monday || {};
  const weekMondayKeys = Object.keys(weekPayloadsByMonday).sort();
  const currentWeekMondayIso = (() => {
    if (!windowEndIso) return null;
    const d = new Date(windowEndIso + 'T00:00:00Z');
    // getUTCDay(): Sunday=0..Saturday=6. ISO-week Monday: subtract (day===0 ? 6 : day-1).
    const dow = d.getUTCDay();
    const offset = (dow === 0) ? 6 : (dow - 1);
    d.setUTCDate(d.getUTCDate() - offset);
    return d.toISOString().slice(0, 10);
  })();
  // WP7: months map. Pre v3, populated only on --month emits; in v3 the
  // `--window` flag's pre-rendered window always emits month_payloads_by_iso
  // covering the full window (aliased to top-level `months` for v2-frontend
  // coexistence). Maps ISO month strings ("YYYY-MM") to range_data payloads.
  // Prev-arrow nav is a pure client-side state swap when target month is in
  // the map; any other nav triggers reload-redirect via MonthNavToast.
  const monthsMap = window.CT_DATA.months || null;
  // WP8: hash.view (if present) wins over CT_INITIAL_VIEW so a shareable
  // URL like #view=custom;range=2026-05-20:2026-05-22 restores correctly.
  // Recognized values: 'day', 'week', 'custom', 'month'. Malformed → fall
  // through to CT_INITIAL_VIEW (which itself defaults to 'day' for unknown
  // values). The 'custom' view requires a valid hash.range OR a
  // CT_INITIAL_VIEW emit-time 'custom'. The 'month' view requires a valid
  // hash.month (or CT_INITIAL_VIEW='month') AND the monthsMap to be present
  // (otherwise there's no data to render).
  const _initView = (() => {
    const hash = parseHash();
    if (hash.view === 'compare') return 'compare';
    if (hash.view === 'month' && /^\d{4}-\d{2}$/.test(hash.month || '') && monthsMap) {
      return 'month';
    }
    if (hash.view === 'custom' && /^\d{4}-\d{2}-\d{2}:\d{4}-\d{2}-\d{2}$/.test(hash.range || '')) {
      return 'custom';
    }
    if (hash.view === 'week' || hash.view === 'day') return hash.view;
    // Fallthrough: emit-time default. CT_INITIAL_VIEW is 'day'|'week'|'custom'|'month'|'compare'
    // (WP7 added 'month'; WP8 added 'custom'; WP11 added 'compare'). For
    // 'custom' emit-time, we require today.meta.start to be present; for
    // 'month', we require monthsMap to be present; for 'compare', we require
    // window.CT_DATA.comparison to be present.
    if (window.CT_INITIAL_VIEW === 'compare' && window.CT_DATA.comparison) {
      return 'compare';
    }
    if (window.CT_INITIAL_VIEW === 'month' && monthsMap) {
      return 'month';
    }
    if (window.CT_INITIAL_VIEW === 'custom' && today.meta && today.meta.start && today.meta.end) {
      return 'custom';
    }
    if (window.CT_INITIAL_VIEW === 'week') return 'week';
    return 'day';
  })();
  const [view, setView] = React.useState(_initView);

  // WP11: Compare preset state — one of 'wow', 'today-vs-trailing', 'mom',
  // 'custom'. Hash takes precedence on init; falls back to CT_INITIAL_PRESET
  // (emitter-supplied, always null in v3 since the unified `--window` emit
  // doesn't pick a preset — URL hash drives Compare-view selection); falls
  // back to a sensible default derived from initial view (Q1).
  const _initPreset = (() => {
    const hash = parseHash();
    if (hash.preset && ['wow', 'today-vs-trailing', 'mom', 'custom'].includes(hash.preset)) {
      return hash.preset;
    }
    if (window.CT_INITIAL_PRESET) return window.CT_INITIAL_PRESET;
    // Derive from emit-time initial view (Q1 mapping).
    if (window.CT_INITIAL_VIEW === 'week') return 'wow';
    if (window.CT_INITIAL_VIEW === 'month') return 'mom';
    if (window.CT_INITIAL_VIEW === 'custom') return 'custom';
    return 'today-vs-trailing';
  })();
  const [preset, setPreset] = React.useState(_initPreset);

  // WP11: compareRanges state — for `preset === 'custom'`, the user-picked
  // {a: {start, end}, b: {start, end}} pair. Hash key is `ranges=A_s:A_e,B_s:B_e`.
  // On init, restore from hash if present + valid; otherwise seed from
  // comparison.meta (the wow-preset payload aliased as `comparison` always
  // ships meta.{a_start,a_end,b_start,b_end} for label rendering).
  const _initCompareRanges = (() => {
    const hash = parseHash();
    if (hash.ranges) {
      const m = hash.ranges.match(/^(\d{4}-\d{2}-\d{2}):(\d{4}-\d{2}-\d{2}),(\d{4}-\d{2}-\d{2}):(\d{4}-\d{2}-\d{2})$/);
      if (m) {
        return {
          a: { start: m[1], end: m[2] },
          b: { start: m[3], end: m[4] },
        };
      }
    }
    if (window.CT_DATA.comparison && window.CT_DATA.comparison.meta) {
      const meta = window.CT_DATA.comparison.meta;
      return {
        a: { start: meta.a_start, end: meta.a_end },
        b: { start: meta.b_start, end: meta.b_end },
      };
    }
    // No comparison data — placeholder ranges; the UI shows the custom
    // RangePicker pair so the user can pick.
    const todayIso = new Date().toISOString().slice(0, 10);
    return { a: { start: todayIso, end: todayIso }, b: { start: todayIso, end: todayIso } };
  })();
  const [compareRanges, setCompareRanges] = React.useState(_initCompareRanges);

  // WP7: monthIso state — which month's grid is currently rendered. Hash
  // takes precedence on init; falls back to active-month emit (today.meta.start
  // → "YYYY-MM"); falls back to current calendar month if nothing else.
  const _initMonthIso = (() => {
    const hash = parseHash();
    if (hash.month && /^\d{4}-\d{2}$/.test(hash.month) && monthsMap && monthsMap[hash.month]) {
      return hash.month;
    }
    if (monthsMap) {
      // Pick the active month — the one matching today.meta.start. If that
      // doesn't match a months[] key, fall back to the first key.
      if (today.meta && today.meta.start) {
        const iso = today.meta.start.slice(0, 7);
        if (monthsMap[iso]) return iso;
      }
      const keys = Object.keys(monthsMap);
      if (keys.length > 0) return keys[0];
    }
    // No emit-time month data — derive from today's calendar month.
    const d = new Date();
    return `${String(d.getFullYear()).padStart(4, '0')}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  })();
  const [monthIso, setMonthIso] = React.useState(_initMonthIso);

  // WP5 (v3): dayIso state — which day's payload is currently rendered in
  // Day view. Hash takes precedence on init (`date=YYYY-MM-DD`); falls back
  // to window.end (the most-recent pre-rendered day). Default-elision in the
  // hash-write effect drops the key when dayIso === windowEndIso.
  const _initDayIso = (() => {
    const hash = parseHash();
    if (hash.date && /^\d{4}-\d{2}-\d{2}$/.test(hash.date) && dayPayloadsByIso[hash.date]) {
      return hash.date;
    }
    if (windowEndIso && dayPayloadsByIso[windowEndIso]) return windowEndIso;
    // No window data — fall back to whatever the alias is keyed at.
    return windowEndIso || (today.meta && today.meta.start) || '';
  })();
  const [dayIso, setDayIso] = React.useState(_initDayIso);

  // WP6 (v3): mondayIso state — which week's payload is currently rendered
  // in Week view. Hash takes precedence on init (`week=YYYY-MM-DD`,
  // Monday-anchored); falls back to currentWeekMondayIso (the Monday of the
  // ISO-week containing window.end). Default-elision in the hash-write
  // effect drops the key when mondayIso === currentWeekMondayIso.
  const _initMondayIso = (() => {
    const hash = parseHash();
    if (hash.week && /^\d{4}-\d{2}-\d{2}$/.test(hash.week) && weekPayloadsByMonday[hash.week]) {
      return hash.week;
    }
    if (currentWeekMondayIso && weekPayloadsByMonday[currentWeekMondayIso]) {
      return currentWeekMondayIso;
    }
    // No window data — fall back to the latest sorted Monday key (the CLI
    // alias attachment uses the same fallback at claude-time:676-678).
    if (weekMondayKeys.length > 0) return weekMondayKeys[weekMondayKeys.length - 1];
    return currentWeekMondayIso || '';
  })();
  const [mondayIso, setMondayIso] = React.useState(_initMondayIso);

  // WP6: stepWeek swaps to the prior/next Monday key in sorted weekMondayKeys.
  // Returns silently if at boundary (caller's button is disabled too).
  const stepWeek = React.useCallback((delta) => {
    if (weekMondayKeys.length === 0) return;
    const idx = weekMondayKeys.indexOf(mondayIso);
    if (idx < 0) return;
    const nextIdx = idx + delta;
    if (nextIdx < 0 || nextIdx >= weekMondayKeys.length) return;
    setMondayIso(weekMondayKeys[nextIdx]);
  }, [mondayIso, weekMondayKeys]);
  const onPrevWeek = React.useCallback(() => stepWeek(-1), [stepWeek]);
  const onNextWeek = React.useCallback(() => stepWeek(+1), [stepWeek]);
  const prevWeekDisabled = weekMondayKeys.length === 0 || weekMondayKeys.indexOf(mondayIso) <= 0;
  const nextWeekDisabled = weekMondayKeys.length === 0 || weekMondayKeys.indexOf(mondayIso) >= weekMondayKeys.length - 1;

  // WP6: weekPayload — the active week's payload, derived from mondayIso.
  // For non-Week views, weekPayload defaults to the v2 `week` alias so the
  // non-WP6 code paths keep their existing behavior (per the WP5–WP9
  // transition convention in CLAUDE.md).
  const weekPayload = React.useMemo(() => {
    if (weekPayloadsByMonday[mondayIso]) return weekPayloadsByMonday[mondayIso];
    return week;
  }, [mondayIso, week]);

  // WP5: stepDay swaps to the prior/next ISO key in sorted dayPayloadsByIso.
  // Returns silently if at boundary (caller's button is disabled too).
  const stepDay = React.useCallback((delta) => {
    if (dayIsoKeys.length === 0) return;
    const idx = dayIsoKeys.indexOf(dayIso);
    if (idx < 0) return;
    const nextIdx = idx + delta;
    if (nextIdx < 0 || nextIdx >= dayIsoKeys.length) return;
    setDayIso(dayIsoKeys[nextIdx]);
  }, [dayIso, dayIsoKeys]);
  const onPrevDay = React.useCallback(() => stepDay(-1), [stepDay]);
  const onNextDay = React.useCallback(() => stepDay(+1), [stepDay]);
  const prevDayDisabled = dayIsoKeys.length === 0 || dayIsoKeys.indexOf(dayIso) <= 0;
  const nextDayDisabled = dayIsoKeys.length === 0 || dayIsoKeys.indexOf(dayIso) >= dayIsoKeys.length - 1;

  // WP5: dayPayload — the active day's payload, derived from dayIso.
  // For non-Day views (Custom, Week, Month, Compare), dayPayload defaults to
  // the v2 `today` alias so the non-WP5 code paths keep their existing
  // behavior. WP9 will route Custom through the v3 map; WP6/WP7/WP8 each
  // wire their own consumers.
  const dayPayload = React.useMemo(() => {
    if (dayPayloadsByIso[dayIso]) return dayPayloadsByIso[dayIso];
    return today;
  }, [dayIso, today]);

  // WP7: nav-toast state — the most recent reload-redirect prompt (or null).
  // Replaces on every new trigger (no stacking).
  const [navToast, setNavToast] = React.useState(null);

  // WP8: range state (start/end ISO date strings). Identity of the Custom
  // view — without a range the view is empty. Hash-restore on init if
  // present + valid; otherwise seed from data.today.meta (the `--window`
  // explicit-range form persists its picked range here via the legacy
  // alias keys).
  const [range, setRange] = React.useState(() => {
    const hash = parseHash();
    if (hash.range && /^\d{4}-\d{2}-\d{2}:\d{4}-\d{2}-\d{2}$/.test(hash.range)) {
      const [s, e] = hash.range.split(':');
      // Validate against the maxRangeDays cap; if invalid, fall back to emit data.
      if (validateRange(s, e, window.CT_MAX_RANGE_DAYS || 90) == null) {
        return { start: s, end: e };
      }
    }
    if (today.meta && today.meta.start && today.meta.end) {
      return { start: today.meta.start, end: today.meta.end };
    }
    // No range available — Custom view will fall back to 'day' via _initView.
    const todayIso = new Date().toISOString().slice(0, 10);
    return { start: todayIso, end: todayIso };
  });

  // WP10: metricsExpanded — collapsed (default) shows just the three
  // headline numbers; expanded reveals the full MetricsPanel below the card.
  // Hash key: `metrics=expanded`. Default-elision drops the key when
  // collapsed. Reload restores from hash.
  const _initMetricsExpanded = (() => {
    const hash = parseHash();
    return hash.metrics === 'expanded';
  })();
  const [metricsExpanded, setMetricsExpanded] = React.useState(_initMetricsExpanded);

  React.useEffect(() => {
    const t = setTimeout(() => {
      updateHash({ metrics: metricsExpanded ? 'expanded' : null });
    }, 100);
    return () => clearTimeout(t);
  }, [metricsExpanded]);

  // WP7/WP8: debounced URL-hash write on view + range + monthIso change.
  // WP5 (v3): adds the `date` key for Day-view sub-payload routing. Day-view
  // hash carries `date=YYYY-MM-DD` when the active day is not the default
  // landing (windowEndIso, the most-recent pre-rendered day in the window).
  // Default-elision:
  //   - view === 'day' AND dayIso === windowEndIso → drop all keys (default landing)
  //   - view === 'day' AND dayIso !== windowEndIso → write date=<iso>, drop others
  //   - view === 'week' → write view=week, drop range/month/date
  //   - view === 'custom' → write view=custom AND range (load-bearing —
  //     don't elide even if it matches today.meta; the data's emitted
  //     range would be ambiguous on a non-custom-emit URL)
  //   - view === 'month' → write view=month AND month=YYYY-MM (load-bearing
  //     — month grid identity is the month key)
  React.useEffect(() => {
    const t = setTimeout(() => {
      if (view === 'compare') {
        // WP11: preset is always emitted when in compare view; ranges only
        // when preset === 'custom' (its load-bearing identity).
        const patch = {
          view: 'compare',
          preset,
          range: null, month: null, date: null, week: null,
        };
        if (preset === 'custom') {
          patch.ranges = `${compareRanges.a.start}:${compareRanges.a.end},${compareRanges.b.start}:${compareRanges.b.end}`;
        } else {
          patch.ranges = null;
        }
        updateHash(patch);
      } else if (view === 'month') {
        updateHash({ view: 'month', month: monthIso, range: null, preset: null, ranges: null, date: null, week: null });
      } else if (view === 'custom') {
        updateHash({ view: 'custom', range: `${range.start}:${range.end}`, month: null, preset: null, ranges: null, date: null, week: null });
      } else if (view === 'week') {
        // WP6: emit `week` when mondayIso != currentWeekMondayIso.
        const weekForHash = (mondayIso && currentWeekMondayIso && mondayIso !== currentWeekMondayIso) ? mondayIso : null;
        updateHash({ view: 'week', range: null, month: null, preset: null, ranges: null, date: null, week: weekForHash });
      } else {
        // 'day' is the default view. WP5: emit `date` when dayIso != windowEndIso.
        const dateForHash = (dayIso && windowEndIso && dayIso !== windowEndIso) ? dayIso : null;
        updateHash({ view: null, range: null, month: null, preset: null, ranges: null, date: dateForHash, week: null });
      }
    }, 100);
    return () => clearTimeout(t);
  }, [view, range, monthIso, preset, compareRanges, dayIso, windowEndIso, mondayIso, currentWeekMondayIso]);

  // WP8: when the user picks a different range via the date-range picker,
  // we don't re-fetch data (would require a CLI round-trip). Instead, the
  // hash updates, and the next claude-time visualize invocation can read
  // the hash via shareable URL to bring up the right window. The picker
  // gives immediate visual feedback (hash updates, picker values reflect),
  // but the timeline body keeps showing the emit-time data. This is the
  // honest MVP behavior the WBS calls out — "mostly UI" — and avoids the
  // complexity of dynamic data-fetch from the browser. A future WP can
  // add a "rerun" button that calls back to the CLI.
  const onRangeChange = React.useCallback((nextRange) => {
    setRange(nextRange);
  }, []);
  // selectedSegId is "<sessionId>:<segIndex>" or null.
  const [selectedSegId, setSelectedSegId] = React.useState(null);
  // expandedProjects: array of project ids; default expanded all on first load.
  const [expandedProjects, setExpandedProjects] = React.useState(
    (today.projects || []).map(p => p.id)
  );
  // WP9 Phase 2: filter state. `filterKinds` is {active, reading, thinking,
  // subagent, away}; entries set to false hide the corresponding segment
  // kind across all consumers (SegmentBar render-or-null, Legend chip
  // visual). `filterProjects` (Phase 4) maps projectId -> false for hidden.
  //
  // WP9 Phase 3 (2026-05-23): URL-hash restore on init + write on change,
  // following the convention in CLAUDE.md → "Claude-time visualize URL-hash
  // state". Hash key is `filters` and its value is the comma-joined list
  // of kinds that are currently ON, in canonical order
  // active,reading,thinking,subagent,away. Default-elision: when all kinds
  // are ON, the key is dropped from the hash (keeps URLs short for the
  // common "haven't customized" case).
  const [filterKinds, setFilterKinds] = React.useState(() => {
    const hash = parseHash();
    if (!hash.filters) return { ...FILTER_ALL_ON };
    const onKinds = new Set(hash.filters.split(',').filter(Boolean));
    // Sanity check: if no recognized kind matched, fall back to all-ON
    // rather than rendering an empty dashboard.
    const recognized = FILTER_KINDS.filter(k => onKinds.has(k));
    if (recognized.length === 0) return { ...FILTER_ALL_ON };
    return FILTER_KINDS.reduce((acc, k) => {
      acc[k] = onKinds.has(k);
      return acc;
    }, {});
  });
  const [filterProjects, setFilterProjects] = React.useState({});

  // WP9 Phase 3: debounced URL-hash write on filterKinds change. Mirrors
  // the viewport pattern below — replaceState (no history pollution),
  // default-elision (drop the key when state equals all-ON default),
  // canonical-order serialization (so the hash is deterministic regardless
  // of toggle sequence).
  React.useEffect(() => {
    const t = setTimeout(() => {
      const allOn = FILTER_KINDS.every(k => filterKinds[k] !== false);
      if (allOn) {
        updateHash({ filters: null });
      } else {
        const onList = FILTER_KINDS.filter(k => filterKinds[k] !== false).join(',');
        updateHash({ filters: onList });
      }
    }, 100);
    return () => clearTimeout(t);
  }, [filterKinds]);
  // WP5 Phase 1: viewport state owned by the interactive Dashboard wrapper.
  // Phase 3 extension: on initial mount, parse #viewport=<start>:<end> from
  // the URL hash and apply it; on viewport change, write back to hash
  // (debounced, replaceState). Hash convention: see CLAUDE.md →
  // "Claude-time visualize URL-hash state".
  // WP5b (2026-05-23, F9b re-entry): consolidated to call
  // `_initialViewport()` from dashboard.jsx — single source of truth for
  // viewport defaulting (multi-day target-day centering OR single-day
  // back-compat flat hour_range OR [6, 23] fallback). Previously this
  // wrapper had its own single-day-only implementation that drifted from
  // the JSX source and produced [360, 1380] for multi-day payloads.
  // _initialViewport reads from window.CT_DATA.today directly, so no
  // arguments needed.
  const _defaultViewport = React.useMemo(() => _initialViewport(), [today]);

  const [viewport, setViewport] = React.useState(() => {
    // Phase 3: read initial viewport from URL hash if present, else default.
    const hash = parseHash();
    if (hash.viewport) {
      const parts = hash.viewport.split(':').map(Number);
      if (parts.length === 2 && Number.isFinite(parts[0]) && Number.isFinite(parts[1]) && parts[0] < parts[1]) {
        return { visible_start_min: parts[0], visible_end_min: parts[1] };
      }
    }
    // WP5b: defer to _initialViewport — same multi-day-aware default used by
    // ViewportContext.createContext and _defaultViewport above.
    return _initialViewport();
  });

  // Phase 3: debounced URL-hash write on viewport change. Default-elision:
  // when viewport equals the data-derived default, drop the key entirely
  // (keeps URLs short for the common "haven't zoomed" case).
  React.useEffect(() => {
    const t = setTimeout(() => {
      const isDefault = viewport.visible_start_min === _defaultViewport.visible_start_min
        && viewport.visible_end_min === _defaultViewport.visible_end_min;
      updateHash({
        viewport: isDefault
          ? null
          : `${Math.round(viewport.visible_start_min)}:${Math.round(viewport.visible_end_min)}`,
      });
    }, 200);
    return () => clearTimeout(t);
  }, [viewport, _defaultViewport]);

  // Phase 4: expose viewport state on window for Playwright introspection.
  // The behavioral test (test_visualize_interactive.sh) reads this to assert
  // gestures actually mutate the viewport. Production users never touch it.
  React.useEffect(() => {
    window.__dashboardViewport = viewport;
  }, [viewport]);

  // Phase 4: __perfRecord — opt-in rAF fps sampler gated by `?perf=1` query.
  // When enabled, attaches a 5-second rAF-loop measuring frame intervals and
  // logs {avg_fps, min_fps, frame_count} to console. No-op when query absent.
  // Used by verify-self's perf-measurement step to record DOM-vs-canvas
  // decision against the synthetic 1-month dataset.
  React.useEffect(() => {
    if (typeof window === 'undefined' || !window.location || !window.location.search) return;
    if (!window.location.search.includes('perf=1')) return;
    let frameCount = 0;
    let lastTs = performance.now();
    let minDeltaMs = Infinity;
    let maxDeltaMs = 0;
    let running = true;
    const startTs = lastTs;
    function tick(ts) {
      if (!running) return;
      const dt = ts - lastTs;
      if (dt < minDeltaMs) minDeltaMs = dt;
      if (dt > maxDeltaMs) maxDeltaMs = dt;
      frameCount++;
      lastTs = ts;
      if (ts - startTs > 5000) {
        running = false;
        const elapsed = ts - startTs;
        const avgFps = Math.round((frameCount / elapsed) * 1000 * 10) / 10;
        const minFps = Math.round((1000 / maxDeltaMs) * 10) / 10;
        const maxFps = Math.round((1000 / minDeltaMs) * 10) / 10;
        const result = { avg_fps: avgFps, min_fps: minFps, max_fps: maxFps, frame_count: frameCount, elapsed_ms: Math.round(elapsed) };
        window.__perfResult = result;
        console.log('[perfRecord]', JSON.stringify(result));
        return;
      }
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
    return () => { running = false; };
  }, []);

  // WP8: 'custom' is rendered using the same DayTimeline as Day (the data
  // shape is identical — build_range_data emits a multi-day union under
  // today). isDayLike is the union — both Day and Custom share the
  // DayTimeline-based timeline body. The dateLabel-vs-picker switch happens
  // in the Toolbar based on raw `view`, not isDayLike.
  // WP7: 'month' is its own render branch — NOT isDayLike (MonthView is a
  // calendar grid, not a timeline; bypasses DayTimeline, Minimap, side panel).
  const isDay = view === 'day';
  const isCustom = view === 'custom';
  const isMonth = view === 'month';
  const isCompare = view === 'compare';
  const isDayLike = isDay || isCustom;

  // WP11: change handler for the custom-preset RangePicker pair. When the
  // user picks both A and B ranges, write to state — the URL-hash effect
  // above writes `ranges=A:B` so a shareable URL restores the same custom
  // compare pair on reload. Pattern mirrors WP8's onRangeChange — no
  // fetch-from-browser.
  const onCompareRangeChange = React.useCallback((next) => {
    setCompareRanges(next);
  }, []);

  // WP7: nav handlers for MonthView. Click-day always triggers reload-redirect
  // toast (D3 + D7 — click-day always means "drill into this day"). Prev-month
  // is a pure client-side swap when the prev-month payload is in monthsMap;
  // otherwise reload-redirect. Next-month is always reload-redirect (no future
  // month is pre-loaded).
  //
  // v3 WP4: nav toasts emit `--window` commands instead of the removed
  // `--date`/`--month` flags. Single-day window is `YYYY-MM-DD:YYYY-MM-DD`;
  // full-month window is `YYYY-MM-01:YYYY-MM-LL` (LL = last day of month).
  const _navCmdForDay = React.useCallback((iso) => {
    return `claude-time visualize --window ${iso}:${iso}`;
  }, []);
  const _navCmdForMonth = React.useCallback((monthIso) => {
    // monthIso is "YYYY-MM". Compute last day via Date(y, m, 0).getDate() —
    // month is 1-indexed in our ISO but 0-indexed to Date; passing day=0 of
    // month=m+1 (i.e. JS-month m) yields the last day of month m.
    const [yStr, mStr] = monthIso.split('-');
    const y = parseInt(yStr, 10);
    const m = parseInt(mStr, 10);
    const lastDay = new Date(y, m, 0).getDate();
    const lastDayStr = String(lastDay).padStart(2, '0');
    return `claude-time visualize --window ${monthIso}-01:${monthIso}-${lastDayStr}`;
  }, []);
  const onDayClick = React.useCallback((iso) => {
    setNavToast({
      message: `Drill into ${iso}? Run this in your terminal to open Day view on that date:`,
      command: _navCmdForDay(iso),
    });
  }, [_navCmdForDay]);
  const onPrevMonth = React.useCallback(() => {
    const prevIso = _prevMonthIso(monthIso);
    if (!prevIso) return;
    if (monthsMap && monthsMap[prevIso]) {
      setMonthIso(prevIso);
    } else {
      setNavToast({
        message: `View ${_monthIsoToLabel(prevIso)}? Run this in your terminal to load that month:`,
        command: _navCmdForMonth(prevIso),
      });
    }
  }, [monthIso, monthsMap, _navCmdForMonth]);
  const onNextMonth = React.useCallback(() => {
    const nextIso = _nextMonthIso(monthIso);
    if (!nextIso) return;
    if (monthsMap && monthsMap[nextIso]) {
      setMonthIso(nextIso);
    } else {
      setNavToast({
        message: `View ${_monthIsoToLabel(nextIso)}? Run this in your terminal to load that month:`,
        command: _navCmdForMonth(nextIso),
      });
    }
  }, [monthIso, monthsMap, _navCmdForMonth]);

  // Resolve the selected session + project for the side panel.
  // WP5: uses dayPayload (= day_payloads_by_iso[dayIso]) for Day view.
  let selSession = null;
  let selProject = null;
  if (selectedSegId && isDay) {
    const [sid] = selectedSegId.split(':');
    for (const p of (dayPayload.projects || [])) {
      const s = p.sessions.find(x => x.id === sid);
      if (s) { selProject = p; selSession = s; break; }
    }
  }

  // Day-view summary stats. WP5: read from dayPayload, not today.
  const dayTotals = (() => {
    if (dayPayload.empty || !(dayPayload.projects && dayPayload.projects.length)) {
      return { active: 0, reading: 0, thinking: 0,
               longest: { active: 0, project: '\u2014', start: 0, end: 0 },
               topTool: ['\u2014', 0] };
    }
    const allSegs = dayPayload.projects.flatMap(p => p.sessions.flatMap(s => s.segs));
    const active = sumActive(allSegs);
    const reading = sumKind(allSegs, 'reading');
    const thinking = sumKind(allSegs, 'thinking');
    let longest = { active: 0, project: '\u2014', start: 0, end: 0 };
    for (const p of dayPayload.projects) for (const s of p.sessions) {
      const a = sumActive(s.segs);
      if (a > longest.active) longest = { active: a, project: p.alias, start: s.start, end: s.end };
    }
    const tools = {};
    for (const p of dayPayload.projects) for (const s of p.sessions) {
      for (const [k,v] of Object.entries(s.tools || {})) tools[k] = (tools[k] || 0) + v;
    }
    const sortedTools = Object.entries(tools).sort((a,b) => b[1] - a[1]);
    return { active, reading, thinking, longest, topTool: sortedTools[0] || ['\u2014', 0] };
  })();

  const dayStats = [
    { label: 'Active', value: fmtDur(dayTotals.active), accent: CT_TOKENS.active },
    { label: 'Reading', value: fmtDur(dayTotals.reading), sub: 'between turns' },
    { label: 'Longest session',
      value: dayTotals.longest.active > 0 ? fmtDur(dayTotals.longest.active) : '\u2014',
      sub: dayTotals.longest.active > 0
        ? `${dayTotals.longest.project} \u00b7 ${fmtClock(dayTotals.longest.start)}`
        : '' },
    { label: 'Most-used tool',
      value: dayTotals.topTool[0] || '\u2014',
      sub: dayTotals.topTool[1] > 0 ? `${dayTotals.topTool[1]} calls` : '' },
  ];

  // WP6: Week-view aggregates derive from weekPayload (the active week's
  // payload). For non-Week views, weekPayload === week (the alias) via the
  // useMemo fallback — these reads remain valid because they're only consumed
  // when isDayLike === false (Week view) anyway, where mondayIso is in scope.
  const weekActiveTotal = weekPayload.projects.reduce(
    (a, p) => a + p.rollup.reduce((b, d) => b + d.active + d.subagent, 0), 0);
  const weekProjectActive = weekPayload.projects
    .map(p => ({ alias: p.alias, total: p.rollup.reduce((a, d) => a + d.active + d.subagent, 0) }))
    .sort((a,b) => b.total - a.total);
  const weekActiveDays = weekPayload.projects.length
    ? new Set(
        weekPayload.projects.flatMap(p => p.rollup.map((d, i) => (d.active + d.subagent > 0) ? i : -1).filter(x => x >= 0))
      ).size
    : 0;
  const weekStats = [
    { label: 'Active', value: fmtDur(weekActiveTotal), accent: CT_TOKENS.active },
    { label: 'Daily avg',
      value: weekActiveDays > 0 ? fmtDur(Math.round(weekActiveTotal / weekActiveDays)) : '\u2014',
      sub: weekActiveDays > 0 ? `${weekActiveDays} active days` : '' },
    { label: 'Top project',
      value: weekProjectActive[0]?.alias || '\u2014',
      sub: weekProjectActive[0] ? fmtDur(weekProjectActive[0].total) : '' },
    { label: 'Most-used tool', value: '\u2014', sub: '' },
  ];

  const filterChips = isCustom
    ? [{ field: 'date', value: `${range.start} \u2192 ${range.end}` }]
    : (isDay ? [{ field: 'date', value: 'Today' }] : [{ field: 'date', value: 'This week' }]);

  // WP5 Phase 2: provide both viewport (read) and setViewport (write) via
  // the same Context. Memoize the value object so leaf consumers that only
  // read viewport don't re-render on every Dashboard render — the object
  // identity stays stable as long as viewport hasn't changed.
  const viewportCtxValue = React.useMemo(
    () => ({ viewport, setViewport }),
    [viewport]
  );

  // WP9 Phase 2: memoize FilterContext value so SegmentBar leaf consumers
  // re-render only when filterKinds or filterProjects actually change.
  const filterCtxValue = React.useMemo(
    () => ({ kinds: filterKinds, setKinds: setFilterKinds,
             projects: filterProjects, setProjects: setFilterProjects }),
    [filterKinds, filterProjects]
  );

  return (
    <FilterContext.Provider value={filterCtxValue}>
    <ViewportContext.Provider value={viewportCtxValue}>
    <div style={{
      width: '100%', height: '100%',
      background: CT_TOKENS.bg,
      fontFamily: CT_TOKENS.sans,
      color: CT_TOKENS.textPrimary,
      display: 'flex', flexDirection: 'column',
      overflow: 'hidden',
    }}>
      {/* WP9 (2026-05-23): Toolbar is now defined in dashboard.jsx
          (duality collapsed — see CLAUDE.md "Design-as-data" convention).
          WP8 (2026-05-24): Toolbar now receives range props for the Custom
          view's date-range picker. When view !== 'custom' the range props
          are ignored by Toolbar (the read-only dateLabel slot renders). */}
      <Toolbar
        view={view}
        onViewChange={setView}
        dateLabel={isCustom ? `${range.start} → ${range.end}` : (isDay ? dayPayload.label : weekPayload.label)}
        snapshot={(window.CT_DATA.meta && window.CT_DATA.meta.snapshot) || null}
        rangeStart={range.start}
        rangeEnd={range.end}
        onRangeChange={onRangeChange}
        maxRangeDays={window.CT_MAX_RANGE_DAYS || 90}
        monthIso={monthIso}
        onPrevMonth={onPrevMonth}
        onNextMonth={onNextMonth}
        dayIso={dayIso}
        onPrevDay={onPrevDay}
        onNextDay={onNextDay}
        prevDayDisabled={prevDayDisabled}
        nextDayDisabled={nextDayDisabled}
        mondayIso={mondayIso}
        onPrevWeek={onPrevWeek}
        onNextWeek={onNextWeek}
        prevWeekDisabled={prevWeekDisabled}
        nextWeekDisabled={nextWeekDisabled}
      />
      {/* WP10: HeadlineCard — three numbers above the timeline; chevron
          expands to MetricsPanel. View-mode-independent (window is always
          trailing-7-days from snapshot regardless of Day/Week/Month/Custom). */}
      {window.CT_DATA.metrics && (
        <HeadlineCard
          metrics={window.CT_DATA.metrics}
          expanded={metricsExpanded}
          onToggleExpanded={() => setMetricsExpanded(v => !v)}
        />
      )}
      {window.CT_DATA.metrics && metricsExpanded && (
        <MetricsPanel metrics={window.CT_DATA.metrics} />
      )}
      <SummaryStrip
        filterChips={filterChips}
        stats={isDayLike ? dayStats : weekStats}
      />

      {/* Date header strip.
          WP7: Month view shows the month name + day-count summary. */}
      <div style={{
        height: 34, flexShrink: 0,
        display: 'flex', alignItems: 'center',
        padding: '0 20px',
        gap: 14,
        background: CT_TOKENS.bg,
        borderBottom: `1px solid ${CT_TOKENS.border}`,
      }}>
        <span style={{
          fontFamily: CT_TOKENS.mono, fontSize: 11,
          color: CT_TOKENS.textSecondary, letterSpacing: '0.08em',
          textTransform: 'uppercase', fontWeight: 500,
        }}>{isMonth
          ? _monthIsoToLabel(monthIso)
          : (isDayLike ? dayPayload.label : weekPayload.label)}</span>
        <span style={{ width: 1, height: 14, background: CT_TOKENS.border }} />
        <span style={{
          fontFamily: CT_TOKENS.sans, fontSize: 11,
          color: CT_TOKENS.textTertiary,
        }}>{isMonth
          ? (monthsMap && monthsMap[monthIso] && monthsMap[monthIso].projects
              ? `${monthsMap[monthIso].projects.length} projects \u00b7 ${monthsMap[monthIso].meta?.day_count || '\u2014'} days`
              : '\u2014')
          : (isDayLike
              ? `${(dayPayload.projects || []).length} projects \u00b7 ${(dayPayload.projects || []).reduce((a,p)=>a+p.sessions.length,0)} sessions`
              : `${weekPayload.projects.length} projects \u00b7 7 days`)}</span>
        <span style={{ flex: 1 }} />
        <Legend />
        {/* WP9 Phase 4 + WP8: per-project filter popover. Day/Custom views:
            dayPayload.projects (Custom is multi-day Day-like; WP5 routes Day
            via dayPayload, Custom still reads the `today` alias key which
            useMemo aliases to dayPayload by identity). Week view:
            weekPayload.projects (WP6 routes Week via weekPayload; shares
            .id + .alias with the v2 `week` alias which is the useMemo
            fallback). WP7: Month view: filter
            chips are visible-but-inert per D4 — the popover stays mounted
            (uses dayPayload.projects as the project source for consistency)
            but Month view ignores filter state. */}
        <ProjectFilterPopover projects={isMonth ? (monthsMap && monthsMap[monthIso] ? monthsMap[monthIso].projects : (dayPayload.projects || [])) : (isDayLike ? (dayPayload.projects || []) : weekPayload.projects)} />
      </div>

      {/* Body — timeline OR month grid (+ optional side panel).
          WP7: Month view is a parallel branch — bypasses the lane-based
          timeline entirely. No side panel in Month view.
          WP8: isCustom shares isDay's DayTimeline rendering path (data shape
          is identical — build_range_data is the same multi-day union used
          by WP5b's Day view). The only Custom-specific bit is the
          empty-state label. */}
      {/* WP11: PresetSelector sub-tabs render below the date-header strip,
          above the body, but only when in compare view. */}
      {isCompare && (
        <PresetSelector
          preset={preset}
          onPresetChange={setPreset}
          compareRangeA={compareRanges.a}
          compareRangeB={compareRanges.b}
          onCompareRangeChange={onCompareRangeChange}
          maxRangeDays={window.CT_MAX_RANGE_DAYS || 90}
        />
      )}
      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>
        {isCompare ? (
          <CompareView comparison={window.CT_DATA.comparison} />
        ) : isMonth ? (
          (monthsMap && monthsMap[monthIso]) ? (
            <MonthView
              monthIso={monthIso}
              payload={monthsMap[monthIso]}
              onDayClick={onDayClick}
            />
          ) : (
            <EmptyState date={`${_monthIsoToLabel(monthIso)} — no data loaded`} />
          )
        ) : isDayLike ? (
          dayPayload.empty ? (
            <EmptyState date={isCustom
              ? `${range.start} to ${range.end}`
              : (dayPayload.iso || dayPayload.meta?.start || '\u2014')} />
          ) : (
            <DayTimeline
              data={dayPayload}
              expandedProjects={expandedProjects}
              selectedSegId={selectedSegId}
              onSelectSeg={setSelectedSegId}
            />
          )
        ) : (
          <WeekTimeline data={weekPayload} />
        )}
        {!isMonth && !isCompare && selSession && (
          <SidePanel
            session={selSession}
            project={selProject}
            segment={null}
            onClose={() => setSelectedSegId(null)}
          />
        )}
      </div>
      {/* WP5 Phase 3 + WP8: minimap (Day/Custom views — re-orientation aid
          after deep zoom). Custom shares the Day-like multi-day data shape
          so Minimap works identically. WP7: Month view skips the minimap —
          the calendar grid IS the navigation surface. WP11: Compare view
          also skips (it's an aggregate-bars view, not a timeline). */}
      {isDayLike && !isCompare && !dayPayload.empty && (
        <Minimap data={dayPayload} />
      )}
      {/* WP7: nav toast (renders only when a click/nav requires reload-redirect). */}
      {navToast && (
        <MonthNavToast
          message={navToast.message}
          command={navToast.command}
          onDismiss={() => setNavToast(null)}
        />
      )}
    </div>
    </ViewportContext.Provider>
    </FilterContext.Provider>
  );
}

/* ── Empty state (no events in window) ────────────────────────── */
function EmptyState({ date }) {
  return (
    <div style={{
      flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: CT_TOKENS.surface,
    }}>
      <div style={{ textAlign: 'center', maxWidth: 360 }}>
        <div style={{
          fontFamily: CT_TOKENS.sans, fontSize: 13,
          color: CT_TOKENS.textSecondary, fontWeight: 500,
          marginBottom: 6,
        }}>No tracked time on {date}</div>
        <div style={{
          fontFamily: CT_TOKENS.sans, fontSize: 11.5,
          color: CT_TOKENS.textTertiary,
        }}>Use Claude Code on this date and re-run <code style={{
          fontFamily: CT_TOKENS.mono, padding: '1px 4px',
          background: CT_TOKENS.surfaceAlt, borderRadius: 3,
        }}>claude-time visualize</code> to refresh.</div>
      </div>
    </div>
  );
}

window.Dashboard = Dashboard;
"""


def _wire_bar_click(jsx: str) -> str:
    """Make SegmentBar and SessionRow accept an onSelect callback so a click
    propagates the selection back to the Dashboard wrapper's state.

    Approach: SegmentBar gains an onClick that calls a prop `onSelect`;
    SessionRow accepts onSelectSeg and passes (sessionId, segIndex) to it.
    DayTimeline accepts onSelectSeg and forwards it.
    """
    # 1. SegmentBar — add onSelect prop + onClick handler.
    # WP5b: source now carries `dayOffset = 0` in the SegmentBar signature;
    # the transform appends onClick after it.
    old_segmentbar = "function SegmentBar({ seg, selected = false, dayOffset = 0 }) {"
    new_segmentbar = "function SegmentBar({ seg, selected = false, dayOffset = 0, onClick }) {"
    if old_segmentbar not in jsx:
        raise ValueError("SegmentBar signature not found — has dashboard.jsx changed?")
    jsx = jsx.replace(old_segmentbar, new_segmentbar)

    # Find the SegmentBar return div and add onClick (interrupt-non-blocking
    # ordering is preserved because click handler attaches to the parent div).
    old_segdiv = "title={`${seg.kind} \u00b7 ${fmtClock(seg.start)}\u2013${fmtClock(seg.end)}`}"
    new_segdiv = ("title={`${seg.kind} \u00b7 ${fmtClock(seg.start)}\u2013${fmtClock(seg.end)}`}\n"
                  "      onClick={onClick}")
    if old_segdiv not in jsx:
        raise ValueError("SegmentBar title attribute not found — has dashboard.jsx changed?")
    jsx = jsx.replace(old_segdiv, new_segdiv)

    # Add `cursor: 'pointer'` to the SegmentBar inline style.
    old_segstyle = "        ...segStyle(seg.kind),"
    new_segstyle = "        ...segStyle(seg.kind),\n        cursor: onClick ? 'pointer' : 'default',"
    if old_segstyle not in jsx:
        raise ValueError("SegmentBar segStyle line not found — has dashboard.jsx changed?")
    jsx = jsx.replace(old_segstyle, new_segstyle, 1)

    # 2. SessionRow — accept onSelectSeg prop, pass it down to SegmentBar.
    old_sessionrow_sig = ("function SessionRow({ session, alt = false, "
                          "selectedSegId = null, onSelect, lastInGroup = false }) {")
    new_sessionrow_sig = ("function SessionRow({ session, alt = false, "
                          "selectedSegId = null, onSelectSeg, lastInGroup = false }) {")
    if old_sessionrow_sig not in jsx:
        raise ValueError("SessionRow signature not found — has dashboard.jsx changed?")
    jsx = jsx.replace(old_sessionrow_sig, new_sessionrow_sig)

    # Wire SegmentBar's onClick. Replace the existing render line.
    # WP5b: source now passes `dayOffset={dayOffset}` to SegmentBar; the
    # transform must match that form (otherwise the replacement fails silently
    # and onClick selection breaks). InterruptHairlines also takes dayOffset
    # so per-session interrupt minutes shift into minute-of-window.
    old_segbar_render = ("        {session.segs.map((seg, i) => (\n"
                        "          <SegmentBar key={i} seg={seg} dayOffset={dayOffset} "
                        "selected={`${session.id}:${i}` === selectedSegId} />\n"
                        "        ))}")
    new_segbar_render = ("        {session.segs.map((seg, i) => (\n"
                        "          <SegmentBar\n"
                        "            key={i} seg={seg} dayOffset={dayOffset}\n"
                        "            selected={`${session.id}:${i}` === selectedSegId}\n"
                        "            onClick={onSelectSeg ? () => onSelectSeg(`${session.id}:${i}`) : undefined}\n"
                        "          />\n"
                        "        ))}\n"
                        "        {/* Interrupt hairlines (Phase 3 / P3.7) */}\n"
                        "        <InterruptHairlines interrupts={session.interrupts || []} dayOffset={dayOffset} />")
    if old_segbar_render not in jsx:
        raise ValueError("SessionRow's SegmentBar map not found — has dashboard.jsx changed?")
    jsx = jsx.replace(old_segbar_render, new_segbar_render)

    # 3. DayTimeline — accept onSelectSeg and forward to SessionRow.
    old_daytimeline_sig = ("function DayTimeline({ data, expandedProjects, "
                           "selectedSegId, showNow = true }) {")
    new_daytimeline_sig = ("function DayTimeline({ data, expandedProjects, "
                           "selectedSegId, showNow = true, onSelectSeg }) {")
    if old_daytimeline_sig not in jsx:
        raise ValueError("DayTimeline signature not found — has dashboard.jsx changed?")
    jsx = jsx.replace(old_daytimeline_sig, new_daytimeline_sig)

    # Forward onSelectSeg to each SessionRow.
    # WP5b: source uses `key={s.day_iso ? \`${s.day_iso}:${s.id}\` : s.id}`
    # so cross-day session aggregation doesn't produce duplicate React keys.
    old_sessionrow_render = ("                <SessionRow\n"
                            "                  key={s.day_iso ? `${s.day_iso}:${s.id}` : s.id}\n"
                            "                  session={s}\n"
                            "                  alt={si % 2 === 1}\n"
                            "                  selectedSegId={selectedSegId}\n"
                            "                  lastInGroup={si === p.sessions.length - 1}\n"
                            "                />")
    new_sessionrow_render = ("                <SessionRow\n"
                            "                  key={s.day_iso ? `${s.day_iso}:${s.id}` : s.id}\n"
                            "                  session={s}\n"
                            "                  alt={si % 2 === 1}\n"
                            "                  selectedSegId={selectedSegId}\n"
                            "                  onSelectSeg={onSelectSeg}\n"
                            "                  lastInGroup={si === p.sessions.length - 1}\n"
                            "                />")
    if old_sessionrow_render not in jsx:
        raise ValueError("DayTimeline's SessionRow render block not found — has dashboard.jsx changed?")
    jsx = jsx.replace(old_sessionrow_render, new_sessionrow_render)

    return jsx


def _add_interrupt_hairlines(jsx: str) -> str:
    """Append the InterruptHairlines component to the (already-stripped) jsx.

    A small component that renders one thin vertical line per minute value in
    `interrupts`, positioned by the same DAY-coord percentage math as segments.
    Called AFTER _strip_design_wrapper, so the design wrapper marker is gone;
    we append at the end (before _interactive_dashboard concatenates its own
    wrapper).
    """
    component = r"""
/* ── Interrupt hairlines (Phase 3 / P3.7) ───────────────────── */
function InterruptHairlines({ interrupts, dayOffset = 0 }) {
  // Hook must run unconditionally — call before the early return.
  // WP5 Phase 1 fix-up (caught at WP5 Phase 3 verify-human, 2026-05-22):
  // this component originally read module-level day-bound constants that
  // Phase 1 deleted as part of the viewport refactor. It now reads the
  // same ViewportContext as SegmentBar.
  // WP5b: dayOffset added so multi-day sessions place interrupts at
  // minute-of-window, matching their segment positioning.
  const viewport = useViewport();
  if (!interrupts || interrupts.length === 0) return null;
  const range = viewport.visible_end_min - viewport.visible_start_min;
  return (
    <>
      {interrupts.map((minute, i) => {
        const leftPct = (((minute + dayOffset) - viewport.visible_start_min) / range) * 100;
        // Don't render hairlines outside the visible viewport.
        if (leftPct < 0 || leftPct > 100) return null;
        return (
          <div key={i} title={`mid-turn interrupt at ${fmtClock(minute)}`} style={{
            position: 'absolute',
            top: 4, bottom: 4,
            left: `${leftPct}%`,
            width: 1.25,
            background: 'oklch(0.55 0.18 25 / 0.5)',
            pointerEvents: 'none',
            zIndex: 2,
          }} />
        );
      })}
    </>
  );
}

"""
    return jsx + component


def render_html(template_path: Path, dashboard_jsx_path: Path,
                data: dict, initial_view: str = "day",
                max_range_days: int = 90,
                initial_preset: str | None = None) -> str:
    """Read template + dashboard.jsx, apply transforms, return the rendered HTML.

    WP8: `max_range_days` is the server-side cap for the Custom-view date-range
    picker, threaded through `window.CT_MAX_RANGE_DAYS` so client-side
    validation matches the CLI's `viz_custom_range_max_days` config (default
    90). Phase 1 emits the value; Phase 2 reads it from the picker.

    WP11: `initial_preset` is the Compare-view preset chosen at emit time —
    one of 'wow', 'today-vs-trailing', 'mom', 'custom', or None. In v3 this
    is always None (the unified `--window` emit doesn't pick a preset; URL
    hash drives Compare-view selection client-side). Threaded through
    `window.CT_INITIAL_PRESET` as a JS literal (string or null).
    """
    template = template_path.read_text()
    jsx = dashboard_jsx_path.read_text()

    # Apply transforms in order:
    jsx = _strip_design_wrapper(jsx)
    jsx = _wire_bar_click(jsx)
    jsx = _add_interrupt_hairlines(jsx)
    jsx = jsx + _interactive_dashboard()

    # JSON-encode data; embed as a literal so the browser's JSON.parse path
    # is bypassed (this is JS-literal, not JSON-in-a-string).
    data_literal = json.dumps(data, ensure_ascii=False)
    # JSON-encode initial_preset so the emitted JS gets a quoted string or
    # `null` — no manual quoting, no injection surface from preset values
    # (which are constrained to argparse choices on the CLI side anyway).
    preset_literal = json.dumps(initial_preset, ensure_ascii=False)

    html = template.replace("{{CT_DATA_JSON}}", data_literal)
    html = html.replace("{{DASHBOARD_JSX}}", jsx)
    html = html.replace("{{CT_INITIAL_VIEW}}", initial_view)
    html = html.replace("{{CT_MAX_RANGE_DAYS}}", str(int(max_range_days)))
    html = html.replace("{{CT_INITIAL_PRESET}}", preset_literal)
    return html
