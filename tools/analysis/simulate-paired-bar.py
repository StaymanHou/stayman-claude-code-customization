#!/usr/bin/env python3
"""simulate-paired-bar.py — measure the error rates of the paired A/B's
pre-registered decision bar, so the choice of n is evidence rather than taste.

WHY THIS EXISTS: the bar in tools/replay-paired.sh was first written with no
noise floor. A synthetic ledger where BOTH arms had the same true rate (0.30)
made the reporter print "VERDICT: WIN" with a 26.7-point apparent drop, because
at n=20/slice chance alone clears a 10-point pooled threshold often. A
pre-registered bar with an unmeasured false-positive rate is not a safeguard.

Simulates the bar directly (same three criteria as report-paired-ab.py):
  (a) reduces BUG rate in >= k-1 of k slices
  (b) increases it in ZERO slices
  (c) pooled drop >= 10 absolute points

Usage:
  tools/analysis/simulate-paired-bar.py
  tools/analysis/simulate-paired-bar.py --control-rate 0.20 --k 3 --trials 4000
Exit: 0 always (report only)
"""
import argparse, random

def fires(p0, p1, n, k, seed):
    r = random.Random(seed)
    better = worse = 0
    cb = cn = mb = mn = 0
    for _ in range(k):
        b0 = sum(1 for _ in range(n) if r.random() < p0)
        b1 = sum(1 for _ in range(n) if r.random() < p1)
        cb += b0; cn += n; mb += b1; mn += n
        if b1 < b0: better += 1
        elif b1 > b0: worse += 1
    if not (better >= max(1, k - 1) and worse == 0):
        return False
    return (mb / mn - cb / cn) <= -0.10

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--control-rate', type=float, default=0.20,
                    help="true BUG rate of the control arm (default: the "
                         "observed stop-arm rate, 0.20)")
    ap.add_argument('--k', type=int, default=3, help="stop slices (default 3)")
    ap.add_argument('--trials', type=int, default=4000)
    a = ap.parse_args()
    p0 = a.control_rate
    print(f"Pre-registered bar error rates — control rate {p0:.0%}, "
          f"k={a.k} slices, {a.trials} trials/cell\n")
    print(f"{'n/slice':>8}{'power 20->5%':>14}{'power 20->10%':>15}"
          f"{'FALSE-POSITIVE':>16}")
    for n in (20, 40, 60, 80, 120):
        pw5 = sum(fires(p0, 0.05, n, a.k, s) for s in range(a.trials)) / a.trials
        pw10 = sum(fires(p0, 0.10, n, a.k, s) for s in range(a.trials)) / a.trials
        fp = sum(fires(p0, p0, n, a.k, s) for s in range(a.trials)) / a.trials
        flag = "  <- UNACCEPTABLE" if fp > 0.05 else ""
        print(f"{n:>8}{pw5:>13.0%}{pw10:>15.0%}{fp:>15.1%}{flag}")
    print("\nThe middle column is FLAT in n: a fix that merely halves the rate")
    print("stays near 50% power at every n, because criterion (c) requires a")
    print("10-point pooled drop. A k=3 paired design sees only a LARGE effect.")
    print("That is a pre-registered limitation — a null here does NOT mean the")
    print("mitigation is worthless, only that it is not large.")
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
