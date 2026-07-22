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

# Print the header comment block as help: the contiguous run of `#` lines that
# follows the shebang, stopping at the first non-comment line. Delimiter-anchored
# (not a magic line range) so it can't leak `set -euo pipefail` or the assignments
# below if the header is later edited.
usage() {
  awk 'NR==1 && /^#!/ {next}
       /^#/ {sub(/^# ?/, ""); print; next}
       {exit}' "${BASH_SOURCE[0]}"
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
  # Strip ALL trailing slashes from $TMPDIR (macOS default ends in /) so the
  # printed path the user copies has no double-slash. `%/` strips only one, so
  # loop until none remain.
  tmpbase="${TMPDIR:-/tmp}"
  while [ "${tmpbase%/}" != "$tmpbase" ]; do tmpbase="${tmpbase%/}"; done
  dest="$(mktemp -d "$tmpbase/onboarding-sample.XXXXXX")/todo"
fi

# No-clobber guard: refuse a non-empty existing dest unless --force.
if [ -e "$dest" ] && [ "$(ls -A "$dest" 2>/dev/null)" ] && [ "$force" -ne 1 ]; then
  echo "new-sample.sh: destination '$dest' exists and is not empty (use --force to overwrite)" >&2
  exit 1
fi

mkdir -p "$dest"
# Copy contents of the sample into dest (preserves the +x bits on todo + lib/*.sh).
cp -R "$SRC"/. "$dest"/

echo "Created fresh sample at: $dest"
echo "Try it:  cd \"$dest\" && ./todo add \"buy milk\" && ./todo list   # expect:  1. [ ] buy milk"
