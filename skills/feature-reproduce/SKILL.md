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

**Valid transitions from here (normal entry — F31 from session-start or direct invocation):**
- **F32 → spec:** Reproduced cleanly, feature is complex (fails small/simple criteria) → tell user to run `/feature-spec`
- **F33 → plan:** Reproduced cleanly, feature is small/simple (all criteria met) → tell user to run `/feature-plan`
- **F34 → spec (preventive hardening):** Could not reproduce, but the user wants a preventive fix → tell user to run `/feature-spec` with the framing reset to "preventive hardening: bug not reproducible in current state"
- **F35 → terminate:** Could not reproduce, no preventive fix needed → close the workflow with the reproduce attempt as the record

**Valid transitions from here (F36-redirect entry — from feature-build mid-phase):**
- **F37 → build (return on success):** Reproduced cleanly mid-build, artifact attached to WIP under `## Reproduction Artifact (mid-build, from F36)` → tell user to run `/feature-build` to resume the in-progress phase
- **F37b → build (return on could-not-reproduce):** Could not reproduce the bug mid-build; document the could-not-reproduce outcome as a Discovery and resume → tell user to run `/feature-build`
- **F34 and F35 are disallowed from F36-entered reproduce.** Terminating a feature mid-build because the bug couldn't be re-reproduced is the wrong outcome (use F37b — return with Discovery), and the feature is already past spec so framing reset to spec is meaningless.

## Orchestrator Pause Policy (cheat-sheet)

When invoked by `/session-start` in orchestrated mode, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause. Per-skill rows for reproduce's exits:

| Transition | Mode 1 — Step-by-step | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — Full-autopilot |
|---|---|---|---|---|
| F32 (reproduce → spec, reproduced cleanly + complex) | PAUSE | AUTO | AUTO | AUTO |
| F33 (reproduce → plan, reproduced cleanly + simple) | PAUSE | AUTO | AUTO | AUTO |
| F34 (reproduce → spec, could-not-reproduce → preventive hardening) | PAUSE | **PAUSE** | **PAUSE** | AUTO |
| F35 (reproduce → terminate, could-not-reproduce + no preventive) | PAUSE | **PAUSE** | **PAUSE** | **PAUSE** |
| F37 (reproduce → build, return-from-F36 on success) | PAUSE | AUTO | AUTO | AUTO |
| F37b (reproduce → build, return-from-F36 on could-not-reproduce) | PAUSE | AUTO | AUTO | AUTO |

**Hard rule for AUTO exits.** When this skill's emitted transition is `AUTO` in the current drive mode, the orchestrator **must immediately invoke the next skill via the `Skill` tool**. It must **NOT** return control to the user. Emitting a clean `TRANSITION: F33` followed by a polite narrative summary ("Reproduced cleanly; ready to run /feature-plan") in Mode 3/4 is the regression mode this block exists to prevent (P1 incident, 2026-05-16, scope-extended 2026-05-17): the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. **This explicitly includes the `AskUserQuestion` tool (and any other user-input/confirmation prompt): invoking it on an AUTO transition IS "returning control to the user" and is the same regression class as the narrative-summary stop above — do NOT call it to "just confirm" the handoff. The only thing that pauses an AUTO transition is the human-input points the active drive mode's pause policy explicitly marks PAUSE.** See `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## Step 0: Available product context

Run `ls docs/product/` to see which strategic docs exist (silent no-op if absent):

- `docs/product/arch.md` — architectural decisions and system design
- `docs/product/wbs.md` — active work breakdown structure (current cycle)
- `docs/product/vision.md` — high-level product vision
- `docs/product/roadmap.md` — strategic roadmap
- `docs/product/research.md` — cycle-scoped research findings

**No eager reads.** Reproduction work is grounded in the bug itself — the failing condition, the suspected commit range, the failing test — not in strategic docs. Loading product docs at reproduce time biases the agent toward over-scoping (e.g., reframing a one-line regression as an arch-level concern). The docs are pointer-only here; read on your own initiative only if reasoning surfaces a specific question that needs them.

**Absent files:** silent no-op. No warning, no prompt.

See `CLAUDE.snippet.md` → "Entry-skill product-context loading (GLOBAL)" for the canonical mapping.

## Procedure

### 1. Confirm the Reported Behavior

- Read `{{args}}` carefully: what is the undesirable behavior, under what conditions, what was expected vs observed?
- If the description is too thin to attempt reproduction, ask one focused question to clarify (e.g., "what input triggers it?", "is this every time or intermittent?"). Otherwise, proceed.

### 1.5. Detect F36 Entry (mid-build REDIRECT source)

Before deciding the reproduction surface, check whether this invocation was reached via F36 from `feature-build`. Mechanism: read the WIP file at `workflow/wip/<feature-name>.md` and inspect `## Current Node` for a sentinel line of the form `**Redirect source:** build (F36 — Phase N)`.

**If the sentinel is present (F36-entry mode):**
- Set `f36_entry = true` for the remainder of this skill invocation.
- The WIP file already contains a placeholder `## Reproduction Artifact (mid-build, from F36)` section (written by `feature-build` at F36 exit). The reproduction artifact you produce in §3 will be written into this section, not the normal `## Reproduction Attempt` section.
- §4 "Evaluate Outcome and Transition" routes to F37/F37b instead of F32/F33/F34/F35. F34 and F35 are disallowed in this mode — F37b is the always-available fallback for could-not-reproduce.
- If `{{args}}` lacks bug-description detail (which is plausible since build is the caller, not the user), read the WIP's `## Problem Statement` and the current phase's impl-task description to infer what undesirable behavior the build phase was applying a fix for.

**If the sentinel is absent (normal entry — F31 or direct invocation):**
- Set `f36_entry = false`. Continue per the existing normal-entry procedure (§2 onward). All four normal-entry exits (F32/F33/F34/F35) remain available.

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

**Branch on `f36_entry` (set in §1.5):**

#### Normal entry (f36_entry = false — F31 from session-start or direct invocation)

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

#### F36-redirect entry (f36_entry = true — invoked from feature-build mid-phase)

**F34 and F35 are disallowed in this mode.** The feature is mid-build and the user is committed to seeing it through; F37b (return with Discovery) is the always-available fallback when reproduction fails.

**If reproduced (failing test exists or recipe deterministic) → F37:**
- Write the artifact details (failing test path, recipe, or telemetry signature) into the WIP file's `## Reproduction Artifact (mid-build, from F36)` section (the placeholder placed there by feature-build at F36 exit).
- Update `## Current Node` to clear the `**Redirect source:** build (F36 — Phase N)` sentinel and restore the path to where build was paused (still Phase N's in-progress impl task).
- The reproduce artifact now anchors the in-progress phase's verify-codify ("fixed means this artifact no longer fails / no longer reproduces").
- → **F37** → recommend `/feature-build` to resume the in-progress phase with the artifact in hand.

**If could-not-reproduce (including partial / flaky) → F37b:**
- Write a one-paragraph could-not-reproduce note into the WIP's `## Reproduction Artifact (mid-build, from F36)` section: what was tried, why it didn't fire (environment difference, deterministic scheduling, missing prod data, etc.), and what evidence the original bug-fix claim rests on now (logs, intuition, prior incident).
- Append a Discovery entry to the WIP's `## Discoveries` section: `[SURFACED-<date>] <phase-node> — F36 reproduce attempt could-not-reproduce; <one-line summary>`.
- Update `## Current Node` to clear the F36 sentinel.
- The fix may still ship, but the verify-codify gate must be considered weaker without an anchoring artifact — the human reviewer at verify-human should be alerted that the phase ships without red-green discipline.
- → **F37b** → recommend `/feature-build` to resume the in-progress phase, with the could-not-reproduce outcome documented.

### 5. Hand Off

Emit the transition ID at the end of your output (the orchestrator reads `TRANSITION: <id>`).

**Possible emit tokens:**
- `TRANSITION: F32` — normal-entry, reproduced cleanly, complex feature → spec
- `TRANSITION: F33` — normal-entry, reproduced cleanly, small/simple feature → plan
- `TRANSITION: F34` — normal-entry, could-not-reproduce, user elects preventive hardening → spec
- `TRANSITION: F35` — normal-entry, could-not-reproduce, no preventive fix → terminate
- `TRANSITION: F37` — F36-entry, reproduced cleanly mid-build → return to build with artifact
- `TRANSITION: F37b` — F36-entry, could-not-reproduce mid-build → return to build with Discovery (F34/F35 disallowed in F36-entry mode)

**Single-step mode only:** STOP after writing the reproduction artifact and emitting the transition — do NOT continue into spec/plan/build. In orchestrated/autopilot/full-autopilot modes the orchestrator chains based on the drive mode's pause policy:
- F32, F33 (reproduced cleanly) → AUTO in modes 2, 3, 4
- F34 (preventive hardening) → AUTO in mode 4 only; PAUSE in modes 1, 2, 3
- F35 (terminate) → PAUSE in all modes (terminating a workflow without a reproduce signal deserves human confirmation)
- F37, F37b (F36-return) → AUTO in modes 2, 3, 4 (back-loop-shape pause policy)

**User Request:** {{args}}
