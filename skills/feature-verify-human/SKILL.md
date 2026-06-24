---
name: feature-verify-human
description: "Feature workflow: guide the human through manual verification of the current phase"
argument-hint: <optional phase number — on rejection, outputs specific failed leaf IDs (e.g. P1.verify-human.1) for scoped re-entry to feature-build>
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Feature Verify — Human

You are an expert QA Engineer guiding the human through manual verification.

## State Machine Context

You are in the **feature** workflow at the **verify-human** state.
This is the third step of the per-phase verification loop: `build → verify-auto → verify-self → verify-human → verify-codify`.

**Valid transitions from here:**
- **F13 → verify-codify:** Human approves → tell user to run `/feature-verify-codify`
- **F11 → verify-codify:** Nothing for human to test (with confirmation) → tell user to run `/feature-verify-codify`
- **F12 → build (back-loop):** Human rejects → document issues, tell user to run `/feature-build`

## Orchestrator Pause Policy (cheat-sheet)

This skill is the **one forced human-pause** in the per-phase loop for Modes 1–2 — invocation itself PAUSEs while the human walks the checklist (§5 of the Procedure). In Mode 3 the pause is **conditional**: when the §2 Auto-skip gate is clean (no integration boundary + verify-self all-PASS), the skill AUTO-SKIPs by emitting F11 without prompting; otherwise Mode 3 still PAUSEs. Mode 4 SKIPs invocation entirely.

Once the human has responded (or in Mode 3 auto-skip, immediately) and this skill emits an exit transition, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause:

| Transition | Mode 1 — Step-by-step | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — Full-autopilot |
|---|---|---|---|---|
| Skill invocation (entry — present checklist) | PAUSE | **PAUSE** (await human) | **PAUSE** (await human) — or AUTO-SKIP when §2 Auto-skip gate clean (no boundary + verify-self all-PASS) | **SKIP** (orchestrator chains verify-self → verify-codify directly) |
| F13 (human approves → verify-codify) | PAUSE | AUTO | AUTO | n/a (skipped) |
| F11 (human-confirmed skip → verify-codify) | PAUSE | AUTO | AUTO | n/a (skipped) |
| F11 (AUTO-SKIP — auto-skip gate clean, no prompt) | n/a | n/a | AUTO | n/a (skipped) |
| F12 (back-loop to build with scoped leaves) | PAUSE | AUTO | AUTO | n/a (skipped) |

**Hard rule for AUTO exits.** When this skill's emitted transition is `AUTO` in the current drive mode (i.e., the human has already responded), the orchestrator **must immediately invoke the next skill via the `Skill` tool**. It must **NOT** return control to the user a second time after the human's reply. Emitting a clean `TRANSITION: F13` followed by a polite narrative summary ("Phase approved; ready to run verify-codify") is the regression mode this block exists to prevent (P1 incident, 2026-05-16): the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. **This explicitly includes the `AskUserQuestion` tool (and any other user-input/confirmation prompt): invoking it on an AUTO transition IS "returning control to the user" and is the same regression class as the narrative-summary stop above — do NOT call it to "just confirm" the handoff. The only thing that pauses an AUTO transition is the human-input points the active drive mode's pause policy explicitly marks PAUSE.** See `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## Procedure

### 1. Read Current Node
Read the WIP file in `workflow/wip/`. Find `## Current Node` — this tells you which phase's `verify-human` node is active and whether this is a first run or re-entry from a back-loop.

### 2. Assess Whether Human Testing is Needed

First, determine whether this phase has an **integration boundary**. A phase has a boundary when any of the following is true:

1. A line of code was added or modified inside a file that an existing HTTP endpoint, route, controller, resolver, or middleware already consumed.
2. A line of code was added or modified inside an existing UI page, view, or component such that user-visible behavior changes.
3. A line of code was added or modified inside an existing CLI command or argument parser.
4. A line of code was added or modified inside an existing scheduled job, cron, queue consumer, or background worker.
5. The request/response shape, payload, or destination of an existing outbound call to an external system was changed.

**If a boundary applies, the F11 skip path is forbidden.** Even when there is no UI to click, the human checklist MUST include at least one item: a recorded `curl` (or equivalent CLI invocation) against the consuming surface, with the response captured. Phrase the item so the human can copy-paste-run it: e.g. "Run `curl -sS -X POST http://localhost:8000/distribution/match -d '{...}'` and paste the response — confirm the `video_id` field is one the new pool would produce." Do **not** mark the phase complete on the human's "looks fine" alone — require the captured response.

**If no boundary applies** (the phase only adds isolated new artifacts that no existing surface consumes):
- Affirm this in writing: "This phase does NOT wire into any existing endpoint, route, UI page, CLI command, scheduled job, or external-system call. It only adds isolated new artifacts: [list them]."
- Then check the **Auto-skip gate** below. If gates clean, auto-skip without prompting. Otherwise, ask the human: "Given that affirmation, do you agree to skip to verify-codify?" Only proceed to verify-codify (F11) if the human confirms.

The skip path is gated by the affirmation, not by the agent's general judgment that "there is nothing to test."

#### Auto-skip gate (Mode 3+ + no boundary + verify-self all-PASS)

In drive_mode `autopilot` (Mode 3) or `full-autopilot` (Mode 4), the human "do you agree to skip?" prompt is redundant when the objective gate is already clean — the operator has opted into autopilot, and the affirmation rules above provide an objective check. The auto-skip elides the prompt but **still prints the affirmation block in chat** so the operator retains a read-time veto.

**Read `drive_mode`** from the WIP file's YAML frontmatter (`drive_mode: autopilot` or `drive_mode: full-autopilot`). Then evaluate all four conditions:

1. **(a) drive_mode is `autopilot` or `full-autopilot`** — read from WIP frontmatter. If frontmatter has no `drive_mode` field, treat as Mode 2 (orchestrated) and do NOT auto-skip.
2. **(b) verify-self all-PASS** — scan the current phase's `verify-self` subtree in the Work Tree. Every leaf must be `[x]` (no `UNVERIFIED`, no `FAILED`, no `FAILED-cosmetic`, no `NOT-STARTED`). If verify-self itself is `NOT-STARTED` or any leaf is non-PASS, do NOT auto-skip.
3. **(c) No integration boundary applies** — the 5-condition check above returned "no boundary." If a boundary applies, auto-skip is irrelevant (the F11 skip path is forbidden entirely).
4. **(d) No observable outcome cites a consuming surface by name** — re-read the phase's Observable Outcomes block. If any outcome line names an existing endpoint, UI route, CLI command, job, or external system that the phase modifies (rather than adds fresh), this is a boundary signal that (c) may have missed. Be conservative: if you cannot affirm "none of the outcomes references a consuming surface this phase touches," do NOT auto-skip.

**When ALL four gates clean:**
- Print the affirmation block in chat (the same paragraph from above naming the isolated new artifacts).
- Print one additional line: `Auto-skipped per drive_mode=<mode> — no integration boundary detected.`
- Emit `TRANSITION: F11` immediately. Do NOT ask "do you agree to skip?" — the operator's autopilot opt-in is the consent.
- Update the WIP tree exactly as the human-confirmed F11 path would (mark verify-human `[x]`, update Current Node).

**When ANY gate fails:** fall through to the existing F11-with-confirmation path (ask the human, wait for "skip" confirmation, then emit F11).

This auto-skip applies only to the F11 path (no boundary, isolated artifacts). The F13 (human approves checklist) and F12 (back-loop) paths are unchanged and never auto-skip — those require actual human judgment by definition.

**Known limitation — probe/decision-artifact false positive.** A phase whose load-bearing deliverable is a human decision ACK (probe results, retrospect findings, baseline measurements) with no integration boundary will be auto-skipped under the current gates. The operator's read-time veto (the printed affirmation block) is the recovery mechanism — manually run `/feature-build <leaf-id>` if a misclassification needs review. A future cycle may add a 5th gate (no decision-artifact outcomes) when a real regression hits.

### 3. Expand verify-human into leaf nodes (first run)

**On first run for this phase** (verify-human node has no children yet):
- Expand the `verify-human` node into individual leaf items in the WIP tree — one leaf per check
- Each leaf gets a node ID (e.g., `P1.verify-human.1`, `P1.verify-human.2`) and `<!-- status: NOT-STARTED -->`

**On re-entry from build back-loop** (verify-human node already has children):
- Present only leaves that are `FAILED` or `BLOCKED` — skip any `[x]` leaves
- Do not re-present items the human already approved

**Pre-filter from verify-self:** Read `verify-self` results in the WIP tree before building the checklist. Apply these rules strictly — do not present items the agent already confirmed:

| verify-self status | Action in human checklist |
|--------------------|--------------------------|
| `[x]` (PASS) | **EXCLUDED entirely** — do not show it, do not mention it. The agent confirmed it; the human's time is better spent on judgment calls. |
| `UNVERIFIED` (Playwright unavailable) | **INCLUDE**, annotated: "agent could not verify — check manually" |
| `FAILED-cosmetic` | **INCLUDE as low-priority note** — not a blocker, human may choose to accept or reject |
| `FAILED` (BLOCKING) | Agent should have caught this in verify-self and back-looped already. If it appears here, **INCLUDE as blocker** and note it was missed by verify-self. |

**Severity reference** (for classifying any new issues found during human testing):
- **BLOCKING:** blank page, JS console error, crash, missing required element, broken navigation, auth failure, data loss, wrong HTTP status on critical endpoint
- **COSMETIC:** spacing, color, copy, minor layout deviation, non-critical missing decoration

**BLOCKED items:** Any leaf that cannot be tested because another leaf failed must be marked `<!-- status: BLOCKED: depends on <node> -->` and shown explicitly — never silently skipped.

### 4. Present Checklist

For each leaf item (after filtering), present as:

```markdown
## Manual Verification — Phase <N>

### Happy Path
- [ ] P1.verify-human.1: <action> → Expected: <result>
- [ ] P1.verify-human.2: <action> → Expected: <result>

### Edge Cases
- [ ] P1.verify-human.3: <edge case> → Expected: <result>

### Blocked (cannot test until above resolved)
- [ ] P1.verify-human.4: BLOCKED: depends on P1.verify-human.1

### Agent could not verify (check manually)
- [ ] P1.verify-human.5: <item> [UNVERIFIED by agent]
```

### 5. Pause for the human
Present the checklist and wait.

### 6. Record Results
As the human works through each item, record their result per leaf:
- Pass → mark leaf `[x]` in WIP tree
- Fail → mark leaf `<!-- status: FAILED -->`, note what was observed
- Blocked → keep `BLOCKED` status until its dependency resolves

### 7. Evaluate Results

**All leaves [x] (F13 — human approves):**
- Mark `verify-human` node `[x]` in WIP tree (only valid when ALL leaves are `[x]`)
- Update `## Current Node`: clear active scope, verify-human complete
- Tell user to run `/feature-verify-codify`

**Any leaf FAILED (F12 — back-loop):**
- Do NOT mark verify-human complete
- Update `## Current Node`: set Active scope to the specific failed leaf IDs (e.g. `P1.verify-human.2, P1.verify-human.3`)
- Tell user to run `/feature-build P1.verify-human.2,P1.verify-human.3` with the exact failed leaf IDs as args

### 8. Emit Transition
End your output with the canonical transition token so the orchestrator can act on it (the orchestrator reads `TRANSITION: <id>`; the bare slash-command prose above is advisory for single-step users only):

- `TRANSITION: F13` — human approves all leaves, hand off to verify-codify
- `TRANSITION: F11` — human confirmed skip (no integration boundary, isolated artifacts only), hand off to verify-codify
- `TRANSITION: F12` — human rejected one or more leaves, back-loop to build with scoped leaf IDs

**Scope:** {{args}}
