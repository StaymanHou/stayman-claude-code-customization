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

## Orchestrator Pause Policy (cheat-sheet)

When invoked by `/session-start` in orchestrated mode, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause. Per-skill rows for verify-self's exits:

| Transition | Mode 1 — Step-by-step | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — Full-autopilot |
|---|---|---|---|---|
| F10b (verify-self → verify-human) | PAUSE | AUTO (chain into verify-human, which itself PAUSEs) | AUTO (chain into verify-human, which itself PAUSEs) | AUTO — **skip verify-human entirely**, chain directly to `feature-verify-codify` |
| F9b (back-loop to build) | PAUSE | AUTO | AUTO | AUTO |

**Hard rule for AUTO exits.** When this skill's emitted transition is `AUTO` in the current drive mode, the orchestrator **must immediately invoke the next skill via the `Skill` tool**. It must **NOT** return control to the user. Emitting a clean `TRANSITION: F10b` followed by a polite narrative summary ("Verify-self complete; ready to run verify-human") is the regression mode this block exists to prevent (P1 incident, 2026-05-16): the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. See `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## Severity Taxonomy

Use this taxonomy consistently when classifying failures. It is also embedded in the subagent prompt.

| Severity | Definition | Examples |
|----------|-----------|---------|
| **BLOCKING** | The feature cannot be considered working. A human handed this would immediately reject it. | Blank page or white screen; JS console error on load; application crash; missing required element (form field, button, nav link); broken navigation (404, redirect loop); auth failure (can't log in); data loss (save doesn't persist); wrong HTTP status on a critical endpoint (500 instead of 200, 404 on existing resource) |
| **COSMETIC** | The feature works but has a visual or copy imperfection. A human might note it but would not reject the phase. | Spacing or padding off; wrong color or font; copy typo or wrong label text; minor layout deviation from design; non-critical missing decoration (icon, border radius) |

**Decision rule:** When in doubt, classify as BLOCKING. A false BLOCKING sends you to fix something minor; a false COSMETIC ships a broken feature to the human.

## Subagent Re-Verification Heuristic

**Rule:** If N-1 of N outcomes PASS and the Nth FAIL is mechanically implied by the PASSes, suspect snapshot timing before back-looping; re-run the same Playwright assertions directly from the orchestrator before invoking `/feature-build` with scoped leaves.

**Why this exists:** Verify-self subagents observe the page through Playwright snapshots. On pages whose interactive surface is JIT-compiled in the browser (Babel-standalone in-page transformation), lazily mounted (React lazy / async chunks), or hydrated after an async data fetch, the subagent's snapshot can be taken *before* the relevant DOM/handlers exist. The subagent then reports a BLOCKING FAIL on an outcome that — at observation time — was genuinely not satisfiable, but which the page **does** satisfy a few hundred milliseconds later. Back-looping to build at that point sends the next phase to fix a non-bug.

**Trigger pattern (all conditions must hold):**

1. The subagent reported at least one PASS in the same run.
2. The reported FAIL is **mechanically implied** by the PASSes — i.e., the failing outcome cannot be false if the passing outcomes are true. ("The hash-restore PASS asserts viewport=720:780, which mechanically implies the ticks PASS that just FAILed must also be true.") This is the calibration that separates genuine fails from snapshot-timing noise.
3. The page under test uses an in-browser JIT pipeline, lazy mount, or pre-render async fetch.

If any one of these does not hold, treat the FAIL as genuine and back-loop normally.

**Procedure when the heuristic fires:**

1. Do **not** mark the failed leaf `FAILED` yet. Do not emit `TRANSITION: F9b`.
2. Re-run the failing outcome's assertions **directly from the orchestrator** (not via a fresh subagent) using the same Playwright MCP tools the subagent used. Wait for the interactive surface to be ready before asserting (`browser_wait_for` on a known late-mounting selector, or `browser_evaluate` to poll for the relevant `window.*` value before snapshotting).
3. Common workaround for React-controlled UI: synthetic DOM events (clicks dispatched via `browser_click` on stale snapshots, `WheelEvent` dispatched via `browser_evaluate`) often do not reach React's synthetic event system on a JIT page. Direct invocation via the React fiber works reliably: `browser_evaluate` something like `el[Object.keys(el).find(k => k.startsWith('__reactProps'))].onClick()` (or equivalent for `onChange`, `onWheel`, etc.). This pattern has been the consistent fix across multiple instances of this heuristic firing.
4. If the direct re-verification **PASSes**: the original FAIL was a snapshot-timing artifact. Mark the leaf `[x]`, document the re-verification in the WIP file (one line: "Re-verified directly; subagent's FAIL was snapshot-timing noise — orchestrator confirmed PASS."), and proceed to F10b.
5. If the direct re-verification **FAILs** the same way: the FAIL is genuine. Mark the leaf `FAILED`, document the orchestrator-side re-verification result, and back-loop F9b normally.

**What this heuristic is not:** It is not license to override subagent findings whenever a FAIL is inconvenient. The mechanical-implication test is the gate — if you cannot state in one sentence why the PASSes imply the FAIL must also be true, the FAIL is genuine and back-loop is the right path.

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
- `FAIL / BLOCKING` → **before marking `FAILED`, check the Subagent Re-Verification Heuristic above.** If the FAIL is mechanically implied by sibling PASSes on a JIT-compiled / lazy-mount / async-fetch page, re-verify directly from the orchestrator before classifying. Otherwise, mark leaf `FAILED` with detail.
- `FAIL / COSMETIC` → mark leaf with `<!-- status: FAILED-cosmetic -->` and note — does NOT block handoff

**Playwright unavailable:** If the subagent errors on Playwright tools, fall back to curl-only for HTTP outcomes. Annotate browser outcomes as `<!-- status: UNVERIFIED: Playwright MCP not available — check manually -->`. These items ARE surfaced to verify-human.

#### In-place fix shortcut (BLOCKING-fail handling — narrow exception)

verify-self is contractually observe-only: BLOCKING failures normally route through the F9b back-loop to `feature-build`. This sub-clause defines a narrow exception that permits an in-place fix when the back-loop would cost 3 extra Skill invocations (build → verify-auto → verify-self) for an outcome equivalent to what the back-loop itself would have produced.

**All three gates must hold:**

1. **Trivial extension of the just-completed leaf.** The fix is a one-line (or small, mechanical) extension of code/config/test scaffolding written in the just-completed impl leaf. It is *not* a redesign, a re-plan, a new abstraction, or a fix that crosses files/modules outside the leaf's scope. If you cannot describe the fix in one sentence as "extend X that was just written in P<N>.<M>", the gate fails — use F9b instead.
2. **Fresh model invocation re-verifies.** Re-verification of the fixed leaf goes through a fresh model invocation — either a freshly-spawned Playwright subagent (preferred, identical artifact to what F9b → verify-self would produce), or a fresh `Skill` invocation of `feature-verify-self` against the same Observable Outcome. Re-verification by the same agent re-reading its own state does NOT count and does NOT satisfy this gate.
3. **Audit-trail entry in WIP `## Discoveries`.** Append an entry of the form `[SHORTCUT-<YYYY-MM-DD>] <leaf-id> — <one-line description of what was fixed and how it was re-verified>` to the WIP file's `## Discoveries` section before transitioning. The entry is the artifact a reviewer can grep for when reconstructing why the F9b back-loop was bypassed.

When all three gates hold (trivial extension + fresh re-verification + audit-trail entry): apply the fix in-place, re-verify per gate 2, mark the leaf `[x]`, append the `## Discoveries` entry, and proceed to F10b. When any gate fails: do not shortcut — back-loop F9b normally.

**What this shortcut is NOT.** It is not license to override genuine BLOCKING failures whenever a fix is convenient. It is not a fast-path for non-trivial fixes that happen to be in the same file. It is not a substitute for re-planning when the plan was wrong (use F23 instead). The triviality + fresh-re-verification + audit-trail gates are the boundary; the agent's comfort with the fix is not.

Rule of three observed instances codified 2026-06-09: v3 WP3 Phase 2 (2026-05-29), v3 WP11 Phase 1 (2026-06-06), verify-human-auto-skip-when-no-integration-boundary Phase 2 (2026-06-07). All three were ad-hoc deviations user-approved at verify-human; this clause formalizes them.

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

### 6. Emit Transition
End your output with the canonical transition token so the orchestrator can act on it (the orchestrator reads `TRANSITION: <id>`; the bare slash-command prose above is advisory for single-step users only):

- `TRANSITION: F10b` — all blocking outcomes pass (cosmetic-only is fine), hand off to verify-human
- `TRANSITION: F9b` — blocking failure found, back-loop to build with scoped leaf IDs

**Scope:** {{args}}
