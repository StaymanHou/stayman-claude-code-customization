---
name: feature-reproduce
description: "Feature workflow: reproduce an undesirable behavior with a failing test before spec/plan (red-green discipline)"
argument-hint: <description of the undesirable behavior to reproduce>
---

# Feature Reproduce

You are an expert Engineer practicing red-green discipline: first prove the bug exists with a failing test, then hand off so the fix can be planned and implemented.

## State Machine Context

You are in the **feature** workflow at the **reproduce** state.

This state is the **optional** entry point for **bug-fix features** — features whose problem statement describes an undesirable behavior (bug, regression, broken state, wrong output) rather than a new capability. It is reached either by `/session-start` routing on bug-shape language (S18) or by direct `/feature-reproduce` invocation.

**Valid transitions from here:**
- **F32 → spec:** Reproduced cleanly, feature is complex (fails small/simple criteria) → tell user to run `/feature-spec`
- **F33 → plan:** Reproduced cleanly, feature is small/simple (all criteria met) → tell user to run `/feature-plan`
- **F34 → spec (preventive hardening):** Could not reproduce, but the user wants a preventive fix → tell user to run `/feature-spec` with the framing reset to "preventive hardening: bug not reproducible in current state"
- **F35 → terminate:** Could not reproduce, no preventive fix needed → close the workflow with the reproduce attempt as the record

## Procedure

### 1. Confirm the Reported Behavior

- Read `{{args}}` carefully: what is the undesirable behavior, under what conditions, what was expected vs observed?
- If the description is too thin to attempt reproduction, ask one focused question to clarify (e.g., "what input triggers it?", "is this every time or intermittent?"). Otherwise, proceed.

### 2. Decide the Reproduction Surface

Choose ONE of the following based on what is most appropriate:
- **Failing test** (preferred when the behavior can be exercised in isolation): write a unit, integration, or end-to-end test that asserts the *expected* behavior and is therefore *currently failing*.
- **Manual repro recipe** (when the behavior depends on environmental conditions a test cannot reproduce — e.g., specific dataset, prod-shape concurrency, external API state): document a deterministic step-by-step recipe with expected vs observed output.
- **Telemetry-only** (when the behavior is observed only via logs/metrics in production): document the telemetry signature; flag this as could-not-reproduce-locally.

### 3. Write the Failing Test or Recipe

- **Failing test path:** Write the test in the appropriate test file. Run it. Confirm it fails *for the reason expected* (not for setup errors, missing imports, etc.). The test name should describe the bug, not the fix (e.g., `test_order_flips_when_finalize_runs_before_ship`).
- **Manual repro path:** Write the recipe in the WIP file. Execute it once and capture the actual observed output verbatim (paste, don't paraphrase).
- **Telemetry path:** Capture the telemetry signature (log message pattern, metric anomaly shape, error code) in the WIP file.

Save artifacts to:
- WIP file at `workflow/wip/<feature-name>.md` — create it if it does not exist (no spec or plan has run yet at this state):

```markdown
# Feature: <title>

**Workflow:** feature
**State:** reproduce
**Created:** <YYYY-MM-DD>
**Entry:** reproduce (bug-fix feature)

## Problem Statement
<undesirable behavior, conditions, expected vs observed>

## Reproduction Attempt
**Surface chosen:** failing test | manual recipe | telemetry-only
**Outcome:** reproduced | could-not-reproduce | partial
**Artifact:** <path to test file, OR pasted recipe with output, OR telemetry signature>
**Determinism:** every-run | flaky (X out of Y) | once-observed
**Notes:** <conditions, dependencies, anything material the spec/plan needs to know>
```

### 4. Evaluate Outcome and Transition

**If reproduced (failing test exists or recipe deterministic):**
- Apply small/simple criteria to the eventual fix:
  - All five hold (no new data models/endpoints, no arch decisions, ≤4 sentences, <4hrs, ≤200 lines)? → **F33** → recommend `/feature-plan`
  - Otherwise → **F32** → recommend `/feature-spec`
- The reproduce artifact (failing test, recipe, signature) becomes the **anchor** for verify-codify: "fixed means this no longer fails / no longer reproduces."

**If could-not-reproduce:**
- The bug isn't reproducible from the user's description in current state. Two paths:
  - User wants a preventive fix anyway (e.g., "even if I can't reproduce it, this code path is fragile and worth hardening") → **F34** → recommend `/feature-spec` with framing reset to "preventive hardening — bug not reproducible at reproduce stage."
  - User accepts that without reproduction there is nothing actionable → **F35** → close the workflow. The WIP file's Reproduction Attempt section becomes the record.

**If partial repro (intermittent / flaky):**
- Treat as could-not-reproduce for transition purposes. Document the conditions narrowed and recommend either preventive hardening (F34) or terminate (F35).

### 5. Hand Off

Emit the transition ID at the end of your output (the orchestrator reads `TRANSITION: <id>`).

**Single-step mode only:** STOP after writing the reproduction artifact and emitting the transition — do NOT continue into spec/plan. In orchestrated/autopilot/full-autopilot modes the orchestrator chains based on the drive mode's pause policy:
- F32, F33 (reproduced cleanly) → AUTO in modes 2, 3, 4
- F34 (preventive hardening) → AUTO in mode 4 only; PAUSE in modes 1, 2, 3
- F35 (terminate) → PAUSE in all modes (terminating a workflow without a reproduce signal deserves human confirmation)

**User Request:** {{args}}
