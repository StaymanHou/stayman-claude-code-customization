---
name: debug-minimal-harness
description: "Debug technique: when a behavioral fix has been handed back ≥2× and the behavior is drivable in a surface you control, build a minimal standalone reproduction and drive it yourself with REAL input until it works — before re-presenting to the human. Agent-pulled sidebar, not a workflow state."
argument-hint: <short description of the stalled behavioral bug (the interaction/behavior, how many times it's been handed back, and what surface you could drive it in — browser/DOM, CLI, HTTP, concurrency)>
---

# Debug: Minimal Self-Driven Harness

You are an expert Debugger applying the **minimal self-driven harness** technique to stop handing a behavioral fix back to the human untested, and instead reproduce it yourself.

## Category Context

This is a **`debug-*` sidebar skill**, not a workflow state. It is invoked from within an existing workflow state (`feature-build`, `incident-investigate`, `task-act`, or by direct user invocation) when a **behavioral** bug (an interaction, a gesture, a command's observable effect, a request/response, a race) has been **fixed-and-handed-back two or more times without confirmation**, AND the behavior is **drivable in a surface the agent can control** — even when the shipping target is one the agent cannot attach to. It runs to completion and returns control to the caller — the workflow state machine is not affected.

This skill does NOT participate in the F/I/T/P/S transition namespace. Its terminal output emits a `DEBUG-MINHARNESS-*` token (for test-harness assertions and human readability) and a `RETURN-TO: <caller>` line so the orchestrator can resume the caller workflow.

**Sibling sidebars — pick the right one:**
- `/debug-bisect-known-good` — a structurally similar **known-good path** exists in the same environment; isolate the cause by adding the broken path's distinguishing variables one at a time. Use it when the discriminator is "what differs between the working sibling and the broken one."
- `/debug-empirical-telemetry` — no known-good sibling; the bug-shape requires **observing the running system** (timing/race, intermittent, query plan, perf, env-dependent state, wrong-value-at-line) via instrument → run → read.
- **This skill (`debug-minimal-harness`)** — the distinguishing trigger is **repeated hand-back on a self-drivable behavior**. You keep handing the fix to the human because "only they can run it," but the underlying logic is in fact drivable in a surface you control (a browser/DOM page, a CLI under real argv/stdin, an HTTP endpoint under a real client, a race under real concurrency). The move is to **stop handing back, reduce the behavior to a minimal standalone reproduction, and drive it yourself with REAL input** until it works.

## When to use

**Both gates must hold (AND, not OR).** This skill is narrowly applicable; building a reproduction harness has a real cost, only worth paying once you've thrashed via hand-back. If either gate fails, exit immediately via the Gate Check in §1.

1. **Primary gate — self-drivable surface.** The behavior runs in a surface you can drive yourself, even if it is NOT the production surface:
   - **Interactive UI** (the canonical case) — drag, click, focus, keyboard, hover, gesture. Even when the shipping target is a native app you can't attach to (Tauri WKWebView, Electron, a mobile webview), the **same web/DOM logic almost always runs in a dev/browser page Playwright can drive**. "The product ships native" is NOT a reason this gate fails — ask "is this logic drivable in a browser/surface I control?"
   - **CLI behavior** — the command misbehaves under real argv/stdin/exit-code/TTY conditions; you can invoke the real binary yourself with real arguments.
   - **HTTP behavior** — the endpoint misbehaves under a real client request (headers, body, status, streaming); you can drive a real request, not a mocked handler call.
   - **Concurrency / race** — the symptom appears under real concurrent input you can generate (parallel requests, multiple drivers, real threads/processes).
   - If the behavior is genuinely undrivable by you (hardware/embedded signal, a third-party system you cannot invoke, a sensor/peripheral, a behavior that only exists in a closed environment you have no access to), this gate **fails** — use a different technique or accept that human verification is unavoidable.

2. **Secondary gate — repeated hand-back (≥2).** You have already **failed or handed the fix back to the human at least twice on the same behavior** — e.g., "fixed, please verify" → rejected → "fixed again, please verify" → still broken. One hand-back is normal collaboration; the **second** is the trigger signal that you are guessing-and-deferring instead of observing. If you have handed back fewer than twice, do the cheap thing first (one more careful read + targeted fix). The harness's cost is only justified once the hand-back loop has demonstrably stalled.

If both gates hold, the procedure activates. If either fails, exit via Gate Check.

## When NOT to use

- **You haven't handed the fix back twice yet.** The first hand-back is normal. Don't build a harness for a bug you've attempted once — try a careful read + targeted fix first.
- **The behavior is genuinely undrivable by you.** A hardware peripheral, a closed third-party system, a sensor, a behavior that only manifests in an environment you have no access to. If you truly cannot drive any faithful surface, this technique offers nothing — human verification is the path.
- **The bug is static-derivable.** A typo, an obvious off-by-one, a wrong constant, an inverted boolean visible by reading the line. Reading the code suffices — don't build a harness.
- **A known-good sibling exists in the same environment.** Use `/debug-bisect-known-good` — isolating by addition from a working baseline is more decisive than reproducing from scratch.
- **The bug-shape is observe-the-running-system (timing/race with no driver, perf, query plan, intermittent with no reliable trigger) and you do NOT need to reproduce an interaction.** Use `/debug-empirical-telemetry`. (Note: if the race IS drivable by you with real concurrent input, this skill applies — the distinction is whether you can *drive* it, not just *observe* it.)

## Procedure

### 1. Gate Check (REQUIRED before any other step)

Before doing anything else, write the following two confirmations to the conversation in **explicit prose** (not just checkbox marks):

```
Gate 1 — Behavior is drivable in a surface I control: <YES / NO>
  Behavior: <one line — e.g., "filmstrip tile drag-reorder">
  Shipping surface: <e.g., "Tauri WKWebView native app — I cannot attach Playwright to it">
  Drivable surface I CAN control: <e.g., "the same React/DOM component runs under Vite at localhost:1420, drivable with a real Playwright mouse"> | <"none — the behavior is <reason undrivable>">

Gate 2 — Already handed back / failed ≥2× on the same behavior: <YES / NO>
  Hand-back count: <N>
  What was handed back each time: <one line per attempt — e.g., "1: 'fixed, only moves right'; 2: 'fixed symmetry, still won't reorder'">
```

**If EITHER gate is NO:** Exit immediately. Emit:

```
This bug does not match the minimal-self-driven-harness trigger profile because <gate-1-reason | gate-2-reason | both>. Recommended alternatives: <one or two — e.g., "hand back once more after a careful read — only 1 prior attempt", "the behavior is genuinely undrivable (hardware) — human verification is the path", "a known-good sibling exists → /debug-bisect-known-good", "this needs runtime observation, not reproduction → /debug-empirical-telemetry">.

TRANSITION: DEBUG-MINHARNESS-SKIP
RETURN-TO: <caller-skill-name, or "user" if directly invoked>
```

Stop. Do not proceed.

**If BOTH gates are YES:** Emit `TRANSITION: DEBUG-MINHARNESS-START` (informational — the procedure has activated) and proceed to §2.

### 2. Reduce to a minimal standalone reproduction

The mistake is to keep debugging inside the full app. The discipline is to **extract the misbehaving logic into the smallest standalone artifact that still exhibits the bug** — a throwaway hello-world you fully control. Write down the plan before building:

```
Minimal repro plan:
  Surface: <browser page under Vite/a static HTML file | a tiny CLI invocation | a curl/httpie request | a small concurrent driver script>
  What it includes: <the suspect component/function + the minimum scaffolding to exercise it>
  What it strips: <everything not implicated — auth, routing, unrelated state, the native shell>
  How I'll drive it: <the REAL input mechanism — see §3>
  What "reproduced" looks like: <the observable failure the human reported, restated as something I can see in my harness>
```

Keep it in a scratch location (e.g. `/tmp/<slug>` or a throwaway dev route) — this artifact is **deleted in §5 cleanup**, it does not ship.

If you cannot reduce the behavior to a standalone artifact, the surface may not actually be drivable by you — re-examine Gate 1. The whole value of this technique is in the *reduction + self-driving*; a repro you still can't run yourself is not a repro.

### 3. Drive it with REAL input — never synthetic dispatch

This is the **load-bearing step**. Drive the reproduction with a **real input device / real I-O**, not a synthetic event dispatched on a held reference:

- **UI:** `page.mouse.down/move/up`, `page.keyboard.press`, real Playwright clicks/drags against the served page. NOT `element.dispatchEvent(new PointerEvent(...))` / `new KeyboardEvent(...)` on a captured element handle.
- **CLI:** invoke the real binary with real argv and a real stdin pipe. NOT a unit-test call that monkeypatches `sys.argv` or stubs the arg parser.
- **HTTP:** issue a real request over the socket (curl, httpie, a real client). NOT a direct in-process handler call with a mocked request object.
- **Concurrency:** spawn real concurrent drivers (parallel processes/requests/threads). NOT a serialized loop that pretends to be concurrent.

**Why this is non-negotiable:** synthetic dispatch / mocked I-O **false-passes**. Dispatching a `PointerEvent` on a held element reference bypasses pointer-capture, hit-testing, focus, and re-render-during-gesture — exactly the machinery where interactive bugs live. A synthetic-event harness can report PASS while the real component stays broken, sending you back to another fruitless hand-back. Only real driven input exercises capture/hit-test/focus/timing faithfully.

Run the harness. Observe:

```
Drove with: <the real input mechanism>
Observed: <reproduced the reported failure / did NOT reproduce>
```

**If the repro does NOT reproduce the failure under real input:** your reduction stripped something load-bearing, OR the bug needs a condition you haven't added yet. Add back the next-most-likely-implicated piece and re-drive. Do not conclude "the bug is gone" from a non-reproducing minimal harness — that is the synthetic-pass trap in a different form.

### 4. Isolate the cause and fix in the harness first

With a reproduction you can drive on demand, iterate **in the harness**: form a hypothesis, change one thing, re-drive with real input, observe. Because the loop is now fast and fully under your control, the root cause surfaces quickly. Record it:

```
Root cause: <one or two sentences — the actual mechanism, e.g., "pointer capture was set on the per-tile <button>, but the live reorder re-renders that button every move, so capture is dropped after the first frame — no further pointermove arrives">
Fix (validated in harness): <what change makes the harness pass under real input — e.g., "move capture + move/up handlers to the stable strip container, resolve the tile via closest()">
Re-driven green: <YES — the harness now passes the same real-input drive that previously reproduced the failure>
```

Then **port the validated fix to the real codebase** and, where the real surface is also drivable by you (e.g. the same logic under Vite), **re-drive the real component with real input** to confirm the port — not just the harness.

### 5. Cleanup

The throwaway harness must not be left behind. Before emitting any `RETURN-TO:`, do and confirm:

- Delete the scratch reproduction (the `/tmp/<slug>` files, the throwaway dev route, the scratch script).
- Remove any temporary instrumentation added while isolating (`console.log`, print lines, timing counters) — grep for your marker.
- Confirm the real fix is in place and re-driven green on a real surface where possible.
- If the project has a lint/format step, run it.

Write the confirmation:

```
Minimal-harness cleanup complete.
  Scratch reproduction deleted: <YES — /tmp/<slug> removed>
  Temporary instrumentation removed: <YES / N/A>
  Real fix in place + re-driven with real input: <YES — what you drove and saw>
  Root cause: <one-sentence summary>
```

Then emit:

```
TRANSITION: DEBUG-MINHARNESS-COMPLETE
RETURN-TO: <caller-skill-name, or "user" if directly invoked>
```

The caller (e.g., `feature-build`) resumes with the cause in hand and the fix already validated under real input — re-presenting to the human now means presenting a *confirmed* fix, not a third guess.

### 6. Inconclusive escalation

If, after building the reproduction and ≥3 rounds of `hypothesize → change → re-drive`, you have NOT converged on the cause — the harness reproduces the failure but no change makes it pass, or the failure stops reproducing in the harness but persists in the real app (a sign the reduction lost a load-bearing condition) — the technique has not paid off cleanly. Do not loop indefinitely.

**Procedure:**

1. Run the §5 Cleanup steps anyway — the scratch harness should not be left behind even on an inconclusive exit.
2. Document the rounds attempted and what the harness did/didn't reproduce.
3. Emit:

```
Minimal-harness reproduction inconclusive after building a self-driven repro and 3 rounds. The harness <reproduced the failure but no fix converged | stopped reproducing while the real app stayed broken — the reduction likely lost a load-bearing condition>. Hypotheses considered: <…>. Suggested next steps: <one or two — e.g., "the real surface differs from the harness in <X> — instrument the real app via /debug-empirical-telemetry", "a known-good sibling may exist → /debug-bisect-known-good", "hand back to the human with the reproduction attached so they verify against the real native surface">.

TRANSITION: DEBUG-MINHARNESS-INCONCLUSIVE
RETURN-TO: <caller-skill-name, or "user" if directly invoked>
```

Log a SURFACE entry to `workflow/backlog.md` summarizing what the reproduction did and didn't show (for future learning).

## Pitfalls (load-bearing — read before building the harness)

1. **Synthetic dispatch false-passes — the single biggest trap.** Dispatching `new PointerEvent(...)` / `new KeyboardEvent(...)` on a held element handle (or a mocked argv / mocked HTTP request / serialized fake-concurrency) bypasses the exact machinery where the bug lives — pointer capture, hit-testing, focus, re-render-during-gesture, real timing. A synthetic harness that PASSES while the real component stays broken is worse than no harness: it manufactures false confidence and sends you back to another hand-back. **Drive with real input or don't bother.** (Origin: a first claudesk drag hello-world using synthetic `PointerEvent` dispatch PASSED while the real component stayed frozen; only a real `page.mouse` drag reproduced the freeze and exposed the capture-on-re-render root cause.)
2. **Reducing too far and losing the bug.** If the minimal repro stops exhibiting the failure under real input, you stripped something load-bearing — add it back, don't declare victory. A non-reproducing harness proves nothing.
3. **"The shipping target is native, so I must hand back."** This is the rationalization the whole skill exists to defeat. The shipping surface being native (WKWebView/Electron/mobile) does NOT mean the logic is undrivable — the same DOM/web logic runs in a browser you control. Ask the Gate-1 question literally.
4. **Building the harness but still debugging in the full app.** Once you have a fast self-driven repro, iterate IN it. Going back to the slow full-app loop discards the technique's main benefit (fast, fully-controlled iteration).
5. **Leaving the scratch repro behind.** The throwaway `/tmp` files, dev route, or scratch script must be deleted in §5. A committed hello-world is debt.
6. **Re-presenting the harness-pass without re-driving the real surface.** A fix that passes in the reduced harness should, where the real surface is drivable, be re-driven there too before claiming done — the port can differ from the reduction.

## Termination

This skill emits exactly one of the following terminal tokens (test harness asserts on the token; orchestrator uses `RETURN-TO:` to resume the caller):

| Token | Meaning | When emitted |
|-------|---------|-------------|
| `DEBUG-MINHARNESS-START` | Both gates passed; procedure has activated | After §1 Gate Check confirms both gates YES; §2 begins |
| `DEBUG-MINHARNESS-SKIP` | Gate Check failed; skill not applicable | §1 (either gate NO); or mid-procedure if a gate no longer holds (e.g., the surface turns out to be undrivable) |
| `DEBUG-MINHARNESS-COMPLETE` | Cause located via a self-driven repro under real input; fix validated; scratch cleaned up | §5 |
| `DEBUG-MINHARNESS-INCONCLUSIVE` | Repro built but ≥3 rounds did not converge; cleanup done | §6 |

Every termination must also include a `RETURN-TO:` line naming the caller skill (or `user` for direct invocation) so the orchestrator can resume.

**For long reproduction sessions (5+ rounds):** consider writing iteration notes to `workflow/wip/debug-<short-slug>.md` for traceability — but this is optional. The default is in-conversation only. Same threshold as the sibling sidebars.

**Sidebar discipline:** This skill never advances any workflow state machine. It does not write to feature/incident/task WIP files' `## Current Node` or `## Discoveries` (the caller does that, after resuming, if the outcome warrants it). The only persistent artifacts the skill itself MAY create are: (a) a SURFACE entry in `workflow/backlog.md` on the inconclusive path (§6), and (b) optional iteration notes in `workflow/wip/debug-<short-slug>.md` for long sessions. The scratch reproduction from §2 is explicitly NOT a persistent artifact — it is deleted in §5.

**Stalled behavioral bug:** {{args}}
