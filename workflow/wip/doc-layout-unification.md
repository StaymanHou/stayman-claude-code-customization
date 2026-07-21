# Feature: Doc-layout unification (M7 / WP1 decision-probe → WP2 sweep → WP3-M7 resync)

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-07-21
**Entry:** spec (complex feature — L-sized 59-file sweep + cross-project migration)
**Milestone:** 7 (Claudesk Handoff Cycle)
**Arch:** `docs/product/arch.md` → Revision 2026-07-20 → AD-1 (Option A, physical unification)
**WBS:** `docs/product/wbs.md` → Milestone 7 (WP1 / WP2 / WP3-M7)
**drive_mode:** autopilot

## Problem Statement

The workflow system splits its per-project state across **two** top-level folders — `docs/product/` (strategic docs) and `workflow/` (transient execution state). For a newcomer not already fluent in this customization, **the two-folder split is itself the confusion** (AD-1 operator reframing). Milestone 7 physically unifies them under **one** top-level root with two clearly-named subfolders, so a newcomer learns one home (`workflow-system/`) while the strategic-vs-operational distinction survives as legible substructure.

This is a **convention change for all consuming projects**, not just this repo: the skills emit the new paths, so every project adopting an updated skill starts writing to the new layout. Existing on-machine projects (old dirs already on disk) must be migrated — confirmed in-scope, not clean-break.

**WP1 is the decision-probe.** It settles the target names, produces the exhaustive old→new rename map, decides dogfood timing, and enumerates the projects to migrate — all **before** the L-sized WP2 mechanical sweep touches any file (resolve the riskiest unknown cheaply first).

## User Stories

- As a **new workflow-system user**, I want a single top-level `workflow-system/` folder so that I only have to learn one place where the system keeps its state, not reverse-engineer why there are two.
- As the **operator maintaining N consuming projects**, I want a one-time idempotent migration helper (modeled on `tools/memory-link/`) so that existing projects move to the new layout safely and reversibly, without hand-editing each.
- As a **future skill author**, I want every path reference swept to the new roots so that the state-machine-in-three-places stays in sync and no skill emits a stale path.

## Acceptance Criteria (WP1 decision-probe)

WP1 is **done** when the following four decisions are recorded here (and mirrored into `arch.md` as-built by WP3-M7):

1. **Final folder + subfolder names** — confirmed or adjusted from the proposal.
2. **Exhaustive old→new rename map** — every distinct path form that appears in the codebase, mapped.
3. **Dogfood decision** — whether/when THIS repo moves its own `docs/product/` + `workflow/`, and whether the migrate helper handles the repo itself or it's a follow-on.
4. **Project enumeration** — the exact list of on-machine consuming projects to migrate, with per-project state (branch, layout, uncommitted-file caution).

The decision-probe **surfaces items 1 + 4 to the operator for confirmation before WP2 runs** (built-in checkpoint — the natural review point per the WBS ordering rationale).

## Decisions (WP1 output — DRAFT for operator confirmation)

### D1 — Final folder + subfolder names

**Proposed (AD-1 working names, recommended to confirm as-is):**

| New root/subfolder | Replaces | Holds |
|---|---|---|
| `workflow-system/` | (new top-level home) | the whole system's per-project state |
| `workflow-system/product/` | `docs/product/` | strategic: `vision.md`, `roadmap.md`, `research.md`, `arch.md`, `wbs.md`, `context.md`, `transitions.md`, `design-priors.md`, `archive/` |
| `workflow-system/state/` | `workflow/` | operational: `wip/`, `backlog.md`, `backlog-*.md`, `.session.md`, `archive/` |

**Recommendation:** confirm as proposed. `workflow-system/` reads as an obvious single home; `product/` and `state/` name the strategic-vs-operational axis cleanly. (Operator confirms/adjusts at the checkpoint below.)

### D2 — Exhaustive old→new rename map

**Directory-level moves (git mv — history preserved):**

```
docs/product/   →  workflow-system/product/
workflow/       →  workflow-system/state/
```

**Path-reference forms found in the codebase (grep-verified) that WP2 must rewrite:**

`docs/product/` forms (all rewrite to `workflow-system/product/…`):
- `docs/product/*.md`, `docs/product/arch.md`, `docs/product/wbs.md`, `docs/product/roadmap.md`, `docs/product/vision.md`, `docs/product/research.md`, `docs/product/transitions.md`, `docs/product/context.md`, `docs/product/design-priors.md`
- `docs/product/archive`, `docs/product/archive/<cycle-name>/`
- `docs/product/<sweep-name>-wbs.md`

`workflow/` forms (all rewrite to `workflow-system/state/…`):
- `workflow/wip`, `workflow/wip/…` (incl. `<f>.md`, `<feature-name>.md`, `<item>.md`, `<task-slug>.md`, `incident-<slug>.md`, `debug-<short-slug>.md`, and fixture names like `feature-build-phase1-done.md`)
- `workflow/backlog.md`, `workflow/backlog-quality-findings.md`, `workflow/backlog-deferred-*.md`, `workflow/backlog*.md`
- `workflow/archive/`, `workflow/archive/<feature-name>.md`, `workflow/archive/<wip-file>`, `workflow/archive/<incident-file>`
- `workflow/.session.md`

**⚠️ Load-bearing constraint discovered at WP1 (feeds WP2 as a hard rule):**
The token **"workflow"** is heavily overloaded — **803** bare-word occurrences ("the feature *workflow*", "*workflow* state", "*workflow* system") vs. only **343** `workflow/`-as-path occurrences across `skills/ agents/ tests/ CLAUDE*.md`. A naive word-level `s/workflow/workflow-system\/state/` would be **catastrophic** — it would corrupt every conceptual mention. **WP2's sweep MUST be path-anchored:** match `workflow/` only where the trailing slash indicates a path (or `workflow` immediately followed by a known child like `/wip`, `/backlog`, `/archive`, `/.session`), never the bare word. `docs/product` is not similarly overloaded (it is always a path), but the same anchored discipline applies. This is the single highest-risk item in the whole milestone.

**Also note (do NOT rename):** the top-level `workflow-system/` name collides *textually* with the phrase "workflow system" used throughout the prose to mean the product itself. That is fine — the folder is always in a path context (`workflow-system/product/…`) and the prose phrase is never path-anchored, so the same anchored-match discipline that protects `workflow/` protects here too.

### D3 — Dogfood decision

**Recommendation:** THIS repo dogfoods the move **in WP2 (task 2.1), as the first step of the sweep** — `git mv` its own `docs/product/` → `workflow-system/product/` and `workflow/` → `workflow-system/state/` before rewriting references. Rationale: the repo must practice what its skills preach, and doing the move first means the reference-rewrite sweep (2.2–2.4) is validated against the repo's *own* moved layout. The `migrate-doc-layout/` helper is built for *other* consuming projects (2.5–2.6); the repo's own move is a plain `git mv` in 2.1 (it does not need the helper's cross-project slug/backup machinery — it's inside the repo and under version control already).

### D4 — On-machine consuming-project enumeration (grep-verified 2026-07-21, full-home sweep)

Swept `~/Personal/projects` **and** `~/Work/Kenosis` (belt-and-suspenders: dirs carrying both `docs/product/` and `workflow/backlog.md`). **10 consuming projects** found; **9 are migration targets** (gospelherald excluded per operator 2026-07-21):

| # | Project (path) | docs/product | wip/archive | git branch | uncommitted | Migration note |
|---|---|---|---|---|---|---|
| 1 | `~/Personal/projects/my-claude-code-customization` | 6 + archive | 0 / 112 | main | 2 | **This repo** — moved in WP2.1 by plain `git mv`, NOT the helper |
| 2 | `~/Personal/projects/claudesk` | 6 + archive | 0 / 104 | main | 1 | M12 return contract also updates its M11 `docs_list` — coordinate |
| 3 | `~/Personal/projects/areo-test-proty-1` | 4 + archive | 0 / 66 | main | 0 | clean tree — straightforward |
| 4 | `~/Personal/projects/neo-stayman-assistant` | 6 + archive | 0 / 76 | main | 1 | commit/stash before migrate |
| 5 | `~/Personal/projects/replicator-1-0` | 5 + archive | 0 / 96 | **phase-6.1-content-production** | 2 | **non-main branch** — migration commit lands there; flag |
| 6 | `~/Personal/projects/turn-based-ai-test-proto-1` | 13 (no archive) | 0 / 7 | main | 2 | most product docs; no product archive yet |
| 7 | `~/Work/Kenosis/google-newsroom-intelligence-engine` | 8 + archive | **1** / 39 | main | **5** | ✅ **MIGRATE (operator-confirmed 2026-07-21): commit the 5 changes first**, then migrate; active wip moves intact |
| 8 | `~/Work/Kenosis/gospelherald.com.hk` | 6 (no archive) | 0 / 2 | **master** | 0 | ❌ **EXCLUDED (operator-confirmed 2026-07-21)** — memory-link exclusion carries over; stays on old layout |
| 9 | `~/Work/Kenosis/ops-data-hub` | 7 + archive | 0 / 22 | main | 0 | clean tree |
| 10 | `~/Work/Kenosis/adops/knowledge_base` | 6 (no archive) | 0 / 1 | **master** | 3 | `master` branch; commit/stash before migrate |

**Per-project pre-risky-action rule (global):** before the helper moves anything in a project, confirm a clean tree or `git stash` first, and the helper takes a timestamped reversible backup regardless (mirroring `migrate-memory.sh`). `--dry-run` runs first on every project. **Branch-agnostic:** the helper commits on whatever branch is checked out (projects #5, #8, #10 are not on `main`/`master` uniformly) — the migration commit lands on the current branch; flag #5's feature branch and #7's in-flight work to the operator.

## Out of Scope

- **The WP2 mechanical sweep itself** — WP1 only *decides* and *maps*; WP2 executes.
- **Building `tools/migrate-doc-layout/`** — that is WP2.5 (though its shape is specified below under Technical Constraints as a settled decision, mirroring `tools/memory-link/`).
- **The `uninstall.sh` (M8/WP4), pause disambiguation (M9/WP5), research collision (M10/WP6), onboarding spike (M11/WP7), return contract (M12/WP8)** — separate milestones/WPs.
- **Renaming the roadmap "Milestone" unit or the feature Work-Tree "Phase" unit** — untouched; unrelated to folder paths.
- **Any state-machine transition change** — AD-1 explicitly adds no new transitions; behavior stays within existing states.

## Technical Constraints

- **`tools/migrate-doc-layout/` mirrors `tools/memory-link/` exactly** (settled precedent, not an open question): idempotent (re-run = no-op when already migrated), `--dry-run`, `--date YYYY-MM-DD` param for deterministic backup-dir naming in tests (the harness-shell date footgun), timestamped reversible backup before any move, **drift/conflict rule** (never silently overwrite — if a target path already exists with different content, keep both and print a `DRIFT:` line), a `test/` suite (`tools/migrate-doc-layout/test/run-tests.sh`), and a `README.md` with canonical invocations. This is a WP2 build constraint, recorded here because WP1's reference-precedent study settled it.
- **Path-anchored sweep (D2 ⚠️)** — the overloaded "workflow" word makes word-level substitution unsafe. Hard rule for WP2.
- **State-machine-in-three-places sync** — path references live in `transitions.md`, per-skill `SKILL.md`, AND `tests/scenarios/*.yaml`; all three update together (CLAUDE.md convention).
- **Path-qualification mandate** — every `.claude/` and doc-path reference in prompts stays explicitly qualified; the sweep must not introduce bare paths. `tests/check-structure.sh` Phase 12 enforces the `.claude/` half; new path pins for `workflow-system/` are a WP2 concern.
- **`git mv` preserves history** for the moved directories — use it, not `rm`+`add`.
- **Verification gate** — WP2 ends green only after `tests/check-structure.sh` + `tests/run-tests.sh` pass (fresh-subprocess — beware harness bootstrap-skip on edited SKILL.md content; the freshly-edited paths are served stale to an in-session re-invocation).
- **No new runtime dependencies** — pure shell + prompt/doc edits (AD-1).
- **No 3rd-party service dependency** — 3rd-party probe check: N/A (this is an internal file-layout change).

## Open Questions

- [x] **[OPERATOR CONFIRMED 2026-07-21]** D1 folder names — `workflow-system/product/` + `workflow-system/state/` confirmed ("good").
- [x] **[OPERATOR CONFIRMED 2026-07-21]** WP2 split into WP2a (source sweep) + WP2b (migration tool + cross-project run) — confirmed ("yes, split").
- [x] **[OPERATOR CONFIRMED 2026-07-21]** D4 scope broadened beyond `~/Personal/projects` to include `~/Work/Kenosis` — 10 projects now enumerated.
- [x] **[OPERATOR CONFIRMED 2026-07-21]** `gospelherald.com.hk` (#8) — **EXCLUDED** (memory-link exclusion carries over).
- [x] **[OPERATOR CONFIRMED 2026-07-21]** `google-newsroom-intelligence-engine` (#7) — **MIGRATE now, commit the 5 in-flight changes first**.
- [x] D3 dogfood timing — repo moves in WP2.1 via plain `git mv`; helper is for other projects only. Recommended path adopted.

**All WP1 decisions settled. Final migration target count: 9 projects (10 found, gospelherald excluded).**

## Work Tree

- [ ] Phase 1: WP2a — Source sweep (move this repo's dirs + rewrite all path references)  <!-- status: NOT-STARTED -->
  **Observable outcomes:**
  - CLI: `ls -d workflow-system/product workflow-system/state` exits 0; `ls -d docs/product workflow` exits non-zero (old dirs gone).
  - CLI: `git log --follow --oneline workflow-system/product/arch.md | wc -l` > 1 (history preserved through the `git mv`).
  - CLI: path-anchored grep finds ZERO stale path refs — `grep -rnE '(^|[^-])docs/product/|[^-a-z]workflow/(wip|backlog|archive|\.session)' skills/ agents/ tests/ CLAUDE.md CLAUDE.snippet.md` returns no output (all rewritten to `workflow-system/`).
  - CLI: NO over-rewrite of the bare concept-word — `grep -rc 'workflow-system/state' skills/ | awk -F: '{s+=$2} END{print s}'` is bounded to the ~343 path sites, and a spot-check confirms conceptual "workflow" prose ("the feature workflow", "workflow state") is untouched.
  - CLI: `bash tests/check-structure.sh` exits 0 (all path pins updated to `workflow-system/…`).
  - CLI: `bash tests/run-tests.sh --group session` (fresh-subprocess) passes — scenarios referencing `workflow/.session.md` / `workflow/wip/…` fixtures resolve at new paths.
  - [ ] P1.1 `git mv docs/product workflow-system/product` and `git mv workflow workflow-system/state` (create `workflow-system/` parent; preserves history) — the dogfood move (D3)  <!-- status: NOT-STARTED -->
  - [ ] P1.2 Build the path-anchored rewrite: enumerate exact match patterns from D2 (`docs/product/…` always-path; `workflow/` only trailing-slash or known-child `wip|backlog|archive|.session|learnings`), NEVER bare-word `workflow`. Dry-run the substitution and diff-review before applying.  <!-- status: NOT-STARTED -->
  - [ ] P1.3 Apply sweep to `skills/` (38 files) — grep-driven per downstream-contract-impacts discipline; re-verify path-qualification mandate (no bare `.claude/` or bare paths introduced)  <!-- status: NOT-STARTED -->
  - [ ] P1.4 Apply sweep to `agents/` (5 files) + `CLAUDE.md` + `CLAUDE.snippet.md`  <!-- status: NOT-STARTED -->
  - [ ] P1.5 Apply sweep to `tests/` (14 files: `scenarios/*.yaml`, `run-tests.sh`, `check-structure.sh` path-pin literals ~30+ `docs/product/…` grep_check args, session jsonl fixtures)  <!-- status: NOT-STARTED -->
  - [ ] P1.6 Honor state-machine-in-three-places sync: confirm `transitions.md` (now at `workflow-system/product/transitions.md`) + per-skill `SKILL.md` + `scenarios/*.yaml` all carry consistent new paths  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: WP2b — Migration tool + gated cross-project run  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - CLI: `bash tools/migrate-doc-layout/migrate-doc-layout.sh --help` exits 0 and documents `<proj-dir>`, `--dry-run`, `--date`.
  - CLI: `bash tools/migrate-doc-layout/test/run-tests.sh` exits 0 (all assertions pass — idempotency, dry-run, backup, drift-keep-both).
  - CLI: on a fixture project, `migrate-doc-layout.sh <fixture> --dry-run` prints planned moves and creates NOTHING; a real run moves `docs/product`→`workflow-system/product` + `workflow`→`workflow-system/state`, leaves a timestamped `.migration-backup-<date>/`, and re-running is a no-op (`OK: already migrated`).
  - CLI: drift case — a pre-existing `workflow-system/product/arch.md` with different content is preserved as `arch.harness.md`-style sidecar + a `DRIFT:` line printed, NEVER silently overwritten.
  - CLI (post-run, per migrated project): `ls -d <proj>/workflow-system/product <proj>/workflow-system/state` exits 0; old dirs gone; project's own `git log --follow` shows history preserved.
  - [ ] P2.1 Scaffold `tools/migrate-doc-layout/` from `tools/memory-link/` template: `migrate-doc-layout.sh`, sourced `lib-*.sh` if shared logic warrants, `README.md`, `test/run-tests.sh`  <!-- status: NOT-STARTED -->
  - [ ] P2.2 Implement the move: idempotent (re-run no-op when `workflow-system/` already present), `--dry-run`, `--date YYYY-MM-DD`, timestamped reversible backup before move, drift-keep-both rule, `git mv` when the project dir is a git repo (preserve history) else plain `mv`  <!-- status: NOT-STARTED -->
  - [ ] P2.3 Write `test/run-tests.sh` (mirror memory-link's 27-assertion suite shape): temp fixture projects, assert dry-run/real/idempotent/backup/drift/git-history-preserved  <!-- status: NOT-STARTED -->
  - [ ] P2.4 Write `README.md` with canonical invocations + the drift rule + the branch-agnostic + pre-risky-action notes  <!-- status: NOT-STARTED -->
  - [ ] P2.5 **[OPERATOR PING — coordination pause]** Before running against ANY external project, ping operator to commit/stash + pause in-flight projects (#4 neo-stayman, #7 GNIE). Confirm the 9-project list is still current.  <!-- status: NOT-STARTED -->
  - [ ] P2.6 Run `migrate-doc-layout.sh <proj> --dry-run` then real, across the 9 confirmed projects (GNIE: commit its 5 changes first; gospelherald excluded); verify each post-run  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 3: WP3-M7 — Resync arch as-built + capture settled layout for the M12 return contract  <!-- status: NOT-STARTED; depends on Phase 2 -->
  **Observable outcomes:**
  - CLI: `grep -c 'workflow-system/product\|workflow-system/state' workflow-system/product/arch.md` > 0 — AD-1 resynced to as-built (paths moved, migration strategy shipped).
  - CLI: a `## Return contract — M7 settled layout` (or equivalent) block exists in the WIP (or a designated doc) carrying the exact new `docs_list` glob paths (`workflow-system/product/*.md`, `workflow-system/state/wip/*.md`, `workflow-system/state/backlog.md`, `workflow-system/state/.session.md`) for WP8 to hand to Claudesk M11.
  - CLI: `bash tests/check-structure.sh` still exits 0 after the arch.md edit.
  - [ ] P3.1 Resync `arch.md` AD-1 from decision → as-built (paths moved; `tools/migrate-doc-layout/` shipped; 9-project migration done; gospelherald excluded)  <!-- status: NOT-STARTED -->
  - [ ] P3.2 Write the settled layout + exact new `docs_list` glob paths for the WP8 (M12) return contract  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 (WP2a) > P1.1
- **Active scope:** P1.1 (git mv the two dirs — the dogfood move)
- **Blocked:** none
- **Unvisited:** Phase 1 (P1.1→P1.6 + verify group) → Phase 2 (P2.1→P2.6 + verify group, P2.5 is an operator-ping coordination pause) → Phase 3 (P3.1→P3.2 + verify group)
- **Open discoveries:** path-anchoring hard rule (see Discoveries); WP2b operator-coordination ping for in-flight projects

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [SURFACED-2026-07-21] WP2 sweep — "workflow" is overloaded 803 bare-word vs 343 path occurrences; sweep MUST be path-anchored (trailing-slash / known-child match), never word-level. Highest-risk item in M7. Logged here so WP2 inherits it as a hard rule.
- [SURFACED-2026-07-21] WP2b cross-project run — operator is actively working in `neo-stayman-assistant` (#4) concurrently. **Before WP2b migrates ANY project, ping the operator to pause/commit in-flight projects (#4 neo-stayman, #7 GNIE).** WP2b is gated behind WP2a + the tool build, so this coordination pause happens later, not now — operator does NOT need to stop work yet. Reinforces the per-project pre-risky-action rule in D4.
