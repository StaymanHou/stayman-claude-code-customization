# Feature: PP4 — verify-codify Test Triage Gate

**Workflow:** feature
**State:** spec
**Created:** 2026-05-02
**Entry:** spec (complex feature)

## Problem Statement

When `verify-codify` runs the full test suite and a test fails, the agent implicitly decides to fix the code, update the test, or re-run — without stating its reasoning, without a written artifact, and without escalating ambiguous cases to the human.

A test modification is higher-stakes than a code change: it removes a specification artifact, not just an implementation detail. The current workflow applies no asymmetric scrutiny to test changes, has no audit trail for triage decisions, and provides no escalation gate for cases where the correct action is ambiguous.

## User Stories

- As a user, when `verify-codify` hits a failing test, I want to see the agent's classification and reasoning written to the WIP file before it touches anything, so I can audit or override the decision.
- As a user, I want the agent to auto-resolve only high-confidence obvious cases (clear code regression, clearly obsolete test), and pause for my input on everything ambiguous or conflicting.
- As a user, I want flaky tests to be re-run rather than "fixed," and escalated to me after 3 total failed runs.

## Acceptance Criteria

- When any test fails at `verify-codify`, a `## Test Triage — <test name>` block is written to the WIP file before any code or test file is modified
- The triage block contains: classification (spelled out), confidence (high/low/ambiguous), evidence (one sentence pointing to specific cause), action (what was done or what is awaiting approval)
- No test file may be modified or deleted without a completed triage block present in the WIP file
- Classification → action mapping:
  - Code regression, high confidence → agent auto-fixes code
  - Code regression, low/ambiguous → agent pauses for human
  - Obsolete test, high confidence → agent auto-updates/deletes test
  - Obsolete test, low/ambiguous → agent pauses for human
  - Both sides valid (contract conflict requiring product judgment) → agent always pauses regardless of confidence
  - Flaky test (inconsistent across re-runs) → agent re-runs up to 2 retries (3 total); if still failing, agent pauses
- "High confidence" defined as: agent can point to a specific line in new code or the test that unambiguously explains the failure, with no plausible alternative reading

## Out of Scope

- Applying the triage gate to `verify-auto` or `verify-self` — the problem manifests at `verify-codify` (full suite); earlier steps run scoped checks and rarely hit unexpected failures
- Changes to the task workflow or any non-feature workflow
- New workflow states or transitions

## Technical Constraints

- Skill prompts are advisory, not enforced by hooks. The triage gate is prompt-engineering only; if it proves unreliable in practice, structural enforcement is a future WP.
- The fix lives in `feature-verify-codify/SKILL.md` and test scenarios only. No changes to other skills.
- Three files govern the state machine and must stay in sync: `docs/product/transitions.md`, per-skill `SKILL.md`, `tests/scenarios/*.yaml`.

## Open Questions

- (none)
