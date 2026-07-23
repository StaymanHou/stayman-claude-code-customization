---
name: project-tutorial-tour-session-chain-flow
description: The M11 tutorial tour is a CHAIN of real session boundaries; getting-started NEVER dispatches the arm inline — always read docs/lessons/tutorial-tour-session-chain-flow.md before touching any tutorial-* skill
metadata: 
  node_type: memory
  type: project
  originSessionId: e6fc65f2-85d6-429c-a264-4aff62de568d
  modified: 2026-07-23T13:22:16.310Z
---

The M11 onboarding tour (`tutorial-*` family) flow is **operator-specified** and is a
**chain of real session boundaries**, NOT one continuous dispatched session. Before working
on ANY `tutorial-*` skill or `onboarding-flow-spec.md`, read the authoritative doc:
[[docs/lessons/tutorial-tour-session-chain-flow.md]] (`docs/lessons/tutorial-tour-session-chain-flow.md`).

The load-bearing facts I got WRONG by re-deriving instead of reading the origin log
(session `fd4a9b17`, 2026-07-22):

- **getting-started NEVER dispatches the arm skill inline.** It only recommends `auto`
  permission mode, asks new-vs-existing, `cd`s the user to the target dir, points them to the
  right `***-tour` skill, and tells them to `/exit`. The old "dispatches inline to the arm"
  language in the spec + dispatcher Step 3 is WRONG and must be corrected.
- **The arm skill is ALWAYS entered directly, in its own new session.** There is no
  dispatched-vs-direct fork — only **first-run vs. replay**, both direct.
- **Flow:** getting-started (session A, cd + point + exit) → new session B: run arm skill
  DIRECTLY in stepping → handoff → exit → new session C: /session-restore → graduate → clean
  up → exit → new session D: run arm skill DIRECTLY in autopilot/FSD → whole thing again.
- **First-run vs replay discriminator = arm asks ONE line on entry** ("First time through, or
  replaying to try a faster gear?"). First run → stepping, modes stay HIDDEN until Step-8
  graduation. Replay → present the 1–4 drive-mode menu.
- **Drive mode is a numbered menu the workflow presents (1–4), not a slash command.** Because
  the replay enters the arm directly (bypassing /session-start and /session-restore, the two
  canonical menu points), the arm must present that menu itself on the replay run.

Root cause of the miss: violated the standing rule *read the origin session's raw log before
planning session-spawned work* (`~/.claude/CLAUDE.md` last convention bullet;
[[reference_session-log-mining-gotchas]] for the HOW). Always reference the flow doc here.
