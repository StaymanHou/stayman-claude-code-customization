# migrate-doc-layout

One-time migration of a consuming project's **split** workflow-doc layout into the
**unified** single-root layout (M7, Claudesk Handoff Cycle — arch `AD-1`, Option A).

```
OLD (split):                     NEW (unified):
<proj>/docs/product/*      -->    <proj>/workflow-system/product/*
<proj>/workflow/*          -->    <proj>/workflow-system/state/*
```

A newcomer then learns **one** top-level folder (`workflow-system/`); the strategic
(`product/`) vs operational (`state/`) distinction survives as legible substructure.

This mirrors the proven `tools/memory-link/` "reusable primitive + one-time cross-project
migration" template and carries the same safety disciplines.

## Usage

```bash
# Preview (changes nothing):
tools/migrate-doc-layout/migrate-doc-layout.sh <proj-dir> --dry-run

# Real migration:
tools/migrate-doc-layout/migrate-doc-layout.sh <proj-dir>

# Deterministic backup-dir name (used by tests / scripted runs):
tools/migrate-doc-layout/migrate-doc-layout.sh <proj-dir> --date 2026-07-21

# Defaults <proj-dir> to $PWD when omitted:
cd <proj-dir> && /path/to/migrate-doc-layout.sh
```

## Safety contract

| Property | Behavior |
|---|---|
| **Idempotent** | Re-running after a successful migration is a clean no-op (`OK: … nothing to do`). Detected by absence of the old `docs/product`/`workflow` dirs. |
| **`--dry-run`** | Prints planned moves; creates/moves/removes **nothing**. |
| **`--date YYYY-MM-DD`** | Deterministic backup-dir naming (`workflow-system/.migration-backup-<date>/`). Omitted → `date +%F`. The harness shell cannot always call date-of-now, so tests pass this explicitly. |
| **Reversible backup** | Before any move, the entire source subtree is copied into `<proj>/workflow-system/.migration-backup-<date>/`. Delete once you've confirmed the migration. |
| **Drift-keep-both (never clobber)** | If a destination path already exists **and differs** from the source, the destination is kept as-is and the source is moved beside it as `<name>.pre-migrate`; a `DRIFT:` line is printed. Identical duplicates are dropped (`DUP:`). |
| **History-preserving** | In a git repo, uses `git mv` per file so `git log --follow` traces history across the rename. Non-git projects use plain `mv`. |
| **Empty-parent cleanup** | Removes a now-empty `docs/` parent after moving `docs/product`, but **only if empty** — a project keeping `docs/lessons/`, `docs/case-studies/`, etc. is preserved. |

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Migrated, or nothing-to-do (idempotent no-op). |
| `2` | Project dir does not exist. |
| `4` | A source path (`docs/product` or `workflow`) exists but is not a directory — refused. |

## Pre-run checklist (per-project)

Follows the global **pre-risky-action** discipline:

1. **Clean tree or stash.** Confirm the project's git working tree is clean (or `git stash`) before migrating — the script backs up regardless, but a clean tree makes the resulting `git mv` diff easy to review. Projects with **in-flight work** (an active `workflow/wip/` item + uncommitted changes) should commit or stash that work first.
2. **Branch-agnostic.** The migration commits on **whatever branch is checked out** — it does not switch branches. Projects not on `main`/`master` (e.g. a feature branch) get the migration commit on the current branch; that is expected.
3. **`--dry-run` first.** Always preview before the real run.
4. **Review + commit.** In a git repo the moves are **staged** (not committed) — review with `git -C <proj> status`, then commit.

## After migrating

Each migrated project has its docs at the new paths. Any project whose skills read/write
these paths picks up the new layout automatically once it adopts the updated skills (the
skills emit `workflow-system/...` paths). Update any project-specific tooling that hard-codes
the old paths (e.g. Claudesk M11's `docs_list` — see the M12 return contract).

## Tests

```bash
tools/migrate-doc-layout/test/run-tests.sh   # 35 assertions; exit 0 = all pass
```

Exercises the actual script against throwaway fixture projects: dry-run/real/idempotent,
backup, drift-keep-both + identical-dup, git-history-preservation, and error exits.
