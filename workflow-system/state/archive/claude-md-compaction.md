---
drive_mode: autopilot
---

# Feature: CLAUDE.md compaction

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-13
**Entry:** spec (complex feature)

## Problem Statement

The project's `CLAUDE.md` is **54,528 chars** — this is the file the harness warning fires on (`⚠ Large CLAUDE.md will impact performance (54.1k chars > 40.0k)` matches the project file alone; the harness measures per-file). For full context: the global `~/.claude/CLAUDE.md` adds another **19,303 chars** that also get loaded on every session, bringing combined CLAUDE.md context to **~73.8k chars**. The global file is **out of scope** per the user's direction (different lifecycle, different file under `CLAUDE.snippet.md` source control), but the combined cost informs framing: even at the 35k-char target on the project file, ~54k chars of CLAUDE.md instructions stay loaded — meaningful headroom on the harness signal, but the adherence/context-rot cost the Anthropic docs warn about applies to total loaded instructions, not just per-file.

Anthropic's own guidance on the warning is twofold: (1) **adherence** — "bloated CLAUDE.md files cause Claude to ignore your actual instructions" (best-practices doc); (2) **context rot** — model recall degrades as token count grows (effective-context-engineering doc). The token-cost angle is the lesser problem; the adherence/attention angle is the load-bearing one.

The dominant cost lives in the `## Conventions` section (lines 215–251 of the current file) — ~35 multi-paragraph bullets, several pushing 10–30 lines each, accumulated across recent ship cycles. Many of these bullets are now redundantly covered by `docs/product/arch.md`'s `## Revision 2026-06-13` section (added by the just-shipped `arch-resync-2026-06-13` task). Others restate full incident histories with anchor dates and SURFACE-IDs that would fit better as standalone lesson docs (precedent: `docs/lessons/scope-symmetry.md`, `test-harness-primitives.md`, `test-scenario-strict-mode.md` are already pointer-shaped one-line bullets backed by extracted lesson files — this is the established compression pattern in the repo).

The objective is **mechanical**: drop `wc -c CLAUDE.md` from ~54.5k to ≤35k chars (≥36% reduction, ~5k chars of safety margin below the 40k threshold) while preserving every load-bearing convention. Compression is the technique; pruning is the discipline; arch.md and `docs/lessons/` are the destinations.

## User Stories

- As the project's primary operator, when I open a new Claude Code session in this repo, the startup warning about CLAUDE.md size does not fire — so I know the harness is reading my instructions with full adherence.
- As an agent invoked in this repo, I read a CLAUDE.md that fits in a single attention span — so I don't silently drop conventions on the floor when picking what to attend to.
- As the maintainer adding a new convention in the future, I have a structural pin (`tests/check-structure.sh`) that fails CI-equivalent if my edit pushes CLAUDE.md back above 40k chars — so the regression is mechanical, not social.
- As the maintainer running `/feature-finalize`, the skill prompts me to consider whether any new convention bullets added during the just-finished feature would be better placed as lesson docs — so the prune cadence becomes a per-feature habit, not a quarterly chore that drifts.

## Acceptance Criteria

The feature is done when ALL of the following hold:

1. **`wc -c CLAUDE.md` ≤ 40000.** Hard mechanical target — the actual harness threshold that fires the warning. Originally drafted as ≤35000 (5k headroom) but relaxed at P1.1 audit time per user direction: DEDUP work (8 bullets, ~8,144 chars potentially recoverable) is held back as a follow-up lever; DELETE + EXTERNALIZE alone are the conservative path. If Phase 2 doesn't clear the threshold with adequate margin, DEDUP becomes the recovery lever (revisit at verify-self time).
2. ~~`tests/check-structure.sh` includes a `wc -c < CLAUDE.md ≤ 40000` assertion~~ **— SUPERSEDED 2026-06-13 (Phase 3 dropped at user direction).** Reasoning: the 40k threshold lives in the Claude Code harness (out of our control), the harness already self-surfaces the warning on every session start (natural feedback loop), and a structural pin would add friction for future legitimate convention additions while only mattering if structural sweeps run more often than sessions start (they don't). The 4,280-char headroom from Phases 1+2 plus the Phase 4 prune-cadence prompt are the regression-prevention mechanisms.
3. **Every bullet that gets externalized has a one-line pointer in CLAUDE.md** following the existing pattern (`See \`docs/lessons/<topic>.md\`.` or `See \`docs/product/arch.md\` → "<section name>".`). Externalization without a pointer would silently lose discoverability — see Convention bullet about "discoverability surfaces" already in the file.
4. **No durable convention is lost.** Every bullet currently in `## Conventions` either (a) remains as a compressed one-line imperative, (b) gets a pointer to its new home in `arch.md` or `docs/lessons/`, or (c) is explicitly deleted as obsolete with a rationale captured in the WIP `## Discoveries` section. Implicit deletion is forbidden — the audit trail matters for future readers grepping the convention history.
5. **Standalone `util-prune-claude-md` skill exists.** *(Revised 2026-06-13 mid-Phase-4 at user direction — replaced the original feature-finalize edit.)* Lives at `skills/util-prune-claude-md/SKILL.md`, installed into `~/.claude/skills/` via `./install.sh`. User-triggered manually when the 40k warning fires at session start (not embedded in any workflow's close path). Presents a 4-mode menu at entry (Step-by-step / Batch-approve / Autopilot / Dry-run) modeled on the workflow drive modes. Edits the project-root `CLAUDE.md` only — explicitly out of scope for the global `~/.claude/CLAUDE.md`. The `util-*` category is formalized in `docs/product/arch.md` Revision 2026-06-13 as a third skill category (standalone user-triggered utilities, distinct from workflow skills and debug-* sidebars). Predecessor skills `init` and `review` are retroactively considered part of util-* but not renamed.
6. **Structural tests pass.** `./tests/check-structure.sh` exits 0 after all changes, including the new char-count pin.
7. **All existing test scenarios still pass.** No test scenarios in `tests/scenarios/*.yaml` assert against CLAUDE.md content directly (verified at plan time via grep), so no scenario edits should be required — but verify-codify will sweep the feature group to confirm.

## Out of Scope

- **Line count.** Anthropic's docs cite 200 lines as a soft target, but the actual harness signal is character count. We optimize for what the harness measures.
- **Splitting CLAUDE.md into per-directory child files (`<subdir>/CLAUDE.md`).** Anthropic's docs describe this as a layered-context pattern; for this repo's flat skill/agent structure, it would add navigation cost without solving the char-count problem (each file would still be loaded). Re-evaluate only if a future cycle introduces a clear domain boundary (e.g., a separate `tools/claude-time/` subproject with materially different conventions).
- **`@`-imports / `.claude/rules/<topic>.md` decomposition.** Per Anthropic's memory doc, `@`-imports do not reduce loaded context — they only reorganize. `.claude/rules/` with `paths:` frontmatter could in principle help, but introduces a third location for "instructions Claude reads" (alongside `~/.claude/CLAUDE.md` global + project-root `CLAUDE.md`). Defer until the post-compaction file proves insufficient.
- **Touching `~/.claude/CLAUDE.md` (the global instructions) or `CLAUDE.snippet.md`.** Global instructions are managed under a different lifecycle; the snippet is its source. The project-root `CLAUDE.md` is the only file under scope. The global file (19,303 chars) is acknowledged as contributing to combined loaded-context cost but is **explicitly out of bounds** per user direction at spec time.
- **Restructuring the non-Conventions sections.** `## What This Repo Is`, `## Commands`, `## Architecture`, `## Product Workflow Notes`, `## Current Phase`, `## Claude-time visualize URL-hash state` are all in scope for dedup against `arch.md` where overlap exists, but their *section structure* is not under review. We compress within the existing skeleton.
- **The `## Claude-time visualize URL-hash state` table.** Looks long but is a *registry table* — each row is a one-line key reservation, which is already the densest possible form. Out of scope; touch only if a row is genuinely stale.
- **Auto-archiving / git-history cleanup of removed content.** Externalized content goes to `docs/lessons/<topic>.md` (new files) or merges into existing `arch.md` revisions. No git history rewriting.

## Technical Constraints

- **Mechanically-verifiable acceptance criterion.** The 40k-char threshold is in the Claude Code harness (string match on the literal warning text). We pin against `wc -c < CLAUDE.md ≤ 40000` in `check-structure.sh` because that's the underlying metric the harness uses.
- **Existing precedent for the externalize pattern.** Three lesson docs already exist (`docs/lessons/scope-symmetry.md`, `test-harness-primitives.md`, `test-scenario-strict-mode.md`) and their corresponding CLAUDE.md bullets are already one-line pointer-shaped. New extractions follow this exact shape — no novel formatting.
- **arch.md size guard at 322 lines.** Already over the 300-line soft cap per the global product-context-loading rules. Folding additional content into arch.md must be done sparingly — preferably as expansions of the existing `## Revision 2026-06-13` subsections rather than new freestanding sections. The size guard isn't a hard block, but it's a flag that arch.md is also under pressure.
- **No code-path changes.** This is a docs-only feature. No `tests/scenarios/*.yaml` edits expected (verify at plan time); no `skills/*/SKILL.md` edits except for `feature-finalize` (the prune-cadence prompt); no `agents/*/AGENTS.md` edits expected. `tests/check-structure.sh` gains one pin block (~5 lines).
- **Step-by-step drive mode.** User selected Mode 1 at session start. Every skill returns control to the user between phases — no auto-chain.
- **Recent-ship overlap is the highest-ROI target.** Convention bullets added by the last ~5 ship cycles (verify-self-and-review-quality-subagent-dispatch, verify-sh-contains-required, sweep-quality-findings-2026-06-13, arch-resync-2026-06-13) are the most likely to have a parallel home in arch.md's 2026-06-13 revision. Grep these date anchors first.

## Open Questions

(none — research is complete; the externalize/dedup/pin/cadence approach is concrete and the targets are mechanical)

## Work Tree

- [x] Phase 1: Audit + delete HISTORICAL bullets (DEDUP held back per user direction)  <!-- status: complete — 1,656 chars removed; wc -c 54528 → 52872 -->
  **Observable outcomes:**
  - CLI: `wc -c /Users/stayman/Personal/projects/my-claude-code-customization/CLAUDE.md` — reports a value at least 1500 chars lower than the Phase 0 baseline of 54528 (i.e. ≤ 53028 after Phase 1; DELETE-only since DEDUP is deferred).
  - CLI: `grep -c "v3 sub-payload routing pattern: useMemo with v2-alias fallback" CLAUDE.md` returns `0` (the explicit HISTORICAL/retired-2026-06-03 bullet is deleted).
  - File: `docs/product/arch.md` is unchanged (`git diff docs/product/arch.md` is empty after Phase 1 — we are not moving content into arch.md).
  - File: `## Classification Audit` block in this WIP captures the full 32-bullet verdict table, including the 8 DEDUP candidates parked for potential follow-up.
  - [x] P1.1 Inline classification pass — produced `## Classification Audit` table; 32 bullets classified (8 DEDUP-deferred, 1 DELETE, 11 EXTERNALIZE, 12 KEEP). Updated scope: DELETE + EXTERNALIZE only.  <!-- status: complete -->
  - [x] P1.2 Apply DELETE verdicts — deleted bullet #26 (v3 sub-payload routing pattern, HISTORICAL/retired 2026-06-03). `wc -c CLAUDE.md`: 54528 → 52872 (1,656 chars removed). Phase 1 observable ≤ 53028 met with 156 chars to spare.  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete — wc -c 52872 ≤ 53028; grep "v3 sub-payload" returns 0; bullet count 31 (expected); check-structure.sh PASS 251/FAIL 0 -->
  - [x] verify-self  <!-- status: complete — subagent PASS 4/4: wc -c 52872; grep deleted-bullet returns 0; arch.md unchanged (git diff --stat empty); audit table has 32 rows. No integration boundary — docs-only feature, no runtime surface. -->
  - [x] verify-human  <!-- status: complete — F11 human-confirmed skip; no integration boundary, no UI/endpoint/CLI to manually exercise, verify-self 4/4 PASS. -->
  - [x] verify-codify  <!-- status: complete — no new tests needed (one-time content deletion, no stable behavioral contract; the durable wc -c ≤ 40000 contract is Phase 3's deliverable). check-structure.sh PASS 251/FAIL 0. -->

- [x] Phase 2: Externalize the giants to `docs/lessons/<topic>.md`  <!-- status: complete — 17,152 chars removed; wc -c 52872 → 35720 -->
  **Observable outcomes:**
  - CLI: `wc -c CLAUDE.md` ≤ 35000 (the spec's mechanical acceptance criterion — combined Phase 1 + 2 must clear this).
  - CLI: `ls docs/lessons/` reports at least 2 new files beyond the existing 3 (`scope-symmetry.md`, `test-harness-primitives.md`, `test-scenario-strict-mode.md`). Target additions (from the largest remaining bullets after Phase 1): `docs/lessons/downstream-contract-impacts.md` (covers the ~30-line bullet about literal-payload-object / array-length / function-signature / variable-binding subcases — 8 instances), `docs/lessons/debug-skill-template.md` (covers the "Adding a new debug-* sibling skill" bullet — ~10 lines), and `docs/lessons/category-discoverability.md` (covers "A new skill category needs three structurally-enforced discoverability surfaces" — ~5 lines, but bundles well with debug-skill-template since they share context).
  - CLI: for each new lesson file, `grep -F "<lesson-title>" CLAUDE.md` returns 1 (a one-line pointer exists in CLAUDE.md following the existing pattern: `- **<title> — see \`docs/lessons/<file>.md\`.`).
  - File: each new `docs/lessons/<topic>.md` has the same frontmatter shape as `docs/lessons/scope-symmetry.md` (precedent file — check shape via `head -10`).
  - CLI: `wc -l docs/lessons/*.md` shows that the externalized content lives in the new files (each ≥ 30 lines for the giants, ~10 lines for the smaller ones).
  - [x] P2.1 Identify externalization candidates — confirmed from Phase 1 audit: 11 EXTERNALIZE bullets bundle into 6 lesson files. By projected char savings: downstream-contract-impacts.md (~6,610 — bullets #13/#24/#25/#27), debug-skill-template.md (~4,970 — bullets #16/#17/#30), test-scenario-routing-forks.md (~1,500 — #12), work-tree-leaf-substitution.md (~1,230 — #32), harness-bootstrap-skip.md (~1,170 — #31), test-harness-sweep-discipline.md (~810 — #28). Total projected: ~16,290 chars removed minus ~1,200 chars of pointer text = ~15,100 net.  <!-- status: complete -->
  - [x] P2.2 Wrote `docs/lessons/downstream-contract-impacts.md` (bundles bullets #13/#24/#25/#27). 4 CLAUDE.md bullets → 1 pointer. wc -c: 52872 → 45342 (-7,530).  <!-- status: complete -->
  - [x] P2.3 Wrote `docs/lessons/debug-skill-template.md` (bundles bullets #16/#17/#30 — recipe + two underlying disciplines). 3 CLAUDE.md bullets → 1 pointer. wc -c: 45342 → 40466 (-4,876).  <!-- status: complete -->
  - [x] P2.4 Wrote 4 additional lesson files: `test-scenario-routing-forks.md` (#12), `test-harness-sweep-discipline.md` (#28), `harness-bootstrap-skip.md` (#31), `work-tree-leaf-substitution.md` (#32). 4 CLAUDE.md bullets → 4 pointers. wc -c: 40466 → 35720 (-4,746). Total Phase 2: -17,152 chars; final 35,720 — comfortably under 40k (4.3k headroom) and close to original 35k target.  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete — wc -c 35720 ≤ 40000 (and within 720 of original 35000 stretch); 6/6 pointers present; 9 lesson files with valid # Title headings; Conventions bullet count 26 (expected); check-structure.sh PASS 251/FAIL 0 -->
  - [x] verify-self  <!-- status: complete — subagent PASS 5/5: wc -c 35720 (SOFT_PASS on ≤35k stretch, clean PASS on ≤40k acceptance); 9 lesson files; 6/6 pointers; all new files use precedent `# Title` shape; sizing rule met (bundled ≥30, single ≥10). No integration boundary. -->
  - [x] verify-human  <!-- status: complete — F11 human-confirmed skip; no integration boundary, no UI/endpoint/CLI to manually exercise, verify-self 5/5 PASS. -->
  - [x] verify-codify  <!-- status: complete — no new tests needed (content-relocation phase; the durable wc -c ≤ 40000 contract is Phase 3's deliverable; pinning specific filenames/bullet count would over-constrain future maintainers). check-structure.sh PASS 251/FAIL 0. -->

- [~] Phase 3: ~~Pin `wc -c < CLAUDE.md ≤ 40000` in `tests/check-structure.sh`~~  <!-- status: SKIPPED 2026-06-13 at user direction during verify-human — pin reverted; check-structure.sh restored to baseline (PASS 251/FAIL 0). Reasoning: 40k threshold lives in harness (out of our control), harness self-surfaces warning on every session start (natural feedback loop), pin would add friction for future legitimate convention additions, structural sweeps run less often than sessions start. Phase 4 prune-cadence prompt becomes the regression-prevention mechanism. -->
  **Audit trail (work attempted before SKIP decision — all reverted):**
  - P3.1 [completed-then-reverted]: Read existing helpers in `tests/check-structure.sh` (canonical idiom = `check "$desc" "pass"|"fail" "$detail"`).
  - P3.2 [completed-then-reverted]: Added Phase 12 block (19 lines) at lines 1733–1751; pin ran and PASSed at 35720 bytes.
  - P3.3 [completed-then-reverted]: Synthetic-fail test on 65720-byte copy confirmed pin FAILs as designed.
  - verify-auto [completed-then-reverted]: full sweep PASS 252/FAIL 0; Phase 12 label + PASS line present.
  - verify-self [completed-then-reverted]: subagent PASS 5/5; integration boundary noted.
  - verify-human [in-progress-when-reverted]: user halted at the human captured-CLI leaf, decided the pin was the wrong mechanism.
  **Revert action:** `tests/check-structure.sh` restored to pre-Phase-3 state; confirmed `./tests/check-structure.sh` → PASS 251/FAIL 0 (back to Phase-2-end baseline).

- [x] Phase 4: Create standalone `util-prune-claude-md` skill + formalize `util-*` category  <!-- status: complete — new skill file + symlink + arch.md subsection; YAML defect caught and fixed inline at verify-auto; SURFACE filed for follow-up -->
  **Observable outcomes:**
  - File: `skills/util-prune-claude-md/SKILL.md` exists with `name: util-prune-claude-md` frontmatter, `argument-hint`, and the 4-mode menu prose (Step-by-step / Batch-approve / Autopilot / Dry-run).
  - File: `~/.claude/skills/util-prune-claude-md` symlink exists pointing to the repo source (created by `./install.sh`).
  - CLI: `./install.sh` exits 0 after invocation.
  - CLI: `grep -c "mode" skills/util-prune-claude-md/SKILL.md` returns ≥ 4 (one per mode at minimum).
  - File: `docs/product/arch.md` Revision 2026-06-13 gains a new `### util-* skill category` subsection describing the third skill category (standalone user-triggered utilities), naming `util-prune-claude-md` as the first member and noting `init` / `review` as predecessor utilities retroactively considered part of the category but not renamed.
  - CLI: `./tests/check-structure.sh` still exits 0 (no regressions from the new skill files; the structural-check script does not yet have util-* pins so this is a no-impact change for the test suite).
  - [x] P4.1 Design complete. Frontmatter: `name: util-prune-claude-md`, `description`, `argument-hint`. NO `tools:` (not an executable subagent), NO `skills:` list (not an orchestrator). 4-mode menu (1=Step-by-step / 2=Batch-approve / 3=Autopilot / 4=Dry-run — mirrors workflow drive modes). Procedure: §1 Measure → §2 Inventory bullets w/ char counts → §3 Triage (DEDUP if parallel arch.md coverage; EXTERNALIZE if multi-paragraph lesson-shaped; DELETE if HISTORICAL/retired-marked) → §4 Present + apply by mode → §5 Re-measure + report delta. Scope guard: project-root CLAUDE.md only; refuses to touch global `~/.claude/CLAUDE.md`. Predecessor utilities (init/review) are built into Claude Code itself — not file-based — so util-prune-claude-md is the first file-based utility in this repo. install.sh symlinks via iteration over `skills/*/` so the new dir picks up automatically.  <!-- status: complete -->
  - [x] P4.2 Created `skills/util-prune-claude-md/SKILL.md` (~ 4.7k chars; sections: Category Context, What it does, Scope guard hard, When to use, When NOT to use, Modes, Procedure with 6 steps, Output format, Pitfalls). 4-mode menu at entry mirrors workflow drive modes; scope-guard locks edits to project-root CLAUDE.md only.  <!-- status: complete -->
  - [x] P4.3 Ran `./install.sh`; symlink `~/.claude/skills/util-prune-claude-md` → repo source confirmed via `ls -la`. Install report: `[ok] skills/util-prune-claude-md (already linked)` on second run.  <!-- status: complete -->
  - [x] P4.4 Added `### util-* skill category` subsection to `docs/product/arch.md` between the `debug-*` and `verify-self` subsections of Revision 2026-06-13. Distinguishes from workflow skills (no state node, no transitions) and debug-* sidebars (no RETURN-TO, not caller-pulled). Names util-prune-claude-md as the first member; mentions the Claude-Code-builtin utilities (init/review/etc.) as conceptual predecessors but NOT renamed. arch.md grew 322 → 339 lines (still over the 300-line guard — flagged separately, out of scope here).  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete — caught + fixed 1 YAML frontmatter defect (invalid argument-hint colon), surfaced SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN. After fix: YAML frontmatter parses, symlink resolves, arch.md subsection present, check-structure.sh PASS 251/FAIL 0, grep mode count 16 ≥ 4. -->
  - [x] verify-self  <!-- status: complete — subagent PASS 7/7: SKILL.md YAML parses as 3-key dict; symlink → repo source; install.sh idempotent exit 0; grep mode = 16; arch.md util-* subsection in Revision 2026-06-13; util-prune-claude-md mentioned 2x in arch.md; check-structure.sh PASS 251/FAIL 0. No integration boundary — phase adds isolated new artifacts only. -->
  - [x] verify-human  <!-- status: complete — F11 human-confirmed skip; no integration boundary, isolated new artifacts only, verify-self 7/7 PASS. -->
  - [x] verify-codify  <!-- status: complete — no new tests needed (the one durable contract worth pinning — YAML frontmatter parseability across SKILL.md/AGENTS.md — is filed as SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN follow-up, not as a feature-specific test; all other behaviors are operator-supervised, additive-doc-only, or already covered by existing structural assertions). check-structure.sh PASS 251/FAIL 0. -->

  **Audit trail (Phase 4 first attempt — work completed, then reverted at user direction 2026-06-13 verify-human-pause):**
  - P4.1 [completed-then-reverted]: Located insertion point in `skills/feature-finalize/SKILL.md` §1 (sub-bullet under existing CLAUDE.md update bullet, line 34).
  - P4.2 [completed-then-reverted]: Inserted 1-line prune-cadence prompt naming `docs/lessons/<topic>.md` + `docs/product/arch.md` + the 40k harness threshold rationale.
  - verify-auto + verify-self [completed-then-reverted]: 4/4 + subagent 5/5 PASS.
  - verify-human [in-progress-when-reverted]: at the source-eyeball check, operator decided the embedded-in-feature-finalize approach was wrong. Reasoning: forces the cadence into every feature's close path even when CLAUDE.md isn't bloated; demand-driven user-triggered skill is the better mechanism.
  - **Revert action:** `skills/feature-finalize/SKILL.md` restored to pre-P4 state; diff against `~/.claude/skills/feature-finalize/SKILL.md` confirms symlink propagated.

## Current Node
- **Path:** Feature > finalize
- **Active scope:** Review-quality complete (4 MINOR auto-backlogged, 0 MAJOR, 0 CRITICAL). Findings persisted in WIP `## Code-Quality Review` section + `workflow/backlog-quality-findings.md` + pointer in `workflow/backlog.md`. Ready for finalize.
- **Blocked:** none
- **Unvisited:** finalize.
- **Open discoveries:** [SURFACED-2026-06-13] arch.md size guard exceeded (322 lines) — flagged at spec time. [DELETED-2026-06-13] bullet #26 — see `## Discoveries`. [DEFERRED-2026-06-13] 8 DEDUP bullets parked per user direction at P1.1 review. [REVIEW-MINOR] 4 quality findings auto-backlogged 2026-06-13.

## Classification Audit (P1.1)

Each bullet in CLAUDE.md `## Conventions` (lines 217–251) classified against arch.md Revision 2026-06-13 + the size/shape signal. Verdicts: **DEDUP** (covered by arch.md → replace with pointer), **DELETE** (obsolete/HISTORICAL → remove entirely), **EXTERNALIZE** (Phase 2 target → extract to `docs/lessons/<topic>.md`), **KEEP** (already compressed or operational fact).

| # | Bullet (leading bold phrase) | Line(s) | Chars | Verdict | Destination / Rationale |
|---|---|---|---|---|---|
| 1 | `install.sh is idempotent` | 217 | ~150 | KEEP | Operational, already one line |
| 2 | Skill frontmatter fields | 218 | ~120 | KEEP | Concrete operational fact, one line |
| 3 | Agent frontmatter `skills:` list | 219 | ~110 | KEEP | One line; complements arch.md's `tools:` coverage |
| 4 | PR description references transition | 220 | ~140 | KEEP | One line |
| 5 | **Orchestrator pause policy** (dual location) | 221 | 1149 | **DEDUP** | arch.md → "Drive modes (1–4) — orchestrator pause-policy contract" |
| 6 | **task-verify single-step gate** | 222 | 715 | **DEDUP** | arch.md → "`task-verify` single-step gate (T5a / T5b / T5c)" |
| 7 | **feature-review-quality** | 223 | 2143 | **DEDUP** | arch.md → "`feature-review-quality` — post-ship code-quality reviewer subagent" |
| 8 | **Close-commit discipline** | 224 | 1191 | **DEDUP** | arch.md → "Close-commit discipline (workflow-system convention)" |
| 9 | **Test triage at verify-codify** | 225 | 380 | **DEDUP** | arch.md → "verify-codify test failure triage protocol" (Revision 2026-05-02) |
| 10 | **Integration-boundary rule** | 226 | ~520 | KEEP | Not in arch.md; specific rule, brief enough |
| 11 | **Test scenario `expect:` fields** | 227 | ~1100 | KEEP (Phase 2 candidate) | Test-harness specifics; long but not multi-paragraph lesson-shaped |
| 12 | **Test scenario design — routing-fork patterns** | 228–231 | ~1500 | EXTERNALIZE | Phase 2 → `docs/lessons/test-scenario-routing-forks.md` |
| 13 | **Plan-level "downstream contract impacts" pass** | 232 | ~720 | EXTERNALIZE | Phase 2 → bundle into `docs/lessons/downstream-contract-impacts.md` (with #24, #25, #27) |
| 14 | **Per-project `CHANGELOG.md` convention** | 233 | 858 | **DEDUP** | arch.md → "`CHANGELOG.md` convention — terminal-close auto-append contract" |
| 15 | **`debug-*` skill category convention** | 234 | 835 | **DEDUP** | arch.md → "`debug-*` skill category — agent-pulled sidebars" |
| 16 | **Adding a new `debug-*` sibling skill — reusable template** | 235 | ~3000 | EXTERNALIZE | Phase 2 → `docs/lessons/debug-skill-template.md` (bundle with #17, #30) |
| 17 | **A new skill category needs three structurally-enforced discoverability surfaces** | 236 | ~740 | EXTERNALIZE | Phase 2 → bundles with #16 in `debug-skill-template.md` |
| 18 | **Test-harness primitives** → `docs/lessons/test-harness-primitives.md` | 237 | ~270 | KEEP | Already one-line pointer |
| 19 | **Scope-symmetry at mitigate time** → `docs/lessons/scope-symmetry.md` | 238 | ~190 | KEEP | Already one-line pointer |
| 20 | **`not_contains_strict: true`** → `docs/lessons/test-scenario-strict-mode.md` | 239 | ~280 | KEEP | Already one-line pointer |
| 21 | **`build_metrics` empty-window contract** (claude-time) | 240 | ~290 | KEEP | One-line; inline-comment pointer to source file |
| 22 | **Design-as-data byte-pin / v3 sub-payload routing (claude-time history)** → `tools/claude-time/docs/design-extract-history.md` | 241 | ~260 | KEEP | Already one-line pointer |
| 23 | **Calendar-anchored vs rolling-N-days defaults** | 242 | ~870 | KEEP (or thin candidate) | claude-time specific; real reusable rule; leave as-is unless we need more headroom |
| 24 | **Cross-layer contract migration** | 243 | ~1490 | EXTERNALIZE | Phase 2 → bundles with #25 in `docs/lessons/downstream-contract-impacts.md` |
| 25 | **Plan-time downstream-contract-impacts grep** | 244 | ~2900 | EXTERNALIZE | Phase 2 → `docs/lessons/downstream-contract-impacts.md` (main extract; biggest single bullet) |
| 26 | **v3 sub-payload routing pattern (HISTORICAL, retired 2026-06-03)** | 245 | 1656 | **DELETE** | Explicitly marked retired; ~1.6k chars of dead context |
| 27 | **Build-time selector-emission discipline** | 246 | ~1500 | EXTERNALIZE | Phase 2 → bundles into `downstream-contract-impacts.md` (same theme: plan-time declarations need build-time mechanical verification) |
| 28 | **Verify-codify full-group sweep discipline** | 247 | ~810 | EXTERNALIZE | Phase 2 → `docs/lessons/test-harness-sweep-discipline.md` (separate concern: test runner mechanics) |
| 29 | **Verify-self in-place fix shortcut** | 248 | 873 | **DEDUP** | arch.md → "Per-phase verify loop extended with `verify-self`" mentions the shortcut; SKILL.md §3 is authoritative; CLAUDE.md only needs a pointer |
| 30 | **Category-level conventions need the harness's own marker** | 249 | ~1230 | EXTERNALIZE | Phase 2 → bundles with #16, #17 in `debug-skill-template.md` (umbrella: category-level convention design) |
| 31 | **Bootstrap-skip is broader than registry** | 250 | ~1170 | EXTERNALIZE | Phase 2 → `docs/lessons/harness-bootstrap-skip.md` (load-bearing harness behavior; own concern) |
| 32 | **Verify-codify leaf substitution discipline** | 251 | ~1230 | EXTERNALIZE | Phase 2 → `docs/lessons/work-tree-leaf-substitution.md` (Work-Tree-format discipline) |

**Phase 1 char-count math (DEDUP + DELETE only):**
- DEDUP bullets (8): 1149 + 715 + 2143 + 1191 + 380 + 858 + 835 + 873 = **8,144 chars** removed
- DELETE bullet (1): 1,656 chars removed
- Total Phase 1 removal: **9,800 chars**
- Pointer additions (8 × ~150 chars): ~1,200 chars added back
- **Net Phase 1 reduction: ~8,600 chars** → projected `wc -c CLAUDE.md` after Phase 1: **~45,900 chars** (clears the ≤ 46,528 Phase 1 observable)

**Phase 2 char-count math (EXTERNALIZE — 11 bullets):**
- #12 (~1500) + #13 (~720) + #16 (~3000) + #17 (~740) + #24 (~1490) + #25 (~2900) + #27 (~1500) + #28 (~810) + #30 (~1230) + #31 (~1170) + #32 (~1230) = **~16,290 chars** removed
- Pointer additions (estimate 6 lessons × ~200 chars per pointer; some pointers bundle multiple bullets): ~1,200 chars added back
- **Net Phase 2 reduction: ~15,100 chars** → projected `wc -c CLAUDE.md` after Phase 2: **~30,800 chars** (clears the ≤ 35,000 target with comfortable margin)

## Discoveries

- [SURFACED-2026-06-13] feature-spec — `docs/product/arch.md` exceeds size guard (322 lines), truncated to first 100 + heading grep. Compaction work for arch.md is out of scope here, but the file is also under pressure; if Phase 3 dedup *adds* content to arch.md, we'll need to be deliberate about expanding within existing Revision subsections rather than appending new ones.
- [DELETED-2026-06-13] **v3 sub-payload routing pattern: useMemo with v2-alias fallback** — bullet was explicitly self-marked "HISTORICAL, retired 2026-06-03" in its own opening line; pattern was retired at WP9 Phase 2 of the v3 cycle. No remaining consumers; sub-tool-specific historical context lives in commits + `tools/claude-time/docs/design-extract-history.md`. 1,656 chars removed.
- [DEFERRED-2026-06-13] **8 DEDUP candidates parked** at user direction during P1.1 audit review — these would replace the leading-bold multi-paragraph bullets for Orchestrator pause policy, task-verify, feature-review-quality, Close-commit discipline, Test triage, CHANGELOG.md convention, debug-* skill category, Verify-self in-place fix shortcut with one-line pointers to their parallel arch.md Revision 2026-06-13 subsections. Recovery lever if EXTERNALIZE (Phase 2) doesn't clear the ≤ 40k target with adequate margin. Total recoverable: ~8,144 chars.
- [DISCARDED-2026-06-13] **Phase 3 structural pin (wc -c ≤ 40000 in tests/check-structure.sh)** — built, verified, then reverted at user direction during Phase 3 verify-human. Reasoning: the 40k threshold is in the Claude Code harness (Anthropic-controlled, may change), the harness already self-surfaces the warning on every session start (natural feedback loop), structural sweeps run less often than sessions start, and the pin would add friction for future legitimate convention additions.
- [DISCARDED-2026-06-13] **Phase 4 first attempt: prune-cadence prompt embedded in feature-finalize/SKILL.md** — built, verified through verify-self (5/5 PASS), reverted at user direction during verify-human. Reasoning: forces the cadence into every feature's close path even when CLAUDE.md isn't bloated. Replaced with a standalone `util-prune-claude-md` skill that the operator triggers manually when the 40k warning fires at session start (demand-driven, not feature-driven). The `util-*` category is being formalized in arch.md Revision 2026-06-13 as a third skill category (alongside workflow skills and debug-* sidebars).
- [SURFACED-2026-06-13] Phase 4 verify-auto — `tests/check-structure.sh` does NOT validate full YAML frontmatter parseability on SKILL.md files. The new `util-prune-claude-md/SKILL.md` had a structurally invalid `argument-hint:` value (unquoted string containing an inner colon — YAML interpreted it as a nested mapping key). The structural sweep PASSed 251/0 despite this; only an explicit `python3 yaml.safe_load` check caught it. Backlog candidate: add a YAML-parse pin to Phase 1 of check-structure.sh ("every SKILL.md frontmatter must safe_load without exception"). Fixed in-line during Phase 4 verify-auto (quoted the argument-hint value) — not back-looped because the fix was a single-character mechanical correction.

## Code-Quality Review — claude-md-compaction

### Strengths
- Honest, well-decided scope contraction. The WIP's `[DISCARDED-2026-06-13]` Phase 3 (structural-pin) and `[DISCARDED-2026-06-13]` Phase 4-first-attempt (feature-finalize embed) audit trails are the kind of negative-result documentation that prevents the next maintainer from re-litigating settled questions; both reversals have crisp reasoning attached.
- The `util-*` category is introduced with a clear delta against the existing two categories (workflow, `debug-*`). The arch.md `### util-* skill category` subsection (`docs/product/arch.md:224`) enumerates five distinguishing properties as concrete frontmatter/structure rules, which is exactly the right level of specificity for a category-level convention doc.
- Hard scope-guard on the new skill is well-placed and unambiguous: `skills/util-prune-claude-md/SKILL.md:27-31` ("This skill edits the project-root CLAUDE.md ONLY. It MUST NOT modify the global `~/.claude/CLAUDE.md`") plus the `git rev-parse --show-toplevel` confirmation step. The global-CLAUDE.md lifecycle is the kind of invariant that silently breaks if a future model reaches for the "obvious" file.
- The mode-menu mirrors workflow drive-modes (1–4) deliberately at `skills/util-prune-claude-md/SKILL.md:49-54`, giving operators a familiar aggression-spectrum cognitive shortcut without inventing new vocabulary.
- The extraction work is mechanically faithful — `wc -c` went 54,528 → 35,720 (35% reduction, clearing the 40k harness threshold by 4.3k chars) without losing semantic content; every externalized bullet has a one-line pointer (9 `docs/lessons` references in the post-shrink CLAUDE.md), so the audit trail from CLAUDE.md to the source-of-truth lesson doc remains intact.

### Issues

**CRITICAL**
- (none)

**MAJOR**
- (none)

**MINOR**
- [skills/util-prune-claude-md/SKILL.md:11] Section is named `## Category`, but the precedent `debug-*` skills (`skills/debug-bisect-known-good/SKILL.md:11`, `skills/debug-empirical-telemetry/SKILL.md:11`) use `## Category Context`. The new util-* subsection in `docs/product/arch.md:224` does not formally require either shape, but cross-category heading drift makes future grep-based audits (e.g., "show me every skill's category statement") miss this one. Either rename to `## Category Context` to match precedent, or document the intentional difference in arch.md's util-* subsection.
- [docs/lessons/debug-skill-template.md:5,25,32] The three new lesson files that depart from the established 3-lesson precedent shape (`## Practical application` + `## Instance`) use custom heading structures (`## Mechanical recipe`, `## Discipline 1 — …`, `## Discipline 2 — …` here; `## 1. / ## 2. / ## 3.` in `test-scenario-routing-forks.md`; `## Practical impact` + `## Discipline at plan time` in `harness-bootstrap-skip.md`). Content shape may justify the variance, but a future "what's the lesson-file schema?" reader has to derive it from N files rather than read it once. If the precedent is genuinely two-section (`## Practical application` / `## Instance`), conform; if it's "h1 title + topical sections, no YAML frontmatter, no strict schema", document that openly in a single line at the top of the lessons directory (a `docs/lessons/README.md` would be the canonical place).
- [docs/product/arch.md:6] Inline HTML comment `<!-- 2026-06-13 second edit (same day): added \`### util-* skill category\` subsection under Revision 2026-06-13. updated: unchanged (same calendar day). -->` is unusual for arch.md — adjacent subsections that ship same-day in other features have not adopted this convention. The audit-trail intent is fine, but a comment at file-top noting "second edit, same calendar day" is weak signal (any further same-day edit either has to nest or remove). The Revision-section discipline already provides a date-stamped narrative anchor; the inline comment is redundant.
- [workflow/backlog.md:9-17] New `SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN` correctly captures the YAML-defect near-miss caught at verify-auto. However the "Suggested action" suggests "Add a new Phase to `tests/check-structure.sh`", but a Phase N+1 addition would conflict with the close-commit discipline pin block which sits at the current tail (Phase 11). Worth noting in the SURFACE that the structural pin should land *between* existing phases (e.g., a Phase 3a addition to the existing frontmatter-validation pass) rather than as a tail phase, so the operator doesn't get blocked discovering this when they pull the SURFACE up to a task.

### Assessment
This is a well-disciplined docs-and-skill feature that achieves its primary mechanical objective (CLAUDE.md ≤ 40k chars with 4.3k headroom) cleanly. The execution is conservative: ~17k chars of EXTERNALIZE work was done while 8 DEDUP candidates (~8k more chars) were deliberately parked at user direction, leaving a recovery lever for future cycles. The introduction of the `util-*` category is the more architecturally interesting move — it correctly distinguishes itself from the `debug-*` precedent (no `RETURN-TO:`, not caller-pulled, not part of any state machine) and the arch.md subsection codifies the distinction at the right level of specificity. The new `util-prune-claude-md` skill is reflexively idempotent — re-running it on an already-pruned CLAUDE.md falls into KEEP by design — which is a thoughtful property for a maintenance utility. Three reservations keep this from being unqualified strong-build: (a) the `## Category` vs `## Category Context` heading drift, (b) the lesson-file schema is now ambiguous after 9 files with three different shapes, and (c) the YAML-frontmatter parse-pin gap surfaced by this feature is the kind of harness-contract surface that deserves a Phase-1 pin and should be one of the first things picked up from the backlog. Future readers will find the work clear — the WIP's audit-trail discipline is unusually high-quality for the breadth of in-flight reversals it captures.

### If you disagree
Operator: dismiss any finding by editing this section in the WIP file and marking the line `[DISMISSED]` before `feature-finalize` archives the WIP. The finding will be skipped by the orchestrator's severity-tier action matrix.

## Retrospect

- **What changed in our understanding:**
  - **The real warning is char-count, not line-count.** Initial research (web survey) framed the problem around Anthropic's 200-line guideline. The operator corrected mid-spec: the load-bearing signal is the harness's `54.1k chars > 40k` warning at session start. The framing shift simplified the acceptance criterion (`wc -c ≤ 40000`) and discarded ~half of the research's recommendations as irrelevant.
  - **`util-*` is a real third skill category, not just a name.** It started as a placement decision ("where does `prune-claude-md` belong?") but resolved into a category-level convention with concrete distinguishing properties from workflow skills and `debug-*` sidebars — codified in arch.md Revision 2026-06-13.
  - **Live-validation of skill edits is not possible mid-session.** The bootstrap-skip lesson (extracted in Phase 2) had immediate operational consequence — Phase 4's verify-self couldn't behaviorally test the new skill; we relied on static-source verification + a deferred next-session check. This is a structural property of the Claude Code harness, not a defect.
  - **Two phases were attempted-then-reverted mid-cycle.** Phase 3 (structural pin) and Phase 4-first-attempt (embed cadence in `feature-finalize`) both shipped through verify-self successfully before being reverted at verify-human. The reversals were the right call in both cases — but the time spent building them was real.

- **Assumptions that held:**
  - The externalize pattern (`docs/lessons/<topic>.md` + one-line pointer) was a known-good precedent (3 existing files) and applied cleanly to 6 new lessons. The math worked: ~17k chars removed, no semantic loss, audit trail intact.
  - The `Edit` tool's `old_string` discipline preserved git blame and avoided whitespace drift on unrelated CLAUDE.md sections, exactly as the plan anticipated.
  - The orchestrator's drive-mode mechanism worked correctly across the mid-feature mode switch (step-by-step → orchestrated → autopilot at three different points in the cycle). The frontmatter `drive_mode:` field is the right persistence surface.

- **Assumptions that were wrong:**
  - **`tests/check-structure.sh` validates SKILL.md frontmatter parseability.** It does not — caught only because verify-auto ran an explicit `python3 yaml.safe_load`. The new skill's invalid `argument-hint:` would have silently broken the harness's registry at next session start. Surfaced as P1 backlog item.
  - **DEDUP was needed to clear the 40k threshold.** It wasn't — EXTERNALIZE alone got us to 35,720, with ~4.3k chars of headroom. The 8 DEDUP candidates parked at P1.1 audit time turned out to be unnecessary recovery lever (which is the correct outcome for a recovery lever — held in reserve, not used).
  - **The cadence-prompt belonged in `feature-finalize`.** Phase 4-first-attempt shipped through verify-self before the operator (correctly) reframed it: a workflow-embedded cadence prompt fires on every feature close, but CLAUDE.md only bloats occasionally — demand-driven user-triggered skill (the harness warning IS the trigger) is the right mechanism.

- **Approach delta:**
  - **Phase 3 was built then SKIPPED.** Originally proposed as a `wc -c ≤ 40000` pin in `tests/check-structure.sh`; reverted at operator direction during verify-human. Full audit trail preserved in WIP Phase 3 block + `[DISCARDED-2026-06-13]` Discovery entry.
  - **Phase 4 restructured mid-cycle.** Original scope was a SKILL.md edit; final scope is a new file-based standalone skill + a new arch.md category subsection. Both attempts preserved in audit trail.
  - **Mode switched three times mid-feature.** step-by-step (spec/plan) → orchestrated (build/verify across Phases 1–3) → autopilot (ship onward). Each switch was operator-initiated and tracked in WIP frontmatter.
  - **Verify-codify wrote zero new tests.** Across all 4 phases. Rationale: content-relocation phases don't have stable behavioral contracts to pin; the one durable contract (YAML frontmatter parseability) is filed as a structural-sweep gap, not a feature-specific test.
