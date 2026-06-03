// claude-time dashboard component
// Three configurations rendered into design-canvas artboards:
//   • day view (default)
//   • week view with project rollups (one row per project, 7 day columns)
//   • day view with a bar selected and the side panel open
//
// Light theme. Warm cream surface, deep indigo for active coding,
// muted amber for thinking, desat lavender for reading, hairline
// stripes for away. Monospace for timestamps/durations.

/* ── Tokens ─────────────────────────────────────────────────── */
const CT_TOKENS = {
  bg: 'oklch(0.97 0.008 80)',
  surface: '#FFFFFF',
  surfaceAlt: 'oklch(0.955 0.008 80)',
  surfaceDim: 'oklch(0.94 0.008 80)',
  border: 'oklch(0.905 0.008 80)',
  borderStrong: 'oklch(0.85 0.008 80)',
  textPrimary: 'oklch(0.22 0.01 60)',
  textSecondary: 'oklch(0.48 0.01 60)',
  textTertiary: 'oklch(0.62 0.01 60)',
  textMuted: 'oklch(0.74 0.01 60)',

  active: 'oklch(0.42 0.17 268)',
  activeSoft: 'oklch(0.42 0.17 268 / 0.10)',
  reading: 'oklch(0.80 0.04 268)',
  thinking: 'oklch(0.74 0.11 75)',
  awayBase: 'oklch(0.93 0.008 80)',
  awayStripe: 'oklch(0.86 0.008 80)',
  subagent: 'oklch(0.55 0.10 175)',

  gridHour: 'oklch(0 0 0 / 0.04)',
  gridDay: 'oklch(0 0 0 / 0.10)',
  rowAlt: 'oklch(0.965 0.008 80)',

  sans: '"Geist", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  mono: '"Geist Mono", "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, monospace',
};

/* ── Helpers ────────────────────────────────────────────────── */
const fmtDur = (mins) => {
  if (mins < 1) return '0m';
  const h = Math.floor(mins / 60);
  const m = Math.round(mins % 60);
  if (h && m) return `${h}h ${m}m`;
  if (h) return `${h}h`;
  return `${m}m`;
};
const fmtClock = (mins) => {
  const h = Math.floor(mins / 60), m = Math.floor(mins % 60);
  return `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}`;
};
const sumActive = (segs) => segs.filter(s => s.kind === 'active' || s.kind === 'subagent').reduce((a,s) => a + (s.end - s.start), 0);
const sumKind = (segs, k) => segs.filter(s => s.kind === k).reduce((a,s) => a + (s.end - s.start), 0);

// minutes-since-midnight from a Date (local-tz)
const _nowMinFromDate = (d) => d.getHours() * 60 + d.getMinutes();
// ISO YYYY-MM-DD in local-tz (matches how viz_data emits today's `iso`)
const _todayISO = (d) => {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${dd}`;
};

// WP7: month helpers. ISO month (YYYY-MM) <-> (year, month) tuple,
// month-name labels, prev/next-month arithmetic, days-in-month.
const _MONTH_NAMES = ['January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'];
const _monthIsoToParts = (iso) => {
  // "2026-04" -> {year: 2026, month: 4}. Returns null on invalid input.
  if (typeof iso !== 'string' || !/^\d{4}-\d{2}$/.test(iso)) return null;
  const y = parseInt(iso.slice(0, 4), 10);
  const m = parseInt(iso.slice(5, 7), 10);
  if (m < 1 || m > 12) return null;
  return { year: y, month: m };
};
const _monthIsoToLabel = (iso) => {
  const p = _monthIsoToParts(iso);
  if (!p) return '\u2014';
  return `${_MONTH_NAMES[p.month - 1]} ${p.year}`;
};
const _prevMonthIso = (iso) => {
  const p = _monthIsoToParts(iso);
  if (!p) return null;
  const py = p.month === 1 ? p.year - 1 : p.year;
  const pm = p.month === 1 ? 12 : p.month - 1;
  return `${String(py).padStart(4, '0')}-${String(pm).padStart(2, '0')}`;
};
const _nextMonthIso = (iso) => {
  const p = _monthIsoToParts(iso);
  if (!p) return null;
  const ny = p.month === 12 ? p.year + 1 : p.year;
  const nm = p.month === 12 ? 1 : p.month + 1;
  return `${String(ny).padStart(4, '0')}-${String(nm).padStart(2, '0')}`;
};
const _daysInMonth = (year, month) => {
  // Standard JS trick: day 0 of next month = last day of this month.
  return new Date(year, month, 0).getDate();
};
// Monday-first day-of-week index (0 = Mon ... 6 = Sun). JS Date.getDay is
// Sunday-first; we shift to match the existing Week-view convention.
const _mondayIndex = (date) => (date.getDay() + 6) % 7;

// WP7: intensity-to-color mapping for Month view day cells (D5' — GitHub
// contribution-graph style). Input is a 0..1 normalized intensity (day's
// total active+subagent minutes / month's max). 6 buckets: empty + 5
// populated steps. Empty is a faint dim background distinct from even the
// lowest populated bucket; populated buckets run from light tint to deep
// saturated active blue (the same hue family as CT_TOKENS.active so Month
// view coheres with the dashboard's overall palette).
const _MONTH_INTENSITY_PALETTE = [
  'oklch(0.965 0.005 268)',  // empty / 0 — barely-tinted background
  'oklch(0.91 0.035 268)',   // bucket 1 — very light
  'oklch(0.79 0.075 268)',   // bucket 2
  'oklch(0.62 0.13 268)',    // bucket 3 — mid
  'oklch(0.48 0.17 268)',    // bucket 4 — deeper
  'oklch(0.36 0.16 268)',    // bucket 5 — deepest
];
const _intensityColor = (intensity) => {
  if (!(intensity > 0)) return _MONTH_INTENSITY_PALETTE[0];
  // Map (0, 1] → buckets 1..5. The 5 non-empty buckets divide the (0, 1] range
  // into quintiles, but we lower-bias the boundaries slightly so a single
  // active minute on a 10-hour-max day still gets a visible bucket-1 cell
  // (otherwise low-intensity days would render almost-empty and lose signal).
  const idx = intensity >= 0.80 ? 5
            : intensity >= 0.55 ? 4
            : intensity >= 0.30 ? 3
            : intensity >= 0.10 ? 2
            : 1;
  return _MONTH_INTENSITY_PALETTE[idx];
};

// Live "now" hook: returns {nowMin, todayISO}, ticks every 60s.
function useNowMin() {
  const [tick, setTick] = React.useState(() => new Date());
  React.useEffect(() => {
    const id = setInterval(() => setTick(new Date()), 60000);
    return () => clearInterval(id);
  }, []);
  return { nowMin: _nowMinFromDate(tick), todayISO: _todayISO(tick) };
}

/* ── Segment fill ──────────────────────────────────────────── */
const segStyle = (kind) => {
  if (kind === 'active')   return { background: CT_TOKENS.active };
  if (kind === 'reading')  return { background: CT_TOKENS.reading };
  if (kind === 'thinking') return { background: CT_TOKENS.thinking };
  if (kind === 'subagent') return { background: CT_TOKENS.subagent };
  if (kind === 'away')     return {
    backgroundColor: CT_TOKENS.awayBase,
    backgroundImage: `repeating-linear-gradient(45deg, transparent 0 3px, ${CT_TOKENS.awayStripe} 3px 5px)`,
  };
  return {};
};

/* ── Icons ──────────────────────────────────────────────────── */
const Icon = ({ d, size = 14 }) => (
  <svg width={size} height={size} viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round">
    {d}
  </svg>
);
const IconChevDown   = (p) => <Icon {...p} d={<polyline points="4,6 8,10 12,6"/>} />;
const IconChevRight  = (p) => <Icon {...p} d={<polyline points="6,4 10,8 6,12"/>} />;
const IconChevLeft   = (p) => <Icon {...p} d={<polyline points="10,4 6,8 10,12"/>} />;
const IconClose      = (p) => <Icon {...p} d={<><line x1="4" y1="4" x2="12" y2="12"/><line x1="12" y1="4" x2="4" y2="12"/></>} />;
const IconSearch     = (p) => <Icon {...p} d={<><circle cx="7" cy="7" r="4"/><line x1="10" y1="10" x2="13" y2="13"/></>} />;
const IconCalendar   = (p) => <Icon {...p} d={<><rect x="2.5" y="3.5" width="11" height="10" rx="1"/><line x1="2.5" y1="6.5" x2="13.5" y2="6.5"/><line x1="5.5" y1="2" x2="5.5" y2="5"/><line x1="10.5" y1="2" x2="10.5" y2="5"/></>} />;
const IconFilter     = (p) => <Icon {...p} d={<polyline points="2,3 14,3 9.5,8.5 9.5,13 6.5,12 6.5,8.5"/>} />;
const IconMoon       = (p) => <Icon {...p} d={<path d="M12.5 9.5A5 5 0 016.5 3.5a5 5 0 106 6z"/>} />;
const IconRefresh    = (p) => <Icon {...p} d={<><polyline points="13,3 13,6 10,6"/><path d="M13 6A5 5 0 003 8a5 5 0 005 5 5 5 0 004.5-2.8"/></>} />;
const IconTerminal   = (p) => <Icon {...p} d={<><rect x="2" y="3" width="12" height="10" rx="1"/><polyline points="5,7 7,9 5,11"/><line x1="8.5" y1="11" x2="11" y2="11"/></>} />;

/* ── Toolbar — interactive (shipped variant; WP9 duality collapse 2026-05-23) ── */
// History: prior to WP9, this file hosted a static design-canvas Toolbar
// (props: activeRange/activeZoom/dateLabel/dark) and viz_render.py appended a
// parallel InteractiveToolbar at emit time. WP9 collapsed the duality into the
// single interactive Toolbar below; viz_render.py no longer emits a Toolbar
// component. See CLAUDE.md → "Design-as-data" convention for the full history.
/* WP8: client-side range validator. Mirrors _parse_range_flag (Python).
   Returns null on valid input; on invalid input, returns a short string
   naming the rule that failed (used as the tooltip + visual cue).
   maxDays defaults to 90 (matches Python's viz_custom_range_max_days
   default); the caller passes `window.CT_MAX_RANGE_DAYS` so the cap is
   single-sourced from Python config. */
function validateRange(startIso, endIso, maxDays) {
  const ISO_RE = /^\d{4}-\d{2}-\d{2}$/;
  if (!startIso || !endIso) return 'Pick both start and end dates.';
  if (!ISO_RE.test(startIso) || !ISO_RE.test(endIso)) {
    return 'Dates must be in YYYY-MM-DD form.';
  }
  // Date.parse('YYYY-MM-DD') is UTC-anchored, which is fine for day-level math.
  const startMs = Date.parse(startIso);
  const endMs = Date.parse(endIso);
  if (Number.isNaN(startMs) || Number.isNaN(endMs)) {
    return 'One of the dates is not a real date.';
  }
  if (endMs < startMs) return 'End date must be on or after start date.';
  // Today is local-midnight in UTC for the purposes of this comparison.
  // We avoid timezone-of-day complexity: the CLI uses date.today() which is
  // local; the browser's `new Date()` is also local. Compare ISO strings of
  // both — sortable, no tz drift.
  const todayIso = new Date().toISOString().slice(0, 10);
  if (endIso > todayIso) return 'End date must not be in the future.';
  const dayCount = Math.round((endMs - startMs) / 86400000) + 1;
  if (dayCount > maxDays) {
    return `Range too long (${dayCount} days > ${maxDays}). Narrow the range.`;
  }
  return null;
}

function Toolbar({ view = 'day', onViewChange = () => {}, dateLabel, snapshot,
                   rangeStart = null, rangeEnd = null, onRangeChange = () => {},
                   maxRangeDays = 90,
                   monthIso = null, onPrevMonth = () => {}, onNextMonth = () => {},
                   dayIso = null, onPrevDay = () => {}, onNextDay = () => {},
                   prevDayDisabled = false, nextDayDisabled = false }) {
  // WP8: when view === 'custom', the read-only dateLabel slot is replaced by
  // a RangePicker — two <input type=date> controls with client-side validation
  // matching the CLI's _parse_range_flag rules. Local state buffers in-progress
  // edits; only valid (shape + end>=start + end<=today + days<=maxRangeDays)
  // tuples propagate via onRangeChange on blur. Invalid intermediate states
  // (e.g. typing "2026-05-0" mid-keystroke) get a red border + a tooltip
  // naming the rule that failed; the parent's range stays unchanged.
  const tabBtn = (label, value, current, enabled = true) => (
    <button
      key={value}
      data-tab={value}
      aria-selected={current ? 'true' : 'false'}
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

      {/* Toolbar label is 'Day' (WP6); data-layer key remains window.CT_DATA.today (stable contract for WP5b consumers). */}
      {/* View tabs (Day/Week/Month/Custom — all functional as of WP7).
          WP7 enabled Month — its body is the calendar-grid MonthView; the
          dateLabel slot becomes month name + prev/next arrows (D1).
          WP8 enabled Custom — its body is the date-range picker. */}
      <div style={{
        display: 'flex', gap: 2, padding: 3,
        background: CT_TOKENS.surfaceDim, borderRadius: 8,
        border: `1px solid ${CT_TOKENS.border}`,
      }}>
        {tabBtn('Day', 'day', view === 'day', true)}
        {tabBtn('Week', 'week', view === 'week', true)}
        {tabBtn('Month', 'month', view === 'month', true)}
        {tabBtn('Custom', 'custom', view === 'custom', true)}
        {tabBtn('Compare', 'compare', view === 'compare', true)}
      </div>

      {/* WP7: when view === 'month', the dateLabel slot becomes a month-nav
          control: prev arrow, month name (e.g. "April 2026"), next arrow.
          The prev arrow does a client-side state swap (D1) when prev-month
          is pre-loaded; otherwise + next arrow trigger the reload-redirect
          (toast + clipboard, P2.5 resolution).
          WP8: when view === 'custom', the slot becomes a date-range picker.
          Otherwise the slot stays read-only. */}
      {view === 'day' ? (
        /* WP5 (v3): Day-nav ‹/› buttons flank the date label for client-side
           swaps between pre-rendered days in day_payloads_by_iso. Buttons are
           disabled at window boundaries (earliest day → prev disabled; most-
           recent day → next disabled). Mirrors the month-nav pattern below. */
        <div
          data-day-iso={dayIso || ''}
          style={{
            display: 'flex', alignItems: 'center', gap: 4,
            background: CT_TOKENS.surfaceDim, borderRadius: 8,
            border: `1px solid ${CT_TOKENS.border}`,
            padding: 2,
          }}
        >
          <button
            data-day-nav="prev"
            onClick={prevDayDisabled ? undefined : onPrevDay}
            disabled={prevDayDisabled}
            title="Previous day"
            style={{
              height: 28, width: 28, border: 'none', background: 'transparent',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              borderRadius: 5,
              cursor: prevDayDisabled ? 'not-allowed' : 'pointer',
              color: CT_TOKENS.textSecondary,
              opacity: prevDayDisabled ? 0.4 : 1,
              fontSize: 14, fontFamily: CT_TOKENS.mono,
            }}
          >{'\u2039'}</button>
          <span style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '0 8px',
            fontFamily: CT_TOKENS.mono, fontSize: 12, color: CT_TOKENS.textPrimary,
            minWidth: 100, textAlign: 'center', justifyContent: 'center',
          }}>
            <IconCalendar size={12} />
            {dateLabel}
          </span>
          <button
            data-day-nav="next"
            onClick={nextDayDisabled ? undefined : onNextDay}
            disabled={nextDayDisabled}
            title="Next day"
            style={{
              height: 28, width: 28, border: 'none', background: 'transparent',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              borderRadius: 5,
              cursor: nextDayDisabled ? 'not-allowed' : 'pointer',
              color: CT_TOKENS.textSecondary,
              opacity: nextDayDisabled ? 0.4 : 1,
              fontSize: 14, fontFamily: CT_TOKENS.mono,
            }}
          >{'\u203A'}</button>
        </div>
      ) : view === 'month' ? (
        <div style={{
          display: 'flex', alignItems: 'center', gap: 4,
          background: CT_TOKENS.surfaceDim, borderRadius: 8,
          border: `1px solid ${CT_TOKENS.border}`,
          padding: 2,
        }}>
          <button
            data-month-nav="prev"
            onClick={onPrevMonth}
            title="Previous month"
            style={{
              height: 28, width: 28, border: 'none', background: 'transparent',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              borderRadius: 5, cursor: 'pointer', color: CT_TOKENS.textSecondary,
              fontSize: 14, fontFamily: CT_TOKENS.mono,
            }}
          >{'\u2039'}</button>
          <span
            data-month-iso={monthIso || ''}
            style={{
              fontFamily: CT_TOKENS.mono, fontSize: 12,
              color: CT_TOKENS.textPrimary, padding: '0 8px',
              minWidth: 100, textAlign: 'center',
            }}
          >{monthIso ? _monthIsoToLabel(monthIso) : '\u2014'}</span>
          <button
            data-month-nav="next"
            onClick={onNextMonth}
            title="Next month"
            style={{
              height: 28, width: 28, border: 'none', background: 'transparent',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              borderRadius: 5, cursor: 'pointer', color: CT_TOKENS.textSecondary,
              fontSize: 14, fontFamily: CT_TOKENS.mono,
            }}
          >{'\u203A'}</button>
        </div>
      ) : view === 'custom' ? (
        <RangePicker
          startIso={rangeStart}
          endIso={rangeEnd}
          maxRangeDays={maxRangeDays}
          onChange={onRangeChange}
        />
      ) : (
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
      )}

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
const iconBtn = () => ({
  height: 24, width: 24, border: 'none', background: 'transparent',
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  borderRadius: 5, cursor: 'pointer', color: CT_TOKENS.textSecondary,
});
const iconChromeBtn = () => ({
  height: 30, width: 30, border: `1px solid ${CT_TOKENS.border}`, background: 'transparent',
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  borderRadius: 7, cursor: 'pointer', color: CT_TOKENS.textSecondary,
});

/* ── WP8: Date-range picker (Custom view's dateLabel-slot replacement) ─

   Two <input type=date> controls + a separator arrow. Local state buffers
   the in-progress edit; onChange only updates the buffer. On blur (or Enter
   key), we re-validate the (buffered start, buffered end) tuple — if valid,
   call onChange-prop with {start, end}; if invalid, keep the buffer + show
   a red-border + tooltip naming the rule that failed. data-range-picker=
   {start,end} attributes are stable selectors for Playwright behavioral
   tests in Phase 2 verify-self + WP8-P2 codify pins.

   The buffer re-syncs from props when props change (e.g. URL-hash restore
   on reload, or future "set range from CLI" plumbing). */
function RangePicker({ startIso, endIso, maxRangeDays = 90, onChange }) {
  const [bufStart, setBufStart] = React.useState(startIso || '');
  const [bufEnd, setBufEnd] = React.useState(endIso || '');
  // Re-sync buffer when prop changes (parent-driven update — e.g. hash restore).
  React.useEffect(() => { setBufStart(startIso || ''); }, [startIso]);
  React.useEffect(() => { setBufEnd(endIso || ''); }, [endIso]);

  const err = validateRange(bufStart, bufEnd, maxRangeDays);
  const commit = () => {
    if (err == null && (bufStart !== startIso || bufEnd !== endIso)) {
      onChange({ start: bufStart, end: bufEnd });
    }
  };
  const onKeyDown = (e) => { if (e.key === 'Enter') e.currentTarget.blur(); };

  const todayIso = new Date().toISOString().slice(0, 10);
  const inputStyle = (isInvalid) => ({
    padding: '4px 6px',
    border: `1px solid ${isInvalid ? '#c84a4a' : CT_TOKENS.border}`,
    borderRadius: 5,
    background: CT_TOKENS.surface,
    fontFamily: CT_TOKENS.mono,
    fontSize: 12,
    color: CT_TOKENS.textPrimary,
    width: 130,
  });

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 6,
      padding: '4px 8px',
      background: CT_TOKENS.surfaceDim, borderRadius: 8,
      border: `1px solid ${err ? '#c84a4a' : CT_TOKENS.border}`,
    }} title={err || undefined}>
      <IconCalendar size={12} />
      <input
        type="date"
        data-range-picker="start"
        value={bufStart}
        max={todayIso}
        onChange={(e) => setBufStart(e.target.value)}
        onBlur={commit}
        onKeyDown={onKeyDown}
        style={inputStyle(err != null)}
      />
      <span style={{ color: CT_TOKENS.textTertiary, fontSize: 11 }}>→</span>
      <input
        type="date"
        data-range-picker="end"
        value={bufEnd}
        max={todayIso}
        onChange={(e) => setBufEnd(e.target.value)}
        onBlur={commit}
        onKeyDown={onKeyDown}
        style={inputStyle(err != null)}
      />
    </div>
  );
}

/* ── Summary strip ──────────────────────────────────────────── */
function SummaryStrip({ filterChips, stats }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'stretch', gap: 0,
      padding: '14px 20px',
      borderBottom: `1px solid ${CT_TOKENS.border}`,
      background: CT_TOKENS.surface,
      flexShrink: 0,
    }}>
      {/* Filter chips */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, paddingRight: 16, marginRight: 16, borderRight: `1px solid ${CT_TOKENS.border}` }}>
        {filterChips.map((c, i) => (
          <span key={i} style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            padding: '4px 8px 4px 8px',
            background: CT_TOKENS.surfaceAlt,
            border: `1px solid ${CT_TOKENS.border}`,
            borderRadius: 6,
            fontSize: 11.5,
            fontFamily: CT_TOKENS.sans,
            color: CT_TOKENS.textSecondary,
          }}>
            <span style={{ color: CT_TOKENS.textTertiary, fontSize: 10.5 }}>{c.field}</span>
            <span style={{ color: CT_TOKENS.textPrimary, fontWeight: 500 }}>{c.value}</span>
            <span style={{ width: 12, height: 12, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', color: CT_TOKENS.textTertiary }}>
              <IconClose size={9} />
            </span>
          </span>
        ))}
        <button style={{
          padding: '4px 8px',
          background: 'transparent',
          border: `1px dashed ${CT_TOKENS.border}`,
          borderRadius: 6,
          fontSize: 11.5,
          fontFamily: CT_TOKENS.sans,
          color: CT_TOKENS.textTertiary,
          cursor: 'pointer',
        }}>+ Add filter</button>
      </div>

      {/* Stats */}
      <div style={{ display: 'flex', gap: 28, alignItems: 'center' }}>
        {stats.map((s, i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <div style={{
              fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
              letterSpacing: '0.06em', color: CT_TOKENS.textTertiary,
            }}>{s.label}</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
              <span style={{
                fontFamily: CT_TOKENS.mono, fontSize: 17, fontWeight: 500,
                color: s.accent || CT_TOKENS.textPrimary, letterSpacing: '-0.01em',
              }}>{s.value}</span>
              {s.sub && <span style={{ fontFamily: CT_TOKENS.sans, fontSize: 11, color: CT_TOKENS.textTertiary }}>{s.sub}</span>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ── WP10 Phase 2: Metrics surface (HeadlineCard + MetricsPanel) ───── */
// Read window.CT_DATA.metrics (emitted by Phase 1's build_metrics aggregator)
// and render two surfaces: HeadlineCard (3-tile collapsed default) and
// MetricsPanel (expanded full table). State lives in the Dashboard wrapper;
// these components are pure renderers. Filter-aware: kind + project chip
// state shrinks the headline + panel cells via _computeMetricsView.

// Duration formatter: integer ms → "Xh Ym" / "Xm Ys" / "Xs" / "0s".
const _fmtDurMs = (ms) => {
  if (!ms || ms < 0) return '0s';
  const secs = Math.floor(ms / 1000);
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const s = secs % 60;
  if (h) return `${h}h ${String(m).padStart(2, '0')}m`;
  if (m) return `${m}m ${String(s).padStart(2, '0')}s`;
  return `${s}s`;
};

// Multiplier formatter: float → "×1.49" or "—" when 0/null/undefined.
// Concurrency/blocking rows pass null to suppress the multiplier column.
const _fmtMult = (mult) => (typeof mult === 'number' && mult > 0
  ? `\u00d7${mult.toFixed(2)}`
  : '\u2014');

// Filter-aware projection of the metrics tree. Returns the same shape with
// kind/project filtering applied:
//   - subagent kind off → drop subagent from ai_agent (effort + wall reduce)
//   - reading kind off  → drop reading from human (typing + thinking only)
//   - thinking kind off → drop thinking from human (typing + reading only)
//   - active kind off   → drop ai_agent wholesale (active is the burst kind)
//   - away kind off     → blocking metric (human-blocking-agent) drops to 0
//                         (reading + thinking become the only away analogues)
//   - project filter — handled in Phase 3+ if needed; today the aggregator
//     doesn't slice by project, so popover projects are a UI-only concept
//     for headline + panel.
// `_computeMetricsView` returns a SHALLOW projection: identity for unfiltered
// cells, modified copies for filter-impacted cells. Multipliers are
// recomputed from filtered wallclock/effort to stay consistent.
function _computeMetricsView(metrics, filterKinds) {
  if (!metrics) return null;
  const k = filterKinds || {};
  // Defaults: kind ON when undefined (matches FilterContext default).
  const activeOn   = k.active   !== false;
  const readingOn  = k.reading  !== false;
  const thinkingOn = k.thinking !== false;
  const subagentOn = k.subagent !== false;
  const allKindsOn = activeOn && readingOn && thinkingOn && subagentOn;
  if (allKindsOn) return metrics;

  const m = JSON.parse(JSON.stringify(metrics)); // deep clone for mutation safety

  // active OFF → ai_agent and engaged_session collapse to 0 (active IS the
  // load-bearing kind for both metrics).
  if (!activeOn) {
    m.engaged_session = { ...m.engaged_session, wallclock_ms: 0, effort_ms: 0, multiplier: 0, session_count: 0 };
    m.ai_agent = { ...m.ai_agent, wallclock_ms: 0, effort_ms: 0, multiplier: 0,
                    subagent: { wallclock_ms: 0, effort_ms: 0, multiplier: 0 } };
    m.tool_call = { ...m.tool_call, wallclock_ms: 0, effort_ms: 0, multiplier: 0, top: [] };
    m.concurrency = m.concurrency.map(c => ({ ...c, wallclock_ms: 0, effort_ms: 0 }));
    m.blocking = { ...m.blocking, agent_blocking_human_ms: 0 };
  } else if (!subagentOn) {
    // active ON, subagent OFF → subtract subagent from ai_agent
    // (subagent intervals ⊆ ai_agent intervals — verified in reconciliation tests).
    const sa = m.ai_agent.subagent;
    const newWc = Math.max(0, m.ai_agent.wallclock_ms - sa.wallclock_ms);
    const newEff = Math.max(0, m.ai_agent.effort_ms - sa.effort_ms);
    m.ai_agent = {
      ...m.ai_agent,
      wallclock_ms: newWc,
      effort_ms: newEff,
      multiplier: newWc > 0 ? newEff / newWc : 0,
      subagent: { wallclock_ms: 0, effort_ms: 0, multiplier: 0 },
    };
    // blocking.agent_blocking_human ≡ ai_agent.wallclock_ms by definition.
    m.blocking = { ...m.blocking, agent_blocking_human_ms: newWc };
  }

  // Human kind filtering — reading/thinking come from gaps; typing is
  // always-present (it's part of every UPS submission). When a human kind
  // chip is off, drop its contribution from human total.
  let newReading = readingOn ? m.human.reading_ms : 0;
  let newThinking = thinkingOn ? m.human.thinking_ms : 0;
  // typing is not a separate filter chip; it stays.
  const newHumanTotal = m.human.typing_ms + newReading + newThinking;
  m.human = {
    ...m.human,
    reading_ms: newReading,
    thinking_ms: newThinking,
    wallclock_ms: newHumanTotal,
    effort_ms: newHumanTotal,
    // human.multiplier always 1.0 by construction (one brain).
  };

  // blocking.human_blocking_agent ≡ reading_ms + thinking_ms by definition.
  m.blocking = { ...m.blocking, human_blocking_agent_ms: newReading + newThinking };

  return m;
}

// WP11 Phase 2.A: CompareView UI — effectiveness lens (2026-05-26 re-spec).
// Replaces the prior delta-lens design (TopShiftsCallouts / PerKindSection /
// PerProjectSection / _CompareBarRow / _computeComparisonView / _topShifts /
// _sumKindTotals) that verify-human rejected as answering the wrong question.
//
// The new design sources from window.CT_DATA.comparison.{a,b}.metrics — the
// same shape as window.CT_DATA.metrics that WP10's MetricsPanel consumes.
// Filter chips apply via _computeMetricsView (WP10) called separately on each
// window. The 8 rows are rendered by a single generalized EffectivenessRow
// component dispatching on `kind` (multiplier, ratio-pct, blocking-split,
// concurrency-mix, absolute-wallclock-effort-mult, absolute-wallclock-only,
// absolute-engaged).
// WP11 Phase 2.A: signed-duration formatter for ms-valued deltas.
// Converts ms → minutes, applies _fmtSignedDur. U+2212 MINUS SIGN per Q4.
function _fmtSignedDurMs(absMs) {
  if (absMs === 0 || Math.abs(absMs) < 60_000) return '0m';
  const sign = absMs > 0 ? '+' : '\u2212';
  return `${sign}${fmtDur(Math.abs(absMs) / 60_000)}`;
}

// WP11 Phase 2.A: signed-minute formatter (kept for any legacy callers; CompareView
// uses _fmtSignedDurMs because metrics tree is ms-valued).
function _fmtSignedDur(absMin) {
  if (absMin === 0 || Math.abs(absMin) < 1) return '0m';
  const sign = absMin > 0 ? '+' : '\u2212';
  return `${sign}${fmtDur(Math.abs(absMin))}`;
}

// WP11 Phase 2.A: relative-percentage delta formatter — "(+45%)" / "(\u221212%)" / "(N/A)".
function _fmtRelPct(relPct) {
  if (relPct == null) return '(N/A)';
  if (Math.abs(relPct) < 1) return '(\u00b10%)';
  const sign = relPct > 0 ? '+' : '\u2212';
  return `(${sign}${Math.round(Math.abs(relPct))}%)`;
}

// WP11 Phase 2.A: percentage-point delta formatter — "(+8pp)" / "(\u221214pp)" / "(\u00b10pp)".
// Used for shares-of-window stats (blocking split, concurrency stratum) where
// a "percentage of percentage" delta would confuse the reader.
function _fmtSignedPp(absPp) {
  if (Math.abs(absPp) < 0.5) return '(\u00b10pp)';
  const sign = absPp > 0 ? '+' : '\u2212';
  return `(${sign}${Math.round(Math.abs(absPp))}pp)`;
}

// WP11 Phase 2.A: ratio-percentage delta as a `+X.XX×` style multiplier delta.
function _fmtSignedMult(absMult) {
  if (Math.abs(absMult) < 0.01) return '0.00\u00d7';
  const sign = absMult > 0 ? '+' : '\u2212';
  return `${sign}${Math.abs(absMult).toFixed(2)}\u00d7`;
}

// WP11 Phase 2.A: PresetSelector — four sub-tabs below the main Toolbar (Q7).
// Unchanged from Phase 2 except the click bug fix in P2A.4 (see below for the
// `data-compare-preset` button's pointer-events / event-handler attachment).
function PresetSelector({ preset, onPresetChange,
                         compareRangeA, compareRangeB, onCompareRangeChange,
                         maxRangeDays = 90 }) {
  const presets = [
    { value: 'wow', label: 'WoW' },
    { value: 'today-vs-trailing', label: 'Today vs trailing' },
    { value: 'mom', label: 'MoM' },
    { value: 'custom', label: 'Custom' },
  ];
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', gap: 8,
      padding: '8px 20px',
      borderBottom: `1px solid ${CT_TOKENS.border}`,
      background: CT_TOKENS.surface,
    }}>
      <div style={{
        display: 'flex', gap: 2, padding: 3,
        background: CT_TOKENS.surfaceDim, borderRadius: 8,
        border: `1px solid ${CT_TOKENS.border}`,
        alignSelf: 'flex-start',
      }}>
        {presets.map(p => (
          <button
            key={p.value}
            data-compare-preset={p.value}
            data-active={p.value === preset ? 'true' : 'false'}
            onClick={() => onPresetChange(p.value)}
            style={{
              background: p.value === preset ? CT_TOKENS.surface : 'transparent',
              color: p.value === preset ? CT_TOKENS.textPrimary : CT_TOKENS.textSecondary,
              border: 'none', borderRadius: 6,
              padding: '5px 10px',
              fontSize: 12, fontWeight: p.value === preset ? 550 : 450,
              fontFamily: CT_TOKENS.sans,
              cursor: 'pointer',
              boxShadow: p.value === preset
                ? '0 1px 2px rgba(20,18,12,0.06), inset 0 0 0 1px ' + CT_TOKENS.border
                : 'none',
            }}
          >{p.label}</button>
        ))}
      </div>
      {/* Custom preset: side-by-side RangePicker pair. */}
      {preset === 'custom' && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{
            fontFamily: CT_TOKENS.sans, fontSize: 11,
            color: CT_TOKENS.textSecondary, fontWeight: 500,
          }}>A:</span>
          <RangePicker
            startIso={compareRangeA?.start}
            endIso={compareRangeA?.end}
            maxRangeDays={maxRangeDays}
            onChange={(r) => onCompareRangeChange({ a: r, b: compareRangeB })}
          />
          <span style={{ fontFamily: CT_TOKENS.mono, fontSize: 12, color: CT_TOKENS.textTertiary }}>vs</span>
          <span style={{
            fontFamily: CT_TOKENS.sans, fontSize: 11,
            color: CT_TOKENS.textSecondary, fontWeight: 500,
          }}>B:</span>
          <RangePicker
            startIso={compareRangeB?.start}
            endIso={compareRangeB?.end}
            maxRangeDays={maxRangeDays}
            onChange={(r) => onCompareRangeChange({ a: compareRangeA, b: r })}
          />
        </div>
      )}
    </div>
  );
}

// WP11 Phase 2.A: EffectivenessRow — generalized 3-column (A · B · Δ) row.
// `kind` dispatches the column rendering strategy. The component pulls all
// values from aMetrics + bMetrics (each is window.CT_DATA.comparison.{a,b}.metrics,
// already filter-projected by _computeMetricsView at the parent).
//
// Kind variants:
//   - multiplier              → engaged_session.multiplier; columns show ×N.NN
//   - ratio-pct               → AI-effort/human-wallclock as percentage
//   - blocking-split          → stacked-bar a→h / h→a as shares of engaged wallclock
//   - concurrency-mix         → stratified bar k=1/2/3/4+ shares of engaged wallclock
//   - absolute-wallclock-effort-mult → wall/effort/× triplet (ai_agent, tool_call)
//   - absolute-wallclock-only → wall only (human)
//   - absolute-engaged        → wall/effort/× + session count (engaged_session)
function EffectivenessRow({ rowKey, label, aMetrics, bMetrics, kind }) {
  // Helper: render the standardized 3-column grid layout.
  const Layout = ({ aContent, bContent, deltaContent }) => (
    <div data-compare-row={rowKey} style={{
      display: 'grid',
      gridTemplateColumns: '160px 1fr 1fr 130px',
      alignItems: 'center', gap: 8,
      padding: '8px 20px',
      borderBottom: `1px solid ${CT_TOKENS.border}`,
    }}>
      <div style={{
        fontFamily: CT_TOKENS.sans, fontSize: 12, fontWeight: 500,
        color: CT_TOKENS.textPrimary,
      }}>{label}</div>
      <div data-compare-col="a" style={{
        fontFamily: CT_TOKENS.mono, fontSize: 12,
        color: CT_TOKENS.textPrimary,
        fontVariantNumeric: 'tabular-nums',
      }}>{aContent}</div>
      <div data-compare-col="b" style={{
        fontFamily: CT_TOKENS.mono, fontSize: 12,
        color: CT_TOKENS.textPrimary,
        fontVariantNumeric: 'tabular-nums',
        fontWeight: 550,
      }}>{bContent}</div>
      <div data-compare-col="delta" style={{
        textAlign: 'right',
        fontFamily: CT_TOKENS.mono, fontSize: 12,
        fontVariantNumeric: 'tabular-nums',
        fontWeight: 500,
      }}>{deltaContent}</div>
    </div>
  );

  // Colored Δ text — active-blue for positive, muted-gray for negative. No red/green (R4).
  const DeltaText = ({ children, positive }) => (
    <span style={{ color: positive ? CT_TOKENS.active : CT_TOKENS.textMuted }}>
      {children}
    </span>
  );

  if (kind === 'multiplier') {
    const aM = aMetrics?.engaged_session?.multiplier ?? 0;
    const bM = bMetrics?.engaged_session?.multiplier ?? 0;
    const absDelta = bM - aM;
    const relPct = aM === 0 ? null : ((bM - aM) / aM) * 100;
    return (
      <Layout
        aContent={`${aM.toFixed(2)}\u00d7`}
        bContent={`${bM.toFixed(2)}\u00d7`}
        deltaContent={
          <DeltaText positive={absDelta >= 0}>
            <div>{_fmtSignedMult(absDelta)}</div>
            <div style={{ fontSize: 10, color: CT_TOKENS.textTertiary, fontWeight: 400 }}>
              {_fmtRelPct(relPct)}
            </div>
          </DeltaText>
        }
      />
    );
  }

  if (kind === 'ratio-pct') {
    // AI-effort / human-wallclock (×100 for percentage).
    const aAi = aMetrics?.ai_agent?.effort_ms || 0;
    const aHu = aMetrics?.human?.wallclock_ms || 0;
    const bAi = bMetrics?.ai_agent?.effort_ms || 0;
    const bHu = bMetrics?.human?.wallclock_ms || 0;
    const aRatio = aHu === 0 ? 0 : (aAi / aHu) * 100;
    const bRatio = bHu === 0 ? 0 : (bAi / bHu) * 100;
    const absDelta = bRatio - aRatio;
    return (
      <Layout
        aContent={aHu === 0 ? '\u2014' : `${aRatio.toFixed(1)}%`}
        bContent={bHu === 0 ? '\u2014' : `${bRatio.toFixed(1)}%`}
        deltaContent={
          <DeltaText positive={absDelta >= 0}>
            {(aHu === 0 || bHu === 0) ? '(N/A)' : _fmtSignedPp(absDelta)}
          </DeltaText>
        }
      />
    );
  }

  if (kind === 'blocking-split') {
    // Show split as a stacked horizontal bar per side + textual Δ on the larger-shift component.
    const aWall = aMetrics?.engaged_session?.wallclock_ms || 0;
    const bWall = bMetrics?.engaged_session?.wallclock_ms || 0;
    const aAh = aMetrics?.blocking?.agent_blocking_human_ms || 0;
    const aHa = aMetrics?.blocking?.human_blocking_agent_ms || 0;
    const bAh = bMetrics?.blocking?.agent_blocking_human_ms || 0;
    const bHa = bMetrics?.blocking?.human_blocking_agent_ms || 0;
    const aAhShare = aWall === 0 ? 0 : (aAh / aWall) * 100;
    const aHaShare = aWall === 0 ? 0 : (aHa / aWall) * 100;
    const bAhShare = bWall === 0 ? 0 : (bAh / bWall) * 100;
    const bHaShare = bWall === 0 ? 0 : (bHa / bWall) * 100;
    const ahShift = bAhShare - aAhShare;
    const haShift = bHaShare - aHaShare;
    // Report the larger-magnitude shift in the Δ column.
    const showShift = Math.abs(ahShift) >= Math.abs(haShift) ? ahShift : haShift;
    const showLabel = Math.abs(ahShift) >= Math.abs(haShift) ? 'agent→human' : 'human→agent';
    const Bar = ({ ahShare, haShare }) => (
      <div style={{
        display: 'flex', height: 10, borderRadius: 2, overflow: 'hidden',
        background: CT_TOKENS.surfaceDim,
      }} title={`agent→human: ${ahShare.toFixed(1)}%, human→agent: ${haShare.toFixed(1)}%`}>
        <div style={{ width: `${ahShare}%`, background: CT_TOKENS.active }} />
        <div style={{ width: `${haShare}%`, background: CT_TOKENS.textMuted }} />
      </div>
    );
    return (
      <Layout
        aContent={aWall === 0 ? '\u2014' : <Bar ahShare={aAhShare} haShare={aHaShare} />}
        bContent={bWall === 0 ? '\u2014' : <Bar ahShare={bAhShare} haShare={bHaShare} />}
        deltaContent={
          <DeltaText positive={showShift >= 0}>
            <div style={{ fontSize: 10 }}>{showLabel}</div>
            <div>{_fmtSignedPp(showShift)}</div>
          </DeltaText>
        }
      />
    );
  }

  if (kind === 'concurrency-mix') {
    // Stratified bar k=1/2/3/4+ as shares of engaged wallclock. Report the
    // single largest-magnitude stratum shift in the Δ column.
    const buildShares = (m) => {
      const wall = m?.engaged_session?.wallclock_ms || 0;
      const conc = m?.concurrency || [];
      if (wall === 0) return { k1: 0, k2: 0, k3: 0, k4: 0 };
      const find = (k) => (conc.find(c => c.k === k)?.wallclock_ms || 0) / wall * 100;
      return { k1: find(1), k2: find(2), k3: find(3), k4: find(4) };
    };
    const aShares = buildShares(aMetrics);
    const bShares = buildShares(bMetrics);
    const aWall = aMetrics?.engaged_session?.wallclock_ms || 0;
    const bWall = bMetrics?.engaged_session?.wallclock_ms || 0;
    const colors = [CT_TOKENS.textMuted, CT_TOKENS.active, CT_TOKENS.textPrimary, CT_TOKENS.textPrimary];
    const Bar = ({ shares }) => (
      <div style={{
        display: 'flex', height: 10, borderRadius: 2, overflow: 'hidden',
        background: CT_TOKENS.surfaceDim,
      }} title={`k=1: ${shares.k1.toFixed(1)}%, k=2: ${shares.k2.toFixed(1)}%, k=3: ${shares.k3.toFixed(1)}%, k=4+: ${shares.k4.toFixed(1)}%`}>
        <div style={{ width: `${shares.k1}%`, background: colors[0], opacity: 0.5 }} />
        <div style={{ width: `${shares.k2}%`, background: colors[1] }} />
        <div style={{ width: `${shares.k3}%`, background: colors[2], opacity: 0.7 }} />
        <div style={{ width: `${shares.k4}%`, background: colors[3] }} />
      </div>
    );
    // Find the largest-magnitude stratum shift for the Δ column.
    const shifts = [
      { k: 1, label: 'k=1', delta: bShares.k1 - aShares.k1 },
      { k: 2, label: 'k=2', delta: bShares.k2 - aShares.k2 },
      { k: 3, label: 'k=3', delta: bShares.k3 - aShares.k3 },
      { k: 4, label: 'k=4+', delta: bShares.k4 - aShares.k4 },
    ];
    shifts.sort((x, y) => Math.abs(y.delta) - Math.abs(x.delta));
    const top = shifts[0];
    return (
      <Layout
        aContent={aWall === 0 ? '\u2014' : <Bar shares={aShares} />}
        bContent={bWall === 0 ? '\u2014' : <Bar shares={bShares} />}
        deltaContent={
          <DeltaText positive={top.delta >= 0}>
            <div style={{ fontSize: 10 }}>{top.label} share</div>
            <div>{_fmtSignedPp(top.delta)}</div>
          </DeltaText>
        }
      />
    );
  }

  if (kind === 'absolute-wallclock-effort-mult') {
    // For ai_agent / tool_call: show wall · effort · × on each side.
    const path = rowKey === 'ai-agent' ? 'ai_agent' : 'tool_call';
    const aSub = aMetrics?.[path] || {};
    const bSub = bMetrics?.[path] || {};
    const aWall = aSub.wallclock_ms || 0;
    const aEff = aSub.effort_ms || 0;
    const aMult = aSub.multiplier ?? 0;
    const bWall = bSub.wallclock_ms || 0;
    const bEff = bSub.effort_ms || 0;
    const bMult = bSub.multiplier ?? 0;
    const wallDelta = bWall - aWall;
    const wallRelPct = aWall === 0 ? null : ((bWall - aWall) / aWall) * 100;
    const Cell = ({ wall, eff, mult }) => (
      <div>
        <div>{fmtDur(wall / 60_000)}</div>
        <div style={{ fontSize: 10, color: CT_TOKENS.textSecondary }}>
          {`eff: ${fmtDur(eff / 60_000)} \u00b7 ${mult.toFixed(2)}\u00d7`}
        </div>
      </div>
    );
    return (
      <Layout
        aContent={<Cell wall={aWall} eff={aEff} mult={aMult} />}
        bContent={<Cell wall={bWall} eff={bEff} mult={bMult} />}
        deltaContent={
          <DeltaText positive={wallDelta >= 0}>
            <div>{_fmtSignedDurMs(wallDelta)}</div>
            <div style={{ fontSize: 10, color: CT_TOKENS.textTertiary, fontWeight: 400 }}>
              {_fmtRelPct(wallRelPct)}
            </div>
          </DeltaText>
        }
      />
    );
  }

  if (kind === 'absolute-wallclock-only') {
    // human: just wall-clock (effort === wallclock by construction; × is always 1.0).
    const aWall = aMetrics?.human?.wallclock_ms || 0;
    const bWall = bMetrics?.human?.wallclock_ms || 0;
    const wallDelta = bWall - aWall;
    const wallRelPct = aWall === 0 ? null : ((bWall - aWall) / aWall) * 100;
    return (
      <Layout
        aContent={fmtDur(aWall / 60_000)}
        bContent={fmtDur(bWall / 60_000)}
        deltaContent={
          <DeltaText positive={wallDelta >= 0}>
            <div>{_fmtSignedDurMs(wallDelta)}</div>
            <div style={{ fontSize: 10, color: CT_TOKENS.textTertiary, fontWeight: 400 }}>
              {_fmtRelPct(wallRelPct)}
            </div>
          </DeltaText>
        }
      />
    );
  }

  if (kind === 'absolute-engaged') {
    // engaged_session: wall + effort + × + session_count.
    const aS = aMetrics?.engaged_session || {};
    const bS = bMetrics?.engaged_session || {};
    const aWall = aS.wallclock_ms || 0;
    const bWall = bS.wallclock_ms || 0;
    const wallDelta = bWall - aWall;
    const wallRelPct = aWall === 0 ? null : ((bWall - aWall) / aWall) * 100;
    const Cell = ({ s }) => (
      <div>
        <div>{fmtDur((s.wallclock_ms || 0) / 60_000)}</div>
        <div style={{ fontSize: 10, color: CT_TOKENS.textSecondary }}>
          {`eff: ${fmtDur((s.effort_ms || 0) / 60_000)} \u00b7 ${(s.multiplier ?? 0).toFixed(2)}\u00d7`}
        </div>
        <div style={{ fontSize: 10, color: CT_TOKENS.textTertiary }}>
          {s.session_count || 0} sessions
        </div>
      </div>
    );
    return (
      <Layout
        aContent={<Cell s={aS} />}
        bContent={<Cell s={bS} />}
        deltaContent={
          <DeltaText positive={wallDelta >= 0}>
            <div>{_fmtSignedDurMs(wallDelta)}</div>
            <div style={{ fontSize: 10, color: CT_TOKENS.textTertiary, fontWeight: 400 }}>
              {_fmtRelPct(wallRelPct)}
            </div>
          </DeltaText>
        }
      />
    );
  }

  // Unknown kind — shouldn't happen at runtime.
  return null;
}

// WP11 Phase 2.A: CompareView root — effectiveness-lens redesign (2026-05-26).
// Sources from window.CT_DATA.comparison.{a,b}.metrics (Phase 1.B). Filter chips
// project both windows via WP10's _computeMetricsView. Renders 8 rows in the
// priority order locked at re-spec (R1): 4 headline ratios first, then 4
// supporting absolutes.
function CompareView({ comparison }) {
  const { kinds: filterKinds } = useFilter();
  const aMetrics = React.useMemo(
    () => _computeMetricsView(comparison?.a?.metrics, filterKinds),
    [comparison, filterKinds]
  );
  const bMetrics = React.useMemo(
    () => _computeMetricsView(comparison?.b?.metrics, filterKinds),
    [comparison, filterKinds]
  );

  // No comparison payload (e.g., --demo path: demo data is single-day and
  // has no real events to compare across windows).
  if (!comparison || !aMetrics || !bMetrics) {
    return (
      <div data-compare-view="true" style={{
        flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: CT_TOKENS.surface,
      }}>
        <div style={{
          fontFamily: CT_TOKENS.sans, fontSize: 13,
          color: CT_TOKENS.textSecondary, fontWeight: 500,
        }}>No comparison data — emit with real events: <code style={{
          fontFamily: CT_TOKENS.mono, padding: '1px 4px',
          background: CT_TOKENS.surfaceAlt, borderRadius: 3,
        }}>claude-time visualize --window 14d</code></div>
      </div>
    );
  }

  // Empty-window check (engaged_session.wallclock_ms === 0 on each side).
  const aWall = aMetrics.engaged_session?.wallclock_ms || 0;
  const bWall = bMetrics.engaged_session?.wallclock_ms || 0;
  const aEmpty = aWall === 0;
  const bEmpty = bWall === 0;
  const bothEmpty = aEmpty && bEmpty;
  const meta = comparison.meta || {};
  const aDay = meta.a_day_count;
  const bDay = meta.b_day_count;
  const lengthMismatch = aDay && bDay && aDay !== bDay;

  // 8 rows in priority order (R1): 4 headline ratios, then 4 supporting absolutes.
  const rows = [
    { rowKey: 'parallelism-multiplier',      label: 'Parallelism ×',         kind: 'multiplier' },
    { rowKey: 'ai-effort-per-human-wallclock', label: 'AI effort / human wall', kind: 'ratio-pct' },
    { rowKey: 'blocking-split',              label: 'Blocking split',         kind: 'blocking-split' },
    { rowKey: 'concurrency-mix',             label: 'Concurrency mix',        kind: 'concurrency-mix' },
    { rowKey: 'ai-agent',                    label: 'AI agent',               kind: 'absolute-wallclock-effort-mult' },
    { rowKey: 'tool-call',                   label: 'Tool calls',             kind: 'absolute-wallclock-effort-mult' },
    { rowKey: 'human',                       label: 'Human (you)',            kind: 'absolute-wallclock-only' },
    { rowKey: 'engaged-session',             label: 'Engaged sessions',       kind: 'absolute-engaged' },
  ];

  return (
    <div data-compare-view="true" style={{
      flex: 1,
      display: 'flex', flexDirection: 'column',
      overflow: 'auto',
      background: CT_TOKENS.bg,
    }}>
      {/* Window labels — A and B with day-counts (carry-over from Phase 2). */}
      <div data-compare-section="window-labels" style={{
        display: 'flex', justifyContent: 'space-around',
        padding: '10px 20px',
        background: CT_TOKENS.surface,
        borderBottom: `1px solid ${CT_TOKENS.border}`,
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{
            fontFamily: CT_TOKENS.sans, fontSize: 10, fontWeight: 500,
            color: CT_TOKENS.textTertiary, textTransform: 'uppercase',
            letterSpacing: '0.08em',
          }}>A {aEmpty ? '(empty)' : ''}</div>
          <div style={{
            fontFamily: CT_TOKENS.mono, fontSize: 11, color: CT_TOKENS.textPrimary,
          }}>{`${meta.a_start || '\u2014'} \u2192 ${meta.a_end || '\u2014'} (${aDay || 0}d)`}</div>
        </div>
        <div style={{ textAlign: 'center' }}>
          <div style={{
            fontFamily: CT_TOKENS.sans, fontSize: 10, fontWeight: 500,
            color: CT_TOKENS.textTertiary, textTransform: 'uppercase',
            letterSpacing: '0.08em',
          }}>B {bEmpty ? '(empty)' : ''}</div>
          <div style={{
            fontFamily: CT_TOKENS.mono, fontSize: 11, color: CT_TOKENS.textPrimary,
          }}>{`${meta.b_start || '\u2014'} \u2192 ${meta.b_end || '\u2014'} (${bDay || 0}d)`}</div>
        </div>
      </div>
      {lengthMismatch && (
        <div data-compare-warning="length-mismatch" style={{
          padding: '6px 20px',
          background: CT_TOKENS.surfaceDim,
          fontFamily: CT_TOKENS.sans, fontSize: 11,
          color: CT_TOKENS.textSecondary,
          borderBottom: `1px solid ${CT_TOKENS.border}`,
        }}>
          {`windows are different lengths: A is ${aDay}d, B is ${bDay}d \u2014 deltas are absolute, not normalized`}
        </div>
      )}
      {bothEmpty ? (
        <div style={{
          flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <div style={{
            fontFamily: CT_TOKENS.sans, fontSize: 13,
            color: CT_TOKENS.textSecondary, fontWeight: 500,
          }}>no tracked time in either window</div>
        </div>
      ) : (
        <div data-compare-section="effectiveness" style={{
          display: 'flex', flexDirection: 'column',
        }}>
          {/* Column headers above the rows. */}
          <div style={{
            display: 'grid',
            gridTemplateColumns: '160px 1fr 1fr 130px',
            alignItems: 'center', gap: 8,
            padding: '6px 20px',
            background: CT_TOKENS.surfaceDim,
            borderBottom: `1px solid ${CT_TOKENS.border}`,
            fontFamily: CT_TOKENS.sans, fontSize: 10, fontWeight: 600,
            color: CT_TOKENS.textTertiary, textTransform: 'uppercase',
            letterSpacing: '0.08em',
          }}>
            <div>Metric</div>
            <div>A</div>
            <div>B</div>
            <div style={{ textAlign: 'right' }}>Δ (B − A)</div>
          </div>
          {rows.map(r => (
            <EffectivenessRow
              key={r.rowKey}
              rowKey={r.rowKey}
              label={r.label}
              aMetrics={aMetrics}
              bMetrics={bMetrics}
              kind={r.kind}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// HeadlineCard — three primary numbers (collapsed default) + chevron toggle.
// Click chevron → expanded prop true → MetricsPanel renders below.
function HeadlineCard({ metrics, expanded, onToggleExpanded }) {
  const { kinds: filterKinds } = useFilter();
  const view = React.useMemo(
    () => _computeMetricsView(metrics, filterKinds),
    [metrics, filterKinds]
  );
  if (!view) return null;

  // The three headline numbers per Q1 of the spec:
  //   1. active session wall-clock (engaged-session wall-clock — away-gaps excluded)
  //   2. human activity wall-clock (typing + reading + thinking)
  //   3. AI effort hours (agent burst effort-time only — no double counting)
  const tiles = [
    { id: 'engaged-session', label: 'Active session',  value_ms: view.engaged_session.wallclock_ms,
      sub: 'wall-clock' },
    { id: 'human',           label: 'Human activity',  value_ms: view.human.wallclock_ms,
      sub: 'wall-clock' },
    { id: 'ai-effort',       label: 'AI effort',       value_ms: view.ai_agent.effort_ms,
      sub: 'effort-time' },
  ];

  // Empty-window check: post-filter zeros across all three headline numbers.
  const isEmpty = tiles.every(t => t.value_ms === 0);
  // Raw-empty (pre-filter) check: distinguishes "no data at all" from
  // "data exists but filtered out".
  const rawEmpty = metrics.engaged_session.wallclock_ms === 0
                && metrics.human.wallclock_ms === 0
                && metrics.ai_agent.effort_ms === 0;
  const emptyCaption = isEmpty
    ? (rawEmpty
        ? 'No tracked activity in the past 7 days'
        : 'No data matches current filters — adjust chips above to see the past 7 days')
    : null;

  // WP10 P2.verify-human.2 (back-loop 2026-05-24): the window/date-range
  // indicator was previously buried in MetricsPanel's header. User asked for
  // it to be visible without expanding the panel. Surfaced as a `data-metrics-window`
  // strip in the top-right of the collapsed card.
  const windowLabel = `Past ${view.window.day_count} days \u00b7 ${view.window.start} \u2192 ${view.window.end}`;

  return (
    <div
      data-metrics-card="true"
      data-metrics-expanded={expanded ? 'true' : 'false'}
      style={{
        display: 'flex', alignItems: 'stretch', gap: 0,
        padding: '14px 20px',
        borderBottom: `1px solid ${CT_TOKENS.border}`,
        background: CT_TOKENS.surface,
        flexShrink: 0,
      }}>
      {/* Three tiles */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 28, flex: 1 }}>
        {tiles.map((t) => (
          <div key={t.id} data-metric-tile={t.id}
               style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
            <div style={{
              fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
              letterSpacing: '0.06em', color: CT_TOKENS.textTertiary,
            }}>{t.label}</div>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
              <span style={{
                fontFamily: CT_TOKENS.mono, fontSize: 20, fontWeight: 500,
                color: CT_TOKENS.textPrimary, letterSpacing: '-0.01em',
              }}>{emptyCaption ? '\u2014' : _fmtDurMs(t.value_ms)}</span>
              <span style={{ fontFamily: CT_TOKENS.sans, fontSize: 11, color: CT_TOKENS.textTertiary }}>{t.sub}</span>
            </div>
          </div>
        ))}
        {emptyCaption && (
          <div style={{ marginLeft: 14, fontSize: 11.5,
                        color: CT_TOKENS.textTertiary, fontFamily: CT_TOKENS.sans,
                        maxWidth: 360 }}>
            {emptyCaption}
          </div>
        )}
      </div>
      {/* Right column: window/date-range indicator stacked above chevron toggle. */}
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end',
                    justifyContent: 'center', gap: 6 }}>
        <div
          data-metrics-window="true"
          style={{
            fontFamily: CT_TOKENS.mono, fontSize: 10.5,
            color: CT_TOKENS.textTertiary,
            letterSpacing: '0.02em',
          }}
          title="Trailing-7-day window — metrics are always computed over this range, view-mode-independent.">
          {windowLabel}
        </div>
        <button
          data-metric-expand-toggle="true"
          onClick={onToggleExpanded}
          title={expanded ? 'Collapse metrics panel' : 'Expand metrics panel'}
          style={{
            padding: '4px 8px', background: 'transparent',
            border: `1px solid ${CT_TOKENS.border}`, borderRadius: 6,
            cursor: 'pointer',
            color: CT_TOKENS.textSecondary,
            display: 'inline-flex', alignItems: 'center', gap: 6,
            fontFamily: CT_TOKENS.sans, fontSize: 11,
          }}>
          <span>{expanded ? 'Hide' : 'Details'}</span>
          {expanded ? <IconChevDown /> : <IconChevRight />}
        </button>
      </div>
    </div>
  );
}

// MetricsPanel — full six-section table, rendered when HeadlineCard is expanded.
function MetricsPanel({ metrics }) {
  const { kinds: filterKinds } = useFilter();
  const view = React.useMemo(
    () => _computeMetricsView(metrics, filterKinds),
    [metrics, filterKinds]
  );
  if (!view) return null;

  // Header legend describing the wall-clock vs effort-time vocabulary.
  // The legend is the only inline tooltip-style copy in v1.
  const legend = 'Wall-clock = elapsed time. Effort-time = sum of durations. \u00d7Multiplier = effort \u00f7 wall-clock.';

  // Helper: render a single metric row (wall-clock | effort-time | ×mult).
  const Row = ({ label, wc, eff, mult, indent = 0 }) => (
    <tr>
      <td style={{ paddingLeft: 8 + indent * 16, fontFamily: CT_TOKENS.sans,
                   fontSize: 12, color: indent > 0 ? CT_TOKENS.textTertiary : CT_TOKENS.textSecondary }}>
        {label}
      </td>
      <td style={{ fontFamily: CT_TOKENS.mono, fontSize: 12, textAlign: 'right',
                   color: CT_TOKENS.textPrimary }}>
        {_fmtDurMs(wc)}
      </td>
      <td style={{ fontFamily: CT_TOKENS.mono, fontSize: 12, textAlign: 'right',
                   color: CT_TOKENS.textPrimary }}>
        {_fmtDurMs(eff)}
      </td>
      <td style={{ fontFamily: CT_TOKENS.mono, fontSize: 12, textAlign: 'right',
                   color: CT_TOKENS.textSecondary, paddingRight: 8 }}>
        {_fmtMult(mult)}
      </td>
    </tr>
  );

  const colHeader = (text, align = 'left') => (
    <th style={{
      fontFamily: CT_TOKENS.sans, fontSize: 10.5, textTransform: 'uppercase',
      letterSpacing: '0.06em', color: CT_TOKENS.textTertiary,
      fontWeight: 500, paddingBottom: 4, textAlign: align,
    }}>{text}</th>
  );

  const sectionStyle = {
    marginBottom: 14, padding: '12px 16px',
    background: CT_TOKENS.surfaceAlt,
    border: `1px solid ${CT_TOKENS.border}`,
    borderRadius: 6,
  };
  const sectionHeader = (label) => (
    <div style={{
      fontFamily: CT_TOKENS.sans, fontSize: 11.5, fontWeight: 500,
      color: CT_TOKENS.textPrimary, marginBottom: 6,
      textTransform: 'uppercase', letterSpacing: '0.04em',
    }}>{label}</div>
  );

  return (
    <div data-metrics-panel="true" style={{
      background: CT_TOKENS.surface,
      padding: '16px 20px',
      borderBottom: `1px solid ${CT_TOKENS.border}`,
      maxHeight: 480, overflowY: 'auto',
    }}>
      <div style={{ fontFamily: CT_TOKENS.sans, fontSize: 11, color: CT_TOKENS.textTertiary,
                    marginBottom: 12, fontStyle: 'italic' }}>
        {legend}
      </div>

      {/* Engaged session */}
      <div data-metric-section="engaged-session" style={sectionStyle}>
        {sectionHeader('Engaged session duration')}
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead><tr>{colHeader('Metric')}{colHeader('Wall-clock', 'right')}{colHeader('Effort-time', 'right')}{colHeader('×Mult', 'right')}</tr></thead>
          <tbody>
            <Row label={`Across ${view.engaged_session.session_count} session(s)`}
                 wc={view.engaged_session.wallclock_ms}
                 eff={view.engaged_session.effort_ms}
                 mult={view.engaged_session.multiplier} />
          </tbody>
        </table>
      </div>

      {/* AI agent */}
      <div data-metric-section="ai-agent" style={sectionStyle}>
        {sectionHeader('AI agent activity (bursts)')}
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead><tr>{colHeader('Metric')}{colHeader('Wall-clock', 'right')}{colHeader('Effort-time', 'right')}{colHeader('×Mult', 'right')}</tr></thead>
          <tbody>
            <Row label="All bursts"
                 wc={view.ai_agent.wallclock_ms}
                 eff={view.ai_agent.effort_ms}
                 mult={view.ai_agent.multiplier} />
            <Row label="of which: subagent time"
                 wc={view.ai_agent.subagent.wallclock_ms}
                 eff={view.ai_agent.subagent.effort_ms}
                 mult={view.ai_agent.subagent.multiplier}
                 indent={1} />
          </tbody>
        </table>
      </div>

      {/* Tool call */}
      <div data-metric-section="tool-call" style={sectionStyle}>
        {sectionHeader('Tool call duration')}
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead><tr>{colHeader('Metric')}{colHeader('Wall-clock', 'right')}{colHeader('Effort-time', 'right')}{colHeader('×Mult', 'right')}</tr></thead>
          <tbody>
            <Row label="All tool calls"
                 wc={view.tool_call.wallclock_ms}
                 eff={view.tool_call.effort_ms}
                 mult={view.tool_call.multiplier} />
            {view.tool_call.top.map((t, i) => (
              <Row key={t.name} label={`top ${i + 1}: ${t.name}`}
                   wc={t.wallclock_ms} eff={t.effort_ms} mult={t.multiplier}
                   indent={1} />
            ))}
          </tbody>
        </table>
      </div>

      {/* Human active */}
      <div data-metric-section="human" style={sectionStyle}>
        {sectionHeader('Human active duration')}
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead><tr>{colHeader('Metric')}{colHeader('Wall-clock', 'right')}{colHeader('Effort-time', 'right')}{colHeader('×Mult', 'right')}</tr></thead>
          <tbody>
            <Row label="Total (one-brain)"
                 wc={view.human.wallclock_ms}
                 eff={view.human.effort_ms}
                 mult={view.human.multiplier} />
            <Row label="typing"   wc={view.human.typing_ms}   eff={view.human.typing_ms}   mult={1.0} indent={1} />
            <Row label="reading"  wc={view.human.reading_ms}  eff={view.human.reading_ms}  mult={1.0} indent={1} />
            <Row label="thinking" wc={view.human.thinking_ms} eff={view.human.thinking_ms} mult={1.0} indent={1} />
          </tbody>
        </table>
      </div>

      {/* Concurrency stratification */}
      <div data-metric-section="concurrency" style={sectionStyle}>
        {sectionHeader('Concurrency stratification (engaged sessions)')}
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead><tr>{colHeader('Sessions engaged')}{colHeader('Wall-clock', 'right')}{colHeader('Effort-time', 'right')}<th /></tr></thead>
          <tbody>
            {view.concurrency.map((c) => (
              <Row key={c.k}
                   label={c.is_plus ? `${c.k}+ sessions` : `${c.k} session${c.k === 1 ? '' : 's'}`}
                   wc={c.wallclock_ms}
                   eff={c.effort_ms}
                   mult={null} />
            ))}
          </tbody>
        </table>
      </div>

      {/* Blocking metrics */}
      <div data-metric-section="blocking" style={sectionStyle}>
        {sectionHeader('Blocking metrics')}
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead><tr>{colHeader('Direction')}{colHeader('Wall-clock', 'right')}<th /><th /></tr></thead>
          <tbody>
            <Row label="Human blocking agent (reading + thinking)"
                 wc={view.blocking.human_blocking_agent_ms}
                 eff={view.blocking.human_blocking_agent_ms}
                 mult={null} />
            <Row label="Agent blocking human (burst wall-clock)"
                 wc={view.blocking.agent_blocking_human_ms}
                 eff={view.blocking.agent_blocking_human_ms}
                 mult={null} />
          </tbody>
        </table>
      </div>
    </div>
  );
}

/* ── Legend — functional kind-filter chips (WP9 Phase 2, 2026-05-23) ── */
// Pre-WP9 this was a static color-key. WP9 made each item a clickable
// toggle: clicking dims the chip (text strikethrough + reduced opacity)
// AND hides all segments of that kind across the dashboard. State lives
// in FilterContext (provided by the shipped interactive wrapper). The
// design-canvas page also uses Legend; its FilterContext default has all
// kinds ON + a no-op setter, so the design-canvas reference renders
// identically to pre-WP9.
function Legend() {
  const { kinds, setKinds } = useFilter();
  const items = [
    { kind: 'active',   label: 'Active coding', color: CT_TOKENS.active },
    { kind: 'reading',  label: 'Reading',       color: CT_TOKENS.reading },
    { kind: 'thinking', label: 'Thinking',      color: CT_TOKENS.thinking },
    { kind: 'subagent', label: 'Subagent',      color: CT_TOKENS.subagent },
    { kind: 'away',     label: 'Away',          stripe: true },
  ];
  const toggle = (k) => setKinds({ ...kinds, [k]: !kinds[k] });
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
      {items.map((it) => {
        const on = kinds[it.kind] !== false;
        return (
          <button
            key={it.kind}
            data-filter-kind={it.kind}
            data-filter-on={on ? 'true' : 'false'}
            onClick={() => toggle(it.kind)}
            title={on ? `Hide ${it.label.toLowerCase()}` : `Show ${it.label.toLowerCase()}`}
            style={{
              display: 'flex', alignItems: 'center', gap: 6,
              padding: '2px 4px', margin: 0,
              background: 'transparent', border: 'none',
              cursor: 'pointer',
              opacity: on ? 1 : 0.45,
              borderRadius: 4,
            }}
          >
            <span style={{
              width: 14, height: 8, borderRadius: 2,
              ...(it.stripe ? segStyle('away') : { background: it.color }),
              border: it.stripe ? `1px solid ${CT_TOKENS.border}` : 'none',
            }} />
            <span style={{
              fontSize: 11,
              color: CT_TOKENS.textSecondary,
              fontFamily: CT_TOKENS.sans,
              textDecoration: on ? 'none' : 'line-through',
            }}>{it.label}</span>
          </button>
        );
      })}
    </div>
  );
}

/* ── Project filter popover (WP9 Phase 4, 2026-05-23) ───────── */
// Trigger button next to Legend opens a small popover with a checkbox per
// project. State lives in FilterContext.projects ({projectId: false} for
// hidden; absent → visible). Default visible = all projects ON.
// Outside-click dismisses via document mousedown listener (cleaned up on
// unmount or when the popover closes).
function ProjectFilterPopover({ projects }) {
  const { projects: projectFilter, setProjects } = useFilter();
  const [open, setOpen] = React.useState(false);
  const rootRef = React.useRef(null);

  // Outside-click dismiss.
  React.useEffect(() => {
    if (!open) return;
    const onDoc = (e) => {
      if (rootRef.current && !rootRef.current.contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', onDoc);
    return () => document.removeEventListener('mousedown', onDoc);
  }, [open]);

  const hiddenCount = projects.filter(p => projectFilter[p.id] === false).length;
  const toggleProject = (id) => {
    // Symmetric with kind chips: explicit false hides, absent (or true) shows.
    const cur = projectFilter[id] !== false;
    setProjects({ ...projectFilter, [id]: !cur });
  };

  return (
    <div ref={rootRef} style={{ position: 'relative' }} data-project-filter-root>
      <button
        data-project-filter-trigger
        data-project-filter-open={open ? 'true' : 'false'}
        onClick={() => setOpen(o => !o)}
        title={hiddenCount > 0
          ? `Projects (${hiddenCount} hidden — click to manage)`
          : 'Projects (click to filter)'}
        style={{
          display: 'flex', alignItems: 'center', gap: 6,
          padding: '3px 8px',
          background: hiddenCount > 0 ? CT_TOKENS.surfaceDim : 'transparent',
          border: `1px solid ${CT_TOKENS.border}`,
          borderRadius: 6,
          fontSize: 11, fontFamily: CT_TOKENS.sans,
          color: CT_TOKENS.textSecondary,
          cursor: 'pointer',
        }}
      >
        <IconFilter size={11} />
        <span>Projects</span>
        {hiddenCount > 0 && (
          <span data-project-filter-hidden-count style={{
            fontFamily: CT_TOKENS.mono, fontSize: 10,
            padding: '1px 5px', borderRadius: 3,
            background: CT_TOKENS.active, color: '#fff',
            fontWeight: 500,
          }}>{hiddenCount}</span>
        )}
      </button>

      {open && (
        <div
          data-project-filter-panel
          style={{
            position: 'absolute',
            right: 0, top: 'calc(100% + 4px)',
            zIndex: 50,
            minWidth: 200, maxWidth: 320,
            maxHeight: 280, overflowY: 'auto',
            background: CT_TOKENS.surface,
            border: `1px solid ${CT_TOKENS.border}`,
            borderRadius: 6,
            boxShadow: '0 4px 12px rgba(20,18,12,0.10)',
            padding: '6px 0',
          }}
        >
          {projects.length === 0 && (
            <div style={{
              padding: '6px 12px', fontSize: 11,
              color: CT_TOKENS.textTertiary,
              fontFamily: CT_TOKENS.sans,
            }}>No projects in this view.</div>
          )}
          {projects.map(p => {
            const visible = projectFilter[p.id] !== false;
            return (
              <label
                key={p.id}
                data-project-filter-item={p.id}
                data-project-filter-on={visible ? 'true' : 'false'}
                style={{
                  display: 'flex', alignItems: 'center', gap: 8,
                  padding: '5px 12px',
                  cursor: 'pointer',
                  fontSize: 11.5,
                  fontFamily: CT_TOKENS.mono,
                  color: visible ? CT_TOKENS.textPrimary : CT_TOKENS.textTertiary,
                  textDecoration: visible ? 'none' : 'line-through',
                }}
              >
                <input
                  type="checkbox"
                  checked={visible}
                  onChange={() => toggleProject(p.id)}
                  style={{ cursor: 'pointer' }}
                />
                <span style={{
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  flex: 1,
                }}>{p.alias}</span>
              </label>
            );
          })}
        </div>
      )}
    </div>
  );
}

/* ── Day-view timeline ──────────────────────────────────────── */
// WP5: viewport state machine. Module-level DAY_* constants are reduced to
// the *initial-viewport derivation* helpers. The segment-positioning path
// (SegmentBar, HourRuler, HourGridBackground, NOW marker) now reads from
// the ViewportContext rather than module-level constants, so pan + zoom in
// later WP5 phases can update the viewport without touching renderers.
//
// WP5b: convert a YYYY-MM-DD ISO day to absolute minutes-since-window-start,
// using UTC-anchored parsing to avoid DST drift across days. window_start_iso
// is the multi-day data window's first day. dayOffsetMin("2026-05-23",
// "2026-05-09") = 14 * 1440 = 20160. dayOffsetMin(x, x) = 0.
function dayOffsetMin(day_iso, window_start_iso) {
  if (!day_iso || !window_start_iso) return 0;
  const d = new Date(day_iso + "T00:00:00Z");
  const start = new Date(window_start_iso + "T00:00:00Z");
  if (isNaN(d) || isNaN(start)) return 0;
  return Math.round((d - start) / 60_000);
}

// Initial viewport derives from `window.CT_DATA.today`. Three modes:
//   1. Multi-day (WP5b): `target_iso` + `meta.start` + `hour_range_by_day`
//      all present → center on the target day's adaptive hour-range, with
//      day-offset applied so segments from other days are visible on either
//      side via pan.
//   2. Single-day (back-compat, --context-days 0/0): flat `hour_range`
//      present → use it directly (the pre-WP5b path).
//   3. Defensive fallback (standalone design-canvas, no CT_DATA): [6, 23].
function _initialViewport() {
  if (typeof window === 'undefined' || !window.CT_DATA || !window.CT_DATA.today) {
    return { visible_start_min: 6 * 60, visible_end_min: 23 * 60 };
  }
  const today = window.CT_DATA.today;
  // Multi-day path: center on target_iso's per-day hour_range.
  if (today.target_iso && today.meta && today.meta.start) {
    const target_iso = today.target_iso;
    const hr_by_day = today.hour_range_by_day || {};
    const hr = hr_by_day[target_iso] || today.day_window || [6, 23];
    const offset = dayOffsetMin(target_iso, today.meta.start);
    return {
      visible_start_min: offset + hr[0] * 60,
      visible_end_min:   offset + hr[1] * 60,
    };
  }
  // Single-day back-compat path.
  if (today.hour_range) {
    return { visible_start_min: today.hour_range[0] * 60, visible_end_min: today.hour_range[1] * 60 };
  }
  return { visible_start_min: 6 * 60, visible_end_min: 23 * 60 };
}

// React.Context plumbs viewport from the interactive Dashboard down to the
// leaf renderers (SegmentBar, HourRuler, HourGridBackground) without a
// 4-level prop drill. The default value carries an initial viewport and a
// no-op setter so the design-canvas prototype still works standalone
// (gesture handlers attach but setViewport is harmless).
const ViewportContext = React.createContext({
  viewport: _initialViewport(),
  setViewport: () => {},
});

// WP5b: data-window context plumbs the multi-day window metadata
// (`windowStartIso`, `dayCount`) to leaf renderers (HourRuler,
// HourGridBackground, ticksInViewport label formatter) without a deep
// prop drill. Default: single-day mode (`windowStartIso: null, dayCount: 1`)
// so the design-canvas prototype and the single-day back-compat path
// behave identically to pre-WP5b. Provided by `DayTimeline` from the
// data payload.
const DataWindowContext = React.createContext({
  windowStartIso: null,
  dayCount: 1,
});

// WP9 Phase 2: filter context plumbs kind-filter state (which segment
// kinds are visible) and project-filter state (Phase 4) to leaf consumers
// (SegmentBar's render-or-null check, Legend's clickable chip state,
// per-project popover). Default: all kinds enabled, no projects hidden
// — design-canvas prototype renders all segments as before.
const FILTER_KINDS = ['active', 'reading', 'thinking', 'subagent', 'away'];
const FILTER_ALL_ON = Object.freeze(
  FILTER_KINDS.reduce((acc, k) => { acc[k] = true; return acc; }, {})
);
const FilterContext = React.createContext({
  kinds: FILTER_ALL_ON,
  setKinds: () => {},
  projects: {},      // {projectId: false} means hidden; absent => visible
  setProjects: () => {},
});
function useFilter() {
  return React.useContext(FilterContext);
}

// WP5 Phase 3: URL-hash state utilities. The shared convention is
// `#key=value;key=value;...` — semicolon-separated pairs, URL-encoded
// values. Each downstream consumer (WP5 viewport, WP9 filters, WP13
// expanded-projects, WP6/7/8 view + view params) owns one or more keys
// and reads/writes via this helper, preserving other consumers' keys.
//
// See CLAUDE.md → "Claude-time visualize URL-hash state" for the full
// convention spec (key shape, default-elision rule, reload behavior).
function parseHash() {
  const raw = (typeof window !== 'undefined' && window.location)
    ? window.location.hash.replace(/^#/, '')
    : '';
  const out = {};
  if (!raw) return out;
  for (const pair of raw.split(';')) {
    const ix = pair.indexOf('=');
    if (ix < 0) continue;
    const k = decodeURIComponent(pair.slice(0, ix));
    const v = decodeURIComponent(pair.slice(ix + 1));
    if (k) out[k] = v;
  }
  return out;
}

function serializeHash(obj) {
  const parts = [];
  for (const k of Object.keys(obj)) {
    const v = obj[k];
    if (v == null || v === '') continue; // skip empty values
    parts.push(`${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`);
  }
  return parts.join(';');
}

// updateHash applies a patch to the current hash, preserving other keys.
// Values that are `null` or `undefined` are *removed* from the hash —
// callers use this to implement default-elision (when a value equals the
// component's default, pass `null` so the key drops out, keeping URLs short
// for the common case).
function updateHash(patch) {
  if (typeof window === 'undefined' || !window.location) return;
  const current = parseHash();
  for (const k of Object.keys(patch)) {
    if (patch[k] == null) delete current[k];
    else current[k] = patch[k];
  }
  const serialized = serializeHash(current);
  const newUrl = window.location.pathname + window.location.search + (serialized ? `#${serialized}` : '');
  window.history.replaceState(null, '', newUrl);
}

function useViewport() {
  return React.useContext(ViewportContext).viewport;
}

// WP5 Phase 2: separate hook for the setter so leaf renderers that only
// read (SegmentBar, HourGridBackground) don't subscribe to setter changes.
function useViewportSetter() {
  return React.useContext(ViewportContext).setViewport;
}

// WP5 Phase 2 + WP5b: ruler tick density adapts to zoom. Returns the densest
// interval (minutes) from [1440, 360, 60, 30, 15, 10, 5, 1] that produces
// between 8 and 30 visible ticks. WP5b extends the scale set with day-level
// (1440) and 6h (360) intervals for multi-day zoom-out across the new Day
// view context window. The 8–30 band still holds: 21-day window → 21 ticks
// at 1440; 2-day window → 8 ticks at 360; 6h window → 12 ticks at 30
// (360→6 falls out of band so 30 catches it).
function pickTickInterval(viewport) {
  const range = viewport.visible_end_min - viewport.visible_start_min;
  const scales = [1440, 360, 60, 30, 15, 10, 5, 1];
  for (const m of scales) {
    const ticks = Math.ceil(range / m);
    if (ticks >= 8 && ticks <= 30) return m;
  }
  // Edge cases: very small range (< 8 minutes) → 1m ticks; very large
  // range (> ~720h ≈ 30 days) → 1440m ticks (visually sparse but readable).
  if (range < 8) return 1;
  return 1440;
}

// WP5 Phase 2 + WP5b: tick generator. Emits an array of minute-aligned tick
// positions covering the viewport at the given interval. Each tick has an
// absolute-minute value (minute-of-window in multi-day, minute-of-day in
// single-day) and a label.
//
// WP5b label formats:
//   - intervalMin >= 1440 (day-level): "MMM DD"
//   - viewport crosses any midnight: ticks within the same day stay "HH:MM",
//     but ticks ON a midnight (t % 1440 == 0) get "MMM DD" prefix.
//   - single-day intra-viewport (no crossing): "HH:00" or "HH:MM" as before
// windowStartIso is the data window's first day (passed by HourRuler / consumers).
// When absent, falls back to the single-day formatter (HH:00 / HH:MM).
function ticksInViewport(viewport, intervalMin, windowStartIso = null) {
  const startTick = Math.ceil(viewport.visible_start_min / intervalMin) * intervalMin;
  const out = [];
  const crossesMidnight = (
    Math.floor(viewport.visible_start_min / 1440) !==
    Math.floor((viewport.visible_end_min - 1) / 1440)
  );
  for (let t = startTick; t < viewport.visible_end_min; t += intervalMin) {
    const dayIx = Math.floor(t / 1440);
    const minOfDay = ((t % 1440) + 1440) % 1440;
    const h = Math.floor(minOfDay / 60);
    const m = minOfDay % 60;
    let label;
    if (intervalMin >= 1440) {
      label = _formatDayLabel(dayIx, windowStartIso);
    } else if (crossesMidnight && windowStartIso && minOfDay === 0) {
      // First tick of a new day inside the viewport: prefix MMM DD.
      label = _formatDayLabel(dayIx, windowStartIso);
    } else if (intervalMin === 60) {
      label = `${String(h).padStart(2,'0')}:00`;
    } else {
      label = `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}`;
    }
    out.push({ min: t, label });
  }
  return out;
}

// WP5b helper: format a day-index (relative to windowStartIso) as "MMM DD".
// Used by ticksInViewport for day-level + midnight-boundary tick labels.
function _formatDayLabel(dayIx, windowStartIso) {
  if (!windowStartIso) return ""; // safe default — no label rather than wrong label
  const start = new Date(windowStartIso + "T00:00:00Z");
  if (isNaN(start)) return "";
  const d = new Date(start.getTime() + dayIx * 86_400_000);
  const months = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"];
  return `${months[d.getUTCMonth()]} ${String(d.getUTCDate()).padStart(2,'0')}`;
}

const ROW_LEFT_WIDTH = 232;
const ROW_HEIGHT = 36;
const PROJECT_HEADER_HEIGHT = 40;
// NOW marker is computed client-side via useNowMin() (see DayTimeline below).
// v1 used a hardcoded module-level NOW_MIN that froze on every emit; removed in WP2.

// WP5b: derive the timeline's data-window bounds [start_min, end_min] from
// the data payload. Multi-day mode (meta.day_count present): [0, day_count*1440].
// Single-day mode (flat hour_range): [hour_range[0]*60, hour_range[1]*60].
// Defensive fallback: [0, 1440]. Used by DayTimeline (gesture clamp + Home/End)
// and Minimap (rectangle math) — both consume identical bounds so the minimap's
// visible-window rectangle stays in sync with the main timeline's pannable range.
function deriveDataWindow(data) {
  if (data && data.meta && data.meta.day_count) return [0, data.meta.day_count * 1440];
  if (data && data.hour_range) return [data.hour_range[0] * 60, data.hour_range[1] * 60];
  return [0, 1440];
}

function viewportPct(start, end, viewport) {
  const range = viewport.visible_end_min - viewport.visible_start_min;
  const left = ((start - viewport.visible_start_min) / range) * 100;
  const width = ((end - start) / range) * 100;
  return { left: `${left}%`, width: `${width}%` };
}

// WP5: enumerate the whole hours covered by the current viewport. Phase 1
// keeps 1h tick granularity; Phase 2 generalizes this to adaptive density.
function hoursInViewport(viewport) {
  const startHour = Math.floor(viewport.visible_start_min / 60);
  const endHour   = Math.ceil(viewport.visible_end_min / 60);
  const out = [];
  for (let h = startHour; h < endHour; h++) out.push(h);
  return out;
}

function HourRuler({ nowFrac, nowLabel, nowMin }) {
  const viewport = useViewport();
  const dw = React.useContext(DataWindowContext);
  const intervalMin = pickTickInterval(viewport);
  const ticks = ticksInViewport(viewport, intervalMin, dw.windowStartIso);
  const range = viewport.visible_end_min - viewport.visible_start_min;
  // WP5 P2.7 (NOW-label-overlap cosmetic fix, SURFACE-2026-05-19): when the
  // NOW marker falls within ~10 minutes of a top-of-hour tick (or any tick
  // boundary on adaptive density), flip the label to the LEFT of the line
  // so it doesn't overlay the next tick's label. Mechanical 3-line fix; the
  // refactor of HourRuler for adaptive density was already touching this
  // file, so folding the cosmetic in costs nothing.
  const flipNowLeft = nowMin != null
    && (nowMin % intervalMin) >= (intervalMin - 10);
  return (
    <div style={{
      height: 30,
      position: 'relative',
      borderBottom: `1px solid ${CT_TOKENS.border}`,
      background: CT_TOKENS.surfaceAlt,
      overflow: 'hidden',
    }}>
      {ticks.map((t) => {
        const leftPct = ((t.min - viewport.visible_start_min) / range) * 100;
        const widthPct = (intervalMin / range) * 100;
        return (
          <div key={t.min} style={{
            position: 'absolute',
            left: `${leftPct}%`,
            width: `${widthPct}%`,
            top: 0, bottom: 0,
            borderRight: `1px solid ${CT_TOKENS.gridHour}`,
            display: 'flex', alignItems: 'center', paddingLeft: 6,
            boxSizing: 'border-box',
          }}>
            <span style={{
              fontFamily: CT_TOKENS.mono, fontSize: 10.5,
              color: CT_TOKENS.textTertiary, letterSpacing: '0.02em',
            }}>{t.label}</span>
          </div>
        );
      })}
      {nowFrac != null && (
        <div style={{
          position: 'absolute', top: 0, bottom: -1,
          left: `${nowFrac * 100}%`,
          width: 1.5,
          background: 'oklch(0.55 0.18 25)',
        }}>
          <span style={{
            position: 'absolute', top: 4,
            ...(flipNowLeft ? { right: 4 } : { left: 4 }),
            fontFamily: CT_TOKENS.mono, fontSize: 10,
            color: 'oklch(0.45 0.20 25)', fontWeight: 500,
          }}>NOW · {nowLabel}</span>
        </div>
      )}
    </div>
  );
}

function HourGridBackground() {
  const viewport = useViewport();
  const dw = React.useContext(DataWindowContext);
  const intervalMin = pickTickInterval(viewport);
  const ticks = ticksInViewport(viewport, intervalMin, dw.windowStartIso);
  const range = viewport.visible_end_min - viewport.visible_start_min;
  return (
    <div style={{
      position: 'absolute', inset: 0, pointerEvents: 'none',
      overflow: 'hidden',
    }}>
      {ticks.map((t) => {
        const leftPct = ((t.min - viewport.visible_start_min) / range) * 100;
        const widthPct = (intervalMin / range) * 100;
        return (
          <div key={t.min} style={{
            position: 'absolute',
            left: `${leftPct}%`,
            width: `${widthPct}%`,
            top: 0, bottom: 0,
            borderRight: `1px solid ${CT_TOKENS.gridHour}`,
            boxSizing: 'border-box',
          }} />
        );
      })}
    </div>
  );
}

function SegmentBar({ seg, selected = false, dayOffset = 0 }) {
  const viewport = useViewport();
  const { kinds: filterKinds } = useFilter();
  // WP9 Phase 2: if this segment's kind is filtered out, render nothing.
  // Per-segment hide is preferred over per-row hide so the timeline layout
  // remains stable (positions of other kinds unchanged when one is toggled).
  if (filterKinds[seg.kind] === false) return null;
  // WP5b: when the session this segment belongs to is on a non-target day
  // in a multi-day window, `dayOffset` shifts the segment's [start, end]
  // from minute-of-day into minute-of-window before computing viewport %.
  // Single-day case: dayOffset === 0, math is unchanged.
  const { left, width } = viewportPct(seg.start + dayOffset, seg.end + dayOffset, viewport);
  const isSubagent = seg.kind === 'subagent';
  const height = isSubagent ? 14 : ROW_HEIGHT - 12;
  const top = isSubagent ? (ROW_HEIGHT - 14) / 2 + 4 : 6;
  return (
    <div
      title={`${seg.kind} · ${fmtClock(seg.start)}–${fmtClock(seg.end)}`}
      data-seg-id={`${seg.kind}-${seg.start}-${seg.end}`}
      data-kind={seg.kind}
      style={{
        position: 'absolute',
        left, width,
        top,
        height,
        borderRadius: 3,
        ...segStyle(seg.kind),
        boxShadow: selected ? `0 0 0 2px ${CT_TOKENS.surface}, 0 0 0 4px ${CT_TOKENS.active}` : (isSubagent ? `0 0 0 1px ${CT_TOKENS.surface}` : 'none'),
        overflow: 'hidden',
        display: 'flex', alignItems: 'center', paddingLeft: 5,
        minWidth: 2,
      }}
    >
      {isSubagent && seg.label && (
        <span style={{
          fontFamily: CT_TOKENS.mono, fontSize: 9.5,
          color: '#fff', letterSpacing: '0.02em', textTransform: 'uppercase', fontWeight: 600,
        }}>{seg.label}</span>
      )}
    </div>
  );
}

function ProjectHeaderRow({ project, totals, expanded = true, alt = false }) {
  return (
    <div style={{
      display: 'flex',
      height: PROJECT_HEADER_HEIGHT,
      borderBottom: `1px solid ${CT_TOKENS.border}`,
      background: alt ? CT_TOKENS.surfaceAlt : CT_TOKENS.surface,
    }}>
      <div style={{
        width: ROW_LEFT_WIDTH, flexShrink: 0,
        borderRight: `1px solid ${CT_TOKENS.border}`,
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '0 12px',
      }}>
        <span style={{ color: CT_TOKENS.textTertiary, display: 'flex' }}>
          {expanded ? <IconChevDown size={12} /> : <IconChevRight size={12} />}
        </span>
        <span style={{
          fontFamily: CT_TOKENS.mono, fontSize: 13,
          color: CT_TOKENS.textPrimary, fontWeight: 500,
          letterSpacing: '-0.01em',
          whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        }}>{project.alias}</span>
        <span style={{ flex: 1 }} />
        <span style={{
          fontFamily: CT_TOKENS.mono, fontSize: 11,
          padding: '2px 7px', borderRadius: 999,
          background: CT_TOKENS.active, color: '#fff',
          fontWeight: 500,
        }}>{fmtDur(totals.active)}</span>
      </div>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        <HourGridBackground />
        {/* Aggregate density bar at bottom */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 6, height: 3,
          background: CT_TOKENS.surfaceDim,
        }} />
      </div>
    </div>
  );
}

function SessionRow({ session, alt = false, selectedSegId = null, onSelect, lastInGroup = false }) {
  // WP9 Phase 2: filter-aware per-row total. `sumActive` sums only
  // active+subagent regardless; here we additionally drop kinds the user
  // has toggled off so the visible label reflects what's actually rendered.
  const { kinds: filterKinds } = useFilter();
  const totalActive = sumActive(session.segs.filter(s => filterKinds[s.kind] !== false));
  // WP5b: in multi-day mode, sessions carry a `day_iso` tag from
  // build_range_data so the renderer can offset their segments from
  // minute-of-day into minute-of-window. Single-day mode: no tag → offset 0.
  const dw = React.useContext(DataWindowContext);
  const dayOffset = (session.day_iso && dw.windowStartIso)
    ? dayOffsetMin(session.day_iso, dw.windowStartIso)
    : 0;
  return (
    <div style={{
      display: 'flex',
      height: ROW_HEIGHT,
      borderBottom: lastInGroup ? `1px solid ${CT_TOKENS.border}` : `1px solid ${CT_TOKENS.gridHour}`,
      background: alt ? CT_TOKENS.rowAlt : CT_TOKENS.surface,
    }}>
      <div style={{
        width: ROW_LEFT_WIDTH, flexShrink: 0,
        borderRight: `1px solid ${CT_TOKENS.border}`,
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '0 12px 0 30px',
      }}>
        <span style={{
          fontFamily: CT_TOKENS.mono, fontSize: 11.5,
          color: CT_TOKENS.textSecondary,
        }}>{fmtClock(session.start)} <span style={{ color: CT_TOKENS.textMuted }}>→</span> {fmtClock(session.end)}</span>
        <span style={{ flex: 1 }} />
        <span style={{
          fontFamily: CT_TOKENS.mono, fontSize: 10.5,
          color: CT_TOKENS.textTertiary,
        }}>{fmtDur(totalActive)}</span>
      </div>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        <HourGridBackground />
        {session.segs.map((seg, i) => (
          <SegmentBar key={i} seg={seg} dayOffset={dayOffset} selected={`${session.id}:${i}` === selectedSegId} />
        ))}
      </div>
    </div>
  );
}

// WP5 Phase 2: timeline gesture handlers (pan + zoom). Attaches mousedown
// for drag-to-pan and wheel for ctrl/cmd/pinch-zoom on the timeline surface.
// All viewport mutations are rAF-throttled — wheel events fire faster than
// browser repaint, so coalescing prevents redundant React renders.
//
// Cursor-anchor rule for zoom: the data-coordinate at the cursor x-position
// stays under the cursor after zoom. Equivalent to keeping the cursor-anchor
// invariant: cursor_data_min = cursor_data_min_after_zoom.
//
// Gutter exclusion: events whose clientX falls inside [0, ROW_LEFT_WIDTH)
// from the container's left edge are ignored (the gutter is the row-label
// area; users clicking project names shouldn't initiate pan).
function useTimelineGestures(viewport, setViewport, dataWindow) {
  const ref = React.useRef(null);
  const rafIdRef = React.useRef(0);
  const dragRef = React.useRef(null); // {start_x, start_viewport}

  const scheduleSet = React.useCallback((nextViewport) => {
    if (rafIdRef.current) cancelAnimationFrame(rafIdRef.current);
    rafIdRef.current = requestAnimationFrame(() => {
      rafIdRef.current = 0;
      setViewport(nextViewport);
    });
  }, [setViewport]);

  // Convert clientX → (data-minute) using viewport + container bounds.
  // Returns null when cursor is in the gutter or outside the container.
  const clientXToDataMin = React.useCallback((clientX, currentViewport) => {
    const el = ref.current;
    if (!el) return null;
    const rect = el.getBoundingClientRect();
    const offsetX = clientX - rect.left;
    if (offsetX < ROW_LEFT_WIDTH) return null; // gutter
    const timelineWidth = rect.width - ROW_LEFT_WIDTH;
    if (timelineWidth <= 0) return null;
    const frac = (offsetX - ROW_LEFT_WIDTH) / timelineWidth;
    const range = currentViewport.visible_end_min - currentViewport.visible_start_min;
    return currentViewport.visible_start_min + frac * range;
  }, []);

  const onMouseDown = React.useCallback((e) => {
    const dataMin = clientXToDataMin(e.clientX, viewport);
    if (dataMin == null) return; // in gutter
    // Don't initiate pan when clicking a SegmentBar (preserves click-to-select).
    if (e.target && e.target.closest && e.target.closest('[data-seg-id]')) return;
    dragRef.current = {
      start_x: e.clientX,
      start_viewport: viewport,
      container_timeline_width: ref.current.getBoundingClientRect().width - ROW_LEFT_WIDTH,
    };
    // Capture pointer so mouseup outside the container still releases.
    if (e.currentTarget.setPointerCapture && e.pointerId !== undefined) {
      try { e.currentTarget.setPointerCapture(e.pointerId); } catch (_) {}
    }
    document.body.style.cursor = 'grabbing';
  }, [viewport, clientXToDataMin]);

  const onMouseMove = React.useCallback((e) => {
    if (!dragRef.current) return;
    const d = dragRef.current;
    const dx = e.clientX - d.start_x;
    const range = d.start_viewport.visible_end_min - d.start_viewport.visible_start_min;
    const deltaMin = -(dx / d.container_timeline_width) * range; // drag right → pan left
    scheduleSet({
      visible_start_min: d.start_viewport.visible_start_min + deltaMin,
      visible_end_min: d.start_viewport.visible_end_min + deltaMin,
    });
  }, [scheduleSet]);

  const onMouseUp = React.useCallback(() => {
    if (dragRef.current) {
      dragRef.current = null;
      document.body.style.cursor = '';
    }
  }, []);

  // Wheel zoom: ctrl/cmd-modified wheel events (also matches Safari/Chrome
  // trackpad pinch convention — browsers synthesize `e.ctrlKey === true`
  // on pinch even when the user isn't holding ctrl). Plain wheel (no
  // modifier) is ignored so browser scroll keeps working.
  const onWheel = React.useCallback((e) => {
    if (!(e.ctrlKey || e.metaKey)) return; // pass through to browser scroll
    e.preventDefault();
    const dataMin = clientXToDataMin(e.clientX, viewport);
    if (dataMin == null) return;
    const f = e.deltaY > 0 ? 1.1 : 1 / 1.1; // wheel down = zoom out
    const oldRange = viewport.visible_end_min - viewport.visible_start_min;
    let newRange = oldRange * f;
    // Clamp: min 1 minute (extreme zoom-in), max full data window.
    const maxRange = (dataWindow && dataWindow.length === 2)
      ? dataWindow[1] - dataWindow[0]
      : oldRange * 100; // generous fallback if no dataWindow plumbed
    newRange = Math.max(1, Math.min(maxRange, newRange));
    // Cursor-anchor: keep dataMin under cursor.
    const cursorFrac = (dataMin - viewport.visible_start_min) / oldRange;
    const newStart = dataMin - cursorFrac * newRange;
    const newEnd = newStart + newRange;
    scheduleSet({ visible_start_min: newStart, visible_end_min: newEnd });
  }, [viewport, scheduleSet, clientXToDataMin, dataWindow]);

  // Keyboard shortcuts: pan with arrows, zoom with +/-/0, jump with Home/End.
  // Attached at window level; ignored when typing in inputs.
  React.useEffect(() => {
    const onKeyDown = (e) => {
      if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA' || e.target.isContentEditable)) return;
      const range = viewport.visible_end_min - viewport.visible_start_min;
      const maxRange = (dataWindow && dataWindow.length === 2)
        ? dataWindow[1] - dataWindow[0]
        : range * 100;
      if (e.key === 'ArrowLeft') {
        e.preventDefault();
        const dx = range * 0.1;
        scheduleSet({
          visible_start_min: viewport.visible_start_min - dx,
          visible_end_min: viewport.visible_end_min - dx,
        });
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        const dx = range * 0.1;
        scheduleSet({
          visible_start_min: viewport.visible_start_min + dx,
          visible_end_min: viewport.visible_end_min + dx,
        });
      } else if (e.key === '+' || e.key === '=') {
        e.preventDefault();
        const newRange = Math.max(1, range / 1.5);
        const center = (viewport.visible_start_min + viewport.visible_end_min) / 2;
        scheduleSet({
          visible_start_min: center - newRange / 2,
          visible_end_min: center + newRange / 2,
        });
      } else if (e.key === '-' || e.key === '_') {
        e.preventDefault();
        const newRange = Math.min(maxRange, range * 1.5);
        const center = (viewport.visible_start_min + viewport.visible_end_min) / 2;
        scheduleSet({
          visible_start_min: center - newRange / 2,
          visible_end_min: center + newRange / 2,
        });
      } else if (e.key === '0') {
        e.preventDefault();
        // Reset to initial viewport (fit data window).
        scheduleSet(_initialViewport());
      } else if (e.key === 'Home') {
        e.preventDefault();
        if (dataWindow && dataWindow.length === 2) {
          scheduleSet({ visible_start_min: dataWindow[0], visible_end_min: dataWindow[0] + range });
        }
      } else if (e.key === 'End') {
        e.preventDefault();
        if (dataWindow && dataWindow.length === 2) {
          scheduleSet({ visible_start_min: dataWindow[1] - range, visible_end_min: dataWindow[1] });
        }
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [viewport, scheduleSet, dataWindow]);

  // TODO(v3): touch-drag + touch-pinch wiring. Add ontouchstart/ontouchmove
  // handlers here mirroring the mouse path; pinch needs a 2-finger
  // distance-tracking helper.

  return { ref, onMouseDown, onMouseMove, onMouseUp, onWheel };
}

/* ── Day view (project list + sessions) ─────────────────────── */
function DayTimeline({ data, expandedProjects, selectedSegId, showNow = true }) {
  const { nowMin, todayISO } = useNowMin();
  const viewport = useViewport();
  const setViewport = useViewportSetter();

  // WP5b: derive multi-day window metadata (or single-day fallback) from the
  // data payload. `windowStartIso` + `dayCount` are provided via context to
  // leaf renderers (SessionRow's dayOffset math, HourRuler/HourGridBackground
  // label formatting). Single-day data: windowStartIso=null, dayCount=1.
  const dwCtx = React.useMemo(() => {
    if (data && data.meta && data.meta.start && data.meta.day_count) {
      return { windowStartIso: data.meta.start, dayCount: data.meta.day_count };
    }
    return { windowStartIso: null, dayCount: 1 };
  }, [data]);

  // Data-window for clamping zoom-out + Home/End. Shared with Minimap via
  // deriveDataWindow so both surfaces span the same bounds.
  const dataWindow = React.useMemo(() => deriveDataWindow(data), [data]);

  // WP9 Phase 4: per-project filter. `projectFilter[id] === false` hides
  // that project entirely (no row, no segments). Other projects unchanged.
  // Derive a filtered projects list once; downstream `.map` consumers use it.
  const { projects: projectFilter } = useFilter();
  const visibleProjects = React.useMemo(
    () => data.projects.filter(p => projectFilter[p.id] !== false),
    [data.projects, projectFilter]
  );

  const gestures = useTimelineGestures(viewport, setViewport, dataWindow);

  // NOW marker visibility:
  //   - Single-day mode (back-compat): isToday = data.iso === todayISO.
  //     nowMin is minute-of-day from useNowMin (matches the data's day frame).
  //   - Multi-day mode (WP5b): isToday = todayISO falls inside [meta.start, meta.end].
  //     For placement, shift nowMin by dayOffsetMin(todayISO, meta.start) so it
  //     lands at the absolute minute-of-window the rest of the renderer uses.
  const isMultiDay = !!dwCtx.windowStartIso;
  const isToday = isMultiDay
    ? (todayISO >= data.meta.start && todayISO <= data.meta.end)
    : (data && data.iso === todayISO);
  const effectiveNowMin = isMultiDay && isToday
    ? nowMin + dayOffsetMin(todayISO, dwCtx.windowStartIso)
    : nowMin;
  const inWindow = effectiveNowMin >= viewport.visible_start_min && effectiveNowMin < viewport.visible_end_min;
  const nowFrac = (showNow && isToday && inWindow)
    ? (effectiveNowMin - viewport.visible_start_min) / (viewport.visible_end_min - viewport.visible_start_min)
    : null;
  const nowLabel = `${String(Math.floor(nowMin / 60)).padStart(2, '0')}:${String(nowMin % 60).padStart(2, '0')}`;

  // Compute project totals
  const totalsByProject = {};
  for (const p of data.projects) {
    const allSegs = p.sessions.flatMap(s => s.segs);
    totalsByProject[p.id] = {
      active: sumActive(allSegs),
      reading: sumKind(allSegs, 'reading'),
      thinking: sumKind(allSegs, 'thinking'),
    };
  }

  return (
   <DataWindowContext.Provider value={dwCtx}>
    <div
      ref={gestures.ref}
      onMouseDown={gestures.onMouseDown}
      onMouseMove={gestures.onMouseMove}
      onMouseUp={gestures.onMouseUp}
      onMouseLeave={gestures.onMouseUp}
      onWheel={gestures.onWheel}
      style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        overflow: 'hidden', background: CT_TOKENS.surface,
        cursor: 'grab',
        userSelect: 'none',
      }}
    >
      {/* Header row: project label area + hour ruler */}
      <div style={{ display: 'flex', flexShrink: 0 }}>
        <div style={{
          width: ROW_LEFT_WIDTH, flexShrink: 0,
          borderRight: `1px solid ${CT_TOKENS.border}`,
          borderBottom: `1px solid ${CT_TOKENS.border}`,
          background: CT_TOKENS.surfaceAlt,
          display: 'flex', alignItems: 'center',
          padding: '0 12px',
          height: 30,
        }}>
          <span style={{
            fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: CT_TOKENS.textTertiary, fontWeight: 500,
          }}>Project</span>
          <span style={{ flex: 1 }} />
          <span style={{
            fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: CT_TOKENS.textTertiary, fontWeight: 500,
          }}>Active</span>
        </div>
        <div style={{ flex: 1 }}>
          <HourRuler nowFrac={nowFrac} nowLabel={nowLabel} nowMin={isToday && inWindow ? effectiveNowMin : null} />
        </div>
      </div>

      {/* Body rows */}
      <div style={{ flex: 1, overflow: 'auto', position: 'relative' }}>
        {/* Full-height now line */}
        {nowFrac != null && (
          <div style={{
            position: 'absolute',
            top: 0, bottom: 0,
            left: `calc(${ROW_LEFT_WIDTH}px + ${nowFrac} * (100% - ${ROW_LEFT_WIDTH}px))`,
            width: 1.5,
            background: 'oklch(0.55 0.18 25 / 0.5)',
            pointerEvents: 'none', zIndex: 1,
          }} />
        )}
        {visibleProjects.map((p, pi) => {
          const expanded = expandedProjects.includes(p.id);
          return (
            <React.Fragment key={p.id}>
              <ProjectHeaderRow project={p} totals={totalsByProject[p.id]} expanded={expanded} alt={pi % 2 === 1} />
              {expanded && p.sessions.map((s, si) => (
                <SessionRow
                  key={s.day_iso ? `${s.day_iso}:${s.id}` : s.id}
                  session={s}
                  alt={si % 2 === 1}
                  selectedSegId={selectedSegId}
                  lastInGroup={si === p.sessions.length - 1}
                />
              ))}
            </React.Fragment>
          );
        })}
      </div>
    </div>
   </DataWindowContext.Provider>
  );
}

/* ── Week-view rollup ───────────────────────────────────────── */
function WeekTimeline({ data }) {
  // Find max total for normalization
  let maxDayTotal = 0;
  for (const p of data.projects) for (const d of p.rollup) {
    const total = d.active + d.reading + d.thinking + d.subagent;
    if (total > maxDayTotal) maxDayTotal = total;
  }
  // Use a generous ceiling so even biggest day doesn't span 100%
  const ceiling = Math.ceil(maxDayTotal / 60) * 60 + 30; // round up to next hour + 30m

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', background: CT_TOKENS.surface }}>
      {/* Header */}
      <div style={{ display: 'flex', flexShrink: 0 }}>
        <div style={{
          width: ROW_LEFT_WIDTH, flexShrink: 0,
          borderRight: `1px solid ${CT_TOKENS.border}`,
          borderBottom: `1px solid ${CT_TOKENS.border}`,
          background: CT_TOKENS.surfaceAlt,
          display: 'flex', alignItems: 'center',
          padding: '0 12px',
          height: 46,
        }}>
          <span style={{
            fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: CT_TOKENS.textTertiary, fontWeight: 500,
          }}>Project</span>
          <span style={{ flex: 1 }} />
          <span style={{
            fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: CT_TOKENS.textTertiary, fontWeight: 500,
          }}>Week total</span>
        </div>
        <div style={{ flex: 1, display: 'flex', borderBottom: `1px solid ${CT_TOKENS.border}`, background: CT_TOKENS.surfaceAlt }}>
          {data.days.map((d, i) => {
            const [dow, num] = d.split(' ');
            const isWeekend = dow === 'SAT' || dow === 'SUN';
            const isToday = i === 2; // WED · 13
            return (
              <div key={d} style={{
                flex: 1,
                borderRight: i < data.days.length - 1 ? `1px solid ${CT_TOKENS.gridDay}` : 'none',
                padding: '6px 10px',
                display: 'flex', flexDirection: 'column', justifyContent: 'center',
                gap: 2,
                background: isToday ? 'oklch(0.55 0.18 25 / 0.05)' : 'transparent',
              }}>
                <span style={{
                  fontFamily: CT_TOKENS.sans, fontSize: 10.5,
                  color: isToday ? 'oklch(0.45 0.20 25)' : (isWeekend ? CT_TOKENS.textMuted : CT_TOKENS.textTertiary),
                  letterSpacing: '0.06em', fontWeight: 500,
                }}>{dow}</span>
                <span style={{
                  fontFamily: CT_TOKENS.mono, fontSize: 15,
                  fontWeight: 500,
                  color: isToday ? 'oklch(0.45 0.20 25)' : CT_TOKENS.textPrimary,
                  letterSpacing: '-0.01em',
                }}>{num}</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Day-column gridlines through body */}
      <div style={{ flex: 1, overflow: 'auto', position: 'relative' }}>
        {/* Vertical day gridlines spanning all rows */}
        <div style={{
          position: 'absolute',
          top: 0, bottom: 0,
          left: ROW_LEFT_WIDTH,
          right: 0,
          display: 'flex',
          pointerEvents: 'none',
        }}>
          {data.days.map((d, i) => (
            <div key={d} style={{
              flex: 1,
              borderRight: i < data.days.length - 1 ? `1px solid ${CT_TOKENS.gridDay}` : 'none',
              background: (i === 5 || i === 6) ? 'oklch(0.95 0.008 80 / 0.5)' : 'transparent',
            }} />
          ))}
        </div>

        {data.projects.map((p, pi) => {
          const weekActive = p.rollup.reduce((a, d) => a + d.active + d.subagent, 0);
          return (
            <div key={p.id} style={{
              display: 'flex',
              height: 64,
              borderBottom: `1px solid ${CT_TOKENS.border}`,
              background: pi % 2 === 1 ? CT_TOKENS.rowAlt : CT_TOKENS.surface,
              position: 'relative',
              zIndex: 1,
            }}>
              <div style={{
                width: ROW_LEFT_WIDTH, flexShrink: 0,
                borderRight: `1px solid ${CT_TOKENS.border}`,
                display: 'flex', alignItems: 'center', gap: 8,
                padding: '0 12px',
                background: pi % 2 === 1 ? CT_TOKENS.rowAlt : CT_TOKENS.surface,
              }}>
                <span style={{ color: CT_TOKENS.textTertiary, display: 'flex' }}>
                  <IconChevRight size={12} />
                </span>
                <span style={{
                  fontFamily: CT_TOKENS.mono, fontSize: 12.5,
                  color: CT_TOKENS.textPrimary, fontWeight: 500,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>{p.alias}</span>
                <span style={{ flex: 1 }} />
                <span style={{
                  fontFamily: CT_TOKENS.mono, fontSize: 11,
                  padding: '2px 7px', borderRadius: 999,
                  background: weekActive > 0 ? CT_TOKENS.active : CT_TOKENS.surfaceDim,
                  color: weekActive > 0 ? '#fff' : CT_TOKENS.textTertiary,
                  fontWeight: 500,
                }}>{weekActive > 0 ? fmtDur(weekActive) : '—'}</span>
              </div>

              <div style={{ flex: 1, display: 'flex' }}>
                {p.rollup.map((d, di) => {
                  const total = d.active + d.reading + d.thinking + d.subagent;
                  const isWeekend = di >= 5;
                  return (
                    <div key={di} style={{
                      flex: 1, position: 'relative',
                      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
                      padding: '8px 10px',
                    }}>
                      {total === 0 ? (
                        <div style={{ height: 4, background: CT_TOKENS.surfaceDim, borderRadius: 2 }} />
                      ) : (
                        <>
                          {/* Stacked bar */}
                          <div style={{
                            display: 'flex', flexDirection: 'column-reverse',
                            height: `${(total / ceiling) * 44}px`,
                            borderRadius: 3, overflow: 'hidden',
                            boxShadow: `inset 0 0 0 0.5px oklch(0 0 0 / 0.06)`,
                          }}>
                            {d.active > 0 && <div style={{ ...segStyle('active'), height: `${(d.active / total) * 100}%` }} />}
                            {d.subagent > 0 && <div style={{ ...segStyle('subagent'), height: `${(d.subagent / total) * 100}%` }} />}
                            {d.thinking > 0 && <div style={{ ...segStyle('thinking'), height: `${(d.thinking / total) * 100}%` }} />}
                            {d.reading > 0 && <div style={{ ...segStyle('reading'), height: `${(d.reading / total) * 100}%` }} />}
                          </div>
                          {/* Duration label */}
                          <div style={{
                            position: 'absolute', top: 8, left: 10,
                            fontFamily: CT_TOKENS.mono, fontSize: 10.5,
                            color: CT_TOKENS.textSecondary, fontWeight: 500,
                          }}>{fmtDur(d.active + d.subagent)}</div>
                        </>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

/* ── MonthView (WP7) ─────────────────────────────────────────── */
// Calendar-grid view: 7 columns (Mon-Sun), N rows (weeks), one cell per day
// within the active month. Each cell is a single-color tile whose
// saturation/lightness encodes total active+subagent minutes for that day,
// normalized against the month's max — GitHub-contribution-graph style
// (D5', 2026-05-24 verify-human back-loop, supersedes D5 vertical strips).
// The primary signal Month view communicates is daily intensity (1D);
// project-breakdown composition (2D) is what Day view exists for, reached
// via click-day drill-down. Empty days render with the lowest-intensity
// background + "no tracked time" tooltip. Days outside the active month
// (leading + trailing padding to fill the 7-col grid) render as inert
// transparent spacers. Cell aspect ratio is ~1.7:1 wide:tall — shorter than
// square so the calendar grid fits more naturally above the fold.
//
// Click a day-cell → onDayClick(iso). The Dashboard wrapper translates
// that into the toast+clipboard reload-redirect to
//   claude-time visualize --window YYYY-MM-DD:YYYY-MM-DD
// (P2.5 resolution — the dashboard is a file:// page so a real browser
// navigation isn't possible; we surface the CLI command via a non-modal
// toast and auto-copy to clipboard).
//
// Layout note: cells are aspect-square via aspectRatio (CSS), which keeps
// the grid coherent at any container width. Day-number label overlays
// top-left of the cell with a semi-transparent dark background so it
// remains legible regardless of underlying density colors.
function MonthView({ monthIso, payload, onDayClick }) {
  const parts = _monthIsoToParts(monthIso);
  if (!parts) {
    return (
      <div style={{
        flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: CT_TOKENS.surface,
        fontFamily: CT_TOKENS.sans, fontSize: 13, color: CT_TOKENS.textSecondary,
      }}>Invalid month: {monthIso}</div>
    );
  }
  const { year, month } = parts;
  const firstDay = new Date(year, month - 1, 1);
  const daysInMonth = _daysInMonth(year, month);
  const leadingPad = _mondayIndex(firstDay);  // 0..6 — empty cells before day 1
  const totalCells = leadingPad + daysInMonth;
  const trailingPad = totalCells % 7 === 0 ? 0 : 7 - (totalCells % 7);
  const gridLen = leadingPad + daysInMonth + trailingPad;  // multiple of 7

  // Build per-day total active+subagent minutes from the month's range_data
  // payload. The primary signal in Month view is daily intensity (1D: how
  // busy was this day), encoded via monochrome color saturation à la GitHub
  // contribution graph. Project breakdown (2D composition) lives in Day
  // view via drill-down — that's what click-day navigates to.
  // [D5' supersedes D5: 2026-05-24 verify-human back-loop.]
  const dayTotals = React.useMemo(() => {
    // Map<iso, total_minutes>
    const out = new Map();
    if (!payload || !payload.projects) return out;
    for (const p of payload.projects) {
      for (const s of (p.sessions || [])) {
        const iso = s.day_iso || s.iso;
        if (!iso) continue;
        let dayMin = 0;
        for (const seg of (s.segs || [])) {
          if (seg.kind !== 'active' && seg.kind !== 'subagent') continue;
          const dur = (seg.end || 0) - (seg.start || 0);
          if (dur <= 0) continue;
          dayMin += dur;
        }
        out.set(iso, (out.get(iso) || 0) + dayMin);
      }
    }
    return out;
  }, [payload]);

  // Normalize against the month's max for the intensity-color computation.
  const monthMax = React.useMemo(() => {
    let max = 0;
    for (const v of dayTotals.values()) if (v > max) max = v;
    return max;
  }, [dayTotals]);

  // Today marker — highlight current day if it falls in the active month.
  const todayIso = _todayISO(new Date());
  const todayParts = todayIso.slice(0, 7) === monthIso ? parseInt(todayIso.slice(8, 10), 10) : null;

  return (
    <div
      data-month-grid={monthIso}
      style={{
        flex: 1, display: 'flex', flexDirection: 'column',
        background: CT_TOKENS.surface, padding: '14px 20px', overflow: 'auto',
      }}
    >
      {/* Day-of-week header row */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
        gap: 6, marginBottom: 8,
      }}>
        {['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((dow) => (
          <div key={dow} style={{
            textAlign: 'center', padding: '4px 0',
            fontFamily: CT_TOKENS.sans, fontSize: 10.5,
            color: CT_TOKENS.textTertiary, letterSpacing: '0.08em', fontWeight: 500,
          }}>{dow}</div>
        ))}
      </div>

      {/* Day-cell grid */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)',
        gap: 6, alignContent: 'start',
      }}>
        {Array.from({ length: gridLen }, (_, i) => {
          const dayNum = i - leadingPad + 1;
          const inMonth = dayNum >= 1 && dayNum <= daysInMonth;
          if (!inMonth) {
            return (
              <div key={`pad-${i}`} style={{
                aspectRatio: '2 / 1',
                background: 'transparent',
              }} />
            );
          }
          const iso = `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-${String(dayNum).padStart(2, '0')}`;
          const total = dayTotals.get(iso) || 0;
          const isToday = dayNum === todayParts;
          const hasData = total > 0;
          // Intensity: 0..1 normalized against the month's max active minutes.
          const intensity = (hasData && monthMax > 0) ? total / monthMax : 0;
          // 5-bucket GitHub-graph-style monochrome scale. Empty = surfaceDim;
          // populated cells run through 5 oklch steps from light to deep active blue.
          const bg = _intensityColor(intensity);
          // Day-number label adapts to background lightness — light text on
          // high-intensity dark cells, dark text on low-intensity light cells.
          const labelLight = intensity >= 0.5;
          return (
            <button
              key={iso}
              data-month-day={iso}
              data-month-day-active={hasData ? 'true' : 'false'}
              data-month-day-intensity={hasData ? intensity.toFixed(2) : '0'}
              onClick={() => onDayClick(iso)}
              title={hasData ? `${iso} — ${fmtDur(total)}` : `${iso} — no tracked time`}
              style={{
                position: 'relative',
                aspectRatio: '2 / 1',
                border: isToday ? `2px solid ${CT_TOKENS.active}` : `1px solid ${CT_TOKENS.border}`,
                borderRadius: 5,
                background: bg,
                cursor: 'pointer',
                padding: 0, overflow: 'hidden',
              }}
            >
              {/* Day-number overlay (top-left). Color adapts to cell intensity
                  for legibility — light text on dark cells, dark on light. */}
              <span style={{
                position: 'absolute', top: 3, left: 5,
                fontFamily: CT_TOKENS.mono, fontSize: 10,
                color: labelLight ? CT_TOKENS.surface : CT_TOKENS.textSecondary,
                fontWeight: isToday ? 600 : 500,
                letterSpacing: '-0.01em',
              }}>{dayNum}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

/* ── MonthNavToast (WP7) ─────────────────────────────────────── */
// Non-modal toast surfaced when a Month-view click requires a CLI re-invoke
// (P2.5 resolution — file:// dashboard has no server to navigate to).
// Renders a small banner at the bottom-right of the dashboard with the CLI
// command + an auto-copy-to-clipboard nudge. Dismissible via the × button or
// auto-fades after 6 seconds. Multiple invocations replace the prior toast
// (no stacking — the user only cares about the most recent action).
function MonthNavToast({ message, command, onDismiss }) {
  const [copied, setCopied] = React.useState(false);
  React.useEffect(() => {
    // Auto-copy on mount.
    if (command && navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(command).then(
        () => setCopied(true),
        () => setCopied(false)  // clipboard permissions denied — toast still shows
      );
    }
    const t = setTimeout(onDismiss, 6000);
    return () => clearTimeout(t);
  }, [command, onDismiss]);
  return (
    <div
      data-month-nav-toast="true"
      style={{
        position: 'fixed', bottom: 20, right: 20,
        background: CT_TOKENS.surface,
        border: `1px solid ${CT_TOKENS.borderStrong}`,
        borderRadius: 8,
        padding: '12px 14px',
        boxShadow: '0 4px 16px rgba(20,18,12,0.15)',
        fontFamily: CT_TOKENS.sans, fontSize: 12,
        color: CT_TOKENS.textPrimary,
        maxWidth: 420, zIndex: 1000,
        display: 'flex', flexDirection: 'column', gap: 6,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
        <div style={{ flex: 1 }}>{message}</div>
        <button
          onClick={onDismiss}
          aria-label="Dismiss"
          style={{
            border: 'none', background: 'transparent',
            color: CT_TOKENS.textTertiary, fontSize: 14,
            cursor: 'pointer', padding: 0, lineHeight: 1,
          }}
        >{'\u2715'}</button>
      </div>
      <code style={{
        fontFamily: CT_TOKENS.mono, fontSize: 11,
        background: CT_TOKENS.surfaceAlt || CT_TOKENS.surfaceDim,
        padding: '4px 6px', borderRadius: 4,
        color: CT_TOKENS.textPrimary,
        userSelect: 'all', wordBreak: 'break-all',
      }}>{command}</code>
      <div style={{ fontSize: 10.5, color: CT_TOKENS.textTertiary }}>
        {copied ? '\u2713 Copied to clipboard — paste in your terminal.' : 'Run this command to refresh the dashboard.'}
      </div>
    </div>
  );
}

/* ── Minimap (WP5 Phase 3) ──────────────────────────────────── */
// Single combined low-density track showing the full data window with a
// draggable "visible window" rectangle overlay. ~80px tall total. Click
// elsewhere in the minimap re-centers viewport at that point (preserves
// zoom); dragging the rectangle pans; dragging an edge resizes (zooms).
// Per Phase 3 plan: density-light, re-orientation only — not a second
// per-project surface.
function Minimap({ data }) {
  const viewport = useViewport();
  const setViewport = useViewportSetter();
  const ref = React.useRef(null);
  const dragRef = React.useRef(null);
  const rafIdRef = React.useRef(0);

  // Data window: shared with DayTimeline via deriveDataWindow so the
  // minimap's bounds match the main timeline's gesture clamp.
  const dataWindow = React.useMemo(() => deriveDataWindow(data), [data]);

  const scheduleSet = React.useCallback((nextViewport) => {
    if (rafIdRef.current) cancelAnimationFrame(rafIdRef.current);
    rafIdRef.current = requestAnimationFrame(() => {
      rafIdRef.current = 0;
      setViewport(nextViewport);
    });
  }, [setViewport]);

  // Map clientX → data-minute within the minimap container.
  const clientXToDataMin = React.useCallback((clientX) => {
    const el = ref.current;
    if (!el) return null;
    const rect = el.getBoundingClientRect();
    const frac = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
    return dataWindow[0] + frac * (dataWindow[1] - dataWindow[0]);
  }, [dataWindow]);

  // Visible-window rectangle position on the minimap, in percent.
  const dw = dataWindow[1] - dataWindow[0];
  const rectLeftPct = ((viewport.visible_start_min - dataWindow[0]) / dw) * 100;
  const rectWidthPct = ((viewport.visible_end_min - viewport.visible_start_min) / dw) * 100;

  const onMouseDown = React.useCallback((e) => {
    const dataMin = clientXToDataMin(e.clientX);
    if (dataMin == null) return;
    const mode = e.target && e.target.dataset && e.target.dataset.minimapMode;
    if (mode === 'rect') {
      // Drag the rectangle: pan, preserving range.
      dragRef.current = {
        kind: 'pan',
        start_x: e.clientX,
        start_viewport: viewport,
        container_width: ref.current.getBoundingClientRect().width,
      };
    } else if (mode === 'edge-left' || mode === 'edge-right') {
      // Resize an edge: zoom by moving one endpoint.
      dragRef.current = {
        kind: mode,
        start_x: e.clientX,
        start_viewport: viewport,
        container_width: ref.current.getBoundingClientRect().width,
      };
    } else {
      // Click on background: re-center viewport at clicked data point,
      // preserving zoom range.
      const range = viewport.visible_end_min - viewport.visible_start_min;
      scheduleSet({
        visible_start_min: dataMin - range / 2,
        visible_end_min: dataMin + range / 2,
      });
    }
    e.stopPropagation();
  }, [viewport, scheduleSet, clientXToDataMin]);

  const onMouseMove = React.useCallback((e) => {
    if (!dragRef.current) return;
    const d = dragRef.current;
    const dx = e.clientX - d.start_x;
    const dxMin = (dx / d.container_width) * dw;
    if (d.kind === 'pan') {
      scheduleSet({
        visible_start_min: d.start_viewport.visible_start_min + dxMin,
        visible_end_min: d.start_viewport.visible_end_min + dxMin,
      });
    } else if (d.kind === 'edge-left') {
      const newStart = d.start_viewport.visible_start_min + dxMin;
      if (newStart < d.start_viewport.visible_end_min - 1) {
        scheduleSet({
          visible_start_min: newStart,
          visible_end_min: d.start_viewport.visible_end_min,
        });
      }
    } else if (d.kind === 'edge-right') {
      const newEnd = d.start_viewport.visible_end_min + dxMin;
      if (newEnd > d.start_viewport.visible_start_min + 1) {
        scheduleSet({
          visible_start_min: d.start_viewport.visible_start_min,
          visible_end_min: newEnd,
        });
      }
    }
  }, [scheduleSet, dw]);

  const onMouseUp = React.useCallback(() => {
    dragRef.current = null;
  }, []);

  // Compressed segment tracks: collapse all segments from all projects into
  // a single density line. For each segment, render a small bar at
  // (segStart - dataWindow[0]) / dw, segment color encodes kind.
  // WP5b (2026-05-23, P2.verify-human.5 fix): in multi-day mode, segments
  // carry minute-of-day [0, 1440) values; per-session `day_iso` tells us
  // which day they belong to. Pre-shift each seg's start/end by the day's
  // offset before rendering, so cross-day distribution shows up spread
  // across the full minimap width instead of bunched at left.
  const windowStart = (data && data.meta && data.meta.start) || null;
  const allSegs = (data && data.projects)
    ? data.projects.flatMap(p => p.sessions.flatMap(s => {
        const off = (s.day_iso && windowStart) ? dayOffsetMin(s.day_iso, windowStart) : 0;
        return off === 0
          ? s.segs
          : s.segs.map(seg => ({ ...seg, start: seg.start + off, end: seg.end + off }));
      }))
    : [];

  return (
    <div
      ref={ref}
      onMouseDown={onMouseDown}
      onMouseMove={onMouseMove}
      onMouseUp={onMouseUp}
      onMouseLeave={onMouseUp}
      data-minimap=""
      style={{
        height: 80,
        flexShrink: 0,
        position: 'relative',
        borderTop: `1px solid ${CT_TOKENS.border}`,
        background: CT_TOKENS.surfaceAlt,
        cursor: 'pointer',
        userSelect: 'none',
      }}
    >
      {/* Background label */}
      <div style={{
        position: 'absolute', top: 4, left: 8,
        fontFamily: CT_TOKENS.sans, fontSize: 9.5,
        color: CT_TOKENS.textTertiary, letterSpacing: '0.08em',
        textTransform: 'uppercase', fontWeight: 500,
        pointerEvents: 'none',
      }}>Overview</div>
      {/* Compressed segment tracks */}
      {allSegs.map((seg, i) => {
        const leftPct = ((seg.start - dataWindow[0]) / dw) * 100;
        const widthPct = ((seg.end - seg.start) / dw) * 100;
        return (
          <div key={i} style={{
            position: 'absolute',
            left: `${leftPct}%`,
            width: `${Math.max(0.1, widthPct)}%`,
            top: 24, height: 36,
            ...segStyle(seg.kind),
            opacity: 0.6,
            pointerEvents: 'none',
          }} />
        );
      })}
      {/* Visible-window rectangle */}
      <div
        data-minimap-mode="rect"
        style={{
          position: 'absolute',
          left: `${rectLeftPct}%`,
          width: `${rectWidthPct}%`,
          top: 18, bottom: 8,
          border: `1.5px solid ${CT_TOKENS.active}`,
          background: 'oklch(0.7 0.15 250 / 0.15)',
          cursor: 'grab',
          boxSizing: 'border-box',
        }}
      >
        {/* Edge resize handles */}
        <div data-minimap-mode="edge-left" style={{
          position: 'absolute', left: -3, top: 0, bottom: 0, width: 6,
          cursor: 'ew-resize',
        }} />
        <div data-minimap-mode="edge-right" style={{
          position: 'absolute', right: -3, top: 0, bottom: 0, width: 6,
          cursor: 'ew-resize',
        }} />
      </div>
    </div>
  );
}

/* ── Side panel (session details) ───────────────────────────── */
function SidePanel({ session, project, segment, onClose }) {
  if (!session) return null;
  const totalActive = sumActive(session.segs);
  const totalReading = sumKind(session.segs, 'reading');
  const totalThinking = sumKind(session.segs, 'thinking');
  const totalSubagent = sumKind(session.segs, 'subagent');
  const wallTime = session.end - session.start;

  const tools = Object.entries(session.tools).sort((a,b) => b[1] - a[1]);
  const maxTool = tools[0][1];

  return (
    <div style={{
      width: 360, flexShrink: 0,
      borderLeft: `1px solid ${CT_TOKENS.border}`,
      background: CT_TOKENS.surface,
      display: 'flex', flexDirection: 'column',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{
        padding: '14px 16px 12px',
        borderBottom: `1px solid ${CT_TOKENS.border}`,
        display: 'flex', alignItems: 'flex-start', gap: 8,
      }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: CT_TOKENS.textTertiary, fontWeight: 500,
            marginBottom: 4,
          }}>Session</div>
          <div style={{
            fontFamily: CT_TOKENS.mono, fontSize: 13,
            color: CT_TOKENS.textPrimary, fontWeight: 500, letterSpacing: '-0.01em',
            marginBottom: 6,
          }}>{project.alias}</div>
          <div style={{
            fontFamily: CT_TOKENS.mono, fontSize: 11,
            color: CT_TOKENS.textTertiary,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{project.path}</div>
        </div>
        <button onClick={onClose} style={iconChromeBtn()}><IconClose size={11} /></button>
      </div>

      {/* Time block */}
      <div style={{ padding: '14px 16px', borderBottom: `1px solid ${CT_TOKENS.border}` }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginBottom: 10 }}>
          <span style={{
            fontFamily: CT_TOKENS.mono, fontSize: 22,
            color: CT_TOKENS.textPrimary, fontWeight: 500, letterSpacing: '-0.02em',
          }}>{fmtDur(totalActive)}</span>
          <span style={{ fontSize: 11, color: CT_TOKENS.textTertiary, fontFamily: CT_TOKENS.sans }}>active of {fmtDur(wallTime)} wall</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontFamily: CT_TOKENS.mono, fontSize: 11.5, color: CT_TOKENS.textSecondary }}>
          <span>{fmtClock(session.start)}</span>
          <span style={{ flex: 1, height: 1, background: CT_TOKENS.border }} />
          <span>{fmtClock(session.end)}</span>
        </div>

        {/* Mini segment timeline */}
        <div style={{
          marginTop: 12,
          height: 14, position: 'relative',
          borderRadius: 3, overflow: 'hidden',
          background: CT_TOKENS.surfaceDim,
        }}>
          {session.segs.map((seg, i) => {
            const left = ((seg.start - session.start) / wallTime) * 100;
            const width = ((seg.end - seg.start) / wallTime) * 100;
            return (
              <div key={i} style={{
                position: 'absolute', top: 0, bottom: 0,
                left: `${left}%`, width: `${width}%`,
                ...segStyle(seg.kind),
                boxShadow: i === 1 && segment?.idx === 1 ? `inset 0 0 0 1.5px oklch(0 0 0 / 0.5)` : 'none',
              }} />
            );
          })}
        </div>
      </div>

      {/* Breakdown */}
      <div style={{ padding: '14px 16px', borderBottom: `1px solid ${CT_TOKENS.border}` }}>
        <div style={{
          fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
          letterSpacing: '0.08em', color: CT_TOKENS.textTertiary, fontWeight: 500,
          marginBottom: 10,
        }}>Activity breakdown</div>
        {[
          { label: 'Active coding', val: totalActive - totalSubagent, color: CT_TOKENS.active },
          { label: 'Subagent', val: totalSubagent, color: CT_TOKENS.subagent },
          { label: 'Reading', val: totalReading, color: CT_TOKENS.reading },
          { label: 'Thinking', val: totalThinking, color: CT_TOKENS.thinking },
        ].filter(r => r.val > 0).map((r, i) => (
          <div key={i} style={{
            display: 'flex', alignItems: 'center', gap: 8,
            padding: '5px 0',
          }}>
            <span style={{ width: 8, height: 8, borderRadius: 2, background: r.color }} />
            <span style={{ flex: 1, fontSize: 12, color: CT_TOKENS.textPrimary, fontFamily: CT_TOKENS.sans }}>{r.label}</span>
            <span style={{ fontFamily: CT_TOKENS.mono, fontSize: 11.5, color: CT_TOKENS.textSecondary }}>{fmtDur(r.val)}</span>
          </div>
        ))}
      </div>

      {/* Tools */}
      <div style={{ padding: '14px 16px', borderBottom: `1px solid ${CT_TOKENS.border}`, flex: 1, overflow: 'auto' }}>
        <div style={{
          display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
          marginBottom: 10,
        }}>
          <span style={{
            fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: CT_TOKENS.textTertiary, fontWeight: 500,
          }}>Tool calls</span>
          <span style={{ fontFamily: CT_TOKENS.mono, fontSize: 11, color: CT_TOKENS.textTertiary }}>
            {tools.reduce((a, [,n]) => a + n, 0)} total
          </span>
        </div>
        {tools.map(([name, n]) => (
          <div key={name} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '5px 0' }}>
            <span style={{
              width: 56, fontFamily: CT_TOKENS.mono, fontSize: 11.5,
              color: CT_TOKENS.textPrimary, fontWeight: 500,
            }}>{name}</span>
            <div style={{ flex: 1, height: 6, background: CT_TOKENS.surfaceDim, borderRadius: 2, overflow: 'hidden' }}>
              <div style={{
                height: '100%', width: `${(n / maxTool) * 100}%`,
                background: CT_TOKENS.active, opacity: 0.85,
              }} />
            </div>
            <span style={{ width: 28, textAlign: 'right', fontFamily: CT_TOKENS.mono, fontSize: 11.5, color: CT_TOKENS.textSecondary }}>{n}</span>
          </div>
        ))}
      </div>

      {/* Prompts */}
      <div style={{ padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 16 }}>
        <div>
          <div style={{
            fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: CT_TOKENS.textTertiary, fontWeight: 500,
            marginBottom: 3,
          }}>Prompts</div>
          <div style={{ fontFamily: CT_TOKENS.mono, fontSize: 17, fontWeight: 500, color: CT_TOKENS.textPrimary }}>{session.prompts}</div>
        </div>
        <div>
          <div style={{
            fontSize: 10.5, fontFamily: CT_TOKENS.sans, textTransform: 'uppercase',
            letterSpacing: '0.08em', color: CT_TOKENS.textTertiary, fontWeight: 500,
            marginBottom: 3,
          }}>Session ID</div>
          <div style={{ fontFamily: CT_TOKENS.mono, fontSize: 11.5, color: CT_TOKENS.textSecondary }}>cs_4f8e1a · {session.id}</div>
        </div>
      </div>
    </div>
  );
}

/* ── Dashboard wrapper ──────────────────────────────────────── */
function Dashboard({ variant }) {
  const { today, week } = window.CT_DATA;

  // Common: compute totals for summary strip
  const dayTotals = (() => {
    const allSegs = today.projects.flatMap(p => p.sessions.flatMap(s => s.segs));
    const active = sumActive(allSegs);
    const reading = sumKind(allSegs, 'reading');
    const thinking = sumKind(allSegs, 'thinking');
    // Compute longest single session
    let longest = { active: 0, project: '', start: 0, end: 0 };
    for (const p of today.projects) for (const s of p.sessions) {
      const a = sumActive(s.segs);
      if (a > longest.active) longest = { active: a, project: p.alias, start: s.start, end: s.end };
    }
    // Tool tally
    const tools = {};
    for (const p of today.projects) for (const s of p.sessions) for (const [k,v] of Object.entries(s.tools)) tools[k] = (tools[k] || 0) + v;
    const topTool = Object.entries(tools).sort((a,b) => b[1] - a[1])[0];
    return { active, reading, thinking, longest, topTool };
  })();

  const isDay = variant === 'day' || variant === 'detail';
  const showSidePanel = variant === 'detail';

  // For "detail" variant, pre-select a segment to highlight.
  // Pick claude-time / s2 / first 'active' segment (11:12–12:14) — the big morning chunk.
  const selProject = today.projects[0];
  const selSession = selProject.sessions[1];
  const selSegIdx  = 0;
  const selectedSegId = showSidePanel ? `${selSession.id}:${selSegIdx}` : null;

  const filterChips = isDay
    ? [{ field: 'date', value: 'Today' }, { field: 'tool', value: 'Edit' }]
    : [{ field: 'date', value: 'This week' }, { field: 'tool', value: 'Edit' }];

  const dayStats = [
    { label: 'Active', value: fmtDur(dayTotals.active), accent: CT_TOKENS.active },
    { label: 'Away', value: fmtDur(8 * 60 + 12), sub: 'between sessions' },
    { label: 'Longest session', value: fmtDur(dayTotals.longest.active), sub: `${dayTotals.longest.project} · ${fmtClock(dayTotals.longest.start)}` },
    { label: 'Most-used tool', value: dayTotals.topTool[0], sub: `${dayTotals.topTool[1]} calls` },
  ];

  const weekActiveTotal = week.projects.reduce((a, p) =>
    a + p.rollup.reduce((b, d) => b + d.active + d.subagent, 0), 0);
  const weekProjectActive = week.projects
    .map(p => ({ alias: p.alias, total: p.rollup.reduce((a, d) => a + d.active + d.subagent, 0) }))
    .sort((a,b) => b.total - a.total);

  const weekStats = [
    { label: 'Active', value: fmtDur(weekActiveTotal), accent: CT_TOKENS.active },
    { label: 'Daily avg', value: fmtDur(Math.round(weekActiveTotal / 6)), sub: '6 active days' },
    { label: 'Top project', value: weekProjectActive[0].alias, sub: fmtDur(weekProjectActive[0].total) },
    { label: 'Most-used tool', value: 'Edit', sub: '428 calls' },
  ];

  return (
    <div style={{
      width: '100%', height: '100%',
      background: CT_TOKENS.bg,
      fontFamily: CT_TOKENS.sans,
      color: CT_TOKENS.textPrimary,
      display: 'flex', flexDirection: 'column',
      overflow: 'hidden',
    }}>
      {/* Design-canvas reference: passes static props through the new
          interactive-Toolbar prop shape. WP9 collapsed the duality
          (2026-05-23) — see Toolbar definition above for history. */}
      <Toolbar
        view={isDay ? 'day' : 'week'}
        onViewChange={() => {}}
        dateLabel={isDay ? 'Wed \u00b7 May 13, 2026' : 'May 11 \u2014 17, 2026'}
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
        }}>{isDay ? `${today.projects.length} projects · ${today.projects.reduce((a,p)=>a+p.sessions.length,0)} sessions` : `${week.projects.length} projects · 7 days`}</span>
        <span style={{ flex: 1 }} />
        <Legend />
        {/* WP9 Phase 4: project filter popover. Design-canvas page uses
            FilterContext default (no-op setter); the popover renders but
            toggling is a no-op there. Shipped Dashboard wraps with a real
            FilterContext.Provider. */}
        <ProjectFilterPopover projects={isDay ? today.projects : week.projects} />
      </div>

      {/* Body — timeline (+ optional side panel) */}
      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>
        {isDay ? (
          <DayTimeline
            data={today}
            expandedProjects={
              variant === 'detail'
                ? ['claude-time']
                : ['claude-time', 'agent-handoff-protocol']
            }
            selectedSegId={selectedSegId}
          />
        ) : (
          <WeekTimeline data={week} />
        )}
        {showSidePanel && (
          <SidePanel
            session={selSession}
            project={selProject}
            segment={{ idx: selSegIdx }}
          />
        )}
      </div>
    </div>
  );
}

window.Dashboard = Dashboard;
