#!/usr/bin/env bash
# claude-time test-container lifecycle wrapper.
#
# Manages a persistent-but-on-demand Docker container for running the
# claude-time test suite + WP5 Phase 4 Playwright behavioral test without
# installing Node/Playwright/Chromium on the host OS.
#
# Subcommands:
#   start         Build image if missing, then start the container detached.
#   stop          Stop + remove the container (idempotent).
#   restart       stop + start.
#   status        Print state: running | stopped | image-built | image-not-built.
#                 Exit codes: 0=running, 1=stopped, 2=image-not-built.
#   exec <cmd>    Run <cmd> inside the container (requires container running;
#                 does NOT auto-start). Working directory: /work/tools/claude-time/.
#                 Exit 3 if container is not running.
#   logs          Stream `docker logs` of the container.
#   help          Print usage.
#
# Exit code conventions:
#   0  success
#   1  stopped (only meaningful for `status`)
#   2  image not built (only meaningful for `status`)
#   3  exec attempted while container not running
#   64 unknown subcommand
#   *  forwarded from `docker exec` for `exec` subcommand

set -u

IMAGE="claude-time-test:latest"
CONTAINER="claude-time-test"
DOCKERFILE_DIR="$(cd "$(dirname "$0")" && pwd)"
# Compute project root. Prefer git; fall back to relative-path derivation.
# Parenthesize the fallback so the || doesn't accidentally chain into it.
PROJECT_ROOT="$(git -C "$DOCKERFILE_DIR" rev-parse --show-toplevel 2>/dev/null \
    || (cd "$DOCKERFILE_DIR/../../.." && pwd))"

# Match container name exactly via ^/name$ regex (avoids accidental substring
# matches with other containers).
container_running() {
    [ -n "$(docker ps --filter "name=^/${CONTAINER}$" --filter status=running -q 2>/dev/null)" ]
}
container_exists() {
    [ -n "$(docker ps -a --filter "name=^/${CONTAINER}$" -q 2>/dev/null)" ]
}
image_built() {
    [ -n "$(docker images "$IMAGE" -q 2>/dev/null)" ]
}

cmd_start() {
    if container_running; then
        echo "already running ($CONTAINER)"
        return 0
    fi
    if container_exists; then
        # Stopped container left over from a previous session — remove it
        # cleanly before starting fresh.
        docker rm "$CONTAINER" >/dev/null 2>&1
    fi
    if ! image_built; then
        echo "building image $IMAGE..."
        docker build -t "$IMAGE" "$DOCKERFILE_DIR" || return $?
    fi
    docker run -d \
        --name "$CONTAINER" \
        -v "$PROJECT_ROOT:/work" \
        -w /work \
        "$IMAGE" >/dev/null
    echo "started ($CONTAINER)"
}

cmd_stop() {
    if container_exists; then
        docker stop "$CONTAINER" >/dev/null 2>&1
        docker rm "$CONTAINER" >/dev/null 2>&1
        echo "stopped ($CONTAINER)"
    else
        # Idempotent: not running is success.
        echo "not running"
    fi
    return 0
}

cmd_restart() {
    cmd_stop
    cmd_start
}

cmd_status() {
    if container_running; then
        echo "running"
        return 0
    elif container_exists; then
        echo "stopped (container exists but not running)"
        return 1
    elif image_built; then
        echo "stopped (image built, no container)"
        return 1
    else
        echo "image-not-built"
        return 2
    fi
}

cmd_exec() {
    if [ $# -lt 1 ]; then
        echo "usage: $(basename "$0") exec <command...>" >&2
        return 64
    fi
    if ! container_running; then
        echo "container '$CONTAINER' is not running — run '$(basename "$0") start' first" >&2
        return 3
    fi
    # Use -it only when stdin is a tty (allows CI/non-tty invocations to work).
    local docker_flags="-i"
    if [ -t 0 ]; then
        docker_flags="-it"
    fi
    # cd into tools/claude-time/ so test scripts using relative $(dirname "$0")
    # paths resolve the same way as on the host. Quote-preserve the joined
    # args via printf %q so subshell expansion doesn't double-process them.
    local joined
    joined="$(printf '%q ' "$@")"
    docker exec $docker_flags "$CONTAINER" bash -c "cd /work/tools/claude-time && $joined"
}

cmd_logs() {
    if ! container_exists; then
        echo "container '$CONTAINER' does not exist" >&2
        return 1
    fi
    docker logs "$CONTAINER"
}

cmd_help() {
    cat <<EOF
Usage: $(basename "$0") <subcommand> [args...]

Subcommands:
  start         Build image if missing, then start the container.
  stop          Stop + remove the container (idempotent).
  restart       stop + start.
  status        Print state. Exit codes: 0=running, 1=stopped, 2=image-not-built.
  exec <cmd>    Run <cmd> inside the container (working dir: /work/tools/claude-time).
                Requires container running (exit 3 if not). Does NOT auto-start.
  logs          Stream container logs.
  help          This message.

Examples:
  $(basename "$0") start
  $(basename "$0") exec bash test/test_cli.sh
  $(basename "$0") exec python3 test/test_viz_data.py
  $(basename "$0") stop
EOF
}

main() {
    if [ $# -lt 1 ]; then
        cmd_help
        return 0
    fi
    local sub="$1"
    shift
    case "$sub" in
        start)      cmd_start "$@" ;;
        stop)       cmd_stop "$@" ;;
        restart)    cmd_restart "$@" ;;
        status)     cmd_status "$@" ;;
        exec)       cmd_exec "$@" ;;
        logs)       cmd_logs "$@" ;;
        help|-h|--help) cmd_help ;;
        *)
            echo "unknown subcommand: $sub" >&2
            cmd_help >&2
            return 64
            ;;
    esac
}

main "$@"
