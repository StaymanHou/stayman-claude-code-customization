---
workflow: task
state: close
created: 2026-06-09
completed: 2026-06-09
drive_mode: autopilot
---

# Task: settings-fixture-model-drift

**Workflow:** task
**State:** Completed (2026-06-09)
**Created:** 2026-06-09

## Problem Statement

`tests/check-structure.sh` Phase 7 reports persistent drift `model: live=<missing> fixture="opus[1m]"` because `tests/fixtures/settings.json:109` pins a top-level `"model"` field that no longer exists in live `~/.claude/settings.json`; remove the fixture's `model` field so the fixture tracks live and the structural check returns to a clean PASS.

## Context

- **Backlog source:** `SURFACE-2026-06-06-SETTINGS-FIXTURE-MODEL-DRIFT` (workflow/backlog.md:32 — now P1 after 2026-06-09 cleanup).
- **Drift detector:** `tests/check-structure.sh` lines 855-955 (Phase 7) — Python inline that walks live vs fixture, skipping paths in `INTENTIONAL_DIFFS`.
- **Live state:** `~/.claude/settings.json` has no top-level `model` key (confirmed by read 2026-06-09).
- **Fixture state:** `tests/fixtures/settings.json:109` has `"model": "opus[1m]"`.
- **Only drift outstanding:** Confirmed empirically by re-running the inline detector against live + fixture. After removing the fixture's `model` line, the detector returns `OK (no drift outside intentional diffs)`.
- **Decision: option (a) over option (b).** Backlog suggested (a) is correct — no reason to pin a specific harness model fingerprint in the fixture; the fixture should track live unless an intentional-diff reason exists, and none does here.

## Work Tree

- [x] T1 Remove `"model": "opus[1m]"` line + preceding comma from `tests/fixtures/settings.json` (line 109)
- [x] T2 Verify `./tests/check-structure.sh` Phase 7 returns PASS for the settings-fixture check (124/125 → 125/125)
- [x] T3 Commit + close (CHANGELOG.md append, `git mv` to archive, single commit per project convention)

## Current Node

- **Path:** Task > complete
- **Active scope:** all complete
- **Blocked:** none
- **Open discoveries:** none

## Act Log (2026-06-09)

- **T1 done:** Removed `"model": "opus[1m]"` (line 109) and the trailing comma on the prior line via `Edit` in `tests/fixtures/settings.json`. JSON validates (`python3 -m json.tool`).
- **T2 done:** Inline drift-detector returned `OK` (no drift outside intentional diffs). Full `./tests/check-structure.sh` run: **139/139 PASS, FAIL: 0** in 17s. Specific pin confirmed: `[PASS] settings fixture in sync with live (modulo documented diffs)`.
- **Runtime registry:** Updated `runtimes.md` with a new 17s history entry for `./tests/check-structure.sh` (Use timeout unchanged at 84000ms).

## Discoveries

<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect

- **What changed in our understanding:** Nothing new — the backlog entry already had the diagnosis (single `model` key drift) and the recommended action (option a). Confirming empirically before editing took ~5 seconds (one inline Python re-run of the drift walker against live + fixture).
- **Assumptions that held:** Option (a) was correct — dropping the `model` field rather than adding it to `INTENTIONAL_DIFFS`. Fixture should track live unless an intentional reason exists; here there was none. Drift detector logic is symmetric (it walks both sides), so removing the key from one side closes the gap as cleanly as adding it to the diff set would.
- **Assumptions that were wrong:** None. Plan said 3 leaves (T1 edit, T2 verify, T3 commit/archive) and that's exactly what happened.
- **Approach delta:** No deviation from plan. The Edit removed the `model` line + the trailing comma on the prior line as planned. Verification was run twice (inline drift walker first, then the full `./tests/check-structure.sh` script second) — the inline walker was a low-cost pre-check before invoking the full script, not in the plan as separate steps but trivially absorbed into T2.
