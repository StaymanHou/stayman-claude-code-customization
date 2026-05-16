#!/usr/bin/env bash
# capture-session-slice.sh — Extract a slice of a Claude Code session log,
# rewrite sessionId fields to a fresh uuid, apply Tier-1 PII/secret redaction,
# and prepare the slice + diff sidecar for human Tier-2 audit before commit.
#
# Usage:
#   tools/capture-session-slice.sh \
#     --source <path to ~/.claude/projects/<slug>/<session>.jsonl> \
#     --terminator-uuid <uuid of last message to include, inclusive> \
#     --output <tests/sessions/<descriptive-name>.jsonl> \
#     --name <descriptive-name>
#
# Outputs (relative to repo root):
#   tests/sessions/<name>.jsonl            — redacted slice (commit-ready after Tier-2 audit)
#   tests/sessions/<name>.redactions.diff  — side-by-side record of Tier-1 redactions
#
# Tier-1 patterns automatically redacted (replaced with [REDACTED-<KIND>]):
#   - Anthropic API keys      (sk-ant-...)
#   - OpenAI keys             (sk-..., sk-proj-...)
#   - GitHub PATs             (ghp_..., github_pat_...)
#   - AWS access keys         (AKIA...)
#   - Stripe keys             (sk_live_..., whsec_...)
#   - Google API keys         (AIza...)
#   - SendGrid keys           (SG.<22>.<43>)
#   - Slack tokens            (xoxp/b/o/a/r/s-...)
#   - JWTs                    (eyJ...)
#   - Facebook tokens         (EAAA.../EAACEdEose0cBA...)
#   - Private key BEGIN lines (-----BEGIN ... PRIVATE KEY-----)
#
# After this script runs, the human MUST:
#   1. Read the slice + diff side-by-side
#   2. Apply Tier-2 manual edits (see tests/sessions/README.md)
#   3. Append a signoff line to tests/sessions/AUDIT-LOG.md
#   4. Only then `git add` the slice + diff + audit-log
#
# Exit codes:
#   0  — slice captured and Tier-1 redacted successfully
#   1  — argument error or input not found
#   2  — terminator uuid not found in source
#   3  — output path already exists (refuse to overwrite without explicit removal)

set -euo pipefail

# --- Parse args ---
SRC=""
TERMINATOR=""
OUT=""
NAME=""

usage() {
  # First arg: exit code. Explicit --help passes 0; argument errors pass 1.
  local code="${1:-1}"
  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
  exit "$code"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)          SRC="$2"; shift 2 ;;
    --terminator-uuid) TERMINATOR="$2"; shift 2 ;;
    --output)          OUT="$2"; shift 2 ;;
    --name)            NAME="$2"; shift 2 ;;
    -h|--help)         usage 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage 1 ;;
  esac
done

# Validate required args
if [ -z "$SRC" ]; then echo "ERROR: missing --source argument" >&2; usage 1; fi
if [ -z "$TERMINATOR" ]; then echo "ERROR: missing --terminator-uuid argument" >&2; usage 1; fi
if [ -z "$OUT" ]; then echo "ERROR: missing --output argument" >&2; usage 1; fi
if [ -z "$NAME" ]; then echo "ERROR: missing --name argument" >&2; usage 1; fi

# Validate source exists
if [ ! -f "$SRC" ]; then
  echo "ERROR: source not found: $SRC" >&2
  exit 1
fi

# Refuse to overwrite existing output (safety: prevents silently clobbering an already-audited file)
if [ -e "$OUT" ]; then
  echo "ERROR: output already exists: $OUT" >&2
  echo "       Remove it explicitly if you intend to re-capture:" >&2
  echo "         rm $OUT ${OUT%.jsonl}.redactions.diff" >&2
  exit 3
fi

DIFF_OUT="${OUT%.jsonl}.redactions.diff"

# Validate terminator uuid is present in source
if ! grep -q "\"uuid\":\"$TERMINATOR\"" "$SRC"; then
  echo "ERROR: terminator uuid not found in source: $TERMINATOR" >&2
  echo "       (looked in $SRC)" >&2
  exit 2
fi

# Generate fresh session uuid (lowercase)
NEW_SESSION_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')

echo "==> Capturing slice"
echo "    Source:           $SRC"
echo "    Terminator uuid:  $TERMINATOR (inclusive)"
echo "    New sessionId:    $NEW_SESSION_UUID"
echo "    Output:           $OUT"
echo ""

# --- Step 1: extract slice and rewrite sessionId ---
# Pipeline: jq rewrites sessionId on every line → awk truncates after terminator (inclusive).
# Note: awk exits early when it sees the terminator uuid, which causes SIGPIPE on jq's
# write end. That's expected behavior, so we tolerate jq's exit code in this single
# pipeline (SIGPIPE = 141). We re-enable strict mode immediately after.
TMP_RAW=$(mktemp -t slice-raw.XXXXXX.jsonl)
trap 'rm -f "$TMP_RAW"' EXIT

set +o pipefail
jq -c --arg new "$NEW_SESSION_UUID" '
  if .sessionId then .sessionId = $new else . end
' "$SRC" | awk -v term="$TERMINATOR" '
  {print}
  $0 ~ "\"uuid\":\""term"\"" {exit}
' > "$TMP_RAW"
set -o pipefail

SLICE_LINES=$(wc -l < "$TMP_RAW")
SLICE_BYTES=$(wc -c < "$TMP_RAW")
echo "    Slice extracted:  $SLICE_LINES lines, $SLICE_BYTES bytes"

# --- Step 2: Tier-1 redaction ---
# Each pattern: REGEX | KIND
# Order matters slightly — more specific patterns first, so generic catches don't pre-empt them.
# Patterns use extended regex (sed -E).
# Note: \[REDACTED-...\] is the placeholder. We intentionally DO NOT redact patterns
# that look like our own placeholders (avoid re-redacting on idempotent re-runs).

PATTERNS=(
  # Anthropic
  'sk-ant-[A-Za-z0-9_-]{20,}|ANTHROPIC_KEY'
  # OpenAI (project-scoped first — more specific)
  'sk-proj-[A-Za-z0-9_-]{40,}|OPENAI_PROJECT_KEY'
  'sk-[A-Za-z0-9]{32,}|OPENAI_LEGACY_KEY'
  # GitHub (fine-grained first — more specific)
  'github_pat_[A-Za-z0-9_]{82,}|GITHUB_FINE_PAT'
  'ghp_[A-Za-z0-9]{36,}|GITHUB_CLASSIC_PAT'
  # AWS
  'AKIA[0-9A-Z]{16}|AWS_ACCESS_KEY'
  # Stripe
  'sk_live_[0-9a-zA-Z]{24,}|STRIPE_SECRET_KEY'
  'whsec_[A-Za-z0-9]{32,}|STRIPE_WEBHOOK_SECRET'
  # Google
  'AIza[0-9A-Za-z_-]{35}|GOOGLE_API_KEY'
  # SendGrid
  'SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}|SENDGRID_KEY'
  # Slack
  'xox[abprs]-[A-Za-z0-9-]{10,}|SLACK_TOKEN'
  # JWT (note: matches three base64-ish segments separated by dots; conservative length floor)
  'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|JWT'
  # Facebook / Meta
  '(EAAA|EAACEdEose0cBA)[A-Za-z0-9]{20,}|FACEBOOK_TOKEN'
  # Private key BEGIN line (single-line match — content lines are not separately redacted
  # because their structure is meaningless without the BEGIN/END markers, and matching
  # base64 alone would over-redact)
  '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY( BLOCK)?-----|PRIVATE_KEY_BEGIN'
)

# Build a redaction script as a sequence of sed -E -e expressions
SED_ARGS=()
for entry in "${PATTERNS[@]}"; do
  regex="${entry%|*}"
  kind="${entry##*|}"
  # Escape any forward-slashes in the regex for sed's s/// (none in our patterns currently, but defensive)
  SED_ARGS+=(-E -e "s/${regex}/[REDACTED-${kind}]/g")
done

# Apply redaction and write side-by-side diff
sed "${SED_ARGS[@]}" "$TMP_RAW" > "$OUT"

# Build the diff sidecar
{
  echo "# Tier-1 Redactions for: $NAME"
  echo "# Source: $SRC"
  echo "# Captured: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# Slice: $SLICE_LINES lines, $SLICE_BYTES bytes (pre-redaction)"
  echo "# Terminator uuid: $TERMINATOR"
  echo "#"
  echo "# Each entry is a single-line diff: line number in RAW slice, then -RAW / +REDACTED."
  echo "# If no entries follow, no Tier-1 patterns matched."
  echo "# ----------------------------------------------------------------------"
  echo ""

  # diff -u produces a hunk-based diff. For a token-by-token record, we walk both files
  # in parallel and emit changed lines only.
  paste -d $'\t' "$TMP_RAW" "$OUT" | awk -F $'\t' '
    {
      if ($1 != $2) {
        printf "Line %d:\n  -%s\n  +%s\n\n", NR, $1, $2
      }
    }
  '

  # Also count and summarize
  echo ""
  echo "# ----------------------------------------------------------------------"
  echo "# Redactions by kind:"
  for entry in "${PATTERNS[@]}"; do
    kind="${entry##*|}"
    count=$(grep -c "\[REDACTED-${kind}\]" "$OUT" || true)
    if [ "$count" -gt 0 ]; then
      printf "#   %-30s %d\n" "$kind" "$count"
    fi
  done
} > "$DIFF_OUT"

TOTAL_REDACTIONS=$(grep -c '^Line ' "$DIFF_OUT" 2>/dev/null || true)
TOTAL_REDACTIONS=${TOTAL_REDACTIONS:-0}
echo "    Tier-1 redactions: $TOTAL_REDACTIONS"
echo ""

# --- Step 3: prompt human for Tier-2 audit ---
cat <<EOF
==> Tier-1 redaction complete.

    Outputs:
      $OUT
      $DIFF_OUT

==> NEXT STEPS (Tier-2 human audit — DO NOT \`git add\` until done):

    1. Read the slice and diff side-by-side. Walk through tests/sessions/README.md
       for the full Tier-2 checklist.

    2. Apply manual edits to $OUT for any of these (NOT covered by Tier-1):
         - Internal endpoint URLs (real or proprietary-shaped)
         - Project content snippets revealing proprietary logic
         - Non-obvious-secret-shaped strings (custom token formats)
         - OS paths revealing personal identity beyond /Users/stayman
         - Third-party content (names of clients/employers, quoted conversation
           from unrelated projects)

    3. Append a signoff line to tests/sessions/AUDIT-LOG.md:

         $(date -u +%Y-%m-%d) - $(basename "$OUT") - audited by <your-name> - Tier-1 patterns matched: $TOTAL_REDACTIONS - Tier-2 manual edits: <N>

    4. Only after the audit-log entry is in place, stage all three files:

         git add $OUT $DIFF_OUT tests/sessions/AUDIT-LOG.md

    5. Run ./tests/check-structure.sh to verify the audit-log signoff is wired
       correctly (it should be, once Phase 3 of the session-replay-harness feature
       lands).

EOF
