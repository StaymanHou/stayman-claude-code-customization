---
stage: research
state: complete
updated: 2026-04-25
---

# Research

**Phase Focus:** Phase 1 (Problem Tree & Structured Verification) with forward relevance to Phase 2 (Agent Self-Verification)

---

## Q1: What format should the Work Tree use?

### What the current format looks like

Current WIP files (`tests/fixtures/wip/feature-plan-phase1.md`) are flat markdown with prose phase headings and unnested checkboxes. There is no node identity, no status beyond checked/unchecked, no parent-child enforcement, and no dependency notation. The `verify-human` fixture is a completely separate flat checklist with no structural link to the phase tree.

### Research findings

Three approaches were evaluated:

**Option A: Pure nested markdown checkboxes**
```
- [ ] Phase 2: Login page
  - [ ] A.1 Implement form
  - [ ] A.2 ✓ verify-human
    - [ ] A.2.1 Login works  ← FAILED
    - [ ] A.2.2 Text color readable  ← FAILED
    - [ ] A.2.3 Redirect after login  ← BLOCKED
```
- Pro: Human-readable, diffable, no parsing overhead
- Con: Deep nesting (4+ levels) causes LLM parsing ambiguity. Checkbox state alone is unreliable for LLM context rebuilding across sessions — the model must re-read the whole tree to understand position. No machine-readable status beyond binary checked/unchecked.

**Option B: YAML/JSON embedded in markdown**
- Pro: Structured, unambiguous, parseable
- Con: High token cost. Loses human readability. Diverges from the existing skill/WIP markdown convention. Maintenance friction.

**Option C: Markdown nested lists with inline status tags + a Current Node section (recommended)**
```markdown
## Work Tree
- [ ] Phase 2: Login page  <!-- status: in-progress -->
  - [x] A.1 Implement form
  - [ ] A.2 verify-human  <!-- status: in-progress -->
    - [ ] A.2.1 Login works  <!-- status: FAILED -->
    - [ ] A.2.2 Text color readable  <!-- status: FAILED -->
    - [ ] A.2.3 Redirect after login  <!-- status: BLOCKED: depends on A.2.1 -->
  - [ ] A.3 verify-codify
- [ ] Phase 3: Notifications UI  <!-- status: NOT-STARTED; depends on Phase 2 -->

## Current Node
- **Path:** Phase 2 > A.2 verify-human
- **Active scope:** A.2.1, A.2.2 (failed leaves — re-entering build for these only)
- **Blocked leaves:** A.2.3 (blocked by A.2.1)
- **Unvisited siblings:** Phase 3, Phase 4
```
- Pro: Human-readable and diffable. Keeps tree shallow (3–4 levels max). Inline `<!-- status: X -->` comments give the LLM unambiguous machine-readable state without breaking markdown rendering. The **Current Node** section is a compact position pointer the agent reads first — eliminates the need to parse the full tree to find current position.
- Con: HTML comments are a slight convention departure. Requires discipline to keep Current Node in sync.

### Decision

**Option C.** Markdown nested lists, max 4 levels, with inline `<!-- status: X -->` tags and a mandatory `## Current Node` section. Activity log research (Task Memory Engine paper) confirms that a compact position-pointer is more reliable for LLM context rebuilding than relying on checkbox parse state alone.

**Status vocabulary:**
- `NOT-STARTED` — not yet reached
- `in-progress` — currently active
- `FAILED` — human or agent reported failure
- `BLOCKED: depends on <node>` — cannot be tested until dependency resolves
- `SURFACED: <summary>` — discovery attached here, belongs to this node
- `[x]` checkbox — complete (no status tag needed)

**Depth rule:** Tree nodes are: Feature > Phase > Verification group > Individual check item. Four levels maximum. Do not nest deeper — flatten into sibling nodes instead.

---

## Q2: How does Playwright MCP integrate into skills?

### Research findings

Playwright MCP tools are available in Claude Code as deferred tools under the `mcp__playwright__` namespace:
- `mcp__playwright__browser_navigate` — open a URL
- `mcp__playwright__browser_snapshot` — return the accessibility tree (text-based, LLM-optimal — preferred over screenshots)
- `mcp__playwright__browser_take_screenshot` — pixel screenshot (use only when accessibility tree is insufficient)
- `mcp__playwright__browser_click`, `browser_fill_form`, `browser_type`, `browser_evaluate` — interactions
- `mcp__playwright__browser_console_messages` — retrieve JS console output (critical for catching blank-page errors)
- `mcp__playwright__browser_network_requests` — inspect network activity

**Key insight:** `browser_snapshot` returns the accessibility tree, not pixels. This is what the LLM reasons about — it sees the semantic structure of the page (buttons, inputs, headings, their labels and states) not visual layout. This is reliable for detecting blank pages, missing elements, and structural errors. `browser_console_messages` is the correct tool for detecting JS errors — equivalent to opening DevTools console.

**Invocation in skills:** Skills list `mcp__playwright__*` tools in their `allowed-tools` frontmatter. The tools are deferred (schema not loaded by default) — skills that need them must specify them. The agent invokes them directly as tool calls, not via bash.

**Practical self-verification sequence for a web app:**
1. `browser_navigate` to the local dev URL
2. `browser_console_messages` — if any errors, classify severity before proceeding
3. `browser_snapshot` — verify expected elements are present
4. Interact if needed (`browser_click`, `browser_fill_form`)
5. `browser_snapshot` again — verify post-interaction state

### Decision

Phase 2 skills (`feature-verify-auto`) should add `mcp__playwright__browser_navigate`, `mcp__playwright__browser_snapshot`, `mcp__playwright__browser_console_messages` to `allowed-tools`. The behavioral definition of done format should encode expected elements as accessibility-tree queries (e.g., "page contains a button with label 'Submit'") not CSS selectors or pixel coordinates.

---

## Q3: What format for behavioral definitions of done?

### Research findings

The observability literature frames "definition of done" as **declarative observable outcomes** — what should be true about the running system from the outside — rather than implementation assertions or test code. The key distinction: observable outcomes survive code refactors; implementation assertions break with every rename.

Effective observable outcome formats from prior art:
- HTTP: `GET /login → 200, body contains {token: string}`
- Browser: `page snapshot contains element: button[label="Submit"]`
- CLI: `command exits 0, stdout matches pattern X`
- Console: `no errors in browser console`

These are readable by both human and LLM, require no test framework, and can be verified with curl, Playwright snapshot, or bash — all tools available in skills.

### Decision

Behavioral definitions of done live as a sub-section of each Phase node in the Work Tree:

```markdown
- [ ] Phase 2: Login page  <!-- status: in-progress -->
  **Observable outcomes:**
  - Browser: page at /login renders with input[name=email], input[name=password], button[type=submit]
  - Browser: no JS errors in console on page load
  - HTTP: POST /api/login with valid creds → 200 + Set-Cookie header
  - Browser: after login, redirects to /dashboard
  - Browser: after login, nav bar shows user avatar
```

This section is written by `feature-plan` at plan time and read by `feature-verify-auto` at verify time. It is the agent's verification target. Items that can be checked by the agent (Playwright, curl) are pre-filtered from the human checklist.

---

## Risks

- **Tree update discipline:** Skills must reliably update the tree on entry and exit. If a skill exits without updating Current Node, the next skill has stale position. Mitigation: make Current Node update a named final step in every skill's procedure, same weight as "tell user to run /next-skill."
- **Playwright availability:** If the user hasn't configured Playwright MCP, skills that depend on it will fail silently or error. Mitigation: skills check for Playwright availability; fall back to curl for HTTP-only checks; note what could not be self-verified.
- **Tree depth creep:** As features grow, teams will be tempted to add nesting levels. Enforcing the 4-level max in the skill prompt is the only guard. Beyond 4 levels, flatten to siblings.
- **Fixture maintenance:** All 14 existing WIP test fixtures will need to be updated to the new tree format for Phase 1 tests to pass.

---

## References

- [Task Memory Engine (TME): Enhancing State Awareness for Multi-Step LLM Agent Tasks](https://arxiv.org/html/2504.08525v1)
- [The Case for Markdown as Your Agent's Task Format — DEV Community](https://dev.to/battyterm/the-case-for-markdown-as-your-agents-task-format-6mp)
- [Which Nested Data Format Do LLMs Understand Best? JSON vs YAML vs XML vs Markdown](https://www.improvingagents.com/blog/best-nested-data-format/)
- [Using Playwright MCP with Claude Code — Simon Willison's TILs](https://til.simonwillison.net/claude-code/playwright-mcp-claude-code)
- [Playwright MCP & Claude Code: AI-Powered Test Automation Guide](https://testomat.io/blog/playwright-mcp-claude-code/)
- [Playwright MCP Official Docs](https://playwright.dev/docs/getting-started-mcp)
- [AI observability: monitoring and governing autonomous AI agents — Kore.ai](https://www.kore.ai/blog/what-is-ai-observability)
- [LLM Agent Evaluation: Assessing Tool Use, Task Completion, Agentic Reasoning — Confident AI](https://www.confident-ai.com/blog/llm-agent-evaluation-complete-guide)
- [SuperpoweredAI/task-tree-agent — GitHub](https://github.com/SuperpoweredAI/task-tree-agent)
