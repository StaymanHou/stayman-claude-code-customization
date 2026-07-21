---
workflow: task
state: verify (complete)
created: 2026-06-12
docs-only: false
drive_mode: autopilot
---

# Task: Phase 10 back-reference pin (subagent_type → tools-marker agent)

**Workflow:** task
**State:** verify (complete)
**Created:** 2026-06-12

## Problem Statement
Extend `tests/check-structure.sh` Phase 10 with a back-reference pin: every `subagent_type: '<name>'` reference in skills must point to an `agents/<name>/AGENTS.md` with `tools:` frontmatter (executable-subagent marker), NOT `skills:` (reference-only marker). Resolves SURFACE-2026-06-12-QUALITY-SUBAGENT-DISPATCH-PIN-ASYMMETRIC (forward-only enforcement gap) + SURFACE-2026-06-12-REFERENCE-WORKFLOW-AGENTS-ARE-INVOKABLE (latent risk: 4 `*-workflow/AGENTS.md` files are registered as invokable but should not be `subagent_type:` targets).

## Context
- `tests/check-structure.sh:1437-1538` — Phase 10 "Subagent dispatch wiring" block; pin extends the cross-skill loop after assertion (e).
- 4 real `subagent_type:` references found (2 in `skills/feature-verify-self/SKILL.md`, 2 in `skills/feature-review-quality/SKILL.md`). Both target executable subagents (`feature-verify-self-runner`, `code-quality-reviewer`) which have `tools:` frontmatter. Pin will PASS for both today.
- Expected PASS delta: +4 (one per reference, since each is an independent dispatch site). Run total: 210 → 214.
- `skills/session-start/SKILL.md:202` contains `Agent({subagent_type: "..."})` as a literal placeholder in prose — must not match the pin's regex. Pin regex requires non-empty alphanumeric inside quotes to skip this.
- Per arch.md: no state machine change. Structural-pin extension only.
- Per CLAUDE.md "Category-level conventions need the harness's own marker, not just a documentation marker" — this task closes the symmetric-enforcement gap that motivated that very rule.
- Backlog entries: lines 20-29 (P-quality, asymmetric pin) and lines 42-51 (P7, reference-workflow-agents-invokable) in `workflow/backlog.md`.

## Work Tree

- [x] T1 Extend Phase 10 with back-reference pin: iterate `skills/*/SKILL.md`, regex-match `subagent_type: '<name>'` (non-empty name), assert `agents/<name>/AGENTS.md` exists AND its frontmatter has `tools:` (not `skills:`). One pin per reference (line-level), so PASS count tracks dispatch-site count.
- [x] T2 Run `./tests/check-structure.sh` from repo root; confirmed PASS count 210 → 214, 0 FAIL.
- [x] T3 Bite-verification: mutated `feature-verify-self`'s `subagent_type: 'feature-verify-self-runner'` → `'feature-workflow'`; pin FAILed with informative message naming the offending skill, file, and SURFACE-ID. Reverted; re-ran clean (214/0).
- [x] T4 Resolve both backlog entries — task-close handles this per its standard procedure (CHANGELOG `**Backlog resolved:**` lines + status flip).

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** see below (one resolved discovery from act §T1; no new discoveries from verify)

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
- [SURFACED-2026-06-12] T1 — `general-purpose` is a harness-built-in subagent (no `agents/<name>/AGENTS.md` backing in this repo) used as bootstrap-skip fallback in both `feature-verify-self` and `feature-review-quality` SKILL.md. The pin's initial form FAILed on these 2 references because it expected every reference to point at an in-repo agent file. Resolution: added `case "$ref_name" in general-purpose) continue ;; esac` allowlist before the file-exists check. Net PASS delta is now +4 (not +2 as initially feared): the allowlist correctly skips the 2 `general-purpose` references, leaving the 4 in-repo references (`feature-verify-self-runner` ×2, `code-quality-reviewer` ×2) to PASS the new pin — matching the original plan-time estimate. Plan-time scope unchanged.

## Verification Observable

**Observable:** Running `./tests/check-structure.sh` from repo root completes with PASS=214 and FAIL=0, and the [Phase 10] section header is present in output along with the new "→ subagent_type" assertion lines from the back-reference pin.
**Verification command:** `./tests/check-structure.sh`
**Expected result:** Exit code 0; final summary line reads `PASS: 214 | FAIL: 0`; "All structural checks passed." follows; output contains ≥4 lines matching `→ subagent_type '<name>': target has tools: frontmatter (executable subagent)`.

## Verification Result

**Status:** PASS
**Date:** 2026-06-12
**Evidence:** Exit code 0. Final 3 lines of output:
```
=== Summary ===
PASS: 214 | FAIL: 0
All structural checks passed.
```
Back-reference pin assertion lines found: 4 (matches expected count — 2 references × 2 dispatch-aware skills, all pointing at executable subagents).
**Notes:** Verification PASSed against all four declared criteria. The new Phase 10 (f) pin block is wired and emits 4 PASS assertions on the current dispatch-site set. Bite-verification already confirmed in act §T3 (FAIL surface fires with informative message when a reference is mutated to a `skills:`-only target). Ready for /task-close.

## Retrospect

- **What changed in our understanding:** The plan-time PASS-count estimate (+4) was correct *by coincidence* — for the wrong reason. Plan-time counting saw 4 in-repo `subagent_type:` references and assumed all 4 would PASS the new pin. Act-time discovery: 2 of the 4 grep-matched references are `general-purpose` bootstrap-skip fallbacks (harness-built-in, no in-repo backing), which the pin had to allowlist. Final count is +4 again, but from the 4 non-allowlist references (2 `feature-verify-self-runner` + 2 `code-quality-reviewer`), not from 4 of the original grep matches.
- **Assumptions that held:** (a) Phase 10 is the right home for the pin (no new pin block needed). (b) The pin shape — iterate skills' `subagent_type:` references, assert target has `tools:` — was correct. (c) Bite-verification by mutation produced an informative FAIL message naming the offending skill, target file, and SURFACE-ID — exactly the regression signal future readers will need.
- **Assumptions that were wrong:** I assumed every `subagent_type:` reference would point at an in-repo `agents/<name>/AGENTS.md` file. The bootstrap-skip prose in two dispatch-aware skills' §2 references `subagent_type: 'general-purpose'` as the fallback target — `general-purpose` is harness-provided, not in-repo. Plan-time grep saw the references but I didn't follow up on what they pointed at. The fix (case-statement allowlist) was small but exposed a planning-discipline gap: when grepping for references, I should also have checked the *resolved targets* of those references at plan time, not just the reference count.
- **Approach delta:** Plan said "extend Phase 10 with back-reference pin, run check-structure.sh, bite-verify." Actual sequence: extend Phase 10 → run → FAIL on `general-purpose` references → diagnose → add allowlist → re-run → PASS → bite-verify → revert → PASS. One unplanned diagnostic loop in act, no formal back-loop (the plan's scope was correct; the implementation needed an allowlist). T4 (resolve backlog entries) became close-handled per its standard procedure, not a separate task step. Net: +1 unplanned act-time iteration, zero formal back-loops, two backlog items resolved.

## Closure Notice

**Closure notice:** Task `subagent-dispatch-back-reference-pin` is complete. `tests/check-structure.sh` Phase 10 now enforces back-reference symmetry: any skill's `subagent_type: '<name>'` reference must point at an `agents/<name>/AGENTS.md` with `tools:` frontmatter (executable-subagent marker), not `skills:` (reference-only marker), with `general-purpose` allowlisted as a harness-built-in fallback. PASS count 210 → 214; bite-verified by mutating a reference to `feature-workflow` and confirming the pin FAILs informatively. Resolves SURFACE-2026-06-12-QUALITY-SUBAGENT-DISPATCH-PIN-ASYMMETRIC and SURFACE-2026-06-12-REFERENCE-WORKFLOW-AGENTS-ARE-INVOKABLE. Requester = operator — closure notice for self-record.
