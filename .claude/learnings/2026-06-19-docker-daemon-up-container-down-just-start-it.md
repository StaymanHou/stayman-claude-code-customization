---
name: docker-daemon-up-container-down-just-start-it
description: When the Docker daemon is reachable but the project's containers are down, start the container(s) yourself — do NOT pause and ask. The hard-blocker only applies when the daemon itself is unreachable.
scope: global
metadata:
  type: feedback
  surfaced: 2026-06-19
  project: replicator-1-0 (but the rule is global)
---

# Docker: daemon up + container down → start it yourself, don't pause

**Expected behavior:**

- **Daemon UNREACHABLE** (`docker ps` errors / can't connect): this is the
  hard-blocker. STOP and ask the user to start Docker. Never fall back to the
  host OS.
- **Daemon REACHABLE but the project's containers are DOWN** (`docker ps` exits
  0 but the needed services aren't running): do NOT pause, do NOT ask. **Start
  the container(s) yourself** (`docker-compose up -d`, or `up --build` if images
  need building), wait for them to be healthy, then **resume the task**.

`docker` / `docker compose` commands run on the host are explicitly ALLOWED
(they're in the project's command-exception list alongside `git` and read-only
ops). Starting containers is not a host-fallback — it's the correct unblock.

**Why this matters / what went wrong (2026-06-19, replicator-1-0):**

Mid-`feature-build` I needed to run pytest + a migration script, which must run
inside `replicator_backend`. The container was down (but `docker ps` exited 0).
I conflated "container down" with the daemon-unreachable hard-blocker and PAUSED
to ask the operator to start the stack — wasting a round-trip. The operator
pushed back twice ("the daemon is not unreachable, right? why can't you just
start the container yourself?") before I corrected.

**The distinction to internalize:**

| Condition | Test | Action |
|-----------|------|--------|
| Daemon unreachable | `docker ps` errors | PAUSE — ask user (hard-blocker) |
| Daemon up, container down | `docker ps` OK, service missing | START it yourself, then continue |

**How to apply:** Before assuming a Docker hard-block, actually check the
daemon vs the containers separately. `docker ps` exiting 0 = daemon is fine =
NOT the hard-blocker. If the specific service container is missing, bring the
stack up yourself and keep going. Only an erroring daemon justifies a pause.

**Relation to the written rule:** the global CLAUDE.md "Docker Hard-Blocker"
is scoped to "if the Docker daemon is **unreachable**." The project CLAUDE.md
adds "if the Docker daemon is unreachable, STOP and ask … Do not fall back to
the host OS." Neither says to pause when only the *containers* are down — that
case is on me to resolve by starting them. Read the trigger word literally:
**unreachable daemon**, not **stopped container**.
