#!/usr/bin/env bash
# Privacy assertion for tools/claude-time/hook.pl.
#
# The spec's privacy invariant: the hook MUST NOT record prompt text or tool
# input/output content in the DB. It MAY record:
#   - prompt LENGTH (UserPromptSubmit.meta.prompt_length_chars)
#   - tool NAME and tool_use_id (PreToolUse / PostToolUse columns + meta)
#   - notification message (Notification.meta.message, truncated to 200)
#
# This script seeds events with a distinctive marker in fields that MUST NOT
# be recorded, then asserts the marker is absent from the DB binary. If it
# finds the marker, the privacy invariant is broken — exit 1.
#
# Same assertion lives as one of many in test_hook.sh; this standalone script
# is single-purpose for run-on-demand privacy regression checks.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
HOOK="$REPO_ROOT/tools/claude-time/hook.pl"

TMPDIR="$(mktemp -d -t claude-time-privacy-XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

export CLAUDE_TIME_DIR="$TMPDIR"
export CLAUDE_TIME_TRACKING=1

MARKER="PRIVACY-MARKER-9f8e7d6c5b4a3210-DO-NOT-LEAK"

# Seed 1: UserPromptSubmit with the marker AS the prompt text.
echo "{\"hook_event_name\":\"UserPromptSubmit\",\"session_id\":\"s\",\"prompt\":\"$MARKER hello world\"}" \
    | "$HOOK"

# Seed 2: PreToolUse with the marker in tool_input (which the spec says we DO NOT log).
echo "{\"hook_event_name\":\"PreToolUse\",\"session_id\":\"s\",\"tool_name\":\"Bash\",\"tool_use_id\":\"t1\",\"tool_input\":{\"command\":\"$MARKER\"}}" \
    | "$HOOK"

# Seed 3: PostToolUse with the marker in tool_result.
echo "{\"hook_event_name\":\"PostToolUse\",\"session_id\":\"s\",\"tool_name\":\"Bash\",\"tool_use_id\":\"t1\",\"tool_result\":{\"output\":\"$MARKER\"}}" \
    | "$HOOK"

DB="$TMPDIR/events.sqlite"

if [ ! -f "$DB" ]; then
    echo "[FAIL] DB file was not created — hook didn't fire"
    exit 1
fi

# Sanity check: the 3 rows should exist (otherwise the test would be silently
# trivial because no rows = nothing to scan).
rows=$(sqlite3 "$DB" 'SELECT count(*) FROM events')
if [ "$rows" != "3" ]; then
    echo "[FAIL] Expected 3 rows, got $rows — handlers may have rejected payloads"
    exit 1
fi

# Sanity check: UserPromptSubmit DID record the LENGTH (so we know the handler
# ran and didn't just skip the payload).
expected_len=$((${#MARKER} + 12))  # "MARKER hello world" — marker + " hello world"
got_len=$(sqlite3 "$DB" "SELECT json_extract(meta, '\$.prompt_length_chars') FROM events WHERE event='UserPromptSubmit'")
if [ "$got_len" != "$expected_len" ]; then
    echo "[FAIL] UserPromptSubmit didn't record prompt length (got '$got_len', expected $expected_len)"
    exit 1
fi

# THE CORE ASSERTION: scan all DB-related files (main, WAL, SHM) for the marker.
matches=$(grep -a -l "$MARKER" "$DB" "$DB-wal" "$DB-shm" 2>/dev/null | wc -l | tr -d ' ')

if [ "$matches" = "0" ]; then
    echo "[PASS] Privacy invariant holds"
    echo "  - $rows rows recorded"
    echo "  - UserPromptSubmit length: $got_len (no text)"
    echo "  - marker '$MARKER' is absent from DB binary, WAL, and SHM"
    exit 0
fi

# Marker found — print where, for diagnostics.
echo "[FAIL] PRIVACY LEAK: marker '$MARKER' found in DB binary."
echo
echo "Files containing the marker:"
grep -a -l "$MARKER" "$DB" "$DB-wal" "$DB-shm" 2>/dev/null
echo
echo "Context around first occurrence:"
grep -a -o ".\{40\}$MARKER.\{40\}" "$DB" "$DB-wal" "$DB-shm" 2>/dev/null | head -3
echo
echo "Check the UserPromptSubmit, PreToolUse, and PostToolUse handlers in hook.pl —"
echo "one of them is embedding payload content where the spec forbids it."
exit 1
