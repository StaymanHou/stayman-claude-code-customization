#!/usr/bin/env bash
# ensure-memory-link.sh — idempotently ensure a project's harness memory store is a
# symlink to the project's git-tracked repo memory dir (Direction A).
#
#   Repo dir  <proj>/.claude/memory/            <- the real, git-tracked store
#   Harness   ~/.claude/projects/<slug>/memory  -> symlink to the repo dir
#
# This gives one physical copy that is BOTH version-controlled (repo) AND auto-loaded
# by the harness at session start (harness path resolves through the link).
#
# Usage:
#   ensure-memory-link.sh <proj-dir> [--dry-run]
#   ensure-memory-link.sh            (defaults <proj-dir> to $PWD)
#
# Idempotent: safe to run every session. Exits 0 when the link is correct (created or
# already present). Non-zero only on a real error or a case that needs migration first.
#
# Cases handled for the harness memory path:
#   (a) does not exist        -> create parent dirs + repo dir + symlink            [LINKED]
#   (b) correct symlink       -> no-op                                              [OK]
#   (c) wrong-target symlink  -> re-point to the repo dir                           [REPOINTED]
#   (d) real (non-symlink) dir with content -> DO NOT touch; tell caller to migrate [NEEDS-MIGRATION]
#   (e) real EMPTY dir        -> replace with symlink (nothing to migrate)          [LINKED]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=lib-slug.sh
. "$SCRIPT_DIR/lib-slug.sh"

PROJ="${1:-$PWD}"
DRY_RUN=0
for arg in "$@"; do
  [ "$arg" = "--dry-run" ] && DRY_RUN=1
done
# If $1 was the flag itself, fall back to $PWD for the project dir.
[ "$PROJ" = "--dry-run" ] && PROJ="$PWD"

if [ ! -d "$PROJ" ]; then
  echo "ensure-memory-link: project dir does not exist: $PROJ" >&2
  exit 2
fi

REPO_MEM="$(mlink_repo_memory_path "$PROJ")"
HARNESS_MEM="$(mlink_harness_memory_path "$PROJ")"

run() { if [ "$DRY_RUN" -eq 1 ]; then echo "DRY-RUN: $*"; else eval "$*"; fi; }

# Ensure the repo-side real dir exists (it is the link target).
if [ ! -d "$REPO_MEM" ]; then
  run "mkdir -p \"$REPO_MEM\""
fi

# Ensure the harness project parent dir exists (harness normally makes this itself,
# but a brand-new project that has not started a session yet won't have it).
HARNESS_PARENT="$(dirname "$HARNESS_MEM")"
if [ ! -d "$HARNESS_PARENT" ]; then
  run "mkdir -p \"$HARNESS_PARENT\""
fi

if [ -L "$HARNESS_MEM" ]; then
  # It's a symlink — case (b) or (c).
  CURRENT_TARGET="$(readlink "$HARNESS_MEM")"
  # Normalise both to physical paths for comparison.
  if [ "$(cd "$(dirname "$HARNESS_MEM")" && cd "$(readlink "$HARNESS_MEM")" 2>/dev/null && pwd -P || true)" = "$(cd "$REPO_MEM" && pwd -P)" ]; then
    echo "OK: already linked  $HARNESS_MEM -> $REPO_MEM"
    exit 0
  else
    echo "REPOINTED: $HARNESS_MEM was -> $CURRENT_TARGET; re-pointing to $REPO_MEM"
    run "rm \"$HARNESS_MEM\""
    run "ln -s \"$REPO_MEM\" \"$HARNESS_MEM\""
    exit 0
  fi
elif [ -d "$HARNESS_MEM" ]; then
  # Real directory — case (d) or (e).
  if [ -n "$(ls -A "$HARNESS_MEM" 2>/dev/null)" ]; then
    echo "NEEDS-MIGRATION: $HARNESS_MEM is a real non-empty dir; run migrate-memory.sh \"$PROJ\" first" >&2
    exit 3
  else
    echo "LINKED: $HARNESS_MEM was an empty real dir; replacing with symlink -> $REPO_MEM"
    run "rmdir \"$HARNESS_MEM\""
    run "ln -s \"$REPO_MEM\" \"$HARNESS_MEM\""
    exit 0
  fi
elif [ -e "$HARNESS_MEM" ]; then
  echo "ensure-memory-link: $HARNESS_MEM exists but is neither symlink nor dir; refusing to touch" >&2
  exit 4
else
  # Case (a): nothing there.
  echo "LINKED: created $HARNESS_MEM -> $REPO_MEM"
  run "ln -s \"$REPO_MEM\" \"$HARNESS_MEM\""
  exit 0
fi
