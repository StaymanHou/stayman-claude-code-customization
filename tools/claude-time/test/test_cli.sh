#!/usr/bin/env bash
# End-to-end test for the claude-time CLI binary.
#
# Codifies the CLI behaviors that aren't reachable from the pure-function
# unit tests in test_reclassify.py:
#   - --cwd filter against the SQLite DB
#   - empty-window message (no events / out-of-range date)
#   - config.json overrides (chars_per_sec, thresholds) round-trip via the CLI
#   - --help exit code + flag listing (regression guard for argparse breakage)
#
# Runs against an isolated temp CLAUDE_TIME_DIR so it never touches the
# user's real ~/.claude-time/. Exits 0 on full pass.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CLI="$REPO_ROOT/tools/claude-time/claude-time"

TMPDIR="$(mktemp -d -t claude-time-cli-test-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

export CLAUDE_TIME_DIR="$TMPDIR"

pass=0
fail=0
check() {
    local name="$1"
    local result="$2"
    local detail="${3:-}"
    if [ "$result" = "pass" ]; then
        echo "  [PASS] $name"
        pass=$((pass + 1))
    else
        echo "  [FAIL] $name${detail:+ — $detail}"
        fail=$((fail + 1))
    fi
}

# Compute today's noon (local) in ms, so seeded events land in the default
# report window. This is the same shape the hook uses (unix ms).
TODAY_NOON_MS=$(python3 -c "
from datetime import date, datetime, time
print(int(datetime.combine(date.today(), time(12, 0)).timestamp() * 1000))
")

DB="$TMPDIR/events.sqlite"

# Seed a minimal events table (the hook would do this, but we want full control
# over timestamps and rows).
sqlite3 "$DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
SQL

echo "claude-time CLI end-to-end tests"
echo "  CLI: $CLI"
echo "  CLAUDE_TIME_DIR: $TMPDIR"
echo

# ── 1. --help exits 0 and lists the 4 filter flags ─────────────────────
OUT=$("$CLI" report --help 2>&1)
rc=$?
flag_count=$(echo "$OUT" | grep -cE '^\s+--(weekly|date|session|cwd)')
if [ $rc -eq 0 ] && [ "$flag_count" = "4" ]; then
    check "report --help exits 0, lists 4 filter flags" pass
else
    check "report --help exits 0, lists 4 filter flags" fail "rc=$rc, flags=$flag_count"
fi

# ── 2. Empty-window: --date in the distant past returns the no-events message ──
OUT=$("$CLI" report --date 1970-01-01 2>&1)
rc=$?
if [ $rc -eq 0 ] && echo "$OUT" | grep -q "(no events in window"; then
    check "empty-window: --date 1970-01-01 prints '(no events in window...)'" pass
else
    check "empty-window: --date 1970-01-01" fail "rc=$rc, out='$OUT'"
fi

# ── 3. Seed events in two cwds; --cwd filter partitions them correctly ─
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         's', '/foo', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 's', '/foo', 'PreToolUse',       'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+200)), 's', '/foo', 'PostToolUse',      'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+300)), 's', '/bar', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+400)), 's', '/bar', 'PreToolUse',       'Edit', NULL, '{"tool_use_id":"t2"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+500)), 's', '/bar', 'PostToolUse',      'Edit', NULL, '{"tool_use_id":"t2"}');
SQL

OUT_FOO=$("$CLI" report --cwd /foo 2>&1)
OUT_BAR=$("$CLI" report --cwd /bar 2>&1)

if echo "$OUT_FOO" | grep -q "Bash" && ! echo "$OUT_FOO" | grep -q "Edit"; then
    check "--cwd /foo: contains Bash, excludes Edit" pass
else
    check "--cwd /foo: contains Bash, excludes Edit" fail "Bash=$(echo "$OUT_FOO" | grep -c Bash), Edit=$(echo "$OUT_FOO" | grep -c Edit)"
fi

if echo "$OUT_BAR" | grep -q "Edit" && ! echo "$OUT_BAR" | grep -q "Bash"; then
    check "--cwd /bar: contains Edit, excludes Bash" pass
else
    check "--cwd /bar: contains Edit, excludes Bash" fail "Edit=$(echo "$OUT_BAR" | grep -c Edit), Bash=$(echo "$OUT_BAR" | grep -c Bash)"
fi

# ── 4. --session filter ────────────────────────────────────────────────
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         'sA', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 'sA', '/p', 'Stop',             NULL, NULL, NULL);
INSERT INTO events VALUES ($((TODAY_NOON_MS+200)), 'sB', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+300)), 'sB', '/p', 'Stop',             NULL, NULL, NULL);
SQL

OUT=$("$CLI" report --session sA 2>&1)
# After session filter, the events: prefix should report exactly 2 events
if echo "$OUT" | grep -qE "events: 2$"; then
    check "--session sA: only that session's events counted" pass
else
    actual=$(echo "$OUT" | grep -oE 'events: [0-9]+' | head -1)
    check "--session sA: only that session's events counted" fail "$actual (expected 2)"
fi

# ── 5. Config override: chars_per_sec=12 produces half the typing debit ─
# Seed a 110s gap with a 600-char next prompt. At default cps=6, that's
# 100s of typing debit → ~10s effective. At cps=12, 50s typing debit → 60s effective.
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,             's', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+1000)),    's', '/p', 'Stop',             NULL, NULL, NULL);
INSERT INTO events VALUES ($((TODAY_NOON_MS+111000)),  's', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":600}');
SQL

# Without config (default cps=6.0). The report header lists the typing-debit value.
rm -f "$TMPDIR/config.json"
OUT_DEFAULT=$("$CLI" report 2>&1)
if echo "$OUT_DEFAULT" | grep -q "typing debit: 6.0 chars/sec"; then
    check "default config: report header shows cps=6.0" pass
else
    check "default config: report header shows cps=6.0" fail "$(echo "$OUT_DEFAULT" | grep typing)"
fi

# Now override via config.json.
echo '{"chars_per_sec": 12.0}' > "$TMPDIR/config.json"
OUT_OVERRIDE=$("$CLI" report 2>&1)
if echo "$OUT_OVERRIDE" | grep -q "typing debit: 12.0 chars/sec"; then
    check "config override: report header reflects chars_per_sec=12.0 from config.json" pass
else
    check "config override: report header reflects chars_per_sec=12.0" fail "$(echo "$OUT_OVERRIDE" | grep typing)"
fi

# ── 6. Malformed config.json: silent fallback to defaults ─────────────
echo 'this is not valid JSON at all' > "$TMPDIR/config.json"
OUT_BAD=$("$CLI" report 2>&1)
rc=$?
if [ $rc -eq 0 ] && echo "$OUT_BAD" | grep -q "typing debit: 6.0 chars/sec"; then
    check "malformed config.json: silent fallback to defaults, exit 0" pass
else
    check "malformed config.json: silent fallback to defaults, exit 0" fail "rc=$rc, header=$(echo "$OUT_BAD" | grep typing)"
fi
rm -f "$TMPDIR/config.json"

# ── 7. --db override: explicit path bypasses CLAUDE_TIME_DIR ──────────
ALT_DB="$TMPDIR/alt.sqlite"
sqlite3 "$ALT_DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
INSERT INTO events VALUES ($TODAY_NOON_MS, 'altsess', '/x', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
SQL

OUT=$("$CLI" report --db "$ALT_DB" 2>&1)
if echo "$OUT" | grep -qE "events: 1$"; then
    check "--db override: reads from explicit path" pass
else
    check "--db override: reads from explicit path" fail "$(echo "$OUT" | grep events)"
fi

# ── 8. --weekly window includes events from yesterday ─────────────────
YESTERDAY_NOON_MS=$(python3 -c "
from datetime import date, datetime, time, timedelta
print(int(datetime.combine(date.today() - timedelta(days=1), time(12, 0)).timestamp() * 1000))
")
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($YESTERDAY_NOON_MS, 's', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($TODAY_NOON_MS,     's', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
SQL

# Today-only: 1 event
OUT_TODAY=$("$CLI" report 2>&1)
# --weekly: 2 events
OUT_WEEK=$("$CLI" report --weekly 2>&1)
today_count=$(echo "$OUT_TODAY" | grep -oE 'events: [0-9]+' | head -1)
week_count=$(echo "$OUT_WEEK" | grep -oE 'events: [0-9]+' | head -1)
if [ "$today_count" = "events: 1" ] && [ "$week_count" = "events: 2" ]; then
    check "--weekly includes yesterday's events; default excludes them" pass
else
    check "--weekly includes yesterday's events" fail "today=$today_count, week=$week_count"
fi

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== claude-time CLI test summary ==="
echo "PASS: $pass | FAIL: $fail"
if [ $fail -eq 0 ]; then
    echo "All CLI assertions hold."
    exit 0
else
    exit 1
fi
