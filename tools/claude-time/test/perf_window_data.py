#!/usr/bin/env python3
"""WP2 perf probe — measure `build_window_data` emit cost against a real DB.

Runs `build_window_data` N times (default 5) for each of several window sizes
(default 30/60/90/120 days) against the user's real `events.sqlite`. Reports
wall-clock and emit-size (JSON byte count) statistics as a Markdown table on
stdout. The script is permanent — re-run any time the data layer changes to
re-validate the 90-day default window decision.

Usage:
    CLAUDE_TIME_DIR=~/.claude-time python3 perf_window_data.py
    CLAUDE_TIME_DIR=~/.claude-time python3 perf_window_data.py --runs 10
    CLAUDE_TIME_DIR=~/.claude-time python3 perf_window_data.py --windows 90
    CLAUDE_TIME_DIR=~/.claude-time python3 perf_window_data.py --db-path /tmp/other.sqlite

Decision context (v3 WBS, 2026-05-28):
  The v3 emit model pre-renders all Day/Week/Month/Compare sub-payloads over a
  default 90-day window. This script measures the actual cost of that choice
  against real-world data to confirm the 90-day default OR counter-propose a
  smaller default.

  Budget thresholds:
    - wall-clock per emit  ≤ ~2s target, ~4s hard ceiling
    - emit-size per window ≤ ~500KB target, ~1MB hard ceiling

  See `workflow/wip/wp2-emit-perf-probe.md` for full decision criteria.

## Results

Measurement run 2026-05-28 against the author's real DB
(`~/.claude-time/events.sqlite`), default args (--runs 5, --windows 30,60,90,120):

    | window_days | start_iso  | end_iso    | min_ms | avg_ms | max_ms | emit_bytes_min | emit_bytes_avg | emit_bytes_max |
    |-------------|------------|------------|--------|--------|--------|----------------|----------------|----------------|
    |          30 | 2026-04-29 | 2026-05-28 |    990 |   1037 |   1194 |         421579 |         421579 |         421579 |
    |          60 | 2026-03-30 | 2026-05-28 |    989 |   1001 |   1014 |         426200 |         426200 |         426200 |
    |          90 | 2026-02-28 | 2026-05-28 |   1003 |   1012 |   1026 |         431016 |         431016 |         431016 |
    |         120 | 2026-01-29 | 2026-05-28 |   1018 |   1045 |   1142 |         435586 |         435586 |         435586 |

Findings:
- 90-day wall-clock: avg 1012ms ≤ 2000ms target (50% of budget). PASS.
- 90-day emit-size: 431KB ≤ 500KB target (86% of budget). PASS.
- Curve is approximately flat across 30→120 days (cost dominated by fixed
  overhead — SQLite open, import, compare-preset compute — not per-day work).
- Variance is OS-jitter level (±150ms max-vs-avg), within ±25% stability target.

Decision: **90-day default CONFIRMED.** See workflow archive for full rationale.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
import statistics
import sys
import time as time_mod
from datetime import date, datetime, time, timedelta
from importlib.machinery import SourceFileLoader
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
TOOL_DIR = Path(__file__).resolve().parent.parent

# Add tool dir to sys.path so `import viz_data` works.
sys.path.insert(0, str(TOOL_DIR))

import viz_data  # noqa: E402  (after sys.path mutation)


def _import_claude_time_module():
    """Import the hyphen-named `claude-time` entrypoint as a module.

    Gives us access to `load_config`, `_auto_alias_for_cwd`, and
    `_load_window_events` — the exact helpers `_cmd_visualize` uses — so the
    perf script measures the same code path the CLI runs in production.
    """
    entrypoint = TOOL_DIR / "claude-time"
    # The entrypoint has no .py extension, so loader-inference from the suffix
    # fails — pass a SourceFileLoader explicitly.
    loader = SourceFileLoader("claude_time_cli", str(entrypoint))
    spec = importlib.util.spec_from_loader("claude_time_cli", loader)
    if spec is None:
        raise RuntimeError(f"Cannot load {entrypoint} as a module")
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def _build_events_by_day(ct_cli, db_path: Path, start_day: date, end_day: date) -> dict[str, list[dict]]:
    """Load events for every day in [start_day, end_day] inclusive.

    Mirrors `_cmd_visualize`'s per-day loading pattern. The per-day call shape
    is what the CLI uses today; if `viz_data.py` ever moves to a single-window
    SQL load, update this helper to match — otherwise the probe measures the
    wrong code path.
    """
    events_by_day: dict[str, list[dict]] = {}
    current = start_day
    while current <= end_day:
        events_by_day[current.isoformat()] = ct_cli._load_window_events(db_path, current)
        current += timedelta(days=1)
    return events_by_day


def _measure_one_window(
    *,
    window_days: int,
    runs: int,
    db_path: Path,
    ct_cli,
    cfg: dict,
) -> dict:
    """Run `build_window_data` `runs` times for an N-day window; return stats."""
    today = date.today()
    end_day = today
    start_day = today - timedelta(days=window_days - 1)
    start_iso, end_iso = start_day.isoformat(), end_day.isoformat()

    # Load events once per run (SQLite cache will warm; we still time this as
    # part of "emit cost" because the CLI re-loads on every invocation too).
    wall_ms: list[float] = []
    emit_bytes: list[int] = []
    for _ in range(runs):
        t0 = time_mod.perf_counter()
        events_by_day = _build_events_by_day(ct_cli, db_path, start_day, end_day)
        payload = viz_data.build_window_data(
            start_iso,
            end_iso,
            events_by_day=events_by_day,
            cfg=cfg,
            auto_alias_fn=ct_cli._auto_alias_for_cwd,
        )
        # Match the CLI's JSON serialization (compact, no indent).
        encoded = json.dumps(payload, separators=(",", ":"), default=str)
        t1 = time_mod.perf_counter()
        wall_ms.append((t1 - t0) * 1000.0)
        emit_bytes.append(len(encoded.encode("utf-8")))

    def _round(x: float) -> int:
        return int(round(x))

    return {
        "window_days": window_days,
        "start_iso": start_iso,
        "end_iso": end_iso,
        "min_ms": _round(min(wall_ms)),
        "avg_ms": _round(statistics.mean(wall_ms)),
        "max_ms": _round(max(wall_ms)),
        "emit_bytes_min": min(emit_bytes),
        "emit_bytes_avg": _round(statistics.mean(emit_bytes)),
        "emit_bytes_max": max(emit_bytes),
    }


def _format_results_table(rows: list[dict]) -> str:
    """Render a stdout Markdown table — readable & paste-into-WIP friendly."""
    header = (
        "| window_days | start_iso  | end_iso    | min_ms | avg_ms | max_ms |"
        " emit_bytes_min | emit_bytes_avg | emit_bytes_max |"
    )
    sep = (
        "|-------------|------------|------------|--------|--------|--------|"
        "----------------|----------------|----------------|"
    )
    lines = [header, sep]
    for r in rows:
        lines.append(
            f"| {r['window_days']:>11} | {r['start_iso']} | {r['end_iso']} |"
            f" {r['min_ms']:>6} | {r['avg_ms']:>6} | {r['max_ms']:>6} |"
            f" {r['emit_bytes_min']:>14} | {r['emit_bytes_avg']:>14} | {r['emit_bytes_max']:>14} |"
        )
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        description="WP2 perf probe: measure build_window_data emit cost.",
    )
    ap.add_argument(
        "--runs", type=int, default=5,
        help="Number of timed runs per window size (default: 5)",
    )
    ap.add_argument(
        "--windows", default="30,60,90,120",
        help="Comma-separated window sizes in days (default: 30,60,90,120)",
    )
    ap.add_argument(
        "--db-path", default=None,
        help="Path to events.sqlite (default: $CLAUDE_TIME_DIR/events.sqlite)",
    )
    args = ap.parse_args(argv)

    ct_dir_str = os.environ.get("CLAUDE_TIME_DIR")
    if not ct_dir_str:
        print("ERROR: CLAUDE_TIME_DIR not set", file=sys.stderr)
        return 1
    ct_dir = Path(ct_dir_str).expanduser()

    db_path = Path(args.db_path).expanduser() if args.db_path else (ct_dir / "events.sqlite")
    if not db_path.exists():
        print(f"ERROR: DB not found at {db_path}", file=sys.stderr)
        return 1

    try:
        windows = [int(w.strip()) for w in args.windows.split(",") if w.strip()]
    except ValueError as e:
        print(f"ERROR: --windows must be comma-separated ints: {e}", file=sys.stderr)
        return 1
    if not windows:
        print("ERROR: --windows produced an empty list", file=sys.stderr)
        return 1

    ct_cli = _import_claude_time_module()
    cfg = ct_cli.load_config(ct_dir)

    print(f"# build_window_data perf probe", flush=True)
    print(f"# db: {db_path}", flush=True)
    print(f"# runs per window: {args.runs}", flush=True)
    print(f"# windows: {windows}", flush=True)
    print(f"# today: {date.today().isoformat()}", flush=True)
    print("", flush=True)

    rows: list[dict] = []
    for w in windows:
        print(f"... measuring window={w}d (runs={args.runs})", file=sys.stderr, flush=True)
        rows.append(_measure_one_window(
            window_days=w, runs=args.runs, db_path=db_path,
            ct_cli=ct_cli, cfg=cfg,
        ))

    print(_format_results_table(rows))
    return 0


if __name__ == "__main__":
    sys.exit(main())
