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
grep_check "transitions.md has 'Entry-skill context loading' cross-level subsection" "workflow-system/product/transitions.md" "^### Entry-skill context loading" 1
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
grep_check "product-context SKILL.md adds container-down self-start instruction" "skills/product-context/SKILL.md" "[Ss]tart the container\(s\) yourself" 1

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

# Handoff-footer strip shipped to session-restore/SKILL.md §6b (originally the
# strip-pause-footer task; the OUT/IN skills were renamed to handoff/restore in
# WP5/M9). The step removes the orphan `## Session Handoff — <timestamp>`
# block (or the legacy `## Session Pause —` heading) that `/session-handoff`
# always appends to `state_file` EOF. Without §6b, every handed-off-then-restored
# item accrues a 10–30s cleanup tax at finalize/close time (18+ recurrences
# observed in one project alone). This pin anchors the heading so a future edit
# can't silently drop the step.
grep_check "session-restore SKILL.md retains §6b 'Strip the stale Handoff footer' step" "skills/session-restore/SKILL.md" "Strip the stale Handoff footer" 1

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
grep_check "transitions.md P3 condition is milestone-forward (tripartite sync)" "workflow-system/product/transitions.md" "Roadmap has milestones defined" 1

echo ""

# ── Phase 3a: Frontmatter YAML parseability ────────────────────────────────
#
# Every SKILL.md / AGENTS.md opens with a YAML frontmatter block. That block is
# the harness's contract surface: an invalid value (e.g. an unquoted inner-colon
# `argument-hint:` string) renders the skill non-invokable, but the failure mode
# is SILENT until the next session-start reparses the skill registry. Caught by
# hand on 2026-06-13 when an unquoted argument-hint slipped past the structural
# sweep (SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN). Mechanically
# pin-able: extract the frontmatter (between the first two `---` markers) and
# assert `yaml.safe_load` accepts it. Placed here as 3a (not a tail phase) so the
# PASS-count sequence and the Phase-11 close-commit block stay undisturbed.

echo "[Phase 3a] Frontmatter YAML parseability"

if command -v python3 &>/dev/null; then
  for f in skills/*/SKILL.md agents/*/AGENTS.md; do
    [ -f "$f" ] || continue
    # Extract only the block between the FIRST and SECOND `---` (awk c==1),
    # so body-level `---` horizontal rules are ignored. `|| true` keeps a parse
    # failure (non-zero python exit) from aborting the script under `set -e`;
    # the sentinel prefix distinguishes fail from a genuinely-empty (valid) block.
    fm_err=$( { awk '/^---$/{c++; next} c==1' "$f" | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin.read())" 2>&1 && echo "__YAML_OK__"; } || true )
    if [[ "$fm_err" == *"__YAML_OK__"* ]]; then
      check "$f frontmatter is parseable YAML" "pass"
    else
      check "$f frontmatter is parseable YAML" "fail" "$(echo "$fm_err" | tr '\n' ' ' | head -c 200)"
    fi
  done
else
  echo "  [SKIP] python3 not available — frontmatter YAML parse check skipped"
fi

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
#   3. Mention in workflow-system/product/transitions.md "Sidebar skills" subsection (so
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

# debug-minimal-harness: same callers (feature-build, incident-investigate, task-act)
for caller in skills/feature-build/SKILL.md skills/incident-investigate/SKILL.md skills/task-act/SKILL.md; do
  caller_name=$(basename "$(dirname "$caller")")
  grep_check "$caller_name mentions /debug-minimal-harness" "$caller" "/debug-minimal-harness" 1
done

for orch in agents/feature-workflow/AGENTS.md agents/incident-workflow/AGENTS.md agents/task-workflow/AGENTS.md; do
  orch_name=$(basename "$(dirname "$orch")")
  grep_check "$orch_name has 'Debug techniques (agent-pulled sidebars)' subsection" "$orch" "Debug techniques \(agent-pulled sidebars\)" 1
  # Each orchestrator's Debug-techniques table must list debug-empirical-telemetry as a row
  grep_check "$orch_name lists debug-empirical-telemetry in Debug-techniques table" "$orch" "debug-empirical-telemetry" 1
  # ...and debug-minimal-harness as a row
  grep_check "$orch_name lists debug-minimal-harness in Debug-techniques table" "$orch" "debug-minimal-harness" 1
done

grep_check "transitions.md has 'Sidebar skills' subsection (under Cross-level mechanisms)" "workflow-system/product/transitions.md" "^### Sidebar skills" 1
grep_check "transitions.md 'Sidebar skills' mentions /debug-empirical-telemetry" "workflow-system/product/transitions.md" "debug-empirical-telemetry" 1
grep_check "transitions.md 'Sidebar skills' mentions /debug-minimal-harness" "workflow-system/product/transitions.md" "debug-minimal-harness" 1

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

# ── Phase 3f: per-scenario fixture-key resolution (tests/run-tests.sh) ────
#
# Pins the two per-scenario fixture-key paths added by the
# per-scenario-claude-md-fixture feature (WP6 of backlog-paydown-2026-07-13):
#   1. fixtures.claude_md — copy the named CLAUDE.md fixture; fall back to the
#      default fixtures/CLAUDE.md when the key is absent / points at a missing
#      file. (Latent-bug fix: 179 scenarios already declared the key but the
#      runner ignored it and always copied the fixed default.)
#   2. per-scenario budget — pass the scenario's budget as --max-budget-usd;
#      fall back to the global $MAX_BUDGET when the key is absent. (Root-cause
#      fix for heavy scenarios hitting the $0.20 ceiling and reading FLAKY.)
#
# Per docs/lessons/test-harness-primitives.md, a new harness input SHAPE needs
# a permanent property-test across the FULL input namespace, not just the happy
# path. Two guards below: (a) grep_check that the real resolution lines still
# exist in run-tests.sh (catches removal/refactor drift); (b) an executable
# property-test replicating the exact one-liners and asserting every input shape.

echo "[Phase 3f] per-scenario fixture-key resolution (tests/run-tests.sh)"

# (a) The actual resolution logic must be present in the runner.
grep_check "run-tests.sh parses fixtures.claude_md key" "tests/run-tests.sh" 'fixture_claude_md=\$\(parse_scenario_nested .* "claude_md"\)' 1
grep_check "run-tests.sh honors claude_md with [-f] guard + default fallback" "tests/run-tests.sh" 'if \[ -n "\$fixture_claude_md" \] && \[ -f "\$SCRIPT_DIR/\$fixture_claude_md" \]; then' 1
grep_check "run-tests.sh parses per-scenario budget key" "tests/run-tests.sh" 'scenario_budget=\$\(parse_scenario_field .* "budget"\)' 1
grep_check "run-tests.sh passes budget with global fallback" "tests/run-tests.sh" 'max-budget-usd "\$\{scenario_budget:-\$MAX_BUDGET\}"' 1

# (b) Property-test the SEMANTICS across the full input namespace. Replicates
# the exact one-liners from run-tests.sh:176-181 (claude_md) and :236 (budget).
# Uses temp files so shape (a)/(b)/(c)/(d) resolution is observable.
_pt_tmp=$(mktemp -d)
mkdir -p "$_pt_tmp/named" "$_pt_tmp/default" "$_pt_tmp/dest"
echo "NAMED-FIXTURE-MARKER" > "$_pt_tmp/named/CLAUDE.md"
echo "DEFAULT-FIXTURE-MARKER" > "$_pt_tmp/default/CLAUDE.md"

# Mirror of the runner's claude_md branch (SCRIPT_DIR→named dir, FIXTURES_DIR→default dir).
_resolve_claude_md() {
  local fixture_claude_md="$1"; local SCRIPT_DIR="$_pt_tmp/named"; local FIXTURES_DIR="$_pt_tmp/default"
  local tmpdir="$_pt_tmp/dest"; rm -f "$tmpdir/CLAUDE.md"
  # NB: named fixtures live directly at $SCRIPT_DIR/CLAUDE.md here, so a non-empty
  # key resolves to that file; empty/missing keys fall through to the default.
  if [ -n "$fixture_claude_md" ] && [ -f "$SCRIPT_DIR/$fixture_claude_md" ]; then
    cp "$SCRIPT_DIR/$fixture_claude_md" "$tmpdir/CLAUDE.md" 2>/dev/null || true
  else
    cp "$FIXTURES_DIR/CLAUDE.md" "$tmpdir/CLAUDE.md" 2>/dev/null || true
  fi
  cat "$tmpdir/CLAUDE.md" 2>/dev/null
}
_pt_claude() {
  local label="$1"; local key="$2"; local want="$3"; local got
  got=$(_resolve_claude_md "$key")
  if echo "$got" | grep -q "$want"; then check "claude_md shape: $label" "pass"
  else check "claude_md shape: $label" "fail" "key='$key' want='$want' got='$got'"; fi
}
# 4 input shapes. "CLAUDE.md" is the named fixture's basename (present in named dir).
_pt_claude "(a) present → named fixture copied"           "CLAUDE.md"        "NAMED-FIXTURE-MARKER"
_pt_claude "(b) absent → default fixture copied"          ""                 "DEFAULT-FIXTURE-MARKER"
_pt_claude "(c) malformed (whitespace) → default, no crash" "   "            "DEFAULT-FIXTURE-MARKER"
_pt_claude "(d) nonexistent file → default fallback"      "DOES-NOT-EXIST.md" "DEFAULT-FIXTURE-MARKER"

# Mirror of the runner's budget fallback (:236).
_resolve_budget() { local scenario_budget="$1"; local MAX_BUDGET="0.20"; echo "${scenario_budget:-$MAX_BUDGET}"; }
_pt_budget() {
  local label="$1"; local key="$2"; local want="$3"; local got
  got=$(_resolve_budget "$key")
  if [ "$got" = "$want" ]; then check "budget shape: $label" "pass"
  else check "budget shape: $label" "fail" "key='$key' want='$want' got='$got'"; fi
}
_pt_budget "present → scenario value" "0.50" "0.50"
_pt_budget "absent → global default"  ""     "0.20"
rm -rf "$_pt_tmp"

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

# uninstall.sh (WP4/M8) — the defensive reversal of install.sh. These pins are
# DRY-RUN ONLY by design: a real (non-dry-run) uninstall here would tear down the
# live ~/.claude symlinks that install.sh (above) just created. --dry-run mutates
# nothing, so it is safe to exercise inside the structural suite. Behavioral
# coverage lives in tools/uninstall/test/run-tests.sh.
if [ -f uninstall.sh ]; then
  check "uninstall.sh exists at repo root (peer of install.sh)" "pass"
else
  check "uninstall.sh exists at repo root (peer of install.sh)" "fail" "file missing"
fi

if [ -x uninstall.sh ]; then
  check "uninstall.sh is executable" "pass"
else
  check "uninstall.sh is executable" "fail" "missing executable bit"
fi

if bash -n uninstall.sh 2>/dev/null; then
  check "uninstall.sh passes bash -n (syntax valid)" "pass"
else
  check "uninstall.sh passes bash -n (syntax valid)" "fail" "syntax error"
fi

if ./uninstall.sh --help > /dev/null 2>&1; then
  check "uninstall.sh --help exits 0" "pass"
else
  check "uninstall.sh --help exits 0" "fail" "non-zero exit"
fi

# --dry-run exits 0 and changes nothing (safe against the live ~/.claude).
if ./uninstall.sh --dry-run > /dev/null 2>&1; then
  check "uninstall.sh --dry-run exits 0 (dry-run only — never a live uninstall here)" "pass"
else
  check "uninstall.sh --dry-run exits 0 (dry-run only — never a live uninstall here)" "fail" "non-zero exit"
fi

# The live install must still be intact after the dry-run (guard against a dry-run
# regression that accidentally mutates state).
post_dryrun_symlinks=$(ls -la ~/.claude/skills/ 2>/dev/null | grep -c "my-claude-code-customization" || echo 0)
if [ "$post_dryrun_symlinks" -eq "$repo_symlinks" ]; then
  check "uninstall.sh --dry-run left the live install intact ($post_dryrun_symlinks symlinks)" "pass"
else
  check "uninstall.sh --dry-run left the live install intact" "fail" \
    "before: $repo_symlinks, after dry-run: $post_dryrun_symlinks"
fi

echo ""

# ── Phase 5: Hooks ────────────────────────────────────────────────────────

echo "[Phase 5] Hook script integrity"

# (The notify-telegram.sh hook was removed 2026-06-24 — no longer needed.
#  claude-time hook integrity is covered by Phase 5b below.)

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
# transforms can reasonably support. See workflow-system/product/wbs.md and CLAUDE.md.
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
# settings closely so tests run under near-realistic conditions, BUT:
#
#   1. Host-specific hooks are FILTERED, not compared. The developer's claudesk
#      wrapper app (com.claudesk.app[.dev]) installs its own busy/idle-monitoring
#      hooks into live settings via absolute ~/Library paths. Those are not part
#      of this repo and mutate on claudesk's own schedule, so any hook GROUP whose
#      command mentions "claudesk" is stripped from BOTH live and fixture before
#      comparison. The harness must not police claudesk, and claudesk must not
#      break the harness — the filter keeps the two fully decoupled.
#   2. After filtering, a small documented set of INTENTIONAL_DIFFS remains
#      (Notification/Stop are emptied in the fixture so tests never fire the
#      claude-time notification hooks). The repo-owned claude-time hook IS still
#      diffed exactly on every other event.
#
# This check FAILs if any field outside the documented diff set has drifted —
# telling the developer to either update the fixture or document a new exception.

echo "[Phase 7] Settings fixture drift"

if command -v python3 &>/dev/null && [ -f tests/fixtures/settings.json ] && [ -f "$HOME/.claude/settings.json" ]; then
  drift_output=$(python3 - <<'PYEOF' 2>&1 || true
import json, sys, os

LIVE = os.path.expanduser("~/.claude/settings.json")
FIXTURE = "tests/fixtures/settings.json"

# Documented intentional diffs. Format: list of (path, expected_live, expected_fixture).
# `path` is a tuple of nested keys; `MISSING` is a sentinel meaning the key is absent.
# NOTE: these are evaluated AFTER host-specific (claudesk) hooks are stripped from
# both sides — so the live expectations describe the claude-time-only shape.
MISSING = object()
INTENTIONAL_DIFFS = [
    # The fixture empties Notification/Stop so test runs never fire the claude-time
    # notification hooks; live legitimately runs claude-time on both. (claudesk
    # already stripped from both sides — see strip_host_specific below.)
    (("hooks", "Notification"), "non-empty-list", []),
    (("hooks", "Stop"), "any", []),
    # UserPromptSubmit is NOT listed: after stripping claudesk, both sides reduce to
    # the single claude-time hook and must match exactly — it is fully drift-checked.
]

# Machine-local settings keys that are toggled OUTSIDE this repo (Claude Code
# connector/UI preferences set per-machine, not committed here). These paths are
# stripped from BOTH live and fixture before drift detection so they never flag —
# while every repo-owned key stays fully drift-checked. Each entry is a key-PATH
# (tuple of nested keys): we delete the specific leaf, never a whole container, so
# repo-relevant siblings under env/statusLine (CLAUDE_TIME_TRACKING,
# CLAUDE_CODE_ENABLE_TELEMETRY, statusLine.command) remain compared.
HOST_LOCAL_KEYS = [
    ("disableClaudeAiConnectors",),
    ("tui",),
    ("cleanupPeriodDays",),
    ("statusLine", "padding"),
    ("env", "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"),
]

def delete_path(d, path):
    """Delete a nested key-path from d if present; no-op if any segment is absent."""
    cur = d
    for k in path[:-1]:
        if not isinstance(cur, dict) or k not in cur:
            return
        cur = cur[k]
    if isinstance(cur, dict):
        cur.pop(path[-1], None)

# Host-specific hooks installed by the developer's claudesk wrapper app are not
# part of this repo and must not participate in drift detection. Drop any hook
# GROUP whose command mentions "claudesk" from both live and fixture before diffing.
# Also strip the machine-local connector/UI keys enumerated in HOST_LOCAL_KEYS.
def strip_host_specific(settings):
    for path in HOST_LOCAL_KEYS:
        delete_path(settings, path)
    hooks = settings.get("hooks")
    if not isinstance(hooks, dict):
        return
    for event, groups in list(hooks.items()):
        if not isinstance(groups, list):
            continue
        hooks[event] = [
            g for g in groups
            if not any(
                "claudesk" in h.get("command", "")
                for h in g.get("hooks", [])
            )
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

# Strip host-specific (claudesk) hooks from both sides before any comparison
strip_host_specific(live)
strip_host_specific(fixture)

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

  # (4) AUTO-exit AskUserQuestion prohibition (P1 incident 2026-06-23,
  # autopilot-askuserquestion-pauses). The "Hard rule for AUTO exits" block must
  # explicitly forbid AskUserQuestion on AUTO transitions — the 2026-05-16 rule
  # only named the passive narrative-summary stop, leaving the active
  # tool-invocation stop unforbidden. Removing this clause reopens the regression.
  if grep -qF "AskUserQuestion" "$f"; then
    check "$f forbids AskUserQuestion on AUTO exits" "pass"
  else
    check "$f forbids AskUserQuestion on AUTO exits" "fail" \
      "missing AskUserQuestion prohibition in 'Hard rule for AUTO exits' (P1 2026-06-23 regression)"
  fi
done

# (3b) Tier-2: the canonical orchestrator pause-policy section and the three
# other orchestrators must each carry the AUTO ⇒ no-user-input-tool rule.
# (P1 incident 2026-06-23). feature-workflow holds the full statement; the
# others cross-reference it.
for af in agents/feature-workflow/AGENTS.md agents/task-workflow/AGENTS.md \
          agents/product-workflow/AGENTS.md agents/incident-workflow/AGENTS.md; do
  if grep -qF "AskUserQuestion" "$af"; then
    check "$af carries AUTO-exit AskUserQuestion prohibition" "pass"
  else
    check "$af carries AUTO-exit AskUserQuestion prohibition" "fail" \
      "missing AUTO ⇒ no-AskUserQuestion rule (P1 2026-06-23 regression)"
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
    # Expected header: ["Step", "Mode 1 — Stepping", ...]; data rows have label in col 0.
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

# Phase 11: Close-commit discipline + delete-on-resolve pins
# Pins the no-auto-push clause across all four terminal-close skills + the amend-to-HEAD
# clause in session-capture. Codifies SKILL.md prose contracts shipped 2026-06-12
# (close-commit-discipline feature) to prevent silent drift toward auto-push or away
# from learning-amend folding into HEAD.
# Also pins the delete-on-resolve (CHANGELOG-then-delete) convention across the four
# close skills + the canonical snippet rule, shipped 2026-07-15
# (delete-on-resolve-backlog-convention feature, SURFACE-2026-07-14-RESOLVED-ENTRY-AUDIT-TRAIL-CLUTTER):
# a close deletes the resolved backlog entry in the same commit as the **Backlog resolved:**
# CHANGELOG line — prevents drift back toward mark-and-retain (resolved-clutter regeneration).
echo "[Phase 11] Close-commit discipline (no auto-push + amend) + delete-on-resolve"

grep_check "feature-finalize forbids git push from close commit"   "skills/feature-finalize/SKILL.md"        "Do NOT \`git push\`"          1
grep_check "task-close forbids git push from close commit"          "skills/task-close/SKILL.md"              "Do NOT \`git push\`"          1
grep_check "incident-resolve forbids git push from resolve commit"  "skills/incident-resolve/SKILL.md"        "Do NOT \`git push\`"          1
grep_check "product-finalize forbids git push from cycle-close commit" "skills/product-finalize/SKILL.md"     "Do NOT \`git push\`"          1
grep_check "session-capture folds learning into HEAD via amend" "skills/session-capture/SKILL.md" "git commit --amend --no-edit" 1
grep_check "session-capture stages the learning file before amend" "skills/session-capture/SKILL.md" "git add <file-path"        1

# delete-on-resolve (CHANGELOG-then-delete hard invariant) — 4 close skills + canonical snippet rule
grep_check "feature-finalize deletes resolved backlog entry on close"  "skills/feature-finalize/SKILL.md"  "Delete-on-resolve \(CHANGELOG-then-delete" 1
grep_check "task-close deletes resolved backlog entry on close"        "skills/task-close/SKILL.md"        "Delete-on-resolve \(CHANGELOG-then-delete" 1
grep_check "incident-resolve deletes resolved backlog entry on close"  "skills/incident-resolve/SKILL.md"  "Delete-on-resolve \(CHANGELOG-then-delete" 1
grep_check "product-finalize deletes resolved backlog entry on close"  "skills/product-finalize/SKILL.md"  "Delete-on-resolve \(CHANGELOG-then-delete" 1
grep_check "CLAUDE.snippet.md defines the delete-on-resolve CHANGELOG-then-delete invariant" "CLAUDE.snippet.md" "CHANGELOG-then-delete hard invariant" 1

echo ""

# ── Phase 12: Path-qualification — no bare .claude/ in prompt prose ─────────
# Every `.claude/` reference in a skill/agent prompt or the global snippet MUST be
# explicitly qualified as `~/.claude/` (home/global config) or `<proj-dir>/.claude/`
# (project-local). Bare `.claude/` is forbidden because the agent must otherwise
# infer home-vs-project at read time, and infers inconsistently across sessions —
# the root cause of the non-deterministic learning-destination bug fixed by the
# artifact-tracking-policy feature (2026-06-25).
#
# Allowed (NOT violations), excluded before matching:
#   - lines inside ``` fenced code blocks (literal .gitignore patterns are repo-relative
#     and MUST be bare — `<proj-dir>/` prefix would be invalid gitignore syntax);
#   - the exact backtick-quoted generic token `.claude/` (the notation being *discussed*,
#     e.g. "Bare `.claude/` is forbidden" — a meta-reference, not a path instruction).
# The regex matches a `.claude/` not preceded by `~`, `/`, `.`, or a word char, then
# subtracts the two qualified forms and the two allowances above.
echo "[Phase 12] Artifact tracking policy + path-qualification"

# strip_fences: drop every line that sits inside a ```...``` block (and the fence lines).
strip_fences() { awk '/^[[:space:]]*```/{f=!f; next} !f'; }

bare_claude=""
for f in CLAUDE.snippet.md $(find skills agents -name '*.md' 2>/dev/null); do
  hits=$( (strip_fences < "$f" | grep -nE "(^|[^/~.a-zA-Z_-])\.claude/" 2>/dev/null || true) \
    | grep -vE "~/\.claude|<proj-dir>/\.claude" \
    | grep -vE '`\.claude/`' || true )
  [ -n "$hits" ] && bare_claude="${bare_claude}${f}: ${hits}"$'\n'
done
bare_claude=$(printf '%s' "$bare_claude" | grep -c . || true)
if [ "$bare_claude" -eq 0 ]; then
  check "no bare .claude/ in skills/ agents/ CLAUDE.snippet.md (all qualified ~/ or <proj-dir>/)" "pass"
else
  check "no bare .claude/ in skills/ agents/ CLAUDE.snippet.md (all qualified ~/ or <proj-dir>/)" "fail" "found $bare_claude bare mention(s) outside code fences / notation tokens"
fi

# The authoritative artifact tracking policy lives as a GLOBAL section in CLAUDE.snippet.md
# (injected into ~/.claude/CLAUDE.md by install.sh). Pin its presence + the track-by-default
# rule + the override mechanism so the policy can't silently drift away.
grep_check "CLAUDE.snippet.md defines 'Artifact tracking policy (GLOBAL)'" "CLAUDE.snippet.md" "^## Artifact tracking policy \(GLOBAL\)" 1
grep_check "Artifact tracking policy states track-by-default rule" "CLAUDE.snippet.md" "[Tt]rack by default" 1
grep_check "Artifact tracking policy defines the per-project override mechanism" "CLAUDE.snippet.md" "Artifact tracking overrides" 1

# session-capture is a policy-FOLLOWER, not a gitignore-inspector:
# (1) it names the single canonical global-draft destination;
# (2) its git behavior is keyed on the artifact tracking policy, NOT on inspecting/editing .gitignore;
# (3) it explicitly forbids using .gitignore inspection to decide a learning's git fate.
grep_check "session-capture names the canonical learnings destination" "skills/session-capture/SKILL.md" "<proj-dir>/\.claude/learnings/<YYYY-MM-DD>-<slug>\.md" 1
grep_check "session-capture keys git behavior on the artifact tracking policy, not gitignore inspection" "skills/session-capture/SKILL.md" "[Aa]rtifact tracking policy|Artifact tracking overrides" 1
grep_check "session-capture explicitly forbids gitignore-inspection for git fate" "skills/session-capture/SKILL.md" "Do NOT inspect or edit" 1
# product-context owns .gitignore reconciliation (the once-per-project owner).
grep_check "product-context owns .gitignore reconciliation step" "skills/product-context/SKILL.md" "Reconcile .?\.gitignore.? to the artifact tracking policy" 1
# session-reflect emits the scope label as a LEADING [GLOBAL]/[PROJECT] bracket, not a trailing "— Scope:".
grep_check "session-reflect Key Learnings use leading [GLOBAL]/[PROJECT] label" "skills/session-reflect/SKILL.md" "\[GLOBAL\]|\[PROJECT\]" 1
# session-reflect filter rules (reflect-store-filter-rules feature, 2026-07-03): candidate filter +
# scope-default + 3-tier presentation. These pins guard the prose contracts that make reflect propose
# fewer, better-scoped learnings so the operator stops pruning by hand.
# Rule 1 (§2b): default every store candidate to [PROJECT]; [GLOBAL] must clear a 3-part gate.
grep_check "session-reflect defaults store candidates to PROJECT scope" "skills/session-reflect/SKILL.md" "Default every tier-1 store candidate to" 1
# Rule 2 (§2a): already-persisted candidates require a cited location (fail-safe: no cite → stays a candidate).
grep_check "session-reflect requires a cited location for the already-persisted tier" "skills/session-reflect/SKILL.md" "MUST cite the location" 1
# Rule 5 (§3): three-tier presentation — store candidates / already-persisted / collapsed dropped list.
grep_check "session-reflect presents the store-candidates tier" "skills/session-reflect/SKILL.md" "Key Learnings — store candidates" 1
grep_check "session-reflect presents the already-persisted tier" "skills/session-reflect/SKILL.md" "Already persisted \(no action needed\)" 1
grep_check "session-reflect presents the collapsed dropped-candidates tier" "skills/session-reflect/SKILL.md" "Considered and dropped" 1
# Rule 3 carve-out: this repo (mccc) — the workflow system IS the domain, so workflow-mechanism learnings are legit.
grep_check "session-reflect carries the this-repo (workflow-is-domain) carve-out" "skills/session-reflect/SKILL.md" "workflow system IS the domain" 1
# The retired trailing form must be gone (regression guard).
trailing_scope=$( (grep -cE "Scope: global \| project" skills/session-reflect/SKILL.md 2>/dev/null || true) | head -1 )
trailing_scope="${trailing_scope:-0}"
if [ "$trailing_scope" -eq 0 ]; then
  check "session-reflect no longer uses the trailing '— Scope: global | project' form" "pass"
else
  check "session-reflect no longer uses the trailing '— Scope: global | project' form" "fail" "found $trailing_scope trailing-form line(s)"
fi
# This repo declares its artifact tracking override (it IS the learning-assets repo).
grep_check "CLAUDE.md declares the Artifact tracking overrides section" "CLAUDE.md" "^## Artifact tracking overrides" 1
# The superseded false 'gitignored .claude/learnings' claim must not return.
false_claim=$( (grep -cE "Global-scope writes \(gitignored" CLAUDE.md 2>/dev/null || true) | head -1 )
false_claim="${false_claim:-0}"
if [ "$false_claim" -eq 0 ]; then
  check "CLAUDE.md does not carry the superseded 'gitignored .claude/learnings' claim" "pass"
else
  check "CLAUDE.md does not carry the superseded 'gitignored .claude/learnings' claim" "fail" "found $false_claim stale-claim line(s)"
fi
# Tripartite-sync guard: the AUTHORITATIVE state-machine surface (transitions.md) must not carry
# the superseded "learnings ... gitignored" framing in its store-learning / S20 ROW DEFINITIONS.
# Scope to live markdown TABLE ROWS only (lines beginning with `|`) — the dated changelog bullets
# at the bottom of the file (lines beginning with `- **<date>`) are historical records that
# correctly keep their as-of wording, so they are excluded.
stale_transition=$( (grep -nE "^\|.*(store-learning|S20 )" workflow-system/product/transitions.md 2>/dev/null || true) \
  | grep -iE "project-local, gitignored|learnings/.*gitignored" || true )
if [ -z "$stale_transition" ]; then
  check "transitions.md store-learning/S20 rows carry no superseded 'gitignored learnings' framing" "pass"
else
  check "transitions.md store-learning/S20 rows carry no superseded 'gitignored learnings' framing" "fail" "stale framing in a live transition row: $(printf '%s' "$stale_transition" | head -1)"
fi

echo ""

echo "[Phase 13] Design priors (capture + consult contract)"

# The design-priors feature (2026-06-26) adds a per-project design-priors.md doc
# that planning skills CONSULT and capture-checkpoint skills PROPOSE-to. The contract
# is prose across 9 skills + 2 global docs; these pins keep it from silently drifting
# away. The canonical contract lives in CLAUDE.snippet.md → "Design priors (GLOBAL)".

# (1) Canonical schema + global contract.
grep_check "arch.md documents the Design Priors file schema" "workflow-system/product/arch.md" "File Schema: Design Priors" 1
grep_check "arch.md design-priors schema preserves inferred-why vs corrected-why gap" "workflow-system/product/arch.md" "inferred-why" 1
grep_check "arch.md design-priors schema names corrected-why field" "workflow-system/product/arch.md" "corrected-why" 1
grep_check "CLAUDE.snippet.md defines 'Design priors (GLOBAL)'" "CLAUDE.snippet.md" "^## Design priors \(GLOBAL\)" 1
grep_check "Design priors contract states the over-infer guard" "CLAUDE.snippet.md" "over-infer guard" 1
grep_check "Design priors contract names the disclosure form" "CLAUDE.snippet.md" "\[PRIOR: <slug>\]" 1

# (2) Consult block present in the 3 planning skills.
grep_check "product-roadmap consults design-priors.md" "skills/product-roadmap/SKILL.md" "design-priors\.md" 1
grep_check "product-wbs consults design-priors.md" "skills/product-wbs/SKILL.md" "design-priors\.md" 1
grep_check "feature-spec consults design-priors.md" "skills/feature-spec/SKILL.md" "design-priors\.md" 1
grep_check "product-roadmap carries the over-infer guard" "skills/product-roadmap/SKILL.md" "over-infer guard" 1
grep_check "product-wbs carries the over-infer guard" "skills/product-wbs/SKILL.md" "over-infer guard" 1
grep_check "feature-spec carries the over-infer guard" "skills/feature-spec/SKILL.md" "over-infer guard" 1

# (3) Capture move present in the 6 capture-checkpoint skills (+ propose-never-auto-write guard).
for s in product-vision product-roadmap product-arch product-wbs feature-spec feature-verify-human; do
  grep_check "$s carries the capture-a-design-prior move" "skills/$s/SKILL.md" "[Cc]apture a design prior" 1
done
# Propose-never-auto-write is the load-bearing over-capture guard — pin it in every capture skill.
for s in product-vision product-roadmap product-arch product-wbs feature-spec feature-verify-human; do
  # Pin the full contract phrase, not bare "propose". Tolerates both surface forms:
  # the hyphenated token "propose-never-auto-write" (5 skills) and product-vision's
  # comma-form "Propose, never auto-write." — both express the same capture contract.
  grep_check "$s capture move is propose-never-auto-write" "skills/$s/SKILL.md" "[Pp]ropose.{0,6}never.{0,6}auto-write" 1
done
# arch-boundary + FACT exclusions ("not a prior") present in every capture skill.
for s in product-vision product-roadmap product-arch product-wbs feature-spec feature-verify-human; do
  grep_check "$s capture move states the not-a-prior exclusions" "skills/$s/SKILL.md" "not a (design )?prior" 1
done

# (4) session-reflect backstop sweep.
grep_check "session-reflect carries the design-priors backstop sweep" "skills/session-reflect/SKILL.md" "design prior" 1

# (5) No new transition IDs introduced (design priors is behavior-within-states).
grep_check "transitions.md documents design priors as behavior-within-states (no new IDs)" "workflow-system/product/transitions.md" "[Dd]esign prior" 1

echo ""

echo "[Phase 14] Project-memory location — harness symlink + .claude/ track-by-default"

# (1) The memory-link primitive exists and is executable.
check "tools/memory-link/ensure-memory-link.sh exists" "$([ -f tools/memory-link/ensure-memory-link.sh ] && echo pass || echo fail)"
check "tools/memory-link/migrate-memory.sh exists" "$([ -f tools/memory-link/migrate-memory.sh ] && echo pass || echo fail)"
check "tools/memory-link/lib-slug.sh exists (shared slug helper)" "$([ -f tools/memory-link/lib-slug.sh ] && echo pass || echo fail)"
check "ensure-memory-link.sh is executable" "$([ -x tools/memory-link/ensure-memory-link.sh ] && echo pass || echo fail)"
check "migrate-memory.sh is executable" "$([ -x tools/memory-link/migrate-memory.sh ] && echo pass || echo fail)"
check "memory-link permanent test suite exists" "$([ -f tools/memory-link/test/run-tests.sh ] && echo pass || echo fail)"

# (2) The slug is realpath-derived (the footgun guard) — lib-slug uses pwd -P.
grep_check "lib-slug.sh derives slug from realpath (pwd -P), not raw \$PWD" "tools/memory-link/lib-slug.sh" "pwd -P" 1

# (3) The GLOBAL convention is codified in the snippet.
grep_check "CLAUDE.snippet.md defines the memory-location symlink convention" "CLAUDE.snippet.md" "^## Project-memory location — harness symlink \(GLOBAL\)" 1
grep_check "snippet convention names the realpath slug footgun" "CLAUDE.snippet.md" "realpath" 1
grep_check "snippet codifies .claude/ TRACK-by-default posture" "CLAUDE.snippet.md" "The \`.claude/\` default is TRACK" 1

# (4) Both hosts wire the ensure-link check (product-context + session-start).
grep_check "product-context invokes ensure-memory-link.sh" "skills/product-context/SKILL.md" "ensure-memory-link\.sh" 1
grep_check "session-start invokes ensure-memory-link.sh (non-product host)" "skills/session-start/SKILL.md" "ensure-memory-link\.sh" 1

# (5) session-capture carries the convergence note (repo dir is symlinked; no raw ~/.claude/projects write).
grep_check "session-capture documents the project-memory symlink convergence" "skills/session-capture/SKILL.md" "symlink" 1

echo ""

# ── Phase 15: Doc-layout unification — no stale docs/product | workflow/<child> paths ──
# M7 (Claudesk Handoff Cycle, 2026-07-21) physically unified the two per-project doc
# folders under one root: docs/product/* → workflow-system/product/, workflow/* →
# workflow-system/state/ (arch.md AD-1 Option A). This phase LOCKS that layout: a future
# edit MUST NOT silently reintroduce the old `docs/product/` or `workflow/<child>` paths
# in any skill/agent prompt, test scenario, or CLAUDE doc — that would drift the emitted
# paths back and desync consuming projects (+ Claudesk M11's docs_list).
#
# The check is PATH-ANCHORED, mirroring the sweep discipline that built the layout:
#   - `docs/product` is always a path → any occurrence is stale.
#   - `workflow/` is only a state-dir path when followed by a known child
#     (wip|backlog|archive|.session|learnings). The bare concept-word "workflow"
#     ("the feature workflow", "workflow state") and the `-workflow/AGENTS.md`
#     orchestrator-file tails are NOT matched — matching them would be the same
#     false-positive class the sweep itself had to avoid (803 bare-word vs 343 path).
#
# Intentional NON-targets, excluded before matching (these correctly keep old paths):
#   - tests/results/*.json — gitignored, regenerable test output.
#   - tests/sessions/*.jsonl — Tier-2-audited FROZEN historical session captures;
#     rewriting them would falsify the record + invalidate tests/sessions/AUDIT-LOG.md.
#   - tests/check-structure.sh — THIS file: its own descriptive comments + the grep
#     pattern-literals below contain the very strings it searches for (self-match). The
#     check guards the prompt/scenario/CLAUDE surface, not its own source.
#   - Migration-MAPPING prose lines (category-B): a line that DESCRIBES the old→new move
#     via the mapping arrow "→ workflow-system/{product,state}" is documenting history,
#     not emitting a live stale path. Rewriting the left side (docs/product/* →
#     workflow-system/product/*) would falsify the record (see
#     SURFACE-2026-07-21-MOVED-PRODUCT-DOCS-INTERNAL-PATH-REFS). Anchored on the arrow +
#     new-root target so it excludes ONLY the mapping form, NOT a bare live old-path ref.
echo "[Phase 15] Doc-layout unification — no stale docs/product | workflow/<child> paths"

# shared exclusion for category-B migration-mapping prose (old → workflow-system/<root>).
# grep is line-oriented, so '.*' cannot cross lines — no need for a newline-excluding
# char class (which also tripped a "brackets not balanced" warning on BSD grep).
mapping_prose='→.*workflow-system/(product|state)'

stale_docs_product=$( (grep -rnE 'docs/product' skills/ agents/ tests/ CLAUDE.md CLAUDE.snippet.md 2>/dev/null || true) \
  | grep -vE 'tests/results/|tests/sessions/[^:]*\.jsonl|tests/check-structure\.sh' \
  | grep -vE "$mapping_prose" || true )
stale_dp_count=$(printf '%s' "$stale_docs_product" | grep -c . || true)
if [ "$stale_dp_count" -eq 0 ]; then
  check "no stale docs/product/ path in skills/ agents/ tests/ CLAUDE docs (unified to workflow-system/product/)" "pass"
else
  check "no stale docs/product/ path in skills/ agents/ tests/ CLAUDE docs (unified to workflow-system/product/)" "fail" "found $stale_dp_count stale docs/product ref(s) — should be workflow-system/product/"
fi

stale_workflow_state=$( (grep -rnE 'workflow/(wip|backlog|archive|\.session|learnings)' skills/ agents/ tests/ CLAUDE.md CLAUDE.snippet.md 2>/dev/null || true) \
  | grep -vE 'tests/results/|tests/sessions/[^:]*\.jsonl|workflow-system|tests/check-structure\.sh' \
  | grep -vE "$mapping_prose" || true )
stale_ws_count=$(printf '%s' "$stale_workflow_state" | grep -c . || true)
if [ "$stale_ws_count" -eq 0 ]; then
  check "no stale workflow/<child> state path in skills/ agents/ tests/ CLAUDE docs (unified to workflow-system/state/)" "pass"
else
  check "no stale workflow/<child> state path in skills/ agents/ tests/ CLAUDE docs (unified to workflow-system/state/)" "fail" "found $stale_ws_count stale workflow/<child> ref(s) — should be workflow-system/state/"
fi

# Positive anchor: the two unified roots are actually referenced (guards against a
# future over-eager "cleanup" that deletes the paths entirely rather than migrating them).
grep_check "unified root workflow-system/product/ is referenced in skills/" "skills/session-start/SKILL.md" "workflow-system/product/" 1
grep_check "unified root workflow-system/state/ is referenced in skills/" "skills/session-handoff/SKILL.md" "workflow-system/state/" 1

echo ""

# ── Phase 16: Research cost-tier disambiguation (WP6) ────────────────────────
# quick-research is the LIGHT research tier; deep-research (harness built-in) is the HEAVY
# tier. The bite this feature fixed is a cost-tier jump (a light lookup silently escalating
# into deep-research), NOT topic confusion. These pins lock the four load-bearing surfaces:
# (a) quick-research's own behavior anchors — confidence labels, known-unknowns, and the
# human-gated (never-auto-launch) deep-research escalation; (b) the global cost-tier rule in
# CLAUDE.snippet.md; (c) the two in-workflow research skills' sharpened descriptions reading
# as workflow-scoped + NOT web research; (d) the orchestrator reinforcement. Anchors were
# grep-verified present before pinning (per the review-finding-is-a-hypothesis discipline).
echo "[Phase 16] Research cost-tier disambiguation (quick-research + confirm-before-deep)"

# (a) quick-research SKILL.md behavior anchors
grep_check "quick-research SKILL.md name frontmatter" "skills/quick-research/SKILL.md" "^name: quick-research$" 1
grep_check "quick-research requires per-claim confidence labels" "skills/quick-research/SKILL.md" "confidence label" 1
grep_check "quick-research requires a known-unknowns list" "skills/quick-research/SKILL.md" "known unknown" 1
grep_check "quick-research: deep-research escalation is NEVER auto-launched" "skills/quick-research/SKILL.md" "NEVER launched automatically|NEVER auto-launch|never launched automatically" 1
grep_check "quick-research states the ROI bar for deep-research" "skills/quick-research/SKILL.md" "When deep-research IS justified|ROI" 1

# (b) global cost-tier rule in CLAUDE.snippet.md
grep_check "CLAUDE.snippet.md carries the Research cost tiers rule" "CLAUDE.snippet.md" "## Research cost tiers \(GLOBAL\)" 1
grep_check "CLAUDE.snippet.md: confirm-before-deep-research rule" "CLAUDE.snippet.md" "Confirm before deep-research" 1

# (c) the two in-workflow research descriptions read workflow-scoped + NOT web research
grep_check "product-research description reads workflow-scoped (NOT web research)" "skills/product-research/SKILL.md" "^description:.*NOT general web research" 1
grep_check "feature-research description reads workflow-scoped (NOT web research)" "skills/feature-research/SKILL.md" "^description:.*NOT general web research" 1

# (d) orchestrator reinforcement in both product + feature orchestrators
grep_check "feature-workflow orchestrator reinforces research tiers + confirm-before-deep" "agents/feature-workflow/AGENTS.md" "Research tiers — workflow-research vs. web-research" 1
grep_check "product-workflow orchestrator reinforces research tiers + confirm-before-deep" "agents/product-workflow/AGENTS.md" "Research tiers — workflow-research vs. web-research" 1

echo ""

# ── Phase 17: Session-vocabulary disambiguation (WP5 / M9) ───────────────────
# WP5 renamed the two session-boundary skills (session-pause→session-handoff,
# session-resume→session-restore — "restore" avoids the built-in /resume collision)
# and the learning skill (session-store-learning→session-capture — avoids the /restore
# fuzzy-match collision). Two distinct collision surfaces were found: (1) skill NAME
# and (2) skill DESCRIPTION — the fuzzy-matcher ranks on BOTH. These pins lock:
# (a) the renamed skills exist with matching name: frontmatter;
# (b) old names never reappear in LIVE machinery (anti-regression, Phase-15 style);
# (c) the /restore collision stays fixed — no skill NAME or DESCRIPTION contains
#     "restor" except session-restore itself (the description-collision guard);
# (d) the turn-vs-session disambiguation + agent-side guard prose is present.
echo "[Phase 17] Session-vocabulary disambiguation (WP5 — handoff/restore/capture rename + collision guard)"

# (a) renamed skills exist, name: matches dir
grep_check "session-handoff SKILL.md name frontmatter" "skills/session-handoff/SKILL.md" "^name: session-handoff" 1
grep_check "session-restore SKILL.md name frontmatter" "skills/session-restore/SKILL.md" "^name: session-restore" 1
grep_check "session-capture SKILL.md name frontmatter" "skills/session-capture/SKILL.md" "^name: session-capture" 1

# (b) anti-regression: old names never reappear in LIVE machinery.
# Exclusions mirror Phase 15: frozen tests/sessions/*.jsonl, check-structure.sh self,
# and intentional rename/migration DESCRIPTIONS. Two forms count as a description:
#  (1) prose markers — "renamed from …", "renamed session…", "Skill renamed", "legacy",
#      the strip-pause-footer task name;
#  (2) the rename-ARROW form — an old name immediately followed by the → arrow pointing
#      at its new name (e.g. `session-pause`→`session-handoff`), which is unambiguously a
#      "this documents the rename" line, not a live reference to the old skill.
old_session_names=$( (grep -rnE 'session-pause|session-resume|session-store-learning' skills/ agents/ tests/ CLAUDE.md CLAUDE.snippet.md 2>/dev/null || true) \
  | grep -vE 'tests/results/|tests/sessions/[^:]*\.jsonl|tests/check-structure\.sh' \
  | grep -viE 'renamed from|renamed session|Skill renamed|strip-pause-footer|legacy' \
  | grep -vE 'session-(pause|resume|store-learning)`?→' || true )
old_names_count=$(printf '%s' "$old_session_names" | grep -c . || true)
if [ "$old_names_count" -eq 0 ]; then
  check "no old session-skill name (session-pause|resume|store-learning) in live machinery" "pass"
else
  check "no old session-skill name (session-pause|resume|store-learning) in live machinery" "fail" "found $old_names_count old-name ref(s) — should be session-handoff/restore/capture"
fi

# (c) /restore collision guard: no skill NAME or DESCRIPTION contains "restor"
# except session-restore itself. This is the description-collision insight made
# mechanical — the fuzzy-matcher searches descriptions, so a sibling skill whose
# description says "restore service" (as incident-mitigate once did) re-introduces
# the collision even with a clean name. Scans every skills/*/SKILL.md frontmatter.
restore_collision=""
for skill_md in skills/*/SKILL.md; do
  sname=$(basename "$(dirname "$skill_md")")
  [ "$sname" = "session-restore" ] && continue
  fm=$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f{print}' "$skill_md")
  if printf '%s' "$fm" | grep -qiE 'restor'; then
    restore_collision="$restore_collision $sname"
  fi
done
if [ -z "$restore_collision" ]; then
  check "/restore fuzzy-collision guard: only session-restore matches 'restor' (name+description)" "pass"
else
  check "/restore fuzzy-collision guard: only session-restore matches 'restor' (name+description)" "fail" "these skills' name/description also match 'restor':$restore_collision — reframe their description"
fi

# (d) disambiguation + agent-side guard prose present (the behavioral heart of WP5)
grep_check "session-handoff SKILL.md carries the turn-vs-session disambiguation" "skills/session-handoff/SKILL.md" "turn-level" 1
grep_check "session-handoff SKILL.md carries the agent-side guard (contextual — workflow-position-keyed)" "skills/session-handoff/SKILL.md" "Agent-side guard" 1
grep_check "session-handoff guard is contextual: clean-boundary auto-chain vs mid-workflow confirm" "skills/session-handoff/SKILL.md" "clean workflow boundary" 1
grep_check "feature-workflow AGENTS.md carries the pause disambiguation guidance" "agents/feature-workflow/AGENTS.md" "turn-level vs session boundary" 1

# (e) the durable GLOBAL convention is in the injected snippet (mirrors Phase-16's snippet pin)
grep_check "CLAUDE.snippet.md carries the Session vocabulary (turn vs session) rule" "CLAUDE.snippet.md" "Session vocabulary — turn vs. session boundary" 1
grep_check "CLAUDE.snippet.md documents the fuzzy-matcher-searches-descriptions naming rule" "CLAUDE.snippet.md" "fuzzy-matcher searches DESCRIPTIONS" 1
# the guard is CONTEXTUAL (workflow-position-keyed), NOT a universal always-confirm — this
# distinction is load-bearing (operator correction 2026-07-21): clean boundary → auto-chain,
# mid-workflow ambiguity → confirm. A regression to "always confirm" would re-add friction.
grep_check "CLAUDE.snippet.md: session-handoff guard is CONTEXTUAL, not universal-confirm" "CLAUDE.snippet.md" "Agent-side guard is CONTEXTUAL" 1

# (f) /resume is TURN-LEVEL, not a handoff cue — the second confirmed misfire (2026-07-21):
# an agent read "hold, I need to go, I'll /resume later" as a session boundary and wrote
# .session.md. "/resume" (built-in, continues THIS turn) ≠ "/session-restore" (cross-session).
# The going-offline family ("I'll /resume later", "shutting down", "I need to go") is turn-level HOLD.
grep_check "session-handoff SKILL.md: /resume-later is turn-level, NOT a handoff cue" "skills/session-handoff/SKILL.md" "resume\` later" 1
grep_check "CLAUDE.snippet.md distinguishes /resume (turn-level) from /session-restore (cross-session)" "CLAUDE.snippet.md" "/resume\` ≠ \`/session-restore\`" 1

echo ""

# ── Phase 18: Session-boundary exit chain modeled in the state machine ────────
# The boundary-handoff-autochain feature (2026-07-21) promoted the WP5 prose-only
# "auto-chain the handoff at a clean boundary" rule into the state machine: the full
# finalize → reflect → [capture] → handoff exit chain, as MODELED EDGES (S22/S23) +
# pause-policy rows (not first-class dispatched states — D2). Plus the AC-6
# session-capture conditional-gate behavior change (autopilot/FSD [PROJECT] auto-writes
# as a read-time veto; [GLOBAL] keeps the confirm gate; Modes 1/2 unchanged).
# These pins enforce the three-places-in-sync rule (transitions.md / the 4 AGENTS.md /
# the skill prose) for that chain. Resolves
# SURFACE-2026-07-21-BOUNDARY-HANDOFF-AUTOCHAIN-NOT-IN-STATE-MACHINE.
echo "[Phase 18] Session-boundary exit chain modeled (S22/S23 edges + pause rows + capture conditional gate)"

# (a) the two new transition/edge IDs exist in transitions.md's Session-transitions table
grep_check "transitions.md carries the S22 reflect→session-handoff edge" "workflow-system/product/transitions.md" "^\| S22 \| reflect → session-handoff" 1
grep_check "transitions.md carries the S23 session-capture→session-handoff edge" "workflow-system/product/transitions.md" "^\| S23 \| session-capture → session-handoff" 1

# (b) reflect's Behavior row is no longer an unconditional terminus — it names the two-arm fork
grep_check "transitions.md reflect row names the two-arm boundary fork (S22 + S23)" "workflow-system/product/transitions.md" "forks onto the session-boundary exit chain" 1

# (c) the Drive-modes "Session-boundary exit chain" pause-policy block exists in transitions.md
grep_check "transitions.md Drive-modes carries the Session-boundary exit chain block" "workflow-system/product/transitions.md" "Session-boundary exit chain" 1

# (d) all 4 canonical orchestrator AGENTS.md tables carry the exit-chain block (three-places-in-sync at table level)
grep_check "feature-workflow AGENTS.md carries the Session-boundary exit chain block" "agents/feature-workflow/AGENTS.md" "Session-boundary exit chain" 1
grep_check "task-workflow AGENTS.md carries the Session-boundary exit chain block" "agents/task-workflow/AGENTS.md" "Session-boundary exit chain" 1
grep_check "product-workflow AGENTS.md carries the Session-boundary exit chain block" "agents/product-workflow/AGENTS.md" "Session-boundary exit chain" 1
grep_check "incident-workflow AGENTS.md carries the Session-boundary exit chain block" "agents/incident-workflow/AGENTS.md" "Session-boundary exit chain" 1

# (e) the guard prose is re-pointed to "the table is authoritative" in all 4 AGENTS.md
grep_check "feature-workflow AGENTS.md re-points guard to the authoritative table" "agents/feature-workflow/AGENTS.md" "pause-policy table is authoritative" 1
grep_check "task-workflow AGENTS.md re-points guard to the authoritative table" "agents/task-workflow/AGENTS.md" "pause-policy table is authoritative" 1
grep_check "product-workflow AGENTS.md re-points guard to the authoritative table" "agents/product-workflow/AGENTS.md" "pause-policy table is authoritative" 1
grep_check "incident-workflow AGENTS.md re-points guard to the authoritative table" "agents/incident-workflow/AGENTS.md" "pause-policy table is authoritative" 1

# (f) AC-6: session-capture's confirmation gate is drive-mode-conditional (the one behavior change)
#     [PROJECT] auto-writes in autopilot/fsd; [GLOBAL] keeps the confirm gate; read-time veto surface.
grep_check "session-capture §4 gate is drive-mode-conditional (AC-6)" "skills/session-capture/SKILL.md" "Confirmation gate — drive-mode-conditional" 1
grep_check "session-capture autopilot/FSD [PROJECT]-scope auto-writes" "skills/session-capture/SKILL.md" "AUTO-WRITE, no stop" 1
grep_check "session-capture [GLOBAL]-scope still confirms even in autopilot/FSD" "skills/session-capture/SKILL.md" "STILL CONFIRM" 1
grep_check "session-capture auto-write is surfaced as a read-time veto" "skills/session-capture/SKILL.md" "read-time veto" 1

# (g) the durable convention re-point lives in the injected snippet (mirrors Phase-17's snippet pin)
grep_check "CLAUDE.snippet.md re-points the session-boundary handoff to the authoritative pause-policy table" "CLAUDE.snippet.md" "pause-policy table" 1

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
