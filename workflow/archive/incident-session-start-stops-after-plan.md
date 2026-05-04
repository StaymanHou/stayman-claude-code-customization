# Incident: session-start stops after feature-plan instead of chaining to build

**Workflow:** incident
**State:** report
**Created:** 2026-05-04 00:00
**Severity:** TBD (set during triage)
**Status:** Investigating → False Alarm

## Summary

User ran `/session-start` with explicit instruction to drive WP3 end-to-end. The model correctly:
1. Classified the work as Feature (small/simple → feature-plan)
2. Asked for confirmation and received "Yes, drive it end-to-end"
3. Invoked `feature-plan` via Skill tool and wrote the WIP file

Then **stopped**. The final output read: `Run /feature-build to start Phase 1.` — the single-step prose from the skill — and the session ended without chaining to `feature-build`. The user was dropped at the prompt.

This is directly contrary to the `session-start` and feature-workflow orchestration procedure, which says:
- `feature-plan` → `feature-build` is **AUTO** (no pause required)
- The model must NOT treat `"Run /feature-build"` prose as a stop signal; it is for single-step users only
- End-to-end driving means the orchestrator chains immediately after `feature-plan` completes (F7 transition)

## Initial Observations

- The model correctly loaded `session-start` and classified work
- The model correctly invoked `feature-plan` via Skill tool
- The model did NOT read `agents/feature-workflow/AGENTS.md` after the plan was approved — the transcript shows no such read
- The model appears to have acted on the prose output of `feature-plan` (`"Run /feature-build"`) rather than treating it as a machine transition to chain through
- After user confirmed "Yes, drive it end-to-end," the model proceeded to plan but did not re-consult the orchestrator's pause policy for the next step

## Hypotheses

- **H1 — Missing orchestrator read:** `session-start` step 4 says "Load the orchestration procedure — Read `agents/<workflow>-workflow/AGENTS.md`." The model may have skipped this step, causing it to have no pause-policy table and defaulting to treating all skill output prose as stop signals. (unverified)
- **H2 — Prose-as-command confusion:** Even if the orchestrator was read, the model may have weighted the `"Run /feature-build"` prose output from the skill over the orchestrator's AUTO policy, treating it as a user-facing instruction to itself. (unverified)
- **H3 — Context loss at skill boundary:** The Skill tool invocation may reset or de-prioritize prior orchestrator context, causing the model to forget the AUTO-chain policy after returning from the skill. (unverified)
- **H4 — feature-plan SKILL.md emits a strong stop signal:** The skill's output text ("Run /feature-build to start Phase 1") may dominate the model's next-token decision, overriding the orchestrator procedure that lives in AGENTS.md. (unverified)

## Investigation — 2026-05-04

### Observed Facts

1. **`feature-plan/SKILL.md` line 148–151 contains an explicit hard stop:**
   ```
   ### 6. Hand Off
   Tell the user to run `/feature-build` to start Phase 1.
   **STOP** — do NOT start implementing.
   ```
   This `**STOP**` directive is absolute prose aimed at single-step users, but it is embedded in the skill prompt the model executes — making it indistinguishable from an orchestrator-level stop signal.

2. **`session-start/SKILL.md` step 4 says:** *"Do not treat the prose 'Run /feature-x' in skill output as an instruction to stop — that text is for users invoking skills directly."* This counter-instruction exists but competes directly with the in-skill `**STOP**` directive.

3. **The transcript shows no read of `agents/feature-workflow/AGENTS.md`** after `feature-plan` completed. The orchestrator's pause-policy table (which marks `feature-plan` as PAUSE and `feature-build` as AUTO) was never consulted post-skill.

4. **`feature-plan` is marked PAUSE** in the orchestrator's pause-policy table (`AGENTS.md` line 135). Per the pause policy, `feature-plan` is a legitimate stop point — the user must approve the phase breakdown before build starts. The observed behavior (stopping at plan) was therefore **correct per the policy**.

5. **The user's expectation** was that "Yes, drive it end-to-end" meant building immediately. But `session-start` confirms once before starting the workflow — it does NOT skip the intermediate PAUSE points defined by the orchestrator. The orchestrator deliberately pauses at `feature-plan` for human approval.

6. **No missing AGENTS.md read:** Even if the model had read AGENTS.md, the pause policy says `feature-plan → PAUSE`. The model would still have stopped at the same point.

7. **No test gap for this exact scenario:** The existing S7–S9 scenarios test mid-workflow AUTO/PAUSE behavior but there is no scenario asserting that plan→build chains automatically in end-to-end mode. This is consistent with the PAUSE policy being correct — there's nothing to test because stopping at plan IS the expected behavior.

### Hypotheses — Final Status

- **H1 — Missing orchestrator read:** REJECTED. Even with the orchestrator read, `feature-plan` is a PAUSE step. The behavior would be identical.
- **H2 — Prose-as-command confusion:** PARTIALLY CONFIRMED but as contributing factor only. The `**STOP**` in SKILL.md reinforces the PAUSE-step behavior. Not a bug.
- **H3 — Context loss at skill boundary:** REJECTED. Not the root cause — PAUSE policy would cause the same stop regardless.
- **H4 — feature-plan emits a strong stop signal:** CONFIRMED as a design intent, not a bug. The `**STOP**` is there to prevent the model from immediately starting to code after planning. Correct behavior in single-step mode; aligns with PAUSE policy in orchestrated mode.

### Root Cause

**This is a false alarm / user expectation mismatch, not a bug.**

The model behavior was correct:
- `feature-plan` is a PAUSE step per `agents/feature-workflow/AGENTS.md` (line 135).
- The orchestration procedure correctly paused after plan for user approval of the phase breakdown before build starts.
- "Yes, drive it end-to-end" confirms end-to-end driving — it does NOT skip the intermediate PAUSE checkpoints embedded in the orchestrator procedure.

The confusion arose because the user expected "end-to-end" to mean "no stops at all." The orchestrator has 4–5 mandatory human pauses per feature (plan approval, verify-human per phase, finalize). These are by design.

**What the model should have done differently (minor UX improvement):** After stopping at `feature-plan`, it should have been more explicit: *"Plan complete — this is a required review checkpoint before build starts. Approve the plan above to chain to build."* Instead it just showed the plan and dropped to the prompt, leaving the user unclear whether this was intentional or a failure.

## Timeline

- 2026-05-04 — Incident reported via `/incident-report`
- 2026-05-04 — Investigation complete: false alarm (correct behavior, UX communication gap)
