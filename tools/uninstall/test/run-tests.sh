#!/usr/bin/env bash
# run-tests.sh — end-to-end tests for the standalone uninstall.sh.
#
# Runs the ACTUAL install.sh + uninstall.sh against throwaway fake-$HOME sandboxes
# and asserts real filesystem state: into-repo symlinks removed, foreign links and
# real files preserved (the into-repo guard), the CLAUDE.md marker block excised
# (with a .bak backup) while non-block content survives, the per-project memory
# SYMLINK removed while the real store is left intact, print-only settings.json, and
# the install -> uninstall -> re-install round-trip (WP4.5, the AD-2 target).
#
# ⚠️ SAFETY (SURFACE-2026-07-21-UNINSTALL-TEST-HOME-EXPORT-HAZARD): uninstall.sh
# removes things under $HOME/.claude. This harness therefore NEVER exports HOME at
# the top level — every install/uninstall invocation runs via `env HOME="$SBHOME"`
# so a leak cannot reach the real home dir. A dedicated assertion confirms the outer
# $HOME is unchanged after the run.
#
# Isolation: each test uses its own mktemp sandbox; a trap cleans them all up.
#
# Usage: tools/uninstall/test/run-tests.sh
# Exit 0 = all pass; non-zero = at least one failure.
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$TEST_DIR/../../.." && pwd -P)"
INSTALL="$REPO_ROOT/install.sh"
UNINSTALL="$REPO_ROOT/uninstall.sh"
OUTER_HOME="$HOME"   # captured to assert it never changes

PASS=0; FAIL=0
declare -a TMP_ROOTS=()

cleanup() { local t; for t in "${TMP_ROOTS[@]:-}"; do [ -n "$t" ] && rm -rf "$t"; done; }
trap cleanup EXIT

check() {
  local desc="$1" cond="$2"
  if eval "$cond"; then echo "  [PASS] $desc"; PASS=$((PASS+1))
  else echo "  [FAIL] $desc"; FAIL=$((FAIL+1)); fi
}

# new_sandbox — make a throwaway sandbox with a fake $HOME and (optionally) a fake
# project carrying a real memory store + harness memory symlink. Sets globals:
#   SB      = sandbox root
#   SBHOME  = fake home (pass as `env HOME="$SBHOME"` to install/uninstall)
#   PROJ    = fake project dir (with .claude/memory real store)
#   HMEM    = harness memory symlink path (~/.claude/projects/<slug>/memory)
new_sandbox() {
  SB="$(mktemp -d "${TMPDIR:-/tmp}/uninstall-test.XXXXXX")"
  TMP_ROOTS+=("$SB")
  SBHOME="$SB/home"; mkdir -p "$SBHOME/.claude"
  PROJ="$SB/proj"; mkdir -p "$PROJ/.claude/memory"
  printf 'a memory fact\n' > "$PROJ/.claude/memory/fact.md"
  # Slug exactly as tools/memory-link/lib-slug.sh derives it: realpath + s|[/.]|-|g.
  local realproj; realproj="$(cd "$PROJ" && pwd -P)"
  local slug; slug="$(printf '%s' "$realproj" | sed 's/[/.]/-/g')"
  HMEM="$SBHOME/.claude/projects/$slug/memory"
  mkdir -p "$(dirname "$HMEM")"
}

echo "=== uninstall.sh end-to-end tests ==="

# --- Test group 0: --help / bash -n ---
check "uninstall.sh parses (bash -n)" "bash -n '$UNINSTALL'"
HOUT="$("$UNINSTALL" --help 2>&1)"; RC=$?
check "--help exits 0" "[ $RC -eq 0 ]"
check "--help documents --dry-run and --project" \
  "printf '%s' \"\$HOUT\" | grep -q -- '--dry-run' && printf '%s' \"\$HOUT\" | grep -q -- '--project'"
check "--help does NOT remove anything (no [remove] lines)" \
  "printf '%s' \"\$HOUT\" | grep -qv '\\[remove\\]'"
"$UNINSTALL" --bogus-flag >/dev/null 2>&1; RC=$?
check "unknown flag exits 2" "[ $RC -eq 2 ]"

# Arg-parser safety: a flag-shaped or missing --project value must be a usage error
# (exit 2), NEVER swallowed as the value. Guards against the destructive footgun where
# `--project --dry-run` would set PROJECT_DIR="--dry-run", leave DRY_RUN=0, and perform
# a REAL uninstall (the MAJOR finding from feature-review-quality, 2026-07-21). Runs in a
# real sandbox so that IF the guard regressed, the assertions would catch the [remove] lines.
new_sandbox
env HOME="$SBHOME" "$INSTALL" >/dev/null 2>&1
PPERM_OUT="$(env HOME="$SBHOME" "$UNINSTALL" --project --dry-run 2>&1)"; RC=$?
check "--project --dry-run exits 2 (flag-shaped value rejected)" "[ $RC -eq 2 ]"
check "--project --dry-run performed NO removals (no [remove] lines)" \
  "! printf '%s' \"\$PPERM_OUT\" | grep -q '\\[remove\\]'"
check "--project --dry-run left the live-ish sandbox install intact" \
  "[ \"\$(find '$SBHOME/.claude/skills' -maxdepth 1 -type l | wc -l | tr -d ' ')\" -gt 0 ]"
"$UNINSTALL" --project >/dev/null 2>&1; RC=$?
check "--project with no value exits 2 (not a silent exit 1)" "[ $RC -eq 2 ]"
PMISS_OUT="$("$UNINSTALL" --project 2>&1)"
check "--project with no value prints a clear diagnostic" \
  "printf '%s' \"\$PMISS_OUT\" | grep -qi 'requires a directory'"

# --- Test group 1: dry-run changes nothing ---
new_sandbox
env HOME="$SBHOME" "$INSTALL" >/dev/null 2>&1
POST_SK=$(find "$SBHOME/.claude/skills" -maxdepth 1 -type l | wc -l | tr -d ' ')
check "install created skill symlinks (>0)" "[ '$POST_SK' -gt 0 ]"
env HOME="$SBHOME" "$UNINSTALL" --dry-run >/dev/null 2>&1; RC=$?
DR_SK=$(find "$SBHOME/.claude/skills" -maxdepth 1 -type l | wc -l | tr -d ' ')
check "dry-run exits 0" "[ $RC -eq 0 ]"
check "dry-run removed NO skill symlinks" "[ '$DR_SK' -eq '$POST_SK' ]"
check "dry-run left the CLAUDE.md block intact" \
  "grep -qF 'BEGIN claude-workflow-system' '$SBHOME/.claude/CLAUDE.md'"

# --- Test group 2: real uninstall removes into-repo links + excises block ---
new_sandbox
# Seed personal (non-block) content to prove it survives the excise.
printf '# Personal notes\n\nKEEP-THIS-LINE\n' > "$SBHOME/.claude/CLAUDE.md"
env HOME="$SBHOME" "$INSTALL" >/dev/null 2>&1
# LEGACY claude-time links: tools/claude-time/ was retired 2026-07-29, so install.sh
# no longer creates these. uninstall.sh still removes them (to not strand
# pre-retirement installs), so the test must SEED them itself — otherwise the two
# assertions below would pass on paths that never existed, guarding nothing
# (the fails-OPEN-on-missing-file trap). Seeded as DANGLING into-repo links, which is
# exactly what a pre-retirement install becomes once the tool directory is deleted.
mkdir -p "$SBHOME/.claude/hooks" "$SBHOME/.claude/bin"
ln -s "$REPO_ROOT/tools/claude-time/hook.pl"     "$SBHOME/.claude/hooks/claude-time-hook.pl"
ln -s "$REPO_ROOT/tools/claude-time/claude-time" "$SBHOME/.claude/bin/claude-time"
# Fail-closed precondition: if the seeding above ever stops working, these FAIL loudly
# rather than letting the removal assertions go quietly vacuous.
check "seed precondition: legacy claude-time hook link exists pre-uninstall" \
  "[ -L '$SBHOME/.claude/hooks/claude-time-hook.pl' ]"
check "seed precondition: legacy claude-time bin link exists pre-uninstall" \
  "[ -L '$SBHOME/.claude/bin/claude-time' ]"
POST_AG=$(find "$SBHOME/.claude/agents" -maxdepth 1 -type l | wc -l | tr -d ' ')
env HOME="$SBHOME" "$UNINSTALL" >"$SB/u.out" 2>&1; RC=$?
AFTER_SK=$(find "$SBHOME/.claude/skills" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
AFTER_AG=$(find "$SBHOME/.claude/agents" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
check "uninstall exits 0" "[ $RC -eq 0 ]"
check "all skill symlinks removed" "[ '$AFTER_SK' -eq 0 ]"
check "all agent symlinks removed (had $POST_AG)" "[ '$AFTER_AG' -eq 0 ]"
check "CLAUDE.md workflow block excised" \
  "! grep -qF 'BEGIN claude-workflow-system' '$SBHOME/.claude/CLAUDE.md'"
check "non-block personal content survived" \
  "grep -qF 'KEEP-THIS-LINE' '$SBHOME/.claude/CLAUDE.md'"
check "CLAUDE.md .bak backup written" "[ -f '$SBHOME/.claude/CLAUDE.md.bak' ]"
check "legacy claude-time hook symlink removed (seeded dangling into-repo link)" \
  "[ ! -L '$SBHOME/.claude/hooks/claude-time-hook.pl' ]"
check "legacy claude-time bin symlink removed (seeded dangling into-repo link)" \
  "[ ! -L '$SBHOME/.claude/bin/claude-time' ]"

# --- Test group 3: into-repo guard — foreign link + real dir at REAL skill paths ---
new_sandbox
env HOME="$SBHOME" "$INSTALL" >/dev/null 2>&1
REAL1="$(basename "$(find "$REPO_ROOT/skills" -maxdepth 1 -mindepth 1 -type d | sort | sed -n '1p')")"
REAL2="$(basename "$(find "$REPO_ROOT/skills" -maxdepth 1 -mindepth 1 -type d | sort | sed -n '2p')")"
rm -f "$SBHOME/.claude/skills/$REAL1"; ln -s /etc/hosts "$SBHOME/.claude/skills/$REAL1"
rm -rf "$SBHOME/.claude/skills/$REAL2"; mkdir "$SBHOME/.claude/skills/$REAL2"
printf 'keep\n' > "$SBHOME/.claude/skills/$REAL2/keep.md"
env HOME="$SBHOME" "$UNINSTALL" >"$SB/g.out" 2>&1
check "foreign symlink (outside repo) at a real skill path is preserved" \
  "[ -L '$SBHOME/.claude/skills/$REAL1' ]"
check "foreign symlink reported [skip] (points outside this repo)" \
  "grep -q 'skills/$REAL1 (symlink points outside this repo' '$SB/g.out'"
check "real dir at a real skill path is preserved" \
  "[ -d '$SBHOME/.claude/skills/$REAL2' ] && [ -f '$SBHOME/.claude/skills/$REAL2/keep.md' ]"
check "real dir reported [skip] (not a symlink)" \
  "grep -q 'skills/$REAL2 (exists but is not a symlink' '$SB/g.out'"

# --- Test group 4: idempotency (re-run after clean uninstall = no-op) ---
new_sandbox
env HOME="$SBHOME" "$INSTALL" >/dev/null 2>&1
env HOME="$SBHOME" "$UNINSTALL" >/dev/null 2>&1
env HOME="$SBHOME" "$UNINSTALL" >"$SB/re.out" 2>&1; RC=$?
check "re-uninstall exits 0 (idempotent)" "[ $RC -eq 0 ]"
check "re-uninstall reports [ok] already-removed (no [remove])" \
  "grep -q '\\[ok\\]' '$SB/re.out' && ! grep -q '\\[remove\\]' '$SB/re.out'"

# --- Test group 5: per-project memory symlink (--project) ---
new_sandbox
ln -s "$PROJ/.claude/memory" "$HMEM"
# 5a: dry-run leaves the symlink.
env HOME="$SBHOME" "$UNINSTALL" --project "$PROJ" --dry-run >/dev/null 2>&1
check "memory dry-run leaves the symlink" "[ -L '$HMEM' ]"
# 5b: real run removes the symlink, keeps the real store.
env HOME="$SBHOME" "$UNINSTALL" --project "$PROJ" >"$SB/m.out" 2>&1; RC=$?
check "memory uninstall exits 0" "[ $RC -eq 0 ]"
check "memory symlink removed" "[ ! -L '$HMEM' ]"
check "real memory store + fact.md left intact" \
  "[ -f '$PROJ/.claude/memory/fact.md' ]"
# 5c: guard — harness path is a REAL dir => skip, untouched.
new_sandbox
mkdir -p "$HMEM"; printf 'r\n' > "$HMEM/real.md"
env HOME="$SBHOME" "$UNINSTALL" --project "$PROJ" >"$SB/m2.out" 2>&1
check "real-dir memory path preserved (not removed)" "[ -f '$HMEM/real.md' ]"
check "real-dir memory path reported [skip]" \
  "grep -qi 'real directory, not a symlink' '$SB/m2.out'"
# 5d: guard — symlink points ELSEWHERE => skip, preserved.
new_sandbox
ELSE="$SB/else"; mkdir -p "$ELSE"; ln -s "$ELSE" "$HMEM"
env HOME="$SBHOME" "$UNINSTALL" --project "$PROJ" >"$SB/m3.out" 2>&1
check "foreign-target memory symlink preserved" "[ -L '$HMEM' ]"
check "foreign-target memory symlink reported [skip] (not ours)" \
  "grep -qi 'not ours' '$SB/m3.out'"
# 5e: without --project, no memory handling at all.
new_sandbox
ln -s "$PROJ/.claude/memory" "$HMEM"
env HOME="$SBHOME" "$UNINSTALL" >"$SB/m4.out" 2>&1
check "no --project => memory NOT handled" "! grep -qi 'memory symlink' '$SB/m4.out'"
check "no --project => memory symlink still present" "[ -L '$HMEM' ]"

# --- Test group 6: print-only settings.json (never edited) ---
new_sandbox
printf '{"permissions":{"allow":["X"]}}\n' > "$SBHOME/.claude/settings.json"
B4="$(md5 -q "$SBHOME/.claude/settings.json" 2>/dev/null || md5sum "$SBHOME/.claude/settings.json" | cut -d' ' -f1)"
SOUT="$(env HOME="$SBHOME" "$UNINSTALL" 2>&1)"
AFT="$(md5 -q "$SBHOME/.claude/settings.json" 2>/dev/null || md5sum "$SBHOME/.claude/settings.json" | cut -d' ' -f1)"
check "settings.json byte-identical after uninstall (print-only)" "[ '$B4' = '$AFT' ]"
check "settings reminder printed the 4 perms" \
  "printf '%s' \"\$SOUT\" | grep -q 'Read(~/.claude/\\*\\*)' && printf '%s' \"\$SOUT\" | grep -q 'Edit(~/.claude/\\*\\*)'"

# --- Test group 7: WP4.5 round-trip install -> uninstall -> re-install ---
new_sandbox
env HOME="$SBHOME" "$INSTALL" >/dev/null 2>&1
RT_SK1=$(find "$SBHOME/.claude/skills" -maxdepth 1 -type l | wc -l | tr -d ' ')
RT_AG1=$(find "$SBHOME/.claude/agents" -maxdepth 1 -type l | wc -l | tr -d ' ')
RT_BLK1=$(grep -c 'BEGIN claude-workflow-system' "$SBHOME/.claude/CLAUDE.md")
env HOME="$SBHOME" "$UNINSTALL" >/dev/null 2>&1
env HOME="$SBHOME" "$INSTALL" >/dev/null 2>&1
RT_SK2=$(find "$SBHOME/.claude/skills" -maxdepth 1 -type l | wc -l | tr -d ' ')
RT_AG2=$(find "$SBHOME/.claude/agents" -maxdepth 1 -type l | wc -l | tr -d ' ')
RT_BLK2=$(grep -c 'BEGIN claude-workflow-system' "$SBHOME/.claude/CLAUDE.md")
check "round-trip: skill link count restored ($RT_SK1 -> $RT_SK2)" "[ '$RT_SK1' -eq '$RT_SK2' ]"
check "round-trip: agent link count restored ($RT_AG1 -> $RT_AG2)" "[ '$RT_AG1' -eq '$RT_AG2' ]"
check "round-trip: exactly one CLAUDE.md block after re-install" "[ '$RT_BLK2' -eq 1 ] && [ '$RT_BLK1' -eq 1 ]"

# --- Test group 8: SAFETY — the harness never touched the real $HOME ---
check "outer \$HOME unchanged by the whole run" "[ \"\$HOME\" = '$OUTER_HOME' ]"
check "real ~/.claude/skills still populated (live install untouched)" \
  "[ \"\$(find '$OUTER_HOME/.claude/skills' -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')\" -gt 0 ]"

echo ""
echo "=== $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ]
