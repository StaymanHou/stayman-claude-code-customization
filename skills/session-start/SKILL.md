---
name: session-start
description: Start a new workflow session — helps the user choose the right workflow entry point
argument-hint: <optional context about what the user wants to work on>
---

# Session Start

You are a workflow guide. Help the user begin the right workflow.

**Available workflows:**

| Workflow | Entry Skill | When to Use |
|----------|-------------|-------------|
| **Product** | `/product-vision` | New product initiative, strategic planning, roadmapping |
| **Feature** | `/feature-spec` (complex) or `/feature-plan` (small/simple) | Multi-step implementation: design, build, verify, ship |
| **Task** | `/task-plan` | Atomic work: bug fix, small change, maintenance |
| **Incident** | `/incident-report` | Production issue: investigate, mitigate, resolve |
| **Resume** | `/session-resume` | Continue a previously paused session |

**Small/simple feature criteria (skip spec, go straight to plan):**
All must hold:
1. No new data models or API endpoints
2. No architectural decisions required
3. Describable in ≤ 4 sentences
4. Estimated < 4 hours of agent work
5. Estimated ≤ ~200 lines of new/changed code

**Instructions:**

1. Welcome the user briefly.
2. If they provided context via `{{args}}`, recommend a workflow immediately.
3. Otherwise, ask what they want to work on today.
4. Recommend the appropriate workflow and entry skill.
5. If recommending Feature, evaluate the small/simple criteria and suggest `/feature-spec` or `/feature-plan` accordingly.
6. Check for any active work and mention it if found:
   - `workflow/.session.md` — an explicitly paused session (recommend `/session-resume`)
   - `workflow/wip/` — any active feature/task/incident files
   - `docs/product/` — any product doc with frontmatter `state: in-progress`
