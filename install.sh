#!/usr/bin/env bash
# install.sh — Idempotent setup script for Claude Code workflow customizations
# Creates symlinks from source repo to ~/.claude/ and ensures permissions are set.

set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude"

echo "Installing Claude Code workflow customizations..."
echo "  Source: $SOURCE_DIR"
echo "  Target: $TARGET_DIR"
echo

# --- Symlink Skills ---
mkdir -p "$TARGET_DIR/skills"

for skill_dir in "$SOURCE_DIR"/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  link="$TARGET_DIR/skills/$skill_name"

  if [ -L "$link" ]; then
    current_target="$(readlink "$link")"
    if [ "$current_target" = "$skill_dir" ] || [ "$current_target" = "${skill_dir%/}" ]; then
      echo "  [ok] skills/$skill_name (already linked)"
      continue
    else
      echo "  [update] skills/$skill_name (repointing symlink)"
      rm "$link"
    fi
  elif [ -e "$link" ]; then
    echo "  [skip] skills/$skill_name (exists but is not a symlink — manual resolution needed)"
    continue
  fi

  ln -s "${skill_dir%/}" "$link"
  echo "  [new] skills/$skill_name"
done

# --- Symlink Agents ---
mkdir -p "$TARGET_DIR/agents"

for agent_dir in "$SOURCE_DIR"/agents/*/; do
  [ -d "$agent_dir" ] || continue
  agent_name="$(basename "$agent_dir")"
  link="$TARGET_DIR/agents/$agent_name"

  if [ -L "$link" ]; then
    current_target="$(readlink "$link")"
    if [ "$current_target" = "$agent_dir" ] || [ "$current_target" = "${agent_dir%/}" ]; then
      echo "  [ok] agents/$agent_name (already linked)"
      continue
    else
      echo "  [update] agents/$agent_name (repointing symlink)"
      rm "$link"
    fi
  elif [ -e "$link" ]; then
    echo "  [skip] agents/$agent_name (exists but is not a symlink — manual resolution needed)"
    continue
  fi

  ln -s "${agent_dir%/}" "$link"
  echo "  [new] agents/$agent_name"
done

# --- Inject workflow snippet into ~/.claude/CLAUDE.md ---
SNIPPET_FILE="$SOURCE_DIR/CLAUDE.snippet.md"
GLOBAL_CLAUDE_MD="$TARGET_DIR/CLAUDE.md"
BEGIN_MARKER="<!-- BEGIN claude-workflow-system -->"
END_MARKER="<!-- END claude-workflow-system -->"

if [ ! -f "$SNIPPET_FILE" ]; then
  echo "  [warn] CLAUDE.snippet.md not found at $SNIPPET_FILE — skipping injection"
else
  # Build the block (markers + snippet content)
  block_tmp="$(mktemp)"
  {
    printf '%s\n' "$BEGIN_MARKER"
    printf '<!-- Managed by install.sh in %s. Edits between these markers will be overwritten on re-run. -->\n' "$SOURCE_DIR"
    cat "$SNIPPET_FILE"
    printf '%s\n' "$END_MARKER"
  } > "$block_tmp"

  if [ ! -f "$GLOBAL_CLAUDE_MD" ]; then
    # Create file with just the block
    cat "$block_tmp" > "$GLOBAL_CLAUDE_MD"
    echo "  [new] CLAUDE.md (created with workflow block)"
  elif grep -qF "$BEGIN_MARKER" "$GLOBAL_CLAUDE_MD"; then
    # Replace existing block between markers
    backup="${GLOBAL_CLAUDE_MD}.bak"
    cp "$GLOBAL_CLAUDE_MD" "$backup"
    updated_tmp="$(mktemp)"
    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v blockfile="$block_tmp" '
      BEGIN { in_block = 0 }
      $0 == begin {
        # Print our fresh block
        while ((getline line < blockfile) > 0) print line
        close(blockfile)
        in_block = 1
        next
      }
      $0 == end {
        in_block = 0
        next
      }
      !in_block { print }
    ' "$GLOBAL_CLAUDE_MD" > "$updated_tmp"
    mv "$updated_tmp" "$GLOBAL_CLAUDE_MD"

    # Only keep backup on first run (when it differs); otherwise remove to reduce clutter
    if cmp -s "$backup" "$GLOBAL_CLAUDE_MD"; then
      rm "$backup"
      echo "  [ok] CLAUDE.md (workflow block already up to date)"
    else
      echo "  [update] CLAUDE.md (workflow block refreshed, backup: $backup)"
    fi
  else
    # Append block with separator; back up first
    backup="${GLOBAL_CLAUDE_MD}.bak"
    cp "$GLOBAL_CLAUDE_MD" "$backup"
    {
      cat "$GLOBAL_CLAUDE_MD"
      # Ensure a blank line separator
      if [ -n "$(tail -c1 "$GLOBAL_CLAUDE_MD")" ]; then
        printf '\n'
      fi
      printf '\n'
      cat "$block_tmp"
    } > "${GLOBAL_CLAUDE_MD}.new"
    mv "${GLOBAL_CLAUDE_MD}.new" "$GLOBAL_CLAUDE_MD"
    echo "  [append] CLAUDE.md (workflow block appended, backup: $backup)"
  fi

  rm -f "$block_tmp"
fi

echo
echo "Done. Symlinks and CLAUDE.md block are in place."
echo
echo "Ensure ~/.claude/settings.json has these permissions:"
echo '  "Read(~/.claude/**)"'
echo '  "Edit(~/.claude/**)"'
echo "  \"Read($SOURCE_DIR/**)\""
echo "  \"Edit($SOURCE_DIR/**)\""
echo
echo "Ensure TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are set in settings.json env."
