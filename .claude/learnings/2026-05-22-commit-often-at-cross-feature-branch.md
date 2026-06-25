---
date: 2026-05-22
scope: global
type: Context Rule
session-ref: claude-time-visualize-v2 WP5 + claude-time-test-containerization (sibling pause/resume)
---

# Apply "commit often" — branch off the main workflow with a WIP commit rather than carrying cross-feature dirty state

## Summary
Today's session paused WP5 (claude-time-zoomable-timeline) mid-Phase-4 to ship a sibling feature (claude-time-test-containerization). Both features had uncommitted edits to shared files (CLAUDE.md, dashboard.jsx, viz_render.py, test_visualize_cli.sh). At ship time for each feature, selective `git add` was required to commit only that feature's files. The cost: later when reverting a small edit, `git checkout HEAD -- CLAUDE.md` whole-file-reverted both features' edits, destroying ~60 lines of WP5's URL-hash convention section (recovered manually from conversation transcript). Commits are cheap; cross-feature dirty trees are a destructive-operation hazard surface.

## Suggested change
**CLAUDE.md rule (global), under "Executing actions with care" or as a new "Workflow branch-off discipline" subsection:**

> **Commit before branching workflows.** When a workflow branches off mid-execution — pausing one feature to ship a sibling, opening a parallel incident, or any cross-feature pause/resume situation — make a WIP commit on the paused feature's state BEFORE starting the branch-off work. Commits are cheap. A `[wip] pausing for <reason>` commit on `main` is reversible later (`git reset --soft HEAD~1`, amend, or `git rebase -i` to clean up before the next ship), and it prevents cross-feature dirty-tree contamination.
>
> The workflow system tolerates dirty-tree pauses for short-lived pauses (`/session-pause` + `/session-resume` round-trip), but every additional dirty file is a destructive-operation hazard:
> - `git checkout HEAD -- <file>` reverts whole files, not hunks
> - `git stash` saves all dirty state at once (cross-feature)
> - Selective `git add` requires per-commit discipline that's easy to slip on
>
> Rule of thumb: if a pause is going to span more than ~10 minutes or another feature's full lifecycle, commit the in-flight state. The mental cost of cleanup later is much lower than the cost of losing work to a destructive shortcut.

## Session-log excerpt
Operator: "I tried to revert *my* finalize-time CLAUDE.md edit (the Docker-container note) but used `git checkout HEAD -- CLAUDE.md`, which reverted **everything** in CLAUDE.md — including WP5's URL-hash convention section that had been in the dirty working tree. That work is now gone from the file. It was never committed to git, so reflog/fsck can't recover it."
(Recovery: reconstructed manually from the conversation transcript.)
