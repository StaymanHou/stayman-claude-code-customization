---
date: 2026-05-26
scope: global
type: Skill
session-ref: WP5b-ui-finalize
---

# `## Session Pause` marker leaks into durable product docs

## Summary
`session-pause` appends a `## Session Pause — <timestamp>` block to durable
product docs (observed today on `docs/product/wbs.md`). `session-resume`
correctly consumes and deletes the `workflow/.session.md` pointer, but it
does NOT sweep these companion blocks. The stale block lingers across
subsequent features and would be committed as part of unrelated work if not
noticed. Today's WP5b-ui session caught the leak only during
`/feature-finalize` cleanup — it had migrated through plan/build/verify
without anyone touching `wbs.md`, and `git status` was the only signal.

The leak is harness-level (any project using this skill set will hit it),
not Replicator-specific.

## Suggested change
Pick one of two fix shapes (option (a) is cleaner; option (b) is more
defensive):

(a) **`session-pause` stops writing to durable product docs.**
`workflow/.session.md` is the canonical resume pointer and is sufficient on
its own. Duplicating a `## Session Pause` block into `wbs.md` (or any
`docs/product/*.md`) provides no resume signal that the pointer doesn't
already carry — it only creates a cleanup tax. Restrict pause writes to
`workflow/.session.md` and (if needed) the active WIP file under
`workflow/wip/`.

(b) **`session-resume` sweeps stale pause blocks.** Keep the pause-side
behavior unchanged, but add a step to `session-resume`: grep
`docs/product/*.md` (and possibly other configured durable paths) for
`^## Session Pause` and remove those blocks as part of resume cleanup.
This is workable but adds surface area to the resume skill that exists
only because pause leaks.

Prefer (a). The session pointer is by definition transient; durable docs
shouldn't carry transient state.

## Session-log excerpt
> `git status` at ship time showed `M docs/product/wbs.md` — surprising,
> because the WP5b-ui feature is pure frontend. `git diff` revealed the
> stale `## Session Pause — 2026-05-26 15:35` block at the end of the
> file, written by the pause two features ago and never removed when
> the session resumed. It had to be excised by hand during `/feature-finalize`
> before the finalize commit could land cleanly.
