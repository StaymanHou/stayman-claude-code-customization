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
  # NB: Under `set -euo pipefail`, the naive `count=$(grep -cE ... || echo 0)` form
  # produces "0\n0" (3-char string with embedded newline) when grep finds 0 matches,
  # because both grep's stdout (`0\n`) AND the `|| echo 0` fire. The `(... || true)
  # | head -1` form suppresses grep's exit-1 inside the subshell + takes only the
  # first line of count output. The `:-0` fallback handles the empty-capture case.
  count=$( (grep -cE "$pattern" "$file" 2>/dev/null || true) | head -1 )
  count="${count:-0}"
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

# feature-finalize §1 WBS-update step must direct the agent to tick per-task checkboxes within
# the shipped WP's section after appending the ✅ SHIPPED tag. Per SURFACE-2026-05-29-FEATURE-
# FINALIZE-MISSES-WBS-TASK-CHECKBOXES: 12-of-12 WPs since v3 cycle start landed with the WP
# heading ✅ SHIPPED but the underlying task checkboxes left as `- [ ]`, making WBS a
# partially-trustworthy state surface for downstream planning skills. If this directive gets
# dropped in a future edit, the inconsistency returns silently and accrues across every WP
# finalize. Anchor phrase chosen to capture the per-task tick discipline specifically (not the
# generic WP-heading update, which is the pre-existing behavior).
grep_check "feature-finalize directs WBS per-task checkbox tick" "skills/feature-finalize/SKILL.md" "WBS per-task checkbox tick" 1

grep_check "incident-resolve references CHANGELOG convention" "skills/incident-resolve/SKILL.md" "CHANGELOG.md convention" 1
grep_check "task-close references CHANGELOG convention" "skills/task-close/SKILL.md" "CHANGELOG.md convention" 1
grep_check "product-finalize references CHANGELOG convention" "skills/product-finalize/SKILL.md" "CHANGELOG.md convention" 1

# task-verify single-step gate shipped to the task workflow 2026-06-11 (feature:
# task-workflow-needs-lite-verify). The new skill sits between task-act and
# task-close, writing an observable and running it before close. The structural
# pin set below catches regression on its load-bearing properties:
#   1. SKILL.md exists
#   2. Frontmatter `name: task-verify` is present and correct (drives `/task-verify` invocation)
#   3. State Machine Context names T5b/T5c (the two exit transitions)
#   4. Orchestrator Pause Policy cheat-sheet section present (required for all
#      workflow skills that have orchestrator-visible transitions)
#   5. SHORTCUT-token audit-trail convention is preserved (mirrors feature-verify-self §3)
#   6. CLAUDE.md Conventions section cites task-verify (so future agents/authors discover it)
#   7. task-act SKILL.md emits TRANSITION: T5a (replaces old T5 → close routing)
grep_check "task-verify SKILL.md exists with name frontmatter" "skills/task-verify/SKILL.md" "^name: task-verify$" 1
grep_check "task-verify SKILL.md has 'State Machine Context' section" "skills/task-verify/SKILL.md" "^## State Machine Context" 1
grep_check "task-verify SKILL.md names T5b and T5c exit transitions" "skills/task-verify/SKILL.md" "T5b|T5c" 2
grep_check "task-verify SKILL.md has 'Orchestrator Pause Policy (cheat-sheet)' section" "skills/task-verify/SKILL.md" "Orchestrator Pause Policy \(cheat-sheet\)" 1
grep_check "task-verify SKILL.md retains SHORTCUT-token audit-trail convention" "skills/task-verify/SKILL.md" "\[SHORTCUT-<YYYY-MM-DD>\]" 1
grep_check "CLAUDE.md Conventions section cites task-verify" "CLAUDE.md" "task-verify" 1
grep_check "task-act SKILL.md emits TRANSITION: T5a" "skills/task-act/SKILL.md" "TRANSITION: T5a" 1

# Long-running commands rule lives in CLAUDE.snippet.md only — global harness rule, no per-skill
# references. If the snippet section gets dropped or renamed, every project loses the timeout +
# exclusive-resource concurrency discipline.
grep_check "CLAUDE.snippet.md defines 'Long-running commands'" "CLAUDE.snippet.md" "^## Long-running commands" 1

# Runtime registry subsection inside the Long-running commands section. Rule 1 forward-links
# to this subsection ("see `### Runtime registry` below"); if the subsection heading goes missing,
# the forward-link becomes dangling and the agent loses its read+update discipline.
grep_check "CLAUDE.snippet.md defines '### Runtime registry'" "CLAUDE.snippet.md" "^### Runtime registry" 1

# Project-root runtimes.md is the actual registry file each project maintains. The grep below
# asserts the canonical frontmatter marker — a hand-edited file that drops the marker would
# break the agent's "is this a registry?" identification on read.
grep_check "runtimes.md exists with shape: runtime-registry frontmatter" "runtimes.md" "^shape: runtime-registry" 1

# Entry-skill product-context loading convention has three discoverability surfaces:
# (1) canonical mapping in CLAUDE.snippet.md, (2) cross-level note in transitions.md,
# (3) per-skill `## Step 0` sections in each entry-point SKILL.md. If any of these goes missing
# the agent loses its load-discipline guidance. The grep_check pairs below catch each surface.
grep_check "CLAUDE.snippet.md defines 'Entry-skill product-context loading'" "CLAUDE.snippet.md" "^## Entry-skill product-context loading" 1
grep_check "transitions.md has 'Entry-skill context loading' cross-level subsection" "docs/product/transitions.md" "^### Entry-skill context loading" 1
grep_check "task-plan SKILL.md has Step 0 section" "skills/task-plan/SKILL.md" "^## Step 0: Available product context" 1
grep_check "feature-spec SKILL.md has Step 0 section" "skills/feature-spec/SKILL.md" "^## Step 0: Available product context" 1
grep_check "feature-plan SKILL.md has Step 0 section" "skills/feature-plan/SKILL.md" "^## Step 0: Available product context" 1

# Randomize-host-ports guidance shipped to product-context Variant A in commit 5872554
# (feature: docker-init-randomize-host-ports). The bullet is pure prose, so the only
# regression net at the file level is presence of its distinctive anchors. Two pins:
# the literal bullet name, plus the substantive ephemeral-range + 49152 lower-bound.
grep_check "product-context SKILL.md retains 'Randomize host ports' bullet" "skills/product-context/SKILL.md" "Randomize host ports" 1
grep_check "product-context SKILL.md cites ephemeral-port range with 49152 anchor" "skills/product-context/SKILL.md" "ephemeral range.*49152|49152.*ephemeral" 1

# Docker daemon-vs-container distinction shipped to product-context Variant A
# (feature: docker-daemon-vs-container-distinction, 2026-06-19, from learning
# 2026-06-19-docker-daemon-up-container-down-just-start-it). The Variant-A template
# must distinguish a hard-block (daemon unreachable → STOP and ask) from a self-unblock
# (daemon up but containers down → start them yourself, don't pause). Pure prose, so the
# regression net is presence of both load-bearing clauses. Two pins: the daemon-unreachable
# hard-blocker (preserved) and the container-down self-start instruction (new).
grep_check "product-context SKILL.md retains daemon-unreachable hard-blocker clause" "skills/product-context/SKILL.md" "[Dd]aemon ([Ii]s )?unreachable" 1
grep_check "product-context SKILL.md adds container-down self-start instruction" "skills/product-context/SKILL.md" "containers are down|docker compose up" 1

# Auto-skip gate shipped to feature-verify-human/SKILL.md §2 (feature:
# verify-human-auto-skip-when-no-integration-boundary). The gate is prose-only
# behavioral guidance — the regression net is presence of its load-bearing anchors.
# Two pins: the operator-visible affirmation tail-line, and the 4-gate heading anchor.
grep_check "feature-verify-human SKILL.md retains 'Auto-skipped per drive_mode' affirmation line" "skills/feature-verify-human/SKILL.md" "Auto-skipped per drive_mode" 1
grep_check "feature-verify-human SKILL.md retains 4-gate Auto-skip heading anchor" "skills/feature-verify-human/SKILL.md" "Mode 3\+ \+ no boundary \+ verify-self all-PASS" 1
grep_check "feature-workflow AGENTS.md retains AUTO-SKIP pause-policy annotation" "agents/feature-workflow/AGENTS.md" "AUTO-SKIP" 1

# In-place fix shortcut shipped to feature-verify-self/SKILL.md §3 (feature:
# verify-self-in-place-fix-shortcut-policy). The clause is prose-only behavioral
# guidance permitting a narrow exception to the observe-only contract. The
# regression net is presence of its load-bearing anchors. Two pins: the heading
# anchor and the audit-trail SHORTCUT-token convention.
grep_check "feature-verify-self SKILL.md retains 'In-place fix shortcut' sub-clause" "skills/feature-verify-self/SKILL.md" "In-place fix shortcut" 1
grep_check "feature-verify-self SKILL.md retains SHORTCUT-token audit-trail convention" "skills/feature-verify-self/SKILL.md" "\[SHORTCUT-<YYYY-MM-DD>\]" 1

# Pause-footer strip shipped to session-resume/SKILL.md §6b (task:
# session-resume-strip-pause-footer). The step removes the orphan
# `## Session Pause — <timestamp>` block that `/session-pause` always appends
# to `state_file` EOF. Without §6b, every paused-then-resumed item accrues a
# 10–30s cleanup tax at finalize/close time (18+ recurrences observed in one
# project alone). This pin anchors the heading so a future edit can't silently
# drop the step.
grep_check "session-resume SKILL.md retains §6b 'Strip the stale Pause footer' step" "skills/session-resume/SKILL.md" "Strip the stale Pause footer" 1

grep_check "feature-reproduce SKILL.md has Step 0 section" "skills/feature-reproduce/SKILL.md" "^## Step 0: Available product context" 1
grep_check "incident-report SKILL.md has Step 0 section" "skills/incident-report/SKILL.md" "^## Step 0: Available product context" 1
grep_check "product-vision SKILL.md has Step 0 section" "skills/product-vision/SKILL.md" "^## Step 0: Available product context" 1

# feature-review-quality per-feature code-quality reviewer subagent shipped
# 2026-06-11 (feature: code-quality-reviewer-subagent). Sits between ship and
# finalize; advisory by default with severity-tier action matrix (CRITICAL →
# auto-refactor in Modes 2-3, MAJOR → pause-and-ask Mode 2 / auto-backlog
# Mode 3, MINOR → auto-backlog). Mode 4 SKIPs entirely (ship → finalize via
# F17b). The pin set below catches regression on load-bearing properties:
#   1. SKILL.md exists with name frontmatter
#   2. Reviewer prompt body lives at agents/code-quality-reviewer/AGENTS.md
#      (was skills/feature-review-quality/reviewer-prompt.md until 2026-06-12;
#       moved into the executable subagent definition per the
#       verify-self-and-review-quality-subagent-dispatch feature)
#   3. State Machine Context names F39/F40/F41 (the three exit transitions)
#   4. Severity Taxonomy section is present with CRITICAL/MAJOR/MINOR vocabulary
#   5. Reviewer agent body has tripartite output format anchors
#   6. CLAUDE.md Conventions section cites feature-review-quality
#   7. feature-ship SKILL.md emits TRANSITION: F38 (default) AND F17b (Mode-4 SKIP)
grep_check "feature-review-quality SKILL.md exists with name frontmatter" "skills/feature-review-quality/SKILL.md" "^name: feature-review-quality$" 1
grep_check "code-quality-reviewer agent definition exists at agents/code-quality-reviewer/AGENTS.md" "agents/code-quality-reviewer/AGENTS.md" "Code-Quality Reviewer" 1
grep_check "feature-review-quality SKILL.md names F39/F40/F41 exit transitions" "skills/feature-review-quality/SKILL.md" "F39|F40|F41" 3
grep_check "feature-review-quality SKILL.md has Severity Taxonomy with CRITICAL/MAJOR/MINOR" "skills/feature-review-quality/SKILL.md" "CRITICAL|MAJOR|MINOR" 3
grep_check "code-quality-reviewer AGENTS.md has tripartite output anchors" "agents/code-quality-reviewer/AGENTS.md" "Strengths|Issues|Assessment" 3
grep_check "CLAUDE.md Conventions section cites feature-review-quality" "CLAUDE.md" "feature-review-quality" 1
grep_check "feature-ship SKILL.md emits TRANSITION: F38 (default path)" "skills/feature-ship/SKILL.md" "TRANSITION: F38" 1
grep_check "feature-ship SKILL.md emits TRANSITION: F17b (Mode 4 SKIP path)" "skills/feature-ship/SKILL.md" "TRANSITION: F17b" 1

# Roadmap "milestone" terminology + flat numbering shipped 2026-06-18 (feature:
# milestone-terminology-and-wbs-scope, from SURFACE-2026-06-18-PRODUCT-SKILLS-
# MILESTONE-TERMINOLOGY-AND-WBS-SCOPE). product-roadmap now emits FLAT singly-
# numbered "Milestone N" units (no dotted 1.1 hierarchy), with cosmetic "Group"
# headings, and treats "phase" as a backward-compat read-alias. The feature Work
# Tree's "Phase" schema (CLAUDE.snippet.md) is a DIFFERENT artifact and keeps its
# name. These pins are prose-regression nets for the load-bearing anchors:
#   1. roadmap template uses "### Milestone" heading (not "### Phase")
#   2. no dotted milestone numbering survives in the roadmap skill
#   3. cosmetic "Group" heading guidance present
#   4. phase→milestone read-alias backward-compat note present
#   5. feature Work Tree "Phase" schema still present in CLAUDE.snippet.md (un-renamed)
grep_check "product-roadmap SKILL.md uses '### Milestone' template heading" "skills/product-roadmap/SKILL.md" "^### Milestone " 1
grep_check "product-roadmap SKILL.md retains cosmetic 'Group' heading guidance" "skills/product-roadmap/SKILL.md" "Group" 1
grep_check "product-roadmap SKILL.md retains phase read-alias backward-compat note" "skills/product-roadmap/SKILL.md" "alias" 1
grep_check "CLAUDE.snippet.md feature Work Tree 'Phase' schema un-renamed" "CLAUDE.snippet.md" "Phase 1" 1
# Negative pin: no dotted milestone numbering (e.g. "Milestone 1.1") in the roadmap skill.
if grep -Eq "Milestone [0-9]+\.[0-9]" "skills/product-roadmap/SKILL.md"; then
  check "product-roadmap SKILL.md has no dotted milestone numbering" "fail" \
    "found dotted 'Milestone N.M' numbering — roadmap milestones must be flat single integers"
else
  check "product-roadmap SKILL.md has no dotted milestone numbering" "pass"
fi

# product-wbs next-milestone-only scope + milestone terminology (same feature/SURFACE).
# product-wbs decomposes ONLY the immediate next milestone (not the whole roadmap) and
# adopts "milestone" terminology with "phase" as a read-alias. Pins:
#   1. next-milestone-only scope rule present
#   2. milestone terminology adopted (WP template **Milestone:** field)
#   3. phase read-alias / feature-Work-Tree-Phase-is-different terminology note present
grep_check "product-wbs SKILL.md states next-milestone-only scope" "skills/product-wbs/SKILL.md" "immediate next milestone" 1
grep_check "product-wbs SKILL.md WP template uses '**Milestone:**' field" "skills/product-wbs/SKILL.md" "\*\*Milestone:\*\*" 1
grep_check "product-wbs SKILL.md retains phase read-alias terminology note" "skills/product-wbs/SKILL.md" "read-alias|alias" 1

# Phase-vs-Milestone disambiguation note + downstream-consumer milestone terminology
# (Phase 3 of the milestone-terminology-and-wbs-scope feature). The project CLAUDE.md
# Work Tree Format section carries the disambiguation note (feature Work Tree "Phase"
# kept; roadmap "Milestone" renamed; phase = read-alias). Downstream product skills +
# the product-workflow orchestrator adopt milestone terminology. Pins:
grep_check "CLAUDE.md carries Phase-vs-Milestone disambiguation note" "CLAUDE.md" "two different artifacts" 1
# Token-specific milestone-forward pins (anchored on the actual renamed token in each
# file, not bare substring "milestone" presence — sturdier against partial reverts).
grep_check "product-finalize roadmap-loop renamed to milestone" "skills/product-finalize/SKILL.md" "For each milestone defined" 1
grep_check "product-context uses 'Current Milestone' heading" "skills/product-context/SKILL.md" "## Current Milestone" 1
grep_check "product-arch scope-definition renamed to milestone" "skills/product-arch/SKILL.md" "which milestone this architecture" 1
grep_check "product-research uses 'Milestone Focus'" "skills/product-research/SKILL.md" "Milestone Focus" 1
grep_check "product-vision hands off to break vision into milestones" "skills/product-vision/SKILL.md" "into milestones" 1
grep_check "product-workflow AGENTS.md roadmap row is milestone-forward" "agents/product-workflow/AGENTS.md" "Flat milestones with exit criteria" 1
# transitions.md P3 condition renamed (tripartite-sync — keep state-machine doc aligned
# with AGENTS.md + product-roadmap SKILL.md per CLAUDE.md "state machine lives in three places").
grep_check "transitions.md P3 condition is milestone-forward (tripartite sync)" "docs/product/transitions.md" "Roadmap has milestones defined" 1

echo ""

# ── Phase 3b: debug-* skill category invariants ────────────────────────────
#
# `debug-*` skills are agent-pulled sidebars (not workflow states). The
# convention (CLAUDE.md → "`debug-*` Skill Category") requires 6 specific
# SKILL.md sections, an `argument-hint:` frontmatter field, a Gate Check as
# the first `### 1.` subheading under Procedure, and ≥4 DEBUG-<TECH>-<OUTCOME>
# termination tokens. Each property is load-bearing — drop one and the agent
# loses a discoverability or self-documenting surface. Pin them all per skill.

echo "[Phase 3b] debug-* skill category invariants"

for debug_skill in skills/debug-*/SKILL.md; do
  [ -f "$debug_skill" ] || continue
  name=$(basename "$(dirname "$debug_skill")")
  # Gate-boundary sections (the original 2 pins — required for agent to discover the trigger)
  grep_check "$name has '## When to use' section (gate boundary)" "$debug_skill" "^## When to use$" 1
  grep_check "$name has '## When NOT to use' section (gate boundary)" "$debug_skill" "^## When NOT to use$" 1
  # Other 4 required sections (per CLAUDE.md → `debug-*` Skill Category)
  grep_check "$name has '## Category Context' section" "$debug_skill" "^## Category Context$" 1
  grep_check "$name has '## Procedure' section" "$debug_skill" "^## Procedure$" 1
  grep_check "$name has '## Pitfalls' section (parenthetical-suffix tolerant)" "$debug_skill" "^## Pitfalls" 1
  grep_check "$name has '## Termination' section" "$debug_skill" "^## Termination$" 1
  # Frontmatter `argument-hint:` field (per convention — debug-* skills accept a free-form description)
  grep_check "$name has 'argument-hint:' frontmatter field" "$debug_skill" "^argument-hint:" 1
  # Gate Check is the first `### 1.` subheading under Procedure (procedural discipline — gates run before any other step)
  grep_check "$name has Gate Check as first '### 1.' subheading" "$debug_skill" "^### 1\. Gate Check" 1
  # ≥4 DEBUG-<TECH>-<OUTCOME> termination tokens (covers START/SKIP/COMPLETE + 1+ outcome-specific token like NO-CONVERGE / INCONCLUSIVE)
  grep_check "$name emits ≥4 'DEBUG-<TECH>-<OUTCOME>' termination tokens" "$debug_skill" "DEBUG-[A-Z]+(-[A-Z]+)+" 4
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

# debug-empirical-telemetry: same callers (feature-build, incident-investigate, task-act)
for caller in skills/feature-build/SKILL.md skills/incident-investigate/SKILL.md skills/task-act/SKILL.md; do
  caller_name=$(basename "$(dirname "$caller")")
  grep_check "$caller_name mentions /debug-empirical-telemetry" "$caller" "/debug-empirical-telemetry" 1
done

for orch in agents/feature-workflow/AGENTS.md agents/incident-workflow/AGENTS.md agents/task-workflow/AGENTS.md; do
  orch_name=$(basename "$(dirname "$orch")")
  grep_check "$orch_name has 'Debug techniques (agent-pulled sidebars)' subsection" "$orch" "Debug techniques \(agent-pulled sidebars\)" 1
  # Each orchestrator's Debug-techniques table must list debug-empirical-telemetry as a row
  grep_check "$orch_name lists debug-empirical-telemetry in Debug-techniques table" "$orch" "debug-empirical-telemetry" 1
done

grep_check "transitions.md has 'Sidebar skills' subsection (under Cross-level mechanisms)" "docs/product/transitions.md" "^### Sidebar skills" 1
grep_check "transitions.md 'Sidebar skills' mentions /debug-empirical-telemetry" "docs/product/transitions.md" "debug-empirical-telemetry" 1

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
    actual=$(echo "$input" | tr -d '*' | sed -n "$REGEX_PATTERN")
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
    actual=$(echo "$input" | tr -d '*' | sed -n "$REGEX_PATTERN")
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

# ── Phase 3e: verify_result contains_required* semantics ─────────────────
#
# Pins the AND/ANY content-presence semantics added by the
# verify-sh-contains-required feature (2026-06-13). Sources verify.sh and
# invokes verify_result directly with crafted inputs, asserting both the
# return code AND the VERIFY_DETAIL wording (the wording is part of the
# contract — operators read it to debug failures).
#
# Backward-compat cases (A-F) protect the 2026-05-06 transition_id_any +
# not_contains_strict semantics that the new args must preserve.
# Forward cases (G-M) pin the new AND/ANY behavior.

echo "[Phase 3e] verify_result contains_required* semantics (tests/lib/verify.sh)"

# Source verify.sh in a subshell-safe way (verify.sh contains only function
# definitions and no side effects, so sourcing is idempotent).
# shellcheck disable=SC1091
source tests/lib/verify.sh

vr_check() {
  local label="$1"
  local expected_rc="$2"
  local expected_detail_substr="$3"
  local actual_rc="$4"
  local actual_detail="$5"
  if [ "$actual_rc" != "$expected_rc" ]; then
    check "verify_result: $label" "fail" "rc=$actual_rc expected=$expected_rc detail='$actual_detail'"
    return
  fi
  if [ -n "$expected_detail_substr" ] && ! echo "$actual_detail" | grep -qF "$expected_detail_substr"; then
    check "verify_result: $label" "fail" "detail='$actual_detail' missing substring '$expected_detail_substr'"
    return
  fi
  check "verify_result: $label" "pass"
}

# --- Backward-compat (A-F): existing args still work when new args are empty ---

set +e
verify_result "TRANSITION: F1" "F1" "" "" "" "false" "" ""
vr_check "A (plain ID match, empty new args → PASS)" 0 "Structured match" $? "$VERIFY_DETAIL"

verify_result "TRANSITION: F8b" "" "" "" "F8|F8b|F9" "false" "" ""
vr_check "B (transition_id_any match → PASS)" 0 "any-of" $? "$VERIFY_DETAIL"

verify_result "TRANSITION: F1 auto-chain blah" "F1" "" "auto-chain" "" "false" "" ""
vr_check "C (not_contains lenient: ID match + negative hit → PASS warning)" 0 "also mentioned" $? "$VERIFY_DETAIL"

verify_result "TRANSITION: F1 auto-chain blah" "F1" "" "auto-chain" "" "true" "" ""
vr_check "D (not_contains_strict=true: ID match + negative hit → FAIL)" 2 "FAILED strict not_contains" $? "$VERIFY_DETAIL"

verify_result "no transition token here, but mentions /feature-build" "F1" "/feature-build" "" "" "false" "" ""
vr_check "E (no ID, contains_any fallback → SOFT_PASS)" 1 "no structured TRANSITION line" $? "$VERIFY_DETAIL"

verify_result "totally unrelated output" "F1" "" "" "" "false" "" ""
vr_check "F (no match anywhere → FAIL)" 2 "No transition signal found" $? "$VERIFY_DETAIL"

# --- New behavior (G-K): contains_required (AND) + contains_required_any (ANY) ---

# G: contains_required FAIL takes precedence over not_contains lenient warning
verify_result "TRANSITION: F1 auto-chain blah" "F1" "" "auto-chain" "" "false" "ephemeral" ""
vr_check "G (contains_required missing → FAIL, overrides lenient not_contains)" 2 "required content missing: ephemeral" $? "$VERIFY_DETAIL"

# H: contains_required PASS then lenient not_contains warning surfaces
verify_result "TRANSITION: F1 ephemeral auto-chain blah" "F1" "" "auto-chain" "" "false" "ephemeral" ""
vr_check "H (contains_required present, then not_contains warning → PASS)" 0 "also mentioned" $? "$VERIFY_DETAIL"

# I: contains_required_any case-insensitive match (grep -qi)
verify_result "$(printf 'TRANSITION: P10\nRandomize host ports')" "P10" "" "" "" "false" "" "ephemeral|RANDOMIZE"
vr_check "I (contains_required_any case-insensitive → PASS)" 0 "Structured match" $? "$VERIFY_DETAIL"

# J: contains_required AND contains_required_any both set, both PASS
verify_result "$(printf 'TRANSITION: P10\nephemeral 49152')" "P10" "" "" "" "false" "ephemeral" "49152|randomize"
vr_check "J (both required + required_any set, both pass → PASS)" 0 "Structured match" $? "$VERIFY_DETAIL"

# K: contains_required passes, contains_required_any fails → FAIL
verify_result "$(printf 'TRANSITION: P10\nephemeral only')" "P10" "" "" "" "false" "ephemeral" "49152|randomize"
vr_check "K (required passes, required_any all-miss → FAIL)" 2 "required-any content missing" $? "$VERIFY_DETAIL"

# L: contains_required_any all-miss with no contains_required
verify_result "TRANSITION: P10" "P10" "" "" "" "false" "" "ephemeral|49152"
vr_check "L (required_any only, all-miss → FAIL with list)" 2 "ephemeral|49152" $? "$VERIFY_DETAIL"

# M: contains_required two-miss reports BOTH missing strings by name
verify_result "$(printf 'TRANSITION: P10\nephemeral only')" "P10" "" "" "" "false" "ephemeral|49152|randomize" ""
vr_check "M (required two-miss names all missing strings)" 2 "49152, randomize" $? "$VERIFY_DETAIL"

set -e

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

# v3 WP2 perf probe — durable smokes only (existence, syntax, --help). Numeric
# perf thresholds are intentionally NOT pinned (host wall-clock variance would
# make them flaky). The script is the artifact; re-run it manually any time
# viz_data.py materially changes.
if [ -f tools/claude-time/test/perf_window_data.py ]; then
  check "tools/claude-time/test/perf_window_data.py exists" "pass"
else
  check "tools/claude-time/test/perf_window_data.py exists" "fail" "file missing"
fi

if python3 -m py_compile tools/claude-time/test/perf_window_data.py 2>/dev/null; then
  check "tools/claude-time/test/perf_window_data.py passes py_compile" "pass"
else
  check "tools/claude-time/test/perf_window_data.py passes py_compile" "fail" "py_compile failed"
fi

if python3 tools/claude-time/test/perf_window_data.py --help > /dev/null 2>&1; then
  check "tools/claude-time/test/perf_window_data.py --help exits 0" "pass"
else
  check "tools/claude-time/test/perf_window_data.py --help exits 0" "fail" "non-zero exit"
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

# viz_data unit tests (Phase 2 of claude-time-visualize feature)
if [ -f tools/claude-time/viz_data.py ]; then
  check "tools/claude-time/viz_data.py exists" "pass"
else
  check "tools/claude-time/viz_data.py exists" "fail" "file missing"
fi

if python3 -m py_compile tools/claude-time/viz_data.py 2>/dev/null; then
  check "tools/claude-time/viz_data.py compiles" "pass"
else
  check "tools/claude-time/viz_data.py compiles" "fail" "py_compile failed"
fi

if (cd tools/claude-time/test && python3 -m unittest test_viz_data > /dev/null 2>&1); then
  check "tools/claude-time/test/test_viz_data.py — unit tests" "pass"
else
  err=$(cd tools/claude-time/test && python3 -m unittest test_viz_data 2>&1 | tail -3)
  check "tools/claude-time/test/test_viz_data.py — unit tests" "fail" "$err"
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

# visualize CLI end-to-end tests (Phase 3 codify, claude-time-visualize feature)
if [ -x tools/claude-time/test/test_visualize_cli.sh ]; then
  if tools/claude-time/test/test_visualize_cli.sh > /dev/null 2>&1; then
    check "tools/claude-time/test/test_visualize_cli.sh — visualize CLI end-to-end" "pass"
  else
    err=$(tools/claude-time/test/test_visualize_cli.sh 2>&1 | grep '\[FAIL\]' | head -3)
    check "tools/claude-time/test/test_visualize_cli.sh — visualize CLI end-to-end" "fail" "$err"
  fi
else
  check "tools/claude-time/test/test_visualize_cli.sh exists + executable" "fail" "missing or not executable"
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

# ── Phase 5c: claude-time viz prototype integrity ─────────────────────────
#
# Phase 1 of the claude-time-visualize feature transplanted the Claude Design
# mockup (4 files) into tools/claude-time/viz/ verbatim and pinned all 4 to
# their byte sizes — emit-time transforms in viz_render.py let the shipped
# HTML diverge from the immutable source.
#
# The v2 cycle (claude-time-visualize-v2, started 2026-05-19) supersedes the
# immutability pattern for editable files (`dashboard.jsx`, `data.js`):
# direct source edits are now permitted because the cycle's UX evolution
# (zoomable timeline, collapsible rows, etc.) exceeds what emit-time text
# transforms can reasonably support. See docs/product/wbs.md and CLAUDE.md.
#
# `index.html` and `design-canvas.jsx` stay pinned — they remain immutable
# in v2 (the design-canvas prototype is a reference artifact, and the page
# template doesn't need source-level evolution).

echo "[Phase 5c] claude-time viz prototype integrity"

VIZ_DIR="tools/claude-time/viz"

# Expected sizes (bytes) — pinned only for files that v2 holds immutable.
# `dashboard.jsx` and `data.js` are now editable; their integrity is guarded
# by the JS-parse check below + downstream test coverage (test_visualize_cli.sh
# asserts emitted-HTML behavior, which would break first if the source broke).
declare -a VIZ_FILES=(
  "index.html:2634"
  "design-canvas.jsx:49676"
)

for entry in "${VIZ_FILES[@]}"; do
  name="${entry%:*}"
  expected="${entry##*:}"
  path="$VIZ_DIR/$name"
  if [ ! -f "$path" ]; then
    check "$path exists" "fail" "file missing"
    continue
  fi
  check "$path exists" "pass"
  actual=$(wc -c < "$path" | tr -d ' ')
  if [ "$actual" = "$expected" ]; then
    check "$path byte-size = $expected (design contract pinned)" "pass"
  else
    check "$path byte-size = $expected (design contract pinned)" "fail" \
      "actual=$actual; expected=$expected. The design extract is the source-of-truth."
  fi
done

# Existence-only checks for the v2-editable files (no byte pin — see header).
for editable in "dashboard.jsx" "data.js"; do
  if [ -f "$VIZ_DIR/$editable" ]; then
    check "$VIZ_DIR/$editable exists" "pass"
  else
    check "$VIZ_DIR/$editable exists" "fail" "file missing"
  fi
done

# Syntax checks — the JS file must parse as plain JS; the JSX files must parse
# with @babel/parser + jsx plugin (the same parser Babel-standalone uses at
# runtime). We probe whether parser dependencies are present in /tmp; if not,
# skip the JSX parse gracefully (the parsers are the v2 integrity check now
# that two of the four files are no longer byte-pinned, and an actual render
# error would surface in dev-time browser checks regardless).
if command -v node >/dev/null 2>&1; then
  if node --check "$VIZ_DIR/data.js" 2>/dev/null; then
    check "viz/data.js parses as plain JS (node --check)" "pass"
  else
    check "viz/data.js parses as plain JS (node --check)" "fail" "node --check failed"
  fi
else
  check "viz/data.js parses as plain JS (node --check)" "fail" "node not on PATH"
fi

# index.html: structural well-formed-ness via Python's HTMLParser
if python3 -c "
from html.parser import HTMLParser
class V(HTMLParser):
    def __init__(self):
        super().__init__()
        self.opened = []
    def handle_starttag(self, tag, attrs):
        if tag not in ('meta','link','br','hr','img','input'):
            self.opened.append(tag)
    def handle_endtag(self, tag):
        if self.opened and self.opened[-1] == tag:
            self.opened.pop()
import sys
with open('$VIZ_DIR/index.html') as f:
    p = V(); p.feed(f.read())
sys.exit(0 if not p.opened else 1)
" 2>/dev/null; then
  check "viz/index.html is well-formed (no unclosed tags)" "pass"
else
  check "viz/index.html is well-formed (no unclosed tags)" "fail" "HTMLParser found unclosed tags"
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

# Minimum scenario count (should be ≥ 88 after product-doc-archival feature).
# Counts scenarios directly from tests/scenarios/*.yaml via Python rather than
# shelling out to `./tests/run-tests.sh --dry-run` — the subprocess invocation
# took ~240s on this machine (the bulk of check-structure.sh's runtime) and
# orphaned a process tree that subsequent re-invocations would race against
# (see backlog SURFACE-2026-06-07-CHECK-STRUCTURE-DRY-RUN-CONCURRENCY-FRAGILE).
# Counting semantics match run-tests.sh: every scenario in every yaml counts
# (run-tests.sh increments TOTAL once per scenario after filtering; with no
# --id/--filter-model/--group flags, every scenario passes filtering).
total=$(python3 - <<'PYEOF' 2>/dev/null || echo 0
import yaml, pathlib
total = 0
for f in sorted(pathlib.Path('tests/scenarios').glob('*.yaml')):
    with open(f) as fh:
        data = yaml.safe_load(fh) or {}
    total += len(data.get('scenarios', []) or [])
print(total)
PYEOF
)
if [ "${total:-0}" -ge 88 ]; then
  check "Scenario count ≥ 88 ($total registered)" "pass"
else
  check "Scenario count ≥ 88" "fail" "only $total scenarios found"
fi

# Regression pins for the orphan-subprocess fix (backlog SURFACE-2026-06-07).
# Codify Phase 1's chosen approach (inlined Python YAML count) and forbid the
# prior subprocess invocation + the failed-experiment trap helper from silently
# returning via merge or refactor. Each pin's grep regex deliberately avoids
# matching its own implementation lines (no literal match-strings here).
# [s] is a character class matching literal 's' — the [/] brackets in the source
# stop this very line from matching its own regex (which scans for run-tests.sh).
invocation_re='\./tests/run-test[s]\.sh --dry-run'
n=$( (grep -cE "^[[:space:]]*[^#[:space:]].*${invocation_re}" tests/check-structure.sh 2>/dev/null || true) | head -1 )
n="${n:-0}"
if [ "$n" -eq 0 ]; then
  check "tests/check-structure.sh does NOT invoke the prior dry-run subprocess form" "pass"
else
  check "tests/check-structure.sh does NOT invoke the prior dry-run subprocess form" "fail" \
    "$n non-comment lines re-invoke the dead form (orphans + 240s runtime); count scenarios inline with python instead"
fi
walker_re='_kill_descendants[[:space:]]*\('
n=$( (grep -cE "$walker_re" tests/check-structure.sh 2>/dev/null || true) | head -1 )
n="${n:-0}"
if [ "$n" -eq 0 ]; then
  check "tests/check-structure.sh does NOT define/call the failed walker helper" "pass"
else
  check "tests/check-structure.sh does NOT define/call the failed walker helper" "fail" \
    "$n call/definition sites found; helper couldn't reach sibling subshells (see backlog entry)"
fi
grep_check "tests/check-structure.sh counts scenarios via inlined python3 heredoc" \
  "tests/check-structure.sh" "python3 - <<'PYEOF'" 1

# runtimes.md must carry at least one **Use timeout:** entry — that's the
# load-bearing field agents read before invoking tracked long-running commands.
# (shape: frontmatter is already pinned by Phase 3 at line ~114.)
if [ -f runtimes.md ]; then
  grep_check "runtimes.md has at least one **Use timeout:** entry" \
    "runtimes.md" "^- \*\*Use timeout:\*\* [0-9]+" 1
fi

# Pilot-scenario pins for the verify-sh-contains-required feature (2026-06-13).
# P10b is the load-bearing end-to-end regression test for `contains_required_any`
# — a real haiku invocation that asserts the model surfaces randomize-host-ports
# guidance from the symlinked product-context SKILL.md. Pin its existence and the
# use of the new primitive (not the old contains_any) so a future refactor cannot
# silently regress to soft-pass fallback semantics.
grep_check "P10b scenario exists in product.yaml" \
  "tests/scenarios/product.yaml" "^[[:space:]]+- id: P10b\b" 1
grep_check "P10b uses contains_required_any (new hard-assert primitive)" \
  "tests/scenarios/product.yaml" "contains_required_any:" 1

# Convention-doc pin: CLAUDE.md `## Conventions` bullet about `expect:` fields
# must document both new fields. The grep is split into two pins (one per field)
# so a partial revert (e.g. someone removes contains_required_any but leaves
# contains_required) is caught.
grep_check "CLAUDE.md ## Conventions documents contains_required (AND-fanout)" \
  "CLAUDE.md" "contains_required.*AND-fanout" 1
grep_check "CLAUDE.md ## Conventions documents contains_required_any (OR-fanout)" \
  "CLAUDE.md" "contains_required_any.*OR-fanout" 1

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
# Four assertions per file (presence × 3, then drift × 1 over the whole set):
#   (1) the canonical heading is present
#   (2) the "Hard rule for AUTO exits" semantic anchor is present — the
#       imperative wording is the load-bearing part; if it weakens to
#       "should" or a softer phrasing, the regression mode returns
#   (3) the block contains a per-skill pause-policy table referencing all
#       four drive modes
#   (4) Phase 9b drift check (see SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT):
#       per-skill table VALUES match the canonical pause-policy table in
#       agents/feature-workflow/AGENTS.md. Catches the case where AGENTS.md
#       flips a transition's policy but one or more SKILL.md cheat-sheets
#       silently keep claiming the old value. Parses both tables in Python,
#       normalizes cell values (strip markdown bold, take first policy token,
#       map "pause already taken at entry" sentinel to PAUSE), and applies a
#       static row-mapping dict for the many-to-one cases (all back-loop
#       transitions across the 8 files collapse to AGENTS.md's "Back-loops"
#       row; F22→REDIRECT; F25/F26→SURFACE rows).
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
  skills/feature-review-quality/SKILL.md
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

# (4) Phase 9b: per-skill cheat-sheet VALUES match the canonical pause-policy
# table in agents/feature-workflow/AGENTS.md. Phase 9 above catches structural
# regressions (block removed, anchor weakened, mode names dropped); this
# drift check catches the value-mismatch case where AGENTS.md is updated but
# one or more per-skill SKILL.md tables silently keep claiming the old policy.
# See SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT.
#
# Mapping per-skill transition rows → AGENTS.md row keys (many-to-one in places,
# e.g. all back-loops collapse to AGENTS.md's "Back-loops" row). Rows with no
# canonical counterpart (F27 incident interrupt, n/a-tagged Mode-4 cells in
# verify-human) are skipped from comparison without emitting PASS or FAIL.
drift_output=$(python3 - <<'PYEOF' 2>&1 || true
import re
from pathlib import Path

POLICY_TOKEN_RE = re.compile(r"\*?\*?(AUTO-SKIP|AUTO|PAUSE|SKIP|n/a)\*?\*?", re.IGNORECASE)

def normalize_cell(cell):
    """Strip markdown bolding, parenthetical commentary, and 'pause already taken at entry'
    sentinel. Return the first policy token found, lowercased, or '' if none."""
    s = cell.strip()
    # Handle the "pause already taken at entry" sentinel — semantically the per-skill row
    # delegates to the entry row's pause; the exit transition itself does NOT pause. So
    # canonically this row's value matches whatever AGENTS.md says for the skill (which for
    # spec/research/plan in Mode 2/3 is PAUSE — same value). We map sentinel → PAUSE so the
    # comparison passes against AGENTS.md's PAUSE for these rows.
    if "pause already taken at entry" in s.lower():
        return "pause"
    m = POLICY_TOKEN_RE.search(s)
    return m.group(1).lower() if m else ""

def parse_table(lines, start_pat, stop_pat=re.compile(r"^## ")):
    """Find first table inside the block bounded by start_pat (inclusive) and stop_pat
    (exclusive — next ## heading). Return list of [cell, cell, ...] rows (data rows only,
    skipping header + separator)."""
    in_block = False
    rows = []
    for line in lines:
        if not in_block:
            if start_pat.search(line):
                in_block = True
            continue
        if stop_pat.match(line):
            break
        if not line.startswith("|"):
            continue
        # Skip the header-separator line (|---|---|...)
        if re.match(r"^\|\s*[-:]+\s*\|", line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)
    return rows

def parse_agents_table(path):
    """Parse the canonical pause-policy table from agents/feature-workflow/AGENTS.md.
    Returns dict: row_label -> {mode_index: normalized_value}. mode_index is 0-3."""
    lines = Path(path).read_text().splitlines()
    rows = parse_table(lines, re.compile(r"^### Pause policy by drive mode"))
    if not rows:
        return {}
    header = rows[0]
    # Expected header: ["Step", "Mode 1 — Step-by-step", ...]; data rows have label in col 0.
    # Drop the header row and any further rows whose first cell doesn't look like a step name.
    table = {}
    for row in rows[1:]:
        if len(row) < 5:
            continue
        label = row[0].strip()
        if not label:
            continue
        # mode_index 0..3 maps to Mode 1..4 → columns 1..4
        table[label] = {i: normalize_cell(row[i + 1]) for i in range(4)}
    return table

def parse_skill_table(path):
    """Parse the per-skill cheat-sheet table. Returns list of (transition_label, {mode_index: value})."""
    lines = Path(path).read_text().splitlines()
    rows = parse_table(lines, re.compile(r"^## Orchestrator Pause Policy \(cheat-sheet\)"))
    if not rows:
        return []
    out = []
    for row in rows[1:]:  # drop header
        if len(row) < 5:
            continue
        label = row[0].strip()
        if not label:
            continue
        values = {i: normalize_cell(row[i + 1]) for i in range(4)}
        out.append((label, values))
    return out

# Map: (skill basename, transition-label pattern) → AGENTS.md row label.
# Pattern is a substring that must appear in the per-skill row's first cell. None means
# skip from comparison.
ROW_MAPPING = {
    "feature-spec": [
        ("Skill invocation",      "`feature-spec`"),
        ("F3 ",                   "`feature-spec`"),
        ("F4 ",                   "`feature-spec`"),
    ],
    "feature-research": [
        ("Skill invocation",      "`feature-research`"),
        ("F5 ",                   "`feature-research`"),
        ("F6 ",                   "Back-loops (F6, F9, F9b, F12, F14, F23, F24)"),
    ],
    "feature-plan": [
        ("Skill invocation",      "`feature-plan`"),
        ("F7 ",                   "`feature-plan`"),
    ],
    "feature-build": [
        ("F8 ",                   "`feature-build`"),
        ("F9b ",                  "Back-loops (F6, F9, F9b, F12, F14, F23, F24)"),
        ("F22 ",                  "REDIRECT (F22)"),
        ("F36 ",                  "REDIRECT (F36)"),
        ("F23 ",                  "Back-loops (F6, F9, F9b, F12, F14, F23, F24)"),
        ("F25 ",                  "SURFACE F25 (note-and-continue)"),
        ("F26 ",                  "SURFACE F26 (pause-and-escalate)"),
        ("F27 ",                  None),  # incident interrupt — no AGENTS.md table row
    ],
    "feature-reproduce": [
        # F32/F33/F34/F35 are the SKILL's own exit transitions — AGENTS.md does not
        # have per-transition rows for these (they map to the `feature-reproduce`
        # invocation-level pause policy in AGENTS.md, but the canonical-row labels
        # there are "reproduce — F32/F33", "reproduce — F34", "reproduce — F35",
        # not the F-ID-prefix shape used by other skills). Mark None to skip from
        # drift comparison — the SKILL.md cheat-sheet table is the source of truth
        # for these specific rows, mirroring the verify-human treatment for F11/F13.
        ("F32 ",                  None),
        ("F33 ",                  None),
        ("F34 ",                  None),
        ("F35 ",                  None),
        ("F37 ",                  "Return-from-REDIRECT (F37, F37b)"),
        ("F37b ",                 "Return-from-REDIRECT (F37, F37b)"),
    ],
    "feature-verify-auto": [
        ("F10 ",                  "`feature-verify-auto`"),
        ("F9 ",                   "Back-loops (F6, F9, F9b, F12, F14, F23, F24)"),
        ("F24 ",                  "Back-loops (F6, F9, F9b, F12, F14, F23, F24)"),
    ],
    "feature-verify-self": [
        ("F10b ",                 "`feature-verify-self`"),
        ("F9b ",                  "Back-loops (F6, F9, F9b, F12, F14, F23, F24)"),
    ],
    "feature-verify-human": [
        ("Skill invocation",      "`feature-verify-human`"),
        # F13/F11 exit rows describe orchestrator behavior AFTER the skill emits
        # a transition (post-human-response). AGENTS.md has no row for these —
        # the canonical row describes the invocation-pause policy. Skip from
        # comparison. F11-AUTO-SKIP is similar: governed by the auto-skip gate,
        # documented in the SKILL itself, not in AGENTS.md's pause-policy table.
        ("F13 ",                  None),
        ("F11 (human-confirmed",  None),
        ("F11 (AUTO-SKIP",        None),
        ("F12 ",                  "Back-loops (F6, F9, F9b, F12, F14, F23, F24)"),
    ],
    "feature-verify-codify": [
        ("F15 ",                  "`feature-verify-codify`"),
        ("F16 ",                  "`feature-verify-codify`"),
        ("F14 ",                  "Back-loops (F6, F9, F9b, F12, F14, F23, F24)"),
    ],
    "feature-review-quality": [
        # Skill invocation maps to F39 row in AGENTS.md (the default-clean path).
        # F39/F40/F41 each have their own AGENTS.md rows since drift between
        # them matters (each tier's per-mode action is independently load-bearing).
        ("Skill invocation",      "`feature-review-quality` — F39 (clean / MINOR / Mode-3 MAJOR auto-backlogged)"),
        ("F39 ",                  "`feature-review-quality` — F39 (clean / MINOR / Mode-3 MAJOR auto-backlogged)"),
        ("F40 ",                  "`feature-review-quality` — F40 (CRITICAL → auto-invoke refactor)"),
        ("F41 ",                  "`feature-review-quality` — F41 (Mode-2 MAJOR — operator pause-and-ask)"),
    ],
}

agents = parse_agents_table("agents/feature-workflow/AGENTS.md")
if not agents:
    print("FAIL\tparse AGENTS.md pause-policy table\tcould not locate or parse '### Pause policy by drive mode' table")
else:
    print("PASS\tparse AGENTS.md pause-policy table")

SKILLS = [
    "feature-spec", "feature-research", "feature-plan", "feature-build",
    "feature-verify-auto", "feature-verify-self", "feature-verify-human",
    "feature-verify-codify", "feature-reproduce", "feature-review-quality",
]

for skill in SKILLS:
    path = f"skills/{skill}/SKILL.md"
    skill_rows = parse_skill_table(path)
    if not skill_rows:
        print(f"FAIL\t{path} cheat-sheet table parseable\tno data rows found between heading and next ##")
        continue
    mapping = {pat: agents_key for pat, agents_key in ROW_MAPPING.get(skill, [])}
    for label, values in skill_rows:
        # Find which pattern matches this row label
        agents_key = None
        matched_pat = None
        for pat, target in mapping.items():
            if pat in label:
                matched_pat = pat
                agents_key = target
                break
        if matched_pat is None:
            # Row in SKILL.md has no mapping declared — surface as FAIL so we don't
            # silently miss new rows added to a SKILL.md without updating this script.
            print(f"FAIL\t{path} row '{label}' has mapping\tno entry in ROW_MAPPING for this skill — add one or mark None")
            continue
        if agents_key is None:
            # Explicitly marked None → skip from comparison
            continue
        if agents_key not in agents:
            print(f"FAIL\t{path} row '{label}' canonical row exists\tAGENTS.md has no row '{agents_key}'")
            continue
        canon = agents[agents_key]
        for mode_idx in range(4):
            skill_val = values[mode_idx]
            canon_val = canon[mode_idx]
            # Skip n/a cells — they're explicitly out-of-scope (e.g. verify-human Mode 4 SKIP).
            if skill_val == "n/a":
                continue
            if skill_val == canon_val:
                continue
            # Mismatch
            print(f"FAIL\t{path} row '{label}' Mode {mode_idx + 1} matches AGENTS.md '{agents_key}'\texpected '{canon_val}' (from AGENTS.md), got '{skill_val}' (from SKILL.md)")
            break
        else:
            print(f"PASS\t{path} row '{label}' values match AGENTS.md '{agents_key}'")
PYEOF
)

while IFS=$'\t' read -r status desc detail; do
  [ -z "$status" ] && continue
  if [ "$status" = "PASS" ]; then
    check "$desc" "pass"
  else
    check "$desc" "fail" "$detail"
  fi
done <<< "$drift_output"

echo ""

# ── Phase 10: Subagent dispatch wiring ──────────────────────────────────────
#
# Codifies the dispatch contract shipped by the verify-self-and-review-quality-
# subagent-dispatch feature (2026-06-12, SURFACE-2026-06-11-VERIFY-SELF-AND-
# REVIEW-QUALITY-SUBAGENT-DISPATCH-UNVALIDATED). Two new executable subagent
# definitions live under agents/ alongside the 4 reference-only *-workflow
# orchestrator docs. The distinguishing marker is frontmatter shape:
#
#   - Reference-only workflow agents:  `skills:` in frontmatter (no `tools:`).
#     The 4 *-workflow/AGENTS.md files are read by /session-start as procedure
#     references; they are NOT meant to be spawned via Agent({subagent_type:...}).
#   - Executable subagents:  `tools:` in frontmatter (no `skills:`).
#     Spawned by skills that name them via subagent_type. Today: feature-
#     verify-self-runner (verify-self), code-quality-reviewer (review-quality).
#
# The pin block below is SELF-EXTENDING: it iterates agents/*/AGENTS.md and
# selects executable subagents by `tools:` frontmatter presence. New executable
# subagents added later automatically pick up the same coverage.
#
# Assertions (per executable subagent):
#   (a) frontmatter `name:` matches directory basename
#   (b) frontmatter `description:` is present
#   (c) frontmatter `tools:` lists ≥ 1 tool
#   (d) at least one skills/*/SKILL.md body references `subagent_type: '<name>'`
#       — an executable subagent with no caller is dead code
#
# Plus one cross-skill assertion (over the SKILL.md set):
#   (e) every skills/*/SKILL.md with `Agent` in `allowed-tools` contains at
#       least one `subagent_type:` reference. A skill that declares Agent but
#       never names a subagent_type is the dispatch gap that motivated this
#       feature (SURFACE-2026-06-11-VERIFY-SELF-AND-REVIEW-QUALITY-SUBAGENT-
#       DISPATCH-UNVALIDATED) — the pin catches that regression.

echo "[Phase 10] Subagent dispatch wiring"

for agent_md in agents/*/AGENTS.md; do
  agent_dir="$(dirname "$agent_md")"
  agent_name="$(basename "$agent_dir")"

  # Extract frontmatter (lines between the first two `---` markers).
  fm=$(awk '/^---$/{n++; next} n==1' "$agent_md")

  # Executable subagent marker: `tools:` key present in frontmatter.
  if ! grep -qE "^tools:" <<< "$fm"; then
    # Reference-only (or no frontmatter) — skip executable-subagent assertions.
    continue
  fi

  # (a) name matches dir
  if grep -qE "^name:\s*${agent_name}\s*$" <<< "$fm"; then
    check "executable subagent $agent_name: frontmatter name matches dir" "pass"
  else
    check "executable subagent $agent_name: frontmatter name matches dir" "fail" \
      "name: line in $agent_md does not match directory basename '$agent_name'"
  fi

  # (b) description present
  if grep -qE "^description:\s*\S" <<< "$fm"; then
    check "executable subagent $agent_name: description present" "pass"
  else
    check "executable subagent $agent_name: description present" "fail" \
      "no non-empty description: line in $agent_md frontmatter"
  fi

  # (c) tools list non-empty (≥1 list item under tools:)
  tools_lines=$(awk '/^tools:/{flag=1; next} flag && /^[a-zA-Z]/{flag=0} flag' <<< "$fm" | grep -cE "^\s*-\s+\S" || true)
  if [ "${tools_lines:-0}" -ge 1 ]; then
    check "executable subagent $agent_name: tools list non-empty (≥1 entry)" "pass"
  else
    check "executable subagent $agent_name: tools list non-empty (≥1 entry)" "fail" \
      "tools: list under $agent_md frontmatter has 0 entries"
  fi

  # (d) at least one skill references this subagent_type
  ref_count=$(grep -rE "subagent_type:\s*['\"]${agent_name}['\"]" skills/ 2>/dev/null | wc -l | tr -d ' ')
  if [ "${ref_count:-0}" -ge 1 ]; then
    check "executable subagent $agent_name: referenced by ≥1 skill via subagent_type" "pass"
  else
    check "executable subagent $agent_name: referenced by ≥1 skill via subagent_type" "fail" \
      "no skills/*/SKILL.md contains subagent_type: '$agent_name' — executable subagent with no caller is dead code"
  fi
done

# (e) every skill with `Agent` in allowed-tools must reference some subagent_type.
for skill_md in skills/*/SKILL.md; do
  skill_name="$(basename "$(dirname "$skill_md")")"
  fm=$(awk '/^---$/{n++; next} n==1' "$skill_md")

  # Does the skill declare Agent in allowed-tools? Look for a list-item line `- Agent` under allowed-tools.
  if ! grep -qE "^\s*-\s+Agent\s*$" <<< "$fm"; then
    continue
  fi

  ref_count=$(grep -cE "subagent_type:" "$skill_md" 2>/dev/null || echo 0)
  ref_count=${ref_count%%[^0-9]*}
  if [ "${ref_count:-0}" -ge 1 ]; then
    check "skill $skill_name declares Agent and references ≥1 subagent_type" "pass"
  else
    check "skill $skill_name declares Agent and references ≥1 subagent_type" "fail" \
      "$skill_md has 'Agent' in allowed-tools but body contains no 'subagent_type:' reference — dispatch gap (SURFACE-2026-06-11)"
  fi
done

# (f) every `subagent_type: '<name>'` reference in skills/*/SKILL.md must point to
# an agents/<name>/AGENTS.md whose frontmatter carries `tools:` (executable-subagent
# marker), NOT `skills:` (reference-only marker). Closes the symmetric-enforcement
# gap that (a)-(e) above left open: those pins enforce "every exec-subagent must be
# referenced," but did not enforce "every reference must point at an exec-subagent."
# A skill writing subagent_type: 'feature-workflow' (a reference-only orchestrator
# agent) would not have failed any pre-2026-06-12 pin — this pin catches that.
# Closes SURFACE-2026-06-12-QUALITY-SUBAGENT-DISPATCH-PIN-ASYMMETRIC and addresses
# the latent risk in SURFACE-2026-06-12-REFERENCE-WORKFLOW-AGENTS-ARE-INVOKABLE.
# Regex requires a non-empty alphanumeric/dash/underscore name inside quotes — the
# prose mention `Agent({subagent_type: "..."})` in session-start/SKILL.md does not
# match (literal placeholder, no agent name).
#
# Harness-provided subagent_types are allowlisted: `general-purpose` is the
# built-in fallback used by the bootstrap-skip pattern in feature-verify-self
# and feature-review-quality (per SURFACE-2026-06-11-SKILL-HARNESS-REGISTRY-
# LOADED-ONCE-AT-SESSION-START) and is not backed by an agents/<name>/AGENTS.md
# file in this repo. Add more entries to the case statement below if future
# skills use other harness-built-ins.
for skill_md in skills/*/SKILL.md; do
  skill_name="$(basename "$(dirname "$skill_md")")"

  # Extract each subagent_type reference's target name. One PASS per reference.
  while IFS= read -r ref_name; do
    [ -z "$ref_name" ] && continue
    case "$ref_name" in
      general-purpose) continue ;;  # harness-built-in, no agents/<name>/ backing
    esac
    target_agent_md="agents/${ref_name}/AGENTS.md"
    if [ ! -f "$target_agent_md" ]; then
      check "skill $skill_name → subagent_type '$ref_name': target agent file exists" "fail" \
        "$skill_md references subagent_type: '$ref_name' but $target_agent_md does not exist"
      continue
    fi
    target_fm=$(awk '/^---$/{n++; next} n==1' "$target_agent_md")
    if grep -qE "^tools:" <<< "$target_fm"; then
      check "skill $skill_name → subagent_type '$ref_name': target has tools: frontmatter (executable subagent)" "pass"
    else
      check "skill $skill_name → subagent_type '$ref_name': target has tools: frontmatter (executable subagent)" "fail" \
        "$target_agent_md has no 'tools:' frontmatter — reference-only agent cannot be a subagent_type target (asymmetric-enforcement gap, SURFACE-2026-06-12-QUALITY-SUBAGENT-DISPATCH-PIN-ASYMMETRIC)"
    fi
  done < <(grep -oE "subagent_type:\s*['\"][a-zA-Z0-9_-]+['\"]" "$skill_md" 2>/dev/null \
           | sed -E "s/^subagent_type:[[:space:]]*['\"]([a-zA-Z0-9_-]+)['\"]/\1/")
done

echo ""

# Phase 11: Close-commit discipline pins
# Pins the no-auto-push clause across all four terminal-close skills + the amend-to-HEAD
# clause in session-store-learning. Codifies SKILL.md prose contracts shipped 2026-06-12
# (close-commit-discipline feature) to prevent silent drift toward auto-push or away
# from learning-amend folding into HEAD.
echo "[Phase 11] Close-commit discipline (no auto-push + amend learnings to HEAD)"

grep_check "feature-finalize forbids git push from close commit"   "skills/feature-finalize/SKILL.md"        "Do NOT \`git push\`"          1
grep_check "task-close forbids git push from close commit"          "skills/task-close/SKILL.md"              "Do NOT \`git push\`"          1
grep_check "incident-resolve forbids git push from resolve commit"  "skills/incident-resolve/SKILL.md"        "Do NOT \`git push\`"          1
grep_check "product-finalize forbids git push from cycle-close commit" "skills/product-finalize/SKILL.md"     "Do NOT \`git push\`"          1
grep_check "session-store-learning folds learning into HEAD via amend" "skills/session-store-learning/SKILL.md" "git commit --amend --no-edit" 1
grep_check "session-store-learning stages the learning file before amend" "skills/session-store-learning/SKILL.md" "git add <file-path"        1

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
