#!/usr/bin/env bash
# Playwright behavioral test runner for the visualize dashboard.
#
# Thin wrapper around test_visualize_interactive.js — the JS file does
# everything: renders the demo dashboard via the CLI, starts a transient
# python3 -m http.server, drives Playwright + Chromium, asserts behavioral
# outcomes, tears down.
#
# This script exists only so the test invocation matches the project's
# bash-test convention (run-in-container.sh exec bash test/test_*.sh).
# It runs inside the container.
#
# Exits 0 on full pass, 1 on any failure.

set -u

# Sanity: this is a container-only test (host doesn't have Playwright).
# Detect by checking for the canonical Playwright base-image marker.
if [ ! -d /ms-playwright ]; then
    echo "ERROR: test_visualize_interactive.sh must run inside the claude-time-test container." >&2
    echo "       From the host, invoke via:" >&2
    echo "         tools/claude-time/test/run-in-container.sh exec bash test/test_visualize_interactive.sh" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec node "$SCRIPT_DIR/test_visualize_interactive.js"
