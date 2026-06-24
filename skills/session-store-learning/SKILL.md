---
name: session-store-learning
description: "Session operation: classify a learning and persist it — project-scope writes to .claude/ as before; global-scope writes a draft to .claude/learnings/ (gitignored) for the user to curate by hand"
argument-hint: <the learning or insight to store>
---

# Session Store Learning

You are an expert at knowledge engineering. Persist a learning so it's useful for future sessions.

## Context

This is a **session meta-operation** typically invoked after `/session-reflect`.

**Important boundary:** this skill writes only to the **current project**, never to `~/.claude/`. Project-scope learnings go into the project's own `.claude/` directory as before. Global-scope learnings — ones that would have previously been written into `~/.claude/CLAUDE.md` / `~/.claude/projects/*/memory/` / `~/.claude/skills/` — are instead drafted to `.claude/learnings/<YYYY-MM-DD>-<slug>.md` (a gitignored local file), so the user can review and manually port them into the appropriate source repo (e.g. `my-claude-code-customization`) when warranted. The skill never mutates global Claude Code configuration directly.

## Procedure

### 1. Analyze the Learning
Evaluate the input learning from `{{args}}` or from the most recent reflection.

### 2. Classify & Route

**Scope:**
- **Global** — reusable across all projects → draft to **`.claude/learnings/<YYYY-MM-DD>-<slug>.md`** in the current project (gitignored). Never writes to `~/.claude/`.
- **Project-specific** — relevant only to this project → store in `.claude/` (project root) as before.

**Storage Type:**

| Type | When | Project-scope location | Global-scope behavior |
|------|------|------------------------|-----------------------|
| **Ignore** | Trivial, one-off, or already known | Don't store | Don't draft |
| **Context Rule** | Critical convention or constraint | Project: `CLAUDE.md` (root) | Draft entry under `## Suggested change` describes the CLAUDE.md rule to add manually |
| **Memory** | Reusable insight about user, project, or approach | Project: `.claude/memory/` | Draft entry under `## Suggested change` describes the memory to add manually |
| **Skill** | Complex procedural expertise worth codifying | Project: `.claude/skills/<name>/` | Draft entry under `## Suggested change` describes the skill (sketch / name / when-to-use) |

Project-scope learnings are persisted to their permanent home immediately, as before. Global-scope learnings are *documented* — never installed — so the user can review and port them by hand.

### 3. Propose Storage

Present clearly:
- **Scope:** Global vs Project
- **Type:** Context Rule / Memory / Skill / Ignore
- **Location:** Exact file path
  - For project-scope: the permanent path (e.g. `.claude/CLAUDE.md`, `.claude/memory/<name>.md`, `.claude/skills/<name>/SKILL.md`)
  - For global-scope: `.claude/learnings/<YYYY-MM-DD>-<slug>.md` — explicitly note this is a *draft for later curation*, not a permanent install
- **Content:** What will be written (draft it)

After presenting the proposal, end this step's output with the terminal signal line — exactly:

```
TRANSITION: S20
```

This marks the skill as having completed its single-turn job (classification + proposal). The write itself (Step 5) is a separate user-confirmed action.

### 4. Get Confirmation

**STOP** and ask the user for confirmation or feedback. Do NOT execute changes yet.

Present:
- The proposed storage location
- The drafted content
- For global-scope: a one-line reminder — "this is a draft to `.claude/learnings/`; if useful, port to the source repo (e.g. `my-claude-code-customization`) by hand."
- Ask: "Should I save this? Any changes?"

### 5. Execute

**ONLY** after receiving user confirmation:

**Project-scope:**
- Write or append to the existing project file (CLAUDE.md, memory, skill) at the proposed `.claude/` path
- If updating an existing file, append or merge rather than overwrite
- **Amend the learning into HEAD (required).** After the write, fold the learning into the most recent commit so it lives in the same commit as the work it describes (the just-completed close commit, in the typical post-reflect cadence):
  - `git add <file-path-just-written>`
  - `git commit --amend --no-edit`
  - Rationale: `/session-store-learning` typically runs after `/session-reflect`, which runs after a terminal-close skill (`feature-finalize`, `task-close`, `incident-resolve`, `product-finalize`). HEAD is the close commit. Amending prevents the "uncommitted learning file lost in a destructive git operation during the next cross-feature pause" failure mode (resolved `SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH`).
  - If HEAD happens to be a non-close commit (e.g., the user committed manually between reflect and store-learning), amend-to-HEAD still lands the learning into a sensible local commit rather than leaving it uncommitted. Reversible later via `git reset --soft HEAD~1` / `git rebase -i` if the operator wants to detach.
  - Do NOT `git push` after amending — see no-auto-push contract in the four close skills.
- Confirm what was saved and where

**Global-scope:**

(No amend. Global-scope drafts live in `.claude/learnings/` which is gitignored — `git add` would no-op without `-f`, and forcing-add a gitignored file defeats the purpose of the local-curation workflow. The draft stays as a working-tree-only file until the operator hand-ports it.)

- Ensure `.claude/learnings/` exists; create it if not
- Write the drafted file to `.claude/learnings/<YYYY-MM-DD>-<slug>.md` using this schema:

  ```markdown
  ---
  date: <YYYY-MM-DD>
  scope: global
  type: <Context Rule | Memory | Skill>
  session-ref: <optional — short tag or session marker>
  ---

  # <One-line title>

  ## Summary
  <2–4 sentences. What happened, what was learned, why it matters.>

  ## Suggested change
  <Concrete description of where this would belong if promoted to a source repo:
  - "CLAUDE.md rule (global): <rule text>"
  - "Memory (global, type=<user|feedback|project|reference>): <draft body>"
  - "Skill (global): <name, when-to-use, sketch of procedure>"
  >

  ## Session-log excerpt (optional)
  <Short paraphrased fragment that illustrates the moment, if it adds signal.>
  ```

- If a same-slug file exists for today, append `-2`, `-3`, etc.
- Confirm to the user: print the final path. Add a one-liner: "Drafted to `.claude/learnings/`. If you decide it's worth keeping globally, port it to the source repo by hand."

### 6. Verify
- Read back the file to confirm it was written correctly
- If it's a project-scope memory file, ensure the memory index is updated
- For global-scope drafts, ensure `.claude/learnings/` is listed in the project's `.gitignore` — if not, suggest adding it (one-line confirmation; do not edit `.gitignore` without asking)

**Learning to Store:** {{args}}
