"""Unit tests for tools/claude-time/reclassify.py.

Plain unittest (stdlib only). Run via:
  python3 -m unittest tools.claude-time.test.test_reclassify
OR
  cd tools/claude-time/test && python3 -m unittest test_reclassify

Or directly:
  python3 tools/claude-time/test/test_reclassify.py
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

# Make sibling reclassify module importable.
_HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE.parent))
import reclassify  # noqa: E402


def ev(ts, session_id, event, **kw):
    """Construct an event-dict shaped like a sqlite3.Row.dict."""
    row = {
        "ts": ts,
        "session_id": session_id,
        "event": event,
        "cwd": kw.pop("cwd", ""),
        "tool_name": kw.pop("tool_name", None),
        "agent_type": kw.pop("agent_type", None),
        "meta": kw.pop("meta", None),
    }
    assert not kw, f"unexpected kwargs: {kw}"
    return row


class TypingDebitTests(unittest.TestCase):
    def test_normal(self):
        # 60 chars at 6 cps = 10 sec = 10000 ms
        self.assertEqual(reclassify.typing_debit_ms(60, 6.0), 10000)

    def test_zero_length(self):
        self.assertEqual(reclassify.typing_debit_ms(0, 6.0), 0)

    def test_negative_length_safe(self):
        self.assertEqual(reclassify.typing_debit_ms(-5, 6.0), 0)

    def test_zero_cps_safe(self):
        # Defensive — avoid div-by-zero
        self.assertEqual(reclassify.typing_debit_ms(60, 0), 0)

    def test_rounding(self):
        # 7 chars at 6 cps = 7/6 sec = 1166.66... ms → rounds to 1167
        self.assertEqual(reclassify.typing_debit_ms(7, 6.0), 1167)


class GapBucketTests(unittest.TestCase):
    """Edge-of-bucket assertions for the 120s / 300s thresholds."""

    @staticmethod
    def _simple_gap(gap_sec: int, prompt_chars: int = 0) -> reclassify.Gap:
        """Single-session: Stop at t=0, UPS at t=gap_sec*1000."""
        events = [
            ev(0, "s", "Stop"),
            ev(gap_sec * 1000, "s", "UserPromptSubmit",
               meta=f'{{"prompt_length_chars": {prompt_chars}}}'),
        ]
        gaps = reclassify.gap_buckets(events, chars_per_sec=6.0,
                                     reading_threshold_sec=120,
                                     thinking_threshold_sec=300)
        assert len(gaps) == 1, f"expected 1 gap, got {len(gaps)}"
        return gaps[0]

    def test_just_at_reading_threshold(self):
        # 120s gap, 0-length prompt → effective 120000ms → reading (≤ 120s)
        g = self._simple_gap(120)
        self.assertEqual(g.effective_ms, 120_000)
        self.assertEqual(g.bucket, "reading")

    def test_just_over_reading_threshold(self):
        # 121s gap → effective 121000ms → thinking (> 120s, ≤ 300s)
        g = self._simple_gap(121)
        self.assertEqual(g.bucket, "thinking")

    def test_just_at_thinking_threshold(self):
        # 300s gap → effective 300000ms → thinking (≤ 300s)
        g = self._simple_gap(300)
        self.assertEqual(g.bucket, "thinking")

    def test_just_over_thinking_threshold(self):
        # 301s gap → effective 301000ms → away (> 300s)
        g = self._simple_gap(301)
        self.assertEqual(g.bucket, "away")

    def test_typing_debit_clamps_at_zero(self):
        # 1s gap, 600-char prompt (100s of typing) → effective clamps to 0 (reading)
        g = self._simple_gap(1, prompt_chars=600)
        self.assertEqual(g.effective_ms, 0)
        self.assertEqual(g.bucket, "reading")

    def test_typing_debit_subtracts_from_gap(self):
        # 130s gap, 60-char prompt (10s typing) → effective 120s → reading (was thinking)
        g = self._simple_gap(130, prompt_chars=60)
        self.assertEqual(g.effective_ms, 120_000)
        self.assertEqual(g.bucket, "reading")


class CrossSessionOverlapTests(unittest.TestCase):
    def test_other_session_prompt_in_window_counts(self):
        events = [
            ev(0,       "A", "Stop"),
            ev(50_000,  "B", "UserPromptSubmit", meta='{"prompt_length_chars": 60}'),
            ev(120_000, "A", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
        ]
        # A's gap = 120_000ms. B's UPS at 50_000 (within [0, 120_000]).
        # B's typing debit = 60/6 = 10_000ms.
        # Effective = 120_000 - 0 (no typing on A's next) - 10_000 = 110_000ms → reading
        gaps = reclassify.gap_buckets(events, chars_per_sec=6.0)
        self.assertEqual(len(gaps), 1)
        self.assertEqual(gaps[0].cross_session_ms, 10_000)
        self.assertEqual(gaps[0].effective_ms, 110_000)

    def test_same_session_prompt_does_not_count(self):
        events = [
            ev(0,       "A", "Stop"),
            ev(50_000,  "A", "UserPromptSubmit", meta='{"prompt_length_chars": 60}'),
            ev(120_000, "A", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
        ]
        # First Stop pairs with UPS@50000 (next UPS in same session)
        # That gap = 50000, typing_debit = 10000 (60 chars), no other session
        # → effective = 40000 → reading
        gaps = reclassify.gap_buckets(events, chars_per_sec=6.0)
        self.assertEqual(len(gaps), 1)
        self.assertEqual(gaps[0].cross_session_ms, 0)
        self.assertEqual(gaps[0].effective_ms, 40_000)

    def test_prompt_outside_window_does_not_count(self):
        events = [
            ev(0,       "A", "Stop"),
            ev(150_000, "B", "UserPromptSubmit", meta='{"prompt_length_chars": 60}'),
            ev(100_000, "A", "UserPromptSubmit", meta='{"prompt_length_chars": 0}'),
        ]
        # A's gap = [0, 100_000]. B's UPS at 150_000 is OUTSIDE this window.
        gaps = reclassify.gap_buckets(events, chars_per_sec=6.0)
        self.assertEqual(len(gaps), 1)
        self.assertEqual(gaps[0].cross_session_ms, 0)


class ToolDurationsTests(unittest.TestCase):
    def test_paired_pre_and_post(self):
        events = [
            ev(0,    "s", "PreToolUse",  tool_name="Bash", meta='{"tool_use_id":"x"}'),
            ev(1000, "s", "PostToolUse", tool_name="Bash", meta='{"tool_use_id":"x"}'),
        ]
        self.assertEqual(reclassify.tool_durations_ms(events), {"Bash": 1000})

    def test_pre_without_post_skipped(self):
        events = [
            ev(0, "s", "PreToolUse", tool_name="Bash", meta='{"tool_use_id":"x"}'),
        ]
        self.assertEqual(reclassify.tool_durations_ms(events), {})

    def test_failure_post_pairs_too(self):
        events = [
            ev(0,    "s", "PreToolUse",         tool_name="Bash", meta='{"tool_use_id":"x"}'),
            ev(2500, "s", "PostToolUseFailure", tool_name="Bash", meta='{"tool_use_id":"x"}'),
        ]
        self.assertEqual(reclassify.tool_durations_ms(events), {"Bash": 2500})

    def test_multiple_tools_summed_per_name(self):
        events = [
            ev(0,     "s", "PreToolUse",  tool_name="Bash", meta='{"tool_use_id":"x"}'),
            ev(100,   "s", "PostToolUse", tool_name="Bash", meta='{"tool_use_id":"x"}'),
            ev(200,   "s", "PreToolUse",  tool_name="Bash", meta='{"tool_use_id":"y"}'),
            ev(500,   "s", "PostToolUse", tool_name="Bash", meta='{"tool_use_id":"y"}'),
            ev(600,   "s", "PreToolUse",  tool_name="Read", meta='{"tool_use_id":"z"}'),
            ev(700,   "s", "PostToolUse", tool_name="Read", meta='{"tool_use_id":"z"}'),
        ]
        self.assertEqual(
            reclassify.tool_durations_ms(events),
            {"Bash": 400, "Read": 100},
        )


class SubagentDurationsTests(unittest.TestCase):
    def test_paired_start_and_stop(self):
        events = [
            ev(0,    "s", "SubagentStart", agent_type="Explore"),
            ev(5000, "s", "SubagentStop",  agent_type="Explore"),
        ]
        self.assertEqual(
            reclassify.subagent_durations_ms(events),
            {"Explore": 5000},
        )

    def test_unpaired_start_skipped(self):
        events = [ev(0, "s", "SubagentStart", agent_type="Explore")]
        self.assertEqual(reclassify.subagent_durations_ms(events), {})

    def test_multiple_pairs_summed(self):
        events = [
            ev(0,     "s", "SubagentStart", agent_type="Plan"),
            ev(1000,  "s", "SubagentStop",  agent_type="Plan"),
            ev(2000,  "s", "SubagentStart", agent_type="Plan"),
            ev(2500,  "s", "SubagentStop",  agent_type="Plan"),
        ]
        self.assertEqual(
            reclassify.subagent_durations_ms(events),
            {"Plan": 1500},
        )


class SessionActiveTests(unittest.TestCase):
    def test_single_ups_to_stop_window(self):
        events = [
            ev(0,    "s", "UserPromptSubmit"),
            ev(3000, "s", "Stop"),
        ]
        self.assertEqual(reclassify.session_active_ms(events), {"s": 3000})

    def test_multiple_windows_summed(self):
        events = [
            ev(0,     "s", "UserPromptSubmit"),
            ev(1000,  "s", "Stop"),
            ev(5000,  "s", "UserPromptSubmit"),
            ev(8000,  "s", "Stop"),
        ]
        self.assertEqual(reclassify.session_active_ms(events), {"s": 4000})

    def test_stop_without_prior_ups_ignored(self):
        events = [
            ev(0,    "s", "Stop"),  # no prior UPS — orphan Stop
            ev(1000, "s", "UserPromptSubmit"),
            ev(2000, "s", "Stop"),
        ]
        self.assertEqual(reclassify.session_active_ms(events), {"s": 1000})


if __name__ == "__main__":
    unittest.main()
