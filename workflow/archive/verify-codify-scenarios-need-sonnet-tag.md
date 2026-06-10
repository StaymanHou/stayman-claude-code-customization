---
workflow: task
state: closed
drive_mode: autopilot
created: 2026-06-09
completed: 2026-06-09
backlog_ref: SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG
---

# Task: Apply `model: sonnet` recon tags to verify-codify scenarios that flake on haiku

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-06-09

## Problem Statement

Six verify-codify scenarios in `tests/scenarios/feature.yaml` SOFT_PASS or FAIL on haiku due to model-noise (missing TRANSITION line, prose-leak family) but are documented or suspected to PASS strictly on sonnet — they should carry a `model: sonnet` tag per the project's recon discipline.

## Context

- **Backlog entry:** `workflow/backlog.md` → SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG (P2)
- **Recon discipline:** documented in project `CLAUDE.md` under `## Commands` — *"New tests start untagged (haiku). Per-scenario `model: sonnet` is reserved for scenarios where haiku has been proven to produce model-noise — the recon discipline is: see a haiku failure, run the same scenario on sonnet, confirm it PASSes deterministically, then tag it."*
- **Target file:** `tests/scenarios/feature.yaml`
- **Existing precedent (tag format):** line 45 (F4) and line 871 (F22) carry `model: sonnet  # Haiku <flake-shape>; sonnet is reliable. <citation>.`
- **Six candidate scenarios:**
  - **F13-prefiltered** (line 181) — added 2026-05-13 full-sweep extension; FAILs on haiku with "no structured TRANSITION line"
  - **F13** (line 477) — SOFT_PASS on haiku per backlog
  - **F14** (line 498) — SOFT_PASS on haiku per backlog (output-shape issues)
  - **F15** (line 520) — SOFT_PASS on haiku per backlog (output-shape issues)
  - **F16-triage-ambiguous** (line 592) — SOFT_PASS on haiku per backlog (prose-leak family)
  - **F16-triage-flaky** (line 626) — SOFT_PASS on haiku per backlog (prose-leak family)
  - **F16-triage-regression** (line 559) — SOFT_PASS on haiku per backlog (prose-leak family)
  - **F-boundary-codify** (line 1281) — **already confirmed PASS strictly on sonnet 2026-05-13** per backlog, but no tag was applied at confirmation time
- **Runner invocation:** `./tests/run-tests.sh --id <comma-separated-ids> --model sonnet` forces sonnet across all listed scenarios; runtime budget per scenario typically 60-180s on sonnet.
- **Per-project runtime registry:** `runtimes.md` exists at project root — should consult before the sonnet sweep.

## Work Tree

- [x] T1 Read `runtimes.md` for any tracked entry on `./tests/run-tests.sh --id ... --model sonnet`; pick a `timeout` ms value or estimate (rough: 7 scenarios × ~120s = ~14 min wall ⇒ `--id` batch may need `--model sonnet` budget ~900000 ms; if absent, do a small subset first per Rule 3)  <!-- status: [x] — registry has only umbrella `./tests/run-tests.sh` entry (3097s last, clamped to 600000ms timeout). 7-scenario sonnet batch estimated ~600-900s; will run with timeout=600000 and let it auto-background per Rule 2 wait-discipline. -->
- [x] T2 Run the 7 candidate scenarios on sonnet via `./tests/run-tests.sh --id F13-prefiltered,F13,F14,F15,F16-triage-ambiguous,F16-triage-flaky,F16-triage-regression,F-boundary-codify --model sonnet` and capture per-scenario PASS/SOFT_PASS/FAIL  <!-- status: [x] — 197s sonnet sweep (run-2026-06-09-201149.json); 6 strict PASS (F13-prefiltered, F13, F14, F15, F16-triage-regression, F-boundary-codify), 2 SOFT_PASS on sonnet too (F16-triage-ambiguous, F16-triage-flaky) -->
- [x] T3 For each candidate that PASSed strictly on sonnet: add `model: sonnet  # Haiku <observed-flake-shape>; sonnet is reliable. See backlog SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG (recon 2026-06-09).` directly under the `skill:` line — matching the format at line 45 (F4) and line 871 (F22). For scenarios that SOFT_PASS or FAIL on sonnet too, NOTE in WIP `## Discoveries` and do NOT tag.  <!-- status: [x] — 6 tags applied to feature.yaml at F13-prefiltered, F13, F14, F15, F16-triage-regression, F-boundary-codify; F16-triage-ambiguous + F16-triage-flaky surfaced to backlog as SURFACE-2026-06-09-F16-TRIAGE-AMBIGUOUS-FLAKY-SOFT-PASS-ON-SONNET (not tagged) -->
- [x] T4 Verify the tags are syntactically valid YAML by running `./tests/run-tests.sh --dry-run --filter-model sonnet | grep -c '<each-tagged-id>'` (or equivalent enumeration) — each tagged ID should now appear in the sonnet partition.  <!-- status: [x] — sonnet partition went from 3 scenarios (F4, F22, S3) to 9 scenarios (+6 new tags), confirming all 6 tags route correctly -->
- [x] T5 Update `runtimes.md` with the observed wall-clock for the sonnet sweep (`--id <batch> --model sonnet`), per the registry's read+update discipline.  <!-- status: [x] — bookkeeping note added to runtimes.md frontmatter (`--id <N-batch> --model sonnet` shape isn't a tracked-command entry; per-scenario sonnet ≈ 25s recorded for future estimator use) -->
- [x] T6 Update `workflow/backlog.md` to mark SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG as `Status: resolved 2026-06-09` with a one-line summary of which IDs were tagged (or note any that didn't PASS strictly on sonnet and require follow-up).  <!-- status: [x] — P2 entry marked resolved with detailed status line; new follow-up SURFACE-2026-06-09-F16-TRIAGE-AMBIGUOUS-FLAKY-SOFT-PASS-ON-SONNET created -->

## Current Node
- **Path:** Task > (all complete)
- **Active scope:** all complete — ready for /task-close
- **Blocked:** none
- **Open discoveries:** 1 — SURFACE-2026-06-09-F16-TRIAGE-AMBIGUOUS-FLAKY-SOFT-PASS-ON-SONNET (logged to backlog, separate follow-up)

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

- [SURFACED-2026-06-09] T3 — F16-triage-ambiguous and F16-triage-flaky SOFT_PASS on **sonnet too** (197s sonnet sweep, 2026-06-09): F16-triage-ambiguous = "Contains 'pause' but also mentioned: auto-fix" (the assertion forbids "auto-fix" but sonnet's prose still references it while choosing the pause path); F16-triage-flaky = "Contains 'flaky' (no structured TRANSITION line)" (sonnet emits the right reasoning but skips the literal TRANSITION line). Neither is haiku-noise-only — they have deeper output-shape issues (scenario design vs. skill prose drift). Not tagged. Both logged to backlog as a follow-up SURFACE (separate from this P2 task).

## Retrospect

- **What changed in our understanding:** The 2026-05-13 backlog hypothesis was "all 6 candidates are likely haiku-noise; tag all 6 on confirmation." The empirical sonnet sweep refuted this for 2 of 6 — F16-triage-ambiguous and F16-triage-flaky SOFT_PASS on sonnet too, meaning their failure is NOT haiku-noise but a real assertion-shape or skill-prose issue. The recon discipline did exactly what it's designed to do: surface the cases that don't fit the haiku-noise hypothesis rather than silently tag-and-forget.
- **Assumptions that held:** (1) The 6 backlog-listed candidates all needed re-evaluation; F-boundary-codify needed its tag applied even though confirmed in 2026-05-13. (2) The `--id <batch> --model sonnet` shape was the right runner invocation. (3) The 600000ms timeout was sufficient (actual: 197s, well under). (4) The `model: sonnet` tag goes directly under `skill:` matching the F4/F22 precedent.
- **Assumptions that were wrong:** (1) "Likely all 6 fall into this category" (from the backlog suggested-action) was 4-of-6, not 6-of-6. (2) The runtimes.md entry for `./tests/run-tests.sh` (umbrella, 3097s) wouldn't apply to a small `--id <batch>` invocation — sonnet per-scenario is ~25s, not 60-120s as initially estimated. The 197s sweep is far below the 14-minute worst case. Future estimator: ~25s/scenario on sonnet for verify-* scenarios.
- **Approach delta:** Plan called for 6 candidates → 7 actually queued (F-boundary-codify was the +1 from the backlog re-confirmation). The plan accounted for "if any SOFT_PASS on sonnet too, surface them" as a contingency — the contingency triggered for 2 of 8, surfaced cleanly. No replanning needed; back-loop discipline (T6) was unnecessary.
