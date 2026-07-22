#!/usr/bin/env bash
# new-sample.sh — stamp a fresh, throwaway copy of the onboarding sample project.
#
# The tour drops a brand-new user into a COPY of tools/onboarding-scaffold/sample/
# so their real edits, SURFACE, and handoff/restore happen against something
# disposable — never the shipped source. Each tour run gets its own copy.
#
# Usage:
#   new-sample.sh                     # copy into a fresh mktemp dir, print its path
#   new-sample.sh --dest DIR          # copy into DIR (must be empty or nonexistent)
#   new-sample.sh --dest DIR --force  # copy into DIR even if non-empty (overwrite)
#   new-sample.sh --help
#
# On success prints the created directory path and a one-line observable hint.
# POSIX-ish bash, no dependencies.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/sample"

dest=""
force=0

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dest)  dest="${2:-}"; shift 2 ;;
    --force) force=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "new-sample.sh: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

if [ ! -d "$SRC" ]; then
  echo "new-sample.sh: source sample missing at $SRC" >&2
  exit 1
fi

# Default destination: a fresh throwaway dir.
if [ -z "$dest" ]; then
  dest="$(mktemp -d "${TMPDIR:-/tmp}/onboarding-sample.XXXXXX")/greeter"
fi

# No-clobber guard: refuse a non-empty existing dest unless --force.
if [ -e "$dest" ] && [ "$(ls -A "$dest" 2>/dev/null)" ] && [ "$force" -ne 1 ]; then
  echo "new-sample.sh: destination '$dest' exists and is not empty (use --force to overwrite)" >&2
  exit 1
fi

mkdir -p "$dest"
# Copy contents of the sample into dest (preserves the +x bit on greet.sh).
cp -R "$SRC"/. "$dest"/

echo "Created fresh sample at: $dest"
echo "Try it:  cd \"$dest\" && ./greet.sh World   # expect exactly:  Hello, World!"
