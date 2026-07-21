#!/usr/bin/env bash
# run-tests.sh — Test runner for workflow state machine transitions
# Invokes Claude Code skills via --print and verifies correct transitions.
#
# Usage:
#   ./tests/run-tests.sh                              # All tests (haiku default; per-scenario `model:` tag honored)
#   ./tests/run-tests.sh --group task                 # One workflow group
#   ./tests/run-tests.sh --id T2                      # Single transition
#   ./tests/run-tests.sh --id T2,T3,F9                # Multiple IDs
#   ./tests/run-tests.sh --dry-run                    # Show what would run
#   ./tests/run-tests.sh --model sonnet               # Force sonnet for ALL scenarios (overrides per-scenario tags)
#   ./tests/run-tests.sh --filter-model default       # Only scenarios with no `model:` tag
#   ./tests/run-tests.sh --filter-model sonnet        # Only scenarios tagged `model: sonnet`
#
# Tip: for routine sweeps, prefer ./tests/run-all.sh — it runs the haiku and
# sonnet partitions in sequence with the right model for each, optimizing cost.

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
FILTER_MODEL=""        # If set: only run scenarios whose `model:` field equals this value (or, with "default", scenarios that have no `model:` field). Used by tests/run-all.sh to partition haiku vs sonnet passes.
DRY_RUN=false
MODEL="haiku"
MODEL_EXPLICIT=false   # Set true when --model is passed; signals that global flag overrides per-scenario `model:` tags
MAX_BUDGET="0.20"
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
    --filter-model) FILTER_MODEL="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --model)   MODEL="$2"; MODEL_EXPLICIT=true; shift 2 ;;
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

  # --- Cheap pre-parse filter (SURFACE-2026-07-15 fix) ---
  # Parse ONLY the `id` first and apply --id / --filter-model BEFORE the ~20 expensive
  # parse_scenario_field/parse_scenario_nested shell-outs below. Each of those spawns a
  # fresh python3 that re-reads+re-parses the WHOLE yaml, so for a targeted `--id A,B` run
  # over a large group (session.yaml = 33 scenarios) the old parse-then-filter cost ~22
  # full-file parses per NON-matching scenario — the >5min hang that blocked WP5's S26/S27
  # and forced deferred behavioral execution. With this gate a filtered-out scenario pays
  # exactly ONE parse (its id) then returns.  --group and no-filter paths are unaffected:
  # with no --id and no --filter-model, nothing short-circuits and every scenario proceeds
  # exactly as before.
  local id; id=$(parse_scenario_field "$yaml_file" "$index" "id")
  if [ -n "$FILTER_IDS" ]; then
    if ! echo ",$FILTER_IDS," | grep -q ",$id,"; then
      return
    fi
  fi
  # --filter-model also gates on a single cheap field (`model:`) — hoist it too so a
  # partitioned run (tests/run-all.sh) skips non-matching scenarios before the heavy parses.
  if [ -n "$FILTER_MODEL" ]; then
    local _pre_model; _pre_model=$(parse_scenario_field "$yaml_file" "$index" "model")
    if [ "$FILTER_MODEL" = "default" ]; then
      [ -n "$_pre_model" ] && return
    else
      [ "$_pre_model" != "$FILTER_MODEL" ] && return
    fi
  fi

  local name; name=$(parse_scenario_field "$yaml_file" "$index" "name")
  local skill; skill=$(parse_scenario_field "$yaml_file" "$index" "skill")
  local args; args=$(parse_scenario_field "$yaml_file" "$index" "args")
  local extra_prompt; extra_prompt=$(parse_scenario_field "$yaml_file" "$index" "system_prompt_extra")
  local max_retries; max_retries=$(parse_scenario_field "$yaml_file" "$index" "max_retries")
  local scenario_model; scenario_model=$(parse_scenario_field "$yaml_file" "$index" "model")
  # Per-scenario budget override (USD). Inherently-expensive scenarios (heavy skills
  # that run a full reasoning path — e.g. session-capture's artifact-tracking-
  # policy classification) can hit the global default $MAX_BUDGET (0.20) on attempt 1
  # and get laundered into FLAKY on retry. A per-scenario `budget:` lets such a scenario
  # declare the headroom it needs without inflating every cheap scenario's ceiling.
  # Absent → falls back to the global $MAX_BUDGET below.
  local scenario_budget; scenario_budget=$(parse_scenario_field "$yaml_file" "$index" "budget")

  # Effective model resolution:
  # - If --model was passed explicitly (MODEL_EXPLICIT=true), the global flag wins (overrides any scenario tag).
  # - Otherwise, use the scenario's `model:` field if set, else the default ($MODEL = haiku).
  # This way `tests/run-all.sh` can partition by tag and force the right model per pass via --model,
  # while a developer running `./tests/run-tests.sh --model sonnet` to debug forces sonnet for everything.
  local effective_model
  if [ "$MODEL_EXPLICIT" = "true" ]; then
    effective_model="$MODEL"
  else
    effective_model="${scenario_model:-$MODEL}"
  fi
  local expect_id; expect_id=$(parse_scenario_nested "$yaml_file" "$index" "expect" "transition_id")
  local expect_id_any; expect_id_any=$(parse_scenario_nested "$yaml_file" "$index" "expect" "transition_id_any")
  local contains_any; contains_any=$(parse_scenario_nested "$yaml_file" "$index" "expect" "contains_any")
  local not_contains; not_contains=$(parse_scenario_nested "$yaml_file" "$index" "expect" "not_contains")
  local not_contains_strict; not_contains_strict=$(parse_scenario_nested "$yaml_file" "$index" "expect" "not_contains_strict")
  local contains_required; contains_required=$(parse_scenario_nested "$yaml_file" "$index" "expect" "contains_required")
  local contains_required_any; contains_required_any=$(parse_scenario_nested "$yaml_file" "$index" "expect" "contains_required_any")
  local fixture_wip; fixture_wip=$(parse_scenario_nested "$yaml_file" "$index" "fixtures" "wip")
  local fixture_product_dir; fixture_product_dir=$(parse_scenario_nested "$yaml_file" "$index" "fixtures" "product_dir")
  local fixture_session; fixture_session=$(parse_scenario_nested "$yaml_file" "$index" "fixtures" "session")
  local fixture_backlog; fixture_backlog=$(parse_scenario_nested "$yaml_file" "$index" "fixtures" "backlog")
  local fixture_claude_md; fixture_claude_md=$(parse_scenario_nested "$yaml_file" "$index" "fixtures" "claude_md")

  # NB: --id and --filter-model are applied at the TOP of run_test() (cheap pre-parse gate,
  # SURFACE-2026-07-15 fix) — any scenario reaching here has already passed both filters, so
  # no second filter check is needed. The `scenario_model` parse above is retained only for
  # the effective-model resolution below, not for filtering.

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
  mkdir -p "$tmpdir/.claude" "$tmpdir/workflow-system/state/wip" "$tmpdir/workflow-system/product"
  # Honor a per-scenario fixtures.claude_md (path relative to tests/, like the other
  # fixture keys) when it names an existing file; otherwise fall back to the default
  # fixtures/CLAUDE.md. Guarded with [ -f ] like the sibling fixture keys so a missing
  # or malformed value degrades to the default instead of copying nothing.
  if [ -n "$fixture_claude_md" ] && [ -f "$SCRIPT_DIR/$fixture_claude_md" ]; then
    cp "$SCRIPT_DIR/$fixture_claude_md" "$tmpdir/CLAUDE.md" 2>/dev/null || true
  else
    cp "$FIXTURES_DIR/CLAUDE.md" "$tmpdir/CLAUDE.md" 2>/dev/null || true
  fi

  # Copy settings fixture into tmpdir/.claude/ and pass it via --settings.
  # --settings *merges on top of* the user's ~/.claude/settings.json (it does
  # not replace it). We rely on this merge to override only the fields where
  # tests want different behaviour from the developer's live config — primarily
  # the live runtime hook entries (claude-time, claudesk), which we empty or
  # trim here so test runs don't fire host-specific machinery. We deliberately
  # do NOT pass --setting-sources project,local
  # to fully replace user settings: that path also strips access to user-level
  # skills (~/.claude/skills/), and the skills under test live there. The drift
  # check in check-structure.sh enforces that the fixture stays a near-clone of
  # live settings so the merge produces predictable behaviour.
  local settings_fixture="$FIXTURES_DIR/settings.json"
  if [ -f "$settings_fixture" ]; then
    cp "$settings_fixture" "$tmpdir/.claude/settings.json"
  fi

  if [ -n "$fixture_wip" ] && [ -f "$SCRIPT_DIR/$fixture_wip" ]; then
    cp "$SCRIPT_DIR/$fixture_wip" "$tmpdir/workflow-system/state/wip/"
  fi

  if [ -n "$fixture_product_dir" ] && [ -d "$SCRIPT_DIR/$fixture_product_dir" ]; then
    cp "$SCRIPT_DIR/$fixture_product_dir"/*.md "$tmpdir/workflow-system/product/" 2>/dev/null || true
  fi

  if [ -n "$fixture_session" ] && [ -f "$SCRIPT_DIR/$fixture_session" ]; then
    cp "$SCRIPT_DIR/$fixture_session" "$tmpdir/workflow-system/state/.session.md"
  fi

  if [ -n "$fixture_backlog" ] && [ -f "$SCRIPT_DIR/$fixture_backlog" ]; then
    cp "$SCRIPT_DIR/$fixture_backlog" "$tmpdir/workflow-system/state/backlog.md"
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
      --model "$effective_model" \
      --max-budget-usd "${scenario_budget:-$MAX_BUDGET}" \
      --no-session-persistence \
      --permission-mode dontAsk \
      --disallowed-tools "Edit,Write,NotebookEdit" \
      --settings "$tmpdir/.claude/settings.json" \
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

    # Verify — wrap with set +e/-e so verify_result's non-zero return doesn't
    # trip set -e, while still capturing the real return code into rc.
    set +e
    verify_result "$result_text" "$expect_id" "$contains_any" "$not_contains" "$expect_id_any" "$not_contains_strict" "$contains_required" "$contains_required_any"
    local rc=$?
    set -e
    detail="$VERIFY_DETAIL"
    # Display-only capture for logging — kept consistent with verify.sh:39
    # (tr -d '*' strips markdown bold; hyphen in capture class accepts DEBUG-*
    # tokens; tail -1 picks the terminal emit when a skill emits multiple).
    transition_found=$(echo "$result_text" | tr -d '*' | sed -n 's/.*TRANSITION:[[:space:]]*\([A-Za-z0-9_-]*\).*/\1/p' | tail -1) || true

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
    --arg model "$effective_model" \
    '{id:$id, name:$name, group:$group, status:$status, attempts:$attempts,
      cost_usd:$cost, duration_ms:$duration, transition_found:$transition, details:$detail, model:$model}')
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
