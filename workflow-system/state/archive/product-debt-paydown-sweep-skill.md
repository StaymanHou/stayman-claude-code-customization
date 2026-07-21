# Feature: Codify the between-milestone backlog-sweep as a product workflow skill

**Workflow:** feature
**State:** finalize (complete) — archived
**Ship commit:** aa5c831 (committed to main, NOT pushed — operator's call per close-commit discipline)
**Created:** 2026-06-30
**Completed:** 2026-06-30
**drive_mode:** autopilot
**Plan approved:** 2026-06-30 (operator: proceed in autopilot; test scenarios MUST derive from the actual session logs — replicator + Claudesk real backlog items — REDACTED/generalized to strip sensitive/project-specific detail)
**Entry:** spec (complex feature — new skill + state surface + cross-cutting structural pins)
**Spec approved:** 2026-06-30 (operator chose F3 → research to settle the category/transition-surface unknown)
**Research approved:** 2026-06-30 (operator decisions: category = util-* standalone option B; check-structure = B1 no-new-pin; name = `util-backlog-paydown`; ADD an advisory one-line pointer from `product-finalize` → this skill)

## Problem Statement

The operator repeatedly runs a recurring, currently-uncodified process: a **between-milestone backlog
sweep** — a hand-authored *temporary WBS* (a `shape: temporary-wbs` work breakdown that is NOT a roadmap
milestone and is **deleted on completion**) created to clear an accumulated backlog of code-quality
findings + small hygiene/decision items at a clean cycle boundary. It has now been run with an explicit
rule set in at least two projects (Claudesk 2026-06-30; replicator-1-0 ran a whole *family* of five such
sweeps on 2026-06-20). The process has a stable, transferable core — a **3-axis disposition model**
(Impact / Effort / Risk), a **5-action vocabulary** (Sweep / Discuss / Defer / Bury / Delete), a set of
ordering rules, and a fold-back-and-delete lifecycle — but it is re-improvised each time from the operator's
memory and a hand-off learning doc, not driven by a skill.

This feature **codifies that process as a workflow-system skill** so future sweeps are driven consistently
and the disposition model is applied the same way every time, instead of re-derived per session.

The canonical input is `docs/lessons/between-milestone-debt-paydown-sweep.md` (the hand-off artifact,
already moved into this repo). The two prior sessions are the **regression suite** for the codified skill —
the model must *predict* the dispositions those sessions actually made.

## Cross-validation result (done at spec time — grounds the open-question resolutions below)

Both regression sessions were located and their dispositions extracted:

- **Session 1 — Claudesk 2026-06-30** (`docs/product/debt-paydown-wbs.md`): a code-quality / debt-paydown
  sweep clearing the M1–M8 deferred-`/feature-refactor` batch + hygiene SURFACEs before M9. Tabulated the
  full 3-axis matrix explicitly.
- **Session 2 — replicator-1-0 2026-06-20**: a *family of five* temporary-WBS sweeps from one grooming
  sitting — `wave-1-easy-wins`, `wave-2-roi-trio`, `wave-3-easy-wins` (all code-quality/debt), plus
  `keepers` (feature-collection) and the deferred canva item. ~16 items disposed across the family.

**The disposition model predicted ~100% of replicator's real includes/excludes.** Findings that directly
resolve the doc's three open questions:

1. **One skill or two (debt vs feature-collection)?** → **ONE skill.** Replicator ran *both* kinds as
   sibling buckets in the same grooming sitting using the same vehicle. The disposition model itself routes
   feature-collection items correctly (net-new features → Defer/Discuss/milestone) without a separate skill.
   The *vehicle* (temporary-WBS + 3-axis model + fold-back-delete) is shared; "debt sweep vs feature sweep"
   is an emergent property of how items score, not a mode toggle. The skill does NOT need two modes.
2. **Operator veto as a first-class trigger?** → **YES, make it first-class.** Veto fired twice in
   replicator (W6 "just delete — out of scope by design"; canva-deprecation "defer — gated precondition"),
   both *bypassing* axis-scoring but landing as Delete/Defer. The model "captured" them only because the
   operator narrated a reason; the skill should name operator-veto as an explicit pre-scoring disposition.
3. **Effort-benchmark portability?** → **Benchmark against the CONSUMING project's archived units**, not a
   fixed scale. Replicator's "XS/S" calibrated against its own WBS granularity; Claudesk against its own.
   The skill must instruct: read *this* project's recently-archived WBS WPs + WIP to set the Large/Medium/
   Small anchors before scoring.

A fourth finding (not in the doc's open list but spec-relevant):

4. **Scoring fidelity is variable.** Claudesk tabulated the full (item, impact, effort, risk, action)
   matrix; replicator used prose rationale + size estimate on *pre-groomed* buckets (items arrived already
   confirmed cheap+safe). The skill must support **both**: full tabulation for a raw/messy backlog, and a
   light-touch prose path when the operator has pre-groomed items into a bucket.

## User Stories

- As the operator, at a clean milestone boundary, I want to invoke one skill that inventories the standing
  backlog + code-quality findings, applies the disposition model, surfaces the Discuss items to me, and
  emits a priority/risk-ordered temporary-WBS — so I don't re-derive the rules each time.
- As the operator, I want to **veto** an item outright ("not wanted" / "out of scope" / "gated") and have
  that recorded as a first-class Delete/Defer disposition, not forced through axis-scoring.
- As the operator on a *pre-groomed* bucket, I want a light-touch path (prose + size) without being forced
  to tabulate a full 3-axis matrix for items I've already confirmed cheap+safe.
- As a future maintainer, I want the codified disposition model to still predict the two regression
  sessions' real dispositions, so I know a later edit didn't break the model.

## Acceptance Criteria

The feature is done when:

1. A new skill **`util-backlog-paydown`** exists under `skills/util-backlog-paydown/SKILL.md`, symlinked by
   `install.sh`, with frontmatter (`name`, `description`, `argument-hint`) matching repo conventions.

   <!-- ACs #4/#5/#6 NARROWED by research (option B = util-* standalone). Original spec-time wording assumed
        the category was unsettled; it is now superseded by the option-B consequences below. -->
2. The skill's SKILL.md encodes: the 3-axis disposition model, the 5-action vocabulary, the ordering rules,
   the operator-veto first-class trigger, the dual scoring-fidelity paths, the effort-benchmark-against-this-
   project instruction, the "theme over instance for MINOR batches" inventory step, the "read real code
   before deciding a Discuss item" rule, and the temporary-WBS + fold-back-and-delete lifecycle.
3. The skill emits a `shape: temporary-wbs` WBS file consistent with the two precedent artifacts'
   frontmatter shape, with an explicit "what's NOT swept — anchors intact" scope section and a
   fold-back-and-delete completion section.
4. **(NARROWED by research — option B.)** As a `util-*` standalone skill the new skill emits **no workflow
   transition** and is **not** a state in the three-place state-machine sync. The discoverability surfaces
   instead are: the SKILL.md itself, the `arch.md` "Current util-* skills:" listing, the project-root
   CLAUDE.md convention bullet, and the advisory `product-finalize` pointer. No `transitions.md` state-machine
   edit. Behavioral coverage lives in a new `tests/scenarios/util.yaml`.
5. **(NARROWED by research — option B.)** `agents/product-workflow/AGENTS.md` is **NOT** modified — a util-*
   skill is not a product-workflow state and is not added to any orchestrator's `skills:` list. (This is the
   load-bearing difference from a product-workflow state.)
6. **(NARROWED by research — option B = B1.)** `tests/check-structure.sh` gains **no new structural pin** —
   matching the documented util-* status quo (`arch.md` line ~281: util-* pins deferred until load-bearing;
   `util-prune-claude-md` ships with none). The new skill is discoverable via the `util-` prefix + arch.md
   listing. The full structural sweep (`./tests/check-structure.sh`) must still pass with no regressions.
7. Behavioral scenarios exist that exercise the disposition model against representative items drawn from
   the two regression sessions (at minimum: a cheap+safe → Sweep case; a high-effort+high-impact → Discuss
   case; a gated → Defer case; an out-of-scope → operator-veto Delete case).
8. `./tests/check-structure.sh` passes; the new behavioral scenarios pass; `./install.sh` creates the
   symlink idempotently.
9. The `## Termination` / disposition wording in the hand-off learning doc and the skill agree (the doc is
   the author-facing reference; the skill is the agent-facing contract).

## Out of Scope

- A **second** skill for feature-collection sweeps (resolved: one skill — see cross-validation #1).
- A *mode toggle* (debt vs feature). The disposition model handles both kinds emergently.
- Auto-running the sweep (it's operator-triggered at a cycle boundary; no auto-chain from `product-finalize`
  in this feature — a possible future SURFACE, not now).
- Rewriting `product-finalize`'s existing backlog-sweep step. `product-finalize` *records dispositions* at a
  cycle boundary; this skill *does the deferred work*. They are complementary; this feature does not merge
  them. (May add a one-line pointer from finalize → this skill; TBD in plan.)
- Changing the feature Work Tree "Phase" schema or any existing transition IDs.

## Technical Constraints

- **No 3rd-party dependency** (3rd-party probe check: N/A — markdown + shell repo only, per `arch.md` → Dev
  Environment). Skip.
- **State machine lives in three places** — `transitions.md`, SKILL.md, `tests/scenarios/*.yaml` — and must
  stay in sync (CLAUDE.md invariant). Any new transition ID must be added to all three.
- **`temporary-wbs` is not currently a state in any workflow.** It has only ever existed as an *artifact
  shape* hand-authored outside the skill system. This feature introduces the first skill that *emits* it.
  Decision needed (Open Questions): does this become a new **product-workflow state** (P-series transition
  ID), or a standalone operator-triggered skill outside the strict state machine (like `util-*`)?
- **Skill-add recipe** (`docs/lessons/debug-skill-template.md`): mirror the precedent shape across SKILL.md
  scaffold + fixtures + scenarios + `check-structure.sh` pins; ensure the agent-facing discoverability
  surfaces (SKILL.md, orchestrator AGENTS.md) are wired, not just the author-facing CLAUDE.md.
- **Path-qualification mandate** (CLAUDE.md): every `.claude/` reference in the new SKILL.md must be
  qualified `~/.claude/` or `<proj-dir>/.claude/` — bare `.claude/` is forbidden (Phase 12 check).
- **Effort benchmark is consuming-project-relative**, not this repo's units (cross-validation #3).

## Open Questions

- [ ] **Skill category & transition surface.** Is this a **product-workflow state** (gets a `P<n>`
      transition, listed in `product-workflow/AGENTS.md` `skills:`, appears in the state diagram) — or a
      **standalone operator-triggered skill** in the `util-*` mold (user-invoked, no state-machine slot,
      descriptive token instead of a P-ID)? The sweep is operator-triggered at a boundary, runs to
      completion, and folds back — which *resembles* a `util-*` standalone more than a linear product state.
      But it produces a WBS that then drives feature/task workflows, which *resembles* `product-wbs`. This
      determines the transition-ID scheme, AGENTS.md wiring, and check-structure phase. **→ Likely needs
      `/feature-research` (F3) to settle by examining how `util-*` vs `product-*` skills differ in
      practice, OR a quick operator decision.**
- [ ] **Final skill name.** `product-debt-paydown` vs `product-sweep` vs a `util-backlog-sweep`. Depends on
      the category decision above.
- [ ] **Does `product-finalize` get a pointer to this skill?** (one-line "deferred work is paid down via
      `/<this-skill>`") — cheap, improves discoverability; confirm in plan.
- [ ] **How are the two regression sessions encoded as tests?** Real scenario fixtures drawn from
      replicator/Claudesk items, vs. synthetic representative items. (Leaning synthetic-but-faithful to
      avoid coupling tests to other projects' private artifacts; confirm in plan.)

## Recommended next step

The disposition-model content is fully settled by the cross-validation, but **one architectural unknown
remains** (Open Question #1: product-workflow state vs `util-*` standalone), and it drives the transition
scheme, AGENTS.md wiring, naming, and which `check-structure.sh` phase to extend. That is exactly a
research-shaped question.

→ **F3 → `/feature-research`** to settle the category/transition-surface question (examine `util-*` vs
`product-*` skill mechanics), unless the operator wants to decide it directly now (which would let us go
**F4 → `/feature-plan`** immediately).

## Research

**Question:** product-workflow STATE (option A) vs standalone `util-*`-style operator skill (option B)?

**Recommendation: Option B — a standalone operator-triggered skill, modeled on the `util-*` category.**
The skill should be named with a non-`product-` prefix to avoid implying state-machine membership.
**Proposed name: `util-backlog-sweep`** (the operator may prefer `util-debt-paydown`; final name is an
operator pick at plan — see below).

### Evidence

The `util-*` category is defined in `docs/product/arch.md` lines 268–281 (Revision 2026-06-13). Its
distinguishing properties map the sweep skill onto B on *every behavioral axis*:

| `util-*` property (arch.md 270–277) | Sweep skill match? |
|---|---|
| Owns no state node; emits no F/I/T/P/S transitions | ✅ The sweep is invoked at a boundary, not reached by a transition from another state. |
| No `RETURN-TO:` (it's an entry point, not a pulled sidebar) | ✅ It runs to completion and folds back; nothing resumes it. |
| Not in any orchestrator's `skills:` list | ✅ It is not a step in the linear `vision→roadmap→…→context` product flow. |
| Frontmatter `name`/`description`/`argument-hint` only | ✅ matches. |
| Mode menus encouraged for aggression-spectrum utilities | ✅ The sweep wants a Step-by-step↔Autopilot spectrum (operator reviews Discuss items; veto/Defer paths). `util-prune-claude-md`'s 4-mode menu is the precedent. |

**Resolving the stated tension** ("it emits a temporary-wbs like `product-wbs`, so maybe it's a product
state"): producing an artifact ≠ being a state. `util-prune-claude-md` *also* writes durable artifacts
(`docs/lessons/<topic>.md`, edits `arch.md`) without being a workflow state. The temporary-WBS the sweep
emits is *consumed by* feature/task workflows the operator then drives manually — exactly the `util-*`
"entry point, then hand to a workflow" shape, not a linear product-state handoff. The product workflow is
the strategic decomposition pipeline (vision → … → wbs → context, one-product-per-codebase); a
between-milestone scratch sweep that reserves no roadmap slot and self-deletes is by definition NOT a stage
of that pipeline. The learning doc itself frames it as "NOT a roadmap milestone … scratch work between
milestones."

**Why NOT option A:** adding it as a product state would force a `P<n>` transition ID into a pipeline it
doesn't belong to, an entry in `product-workflow/AGENTS.md`'s `skills:` + state diagram + transition table
+ pause-policy table (all of which assume linear flow), and would muddy the "assume one product per
codebase; product workflow completes after wbs/context" invariant. High wiring cost, wrong semantics.

### Concrete consequences for the plan (so plan need not re-litigate)

- **Naming:** `util-backlog-sweep` (prefix `util-`; final token operator's pick at plan).
- **Transition-ID scheme:** **none.** No P/F/I/T/S token. Like `util-prune-claude-md`, the skill emits no
  workflow transition. (It MAY use descriptive internal status prose, but no machine transition token.)
- **AGENTS.md wiring:** **none.** Do NOT add to `agents/product-workflow/AGENTS.md` `skills:` or any
  orchestrator. (This is the load-bearing difference from a product state.)
- **transitions.md edits:** **none required for the state machine.** Optionally a one-line mention under a
  "standalone utilities / `util-*`" note if one exists — but `transitions.md` is the state-machine doc and
  util-* skills are explicitly outside it. The authoritative category home is `arch.md` → `util-*` section.
- **arch.md:** extend the existing `### `util-*` skill category` subsection's "Current util-* skills:" list
  with the new skill (one line), the same way `util-prune-claude-md` is listed there.
- **CLAUDE.md (project root):** add a convention bullet (the skill-add disciplines + pointer to the learning
  doc + the cross-validation regression-suite note).
- **check-structure.sh phase to extend:** Per arch.md line 281, **util-* currently has NO structural pin**
  ("doc-enforced via this section + the `util-` prefix; would gain pins only if a structural marker becomes
  load-bearing, mirroring debug-* at Phase 3b/3c"). Two options for the plan:
    - **B1 (minimal, matches current util-* discipline):** no new check-structure phase; rely on the
      `util-` prefix + arch.md listing, exactly as `util-prune-claude-md` ships today. Lowest cost; matches
      the documented status quo.
    - **B2 (introduce the first util-* structural pin):** add a small `Phase 3f` (or similar) pinning the
      new skill's frontmatter + required sections + the arch.md "Current util-* skills" listing, thereby
      *establishing* the util-* structural-marker discipline that arch.md line 281 says is deferred. Higher
      cost; sets a precedent for all future util-* skills.
  → **Lean B1** (honor the documented "no pin until load-bearing" stance), but surface B2 as an operator
    choice at plan, since this is the second file-based util-* skill and a pin precedent may now be worth
    it. *(This is a plan-time scope decision, not a spec change — the spec's AC#6 "structural pins …
    mirroring the skill-add recipe" is satisfied by either; AC text may be softened at plan to "if a pin is
    introduced.")*

### Does this change the spec?

**No — spec holds (F5 → plan).** The spec's AC#4/#5 (state-machine three-place sync; AGENTS.md wiring)
were written assuming the category was unsettled; they are now *narrowed* by this finding (no transition,
no AGENTS.md wiring) rather than invalidated. The plan will phase the work under option B. The only AC that
softens is #6 (structural pins → "if introduced, per B1/B2 operator choice"). That is a refinement within
the spec's intent, not a contradiction of it, so no F6 back-loop is warranted.

## Work Tree

- [x] Phase 1: Author the `util-backlog-paydown` SKILL.md  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `test -f skills/util-backlog-paydown/SKILL.md` exits 0.
  - CLI: `python3 -c "import yaml,sys; yaml.safe_load(open('skills/util-backlog-paydown/SKILL.md').read().split('---')[1])"` exits 0 (frontmatter is valid YAML — `argument-hint` with inner colons is quoted; guards the regression at backlog line 39).
  - CLI: frontmatter contains `name: util-backlog-paydown` and a `description:` and an `argument-hint:` (`grep -E '^name: util-backlog-paydown' …` exits 0).
  - CLI: the body contains a `## Category` section declaring util-* / no-transition / no-`RETURN-TO` (`grep -F 'util-*' skills/util-backlog-paydown/SKILL.md` AND `grep -F 'no transition' || grep -iF 'emit no' …` matches). Heading matches the util-prune-claude-md precedent (`## Category`, not `## Category Context`).
  - CLI: the body encodes each disposition-model element — `grep` finds all of: the three axes (`Impact`, `Effort`, `Risk`), the five actions (`Sweep`, `Discuss`, `Defer`, `Bury`, `Delete`), the words `operator veto` (or `operator-veto`), `theme` (theme-over-instance), `temporary-wbs`, `fold-back` (or `fold back`), and a mode menu (`Step-by-step` … `Autopilot`).
  - CLI: NO workflow transition token authored as a machine signal — `grep -E 'TRANSITION: (P|F|I|T|S)[0-9]' skills/util-backlog-paydown/SKILL.md` returns nothing (exit 1).
  - [x] P1.1 Author SKILL.md frontmatter (`name`/`description`/`argument-hint`, inner colons quoted) modeled on `skills/util-prune-claude-md/SKILL.md`.  <!-- status: NOT-STARTED -->
  - [x] P1.2 Write `## Category` (util-* / no-transition / no-RETURN-TO, pointer to arch.md util-* section), `## What it does`, `## When to use` / `## When NOT to use` (clean cycle boundary; accrued rolled-forward refactor batch; pre-release — from the learning doc's trigger list).  <!-- status: NOT-STARTED -->
  - [x] P1.3 Encode the disposition model verbatim-faithful to `docs/lessons/between-milestone-debt-paydown-sweep.md`: 3 axes (with maintainability = quality × P(future-touch); effort benchmarked against THE CONSUMING PROJECT's archived WBS/WIP units; risk suite-relative), 5 actions + triggers, Rule 1 (cheap+safe → ALWAYS Sweep, no exception) + the why, ordering rules (deletions → low-risk → high-impact → co-location; effort gates not sorts).  <!-- status: NOT-STARTED -->
  - [x] P1.4 Encode operator-veto as a FIRST-CLASS pre-scoring disposition (bypasses axis-scoring → Delete/Defer with a recorded reason) and the dual scoring-fidelity paths (full table for raw backlog vs light-touch prose+size for pre-groomed buckets).  <!-- status: NOT-STARTED -->
  - [x] P1.5 Encode the process (inventory + theme-over-instance MINOR grouping via a subagent fan-out read; read-real-code-before-Discuss; emit `shape: temporary-wbs` with an explicit "what's NOT swept — anchors intact" scope section + a fold-back-and-delete completion section) and a `util-*` mode menu (Step-by-step↔Autopilot, mirroring util-prune-claude-md's 4 modes).  <!-- status: NOT-STARTED -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete (CLI-grep observation all-PASS) -->
  - [x] verify-human  <!-- status: AUTO-SKIP (Mode-3 gate: no integration boundary, verify-self all-PASS) -->
  - [x] verify-codify  <!-- status: complete (disposition model codified in Phase 3 util.yaml scenarios) -->

- [x] Phase 2: Wire discoverability surfaces (arch.md, product-finalize pointer, CLAUDE.md) + install symlink  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `arch.md` "Current util-* skills:" list now names `util-backlog-paydown` (`grep -F 'util-backlog-paydown' docs/product/arch.md` exits 0) and arch.md line ~281 "no structural pin yet" stance is left INTACT (B1) — `grep -F 'no structural pin' docs/product/arch.md` still exits 0.
  - CLI: `skills/product-finalize/SKILL.md` contains an ADVISORY pointer to `/util-backlog-paydown` (`grep -F 'util-backlog-paydown' skills/product-finalize/SKILL.md` exits 0) AND that pointer is NOT a transition (the surrounding line contains advisory phrasing like "consider" and emits no `TRANSITION:` token — `grep -B1 -A1 'util-backlog-paydown' skills/product-finalize/SKILL.md` shows no `TRANSITION:` on those lines).
  - CLI: project-root `CLAUDE.md` has a new convention bullet naming `util-backlog-paydown`, `docs/lessons/between-milestone-debt-paydown-sweep.md`, and the two regression sessions (`grep -F 'util-backlog-paydown' CLAUDE.md` exits 0).
  - CLI: `./install.sh` exits 0 and `test -L ~/.claude/skills/util-backlog-paydown` is a symlink resolving into this repo (`readlink ~/.claude/skills/util-backlog-paydown` contains `my-claude-code-customization`).
  - [x] P2.1 Append one line to arch.md's `### `util-*` skill category` → "Current util-* skills:" list (one-line entry, same shape as the util-prune-claude-md entry). Do NOT alter the "no structural pin yet" sentence.  <!-- status: NOT-STARTED -->
  - [x] P2.2 Add the advisory pointer to `skills/product-finalize/SKILL.md` (in the Backlog-Sweep step / §4 area) worded like `feature-spec`'s bug-fix discoverability pointer: "consider invoking `/util-backlog-paydown` to actually pay down deferred code-quality/debt items" — advisory prose only, NO transition, NO auto-chain. (Bootstrap-skip caveat: validate via fresh subprocess in Phase 3, per `docs/lessons/harness-bootstrap-skip.md`.)  <!-- status: NOT-STARTED -->
  - [x] P2.3 Add the project-root `CLAUDE.md` convention bullet (skill purpose + disposition-model one-liner + pointers to the learning doc and the two regression sessions as the cross-validation suite).  <!-- status: NOT-STARTED -->
  - [x] P2.4 Run `./install.sh`; confirm symlink.  <!-- status: NOT-STARTED -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete (CLI-grep + symlink observation all-PASS) -->
  - [x] verify-human  <!-- status: deferred to Phase 3 codify (integration boundary: product-finalize edit → tested by pointer-stays-advisory scenario in fresh subprocess) -->
  - [x] verify-codify  <!-- status: complete (product-finalize boundary covered by util.yaml pointer scenario) -->

- [x] Phase 3: Behavioral test scenarios + full structural sweep (the regression gate)  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: a new `tests/scenarios/util.yaml` exists with `group: util` and ≥5 scenarios for `skill: util-backlog-paydown`.
  - CLI: the disposition-model scenarios PASS via `./tests/run-tests.sh --group util` — at minimum: cheap+safe→Sweep; high-effort+high-impact→Discuss; gated→Defer; out-of-scope→operator-veto Delete. (util-* emits no transition → scenarios assert via `contains_required`/`contains_any` on the disposition-output prose, NOT `transition_id`.)
  - CLI: a scenario asserts the `product-finalize` advisory pointer STAYS advisory — `skill: product-finalize` run shows the `/util-backlog-paydown` mention but emits its normal `P13`/`P14` transition (the pointer does NOT divert it). Run via `./tests/run-tests.sh` fresh subprocess (sidesteps the in-session bootstrap-skip).
  - CLI: `./tests/check-structure.sh` exits 0 (no regressions; no new util-* pin added per B1).
  - [x] P3.1 Author `tests/scenarios/util.yaml` (4 disposition scenarios + 1 product-finalize-pointer-stays-advisory scenario; use `contains_required`/`contains_any`; avoid aggressive `not_contains` per the routing-fork + strict-mode lessons — only use `not_contains_strict` for a true failure-proxy phrase).  <!-- status: NOT-STARTED -->
  - [x] P3.2 Author 1–2 fixtures under `tests/fixtures/` if a scenario needs a seeded backlog/findings input (a small fake backlog with items spanning the four dispositions).  <!-- status: NOT-STARTED -->
  - [x] P3.3 Run `./tests/run-tests.sh --group util` (fresh subprocess — also validates the Phase-2 product-finalize edit past bootstrap-skip); iterate until PASS.  <!-- status: NOT-STARTED -->
  - [x] P3.4 Run `./tests/check-structure.sh`; confirm exit 0.  <!-- status: NOT-STARTED -->
  - [x] verify-auto  <!-- status: complete (util group: 4 SOFT_PASS dispositions + P13 pointer-advisory PASS; check-structure 334 PASS, 1 pre-existing host drift SURFACED) -->
  - [x] verify-self  <!-- status: complete (fresh-subprocess run validates product-finalize edit past bootstrap-skip) -->
  - [x] verify-human  <!-- status: AUTO-SKIP (Mode-3: integration boundary covered by the fresh-subprocess pointer scenario; verify-self all-PASS) -->
  - [x] verify-codify  <!-- status: complete (tests/scenarios/util.yaml + fixture; disposition model + pointer-advisory boundary codified) -->

## Code-Quality Review — util-backlog-paydown

*(feature-review-quality against ship commit aa5c831, drive_mode=autopilot/Mode-3. 0 CRITICAL, 1 MAJOR, 2 MINOR. MAJOR + MINORs auto-backlogged per Mode 3; F39 → finalize.)*

### Strengths
- Disposition model transcribed from the learning doc with high fidelity — all three axes, five actions, six rules, ordering rules, and crucially Rule 1's *no-exception* clause + its de-clutter-is-impact why survive intact.
- `## Category` block matches the `util-prune-claude-md` precedent exactly (no F/I/T/P/S tokens, no `RETURN-TO:`, points to arch.md util-* convention).
- The scenario YAML header correctly reasons about its own pass mechanics (util-* emits no transition → `contains_any` SOFT_PASS is the only achievable pass; verified against `tests/lib/verify.sh`).
- The product-finalize advisory pointer is genuinely non-chaining: prose only, no transition, and the FINALIZE-POINTER-ADVISORY scenario hard-asserts both pointer presence AND that the skill still emits P13 — a real integration-boundary codify test.
- Pre-existing host settings-fixture drift correctly surfaced as note-and-continue, not silently absorbed.

### Issues
**CRITICAL**
- (none)

**MAJOR**
- [tests/scenarios/util.yaml] [RESOLVED-2026-06-30] The four disposition scenarios cover Sweep / Discuss / Defer / Delete but **not Bury**. → **Fixed post-review**: added `UTIL-PAYDOWN-MEH-BURY` over the existing `MEH-1` fixture item; SOFT_PASS confirmed (run-2026-06-30-140726). Backlog entry resolved.

**MINOR**
- [skills/util-backlog-paydown/SKILL.md] Grammar slip: `An "carve out an exception…"` should be `A "carve out…"`. Cosmetic, but it's the parenthetical guarding the load-bearing Rule-1-no-exception why. → auto-backlogged.
- [skills/util-backlog-paydown/SKILL.md] Ordering-rules list nests the cross-cutting "Risk outranks impact in ordering" clarification under rule 5 ("Effort is NOT an ordering key"); faithful to the lesson's structure but a literal reader may be momentarily confused. Consider promoting to a top-level note. → auto-backlogged.

### Assessment
Well-built, disciplined codification of a real operator pattern; fidelity to the load-bearing rules + their why is excellent. Follows the util-* category convention rather than inventing state-machine surface, takes the documented no-new-pin status quo (B1), and adds a genuinely advisory finalize pointer the suite proves does not auto-chain. The one substantive gap is the missing Bury scenario — a one-scenario follow-up, not a structural problem.

### If you disagree
Dismiss any finding by marking it `[DISMISSED]` in this section before `feature-finalize` archives the WIP.

## Retrospect
- **What changed in our understanding:** The "two regression sessions" the hand-off doc referenced turned out to be a *family of five* sweeps in replicator-1-0 (waves 1/2/3 + keepers + a gated defer), not one — and they ran in a single grooming sitting. That directly answered the doc's "one skill or two?" open question (one skill; debt-vs-feature is emergent from scoring, not a mode). The disposition model predicted ~100% of replicator's real includes/excludes, validating it as a regression suite.
- **Assumptions that held:** Category resolution to `util-*` (option B) was clean — the skill matched the util-* contract on every behavioral axis; the "it emits a WBS like product-wbs" tension dissolved (producing an artifact ≠ being a state). B1 (no new structural pin) matched the documented util-* status quo exactly.
- **Assumptions that were wrong:** None major. Minor: initially set the finalize-pointer scenario's `product_dir` to the parent fixtures/product (wrong — needed the wbs-complete subdir); caught at first run. The disposition scenarios can only reach SOFT_PASS (util-* emits no transition) — anticipated and acknowledged in the YAML header, not a surprise.
- **Approach delta:** Implementation matched the plan's three phases exactly. One scoped addition mid-flight: reconciled the spec's AC#4/#5/#6 text to option-B after research narrowed them (kept the feature internally consistent). The review-quality MAJOR (missing Bury scenario) is a real, honestly-backlogged gap — the fixture item for it already exists, so it's a ~5-min follow-up rather than rework.

## Current Node
- **Path:** Feature > all phases complete
- **Active scope:** none — build + per-phase verify loops done for Phase 1, 2, 3
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** SURFACE-2026-06-30-SETTINGS-FIXTURE-DISABLECLAUDEAICONNECTORS-DRIFT (pre-existing host drift, note-and-continue, logged to backlog)
- **Next:** ship → review-quality → finalize

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [SURFACED-2026-06-30] feature-spec — `arch.md` is 381 lines (exceeds 300-line size guard); read first 100 + headings only.
- [SURFACED-2026-06-30] feature-research — Category resolved to `util-*` standalone (option B). This is only the SECOND file-based util-* skill; arch.md line 281 defers util-* structural pins until "load-bearing." Operator chose B1 (no pin, status quo).
- [SURFACED-2026-06-30] feature-plan — No `tests/scenarios/util.yaml` exists yet (util-prune-claude-md shipped with no scenarios). This feature adds the FIRST util scenario file — additive, consistent with B1 (a behavioral scenario file is not a structural pin). The test runner is group-agnostic (iterates `tests/scenarios/*.yaml`), so no runner change is needed.
- [SURFACED-2026-06-30] feature-plan — backlog line 28 MINOR notes util-* `## Category` heading drift vs debug-*'s `## Category Context`. This skill deliberately uses `## Category` to match the util-prune-claude-md precedent (the correct util-* heading).
- [SURFACED-2026-06-30] feature-plan — backlog line 39: SKILL.md frontmatter must be valid YAML (quote inner-colon `argument-hint`). Baked into Phase 1 verify-auto outcome.
