#!/usr/bin/env bash
# run-tests.sh — end-to-end tests for the memory-link primitive.
#
# Runs the ACTUAL ensure-memory-link.sh / migrate-memory.sh scripts against throwaway
# projects under a temp dir and asserts real filesystem state (symlink targets, exit
# codes, drift handling, backups, MEMORY.md rebuild). This is the highest-level test:
# it exercises the scripts the same way the workflow will, from the outside.
#
# Isolation: each test uses its own temp project. Because the harness slug is derived
# from the realpath, the test creates real ~/.claude/projects/<slug> dirs — every test
# cleans up the specific slug dir it created (tracked in CREATED_HARNESS) in a trap.
# The test NEVER touches any pre-existing harness dir.
#
# Usage: tools/memory-link/test/run-tests.sh
# Exit 0 = all pass; non-zero = at least one failure.
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLS_DIR="$(dirname "$TEST_DIR")"
. "$TOOLS_DIR/lib-slug.sh"

PASS=0; FAIL=0
declare -a CREATED_HARNESS=()
declare -a TMP_ROOTS=()

cleanup() {
  local h
  for h in "${CREATED_HARNESS[@]:-}"; do [ -n "$h" ] && rm -rf "$h"; done
  local t
  for t in "${TMP_ROOTS[@]:-}"; do [ -n "$t" ] && rm -rf "$t"; done
}
trap cleanup EXIT

check() {
  local desc="$1" cond="$2"
  if eval "$cond"; then echo "  [PASS] $desc"; PASS=$((PASS+1))
  else echo "  [FAIL] $desc"; FAIL=$((FAIL+1)); fi
}

# Make a fresh throwaway project. Sets globals P (project path) and HARNESS (its harness
# memory path), and registers the harness slug dir + temp root for cleanup. NOT called via
# command substitution — it mutates parent-shell globals directly (a $(...) subshell would
# lose them under `set -u`).
new_proj() {
  local root; root="$(mktemp -d "${TMPDIR:-/tmp}/mlink-test.XXXXXX")"
  TMP_ROOTS+=("$root")
  P="$root/proj"; mkdir -p "$P"
  HARNESS="$(mlink_harness_memory_path "$P")"
  CREATED_HARNESS+=("$(dirname "$HARNESS")")
}

echo "=== memory-link end-to-end tests ==="

# --- Test group 1: ensure-memory-link fresh + idempotent ---
new_proj
"$TOOLS_DIR/ensure-memory-link.sh" "$P" >/dev/null 2>&1; RC=$?
check "fresh ensure-link exits 0" "[ $RC -eq 0 ]"
check "fresh ensure-link creates a symlink" "[ -L '$HARNESS' ]"
check "symlink target is the repo memory dir" \
  "[ \"\$(cd \"\$(readlink '$HARNESS')\" && pwd -P)\" = \"\$(cd '$P/.claude/memory' && pwd -P)\" ]"
OUT="$("$TOOLS_DIR/ensure-memory-link.sh" "$P" 2>&1)"
check "idempotent re-run prints 'already linked'" "printf '%s' \"\$OUT\" | grep -q '^OK: already linked'"

# --- Test group 2: realpath slug (footgun regression guard) ---
# The slug must be derived from the physical path. On macOS TMPDIR often lives under
# /var/folders -> /private/var/folders; on Linux /tmp is real. Assert the slug matches
# realpath, NOT the possibly-symlinked raw path.
new_proj
RAW="$P"
REAL="$(cd "$P" && pwd -P)"
SLUG_FROM_REAL="$(printf '%s' "$REAL" | sed 's/[/.]/-/g')"
SLUG_ACTUAL="$(mlink_slug "$P")"
check "mlink_slug uses realpath (matches pwd -P derivation)" "[ '$SLUG_ACTUAL' = '$SLUG_FROM_REAL' ]"
if [ "$RAW" != "$REAL" ]; then
  SLUG_FROM_RAW="$(printf '%s' "$RAW" | sed 's/[/.]/-/g')"
  check "mlink_slug does NOT use the raw (symlinked) path" "[ '$SLUG_ACTUAL' != '$SLUG_FROM_RAW' ]"
else
  echo "  [SKIP] raw path == realpath here (no symlink to differentiate); realpath assertion above still holds"
fi

# --- Test group 3: migration merge + drift + backup + MEMORY.md rebuild ---
new_proj
mkdir -p "$P/.claude/memory"
mkdir -p "$HARNESS"   # a REAL harness dir (not symlink) to migrate from
# repo-side: unique + one that will drift
printf -- '---\ndescription: repo only\n---\nREPO body\n' > "$P/.claude/memory/repo-only.md"
printf -- '---\ndescription: shared repo version\n---\nREPO shared\n' > "$P/.claude/memory/shared.md"
# harness-side: unique + drift (same name diff content) + identical dup
printf -- '---\ndescription: harness only\n---\nHARNESS body\n' > "$HARNESS/harness-only.md"
printf -- '---\ndescription: shared harness version\n---\nHARNESS shared\n' > "$HARNESS/shared.md"
cp "$P/.claude/memory/repo-only.md" "$HARNESS/repo-only.md"   # identical dup
MOUT="$("$TOOLS_DIR/migrate-memory.sh" "$P" --date 2026-07-03 2>&1)"; MRC=$?
check "migration exits 0" "[ $MRC -eq 0 ]"
check "harness-only.md merged into repo" "[ -f '$P/.claude/memory/harness-only.md' ]"
check "repo shared.md preserved (not clobbered)" "grep -q 'REPO shared' '$P/.claude/memory/shared.md'"
check "drift kept as shared.harness.md" "grep -q 'HARNESS shared' '$P/.claude/memory/shared.harness.md'"
check "migration printed DRIFT line for shared.md" "printf '%s' \"\$MOUT\" | grep -q '^DRIFT: shared.md'"
check "identical dup dropped (printed DUP)" "printf '%s' \"\$MOUT\" | grep -q '^DUP: repo-only.md'"
check "no drift file for identical dup" "[ ! -f '$P/.claude/memory/repo-only.harness.md' ]"
check "timestamped backup dir exists" "[ -d '$P/.claude/memory/.migration-backup-2026-07-03' ]"
check "backup contains harness originals" "[ -f '$P/.claude/memory/.migration-backup-2026-07-03/harness-only.md' ]"
check "MEMORY.md rebuilt with merged entry" "grep -q 'harness-only.md' '$P/.claude/memory/MEMORY.md'"
check "MEMORY.md excludes itself from index" "! grep -q '\[MEMORY.md\]' '$P/.claude/memory/MEMORY.md'"
check "harness path is now a symlink" "[ -L '$HARNESS' ]"

# --- Test group 3b: MEMORY.md is index, not a memory (regression guard) ---
# A pre-existing repo MEMORY.md + a harness MEMORY.md must NOT produce a MEMORY.harness.md
# drift file, and MEMORY.harness.md must never appear in the rebuilt index.
new_proj
mkdir -p "$P/.claude/memory"
mkdir -p "$HARNESS"
printf -- '# Memory Index\n\n- [x.md](x.md) — hand-curated hook\n' > "$P/.claude/memory/MEMORY.md"
printf -- '---\ndescription: x\n---\nX\n' > "$P/.claude/memory/x.md"
printf -- '# Memory Index\n\n- [y.md](y.md) — harness index line\n' > "$HARNESS/MEMORY.md"
printf -- '---\ndescription: y\n---\nY\n' > "$HARNESS/y.md"
IOUT="$("$TOOLS_DIR/migrate-memory.sh" "$P" --date 2026-07-03 2>&1)"
check "MEMORY.md skipped as index (printed INDEX line)" "printf '%s' \"\$IOUT\" | grep -q '^INDEX: MEMORY.md'"
check "no MEMORY.harness.md drift file created" "[ ! -f '$P/.claude/memory/MEMORY.harness.md' ]"
check "rebuilt index does NOT list MEMORY.harness.md" "! grep -q 'MEMORY.harness.md' '$P/.claude/memory/MEMORY.md'"
check "harness memory y.md still merged in" "[ -f '$P/.claude/memory/y.md' ]"
check "backup still contains harness MEMORY.md" "[ -f '$P/.claude/memory/.migration-backup-2026-07-03/MEMORY.md' ]"

# --- Test group 4: migration idempotency ---
MOUT2="$("$TOOLS_DIR/migrate-memory.sh" "$P" --date 2026-07-03 2>&1)"
check "re-migration is a no-op (already a symlink)" "printf '%s' \"\$MOUT2\" | grep -q 'already a symlink'"

# --- Test group 5: NEEDS-MIGRATION exit 3 ---
new_proj
mkdir -p "$HARNESS"
echo 'x' > "$HARNESS/existing.md"   # non-empty real harness dir
"$TOOLS_DIR/ensure-memory-link.sh" "$P" >/dev/null 2>&1; NRC=$?
check "ensure-link on non-empty real harness dir exits 3 (NEEDS-MIGRATION)" "[ $NRC -eq 3 ]"
check "ensure-link did NOT clobber the real dir into a symlink" "[ ! -L '$HARNESS' ] && [ -d '$HARNESS' ]"

# --- Test group 6: dry-run makes no changes ---
new_proj
"$TOOLS_DIR/ensure-memory-link.sh" "$P" --dry-run >/dev/null 2>&1
check "dry-run creates no symlink" "[ ! -e '$HARNESS' ]"

echo ""
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
