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
#   8. greenfield arm references this scaffold (arm ↔ scaffold wiring contract)
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
else
  echo "  SKIP: arm SKILL.md not found at expected path ($ARM) — wiring check skipped"
fi

echo
echo "== results: $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
