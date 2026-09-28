---
workflow: task
state: close (complete)
completed: 2026-09-28
created: 2026-09-28
docs-only: false
drive_mode: autopilot
---

# Task: Split Opus 5.5 out of the opus-5 bucket in the F10b measurement

**Workflow:** task
**State:** Completed 2026-09-28
**Created:** 2026-09-28

## Problem Statement
`measure-f10b-handback-rate.py` buckets models with `"opus-5" in m`, so `claude-opus-5-5` (first seen 2026-09-22T18:09Z, ~21h after m-prose shipped) is silently merged into `opus-5` — 35 of the 51 "post-ship opus-5" turns are actually Opus 5.5, which confounds the fix with a model change and makes the pre-registered "≥100 opus-5 turns" rule unreachable.

## Context
- `tools/analysis/measure-f10b-handback-rate.py` — `norm()` (substring bucketing) and the hardcoded report tuple `("opus-4-7","opus-4-8","opus-5")`; any unrecognised model returns `None` and is dropped silently.
- `tests/results/M-PROSE-SHIP-BASELINE.md` — pre-registered baseline (opus-5 7.6%, 21/278) + decision rule. Rule must stay intact; add a dated addendum only.
- No `check-structure.sh` pin or test references either file (grepped `tests/*.sh`, `tools`, `skills`, `agents`, `docs`).
- Measured split (scratchpad variant, 2026-09-28): post-ship opus-5 16/0, opus-5-5 35/0; pre-ship unchanged (opus-5 278/21, opus-5-5 0).
- CLAUDE.md convention "A measured rate over agent behavior needs a validity gate on BOTH sides" — this is the wrong-denominator failure class.

## Work Tree

- [x] T1 Replace substring `norm()` with an ID parser that yields one bucket per Opus family+minor (`opus-5`, `opus-5-5`, …, tolerating an optional date suffix), and report every bucket seen rather than a hardcoded tuple — so the next minor release cannot be silently merged either. Document the confound in the docstring.
- [x] T2 Verify invariant: unfiltered output for existing rows is identical to the recorded baseline (opus-4-7 198/30, opus-4-8 452/9, opus-5 278/21, total 928); post-ship window splits 16/0 + 35/0.
- [x] T3 Append a dated `## Addendum 2026-09-28` to `M-PROSE-SHIP-BASELINE.md`: model-switch timeline, the split table, why attribution is not separable, and the reframed with-fix model-agnostic question — original decision rule untouched.

## Verification Observable

**Observable:** The real measurement script reports Opus 5.5 as its own row post-ship (opus-5 16/0, opus-5-5 35/0) while the pre-ship window still reproduces the recorded baseline exactly (198/30, 452/9, 278/21, total 928, no opus-5-5 row).
**Verification command:** `/usr/bin/python3 tools/analysis/measure-f10b-handback-rate.py --since 2026-09-21T21:33Z` and `... --until 2026-09-21T21:32Z`, each row asserted by anchored `grep -E`
**Expected result:** all anchored greps match, `TOTAL turns: 928` present pre-ship, no `opus-5-5` row pre-ship; prints `VERIFY-PASS`, exit 0

## Verification Result

**Status:** PASS
**Date:** 2026-09-28
**Evidence:** `COMPILE-OK`; post-ship `opus-5                16         0    0.0%` / `opus-5-5              35         0    0.0%`; pre-ship `opus-4-7             198        30   15.2%` / `opus-4-8             452         9    2.0%` / `opus-5               278        21    7.6%`; `VERIFY-PASS`, `exit=0`
**Notes:** Split is in effect on the real tool and the pre-registered baseline table is unchanged.

## Current Node
- **Path:** Task > close (complete)
- **Active scope:** none — archived
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
- 2026-09-28 T2 — verified: `--until 2026-09-21T21:32Z` output byte-identical before/after (198/30, 452/9, 278/21, 928); post-ship splits opus-5 16/0 + opus-5-5 35/0; parser spot-checked on dotted IDs, date suffixes, non-Opus, and an unseen `opus-6`.
- 2026-09-28 T3 — addendum re-points the ≥6% branch away from WP-B3 (dropped by operator 2026-09-22); original rule text untouched.

## Retrospect
- **What changed in our understanding:** the "51 post-ship opus-5 turns, 0 stopped" reading was two models — Opus 5.5 arrived ~21h after the fix, so 35/51 turns cannot attribute the drop to m-prose; the clean fix-only evidence is opus-5 0/16 (~28% by chance at baseline).
- **Assumptions that held:** Opus 5.5 was absent pre-ship, so the recorded baseline reproduces byte-identically after the split.
- **Assumptions that were wrong:** the prior session's handoff (and my own first restore readout) treated `opus-5` as one model; the operator's prompt to "check the timeline" is what exposed it.
- **Approach delta:** generalized beyond the planned opus-5-5 special case to parsing family+minor from the ID and printing every bucket seen, so the next release cannot merge silently either. The addendum also had to re-point the ≥6% branch, since its WP-B3 route was dropped on 2026-09-22.

**Closure notice:** Requester = operator — closure notice for self-record. The F10b measurement now reports Opus 5.5 as its own row, and `tests/results/M-PROSE-SHIP-BASELINE.md` carries a dated addendum restating the question as "with the fix in place, does the hand-back still happen?" (pooled, cause unattributed). Check with `/usr/bin/python3 tools/analysis/measure-f10b-handback-rate.py --since 2026-09-21T21:33Z`.
