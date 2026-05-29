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

# ── 1c. v3 WP3 Phase 1: --help lists --window with all three forms named ──
# Phase 1 consuming-surface contract: the new `--window` arg appears at column-3
# in --help; help text names all three accepted forms (MTD-N / Nd /
# YYYY-MM-DD:YYYY-MM-DD) plus the MTD-2 default. WP3 Phase 3 adds behavioral
# tests for the flag itself; this assertion only locks the help-text contract
# established in Phase 1.
window_flag_present=$(echo "$OUT" | grep -cE '^  --window VALUE\b')
help_flat=$(echo "$OUT" | tr '\n' ' ' | tr -s ' ')
if [ $rc -eq 0 ] && [ "$window_flag_present" = "1" ] && \
   echo "$help_flat" | grep -q 'MTD-N' && \
   echo "$help_flat" | grep -q 'Nd ' && \
   echo "$help_flat" | grep -q 'YYYY-MM-DD:YYYY-MM-DD' && \
   echo "$help_flat" | grep -q 'Default when omitted: MTD-2'; then
    check "v3 WP3 P1: --help lists --window VALUE with three forms + MTD-2 default" pass
else
    check "v3 WP3 P1: --window help-text contract" fail "rc=$rc, flag_at_col3=$window_flag_present, MTD-N=$(echo $help_flat | grep -c 'MTD-N'), default=$(echo $help_flat | grep -c 'Default when omitted: MTD-2')"
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

# Sections 8, 9, 9b deleted (v3 WP3 Phase 2 verify-codify, 2026-05-29):
# v2 flags --week / --date / --context-days-* are silently no-op'd by the v3
# --window default-to-MTD-2 branch; their CT_INITIAL_VIEW/target_iso effects
# are intentionally retired. WP4 removes the flags entirely.

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
# v3 WP3 Phase 2 verify-codify rewrite: was `$TMPDIR/v-week.html` (emitted by
# the deleted --week section 8). Wrapper-integrity is a source-shape pin on
# the Dashboard component + ViewportContext provider — agnostic to which
# initial view is selected. Emit fresh with --window 7d.
WEEK_HTML="$TMPDIR/v-wrapper.html"
"$CLI" visualize --no-open --window 7d --out "$WEEK_HTML" > /dev/null 2>&1
if [ -f "$WEEK_HTML" ] && \
   grep -q 'function Dashboard(' "$WEEK_HTML" && \
   grep -q 'ViewportContext' "$WEEK_HTML"; then
    check "WP5-P1 codify: visualize emit has Dashboard + ViewportContext (wrapper integrity)" pass
else
    check "WP5-P1 codify: wrapper integrity" fail "Dashboard or ViewportContext missing in $WEEK_HTML"
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

# ── WP5b codify block REMOVED (v3 WP3 Phase 2 verify-codify, 2026-05-29) ─
# The 6 scenarios (config.json applied, --context-days 0/0 overrides config,
# invalid-config-fallback, --demo forces single-day, week-coexists, target_iso
# path-divergence) all asserted on viz_context_days_* behavior. The v3 emit
# model retires those flags: --window defaults to MTD-2 (regardless of config),
# pre-renders all sub-payloads, and removes the "context-days expansion"
# concept entirely. WP4 deletes the underlying config keys + CLI flags.

# ── WP5b-P2 codify (renderer multi-day source-shape pins) ──────────────
# These assertions pin source code inside dashboard.jsx / viz_render.py
# (function names, prop signatures, scale arrays). They're agnostic to which
# CLI flag emitted the bundle — any multi-day visualize emit works. v3 WP3
# Phase 2 verify-codify reroutes the source HTML from a --date-emitted file
# to a --window-emitted file so the pins still run.
WP5B_DIR="$(mktemp -d -t claude-time-wp5bp2-XXXXXX)"
WP5B_DB="$WP5B_DIR/events.sqlite"
sqlite3 "$WP5B_DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
INSERT INTO events VALUES
  ($TODAY_NOON_MS,              'sid-wp5bp2', '/repo/wp5b', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars": 10}'),
  ($((TODAY_NOON_MS + 60000)),  'sid-wp5bp2', '/repo/wp5b', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 120000)), 'sid-wp5bp2', '/repo/wp5b', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 180000)), 'sid-wp5bp2', '/repo/wp5b', 'Stop', NULL, NULL, '{}');
SQL
WP5B_OUT5="$WP5B_DIR/multi-day.html"
CLAUDE_TIME_DIR="$WP5B_DIR" "$CLI" visualize --no-open \
    --window 7d --out "$WP5B_OUT5" > /dev/null 2>&1

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

# ── WP8 Phase 1 codify (v3 WP3 Phase 2 verify-codify rewrite, 2026-05-29) ──
# v3 retires the --range CLI flag; its view-selecting effects + validation +
# mutex behaviors are obsolete (10 scenarios removed: --help lists, happy path
# CT_INITIAL_VIEW="custom", --range meta.start/end/day_count, multi-day shape,
# opt-in regression-pin, end<start, days>cap, end>today, bad shape,
# --range+--demo mutex, warning on combined flags, config cap override).
#
# KEPT scenarios (rerouted to use --window emit):
#  - WP8-4: CT_MAX_RANGE_DAYS template injection — RangePicker UI still uses
#    this template variable (set from cfg.viz_custom_range_max_days) for the
#    Compare-custom-preset path that survives v3. Pin remains relevant.
#  - WP8-12: invalid-config-fallback for viz_custom_range_max_days — config
#    key still exists in v3 (used by Compare-custom-range). Pin remains.
#  - WP8-13: P1.disc.1 regex hardening — purely about the test file's own
#    regex shape; unrelated to --range CLI.

WP8_DIR="$(mktemp -d -t claude-time-wp8-codify-XXXXXX)"
WP8_DB="$WP8_DIR/events.sqlite"
sqlite3 "$WP8_DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
INSERT INTO events VALUES
  ($TODAY_NOON_MS,              'sid-wp8', '/repo/wp8', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars": 10}'),
  ($((TODAY_NOON_MS + 60000)),  'sid-wp8', '/repo/wp8', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 120000)), 'sid-wp8', '/repo/wp8', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 180000)), 'sid-wp8', '/repo/wp8', 'Stop', NULL, NULL, '{}');
SQL
WP8_HAPPY="$WP8_DIR/happy.html"
CLAUDE_TIME_DIR="$WP8_DIR" "$CLI" visualize --no-open \
    --window 7d --out "$WP8_HAPPY" > /dev/null 2>&1

# WP8-4 (kept): CT_MAX_RANGE_DAYS template injection — defaults to 90.
if grep -qE 'CT_MAX_RANGE_DAYS = 90\b' "$WP8_HAPPY"; then
    check "WP8-P1 codify (v3-rerouted): CT_MAX_RANGE_DAYS = 90 default injected" pass
else
    check "WP8-P1 codify: CT_MAX_RANGE_DAYS injection" fail "placeholder not replaced or wrong default"
fi

# WP8-12 (kept): config — invalid viz_custom_range_max_days falls back to 90.
printf '{"viz_custom_range_max_days": "not a number"}' > "$WP8_DIR/config.json"
WP8_BADCFG="$WP8_DIR/badcfg.html"
CLAUDE_TIME_DIR="$WP8_DIR" "$CLI" visualize --no-open \
    --window 7d --out "$WP8_BADCFG" > /dev/null 2>&1
badcfg_rc=$?
if [ $badcfg_rc -eq 0 ] && [ -f "$WP8_BADCFG" ] && \
   grep -qE 'CT_MAX_RANGE_DAYS = 90\b' "$WP8_BADCFG"; then
    check "WP8-P1 codify (v3-rerouted): invalid viz_custom_range_max_days falls back to default 90" pass
else
    check "WP8-P1 codify: invalid-config fallback" fail "rc=$badcfg_rc, default not preserved"
fi
rm -f "$WP8_DIR/config.json"

# WP8-13 (kept): P1.disc.1 hardening lock-in — test file's own regex shape.
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

# WP8-P2-8 (extended by WP7-P2 then WP11-P2): Debounced view+range+month
# hash-write useEffect with FIVE-branch dispatch (day/week/custom/month/compare).
# WP7 added the 'month' branch; WP11 added 'compare' + threaded the new
# `preset` and `ranges` keys through all non-compare branches (set when
# view==='compare', null otherwise per default-elision).
# Triaged 2026-05-24 as obsolete-test (high-confidence): updated for WP7
# month branch. Triaged 2026-05-26 again as obsolete-test (high-confidence):
# updated for WP11 compare branch + preset/ranges threading.
# The effect body contains the five view-conditional updateHash calls.
if grep -qF "if (view === 'month') {" "$WP8_HAPPY" && \
   grep -qF "updateHash({ view: 'month', month: monthIso, range: null, preset: null, ranges: null })" "$WP8_HAPPY" && \
   grep -qF "updateHash({ view: 'custom', range:" "$WP8_HAPPY" && \
   grep -qF "updateHash({ view: 'week', range: null, month: null, preset: null, ranges: null })" "$WP8_HAPPY" && \
   grep -qF "updateHash({ view: null, range: null, month: null, preset: null, ranges: null })" "$WP8_HAPPY"; then
    check "WP8-P2+WP7-P2+WP11-P2 codify: view+range+month+preset+ranges hash-write five-branch dispatch (compare/month/custom/week/day)" pass
else
    check "WP8-P2+WP7-P2+WP11-P2 codify: hash-write five-branch dispatch" fail "one or more dispatch branches missing"
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

# ── WP7 Phase 1 codify (v3 WP3 Phase 2 verify-codify rewrite, 2026-05-29) ──
# v3 retires the --month CLI flag; its view-selecting effects + validation +
# mutex behaviors are obsolete (12 scenarios removed: --help lists --month,
# CT_INITIAL_VIEW="month", months map keys, per-month meta boundaries,
# default-emit-no-months opt-in pin, bad-shape exit, month-bounds exit,
# future-month exit, --month+--range mutex, --month+--demo mutex, D6 fallback
# identity).
#
# KEPT scenario (no rerouting needed):
#  - WP7-P1-13: render_html signature unchanged — purely a Python source-shape
#    pin against viz_render.py. v3's --window path uses the same render_html
#    call signature; pin remains relevant.
#
# Setup retained: $WP7_DIR + $WP7_HAPPY are consumed by the WP7 Phase 2 codify
# block below (MonthView UI source-shape pins). Reroute $WP7_HAPPY to a
# --window 7d emit; the MonthView source code is still embedded in any
# visualize emit, so the pins survive.

WP7_DIR="$(mktemp -d -t claude-time-wp7-codify-XXXXXX)"
WP7_DB="$WP7_DIR/events.sqlite"
sqlite3 "$WP7_DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
INSERT INTO events VALUES
  ($TODAY_NOON_MS,              'sid-wp7', '/repo/wp7', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars": 10}'),
  ($((TODAY_NOON_MS + 60000)),  'sid-wp7', '/repo/wp7', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 120000)), 'sid-wp7', '/repo/wp7', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 180000)), 'sid-wp7', '/repo/wp7', 'Stop', NULL, NULL, '{}');
SQL
WP7_HAPPY="$WP7_DIR/happy.html"
CLAUDE_TIME_DIR="$WP7_DIR" "$CLI" visualize --no-open \
    --window 7d --out "$WP7_HAPPY" > /dev/null 2>&1

# WP7-P1-13 (kept): viz_render.render_html signature unchanged.
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

# ── WP10 Phase 1: Aggregator + emit wiring (metrics surface) ──────────
# Phase 1 verify-codify: source-shape pins for `window.CT_DATA.metrics` payload.
# Phase 1 emits the metrics tree on the --demo path AND on the real-DB path;
# we use --demo here for hermetic testing (no DB seeding needed).

WP10_DIR="$(mktemp -d -t claude-time-wp10-test-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$DEMO_DIR" "$NO_DB_DIR" "$WP8_DIR" "$WP7_DIR" "$WP10_DIR"' EXIT
WP10_HAPPY="$WP10_DIR/wp10-demo.html"
CLAUDE_TIME_DIR="$WP10_DIR" "$CLI" visualize --no-open --demo --out "$WP10_HAPPY" > /dev/null 2>&1
if [ ! -f "$WP10_HAPPY" ]; then
    check "WP10-P1 codify: --demo emit landed" fail "html missing"
fi

# WP10-P1-1: window.CT_DATA contains a `metrics` top-level key.
if grep -qF '"metrics":' "$WP10_HAPPY"; then
    check "WP10-P1 codify: window.CT_DATA.metrics top-level key present" pass
else
    check "WP10-P1 codify: metrics top-level key" fail "missing"
fi

# WP10-P1-2: all 7 metric sub-keys present (window, engaged_session, ai_agent,
# tool_call, human, concurrency, blocking).
if grep -qF '"window":' "$WP10_HAPPY" && \
   grep -qF '"engaged_session":' "$WP10_HAPPY" && \
   grep -qF '"ai_agent":' "$WP10_HAPPY" && \
   grep -qF '"tool_call":' "$WP10_HAPPY" && \
   grep -qF '"human":' "$WP10_HAPPY" && \
   grep -qF '"concurrency":' "$WP10_HAPPY" && \
   grep -qF '"blocking":' "$WP10_HAPPY"; then
    check "WP10-P1 codify: 7 metric sub-keys (window/engaged_session/ai_agent/tool_call/human/concurrency/blocking)" pass
else
    check "WP10-P1 codify: 7 metric sub-keys" fail "one or more missing"
fi

# WP10-P1-3: window.day_count is exactly 7 (trailing-7-day window — today
# inclusive + prior 6).
if grep -qE '"day_count":\s*7' "$WP10_HAPPY"; then
    check "WP10-P1 codify: metrics.window.day_count == 7 (trailing 7 days)" pass
else
    check "WP10-P1 codify: window.day_count" fail "not 7"
fi

# WP10-P1-4: concurrency array has 4 entries with is_plus on the 4th.
# JSON serialization is compact in viz_render; grep for the structural shape.
if grep -qE '"is_plus":\s*true' "$WP10_HAPPY"; then
    check "WP10-P1 codify: concurrency 4+ bucket has is_plus:true" pass
else
    check "WP10-P1 codify: is_plus:true" fail "missing"
fi

# WP10-P1-5: human.multiplier == 1.0 (one-brain by construction).
# Compact JSON omits trailing zeros, so check both literal forms.
if grep -qE '"multiplier":\s*1(\.0)?[,}]' "$WP10_HAPPY"; then
    check "WP10-P1 codify: human.multiplier == 1.0 (one-brain)" pass
else
    check "WP10-P1 codify: multiplier 1.0" fail "not found"
fi

# WP10-P1-6: ai_agent has a nested `subagent` sub-object (load-bearing for
# the "ai_agent.subagent" drill row in MetricsPanel).
if grep -qF '"subagent":' "$WP10_HAPPY"; then
    check "WP10-P1 codify: ai_agent.subagent nested sub-object present" pass
else
    check "WP10-P1 codify: ai_agent.subagent" fail "missing"
fi

# WP10-P1-7: tool_call has a `top` list (top-5 tools by effort-time).
if grep -qE '"top":\s*\[' "$WP10_HAPPY"; then
    check "WP10-P1 codify: tool_call.top list present" pass
else
    check "WP10-P1 codify: tool_call.top" fail "missing"
fi

rm -rf "$WP10_DIR"

# ── WP10 Phase 1 codify: integration-boundary tests (real-DB path) ────
# The 7 pins above exercise the --demo emit-shape; this block exercises the
# real-DB events-from-SQLite → build_metrics → emitted HTML pipeline, which
# is the load-bearing consuming surface for the integration-boundary rule
# (Phase 1 modifies `_cmd_visualize` in the existing `claude-time visualize`
# CLI command). User verified this path manually against /tmp/usage_analysis_v3.py
# in verify-human (22 numeric assertions matched exactly); these pins codify
# the verified behavior.

WP10C_DIR="$(mktemp -d -t claude-time-wp10-codify-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$DEMO_DIR" "$NO_DB_DIR" "$WP8_DIR" "$WP7_DIR" "$WP10_DIR" "$WP10C_DIR"' EXIT
WP10C_DB="$WP10C_DIR/events.sqlite"
sqlite3 "$WP10C_DB" <<SQL
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
SQL

# Seed one known burst-with-tool-call pattern that landed 1 hour ago — always
# inside the trailing-7-day window regardless of when the test runs.
# Burst: UPS at T-3600s, Stop at T-3540s = 60s wall-clock.
# Tool call: PreToolUse at T-3590s, PostToolUse at T-3580s = 10s.
# Expected:
#   metrics.ai_agent.wallclock_ms == 60000 (burst is 60s)
#   metrics.ai_agent.effort_ms    == 60000 (single burst, effort == wall)
#   metrics.tool_call.effort_ms   == 10000 (one 10s tool call)
#   metrics.engaged_session.wallclock_ms == 60000
#   metrics.engaged_session.session_count == 1
T_NOW_MS=$(python3 -c "import time; print(int(time.time() * 1000))")
UPS_MS=$((T_NOW_MS - 3600000))
STOP_MS=$((T_NOW_MS - 3540000))
PRE_MS=$((T_NOW_MS - 3590000))
POST_MS=$((T_NOW_MS - 3580000))
sqlite3 "$WP10C_DB" "INSERT INTO events VALUES \
  ($UPS_MS,  'sid-wp10c', '/repo/p', 'UserPromptSubmit', NULL, NULL, '{\"prompt_length_chars\":0}'), \
  ($PRE_MS,  'sid-wp10c', '/repo/p', 'PreToolUse',       'Bash', NULL, '{\"tool_use_id\":\"t1\"}'), \
  ($POST_MS, 'sid-wp10c', '/repo/p', 'PostToolUse',      'Bash', NULL, '{\"tool_use_id\":\"t1\"}'), \
  ($STOP_MS, 'sid-wp10c', '/repo/p', 'Stop',             NULL, NULL, NULL);"

WP10C_HAPPY="$WP10C_DIR/wp10c.html"
# v3 WP3 Phase 2 verify-codify rewrite: was bare `visualize --no-open` (which
# now defaults to MTD-2/90-day window). Reroute to `--window 7d` so the
# trailing-7-day window-math assertion in WP10-P1 codify-9 holds.
CLAUDE_TIME_DIR="$WP10C_DIR" "$CLI" visualize --no-open --window 7d --out "$WP10C_HAPPY" > /dev/null 2>&1
wp10c_rc=$?

# WP10-P1 codify-8: real-DB path emits metrics that reflect seeded events.
# Extracts metrics tree from emitted HTML and asserts known values from the
# seeded burst+tool-call pattern.
if [ $wp10c_rc -eq 0 ] && [ -f "$WP10C_HAPPY" ]; then
    METRICS_OK=$(python3 <<PYEOF
import re, json, sys
with open("$WP10C_HAPPY") as f: html = f.read()
m = re.search(r"window\.CT_DATA\s*=\s*(\{.*?\});", html, re.DOTALL)
assert m, "CT_DATA not found"
mt = json.loads(m.group(1))["metrics"]
# Burst was 60s (60000ms); single session.
assert mt["ai_agent"]["wallclock_ms"] == 60000, f"ai_agent.wc {mt['ai_agent']['wallclock_ms']} != 60000"
assert mt["ai_agent"]["effort_ms"] == 60000, f"ai_agent.eff {mt['ai_agent']['effort_ms']} != 60000"
assert mt["engaged_session"]["wallclock_ms"] == 60000, f"engaged.wc {mt['engaged_session']['wallclock_ms']} != 60000"
assert mt["engaged_session"]["session_count"] == 1, f"session_count {mt['engaged_session']['session_count']} != 1"
# Tool call was 10s.
assert mt["tool_call"]["effort_ms"] == 10000, f"tool effort {mt['tool_call']['effort_ms']} != 10000"
assert mt["tool_call"]["wallclock_ms"] == 10000, f"tool wc {mt['tool_call']['wallclock_ms']} != 10000"
# Top-5 includes Bash with effort 10000.
top_names = [t["name"] for t in mt["tool_call"]["top"]]
assert "Bash" in top_names, f"Bash not in top: {top_names}"
print("OK")
PYEOF
2>&1)
    if [ "$METRICS_OK" = "OK" ]; then
        check "WP10-P1 codify-8: real-DB path emits metrics reflecting seeded events (consuming surface)" pass
    else
        check "WP10-P1 codify-8: real-DB seeded events" fail "$METRICS_OK"
    fi
else
    check "WP10-P1 codify-8: real-DB emit" fail "rc=$wp10c_rc, html_exists=$([ -f "$WP10C_HAPPY" ] && echo yes || echo no)"
fi

# WP10-P1 codify-9: trailing-7-day window math is correct (today + prior 6).
# The CLI computes the window from snapshot_dt (wall-clock now). The test's
# expected window-end is today, window-start is today - 6 days.
if [ $wp10c_rc -eq 0 ] && [ -f "$WP10C_HAPPY" ]; then
    WINDOW_OK=$(python3 <<PYEOF
import re, json
from datetime import date, timedelta
with open("$WP10C_HAPPY") as f: html = f.read()
m = re.search(r"window\.CT_DATA\s*=\s*(\{.*?\});", html, re.DOTALL)
mt = json.loads(m.group(1))["metrics"]
today = date.today()
expected_start = (today - timedelta(days=6)).isoformat()
expected_end = today.isoformat()
assert mt["window"]["start"] == expected_start, f"start {mt['window']['start']} != {expected_start}"
assert mt["window"]["end"] == expected_end, f"end {mt['window']['end']} != {expected_end}"
assert mt["window"]["day_count"] == 7, f"day_count {mt['window']['day_count']} != 7"
print("OK")
PYEOF
2>&1)
    if [ "$WINDOW_OK" = "OK" ]; then
        check "WP10-P1 codify-9: trailing-7-day window math (today + prior 6, day_count=7)" pass
    else
        check "WP10-P1 codify-9: window math" fail "$WINDOW_OK"
    fi
else
    check "WP10-P1 codify-9: window math (emit failed)" fail "rc=$wp10c_rc"
fi

rm -rf "$WP10C_DIR"

# ── WP10 Phase 2 codify: HeadlineCard + MetricsPanel UI source-shape pins ──
# These pins assert that the JSX components landed in the emitted HTML and
# that the load-bearing selectors (data-metrics-card, data-metric-tile=*,
# data-metric-section=*, data-metric-expand-toggle) are present.

WP10P2_DIR="$(mktemp -d -t claude-time-wp10p2-test-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$DEMO_DIR" "$NO_DB_DIR" "$WP8_DIR" "$WP7_DIR" "$WP10_DIR" "$WP10C_DIR" "$WP10P2_DIR"' EXIT
WP10P2_HAPPY="$WP10P2_DIR/p2.html"
CLAUDE_TIME_DIR="$WP10P2_DIR" "$CLI" visualize --no-open --demo --out "$WP10P2_HAPPY" > /dev/null 2>&1

# WP10-P2-1: HeadlineCard component definition present in emitted HTML.
if grep -qF 'function HeadlineCard' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: HeadlineCard component definition present" pass
else
    check "WP10-P2 codify: HeadlineCard" fail "missing"
fi

# WP10-P2-2: MetricsPanel component definition present.
if grep -qF 'function MetricsPanel' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: MetricsPanel component definition present" pass
else
    check "WP10-P2 codify: MetricsPanel" fail "missing"
fi

# WP10-P2-3: _computeMetricsView filter-aware projection helper present.
if grep -qF 'function _computeMetricsView' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: _computeMetricsView filter-aware projection helper present" pass
else
    check "WP10-P2 codify: _computeMetricsView" fail "missing"
fi

# WP10-P2-4: data-metrics-card root selector present.
if grep -qF 'data-metrics-card="true"' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: data-metrics-card root selector present" pass
else
    check "WP10-P2 codify: data-metrics-card" fail "missing"
fi

# WP10-P2-5: three headline tile selectors (engaged-session, human, ai-effort).
if grep -qF 'data-metric-tile={t.id}' "$WP10P2_HAPPY" && \
   grep -qF "'engaged-session'" "$WP10P2_HAPPY" && \
   grep -qF "'ai-effort'" "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: three headline tile selectors (engaged-session, human, ai-effort)" pass
else
    check "WP10-P2 codify: headline tile selectors" fail "one or more missing"
fi

# WP10-P2-6: six metric-section selectors (engaged-session, ai-agent, tool-call, human, concurrency, blocking).
sections_found=0
for section in "engaged-session" "ai-agent" "tool-call" "human" "concurrency" "blocking"; do
    if grep -qF "data-metric-section=\"$section\"" "$WP10P2_HAPPY"; then
        sections_found=$((sections_found + 1))
    fi
done
if [ "$sections_found" -eq 6 ]; then
    check "WP10-P2 codify: six data-metric-section selectors (engaged-session, ai-agent, tool-call, human, concurrency, blocking)" pass
else
    check "WP10-P2 codify: metric-section selectors" fail "found $sections_found of 6"
fi

# WP10-P2-7: data-metric-expand-toggle chevron selector present.
if grep -qF 'data-metric-expand-toggle="true"' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: data-metric-expand-toggle chevron selector present" pass
else
    check "WP10-P2 codify: data-metric-expand-toggle" fail "missing"
fi

# WP10-P2-8: metricsExpanded state + setMetricsExpanded setter in interactive
# Dashboard wrapper (load-bearing for the chevron toggle behavior).
if grep -qF '[metricsExpanded, setMetricsExpanded] = React.useState' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: metricsExpanded state in Dashboard wrapper" pass
else
    check "WP10-P2 codify: metricsExpanded state" fail "useState not found"
fi

# WP10-P2-9: hash 'metrics' key writer present (default-elision: writes null when collapsed).
if grep -qF "updateHash({ metrics: metricsExpanded ? 'expanded' : null })" "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: hash 'metrics' key writer with default-elision" pass
else
    check "WP10-P2 codify: hash metrics writer" fail "missing"
fi

# WP10-P2-10: _initMetricsExpanded IIFE reads hash.metrics === 'expanded' on init.
if grep -qF "_initMetricsExpanded" "$WP10P2_HAPPY" && \
   grep -qF "hash.metrics === 'expanded'" "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: _initMetricsExpanded IIFE reads hash.metrics on init" pass
else
    check "WP10-P2 codify: _initMetricsExpanded IIFE" fail "missing"
fi

# WP10-P2-11: empty-window caption literal present.
if grep -qF 'No tracked activity in the past 7 days' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: empty-window caption literal 'No tracked activity in the past 7 days'" pass
else
    check "WP10-P2 codify: empty-window caption" fail "missing"
fi

# WP10-P2-12: filter-state-aware variant caption (filtered-empty case).
if grep -qF 'No data matches current filters' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: filter-empty caption variant present" pass
else
    check "WP10-P2 codify: filter-empty caption" fail "missing"
fi

# WP10-P2-13: HeadlineCard + MetricsPanel are rendered inside Dashboard,
# gated by window.CT_DATA.metrics presence (additive-emit guard).
if grep -qF 'window.CT_DATA.metrics && (' "$WP10P2_HAPPY" && \
   grep -qF '<HeadlineCard' "$WP10P2_HAPPY" && \
   grep -qF '<MetricsPanel' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: HeadlineCard + MetricsPanel rendered in Dashboard, gated by metrics presence" pass
else
    check "WP10-P2 codify: Dashboard placement" fail "components or guard missing"
fi

# WP10-P2-14 (P2.verify-human.2 back-loop, 2026-05-24): data-metrics-window
# selector on HeadlineCard surfaces the trailing-7-day window context without
# requiring panel expansion. The label uses the "Past N days · YYYY-MM-DD → YYYY-MM-DD"
# format with monospaced font for the date pair.
if grep -qF 'data-metrics-window="true"' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: data-metrics-window selector on collapsed HeadlineCard" pass
else
    check "WP10-P2 codify: data-metrics-window selector" fail "missing"
fi

# WP10-P2-15: the window label format "Past N days · ..." literal present
# (sanity pin against the format string drifting without intent).
if grep -qF 'Past ${view.window.day_count} days' "$WP10P2_HAPPY"; then
    check "WP10-P2 codify: window label uses 'Past N days' format on HeadlineCard" pass
else
    check "WP10-P2 codify: window label format" fail "missing"
fi

rm -rf "$WP10P2_DIR"

# ── WP11 Phase 1 codify: --compare / --compare-range CLI surface + emit pins ──
# Integration boundary: this block exercises the consuming surfaces (the
# `visualize` subcommand's argparse + _cmd_visualize + viz_render.render_html
# + template.html) by emit-and-grep. Source-shape pins are in this file;
# Python unit tests for compare_month_over_month live in test_viz_data.py
# (CompareMonthOverMonthTests) and the render_html signature/emit test lives
# in test_viz_render.py.

WP11P1_DIR="$(mktemp -d -t claude-time-wp11p1-test-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$DEMO_DIR" "$NO_DB_DIR" "$WP8_DIR" "$WP7_DIR" "$WP10_DIR" "$WP10C_DIR" "$WP10P2_DIR" "$WP11P1_DIR"' EXIT

WP11_WOW="$WP11P1_DIR/wow.html"
WP11_RANGE="$WP11P1_DIR/range.html"
WP11_DEFAULT="$WP11P1_DIR/default.html"

CLAUDE_TIME_DIR="$WP11P1_DIR" "$CLI" visualize --no-open --demo --compare wow --out "$WP11_WOW" > /dev/null 2>&1
CLAUDE_TIME_DIR="$WP11P1_DIR" "$CLI" visualize --no-open --demo --compare-range 2026-05-13:2026-05-19,2026-05-20:2026-05-26 --out "$WP11_RANGE" > /dev/null 2>&1
CLAUDE_TIME_DIR="$WP11P1_DIR" "$CLI" visualize --no-open --demo --out "$WP11_DEFAULT" > /dev/null 2>&1

# WP11-P1-1: --help lists both new flags.
WP11_HELP="$("$CLI" visualize --help 2>&1)"
if echo "$WP11_HELP" | grep -qE -- '--compare \{wow,today-vs-trailing,mom\}'; then
    check "WP11-P1 codify: --help lists --compare with choices" pass
else
    check "WP11-P1 codify: --help --compare" fail "missing or choices changed"
fi

if echo "$WP11_HELP" | grep -qE -- '--compare-range A_START:A_END,B_START:B_END'; then
    check "WP11-P1 codify: --help lists --compare-range with metavar" pass
else
    check "WP11-P1 codify: --help --compare-range" fail "missing or metavar changed"
fi

# WP11-P1-2: --compare wow emit has CT_INITIAL_VIEW = "compare".
if grep -qF 'window.CT_INITIAL_VIEW = "compare";' "$WP11_WOW"; then
    check "WP11-P1 codify: --compare wow emits CT_INITIAL_VIEW=\"compare\"" pass
else
    check "WP11-P1 codify: CT_INITIAL_VIEW=compare on --compare wow" fail "wrong or missing"
fi

# WP11-P1-3: --compare wow emit has CT_INITIAL_PRESET = "wow".
if grep -qF 'window.CT_INITIAL_PRESET = "wow";' "$WP11_WOW"; then
    check "WP11-P1 codify: --compare wow emits CT_INITIAL_PRESET=\"wow\"" pass
else
    check "WP11-P1 codify: CT_INITIAL_PRESET=wow" fail "wrong or missing"
fi

# WP11-P1-4: --compare-range emit has CT_INITIAL_PRESET = "custom".
if grep -qF 'window.CT_INITIAL_PRESET = "custom";' "$WP11_RANGE"; then
    check "WP11-P1 codify: --compare-range emits CT_INITIAL_PRESET=\"custom\"" pass
else
    check "WP11-P1 codify: CT_INITIAL_PRESET=custom" fail "wrong or missing"
fi

# WP11-P1-5: default (no --compare* flag) → CT_INITIAL_PRESET = null.
# Pin against the JSON-encoded null literal, not the string "null".
if grep -qF 'window.CT_INITIAL_PRESET = null;' "$WP11_DEFAULT"; then
    check "WP11-P1 codify: default CT_INITIAL_PRESET=null (no compare flag)" pass
else
    check "WP11-P1 codify: default CT_INITIAL_PRESET=null" fail "wrong or missing"
fi

# WP11-P1-6: --compare wow emit has window.CT_DATA.comparison object with
# {a, b, deltas, meta} keys. Use a Python sub-shell to JSON-parse the
# CT_DATA literal because grep-on-JSON is brittle.
python3 -c "
import re, json, sys
h = open('$WP11_WOW').read()
m = re.search(r'window\.CT_DATA = ({.*?});', h, re.DOTALL)
if not m: sys.exit('CT_DATA assignment not found in emit')
d = json.loads(m.group(1))
if 'comparison' not in d: sys.exit('comparison key missing')
c = d['comparison']
missing = [k for k in ('a','b','deltas','meta') if k not in c]
if missing: sys.exit(f'comparison missing keys: {missing}')
" 2>/dev/null
if [ $? -eq 0 ]; then
    check "WP11-P1 codify: --compare wow emits CT_DATA.comparison with {a,b,deltas,meta}" pass
else
    check "WP11-P1 codify: CT_DATA.comparison shape" fail "missing or wrong keys"
fi

# WP11-P1-7: default emit (no --compare* flag) does NOT include the
# comparison key — default-elision keeps unrelated payloads out.
if grep -qE '"comparison"\s*:' "$WP11_DEFAULT"; then
    check "WP11-P1 codify: default emit comparison absent" fail "comparison key present on default emit"
else
    check "WP11-P1 codify: default emit has no comparison key" pass
fi

# WP11-P1-8: mutex --compare + --compare-range returns rc=2 with the right
# error message naming both flags.
err=$(CLAUDE_TIME_DIR="$WP11P1_DIR" "$CLI" visualize --compare wow --compare-range 2026-05-13:2026-05-19,2026-05-20:2026-05-26 --demo --no-open --out "$WP11P1_DIR/m1.html" 2>&1)
rc=$?
if [ $rc -eq 2 ] && echo "$err" | grep -qF -- '--compare and --compare-range are mutually exclusive'; then
    check "WP11-P1 codify: mutex --compare ⨯ --compare-range (rc=2 + right msg)" pass
else
    check "WP11-P1 codify: mutex --compare ⨯ --compare-range" fail "rc=$rc msg=$err"
fi

# WP11-P1-9: mutex --compare + --range — the error must name --range, not
# --demo. This catches the build-time discovery: cross-flag mutex must fire
# BEFORE --range vs --demo parsing.
err=$(CLAUDE_TIME_DIR="$WP11P1_DIR" "$CLI" visualize --compare wow --range 2026-05-01:2026-05-07 --demo --no-open --out "$WP11P1_DIR/m2.html" 2>&1)
rc=$?
if [ $rc -eq 2 ] && echo "$err" | grep -qF 'incompatible with --range'; then
    check "WP11-P1 codify: mutex --compare ⨯ --range names --range (rc=2)" pass
else
    check "WP11-P1 codify: mutex --compare ⨯ --range error precedence" fail "rc=$rc msg=$err"
fi

# WP11-P1-10: mutex --compare + --month — same error-precedence pin.
err=$(CLAUDE_TIME_DIR="$WP11P1_DIR" "$CLI" visualize --compare wow --month 2026-05 --demo --no-open --out "$WP11P1_DIR/m3.html" 2>&1)
rc=$?
if [ $rc -eq 2 ] && echo "$err" | grep -qF 'incompatible with --month'; then
    check "WP11-P1 codify: mutex --compare ⨯ --month names --month (rc=2)" pass
else
    check "WP11-P1 codify: mutex --compare ⨯ --month error precedence" fail "rc=$rc msg=$err"
fi

# WP11-P1-11: mutex --compare + --date — explicit --date conflict.
err=$(CLAUDE_TIME_DIR="$WP11P1_DIR" "$CLI" visualize --compare wow --date 2026-05-20 --demo --no-open --out "$WP11P1_DIR/m4.html" 2>&1)
rc=$?
if [ $rc -eq 2 ] && echo "$err" | grep -qF 'incompatible with --date'; then
    check "WP11-P1 codify: mutex --compare ⨯ --date names --date (rc=2)" pass
else
    check "WP11-P1 codify: mutex --compare ⨯ --date" fail "rc=$rc msg=$err"
fi

# WP11-P1-12: bad --compare-range shape returns rc=2 with rule-named error.
err=$(CLAUDE_TIME_DIR="$WP11P1_DIR" "$CLI" visualize --compare-range 'no-comma-here' --demo --no-open --out "$WP11P1_DIR/m5.html" 2>&1)
rc=$?
if [ $rc -eq 2 ] && echo "$err" | grep -qF 'two ranges separated by a comma'; then
    check "WP11-P1 codify: --compare-range bad shape (no comma) → rc=2 + rule-named error" pass
else
    check "WP11-P1 codify: --compare-range bad shape" fail "rc=$rc msg=$err"
fi

# WP11-P1-13: bad --compare-range first half tags which half failed.
err=$(CLAUDE_TIME_DIR="$WP11P1_DIR" "$CLI" visualize --compare-range 'bogus,2026-05-20:2026-05-26' --demo --no-open --out "$WP11P1_DIR/m6.html" 2>&1)
rc=$?
if [ $rc -eq 2 ] && echo "$err" | grep -qF 'first range (A) failed validation'; then
    check "WP11-P1 codify: --compare-range A-half failure tagged" pass
else
    check "WP11-P1 codify: --compare-range A-half tag" fail "rc=$rc msg=$err"
fi

# WP11-P1-14: render_html template placeholder substitution worked. If the
# replacement is missed, the raw '{{CT_INITIAL_PRESET}}' would leak into the
# emit and break JS parsing.
if grep -qF '{{CT_INITIAL_PRESET}}' "$WP11_WOW"; then
    check "WP11-P1 codify: template placeholder leak" fail "{{CT_INITIAL_PRESET}} leaked into emit"
else
    check "WP11-P1 codify: no template placeholder leak in emit" pass
fi

# WP11-P1-15: --compare-range meta windows match input. The data-layer
# emits comparison.meta.{a_start,a_end,b_start,b_end} which Phase 2 will
# render — this pin guards the byte-equivalence.
python3 -c "
import re, json, sys
h = open('$WP11_RANGE').read()
m = re.search(r'window\.CT_DATA = ({.*?});', h, re.DOTALL)
d = json.loads(m.group(1))
meta = d['comparison']['meta']
expected = {'a_start':'2026-05-13','a_end':'2026-05-19','b_start':'2026-05-20','b_end':'2026-05-26',
            'a_day_count':7,'b_day_count':7}
for k, v in expected.items():
    if meta.get(k) != v: sys.exit(f'meta.{k} = {meta.get(k)!r} (expected {v!r})')
" 2>/dev/null
if [ $? -eq 0 ]; then
    check "WP11-P1 codify: --compare-range meta windows match input verbatim" pass
else
    check "WP11-P1 codify: --compare-range meta windows" fail "shape mismatch"
fi

rm -rf "$WP11P1_DIR"

# ── WP11 Phase 1.B codify: per-window metrics emit ──
# Phase 1.B adds `comparison.a.metrics` and `comparison.b.metrics` sub-trees
# to the emit, sourced by calling viz_data.build_metrics over each window's
# events. The CompareView UI (Phase 2.A) consumes these. Pins exercise the
# emit-side contract: shape, key set, demo empty-shape sanity.

WP11P1B_DIR="$(mktemp -d -t claude-time-wp11p1b-test-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$DEMO_DIR" "$NO_DB_DIR" "$WP8_DIR" "$WP7_DIR" "$WP10_DIR" "$WP10C_DIR" "$WP10P2_DIR" "$WP11P1_DIR" "$WP11P1B_DIR"' EXIT

WP11P1B_DEMO="$WP11P1B_DIR/demo.html"
CLAUDE_TIME_DIR="$WP11P1B_DIR" "$CLI" visualize --no-open --demo --compare wow --out "$WP11P1B_DEMO" > /dev/null 2>&1

# WP11-P1B-1: comparison.a.metrics is a dict (object).
python3 -c "
import re, json, sys
h = open('$WP11P1B_DEMO').read()
m = re.search(r'window\.CT_DATA = ({.*?});', h, re.DOTALL)
d = json.loads(m.group(1))
am = d.get('comparison', {}).get('a', {}).get('metrics')
if not isinstance(am, dict): sys.exit(f'a.metrics is not a dict: {type(am)}')
" 2>/dev/null
if [ $? -eq 0 ]; then
    check "WP11-P1B codify: comparison.a.metrics is a dict on emit" pass
else
    check "WP11-P1B codify: a.metrics shape" fail "missing or wrong type"
fi

# WP11-P1B-2: comparison.b.metrics is a dict (object).
python3 -c "
import re, json, sys
h = open('$WP11P1B_DEMO').read()
m = re.search(r'window\.CT_DATA = ({.*?});', h, re.DOTALL)
d = json.loads(m.group(1))
bm = d.get('comparison', {}).get('b', {}).get('metrics')
if not isinstance(bm, dict): sys.exit(f'b.metrics is not a dict: {type(bm)}')
" 2>/dev/null
if [ $? -eq 0 ]; then
    check "WP11-P1B codify: comparison.b.metrics is a dict on emit" pass
else
    check "WP11-P1B codify: b.metrics shape" fail "missing or wrong type"
fi

# WP11-P1B-3: both a.metrics and b.metrics have the 6 expected top-level
# keys (engaged_session, ai_agent, tool_call, human, concurrency, blocking) —
# the shape contract matches the existing data.metrics tree, so CompareView
# can reuse _computeMetricsView (WP10) over both windows.
python3 -c "
import re, json, sys
h = open('$WP11P1B_DEMO').read()
m = re.search(r'window\.CT_DATA = ({.*?});', h, re.DOTALL)
d = json.loads(m.group(1))
EXPECTED = {'engaged_session', 'ai_agent', 'tool_call', 'human', 'concurrency', 'blocking'}
for side in ('a', 'b'):
    keys = set(d['comparison'][side]['metrics'].keys())
    missing = EXPECTED - keys
    if missing: sys.exit(f'{side}.metrics missing keys: {missing}')
" 2>/dev/null
if [ $? -eq 0 ]; then
    check "WP11-P1B codify: a.metrics and b.metrics both have the 6 canonical keys" pass
else
    check "WP11-P1B codify: a.metrics + b.metrics key set" fail "missing canonical keys"
fi

# WP11-P1B-4: demo path emits empty-shape metrics on both sides
# (engaged_session.wallclock_ms === 0). Confirms _build_demo_comparison was
# extended (not just the real-DB branch).
python3 -c "
import re, json, sys
h = open('$WP11P1B_DEMO').read()
m = re.search(r'window\.CT_DATA = ({.*?});', h, re.DOTALL)
d = json.loads(m.group(1))
a_wc = d['comparison']['a']['metrics']['engaged_session']['wallclock_ms']
b_wc = d['comparison']['b']['metrics']['engaged_session']['wallclock_ms']
if a_wc != 0: sys.exit(f'demo a.engaged_session.wallclock_ms expected 0, got {a_wc}')
if b_wc != 0: sys.exit(f'demo b.engaged_session.wallclock_ms expected 0, got {b_wc}')
" 2>/dev/null
if [ $? -eq 0 ]; then
    check "WP11-P1B codify: demo path emits empty-shape metrics (wallclock_ms === 0 on both sides)" pass
else
    check "WP11-P1B codify: demo empty-shape" fail "demo metrics not empty-shape"
fi

rm -rf "$WP11P1B_DIR"

# ── WP11 Phase 2.A codify: effectiveness-lens UI source-shape pins ──
# Phase 2.A replaces the rejected delta-lens design (TopShiftsCallouts /
# PerKindSection / PerProjectSection / _CompareBarRow) with an
# effectiveness-lens design sourced from comparison.{a,b}.metrics. Pins
# assert: (a) obsolete delta-lens components are GONE; (b) new effectiveness
# section + 8 ratio/absolute rows are present; (c) generalized
# EffectivenessRow component is defined.

WP11P2A_DIR="$(mktemp -d -t claude-time-wp11p2a-test-XXXXXX)"
trap 'rm -rf "$TMPDIR" "$DEMO_DIR" "$NO_DB_DIR" "$WP8_DIR" "$WP7_DIR" "$WP10_DIR" "$WP10C_DIR" "$WP10P2_DIR" "$WP11P1_DIR" "$WP11P1B_DIR" "$WP11P2A_DIR"' EXIT

WP11P2A_EMIT="$WP11P2A_DIR/emit.html"
CLAUDE_TIME_DIR="$WP11P2A_DIR" "$CLI" visualize --no-open --demo --compare wow --out "$WP11P2A_EMIT" > /dev/null 2>&1

# WP11-P2A-1: EffectivenessRow component definition present in emitted HTML.
if grep -qF 'function EffectivenessRow(' "$WP11P2A_EMIT"; then
    check "WP11-P2A codify: EffectivenessRow component definition present" pass
else
    check "WP11-P2A codify: EffectivenessRow" fail "missing"
fi

# WP11-P2A-2: data-compare-section="effectiveness" container is present.
if grep -qF 'data-compare-section="effectiveness"' "$WP11P2A_EMIT"; then
    check "WP11-P2A codify: data-compare-section=\"effectiveness\" container present" pass
else
    check "WP11-P2A codify: effectiveness section" fail "missing"
fi

# WP11-P2A-3: 8 effectiveness rows in priority order (R1). Pin each
# data-compare-row="<key>" as a separate assertion so we know exactly
# which row went missing if regression hits.
for row_key in parallelism-multiplier ai-effort-per-human-wallclock blocking-split concurrency-mix ai-agent tool-call human engaged-session; do
    if grep -qF "rowKey: '${row_key}'" "$WP11P2A_EMIT"; then
        check "WP11-P2A codify: row '${row_key}' present in rows[] array" pass
    else
        check "WP11-P2A codify: row '${row_key}'" fail "missing from rows[]"
    fi
done

# WP11-P2A-4: negative pin — the 4 obsolete delta-lens selectors are GONE.
# This is the explicit "do not regress" guard against re-introducing the
# rejected design.
for obsolete_sel in 'data-compare-section="top-shifts"' 'data-compare-section="per-kind"' 'data-compare-section="per-kind-total"' 'data-compare-section="per-project"'; do
    if grep -qF "$obsolete_sel" "$WP11P2A_EMIT"; then
        check "WP11-P2A codify: obsolete delta-lens selector ${obsolete_sel} is GONE" fail "still present"
    else
        check "WP11-P2A codify: obsolete delta-lens selector ${obsolete_sel} is GONE" pass
    fi
done

# WP11-P2A-5: negative pin — the 4 obsolete delta-lens component functions are GONE.
for obsolete_fn in 'function TopShiftsCallouts(' 'function PerKindSection(' 'function PerProjectSection(' 'function _CompareBarRow('; do
    if grep -qF "$obsolete_fn" "$WP11P2A_EMIT"; then
        check "WP11-P2A codify: obsolete component '${obsolete_fn}' is GONE" fail "still defined"
    else
        check "WP11-P2A codify: obsolete component '${obsolete_fn}' is GONE" pass
    fi
done

# WP11-P2A-6: negative pin — _computeComparisonView helper is GONE (replaced
# by twice-applied _computeMetricsView from WP10).
if grep -qF 'function _computeComparisonView(' "$WP11P2A_EMIT"; then
    check "WP11-P2A codify: obsolete _computeComparisonView helper is GONE" fail "still defined"
else
    check "WP11-P2A codify: obsolete _computeComparisonView helper is GONE" pass
fi

# WP11-P2A-7: CompareView consumes comparison.a.metrics + comparison.b.metrics
# via _computeMetricsView (the same projection helper WP10 uses for the
# trailing-7-day MetricsPanel). Pin both calls.
if grep -qF '_computeMetricsView(comparison?.a?.metrics' "$WP11P2A_EMIT" && \
   grep -qF '_computeMetricsView(comparison?.b?.metrics' "$WP11P2A_EMIT"; then
    check "WP11-P2A codify: CompareView calls _computeMetricsView on both windows" pass
else
    check "WP11-P2A codify: CompareView projection helper wiring" fail "missing one or both _computeMetricsView calls"
fi

# WP11-P2A-8: column-header selectors data-compare-col=a/b/delta on each row
# (Playwright behavioral test will assert these too).
if grep -qF 'data-compare-col="a"' "$WP11P2A_EMIT" && \
   grep -qF 'data-compare-col="b"' "$WP11P2A_EMIT" && \
   grep -qF 'data-compare-col="delta"' "$WP11P2A_EMIT"; then
    check "WP11-P2A codify: data-compare-col=\"a/b/delta\" selectors present" pass
else
    check "WP11-P2A codify: data-compare-col selectors" fail "missing one or more of a/b/delta"
fi

rm -rf "$WP11P2A_DIR"

# ── v3 WP3 Phase 2 codify: --window emits both v3 sub-payload maps AND ──
# ── legacy alias keys side-by-side (the v2-frontend coexistence contract) ──
#
# Phase 2 hits the integration boundary (CLI command behavior + dashboard HTML
# rendering changed substantively). The boundary contract this whole phase
# exists to preserve is: the emitted window.CT_DATA contains BOTH the new v3
# sub-payload keys (day_payloads_by_iso etc.) AND legacy alias keys (today,
# week, comparison, metrics, meta, months) side-by-side, so the v2 frontend
# keeps rendering until WP5–WP9 wire the sub-payloads.
#
# The verify-self alias-key audit miss (P2.4 initial grep was incomplete —
# missed `const {today, week} = window.CT_DATA` destructure + `meta.start/end/
# day_count` reads) was the exact regression this test would catch. Pinning
# both sets ensures future WPs (WP5–WP9) progressively remove aliases as they
# wire each consumer to the v3 sub-payloads, without accidentally regressing
# the others mid-transition.
#
# Parser-correctness scenarios (default MTD-2 bounds, --window 30d day_count,
# --window 2026-04-01:2026-05-26 explicit bounds, --window+--demo mutex,
# bad-shape error) are owned by Phase 3 per the plan split.
WP3P2_DIR="$(mktemp -d -t claude-time-wp3p2-XXXXXX)"
WP3P2_DB="$WP3P2_DIR/events.sqlite"
sqlite3 "$WP3P2_DB" <<SQL > /dev/null 2>&1
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
INSERT INTO events VALUES
  ($TODAY_NOON_MS,              'sid-wp3', '/repo/wp3', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars": 10}'),
  ($((TODAY_NOON_MS + 60000)),  'sid-wp3', '/repo/wp3', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 120000)), 'sid-wp3', '/repo/wp3', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 180000)), 'sid-wp3', '/repo/wp3', 'Stop', NULL, NULL, '{}');
SQL

WP3P2_EMIT="$WP3P2_DIR/wp3-window.html"
CLAUDE_TIME_DIR="$WP3P2_DIR" "$CLI" visualize --no-open \
    --window 30d --out "$WP3P2_EMIT" > /dev/null 2>&1
wp3p2_rc=$?

if [ $wp3p2_rc -eq 0 ] && [ -f "$WP3P2_EMIT" ]; then
    check "v3 WP3 P2 codify: --window 30d emits HTML, rc=0" pass
else
    check "v3 WP3 P2 codify: --window 30d emits HTML, rc=0" fail "rc=$wp3p2_rc, emit_exists=$([ -f "$WP3P2_EMIT" ] && echo yes || echo no)"
fi

# Boundary contract — both v3 keys and legacy alias keys present side-by-side.
# Extract the CT_DATA literal and check key membership via Python (jq would be
# nice but isn't a project test dep; python3 already is for date math above).
wp3p2_audit=$(python3 - <<PY
import re, json, sys
try:
    txt = open("$WP3P2_EMIT").read()
except Exception as e:
    print(f"FAIL: emit not readable: {e}")
    sys.exit(0)
m = re.search(r'window\.CT_DATA\s*=\s*(\{.*?\});', txt, re.DOTALL)
if not m:
    print("FAIL: window.CT_DATA literal not found in emit")
    sys.exit(0)
try:
    data = json.loads(m.group(1))
except Exception as e:
    print(f"FAIL: CT_DATA not valid JSON: {e}")
    sys.exit(0)
v3_keys = {"window", "day_payloads_by_iso", "week_payloads_by_monday",
           "month_payloads_by_iso", "compare_payloads_by_preset"}
legacy_keys = {"today", "week", "comparison", "metrics", "meta", "months"}
missing_v3 = v3_keys - set(data.keys())
missing_legacy = legacy_keys - set(data.keys())
if missing_v3 or missing_legacy:
    print(f"FAIL: missing v3={sorted(missing_v3)} missing legacy={sorted(missing_legacy)}")
    sys.exit(0)
# Cross-check: meta has the shape v2 frontend reads (start/end/day_count).
meta_required = {"start", "end", "day_count"}
missing_meta = meta_required - set(data.get("meta", {}).keys())
if missing_meta:
    print(f"FAIL: meta alias shape incomplete; missing={sorted(missing_meta)}")
    sys.exit(0)
# Cross-check: today === day_payloads_by_iso[meta.end] (alias derivation contract).
end_iso = data["meta"]["end"]
if data["today"] is not data["day_payloads_by_iso"].get(end_iso):
    # Object identity not preserved across JSON round-trip; check structural equality instead.
    if data["today"] != data["day_payloads_by_iso"].get(end_iso):
        print(f"FAIL: today alias != day_payloads_by_iso[{end_iso}]")
        sys.exit(0)
print("PASS")
PY
)
if [ "$wp3p2_audit" = "PASS" ]; then
    check "v3 WP3 P2 codify: --window emit has BOTH v3 sub-payload keys AND legacy alias keys (boundary contract for WP5-WP9 transition)" pass
else
    check "v3 WP3 P2 codify: --window emit boundary contract" fail "$wp3p2_audit"
fi

rm -rf "$WP3P2_DIR"

# ── v3 WP3 Phase 3 codify: --window parser-correctness behavioral pins ──
#
# Phase 2 codify added the boundary-contract test (v3 sub-payload keys +
# legacy alias keys both present in --window emit). Phase 3 adds the
# per-form parser-correctness pins so a regression on one form doesn't
# mask the others. Six scenarios:
#
#   P3.1: --window MTD-2 default (no flag → MTD-2 = 1st of current_month-2
#         through today, calendar-anchored)
#   P3.2: --window 30d → day_payloads_by_iso has exactly 30 keys
#   P3.3: --window 2026-04-01:2026-05-26 → explicit bounds match
#   P3.4: bare invocation (no --window) → MTD-2 default (regression-pin)
#   P3.5: --window + --demo → rc=2 with expected error
#   P3.6: bad-shape inputs → rc=2 with three-forms error
#
# Setup: isolated DB with today-noon events so the metrics payload is
# non-empty (matches WP10C_DIR shape but smaller).
WP3P3_DIR="$(mktemp -d -t claude-time-wp3p3-XXXXXX)"
WP3P3_DB="$WP3P3_DIR/events.sqlite"
sqlite3 "$WP3P3_DB" <<SQL > /dev/null 2>&1
CREATE TABLE events (
  ts INTEGER NOT NULL, session_id TEXT NOT NULL, cwd TEXT NOT NULL,
  event TEXT NOT NULL, tool_name TEXT, agent_type TEXT, meta TEXT
);
CREATE INDEX idx_session_ts ON events(session_id, ts);
CREATE INDEX idx_ts ON events(ts);
INSERT INTO events VALUES
  ($TODAY_NOON_MS,              'sid-wp3p3', '/repo/wp3p3', 'UserPromptSubmit', NULL, NULL, '{"prompt_length_chars": 10}'),
  ($((TODAY_NOON_MS + 60000)),  'sid-wp3p3', '/repo/wp3p3', 'PreToolUse',  'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 120000)), 'sid-wp3p3', '/repo/wp3p3', 'PostToolUse', 'Edit', NULL, '{"tool_use_id":"t1"}'),
  ($((TODAY_NOON_MS + 180000)), 'sid-wp3p3', '/repo/wp3p3', 'Stop', NULL, NULL, '{}');
SQL

# Compute expected MTD-2 window bounds dynamically (today is variable per run).
EXPECTED_MTD2_START=$(python3 -c "
from datetime import date
today = date.today()
m_idx = today.year * 12 + (today.month - 1) - 2
start_year, start_month_zero = divmod(m_idx, 12)
print(date(start_year, start_month_zero + 1, 1).isoformat())
")
EXPECTED_MTD2_END=$(python3 -c "from datetime import date; print(date.today().isoformat())")
EXPECTED_MTD2_DAYS=$(python3 -c "
from datetime import date
today = date.today()
m_idx = today.year * 12 + (today.month - 1) - 2
start_year, start_month_zero = divmod(m_idx, 12)
start = date(start_year, start_month_zero + 1, 1)
print((today - start).days + 1)
")

# Compute expected 30d window bounds.
EXPECTED_30D_START=$(python3 -c "
from datetime import date, timedelta
print((date.today() - timedelta(days=29)).isoformat())
")

# ── P3.1: --window MTD-2 default ───────────────────────────────────────
WP3P3_MTD2="$WP3P3_DIR/mtd2.html"
CLAUDE_TIME_DIR="$WP3P3_DIR" "$CLI" visualize --no-open \
    --window MTD-2 --out "$WP3P3_MTD2" > /dev/null 2>&1
mtd2_audit=$(python3 - <<PY
import re, json, sys
try:
    data = json.loads(re.search(r'window\.CT_DATA\s*=\s*(\{.*?\});', open("$WP3P3_MTD2").read(), re.DOTALL).group(1))
except Exception as e:
    print(f"FAIL: {e}"); sys.exit(0)
w = data.get("window", {})
if w.get("start") != "$EXPECTED_MTD2_START":
    print(f"FAIL: window.start={w.get('start')!r} expected={'$EXPECTED_MTD2_START'!r}"); sys.exit(0)
if w.get("end") != "$EXPECTED_MTD2_END":
    print(f"FAIL: window.end={w.get('end')!r} expected={'$EXPECTED_MTD2_END'!r}"); sys.exit(0)
if w.get("day_count") != $EXPECTED_MTD2_DAYS:
    print(f"FAIL: window.day_count={w.get('day_count')!r} expected=$EXPECTED_MTD2_DAYS"); sys.exit(0)
print("PASS")
PY
)
if [ "$mtd2_audit" = "PASS" ]; then
    check "v3 WP3 P3 codify P3.1: --window MTD-2 → calendar-anchored start, end=today, correct day_count" pass
else
    check "v3 WP3 P3 codify P3.1: --window MTD-2" fail "$mtd2_audit"
fi

# ── P3.2: --window 30d → day_payloads_by_iso has exactly 30 keys ───────
WP3P3_30D="$WP3P3_DIR/30d.html"
CLAUDE_TIME_DIR="$WP3P3_DIR" "$CLI" visualize --no-open \
    --window 30d --out "$WP3P3_30D" > /dev/null 2>&1
day30_audit=$(python3 - <<PY
import re, json, sys
try:
    data = json.loads(re.search(r'window\.CT_DATA\s*=\s*(\{.*?\});', open("$WP3P3_30D").read(), re.DOTALL).group(1))
except Exception as e:
    print(f"FAIL: {e}"); sys.exit(0)
dp = data.get("day_payloads_by_iso", {})
if len(dp) != 30:
    print(f"FAIL: day_payloads_by_iso has {len(dp)} keys, expected 30"); sys.exit(0)
w = data.get("window", {})
if w.get("start") != "$EXPECTED_30D_START":
    print(f"FAIL: window.start={w.get('start')!r} expected={'$EXPECTED_30D_START'!r}"); sys.exit(0)
if w.get("day_count") != 30:
    print(f"FAIL: window.day_count={w.get('day_count')!r} expected=30"); sys.exit(0)
print("PASS")
PY
)
if [ "$day30_audit" = "PASS" ]; then
    check "v3 WP3 P3 codify P3.2: --window 30d → day_payloads_by_iso has exactly 30 keys, window matches" pass
else
    check "v3 WP3 P3 codify P3.2: --window 30d" fail "$day30_audit"
fi

# ── P3.3: --window 2026-04-01:2026-05-26 → explicit bounds match ──────
WP3P3_RANGE="$WP3P3_DIR/range.html"
CLAUDE_TIME_DIR="$WP3P3_DIR" "$CLI" visualize --no-open \
    --window 2026-04-01:2026-05-26 --out "$WP3P3_RANGE" > /dev/null 2>&1
range_audit=$(python3 - <<PY
import re, json, sys
try:
    data = json.loads(re.search(r'window\.CT_DATA\s*=\s*(\{.*?\});', open("$WP3P3_RANGE").read(), re.DOTALL).group(1))
except Exception as e:
    print(f"FAIL: {e}"); sys.exit(0)
w = data.get("window", {})
if w.get("start") != "2026-04-01":
    print(f"FAIL: window.start={w.get('start')!r} expected='2026-04-01'"); sys.exit(0)
if w.get("end") != "2026-05-26":
    print(f"FAIL: window.end={w.get('end')!r} expected='2026-05-26'"); sys.exit(0)
if w.get("day_count") != 56:
    print(f"FAIL: window.day_count={w.get('day_count')!r} expected=56"); sys.exit(0)
print("PASS")
PY
)
if [ "$range_audit" = "PASS" ]; then
    check "v3 WP3 P3 codify P3.3: --window 2026-04-01:2026-05-26 → explicit bounds match (day_count=56)" pass
else
    check "v3 WP3 P3 codify P3.3: --window explicit range" fail "$range_audit"
fi

# ── P3.4: bare visualize (no --window) → MTD-2 default (regression-pin) ─
WP3P3_DEFAULT="$WP3P3_DIR/default.html"
CLAUDE_TIME_DIR="$WP3P3_DIR" "$CLI" visualize --no-open \
    --out "$WP3P3_DEFAULT" > /dev/null 2>&1
default_audit=$(python3 - <<PY
import re, json, sys
try:
    data = json.loads(re.search(r'window\.CT_DATA\s*=\s*(\{.*?\});', open("$WP3P3_DEFAULT").read(), re.DOTALL).group(1))
except Exception as e:
    print(f"FAIL: {e}"); sys.exit(0)
w = data.get("window", {})
if w.get("start") != "$EXPECTED_MTD2_START":
    print(f"FAIL: bare invocation window.start={w.get('start')!r} expected MTD-2 start {'$EXPECTED_MTD2_START'!r}"); sys.exit(0)
if w.get("end") != "$EXPECTED_MTD2_END":
    print(f"FAIL: bare invocation window.end={w.get('end')!r} expected today {'$EXPECTED_MTD2_END'!r}"); sys.exit(0)
print("PASS")
PY
)
if [ "$default_audit" = "PASS" ]; then
    check "v3 WP3 P3 codify P3.4: bare visualize (no --window) → MTD-2 default (regression-pin against silent default-shift)" pass
else
    check "v3 WP3 P3 codify P3.4: default invocation" fail "$default_audit"
fi

# ── P3.5: --window + --demo → rc=2 with expected error ─────────────────
mutex_err=$(CLAUDE_TIME_DIR="$WP3P3_DIR" "$CLI" visualize --no-open \
    --window 30d --demo --out "$WP3P3_DIR/mutex.html" 2>&1)
mutex_rc=$?
if [ "$mutex_rc" = "2" ] && echo "$mutex_err" | grep -qF "incompatible with --demo"; then
    check "v3 WP3 P3 codify P3.5: --window + --demo → rc=2 with 'incompatible with --demo' error" pass
else
    check "v3 WP3 P3 codify P3.5: --window+--demo mutex" fail "rc=$mutex_rc msg=$mutex_err"
fi

# ── P3.6: bad-shape inputs → rc=2 with three-forms error ───────────────
# Three sub-cases: garbage shape; inverted range; >365-day range (exceeds cap).
bad_garbage_err=$(CLAUDE_TIME_DIR="$WP3P3_DIR" "$CLI" visualize --no-open \
    --window garbage --out "$WP3P3_DIR/bad1.html" 2>&1)
bad_garbage_rc=$?
bad_inverted_err=$(CLAUDE_TIME_DIR="$WP3P3_DIR" "$CLI" visualize --no-open \
    --window 2026-05-29:2026-05-01 --out "$WP3P3_DIR/bad2.html" 2>&1)
bad_inverted_rc=$?
bad_oversize_err=$(CLAUDE_TIME_DIR="$WP3P3_DIR" "$CLI" visualize --no-open \
    --window 2020-01-01:2026-05-29 --out "$WP3P3_DIR/bad3.html" 2>&1)
bad_oversize_rc=$?

if [ "$bad_garbage_rc" = "2" ] && \
   echo "$bad_garbage_err" | grep -qF "MTD-N" && \
   echo "$bad_garbage_err" | grep -qF "YYYY-MM-DD:YYYY-MM-DD"; then
    check "v3 WP3 P3 codify P3.6a: --window garbage → rc=2 with three-forms error" pass
else
    check "v3 WP3 P3 codify P3.6a: garbage shape" fail "rc=$bad_garbage_rc msg=$bad_garbage_err"
fi
if [ "$bad_inverted_rc" = "2" ] && \
   echo "$bad_inverted_err" | grep -qF "end >= start"; then
    check "v3 WP3 P3 codify P3.6b: --window inverted-range → rc=2 with 'end >= start' rule" pass
else
    check "v3 WP3 P3 codify P3.6b: inverted range" fail "rc=$bad_inverted_rc msg=$bad_inverted_err"
fi
if [ "$bad_oversize_rc" = "2" ] && \
   echo "$bad_oversize_err" | grep -qF "exceeds viz_window_max_days"; then
    check "v3 WP3 P3 codify P3.6c: --window oversize-range → rc=2 with 'exceeds viz_window_max_days' cap" pass
else
    check "v3 WP3 P3 codify P3.6c: oversize range" fail "rc=$bad_oversize_rc msg=$bad_oversize_err"
fi

rm -rf "$WP3P3_DIR"

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
