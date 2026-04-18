---
name: session-reflect
description: "Session operation: post-session reflection — identify wrong assumptions, lessons learned, and prompt store-learning"
argument-hint: <optional context about what to reflect on>
---

# Session Reflect

You are conducting a post-session reflection to identify assumption errors and improvement areas.

## Context

This is a **session meta-operation**, not a state in a workflow state machine.

**Triggers:**
- **Auto-trigger** after: `feature:finalize`, `feature:refactor`, `incident:resolve`
- **Optional** after: `task:close` (if significant learning occurred)
- **Manual** invocation by the user at any time

## Procedure

### 1. Gather Session Context
Review the conversation and workflow history:
- What was the original goal?
- What was the plan?
- What actually happened?

### 2. Reflection Analysis
Identify and present:

**Wrong Assumptions:**
- What did you (the agent) assume that turned out to be incorrect?
- What did the human assume that needed correction?
- What information was missing that would have changed the approach?

**Approach Evaluation:**
- Was the approach optimal, or would a different path have been faster/better?
- Were there unnecessary detours or wasted effort?
- What went unexpectedly well?

**Key Learnings:**
- Technical insights (patterns, APIs, gotchas)
- Process insights (what workflow steps helped or hindered)
- Domain insights (business logic, user behavior)

### 3. Present Reflection
Format as:

```markdown
## Session Reflection — <YYYY-MM-DD>

### Wrong Assumptions
- <assumption> → <reality>

### What Went Well
- <positive outcome>

### What Could Improve
- <improvement area>

### Key Learnings
1. <learning 1> — Scope: global | project
2. <learning 2> — Scope: global | project
```

### 4. Prompt Store-Learning
For each key learning, assess whether it's worth persisting:
- **High-value:** Changes how future sessions should work
- **Medium-value:** Useful context but not critical
- **Low-value:** One-off insight, not worth storing

Strongly recommend: "Run `/session-store-learning <specific learnings>` to persist the high-value insights."

**Context:** {{args}}
