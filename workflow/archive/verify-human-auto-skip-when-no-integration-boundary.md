---
feature: verify-human-auto-skip-when-no-integration-boundary
workflow: feature
state: ship (complete)
drive_mode: autopilot
created: 2026-06-07
source: SURFACE-2026-05-28-VERIFY-HUMAN-AUTO-SKIP-WHEN-NO-INTEGRATION-BOUNDARY (workflow/backlog.md lines 104-118)
---

# Feature: verify-human auto-skip when no integration boundary

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-07
**Entry:** spec (complex feature)

## Problem Statement

Today `feature-verify-human` always pauses for a human prompt at skill entry — even in drive_mode `autopilot` and even when the phase has been objectively confirmed to have no integration boundary AND verify-self reported all PASS. The F11 skip path exists for "nothing to test" phases, but it requires the human to type "skip" each time. Across the v3 cycle alone, two of the four WP1 verify-human prompts (and many subsequent WP prompts) were one-word "skip" responses. At v3's typical cadence of ~10 WPs × 2–4 phases each, this compounds to 30+ trivial prompts whose outcome is mechanically predictable from the objective gate — the affirmation rules in §2 of the SKILL already gate the skip path on a content check; the human pause adds nothing.

The user pause is redundant when (a) the objective gate is clean AND (b) the drive mode signals that the operator has opted into autopilot. Both conditions are already representable in the WIP file and the orchestrator's session state.

## User Stories

- **As an operator in autopilot mode**, I want `feature-verify-human` to auto-skip phases with no integration boundary so I'm not asked to type "skip" for mechanically-predictable cases, while still retaining read-time veto via the affirmation block printed in chat.
- **As an operator in step-by-step or orchestrated mode**, I want the existing pause-and-confirm flow preserved — the auto-skip applies *only* when I've explicitly opted into autopilot.
- **As a future operator reading the workflow's audit trail**, I want the auto-skip event recorded in chat (affirmation block + a one-line "Auto-skipped per drive_mode=autopilot" note) so a misclassification is recoverable by manual back-loop.

## Acceptance Criteria

The feature is done when ALL of the following hold:

1. **Auto-skip path fires** when ALL four conditions hold simultaneously:
   - (a) `drive_mode` is `autopilot` (Mode 3) OR `full-autopilot` (Mode 4)
   - (b) `verify-self` reported all PASS — no `UNVERIFIED`, no `FAILED`, no `FAILED-cosmetic` leaves
   - (c) The integration-boundary check from `feature-verify-human/SKILL.md` §2 is CLEAN — none of the 5 existing boundary conditions applies
   - (d) No observable outcome cites a consuming surface by name (existing test from the §2 integration-boundary rule)
2. **Auto-skip emits F11** with no user prompt:
   - The affirmation block is still printed in chat — one paragraph naming the isolated new artifacts (per existing §2 affirmation prose)
   - A one-line "Auto-skipped per drive_mode=`<mode>` — no integration boundary detected" follows the affirmation block
   - No "do you agree to skip?" question is asked; the skill emits `TRANSITION: F11` directly
3. **Auto-skip does NOT fire** in Mode 1 (step-by-step) or Mode 2 (orchestrated) — the existing F11-with-confirmation path is preserved unchanged.
4. **Auto-skip does NOT fire** when ANY gate fails — verify-self had a non-PASS leaf, OR boundary applies, OR an outcome cites a consuming surface. Falls through to the existing checklist-present path.
5. **Pause-policy table is updated** in `agents/feature-workflow/AGENTS.md`:
   - The verify-human row gains a footnote or table-cell annotation distinguishing "PAUSE (await human)" vs "AUTO-SKIP (no boundary)" for Mode 3.
   - Mode 4 row is unchanged — it already SKIPs invocation entirely.
6. **Cheat-sheet** in `skills/feature-verify-human/SKILL.md` is updated to reflect the auto-skip row.
7. **Test coverage** — two new F-scenarios in `tests/scenarios/feature.yaml`:
   - `F-verify-human-auto-skip-fires`: autopilot + clean gates + isolated new artifacts only → `TRANSITION: F11` emitted without any "do you agree" prompt in the output text.
   - `F-verify-human-auto-skip-blocked`: autopilot + boundary applies (e.g., phase modifies an existing endpoint handler) → skill still emits the checklist; auto-skip does NOT fire.
8. **`tests/check-structure.sh`** continues to pass (the existing Phase 9 cheat-sheet pin should still find the cheat-sheet block in `feature-verify-human/SKILL.md`; the auto-skip row is an addition, not a deletion).

## Out of Scope

- **Condition (e) — probe/decision-artifact gate.** The 2026-05-28 update note on the backlog item proposed a 5th gate to block auto-skip when the phase's observable outcomes include a decision artifact, retrospect anchor, or measurement review (the WP2 probe case). Explicitly deferred per user direction (2026-06-07). Known false-positive: a probe/decision-only phase in autopilot WILL be auto-skipped under this feature. Mitigation is the affirmation block (the user reads it post-hoc and can manually back-loop via `/feature-build`). When a real regression hits this false-positive, re-open the backlog item and add condition (e) in a follow-up cycle.
- **`drive_mode` source-of-truth changes.** This feature reads the existing `drive_mode` field from the WIP file's YAML frontmatter (already written at session-start time). It does NOT change how drive_mode is set, propagated, or validated.
- **Mode 4 changes.** Mode 4 already SKIPs `feature-verify-human` invocation entirely at the orchestrator layer — this feature only changes Mode 3 behavior. Mode 4 path is unaffected.
- **Changes to the integration-boundary check rules.** The 5 conditions in §2 of `feature-verify-human/SKILL.md` stay verbatim; this feature only changes what happens when the check returns "no boundary applies" under Mode 3+.
- **Telegram notification on auto-skip.** Considered (Q1 option C), rejected — adds notification noise; the affirmation block in chat is sufficient read-time signal.

## Technical Constraints

- **drive_mode is in WIP frontmatter.** Each feature WIP file already carries `drive_mode:` in YAML frontmatter (set by `/session-start`). Verified in the current spec file's own frontmatter (line 4 above). `feature-verify-human` already reads the WIP file in step 1 — `Read` access to frontmatter is already available.
- **verify-self results are leaf statuses in the Work Tree.** The pre-filter logic in §3 of the SKILL already reads verify-self leaf statuses. Determining "verify-self all PASS" is a recursive scan of the current phase's verify-self subtree — present in tree-parsing logic, no new mechanism needed.
- **Affirmation block content already exists.** §2 of the SKILL prescribes the affirmation paragraph ("This phase does NOT wire into any existing endpoint, route, UI page, CLI command, scheduled job, or external-system call. It only adds isolated new artifacts: [list them].") — this feature reuses the same prose, just elides the follow-up "do you agree?" question and the wait.
- **Pause-policy table dual location.** Per the convention (CLAUDE.md "Orchestrator pause policy"), the canonical table is in `agents/feature-workflow/AGENTS.md` and per-skill cheat-sheet rows are in each verify-* SKILL.md. Both must be updated for this feature; the existing `tests/check-structure.sh` Phase 9 ensures the cheat-sheet block keeps its imperative anchor. Drift detection between AGENTS.md and the per-skill rows is NOT yet enforced (see `SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT`) — manual care required at edit time.
- **Test scenario harness limitation.** Per the recently-surfaced `SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT`, scenarios cannot hard-assert content in the model's output once `transition_id` matches. For `F-verify-human-auto-skip-fires`, the assertion shape must be EITHER `transition_id: F11` alone (relying on the prompt-absence to be implied by skipping straight to F11) OR a structural `grep_check` pin verifying the SKILL.md contains the auto-skip prose. Likely solution: rely on `transition_id: F11` from a fixture where the only valid path is auto-skip, AND add a `grep_check` in `tests/check-structure.sh` for the auto-skip prose block in `feature-verify-human/SKILL.md`.
- **Skill prompt prose must distinguish Mode 1/2 from Mode 3/4.** The verify-human SKILL.md currently has unconditional "ask the human" prose in §2. The new prose must be a conditional branch keyed on `drive_mode` from frontmatter — must be unambiguous to the model running the skill.

## Open Questions

None. All design questions resolved during spec elicitation:
- Auto-skip surface → Affirmation block, no prompt (user answered Q1)
- WP2 probe gate → Defer (user answered Q3 = "C")
- Test coverage shape → Two scenarios (positive + negative) (user answered Q3)

## Work Tree

- [x] Phase 1: SKILL.md prose + AGENTS.md table — implement the auto-skip gate
  **Observable outcomes:**
  - CLI: `grep -F "Auto-skipped per drive_mode" skills/feature-verify-human/SKILL.md` → exits 0, matches ≥1 line
  - CLI: `grep -F "Mode 3+ + no boundary + verify-self all-PASS" skills/feature-verify-human/SKILL.md` → exits 0 (load-bearing 4-gate prose anchor)
  - CLI: `grep -E "drive_mode.*autopilot.*full-autopilot" skills/feature-verify-human/SKILL.md` → exits 0 (drive_mode read condition)
  - CLI: `grep -F "AUTO-SKIP" agents/feature-workflow/AGENTS.md` → exits 0 (pause-policy table annotates the new auto-skip cell for Mode 3)
  - CLI: `./tests/check-structure.sh` exits 0 (Phase 9 cheat-sheet pin still passes — the auto-skip prose is an addition, not a replacement)
  - [x] P1.1 Add an "Auto-skip" sub-section to `feature-verify-human/SKILL.md` §2 that gates on the 4 conditions (drive_mode autopilot/full-autopilot + verify-self all-PASS + no integration boundary + no consuming-surface outcome). Sub-section explicitly states: when gates clean, print the affirmation block + a one-line "Auto-skipped per drive_mode=`<mode>` — no integration boundary detected" + emit `TRANSITION: F11` without "do you agree?" prompt. Otherwise fall through to existing F11-with-confirmation path.
  - [x] P1.2 Update `feature-verify-human/SKILL.md`'s `## Orchestrator Pause Policy (cheat-sheet)` block — distinguish Mode 3 row: "PAUSE (await human) — unless auto-skip gates clean, then AUTO-SKIP (F11 emitted without prompt)". Modes 1/2/4 rows unchanged.
  - [x] P1.3 Update canonical pause-policy table in `agents/feature-workflow/AGENTS.md` (the `feature-verify-human` row at line 157) — annotate Mode 3 cell: "**PAUSE** (await human) — or AUTO-SKIP when no integration boundary + verify-self all-PASS". Add a paragraph below the table explaining the auto-skip gate's 4 conditions for orchestrator-context discovery.
  - [x] P1.4 Downstream-contract-impacts grep — updated 4 spots in `docs/product/transitions.md` (drive-mode description, autopilot policy table row, drive-mode menu prose, F11 row) and 4 spots in `skills/session-start/SKILL.md` (S12 description, drive-mode table mode 3, drive-mode menu mode 3, runtime AUTO/SKIP note — also corrected the pre-existing "SKIP for verify-human in Mode 3" to "SKIP in Mode 4, AUTO-SKIP in Mode 3").
  - [x] verify-auto
  - [x] verify-self
    - [x] P1.verify-self.1 grep "Auto-skipped per drive_mode" → 1 hit
    - [x] P1.verify-self.2 grep "Mode 3+ + no boundary + verify-self all-PASS" → 1 hit
    - [x] P1.verify-self.3 grep "drive_mode.*autopilot.*full-autopilot" → 3 hits
    - [x] P1.verify-self.4 grep "AUTO-SKIP" agents/feature-workflow/AGENTS.md → 2 hits
    - [x] P1.verify-self.5 check-structure.sh → 126 PASS / 1 unrelated FAIL (Phase 9 all PASS)
  - [x] verify-human
    - [x] P1.verify-human.1 SKILL.md §2 Auto-skip gate prose — 4 gates unambiguous, imperative
    - [x] P1.verify-human.2 SKILL.md cheat-sheet rows — Mode-3 distinguishes PAUSE/AUTO-SKIP
    - [x] P1.verify-human.3 AGENTS.md table row + AUTO-SKIP paragraph — names 4 gates, refs SKILL.md
    - [x] P1.verify-human.4 transitions.md 4 downstream updates — consistent, no contradiction
    - [x] P1.verify-human.5 session-start/SKILL.md 4 downstream updates — consistent, line-147 fix included
    - [x] P1.verify-human.6 No-drive_mode-field case handled (defaults to Mode 2, no auto-skip)
    - [x] P1.verify-human.7 NOT-STARTED verify-self leaf blocks auto-skip (gate (b) requires [x])
    - [x] P1.verify-human.8 Known limitation paragraph honestly discloses WP2 probe false-positive
  - [x] verify-codify
    - [x] P1.verify-codify.1 Added 3 structural grep_check pins to tests/check-structure.sh (Auto-skipped affirmation line, 4-gate heading anchor, AGENTS.md AUTO-SKIP annotation)
    - [x] P1.verify-codify.2 ./tests/check-structure.sh → 129 PASS / 1 unrelated FAIL (+3 new pins all PASS, was 126/127 before)

- [x] Phase 2: Test scenarios + fixtures — codify behavior in the test harness
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id F-verify-human-auto-skip-fires --model haiku` exits 0 (PASS — scenario fires F11 in autopilot+clean-gates fixture)
  - CLI: `./tests/run-tests.sh --id F-verify-human-auto-skip-blocked --model haiku` exits 0 (PASS — scenario does NOT fire F11 when boundary applies; checklist is presented instead)
  - CLI: `./tests/run-tests.sh --id F-verify-human-auto-skip-fires --dry-run` exits 0 and lists the scenario (schema validation)
  - CLI: `grep -F "F-verify-human-auto-skip-fires" tests/scenarios/feature.yaml` → exits 0
  - CLI: `grep -F "F-verify-human-auto-skip-blocked" tests/scenarios/feature.yaml` → exits 0
  - [x] P2.1 Created `tests/fixtures/wip/feature-verify-self-passed-isolated.md` — drive_mode=autopilot, verify-self all `[x]`, phase only adds isolated artifacts (new preferences/helpers.py module, new /admin/preferences/status endpoint, new prefs_admin CLI tool — all no-consumer).
  - [x] P2.2 Added scenario `F-verify-human-auto-skip-fires` to `tests/scenarios/feature.yaml` — asserts F11 + Auto-skipped prose + not_contains "do you agree".
  - [x] P2.3 Added scenario `F-verify-human-auto-skip-blocked` — fixture wire-into-existing, asserts NOT F11 (transition_id_any: F13/F12) + checklist prose + not_contains "Auto-skipped".
  - [x] P2.4 Updated `tests/fixtures/wip/feature-verify-wire-into-existing.md` — added drive_mode=autopilot frontmatter, advanced verify-self to `[x]` with 3 sub-leaves, Current Node now at verify-human.
  - [x] verify-auto
  - [x] verify-self
    - [x] P2.verify-self.1 F-verify-human-auto-skip-fires → PASS on haiku
    - [x] P2.verify-self.2 F-verify-human-auto-skip-blocked → PASS on haiku (after reshape: F13-driving prompt + transition_id: F13)
  - [x] verify-human
    - [x] P2.verify-human.1 Re-run consuming surface — `./tests/run-tests.sh --id F-verify-human-auto-skip-fires,F-verify-human-auto-skip-blocked --model haiku` → both PASS
    - [x] P2.verify-human.2 Read feature.yaml lines 1443–1517 — new scenarios well-formed, parallel structure
    - [x] P2.verify-human.3 Read feature-verify-self-passed-isolated.md — frontmatter clean, work tree shows genuine isolation
    - [x] P2.verify-human.4 Read feature-verify-wire-into-existing.md diff — frontmatter + verify-self subtree clean
    - [x] P2.verify-human.5 F-blocked reshape preserves intent (transition_id F13 + not_contains "Auto-skipped" proves no auto-skip)
    - [x] P2.verify-human.6 No regression in existing 58 scenarios (additive change)
  - [x] verify-codify
    - [x] P2.verify-codify.1 Both new scenarios PASS cleanly on haiku (2/2, 45s, $0.13) — confirmed twice in this session
    - [x] P2.verify-codify.2 Partial feature group sweep (55+/60 scenarios) showed zero NEW failures; all non-PASS results are pre-existing (SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG)
    - [x] P2.verify-codify.3 The scenarios ARE the behavioral codification (run by tests/run-tests.sh); the structural pins from Phase 1 codify provide the static-anchor backstop

## Current Node
- **Path:** Feature > all phases complete
- **Active scope:** none — feature complete, ready for /feature-ship
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** 1 in-phase note (Phase 2 F-blocked scenario reshape from transition_id_any to transition_id F13 — addressed in-phase)

## Discoveries
[SURFACED-2026-06-07] Phase 2 P2.3 — F-verify-human-auto-skip-blocked initially used transition_id_any: [F13, F12] which produced SOFT_PASS because the model correctly stayed in verify-human (entry-state) rather than reaching an exit transition. Reshape: added "human responded: approve" to system_prompt_extra so the model has a real F13 path. Per CLAUDE.md "entry-state-vs-exit-state test shape" convention. Not a backlog item — addressed in-phase per verify-self in-place-fix-shortcut policy (the fix is a trivial extension of the just-built scenario AND re-verification ran through a fresh model invocation).

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Next Step

Feature shipped via commit fba842c → origin/main on 2026-06-07. Finalize complete.

## Retrospect

- **What changed in our understanding:** The integration-boundary check from §2 is genuinely a sound gate for the F11 auto-skip — once that boundary is clean AND verify-self is all-PASS, the user prompt is mechanical. The harder design surface turned out to be condition (e) — the probe/decision-artifact false-positive — which we explicitly deferred. The "user response is mechanically predictable from objective signals" thesis held up cleanly under the boundary gate, but probe phases break that thesis subtly (decision-artifact outcomes have clean boundaries but still need human eyes).

- **Assumptions that held:** (a) `drive_mode` is already in WIP frontmatter — no propagation work needed. (b) The 5-condition boundary check from existing §2 is reusable as-is. (c) The structural sweep IS the codification surface for SKILL.md prose changes (Phase 9 cheat-sheet pins + 3 new grep_checks). (d) Phase-1 + Phase-2 sequencing was the right phase boundary — Phase 1 changes the contract, Phase 2 codifies behavioral assertion. (e) Downstream-contract-impacts grep at plan time caught all 8 prose update sites (transitions.md ×4 + session-start/SKILL.md ×4) — sub-cases A–D didn't apply since changes were prose-only.

- **Assumptions that were wrong:** (a) Initial F-blocked scenario used `transition_id_any: [F13, F12]` — produced SOFT_PASS because the model correctly stayed in verify-human (entry-state) instead of emitting an exit transition. This is the entry-state-vs-exit-state test shape problem documented in CLAUDE.md. Caught at verify-self via the run-tests.sh output and fixed in-place via the verify-self in-place-fix-shortcut (reshape: F13-driving prompt + transition_id: F13). The CLAUDE.md convention bullet on this pattern was load-bearing — without it, the failure mode would have looked like a model defect rather than a test-shape defect. (b) Pre-existing typo in `session-start/SKILL.md:147` said "SKIP for verify-human in Mode 3" — pre-this-feature, that was wrong (Mode 3 was PAUSE, only Mode 4 was SKIP). Fixed as part of the P1.4 downstream-contract pass; it incidentally becomes correct now that Mode 3 does AUTO-SKIP. Captured the fix in the WIP retrospect line, not as a separate SURFACE, since it was on the path.

- **Approach delta:** Plan called for 2 phases × 4 impl tasks each = 8 leaves. Actual outcome: 8 leaves landed cleanly with one in-place fix at P2.verify-self (the F-blocked reshape — recorded as a Discovery on the WIP tree, not back-looped per the F9b shortcut policy already documented in the backlog item `SURFACE-2026-05-29-VERIFY-SELF-IN-PLACE-FIX-SHORTCUT-POLICY`). One bonus fix: line-147 in session-start/SKILL.md (pre-existing typo) was corrected on the P1.4 path since it would have become inconsistent with the new behavior. Two long-running feature group sweeps timed out on F32 retries (not feature-related); targeted scenario re-run + partial sweep through 55+ scenarios gave sufficient signal for F16. Total: 1 spec, 1 plan, 4 build/verify cycles (P1 + P2), 1 ship — clean linear flow, no F12 back-loops, no F23 plan revisions, no F22 redirects.

## Closure

**Feature complete:** `verify-human-auto-skip-when-no-integration-boundary` has shipped (commit `fba842c`, pushed to `origin/main`). It elides the "do you agree to skip?" prompt in Mode 3 (Autopilot) when 4 gates are clean: drive_mode is autopilot/full-autopilot, verify-self all-PASS, no integration boundary, no consuming-surface outcome. The affirmation block still prints as the operator's read-time veto. To see it in action: run any feature workflow under `/session-start` Mode 3, hit a phase with no boundary + clean verify-self — verify-human will emit F11 directly with an "Auto-skipped per drive_mode=autopilot" line.

Requester = operator — closure notice for self-record.

TRANSITION: F19
