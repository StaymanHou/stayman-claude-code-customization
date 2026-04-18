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

echo
echo "Done. Symlinks are in place."
echo
echo "Ensure ~/.claude/settings.json has these permissions:"
echo '  "Read(~/.claude/**)"'
echo '  "Edit(~/.claude/**)"'
echo "  \"Read($SOURCE_DIR/**)\""
echo "  \"Edit($SOURCE_DIR/**)\""
echo
echo "Ensure TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are set in settings.json env."
