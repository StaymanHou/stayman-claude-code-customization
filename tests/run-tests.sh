#!/usr/bin/env bash
# run-tests.sh — Test runner for workflow state machine transitions
# Invokes Claude Code skills via --print and verifies correct transitions.
#
# Usage:
#   ./tests/run-tests.sh                    # All tests
#   ./tests/run-tests.sh --group task       # One workflow group
#   ./tests/run-tests.sh --id T2            # Single transition
#   ./tests/run-tests.sh --id T2,T3,F9     # Multiple IDs
#   ./tests/run-tests.sh --dry-run          # Show what would run
#   ./tests/run-tests.sh --model sonnet     # Override model (default: haiku)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCENARIOS_DIR="$SCRIPT_DIR/scenarios"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
RESULTS_DIR="$SCRIPT_DIR/results"

source "$SCRIPT_DIR/lib/verify.sh"

# --- Defaults ---
FILTER_GROUP=""
FILTER_IDS=""
DRY_RUN=false
MODEL="haiku"
MAX_BUDGET="0.05"
GLOBAL_RETRY=0  # 0 = use per-scenario setting

# --- Shared testing system prompt ---
SHARED_PROMPT='TESTING MODE — TRANSITION VERIFICATION

You are being tested on whether you select the correct state machine transition.
After your analysis, you MUST include this exact line in your response:

TRANSITION: <id> (<from> → <to>)

For example: TRANSITION: T2 (plan → act)

This line is REQUIRED. Place it near the end of your response, before giving
the user instruction to run the next skill.

Do NOT actually create or modify any files. Do NOT run any commands.
Instead, describe what you WOULD do and which transition you are taking.'

# --- Parse CLI args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --group)   FILTER_GROUP="$2"; shift 2 ;;
    --id)      FILTER_IDS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --model)   MODEL="$2"; shift 2 ;;
    --budget)  MAX_BUDGET="$2"; shift 2 ;;
    --retry)   GLOBAL_RETRY="$2"; shift 2 ;;
    *)         echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# --- Counters ---
TOTAL=0; PASSED=0; SOFT_PASSED=0; FAILED=0; FLAKY=0; SKIPPED=0
TOTAL_COST=0
TOTAL_DURATION=0
FAILURES=""
FLAKY_LIST=""

# --- Results JSON ---
RUN_ID=$(date +%Y-%m-%d-%H%M%S)
RESULTS_FILE="$RESULTS_DIR/run-${RUN_ID}.json"
mkdir -p "$RESULTS_DIR"
echo '{"run_id":"'"$RUN_ID"'","model":"'"$MODEL"'","tests":[' > "$RESULTS_FILE"
FIRST_RESULT=true

append_result() {
  local json="$1"
  if [ "$FIRST_RESULT" = true ]; then
    FIRST_RESULT=false
  else
    echo "," >> "$RESULTS_FILE"
  fi
  echo "$json" >> "$RESULTS_FILE"
}

# --- Run a single test scenario ---
run_test() {
  local yaml_file="$1"
  local index="$2"
  local group="$3"

  local id; id=$(parse_scenario_field "$yaml_file" "$index" "id")
  local name; name=$(parse_scenario_field "$yaml_file" "$index" "name")
  local skill; skill=$(parse_scenario_field "$yaml_file" "$index" "skill")
  local args; args=$(parse_scenario_field "$yaml_file" "$index" "args")
  local extra_prompt; extra_prompt=$(parse_scenario_field "$yaml_file" "$index" "system_prompt_extra")
  local max_retries; max_retries=$(parse_scenario_field "$yaml_file" "$index" "max_retries")
  local expect_id; expect_id=$(parse_scenario_nested "$yaml_file" "$index" "expect" "transition_id")
  local contains_any; contains_any=$(parse_scenario_nested "$yaml_file" "$index" "expect" "contains_any")
  local not_contains; not_contains=$(parse_scenario_nested "$yaml_file" "$index" "expect" "not_contains")
  local fixture_wip; fixture_wip=$(parse_scenario_nested "$yaml_file" "$index" "fixtures" "wip")

  # Apply filters
  if [ -n "$FILTER_IDS" ]; then
    if ! echo ",$FILTER_IDS," | grep -q ",$id,"; then
      return
    fi
  fi

  max_retries=${max_retries:-1}
  [ "$GLOBAL_RETRY" -gt 0 ] && max_retries="$GLOBAL_RETRY"

  TOTAL=$((TOTAL + 1))

  if [ "$DRY_RUN" = true ]; then
    printf "  [DRY] %-6s %-60s skill=/%s\n" "$id" "$name" "$skill"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  printf "  %-6s %s ... " "$id" "$name"

  # Build system prompt
  local full_prompt="$SHARED_PROMPT"
  if [ -n "$extra_prompt" ]; then
    full_prompt="${full_prompt}

${extra_prompt}"
  fi

  # Build temp project dir with fixtures
  local tmpdir; tmpdir=$(mktemp -d)
  mkdir -p "$tmpdir/.claude" "$tmpdir/workflow/wip"
  cp "$FIXTURES_DIR/CLAUDE.md" "$tmpdir/.claude/CLAUDE.md" 2>/dev/null || true

  if [ -n "$fixture_wip" ] && [ -f "$SCRIPT_DIR/$fixture_wip" ]; then
    cp "$SCRIPT_DIR/$fixture_wip" "$tmpdir/workflow/wip/"
  fi

  local attempt=0
  local status="FAIL"
  local detail=""
  local cost=0
  local duration=0
  local transition_found=""

  while [ $attempt -lt "$max_retries" ]; do
    attempt=$((attempt + 1))

    # Invoke claude
    local output
    output=$(cd "$tmpdir" && claude --print "/$skill $args" \
      --output-format json \
      --model "$MODEL" \
      --max-budget-usd "$MAX_BUDGET" \
      --no-session-persistence \
      --permission-mode dontAsk \
      --disallowed-tools "Edit,Write,NotebookEdit" \
      --append-system-prompt "$full_prompt" 2>/dev/null) || true

    # Parse JSON output
    local result_text; result_text=$(echo "$output" | jq -r '.result // empty' 2>/dev/null) || result_text=""
    local run_cost; run_cost=$(echo "$output" | jq -r '.total_cost_usd // 0' 2>/dev/null) || run_cost=0
    local run_duration; run_duration=$(echo "$output" | jq -r '.duration_ms // 0' 2>/dev/null) || run_duration=0

    cost=$(echo "$cost + $run_cost" | bc 2>/dev/null || echo "$cost")
    duration=$((duration + ${run_duration%.*}))

    if [ -z "$result_text" ]; then
      detail="No output from claude (possibly budget exceeded or error)"
      continue
    fi

    # Verify
    verify_result "$result_text" "$expect_id" "$contains_any" "$not_contains"
    local rc=$?
    detail="$VERIFY_DETAIL"
    transition_found=$(echo "$result_text" | sed -n 's/.*TRANSITION:[[:space:]]*\([A-Za-z0-9_]*\).*/\1/p' | head -1) || true

    if [ $rc -eq 0 ]; then
      if [ $attempt -gt 1 ]; then
        status="FLAKY"
      else
        status="PASS"
      fi
      break
    elif [ $rc -eq 1 ]; then
      if [ $attempt -gt 1 ]; then
        status="FLAKY"
      else
        status="SOFT_PASS"
      fi
      break
    fi
    # rc=2 → FAIL, retry if attempts remain
  done

  # Update counters
  case "$status" in
    PASS)      PASSED=$((PASSED + 1)); printf "PASS\n" ;;
    SOFT_PASS) SOFT_PASSED=$((SOFT_PASSED + 1)); printf "SOFT_PASS (%s)\n" "$detail" ;;
    FLAKY)     FLAKY=$((FLAKY + 1)); printf "FLAKY (attempt %d)\n" "$attempt"
               FLAKY_LIST="${FLAKY_LIST}  ${id}: ${name} — ${detail}\n" ;;
    FAIL)      FAILED=$((FAILED + 1)); printf "FAIL (%s)\n" "$detail"
               FAILURES="${FAILURES}  ${id}: ${name} — ${detail}\n" ;;
  esac

  TOTAL_COST=$(echo "$TOTAL_COST + $cost" | bc 2>/dev/null || echo "$TOTAL_COST")
  TOTAL_DURATION=$((TOTAL_DURATION + duration))

  # Append to results JSON
  local result_json
  result_json=$(jq -n \
    --arg id "$id" \
    --arg name "$name" \
    --arg group "$group" \
    --arg status "$status" \
    --argjson attempts "$attempt" \
    --arg cost "$cost" \
    --argjson duration "$duration" \
    --arg transition "$transition_found" \
    --arg detail "$detail" \
    '{id:$id, name:$name, group:$group, status:$status, attempts:$attempts,
      cost_usd:$cost, duration_ms:$duration, transition_found:$transition, details:$detail}')
  append_result "$result_json"

  # Clean up
  rm -rf "$tmpdir"
}

# --- Main ---
echo "=== Workflow Transition Tests ==="
echo "Run: $RUN_ID | Model: $MODEL | Budget/test: \$$MAX_BUDGET"
echo

# Find scenario files
SCENARIO_FILES=()
if [ -n "$FILTER_GROUP" ]; then
  f="$SCENARIOS_DIR/${FILTER_GROUP}.yaml"
  [ -f "$f" ] && SCENARIO_FILES+=("$f") || { echo "No scenario file for group: $FILTER_GROUP"; exit 1; }
else
  for f in "$SCENARIOS_DIR"/*.yaml; do
    [ -f "$f" ] && SCENARIO_FILES+=("$f")
  done
fi

if [ ${#SCENARIO_FILES[@]} -eq 0 ]; then
  echo "No scenario files found in $SCENARIOS_DIR/"
  exit 1
fi

# Track per-group stats for summary (bash 3 compatible — no associative arrays)
GROUP_SUMMARY=""

for yaml_file in "${SCENARIO_FILES[@]}"; do
  group=$(basename "$yaml_file" .yaml)
  count=$(count_scenarios "$yaml_file")

  echo "[$group] ($count scenarios)"

  before_pass=$PASSED; before_soft=$SOFT_PASSED; before_fail=$FAILED; before_flaky=$FLAKY

  for ((i=0; i<count; i++)); do
    run_test "$yaml_file" "$i" "$group"
  done

  g_pass=$((PASSED - before_pass))
  g_soft=$((SOFT_PASSED - before_soft))
  g_fail=$((FAILED - before_fail))
  g_flaky=$((FLAKY - before_flaky))
  g_total=$((g_pass + g_soft + g_fail + g_flaky))
  GROUP_SUMMARY="${GROUP_SUMMARY}${group}|${g_pass}|${g_soft}|${g_fail}|${g_flaky}|${g_total}\n"

  echo
done

# Close results JSON
echo '],"total_tests":'"$TOTAL"',"passed":'"$PASSED"',"soft_passed":'"$SOFT_PASSED"',"failed":'"$FAILED"',"flaky":'"$FLAKY"',"total_cost_usd":"'"$TOTAL_COST"'","total_duration_ms":'"$TOTAL_DURATION"'}' >> "$RESULTS_FILE"

# --- Summary ---
echo "=== Summary ==="
printf "%-12s %5s %5s %5s %5s %5s\n" "GROUP" "PASS" "SOFT" "FAIL" "FLAKY" "TOTAL"
printf "%-12s %5s %5s %5s %5s %5s\n" "────────────" "─────" "─────" "─────" "─────" "─────"

echo -e "$GROUP_SUMMARY" | while IFS='|' read -r g p s f fl t; do
  [ -z "$g" ] && continue
  printf "%-12s %5d %5d %5d %5d %5d\n" "$g" "$p" "$s" "$f" "$fl" "$t"
done

printf "%-12s %5s %5s %5s %5s %5s\n" "────────────" "─────" "─────" "─────" "─────" "─────"
printf "%-12s %5d %5d %5d %5d %5d\n" "TOTAL" "$PASSED" "$SOFT_PASSED" "$FAILED" "$FLAKY" "$TOTAL"
echo
echo "Cost: \$$TOTAL_COST | Duration: $((TOTAL_DURATION / 1000))s | Results: $RESULTS_FILE"

if [ -n "$FAILURES" ]; then
  echo
  echo "FAILURES:"
  echo -e "$FAILURES"
fi

if [ -n "$FLAKY_LIST" ]; then
  echo "FLAKY (passed on retry):"
  echo -e "$FLAKY_LIST"
fi

# Exit with failure count
exit "$FAILED"
