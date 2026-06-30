---
name: task-verify
description: "Task workflow: verify the implementation actually works before close — single-step gate between act and close"
argument-hint: <optional notes or the specific WIP file to verify>
allowed-tools:
  - Read
  - Bash
  - Edit
  - Grep
  - Glob
---

# Task Verify

You are an expert software engineer running the verification gate for a completed task.

## State Machine Context

You are in the **task** workflow at the **verify** state. This is a single-step gate between `task-act` and `task-close` — analogous to `feature-verify-self` at feature scope, but lighter (no 5-leaf chain, no Playwright machinery, no Observable Outcomes section at plan time).

**Valid transitions from here:**
- **T5b → close:** Verification PASSed — observable confirms the fix worked → tell user to run `/task-close`
- **T5c → act (back-loop):** Verification FAILed — observable did not pass; document what failed, tell user to run `/task-act` to fix with scope restricted to the failed observable

## Orchestrator Pause Policy (cheat-sheet)

When invoked by `/session-start` in orchestrated mode, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause. Per-skill rows for verify's exits:

| Transition | Mode 1 — Stepping | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — FSD |
|---|---|---|---|---|
| T5b (verify → close, PASS) | PAUSE | AUTO | AUTO | AUTO |
| T5c (verify → act, FAIL back-loop) | PAUSE | AUTO | AUTO | AUTO |

**Hard rule for AUTO exits.** When this skill's emitted transition is `AUTO` in the current drive mode, the orchestrator **must immediately invoke the next skill via the `Skill` tool**. It must **NOT** return control to the user. Emitting a clean `TRANSITION: T5b` followed by a polite narrative summary ("Verify complete; ready to run task-close") is the regression mode this block exists to prevent: the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. **This explicitly includes the `AskUserQuestion` tool (and any other user-input/confirmation prompt): invoking it on an AUTO transition IS "returning control to the user" and is the same regression class as the narrative-summary stop above — do NOT call it to "just confirm" the handoff. The only thing that pauses an AUTO transition is the human-input points the active drive mode's pause policy explicitly marks PAUSE.** See `agents/task-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## When the gate auto-skips

If the WIP file's frontmatter contains `docs-only: true` (declared at plan time per `task-plan` SKILL.md), this skill emits `TRANSITION: T5b` immediately with an auto-skip annotation in the verification block. No observable is required, no verification is run. Rationale: pure-docs tasks (CLAUDE.md prose edits, backlog status updates, README touches) have no runtime surface to verify; forcing ceremony there is overhead, not signal. The explicit `docs-only: true` declaration is the discipline — the auto-skip is the convenience.

**The gate is NOT auto-skipped just because the task "looks like docs."** Only the plan-time `docs-only: true` declaration triggers auto-skip. If a task that touches code is misdeclared `docs-only: true`, that's an upstream bug in task-plan; this skill trusts the declaration.

## Procedure

### 1. Read inputs

- Look in `workflow/wip/` for the active task WIP file
- If `{{args}}` specifies a file, use that
- If multiple exist, ask the user which one
- **Read `## Current Node` first** — this is the authoritative position pointer
- Read the WIP file's frontmatter: check for `docs-only: true`

**Docs-only auto-skip branch:** If frontmatter contains `docs-only: true`, skip to step 6 and emit `TRANSITION: T5b` with the auto-skip annotation. Do not perform steps 2–5.

### 2. State the observable in writing

This is the load-bearing discipline. Before running anything, write into the WIP file a new section `## Verification Observable`:

```markdown
## Verification Observable

**Observable:** <one-sentence declarative statement of what, when run, will confirm the fix worked>
**Verification command:** `<exact CLI invocation, curl, or file check>`
**Expected result:** <PASS criterion — exit code, stdout pattern, HTTP status, etc.>
```

**Rules for the observable:**

- It must be **mechanically verifiable** — a CLI exit code, stdout pattern, HTTP status, or file-existence check. Prose criteria ("looks right", "works correctly") are NOT acceptable.
- It must be **end-to-end against the consuming surface** — not a proxy. If the task fixed a shell script, the observable runs the script for real (not `--dry-run`). If the task fixed an endpoint handler, the observable hits the endpoint with curl (not a unit test of the function). The 2026-06-09 `run-all-unbound-forward-args` near-miss happened because the plan accepted `--dry-run` as a proxy and the bug lived outside `--dry-run`'s code path.
- It must **target the failure mode the task was meant to fix.** If the task says "fix unbound variable on line 42 when FORWARD_ARGS is empty," the observable invokes the script with empty FORWARD_ARGS. Don't shift the observable to something easier-to-verify just because the original failure mode is harder to trigger.

If you cannot state the observable in one sentence with a concrete command, the task's problem statement is too vague to verify — back-loop to act (T5c) and document the gap.

### 3. Run the verification

Execute the verification command via `Bash`. Capture stdout, stderr, and exit code. If the verification is multi-step (e.g., start a server, then curl an endpoint, then stop the server), run all steps and capture the relevant observation at each.

**Real invocation only.** Do not substitute a proxy at run-time, even if the real invocation is slow or requires setup. If the verification needs a dev server or a test database, start it; the verification time cost is the workflow's discipline, not its overhead.

### 4. Classify the result

Three outcomes:

- **PASS:** The verification command's actual result matches the declared expected result. The fix is confirmed.
- **FAIL:** The verification command's actual result does NOT match the declared expected result. The fix did not work, or the task scope was wrong.
- **SURFACED-sibling-bug:** The verification revealed a related-but-distinct issue — same file, same general bug-family, but not what the task was meant to fix. See §4b for handling.

Write the result into the WIP file under the just-added Verification Observable section:

```markdown
## Verification Result

**Status:** PASS | FAIL | SURFACED-sibling-bug
**Date:** <YYYY-MM-DD>
**Evidence:** <what the verification actually produced — exit code, stdout excerpt, HTTP status. Quote literally, don't paraphrase>
**Notes:** <one-line interpretation if PASS; failure detail if FAIL; sibling-bug description if SURFACED>
```

### 4b. In-place fix shortcut (SURFACED-sibling-bug handling — narrow exception)

task-verify is contractually a gate, not a fix shop: FAIL routes through T5c back-loop to `task-act`. This sub-clause defines a narrow exception that permits an in-place fix when the sibling-bug is a trivial extension of the just-completed task and the back-loop would cost a full act → verify round trip for an equivalent outcome.

**All three gates must hold:**

1. **Trivial extension of the just-completed task.** The sibling-bug is a one-line (or small, mechanical) fix in the same file, with the same bug-family, that emerged only when the verification ran end-to-end. It is *not* a redesign, a re-plan, a new abstraction, or a fix that crosses files or modules outside the task's scope. If you cannot describe the fix in one sentence as "extend the task-act fix to also handle X in the same place", the gate fails — use T5c instead.
2. **Fresh re-verification.** After applying the sibling-bug fix in-place, re-run the verification command (step 3) to confirm the fix worked. Re-classifying without re-running does NOT count and does NOT satisfy this gate.
3. **Audit-trail entry in WIP `## Discoveries`.** Append an entry of the form `[SHORTCUT-<YYYY-MM-DD>] task-verify — <one-line description of the sibling-bug fix and its re-verification>` to the WIP file's `## Discoveries` section before transitioning. The entry is the artifact a reviewer can grep for when reconstructing why the T5c back-loop was bypassed.

When all three gates hold (trivial extension + fresh re-verification + audit-trail entry): apply the fix in-place, re-run the verification, update the Verification Result section to reflect the post-fix PASS, append the `## Discoveries` entry, and proceed to T5b. When any gate fails: do not shortcut — emit T5c and back-loop normally.

**SURFACED-sibling-bug out of scope:** If the sibling-bug is too large for the shortcut (multiple files, different bug-family, requires re-planning), append it to `workflow/backlog.md` as a new `## SURFACE-<timestamp>` entry per the standard surface protocol, note "SURFACED to backlog; original observable still PASS" in the Verification Result, and proceed to T5b. The original task is verified; the sibling-bug becomes its own future work item.

**What this shortcut is NOT.** It is not license to merge unrelated bugs into the task. It is not a fast-path for non-trivial fixes that happen to be nearby. It is not a substitute for re-planning when the task scope was wrong (use T5c → T6 chain instead). The triviality + fresh-re-verification + audit-trail gates are the boundary; agent comfort with the fix is not.

This shortcut mirrors `skills/feature-verify-self/SKILL.md` §3 "In-place fix shortcut" — same three-gate shape, adapted to task scope.

### 5. Update WIP tree and Current Node

- Update the WIP file's `state:` frontmatter field to `verify (complete)` on PASS, or `verify (FAILED — back-loop pending)` on FAIL.
- Update `## Current Node`:
  - **PASS:** Path = `Task > verify (complete)`, Active scope = `all complete, ready for close`, Open discoveries = none (or list the SURFACED-sibling-bug if applicable).
  - **FAIL:** Path = `Task > verify (FAILED)`, Active scope = `the failed observable — back-loop to act`, Open discoveries = the FAIL evidence.

### 6. Decide transition

**PASS (T5b):**
- Tell user to run `/task-close`.

**Docs-only auto-skip (T5b):**
- The Verification Observable section is replaced by a short note: `Verification skipped: docs-only declared at plan time. No runtime surface to verify.`
- Tell user to run `/task-close`.

**FAIL (T5c):**
- The Verification Result documents the failure detail.
- The back-loop message to `task-act` cites the failed observable text verbatim as the scope-restriction marker: `"Verify failed: <observable>. Back-loop to /task-act to fix the underlying issue before re-running /task-verify."`
- Tell user to run `/task-act` (the task-act skill on re-entry treats this as a T6-equivalent back-loop and applies the Problem Statement re-check).

### 7. Emit Transition

End your output with the canonical transition token so the orchestrator can act on it (the orchestrator reads `TRANSITION: <id>`; the bare slash-command prose above is advisory for single-step users only):

- `TRANSITION: T5b` — verification PASSed (or docs-only auto-skip), hand off to task-close
- `TRANSITION: T5c` — verification FAILed, back-loop to task-act with the failed observable as scope

**Scope:** {{args}}
