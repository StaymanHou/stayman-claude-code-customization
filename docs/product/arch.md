---
stage: arch
state: complete
updated: 2026-04-25
---

# Architecture

**Phase:** Phase 1 (Problem Tree & Structured Verification) + Phase 2 (Agent Self-Verification)

This system has no runtime, no services, and no database. The "architecture" is entirely: file schemas that skills read and write, and skill prompt contracts that enforce behavior. Every decision here is a format decision or a skill contract decision.

---

## Dev Environment

**Host-based (opt-out).**

**Rationale:** This repo contains only markdown files and shell scripts. There are no services, no language runtimes to isolate, no dependency graphs. The only runtime dependency is the `claude` CLI itself, which runs on the host. Docker would add friction with zero benefit — there is nothing to containerize.

---

## Tech Stack

- **Format:** Markdown — established convention for all existing skills, WIP files, and fixtures. No change.
- **Structured metadata within markdown:** Inline HTML comments `<!-- status: X -->` — chosen over YAML frontmatter (too high token cost for inline node annotation) and JSON embedding (breaks human readability). HTML comments are invisible in rendered markdown, machine-readable by LLM, and zero overhead.
- **Position pointer:** A `## Current Node` section in every WIP file — a compact human-readable summary of where in the tree the agent currently is, what is in scope, and what is blocked. Eliminates full-tree re-parse on every skill entry.
- **Playwright MCP:** `mcp__playwright__` tool namespace — for live-system self-verification. Tools declared in skill `allowed-tools` frontmatter, invoked as direct tool calls (not bash).

---

## File Schema: Work Tree WIP Format

This replaces the current flat-checklist WIP format. All feature and task WIP files adopt this schema.

### Full annotated example

```markdown
# Feature: <Name>

**Workflow:** feature
**State:** <current skill state>
**Created:** <YYYY-MM-DD>

## Problem Statement
<One paragraph. Re-examined on every back-loop entry — not static.>

## Work Tree
<!-- Rules:
  - Max 4 levels: Feature > Phase > Verification-group > Leaf
  - Every non-complete node carries a status tag
  - A parent's checkbox can only be [x] when ALL children are [x]
  - Discoveries attach as SURFACED leaf nodes under the relevant parent
-->

- [ ] Phase 1: <name>  <!-- status: complete -->  ← use [x] when done
  **Observable outcomes:**
  - Browser: <declarative outcome>
  - HTTP: <declarative outcome>
  - CLI: <declarative outcome>
  - [x] P1.1 <impl task>
  - [x] P1.2 <impl task>
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete -->
    - [x] <check item>
    - [x] <check item>
  - [x] verify-codify  <!-- status: complete -->

- [ ] Phase 2: <name>  <!-- status: in-progress -->
  **Observable outcomes:**
  - Browser: page at /login renders with input[name=email], input[name=password], button[type=submit]
  - Browser: no JS errors in console on page load
  - HTTP: POST /api/login with valid creds → 200 + Set-Cookie header
  - [ ] P2.1 <impl task>  <!-- status: in-progress -->
  - [ ] P2.2 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 3: <name>  <!-- status: NOT-STARTED; depends on Phase 2 -->
  **Observable outcomes:**
  - <...>

## Current Node
- **Path:** Feature > Phase 2 > P2.1
- **Active scope:** P2.1 (currently implementing)
- **Blocked:** verify-human > check-C (blocked by check-A resolution)
- **Unvisited:** Phase 3
- **Open discoveries:** none

## Discoveries
<!-- Surfaced items that don't belong to the current phase.
     Each entry is also logged to workflow/backlog.md.
     Format: [SURFACED-<date>] <target node> — <summary> -->
```

### Status vocabulary

| Tag | Meaning |
|-----|---------|
| `NOT-STARTED` | Node exists in plan, not yet reached |
| `in-progress` | Agent is actively working this node |
| `FAILED` | Human or agent reported failure; must be resolved before parent advances |
| `BLOCKED: depends on <node>` | Cannot be tested/executed until named node is resolved |
| `SURFACED: <summary>` | Discovery attached here; agent logged it to backlog |
| `[x]` checkbox (no tag) | Complete — all children also complete |

### Depth rule

Four levels maximum: **Feature > Phase > Verification-group > Leaf item**. If a phase becomes too complex, split into two phases (siblings) rather than adding a 5th level.

---

## File Schema: Task WIP Format (lighter variant)

Tasks are simpler — no per-phase verification loop, no observable outcomes section. But they gain the same Current Node pointer and discovery attachment.

```markdown
# Task: <Name>

**Workflow:** task
**State:** <current skill state>
**Created:** <YYYY-MM-DD>

## Problem Statement
<One sentence. Re-examined on back-loop entry.>

## Work Tree
- [ ] T1 <step>  <!-- status: in-progress -->
- [ ] T2 <step>  <!-- status: NOT-STARTED -->
- [ ] T3 <step>  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Task > T1
- **Active scope:** T1
- **Open discoveries:** none

## Discoveries
```

---

## Skill Contract Changes

### Skills that write the Work Tree

| Skill | Change |
|-------|--------|
| `feature-plan` | Emits Work Tree format with Phase nodes, Observable Outcomes per phase, all verification group nodes pre-populated as `NOT-STARTED` |
| `task-plan` | Emits lighter Work Tree format with step nodes and Current Node |

### Skills that read + update the Work Tree

| Skill | Entry action | Exit action |
|-------|-------------|-------------|
| `feature-build` | Read Current Node for scope. If scoped args present (failed leaf IDs), restrict work to those leaves only. Attach discoveries to correct phase node. | Update leaf statuses. Update Current Node. Verify no parent has all-complete children without being marked complete itself. |
| `feature-verify-auto` | Read current phase's Observable Outcomes. Run live-system checks (Playwright/curl/CLI) against them. Classify failures as blocking/cosmetic. | Write results as leaf nodes under `verify-auto` node. Update `verify-auto` status. Update Current Node. |
| `feature-verify-human` | Read current phase's `verify-human` node. Expand into leaf items if empty (first run). Present only items not yet `[x]`. Note BLOCKED items explicitly. | Update each leaf's status individually. If any `FAILED`, update Current Node with failed leaf IDs as active scope for re-entry to build. Only mark `verify-human` complete when ALL leaves are `[x]`. |
| `feature-verify-codify` | Read phase node to confirm verify-human is complete before proceeding. | Update `verify-codify` status. If all phases complete, update feature-level status. |
| `task-act` | Read Current Node for scope. Attach discoveries to correct task node. | Update node statuses. Update Current Node. |

### Skills that add Playwright tools

| Skill | New allowed-tools additions |
|-------|----------------------------|
| `feature-verify-auto` | `mcp__playwright__browser_navigate`, `mcp__playwright__browser_snapshot`, `mcp__playwright__browser_console_messages`, `mcp__playwright__browser_take_screenshot` |
| `feature-build` (re-verify gate) | Same as above — needed for re-verify after fix |

---

## Key Decisions

- **HTML comments for status, not YAML frontmatter:** Inline node metadata must live next to the node, not in a separate section. YAML frontmatter can only appear once per file. HTML comments survive markdown rendering, are invisible to humans reading rendered output, and are reliably parsed by LLMs. Alternative (inline emoji badges like `🔴`) was rejected — ambiguous, not machine-readable by convention.

- **`## Current Node` as position pointer, not derived from tree parse:** The LLM should not have to re-traverse the full tree on every skill entry to find its position. Current Node is a first-class section, written on skill exit, read on skill entry. It is the authoritative answer to "where are we and what's in scope." If it ever diverges from the tree (bug), the tree wins and Current Node is rewritten.

- **Observable outcomes written at plan time, not verify time:** At plan time, the agent understands intent. At verify time, it understands implementation. Outcomes written at verify time are post-hoc and biased toward what was built. Outcomes written at plan time define the target and catch cases where what was built doesn't match what was intended.

- **`feature-verify-auto` gains live-system observation, not just test runner:** The self-verification step runs Playwright/curl against Observable Outcomes before handing to human. This is not a replacement for the test suite — both run. The test suite catches unit-level regressions; the live-system check catches integration failures, environment issues, and UX-visible breakage that tests don't exercise.

- **Re-verify gate lives in `feature-build`, not `feature-verify-auto`:** When build re-enters after a human rejection, it must self-verify before handing back. This gate belongs at build exit, not verify-auto entry — because the agent doing the fix knows exactly what it changed and should immediately verify the specific failed items, not re-run the full suite.

- **Playwright MCP falls back gracefully:** Skills check whether Playwright MCP is available. If not, they fall back to curl for HTTP checks and note which browser checks could not be completed. The human checklist for those items is annotated "agent could not verify — check manually." No hard failure if MCP is absent.

---

## What Does NOT Change

- The state machine in `docs/product/transitions.md` — no new states, no new transitions for Phases 1–2. The tree format changes what lives inside WIP files; it does not change the state machine.
- The `feature-spec`, `feature-research`, `feature-ship`, `feature-finalize`, `feature-refactor` skills — they don't touch the Work Tree during Phase 1.
- Product-workflow skills (`product-*`) — unaffected by Phases 1–2.
- Incident-workflow skills — unaffected.
- `session-*` skills — unaffected. The Work Tree is carried transparently through pause/resume because it lives in the WIP file.
- `install.sh` — no new files, no new symlinks needed for Phases 1–2.
