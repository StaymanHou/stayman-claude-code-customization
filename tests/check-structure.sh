#!/usr/bin/env bash
# check-structure.sh — Structural integrity checks for the workflow system.
# Tests argument-hints, CLAUDE.md content, install.sh idempotence, and symlink counts.
# Complements run-tests.sh (which tests skill transitions) with static-file assertions.
#
# Usage:
#   ./tests/check-structure.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0
FAIL=0
ERRORS=()

check() {
  local desc="$1"
  local result="$2"  # "pass" or "fail"
  local detail="${3:-}"
  if [ "$result" = "pass" ]; then
    echo "  [PASS] $desc"
    ((PASS++)) || true
  else
    echo "  [FAIL] $desc${detail:+ — $detail}"
    ((FAIL++)) || true
    ERRORS+=("$desc${detail:+: $detail}")
  fi
}

grep_check() {
  local desc="$1"
  local file="$2"
  local pattern="$3"
  local min_count="${4:-1}"
  local count
  count=$(grep -cE "$pattern" "$file" 2>/dev/null || echo 0)
  if [ "$count" -ge "$min_count" ]; then
    check "$desc" "pass"
  else
    check "$desc" "fail" "found $count lines matching '$pattern' in $file (need ≥$min_count)"
  fi
}

cd "$PROJECT_DIR"

echo "=== Structural Integrity Checks ==="
echo ""

# ── Phase 2: Argument-Hint Polish ──────────────────────────────────────────

echo "[Phase 2] Argument-hint correctness"

# feature-build must mention scoped leaf IDs
if grep -q "argument-hint" skills/feature-build/SKILL.md && \
   grep "argument-hint" skills/feature-build/SKILL.md | grep -qE "leaf IDs|leaf-id|verify-human\.[0-9]"; then
  check "feature-build hint mentions scoped leaf IDs" "pass"
else
  check "feature-build hint mentions scoped leaf IDs" "fail" \
    "$(grep 'argument-hint' skills/feature-build/SKILL.md 2>/dev/null || echo 'not found')"
fi

# feature-verify-human must mention scoped re-entry context
if grep -q "argument-hint" skills/feature-verify-human/SKILL.md && \
   grep "argument-hint" skills/feature-verify-human/SKILL.md | grep -qE "scoped|leaf ID|verify-human\.[0-9]"; then
  check "feature-verify-human hint mentions scoped re-entry" "pass"
else
  check "feature-verify-human hint mentions scoped re-entry" "fail" \
    "$(grep 'argument-hint' skills/feature-verify-human/SKILL.md 2>/dev/null || echo 'not found')"
fi

# feature-verify-auto must mention scope or phase
if grep -q "argument-hint" skills/feature-verify-auto/SKILL.md && \
   grep "argument-hint" skills/feature-verify-auto/SKILL.md | grep -qiE "scope|phase"; then
  check "feature-verify-auto hint mentions scope or phase" "pass"
else
  check "feature-verify-auto hint mentions scope or phase" "fail" \
    "$(grep 'argument-hint' skills/feature-verify-auto/SKILL.md 2>/dev/null || echo 'not found')"
fi

echo ""

# ── Phase 3: CLAUDE.md Documentation ──────────────────────────────────────

echo "[Phase 3] CLAUDE.md documentation content"

grep_check "CLAUDE.md contains 'Work Tree' ≥3 times" "CLAUDE.md" "Work Tree" 3
grep_check "CLAUDE.md contains 'Observable Outcomes'" "CLAUDE.md" "Observable Outcomes" 1
grep_check "CLAUDE.md contains severity taxonomy (BLOCKING or severity)" "CLAUDE.md" "BLOCKING|severity" 1
grep_check "CLAUDE.md mentions verify-self" "CLAUDE.md" "verify-self" 1

echo ""

# ── Phase 4: install.sh and symlinks ──────────────────────────────────────

echo "[Phase 4] install.sh idempotence and symlink integrity"

# install.sh exits 0
if ./install.sh > /dev/null 2>&1; then
  check "install.sh first run exits 0" "pass"
else
  check "install.sh first run exits 0" "fail" "non-zero exit"
fi

# install.sh second run exits 0 (idempotent)
if ./install.sh > /dev/null 2>&1; then
  check "install.sh second run exits 0 (idempotent)" "pass"
else
  check "install.sh second run exits 0 (idempotent)" "fail" "non-zero exit on second run"
fi

# feature-verify-self symlink exists and points to this repo
symlink_target=$(readlink ~/.claude/skills/feature-verify-self 2>/dev/null || echo "")
if echo "$symlink_target" | grep -q "my-claude-code-customization"; then
  check "~/.claude/skills/feature-verify-self symlink resolves to this repo" "pass"
else
  check "~/.claude/skills/feature-verify-self symlink resolves to this repo" "fail" \
    "target: ${symlink_target:-missing}"
fi

# symlink count matches skill dir count
skill_dirs=$(ls -d skills/*/ 2>/dev/null | wc -l | tr -d ' ')
repo_symlinks=$(ls -la ~/.claude/skills/ 2>/dev/null | grep -c "my-claude-code-customization" || echo 0)
if [ "$skill_dirs" -eq "$repo_symlinks" ]; then
  check "symlink count matches skill dir count ($skill_dirs/$repo_symlinks)" "pass"
else
  check "symlink count matches skill dir count" "fail" \
    "skill dirs: $skill_dirs, repo symlinks: $repo_symlinks"
fi

echo ""

# ── Phase 5: Hooks ────────────────────────────────────────────────────────

echo "[Phase 5] Hook script integrity"

# notify-telegram.sh exists in repo
if [ -f hooks/notify-telegram.sh ]; then
  check "hooks/notify-telegram.sh exists in repo" "pass"
else
  check "hooks/notify-telegram.sh exists in repo" "fail" "file missing"
fi

# notify-telegram.sh is executable
if [ -x hooks/notify-telegram.sh ]; then
  check "hooks/notify-telegram.sh is executable" "pass"
else
  check "hooks/notify-telegram.sh is executable" "fail" "missing executable bit"
fi

# notify-telegram.sh passes bash syntax check
if bash -n hooks/notify-telegram.sh 2>/dev/null; then
  check "hooks/notify-telegram.sh passes bash syntax check" "pass"
else
  check "hooks/notify-telegram.sh passes bash syntax check" "fail" "bash -n failed"
fi

# Hook symlink in ~/.claude/hooks/ resolves into this repo (only after install.sh)
hook_link_target=$(readlink ~/.claude/hooks/notify-telegram.sh 2>/dev/null || echo "")
if echo "$hook_link_target" | grep -q "my-claude-code-customization"; then
  check "~/.claude/hooks/notify-telegram.sh symlink resolves to this repo" "pass"
else
  check "~/.claude/hooks/notify-telegram.sh symlink resolves to this repo" "fail" \
    "target: ${hook_link_target:-missing}"
fi

# Hook is silent no-op when env vars missing (must exit 0)
if (unset CLAUDE_TELEGRAM_BOT_TOKEN CLAUDE_TELEGRAM_CHAT_ID; \
    echo '{"hook_event_name":"Notification","message":"x"}' \
    | hooks/notify-telegram.sh > /dev/null 2>&1); then
  check "hook exits 0 with missing env vars (silent no-op)" "pass"
else
  check "hook exits 0 with missing env vars (silent no-op)" "fail" "non-zero exit"
fi

# Hook tolerates malformed JSON on stdin (must exit 0)
if (unset CLAUDE_TELEGRAM_BOT_TOKEN CLAUDE_TELEGRAM_CHAT_ID; \
    echo "not json at all" | hooks/notify-telegram.sh > /dev/null 2>&1); then
  check "hook exits 0 with malformed JSON stdin" "pass"
else
  check "hook exits 0 with malformed JSON stdin" "fail" "non-zero exit"
fi

# Hook tolerates empty stdin (must exit 0)
if (unset CLAUDE_TELEGRAM_BOT_TOKEN CLAUDE_TELEGRAM_CHAT_ID; \
    echo "" | hooks/notify-telegram.sh > /dev/null 2>&1); then
  check "hook exits 0 with empty stdin" "pass"
else
  check "hook exits 0 with empty stdin" "fail" "non-zero exit"
fi

# settings.json (global) is valid JSON and contains the Notification hook
# (Stop hook was removed 2026-05-10 — was firing on every turn end, too noisy.)
if command -v python3 &>/dev/null; then
  if python3 -c "import json; d=json.load(open('$HOME/.claude/settings.json')); \
      assert 'Notification' in d.get('hooks',{}), 'Notification hook missing'" 2>/dev/null; then
    check "~/.claude/settings.json has Notification hook" "pass"
  else
    err=$(python3 -c "import json; d=json.load(open('$HOME/.claude/settings.json')); \
      assert 'Notification' in d.get('hooks',{}), 'Notification hook missing'" 2>&1)
    check "~/.claude/settings.json has Notification hook" "fail" "$err"
  fi
fi

echo ""

# ── Phase 6: notify-human skill is gone ───────────────────────────────────
#
# The notify-human skill was replaced by the notify-telegram.sh hook.
# These assertions catch a regression where someone re-introduces the skill
# or leaves a stale invocation in active orchestration guidance.

echo "[Phase 6] notify-human skill removal"

# (a) skills/notify-human/ does not exist in the repo
if [ ! -e skills/notify-human ]; then
  check "skills/notify-human/ does not exist" "pass"
else
  check "skills/notify-human/ does not exist" "fail" "directory still present"
fi

# (b) ~/.claude/skills/notify-human symlink is gone (post-install)
if [ ! -e ~/.claude/skills/notify-human ]; then
  check "~/.claude/skills/notify-human symlink is gone" "pass"
else
  check "~/.claude/skills/notify-human symlink is gone" "fail" "stale symlink present"
fi

# (c) No AGENTS.md references notify-human (skills list or invocation)
agents_hits=$( { grep -l "notify-human\|notify_human" agents/*/AGENTS.md 2>/dev/null || true; } | wc -l | tr -d ' ')
if [ "$agents_hits" = "0" ]; then
  check "no AGENTS.md references notify-human" "pass"
else
  check "no AGENTS.md references notify-human" "fail" \
    "$( { grep -l 'notify-human\|notify_human' agents/*/AGENTS.md 2>/dev/null || true; } )"
fi

# (d) No active SKILL.md references invoke /notify-human
skills_hits=$( { grep -l "notify-human\|notify_human" skills/*/SKILL.md 2>/dev/null || true; } | wc -l | tr -d ' ')
if [ "$skills_hits" = "0" ]; then
  check "no SKILL.md references notify-human" "pass"
else
  check "no SKILL.md references notify-human" "fail" \
    "$( { grep -l 'notify-human\|notify_human' skills/*/SKILL.md 2>/dev/null || true; } )"
fi

# (e) CLAUDE.snippet.md has no notify-human mention (the global mandate is gone)
if ! grep -q "notify-human\|notify_human" CLAUDE.snippet.md 2>/dev/null; then
  check "CLAUDE.snippet.md has no notify-human reference" "pass"
else
  check "CLAUDE.snippet.md has no notify-human reference" "fail" "still referenced"
fi

# (f) ~/.claude/CLAUDE.md (the rendered global guidance) has no notify-human mention
if ! grep -q "notify-human\|notify_human" "$HOME/.claude/CLAUDE.md" 2>/dev/null; then
  check "~/.claude/CLAUDE.md has no notify-human reference" "pass"
else
  check "~/.claude/CLAUDE.md has no notify-human reference" "fail" "still referenced"
fi

# (g) ~/.claude/settings.json has no orphan permission entry pointing at the
# deleted skill directory
if ! grep -q "skills/notify-human" "$HOME/.claude/settings.json" 2>/dev/null; then
  check "~/.claude/settings.json has no skills/notify-human permission" "pass"
else
  check "~/.claude/settings.json has no skills/notify-human permission" "fail" "orphan entry present"
fi

echo ""

# ── Phase 1: Scenario YAML validity ───────────────────────────────────────

echo "[Phase 1] Scenario YAML integrity"

if command -v python3 &>/dev/null; then
  yaml_errors=$(python3 -c "
import yaml, pathlib, sys
errors = []
for f in pathlib.Path('tests/scenarios').glob('*.yaml'):
    try:
        yaml.safe_load(f.read_text())
    except yaml.YAMLError as e:
        errors.append(str(f) + ': ' + str(e))
if errors:
    for e in errors: print(e)
    sys.exit(1)
" 2>&1 || true)
  if [ -z "$yaml_errors" ]; then
    check "All scenario YAML files parse cleanly" "pass"
  else
    check "All scenario YAML files parse cleanly" "fail" "$yaml_errors"
  fi
else
  check "All scenario YAML files parse cleanly" "fail" "python3 not available"
fi

# Minimum scenario count (should be ≥ 88 after product-doc-archival feature)
total=$(./tests/run-tests.sh --dry-run 2>/dev/null | grep "^TOTAL" | grep -oE "[0-9]+" | tail -1 || echo 0)
if [ "${total:-0}" -ge 88 ]; then
  check "Scenario count ≥ 88 ($total registered)" "pass"
else
  check "Scenario count ≥ 88" "fail" "only $total scenarios found"
fi

echo ""

# ── Phase 7: Settings fixture drift ───────────────────────────────────────
#
# tests/fixtures/settings.json is loaded by run-tests.sh via --settings (with
# --setting-sources project,local) so test invocations don't inherit the
# developer's live ~/.claude/settings.json. We want the fixture to mirror live
# settings closely so tests run under near-realistic conditions, BUT we have
# a documented set of intentional differences (Telegram hooks disabled, Telegram
# env vars absent). This check FAILs if any field outside the documented diff
# set has drifted — telling the developer to either update the fixture or
# document a new exception.

echo "[Phase 7] Settings fixture drift"

if command -v python3 &>/dev/null && [ -f tests/fixtures/settings.json ] && [ -f "$HOME/.claude/settings.json" ]; then
  drift_output=$(python3 - <<'PYEOF' 2>&1 || true
import json, sys, os

LIVE = os.path.expanduser("~/.claude/settings.json")
FIXTURE = "tests/fixtures/settings.json"

# Documented intentional diffs. Format: list of (path, expected_live, expected_fixture).
# `path` is a tuple of nested keys; `MISSING` is a sentinel meaning the key is absent.
MISSING = object()
INTENTIONAL_DIFFS = [
    # Telegram hook is wired in live, absent in fixture
    (("hooks", "Notification"), "non-empty-list", []),
    (("hooks", "Stop"), "any", []),
    # Telegram env vars present in live, absent in fixture
    (("env", "CLAUDE_TELEGRAM_BOT_TOKEN"), "present", MISSING),
    (("env", "CLAUDE_TELEGRAM_CHAT_ID"), "present", MISSING),
]

def get_path(d, path):
    cur = d
    for k in path:
        if not isinstance(cur, dict) or k not in cur:
            return MISSING
        cur = cur[k]
    return cur

def matches_expected(actual, expected):
    if expected == "any":
        return True
    if expected == "present":
        return actual is not MISSING
    if expected == "non-empty-list":
        return isinstance(actual, list) and len(actual) > 0
    return actual == expected

with open(LIVE) as f:
    live = json.load(f)
with open(FIXTURE) as f:
    fixture = json.load(f)

# Strip fixture-only metadata fields from comparison
fixture = {k: v for k, v in fixture.items() if not k.startswith("_")}

# Verify each intentional diff is present and matches expectation
diff_violations = []
for path, exp_live, exp_fix in INTENTIONAL_DIFFS:
    live_val = get_path(live, path)
    fix_val = get_path(fixture, path)
    if not matches_expected(live_val, exp_live):
        diff_violations.append(
            f"  {'.'.join(path)}: live should be {exp_live!r}, got {live_val!r}"
        )
    if not matches_expected(fix_val, exp_fix):
        diff_violations.append(
            f"  {'.'.join(path)}: fixture should be {exp_fix!r}, got {fix_val!r}"
        )

if diff_violations:
    print("INTENTIONAL_DIFFS_BROKEN")
    for v in diff_violations:
        print(v)
    sys.exit(1)

# Now compare live vs fixture, ignoring the documented diff paths.
# Anything that differs outside the diff set is unexpected drift.
intentional_paths = {tuple(p) for p, _, _ in INTENTIONAL_DIFFS}

def walk(a, b, path=()):
    """Yield (path, a_val, b_val) for every leaf or container that differs."""
    if path in intentional_paths:
        return
    if type(a) != type(b):
        yield (path, a, b)
        return
    if isinstance(a, dict):
        keys = set(a.keys()) | set(b.keys())
        for k in keys:
            subpath = path + (k,)
            if subpath in intentional_paths:
                continue
            if k not in a or k not in b:
                yield (subpath, a.get(k, MISSING), b.get(k, MISSING))
            else:
                yield from walk(a[k], b[k], subpath)
    elif isinstance(a, list):
        if a != b:
            yield (path, a, b)
    else:
        if a != b:
            yield (path, a, b)

drift = list(walk(live, fixture))
if drift:
    print("DRIFT_DETECTED")
    for path, lv, fv in drift:
        p = ".".join(path) if path else "<root>"
        lv_s = "<missing>" if lv is MISSING else json.dumps(lv)
        fv_s = "<missing>" if fv is MISSING else json.dumps(fv)
        print(f"  {p}: live={lv_s} fixture={fv_s}")
    sys.exit(1)

print("OK")
PYEOF
)
  case "$drift_output" in
    "OK")
      check "settings fixture in sync with live (modulo documented diffs)" "pass" ;;
    DRIFT_DETECTED*)
      drift_detail=$(echo "$drift_output" | tail -n +2)
      check "settings fixture in sync with live (modulo documented diffs)" "fail" \
        "drift detected — update tests/fixtures/settings.json (or add to INTENTIONAL_DIFFS in tests/check-structure.sh):
$drift_detail" ;;
    INTENTIONAL_DIFFS_BROKEN*)
      drift_detail=$(echo "$drift_output" | tail -n +2)
      check "settings fixture in sync with live (modulo documented diffs)" "fail" \
        "intentional diffs no longer hold:
$drift_detail" ;;
    *)
      check "settings fixture in sync with live (modulo documented diffs)" "fail" \
        "unexpected output: $drift_output" ;;
  esac
else
  if [ ! -f tests/fixtures/settings.json ]; then
    check "tests/fixtures/settings.json exists" "fail" "fixture missing"
  fi
fi

echo ""

# ── Summary ────────────────────────────────────────────────────────────────

echo "=== Summary ==="
echo "PASS: $PASS | FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failures:"
  for e in "${ERRORS[@]}"; do
    echo "  - $e"
  done
  exit 1
fi

echo "All structural checks passed."
