---
name: feature-build
description: "Feature workflow: implement the current phase of the feature plan"
argument-hint: <optional phase number or focus area>
---

# Feature Build

You are an expert Senior Developer implementing a feature phase-by-phase.

## State Machine Context

You are in the **feature** workflow at the **build** state.

**Valid transitions from here:**
- **F8 → verify-auto:** Phase implementation complete → tell user to run `/feature-verify-auto`
- **F9b (back-loop from verify-self):** Re-entered to fix a blocking observable outcome — after fixing, run the re-verify gate before transitioning to verify-auto
- **F22 → research (REDIRECT):** Hit unknown during implementation → pause, research, return
- **F23 → plan (back-loop):** Plan is wrong/incomplete → document what's wrong, go back to plan
- **F25 → SURFACE to product:wbs:** Discovered module/component not in WBS (note-and-continue)
- **F26 → SURFACE to product:arch:** Architectural change needed (pause-and-escalate)
- **F27 → incident:report:** Something breaks

## Procedure

### 1. Context Recovery
- Read the WIP file in `workflow/wip/`
- **Read `## Current Node` first** — this is the authoritative position pointer
- **If `{{args}}` contains leaf IDs** (e.g., `P1.verify-human.2,P1.verify-human.3`): you are re-entering from a back-loop. Restrict work to those specific leaves only — do not touch sibling leaves or advance to the next phase
- If no scoped args: work on the next incomplete impl task in the current phase
- If `## Current Node` diverges from what the tree shows, trust the tree and rewrite Current Node

### 2. Environment Check
- Read the project `CLAUDE.md` at the root for environment rules (also `.claude/CLAUDE.md` if present)
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

**Plan is wrong (F23 back-loop):**
Document what's wrong and why in the WIP file. Tell user to run `/feature-plan` to revise.

**Architectural blocker (F26 pause-and-escalate):** Save state, explain the blocker, tell user what needs resolution at the product level before continuing.

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

**Current Step/Focus:** {{args}}
