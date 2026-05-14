#!/usr/bin/env bash
# verify.sh — Verification functions for workflow transition tests
# Sources by run-tests.sh; not invoked directly.

# verify_result <result_text> <expected_id> <contains_any_csv> <not_contains_csv> [<expected_id_any_csv>] [<not_contains_strict>]
# Returns: 0=PASS, 1=SOFT_PASS, 2=FAIL
# Sets global: VERIFY_DETAIL with explanation
#
# Args:
#   expected_id          single ID match (existing); may be empty when expected_id_any is used
#   contains_any         pipe-separated content matchers (existing) — used as soft-pass fallback
#   not_contains         pipe-separated negative content matchers (existing)
#   expected_id_any      pipe-separated alternate IDs that all count as PASS (new — for dual-identity scenarios)
#   not_contains_strict  "true" → any not_contains hit FAILs the test (new — opt-in; default lenient preserves prior behavior)
verify_result() {
  local result_text="$1"
  local expected_id="$2"
  local contains_any="$3"
  local not_contains="$4"
  local expected_id_any="${5:-}"
  # Normalize strict flag — Python's True/False from YAML serializes capitalized;
  # "yes"/"on" also accepted for ergonomics. Anything else → false.
  local strict_raw="${6:-false}"
  local not_contains_strict="false"
  case "$(echo "$strict_raw" | tr '[:upper:]' '[:lower:]')" in
    true|yes|on|1) not_contains_strict="true" ;;
  esac

  VERIFY_DETAIL=""
  local found_transition=""
  local negative_hits=""

  # 1. Structured check: look for TRANSITION: <id>
  # Tolerances built into this regex:
  #   - Leading/trailing markdown decoration (e.g. `**TRANSITION:**` from bold-mark)
  #     — strip `*` between colon and the ID, plus any whitespace
  #   - Hyphens in the ID — captures `DEBUG-BISECT-SKIP` as well as `F1`, `T2`
  #     (debug-* sidebar tokens are hyphenated; legacy IDs are alphanumeric+_)
  found_transition=$(echo "$result_text" | sed -n 's/.*TRANSITION:[*[:space:]]*\([A-Za-z0-9_-]*\).*/\1/p' | head -1)

  # 2. Negative check
  if [ -n "$not_contains" ]; then
    IFS='|' read -ra NC_ARRAY <<< "$not_contains"
    for nc in "${NC_ARRAY[@]}"; do
      if echo "$result_text" | grep -qi "$nc"; then
        negative_hits="${negative_hits}${nc}, "
      fi
    done
  fi

  # 3. Build ID match set: union of expected_id and expected_id_any (if set)
  local id_match=false
  local match_label=""
  if [ -n "$found_transition" ]; then
    if [ -n "$expected_id" ] && [ "$found_transition" = "$expected_id" ]; then
      id_match=true
      match_label="$found_transition"
    elif [ -n "$expected_id_any" ]; then
      IFS='|' read -ra ID_ANY_ARRAY <<< "$expected_id_any"
      for eid in "${ID_ANY_ARRAY[@]}"; do
        if [ "$found_transition" = "$eid" ]; then
          id_match=true
          match_label="$found_transition (any-of: $expected_id_any)"
          break
        fi
      done
    fi
  fi

  # 4. Evaluate ID match
  if [ "$id_match" = true ]; then
    if [ -n "$negative_hits" ]; then
      if [ "$not_contains_strict" = "true" ]; then
        VERIFY_DETAIL="Structured match on $match_label but FAILED strict not_contains: ${negative_hits%%, }"
        return 2  # FAIL — strict mode flips on negative hit
      fi
      VERIFY_DETAIL="Structured match on $match_label but also mentioned: ${negative_hits%%, }"
      return 0  # PASS — lenient (default): structured match is authoritative
    fi
    VERIFY_DETAIL="Structured match: TRANSITION: $match_label"
    return 0  # PASS
  fi

  # No structured ID match — try contains check
  if [ -n "$contains_any" ]; then
    IFS='|' read -ra CA_ARRAY <<< "$contains_any"
    for ca in "${CA_ARRAY[@]}"; do
      if echo "$result_text" | grep -qi "$ca"; then
        if [ -n "$negative_hits" ]; then
          if [ "$not_contains_strict" = "true" ]; then
            VERIFY_DETAIL="Contains '$ca' but FAILED strict not_contains: ${negative_hits%%, }"
            return 2  # FAIL — strict mode flips on negative hit even in soft-pass path
          fi
          VERIFY_DETAIL="Contains '$ca' but also mentioned: ${negative_hits%%, }"
        else
          VERIFY_DETAIL="Contains '$ca' (no structured TRANSITION line)"
        fi
        return 1  # SOFT_PASS
      fi
    done
  fi

  # Nothing matched
  local expected_label="$expected_id"
  [ -n "$expected_id_any" ] && expected_label="${expected_label:+$expected_label or any-of: }$expected_id_any"
  if [ -n "$found_transition" ]; then
    VERIFY_DETAIL="Wrong transition: found $found_transition, expected $expected_label"
  else
    VERIFY_DETAIL="No transition signal found. Expected $expected_label or contains: $contains_any"
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
