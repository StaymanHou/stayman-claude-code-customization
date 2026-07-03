---
name: session-store-learning
description: "Session operation: classify a learning and persist it — project-scope Context Rules write to the project ROOT <proj-dir>/CLAUDE.md, memories/skills to <proj-dir>/.claude/; global-scope writes a draft to the canonical <proj-dir>/.claude/learnings/ path. Git behavior (commit vs leave-uncommitted) follows the artifact tracking policy + project overrides, not gitignore inspection."
argument-hint: <the learning or insight to store>
---

# Session Store Learning

You are an expert at knowledge engineering. Persist a learning so it's useful for future sessions.

## Context

This is a **session meta-operation** typically invoked after `/session-reflect`.

**Important boundary:** this skill writes only to the **current project**, never to `~/.claude/`. Project-scope learnings go into the current project: a **Context Rule** to the project **root** `<proj-dir>/CLAUDE.md`, a **Memory** to `<proj-dir>/.claude/memory/`, a **Skill** to `<proj-dir>/.claude/skills/` (see the storage-type table in §2 — the root vs `.claude/` distinction is load-bearing, not interchangeable). Global-scope learnings — ones that would have previously been written into `~/.claude/CLAUDE.md` / `~/.claude/projects/*/memory/` / `~/.claude/skills/` — are instead drafted to `<proj-dir>/.claude/learnings/<YYYY-MM-DD>-<slug>.md`, so the user can review and manually port them into the appropriate source repo (e.g. `my-claude-code-customization`) when warranted. The skill never mutates global Claude Code configuration directly.

## Procedure

### 1. Analyze the Learning
Evaluate the input learning from `{{args}}` or from the most recent reflection.

**Intake note (when invoked after `session-reflect`).** `session-reflect` now pre-filters and pre-scopes: only its **tier-1 store candidates** are handed here, already carrying a `[PROJECT]` / `[GLOBAL]` label from the reflect scope-default (§2b of `session-reflect`). Its "already persisted" and "considered and dropped" tiers are NOT routed to this skill — do not expect them, and do not re-surface them. **Respect the incoming scope label as the default** (it encodes the operator's revealed lean-project preference); only override it if the learning's content plainly contradicts the label, and disclose the override. Do not re-run the reflect filter here — this skill classifies storage *type* and *destination*, not whether the learning is worth keeping.

### 2. Classify & Route

**Scope:**
- **Global** — reusable across all projects → draft to **`<proj-dir>/.claude/learnings/<YYYY-MM-DD>-<slug>.md`** in the current project. Never writes to `~/.claude/`.
- **Project-specific** — relevant only to this project → store in the current project per the **storage-type table below**. Note the two distinct project-scope CLAUDE.md files, which are NOT interchangeable:
  - **`<proj-dir>/CLAUDE.md`** (the project **root** CLAUDE.md) — the project's conventions / "Development Conventions" / gotcha doc. **This is the destination for a project-scope Context Rule** (a standing convention or code-contract constraint).
  - **`<proj-dir>/.claude/CLAUDE.md`** (the project-**local agent-config** file, only present in some projects) — supplementary agent-config a project may maintain. **Do NOT default a Context Rule here.** Only target it if §3's destination check shows the project actually keeps conventions of this kind there *and* the project's root `CLAUDE.md` explicitly routes them there.

**Storage Type:**

| Type | When | Project-scope location | Global-scope behavior |
|------|------|------------------------|-----------------------|
| **Ignore** | Trivial, one-off, or already known | Don't store | Don't draft |
| **Context Rule** | Critical convention or constraint | Project: **`<proj-dir>/CLAUDE.md`** (the project ROOT CLAUDE.md — NOT `<proj-dir>/.claude/CLAUDE.md`) | Draft entry under `## Suggested change` describes the CLAUDE.md rule to add manually |
| **Memory** | Reusable insight about user, project, or approach | Project: `<proj-dir>/.claude/memory/` | Draft entry under `## Suggested change` describes the memory to add manually |
| **Skill** | Complex procedural expertise worth codifying | Project: `<proj-dir>/.claude/skills/<name>/` | Draft entry under `## Suggested change` describes the skill (sketch / name / when-to-use) |

Project-scope learnings are persisted to their permanent home immediately, as before. Global-scope learnings are *documented* — never installed — so the user can review and port them by hand.

### 3. Propose Storage

**Ground the destination in what actually exists — READ before you propose.** Do NOT assert a destination from inference (e.g. "the project already collects this kind of rule in file X"). For a **project-scope** learning, before naming the location:
- **Read the project ROOT `<proj-dir>/CLAUDE.md`** to confirm it exists and see where conventions of this kind already live (e.g. a `## Development Conventions` / `## Key Decisions` / gotcha section). A Context Rule's natural home is alongside the existing conventions there.
- **Check whether `<proj-dir>/.claude/CLAUDE.md` exists** (`ls`/Read). If it does NOT exist, never propose it. If it does, only consider it when the root `CLAUDE.md` explicitly routes conventions of this kind there — otherwise the root file wins.
- A claim like "X already collects this kind of thing" is only allowed *after* you have opened X and seen it. Never route a learning to a file you have not read.

(For a Memory the destination is `<proj-dir>/.claude/memory/`; for a Skill it is `<proj-dir>/.claude/skills/<name>/`. Only **Context Rule** has the root-vs-`.claude/` ambiguity that requires the read above.)

Present clearly:
- **Scope:** Global vs Project
- **Type:** Context Rule / Memory / Skill / Ignore
- **Location:** Exact file path
  - For project-scope: the permanent path, drawn from the storage-type table and grounded in the read above:
    - **Context Rule → `<proj-dir>/CLAUDE.md`** (the project ROOT CLAUDE.md — NOT `<proj-dir>/.claude/CLAUDE.md`)
    - Memory → `<proj-dir>/.claude/memory/<name>.md`
    - Skill → `<proj-dir>/.claude/skills/<name>/SKILL.md`
  - For global-scope: `<proj-dir>/.claude/learnings/<YYYY-MM-DD>-<slug>.md` — explicitly note this is a *draft for later curation*, not a permanent install
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
- For global-scope: a one-line reminder — "this is a draft to `<proj-dir>/.claude/learnings/`; if useful, port to the source repo (e.g. `my-claude-code-customization`) by hand."
- Ask: "Should I save this? Any changes?"

### 5. Execute

**ONLY** after receiving user confirmation:

**Project-scope:**
- Write or append to the existing project file (CLAUDE.md, memory, skill) at the proposed `<proj-dir>/.claude/` path
- If updating an existing file, append or merge rather than overwrite
- **Amend the learning into HEAD (required).** After the write, fold the learning into the most recent commit so it lives in the same commit as the work it describes (the just-completed close commit, in the typical post-reflect cadence):
  - `git add <file-path-just-written>`
  - `git commit --amend --no-edit`
  - Rationale: `/session-store-learning` typically runs after `/session-reflect`, which runs after a terminal-close skill (`feature-finalize`, `task-close`, `incident-resolve`, `product-finalize`). HEAD is the close commit. Amending prevents the "uncommitted learning file lost in a destructive git operation during the next cross-feature pause" failure mode (resolved `SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH`).
  - If HEAD happens to be a non-close commit (e.g., the user committed manually between reflect and store-learning), amend-to-HEAD still lands the learning into a sensible local commit rather than leaving it uncommitted. Reversible later via `git reset --soft HEAD~1` / `git rebase -i` if the operator wants to detach.
  - Do NOT `git push` after amending — see no-auto-push contract in the four close skills.
- Confirm what was saved and where

**Global-scope:**

Global-scope drafts always go to the single canonical destination **`<proj-dir>/.claude/learnings/<YYYY-MM-DD>-<slug>.md`** — never `~/.claude/`, never `<proj-dir>/docs/learnings/`, never anywhere else. Do not infer the destination; it is fixed.

**Git behavior follows the artifact tracking policy, not gitignore inspection.** Per `~/.claude/CLAUDE.md` → `## Artifact tracking policy (GLOBAL)`, `<proj-dir>/.claude/learnings/` is **ignore by default**, overridable per the project's root `CLAUDE.md` `## Artifact tracking overrides`. Decide once, deterministically:

- **If the project's policy IGNORES `<proj-dir>/.claude/learnings/`** (the default — no override): leave the draft uncommitted. It is a working-tree-only parking spot the operator hand-ports to a source repo later. Do NOT `git add`, do NOT amend, do NOT force-add.
- **If the project's root `CLAUDE.md` OVERRIDES to TRACK `<proj-dir>/.claude/learnings/`** (e.g. this repo IS the learning-assets/source repo): the draft is a first-class tracked artifact — `git add` it and `git commit --amend --no-edit` into HEAD, exactly as the project-scope path does (same rationale: fold into the close commit, prevent loss in the next destructive git op).

To determine which branch applies: read the project's root `CLAUDE.md` for an `## Artifact tracking overrides` section naming `<proj-dir>/.claude/learnings/` as tracked. Absent that override, the default (ignore → leave uncommitted) holds. This is the deterministic discriminator — the gitignore file's contents are downstream of the policy, not the source of truth.

- Ensure `<proj-dir>/.claude/learnings/` exists; create it if not
- Write the drafted file to `<proj-dir>/.claude/learnings/<YYYY-MM-DD>-<slug>.md` using this schema:

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
- Confirm to the user: print the final path. Add a one-liner: "Drafted to `<proj-dir>/.claude/learnings/`. If you decide it's worth keeping globally, port it to the source repo by hand."

### 6. Verify
- Read back the file to confirm it was written correctly
- If it's a project-scope memory file, ensure the memory index is updated
- **Memory PII audit (any scope, when the artifact is a memory file).** Per `~/.claude/CLAUDE.md` → `## Artifact tracking policy (GLOBAL)`, memories are tracked by default. After writing a memory, audit it for secrets/PII: **redact in place** if redaction preserves the memory's usefulness (preferred), or **add that specific file to `.gitignore`** if the sensitive content is load-bearing and must be kept verbatim (expected rare). Do not blanket-ignore the whole `<proj-dir>/.claude/memory/` directory.
- **Do NOT inspect or edit `.gitignore` to decide a learning's git fate.** Git behavior is already decided in §5 by the artifact tracking policy + the project's `## Artifact tracking overrides`. `.gitignore` reconciliation across a project is owned by `product-context` (see its `.gitignore` reconciliation step), not by this skill.

**Learning to Store:** {{args}}
