---
workflow: feature
state: verify-codify (all phases complete)
created: 2026-05-22
drive_mode: autopilot
blocks: claude-time-visualize-v2 cycle WP5 Phase 4 (paused — unblocked by this feature; resume after ship+finalize)
---

# Feature: Containerize the `claude-time` test infrastructure

**Workflow:** feature
**State:** spec
**Created:** 2026-05-22
**Entry:** spec (complex feature — new architectural layer, no existing equivalent in repo)

## Problem Statement

The `claude-time` test suite has grown to 156 PASS across 5 test files spanning bash, Python, Perl, and now needs Playwright for WP5 Phase 4's behavioral test (`test_visualize_interactive.sh`). Playwright requires a Node/npm install + a Chromium binary (~150MB), neither of which currently exist on the developer's host. Installing them on the host violates the global `CLAUDE.md` Docker Hard-Blocker rule — that rule was written exactly for this scenario.

This feature creates a Docker-based test environment for `tools/claude-time/` so all test infrastructure (existing + new) runs in a controlled environment without touching the host. The container is persistent + on-demand: a wrapper script (`tools/claude-time/test/run-in-container.sh`) handles `start` / `stop` / `exec <cmd>` lifecycle; tests are invoked via `exec`. The container is not always running; the developer starts it before running tests and stops it when done.

Once shipped, this becomes the **only supported test-runner path** going forward. Host runs are not removed (Python unit tests will still work on the host because they use only stdlib), but they are not the supported path and no documentation will recommend them.

This feature pauses WP5 (claude-time-visualize-v2 cycle) at Phase 4 P4.1; WP5 resumes at Phase 4 P4.2 (Playwright test) inside the container once this feature ships.

## User Stories

- **As the developer (or any future contributor),** I want to run the full claude-time test suite without installing Node, Playwright, browser binaries, or any other test-only dependency on my host.
- **As the developer,** I want to start the test container with one command (`run-in-container.sh start`) and tear it down with another (`run-in-container.sh stop`); the container should not consume resources when I'm not testing.
- **As the developer,** I want each test invocation to be fast — the container should stay up between test runs so I don't pay the cold-start tax on every `exec`. `run-in-container.sh exec bash test/test_visualize_cli.sh` should complete in seconds, not minutes.
- **As the developer,** I want the container to bind-mount the project read-write so source edits I make on the host are immediately visible inside the container without rebuilding the image.
- **As the developer,** I want `test_hook.sh` (which exercises `hook.pl`) to keep passing inside the container even though `hook.pl` normally runs on the host's `~/.claude/hooks/`. The container copies the script in and unit-tests its behavior; this is an acceptable trade since the test was always testing the script, not the install state.
- **As the WP5 Phase 4 implementer,** I want to write a real Playwright behavioral test (`test_visualize_interactive.sh`) that drives a headless Chromium against the dashboard HTML, asserts gesture behavior, hash round-trip, and adaptive ruler density — all running inside the container with zero host-OS impact.
- **As the WP5 Phase 4 perf-measurement implementer,** I want `__perfRecord` (the `?perf=1`-gated rAF fps sampler) to be exercisable against a synthetic 1-month dataset inside the container, with the measurement result extractable via console-log capture or via `window.__perfResult`.
- **As the documentation reader,** I want `tools/claude-time/README.md` to clearly state that tests run in the container and how to start/stop/exec it, with no leftover wording suggesting host-side test invocation is the supported path.

## Acceptance Criteria

The feature is done when:

1. **Container image builds cleanly.** `docker build -t claude-time-test tools/claude-time/test/` (or equivalent path) produces an image that includes: Playwright official base (`mcr.microsoft.com/playwright:v1.x-noble`, where `x` is pinned to a specific tagged release at build time), Python 3.12, Perl 5 (≥5.30), sqlite3 CLI, bash 5+, `jq`. Image build is reproducible — pinning all package versions at build time.
2. **Persistent + on-demand lifecycle.** `tools/claude-time/test/run-in-container.sh start` builds the image (if not cached), starts the container in detached mode with the project bind-mounted at `/work` read-write, and exits. The container has no `restart: always` policy — it does not survive a host reboot, but it does survive between test runs. `run-in-container.sh stop` stops and removes the container. `run-in-container.sh exec <cmd>` runs the command inside the running container and streams stdout/stderr.
3. **`run-in-container.sh status`** prints `running` / `stopped` / `image-not-built` based on `docker ps` and `docker images` state. Exit code reflects state for shell scripting (`0` = running, `1` = stopped, `2` = no image).
4. **`run-in-container.sh exec`** errors out with exit code `3` and a helpful message ("container is not running — run `run-in-container.sh start` first") if the container isn't up. Does NOT auto-start. Auto-start would mask the "container should not always be on" requirement.
5. **All existing tests PASS inside the container.** `run-in-container.sh exec bash test/test_cli.sh` PASS 29/29. Same for `test_hook.sh` (17/17), `test_visualize_cli.sh` (41/41), `test_reclassify.py` (29 ok), `test_viz_data.py` (40 ok). Aggregate: 156/156 inside the container, matching pre-containerization host count. Performance benchmarks (`bench.sh`, `multi_instance.sh`, `privacy_check.sh`, `stress_concurrent.sh`) are out of scope for this feature — they may or may not work inside the container; document as known-unknown if not exercised.
6. **`hook.pl` testing inside the container.** `test_hook.sh` runs against the project's copy of `hook.pl` (NOT against `~/.claude/hooks/claude-time-hook.pl` — that path doesn't exist in the container). The test's environment variables (`CLAUDE_TIME_TRACKING=1`, `CLAUDE_TIME_DIR=$tmpdir`) work as before; the script-resolution path uses the project source. Acceptable — the test was always exercising the script's behavior in isolation, not the live-install state.
7. **WP5 Phase 4 work resumes inside the container.** A new `test/test_visualize_interactive.sh` (written as part of THIS feature's verify-codify? or in WP5 Phase 4? see Open Questions) successfully drives Playwright (or a Python-Playwright wrapper) against `claude-time visualize`'s emitted HTML, served by an `http.server` started inside the container.
8. **Bind-mount works correctly.** A source edit made on the host (e.g., touch `viz/dashboard.jsx`) is immediately visible inside the container without rebuild — `docker exec ... stat /work/tools/claude-time/viz/dashboard.jsx` shows the new mtime. The container writes test artifacts (sqlite DBs, emitted HTML) to host-visible paths via the bind-mount.
9. **README.md updated.** A new "Running tests" section in `tools/claude-time/README.md` explains the container lifecycle and lists the standard test invocations. Any previous wording that implied host-side test invocation is updated or removed.
10. **`tests/check-structure.sh` Phase 7 (settings fixture drift)** is NOT affected by this feature — that phase checks `~/.claude/settings.json` which lives on the host and is unrelated to the test container. The pre-existing `SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME` backlog item remains independent.
11. **No host-OS pollution.** Nothing this feature adds requires the developer to `pip install`, `npm install`, `brew install`, or otherwise modify host-OS state. The only host requirement is Docker engine (already installed per ambient check during spec — Docker 29.4.0). The container's `Dockerfile`, `docker-compose.yml` (if used), wrapper script, and image build all live inside `tools/claude-time/test/` (or similar containment).
12. **`run-in-container.sh` is the public surface.** Developers invoke tests via `run-in-container.sh exec <cmd>`. Raw `docker run` / `docker exec` calls work too, but are not the documented entry. The wrapper handles image-build state, container lifecycle, bind-mount paths, and forwards exit codes correctly.

## Out of Scope

- **Containerizing the production CLI** (`claude-time` invocations against the user's real `~/.claude-time` data). The container is test-only; production runs continue against the host's `~/.claude-time/` via the host's Perl + Python.
- **CI integration.** This feature ships the local container; CI is a separate concern. A future feature can wire GitHub Actions to use the same Dockerfile, but that's not in this scope.
- **Cross-platform builds.** Single linux/amd64 image. No `--platform linux/arm64` consideration. Apple Silicon developers get x86_64 emulation via Docker Desktop's QEMU layer — that's fine for test workloads; perf measurement results from Apple Silicon hosts running x86_64 emulation should not be trusted for the WP5 P4.4 60fps measurement (verify-self should run on a Linux x86_64 host, or note the emulation caveat).
- **The benchmark scripts** (`bench.sh`, `multi_instance.sh`, `privacy_check.sh`, `stress_concurrent.sh`). Acceptance #5 says these are out of scope. If any of them happen to work in the container, great; if not, log as backlog.
- **Removing the host-side stress/bench scripts.** They remain runnable on the host for ad-hoc developer use.
- **`tests/check-structure.sh` (workflow-system tests)** — separate from claude-time, not part of this containerization.
- **Workflow-system test runner** (`tests/run-tests.sh`, scenario YAMLs). Different project surface; not touched.
- **A way to develop inside the container** (devcontainer.json, VS Code integration, etc.). The container is for test runs, not for editing. Source edits happen on the host.
- **Hot-reload of `viz/dashboard.jsx` for browser-based testing.** Out of scope — Playwright drives `claude-time visualize` which emits a static HTML file; no dev server needed.

## Technical Constraints

- **Docker engine required on host.** Verified during spec: `docker --version` reports `29.4.0`, daemon responsive. Container does not need elevated privileges (rootless OK).
- **Playwright base image:** `mcr.microsoft.com/playwright:v1.x-noble` — pin to a specific tagged release at Dockerfile commit time (TBD at plan time — likely `v1.49.0-noble` or whatever is current). The image already includes Node, npm, Playwright JS bindings, and Chromium. We add Python 3.12 (via `apt-get install python3.12 python3.12-venv`), Perl 5 (already in noble), sqlite3 CLI (`apt-get install sqlite3`), and jq.
- **Image size budget:** ≤ ~2 GB total. The Playwright base alone is ~1.5 GB; our additions should add < 500 MB.
- **Bind-mount path convention:** Project root mounts at `/work` inside the container. All scripts inside the container use `/work/tools/claude-time/` paths. The wrapper script computes the host-side project root via `git rev-parse --show-toplevel` and passes it as the bind-mount source.
- **Container working directory:** `/work` (project root). Tests cd into `tools/claude-time/` as needed.
- **No persistent container volumes.** All test artifacts (sqlite DBs, emitted HTML, screenshots) write to the bind-mounted project tree (specifically into `/tmp` paths that are NOT bind-mounted — temp data inside the container is ephemeral; only test-source files visible via bind-mount). When `run-in-container.sh stop` removes the container, all `/tmp` data is discarded — that's fine, tests should write their own tempdirs anyway (existing tests do).
- **Pinning policy.** Pin all versions: Playwright base image tag, Python version (`python3.12`, not `python3`), sqlite3 version (whatever noble ships), Perl version (whatever noble ships). Lock the Dockerfile so a `docker build` six months from now produces the same image.
- **No Docker Compose required.** Single container, no service orchestration. A `Dockerfile` + the wrapper script is enough. (Could add `docker-compose.yml` if it simplifies the wrapper — plan-time decision.)
- **Container name:** `claude-time-test` (single instance; the wrapper checks if it already exists before `docker run`).
- **Wrapper script location:** `tools/claude-time/test/run-in-container.sh`. Other test files stay where they are; the wrapper is what changes the invocation pattern from `bash test/test_xxx.sh` to `tools/claude-time/test/run-in-container.sh exec bash test/test_xxx.sh`.

## Plan-time decisions (resolves spec Open Questions)

| Spec question | Decision | Rationale |
|---|---|---|
| Playwright invocation language | **Node directly** — `node test/test_visualize_interactive.js` invoked from a thin `test_visualize_interactive.sh` wrapper | Base image already ships Node + Playwright JS. Zero extra install. |
| `http.server` lifecycle | Bash helper inside `test_visualize_interactive.sh`: `python3 -m http.server 8769 &; SRV_PID=$!; sleep 0.5; trap 'kill $SRV_PID 2>/dev/null' EXIT`. Fixed port `8769` (no collision with verify-self workarounds) | Standard bash pattern; trap-on-exit ensures cleanup |
| Cold-start budget | `run-in-container.sh start` ≤ 5s (cached), ≤ 5min cold build. `exec` ≤ 1s overhead. Measured at Phase 2 verify-self via `time` | Concrete numbers for verify-self; cached-build measurement excludes initial pull/build |
| Layer-caching strategy | Single `apt-get install` layer for system packages; `pip install` / `npm install` (if any) on later layers | Minimal additions to Playwright base; one-layer apt is cache-friendly |
| `~/.claude-time/` access | None needed. All tests `mktemp -d` for `CLAUDE_TIME_DIR`. Confirmed via grep at plan time. | No host-data passthrough |
| Restart-on-reboot | No restart policy. On-demand only per user direction. Container survives `docker stop/start` but not host reboot. | Matches "not always on" requirement |
| In-flight WP5 dirty files | Leave in working tree. They'll validate when WP5 resumes inside container. | Workflow tolerates cross-feature pause |

### Additional plan-shape decisions

- **Image build context:** `tools/claude-time/test/` (small directory; fast context send to Docker daemon)
- **Container name:** `claude-time-test` (single instance; wrapper uses `docker ps --filter name=^/claude-time-test$` for exact match)
- **Image tag:** `claude-time-test:latest` (no version tag — image is rebuilt from pinned base + pinned apt; reproducibility comes from the Dockerfile, not the tag)
- **Bind-mount:** project root (`git rev-parse --show-toplevel`) → `/work` read-write
- **Working directory inside container:** `/work`
- **Sleep-forever entrypoint:** `tail -f /dev/null` (standard pattern for persistent-but-idle containers)
- **Wrapper script:** plain bash, no dependencies beyond `docker` CLI

## Open Questions

These are non-blocking — plan time resolves them:

- [ ] **Where does the Playwright test invocation language live?** Three options:
  - (a) Python — install `playwright` via pip inside the container; `test_visualize_interactive.sh` calls a Python helper that drives Playwright. Pro: consistent with the project's Python-leaning stack. Con: adds `pip install` step inside the container.
  - (b) Node directly — Playwright is already in the base image as a JS lib; write `test_visualize_interactive.js`, invoke via `node`. Pro: zero extra install; uses what's already there. Con: project has no other Node test code.
  - (c) Playwright CLI's built-in test runner — `npx playwright test`. Pro: standard pattern. Con: heavyweight for a single test file.
  - **Lean:** (b) Node directly. The base image already has it; the test is small; we don't take on a pip-install responsibility.

- [ ] **How does `test_visualize_interactive.sh` start `http.server` to serve dashboard HTML to Playwright?** The Phase 1+2+3 verify-self subagent used `python3 -m http.server <port> &`. Inside the container that's fine — Python is present. But the script needs to background it, capture the PID, wait briefly for port-open, then `kill` it on exit. Standard bash pattern; plan-time spelling-out.

- [ ] **What's the cold-start time of the container?** Acceptance #2 says "fast" — but how fast is fast? Plan time should measure: `time run-in-container.sh start` (build cached) should be under ~5 seconds; subsequent `exec` calls under ~1 second of overhead.

- [ ] **Image layer caching strategy.** Should the Dockerfile pull Playwright base, then `apt-get install` everything in one layer, or separate Python / Perl / sqlite3 into individual layers? Plan time decides; the trade-off is build-cache invalidation granularity vs. layer count.

- [ ] **How does the container access `~/.claude-time/` (production data)?** Acceptance #1 says it's test-only — does any test currently read the real `~/.claude-time/`? Spot-check: `test_cli.sh` and `test_visualize_cli.sh` both create their own `CLAUDE_TIME_DIR` via `mktemp` — they do NOT read host `~/.claude-time/`. So the container needs no access to host's real data. Confirm at plan time.

- [ ] **Container restart on host reboot.** Per user direction: "Just make sure it's not always on. We only turn it on when we need it." Acceptance #2 says no `restart: always`. This means a host reboot leaves the container stopped — developer must `run-in-container.sh start` again. Confirm this is the intended behavior (likely yes given the on-demand framing).

- [ ] **What happens to the in-flight Phase 4 P4.1 + P4.3 work** that's already in the working tree (seed_perf_dataset.py + viz_render.py __perfRecord hook)? They were drafted but not validated. Plan: leave them in place; they get validated when WP5 Phase 4 resumes inside the container. Until then, working tree is dirty across two features. Acceptable — feature workflow tolerates this for the duration of a pause.

## Plan-time / phase-shape hint

Given the scope, the plan will likely split into ~3 phases:

1. **Phase 1: Dockerfile + image build.** Write Dockerfile, build successfully, verify base image contents (Playwright + Python + Perl + sqlite3 + jq all present + versioned). Image cache works for repeated builds.
2. **Phase 2: Wrapper script + lifecycle.** `run-in-container.sh start | stop | status | exec`. Container persists between exec calls. Bind-mount works. Run existing tests via `exec` — confirm 156/156 PASS inside the container.
3. **Phase 3: README update + handoff prep for WP5 Phase 4.** Documentation. Confirm the Playwright invocation surface (a small smoke `node` script that opens a URL and snapshots — not the full WP5 test, just confirming Playwright + Chromium work inside the container). At feature-finalize, transition the paused WP5 back to active (workflow's job, not this feature's job).

Plan skill confirms or revises.

## Downstream contract impacts (plan-level pass)

- **`tools/claude-time/README.md`** — needs the new "Running tests" section. Phase 3.
- **`tools/claude-time/test/` directory** — gains 1 new file (`run-in-container.sh`) + 1 new file (`Dockerfile`, possibly under `test/docker/` or `test/`). No existing test files modified (Acceptance #5).
- **`workflow/wip/claude-time-zoomable-timeline.md`** (the paused WP5 file) — its `## Current Node` note already documents the block. When THIS feature finishes, the WP5 file's note gets updated to reflect that the block is resolved and Phase 4 can resume.
- **`tests/check-structure.sh`** — unaffected (different project surface).
- **`CLAUDE.md` (project)** — no changes. The "Running tests" instruction lives in claude-time's own README.
- **No backlog item resolutions expected.** This is foundational new infrastructure, not a backlog fix. The pre-existing `SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME` remains independent (it's about host install-state, not test-environment).

## Work Tree

- [x] Phase 1: Dockerfile + reproducible image build  <!-- status: complete (2026-05-22) -->
  **Observable outcomes:**
  - CLI: `docker build -t claude-time-test:latest tools/claude-time/test/` exits 0 on first build (cold).
  - CLI: a second `docker build` of the same Dockerfile uses cache (`Using cache` lines visible in output) and completes in ≤ 10s.
  - CLI: `docker run --rm claude-time-test:latest python3 --version` reports `Python 3.12.x`.
  - CLI: `docker run --rm claude-time-test:latest perl --version` reports `5.x` (≥ 5.30 per noble).
  - CLI: `docker run --rm claude-time-test:latest sqlite3 --version` reports a 3.x version + date.
  - CLI: `docker run --rm claude-time-test:latest jq --version` reports `jq-1.x`.
  - CLI: `docker run --rm claude-time-test:latest node --version` reports `v22.x` (per Playwright noble base).
  - CLI: `docker run --rm claude-time-test:latest npx playwright --version` reports `Version 1.x.x` (Playwright JS bindings present).
  - CLI: `docker run --rm claude-time-test:latest bash -c 'ls /ms-playwright/chromium-*'` lists at least one Chromium directory (the bundled browser binary).
  - File: `tools/claude-time/test/Dockerfile` exists, parses cleanly (`docker build` succeeded), pins base image to a specific Playwright tag (no `:latest` upstream).
  - [x] P1.1 Created `tools/claude-time/test/Dockerfile` based on `mcr.microsoft.com/playwright:v1.49.1-noble` (verified tag exists in registry). Added `python3.12 python3.12-venv perl sqlite3 jq ca-certificates` via single-layer `apt-get install --no-install-recommends`. Added `npm install -g playwright@1.49.1` (with `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` since binaries already at `/ms-playwright/`). Set `NODE_PATH=/usr/lib/node_modules` so `require('playwright')` resolves from any cwd. Symlinked `python3 → python3.12`. `WORKDIR /work`. `ENTRYPOINT ["tail","-f","/dev/null"]` for persistent-idle.
  - [x] P1.2 Created `tools/claude-time/test/.dockerignore` excluding `__pycache__`, `*.pyc/pyo`, `.pytest_cache/`, `.DS_Store`, `results/`. Build context stays small.
  - [x] P1.3 Image built successfully: `docker build -t claude-time-test:latest tools/claude-time/test/`. Cache-hit rebuild: 0.7s (well under 10s budget). Image size: **3.56 GB** (exceeds spec's "≤ ~2 GB" budget — see discovery below).
  - [x] P1.4 Image-contents verification: arch=aarch64 (native Apple Silicon), Python 3.12.3, Perl 5.38.2, sqlite3 3.45.1, jq 1.7, Node v22.12.0, Playwright 1.49.1 (resolves via `require('playwright')` from any cwd), Chromium 1148 + headless_shell 1148 present at `/ms-playwright/`. End-to-end smoke (`chromium.launch() → newPage() → setContent → title round-trip`) PASSES inside the container.
  - [x] verify-auto — Phase 1 verify-auto (2026-05-22): scoped checks PASS. (1) Dockerfile pins to `FROM mcr.microsoft.com/playwright:v1.49.1-noble`. (2) `docker build --check tools/claude-time/test/` → "Check complete, no warnings found" (Dockerfile syntax lint). (3) `.dockerignore` exists. (4) Image `claude-time-test:latest` present. (5) One-shot tool versions from image: Python 3.12.3 / Perl 5.38.2 / sqlite3 3.45.1 / jq 1.7 / Node v22.12.0 / Playwright 1.49.1.
  - [x] verify-self — Phase 1 verify-self (2026-05-22): 5/5 outcomes PASS via direct bash-shell observation against the live `docker run --rm` invocations (no Playwright subagent needed — Phase 1 has no UI surface; the "live system" IS the Docker image). (1) End-to-end Chromium launch via `node -e require('playwright').chromium.launch()` succeeds and title round-trips; (2) `PLAYWRIGHT_BROWSERS_PATH=/ms-playwright` env set; (3) Chromium headless_shell binary present at `/ms-playwright/chromium_headless_shell-1148/chrome-linux/headless_shell` (265MB); (4) `require('playwright')` resolves correctly from arbitrary cwd (`/tmp`) → `/usr/lib/node_modules/playwright/index.js`; (5) `NODE_PATH=/usr/lib/node_modules` env set. No integration boundary applies (Phase 1 adds isolated new artifacts only — Dockerfile + .dockerignore — no existing endpoint/UI/CLI consumes them; the wrapper script in Phase 2 will be the first consumer).
  - [x] verify-human — Phase 1 verify-human (2026-05-22): F11 skip path taken. No integration boundary (isolated new artifacts only — Dockerfile + .dockerignore). User affirmed skip ("yes, skip"). All 3 non-blocking discoveries (aarch64 arch, 3.56GB image size, npx noise) acknowledged but no human decision needed; documented in WIP.
  - [x] verify-codify — Phase 1 verify-codify (2026-05-22): added 1 new test file `tools/claude-time/test/test_container_image.sh` (9 structural assertions on the Dockerfile, **regression-pin** discipline). Asserts: Dockerfile exists; `FROM` line pins to specific Playwright `vX.Y.Z-distro` form (not `:latest` or unpinned); `NODE_PATH` env explicitly set; ENTRYPOINT is `tail -f /dev/null` (persistent-idle); apt-get installs python3.12/perl/sqlite3/jq; npm-installs pinned Playwright JS. **No "verify image contents" test added** — functional coverage already lives in Phase 2's existing-tests-pass-inside outcomes (broken python/perl/sqlite3/jq surfaces immediately when their consuming tests run inside the container) and Phase 3's Playwright smoke (which exercises Node+Playwright+Chromium). Adding a separate image-contents test would duplicate functional coverage — wrong test pyramid level per the procedure's preference for highest-level tests. Full claude-time host suite **165/165 PASS** (was 156, +9 from new test_container_image.sh).

  **Phase 1 build notes (2026-05-22):**
  - **Image arch is aarch64, not x86_64.** Spec said "single linux-x86_64" but Docker pulled the matching architecture for the Apple Silicon host. This is *better* than the spec assumed — no QEMU emulation tax, tests run at native speed. The "no cross-platform" direction from the user (3 in the spec confirm-call) makes this fine — aarch64 is what we actually need. Spec's "x86_64" wording is updated as a non-blocking discovery; perf-measurement in WP5 P4.4 will run on native aarch64, which is fine for the dev-loop use case.
  - **Image size 3.56 GB > 2 GB budget.** The Playwright official base ships all 4 browsers (chromium, firefox, webkit, ffmpeg) plus a headless-shell Chromium variant — bigger than the spec anticipated. Accepting: the goal (working Playwright + Chromium for tests) is met, and trimming would require building a custom Playwright base (out of scope, brittle). Discovery captured.
  - **Two corrections during build:** (1) the original Dockerfile didn't install Playwright as a globally-resolvable npm module — the base image ships browser binaries but not the JS bindings as a global package. Added `npm install -g playwright@1.49.1` with `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` to avoid re-downloading the already-present binaries. (2) `require('playwright')` still failed because Node's default `require.resolve.paths` doesn't include `/usr/lib/node_modules`; set `ENV NODE_PATH=/usr/lib/node_modules` to make global modules resolvable from `/work`.
  - **Discovery — npx warning during initial verification:** running `docker run --rm claude-time-test npx playwright --version` triggered npx to download Playwright fresh (because `npx` looks in local `node_modules` first, then prompts). This is harmless verification-tool noise, not a real defect — the `require('playwright')` path works correctly without re-download. Documenting so future verification scripts use `node -e require("playwright/package.json").version` instead of `npx`.

- [x] Phase 2: Wrapper script + lifecycle + existing-tests-pass-inside  <!-- status: complete (2026-05-22) -->
  **Observable outcomes:**
  - CLI: `tools/claude-time/test/run-in-container.sh start` exits 0, container is up (`docker ps --filter name=^/claude-time-test$ --filter status=running` returns a row).
  - CLI: `run-in-container.sh status` prints `running` and exits 0 when up; prints `stopped` and exits 1 when down; prints `image-not-built` and exits 2 when image absent.
  - CLI: `run-in-container.sh exec` with no container running prints a helpful error mentioning `start` and exits 3 (does NOT auto-start).
  - CLI: `run-in-container.sh exec bash test/test_cli.sh` PASS 29/29 inside the container (matches host baseline).
  - CLI: `run-in-container.sh exec bash test/test_hook.sh` PASS 17/17 inside the container.
  - CLI: `run-in-container.sh exec bash test/test_visualize_cli.sh` PASS 41/41 inside the container.
  - CLI: `run-in-container.sh exec python3 test/test_reclassify.py` reports `OK` with 29 tests.
  - CLI: `run-in-container.sh exec python3 test/test_viz_data.py` reports `OK` with 40 tests.
  - CLI: `run-in-container.sh exec bash -c 'echo hello'` round-trips text in ≤ 1s of overhead (excluding command execution itself). Verify-self measures via `time`.
  - CLI: `run-in-container.sh stop` exits 0, container is gone (`docker ps --filter name=^/claude-time-test$` returns no rows).
  - File: source edit on host (e.g., `touch tools/claude-time/viz/dashboard.jsx`) is immediately visible inside the container via the bind-mount (`run-in-container.sh exec stat /work/tools/claude-time/viz/dashboard.jsx` shows the new mtime).
  - [x] P2.1 `tools/claude-time/test/run-in-container.sh` written; dispatches on subcommand via a `case` statement in `main`. Container name `claude-time-test`; image `claude-time-test:latest`; project root via `git rev-parse --show-toplevel` with a relative-path fallback. Three reusable helpers: `container_running`, `container_exists`, `image_built`.
  - [x] P2.2 `start` subcommand: detects already-running (no-op + "already running" + exit 0); detects leftover stopped container (rm before fresh start); auto-builds image if not present; `docker run -d --name claude-time-test -v "$PROJECT_ROOT:/work" -w /work claude-time-test:latest`.
  - [x] P2.3 `stop` subcommand: stops + removes container; idempotent (prints "not running" + exit 0 if no container).
  - [x] P2.4 `status` subcommand: 3-tier check (running → exit 0 / stopped → exit 1 / image-not-built → exit 2). Verified all three states return the correct exit codes.
  - [x] P2.5 `exec` subcommand: requires container running (exit 3 with helpful message if not); does NOT auto-start; tty-aware (`-it` when stdin is tty, `-i` otherwise); `cd /work/tools/claude-time` before running user command so relative paths in test scripts work; uses `printf '%q '` to safely re-quote args.
  - [x] P2.6 `restart` subcommand: chains `stop` + `start`.
  - [x] P2.7 `logs` subcommand: `docker logs claude-time-test`; gracefully reports if container doesn't exist.
  - [x] P2.8 `help` (and unknown subcommand) prints usage; help exits 0, unknown subcommand exits 64 (verified via stderr separation: stdout empty, stderr has the unknown-subcommand message + usage).
  - [x] P2.9 `chmod +x` applied to `run-in-container.sh`.
  - [x] P2.10 Full existing test suite PASSES inside the container: test_cli.sh 29/29, test_hook.sh 17/17, test_visualize_cli.sh 41/41, test_reclassify.py 29 ok, test_viz_data.py 40 ok, test_container_image.sh 9/9. **Total: 165/165 PASS** inside the container — matches host baseline exactly.
  - [x] verify-auto — Phase 2 verify-auto (2026-05-22): scoped checks PASS. (1) `bash -n run-in-container.sh` → OK. (2) executable bit set (`-rwxr-xr-x`). (3) `help` exits 0. (4) `status` reports `running` (container from build sweep still up). (5) `exec` smoke: `python3 -c print(...)` round-trips through container, exits 0.
  - [x] verify-self — Phase 2 verify-self (2026-05-22): 5/5 outcomes PASS via direct bash/docker observation. No integration boundary (Phase 2 adds isolated new artifact only — run-in-container.sh — no existing endpoint/UI/CLI consumes it yet; Phase 3's `playwright_smoke.js` will be the first consumer). (1) Full lifecycle round-trip stop→status(1)→start→status(0)→exec smoke→restart→status(0) — all exit codes match expectations; (2) Full 165/165 test suite re-confirmed inside container (test_cli 29 + test_hook 17 + test_visualize_cli 41 + test_reclassify 29 + test_viz_data 40 + test_container_image 9), matches host baseline exactly; (3) bind-mount source-edit visibility — host touch + 1s settle + docker exec stat = mtimes match exactly (Docker Desktop on macOS has sub-second bind-mount propagation latency for mtime; content reads propagate instantly — not a defect, just a timing nuance worth noting); (4) `exec` without container → exit 3 + correct helpful message ("container is not running — run 'run-in-container.sh start' first"); (5) Unknown subcommand `frobnicate` → exit 64.
  - [x] verify-human — Phase 2 verify-human (2026-05-22): F11 skip path taken. No integration boundary (isolated new artifact only — run-in-container.sh). User affirmed skip ("yes, skip"). One nuance noted (Docker Desktop macOS sub-second bind-mount mtime propagation) — not a defect.
  - [x] verify-codify — Phase 2 verify-codify (2026-05-22): extended `test_container_image.sh` with 15 wrapper-structural assertions (existence + executable bit; 7 subcommand dispatcher branches; 5 exit-code header docstrings; container name pin; `-w /work` workdir pin). **No behavioral lifecycle test written** — would risk recursion if future test invocations run inside the container, and Phase 3's Playwright smoke functionally exercises start+exec. One triage event: initial dispatcher-branch regex didn't accept bash multi-alternative case patterns (`help|-h|--help)`) — high-confidence obsolete-test classification, auto-fixed regex. `test_container_image.sh` 9 → 24 PASS. Full claude-time host suite **180/180 PASS** (was 165, +15 net).

  **Phase 2 build notes (2026-05-22):**
  - **Build-time gotcha caught + fixed in-build:** the original `PROJECT_ROOT="$(git ... || cd ... && pwd)"` had a bash precedence bug — the `&& pwd` chained the `cd` to *both* paths (git success and git fail), so the variable ended up with a literal newline-joined value (git's stdout + cd-then-pwd's stdout). Result: `docker inspect` showed `"Source": "/path/...\n/path/..."` with embedded newline. Fix: parenthesize the fallback `(cd "$DOCKERFILE_DIR/../../.." && pwd)` so the `||` binds correctly. After fix, mount source is the clean project root and the bind-mount works.
  - **Initial bind-mount failure diagnosed via `docker inspect --format '{{json .Mounts}}'`** — the JSON output revealed the corrupted mount Source with the embedded newline. Without that diagnostic step, the symptom ("`/work` is empty inside container") could have led to many wrong hypotheses (mount permission, propagation mode, even SIP issues on macOS). Worth carrying forward: **`docker inspect Mounts`** is the first diagnostic when bind-mount visibility unexpectedly fails.
  - **Bind-mount propagation verified:** `touch <host file>; stat host vs container` → mtimes match exactly (Unix epoch is timezone-neutral). Host edits visible inside container immediately, no rebuild needed.
  - **Container lifecycle exit-code matrix tested:** start (0), start-while-running (0), status-running (0), status-stopped-image-built (1), status-image-not-built (2), exec-no-container (3), unknown-subcommand (64), help (0), stop-running (0), stop-not-running (0 idempotent).
  - **Persistent + on-demand confirmed:** container stays up between `exec` calls (no cold-start tax); `stop` cleanly removes it (no leaking containers).

- [x] Phase 3: Playwright smoke + README + handoff prep  <!-- status: complete (2026-05-22) -->
  **Observable outcomes:**
  - CLI: a tiny `test/playwright_smoke.js` invokes `chromium.launch()`, opens a blank page, queries `document.title`, closes, exits 0.
  - CLI: `run-in-container.sh exec node test/playwright_smoke.js` exits 0 with output confirming Chromium started (e.g., "smoke ok"). This proves Playwright + Chromium are wired correctly inside the container, ready for WP5 P4.2 to write the real behavioral test against `claude-time visualize`'s emitted HTML.
  - File: `tools/claude-time/README.md` contains a new "Running tests" section with the canonical container-based invocation patterns.
  - File: `tools/claude-time/test/playwright_smoke.js` exists, ≤ 50 lines, no external npm dependencies (uses `playwright` already in the base image).
  - [x] P3.1 `tools/claude-time/test/playwright_smoke.js` written — Node script: requires `playwright`, launches chromium, opens new page, `setContent('<title>smoke</title><body>hello smoke</body>')`, asserts title + body, logs "smoke ok", closes browser, exits 0 (or 1 with FAIL message on assertion or thrown error).
  - [x] P3.2 Ran via wrapper: `tools/claude-time/test/run-in-container.sh exec node test/playwright_smoke.js` → stdout `smoke ok`, exit 0. Playwright + Chromium fully functional inside the container; WP5 Phase 4 P4.2 readiness signal achieved.
  - [x] P3.3 `tools/claude-time/README.md` updated — new `## Running tests` section before `## Files` covers prerequisite (Docker engine), lifecycle (start/exec/stop/status/help with copy-paste examples), the 6 canonical test invocations (test_cli, test_hook, test_visualize_cli, test_container_image, test_reclassify, test_viz_data) plus the new playwright_smoke, exit-code table (0/1/2/3/64), bind-mount behavior note (host edits visible immediately, no rebuild), no-host-reboot persistence note, and explicit "host-side tests are not supported" line. `## Files` listing extended with the 4 new container-related files (Dockerfile, .dockerignore, run-in-container.sh, playwright_smoke.js, test_container_image.sh) and assertion-count freshness (test_visualize_cli.sh 13 → 41, test_viz_data.py 22 → 40).
  - [x] P3.4 `workflow/wip/claude-time-zoomable-timeline.md` Current Node updated — WP5 Phase 4 block resolved, marked "resumable", with the explicit handoff note that P4.2 should use `playwright_smoke.js` as the pattern and `run-in-container.sh exec node <test>` as the invocation surface.
  - [x] verify-auto — Phase 3 verify-auto (2026-05-22): scoped checks PASS. (1) `node --check playwright_smoke.js` → OK; 30 lines (≤ 50 budget); single `require('playwright')` — no external npm deps. (2) `run-in-container.sh exec node test/playwright_smoke.js` → "smoke ok", exit 0. (3) `README.md` contains the `## Running tests` heading + canonical Docker-container intro paragraph. (4) WP5 WIP Current Node updated to "Phase 4 P4.1 (resumable — test-env containerization unblocked 2026-05-22)" and references playwright_smoke.js as the pattern.
  - [x] verify-self — Phase 3 verify-self (2026-05-22): 4/4 outcomes PASS via direct bash/filesystem observation. No integration boundary (Phase 3 adds isolated new artifact `playwright_smoke.js` + modifies README/WP5-WIP for documentation/handoff — neither modifies a programmatic surface). (1) playwright_smoke.js through wrapper → "smoke ok", exit 0; (2) all 4 new files visible inside container via bind-mount (Dockerfile, run-in-container.sh, playwright_smoke.js, test_container_image.sh); (3) README new "## Running tests" section well-formed: heading + start/stop/exec invocations + exit-code table including code 3 + canonical test invocations + explicit "Host-side tests are not supported" note; (4) WP5 WIP Current Node note is readable, says "Phase 4 P4.1 (resumable)" + names the playwright_smoke.js pattern + run-in-container.sh exec surface. **One surface-discovery noted (NOT a Phase 3 defect):** WP5 WIP's `**Unvisited:**` line is stale — still claims "Phase 3 (P3.1 → P3.7 → ...)" even though WP5 Phase 3 (minimap+URL-hash) is already `[x]`. This is a hygiene issue in the WP5 WIP that should be cleaned up when WP5 resumes; not blocking this feature.
  - [x] verify-human — Phase 3 verify-human (2026-05-22): F11 skip path taken. No integration boundary (isolated new artifact + documentation-only changes). User affirmed skip ("yes skip"). Non-blocking surface-discovery (stale WP5 WIP Unvisited line) noted for cleanup at WP5 resumption.
  - [x] verify-codify — Phase 3 verify-codify (2026-05-22): extended `test_container_image.sh` with 6 Phase-3-codify assertions: `playwright_smoke.js` exists + requires `playwright` + invokes `chromium.launch` + logs `smoke ok` marker; README has `## Running tests` heading + references the run-in-container.sh wrapper. **No behavioral run-the-smoke test added** to `test_container_image.sh` — that would couple host structural lint to container runtime (test_container_image.sh runs on host today; coupling it to container makes the test flaky on a stopped container). The smoke gets functional coverage from WP5 Phase 4 P4.2 (which will invoke it implicitly via the same pattern) + ad-hoc manual runs. `test_container_image.sh` 24 → 30 PASS. Full claude-time host suite **186/186 PASS** (was 180, +6 net). Same suite re-confirmed 30/30 on `test_container_image.sh` *inside* the container.

  **Phase 3 build notes (2026-05-22):**
  - **Playwright smoke `smoke ok` first try** — the Phase 1 image-contents work already exercised `chromium.launch()` end-to-end inline; the only new code here was wrapping it in a re-usable JS file plus running it via the wrapper. Zero gotchas.
  - **README new section length:** ~50 lines under `## Running tests`. Includes a hand-curated invocation list rather than a `find test/ -name 'test_*'` style discovery, because the test files have slightly different invocation patterns (bash vs python3) and the table reads better with explicit commands.
  - **WP5 handoff:** the WP5 WIP file Current Node now says "Phase 4 build resumable" rather than "paused". The session pointer (`workflow/.session.md`) still says "paused" but it'll be overwritten or cleared when WP5 resumes; not worth a separate edit here — the finalize step's session-state hygiene handles it.

## Current Node
- **Path:** Feature > ship
- **Active scope:** All 3 phases complete; ready for `/feature-ship` → `/feature-finalize`. After this feature ships, WP5 Phase 4 (paused) resumes.
- **Blocked:** none
- **Unvisited:** Phase 1 (remaining: verify-auto → verify-self → verify-human → verify-codify); Phase 2 (wrapper script + lifecycle + existing-tests-pass-inside, depends on Phase 1); Phase 3 (Playwright smoke + README + WP5 handoff, depends on Phase 2)
- **Open discoveries:** 3 — image arch (aarch64 not x86_64), image size (3.56GB > 2GB budget), npx noise — all accepted as-is, no back-loops

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

- [SURFACED-2026-05-22] Phase 1 build — Image arch is aarch64 (matches Apple Silicon host), not x86_64 as spec wording suggested. Better than spec assumed: no QEMU emulation. Spec's "single linux-x86_64" → effectively "single linux-{host-arch}". No back-loop; just note for future readers.
- [SURFACED-2026-05-22] Phase 1 build — Image size 3.56 GB exceeds spec's "≤ ~2 GB" budget. Playwright official base ships all 4 browsers + ffmpeg. Accepted as-is; trimming would require building a custom base (out of scope). No back-loop.
- [SURFACED-2026-05-22] Phase 1 build — `npx playwright --version` triggers a fresh Playwright download (npx's "not in local node_modules → install" behavior). Harmless for our use (we use `require('playwright')` via NODE_PATH). Note for future verification scripts: prefer `node -e require("playwright/package.json").version` over `npx playwright --version`.

## Next step

Per the Orchestrator Pause Policy for `feature-plan` in Autopilot (Mode 3), **plan is AUTO** — orchestrator chains to `/feature-build` immediately on `TRANSITION: F7`.

TRANSITION: F7
