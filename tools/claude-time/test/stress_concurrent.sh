#!/usr/bin/env bash
# Concurrent-write stress test for tools/claude-time/hook.pl.
#
# Spec acceptance #2: "WAL mode enabled to support concurrent writers
# (multiple Claude Code instances)." This script exercises that by
# spawning 50 hook invocations in parallel (xargs -P 50), then asserts:
#   - All 50 succeed (exit 0)
#   - DB has exactly 50 rows
#   - No "database is locked" errors in stderr
#
# Exits 0 if all assertions hold.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOOK="$HOME/.claude/hooks/claude-time-hook.pl"
[ -f "$HOOK" ] || HOOK="$REPO_ROOT/tools/claude-time/hook.pl"

TMPDIR="$(mktemp -d -t claude-time-stress-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

export CLAUDE_TIME_DIR="$TMPDIR" CLAUDE_TIME_TRACKING=1

echo "claude-time concurrent-write stress test"
echo "  HOOK: $HOOK"
echo "  CLAUDE_TIME_DIR: $TMPDIR"
echo

# Pre-create the DB to skip the schema-bootstrap race (multiple writers
# attempting CREATE TABLE concurrently isn't pathological — IF NOT EXISTS
# is idempotent — but pre-creating isolates concurrency from setup).
echo '{"hook_event_name":"Stop","session_id":"warmup","cwd":"/x"}' | "$HOOK" > /dev/null 2>&1
sqlite3 "$TMPDIR/events.sqlite" 'DELETE FROM events'

# Spawn 50 concurrent hook invocations, each writing a distinct session_id.
# xargs -P 50 spawns up to 50 in parallel; each one is a fresh perl process.
# Capture stderr to detect "database is locked" or other SQLite errors.
STDERR=$(seq 1 50 | xargs -P 50 -I {} sh -c "
  echo '{\"hook_event_name\":\"Stop\",\"session_id\":\"stress-{}\",\"cwd\":\"/x\"}' | $HOOK
" 2>&1)
xargs_rc=$?

rows=$(sqlite3 "$TMPDIR/events.sqlite" 'SELECT count(*) FROM events')
distinct=$(sqlite3 "$TMPDIR/events.sqlite" 'SELECT count(DISTINCT session_id) FROM events')

echo "  xargs exit code:           $xargs_rc"
echo "  rows in DB:                $rows (expected 50)"
echo "  distinct session_ids:      $distinct (expected 50)"
echo "  stderr noise (chars):      $(echo -n "$STDERR" | wc -c | tr -d ' ')"
echo

fail=0
if [ $xargs_rc -ne 0 ]; then
    echo "[FAIL] xargs exit code was $xargs_rc (some hook calls failed)"
    fail=1
fi
if [ "$rows" != "50" ]; then
    echo "[FAIL] Expected 50 rows, got $rows — some writes were lost"
    fail=1
fi
if [ "$distinct" != "50" ]; then
    echo "[FAIL] Expected 50 distinct session_ids, got $distinct — events overwrote each other"
    fail=1
fi
if [ -n "$STDERR" ]; then
    echo "[FAIL] Unexpected stderr from hook (should be silent):"
    echo "$STDERR" | head -5
    fail=1
fi

if [ $fail -eq 0 ]; then
    echo "[PASS] 50 concurrent writers, all succeeded, all 50 rows persisted, no errors"
    exit 0
fi
exit 1
