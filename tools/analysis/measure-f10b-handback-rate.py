#!/usr/bin/env python3
"""Measure the per-model rate of handing back at the verify-self -> verify-human
transition, across real session logs. Derivation behind
docs/upstream/opus5-f10b-edge-pause-issue.md.

TWO GATES ARE LOAD-BEARING; removing either inflates the rate ~2x:

  1. DRIVE-MODE GATE. The bug only exists in autopilot/FSD. In stepping and
     orchestrated modes, ending the turn with "Run /feature-verify-human" is
     CORRECT single-step behaviour, not the bug. An ungated pass counted those
     and put opus-4-7 at 18.4%, which is how the first re-derivation failed to
     reproduce the recorded table.

  2. OPERATOR-INTERVENTION EXCLUSION. If a human turn lands before the next
     assistant turn, the chain was pushed rather than taken; that is not a clean
     observation either way and is dropped.

Classification is STRUCTURAL — did feature-verify-human actually get invoked —
never keyword matching on the prose. A keyword classifier over-reported by ~2x
by counting legitimate pauses (design questions put to the operator, a correct
refusal to override a recorded deferral instruction).

PERIOD FILTERING (--since / --until) exists to measure a SHIPPED MITIGATION.
Without it every reading mixes post-ship turns with the whole pre-ship history
and dilutes the effect toward zero: after m-prose shipped (2026-09-21) the
opus-5 arm still carried 278 pre-ship turns, so even a perfect fix would have
moved the all-time rate by only a couple of points. Always pass --since when
reading an "after" number, and compare it against the recorded pre-ship
baseline in tests/results/M-PROSE-SHIP-BASELINE.md rather than against an
unfiltered run.

Filtering is on each assistant record's top-level ISO-8601 `timestamp` field,
audited at 100% coverage (0 missing, 0 malformed across 267,096 assistant
records), so a bound never silently drops data. A record whose timestamp is
absent or unparseable is EXCLUDED and COUNTED when a bound is in force, and the
count is printed — a filter that quietly skipped such records would be the same
class of confound it exists to remove.

Usage:
  /usr/bin/python3 tools/analysis/measure-f10b-handback-rate.py
  /usr/bin/python3 tools/analysis/measure-f10b-handback-rate.py --since 2026-09-21
  /usr/bin/python3 tools/analysis/measure-f10b-handback-rate.py --since 2026-09-21 --until 2026-10-31

Bounds are UTC and accept either a date (YYYY-MM-DD) or a full instant
(YYYY-MM-DDTHH:MM[:SS]Z). A bare date means the whole day: --since from
00:00:00Z, --until through 23:59:59Z.

USE THE INSTANT, NOT THE DATE, WHEN THE SHIP LANDED ON THE DAY YOU ARE
MEASURING. m-prose shipped 2026-09-21T21:33Z; `--since 2026-09-21` returned 16
"post-ship" opus-5 turns that were all recorded 12:43-15:29Z, hours BEFORE the
edit existed. The correct invocation is
`--since 2026-09-21T21:33Z`.
"""
import json,glob,os,re,collections,argparse,sys
F10B=re.compile(r"TRANSITION:\s*\*{0,2}F10b\b",re.I)
AUTO=re.compile(r"autopilot|\bFSD\b|full self.driv",re.I)
STEP=re.compile(r"stepping mode|Mode 1\b|Mode 2\b|orchestrated",re.I)
def real(d):
    b=os.path.basename(d.rstrip("/"))
    return not any(x in b for x in ("-private-var-folders","-private-tmp","-tmp-")) and b!="-"
def load(f):
    out=[]
    try:
        for l in open(f,errors="replace"):
            l=l.strip()
            if l:
                try: out.append(json.loads(l))
                except ValueError: pass
    except OSError: pass
    return out
def vh(rec):
    for b in ((rec.get("message") or {}).get("content") or []):
        if isinstance(b,dict) and b.get("type")=="tool_use":
            if "verify-human" in json.dumps(b.get("input") or {}): return True
    return False
def norm(m):
    if "opus-5" in m: return "opus-5"
    if "opus-4-8" in m or "opus-4.8" in m: return "opus-4-8"
    if "opus-4-7" in m or "opus-4.7" in m: return "opus-4-7"
    return None
ap=argparse.ArgumentParser(add_help=True)
ap.add_argument("--since",help="only count turns on/after this UTC date (YYYY-MM-DD)")
ap.add_argument("--until",help="only count turns on/before this UTC date (YYYY-MM-DD)")
A=ap.parse_args()
def _bound(v,end):
    """YYYY-MM-DD or a full instant YYYY-MM-DDTHH:MM:SSZ.

    DAY GRANULARITY IS NOT ENOUGH FOR A SHIP-DAY BOUNDARY, and assuming it was
    is a real trap this filter hit on its first run: m-prose shipped at
    21:33Z on 2026-09-21, but `--since 2026-09-21` admits the whole day, so all
    16 "post-ship" turns it returned were actually recorded 12:43-15:29Z --
    BEFORE the change existed. A same-day ship needs the instant, not the date.
    """
    if not v: return None
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}",v):
        return v+("T23:59:59.999Z" if end else "T00:00:00.000Z")
    m=re.fullmatch(r"(\d{4}-\d{2}-\d{2})[T ](\d{2}:\d{2}(?::\d{2})?)Z?",v)
    if m:
        hms=m.group(2) if len(m.group(2))==8 else m.group(2)+":00"
        return f"{m.group(1)}T{hms}.{'999' if end else '000'}Z"
    print(f"ERROR: --since/--until want YYYY-MM-DD or YYYY-MM-DDTHH:MM[:SS]Z "
          f"(got {v!r})",file=sys.stderr); sys.exit(1)
SINCE=_bound(A.since,False); UNTIL=_bound(A.until,True)
if SINCE and UNTIL and SINCE>UNTIL:
    print(f"ERROR: --since {A.since} is after --until {A.until}",file=sys.stderr); sys.exit(1)
# ISO-8601 UTC strings with a fixed shape compare correctly as plain strings.
SKIPPED_NO_TS=[0]
def in_period(r):
    if not (SINCE or UNTIL): return True
    ts=r.get("timestamp")
    if not isinstance(ts,str) or not ts.endswith("Z"):
        SKIPPED_NO_TS[0]+=1      # excluded AND counted — never silently dropped
        return False
    if SINCE and ts<SINCE: return False
    if UNTIL and ts>UNTIL: return False
    return True
tally=collections.defaultdict(lambda:[0,0])
for d in glob.glob(os.path.expanduser("~/.claude/projects/*/")):
    if not real(d): continue
    for f in glob.glob(os.path.join(d,"*.jsonl")):
        recs=load(f)
        for i,r in enumerate(recs):
            if r.get("type")!="assistant": continue
            if not in_period(r): continue
            mm=norm((r.get("message") or {}).get("model") or "")
            if not mm: continue
            bl=(r.get("message") or {}).get("content") or []
            if not isinstance(bl,list): continue
            t="\n".join(b.get("text","") for b in bl if isinstance(b,dict) and b.get("type")=="text")
            if not F10B.search(t): continue
            # DRIVE-MODE GATE: only autopilot/FSD context counts.
            ctx=json.dumps(recs[max(0,i-40):i+1])
            if not AUTO.search(ctx): continue
            # and the turn must not be explicitly telling the user to run it (single-step prose)
            if re.search(r"[Rr]un `?/feature-verify-human", t): 
                told_user=True
            else:
                told_user=False
            inv=vh(r)
            if not inv:
                for j in range(i+1,min(i+6,len(recs))):
                    rr=recs[j]
                    if rr.get("type")=="user":
                        c=(rr.get("message") or {}).get("content")
                        s=c if isinstance(c,str) else json.dumps(c)
                        if "tool_result" not in s: inv=None; break   # human pushed
                    if rr.get("type")=="assistant":
                        inv=vh(rr); break
            if inv is None: continue          # operator intervened: not a clean observation
            tally[mm][0]+=1
            if not inv: tally[mm][1]+=1
period=""
if SINCE or UNTIL:
    period=f"  [period: {A.since or 'start'} .. {A.until or 'now'} UTC]"
print("AUTOPILOT/FSD-gated (the only context where auto-chain is expected):"+period)
print(f"{'model':<12}{'F10b turns':>12}{'stopped':>10}{'rate':>9}")
for k in ("opus-4-7","opus-4-8","opus-5"):
    n,s=tally[k]
    print(f"{k:<12}{n:>12}{s:>10}{(s/n if n else 0):>8.1%}")
print(f"TOTAL turns: {sum(v[0] for v in tally.values())}")
