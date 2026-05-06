#!/usr/bin/env bash
# run-all.sh — Two-pass test runner: haiku for the cheap default partition,
# sonnet for scenarios tagged `model: sonnet` in their YAML.
#
# Process rule: new tests start untagged (haiku). Only escalate a scenario to
# `model: sonnet` after a haiku failure is shown to be model-noise (e.g., the
# scenario PASSes deterministically on sonnet recon).
#
# Usage:
#   ./tests/run-all.sh                  # Both passes, all groups
#   ./tests/run-all.sh --group session  # Both passes, scoped to one group
#
# Forwarding: any flags except --model/--filter-model pass through to run-tests.sh.
# (--model and --filter-model are managed internally by this wrapper.)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"

# Strip any --model / --filter-model the user passed (this wrapper owns them).
FORWARD_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model|--filter-model) shift 2 ;;
    *)                      FORWARD_ARGS+=("$1"); shift ;;
  esac
done

RUN_ID=$(date +%Y-%m-%d-%H%M%S)
COMBINED="$RESULTS_DIR/run-${RUN_ID}-combined.json"

echo "=== run-all.sh — two-pass sweep ==="
echo "Run ID: $RUN_ID"
echo

# --- Pass 1: haiku partition (untagged scenarios) ---
# Note: run-tests.sh exits non-zero on FAIL; we want Pass 2 to run regardless,
# then exit non-zero based on the combined merged result. Hence `|| true`.
echo "[Pass 1/2] haiku — scenarios without a model: tag"
"$SCRIPT_DIR/run-tests.sh" --model haiku --filter-model default "${FORWARD_ARGS[@]}" || true
P1_FILE=$(ls -1t "$RESULTS_DIR"/run-*.json 2>/dev/null | grep -v combined | head -1)
echo "Pass 1 results: $P1_FILE"
echo

# --- Pass 2: sonnet partition (scenarios tagged model: sonnet) ---
echo "[Pass 2/2] sonnet — scenarios tagged model: sonnet"
"$SCRIPT_DIR/run-tests.sh" --model sonnet --filter-model sonnet "${FORWARD_ARGS[@]}" || true
P2_FILE=$(ls -1t "$RESULTS_DIR"/run-*.json 2>/dev/null | grep -v combined | head -1)
echo "Pass 2 results: $P2_FILE"
echo

# --- Merge ---
# Combined JSON: {run_id, passes:[{model, file, summary}], tests:[...all tests with .model annotated]}
jq -n \
  --arg run_id "$RUN_ID" \
  --arg p1_file "$P1_FILE" \
  --arg p2_file "$P2_FILE" \
  --slurpfile p1 "$P1_FILE" \
  --slurpfile p2 "$P2_FILE" \
  '
  ($p1[0].total_cost_usd | tonumber) as $c1 |
  ($p2[0].total_cost_usd | tonumber) as $c2 |
  {
    run_id: $run_id,
    type: "combined",
    passes: [
      { model: $p1[0].model, file: $p1_file, passed: $p1[0].passed, soft_passed: $p1[0].soft_passed, failed: $p1[0].failed, flaky: $p1[0].flaky, total_cost_usd: $p1[0].total_cost_usd },
      { model: $p2[0].model, file: $p2_file, passed: $p2[0].passed, soft_passed: $p2[0].soft_passed, failed: $p2[0].failed, flaky: $p2[0].flaky, total_cost_usd: $p2[0].total_cost_usd }
    ],
    passed:      ($p1[0].passed      + $p2[0].passed),
    soft_passed: ($p1[0].soft_passed + $p2[0].soft_passed),
    failed:      ($p1[0].failed      + $p2[0].failed),
    flaky:       ($p1[0].flaky       + $p2[0].flaky),
    total_cost_usd: ($c1 + $c2),
    tests: ($p1[0].tests + $p2[0].tests)
  }' > "$COMBINED"

echo "=== Combined Summary ==="
jq -r '"PASS:        \(.passed)\nSOFT_PASS:   \(.soft_passed)\nFAIL:        \(.failed)\nFLAKY:       \(.flaky)\nTotal cost:  $\(.total_cost_usd)\n\nPasses:\n  haiku  → \(.passes[0].file)\n  sonnet → \(.passes[1].file)\nCombined:    '"$COMBINED"'"' "$COMBINED"

# Exit non-zero if any failures
FAILED=$(jq -r '.failed' "$COMBINED")
[ "$FAILED" -eq 0 ] || exit 1
