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
// Hour-ruler bounds derive from `window.CT_DATA.today.hour_range` (emitted
// adaptively by viz_data.build_day_data as [start, end_exclusive] —
// e.g. [6, 23] means 17 hour ticks: 06:00..22:00). Falls back to [6, 23]
// when CT_DATA is absent (defensive — keeps the design-canvas prototype
// happy if loaded standalone) or `hour_range` is missing.
const _CT_HR = (
  (typeof window !== 'undefined' && window.CT_DATA && window.CT_DATA.today && window.CT_DATA.today.hour_range)
    ? window.CT_DATA.today.hour_range
    : [6, 23]
);
const DAY_HOURS = Array.from({ length: Math.max(1, _CT_HR[1] - _CT_HR[0]) }, (_, i) => _CT_HR[0] + i);
const DAY_START_MIN = DAY_HOURS[0] * 60;
const DAY_END_MIN   = (DAY_HOURS[DAY_HOURS.length - 1] + 1) * 60;
const DAY_RANGE_MIN = DAY_END_MIN - DAY_START_MIN;
const ROW_LEFT_WIDTH = 232;
const ROW_HEIGHT = 36;
const PROJECT_HEADER_HEIGHT = 40;
const NOW_MIN = 17 * 60 + 22; // 17:22 — current marker

function pct(start, end) {
  const left = ((start - DAY_START_MIN) / DAY_RANGE_MIN) * 100;
  const width = ((end - start) / DAY_RANGE_MIN) * 100;
  return { left: `${left}%`, width: `${width}%` };
}

function HourRuler({ nowFrac }) {
  return (
    <div style={{
      height: 30,
      position: 'relative',
      borderBottom: `1px solid ${CT_TOKENS.border}`,
      background: CT_TOKENS.surfaceAlt,
      display: 'flex',
    }}>
      {DAY_HOURS.map((h) => (
        <div key={h} style={{
          flex: 1, position: 'relative',
          borderRight: `1px solid ${CT_TOKENS.gridHour}`,
          display: 'flex', alignItems: 'center', paddingLeft: 6,
        }}>
          <span style={{
            fontFamily: CT_TOKENS.mono, fontSize: 10.5,
            color: CT_TOKENS.textTertiary, letterSpacing: '0.02em',
          }}>{String(h).padStart(2,'0')}:00</span>
        </div>
      ))}
      {nowFrac != null && (
        <div style={{
          position: 'absolute', top: 0, bottom: -1,
          left: `${nowFrac * 100}%`,
          width: 1.5,
          background: 'oklch(0.55 0.18 25)',
        }}>
          <span style={{
            position: 'absolute', top: 4, left: 4,
            fontFamily: CT_TOKENS.mono, fontSize: 10,
            color: 'oklch(0.45 0.20 25)', fontWeight: 500,
          }}>NOW · 17:22</span>
        </div>
      )}
    </div>
  );
}

function HourGridBackground() {
  return (
    <div style={{
      position: 'absolute', inset: 0, pointerEvents: 'none',
      display: 'flex',
    }}>
      {DAY_HOURS.map((h) => (
        <div key={h} style={{
          flex: 1, borderRight: `1px solid ${CT_TOKENS.gridHour}`,
        }} />
      ))}
    </div>
  );
}

function SegmentBar({ seg, selected = false }) {
  const { left, width } = pct(seg.start, seg.end);
  const isSubagent = seg.kind === 'subagent';
  const height = isSubagent ? 14 : ROW_HEIGHT - 12;
  const top = isSubagent ? (ROW_HEIGHT - 14) / 2 + 4 : 6;
  return (
    <div
      title={`${seg.kind} · ${fmtClock(seg.start)}–${fmtClock(seg.end)}`}
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
      <div style={{ flex: 1, position: 'relative' }}>
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
      <div style={{ flex: 1, position: 'relative' }}>
        <HourGridBackground />
        {session.segs.map((seg, i) => (
          <SegmentBar key={i} seg={seg} selected={`${session.id}:${i}` === selectedSegId} />
        ))}
      </div>
    </div>
  );
}

/* ── Day view (project list + sessions) ─────────────────────── */
function DayTimeline({ data, expandedProjects, selectedSegId, showNow = true }) {
  const nowFrac = showNow ? (NOW_MIN - DAY_START_MIN) / DAY_RANGE_MIN : null;

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
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', background: CT_TOKENS.surface }}>
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
          <HourRuler nowFrac={nowFrac} />
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
