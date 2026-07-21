# Feature: Design Priors — learned product-design decision principles

**Workflow:** feature
**State:** COMPLETED 2026-06-26 — shipped (commit 6542e57, NOT pushed); review-quality clean-of-CRITICAL (2 MAJOR + 3 MINOR auto-backlogged); finalized.
**Created:** 2026-06-26
**Entry:** spec (complex feature)
**drive_mode:** autopilot

## Plan-time decisions (4 open questions resolved)

- **Q3 reversal-probe:** IN, minimal — one optional probe line in the capture contract ("reversal with no stated why → ask once if a principle is behind it"). No dedicated scenario; operator may cut at verify-human.
- **vision capture-vs-consult:** **capture-only** at `product-vision` — it is the *source* of identity/anti-persona priors, not a consumer of tradeoff-leans. Vision does NOT load design-priors for consult.
- **schema-location:** the canonical `design-priors.md` schema is documented in `docs/product/arch.md`'s **File Schema family** (alongside Work Tree / Task WIP), for consistency. The skill prose references it; it is not re-inlined per skill.
- **disclosure-naming:** when a prior fires (tie-break or contradiction), the standard disclosure form is **`[PRIOR: <slug>] leaning <x> — flag if wrong`**, emitted into the plan/spec/roadmap output.

## Structural notes discovered at plan time

- Only `feature-spec` and `product-vision` currently have `## Step 0: Available product context` sections. `product-roadmap`, `product-wbs`, `product-arch`, `feature-verify-human`, `session-reflect` do **not** — so consult/capture hooks for those skills are **new prose insertions**, not edits to an existing Step 0.
- Global per-skill load mapping table lives in `CLAUDE.snippet.md` (line ~100). `design-priors.md` must be added as a new column-row entry for each consult skill.
- `check-structure.sh` is at Phase 12; this feature adds **Phase 13** (design-priors structural pins).
- This feature adds **behavior within existing states** (Step-0-style consult + capture move) — **no new F/P transition IDs**. transitions.md gets a descriptive subsection only.

## Problem Statement

The operator deliberately leaves gaps in feature/scope asks and lets Claude Code fill them from convention. ~90% of the time the "average / common-sense" fill is correct. The remaining ~10% is where the right fill is the operator's **project-specific product-design lean** (focus-vs-breadth, perf-vs-ship, defaults-vs-config, an anti-persona, etc.) — and there CC fills it "average" instead of "the operator's way." Today the only mitigation is autopilot → correct at verify-human; it works (preserves operator attention) but burns tokens/AI-time rebuilding the wrong thing, and the *same class* of mis-fill recurs across features because nothing durable records *why* the operator decides the way they do.

This feature adds a per-project, canonical, deterministically-loaded document — `docs/product/design-priors.md` — of the operator's **design priors**: terse, transferable statements of how they resolve recurring product-design tradeoffs *for a given project*, each paired with its *why*. Skills **capture** priors (propose → operator reviews/enriches → write) at the moments operator input reveals a transferable principle, and **consult** priors at planning time to fill product-design gaps the operator's way. Priors are **directional, overridable-by-strong-evidence, tie-breaking** — not decisive — so the 90% common-sense path is untouched and the over-infer failure mode (a prior firing on a decision it doesn't govern) is structurally guarded.

This is a workflow-system feature: this repo ships the **behavior** (the doc schema, the consult-contract in planning skills, the capture mechanism, structural pins, test scenarios). The `design-priors.md` files themselves live in *consuming* projects, per the established "skill repo ships behavior, not state" principle (vision.md §6).

## User Stories

- As the operator, when I make a product-design tradeoff decision (or correct one) and state/imply a *generalizable why*, I want CC to **propose recording it as a design prior** so I don't have to re-teach the same lean on the next feature — and I want to **review and enrich the inferred why** before it's written, because the real reasoning is in my head.
- As the operator, when CC fills a product-design gap at roadmap/wbs/feature-spec time, I want it to **consult recorded design priors** so the fill matches my project's lean — *without* CC suddenly asking lots of questions or steering off "average" for decisions no prior actually governs.
- As the operator, I want design priors to be **overridable**: when strong common-sense evidence says a recorded prior doesn't apply here, CC should fill from common sense and **disclose** the override, not blindly obey the prior.
- As the operator, I want priors stored in a **dedicated, deterministically-loaded** doc (not CLAUDE.md — context bloat; not the memory store — non-deterministic load) so consulting them is free at exactly the decision moments and nowhere else.

## Acceptance Criteria

The feature is done when:

1. **Schema.** `docs/product/design-priors.md` has a defined, documented schema. Each prior records: a short **ID/slug**, the **tradeoff axis** (or identity/anti-persona), the **lean** (the direction), an **inferred-why**, and the operator's **corrected/true-why** *preserved as a distinct field when it differs from the inferred-why* (the gap is the signal — Q2 ruling). Plus a capture date. Priors are terse (≈one entry = a few lines). The doc is a durable product doc (frontmatter `stage`, `state`, `updated`), in the same family as `vision.md`/`arch.md`, surviving cycles, with a size guard consistent with the 300-line product-doc rule.

2. **Consult contract.** The planning skills that make product-design decisions — **`product-roadmap`, `product-wbs`, `feature-spec`** (and `product-vision` only as a pointer; see Open Q) — load `design-priors.md` at their `## Step 0` product-context load step (added to the per-skill load mapping), and apply the **consult weighting rules**:
   - No prior governs the decision → fill from common sense (90% path untouched).
   - A prior *agrees* with the common-sense default → take it, higher confidence, brief note.
   - A prior breaks a *genuine tie* → lean prior + **disclose**.
   - A clear common-sense default *contradicts* a strong prior → **the 10% case → surface as a proposal; never silently steer (neither auto-adopt the prior nor auto-ignore it).**
   - **A prior only fires on the axis it is actually about** (the over-infer guard — a prior must not be stretched to a decision it doesn't govern).

3. **Capture contract.** At the checkpoints where operator input is *likely* to reveal a prior — **`product-vision`, `product-roadmap`, `product-arch`, `product-wbs`, `feature-spec`, `feature-verify-human`** — a lightweight capture move fires when the **capture discriminant** holds (operator made/corrected a *product-design tradeoff* — or stated an identity/non-goal/anti-persona — AND a *transferable why* is stated or implied). On fire, CC **proposes** the prior (inferred lean + inferred why), the operator **reviews/enriches/corrects the why** (and may reject), and only then is it written. A **backstop sweep** in `session-reflect` catches the long-tail checkpoints (the "other steps, less likely" cases) by asking once whether any decision this session revealed a durable design prior.

4. **Anti-noise + over-infer guards (the rigorous-engineering core).**
   - Capture is **propose-never-auto-write**; operator approval is required before any line is written to `design-priors.md`.
   - Before proposing, CC **reads existing priors and dedup/conflict-checks**: a duplicate is not re-added; a *contradicting* new prior is surfaced as a conflict (the lean may have shifted, or the projects differ) rather than silently appended.
   - **Arch-boundary exclusion (Q1 ruling):** technical/architecture tradeoffs (stack choice, operational mechanics) are **NOT** design priors — they belong in `arch.md`. The capture discriminant explicitly excludes them. Rationale: low per-project frequency → low prior value; avoids over-infer risk now; revisitable later.
   - **FACT/NOTHING exclusion:** bare one-off preferences, label/copy fixes, pure scope additions, and dependency-driven sequencing are NOT priors (session-reflect / WIP territory).
   - **Reversal-with-no-why → probe once, gated (Q3 — proposed, operator to confirm/cut at spec review):** a decision reversal with no stated why triggers at most one optional probe ("is there a principle behind this?"); a "no" captures nothing.

5. **Vision/arch non-collision.** Spec documents the crisp seam: **vision = what/who the product is (destination, set-once-stable); design-priors = how the recurring tradeoffs are resolved in service of that (directional, accreting); arch = technical/stack tradeoffs.** Cross-link, don't overlap. (Vision read this session confirms vision.md is destination-genre and is NOT loaded at wbs/spec time, which is exactly why priors need their own doc.)

6. **Structural pins + tests.** `tests/check-structure.sh` gains pins asserting: the consult-load step names `design-priors.md` in each consult skill's `## Step 0`; the capture move is present in each capture skill; the global per-skill load mapping in `CLAUDE.snippet.md` lists `design-priors.md`. Test scenarios (seeded from `workflow/wip/design-priors-corpus-DRAFT.md`) assert: capture FIRES on a principled-tradeoff input, does NOT fire on a bare fact / arch-tradeoff / scope-add; consult CHANGES a fill when a governing prior exists, does NOT change (NOCHANGE) when no prior governs the axis (the B6 over-infer trap).

7. **Three-places-in-sync.** If any transition wording changes, `transitions.md` / SKILL.md / scenarios are updated together. *Expected:* this feature adds **behavior within existing states** (Step-0 consult + capture move), not new transition IDs — confirm during plan; if confirmed, transitions.md gets a descriptive subsection but no new F/P IDs.

## Out of Scope

- **Global/cross-project priors.** Global conventions already live in this workflow system; this feature targets **project-specific** product-design priors only.
- **Technical/architecture priors.** Excluded by the Q1 ruling — they stay in `arch.md`. (Revisitable later.)
- **The latitude/guardrail reconciliation** (good-latitude vs bad-latitude, the `SURFACE-2026-06-25-AUDIT-PROMPT-LATITUDE` class). Operator ruled this out of scope.
- **Auto-writing priors without operator review.** Never — propose-then-review is the contract.
- **Replacing session-reflect's fact/lesson capture.** Design priors are a distinct, narrower genre (transferable product-design *why*); the two coexist.
- **Retrofitting `design-priors.md` into existing consuming projects.** The doc is created lazily on first capture; absent file = silent no-op at consult time.

## Technical Constraints

- **No runtime.** Like all of this repo, the deliverable is markdown schemas + skill prompt contracts + structural pins + scenarios (arch.md: "no runtime, no services, no database").
- **Deterministic load only.** Must NOT rely on the auto-memory store (non-deterministic load — operator-confirmed disqualifier). Load is via the explicit `## Step 0` product-context mechanism in planning skills (canonical mapping in `CLAUDE.snippet.md`).
- **No CLAUDE.md bloat.** Priors must not be injected into global context; they load only at the planning steps that consult them.
- **Pause-policy invariant preserved.** Capture-propose at `feature-verify-human` happens at an *already-PAUSE* point (verify-human is the canonical autopilot pause), so it adds no new autopilot stop. Capture at product-workflow checkpoints must not introduce AUTO-path pauses that violate the drive-mode pause policy — confirm placement during plan.
- **Source-ships-behavior.** `design-priors.md` instances live in consuming projects, never in this repo's own `docs/product/`. This repo ships the schema doc + skill contracts.
- **Corpus is the test oracle.** `workflow/wip/design-priors-corpus-DRAFT.md` (23 labeled cases + extracted patterns) is the source for scenario design and the discriminant/weighting prose.

## Open Questions

- [ ] **Q3 — reversal-probe:** Confirm or cut the "reversal-with-no-why → probe once" capture behavior (AC#4). Low-stakes, optional; proposed IN, operator to decide at spec/plan review.
- [ ] **product-vision capture vs consult:** vision is a capture checkpoint (identity/anti-persona priors often surface there) but should it also *consult* priors, or only emit them? Lean: capture-only at vision (it's the source of identity, not a consumer of leans). Confirm at plan.
- [ ] **Schema location of the doc-schema spec:** does the canonical `design-priors.md` schema get documented in `arch.md` (File Schema family, alongside Work Tree / Task WIP) or inline in a new schema section? Lean: `arch.md` File Schema family for consistency. Decide at plan.
- [ ] **Naming the consult-emitted disclosure:** when a prior fires (tie-break or contradiction), what's the standard disclosure form in the plan/spec output? (e.g. a one-line `[PRIOR: <id>] leaning <x>; flag if wrong`.) Decide at plan.

These are design-detail questions resolvable at plan time, not research-grade unknowns — no spike or 3rd-party probe needed. **All four resolved above (see "Plan-time decisions").**

## Work Tree

- [x] Phase 1: Schema + canonical doc definition  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -q "design-priors.md" docs/product/arch.md` exits 0 (schema documented in File Schema family).
  - CLI: the documented schema block in `arch.md` contains all required fields — `grep -E "slug|axis|lean|inferred-why|corrected-why|date"` over the design-priors schema section matches all six.
  - CLI: `grep -q "design-priors" CLAUDE.snippet.md` exits 0 (global mapping row added).
  - CLI: a sample `design-priors.md` fixture validates against the schema (frontmatter `stage`/`state`/`updated` present, ≥1 well-formed prior entry) — `tests/fixtures/product/design-priors-done/design-priors.md` parses.
  - [x] P1.1 Add `### File Schema: Design Priors Format (docs/product/design-priors.md)` to `arch.md` File Schema family — fields: slug, axis-or-identity, lean, inferred-why, corrected-why (preserved-when-differs), date; terse-entry rule; size-guard note; durable-doc frontmatter (`stage: design-priors`, `state`, `updated`)  <!-- status: complete -->
  - [x] P1.2 Add the `design-priors.md` schema family note to `arch.md` Revision section dated 2026-06-26; bump frontmatter `updated`  <!-- status: complete -->
  - [x] P1.3 Add `design-priors.md` rows to the global per-skill load mapping table in `CLAUDE.snippet.md` + a "## Design priors (GLOBAL)" subsection stating the consult-weighting rules, capture discriminant, arch-boundary exclusion, and disclosure form  <!-- status: complete -->
  - [x] P1.4 Create `tests/fixtures/product/design-priors-done/design-priors.md` — a valid sample with 4 priors drawn from the corpus (P-FOCUS, P-SHIP, P-DEFAULTS, P-ANTI), demonstrating the inferred-why/corrected-why gap on P-FOCUS and P-DEFAULTS  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete; no integration boundary (isolated new artifacts only); subagent 6/6 PASS -->
  - [x] verify-human  <!-- status: complete; F11 auto-skip (Mode 3, no boundary, verify-self all-PASS); affirmation + schema-decision veto surface printed in chat -->
  - [x] verify-codify  <!-- status: complete; coverage deferred to Phase 4 (P4.1 pin batch) by design — see codify note below; fixture well-formed, no half-coverage, 303-pin sweep clean -->

- [x] Phase 2: Consult contract in planning skills  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: each of `skills/product-roadmap/SKILL.md`, `skills/product-wbs/SKILL.md` gains a Step-0-style "Available product context" consult block naming `design-priors.md` — `grep -l "design-priors.md" skills/product-roadmap/SKILL.md skills/product-wbs/SKILL.md` lists both.
  - CLI: `feature-spec` Step 0 (existing) updated to add `design-priors.md` to its load list — `grep -q "design-priors" skills/feature-spec/SKILL.md` exits 0.
  - CLI: each consult skill's block contains all 5 weighting rules including the over-infer guard — `grep -E "only fires on the axis|does not govern"` matches in each.
  - CLI: each consult skill names the disclosure form `[PRIOR:` — `grep -q "\[PRIOR:" skills/product-wbs/SKILL.md` exits 0.
  - [x] P2.1 `product-roadmap`: add `## Step 0: Available product context` with `design-priors.md` consult (eager-read) + the 5 weighting rules + disclosure form + over-infer guard  <!-- status: complete -->
  - [x] P2.2 `product-wbs`: add `## Step 0` consult block (mirrors roadmap; wbs decomposes the next milestone so priors govern WP-level design choices)  <!-- status: complete -->
  - [x] P2.3 `feature-spec`: extend existing Step 0 — add `design-priors.md` to eager-read list + weighting-rules pointer + disclosure form + size-guard line  <!-- status: complete -->
  - [x] P2.4 `feature-plan`: pointer-only mention (plan consumes the spec's already-applied priors; note design-priors in its Step 0 pointer list so it doesn't re-decide)  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; structural sweep 303/0 + scoped grep outcomes PASS -->
  - [x] verify-self  <!-- status: complete; integration boundary (4 harness-consumed skills, cited by name); subagent 8/8 PASS incl. frontmatter-parseability -->
  - [x] verify-human  <!-- status: complete; F13 operator-approved 2026-06-26 (wording of 5 weighting rules, disclosure form, feature-plan inherit, Step-0 placement). Operator condition: comprehensive behavioral scenarios are MANDATORY at Phase 4 (carried as hard AC). -->
  - [x] verify-codify  <!-- status: complete; behavioral consult scenarios consolidated to Phase 4 P4.2 (need full machinery + fresh subprocess); no regression (303/0), no half-coverage, skills parse, symlinks live; no test failures → no triage -->

- [x] Phase 3: Capture contract + dedup/conflict guard  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: each capture skill (`product-vision`, `product-roadmap`, `product-arch`, `product-wbs`, `feature-spec`, `feature-verify-human`) contains a "Capture a design prior" move — `grep -l "design prior" skills/<each>/SKILL.md` lists all six.
  - CLI: the capture move states propose-never-auto-write + operator-review-the-why + dedup/conflict-check — `grep -E "propose|review.*why|dedup|conflict"` matches in each.
  - CLI: the capture move states the arch-boundary exclusion (technical/stack tradeoffs → arch.md, NOT a prior) and FACT/NOTHING exclusions — `grep -q "arch.md" + "not a (design )?prior"` matches.
  - CLI: `session-reflect` gains the backstop sweep question — `grep -q "design prior" skills/session-reflect/SKILL.md` exits 0.
  - [x] P3.1 Author a single canonical "Capture a design prior" prose block — authored as compact per-skill pointers referencing the canonical contract in `CLAUDE.snippet.md` → "Design priors (GLOBAL)" (single source; avoids 6-way drift) + per-checkpoint emphasis  <!-- status: complete -->
  - [x] P3.2 Insert the capture block into the 6 capture skills, tuned per-checkpoint (vision = identity/anti-persona §2b; arch = boundary-is-the-discipline §3b; roadmap/wbs/feature-spec appended to Step-0 consult block; verify-human = correction-reveals-lean §6b at already-PAUSE point)  <!-- status: complete -->
  - [x] P3.3 `session-reflect`: backstop sweep added to §2 Reflection Analysis ("Design priors (backstop sweep)" block — did any decision reveal a durable prior? propose if yes)  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; structural sweep 303/0 + scoped grep outcomes (6 capture skills, backstop, exclusions, 7-skill frontmatter) ALL-PASS -->
  - [x] verify-self  <!-- status: complete; integration boundary (7 harness-consumed skills, cited); subagent 9/9 PASS incl. propose-only-everywhere, verify-human bare-fix-vs-lean line, arch boundary, vision capture-only, 7-skill frontmatter -->
  - [x] verify-human  <!-- status: complete; F13 operator-approved 2026-06-26 (over-capture guards: bare-fix-vs-lean line, propose-only friction, arch boundary tie-breaker biases toward not-capturing, no-new-pause, centralize-and-point authoring). NEW operator requirement: add a revert safety net before ship (see Phase 4 + Reverting section). -->
  - [x] verify-codify  <!-- status: complete; capture behavioral scenarios consolidated to Phase 4 P4.2 (need full machinery + fresh subprocess); no regression (303/0), no half-coverage, 7 skills parse + symlinks live; no test failures → no triage -->

- [x] Phase 4: Structural pins + behavioral scenarios + tripartite sync  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `tests/check-structure.sh` gains `[Phase 13] Design priors` with grep_check pins for: schema in arch.md; global mapping row; consult block present in roadmap/wbs/feature-spec; capture block present in the 6 capture skills; session-reflect backstop. `bash tests/check-structure.sh` exits 0 with the new pins counted.
  - CLI: behavioral scenarios added (seeded from the corpus) — `tests/run-tests.sh --id <new-ids> --dry-run` lists them; capture-fires-on-prior, capture-skips-on-fact/arch/scope, consult-changes-on-governing-prior, consult-nochange-on-ungoverned-axis (B6 over-infer trap).
  - CLI: `transitions.md` gains a "Design priors (capture + consult)" subsection — `grep -q "design prior" docs/product/transitions.md` exits 0; confirm NO new F/P IDs were added.
  - [x] P4.2 Add behavioral scenarios to `tests/scenarios/product.yaml` (7 DP-* scenarios) — VALIDATED in fresh subprocess: all 7 PASS/SOFT_PASS on haiku, 0 FAIL; over-infer trap (B6) stable across 2 runs. HARD AC met. Coverage: consult-changes (cites prior), over-infer-NOCHANGE (strict-bans `PRIOR: P` firing on ungoverned axis), no-prior-90%-path, contradiction (proposes), capture-fires, capture-skips-bare-fact (strict), capture-skips-arch. Scenario-design fixes logged in Discoveries.  <!-- status: complete -->
  - [x] P4.3 Added "Design priors — consult + capture" subsection to `transitions.md` Cross-Level Mechanisms (explicit "no new transition IDs"); added design-priors Conventions bullet to `CLAUDE.md` (incl. revert pointer)  <!-- status: complete -->
  - [x] P4.4 Moved corpus draft → `docs/lessons/design-priors-corpus.md` (durable oracle; header updated from DRAFT to curated; notes it seeds the DP-* scenarios)  <!-- status: complete -->
  - [x] P4.5 Revert net: (a) tag `pre-design-priors`@9ef469d created; (b) grep enumeration confirmed clean (8 skills + 4 docs + check-structure + scenarios + 2 fixtures); (c) `## Reverting this feature` recipe written in WIP + summarized in CLAUDE.md bullet  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; check-structure 334/1 — all 33 NEW Phase-13 design-priors pins PASS (total 303→334); 7 DP-* scenarios dry-run-list + product.yaml parses (25 scenarios). The 1 FAIL is PRE-EXISTING unrelated settings-fixture drift (disableClaudeAiConnectors), SURFACED not feature-caused. -->
  - [x] verify-self  <!-- status: complete; integration boundary (check-structure + scenarios + 4 docs); subagent 6/6 PASS; correctly classified the 1 settings-FAIL as pre-existing/not-feature-caused (git status on fixture empty). Revert net confirmed (tag + grep enumeration). -->
  - [x] verify-human  <!-- status: complete; F13 operator-approved 2026-06-26 (scenario coverage comprehensive incl. the strict over-infer guard PASS×2; 1 settings-FAIL correctly out-of-scope/SURFACED; revert net satisfies the easy-revert requirement). A6 scope-add scenario judged optional, not added. -->
  - [x] verify-codify  <!-- status: complete; Phase 4's deliverable WAS the test layer — coverage complete across all 4 phases (25 design-priors structural PASS lines + 7 behavioral scenarios + fixture); no new tests needed; lone check-structure FAIL is pre-existing settings drift (not feature-caused) → no triage. ALL PHASES COMPLETE → ship. -->
  - [x] SURFACED: settings-fixture drift (disableClaudeAiConnectors) → logged to backlog as SURFACE-2026-06-26-SETTINGS-FIXTURE-DRIFT-DISABLECLAUDEAICONNECTORS  <!-- status: SURFACED (note-and-continue; pre-existing, not feature-caused; does not block ship) — logged, discovery resolved-as-surfaced -->

## Code-Quality Review — design-priors

Reviewer (code-quality-reviewer subagent) against ship commit 6542e57. Mode 3 (autopilot): 0 CRITICAL, 2 MAJOR, 3 MINOR → MAJORs+MINORs auto-backlogged (F39, no pause). Operator read-time veto: mark a finding `[DISMISSED]` here before finalize archives the WIP.

### Strengths
- Canonical-contract-in-one-place correctly executed: full contract in CLAUDE.snippet.md "Design priors (GLOBAL)"; the 9 SKILL.md + arch.md + transitions.md edits all close with a pointer — pointer-shaped, not copy-paste divergence.
- "No new transition IDs — behavior within existing states" framing is the right call, stated consistently across commit/transitions.md/arch.md/CLAUDE.md.
- `design-priors-corpus.md` oracle labels examples so the discriminant is auditable and the over-infer trap (B6) traces to a named example.
- Phase 13 pins honest about what they guard; loop-over-skills shape keeps the 6-skill capture contract from per-skill drift.
- Revert net (tag + grep recipe) is a disciplined response to a self-flagged over-noise-risk feature.

### Issues
**CRITICAL** — (none)

**MAJOR**
- [tests/scenarios/product.yaml DP-consult-*] Consult scenarios encode the correct answer in `system_prompt_extra` rather than letting the SKILL.md consult contract drive it — tests obedience more than skill-prose-driven behavior; the over-infer guard (headline anti-overfit claim) is most softened. Residual signal survives (must still emit/withhold `PRIOR: P`; strict not_contains catches over-firing) → coverage weakness, not broken. → backlogged.
- [product-roadmap, product-wbs SKILL.md] Both gained a `## Step 0` section but are NOT entry-point skills (Step-0-presence pin enumerates only the 6 entry skills) — new Step-0 headings unguarded; overloads the "Step 0 = entry-point load" convention; CLAUDE.snippet.md mapping lists them as eager-read consulters without transitions.md entry-point prose matching. → backlogged.

**MINOR**
- [check-structure.sh propose pin] Pins bare `propose` not the contract phrase `propose-never-auto-write` — weaker than its comment claims. → backlogged.
- [design-priors-corpus.md Open questions] Q1/Q2 ship as open prompts though preamble says resolved; mark RESOLVED inline. → backlogged.
- [design-priors-consult/roadmap.md fixture] Uses "Phase" (backward-compat alias) not "Milestone"; cosmetic, consistent with pre-existing fixture. → backlogged.

### Assessment
Well-built prose/schema/test feature respecting codebase disciplines; canonical-contract + per-skill-pointer is the right drift defense; "behavior-within-states, no new IDs" keeps the state machine clean; schema (inferred/corrected-why gap) is thoughtful; corpus gives real traceability. Main debt: test layer leaning on answer-bearing prompts (over-infer guard most softened) + slightly loose pins. Bounded and easy-revert-netted. Net: advances the codebase.

### If you disagree
Mark a finding `[DISMISSED]` in this section before finalize archives the WIP.

## Retrospect
- **What changed in our understanding:** The literal ask ("codify the infer-intent learning") was reframed in dialogue with the operator into something larger and more precise — a *design-priors store* (capture the operator's product-design decision principles), NOT a generic "infer intent" rule. The real target is the ~10% of product-design gaps where the operator's project-specific lean differs from the common-sense fill; the 90% common-sense path must stay untouched.
- **Assumptions that held:** A dedicated `docs/product/design-priors.md` (deterministic Step-0 load) beats both CLAUDE.md (context bloat) and the memory store (non-deterministic load). Canonical-contract-in-CLAUDE.snippet.md + per-skill pointers prevents 9-way drift. "Behavior within existing states, no new transition IDs" was the right architectural call.
- **Assumptions that were wrong:** (1) product-vision/product-arch have NO "Emit Transition" section — capture scenarios on them must assert via the SOFT_PASS content path, not a structured-ID match (cost: one scenario-design back-and-forth). (2) `[PRIOR:` as a literal in a scenario `not_contains` breaks verify.sh's BRE grep — the failure-proxy must be `PRIOR: P` (disclosure-with-slug), and strict mode must ban only the true firing-proxy, never the prior NAMES (which appear in benign "doesn't apply" reasoning). (3) product-roadmap/product-wbs/product-arch/feature-verify-human/session-reflect lacked `## Step 0` sections — consult/capture hooks were fresh insertions, and the review-quality pass flagged that overloading "Step 0" onto non-entry-point skills is a convention smell (backlogged MAJOR).
- **Approach delta:** Plan was 4 phases (schema → consult → capture → pins+scenarios+sync), executed exactly in that order. The operator added a mid-flight requirement at P3 verify-human (an easy-revert net) → became P4.5 (tag + grep recipe). The behavioral-scenarios-are-mandatory condition (P2 verify-human) was carried as a hard AC and met, though review-quality fairly flagged the scenarios test obedience more than skill-prose-driven behavior (backlogged MAJOR — the operator's own concern, independently confirmed).

## Communicate
> **Feature complete:** Design Priors has shipped. Planning skills (product-roadmap/wbs, feature-spec) now consult a per-project `docs/product/design-priors.md` to fill product-design gaps the operator's way, and six checkpoints + a session-reflect backstop propose new priors (operator reviews before write) — directional/overridable, with an over-infer guard so the 90% common-sense path is untouched. Verify via `tests/scenarios/product.yaml::DP-*` (7 behavioral scenarios) + `check-structure.sh [Phase 13]` (33 pins). Easy-revert: tag `pre-design-priors` + the `## Reverting this feature` recipe below.
>
> Requester = operator — closure notice for self-record.

## Reverting this feature

This feature is behavioral and prose-only; the operator flagged over-noise risk at P3 verify-human (2026-06-26) and required an easy revert path. Two levels:

**Full rollback (nuke everything back to before the feature):**
- `git tag pre-design-priors` points at `9ef469d` (the artifact-tracking-policy finalize commit, immediately before this feature). `git diff pre-design-priors..HEAD` shows the whole feature; `git revert` the feature's commits, or hard-reset to the tag if no later work sits on top.

**Surgical removal (remove design-priors, keep later work):**
1. `grep -rl "design prior\|design-priors\|\[PRIOR:" skills/ docs/ CLAUDE.snippet.md tests/check-structure.sh tests/scenarios/ tests/fixtures/` enumerates every insertion (scope `tests/` to those 3 subpaths — `tests/results/*.json` are gitignored run artifacts, not feature files). Expected hits: 8 skills (product-vision/roadmap/arch/wbs consult+capture; feature-spec consult+capture; feature-plan pointer-only; feature-verify-human capture; session-reflect backstop), `docs/product/arch.md` (File Schema + Revision), `docs/product/transitions.md` (Design priors mechanism subsection), `docs/lessons/design-priors-corpus.md` (the oracle — delete or keep as a historical artifact), `CLAUDE.snippet.md` ("Design priors (GLOBAL)" subsection + mapping rows), `CLAUDE.md` (Conventions bullet), `tests/check-structure.sh` (Phase 13 pins), `tests/scenarios/product.yaml` (DP-* scenarios), `tests/fixtures/product/design-priors-done/` + `design-priors-consult/`.
2. Delete the marked blocks from the 7 skills + the 2 global docs (each is a contiguous, clearly-headed section — `## Step 0`/`### 2b/3b/6b Capture`/`## Design priors (GLOBAL)`/`### File Schema: Design Priors`).
3. Drop the `[Phase 13] Design priors` block from `check-structure.sh` and the design-priors scenarios from `tests/scenarios/`; delete `tests/fixtures/product/design-priors-done/`.
4. Re-run `tests/check-structure.sh` (must return to the pre-feature pin count) + `tests/run-tests.sh` to confirm clean removal.

## Current Node
- **Path:** Feature > ship [x] > review-quality [x] > finalize
- **Active scope:** none — shipped (6542e57), review-quality complete (0 CRITICAL / 2 MAJOR / 3 MINOR, all auto-backlogged Mode-3); ready for /feature-finalize
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** SURFACE-2026-06-26-SETTINGS-FIXTURE-DRIFT-DISABLECLAUDEAICONNECTORS + 5 code-quality findings (pointer in backlog.md, full in backlog-quality-findings.md) — all note-and-continue, none block finalize

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [SURFACED-2026-06-26] Phase 2/3 — product-roadmap, product-wbs, product-arch, feature-verify-human, session-reflect lack `## Step 0` sections; consult/capture hooks are new prose insertions (not Step-0 edits) for those skills. Logged for build awareness; not a backlog item.
- [SCENARIO-LESSON-2026-06-26] Phase 4 P4.2 — three scenario-design fixes surfaced while validating in fresh subprocess: (1) `[PRIOR:` in a `not_contains`/`contains` literal breaks verify.sh's BRE `grep` ("brackets not balanced") — match `PRIOR: P` (disclosure-with-slug, the true failure-proxy) instead; (2) product-vision/product-arch have NO "Emit Transition" section, so capture scenarios on them must assert via the SOFT_PASS `contains_any` path, not `contains_required_any` (which only fires on a structured id_match those skills don't reliably produce); (3) strict `not_contains` must ban only the failure-proxy `PRIOR: P` (a real firing), NOT the prior NAMES — naming a prior while reasoning "it doesn't apply here" is correct behavior (per docs/lessons/test-scenario-strict-mode.md). Candidate generalization for that lesson doc; not separately backlogged (covered by existing lesson).

## Codify Notes
- **Phase 1 (codify deferred to Phase 4):** The schema (arch.md) + global subsection (CLAUDE.snippet.md) are not load-bearing contracts *in isolation* — they become enforceable only once Phase 2/3 wire the consult/capture blocks into skills. Writing a "schema present" Phase-13 pin now would be re-written alongside the consult/capture pins in P4.1 (the plan consolidates them), duplicating a pin against the no-duplicate discipline. Phase 1 artifacts ARE exercised: fixture parses (verify-auto + verify-self), and the existing 303-pin structural sweep ran clean against the edited docs (no regression to existing contracts). No test failures → no triage. Deferral is principled, not a skip.
