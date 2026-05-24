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
# The regex anchors at "  --foo " (column 3 indent, flag name, then a space
# or end-of-help-arg). This avoids matching wrapped help-text continuation
# lines that mention sibling flag names mid-paragraph (WP8 hardening — the
# new --range flag's help text references --demo/--week/--date by name).
OUT=$("$CLI" visualize --help 2>&1)
rc=$?
flag_count=$(echo "$OUT" | grep -cE '^  --(date|week|demo|no-open|out)( |$)')
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

# ── WP9 Phase 1 codify: Toolbar duality collapsed ────────────────────
# WP9 Phase 1 (2026-05-23) collapsed the design-canvas/InteractiveToolbar
# duality: viz_render.py::InteractiveToolbar was deleted; its body moved into
# viz/dashboard.jsx::Toolbar. The shipped Dashboard wrapper now renders
# <Toolbar ...> directly. Regression-pin: the emitted HTML must contain
# exactly ONE Toolbar function definition AND ZERO InteractiveToolbar
# references. If a future WP accidentally re-introduces a second Toolbar
# (e.g. by appending one in viz_render.py), this assertion fails. This is
# the structural successor to the WP6 string-pin above — WP6 caught
# wrong-file edits via positive+negative tabBtn greps; WP9 catches the
# class of mistake entirely by pinning that there is only one Toolbar.
#
# Reuses $WP5B_OUT5 (any emit works — invariant is structural). Must run
# BEFORE rm -rf "$WP5B_DIR" below.
TOOLBAR_FN_COUNT=$(grep -c '^function Toolbar\b\|^function InteractiveToolbar\b' "$WP5B_OUT5")
if [ "$TOOLBAR_FN_COUNT" = "1" ]; then
    check "WP9-P1 codify: exactly one Toolbar function (duality collapsed)" pass
else
    check "WP9-P1 codify: Toolbar function count" fail "expected 1, got $TOOLBAR_FN_COUNT"
fi

if ! grep -q '<InteractiveToolbar\b' "$WP5B_OUT5"; then
    check "WP9-P1 codify: no <InteractiveToolbar> JSX usage (regression-pin)" pass
else
    check "WP9-P1 codify: no <InteractiveToolbar> usage" fail "InteractiveToolbar JSX still present"
fi

# ── WP9 Phase 2 codify: filter chip state machine + consuming-surface contract ──
# WP9 Phase 2 (2026-05-23) wired functional filter chips. Verify-self
# confirmed on a live Playwright session: 5 chips with data-filter-kind
# attrs, clicking toggles data-filter-on, segments with the toggled kind
# disappear from the DOM (read-out via [data-kind] querySelectorAll counts).
# Codify pins the *structural contract* that makes those behaviors testable:
#   - data-kind={seg.kind} on SegmentBar (Playwright selector)
#   - 5 data-filter-kind buttons emitted (one per kind)
#   - FilterContext + filterKinds state present (state machine wired)
# This is the consuming-surface assertion for the integration boundary:
# any regression in the emit path that breaks the filter UI would fail here
# rather than only surfacing at the next manual verify-human.
if grep -q 'data-kind={seg\.kind}' "$WP5B_OUT5"; then
    check "WP9-P2 codify: SegmentBar emits data-kind attribute (selector contract)" pass
else
    check "WP9-P2 codify: SegmentBar data-kind attribute" fail "data-kind={seg.kind} missing in emitted HTML"
fi

# The 5 filter chip kinds are listed in Legend's `items` array (inline in
# the JSX source). React's .map() expands this to 5 DOM buttons at runtime.
# Static emit assertion: each of the 5 kinds appears as a `kind: '<name>'`
# entry in the Legend items list. If a future edit drops one (e.g. removes
# "away" thinking it's redundant) the assertion fails. The corresponding
# runtime contract — that 5 [data-filter-kind] buttons render — is asserted
# by the verify-self Playwright subagent and would also be caught by any
# interactive-test add-on later.
LEGEND_KINDS_PASS=1
for kind in active reading thinking subagent away; do
    if ! grep -q "kind: '$kind'" "$WP5B_OUT5"; then
        LEGEND_KINDS_PASS=0
        break
    fi
done
if [ "$LEGEND_KINDS_PASS" = "1" ]; then
    check "WP9-P2 codify: Legend items list all 5 kinds (active/reading/thinking/subagent/away)" pass
else
    check "WP9-P2 codify: Legend kinds completeness" fail "one or more of [active, reading, thinking, subagent, away] missing from Legend items"
fi

if grep -q 'FilterContext' "$WP5B_OUT5" && grep -q 'filterKinds' "$WP5B_OUT5"; then
    check "WP9-P2 codify: FilterContext + filterKinds state machine present" pass
else
    check "WP9-P2 codify: filter state machine" fail "FilterContext or filterKinds missing in emitted HTML"
fi

# ── WP9 Phase 3 codify: URL-hash filters= contract (static-emit pins) ──
# Phase 3 wired hash-restore-on-init + hash-write-on-change for filter
# state, per the schema in CLAUDE.md → "Claude-time visualize URL-hash state".
# Behavioral coverage lives in test_visualize_interactive.js Outcome 9-11
# (container-only Playwright). These static pins catch emit-time wiring
# regression cheaply: if a future refactor accidentally drops the hash
# read/write plumbing from _interactive_dashboard, these fail without
# needing the container.
if grep -q 'hash\.filters' "$WP5B_OUT5"; then
    check "WP9-P3 codify: hash.filters read at init (restore)" pass
else
    check "WP9-P3 codify: hash.filters read" fail "no hash.filters reference in emitted HTML"
fi

if grep -q 'updateHash({ filters:' "$WP5B_OUT5"; then
    check "WP9-P3 codify: updateHash({ filters: ... }) writer present" pass
else
    check "WP9-P3 codify: updateHash filter write" fail "no updateHash({ filters: ...}) call in emitted HTML"
fi

# Default-elision pin: the write path must include the all-on → null branch.
if grep -q 'filters: null' "$WP5B_OUT5"; then
    check "WP9-P3 codify: default-elision branch (filters: null when all-on)" pass
else
    check "WP9-P3 codify: default-elision" fail "no 'filters: null' branch found"
fi

# Canonical-order const pin: the kinds array must be in active,reading,
# thinking,subagent,away order (matches Legend rendering, ensures hash
# determinism). If a future edit shuffles FILTER_KINDS, the hash format
# in shared links changes — this pin makes that intentional.
if grep -q "'active', 'reading', 'thinking', 'subagent', 'away'" "$WP5B_OUT5"; then
    check "WP9-P3 codify: FILTER_KINDS canonical order (active,reading,thinking,subagent,away)" pass
else
    check "WP9-P3 codify: canonical order" fail "FILTER_KINDS canonical order list not found"
fi

# ── WP9 Phase 4 codify: per-project filter popover (static-emit pins) ──
# Phase 4 added a ProjectFilterPopover next to Legend with a trigger button
# + floating panel + outside-click dismiss. Behavioral coverage lives in
# test_visualize_interactive.js Outcomes 12-13. These static pins catch
# emit-time wiring regression cheaply.
if grep -q 'function ProjectFilterPopover' "$WP5B_OUT5"; then
    check "WP9-P4 codify: ProjectFilterPopover component defined" pass
else
    check "WP9-P4 codify: ProjectFilterPopover defined" fail "function ProjectFilterPopover not in emit"
fi

if grep -q '<ProjectFilterPopover' "$WP5B_OUT5"; then
    check "WP9-P4 codify: ProjectFilterPopover rendered by Dashboard" pass
else
    check "WP9-P4 codify: ProjectFilterPopover usage" fail "no <ProjectFilterPopover ...> JSX usage in emit"
fi

if grep -q 'data-project-filter-trigger' "$WP5B_OUT5"; then
    check "WP9-P4 codify: data-project-filter-trigger attribute (popover trigger contract)" pass
else
    check "WP9-P4 codify: trigger attribute" fail "data-project-filter-trigger missing"
fi

if grep -q 'data-project-filter-item' "$WP5B_OUT5"; then
    check "WP9-P4 codify: data-project-filter-item attribute (per-project checkbox contract)" pass
else
    check "WP9-P4 codify: item attribute" fail "data-project-filter-item missing"
fi

# Outside-click dismiss pin: a document mousedown listener must be wired
# inside the popover's useEffect. If a future refactor drops the listener,
# popover would no longer dismiss on outside-click.
if grep -q "addEventListener('mousedown'" "$WP5B_OUT5"; then
    check "WP9-P4 codify: outside-click mousedown listener wired (dismiss contract)" pass
else
    check "WP9-P4 codify: outside-click listener" fail "no addEventListener('mousedown', ...) in emit"
fi

rm -rf "$WP5B_DIR"

# ── WP8 Phase 1 codify: --range flag + range-aware visualize emit ──────
# Codifies the 10 Phase 1 deliverables for Custom-range view (WP8). Builds
# its own isolated fixture (5-day multi-day seed + per-test config overrides)
# so it doesn't depend on $WP5B_DIR which was already cleaned up.

WP8_DIR="$(mktemp -d -t claude-time-wp8-codify-XXXXXX)"
WP8_DB="$WP8_DIR/events.sqlite"
sqlite3 "$WP8_DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
SQL
# Seed 3 days (2026-05-20 .. 2026-05-22), one UPS+Stop per day at noon.
# Picked safely in the past so end<=today rule never blocks the happy path.
for OFF in 0 1 2; do
    DAY_MS=$(python3 -c "
from datetime import date, datetime, time, timedelta
d = date(2026, 5, 20) + timedelta(days=$OFF)
print(int(datetime.combine(d, time(12, 0)).timestamp() * 1000))
")
    DAY_ISO=$(python3 -c "
from datetime import date, timedelta
print((date(2026, 5, 20) + timedelta(days=$OFF)).isoformat())
")
    STOP_MS=$((DAY_MS + 1800000))
    sqlite3 "$WP8_DB" "INSERT INTO events VALUES ($DAY_MS, 'sid-$DAY_ISO', '/repo/p', 'UserPromptSubmit', NULL, NULL, '{\"prompt_length_chars\":5}'), ($STOP_MS, 'sid-$DAY_ISO', '/repo/p', 'Stop', NULL, NULL, NULL);"
done

# WP8-1: --range flag appears in `visualize --help`.
HELP_OUT=$("$CLI" visualize --help 2>&1)
if echo "$HELP_OUT" | grep -qE '^  --range START:END'; then
    check "WP8-P1 codify: --help lists --range START:END flag" pass
else
    check "WP8-P1 codify: --range in --help" fail "flag not listed at column-3"
fi

# WP8-2a: happy path emits CT_INITIAL_VIEW="custom".
WP8_HAPPY="$WP8_DIR/happy.html"
CLAUDE_TIME_DIR="$WP8_DIR" "$CLI" visualize --no-open \
    --range 2026-05-20:2026-05-22 --out "$WP8_HAPPY" > /dev/null 2>&1
happy_rc=$?
if [ $happy_rc -eq 0 ] && [ -f "$WP8_HAPPY" ] && \
   grep -q 'CT_INITIAL_VIEW = "custom"' "$WP8_HAPPY"; then
    check "WP8-P1 codify: --range emits CT_INITIAL_VIEW=\"custom\"" pass
else
    check "WP8-P1 codify: --range emits CT_INITIAL_VIEW=\"custom\"" fail "rc=$happy_rc, value missing"
fi

# WP8-2b: emitted multi-day shape — meta.start + meta.end + meta.day_count = 3.
if grep -q '"start": "2026-05-20"' "$WP8_HAPPY" && \
   grep -q '"end": "2026-05-22"' "$WP8_HAPPY" && \
   grep -q '"day_count": 3' "$WP8_HAPPY"; then
    check "WP8-P1 codify: --range payload has meta.start/end/day_count" pass
else
    check "WP8-P1 codify: --range meta.start/end/day_count" fail "field(s) missing"
fi

# WP8-2c: range-shape vs single-day-shape distinction — --range payload uses
# hour_range_by_day (dict), NOT the single-day flat `hour_range` shape that
# build_day_data emits for the 0/0 back-compat case.
if grep -q '"hour_range_by_day"' "$WP8_HAPPY" && \
   ! grep -qE '"target_iso"' "$WP8_HAPPY"; then
    check "WP8-P1 codify: --range emits multi-day shape (hour_range_by_day; no target_iso)" pass
else
    check "WP8-P1 codify: --range multi-day shape" fail "shape contamination — target_iso must NOT appear in range mode"
fi

# WP8-3: default invocation (no --range, no --week) still emits CT_INITIAL_VIEW="day".
# Regression-pin: the --range path is opt-in, not a silent default change.
WP8_DEFAULT="$WP8_DIR/default.html"
TODAY_ISO=$(python3 -c "from datetime import date; print(date.today().isoformat())")
CLAUDE_TIME_DIR="$WP8_DIR" "$CLI" visualize --no-open \
    --date "$TODAY_ISO" --context-days-prior 0 --context-days-after 0 \
    --out "$WP8_DEFAULT" > /dev/null 2>&1
def_rc=$?
if [ $def_rc -eq 0 ] && [ -f "$WP8_DEFAULT" ] && \
   grep -q 'CT_INITIAL_VIEW = "day"' "$WP8_DEFAULT" && \
   ! grep -q 'CT_INITIAL_VIEW = "custom"' "$WP8_DEFAULT"; then
    check "WP8-P1 codify: --range is opt-in (no --range → CT_INITIAL_VIEW=\"day\")" pass
else
    check "WP8-P1 codify: --range opt-in regression-pin" fail "rc=$def_rc, default emit got 'custom'"
fi

# WP8-4: CT_MAX_RANGE_DAYS template injection — defaults to 90.
if grep -qE 'CT_MAX_RANGE_DAYS = 90\b' "$WP8_HAPPY"; then
    check "WP8-P1 codify: CT_MAX_RANGE_DAYS = 90 default injected" pass
else
    check "WP8-P1 codify: CT_MAX_RANGE_DAYS injection" fail "placeholder not replaced or wrong default"
fi

# WP8-5: validation — end<start fails with rc=2 + rule-named message.
err1=$("$CLI" visualize --no-open --range 2026-05-22:2026-05-20 --out "$WP8_DIR/v1.html" 2>&1)
rc1=$?
if [ $rc1 -eq 2 ] && echo "$err1" | grep -qE 'end >= start'; then
    check "WP8-P1 codify: validation — end<start exits 2, names rule" pass
else
    check "WP8-P1 codify: validation end<start" fail "rc=$rc1, msg=$err1"
fi

# WP8-6: validation — days>cap fails with rc=2 + names cap.
# Use a date safely in the past with 100+ days inside the WP8_DB-irrelevant range.
err2=$("$CLI" visualize --no-open --range 2026-01-01:2026-05-20 --out "$WP8_DIR/v2.html" 2>&1)
rc2=$?
if [ $rc2 -eq 2 ] && echo "$err2" | grep -qE 'viz_custom_range_max_days|cap'; then
    check "WP8-P1 codify: validation — days>cap exits 2, names cap" pass
else
    check "WP8-P1 codify: validation days>cap" fail "rc=$rc2, msg=$err2"
fi

# WP8-7: validation — end>today fails with rc=2 + names "future".
err3=$("$CLI" visualize --no-open --range 2026-05-20:2030-01-01 --out "$WP8_DIR/v3.html" 2>&1)
rc3=$?
if [ $rc3 -eq 2 ] && echo "$err3" | grep -qE 'future'; then
    check "WP8-P1 codify: validation — end>today exits 2, names 'future'" pass
else
    check "WP8-P1 codify: validation end>today" fail "rc=$rc3, msg=$err3"
fi

# WP8-8: validation — bad shape (no colon) fails with rc=2 + names grammar.
err4=$("$CLI" visualize --no-open --range 'not-a-range' --out "$WP8_DIR/v4.html" 2>&1)
rc4=$?
if [ $rc4 -eq 2 ] && echo "$err4" | grep -qE 'YYYY-MM-DD'; then
    check "WP8-P1 codify: validation — bad shape exits 2, names grammar" pass
else
    check "WP8-P1 codify: validation bad shape" fail "rc=$rc4, msg=$err4"
fi

# WP8-9: mutual exclusion — --range + --demo fails with rc=2 + names "demo".
err5=$("$CLI" visualize --no-open --range 2026-05-20:2026-05-22 --demo --out "$WP8_DIR/v5.html" 2>&1)
rc5=$?
if [ $rc5 -eq 2 ] && echo "$err5" | grep -qE 'demo'; then
    check "WP8-P1 codify: --range + --demo mutual exclusion (rc=2)" pass
else
    check "WP8-P1 codify: --range+--demo exclusion" fail "rc=$rc5, msg=$err5"
fi

# WP8-10: warning — --range + --context-days-prior emits stderr warning + exits 0.
# Subtler than the error cases — the warning is easy to lose silently in a refactor.
warn_out="$WP8_DIR/warn.html"
err6=$(CLAUDE_TIME_DIR="$WP8_DIR" "$CLI" visualize --no-open \
        --range 2026-05-20:2026-05-22 --context-days-prior 3 --out "$warn_out" 2>&1 >/dev/null)
rc6=$?
if [ $rc6 -eq 0 ] && [ -f "$warn_out" ] && \
   echo "$err6" | grep -qE 'warning.*ignored.*range mode'; then
    check "WP8-P1 codify: --range + --context-days-prior emits warning + exits 0" pass
else
    check "WP8-P1 codify: warning on combined flags" fail "rc=$rc6, msg=$err6"
fi

# WP8-11: config — viz_custom_range_max_days override validated through load_config.
# Set cap to 2 days; a 3-day range should now fail.
printf '{"viz_custom_range_max_days": 2}' > "$WP8_DIR/config.json"
err7=$(CLAUDE_TIME_DIR="$WP8_DIR" "$CLI" visualize --no-open \
        --range 2026-05-20:2026-05-22 --out "$WP8_DIR/v7.html" 2>&1)
rc7=$?
if [ $rc7 -eq 2 ] && echo "$err7" | grep -qE '3 days > 2'; then
    check "WP8-P1 codify: viz_custom_range_max_days config override applied" pass
else
    check "WP8-P1 codify: config cap override" fail "rc=$rc7, msg=$err7"
fi

# WP8-12: config — invalid value silently falls back to default 90.
printf '{"viz_custom_range_max_days": "not a number"}' > "$WP8_DIR/config.json"
WP8_BADCFG="$WP8_DIR/badcfg.html"
CLAUDE_TIME_DIR="$WP8_DIR" "$CLI" visualize --no-open \
    --range 2026-05-20:2026-05-22 --out "$WP8_BADCFG" > /dev/null 2>&1
badcfg_rc=$?
if [ $badcfg_rc -eq 0 ] && [ -f "$WP8_BADCFG" ] && \
   grep -qE 'CT_MAX_RANGE_DAYS = 90\b' "$WP8_BADCFG"; then
    check "WP8-P1 codify: invalid config value falls back to default 90" pass
else
    check "WP8-P1 codify: invalid-config fallback" fail "rc=$badcfg_rc, default not preserved"
fi
rm -f "$WP8_DIR/config.json"

# WP8-13: P1.disc.1 hardening lock-in — test #1's flag-count regex is
# anchored at column-3 (2 leading spaces) + space-or-EOL after flag name.
# This pin asserts the test file itself uses the hardened regex shape; a
# regression to the permissive `^\s+--(...)\b` form would re-introduce the
# false-match against wrapped help-text continuation lines. We grep for a
# byte-stable substring of the hardened pattern (column-3 anchor + non-greedy
# tail) — fixed-string match (-F) avoids regex-quoting hell on $.
TEST_FILE="$(dirname "$0")/test_visualize_cli.sh"
if grep -Fq '^  --(date|week|demo|no-open|out)( |$)' "$TEST_FILE"; then
    check "WP8-P1 codify: P1.disc.1 — flag-count regex hardened (column-3 + EOL)" pass
else
    check "WP8-P1 codify: P1.disc.1 regex hardening" fail "test file does not contain the hardened regex form"
fi

# ── WP8 Phase 2 codify: UI — Custom tab + date-range picker + URL-hash ──
# Static-emit pins against $WP8_HAPPY (same range-emitted HTML used by
# Phase 1 codify). Phase 2 adds 10 UI deliverables that ride on the data
# contract Phase 1 already pinned.

# WP8-P2-1: Custom toolbar tab enabled (was disabled pre-WP8).
if grep -qF "tabBtn('Custom', 'custom', view === 'custom', true)" "$WP8_HAPPY"; then
    check "WP8-P2 codify: Custom toolbar tab enabled (cursor=pointer)" pass
else
    check "WP8-P2 codify: Custom tab enabled" fail "tabBtn('Custom', 'custom', view === 'custom', true) not in emit"
fi
# Plus regression-pin against the pre-WP8 disabled form returning.
if ! grep -qF "tabBtn('Custom', 'custom', false, false)" "$WP8_HAPPY"; then
    check "WP8-P2 codify: no pre-WP8 disabled Custom tab form (regression-pin)" pass
else
    check "WP8-P2 codify: regression — disabled Custom tab" fail "pre-WP8 disabled form still in emit"
fi

# WP8-P2-2: RangePicker component defined + data-range-picker selectors.
if grep -qF 'function RangePicker(' "$WP8_HAPPY" && \
   grep -qF 'data-range-picker="start"' "$WP8_HAPPY" && \
   grep -qF 'data-range-picker="end"' "$WP8_HAPPY"; then
    check "WP8-P2 codify: RangePicker component + data-range-picker=start/end selectors" pass
else
    check "WP8-P2 codify: RangePicker component" fail "function or selector attrs missing"
fi

# WP8-P2-3: validateRange helper defined with the 4 rules.
# Each rule's stderr-style message is a substring we can grep for.
if grep -qF 'function validateRange(' "$WP8_HAPPY" && \
   grep -qF 'End date must be on or after start date' "$WP8_HAPPY" && \
   grep -qF 'End date must not be in the future' "$WP8_HAPPY" && \
   grep -qF 'Range too long' "$WP8_HAPPY" && \
   grep -qF 'Dates must be in YYYY-MM-DD form' "$WP8_HAPPY"; then
    check "WP8-P2 codify: validateRange helper with 4 client-side rule messages" pass
else
    check "WP8-P2 codify: validateRange helper" fail "function or rule strings missing"
fi

# WP8-P2-4: isCustom + isDayLike constants in the interactive Dashboard wrapper.
if grep -qF "const isCustom = view === 'custom'" "$WP8_HAPPY" && \
   grep -qF "const isDayLike = isDay || isCustom" "$WP8_HAPPY"; then
    check "WP8-P2 codify: isCustom + isDayLike constants in Dashboard wrapper" pass
else
    check "WP8-P2 codify: isCustom/isDayLike constants" fail "constants missing"
fi

# WP8-P2-5: Toolbar invocation passes range props + maxRangeDays from window.
if grep -qF 'rangeStart={range.start}' "$WP8_HAPPY" && \
   grep -qF 'rangeEnd={range.end}' "$WP8_HAPPY" && \
   grep -qF 'onRangeChange={onRangeChange}' "$WP8_HAPPY" && \
   grep -qF 'maxRangeDays={window.CT_MAX_RANGE_DAYS || 90}' "$WP8_HAPPY"; then
    check "WP8-P2 codify: Toolbar receives range props + maxRangeDays from window" pass
else
    check "WP8-P2 codify: Toolbar range props" fail "one or more props missing in wrapper"
fi

# WP8-P2-6: _initView IIFE with hash.view priority over CT_INITIAL_VIEW.
# The IIFE form `(() => { ... })()` + the substring 'CT_INITIAL_VIEW' inside it
# uniquely identifies the new precedence logic.
if grep -qF 'const _initView = (() => {' "$WP8_HAPPY" && \
   grep -qF "if (hash.view === 'custom'" "$WP8_HAPPY" && \
   grep -qF "window.CT_INITIAL_VIEW === 'custom'" "$WP8_HAPPY"; then
    check "WP8-P2 codify: _initView IIFE prefers hash.view over CT_INITIAL_VIEW" pass
else
    check "WP8-P2 codify: _initView IIFE" fail "init-view precedence logic not in emit"
fi

# WP8-P2-7: range state with hash-restore + validation fallback.
# Substring search for the useState initializer body's distinctive lines.
if grep -qF 'const [range, setRange] = React.useState(() => {' "$WP8_HAPPY" && \
   grep -qF 'if (hash.range &&' "$WP8_HAPPY" && \
   grep -qF 'validateRange(s, e, window.CT_MAX_RANGE_DAYS || 90) == null' "$WP8_HAPPY"; then
    check "WP8-P2 codify: range state hash-restore + validation fallback" pass
else
    check "WP8-P2 codify: range state hash-restore" fail "useState initializer not in emit"
fi

# WP8-P2-8 (extended by WP7-P2): Debounced view+range+month hash-write
# useEffect with FOUR-branch dispatch (day/week/custom/month). WP7 added
# the 'month' branch + threaded the `month` key through all four branches
# (set when view==='month', null otherwise per default-elision).
# Triaged 2026-05-24 as obsolete-test (high-confidence): updated to match
# the new contract; the previous three-branch pin was checking a pre-WP7
# shape that no longer exists.
# The effect body contains the four view-conditional updateHash calls.
if grep -qF "if (view === 'month') {" "$WP8_HAPPY" && \
   grep -qF "updateHash({ view: 'month', month: monthIso, range: null })" "$WP8_HAPPY" && \
   grep -qF "updateHash({ view: 'custom', range:" "$WP8_HAPPY" && \
   grep -qF "updateHash({ view: 'week', range: null, month: null })" "$WP8_HAPPY" && \
   grep -qF "updateHash({ view: null, range: null, month: null })" "$WP8_HAPPY"; then
    check "WP8-P2+WP7-P2 codify: view+range+month hash-write four-branch dispatch (month/custom/week/day)" pass
else
    check "WP8-P2+WP7-P2 codify: hash-write four-branch dispatch" fail "one or more dispatch branches missing"
fi

# WP8-P2-9: isDayLike used at all 6 consumer surfaces. Count must be >= 6.
# Surfaces: Body timeline ternary, Minimap render gate, Date-header label,
# Date-header projects/sessions count, ProjectFilterPopover projects prop,
# SummaryStrip stats selection.
isdaylike_count=$(grep -cF 'isDayLike' "$WP8_HAPPY" || true)
if [ "$isdaylike_count" -ge 6 ]; then
    check "WP8-P2 codify: isDayLike used at >=6 consumer surfaces (got $isdaylike_count)" pass
else
    check "WP8-P2 codify: isDayLike surfaces" fail "expected >=6, got $isdaylike_count"
fi

# WP8-P2-10: EmptyState date string format for Custom view.
# The conditional `isCustom ? \`${range.start} to ${range.end}\` : ...` lives
# in the body's <EmptyState date={...} /> ternary.
if grep -qF '<EmptyState date={isCustom' "$WP8_HAPPY" && \
   grep -qF '`${range.start} to ${range.end}`' "$WP8_HAPPY"; then
    check "WP8-P2 codify: EmptyState date string format for Custom view" pass
else
    check "WP8-P2 codify: EmptyState date string" fail "isCustom date-string conditional missing"
fi

rm -rf "$WP8_DIR"

# ── WP7 Phase 1 codify: --month flag + two-month payload emit ──────────
# Codifies the 12 Phase 1 deliverables for Month view (WP7). Builds its own
# isolated fixture (5-event seed across 2026-03 + 2026-04) so it doesn't
# depend on $WP8_DIR which was already cleaned up.

WP7_DIR="$(mktemp -d -t claude-time-wp7-codify-XXXXXX)"
WP7_DB="$WP7_DIR/events.sqlite"
sqlite3 "$WP7_DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
SQL
# Seed: 3 events in 2026-04 (active month), 2 events in 2026-03 (prev).
# Picked safely in the past so the not-future rule never blocks the happy path.
for ISO in 2026-04-05 2026-04-12 2026-04-15 2026-03-08 2026-03-20; do
    DAY_MS=$(python3 -c "
from datetime import date, datetime, time
d = date.fromisoformat('$ISO')
print(int(datetime.combine(d, time(12, 0)).timestamp() * 1000))
")
    STOP_MS=$((DAY_MS + 1800000))
    sqlite3 "$WP7_DB" "INSERT INTO events VALUES ($DAY_MS, 'sid-$ISO', '/repo/p', 'UserPromptSubmit', NULL, NULL, '{\"prompt_length_chars\":5}'), ($STOP_MS, 'sid-$ISO', '/repo/p', 'Stop', NULL, NULL, NULL);"
done

# WP7-P1-1: --month flag appears in `visualize --help` at column 3 with
# YYYY-MM metavar. Anchored against wrapped help-text continuation lines
# (same pattern as WP8-1).
HELP_OUT=$("$CLI" visualize --help 2>&1)
if echo "$HELP_OUT" | grep -qE '^  --month YYYY-MM'; then
    check "WP7-P1 codify: --help lists --month YYYY-MM flag" pass
else
    check "WP7-P1 codify: --month in --help" fail "flag not listed at column-3"
fi

# WP7-P1-2: happy path emits CT_INITIAL_VIEW="month".
WP7_HAPPY="$WP7_DIR/happy.html"
CLAUDE_TIME_DIR="$WP7_DIR" "$CLI" visualize --no-open \
    --month 2026-04 --out "$WP7_HAPPY" > /dev/null 2>&1
happy_rc=$?
if [ $happy_rc -eq 0 ] && [ -f "$WP7_HAPPY" ] && \
   grep -q 'CT_INITIAL_VIEW = "month"' "$WP7_HAPPY"; then
    check "WP7-P1 codify: --month emits CT_INITIAL_VIEW=\"month\"" pass
else
    check "WP7-P1 codify: --month emits CT_INITIAL_VIEW=\"month\"" fail "rc=$happy_rc, value missing"
fi

# WP7-P1-3: window.CT_DATA.months map present with active + prev keys.
# The shape is {"2026-04": {...}, "2026-03": {...}} — both keys must appear.
if grep -qE '"months": \{"2026-04":' "$WP7_HAPPY" && \
   grep -q '"2026-03":' "$WP7_HAPPY"; then
    check "WP7-P1 codify: months map has active (2026-04) + prev (2026-03) keys" pass
else
    check "WP7-P1 codify: months map keys" fail "active or prev key missing"
fi

# WP7-P1-4: per-month meta.start/.end correctness — active month boundaries.
if grep -q '"start": "2026-04-01"' "$WP7_HAPPY" && \
   grep -q '"end": "2026-04-30"' "$WP7_HAPPY"; then
    check "WP7-P1 codify: active-month meta.start=2026-04-01, meta.end=2026-04-30" pass
else
    check "WP7-P1 codify: active-month meta boundaries" fail "start or end missing"
fi

# WP7-P1-5: per-month meta.start/.end correctness — prev month boundaries.
if grep -q '"start": "2026-03-01"' "$WP7_HAPPY" && \
   grep -q '"end": "2026-03-31"' "$WP7_HAPPY"; then
    check "WP7-P1 codify: prev-month meta.start=2026-03-01, meta.end=2026-03-31" pass
else
    check "WP7-P1 codify: prev-month meta boundaries" fail "start or end missing"
fi

# WP7-P1-6: regression-pin — without --month, NO months key is emitted.
# Catches future drift where someone accidentally adds the months key to
# the default emit path (would bloat HTML for non-Month users).
WP7_NOMONTH="$WP7_DIR/nomonth.html"
CLAUDE_TIME_DIR="$WP7_DIR" "$CLI" visualize --no-open \
    --date 2026-04-10 --out "$WP7_NOMONTH" > /dev/null 2>&1
if ! grep -q '"months":' "$WP7_NOMONTH"; then
    check "WP7-P1 codify: default emit has NO months key (opt-in regression-pin)" pass
else
    check "WP7-P1 codify: default-emit no-months" fail "months key found in default emit"
fi

# WP7-P1-7: validation — bad shape exits 2, names shape rule.
err1=$(CLAUDE_TIME_DIR="$WP7_DIR" "$CLI" visualize --no-open \
    --month not-a-date --out /tmp/x.html 2>&1)
err1_rc=$?
if [ $err1_rc -eq 2 ] && echo "$err1" | grep -q -- '--month' && \
   echo "$err1" | grep -qi 'shape'; then
    check "WP7-P1 codify: validation — bad shape exits 2, names rule" pass
else
    check "WP7-P1 codify: bad shape exit" fail "rc=$err1_rc msg=$err1"
fi

# WP7-P1-8: validation — month bounds (e.g. month=99) exits 2, names rule.
err2=$(CLAUDE_TIME_DIR="$WP7_DIR" "$CLI" visualize --no-open \
    --month 2026-99 --out /tmp/x.html 2>&1)
err2_rc=$?
if [ $err2_rc -eq 2 ] && echo "$err2" | grep -q -- '--month' && \
   echo "$err2" | grep -qE 'month=99|01\.\.12'; then
    check "WP7-P1 codify: validation — out-of-bounds month exits 2, names rule" pass
else
    check "WP7-P1 codify: month bounds exit" fail "rc=$err2_rc msg=$err2"
fi

# WP7-P1-9: validation — future month exits 2, names 'future'.
err3=$(CLAUDE_TIME_DIR="$WP7_DIR" "$CLI" visualize --no-open \
    --month 2099-01 --out /tmp/x.html 2>&1)
err3_rc=$?
if [ $err3_rc -eq 2 ] && echo "$err3" | grep -q -- '--month' && \
   echo "$err3" | grep -qi 'future'; then
    check "WP7-P1 codify: validation — future month exits 2, names 'future'" pass
else
    check "WP7-P1 codify: future month exit" fail "rc=$err3_rc msg=$err3"
fi

# WP7-P1-10: mutex with --range (rc=2).
err4=$(CLAUDE_TIME_DIR="$WP7_DIR" "$CLI" visualize --no-open \
    --month 2026-04 --range 2026-05-01:2026-05-07 --out /tmp/x.html 2>&1)
err4_rc=$?
if [ $err4_rc -eq 2 ] && echo "$err4" | grep -q -- '--month' && \
   echo "$err4" | grep -q -- '--range' && \
   echo "$err4" | grep -qE 'incompatible|mutex|exclusive'; then
    check "WP7-P1 codify: --month + --range mutual exclusion (rc=2)" pass
else
    check "WP7-P1 codify: --month + --range mutex" fail "rc=$err4_rc msg=$err4"
fi

# WP7-P1-11: mutex with --demo (rc=2).
err5=$(CLAUDE_TIME_DIR="$WP7_DIR" "$CLI" visualize --no-open \
    --month 2026-04 --demo --out /tmp/x.html 2>&1)
err5_rc=$?
if [ $err5_rc -eq 2 ] && echo "$err5" | grep -q -- '--month' && \
   echo "$err5" | grep -qE 'incompatible|mutex|exclusive'; then
    check "WP7-P1 codify: --month + --demo mutual exclusion (rc=2)" pass
else
    check "WP7-P1 codify: --month + --demo mutex" fail "rc=$err5_rc msg=$err5"
fi

# WP7-P1-12: D6 fallback identity — when --month is set, data.today is
# the active-month payload (so Day/Week tabs in Month-emit mode still
# have something coherent to render). Identity check: data.today.meta.start
# equals the active month's first day. This guards against a future change
# that decouples today from months[active] and accidentally leaves today
# pointing at default-today instead of the active-month window.
if python3 -c "
import json, re, sys
html = open('$WP7_HAPPY').read()
m = re.search(r'window\.CT_DATA = (.*?);\n', html, re.DOTALL)
if not m:
    print('no window.CT_DATA match', file=sys.stderr); sys.exit(1)
data = json.loads(m.group(1))
today = data.get('today', {})
start = today.get('meta', {}).get('start')
sys.exit(0 if start == '2026-04-01' else 1)
" 2>/dev/null; then
    check "WP7-P1 codify: D6 fallback — data.today.meta.start == active-month start" pass
else
    check "WP7-P1 codify: D6 fallback identity" fail "data.today.meta.start != 2026-04-01"
fi

# WP7-P1-13: integration-boundary — viz_render.render_html signature is
# unchanged from WP8. The two-month payload flows through data dict's new
# `months` key, NOT via a new positional arg. Catches a future refactor
# that thinks "the renderer needs to know about month-mode" — it doesn't.
if grep -qE '^def render_html\(template_path: Path, dashboard_jsx_path: Path,' "$REPO_ROOT/tools/claude-time/viz_render.py"; then
    check "WP7-P1 codify: integration-boundary — viz_render.render_html signature unchanged" pass
else
    check "WP7-P1 codify: render_html signature" fail "signature changed"
fi

# ── WP7 Phase 2 codify: MonthView UI + nav + intensity encoding ─────
# Codifies the Phase 2 UI deliverables. Reuses $WP7_HAPPY emit from Phase 1
# block above (still contains the --month 2026-04 emitted HTML).

# WP7-P2-1: MonthView component function defined in emit.
if grep -qF 'function MonthView' "$WP7_HAPPY"; then
    check "WP7-P2 codify: MonthView component function defined" pass
else
    check "WP7-P2 codify: MonthView component" fail "function MonthView missing"
fi

# WP7-P2-2: MonthNavToast component function defined (toast+clipboard for
# reload-redirect paths — P2.5 resolution).
if grep -qF 'function MonthNavToast' "$WP7_HAPPY"; then
    check "WP7-P2 codify: MonthNavToast component function defined" pass
else
    check "WP7-P2 codify: MonthNavToast component" fail "function MonthNavToast missing"
fi

# WP7-P2-3: Month tab enabled form. Was disabled (false, false) before WP7.
if grep -qF "tabBtn('Month', 'month', view === 'month', true)" "$WP7_HAPPY"; then
    check "WP7-P2 codify: Month toolbar tab enabled (view === 'month', true)" pass
else
    check "WP7-P2 codify: Month tab enabled" fail "enabled form missing"
fi

# WP7-P2-4: Disabled Month tab form is GONE (regression-pin). The literal
# `tabBtn('Month', 'month', false, false)` was the v1 placeholder shape;
# its presence would mean the Month tab is back to "Not available in MVP".
if ! grep -qF "tabBtn('Month', 'month', false, false)" "$WP7_HAPPY"; then
    check "WP7-P2 codify: disabled Month tab form removed (regression-pin)" pass
else
    check "WP7-P2 codify: disabled Month tab regression" fail "legacy disabled form still present"
fi

# WP7-P2-5: _intensityColor helper present (D5' monochrome encoding).
if grep -qF '_intensityColor' "$WP7_HAPPY"; then
    check "WP7-P2 codify: _intensityColor helper present (D5')" pass
else
    check "WP7-P2 codify: _intensityColor helper" fail "missing"
fi

# WP7-P2-6: _MONTH_INTENSITY_PALETTE constant present — 6 oklch entries
# (empty + 5 populated buckets). This is the load-bearing color contract;
# changing the palette is a UX decision that should require a deliberate edit.
if grep -qF '_MONTH_INTENSITY_PALETTE' "$WP7_HAPPY" && \
   grep -qF "'oklch(0.965 0.005 268)'" "$WP7_HAPPY" && \
   grep -qF "'oklch(0.36 0.16 268)'" "$WP7_HAPPY"; then
    check "WP7-P2 codify: _MONTH_INTENSITY_PALETTE present with min + max bucket colors" pass
else
    check "WP7-P2 codify: _MONTH_INTENSITY_PALETTE" fail "constant or palette endpoints missing"
fi

# WP7-P2-7: D5 → D5' redesign — _projectTint helper REMOVED.
# Old WP7-P2 (pre-back-loop) had _projectTint(alias) → oklch per-project tint.
# D5' is a single-tile monochrome encoding; _projectTint should not appear.
if ! grep -qF '_projectTint' "$WP7_HAPPY"; then
    check "WP7-P2 codify: _projectTint helper removed (D5 → D5' regression-pin)" pass
else
    check "WP7-P2 codify: _projectTint regression" fail "legacy per-project tint helper still present"
fi

# WP7-P2-8: D5 → D5' redesign — data-project-strip selectors REMOVED.
# These attributes were on the per-project sub-rectangles inside each day cell
# in D5. D5' has no sub-rectangles; the attribute should not appear.
if ! grep -qF 'data-project-strip' "$WP7_HAPPY"; then
    check "WP7-P2 codify: data-project-strip selectors removed (D5 → D5' regression-pin)" pass
else
    check "WP7-P2 codify: data-project-strip regression" fail "legacy strip selector still present"
fi

# WP7-P2-9: Cell aspect ratio is 2:1 (whole month fits in one screen height
# per 2026-05-24 user-tuning at verify-human).
if grep -qF "aspectRatio: '2 / 1'" "$WP7_HAPPY"; then
    check "WP7-P2 codify: day-cell aspectRatio 2:1 (fits-in-viewport-height contract)" pass
else
    check "WP7-P2 codify: 2:1 aspect ratio" fail "aspectRatio: '2 / 1' missing"
fi

# WP7-P2-10: Old square aspect ratio is GONE (regression-pin against the
# 1:1 form that we shipped → reverted → re-shipped intermediate. WP9's
# WP8-P2-9 isDayLike block already counts grep instances of certain
# patterns, so this is an independent narrow pin on the literal 1:1 form
# inside MonthView's day-cell block specifically.)
# Note: this is a coarse string check; if some future code legitimately uses
# `aspectRatio: '1 / 1'` for a non-MonthView purpose, this assertion would
# need scoping. Today nothing else in the codebase uses that literal.
if ! grep -qF "aspectRatio: '1 / 1'" "$WP7_HAPPY"; then
    check "WP7-P2 codify: square 1:1 aspect ratio absent (back-loop fix regression-pin)" pass
else
    check "WP7-P2 codify: 1:1 aspect regression" fail "legacy square aspect still present"
fi

# WP7-P2-11: data-month-grid container selector. The MonthView root element
# carries `data-month-grid={monthIso}` for Playwright-stable selection.
if grep -qF 'data-month-grid={monthIso}' "$WP7_HAPPY"; then
    check "WP7-P2 codify: data-month-grid={monthIso} container selector" pass
else
    check "WP7-P2 codify: data-month-grid selector" fail "missing"
fi

# WP7-P2-12: data-month-day + data-month-day-active + data-month-day-intensity
# day-cell selectors. All three are load-bearing for Playwright behavioral
# coverage and for the empty-vs-populated visual contract.
if grep -qF 'data-month-day={iso}' "$WP7_HAPPY" && \
   grep -qF 'data-month-day-active' "$WP7_HAPPY" && \
   grep -qF 'data-month-day-intensity' "$WP7_HAPPY"; then
    check "WP7-P2 codify: day-cell selectors (data-month-day, -active, -intensity)" pass
else
    check "WP7-P2 codify: day-cell selectors" fail "one or more missing"
fi

# WP7-P2-13: data-month-nav arrow selectors (prev + next).
if grep -qF 'data-month-nav="prev"' "$WP7_HAPPY" && \
   grep -qF 'data-month-nav="next"' "$WP7_HAPPY"; then
    check "WP7-P2 codify: data-month-nav prev/next arrow selectors" pass
else
    check "WP7-P2 codify: data-month-nav selectors" fail "prev or next missing"
fi

# WP7-P2-14: data-month-nav-toast selector. MonthNavToast root has this
# attribute so Playwright can find it without title/aria-label coupling.
if grep -qF 'data-month-nav-toast="true"' "$WP7_HAPPY"; then
    check "WP7-P2 codify: data-month-nav-toast selector" pass
else
    check "WP7-P2 codify: data-month-nav-toast selector" fail "missing"
fi

# WP7-P2-15: _initMonthIso IIFE in Dashboard wrapper. Reads hash.month →
# today.meta.start[:7] → first months key → current calendar month fallback.
if grep -qF '_initMonthIso' "$WP7_HAPPY"; then
    check "WP7-P2 codify: _initMonthIso IIFE in Dashboard wrapper" pass
else
    check "WP7-P2 codify: _initMonthIso IIFE" fail "missing"
fi

# WP7-P2-16: monthIso state + setMonthIso setter in Dashboard wrapper.
# This is the load-bearing state for prev-arrow client-side swap (D1).
if grep -qF '[monthIso, setMonthIso] = React.useState' "$WP7_HAPPY"; then
    check "WP7-P2 codify: monthIso state + setter in Dashboard wrapper" pass
else
    check "WP7-P2 codify: monthIso state" fail "useState not found"
fi

# WP7-P2-17: Month-helper functions present (used by Toolbar's month-nav
# pill + MonthView grid math). All six are tiny pure functions — losing any
# one would cause runtime errors.
if grep -qF 'const _monthIsoToParts' "$WP7_HAPPY" && \
   grep -qF 'const _monthIsoToLabel' "$WP7_HAPPY" && \
   grep -qF 'const _prevMonthIso' "$WP7_HAPPY" && \
   grep -qF 'const _nextMonthIso' "$WP7_HAPPY" && \
   grep -qF 'const _daysInMonth' "$WP7_HAPPY" && \
   grep -qF 'const _mondayIndex' "$WP7_HAPPY"; then
    check "WP7-P2 codify: 6 month-helper functions defined (parts/label/prev/next/days/mondayIndex)" pass
else
    check "WP7-P2 codify: month-helper functions" fail "one or more missing"
fi

rm -rf "$WP7_DIR"

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
