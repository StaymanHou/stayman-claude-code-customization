# Read the origin session's raw log before planning a session-spawned feature

When a feature or task is spawned from a decision made in a **prior** session —
a `SURFACE` logged by `feature:reflect` plus operator follow-up, a
`/session-handoff` note saying "address X next session," a "hand it off to next
session" instruction — **read that prior session's raw
`~/.claude/projects/<slug>/*.jsonl` log to recover the operator's already-settled
decisions BEFORE planning.**

## Why

The spawning SURFACE/backlog/handoff entry is a **compression** of the origin
discussion. It preserves the *what* but drops the settled *how*: design decisions
already reached, weightings the operator stated, options already rejected.

Planning from the compressed entry alone risks **re-litigating settled calls** —
presenting an `AskUserQuestion` for a decision the operator already made, which
reads as not having done the homework.

## The concrete failure mode

2026-07-21, the `boundary-handoff-autochain` feature. The first
`AskUserQuestion` re-opened the meta-op-edge-vs-first-class-state modeling choice
that the WP5 origin session's raw log had **already settled** — the prior
session's own reading-(b) recommendation plus the operator's turns 13/14.

The operator's correction was literally: *"read my instruction and desired
behavior from the raw session log of the previous session first."*

## Practically

1. Identify the origin session, newest-first:
   ```sh
   stat -f '%m %N' ~/.claude/projects/<slug>/*.jsonl | sort -rn
   ```
2. Extract the human turns.
3. Read the ones around the spawning decision — before writing the spec or plan.

## Relationship to the mining-gotchas memory

This is a **methodological** rule: *when* and *why* to read the origin log. It is
distinct from and complementary to
[`reference_session-log-mining-gotchas.md`](../../.claude/memory/reference_session-log-mining-gotchas.md),
which is **mechanical**: how to grep the jsonl safely (absolute-path / `--`
guards for leading-dash slugs; count real skill invocations from assistant
`tool_use` rather than raw greps, since skill-listing noise runs ~435/session).
