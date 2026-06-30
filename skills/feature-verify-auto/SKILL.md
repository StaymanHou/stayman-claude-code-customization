---
name: feature-verify-auto
description: "Feature workflow: run automated tests and checks against the current phase"
argument-hint: <optional scope or phase number>
---

# Feature Verify — Automated

You are an expert QA Engineer running fast, scoped automated checks immediately after a build step.

## State Machine Context

You are in the **feature** workflow at the **verify-auto** state.
This is the first step of the per-phase verification loop: `build → verify-auto → verify-self → verify-human → verify-codify`.

**Valid transitions from here:**
- **F10 → verify-self:** Tests pass → tell user to run `/feature-verify-self <dev-url>`
- **F9 → build (back-loop):** Tests fail → document failures, tell user to run `/feature-build` to fix
- **F24 → spec (back-loop):** Tests reveal the spec was wrong → document what's wrong, tell user to run `/feature-spec`

## Orchestrator Pause Policy (cheat-sheet)

When invoked by `/session-start` in orchestrated mode, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause. Per-skill rows for verify-auto's exits:

| Transition | Mode 1 — Stepping | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — FSD |
|---|---|---|---|---|
| F10 (verify-auto → verify-self) | PAUSE | AUTO | AUTO | AUTO |
| F9 (back-loop to build) | PAUSE | AUTO | AUTO | AUTO |
| F24 (back-loop to spec) | PAUSE | AUTO | AUTO | AUTO |

**Hard rule for AUTO exits.** When this skill's emitted transition is `AUTO` in the current drive mode, the orchestrator **must immediately invoke the next skill via the `Skill` tool**. It must **NOT** return control to the user. Emitting a clean `TRANSITION: F10` followed by a polite narrative summary ("Tests pass; ready to run verify-self") is the regression mode this block exists to prevent (P1 incident, 2026-05-16): the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. **This explicitly includes the `AskUserQuestion` tool (and any other user-input/confirmation prompt): invoking it on an AUTO transition IS "returning control to the user" and is the same regression class as the narrative-summary stop above — do NOT call it to "just confirm" the handoff. The only thing that pauses an AUTO transition is the human-input points the active drive mode's pause policy explicitly marks PAUSE.** See `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## Role and Scope

**verify-auto is a cheap, fast, early-indicator check — not a full QA pass.**

Its job is to catch obvious breakage in the specific code that was just changed: syntax errors, import failures, type errors, and basic smoke behaviour. The checks are temporary and one-off; they may or may not be codified into permanent tests later (that happens in verify-codify).

**Do NOT run the full test suite here.** Running the full suite is slow, catches regressions that belong to other phases, and blurs the signal. verify-auto must be scoped to the change just made.

Concrete examples of appropriate verify-auto checks:
- **Syntax / parse:** `python -m py_compile mymodule.py` or `node --check myfile.js`
- **Lint:** `ruff check mymodule.py` or `eslint src/mycomponent.tsx`
- **Import smoke:** `python -c "from mymodule import MyClass; MyClass()"` — confirms the module loads and the class is instantiable
- **Type check (scoped):** `mypy mymodule.py` or `tsc --noEmit src/mycomponent.tsx`
- **Unit smoke:** run a single targeted test file, not the full suite — e.g. `pytest tests/test_mymodule.py`

## Procedure

### 1. Identify What to Verify
- Read the WIP plan in `workflow/wip/`
- Identify the specific files changed in this build step
- Select 2–4 cheap checks scoped to those files only

### 2. Run Scoped Checks
- **Syntax / lint / import-smoke on the changed files** (respect Docker rules from the project `CLAUDE.md`)
- **Do not run the full test suite** — a single targeted test file is acceptable if it directly exercises the new code
- These checks are intentionally temporary; don't invest in making them permanent

### 3. Evaluate Results

**All tests pass (F10):**
- Update WIP tree: mark `verify-auto` node `[x]`, update `## Current Node`
- Tell user to run `/feature-verify-self <dev-url>` for live-system self-verification (user must supply the URL)

**Tests fail (F9):**
- Document which tests failed and why
- Categorize: is it a code bug or a spec problem?
  - **Code bug:** Tell user to run `/feature-build` to fix (F9)
  - **Spec problem:** If the tests reveal the spec itself was wrong (not just the code), document the discrepancy and tell user to run `/feature-spec` (F24)

### 4. Report
Present a clear summary:
- Tests run / passed / failed
- Any warnings from linters or static analysis
- Recommendation for next step

### 5. Emit Transition
End your output with the canonical transition token so the orchestrator can act on it (the orchestrator reads `TRANSITION: <id>`; the bare slash-command prose above is advisory for single-step users only):

- `TRANSITION: F10` — tests pass, hand off to verify-self
- `TRANSITION: F9` — tests fail (code bug), back-loop to build
- `TRANSITION: F24` — tests reveal spec was wrong, back-loop to spec

**Scope:** {{args}}
