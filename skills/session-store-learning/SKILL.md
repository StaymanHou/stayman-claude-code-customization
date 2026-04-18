---
name: session-store-learning
description: "Session operation: classify a learning and persist it to the appropriate location (global ~/.claude/ or project .claude/)"
argument-hint: <the learning or insight to store>
---

# Session Store Learning

You are an expert at knowledge engineering. Persist a learning so it's useful for future sessions.

## Context

This is a **session meta-operation** typically invoked after `/session-reflect`.

## Procedure

### 1. Analyze the Learning
Evaluate the input learning from `{{args}}` or from the most recent reflection.

### 2. Classify & Route

**Scope:**
- **Global** — reusable across all projects → store in `~/.claude/`
- **Project-specific** — relevant only to this project → store in `.claude/` (project root)

**Storage Type:**
| Type | When | Location |
|------|------|----------|
| **Ignore** | Trivial, one-off, or already known | Don't store |
| **Context Rule** | Critical convention or constraint | Global: `~/.claude/CLAUDE.md` / Project: `.claude/CLAUDE.md` |
| **Memory** | Reusable insight about user, project, or approach | Global: `~/.claude/projects/*/memory/` / Project: `.claude/memory/` |
| **Skill** | Complex procedural expertise worth codifying | Global: `~/.claude/skills/<name>/` / Project: `.claude/skills/<name>/` |

### 3. Propose Storage
Present clearly:
- **Scope:** Global vs Project
- **Type:** Context Rule / Memory / Skill / Ignore
- **Location:** Exact file path
- **Content:** What will be written (draft it)

### 4. Get Confirmation
Invoke `/notify-human` before asking — the user may have stepped away.

**STOP** and ask the user for confirmation or feedback. Do NOT execute changes yet.

Present:
- The proposed storage location
- The drafted content
- Ask: "Should I save this? Any changes?"

### 5. Execute
**ONLY** after receiving user confirmation:
- Write the content to the proposed location
- If updating an existing file (like CLAUDE.md), append or merge rather than overwrite
- Confirm what was saved and where

### 6. Verify
- Read back the file to confirm it was written correctly
- If it's a memory file, ensure the memory index is updated

**Learning to Store:** {{args}}
