# Feature: Phase 2 — Agent Self-Verification Before Human Handoff

**Workflow:** feature
**State:** COMPLETED 2026-04-29
**Created:** 2026-04-28

## Problem Statement

The current verification loop hands off to the human immediately after automated tests pass. The agent never observes the running system — it never navigates a browser, checks the console, or hits a live endpoint. The human is used as a smoke-tester, not a judgment-layer. Phase 2 fixes this by making `verify-self` a real mandatory step: the agent observes the live system, classifies failures as blocking vs cosmetic, fixes blocking issues itself via a re-verify gate, and only presents items requiring genuine human judgment. This feature also clarifies `verify-auto`'s narrow role (cheap, fast, scoped to the specific code change) and enforces that Observable outcomes are written at plan time — not retrofitted.

## Work Tree

- [x] Phase 1: Observable outcomes format + feature-plan prompt  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -r "Observable outcomes" skills/feature-plan/SKILL.md` exits 0 with content showing explicit testability guidance
  - CLI: `grep -i "testable\|verifiable\|HTTP\|browser\|curl" skills/feature-plan/SKILL.md` matches ≥ 3 lines in the Observable outcomes section
  - CLI: `grep -i "not prose\|declarative\|must include" skills/feature-plan/SKILL.md` exits 0
  - [x] P1.1 Update `skills/feature-plan/SKILL.md` — add explicit guidance that Observable outcomes must be declarative and testable (e.g. "must include at least one HTTP, browser, or CLI check per phase"); warn against prose outcomes that cannot be mechanically verified  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete — skipped: prompt-only change, all CLI outcomes confirmed by verify-self -->
  - [x] verify-codify  <!-- status: complete — F7-observable-outcomes scenario added and passes -->

- [x] Phase 2: Severity taxonomy + feature-verify-self finalization  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -i "BLOCKING\|COSMETIC" skills/feature-verify-self/SKILL.md` matches ≥ 6 lines (taxonomy defined inline)
  - CLI: `grep -i "blank page\|JS console\|crash\|data loss\|auth" skills/feature-verify-self/SKILL.md` exits 0 (blocking examples present)
  - CLI: `grep -i "spacing\|color\|copy\|cosmetic" skills/feature-verify-self/SKILL.md` exits 0 (cosmetic examples present)
  - CLI: `grep -i "Playwright unavailable\|curl.only\|fallback" skills/feature-verify-self/SKILL.md` exits 0 (graceful degradation documented)
  - CLI: `grep "F9b\|F10b" skills/feature-verify-self/SKILL.md` exits 0 (both transitions present)
  - [x] P2.1 Finalize `skills/feature-verify-self/SKILL.md` — expand the severity taxonomy section inline (BLOCKING: blank page, JS error, crash, missing required element, broken navigation, auth failure, data loss, wrong HTTP status; COSMETIC: spacing, color, copy, minor layout, non-critical decoration); verify both transitions F9b and F10b are clearly stated; verify Playwright fallback procedure is complete  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete — skipped: prompt-only change, all CLI outcomes confirmed by verify-self -->
  - [x] verify-codify  <!-- status: complete — F9b and F10b scenarios added, both PASS -->

- [x] Phase 3: feature-verify-auto prompt clarification  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -i "cheap\|fast\|scoped\|syntax\|lint\|import" skills/feature-verify-auto/SKILL.md` exits 0
  - CLI: `grep -i "do not run\|avoid\|full test suite\|not the full" skills/feature-verify-auto/SKILL.md` exits 0
  - CLI: `grep -i "temporary\|one.off\|may not become" skills/feature-verify-auto/SKILL.md` exits 0
  - [x] P3.1 Update `skills/feature-verify-auto/SKILL.md` — reframe role as cheap/fast early-indicator; add concrete examples (syntax check, lint, import-smoke: instantiate the class just created); explicitly warn against running the full test suite; clarify tests are temporary/one-off and may or may not be codified later  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete — skipped: prompt-only change, all CLI outcomes confirmed by verify-self -->
  - [x] verify-codify  <!-- status: complete — F10-clarified scenario added, PASS -->

- [x] Phase 4: Re-verify gate in feature-build  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -i "re.verify\|re-run.*behavioral\|re-run.*failed" skills/feature-build/SKILL.md` exits 0
  - CLI: `grep -i "before.*verify-auto\|before.*handing" skills/feature-build/SKILL.md | grep -i "behavioral\|observable"` exits 0
  - CLI: `grep "F9b\|verify-self" skills/feature-build/SKILL.md` exits 0 (build knows about verify-self back-loop)
  - [x] P4.1 Update `skills/feature-build/SKILL.md` — add re-verify gate (Step 6): when re-entering from verify-self back-loop, re-run the previously failed behavioral checks before transitioning to verify-auto; concrete curl/browser/CLI instructions; if re-verify fails, stay in build  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete — skipped: prompt-only change, all CLI outcomes confirmed by verify-self -->
  - [x] verify-codify  <!-- status: complete — F8-reverify scenario added, PASS -->

- [x] Phase 5: feature-verify-human pre-filtering from verify-self  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -i "pre.filter\|already.*verified\|verify-self.*pass\|exclude.*verify-self\|EXCLUDED" skills/feature-verify-human/SKILL.md` exits 0
  - CLI: `grep -i "UNVERIFIED\|agent could not verify\|check manually" skills/feature-verify-human/SKILL.md` exits 0
  - CLI: `grep -i "BLOCKING\|COSMETIC" skills/feature-verify-human/SKILL.md` exits 0 (taxonomy referenced)
  - [x] P5.1 Update `skills/feature-verify-human/SKILL.md` — strengthen pre-filter section: EXCLUDED table, UNVERIFIED annotation, FAILED-cosmetic as low-priority note, inline severity taxonomy  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete — skipped: prompt-only change, all CLI outcomes confirmed by verify-self -->
  - [x] verify-codify  <!-- status: complete — F13-prefiltered scenario added, PASS -->

- [x] Phase 6: Transition test scenarios  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --id F9b,F10b,F9b-rerun,F10-clarified --dry-run` exits 0 (scenarios recognized)
  - CLI: `./tests/run-tests.sh --id F9b,F10b,F9b-rerun,F10-clarified --model haiku` all pass (green)
  - CLI: `grep "F9b\|F10b\|F9b-rerun\|F10-clarified" tests/scenarios/feature.yaml` exits 0 (scenarios present)
  - [x] P6.1 Add test fixture `tests/fixtures/wip/feature-verify-self-blocking.md`  <!-- status: complete -->
  - [x] P6.2 Add test fixture `tests/fixtures/wip/feature-verify-self-passed.md`  <!-- status: complete -->
  - [x] P6.3 Add scenario `F9b` — PASS  <!-- status: complete -->
  - [x] P6.4 Add scenario `F10b` — PASS  <!-- status: complete -->
  - [x] P6.5 Add scenario `F9b-rerun` — PASS  <!-- status: complete -->
  - [x] P6.6 Add scenario `F10-clarified` — PASS  <!-- status: complete -->
  - [x] P6.7 `install.sh` symlink for `feature-verify-self` verified present and correct  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete — skipped: test scenarios only, all outcomes confirmed by verify-self -->
  - [x] verify-codify  <!-- status: complete — scenarios are the codification; all pass -->

## Current Node
- **Path:** Feature > COMPLETE
- **Active scope:** all phases done — ready to ship
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Session Pause — 2026-04-28 16:15
Paused. See `workflow/.session.md` to resume.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
