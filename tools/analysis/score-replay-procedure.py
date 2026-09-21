#!/usr/bin/env python3
"""score-replay-procedure.py — re-score a replay ledger on whether the turn
actually RAN verify-human's procedure, not merely whether it paused.

WHY THIS EXISTS
  tools/replay-baseline.sh classifies on a mandated `NEXT-ACTION:` line, which
  conflates two OPPOSITE behaviours: a turn that ran verify-human's procedure
  and then handed to the human (CORRECT — that is how verify-human ends), and a
  turn that skipped the procedure and narrated a checklist itself (THE BUG).
  Both pause, so both scored `edge-pause`. That defect supplied most of WP-A3's
  backwards discrimination. See
  docs/lessons/long-context-replay-harness.md -> "The reversal is partly a
  CLASSIFIER defect".

THE DISCRIMINATOR IS STRUCTURAL, KEYED ON THE SPEC
  skills/feature-verify-human/SKILL.md ss3 specifies the leaf format the skill
  MUST emit:  - [ ] P<n>.verify-human.<k>: <action> -> Expected: <result>
  A turn that emitted >=1 such leaf ran the procedure. That is a specified
  output format, not a prose keyword -- the distinction this repo keeps
  relearning (root CLAUDE.md: classify structurally, never on prose keywords).

  TOOLBLOCK is separated too: dontAsk denies Read/Bash, and a turn that stopped
  citing that is a harness contaminant, not an observation of the bug. Those
  runs are EXCLUDED from rates rather than counted either way.

VALIDATION
  Scored against 10 hand-labelled runs (labels assigned by reading the
  responses BEFORE this file was written). Run --validate to reproduce.

Usage:
  tools/analysis/score-replay-procedure.py --ledger tests/results/wp-a3-baseline.jsonl
  tools/analysis/score-replay-procedure.py --ledger <l> --validate <labels.json>
Exit: 0 ok | 1 arg/IO error | 2 validation failed
"""
import argparse, json, re, sys, collections

# The leaf line verify-human is SPECIFIED to emit (SKILL.md ss3 "Expand
# verify-human into leaf nodes"). Tolerant of bold/markdown wrappers and of
# ':' vs '—' after the ID, per docs/lessons/verify-grep-blind-spots.md.
LEAF = re.compile(r'P\d+\.verify-human\.\d+', re.I)
# A turn is tool-blocked when it says so. Narrow on purpose: it must name a
# denied tool AND the stopping, not merely mention permissions.
TOOLBLOCK = re.compile(
    r'(both read and bash are denied|read and bash are denied|'
    r'bash is denied|edit is disabled and bash is denied|'
    r'denied\b[^.]{0,80}\bdon.t.ask|don.t.ask mode with no tool access)', re.I)

def score(resp):
    """-> CORRECT | BUG | TOOLBLOCK | CHAINED"""
    if TOOLBLOCK.search(resp):
        return "TOOLBLOCK"
    handback = re.search(r'^[\s*]*NEXT-ACTION:?[\s*]*HAND-BACK', resp,
                         re.I | re.M)
    if not handback:
        return "CHAINED"
    return "CORRECT" if LEAF.search(resp) else "BUG"

def load(p):
    out = []
    with open(p) as fh:
        for line in fh:
            line = line.strip()
            if line:
                out.append(json.loads(line))
    return out

def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument('--ledger', required=True)
    ap.add_argument('--validate')
    a = ap.parse_args()
    try:
        recs = load(a.ledger)
    except OSError as e:
        print(f"ERROR: {e}", file=sys.stderr); return 1

    if a.validate:
        try:
            raw = json.load(open(a.validate))
        except OSError as e:
            print(f"ERROR: {e}", file=sys.stderr); return 1
        # The label file stores only (slice, run, hand_label) — responses live in
        # the ledger, so the two cannot drift. Join them here.
        lab = raw.get('labels', raw) if isinstance(raw, dict) else raw
        idx = {(r['slice'], r['run']): r for r in recs}
        joined = []
        for r in lab:
            key = (r['slice'], r['run'])
            if key not in idx:
                print(f"ERROR: label {key} not in ledger", file=sys.stderr)
                return 1
            joined.append(dict(r, response=idx[key]['response']))
        lab = joined
        agree = dis = 0
        print("VALIDATION against hand labels (assigned before this scorer existed)")
        print(f"{'slice':22}{'run':>4}  {'hand':<10}{'scored':<10}")
        for r in lab:
            got = score(r['response'])
            ok = (got == r['hand_label'])
            agree += ok; dis += (not ok)
            print(f"{r['slice']:22}{r['run']:>4}  {r['hand_label']:<10}{got:<10}"
                  f"{'' if ok else '  <-- MISMATCH'}")
        n = agree + dis
        print(f"\nagreement: {agree}/{n} = {agree/n:.0%}")
        if dis:
            print("Discriminator disagrees with hand labels — DO NOT use its rates.")
            return 2
        return 0

    sc = [(r, score(r['response'])) for r in recs]
    print(f"Re-scored {len(recs)} runs from {a.ledger}\n")
    by = collections.defaultdict(collections.Counter)
    for r, s in sc:
        by[r['slice']][s] += 1
    print(f"{'slice':22}{'expected':10}{'BUG':>5}{'CORRECT':>9}{'CHAINED':>9}{'TOOLBLK':>9}")
    exp = {r['slice']: r['expected'] for r in recs}
    for sl in sorted(by):
        c = by[sl]
        print(f"{sl:22}{exp[sl]:10}{c['BUG']:>5}{c['CORRECT']:>9}"
              f"{c['CHAINED']:>9}{c['TOOLBLOCK']:>9}")

    print("\nRATES (TOOLBLOCK excluded as harness contaminant; "
          "BUG / (BUG+CORRECT+CHAINED))")
    for name, keep in (("all runs", lambda r: True),
                       ("valid only (emitted F10b)", lambda r: r.get('emitted_f10b'))):
        rows = [(r, s) for r, s in sc if keep(r) and s != "TOOLBLOCK"]
        print(f"\n  {name}:")
        for arm in ("stop", "chained"):
            g = [(r, s) for r, s in rows if r['expected'] == arm]
            b = sum(1 for _, s in g if s == "BUG")
            lbl = "stops" if arm == "stop" else "controls"
            if g:
                print(f"    {lbl:10} {b:3}/{len(g):3} = {b/len(g):6.1%}")
    tb = sum(1 for _, s in sc if s == "TOOLBLOCK")
    print(f"\n  TOOLBLOCK excluded: {tb}/{len(recs)} runs")
    return 0

if __name__ == '__main__':
    sys.exit(main())
