#!/usr/bin/env bash
# run-tests.sh — smoke test for the onboarding sample + scaffolder (WP7c).
#
# Codifies the Phase-1 Observable Outcomes:
#   1. sample greet.sh prints exactly "Hello, World!" (the verify-self grounding target)
#   2. planted tangent is real + authentic (no-arg -> "Hello, !"; README carries a TODO)
#   3. scaffolder produces a fresh runnable copy, independent of the source
#   4. scaffolder refuses to clobber a non-empty dest (writes nothing) unless --force
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

echo "== onboarding-scaffold smoke test =="

# ── 1. Sample runnable — exact observable outcome ────────────────────────────
echo "[1] sample greet.sh happy path"
out="$("$SAMPLE/greet.sh" World)"; rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = "Hello, World!" ]; then
  ok "greet.sh World -> exit 0, stdout exactly 'Hello, World!'"
else
  bad "greet.sh World: rc=$rc stdout=[$out] (expected exit 0 / 'Hello, World!')"
fi

# ── 2. Planted tangent is real + authentic ───────────────────────────────────
echo "[2] planted tangent"
noarg="$("$SAMPLE/greet.sh")"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s' "$noarg" | grep -q 'Hello, !'; then
  ok "greet.sh (no arg) -> exit 0, stdout contains ungrammatical 'Hello, !'"
else
  bad "greet.sh (no arg): rc=$rc stdout=[$noarg] (expected exit 0 containing 'Hello, !')"
fi
if grep -q 'TODO' "$SAMPLE/README.md"; then
  ok "sample README documents the tangent (contains TODO)"
else
  bad "sample README has no TODO documenting the tangent"
fi

# ── 3. Scaffolder produces a fresh, independent, runnable copy ────────────────
echo "[3] scaffolder fresh copy + independence"
D="$(mktemp -d)"; TMPDIRS+=("$D")
if "$SCAFFOLD" --dest "$D/s" >/dev/null 2>&1; then
  copyout="$("$D/s/greet.sh" World 2>/dev/null)"; rc=$?
  if [ "$rc" -eq 0 ] && [ "$copyout" = "Hello, World!" ]; then
    ok "scaffolded copy runs: greet.sh World -> 'Hello, World!'"
  else
    bad "scaffolded copy: rc=$rc stdout=[$copyout]"
  fi
  # independence: mutate the copy, source must be untouched
  marker="INDEPENDENCE_MARKER_$$"
  echo "# $marker" >> "$D/s/greet.sh"
  if grep -q "$marker" "$SAMPLE/greet.sh"; then
    bad "editing the copy leaked into the source greet.sh"
  else
    ok "editing the copy does NOT touch the source (independent)"
  fi
else
  bad "scaffolder failed to produce a copy at $D/s"
fi

# ── 4. Scaffolder refuses to clobber a non-empty dest (no --force) ────────────
echo "[4] no-clobber guard"
NE="$(mktemp -d)"; TMPDIRS+=("$NE")
echo "keep" > "$NE/keep.txt"
if "$SCAFFOLD" --dest "$NE" >/dev/null 2>&1; then
  bad "scaffolder overwrote a non-empty dir without --force (should have refused)"
else
  # must have written nothing: only keep.txt remains, no greet.sh
  if [ -e "$NE/greet.sh" ]; then
    bad "scaffolder refused (exit non-zero) but still wrote files into the non-empty dir"
  else
    ok "scaffolder refused non-empty dest and wrote nothing"
  fi
fi
# and --force DOES overwrite + stays runnable
if "$SCAFFOLD" --dest "$NE" --force >/dev/null 2>&1 && [ "$("$NE/greet.sh" World 2>/dev/null)" = "Hello, World!" ]; then
  ok "scaffolder --force overwrites and the result is runnable"
else
  bad "scaffolder --force did not overwrite/run correctly"
fi

# ── 5. Wiring contract: the greenfield arm references this scaffold (WP7c Phase 2) ──
# Anti-regression guard against the arm and the scaffold drifting apart (e.g. a future
# scaffold rename silently orphaning the arm's drop-in reference). This pins the
# consuming-surface wiring only; the tour's behavioral scenarios + structural pins are
# WP7e's job — deliberately NOT duplicated here.
echo "[5] greenfield arm ↔ scaffold wiring"
ARM="$TOOL_DIR/../../skills/tutorial-greenfield-workflow-tour/SKILL.md"
if [ -f "$ARM" ]; then
  grep -q 'tools/onboarding-scaffold' "$ARM" \
    && ok "arm SKILL.md references the scaffold path (tools/onboarding-scaffold)" \
    || bad "arm SKILL.md no longer references tools/onboarding-scaffold (wiring drifted)"
  grep -q 'Hello, World!' "$ARM" \
    && ok "arm SKILL.md cites the runnable observable (Hello, World!)" \
    || bad "arm SKILL.md no longer cites the Hello, World! observable"
  grep -q 'Hello, !' "$ARM" \
    && ok "arm SKILL.md cites the planted tangent (Hello, !)" \
    || bad "arm SKILL.md no longer cites the Hello, ! tangent"
else
  echo "  SKIP: arm SKILL.md not found at expected path ($ARM) — wiring check skipped"
fi

echo
echo "== results: $pass passed, $fail failed =="
[ "$fail" -eq 0 ]
