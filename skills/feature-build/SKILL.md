---
name: feature-build
description: "Feature workflow: implement the current phase of the feature plan"
argument-hint: <optional: scoped leaf IDs from verify-human back-loop, e.g. P1.verify-human.1,P1.verify-human.2 — or phase number / focus area>
---

# Feature Build

You are an expert Senior Developer implementing a feature phase-by-phase.

## State Machine Context

You are in the **feature** workflow at the **build** state.

**Valid transitions from here:**
- **F8 → verify-auto:** Phase implementation complete → tell user to run `/feature-verify-auto`
- **F9b (back-loop from verify-self):** Re-entered to fix a blocking observable outcome — after fixing, run the re-verify gate before transitioning to verify-auto
- **F22 → research (REDIRECT):** Hit unknown during implementation → pause, research, return
- **F36 → reproduce (REDIRECT):** Realized the fix cannot be confirmed without first reproducing the bug → pause, reproduce, return (F37 on success or F37b on could-not-reproduce)
- **F23 → plan (back-loop):** Plan is wrong/incomplete → document what's wrong, go back to plan
- **F25 → SURFACE to product:wbs:** Discovered module/component not in WBS (note-and-continue)
- **F26 → SURFACE to product:arch:** Architectural change needed (pause-and-escalate)
- **F27 → incident:report:** Something breaks

## Orchestrator Pause Policy (cheat-sheet)

When invoked by `/session-start` in orchestrated mode, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause. Per-skill rows for build's exits:

| Transition | Mode 1 — Stepping | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — FSD |
|---|---|---|---|---|
| F8 (build → verify-auto) | PAUSE | AUTO | AUTO | AUTO |
| F9b (back-loop re-verify passed → verify-auto) | PAUSE | AUTO | AUTO | AUTO |
| F22 (REDIRECT to research) | PAUSE | **PAUSE** | **PAUSE** | AUTO |
| F36 (REDIRECT to reproduce) | PAUSE | **PAUSE** | **PAUSE** | AUTO |
| F23 (back-loop to plan) | PAUSE | AUTO | AUTO | AUTO |
| F25 (SURFACE to product:wbs, note-and-continue) | PAUSE | AUTO | AUTO | AUTO |
| F26 (SURFACE to product:arch, pause-and-escalate) | PAUSE | **PAUSE** | **PAUSE** | AUTO |
| F27 (incident:report interrupt) | PAUSE | **PAUSE** | **PAUSE** | **PAUSE** |

**Hard rule for AUTO exits.** When this skill's emitted transition is `AUTO` in the current drive mode, the orchestrator **must immediately invoke the next skill via the `Skill` tool**. It must **NOT** return control to the user. Emitting a clean `TRANSITION: F8` followed by a polite narrative summary ("Phase 1 complete; ready to run verify-auto") is the regression mode this block exists to prevent (P1 incident, 2026-05-16): the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. **This explicitly includes the `AskUserQuestion` tool (and any other user-input/confirmation prompt): invoking it on an AUTO transition IS "returning control to the user" and is the same regression class as the narrative-summary stop above — do NOT call it to "just confirm" the handoff. The only thing that pauses an AUTO transition is the human-input points the active drive mode's pause policy explicitly marks PAUSE.** See `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## Procedure

### 1. Context Recovery
- Read the WIP file in `workflow/wip/`
- **Read `## Current Node` first** — this is the authoritative position pointer
- **If `{{args}}` contains leaf IDs** (e.g., `P1.verify-human.2,P1.verify-human.3`): you are re-entering from a back-loop. Restrict work to those specific leaves only — do not touch sibling leaves or advance to the next phase
- If no scoped args: work on the next incomplete impl task in the current phase
- If `## Current Node` diverges from what the tree shows, trust the tree and rewrite Current Node

### 1b. Problem Statement Re-Check (back-loop re-entry only)

**Applies when:** re-entering from any back-loop (F9b, F12, F23) — i.e., this is not the first time build has been entered for this phase.

Before implementing anything, answer this question in writing and record the answer in the WIP file's `## Problem Statement` section:

> **Has the root problem changed based on what we learned?**
> - What did we learn from the failed verification or rejected phase?
> - Is the original problem statement still accurate, or has our understanding shifted?
> - If the problem has changed: update `## Problem Statement` to reflect the current understanding. Mark the update with `[Updated YYYY-MM-DD: <one-line reason>]`.
> - If the problem has NOT changed: record "Problem statement unchanged — [brief confirmation of why]" as a one-liner appended to the Problem Statement section.

This check must be completed before proceeding to implement. Its purpose: prevent the agent from fixing symptoms while the root cause has shifted.

### 2. Environment Check
- Read the project `CLAUDE.md` at the root for environment rules (also `<proj-dir>/.claude/CLAUDE.md` if present)
- **Docker Rule:** If the project mandates Docker, ALL commands MUST run inside the container

### 3. Implement
- Implement only the items in scope (scoped leaf IDs if present; otherwise next incomplete impl task)
- Write or update tests alongside code where possible (TDD)
- Follow project conventions strictly
- Run tests frequently to catch regressions
- Mark each leaf `[x]` in the WIP tree as it completes

### 4. Attach Discoveries to the Tree

When you discover something new while working on a leaf:
- Add a `SURFACED` child node under the **relevant parent phase node** in the WIP tree: `- [ ] <summary>  <!-- status: SURFACED: <summary> -->`
- Also log to `workflow/backlog.md`:

```markdown
## SURFACE-<timestamp>
- **Source:** feature:build
- **Target level:** product:wbs | product:arch
- **Type:** new-work | gap | tech-debt | bug
- **Summary:** <what was discovered>
- **Context:** <why it matters>
- **Suggested action:** <what should be done>
- **Priority:** low | medium | high
- **Status:** pending
```

**Unknown encountered (F22 REDIRECT):**
Save state, document the question, tell user to run `/feature-research`. Note that this is a REDIRECT so research knows to return here.

**Cannot confirm fix worked without reproduction (F36 REDIRECT):**
When you realize mid-build that you applied a bug fix but never confirmed the bug actually existed in the first place — i.e., you cannot distinguish "the code path is different now" from "the bug never reproduced because it wasn't there" — pause build and REDIRECT into `/feature-reproduce` to capture a pre-fix failing test or deterministic recipe. Before emitting the transition:

1. Write a placeholder section to the WIP file: `## Reproduction Artifact (mid-build, from F36)` with an empty body (reproduce will fill it on return).
2. Update `## Current Node` to add a sentinel line: `**Redirect source:** build (F36 — Phase N)` — `feature-reproduce` reads this on entry to detect F36-source and route its exit through F37 (success) or F37b (could-not-reproduce) instead of the normal F32/F33/F34/F35.
3. Tell user to run `/feature-reproduce`. Note that F35 (terminate) and F34 (preventive hardening reset to spec) are disallowed from F36-entered reproduce — F37b (return with could-not-reproduce documented as Discovery) is the always-available fallback.

**Plan is wrong (F23 back-loop):**
Document what's wrong and why in the WIP file. Tell user to run `/feature-plan` to revise.

**Architectural blocker (F26 pause-and-escalate):** Save state, explain the blocker, tell user what needs resolution at the product level before continuing.

### 4b. Debug-technique Sidebar (optional)

If straight-line debugging during implementation has stalled (≥3 failed attempts to localize a bug, or 2+ verify-self back-loops on the same observable outcome) AND a structurally similar known-good path exists in the same environment, consider invoking `/debug-bisect-known-good` as a sidebar before continuing. The sidebar runs to completion, emits a `RETURN-TO: feature-build` token, and resumes this state with the cause in hand. This is a same-state round-trip — no new transition ID, no plan revision needed.

If instead the bug-shape requires runtime evidence (timing/race, intermittent symptom, DB query plan or timing, perf regression, env-dependent state, "wrong value at this line") and static reasoning has stalled (≥2–3 failed read-the-code-and-guess attempts), consider `/debug-empirical-telemetry` as the sidebar. It walks the agent through smallest-discriminating-observable → instrument → run → read → cleanup, and emits a `RETURN-TO: feature-build` token on completion. Same same-state round-trip discipline — no transition ID, no plan revision. See `agents/feature-workflow/AGENTS.md` → "Debug techniques (agent-pulled sidebars)" for the full list of available techniques.

If instead you've been fixing a **behavioral** bug (a drag/click/focus/keyboard gesture, a CLI under real argv/stdin, an HTTP endpoint under a real client, a race under real concurrency) and have **handed the fix back untested ≥2 times** on the same behavior, AND that behavior is drivable in a surface you control — even when the shipping target is native (Tauri WKWebView, Electron) the same DOM/CLI/HTTP logic usually runs in a browser/process you *can* drive — consider `/debug-minimal-harness`. It has you build a minimal standalone reproduction and drive it yourself with **real input** (`page.mouse`, real argv, a real request) rather than synthetic dispatch, until the fix works, before re-presenting to the human. Emits a `RETURN-TO: feature-build` token on completion. Same same-state round-trip discipline — no transition ID, no plan revision.

### 5. Parent Completion Enforcement
Before exiting, scan every phase node in the Work Tree:
- If ALL children of a phase are `[x]` but the phase itself is not `[x]` → mark the phase `[x]` now
- This includes impl tasks, verify-auto, verify-self, verify-human, verify-codify — all must be `[x]`

### 6. Re-Verify Gate (back-loop exits only)

**Only applies when re-entering from a verify-self back-loop (F9b) — i.e., `{{args}}` contained specific failed leaf IDs.**

Before transitioning to verify-auto, re-run the behavioral checks that previously failed. These are the Observable outcomes from the current phase's WIP tree node that were marked `FAILED` in verify-self.

Concrete re-verify actions:
- **HTTP outcome:** `curl -s -o /dev/null -w "%{http_code}" <endpoint>` and compare to expected status
- **Browser outcome:** use `browser_snapshot` / `browser_console_messages` at the relevant URL
- **CLI outcome:** re-run the exact CLI command from the Observable outcomes list

**If re-verify passes:** proceed to verify-auto (F8) — the fix is confirmed.
**If re-verify fails:** document what still fails, update the failed leaf status in the WIP tree, and stay in build to investigate further. Do not transition to verify-auto with an unconfirmed fix.

### 7. Update Current Node and Exit
Always update `## Current Node` before handing off:
- If scoped re-entry: update Active scope to reflect which leaves were fixed (or clear if all resolved)
- If normal impl: update Path and Active scope to reflect current position

### 8. Phase Complete
When all impl tasks in the current phase are done (verify nodes will be handled by their own skills):
- Update `## Current Node` to point to `verify-auto` for this phase
- Tell user to run `/feature-verify-auto` to verify this phase

### 9. Emit Transition
End your output with the canonical transition token so the orchestrator can act on it (the orchestrator reads `TRANSITION: <id>`; the bare slash-command prose above is advisory for single-step users only):

- `TRANSITION: F8` — phase complete, hand off to verify-auto (default exit)
- `TRANSITION: F9b` — back-loop re-verify passed, hand off to verify-auto after scoped re-entry
- `TRANSITION: F22` — REDIRECT to research (unknown encountered)
- `TRANSITION: F36` — REDIRECT to reproduce (fix cannot be confirmed without reproducing the bug first)
- `TRANSITION: F23` — back-loop to plan (plan was wrong)
- `TRANSITION: F25` — SURFACE to product:wbs (note-and-continue, then return)
- `TRANSITION: F26` — SURFACE to product:arch (pause-and-escalate)
- `TRANSITION: F27` — escalate to incident (something broke)

**Current Step/Focus:** {{args}}
