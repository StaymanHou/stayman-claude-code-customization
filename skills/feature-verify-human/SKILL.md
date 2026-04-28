---
name: feature-verify-human
description: "Feature workflow: guide the human through manual verification of the current phase"
argument-hint: <optional scope or phase number>
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

## Procedure

### 1. Read Current Node
Read the WIP file in `workflow/wip/`. Find `## Current Node` — this tells you which phase's `verify-human` node is active and whether this is a first run or re-entry from a back-loop.

### 2. Assess Whether Human Testing is Needed
Review the current phase and determine if there are user-facing changes that need manual verification.

**If there is genuinely nothing for a human to test** (e.g., purely internal refactor, backend-only logic with full test coverage):
- Present your reasoning for why there's nothing to manually test
- Explicitly ask the human: "I believe there's nothing to manually verify for this phase because [reasoning]. Do you agree to skip to verify-codify?"
- Only proceed to verify-codify (F11) if the human confirms

### 3. Expand verify-human into leaf nodes (first run)

**On first run for this phase** (verify-human node has no children yet):
- Expand the `verify-human` node into individual leaf items in the WIP tree — one leaf per check
- Each leaf gets a node ID (e.g., `P1.verify-human.1`, `P1.verify-human.2`) and `<!-- status: NOT-STARTED -->`

**On re-entry from build back-loop** (verify-human node already has children):
- Present only leaves that are `FAILED` or `BLOCKED` — skip any `[x]` leaves
- Do not re-present items the human already approved

**Pre-filter from verify-self:** Read `verify-self` results in the WIP tree before building the checklist:
- Items `[x]` in verify-self → exclude from human checklist entirely (agent already confirmed)
- Items `UNVERIFIED` → include, annotated "agent could not verify — check manually"
- Cosmetic failures from verify-self → include as low-priority notes, not blockers

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

### 5. Invoke `/notify-human`
Before presenting the checklist, invoke `/notify-human` to alert the user — they may have stepped away during the automated phase.

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

**Scope:** {{args}}
