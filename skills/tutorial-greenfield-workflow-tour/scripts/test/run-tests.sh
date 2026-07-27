#!/usr/bin/env bash
# run-tests.sh — smoke test for the onboarding sample + scaffolder (WP7c; sample
# redesigned to a todo CLI in WP7i).
#
# Codifies the sample's Observable Outcomes:
#   1. `todo add "buy milk" && todo list` prints exactly "1. [ ] buy milk"
#      (the verify-self grounding target)
#   2. `todo add … && todo done 1 && todo list` marks item 1 "[x]" (persisted)
#   3. planted tangent is real + authentic: `todo done 99` on a short list reports
#      success, exits 0, and changes nothing (out-of-range no-op); README carries a TODO
#   4. sample is no-runtime: bash -n clean on every *.sh, all shebangs are bash
#   5. scaffolder produces a fresh runnable copy, independent of the source
#   6. scaffolder refuses to clobber a non-empty dest (writes nothing) unless --force
#   7. scaffolder --help shows only usage prose (no leaked code) + prints a //-free path
#   8. greenfield arm references this scaffold (arm ↔ scaffold wiring contract),
#      including its --dest invocation form (WP7l)
#   9. `--dest .` from inside the cwd: flat stamp + runnable + non-empty refusal (WP7l —
#      the tour's actual invocation form; distinct path from groups 5/6's nested --dest)
#
# End-to-end CLI test — no framework, no deps (matches the no-runtime repo convention
# and the shell-tool test shape used by tools/migrate-doc-layout/test/ and tools/uninstall/test/).
# Exit 0 = all pass; non-zero = a failure (prints which).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SAMPLE="$TOOL_DIR/sample"
SCAFFOLD="$TOOL_DIR/new-sample.sh"

pass=0
fail=0
TMPDIRS=()

cleanup() { for d in "${TMPDIRS[@]:-}"; do [ -n "$d" ] && rm -rf "$d"; done; }
trap cleanup EXIT

ok()   { pass=$((pass+1)); echo "  PASS: $1"; }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }

# Give each scenario its own throwaway store so runs don't interfere and the
# shipped sample/todos.txt is never touched.
fresh_store() { local d; d="$(mktemp -d)"; TMPDIRS+=("$d"); echo "$d/todos.txt"; }

echo "== onboarding-scaffold smoke test =="

# ── 1. Sample runnable — exact observable outcome ────────────────────────────
echo "[1] sample todo add + list -> exact observable"
S="$(fresh_store)"
TODO_STORE="$S" "$SAMPLE/todo" add "buy milk" >/dev/null 2>&1
out="$(TODO_STORE="$S" "$SAMPLE/todo" list)"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = "1. [ ] buy milk" ]; then
  ok "todo add \"buy milk\" && todo list -> exit 0, stdout exactly '1. [ ] buy milk'"
else
  bad "todo add/list: rc=$rc stdout=[$out] (expected exit 0 / '1. [ ] buy milk')"
fi

# ── 2. done persists the checkbox flip ───────────────────────────────────────
echo "[2] todo done marks + persists"
S="$(fresh_store)"
TODO_STORE="$S" "$SAMPLE/todo" add "a" >/dev/null 2>&1
TODO_STORE="$S" "$SAMPLE/todo" done 1 >/dev/null 2>&1
out="$(TODO_STORE="$S" "$SAMPLE/todo" list)"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = "1. [x] a" ]; then
  ok "todo add a && done 1 && list -> '1. [x] a' (persisted)"
else
  bad "todo done: rc=$rc stdout=[$out] (expected '1. [x] a')"
fi

# ── 3. Planted tangent is real + authentic (out-of-range done is a no-op) ─────
echo "[3] planted tangent (out-of-range done)"
S="$(fresh_store)"
TODO_STORE="$S" "$SAMPLE/todo" add "only item" >/dev/null 2>&1
before="$(TODO_STORE="$S" "$SAMPLE/todo" list)"
tang="$(TODO_STORE="$S" "$SAMPLE/todo" done 99)"; rc=$?
after="$(TODO_STORE="$S" "$SAMPLE/todo" list)"
if [ "$rc" -eq 0 ] && [ "$before" = "$after" ] && printf '%s' "$tang" | grep -q '99'; then
  ok "todo done 99 on a 1-item list -> exit 0, reports item 99, list UNCHANGED (authentic bug)"
else
  bad "tangent: rc=$rc before=[$before] after=[$after] msg=[$tang] (expected no-op mishandling)"
fi
if grep -q 'TODO' "$SAMPLE/README.md"; then
  ok "sample README documents the tangent (contains TODO)"
else
  bad "sample README has no TODO documenting the tangent"
fi

# ── 4. No-runtime: bash -n clean, only bash shebangs ─────────────────────────
echo "[4] no-runtime (bash -n + shebangs)"
parse_ok=1
while IFS= read -r f; do
  bash -n "$f" 2>/dev/null || { parse_ok=0; echo "    parse fail: $f"; }
done < <(find "$SAMPLE" -name '*.sh' -o -name 'todo')
[ "$parse_ok" -eq 1 ] && ok "bash -n clean on all sample scripts" || bad "a sample script failed bash -n"
# every shebang line is bash; no other interpreter
nonbash="$(grep -rhE '^#!' "$SAMPLE" | grep -v 'env bash' || true)"
[ -z "$nonbash" ] && ok "all shebangs are '#!/usr/bin/env bash' (no other interpreter)" \
  || bad "non-bash shebang found: $nonbash"

# ── 5. Scaffolder produces a fresh, independent, runnable copy ────────────────
echo "[5] scaffolder fresh copy + independence"
D="$(mktemp -d)"; TMPDIRS+=("$D")
if "$SCAFFOLD" --dest "$D/s" >/dev/null 2>&1; then
  cs="$(mktemp -d)"; TMPDIRS+=("$cs")
  TODO_STORE="$cs/todos.txt" "$D/s/todo" add "buy milk" >/dev/null 2>&1
  copyout="$(TODO_STORE="$cs/todos.txt" "$D/s/todo" list 2>/dev/null)"; rc=$?
  if [ "$rc" -eq 0 ] && [ "$copyout" = "1. [ ] buy milk" ]; then
    ok "scaffolded copy runs: todo add/list -> '1. [ ] buy milk'"
  else
    bad "scaffolded copy: rc=$rc stdout=[$copyout]"
  fi
  # independence: mutate the copy, source must be untouched
  marker="INDEPENDENCE_MARKER_$$"
  echo "# $marker" >> "$D/s/todo"
  if grep -q "$marker" "$SAMPLE/todo"; then
    bad "editing the copy leaked into the source todo"
  else
    ok "editing the copy does NOT touch the source (independent)"
  fi
else
  bad "scaffolder failed to produce a copy at $D/s"
fi

# ── 6. Scaffolder refuses to clobber a non-empty dest (no --force) ────────────
echo "[6] no-clobber guard"
NE="$(mktemp -d)"; TMPDIRS+=("$NE")
echo "keep" > "$NE/keep.txt"
if "$SCAFFOLD" --dest "$NE" >/dev/null 2>&1; then
  bad "scaffolder overwrote a non-empty dir without --force (should have refused)"
else
  # must have written nothing: only keep.txt remains, no todo
  if [ -e "$NE/todo" ]; then
    bad "scaffolder refused (exit non-zero) but still wrote files into the non-empty dir"
  else
    ok "scaffolder refused non-empty dest and wrote nothing"
  fi
fi
# and --force DOES overwrite + stays runnable
fs="$(mktemp -d)"; TMPDIRS+=("$fs")
if "$SCAFFOLD" --dest "$NE" --force >/dev/null 2>&1 \
   && [ "$(TODO_STORE="$fs/todos.txt" "$NE/todo" add "x" >/dev/null 2>&1; TODO_STORE="$fs/todos.txt" "$NE/todo" list 2>/dev/null)" = "1. [ ] x" ]; then
  ok "scaffolder --force overwrites and the result is runnable"
else
  bad "scaffolder --force did not overwrite/run correctly"
fi

# ── 7. Scaffolder --help hygiene: no code leak + no double-slash path ─────────
echo "[7] scaffolder --help + path hygiene"
help="$("$SCAFFOLD" --help 2>&1)"
if printf '%s' "$help" | grep -qE 'set -euo pipefail|SCRIPT_DIR=|SRC='; then
  bad "--help leaks script code (found 'set -euo pipefail' / an assignment)"
else
  ok "--help shows only usage prose (no leaked code)"
fi
# default-dest path must not contain // even when TMPDIR ends in /
slashout="$(TMPDIR="${TMPDIR:-/tmp}/" "$SCAFFOLD" 2>/dev/null | head -1)"
# clean up whatever it just made
made="$(printf '%s' "$slashout" | sed -n 's/^Created fresh sample at: //p')"
[ -n "$made" ] && TMPDIRS+=("$(dirname "$made")")
if printf '%s' "$slashout" | grep -q '//'; then
  bad "default-dest printed path contains // (TMPDIR trailing-slash not stripped)"
else
  ok "default-dest printed path has no // (trailing-slash stripped)"
fi

# ── 8. Wiring contract: the greenfield arm references this scaffold (WP7c/WP7i) ──
# Anti-regression guard against the arm and the scaffold drifting apart (e.g. a future
# scaffold rename silently orphaning the arm's drop-in reference). This pins the
# consuming-surface wiring only; the tour's behavioral scenarios + structural pins are
# WP7e's job — deliberately NOT duplicated here.
echo "[8] greenfield arm ↔ scaffold wiring"
# The scaffold now lives INSIDE the greenfield arm skill dir (WP7j Phase 6):
# skills/tutorial-greenfield-workflow-tour/scripts/. So TOOL_DIR is .../scripts and
# the arm SKILL.md is its parent dir's SKILL.md.
ARM="$TOOL_DIR/../SKILL.md"
if [ -f "$ARM" ]; then
  grep -q 'scripts/new-sample.sh\|scripts/sample' "$ARM" \
    && ok "arm SKILL.md references the in-skill scaffold path (scripts/)" \
    || bad "arm SKILL.md no longer references the in-skill scripts/ scaffold (wiring drifted)"
  grep -q '1. \[ \] buy milk' "$ARM" \
    && ok "arm SKILL.md cites the runnable observable (1. [ ] buy milk)" \
    || bad "arm SKILL.md no longer cites the '1. [ ] buy milk' observable"
  grep -q 'done 99' "$ARM" \
    && ok "arm SKILL.md cites the planted tangent (done 99)" \
    || bad "arm SKILL.md no longer cites the 'done 99' tangent"
  # WP7l: the arm must invoke the scaffolder with a --dest argument (stamping into the
  # user's own cwd), NOT bare (which would stamp into a $TMPDIR dir the agent cd's into
  # — the behavior the operator's live walkthrough rejected). Wiring-contract scope:
  # this pins the INVOCATION FORM the arm depends on, not the tour's prose/copy.
  grep -q 'new-sample.sh --dest' "$ARM" \
    && ok "arm SKILL.md invokes the scaffolder with --dest (stamps into the user's cwd)" \
    || bad "arm SKILL.md lost its --dest invocation (would stamp into a temp dir again — WP7l regression)"
else
  echo "  SKIP: arm SKILL.md not found at expected path ($ARM) — wiring check skipped"
fi

# ── 9. `--dest .` from inside the cwd: flat stamp + refusal (WP7l) ────────────
# The tour's actual invocation form. Groups 5/6 cover `--dest <nonexistent-nested-dir>`;
# neither exercises `--dest .` executed from *inside* the target, which is what the arm
# now runs. Distinct code path worth pinning: `.` always exists (so the "nonexistent"
# branch never fires) and emptiness is judged on the cwd itself.
echo "[9] --dest . flat stamp into cwd + non-empty refusal"
C="$(mktemp -d)"; TMPDIRS+=("$C")
if ( cd "$C" && "$SCAFFOLD" --dest . >/dev/null 2>&1 ); then
  # flat: the sample's contents land at the top level, with NO nested wrapper dir
  if [ -f "$C/todo" ] && [ -d "$C/lib" ] && [ -f "$C/todos.txt" ] && [ -f "$C/README.md" ] \
     && [ ! -d "$C/todo" ]; then
    ok "--dest . stamps FLAT into the cwd (todo, lib/, todos.txt, README.md at top level)"
  else
    bad "--dest . did not stamp flat into the cwd (contents: $(ls -A "$C" | tr '\n' ' '))"
  fi
  # and the flat copy is runnable — the grounding observable still holds from the cwd.
  # NOTE: deliberately NO TODO_STORE override here. The tour's Step-5 grounding beat runs
  # the bare `./todo add "buy milk" && ./todo list`, so the store it exercises is the
  # flat-stamped `./todos.txt` resolved from the dispatcher's own SCRIPT_DIR. Overriding
  # TODO_STORE to an external temp file (as groups 1-3 must, to protect the shipped
  # sample/) would test a path the tour never uses and would hide a SCRIPT_DIR-resolution
  # or stamped-file-permission regression. Isolation is unnecessary here: $C is already a
  # throwaway mktemp -d, so the default store IS disposable.
  out9="$(cd "$C" && ./todo add "buy milk" >/dev/null 2>&1; cd "$C" && ./todo list 2>/dev/null)"
  [ "$out9" = "1. [ ] buy milk" ] \
    && ok "flat-stamped cwd copy runs on its OWN ./todos.txt: ./todo add/list -> '1. [ ] buy milk'" \
    || bad "flat-stamped cwd copy not runnable on its own store: stdout=[$out9]"
  # the stamped store is the one that actually got written (guards SCRIPT_DIR resolution)
  grep -q "buy milk" "$C/todos.txt" 2>/dev/null \
    && ok "the flat-stamped ./todos.txt is the store that was written" \
    || bad "./todo wrote somewhere other than the flat-stamped ./todos.txt"
else
  bad "--dest . failed to stamp into an empty cwd"
fi
# Re-running in the now-non-empty cwd must refuse and write nothing new. This is the
# case a REPLAY hits every time (user stands in their previous run's dir), so the arm
# depends on the refusal being reliable rather than a partial overwrite.
before9="$(cd "$C" && find . | sort)"
if ( cd "$C" && "$SCAFFOLD" --dest . >/dev/null 2>&1 ); then
  bad "--dest . overwrote a non-empty cwd without --force (should have refused)"
else
  after9="$(cd "$C" && find . | sort)"
  [ "$before9" = "$after9" ] \
    && ok "--dest . refused the non-empty cwd and wrote nothing (tree identical)" \
    || bad "--dest . refused but mutated the cwd tree"
fi

echo

# ── 10. §D destructive-offer protocol in the arm's prose (WP7o) ────────────────
# Group 9 above already pins the SCAFFOLDER half of §D (refuses, writes nothing) on the
# real `--dest .` path, so this group deliberately does NOT re-assert that. What is new in
# WP7o is the ARM-side offer: on refusal the arm may offer to CLEAR the directory, which is
# destructive and therefore governed by hard rules. Those rules live in prose (the arm
# instructs an agent), so prose is the only place they can be pinned.
#
# Every assertion below is a NEGATIVE or presence check on one file, so each is wrapped in
# an explicit `[ -f ]` precondition that fails CLOSED. Per the repo convention
# (CLAUDE.md:259): a negative shell assertion run against a missing/renamed file passes
# VACUOUSLY -- `2>/dev/null` swallows the error, `|| true` eats the status, and `${n:-0}`
# turns the empty capture into the expected 0. Mutation testing structurally CANNOT catch
# that branch, because proving the assertion "can fail" requires the file to exist. The
# rename case is real here: this arm's scaffold was re-homed once already (WP7j moved it
# from tools/onboarding-scaffold/ into skills/.../scripts/).
echo "[10] §D destructive-offer protocol (arm prose)"
# ARM is already defined by group 8 as "$TOOL_DIR/../SKILL.md"; re-derive it here so this
# group stays valid if group 8 is ever moved or removed.
ARM="$TOOL_DIR/../SKILL.md"
if [ ! -f "$ARM" ]; then
  bad "arm SKILL.md not found at $ARM — cannot verify the §D protocol; if the skill was renamed or the scaffold re-homed again, update ARM in this test"
else
  # (a) show-before-asking: the arm must instruct an `ls -A` listing.
  #     SCOPE NOTE: a grep can only prove the instruction is PRESENT — it cannot prove the
  #     listing is ORDERED before the question (that is prose semantics, and it belongs to
  #     the verify-self coherence read). The ok() message says "instructs", not "shows
  #     before asking", so the pin does not overstate what it actually proves.
  grep -q 'ls -A' "$ARM" \
    && ok "arm instructs an ls -A listing (ordering itself is the coherence read's gate)" \
    || bad "arm does not tell the agent to run ls -A before offering to clear"

  # (b) explicit consent: a bare forward-motion "go"/"proceed" must not count as consent.
  #     NOTE: the clause is LINE-WRAPPED in the prose ("is **not**" ends one line, "consent
  #     to delete" begins the next), so a single-line grep misses it. Match on a
  #     wrap-immune anchor instead. This is the documented prose-grep blind spot
  #     (docs/lessons/verify-grep-blind-spots.md): suspect the grep before the copy.
  grep -qi 'not.*consent to delete\|Explicit confirmation only' "$ARM" \
    && ok "arm requires EXPLICIT consent (bare 'go'/'proceed' is not consent to delete)" \
    || bad "arm does not state that bare forward-motion replies are not consent to delete"

  # (c) the alternative is a peer option, not a grudging fallback
  grep -q 'equal, not a fallback' "$ARM" \
    && ok "arm presents 'different empty folder' as an EQUAL option" \
    || bad "arm does not present the different-folder option as an equal peer"

  # (d) git working tree is never cleared
  grep -q 'is-inside-work-tree' "$ARM" \
    && ok "arm checks git rev-parse --is-inside-work-tree and refuses to clear a repo" \
    || bad "arm does not gate the clear-offer on a git-working-tree check"

  # (e) deletion is bounded to the cwd's contents
  grep -q 'nothing above it' "$ARM" \
    && ok "arm bounds deletion to the cwd's contents (no .., no ~, no paths above)" \
    || bad "arm does not bound the deletion to the cwd's own contents"

  # (f) NEGATIVE: the arm must never INSTRUCT passing --force to the scaffolder.
  #     Every --force mention in the arm is legitimately PROHIBITIVE ("do not reach for
  #     `--force`", "Never `--force`", "Do not pass `--force` ... under any circumstances").
  #     So a naive '(pass|use|run).*--force' pattern false-positives on the prohibition
  #     itself — it fired on "Do not pass `--force`" on the first run of this pin. The
  #     assertion must therefore count only mentions NOT preceded by a negator, i.e. strip
  #     the prohibitive lines first and require nothing to remain.
  #     Anchor note: markdown emphasis sits *between* the negator and the flag
  #     ("**do not** reach for `--force`"), so a `[^.]{0,60}` bridge is unreliable — strip
  #     `*` and backticks first, then match on plain words.
  #
  #     DESIGN NOTE — this pin was INERT through FOUR successive designs before the shipped
  #     one; all four are recorded because the failure modes are instructive and mutation
  #     testing is the only thing that exposed them:
  #       1. COUNT-EQUALITY: compare total `--force` lines against prohibitive ones and
  #          assert equality. Unfalsifiable by the very mutation it must catch — rewriting
  #          "Do not pass --force" to "Pass --force" decrements BOTH counters, so equality
  #          held and the pin stayed green while the arm instructed what it forbids. Two
  #          numbers that move together cannot express "none of these is an instruction."
  #       2. PER-LINE NEGATOR FILTER: drop lines carrying a negator, require zero remaining.
  #          Also inert, because the granularity is wrong: the prose line reads
  #          "4. **Never `--force`, never auto-delete...** Do not pass `--force` to ..." —
  #          negator and instruction SHARE a line, so mutating the second clause leaves the
  #          line's first "Never" intact and `grep -v` still discards it.
  #       3. CLAUSE-GRANULARITY NEGATOR FILTER: caught the primary mutation but stayed inert
  #          on same-clause rewrites — an adjacent negator in the SAME clause ("...and do not
  #          silently fall back...", "...never auto-delete...") keeps satisfying the filter.
  #       4. PRESENCE-OF-EACH-PROHIBITION + IMPERATIVE-PROBE: also partly inert, because the
  #          presence anchors are themselves fuzzy against markdown (backticks sit between
  #          "Never" and "--force", so a bridging `.{0,3}` re-matches mutated text).
  #
  #     CONCLUSION after five mutation-verified iterations: **"no non-prohibitive mention of X
  #     anywhere in prose" is not reliably expressible as a grep.** The repo convention is
  #     explicit that when an anchor needs this many attempts the ANCHOR is wrong, not the
  #     regex — so rather than ship a pin that LOOKS like it guards the --force prohibition
  #     while being inert to the rewrites that matter (precisely the fail-open trap
  #     CLAUDE.md:259 is about), this pin asserts only what genuinely fails closed:
  #     the single most load-bearing prohibition is PRESENT, by an exact-literal anchor.
  #
  #     WHAT IS DELIBERATELY *NOT* PINNED HERE, and where it is covered instead: whether the
  #     surrounding prose still *reads* as prohibitive rather than permissive. That is prose
  #     semantics, and the documented gate for it is the verify-self coherence read (a fresh
  #     subagent judging "would a cold agent pass --force after reading this?"), not a grep.
  #     Recorded so nobody mistakes this pin's scope for more than it is.
  if grep -qF 'Do not pass `--force`' "$ARM"; then
    ok "arm carries the exact --force prohibition (exact-literal anchor, fails closed)"
  else
    bad "arm no longer says 'Do not pass \`--force\`' — the refusal is the safety property, not an obstacle; if the wording changed deliberately, update this anchor"
  fi

  # (g) the temp-dir prohibition is PRESENT, by an exact-literal anchor.
  #     Same lesson as (f): the first version of this assertion was an OR of two fuzzy
  #     counts ("mentions a temp fallback" OR "prohibits one"), which is inert by
  #     construction — an OR passes whenever either arm holds, so removing the prohibition
  #     while leaving the mention still satisfied it. Mutation testing caught that. Asserting
  #     PRESENCE of the exact prohibition is what fails closed; judging whether the prose
  #     still *reads* as prohibitive belongs to the verify-self coherence read.
  if grep -qF 'never a temp dir' "$ARM"; then
    ok "arm carries the exact temp-dir prohibition (exact-literal anchor, fails closed)"
  else
    bad "arm no longer prohibits a silent temp-dir fallback ('never a temp dir') — that fallback breaks the state-is-a-real-file-you-own beat; if the wording changed deliberately, update this anchor"
  fi

  # (h) decline is non-destructive, including on ambiguity
  grep -q 'nothing is touched' "$ARM" \
    && ok "arm guarantees nothing is touched on decline or ambiguity" \
    || bad "arm does not guarantee the directory is untouched when the user declines"

  # (i) ORDERING: the git pre-check must appear BEFORE the two-option offer script.
  #     Presence alone (assertion d) is NOT enough, and this is not hypothetical — the
  #     first cut of this phase stated the rule correctly but placed it ~20 lines AFTER the
  #     copy-paste offer, so an agent pattern-matching the script could offer to delete a
  #     git repository and retract it afterwards. Every grep passed; only a coherence read
  #     caught it. This pin makes the ordering itself mechanical: compare line numbers.
  git_ln=$(grep -n 'is-inside-work-tree' "$ARM" | head -1 | cut -d: -f1)
  offer_ln=$(grep -n 'Two ways forward' "$ARM" | head -1 | cut -d: -f1)
  if [ -n "$git_ln" ] && [ -n "$offer_ln" ] && [ "$git_ln" -lt "$offer_ln" ]; then
    ok "git pre-check (line $git_ln) precedes the clear-offer script (line $offer_ln)"
  else
    bad "git pre-check must PRECEDE the offer script (git=${git_ln:-missing}, offer=${offer_ln:-missing}) — otherwise an agent can offer to delete a repo and retract it"
  fi
fi

# ── 11. Scaffolder refusal MESSAGE text (WP7o) ─────────────────────────────────
# Groups 6 and 9 pin refusal BEHAVIOUR (exit 1, tree identical); neither pins the
# message TEXT, and that gap was demonstrated empirically at this phase's codify gate:
# reverting the stderr back to its pre-WP7o wording — "(use --force to overwrite)", which
# actively advertised the flag the arm forbids — left the suite at 28/28 green. The wording
# is a real consuming-surface contract (the arm's offer tells the user "nothing was
# written"), so a silent revert would make the arm's copy a lie. Driven through a REAL
# refusal invocation on the actual `--dest .` path, not a grep of the script source.
echo "[11] scaffolder refusal message text"
M="$(mktemp -d)"; TMPDIRS+=("$M")
echo sentinel > "$M/keep.txt"
err11="$( (cd "$M" && "$SCAFFOLD" --dest . ) 2>&1 >/dev/null || true )"
case "$err11" in
  *"nothing was written"*)
    ok "refusal states 'nothing was written' (the safety property the arm's copy promises)" ;;
  *)
    bad "refusal message no longer states 'nothing was written' — the arm's offer copy depends on it; got: [$err11]" ;;
esac
case "$err11" in
  *"must never pass it"*)
    ok "refusal message binds --force ('the tour must never pass it'), not advertises it" ;;
  *)
    bad "refusal message no longer binds --force — the pre-WP7o text said '(use --force to overwrite)', which recommends the exact flag the arm forbids; got: [$err11]" ;;
esac

echo
echo "== results: $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
