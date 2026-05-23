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

/* ── Toolbar ────────────────────────────────────────────────── */
function Toolbar({ activeRange = 'today', activeZoom = 'day', dateLabel, dark = false }) {
  const tabBtn = (label, value, current) => (
    <button key={value} style={{
      background: current ? CT_TOKENS.surface : 'transparent',
      color: current ? CT_TOKENS.textPrimary : CT_TOKENS.textSecondary,
      border: 'none',
      borderRadius: 6,
      padding: '6px 12px',
      fontSize: 13,
      fontWeight: current ? 550 : 450,
      fontFamily: CT_TOKENS.sans,
      cursor: 'pointer',
      boxShadow: current ? '0 1px 2px rgba(20,18,12,0.06), inset 0 0 0 1px ' + CT_TOKENS.border : 'none',
    }}>{label}</button>
  );
  const segGroup = (items, current) => (
    <div style={{
      display: 'flex',
      gap: 2,
      padding: 3,
      background: CT_TOKENS.surfaceDim,
      borderRadius: 8,
      border: `1px solid ${CT_TOKENS.border}`,
    }}>
      {items.map(([l, v]) => tabBtn(l, v, v === current))}
    </div>
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
          <span style={{ fontSize: 11, color: CT_TOKENS.textTertiary, fontFamily: CT_TOKENS.mono }}>v0.4.2</span>
        </div>
      </div>

      <div style={{ width: 1, height: 22, background: CT_TOKENS.border, margin: '0 4px' }} />

      {/* Range tabs */}
      {segGroup([['Today','today'],['Week','week'],['Month','month'],['Custom','custom']], activeRange)}

      {/* Date stepper */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 2, padding: 3, background: CT_TOKENS.surfaceDim, borderRadius: 8, border: `1px solid ${CT_TOKENS.border}` }}>
        <button style={iconBtn()}><IconChevLeft size={12} /></button>
        <button style={{ ...iconBtn(), width: 'auto', padding: '0 10px', gap: 6, fontFamily: CT_TOKENS.mono, fontSize: 12, color: CT_TOKENS.textPrimary }}>
          <IconCalendar size={12} />
          {dateLabel}
        </button>
        <button style={iconBtn()}><IconChevRight size={12} /></button>
      </div>

      <div style={{ flex: 1 }} />

      {/* Filters */}
      <button style={{
        display: 'flex', alignItems: 'center', gap: 6,
        height: 30, padding: '0 10px',
        background: 'transparent', border: `1px solid ${CT_TOKENS.border}`,
        borderRadius: 7, fontFamily: CT_TOKENS.sans, fontSize: 12, color: CT_TOKENS.textSecondary, cursor: 'pointer',
      }}>
        <IconFilter size={12} />
        Filters
        <span style={{
          fontFamily: CT_TOKENS.mono, fontSize: 10,
          padding: '1px 5px', borderRadius: 3,
          background: CT_TOKENS.surfaceDim, color: CT_TOKENS.textSecondary,
        }}>2</span>
      </button>
      <button style={iconChromeBtn()}><IconRefresh size={13} /></button>
      <button style={iconChromeBtn()}><IconMoon size={13} /></button>
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

/* ── Legend ─────────────────────────────────────────────────── */
function Legend() {
  const items = [
    { label: 'Active coding', color: CT_TOKENS.active },
    { label: 'Reading', color: CT_TOKENS.reading },
    { label: 'Thinking', color: CT_TOKENS.thinking },
    { label: 'Subagent', color: CT_TOKENS.subagent },
    { label: 'Away', stripe: true },
  ];
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
      {items.map((it, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{
            width: 14, height: 8, borderRadius: 2,
            ...(it.stripe ? segStyle('away') : { background: it.color }),
            border: it.stripe ? `1px solid ${CT_TOKENS.border}` : 'none',
          }} />
          <span style={{ fontSize: 11, color: CT_TOKENS.textSecondary, fontFamily: CT_TOKENS.sans }}>{it.label}</span>
        </div>
      ))}
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
// Initial viewport derives from `window.CT_DATA.today.hour_range` (emitted
// adaptively by viz_data.build_day_data as [start, end_exclusive] —
// e.g. [6, 23] means 17 hour ticks: 06:00..22:00). Falls back to [6, 23]
// when CT_DATA is absent (defensive — keeps the design-canvas prototype
// happy if loaded standalone) or `hour_range` is missing.
function _initialViewport() {
  const hr = (
    (typeof window !== 'undefined' && window.CT_DATA && window.CT_DATA.today && window.CT_DATA.today.hour_range)
      ? window.CT_DATA.today.hour_range
      : [6, 23]
  );
  const visible_start_min = hr[0] * 60;
  const visible_end_min   = hr[1] * 60;
  return { visible_start_min, visible_end_min };
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

// WP5 Phase 2: ruler tick density adapts to zoom. Returns the densest
// interval (minutes) from [60, 30, 15, 10, 5, 1] that produces between
// 8 and 30 visible ticks in the current viewport. Phase 1 used a hardcoded
// 60-minute interval via hoursInViewport(); pickTickInterval generalizes
// that for arbitrary viewport ranges (1-minute extreme zoom-in up to
// multi-day zoom-out).
function pickTickInterval(viewport) {
  const range = viewport.visible_end_min - viewport.visible_start_min;
  const scales = [60, 30, 15, 10, 5, 1];
  for (const m of scales) {
    const ticks = Math.ceil(range / m);
    if (ticks >= 8 && ticks <= 30) return m;
  }
  // Edge cases: very small range (< 8 minutes) → 1m ticks; very large
  // range (> 30h) → 60m ticks (visually sparse but at least readable).
  if (range < 8) return 1;
  return 60;
}

// WP5 Phase 2: tick generator. Emits an array of minute-aligned tick
// positions covering the viewport at the given interval. Each tick has a
// minute-of-day value and a label. The first tick at-or-after
// visible_start_min that aligns to the interval is the start.
function ticksInViewport(viewport, intervalMin) {
  const startTick = Math.ceil(viewport.visible_start_min / intervalMin) * intervalMin;
  const out = [];
  for (let t = startTick; t < viewport.visible_end_min; t += intervalMin) {
    const h = Math.floor(t / 60);
    const m = t % 60;
    // Label format: HH:00 for hour ticks, HH:MM otherwise.
    const label = intervalMin === 60
      ? `${String(h).padStart(2,'0')}:00`
      : `${String(h).padStart(2,'0')}:${String(m).padStart(2,'0')}`;
    out.push({ min: t, label });
  }
  return out;
}

const ROW_LEFT_WIDTH = 232;
const ROW_HEIGHT = 36;
const PROJECT_HEADER_HEIGHT = 40;
// NOW marker is computed client-side via useNowMin() (see DayTimeline below).
// v1 used a hardcoded module-level NOW_MIN that froze on every emit; removed in WP2.

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
  const intervalMin = pickTickInterval(viewport);
  const ticks = ticksInViewport(viewport, intervalMin);
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
  const intervalMin = pickTickInterval(viewport);
  const ticks = ticksInViewport(viewport, intervalMin);
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

function SegmentBar({ seg, selected = false }) {
  const viewport = useViewport();
  const { left, width } = viewportPct(seg.start, seg.end, viewport);
  const isSubagent = seg.kind === 'subagent';
  const height = isSubagent ? 14 : ROW_HEIGHT - 12;
  const top = isSubagent ? (ROW_HEIGHT - 14) / 2 + 4 : 6;
  return (
    <div
      title={`${seg.kind} · ${fmtClock(seg.start)}–${fmtClock(seg.end)}`}
      data-seg-id={`${seg.kind}-${seg.start}-${seg.end}`}
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
  const totalActive = sumActive(session.segs);
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
          <SegmentBar key={i} seg={seg} selected={`${session.id}:${i}` === selectedSegId} />
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
  // Data-window for clamping zoom-out + Home/End. For the day view, fall
  // back to [0, 1440] (full day in minutes) if no explicit window present.
  const dataWindow = (data && data.hour_range)
    ? [data.hour_range[0] * 60, data.hour_range[1] * 60]
    : [0, 1440];
  const gestures = useTimelineGestures(viewport, setViewport, dataWindow);
  // Only show the marker when (a) caller opts in, (b) the day being rendered IS today
  // (compare ISO date, since "now" is undefined for past days), and (c) nowMin lies
  // within the current viewport (replaces WP1's DAY_*-bound check; pan/zoom now move
  // the viewport rather than the day-window). The frac/label only render when all three hold.
  const isToday = data && data.iso === todayISO;
  const inWindow = nowMin >= viewport.visible_start_min && nowMin < viewport.visible_end_min;
  const nowFrac = (showNow && isToday && inWindow)
    ? (nowMin - viewport.visible_start_min) / (viewport.visible_end_min - viewport.visible_start_min)
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
          <HourRuler nowFrac={nowFrac} nowLabel={nowLabel} nowMin={isToday && inWindow ? nowMin : null} />
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
        {data.projects.map((p, pi) => {
          const expanded = expandedProjects.includes(p.id);
          return (
            <React.Fragment key={p.id}>
              <ProjectHeaderRow project={p} totals={totalsByProject[p.id]} expanded={expanded} alt={pi % 2 === 1} />
              {expanded && p.sessions.map((s, si) => (
                <SessionRow
                  key={s.id}
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

  // Data window: union of all sessions' segment ranges, falling back to
  // hour_range or [0, 1440]. The minimap maps this range to its full width.
  const dataWindow = React.useMemo(() => {
    if (data && data.hour_range) {
      return [data.hour_range[0] * 60, data.hour_range[1] * 60];
    }
    return [0, 1440];
  }, [data]);

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
  const allSegs = (data && data.projects)
    ? data.projects.flatMap(p => p.sessions.flatMap(s => s.segs))
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
      <Toolbar
        activeRange={isDay ? 'today' : 'week'}
        activeZoom={isDay ? 'day' : 'week'}
        dateLabel={isDay ? 'Wed · May 13, 2026' : 'May 11 — 17, 2026'}
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
