---
drive_mode: autopilot
---

# Feature: Entry-point skills load product context

**Workflow:** feature
**State:** ship (complete)
**Created:** 2026-05-14
**Shipped:** 2026-05-14 (commit 786c03f, pushed to origin/main)
**Entry:** spec (complex feature)
**Source:** SURFACE-2026-05-11-ENTRYPOINT-SKILLS-LOAD-PRODUCT-CONTEXT

## Problem Statement

Entry-point skills (`task-plan`, `feature-spec`, `feature-plan`, `feature-reproduce`, `incident-report`, `product-vision`) currently know nothing about a project's strategic product docs unless the user pastes the relevant content into the slash command's `{{args}}`. The docs (`vision.md`, `roadmap.md`, `research.md`, `arch.md`, `wbs.md`, `context.md`) already exist on disk in `docs/product/` — but the entry skills don't read them.

Result: planning starts from a blank slate. An agent specifying a new feature has no awareness of the active WBS cycle, the architectural decisions that constrain the solution space, or the product vision that should orient priorities.

**The counter-pressure (load discipline, decided during spec review):** dumping every relevant `docs/product/*.md` into every entry skill is wasteful in the opposite direction. A `task-plan` for a one-line bug fix doesn't benefit from 240 lines of `arch.md`. Token cost compounds across the workflow (the loaded doc sits in context through plan, build, verify, ship). Signal-to-noise drops. CLAUDE.md is already loaded by the harness and overlaps with `docs/product/context.md`. So the design needs an explicit boundary: load the minimum that materially improves planning quality, and surface availability of the rest as a pointer.

The user explicitly called this out as a debate before approving the spec. The resolution is encoded in the **Loading Strategy** section below.

## User Stories

- **As a workflow-system user**, I want entry-point skills to surface relevant strategic context so that the resulting spec/plan reflects current architectural constraints and active WBS context — without me re-pasting that content into every slash command.
- **As a workflow-system user on a project with no product docs**, I want entry-point skills to behave exactly as they do today (no warnings, no friction) so that the workflow stays lightweight for ad-hoc projects.
- **As a workflow-system user on a project with mature, lengthy product docs**, I want entry-point skills to pay a bounded context cost (not "load everything always") so that running `/task-plan` for a small fix doesn't dump 50K tokens of strategic narrative into my session.
- **As a workflow-system maintainer**, I want one canonical place that documents the per-skill loading strategy so that adding a new entry skill or a new product-doc kind is a single mechanical edit, not six skill-prompt updates.

## Loading Strategy (decided)

This is the load-discipline boundary the user requested. It combines three principles:

### (1) Pointer-not-payload — the default for every entry skill

Every entry-point skill's procedure gains a **"Step 0: Available product context"** section. This step lists which `docs/product/*.md` files exist *in the current project* and gives each a one-line description of what it contains. **No file content is read at this step.** The cost is a few lines of always-present pointer text in the prompt plus one `ls docs/product/` (or equivalent) at runtime.

Rationale: the agent now knows the docs exist and what they cover. If its reasoning during the skill needs the detail, it can choose to read. Most invocations won't need any of them — and pay only the pointer cost.

### (2) Eager-read for the two skills where strategic alignment is most expensive to miss

Two skills go beyond the pointer and eagerly read specific docs:

| Skill | Eager-reads | Rationale |
|-------|-------------|-----------|
| `feature-spec` | `arch.md`, `wbs.md` (if present) | Spec is the most upstream complex-feature decision point. Architectural divergence here propagates through plan/build/verify and is expensive to unwind. WBS awareness prevents specifying a feature that's already a planned WP or contradicts an active one. |
| `feature-plan` | `wbs.md` (if present **and not already in conversation context**) | Plan phasing should align with the active WBS cycle. `arch.md` is spec's concern (constraints are already in the spec by the time plan runs); plan doesn't re-read it. **Context-skip rule:** if `feature-spec` ran earlier in the same conversation and loaded `wbs.md`, the content is already available — `feature-plan` notes "wbs.md already in context (loaded by feature-spec)" and skips the re-read. If the conversation is fresh (e.g., `/session-resume` after a pause, or direct F2 small/simple entry with no prior spec), `wbs.md` is not in context and `feature-plan` reads it itself. The agent introspects its own conversation context to decide — no WIP-frontmatter inspection, no session-state file. |

That's it. **`task-plan`, `feature-reproduce`, `incident-report`, `product-vision` are pointer-only** — they get Step 0's existence list but read nothing eagerly.

### (3) Relevance-conditional read for `task-plan` and `incident-report`

Two skills get a conditional read in addition to the pointer:

- **`task-plan`:** prompt instructs the agent: "if the task description appears to touch architectural decisions (renaming a public API, changing a data shape, modifying a cross-module boundary, altering a workflow state machine), read `docs/product/arch.md` after writing the initial task plan, and revise the plan if a constraint is found." This is agent-judgment, but the trigger conditions are spelled out.
- **`incident-report`:** prompt instructs the agent: "if the incident appears to involve cross-component behavior or system-architecture-level effects, read `docs/product/arch.md` while writing the report." Same conditional shape.

Rationale: atomic tasks and incident *reports* often don't need arch context. The few that do are detectable from the work description.

### (4) Size guard for eager reads

If an eager-read doc exceeds **~300 lines**, the skill reads the first 100 lines + the section heading list only, and writes one line to the WIP file's `## Discoveries` section: `[SURFACED-<date>] <skill-name> — <doc>.md exceeds size guard (N lines), truncated to first 100. Consider summarizing.`

Rationale: a bounded worst-case for context cost on mature projects. Truncation degrades gracefully — the agent still sees structure (heading list) and the first ~100 lines, and the truncation event becomes a SURFACE the maintainer can address by trimming the doc.

### (5) No `context.md`, ever

`context.md` is dropped from the mapping entirely. CLAUDE.md is auto-loaded by the harness and serves the same role in spirit; double-loading is wasteful and risks drift if both files exist with diverged content. If a project actually uses both distinctly, the user can paste content into args — explicit non-goal.

### Worst-case context cost (sanity check)

- **Pointer-only skills** (`task-plan`, `feature-reproduce`, `incident-report`, `product-vision`): ~5 lines of pointer text, plus one `ls` output. ~200 tokens.
- **`task-plan` with conditional read triggered:** pointer + `arch.md` capped at ~100 lines. ~3K tokens.
- **`feature-spec` worst case:** pointer + `arch.md` (capped) + `wbs.md` (capped). ~6K tokens. Compare to today's "no context at all"; the cost is real but bounded and the spec is the place where it's most worth paying.
- **`feature-plan`:** pointer + `wbs.md` (capped). ~3K tokens.
- **`incident-report` with conditional read triggered:** pointer + `arch.md` (capped). ~3K tokens.

## Acceptance Criteria

The feature is done when:

1. **Canonical loading-strategy section in `CLAUDE.snippet.md`** documents the rules in the "Loading Strategy" section above — pointer-default, the two eager-read skills with their doc lists, the two conditional-read skills with their trigger phrases, the 300-line size guard, and the no-`context.md` rule.
2. **Each of the 6 entry-point skills** has a "Step 0: Available product context" procedure section that (a) lists the `docs/product/*.md` files relevant to that skill with one-line descriptions, (b) instructs the agent to confirm which exist by listing the directory, and (c) for `feature-spec` and `feature-plan`, additionally eagerly reads the mapped docs subject to the size guard, and (d) for `task-plan` and `incident-report`, names the conditional-read trigger phrases.
3. **Absent-file behavior is silent.** When a mapped or pointed-to doc is missing on disk, the skill no-ops on that doc and proceeds. No warnings, no prompts to the user.
4. **Size guard works as specified.** When an eager-read doc exceeds 300 lines, the skill reads first 100 lines + section headings only and appends a SURFACE line to the WIP file's `## Discoveries` section.
5. **`product-vision` is excluded from any reading** (it writes vision.md; reading would be circular). Its Step 0 is a one-line note explaining the exclusion.
6. **No `context.md` references anywhere** in the mapping or in any skill's Step 0 (decided non-goal).
7. **Test coverage:** for each modified skill, scenarios verify (a) when relevant docs exist, the skill's output reflects awareness of their presence (pointer surfaces them; eager-read reflects content); (b) when docs are absent, the skill proceeds without error or warning; (c) for `feature-spec` and `feature-plan`, the size guard activates correctly when a fixture doc exceeds 300 lines.
8. **No regressions** in existing scenarios — the 6 entry skills still emit their existing TRANSITION IDs correctly.
9. **Structural check:** `tests/check-structure.sh` asserts that each entry-point skill's SKILL.md has a "Step 0" section and that the doc paths it names are consistent with the canonical mapping in `CLAUDE.snippet.md`.

## Out of Scope

- **Non-entry skills.** Mid-workflow skills (`feature-build`, `feature-verify-*`, `feature-ship`, `feature-finalize`, `incident-investigate`, etc.) are not modified. They operate inside a WIP file that already carries strategic context forward.
- **`session-start` itself.** It's a dispatcher, not a planner. Its classification step doesn't need product-doc content to route correctly. Revisit if classification quality is later observed to degrade without it.
- **Sub-agent context loading.** Agents spawned via the `Agent` tool inherit context from the parent.
- **Caching or summarization across invocations.** Each skill invocation reads fresh. A "summary section at the top of each doc" idea was considered and rejected for v1 (drift risk; the size guard delivers most of the benefit).
- **A new doc kind.** This feature plumbs *existing* `docs/product/*.md` files.
- **Cross-project doc discovery.** Skills consult docs in the *current project root only*.
- **Lazy mid-skill loading.** Eager reads happen at Step 0; conditional reads happen at the trigger point in the procedure. No "the agent decides whether to load each doc independently as it reasons" — the SKILL.md spells out load points concretely.
- **`research.md`, `roadmap.md`, `vision.md` reads.** Pointer-only for all skills. Vision is too high-level to mechanically constrain spec; roadmap is too coarse to constrain plan phasing; research is cycle-scoped and migrated to archive on cycle close.

## Technical Constraints

- **Canonical mapping lives in `CLAUDE.snippet.md`.** Globally injected by `install.sh` into `~/.claude/CLAUDE.md`. The snippet is the maintainer-facing canonical table.
- **Each SKILL.md spells out its own load points concretely.** No agent-runtime indirection through the snippet — the per-skill prompt names paths explicitly. The snippet and the per-skill spelled-out paths must stay in sync; the structural check (AC #9) enforces this.
- **The agent never runs shell commands to gather context** beyond a single `ls docs/product/` (via `Glob` or `Bash`) to confirm which mapped files exist. No `find`, no `grep`, no recursive traversal.
- **Size-guard read mechanics:** use the existing `Read` tool's `limit:` parameter for the first 100 lines, and a separate `Grep` for `^## ` headings to capture structure. Both are tools the agent already has.
- **Test fixtures:** `tests/fixtures/docs/product/` gains stub `arch.md`, `wbs.md`, `vision.md`, `roadmap.md` (~20 lines each), plus an oversized `arch.md` variant (~400 lines) in a separate fixture path to exercise the size guard.
- **Drive-mode-neutral.** Same behavior across all four drive modes.
- **Reads are local-only.** `<project-root>/docs/product/*.md` only. No parent-dir traversal, no network.
- **Three-surface discoverability convention.** Per the CLAUDE.md rule "A new skill category needs three structurally-enforced discoverability surfaces": (1) caller-skill prose mentions in each entry skill's SKILL.md, (2) the canonical mapping section in `CLAUDE.snippet.md` (globally injected) plays the role of the orchestrator-AGENTS mention since these are entry-point skills not invoked by a higher orchestrator inside the workflow, (3) a cross-level mechanism note in `docs/product/transitions.md` under a new "Entry-skill context loading" subsection. Structural check enforces all three.

## Open Questions

All major design questions resolved in spec review. One tactical question remains for plan/build:

- [ ] **Q1 — Exact wording of the conditional-read triggers for `task-plan` and `incident-report`.** Spec gives examples ("renaming a public API, changing a data shape, modifying a cross-module boundary, altering a workflow state machine"). Trigger phrases stay as authored — no validation against `workflow/archive/` (would not scale; archive grows unboundedly). Tunable later if observed to misfire in practice.

**Resolved during spec review (recorded for traceability):**
- **Q2 (prior draft) — `feature-plan` conditional `arch.md` on direct F2 entry:** rejected. Plan does not read `arch.md`; that remains exclusively spec's concern. Small/simple features entering at plan are by definition no-arch-decision-required (criterion 2 of the small/simple gate).
- **Q3 (prior draft) — Size-guard heading extraction:** resolved to `^#+ ` (all heading levels, more inclusive).
- **Q4 (prior draft) — Structural-check granularity:** resolved to "Step 0 section exists" only. No line-by-line consistency check against the canonical mapping for v1 — over-engineering. Drift surfaces as test failures when the per-skill path list goes stale.
- **`feature-plan` wbs.md context-skip:** resolved to conversation-context introspection (not WIP file inspection). If `wbs.md` is already in conversation context, `feature-plan` skips the read. See the eager-read table above for the full rule.

## Plan Rationale (sequencing)

Four-phase plan, executed in this order:

1. **Mapping first** (Phase 1) so the canonical reference exists before any skill prompt cites it. Editing skills first and then the snippet would mean Phase 2 cites a section that doesn't exist yet.
2. **Skill edits second** (Phase 2) — all six entry-point skills updated in one phase. They share the same Step 0 pattern; doing them in lockstep avoids drift between snippet and skill prompts mid-feature.
3. **Tests third** (Phase 3) — fixtures + scenarios verify the runtime behavior. Tests come after the impl because the scenarios assert on behavior that doesn't exist until Phase 2 lands.
4. **Structural enforcement last** (Phase 4) — the check-structure.sh phase guards against future regression (a SKILL.md losing its Step 0 section). Adding it last avoids the structural check failing on partial intermediate states during Phase 2.

The integration-boundary rule applies to Phase 2 (modifying existing skill SKILL.md files that test scenarios already assert against) and Phase 4 (adding to `tests/check-structure.sh` which the test sweep already runs). Plan-level "downstream contract impacts" pass: the existing scenarios for task-plan, feature-spec, feature-plan, feature-reproduce, incident-report, product-vision (in `tests/scenarios/*.yaml`) need to be re-run after Phase 2 to confirm they still emit the right TRANSITION IDs despite the new Step 0 prose. This is captured in Phase 2's verify-auto.

---

## Work Tree

- [x] Phase 1: Canonical mapping section + transitions.md note
  **Observable outcomes:**
  - CLI: `grep -c "Entry-skill product-context loading" CLAUDE.snippet.md` → output `1` (section exists, single occurrence).
  - CLI: `grep -c "Entry-skill product-context loading\|Entry-skill context loading" ~/.claude/CLAUDE.md` → output ≥ `1` after re-running `./install.sh` (snippet injection succeeded).
  - CLI: `grep -c "Entry-skill context loading" docs/product/transitions.md` → output `1` (cross-level mechanism note added).
  - CLI: `./tests/check-structure.sh` exits 0 (no regression in existing structural checks).
  - [x] P1.1 Add "Entry-skill product-context loading" section to `CLAUDE.snippet.md` (after the existing "Work Tree Format (GLOBAL)" section, before "CHANGELOG.md convention (GLOBAL)"). Section includes: per-skill mapping table (6 rows), the five rules (pointer-default, eager-read for spec/plan, conditional-read for task-plan/incident-report, 300-line size guard with `^#+ ` heading extraction, no context.md), and the wbs.md conversation-context skip rule for feature-plan.
  - [x] P1.2 Add a "Cross-level mechanisms" subsection (or extend an existing one) to `docs/product/transitions.md` titled "Entry-skill context loading", with a one-paragraph summary + reference to the canonical snippet section. This is the third discoverability surface required by the convention.
  - [x] P1.3 Run `./install.sh` and verify `~/.claude/CLAUDE.md` now contains the new section (the snippet is symlinked-or-injected; re-running install.sh refreshes any per-file copies if applicable).
  - [x] verify-auto
  - [x] verify-self  <!-- 4 outcomes PASS after effortLevel fix + snippet trim -->
  - [x] verify-human  <!-- approved 2026-05-14: trimmed snippet preserves all load-bearing rules -->
  - [x] verify-codify  <!-- 2 new grep_check assertions added to tests/check-structure.sh; perturbation test confirmed catch; 57 PASS / 0 FAIL -->

- [x] Phase 2: Per-skill "Step 0" prompt edits
  **Observable outcomes:**
  - CLI: `grep -l "Step 0: Available product context" skills/task-plan/SKILL.md skills/feature-spec/SKILL.md skills/feature-plan/SKILL.md skills/feature-reproduce/SKILL.md skills/incident-report/SKILL.md skills/product-vision/SKILL.md` lists all 6 paths (every entry-point skill has the new section).
  - CLI: `grep -A2 "Step 0" skills/feature-spec/SKILL.md | grep -c "docs/product/arch.md\|docs/product/wbs.md"` → output ≥ `2` (feature-spec names both eager-read paths).
  - CLI: `grep -A2 "Step 0" skills/feature-plan/SKILL.md | grep -c "docs/product/wbs.md"` → output ≥ `1` (feature-plan names wbs.md).
  - CLI: `grep -A5 "Step 0" skills/feature-plan/SKILL.md | grep -c "already in.*context\|conversation context"` → output ≥ `1` (feature-plan documents the context-skip rule).
  - CLI: `grep -A5 "Step 0" skills/task-plan/SKILL.md skills/incident-report/SKILL.md | grep -c "conditional\|if.*touches\|trigger"` → output ≥ `2` (conditional-read trigger language present in both).
  - CLI: `grep -c "context.md" skills/{task-plan,feature-spec,feature-plan,feature-reproduce,incident-report,product-vision}/SKILL.md` → output `0` for every file (no context.md references anywhere per Loading Strategy rule 5).
  - CLI: `./tests/run-tests.sh --group task --group feature --group incident --group product --dry-run` shows the same scenario count as before Phase 2 (sanity — no scenarios were accidentally removed).
  - CLI: `./tests/run-tests.sh --id S1,F1,F2,F31,I1,P1 --filter-model default` exits 0 with all listed scenarios PASS or SOFT_PASS (the entry-skill routing scenarios are not regressed by the new Step 0 prose).
  - [x] P2.1 Edit `skills/task-plan/SKILL.md`: insert "Step 0: Available product context" section before existing "1. Backlog Check". Lists `docs/product/arch.md` with one-line pointer; conditional-read trigger phrases ("renaming a public API, changing a data shape, modifying a cross-module boundary, altering a workflow state machine") instruct agent to read arch.md only when triggered.
  - [x] P2.2 Edit `skills/feature-spec/SKILL.md`: insert "Step 0: Available product context" section before existing "1. Elicit Requirements". Eager-reads `docs/product/arch.md` and `docs/product/wbs.md` with size-guard mechanic (Read limit 100 + `^#+ ` heading list when file > 300 lines); pointer-only mentions for vision.md, roadmap.md, research.md.
  - [x] P2.3 Edit `skills/feature-plan/SKILL.md`: insert "Step 0: Available product context" section before existing "1. Backlog Check". Conditional eager-read of `docs/product/wbs.md` — skipped if already in conversation context (e.g., from prior feature-spec invocation in same session). Pointer-only for arch.md, vision.md, roadmap.md, research.md.
  - [x] P2.4 Edit `skills/feature-reproduce/SKILL.md`: insert "Step 0: Available product context" section. Pointer-only for all docs (existence list with one-line descriptions, no eager reads, no conditionals). Rationale: bug context lives in the bug itself.
  - [x] P2.5 Edit `skills/incident-report/SKILL.md`: insert "Step 0: Available product context" section. Conditional-read of `docs/product/arch.md` when incident "appears to involve cross-component behavior or system-architecture-level effects"; pointer-only for the rest.
  - [x] P2.6 Edit `skills/product-vision/SKILL.md`: insert "Step 0: Available product context" section. One-line exclusion note explaining why product-vision reads nothing (it WRITES vision.md). Lists no docs.
  - [x] verify-auto  <!-- frontmatter parses, Step 0 unique per file, heading order intact, no duplicates -->
  - [x] verify-self  <!-- 9 outcomes (O1-O8 + structural-check regression guard) all PASS -->
  - [x] verify-human  <!-- approved 2026-05-14: 6 SKILL.md Step 0 sections approved as-written -->
  - [x] verify-codify  <!-- 6 grep_check assertions added (one per entry-point SKILL.md); perturbation test on feature-plan confirmed catch; 63 PASS / 0 FAIL -->

- [x] Phase 3: Test fixtures and scenarios  <!-- SCOPED-DOWN-TO-ZERO 2026-05-14 (user-approved). Rationale: structural enforcement via Phase 1+2 codify (8 grep_check assertions total) is sufficient bar for v1; behavioral end-to-end scenarios would add ~$0.50-$2 per test run for assertions on model-behavior (agent reading/skipping docs) that are harder to test reliably than structure. If a behavioral regression is observed in real use, add a scenario then. -->
  **Observable outcomes:** N/A (phase skipped)
  - [x] P3.1 Skipped — fixtures not needed because no behavioral scenarios added.
  - [x] P3.2 Skipped — oversized fixture not needed (size-guard mechanic is documented in Step 0 prose; behavioral test deferred).
  - [x] P3.3 Skipped — task-plan scenarios deferred.
  - [x] P3.4 Skipped — feature-spec / feature-plan scenarios deferred.
  - [x] P3.5 Skipped — incident-report scenarios deferred.
  - [x] P3.6 Skipped — product-vision scenarios deferred.
  - [x] verify-auto  <!-- N/A; phase skipped -->
  - [x] verify-self  <!-- N/A; phase skipped -->
  - [x] verify-human  <!-- scope-down approved by user 2026-05-14 -->
  - [x] verify-codify  <!-- N/A; phase skipped -->

- [x] Phase 4: Structural enforcement  <!-- ABSORBED into Phase 1 codify (canonical + cross-level grep_checks) + Phase 2 codify (6 per-skill Step 0 grep_checks + perturbation test). check-structure.sh: 57→63 PASS / 0 FAIL after both codify rounds. P4.1 and P4.2 effectively complete; no separate Phase 4 work remains. -->
  **Observable outcomes (all met across Phase 1+2 codify):**
  - CLI: `./tests/check-structure.sh` PASS 63/0 with new assertions printed (canonical + cross-level + 6 per-skill Step 0).
  - CLI: deliberate Step 0 removal (perturbation test on feature-plan) caused check-structure.sh to exit 1; restore returned to 63/0.
  - [x] P4.1 Add structural-check assertions for the Step 0 contract. — Done in Phase 1 codify (2 assertions: canonical + cross-level) + Phase 2 codify (6 assertions: one per entry-point SKILL.md). One enhancement *not* done: "asserts each contains at least one `docs/product/` path reference" — left as maintainer-discretion because (a) for the 4 readers, content drift would be caught by build-time outcomes O2/O3; (b) for pointer-only and excluded skills there is no path requirement.
  - [x] P4.2 Perturbation test — Done in Phase 2 codify: disabled feature-plan Step 0 heading, confirmed check-structure.sh exited 1 with the specific assertion firing; restored to green.
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human  <!-- implicit: Phase 4 outputs landed inside Phase 1 and Phase 2 which both received explicit human approval -->
  - [x] verify-codify  <!-- N/A; Phase 4 itself is the codify -->


## Current Node
- **Path:** entrypoint-skills-load-product-context > finalize
- **Active scope:** finalize (ship complete; commit 786c03f pushed to origin/main)
- **Blocked:** none
- **Unvisited:** finalize
- **Open discoveries:** Phase 4 absorbed into Phase 1+2 codify; Phase 3 scoped-down-to-zero (user-approved 2026-05-14). All work is concentrated in 3 sets of edits: (a) CLAUDE.snippet.md + transitions.md (Phase 1), (b) 6 SKILL.md files (Phase 2), (c) 8 grep_check assertions in tests/check-structure.sh (Phase 1+2 codify). Side-effects: SURFACE-2026-05-13-SETTINGS-FIXTURE-EFFORTLEVEL-DRIFT resolved by re-adding effortLevel=xhigh to ~/.claude/settings.json.
- **Open discoveries:** pre-existing settings-fixture drift (already tracked in backlog as SURFACE-2026-05-13-SETTINGS-FIXTURE-EFFORTLEVEL-DRIFT — not a regression from this feature)

## Discoveries

- [SURFACED-2026-05-14] Phase 1 verify-auto — `./tests/check-structure.sh` initially showed 54 PASS / 1 FAIL on the `effortLevel` settings-fixture drift (`SURFACE-2026-05-13-SETTINGS-FIXTURE-EFFORTLEVEL-DRIFT`). User confirmed they had inadvertently dropped `effortLevel` from `~/.claude/settings.json` when switching between effort modes; the test fixture is correct (xhigh is the intended default). Resolved by re-adding `"effortLevel": "xhigh"` to live settings.json. **Backlog item SURFACE-2026-05-13-SETTINGS-FIXTURE-EFFORTLEVEL-DRIFT now resolved as a side effect of this feature.** `check-structure.sh` now reports 55 PASS / 0 FAIL.
- [SURFACED-2026-05-14] Phase 1 verify-self — User flagged that the initial draft of the canonical-mapping section in `CLAUDE.snippet.md` was too wordy (~55 lines), and since the snippet is auto-injected into `~/.claude/CLAUDE.md` it pays token cost in every future session. Trimmed to 24 lines (60% reduction). Cut: worst-case cost table, "What is NOT loaded" block (folded into rule 3 and table column), 5 rules → 3, discoverability paragraph (collapsed to one sentence). Kept: full mapping table, pointer-default, size guard with concrete read instructions, no-context.md rule, structural-check enforcement reference.

## Retrospect

- **What changed in our understanding:** Three things became sharper during execution:
  1. *Load discipline is the real design problem, not load mapping.* The backlog entry framed this as "which docs map to which skill"; the actual design problem was "how much context cost is each entry-skill invocation allowed to pay, and what's the floor below which we degrade gracefully?" The spec evolved a 5-rule discipline (pointer-default → eager for the 2 most-upstream skills → conditional for 2 trigger-driven ones → 300-line size guard → no context.md) precisely because the user pushed back when the first spec draft treated loading as free.
  2. *Phase 4 was redundant from the start.* The original plan had Phase 4 as a dedicated structural-enforcement phase. In practice, the right place for that work was inline with Phase 1 and Phase 2 codify — because codify is *exactly* where you add the regression guard for what verify-human just approved. Doing it as a separate later phase would have meant verify-human and verify-codify in Phase 1+2 happened against contracts that had no automated test guard for ~1 day.
  3. *Phase 3 was speculative coverage we didn't need.* The plan included behavioral end-to-end scenarios (test fixtures + ~6 scenarios). After Phase 2 verify-codify shipped structural enforcement, behavioral coverage looked like pre-built speculation rather than a real gap. User-approved scope-down was the right call.
- **Assumptions that held:**
  - The canonical-snippet + per-skill-SKILL.md split (snippet = rules, SKILL.md = paths) worked cleanly. The agent needs concrete paths inline in the SKILL.md prompt at invocation time; the snippet is the maintainer-facing reference. Both surfaces agree because they're independently authored from the same mapping.
  - The structural-check pattern (grep_check against fixed headings) scales: 8 new assertions land in `tests/check-structure.sh` using the exact same shape as the existing CHANGELOG / Sidebar / debug-* conventions.
  - The integration-boundary rule from CLAUDE.md fired correctly: each codify pass cited `tests/check-structure.sh` as the consuming surface and added the assertion there.
- **Assumptions that were wrong:**
  - *Initial spec assumed loading was effectively free.* The first draft proposed loading all relevant docs eagerly for every entry skill (e.g., feature-spec reads vision + roadmap + arch + wbs; task-plan reads arch + maybe context.md). User correctly flagged this as wasteful: the snippet is auto-injected into every Claude Code session, so every word costs tokens in every future session, and most entry-skill invocations don't benefit from strategic context at all. The spec was reworked to encode load discipline as a first-class design decision, not an afterthought.
  - *Plan assumed Step 0 would be `### 0. ...` under `## Procedure`.* In practice it became `## Step 0` at the top level (between `## State Machine Context` and `## Procedure`). The existing SKILL.md procedure-numbering convention uses `### N.` subheadings under `## Procedure`, and inserting a `### 0.` would have visually mixed pre-procedure setup with procedure steps. Top-level `## Step 0` reads more naturally and matches the canonical snippet wording — but this was a structural decision discovered during build, not specified upfront.
  - *Plan assumed Phase 4 was a real phase.* See "What changed in our understanding" above — Phase 4 was structural redundancy that codify absorbed naturally.
- **Approach delta:** Plan was 4 phases; actual execution was 2 phases of real work (P1 + P2), with P3 scoped-down-to-zero and P4 absorbed into P1+P2 codify rounds. The work product is the same as the original 4-phase plan would have produced, minus the speculative behavioral scenarios (P3) — and minus the latency that a separate Phase 4 would have introduced. The trim of CLAUDE.snippet.md (55 → 24 lines) was also an unplanned back-loop during Phase 1 verify-self, prompted by user pushback that the canonical snippet was paying too much per-session token cost; this resulted in a tighter, more durable artifact than the original spec sketched.
