---
stage: arch
state: complete
updated: 2026-07-15
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

## File Schema: Design Priors Format (`docs/product/design-priors.md`)

A per-project, durable product doc recording the operator's **design priors** — terse, transferable statements of how the operator resolves recurring *product-design* tradeoffs for this project, each paired with its *why*. Planning skills **consult** it to fill product-design gaps the operator's way; capture-checkpoint skills **propose** new priors (operator reviews before write). Priors are **directional and overridable**, never decisive — see "Design priors (GLOBAL)" in `CLAUDE.snippet.md` for the consult-weighting rules and capture discriminant.

**This doc lives in *consuming* projects, never in this repo's own `docs/product/`** — the skill repo ships the schema + skill contracts (behavior), not state (vision.md §6). Absent file = silent no-op at consult time. Created lazily on the first approved capture.

```markdown
---
stage: design-priors
state: in-progress        # priors accrete over time; rarely "complete"
updated: <YYYY-MM-DD>
---

# Design Priors — <project>

<!-- Each prior is terse (a few lines). Fields:
  - slug:          short kebab-case ID, e.g. P-FOCUS (used in [PRIOR: <slug>] disclosures)
  - axis:          the tradeoff axis OR an identity/non-goal/anti-persona statement
  - lean:          the direction the operator leans on that axis, for THIS project
  - inferred-why:  the why CC could infer from the operator's choice alone
  - corrected-why: the operator's true why — PRESERVED as a distinct field WHEN it differs
                   from inferred-why (the gap is the signal this feature exists to capture).
                   Omit only when operator confirms inferred-why is already correct.
  - date:          capture date (YYYY-MM-DD)
-->

## P-FOCUS — audience breadth
- **axis:** laser-focus on one use-case vs. broad applicability
- **lean:** focus — solo founders only; resist breadth toward agencies/teams
- **inferred-why:** operator rejected the agency generalization
- **corrected-why:** the product's bet is depth-for-one-demographic; breadth dilutes the wedge
- **date:** 2026-06-26
```

**Size guard:** consistent with the 300-line product-doc rule (consult-load reads first 100 lines + `^#+ ` headings if exceeded). Priors are terse precisely so this is rarely hit.

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

## Revision 2026-06-26

### Design priors — learned product-design decision principles (`docs/product/design-priors.md`)

A new durable product-doc schema (see "File Schema: Design Priors Format" above) plus a capture/consult skill contract. Planning skills (`product-roadmap`, `product-wbs`, `feature-spec`) **consult** the doc at their `## Step 0` product-context load to fill product-design gaps the operator's way; capture-checkpoint skills (`product-vision`, `product-roadmap`, `product-arch`, `product-wbs`, `feature-spec`, `feature-verify-human`) and the `session-reflect` backstop **propose** new priors (operator reviews the why before write). Priors are directional/overridable, never decisive — the consult-weighting rules, capture discriminant, arch-boundary exclusion (technical/stack tradeoffs stay in *this* file, not design-priors), and the `[PRIOR: <slug>] leaning <x> — flag if wrong` disclosure form are documented in `CLAUDE.snippet.md` → "Design priors (GLOBAL)". **No new transition IDs** — this is behavior within existing states. Shipped by the `design-priors` feature, 2026-06-26.

## Revision 2026-06-13

Architecturally significant additions since the 2026-05-02 revision. Each subsection points to the authoritative source rather than restating procedure — `docs/product/transitions.md` is the canonical state-machine reference, `CLAUDE.md` is the convention-doc home.

### Drive modes (1–4) — orchestrator pause-policy contract

The orchestrator now exposes four drive modes that control pause aggression: **Stepping**, **Orchestrated**, **Autopilot**, **FSD**. The selected mode is recorded as `drive_mode:` in the WIP frontmatter at first skill entry, honored across `/session-pause` + `/session-resume`, and re-checked after every Skill-tool return. Mode 3 (autopilot) auto-skips `verify-human` when no integration boundary is touched AND verify-self is all-PASS. Mode 4 (fsd) skips verify-human entirely. Canonical pause-policy tables live in `docs/product/transitions.md` → "Drive modes". The `TRANSITION: <id>` token at skill exit is the only machine signal — `"Run /x"` prose and `**STOP**` directives in skill output are advisory for single-step users only.

### Executable subagents vs reference-only orchestrator agents (`tools:` frontmatter marker)

`agents/<name>/AGENTS.md` files split into two structural kinds, distinguished by frontmatter shape:
- **Reference-only orchestrators** (frontmatter has `skills:`) — one per workflow group (product, feature, task, incident). Hold the state-machine view + Orchestration Procedure. NOT meant to be spawned via `Agent({subagent_type: ...})`.
- **Executable subagents** (frontmatter has `tools:`) — spawned by skills that name them. Currently `feature-verify-self-runner` (spawned by `feature-verify-self`) and `code-quality-reviewer` (spawned by `feature-review-quality`). The `tools:` field declares the subagent's tool surface.

The frontmatter shape is the structural marker, not documentation. `tests/check-structure.sh` Phase 10 ("Subagent dispatch wiring") enforces both directions: every `tools:`-bearing agent must be referenced by exactly one skill's `Agent({subagent_type: ...})` call, and every such skill call must point to a `tools:`-marked agent. Introduced 2026-06-12 by the `verify-self-and-review-quality-subagent-dispatch` feature.

### `debug-*` skill category — agent-pulled sidebars, not workflow states

A new skill category for ad-hoc debugging techniques that the orchestrator (or user) reaches for when standard debugging stalls inside an existing workflow state. Distinguishing properties:
- Own no state node; emit descriptive `DEBUG-<TECHNIQUE>-<OUTCOME>` tokens **outside** the F/I/T/P/S transition namespace.
- Always emit a `RETURN-TO: <caller-skill>` line so the caller workflow state resumes without consuming a transition ID.
- Required SKILL.md sections enforced by `tests/check-structure.sh` Phase 3b: `## Category Context`, `## When to use`, `## When NOT to use`, `## Procedure` (with `### 1. Gate Check` as the first subheading), `## Pitfalls`, `## Termination`.
- Three discoverability surfaces enforced by Phase 3c: caller-skill prose mentions, orchestrator AGENTS.md "Debug techniques" subsections, `transitions.md` "Sidebar skills" note.

Current sidebars: `debug-bisect-known-good` (codified 2026-05-13), `debug-empirical-telemetry` (shipped 2026-06-10), `debug-minimal-harness` (shipped 2026-06-23 — build a minimal self-driven reproduction and drive it with real input when a behavioral fix has been handed back ≥2× and is drivable in a surface you control). Full category convention in `CLAUDE.md` → Architecture → "`debug-*` Skill Category".

### `util-*` skill category — standalone user-triggered utilities

A third skill category for standalone utilities that the operator invokes manually outside any workflow. Distinguishing properties (vs workflow skills and `debug-*` sidebars):

- **Own no state node** and emit **no transitions** — neither workflow F/I/T/P/S tokens nor `DEBUG-*` tokens. The skill runs, does its work, and ends.
- **No `RETURN-TO:`** — unlike `debug-*` sidebars, util-* skills are not pulled by another workflow; they are entry points themselves.
- **No `tools:` frontmatter** — they are not executable subagents spawned via `Agent()`; they are plain skills invoked via slash command.
- **No `skills:` list** in frontmatter — they are not orchestrators.
- **Frontmatter shape:** `name`, `description`, `argument-hint`. Same minimal shape as a workflow skill, minus all workflow integration.
- **Mode menus are encouraged** for utilities that span an aggression spectrum (Stepping ↔ Autopilot). `util-prune-claude-md` mirrors the workflow drive-mode 1–4 spectrum at skill entry; the operator picks per-invocation rather than a persistent `drive_mode:` (no WIP file to persist into).

Current util-* skills: `util-prune-claude-md` (shipped 2026-06-13 — compacts the project-root `CLAUDE.md` against the 40k-char harness threshold by extracting bulky bullets to `docs/lessons/<topic>.md` or `docs/product/arch.md`); `util-backlog-paydown` (shipped 2026-06-30 — between-milestone backlog-paydown sweep: scores the standing backlog on a 3-axis disposition model and emits a priority/risk-ordered `shape: temporary-wbs` to pay down deferred code-quality/debt; fold-back-and-delete on completion; see `docs/lessons/between-milestone-debt-paydown-sweep.md`). The pre-existing Claude-Code-builtin utilities `init`, `review`, `security-review`, `update-config`, `simplify`, `loop`, `keybindings-help`, `statusline-setup`, `claude-api`, `fewer-permission-prompts` are retroactively considered part of the util-* concept but are NOT renamed (they ship with the Claude Code harness, not from this repo's `skills/` directory). File-based util-* skills authored in this repo use the `util-` prefix; harness-builtin utilities keep their original names.

The category convention is forward-looking (no structural pin yet — `tests/check-structure.sh` would gain util-* pins only if a structural marker becomes load-bearing, mirroring the `debug-*` pin discipline at Phase 3b/3c). Until then, the category is doc-enforced via this section + the `util-` prefix.

**Heading convention (intentional divergence from `debug-*`):** util-* SKILL.md files open their category-statement section with `## Category` — deliberately distinct from `debug-*` skills' `## Category Context` (which is a *pinned* debug-* structural requirement, enforced at `tests/check-structure.sh` Phase 3b). A grep-across-categories audit will therefore see two heading shapes; this is by design, not drift — util-* is a separate category with no pinned heading requirement, so the divergence is intentional and should not be "normalized" away.

### Per-phase verify loop extended with `verify-self`

The feature per-phase loop is now: **build → verify-auto → verify-self → verify-human → verify-codify**. `verify-self` (agent live-system observation) sits between automated checks and human review. Added in WP7 to close the gap where agents handed off to humans without ever observing the running system. Severity taxonomy: BLOCKING (back-loop to build, F9b) vs COSMETIC (forward to verify-human, F10b). In-place fix shortcut formalized 2026-06-09 in `skills/feature-verify-self/SKILL.md` §3 — narrow exception when three gates hold (trivial extension + fresh model invocation + audit-trail entry).

### `task-verify` single-step gate (T5a / T5b / T5c)

Every `task-act` now exits to `task-verify`, not directly to `task-close`. `task-verify` writes an observable into the WIP, runs the verification, and routes T5b (PASS → close) or T5c (FAIL → back-loop to act). Pure-docs tasks may declare `docs-only: true` in WIP frontmatter at plan time to auto-skip the gate. Mirrors `feature-verify-self`'s in-place fix shortcut shape. Shipped 2026-06-11 from `SURFACE-2026-06-09-TASK-WORKFLOW-NEEDS-LITE-VERIFY`. Full procedure in `skills/task-verify/SKILL.md`; transitions in `docs/product/transitions.md` → Task Workflow.

### `feature-review-quality` — post-ship code-quality reviewer subagent

A new state between `feature-ship` and `feature-finalize` invokes a one-shot `code-quality-reviewer` Agent subagent against the ship commit baseline. Severity-tier action matrix (advisory by default, operator-veto via WIP read):
- **CRITICAL** → auto-invokes `feature-refactor` (F40, Modes 2–3)
- **MAJOR** → Mode 2 pause-and-ask (F41) or Mode 3 auto-backlog (F39)
- **MINOR** → auto-backlog (F39)
- **Mode 4** (fsd) skips the skill entirely; `feature-ship` emits F17b directly to finalize when `drive_mode: fsd`

Transitions: F38 (ship→review-quality), F39 (clean/MINOR/Mode-3-MAJOR forward), F40 (CRITICAL→refactor), F41 (Mode-2-MAJOR forward after pause), F17b (Mode-4 SKIP). F17 retired. Reviewer prompt body lives at `agents/code-quality-reviewer/AGENTS.md`. Findings flow forward into refactor or backlog (auto-backlogged findings collect in `workflow/backlog-quality-findings.md`, not the main backlog). Shipped 2026-06-11; subagent-dispatch wiring landed 2026-06-12.

### `incident-codify` — incident-side regression coverage (I19)

Incident workflow gains its own regression-securing step between mitigate and resolve: **mitigate → codify → resolve**. Adapts feature-verify-codify's discipline (highest-level test, integration-boundary check, six-case triage table) with two incident-context flips:
1. A codify-time test failure means the mitigation didn't fix the bug → back-loop to mitigate (I19), not auto-fix the test.
2. Speed-aware paths — Path A reuses an existing reproduce-artifact; Path B writes from scratch; a defer path (I9, with SURFACE→task:plan audit trail) is available when active incident pressure makes writing coverage now infeasible.

Full procedure in `skills/incident-codify/SKILL.md`; transitions in `docs/product/transitions.md` → Incident Workflow.

### `feature-reproduce` — red-green pre-spec/plan step (S18)

Bug-shape features (user describes undesirable behavior — bug, regression, broken state, wrong output) route through `feature-reproduce` *before* spec/plan. The skill produces a failing test or a documented reason local reproduction is infeasible, then hands off to spec or plan. `/session-start` classification step adds bug-shape detection as the first axis of feature classification; ambiguous cases default to skipping reproduce (user can explicitly invoke `/feature-reproduce` if needed).

### Close-commit discipline (workflow-system convention)

The four terminal-close skills (`feature-finalize`, `task-close`, `incident-resolve`, `product-finalize`) commit locally and **never** auto-`git push` — pushing is the operator's call (review window for squash/amend/follow-up-learning before publishing). `session-store-learning` project-scope writes additionally `git add` + `git commit --amend --no-edit` after writing the learning file, folding the artifact into HEAD (typically the just-completed close commit). Global-scope learning writes (gitignored `.claude/learnings/`) opt out of the amend.

Enforced by `tests/check-structure.sh` Phase 11 — 6 `grep_check` pins (4 no-push + 2 amend) + behavioral scenarios `F19`/`T10`/`I10`/`P13`-no-auto-push + `S20`-amend-head. Codifies pre-existing behavior as a load-bearing contract so future drift cannot silently reintroduce auto-push. Shipped 2026-06-12.

### `CHANGELOG.md` convention — terminal-close auto-append contract

Every project that uses this workflow system maintains a human-readable `CHANGELOG.md` at its root. The four terminal-close skills auto-append one-line entries on close with fixed entry-kind vocabulary: `**Feature shipped:**`, `**Task closed:**`, `**Incident resolved:**`, `**Backlog resolved:**`, `**Milestone:**`, `**Product cycle complete:**`. ISO-8601 `## YYYY-MM-DD` date headings, reverse-chronological across days, chronological within a day. Append must happen **before** `git mv` of the WIP file so both stage in the same commit (mitigates `SURFACE-2026-05-10-FINALIZE-RETROSPECT-LOST-IN-GIT-MV` — rename commits dropping unstaged content edits).

Canonical procedure in `CLAUDE.snippet.md` → "CHANGELOG.md convention", injected into `~/.claude/CLAUDE.md` by `install.sh`. **Delete-on-resolve (added 2026-07-15, `SURFACE-2026-07-14-RESOLVED-ENTRY-AUDIT-TRAIL-CLUTTER`):** CHANGELOG is the *sole* resolved-item record — a close **deletes** the resolved entry from `workflow/backlog.md` (and the coupled full body + stub in `workflow/backlog-quality-findings.md`) in the *same commit* as the `**Backlog resolved:**` append, under a CHANGELOG-then-delete hard invariant. The backlog files carry only open work; they never retain a `Status: resolved` line or a `## Resolved` section. Only fully-resolved items are deleted (partial resolutions are rewritten to remaining open work); buried/deferred items are a different lifecycle and are never deleted by this rule.

### Human-in-the-loop alerting (no longer wired)

There is **no notification hook** in the system. An earlier `notify-human` skill (model-driven, unreliable — the model frequently forgot to invoke it) was replaced 2026-05-06 by a deterministic `hooks/notify-telegram.sh` harness hook on `Notification`/`Stop` events; that hook was then removed entirely on 2026-06-24 as no longer needed. Human-input moments (verify-human, triage severity, plan review) still pause the conversation; the operator is simply expected to be watching the session rather than alerted out-of-band. Migration history in `docs/product/transitions.md` change-log.

### Session orchestration runs in the parent conversation, not via Agent spawn

`/session-start` classifies, presents the drive-mode menu, then **drives the workflow in the current conversation** by reading the matching `agents/<workflow>-workflow/AGENTS.md` Orchestration Procedure and invoking each skill via the Skill tool. It does NOT spawn an Agent subagent. Rationale: the Agent tool is one-shot — a subagent that pauses for human input can't be resumed, which would force each human pause to respawn a fresh subagent and lose mid-step state. Keeps user dialogue continuous. Experimental subagent-per-step design parked in `docs/product/transitions.md` → "Experiment: Subagent-Per-Step Orchestration" for future revisit if context growth becomes a problem.

---

## Revision 2026-05-02

Two behavioral additions from the v2 cycle (PP4 + PP5):

### Orchestrator AUTO/PAUSE pause policy

The feature-workflow Orchestration Procedure in `agents/feature-workflow/AGENTS.md` now carries an explicit pause-policy table. Every step is annotated `AUTO` (orchestrator chains immediately) or `PAUSE` (orchestrator waits for human input). The `TRANSITION: <id>` token in skill output is the machine signal; prose "Run `/x`" is for single-step users only.

AUTO steps: build, verify-auto, verify-self, verify-codify, ship, refactor, all back-loops.
PAUSE steps: spec, research, plan, verify-human, finalize, REDIRECT (F22), SURFACE F26.

This is an orchestrator-layer concern only — individual skill SKILL.md files remain agnostic about whether they're running in orchestrated or single-step mode.

### verify-codify test failure triage protocol

`feature-verify-codify/SKILL.md` now requires a mandatory triage step before any action on a failing test. Six cases:

| Classification | Confidence | Action |
|---|---|---|
| Code regression | High | Auto-fix code |
| Code regression | Low/ambiguous | Pause for human |
| Obsolete test | High | Auto-update/delete test |
| Obsolete test | Low/ambiguous | Pause for human |
| Contract conflict (both sides valid) | Any | Always pause |
| Flaky test | — | Re-run 3 total; then pause |

A `## Test Triage` artifact is written to the WIP file before any file is modified. No test file may be modified or deleted without a completed triage entry. "High confidence" = the failure has exactly one plausible explanation, stateable in one sentence without hedging.

## Revision 2026-04-27

Three design decisions revised after WBS completion:

### verify-self runs as a subagent (not in parent context)

`feature-verify-self` spawns a one-shot `Agent` with Playwright/curl tools. Playwright output (snapshots, console logs, network requests) stays in the subagent's context — parent context stays lean across multi-phase features. Trade-off accepted: the subagent is one-shot and cannot ask the user questions mid-verify. All inputs (dev URL, Observable Outcomes, severity taxonomy) must be baked into the spawn prompt. The dev URL is supplied by the user as an argument when invoking `/feature-verify-self <url>` — no magic derivation.

### Work Tree has no depth cap — recursive as needed

The 4-level maximum is removed. The tree can nest as deeply as the feature requires. The practical guidance ("prefer splitting wide phases into siblings over deep nesting") remains, but it is advisory, not enforced. This aligns with the task workflow peer model: tasks no longer map to a "lighter" variant — they use the same tree format, just without Observable Outcomes and the verify loop.

### Task workflow is a peer entry point, not a sub-workflow

The feature workflow no longer spawns tasks. Task is an independent entry point like incident. Escalation is one-way upward only (task → feature when scope grows). The feature workflow's previous ability to hand work down to tasks is removed — if work belongs at task scope, the user starts a task directly. This simplifies the cross-level mechanism: SURFACE and ESCALATE still exist, but no downward delegation.

### Tree grammar lives in CLAUDE.snippet.md (global)

The Work Tree format spec (schema, status vocabulary, rules) is defined once in `CLAUDE.snippet.md`, injected into `~/.claude/CLAUDE.md` at install time. Individual skill SKILL.md files do not duplicate the spec — they reference it by behavior (e.g., "update Current Node on exit"). This is the single source of truth for all sessions across all projects.
