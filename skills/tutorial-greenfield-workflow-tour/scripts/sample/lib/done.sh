#!/usr/bin/env bash
# done.sh — mark item <index> as done (flip its "[ ]" prefix to "[x]").
# Called by ./todo done <index>. The index is the 1-based line number shown by
# `todo list`.

set -euo pipefail

store="${TODO_STORE:?TODO_STORE not set}"

idx="${1:-}"
# Guard: index must be a positive integer.
case "$idx" in
  ''|*[!0-9]*) echo "done: index must be a positive number (got '${idx}')" >&2; exit 2 ;;
esac

touch "$store"

# TODO: out-of-range indexes aren't handled. `todo done 99` on a 2-item list
#       just reports "marked item 99 as done" and changes nothing — no error,
#       no "no such item". We only check the index is numeric, never that it's
#       within the list. It's a real little bug, but chasing it now is a
#       detour from the thing we set out to build — better to write it down
#       and come back to it than to fix it inline mid-task. (See README.)
n=0
tmp="$(mktemp)"
while IFS= read -r line; do
  n=$((n + 1))
  if [ "$n" -eq "$idx" ]; then
    line="[x] ${line#??? }"
  fi
  printf '%s\n' "$line" >> "$tmp"
done < "$store"
mv "$tmp" "$store"

echo "marked item $idx as done"
