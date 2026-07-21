---
name: incident-codify
workflow: feature
state: finalize (complete) — archived 2026-05-10
created: 2026-05-10
entry: spec (complex feature)
drive_mode: orchestrated
source: SURFACE-2026-05-08-INCIDENT-CODIFY-EQUIVALENT
---

# Feature: `incident-codify` — Regression-Securing Step for Incident Workflow

## Problem Statement

The incident workflow lacks a regression-securing step analogous to `feature-verify-codify`. After `incident-mitigate` applies a fix and `incident-resolve` confirms monitoring passes, no formal step writes or extends test coverage to prevent recurrence. The reproduce artifact from `/incident-reproduce` (when used) may live only in WIP/archive and never enter CI. For incidents that bypass reproduce (telemetry-only, prod-data-only), the fix may have no permanent test at all. This mirrors the gap that motivated `feature-verify-codify`. Adding `incident-codify` between mitigate and resolve closes the gap — speed-aware via conditional pause + defer-with-SURFACE path.

## Spec Reference

Spec content (problem, user stories, acceptance criteria, technical constraints, decided open questions) is preserved below the Work Tree for back-loop reference.

## Work Tree

- [x] Phase 1: New `incident-codify` SKILL
  **Observable outcomes:**
  - CLI: `ls -la ~/.claude/skills/incident-codify/SKILL.md` resolves to repo `skills/incident-codify/SKILL.md` (symlink present after `./install.sh`)
  - CLI: `python -c "import yaml; m=open('skills/incident-codify/SKILL.md').read().split('---')[1]; d=yaml.safe_load(m); assert d['name']=='incident-codify'; assert 'description' in d"` exits 0
  - CLI: `grep -c "TRANSITION:" skills/incident-codify/SKILL.md` returns ≥1 (skill emits transition token)
  - CLI: `grep -E "I17|I18|I19|I20" skills/incident-codify/SKILL.md | wc -l` returns ≥4 (all four transitions referenced)
  - CLI: `./tests/check-structure.sh` exits 0
  - [x] P1.1 Create `skills/incident-codify/SKILL.md` with frontmatter (name, description, argument-hint), State Machine Context section listing I17 entry / I18/I19/I20 exits, and full Procedure
  - [x] P1.2 In Procedure, adapt feature-verify-codify §2 (highest-level test rule + integration-boundary check) for incident context — cite consuming surface where fix touches a boundary
  - [x] P1.3 In Procedure, add reproduce-artifact-reuse logic — if `## Reproduction Attempt` section exists with failing test, run it (must now pass), do not write duplicate
  - [x] P1.4 In Procedure, adapt feature-verify-codify §3b triage gate (six-case table) for incident semantics — "code regression" → back-loop to mitigate (I19), not auto-fix; flaky-detection re-run 3x then pause
  - [x] P1.5 In Procedure, add speed-aware paths — minimum-viable-coverage (one test, the one that catches this incident) + defer-with-SURFACE (writes SURFACE→task:plan entry with reasoning, exits via I18-defer)
  - [x] P1.6 In Procedure, add conditional-pause note (AUTO when reproduce-artifact passes; PAUSE when writing new coverage from scratch) — this is descriptive for the orchestrator, the actual policy lives in AGENTS.md
  - [x] P1.7 Run `./install.sh` to create the symlink
  - [x] verify-auto
  - [x] verify-self  <!-- No integration boundary (Phase 1 adds isolated new artifact); CLI outcomes re-observed against live ~/.claude/ — all PASS -->
  - [x] verify-human  <!-- approved 2026-05-10: all five checklist items (semantic flip, Path A/B split, defer-with-SURFACE friction, I20 distinction, conditional-pause docs) approved as-is -->
  - [x] verify-codify  <!-- No new tests added in Phase 1: behavioral scenarios deferred to Phase 3 (they require Phase 2 wiring to be meaningful). Phase 1 is covered by generic check-structure.sh assertions (symlink-count invariant, YAML validity, scenario YAML integrity — all PASS 29/29). No integration boundary in Phase 1. -->

- [x] Phase 2: State machine wiring — transitions and orchestrator
  **Observable outcomes:**
  - CLI: `grep -E "^\| I17 \|" docs/product/transitions.md` matches one line with `mitigate | codify`
  - CLI: `grep -E "^\| I18 \|" docs/product/transitions.md` matches one line with `codify | resolve`
  - CLI: `grep -E "^\| I19 \|" docs/product/transitions.md` matches one line with `codify | mitigate`
  - CLI: `grep -E "^\| I20 \|" docs/product/transitions.md` matches one line with `codify | investigate`
  - CLI: `grep -c "incident-codify" agents/incident-workflow/AGENTS.md` returns ≥2 (frontmatter skills list + States and Skills table `/incident-codify` reference; short form `codify` used in tables/prose per existing convention)
  - CLI: `grep -nE " codify |codify \(|codify →|→ codify| codify$" agents/incident-workflow/AGENTS.md | wc -l` returns ≥6 (short-form codify appears in diagram, states table, transition table x4, pause-policy rows — confirms full wiring)
  - CLI: `grep "codify" agents/incident-workflow/AGENTS.md | grep -E "AUTO|PAUSE"` returns ≥3 (pause-policy rows: I17 AUTO, Path A AUTO, Path B PAUSE, plus defer/back-loops PAUSE)
  - CLI: `python -c "import yaml; d=yaml.safe_load(open('agents/incident-workflow/AGENTS.md').read().split('---')[1]); assert 'incident-codify' in d['skills']"` exits 0
  - HTTP: N/A (no HTTP surface)
  - [x] P2.1 Edit `docs/product/transitions.md` — add I17–I20 rows to incident transition table; update Incident Workflow state diagram to show `mitigate → codify → resolve`; update the Reproduce step (I13–I16) trailing paragraph to mention codify-handoff; add new Codify-step paragraph
  - [x] P2.2 Edit `docs/product/transitions.md` — add codify rows to incident pause-policy table (I17 AUTO, Path A AUTO, Path B PAUSE, defer PAUSE, I19/I20 PAUSE); I9 condition updated to defer-with-SURFACE
  - [x] P2.3 Edit `agents/incident-workflow/AGENTS.md` — added `incident-codify` to `skills:` frontmatter; updated State Machine ASCII diagram; added codify row to States and Skills table; added I17–I20 to transition table; added six codify rows to pause policy table; updated happy-path summary
  - [x] P2.4 Edit `skills/incident-mitigate/SKILL.md` — replaced "I9 → resolve" valid-transitions section with "I17 → codify (default) + I9 → resolve (skip-codify defer)"; updated §6 Evaluate Outcome with three branches (I17 default, I9 defer, I8 back-loop)
  - [x] P2.5 Edit `skills/incident-resolve/SKILL.md` — added "How this state is reached" block listing I18 / I9 / I4 / I7 entry paths; updated §1 Verify Resolution to check Codify or Codify-Deferred section in WIP file
  - [x] P2.6 Edit `skills/incident-reproduce/SKILL.md` — added one-line note in §5 Hand Off that codify will pick up the reproduction artifact
  - [x] verify-auto  <!-- 8/8 Observable Outcomes PASS + 29/29 structural checks -->
  - [x] verify-self  <!-- Integration boundary applied: live ~/.claude/ harness re-observed. 6/6 consuming surfaces PASS — AGENTS.md skills list, mitigate/resolve/reproduce SKILLs, incident-codify skill, and existing I2–I16 scenarios all intact. -->
  - [x] verify-human  <!-- approved 2026-05-10: state machine wiring across 5 files reviewed; I9-semantics-change accepted (defer path is the lower-churn choice over renumbering); AGENTS.md diagram density acceptable -->
  - [x] verify-codify  <!-- Integration boundary applied; existing I2-I16 scenarios re-checked: all assertion phrases still present in edited SKILLs (no false positives). One obsolete-test discovered (I9 contract change) — triage artifact written above, scenario update batched into Phase 3 P3.2. 29/29 structural checks PASS. -->

- [x] Phase 3: Test scenarios + docs + backlog close
  **Relevance check (before Phase 3):**
  - Requester still needs this: yes — user approved Phase 1 and Phase 2
  - Requirements unchanged: yes
  - Solution still feasible: yes — Phase 2 wired the state machine; Phase 3 exercises it
  - No superior alternative discovered: yes
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: `grep -E "^\s+- id: I17" tests/scenarios/incident.yaml` matches
  - CLI: `grep -E "^\s+- id: I18" tests/scenarios/incident.yaml` matches (happy path)
  - CLI: `grep -E "^\s+- id: I18-defer" tests/scenarios/incident.yaml` matches (defer-with-SURFACE variant) OR a separate scenario asserts defer path
  - CLI: `grep -E "^\s+- id: I19" tests/scenarios/incident.yaml` matches
  - CLI: `grep -c "incident-codify" CLAUDE.md` returns ≥1
  - CLI: `grep "SURFACE-2026-05-08-INCIDENT-CODIFY-EQUIVALENT" workflow/backlog.md | grep -E "RESOLVED 2026-05-10"` matches
  - CLI: `./tests/run-tests.sh --group incident --id I17,I18,I19 --dry-run` exits 0 (scenarios parse) — full run gated on verify-auto
  - CLI: `./tests/check-structure.sh` exits 0
  - [x] P3.1 Created test fixtures: `tests/fixtures/wip/incident-codify-with-reproduce-artifact.md` (Path A — passing test + monitoring done) and `tests/fixtures/wip/incident-codify-no-reproduce.md` (Path B — mitigation done, no prior reproduce)
  - [x] P3.2 Added scenarios to `tests/scenarios/incident.yaml`: I17 (mitigate→codify default), I18 (codify→resolve Path A artifact-passes), I18-defer (codify→resolve via SURFACE), I19 (codify→mitigate back-loop). Also updated existing I9 scenario per Phase 2 Test Triage — now asserts defer semantics with explicit P0 customer-escalation reasoning in the prompt.
  - [x] P3.3 Edited `CLAUDE.md` Architecture section — added paragraph after the feature per-phase-loop description explaining the incident `mitigate → codify → resolve` step and its two incident-context flips (semantic flip + speed-aware paths)
  - [x] P3.4 Moved SURFACE-2026-05-08-INCIDENT-CODIFY-EQUIVALENT to Resolved log with RESOLVED 2026-05-10 entry summarizing the implementation
  - [x] verify-auto  <!-- 7/7 Observable Outcomes PASS + dry-run resolved all 4 new scenarios + 29/29 structural checks -->
  - [x] verify-self  <!-- Integration boundary applied: test runner is the consuming surface. 6/6 live observations PASS — fixtures resolve, YAML parses with new scenarios, I17/I18/I18-defer/I19 dry-run all resolve to correct skill, I9 updated contract still resolves, scenario count 118→122 -->
  - [x] verify-human  <!-- approved 2026-05-10: scenarios + fixtures + CLAUDE.md + backlog all reviewed and accepted; live haiku run declined for now (will surface as backlog risk if scenarios SOFT_PASS later) -->
  - [x] verify-codify  <!-- All 4 phase-3 scenarios in place (I17, I18, I18-defer, I19) + I9 updated; I20 absence surfaced as SURFACE-2026-05-10-I20-SCENARIO-MISSING (low priority, plan didn't include it); 29/29 structural checks PASS -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** finalize (archive WIP, sweep backlog, mark cycle done)
- **Blocked:** none
- **Unvisited:** Phase 2 (state machine wiring), Phase 3 (tests + docs + backlog close)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
- [SURFACED-2026-05-10] Phase 3 verify-codify — I20 (codify → investigate back-loop) has no test scenario. Logged to backlog as SURFACE-2026-05-10-I20-SCENARIO-MISSING (priority: low).

## Retrospect

- **What changed in our understanding:** The biggest learning was that calibrating a plan's Observable Outcomes against existing codebase conventions matters. The Phase 2 plan asserted `grep -c "incident-codify" agents/incident-workflow/AGENTS.md ≥4`, but the existing AGENTS.md convention uses short-form `codify` in tables and prose, full form only in frontmatter and slash-command references. The wiring was correct; the outcome threshold was miscalibrated. Caught and adjusted in Phase 2 verify-auto — the outcome was rewritten to assert two distinct thresholds (literal `incident-codify` ≥2 + short-form `codify` references ≥6).
- **Assumptions that held:** The structural mirroring of feature-verify-codify worked cleanly — the highest-level test rule, integration-boundary check, and six-case triage table all adapted to incident context without architectural changes. Path A vs Path B distinction proved load-bearing and not over-engineered. The conditional pause model (AUTO on artifact-passes / defer, PAUSE on new-test-from-scratch) cleanly captured the speed-vs-rigor tradeoff.
- **Assumptions that were wrong:** I9 contract change cascaded into the existing I9 test scenario in a way the plan didn't anticipate. The Phase 2 plan listed "test scenarios" only in Phase 3 — but Phase 2's mitigate-SKILL edit silently invalidated the existing I9 scenario's premise. Caught by Phase 2 verify-codify's triage gate; classified as obsolete-test, batched into Phase 3 P3.2. The triage gate doing its job here was the system working as designed — but the plan should have flagged the I9 contract change as a Phase 2 deliverable, not a Phase 3 cleanup.
- **Approach delta:** Implementation matched the plan with two adjustments: (a) Phase 2 Observable Outcome threshold recalibrated mid-build (described above); (b) one discovery surfaced — I20 scenario absence — and logged to backlog rather than absorbed into Phase 3 (plan didn't include it; user approved I20's distinct existence in verify-human Phase 1 but didn't request a scenario). Both adjustments documented in the WIP file at the time. Plan held to 3 phases with no insertion or merging.

## Communicate

> **Feature complete:** `incident-codify` has shipped. A new regression-securing step now sits between `/incident-mitigate` and `/incident-resolve` in the incident workflow, with Path A (reuse reproduce-artifact), Path B (write from scratch), and a defer-with-SURFACE escape hatch for active P0s. The four new transitions (I17, I18, I19, I20) and the I9 contract change are wired through transitions.md, AGENTS.md, the three adjacent SKILLs, and the test scenario suite.
>
> Verify in action: next time you run `/incident-mitigate` after a successful fix, it should hand off to `/incident-codify` instead of going straight to `/incident-resolve`. Or run `./tests/run-tests.sh --group incident --id I17,I18,I18-defer,I19 --dry-run` to see the new scenarios resolve.
>
> Requester = operator — closure notice for self-record.


## Test Triage — tests/scenarios/incident.yaml I9
Classification: Obsolete test — new feature intentionally supersedes what the test checked
Confidence: high
Evidence: The I9 scenario (incident.yaml:144–161) asserts `transition_id: I9` and "/incident-resolve" for the input "fix is confirmed working and stable". Per Phase 2 of this feature, that input is now the I17 path (mitigate → codify is default); I9 has been redefined as the defer-with-SURFACE path requiring explicit deferral reasoning. The fixture (`incident-rootcause-found.md`) and prompt have no deferral signal, so the model should now emit I17, not I9.
Action: Update I9 scenario in two parts: (a) update existing I9 to assert the new defer semantics (input must include explicit "defer codify" reasoning) — possibly rename to I9-defer; (b) the "fix works → mitigate to next-step" happy-path test moves under I17 in Phase 3. Since Phase 3 of this feature will add I17/I18/I19 scenarios, this update is naturally batched there. For Phase 2 verify-codify completion: noting the contract change here; the actual scenario update happens in Phase 3 P3.2.


---

## Spec (preserved for back-loop reference)

### User Stories

- **As an SRE closing an incident**, I want a formal step between mitigate and resolve that codifies regression coverage so the same incident cannot silently recur.
- **As an SRE handling a P0 with time pressure**, I want incident-codify to be speed-aware — minimum-viable-test now, with the option to defer broader coverage to a SURFACE backlog item rather than blocking resolution.
- **As an SRE reviewing an archived incident**, I want the codify step's artifact in the WIP file so I can see what coverage was added (or explicitly deferred) without re-reading the entire history.

### Acceptance Criteria

1. New `incident-codify` SKILL exists at `skills/incident-codify/SKILL.md`, symlinked into `~/.claude/skills/` via `install.sh`.
2. New transitions in `docs/product/transitions.md`:
   - **I17:** `mitigate → codify` (monitoring passed, codify before resolve)
   - **I18:** `codify → resolve` (coverage written or explicitly deferred)
   - **I19:** `codify → mitigate` (back-loop: codify-time test exposes mitigation didn't fix the bug)
   - **I20:** `codify → investigate` (back-loop: codify-time test reveals root cause analysis was wrong)
   - **I9** (mitigate→resolve direct) kept as explicit "skip-codify defer" path with required human reasoning + SURFACE→task:plan audit trail.
3. `agents/incident-workflow/AGENTS.md` updated (diagram, states table, transitions, pause policy, skills frontmatter).
4. SKILL adapts feature-verify-codify's: highest-level test rule, integration-boundary check, six-case triage table — with incident semantics ("code regression" → back-loop to mitigate, not auto-fix).
5. Speed-aware paths: minimum-viable-coverage + defer-with-SURFACE.
6. Reproduce-artifact reuse: existing failing test from `/incident-reproduce` is preserved; codify confirms it now passes.
7. Test scenarios for I17 happy path, I18 happy + defer, I19 back-loop, reproduce-artifact reuse.
8. CLAUDE.md updated; backlog item marked RESOLVED.

### Out of Scope

- Renaming `feature-verify-codify`.
- Auto-promoting reproduce artifacts to CI (relies on existing project CI conventions).
- Severity-based mandatory codify (codify-vs-defer remains a human judgment call).
- Replacing/extending existing `incident-resolve` SURFACE→task / SURFACE→feature follow-up logic (I11, I12) — those are root-cause-fix follow-ups; codify is regression-coverage. Both coexist.
- Backporting codify to past archived incidents.

### Technical Constraints

- Pause policy must keep incident workflow speed-tolerant. Always Mode 2 regardless of session drive mode.
- I9 (mitigate→resolve direct) cannot be deleted — fast-close paths (I4, I7) from triage/investigate still go straight to resolve. Codify sits only between mitigate and resolve, not in fast-close paths.
- Reproduce artifact handoff is asymmetric: when present, it's *the* regression test; when absent, codify writes from scratch.
- Triage gate semantics flip from feature workflow: "code regression" in incident context = "mitigation didn't fix it" → back-loop (I19), not auto-fix.

### Decided Open Questions

- **I9 fate:** Kept as explicit "skip-codify defer" path with required human reasoning in WIP file + SURFACE→task:plan to ensure test gets written later.
- **Codify pause:** Conditional — AUTO when reproduce-artifact present and now passing (artifact's pass is the gate); PAUSE when writing new coverage from scratch (human reviews new test before resolve).
- **Naming:** `incident-codify` (no "verify-" prefix; incident workflow has no verify-loop to disambiguate from).

### Risks and Mitigations

- **Risk:** Codify slows P0 closure. **Mitigation:** Conditional pause + defer-with-SURFACE.
- **Risk:** Triage gate adapted from feature context introduces ambiguity. **Mitigation:** Reuse six-case table verbatim; document incident-specific "code regression" semantic flip.
- **Risk:** Codify-time tests could be flaky. **Mitigation:** Inherit flaky-detection rule (re-run 3x, pause for human).
