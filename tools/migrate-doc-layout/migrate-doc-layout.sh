#!/usr/bin/env bash
# migrate-doc-layout.sh — one-time migration of a consuming project's split workflow-doc
# layout into the unified single-root layout (M7, Claudesk Handoff Cycle, arch AD-1).
#
#   OLD (split):                       NEW (unified):
#   <proj>/docs/product/*        ->    <proj>/workflow-system/product/*
#   <proj>/workflow/*            ->    <proj>/workflow-system/state/*
#
# Result: one top-level `workflow-system/` folder a newcomer must learn, with the
# strategic (product/) vs operational (state/) distinction surviving as substructure.
#
# This mirrors tools/memory-link/migrate-memory.sh's disciplines:
#   - Idempotent: re-running after a successful migration is a no-op.
#   - --dry-run: print planned moves, change nothing.
#   - --date YYYY-MM-DD: deterministic backup-dir naming for tests (the harness-shell
#     cannot call date-of-now in some contexts). If omitted, uses `date +%F`.
#   - Timestamped reversible backup: before any move, the whole source dir is copied
#     into <proj>/workflow-system/.migration-backup-<date>/ so the move is reversible.
#   - Drift/conflict rule: NEVER silently overwrite. If a destination path already
#     exists AND differs from the source, the source is preserved alongside it under
#     a ".pre-migrate" sidecar and a "DRIFT:" line is printed. Identical duplicates
#     are dropped (destination already covers them).
#   - History-preserving move: `git mv` when the project dir is a git repo (so file
#     history follows the rename); plain `mv` otherwise.
#
# Usage:
#   migrate-doc-layout.sh <proj-dir> [--date YYYY-MM-DD] [--dry-run]
#   migrate-doc-layout.sh                 (defaults <proj-dir> to $PWD)
#
# Exit codes: 0 = migrated or nothing-to-do (idempotent no-op); 2 = proj dir missing;
#             4 = a source path exists but is not a directory (refuse).
set -euo pipefail

# --- arg parse (mirrors migrate-memory.sh's loop) ---
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
  echo "migrate-doc-layout: project dir does not exist: $PROJ" >&2
  exit 2
fi

# Normalise to physical path so backup/move operations are unambiguous.
PROJ="$(cd "$PROJ" && pwd -P)"

NEW_ROOT="$PROJ/workflow-system"
BACKUP="$NEW_ROOT/.migration-backup-$STAMP"

run() { if [ "$DRY_RUN" -eq 1 ]; then echo "DRY-RUN: $*"; else eval "$*"; fi; }

# Is this project a git repo? (drives git mv vs plain mv, and history preservation)
IS_GIT=0
if git -C "$PROJ" rev-parse --is-inside-work-tree >/dev/null 2>&1; then IS_GIT=1; fi

# The two (source -> destination-subfolder) mappings.
#   docs/product  -> workflow-system/product
#   workflow      -> workflow-system/state
declare -a SRC=("docs/product" "workflow")
declare -a DST=("product" "state")

# --- Idempotency / nothing-to-do detection ---
# If neither old source dir exists, there is nothing to migrate. This is the
# post-migration steady state (dirs already moved) OR a project that never had them.
have_any_src=0
for s in "${SRC[@]}"; do [ -e "$PROJ/$s" ] && have_any_src=1; done
if [ "$have_any_src" -eq 0 ]; then
  echo "OK: no old-layout dirs at $PROJ (docs/product, workflow) — already migrated or N/A; nothing to do"
  exit 0
fi

# Refuse if a "source" path exists but is not a directory (defensive; matches
# migrate-memory.sh's "exists but not a directory -> refuse").
for i in 0 1; do
  s="$PROJ/${SRC[$i]}"
  if [ -e "$s" ] && [ ! -d "$s" ]; then
    echo "migrate-doc-layout: $s exists but is not a directory; refusing" >&2
    exit 4
  fi
done

echo "Migrating doc layout at $PROJ (git=$IS_GIT, backup=$BACKUP)"
run "mkdir -p \"$NEW_ROOT\""
run "mkdir -p \"$BACKUP\""

# move_dir <src-rel> <dst-subfolder>
#   Moves $PROJ/<src-rel>/* into $NEW_ROOT/<dst-subfolder>/, backing up first, and
#   applying the drift-keep-both rule per file. Uses git mv in a git repo.
move_one() {
  local src_rel="$1" dst_sub="$2"
  local src="$PROJ/$src_rel"
  local dst="$NEW_ROOT/$dst_sub"

  # Nothing at this source -> skip (the other mapping may still apply).
  if [ ! -e "$src" ]; then
    echo "SKIP: $src_rel absent; nothing to move for this mapping"
    return 0
  fi

  # Back up the entire source subtree before touching it (reversible).
  run "cp -R \"$src\" \"$BACKUP/$(basename "$src_rel")\""

  run "mkdir -p \"$dst\""

  # Walk the source recursively; move each file to its mirrored destination path,
  # applying drift-keep-both. Directories are created as needed. We iterate files
  # (not a bulk mv) so the drift rule can be applied per file and so a partially
  # pre-existing destination (an interrupted earlier run) is handled safely.
  #
  # In dry-run we cannot rely on the moves having happened, so we just print intent.
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: move contents of $src -> $dst (git mv per file if git repo), drift-keep-both on conflicts"
    echo "DRY-RUN: rmdir $src after its contents move"
    return 0
  fi

  # find all files under src (including dotfiles like .session.md, .DS_Store).
  # -print0 / read -d '' to survive spaces.
  while IFS= read -r -d '' f; do
    local rel="${f#"$src"/}"          # path relative to src root
    local target="$dst/$rel"
    local target_dir; target_dir="$(dirname "$target")"
    mkdir -p "$target_dir"

    if [ -e "$target" ]; then
      if cmp -s "$f" "$target"; then
        # identical -> destination already covers it; drop the source copy.
        rm -f "$f"
        echo "DUP: $src_rel/$rel (identical, dropped)"
      else
        # DRIFT: same relative path, different content -> keep both, never clobber.
        local sidecar="$target.pre-migrate"
        # If a git repo, prefer git mv for the sidecar so history follows; else cp.
        if [ "$IS_GIT" -eq 1 ] && git -C "$PROJ" ls-files --error-unmatch "$f" >/dev/null 2>&1; then
          git -C "$PROJ" mv -f "$f" "${sidecar#"$PROJ"/}" 2>/dev/null || mv -f "$f" "$sidecar"
        else
          mv -f "$f" "$sidecar"
        fi
        echo "DRIFT: $dst_sub/$rel differs; kept destination + moved source to $(basename "$sidecar")"
      fi
    else
      # No destination counterpart -> move it in (git mv preserves history).
      if [ "$IS_GIT" -eq 1 ] && git -C "$PROJ" ls-files --error-unmatch "$f" >/dev/null 2>&1; then
        git -C "$PROJ" mv "$f" "${target#"$PROJ"/}" 2>/dev/null || mv "$f" "$target"
      else
        mv "$f" "$target"
      fi
    fi
  done < <(find "$src" -type f -print0)

  # Remove the now-empty source tree, deepest-first so parents become removable after
  # their children go. A `find -exec rmdir +` with `-empty` evaluates emptiness at
  # traversal time (before inner dirs are removed), so iterate deepest-first instead.
  # rmdir only succeeds on a truly-empty dir, so a DRIFT sidecar / untracked leftover
  # keeps its dir (intentional — surfaced by the NOTE below).
  while IFS= read -r -d '' d; do
    rmdir "$d" 2>/dev/null || true
  done < <(find "$src" -depth -type d -print0 2>/dev/null)

  if [ -d "$src" ]; then
    echo "NOTE: $src not fully removed (leftover content — inspect); backup at $BACKUP"
  else
    echo "MOVED: $src_rel -> workflow-system/$dst_sub"
    # If the immediate parent of the source (e.g. docs/ for docs/product) is now
    # empty, remove it too — but ONLY if empty (a project may keep docs/lessons/,
    # docs/case-studies/, etc., which must survive).
    local parent; parent="$(dirname "$src")"
    local parent_rel; parent_rel="$(dirname "$src_rel")"
    if [ "$parent" != "$PROJ" ] && [ -d "$parent" ] && [ -z "$(ls -A "$parent" 2>/dev/null)" ]; then
      if rmdir "$parent" 2>/dev/null; then echo "MOVED: removed now-empty parent $parent_rel/"; fi
    fi
  fi
}

for i in 0 1; do
  move_one "${SRC[$i]}" "${DST[$i]}"
done

echo "DONE. Backup retained at $BACKUP (delete once confirmed)."
if [ "$IS_GIT" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
  echo "NOTE: moves are staged (git mv). Review with 'git -C $PROJ status' then commit."
fi
