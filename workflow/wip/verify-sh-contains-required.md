---
workflow: feature
state: ship (complete)
drive_mode: autopilot
created: 2026-06-13
---

# Feature: `contains_required` / `contains_required_any` — hard content-presence assertion in verify.sh

## Problem Statement

`tests/lib/verify.sh::verify_result` (lines 70-82 of the pre-feature snapshot, lines 83-94 of current verify.sh) treats a matching `transition_id` as **authoritative PASS** and short-circuits before re-examining `contains_any`. `contains_any` is only consulted as a SOFT_PASS fallback when no `transition_id` match was found. Net effect: today no scenario can hard-assert content presence — if you write `transition_id: X` + `contains_any: [Y, Z]` intending "must emit X AND contain Y or Z," you actually get "emit X (Y and Z are checked only when X is absent)." Confirmed by 2x bite-verification 2026-06-06 in task `codify-randomize-host-ports-test-coverage` (T5): mutating SKILL.md to remove a content bullet didn't break the candidate P10b scenario because the model still emitted `TRANSITION: P10` correctly and the harness short-circuited.

This blocks future scenarios whose only verifiable surface is "the model emits the right downstream prose under a real skill invocation." Structural `grep_check` pins in `tests/check-structure.sh` cover prose-presence-in-file regressions; they do NOT cover prose-presence-in-model-output regressions. Add the missing primitive: `contains_required` (ALL — AND-fanout) + `contains_required_any` (ANY — OR-fanout). When set, even on a `transition_id` match, the listed strings must appear in `result_text` or the scenario FAILs. Backward-compatible — existing scenarios with empty-string defaults preserve all prior behavior, mirroring the `not_contains_strict` and `transition_id_any` extensions shipped 2026-05-06 (`workflow/archive/transition-id-any-and-strict-mode.md`).

## Work Tree

- [x] Phase 1: Harness primitive + plumbing
  **Observable outcomes:**
  - CLI: `bash -c 'source tests/lib/verify.sh; verify_result "TRANSITION: P10\nhost ports are ephemeral" "P10" "" "" "" "false" "" "ephemeral|49152"; echo $?'` → exits `0` (PASS, content matches one of the required-any items)
  - CLI: `bash -c 'source tests/lib/verify.sh; verify_result "TRANSITION: P10" "P10" "" "" "" "false" "" "ephemeral|49152"; echo $?'` → exits `2` (FAIL, transition matches but no required content present); `VERIFY_DETAIL` mentions "contains_required_any"
  - CLI: `bash -c 'source tests/lib/verify.sh; verify_result "TRANSITION: P10\nephemeral 49152 randomize" "P10" "" "" "" "false" "ephemeral|49152|randomize" ""; echo $?'` → exits `0` (PASS, all required strings present)
  - CLI: `bash -c 'source tests/lib/verify.sh; verify_result "TRANSITION: P10\nephemeral only" "P10" "" "" "" "false" "ephemeral|49152|randomize" ""; echo $?'` → exits `2` (FAIL — missing `49152` and `randomize`); `VERIFY_DETAIL` names the missing string(s)
  - CLI: `./tests/run-tests.sh --dry-run` exits 0 (scenario YAML still parses correctly across all groups)
  - CLI: existing verify.sh behavior preserved — running `./tests/run-tests.sh --id S9,S12,T10-no-auto-push --dry-run` lists scenarios (no parser regression on the existing `not_contains_strict`/`transition_id_any` fields)
  - [x] P1.1 Add two new positional args to `verify_result` signature: `contains_required` (7th, pipe-separated AND list) and `contains_required_any` (8th, pipe-separated OR list). Update the function-header comment block to document both, including the empty-default backward-compat note. Mirror the shape of the 2026-05-06 `not_contains_strict` / `expected_id_any` extension.
  - [x] P1.2 Implement the new check logic. Placement: insert a new step **between the existing step 3 ("Build ID match set") and step 4 ("Evaluate ID match")** so the required-content check runs only after an ID match is established and before PASS is returned. Semantics: (a) if `contains_required` is set, EVERY string must `grep -qi` against `result_text` — first miss → FAIL with `VERIFY_DETAIL="Required content missing: <missing-strings>"`; (b) if `contains_required_any` is set, AT LEAST ONE string must `grep -qi` against `result_text` — none-match → FAIL with `VERIFY_DETAIL="Required-any content missing — none of: <list>"`; (c) when both are set, both checks must pass; (d) when neither is set, behavior is unchanged. Required-content failures take precedence over `not_contains` lenient warnings (i.e., they FAIL, never SOFT_PASS).
  - [x] P1.3 Wire the two new fields through `tests/run-tests.sh`. Two `parse_scenario_nested` lookups added after `not_contains_strict`; passed as 7th + 8th positional args to `verify_result` at the existing call site.
  - [x] verify-auto  <!-- bash -n on both modified files: syntax OK; check-structure.sh: 232 PASS / 2 FAIL (baseline pre-existing, unrelated). 12 inline unit-test cases (A-K) on verify_result: all behave as designed — backward-compat for empty-default args, AND/ANY semantics, case-insensitivity, composite with not_contains_strict. -->
  - [x] verify-self  <!-- feature-verify-self-runner subagent: all 4 CLI outcomes PASS. rc and VERIFY_DETAIL exactly match planned values; literal phrases "required-any content missing" and "required content missing:" appear with the correct strings listed by name. -->
  - [x] verify-human
    - [x] P1.verify-human.1 Inline-CLI smoke — all 4 verify_result outcomes (OUTCOME 1-4) ran in fresh bash; rc and VERIFY_DETAIL exactly match expected (verified via verify-self subagent + build-time smoke).
    - [x] P1.verify-human.2 `./tests/run-tests.sh --dry-run --id S9` exits 0; output lists S9 row correctly (`[DRY] S9 session:orchestrator pauses at feature-finalize (PAUSE step) skill=/session-start`). No YAML parse errors with new optional `expect.contains_required*` fields added. Bg invocation per CLAUDE.md "long-running" rule — runtime ~5 min (standard per-scenario YAML-parse pass, not feature-introduced).
  - [x] verify-codify  <!-- Phase 3e added to tests/check-structure.sh: 13 vr_check unit cases (A-M) covering backward-compat A-F + new AND/ANY behavior G-M. All 13 PASS. Test triage logged below for the 2 perpetual baseline FAILs (pre-existing SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX, unrelated). -->

- [x] Phase 2: Pilot scenario + doc update
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id P10b` exits with the scenario PASSing on haiku (model output reading `skills/product-context/SKILL.md` with Docker-Mandate `system_prompt_extra` includes one of `ephemeral|49152|randomize`)
  - CLI: Mutation test — temporarily stash-remove the "Randomize host ports" bullet from `skills/product-context/SKILL.md`, run `./tests/run-tests.sh --id P10b`; scenario must FAIL with `VERIFY_DETAIL` mentioning "Required-any content missing". Restore the bullet; scenario passes again. (Per the SKILL.md `## Test scenario design — routing-fork patterns` discipline — confirms the new primitive is load-bearing, not trivially-true.)
  - CLI: `grep -A1 "^## SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT" workflow/backlog.md` returns the item flagged `**Status:** resolving` or removed (closure pending §finalize)
  - HTTP/Browser: n/a — test-harness change, no runtime UI/HTTP surface
  - Console: n/a
  - [x] P2.1 Added `P10b` scenario to `tests/scenarios/product.yaml` after P10, using `contains_required_any: [ephemeral, 49152, randomize]` + Docker-Mandate `system_prompt_extra`. `transition_id: P10` retained. Untagged (haiku). Header comment documents the precedent + restoration history.
  - [x] P2.2 Extended the `**Test scenario `expect:` fields**` bullet in `CLAUDE.md` `## Conventions` to document `contains_required` (AND-fanout) and `contains_required_any` (OR-fanout). Cites the `verify-sh-contains-required` feature as the empirical anchor and `P10b` as the first pilot use.
  - [x] verify-auto  <!-- product.yaml YAML parse: P10b at index 9 with all expected fields (transition_id=P10, contains_required_any=['ephemeral','49152','randomize'], system_prompt_extra present); scenario count 17→18. parse_scenario_nested probe: extracts contains_required_any as "ephemeral|49152|randomize" (correct pipe-form for verify_result 8th arg); contains_required empty (not set in P10b, preserves empty-default). CLAUDE.md line 227 bullet well-formed with new field documentation. -->
  - [x] verify-self  <!-- feature-verify-self-runner subagent: 3/3 outcomes PASS. OUTCOME 1 (baseline): P10b PASSes real haiku invocation in 12s ($0.115) — primitive wired end-to-end. OUTCOME 2 (mutation/load-bearing): removed "Randomize host ports" from skills/product-context/SKILL.md → P10b FAILed with EXACT wording "Structured match on P10 but required-any content missing — none of: ephemeral|49152|randomize"; restored SKILL.md (git diff empty) → P10b PASSes again. Confirms the primitive is mechanically biting on real model output, not trivially-true. OUTCOME 3: backlog SURFACE item still present awaiting finalize-time closure. -->
  - [x] verify-human
    - [x] P2.verify-human.1 EXCLUDED — verify-self OUTCOME 1 already executed `./tests/run-tests.sh --id P10b` against live haiku; PASS in 12s ($0.115).
    - [x] P2.verify-human.2 EXCLUDED — verify-self OUTCOME 2 already executed the full mutation sequence: SKILL.md bullet removed → P10b FAIL with exact required-any wording → SKILL.md restored (git diff empty) → P10b PASSes again.
    - [x] P2.verify-human.3 Human approved: CLAUDE.md line 227 bullet documents both `contains_required` (AND) and `contains_required_any` (ANY) with clear semantic distinction, relationship to `contains_any` (hard-assert vs soft-pass-fallback) explicit, and pointer to P10b pilot use.
  - [x] verify-codify  <!-- Added 4 structural pins to tests/check-structure.sh Phase 1: (a) "P10b scenario exists in product.yaml", (b) "P10b uses contains_required_any (new hard-assert primitive)", (c) "CLAUDE.md ## Conventions documents contains_required (AND-fanout)", (d) "CLAUDE.md ## Conventions documents contains_required_any (OR-fanout)". All 4 PASS. check-structure.sh: 249 PASS / 2 FAIL (baseline pre-existing FAILs unchanged, already triaged in Phase 1). Phase 3e (verify_result semantics, 13 cases) + these 4 Phase 2 pins together form the complete safety net for the feature contract. -->

## Current Node
- **Path:** Feature complete — ready to ship
- **Active scope:** All phases (1 + 2) complete. Hand off to /feature-ship.
- **Blocked:** none
- **Unvisited:** none (post-ship: review-quality, finalize)
- **Open discoveries:** none

## Test Triage — regex markdown-bold cases (Phase 3d, pre-existing baseline)

Classification: Obsolete test
Confidence: high
Evidence: `tests/check-structure.sh` Phase 3d ("TRANSITION-line regex") extracts ONLY the sed regex from `tests/lib/verify.sh:51` via `grep -oE` and runs each test case through `sed -n "$REGEX_PATTERN"` directly. But verify.sh's actual production pipeline is `tr -d '*' | sed -n '...'` — the `tr -d '*'` strip is what handles markdown-bold tolerance. The property test asserts the sed regex alone handles markdown bold; it doesn't (and wasn't designed to). Production behavior is correct; only the property test is misaligned. Reproduces at HEAD~N for several commits; not introduced by this feature. Logged in backlog as `SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX`.
Action: No action. This feature does not own the fix; it is the next pickup in the resume queue (P3). Triage entry written here for audit trail. Phase 1 verify-codify advances on the new 13 vr_check PASSes (Phase 3e), which are the actual codification scope.

## Downstream contract impacts

Per CLAUDE.md `## Conventions` — "Plan-level downstream contract impacts pass" — items asserting against the surfaces this feature changes:

- **`tests/run-tests.sh:240`** — caller of `verify_result`. P1.3 updates the call site to pass two new positional args. No external scenario asserts against the literal call shape — internal-only.
- **`verify_result` function-signature comment** (verify.sh:5-14) — updated by P1.1 to document new args. No grep pin in `check-structure.sh` against this comment block as of pre-feature snapshot (confirmed by `grep -n "verify_result" tests/check-structure.sh` — no results).
- **`tests/scenarios/*.yaml` schema** — adding two new optional fields under `expect:`. Existing scenarios are unaffected (empty-default behavior preserved). No scenario lints or YAML schema validator enforces a closed key set.
- **`CLAUDE.md` line 227** — `## Conventions` bullet about `expect:` fields. P2.2 extends the bullet; no other doc grep-asserts against its current literal text (confirmed by `grep -rn "Test scenario .expect. fields" .` — sole occurrence is CLAUDE.md itself).
- **No subcase-A/B/C/D fragility** (literal-payload-object, array-length, function-signature, variable-binding-name): the function-signature change at P1.1 is in `tests/lib/verify.sh`, which `check-structure.sh` does not grep-pin against literal arg-count or signature shape; only `tests/run-tests.sh` invokes it, and that single call site is owned by this feature's P1.3.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
