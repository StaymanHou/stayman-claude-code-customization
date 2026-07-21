---
name: debug-bisect-known-good
description: "Debug technique: walk variables from a known-good runner toward a broken one to isolate the cause by addition rather than subtraction. Agent-pulled sidebar, not a workflow state."
argument-hint: <short description of the broken-vs-working pair (which path reproduces the bug, which path is the known-good sibling, what environment they share)>
---

# Debug: Bisect from Known-Good

You are an expert Debugger applying the **known-good bisection** technique to isolate a stubborn bug.

## Category Context

This is a **`debug-*` sidebar skill**, not a workflow state. It is invoked from within an existing workflow state (`feature-build`, `incident-investigate`, `task-act`, or by direct user invocation) when standard straight-line debugging has stalled. It runs to completion and returns control to the caller — the workflow state machine is not affected.

This skill does NOT participate in the F/I/T/P/S transition namespace. Its terminal output emits a `DEBUG-BISECT-*` token (purely for test-harness assertions and human readability) and a `RETURN-TO: <caller>` line so the orchestrator can resume the caller workflow.

## When to use

**Both gates must hold (AND, not OR).** This skill is narrowly applicable; misapplying it wastes time. If either gate fails, exit immediately via the Gate Check in §1.

1. **Primary gate — known-good present.** A structurally similar runner / path / configuration exists in the same environment that **does not exhibit the bug**. The two paths share their host, runtime, language, and most of their dependency surface, but differ in some enumerable set of variables (config keys, code branches, init paths, decorators, framework hooks, etc.). Without a known-good sibling, this technique has no anchor — exit.
2. **Secondary gate — straight-line debug has stalled.** Standard "remove a suspect from the broken path and retest" has been attempted **≥3 times** without converging on a cause. If you have not yet attempted straight-line debug, do that first — bisection's overhead is only worth paying after hypothesis-poor thrashing.

Additional preconditions (soft, not gating):
- The bug reproduces **deterministically** on the broken path. Bisection needs a stable signal between iterations.
- Each iteration is cheap (~30–60 s round-trip). If iterations are slow (long redeploys, costly resources), pay for a tighter hypothesis instead.
- The two paths differ in **more than ~3 variables**. If they differ in only 1–2, just diff them directly — bisection adds no value.

## When NOT to use

- **The two paths are nearly identical.** Just diff them.
- **The bug is flaky / non-deterministic.** Bisection assumes the symptom either reliably appears or reliably doesn't on each tested clone. A flaky bug will produce false stops mid-bisect.
- **Each iteration is expensive.** Bisection's value is cumulative test count. If each step costs you 20 minutes of redeploy + cold-start time, invest in a tighter hypothesis instead.
- **You have a strong specific hypothesis already.** Bisection is for hypothesis-poor situations. If you can name the line of code you suspect, test that directly.
- **No known-good path exists.** Without a working sibling, there's nothing to bisect from. Use other techniques (binary-search the codebase history, minimal reproduction, etc.).

## Procedure

### 1. Gate Check (REQUIRED before any other step)

Before doing anything else, write the following two confirmations to the conversation in **explicit prose** (not just checkbox marks):

```
Gate 1 — Known-good present: <YES / NO>
  Broken path: <name / file / entrypoint of the path that reproduces the bug>
  Known-good path: <name / file / entrypoint of the path that does NOT exhibit the bug>
  Shared environment: <host, runtime, dependency surface — confirm both run in the same env>

Gate 2 — Straight-line attempts ≥3: <YES / NO>
  Attempts made: <brief list of what was tried — e.g., "removed config X, swapped class Y, disabled feature Z">
  Status: <none converged / partial signal but no cause / inconclusive>
```

**If EITHER gate is NO:** Exit immediately. Emit:

```
This bug does not match the bisect-known-good trigger profile because <gate-1-reason | gate-2-reason | both>. Recommended alternatives: <one or two suggestions — e.g., "diff the two paths directly", "try straight-line debug first", "use minimal-reproduction", "binary-search the codebase history">.

TRANSITION: DEBUG-BISECT-SKIP
RETURN-TO: <caller-skill-name, or "user" if directly invoked>
```

Stop. Do not proceed.

**If BOTH gates are YES:** Proceed to §2.

### 2. Backup the Broken Runner

The broken runner stays untouched as the control. Confirm in writing:

```
Broken runner backed up / preserved: <path or commit reference>
```

Do not modify the broken runner during bisection. It serves as the A/B comparison anchor.

### 3. Build B0 — Verbatim Clone Baseline

Create a second runner that is a **byte-for-byte clone** of the known-good runner's launch / setup shape. Register it as a separate job-type / entry point / script so it can be triggered independently of both the broken runner and the production known-good (so production isn't disrupted, and direct A/B is possible).

**Mark the clone TEMPORARY in source** — comment, filename suffix, or convention that signals "this is a bisect throwaway, will be removed."

**Sanity-verify B0 before adding any variables.** Run B0 in the target environment exactly as the known-good would run. Confirm the bug **does not reproduce** on B0. If B0 reproduces the bug, the cause is in the cloned environment / runner shape itself, not in any of the variables you were about to test — escalate per §7 before proceeding.

```
B0 sanity check: <PASS = working-behavior confirmed on clone | FAIL = bug reproduces on the verbatim clone>
```

If FAIL → go to §7. If PASS → proceed to §4.

### 4. Enumerate the Differences

List every variable that differs between the broken runner and the known-good runner. Order them by:
1. If you have priors → outermost-structural-first, innermost-config-last (structural deltas are more likely to be the cause).
2. If you have no priors → any consistent order. Order matters less than people think — what matters is that each step adds **exactly ONE** variable, never two.

Record the enumeration in the conversation:

```
Differences B → A (variables to add to clone, in order):
  V1: <variable name and what it changes>
  V2: <...>
  V3: <...>
  ...
  Vn: <...>
```

### 5. Iterate B1..Bn — One Variable Per Step

For each variable V_i in order:

**Per-step sub-procedure (DO NOT SKIP ANY):**

1. **Apply V_i to the clone.** Bn = B(n-1) + exactly one variable. Never two.
2. **Sync the runner to the target environment.** Whatever deploy / push / file-sync mechanism the project uses.
3. **Restart the process.** Kill any stale in-memory state — stale code in memory produces false positives. If the project runs a long-lived process (worker, server, REPL), restart it. If unsure, restart anyway.
4. **Trigger the runner.**
5. **Observe with a fixed observation window.** Include an explicit `sleep` of ~8s (or equivalent) AT THE END of the runner that fires regardless of wire-level success — including early-exit paths and exception paths. **Wire-level success ≠ symptom resolved.** The observation window is the human-eye check, not the diagnostic dictionary.
6. **Y/N eye-check.** After each step, prompt the operator explicitly:

   ```
   Step B_i (added V_i): symptom reproduces? <Y / N>
   Evidence: <what the eye-check saw — visible symptom, snapshot, log line>
   ```

   Do not rely on wire-level pass/fail. Do not assume "the test passed" means "the symptom is gone."

**First step where the symptom reproduces (Y) = cause. Stop. Do NOT continue adding variables.** Document:

```
Cause located at step B_<i>: <variable V_i>
Mechanism: <what V_i does that triggers the symptom>
Evidence: <eye-check confirmation>
```

Proceed to §6 (Cleanup).

### 6. Cleanup

Cleanup is **planned before iteration starts** — do not leave the bisect runner alive after the cause is found:

- Remove the temporary clone runner (file, job-config entry, deploy registration).
- Remove any backup copies of the broken runner that are no longer needed.
- Restore the production / broken-path code to its original shape (you have not modified it, but confirm).
- Note in the WIP file or conversation: "Bisect runner removed; cause was V_<i>."

Then emit:

```
Bisection complete. Cause: V_<i> — <one-line mechanism>.
Recommended fix surface: <where the actual code change should go in the broken path>.

TRANSITION: DEBUG-BISECT-COMPLETE
RETURN-TO: <caller-skill-name, or "user" if directly invoked>
```

The caller (e.g., `feature-build`) resumes with the cause in hand and applies the fix in the broken path itself.

### 7. No-Converge Escalation

**This branch fires in two cases:**
- B0 sanity check FAILED (§3): the verbatim clone already reproduces the bug, so the cause is in the cloned environment/runner shape itself, not in any enumerated variable.
- All Vn applied, none reproduced the symptom: the cause is not in the structural variable set you enumerated. The cause is likely in something subtler — class instantiation order, config loading mechanism, decorator behavior, base-class attribute lookup, etc.

**Procedure:** Escalate by wrapping the **real broken code** inside the clone harness. Concretely:
- Instantiate the real broken class inside the clone runner.
- Call its real method, with the clone's surrounding setup.
- Keep the observation window (§5 step 5) intact.

If the symptom reproduces inside the wrapper, **bisect inside that** — what differs between calling the real class directly (reproduces) vs the clone's analog (doesn't)?

If even the wrapper does not reproduce the symptom, the cause is beyond what this technique can isolate. Emit:

```
Bisection inconclusive after <N> structural variables + wrapper-escalation. The cause is not in the enumerated variable set or in the direct class-call boundary. Suggested next steps: <one or two — e.g., "diff config-loading paths between the two runners", "instrument the failing line with print statements", "check decorator order on the broken class">.

TRANSITION: DEBUG-BISECT-NO-CONVERGE
RETURN-TO: <caller-skill-name, or "user" if directly invoked>
```

Log a SURFACE entry to `workflow-system/state/backlog.md` summarizing what was tried (for future learning).

## Pitfalls (load-bearing — read before iterating)

1. **The observation window must fire on every code path.** Structure the runner so the human-visible check happens *after* all early-exit and exception paths — not inside a try-block that may be skipped. A common failure mode: an exception fires before the observation point, the runner exits cleanly at wire level, and the operator assumes "no symptom" when in fact the observation never happened.
2. **Wire-level success masks the symptom — this is the #1 failure mode for this technique.** A 200 OK, a passing test, or a clean exit code does NOT mean the symptom is gone. The skill REQUIRES an explicit Y/N eye-check after every step (§5 step 6). Do not skip it. Do not infer from wire-level signals.
3. **Restart the process between iterations.** Stale in-memory code/state produces false positives — you "fixed" the bug by changing code that was never re-loaded. If the project has any persistent process (worker, server, REPL, watcher), restart it. When in doubt, restart anyway.
4. **One variable per step, never two.** This is the load-bearing invariant of the technique. If you add two variables and the symptom flips, you cannot tell which one caused it. Order matters less than people think — what matters is the one-at-a-time discipline.
5. **The cause may not be on your suspect list.** Bisection works by addition, not subtraction — its strength is that it surfaces causes you never hypothesized. Don't pre-filter the enumeration in §4 to "things I think might matter." Include every variable.

## Termination

This skill emits exactly one of the following terminal tokens (test harness asserts on the token; orchestrator uses `RETURN-TO:` to resume the caller):

| Token | Meaning | When emitted |
|-------|---------|-------------|
| `DEBUG-BISECT-START` | Procedure entered (post-Gate Check, into §2+) | After both gates pass and §2 begins — informational for tests that assert the procedure activates |
| `DEBUG-BISECT-SKIP` | Gate Check failed; skill not applicable | Either gate is NO in §1 |
| `DEBUG-BISECT-COMPLETE` | Cause located and cleanup done | §6 |
| `DEBUG-BISECT-NO-CONVERGE` | All variables walked (and wrapper escalation tried), no cause found | §7, after wrapper-escalation also fails |

Every termination must also include a `RETURN-TO:` line naming the caller skill (or `user` for direct invocation) so the orchestrator can resume.

**For long bisects (5+ iterations):** consider writing iteration notes to `workflow-system/state/wip/debug-<short-slug>.md` for traceability — but this is optional. The default is in-conversation only.

**Sidebar discipline:** This skill never advances any workflow state machine. It does not write to feature/incident/task WIP files' `## Current Node` or `## Discoveries` (the caller does that, after resuming, if the bisect outcome warrants it). The only persistent artifact the skill itself MAY create is a SURFACE entry in `workflow-system/state/backlog.md` on the no-converge path (§7).

**Bisect target / pair:** {{args}}
