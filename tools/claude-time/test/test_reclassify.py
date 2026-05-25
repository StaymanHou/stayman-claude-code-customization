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


class ToolIntervalsTests(unittest.TestCase):
    def test_empty_events(self):
        self.assertEqual(reclassify.tool_intervals([]), {})

    def test_single_pair(self):
        events = [
            ev(0,    "s", "PreToolUse",  tool_name="Bash", meta='{"tool_use_id":"x"}'),
            ev(1000, "s", "PostToolUse", tool_name="Bash", meta='{"tool_use_id":"x"}'),
        ]
        self.assertEqual(reclassify.tool_intervals(events), {"Bash": [(0, 1000)]})

    def test_unpaired_pre_skipped(self):
        events = [
            ev(0, "s", "PreToolUse", tool_name="Bash", meta='{"tool_use_id":"x"}'),
        ]
        self.assertEqual(reclassify.tool_intervals(events), {})

    def test_failure_post_pairs(self):
        events = [
            ev(0,    "s", "PreToolUse",         tool_name="Bash", meta='{"tool_use_id":"x"}'),
            ev(2500, "s", "PostToolUseFailure", tool_name="Bash", meta='{"tool_use_id":"x"}'),
        ]
        self.assertEqual(reclassify.tool_intervals(events), {"Bash": [(0, 2500)]})

    def test_overlapping_pairs_across_sessions(self):
        # Two concurrent Bash tool calls in different sessions overlap in time.
        # Both pairs must appear in the per-tool list (no implicit merging).
        events = [
            ev(0,    "A", "PreToolUse",  tool_name="Bash", meta='{"tool_use_id":"a"}'),
            ev(500,  "B", "PreToolUse",  tool_name="Bash", meta='{"tool_use_id":"b"}'),
            ev(1000, "A", "PostToolUse", tool_name="Bash", meta='{"tool_use_id":"a"}'),
            ev(1500, "B", "PostToolUse", tool_name="Bash", meta='{"tool_use_id":"b"}'),
        ]
        result = reclassify.tool_intervals(events)
        self.assertEqual(set(result.keys()), {"Bash"})
        # Order follows the order of PreToolUse occurrences in the input.
        self.assertEqual(result["Bash"], [(0, 1000), (500, 1500)])

    def test_reverse_zero_pair_skipped(self):
        # Post before Pre (clock skew or corrupt data) → end <= start → skipped.
        events = [
            ev(1000, "s", "PreToolUse",  tool_name="Bash", meta='{"tool_use_id":"x"}'),
            ev(500,  "s", "PostToolUse", tool_name="Bash", meta='{"tool_use_id":"x"}'),
        ]
        self.assertEqual(reclassify.tool_intervals(events), {})

    def test_missing_tool_use_id_skipped(self):
        events = [
            ev(0,    "s", "PreToolUse",  tool_name="Bash"),  # no meta → no tool_use_id
            ev(1000, "s", "PostToolUse", tool_name="Bash"),
        ]
        self.assertEqual(reclassify.tool_intervals(events), {})


class SubagentIntervalsTests(unittest.TestCase):
    def test_empty_events(self):
        self.assertEqual(reclassify.subagent_intervals([]), [])

    def test_single_pair(self):
        events = [
            ev(0,    "s", "SubagentStart", agent_type="Explore"),
            ev(5000, "s", "SubagentStop",  agent_type="Explore"),
        ]
        self.assertEqual(reclassify.subagent_intervals(events), [(0, 5000)])

    def test_unpaired_start_skipped(self):
        events = [ev(0, "s", "SubagentStart", agent_type="Explore")]
        self.assertEqual(reclassify.subagent_intervals(events), [])

    def test_multiple_pairs_concatenated(self):
        events = [
            ev(0,    "s", "SubagentStart", agent_type="Plan"),
            ev(1000, "s", "SubagentStop",  agent_type="Plan"),
            ev(2000, "s", "SubagentStart", agent_type="Plan"),
            ev(2500, "s", "SubagentStop",  agent_type="Plan"),
        ]
        # FIFO chronological pairing within session+agent_type.
        self.assertEqual(reclassify.subagent_intervals(events),
                         [(0, 1000), (2000, 2500)])

    def test_distinct_agent_types_paired_independently(self):
        events = [
            ev(0,    "s", "SubagentStart", agent_type="Plan"),
            ev(100,  "s", "SubagentStart", agent_type="Explore"),
            ev(500,  "s", "SubagentStop",  agent_type="Explore"),
            ev(1000, "s", "SubagentStop",  agent_type="Plan"),
        ]
        # Two pairs: Plan (0→1000) and Explore (100→500). Order follows the
        # event scan; per-agent-type pairings emit on their respective Stops.
        result = reclassify.subagent_intervals(events)
        self.assertEqual(sorted(result), [(0, 1000), (100, 500)])

    def test_zero_duration_pair_skipped(self):
        events = [
            ev(1000, "s", "SubagentStart", agent_type="Plan"),
            ev(1000, "s", "SubagentStop",  agent_type="Plan"),
        ]
        self.assertEqual(reclassify.subagent_intervals(events), [])


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


class ActiveBurstsTests(unittest.TestCase):
    """Direct tests for the `active_bursts` helper extracted as the shared
    burst-pairing source of truth (used by both `session_active_ms` and the
    dashboard's viz_data module).
    """

    def test_single_burst(self):
        events = [
            ev(1000, "s", "UserPromptSubmit"),
            ev(5000, "s", "Stop"),
        ]
        out = reclassify.active_bursts(events)
        self.assertEqual(out, {"s": [{"start_ts": 1000, "end_ts": 5000, "interrupts": []}]})

    def test_consecutive_ups_records_interrupt(self):
        """A UPS that arrives while a burst is open is recorded as an
        `interrupt` on that burst; the burst's anchor advances to the new
        UPS (narrow definition)."""
        events = [
            ev(1000, "s", "UserPromptSubmit"),
            ev(2000, "s", "UserPromptSubmit"),  # overwrites — interrupt
            ev(5000, "s", "Stop"),
        ]
        out = reclassify.active_bursts(events)
        self.assertEqual(out, {
            "s": [{"start_ts": 2000, "end_ts": 5000, "interrupts": [1000]}]
        })

    def test_three_consecutive_ups_two_interrupts(self):
        events = [
            ev(1000, "s", "UserPromptSubmit"),
            ev(2000, "s", "UserPromptSubmit"),
            ev(3000, "s", "UserPromptSubmit"),
            ev(5000, "s", "Stop"),
        ]
        out = reclassify.active_bursts(events)
        self.assertEqual(out["s"], [
            {"start_ts": 3000, "end_ts": 5000, "interrupts": [1000, 2000]},
        ])

    def test_multiple_bursts_interrupts_reset_per_burst(self):
        """The interrupts list resets between bursts — interrupts from burst N
        don't leak into burst N+1."""
        events = [
            ev(1000, "s", "UserPromptSubmit"),
            ev(2000, "s", "UserPromptSubmit"),  # interrupt for burst 1
            ev(5000, "s", "Stop"),
            ev(6000, "s", "UserPromptSubmit"),
            ev(9000, "s", "Stop"),
        ]
        out = reclassify.active_bursts(events)
        self.assertEqual(out["s"], [
            {"start_ts": 2000, "end_ts": 5000, "interrupts": [1000]},
            {"start_ts": 6000, "end_ts": 9000, "interrupts": []},
        ])

    def test_session_active_ms_consumes_active_bursts(self):
        """Regression guard: session_active_ms must remain consistent with
        what active_bursts returns. Sum of (end-start) per burst should equal
        session_active_ms exactly.
        """
        events = [
            ev(1000, "s", "UserPromptSubmit"),
            ev(2000, "s", "UserPromptSubmit"),
            ev(5000, "s", "Stop"),
            ev(6000, "s", "UserPromptSubmit"),
            ev(9000, "s", "Stop"),
        ]
        bursts = reclassify.active_bursts(events)["s"]
        burst_sum = sum(b["end_ts"] - b["start_ts"] for b in bursts)
        self.assertEqual(reclassify.session_active_ms(events)["s"], burst_sum)


if __name__ == "__main__":
    unittest.main()
