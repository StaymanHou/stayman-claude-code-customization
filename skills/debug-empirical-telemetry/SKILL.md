---
name: debug-empirical-telemetry
description: "Debug technique: switch from static-analysis debugging to empirical runtime observation — instrument, run, read telemetry, iterate. Agent-pulled sidebar, not a workflow state."
argument-hint: <short description of the stalled bug (what you've tried statically, what runtime values you cannot derive from reading code, what the smallest discriminating observation would be)>
---

# Debug: Empirical Telemetry

You are an expert Debugger applying the **empirical telemetry** technique to break out of a stalled static-analysis debugging loop.

## Category Context

This is a **`debug-*` sidebar skill**, not a workflow state. It is invoked from within an existing workflow state (`feature-build`, `incident-investigate`, `task-act`, or by direct user invocation) when static-reasoning ("read the code, build a mental model, propose a fix") has demonstrably failed to converge on a cause and the bug-shape requires runtime evidence. It runs to completion and returns control to the caller — the workflow state machine is not affected.

This skill does NOT participate in the F/I/T/P/S transition namespace. Its terminal output emits a `DEBUG-TELEMETRY-*` token (for test-harness assertions and human readability) and a `RETURN-TO: <caller>` line so the orchestrator can resume the caller workflow.

Sibling sidebar: `/debug-bisect-known-good` (different stall shape — when a structurally similar known-good path exists in the same environment, bisect one variable at a time from working to broken). Empirical telemetry is the alternative when no known-good sibling exists OR when the bug-shape is timing/race/intermittent/perf/env-dependent rather than structural.

## When to use

**Both gates must hold (AND, not OR).** This skill is narrowly applicable; misapplying it wastes time on instrumentation that doesn't pay off. If either gate fails, exit immediately via the Gate Check in §1.

1. **Primary gate — straight-line debug has stalled.** Standard "read the code, hypothesize a cause, propose a fix" has been attempted **≥2–3 times** on the same bug without converging on a cause. If you have not yet attempted static-reasoning debug, do that first — telemetry's overhead (instrumentation + run + read + cleanup) is only worth paying after hypothesis-poor thrashing.
2. **Secondary gate — bug-shape requires runtime evidence.** The bug's cause cannot be derived from reading the code alone — it requires observing values, timing, or behavior of the running system. Non-exhaustive list of qualifying bug shapes:
   - **Timing / race conditions** — the symptom depends on the order or interleaving of operations.
   - **Intermittent symptoms** — the bug appears 1-in-N runs with no reliably-static trigger.
   - **DB query plans or execution timing** — the symptom is "the query is slow / takes the wrong path" and EXPLAIN/ANALYZE output is needed.
   - **Perf regressions** — the symptom is "this is suddenly slower" and you need timing samples to localize.
   - **Env-dependent state** — the symptom depends on env vars, file presence, network reachability, container state, etc.
   - **"Wrong value at this line"** — a specific variable, attribute, or return value is observably wrong at some point in the flow and reading the code doesn't explain why.

If both gates hold, the procedure activates. If either fails, exit via Gate Check.

## When NOT to use

- **The bug is static-derivable.** A typo, an off-by-one in a literal, an obviously-missing import, a wrong constant, an inverted boolean — reading the code suffices. Do not instrument.
- **You haven't tried straight-line debug yet.** The cost of static-reasoning is one read + one fix. Telemetry's cost is several rounds plus cleanup. Try the cheap path first.
- **You already know the cause from a previous failed-fix attempt.** A known cause doesn't need observation — it needs the right fix.
- **The runtime is unobservable without major scaffolding.** If adding a single log line requires a new build pipeline, a CI cycle, and a deploy, the instrumentation cost dominates the savings. Pick a different technique (offline reproduction, profiling tools the project already integrates with, etc.).
- **The bug has a known-good sibling path in the same environment.** Use `/debug-bisect-known-good` instead — it isolates the cause by structural addition, which is more decisive than blind observation when a working baseline exists.

## Procedure

### 1. Gate Check (REQUIRED before any other step)

Before doing anything else, write the following two confirmations to the conversation in **explicit prose** (not just checkbox marks):

```
Gate 1 — Straight-line debug stalled (≥2–3 failed static-reasoning attempts): <YES / NO>
  Attempts made: <brief list — e.g., "read query builder, checked the WHERE clause is built correctly, traced the param-binding path, confirmed the index exists">
  Status: <none converged / partial signal but no cause / inconclusive>

Gate 2 — Bug-shape requires runtime evidence: <YES / NO>
  Bug-shape category: <timing/race | intermittent | DB query plan/timing | perf regression | env-dependent state | wrong-value-at-line | other (specify)>
  Why static reasoning cannot answer: <one sentence — e.g., "the query plan depends on actual row counts which I cannot derive from the code">
```

**If EITHER gate is NO:** Exit immediately. Emit:

```
This bug does not match the empirical-telemetry trigger profile because <gate-1-reason | gate-2-reason | both>. Recommended alternatives: <one or two suggestions — e.g., "try static-reasoning debug first", "diff the broken path against a known-good sibling via /debug-bisect-known-good", "the cause is likely a typo — re-read the literal strings in the failing path">.

TRANSITION: DEBUG-TELEMETRY-SKIP
RETURN-TO: <caller-skill-name, or "user" if directly invoked>
```

Stop. Do not proceed.

**If BOTH gates are YES:** Emit `TRANSITION: DEBUG-TELEMETRY-START` (informational — the procedure has activated) and proceed to §2.

### 2. Pick the smallest discriminating observable

The mistake is to instrument everything. The discipline is to pick the **single observation that, more than any other, would discriminate between current hypotheses**. Write it down in the conversation before instrumenting:

```
Current hypotheses (from §1 attempts):
  H1: <one sentence>
  H2: <one sentence>
  H3: <one sentence — optional>

Smallest discriminating observable: <what value, at what point, would tell you which hypothesis is correct (or rule them all out)>
Why this observation discriminates: <one sentence>
```

If you cannot name the discriminating observable, your hypotheses are not yet sharp enough — go back to static reasoning to sharpen them. Telemetry's value is in the targeted observation, not in the volume of data.

### 3. Instrument

Add the **smallest instrumentation** that produces the §2 observable. Pick from the technique that fits the runtime:

- **Log/print line** — for a "what is this value at this point" observation. Include enough context (variable name + value + nearby state) that the output is interpretable without re-running.
- **Timing counter** — for "is this slow / when does this fire" observations. Wrap the suspect block with `start = time.now(); ...; print(time.now() - start)` or the language's idiom.
- **State/dict dump** — for "what's the full state of this object at this point" observations. Don't dump everything; dump the keys/attributes your hypotheses depend on.
- **EXPLAIN / ANALYZE / query plan** — for DB-shape bugs. Capture the actual plan, not the assumed one.
- **Breakpoint trace / pdb / debugger** — when the runtime supports it and the bug is reproducible interactively.
- **Perf sampler / profile dump** — for perf regressions when the surface is unclear.

**Mark the instrumentation TEMPORARY in source.** Use a comment marker the cleanup step will grep for — e.g., `# TELEMETRY` or `// telemetry:` — so cleanup is mechanical, not memory-bound.

### 4. Run and read the telemetry

Run the affected path. Read **exactly what the instrumentation produced**.

**Do not infer beyond the observation.** A common failure mode here is to read the telemetry, see a value that "looks fine," and conclude the bug is elsewhere — when in fact the instrumentation was at the wrong point, or the value was fine on that particular run but flaky across runs, or the wire-level success masked the symptom.

Record what was observed:

```
Observed value(s):
  <variable / counter / timing> = <actual value>
  <variable / counter / timing> = <actual value>
  <...>

Discriminates which hypothesis? <H1 confirmed / H2 ruled out / all three ruled out / inconclusive>
```

### 5. Decide

Based on §4:

- **Cause located** (telemetry confirmed a specific hypothesis or surfaced a previously-unhypothesized cause) → proceed to §6 (Cleanup).
- **Inconclusive but a new hypothesis is sharper** → re-enter §2 with the new hypothesis, pick a new smallest discriminating observable, and iterate. Count this as one round.
- **≥3 inconclusive rounds without converging** → proceed to §7 (Inconclusive escalation).
- **Gates no longer hold** (e.g., further attempts reveal the bug actually IS static-derivable, just subtle) → exit with `DEBUG-TELEMETRY-SKIP`, document the realization, and return to the caller.

### 6. Cleanup

Cleanup is **planned before instrumentation starts** — do not leave telemetry in committed code. Stray prints, leftover timing counters, and ad-hoc debug logging at WARN level are real failure modes that have shipped in past work.

**Action list** — for each item that applies, do it:

- Remove or revert temporary log/print lines (grep for the `# TELEMETRY` / `// telemetry:` marker from §3).
- Remove temporary timing counters and the imports/dependencies they introduced (`import time` etc.).
- Remove ad-hoc state/dict dumps.
- Restore any log-level changes (e.g., a DEBUG-level bump → restore to original).
- Delete any scratch files created during instrumentation (sample dumps, profile artifacts, query-plan snapshots).
- Remove or guard any commented-out instrumentation — DO NOT leave dead code as "useful for next time."
- If the project has a lint/format step, run it to ensure no stray formatting/import drift.

**Written checklist** — before emitting any `RETURN-TO:`, write the following confirmation:

```
Telemetry cleanup complete.
  Instrumentation markers removed: <YES — grep for "<your marker>" returns 0>
  Temporary imports removed: <YES / N/A>
  Log levels restored: <YES / N/A>
  Scratch files deleted: <YES / N/A>
  Cause located: <one-sentence summary of what the telemetry revealed>
```

Then emit:

```
TRANSITION: DEBUG-TELEMETRY-COMPLETE
RETURN-TO: <caller-skill-name, or "user" if directly invoked>
```

The caller (e.g., `feature-build`) resumes with the cause in hand and applies the fix at the right surface.

### 7. Inconclusive escalation

After ≥3 rounds of `instrument → run → read` without converging on a hypothesis-discriminating observation, the technique has not paid off for this bug. Do not iterate further — the cost-to-signal ratio is poor and other techniques may apply.

**Procedure:**

1. Run the §6 Cleanup steps anyway — instrumentation should not be left behind even on inconclusive exits.
2. Document the rounds attempted in the conversation (or in `workflow-system/state/wip/debug-<short-slug>.md` if the session was long enough that the trail matters).
3. Emit:

```
Empirical telemetry inconclusive after 3 rounds. Hypotheses considered: <H1, H2, H3, …>. Observed: <one-line summary of what telemetry showed>. The cause was not discriminated by the available observations. Suggested next steps: <one or two — e.g., "try /debug-bisect-known-good if a known-good sibling exists", "binary-search the codebase history with git bisect", "reproduce in an isolated environment with debugger attached", "escalate to incident if production-impacting">.

TRANSITION: DEBUG-TELEMETRY-INCONCLUSIVE
RETURN-TO: <caller-skill-name, or "user" if directly invoked>
```

Log a SURFACE entry to `workflow-system/state/backlog.md` summarizing what was tried (for future learning).

## Pitfalls (load-bearing — read before instrumenting)

1. **Instrumenting too much at once destroys signal.** Pick ONE smallest discriminating observable per round. Adding 10 print statements produces 10 noisy outputs and obscures which one moved the needle. The discipline is targeted observation, not volume.
2. **Skipping the read step.** A common failure mode: the agent instruments, runs, and sees "no crash / wire-level success" and assumes the bug is elsewhere — without ever reading what the instrumentation produced. Wire-level success ≠ symptom resolved. The procedure REQUIRES reading the observed value(s) in §4.
3. **Leaving instrumentation in committed code.** Stray prints in production code is a real, repeated failure mode in past work. The cleanup step is not optional. The pre-exit checklist in §6 catches this.
4. **Inferring beyond the observation.** If the telemetry shows "X = 5" at line N, that is the only fact you have. Do not extrapolate to "and therefore Y must equal Z at line M" without observing Y at M. Sharp observation, sharp inference; loose either and the bug evades you.
5. **Over-iterating past the gates.** The Gate 2 check holds at procedure entry. If after 1–2 rounds you realize the bug is actually static-derivable (e.g., the telemetry surfaced "ah, that literal is misspelled"), exit via Gate-Check-no-longer-holds — don't keep instrumenting for the sake of completeness. The discipline is to exit clean when the procedure's premise no longer applies.
6. **Treating wire-level success as symptom-resolved.** This is the cousin of pitfall #2. A 200 OK, an exit code 0, or a passing test does not mean the symptom is gone. The observation must address the symptom directly, not a proxy for it.

## Termination

This skill emits exactly one of the following terminal tokens (test harness asserts on the token; orchestrator uses `RETURN-TO:` to resume the caller):

| Token | Meaning | When emitted |
|-------|---------|-------------|
| `DEBUG-TELEMETRY-START` | Both gates passed; procedure has activated | After §1 Gate Check confirms both gates YES; §2 begins |
| `DEBUG-TELEMETRY-SKIP` | Gate Check failed; skill not applicable | §1 (either gate NO); or mid-procedure if gates no longer hold |
| `DEBUG-TELEMETRY-COMPLETE` | Cause located via telemetry; cleanup done | §6 |
| `DEBUG-TELEMETRY-INCONCLUSIVE` | ≥3 rounds attempted; no discriminating observation; cleanup done | §7 |

Every termination must also include a `RETURN-TO:` line naming the caller skill (or `user` for direct invocation) so the orchestrator can resume.

**For long telemetry sessions (5+ iterations):** consider writing iteration notes to `workflow-system/state/wip/debug-<short-slug>.md` for traceability — but this is optional. The default is in-conversation only. Same threshold as `/debug-bisect-known-good`.

**Sidebar discipline:** This skill never advances any workflow state machine. It does not write to feature/incident/task WIP files' `## Current Node` or `## Discoveries` (the caller does that, after resuming, if the telemetry outcome warrants it). The only persistent artifacts the skill itself MAY create are: (a) a SURFACE entry in `workflow-system/state/backlog.md` on the inconclusive path (§7), and (b) optional iteration notes in `workflow-system/state/wip/debug-<short-slug>.md` for long sessions.

**Telemetry target / bug:** {{args}}
