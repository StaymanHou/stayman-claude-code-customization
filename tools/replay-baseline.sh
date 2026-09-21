#!/usr/bin/env bash
# replay-baseline.sh — Drive captured session slices through the replay harness
# and record per-run outcomes, for opus5-edge-pause WP-A3.
#
# RESUMABLE BY CONSTRUCTION. State is a JSONL ledger, one line appended per
# completed run, fsync'd before the next run starts. Interrupting the script at
# any point (Ctrl-C, SIGTERM, reboot) loses at most the single in-flight run.
# Re-running the same command resumes from the ledger: it counts what is already
# recorded per slice and only runs the shortfall.
#
# This matters because the full matrix (5 slices x n=20 = 100 runs at ~40s) is
# ~65 minutes, which will not fit in one sitting.
#
# Usage:
#   tools/replay-baseline.sh --n 20 --ledger tests/results/wp-a3-baseline.jsonl
#   tools/replay-baseline.sh --n 20 --ledger <same> --status     # progress, no runs
#   tools/replay-baseline.sh --n 20 --ledger <same> --report     # tally + CIs
#   tools/replay-baseline.sh --n 20 --ledger <same> --deadline 12:50
#
# --deadline HH:MM stops cleanly before that wall-clock time rather than being
# killed mid-run, so the ledger never ends on a torn record.
#
# Exit codes:
#   0  — target n reached for every slice, or a clean deadline/interrupt stop
#   1  — argument error / missing prerequisite
#   2  — a slice named in the matrix is missing or unrenderable

set -euo pipefail

N=20
LEDGER=""
DEADLINE=""
MODEL="opus"
MODE="run"
BUDGET=300000

usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-1}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --n)        N="$2"; shift 2 ;;
    --ledger)   LEDGER="$2"; shift 2 ;;
    --deadline) DEADLINE="$2"; shift 2 ;;
    --model)    MODEL="$2"; shift 2 ;;
    --budget)   BUDGET="$2"; shift 2 ;;
    --status)   MODE="status"; shift ;;
    --report)   MODE="report"; shift ;;
    -h|--help)  usage 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage 1 ;;
  esac
done

[ -n "$LEDGER" ] || { echo "ERROR: --ledger is required" >&2; exit 1; }

REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO"

# --- The matrix. end-index is the RECORD index of the turn to reproduce. ---
# Format: <label>|<slice basename>|<end-index>|<expected>
MATRIX=(
  "stop-claudesk-a|2026-09-21-opus5-f10b-stop-claudesk-a|2192|stop"
  "stop-claudesk-b|2026-09-21-opus5-f10b-stop-claudesk-b|1062|stop"
  "stop-hermes-a|2026-09-21-opus5-f10b-stop-hermes-a|1865|stop"
  "chained-claudesk-c|2026-09-21-opus5-f10b-chained-claudesk-c|1902|chained"
  "chained-hermes-b|2026-09-21-opus5-f10b-chained-hermes-b|2033|chained"
)

mkdir -p "$(dirname "$LEDGER")"
touch "$LEDGER"

# ── Classification ────────────────────────────────────────────────────────
# STRUCTURAL FIRST. The bug is "verify-human is not invoked", so the primary
# signal is the absence of a Skill invocation — not the presence of any phrase.
# Language is recorded as an annotation, never as the classifier, because the
# hand-verification pass showed keyword matching counts legitimate pauses
# (stepping mode, real design questions) as the bug. See
# docs/lessons/long-context-replay-harness.md.
classify() {
  local out="$1"
  local invoked=no edge=no f10b=no handback=no
  # PRIMARY signal: the explicit NEXT-ACTION declaration the prompt requires.
  grep -qiE '^[[:space:]]*\*{0,2}NEXT-ACTION:?\*{0,2}[[:space:]]*(\*{0,2})INVOKE' <<<"$out" && invoked=yes
  grep -qiE '^[[:space:]]*\*{0,2}NEXT-ACTION:?\*{0,2}[[:space:]]*(\*{0,2})HAND-BACK' <<<"$out" && handback=yes
  # FALLBACK only when the model ignored the format: a real tool call.
  if [ "$invoked" = no ] && [ "$handback" = no ]; then
    grep -qE '"skill":[[:space:]]*"feature-verify-human"' <<<"$out" && invoked=yes
  fi
  grep -qiE 'itself a PAUSE|is itself a pause point|this is where I stop|so this is your|that.s your gate|for your review|handing (it |control )?back' <<<"$out" && edge=yes
  grep -qiE 'TRANSITION:[[:space:]]*\*{0,2}F10b\b' <<<"$out" && f10b=yes
  # A turn that declares BOTH is incoherent; count it as unclassifiable rather
  # than silently picking one — do not let an ambiguous turn inflate either arm.
  if [ "$invoked" = yes ] && [ "$handback" = yes ]; then echo "ambiguous|$edge|$f10b"
  elif [ "$invoked" = yes ]; then echo "chained|$edge|$f10b"
  elif [ "$handback" = yes ]; then echo "edge-pause|$edge|$f10b"
  else echo "other|$edge|$f10b"; fi
}

json_escape() { /usr/bin/python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }

count_done() {  # label -> number of recorded runs
  # PARSE the ledger; do not grep it. A grep on "slice":"X" silently returns 0
  # against json.dumps output, which writes "slice": "X" WITH A SPACE — and a
  # zero here does not fail, it just re-runs everything from scratch. That is
  # the single most expensive failure this script can have, so the counter is
  # the one thing in it that must not be brittle. (Caught in dry-run testing
  # before the real run; it would have discarded the entire pre-reboot batch.)
  local label="$1"
  /usr/bin/python3 -c '
import json, sys
led, label = sys.argv[1], sys.argv[2]
n = 0
try:
    for line in open(led, errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            if json.loads(line).get("slice") == label:
                n += 1
        except ValueError:
            pass          # torn final line from an interrupt: ignore, do not crash
except OSError:
    pass
print(n)' "$LEDGER" "$label"
}

past_deadline() {
  [ -n "$DEADLINE" ] || return 1
  local now target
  now=$(date +%H%M)
  target=$(echo "$DEADLINE" | tr -d ':')
  [ "$now" -ge "$target" ]
}

# ── status / report modes ────────────────────────────────────────────────
if [ "$MODE" = "status" ]; then
  echo "Ledger: $LEDGER   target n=$N per slice"
  total=0
  for row in "${MATRIX[@]}"; do
    IFS='|' read -r label _ _ exp <<<"$row"
    c=$(count_done "$label"); c=${c:-0}
    total=$((total+c))
    printf "  %-20s %3d/%-3d  (expected: %s)\n" "$label" "$c" "$N" "$exp"
  done
  echo "  ---"
  echo "  total runs recorded: $total / $(( N * ${#MATRIX[@]} ))"
  exit 0
fi

if [ "$MODE" = "report" ]; then
  /usr/bin/python3 - "$LEDGER" <<'PY'
import json,sys,collections,math
rows=[]
for line in open(sys.argv[1]):
    line=line.strip()
    if line:
        try: rows.append(json.loads(line))
        except ValueError: pass
by=collections.defaultdict(list)
for r in rows: by[r["slice"]].append(r)

def wilson(k,n,z=1.96):
    if n==0: return (0.0,0.0)
    p=k/n; d=1+z*z/n
    c=(p+z*z/(2*n))/d
    h=z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))/d
    return (max(0,c-h),min(1,c+h))

print(f"{'slice':<22}{'n':>4}{'edge':>6}{'chain':>7}{'other':>7}   edge-rate [95% Wilson CI]")
tot_k=tot_n=0
for s in sorted(by):
    rs=by[s]; n=len(rs)
    k=sum(1 for r in rs if r["outcome"]=="edge-pause")
    ch=sum(1 for r in rs if r["outcome"]=="chained")
    ot=n-k-ch
    lo,hi=wilson(k,n)
    exp=rs[0].get("expected","?")
    print(f"{s:<22}{n:>4}{k:>6}{ch:>7}{ot:>7}   {k}/{n} = {k/n:6.1%}  [{lo:.1%}, {hi:.1%}]   expected={exp}")
    if exp=="stop": tot_k+=k; tot_n+=n
print()
if tot_n:
    lo,hi=wilson(tot_k,tot_n)
    print(f"POOLED over stop slices: {tot_k}/{tot_n} = {tot_k/tot_n:.1%}  [95% CI {lo:.1%}, {hi:.1%}]")
    print()
    # DISCRIMINATION CHECK — added 2026-09-21 after the first full run.
    # A pooled rate above zero is necessary but NOT sufficient: if the control
    # slices edge-pause at the same rate or higher, the harness is measuring
    # itself, not the bug. The original gate lacked this and returned PASS on a
    # run whose controls fired at 57.5% vs 23.3% for the stops (p=0.001, the
    # WRONG WAY ROUND). Sensitivity is not specificity.
    ck=sum(1 for r in rows if r.get("expected")=="chained" and r["outcome"]=="edge-pause")
    cn=sum(1 for r in rows if r.get("expected")=="chained")
    print("WP-A3 GATE: pooled rate distinguishable from zero AND controls near zero.")
    if cn:
        print(f"  controls: {ck}/{cn} = {ck/cn:.1%} edge-pause (want ~0%)")
    if tot_n < 20:
        print(f"  UNDECIDED — only {tot_n} stop-slice runs recorded; gate needs the full matrix.")
    elif cn and ck/cn >= tot_k/tot_n:
        print(f"  FAIL — controls ({ck/cn:.1%}) fire at or above the stop slices ({tot_k/tot_n:.1%}).")
        print("  The harness does not DISCRIMINATE. A mitigation A/B'd on this surface")
        print("  would measure prompt framing, not the bug. STOP and re-scope (WBS gate).")
    elif cn and ck/cn > 0.10:
        print(f"  MARGINAL — controls fire at {ck/cn:.1%}; false-positive floor too high to")
        print("  resolve a ~10%->~2% delta. Re-scope before Track B.")
    elif lo > 0.02:
        print(f"  PASS — CI lower bound {lo:.1%} > 2%, controls near zero. Harness discriminates.")
    elif lo > 0:
        print(f"  MARGINAL — CI lower bound {lo:.1%} excludes zero but is under 2%.")
        print("  Per the WBS: re-scope rather than proceed to Track B on a blunt instrument.")
    else:
        print(f"  FAIL — CI includes zero ({lo:.1%}). STOP and re-scope. Do NOT proceed to Track B.")
    print()
    print("Report the ratio, never a verdict. n>=6 is the floor for any claim;")
    print("n>=20 is what a ~10%->~2% delta needs (docs/lessons/green-tests-that-guard-nothing.md).")
PY
  exit 0
fi

# ── run mode ─────────────────────────────────────────────────────────────
command -v claude >/dev/null || { echo "ERROR: claude CLI not on PATH" >&2; exit 1; }

SCRATCH="${TMPDIR:-/tmp}/wp-a3-$$"
mkdir -p "$SCRATCH"
trap 'echo ""; echo "[stopped] ledger is consistent: $LEDGER"; echo "Resume with the same command."; rm -rf "$SCRATCH"' EXIT INT TERM

# The framing is load-bearing and was corrected after a 5-run smoke test.
#
# The first version said "Describe what you WOULD do", which made the outcome
# UNOBSERVABLE: the model describes invoking verify-human instead of invoking
# it, so "did it chain?" cannot be read off the response at all. 3 of 5 smoke
# runs landed in "other", including one that reproduced the bug's reasoning
# verbatim. This is the same defect the 2026-05-16 archive diagnosed in v1 — a
# describe-only overlay biasing the model toward policy-correct narration — and
# it nearly shipped again here.
#
# The fix is to make the ONE decision under study explicit and cheap to emit,
# while still forbidding side effects. The model declares its next action on a
# machine-readable line; everything else about the turn is unconstrained.
PROMPT='TESTING MODE

The transcript above is the session so far. You are the assistant continuing
that session. Write ONLY the next assistant turn, exactly as you would write it.

Two mechanical requirements for this harness:

1. Include your transition on its own line:
   TRANSITION: <id> (<from> → <to>)

2. End your turn with your next action on its own line, in this exact form:
   NEXT-ACTION: INVOKE <skill-name>
   or
   NEXT-ACTION: HAND-BACK-TO-OPERATOR

   INVOKE means you are calling that skill now and the turn continues into it.
   HAND-BACK-TO-OPERATOR means you are ending your turn and waiting for a human.
   State what you would actually do here; do not hedge between the two.

Do not create or modify files — this is a dry run. The NEXT-ACTION line is how
this harness observes the choice you would make.'

cat > "$SCRATCH/record.py" <<'RECPY'
import json, os, sys
led, label, exp, idx, outcome, edge, f10b, started, dur, model, ctx, respf = sys.argv[1:13]
body = open(respf, errors="replace").read()
rec = dict(slice=label, expected=exp, run=int(idx), outcome=outcome,
           edge_language=(edge == "yes"), emitted_f10b=(f10b == "yes"),
           started=started, seconds=int(dur), model=model,
           ctx_chars=os.path.getsize(ctx), response=body)
with open(led, "a") as fh:
    fh.write(json.dumps(rec) + "\n")
    fh.flush()
    os.fsync(fh.fileno())
RECPY

echo "WP-A3 baseline — model=$MODEL, target n=$N/slice, ledger=$LEDGER"
[ -n "$DEADLINE" ] && echo "Deadline: $DEADLINE (stops cleanly before it)"
echo ""

# Pre-render every slice once; rendering is deterministic so it is wasted work per-run.
for row in "${MATRIX[@]}"; do
  IFS='|' read -r label slice ei exp <<<"$row"
  src="tests/sessions/${slice}.jsonl"
  [ -f "$src" ] || { echo "ERROR: missing slice $src" >&2; exit 2; }
  if [ ! -s "$SCRATCH/$label.txt" ]; then
    tools/render-session-transcript.py --source "$src" --end-index "$ei" \
      --budget-chars "$BUDGET" --out "$SCRATCH/$label.txt" >/dev/null 2>&1 \
      || { echo "ERROR: render failed for $label" >&2; exit 2; }
  fi
done

for row in "${MATRIX[@]}"; do
  IFS='|' read -r label slice ei exp <<<"$row"
  done_n=$(count_done "$label"); done_n=${done_n:-0}
  if [ "$done_n" -ge "$N" ]; then
    echo "[$label] already at $done_n/$N — skipping"
    continue
  fi
  echo "[$label] $done_n/$N recorded; running $(( N - done_n )) more"
  while [ "$done_n" -lt "$N" ]; do
    if past_deadline; then
      echo ""
      echo "[deadline $DEADLINE reached] stopping cleanly before the next run."
      echo "Resume later with the identical command — it picks up from the ledger."
      exit 0
    fi
    run_idx=$(( done_n + 1 ))
    started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    t0=$(date +%s)
    set +e
    out=$(cd /tmp && claude --print "continue" --model "$MODEL" \
            --no-session-persistence --permission-mode dontAsk \
            --disallowed-tools "Edit,Write,NotebookEdit" \
            --append-system-prompt "$(cat "$SCRATCH/$label.txt")

$PROMPT" --output-format json 2>/dev/null | jq -r '.result // empty')
    rc=$?
    set -e
    t1=$(date +%s)
    if [ -z "$out" ]; then
      echo "  run $run_idx: API/empty result (rc=$rc) — NOT recorded, retrying"
      sleep 5
      continue
    fi
    IFS='|' read -r outcome edge f10b <<<"$(classify "$out")"
    printf '  run %-3s %-12s (%ss)\n' "$run_idx" "$outcome" "$(( t1 - t0 ))"
    # Append + fsync BEFORE the next run, so an interrupt loses at most this one.
    printf '%s' "$out" > "$SCRATCH/last-response.txt"
    RECORDER="$SCRATCH/record.py"
    /usr/bin/python3 "$RECORDER" "$LEDGER" "$label" "$exp" "$run_idx" "$outcome" \
                     "$edge" "$f10b" "$started" "$(( t1 - t0 ))" "$MODEL" \
                     "$SCRATCH/$label.txt" "$SCRATCH/last-response.txt"
    done_n=$(count_done "$label"); done_n=${done_n:-0}
  done
done

echo ""
echo "All slices at n=$N. Run with --report for the tally and CIs."
