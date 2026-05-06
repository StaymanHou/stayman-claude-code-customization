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

## Severity Taxonomy

Use this taxonomy consistently when classifying failures. It is also embedded in the subagent prompt.

| Severity | Definition | Examples |
|----------|-----------|---------|
| **BLOCKING** | The feature cannot be considered working. A human handed this would immediately reject it. | Blank page or white screen; JS console error on load; application crash; missing required element (form field, button, nav link); broken navigation (404, redirect loop); auth failure (can't log in); data loss (save doesn't persist); wrong HTTP status on a critical endpoint (500 instead of 200, 404 on existing resource) |
| **COSMETIC** | The feature works but has a visual or copy imperfection. A human might note it but would not reject the phase. | Spacing or padding off; wrong color or font; copy typo or wrong label text; minor layout deviation from design; non-critical missing decoration (icon, border radius) |

**Decision rule:** When in doubt, classify as BLOCKING. A false BLOCKING sends you to fix something minor; a false COSMETIC ships a broken feature to the human.

## Integration-boundary rule

A phase has an **integration boundary** when any of the following is true of the implementation leaves under the current phase:

1. A line of code was added or modified inside a file that an existing HTTP endpoint, route, controller, GraphQL resolver, RPC handler, or middleware already consumed.
2. A line of code was added or modified inside a file that backs an existing UI page, view, or component such that user-visible behavior changes.
3. A line of code was added or modified inside an existing CLI command, subcommand, or argument parser.
4. A line of code was added or modified inside an existing scheduled job, cron, queue consumer, or background worker.
5. The request/response shape, payload, or destination of an existing outbound call to an external system was changed.

If a boundary applies, **at least one Observable Outcome for this phase must cite the consuming surface by name** — the existing endpoint path, route URL, UI page URL, CLI command, job name, or external-call target. An outcome that only exercises the new module or new dedicated admin/status endpoints does not satisfy this rule.

If you reach §1 of the procedure and find the current phase has a boundary but no outcome citing the consuming surface, **do not run the verification subagent**. Instead, document the missing outcome and back-loop to build (F9b) so the plan can be updated and the missing outcome verified. Cite the specific consuming surface (e.g. `POST /distribution/match`) in your back-loop message.

If a boundary does not apply (the phase only adds isolated new artifacts — a new module nothing imports, a new endpoint nothing links to, a constant, a renamed private function), this rule does not apply. Note in your output: "No integration boundary — phase adds isolated new artifacts only."

## Procedure

### 1. Read inputs

- Read the WIP file in `workflow/wip/`
- Identify the current phase from `## Current Node`
- Extract the **Observable outcomes** for that phase
- Confirm the dev URL from `{{args}}` — if empty, stop and ask the user for it before proceeding
- Determine whether this phase has an **integration boundary** (see "Integration-boundary rule" above). If yes, confirm at least one Observable Outcome cites the consuming surface; if no such outcome exists, follow the back-loop guidance in that section.

### 2. Spawn self-verification subagent

Spawn an `Agent` with the following information baked into the prompt (the subagent is one-shot — all context must be in the prompt):

```
You are a QA verification agent. Your job is to observe a running application and report pass/fail for each observable outcome. Do NOT fix anything — observe only.

Dev URL: <url from args>

Observable outcomes to verify:
<paste the Observable outcomes list from the current phase>

Severity taxonomy:
- BLOCKING: blank page or white screen, JS console error on load, application crash, missing required element (form field, button, nav link), broken navigation (404/redirect loop), auth failure, data loss (save doesn't persist), wrong HTTP status on critical endpoint (500 instead of 200, 404 on existing resource)
- COSMETIC: spacing/padding off, wrong color or font, copy typo or wrong label, minor layout deviation, non-critical missing decoration (icon, border radius)
- When in doubt, classify as BLOCKING.

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
