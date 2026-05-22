"""Unit tests for tools/claude-time/viz_data.py.

Run via:
  cd tools/claude-time/test && python3 -m unittest test_viz_data
"""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

_HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE.parent))
import viz_data  # noqa: E402


# Build a fake event-row dict matching the existing `events` table shape.
def ev(ts, sid, event, **kw):
    return {
        "ts": ts,
        "session_id": sid,
        "event": event,
        "cwd": kw.pop("cwd", "/repo/proj"),
        "tool_name": kw.pop("tool_name", None),
        "agent_type": kw.pop("agent_type", None),
        "meta": kw.pop("meta", None),
    }


def stub_auto_alias(cwd):
    """Test stub: cwd "/repo/foo" → "foo"."""
    return Path(cwd).name if cwd else "misc"


CFG = {
    "chars_per_sec": 6.0,
    "reading_threshold_sec": 120,
    "thinking_threshold_sec": 300,
    "project_names": {},
}


# Time helpers: 2026-05-13 local midnight in ms.
import datetime as _dt
_DAY = _dt.date(2026, 5, 13)
_DAY_START_MS = int(_dt.datetime.combine(_DAY, _dt.time.min).timestamp() * 1000)


def ms_at(hh, mm):
    """Convert HH:MM on 2026-05-13 local time to unix ms."""
    return _DAY_START_MS + (hh * 60 + mm) * 60_000


class BuildDayDataShapeTests(unittest.TestCase):
    """Top-level shape must match data.js's `today` literal."""

    def test_empty_day(self):
        out = viz_data.build_day_data("2026-05-13", [], CFG, stub_auto_alias)
        self.assertEqual(out["iso"], "2026-05-13")
        self.assertEqual(out["projects"], [])
        self.assertTrue(out["empty"])
        self.assertEqual(out["hour_range"], [6, 23])
        self.assertIn("label", out)

    def test_single_burst_shape(self):
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", cwd="/repo/proj-a",
               meta='{"prompt_length_chars": 12}'),
            ev(ms_at(9, 5), "sid-1", "PreToolUse", cwd="/repo/proj-a",
               tool_name="Edit", meta='{"tool_use_id":"t1"}'),
            ev(ms_at(9, 6), "sid-1", "PostToolUse", cwd="/repo/proj-a",
               tool_name="Edit", meta='{"tool_use_id":"t1"}'),
            ev(ms_at(9, 30), "sid-1", "Stop", cwd="/repo/proj-a"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        self.assertEqual(out["iso"], "2026-05-13")
        self.assertFalse(out.get("empty", False))
        self.assertEqual(len(out["projects"]), 1)
        p = out["projects"][0]
        self.assertEqual(p["alias"], "proj-a")
        self.assertEqual(p["path"], "/repo/proj-a")
        self.assertEqual(len(p["sessions"]), 1)
        s = p["sessions"][0]
        # Session window: 9:00 → 9:30 in minutes-from-midnight = 540 → 570.
        self.assertEqual(s["start"], 9 * 60)
        self.assertEqual(s["end"], 9 * 60 + 30)
        self.assertEqual(s["prompts"], 1)
        self.assertEqual(s["tools"], {"Edit": 1})
        # One contiguous active segment for the burst.
        self.assertEqual(s["segs"], [
            {"kind": "active", "start": 540, "end": 570},
        ])

    def test_segment_kinds_are_valid(self):
        """Every emitted segment must be one of the 5 design kinds."""
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
            ev(ms_at(9, 31), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 0), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        for p in out["projects"]:
            for s in p["sessions"]:
                for seg in s["segs"]:
                    self.assertIn(seg["kind"],
                                  ("active", "reading", "thinking", "away", "subagent"),
                                  f"unexpected kind: {seg['kind']}")
                    self.assertIsInstance(seg["start"], int)
                    self.assertIsInstance(seg["end"], int)
                    self.assertLessEqual(seg["start"], seg["end"])


class BurstSegmentationTests(unittest.TestCase):
    """Segments must tile each viz-session non-overlapping, sorted by start."""

    def test_two_bursts_with_short_gap(self):
        """A short gap between two bursts → reading segment between them."""
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
            # 60s gap (1 minute) — well under 120s reading threshold
            ev(ms_at(9, 31), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 0), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        p = out["projects"][0]
        # Same viz-session (short gap is reading, doesn't split).
        self.assertEqual(len(p["sessions"]), 1)
        segs = p["sessions"][0]["segs"]
        # Should be: active 9:00-9:30, reading 9:30-9:31, active 9:31-10:00.
        kinds = [s["kind"] for s in segs]
        self.assertEqual(kinds, ["active", "reading", "active"])
        # No overlaps, no gaps.
        for prev, curr in zip(segs, segs[1:]):
            self.assertEqual(prev["end"], curr["start"])

    def test_away_gap_stays_inline_in_one_viz_session(self):
        """An away gap does NOT split a session_id — the gap renders inline
        as an 'away' segment within the single viz-session. Rationale: the
        harness preserves session_id across /resume, so an away gap means
        'I stepped away and came back', not 'new chat'. See viz_data.py
        comment for SURFACE-2026-05-18 (Phase 3 verify-human spot-check)."""
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
            # 90 minute gap → away (> 300s threshold)
            ev(ms_at(11, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(11, 30), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        p = out["projects"][0]
        # ONE viz-session — session_id is preserved across the gap.
        self.assertEqual(len(p["sessions"]), 1)
        s = p["sessions"][0]
        # The viz-session window spans from first UPS to last Stop.
        self.assertEqual(s["start"], 9 * 60)
        self.assertEqual(s["end"], 11 * 60 + 30)
        # An 'away' segment appears inline between the two active bursts.
        kinds = [seg["kind"] for seg in s["segs"]]
        self.assertEqual(kinds, ["active", "away", "active"])
        # Segments tile the window with no overlaps.
        for prev_seg, curr_seg in zip(s["segs"], s["segs"][1:]):
            self.assertEqual(prev_seg["end"], curr_seg["start"])


class SubagentNestingTests(unittest.TestCase):
    def test_subagent_nested_within_active(self):
        """A SubagentStart/Stop pair inside a burst becomes a subagent segment
        that splits the surrounding active time."""
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 10), "sid-1", "SubagentStart", agent_type="Explore"),
            ev(ms_at(9, 20), "sid-1", "SubagentStop", agent_type="Explore"),
            ev(ms_at(9, 30), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        segs = out["projects"][0]["sessions"][0]["segs"]
        kinds = [s["kind"] for s in segs]
        self.assertEqual(kinds, ["active", "subagent", "active"])
        # Subagent segment carries label.
        subagent = next(s for s in segs if s["kind"] == "subagent")
        self.assertEqual(subagent["label"], "Explore")


class AliasResolutionTests(unittest.TestCase):
    def test_explicit_project_names(self):
        """An explicit project_names entry wins over auto-alias."""
        cfg = dict(CFG)
        cfg["project_names"] = {"big-project": ["/repo/proj-a", "/repo/proj-a-worktree"]}
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit",
               cwd="/repo/proj-a", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop", cwd="/repo/proj-a"),
            ev(ms_at(10, 0), "sid-2", "UserPromptSubmit",
               cwd="/repo/proj-a-worktree", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 30), "sid-2", "Stop", cwd="/repo/proj-a-worktree"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, cfg, stub_auto_alias)
        # Two cwds collapse into one alias.
        self.assertEqual(len(out["projects"]), 1)
        self.assertEqual(out["projects"][0]["alias"], "big-project")
        # Both viz-sessions present.
        self.assertEqual(len(out["projects"][0]["sessions"]), 2)

    def test_auto_alias_fallback(self):
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit",
               cwd="/repo/proj-z", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop", cwd="/repo/proj-z"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        # stub_auto_alias returns basename → "proj-z"
        self.assertEqual(out["projects"][0]["alias"], "proj-z")


class HourRangeTests(unittest.TestCase):
    def test_adaptive_window(self):
        events = [
            ev(ms_at(8, 30), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 15), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        # Min event minute = 8:30 → hour 8; pad -1 → start hour 7.
        # Max event minute = 10:15 → hour 10; pad +1 → end hour 12 (rounded up).
        self.assertEqual(out["hour_range"][0], 7)
        self.assertGreaterEqual(out["hour_range"][1], 11)

    def test_fallback_on_empty(self):
        out = viz_data.build_day_data("2026-05-13", [], CFG, stub_auto_alias)
        self.assertEqual(out["hour_range"], [6, 23])

    def test_clamp_to_day(self):
        # Very early event (before 6am).
        events = [
            ev(ms_at(2, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(3, 0), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        self.assertGreaterEqual(out["hour_range"][0], 0)
        self.assertLessEqual(out["hour_range"][1], 24)


class CrossCheckAgainstSessionActiveMsTests(unittest.TestCase):
    """The total active+subagent minutes summed across all viz-segments must
    equal `reclassify.session_active_ms` exactly. Both consume the shared
    `reclassify.active_bursts` helper, so this asserts the single source of
    truth is being used by both consumers.
    """

    def test_simple_two_burst_session(self):
        import reclassify
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 10), "sid-1", "SubagentStart", agent_type="Explore"),
            ev(ms_at(9, 20), "sid-1", "SubagentStop", agent_type="Explore"),
            ev(ms_at(9, 30), "sid-1", "Stop"),
            ev(ms_at(9, 31), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 0), "sid-1", "Stop"),
        ]
        truth_min = sum(reclassify.session_active_ms(events).values()) // 60_000
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        viz_active = sum(
            seg["end"] - seg["start"]
            for p in out["projects"] for s in p["sessions"] for seg in s["segs"]
            if seg["kind"] in ("active", "subagent")
        )
        self.assertEqual(viz_active, truth_min)

    def test_consecutive_ups_narrow_definition(self):
        """Consecutive UPSes overwrite — burst spans from LAST_UPS to Stop;
        earlier UPSes become 'interrupts'."""
        import reclassify
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            # second UPS at 9:05 — overwrites; becomes an interrupt
            ev(ms_at(9, 5), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
        ]
        # Truth: only the 9:05 → 9:30 burst counts = 25 min
        truth_min = sum(reclassify.session_active_ms(events).values()) // 60_000
        self.assertEqual(truth_min, 25)
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        viz_active = sum(
            seg["end"] - seg["start"]
            for p in out["projects"] for s in p["sessions"] for seg in s["segs"]
            if seg["kind"] in ("active", "subagent")
        )
        # Viz matches truth exactly.
        self.assertEqual(viz_active, 25)


class InterruptsFieldTests(unittest.TestCase):
    """The `interrupts` field on each viz-session lists the UPS timestamps
    that were superseded (mid-turn prompts before the burst's Stop). Phase 3
    will render a vertical hairline at each one inside the active bar.
    """

    def test_no_interrupts_when_no_overwrite(self):
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        s = out["projects"][0]["sessions"][0]
        self.assertEqual(s["interrupts"], [])

    def test_single_interrupt(self):
        """One mid-turn UPS → one interrupt at the first UPS's minute."""
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 5), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        s = out["projects"][0]["sessions"][0]
        # The 9:00 UPS was superseded — it's the recorded interrupt.
        self.assertEqual(s["interrupts"], [9 * 60])

    def test_multiple_interrupts(self):
        """Three UPSes before one Stop → two interrupts at the first two."""
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 5), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 10), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        s = out["projects"][0]["sessions"][0]
        self.assertEqual(s["interrupts"], [9 * 60, 9 * 60 + 5])

    def test_interrupts_aggregated_across_bursts_in_viz_session(self):
        """Interrupts from multiple bursts in the same viz-session combine."""
        events = [
            # Burst 1: one interrupt at 9:00, anchor at 9:05, stop at 9:30
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 5), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
            # Burst 2: one interrupt at 9:31, anchor at 9:33, stop at 10:00
            ev(ms_at(9, 31), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 33), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 0), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        # Both bursts share one viz-session (no away gap between them).
        self.assertEqual(len(out["projects"][0]["sessions"]), 1)
        s = out["projects"][0]["sessions"][0]
        # Aggregated interrupts from both bursts.
        self.assertEqual(s["interrupts"], [9 * 60, 9 * 60 + 31])


class WeekRollupTests(unittest.TestCase):
    def test_empty_week(self):
        out = viz_data.build_week_data("2026-05-11", {}, CFG, stub_auto_alias)
        self.assertEqual(len(out["days"]), 7)
        self.assertEqual(out["projects"], [])

    def test_basic_aggregation(self):
        # Two days with one burst each.
        d1_events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", cwd="/repo/proj",
               meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop", cwd="/repo/proj"),
        ]
        # Day 2: shift events to 2026-05-14 by using a different day-start.
        d2_start_ms = int(_dt.datetime.combine(_dt.date(2026, 5, 14), _dt.time.min).timestamp() * 1000)
        d2_events = [
            {**e, "ts": e["ts"] - _DAY_START_MS + d2_start_ms + 60 * 60_000}  # offset 1h
            for e in d1_events
        ]
        # Build week starting 2026-05-11 (Mon). 2026-05-13 = Wed (idx 2), 2026-05-14 = Thu (idx 3).
        events_by_day = {
            "2026-05-13": d1_events,
            "2026-05-14": d2_events,
        }
        out = viz_data.build_week_data("2026-05-11", events_by_day, CFG, stub_auto_alias)
        self.assertEqual(len(out["projects"]), 1)
        rollup = out["projects"][0]["rollup"]
        # Day index 2 (Wed) should have 30 min active.
        self.assertEqual(rollup[2]["active"], 30)
        # Day index 3 (Thu) should have 30 min active.
        self.assertEqual(rollup[3]["active"], 30)
        # Other days should be 0.
        for i in (0, 1, 4, 5, 6):
            self.assertEqual(rollup[i]["active"], 0)


class MatchDataJsContractTests(unittest.TestCase):
    """Phase boundary discipline: assert the emitted shape matches data.js's
    declared shape (key set, type-of-value parity for at least one row per
    top-level field). Per CLAUDE.md 'Plan-level downstream contract impacts'."""

    def test_today_shape_keys_match_data_js(self):
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        # Top-level keys
        self.assertIn("label", out)
        self.assertIn("iso", out)
        self.assertIn("projects", out)
        self.assertIn("hour_range", out)
        # Project shape
        p = out["projects"][0]
        for k in ("id", "alias", "path", "sessions"):
            self.assertIn(k, p)
        # Session shape — original data.js keys + additive `interrupts` field
        # (Phase 2 extension; design renders it as hairlines in Phase 3).
        s = p["sessions"][0]
        for k in ("id", "start", "end", "prompts", "tools", "segs", "interrupts"):
            self.assertIn(k, s)
        # Segment shape
        seg = s["segs"][0]
        for k in ("kind", "start", "end"):
            self.assertIn(k, seg)
        # `tools` is dict — matches data.js shape (tool name → number)
        self.assertIsInstance(s["tools"], dict)
        # `interrupts` is list — additive field for hairline rendering
        self.assertIsInstance(s["interrupts"], list)

    def test_week_shape_keys_match_data_js(self):
        out = viz_data.build_week_data("2026-05-11", {}, CFG, stub_auto_alias)
        for k in ("label", "days", "projects"):
            self.assertIn(k, out)
        self.assertEqual(len(out["days"]), 7)

    def test_emitted_json_is_serializable(self):
        """The whole payload must JSON-serialize cleanly for the HTML inline-script."""
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
        ]
        out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        # Must not raise.
        serialized = json.dumps(out)
        self.assertIn('"projects"', serialized)


class BuildRangeDataTests(unittest.TestCase):
    """WP3: `build_range_data(start_iso, end_iso)` — the new multi-day core
    that day/week wrappers delegate to."""

    def _day_n_ms(self, day, hh, mm):
        """ms for HH:MM on the given date (avoids _DAY_START_MS coupling)."""
        ds = int(_dt.datetime.combine(day, _dt.time.min).timestamp() * 1000)
        return ds + (hh * 60 + mm) * 60_000

    def test_empty_three_day_range_meta_and_per_day_defaults(self):
        out = viz_data.build_range_data(
            "2026-05-11", "2026-05-13",
            events_by_day={"2026-05-11": [], "2026-05-12": [], "2026-05-13": []},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(out["meta"], {"start": "2026-05-11", "end": "2026-05-13", "day_count": 3})
        self.assertEqual(out["projects"], [])
        # Per-day hour_range defaults to [6, 23] on empty days; map has all 3 entries.
        self.assertEqual(set(out["hour_range_by_day"].keys()),
                         {"2026-05-11", "2026-05-12", "2026-05-13"})
        for hr in out["hour_range_by_day"].values():
            self.assertEqual(hr, [6, 23])
        # Global day_window is the union — all empty so [6, 23].
        self.assertEqual(out["day_window"], [6, 23])

    def test_single_day_range_back_compat_shape(self):
        """day_count == 1: range payload surfaces flat `iso` + `hour_range` so
        callers get the day shape from a 1-day range too."""
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 30), "sid-1", "Stop"),
        ]
        range_out = viz_data.build_range_data(
            "2026-05-13", "2026-05-13",
            events_by_day={"2026-05-13": events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        day_out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        # Range payload has back-compat day fields when day_count == 1.
        self.assertEqual(range_out["iso"], "2026-05-13")
        self.assertEqual(range_out["hour_range"], day_out["hour_range"])
        # Range projects are shape-equivalent (modulo the day_iso tag on sessions).
        self.assertEqual(len(range_out["projects"]), len(day_out["projects"]))
        for rp, dp in zip(range_out["projects"], day_out["projects"]):
            self.assertEqual(rp["alias"], dp["alias"])
            self.assertEqual(rp["path"], dp["path"])
            # Sessions match modulo day_iso tag.
            for rs, ds in zip(rp["sessions"], dp["sessions"]):
                rs_clean = {k: v for k, v in rs.items() if k != "day_iso"}
                self.assertEqual(rs_clean, ds)
                self.assertEqual(rs["day_iso"], "2026-05-13")

    def test_seven_day_range_day_window_unions_per_day_ranges(self):
        """7-day range with events on day 0 (early morning) and day 6 (late
        evening) → day_window spans the union of both days' adaptive ranges."""
        d0 = _dt.date(2026, 5, 11)
        d6 = _dt.date(2026, 5, 17)
        d0_events = [
            ev(self._day_n_ms(d0, 6, 30), "sid-d0", "UserPromptSubmit",
               cwd="/repo/proj-a", meta='{"prompt_length_chars": 0}'),
            ev(self._day_n_ms(d0, 7, 0), "sid-d0", "Stop", cwd="/repo/proj-a"),
        ]
        d6_events = [
            ev(self._day_n_ms(d6, 21, 0), "sid-d6", "UserPromptSubmit",
               cwd="/repo/proj-a", meta='{"prompt_length_chars": 0}'),
            ev(self._day_n_ms(d6, 21, 30), "sid-d6", "Stop", cwd="/repo/proj-a"),
        ]
        out = viz_data.build_range_data(
            "2026-05-11", "2026-05-17",
            events_by_day={"2026-05-11": d0_events, "2026-05-17": d6_events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(out["meta"]["day_count"], 7)
        # day 0 hour_range should start around 5-6 (early-morning adaptive padding).
        self.assertLess(out["hour_range_by_day"]["2026-05-11"][0], 8)
        # day 6 hour_range should end at 22+ (late-evening padding).
        self.assertGreaterEqual(out["hour_range_by_day"]["2026-05-17"][1], 22)
        # Global day_window covers the union.
        self.assertEqual(out["day_window"][0],
                         out["hour_range_by_day"]["2026-05-11"][0])
        self.assertEqual(out["day_window"][1],
                         out["hour_range_by_day"]["2026-05-17"][1])

    def test_cross_day_project_aggregation(self):
        """Same alias appearing on multiple days appears once in the cross-day
        projects list, with sessions from both days (each tagged with day_iso)."""
        d1 = _dt.date(2026, 5, 13)
        d3 = _dt.date(2026, 5, 15)
        d1_events = [
            ev(self._day_n_ms(d1, 9, 0), "sid-d1", "UserPromptSubmit",
               cwd="/repo/proj-a", meta='{"prompt_length_chars": 0}'),
            ev(self._day_n_ms(d1, 9, 30), "sid-d1", "Stop", cwd="/repo/proj-a"),
        ]
        d3_events = [
            ev(self._day_n_ms(d3, 14, 0), "sid-d3", "UserPromptSubmit",
               cwd="/repo/proj-a", meta='{"prompt_length_chars": 0}'),
            ev(self._day_n_ms(d3, 14, 30), "sid-d3", "Stop", cwd="/repo/proj-a"),
        ]
        out = viz_data.build_range_data(
            "2026-05-13", "2026-05-15",
            events_by_day={"2026-05-13": d1_events, "2026-05-15": d3_events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        # One project (alias "proj-a"), sessions from both days.
        self.assertEqual(len(out["projects"]), 1)
        proj = out["projects"][0]
        self.assertEqual(proj["alias"], "proj-a")
        self.assertEqual(len(proj["sessions"]), 2)
        day_isos = {s["day_iso"] for s in proj["sessions"]}
        self.assertEqual(day_isos, {"2026-05-13", "2026-05-15"})
        # Sessions sorted by (day_iso, start).
        self.assertEqual(proj["sessions"][0]["day_iso"], "2026-05-13")
        self.assertEqual(proj["sessions"][1]["day_iso"], "2026-05-15")

    def test_meta_has_exact_keys(self):
        out = viz_data.build_range_data(
            "2026-05-01", "2026-05-05",
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(set(out["meta"].keys()), {"start", "end", "day_count"})
        self.assertEqual(out["meta"]["start"], "2026-05-01")
        self.assertEqual(out["meta"]["end"], "2026-05-05")
        self.assertEqual(out["meta"]["day_count"], 5)

    def test_invalid_range_raises(self):
        with self.assertRaises(ValueError):
            viz_data.build_range_data(
                "2026-05-15", "2026-05-13",
                events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
            )


class WrapperPreservationTests(unittest.TestCase):
    """WP3 regression gate: `build_day_data(date, events)` and
    `build_range_data(date, date, {date: events})` must produce equivalent
    day-shape projections (excluding the new range-only `meta` /
    `hour_range_by_day` / `day_window` keys)."""

    def test_day_shape_equivalence(self):
        events = [
            ev(ms_at(9, 0), "sid-1", "UserPromptSubmit", cwd="/repo/proj-a",
               meta='{"prompt_length_chars": 0}'),
            ev(ms_at(9, 5), "sid-1", "PreToolUse", cwd="/repo/proj-a",
               tool_name="Edit", meta='{"tool_use_id":"t1"}'),
            ev(ms_at(9, 6), "sid-1", "PostToolUse", cwd="/repo/proj-a",
               tool_name="Edit", meta='{"tool_use_id":"t1"}'),
            ev(ms_at(9, 30), "sid-1", "Stop", cwd="/repo/proj-a"),
        ]
        day_out = viz_data.build_day_data("2026-05-13", events, CFG, stub_auto_alias)
        range_out = viz_data.build_range_data(
            "2026-05-13", "2026-05-13",
            events_by_day={"2026-05-13": events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        # Day-shape keys must match byte-for-byte between the two.
        self.assertEqual(day_out["iso"], range_out["iso"])
        self.assertEqual(day_out["label"], range_out["label"])
        self.assertEqual(day_out["hour_range"], range_out["hour_range"])
        # Projects/sessions match modulo the day_iso tag added by range.
        self.assertEqual(len(day_out["projects"]), len(range_out["projects"]))
        for dp, rp in zip(day_out["projects"], range_out["projects"]):
            for k in ("id", "alias", "path"):
                self.assertEqual(dp[k], rp[k])
            for ds, rs in zip(dp["sessions"], rp["sessions"]):
                rs_clean = {k: v for k, v in rs.items() if k != "day_iso"}
                self.assertEqual(ds, rs_clean)


if __name__ == "__main__":
    unittest.main()
