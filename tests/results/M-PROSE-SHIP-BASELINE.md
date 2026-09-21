# m-prose ship — production before/after

**Shipped 2026-09-21.** The mitigation is a prose edit to
`skills/feature-verify-self/SKILL.md`; this file is the **pre-ship baseline** it
will be measured against, recorded at ship time so the comparison is anchored to
a number that existed *before* the change.

## Pre-ship baseline (autopilot/FSD-gated, structural classifier)

Reproduce exactly: `/usr/bin/python3 tools/analysis/measure-f10b-handback-rate.py`

| model | F10b turns | handed back | rate |
|---|---|---|---|
| opus-4-7 | 198 | 30 | 15.2% |
| opus-4-8 | 452 | 9 | 2.0% |
| **opus-5** | **278** | **21** | **7.6%** |

**Total 928 turns.** opus-5 vs opus-4-8: Fisher p = 3.8×10⁻⁴, risk ratio ≈ 3.8×.
**opus-5's 7.6% is the number to beat.**

## What shipped

The F10b cheat-sheet row in `skills/feature-verify-self/SKILL.md` changed from
`AUTO (chain into verify-human, which itself PAUSEs)` — the parenthetical failing
production runs literally cite as their reason to stop — to an imperative to
invoke the skill, plus a paragraph locating the pause in the **state** rather than
the **edge into** it. Pinned by `tests/check-structure.sh` `[Phase 22]`.

## Replay evidence (why this arm, and its limits)

Paired within-slice A/B, 224/600 runs, balanced 15/40 per cell:

| slice | control | m-prose |
|---|---|---|
| stop-claudesk-a | 13.3% | **0.0%** |
| stop-claudesk-b | 6.7% | **0.0%** |
| stop-hermes-a | 6.7% | **0.0%** |
| pooled | 8.9% | **0.0%** (0 BUG in 45 runs) |

`m-actdontask` was flat (−2.2%). **The pre-registered bar returned NOT A WIN** —
it required a ≥10-point pooled drop, and the control arm ran at 8.9%, so even a
perfect mitigation could not clear it. **That is a calibration failure of the bar,
not evidence against m-prose**, and the replay result is therefore *supporting*
evidence only. The decision to ship rests on production measurement, below.

## How to measure the after

**Wait for ≥100 opus-5 F10b turns in autopilot/FSD** accumulated *after*
2026-09-21, then:

```bash
/usr/bin/python3 tools/analysis/measure-f10b-handback-rate.py
```

Read **opus-5's rate** and compare against **7.6% (21/278)**.

- The classifier is **structural** (was a `verify-human` tool_use emitted?) and
  **drive-mode-gated** — both load-bearing. Do not substitute a keyword count.
- Report a **ratio**, never a verdict. Per
  `docs/lessons/green-tests-that-guard-nothing.md` (eighth mechanism), n≥6 is the
  floor for any claim and these are stochastic rates.
- **Mind the confound:** the script reads *all* logs, so post-ship turns are
  mixed with the 278 pre-ship ones. A future measurement should filter by
  timestamp to isolate the after-period, or the effect will be diluted.
  That filter is **not yet implemented** — it is the first thing to add.

## Decision rule (stated now, before the data exists)

- opus-5 drops to **≤3%** over ≥100 post-ship turns → the mitigation works;
  record it and close Track B.
- opus-5 stays **≥6%** → it did not work; route to WP-B3 (the unfiled upstream
  draft at `docs/upstream/opus5-f10b-edge-pause-issue.md`).
- Anything between → inconclusive; keep accumulating rather than deciding.

Setting this bar *before* seeing post-ship data is deliberate — the replay A/B's
bar was set against an unvalidated base rate and became unclearable, which is the
mistake this rule exists to avoid repeating.
