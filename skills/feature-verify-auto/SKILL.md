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

**Scope:** {{args}}
