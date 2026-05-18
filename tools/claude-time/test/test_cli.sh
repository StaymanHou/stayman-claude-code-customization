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

# ── 1. --help exits 0 and lists the 5 filter/grouping flags ───────────
OUT=$("$CLI" report --help 2>&1)
rc=$?
flag_count=$(echo "$OUT" | grep -cE '^\s+--(weekly|date|session|cwd|by)')
if [ $rc -eq 0 ] && [ "$flag_count" = "5" ]; then
    check "report --help exits 0, lists 5 filter/grouping flags" pass
else
    check "report --help exits 0, lists 5 filter/grouping flags" fail "rc=$rc, flags=$flag_count"
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

# ── 9. --by cwd groups events into one row per distinct cwd ───────────
# Use explicit project_names aliases for /foo and /bar so the test labels
# survive Phase 2 P2.4 auto-aliasing (which would collapse non-existent paths
# into "misc"). Explicit > auto-derived per the precedence rule.
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         's', '/foo', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 's', '/foo', 'PreToolUse',  'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+5100)),'s', '/foo', 'PostToolUse', 'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+200)), 's', '/bar', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+300)), 's', '/bar', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t2"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+800)), 's', '/bar', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t2"}');
SQL
cat > "$TMPDIR/config.json" <<'JSON'
{"project_names": {"foo-alias": ["/foo"], "bar-alias": ["/bar"]}}
JSON

OUT=$("$CLI" report --by cwd 2>&1)
rc=$?
foo_row=$(echo "$OUT" | grep -cE '^  foo-alias')
bar_row=$(echo "$OUT" | grep -cE '^  bar-alias')
header=$(echo "$OUT" | grep -cE 'Grouped by cwd')
if [ $rc -eq 0 ] && [ "$foo_row" = "1" ] && [ "$bar_row" = "1" ] && [ "$header" = "1" ]; then
    check "--by cwd: one row per cwd, 'Grouped by cwd' header" pass
else
    check "--by cwd: one row per cwd, header present" fail "rc=$rc, foo-alias=$foo_row, bar-alias=$bar_row, header=$header"
fi

# Engagement-total sort: foo-alias has 5s tool time, bar-alias has 500ms — foo must precede bar
foo_line=$(echo "$OUT" | grep -nE '^  foo-alias' | cut -d: -f1)
bar_line=$(echo "$OUT" | grep -nE '^  bar-alias' | cut -d: -f1)
if [ -n "$foo_line" ] && [ -n "$bar_line" ] && [ "$foo_line" -lt "$bar_line" ]; then
    check "--by cwd: rows sorted by engagement total desc (foo before bar)" pass
else
    check "--by cwd: row sort order" fail "foo_line=$foo_line, bar_line=$bar_line"
fi
rm -f "$TMPDIR/config.json"

# ── 10. --by session groups events by session_id ──────────────────────
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         'sX', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 'sX', '/p', 'Stop',             NULL, NULL, NULL);
INSERT INTO events VALUES ($((TODAY_NOON_MS+200)), 'sY', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+300)), 'sY', '/p', 'Stop',             NULL, NULL, NULL);
SQL

OUT=$("$CLI" report --by session 2>&1)
rc=$?
sX_row=$(echo "$OUT" | grep -cE '^  sX')
sY_row=$(echo "$OUT" | grep -cE '^  sY')
header=$(echo "$OUT" | grep -cE 'Grouped by session')
if [ $rc -eq 0 ] && [ "$sX_row" = "1" ] && [ "$sY_row" = "1" ] && [ "$header" = "1" ]; then
    check "--by session: one row per session_id, 'Grouped by session' header" pass
else
    check "--by session: one row per session_id" fail "rc=$rc, sX=$sX_row, sY=$sY_row, header=$header"
fi

# ── 11. --by day groups events by local-TZ calendar date ──────────────
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($YESTERDAY_NOON_MS, 's', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($TODAY_NOON_MS,     's', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
SQL

OUT=$("$CLI" report --by day --weekly 2>&1)
rc=$?
date_rows=$(echo "$OUT" | grep -cE '^  [0-9]{4}-[0-9]{2}-[0-9]{2}')
header=$(echo "$OUT" | grep -cE 'Grouped by day')
if [ $rc -eq 0 ] && [ "$date_rows" = "2" ] && [ "$header" = "1" ]; then
    check "--by day --weekly: one row per local-TZ date" pass
else
    check "--by day --weekly: date rows" fail "rc=$rc, date_rows=$date_rows, header=$header"
fi

# ── 12. --by foo: argparse rejects unknown dimension ──────────────────
ERR=$("$CLI" report --by foo 2>&1)
rc=$?
if [ $rc -ne 0 ] && echo "$ERR" | grep -q 'cwd' && echo "$ERR" | grep -q 'session' && echo "$ERR" | grep -q 'day'; then
    check "--by foo: exits non-zero, error lists valid choices" pass
else
    check "--by foo: error" fail "rc=$rc, err=$ERR"
fi

# ── 13. --by cwd with empty window: empty-window message preserved ────
OUT=$("$CLI" report --by cwd --date 1970-01-01 2>&1)
rc=$?
if [ $rc -eq 0 ] && echo "$OUT" | grep -q '(no events in window'; then
    check "--by cwd --date 1970-01-01: empty-window message" pass
else
    check "--by cwd empty window" fail "rc=$rc, out='$OUT'"
fi

# ── 14. Regression guard: default report unchanged when --by absent ────
# Compare two invocations on the same DB: one with --by cwd, one default.
# They must differ (proves --by is doing something), AND the default invocation
# must contain the 4 canonical section headers from the per-metric layout.
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         's', '/p', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 's', '/p', 'PreToolUse',  'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+200)), 's', '/p', 'PostToolUse', 'Bash', NULL, '{"tool_use_id":"t1"}');
SQL

DEFAULT_OUT=$("$CLI" report 2>&1)
GROUPED_OUT=$("$CLI" report --by cwd 2>&1)

# Default-mode section headers (the canonical 4-section layout)
sec_tool=$(echo "$DEFAULT_OUT" | grep -c 'Tool time')
sec_sub=$(echo "$DEFAULT_OUT" | grep -c 'Subagent time')
sec_act=$(echo "$DEFAULT_OUT" | grep -c 'Active session time')
sec_gap=$(echo "$DEFAULT_OUT" | grep -c 'Reclassified gap buckets')
# Grouped-mode header (must NOT be in default output)
default_has_grouped=$(echo "$DEFAULT_OUT" | grep -c 'Grouped by')

if [ "$sec_tool" = "1" ] && [ "$sec_sub" = "1" ] && [ "$sec_act" = "1" ] && [ "$sec_gap" = "1" ] && [ "$default_has_grouped" = "0" ] && [ "$DEFAULT_OUT" != "$GROUPED_OUT" ]; then
    check "default report unchanged when --by absent (4 sections present, no 'Grouped by')" pass
else
    check "default report unchanged when --by absent" fail "tool=$sec_tool sub=$sec_sub act=$sec_act gap=$sec_gap grouped-leak=$default_has_grouped same-as-grouped=$([ "$DEFAULT_OUT" = "$GROUPED_OUT" ] && echo yes || echo no)"
fi

# ── 15. project_names: explicit alias collapses multiple cwds + sums events ──
# Two events in /foo (5s of Bash) + one event in /bar (500ms of Edit).
# Alias both under "my-project"; the row should sum 5.5s and the raw paths
# should not appear as separate rows.
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         's', '/foo', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 's', '/foo', 'PreToolUse',  'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+5100)),'s', '/foo', 'PostToolUse', 'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+200)), 's', '/bar', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t2"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+700)), 's', '/bar', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t2"}');
SQL
cat > "$TMPDIR/config.json" <<'JSON'
{"project_names": {"my-project": ["/foo", "/bar"]}}
JSON

OUT=$("$CLI" report --by cwd 2>&1)
has_alias=$(echo "$OUT" | grep -cE '^  my-project')
no_foo=$(echo "$OUT" | grep -cE '^  /foo')
no_bar=$(echo "$OUT" | grep -cE '^  /bar')
# 5.0s tool + 500ms tool = 5.5s tool — must appear in the my-project row
sum_check=$(echo "$OUT" | awk '/^  my-project/ {print}' | grep -c '5.5s')
if [ "$has_alias" = "1" ] && [ "$no_foo" = "0" ] && [ "$no_bar" = "0" ] && [ "$sum_check" = "1" ]; then
    check "project_names: alias collapses cwds AND sums events (5.5s = 5s + 500ms)" pass
else
    check "project_names: alias collapse + sum" fail "alias=$has_alias foo_leak=$no_foo bar_leak=$no_bar sum_5.5s=$sum_check"
fi
rm -f "$TMPDIR/config.json"

# ── 16. project_names: malformed entries silent-drop (value not a list) ───
cat > "$TMPDIR/config.json" <<'JSON'
{"project_names": {"oops": "not-a-list", "valid": ["/foo"]}}
JSON
OUT=$("$CLI" report --by cwd 2>&1)
rc=$?
no_oops=$(echo "$OUT" | grep -cE '^  oops')
has_valid=$(echo "$OUT" | grep -cE '^  valid')
if [ $rc -eq 0 ] && [ "$no_oops" = "0" ] && [ "$has_valid" = "1" ]; then
    check "project_names: malformed entry silent-drops; valid sibling still applies" pass
else
    check "project_names: malformed silent-drop" fail "rc=$rc no_oops=$no_oops has_valid=$has_valid"
fi
rm -f "$TMPDIR/config.json"

# ── 17. project_names: top-level malformed (string instead of dict) → empty ──
echo '{"project_names": "garbage"}' > "$TMPDIR/config.json"
OUT=$("$CLI" report --by cwd 2>&1)
rc=$?
# With no aliases, both /foo and /bar fall through to auto-alias path → "misc"
# (since /foo and /bar don't exist on disk in this test env)
has_misc=$(echo "$OUT" | grep -cE '^  misc')
if [ $rc -eq 0 ] && [ "$has_misc" = "1" ]; then
    check "project_names: top-level malformed silent-drops, exit 0" pass
else
    check "project_names: top-level malformed" fail "rc=$rc has_misc=$has_misc"
fi
rm -f "$TMPDIR/config.json"

# ── 18. Auto-alias: git-repo cwd → basename(repo_root) (no config) ────
# Create a temp git repo. Events under the repo path should label as the basename.
REPO_DIR="$TMPDIR/my-test-project"
mkdir -p "$REPO_DIR"
git -C "$REPO_DIR" init -q 2>/dev/null
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         's', '$REPO_DIR', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 's', '$REPO_DIR', 'PreToolUse',  'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+5100)),'s', '$REPO_DIR', 'PostToolUse', 'Bash', NULL, '{"tool_use_id":"t1"}');
SQL

OUT=$("$CLI" report --by cwd 2>&1)
has_basename=$(echo "$OUT" | grep -cE '^  my-test-project')
no_full_path=$(echo "$OUT" | grep -cF "$REPO_DIR ")
if [ "$has_basename" = "1" ] && [ "$no_full_path" = "0" ]; then
    check "auto-alias: git-repo cwd → basename(repo_root)" pass
else
    check "auto-alias: git-repo basename" fail "basename=$has_basename full_path_leak=$no_full_path"
fi

# ── 19. Auto-alias: nested cwd inside repo → still resolves to repo basename ──
mkdir -p "$REPO_DIR/src/sub"
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS, 's', '$REPO_DIR/src/sub', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
SQL
OUT=$("$CLI" report --by cwd 2>&1)
has_basename=$(echo "$OUT" | grep -cE '^  my-test-project')
if [ "$has_basename" = "1" ]; then
    check "auto-alias: nested cwd inside repo also resolves to repo basename" pass
else
    check "auto-alias: nested cwd" fail "basename=$has_basename"
fi

# ── 20. Auto-alias: non-git cwd → 'misc' ──────────────────────────────
# Use TMPDIR root itself, which is not a git repo.
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS, 's', '$TMPDIR', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
SQL
OUT=$("$CLI" report --by cwd 2>&1)
has_misc=$(echo "$OUT" | grep -cE '^  misc')
no_tmpdir=$(echo "$OUT" | grep -cF "$TMPDIR ")
if [ "$has_misc" = "1" ] && [ "$no_tmpdir" = "0" ]; then
    check "auto-alias: non-git cwd → 'misc' bucket" pass
else
    check "auto-alias: misc bucket" fail "misc=$has_misc tmpdir_leak=$no_tmpdir"
fi

# ── 21. Auto-alias: multiple non-git cwds aggregate into single 'misc' row ──
NONGIT_A="$TMPDIR/non-git-a"
NONGIT_B="$TMPDIR/non-git-b"
mkdir -p "$NONGIT_A" "$NONGIT_B"
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         's', '$NONGIT_A', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 's', '$NONGIT_B', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
SQL
OUT=$("$CLI" report --by cwd 2>&1)
misc_count=$(echo "$OUT" | grep -cE '^  misc')
if [ "$misc_count" = "1" ]; then
    check "auto-alias: multiple non-git cwds aggregate into single 'misc' row" pass
else
    check "auto-alias: misc aggregation" fail "misc_count=$misc_count"
fi

# ── 22. Precedence: explicit project_names wins over auto-derived basename ──
# REPO_DIR's auto-alias would be "my-test-project"; with explicit, it becomes "explicit-name".
cat > "$TMPDIR/config.json" <<JSON
{"project_names": {"explicit-name": ["$REPO_DIR"]}}
JSON
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS, 's', '$REPO_DIR', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
SQL
OUT=$("$CLI" report --by cwd 2>&1)
has_explicit=$(echo "$OUT" | grep -cE '^  explicit-name')
no_auto=$(echo "$OUT" | grep -cE '^  my-test-project')
if [ "$has_explicit" = "1" ] && [ "$no_auto" = "0" ]; then
    check "precedence: explicit project_names wins over auto-derived basename" pass
else
    check "precedence: explicit wins" fail "explicit=$has_explicit auto_leak=$no_auto"
fi
rm -f "$TMPDIR/config.json"

# ── 23. --by cwd: header has 'total' as rightmost token ────────────────
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         's', '/foo', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 's', '/foo', 'PreToolUse',  'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+5100)),'s', '/foo', 'PostToolUse', 'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+200)), 's', '/bar', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+300)), 's', '/bar', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t2"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+800)), 's', '/bar', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t2"}');
SQL
cat > "$TMPDIR/config.json" <<'JSON'
{"project_names": {"foo-alias": ["/foo"], "bar-alias": ["/bar"]}}
JSON

OUT=$("$CLI" report --by cwd 2>&1)
HEADER=$(echo "$OUT" | grep -E '^  cwd ' | head -1)
if echo "$HEADER" | grep -qE 'total$'; then
    check "--by cwd: header has 'total' as rightmost token" pass
else
    check "--by cwd: header rightmost token is 'total'" fail "header='$HEADER'"
fi

# ── 24. --by cwd: each data row has 6 metric cells (was 5) ─────────────
foo_metrics=$(echo "$OUT" | grep -E '^  foo-alias' | awk '{print NF-1}')
bar_metrics=$(echo "$OUT" | grep -E '^  bar-alias' | awk '{print NF-1}')
total_metrics=$(echo "$OUT" | grep -E '^  TOTAL' | awk '{print NF-1}')
if [ "$foo_metrics" = "6" ] && [ "$bar_metrics" = "6" ] && [ "$total_metrics" = "6" ]; then
    check "--by cwd: each data row + TOTAL row has 6 metric cells" pass
else
    check "--by cwd: data row metric-cell count" fail "foo=$foo_metrics bar=$bar_metrics TOTAL=$total_metrics (expect 6 each)"
fi
rm -f "$TMPDIR/config.json"

# ── 25. --by cwd: grand-total cell math cross-checks (integer-ms) ──────
# Use the reclassify module directly to compute totals at integer-ms; assert that
# sum(column totals) == sum(per-row totals). This is what render_grouped's
# grand_total cell value should equal. Bypasses fmt_ms display lossiness.
sqlite3 "$DB" <<SQL
DELETE FROM events;
INSERT INTO events VALUES ($TODAY_NOON_MS,         's', '/foo', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+100)), 's', '/foo', 'PreToolUse',  'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+5100)),'s', '/foo', 'PostToolUse', 'Bash', NULL, '{"tool_use_id":"t1"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+200)), 's', '/bar', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":0}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+300)), 's', '/bar', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t2"}');
INSERT INTO events VALUES ($((TODAY_NOON_MS+800)), 's', '/bar', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t2"}');
SQL

CROSSCHECK=$(REPO_ROOT="$REPO_ROOT" DB="$DB" python3 <<'PY'
import os, sqlite3, sys
sys.path.insert(0, os.path.join(os.environ["REPO_ROOT"], "tools/claude-time"))
import reclassify

conn = sqlite3.connect(os.environ["DB"])
conn.row_factory = sqlite3.Row
events = [dict(r) for r in conn.execute("SELECT * FROM events ORDER BY ts")]
conn.close()

groups = {}
for ev in events:
    groups.setdefault(ev["cwd"], []).append(ev)

rows = []
for sub in groups.values():
    tool = sum(reclassify.tool_durations_ms(sub).values())
    active = sum(reclassify.session_active_ms(sub).values())
    gaps = reclassify.gap_buckets(sub, chars_per_sec=6.0,
                                  reading_threshold_sec=120, thinking_threshold_sec=300)
    reading  = sum(g.effective_ms for g in gaps if g.bucket=="reading")
    thinking = sum(g.effective_ms for g in gaps if g.bucket=="thinking")
    away     = sum(g.effective_ms for g in gaps if g.bucket=="away")
    rows.append((tool, active, reading, thinking, away))

sum_of_per_row_totals = sum(sum(r) for r in rows)
col_totals = [sum(r[i] for r in rows) for i in range(5)]
sum_of_col_totals = sum(col_totals)

if sum_of_per_row_totals == sum_of_col_totals:
    print(f"ok:{sum_of_col_totals}")
else:
    print(f"mismatch:rows={sum_of_per_row_totals}:cols={sum_of_col_totals}")
PY
)

if echo "$CROSSCHECK" | grep -q '^ok:'; then
    check "--by cwd: grand-total math cross-check (sum cols == sum rows, integer-ms)" pass
else
    check "--by cwd: grand-total math cross-check" fail "$CROSSCHECK"
fi

# ── 26. --by cwd --date 1970-01-01: empty-window message still works ───
# (Regression guard — total-col change must not break the early-return path.)
OUT=$("$CLI" report --by cwd --date 1970-01-01 2>&1)
rc=$?
no_total_col=$(echo "$OUT" | grep -cE 'total$' || true)
if [ $rc -eq 0 ] && echo "$OUT" | grep -q '(no events in window' && [ "$no_total_col" = "0" ]; then
    check "--by + empty-window: empty message preserved, no table rendered" pass
else
    check "--by + empty-window" fail "rc=$rc, out='$OUT', total_col_leak=$no_total_col"
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
