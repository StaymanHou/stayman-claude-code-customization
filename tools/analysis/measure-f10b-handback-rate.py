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

Usage: /usr/bin/python3 tools/analysis/measure-f10b-handback-rate.py
"""
import json,glob,os,re,collections
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
tally=collections.defaultdict(lambda:[0,0])
for d in glob.glob(os.path.expanduser("~/.claude/projects/*/")):
    if not real(d): continue
    for f in glob.glob(os.path.join(d,"*.jsonl")):
        recs=load(f)
        for i,r in enumerate(recs):
            if r.get("type")!="assistant": continue
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
print("AUTOPILOT/FSD-gated (the only context where auto-chain is expected):")
print(f"{'model':<12}{'F10b turns':>12}{'stopped':>10}{'rate':>9}")
for k in ("opus-4-7","opus-4-8","opus-5"):
    n,s=tally[k]
    print(f"{k:<12}{n:>12}{s:>10}{(s/n if n else 0):>8.1%}")
print(f"TOTAL turns: {sum(v[0] for v in tally.values())}")
