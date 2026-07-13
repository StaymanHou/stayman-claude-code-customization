---
workflow: task
state: verify (complete)
created: 2026-07-13
docs-only: false
drive_mode: autopilot
---

# Task: WP2 — check-structure pin tightening + settings-fixture strip

**Workflow:** task
**State:** verify (complete)
**Created:** 2026-07-13

## Problem Statement
Three `tests/check-structure.sh` findings: the Phase-7 settings-drift check FAILs on machine-local keys (the sweep's 1 outstanding suite failure), and two pins are looser than the contract they guard (container-down OR-branch too broad; `propose` pin too bare).

## Context
- Governed by `docs/product/backlog-paydown-2026-07-13-wbs.md` → WP2. Resolves 3 SURFACE IDs.
- **All three edits are in `tests/check-structure.sh`.** `docs-only: false` — this is harness code; the suite going green (esp. Phase 7) is the real verification.
- **Grounding done at plan time (two corrections to the naive patch):**
  - **EDIT 2:** the WBS's suggested anchor `start the container(s) yourself` does NOT literally exist — the actual clause (`skills/product-context/SKILL.md:73`) reads `Start the container(s) yourself` (capital S). Use pattern `[Ss]tart the container\(s\) yourself` — distinctive to the new clause, won't match the line-64 "First-run bootstrap" prose.
  - **EDIT 3:** `product-vision` does NOT contain the literal hyphenated `propose-never-auto-write` (0 hits) — it legitimately writes the contract as **"Propose, never auto-write."** (SKILL.md:64). The other 5 capture skills use the hyphenated token (1 hit each). So a uniform `propose-never-auto-write` pattern would FAIL on product-vision. → Use a both-forms-tolerant pattern `[Pp]ropose.{0,6}never.{0,6}auto-write` that still requires the full contract phrase (delivers the finding's intent: pin the *phrase*, not bare "propose") while tolerating product-vision's comma-form. Do NOT edit product-vision's prose — it's already correct.
- **Settings-strip design (EDIT 1):** `env` and `statusLine` hold repo-relevant keys (`CLAUDE_TIME_TRACKING`, `CLAUDE_CODE_ENABLE_TELEMETRY`, `statusLine.command`) that must stay drift-checked → strip specific machine-local key-PATHS, never whole `env`/`statusLine` keys.

## Work Tree

- [x] T1 EDIT 1 — extend `strip_host_specific()` with a `HOST_LOCAL_KEYS` path-allowlist + a `delete_path` helper; delete the 5 machine-local paths from BOTH live and fixture before `walk()`. Explanatory inline comment added.  <!-- status: [x] -->
- [x] T2 EDIT 2 — tighten container-down pin (line 178): → `"[Ss]tart the container\(s\) yourself"`  <!-- status: [x] -->
- [x] T3 EDIT 3 — tighten propose pin (line 1929): → `"[Pp]ropose.{0,6}never.{0,6}auto-write"` (both-forms tolerant)  <!-- status: [x] -->
- [x] T4 Ran `./tests/check-structure.sh` — `354 PASS / 0 FAIL`. Phase 7 now PASS; both tightened pins PASS (verified match ×1 product-context, ×6 capture skills incl product-vision). Suite flipped 353/1 → 354/0.  <!-- status: [x] -->
- [x] T5 Negative check DONE (empirical) — corrupted `env.CLAUDE_TIME_TRACKING` in fixture → Phase 7 correctly FAILed on it (`live="1" fixture="0"`); restored → 354/0. Confirms path-specific strip does NOT mask repo-owned sibling drift under env/statusLine.  <!-- status: [x] -->
- [x] T6 Marked 3 SURFACE statuses resolved: connector-drift (`backlog.md`), container-down + propose-pin (`backlog-quality-findings.md`).  <!-- status: [x] -->

## Verification Observable

**Observable:** The full structural suite passes with zero failures after WP2's harness edits — i.e. the settings-strip fixed the previously-failing Phase 7, and the two tightened pins still find their targets (no self-inflicted pin failure).
**Verification command:** `./tests/check-structure.sh`
**Expected result:** exit 0, summary `PASS: 354 | FAIL: 0`.

## Verification Result

**Status:** PASS
**Date:** 2026-07-13
**Evidence:** Fresh `./tests/check-structure.sh` → `PASS: 354 | FAIL: 0`, "All structural checks passed." Targeted lines: `[PASS] product-context SKILL.md adds container-down self-start instruction`; Phase 7 present with no FAIL; all 6 `[PASS] <skill> capture move is propose-never-auto-write` (including product-vision's comma-form). Plus the act-time negative test proved a corrupted repo-owned `env.CLAUDE_TIME_TRACKING` still FAILs.
**Notes:** Observable met exactly. The harness change is self-verifying — the suite validates its own tightened pins, and the negative test confirms the settings-strip is scoped (doesn't mask repo-owned sibling drift).

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [NOTE-2026-07-13] Two plan-time corrections to the naive patch, both caught by grounding before editing: (EDIT 2) the WBS-suggested anchor `start the container(s) yourself` didn't literally exist — actual clause is capital-S; (EDIT 3) `product-vision` uses the comma-form "Propose, never auto-write." not the hyphenated token, so a uniform `propose-never-auto-write` pin would have FAILed on it → used a both-forms-tolerant pattern instead of forcing a prose edit. Same lesson as WP1's Finding #1: a finding's suggested action is a hypothesis, verify against code first.

## Retrospect
- **What changed in our understanding:** Two of the three findings' *suggested actions* were subtly wrong — a naive apply would have (a) pinned a string that doesn't exist and (b) broken product-vision's pin. This is now the SECOND WP in a row (WP1 Finding #1 was the first) where the finding's suggested fix was a hypothesis that failed on contact with the code. Strong signal that "verify the finding against code before applying" is the load-bearing discipline of a debt sweep — not a nicety.
- **Assumptions that held:** The 3-axis scoring (Small effort · low risk, self-verifying via the suite) was right — WP2 was cheap and the suite validated its own harness change.
- **Assumptions that were wrong:** "Line 1929 = 6 one-line edits" (the finding's framing) — it's actually ONE loop pattern, and the uniform token the finding assumed doesn't hold across all 6 skills.
- **Approach delta:** Added an empirical negative test (corrupt a repo-owned sibling key → confirm still caught) rather than reasoning about it in prose. For a change that *loosens* a drift check, proving it doesn't over-loosen is the verification that matters — a green suite alone wouldn't have shown that.

## Completed
- **Completion date:** 2026-07-13
- **Status:** Completed (WP2 of backlog-paydown-2026-07-13 sweep)
