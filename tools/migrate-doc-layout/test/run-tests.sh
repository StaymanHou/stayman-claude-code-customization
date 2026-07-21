#!/usr/bin/env bash
# run-tests.sh — end-to-end tests for the migrate-doc-layout primitive.
#
# Runs the ACTUAL migrate-doc-layout.sh against throwaway projects under a temp dir and
# asserts real filesystem state (dirs moved, old dirs gone, backup present, drift kept
# both ways, idempotent no-op, git history preserved via git mv). Highest-level test:
# exercises the script the same way the migration run will, from the outside.
#
# Isolation: each test uses its own mktemp project root; a trap cleans them all up.
# The --date flag is always passed so backup-dir names are deterministic.
#
# Usage: tools/migrate-doc-layout/test/run-tests.sh
# Exit 0 = all pass; non-zero = at least one failure.
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOL_DIR="$(dirname "$TEST_DIR")"
SCRIPT="$TOOL_DIR/migrate-doc-layout.sh"
DATE="2026-07-21"

PASS=0; FAIL=0
declare -a TMP_ROOTS=()

cleanup() { local t; for t in "${TMP_ROOTS[@]:-}"; do [ -n "$t" ] && rm -rf "$t"; done; }
trap cleanup EXIT

check() {
  local desc="$1" cond="$2"
  if eval "$cond"; then echo "  [PASS] $desc"; PASS=$((PASS+1))
  else echo "  [FAIL] $desc"; FAIL=$((FAIL+1)); fi
}

# new_proj [--git] — make a throwaway project with the OLD split layout populated.
# Sets global P (project path). Optionally inits a git repo and commits the layout.
new_proj() {
  local want_git=0
  [ "${1:-}" = "--git" ] && want_git=1
  local root; root="$(mktemp -d "${TMPDIR:-/tmp}/migdoc-test.XXXXXX")"
  TMP_ROOTS+=("$root")
  P="$root/proj"; mkdir -p "$P"
  mkdir -p "$P/docs/product/archive" "$P/workflow/wip" "$P/workflow/archive"
  printf 'vision body\n'  > "$P/docs/product/vision.md"
  printf 'arch body\n'    > "$P/docs/product/arch.md"
  printf 'old wbs\n'      > "$P/docs/product/archive/wbs.md"
  printf 'backlog body\n' > "$P/workflow/backlog.md"
  printf 'wip body\n'     > "$P/workflow/wip/feature-x.md"
  printf 'session\n'      > "$P/workflow/.session.md"
  if [ "$want_git" -eq 1 ]; then
    ( cd "$P" && git init -q && git add -A && \
      git -c user.name=t -c user.email=t@t commit -q -m "baseline old layout" )
  fi
}

echo "=== migrate-doc-layout end-to-end tests ==="

# --- Test group 1: dry-run changes nothing ---
new_proj
"$SCRIPT" "$P" --date "$DATE" --dry-run >/dev/null 2>&1; RC=$?
check "dry-run exits 0" "[ $RC -eq 0 ]"
check "dry-run does NOT create workflow-system/" "[ ! -e '$P/workflow-system' ]"
check "dry-run leaves old docs/product intact" "[ -f '$P/docs/product/vision.md' ]"
check "dry-run leaves old workflow/ intact" "[ -f '$P/workflow/backlog.md' ]"

# --- Test group 2: real migration (non-git) moves everything ---
new_proj
MOUT="$("$SCRIPT" "$P" --date "$DATE" 2>&1)"; RC=$?
check "migration exits 0" "[ $RC -eq 0 ]"
check "workflow-system/product/vision.md exists" "[ -f '$P/workflow-system/product/vision.md' ]"
check "workflow-system/product/arch.md exists" "[ -f '$P/workflow-system/product/arch.md' ]"
check "nested archive preserved (product/archive/wbs.md)" "[ -f '$P/workflow-system/product/archive/wbs.md' ]"
check "workflow-system/state/backlog.md exists" "[ -f '$P/workflow-system/state/backlog.md' ]"
check "workflow-system/state/wip/feature-x.md exists" "[ -f '$P/workflow-system/state/wip/feature-x.md' ]"
check "dotfile .session.md moved to state/" "[ -f '$P/workflow-system/state/.session.md' ]"
check "old docs/product/ removed" "[ ! -d '$P/docs/product' ]"
check "old workflow/ removed" "[ ! -d '$P/workflow' ]"
# The reversible backup lives OUTSIDE the repo (SURFACE-2026-07-21 fix), keyed by a
# slugged project path + date — mirror the script's derivation to locate it.
G2SLUG="$(printf '%s' "$(cd "$P" && pwd -P)" | sed 's/[/.]/-/g')"
G2BACKUP="${TMPDIR:-/tmp}/migrate-doc-layout-backup${G2SLUG}-$DATE"
TMP_ROOTS+=("$G2BACKUP")
check "timestamped backup dir exists (outside the repo)" "[ -d \"\$G2BACKUP\" ]"
check "backup contains the old docs/product tree" "[ -f \"\$G2BACKUP/product/vision.md\" ]"
check "backup contains the old workflow tree" "[ -f \"\$G2BACKUP/workflow/backlog.md\" ]"
check "backup is NOT inside the project (regression guard)" "[ ! -d '$P/workflow-system/.migration-backup-$DATE' ]"
check "printed MOVED for docs/product" "printf '%s' \"\$MOUT\" | grep -q 'MOVED: docs/product'"
check "printed MOVED for workflow" "printf '%s' \"\$MOUT\" | grep -q 'MOVED: workflow'"

# --- Test group 3: idempotency (re-run is a no-op) ---
MOUT2="$("$SCRIPT" "$P" --date "$DATE" 2>&1)"; RC=$?
check "re-migration exits 0" "[ $RC -eq 0 ]"
check "re-migration is a no-op (nothing to do)" "printf '%s' \"\$MOUT2\" | grep -q 'nothing to do'"
check "re-migration did not create a nested workflow-system" "[ ! -e '$P/workflow-system/workflow-system' ]"

# --- Test group 4: drift-keep-both (never clobber) ---
new_proj
# Pre-create a DESTINATION file that DIFFERS from what the source will move in.
mkdir -p "$P/workflow-system/product"
printf 'DESTINATION arch (pre-existing, different)\n' > "$P/workflow-system/product/arch.md"
DOUT="$("$SCRIPT" "$P" --date "$DATE" 2>&1)"; RC=$?
check "migration-with-drift exits 0" "[ $RC -eq 0 ]"
check "destination arch.md preserved (not clobbered)" "grep -q 'DESTINATION arch' '$P/workflow-system/product/arch.md'"
check "source arch.md kept as .pre-migrate sidecar" "[ -f '$P/workflow-system/product/arch.md.pre-migrate' ]"
check "sidecar carries the source content" "grep -q 'arch body' '$P/workflow-system/product/arch.md.pre-migrate'"
check "printed DRIFT line for arch.md" "printf '%s' \"\$DOUT\" | grep -q '^DRIFT: product/arch.md'"

# --- Test group 4b: identical destination file is dropped (DUP), not sidecar'd ---
new_proj
mkdir -p "$P/workflow-system/product"
cp "$P/docs/product/vision.md" "$P/workflow-system/product/vision.md"  # identical
UOUT="$("$SCRIPT" "$P" --date "$DATE" 2>&1)"
check "identical destination -> printed DUP" "printf '%s' \"\$UOUT\" | grep -q '^DUP: docs/product/vision.md'"
check "no sidecar created for identical dup" "[ ! -f '$P/workflow-system/product/vision.md.pre-migrate' ]"

# --- Test group 5: git history preserved via git mv ---
new_proj --git
"$SCRIPT" "$P" --date "$DATE" >/dev/null 2>&1; RC=$?
check "git-project migration exits 0" "[ $RC -eq 0 ]"
check "git sees the move as renames (staged R)" \
  "[ \"\$(git -C '$P' status --short | grep -c '^R')\" -ge 1 ]"
check "no delete+add of moved content in git" \
  "[ \"\$(git -C '$P' status --short | grep -cE '^(D|A) ')\" -eq 0 ]"
# Regression guard for SURFACE-2026-07-21-QUALITY-BACKUP-INSIDE-REPO-STAGED:
# the reversible backup MUST live outside the repo, so (a) no .migration-backup-* dir
# appears anywhere under the project, and (b) `git status` shows nothing referencing it
# (staging the backup into the migration commit was the claudesk mid-run footgun).
check "backup dir is NOT created inside the project" \
  "[ -z \"\$(find '$P' -name '.migration-backup-*' -not -path '*/.git/*' 2>/dev/null)\" ]"
check "git status shows no migration-backup artifact (backup lives outside the repo)" \
  "[ \"\$(git -C '$P' status --short | grep -c 'migration-backup')\" -eq 0 ]"
# The external backup DOES exist (reversibility preserved) — just not inside the repo.
BSLUG="$(printf '%s' "$(cd "$P" && pwd -P)" | sed 's/[/.]/-/g')"
EXTBACKUP="${TMPDIR:-/tmp}/migrate-doc-layout-backup${BSLUG}-$DATE"
TMP_ROOTS+=("$EXTBACKUP")
check "external backup exists (reversibility preserved, outside the repo)" \
  "[ -d \"\$EXTBACKUP\" ] && [ -f \"\$EXTBACKUP/product/arch.md\" ]"
# commit so --follow can trace history across the rename
( cd "$P" && git add -A && git -c user.name=t -c user.email=t@t commit -q -m "migrate layout" )
check "git history follows arch.md across the rename" \
  "[ \"\$(git -C '$P' log --follow --oneline workflow-system/product/arch.md | wc -l | tr -d ' ')\" -ge 2 ]"
# After commit, the tree is clean — the backup never entered git (the actual defect).
check "working tree clean after migration commit (backup never staged)" \
  "[ \"\$(git -C '$P' status --porcelain | wc -l | tr -d ' ')\" -eq 0 ]"

# --- Test group 5b: --help / -h prints usage and exits 0 (SURFACE-2026-07-21-QUALITY-HELP-FLAG-UNIMPLEMENTED) ---
HOUT="$("$SCRIPT" --help 2>&1)"; RC=$?
check "--help exits 0" "[ $RC -eq 0 ]"
check "--help documents <proj-dir>, --dry-run, --date" \
  "printf '%s' \"\$HOUT\" | grep -q -- '--dry-run' && printf '%s' \"\$HOUT\" | grep -q -- '--date' && printf '%s' \"\$HOUT\" | grep -q 'proj-dir'"
check "-h short form also exits 0" "\"$SCRIPT\" -h >/dev/null 2>&1"
check "--help does NOT migrate (no project touched)" \
  "printf '%s' \"\$HOUT\" | grep -qv '^MOVED:'"

# --- Test group 6: missing project dir -> exit 2 ---
"$SCRIPT" "/no/such/project/dir/xyz" --date "$DATE" >/dev/null 2>&1; RC=$?
check "missing project dir exits 2" "[ $RC -eq 2 ]"

# --- Test group 7: project with no old-layout dirs -> clean no-op exit 0 ---
EMPTY="$(mktemp -d "${TMPDIR:-/tmp}/migdoc-empty.XXXXXX")"; TMP_ROOTS+=("$EMPTY")
NOUT="$("$SCRIPT" "$EMPTY" --date "$DATE" 2>&1)"; RC=$?
check "no-old-dirs project exits 0" "[ $RC -eq 0 ]"
check "no-old-dirs project reports nothing to do" "printf '%s' \"\$NOUT\" | grep -q 'nothing to do'"

echo ""
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
