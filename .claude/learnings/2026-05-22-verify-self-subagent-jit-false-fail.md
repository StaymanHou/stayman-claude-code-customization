---
date: 2026-05-22
scope: global
type: Context Rule
session-ref: claude-time-visualize-v2 WP5 Phase 3 verify-self
---

# Verify-self subagents can produce false-FAILs on complex pages with JIT/async rendering

## Summary
A spawned Playwright verify-self subagent reported 7 PASS + 1 BLOCKING FAIL on the dashboard's hash-restore outcome. Direct re-verification by the orchestrator with the same Playwright MCP tools showed the outcome actually PASSed. The subagent's regex snapshot apparently ran before Babel-standalone JIT-compiled the JSX, or read different DOM elements. Babel-in-browser, lazy-mount React trees, and other JIT/async pipelines create a window where snapshots taken "right after navigate" reflect intermediate DOM state, not the final user-visible state.

## Suggested change
**CLAUDE.md rule (global), or addition to `feature-verify-self/SKILL.md`'s severity-taxonomy section:**

> When a verify-self subagent reports a single BLOCKING FAIL that conflicts with a coherent set of subagent PASSes that imply the FAIL outcome must mechanically work (e.g., the dashboard renders fine, hash-write half works, hash-read half should follow trivially), the orchestrator should re-verify the failing outcome directly with the same MCP tools before back-looping to build. Subagent regex/snapshot timing on JIT-compiled or async-rendered pages produces noise that looks like real failures.
>
> Practical applications: pages using Babel-standalone, in-browser JSX transformation, lazy-mounted React subtrees, async data fetches before initial render, or any framework that hydrates content after first paint. The pattern: if N-1 PASSes imply the Nth outcome should hold, suspect snapshot timing before assuming code bug.

## Session-log excerpt
Subagent: "outcome: reload with #viewport=720:780 restores viewport — status: FAIL — Ruler still shows hourly ticks from 06:00 to 22:00 (17 ticks)."
Orchestrator direct re-verify (same Playwright, same URL): `tick_count: 12, first_tick: "12:00", last_tick: "12:55"`, minimap visible-rect at `35.29% / 5.88%` — viewport WAS restored correctly. Subagent's regex `/^\d\d:\d\d$/` apparently ran while Babel was still JIT-compiling.
