// Mock session data for claude-time dashboard
// Times are in minutes-from-midnight for simplicity.

window.CT_DATA = (() => {
  // Helper: minutes from "HH:MM"
  const t = (s) => {
    const [h, m] = s.split(':').map(Number);
    return h * 60 + m;
  };

  // ── Segment types ─────────────────────────────────────────────
  // active   — deep indigo solid
  // reading  — desat lavender
  // thinking — muted amber
  // away     — hairline stripes (rendered as background)
  // subagent — teal nested inside its parent

  // ── Today (Wed May 13, 2026) ──────────────────────────────────
  // WP12 P2.4: hour_range extended from [6, 23] to [6, 24] to fit the new
  // s8/s9 overlap pair at 22:00–23:30. Adds 1 hour of headroom — does not
  // change any existing session's render position.
  const today = {
    label: 'WED · MAY 13',
    iso: '2026-05-13',
    hour_range: [6, 24],  // [start, end_exclusive] — matches viz_data.build_day_data shape
    projects: [
      {
        id: 'claude-time',
        alias: 'claude-time',
        path: '~/code/claude-time',
        sessions: [
          {
            id: 's1',
            start: t('08:42'), end: t('10:15'),
            prompts: 14,
            tools: { Edit: 22, Write: 6, Bash: 11, Read: 18 },
            segs: [
              { kind: 'active',   start: t('08:42'), end: t('09:18') },
              { kind: 'reading',  start: t('09:18'), end: t('09:24') },
              { kind: 'active',   start: t('09:24'), end: t('10:02') },
              { kind: 'thinking', start: t('10:02'), end: t('10:08') },
              { kind: 'active',   start: t('10:08'), end: t('10:15') },
            ],
          },
          {
            id: 's2',
            start: t('11:12'), end: t('13:47'),
            prompts: 21,
            tools: { Edit: 38, Write: 4, Bash: 17, Read: 29, Grep: 12 },
            segs: [
              { kind: 'active',   start: t('11:12'), end: t('12:14') },
              { kind: 'subagent', start: t('12:14'), end: t('12:38'), label: 'Explore' },
              { kind: 'active',   start: t('12:38'), end: t('13:05') },
              { kind: 'reading',  start: t('13:05'), end: t('13:18') },
              { kind: 'active',   start: t('13:18'), end: t('13:47') },
            ],
          },
          {
            id: 's3',
            start: t('16:45'), end: t('17:32'),
            prompts: 8,
            tools: { Edit: 11, Bash: 5, Read: 7 },
            segs: [
              { kind: 'active',   start: t('16:45'), end: t('17:12') },
              { kind: 'thinking', start: t('17:12'), end: t('17:18') },
              { kind: 'active',   start: t('17:18'), end: t('17:32') },
            ],
          },
          // WP12 P2.4: late-night session that overlaps with agent-handoff-protocol's
          // s9 from 22:30 to 23:00 — exercises the overlap detector + overlay layer
          // + side-panel "Overlaps with" section + HeadlineCard Parallel tile.
          // Cross-project overlap; does NOT trigger a collapsed-row marker (markers
          // are within-project only — see P2.verify-human.2). Distinct session-id
          // prefix (`s8`, not colliding with `s1`–`s7`) per the
          // SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE mitigation.
          {
            id: 's8',
            start: t('22:00'), end: t('23:00'),
            prompts: 5,
            tools: { Edit: 6, Bash: 3, Read: 4 },
            segs: [
              { kind: 'active', start: t('22:00'), end: t('23:00') },
            ],
          },
          // WP12 P2.verify-human.2: within-project overlap pair — s10 overlaps
          // with s8 (both in claude-time) from 22:15 to 22:45 (30 min). This is
          // the scenario the collapsed-row marker is FOR: two terminals open in
          // the same cwd / same project. Triggers a marker on the claude-time
          // collapsed row.
          {
            id: 's10',
            start: t('22:15'), end: t('22:45'),
            prompts: 2,
            tools: { Edit: 3, Read: 2 },
            segs: [
              { kind: 'active', start: t('22:15'), end: t('22:45') },
            ],
          },
        ],
      },
      {
        id: 'agent-handoff-protocol',
        alias: 'agent-handoff-protocol',
        path: '~/work/agent-handoff-protocol',
        sessions: [
          {
            id: 's4',
            start: t('10:30'), end: t('10:48'),
            prompts: 3,
            tools: { Read: 9, Grep: 4 },
            segs: [
              { kind: 'reading', start: t('10:30'), end: t('10:36') },
              { kind: 'active',  start: t('10:36'), end: t('10:48') },
            ],
          },
          {
            id: 's5',
            start: t('14:02'), end: t('15:38'),
            prompts: 12,
            tools: { Edit: 19, Write: 2, Bash: 8, Read: 14 },
            segs: [
              { kind: 'active',   start: t('14:02'), end: t('14:41') },
              { kind: 'thinking', start: t('14:41'), end: t('14:52') },
              { kind: 'active',   start: t('14:52'), end: t('15:20') },
              { kind: 'subagent', start: t('15:20'), end: t('15:32'), label: 'Plan' },
              { kind: 'active',   start: t('15:32'), end: t('15:38') },
            ],
          },
          // WP12 P2.4: late-night peer session overlapping with claude-time's s8
          // from 22:30 to 23:00. See s8 for the overlap-pair purpose.
          {
            id: 's9',
            start: t('22:30'), end: t('23:30'),
            prompts: 4,
            tools: { Edit: 5, Bash: 2, Read: 3 },
            segs: [
              { kind: 'active', start: t('22:30'), end: t('23:30') },
            ],
          },
        ],
      },
      {
        id: 'om-design-system',
        alias: 'om-design-system',
        path: '~/work/om/design-system',
        sessions: [
          {
            id: 's6',
            start: t('15:48'), end: t('16:36'),
            prompts: 9,
            tools: { Edit: 14, Read: 11, Bash: 3 },
            segs: [
              { kind: 'active',   start: t('15:48'), end: t('16:14') },
              { kind: 'reading',  start: t('16:14'), end: t('16:22') },
              { kind: 'active',   start: t('16:22'), end: t('16:36') },
            ],
          },
        ],
      },
      {
        id: 'weekend-tinkering',
        alias: 'weekend-tinkering',
        path: '~/personal/weekend-tinkering',
        sessions: [
          {
            id: 's7',
            start: t('19:20'), end: t('21:08'),
            prompts: 6,
            tools: { Edit: 7, Bash: 4, Read: 12 },
            segs: [
              { kind: 'reading',  start: t('19:20'), end: t('19:35') },
              { kind: 'active',   start: t('19:35'), end: t('20:04') },
              { kind: 'thinking', start: t('20:04'), end: t('20:18') },
              { kind: 'active',   start: t('20:18'), end: t('20:48') },
              { kind: 'reading',  start: t('20:48'), end: t('21:08') },
            ],
          },
        ],
      },
    ],
  };

  // ── Week view (May 11 – May 17, 2026) — project rollups ───────
  // For each project, an array of 7 days with total active minutes
  // and a coarse segment breakdown for the day's rollup bar.
  const week = {
    label: 'WEEK 20 · MAY 11 — MAY 17',
    days: ['MON 11', 'TUE 12', 'WED 13', 'THU 14', 'FRI 15', 'SAT 16', 'SUN 17'],
    projects: [
      {
        id: 'claude-time',
        alias: 'claude-time',
        rollup: [
          { active: 184, reading: 22, thinking: 18, away: 0,  subagent: 14, prompts: 38 },
          { active: 142, reading: 18, thinking: 22, away: 0,  subagent: 8,  prompts: 27 },
          { active: 168, reading: 31, thinking: 19, away: 0,  subagent: 24, prompts: 43 },
          { active: 96,  reading: 12, thinking: 14, away: 0,  subagent: 0,  prompts: 19 },
          { active: 211, reading: 28, thinking: 22, away: 0,  subagent: 18, prompts: 51 },
          { active: 42,  reading: 8,  thinking: 4,  away: 0,  subagent: 0,  prompts: 7  },
          { active: 0,   reading: 0,  thinking: 0,  away: 0,  subagent: 0,  prompts: 0  },
        ],
      },
      {
        id: 'agent-handoff-protocol',
        alias: 'agent-handoff-protocol',
        rollup: [
          { active: 84,  reading: 11, thinking: 8,  away: 0, subagent: 0,  prompts: 14 },
          { active: 122, reading: 19, thinking: 11, away: 0, subagent: 12, prompts: 24 },
          { active: 114, reading: 17, thinking: 12, away: 0, subagent: 12, prompts: 22 },
          { active: 178, reading: 24, thinking: 18, away: 0, subagent: 16, prompts: 38 },
          { active: 98,  reading: 14, thinking: 8,  away: 0, subagent: 0,  prompts: 17 },
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0,  prompts: 0  },
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0,  prompts: 0  },
        ],
      },
      {
        id: 'om-design-system',
        alias: 'om-design-system',
        rollup: [
          { active: 38,  reading: 8,  thinking: 4,  away: 0, subagent: 0, prompts: 7  },
          { active: 62,  reading: 11, thinking: 6,  away: 0, subagent: 0, prompts: 12 },
          { active: 48,  reading: 8,  thinking: 4,  away: 0, subagent: 0, prompts: 9  },
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0, prompts: 0  },
          { active: 124, reading: 18, thinking: 11, away: 0, subagent: 8, prompts: 26 },
          { active: 88,  reading: 14, thinking: 7,  away: 0, subagent: 0, prompts: 16 },
          { active: 18,  reading: 4,  thinking: 2,  away: 0, subagent: 0, prompts: 3  },
        ],
      },
      {
        id: 'weekend-tinkering',
        alias: 'weekend-tinkering',
        rollup: [
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0, prompts: 0  },
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0, prompts: 0  },
          { active: 88,  reading: 20, thinking: 14, away: 0, subagent: 0, prompts: 6  },
          { active: 32,  reading: 8,  thinking: 4,  away: 0, subagent: 0, prompts: 4  },
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0, prompts: 0  },
          { active: 168, reading: 28, thinking: 18, away: 0, subagent: 0, prompts: 21 },
          { active: 142, reading: 24, thinking: 14, away: 0, subagent: 0, prompts: 17 },
        ],
      },
      {
        id: 'crt-shader-experiments',
        alias: 'crt-shader-experiments',
        rollup: [
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0, prompts: 0  },
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0, prompts: 0  },
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0, prompts: 0  },
          { active: 64,  reading: 11, thinking: 6,  away: 0, subagent: 0, prompts: 9  },
          { active: 22,  reading: 4,  thinking: 2,  away: 0, subagent: 0, prompts: 4  },
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0, prompts: 0  },
          { active: 0,   reading: 0,  thinking: 0,  away: 0, subagent: 0, prompts: 0  },
        ],
      },
    ],
  };

  return { today, week };
})();
