#!/usr/bin/env bash
# uninstall.sh — Standalone, defensive reversal of install.sh.
#
# Removes everything install.sh sets up, with ZERO Claudesk dependency:
#   - the per-skill symlinks under ~/.claude/skills/
#   - the per-agent symlinks under ~/.claude/agents/
#   - the per-hook symlinks under ~/.claude/hooks/ (if a hooks/ dir exists in the repo)
#   - the claude-time hook.pl + CLI bin symlinks (~/.claude/hooks/claude-time-hook.pl,
#     ~/.claude/bin/claude-time)
#   - the marker-delimited <!-- BEGIN/END claude-workflow-system --> block from
#     ~/.claude/CLAUDE.md
# Optionally (with an explicit --project <dir>) it also removes that project's
# harness memory *symlink* (~/.claude/projects/<slug>/memory) — never the real store.
#
# Safety contract (mirrors install.sh's idempotency + guards, in reverse):
#   - Only removes a symlink when it EXISTS and its resolved target points INTO THIS
#     REPO ($SOURCE_DIR). A foreign symlink or a real file at a link path is left
#     untouched and reported [skip] — exactly the mirror of install's
#     "exists but is not a symlink -> skip" guard.
#   - Excises ONLY the marker block from ~/.claude/CLAUDE.md (backs up to .bak first);
#     never deletes the file wholesale. If the file ends up empty, it is left as an
#     empty file (the user may re-add their own content).
#   - Only prints the settings.json permissions the user may want to remove — install
#     only prints them, so uninstall symmetrically only prints. Never edits settings.json.
#   - Memory reversal removes the SYMLINK only (never the real <proj>/.claude/memory
#     store it points at); slug is realpath-derived via tools/memory-link/lib-slug.sh
#     (the macOS /private/tmp footgun).
#   - Idempotent: re-running after a successful uninstall is a clean no-op.
#
# Usage:
#   uninstall.sh [--dry-run] [--project <dir>]
#   uninstall.sh --help
#
# Exit codes: 0 = uninstalled or nothing-to-do (idempotent no-op).

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude"

DRY_RUN=0
PROJECT_DIR=""

usage() {
  cat <<'EOF'
uninstall.sh — defensively reverse everything install.sh sets up (standalone).

Removes into-this-repo symlinks under ~/.claude/{skills,agents,hooks,bin}, excises the
marker-delimited workflow block from ~/.claude/CLAUDE.md (backup first), and prints
(never edits) the settings.json permissions you may want to remove.

Usage:
  uninstall.sh [--dry-run] [--project <dir>]
  uninstall.sh -h | --help

Options:
  --dry-run          Print planned removals; change nothing on disk.
  --project <dir>    Also remove that project's harness memory SYMLINK
                     (~/.claude/projects/<slug>/memory). The real store it points
                     at (<dir>/.claude/memory) is NEVER touched. Omit to skip
                     memory handling (memory links are per-project, not global).
  -h, --help         Show this help and exit.

Safety: only removes symlinks that resolve INTO this repo; foreign links and real
files are left untouched (reported [skip]). Idempotent — re-run is a clean no-op.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --project)
      # The value must be present AND not flag-shaped. Without this guard, a naive
      # `shift 2` would swallow a following flag as the value — e.g.
      # `--project --dry-run` would set PROJECT_DIR="--dry-run" and leave DRY_RUN=0,
      # silently escalating an intended preview into a REAL uninstall. For a
      # destructive-capable tool that must never happen: treat a missing or
      # flag-shaped value as a usage error (exit 2), same as an unknown argument.
      if [ $# -lt 2 ] || case "${2:-}" in -*) true ;; *) false ;; esac; then
        echo "uninstall.sh: --project requires a directory argument (got: '${2:-<none>}')" >&2
        usage >&2
        exit 2
      fi
      PROJECT_DIR="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "uninstall.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

echo "Uninstalling Claude Code workflow customizations..."
echo "  Source: $SOURCE_DIR"
echo "  Target: $TARGET_DIR"
[ "$DRY_RUN" -eq 1 ] && echo "  (dry-run — nothing will be changed)"
echo

# --- Helper: remove a symlink only if it points INTO this repo ---------------
# Mirror of install.sh's guard, reversed:
#   - not present            -> [ok] (already gone) — idempotent no-op
#   - symlink into this repo -> [remove] (or dry-run print)
#   - symlink elsewhere      -> [skip] (foreign — not ours to remove)
#   - real file/dir          -> [skip] (exists but is not our symlink)
remove_link() {
  local link="$1"
  local label="$2"

  if [ -L "$link" ]; then
    # Resolve the link's target to an absolute physical path. readlink -f follows
    # the chain; guard against a dangling link (target gone) by falling back to the
    # raw readlink value for the into-repo prefix test.
    local resolved
    resolved="$(readlink -f "$link" 2>/dev/null || true)"
    local raw
    raw="$(readlink "$link" 2>/dev/null || true)"
    case "$resolved" in
      "$SOURCE_DIR"/*|"$SOURCE_DIR")
        if [ "$DRY_RUN" -eq 1 ]; then echo "  [remove] $label (dry-run)"; else rm "$link"; echo "  [remove] $label"; fi
        return ;;
    esac
    # Dangling link whose raw target still names this repo counts as ours.
    case "$raw" in
      "$SOURCE_DIR"/*|"$SOURCE_DIR")
        if [ "$DRY_RUN" -eq 1 ]; then echo "  [remove] $label (dry-run, dangling into-repo link)"; else rm "$link"; echo "  [remove] $label (dangling into-repo link)"; fi
        return ;;
    esac
    echo "  [skip] $label (symlink points outside this repo — not ours)"
    return
  elif [ -e "$link" ]; then
    echo "  [skip] $label (exists but is not a symlink — manual resolution needed)"
    return
  fi
  echo "  [ok] $label (already removed)"
}

# --- Remove Skill symlinks ---
if [ -d "$SOURCE_DIR/skills" ]; then
  for skill_dir in "$SOURCE_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name="$(basename "$skill_dir")"
    remove_link "$TARGET_DIR/skills/$skill_name" "skills/$skill_name"
  done
fi

# --- Remove Agent symlinks ---
if [ -d "$SOURCE_DIR/agents" ]; then
  for agent_dir in "$SOURCE_DIR"/agents/*/; do
    [ -d "$agent_dir" ] || continue
    agent_name="$(basename "$agent_dir")"
    remove_link "$TARGET_DIR/agents/$agent_name" "agents/$agent_name"
  done
fi

# --- Remove Hook symlinks (only if the repo has a hooks/ dir, mirroring install) ---
if [ -d "$SOURCE_DIR/hooks" ]; then
  for hook_file in "$SOURCE_DIR"/hooks/*; do
    [ -f "$hook_file" ] || continue
    hook_name="$(basename "$hook_file")"
    remove_link "$TARGET_DIR/hooks/$hook_name" "hooks/$hook_name"
  done
fi

# --- Remove claude-time hook + CLI symlinks ---
CLAUDE_TIME_DIR="$SOURCE_DIR/tools/claude-time"
if [ -d "$CLAUDE_TIME_DIR" ]; then
  remove_link "$TARGET_DIR/hooks/claude-time-hook.pl" "hooks/claude-time-hook.pl"
  remove_link "$TARGET_DIR/bin/claude-time"           "bin/claude-time"
fi

# --- Excise the marker-delimited block from ~/.claude/CLAUDE.md --------------
GLOBAL_CLAUDE_MD="$TARGET_DIR/CLAUDE.md"
BEGIN_MARKER="<!-- BEGIN claude-workflow-system -->"
END_MARKER="<!-- END claude-workflow-system -->"

if [ ! -f "$GLOBAL_CLAUDE_MD" ]; then
  echo "  [ok] CLAUDE.md (no file — nothing to excise)"
elif ! grep -qF "$BEGIN_MARKER" "$GLOBAL_CLAUDE_MD"; then
  echo "  [ok] CLAUDE.md (no workflow block present — nothing to excise)"
else
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [remove] CLAUDE.md workflow block (dry-run)"
  else
    backup="${GLOBAL_CLAUDE_MD}.bak"
    cp "$GLOBAL_CLAUDE_MD" "$backup"
    excised_tmp="$(mktemp)"
    # Delete every line from the BEGIN marker through the END marker inclusive.
    # Same marker literals install.sh writes; awk block-delete mirrors install's
    # block-replace with an empty replacement.
    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
      $0 == begin { in_block = 1; next }
      $0 == end   { in_block = 0; next }
      !in_block   { print }
    ' "$GLOBAL_CLAUDE_MD" > "$excised_tmp"
    mv "$excised_tmp" "$GLOBAL_CLAUDE_MD"
    echo "  [remove] CLAUDE.md workflow block (backup: $backup)"
  fi
fi

# --- Remove the per-project harness memory SYMLINK (only with --project) ------
# install.sh does NOT create this — the memory symlink is created per consuming
# project (by product-context / session-start via tools/memory-link/). So it is
# per-project, opt-in here: only handled when the caller names a project with
# --project. We remove ONLY the symlink at ~/.claude/projects/<slug>/memory, and
# ONLY when it resolves to that project's real store (<proj>/.claude/memory). The
# real store is NEVER touched. Slug is realpath-derived (macOS /private/tmp footgun).
if [ -n "$PROJECT_DIR" ]; then
  SLUG_LIB="$SOURCE_DIR/tools/memory-link/lib-slug.sh"
  if [ ! -f "$SLUG_LIB" ]; then
    echo "  [skip] memory symlink (tools/memory-link/lib-slug.sh not found — cannot derive slug safely)"
  elif [ ! -d "$PROJECT_DIR" ]; then
    echo "  [skip] memory symlink (--project dir does not exist: $PROJECT_DIR)"
  else
    # shellcheck source=tools/memory-link/lib-slug.sh
    . "$SLUG_LIB"
    harness_mem="$(mlink_harness_memory_path "$PROJECT_DIR")"
    repo_mem="$(mlink_repo_memory_path "$PROJECT_DIR")"
    if [ -L "$harness_mem" ]; then
      resolved="$(readlink -f "$harness_mem" 2>/dev/null || true)"
      repo_mem_real="$(readlink -f "$repo_mem" 2>/dev/null || printf '%s' "$repo_mem")"
      if [ "$resolved" = "$repo_mem_real" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
          echo "  [remove] memory symlink $harness_mem -> $repo_mem (dry-run)"
        else
          rm "$harness_mem"
          echo "  [remove] memory symlink $harness_mem (real store $repo_mem left intact)"
        fi
      else
        echo "  [skip] memory symlink (points to '$resolved', not this project's store '$repo_mem_real' — not ours)"
      fi
    elif [ -e "$harness_mem" ]; then
      echo "  [skip] memory store (real directory, not a symlink — never removed): $harness_mem"
    else
      echo "  [ok] memory symlink (already absent): $harness_mem"
    fi
  fi
fi

# --- Print-only settings.json reminder (symmetric to install.sh) --------------
# install.sh only PRINTS the permissions it wants; it never edits settings.json.
# Uninstall symmetrically only PRINTS the permissions you may want to REMOVE.
echo
echo "Uninstall does NOT edit ~/.claude/settings.json. You may want to remove these"
echo "permissions if you added them for this workflow system:"
echo '  "Read(~/.claude/**)"'
echo '  "Edit(~/.claude/**)"'
echo "  \"Read($SOURCE_DIR/**)\""
echo "  \"Edit($SOURCE_DIR/**)\""

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Done (dry-run). Nothing was changed — the lines above are what a real run would remove."
else
  echo "Done. Workflow symlinks and the CLAUDE.md block have been removed."
fi
