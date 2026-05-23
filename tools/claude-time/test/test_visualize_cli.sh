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

# ── 1. --help exits 0 and lists the original 5 visualize flags ─────────
OUT=$("$CLI" visualize --help 2>&1)
rc=$?
flag_count=$(echo "$OUT" | grep -cE '^\s+--(date|week|demo|no-open|out)\b')
if [ $rc -eq 0 ] && [ "$flag_count" = "5" ]; then
    check "visualize --help exits 0, lists 5 original flags" pass
else
    check "visualize --help exits 0, lists 5 original flags" fail "rc=$rc, flags=$flag_count"
fi

# ── 1b. WP5b: --help lists the two new context-days flags + updated --demo text ──
# Note: argparse wraps long help-strings at terminal width; flatten newlines before
# matching the demo-text phrase so the assertion is wrap-tolerant.
new_flag_count=$(echo "$OUT" | grep -cE '^\s+--context-days-(prior|after)\b')
demo_text_flat=$(echo "$OUT" | tr '\n' ' ' | tr -s ' ')
if [ $rc -eq 0 ] && [ "$new_flag_count" = "2" ] && \
   echo "$demo_text_flat" | grep -q 'forces context-days-prior/after to 0'; then
    check "WP5b: --help lists --context-days-prior + --context-days-after, --demo text updated" pass
else
    check "WP5b: --help new flags + demo text" fail "rc=$rc, new_flags=$new_flag_count, demo_text_match=fail"
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

# ── 9. --date flag ⇒ emitted CT_DATA.today.target_iso matches (WP5b) ──
# Pre-WP5b: assertion checked `"iso": "1970-01-01"` on the single-day shape.
# WP5b changed the default Day payload to multi-day (prior=14, after=7) where
# the user-requested day is surfaced as `target_iso` (renderer-centering pointer).
"$CLI" visualize --no-open --date 1970-01-01 --out "$TMPDIR/v-old.html" > /dev/null 2>&1
if [ -f "$TMPDIR/v-old.html" ] && grep -q '"target_iso": "1970-01-01"' "$TMPDIR/v-old.html"; then
    check "--date 1970-01-01 sets CT_DATA.today.target_iso accordingly" pass
else
    check "--date 1970-01-01" fail "target_iso field missing or wrong"
fi

# ── 9b. --date with --context-days-prior=0 --context-days-after=0 keeps single-day shape (back-compat) ──
"$CLI" visualize --no-open --date 1970-01-01 --context-days-prior 0 --context-days-after 0 \
       --out "$TMPDIR/v-single.html" > /dev/null 2>&1
if [ -f "$TMPDIR/v-single.html" ] && grep -q '"iso": "1970-01-01"' "$TMPDIR/v-single.html"; then
    check "WP5b: --context-days 0/0 keeps single-day back-compat shape (iso present)" pass
else
    check "WP5b: --context-days 0/0 keeps single-day shape" fail "iso field missing or wrong"
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
# WP5b: default Day payload is multi-day (prior=14, after=7). The per-day
# adaptive hour_range is now surfaced under `hour_range_by_day["2026-05-01"]`,
# not the top-level `hour_range`. Use --context-days 0/0 to assert the
# single-day back-compat shape's flat `hour_range` field too.
CLAUDE_TIME_DIR="$ADAPT_DIR" "$CLI" visualize --no-open --date 2026-05-01 --out "$ADAPT_OUT" > /dev/null 2>&1
adapt_rc=$?
if [ $adapt_rc -eq 0 ] && [ -f "$ADAPT_OUT" ] && \
   grep -q '"2026-05-01": \[13, 16\]' "$ADAPT_OUT"; then
    check "adaptive hour-ruler: narrow-event-window emits hour_range_by_day [13,16]" pass
else
    check "adaptive hour-ruler narrow-window (multi-day shape)" fail "rc=$adapt_rc, hour_range_by_day pattern not found"
fi

# ── 14b. WP5b single-day path: flat hour_range still emitted (back-compat) ──
ADAPT_OUT_SINGLE="$ADAPT_DIR/adaptive-single.html"
CLAUDE_TIME_DIR="$ADAPT_DIR" "$CLI" visualize --no-open --date 2026-05-01 \
    --context-days-prior 0 --context-days-after 0 --out "$ADAPT_OUT_SINGLE" > /dev/null 2>&1
adapt_single_rc=$?
if [ $adapt_single_rc -eq 0 ] && [ -f "$ADAPT_OUT_SINGLE" ] && \
   grep -q '"hour_range": \[13, 16\]' "$ADAPT_OUT_SINGLE"; then
    check "WP5b single-day path: flat hour_range [13,16] preserved" pass
else
    check "WP5b single-day hour_range" fail "rc=$adapt_single_rc, flat hour_range missing"
fi

# ── 13. WP2: NOW marker is client-side (no hardcoded values, has Date.now + cleanup) ─
# Codifies the WP2 contract: the emit-time NOW marker constant + label were
# removed; the dashboard derives NOW from the system clock client-side; the
# useNowMin hook installs a setInterval cleanup; the data payload carries a
# meta.snapshot field that the toolbar caption renders.
if grep -q 'NOW_MIN = 17 \* 60 + 22' "$OUT_HTML"; then
    check "WP2: emitted HTML lacks v1 hardcoded NOW_MIN constant" fail "found 'NOW_MIN = 17 * 60 + 22' in $OUT_HTML"
else
    check "WP2: emitted HTML lacks v1 hardcoded NOW_MIN constant" pass
fi

if grep -q 'NOW · 17:22' "$OUT_HTML"; then
    check "WP2: emitted HTML lacks v1 hardcoded 'NOW · 17:22' label" fail "found 'NOW · 17:22' in $OUT_HTML"
else
    check "WP2: emitted HTML lacks v1 hardcoded 'NOW · 17:22' label" pass
fi

if grep -qE 'Date\.now\(\)|new Date\(' "$OUT_HTML"; then
    check "WP2: emitted HTML contains client-side timestamp source (Date.now() or new Date(...))" pass
else
    check "WP2: emitted HTML contains client-side timestamp source" fail "no Date.now()/new Date( in $OUT_HTML"
fi

if grep -q '"snapshot"' "$OUT_HTML"; then
    check "WP2: emitted JSON payload contains \"snapshot\" key (meta.snapshot)" pass
else
    check "WP2: emitted JSON payload contains \"snapshot\" key" fail "no \"snapshot\" key in $OUT_HTML"
fi

if grep -q 'clearInterval' "$OUT_HTML"; then
    check "WP2: emitted HTML contains clearInterval (useNowMin cleanup)" pass
else
    check "WP2: emitted HTML contains clearInterval cleanup" fail "no clearInterval in $OUT_HTML"
fi

# ── 15. WP5 Phase 1: viewport state machine + pixel math source shapes ────
# Codifies the WP5 Phase 1 contract: the dashboard exposes a useViewport
# custom hook (consumed by every segment renderer), a viewportPct(start,end,
# viewport) helper that replaces the legacy module-level DAY_*-bound pct(),
# a hoursInViewport(viewport) helper for the (still-1h) ruler tick generator,
# and ViewportContext.Provider plumbing in the interactive Dashboard wrapper.
# Phase 2 (gestures) and Phase 3 (URL hash) will assert against more.
if grep -q 'function useViewport(' "$OUT_HTML"; then
    check "WP5-P1: emitted HTML defines useViewport hook" pass
else
    check "WP5-P1: emitted HTML defines useViewport hook" fail "no 'function useViewport(' in $OUT_HTML"
fi

if grep -q 'function viewportPct(' "$OUT_HTML"; then
    check "WP5-P1: emitted HTML defines viewportPct helper" pass
else
    check "WP5-P1: emitted HTML defines viewportPct helper" fail "no 'function viewportPct(' in $OUT_HTML"
fi

if grep -q 'visible_start_min' "$OUT_HTML" && grep -q 'visible_end_min' "$OUT_HTML"; then
    check "WP5-P1: viewport state shape (visible_start_min + visible_end_min) present" pass
else
    check "WP5-P1: viewport state shape present" fail "visible_start_min/visible_end_min missing in $OUT_HTML"
fi

if grep -q 'function hoursInViewport(' "$OUT_HTML"; then
    check "WP5-P1: emitted HTML defines hoursInViewport helper" pass
else
    check "WP5-P1: emitted HTML defines hoursInViewport helper" fail "no 'function hoursInViewport(' in $OUT_HTML"
fi

if grep -q 'ViewportContext' "$OUT_HTML"; then
    check "WP5-P1: emitted HTML defines ViewportContext (provider plumbing)" pass
else
    check "WP5-P1: emitted HTML defines ViewportContext" fail "no 'ViewportContext' in $OUT_HTML"
fi

# Legacy module-level DAY_RANGE_MIN/DAY_START_MIN/DAY_END_MIN are removed
# from the segment-positioning path. They MAY still appear in comments or
# the _initialViewport() helper, but no `const DAY_RANGE_MIN =` statement
# should remain at module level. (Strict grep on the exact assignment form.)
if grep -qE '^const DAY_RANGE_MIN\s*=' "$OUT_HTML"; then
    check "WP5-P1: legacy module-level 'const DAY_RANGE_MIN =' removed from segment-positioning path" fail "still found in $OUT_HTML"
else
    check "WP5-P1: legacy module-level 'const DAY_RANGE_MIN =' removed" pass
fi

# WP5-P1 codify hardening (added 2026-05-22 after a Phase 3 verify-human
# regression where InterruptHairlines still referenced the deleted
# DAY_START_MIN/DAY_END_MIN/DAY_RANGE_MIN identifiers and threw at runtime).
# Assert no remaining JS-reference shape exists for these identifiers
# (matches identifier usage; tolerates one-off occurrences in comments).
# Specifically: grep for the identifiers followed by NOT-comment-context.
# Heuristic: any line that contains the identifier AND is not a pure comment
# line (doesn't start with `//` or `*` after leading whitespace).
day_const_refs=$(grep -nE '\b(DAY_START_MIN|DAY_END_MIN|DAY_RANGE_MIN)\b' "$OUT_HTML" \
    | grep -vE '^\s*[0-9]+:\s*(//|\*|--)' \
    | wc -l | tr -d ' ')
if [ "$day_const_refs" = "0" ]; then
    check "WP5-P1 codify-hardening: no live JS refs to deleted DAY_*_MIN constants (comment-only refs tolerated)" pass
else
    check "WP5-P1 codify-hardening: no live JS refs to deleted DAY_*_MIN constants" fail "$day_const_refs ref(s) found in $OUT_HTML"
fi

# ── 15b. WP5 Phase 1 verify-codify gaps (3 additional assertions) ─────
# These assertions codify behaviors approved at verify-human that the P1.7
# assertions only confirmed structurally (definition-of-symbol) rather than
# consumption-of-symbol. Each gap was identified at verify-codify time.

# Gap 1 was attempted as a "17 HH:00 labels present in emitted HTML"
# assertion but found, at verify-codify triage time, to be unverifiable at
# the CLI level — labels are produced by a JSX template literal that only
# runs after Babel-standalone executes in the browser. Moved to Phase 4
# Playwright behavioral test (`test_visualize_interactive.sh`) where the
# rendered DOM is observable. Triage record in the WIP file under
# `## Test Triage — WP5-P1 codify "all 17 expected HH:00 ruler labels"`.

# Gap 2: --week view still mounts cleanly after Phase 1's wrapper-level
# ViewportContext.Provider wrap. The week path doesn't use viewport math,
# but it lives inside the same Dashboard tree that's now wrapped in the
# Provider. Assert both the Dashboard mount marker AND the ViewportContext
# presence in the --week-emitted HTML — i.e., wrapper integrity survives
# regardless of which view is initially selected.
WEEK_HTML="$TMPDIR/v-week.html"
if [ -f "$WEEK_HTML" ] && \
   grep -q 'function Dashboard(' "$WEEK_HTML" && \
   grep -q 'ViewportContext' "$WEEK_HTML"; then
    check "WP5-P1 codify: --week view emits Dashboard + ViewportContext (wrapper integrity)" pass
else
    check "WP5-P1 codify: --week view wrapper integrity" fail "Dashboard or ViewportContext missing in $WEEK_HTML"
fi

# ── 15c. WP5 Phase 2: pan + zoom gestures + adaptive ruler density ──
# Codifies the Phase 2 contract: pan via onMouseDown/onMouseMove (gutter-
# excluded), zoom via onWheel with cmd/ctrl + cursor-anchor math, keyboard
# shortcuts (arrows, +/-/0, Home/End), all rAF-throttled. Adaptive ruler
# tick density via pickTickInterval. Plus the SURFACE-2026-05-19 NOW-label
# cosmetic fold-in (P2.7 opportunistic).
if grep -q 'function useTimelineGestures(' "$OUT_HTML"; then
    check "WP5-P2: emitted HTML defines useTimelineGestures hook" pass
else
    check "WP5-P2: emitted HTML defines useTimelineGestures hook" fail "no 'function useTimelineGestures(' in $OUT_HTML"
fi

if grep -q 'requestAnimationFrame' "$OUT_HTML"; then
    check "WP5-P2: emitted HTML contains requestAnimationFrame (rAF throttling)" pass
else
    check "WP5-P2: emitted HTML contains requestAnimationFrame" fail "no 'requestAnimationFrame' in $OUT_HTML"
fi

if grep -q 'onMouseDown=' "$OUT_HTML" && grep -q 'onWheel=' "$OUT_HTML"; then
    check "WP5-P2: emitted HTML wires onMouseDown + onWheel handlers on the timeline surface" pass
else
    check "WP5-P2: pan + wheel handlers wired" fail "onMouseDown or onWheel missing in $OUT_HTML"
fi

if grep -q "'ArrowLeft'" "$OUT_HTML" && grep -q "'ArrowRight'" "$OUT_HTML" && grep -q "'Home'" "$OUT_HTML" && grep -q "'End'" "$OUT_HTML"; then
    check "WP5-P2: keyboard shortcuts wired (ArrowLeft, ArrowRight, Home, End)" pass
else
    check "WP5-P2: keyboard shortcuts wired" fail "one of ArrowLeft/ArrowRight/Home/End missing in $OUT_HTML"
fi

if grep -q 'function pickTickInterval(' "$OUT_HTML" && grep -q 'function ticksInViewport(' "$OUT_HTML"; then
    check "WP5-P2: adaptive ruler density helpers (pickTickInterval + ticksInViewport) defined" pass
else
    check "WP5-P2: adaptive ruler density helpers defined" fail "pickTickInterval or ticksInViewport missing in $OUT_HTML"
fi

# P2.7 opportunistic: NOW-label flips left when within (intervalMin - 10)..
# intervalMin of a tick boundary. Confirms the SURFACE-2026-05-19 cosmetic
# was folded in during the HourRuler refactor.
if grep -q 'flipNowLeft' "$OUT_HTML"; then
    check "WP5-P2.7: NOW-label overlap fix folded into HourRuler (flipNowLeft branch)" pass
else
    check "WP5-P2.7: NOW-label overlap fix" fail "no 'flipNowLeft' branch in $OUT_HTML"
fi

# ── 15d. WP5 Phase 3: Minimap + URL-hash state + convention codification ──
# Codifies the Phase 3 contract: Minimap component (single combined low-
# density track, ~80px tall, draggable visible-window rectangle); URL-hash
# read/write via parseHash/updateHash/serializeHash helpers; default-elision
# (viewport key omitted when equal to default); CLAUDE.md carries the
# URL-hash state convention with one-line examples per downstream WP slot.

if grep -q 'function Minimap(' "$OUT_HTML"; then
    check "WP5-P3: emitted HTML defines Minimap component" pass
else
    check "WP5-P3: emitted HTML defines Minimap component" fail "no 'function Minimap(' in $OUT_HTML"
fi

if grep -q 'data-minimap-mode' "$OUT_HTML"; then
    check "WP5-P3: Minimap visible-window rectangle has drag/resize affordances (data-minimap-mode)" pass
else
    check "WP5-P3: Minimap drag/resize affordances" fail "no 'data-minimap-mode' attribute in $OUT_HTML"
fi

if grep -q 'function parseHash(' "$OUT_HTML" && grep -q 'function updateHash(' "$OUT_HTML" && grep -q 'function serializeHash(' "$OUT_HTML"; then
    check "WP5-P3: URL-hash helpers (parseHash + updateHash + serializeHash) defined" pass
else
    check "WP5-P3: URL-hash helpers defined" fail "one of parseHash/updateHash/serializeHash missing in $OUT_HTML"
fi

if grep -q 'history.replaceState' "$OUT_HTML"; then
    check "WP5-P3: URL-hash write uses history.replaceState (not pushState)" pass
else
    check "WP5-P3: URL-hash uses replaceState" fail "no 'history.replaceState' in $OUT_HTML"
fi

if grep -q 'window\.location\.hash' "$OUT_HTML"; then
    check "WP5-P3: URL-hash read references window.location.hash" pass
else
    check "WP5-P3: URL-hash read" fail "no 'window.location.hash' in $OUT_HTML"
fi

# CLAUDE.md convention codification: the new section must be present at
# project root with the canonical heading + table of key reservations.
REPO_CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
if [ -f "$REPO_CLAUDE_MD" ] && grep -q '^## Claude-time visualize URL-hash state' "$REPO_CLAUDE_MD"; then
    check "WP5-P3: CLAUDE.md contains 'Claude-time visualize URL-hash state' convention section" pass
else
    check "WP5-P3: CLAUDE.md convention section" fail "missing heading in $REPO_CLAUDE_MD"
fi

if [ -f "$REPO_CLAUDE_MD" ] && grep -q 'Per-consumer key reservations' "$REPO_CLAUDE_MD"; then
    check "WP5-P3: CLAUDE.md convention has per-consumer key reservations table" pass
else
    check "WP5-P3: CLAUDE.md per-consumer key reservations" fail "missing key reservations subsection in $REPO_CLAUDE_MD"
fi

# Gap 3: SegmentBar (or any consumer) actually *calls* viewportPct — the
# P1.7 assertions confirmed the function is defined but not that anyone
# consumes it. A dead-but-defined helper would pass P1.7 but break the
# day view. Assert the emitted JS contains at least one call like
# `viewportPct(seg.start` (the SegmentBar invocation pattern).
# WP5b loosened the pattern: SegmentBar now calls
#   `viewportPct(seg.start + dayOffset, seg.end + dayOffset, viewport)`
# so the seg.end anchor is no longer adjacent. Match `viewportPct(seg.start`
# only; that's still distinctive of the SegmentBar call site.
if grep -q 'viewportPct(seg\.start' "$OUT_HTML"; then
    check "WP5-P1 codify: viewportPct is consumed by a segment renderer (not dead code)" pass
else
    check "WP5-P1 codify: viewportPct is consumed" fail "no 'viewportPct(seg.start' call site found in $OUT_HTML"
fi

# ── 16. Re-running visualize overwrites in place (no archive) ─────────
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

# ── WP5b codify: config-file path exercises viz_context_days_prior/after ──
WP5B_DIR="$(mktemp -d -t claude-time-wp5b-codify-XXXXXX)"
WP5B_DB="$WP5B_DIR/events.sqlite"
# Seed 5 days (2026-05-20 .. 2026-05-24), one UPS+Stop per day at 12:00 local.
sqlite3 "$WP5B_DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
SQL
for OFF in -2 -1 0 1 2; do
    DAY_MS=$(python3 -c "
from datetime import date, datetime, time, timedelta
d = date(2026, 5, 22) + timedelta(days=$OFF)
print(int(datetime.combine(d, time(12, 0)).timestamp() * 1000))
")
    DAY_ISO=$(python3 -c "
from datetime import date, timedelta
print((date(2026, 5, 22) + timedelta(days=$OFF)).isoformat())
")
    STOP_MS=$((DAY_MS + 1800000))
    sqlite3 "$WP5B_DB" "INSERT INTO events VALUES ($DAY_MS, 'sid-$DAY_ISO', '/repo/p', 'UserPromptSubmit', NULL, NULL, '{\"prompt_length_chars\":5}'), ($STOP_MS, 'sid-$DAY_ISO', '/repo/p', 'Stop', NULL, NULL, NULL);"
done

# WP5b-1: config.json prior=3 after=1 → day_count=5; CLI no-flag uses config.
printf '{"viz_context_days_prior": 3, "viz_context_days_after": 1}' > "$WP5B_DIR/config.json"
WP5B_OUT="$WP5B_DIR/cfg.html"
CLAUDE_TIME_DIR="$WP5B_DIR" "$CLI" visualize --no-open --date 2026-05-22 --out "$WP5B_OUT" > /dev/null 2>&1
cfg_rc=$?
if [ $cfg_rc -eq 0 ] && [ -f "$WP5B_OUT" ] && \
   grep -q '"day_count": 5' "$WP5B_OUT" && \
   grep -q '"target_iso": "2026-05-22"' "$WP5B_OUT"; then
    check "WP5b codify: config.json viz_context_days_prior/after applied (day_count=5)" pass
else
    check "WP5b codify: config.json applied" fail "rc=$cfg_rc, day_count or target_iso not found"
fi

# WP5b-2: CLI flag overrides config (0/0 forces single-day back-compat).
WP5B_OUT2="$WP5B_DIR/override.html"
CLAUDE_TIME_DIR="$WP5B_DIR" "$CLI" visualize --no-open --date 2026-05-22 \
    --context-days-prior 0 --context-days-after 0 --out "$WP5B_OUT2" > /dev/null 2>&1
ovr_rc=$?
if [ $ovr_rc -eq 0 ] && [ -f "$WP5B_OUT2" ] && \
   grep -q '"iso": "2026-05-22"' "$WP5B_OUT2" && \
   ! grep -q '"target_iso"' "$WP5B_OUT2" && \
   ! grep -q '"day_count"' "$WP5B_OUT2"; then
    check "WP5b codify: --context-days 0/0 overrides config, single-day back-compat" pass
else
    check "WP5b codify: flag-overrides-config" fail "rc=$ovr_rc, shape mismatch"
fi

# WP5b-3: invalid config values silently fall back to defaults (14/7 = day_count 22).
# Seed all 22 days for a full real-data assertion.
for OFF in $(seq -14 7); do
    DAY_MS=$(python3 -c "
from datetime import date, datetime, time, timedelta
d = date(2026, 5, 22) + timedelta(days=$OFF)
print(int(datetime.combine(d, time(12, 0)).timestamp() * 1000))
")
    DAY_ISO=$(python3 -c "
from datetime import date, timedelta
print((date(2026, 5, 22) + timedelta(days=$OFF)).isoformat())
")
    STOP_MS=$((DAY_MS + 1800000))
    sqlite3 "$WP5B_DB" "INSERT OR IGNORE INTO events VALUES ($DAY_MS, 'sid-full-$DAY_ISO', '/repo/p', 'UserPromptSubmit', NULL, NULL, '{\"prompt_length_chars\":5}'), ($STOP_MS, 'sid-full-$DAY_ISO', '/repo/p', 'Stop', NULL, NULL, NULL);"
done
printf '{"viz_context_days_prior": -5, "viz_context_days_after": "seven"}' > "$WP5B_DIR/config.json"
WP5B_OUT3="$WP5B_DIR/bad.html"
CLAUDE_TIME_DIR="$WP5B_DIR" "$CLI" visualize --no-open --date 2026-05-22 --out "$WP5B_OUT3" > /dev/null 2>&1
bad_rc=$?
if [ $bad_rc -eq 0 ] && [ -f "$WP5B_OUT3" ] && grep -q '"day_count": 22' "$WP5B_OUT3"; then
    check "WP5b codify: invalid config values silently fall back to defaults (14/7)" pass
else
    check "WP5b codify: invalid-config-fallback" fail "rc=$bad_rc, day_count=22 not found"
fi

# WP5b-4: --demo path forces single-day even with explicit context-days flags.
WP5B_OUT4="$WP5B_DIR/demo.html"
CLAUDE_TIME_DIR="$WP5B_DIR" "$CLI" visualize --no-open --demo \
    --context-days-prior 5 --context-days-after 5 --out "$WP5B_OUT4" > /dev/null 2>&1
demo_rc=$?
if [ $demo_rc -eq 0 ] && [ -f "$WP5B_OUT4" ] && \
   ! grep -q '"target_iso"' "$WP5B_OUT4" && \
   ! grep -q '"day_count"' "$WP5B_OUT4"; then
    check "WP5b codify: --demo forces single-day even with explicit flags" pass
else
    check "WP5b codify: --demo-forces-single-day" fail "rc=$demo_rc, shape mismatch"
fi

# WP5b-5: integration boundary — Week payload still emitted, independent of Day's context-days.
# Multi-day Day window should NOT poison the Week payload's shape.
WP5B_OUT5="$WP5B_DIR/with-week.html"
CLAUDE_TIME_DIR="$WP5B_DIR" "$CLI" visualize --no-open --date 2026-05-22 --out "$WP5B_OUT5" > /dev/null 2>&1
week_rc=$?
# Week payload has its own "label" field per build_week_data; check both today + week shape coexist.
if [ $week_rc -eq 0 ] && [ -f "$WP5B_OUT5" ] && \
   grep -q '"week"' "$WP5B_OUT5" && \
   grep -q '"today"' "$WP5B_OUT5" && \
   grep -q '"target_iso"' "$WP5B_OUT5"; then
    check "WP5b codify: Week payload coexists with multi-day Day payload (no contamination)" pass
else
    check "WP5b codify: week-coexists" fail "rc=$week_rc, shape mismatch"
fi

# WP5b-6: integration boundary regression-pin — _cmd_visualize emits target_iso ONLY
# on multi-day (build_range_data) path, NOT on the single-day (build_day_data) path.
# This pins the "0/0 takes single-day code path" plan decision and prevents a future
# refactor from collapsing both paths into a single build_range_data call (which would
# emit target_iso even at day_count=1 — a downstream renderer back-compat hazard).
single_day_emits_target=$(grep -c '"target_iso"' "$WP5B_OUT2" || true)
multi_day_emits_target=$(grep -c '"target_iso"' "$WP5B_OUT5" || true)
if [ "$single_day_emits_target" = "0" ] && [ "$multi_day_emits_target" -ge "1" ]; then
    check "WP5b codify: target_iso emitted on multi-day only, not single-day (path-divergence pin)" pass
else
    check "WP5b codify: target_iso path-divergence" fail "single=$single_day_emits_target multi=$multi_day_emits_target"
fi

# ── Phase 2 codify: renderer multi-day support ───────────────────────
# These assertions are run against $WP5B_OUT5 (a real multi-day emission)
# so they exercise the actual end-to-end path: real DB → build_range_data
# → _cmd_visualize → viz_render.render_html → emitted HTML.

# WP5b-P2-1: dayOffsetMin helper is in the bundle (Phase 2 P2.1)
if grep -q 'function dayOffsetMin' "$WP5B_OUT5"; then
    check "WP5b-P2 codify: dayOffsetMin helper defined" pass
else
    check "WP5b-P2 codify: dayOffsetMin" fail "function not found in emitted HTML"
fi

# WP5b-P2-2: pickTickInterval scale set extended to include 1440 (day-level)
# Pin the literal scale array — if anyone trims it back to [60,30,...] the
# day-level ruler labels disappear at multi-day zoom-out.
if grep -q '\[1440, 360, 60, 30, 15, 10, 5, 1\]' "$WP5B_OUT5"; then
    check "WP5b-P2 codify: pickTickInterval scale set includes [1440, 360]" pass
else
    check "WP5b-P2 codify: scale set" fail "extended scale-set literal not found"
fi

# WP5b-P2-3: _formatDayLabel helper present (drives "MMM DD" ruler labels)
if grep -q 'function _formatDayLabel' "$WP5B_OUT5"; then
    check "WP5b-P2 codify: _formatDayLabel helper for MMM DD ruler labels" pass
else
    check "WP5b-P2 codify: _formatDayLabel" fail "function not found"
fi

# WP5b-P2-4: DataWindowContext is declared and provided.
if grep -q 'DataWindowContext = React\.createContext' "$WP5B_OUT5" && \
   grep -q 'DataWindowContext\.Provider' "$WP5B_OUT5"; then
    check "WP5b-P2 codify: DataWindowContext defined + provided" pass
else
    check "WP5b-P2 codify: DataWindowContext" fail "context decl or provider missing"
fi

# WP5b-P2-5: SegmentBar accepts dayOffset prop AND uses it in viewportPct.
# Pins the full Phase 2 SegmentBar shape — guards against a future edit that
# drops the prop (regressing to seg.start as minute-of-day in multi-day mode).
if grep -q 'function SegmentBar({ seg, selected = false, dayOffset = 0' "$WP5B_OUT5" && \
   grep -q 'viewportPct(seg\.start + dayOffset' "$WP5B_OUT5"; then
    check "WP5b-P2 codify: SegmentBar accepts + applies dayOffset prop" pass
else
    check "WP5b-P2 codify: SegmentBar dayOffset" fail "signature or usage missing"
fi

# WP5b-P2-6 (regression-pin for F9b fix #1): viz_render.py Dashboard wrapper
# must delegate to _initialViewport() (single source of truth) — not maintain
# its own duplicate single-day-only initializer. Pin the consolidation: the
# inner useState initializer should reference _initialViewport.
# (The pattern is `return _initialViewport();` in two places — useMemo + useState init.)
init_delegates=$(grep -c '_initialViewport()' "$WP5B_OUT5" || true)
if [ "$init_delegates" -ge "3" ]; then
    # 3 = 1 ViewportContext.createContext default + 2 wrapper delegations
    check "WP5b-P2 codify: viz_render wrapper delegates to _initialViewport (no double-path regression)" pass
else
    check "WP5b-P2 codify: viewport-init consolidation" fail "expected >=3 _initialViewport() call sites in bundle, found $init_delegates"
fi

# WP5b-P2-7 (regression-pin for F9b fix #2): SessionRow key uses day_iso when
# present so cross-day session aggregation doesn't produce duplicate React keys.
# Pin the key template literal — if it reverts to `key={s.id}` only, multi-day
# views will emit "Encountered two children with the same key" console errors.
if grep -q 'key={s\.day_iso ? `${s\.day_iso}:${s\.id}` : s\.id}' "$WP5B_OUT5"; then
    check "WP5b-P2 codify: SessionRow key uses day_iso (no duplicate-key regression)" pass
else
    check "WP5b-P2 codify: SessionRow key" fail "day_iso-aware key template missing"
fi

# WP5b-P2-8 (regression-pin for Phase 2 verify-human fix #3): Minimap.allSegs
# pre-shifts seg.start/end by dayOffsetMin so density bars distribute correctly
# across the multi-day window. Pin the pre-shift pattern — if it reverts to a
# plain flatMap, density bars bunch at the left of the minimap (the bug user
# caught at verify-human).
if grep -q 'seg\.start + off' "$WP5B_OUT5" && grep -q 'seg\.end + off' "$WP5B_OUT5"; then
    check "WP5b-P2 codify: Minimap pre-shifts segs by day-offset (no left-bunching regression)" pass
else
    check "WP5b-P2 codify: Minimap day-offset" fail "seg.start + off / seg.end + off pre-shift missing"
fi

# WP5b-P2-9: emitted HTML includes the day-window math — hour_range_by_day map
# is present and contains the target day's adaptive hour-range. Pins that the
# multi-day payload's per-day-adaptive ruler data survives the JSON serialize.
if grep -q '"hour_range_by_day"' "$WP5B_OUT5" && grep -q '"day_window"' "$WP5B_OUT5"; then
    check "WP5b-P2 codify: hour_range_by_day + day_window emitted in multi-day payload" pass
else
    check "WP5b-P2 codify: per-day hour ranges" fail "hour_range_by_day or day_window missing"
fi

# ── WP6 codify: "Today" → "Day" toolbar rename ───────────────────────
# WP6 renamed the user-visible toolbar tab from "Today" to "Day". The
# load-bearing edit lives in viz_render.py::InteractiveToolbar (the
# emit-time-appended shipped toolbar) — NOT in viz/dashboard.jsx::Toolbar
# (the design-canvas static prototype that viz_render.py strips at emit).
# The F9 back-loop during WP6 build caught this: editing the design-canvas
# Toolbar alone produces zero shipped-UI change. This assertion pins the
# correct file by grepping the emitted HTML for the shipped tabBtn form.
#
# Reuses $WP5B_OUT5 (multi-day emit from WP5b assertions) — InteractiveToolbar
# emit is invariant of the data window, so any existing emitted HTML works.
if grep -q "tabBtn('Day', 'day', view === 'day', true)" "$WP5B_OUT5"; then
    check "WP6 codify: InteractiveToolbar emits Day tab (shipped consuming surface)" pass
else
    check "WP6 codify: shipped Day tab" fail "Day tabBtn missing in emitted HTML"
fi

# Negative regression-pin: the OLD form must be absent. Catches the exact
# regression class the F9 back-loop revealed — accidentally editing only
# viz/dashboard.jsx (design-canvas, byte-pinned-historically) without
# propagating to viz_render.py::InteractiveToolbar (the actual shipped UI).
if grep -q "tabBtn('Today', 'day'," "$WP5B_OUT5"; then
    check "WP6 codify: no legacy Today tabBtn" fail "old tabBtn('Today',...) form still present"
else
    check "WP6 codify: no legacy Today tabBtn in shipped toolbar (regression-pin)" pass
fi

# Rename-scope decision pin: data-layer key window.CT_DATA.today preserved.
# WP6 chose to rename only UI-visible surfaces; the data-layer key stays
# as the stable contract WP5b's six consumers depend on. This is partially
# redundant with WP5b's existing "today"/"target_iso" assertions but pins
# the WP6 decision itself — if a future WP renames the data-layer key,
# this test fails as a deliberate forcing function to update WP6's WBS row.
if grep -q '"today"' "$WP5B_OUT5" && grep -q 'window.CT_DATA.today' "$WP5B_OUT5"; then
    check "WP6 codify: data-layer .today key preserved (rename-scope decision pin)" pass
else
    check "WP6 codify: data-layer .today key" fail "window.CT_DATA.today or \"today\": missing"
fi

rm -rf "$WP5B_DIR"

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
