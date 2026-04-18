## Workflow System

This machine has a state-machine-driven workflow system installed (skills + orchestrator agents). Projects that use it keep transient state in `workflow/` and strategic product docs in `docs/product/`.

**Four workflows with entry-point slash commands:**

- **Product** — `/product-vision` (new initiative) → roadmap → research → arch → wbs → context
- **Feature** — `/feature-spec` (complex) or `/feature-plan` (small/simple) → build/verify loop → ship → finalize
- **Task** — `/task-plan` → act → close (atomic changes, bug fixes)
- **Incident** — `/incident-report` → triage → investigate → mitigate → resolve

Or `/session-start` to get routed, `/session-pause` and `/session-resume` for cross-session continuity.

**Orchestrator subagents** (`product-workflow`, `feature-workflow`, `task-workflow`, `incident-workflow`) own their full state machine and know every valid transition. **Delegate to the matching orchestrator when** the user is about to run a multi-step workflow, asks "what's next" mid-workflow, or needs help recovering from a back-loop. For single-step requests, invoke the skill directly.

**Per-project layout** (not shared between projects):
```
docs/product/          # vision.md, roadmap.md, research.md, arch.md, wbs.md, context.md
workflow/wip/          # active feature/task/incident items
workflow/backlog.md    # SURFACE discoveries
workflow/archive/      # completed items
workflow/.session.md   # single-file pause pointer
```

## Telegram notify-human (GLOBAL)

**ALWAYS invoke the `/notify-human` skill before requesting human input** — any substantive question, decision point, review request, verification checklist, or any moment the user might have walked away from the terminal. This is non-negotiable across all projects and contexts.

- Requires `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` in `~/.claude/settings.json` env. If unset, skip the notification silently and proceed.
- **Do NOT notify for:** trivial yes/no confirmations during routine steps, or tool permission prompts (Claude Code handles those natively).
