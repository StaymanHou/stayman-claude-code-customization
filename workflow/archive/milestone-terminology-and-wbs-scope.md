# Feature: Milestone Terminology and WBS Scope

**Workflow:** feature
**State:** Completed 2026-06-18 — commit ab5f7a2 (amended with review resolutions), not pushed
**Created:** 2026-06-18
**drive_mode:** autopilot

## Problem Statement
The product workflow uses "Phase" as the roadmap's strategic decomposition unit, emits dotted hierarchical milestone numbering (`Milestone 1.1`), and decomposes the entire roadmap into WBS work packages up front. The repo owner wants three durable corrections (captured in `docs/lessons/product-skills-milestone-terminology-and-wbs-scope.md`): (1) roadmap-sense "Phase" → "Milestone", applied backward-compatibly (treat "phase" as a read-alias) across the 5 product-workflow files, while leaving the *feature Work Tree* "Phase" schema untouched (only adding a disambiguating alias note); (2) `product-roadmap` emits FLAT singly-numbered milestones with "Group" headings used only for cosmetic clustering; (3) `product-wbs` decomposes ONLY the immediate next milestone, not the whole roadmap. This is prose-only editing of SKILL.md / AGENTS.md files; the canonical state machine in `transitions.md` is content-checked. Verification is structural (`tests/check-structure.sh`) plus product-group scenarios (`tests/run-tests.sh --group product`), which must still PASS since transition IDs are unchanged.

## Work Tree

- [x] Phase 1: Roadmap milestone terminology + flat numbering + groups  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -c 'Milestone' skills/product-roadmap/SKILL.md` ≥ 3 (template + prose now say "Milestone")
  - CLI: `grep -E 'Milestone 1\.1|Milestone [0-9]+\.[0-9]' skills/product-roadmap/SKILL.md` exits 1 (no matches — no dotted numbering remains in the template)
  - CLI: `grep -qi 'group' skills/product-roadmap/SKILL.md` exits 0 (cosmetic "Group" heading guidance present)
  - CLI: `grep -qi 'phase.*alias\|alias.*phase\|recognized.*phase\|read.*phase' skills/product-roadmap/SKILL.md` exits 0 (backward-compat read-alias note present)
  - CLI: `tests/check-structure.sh` exits 0 (no structural regression; product-roadmap argument-hint + frontmatter intact)
  - [x] P1.1 Edit `skills/product-roadmap/SKILL.md`: rename roadmap template `### Phase N:` → `### Milestone N:`, switch `Milestone 1.1/1.2` to flat single-number milestone bullets, add cosmetic "Group" heading guidance, add an explicit "phase = read-alias for milestone" backward-compat note, update surrounding prose ("logical phases" → "milestones", "each phase" → "each milestone", "next phase" → "next milestone")  <!-- status: complete -->
  - [x] P1.2 Update the skill's frontmatter `description` if it says "phased milestones" → keep readable but milestone-forward  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; check-structure.sh 251 PASS / 0 FAIL; 4 grep outcomes pass -->
  - [x] verify-self  <!-- status: complete; runner subagent: 6/6 outcomes PASS, no integration boundary (prose artifact) -->
  - [x] verify-human  <!-- status: complete; AUTO-SKIP (F11) — drive_mode=autopilot, no integration boundary, verify-self all-PASS -->
  - [x] verify-codify  <!-- status: complete; +5 structural pins in check-structure.sh (256 PASS/0 FAIL) -->

- [x] Phase 2: WBS next-milestone-only scope + milestone terminology  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -qi 'next milestone\|immediate next\|only.*milestone' skills/product-wbs/SKILL.md` exits 0 (next-milestone-only scoping rule present)
  - CLI: `grep -qi 'milestone' skills/product-wbs/SKILL.md` exits 0 (milestone terminology adopted, with phase alias-on-read retained where it references roadmap units)
  - CLI: `tests/check-structure.sh` exits 0 (no structural regression)
  - [x] P2.1 Edit `skills/product-wbs/SKILL.md`: added Terminology note (milestone unit / phase read-alias / feature-Work-Tree-Phase is different) + "decompose ONLY the immediate next milestone" Scope section; renamed roadmap-sense "phase" → "milestone" (WP/Probe template `**Phase:**` → `**Milestone:**`, learning-sequence ordering reworded WP-relative, orchestration-ordering rule reworded WP/milestone-relative)  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; 2 grep outcomes PASS, frontmatter intact, check-structure 256/0 -->
  - [x] verify-self  <!-- status: complete; runner subagent 6/6 PASS, no integration boundary (prose artifact) -->
  - [x] verify-human  <!-- status: complete; AUTO-SKIP (F11) — drive_mode=autopilot, no integration boundary, verify-self all-PASS -->
  - [x] verify-codify  <!-- status: complete; +3 structural pins (259 PASS/0 FAIL) -->

- [x] Phase 3: Downstream consumers (finalize, context, product AGENTS) + alias note  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -qi 'milestone' skills/product-finalize/SKILL.md` exits 0 (roadmap-loop prose milestone-aware, phase alias retained)
  - CLI: `grep -qi 'milestone' skills/product-context/SKILL.md` exits 0
  - CLI: `grep -qi 'milestone' agents/product-workflow/AGENTS.md` exits 0 (roadmap state row milestone-forward)
  - CLI: `grep -qi 'phase' CLAUDE.snippet.md` exits 0 (feature Work Tree "Phase" schema UNCHANGED — still present)
  - CLI: `tests/run-tests.sh --group product --dry-run` lists product scenarios (harness intact); full product-group run PASSes at verify-codify
  - CLI: `tests/check-structure.sh` exits 0
  - [x] P3.1 Edit `skills/product-finalize/SKILL.md`: roadmap-loop prose → milestone-forward with phase read-alias  <!-- status: complete -->
  - [x] P3.2 Edit `skills/product-context/SKILL.md`: "roadmap.md (milestones)", "Current Milestone", "Active milestone" → milestone-forward  <!-- status: complete -->
  - [x] P3.3 Edit `agents/product-workflow/AGENTS.md`: roadmap+arch state rows + P3 condition → milestone-forward with read-alias  <!-- status: complete -->
  - [x] P3.4 Confirmed `CLAUDE.snippet.md` feature Work Tree "Phase" untouched (empty git diff); added disambiguation note to project `CLAUDE.md` Work Tree Format section. SCOPE-SYMMETRY: also renamed product-arch/product-research/product-vision roadmap-sense phase (see Discoveries)  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; 8 grep outcomes PASS, snippet untouched, CLAUDE.md 36360c <40k, check-structure 259/0 -->
  - [x] verify-self  <!-- status: complete; runner subagent 9/9 PASS, no integration boundary; product-group harness intact (18 scenarios) -->
  - [x] verify-human  <!-- status: complete; AUTO-SKIP (F11) — drive_mode=autopilot, no integration boundary, verify-self all-PASS -->
  - [x] verify-codify  <!-- status: complete; +6 structural pins (265 PASS/0 FAIL); P3 behavioral smoke SOFT_PASS (roadmap prose rename safe) -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** finalize — review-quality complete (0 CRITICAL, all findings resolved in-place)
- **Blocked:** none
- **Unvisited:** (none — finalize is terminal)
- **Open discoveries:** none

## Retrospect
- **What changed in our understanding:** The blast radius was larger than the plan's "5 product-workflow files." Roadmap-sense "phase" lived in 9 files (the 5 planned + product-arch/research/vision) plus `transitions.md` (the tripartite-sync third leg). The scope-symmetry discipline (grep the whole surface before sealing) is what caught the extra skills mid-build; the code-quality reviewer caught the transitions.md miss post-ship.
- **Assumptions that held:** The roadmap-vs-feature-Work-Tree "Phase" distinction was the only real design decision, and it was settled up front by the operator (keep feature Work Tree, rename roadmap, alias-on-read). Prose-only edits with structural pins as the codify surface was the right altitude — a full behavioral scenario rerun was unnecessary (P3 smoke confirmed transition-safety).
- **Assumptions that were wrong:** The plan said "the canonical state machine in transitions.md is content-checked" and reasoned that transition IDs being unchanged meant transitions.md needed no edit — but that sidestepped the *condition-string* drift (P3 "has phases" vs AGENTS.md "has milestones"). CLAUDE.md's explicit "state machine lives in three places, keep them in sync" rule should have pulled transitions.md into the plan from the start.
- **Approach delta:** Three findings (1 MAJOR + 2 MINOR) from the post-ship reviewer were resolved in-place during review-quality rather than backlogged, since all three were trivial atomic-completeness fixes within the feature's own theme (and the lesson doc itself flagged transitions.md as affected). Ship commit was amended to fold them in. Otherwise implementation matched the plan: 3 phases, zero build back-loops, all verify-human auto-skipped (no integration boundary).

## Code-Quality Review — milestone-terminology-and-wbs-scope

Reviewer subagent (code-quality-reviewer) run against ship commit cf4f639. Found 0 CRITICAL, 1 MAJOR, 2 MINOR. **All three findings resolved in-place during review-quality** (trivial atomic-completeness fixes within the feature's own theme; fresh re-verification via check-structure.sh 267/0).

### Strengths
- "Phase vs. Milestone" disambiguation note in CLAUDE.md is crisp and load-bearing.
- Read-alias backward-compat coherently applied (write "Milestone", read both); leaves live dogfood roadmap.md valid.
- Scope-symmetry shortcut (arch/research/vision) properly disciplined with all three gates + audit trail.
- Negative dotted-numbering pin well-shaped.
- product-wbs next-milestone scope well-motivated and threaded through ordering prose.

### Issues
**CRITICAL** — (none)

**MAJOR**
- [RESOLVED] [docs/product/transitions.md:248] P3 condition still said "Roadmap has phases defined" while AGENTS.md + product-roadmap SKILL.md were renamed to "milestones" — tripartite-sync drift (CLAUDE.md "state machine lives in three places"). **Fixed:** line 248 → "Roadmap has milestones defined"; added structural pin to lock tripartite sync. This was a genuine completeness gap in the feature's own theme (the lesson flagged transitions.md as affected), so fixed now rather than backlogged.

**MINOR**
- [RESOLVED] [check-structure.sh] Four "milestone-forward" pins asserted only bare substring "milestone" — low altitude. **Fixed:** replaced with token-specific anchors (`## Current Milestone`, `Milestone Focus`, `which milestone this architecture`, `For each milestone defined`).
- [RESOLVED] [product-vision] Renamed but unpinned while 4 siblings got pins. **Fixed:** added `into milestones` pin.

### Assessment
Well-built, low-risk prose refactor; changes write-time vocabulary while keeping read-time backward compat, with a bright dated line around the deliberately-untouched feature Work Tree "Phase" schema. The one substantive gap (transitions.md tripartite-sync) and the two pin-sturdiness nits were all resolved in-place. Net: advances the codebase, no residual debt.

### If you disagree
Operator: the three findings were resolved in-place (not backlogged). To revert any resolution, see the commit diff; the original findings are preserved above.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
[SHORTCUT-2026-06-18] review-quality — resolved 1 MAJOR (transitions.md P3 tripartite-sync drift) + 2 MINOR (pin altitude) in-place during review-quality rather than backlogging; all three are trivial atomic-completeness fixes within the feature's own theme. Re-verified via check-structure.sh (267/0).
[SHORTCUT-2026-06-18] P3.1-P3.4 — scope-symmetry sweep (per docs/lessons/scope-symmetry.md) found roadmap-sense "phase" also in skills/product-arch, skills/product-research, skills/product-vision beyond the 5 files the plan enumerated. Folded these into Phase 3 (trivial same-theme extension: identical milestone-rename + read-alias treatment); re-verified via fresh check-structure.sh run (259/0) + grep sweep (zero leftover roadmap-sense phase). No back-loop needed — these are downstream consumers of the same terminology rule, within Phase 3's "downstream consumers" theme.
