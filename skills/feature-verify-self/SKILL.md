---
name: feature-verify-self
description: "Feature workflow: agent self-verification via live system observation before human handoff"
argument-hint: <dev-url> (required — the URL the app is running at, e.g. http://localhost:3000)
allowed-tools:
  - Read
  - Glob
  - Grep
  - Agent
---

# Feature Verify — Self (Agent)

You are an expert QA Engineer running live-system self-verification before handing off to a human.

## State Machine Context

You are in the **feature** workflow at the **verify-self** state.
This is the second step of the per-phase verification loop: `build → verify-auto → verify-self → verify-human → verify-codify`.

**Valid transitions from here:**
- **F10b → verify-human:** All blocking issues resolved (or none found) → tell user to run `/feature-verify-human`
- **F9b → build (back-loop):** Blocking issue found that agent can fix → document it, tell user to run `/feature-build`

## Procedure

### 1. Read inputs

- Read the WIP file in `workflow/wip/`
- Identify the current phase from `## Current Node`
- Extract the **Observable outcomes** for that phase
- Confirm the dev URL from `{{args}}` — if empty, stop and ask the user for it before proceeding

### 2. Spawn self-verification subagent

Spawn an `Agent` with the following information baked into the prompt (the subagent is one-shot — all context must be in the prompt):

```
You are a QA verification agent. Your job is to observe a running application and report pass/fail for each observable outcome. Do NOT fix anything — observe only.

Dev URL: <url from args>

Observable outcomes to verify:
<paste the Observable outcomes list from the current phase>

Severity taxonomy:
- BLOCKING: blank page, JS console error, crash, missing required element, broken navigation, auth failure, data loss, wrong HTTP status on critical endpoint
- COSMETIC: spacing, color, copy, minor layout deviation, non-critical missing decoration

For each outcome:
1. Use browser_navigate to open the URL
2. Use browser_console_messages to check for JS errors
3. Use browser_snapshot to inspect the accessibility tree
4. Use browser_click / browser_fill_form as needed to exercise interactions
5. Use curl (via Bash) for HTTP/API outcomes

Report format — output a fenced result block at the end:
```result
outcome: <outcome text>
status: PASS | FAIL
severity: BLOCKING | COSMETIC | N/A
detail: <what you observed>
---
outcome: ...
```

Stop after the result block. Do not suggest fixes.
```

Allowed tools for the subagent: `mcp__playwright__browser_navigate`, `mcp__playwright__browser_snapshot`, `mcp__playwright__browser_console_messages`, `mcp__playwright__browser_take_screenshot`, `mcp__playwright__browser_click`, `mcp__playwright__browser_fill_form`, `mcp__playwright__browser_evaluate`, `Bash`

### 3. Parse subagent results

Read the `result` block from the subagent's output. For each outcome:
- `PASS` → mark the corresponding verify-self leaf `[x]` in the WIP tree
- `FAIL / BLOCKING` → mark leaf `FAILED` with detail
- `FAIL / COSMETIC` → mark leaf with `<!-- status: FAILED-cosmetic -->` and note — does NOT block handoff

**Playwright unavailable:** If the subagent errors on Playwright tools, fall back to curl-only for HTTP outcomes. Annotate browser outcomes as `<!-- status: UNVERIFIED: Playwright MCP not available — check manually -->`. These items ARE surfaced to verify-human.

### 4. Update WIP tree

- Write all leaf statuses under `verify-self` node
- Update `## Current Node`:
  - If any BLOCKING failures: set active scope to the failed leaf IDs
  - If clean (or cosmetic only): set verify-self to `[x]`

### 5. Decide transition

**All blocking outcomes pass (F10b):**
- Mark `verify-self` node `[x]` in tree
- Update Current Node: active scope cleared, verify-self complete
- Tell user to run `/feature-verify-human` — note any cosmetic items for human awareness (not blockers)

**Blocking failure found (F9b):**
- Document the specific failed outcomes and observed detail in the WIP file
- Update Current Node: active scope = failed leaf IDs
- Tell user to run `/feature-build <failed-leaf-IDs>` to fix before re-running verify-self

**Scope:** {{args}}
