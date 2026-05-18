#!/usr/bin/env bash
# Phase 1 behavioral test for tools/claude-time/hook.pl.
#
# Codifies the 7 verify-self / verify-human checks against a deployed symlink
# at ~/.claude/hooks/claude-time-hook.pl. Each check is an assertion on
# observable behavior (rc, file existence, row count, output bytes) — no
# implementation-detail introspection.
#
# Runs against a temp CLAUDE_TIME_DIR so it never touches the user's real
# ~/.claude-time/. Sets a flag for the runner to detect failure.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOOK="$REPO_ROOT/tools/claude-time/hook.pl"

TMPDIR="$(mktemp -d -t claude-time-test-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

export CLAUDE_TIME_DIR="$TMPDIR"

pass=0
fail=0

check() {
    local name="$1"
    local result="$2"  # "pass" or "fail"
    local detail="${3:-}"
    if [ "$result" = "pass" ]; then
        echo "  [PASS] $name"
        pass=$((pass + 1))
    else
        echo "  [FAIL] $name${detail:+ — $detail}"
        fail=$((fail + 1))
    fi
}

reset_db() {
    rm -f "$TMPDIR/events.sqlite" "$TMPDIR/events.sqlite-shm" "$TMPDIR/events.sqlite-wal"
}

echo "tools/claude-time/hook.pl — Phase 1 behavioral tests"
echo "  HOOK: $HOOK"
echo "  CLAUDE_TIME_DIR: $TMPDIR"
echo

# ── 1. Fast-fail: env unset → exit 0, no DB, no output ─────────────────
reset_db
unset CLAUDE_TIME_TRACKING
OUT=$(echo '{"hook_event_name":"Stop","session_id":"t"}' | "$HOOK" 2>&1)
rc=$?
if [ $rc -eq 0 ] && [ ! -f "$TMPDIR/events.sqlite" ] && [ -z "$OUT" ]; then
    check "fast-fail: env unset → exit 0, no DB, no output" pass
else
    check "fast-fail: env unset → exit 0, no DB, no output" fail "rc=$rc, db=$([ -f "$TMPDIR/events.sqlite" ] && echo yes || echo no), out='$OUT'"
fi

# ── 2. Set path: env=1 → DB created with row ───────────────────────────
reset_db
export CLAUDE_TIME_TRACKING=1
OUT=$(echo '{"hook_event_name":"Stop","session_id":"s1","cwd":"/x"}' | "$HOOK" 2>&1)
rc=$?
rows=$(sqlite3 "$TMPDIR/events.sqlite" 'SELECT count(*) FROM events' 2>/dev/null)
if [ $rc -eq 0 ] && [ "$rows" = "1" ] && [ -z "$OUT" ]; then
    check "set path: Stop event → 1 row, clean output" pass
else
    check "set path: Stop event → 1 row, clean output" fail "rc=$rc, rows=$rows, out='$OUT'"
fi

# ── 3. Schema: events table + 2 indexes present ────────────────────────
tbl=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='events'")
idx=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT count(*) FROM sqlite_master WHERE type='index' AND name IN ('idx_session_ts','idx_ts')")
if [ "$tbl" = "1" ] && [ "$idx" = "2" ]; then
    check "schema: events table + idx_session_ts + idx_ts present" pass
else
    check "schema: events table + idx_session_ts + idx_ts present" fail "tbl=$tbl, idx=$idx"
fi

# ── 4. WAL pragma applied ──────────────────────────────────────────────
mode=$(sqlite3 "$TMPDIR/events.sqlite" 'PRAGMA journal_mode')
if [ "$mode" = "wal" ]; then
    check "WAL pragma: journal_mode = wal" pass
else
    check "WAL pragma: journal_mode = wal" fail "mode=$mode"
fi

# ── 5. Row columns populated correctly for Stop event ──────────────────
row=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT session_id, cwd, event, tool_name, agent_type, meta, ts > 0 FROM events LIMIT 1")
expected="s1|/x|Stop|||\|1"
# tool_name, agent_type, meta NULL for Stop; ts > 0
if [ "$row" = "s1|/x|Stop||||1" ]; then
    check "row shape: session_id, cwd, event, NULL extras, ts > 0" pass
else
    check "row shape: session_id, cwd, event, NULL extras, ts > 0" fail "got '$row'"
fi

# ── 6. Non-Stop events no-op in Phase 1 ────────────────────────────────
reset_db
echo '{"hook_event_name":"Stop","session_id":"s","cwd":"/x"}' | "$HOOK"
echo '{"hook_event_name":"PreToolUse","session_id":"s","tool_name":"Bash"}' | "$HOOK"
echo '{"hook_event_name":"UserPromptSubmit","session_id":"s","prompt":"hi"}' | "$HOOK"
rows=$(sqlite3 "$TMPDIR/events.sqlite" 'SELECT count(*) FROM events')
if [ "$rows" = "1" ]; then
    check "phase-1 scope: only Stop event recorded; other events no-op" pass
else
    check "phase-1 scope: only Stop event recorded; other events no-op" fail "rows=$rows (expected 1)"
fi

# ── 7. SQL injection safety: apostrophe in session_id stored intact ───
reset_db
echo "{\"hook_event_name\":\"Stop\",\"session_id\":\"it's-tricky\",\"cwd\":\"/Users/o'malley\"}" | "$HOOK"
got_sid=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT session_id FROM events LIMIT 1")
got_cwd=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT cwd FROM events LIMIT 1")
if [ "$got_sid" = "it's-tricky" ] && [ "$got_cwd" = "/Users/o'malley" ]; then
    check "SQL safety: apostrophe in session_id + cwd stored intact" pass
else
    check "SQL safety: apostrophe in session_id + cwd stored intact" fail "sid='$got_sid', cwd='$got_cwd'"
fi

# ── 8. Malformed JSON → exit 0, no crash ───────────────────────────────
OUT=$(echo 'this is not json at all' | "$HOOK" 2>&1)
rc=$?
if [ $rc -eq 0 ] && [ -z "$OUT" ]; then
    check "malformed JSON → exit 0, no output" pass
else
    check "malformed JSON → exit 0, no output" fail "rc=$rc, out='$OUT'"
fi

# ── 9. Read-only DB → exit 0, no output ────────────────────────────────
chmod 444 "$TMPDIR/events.sqlite"
OUT=$(echo '{"hook_event_name":"Stop","session_id":"s","cwd":"/x"}' | "$HOOK" 2>&1)
rc=$?
chmod 644 "$TMPDIR/events.sqlite"
if [ $rc -eq 0 ] && [ -z "$OUT" ]; then
    check "read-only DB → exit 0, no output" pass
else
    check "read-only DB → exit 0, no output" fail "rc=$rc, out='$OUT'"
fi

# ── 10. Empty stdin (manual invocation) → exit 0, no crash ─────────────
OUT=$("$HOOK" < /dev/null 2>&1)
rc=$?
if [ $rc -eq 0 ] && [ -z "$OUT" ]; then
    check "empty stdin → exit 0, no output" pass
else
    check "empty stdin → exit 0, no output" fail "rc=$rc, out='$OUT'"
fi

echo
echo "=== Phase 1 hook test summary ==="
echo "PASS: $pass | FAIL: $fail"
if [ $fail -eq 0 ]; then
    echo "All Phase 1 behavioral assertions hold."
    exit 0
else
    exit 1
fi
