---
workflow: feature
state: complete
completed: 2026-06-19
drive_mode: autopilot
created: 2026-06-19
---

# Feature: Docker daemon-vs-container distinction in the Docker Hard-Blocker rule

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-19

## Problem Statement

The Docker Hard-Blocker rule conflates two distinct conditions. As written it says only: "If the Docker daemon is **unreachable**, STOP and ask the user … Do not fall back to the host OS." In practice this caused a real wasted round-trip (2026-06-19, replicator-1-0): mid-`feature-build`, a needed service container was *down* but the daemon was *up* (`docker ps` exited 0). The agent conflated "container down" with "daemon unreachable" and PAUSED to ask the operator to start the stack — when the correct unblock was to start the container itself (`docker` / `docker compose` commands are already on every project's allowed list). The rule must distinguish: **daemon unreachable → pause (hard-blocker, unchanged); daemon reachable but containers down → start them yourself, then resume — do NOT pause.** Source learning: `.claude/learnings/2026-06-19-docker-daemon-up-container-down-just-start-it.md`.

**Scope correction discovered during planning:** the args assumed the rule lives in `CLAUDE.snippet.md` under `## Environment & Infrastructure`. It does not — `CLAUDE.snippet.md` has no Environment section, and the global "Docker Hard-Blocker" rule lives in the user's *hand-maintained* `~/.claude/CLAUDE.md` (outside install.sh's managed markers, hence not a repo artifact). The repo-owned surface that propagates this rule is `skills/product-context/SKILL.md:70` — the Variant-A generated-CLAUDE.md template line. That is the only in-repo file this feature edits. The user's private global file is out of repo; the learning file already captures the same correction for that surface (logged as a discovery / follow-up, not silently edited here).

## Work Tree

- [x] Phase 1: Refine the generated Docker rule to distinguish daemon-down from container-down  <!-- status: [x] — all children complete -->

  **Observable outcomes:**
  - CLI: `grep -c "daemon is unreachable" skills/product-context/SKILL.md` → still ≥1 (hard-blocker clause preserved).
  - CLI: `grep -iE "container.*(down|start)|docker compose up" skills/product-context/SKILL.md` → ≥1 match (new container-down → start-it-yourself clause present).
  - CLI: `grep -c "fall back to the host OS" skills/product-context/SKILL.md` → ≥1 (host-OS no-fallback discipline preserved).
  - CLI: `./tests/check-structure.sh` exits 0 (no structural regression).
  - CLI: `./tests/run-tests.sh --id P10b` PASSes (Variant-A generation scenario still green; the daemon line is not pinned by it, but confirm no regression).
  - [x] P1.1 Edit `skills/product-context/SKILL.md:70` — replace the single daemon-unreachable line with a two-case clause: (a) daemon unreachable → STOP/ask, no host fallback (unchanged intent); (b) daemon reachable but containers down → start them yourself (`docker compose up -d`, `up --build` if images need building), wait for healthy, resume — do NOT pause. Keep it concise (template prose).  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — content greps pass; check-structure.sh 267/0 green (17s); P10b unaffected (touches a different paragraph) -->
  - [x] verify-self  <!-- status: [x] — subagent: all 4 CLI outcomes PASS, 0 BLOCKING/COSMETIC. No integration boundary (isolated prose edit). -->
  - [x] verify-human  <!-- status: [x] — AUTO-SKIP (F11): all 4 auto-skip gates clean (autopilot + verify-self all-PASS + no boundary + no consuming-surface outcome). Affirmation printed as read-time veto. -->
  - [x] verify-codify  <!-- status: [x] — 2 structural pins added to tests/check-structure.sh (daemon-unreachable hard-blocker + container-down self-start), mirroring the randomize-host-ports precedent at lines 163-168. Suite 269/0. No integration boundary. -->

## Current Node
- **Path:** Feature > (shipped, reviewed) > finalize
- **Active scope:** review-quality complete (0 CRITICAL, 0 MAJOR, 1 MINOR auto-backlogged) — finalize next
- **Blocked:** none
- **Unvisited:** none (single-phase feature)
- **Open discoveries:** Args premise was wrong (rule not in CLAUDE.snippet.md) — see Problem Statement scope correction; user's hand-maintained global `~/.claude/CLAUDE.md` Environment block is the out-of-repo twin and is a manual follow-up captured by the learning file.

## Code-Quality Review — docker-daemon-vs-container-distinction

### Strengths
- The prose split is sharp: each case names its concrete observable (`docker ps` errors vs. exits 0) and its exact response, eliminating the diagnostic ambiguity the source learning identified.
- The new rule correctly preserves the global hard-blocker invariant (daemon unreachable → STOP, no host-OS fallback) verbatim in spirit while carving out the self-unblock case — no regression to the load-bearing CLAUDE.md Docker rule.
- Structural pins follow the established `randomize-host-ports` precedent (two `grep_check` pins on the same file), and the pin comment block explains the why and the provenance.
- The container-down branch explicitly cross-references the allowed-list so the self-start instruction is anchored to the surrounding template.
- The pin regexes are appropriately tolerant of prose variation — they pin the load-bearing concept, not exact wording.

### Issues
**CRITICAL** — (none)
**MAJOR** — (none)
**MINOR**
- [tests/check-structure.sh:176] The container-down pin matches `containers are down|docker compose up`, but `docker compose up` may also appear in unrelated allowed-list prose in the same template. The OR-branch means the pin could pass on the wrong line if the new clause is ever deleted but a stray `docker compose up` survives. Pinning the more distinctive `start the container(s) yourself` phrasing would tie the pin to the actual new clause. Low-stakes since the daemon-unreachable pin still anchors the section.

### Assessment
Small, well-targeted prose refinement that does exactly what its commit message claims. Minimal change, operationally precise distinction (each case keyed to a checkable signal), global hard-blocker invariant left intact. The only blemish is a mildly over-broad pin regex (MINOR). No refactor warranted.

### If you disagree
Operator: dismiss any finding by editing this section in the WIP and marking the line `[DISMISSED]` before `feature-finalize` archives the WIP.

## Retrospect
- **What changed in our understanding:** The args assumed the Docker Hard-Blocker rule lived in `CLAUDE.snippet.md`. It does not — the snippet has no Environment section. The global rule lives in the user's hand-maintained `~/.claude/CLAUDE.md` (outside install.sh's managed markers, so not a repo artifact). The only repo-owned propagation surface is `skills/product-context/SKILL.md:70`, the Variant-A generated-CLAUDE.md template line.
- **Assumptions that held:** The intended behavior change (daemon-unreachable → pause; container-down → start-it-yourself) was exactly as the learning prescribed; the structural-pin codification surface (mirroring randomize-host-ports precedent) was the right one.
- **Assumptions that were wrong:** The target file. A whole-repo grep at plan time (which I ran) corrected the premise before any wasted edit — confirming the "grep the canonical source before close-reading" discipline from the prior session's deferred learning.
- **Approach delta:** None vs. the corrected plan. The single-phase plan, build, verify chain, and ship executed exactly as planned. The MINOR pin-over-broadness finding (auto-backlogged) was the only surprise, and it's a test-pin polish item, not a behavior defect.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
[SURFACED-2026-06-19] P1.1 — The global "Docker Hard-Blocker" rule is NOT in CLAUDE.snippet.md (no Environment section there); it lives in the user's hand-maintained ~/.claude/CLAUDE.md outside install.sh markers. The only repo-owned propagation surface is skills/product-context/SKILL.md:70 (Variant-A template). Out-of-repo global file is a manual operator follow-up — not edited by this feature.
