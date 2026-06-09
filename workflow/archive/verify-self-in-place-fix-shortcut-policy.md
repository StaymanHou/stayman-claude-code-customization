---
workflow: feature
state: plan (complete)
drive_mode: autopilot
created: 2026-06-09
surface_id: SURFACE-2026-05-29-VERIFY-SELF-IN-PLACE-FIX-SHORTCUT-POLICY
---

# Feature: Verify-Self In-Place Fix Shortcut Policy

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-09

## Problem Statement

`skills/feature-verify-self/SKILL.md` is contractually observe-only: BLOCKING failures route through the F9b back-loop to `feature-build`. Three observed instances (v3 WP3 Phase 2 on 2026-05-29; v3 WP11 Phase 1 on 2026-06-06; verify-human-auto-skip-when-no-integration-boundary Phase 2 on 2026-06-07) demonstrate that when a fix is a trivial extension of the just-completed leaf AND re-verification runs through a fresh model invocation, the formal F9b back-loop costs 3 extra Skill invocations (build → verify-auto → verify-self) for an outcome equivalent to what the back-loop would have produced. Each instance was an ad-hoc deviation, user-approved at verify-human. The rule of three is met (per project CLAUDE.md note), so this feature codifies the shortcut as an explicit, gated sub-clause in §3 of the skill — with an audit-trail requirement in `## Discoveries` — and adds a structural-check assertion so the anchor doesn't silently rot. Option (b) from the backlog (auto-fast F9b chain) is out of scope; only option (a) (explicit in-place fix sub-clause) ships.

## Work Tree

- [x] Phase 1: Codify in-place fix shortcut in verify-self SKILL.md  <!-- status: [x] (all impl + verify leaves complete; codification deferred to Phase 2 by design; pre-existing P4 fixture-drift triaged as out-of-scope; 2026-06-09) -->
  **Observable outcomes:**
  - CLI: `grep -c "In-place fix shortcut" skills/feature-verify-self/SKILL.md` returns ≥ 1 — PASS (count=1, 2026-06-09)
  - CLI: `grep -c "audit-trail" skills/feature-verify-self/SKILL.md` returns ≥ 1 — PASS (count=1, 2026-06-09)
  - CLI: `awk '/^### 3\. Parse subagent results/,/^### 4\./' skills/feature-verify-self/SKILL.md | grep -c "trivial extension"` returns ≥ 1 — PASS (count=1 in §3 region, 2026-06-09)
  - CLI: `readlink ~/.claude/skills/feature-verify-self` resolves to this repo — PASS (resolves to `/Users/stayman/Personal/projects/my-claude-code-customization/skills/feature-verify-self`, 2026-06-09)
  - [x] P1.1 Draft the "In-place fix shortcut" sub-clause inside §3 of `skills/feature-verify-self/SKILL.md`, after the existing FAIL handling bullet, with explicit triple-gate language: (a) trivial extension of just-completed leaf, (b) fresh model invocation re-verifies, (c) audit-trail entry in WIP `## Discoveries` describing what was fixed + how it was re-verified. Emit `TRANSITION: F10b` after the fix (not F9b). Cross-link to §1 "Subagent Re-Verification Heuristic" so authors see both observe-only deviations together.
  - [x] P1.2 Add a "what this is NOT" guard paragraph mirroring the existing heuristic's "What this heuristic is not" framing — explicit anti-abuse: not license to override genuine BLOCKING fails whenever a fix is convenient; the triviality gate is the boundary, not the agent's comfort. (Landed as "What this shortcut is NOT" paragraph in the same edit as P1.1.)
  - [x] P1.3 Cross-link from the project `CLAUDE.md` line ~241 "ready to formalize" note: append `(formalized 2026-06-09)` so the convention doc isn't stuck advertising the future-tense state.
  - [x] verify-auto  <!-- status: [x] (YAML frontmatter parses, anchors present, 2026-06-09) -->
  - [x] verify-self  <!-- status: [x] (no integration boundary; all 4 CLI grep outcomes PASS on fresh re-verification, 2026-06-09; no Playwright subagent — markdown-only phase) -->
  - [x] verify-human  <!-- status: [x] (auto-skipped per drive_mode=autopilot — all 4 auto-skip gates clean; affirmation printed; 2026-06-09) -->
  - [x] verify-codify  <!-- status: [x] (codification deferred to Phase 2 by plan design — Phase 2 IS the test-coverage phase for Phase 1 content; suite ran PASS 132/FAIL 1 with the 1 FAIL triaged as pre-existing P4 fixture drift, see ## Test Triage; 2026-06-09) -->

- [x] Phase 2: Structural check + test scenario  <!-- status: [x] (all impl + verify leaves complete; structural pins + F10b-shortcut scenario shipped and PASS; 2026-06-09) -->
  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` reports 2 new PASS lines for "In-place fix shortcut" and "SHORTCUT-token audit-trail convention" — PASS (both PASS lines confirmed, 2026-06-09)
  - CLI: `./tests/check-structure.sh` total PASS count went 132 → 134 (the +2 new); pre-existing P4 fixture drift remains the only FAIL — PASS (no regression)
  - CLI: `grep -c "F10b-shortcut\|In-place fix shortcut" tests/scenarios/feature.yaml` ≥ 1 — PASS (new F10b-shortcut scenario added with shortcut-shaped fixture)
  - CLI: `./tests/run-tests.sh --id F10b-shortcut --model haiku` returns PASS — PASS (1/1 strict, 31s, no haiku noise, untagged default is correct, 2026-06-09)
  - [x] P2.1 Add a structural-check assertion in `tests/check-structure.sh` (next to the existing Auto-skip-gate pins near line 137): two `grep_check` calls — one for the "In-place fix shortcut" heading anchor, one for the `[SHORTCUT-<YYYY-MM-DD>]` audit-trail token convention. Mirrors the auto-skip-gate comment-block style.
  - [x] P2.2 Add `F10b-shortcut` scenario to `tests/scenarios/feature.yaml` (inserted immediately after the existing F10b scenario for adjacency). New fixture `tests/fixtures/wip/feature-verify-self-trivial-fix.md` frames a BLOCKING fail that is a one-character SQL fix to the migration just written — unambiguously inside all three shortcut gates. `transition_id: F10b` (single), `not_contains: /feature-build`. Untagged for haiku default.
  - [x] P2.3 Ran `./tests/check-structure.sh` (134 PASS / 1 pre-existing FAIL) and `./tests/run-tests.sh --id F10b-shortcut --model haiku` (1/1 PASS, 31s on haiku — no recon needed, untagged is correct).
  - [x] verify-auto  <!-- status: [x] (bash syntax PASS, YAML parse PASS — 61 scenarios + F10b-shortcut unique ID, fixture has required sections, 2026-06-09) -->
  - [x] verify-self  <!-- status: [x] (no integration boundary; all 4 CLI observable outcomes PASS on fresh re-verification — 2 new check-structure PASS lines, 134/1 counts unchanged, F10b-shortcut grep count=1, scenario re-run PASS 1/1 28s; 2026-06-09) -->
  - [x] verify-human  <!-- status: [x] (auto-skipped per drive_mode=autopilot — all 4 gates clean; affirmation printed; 2026-06-09) -->
  - [x] verify-codify  <!-- status: [x] (Phase 2 IS the codify phase — coverage already in place; full feature-group haiku partition: 34 PASS / 17 SOFT / 4 FAIL / 4 FLAKY, all 4 FAILs triaged as pre-existing haiku-noise outside Phase 2's diff; F10b-shortcut PASSes strict; 2026-06-09) -->

## Current Node
- **Path:** Feature > ship
- **Active scope:** all phases complete; ready to ship
- **Blocked:** none
- **Unvisited:** ship → finalize
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Test Triage — feature-group haiku partition (Phase 2 verify-codify, 2026-06-09)
- **Classification:** Pre-existing haiku-noise on unrelated scenarios — not caused by Phase 2.
- **Confidence:** High — Phase 2's only edit to `tests/scenarios/feature.yaml` is the append-only F10b-shortcut block at line 374. The 4 FAIL scenarios are F3 (line 22), F5 (line 61), F14 (line 498), F33 (line 1360) — completely outside Phase 2's diff. All four failures match the documented haiku-noise pattern: "No transition signal found" / "No output from claude" / "Wrong transition" — exactly `SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG` (P5 backlog).
- **Sweep result:** 34 PASS / 17 SOFT_PASS / 4 FAIL / 4 FLAKY (retried-passed) on haiku-untagged partition. F10b-shortcut (Phase 2's new scenario) PASSed strictly. New structural assertions in check-structure.sh also PASS (verified in Phase 2 verify-self).
- **Action:** No file modified or deleted. The 4 FAILs are documented P5 backlog items awaiting their own recon discipline (haiku→sonnet promotion); Phase 2 does not regress them. Sonnet partition skipped per CLAUDE.md "Verify-codify full-group sweep discipline" — its purpose is to surface *Phase 2's* regressions on sonnet-tagged scenarios, but Phase 2 added no sonnet-tagged scenarios and the haiku failures are pre-existing noise.

## Test Triage — settings fixture in sync with live (Phase 1 verify-codify, 2026-06-09)
- **Classification:** Pre-existing fixture drift / obsolete test — not introduced by this feature.
- **Confidence:** High — the failure (`model: live=<missing> fixture="opus[1m]"`) is identical to `SURFACE-2026-06-06-SETTINGS-FIXTURE-MODEL-DRIFT` (P4 in `workflow/backlog.md`), which documents this exact failure as a pre-existing P4 backlog item from 2026-06-06, three days before Phase 1 started. Phase 1 touched only `skills/feature-verify-self/SKILL.md` and `CLAUDE.md` — neither file is in the settings-fixture audit path.
- **Evidence:** Phase 1's diff is markdown-only edits to two files; the failing assertion in `tests/check-structure.sh` reads `~/.claude/settings.json` vs. `tests/fixtures/settings.json` — completely orthogonal.
- **Action:** No file modified or deleted by Phase 1 verify-codify. Pre-existing failure is acknowledged and left for P4's own task cycle. Total: PASS 132 / FAIL 1 (the 1 FAIL is the pre-existing P4 drift).

## Retrospect

- **What changed in our understanding:** None — the policy was well-defined in the backlog entry (option (a) selected at plan time, three observed instances analyzed) and CLAUDE.md line 240 had explicitly marked it "ready to formalize." The feature was nearly a transcription job from spec → implementation.
- **Assumptions that held:**
  - The build-time grep discipline (CLAUDE.md "Build-time selector-emission discipline") caught one case-sensitivity miss in Phase 1 — `awk` outcome was case-sensitive but my first edit used "Trivial extension" (capitalized). One small in-place edit (no back-loop needed). Discipline worked as designed.
  - Phase splitting was correct — Phase 1 (SKILL.md edit) and Phase 2 (tests) cleanly separated. Phase 1's verify-codify correctly deferred all test coverage to Phase 2 (the codification phase), which avoided the temptation to write tests for SKILL.md prose before the structural pin existed.
  - The auto-skip gate fired correctly twice (both Phase 1 and Phase 2 verify-human) — the affirmation block + drive_mode autopilot was the right composition for a doc-only feature.
- **Assumptions that were wrong:** None of significance. The plan's downstream contract analysis correctly identified that no existing tests grep against §3 prose, so the SKILL.md edit had no fragile downstream consumers.
- **Approach delta:** Implementation matched plan exactly. P1.1 + P1.2 collapsed into a single Edit invocation because the "What this shortcut is NOT" guard paragraph fit naturally adjacent to the gate language; the plan had allowed for either separate or combined.

## Communicate

> **Feature complete:** `verify-self-in-place-fix-shortcut-policy` has shipped (commit b097ac0). The verify-self "in-place fix shortcut" is now an explicit triple-gated sub-clause in `skills/feature-verify-self/SKILL.md` §3 — permitting a fix in place when (a) it's a trivial extension of the just-completed leaf, (b) re-verification runs through a fresh model invocation, and (c) an audit-trail `[SHORTCUT-<date>]` entry lands in WIP `## Discoveries`. Regression coverage: 2 structural-check pins + the `F10b-shortcut` behavioral scenario (PASS strict on haiku).
>
> Requester = operator — closure notice for self-record.

## Downstream contract impacts (plan-time grep)

- **`skills/feature-verify-self/SKILL.md`** — Phase 1 edits the file in place. No other skill greps against literal §3 text, so no downstream key-name/object-shape impact from the SKILL.md edit alone.
- **`tests/check-structure.sh`** — Phase 2 ADDS a new assertion; no existing assertion is being mutated. The new anchor string "In-place fix shortcut" must be unique within the SKILL.md so the grep_check is unambiguous.
- **`tests/scenarios/feature.yaml`** — Phase 2 adds one new scenario. No existing scenario's expected transitions change. Verified via `grep -n "verify-self\|F10b\|F9b" tests/scenarios/feature.yaml` mental-grep at plan time.
- **CLAUDE.md line ~241** — Phase 1 P1.3 mutates the project convention doc to mark the rule "formalized 2026-06-09". No tests grep against that exact line; the edit is doc-only.
- **No new transitions, no new states** — F10b and F9b remain the only exits; the shortcut is a §3 procedure-clause refinement, not a state-machine change.

## Integration-boundary analysis (plan-time)

Phase 1 modifies `skills/feature-verify-self/SKILL.md`, which is a "consuming surface" in the sense that the live `~/.claude/skills/feature-verify-self/` symlink resolves to it and is read by Claude Code at skill-invocation time. However:
- No HTTP endpoint, UI page, CLI command, scheduled job, or external call is involved.
- The "consumer" is the model's own skill-prompt loading — a meta-consumer, not a feature-runtime surface.
- The 5-condition integration-boundary rule in `skills/feature-verify-self/SKILL.md` does not fire (none of conditions 1–5 apply).

Phase 2 modifies `tests/check-structure.sh` (a CLI) and `tests/scenarios/feature.yaml` (a fixture). Condition 3 (CLI modification) arguably applies for check-structure.sh, but the modification adds an *additional* assertion — it doesn't change the script's existing invocation contract or output shape, just appends one more pass/fail line. Out of conservatism, the Phase 2 observable outcomes include `./tests/check-structure.sh` invocation explicitly, which satisfies condition 3 if it does apply.

**Verdict:** No integration boundary in the strict sense. verify-human auto-skip gate is eligible to fire in autopilot mode if verify-self all-PASS holds.
