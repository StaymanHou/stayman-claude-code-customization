---
date: 2026-06-16
scope: global
type: Memory
session-ref: claudesk WP2 PTY probe
---

# Odd-shape findings deserve one more curiosity cycle before shipping

## Summary

When a verify-self or review-quality finding has a shape that diverges from the standard idiom for that class of system (e.g., "TUI exits on Ctrl+D twice" when modern REPLs typically have `/exit + Enter`; "endpoint returns 200 but body is empty" when sibling endpoints return populated bodies; "test passes but only because the assertion is satisfied by a typeahead side-effect"), the divergence is a signal to invest one more cycle of curiosity before shipping. In autopilot modes (Mode 3, Mode 4), the objective gates can't catch this — the operator's "doesn't feel right" instinct is the recovery mechanism, but it fires post-finalize when the ship commit and CHANGELOG entry already exist.

The WP2 incident that surfaced this: the original finding "CC requires Ctrl+D twice to exit; `/exit\n` doesn't work" was correct as far as it went, but missed the load-bearing root cause (raw-mode CR vs LF — `\r` is Enter, not `\n`). The autopilot gates passed because the verify-self assertion was technically satisfied. The operator caught it post-finalize by gut-check ("just don't feel that should be difficult").

## Suggested change

**Type: Memory (feedback-style)**

Add to `~/.claude/CLAUDE.md` or a global memory file:

> **Odd-shape findings are a probe-more signal, not a ship signal.**
>
> When a verify-self / review-quality finding has a shape that diverges from the standard idiom for that class of system — e.g., a TUI needing two keystrokes to exit when one is the norm, an endpoint passing tests but with surprisingly empty bodies, an assertion satisfied by a side-effect rather than the actual behavior under test — treat the divergence as a signal to invest one more curiosity cycle before shipping. Especially in autopilot modes (Mode 3, Mode 4), where the operator's veto fires post-finalize and ship+CHANGELOG entries already exist by the time gut-check catches the issue.
>
> Heuristic: if you can finish the sentence "this is the shape because…" with a load-bearing reason (raw mode, deliberate API choice, documented behavior), ship. If the sentence ends with "…I don't know, that's just what we observed," probe more.
>
> Mechanism in autopilot: an extra gate is hard to codify (definition of "odd" is judgment), but the heuristic above is a check the agent can self-apply in the verify-self subagent prompt before passing an outcome.

**Type: Skill addition (optional)**

A potential `feature-verify-self-runner` enhancement: before reporting PASS on an outcome, ask the LLM "is this the shape you'd expect from a system of this class?" If the answer hedges ("it's unusual but works"), surface the hedge in the result block as `severity: COSMETIC, detail: <hedge>` so it lands in the verify-human checklist.

## Session-log excerpt

Operator: "Shall we probe a bit more? Just don't feel that should be difficult"

That single sentence reversed an already-finalized finding and corrected a load-bearing WP7 design constraint. Without it, `CcSession::send_slash_command` would have been written with `\n` and would have silently produced typed-but-not-executed bytes — a debug nightmare.
