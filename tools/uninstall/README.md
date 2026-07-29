# uninstall

Standalone, defensive reversal of `install.sh` (WP4, Claudesk Handoff Cycle — arch `AD-2`,
Milestone 8). Works with **zero Claudesk dependency** and leaves **no residue** — the
"try the workflow system, then cleanly back out" story.

The script itself lives at the **repo root** (`uninstall.sh`) as the peer of `install.sh`;
this `tools/uninstall/` dir holds only its test harness and this README.

```
install.sh sets up      -->   uninstall.sh reverses
  ~/.claude/skills/*            removes each into-this-repo symlink
  ~/.claude/agents/*            removes each into-this-repo symlink
  ~/.claude/hooks/*             removes each into-this-repo symlink (if repo has hooks/)
  (nothing — retired)          removes LEGACY ~/.claude/hooks/claude-time-hook.pl
                               + ~/.claude/bin/claude-time (see note below)
  the <!-- BEGIN/END claude-workflow-system --> block in ~/.claude/CLAUDE.md  excises it (backup first)
  (prints settings.json perms)  prints them as "you may want to remove" (never edits)
```

**Legacy claude-time row (asymmetric on purpose).** `tools/claude-time/` was retired from
this repo on 2026-07-29 after Claudesk's Milestone 9 absorbed the capability natively, so
`install.sh` no longer creates those two symlinks — but `uninstall.sh` still removes them,
unconditionally, so installs made by *earlier* versions of `install.sh` are not stranded.
This is the one row where uninstall does more than reverse a current install. The removal is
still bounded by the into-repo guard, and its test seeds the links itself (as dangling
into-repo links) so the assertions exercise a real removal rather than passing on absent paths.

## Usage

```bash
# Preview (changes nothing):
./uninstall.sh --dry-run

# Real uninstall (removes into-repo symlinks + excises the CLAUDE.md block):
./uninstall.sh

# Also remove a specific project's harness memory SYMLINK (never the real store):
./uninstall.sh --project /path/to/consuming/project

# Help:
./uninstall.sh --help
```

Run it from the repo root (it derives `SOURCE_DIR` from its own location, exactly like
`install.sh`, so it also works via an absolute path from anywhere).

## Safety contract

| Property | Behavior |
|---|---|
| **Into-repo guard** | Only removes a symlink when it exists **and** its resolved target points **into this repo** (`$SOURCE_DIR`). A foreign symlink (resolving elsewhere) or a real file/dir at a link path is left untouched and reported `[skip]` — the exact mirror of install's "exists but not a symlink → skip". |
| **`--dry-run`** | Prints planned `[remove]` lines; changes **nothing** on disk. |
| **CLAUDE.md block-only excise** | Removes **only** the marker-delimited `<!-- BEGIN/END claude-workflow-system -->` block via the same `awk` block-delete install uses, after backing the file up to `CLAUDE.md.bak`. Never deletes the file wholesale; non-block content (your own notes) survives. If the file has only the block, an empty file is left (not removed). |
| **Memory symlink-only removal** | With `--project <dir>`, removes **only** the harness memory *symlink* (`~/.claude/projects/<slug>/memory`) and **only** when it resolves to that project's real store (`<dir>/.claude/memory`). The real store is **never** touched. Without `--project`, memory is not handled at all (memory links are per-project, not created by `install.sh`). |
| **Realpath-safe slug** | The `<slug>` is derived via `tools/memory-link/lib-slug.sh` from the **physical** (symlink-resolved) project path (`pwd -P`) — the macOS `/private/tmp` footgun. Target comparison uses `readlink -f` on both sides. |
| **Print-only settings.json** | `install.sh` only *prints* the permissions it wants; `uninstall.sh` symmetrically only *prints* the ones you may want to remove. It **never** edits `~/.claude/settings.json`. |
| **Idempotent** | Re-running after a clean uninstall is a no-op — every target reports `[ok] (already removed)`. |

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Uninstalled, or nothing-to-do (idempotent no-op). |
| `2` | Unknown argument. |

## Relationship to `install.sh`

`install.sh` remains the **canonical single source of truth** for the install steps
(Claudesk's invite *displays* these, it does not hardcode them). `uninstall.sh` reverses
each install action symmetrically. A clean `install → uninstall → re-install` round-trip
is the AD-2 verification target (see test group 7).

## Tests

```bash
tools/uninstall/test/run-tests.sh   # 40 assertions; exit 0 = all pass
```

Exercises the **actual** `install.sh` + `uninstall.sh` against throwaway fake-`$HOME`
sandboxes: dry-run/real/idempotent, into-repo guard (foreign link + real dir preserved),
CLAUDE.md block excise with backup + content survival, per-project memory symlink removal +
all three guards, print-only settings.json, and the WP4.5 install→uninstall→re-install
round-trip.

> ⚠️ **Test-harness safety** (`SURFACE-2026-07-21-UNINSTALL-TEST-HOME-EXPORT-HAZARD`):
> `uninstall.sh` removes things under `$HOME/.claude`. The harness therefore runs **every**
> invocation via `env HOME="$SANDBOX" ...` and **never** `export HOME` at the top level —
> a leak would reach your real home dir. A dedicated assertion confirms the outer `$HOME`
> and the live install are untouched after the run. Any future test of this script must
> follow the same discipline.
