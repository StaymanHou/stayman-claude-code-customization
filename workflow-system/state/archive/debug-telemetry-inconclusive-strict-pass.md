---
workflow: task
state: verify (complete)
created: 2026-06-12
docs-only: false
drive_mode: autopilot
---

# Task: Harness regex broadening for markdown-bold mid-token TRANSITION emits

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-06-12

## Problem Statement
`DEBUG-TELEMETRY-INCONCLUSIVE` scenario SOFT_PASSes on sonnet because the harness regex `s/.*TRANSITION:[*[:space:]]*\([A-Za-z0-9_-]*\).*/\1/p` cannot capture across mid-token `**` (e.g., `**TRANSITION: DEBUG**-TELEMETRY-INCONCLUSIVE` captures only `DEBUG`); fix the asymmetric prefix-tolerance by stripping `*` from input before capture.

## Context

Backlog item: `SURFACE-2026-06-12-DEBUG-TELEMETRY-INCONCLUSIVE-STRICT-PASS-NEEDED` (P-followup, low priority).

Three candidate paths from the SURFACE; path (b) selected — **harness regex broadening**. Rationale:
- Path (a) — skill-prose fix: fights model behavior. Sonnet already ignored explicit "no markdown decoration" instructions per 3 prior bite-verify attempts (SURFACE notes $0.07 + $0.09 + $0.09 = $0.25 spent on prose tightening). Markdown-bold of tokens is a model default; prose alone won't suppress it reliably.
- Path (b) — harness regex broadening: fixes the actual primitive bug. The current regex already strips leading `**` (the `[*[:space:]]*` prefix-tolerance at line 39); the asymmetry is that mid-token `**` is not handled. Surgical fix: pre-process input with `tr -d '*'` to strip ALL asterisks before applying the capture regex. `*` is not valid in any F/I/T/P/S/DEBUG token, so stripping is safe — it relaxes accepted shapes without inventing new matches.
- Path (c) — accept SOFT_PASS: status quo.

Files touched:
- `tests/lib/verify.sh` line 39 — the canonical regex used by `verify_result`.
- `tests/run-tests.sh` line 244 — duplicate regex used for display/logging (`transition_found` for output formatting). The actual verification result already came from `verify_result` via `$rc`, but keep the display regex consistent with the canonical one for grep-able log output. (Also has a separate bug: missing `[*[:space:]]*` prefix-tolerance + missing hyphen in capture class — drifted from verify.sh. Fixing both occurrences in lock-step is scope-symmetry discipline.)
- `tests/scenarios/debug.yaml` — update `DEBUG-TELEMETRY-INCONCLUSIVE` scenario's inline comment (currently documents the SOFT_PASS workaround at lines 161-162) to reflect strict-PASS achievement once verified.
- `workflow/backlog.md` — `SURFACE-2026-06-12-DEBUG-TELEMETRY-INCONCLUSIVE-STRICT-PASS-NEEDED` resolved at task close.

**Risk surface:** could the strip cause false positives? Only if some non-TRANSITION text already contained `TRANSITION:` plus a valid alnum-hyphen ID elsewhere — but then it would already match without the strip. Stripping `*` only widens accepted shapes, never invents new matches. Smoke-test by re-running a sample of currently-PASSing scenarios after the change.

## Work Tree

- [x] T1 Update `tests/lib/verify.sh` line 39 — insert `tr -d '*'` between `echo "$result_text"` and `sed`  <!-- status: done -->
- [x] T2 Update `tests/run-tests.sh` line 244 — same `tr -d '*'` insertion + add hyphen to capture class for consistency with verify.sh  <!-- status: done -->
- [x] T3 Update inline comment block on the verify.sh regex (lines 33-38) — document that `tr -d '*'` strips ALL asterisks (incl. mid-token) and explain why stripping is safe  <!-- status: done — inline with T1 -->
- [x] T3.5 **DISCOVERED:** Changed `head -1` → `tail -1` in both regex pipelines. Root cause is broader than SURFACE described: `debug-empirical-telemetry` SKILL.md §1 line 69 intentionally emits `TRANSITION: DEBUG-TELEMETRY-START` mid-procedure (informational gate-met signal), then §7 emits the terminal `TRANSITION: DEBUG-TELEMETRY-INCONCLUSIVE`. `head -1` grabbed the first (START), not the last (INCONCLUSIVE). Both fixes (tr -d '*' + head→tail) were needed.  <!-- status: done -->
- [x] T4 Bite-verified `DEBUG-TELEMETRY-INCONCLUSIVE` on sonnet → strict PASS, 21s, $0.088 (run-2026-06-12-135204.json)  <!-- status: done -->
- [x] T5 Regression smoke-test: ran DEBUG-BISECT-GATE-MET, DEBUG-TELEMETRY-GATE-MET, F16-triage-flaky, F16-triage-ambiguous on haiku → 3 PASS + 1 SOFT_PASS. The SOFT_PASS (DEBUG-BISECT-GATE-MET haiku) reproduces pre-fix baseline flakiness (06-09 baseline runs show same intermittent SOFT_PASS pattern; haiku is noisy on debug-* gates). Sonnet re-run of same scenario: PASS. No regression introduced.  <!-- status: done -->
- [x] T6 Updated `tests/scenarios/debug.yaml` inline comment on DEBUG-TELEMETRY-INCONCLUSIVE — replaced SOFT_PASS-explainer with strict-PASS confirmation + harness-fix rationale  <!-- status: done -->

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
[SURFACED-2026-06-12] T3.5 — DEBUG-TELEMETRY-INCONCLUSIVE bite-verify revealed `transition_found: DEBUG-TELEMETRY-START`, not the markdown-bold capture-truncation the SURFACE described. Root cause is `head -1` picking the first (intermediate) TRANSITION emit instead of the last (terminal). Model is flaky between two emission patterns. Both fixes (tr -d '*' + head→tail) are required. Sibling fix added to scope at T3.5; no T6 back-loop needed since the additional change touches the same lines/files the plan already covers.

## Verification Observable

**Observable:** Running the `DEBUG-TELEMETRY-INCONCLUSIVE` test scenario on sonnet produces a strict PASS (not SOFT_PASS), confirming the harness regex now captures the terminal `DEBUG-TELEMETRY-INCONCLUSIVE` TRANSITION emit despite mid-procedure START emit and/or markdown-bold decoration.
**Verification command:** `./tests/run-tests.sh --id DEBUG-TELEMETRY-INCONCLUSIVE --model sonnet`
**Expected result:** Output contains `DEBUG-TELEMETRY-INCONCLUSIVE ... PASS` (not SOFT_PASS) and final summary shows `PASS=1 SOFT=0 FAIL=0`.

## Verification Result

**Status:** PASS
**Date:** 2026-06-12
**Evidence:** Run 2026-06-12-141818 — `DEBUG-TELEMETRY-INCONCLUSIVE debug-empirical-telemetry: 3 rounds exhausted, no converging observable → INCONCLUSIVE ... PASS`; Summary `TOTAL PASS=1 SOFT=0 FAIL=0 FLAKY=0`; 16s, $0.085.
**Notes:** Strict PASS confirmed on first attempt. Harness regex fixes (tr -d '*' + tail -1) successfully captured the terminal `DEBUG-TELEMETRY-INCONCLUSIVE` TRANSITION emit.

## Retrospect

- **What changed in our understanding:** The SURFACE described one bug (markdown-bold mid-token capture-truncation), but bite-verify revealed an orthogonal bug — multi-emit TRANSITION lines + `head -1` picking the first (intermediate) instead of the last (terminal). The `debug-empirical-telemetry` SKILL.md design intentionally emits `TRANSITION: DEBUG-TELEMETRY-START` mid-procedure (§1 gate-met informational signal) followed by a terminal token at §6/§7. This multi-emit design is a SKILL.md property the harness needed to accommodate. Sonnet's emission behavior flakes between two patterns (markdown-bold OR multi-emit); both needed fixing.
- **Assumptions that held:** Path (b) — harness regex broadening — was the right candidate selection. Pre-test hypothesis was that path (a) skill-prose fix would have failed because sonnet's markdown decoration of tokens is a deep model default not suppressible by prose alone. Confirmed: even after the harness fix, sonnet still emits multi-emit patterns; the right surface is the harness, not the prose.
- **Assumptions that were wrong:** Plan assumed a single root cause (the SURFACE's markdown hypothesis). Reality: two orthogonal root causes both contributing. Plan was extended in-act at T3.5 without a back-loop because the additional change touched the same files/lines the plan already scoped.
- **Approach delta:** Plan said "edit verify.sh + run-tests.sh regex + bite-verify + smoke-test + yaml comment." Actual sequence inserted T3.5 (head→tail change) after the first bite-verify revealed the orthogonal bug. Net: one extra impl task added mid-act; no back-loop. Total scope was bigger than the SURFACE proposed but smaller than would have triggered ESCALATE.

## Closure Notice

**Closure notice:** Task `debug-telemetry-inconclusive-strict-pass` is complete. Fixed two harness-regex bugs in `tests/lib/verify.sh` and `tests/run-tests.sh` (markdown-bold strip via `tr -d '*'` + terminal-emit selection via `tail -1`) so the `DEBUG-TELEMETRY-INCONCLUSIVE` scenario now PASSes strictly on sonnet. Verify: `./tests/run-tests.sh --id DEBUG-TELEMETRY-INCONCLUSIVE --model sonnet` should show PASS (not SOFT_PASS). Requester = operator — closure notice for self-record.
