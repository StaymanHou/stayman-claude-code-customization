#!/usr/bin/env bash
# Structural regression-pin for the claude-time test-environment image.
#
# Codifies Phase 1 of claude-time-test-containerization: the Dockerfile must
# pin its base image to a specific Playwright version tag (not :latest, not
# an unpinned form). Without this pin, the image would silently track
# upstream and break reproducibility — the failure mode would only surface
# at the next `docker pull` of an unsuspecting developer.
#
# Run on the host (no container needed — this is static lint of the
# Dockerfile). Exits 0 on pass.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
DOCKERFILE="$REPO_ROOT/tools/claude-time/test/Dockerfile"

pass=0
fail=0
check() {
    local name="$1"
    local result="$2"
    local detail="${3:-}"
    if [ "$result" = "pass" ]; then
        echo "  [PASS] $name"
        pass=$((pass + 1))
    else
        echo "  [FAIL] $name${detail:+ — $detail}"
        fail=$((fail + 1))
    fi
}

echo "claude-time test-container image structural tests"
echo "  Dockerfile: $DOCKERFILE"
echo

# ── 1. Dockerfile exists ───────────────────────────────────────────────
if [ -f "$DOCKERFILE" ]; then
    check "Dockerfile exists at expected path" pass
else
    check "Dockerfile exists" fail "not found"
    exit 1
fi

# ── 2. FROM line pins a specific Playwright tag ────────────────────────
# Acceptable: FROM mcr.microsoft.com/playwright:v<X>.<Y>.<Z>-<distro>
# Rejected: :latest, missing tag, or any non-version-pinned form.
FROM_LINE=$(grep -E "^FROM " "$DOCKERFILE" | head -1)
if echo "$FROM_LINE" | grep -qE "^FROM mcr\.microsoft\.com/playwright:v[0-9]+\.[0-9]+\.[0-9]+-[a-z]+$"; then
    check "FROM pins a specific Playwright version tag (vX.Y.Z-distro form)" pass
else
    check "FROM pins a specific Playwright version tag" fail "FROM line is '$FROM_LINE' — expected vX.Y.Z-distro form"
fi

# ── 3. NODE_PATH is set explicitly (needed for require('playwright') from /work) ──
if grep -qE "^ENV NODE_PATH=" "$DOCKERFILE"; then
    check "NODE_PATH explicitly set in Dockerfile (require resolution from any cwd)" pass
else
    check "NODE_PATH set" fail "no 'ENV NODE_PATH=' in Dockerfile"
fi

# ── 4. ENTRYPOINT is tail -f /dev/null (persistent-idle for `docker exec`) ──
if grep -qE 'ENTRYPOINT.*tail.*-f.*/dev/null' "$DOCKERFILE"; then
    check "ENTRYPOINT is tail -f /dev/null (persistent-idle for exec)" pass
else
    check "ENTRYPOINT persistent-idle" fail "no tail -f /dev/null ENTRYPOINT"
fi

# ── 5. Required tools installed (apt-get layer mentions them) ──────────
for tool in python3.12 perl sqlite3 jq; do
    if grep -qE "[[:space:]]$tool([[:space:]]|\\\\)" "$DOCKERFILE"; then
        check "Dockerfile installs $tool" pass
    else
        check "Dockerfile installs $tool" fail "no '$tool' in apt-get install line"
    fi
done

# ── 6. Playwright JS bindings installed at build time ──────────────────
if grep -qE "npm install -g playwright@" "$DOCKERFILE"; then
    check "Playwright JS bindings installed at build time (pinned npm install)" pass
else
    check "Playwright JS bindings installed" fail "no 'npm install -g playwright@<ver>' in Dockerfile"
fi

# ── Wrapper script structural checks (Phase 2 codify) ─────────────────
# Codifies the run-in-container.sh wrapper's contract: exists, executable,
# dispatches on the documented subcommand set, encodes the canonical exit
# code convention. Behavioral lifecycle (start/exec/stop) is NOT codified
# here — covered functionally by Phase 3's Playwright smoke + future test
# invocations that USE the wrapper to run themselves inside the container.

WRAPPER="$REPO_ROOT/tools/claude-time/test/run-in-container.sh"

if [ -f "$WRAPPER" ] && [ -x "$WRAPPER" ]; then
    check "run-in-container.sh exists + executable" pass
else
    check "run-in-container.sh exists + executable" fail "missing or not executable"
fi

# Subcommand dispatcher — assert each documented subcommand is wired.
# Pattern accepts either a standalone case branch (e.g. `start)`) or an
# alternative-pattern case (e.g. `help|-h|--help)`), since bash case
# statements support both forms equivalently.
for sub in start stop restart status exec logs help; do
    if grep -qE "^[[:space:]]*(${sub}\\)|${sub}\\|)" "$WRAPPER"; then
        check "wrapper dispatcher recognizes '$sub' subcommand" pass
    else
        check "wrapper dispatcher recognizes '$sub' subcommand" fail "no case branch found"
    fi
done

# Exit-code convention — assert the canonical codes are mentioned in the
# header docstring. Cheap proxy for "the script author thought about this."
for code_grep in "0  success" "1  stopped" "2  image not built" "3  exec attempted while container not running" "64 unknown subcommand"; do
    if grep -qF "$code_grep" "$WRAPPER"; then
        check "wrapper header documents exit code: '$code_grep'" pass
    else
        check "wrapper header documents exit code: '$code_grep'" fail "not found in header"
    fi
done

# Container name pin — if someone changes this, downstream tests that
# inspect the container by name (or future test_run_in_container behavioral
# tests) break silently. Pin it as a regression guard.
if grep -qE '^CONTAINER="claude-time-test"' "$WRAPPER"; then
    check "wrapper pins container name to 'claude-time-test'" pass
else
    check "wrapper pins container name" fail "expected CONTAINER=\"claude-time-test\""
fi

# Bind-mount target — /work is the documented mount path; if changed,
# everything that paths into /work/tools/claude-time/ breaks.
if grep -qE '\-w /work' "$WRAPPER"; then
    check "wrapper sets working directory to /work" pass
else
    check "wrapper sets WORKDIR /work" fail "no '-w /work' in docker run"
fi

# ── Playwright smoke script structural checks (Phase 3 codify) ─────────
# Codifies the Playwright readiness signal that WP5 Phase 4 P4.2 will rely
# on. Behavioral coverage comes from running the smoke via the wrapper +
# downstream Phase-4 behavioral tests; the structural pin guards against
# silent removal or shape-drift of the readiness script itself.

PLAYWRIGHT_SMOKE="$REPO_ROOT/tools/claude-time/test/playwright_smoke.js"

if [ -f "$PLAYWRIGHT_SMOKE" ]; then
    check "playwright_smoke.js exists" pass
else
    check "playwright_smoke.js exists" fail "not found"
fi

if grep -qE "require\(['\"]playwright['\"]\)" "$PLAYWRIGHT_SMOKE"; then
    check "playwright_smoke.js requires the playwright npm module" pass
else
    check "playwright_smoke.js requires playwright" fail "no require('playwright') in smoke script"
fi

if grep -qE 'chromium\.launch\(' "$PLAYWRIGHT_SMOKE"; then
    check "playwright_smoke.js launches chromium" pass
else
    check "playwright_smoke.js launches chromium" fail "no chromium.launch() call"
fi

if grep -qF 'smoke ok' "$PLAYWRIGHT_SMOKE"; then
    check "playwright_smoke.js logs canonical 'smoke ok' marker" pass
else
    check "playwright_smoke.js canonical marker" fail "no 'smoke ok' string in smoke script"
fi

# ── WP5 Phase 4 deliverables (behavioral test + perf seeder + hooks) ──
# Structural pins on the Phase 4 infrastructure. Behavioral correctness is
# functionally covered by test_visualize_interactive.sh itself (10 PASS at
# the WP5 Phase 4 build); these assertions guard against silent deletion
# or shape-drift of the infrastructure files.

INTERACTIVE_TEST_JS="$REPO_ROOT/tools/claude-time/test/test_visualize_interactive.js"
INTERACTIVE_TEST_SH="$REPO_ROOT/tools/claude-time/test/test_visualize_interactive.sh"
PERF_SEEDER="$REPO_ROOT/tools/claude-time/test/seed_perf_dataset.py"

if [ -f "$INTERACTIVE_TEST_JS" ]; then
    check "test_visualize_interactive.js exists" pass
else
    check "test_visualize_interactive.js exists" fail "not found"
fi

if grep -qE "require\(['\"]playwright['\"]\)" "$INTERACTIVE_TEST_JS"; then
    check "test_visualize_interactive.js requires playwright" pass
else
    check "test_visualize_interactive.js requires playwright" fail "no require('playwright')"
fi

if grep -qE 'chromium\.launch\(' "$INTERACTIVE_TEST_JS"; then
    check "test_visualize_interactive.js launches chromium" pass
else
    check "test_visualize_interactive.js launches chromium" fail "no chromium.launch()"
fi

if [ -f "$INTERACTIVE_TEST_SH" ] && [ -x "$INTERACTIVE_TEST_SH" ]; then
    check "test_visualize_interactive.sh exists + executable" pass
else
    check "test_visualize_interactive.sh exists + executable" fail "missing or not executable"
fi

# Wrapper guards against host invocation — looks for /ms-playwright marker.
if grep -qF '/ms-playwright' "$INTERACTIVE_TEST_SH"; then
    check "test_visualize_interactive.sh enforces container-only invocation" pass
else
    check "test_visualize_interactive.sh container-only guard" fail "no /ms-playwright check in wrapper"
fi

if [ -f "$PERF_SEEDER" ]; then
    check "seed_perf_dataset.py exists" pass
else
    check "seed_perf_dataset.py exists" fail "not found"
fi

# Seeder must use a session-id format that doesn't collide at viz_data.py's
# [:8] truncation. Anti-pattern guard: reject `f"perf-{d.isoformat()}-"`
# format (the original colliding shape). Accept the post-fix counter-prefix
# format which encodes `f"p{counter_hex}-"`.
if grep -qE 'f"p\{counter_hex' "$PERF_SEEDER"; then
    check "seed_perf_dataset.py uses 8-char-unique session-id format (no [:8] truncation collision)" pass
else
    check "seed_perf_dataset.py session-id collision guard" fail "expected 'p{counter_hex}-' format in seeder"
fi

# Perf hooks must be plumbed in viz_render.py.
VIZ_RENDER="$REPO_ROOT/tools/claude-time/viz_render.py"
if grep -qF '__dashboardViewport' "$VIZ_RENDER"; then
    check "viz_render.py exposes window.__dashboardViewport for Playwright introspection" pass
else
    check "viz_render.py exposes window.__dashboardViewport" fail "not found"
fi

if grep -qF '__perfRecord' "$VIZ_RENDER" || grep -qF '__perfResult' "$VIZ_RENDER"; then
    check "viz_render.py wires __perfRecord rAF sampler (gated by ?perf=1)" pass
else
    check "viz_render.py wires __perfRecord" fail "no __perfRecord/__perfResult ref"
fi

# ── README has the canonical "Running tests" section (Phase 3 codify) ──
# README is human documentation, not a programmatic surface. The structural
# pin catches accidental removal of the new section (e.g., a future README
# rewrite that drops it). Not asserting prose content — only that the
# section header survives.

CT_README="$REPO_ROOT/tools/claude-time/README.md"

if grep -qE '^## Running tests' "$CT_README"; then
    check "README contains '## Running tests' section" pass
else
    check "README 'Running tests' section" fail "missing heading in $CT_README"
fi

if grep -qF 'run-in-container.sh' "$CT_README"; then
    check "README references the run-in-container.sh wrapper" pass
else
    check "README references run-in-container.sh" fail "no mention of the wrapper in README"
fi

# ── Summary ────────────────────────────────────────────────────────────
echo
echo "=== claude-time container-image structural test summary ==="
echo "PASS: $pass | FAIL: $fail"
if [ $fail -eq 0 ]; then
    echo "All container-image structural assertions hold."
    exit 0
else
    exit 1
fi
