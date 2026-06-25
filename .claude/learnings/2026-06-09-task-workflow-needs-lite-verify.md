---
date: 2026-06-09
scope: global
type: Skill
session-ref: task:close run-all-unbound-forward-args
---

# Task workflow needs a lite verify step between act and close

## Summary
The current task workflow (plan → act → close) has no verify gate. This relies on
the implicit assumption that tasks are atomic enough that "act = verify" — but
this is empirically false even for trivial 2-line shell fixes. On 2026-06-09,
task `run-all-unbound-forward-args` planned as a one-line shell fix surfaced a
second pre-existing bug ONLY because the user mid-act directed "verify the test
still works before closing." Without that override, a script that still didn't
run end-to-end would have shipped with a passing close. The feature workflow has
a 5-step verify chain (`verify-auto → verify-self → verify-human → verify-codify`)
specifically because "the agent built it and it compiles" ≠ "it actually works
end-to-end" — that same property holds for tasks, just at smaller scale.

## Suggested change
Skill (global): add `task-verify` as a new state between `task-act` and `task-close`.

**Sketch:**
- **Single step**, not a 5-leaf chain. Tasks are atomic; the full feature ceremony
  (Observable Outcomes at plan time, separate auto/self/human/codify leaves) is
  overhead, not signal.
- **Procedure:**
  1. **State the observable in writing.** Before running anything, write into the
     WIP "What observable confirms the fix worked?" — analogous to feature
     Observable Outcomes but inline at verify time, not at plan time. This forces
     commitment to a verification surface, preventing implicit-`--dry-run`-shrug.
  2. **Run the verification.** Real invocation against the observable. Not a
     proxy (no `--dry-run` if the bug lives outside the dry-run path; no
     compile-check if the bug lives at runtime).
  3. **Classify the result:** PASS / FAIL / SURFACED-sibling-bug.
- **Pause policy** (analogous to feature workflow's verify-self):
  - PASS → AUTO in single-step / orchestrated / autopilot / full-autopilot → /task-close
  - FAIL → PAUSE; scope-restricted back-loop to task-act (analogous to F9b → F8)
  - SURFACED-sibling-bug → AUTO-absorb if it's a trivial extension in the same
    file with the same bug-family (the same shape the just-shipped
    `verify-self-in-place-fix-shortcut-policy` codifies for feature-verify-self),
    else SURFACE to backlog and proceed.

**New transitions:**
- T5 (currently `act → close`) splits into:
  - T5a: `act → verify` (always)
  - T5b: `verify → close` (PASS, AUTO)
  - T5c: `verify → act` (FAIL, scope-restricted back-loop)

**Files that would change in a feature-spec implementation:**
- New `skills/task-verify/SKILL.md`
- `skills/task-act/SKILL.md` (transition from T5 → T5a; "tell user to run /task-verify")
- `skills/task-close/SKILL.md` (entry precondition becomes "task-verify PASSed")
- `agents/task-workflow/AGENTS.md` (add task-verify to skills frontmatter; update orchestration procedure)
- `docs/product/transitions.md` (new T5a/T5b/T5c rows; old T5 retired)
- `tests/scenarios/task.yaml` (new T5b PASS scenario; T5c FAIL scenario)
- `tests/check-structure.sh` (new structural pins on the new skill's required sections)

**Open design questions** (for the feature-spec to resolve):
- Should task-verify support an auto-skip path when the task is a pure-docs edit
  (no code changes, nothing to run)? Argues yes — would otherwise add ceremony
  to backlog-status updates and CLAUDE.md prose edits. Argues no — even docs
  edits can have a verification ("the markdown renders", "the link resolves").
  Probably yes-with-explicit-gate (`docs-only: true` declared at plan time).
- How does task-verify interact with T7/T8 SURFACE? If verify surfaces something
  bigger than the task scope, does it escalate via T9 or just SURFACE-to-backlog
  and continue?
- Plan-time vs verify-time: should the observable be declared at plan time (like
  feature Observable Outcomes) or at verify time? Verify time is lower ceremony;
  plan time would prevent the "I'll figure out verification when I get there"
  failure mode but adds plan-step friction. Empirically this session's task plan
  *did* state a verification — but stated it too narrowly. So plan-time
  declaration doesn't help if the declaration itself is wrong; only verify-time
  commitment-to-observable forces the planner to face the question with full
  context.

## Session-log excerpt
User mid-act directive: "continue, don't return control to me. make sure verify
the test still works after the change before closing it."

This one sentence over-rode the plan's narrower verification path (which would
have been satisfied by `--dry-run`) and was the direct cause of T1b surfacing.
The reflection scope is broader than this incident: the gap is structural, not
operator-specific. A workflow-level fix removes the dependency on the user
catching the right moment with the right directive.
