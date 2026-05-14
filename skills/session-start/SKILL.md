---
name: session-start
description: Start a new workflow session — classify the work, select a drive mode, then drive the matching workflow end-to-end in this context
argument-hint: <optional context about what the user wants to work on>
---

# Session Start

You are a workflow dispatcher AND orchestrator. Your job is to **classify** the work, let the user **select a drive mode**, and then **drive the workflow end-to-end** by invoking each skill via the `Skill` tool — all in this conversation. You do **not** spawn a subagent.

## Available workflows

| Workflow | Entry skill | Orchestrator procedure | When to use |
|----------|-------------|------------------------|-------------|
| **Product** | `product-vision` | `agents/product-workflow/AGENTS.md` | New product initiative, strategic planning |
| **Feature** | `feature-spec` (complex) or `feature-plan` (small/simple) | `agents/feature-workflow/AGENTS.md` | Multi-step implementation |
| **Task** | `task-plan` | `agents/task-workflow/AGENTS.md` | Atomic work: bug fix, small change |
| **Incident** | `incident-report` | `agents/incident-workflow/AGENTS.md` | Production issue |
| **Resume** | — (run `/session-resume` directly) | — | Continue a previously paused session |

**Small/simple feature criteria** (skip spec, go straight to plan):
All must hold: (1) no new data models or API endpoints, (2) no architectural decisions required, (3) describable in ≤ 4 sentences, (4) estimated < 4 hours of agent work, (5) estimated ≤ ~200 lines of new/changed code.

## Valid transitions

When you finish dispatching, label your output with one of these IDs (the test harness asserts on them; in production they're a clarity aid):

**Routing — classification outputs:**
- **S1 → task:plan** — atomic change, bug fix
- **S2 → feature:spec** — complex feature (fails small/simple criteria, no bug-shape language)
- **S3 → feature:plan** — small/simple feature (all criteria met, no bug-shape language)
- **S4 → incident:report** — production incident
- **S5 → product:vision** — new product initiative
- **S18 → feature:reproduce** — bug-shape feature (user describes undesirable behavior — bug, regression, broken state, wrong output) → optional pre-spec/pre-plan red-green reproduction

**Drive-mode and orchestration outputs (after the user has selected a mode):**
- **S7** — auto-chain build → verify-auto without asking the user (orchestration step in modes 2-4)
- **S8** — pause at verify-human (orchestration PAUSE step)
- **S9** — pause at feature-finalize (orchestration PAUSE step)
- **S10** — user asked for end-to-end driving but no mode picked yet — present the drive-mode menu (do NOT skip directly to build)
- **S11** — Mode 4 (Full-autopilot): chain past plan into build without pausing
- **S12** — Mode 3 (Autopilot): pause only at verify-human
- **S13** — Mode 1 (Step-by-step): pause after every skill, tell the user the next slash command (do NOT auto-chain)
- **S14** — Mode 4 (Full-autopilot): skip verify-human, chain to verify-codify

## Drive modes

Four modes control how aggressively the orchestrator chains between steps. The full pause-policy tables for all workflows are in `docs/product/transitions.md` → "Drive modes".

| Mode | Name | Pause behaviour |
|------|------|----------------|
| 1 | **Step-by-step** | Pause after every skill — you confirm each transition manually |
| 2 | **Orchestrated** | Standard policy from AGENTS.md (spec, plan, verify-human, finalize pause; everything else auto) |
| 3 | **Autopilot** | Only `verify-human` pauses; all other steps auto-chain |
| 4 | **Full-autopilot** | No pauses at all; `verify-human` is **skipped** (verify-self result is the acceptance gate); runs to completion |

**Precedence rule (critical — read before driving):**
- In modes 2–4, skill-level `**STOP**` directives and `"Run /x"` prose are **never** authoritative. The orchestrator ignores them.
- The only machine signal the orchestrator acts on is the `TRANSITION: <id>` token at the end of a skill's output.
- After every `Skill` tool call returns, **immediately re-check the active mode's pause policy** before deciding whether to chain or wait. Do not carry forward assumptions from before the skill ran.
- Mode 1 is the exception: after each skill, stop and hand control back to the user.

## Procedure

### 1. Check for active work
Briefly check for any active work and mention it if found:
- `workflow/.session.md` — an explicitly paused session → strongly recommend `/session-resume` over starting fresh
- `workflow/wip/` — any active feature/task/incident files
- `docs/product/` — any product doc with frontmatter `state: in-progress`

If active work exists, ask whether the user wants to resume or start something new.

**If all three sources are empty AND `{{args}}` is empty**, also check `workflow/backlog.md` and surface open items as candidate work *before* asking the question in step 2. This turns the curated backlog into a useful starting menu.

**Backlog surfacing rules:**
- **Trigger:** Only when no active work was found above *and* the user did not provide `{{args}}` describing what they want to tackle. If args are present, the user has already declared intent — skip the backlog surfacing entirely.
- **Silent no-op:** If `workflow/backlog.md` is absent or contains zero open `## SURFACE-…` blocks, skip — do not say "no backlog items," just proceed to the question.
- **Parsing:** Read each `## SURFACE-…` block from `workflow/backlog.md`. Include entries whose `**Status:**` line is `open` *or* missing (defensive — old entries may lack a status). Skip entries with `**Status:** resolved` (these are leftovers from migration; should not appear in the open list).
- **Ranking:** By `**Priority:**` tier in this order: `high` → `medium-high` → `medium` → `low`. Within a tier, newer SURFACE date first (the date in the SURFACE-ID prefix, e.g., `SURFACE-2026-05-11-…` is newer than `SURFACE-2026-05-08-…`).
- **Cap at 3.** Show the top-3. If more remain, append a single line: "…and N more — say 'more backlog' to see the full list."
- **Display shape (numbering anchor — important):** Each item shows on its own block with both the local index `1./2./3.` and the full SURFACE-ID, plus the first sentence of the `**Summary:**` line and the priority. Both the local index and the SURFACE-ID are valid references for the user's reply. The numbering anchors to the displayed top-3 only — never to a hidden full-backlog enumeration. Example:

  > By the way, the backlog has these open items —
  >
  > **1. SURFACE-2026-05-12-STORE-LEARNING-WRONG-ITEM-SELECTED** *(medium-high)*
  > `/session-store-learning` re-indexes within the "Recommendations" sub-list, silently picks the wrong learning.
  >
  > **2. SURFACE-2026-05-11-ENTRYPOINT-SKILLS-LOAD-PRODUCT-CONTEXT** *(medium)*
  > Entry-point skills should optionally load relevant `docs/product/*.md` files when present.
  >
  > **3. SURFACE-2026-05-06-FINALIZE-BEFORE-SHIP-ORDER-FLIP** *(medium)*
  > Agent prose inverted ship→finalize order in a real run; finalize wrote "shipped" before push.
  >
  > …and 7 more — say "more backlog" to see the full list. Or describe new work below.

- **Then proceed to step 2's question.** The user can reply with: a candidate reference (1/2/3 or full SURFACE-ID), "more backlog", or free-form text describing new work.

### 2. Classify the work
If the user provided context via `{{args}}`, classify immediately. Otherwise, ask one brief question: "What are you tackling?" — then classify.

**If the user's reply references a backlog candidate from step 1's surfacing** (either a local index `1`/`2`/`3` or a full `SURFACE-…` identifier), resolve the reference back to the matching backlog entry and use that entry's `**Summary:**` plus `**Target level:**` and `**Type:**` lines as the classification input (as if they had been passed in via `{{args}}`). Then **confirm the match by SURFACE-ID** ("Picked up SURFACE-…") before classifying, so the user can catch a wrong-item selection (see SURFACE-2026-05-12-STORE-LEARNING-WRONG-ITEM-SELECTED for the failure mode this defends against). If the user replies "more backlog", expand the list (no cap, same display shape) and re-ask. If the user types free-form text, ignore the surfaced list and classify the free-form text.

Classification outputs:
- **Workflow:** product | feature | task | incident | resume
- **Entry skill:** the specific skill name from the table above
- **For features:** evaluate two axes:
  1. **Bug-shape detection.** Does the user's description explicitly mention an undesirable behavior — a bug, regression, broken state, wrong output, "fix" referring to existing behavior, or "X is happening when it shouldn't"? If yes → route to **`feature-reproduce`** (S18) for optional red-green reproduction *before* spec/plan. The reproduce skill itself decides whether reproduction succeeded and hands off to spec/plan accordingly. If the description is about adding/changing/extending capability (no broken behavior described) → skip reproduce.
  2. **Small/simple criteria** (only if bug-shape was NO above): evaluate to pick `feature-spec` (S2) vs `feature-plan` (S3).

  **Decision rule (bug-shape):** if ambiguous, default to skipping reproduce. Do not ask a clarifying question — let the user explicitly invoke `/feature-reproduce` if they realize they need it. (Repo owner has self-disciplined to describe bugs explicitly when intended; ambiguous descriptions are treated as new-capability features.)

### 3. Confirm and select drive mode
State your classification (1–2 sentences), then present the mode menu (the harness's Notification hook will fire automatically when you pause for the user's reply):

> I'll drive the `<workflow>` workflow. Which drive mode do you want?
>
>   1. Step-by-step   — pause after every skill; you confirm each transition
>   2. Orchestrated   — standard pauses (spec, plan, verify-human, finalize)
>   3. Autopilot      — only pauses at verify-human; everything else chains automatically
>   4. Full-autopilot — no pauses; verify-human skipped; runs to completion
>
> (Type 1–4 — or just press Enter for Autopilot)

**Interpreting the reply:**
- "1" / "step" / "step-by-step" / "manual" → **Mode 1** (pause after every skill; hand control back after each step)
- "2" / "orchestrated" → **Mode 2**
- "3" / Enter / blank / "yes" / "autopilot" → **Mode 3**
- "4" / "full" / "full-autopilot" / "no stops" / "end-to-end" / "drive it end-to-end" → **Mode 4**
- "no" → tell the user which entry skill to run manually (e.g. `/feature-plan`). Stop. You're done.

**Mode 1 behaviour:** after each skill completes, summarise what was done and tell the user which slash command to run next. Do not invoke the next skill automatically.

**Record the selected mode** in the WIP file's frontmatter as `drive_mode: step-by-step | orchestrated | autopilot | full-autopilot` when the first skill creates or updates the file. Honour this value across any `/session-pause` + `/session-resume` cycle and across cross-workflow handoffs.

**Incident override:** regardless of the selected drive mode, the incident workflow always runs as Mode 2 (Orchestrated). Human judgment is non-negotiable during incidents.

### 4. Drive the workflow (in THIS context)

You are now the orchestrator for the classified workflow. You do **NOT** spawn an Agent subagent. You run the entire workflow in the current conversation.

**Load the orchestration procedure.** Read `agents/<workflow>-workflow/AGENTS.md` (the matching orchestrator file for the classified workflow). Its `## Orchestration Procedure` section tells you the happy-path sequence of skills, back-loops, and cross-level transitions.

**Run the loop.** For each step:
1. Invoke the current skill via the `Skill` tool.
2. When the skill returns, **re-read the active drive mode** and check the pause-policy table in `docs/product/transitions.md` → "Drive modes" for that step.
3. If the policy says PAUSE for the active mode: stop and wait for the user (the harness's Notification hook fires automatically).
4. If the policy says AUTO (or SKIP for verify-human in Mode 3): invoke the next skill immediately — do **not** ask the user to retype a slash command, and do **not** treat `"Run /x"` or `**STOP**` in the skill's output as a stop signal.
5. Repeat until the workflow reaches a terminal state or the user explicitly pauses.

**Anti-example — the exact failure pattern this rule prevents:**

A buggy run looks like this. Skill returns with:

```
Phase 1 impl complete:
- Migration applied, schema updated
- Manual smoke check passes

**Next:** Run `/feature-verify-auto` to verify Phase 1.

TRANSITION: F8
```

The orchestrator must read `TRANSITION: F8`, look up F8 in the pause-policy table (build is AUTO in Mode 2/3/4), and **immediately invoke `feature-verify-auto` via the Skill tool**. It must NOT do any of these:
- "Phase 1 done. Ready to run verify-auto when you are." (waiting on user — wrong)
- "Phase 1 done. Type `/feature-verify-auto` to continue." (deferring to user — wrong)
- "Phase 1 done. You'll need to supply the dev URL when prompted." (mixing chain narration with user-deferral — wrong)

The "Run /feature-verify-auto" prose in the skill output is advisory for single-step users who invoked the skill directly via slash command. When *you* invoked it via the Skill tool, that prose is not addressed to you — it's noise. The machine signal is `TRANSITION: F8`, full stop.

**Persist progress.** After each completed step, update the active state file on disk (the skill itself writes this — you just trust it) and optionally touch `workflow/.session.md` if the user steps away.

### 5. Cross-workflow handoff (EXIT→<other-workflow> transitions)

Some terminal transitions exit into *another* workflow (e.g., `P10: context → EXIT→feature:plan`). When you hit one:

1. **Do not stop.** The user already selected a drive mode — apply it to the next workflow too.
2. **Read the next orchestrator's AGENTS.md.** For `EXIT→feature:plan`, that's `agents/feature-workflow/AGENTS.md`. Load its Orchestration Procedure.
3. **Pick the entry skill.** For feature handoffs, evaluate the small/simple criteria against the work item being entered (e.g., the first WP from the WBS). Use `feature-plan` for small/simple, `feature-spec` for complex.
4. **Drive the next workflow in the same dialogue** using the same active drive mode.
5. **Scope of one handoff = one unit of the next workflow.** After one feature workflow completes (through `finalize` or `refactor`), **pause and ask**: "Next WP or stop?" Do **not** auto-chain into a second feature. Each feature is a natural stopping point.
6. **If the user says "next WP"**, loop back into step 2 of cross-workflow handoff with the next work item. Don't re-ask classification or drive mode.

Cross-workflow examples you may hit:
- **P10** (product → feature:plan) — product exit, first WP starts
- **T3 / T9 / F28** (task ESCALATE → feature:spec) — task grew too big; close the task, open a feature
- **F25 / F26 / P11 / P12** — SURFACE, not EXIT: these edit backlog or jump back to product during a feature; they return to the original workflow automatically.

Non-EXIT terminal states (e.g., `F19` finalize → reflect, `T10` close → EXIT): the workflow simply ends. Do not auto-chain into a new one.

### 6. Resume path
If the work classifies as a resume, do NOT start driving. Tell the user to run `/session-resume`. That skill reads `workflow/.session.md` and restores context — including the previously selected drive mode — before any workflow driving would make sense.

## What success looks like

User runs `/session-start <short description>`. You classify, present the mode menu, user picks a mode. You then run every skill in the matching workflow inline, applying the mode's pause policy after each skill returns — re-checking the policy table every time, never relying on skill-level prose. User never retypes a slash command to move forward.

If a terminal transition exits into another workflow (e.g., product → feature), you continue driving in the same dialogue under the new orchestrator's procedure at the same drive mode — one unit deep (one feature, one task). After that unit finishes, pause and ask whether to continue with another.

## What this skill is NOT

- **Not an Agent spawner.** Do not invoke `Agent({subagent_type: "..."})`. The orchestrator files live at `agents/<workflow>-workflow/AGENTS.md`, but you read them as reference material and run the workflow yourself.
- **Not a single-skill runner.** Direct slash commands like `/product-vision` still exist for one-step invocations. `/session-start` is specifically for end-to-end driving.
