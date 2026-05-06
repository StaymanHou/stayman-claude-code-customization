---
workflow: feature
state: complete
drive_mode: full-autopilot
created: 2026-05-06
completed: 2026-05-06
---

# Feature: transition_id_any + not_contains_strict harness extensions — Completed 2026-05-06

## Goal

Resolve the three remaining backlog items (D2, S9-S11-S14 dual-identity, S10-S13 routing-vs-drive-mode) by adding two opt-in features to `tests/lib/verify.sh`:

1. `transition_id_any: [A, B, C]` — accepts any of multiple IDs as PASS, for scenarios with legitimate dual identity (orchestrator emitting either S-ID or F-ID).
2. `not_contains_strict: true` — flips negative content match from warning to FAIL, for scenarios where prose-leak is a real behavior bug.

## Retrospect

- **What changed in our understanding:** Strict mode wasn't a precision-only improvement; on its very first run it surfaced a real bug (S12 emitting "auto-chain" prose in autopilot mode). The lenient default was hiding signal. Adding a `not_contains_strict` opt-in is the right tradeoff: existing scenarios keep their warning behavior, while opt-in scenarios get hard signal where it matters.
- **Assumptions that held:** `transition_id_any` would resolve the dual-identity SOFT_PASSes for orchestration steps. S9 confirms cleanly. The pre-existing `parse_scenario_nested` already converts YAML lists to pipe-separated strings, so no parser changes were needed.
- **Assumptions that were wrong:** Initial cut of the strict-mode flag compared `not_contains_strict` to literal "true", but Python's YAML serialization yields "True" (capital T) when `parse_scenario_field` does `str(val)`. First sweep showed S12 PASSing despite the strict tag — the flag was never activating. Fixed with case-insensitive normalization (`true|yes|on|1`).
- **Approach delta:** Plan was "extend the harness, update scenarios, sweep, ship". Reality matched, except the strict-mode bug needed a quick re-run mid-sweep. Total cost ~$2 across two sweeps + one retest. No oscillation, no new tasks spawned.

## Changes

- **`tests/lib/verify.sh`** — `verify_result()` extended with two new args. Backward-compatible: empty-string defaults preserve all prior behavior.
- **`tests/run-tests.sh`** — pulls `expect.transition_id_any` and `expect.not_contains_strict` from scenario YAML; passes through to verify.
- **`tests/scenarios/session.yaml`** — S9/S10/S11/S12/S13/S14 updated to use `transition_id_any`. S12, S14 also get `not_contains_strict: true`.
- **`CLAUDE.md`** — Conventions bullet documents the new fields.
- **`workflow/backlog.md`** — 6 RESOLVED entries (this feature + prior follow-ups), 1 new pending (S12 prose-leak).

## Verification

- run-2026-05-06-142557.json — initial sweep, surfaced strict-mode bug
- run-2026-05-06-143442.json — strict-mode fix verified (S12 changed behavior)
- run-2026-05-06-143839-combined.json — final wrapper sweep:
  - 3 PASS, 3 FLAKY, 10 SOFT_PASS, 1 FAIL (the FAIL is S12 strict-mode catching a real prose-leak bug)
  - S3 sonnet pass solid
  - tests/check-structure.sh: 13/13 PASS

## Closure

Two harness features shipped. Zero behavior regressions in untouched scenarios. One real bug surfaced (S12 auto-chain prose leak in autopilot mode) — logged in backlog for follow-up.
