#!/usr/bin/env bash
# verify.sh — Verification functions for workflow transition tests
# Sources by run-tests.sh; not invoked directly.

# verify_result <result_text> <expected_id> <contains_any_csv> <not_contains_csv>
# Returns: 0=PASS, 1=SOFT_PASS, 2=FAIL
# Sets global: VERIFY_DETAIL with explanation
verify_result() {
  local result_text="$1"
  local expected_id="$2"
  local contains_any="$3"    # pipe-separated: "/task-act|task-act"
  local not_contains="$4"    # pipe-separated: "/feature-spec|/feature-research"

  VERIFY_DETAIL=""
  local found_transition=""
  local negative_hits=""

  # 1. Structured check: look for TRANSITION: <id>
  found_transition=$(echo "$result_text" | sed -n 's/.*TRANSITION:[[:space:]]*\([A-Za-z0-9_]*\).*/\1/p' | head -1)

  # 2. Negative check
  if [ -n "$not_contains" ]; then
    IFS='|' read -ra NC_ARRAY <<< "$not_contains"
    for nc in "${NC_ARRAY[@]}"; do
      if echo "$result_text" | grep -qi "$nc"; then
        negative_hits="${negative_hits}${nc}, "
      fi
    done
  fi

  # 3. Evaluate
  if [ "$found_transition" = "$expected_id" ]; then
    if [ -n "$negative_hits" ]; then
      VERIFY_DETAIL="Structured match on $expected_id but also mentioned: ${negative_hits%%, }"
      return 0  # Still PASS — structured match is authoritative
    fi
    VERIFY_DETAIL="Structured match: TRANSITION: $found_transition"
    return 0  # PASS
  fi

  # No structured match — try contains check
  if [ -n "$contains_any" ]; then
    IFS='|' read -ra CA_ARRAY <<< "$contains_any"
    for ca in "${CA_ARRAY[@]}"; do
      if echo "$result_text" | grep -qi "$ca"; then
        if [ -n "$negative_hits" ]; then
          VERIFY_DETAIL="Contains '$ca' but also mentioned: ${negative_hits%%, }"
        else
          VERIFY_DETAIL="Contains '$ca' (no structured TRANSITION line)"
        fi
        return 1  # SOFT_PASS
      fi
    done
  fi

  # Nothing matched
  if [ -n "$found_transition" ]; then
    VERIFY_DETAIL="Wrong transition: found $found_transition, expected $expected_id"
  else
    VERIFY_DETAIL="No transition signal found. Expected $expected_id or contains: $contains_any"
  fi
  return 2  # FAIL
}

# parse_scenario_field <yaml_file> <scenario_index> <field>
# Uses python3 to extract fields from YAML (lightweight, no pip deps)
parse_scenario_field() {
  local yaml_file="$1"
  local index="$2"
  local field="$3"

  python3 -c "
import yaml, sys, json
with open('$yaml_file') as f:
    data = yaml.safe_load(f)
scenarios = data.get('scenarios', [])
if $index >= len(scenarios):
    sys.exit(1)
val = scenarios[$index].get('$field', '')
if isinstance(val, list):
    print('|'.join(str(v) for v in val))
elif isinstance(val, dict):
    print(json.dumps(val))
else:
    print(str(val) if val else '')
"
}

# parse_scenario_nested <yaml_file> <scenario_index> <parent> <field>
parse_scenario_nested() {
  local yaml_file="$1"
  local index="$2"
  local parent="$3"
  local field="$4"

  python3 -c "
import yaml, sys
with open('$yaml_file') as f:
    data = yaml.safe_load(f)
scenarios = data.get('scenarios', [])
if $index >= len(scenarios):
    sys.exit(1)
parent_val = scenarios[$index].get('$parent', {})
if not isinstance(parent_val, dict):
    print('')
    sys.exit(0)
val = parent_val.get('$field', '')
if isinstance(val, list):
    print('|'.join(str(v) for v in val))
else:
    print(str(val) if val else '')
"
}

# count_scenarios <yaml_file>
count_scenarios() {
  local yaml_file="$1"
  python3 -c "
import yaml
with open('$yaml_file') as f:
    data = yaml.safe_load(f)
print(len(data.get('scenarios', [])))
"
}
