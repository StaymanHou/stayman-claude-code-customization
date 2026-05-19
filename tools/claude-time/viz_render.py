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

The design contract (`viz/dashboard.jsx`) is treated as immutable — these
transforms apply text replacements rather than asking the design source to
carry interactivity-specific behavior. Phase 5c's structural-check pins the
design file's byte size; modifying it would fail that check.

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

  return (
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
    </div>
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
function InteractiveToolbar({ view, onViewChange, dateLabel }) {
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
    old_segmentbar = "function SegmentBar({ seg, selected = false }) {"
    new_segmentbar = "function SegmentBar({ seg, selected = false, onClick }) {"
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
    old_segbar_render = ("        {session.segs.map((seg, i) => (\n"
                        "          <SegmentBar key={i} seg={seg} "
                        "selected={`${session.id}:${i}` === selectedSegId} />\n"
                        "        ))}")
    new_segbar_render = ("        {session.segs.map((seg, i) => (\n"
                        "          <SegmentBar\n"
                        "            key={i} seg={seg}\n"
                        "            selected={`${session.id}:${i}` === selectedSegId}\n"
                        "            onClick={onSelectSeg ? () => onSelectSeg(`${session.id}:${i}`) : undefined}\n"
                        "          />\n"
                        "        ))}\n"
                        "        {/* Interrupt hairlines (Phase 3 / P3.7) */}\n"
                        "        <InterruptHairlines interrupts={session.interrupts || []} />")
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
    old_sessionrow_render = ("                <SessionRow\n"
                            "                  key={s.id}\n"
                            "                  session={s}\n"
                            "                  alt={si % 2 === 1}\n"
                            "                  selectedSegId={selectedSegId}\n"
                            "                  lastInGroup={si === p.sessions.length - 1}\n"
                            "                />")
    new_sessionrow_render = ("                <SessionRow\n"
                            "                  key={s.id}\n"
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
function InterruptHairlines({ interrupts }) {
  if (!interrupts || interrupts.length === 0) return null;
  return (
    <>
      {interrupts.map((minute, i) => {
        const leftPct = ((minute - DAY_START_MIN) / DAY_RANGE_MIN) * 100;
        // Don't render hairlines outside the visible day window.
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
