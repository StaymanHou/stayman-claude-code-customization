#!/usr/bin/env python3
"""report-paired-ab.py — paired within-slice analysis of the F10b mitigation A/B.

Enforces the PRE-REGISTERED bar from tools/replay-paired.sh. A mitigation
"wins" only if ALL THREE hold:
  (a) reduces the BUG rate in >= k-1 of the k STOP slices (k=3 -> >=2)
  (b) increases it in ZERO slices
  (c) pooled BUG rate drops by >= 10 absolute points
  (d) no negative-control slice degrades

Only the STOP slices are bug-arm data. The 2 chained slices are negative
controls with a different base rate and are never pooled into (a)-(c).

MEASURED ERROR RATES (tools/analysis/simulate-paired-bar.py, 4000 trials/cell,
control rate 20%, k=3): at n=20/slice this bar fires 7.9% of the time on a
mitigation with NO real effect -- which is how the missing noise floor was
caught (a synthetic null ledger printed "WIN"). At n=40 the false-positive
rate is 2.6% with 88% power against a large effect (20%->5%). Power against a
merely-halving effect is ~50% at EVERY n, because (c) demands a 10-point
pooled drop: this design sees only a LARGE effect, by design.

A two-sided exact sign test over k=3 cannot reach 0.05 (best case 3/3 gives
p = 0.25), so the sign test is reported for DIRECTION ONLY and the bar above is
the decision rule. Scoring is delegated to score-replay-procedure.py -- the
validated classifier -- never reimplemented here.

Exit: 0 report printed | 1 IO/arg error | 3 ledger has no control arm
"""
import argparse, collections, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
# score-replay-procedure.py is not importable (its name has hyphens), so it is
# exec'd into a namespace and its validated score() is reused verbatim. Do NOT
# reimplement scoring here — one classifier, validated once.
_ns = {}
_p = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                  'score-replay-procedure.py')
with open(_p) as fh:
    exec(compile(fh.read(), _p, 'exec'), _ns)
SCORE = _ns['score']

def sign_test_two_sided(pos, neg):
    """Exact two-sided sign test over pos/neg (ties dropped)."""
    from math import comb
    n = pos + neg
    if n == 0:
        return 1.0
    k = min(pos, neg)
    tail = sum(comb(n, i) for i in range(0, k + 1)) / 2 ** n
    return min(1.0, 2 * tail)

def wilson(k, n, z=1.96):
    if n == 0:
        return (0.0, 0.0)
    p = k / n
    d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d
    h = z * ((p * (1 - p) / n + z * z / (4 * n * n)) ** 0.5) / d
    return (max(0.0, c - h), min(1.0, c + h))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--ledger', required=True)
    a = ap.parse_args()
    try:
        recs = [json.loads(l) for l in open(a.ledger) if l.strip()]
    except OSError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    if not recs:
        print("Ledger is empty — nothing to report.")
        return 0

    # tally[(slice, arm)] = Counter of scored outcomes
    tally = collections.defaultdict(collections.Counter)
    exp = {}
    for r in recs:
        tally[(r['slice'], r['arm'])][SCORE(r['response'])] += 1
        exp[r['slice']] = r['expected']
    arms = sorted({r['arm'] for r in recs},
                  key=lambda x: (x != 'control', x))
    if 'control' not in arms:
        print("ERROR: ledger has no 'control' arm — a paired design needs it.",
              file=sys.stderr)
        return 3
    slices = sorted(exp, key=lambda s: (exp[s] != 'stop', s))

    def rate(sl, arm):
        c = tally[(sl, arm)]
        eff = c['BUG'] + c['CORRECT'] + c['CHAINED']   # TOOLBLOCK excluded
        return (c['BUG'], eff)

    print("PAIRED WITHIN-SLICE A/B — F10b edge-pause mitigation")
    print("TOOLBLOCK runs excluded (harness contaminant, not an observation).\n")
    for arm in arms:
        print(f"  arm: {arm}")
        print(f"    {'slice':22}{'exp':9}{'BUG':>5}{'n':>5}{'rate':>8}")
        for sl in slices:
            b, n = rate(sl, arm)
            r = f"{b/n:.1%}" if n else "n/a"
            print(f"    {sl:22}{exp[sl]:9}{b:>5}{n:>5}{r:>8}")
        print()

    print("PAIRED DIFFERENCES vs control (stop slices only — the bug arm)")
    stops = [s for s in slices if exp[s] == 'stop']
    for arm in [x for x in arms if x != 'control']:
        print(f"\n  {arm} vs control:")
        print(f"    {'slice':22}{'ctrl':>8}{'mitig':>8}{'delta':>9}")
        better = worse = tie = 0
        cb = cn = mb = mn = 0
        for sl in stops:
            b0, n0 = rate(sl, 'control')
            b1, n1 = rate(sl, arm)
            if not n0 or not n1:
                print(f"    {sl:22}{'—':>8}{'—':>8}{'skip':>9}")
                continue
            r0, r1 = b0 / n0, b1 / n1
            d = r1 - r0
            cb += b0; cn += n0; mb += b1; mn += n1
            if d < 0: better += 1
            elif d > 0: worse += 1
            else: tie += 1
            print(f"    {sl:22}{r0:>7.1%}{r1:>8.1%}{d:>+8.1%}")
        pooled_d = (mb / mn - cb / cn) if (mn and cn) else 0.0
        print(f"    {'POOLED':22}{cb/cn if cn else 0:>7.1%}"
              f"{mb/mn if mn else 0:>8.1%}{pooled_d:>+8.1%}")
        lo0, hi0 = wilson(cb, cn); lo1, hi1 = wilson(mb, mn)
        print(f"      control  95% CI {lo0:.1%}–{hi0:.1%}   (n={cn})")
        print(f"      {arm:8} 95% CI {lo1:.1%}–{hi1:.1%}   (n={mn})")
        p = sign_test_two_sided(better, worse)
        print(f"      per-slice direction: {better} better, {worse} worse, {tie} tied")
        print(f"      exact two-sided sign test p = {p:.4f}"
              f"   (k={better+worse}; DESIGN CANNOT REACH 0.05 — see header)")
        # PRE-REGISTERED GATE
        k = len(stops)
        a_ok = better >= max(1, k - 1)
        b_ok = worse == 0
        c_ok = pooled_d <= -0.10
        print(f"      pre-registered bar:")
        print(f"        (a) reduces in >= {max(1,k-1)}/{k} slices ....... "
              f"{'PASS' if a_ok else 'FAIL'} ({better}/{k})")
        print(f"        (b) increases in ZERO slices ......... "
              f"{'PASS' if b_ok else 'FAIL'} ({worse})")
        print(f"        (c) pooled drop >= 10 points ......... "
              f"{'PASS' if c_ok else 'FAIL'} ({pooled_d:+.1%})")
        # (d) negative controls must not degrade — part of the BAR, not an aside.
        ctrls = [s for s in slices if exp[s] == 'chained']
        # A negative control is "degraded" only on a MATERIAL rise, not on any
        # upward wobble: these slices sit near 0-11%, so at n=20 a single extra
        # BUG run is +5 points of pure noise. Requiring an exact non-increase
        # made a synthetic arm with IDENTICAL true control rates fail (d).
        # Threshold: +10 points, matching criterion (c)'s materiality.
        DEG_TOL = 0.10
        deg = []
        for sl in ctrls:
            b0, n0 = rate(sl, 'control'); b1, n1 = rate(sl, arm)
            if n0 and n1 and (b1 / n1) - (b0 / n0) > DEG_TOL:
                deg.append(f"{sl} ({b0/n0:.0%}->{b1/n1:.0%})")
        d_ok = not deg
        print(f"        (d) no neg-control +>10pts ......... "
              f"{'PASS' if d_ok else 'FAIL'}"
              f"{'' if d_ok else ' — ' + ','.join(deg)}")
        win = a_ok and b_ok and c_ok and d_ok
        print(f"      VERDICT: {'WIN' if win else 'NOT A WIN'}")
        if win and min(cn, mn) < 3 * 40:
            print(f"      ⚠️  n is below the pre-registered 40/slice operating "
                  f"point (control n={cn}, mitigation n={mn}). At n=20/slice "
                  f"this bar has a 7.9% FALSE-POSITIVE rate — treat a WIN here "
                  f"as provisional and finish the run.")
    return 0

if __name__ == '__main__':
    sys.exit(main())
