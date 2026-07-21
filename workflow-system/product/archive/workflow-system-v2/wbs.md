---
stage: wbs
state: in-progress
updated: 2026-05-02
completed: 2026-05-02
---

# Work Breakdown Structure — Workflow System v2 (PP4 + PP5)

## Scope

Two pain points diagnosed in `docs/product/workflow-pain-points-2.md`:

- **PP4:** Agent cannot reliably triage a failed test at `verify-codify` — silently chooses between fixing code, updating tests, or re-running without escalating ambiguous cases to the human.
- **PP5:** In orchestrated mode (`/session-start`), the agent stops after every step and waits for the user to invoke the next slash command — even when the step passes cleanly and no human decision is required.

---

## Phase 1: Orchestrator Auto-Advance (PP5)

**Goal:** The orchestrator in `agents/feature-workflow/AGENTS.md` auto-advances through steps that have no human decision point, stopping only at defined PAUSE gates. Single-step invocation (e.g., direct `/feature-verify-auto`) is unaffected.

**Phase 1 → Phase 2 rationale:** PP5 is a pure orchestrator change — no skill prompt edits, no new states, no file schema changes. It is self-contained and unblocks user flow immediately. PP4 requires multi-skill edits; doing PP5 first keeps those changes clean and reviewable independently.

### WP14: Orchestrator AUTO/PAUSE Annotation

**Description:** Annotate every step in the feature-workflow Orchestration Procedure with its pause policy (`AUTO` or `PAUSE`), and update the procedure so the orchestrator acts on the policy rather than always stopping after each step.
**Phase:** 1
**Dependencies:** None
**Size:** S
**Tasks:**
- [x] 14.1 Define AUTO/PAUSE policy for each feature-workflow step (build→AUTO, verify-auto→AUTO on pass, verify-self→AUTO on pass, verify-human→PAUSE, verify-codify→AUTO on pass, feature-ship→AUTO, feature-finalize→PAUSE)
- [x] 14.2 Update `agents/feature-workflow/AGENTS.md` Orchestration Procedure to annotate each step with its pause policy and instruct the orchestrator to chain AUTO steps without waiting for user input
- [x] 14.3 Clarify that the `TRANSITION: <id>` token is the machine signal the orchestrator acts on; the prose "Run `/x`" in skill output is for single-step users only and should not cause the orchestrator to pause
- [x] 14.4 Back-loop transitions are AUTO — orchestrator re-enters build without pausing; human sees outcome at next verify-human (revised from original plan)
- [x] 14.5 Update transition test scenarios to cover orchestrated auto-advance behavior (S7, S8, S9)

---

## Phase 2: `verify-codify` Test Triage Gate (PP4)

**Goal:** When `verify-codify` encounters a failing test, the agent must classify the failure before acting, produce a written triage artifact, and escalate to the human for all non-obvious cases.

**Phase 2 → Phase 3 rationale:** The triage gate is a self-contained `verify-codify` skill change. Phase 3 (hardening) validates everything with tests and updates docs — it depends on Phase 2 being stable first.

### WP15: `verify-codify` Triage Protocol

**Description:** Add a mandatory triage decision procedure to `feature-verify-codify/SKILL.md`. When any test fails during the full suite run, the agent must classify and record before acting.
**Phase:** 2
**Dependencies:** None
**Size:** M
**Tasks:**
- [x] 15.1 Add the six-case classification table to `feature-verify-codify/SKILL.md` (flaky test added as 6th case)
- [x] 15.2 Define "high confidence": failure has exactly one plausible explanation, stateable in one sentence without hedging (revised from original line-pointing definition)
- [x] 15.3 Require `## Test Triage` artifact in WIP file before any action on failing test
- [x] 15.4 Hard rule: no test file modified/deleted without completed triage entry
- [x] 15.5 Flaky detection: re-run up to 2 retries (3 total); if still failing, pause

### WP16: Transition Test Scenarios for PP4

**Description:** Add test scenarios covering each triage path in `verify-codify`.
**Phase:** 2
**Dependencies:** WP15
**Size:** S
**Tasks:**
- [x] 16.1 F16-triage-regression: code regression, high confidence → auto-fix
- [x] 16.2 F16-triage-ambiguous: ambiguous failure → pause
- [x] 16.3 F16-triage-flaky: inconsistent test → classify as flaky, pause
- [x] 16.4 F16-triage-contract: contract conflict → always pause

---

## Phase 3: Hardening

**Goal:** All new behavior is tested, documented, and structurally checked.

**Phase 3 rationale:** Depends on Phases 1 and 2 being stable. Hardening last is the standard pattern from the prior cycle.

### WP17: Docs and Structure Update

**Description:** Update CLAUDE.md, transitions.md, and any argument-hints to reflect the new AUTO/PAUSE orchestration policy and the verify-codify triage protocol.
**Phase:** 3
**Dependencies:** WP14, WP15, WP16
**Size:** S
**Tasks:**
- [x] 17.1 Update `docs/product/transitions.md` with AUTO/PAUSE pause-policy concept and feature workflow pause policy summary table
- [x] 17.2 Update `CLAUDE.md`: mark WP14–WP17 complete, add orchestrator pause policy and test triage conventions
- [x] 17.3 `./tests/check-structure.sh` — 13/13 pass
- [x] 17.4 Skipped per operator instruction (full suite already green from PP4 ship)

---

## Dependency Map

```
WP14 (Orchestrator AUTO/PAUSE)     — independent, Phase 1
WP15 (verify-codify triage gate)   — independent, Phase 2
WP16 (triage test scenarios)       — depends on WP15
WP17 (hardening + docs)            — depends on WP14, WP15, WP16
```

**Parallel tracks:** WP14 and WP15 are fully independent and can be built in parallel.

---

## Exit Criteria

- In orchestrated mode, the agent completes `build → verify-auto → verify-self → verify-codify → feature-ship` without stopping for user input when all steps pass cleanly
- `verify-human` and `feature-finalize` remain explicit PAUSE points in orchestrated mode
- Any failing transition in an AUTO step triggers a PAUSE before re-entering build
- When `verify-codify` hits a failing test, a `## Test Triage` entry exists in the WIP file before any code or test is modified
- High-confidence code regressions and obsolete tests are auto-resolved; all other cases pause for human
- Flaky tests are re-run up to 3 times before escalating; they are never "fixed" by modifying code
- `./tests/run-tests.sh` passes clean on haiku for all groups
