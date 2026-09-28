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
/usr/bin/python3 tools/analysis/measure-f10b-handback-rate.py --since 2026-09-21T21:33Z
```

Read **opus-5's rate** and compare against **7.6% (21/278)**.

**Use the INSTANT, not the date.** m-prose shipped at `2026-09-21T21:33Z`
(commit `07ff3ba`). A bare `--since 2026-09-21` admits the whole ship day and
returned **16 "post-ship" opus-5 turns recorded 12:43–15:29Z — hours BEFORE the
edit existed**, at an apparent 28.6%. That is this session's own pre-ship work,
not evidence about the mitigation. The filter was verified to partition exactly:
pre-ship 914 + post-ship 14 = 928 unfiltered, and opus-5 264 + 14 = 278.

As of the ship commit the correct window returns **0 turns** — the honest
starting state. Nothing can be concluded until turns accumulate.

- The classifier is **structural** (was a `verify-human` tool_use emitted?) and
  **drive-mode-gated** — both load-bearing. Do not substitute a keyword count.
- Report a **ratio**, never a verdict. Per
  `docs/lessons/green-tests-that-guard-nothing.md` (eighth mechanism), n≥6 is the
  floor for any claim and these are stochastic rates.
- **The dilution confound is now FIXED.** `--since` / `--until` filter on each
  assistant record's ISO-8601 `timestamp` (audited at 100% coverage: 0 missing,
  0 malformed across 267,096 assistant records, so a bound never silently drops
  data). A record with an absent or unparseable timestamp is excluded *and
  counted*, with the count printed. Unfiltered output is unchanged from the
  recorded baseline — verified byte-identical.

## Decision rule (stated now, before the data exists)

- opus-5 drops to **≤3%** over ≥100 post-ship turns → the mitigation works;
  record it and close Track B.
- opus-5 stays **≥6%** → it did not work; route to WP-B3 (the unfiled upstream
  draft at `docs/upstream/opus5-f10b-edge-pause-issue.md`).
- Anything between → inconclusive; keep accumulating rather than deciding.

Setting this bar *before* seeing post-ship data is deliberate — the replay A/B's
bar was set against an unvalidated base rate and became unclearable, which is the
mistake this rule exists to avoid repeating.

## Addendum 2026-09-28 — Opus 5.5 entered the window; the question is restated

**Nothing above is edited.** The baseline and the decision rule stand as
pre-registered. This section records a confound found after the fact and the
question the operator chose to answer instead.

**What happened.** `claude-opus-5-5` first appears in the logs at
**2026-09-22T18:09Z**, about 21h after m-prose shipped (`2026-09-21T21:33Z`); the
last `claude-opus-5` turn is 19:57Z the same day. The measurement script bucketed
models by substring (`"opus-5" in m`), so Opus 5.5 was **silently counted as
opus-5**. The "51 post-ship opus-5 turns, 0 stopped" reading of 2026-09-28 was
really two models. The script now parses one bucket per family+minor, so the next
release gets its own row too. The pre-ship table is unaffected (0 Opus 5.5 turns
before ship; output verified identical).

| window | model | fix | F10b turns | stopped |
|---|---|---|---|---|
| pre-ship | opus-5 | no | 278 | 21 (7.6%) |
| post-ship, 09-21 22:25Z → 09-22 18:42Z | opus-5 | yes | 16 | 0 |
| post-ship, 09-23 → 09-27 | opus-5-5 | yes | 35 | 0 |

**What it does and does not show.**

- The only fix-only evidence is **opus-5 0/16**. At the 7.6% baseline, 0/16
  happens by chance ~28% of the time — consistent with the fix working,
  not evidence of it.
- **opus-5-5 has no no-fix arm.** Every 5.5 turn ran on patched prose, so the fix
  and the model change are **not separable** from production data. Separating them
  would need replaying 5.5 on the old prose — the audited-slice cost already judged
  not worth it for one prose edit.
- Pooled with-fix: **0/51**, ~2% by chance at 7.6%. The improvement the operator
  noticed is real in the data; its **cause is unattributed**.
- The original rule's "≥100 opus-5 turns" is **unreachable** — the operator no
  longer runs Opus 5.

**Restated question (operator decision, 2026-09-28):** *with the fix in place,
does the hand-back still happen in practice?* — model-agnostic, not "did m-prose
cause the drop." The fix stays shipped either way.

- Count **with-fix Opus-family turns pooled** (currently opus-5 + opus-5-5) since
  `2026-09-21T21:33Z`, reading the per-model rows alongside so a model-specific
  regression is still visible.
- **Same thresholds:** ≤3% over ≥100 turns → close Track B; ≥6% → inconclusive
  about the fix but a live problem, re-open; between → keep accumulating. (WP-B3,
  the upstream filing, was dropped by the operator on 2026-09-22 and is not the
  ≥6% route any more.)
- **A close under this reading must say so:** "the hand-back is gone in practice;
  whether m-prose or Opus 5.5 removed it is not determined."
- If a future model lands mid-window, record its first-seen instant here before
  reading any pooled number.
