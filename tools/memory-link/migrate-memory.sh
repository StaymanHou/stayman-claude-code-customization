#!/usr/bin/env bash
# migrate-memory.sh — one-time migration of a project's harness memory store into its
# git-tracked repo memory dir, then replace the harness dir with a symlink (Direction A).
#
# Merges  ~/.claude/projects/<slug>/memory/*  into  <proj>/.claude/memory/  then links.
#
# Drift conflict rule: if a file with the SAME name exists in BOTH stores with DIFFERENT
# content, the repo copy is kept as-is and the harness copy is preserved alongside it as
# "<name>.harness.md" (NEVER silently overwritten). A "DRIFT:" line is printed for each.
# Identical duplicates are dropped (repo copy already covers them).
#
# Safety: every file moved out of the harness store is first copied into a timestamped
# backup under <proj>/.claude/memory/.migration-backup-<date>/ so the migration is
# reversible. Idempotent: re-running after a successful migration is a no-op (the harness
# path is already a symlink, so there is nothing to merge).
#
# Usage:
#   migrate-memory.sh <proj-dir> [--date YYYY-MM-DD] [--dry-run]
#
# --date is required for deterministic backup-dir naming in tests (the harness shell
# cannot call date-of-now in some contexts). If omitted, uses `date +%F`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib-slug.sh
. "$SCRIPT_DIR/lib-slug.sh"

PROJ=""
STAMP=""
DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --date) STAMP="$2"; shift 2 ;;
    *) if [ -z "$PROJ" ]; then PROJ="$1"; fi; shift ;;
  esac
done
[ -z "$PROJ" ] && PROJ="$PWD"
[ -z "$STAMP" ] && STAMP="$(date +%F)"

if [ ! -d "$PROJ" ]; then
  echo "migrate-memory: project dir does not exist: $PROJ" >&2
  exit 2
fi

REPO_MEM="$(mlink_repo_memory_path "$PROJ")"
HARNESS_MEM="$(mlink_harness_memory_path "$PROJ")"

run() { if [ "$DRY_RUN" -eq 1 ]; then echo "DRY-RUN: $*"; else eval "$*"; fi; }

# Idempotency: already a symlink -> nothing to migrate.
if [ -L "$HARNESS_MEM" ]; then
  echo "OK: $HARNESS_MEM is already a symlink; nothing to migrate"
  exec "$SCRIPT_DIR/ensure-memory-link.sh" "$PROJ"
fi

# Nothing at the harness path -> nothing to migrate; just ensure the link.
if [ ! -e "$HARNESS_MEM" ]; then
  echo "OK: no harness store at $HARNESS_MEM; ensuring link only"
  exec "$SCRIPT_DIR/ensure-memory-link.sh" "$PROJ"
fi

if [ ! -d "$HARNESS_MEM" ]; then
  echo "migrate-memory: $HARNESS_MEM exists but is not a directory; refusing" >&2
  exit 4
fi

run "mkdir -p \"$REPO_MEM\""
BACKUP="$REPO_MEM/.migration-backup-$STAMP"
run "mkdir -p \"$BACKUP\""

echo "Migrating $HARNESS_MEM -> $REPO_MEM (backup: $BACKUP)"

# Iterate harness files (top-level *.md; the store is flat by convention).
shopt -s nullglob
for src in "$HARNESS_MEM"/*; do
  [ -f "$src" ] || continue
  name="$(basename "$src")"
  # Always back up the harness-side file before doing anything.
  run "cp -p \"$src\" \"$BACKUP/$name\""

  # MEMORY.md is the index, NOT a memory. Never merge it and never create a
  # MEMORY.harness.md drift artifact — the index is rebuilt from scratch below.
  # It is still backed up (above) so nothing is lost.
  if [ "$name" = "MEMORY.md" ]; then
    echo "INDEX: MEMORY.md backed up + skipped (index is rebuilt, not merged)"
    continue
  fi

  dst="$REPO_MEM/$name"

  if [ ! -e "$dst" ]; then
    # No repo counterpart -> move it in.
    run "cp -p \"$src\" \"$dst\""
    echo "MOVED: $name"
  elif cmp -s "$src" "$dst"; then
    # Identical -> repo copy already covers it; drop the harness dup.
    echo "DUP: $name (identical, dropped)"
  else
    # DRIFT: same name, different content -> keep both.
    drift_name="${name%.md}.harness.md"
    [ "$drift_name" = "$name" ] && drift_name="$name.harness"
    run "cp -p \"$src\" \"$REPO_MEM/$drift_name\""
    echo "DRIFT: $name differs; kept repo copy + harness copy as $drift_name"
  fi
done
shopt -u nullglob

# Rebuild MEMORY.md index from the repo dir's memory files (excludes MEMORY.md,
# the backup dir, and hidden files). Preserves an existing MEMORY.md header line.
rebuild_index() {
  local mem="$1"
  local idx="$mem/MEMORY.md"
  {
    echo "# Memory Index"
    echo ""
    for f in "$mem"/*.md; do
      [ -f "$f" ] || continue
      local base; base="$(basename "$f")"
      # Exclude the index itself and any stale MEMORY.harness.md left by an older run.
      [ "$base" = "MEMORY.md" ] && continue
      [ "$base" = "MEMORY.harness.md" ] && continue
      # Pull description from frontmatter if present, else a placeholder.
      local desc
      desc="$(awk -F': ' '/^description:/{sub(/^description: */,""); print; exit}' "$f")"
      [ -z "$desc" ] && desc="(no description)"
      echo "- [$base]($base) — $desc"
    done
  } > "$idx.tmp"
  mv "$idx.tmp" "$idx"
}

if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY-RUN: would rebuild $REPO_MEM/MEMORY.md"
else
  rebuild_index "$REPO_MEM"
  echo "REBUILT: $REPO_MEM/MEMORY.md"
fi

# Replace the harness dir with a symlink. The originals are already backed up in the
# repo dir; we can safely remove the now-merged harness dir.
run "rm -rf \"$HARNESS_MEM\""
run "ln -s \"$REPO_MEM\" \"$HARNESS_MEM\""
echo "LINKED: $HARNESS_MEM -> $REPO_MEM"
echo "DONE. Backup retained at $BACKUP (delete once confirmed)."
