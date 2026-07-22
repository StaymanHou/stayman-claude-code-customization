#!/usr/bin/env bash
# greet.sh — a tiny greeter for the onboarding tour's sample project.
#
# Observable behavior (this is what verify-self checks):
#   ./greet.sh World   -> exit 0, prints exactly:  Hello, World!
#
# Run it, read the output, compare to the line above. That is the whole contract.

set -euo pipefail

name="${1:-}"

# TODO: the no-argument case below is not handled well — it prints "Hello, !"
#       which reads wrong. Left as-is on purpose (see README). Don't fix it
#       inline mid-task; that's the kind of tangent worth writing down instead.
echo "Hello, ${name}!"
