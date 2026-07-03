---
name: Workflow Pain Points Diagnostic
description: Three diagnosed pain points in the current workflow system, with root causes — input for upcoming skill improvements
type: project
originSessionId: 53e3f8e5-8ed6-4996-864b-8e8212465cbd
---
Three pain points + seven framework gaps diagnosed 2026-04-25. Full detail in `docs/product/workflow-pain-points.md`.

**Pain Point 1 — No live problem tree.** WIP file is a linear checklist. verify-human produces a flat list with no persistent leaf identity. Failed items lose their specific identity when re-entering build. Discoveries during work on node A cannot attach to node B's tree position. No enforcement that a parent node is incomplete until all children are done.

**Why:** The workflow has no parent-child node structure — only a flat checklist and an append-only backlog.

**How to apply:** Any redesign of verify-human, feature-build, and the WIP file format must introduce a persisted tree with explicit node status and scoped re-entry args.

---

**Pain Point 2 — Shallow self-verification.** Agent runs unit tests and hands off to human. Never opens browser, runs curl, or uses Playwright MCP before declaring a phase done. No re-verify gate after its own fix. No behavioral definition of done. No severity triage (blank page vs. cosmetic).

**Why:** verify-auto is scoped to test suite only. No skill mandates observing the running system as a user would before escalating to human.

**How to apply:** Any verify-auto redesign must include a live-system observation step using available tools (Playwright, curl, Bash with real data) before human handoff. A re-verify gate must exist after every agent-initiated fix.

---

**Pain Point 3 — WBS orders by architectural completeness, not learning sequence.** Agent front-loads infrastructure and integrations before API shapes or UX are confirmed. No "spike/probe" work package class. Orchestration layer introduced early, multiplying debug surface before synchronous path is proven.

**Why:** product-wbs has no de-risking order heuristic. It decomposes by build dependencies, not learning dependencies.

**How to apply:** product-wbs must be updated to require a learning-sequence ordering: (1) Docker env, (2) 3rd-party API probes/spikes, (3) frontend mockups, (4) backend without orchestration, (5) orchestration as refactor. Spike WPs must be a named class.
