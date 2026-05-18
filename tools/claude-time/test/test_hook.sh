#!/usr/bin/env bash
# Behavioral test for tools/claude-time/hook.pl (Phases 1 + 2).
#
# Codifies observable behavior against a deployed symlink at
# ~/.claude/hooks/claude-time-hook.pl. Each check is an assertion on rc,
# file existence, row count, column values, or output bytes — no
# implementation-detail introspection.
#
# Phase 1 coverage: opt-in gate, schema bootstrap, WAL, single-event INSERT,
# SQL injection safety, malformed JSON handling, read-only DB, empty stdin.
# Phase 2 coverage: all 10 hook events produce correctly-shaped rows;
# unrecognized events no-op; UserPromptSubmit privacy invariant; Notification
# 200-char truncation.
#
# Runs against a temp CLAUDE_TIME_DIR so it never touches the user's real
# ~/.claude-time/. Exits 0 on full pass, non-zero on any failure.

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

echo "tools/claude-time/hook.pl — behavioral tests (Phases 1 + 2)"
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

# ── 6. All 10 hook events produce one row each (Phase 2 dispatch) ──────
reset_db
echo '{"hook_event_name":"UserPromptSubmit","session_id":"s","prompt":"hi"}' | "$HOOK"
echo '{"hook_event_name":"PreToolUse","session_id":"s","tool_name":"Bash","tool_use_id":"t1"}' | "$HOOK"
echo '{"hook_event_name":"PostToolUse","session_id":"s","tool_name":"Bash","tool_use_id":"t1"}' | "$HOOK"
echo '{"hook_event_name":"PostToolUseFailure","session_id":"s","tool_name":"Bash","tool_use_id":"t2"}' | "$HOOK"
echo '{"hook_event_name":"Stop","session_id":"s","cwd":"/x"}' | "$HOOK"
echo '{"hook_event_name":"Notification","session_id":"s","message":"awaiting"}' | "$HOOK"
echo '{"hook_event_name":"SessionStart","session_id":"s","source":"resume"}' | "$HOOK"
echo '{"hook_event_name":"SessionEnd","session_id":"s"}' | "$HOOK"
echo '{"hook_event_name":"SubagentStart","session_id":"s","subagent_type":"Explore"}' | "$HOOK"
echo '{"hook_event_name":"SubagentStop","session_id":"s","subagent_type":"Explore"}' | "$HOOK"
rows=$(sqlite3 "$TMPDIR/events.sqlite" 'SELECT count(*) FROM events')
events=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT group_concat(event, ',') FROM (SELECT DISTINCT event FROM events ORDER BY event)")
expected_events="Notification,PostToolUse,PostToolUseFailure,PreToolUse,SessionEnd,SessionStart,Stop,SubagentStart,SubagentStop,UserPromptSubmit"
if [ "$rows" = "10" ] && [ "$events" = "$expected_events" ]; then
    check "all 10 hook events recorded (one row each)" pass
else
    check "all 10 hook events recorded (one row each)" fail "rows=$rows, events='$events'"
fi

# ── 6a. Unrecognized event no-ops (forward-compat) ─────────────────────
reset_db
echo '{"hook_event_name":"FutureEventNotYetImplemented","session_id":"s"}' | "$HOOK"
rows=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT count(*) FROM events" 2>/dev/null || echo "0")
# No row, but also no error: if the DB doesn't exist yet, count is 0 OR sqlite errors with no such file
if [ "$rows" = "0" ] || [ ! -f "$TMPDIR/events.sqlite" ]; then
    check "unrecognized event → no row, no crash (forward-compat)" pass
else
    check "unrecognized event → no row, no crash (forward-compat)" fail "rows=$rows"
fi

# ── 6b. PreToolUse meta carries tool_use_id; tool_name in column ───────
reset_db
echo '{"hook_event_name":"PreToolUse","session_id":"s","tool_name":"Bash","tool_use_id":"abc123"}' | "$HOOK"
got_tool=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT tool_name FROM events LIMIT 1")
got_tuid=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT json_extract(meta, '\$.tool_use_id') FROM events LIMIT 1")
if [ "$got_tool" = "Bash" ] && [ "$got_tuid" = "abc123" ]; then
    check "PreToolUse: tool_name column populated; tool_use_id in meta JSON" pass
else
    check "PreToolUse: tool_name column populated; tool_use_id in meta JSON" fail "tool='$got_tool', tuid='$got_tuid'"
fi

# ── 6c. SubagentStart agent_type column populated ──────────────────────
reset_db
echo '{"hook_event_name":"SubagentStart","session_id":"s","subagent_type":"Explore"}' | "$HOOK"
got_agent=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT agent_type FROM events LIMIT 1")
got_meta=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT meta FROM events LIMIT 1")
if [ "$got_agent" = "Explore" ] && [ -z "$got_meta" ]; then
    check "SubagentStart: agent_type populated, meta NULL" pass
else
    check "SubagentStart: agent_type populated, meta NULL" fail "agent='$got_agent', meta='$got_meta'"
fi

# ── 6d. SessionStart meta.source populated ─────────────────────────────
reset_db
echo '{"hook_event_name":"SessionStart","session_id":"s","source":"resume"}' | "$HOOK"
got_src=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT json_extract(meta, '\$.source') FROM events LIMIT 1")
if [ "$got_src" = "resume" ]; then
    check "SessionStart: meta.source populated" pass
else
    check "SessionStart: meta.source populated" fail "source='$got_src'"
fi

# ── 6e. Notification message truncated to 200 chars ────────────────────
reset_db
LONG_MSG=$(perl -e 'print "X" x 300')
echo "{\"hook_event_name\":\"Notification\",\"session_id\":\"s\",\"message\":\"$LONG_MSG\"}" | "$HOOK"
got_len=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT length(json_extract(meta, '\$.message')) FROM events LIMIT 1")
if [ "$got_len" = "200" ]; then
    check "Notification: message truncated to 200 chars" pass
else
    check "Notification: message truncated to 200 chars" fail "got length $got_len (expected 200)"
fi

# ── 6f. Privacy: UserPromptSubmit records length, NOT prompt text ──────
reset_db
echo '{"hook_event_name":"UserPromptSubmit","session_id":"s","prompt":"SECRET-MARKER-XYZ hello world"}' | "$HOOK"
got_len=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT json_extract(meta, '\$.prompt_length_chars') FROM events LIMIT 1")
# Grep -a treats the binary DB file as text. Should find nothing.
secret_found=$(grep -a "SECRET-MARKER-XYZ" "$TMPDIR/events.sqlite" 2>/dev/null | wc -l | tr -d ' ')
expected_len=29  # length of "SECRET-MARKER-XYZ hello world"
if [ "$got_len" = "$expected_len" ] && [ "$secret_found" = "0" ]; then
    check "UserPromptSubmit: length recorded ($expected_len), prompt text never in DB" pass
else
    check "UserPromptSubmit: length recorded, prompt text never in DB" fail "len='$got_len' (expected $expected_len), secret_found=$secret_found"
fi

# ── 6g. PreToolUse/PostToolUse pair share tool_use_id (pairing signal) ─
reset_db
echo '{"hook_event_name":"PreToolUse","session_id":"s","tool_name":"Bash","tool_use_id":"pair-1"}' | "$HOOK"
echo '{"hook_event_name":"PostToolUse","session_id":"s","tool_name":"Bash","tool_use_id":"pair-1"}' | "$HOOK"
pair_rows=$(sqlite3 "$TMPDIR/events.sqlite" "SELECT count(*) FROM events WHERE json_extract(meta, '\$.tool_use_id') = 'pair-1'")
if [ "$pair_rows" = "2" ]; then
    check "PreToolUse/PostToolUse share tool_use_id (durations can be paired)" pass
else
    check "PreToolUse/PostToolUse share tool_use_id" fail "rows with pair-1: $pair_rows (expected 2)"
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
echo "=== hook.pl behavioral test summary ==="
echo "PASS: $pass | FAIL: $fail"
if [ $fail -eq 0 ]; then
    echo "All behavioral assertions hold."
    exit 0
else
    exit 1
fi
