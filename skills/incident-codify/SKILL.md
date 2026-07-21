---
name: incident-codify
description: "Incident workflow: codify regression coverage after mitigation — write the test that would have caught this incident (speed-aware), then hand off to resolve"
argument-hint: <incident file name or ID>
---

# Incident Codify

You are an expert Test Engineer hardening the codebase against recurrence of the incident that was just mitigated. Your job is to ensure that **a permanent test now exists that would catch this incident if it happened again** — or to explicitly defer that coverage with a SURFACE backlog entry when speed demands it.

## State Machine Context

You are in the **incident** workflow at the **codify** state, between `mitigate` and `resolve`.

**Valid transitions from here:**
- **I18 → resolve:** Coverage is now in place (existing reproduce artifact passes, OR new test written, OR coverage explicitly deferred with SURFACE entry) → tell user to run `/incident-resolve`
- **I19 → mitigate (back-loop):** Codify-time test still fails → the mitigation didn't actually fix the bug — document the failure, tell user to run `/incident-mitigate`
- **I20 → investigate (back-loop):** Codify-time test reveals the root-cause analysis was wrong (the symptom returns under conditions investigate didn't predict) — document the new evidence, tell user to run `/incident-investigate`

**How this state is reached:**
- **I17 from mitigate:** Mitigation applied, monitoring period passed cleanly. The default path.
- It is **not** reached from fast-close paths (I4 triage→resolve, I7 investigate→resolve) — those have no mitigation and therefore no coverage to write.

**Important semantic flip vs `feature-verify-codify`:**
In the feature workflow, a test failure during codify usually means the new code broke a real contract → auto-fix the code. In the **incident** workflow, a test failure during codify means **the mitigation did not actually fix the underlying bug** → back-loop to mitigate (I19), not auto-fix. Do not paper over a failing regression test by adjusting the test — the test failing IS the signal.

## Procedure

### 1. Load Context

- Read the incident WIP file in `workflow-system/state/wip/`
- Identify:
  - The **mitigation** that was applied (§ Mitigation section)
  - Whether **`## Reproduction Attempt`** is present (i.e. `/incident-reproduce` was run upstream)
  - The **severity** assigned at triage (P0–P3) — this informs speed-vs-thoroughness tradeoff
- Read the project `CLAUDE.md` for testing conventions and Docker rules

### 2. Decide Path Based on Reproduce Artifact

**Path A — Reproduce artifact exists (failing test from `/incident-reproduce`):**

The test was written when the bug was live; it was failing. After mitigation, it should now pass. Run it and confirm:

- If it **passes** → the artifact IS your regression test. Skip to §4 (Integration-boundary check) for any consuming-surface coverage that may be needed in addition.
- If it **fails** → the mitigation did not actually fix the bug. Go to §3b (triage). Default classification: **mitigation regression** → back-loop to mitigate (I19).

If the reproduce artifact was a **manual recipe** (not a test) or **telemetry signature** (not a test), it cannot serve as a CI regression test. Treat as Path B but acknowledge the artifact in the WIP file as supporting evidence.

**Path B — No reproduce artifact (incident skipped reproduce, or reproduce was telemetry-only/recipe-only):**

You need to write coverage from scratch. Continue to §3.

### 3. Choose Test Level — Highest-Level Test That Catches This Incident

For the behavior that was broken, choose the **highest-level test type** that still runs reliably in CI:

1. **End-to-end / scenario test** (preferred for user-facing incidents) — exercises the broken behavior from the outside, the way the affected users/clients did. Examples: HTTP request against the real endpoint that was failing, Playwright interaction against the affected page, CLI command against the affected interface.
2. **Integration test** — if the behavior involves multiple components but can't be exercised end-to-end without excessive setup.
3. **Unit test** — only if the broken behavior is purely internal and unreachable from a higher level.

**Do not default to unit tests** just because they are easier. A unit test that passes while the user-visible failure is still triggerable is not real regression coverage.

**Speed-aware: minimum viable coverage.** An incident is time-sensitive. The goal is **one test that would have caught this specific incident** — not a broader sweep of adjacent coverage. If you notice adjacent gaps, log them as SURFACE entries (§6) and move on; do not block resolve on writing them now.

### 4. Integration-Boundary Check

Determine whether the mitigation modified code inside an existing HTTP endpoint, route, UI surface, CLI command, scheduled job, or external-system call.

- **If a boundary applies:** the test must exercise the **consuming surface by name** and assert the post-mitigation behavior. A unit test on the modified internal function does **not** satisfy this — the consuming-surface test is what catches the regression at the layer the incident manifested at. Cite the surface explicitly in the WIP file (e.g. "test `test_api_v2_users_returns_200_with_null_profile_image`").
- **If no boundary applies** (mitigation was a config flip, a constant change, a data backfill, or otherwise an isolated artifact): note "No integration boundary — mitigation is isolated" in the WIP file and proceed without a consuming-surface test.

### 5. Write or Confirm the Test, Then Run All Tests

- Path A (artifact passes): no new test needed unless integration-boundary check (§4) demands a consuming-surface test that the existing artifact does not exercise.
- Path B (writing from scratch): write the test in the appropriate test file, following project conventions. Confirm it passes against the mitigated code.
- Run the **full test suite** (not just the new test) to ensure the mitigation did not regress anything else. Respect Docker rules from project `CLAUDE.md`.

### 5b. Test Failure Triage

**If any test fails during §5, you MUST classify the failure before taking any action.** Do not fix code, modify tests, or re-run without completing this step first.

#### Classification table (incident-context)

| Classification | Confidence | Action |
|---|---|---|
| **Mitigation regression** — the codify test (Path A artifact or new Path B test) fails, asserting the bug is still present | High | **Back-loop to mitigate (I19)** — mitigation didn't fix the bug. Document and exit. Do NOT auto-fix. |
| Mitigation regression | Low / ambiguous | Write triage artifact, pause for human |
| **Root-cause misdiagnosis** — codify-time evidence reveals the bug has different conditions than investigate concluded | Any | **Back-loop to investigate (I20)**. Document new evidence. Do NOT auto-fix. |
| Unrelated regression — full-suite run failed on a test unrelated to this incident, but new mitigation broke it | High | Auto-fix code (the mitigation introduced a side effect), then re-run |
| Unrelated regression | Low / ambiguous | Write triage artifact, pause for human |
| Obsolete test — pre-existing test asserted behavior the mitigation legitimately changed | High | Auto-update or delete the obsolete test (with one-line rationale in WIP), then re-run |
| Obsolete test | Low / ambiguous | Write triage artifact, pause for human |
| Contract conflict — mitigation and an existing test both assert valid-looking but incompatible contracts | Any | Always write triage artifact and pause |
| Flaky test — failure unrelated to this incident; inconsistent across runs | — | Re-run up to 2 retries (3 total); if still failing, write triage artifact and pause |

**High confidence** means: the failure has exactly one plausible explanation, stateable in one sentence without hedging. Any doubt → low/ambiguous.

**Hard rule: no test file may be modified or deleted without a completed `## Test Triage — <test name>` entry in the WIP file** (same format as `feature-verify-codify`). For mitigation-regression and root-cause-misdiagnosis cases, the triage entry replaces the action — do not also modify code.

### 6. Speed-Aware Defer Path (optional)

**When to use:** the incident is P0 or has unusual time pressure (e.g., active customer escalation, monitoring period must remain short), the mitigation is genuinely confirmed (Path A artifact passes OR human attests the user-visible symptom is gone), AND writing coverage now would delay all-clear by a meaningful amount.

**What it requires (audit trail):**
1. Add a `## Codify — Deferred` section to the WIP file with:
   - **Reasoning:** one-paragraph human explanation of why codify is being deferred now (must be written, not implicit).
   - **Severity at time of defer:** P0/P1/P2/P3.
   - **Symptom-confirmation source:** what makes you confident the bug is gone without a regression test (telemetry pattern, customer confirmation, etc.).
2. Append a `SURFACE-<YYYY-MM-DD>` entry to `workflow-system/state/backlog.md` targeting `task:plan` (or `feature:spec` if the test scope is non-trivial):

```markdown
## SURFACE-<YYYY-MM-DD>-CODIFY-DEFERRED-<incident-name>
- **Source:** incident:codify (deferred path)
- **Target level:** task:plan
- **Type:** tech-debt (missing regression test)
- **Summary:** Regression test for <incident> was deferred during active incident response.
- **Context:** <one line — link to incident archive file>
- **Suggested action:** Write the test that would have caught <incident>. Confirm it fails against the pre-mitigation code (git revert in a scratch branch) and passes against post-mitigation code.
- **Priority:** medium
- **Status:** pending
```

3. Take the **I18 defer path** — exit to resolve. Codify is "done" only in the sense that a SURFACE entry now owns the coverage debt.

**Note on conditional pause:** When the orchestrator runs codify, it pauses **only if** you took Path B (wrote new coverage from scratch) — human reviews the new test before resolve. If Path A (reproduce artifact already passes) or §6 defer, the orchestrator chains directly to resolve (AUTO). This is documented in `agents/incident-workflow/AGENTS.md` → pause policy table. You do not control the pause; you control which path you took, and the orchestrator follows.

### 7. Update Incident Report

Add a `## Codify` section to the WIP file with:

- **Path:** A (reproduce artifact) | B (new coverage) | Deferred
- **Test(s):** path(s) to test file(s) and test function name(s), OR reference to SURFACE backlog entry if deferred
- **Integration boundary:** consuming surface name + test that exercises it, OR "no boundary"
- **Full suite result:** passed | passed-with-unrelated-fixes-triaged | failed-back-loop

### 8. Evaluate Outcome and Hand Off

**Coverage in place (I18) — all tests pass:**
- Tell user to run `/incident-resolve`. Codify is complete.

**Deferred (I18 defer path):**
- Tell user to run `/incident-resolve`. SURFACE entry now owns the debt; resolve will sweep backlog on close.

**Mitigation regression (I19):**
- Document the failed test and what it asserts. Tell user to run `/incident-mitigate` to re-fix. The codify test stays in place — it is the new verify gate for the next mitigation attempt.

**Root-cause misdiagnosis (I20):**
- Document the new evidence that contradicts the prior investigation. Tell user to run `/incident-investigate` to re-analyze.

Emit the transition ID at the end of your output (the orchestrator reads `TRANSITION: <id>`).

**Single-step mode only:** STOP after writing the codify section and emitting the transition. The incident workflow runs as Mode 2 (Orchestrated) regardless of session drive mode — human judgment is non-negotiable. Per pause policy: I18 (coverage in place, Path A or defer) is AUTO; I18 (Path B, new test written) is PAUSE; I19 and I20 are PAUSE (back-loops to mitigate or investigate require human acknowledgment).

**Incident:** {{args}}
