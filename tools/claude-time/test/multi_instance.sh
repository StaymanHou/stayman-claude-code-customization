#!/usr/bin/env bash
# Multi-instance cross-session reattribution scenario.
#
# Spec acceptance #7: when two Claude Code sessions run side-by-side and
# session B has user activity during session A's idle gap, A's gap should
# be reattributed (reduced by B's typing-debit equivalent) before bucketing.
#
# Pure-function unit tests cover the math (test_reclassify.py); this script
# validates the end-to-end real-process scenario:
#   - Two parallel subshells write to the same DB through the deployed hook
#   - WAL mode handles concurrent writes
#   - The reclassifier reads the merged event stream and applies reattribution
#
# Exits 0 if the observed cross-session subtraction matches expected within tolerance.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOOK="$HOME/.claude/hooks/claude-time-hook.pl"
[ -f "$HOOK" ] || HOOK="$REPO_ROOT/tools/claude-time/hook.pl"

TMPDIR="$(mktemp -d -t claude-time-multi-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

export CLAUDE_TIME_DIR="$TMPDIR" CLAUDE_TIME_TRACKING=1

echo "claude-time multi-instance scenario"
echo "  HOOK: $HOOK"
echo "  CLAUDE_TIME_DIR: $TMPDIR"
echo

# Scenario:
#   Session A: UserPromptSubmit at t=0, Stop at t=0.5s, UserPromptSubmit at t=2s
#     → gap of ~1.5s in A
#   Session B: UserPromptSubmit at t=0.8s, with a 600-char prompt
#     → falls within A's gap
#     → at default 6 cps, B's typing-debit = 100s
#
# Reclassifier should:
#   - See A's gap of ~1500ms
#   - Subtract 100000ms of cross-session debit
#   - Result: effective = max(0, 1500 - 0 - 100000) = 0ms → bucket "reading"
#
# The load-bearing assertion: cross_session_ms > 0. Without reattribution
# the value would be 0; with reattribution it should be 100000 (or close).

# Subshell A
(
    echo '{"hook_event_name":"UserPromptSubmit","session_id":"A","cwd":"/proj","prompt":"hi"}' | "$HOOK"
    sleep 0.5
    echo '{"hook_event_name":"Stop","session_id":"A","cwd":"/proj"}' | "$HOOK"
    sleep 1.5  # A is idle here; B will fire mid-gap
    echo '{"hook_event_name":"UserPromptSubmit","session_id":"A","cwd":"/proj","prompt":"hello again"}' | "$HOOK"
) &
PID_A=$!

# Subshell B fires during A's gap, with a 600-char prompt (100s of typing-debit equivalent).
LONG_PROMPT=$(perl -e 'print "X" x 600')
(
    sleep 0.8  # land inside A's idle window [t=0.5, t=2.0]
    echo "{\"hook_event_name\":\"UserPromptSubmit\",\"session_id\":\"B\",\"cwd\":\"/proj\",\"prompt\":\"$LONG_PROMPT\"}" | "$HOOK"
) &
PID_B=$!

wait $PID_A
wait $PID_B

# Inspect what landed.
rows=$(sqlite3 "$TMPDIR/events.sqlite" 'SELECT count(*) FROM events')
echo "  Events recorded: $rows (expected: 4 — A: 3, B: 1)"

if [ "$rows" != "4" ]; then
    echo "[FAIL] expected 4 rows total, got $rows"
    sqlite3 "$TMPDIR/events.sqlite" 'SELECT session_id, event, ts FROM events ORDER BY ts'
    exit 1
fi

# Compute the cross_session value via the reclassify module directly.
result=$(python3 - <<'PYEOF'
import os, sqlite3, sys
sys.path.insert(0, os.path.join(os.environ.get('REPO_ROOT', '.'), 'tools/claude-time'))
import reclassify

db = os.path.join(os.environ['CLAUDE_TIME_DIR'], 'events.sqlite')
conn = sqlite3.connect(db); conn.row_factory = sqlite3.Row
rows = [dict(r) for r in conn.execute("SELECT * FROM events ORDER BY ts")]
conn.close()

gaps = reclassify.gap_buckets(rows, chars_per_sec=6.0,
                              reading_threshold_sec=120,
                              thinking_threshold_sec=300)
a_gaps = [g for g in gaps if g.session_id == "A"]
if not a_gaps:
    print("NO_A_GAP")
    sys.exit()
g = a_gaps[0]
print(f"wall_clock_ms={g.wall_clock_ms}")
print(f"cross_session_ms={g.cross_session_ms}")
print(f"effective_ms={g.effective_ms}")
print(f"bucket={g.bucket}")
PYEOF
)
export REPO_ROOT
echo "$result"

# Parse and assert
cross=$(echo "$result" | grep -oE 'cross_session_ms=[0-9]+' | cut -d= -f2)
wall=$(echo "$result" | grep -oE 'wall_clock_ms=[0-9]+' | cut -d= -f2)

# Expected: B's prompt is 600 chars / 6 cps = 100000ms typing debit.
# The actual cross_session_ms should equal exactly that.
if [ -z "$cross" ] || [ -z "$wall" ]; then
    echo "[FAIL] could not parse gap analysis result"
    exit 1
fi

echo
if [ "$cross" -ge 99000 ] && [ "$cross" -le 101000 ]; then
    echo "[PASS] cross_session_ms = $cross (expected ~100000 for 600-char B prompt at 6 cps)"
    echo "       → A's wall-clock gap of ${wall}ms was reattributed by ~100s of B's typing-debit"
    echo "       → without reattribution, the bucket would have been determined by raw wall-clock"
    exit 0
else
    echo "[FAIL] cross_session_ms = $cross (expected ~100000)"
    echo "       Either: WAL didn't merge B's write before reclassify ran, OR reattribution math broke."
    exit 1
fi
