---
name: feature-plan
description: "Feature workflow: create a phased implementation plan for the feature"
argument-hint: <feature name or notes>
---

# Feature Plan

You are an expert Software Architect creating an implementation plan.

## State Machine Context

You are in the **feature** workflow at the **plan** state.

This is the entry point for **small/simple** features (F2) or follows spec/research for complex ones.

**Valid transitions from here:**
- **F7 → build (phase 1):** Plan created with phases → tell user to run `/feature-build`

Also entered via:
- **F20 (refactor → plan):** CONSTRAINT — plan must be scoped to cleanup only, no new features
- **F23 (build → plan back-loop):** Plan was wrong/incomplete — revise it
- **F33 (reproduce → plan):** Bug-fix small/simple feature — repro artifact already exists; plan must reference the failing test as the verify-codify anchor

**Bug-fix discoverability:** If `{{args}}` describes an undesirable behavior (bug, regression, broken state, wrong output) and you have not been entered via F33 from `feature-reproduce`, surface a one-line suggestion to the user: "If this describes a bug-fix or regression and you haven't run reproduction, consider running `/feature-reproduce` first to capture a failing test before planning the fix." Then proceed with planning — this is a soft pointer, not a gate.

## Orchestrator Pause Policy (cheat-sheet)

When invoked by `/session-start` in orchestrated mode, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause. Per-skill rows for plan's exits:

| Transition | Mode 1 — Stepping | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — FSD |
|---|---|---|---|---|
| Skill invocation (entry — plan review point) | PAUSE | **PAUSE** | AUTO | AUTO |
| F7 (plan → build, Phase 1) | PAUSE | (pause already taken at entry) | AUTO | AUTO |

Also entered via:
- **F20 (refactor → plan):** plan-as-cleanup. Same pause policy as above.
- **F23 (build → plan, back-loop):** AUTO in Modes 2–4 (back-loops are AUTO).
- **F33 (reproduce → plan):** Same pause policy as F2 entry (entry-point review point).

**Hard rule for AUTO exits.** In Modes 3 and 4, plan is AUTO — when this skill emits `TRANSITION: F7` in Mode 3 or 4, the orchestrator **must immediately invoke `feature-build` via the `Skill` tool**. It must **NOT** return control to the user. Emitting a clean `TRANSITION: F7` followed by a polite narrative summary ("Plan complete; ready to run /feature-build for Phase 1") in Mode 3/4 is the regression mode this block exists to prevent (P1 incident, 2026-05-16, scope-extended 2026-05-17): the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. **This explicitly includes the `AskUserQuestion` tool (and any other user-input/confirmation prompt): invoking it on an AUTO transition IS "returning control to the user" and is the same regression class as the narrative-summary stop above — do NOT call it to "just confirm" the handoff. The only thing that pauses an AUTO transition is the human-input points the active drive mode's pause policy explicitly marks PAUSE.**

In Modes 1–2 the user reviews the plan before build — that pause is taken at skill *entry*. After the user's response, F7 then chains forward without a second pause. See `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## Step 0: Available product context

Before planning, align phasing with the active WBS cycle. Run `ls workflow-system/product/` to see which docs exist. The docs you may find:

- `workflow-system/product/arch.md` — architectural decisions and system design
- `workflow-system/product/wbs.md` — active work breakdown structure (current cycle)
- `workflow-system/product/vision.md` — high-level product vision
- `workflow-system/product/roadmap.md` — strategic roadmap
- `workflow-system/product/research.md` — cycle-scoped research findings

**Eager read — `wbs.md` with conversation-context skip:** WBS context grounds plan phasing in the active cycle. **However**, if `wbs.md` content is already in your conversation context — typically because `feature-spec` ran earlier in this same conversation and loaded it — skip the read and note "wbs.md already in context (loaded by feature-spec)" in your reasoning. The agent (you) introspects its own conversation context to decide; do **not** inspect the WIP file's state for this decision. If the conversation is fresh (e.g., resumed via `/session-resume` after a pause, or this skill was entered directly via F2 with no prior spec), `wbs.md` is not in context — read it.

**Size guard:** if `wbs.md` exceeds ~300 lines, read only the first 100 lines (via the `Read` tool's `limit:` parameter) plus a `Grep` for `^#+ ` headings. Append one line to the WIP file's `## Discoveries` section: `[SURFACED-<date>] feature-plan — wbs.md exceeds size guard (N lines), truncated to first 100. Consider summarizing.`

**`arch.md`, `vision.md`, `roadmap.md`, `research.md`, `design-priors.md`:** pointer-only. `arch.md` and `design-priors.md` are spec's concern — by plan time, `feature-spec` has already consulted `design-priors.md` and applied any firing priors (disclosed as `[PRIOR: …]` in the spec), so plan inherits those decisions rather than re-deciding. The others are too coarse to constrain phase-level planning.

**Absent files:** silent no-op. No warning, no prompt.

See `CLAUDE.snippet.md` → "Entry-skill product-context loading (GLOBAL)" for the canonical mapping these rules follow.

## Procedure

### 1. Backlog Check
Scan `workflow-system/state/backlog.md` (if it exists) for:
- `high` priority items matching this feature area
- Conflicts with what's about to be planned
Mention any relevant items to the user.

### 2. Context Review
- Read the spec in `workflow-system/state/wip/` (if complex feature)
- Review research findings (if any)
- Examine existing codebase structure and patterns
- Read the project `CLAUDE.md` at the root for project rules (also `<proj-dir>/.claude/CLAUDE.md` if present)

### 3. 3rd-Party Probe Check

Before writing the plan, check whether this feature depends on any 3rd-party service, external API, or SDK (e.g. Stripe, Twilio, SendGrid, AWS, Google Maps, an OAuth provider, any API you don't own).

**If a 3rd-party dependency is present:**
1. Check `workflow-system/product/wbs.md` (if it exists) for a completed Probe WP covering that integration.
2. If no probe WP exists or none is marked complete — this is a **known unknown**. Flag it explicitly:

> ⚠️ **Known unknown — probe required before planning**
> This feature depends on [service/API name], but no completed probe WP exists for it. The API's request/response shapes, auth model, rate limits, and error codes are unverified assumptions. Planning now risks major revision once the probe is complete.
> **Recommended action:** Run a spike task first to document the integration's I/O shapes. Then return to `/feature-plan` with that knowledge.
> If you want to proceed anyway, mark the 3rd-party-dependent phases as explicitly provisional in the plan.

3. If a completed probe WP exists — note it in the plan's Problem Statement and proceed.

**If no 3rd-party dependency is present:** skip this step and continue.

### 4. Create Phased Plan

**If entering for a new feature** (F2 or F4→F7), create or update `workflow-system/state/wip/<feature-name>.md` using the **Work Tree format** (see `## Work Tree Format (GLOBAL)` in your system context):

```markdown
# Feature: <Name>

**Workflow:** feature
**State:** plan (complete)
**Created:** <YYYY-MM-DD>

## Problem Statement
<One paragraph. Will be re-examined on every back-loop entry — not static.>

## Work Tree

- [ ] Phase 1: <title>  <!-- status: NOT-STARTED -->
  **Observable outcomes:**
  - Browser: <declarative outcome — what a user/curl/Playwright would observe>
  - HTTP: <e.g. GET /endpoint → 200, body contains {field: type}>
  - CLI: <e.g. command exits 0, stdout matches pattern>
  - Console: <e.g. no JS errors on page load>
  - [ ] P1.1 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] P1.2 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: <title>  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - <...>
  - [ ] P2.1 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > P1.1
- **Active scope:** P1.1 (first task)
- **Blocked:** none
- **Unvisited:** <phases beyond Phase 1, in the order they will execute (sequence-of-execution — NOT alphabetical or order-of-thought)>
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
```

**Rules for this template:**
- **Observable outcomes** are written NOW at plan time — not at verify time. They describe what must be true about the *running system* from the outside (HTTP responses, browser state, CLI output). They are the agent's verification target in `feature-verify-self`.
  - **Each outcome must be mechanically verifiable** — it must be checkable by Playwright, curl, or a CLI command. Prose outcomes ("the feature works correctly", "the UI looks good") are NOT acceptable. If you cannot describe a concrete check, the outcome is not done.
  - **Every phase must include at least one HTTP, Browser, or CLI outcome.** If a phase has no user-facing surface (pure internal refactor), state that explicitly and use a CLI smoke-test (e.g., `python -c "from mymodule import MyClass; MyClass()"` exits 0).
  - **Bad:** `Browser: The login page looks correct` → **Good:** `Browser: Playwright navigates to /login, snapshot contains input[type=email] and input[type=password], no JS console errors`
  - **Bad:** `HTTP: API works` → **Good:** `HTTP: POST /api/login with valid credentials → 200, body contains {"token": string}`
- **All 5 verification group nodes** (`verify-auto`, `verify-self`, `verify-human`, `verify-codify`) must be pre-populated as `NOT-STARTED` under every phase. Do not omit any.
- **`## Current Node`** must be initialized pointing to Phase 1's first impl task. This is the position pointer every subsequent skill reads first.
- **No depth cap** — nest as needed, but prefer splitting wide phases into sibling phases over excessive nesting.

Each phase should be a coherent unit that can go through the `build → verify-auto → verify-self → verify-human → verify-codify` loop independently.

### 4b. Phase-Advance Relevance Gate (multi-phase features only)

**Applies when:** advancing to Phase 2 or later — i.e., Phase 1 is complete and build is transitioning to the next phase.

Before writing or starting any new phase, check four relevance signals and record the result in the WIP file under the phase node being started:

```markdown
**Relevance check (before Phase N):**
- Requester still needs this: yes / no — <brief note>
- Requirements unchanged: yes / no — <brief note>
- Solution still feasible: yes / no — <brief note>
- No superior alternative discovered: yes / no — <brief note>
**Verdict:** proceed / pause-and-reassess
```

If all four signals are "yes" → proceed with the phase as planned.

If any signal is "no" → stop. Document which signal failed and why in the WIP file. Present the issue to the user before starting the phase — do not silently continue with work that may no longer be warranted.

This check is lightweight: one paragraph, not a full re-plan. Its purpose is to catch the case where the feature's context has changed during earlier phases and proceeding blindly would produce waste.

**If entering from refactor (F20):**
- CONSTRAINT: Scope to cleanup only — no new features, no scope expansion
- Plan should address specific tech debt items identified in finalize

**If entering from build back-loop (F23):**
- Revise the existing plan, document what was wrong and why

### 5. Update WIP State
Set state to `plan (complete)` in the WIP file.

### 6. Hand Off
Tell the user to run `/feature-build` to start Phase 1.

**Single-step mode only:** STOP here — do NOT start implementing. In orchestrated/autopilot/fsd modes the orchestrator decides whether to pause or chain per the **Orchestrator Pause Policy (cheat-sheet)** block at the top of this SKILL. The hard rule for AUTO exits applies — see that block.

**User Request:** {{args}}
