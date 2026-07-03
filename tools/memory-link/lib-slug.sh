#!/usr/bin/env bash
# lib-slug.sh — shared helpers for the memory-link tooling.
# Sourced by ensure-memory-link.sh and migrate-memory.sh. Not executed directly.
#
# THE REALPATH FOOTGUN (read this before touching slug logic):
# The Claude Code harness derives a project's memory-store directory name from the
# *physical* (symlink-resolved) absolute path of the project's working directory —
# NOT the raw $PWD. On macOS, /tmp is a symlink to /private/tmp, so a project at
# /tmp/foo gets the harness slug "-private-tmp-foo", not "-tmp-foo". Computing the
# slug from a non-resolved path targets the WRONG ~/.claude/projects/<slug> dir and
# silently creates an orphan store. This bit the WP1 spike on its first attempt.
# ALWAYS resolve to the physical path first (cd … && pwd -P).

# Resolve a directory to its physical (symlink-free) absolute path.
# Args: $1 = directory path (must exist). Echoes the resolved path.
mlink_realpath() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo "mlink_realpath: not a directory: $dir" >&2
    return 1
  fi
  ( cd "$dir" && pwd -P )
}

# Compute the harness slug for a project directory.
# The harness rule (empirically confirmed 2026-07-03): take the physical absolute
# path and replace every '/' and '.' with '-'. The leading '/' becomes a leading '-'.
# Args: $1 = project directory path. Echoes the slug (e.g. -Users-me-projects-foo).
mlink_slug() {
  local real
  real="$(mlink_realpath "$1")" || return 1
  printf '%s\n' "$real" | sed 's/[/.]/-/g'
}

# Compute the harness memory-store path for a project directory.
# Args: $1 = project directory path. Echoes ~/.claude/projects/<slug>/memory.
mlink_harness_memory_path() {
  local slug
  slug="$(mlink_slug "$1")" || return 1
  printf '%s\n' "$HOME/.claude/projects/$slug/memory"
}

# Compute the repo-side memory dir for a project directory (the real, git-tracked store).
# Args: $1 = project directory path. Echoes <realpath>/.claude/memory.
mlink_repo_memory_path() {
  local real
  real="$(mlink_realpath "$1")" || return 1
  printf '%s\n' "$real/.claude/memory"
}
