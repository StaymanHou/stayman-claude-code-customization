---
name: Replay-harness runs are not independent draws (shared prompt cache)
description: tools/replay-baseline.sh replays a byte-identical ~300k-char prefix per slice inside one short window, so runs share prompt-cache state; log timestamps and interleave arms before trusting any rate
type: project
---

`tools/replay-baseline.sh` passes a **byte-identical ~300k-char rendered transcript** via
`--append-system-prompt` for every run of a slice, and the WP-A3 `n=100` executed inside a single
**31-minute window** — well inside prompt-cache TTL. So runs within a slice are **not independent
draws**, unlike the real production turns they stand in for. This is a property of the harness by
construction; it was never considered during the cycle that built it (operator raised it 2026-09-22).

**What the evidence says — check it before repeating either claim:**

- **Caching does NOT explain the within-A3 rates.** Split `tests/results/wp-a3-baseline.jsonl`
  first-half vs second-half per slice: `chained-claudesk-c` 5/10 vs 5/10, `chained-hermes-b` 8/10 vs
  5/10, `stop-claudesk-a` 6/10 vs 4/10, `stop-claudesk-b` 1/10 vs 1/10, `stop-hermes-a` 1/10 vs 1/10.
  **No monotone drift as the cache warms.**
- **It remains an unexcluded confound for the CROSS-session baseline shift** — `stop-claudesk-a` went
  40% (8/20) → 13.3% (2/15) on identical inputs, Fisher p = 0.134. Different invocations, different
  cache states. It sits *alongside* noise as a second unexcluded hypothesis, not as a replacement.

**Coupled instrumentation defect:** `tests/results/paired-ab.jsonl` records **no timestamps at all**
(`arm, expected, model, response, run, seconds, slice`) — while `wp-a3-baseline.jsonl` *does* carry
`started`. So the cross-session cache hypothesis **cannot be tested against the recorded evidence**
for the paired A/B. That absence is the finding.

**How to apply — the two mitigations differ sharply in cost, and the cheap one is better:**

1. **Log `started` and interleave arms** (don't run arm-blocks back to back). Near-zero cost, and it
   removes the confound from the *design* rather than measuring it. Do this before any future run.
2. **Prefix-nonce cache-busting** (prepend a per-run UUID to force a miss) forces a full ~300k-token
   prefill every run and would **invalidate the ~$0.35/run cost basis the power calculation depends
   on**. Do not reach for it casually; if it's ever wanted, measure it as one slice n=20 busted vs
   n=20 as-is (~$15–30) rather than flipping the default.

Instance of the standing rule in root `CLAUDE.md` → `## Conventions`: a measured rate over agent
behavior needs a validity gate on both sides. Non-independent draws are a denominator problem — the
effective n is smaller than the run count, on top of the already-measured slice clustering
(ICC ≈ 0.12, design effect 3.30).

Related: [[feedback_replay_harness_research_conditions]] (which *model* and *cwd* to replay with — a
different axis from run independence), [[project_pain_points]].
