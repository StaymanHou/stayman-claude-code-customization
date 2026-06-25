---
date: 2026-05-13
scope: global
type: Skill
session-ref: WP9.6 amazon-affiliate window-invisibility debug
---

# Known-good bisection: walk variables from a working runner toward a broken one

## Summary
When a bug reproduces on path A but not on a structurally similar path B in the
same environment, and straight-line "remove a suspect from A and retest" has
already failed multiple times to converge, a more reliable technique is to build
a temporary clone of B (the known-good path) as a sibling runner, then add A's
distinguishing variables to the clone one at a time, restarting and re-observing
between each step. The first variable that flips the symptom identifies the
cause — and because the cause is found by *addition* rather than *subtraction*,
the technique can surface causes that weren't on the original suspect list.
In a real run this isolated a silent attribute-lookup miss that no straight-line
attempt would have found, because the buggy convention wasn't part of any
"different thing about the broken path" hypothesis.

## Suggested change
Skill (global): `bisect-known-good` (or similar).

**When to use:**
- A bug reproduces on one runner/path and not on a structurally similar one in
  the same environment
- Straight-line "remove suspect, retest" on the broken path has failed two or
  more times without converging
- The two paths differ in more than ~3 variables (i.e., you can't just visually
  diff)
- Each iteration is cheap (~30–60s round-trip) — bisection's value is in
  cumulative test count
- The bug reproduces deterministically (bisection needs a stable signal)

**When NOT to use:**
- The two paths are nearly identical (just diff them)
- The bug is flaky / non-deterministic
- Each iteration is expensive (long redeploys, costly resources) — pay for a
  tighter hypothesis instead

**Procedure sketch:**
1. **Backup the broken runner**, untouched, so it remains available as control.
2. **Create a second runner** that's a byte-for-byte clone of the known-good
   runner's launch / setup shape. Register it as a separate job-type / entry
   point so it can be triggered independently and the production path stays
   runnable for direct A/B.
3. **Enumerate the differences** between the two paths — every variable, no
   matter how innocuous. Order them roughly by suspicion if you have priors;
   otherwise outermost-structural-first, innermost-config-last.
4. **Iterate B0..Bn**, adding *exactly one* variable per step. B0 is the
   verbatim clone (sanity-check the baseline before adding anything). Each
   subsequent Bn adds one variable to B(n-1).
5. **Between every step:** sync the runner to the target environment, restart
   the process (kill stale in-memory state), trigger, observe.
6. **Always include a fixed observation window** (e.g. an explicit `sleep` of
   ~8s) AT THE END of every step. The observation must fire **regardless** of
   wire-level pass/fail — early-exit on a 404 or an exception must still hit
   the sleep. Wire-level success ≠ human-eye success.
7. **First step where the symptom reproduces = cause.** Stop there. Don't
   continue adding variables.
8. **If you walk through every structural variable without reproducing:** the
   cause is elsewhere (class instantiation, config loading, etc.). Escalate by
   wrapping the *real* broken code inside the harness (instantiate the real
   class, call its real method) — keeping the observation window. Then bisect
   inside that.
9. **Cleanup is planned before the first iteration.** The bisect runner is
   throwaway; mark it TEMPORARY in source, and remove it (plus job-config
   entries and backups) the moment the cause is found.

**Pitfalls to encode in the skill:**
1. The observation window must fire on every code path. Structure the
   runner so the human-visible check happens *after* all early-exit paths.
2. Wire-level success masks the symptom in the most common failure mode for
   this technique. The skill should explicitly prompt the operator with a Y/N
   eye-check after every step, not rely on diagnostic-dict contents.
3. Restart the process between iterations. Stale in-memory code = false
   positives. The skill should include this in the per-step procedure.
4. Order matters less than people think; what matters is that each step adds
   ONE variable, never two.

## Session-log excerpt (optional)
A run on 2026-05-13 isolated a Playwright window-invisibility bug across 7
bisect steps (B0–B6 walked structural deltas; B7 was an inspection-only step
that printed the cause). Cause: an attribute-name mismatch in a base-class
config lookup that silently defaulted `headless` to True. Total time from
opening the harness to identifying the cause: ~12 minutes. Prior straight-line
debugging in the same session (Attempts 1–7) had not converged after ~2 hours.
