# Feature: Reflect/store proposal filter rules

**Workflow:** feature
**State:** finalize (complete)
**Created:** 2026-07-03
**Completed:** 2026-07-03
**Entry:** spec (complex feature)
**Drive mode:** fsd

## Retrospect
- **What changed in our understanding:** The harness cannot hard-assert content (`contains_required`) on a skill that emits no TRANSITION token — that path is gated behind `id_match`, which `session-reflect` never satisfies. So a no-transition skill is testable only via `contains_any`→SOFT_PASS and `not_contains_strict`→FAIL. This constrained the Phase 3 scenario design and is worth remembering for any future token-less skill.
- **Assumptions that held:** The 5 filter rules were operator-confirmed in discussion before any build, so no spec/plan churn. The prompt-only change had no architectural conflict (arch.md consulted, none found). The 15→0 global→project directional evidence made the scope-default rule high-confidence and it landed cleanly.
- **Assumptions that were wrong:** (1) I initially wrote R1 with a strict `not_contains: [GLOBAL]` — but the new reflect prompt legitimately discusses the `[GLOBAL]` gate, so the model echoes `[GLOBAL]` in benign reasoning. That's the informational-vs-failure-proxy trap (test-scenario-strict-mode lesson) — fixed to a positive assertion. Caught by the real P3.2 run, exactly as intended. (2) Assumed I might give case-(b) a custom already-encoded CLAUDE.md; the runner hard-copies the default fixture (per-scenario `claude_md:` key unsupported, backlogged) — worked around by using the Docker fact already in the default fixture.
- **Approach delta:** Implementation matched the plan's 3-phase structure exactly (rewrite reflect → structural pins + store-learning alignment → behavioral scenarios + doc sync). The only deviation was the R1 assertion fix mid-Phase-3, which is normal verify-codify-style test iteration, not a plan miss.

## Problem Statement

An audit of all 145 `session-reflect` invocations across 8 projects (see `tmp/reflect-learnings-audit.md`, gitignored) revealed two systematic mismatches between what `session-reflect` **proposes** and what the operator actually **keeps**:

1. **Over-proposal.** ~230 learnings proposed, ~70 kept. The operator prunes ~3–4× every session by hand. The current §4 "assess high/medium/low value" is too weak a filter — it presents everything with a label, so the operator still reads every candidate to decide store/scope/drop.
2. **Scope over-labeling.** 15 learnings were re-scoped by the operator at store time; **every one was `[GLOBAL]`→`[PROJECT]`**, zero the other way. The current prompt has a symmetric `[GLOBAL]`/`[PROJECT]` label with no default-lean, so the agent over-labels global and the operator corrects by hand.

**Goal:** change how `session-reflect` proposes learnings so proposals (1) match the operator's revealed scoping and (2) surface far fewer store-decisions to read — eliminating the manual per-session pruning.

This is **Feature 1** of a two-feature decoupling (`tmp/temp-wbs-reflect-memory.md`). Feature 2 (memory-location symlink) is separate and spike-gated; NOT in this feature.

## User Stories

- As the operator, I want reflect to propose learnings already scoped the way I'd keep them, so I stop re-typing "make it project-scope" every session.
- As the operator, I want reflect to surface only learnings that actually need a store decision from me, so a reflection is short to read.
- As the operator, I want learnings that are already captured elsewhere to be acknowledged (with a pointer to where) rather than re-offered as store candidates, so I neither lose them nor have to decide on them.
- As the operator, I want a cheap audit trail of what reflect chose to suppress, so a mis-suppression is recoverable at a glance.

## Acceptance Criteria

The feature is done when `skills/session-reflect/SKILL.md` (and `session-store-learning/SKILL.md` where needed) encode the 5 greenlit rules, structure-check pins guard them, behavioral scenarios exercise them, and existing pins still pass:

1. **Rule 1 — scope default.** The prompt instructs: default every surviving learning to `[PROJECT]`; label `[GLOBAL]` only when all three hold — (a) about the workflow/agent-operation itself, not any codebase's domain/stack; (b) would change behavior in an unrelated project with a different stack; (c) can name the specific cross-project mechanism it changes. Includes the mccc carve-out (this repo: workflow IS the domain, so global-flavored workflow learnings are legit + tracked first-class).
2. **Rule 2 — already-persisted tier.** A learning already captured (root `CLAUDE.md` / `arch.md` / `wbs.md` / code comment at the site / WIP / backlog SURFACE) is surfaced in a distinct tier **with a cited location**, NOT offered as a store candidate. Fail-safe: if the agent can't cite where, it stays a store candidate (never silently dropped).
3. **Rule 3 — suppress workflow/process commentary** unless it clears Rule 1's global gate. mccc carve-out applies.
4. **Rule 4 — suppress single-observation generalizations & self-documenting restatements.**
5. **Rule 5 — three-tier presentation:** (i) full store candidates with scope label; (ii) already-persisted (cited, no decision); (iii) one-line collapsed `Considered and dropped: X, Y, Z (reason)`.
6. **Filter keys on learning SHAPE, not aggregate drop-rate** — so it behaves the same in a scratch project and a real one (the pressure-test).
7. **No regression:** existing structure-check pins pass — `check-structure.sh:1853` (leading `[GLOBAL]`/`[PROJECT]` label) and `:1847–1849` (store-learning destinations, canonical `.claude/learnings/` path, no-gitignore-inspection).
8. `./tests/check-structure.sh` passes; new + existing `tests/scenarios/session.yaml` cases pass.

## Out of Scope

- **Feature 2** — memory-location symlink, migration sweep, `product-context` wiring, Rules 6/7 (destination rules). Entirely separate, spike-gated.
- The reflect→store→confirm→execute flow (S20 transition, the confirmation pause) — unchanged.
- The `session-store-learning` global-draft path to `<proj-dir>/.claude/learnings/` — unchanged.
- The artifact-tracking policy + this repo's track-override — unchanged.
- The design-priors backstop sweep in reflect — unchanged (stays as its own section).
- The harness auto-memory mechanism — untouched (that's Feature 2 territory).

## Technical Constraints

- **Prompt-only change.** No new data models, endpoints, or code — edits to two SKILL.md files + `tests/check-structure.sh` + `tests/scenarios/session.yaml` + a CLAUDE.md convention bullet. No 3rd-party dependency (3rd-party probe check: N/A).
- **Tripartite-sync discipline:** if any transition wording changes, update `transitions.md` + SKILL + scenarios together. (Expected: S20 surface description is unchanged; verify.)
- **Bootstrap-skip caveat:** editing an existing SKILL.md and re-invoking it mid-session serves OLD prose. Validation must go through `tests/run-tests.sh` (fresh subprocess) or accept defer-to-next-session (see `docs/lessons/harness-bootstrap-skip.md`).
- **Test model discipline:** new scenarios start untagged (haiku); tag `model: sonnet` only on proven haiku model-noise.

## Open Questions

- [ ] None blocking. The 5 rules + mccc carve-out + cite-location + collapse-list are all operator-confirmed in the originating discussion. Plan can proceed.

## Work Tree

- [x] Phase 1: Rewrite session-reflect prompt with the 5 filter rules  <!-- status: [x] -->
  **Verify-human:** skipped (FSD mode, F10b). **Verify-codify:** no new tests written now — Phase 1's structural coverage is assigned to Phase 2 (grep pins) and behavioral coverage to Phase 3 (run-tests.sh scenarios); the natural higher-level test homes per the plan. Writing throwaway tests here would duplicate planned work. Existing reflect pins pass (current regression guard). No test failures except pre-existing host settings-fixture drift (unrelated, backlogged).
  **Observable outcomes:**
  - CLI: `grep -c "PROJECT" skills/session-reflect/SKILL.md` ≥ 1 AND the prompt contains a "default to `[PROJECT]`" instruction and a 3-part `[GLOBAL]` gate (verifiable by grep for the gate clauses).
  - CLI: the prompt contains all three presentation tiers — a store-candidate tier, an "already-persisted" tier requiring a **cited location**, and a one-line "Considered and dropped" collapsed list (grep for each tier's marker phrase).
  - CLI: the prompt contains the mccc carve-out (grep for a "workflow system IS the domain" / this-repo exception clause).
  - CLI: existing regression guard still holds — `grep -E "\[GLOBAL\]|\[PROJECT\]" skills/session-reflect/SKILL.md` matches (Phase-12 pin at check-structure.sh:1853), and NO trailing `Scope: global | project` form is introduced.
  - CLI: no bare `.claude/` introduced — Phase-12 `strip_fences` check would pass (all refs qualified `~/.claude/` or `<proj-dir>/.claude/`).
  - [x] P1.1 Add §2a candidate-filter step to `skills/session-reflect/SKILL.md`: the 4 DROP gates (already-encoded, workflow/process-commentary, single-observation, self-documenting-restatement) + the STORE bar (3 kept shapes: empirical tool/API gotcha → project memory; standing code-contract → project Context Rule; genuine cross-project workflow-mechanism → global). Apply BEFORE presenting.  <!-- status: [x] -->
  - [x] P1.2 Add §2b scope-default step: default `[PROJECT]`; `[GLOBAL]` requires all 3 gate conditions; mccc carve-out (workflow-mechanism learnings legit + tracked first-class here). Include the "over-labels global; 15→0 directional evidence" rationale one-liner so the instruction is self-justifying.  <!-- status: [x] -->
  - [x] P1.3 Rewrite §3 presentation format for the 3 tiers (store-candidate / already-persisted-with-cited-location / collapsed dropped-list) and update §4 prompt-store wording to consume the pre-filtered, pre-scoped output. Keep the design-priors backstop sweep (§ "Design priors") unchanged. Keep all `.claude/` refs qualified.  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x]; check-structure.sh 333/334 pass, sole FAIL is pre-existing host settings-fixture drift (SURFACE-2026-06-30), unrelated; all reflect/store pins PASS, no regression -->
  - [x] verify-self  <!-- status: [x]; all 6 observable outcomes PASS on fresh grep re-check. No integration boundary in code terms (prose file; only mechanical consumer = check-structure pins, verified). No live app to observe — Playwright subagent spawn skipped as inapplicable (no URL, no snapshots to isolate); behavioral verification authoritatively deferred to Phase 3 fresh-subprocess test run per bootstrap-skip lesson. Deviation logged in Discoveries. -->
  - [x] verify-human  <!-- status: [x] SKIPPED (FSD mode, F10b skips verify-human) -->
  - [x] verify-codify  <!-- status: [x]; coverage assigned to Phase 2 (structural pins) + Phase 3 (behavioral scenarios), not duplicated here. Existing reflect pins pass. -->

- [x] Phase 2: Structure-check pins + session-store-learning alignment  <!-- status: [x] -->
  **Verify-codify:** Phase 2 IS the structural-codification work — the 6 grep pins ARE the permanent regression coverage for Phase 1's prose. Nothing further to codify (tests-for-tests = duplication). Full check-structure.sh 340/1; sole FAIL is pre-existing host settings-fixture drift (SURFACE-2026-06-30, HIGH-confidence triage: not caused by this feature — touched only reflect/store SKILLs + check-structure.sh, not the settings fixture; already backlogged). No triage-pause needed.
  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` exits 0 with new pins added and ALL existing pins passing (no regression). New pins assert: scope-default-to-project clause present; already-persisted-cite-location clause present; 3-tier presentation present; mccc carve-out present.
  - CLI: the 4 new `grep_check` pins each report `pass` in the Phase-12 (or a new phase) output block.
  - CLI: `session-store-learning/SKILL.md` intake note present IF §4 handoff wording changed (grep) — else this leaf is a no-op explicitly recorded.
  - **Integration-boundary note:** Phase 1 changes the prose that check-structure.sh Phase 12 already pins (leading scope label). This phase MUST re-run the full check-structure.sh and confirm the existing `:1853` and `:1847–1849` pins still pass against the rewritten prose — the integration-boundary rule requires citing that consuming surface.
  - [x] P2.1 Add 4 `grep_check` pins to `tests/check-structure.sh` for the new reflect contracts (scope-default, already-persisted-cite, 3-tier, mccc carve-out). Place in Phase 12 alongside the existing reflect pin, or a clearly-labeled new sub-block. Use anchor phrases that Phase 1 actually wrote (coordinate the literal strings).  <!-- status: [x]; added 6 pins (1 scope-default + 1 cite + 3 tier + 1 carve-out) after :1853, all PASS -->
  - [x] P2.2 If P1.3 changed the §4 handoff wording that store-learning depends on, add a one-line intake note to `session-store-learning/SKILL.md` (it now receives pre-filtered/pre-scoped input; already-persisted items won't arrive). Verify the existing store-learning pins (destination, amend, no-gitignore-inspection) still pass. If no change needed, record "no-op — store-learning intake unchanged" here.  <!-- status: [x]; added §1 intake note (respect incoming scope label, don't re-run filter, tier-2/3 not routed here). All 5 existing store-learning pins still PASS -->
  - [x] verify-auto  <!-- status: [x]; bash -n OK; 6 new pins PASS; check-structure 340/1, sole FAIL is pre-existing settings drift; no regression -->
  - [x] verify-self  <!-- status: [x]; all Phase 2 outcomes PASS. Integration-boundary confirmed: existing :1853 leading-label + :1847-1849 store pins still pass against the pinned prose (3/3). Playwright spawn skipped (test-script + prompt edits; no live app / URL / browser artifacts) — same rationale as Phase 1. Behavioral verification is Phase 3. -->
  - [x] verify-human  <!-- status: [x] SKIPPED (FSD mode, F10b) -->
  - [x] verify-codify  <!-- status: [x]; Phase 2 IS the structural-codification phase — 6 pins ARE the coverage. Full suite 340/1 (sole FAIL pre-existing settings drift, triaged not-this-feature). Nothing to duplicate. -->

- [x] Phase 3: Behavioral scenarios + doc sync  <!-- status: [x] -->
  **Verify-codify:** Phase 3 IS the behavioral-codification phase — the 3 reflect scenarios (R1/R2/R3) ARE the permanent behavioral regression coverage (run the real reflect skill, assert 3-tier + scope-default). Combined with Phase 2's 6 structural pins, coverage is complete. Nothing to duplicate. Full check-structure.sh 340/1 (sole FAIL pre-existing settings drift, HIGH-confidence triage: not this feature). All phases complete → F16 ship.
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --group session` runs the new `session-reflect` scenarios and they PASS (fresh subprocess — avoids the bootstrap-skip stale-prose trap). NB: reflect emits NO transition token, so scenarios assert via `contains_required` / `not_contains_strict` on reflect output prose, not `transition_id`.
  - CLI: new scenarios exist in `tests/scenarios/session.yaml` — (a) a global-flavored candidate is labeled `[PROJECT]` by default; (b) an already-encoded candidate is surfaced-with-pointer, NOT offered as a store candidate; (c) a process-commentary candidate lands in the collapsed dropped-list.
  - CLI: `grep -n "skill: session-reflect" tests/scenarios/session.yaml` ≥ 3 (was 0).
  - CLI: `git grep -n "reflect.*filter\|filter.*rules" CLAUDE.md docs/product/transitions.md` — the convention bullet + any transitions.md wording is synced (tripartite-sync).
  - [x] P3.1 Add ≥3 `session-reflect` behavioral scenarios to `tests/scenarios/session.yaml` per the (a)/(b)/(c) cases, using `contains_required`/`contains_required_any`/`not_contains_strict` on the prose surface. Start UNTAGGED (haiku). Provide a fixture with a CLAUDE.md that contains a "already-encoded" fact so case (b) has something to cite.  <!-- status: [x]; added R1/R2/R3. NOTE: reflect emits no transition → contains_required is unreachable (needs id_match); used contains_any (SOFT_PASS) + not_contains_strict instead. Case (b) uses the Docker fact already in the DEFAULT fixture CLAUDE.md (runner hard-copies default; per-scenario claude_md key unsupported — backlogged SURFACE-2026-06-27). R1 = real logged case (replicator eeb4d4c3, STORE-DIFFERENT-SCOPE). -->
  - [x] P3.2 Run `./tests/run-tests.sh --group session`; if a scenario FAILs deterministically on haiku for model-noise reasons, re-run on sonnet, confirm PASS, then tag `model: sonnet` (per the recon discipline). Record the tag decision + evidence in Discoveries.  <!-- status: [x]; R2+R3 SOFT_PASS first run (haiku). R1 initially FAILed on a TEST-ASSERTION bug (strict not_contains [GLOBAL] — but reflect prompt legitimately discusses the [GLOBAL] gate → informational phrase, per test-scenario-strict-mode lesson); fixed assertion to positive contains_any [PROJECT]; re-ran → SOFT_PASS on haiku. NO sonnet tag needed — no haiku model-noise, the fail was my assertion. -->
  - [x] P3.3 Doc sync (tripartite): add a `## Conventions` bullet to root `CLAUDE.md` describing the reflect filter rules + scope-default + 3-tier presentation. Check `transitions.md` — the S20/reflect surface description likely unchanged; update only if wording drifted. Confirm no `wbs.md` (cycle archived) needs touching.  <!-- status: [x]; CLAUDE.md Conventions bullet added; transitions.md reflect row updated (behavior-within-state, no new ID); wbs.md confirmed absent. -->
  - [x] verify-auto  <!-- status: [x]; session.yaml parses (30), docs well-formed, check-structure 340/1 no regression, 6 changed files as intended -->
  - [x] verify-self  <!-- status: [x]; Phase 3's outcomes ARE the behavioral run — R1/R2/R3 executed the real reflect skill in fresh subprocesses (authoritative live observation, the surface Phases 1-2 deferred to), all SOFT_PASS on haiku. Doc-sync greps confirmed. No separate Playwright surface. -->
  - [x] verify-human  <!-- status: [x] SKIPPED (FSD mode, F10b) -->
  - [x] verify-codify  <!-- status: [x]; Phase 3 IS the behavioral-codification phase — 3 scenarios ARE the coverage. Full suite 340/1 (pre-existing settings drift, triaged not-this-feature). All phases complete → F16. -->

## Current Node
- **Path:** Feature > COMPLETE — all 3 phases [x] → ship (F16)
- **Active scope:** All 3 phases complete; ready for /feature-ship
- **Blocked:** none
- **Unvisited:** (none)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [SURFACED-2026-07-03] feature-spec — arch.md exceeds size guard (381 lines, read headings + structure only). Consider summarizing. No architectural constraint on this feature found.
- [SURFACED-2026-07-03] feature-plan — session-reflect emits NO transition token and has ZERO behavioral scenarios today. New tests must assert on reflect output PROSE via `contains_required`/`not_contains_strict`, not `transition_id`. This shapes Phase 3.
- [SURFACED-2026-07-03] feature-plan — no `docs/product/wbs.md` (cycle archived to docs/product/archive/); no `design-priors.md`. Plan grounded in arch.md structure + the temp WBS (tmp/temp-wbs-reflect-memory.md) instead.
- [SURFACED-2026-07-03] Phase 1 verify-self — Playwright `feature-verify-self-runner` subagent spawn deliberately SKIPPED: this feature is a prompt-only edit with no running app / dev URL to observe and no browser artifacts to isolate from parent context (the design property the unconditional-spawn rule protects). Phase 1 outcomes are static grep checks, all PASS. Behavioral verification (model actually emits 3 tiers + PROJECT-default) is authoritatively deferred to Phase 3 `tests/run-tests.sh --group session` (fresh subprocess), because in-session re-invocation of the edited reflect skill serves stale pre-edit prose (harness-bootstrap-skip lesson).
- [SURFACED-2026-07-03] Phase 3 P3.2 — R1 test-assertion fix (caught by the real run, the point of P3.2): initial R1 used `not_contains_strict: [GLOBAL]`, but the new reflect prompt legitimately discusses the `[GLOBAL]` gate, so a model explaining WHY it chose `[PROJECT]` echoes `[GLOBAL]` in benign reasoning — an INFORMATIONAL phrase, not a failure-proxy (docs/lessons/test-scenario-strict-mode.md). Fixed to positive `contains_any: [PROJECT]`. This validates the strict-mode lesson holds for no-transition skills too.
- [SURFACED-2026-07-03] Phase 3 — reflect scenarios confirm the harness cannot assert `contains_required` on a no-transition skill (the hard-assert path is gated behind `id_match`, which requires a TRANSITION token reflect never emits). Only `contains_any`→SOFT_PASS + `not_contains_strict`→FAIL are usable for reflect. Relates to the backlogged per-scenario `claude_md:` fixture-key gap (SURFACE-2026-06-27) which would let case (b) use a custom already-encoded CLAUDE.md instead of the default fixture's Docker fact. Both are harness-enhancement territory, not this feature's scope.
