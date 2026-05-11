# State Machine Architecture

This document is the authoritative reference for the workflow state machine: all transitions, the enforcement model, cross-level mechanisms, and implementation notes. It replaces the former `transitions.yaml` (machine-readable) and `PLAN.md` (design narrative) — both are now consolidated here.

---

## Design Principles

### Enforcement model

State transitions are **advisory**, not hard-blocked. Skill prompts tell the model what the valid next states are; there are no hooks that prevent invalid transitions. This is intentional — the overhead of hard enforcement is higher than the cost of the occasional out-of-order invocation, and the system is designed to be used by a capable agent that can self-correct. Back-loops (`type: back-loop`) require the model to document *what changed and why* before re-entering an earlier state.

### Two invocation paths

- **Direct slash command** (e.g., `/product-vision`) — runs exactly one skill, then tells the user the next slash command. Single-step, no chaining.
- **`/session-start`** — drives the workflow end-to-end in the current conversation by reading the matching orchestrator's Orchestration Procedure and invoking each skill via the Skill tool. Pauses only at human-input points.

Keep both paths working: never bake auto-chain logic into individual skill prompts. Orchestration behavior lives in `agents/<workflow>-workflow/AGENTS.md`.

### Orchestrator pause policy (AUTO vs PAUSE)

The feature-workflow orchestrator (and any future workflow orchestrators) annotates every step with a pause policy. This lives in `agents/feature-workflow/AGENTS.md` → "Pause policy" table, not in individual skill SKILL.md files.

- **AUTO** — orchestrator chains immediately to the next step on a passing transition. No user prompt.
- **PAUSE** — orchestrator stops and waits for the user before proceeding. The harness's `Notification` hook fires automatically when the orchestrator blocks for input.

The `TRANSITION: <id>` token emitted at the end of a skill's output is the machine signal the orchestrator acts on. The prose "Run `/feature-x`" in skill output is for single-step users only and must not cause the orchestrator to pause.

The full pause policy per workflow and per drive mode is in the **Drive modes** section below.

### Drive modes

`/session-start` supports four named drive modes. The model selects the mode by asking the user to choose from a numbered list in the CLI (not via command-line flags). The selected mode is recorded in the session's WIP state and governs all pause/chain decisions for the duration of the workflow.

#### Mode definitions

| # | Name | How selected | Description |
|---|------|-------------|-------------|
| 0 | **Direct** | Direct slash command (e.g. `/feature-plan`) — not via session-start | One skill runs, then stops. The skill's own "Hand Off" prose is authoritative. No chaining. |
| 1 | **Step-by-step** | session-start option 1 | Pause after every skill. The orchestrator summarises what was done and tells the user which slash command to run next — but does not invoke it automatically. |
| 2 | **Orchestrated** | session-start option 2 / default (Enter) | Follows the pause-policy table in `agents/<workflow>-workflow/AGENTS.md` exactly. Skill-level stop signals are ignored; `TRANSITION: <id>` tokens are the sole machine signal. |
| 3 | **Autopilot** | session-start option 3 | All steps AUTO except `verify-human` (still PAUSE) and ESCALATE (always PAUSE). |
| 4 | **Full-autopilot** | session-start option 4 | All steps AUTO. `verify-human` is **skipped** — `verify-self` result is the acceptance gate. ESCALATE remains PAUSE. Runs until terminal state. |

#### Mode precedence

```
Direct (mode 0):         skill SKILL.md "Hand Off" / **STOP** is authoritative
Step-by-step (mode 1):   orchestrator chains to next skill but pauses for user confirmation after each
Orchestrated (mode 2):   AGENTS.md pause-policy table overrides skill-level stop signals
Autopilot (mode 3):      simplified policy below overrides AGENTS.md
Full-autopilot (mode 4): all-AUTO policy overrides AGENTS.md; verify-human is skipped
```

Skill-level `**STOP**` and `"Run /x"` prose are **never** authoritative in modes 2–4. The orchestrator ignores them and acts on `TRANSITION: <id>` tokens only.

#### Pause policy by mode — feature workflow

| Step | Mode 1 (Step-by-step) | Mode 2 (Orchestrated) | Mode 3 (Autopilot) | Mode 4 (Full-autopilot) |
|------|-----------------------|-----------------------|--------------------|------------------------|
| reproduce — F32/F33 (reproduced cleanly) | PAUSE | AUTO | AUTO | AUTO |
| reproduce — F34 (could-not-reproduce → preventive hardening) | PAUSE | **PAUSE** | **PAUSE** | AUTO |
| reproduce — F35 (could-not-reproduce → terminate) | PAUSE | **PAUSE** | **PAUSE** | **PAUSE** |
| spec | PAUSE | PAUSE | PAUSE | AUTO |
| research | PAUSE | PAUSE | AUTO | AUTO |
| plan | PAUSE | PAUSE | AUTO | AUTO |
| build | PAUSE | AUTO | AUTO | AUTO |
| verify-auto | PAUSE | AUTO | AUTO | AUTO |
| verify-self | PAUSE | AUTO | AUTO | AUTO |
| verify-human | PAUSE | PAUSE | **PAUSE** | **SKIP** |
| verify-codify | PAUSE | AUTO | AUTO | AUTO |
| ship | PAUSE | AUTO | AUTO | AUTO |
| finalize | PAUSE | PAUSE | AUTO | AUTO |
| refactor | PAUSE | AUTO | AUTO | AUTO |
| Back-loops | PAUSE | AUTO | AUTO | AUTO |
| REDIRECT (F22) | PAUSE | PAUSE | PAUSE | AUTO |
| SURFACE F25 | PAUSE | AUTO | AUTO | AUTO |
| SURFACE F26 | PAUSE | PAUSE | PAUSE | AUTO |
| ESCALATE (any) | PAUSE | **PAUSE** | **PAUSE** | **PAUSE** |

#### Pause policy by mode — task workflow

| Step | Mode 1 (Step-by-step) | Mode 2 (Orchestrated) | Mode 3 (Autopilot) | Mode 4 (Full-autopilot) |
|------|-----------------------|-----------------------|--------------------|------------------------|
| plan | PAUSE | PAUSE | AUTO | AUTO |
| act | PAUSE | AUTO | AUTO | AUTO |
| close | PAUSE | PAUSE | AUTO | AUTO |
| ESCALATE / REDIRECT | PAUSE | **PAUSE** | **PAUSE** | **PAUSE** |

#### Pause policy by mode — product workflow

| Step | Mode 1 (Step-by-step) | Mode 2 (Orchestrated) | Mode 3 (Autopilot) | Mode 4 (Full-autopilot) |
|------|-----------------------|-----------------------|--------------------|------------------------|
| vision scoping questions | PAUSE | PAUSE | PAUSE | AUTO |
| roadmap review | PAUSE | PAUSE | AUTO | AUTO |
| research / arch / wbs happy path | PAUSE | AUTO | AUTO | AUTO |
| back-loops (P4, P6, P8) | PAUSE | PAUSE | PAUSE | AUTO |
| P10 exit to feature | PAUSE | PAUSE | AUTO | AUTO |
| P14 product-finalize back-loop | PAUSE | PAUSE | PAUSE | AUTO |

#### Pause policy by mode — incident workflow

Incidents are always treated as **Mode 2 (Orchestrated)** regardless of the selected drive mode. Human judgment is non-negotiable in an incident.

| Step | All modes |
|------|-----------|
| triage (I2→I3 / I2→I13) | PAUSE |
| reproduce → investigate (I14) | AUTO |
| reproduce → investigate-with-telemetry-constraint (I15) | PAUSE |
| reproduce → pause-as-record (I16) | PAUSE |
| before mitigate (I6) | PAUSE |
| back-loop (I8) | PAUSE |
| mitigate → codify (I17) | AUTO |
| codify → resolve, Path A (reproduce-artifact passes) | AUTO |
| codify → resolve, Path B (new test written from scratch) | PAUSE |
| codify → resolve, defer path (I9 with SURFACE entry) | PAUSE |
| codify → mitigate (I19 back-loop) | PAUSE |
| codify → investigate (I20 back-loop) | PAUSE |
| before resolve (no codify — fast-close paths I4, I7) | PAUSE |
| surface (I11, I12) | PAUSE |
| investigate self-loop (I5) | AUTO |

#### Session-start prompt

When `/session-start` confirms the work classification, it presents the mode choice before proceeding:

```
I'll drive the <workflow> workflow. Which drive mode do you want?

  1. Orchestrated  — follows the standard pause policy (spec, plan, verify-human, finalize)
  2. Autopilot     — only pauses at verify-human; everything else chains automatically
  3. Full-autopilot — no pauses; verify-human skipped; runs to completion

(Type 1, 2, or 3 — or just press Enter for Orchestrated)
```

The selected mode is stored in `workflow/wip/<item>.md` frontmatter as `drive_mode: orchestrated | autopilot | full-autopilot` and honoured for the full workflow duration including cross-workflow handoffs. The mode persists across `/session-pause` and `/session-resume`.

### Back-loop guard

Any back-loop transition must document *what changed and why* before re-entering the earlier state. This prevents infinite loops and creates an audit trail in the WIP file.

---

## Cross-Level Mechanisms

Three ways workflows interact with each other:

### SURFACE (lower → higher)

A discovery in a lower-level workflow is logged upstream. Two modes:

| Mode | When | Behavior |
|------|------|----------|
| `note-and-continue` | Discovery is NOT a blocker | Log to `workflow/backlog.md`, annotate current WIP plan, continue working |
| `pause-and-escalate` | Discovery IS a blocker | Pause current workflow, create higher-level item, address it, resume |

**Escalate criteria** (default is note-and-continue unless one of these holds):
- The discovery changes an interface being actively coded against
- An architectural decision is required before proceeding
- Current work would be invalidated without the change

**Backlog entry format:**
```markdown
## SURFACE-<timestamp>
- **Source:** <current workflow>:<current step>
- **Target level:** <product|feature>:<suggested step>
- **Type:** new-work | gap | tech-debt | bug
- **Summary:** <what was discovered>
- **Context:** <why it matters>
- **Suggested action:** <what should be done>
- **Priority:** low | medium | high
- **Status:** pending
```

**Backlog review timing:**
- During `plan` (any workflow): lightweight scan for `high` priority items or items whose target matches the current workflow level
- During `finalize`/`close`: full backlog review, surface unresolved items to user

### ESCALATE (one-way absorption)

Current work item is abandoned in favor of a higher-level one:
1. Update all docs to reflect escalation
2. Mark current item as "Escalated to [target]", close/archive it
3. Create higher-level item, enter that workflow
4. No resume of original — it's been absorbed

### REDIRECT (round-trip)

Current workflow pauses, another workflow/step runs, original resumes:
1. Pause current workflow (save state)
2. Enter the other workflow/step
3. On return, evaluate: did findings change the plan?
   - If **no**: auto-flow results into plan, annotate, continue
   - If **yes**: re-plan before resuming

---

## Product Workflow

```
States:  vision → roadmap → research → arch → wbs → context → [features] → product-finalize
Entry:   vision
Terminal: product-finalize (→ EXIT; docs archived, cycle closed)
```

| ID | From | To | Condition |
|----|------|----|-----------|
| P1 | ENTRY | vision | Always |
| P2 | vision | roadmap | Vision doc created |
| P3 | roadmap | research | Roadmap has phases defined |
| P4 | research | roadmap | Back-loop: research invalidates roadmap assumptions |
| P5 | research | arch | Research complete, no roadmap changes needed |
| P6 | arch | research | Back-loop: architecture reveals unknowns |
| P7 | arch | wbs | Architecture defined |
| P8 | wbs | arch | Back-loop: WBS reveals architectural gaps |
| P9 | wbs | context | WBS complete |
| P10 | context | EXIT→feature:plan | Always — start first milestone from roadmap |
| P11 | SURFACE-IN | wbs | Lower-level workflow discovers new work |
| P12 | SURFACE-IN | arch | Lower-level workflow discovers architectural gap |
| P13 | product-finalize | EXIT | Cycle closed — durable docs resynced, cycle-scoped docs archived |
| P14 | product-finalize | arch | Back-loop: resync reveals significant architectural drift requiring formal revision |

Back-loop guard applies to: P4, P6, P8, P14.

**product-finalize** is triggered by `feature-finalize` (via F29) when all WBS items are `[x]`. It resyncs durable docs (arch.md, roadmap.md) against what was actually built, sweeps the backlog, then archives cycle-scoped docs (`wbs.md`, `research.md`, and any cycle-specific diagnostics) to `docs/product/archive/<cycle-name>/`. Durable docs (`vision.md`, `arch.md`, `transitions.md`, `roadmap.md`) remain in place.

**Back-loop behavior:** Edit the earlier stage's file in place — bump `updated:`, set `state: in-progress`, append a `## Revision <date>` section. Files are never deleted on back-loops.

---

## Feature Workflow

```
States:  reproduce, spec, research, plan, build, verify-auto, verify-self,
         verify-human, verify-codify, ship, finalize, refactor
Entry:   spec (complex) or plan (small/simple) — or reproduce (bug-shape, optional)
Terminal: finalize or refactor (both → auto-trigger reflect); reproduce → terminate (F35) when could-not-reproduce
```

**Per-phase loop:** `plan` decomposes a milestone into phases. The loop `build → verify-auto → verify-self → verify-human → verify-codify` executes once per phase. After all phases complete → ship.

**verify-self:** Agent spawns a one-shot subagent with Playwright/curl tools to observe the running system against the phase's Observable Outcomes. Blocking failures return to build; cosmetic failures are noted but don't block. The subagent is one-shot — all inputs must be in the spawn prompt (dev URL, Observable Outcomes, severity taxonomy). Human checklist in verify-human is pre-filtered: items the agent already confirmed are excluded.

**Integration-boundary rule (verify-self / verify-human / verify-codify):** A phase has an integration boundary when it modifies a line of code inside an existing HTTP endpoint, route, UI surface, CLI command, scheduled job, or external-system call. When a boundary applies, all three verify SKILLs require an outcome / check / test that targets the consuming surface by name (not just the new module). When no boundary applies, each SKILL provides an affirmation-gated path that lets the phase proceed normally. Full rules in:
- `skills/feature-verify-self/SKILL.md` ("Integration-boundary rule" section)
- `skills/feature-verify-human/SKILL.md` (Procedure §2)
- `skills/feature-verify-codify/SKILL.md` (Procedure §2 "Integration-boundary check")

**Small/simple criteria** (all must hold to skip spec and go straight to plan):
1. No new data models or API endpoints
2. No architectural decisions required
3. Describable in ≤ 4 sentences
4. Estimated < 4 hours of agent work
5. Estimated ≤ ~200 lines of new/changed code

| ID | From | To | Condition |
|----|------|----|-----------|
| F1 | ENTRY | spec | Feature is complex (fails small/simple criteria) |
| F2 | ENTRY | plan | Feature is small/simple (all criteria met) |
| F3 | spec | research | Unknowns exist |
| F4 | spec | plan | No unknowns, spec is clear |
| F5 | research | plan | Research complete |
| F6 | research | spec | Back-loop: research reveals spec is wrong |
| F7 | plan | build | Plan created with phases (starts phase 1) |
| F8 | build | verify-auto | Phase implementation complete |
| F9 | verify-auto | build | Back-loop: tests fail |
| F10 | verify-auto | verify-self | Tests pass → user runs `/feature-verify-self <dev-url>` |
| F10b | verify-self | verify-human | All blocking outcomes pass (cosmetic issues noted) |
| F9b | verify-self | build | Back-loop: blocking observable outcome failed |
| F11 | verify-human | verify-codify | Phase has no integration boundary (agent affirms in writing) and human confirms skip — see verify-human SKILL.md "Integration-boundary rule" |
| F12 | verify-human | build | Back-loop: human rejects |
| F13 | verify-human | verify-codify | Human approves happy path |
| F14 | verify-codify | verify-human | Back-loop: new tests reveal issues human missed |
| F15 | verify-codify | build | Tests written, more phases remain (advance to next phase) |
| F16 | verify-codify | ship | Tests written, all phases complete |
| F17 | ship | finalize | Shipped / PR ready |
| F18 | finalize | refactor | Tech debt identified |
| F19 | finalize | EXIT→reflect | No tech debt, feature done |
| F20 | refactor | plan | Refactor needs a plan — CONSTRAINT: scoped to cleanup only, no new features |
| F21 | refactor | EXIT→reflect | Refactor complete |
| F22 | build | research | REDIRECT: hit unknown during implementation — pause, research, return |
| F23 | build | plan | Back-loop: plan is wrong/incomplete |
| F24 | verify-auto | spec | Back-loop: tests reveal spec was wrong |
| F25 | build | SURFACE→product:wbs | Discovered module/component not in WBS (note-and-continue) |
| F26 | build | SURFACE→product:arch | Architectural change needed (pause-and-escalate) |
| F27 | ANY | incident:report | Something breaks |
| F28 | SURFACE-IN | spec | Task/incident escalated to feature |
| F30 | finalize | product-finalize | WBS fully complete — all WPs `[x]`; surface product-finalize to user |
| F31 | ENTRY | reproduce | Bug-shape entry: user describes undesirable behavior (bug, regression, broken state) — optional pre-spec/pre-plan reproduction step |
| F32 | reproduce | spec | Reproduced cleanly, feature is complex (fails small/simple criteria) |
| F33 | reproduce | plan | Reproduced cleanly, feature is small/simple (all criteria met) |
| F34 | reproduce | spec | Could-not-reproduce, user elects preventive hardening — spec framing reset to "preventive hardening" |
| F35 | reproduce | EXIT (terminate) | Could-not-reproduce, no preventive fix — close workflow with reproduce attempt as record |

**Reproduce step (F31–F35):** Optional, opt-in. Triggered when the user describes undesirable behavior (bug, regression, broken state). For new-capability features (no bug language) reproduce is skipped — workflow enters at spec or plan as before. Red-green discipline: write a failing test (or deterministic manual recipe, or telemetry signature) capturing the bug *before* spec/plan. The reproduction artifact becomes the anchor verify-codify uses to confirm "fixed means this no longer happens." Drive-mode behavior in the Pause-policy section above: F32/F33 are AUTO in modes 2–4; F34 is AUTO in mode 4 only (PAUSE in 1–3 because preventive hardening is a meaningful divergence); F35 is PAUSE in all modes (terminating a workflow without a reproduce signal deserves human confirmation).

---

## Task Workflow

```
States:  plan → act → close
Entry:   plan (peer workflow — not spawned by feature workflow)
Terminal: close
```

**Peer model:** Task is an independent entry point (like incident), not a sub-workflow of feature. The feature workflow does not spawn tasks. Tasks escalate *upward* to feature when scope grows — never downward. Use task for atomic, well-scoped changes; use feature for anything with multiple phases or a verify loop.

| ID | From | To | Condition |
|----|------|----|-----------|
| T1 | ENTRY | plan | Always |
| T2 | plan | act | Plan is clear, ready to implement |
| T3 | plan | ESCALATE→feature:spec | "This is bigger than a task" — close task, update docs, open feature |
| T4 | plan | REDIRECT→feature:research | Research needed — pause task, research, return |
| T5 | act | close | Implementation complete, no issues |
| T6 | act | plan | Back-loop: need to re-plan |
| T7 | act | SURFACE→feature:spec | Discovered something bigger (note-and-continue or pause-and-escalate depending on blocker status) |
| T8 | act | SURFACE→product:wbs | New work item discovered (note-and-continue) |
| T9 | act | ESCALATE→feature:spec | Task grew beyond task scope — close task, open feature |
| T10 | close | EXIT | Always |
| T11 | close | EXIT→reflect | Significant learning occurred (optional auto-trigger) |

---

## Incident Workflow

```
States:  report → triage → [reproduce] → investigate → mitigate → codify → resolve
Entry:   report
Terminal: resolve (or reproduce → pause-as-record when could-not-reproduce-no-signal)
```

| ID | From | To | Condition |
|----|------|----|-----------|
| I1 | ENTRY | report | Always |
| I2 | report | triage | Report filed |
| I3 | triage | investigate | Severity assessed (P0–P3 via human input), needs investigation |
| I4 | triage | resolve | Fast-close: false alarm or duplicate |
| I5 | investigate | investigate | Self-loop: need more data (agent decides when to stop) |
| I6 | investigate | mitigate | Root cause found |
| I7 | investigate | resolve | Fast-close: false alarm discovered during investigation |
| I8 | mitigate | investigate | Back-loop: fix didn't work, need more data |
| I9 | mitigate | resolve | Skip-codify (defer) path — fix applied, monitoring passed, codify explicitly deferred via SURFACE→task:plan entry with human-written reasoning in WIP file |
| I10 | resolve | EXIT→reflect | Always (auto-trigger) |
| I11 | resolve | SURFACE→task:plan | Root cause needs proper fix (small) |
| I12 | resolve | SURFACE→feature:spec | Root cause needs architectural fix (large) |
| I13 | triage | reproduce | Reproducible incident — human or autopilot elects red-green reproduction before investigate |
| I14 | reproduce | investigate | Reproduced cleanly (failing test or deterministic recipe) — investigate uses artifact as root-cause anchor |
| I15 | reproduce | investigate | Could-not-reproduce-locally but telemetry confirms incident — investigate must rely on prod signals |
| I16 | reproduce | EXIT (pause-as-record) | Could-not-reproduce and no telemetry signal — close workflow with reproduce attempt as record |
| I17 | mitigate | codify | Default path — fix applied, monitoring passed, codify regression coverage before resolve |
| I18 | codify | resolve | Coverage written (Path A reproduce-artifact verified, Path B new test added, or deferred via SURFACE) → resolve |
| I19 | codify | mitigate | Back-loop: codify-time test still fails — mitigation didn't actually fix the bug |
| I20 | codify | investigate | Back-loop: codify-time evidence reveals the root-cause analysis was wrong — re-investigate |

**Reproduce step (I13–I16):** Optional, post-triage. The human decides at triage whether to attempt reproduction (I13) or go straight to investigate (I3) — reproducible bugs benefit from the red-green anchor; prod-data-only or telemetry-only incidents skip reproduce. Reproduce produces a failing test, a deterministic manual recipe, or a captured telemetry signature. The reproduction artifact becomes the anchor investigate uses to confirm root cause, mitigate uses to confirm the fix, and **codify uses to lock the regression test into permanent coverage**. Drive-mode behavior: incident workflow is always Mode 2 (Orchestrated) regardless of session drive mode — human judgment is non-negotiable. I14 (reproduced) is AUTO; I15 (telemetry-only constraint) and I16 (close-as-record) are PAUSE because they require human acknowledgement of degraded investigation conditions or workflow termination.

**Codify step (I17–I20):** Required step between mitigate and resolve. Adapts the feature workflow's `verify-codify` discipline (highest-level test rule, integration-boundary check, six-case triage table) to incident context with two key adaptations: (1) **semantic flip** — a codify-time test failure means the mitigation didn't fix the bug → back-loop to mitigate (I19), not auto-fix; (2) **speed-aware paths** — Path A reuses an existing reproduce-artifact, Path B writes from scratch, and a defer path (I9) is available when active incident response pressure makes writing coverage now infeasible. Defer requires explicit human reasoning in the WIP file plus a SURFACE→task:plan entry so the coverage debt is owned. I20 is a separate back-loop from I19 for the case where the codify-time evidence reveals investigate's root-cause analysis was wrong (not just the mitigation). Pause-policy behavior in §"Pause policy by mode — incident workflow" below.

---

## Session Operations (Cross-Cutting)

Not a state machine — meta-operations that attach to any workflow state.

| Operation | Trigger | Behavior |
|-----------|---------|----------|
| `start` | Manual | Routes user to correct workflow entry point |
| `pause` | Manual | Save current workflow + state + step to `workflow/wip/` file |
| `resume` | Manual | Read state file, summarize where left off, suggest resume command |
| `reflect` | Auto: after feature:finalize, feature:refactor, incident:resolve. Optional: after task:close. | Analyze session for wrong assumptions. Strongly prompt user to run store-learning. |
| `store-learning` | Manual (prompted by reflect) | Classify learning (global vs project), propose storage location, execute after human confirmation. **Project-scope** writes to the project's own `.claude/` (CLAUDE.md / memory / skills) as before. **Global-scope** drafts to `.claude/learnings/<YYYY-MM-DD>-<slug>.md` (project-local, gitignored) for manual curation into a source repo — never writes to `~/.claude/`. |

### Session transitions (dispatcher outputs)

Session entry skills (`session-start`, `session-resume`, `session-pause`) are dispatchers and meta-operations, not state-machine states. The IDs below label each skill's possible outputs so they can be asserted by the test harness — they are NOT classical state transitions.

| ID | Skill | Output | Condition |
|----|-------|--------|-----------|
| S1 | session-start | task:plan | Classified as task (atomic change, bug fix) |
| S2 | session-start | feature:spec | Classified as complex feature (fails small/simple criteria) |
| S3 | session-start | feature:plan | Classified as small/simple feature (all criteria met) |
| S4 | session-start | incident:report | Classified as production incident |
| S5 | session-start | product:vision | Classified as new product initiative |
| S6 | session-resume | (resume_skill) | Context restored; `.session.md` deleted after handoff |
| S7 | session-start | (auto-chain) | Orchestrator auto-chains build → verify-auto without asking user |
| S8 | session-start | (pause) | Orchestrator pauses at verify-human (PAUSE step in policy) |
| S9 | session-start | (pause) | Orchestrator pauses at feature-finalize (PAUSE step in policy) |
| S10 | session-start | (drive-mode menu) | User wants end-to-end drive — present mode menu (do not skip to build) |
| S11 | session-start | (auto-chain) | Mode 4 (Full-autopilot): chain past plan into build without pausing |
| S12 | session-start | (pause) | Mode 3 (Autopilot): pause only at verify-human |
| S13 | session-start | (pause-after-each) | Mode 1 (Step-by-step): pause after every skill, tell user next slash command |
| S14 | session-start | (skip+chain) | Mode 4 (Full-autopilot): skip verify-human, chain to verify-codify |
| S15 | session-resume | (mode menu) | Surface `drive_mode` from `.session.md` and present change-mode menu |
| S16 | session-resume | (mode change) | User selects different drive mode on resume — update WIP frontmatter |
| S17 | session-pause | (.session.md) | Write `drive_mode` from WIP frontmatter into `.session.md` |
| S18 | session-start | feature:reproduce | Classified as bug-shape feature (user describes undesirable behavior) — route to optional pre-spec/pre-plan red-green reproduction |
| S20 | session-store-learning | (terminal) | Learning persisted: project-scope to `.claude/<dest>`, or global-scope drafted to `.claude/learnings/<date>-<slug>.md` for manual curation; never writes to `~/.claude/` |

---

## Experiment: Subagent-Per-Step Orchestration (Parked)

The current orchestration approach runs in the **parent context** via `/session-start`. This works but grows the main context over long workflows.

If context bloat becomes a real problem, revisit this design: each workflow step runs inside its own short-lived subagent spawn. Parent owns only the orchestration loop.

### Why it's hard

`Agent` is a one-shot tool. A subagent that pauses for human input can't be resumed — it just returns. The parent then has to spawn a *new* subagent with the user's answer, rebuilding context each time. Live testing showed: subagent asked scoping questions, returned, parent got answer, had to respawn from scratch with the same skill — which re-ran `product-vision` and lost mid-step state.

### Minimum viable design

**One subagent = one skill invocation.** No chaining inside a subagent. The parent `/session-start` runs a dispatcher loop that spawns one step, parses a structured return, collects any needed human input, then spawns the next step.

**Structured return protocol.** Subagents emit a fenced `orchestration` JSON block as the last content of their response:

```json
{
  "transition_id": "P2",
  "next_skill": "product-roadmap",
  "state_file_path": "docs/product/vision.md",
  "needs_human_input": false,
  "question_to_user": null,
  "summary": "Drafted vision doc covering audience, physics scope, mission types, WWII setting.",
  "done": false
}
```

Fields: `transition_id`, `next_skill` (null iff done/paused), `state_file_path`, `needs_human_input`, `question_to_user` (required iff needs_human_input), `summary` (1–2 sentences), `done`.

**Parent loop (pseudocode):**
```
state = { workflow, next_skill, context_summary, pending_answers, state_file_path, history }
persist to workflow/.session.md

loop:
  spawn Agent(subagent_type=<workflow>-workflow,
              prompt=spawn_prompt(state))
  parse orchestration block from output
  if malformed: retry once with stricter prompt, then pause for human input
  if needs_human_input: pause and collect answer (Notification hook fires automatically), append to pending_answers
  append summary to history
  if done: break, clean up .session.md
  state.next_skill = next_skill; persist
```

**Spawn prompt skeleton:**
```
You are running ONE step of the <workflow> workflow in single-step orchestration mode.
STEP TO RUN: <skill-name>
WORKFLOW: <product|feature|task|incident>
STATE FILE: <path>
PRIOR CONTEXT SUMMARY: <short paragraph>
RECENT HUMAN ANSWERS: <verbatim replies, or "none">

Procedure:
1. Read the state file(s) you need.
2. Run the <skill-name> skill via the Skill tool.
3. Emit the orchestration JSON block described in docs/product/transitions.md (tagged `orchestration`).
4. STOP. Do not invoke the next skill.
```

**Cross-level transitions under this model:**
- **SURFACE note-and-continue:** next_skill stays in same workflow; no pause
- **SURFACE pause-and-escalate:** next_skill=null, done=false, needs_human_input=true
- **ESCALATE:** next_skill=null, done=true, summary describes handoff
- **REDIRECT:** next_skill is a skill in a different workflow; parent tracks "return workflow"
- **Back-loops:** next_skill points at the earlier skill; parent spawns it with the back-loop reason in RECENT HUMAN ANSWERS

**Failure modes:**

| Symptom | Handling |
|---------|----------|
| Missing orchestration block | Retry once with strict prompt prefix. Then pause. |
| Multiple blocks emitted | Parse last one. |
| Invalid transition_id | Pause, surface to user. |
| `next_skill` mismatches transition | Prefer next_skill; log hint into next spawn. |
| done=true with pending SURFACE | Process surface first, then terminate. |

**Trade-offs vs current approach:**

| | Option 1 (current — in-context) | Option 2 (experiment — subagent-per-step) |
|--|--|--|
| Parent context growth | Linear with workflow length | Small — only summaries |
| Spawn count | 0 | 1 per step (6 for product, 3+ per phase for feature) |
| Wall time | Faster | Slower (spawn overhead per step) |
| Implementation complexity | Low | High — JSON protocol, retry logic, resume hydration |
| Resume semantics | Per-skill boundary | Orchestration-loop boundary (finer-grained) |

**When to revisit:**
- If a full product + feature workflow regularly hits `/compact` boundaries mid-run
- If long feature workflows (4+ phases) visibly slow down the main agent
- If we want finer-grained resume (mid-orchestration, not just mid-skill)

---

## Change Log

- **2026-05-11 — `session-store-learning` global path redirected away from `~/.claude/`.** Project-scope behavior is unchanged (still writes to the project's own `.claude/CLAUDE.md` / `.claude/memory/` / `.claude/skills/`). Global-scope learnings — previously written into `~/.claude/CLAUDE.md` / `~/.claude/projects/*/memory/` / `~/.claude/skills/` — are now drafted to `.claude/learnings/<YYYY-MM-DD>-<slug>.md` (project-local, gitignored) for manual curation into a source repo (e.g., `my-claude-code-customization`). Rationale: a project session should not silently mutate global Claude Code configuration; the curation step belongs to the human, by hand, in the source repo. New transition ID **S20** registers the skill's terminal output for the test harness. Affects: `skills/session-store-learning/SKILL.md`, `tests/scenarios/session.yaml` (S19 updated, S20 introduced).

- **2026-05-06 — `notify-human` skill removed; replaced by harness hook.** Telegram alerts are now sent by `hooks/notify-telegram.sh` (symlinked to `~/.claude/hooks/`) configured in `~/.claude/settings.json` under `hooks.Notification` (Claude is blocked) and `hooks.Stop` (turn ended). Rationale: the prior skill relied on the model remembering a global rule before each human-input moment, which drifted in long sessions. The hook is deterministic, runs outside the model loop, and adds Stop-event coverage (notifies on turn end as well as input-blocked). All references to invoking `/notify-human` were stripped from agent procedures, skill steps, and CLAUDE.md guidance in the same change.

## Future Transitions

Deferred items not yet in the state machine:

- **Vision revision loop** — back-loop from roadmap to vision if scope changes fundamentally
- **Reflect after product:context** — auto-trigger reflect after P10
- **Auto-trigger hook for reflect** — `settings.json` hook that detects completion of feature:finalize, feature:refactor, or incident:resolve and auto-prompts `/session-reflect`. Currently skills only suggest it.
- **Lightweight workflow state hook** — PreToolUse hook that reads `workflow/wip/` state and warns (or blocks via exit code 2) when a skill invocation doesn't match the current state. Best tuned after real usage.
- **Hierarchy of facts** — explicit priority ordering for information sources when they conflict: (1) human input, (2) raw error logs/runtime output, (3) online official references, (4) current codebase state, (5) model's trained knowledge. **Case study:** `docs/case-studies/2026-05-06-user-domain-memory-vs-api-error-string.md` — agent built a self-consistent diagnosis from JWT + folder-walk evidence, but the diagnosis was framed by the API error string; user's memory of how the system had actually behaved redirected the investigation in 5 minutes. Load-bearing nuance: error strings are themselves a *source* in this hierarchy and can be misleading even when literally true; user historical memory should outrank live evidence framed by an unreliable source.
