# Feature: Deterministic artifact tracking policy

**Workflow:** feature
**State:** finalize (complete) — COMPLETED 2026-06-25
**Created:** 2026-06-25
**Entry:** spec (complex feature)
**drive_mode:** autopilot

## Problem Statement

The workflow system has no authoritative answer to *"which artifacts get git-tracked vs. ignored, and where do they get written?"* — so skills decide at runtime, inconsistently, and the same artifact is staged-and-committed in one project but ignored in another. Three confirmed symptoms:

1. **`session-store-learning` guesses the destination.** A global-scope learning lands sometimes in `~/.claude/learnings/`, sometimes `<proj-dir>/docs/learnings/`, sometimes `<proj-dir>/.claude/learnings/`. Root cause includes pervasive **unqualified `.claude/` path references** in the prompts (24 bare mentions across skills/agents/snippet; 19 in `session-store-learning` alone) — the agent must infer home-vs-project each time, and infers differently across sessions.
2. **Track-vs-ignore is random across projects.** The only enforcement today is `session-store-learning` lazily editing `.gitignore` and asking each time (`SKILL.md:119`), plus git behavior keyed on the now-false proxy *"is `.claude/learnings/` gitignored?"*.
3. **`.session.md` handling is unspecified**, and this repo carries **live contradictions**: `CLAUDE.md:222` calls `.claude/learnings/` "gitignored" but it is tracked (17 files); `.claude/memory/` has an orphaned "should ignore" comment in `.gitignore` but is actually tracked (2 files).

Root cause: the tracking convention is implicit, the path references are ambiguous, and skills *infer* the policy instead of *following* it.

## User Stories

- As the operator, I want a single authoritative policy for which artifacts are tracked vs. ignored, so the workflow system stops making inconsistent per-session decisions.
- As the operator, I want every `.claude/` path in a prompt explicitly qualified (`~/.claude/` vs `<proj-dir>/.claude/`), so global-scope learnings always land in one canonical place.
- As the operator, I want a per-project override mechanism so THIS repo (the global learning-assets repo) tracks `<proj-dir>/.claude/learnings/` + `<proj-dir>/.claude/memory/` while other projects ignore them by default.
- As the operator, I want memories tracked by default but audited for PII at write time, so I get version history without leaking personal info.
- As the operator, I want `session-reflect` to label each learning's scope (`[GLOBAL]`/`[PROJECT]`) as a **leading** label, so scope is visible at a glance rather than buried in a paragraph.

## Acceptance Criteria

The feature is done when:

1. **Authoritative policy exists (GLOBAL).** `CLAUDE.snippet.md` has a new `## Artifact tracking policy (GLOBAL)` section (injected to `~/.claude/CLAUDE.md` via the existing install.sh marker mechanism — no install.sh code change) containing: (a) the **track-by-default rule** (*ignore a path only if it contains secrets/PII, or is machine-local/trivially regenerable*); (b) the **canonical track/ignore MAP**, fully path-qualified; (c) the **override mechanism** spec; (d) a copy-pasteable canonical `.gitignore` reference block.
2. **Per-project override mechanism.** A project's root `CLAUDE.md` may declare a `## Artifact tracking overrides` block naming exceptions; `product-context` and the artifact-writer skills read it. This repo's `CLAUDE.md` declares the override (track `<proj-dir>/.claude/learnings/` + `<proj-dir>/.claude/memory/`).
3. **Path-qualification rule enforced.** All 24 bare `.claude/` mentions in `skills/*/SKILL.md` + `agents/*/AGENTS.md` + `CLAUDE.snippet.md` are qualified as `~/.claude/` or `<proj-dir>/.claude/`. A `check-structure.sh` pin rejects new bare `.claude/` (allowing the two qualified forms + code-fenced examples).
4. **Memory policy: track-by-default + write-time PII audit.** Any skill writing a memory audits the file for PII after writing; redacts in place if it preserves usefulness, else adds that specific file to `.gitignore` (expected rare). `<proj-dir>/.claude/memory/` + `MEMORY.md` track by default.
5. **`session-store-learning` is a policy-follower.** One canonical global-draft destination `<proj-dir>/.claude/learnings/<YYYY-MM-DD>-<slug>.md` (never `~/.claude/`, never `docs/learnings/`); git behavior keyed on the policy + project override (commit/amend iff the path is tracked-by-policy; leave uncommitted where ignored); the "ensure-in-`.gitignore`/force-add" guessing logic (lines 84, 119) is removed; `description:` frontmatter + the CLAUDE.md:222 false "gitignored" claim reconciled.
6. **`product-context` owns `.gitignore` reconciliation.** After writing root `CLAUDE.md`, it syncs the project's `.gitignore` to `[canonical map] minus [CLAUDE.md overrides]`. `install.sh` is NOT modified to touch `.gitignore`. Skip-projects (this repo) are unaffected unless the operator invokes `product-context` manually.
7. **Other artifact-writers audited.** `session-pause`/`session-resume` (`.session.md`), the 4 close skills (`feature-finalize`, `task-close`, `incident-resolve`, `product-finalize`), and the `debug-*` backlog writers are verified to follow the map; only wording fixes expected (inventory shows their git behavior is already deterministic).
8. **`session-reflect` leading scope label.** Key Learnings format changes from trailing `— Scope: global | project` to a leading `[GLOBAL]` / `[PROJECT]` bracketed label (consistent with existing `[SHORTCUT-...]`/`[SURFACED-...]` marker style). `session-store-learning` consumes the same scope vocabulary.
9. **This repo's contradictions fixed.** `CLAUDE.md:222` corrected; orphaned `.gitignore` comment repaired/removed; both reconciled with the new override declaration.
10. **Verification.** `./tests/check-structure.sh` PASSes with new pins (snippet-section-exists, no-bare-`.claude/`, no-gitignore-inspection-for-git-behavior, single-canonical-learnings-path). `./tests/run-tests.sh --group session` PASSes a new behavioral scenario asserting `session-store-learning` deterministic routing.

## Out of Scope

- **`install.sh` will NOT touch project `.gitignore`** — it is machine-setup (run once per machine, no notion of "current project"); making it reach into arbitrary project trees is a category error.
- **No standalone reconcile skill for skip-projects** — the operator manually invokes `product-context` if a skip-project ever needs reconciliation.
- **No relocation/renaming of existing artifacts** beyond fixing the two contradictions in this repo.
- Not changing the feature Work Tree "Phase" schema or any unrelated convention.

## Technical Constraints

- **Architecture domain match:** per `docs/product/arch.md` ("the architecture is entirely file schemas that skills read/write, and skill prompt contracts that enforce behavior"), this feature is a format-decision + skill-contract change — no runtime, no services.
- **Tripartite-sync discipline:** if any transition is touched, keep `transitions.md` / per-skill SKILL.md / scenario YAML in sync. (Expected: NO new transition IDs — these are prose + structural-pin changes, like the `debug-*` and close-commit conventions before them.)
- **Snippet → global injection:** `CLAUDE.snippet.md` is injected into `~/.claude/CLAUDE.md` by `install.sh` between `<!-- BEGIN claude-workflow-system -->` / `<!-- END ... -->` markers — adding a section propagates to all projects on next `./install.sh` run; no install.sh logic change needed.
- **No 3rd-party dependency** — 3rd-party probe check N/A.
- **Path notation locked:** `<proj-dir>/.claude/` (project-local) and `~/.claude/` (home/global) are the two canonical forms; bare `.claude/` forbidden in prompt prose.

## Open Questions

- [x] None — all design forks resolved in the pre-spec discussion (source-of-truth location, override mechanism, `.gitignore` automation owner, memory default + PII audit, draft-commit behavior, path notation, `session-reflect` label format).

## Work Tree

- [x] Phase 1: Path-qualification sweep + structural pin  <!-- status: complete -->
  **Rationale:** Mechanical, independently verifiable, and unblocks everything downstream — once every `.claude/` reference is unambiguous, the policy work can name exact paths. Goes first per the dependency order locked in pre-spec discussion.
  **Observable outcomes:**
  - CLI: `grep -rnoE "[^/~.a-zA-Z_-]\.claude/" skills/ agents/ CLAUDE.snippet.md` (excluding code-fenced examples) returns ZERO bare `.claude/` mentions in prose — every reference is `~/.claude/` or `<proj-dir>/.claude/`.
  - CLI: `./tests/check-structure.sh` runs and the NEW "no bare `.claude/` in prompts" pin PASSes (and would FAIL if a bare mention is reintroduced — verified by a scratch negative test).
  - CLI: `./tests/check-structure.sh` overall still exits 0 (no regression in existing pins).
  - [x] P1.1 Sweep all 24 bare `.claude/` mentions → qualify as `~/.claude/` or `<proj-dir>/.claude/` across skills/*/SKILL.md, agents/*/AGENTS.md, CLAUDE.snippet.md (19 are in session-store-learning)  <!-- status: complete -->
  - [x] P1.2 Add a `check-structure.sh` pin (Phase 12) rejecting new bare `.claude/` in prompt prose; verified positive + negative  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; check-structure 291/0 PASS, bash -n OK, qualification grep 0 -->
  - [x] verify-self  <!-- status: complete; subagent confirmed all 3 CLI outcomes PASS (incl. negative test). No integration boundary — isolated new pin + prose edits. -->
  - [x] verify-human  <!-- status: complete; AUTO-SKIP per drive_mode=autopilot, no integration boundary, verify-self all-PASS (F11) -->
  - [x] verify-codify  <!-- status: complete; Phase 12 pin IS the regression test (verified +/- in verify-self); check-structure 291/0. No integration boundary. -->

- [x] Phase 2: Authoritative policy + canonical MAP in CLAUDE.snippet.md  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -c '## Artifact tracking policy (GLOBAL)' CLAUDE.snippet.md` → 1.
  - CLI: the new section contains the track-by-default rule, the canonical MAP (every artifact row path-qualified — `<proj-dir>/.claude/...` / `~/.claude/...`), the override-mechanism spec, and a copy-pasteable `.gitignore` reference block — verified by `grep` for each anchor heading/phrase.
  - CLI: `grep -i 'gitignore' CLAUDE.snippet.md` shows policy/reference prose only — no per-skill decision logic.
  - CLI: new `check-structure.sh` pin "Artifact tracking policy section exists" PASSes; overall exits 0.
  - [x] P2.1 Write `## Artifact tracking policy (GLOBAL)` section: track-by-default rule + canonical MAP (fully path-qualified) + override mechanism + copy-pasteable `.gitignore` block  <!-- status: complete -->
  - [x] P2.2 Memory row in MAP = track-by-default + write-time PII-audit clause (redact-in-place else per-file ignore); learnings row = track via override, else ignore-and-leave-uncommitted; `.session.md`/settings.local.json = ignore  <!-- status: complete -->
  - [x] P2.3 Add `check-structure.sh` pin (Phase 12) asserting the GLOBAL section + track-by-default rule + override mechanism  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; refined Phase 1 path-qualification pin to strip ``` fences + allow the `.claude/` notation token (the new policy section + .gitignore block legitimately contain those); check-structure 294/0 -->
  - [x] verify-self  <!-- status: complete; subagent confirmed all 4 CLI outcomes PASS (section, anchors, gitignore-prose-only, 294/0). No integration boundary — isolated new doc section + pins. -->
  - [x] verify-human  <!-- status: complete; AUTO-SKIP per drive_mode=autopilot, no integration boundary, verify-self all-PASS (F11) -->
  - [x] verify-codify  <!-- status: complete; 3 Phase 12 artifact-tracking pins ARE the regression tests; check-structure 294/0. No integration boundary. -->

- [x] Phase 3: Skill reconciliation — make artifact-writers policy-followers  <!-- status: complete -->
  **Integration-boundary note:** This phase modifies existing skill prompts (`session-store-learning`) and the per-project override is read by `product-context` — both are consuming surfaces. verify-self/human/codify must cite them.
  **Observable outcomes:**
  - CLI: `session-store-learning/SKILL.md` names exactly ONE global-draft destination (`<proj-dir>/.claude/learnings/<YYYY-MM-DD>-<slug>.md`); `grep -c` for alternate dirs (`~/.claude/learnings`, `docs/learnings`) → 0.
  - CLI: `grep -i 'gitignore' skills/session-store-learning/SKILL.md` returns NO decision logic (the "ensure-in-.gitignore / force-add" lines 84+119 are gone); git behavior references the policy/override, not live gitignore inspection.
  - CLI: `product-context/SKILL.md` contains a `.gitignore` reconciliation step keyed on `[canonical map] minus [CLAUDE.md overrides]`; `install.sh` is unchanged (`git diff --stat install.sh` empty).
  - CLI: new `check-structure.sh` pins PASS — "single canonical learnings path in session-store-learning" + "no skill keys git behavior on gitignore inspection"; overall exits 0.
  - Behavioral: `./tests/run-tests.sh --group session` PASSes a new scenario asserting `session-store-learning` deterministic routing.
  - [x] P3.1 Rewrite `session-store-learning`: one canonical global-draft path; git behavior keyed on policy+override (commit/amend iff tracked, else leave uncommitted); removed ensure-in-.gitignore/force-add logic; reconciled `description:` frontmatter; added memory PII-audit clause  <!-- status: complete -->
  - [x] P3.2 Added `.gitignore` reconciliation step (§2b) to `product-context/SKILL.md` + optional `## Artifact tracking overrides` in generated CLAUDE.md template; `install.sh` confirmed untouched (git diff --stat empty)  <!-- status: complete -->
  - [x] P3.3 Audited `session-pause`/`session-resume` (.session.md fixed-path, deleted on resume — no git decision), 4 close skills (no gitignore-inspection — already deterministic), debug-* (write to tracked backlog.md). Only session-store-learning was guessing; no other changes needed.  <!-- status: complete -->
  - [x] P3.4 Added behavioral scenario S20-global-canonical-path (tests/scenarios/session.yaml) — contains_required `.claude/learnings/`, not_contains `~/.claude/learnings`+`docs/learnings`  <!-- status: complete -->
  - [x] P3.5 Added 4 check-structure pins (Phase 12): canonical-path, policy-keyed git behavior, forbids-gitignore-inspection, product-context-reconcile-owner  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; bash -n OK, session.yaml + both edited SKILL frontmatters valid YAML, check-structure 298/0 (8 Phase 12 pins green) -->
  - [x] verify-self  <!-- status: complete; subagent confirmed all 4 CLI outcomes PASS (canonical path, policy-keyed git, install.sh untouched, 298/0). 5th outcome (behavioral) S20-global-canonical-path ran via run-tests.sh --id → PASS (haiku, 11s). Integration boundary cited: session-store-learning exercised end-to-end by the scenario. -->
  - [x] verify-human  <!-- status: complete; operator APPROVED (F13) after reviewing rewritten prose + directing the snippet→CLAUDE.md/product-context relocation of 3 implementation subsections. Integration boundary present (skill prompts) so no auto-skip. -->
  - [x] verify-codify  <!-- status: complete; coverage = 4 Phase 12 structural pins (P3.5) + S20-global-canonical-path behavioral scenario (P3.4, PASS). Integration boundary satisfied by the end-to-end scenario. check-structure 298/0. -->

- [x] Phase 4: session-reflect leading scope label + reconcile THIS repo's contradictions  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `session-reflect/SKILL.md` Key Learnings template uses leading `[GLOBAL]`/`[PROJECT]` labels; `grep '— Scope: global | project' skills/session-reflect/SKILL.md` → 0 (trailing form gone).
  - CLI: `grep -n 'gitignored.*learnings' CLAUDE.md` → 0 (false claim at line 222 corrected); project `CLAUDE.md` contains a `## Artifact tracking overrides` block declaring `<proj-dir>/.claude/learnings/` + `<proj-dir>/.claude/memory/` tracked.
  - CLI: `.gitignore` orphaned comment (memory/ + settings.local.json describing absent patterns) is repaired/removed and consistent with the override declaration; `git check-ignore -v .claude/learnings/` → not ignored (tracked here).
  - CLI: `./tests/check-structure.sh` exits 0 with all new pins; full structural sweep green.
  - [x] P4.1 Changed `session-reflect/SKILL.md` Key Learnings to leading `[GLOBAL]`/`[PROJECT]` label + added the "scope label leads, by design" note  <!-- status: complete -->
  - [x] P4.2 Fixed project `CLAUDE.md`: corrected the false "gitignored .claude/learnings opt out of amend" claim (now policy/override-keyed); added `## Artifact tracking overrides` declaring learnings + memory tracked. (Path-qualification mandate also landed here during Phase 3 relocation.)  <!-- status: complete -->
  - [x] P4.3 Repaired orphaned `.gitignore` comment → real patterns: settings.local.json + workflow/.session.md ignored; explicit NOTE that learnings + memory are tracked (override). Verified git check-ignore.  <!-- status: complete -->
  - [x] P4.4 Added 4 check-structure pins (Phase 12): reflect leading-label + no-trailing-form + CLAUDE.md override section + no-stale-gitignored-claim  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; bash -n OK, check-structure 302/0 (12 Phase 12 pins green), git check-ignore confirmed learnings+memory tracked / settings.local.json ignored -->
  - [x] verify-self  <!-- status: complete; subagent confirmed all 4 CLI outcomes PASS (reflect leading label + no trailing form, CLAUDE.md override + no stale claim, .gitignore git check-ignore correct, 302/0). No runtime integration boundary — prompt-template + docs + .gitignore edits. -->
  - [x] verify-human  <!-- status: complete; AUTO-SKIP per drive_mode=autopilot, no integration boundary (prompt-template + docs + config), verify-self all-PASS (F11) -->
  - [x] verify-codify  <!-- status: complete; coverage = 4 Phase 12 pins (P4.4); check-structure 302/0. No integration boundary. ALL 4 PHASES COMPLETE. -->

## Current Node
- **Path:** Feature > refactor (complete) > finalize
- **Active scope:** F40 CRITICAL fixed + re-verified (303/0, transitions.md sync pin green). MAJOR/MINOR dispositioned (see Refactor disposition). Ready for finalize.
- **Blocked:** none
- **Unvisited:** finalize (terminal close)
- **Open discoveries:** arch.md size-guard (informational, no action)

## Code-Quality Review — artifact-tracking-policy

### Strengths
- Policy/implementation split sourced correctly: rule+MAP+override in CLAUDE.snippet.md (cross-project), path-qualification authoring rule + .gitignore reconciliation in CLAUDE.md/product-context (implementation).
- Git-behavior discriminator re-keyed from fragile "is it gitignored?" proxy to authoritative policy+override — fixes the root cause, not a symptom.
- Path-qualification pin carefully scoped: strips ``` fences, exempts the backtick notation token (correct exclusion set).
- Regression-guard discipline: two "stale form must not return" pins (trailing `— Scope:`, `gitignored .claude/learnings` claim).
- Leading `[GLOBAL]`/`[PROJECT]` label reuses the existing `[SHORTCUT-...]`/`[SURFACED-...]` marker idiom.

### Issues
**CRITICAL**
- [docs/product/transitions.md:425,451] The authoritative state-machine surface was NOT updated. The `store-learning` row (425) and S20 row (451) still describe global-scope as "drafted to `.claude/learnings/...` (project-local, gitignored) ... never writes to `~/.claude/`" — the exact "gitignored" framing this feature retired (AC#5/#9), with bare `.claude/` paths the path-qualification mandate now forbids. Violates the repo's tripartite-sync convention (transitions.md ⇄ SKILL.md ⇄ scenario YAML); the Phase-12 pin excludes transitions.md from scan scope so nothing catches it. (Line 563 is a dated historical changelog entry — leave as-was.)

**MAJOR**
- [tests/check-structure.sh Phase 12] The path-qualification pin scans CLAUDE.snippet.md + skills/ + agents/ but not docs/product/transitions.md — exactly where the stale references survived. Extend the scan (or add a no-stale-gitignored-claim pin on transitions.md mirroring the CLAUDE.md pin).
- [tests/scenarios/session.yaml S20-global-canonical-path] Only exercises the default (no-override → leave-uncommitted) branch; the override→track→amend branch (which governs THIS repo) has zero behavioral coverage. Per routing-fork convention, add a second scenario with an override-declaring fixture.

**MINOR**
- [tests/scenarios/session.yaml:790-794] `contains_required: [".claude/learnings/"]` would pass on `~/.claude/learnings/` (superset match) and the not_contains guard is lenient. Assert `<proj-dir>/.claude/learnings/` to tighten.
- [.gitignore NOTE comment] Restates override rationale already in CLAUDE.md + snippet (3 copies). A one-line pointer would suffice. Cosmetic.

### Assessment
Well-architected prose-contract feature fixing a real non-determinism root cause cleanly. One material defect: a tripartite-sync miss — transitions.md still carries the superseded "gitignored" framing + bare `.claude/` paths this feature aimed to eliminate, and the enforcing pin's scope excludes that file. Combined with the override-branch coverage gap, the feature leaves a small well-defined debt at its riskiest seam (the canonical state-machine surface). Net: solid build, one CRITICAL sync correction warranted before the debt calcifies.

### If you disagree
Operator: dismiss any finding by editing this section in the WIP and marking the line `[DISMISSED]` before finalize archives the WIP.

### Refactor disposition (F40, 2026-06-25)
- **CRITICAL (transitions.md:425,451)** — [FIXED] Both live transition rows (`store-learning`, S20) updated to qualified `<proj-dir>/.claude/...` paths + policy/override-keyed git behavior wording; dropped the "(project-local, gitignored)" framing. Line 563 left as-is (dated historical changelog entry).
- **MAJOR #1 (pin scope gap on transitions.md)** — [FIXED] Added a targeted Phase-12 pin asserting the `store-learning`/S20 transition ROWS carry no superseded "gitignored learnings" framing (scoped to live rows, not the dated changelog history which legitimately keeps as-of wording).
- **MAJOR #2 (override-branch scenario coverage gap)** — [BACKLOGGED] Requires test-runner support for a per-scenario `claude_md:` fixture (run-tests.sh hard-copies the fixed fixture today). That's new harness functionality, out of refactor scope. Logged as SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE (medium).
- **MINOR #1 (tighten contains_required to `<proj-dir>/.claude/learnings/`)** — [DISMISSED] The model proposes the path in prose to the user and may legitimately phrase it bare; requiring the `<proj-dir>/` prefix risks a false FAIL on benign phrasing (the very test-fragility the strict-mode lesson warns against). The existing `not_contains: [~/.claude/learnings, docs/learnings]` already guards the real wrong-destination failure modes. Keeping the assertion as-is is the more robust choice.
- **MINOR #2 (.gitignore comment dedup)** — [FIXED] Trimmed the 5-line NOTE to a 2-line pointer to CLAUDE.md.

## Retrospect
- **What changed in our understanding:** The non-determinism wasn't only a broken scope-discriminator — a large contributor was **pervasive unqualified `.claude/` path references** (24 of them, 19 in session-store-learning) forcing the agent to infer home-vs-project at read time. Naming that as a first-class principle (path-qualification) was the operator's insight during clarification, and it reframed the whole feature from "fix the discriminator" to "make track-vs-ignore + destinations deterministic system-wide."
- **Assumptions that held:** The policy/implementation split (snippet = cross-project policy; CLAUDE.md/skills = implementation) was the right organizing principle — confirmed by the operator's Phase-3 pushback that relocated 3 subsections out of the snippet. The audit prediction held: only session-store-learning was actually guessing; the close skills + session-pause were already deterministic.
- **Assumptions that were wrong:** (1) I initially put path-qualification + reconciliation-owner + the .gitignore block in the GLOBAL snippet; the operator correctly identified these as implementation/authoring concerns that don't belong in every project's ~/.claude/CLAUDE.md. (2) I missed the tripartite-sync obligation — transitions.md still carried the stale "gitignored" framing; the code-quality reviewer caught it as a CRITICAL. Lesson: when editing a SKILL.md that has a transition, transitions.md is the third leg that must move with it.
- **Approach delta:** Plan was 4 phases (qualify → policy → skills → reflect+reconcile); executed as planned, plus an unplanned F40 refactor cycle to fix the transitions.md sync miss the reviewer surfaced. Two structural pins needed mid-flight refinement (the path-qualification pin over-matched its own meta-references; the transitions.md sync pin over-matched a dated changelog bullet) — both caught and fixed within their verify steps, a sign the pins are exercising real edge cases.

## Code-Quality Review

(See `## Code-Quality Review — artifact-tracking-policy` section above, with the F40 Refactor disposition.)

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
[SURFACED-2026-06-25] feature-spec — arch.md exceeds size guard (337 lines), read first 100 + headings only. Consider summarizing.
[SURFACED-2026-06-25] Phase 2 verify-auto — the Phase 1 path-qualification pin over-matched: it flagged the new policy section's own meta-references (`.claude/` notation token) and the `.gitignore` code-fence patterns. Refined the pin to strip ``` fences and allow the exact backtick `.claude/` token before this phase's section landed. Caught + fixed in verify-auto (294/0). Informational — no separate backlog item needed.
[SURFACED-2026-06-25] Phase 3 verify-human — operator review reallocated 3 subsections out of the CLAUDE.snippet.md policy section (they were workflow-implementation, not cross-project policy): (1) path-qualification mandate → this repo's CLAUDE.md Conventions; (2) reconciliation-owner → collapsed to a one-line pointer; (3) canonical .gitignore block → product-context §2b (where it's consumed). Snippet now holds only rule+MAP+override (the universal policy). Re-verified: check-structure 298/0, all 8 Phase 12 pins green. Principle: snippet = cross-project policy (the what); skill/CLAUDE.md = implementation + enforcement (the how).
