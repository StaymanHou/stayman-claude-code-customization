#!/usr/bin/env bash
# add.sh — append a new unchecked item to the store.
# Called by ./todo add "<text>". Store format: one item per line, prefixed
# "[ ] " (open) or "[x] " (done). The line number IS the item index.

set -euo pipefail

store="${TODO_STORE:?TODO_STORE not set}"

text="${1:-}"
if [ -z "$text" ]; then
  echo "add: nothing to add (usage: todo add \"<text>\")" >&2
  exit 2
fi

touch "$store"
printf '[ ] %s\n' "$text" >> "$store"
echo "added: $text"
