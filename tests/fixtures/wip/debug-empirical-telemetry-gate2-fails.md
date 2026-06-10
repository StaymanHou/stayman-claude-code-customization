# Bug: Config lookup fails — `KeyError: 'emial'` in user-onboarding code

**Workflow:** feature
**State:** build (Phase 1 — fix attempt)
**Created:** 2026-06-10

## Problem Statement
The user-onboarding flow crashes with `KeyError: 'emial'` when looking up the email field from a config dict. The crash is 100% reproducible — every onboarding call fails on the same line. The stack trace points clearly at `config_loader.py:42: return config["emial"]`. The config schema documents the field as `email`, and every other reference in the codebase uses `email` correctly.

## Investigation State

Straight-line debug attempts so far (3 — all "attempts" amount to re-reading the same line):
1. Read `config_loader.py` line 42 — see `config["emial"]`.
2. Searched the codebase for other `config["email"]` lookups — they all use the correct spelling.
3. Read the config schema definition — the field is named `email`.

These are not really independent attempts — each one re-confirms the same trivially-readable fact: line 42 has a one-character typo (`emial` instead of `email`). The cause is fully visible by reading the code; no runtime observation is needed to localize it.

## Bug-shape

The bug-shape does **NOT** require runtime evidence. The cause is statically derivable — a literal-string typo at a specific line that can be fixed by reading the code. No timing, no race, no intermittency, no DB query plan, no env-dependent state, no perf regression, no "wrong value at a line that I can't reason out from reading."

The bug is the cousin of the canonical examples in `## When NOT to use` of the empirical-telemetry skill: typo, off-by-one, missing import, wrong constant. Reading the code suffices to fix it.

## Next Step

This does NOT match the empirical-telemetry trigger profile. The static-derivable nature of the typo means Gate 2 fails. The fix is one character: `config["emial"]` → `config["email"]`. Apply the fix directly; do not instrument.
