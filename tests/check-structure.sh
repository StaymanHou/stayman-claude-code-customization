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

# CHANGELOG convention is defined in the snippet and referenced by all four closing SKILLs.
# If any of these drop the reference, the close path silently stops writing to CHANGELOG.
grep_check "CLAUDE.snippet.md defines 'CHANGELOG.md convention'" "CLAUDE.snippet.md" "^## CHANGELOG.md convention" 1
grep_check "feature-finalize references CHANGELOG convention" "skills/feature-finalize/SKILL.md" "CHANGELOG.md convention" 1
grep_check "incident-resolve references CHANGELOG convention" "skills/incident-resolve/SKILL.md" "CHANGELOG.md convention" 1
grep_check "task-close references CHANGELOG convention" "skills/task-close/SKILL.md" "CHANGELOG.md convention" 1
grep_check "product-finalize references CHANGELOG convention" "skills/product-finalize/SKILL.md" "CHANGELOG.md convention" 1

# Entry-skill product-context loading convention has three discoverability surfaces:
# (1) canonical mapping in CLAUDE.snippet.md, (2) cross-level note in transitions.md,
# (3) per-skill `## Step 0` sections in each entry-point SKILL.md. If any of these goes missing
# the agent loses its load-discipline guidance. The grep_check pairs below catch each surface.
grep_check "CLAUDE.snippet.md defines 'Entry-skill product-context loading'" "CLAUDE.snippet.md" "^## Entry-skill product-context loading" 1
grep_check "transitions.md has 'Entry-skill context loading' cross-level subsection" "docs/product/transitions.md" "^### Entry-skill context loading" 1
grep_check "task-plan SKILL.md has Step 0 section" "skills/task-plan/SKILL.md" "^## Step 0: Available product context" 1
grep_check "feature-spec SKILL.md has Step 0 section" "skills/feature-spec/SKILL.md" "^## Step 0: Available product context" 1
grep_check "feature-plan SKILL.md has Step 0 section" "skills/feature-plan/SKILL.md" "^## Step 0: Available product context" 1
grep_check "feature-reproduce SKILL.md has Step 0 section" "skills/feature-reproduce/SKILL.md" "^## Step 0: Available product context" 1
grep_check "incident-report SKILL.md has Step 0 section" "skills/incident-report/SKILL.md" "^## Step 0: Available product context" 1
grep_check "product-vision SKILL.md has Step 0 section" "skills/product-vision/SKILL.md" "^## Step 0: Available product context" 1

echo ""

# ── Phase 3b: debug-* skill category invariants ────────────────────────────
#
# `debug-*` skills are agent-pulled sidebars (not workflow states). The trigger
# boundary lives in two required sections — `## When to use` and `## When NOT to use`.
# If those are removed, the skill loses its self-documenting gate boundary and
# becomes silently more permissive. A grep check catches the regression.

echo "[Phase 3b] debug-* skill category invariants"

for debug_skill in skills/debug-*/SKILL.md; do
  [ -f "$debug_skill" ] || continue
  name=$(basename "$(dirname "$debug_skill")")
  grep_check "$name has '## When to use' section (gate boundary)" "$debug_skill" "^## When to use$" 1
  grep_check "$name has '## When NOT to use' section (gate boundary)" "$debug_skill" "^## When NOT to use$" 1
done

echo ""

# ── Phase 3c: debug-* sidebar discoverability surfaces ─────────────────────
#
# Each debug-* sidebar relies on three discoverability surfaces:
#   1. Prose mention in each caller workflow skill's SKILL.md (so the agent
#      executing the caller state knows to reach for the sidebar)
#   2. Row in each relevant orchestrator's "Debug techniques (agent-pulled
#      sidebars)" subsection (so /session-start can enumerate available techniques)
#   3. Mention in docs/product/transitions.md "Sidebar skills" subsection (so
#      contributors editing the state machine know the category exists)
#
# A regression on (1) or (2) silently makes the sidebar undiscoverable from
# that caller — the skill still works if invoked directly, but the system loses
# the surface that prompts the agent to invoke it. Worth catching.

echo "[Phase 3c] debug-* sidebar discoverability"

# debug-bisect-known-good: callers are feature-build, incident-investigate, task-act
for caller in skills/feature-build/SKILL.md skills/incident-investigate/SKILL.md skills/task-act/SKILL.md; do
  caller_name=$(basename "$(dirname "$caller")")
  grep_check "$caller_name mentions /debug-bisect-known-good" "$caller" "/debug-bisect-known-good" 1
done

for orch in agents/feature-workflow/AGENTS.md agents/incident-workflow/AGENTS.md agents/task-workflow/AGENTS.md; do
  orch_name=$(basename "$(dirname "$orch")")
  grep_check "$orch_name has 'Debug techniques (agent-pulled sidebars)' subsection" "$orch" "Debug techniques \(agent-pulled sidebars\)" 1
done

grep_check "transitions.md has 'Sidebar skills' subsection (under Cross-level mechanisms)" "docs/product/transitions.md" "^### Sidebar skills" 1

echo ""

# ── Phase 3d: TRANSITION-line regex in tests/lib/verify.sh ────────────────
#
# verify.sh's regex extracts the transition ID from model output. It must
# handle the full namespace of ID shapes used by scenarios:
#   - Plain alphanumeric workflow IDs (F1, T2, I3, P10, S18)
#   - IDs with letter suffix (F9b, F10b)
#   - Compound legacy scenario IDs (F-CHGLOG-1, F16-triage-ambiguous)
#   - Hyphenated debug-* sidebar tokens (DEBUG-BISECT-START, DEBUG-BISECT-SKIP)
#   - With markdown decoration: **TRANSITION:**, *TRANSITION:*
#   - With "(<from> → <to>)" suffix
# And it must NOT match obvious non-ID usages of the word TRANSITION.
#
# This regex is load-bearing: every scenario consumes it. A silent regression
# would cause widespread SOFT_PASS-with-no-structured-line failures.
#
# Source-of-truth: the regex is in tests/lib/verify.sh. We re-derive it from
# the file (rather than hardcoding here) so this test stays honest if the
# regex evolves.

echo "[Phase 3d] TRANSITION-line regex (tests/lib/verify.sh)"

# Extract the actual regex used by verify.sh (the line we care about).
REGEX_PATTERN=$(grep -oE 's/\.\*TRANSITION:[^/]*/\\1/p' tests/lib/verify.sh | head -1)
if [ -z "$REGEX_PATTERN" ]; then
  check "verify.sh contains a TRANSITION regex" "fail" "could not locate sed pattern in tests/lib/verify.sh"
else
  check "verify.sh contains a TRANSITION regex" "pass"
  # Replace the captured pattern with the literal regex we want to run sed with
  regex_test() {
    local label="$1"
    local input="$2"
    local expected="$3"
    local actual
    actual=$(echo "$input" | sed -n "$REGEX_PATTERN")
    if [ "$actual" = "$expected" ]; then
      check "regex: $label" "pass"
    else
      check "regex: $label" "fail" "input='$input' expected='$expected' got='$actual'"
    fi
  }

  # Positive cases — should capture the ID
  regex_test "plain workflow ID (F1)" "TRANSITION: F1" "F1"
  regex_test "workflow ID with arrow decoration (T2)" "TRANSITION: T2 (plan → act)" "T2"
  regex_test "markdown bold (F1)" "**TRANSITION:** F1 (entry → spec)" "F1"
  regex_test "back-loop suffix (F9b)" "TRANSITION: F9b" "F9b"
  regex_test "compound legacy ID (F-CHGLOG-1)" "TRANSITION: F-CHGLOG-1" "F-CHGLOG-1"
  regex_test "compound legacy ID (F16-triage-ambiguous)" "TRANSITION: F16-triage-ambiguous" "F16-triage-ambiguous"
  regex_test "hyphenated debug token (DEBUG-BISECT-START)" "TRANSITION: DEBUG-BISECT-START" "DEBUG-BISECT-START"
  regex_test "hyphenated debug token with markdown bold (SKIP)" "**TRANSITION:** DEBUG-BISECT-SKIP" "DEBUG-BISECT-SKIP"
  regex_test "long debug token (NO-CONVERGE)" "TRANSITION: DEBUG-BISECT-NO-CONVERGE" "DEBUG-BISECT-NO-CONVERGE"

  # Negative cases — should NOT match (capture empty)
  regex_test_negative() {
    local label="$1"
    local input="$2"
    local actual
    actual=$(echo "$input" | sed -n "$REGEX_PATTERN")
    if [ -z "$actual" ]; then
      check "regex no-match: $label" "pass"
    else
      check "regex no-match: $label" "fail" "input='$input' matched='$actual'"
    fi
  }
  regex_test_negative "no TRANSITION in text" "No transition emitted here"
  regex_test_negative "TRANSITION without colon" "TRANSITION needs to be added"
fi

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

# ── Phase 5b: claude-time hook script integrity ───────────────────────────
#
# Phase 1 of the claude-code-time-tracking feature shipped tools/claude-time/hook.pl
# (Perl). These structural assertions guard against regression of the artifact
# itself — existence, executable bit, perl -c compile, symlink resolution.
# Behavioral assertions live in tools/claude-time/test/test_hook.sh,
# which is invoked at the bottom of this Phase.

echo "[Phase 5b] claude-time hook script integrity"

if [ -f tools/claude-time/hook.pl ]; then
  check "tools/claude-time/hook.pl exists in repo" "pass"
else
  check "tools/claude-time/hook.pl exists in repo" "fail" "file missing"
fi

if [ -x tools/claude-time/hook.pl ]; then
  check "tools/claude-time/hook.pl is executable" "pass"
else
  check "tools/claude-time/hook.pl is executable" "fail" "missing executable bit"
fi

if perl -c tools/claude-time/hook.pl 2>/dev/null; then
  check "tools/claude-time/hook.pl passes perl -c" "pass"
else
  check "tools/claude-time/hook.pl passes perl -c" "fail" "perl -c failed"
fi

ct_link_target=$(readlink ~/.claude/hooks/claude-time-hook.pl 2>/dev/null || echo "")
if echo "$ct_link_target" | grep -q "my-claude-code-customization/tools/claude-time/hook.pl"; then
  check "~/.claude/hooks/claude-time-hook.pl symlink resolves to this repo" "pass"
else
  check "~/.claude/hooks/claude-time-hook.pl symlink resolves to this repo" "fail" \
    "target: ${ct_link_target:-missing}"
fi

if [ -f tools/claude-time/README.md ]; then
  check "tools/claude-time/README.md exists" "pass"
else
  check "tools/claude-time/README.md exists" "fail" "file missing"
fi

# Behavioral end-to-end test for the hook. Lives in the tool's own test/ dir
# rather than being inlined here — it's a behavioral suite, not a structural
# one. We invoke it and surface its pass/fail.
if [ -x tools/claude-time/test/test_hook.sh ]; then
  if tools/claude-time/test/test_hook.sh > /dev/null 2>&1; then
    check "tools/claude-time/test/test_hook.sh — behavioral assertions" "pass"
  else
    err=$(tools/claude-time/test/test_hook.sh 2>&1 | grep '\[FAIL\]' | head -3)
    check "tools/claude-time/test/test_hook.sh — behavioral assertions" "fail" "$err"
  fi
else
  check "tools/claude-time/test/test_hook.sh exists + executable" "fail" "missing or not executable"
fi

# Privacy assertion — single-purpose, run every structural check.
if [ -x tools/claude-time/test/privacy_check.sh ]; then
  if tools/claude-time/test/privacy_check.sh > /dev/null 2>&1; then
    check "tools/claude-time/test/privacy_check.sh — privacy invariant" "pass"
  else
    err=$(tools/claude-time/test/privacy_check.sh 2>&1 | grep '\[FAIL\]' | head -3)
    check "tools/claude-time/test/privacy_check.sh — privacy invariant" "fail" "$err"
  fi
else
  check "tools/claude-time/test/privacy_check.sh exists + executable" "fail" "missing or not executable"
fi

# Phase 3 additions: reclassifier module + CLI + unit tests
if [ -f tools/claude-time/reclassify.py ]; then
  check "tools/claude-time/reclassify.py exists" "pass"
else
  check "tools/claude-time/reclassify.py exists" "fail" "file missing"
fi

if [ -x tools/claude-time/claude-time ]; then
  check "tools/claude-time/claude-time CLI is executable" "pass"
else
  check "tools/claude-time/claude-time CLI is executable" "fail" "missing executable bit"
fi

if python3 -m py_compile tools/claude-time/reclassify.py 2>/dev/null && \
   python3 -m py_compile tools/claude-time/claude-time 2>/dev/null; then
  check "tools/claude-time Python sources compile" "pass"
else
  check "tools/claude-time Python sources compile" "fail" "py_compile failed"
fi

ct_cli_link_target=$(readlink ~/.claude/bin/claude-time 2>/dev/null || echo "")
if echo "$ct_cli_link_target" | grep -q "my-claude-code-customization/tools/claude-time/claude-time"; then
  check "~/.claude/bin/claude-time symlink resolves to this repo" "pass"
else
  check "~/.claude/bin/claude-time symlink resolves to this repo" "fail" \
    "target: ${ct_cli_link_target:-missing}"
fi

# Reclassifier unit tests
if (cd tools/claude-time/test && python3 -m unittest test_reclassify > /dev/null 2>&1); then
  check "tools/claude-time/test/test_reclassify.py — unit tests" "pass"
else
  err=$(cd tools/claude-time/test && python3 -m unittest test_reclassify 2>&1 | tail -3)
  check "tools/claude-time/test/test_reclassify.py — unit tests" "fail" "$err"
fi

# CLI end-to-end tests
if [ -x tools/claude-time/test/test_cli.sh ]; then
  if tools/claude-time/test/test_cli.sh > /dev/null 2>&1; then
    check "tools/claude-time/test/test_cli.sh — CLI end-to-end" "pass"
  else
    err=$(tools/claude-time/test/test_cli.sh 2>&1 | grep '\[FAIL\]' | head -3)
    check "tools/claude-time/test/test_cli.sh — CLI end-to-end" "fail" "$err"
  fi
else
  check "tools/claude-time/test/test_cli.sh exists + executable" "fail" "missing or not executable"
fi

# Multi-instance scenario (real two-process reattribution end-to-end)
if [ -x tools/claude-time/test/multi_instance.sh ]; then
  if REPO_ROOT="$(pwd)" tools/claude-time/test/multi_instance.sh > /dev/null 2>&1; then
    check "tools/claude-time/test/multi_instance.sh — cross-session reattribution" "pass"
  else
    err=$(REPO_ROOT="$(pwd)" tools/claude-time/test/multi_instance.sh 2>&1 | grep '\[FAIL\]' | head -3)
    check "tools/claude-time/test/multi_instance.sh — cross-session reattribution" "fail" "$err"
  fi
else
  check "tools/claude-time/test/multi_instance.sh exists + executable" "fail" "missing or not executable"
fi

# Concurrent-write stress (50 parallel writers, WAL safety)
if [ -x tools/claude-time/test/stress_concurrent.sh ]; then
  if tools/claude-time/test/stress_concurrent.sh > /dev/null 2>&1; then
    check "tools/claude-time/test/stress_concurrent.sh — 50 concurrent writers" "pass"
  else
    err=$(tools/claude-time/test/stress_concurrent.sh 2>&1 | grep '\[FAIL\]' | head -3)
    check "tools/claude-time/test/stress_concurrent.sh — 50 concurrent writers" "fail" "$err"
  fi
else
  check "tools/claude-time/test/stress_concurrent.sh exists + executable" "fail" "missing or not executable"
fi

# bench.sh: existence only (perf assertion is OS-dependent; runs on demand via
# `tools/claude-time/test/bench.sh`, not on every structural check)
if [ -x tools/claude-time/test/bench.sh ]; then
  check "tools/claude-time/test/bench.sh exists + executable" "pass"
else
  check "tools/claude-time/test/bench.sh exists + executable" "fail" "missing or not executable"
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

# ── Phase 8: capture-session-slice.sh contract ─────────────────────────────
# Regression coverage for tools/capture-session-slice.sh, written 2026-05-16
# during the session-replay-harness feature (Phase 1 verify-codify). This
# catches the class of regression that surfaced in P1.5: --help silently
# exiting non-zero. Also catches: script removed, shebang broken, executable
# bit cleared.

echo "[Phase 8] capture-session-slice.sh contract"

if [ -f tools/capture-session-slice.sh ]; then
  check "tools/capture-session-slice.sh exists" "pass"

  if [ -x tools/capture-session-slice.sh ]; then
    check "tools/capture-session-slice.sh is executable" "pass"
  else
    check "tools/capture-session-slice.sh is executable" "fail" "chmod +x missing"
  fi

  if bash -n tools/capture-session-slice.sh 2>/dev/null; then
    check "tools/capture-session-slice.sh has valid bash syntax" "pass"
  else
    check "tools/capture-session-slice.sh has valid bash syntax" "fail"
  fi

  # --help must exit 0 (regression catch for the P1.5 bug)
  if tools/capture-session-slice.sh --help >/dev/null 2>&1; then
    check "tools/capture-session-slice.sh --help exits 0" "pass"
  else
    check "tools/capture-session-slice.sh --help exits 0" "fail" "exits $?"
  fi

  if tools/capture-session-slice.sh -h >/dev/null 2>&1; then
    check "tools/capture-session-slice.sh -h exits 0" "pass"
  else
    check "tools/capture-session-slice.sh -h exits 0" "fail" "exits $?"
  fi

  # Error paths must exit 1 (regression catch: P1.5 fix must not over-broaden
  # the success path).
  set +e
  tools/capture-session-slice.sh >/dev/null 2>&1
  rc=$?
  set -e
  if [ "$rc" = "1" ]; then
    check "tools/capture-session-slice.sh missing-arg exits 1" "pass"
  else
    check "tools/capture-session-slice.sh missing-arg exits 1" "fail" "got $rc"
  fi

  set +e
  tools/capture-session-slice.sh --bogus-flag >/dev/null 2>&1
  rc=$?
  set -e
  if [ "$rc" = "1" ]; then
    check "tools/capture-session-slice.sh unknown-arg exits 1" "pass"
  else
    check "tools/capture-session-slice.sh unknown-arg exits 1" "fail" "got $rc"
  fi
else
  check "tools/capture-session-slice.sh exists" "fail" "file not found"
fi

echo ""

# ── Phase 9: Orchestrator pause-policy cheat-sheet block ──────────────────
#
# Each feature SKILL.md affected by incident
# "autopilot-pause-policy-recheck-regression" (2026-05-17) must carry a hard
# in-skill cheat-sheet block. The block is what load-bears the fix: SKILL.md
# prose is reliably loaded into context at every Skill tool invocation, so
# the pause-policy decision sits next to the transition emission instead of
# relying on AGENTS.md prose the orchestrator read once at session start.
#
# Three structural assertions per file:
#   (1) the canonical heading is present
#   (2) the "Hard rule for AUTO exits" semantic anchor is present — the
#       imperative wording is the load-bearing part; if it weakens to
#       "should" or a softer phrasing, the regression mode returns
#   (3) the block contains a per-skill pause-policy table referencing all
#       four drive modes
#
# If this phase fails, the mitigation has been silently weakened — that is
# the regression signal the original incident WIP file says we must catch.

echo "[Phase 9] Orchestrator pause-policy cheat-sheet presence"

PAUSE_POLICY_FILES=(
  skills/feature-spec/SKILL.md
  skills/feature-research/SKILL.md
  skills/feature-plan/SKILL.md
  skills/feature-build/SKILL.md
  skills/feature-verify-auto/SKILL.md
  skills/feature-verify-self/SKILL.md
  skills/feature-verify-human/SKILL.md
  skills/feature-verify-codify/SKILL.md
)

for f in "${PAUSE_POLICY_FILES[@]}"; do
  if [ ! -f "$f" ]; then
    check "$f exists" "fail" "file missing"
    continue
  fi

  # (1) Canonical heading
  if grep -qF "## Orchestrator Pause Policy (cheat-sheet)" "$f"; then
    check "$f has Orchestrator Pause Policy block" "pass"
  else
    check "$f has Orchestrator Pause Policy block" "fail" \
      "missing '## Orchestrator Pause Policy (cheat-sheet)' heading"
  fi

  # (2) Load-bearing imperative "Hard rule for AUTO exits"
  if grep -qF "Hard rule for AUTO exits" "$f"; then
    check "$f has 'Hard rule for AUTO exits' anchor" "pass"
  else
    check "$f has 'Hard rule for AUTO exits' anchor" "fail" \
      "missing 'Hard rule for AUTO exits' phrase (semantic anchor)"
  fi

  # (3) Per-skill pause-policy table referencing all four drive modes.
  # The block contains a markdown row mentioning all four mode names.
  if grep -qE "Mode 1.*Mode 2.*Mode 3.*Mode 4" "$f"; then
    check "$f has pause-policy table with all 4 drive modes" "pass"
  else
    check "$f has pause-policy table with all 4 drive modes" "fail" \
      "no single line references all four modes (table row missing or malformed)"
  fi
done

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
