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
- **Path:** Feature shipped + reviewed — ready to finalize
- **Active scope:** Ship commit e0c2917 + review-quality complete (3 MINOR findings auto-backlogged). Next: /feature-finalize.
- **Blocked:** none
- **Unvisited:** none
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

## Retrospect

- **What changed in our understanding:** Two things. (1) The `_csv` arg-suffix naming in `verify_result`'s docstring is more misleading than it first appears — the separator is pipe `|`, not comma, and a future contributor reading "csv" could write a comma-separated string and get silent single-string match. Surfaced as MINOR by the code-quality reviewer; mirrors the pre-existing `contains_any_csv`/`not_contains_csv` convention but worth a future rename pass. (2) `./tests/run-tests.sh --dry-run --id <ID>` — even with `--id` filtering — does a full YAML-parse pass through ALL 159 scenarios via python subprocesses before filtering. Wall-clock per invocation: ~5 min (parse) + 30-90s (haiku call if not dry-run). The `--id` flag does NOT skip the parse pass; this is structural to the runner's filter-after-parse design. Surfaced operationally during Phase 1 verify-human (bash auto-bg several times before completion).
- **Assumptions that held:** (a) The 2026-05-06 `transition_id_any` + `not_contains_strict` extension was the right structural precedent — same positional-args-with-empty-default pattern, same parse_scenario_nested wiring. (b) `contains_required_any` would be the right primitive for P10b (OR-fanout, robust to phrasing variation in haiku output). (c) Phase 2's mutation test would mechanically prove the primitive bites, providing high-confidence load-bearing evidence the structural pins alone can't give. (d) The Test Triage gate for the 2 baseline FAILs (Phase 3d regex/markdown-bold) would absorb correctly without action by this feature.
- **Assumptions that were wrong:** (a) Initial expectation was that codifying Phase 1 would happen "indirectly via Phase 2's pilot scenario." That was wrong: Phase 2 is end-to-end coverage at the model level; Phase 1 needs its own unit-level pins because the new args' bite is only exercised when a scenario opts in. Resolved by adding Phase 3e (13 vr_check cases A-M) sourcing verify.sh directly — mirrors the existing Phase 3d shape. (b) Expected `./tests/run-tests.sh --dry-run` to complete in seconds based on the "dry-run skips the claude --print call" branch in run-tests.sh:152. Was wrong — the per-scenario YAML-parse pass that precedes filtering is the cost (~5min for 159 scenarios). Adjusted by switching to direct unit-cases against `verify_result` for regression coverage.
- **Approach delta:** Plan was 2 phases (harness primitive + pilot scenario/doc). Reality matched exactly — zero back-loops, zero F23 plan revisions, zero F22 redirects. The only mid-feature surprise was the `./tests/run-tests.sh --dry-run` auto-bg behavior; resolved as operator-discipline (wait for completion notification) rather than feature scope creep. Phase 1's verify-codify scope grew slightly during execution — added Phase 3e (12+1=13 cases A-M including the L+M `contains_required_any all-miss with list` and `contains_required two-miss naming both missing strings`) once the unit-test approach was clear. The reviewer subagent flagged this as MINOR doc-drift in the Phase 3e header comment (says "G-K", should be "G-M") — captured in backlog-quality-findings.md for the next sweep.

## Code-Quality Review — verify-sh-contains-required

### Strengths
- Backward-compatibility is structurally guarded: empty-string defaults in positions 7 and 8 mean every existing scenario behaves identically, and Phase 3e cases A-F explicitly pin that invariant — a future refactor that accidentally drops the empty-default contract will redden the structural test before any scenario runs.
- Mutation-verification mid-feature (stash-remove the SKILL.md bullet → P10b FAILed with exact wording → restore → PASS) is the right empirical anchor for "the primitive is load-bearing, not trivially-true." This is the kind of evidence-driven verify-self that the workflow's discipline is designed to produce.
- `VERIFY_DETAIL` wording is treated as part of the contract — Phase 3e asserts on operator-facing substrings (e.g., "required content missing: ephemeral", "49152, randomize") so the human debugging story can't silently regress to a generic message.
- The Phase-3e/Phase-2-grep-pin pair is well-decomposed: Phase 3e pins the harness primitive's semantics in isolation; Phase 2 pins the scenario + convention-doc surface. Each pin layer breaks for a different class of regression.
- Step numbering inside `verify_result` was updated cleanly (old "4. Evaluate ID match" → "5. Evaluate ID match" with new "4. Required-content checks" inserted) — comment-numbering drift is the kind of thing that's easy to skip on refactor; the author didn't skip it.

### Issues
**CRITICAL**
- (none)

**MAJOR**
- (none)

**MINOR**
- [tests/check-structure.sh:378] Phase 3e header comment says "Forward cases (G-K) pin the new AND/ANY behavior" but the actual implementation runs cases G through M (7 forward cases — G, H, I, J, K, L, M). Cases L and M were added without updating the header comment. The WIP's verify-codify note and the diff-stat comment in `runtimes.md` both correctly say "13 vr_check unit cases (A-M)" — only the Phase 3e header is stale. Trivial documentation drift; tomorrow's reader of the header comment will mis-count.
- [tests/lib/verify.sh:5,15-16] The new arg names in the function signature comment are suffixed `_csv` (`contains_required_csv`, `contains_required_any_csv`) but the actual separator is the pipe `|`, not comma. This mirrors the pre-existing `contains_any_csv` / `not_contains_csv` naming convention so it isn't a new sin — but it is a small documentation hazard: a future contributor reading "csv" and writing `"ephemeral,49152,randomize"` in a scenario will get a single literal string match attempt rather than three. Worth a follow-up rename to `_list` (or a parenthetical "(pipe-separated, despite name)" in the docstring) at a future cleanup pass — not load-bearing here because the new field-level CLAUDE.md docs correctly say "pipe-separated."
- [tests/check-structure.sh:1037-1042] The two CLAUDE.md grep pins use alternation `"contains_required:.*AND-fanout|AND-fanout.*contains_required:"` to tolerate either ordering on the line. This is defensive and harmless, but the documented convention is a single bullet on one line with a fixed ordering — the simpler grep `"contains_required.*AND-fanout"` (without anchoring to the colon) would catch the same regressions while being easier to read at the grep-call site. Cosmetic; pin works as written.

### Assessment
This is a tightly-scoped, well-built test-harness primitive that closes a real load-bearing gap (the SOFT_PASS-fallback masking of content regressions, twice-bitten in the 2026-06-06 task that motivated the SURFACE). The mutation-verification of the pilot P10b scenario gives high confidence the primitive bites on real model output rather than being a trivially-true addition; the Phase 3e backward-compat cases A-F give high confidence existing scenarios stayed semantically identical; and the Phase 2 grep pins (P10b existence + CLAUDE.md docs) close the convention-discoverability loop so a future contributor can't silently revert to soft-pass-only verification. Future readers will find the code clear — the step-numbered comment block in `verify_result` is unusually friendly for a shell function. No technical debt accrued; the only findings are documentation-polish nits with no behavioral consequence.

### If you disagree
Operator: dismiss any finding by editing this section in the WIP file and marking the line `[DISMISSED]` before `feature-finalize` archives the WIP. The finding will be skipped by the orchestrator's severity-tier action matrix.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
