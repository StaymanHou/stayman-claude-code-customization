## Workflow System

This machine has a state-machine-driven workflow system installed (skills + orchestrator agents). Projects that use it keep transient state in `workflow/` and strategic product docs in `docs/product/`.

**Four workflows with entry-point slash commands:**

- **Product** — `/product-vision` (new initiative) → roadmap → research → arch → wbs → context
- **Feature** — `/feature-spec` (complex) or `/feature-plan` (small/simple) → build/verify loop → ship → finalize
- **Task** — `/task-plan` → act → close (atomic changes, bug fixes)
- **Incident** — `/incident-report` → triage → investigate → mitigate → resolve

Or `/session-start` to get routed, `/session-pause` and `/session-resume` for cross-session continuity.

**Orchestrator procedures** (`agents/<workflow>-workflow/AGENTS.md`) describe how to drive each workflow end-to-end — happy path, back-loops, and which moments require a human pause. `/session-start` reads the matching orchestrator file and runs the workflow **in the current conversation** (not via a subagent spawn), invoking each skill via the Skill tool and pausing only at real decision points (spec/plan review, verify-human, back-loops, triage severity, etc.).

Running an entry-point slash command directly (e.g., `/product-vision`) stays single-step — no auto-chain. Use `/session-start` when you want end-to-end orchestration.

**Per-project layout** (not shared between projects):
```
docs/product/          # vision.md, roadmap.md, research.md, arch.md, wbs.md, context.md
workflow/wip/          # active feature/task/incident items
workflow/backlog.md    # SURFACE discoveries
workflow/archive/      # completed items
workflow/.session.md   # single-file pause pointer
```

## Work Tree Format (GLOBAL)

Every feature WIP file uses the Work Tree format. All skills that read or write WIP files must understand and maintain this structure.

### Schema

```markdown
## Work Tree
- [ ] Phase 1: <name>  <!-- status: in-progress -->
  **Observable outcomes:**
  - Browser: <declarative outcome>
  - HTTP: <declarative outcome>
  - CLI: <declarative outcome>
  - [ ] P1.1 <impl task>  <!-- status: in-progress -->
  - [ ] P1.2 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
    - [ ] <check item>  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: <name>  <!-- status: NOT-STARTED; depends on Phase 1 -->
  ...

## Current Node
- **Path:** <Feature > Phase > specific node>
- **Active scope:** <node IDs currently in focus>
- **Blocked:** <node IDs blocked and why>
- **Unvisited:** <phases not yet started>
- **Open discoveries:** <none | summary>

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
```

### Status vocabulary

| Tag | Meaning |
|-----|---------|
| `NOT-STARTED` | Planned, not yet reached |
| `in-progress` | Agent actively working this node |
| `FAILED` | Failure reported; must resolve before parent advances |
| `BLOCKED: depends on <node>` | Cannot proceed until named node resolves |
| `SURFACED: <summary>` | Discovery attached here; also logged to backlog |
| `[x]` (no tag) | Complete — all children also `[x]` |

### Rules
- **No depth cap** — nest as needed, but prefer splitting wide phases into sibling phases over nesting deeper than Feature > Phase > Verification group > Leaf
- **Parent completion** — a parent's checkbox may only be `[x]` when ALL children are `[x]`
- **Current Node is authoritative** — written on every skill exit, read first on every skill entry; if it diverges from the tree, the tree wins and Current Node is rewritten
- **Observable outcomes at plan time** — written by `feature-plan`, read by `feature-verify-self`; never written post-hoc
- **Tree update on every exit** — every skill that touches a WIP file must update leaf statuses AND Current Node before handing off

## Pre-risky-action checklist (GLOBAL)

**Before running any destructive-capable CLI** — scaffolders (`create-*`, `npm create *`), initializers (`*-init`, `yo *`), codegen tools that write to the working directory, or anything with an `--overwrite` / `--force` flag — run through this checklist:

1. **Git safety net.** If the directory is **not** a git repo, initialize one and commit the current state **before** running the tool: `git init && git add -A && git commit -m "pre-scaffold baseline"`. If it **is** a repo, confirm the working tree is clean (no uncommitted changes that could be destroyed) or `git stash` first.
2. **Read the flags.** If the tool has an `--overwrite`, `--force`, or similar flag and you haven't used it before, run `<tool> --help` first. Flag names lie — `--overwrite=ignore` in some tools means "silently replace existing files," not "skip them." One extra tool call is cheap.
3. **Treat all template/scaffold generators as destructive** until proven otherwise. Non-empty target directories are the danger zone.

Rationale: this rule exists because of a real incident where a scaffolder wiped strategic docs without warning. Only the conversation transcript saved the work. Don't rely on transcript survival.

## Telegram notify-human (GLOBAL)

**ALWAYS invoke the `/notify-human` skill before requesting human input** — any substantive question, decision point, review request, verification checklist, or any moment the user might have walked away from the terminal. This is non-negotiable across all projects and contexts.

- Requires `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` in `~/.claude/settings.json` env. If unset, skip the notification silently and proceed.
- **Do NOT notify for:** trivial yes/no confirmations during routine steps, or tool permission prompts (Claude Code handles those natively).
