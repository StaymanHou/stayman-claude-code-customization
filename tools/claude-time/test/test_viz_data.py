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


class BuildComparisonDataTests(unittest.TestCase):
    """WP4: `build_comparison_data(start_a, end_a, start_b, end_b)` —
    coordinator-on-top-of-build_range_data; emits {a, b, deltas, meta}."""

    def _day_n_ms(self, day, hh, mm):
        ds = int(_dt.datetime.combine(day, _dt.time.min).timestamp() * 1000)
        return ds + (hh * 60 + mm) * 60_000

    def _one_burst_events(self, day, hh_start, hh_end, *, sid=None, cwd="/repo/proj-a"):
        """Helper: one UPS at hh_start, one Stop at hh_end on the given day.

        Default session_id derives from the day so A-side and B-side bursts
        don't collide when both windows are passed to comparison helpers."""
        if sid is None:
            sid = f"sid-{day.isoformat()}"
        return [
            ev(self._day_n_ms(day, hh_start, 0), sid, "UserPromptSubmit",
               cwd=cwd, meta='{"prompt_length_chars": 0}'),
            ev(self._day_n_ms(day, hh_end, 0), sid, "Stop", cwd=cwd),
        ]

    def test_empty_both_windows(self):
        out = viz_data.build_comparison_data(
            "2026-05-11", "2026-05-13", "2026-05-18", "2026-05-20",
            events_by_day_a={}, events_by_day_b={},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(out["deltas"], {})
        self.assertEqual(out["meta"]["a_day_count"], 3)
        self.assertEqual(out["meta"]["b_day_count"], 3)
        self.assertEqual(out["a"]["projects"], [])
        self.assertEqual(out["b"]["projects"], [])

    def test_empty_a_only(self):
        """A empty, B has one project with 60min active → abs_min: +60, rel_pct: None."""
        d_b = _dt.date(2026, 5, 20)
        b_events = self._one_burst_events(d_b, 9, 10)  # 60 minutes
        out = viz_data.build_comparison_data(
            "2026-05-13", "2026-05-13", "2026-05-20", "2026-05-20",
            events_by_day_a={},
            events_by_day_b={"2026-05-20": b_events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertIn("proj-a", out["deltas"])
        active_d = out["deltas"]["proj-a"]["active"]
        self.assertEqual(active_d["abs_min"], 60)
        self.assertIsNone(active_d["rel_pct"])  # zero baseline → None
        # total_active_subagent should also be +60 (no subagent here).
        total_d = out["deltas"]["proj-a"]["total_active_subagent"]
        self.assertEqual(total_d["abs_min"], 60)
        self.assertIsNone(total_d["rel_pct"])

    def test_empty_b_only(self):
        """Symmetric inverse — A has 60min active, B empty → abs_min: -60, rel_pct: -100.0."""
        d_a = _dt.date(2026, 5, 13)
        a_events = self._one_burst_events(d_a, 9, 10)
        out = viz_data.build_comparison_data(
            "2026-05-13", "2026-05-13", "2026-05-20", "2026-05-20",
            events_by_day_a={"2026-05-13": a_events},
            events_by_day_b={},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertIn("proj-a", out["deltas"])
        active_d = out["deltas"]["proj-a"]["active"]
        self.assertEqual(active_d["abs_min"], -60)
        self.assertEqual(active_d["rel_pct"], -100.0)

    def test_identical_windows(self):
        """Same events shape in A and B → all deltas zero, rel_pct == 0.0 for non-empty kinds."""
        d_a = _dt.date(2026, 5, 13)
        d_b = _dt.date(2026, 5, 20)
        a_events = self._one_burst_events(d_a, 9, 10)
        b_events = self._one_burst_events(d_b, 9, 10)
        out = viz_data.build_comparison_data(
            "2026-05-13", "2026-05-13", "2026-05-20", "2026-05-20",
            events_by_day_a={"2026-05-13": a_events},
            events_by_day_b={"2026-05-20": b_events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        active_d = out["deltas"]["proj-a"]["active"]
        self.assertEqual(active_d["abs_min"], 0)
        self.assertEqual(active_d["rel_pct"], 0.0)
        total_d = out["deltas"]["proj-a"]["total_active_subagent"]
        self.assertEqual(total_d["abs_min"], 0)
        self.assertEqual(total_d["rel_pct"], 0.0)

    def test_regression_case(self):
        """A has 120min active, B has 60min → abs_min: -60, rel_pct: -50.0."""
        d_a = _dt.date(2026, 5, 13)
        d_b = _dt.date(2026, 5, 20)
        a_events = self._one_burst_events(d_a, 9, 11)   # 120 minutes
        b_events = self._one_burst_events(d_b, 9, 10)   # 60 minutes
        out = viz_data.build_comparison_data(
            "2026-05-13", "2026-05-13", "2026-05-20", "2026-05-20",
            events_by_day_a={"2026-05-13": a_events},
            events_by_day_b={"2026-05-20": b_events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        active_d = out["deltas"]["proj-a"]["active"]
        self.assertEqual(active_d["abs_min"], -60)
        self.assertEqual(active_d["rel_pct"], -50.0)

    def test_meta_shape_exact_keys(self):
        out = viz_data.build_comparison_data(
            "2026-05-11", "2026-05-13", "2026-05-18", "2026-05-20",
            events_by_day_a={}, events_by_day_b={},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(
            set(out["meta"].keys()),
            {"a_start", "a_end", "b_start", "b_end", "a_day_count", "b_day_count"},
        )
        self.assertEqual(out["meta"]["a_start"], "2026-05-11")
        self.assertEqual(out["meta"]["a_end"], "2026-05-13")
        self.assertEqual(out["meta"]["b_start"], "2026-05-18")
        self.assertEqual(out["meta"]["b_end"], "2026-05-20")
        self.assertEqual(out["meta"]["a_day_count"], 3)
        self.assertEqual(out["meta"]["b_day_count"], 3)

    def test_total_active_subagent_synthesised(self):
        """The 6th synthesised `total_active_subagent` key equals active + subagent deltas
        for the same project. Uses a subagent-bearing burst to exercise both kinds."""
        d_a = _dt.date(2026, 5, 13)
        d_b = _dt.date(2026, 5, 20)
        # B-side: 60min burst with a 20min subagent inside (so the burst is
        # split into active+subagent+active by _split_active_with_subagents).
        b_events = [
            ev(self._day_n_ms(d_b, 9, 0), "sid-b", "UserPromptSubmit",
               cwd="/repo/proj-a", meta='{"prompt_length_chars": 0}'),
            ev(self._day_n_ms(d_b, 9, 20), "sid-b", "SubagentStart",
               cwd="/repo/proj-a", agent_type="explorer"),
            ev(self._day_n_ms(d_b, 9, 40), "sid-b", "SubagentStop",
               cwd="/repo/proj-a", agent_type="explorer"),
            ev(self._day_n_ms(d_b, 10, 0), "sid-b", "Stop", cwd="/repo/proj-a"),
        ]
        out = viz_data.build_comparison_data(
            "2026-05-13", "2026-05-13", "2026-05-20", "2026-05-20",
            events_by_day_a={},
            events_by_day_b={"2026-05-20": b_events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        d = out["deltas"]["proj-a"]
        # Verify the invariant directly: total_active_subagent.abs_min == active.abs_min + subagent.abs_min.
        self.assertEqual(
            d["total_active_subagent"]["abs_min"],
            d["active"]["abs_min"] + d["subagent"]["abs_min"],
        )
        # And the actual numbers: B has 40min active (20 before sub + 20 after) and 20min subagent.
        self.assertEqual(d["active"]["abs_min"], 40)
        self.assertEqual(d["subagent"]["abs_min"], 20)
        self.assertEqual(d["total_active_subagent"]["abs_min"], 60)

    def test_compare_week_over_week_window_math(self):
        """Helper produces a 7-day-vs-7-day comparison with correct meta dates."""
        out = viz_data.compare_week_over_week(
            "2026-05-18",  # this Monday
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        # A = 2026-05-11..2026-05-17  (prior 7 days, prev_monday..prev_sunday)
        self.assertEqual(out["meta"]["a_start"], "2026-05-11")
        self.assertEqual(out["meta"]["a_end"], "2026-05-17")
        # B = 2026-05-18..2026-05-24  (this Monday + 6 days)
        self.assertEqual(out["meta"]["b_start"], "2026-05-18")
        self.assertEqual(out["meta"]["b_end"], "2026-05-24")
        self.assertEqual(out["meta"]["a_day_count"], 7)
        self.assertEqual(out["meta"]["b_day_count"], 7)

    def test_compare_day_vs_trailing_window_math(self):
        """Helper: A spans `window_days` days ending the day before `target_day_iso`,
        B is the single target day."""
        out = viz_data.compare_day_vs_trailing_window(
            "2026-05-21",
            window_days=7,
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        # A = 2026-05-14..2026-05-20  (7 days, ending day-before target)
        self.assertEqual(out["meta"]["a_start"], "2026-05-14")
        self.assertEqual(out["meta"]["a_end"], "2026-05-20")
        self.assertEqual(out["meta"]["a_day_count"], 7)
        # B = target only.
        self.assertEqual(out["meta"]["b_start"], "2026-05-21")
        self.assertEqual(out["meta"]["b_end"], "2026-05-21")
        self.assertEqual(out["meta"]["b_day_count"], 1)

    def test_compare_day_vs_trailing_window_invalid_window_raises(self):
        """`window_days < 1` is a defensive guard — raises ValueError so a
        caller passing 0 or a negative doesn't silently flip A and B."""
        with self.assertRaises(ValueError):
            viz_data.compare_day_vs_trailing_window(
                "2026-05-21", window_days=0,
                events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
            )
        with self.assertRaises(ValueError):
            viz_data.compare_day_vs_trailing_window(
                "2026-05-21", window_days=-3,
                events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
            )

    def test_helpers_partition_events_by_day_across_windows(self):
        """Both helpers take a single `events_by_day` and partition it internally
        into A-window events and B-window events. This test verifies that
        partitioning is real — events in window B do not bleed into A and
        vice versa.

        Scenario: same project alias active on one day in A and one day in B,
        with different burst lengths so a misrouted event would visibly skew
        the deltas. compare_week_over_week selects A = 2026-05-11..2026-05-17,
        B = 2026-05-18..2026-05-24. Place 30 min of active in A (on 2026-05-14)
        and 90 min of active in B (on 2026-05-20) for alias "proj-a". Correct
        partition → deltas.active.abs_min == +60. A bleed-through would show
        wrong numbers (e.g. if the B-day events leaked into A's range payload,
        A would have 120 min instead of 30)."""
        d_a = _dt.date(2026, 5, 14)  # inside week 1
        d_b = _dt.date(2026, 5, 20)  # inside week 2
        a_events = self._one_burst_events(d_a, 9, 9)  # 0 min — placeholder; replace below
        # Re-build with explicit durations.
        a_events = [
            ev(self._day_n_ms(d_a, 10, 0), "sid-a", "UserPromptSubmit",
               cwd="/repo/proj-a", meta='{"prompt_length_chars": 0}'),
            ev(self._day_n_ms(d_a, 10, 30), "sid-a", "Stop", cwd="/repo/proj-a"),
        ]  # 30 min active
        b_events = [
            ev(self._day_n_ms(d_b, 14, 0), "sid-b", "UserPromptSubmit",
               cwd="/repo/proj-a", meta='{"prompt_length_chars": 0}'),
            ev(self._day_n_ms(d_b, 15, 30), "sid-b", "Stop", cwd="/repo/proj-a"),
        ]  # 90 min active
        out = viz_data.compare_week_over_week(
            "2026-05-18",  # this Monday → A = prev week, B = this week
            events_by_day={d_a.isoformat(): a_events, d_b.isoformat(): b_events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        # A correctly received only the d_a events (30 min in week-1 window).
        self.assertEqual(len(out["a"]["projects"]), 1)
        self.assertEqual(out["a"]["projects"][0]["alias"], "proj-a")
        # B correctly received only the d_b events (90 min in week-2 window).
        self.assertEqual(len(out["b"]["projects"]), 1)
        self.assertEqual(out["b"]["projects"][0]["alias"], "proj-a")
        # Delta math confirms partition correctness: +60 abs, +200% rel.
        self.assertEqual(out["deltas"]["proj-a"]["active"]["abs_min"], 60)
        self.assertEqual(out["deltas"]["proj-a"]["active"]["rel_pct"], 200.0)


class CompareMonthOverMonthTests(unittest.TestCase):
    """WP11 Phase 1: `compare_month_over_month(this_month_iso)` helper —
    thin wrapper over `build_comparison_data` with calendar-month window
    math. Companion to WP4's `compare_week_over_week` and
    `compare_day_vs_trailing_window`.

    Tests focus on the boundary math (Jan-prev-year wrap, leap year, month
    count parity) and input validation. The deltas computation itself is
    covered by BuildComparisonDataTests; these tests assume that path
    works and pin only the window-selection contract.
    """

    def test_mid_year_basic(self):
        out = viz_data.compare_month_over_month(
            "2026-05",
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(out["meta"]["a_start"], "2026-04-01")
        self.assertEqual(out["meta"]["a_end"], "2026-04-30")
        self.assertEqual(out["meta"]["b_start"], "2026-05-01")
        self.assertEqual(out["meta"]["b_end"], "2026-05-31")
        self.assertEqual(out["meta"]["a_day_count"], 30)
        self.assertEqual(out["meta"]["b_day_count"], 31)

    def test_january_wraps_to_december_previous_year(self):
        """The prev_month math must cross the year boundary correctly."""
        out = viz_data.compare_month_over_month(
            "2026-01",
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(out["meta"]["a_start"], "2025-12-01")
        self.assertEqual(out["meta"]["a_end"], "2025-12-31")
        self.assertEqual(out["meta"]["b_start"], "2026-01-01")
        self.assertEqual(out["meta"]["b_end"], "2026-01-31")

    def test_march_after_february_handles_28_days(self):
        """Non-leap February → 28-day A window, 31-day B window."""
        out = viz_data.compare_month_over_month(
            "2026-03",
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(out["meta"]["a_start"], "2026-02-01")
        self.assertEqual(out["meta"]["a_end"], "2026-02-28")
        self.assertEqual(out["meta"]["a_day_count"], 28)
        self.assertEqual(out["meta"]["b_day_count"], 31)

    def test_march_after_february_leap_year(self):
        """Leap February (2024) → 29-day A window."""
        out = viz_data.compare_month_over_month(
            "2024-03",
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(out["meta"]["a_end"], "2024-02-29")
        self.assertEqual(out["meta"]["a_day_count"], 29)

    def test_invalid_shape_raises(self):
        with self.assertRaises(ValueError):
            viz_data.compare_month_over_month(
                "2026/05",
                events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
            )
        with self.assertRaises(ValueError):
            viz_data.compare_month_over_month(
                "26-05",
                events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
            )
        with self.assertRaises(ValueError):
            viz_data.compare_month_over_month(
                "",
                events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
            )

    def test_invalid_month_number_raises(self):
        with self.assertRaises(ValueError):
            viz_data.compare_month_over_month(
                "2026-13",
                events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
            )
        with self.assertRaises(ValueError):
            viz_data.compare_month_over_month(
                "2026-00",
                events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
            )

    def test_emits_all_four_top_level_keys(self):
        """Sanity pin: every comparison helper returns {a,b,deltas,meta}."""
        out = viz_data.compare_month_over_month(
            "2026-05",
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(sorted(out.keys()), ["a", "b", "deltas", "meta"])


class BuildMetricsTests(unittest.TestCase):
    """WP10 Phase 1: `build_metrics(events, start_dt, end_dt)` aggregator.

    Engaged-session definition (away-gaps excluded) is metrics-layer-only;
    `_build_viz_sessions` is unchanged (verified separately by the existing
    BuildDayDataShapeTests etc. staying green).
    """

    # Reuse the existing 2026-05-13 day reference for single-day fixtures;
    # the metrics aggregator doesn't care about windows being exactly 7 days
    # in unit tests — it just records what's passed.
    _WINDOW_START = _dt.datetime(2026, 5, 7, 0, 0, 0)   # 7 days before _DAY
    _WINDOW_END = _dt.datetime(2026, 5, 13, 23, 59, 59)

    # ---- Merge helper unit tests ----

    def test_merge_intervals_empty(self):
        self.assertEqual(viz_data._merge_intervals([]), [])

    def test_merge_intervals_single(self):
        self.assertEqual(viz_data._merge_intervals([(0, 10)]), [(0, 10)])

    def test_merge_intervals_non_overlapping(self):
        self.assertEqual(viz_data._merge_intervals([(0, 10), (20, 30)]),
                         [(0, 10), (20, 30)])

    def test_merge_intervals_overlapping(self):
        self.assertEqual(viz_data._merge_intervals([(0, 10), (5, 15)]),
                         [(0, 15)])

    def test_merge_intervals_touching_boundary(self):
        # (0,10) and (10,20) touch at 10 — must merge (10 <= 10).
        self.assertEqual(viz_data._merge_intervals([(0, 10), (10, 20)]),
                         [(0, 20)])

    def test_merge_intervals_zero_width_dropped(self):
        self.assertEqual(viz_data._merge_intervals([(5, 5), (10, 20)]),
                         [(10, 20)])

    def test_sum_intervals(self):
        self.assertEqual(viz_data._sum_intervals([]), 0)
        self.assertEqual(viz_data._sum_intervals([(0, 10), (20, 25)]), 15)

    # ---- Empty-events guard ----

    def test_empty_events_with_window(self):
        out = viz_data.build_metrics([], self._WINDOW_START, self._WINDOW_END)
        self.assertEqual(out["window"]["start"], "2026-05-07")
        self.assertEqual(out["window"]["end"], "2026-05-13")
        self.assertEqual(out["window"]["day_count"], 7)
        # All metrics zero, fully-shaped.
        self.assertEqual(out["engaged_session"]["wallclock_ms"], 0)
        self.assertEqual(out["engaged_session"]["session_count"], 0)
        self.assertEqual(out["ai_agent"]["effort_ms"], 0)
        self.assertEqual(out["tool_call"]["top"], [])
        self.assertEqual(out["human"]["multiplier"], 1.0)
        self.assertEqual(len(out["concurrency"]), 4)
        self.assertTrue(out["concurrency"][3]["is_plus"])
        self.assertEqual(out["blocking"]["agent_blocking_human_ms"], 0)

    def test_empty_events_no_window(self):
        # Window may be None for placeholder emits.
        out = viz_data.build_metrics([], None, None)
        self.assertEqual(out["window"], {"start": "", "end": "", "day_count": 0})

    # ---- Single-burst session ----

    def test_single_burst_session(self):
        # One session with one burst from 10:00 to 10:30 → 30min effort+wall.
        events = [
            ev(ms_at(10, 0), "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 30), "s1", "Stop", cwd="/repo/p"),
        ]
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        thirty_min = 30 * 60_000
        self.assertEqual(out["engaged_session"]["wallclock_ms"], thirty_min)
        self.assertEqual(out["engaged_session"]["effort_ms"], thirty_min)
        self.assertEqual(out["engaged_session"]["session_count"], 1)
        self.assertEqual(out["ai_agent"]["wallclock_ms"], thirty_min)
        self.assertEqual(out["ai_agent"]["effort_ms"], thirty_min)
        # Concurrency: all 30min is k=1.
        self.assertEqual(out["concurrency"][0]["wallclock_ms"], thirty_min)
        self.assertEqual(out["concurrency"][1]["wallclock_ms"], 0)

    # ---- Engaged-session: away-gap split ----

    def test_two_burst_session_away_gap_splits_engaged(self):
        # Burst 1: 10:00–10:30. Burst 2: 14:00–14:30. Gap between is 3.5h
        # of pure away (> 5min thinking threshold → "away"), so engaged
        # window splits: [10:00–10:30] + [14:00–14:30] = 60min each axis.
        events = [
            ev(ms_at(10, 0),  "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 30), "s1", "Stop", cwd="/repo/p"),
            ev(ms_at(14, 0),  "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(14, 30), "s1", "Stop", cwd="/repo/p"),
        ]
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        self.assertEqual(out["engaged_session"]["wallclock_ms"], 60 * 60_000)
        self.assertEqual(out["engaged_session"]["effort_ms"], 60 * 60_000)
        # Importantly: engaged != session-wall-clock-from-10:00-to-14:30,
        # which would be 4.5h. The away-gap exclusion is the load-bearing
        # behavior.
        self.assertNotEqual(out["engaged_session"]["wallclock_ms"], int(4.5 * 60 * 60_000))

    def test_two_burst_session_reading_gap_keeps_engaged_joined(self):
        # Burst 1: 10:00–10:30. Burst 2: 10:31:30–10:35. Gap = 1.5min →
        # below 2min reading_threshold → "reading", NOT away → engaged
        # window stays joined [10:00–10:35] = 5min wall (merged via
        # joined-interval) but effort = 30min + 3.5min = 33.5min.
        events = [
            ev(ms_at(10, 0),  "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 30), "s1", "Stop", cwd="/repo/p"),
            ev(ms_at(10, 0) + 31 * 60_000 + 30_000, "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 0) + 35 * 60_000, "s1", "Stop", cwd="/repo/p"),
        ]
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        # Engaged = [10:00 → 10:35] = 35min via the joined-interval path.
        self.assertEqual(out["engaged_session"]["wallclock_ms"], 35 * 60_000)

    # ---- Concurrency ----

    def test_two_concurrent_sessions(self):
        # s1: 10:00–11:00; s2: 10:30–11:30. Overlap [10:30–11:00] = 30min.
        # Concurrency sweep: k=1 for [10:00–10:30] + [11:00–11:30] = 60min;
        # k=2 for [10:30–11:00] = 30min.
        events = [
            ev(ms_at(10, 0),  "s1", "UserPromptSubmit",
               cwd="/repo/p1", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(11, 0),  "s1", "Stop", cwd="/repo/p1"),
            ev(ms_at(10, 30), "s2", "UserPromptSubmit",
               cwd="/repo/p2", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(11, 30), "s2", "Stop", cwd="/repo/p2"),
        ]
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        self.assertEqual(out["concurrency"][0]["wallclock_ms"], 60 * 60_000)
        self.assertEqual(out["concurrency"][1]["wallclock_ms"], 30 * 60_000)
        # Effort column = wallclock * k.
        self.assertEqual(out["concurrency"][1]["effort_ms"], 60 * 60_000)

    # ---- Tool intervals & top-5 ----

    def test_tool_calls_top_5_ordering(self):
        # 6 distinct tools with effort-time 100, 200, 300, 400, 500, 600 ms.
        # Top 5 should be 600, 500, 400, 300, 200 (descending by effort).
        events = []
        # need a burst window to host the tool calls (no burst → no AI agent
        # entry, but tools still register independently from PreToolUse)
        for i, ms in enumerate([100, 200, 300, 400, 500, 600]):
            events.append(ev(1000 + i * 10_000, f"s{i}", "PreToolUse",
                             tool_name=f"Tool{i}",
                             meta=f'{{"tool_use_id":"t{i}"}}'))
            events.append(ev(1000 + i * 10_000 + ms, f"s{i}", "PostToolUse",
                             tool_name=f"Tool{i}",
                             meta=f'{{"tool_use_id":"t{i}"}}'))
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        top = out["tool_call"]["top"]
        self.assertEqual(len(top), 5)
        effs = [t["effort_ms"] for t in top]
        self.assertEqual(effs, [600, 500, 400, 300, 200])
        # The 100ms tool (Tool0) is dropped.
        names = [t["name"] for t in top]
        self.assertNotIn("Tool0", names)

    def test_tool_call_wallclock_vs_effort_with_overlap(self):
        # Two overlapping tool calls (same session, but tool_intervals is
        # cross-session anyway): [0, 1000] and [500, 1500].
        # Effort-time = 1000 + 1000 = 2000; wall-clock (merged) = 1500.
        events = [
            ev(0,    "s1", "PreToolUse",  tool_name="Bash",
               meta='{"tool_use_id":"a"}'),
            ev(1000, "s1", "PostToolUse", tool_name="Bash",
               meta='{"tool_use_id":"a"}'),
            ev(500,  "s2", "PreToolUse",  tool_name="Bash",
               meta='{"tool_use_id":"b"}'),
            ev(1500, "s2", "PostToolUse", tool_name="Bash",
               meta='{"tool_use_id":"b"}'),
        ]
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        self.assertEqual(out["tool_call"]["effort_ms"], 2000)
        self.assertEqual(out["tool_call"]["wallclock_ms"], 1500)
        # Multiplier = 2000/1500 ≈ 1.333.
        self.assertAlmostEqual(out["tool_call"]["multiplier"], 2000 / 1500, places=4)

    # ---- Subagent reconciliation ----

    def test_subagent_subset_of_ai_agent(self):
        # Burst 10:00–11:00 with a subagent nested 10:15–10:45 inside it.
        events = [
            ev(ms_at(10, 0),  "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 15), "s1", "SubagentStart", agent_type="Explore"),
            ev(ms_at(10, 45), "s1", "SubagentStop",  agent_type="Explore"),
            ev(ms_at(11, 0),  "s1", "Stop", cwd="/repo/p"),
        ]
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        self.assertLessEqual(out["ai_agent"]["subagent"]["wallclock_ms"],
                             out["ai_agent"]["wallclock_ms"])
        self.assertLessEqual(out["ai_agent"]["subagent"]["effort_ms"],
                             out["ai_agent"]["effort_ms"])
        self.assertEqual(out["ai_agent"]["subagent"]["wallclock_ms"], 30 * 60_000)

    # ---- Human activity ----

    def test_human_typing_reading_thinking(self):
        # Single session with three gaps:
        # - 1.5min gap, 0 chars → reading (≤ 2min)
        # - 4min gap, 0 chars → thinking (between 2 and 5min)
        # - typing_debit accumulates: 60 chars at 6cps = 10 sec on each UPS
        events = [
            ev(ms_at(10, 0),  "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 5),  "s1", "Stop", cwd="/repo/p"),
            # Gap1: Stop@10:05 → UPS@10:06:30 = 1.5min → reading
            ev(ms_at(10, 0) + 6 * 60_000 + 30_000, "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 60}'),
            ev(ms_at(10, 0) + 10 * 60_000, "s1", "Stop", cwd="/repo/p"),
            # Gap2: Stop@10:10 → UPS@10:14 = 4min → thinking
            ev(ms_at(10, 0) + 14 * 60_000, "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 60}'),
            ev(ms_at(10, 0) + 20 * 60_000, "s1", "Stop", cwd="/repo/p"),
        ]
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        # reading: 1.5min - 10s typing (60chars/6cps = 10s) = 80s = 80000ms
        # thinking: 4min - 10s typing = 230s = 230000ms
        self.assertEqual(out["human"]["typing_ms"], 20_000)  # 2 × 10s
        self.assertEqual(out["human"]["reading_ms"], 80_000)
        self.assertEqual(out["human"]["thinking_ms"], 230_000)
        self.assertEqual(out["human"]["wallclock_ms"], 20_000 + 80_000 + 230_000)
        self.assertEqual(out["human"]["effort_ms"], out["human"]["wallclock_ms"])
        self.assertEqual(out["human"]["multiplier"], 1.0)

    # ---- Blocking metrics ----

    def test_blocking_metric_reconciliation(self):
        # human_blocking_agent = reading + thinking (NOT typing).
        # agent_blocking_human = ai_agent.wallclock_ms (merged bursts).
        events = [
            ev(ms_at(10, 0),  "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 30), "s1", "Stop", cwd="/repo/p"),
            # 4-minute thinking gap.
            ev(ms_at(10, 0) + 34 * 60_000, "s1", "UserPromptSubmit",
               cwd="/repo/p", meta='{"prompt_length_chars": 0}'),
            ev(ms_at(10, 0) + 40 * 60_000, "s1", "Stop", cwd="/repo/p"),
        ]
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        # human_blocking_agent = reading_ms + thinking_ms (no typing here).
        self.assertEqual(out["blocking"]["human_blocking_agent_ms"],
                         out["human"]["reading_ms"] + out["human"]["thinking_ms"])
        self.assertEqual(out["blocking"]["agent_blocking_human_ms"],
                         out["ai_agent"]["wallclock_ms"])


class BuildMetricsReconciliationTests(unittest.TestCase):
    """WP10 Phase 1: invariants that must hold over any input.

    Each test asserts a specific reconciliation property over a seeded
    multi-day, multi-session fixture. Failing any of these means the
    aggregator's accounting is broken.
    """

    _WINDOW_START = _dt.datetime(2026, 5, 7, 0, 0, 0)
    _WINDOW_END = _dt.datetime(2026, 5, 13, 23, 59, 59)

    @staticmethod
    def _fixture_seven_days_multi_session():
        """A 7-day multi-session fixture exercising concurrency, tools,
        subagents, and gaps. Used by every reconciliation assertion."""
        events = []
        # s1, day 0: 10:00–11:00, then 14:00–14:30 (away gap between).
        events += [
            ev(ms_at(10, 0), "sA", "UserPromptSubmit",
               cwd="/repo/p1", meta='{"prompt_length_chars": 30}'),
            ev(ms_at(11, 0), "sA", "Stop", cwd="/repo/p1"),
            ev(ms_at(14, 0), "sA", "UserPromptSubmit",
               cwd="/repo/p1", meta='{"prompt_length_chars": 30}'),
            ev(ms_at(14, 30), "sA", "Stop", cwd="/repo/p1"),
        ]
        # s2 overlaps s1's first burst (concurrency=2 for 10:30–11:00).
        events += [
            ev(ms_at(10, 30), "sB", "UserPromptSubmit",
               cwd="/repo/p2", meta='{"prompt_length_chars": 30}'),
            ev(ms_at(11, 30), "sB", "Stop", cwd="/repo/p2"),
        ]
        # Tool calls inside s1's first burst: 10:05–10:10 (Bash), 10:40–10:50 (Read).
        events += [
            ev(ms_at(10, 5),  "sA", "PreToolUse",  tool_name="Bash",
               meta='{"tool_use_id":"t1"}'),
            ev(ms_at(10, 10), "sA", "PostToolUse", tool_name="Bash",
               meta='{"tool_use_id":"t1"}'),
            ev(ms_at(10, 40), "sA", "PreToolUse",  tool_name="Read",
               meta='{"tool_use_id":"t2"}'),
            ev(ms_at(10, 50), "sA", "PostToolUse", tool_name="Read",
               meta='{"tool_use_id":"t2"}'),
        ]
        # Subagent inside s1's first burst: 10:20–10:35.
        events += [
            ev(ms_at(10, 20), "sA", "SubagentStart", agent_type="Explore"),
            ev(ms_at(10, 35), "sA", "SubagentStop",  agent_type="Explore"),
        ]
        events.sort(key=lambda r: r["ts"])
        return events

    def test_concurrency_wallclock_sum_equals_engaged_wallclock(self):
        events = self._fixture_seven_days_multi_session()
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        concurrency_sum = sum(c["wallclock_ms"] for c in out["concurrency"])
        self.assertEqual(concurrency_sum, out["engaged_session"]["wallclock_ms"])

    def test_subagent_subset_of_ai_agent_both_axes(self):
        events = self._fixture_seven_days_multi_session()
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        self.assertLessEqual(out["ai_agent"]["subagent"]["wallclock_ms"],
                             out["ai_agent"]["wallclock_ms"])
        self.assertLessEqual(out["ai_agent"]["subagent"]["effort_ms"],
                             out["ai_agent"]["effort_ms"])

    def test_human_multiplier_always_one(self):
        events = self._fixture_seven_days_multi_session()
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        self.assertEqual(out["human"]["multiplier"], 1.0)

    def test_concurrency_effort_equals_wallclock_times_k(self):
        events = self._fixture_seven_days_multi_session()
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        for i, row in enumerate(out["concurrency"]):
            expected_k = i + 1
            self.assertEqual(row["effort_ms"], row["wallclock_ms"] * expected_k,
                             f"concurrency[k={expected_k}] effort != wallclock × k")

    def test_blocking_agent_equals_ai_agent_wallclock(self):
        events = self._fixture_seven_days_multi_session()
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        self.assertEqual(out["blocking"]["agent_blocking_human_ms"],
                         out["ai_agent"]["wallclock_ms"])

    def test_top_tools_capped_at_5(self):
        events = self._fixture_seven_days_multi_session()
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        self.assertLessEqual(len(out["tool_call"]["top"]), 5)

    def test_multipliers_in_valid_range(self):
        events = self._fixture_seven_days_multi_session()
        out = viz_data.build_metrics(events, self._WINDOW_START, self._WINDOW_END)
        # All three metrics that have multiplier: >= 0; and equal to
        # effort/wallclock when wallclock > 0.
        for path in (out["engaged_session"], out["ai_agent"], out["tool_call"]):
            mult = path["multiplier"]
            self.assertGreaterEqual(mult, 0.0)
            if path["wallclock_ms"] > 0:
                self.assertAlmostEqual(mult,
                                       path["effort_ms"] / path["wallclock_ms"],
                                       places=4)


class BuildWindowDataTests(unittest.TestCase):
    """v3 WP1: `build_window_data(start_iso, end_iso)` — top-level coordinator
    that pre-renders day/week/month/compare sub-payloads + window-level metrics
    for the single-emit dashboard model."""

    def _day_n_ms(self, day, hh, mm):
        ds = int(_dt.datetime.combine(day, _dt.time.min).timestamp() * 1000)
        return ds + (hh * 60 + mm) * 60_000

    def _one_burst_events(self, day, hh_start, hh_end, *, sid=None, cwd="/repo/proj-a"):
        if sid is None:
            sid = f"sid-{day.isoformat()}"
        return [
            ev(self._day_n_ms(day, hh_start, 0), sid, "UserPromptSubmit",
               cwd=cwd, meta='{"prompt_length_chars": 0}'),
            ev(self._day_n_ms(day, hh_end, 0), sid, "Stop", cwd=cwd),
        ]

    def test_empty_window_three_day_shape(self):
        """Empty events_by_day, 3-day window → all sub-payload maps populated
        with the right key sets; metrics emits the empty-window shape."""
        out = viz_data.build_window_data(
            "2026-05-26", "2026-05-28",
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(set(out.keys()), {
            "window", "day_payloads_by_iso", "week_payloads_by_monday",
            "month_payloads_by_iso", "compare_payloads_by_preset", "metrics",
        })
        self.assertEqual(out["window"],
                         {"start": "2026-05-26", "end": "2026-05-28", "day_count": 3})
        self.assertEqual(set(out["day_payloads_by_iso"].keys()),
                         {"2026-05-26", "2026-05-27", "2026-05-28"})
        # 2026-05-26 is a Tuesday; the containing Monday is 2026-05-25.
        # Window ends 2026-05-28 (still in the same ISO week). One Monday.
        self.assertEqual(set(out["week_payloads_by_monday"].keys()),
                         {"2026-05-25"})
        self.assertEqual(set(out["month_payloads_by_iso"].keys()), {"2026-05"})
        self.assertEqual(set(out["compare_payloads_by_preset"].keys()),
                         {"wow", "today-vs-trailing", "mom"})
        # Empty-window metrics: engaged_session.wallclock_ms is 0.
        self.assertEqual(out["metrics"]["engaged_session"]["wallclock_ms"], 0)

    def test_single_day_window_shape(self):
        """start == end → exactly one entry in day/week/month maps."""
        d = _dt.date(2026, 5, 26)  # Tuesday; containing Monday is 2026-05-25
        events = self._one_burst_events(d, 9, 10)  # 60 minutes active
        out = viz_data.build_window_data(
            "2026-05-26", "2026-05-26",
            events_by_day={"2026-05-26": events},
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(out["window"]["day_count"], 1)
        self.assertEqual(set(out["day_payloads_by_iso"].keys()), {"2026-05-26"})
        self.assertEqual(set(out["week_payloads_by_monday"].keys()), {"2026-05-25"})
        self.assertEqual(set(out["month_payloads_by_iso"].keys()), {"2026-05"})

    def test_compare_preset_anchors_on_window_end(self):
        """end_iso is the anchor for compare presets, NOT real-world today.
        A window ending on a historical date pins WoW b_start to that day's
        containing Monday — proves the pre-rendered payload is reproducible
        regardless of when emitted."""
        # Pick a historical window ending on Wed 2026-05-13.
        # Containing Monday: 2026-05-11. Containing month: 2026-05.
        out = viz_data.build_window_data(
            "2026-05-07", "2026-05-13",
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        # WoW: B = [this_monday, this_monday + 6 days] = [2026-05-11, 2026-05-17]
        self.assertEqual(out["compare_payloads_by_preset"]["wow"]["meta"]["b_start"],
                         "2026-05-11")
        # today-vs-trailing: B = [end_iso, end_iso]
        self.assertEqual(
            out["compare_payloads_by_preset"]["today-vs-trailing"]["meta"]["b_start"],
            "2026-05-13",
        )
        self.assertEqual(
            out["compare_payloads_by_preset"]["today-vs-trailing"]["meta"]["b_end"],
            "2026-05-13",
        )
        # MoM: B = [first_of_month, last_of_month] for end_iso's month
        self.assertEqual(out["compare_payloads_by_preset"]["mom"]["meta"]["b_start"],
                         "2026-05-01")
        self.assertEqual(out["compare_payloads_by_preset"]["mom"]["meta"]["b_end"],
                         "2026-05-31")

    def test_metrics_cross_check_against_direct_call(self):
        """Top-level metrics should equal what build_metrics returns when
        called directly with the same flattened+sorted event list and the
        same window dts. Pins: no double-counting, no partitioning bug."""
        d = _dt.date(2026, 5, 26)
        events = self._one_burst_events(d, 9, 10)  # 60-min active burst
        events_by_day = {"2026-05-26": events}
        out = viz_data.build_window_data(
            "2026-05-26", "2026-05-26",
            events_by_day=events_by_day,
            cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        # Direct call: flatten + sort the same way build_window_data does.
        all_events = sorted(
            (e for day_events in events_by_day.values() for e in day_events),
            key=lambda e: e["ts"],
        )
        start = _dt.date.fromisoformat("2026-05-26")
        end = _dt.date.fromisoformat("2026-05-26")
        window_start_dt = _dt.datetime.combine(start, _dt.time.min)
        window_end_dt = _dt.datetime.combine(end, _dt.time.max)
        direct = viz_data.build_metrics(all_events, window_start_dt, window_end_dt)
        # Engaged-session wallclock is the most sensitive cross-check field.
        self.assertGreater(out["metrics"]["engaged_session"]["wallclock_ms"], 0)
        self.assertEqual(out["metrics"]["engaged_session"]["wallclock_ms"],
                         direct["engaged_session"]["wallclock_ms"])
        # AI-agent + tool_call should also match.
        self.assertEqual(out["metrics"]["ai_agent"]["wallclock_ms"],
                         direct["ai_agent"]["wallclock_ms"])
        self.assertEqual(out["metrics"]["tool_call"]["wallclock_ms"],
                         direct["tool_call"]["wallclock_ms"])

    def test_end_before_start_raises(self):
        """Mirrors build_range_data's contract: end < start → ValueError."""
        with self.assertRaises(ValueError):
            viz_data.build_window_data(
                "2026-05-28", "2026-05-26",
                events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
            )

    def test_90_day_window_smoke(self):
        """Empty 90-day window from a fixed start → 90 days, 13 or 14 Mondays
        depending on alignment, 3 or 4 calendar months. No perf assertion."""
        # 2026-03-01 (Sunday) + 89 days = 2026-05-29 (Friday).
        # Months touched: 2026-03, 2026-04, 2026-05 → 3 months.
        # First Monday on or before 2026-03-01: 2026-02-23. Then 2026-03-02,
        # 03-09, ..., walking in 7-day steps while monday <= 2026-05-29.
        out = viz_data.build_window_data(
            "2026-03-01", "2026-05-29",
            events_by_day={}, cfg=CFG, auto_alias_fn=stub_auto_alias,
        )
        self.assertEqual(out["window"]["day_count"], 90)
        self.assertEqual(len(out["day_payloads_by_iso"]), 90)
        # 14 Mondays in this 90-day span (2026-02-23 through 2026-05-25).
        self.assertEqual(len(out["week_payloads_by_monday"]), 14)
        self.assertEqual(set(out["month_payloads_by_iso"].keys()),
                         {"2026-03", "2026-04", "2026-05"})


if __name__ == "__main__":
    unittest.main()
