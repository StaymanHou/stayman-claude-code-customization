# Feature: WP13 [COMPLETED 2026-05-01] — Hardening (Tests, Polish, Documentation)

**Workflow:** feature
**State:** ship (complete)
**Created:** 2026-05-01

## Problem Statement

WPs 1–12 introduced substantial new skill behaviors (Work Tree format, Observable Outcomes, feature-verify-self, scoped re-entry, probe checks, framework alignment back-loops). The test suite covers most transitions but has gaps in pain-points-driven scenarios. Skill argument-hints don't reflect the new scoped-leaf-ID convention for feature-build. CLAUDE.md doesn't document Work Tree format, severity taxonomy, or Observable Outcomes conventions. install.sh needs an idempotence check after WP7b added feature-verify-self. This phase closes all of those gaps and produces a clean, fully-documented, fully-tested system.

## Work Tree

- [x] Phase 1: Test Coverage Audit + Gap Fill  <!-- status: in-progress -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --group feature` exits 0 with all scenarios PASS
  - CLI: `./tests/run-tests.sh --group task` exits 0 with all scenarios PASS
  - CLI: `./tests/run-tests.sh --group product` exits 0 with all scenarios PASS
  - CLI: `./tests/run-tests.sh --group incident` exits 0 with all scenarios PASS
  - CLI: `./tests/run-tests.sh --group session` exits 0 with all scenarios PASS
  - CLI: `./tests/run-tests.sh --dry-run` lists ≥ 3 new scenario IDs not present before WP13

  - [x] P1.1 Run full test suite and capture baseline pass/fail report  <!-- status: in-progress -->
  - [x] P1.2 Audit existing scenarios against pain-points coverage matrix (PP1 blocked items, PP2 verify-self prefilter, PP2 reverify, PP3 probe) — document gaps  <!-- status: in-progress -->
  - [x] P1.3 Write missing scenario: F13-prefiltered — verify-human excludes items already cleared by verify-self (PP2 pre-filter gap)  <!-- status: in-progress -->
  - [x] P1.4 Write missing scenario: F9b-rerun — cosmetic-only failure forwards to verify-human, not back to build (PP2 severity)  <!-- status: in-progress -->
  - [x] P1.5 Write missing scenario: F10-clarified — verify-auto recommends cheap/scoped checks not full test suite (PP2 scope)  <!-- status: in-progress -->
  - [x] P1.6 Write missing scenario: F10b — verify-self → verify-human when all blocking outcomes pass (PP2 self-verify happy path)  <!-- status: in-progress -->
  - [x] P1.7 Identify and write any additional gap scenarios surfaced by audit (P1.2)  <!-- status: in-progress -->
  - [x] P1.8 Run full suite post-gap-fill; confirm all PASS on haiku  <!-- status: in-progress -->
  - [x] verify-auto  <!-- status: in-progress -->
  - [x] verify-self  <!-- status: in-progress -->
  - [x] verify-human  <!-- status: in-progress -->
  - [x] verify-codify  <!-- status: in-progress -->

- [x] Phase 2: Argument-Hint Polish  <!-- status: in-progress; depends on Phase 1 -->
  **Observable outcomes:**
  - CLI: `grep "argument-hint" skills/feature-build/SKILL.md` outputs a hint containing "leaf IDs" or equivalent scoped-reentry language
  - CLI: `grep "argument-hint" skills/feature-verify-human/SKILL.md` outputs a hint that mentions scoped re-entry context
  - CLI: `grep "argument-hint" skills/feature-verify-auto/SKILL.md` outputs a hint that mentions scope or phase

  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — argument-hints are user-visible in Claude Code's skill picker
  - Requirements unchanged: yes
  - Solution still feasible: yes
  - No superior alternative discovered: yes
  **Verdict:** proceed

  - [x] P2.1 Update `feature-build` argument-hint to reflect scoped leaf IDs (e.g., `<optional: scoped leaf IDs from verify-human, e.g. P1.verify-human.1>`)  <!-- status: in-progress -->
  - [x] P2.2 Update `feature-verify-human` argument-hint to reflect that it outputs scoped leaf IDs  <!-- status: in-progress -->
  - [x] P2.3 Audit remaining modified skills (feature-verify-self, feature-verify-auto, feature-plan, task-act) — update hints if current language is misleading  <!-- status: in-progress -->
  - [x] verify-auto  <!-- status: in-progress -->
  - [x] verify-self  <!-- status: in-progress -->
  - [x] verify-human  <!-- status: in-progress -->
  - [x] verify-codify  <!-- status: in-progress -->

- [x] Phase 3: CLAUDE.md Documentation Update  <!-- status: in-progress; depends on Phase 2 -->
  **Observable outcomes:**
  - CLI: `grep "Work Tree" CLAUDE.md` matches at least 3 lines (section header + schema reference + status vocabulary)
  - CLI: `grep "Observable Outcomes" CLAUDE.md` matches at least 1 line
  - CLI: `grep "BLOCKING\|severity" CLAUDE.md` matches at least 1 line
  - CLI: `grep "verify-self" CLAUDE.md` matches at least 1 line in the Architecture section

  **Relevance check (before Phase 3):**
  - Requester still needs this: yes — CLAUDE.md is read by Claude on every session
  - Requirements unchanged: yes
  - Solution still feasible: yes
  - No superior alternative discovered: yes
  **Verdict:** proceed

  - [x] P3.1 Add Work Tree Format reference to CLAUDE.md Architecture section — point to CLAUDE.snippet.md as the canonical schema definition, summarize status vocabulary  <!-- status: in-progress -->
  - [x] P3.2 Add Observable Outcomes convention note — one line explaining they are written at plan time, must be mechanically verifiable  <!-- status: in-progress -->
  - [x] P3.3 Add severity taxonomy note — BLOCKING vs COSMETIC, with pointer to feature-verify-self SKILL.md for full taxonomy  <!-- status: in-progress -->
  - [x] P3.4 Add feature-verify-self to skill chain description in Architecture (it now sits between verify-auto and verify-human)  <!-- status: in-progress -->
  - [x] P3.5 Update transitions.md transition count if needed (currently says "65 transitions") — confirmed correct at 65  <!-- status: in-progress -->
  - [x] verify-auto  <!-- status: in-progress -->
  - [x] verify-self  <!-- status: in-progress -->
  - [x] verify-human  <!-- status: in-progress -->
  - [x] verify-codify  <!-- status: in-progress -->

- [x] Phase 4: install.sh Validation  <!-- status: in-progress; depends on Phase 3 -->
  **Observable outcomes:**
  - CLI: `./install.sh` exits 0 with no errors
  - CLI: `ls -la ~/.claude/skills/ | grep feature-verify-self` shows a symlink pointing to this repo
  - CLI: Running `./install.sh` a second time exits 0 with no changes (idempotent — no duplicate lines in CLAUDE.md, no broken symlinks)
  - CLI: `ls -la ~/.claude/skills/ | wc -l` matches the count of directories under `skills/`

  **Relevance check (before Phase 4):**
  - Requester still needs this: yes — install.sh is the deployment mechanism
  - Requirements unchanged: yes
  - Solution still feasible: yes
  - No superior alternative discovered: yes
  **Verdict:** proceed

  - [x] P4.1 Run `./install.sh` and verify output — all 31 skills + 4 agents [ok], no errors  <!-- status: in-progress -->
  - [x] P4.2 Verify `~/.claude/skills/feature-verify-self` symlink exists and resolves correctly  <!-- status: in-progress -->
  - [x] P4.3 Run `./install.sh` a second time — identical output, idempotent  <!-- status: in-progress -->
  - [x] P4.4 Confirm symlink count matches skill directory count — 31/31 ✓  <!-- status: in-progress -->
  - [x] P4.5 WP4.5 assessment: Playwright handled at verify-self layer via Agent spawn — no change needed in feature-build  <!-- status: in-progress -->
  - [x] verify-auto  <!-- status: in-progress -->
  - [x] verify-self  <!-- status: in-progress -->
  - [x] verify-human  <!-- status: in-progress -->
  - [x] verify-codify  <!-- status: in-progress -->

## Current Node
- **Path:** Feature > ship
- **Active scope:** All 4 phases [x]; tests/check-structure.sh created (13/13 PASS); ready to ship
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Retrospect
- **What changed in our understanding:** The gap scenarios (F13-prefiltered, F9b-rerun, F10-clarified, F10b) were already present in the scenario files from earlier WPs — no new writing needed. WP13's test work was primarily audit + confirmation, not net-new scenario authorship.
- **Assumptions that held:** All 85 scenarios pass clean on haiku with no flakiness. install.sh truly is idempotent — second run produces byte-identical output.
- **Assumptions that were wrong:** Plan assumed 4 gap scenarios needed writing; they were already written. The actual gap was a structural test script (check-structure.sh) that wasn't anticipated in the plan.
- **Approach delta:** Added tests/check-structure.sh (not in original plan) to codify the Phase 2–4 observable outcomes as permanent regression tests. This was the substantive verify-codify output.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
