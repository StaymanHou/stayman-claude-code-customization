#!/usr/bin/env bash
# End-to-end test for the `claude-time visualize` CLI subcommand.
#
# Codifies the integration-boundary surface — the consuming surface modified
# in Phase 3 of the claude-time-visualize feature. Asserts:
#   - Default invocation writes HTML + prints path, against seeded SQLite
#   - --no-open suppresses webbrowser.open (verified by --no-open not failing in headless env)
#   - --demo bypasses SQLite entirely (works without a DB present)
#   - --week sets initial-view state in the emitted HTML
#   - --date YYYY-MM-DD selects that day's data (verified via emitted JSON "iso" field)
#   - --out overrides the default output path
#   - --help exits 0 and lists all 5 visualize flags
#   - Emitted HTML structure: CDN script tags, window.CT_DATA literal, Dashboard function
#   - Emitted HTML is single-file (no external script src other than CDN libs)
#
# Runs against an isolated temp CLAUDE_TIME_DIR. Exits 0 on full pass.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CLI="$REPO_ROOT/tools/claude-time/claude-time"

TMPDIR="$(mktemp -d -t claude-time-viz-cli-test-XXXXXX)"
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

# Compute today's noon (local) in ms.
TODAY_NOON_MS=$(python3 -c "
from datetime import date, datetime, time
print(int(datetime.combine(date.today(), time(12, 0)).timestamp() * 1000))
")
TODAY_ISO=$(python3 -c "from datetime import date; print(date.today().isoformat())")

DB="$TMPDIR/events.sqlite"

# Seed a minimal events table with one session: UPS at noon, Stop at 12:30.
sqlite3 "$DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);

INSERT INTO events VALUES
  ($TODAY_NOON_MS,           'sid-1', '/repo/test-project', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars": 10}'),
  ($((TODAY_NOON_MS + 60000)),  'sid-1', '/repo/test-project', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 120000)), 'sid-1', '/repo/test-project', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 1800000)), 'sid-1', '/repo/test-project', 'Stop', NULL, NULL, NULL);
SQL

echo "claude-time visualize CLI end-to-end tests"
echo "  CLI: $CLI"
echo "  CLAUDE_TIME_DIR: $TMPDIR"
echo

# ── 1. --help exits 0 and lists the 5 visualize flags ─────────────────
OUT=$("$CLI" visualize --help 2>&1)
rc=$?
flag_count=$(echo "$OUT" | grep -cE '^\s+--(date|week|demo|no-open|out)\b')
if [ $rc -eq 0 ] && [ "$flag_count" = "5" ]; then
    check "visualize --help exits 0, lists 5 flags" pass
else
    check "visualize --help exits 0, lists 5 flags" fail "rc=$rc, flags=$flag_count"
fi

# ── 2. Default visualize against seeded DB writes file + prints path ──
OUT_HTML="$TMPDIR/visualize.html"
OUT=$("$CLI" visualize --no-open 2>&1)
rc=$?
if [ $rc -eq 0 ] && [ -f "$OUT_HTML" ] && echo "$OUT" | grep -q "$OUT_HTML"; then
    check "visualize (default) writes file + prints path" pass
else
    check "visualize (default) writes file + prints path" fail "rc=$rc, out='$OUT', file_exists=$([ -f "$OUT_HTML" ] && echo yes || echo no)"
fi

# ── 3. Emitted HTML contains CDN script tags for React / ReactDOM / Babel ──
if [ -f "$OUT_HTML" ]; then
    react_count=$(grep -c 'unpkg.com/react' "$OUT_HTML" || true)
    babel_count=$(grep -c 'unpkg.com/@babel/standalone' "$OUT_HTML" || true)
    if [ "$react_count" -ge 2 ] && [ "$babel_count" = "1" ]; then
        check "emitted HTML has React (≥2 refs: react + react-dom) + Babel CDN tags" pass
    else
        check "emitted HTML has CDN tags" fail "react=$react_count, babel=$babel_count"
    fi
fi

# ── 4. Emitted HTML inlines window.CT_DATA = ... ──────────────────────
if [ -f "$OUT_HTML" ] && grep -q 'window\.CT_DATA = {' "$OUT_HTML"; then
    check "emitted HTML inlines window.CT_DATA literal" pass
else
    check "emitted HTML inlines window.CT_DATA literal" fail "missing assignment"
fi

# ── 5. Emitted HTML defines the Dashboard component + mounts it ───────
if [ -f "$OUT_HTML" ] && \
   grep -q 'function Dashboard(' "$OUT_HTML" && \
   grep -q 'ReactDOM.createRoot' "$OUT_HTML"; then
    check "emitted HTML defines Dashboard + mounts via ReactDOM.createRoot" pass
else
    check "emitted HTML defines Dashboard + mounts" fail "missing function or mount"
fi

# ── 6. Emitted HTML is single-file (no external <script src=...> except CDN) ──
if [ -f "$OUT_HTML" ]; then
    # All <script src=> values must be CDN URLs (https://unpkg.com/...).
    bad_srcs=$(grep -oE '<script[^>]+src="[^"]+"' "$OUT_HTML" | grep -v 'unpkg.com' | wc -l | tr -d ' ')
    if [ "$bad_srcs" = "0" ]; then
        check "emitted HTML uses only CDN script srcs (single-file)" pass
    else
        check "emitted HTML uses only CDN script srcs" fail "$bad_srcs non-CDN srcs found"
    fi
fi

# ── 7. Default --week omitted ⇒ CT_INITIAL_VIEW is 'day' ──────────────
if [ -f "$OUT_HTML" ] && grep -q 'CT_INITIAL_VIEW = "day"' "$OUT_HTML"; then
    check "default invocation sets CT_INITIAL_VIEW=\"day\"" pass
else
    check "default CT_INITIAL_VIEW=\"day\"" fail "value not 'day'"
fi

# ── 8. --week flag ⇒ CT_INITIAL_VIEW is 'week' ────────────────────────
"$CLI" visualize --no-open --week --out "$TMPDIR/v-week.html" > /dev/null 2>&1
if [ -f "$TMPDIR/v-week.html" ] && grep -q 'CT_INITIAL_VIEW = "week"' "$TMPDIR/v-week.html"; then
    check "--week sets CT_INITIAL_VIEW=\"week\"" pass
else
    check "--week sets CT_INITIAL_VIEW=\"week\"" fail "value missing"
fi

# ── 9. --date flag ⇒ emitted CT_DATA.today.iso matches ────────────────
"$CLI" visualize --no-open --date 1970-01-01 --out "$TMPDIR/v-old.html" > /dev/null 2>&1
if [ -f "$TMPDIR/v-old.html" ] && grep -q '"iso": "1970-01-01"' "$TMPDIR/v-old.html"; then
    check "--date 1970-01-01 sets CT_DATA.today.iso accordingly" pass
else
    check "--date 1970-01-01" fail "iso field missing or wrong"
fi

# ── 10. --out flag writes to a custom path ────────────────────────────
CUSTOM_OUT="$TMPDIR/custom-name.html"
"$CLI" visualize --no-open --out "$CUSTOM_OUT" > /dev/null 2>&1
if [ -f "$CUSTOM_OUT" ]; then
    check "--out writes to custom path" pass
else
    check "--out writes to custom path" fail "file missing"
fi

# ── 11. --demo bypasses SQLite (works without a DB) ───────────────────
# Create a fresh CLAUDE_TIME_DIR with NO db.
DEMO_DIR="$(mktemp -d -t claude-time-demo-test-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$DEMO_DIR"' EXIT
CLAUDE_TIME_DIR="$DEMO_DIR" "$CLI" visualize --no-open --demo --out "$DEMO_DIR/demo.html" > /dev/null 2>&1
demo_rc=$?
if [ $demo_rc -eq 0 ] && [ -f "$DEMO_DIR/demo.html" ] && [ ! -f "$DEMO_DIR/events.sqlite" ]; then
    check "--demo works without a DB (bypasses SQLite)" pass
else
    check "--demo works without DB" fail "rc=$demo_rc, html_exists=$([ -f "$DEMO_DIR/demo.html" ] && echo yes || echo no), db_exists=$([ -f "$DEMO_DIR/events.sqlite" ] && echo yes || echo no)"
fi

# ── 12. visualize without DB AND without --demo ⇒ helpful error ────────
NO_DB_DIR="$(mktemp -d -t claude-time-nodb-test-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$DEMO_DIR" "$NO_DB_DIR"' EXIT
OUT=$(CLAUDE_TIME_DIR="$NO_DB_DIR" "$CLI" visualize --no-open --out "$NO_DB_DIR/x.html" 2>&1)
rc=$?
if [ $rc -ne 0 ] && echo "$OUT" | grep -qi "does not exist"; then
    check "no DB + no --demo: exits non-zero with helpful error" pass
else
    check "no DB + no --demo: helpful error" fail "rc=$rc, out='$OUT'"
fi

# ── 14. Adaptive hour-ruler reflects today.hour_range from data ───────
# Seed a DB with events confined to 14:00–15:00 on a fixed past date.
# Adaptive computation: viz_data._hour_range_for emits [min_hour-1, max_hour+1]
# clamped to [0,24] — events at 14:00–15:00 → hour_range = [13, 16].
# The emitted HTML's hour-ruler should reflect that range, not the default [6..22].
ADAPT_DIR="$(mktemp -d -t claude-time-adaptive-test-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$DEMO_DIR" "$NO_DB_DIR" "$ADAPT_DIR"' EXIT
ADAPT_DB="$ADAPT_DIR/events.sqlite"
# 2026-05-01 14:00 local → 2026-05-01 15:00 local. Compute via python.
ADAPT_UPS_MS=$(python3 -c "
from datetime import datetime
print(int(datetime(2026, 5, 1, 14, 0).timestamp() * 1000))
")
ADAPT_STOP_MS=$((ADAPT_UPS_MS + 3600000))  # +1h
sqlite3 "$ADAPT_DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
INSERT INTO events VALUES
  ($ADAPT_UPS_MS,   'sid-narrow', '/repo/narrow', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars":5}'),
  ($ADAPT_STOP_MS,  'sid-narrow', '/repo/narrow', 'Stop',             NULL, NULL, NULL);
SQL
ADAPT_OUT="$ADAPT_DIR/adaptive.html"
CLAUDE_TIME_DIR="$ADAPT_DIR" "$CLI" visualize --no-open --date 2026-05-01 --out "$ADAPT_OUT" > /dev/null 2>&1
adapt_rc=$?
if [ $adapt_rc -eq 0 ] && [ -f "$ADAPT_OUT" ] && \
   grep -q '"hour_range": \[13, 16\]' "$ADAPT_OUT"; then
    check "adaptive hour-ruler: narrow-event-window emits hour_range [13,16]" pass
else
    check "adaptive hour-ruler narrow-window" fail "rc=$adapt_rc, hour_range pattern not found"
fi

# ── 13. Re-running visualize overwrites in place (no archive) ─────────
"$CLI" visualize --no-open > /dev/null 2>&1
mtime1=$(stat -f '%m' "$OUT_HTML" 2>/dev/null || stat -c '%Y' "$OUT_HTML")
sleep 1
"$CLI" visualize --no-open > /dev/null 2>&1
mtime2=$(stat -f '%m' "$OUT_HTML" 2>/dev/null || stat -c '%Y' "$OUT_HTML")
file_count=$(ls "$TMPDIR" | grep -c '^visualize.*\.html$' || true)
if [ "$mtime1" != "$mtime2" ] && [ "$file_count" = "1" ]; then
    check "re-running overwrites in place (single file, mtime changes)" pass
else
    check "re-running overwrites in place" fail "mtime1=$mtime1 mtime2=$mtime2 file_count=$file_count"
fi

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== claude-time visualize CLI test summary ==="
echo "PASS: $pass | FAIL: $fail"
if [ $fail -eq 0 ]; then
    echo "All visualize CLI assertions hold."
    exit 0
else
    exit 1
fi
