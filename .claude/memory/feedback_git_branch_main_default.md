---
name: git-branch-main-default
description: User wants work on main by default; never auto-create git branches unless explicitly asked
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4634c80e-3844-4192-a319-c48b1b978a43
---

For this user's repos, `main` (the default branch) IS the working branch. Commit directly to it. Never create or switch to a feature/topic branch on your own initiative — not before a commit, not "for safety," not because a change is large. Only branch when the user explicitly asks (e.g. "make a branch", "open a PR").

**Why:** After upgrading the Claude Code client + switching to Opus 4.8, the agent began auto-creating branches "from time to time," driven by the default harness guidance "if on the default branch, branch first." The user's workflow is trunk-based — branching is friction, not safety.

**How to apply:** Codified as a global rule in `CLAUDE.snippet.md` → `## Environment & Infrastructure (GLOBAL)` → "Git Branch Policy" (propagated to `~/.claude/CLAUDE.md` via `install.sh`). If a branch seems genuinely warranted, ask first; never branch silently. Pairs with [[project_ship_process]] (commit + push to main, no PR workflow).