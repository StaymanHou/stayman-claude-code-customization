# Paired A/B run — operator runbook

Written 2026-09-21 **while the run was in flight**, so that finishing and reading it
does not depend on the session that started it still being alive. If that session hit
its context limit, everything you need is here.

## The run is detached and survives everything

Started as a `nohup` background process writing `tests/results/paired-ab.jsonl`.
It is **not** a child of the Claude Code session. It survives the session ending,
the terminal closing, and `/clear`. It does **not** survive a machine shutdown —
that is fine, it is resumable.

Ledger writes are `fsync`'d per record, so a hard kill loses at most the single
in-flight run. Projected final size ~1.5 MB for 600 records.

## Commands

```bash
cd /Users/stayman/Personal/projects/my-claude-code-customization

# progress, no runs
./tools/replay-paired.sh --ledger tests/results/paired-ab.jsonl --n 40 --status

# RESUME after a reboot — identical to the start command. It counts what is
# recorded per (slice, arm) and runs only the shortfall.
./tools/replay-paired.sh --n 40 --ledger tests/results/paired-ab.jsonl

# the analysis, at whatever depth exists
./tools/replay-paired.sh --ledger tests/results/paired-ab.jsonl --report
```

Optional `--deadline HH:MM` stops cleanly before a wall-clock time.
`MAX_FAILS=N` (default 12) caps consecutive empty results, then exits 4.

Exit codes: `0` done or clean stop · `1` arg/prerequisite · `2` missing slice ·
`4` aborted on repeated empty results (ledger intact, just re-run).

## Reading the result — THE PART THAT MATTERS

`--report` prints four criteria and a VERDICT. **The verdict is mechanical and
pre-registered; do not reinterpret it.** A mitigation wins only if ALL hold:

| | criterion |
|---|---|
| (a) | reduces the BUG rate in ≥2 of the 3 **stop** slices |
| (b) | increases it in **zero** slices |
| (c) | pooled BUG rate drops by **≥10 absolute points** |
| (d) | no negative-control slice rises by >10 points |

Three caveats, all pre-registered — none of them are excuses invented afterwards:

1. **This design detects only a LARGE effect** (20%→5%). Power against a fix that
   merely *halves* the rate is ~50% **at every n** — criterion (c) demands a
   10-point pooled drop. **A null means "not large", NOT "worthless."**
2. **At partial n a WIN is provisional.** The bar's own false-positive rate is
   **7.9% at n=20/slice** vs **2.6% at n=40**. The report prints a ⚠️ warning
   automatically when n is below the 40/slice operating point. Reproduce these
   rates with `tools/analysis/simulate-paired-bar.py`.
3. **The two `chained-*` slices are negative controls, not bug data.** They have a
   different base rate and are never pooled into (a)–(c). A mitigation that
   "fixes" everything by flattening the controls into silence fails (d).

Scoring is delegated to `tools/analysis/score-replay-procedure.py`, validated
**10/10** against `tests/results/wp-a3-handlabels.json` (hand-labelled before the
scorer was written). **Do not add a second classifier.** To re-check it:

```bash
/usr/bin/python3 tools/analysis/score-replay-procedure.py \
  --ledger tests/results/wp-a3-baseline.jsonl \
  --validate tests/results/wp-a3-handlabels.json
```

## The arms

- `control` — no added instruction; the baseline.
- `m-prose` — disambiguates the cheat-sheet parenthetical the failing production runs
  literally cite (*"AUTO (chain into verify-human, which itself PAUSEs)"*) by locating
  the pause in the **state**, reachable only by entering it.
- `m-actdontask` — the operator's timing-rule lean ("Act. Don't Ask"), deliberately
  silent about F10b specifically.

The rendered transcript is **byte-identical across arms**; the mitigation is injected
as *current-instruction* context. Arms are interleaved within each slice so model
drift is shared rather than loaded onto whichever arm ran last.

## What to do with the outcome

- **A WIN at full n** → ship that arm's prose as a real SKILL.md edit (WP-B2), with
  the measured before/after in the commit message. Re-verify in production afterwards
  via `tools/analysis/measure-f10b-handback-rate.py`.
- **A null** → legitimate outcome, routes to WP-B3 (the upstream issue draft at
  `docs/upstream/opus5-f10b-edge-pause-issue.md`, unfiled and the operator's call).
  **Do not** ship an unmeasured mitigation; that is how three prior attempts died.
- **Anything ambiguous** → it is a null. See caveat 1.

Context and provenance: `docs/lessons/long-context-replay-harness.md`,
`workflow-system/product/opus5-edge-pause-wbs.md` (banner carries corrected status).
