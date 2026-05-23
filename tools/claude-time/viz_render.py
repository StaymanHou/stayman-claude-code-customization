"""Render the claude-time dashboard to a self-contained HTML file.

Reads `viz/template.html` + `viz/dashboard.jsx`, applies transforms that:
  1. Strip the Phase 1 design-canvas-style `Dashboard({variant})` wrapper
     and replace it with an interactive `Dashboard()` (no props) that uses
     `useState` for current view (day|week) and selected session segment.
  2. Wire toolbar tabs (Today/Week) to switch view state.
  3. Wire bar clicks to set the selected segment + show side panel.
  4. Disable Month/Custom tabs visually.
  5. Add the refresh-icon tooltip ("run: claude-time visualize").
  6. Render `interrupts: [<minutes>]` as vertical hairlines inside the
     active bar (Phase 2 added the data; Phase 3 renders it).
  7. Render a `snapshot: HH:MM` caption in the toolbar (WP2). The caption
     reads `window.CT_DATA.meta.snapshot`, populated by `_cmd_visualize`
     in `claude-time` at emit time. Coexists with the live NOW marker
     (computed client-side via `useNowMin()` in `dashboard.jsx`): the
     cursor moves, the bars don't — the caption is how the user is told.

Historically (v1) `viz/dashboard.jsx` was treated as immutable and Phase 5c
byte-pinned it. Starting with the v2 cycle (claude-time-visualize-v2,
2026-05-19), direct source edits to `dashboard.jsx` and `data.js` are
permitted — the byte-pin is relaxed for those two files. The emit-time
transforms below remain as the *additive* layer that wires interactivity
on top of the (now-editable) design source. See `CLAUDE.md` →
"Design-as-data" convention for the full history.

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
    """
    # Locate the `/* ── Dashboard wrapper ── */` comment block and everything after.
    marker = "/* \u2500\u2500 Dashboard wrapper \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */"
    idx = jsx.find(marker)
    if idx == -1:
        # Fall back to less-strict marker matching (in case unicode dashes drift).
        idx = jsx.find("Dashboard wrapper")
        if idx == -1:
            raise ValueError("dashboard.jsx: cannot locate the Dashboard wrapper comment marker")
        # Back up to start of the line containing the marker.
        line_start = jsx.rfind("\n", 0, idx)
        idx = line_start + 1 if line_start >= 0 else 0
    return jsx[:idx]


def _interactive_dashboard() -> str:
    """The replacement Dashboard wrapper for the shipped HTML.

    Uses useState to switch between day/week views, manage selected segment
    (for side panel), and track which projects are expanded.
    """
    return r"""
/* ── Dashboard wrapper (interactive, shipped variant) ───────── */
function Dashboard() {
  const { today, week } = window.CT_DATA;
  const initialView = (window.CT_INITIAL_VIEW === 'week') ? 'week' : 'day';

  const [view, setView] = React.useState(initialView);
  // selectedSegId is "<sessionId>:<segIndex>" or null.
  const [selectedSegId, setSelectedSegId] = React.useState(null);
  // expandedProjects: array of project ids; default expanded all on first load.
  const [expandedProjects, setExpandedProjects] = React.useState(
    (today.projects || []).map(p => p.id)
  );
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

  const isDay = view === 'day';

  // Resolve the selected session + project for the side panel.
  let selSession = null;
  let selProject = null;
  if (selectedSegId && isDay) {
    const [sid] = selectedSegId.split(':');
    for (const p of today.projects) {
      const s = p.sessions.find(x => x.id === sid);
      if (s) { selProject = p; selSession = s; break; }
    }
  }

  // Day-view summary stats.
  const dayTotals = (() => {
    if (today.empty || !today.projects.length) {
      return { active: 0, reading: 0, thinking: 0,
               longest: { active: 0, project: '\u2014', start: 0, end: 0 },
               topTool: ['\u2014', 0] };
    }
    const allSegs = today.projects.flatMap(p => p.sessions.flatMap(s => s.segs));
    const active = sumActive(allSegs);
    const reading = sumKind(allSegs, 'reading');
    const thinking = sumKind(allSegs, 'thinking');
    let longest = { active: 0, project: '\u2014', start: 0, end: 0 };
    for (const p of today.projects) for (const s of p.sessions) {
      const a = sumActive(s.segs);
      if (a > longest.active) longest = { active: a, project: p.alias, start: s.start, end: s.end };
    }
    const tools = {};
    for (const p of today.projects) for (const s of p.sessions) {
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

  const weekActiveTotal = week.projects.reduce(
    (a, p) => a + p.rollup.reduce((b, d) => b + d.active + d.subagent, 0), 0);
  const weekProjectActive = week.projects
    .map(p => ({ alias: p.alias, total: p.rollup.reduce((a, d) => a + d.active + d.subagent, 0) }))
    .sort((a,b) => b.total - a.total);
  const weekActiveDays = week.projects.length
    ? new Set(
        week.projects.flatMap(p => p.rollup.map((d, i) => (d.active + d.subagent > 0) ? i : -1).filter(x => x >= 0))
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

  const filterChips = isDay
    ? [{ field: 'date', value: 'Today' }]
    : [{ field: 'date', value: 'This week' }];

  // WP5 Phase 2: provide both viewport (read) and setViewport (write) via
  // the same Context. Memoize the value object so leaf consumers that only
  // read viewport don't re-render on every Dashboard render — the object
  // identity stays stable as long as viewport hasn't changed.
  const viewportCtxValue = React.useMemo(
    () => ({ viewport, setViewport }),
    [viewport]
  );

  return (
    <ViewportContext.Provider value={viewportCtxValue}>
    <div style={{
      width: '100%', height: '100%',
      background: CT_TOKENS.bg,
      fontFamily: CT_TOKENS.sans,
      color: CT_TOKENS.textPrimary,
      display: 'flex', flexDirection: 'column',
      overflow: 'hidden',
    }}>
      <InteractiveToolbar
        view={view}
        onViewChange={setView}
        dateLabel={isDay ? today.label : week.label}
        snapshot={(window.CT_DATA.meta && window.CT_DATA.meta.snapshot) || null}
      />
      <SummaryStrip
        filterChips={filterChips}
        stats={isDay ? dayStats : weekStats}
      />

      {/* Date header strip */}
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
        }}>{isDay ? today.label : week.label}</span>
        <span style={{ width: 1, height: 14, background: CT_TOKENS.border }} />
        <span style={{
          fontFamily: CT_TOKENS.sans, fontSize: 11,
          color: CT_TOKENS.textTertiary,
        }}>{isDay
          ? `${today.projects.length} projects \u00b7 ${today.projects.reduce((a,p)=>a+p.sessions.length,0)} sessions`
          : `${week.projects.length} projects \u00b7 7 days`}</span>
        <span style={{ flex: 1 }} />
        <Legend />
      </div>

      {/* Body — timeline (+ optional side panel) */}
      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>
        {isDay ? (
          today.empty ? (
            <EmptyState date={today.iso} />
          ) : (
            <DayTimeline
              data={today}
              expandedProjects={expandedProjects}
              selectedSegId={selectedSegId}
              onSelectSeg={setSelectedSegId}
            />
          )
        ) : (
          <WeekTimeline data={week} />
        )}
        {selSession && (
          <SidePanel
            session={selSession}
            project={selProject}
            segment={null}
            onClose={() => setSelectedSegId(null)}
          />
        )}
      </div>
      {/* WP5 Phase 3: minimap (Day view only — re-orientation aid after deep zoom) */}
      {isDay && !today.empty && (
        <Minimap data={today} />
      )}
    </div>
    </ViewportContext.Provider>
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

/* ── Toolbar — interactive variant with view switching ────────── */
function InteractiveToolbar({ view, onViewChange, dateLabel, snapshot }) {
  const tabBtn = (label, value, current, enabled = true) => (
    <button
      key={value}
      onClick={enabled ? () => onViewChange(value) : undefined}
      disabled={!enabled}
      style={{
        background: current ? CT_TOKENS.surface : 'transparent',
        color: !enabled ? CT_TOKENS.textMuted
             : current ? CT_TOKENS.textPrimary : CT_TOKENS.textSecondary,
        border: 'none',
        borderRadius: 6,
        padding: '6px 12px',
        fontSize: 13,
        fontWeight: current ? 550 : 450,
        fontFamily: CT_TOKENS.sans,
        cursor: enabled ? 'pointer' : 'not-allowed',
        opacity: enabled ? 1 : 0.5,
        boxShadow: current ? '0 1px 2px rgba(20,18,12,0.06), inset 0 0 0 1px ' + CT_TOKENS.border : 'none',
      }}
      title={!enabled ? 'Not available in MVP' : undefined}
    >{label}</button>
  );

  return (
    <div style={{
      height: 56,
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      padding: '0 20px',
      borderBottom: `1px solid ${CT_TOKENS.border}`,
      background: CT_TOKENS.surface,
      flexShrink: 0,
    }}>
      {/* Wordmark */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{
          width: 22, height: 22, borderRadius: 5,
          background: CT_TOKENS.textPrimary,
          color: CT_TOKENS.surface,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <IconTerminal size={13} />
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
          <span style={{ fontFamily: CT_TOKENS.mono, fontSize: 13, color: CT_TOKENS.textPrimary, fontWeight: 500, letterSpacing: '-0.01em' }}>claude-time</span>
        </div>
      </div>

      <div style={{ width: 1, height: 22, background: CT_TOKENS.border, margin: '0 4px' }} />

      {/* View tabs (Today/Week functional; Month/Custom disabled) */}
      <div style={{
        display: 'flex', gap: 2, padding: 3,
        background: CT_TOKENS.surfaceDim, borderRadius: 8,
        border: `1px solid ${CT_TOKENS.border}`,
      }}>
        {tabBtn('Today', 'day', view === 'day', true)}
        {tabBtn('Week', 'week', view === 'week', true)}
        {tabBtn('Month', 'month', false, false)}
        {tabBtn('Custom', 'custom', false, false)}
      </div>

      {/* Date label (read-only) */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 6,
        padding: '6px 10px',
        background: CT_TOKENS.surfaceDim, borderRadius: 8,
        border: `1px solid ${CT_TOKENS.border}`,
        fontFamily: CT_TOKENS.mono, fontSize: 12, color: CT_TOKENS.textPrimary,
      }}>
        <IconCalendar size={12} />
        {dateLabel}
      </div>

      {/* Snapshot caption — communicates that the data is point-in-time at emit
          (the live NOW cursor moves; the bars do not until next visualize run). */}
      {snapshot && (
        <span
          title="Data is a snapshot at emit time. The live NOW cursor moves; bars do not. Re-run `claude-time visualize` for fresh data."
          style={{
            fontFamily: CT_TOKENS.mono, fontSize: 11,
            color: CT_TOKENS.textTertiary, cursor: 'help',
          }}
        >snapshot: {snapshot}</span>
      )}

      <div style={{ flex: 1 }} />

      {/* Refresh icon — tooltip-only, no action */}
      <button
        title="Re-run: claude-time visualize"
        style={{
          height: 30, width: 30,
          border: `1px solid ${CT_TOKENS.border}`,
          background: 'transparent',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          borderRadius: 7, cursor: 'help',
          color: CT_TOKENS.textSecondary,
        }}
      ><IconRefresh size={13} /></button>
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
                data: dict, initial_view: str = "day") -> str:
    """Read template + dashboard.jsx, apply transforms, return the rendered HTML."""
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

    html = template.replace("{{CT_DATA_JSON}}", data_literal)
    html = html.replace("{{DASHBOARD_JSX}}", jsx)
    html = html.replace("{{CT_INITIAL_VIEW}}", initial_view)
    return html
