#!/usr/bin/env bash
# Benchmark the claude-time hook: measure per-call overhead.
#
# Three scenarios, each 100 invocations, measured against the deployed
# symlink at ~/.claude/hooks/claude-time-hook.pl:
#   1. Fast-fail path (env var unset)
#   2. Set path with Stop event
#   3. Set path with mixed events (mirrors realistic usage)
#
# Prints a summary table. Exits 1 if the set-path budget is exceeded
# (per the spec's amended performance contract: < 2000ms / 100 calls on
# macOS, < 500ms on Linux). Use --no-fail to print results without
# asserting (e.g. on slow CI hardware).
#
# Run via:
#   tools/claude-time/test/bench.sh           # measure + assert budget
#   tools/claude-time/test/bench.sh --no-fail # measure only

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOOK="$HOME/.claude/hooks/claude-time-hook.pl"
[ -f "$HOOK" ] || HOOK="$REPO_ROOT/tools/claude-time/hook.pl"

NO_FAIL=0
if [ "${1:-}" = "--no-fail" ]; then
    NO_FAIL=1
fi

TMPDIR="$(mktemp -d -t claude-time-bench-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

# Use Time::HiRes for ms-precision wall clock (consistent with hook.pl).
ms_now() {
    perl -MTime::HiRes=time -e 'printf "%d\n", time*1000'
}

# Detect OS for the budget value (Linux GNU date supports %3N → faster hook).
OS="$(uname -s)"
case "$OS" in
    Darwin) BUDGET_MS=2000; OS_LABEL="macOS" ;;
    Linux)  BUDGET_MS=500;  OS_LABEL="Linux" ;;
    *)      BUDGET_MS=2000; OS_LABEL="$OS (using macOS budget)" ;;
esac

echo "claude-time hook.pl — benchmark"
echo "  HOOK: $HOOK"
echo "  CLAUDE_TIME_DIR: $TMPDIR"
echo "  OS: $OS_LABEL (budget: < ${BUDGET_MS}ms / 100 calls)"
echo

# Warm the Perl interpreter cache (one throwaway invocation before timing).
unset CLAUDE_TIME_TRACKING
echo '{}' | "$HOOK" > /dev/null 2>&1

# ── Scenario 1: fast-fail (CLAUDE_TIME_TRACKING unset) ────────────────
unset CLAUDE_TIME_TRACKING
PAYLOAD='{"hook_event_name":"Stop","session_id":"u","cwd":"/x"}'
start=$(ms_now)
for i in $(seq 1 100); do
    echo "$PAYLOAD" | "$HOOK" > /dev/null 2>&1
done
end=$(ms_now)
fastfail_ms=$((end - start))
fastfail_per_call=$((fastfail_ms / 100))

# ── Scenario 2: set path, all Stop events ─────────────────────────────
export CLAUDE_TIME_DIR="$TMPDIR" CLAUDE_TIME_TRACKING=1
PAYLOAD='{"hook_event_name":"Stop","session_id":"s","cwd":"/x"}'
start=$(ms_now)
for i in $(seq 1 100); do
    echo "$PAYLOAD" | "$HOOK" > /dev/null 2>&1
done
end=$(ms_now)
stop_ms=$((end - start))
stop_per_call=$((stop_ms / 100))

# Verify rows landed (defensive — if not, benchmark is meaningless).
stop_rows=$(sqlite3 "$TMPDIR/events.sqlite" 'SELECT count(*) FROM events' 2>/dev/null || echo 0)

# ── Scenario 3: set path, mixed events ────────────────────────────────
# 10 distinct event names rotated through 100 calls (10 of each).
rm -f "$TMPDIR/events.sqlite" "$TMPDIR/events.sqlite-shm" "$TMPDIR/events.sqlite-wal"
events=(
    "UserPromptSubmit" "PreToolUse" "PostToolUse" "PostToolUseFailure" "Stop"
    "Notification" "SessionStart" "SessionEnd" "SubagentStart" "SubagentStop"
)
start=$(ms_now)
for i in $(seq 1 100); do
    name="${events[$(( (i - 1) % 10 ))]}"
    case "$name" in
        UserPromptSubmit)
            echo "{\"hook_event_name\":\"$name\",\"session_id\":\"s\",\"cwd\":\"/x\",\"prompt\":\"hello\"}" ;;
        PreToolUse|PostToolUse|PostToolUseFailure)
            echo "{\"hook_event_name\":\"$name\",\"session_id\":\"s\",\"cwd\":\"/x\",\"tool_name\":\"Bash\",\"tool_use_id\":\"t$i\"}" ;;
        Notification)
            echo "{\"hook_event_name\":\"$name\",\"session_id\":\"s\",\"cwd\":\"/x\",\"message\":\"awaiting\"}" ;;
        SessionStart)
            echo "{\"hook_event_name\":\"$name\",\"session_id\":\"s\",\"cwd\":\"/x\",\"source\":\"resume\"}" ;;
        SubagentStart|SubagentStop)
            echo "{\"hook_event_name\":\"$name\",\"session_id\":\"s\",\"cwd\":\"/x\",\"subagent_type\":\"Explore\"}" ;;
        *)
            echo "{\"hook_event_name\":\"$name\",\"session_id\":\"s\",\"cwd\":\"/x\"}" ;;
    esac | "$HOOK" > /dev/null 2>&1
done
end=$(ms_now)
mixed_ms=$((end - start))
mixed_per_call=$((mixed_ms / 100))
mixed_rows=$(sqlite3 "$TMPDIR/events.sqlite" 'SELECT count(*) FROM events' 2>/dev/null || echo 0)

# ── Report ────────────────────────────────────────────────────────────
echo "  Scenario                          Total      Per-call    Rows"
echo "  ────────────────────────────────  ─────────  ──────────  ─────"
printf "  1. fast-fail (env unset)          %5dms     %3dms/call   n/a\n" "$fastfail_ms" "$fastfail_per_call"
printf "  2. set-path Stop ×100             %5dms     %3dms/call   %3d\n" "$stop_ms" "$stop_per_call" "$stop_rows"
printf "  3. set-path mixed (10 events ×10) %5dms     %3dms/call   %3d\n" "$mixed_ms" "$mixed_per_call" "$mixed_rows"
echo

# ── Budget assertion (set-path scenarios only) ────────────────────────
if [ $NO_FAIL -eq 1 ]; then
    echo "(--no-fail: not asserting budget)"
    exit 0
fi

worst_set_ms=$stop_ms
[ $mixed_ms -gt $worst_set_ms ] && worst_set_ms=$mixed_ms

if [ $worst_set_ms -lt $BUDGET_MS ]; then
    echo "✓ Within budget (worst set-path: ${worst_set_ms}ms vs ${BUDGET_MS}ms)"
    exit 0
else
    echo "✗ OVER BUDGET (worst set-path: ${worst_set_ms}ms vs ${BUDGET_MS}ms)"
    echo "  This is the perf contract from the spec amendment (2026-05-18)."
    echo "  Either the hook regressed, or this hardware is slower than dev baseline."
    exit 1
fi
