---
workflow: feature
state: ship (complete)
created: 2026-06-10
entry: spec (complex feature)
drive_mode: autopilot
shipped_commit: 43cb517
---

# Feature: reproduce-as-redirect-from-build

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-10
**Entry:** spec (complex feature — workflow-system state-machine extension)

## Problem Statement

The feature workflow currently has `feature-reproduce` as an **entry-only** state (F31). Once `feature-build` is running, there is no path back into reproduce — yet build is exactly where an agent often discovers it needs reproduction. Without a pre-fix failing-test anchor, "verified" cannot be distinguished from "the code path is now different but the bug was never actually there." This feature adds an in-workflow REDIRECT (F36) from `feature-build` → `feature-reproduce`, mirroring the existing F22 REDIRECT to `feature-research`. Reproduce runs to completion and emits a return transition back to build (F37 on success, F37b on could-not-reproduce) so the per-phase loop stays intact and the reproduce artifact anchors verify-codify.

## Open-Question Resolutions (decided at plan time)

1. **Return-transition naming: NEW IDs F37 (success) + F37b (could-not-reproduce).** Reusing F32/F33 with branching on entry source would couple reproduce's exit logic to entry context — opaque to the state-machine and the test harness. New explicit IDs are parseable, pin-able in scenarios, and match the precedent set by F9/F9b (verify-self success vs back-loop).
2. **Entry-via-F36 detection via WIP sentinel in `## Current Node`.** When build emits F36 it writes `**Redirect source:** build (F36 — Phase N)` into `## Current Node`. Reproduce reads Current Node first per existing protocol (per arch.md), sees the sentinel, knows to emit F37/F37b on exit. No frontmatter mutation, no skill-arg passing. Current Node is already the authoritative position pointer; reusing it minimizes new mechanism surface.
3. **Reproduce artifact attachment: explicit `## Reproduction Artifact (mid-build, from F36)` section in WIP file.** Parallel to how F31-entered features own a top-level `## Reproduction Attempt` section. Build resumes by reading this section and treating the artifact as the verify-codify anchor for the current phase.
4. **F35 from F36-entered reproduce: disallowed.** F36 is a recoverable detour, not a termination point. If reproduce cannot reproduce the bug, it must emit F37b (return to build with `## Reproduction Artifact (mid-build)` documenting the could-not-reproduce outcome as a Discovery) — never F35. F34 (preventive hardening with framing reset to spec) is also disallowed for the same reason: the feature is already past spec, framing reset is meaningless mid-build.
5. **Sonnet tag for F36 scenario.** F22 is sonnet-tagged (haiku-noisy "BLOCKED" instead of F22). F36 mirrors F22's structure; tag sonnet preemptively. F37/F37b haiku-untagged initially — recon at verify-codify, promote only if SOFT_PASS observed.

## Work Tree

- [x] Phase 1: State-machine docs (transitions.md + AGENTS.md)  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -E "^\| F36 " docs/product/transitions.md` returns exactly 1 line matching `F36 | build | reproduce | REDIRECT`
  - CLI: `grep -E "^\| F37 " docs/product/transitions.md` returns exactly 1 line matching `F37 | reproduce | build | Return-from-F36`
  - CLI: `grep -E "^\| F37b " docs/product/transitions.md` returns exactly 1 line matching `F37b | reproduce | build | Could-not-reproduce return`
  - CLI: `grep -c "F36\|F37" agents/feature-workflow/AGENTS.md` ≥ 6 (transition table rows + pause-policy rows + narrative mention)
  - CLI: `./tests/check-structure.sh` PASS count unchanged from baseline (175) — no SKILL.md changes yet, so cheat-sheet drift check stays clean
  - [x] P1.1 Add F36/F37/F37b rows to `docs/product/transitions.md` "Full Transition Table" under Feature Workflow section, in F-ID numerical order (after F35)
  - [x] P1.2 Add narrative paragraph to `docs/product/transitions.md` Feature Workflow section explaining F36/F37/F37b mechanism (mirror the existing F31–F35 reproduce-step narrative shape)
  - [x] P1.3 Add F36/F37/F37b rows to `agents/feature-workflow/AGENTS.md` "Full Transition Table" — F36 type=redirect, F37/F37b type=forward
  - [x] P1.4 Add F36/F37/F37b rows to `agents/feature-workflow/AGENTS.md` "Pause policy by drive mode" table — F36 mirrors F22 row (PAUSE 1–3, AUTO 4); F37 follows back-loop policy (PAUSE 1, AUTO 2–4); F37b same as F37. Also updated the duplicated table in `docs/product/transitions.md` → "Pause policy by mode — feature workflow" to stay in sync.
  - [x] P1.5 Update `agents/feature-workflow/AGENTS.md` §"Your Role" Cross-level transitions block to mention F36 alongside F22 (both REDIRECTs)
  - [x] P1.6 Add Change Log entry to `docs/product/transitions.md` with today's date documenting F36/F37/F37b addition
  - [x] verify-auto  <!-- check-structure.sh 175/175 PASS, 0 FAIL -->
  - [x] verify-self  <!-- All 5 Observable Outcomes PASS via CLI greps + check-structure.sh 175/175. No browser surface; CLI is the canonical consumer of these markdown files. -->
  - [x] verify-human  <!-- Human approved all 5 items (doc readability + integration-boundary attestation on check-structure.sh PASS); F13 -->
    - [x] P1.verify-human.1 transitions.md F36/F37/F37b rows + narrative read correctly
    - [x] P1.verify-human.2 AGENTS.md table rows + pause-policy + Your Role mention land cleanly
    - [x] P1.verify-human.3 Change Log entry is standalone-parseable
    - [x] P1.verify-human.4 no missed F-ID references elsewhere in transitions.md
    - [x] P1.verify-human.5 check-structure.sh 175/175 PASS unchanged (integration-boundary attestation)
  - [x] verify-codify  <!-- No new tests needed: consuming-surface coverage (check-structure.sh 175/175) already exists; F36/F37/F37b transition scenarios deferred to Phase 4 by plan -->

- [x] Phase 2: feature-build SKILL.md updates  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -c "F36" skills/feature-build/SKILL.md` ≥ 4 (valid transitions list, cheat-sheet row, §4 case heading, §9 emit token line)
  - CLI: `grep -F "TRANSITION: F36" skills/feature-build/SKILL.md` returns ≥ 1 line
  - CLI: `grep -F "Redirect source:** build" skills/feature-build/SKILL.md` returns ≥ 1 line (sentinel-write instruction)
  - CLI: `./tests/check-structure.sh` Phase 9 reports PASS for `feature-build` cheat-sheet table parseable (existing test) AND new F36 row matches AGENTS.md REDIRECT (F22) policy values (requires Phase 3's ROW_MAPPING update — Phase 2 alone will FAIL Phase 9b until Phase 3 lands; document this explicitly)
  - [x] P2.1 Add `F36 → reproduce (REDIRECT)` line to skills/feature-build/SKILL.md "Valid transitions from here" list, immediately after F22
  - [x] P2.2 Add F36 row to skills/feature-build/SKILL.md "Orchestrator Pause Policy (cheat-sheet)" table — values match AGENTS.md row "REDIRECT (F36)" exactly (PAUSE/PAUSE/PAUSE/AUTO)
  - [x] P2.3 Add new subsection to §4 in skills/feature-build/SKILL.md: "**Cannot confirm fix worked without reproduction (F36 REDIRECT):**" — explains trigger condition, instructs sentinel-write + placeholder-section + F36 emit
  - [x] P2.4 Add `TRANSITION: F36` line to skills/feature-build/SKILL.md §9 "Emit Transition" list
  - [x] verify-auto  <!-- check-structure.sh 175 PASS + 1 expected FAIL (ROW_MAPPING gap for F36 — Phase 3 P3.6 deliverable). Plan-declared transient state, not a regression. -->
  - [x] verify-self  <!-- All 4 Observable Outcomes PASS via CLI greps + integration-boundary attestation on check-structure.sh. The 1 FAIL is plan-declared cross-phase dependency, resolved in Phase 3 P3.6. -->
  - [x] verify-human  <!-- Human approved all 4 items (SKILL.md doc-judgment + integration-boundary attestation that the FAIL is the expected ROW_MAPPING gap); F13 -->
    - [x] P2.verify-human.1 F36 transition line + cheat-sheet row read cleanly
    - [x] P2.verify-human.2 §4 F36 REDIRECT subsection procedure is clear
    - [x] P2.verify-human.3 §9 emit-transition list ordering correct
    - [x] P2.verify-human.4 check-structure.sh 1 FAIL is exactly the expected ROW_MAPPING gap
  - [x] verify-codify  <!-- No new tests needed: structural Phase 9 coverage on SKILL.md exists; Phase 9b row-drift correctly deferred to Phase 3 P3.6 (test-harness ROW_MAPPING); F36 transition-firing scenario deferred to Phase 4 P4.4. Triage artifact written for the 1 plan-declared FAIL. -->

- [x] Phase 3: feature-reproduce SKILL.md updates + check-structure.sh ROW_MAPPING extension  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -c "F37" skills/feature-reproduce/SKILL.md` ≥ 4 (valid transitions list × 2 for F37/F37b, cheat-sheet rows, §4 transition branches, §5 emit list)
  - CLI: `grep -F "TRANSITION: F37" skills/feature-reproduce/SKILL.md` returns ≥ 1 line; `grep -F "TRANSITION: F37b" skills/feature-reproduce/SKILL.md` returns ≥ 1 line
  - CLI: `grep -F "Redirect source:** build" skills/feature-reproduce/SKILL.md` returns ≥ 1 line (sentinel-detection instruction)
  - CLI: `grep -F "\"F36 \"" tests/check-structure.sh` returns ≥ 1 line (ROW_MAPPING entry for feature-build); `grep -F "\"F37 \"" tests/check-structure.sh` returns ≥ 1 line (ROW_MAPPING entry for feature-reproduce)
  - CLI: `./tests/check-structure.sh` PASS count = 175 (baseline) + 1 (F36 row on feature-build) + 2 (F37 + F37b rows on feature-reproduce) = **178**, 0 FAIL
  - [x] P3.1 Add `F37 → build (return after successful reproduce)` and `F37b → build (return after could-not-reproduce)` lines to skills/feature-reproduce/SKILL.md "Valid transitions from here" list (split into "normal entry" / "F36-redirect entry" subsections; also documents F34/F35 disallowed from F36-entry)
  - [x] P3.2 Add `## Orchestrator Pause Policy (cheat-sheet)` block to skills/feature-reproduce/SKILL.md with rows F32/F33/F34/F35/F37/F37b. Values match AGENTS.md exactly.
  - [x] P3.3 Add Procedure §1.5 "Detect F36 Entry" — reads `## Current Node` for `**Redirect source:** build (F36 — Phase N)` sentinel, sets `f36_entry = true/false`
  - [x] P3.4 Update Procedure §4 to branch on `f36_entry`: normal-entry path keeps F32/F33/F34/F35 logic; F36-entry path routes F37 (reproduced) or F37b (could-not-reproduce), writes artifact to `## Reproduction Artifact (mid-build, from F36)` section, disallows F34/F35
  - [x] P3.5 Update Procedure §5 "Hand Off" emit-transition list — added `TRANSITION: F37` and `TRANSITION: F37b` plus per-mode pause-policy reminders
  - [x] P3.6 Add ROW_MAPPING entries to tests/check-structure.sh: `("F36 ", "REDIRECT (F36)")` to feature-build's mapping; new `feature-reproduce` entry with F32/F33/F34/F35 marked None (no AGENTS.md per-transition rows for these) + F37/F37b mapped to `Return-from-REDIRECT (F37, F37b)`. Added `feature-reproduce` to SKILLS list.
  - [x] P3.7 Verified `parse_agents_table` generic markdown-table parsing handles new rows without modification — confirmed via 178/178 PASS sweep.
  - [x] verify-auto  <!-- check-structure.sh 178/178 PASS, 0 FAIL. Phase 2's transient FAIL closed by P3.6 ROW_MAPPING update; +3 PASS predicted at plan time hit exactly. -->
  - [x] verify-self  <!-- All 5 Observable Outcomes PASS via CLI greps + check-structure.sh 178/178. Phase 2's transient FAIL closed as predicted. -->
  - [x] verify-human  <!-- Human approved all 3 items (SKILL.md branched-entry + ROW_MAPPING shape + 178/178 PASS attestation); F13 -->
    - [x] P3.verify-human.1 feature-reproduce/SKILL.md F36-redirect entry mode + cheat-sheet + §1.5/§4/§5 changes are clean
    - [x] P3.verify-human.2 check-structure.sh ROW_MAPPING entries match existing-skill pattern
    - [x] P3.verify-human.3 check-structure.sh = 178 PASS, 0 FAIL — Phase 2's transient FAIL closed
  - [x] verify-codify  <!-- Structural coverage active at 178/178 (Phase 9 shape + Phase 9b drift on F36/F37/F37b all PASS); F36/F37/F37b transition-firing scenarios are Phase 4 deliverables per plan -->

- [x] Phase 4: Test fixtures + scenarios  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `ls tests/fixtures/wip/feature-build-needs-repro.md tests/fixtures/wip/feature-reproduce-from-build-success.md tests/fixtures/wip/feature-reproduce-from-build-could-not.md` exits 0
  - CLI: `grep -c "^  - id: F3[67]" tests/scenarios/feature.yaml` returns 3 (F36, F37, F37b)
  - CLI: `./tests/run-tests.sh --id F36,F37,F37b --dry-run` lists exactly 3 scenarios
  - CLI: `./tests/run-tests.sh --id F36 --model sonnet` → PASS (F36 sonnet-tagged per F22 precedent)
  - CLI: `./tests/run-tests.sh --id F37,F37b` (haiku default) → PASS (or SOFT_PASS noted for verify-codify recon)
  - [x] P4.1 Create tests/fixtures/wip/feature-build-needs-repro.md — feature mid-build at Phase 2 with InventoryService.reserveStock() race-condition fix; trigger prose at end of fixture explicitly explains realizing no pre-fix anchor exists
  - [x] P4.2 Create tests/fixtures/wip/feature-reproduce-from-build-success.md — F36 sentinel in Current Node, placeholder ## Reproduction Artifact section, fixture's Reproduction section frames cleanly-reproduced failing-test-on-pre-Phase-1 outcome
  - [x] P4.3 Create tests/fixtures/wip/feature-reproduce-from-build-could-not.md — F36 sentinel + placeholder + Reproduction section framing 0/200 reproduces locally due to deterministic asyncio scheduling, telemetry confirms bug is real
  - [x] P4.4 Add F36 scenario to feature.yaml — skill=feature-build, model=sonnet, fixtures.wip=feature-build-needs-repro.md, system_prompt_extra explains "fix applied, never confirmed bug fires", expects F36 + REDIRECT prose
  - [x] P4.5 Add F37 scenario — skill=feature-reproduce, haiku-default, fixtures.wip=feature-reproduce-from-build-success.md, system_prompt_extra reinforces F36-redirect mode + clean reproduce, expects F37 + return-to-build prose, not_contains F32/F33/spec/plan
  - [x] P4.6 Add F37b scenario — skill=feature-reproduce, haiku-default, fixtures.wip=feature-reproduce-from-build-could-not.md, system_prompt_extra explains F34/F35 disallowed in F36-entry mode + could-not-reproduce outcome, expects F37b, not_contains F34/F35/terminate/spec
  - [x] verify-auto  <!-- All 5 outcomes PASS: 3 fixtures exist, 3 scenarios in YAML, dry-run lists 3, F36 sonnet PASS (1 attempt 16s, $0.131), F37+F37b haiku PASS (1 attempt each, 54s total $0.20). check-structure.sh still 178/178. F37b "details" notes F34/F35 mentioned in prose (harness still PASSed on transition_id match — well-known prose-leak family). -->
  - [x] verify-self  <!-- All scenario PASSes re-confirmed from persisted JSON (tests/results/run-2026-06-10-{145236,145749}.json). F36/F37/F37b all status=PASS, single attempt each. The test runner IS the consuming surface for the new scenarios — no separate browser/HTTP surface applies. -->
  - [x] verify-human  <!-- Human approved all 4 items (3 fixtures + 3 scenarios design + F37b prose-leak note + integration-boundary attestation). F37b prose-leak flagged for verify-codify consideration. F13 -->
    - [x] P4.verify-human.1 3 fixtures frame scenarios clearly; F36 sentinel present on both reproduce-side fixtures
    - [x] P4.verify-human.2 3 scenarios in feature.yaml; F36 sonnet-tagged per F22 precedent; F37b's not_contains includes F34/F35/terminate
    - [x] P4.verify-human.3 F37b prose-leak note acknowledged — harness PASSed correctly on transition_id match; question of sonnet-tag promotion deferred to verify-codify
    - [x] P4.verify-human.4 All 3 scenarios PASS empirically (JSON results persisted at tests/results/run-2026-06-10-{145236,145749}.json)
  - [x] verify-codify  <!-- The scenarios ARE the codified tests for this feature. F36 sonnet PASS, F37 haiku PASS, F37b haiku PASS — all single-attempt strict PASSes. Final structural sweep 178/178. F37b sonnet-tag promotion considered but declined per CLAUDE.md convention ("Don't tag preemptively"). All 4 phases complete → F16 → ship. -->

## Current Node
- **Path:** Feature > ship
- **Active scope:** ship (all 4 phases complete, F16 emitted)
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect

- **What changed in our understanding:** Nothing fundamental — the feature shipped exactly as specced and planned. All 5 open spec questions resolved cleanly at plan-time (new F37/F37b IDs, Current Node sentinel detection, explicit `## Reproduction Artifact (mid-build, from F36)` section, F34/F35 disallow rule, F36 sonnet tag mirroring F22). Plan-time predictions (+3 PASS delta on check-structure.sh, 1 transient FAIL between Phase 2 and Phase 3 P3.6) hit exactly.
- **Assumptions that held:** F36 mirroring F22's REDIRECT shape was the right precedent; PAUSE/PAUSE/PAUSE/AUTO pause policy is correct without a single back-loop or operator override. The cross-phase dependency between SKILL.md changes (Phase 2) and ROW_MAPPING changes (Phase 3) was correctly scoped at plan-time and the predicted 1 FAIL → 0 FAIL transition fired exactly. F36 sonnet tagging was the right call (PASS 1/1 attempt). Haiku-default for F37/F37b PASSed strictly (1/1 attempt each).
- **Assumptions that were wrong:** None at the structural level. The F37b harness output noted "Structured match on F37b but also mentioned: F34, F35" — a prose-leak signal where haiku echoes the F34/F35 tokens when explaining the disallow rule. PASSed strictly so no action taken, but flagged as a future sonnet-promotion candidate if it ever produces a real SOFT_PASS or FAIL.
- **Approach delta:** None. Implementation matched the plan exactly across all 4 phases. No F12/F22/F23 back-loops, no in-place-fix shortcuts, no surfaced discoveries beyond the resolved P4 backlog item. The two WIP-tree-edit hygiene bumps mid-cycle (accidentally duplicated "Phase N" headings during checkbox advances on three separate occasions) are an edit-tool ergonomics signal — see below.
- **Notable observation worth flagging (not surfaced as a separate backlog item):** During phase-transition edits, the `Edit` tool's "replace once" semantics caused 3 instances where new phase headings got appended without removing the original `NOT-STARTED` heading, requiring a second cleanup edit. Pattern: when transitioning from Phase N → Phase N+1 in the WIP tree, single-string Edit replacements that flip Phase N's status comment AND insert Phase N+1's status comment in the same edit are fragile because the Phase N+1 heading already exists in the tree with its original `NOT-STARTED` status. The clean shape is: edit Phase N's status comment alone (1 edit), then edit Phase N+1's status comment alone (separate edit). Worth keeping in mind for future feature finalize / WIP-update workflows — not codifying as a CLAUDE.md convention because it's editor-mechanics, not workflow-mechanics.

## Communicate

**Feature complete:** `reproduce-as-redirect-from-build` has shipped at commit `43cb517`. The feature workflow now has a REDIRECT path from `feature-build` into `feature-reproduce` (F36) when an agent mid-build realizes a fix cannot be confirmed without first reproducing the bug, with F37/F37b return transitions that resume build with the artifact (or could-not-reproduce Discovery) in hand. Verify by inspecting the new sections in `docs/product/transitions.md` (search F36–F37b), the new sentinel-detection logic in `skills/feature-reproduce/SKILL.md` §1.5, and the 3 new scenarios in `tests/scenarios/feature.yaml`. `./tests/check-structure.sh` reports 178 PASS, 0 FAIL.

**Requester = operator** (this is Stayman's repo, solo development) — closure notice for self-record.

## Test Triage — skills/feature-build/SKILL.md row 'F36 (REDIRECT to reproduce)' has mapping
Classification: Plan-declared transient state — NOT a code regression, NOT obsolete test, NOT contract conflict, NOT flaky. The Phase 9b drift parser cannot map the new F36 row to its AGENTS.md counterpart until ROW_MAPPING in tests/check-structure.sh gains a `("F36 ", "REDIRECT (F36)")` tuple for feature-build. The plan intentionally separates SKILL.md changes (Phase 2) from test-harness changes (Phase 3 P3.6) because they touch different artifact families.
Confidence: high
Evidence: tests/check-structure.sh:1262-1270 ROW_MAPPING["feature-build"] has F8/F9b/F22/F23/F25/F26/F27 entries, no F36 — Phase 3 P3.6 adds it.
Action: No file modified at verify-codify. Phase 3 P3.6 deliverable closes the gap. Documented at plan time in the WIP's "Downstream contract-impact pass" section.

## Downstream contract-impact pass (plan-time literal-string greps)

Per CLAUDE.md "Plan-time downstream-contract-impacts grep must include literal-payload-object assertions, array-length assertions, literal function-signature strings, AND literal variable-binding-name strings — not just key-name greps":

- **Phase 1 changes the AGENTS.md pause-policy table structure** (adds new rows). The `parse_agents_table` function in `tests/check-structure.sh` (Phase 9b) reads this table. **Verified**: parser uses generic markdown-table parsing with a row-label-key approach (not literal row-name assertions), so new rows are picked up automatically — provided their first cell label matches `^| <label> |`. No parser change needed for Phase 1's additions. **Documented at plan time, not deferred to verify-codify.**
- **Phase 2 changes the feature-build SKILL.md cheat-sheet table** (adds F36 row). The Phase 9b drift check (`parse_skill_table` + ROW_MAPPING dict) requires a `("F36 ", "REDIRECT (F36)")` entry in `ROW_MAPPING["feature-build"]`. **Without P3.6's ROW_MAPPING update, Phase 2's standalone PASS would emit a FAIL** (`row 'F36 (REDIRECT to reproduce)' has mapping` — no entry in ROW_MAPPING). This is intentional cross-phase dependency, not a planning miss — Phase 2's verify-auto/verify-self may show transient FAIL until Phase 3 lands. **Documented**: Phase 2's `verify-auto` expected outcome notes "PASS count unchanged until Phase 3 lands; Phase 9b will FAIL with 1 unmapped-row error in the interim — acceptable."
- **Phase 3 adds a new entry to `SKILLS` list in tests/check-structure.sh line ~1305** (`"feature-reproduce"`). The `for skill in SKILLS:` loop then iterates it. **Verified**: the loop is generic, no per-skill literal-name asserts elsewhere. No additional change needed.
- **Phase 4 adds new scenario IDs (F36, F37, F37b)** to tests/scenarios/feature.yaml. The test runner reads YAML — no literal id-grep elsewhere in the codebase. **Verified**: `grep -rn "F36\|F37" tests/` returns only the scenarios themselves once added; no other harness file pins specific F-IDs.
- **No literal function-signature, array-length, or variable-binding-name greps applicable** — this feature is markdown + YAML + small Python in check-structure.sh; the load-bearing literal pattern is the `("F36 ", "...")` tuple in ROW_MAPPING, which P3.6 owns explicitly.

## Recommended next step

Phase 1 starts. Recommend `/feature-build` to begin P1.1 (state-machine docs edits).

TRANSITION: F7
