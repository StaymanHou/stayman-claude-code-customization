#!/usr/bin/env python3
"""Seed a synthetic 1-month dataset for WP5 Phase 4 perf measurement.

Produces ~30 days × ~3 sessions × ~20 segments = ~1800 segments in the
events table at $CLAUDE_TIME_DIR/events.sqlite. Used by
`test_visualize_interactive.sh` to load a heavy dataset into the dashboard
for pan/zoom fps benchmarking.

The shape mirrors test_visualize_cli.sh's seeding pattern (UPS / PreToolUse /
PostToolUse / Stop event sequence) but at higher volume across a date range.

Usage:
    CLAUDE_TIME_DIR=/tmp/ct-perf python3 seed_perf_dataset.py [--days N]

Output: prints the path to the seeded DB.
"""
import argparse
import os
import sqlite3
import sys
from datetime import date, datetime, time, timedelta


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=30,
                    help="Number of trailing days to seed (default: 30)")
    ap.add_argument("--sessions-per-day", type=int, default=3,
                    help="Sessions per day (default: 3)")
    ap.add_argument("--segments-per-session", type=int, default=20,
                    help="Segments per session (default: 20)")
    ap.add_argument("--end-date", default=None,
                    help="End date in YYYY-MM-DD (default: today)")
    args = ap.parse_args()

    ct_dir = os.environ.get("CLAUDE_TIME_DIR")
    if not ct_dir:
        print("ERROR: CLAUDE_TIME_DIR not set", file=sys.stderr)
        sys.exit(1)
    os.makedirs(ct_dir, exist_ok=True)
    db_path = os.path.join(ct_dir, "events.sqlite")

    end = date.fromisoformat(args.end_date) if args.end_date else date.today()
    start = end - timedelta(days=args.days - 1)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.executescript("""
        DROP TABLE IF EXISTS events;
        CREATE TABLE events (
            ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
            event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
        );
        CREATE INDEX idx_session_ts ON events(session_id, ts);
        CREATE INDEX idx_ts ON events(ts);
    """)

    projects = [
        "/repo/claude-time-perf",
        "/repo/agent-handoff",
        "/repo/om-design-system",
    ]
    tools = ["Edit", "Read", "Bash", "Grep", "Glob", "Write"]

    # Session ID format: each session globally unique within the first 8
    # characters. viz_data.py truncates `session_id[:8]` for display (line
    # 288); seeds like `perf-2026-05-23-0` collide at the first 8 chars
    # (`perf-202`) and trigger React duplicate-key warnings in DayTimeline.
    # Use a counter-prefixed scheme: `<8charA>-<full-detail>`.
    total_segments = 0
    session_counter = 0
    d = start
    while d <= end:
        for sess_idx in range(args.sessions_per_day):
            # 8-char-unique prefix: "p" + base36-ish 7-digit counter.
            # Up to 36^7 = ~78B sessions before collision; plenty.
            counter_hex = f"{session_counter:07x}"
            session_id = f"p{counter_hex}-{d.isoformat()}-{sess_idx}"
            session_counter += 1
            cwd = projects[sess_idx % len(projects)]
            # Session window: spaced across 9:00, 13:00, 17:00 (rough thirds).
            session_start_hour = 9 + sess_idx * 4
            session_start = datetime.combine(d, time(session_start_hour, 0))
            session_start_ms = int(session_start.timestamp() * 1000)

            # UPS at session start
            cur.execute(
                "INSERT INTO events VALUES (?,?,?,?,?,?,?)",
                (session_start_ms, session_id, cwd, "UserPromptSubmit",
                 None, None, '{"prompt_length_chars": 100}')
            )

            # Segments: alternating PreToolUse / PostToolUse pairs, ~3 min each,
            # creating ~segments_per_session/2 tool segments + active-time gaps.
            t = session_start_ms + 30_000  # 30s after UPS
            for seg_idx in range(args.segments_per_session):
                tool = tools[seg_idx % len(tools)]
                tool_use_id = f"t{sess_idx}-{seg_idx}"
                # Tool start
                cur.execute(
                    "INSERT INTO events VALUES (?,?,?,?,?,?,?)",
                    (t, session_id, cwd, "PreToolUse", tool, None,
                     f'{{"tool_use_id":"{tool_use_id}"}}')
                )
                # Tool end (90s later)
                t += 90_000
                cur.execute(
                    "INSERT INTO events VALUES (?,?,?,?,?,?,?)",
                    (t, session_id, cwd, "PostToolUse", tool, None,
                     f'{{"tool_use_id":"{tool_use_id}"}}')
                )
                # Gap to next tool (~90s)
                t += 90_000
                total_segments += 1

            # Stop at end of session
            cur.execute(
                "INSERT INTO events VALUES (?,?,?,?,?,?,?)",
                (t, session_id, cwd, "Stop", None, None, None)
            )
        d += timedelta(days=1)

    conn.commit()
    conn.close()

    print(db_path)
    print(f"  seeded: {args.days} days × {args.sessions_per_day} sessions × "
          f"{args.segments_per_session} segments = {total_segments} segments total",
          file=sys.stderr)
    print(f"  date range: {start.isoformat()} → {end.isoformat()}", file=sys.stderr)


if __name__ == "__main__":
    main()
