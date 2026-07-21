---
workflow: task
state: verify (complete)
created: 2026-07-13
docs-only: false
drive_mode: autopilot
---

# Task: WP3 — frontmatter-YAML-parseability structural phase

**Workflow:** task
**State:** verify (complete)
**Created:** 2026-07-13

## Problem Statement
`tests/check-structure.sh` does not validate that every SKILL.md / AGENTS.md frontmatter is parseable YAML — an invalid value (e.g. an unquoted inner-colon `argument-hint:`) silently breaks the harness's skill registry at next session load; add a check that catches it.

## Context
- Governed by `docs/product/backlog-paydown-2026-07-13-wbs.md` → WP3 (Order P1). Resolves `SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN` + folds in `SURFACE-2026-06-13-QUALITY-YAML-PIN-PLACEMENT-NOTE`.
- `docs-only: false` — adds real logic to `tests/check-structure.sh`.
- **Grounding (this session):** pyyaml available (6.0.2); all 47 target files (`skills/*/SKILL.md` + `agents/*/AGENTS.md`) start with `---`; Phase 3 ends ~line 285 / Phase 3b starts line 288 comment → **land as [Phase 3a] between them** (placement-note requirement — not a tail phase). Reporter idiom: `check "$desc" "pass"` / `check "$desc" "fail" "$detail"`.
- **Frontmatter extraction idiom:** `awk '/^---$/{c++; next} c==1'` — prints only the block between the FIRST and SECOND `---` (ignores body `---` horizontal rules). Pipe to `python3 -c "import sys,yaml; yaml.safe_load(sys.stdin.read())"`.
- **Property-test discipline** (`docs/lessons/test-harness-primitives.md`): the new primitive must be tested against BOTH good and bad input. Bad-input fixture goes in the SCRATCHPAD, never committed into `skills/` — a broken file under `skills/` would trigger the exact registry-break this guards against.

## Work Tree

- [x] T1 Inserted `[Phase 3a] Frontmatter YAML parseability` between Phase 3 and 3b — python3-guarded, iterates 47 files, awk-extract + `yaml.safe_load`, per-file `check` reporter, why-comment block. Includes `set -e` safety (sentinel + `|| true`).  <!-- status: [x] -->
- [x] T2 Property-test BAD input — scratchpad broken-fm.md (unquoted inner-colon + unclosed `[`) → CORRECTLY FAILED (yaml raised).  <!-- status: [x] -->
- [x] T3 Property-test GOOD input — real task-plan/SKILL.md → CORRECTLY PASSED; throwaway deleted (never committed to skills/).  <!-- status: [x] -->
- [x] T4 Ran suite — `401 PASS / 0 FAIL`. Phase 3a fired for all 47 files. **Caught a real bug** (feature-build unquoted argument-hint) → fixed in-place → re-verified green.  <!-- status: [x] -->
- [x] T5 Marked both SURFACEs resolved (parent in `backlog.md`, placement-note in `backlog-quality-findings.md`).  <!-- status: [x] -->
- [x] T6 Updated `runtimes.md` — Last 21s (was 17s; +4s from 47 python spawns), timeout unchanged (90000).  <!-- status: [x] -->

## Verification Observable

**Observable:** The full structural suite passes with zero failures, and the new `[Phase 3a]` check is present and fires a parse assertion for every SKILL.md/AGENTS.md (including the just-fixed feature-build).
**Verification command:** `./tests/check-structure.sh`
**Expected result:** exit 0, summary `PASS: 401 | FAIL: 0`, with `[PASS] skills/feature-build/SKILL.md frontmatter is parseable YAML` present in the Phase 3a block.

## Verification Result

**Status:** PASS
**Date:** 2026-07-13
**Evidence:** Fresh `./tests/check-structure.sh` → `PASS: 401 | FAIL: 0`, "All structural checks passed." `[Phase 3a] Frontmatter YAML parseability` present; `[PASS] skills/feature-build/SKILL.md frontmatter is parseable YAML` confirms the fixed file now passes the new check. Plus the act-time property-test proved the check FAILs on deliberately-broken YAML and PASSes on valid.
**Notes:** Observable met. The check is doubly validated — the property-test proved it discriminates good/bad input, and it caught+drove the fix of a real in-the-wild bug (feature-build) on its first full run.

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [CAUGHT-2026-07-13] T4 — the new Phase 3a check immediately surfaced a REAL latent bug: `skills/feature-build/SKILL.md:4` had an unquoted inner-colon `argument-hint:` value (`<optional: scoped leaf IDs...>`) → invalid YAML (`mapping values are not allowed here`). This is EXACTLY the failure class SURFACE-2026-06-13 hypothesized. Fixed in-place by quoting the value (one line, string preserved verbatim). Re-verified: 400/1 → 401/0. The check paid for itself on its first run. NB per docs/lessons/harness-bootstrap-skip.md: the running harness served the pre-quote frontmatter this session, but the fix is validated by check-structure's fresh subprocess parse; the corrected registry loads next session.
- [NOTE-2026-07-13] set -e safety: the parse pipeline uses `{ ... && echo __YAML_OK__; } || true` with a sentinel so a failing parse (non-zero python exit) neither aborts the script under `set -euo pipefail` nor is mistaken for a valid empty block.

## Retrospect
- **What changed in our understanding:** The SURFACE hypothesized this failure mode ("an invalid argument-hint could break the registry") but assumed it was a *past, already-fixed* instance (util-prune-claude-md, fixed 2026-06-13). WP3 revealed a **currently-live** instance in feature-build that had gone undetected — the check didn't just prevent future bugs, it found a present one. A "write the guard" task became a "write the guard AND it immediately earns out" task.
- **Assumptions that held:** pyyaml available, uniform `---` delimiters, Phase 3a placement — all confirmed at plan time, all held. Property-testing the primitive before trusting it (per the test-harness-primitives lesson) was the right discipline.
- **Assumptions that were wrong:** "expect suite to just go green (+47 PASS)" — it went 400/**1** first because of the real bug. Good: the plan's verification step (run the suite) is what surfaced it, not luck.
- **Approach delta:** Had to handle a SURFACED-sibling-bug (feature-build) mid-act. Fixed it in-place because it was a one-line trivial extension directly in the WP's purpose (a frontmatter-parse guard that leaves a known-broken frontmatter file unfixed is self-defeating), and re-verified via the fresh subprocess. Recorded per the bootstrap-skip lesson (running harness served stale frontmatter this session; fix loads next session).

## Completed
- **Completion date:** 2026-07-13
- **Status:** Completed (WP3 of backlog-paydown-2026-07-13 sweep)
