# memory-link

Tooling for **Direction A** of the project-memory location fix: make each project's
harness memory store a **symlink** to its git-tracked repo memory dir, so memories are
both version-controlled *and* auto-loaded by the harness at session start.

```
Repo dir   <proj>/.claude/memory/            <- the real, git-tracked store
Harness    ~/.claude/projects/<slug>/memory  -> symlink to the repo dir
```

One physical copy. No drift. Auto-load (harness resolves through the link) + durability
(git tracks the repo dir) from the same files. Confirmed viable by the WP1 spike
(2026-07-03): the harness writer follows the link (no clobber), reads through it, and
auto-loads `MEMORY.md` through it at session start.

## ⚠️ The realpath footgun (read before touching slug logic)

The harness derives `<slug>` from the **physical (symlink-resolved) absolute path** of the
project working directory — **not** the raw `$PWD`. On macOS `/tmp` → `/private/tmp`, so a
project at `/tmp/foo` gets slug `-private-tmp-foo`, not `-tmp-foo`. Computing the slug from
a non-resolved path targets the **wrong** `~/.claude/projects/<slug>` dir and silently
creates an orphan store. This bit the WP1 spike on its first attempt.

**Rule (empirically confirmed):** `slug = realpath(proj-dir)` with every `/` and `.`
replaced by `-`. Implemented once in `lib-slug.sh` (`mlink_slug`); both scripts source it.
Never re-implement slug math inline.

## Scripts

### `ensure-memory-link.sh <proj-dir> [--dry-run]`
Idempotent. Ensures the harness memory path is a correct symlink to the repo dir. Safe to
run every session. Handles: missing path (create link), correct link (no-op), wrong-target
link (re-point), empty real dir (replace with link). If the harness path is a **non-empty
real dir**, it exits `3` (`NEEDS-MIGRATION`) — run `migrate-memory.sh` first.

### `migrate-memory.sh <proj-dir> [--date YYYY-MM-DD] [--dry-run]`
One-time migration: merges the harness store's files into the repo dir, then links.

- **Drift conflict rule:** same filename + different content in both stores → keep the repo
  copy, preserve the harness copy as `<name>.harness.md`, print a `DRIFT:` line. Never
  silently overwrites. Identical duplicates are dropped.
- **Backup:** every harness-side file is copied into
  `<proj>/.claude/memory/.migration-backup-<date>/` before merge — the migration is
  reversible until you delete the backup. **The backup is transient: delete it once the
  migration is confirmed** (do not commit it, do not add a permanent `.gitignore` rule for
  it — it exists only for the duration of the one-time migration).
- **Index:** rebuilds `MEMORY.md` from the merged repo dir.
- **Idempotent:** re-running after success is a no-op (harness path is already a symlink).

## Reversal

1. `rm ~/.claude/projects/<slug>/memory` (removes the symlink only, not the target).
2. Restore the harness store from the backup:
   `cp -p <proj>/.claude/memory/.migration-backup-<date>/* ~/.claude/projects/<slug>/memory/`
   (recreate the dir first).
3. The repo dir `<proj>/.claude/memory/` is unaffected by reversal — it is the durable copy.

## Scope

Migration applies to any project with a `docs/product/` dir (a real workflow-convention
project). Scratch/copy dirs are excluded. The concrete list is confirmed with the operator
before any migration write.
