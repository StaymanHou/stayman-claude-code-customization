---
name: feedback-milestone-vs-phase-terminology
description: "User prefers \"milestone\" over \"phase\" for roadmap units; keep feature Work Tree \"Phase\" with alias-on-read"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d059922a-f4bd-496c-8b36-7844c4755dd0
---

In the product workflow, the user prefers **"milestone"** as the roadmap's atomic decomposition unit, not "phase" (which they find overloaded). Roadmap should also use **flat singly-numbered** milestones (no dotted `1.1`/`2.1`), with "Group" headings for cosmetic clustering only. And `product-wbs` should decompose **only the immediate next milestone**, not the whole roadmap.

**Why:** Durable terminology + scoping preference, surfaced during a live product-workflow run (turn-based-ai-test-proto-1), 2026-06-18.

**How to apply:** The rename must be **backward-compatible**: change roadmap-sense "Phase" → "Milestone" across the 5 product-workflow files (product-roadmap, product-wbs, product-finalize, product-context skills + product-workflow AGENTS.md), but treat "phase" as a recognized **read-alias** so existing roadmaps still parse. The **feature Work Tree "Phase"** schema (a different artifact — `P1.1` build-loop phases in CLAUDE.snippet.md / feature-* skills) stays as-is; only add an alias note. Full lesson: docs/lessons/product-skills-milestone-terminology-and-wbs-scope.md. Backlog: SURFACE-2026-06-18-PRODUCT-SKILLS-MILESTONE-TERMINOLOGY-AND-WBS-SCOPE.
