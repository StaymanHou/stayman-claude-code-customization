#!/usr/bin/env bash
# verify.sh — Verification functions for workflow transition tests
# Sources by run-tests.sh; not invoked directly.

# verify_result <result_text> <expected_id> <contains_any_csv> <not_contains_csv> [<expected_id_any_csv>] [<not_contains_strict>] [<contains_required_csv>] [<contains_required_any_csv>]
# (The `_csv` suffix on multi-value args is historical — separator is the pipe `|`, not comma.)
# Returns: 0=PASS, 1=SOFT_PASS, 2=FAIL
# Sets global: VERIFY_DETAIL with explanation
#
# Args:
#   expected_id            single ID match (existing); may be empty when expected_id_any is used
#   contains_any           pipe-separated content matchers (existing) — used as soft-pass fallback only
#   not_contains           pipe-separated negative content matchers (existing)
#   expected_id_any        pipe-separated alternate IDs that all count as PASS (for dual-identity scenarios)
#   not_contains_strict    "true" → any not_contains hit FAILs the test (opt-in; default lenient preserves prior behavior)
#   contains_required      pipe-separated strings — ALL must appear in result_text (AND-fanout); enforced even on transition_id match
#   contains_required_any  pipe-separated strings — AT LEAST ONE must appear in result_text (OR-fanout); enforced even on transition_id match
#
# contains_required* differs from contains_any: the latter is soft-pass fallback (only consulted when the structured
# ID match is absent); the former are HARD assertions on content presence, evaluated after the ID match passes.
# Empty defaults preserve all prior behavior — existing scenarios are unaffected.
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
  local contains_required="${7:-}"
  local contains_required_any="${8:-}"

  VERIFY_DETAIL=""
  local found_transition=""
  local negative_hits=""

  # 1. Structured check: look for TRANSITION: <id>
  # Tolerances built into this pipeline:
  #   - Markdown bold decoration anywhere on the line — `tr -d '*'` strips ALL
  #     asterisks before capture. Handles `**TRANSITION: ID**` (leading+trailing),
  #     `**TRANSITION:** ID` (prefix-only — was already handled), and crucially
  #     `**TRANSITION: DEBUG**-TELEMETRY-INCONCLUSIVE` (mid-token bold-end, which
  #     the prior `[*[:space:]]*` prefix-only tolerance could NOT handle).
  #     `*` is not a valid character in any F/I/T/P/S/DEBUG token, so stripping
  #     it globally only widens accepted shapes — never invents new matches.
  #   - Hyphens in the ID — captures `DEBUG-BISECT-SKIP` as well as `F1`, `T2`
  #     (debug-* sidebar tokens are hyphenated; legacy IDs are alphanumeric+_).
  #   - Multiple TRANSITION emits per output — `tail -1` picks the LAST emit,
  #     which is the terminal signal. `debug-empirical-telemetry` intentionally
  #     emits `TRANSITION: DEBUG-TELEMETRY-START` mid-procedure (§1 gate-met
  #     informational) before the terminal token (`DEBUG-TELEMETRY-COMPLETE` or
  #     `DEBUG-TELEMETRY-INCONCLUSIVE`). `head -1` would pick START; we want the
  #     terminal one. Single-emit scenarios converge — `head -1` and `tail -1`
  #     return the same thing.
  found_transition=$(echo "$result_text" | tr -d '*' | sed -n 's/.*TRANSITION:[[:space:]]*\([A-Za-z0-9_-]*\).*/\1/p' | tail -1)

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

  # 4. Required-content checks (hard assertions, evaluated after ID match)
  # contains_required: every string must appear (AND). First miss → FAIL.
  # contains_required_any: at least one string must appear (ANY). All miss → FAIL.
  # Both run before PASS is returned, so a clean ID match alone is no longer authoritative
  # when these are set. Takes precedence over the lenient not_contains warning path —
  # missing required content is always FAIL, never SOFT_PASS.
  if [ "$id_match" = true ]; then
    if [ -n "$contains_required" ]; then
      local missing_required=""
      IFS='|' read -ra CR_ARRAY <<< "$contains_required"
      for cr in "${CR_ARRAY[@]}"; do
        if ! echo "$result_text" | grep -qi "$cr"; then
          missing_required="${missing_required}${cr}, "
        fi
      done
      if [ -n "$missing_required" ]; then
        VERIFY_DETAIL="Structured match on $match_label but required content missing: ${missing_required%%, }"
        return 2  # FAIL — required content absent
      fi
    fi
    if [ -n "$contains_required_any" ]; then
      local any_match=false
      IFS='|' read -ra CRA_ARRAY <<< "$contains_required_any"
      for cra in "${CRA_ARRAY[@]}"; do
        if echo "$result_text" | grep -qi "$cra"; then
          any_match=true
          break
        fi
      done
      if [ "$any_match" = false ]; then
        VERIFY_DETAIL="Structured match on $match_label but required-any content missing — none of: $contains_required_any"
        return 2  # FAIL — none of the required-any strings present
      fi
    fi
  fi

  # 5. Evaluate ID match
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
