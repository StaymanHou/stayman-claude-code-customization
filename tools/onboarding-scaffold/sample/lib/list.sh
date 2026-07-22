#!/usr/bin/env bash
# list.sh — print the numbered todo list.
# Called by ./todo list. Each stored line "[ ] text" / "[x] text" is printed
# as "N. [ ] text" where N is its 1-based line number (the item index).

set -euo pipefail

store="${TODO_STORE:?TODO_STORE not set}"

if [ ! -s "$store" ]; then
  echo "(no todos yet — add one with: todo add \"<text>\")"
  exit 0
fi

n=0
while IFS= read -r line; do
  n=$((n + 1))
  printf '%d. %s\n' "$n" "$line"
done < "$store"
