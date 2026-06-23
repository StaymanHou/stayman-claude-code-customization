---
name: feature-research
description: "Feature workflow: conduct research, spikes, or investigation to answer technical questions"
argument-hint: <research topic or questions to answer>
---

# Feature Research

You are an expert Researcher and Code Investigator.

## State Machine Context

You are in the **feature** workflow at the **research** state.

**Valid transitions from here:**
- **F5 → plan:** Research complete, answers are clear → tell user to run `/feature-plan`
- **F6 → spec (back-loop):** Research reveals the spec is wrong → document what changed and why, tell user to run `/feature-spec`

Also used as a **REDIRECT** target:
- From **build** (F22): Hit unknown during implementation — research, then return to build
- From **task:plan** (T4): Task needs research before acting — research, then return to task

If this is a REDIRECT, note the source workflow/state so you can hand back correctly.

## Orchestrator Pause Policy (cheat-sheet)

When invoked by `/session-start` in orchestrated mode, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause. Per-skill rows for research's exits:

| Transition | Mode 1 — Step-by-step | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — Full-autopilot |
|---|---|---|---|---|
| Skill invocation (entry — research review point) | PAUSE | **PAUSE** | AUTO | AUTO |
| F5 (research → plan, findings clear) | PAUSE | (pause already taken at entry) | AUTO | AUTO |
| F6 (research → spec, back-loop) | PAUSE | AUTO | AUTO | AUTO |

REDIRECT returns (from `feature-build` F22 or `task:plan` T4): on completion, the orchestrator returns control to the caller workflow. The hard rule below still applies — chain back via `Skill` in AUTO modes, do not turn-end.

**Hard rule for AUTO exits.** In Modes 3 and 4, research is AUTO — when this skill emits `TRANSITION: F5` (or `F6`, or returns from a REDIRECT) in Mode 3/4, the orchestrator **must immediately invoke the next skill via the `Skill` tool**. It must **NOT** return control to the user. Emitting a clean `TRANSITION: F5` followed by a polite narrative summary ("Research complete; ready to run /feature-plan") in Mode 3/4 is the regression mode this block exists to prevent (P1 incident, 2026-05-16, scope-extended 2026-05-17): the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. **This explicitly includes the `AskUserQuestion` tool (and any other user-input/confirmation prompt): invoking it on an AUTO transition IS "returning control to the user" and is the same regression class as the narrative-summary stop above — do NOT call it to "just confirm" the handoff. The only thing that pauses an AUTO transition is the human-input points the active drive mode's pause policy explicitly marks PAUSE.**

In Modes 1–2 the user reviews research findings before continuing — that pause is taken at skill *entry*. After the user's response, F5 chains forward without a second pause. F6 (back-loop) is AUTO in Modes 2–4 (back-loops are always AUTO). See `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## Procedure

### 1. Identify Questions
- Read the spec in `workflow/wip/` if it exists
- Clarify exactly what needs to be answered
- If arriving via REDIRECT, read the pause note for specific questions

### 2. Investigate
- Search the codebase for relevant patterns, existing implementations
- Use web search for external documentation, libraries, best practices
- Read official references and docs (these override model knowledge per the hierarchy of facts)
- Create temporary scripts or files to test theories (clean them up afterwards)

### 3. Report Findings
Document findings directly in the WIP file under a `## Research` section:
- Specific findings and evidence
- Potential risks identified
- Recommended approaches with trade-offs

### 4. Evaluate Next Step

**If this is a normal research step:**
- If findings are clear and spec holds → recommend `/feature-plan` (F5)
- If findings invalidate the spec → document what changed, recommend `/feature-spec` (F6)

**If this is a REDIRECT return:**
- Evaluate: did findings change the plan?
  - **No change:** Auto-flow results into the plan, annotate, tell user to resume where they left off
  - **Plan changed:** Recommend re-plan before resuming

**Research Topic:** {{args}}
