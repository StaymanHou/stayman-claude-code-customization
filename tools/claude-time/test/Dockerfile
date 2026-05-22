# claude-time test environment
#
# Base image: Playwright official + Chromium (already includes Node 22 + npm).
# Layered additions: Python 3.12, Perl 5, sqlite3 CLI, jq.
#
# Pinned base: v1.49.1-noble (Ubuntu 24.04 LTS "Noble Numbat"). Re-pin when
# Playwright cuts a new tag we want; the lock here ensures reproducibility.
#
# Build:    docker build -t claude-time-test:latest tools/claude-time/test/
# Usage:    via tools/claude-time/test/run-in-container.sh (start | exec | stop)
# Mount:    project root → /work read-write at run time (handled by wrapper)

FROM mcr.microsoft.com/playwright:v1.49.1-noble

# noninteractive apt: no tzdata prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Single-layer system-package install. python3.12 is the noble default;
# python3.12-venv enables venv for any future test that needs isolation
# (current tests use only stdlib, so no pip-install layer is needed).
# perl 5 is already on noble; install explicitly to pin against the base.
# sqlite3 + jq are needed by test_cli.sh / test_hook.sh / test_visualize_cli.sh.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       python3.12 \
       python3.12-venv \
       perl \
       sqlite3 \
       jq \
       ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Symlink python3 → python3.12 to make `python3` work consistently. The
# Playwright base image may have set python3 differently; force the noble
# 3.12 binary as the canonical python3.
RUN ln -sf /usr/bin/python3.12 /usr/local/bin/python3

# Install Playwright JS bindings globally. The base image ships browser
# binaries at /ms-playwright/ via PLAYWRIGHT_BROWSERS_PATH but NOT the JS
# bindings as a global npm package. We install them so `require('playwright')`
# works from any cwd inside the container. PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
# prevents npm postinstall from re-downloading Chromium (already present at
# /ms-playwright/). Pin to the exact version matching the base image tag.
RUN PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm install -g playwright@1.49.1 \
  && npm cache clean --force

# Make globally-installed npm modules resolvable via `require()` from any
# cwd inside the container (default Node lookup doesn't include the npm-g
# path on the Playwright base image — the env var is unset, so we set it).
ENV NODE_PATH=/usr/lib/node_modules

WORKDIR /work

# Persistent-but-idle: container stays up via tail -f /dev/null so the
# wrapper's `exec` subcommand can attach. No `restart: always` policy —
# the wrapper's `start`/`stop` lifecycle is the supported control plane.
ENTRYPOINT ["tail", "-f", "/dev/null"]
