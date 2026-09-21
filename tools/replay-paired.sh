#!/usr/bin/env bash
# replay-paired.sh — PAIRED within-slice A/B of F10b edge-pause mitigations.
#
# WHY PAIRED (read this before changing the design):
#   Replay runs are CLUSTERED BY SLICE. The stop arm's pooled 20% is really
#   40%/10%/10% across three slices (ICC ~ 0.12, design effect 3.3 at 20
#   runs/slice). An unpaired A/B would need ~33 SLICES per arm; only ~25 real
#   opus-5 stop sessions exist and each costs a Tier-2 human audit. A paired
#   design uses each slice as its own control and tests the WITHIN-slice
#   difference, which cancels the between-slice variance eating the power.
#   Sizing + ICC derivation: docs/lessons/long-context-replay-harness.md ->
#   "Power calculation".
#
# PRE-REGISTERED BAR (binding — do not revise after seeing results):
#   Primary: per-slice BUG-rate difference (control - mitigation) over the
#   k=3 STOP slices (the 2 chained slices are negative controls, not bug-arm
#   data -- they have a different base rate and must not be pooled in).
#   A two-sided exact sign test over k=3 cannot reach 0.05 (best case 3/3
#   gives p = 0.25), so the sign test is reported for direction only and the
#   BAR ABOVE is the decision rule. Its error rates are measured, not assumed.
#   A mitigation "wins" only if ALL of:
#     (a) it reduces the BUG rate in >= k-1 of the k stop slices (k=3 -> >=2), AND
#     (b) it increases it in ZERO slices, AND
#     (c) the pooled BUG rate drops by >= 10 absolute points, AND
#     (d) no negative-control slice degrades.
#   Anything else is NOT a win. A null result is a legitimate outcome and
#   routes to WP-B3.
#
# ERROR RATES OF THAT BAR — MEASURED BY SIMULATION, NOT ASSUMED (4000 trials
# per cell; the bar was first written with NO noise floor and a synthetic
# null-effect ledger made it print "WIN", which is how this got caught):
#
#   n/slice  power(20->5%)  power(20->10%)  FALSE-POSITIVE (no real effect)
#        20           76%             46%            7.9%   <- UNACCEPTABLE
#        40           88%             49%            2.6%   <- chosen
#        60           94%             51%            0.7%
#        80           96%             50%            0.3%
#
#   => --n 40 is the operating point: 88% power against a large effect at a
#      2.6% false-positive rate. n=20 fires ~8% of the time on a mitigation
#      that does nothing.
#
#   NOTE the flat middle column: a fix that merely HALVES the rate sits at
#   ~50% power at EVERY n, because criterion (c) demands a 10-point pooled
#   drop. That is the pre-registered, deliberate limitation of a k=3 paired
#   design -- it can only see a LARGE effect. Do not reinterpret a null as
#   "promising"; a modest-but-real mitigation is INVISIBLE here by design.
#   Reproduce: tools/analysis/simulate-paired-bar.py
#
# WHAT IS AND IS NOT VARIED:
#   The rendered transcript is a FROZEN historical session and is byte-identical
#   across arms -- the mitigation is NOT written into it (that would rewrite
#   history and confound the comparison). The mitigation is injected as
#   CURRENT-instruction context, which is where a shipped SKILL.md edit would
#   actually live at the moment of the decision.
#
# Scoring is delegated to tools/analysis/score-replay-procedure.py, which is
# validated 10/10 against hand labels. Do NOT add a second classifier here.
#
# Usage:
#   tools/replay-paired.sh --n 20 --ledger tests/results/paired-ab.jsonl
#   tools/replay-paired.sh --ledger <same> --status
#   tools/replay-paired.sh --ledger <same> --report
#   tools/replay-paired.sh --ledger <same> --arms control,m-prose --n 20
#
# Exit codes: 0 ok/clean stop | 1 arg or prerequisite error | 2 missing slice
#             4 aborted after MAX_FAILS consecutive empty results (default 12)

set -euo pipefail

N=20
LEDGER=""
DEADLINE=""
MODEL="opus"
MODE="run"
BUDGET=300000
ARMS="control,m-prose,m-actdontask"

usage() { sed -n '2,50p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-1}"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --n)        N="$2"; shift 2 ;;
    --ledger)   LEDGER="$2"; shift 2 ;;
    --deadline) DEADLINE="$2"; shift 2 ;;
    --model)    MODEL="$2"; shift 2 ;;
    --budget)   BUDGET="$2"; shift 2 ;;
    --arms)     ARMS="$2"; shift 2 ;;
    --status)   MODE="status"; shift ;;
    --report)   MODE="report"; shift ;;
    -h|--help)  usage 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; usage 1 ;;
  esac
done

[ -n "$LEDGER" ] || { echo "ERROR: --ledger is required" >&2; exit 1; }
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO"
command -v claude >/dev/null || { echo "ERROR: claude CLI not on PATH" >&2; exit 1; }

# Only the 3 stop slices carry the bug; the 2 chained slices are kept as
# in-run negative controls so a mitigation cannot "win" by flattening
# everything into silence.
MATRIX=(
  "stop-claudesk-a|2026-09-21-opus5-f10b-stop-claudesk-a|2192|stop"
  "stop-claudesk-b|2026-09-21-opus5-f10b-stop-claudesk-b|1062|stop"
  "stop-hermes-a|2026-09-21-opus5-f10b-stop-hermes-a|1865|stop"
  "chained-claudesk-c|2026-09-21-opus5-f10b-chained-claudesk-c|1902|chained"
  "chained-hermes-b|2026-09-21-opus5-f10b-chained-hermes-b|2033|chained"
)

mkdir -p "$(dirname "$LEDGER")"; touch "$LEDGER"
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

# ── The arms ──────────────────────────────────────────────────────────────
# control: no added instruction. The baseline the ledger already measured.
arm_text() {
  case "$1" in
    control) printf '' ;;
    m-prose)
      # Disambiguates the cheat-sheet parenthetical the failing runs CITE as
      # their reason to stop: "AUTO (chain into verify-human, which itself
      # PAUSEs)". The pause belongs to the STATE, reachable only by entering it.
      cat <<'TXT'
CURRENT PAUSE-POLICY CLARIFICATION (supersedes any older wording in the transcript above):

| F10b (verify-self → verify-human) | Mode 3 — Autopilot | AUTO — invoke `feature-verify-human` via the Skill tool NOW |

The verify-human PAUSE belongs to the verify-human STATE, not to the edge into it. You
reach that pause by ENTERING the state — the skill evaluates its own auto-skip gate and
decides whether to pause. Ending your turn at F10b to "let the human review" is the
edge-pause regression: it skips the gate, the integration-boundary check, and the leaf
construction, and writes verify-human's output without running verify-human.

Do not end your turn on F10b in autopilot. Invoke the skill.
TXT
      ;;
    m-actdontask)
      # The operator's stated lean: a TIMING rule, not another per-transition
      # prohibition. Deliberately says nothing about F10b specifically.
      cat <<'TXT'
CURRENT OPERATING RULE (supersedes any older wording in the transcript above):

Act. Don't Ask. Do not stop to ask for permission, confirmation, or review between the
steps of a task you have already been asked to carry out. Complete the task. Ask only
when you genuinely cannot proceed without an answer that only the operator has.
TXT
      ;;
    *) echo "ERROR: unknown arm: $1" >&2; exit 1 ;;
  esac
}

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

count_done() {  # slice + arm -> recorded runs. PARSE, never grep (json.dumps spacing).
  /usr/bin/python3 -c '
import json,sys
led,sl,arm=sys.argv[1:4]; n=0
try:
    for line in open(led,errors="replace"):
        line=line.strip()
        if not line: continue
        try:
            r=json.loads(line)
            if r.get("slice")==sl and r.get("arm")==arm: n+=1
        except ValueError: pass
except OSError: pass
print(n)' "$LEDGER" "$1" "$2"
}

# Deadline as an EPOCH instant, resolved once at startup. Two bugs this avoids:
#  (1) `date +%H%M` yields e.g. 0930, and bash arithmetic reads a leading zero
#      as octal -- "0830" is an invalid octal literal and errors out, so any
#      morning deadline broke the comparison outright.
#  (2) comparing HHMM has no midnight wraparound: a deadline earlier in the
#      clock-day than "now" looked already-past and stopped the run instantly.
#      Resolving to an epoch and rolling forward a day fixes both.
DEADLINE_EPOCH=""
resolve_deadline() {
  [ -n "$DEADLINE" ] || return 0
  case "$DEADLINE" in
    *:*) ;;
    *) echo "ERROR: --deadline wants HH:MM (got '$DEADLINE')" >&2; exit 1 ;;
  esac
  local today
  today="$(date +%Y-%m-%d)"
  # BSD date (macOS) first, then GNU date.
  DEADLINE_EPOCH="$(date -j -f '%Y-%m-%d %H:%M' "$today $DEADLINE" +%s 2>/dev/null                    || date -d "$today $DEADLINE" +%s 2>/dev/null || true)"
  [ -n "$DEADLINE_EPOCH" ] || { echo "ERROR: cannot parse --deadline '$DEADLINE'" >&2; exit 1; }
  if [ "$DEADLINE_EPOCH" -le "$(date +%s)" ]; then
    DEADLINE_EPOCH=$(( DEADLINE_EPOCH + 86400 ))
    echo "Note: --deadline $DEADLINE already passed today; treating it as tomorrow."
  fi
}
past_deadline() {
  [ -n "$DEADLINE_EPOCH" ] || return 1
  [ "$(date +%s)" -ge "$DEADLINE_EPOCH" ]
}

IFS=',' read -r -a ARM_LIST <<<"$ARMS"
resolve_deadline
FAILS=0
MAX_FAILS=${MAX_FAILS:-12}

if [ "$MODE" = "report" ]; then
  exec /usr/bin/python3 tools/analysis/report-paired-ab.py --ledger "$LEDGER"
fi

if [ "$MODE" = "status" ]; then
  echo "Paired A/B progress — target n=$N per (slice, arm)"
  for row in "${MATRIX[@]}"; do
    IFS='|' read -r label _ _ exp <<<"$row"
    line="  $label ($exp):"
    for arm in "${ARM_LIST[@]}"; do
      line="$line  $arm=$(count_done "$label" "$arm")/$N"
    done
    echo "$line"
  done
  exit 0
fi

# Pre-render each slice ONCE. Identical bytes across arms — that is the point.
for row in "${MATRIX[@]}"; do
  IFS='|' read -r label slice ei exp <<<"$row"
  src="tests/sessions/${slice}.jsonl"
  [ -f "$src" ] || { echo "ERROR: missing slice $src" >&2; exit 2; }
  tools/render-session-transcript.py --source "$src" --end-index "$ei" \
    --budget-chars "$BUDGET" --out "$SCRATCH/$label.txt" >/dev/null 2>&1 \
    || { echo "ERROR: render failed for $label" >&2; exit 2; }
done
echo "Rendered ${#MATRIX[@]} slices (byte-identical across arms)."
echo "Paired A/B — model=$MODEL, n=$N per (slice,arm), arms=${ARMS}"
echo "Ledger: $LEDGER"
[ -n "$DEADLINE" ] && echo "Deadline: $DEADLINE"
echo ""

# ROUND-ROBIN over (run-index x slice x arm), in that nesting order.
#
# Run-index OUTERMOST is what makes an early stop analysable. A slice-major
# order (finish slice 1's 120 runs, then slice 2...) would, on a 1-hour stop of
# a 3.2-hour job, leave ~3 slices complete and 2 with ZERO data -- and the
# paired bar needs all 3 stop slices, so the result would be unanalysable
# despite being "balanced". Round-robin instead yields EQUAL PARTIAL DEPTH
# across every (slice, arm) cell, which --report can analyse at whatever n was
# reached. Arms stay adjacent within a slice so model drift is still shared.
for i in $(seq 1 "$N"); do
  for row in "${MATRIX[@]}"; do
    IFS='|' read -r label slice ei exp <<<"$row"
    for arm in "${ARM_LIST[@]}"; do
      have=$(count_done "$label" "$arm")
      [ "$have" -ge "$i" ] && continue
      if past_deadline; then
        echo ""; echo "[deadline $DEADLINE] stopping cleanly. Re-run to resume."; exit 0
      fi
      extra="$(arm_text "$arm")"
      sys="$(cat "$SCRATCH/$label.txt")"
      if [ -n "$extra" ]; then sys="$sys

$extra"; fi
      t0=$(date +%s)
      set +e
      out=$(cd /tmp && claude --print "continue" --model "$MODEL" \
              --no-session-persistence --permission-mode dontAsk \
              --disallowed-tools "Edit,Write,NotebookEdit" \
              --append-system-prompt "$sys

$PROMPT" --output-format json 2>/dev/null | jq -r '.result // empty')
      rc=$?
      set -e
      t1=$(date +%s)
      if [ -z "$out" ]; then
        # Bounded retry. An unbounded `continue` here spins forever on a
        # sustained API outage or a malformed-response bug, which is the worst
        # failure for an unattended run: it burns the whole window printing
        # retry lines and records nothing. Cap it, then move on to the next
        # cell so the rest of the matrix still fills.
        FAILS=$(( FAILS + 1 ))
        echo "  $label/$arm run $i: empty (rc=$rc) — not recorded (fail $FAILS/$MAX_FAILS)"
        if [ "$FAILS" -ge "$MAX_FAILS" ]; then
          echo ""
          echo "ABORT: $MAX_FAILS consecutive empty results — the API or the"
          echo "harness is broken, not the model. Nothing further recorded."
          echo "Ledger is intact and resumable: re-run the identical command."
          exit 4
        fi
        sleep 5
        continue
      fi
      FAILS=0
      printf '%s' "$out" > "$SCRATCH/resp.txt"
      /usr/bin/python3 - "$LEDGER" "$label" "$exp" "$arm" "$i" \
          "$(( t1 - t0 ))" "$MODEL" "$SCRATCH/resp.txt" <<'RECPY'
import json,os,sys
led,sl,exp,arm,idx,dur,model,respf=sys.argv[1:9]
rec=dict(slice=sl,expected=exp,arm=arm,run=int(idx),seconds=int(dur),
         model=model,response=open(respf,errors="replace").read())
with open(led,"a") as fh:
    fh.write(json.dumps(rec)+"\n"); fh.flush(); os.fsync(fh.fileno())
RECPY
      printf '  %-20s %-14s run %-3s (%ss)\n' "$label" "$arm" "$i" "$(( t1 - t0 ))"
    done
  done
done
echo ""
echo "Complete. Run with --report for the paired analysis."
