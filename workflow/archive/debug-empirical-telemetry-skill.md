---
workflow: feature
state: ship (complete)
created: 2026-06-10
entry: spec (complex feature)
drive_mode: autopilot
---

# Feature: debug-empirical-telemetry sidebar skill

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-10
**Entry:** spec (complex feature) → plan
**Source:** `SURFACE-2026-05-22-DEBUG-EMPIRICAL-TELEMETRY-SKILL` (workflow/backlog.md, P3)

## Plan-time question resolutions (locked, 2026-06-10)

The 7 spec-time Open Questions are resolved as follows. These are no longer questions — they are plan-locked decisions. The original Open Questions section is preserved below for traceability.

1. **Skill name:** `debug-empirical-telemetry` (working name kept). Rejected `debug-observe-runtime` (vague — doesn't signal the instrument-and-read mechanism); rejected `debug-instrument-and-observe` (too long for a slash command). "Empirical telemetry" is mildly jargon-y but evocative of the runtime-observation discipline.
2. **Gate 2 wording:** abstract criterion + non-exhaustive examples. The criterion: "the bug's cause cannot be derived from reading the code alone — it requires observing values, timing, or behavior of the running system." Examples (non-exhaustive): timing/race conditions, intermittent symptoms, DB query plans or execution timing, perf regressions, env-dependent state, "this variable has the wrong value at this line and reading the code doesn't explain why."
3. **INCONCLUSIVE threshold:** ≥3 rounds of `instrument → run → read` without a discriminating observation. Same numerical anchor as Gate 2's static-attempt count (3) — keeps the skill's gating shape consistent. After 3 rounds with no convergence, the agent calls `DEBUG-TELEMETRY-INCONCLUSIVE` and escalates to caller with suggestions for the next debugging mode.
4. **Cleanup discipline:** **Option C — both** an action list AND a pre-exit written checklist. The action list covers categories of instrumentation to remove (print/log statements, timing counters, ad-hoc breakpoints, restored log levels, deleted scratch files). The written checklist is a 1–3-line post-condition the agent commits before emitting any `RETURN-TO:` token (mirrors bisect's `Bisect runner removed; cause was V_<i>.` pattern).
5. **Test scenario count:** 4 total — 1 gates-met (procedure activates), 2 SKIPs (one per gate), 1 INCONCLUSIVE-shaped scenario optional but **deferred to Phase 3** as a stretch. Phase 3 ships minimum-3, expands to 4 if scenario design is tractable.
6. **`workflow/wip/debug-<slug>.md` for long sessions:** include as an **optional clause** in the skill's `## Procedure` (mirrors bisect's "For long bisects (5+ iterations): consider writing iteration notes…"). Same threshold (≥5 iterations). Plan-locked: optional, not required.
7. **Phase 3c extension count:** 7 new assertions confirmed — 3 caller-prose mentions + 3 orchestrator-row presence checks + 1 transitions.md mention. Expected new baseline: 141 → 148 PASS.

## Problem Statement

Agents default to **static-analysis debugging** — read code, build a mental model, propose a fix — even when the bug shape demands **runtime evidence**. Bug categories where static reasoning cannot converge include: race conditions, timing-sensitive failures, environment-dependent state, DB query plans, intermittent failures, performance regressions, and "this variable is somehow the wrong value at this line." Without an explicit prompt to switch modes, the agent loops on the static approach long after it has demonstrably failed — burning wall-clock and increasing the chance of a guessed-fix-that-ships-broken.

The workflow harness already codified one stall-recovery sidebar (`debug-bisect-known-good`, 2026-05-13) for a different stall shape: when a known-good sibling exists and straight-line debug has stalled, walk one-variable-at-a-time from the working path to the broken one. The empirical-telemetry shape is the **next member** of the `debug-*` family — same agent-pulled-sidebar architecture, different trigger profile and procedure.

This is not a hypothetical gap. The "static-analysis loop" failure mode has bitten in this repo's own work (e.g. 2026-06-09 `tests/run-all.sh` `set -o pipefail` + `SIGPIPE` interaction was localizable only by running the script and reading what actually happened — code-reading produced wrong hypotheses across multiple attempts). A codified trigger gate + instrumentation playbook + cleanup discipline turns an ad-hoc lesson into a reachable harness primitive.

## User Stories

- **As an agent mid-`feature-build`,** when I have failed ≥2–3 static-reasoning fix attempts on the same bug AND the bug involves a runtime value I cannot derive from code alone, I want a sidebar skill I can invoke to switch into empirical mode — so I stop thrashing and start observing.
- **As an agent in `incident-investigate`** facing an intermittent or timing-sensitive failure, I want a sidebar that walks me through smallest-discriminating-observable → instrument → run → read → iterate, so I produce evidence-backed findings instead of speculative ones.
- **As an agent in `task-act`** debugging a "the test says it's broken but the code looks right" failure, I want a skill that forces a runtime check before I propose another code edit.
- **As the user reviewing a fix,** I want stray instrumentation (debug prints, timing counters, ad-hoc logging) removed or explicitly guarded before commit, so empirical work doesn't pollute committed code.
- **As an agent who has already converged via empirical evidence,** I want a clean `RETURN-TO: <caller>` hand-off so my caller workflow state resumes with the cause in hand and applies the fix at the right surface.

## Acceptance Criteria

The feature is done when:

1. **`skills/debug-empirical-telemetry/SKILL.md` exists** with all six required `debug-*` sections (`## Category Context`, `## When to use`, `## When NOT to use`, `## Procedure` containing a `### 1. Gate Check`, `## Pitfalls`, `## Termination`).
2. **Trigger gate is conjunctive (AND, not OR)** and documented in both `## When to use` and the `### 1. Gate Check`. Both gates required:
   - Gate 1: ≥2–3 failed static-analysis fix attempts on the same bug (the "stall" precondition).
   - Gate 2: bug-shape involves a runtime value the agent cannot derive from code alone — non-exhaustive list: timing/race, DB query plan or timing, intermittent symptom, perf regression, env-dependent state, "variable has the wrong value at this line and I can't reason out why from reading."
3. **Procedure encodes the empirical playbook** with these load-bearing steps in order:
   - Gate Check (emits `DEBUG-TELEMETRY-SKIP` + `RETURN-TO:` on failure, stops).
   - Pick the smallest observable that would discriminate current hypotheses (not the most instrumentation — the most decisive single observation).
   - Instrument (log line / timing / counter / EXPLAIN / stack dump / breakpoint trace — whatever the smallest observable requires).
   - Run the affected path and read the telemetry.
   - Decide: cause located (proceed to cleanup) | inconclusive (iterate with a different observable) | gates no longer hold (escalate).
   - Cleanup: remove or guard instrumentation before exit. Cleanup discipline is explicit, not implicit.
4. **Termination tokens** follow the `DEBUG-<TECHNIQUE>-<OUTCOME>` namespace and include at minimum: `DEBUG-TELEMETRY-START`, `DEBUG-TELEMETRY-SKIP`, `DEBUG-TELEMETRY-COMPLETE`, `DEBUG-TELEMETRY-INCONCLUSIVE`. Every termination emits a `RETURN-TO: <caller>` line.
5. **Three discoverability surfaces are wired** (per the "new skill category needs three structurally-enforced discoverability surfaces" lesson in `CLAUDE.md`):
   - Caller-skill prose mention in each of `skills/feature-build/SKILL.md`, `skills/incident-investigate/SKILL.md`, and `skills/task-act/SKILL.md` (sibling to the existing `debug-bisect-known-good` mention, in each skill's `### Xb. Debug-technique Sidebar (optional)` section).
   - Row in the "Debug techniques (agent-pulled sidebars)" subsection of each relevant orchestrator's AGENTS.md (`agents/feature-workflow/AGENTS.md`, `agents/incident-workflow/AGENTS.md`, `agents/task-workflow/AGENTS.md`).
   - Mention in `docs/product/transitions.md` → "Sidebar skills (`debug-*` category)" alongside the existing `/debug-bisect-known-good` example.
6. **Structural test coverage extends Phase 3c** of `tests/check-structure.sh` to assert all three discoverability surfaces for the new skill (caller-prose mentions in 3 callers + orchestrator-row in 3 AGENTS.md + transitions.md mention). Phase 3b's `## When to use` / `## When NOT to use` grep already covers the new skill automatically (it iterates `skills/debug-*/SKILL.md`).
7. **Test scenarios exist** in `tests/scenarios/debug.yaml` covering at minimum:
   - Gates-met fixture → procedure activates (asserts `DEBUG-TELEMETRY-START`).
   - Gate-1-fails fixture (only 1 static attempt) → SKIP (asserts `DEBUG-TELEMETRY-SKIP`).
   - Gate-2-fails fixture (static-derivable bug shape, e.g. typo in literal string) → SKIP.
   - At least one scenario covers each Gate's failure path separately (mirrors the existing `DEBUG-BISECT-NO-KNOWN-GOOD` + `DEBUG-BISECT-INSUFFICIENT-ATTEMPTS` pair).
8. **`install.sh` picks up the new skill directory automatically** (it iterates `skills/*/`); a re-run creates the symlink without manual edits. Verified by running `./install.sh` post-implementation.
9. **`./tests/check-structure.sh` returns the new pin-count PASS** (current baseline 141; expected new pin-count = 141 + N where N is the count of new Phase 3c assertions added — likely 7: 3 caller-prose + 3 orchestrator-row + 1 transitions.md).
10. **The new scenarios run cleanly** under both the haiku and sonnet partitions (`./tests/run-tests.sh --group debug --model haiku` and `--model sonnet`). Gates-met scenarios may be tagged `model: sonnet` post-recon **only if** haiku is shown to be empirically noisy (per the CLAUDE.md "new tests start untagged" discipline).

## Out of Scope

- **No changes to `debug-bisect-known-good`.** The new skill is a sibling member of the `debug-*` family, not a refactor of the existing one. The two skills have different trigger profiles, different procedures, and serve different stall shapes. They coexist.
- **No new F/I/T transition IDs.** Sidebars don't consume transition IDs (per the `debug-*` category convention codified 2026-05-13). The new skill emits `DEBUG-TELEMETRY-*` tokens and a `RETURN-TO:` line; the caller's state machine is unchanged.
- **No changes to pause-policy tables.** Sidebars don't appear in any orchestrator's pause-policy table (same reason as above).
- **No instrumentation library or telemetry framework.** The skill is procedural guidance, not infrastructure. It tells the agent what kind of observation to add (log line, counter, timing, EXPLAIN) without prescribing a specific tool or library — the agent picks per the language/runtime in front of it.
- **No automatic cleanup tooling.** Cleanup is procedural discipline within the skill, not a hook or a CI check that scans for leftover prints. The skill prose makes cleanup explicit; mechanical enforcement is out of scope (and arguably a separate, future feature).
- **No new debugger-specific category** (e.g. no `debug-`-renamed subcategory like `debug-runtime-`). The single `debug-*` namespace is sufficient; further subdivision adds friction without value at current cardinality (2 skills).
- **No changes to `feature-spec`, `feature-research`, `feature-plan`, `feature-verify-*`, or `feature-finalize` SKILL.md files.** Empirical telemetry is a build/investigate/act-time technique. Adding it to spec/plan/finalize would dilute the trigger profile.
- **No port to product-workflow skills.** Product workflow is strategic decomposition, not implementation; runtime evidence is not the failure mode there.

## Technical Constraints

- **Sidebar architecture is fixed** (codified 2026-05-13 in `docs/product/transitions.md` → "Sidebar skills (`debug-*` category)" and `CLAUDE.md` → "`debug-*` Skill Category"). The new skill MUST follow it: no new transition IDs, no pause-policy entry, `RETURN-TO:` line on every termination, agent-pulled invocation only.
- **Six required SKILL.md sections** (`## Category Context`, `## When to use`, `## When NOT to use`, `## Procedure` with Gate Check first, `## Pitfalls`, `## Termination`) are enforced by `tests/check-structure.sh` Phase 3b. The first three regex-match against `^## ...$` headers; Gate Check is implicit-required-by-convention rather than grep-enforced today, but the existing `debug-bisect-known-good` precedent must be followed structurally.
- **Three discoverability surfaces** (caller-prose, orchestrator-rows, transitions.md mention) are enforced by `tests/check-structure.sh` Phase 3c. Currently Phase 3c hard-codes assertions for `debug-bisect-known-good` only — the new skill requires Phase 3c **extension**, not a rewrite. Pattern: copy the existing 3-caller-prose + 3-orchestrator-subsection assertions, adapt to the new skill name.
- **`install.sh` idempotency.** A new top-level `skills/debug-empirical-telemetry/` directory is automatically picked up — no manual install-script edits required.
- **Skill prompt-shape parity with `debug-bisect-known-good`.** The new skill's frontmatter, `argument-hint`, and termination-block table format must mirror the existing precedent for consistency (and so future agents recognize the family).
- **Test scenario assertion shape.** Entry-state scenarios (gates-met → procedure activates) should follow the precedent of `DEBUG-BISECT-GATE-MET`: assert `transition_id: DEBUG-TELEMETRY-START` + `contains_any` for procedure-anchor phrases, **without** aggressive `not_contains` constraints (per CLAUDE.md "Entry-state transitions need a different test shape than exit transitions"). SKIP scenarios may use `not_contains: [DEBUG-TELEMETRY-START, DEBUG-TELEMETRY-COMPLETE]` since those are unambiguous downstream-path tokens.
- **No 3rd-party dependencies.** Pure markdown + shell test extension. No probe WP needed.
- **Backlog hygiene.** On feature-finalize, the P3 backlog entry (`SURFACE-2026-05-22-DEBUG-EMPIRICAL-TELEMETRY-SKILL`) is resolved → `**Backlog resolved:**` entry in `CHANGELOG.md`, backlog entry removed (per the project's CHANGELOG convention).

## Open Questions

All questions below have load-bearing-enough answers to NOT block planning — captured as questions to be resolved in the plan. None requires research-skill investigation (no unknowns about unfamiliar tech, no external integration, no architectural shift). Spec exit is F4 → plan.

- [ ] **Skill name finalization.** Working name is `debug-empirical-telemetry`. Alternative considered: `debug-observe-runtime`, `debug-instrument-and-observe`. "Empirical telemetry" is the most evocative but borderline-jargon. Plan-time decision; can settle in the WBS or first phase. Default if unresolved: `debug-empirical-telemetry`.
- [ ] **Exact wording of Gate 2 (runtime-value-required bug shape).** Candidates: enumerated list (timing/race/DB-plan/intermittent/perf/env-dependent/wrong-value-at-line), abstract criterion ("the bug's cause cannot be derived from reading the code without observing the running system"), or both. Likely both — abstract definition + non-exhaustive examples. Resolved at plan time.
- [ ] **How many "smallest observable" iterations are reasonable before declaring INCONCLUSIVE?** Bisect's `DEBUG-BISECT-NO-CONVERGE` is reached after "all enumerated variables walked + wrapper escalation tried." Telemetry doesn't have an analogous bounded enumeration. Candidate: "≥3 rounds of instrument→run→read without converging on a hypothesis-discriminating observation" — same numerical anchor as Gate 2's static-attempt count. Or: no fixed number, agent calls inconclusive when it can articulate why further observation won't discriminate. Resolve at plan time.
- [ ] **Cleanup discipline shape.** Options:
  - **A.** Procedural section listing actions (remove print statements; remove commented-out instrumentation; restore log levels; remove temporary timing counters).
  - **B.** A pre-exit checklist the agent fills in writing (mirrors `debug-bisect`'s `Bisect runner removed; cause was V_<i>.` post-condition).
  - **C.** Both — actions list + written checklist.
  - Likely **C**. Plan-time choice.
- [ ] **Test scenario count for SKIP paths.** Bisect ships with 2 SKIP scenarios (one per gate). Telemetry has the same gate structure (2 gates) and should probably also ship 2 SKIPs. Possibly a 3rd for the INCONCLUSIVE path if writeable. Resolve at plan time.
- [ ] **Should the new skill optionally instruct logging to `workflow/wip/debug-<short-slug>.md` for long telemetry sessions?** Bisect mentions this as optional for ≥5 iterations. Telemetry sessions can run long too. Likely same optional shape. Plan-time decision.
- [ ] **Phase 3c extension shape.** Likely 7 new assertions: 3 caller-prose + 3 orchestrator-row + 1 transitions.md. Final count fixed at plan time once skill name is locked and orchestrator-row wording is drafted.

## Backlog reference

This feature resolves **`SURFACE-2026-05-22-DEBUG-EMPIRICAL-TELEMETRY-SKILL`** (workflow/backlog.md, P3, medium). On `/feature-finalize`, that entry is removed from backlog and logged as `**Backlog resolved:**` in CHANGELOG.md per project convention.

## Work Tree

- [x] Phase 1: Author the `debug-empirical-telemetry` SKILL.md  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `ls skills/debug-empirical-telemetry/SKILL.md` exits 0 and the file is non-empty.
  - CLI: `grep -cE '^## (Category Context|When to use|When NOT to use|Procedure|Pitfalls|Termination)' skills/debug-empirical-telemetry/SKILL.md` returns `6` (regex matches `## Pitfalls (load-bearing — read before instrumenting)` shape — same convention as `debug-bisect-known-good`).
  - CLI: `grep -cE '^### 1\. Gate Check' skills/debug-empirical-telemetry/SKILL.md` returns ≥1 (Gate Check is the first `### ` subheading under `## Procedure`).
  - CLI: `grep -cE 'DEBUG-TELEMETRY-(START|SKIP|COMPLETE|INCONCLUSIVE)' skills/debug-empirical-telemetry/SKILL.md` returns ≥4 (all four termination tokens documented in the `## Termination` table).
  - CLI: `grep -cE '^RETURN-TO:' skills/debug-empirical-telemetry/SKILL.md` returns ≥1 (the `RETURN-TO:` convention is documented in `## Termination`).
  - CLI: `grep -c 'argument-hint:' skills/debug-empirical-telemetry/SKILL.md` returns 1 (frontmatter parity with `debug-bisect-known-good`).
  - CLI: `test -L ~/.claude/skills/debug-empirical-telemetry` exits 0 (install.sh picked up the new directory).
  - [x] P1.1 Create `skills/debug-empirical-telemetry/SKILL.md` with frontmatter (`name`, `description`, `argument-hint`) mirroring `debug-bisect-known-good`'s shape. The `name:` value must match the directory exactly.
  - [x] P1.2 Author `## Category Context` (1 paragraph confirming sidebar-not-state, naming caller skills: `feature-build`, `incident-investigate`, `task-act`).
  - [x] P1.3 Author `## When to use` with **both** conjunctive gates (Gate 1: ≥2–3 failed static-analysis attempts on the same bug; Gate 2: bug-shape requires runtime evidence — abstract criterion + 6 example categories per plan-resolution #2). Marked with explicit "AND, not OR" language matching bisect's precedent.
  - [x] P1.4 Author `## When NOT to use` with 5 explicit non-applicability conditions (static-derivable; no straight-line debug attempted yet; cause already known from prior failed-fix; runtime unobservable without major scaffolding; known-good sibling exists → use bisect instead).
  - [x] P1.5 Author `## Procedure` with 7 subsections in spec'd order (Gate Check; Smallest discriminating observable; Instrument; Run and read; Decide; Cleanup; Inconclusive escalation).
  - [x] P1.6 Author `## Pitfalls (load-bearing — read before instrumenting)` with 6 failure modes (instrument too much; skip the read; leave instrumentation; infer beyond observation; over-iterate past gates; treat wire-level success as symptom-resolved). Heading uses parenthetical suffix matching `debug-bisect-known-good`'s convention.
  - [x] P1.7 Author `## Termination` table with 4 tokens. Includes RETURN-TO convention + optional `workflow/wip/debug-<slug>.md` ≥5-iteration clause + sidebar-discipline note.
  - [x] P1.8 Re-ran `./install.sh`; `~/.claude/skills/debug-empirical-telemetry` symlink confirmed.
  - [x] verify-auto  <!-- all 9 scoped checks PASS: file presence, 6 required sections, Gate Check first, 4 termination tokens, RETURN-TO, argument-hint, symlink, name=dir, frontmatter delimiters. Phase 3b auto-pick-up confirmed: both gate-boundary assertions PASS. -->
  - [x] verify-self  <!-- No integration boundary — phase adds isolated new artifacts only (new skill directory, no modification to existing endpoints/UI/CLI/jobs). No dev-URL applicable. Live-system check ran 9 outcomes against the SYMLINKED path (~/.claude/skills/debug-empirical-telemetry/SKILL.md) to confirm what future skill invocations actually load: all 9 PASS. Symlink resolves correctly to source (no copy drift). check-structure.sh Phase 3b auto-picks up new skill — both gate-boundary assertions PASS. -->
  - [x] verify-human  <!-- AUTO-SKIPPED per autopilot mode. All 4 gates clean: (a) drive_mode=autopilot from WIP frontmatter; (b) verify-self all-PASS (9/9 outcomes); (c) no integration boundary — only adds new skills/debug-empirical-telemetry/ directory + symlink; (d) no Observable Outcome cites a consuming surface this phase touches. Affirmation block printed in chat for operator read-time veto. -->
  - [x] verify-codify  <!-- ./tests/check-structure.sh: 143 PASS / 0 FAIL (was 141; new skill auto-added Phase 3b's 2 gate-boundary assertions via iterating loop). No test failures, no triage required. Phase 3b already pins the highest-signal regression channel for this skill (gate-boundary headings); other within-skill pins (file existence in loop, all 6 sections, 4 termination tokens, argument-hint, Gate Check first) are not pinned per the existing debug-* convention — surfaced to ## Discoveries as a Phase 3 scope-expansion candidate. -->

- [x] Phase 2: Wire the three discoverability surfaces  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -c '/debug-empirical-telemetry' skills/feature-build/SKILL.md` returns ≥1.
  - CLI: `grep -c '/debug-empirical-telemetry' skills/incident-investigate/SKILL.md` returns ≥1.
  - CLI: `grep -c '/debug-empirical-telemetry' skills/task-act/SKILL.md` returns ≥1.
  - CLI: `grep -c 'debug-empirical-telemetry' agents/feature-workflow/AGENTS.md` returns ≥1, AND the match falls inside the "Debug techniques (agent-pulled sidebars)" subsection.
  - CLI: `grep -c 'debug-empirical-telemetry' agents/incident-workflow/AGENTS.md` returns ≥1 (same subsection check).
  - CLI: `grep -c 'debug-empirical-telemetry' agents/task-workflow/AGENTS.md` returns ≥1 (same subsection check).
  - CLI: `grep -c 'debug-empirical-telemetry' docs/product/transitions.md` returns ≥1, AND the match falls inside the "Sidebar skills (`debug-*` category)" subsection.
  - [x] P2.1 Added sibling paragraph to `skills/feature-build/SKILL.md` §4b after the existing bisect mention. New paragraph names `/debug-empirical-telemetry`, its trigger (≥2–3 failed static-reasoning attempts AND runtime-value-required bug shape with 6 example categories), and the `RETURN-TO: feature-build` same-state contract.
  - [x] P2.2 Added the same sibling paragraph to `skills/incident-investigate/SKILL.md` §3b — incident-flavored wording ("incident-shape demands runtime evidence...in production").
  - [x] P2.3 Added the same sibling paragraph to `skills/task-act/SKILL.md` §3b.
  - [x] P2.4 Added row to `agents/feature-workflow/AGENTS.md` "Debug techniques (agent-pulled sidebars)" subsection table — line 188, immediately after the bisect row.
  - [x] P2.5 Added row to `agents/incident-workflow/AGENTS.md` same subsection — line 122.
  - [x] P2.6 Added row to `agents/task-workflow/AGENTS.md` same subsection — line 98.
  - [x] P2.7 Extended the "Examples:" sentence in `docs/product/transitions.md` → "Sidebar skills (`debug-*` category)" subsection (line 202) to name `/debug-empirical-telemetry` alongside `/debug-bisect-known-good` with 1-line trigger-shape summaries for both.
  - [x] verify-auto  <!-- All 5 scoped check groups PASS: (1) 7 observable outcomes (greps) PASS in target files; (2) markdown code fences balanced in all 7 edited files; (3) original debug-bisect-known-good mentions preserved (additive edits, no overwrites); (4) SKILL.md frontmatter delimiters intact; (5) ./tests/check-structure.sh: 143 PASS / 0 FAIL (no regression). -->
  - [x] verify-self  <!-- No integration boundary (5-condition check failed): no HTTP endpoint, no UI page, no CLI command, no scheduled job, no external-call modification. Phase 2 adds isolated additive content inside existing markdown files. Live-system observation ran 6 outcomes against the SYMLINKED paths (~/.claude/skills/feature-build|incident-investigate|task-act/SKILL.md and ~/.claude/agents/{feature,incident,task}-workflow/AGENTS.md) + 1 against the repo-only transitions.md: all 7 PASS. Subsection-scoped consistency check confirmed each orchestrator row lands inside the right "Debug techniques (agent-pulled sidebars)" subsection. All 6 symlinks resolve to source (no copy drift). check-structure.sh 143 PASS / 0 FAIL. -->
  - [x] verify-human  <!-- AUTO-SKIPPED per autopilot mode. All 4 gates clean: (a) drive_mode=autopilot; (b) verify-self all-PASS (7/7 outcomes); (c) no integration boundary — only adds additive content inside existing markdown files (no HTTP/UI/CLI/job/external modification); (d) no Observable Outcome cites a consuming surface this phase modifies. Affirmation block printed in chat for operator read-time veto. -->
  - [x] verify-codify  <!-- ./tests/check-structure.sh: 143 PASS / 0 FAIL (no regression from Phase 2's 7 additive edits). All 7 Phase 2 deliverables have NO existing coverage today, but Phase 3.1 (immediately next in autopilot) is explicitly scoped to add the 7 grep_check assertions that pin these surfaces. Codification deferred to Phase 3.1 to avoid duplication with the plan's already-scoped work. -->

- [x] Phase 3: Extend `tests/check-structure.sh` Phase 3c + add `tests/scenarios/debug.yaml` scenarios  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` exits 0 and reports **150** PASS (143 → 150 = +7 new Phase 3c assertions for the new skill). Plan estimated 148 (from 141 baseline) but Phase 1's `for debug_skill in skills/debug-*/SKILL.md` iterating loop auto-added 2 baseline counts; effective math: 141 + 2 (Phase 1 auto-iterate) + 7 (Phase 3.1 explicit pins) = 150.
  - CLI: `grep -c 'debug-empirical-telemetry' tests/check-structure.sh` returns ≥1 (Phase 3c extended).
  - CLI: `grep -c '^  - id: DEBUG-TELEMETRY-' tests/scenarios/debug.yaml` returns ≥3 (minimum: gates-met + 2 SKIPs).
  - CLI: `./tests/run-tests.sh --group debug --filter-model default` runs without errors, all DEBUG-TELEMETRY scenarios PASS or SOFT_PASS on haiku (the `filter-model default` flag matches the new untagged scenarios; per CLAUDE.md "new tests start untagged").
  - CLI: at least one fixture file exists per new scenario under `tests/fixtures/wip/` (mirrors the `debug-bisect-gates-met.md` / `debug-bisect-insufficient-attempts.md` / `debug-bisect-no-known-good.md` pattern).
  - [x] P3.1 Extended `tests/check-structure.sh` Phase 3c with 7 new `grep_check` calls: 3 caller-prose (feature-build/incident-investigate/task-act) + 3 orchestrator-row (feature-workflow/incident-workflow/task-workflow AGENTS.md) + 1 transitions.md mention. Structural test goes from 143 → 150 PASS.
  - [x] P3.2 Authored `tests/fixtures/wip/debug-empirical-telemetry-gates-met.md` — race condition in `processQueue()` worker; 3 failed static attempts; bug-shape clearly timing/race (not derivable from reading code).
  - [x] P3.3 Authored `tests/fixtures/wip/debug-empirical-telemetry-gate1-fails.md` — only 1 static attempt so far (GET /api/users/12345 KeyError); Gate 1 fails.
  - [x] P3.4 Authored `tests/fixtures/wip/debug-empirical-telemetry-gate2-fails.md` — literal 1-character typo (`config["emial"]`); fully static-derivable; Gate 2 fails.
  - [x] P3.5 Added 3 scenarios to `tests/scenarios/debug.yaml`: DEBUG-TELEMETRY-GATE-MET (asserts DEBUG-TELEMETRY-START + procedure-anchor contains_any); DEBUG-TELEMETRY-INSUFFICIENT-ATTEMPTS (asserts DEBUG-TELEMETRY-SKIP + Gate-1 contains_any); DEBUG-TELEMETRY-STATIC-DERIVABLE (asserts DEBUG-TELEMETRY-SKIP + Gate-2 contains_any). Per CLAUDE.md guidance, no aggressive `not_contains` on entry-state GATE-MET.
  - [x] P3.6 Ran `./tests/run-tests.sh --id DEBUG-TELEMETRY-GATE-MET,DEBUG-TELEMETRY-INSUFFICIENT-ATTEMPTS,DEBUG-TELEMETRY-STATIC-DERIVABLE` (haiku, 33s, $0.18). **3/3 PASS strictly on haiku** — no SOFT_PASS, no FAIL, no sonnet tagging needed.
  - [x] P3.7 (stretch — deferred) Decision: skip the DEBUG-TELEMETRY-INCONCLUSIVE scenario for this feature. Reasoning: the INCONCLUSIVE path is structurally hard to test from a fixture — it requires simulating "the agent has already done 3 rounds of telemetry and none discriminated," which (a) is hard to convey without embedding telemetry results in the fixture itself, and (b) is the kind of scenario where the model tends to suggest more telemetry rounds rather than escalating. Surfaced as a follow-up backlog candidate (low priority); the 3 PASSing scenarios cover the 3 main paths (procedure activates + Gate-1 SKIP + Gate-2 SKIP).
  - [x] P3.8 Final `./tests/check-structure.sh`: **150 PASS / 0 FAIL.** All assertions green, no regression.
  - [x] verify-auto  <!-- 6 scoped checks PASS: (1) check-structure.sh shell syntax valid; (2) debug.yaml YAML parses, 6 scenarios total; (3) 3 fixture files non-empty; (4) 3 new DEBUG-TELEMETRY scenarios in debug.yaml; (5) check-structure.sh extension grep returns 5 matches; (6) full structural test 150 PASS / 0 FAIL. -->
  - [x] verify-self  <!-- INTEGRATION BOUNDARY: Phase 3 modifies/creates files consumed by ./tests/check-structure.sh and ./tests/run-tests.sh (both CLI commands). Both consuming surfaces cited by Phase 3 Observable Outcomes. Fresh live-system invocation: (1) ./tests/check-structure.sh → 150 PASS / 0 FAIL; (2) ./tests/run-tests.sh --id DEBUG-TELEMETRY-{GATE-MET,INSUFFICIENT-ATTEMPTS,STATIC-DERIVABLE} → 3 PASS / 0 SOFT_PASS / 0 FAIL / 0 FLAKY (haiku, 39s, $0.10). Second invocation of run-tests against these scenarios (first was P3.6); both runs strict PASS → no flakiness, deterministic behavior. -->
  - [x] verify-human  <!-- Human approved 2026-06-10 ("looks good"). Integration boundary present (CLI command #3); F11 skip forbidden. All 3 sub-leaves [x]. -->
    - [x] P3.verify-human.1: Review the captured ./tests/check-structure.sh response (150 PASS / 0 FAIL) — confirmed the 7 new Phase 3c assertions reflected in the +7 PASS delta (143 → 150).
    - [x] P3.verify-human.2: Review the captured ./tests/run-tests.sh response (3 PASS / 0 SOFT_PASS / 0 FAIL on haiku) — confirmed all 3 new DEBUG-TELEMETRY scenarios passed strictly without sonnet retry.
    - [x] P3.verify-human.3: Approved — consuming-surface evidence sufficient; both CLIs returned expected post-change behavior, no regression to existing assertions.
  - [x] verify-codify  <!-- Final regression suite: ./tests/check-structure.sh 150 PASS / 0 FAIL; ./tests/run-tests.sh --group debug --filter-model default → 5 PASS + 1 FLAKY (passed on retry) + 0 SOFT + 0 FAIL / 6 total. The FLAKY hit was the pre-existing DEBUG-BISECT-GATE-MET scenario (output-shape pattern documented in SURFACE-2026-06-09-F16-TRIAGE-AMBIGUOUS-FLAKY-SOFT-PASS-ON-SONNET, not related to this feature). All 3 new DEBUG-TELEMETRY scenarios PASSed strictly on first attempt. Test Triage block written for the FLAKY scenario; no modification action per the triage rule (passed on retry, unrelated infrastructure). No new tests to write — Phase 3's deliverable IS the codification work. -->

## Current Node
- **Path:** Feature > (all phases complete) > ship
- **Active scope:** Ship — all 3 phases (P1/P2/P3) marked [x]; final regression check PASS; ready for /feature-ship.
- **Blocked:** none
- **Unvisited:** /feature-ship → /feature-finalize.
- **Open discoveries:** 2 entries — within-skill structural pins (low priority, P3-scope-expansion-deferred) + DEBUG-TELEMETRY-INCONCLUSIVE scenario coverage (low priority, follow-up backlog candidate).

## Retrospect

- **What changed in our understanding:** Surprisingly little. The feature shipped with no plan revisions, no F12/F22/F23 back-loops, no F26 escalations, no triage on this feature's own scenarios. The plan's 3-phase structure (author SKILL.md → wire 3 discoverability surfaces → codify with 7 pins + 3 scenarios) mapped 1:1 onto the implementation. The "new skill category needs three discoverability surfaces" lesson from CLAUDE.md (codified 2026-05-14 during the original `debug-*` category feature) was load-bearing — without it, Phase 2's 3-surface checklist would have been ad-hoc. The discipline of mirroring `debug-bisect-known-good`'s precedent shape paid off across SKILL.md sections, fixture structure, scenario assertion-shape, and Phase 3c grep patterns.
- **Assumptions that held:** (1) Phase 1's SKILL.md would PASS Phase 3b structural assertions automatically via the iterating loop (it did — `[PASS] debug-empirical-telemetry has '## When to use' / '## When NOT to use'`). (2) Phase 2's 7 additive edits would not regress any existing structural pin (143 PASS held before and after Phase 2's edits). (3) Phase 3's 3 new scenarios would PASS strictly on haiku without requiring sonnet tagging (they did — all 3 strict-PASS, 33s on first run, 39s on the verify-self re-run, 76s on the full-group sweep with retry; deterministic). (4) The auto-skip gate in verify-human would correctly identify the no-integration-boundary phases (it did for P1 and P2; correctly DID NOT for P3 where tests/check-structure.sh and tests/run-tests.sh are CLI consuming surfaces).
- **Assumptions that were wrong:** Only one minor calibration miss. The plan's Phase 1 observable-outcome regex `^## (Category Context|...|Pitfalls|Termination)$` was anchored at `$`, but the `debug-bisect-known-good` precedent uses `## Pitfalls (load-bearing — read before iterating)` with a parenthetical suffix that doesn't match the anchored form. I caught this at verify-auto and relaxed the regex to match the established convention. Net cost: 1 small WIP-side edit, no impl rework. Not a real surprise — the precedent doc was unambiguous; the plan was just slightly stricter than reality.
- **Approach delta:** None of substance. The 22 impl leaves (8 in P1 + 7 in P2 + 8 in P3) landed in plan-order without scope flex. The one decision deviation: P3.7 (the DEBUG-TELEMETRY-INCONCLUSIVE stretch scenario) was deferred at impl time rather than attempted-and-skipped, surfaced explicitly as a follow-up backlog item per the plan's "drop if scenario design is intractable" clause. The Phase 3 verify-codify hit a FLAKY-on-retry on the PRE-EXISTING `DEBUG-BISECT-GATE-MET` scenario (output-shape pattern documented in `SURFACE-2026-06-09-F16-TRIAGE-AMBIGUOUS-FLAKY-SOFT-PASS-ON-SONNET`); triaged as unrelated-infrastructure, no action.

## Communicate

> **Feature complete:** `debug-empirical-telemetry` has shipped — a new agent-pulled debug sidebar that switches the agent from static-analysis debugging to empirical runtime observation (instrument → run → read telemetry → iterate or escalate). Triggered when ≥2–3 static-reasoning attempts have failed AND the bug-shape requires runtime evidence (timing/race, intermittent, DB query plan/timing, perf regression, env-dependent state, "wrong value at this line"). Verify by running `/debug-empirical-telemetry <bug description>` from inside `feature-build`, `incident-investigate`, or `task-act` when both gates hold — or directly when triaging an empirical-shaped bug.

Requester = operator — closure notice for self-record.

## Test Triage — DEBUG-BISECT-GATE-MET (Phase 3 verify-codify, 2026-06-10)
Classification: Flaky test — failure unrelated to new code; inconsistent across runs (haiku skipped the literal `TRANSITION: DEBUG-BISECT-START` line on attempt 1, emitted it on attempt 2).
Confidence: high — exactly one plausible explanation: the model output-shape issue (literal TRANSITION line occasionally elided) documented in `SURFACE-2026-06-09-F16-TRIAGE-AMBIGUOUS-FLAKY-SOFT-PASS-ON-SONNET` (workflow/backlog.md P-NEW). This scenario belongs to the pre-existing `debug-bisect-known-good` skill, NOT to anything Phase 1/2/3 of this feature added or modified. The skill was not edited by this feature. The harness retried per `max_retries: 2` and the test PASSed on attempt 2 — final status FLAKY (passed on retry), not FAIL.
Evidence: tests/results/run-2026-06-10-123208.json → `id=DEBUG-BISECT-GATE-MET, status=FLAKY, attempts=2, details="Contains 'clone' (no structured TRANSITION line)"`. Output-shape pattern matches the existing backlog item exactly.
Action: NO test or code modification. The FLAKY hit is in pre-existing infrastructure unrelated to this feature; this feature's 3 new scenarios all PASSed strictly on first attempt. The flake is a known issue tracked in the existing backlog item — no new SURFACE needed. Per the verify-codify Hard rule (no test modification without triage entry), this triage block satisfies the rule by documenting why no modification is being made.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-06-10] Phase 3 — `debug-*` skills currently have within-skill structural pin gaps. Phase 3b only pins the 2 gate-boundary headings (`## When to use` / `## When NOT to use`) for any debug-* skill. The other Phase 1 deliverables (file presence in the iterating loop, 6 required sections in full, 4 termination tokens, argument-hint, Gate Check first under Procedure) are not pinned. This is the existing convention — `debug-bisect-known-good` shipped with the same gaps. NOT a Phase 1 regression. Optional Phase 3 scope expansion: extend Phase 3b's loop to add ~5 within-skill pins (file presence + 6 sections + 4 termination tokens + argument-hint + Gate Check), which would apply to all debug-* skills uniformly. Decision deferred — Phase 3 currently scopes only Phase 3c (discoverability surfaces). If picked up, expected new PASS count: 143 + (5 pins × 2 skills) = 153 instead of the planned 148. Not blocking; surfacing for Phase 3 planning consideration.

[SURFACED-2026-06-10] Backlog follow-up — DEBUG-TELEMETRY-INCONCLUSIVE scenario coverage deferred. The 4th scenario (inconclusive-escalation path) was authored as a stretch goal in P3.7 but skipped at impl time. Reasoning: the path is structurally hard to test from a static fixture — it requires conveying "the agent has done 3 rounds of telemetry and none discriminated" without embedding telemetry results in the fixture itself, and the model tends to suggest more telemetry rounds rather than escalating from a fixture description. The 3 PASSing scenarios already cover the 3 main paths (procedure activates + Gate-1 SKIP + Gate-2 SKIP). Surface to backlog as a low-priority follow-up if the INCONCLUSIVE path ever regresses in practice; until then the gap is acceptable. Low priority.

## Downstream-contract-impacts check (plan-time)

Per the CLAUDE.md "Plan-time downstream-contract-impacts grep must include literal-payload-object assertions, array-length assertions, literal function-signature strings, AND literal variable-binding-name strings" convention, this plan checked for downstream consumers of the artifacts this feature changes:

- **New SKILL.md file** (Phase 1) — no existing consumers; new directory. No downstream impact possible at write time.
- **Caller SKILL.md `### Xb` Debug-technique-Sidebar prose additions** (Phase 2.1–2.3) — these are additive sentence inserts inside existing `### Xb` sections. No existing test asserts the literal content of those sections. The Phase 3c `grep_check` is the new assertion, written in Phase 3.
- **Orchestrator AGENTS.md table rows** (Phase 2.4–2.6) — these are new rows in an existing markdown table. No existing test asserts the row count or content of "Debug techniques (agent-pulled sidebars)" subsections beyond the coarse `grep_check` for the subsection header itself (Phase 3c line 217). No row-shape regression risk.
- **`docs/product/transitions.md` "Sidebar skills" sentence add** (Phase 2.7) — additive paragraph extension. No test asserts the literal content beyond the section-header grep (Phase 3c line 220). No regression risk.
- **`tests/check-structure.sh` Phase 3c extension** (Phase 3.1) — new `grep_check` calls in an existing test file. The expected PASS count changes from 141 → 148. No other test asserts the PASS count except by direct comparison; the `check-structure.sh` script reports its own total at exit. The runtime registry's `**Use timeout:**` value (87000ms last observed at 17s, 2026-06-10) is unaffected by the addition of 7 fast grep checks.
- **`tests/scenarios/debug.yaml` scenario additions** (Phase 3.2–3.7) — new scenarios in an existing YAML file. No existing test asserts the scenario count. `tests/run-all.sh` partitions by `model:` tag (or untagged → default/haiku); the new scenarios start untagged so they land in the haiku partition. No regression to existing bisect scenarios.

**Conclusion:** no cross-layer contract migration needed, no array-length-add risk, no literal function-signature change, no literal variable-binding-name change. This is a pure-additive feature on the harness side.
