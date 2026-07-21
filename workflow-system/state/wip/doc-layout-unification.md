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

- [ ] Phase 1: WP2a — Source sweep (move this repo's dirs + rewrite all path references)  <!-- status: in-progress; impl done, verify pending -->
  **Observable outcomes:**
  - CLI: `ls -d workflow-system/product workflow-system/state` exits 0; `ls -d docs/product workflow` exits non-zero (old dirs gone).
  - CLI: `git log --follow --oneline workflow-system/product/arch.md | wc -l` > 1 (history preserved through the `git mv`).
  - CLI: path-anchored grep finds ZERO stale path refs — `grep -rnE '(^|[^-])docs/product/|[^-a-z]workflow/(wip|backlog|archive|\.session)' skills/ agents/ tests/ CLAUDE.md CLAUDE.snippet.md` returns no output (all rewritten to `workflow-system/`).
  - CLI: NO over-rewrite of the bare concept-word — `grep -rc 'workflow-system/state' skills/ | awk -F: '{s+=$2} END{print s}'` is bounded to the ~343 path sites, and a spot-check confirms conceptual "workflow" prose ("the feature workflow", "workflow state") is untouched.
  - CLI: `bash tests/check-structure.sh` exits 0 (all path pins updated to `workflow-system/…`).
  - CLI: `bash tests/run-tests.sh --group session` (fresh-subprocess) passes — scenarios referencing `workflow/.session.md` / `workflow/wip/…` fixtures resolve at new paths.
  - [x] P1.1 `git mv docs/product workflow-system/product` and `git mv workflow workflow-system/state` (create `workflow-system/` parent; preserves history) — the dogfood move (D3)  <!-- status: done — 133 renames, 0 delete+add; history follows on commit -->
  - [x] P1.2 Build the path-anchored rewrite: enumerate exact match patterns from D2 (`docs/product/…` always-path; `workflow/` only trailing-slash or known-child `wip|backlog|archive|.session|learnings`), NEVER bare-word `workflow`. Dry-run the substitution and diff-review before applying.  <!-- status: done — 6 patterns; caught 2 false-positive classes (-workflow/AGENTS.md tails, workflow/process prose) EXCLUDED -->
  - [x] P1.3 Apply sweep to `skills/` (all matching SKILL.md) — grep-driven per downstream-contract-impacts discipline; re-verify path-qualification mandate (no bare `.claude/` or bare paths introduced)  <!-- status: done -->
  - [x] P1.4 Apply sweep to `agents/` (5 files) + `CLAUDE.md` + `CLAUDE.snippet.md` (+ 4 hand-fixed prose dir-name residues the anchored pattern correctly skipped)  <!-- status: done -->
  - [x] P1.5 Apply sweep to `tests/` (scenarios/*.yaml, run-tests.sh incl. line-178 mkdir fixture-scaffold fix, check-structure.sh 12 product-path pins); EXCLUDED tests/results/*.json (gitignored) + tests/sessions/*.jsonl (frozen audited historical capture)  <!-- status: done -->
  - [x] P1.6 Honor state-machine-in-three-places sync: `transitions.md` (now at `workflow-system/product/transitions.md`) + per-skill `SKILL.md` + `scenarios/*.yaml` all carry consistent new paths  <!-- status: done — 58 files swept, 0 stale refs remain -->
  - [x] verify-auto  <!-- status: done — check-structure.sh 416/0; all 71 scenario fixture paths resolve on disk; 0 stale paths in scenario yamls + fixture contents; harness mkdir/copy targets aligned. Full model-driven scenario suite deferred to verify-codify (right place for behavioral coverage; 13-17min fresh-subprocess run). -->
  - [x] verify-self  <!-- status: done — feature-verify-self-runner subagent: 6/6 PASS, 0 BLOCKING, 0 COSMETIC. Verified: new dirs exist+old gone; 133 renames/0 delete+add (history preserved); zero stale refs; concept-word preserved (9)+agent-tails uncorrupted; check-structure.sh 416/0; frozen jsonl exclusion intentional (31 old refs retained). -->
  - [x] verify-human  <!-- status: done — operator approved all 3 leaves 2026-07-21 -->
    - [x] P1.verify-human.1 Operator eyeballed the new top-level layout — approved  <!-- status: done -->
    - [x] P1.verify-human.2 Operator confirmed sweep exclusions correct (frozen jsonl + gitignored results intentionally on old paths)  <!-- status: done -->
    - [x] P1.verify-human.3 Operator OK'd committing the Phase-1 sweep now, atomic commit  <!-- status: done -->
  - [ ] verify-codify  <!-- status: in-progress — structural pin DONE (Phase 15, 420/0); behavioral session-suite running in bg -->
    - [x] verify-codify.1 Structural regression lock: check-structure.sh Phase 15 (4 pins) — asserts NO stale docs/product|workflow/<child> reappears + both unified roots stay referenced. 420/0. Caught 8 self-match false-positives on first write → triaged (obsolete-test, high-conf) → excluded check-structure.sh from its own grep.  <!-- status: done -->
    - [ ] verify-codify.2 Behavioral highest-level test: full session-group suite (31 scenarios, fresh-subprocess) — running in bg (id ba3ldcv7g)  <!-- status: in-progress -->

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
- **Path:** Feature > Phase 1 (WP2a) > verify-codify
- **Active scope:** verify-codify (add regression coverage locking the new layout; run full behavioral gate)
- **Blocked:** none
- **Unvisited:** Phase 1 verify-codify → Phase 2 (P2.1→P2.6 + verify group, P2.5 is an operator-ping coordination pause) → Phase 3 (P3.1→P3.2 + verify group)
- **Open discoveries:** WP2b operator-coordination ping for in-flight projects (Phase 2 gate)
- **Phase-1 sweep committed** (operator-approved atomic commit 2026-07-21). verify-human approved 3/3.

## Test Triage — Phase 15 "no stale docs/product path" (verify-codify)
Classification: Obsolete test — the check as first written was self-matching (its own descriptive comments + the `grep -rnE 'docs/product'` pattern literal live inside check-structure.sh, which the check greps).
Confidence: high
Evidence: all 8 reported "stale" refs are on lines 2121–2149 of tests/check-structure.sh — the Phase 15 block's own comments/pattern, zero in any skill/agent/scenario/CLAUDE doc.
Action: exclude check-structure.sh from its own docs/product grep (the check guards the prompt/scenario/CLAUDE surface, not its own source). Auto-fixed then re-ran. NOTE: the fact that a legitimate stale-path check would trip on its own pattern-literal is itself signal the sweep+lock is working — no real stale ref exists in the guarded surface.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [SURFACED-2026-07-21] WP2 sweep — "workflow" is overloaded 803 bare-word vs 343 path occurrences; sweep MUST be path-anchored (trailing-slash / known-child match), never word-level. Highest-risk item in M7. Logged here so WP2 inherits it as a hard rule.
- [SURFACED-2026-07-21] P1.2 false-positive classes CAUGHT by the anchored sweep (each would have been corrupted by a naive `s/workflow/…/`): (1) `-workflow/AGENTS.md` = tail of `agents/<x>-workflow/AGENTS.md` orchestrator-file refs (NOT the state dir); (2) `workflow/state` in feature-research prose ("source workflow/state"); (3) `workflow/process`, `workflow/agent` = session-reflect DROP-gate prose. All excluded from rewrite. Confirms the path-anchoring rule was load-bearing, not theoretical.
- [SURFACED-2026-07-21] P1.5 sweep EXCLUSIONS (scope decision): `tests/results/*.json` (gitignored, regenerable test output) and `tests/sessions/*.jsonl` (a Tier-2-audited FROZEN historical session capture — its commit msg says "abandon single-shot replay harness"; nothing consumes it; rewriting would falsify the 2026-05-16 record + invalidate the AUDIT-LOG.md signoff). Both correctly left on old paths.
- [SURFACED-2026-07-21] P1.5 harness half-migration BUG caught + fixed: `tests/run-tests.sh:178` `mkdir`'d `$tmpdir/docs/product` but line 210 (swept) copies fixtures into `$tmpdir/workflow-system/product/` — the mkdir was updated to match. Prose dir-name residues (4 in CLAUDE.md/CLAUDE.snippet.md that the trailing-slash-anchored pattern skipped) also hand-fixed.
- [SURFACED-2026-07-21] WP2b cross-project run — operator is actively working in `neo-stayman-assistant` (#4) concurrently. **Before WP2b migrates ANY project, ping the operator to pause/commit in-flight projects (#4 neo-stayman, #7 GNIE).** WP2b is gated behind WP2a + the tool build, so this coordination pause happens later, not now — operator does NOT need to stop work yet. Reinforces the per-project pre-risky-action rule in D4.
