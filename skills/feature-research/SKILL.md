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
