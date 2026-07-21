# Feature: Doc-layout unification (M7 / WP1 decision-probe → WP2 sweep → WP3-M7 resync)

**Workflow:** feature
**State:** ship (complete)
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

## Return Contract — M7 settled layout (for WP8 → Claudesk M11)

**Deliverable for the M12 cross-repo return contract (WP8).** M7 shipped **Option A** — the doc layout is physically unified. Claudesk M11's `docs_list` auto-discovery MUST be updated to glob the **new** roots. This block is the authoritative old→new mapping to hand back.

### Settled layout (as-built 2026-07-21)

| Old path (M11 currently globs) | New path (M11 MUST glob) |
|---|---|
| `docs/product/*.md` | `workflow-system/product/*.md` |
| `docs/product/*wbs*.md` (scratch) | `workflow-system/product/*wbs*.md` |
| `workflow/wip/*.md` | `workflow-system/state/wip/*.md` |
| `workflow/backlog.md` | `workflow-system/state/backlog.md` |
| `workflow/.session.md` | `workflow-system/state/.session.md` |

### `docs_list` backend command change (required, not optional)

Claudesk M11's `docs_list` glob set changes from:
```
docs/product/*.md  +  *wbs*.md  +  workflow/wip/*.md  +  workflow/backlog.md  +  workflow/.session.md
```
to:
```
workflow-system/product/*.md  +  workflow-system/product/*wbs*.md  +  workflow-system/state/wip/*.md  +  workflow-system/state/backlog.md  +  workflow-system/state/.session.md
```

- **Workflow-order for the viewer** (unchanged ordering, new paths): vision → roadmap → wbs (+ `*wbs*.md` scratch) → `workflow-system/state/wip/*.md` → `workflow-system/state/backlog.md` → `workflow-system/state/.session.md` → (arch · research · context).
- **Auto-select-on-open relevance** (new paths): `workflow-system/state/.session.md` → else active `workflow-system/state/wip/*.md` → else `roadmap.md`.
- **`CHANGELOG.md` still deliberately excluded.** Absent files remain silent no-ops.
- **Timing still favorable:** Claudesk M11 is paused/unshipped, so it can adopt the new globs before first ship — no migration of M11-rendered state needed.
- **Note for Claudesk:** claudesk's OWN repo has already been migrated to `workflow-system/` (commit `aacc687`), so M11 can be developed against the new layout directly.

---

## Work Tree

- [x] Phase 1: WP2a — Source sweep (move this repo's dirs + rewrite all path references)  <!-- status: COMPLETE — all impl + verify-auto/self/human/codify done; committed 6fedeb5 + b455657 -->
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
  - [x] verify-codify  <!-- status: done — structural pin (420/0) + behavioral suite run; 3 fails proven independent of rename + SURFACED, not blocking -->
    - [x] verify-codify.1 Structural regression lock: check-structure.sh Phase 15 (4 pins) — asserts NO stale docs/product|workflow/<child> reappears + both unified roots stay referenced. 420/0. Caught 8 self-match false-positives on first write → triaged (obsolete-test, high-conf) → excluded check-structure.sh from its own grep.  <!-- status: done -->
    - [x] verify-codify.2 Behavioral highest-level test: full session-group suite (31 scenarios) ran (14 PASS, 12 SOFT_PASS, 3 FAIL, 2 FLAKY). All 3 FAIL (S2/S3/S12) PROVEN independent of the rename (byte-identical scenario blocks + 100%-path-substitution SKILL.md diff) → triaged + SURFACED (2026-07-21-SESSION-SCENARIO-S2-S12-FRAGILITY), NOT blocking. S3 flaky→passed on sonnet retry.  <!-- status: done -->
    - [x] verify-codify.3 SCOPE discovery: moved product-docs' internal refs (category A live-prose vs B historical) → SURFACED (2026-07-21-MOVED-PRODUCT-DOCS-INTERNAL-PATH-REFS, medium) for operator decision / WP3-M7 fold-in. NOT auto-swept (needs per-ref judgment).  <!-- status: done -->


- [x] Phase 2: WP2b — Migration tool + gated cross-project run  <!-- status: COMPLETE — tool built+tested (35/35), all 8 external projects migrated + committed, verify loop done -->

  **Observable outcomes:**
  - CLI: `bash tools/migrate-doc-layout/migrate-doc-layout.sh --help` exits 0 and documents `<proj-dir>`, `--dry-run`, `--date`.
  - CLI: `bash tools/migrate-doc-layout/test/run-tests.sh` exits 0 (all assertions pass — idempotency, dry-run, backup, drift-keep-both).
  - CLI: on a fixture project, `migrate-doc-layout.sh <fixture> --dry-run` prints planned moves and creates NOTHING; a real run moves `docs/product`→`workflow-system/product` + `workflow`→`workflow-system/state`, leaves a timestamped `.migration-backup-<date>/`, and re-running is a no-op (`OK: already migrated`).
  - CLI: drift case — a pre-existing `workflow-system/product/arch.md` with different content is preserved as `arch.harness.md`-style sidecar + a `DRIFT:` line printed, NEVER silently overwritten.
  - CLI (post-run, per migrated project): `ls -d <proj>/workflow-system/product <proj>/workflow-system/state` exits 0; old dirs gone; project's own `git log --follow` shows history preserved.
  - [x] P2.1 Scaffold `tools/migrate-doc-layout/` from `tools/memory-link/` template: `migrate-doc-layout.sh` + `README.md` + `test/run-tests.sh` (no shared lib needed — plain in-project dir move, no slug/symlink machinery)  <!-- status: done -->
  - [x] P2.2 Implement the move: idempotent (no-op when old dirs absent), `--dry-run`, `--date YYYY-MM-DD`, timestamped reversible backup, drift-keep-both (`.pre-migrate` sidecar + DRIFT line; DUP-drop on identical), `git mv` per-file in a git repo else plain `mv`, empty-`docs/`-parent cleanup (only if empty — preserves docs/lessons etc.)  <!-- status: done -->
  - [x] P2.3 Write `test/run-tests.sh` — 35 assertions (dry-run/real/idempotent/backup/drift/DUP/git-history-preserved/exit-codes/no-old-dirs-noop). Caught + fixed an empty-source-dir cleanup bug (find -empty evaluates at traversal time) → deepest-first rmdir walk. 35/35 PASS.  <!-- status: done -->
  - [x] P2.4 Write `README.md` — canonical invocations, full safety-contract table, exit codes, per-project pre-run checklist (clean-tree/stash, branch-agnostic, dry-run-first, review+commit)  <!-- status: done -->
  - [x] P2.5 **[OPERATOR PING — coordination pause]** CLEARED 2026-07-21. Operator go-ahead received. Decisions: (a) for each DIRTY project, I commit its in-flight work as a `pre-doc-layout-migration` commit before migrating; (b) run sequence = ONE PROJECT AT A TIME (dry-run → show → real → verify → next). Live pre-flight confirmed: 8 external targets, dirty counts recorded. neo-stayman paused by operator.  <!-- status: done -->
  - [x] P2.6 Ran one-at-a-time across the 8 external projects (this repo already done in Phase 1). Each: commit-if-dirty → dry-run → real → verify → commit → remove-backup.  <!-- status: DONE -->
    - [x] P2.6.a areo-test-proty-1 (clean, main)  <!-- status: DONE — 77 renames, 20-commit history, committed d5d339c -->
    - [x] P2.6.b ops-data-hub (clean, main, ~/Work/Kenosis)  <!-- status: DONE — 107 renames, 13-commit history, committed 13eed97 -->
    - [x] P2.6.c claudesk (dirty=1→baseline, main)  <!-- status: DONE — 133 renames, 35-commit history, committed aacc687 (amended to drop backup-in-commit → fixed the loop ordering for all subsequent) -->
    - [x] P2.6.d turn-based-ai-test-proto-1 (dirty=2→baseline 0ac394d, main)  <!-- status: DONE — 28 renames, committed a01d5bb -->
    - [x] P2.6.e knowledge_base (dirty=3→baseline 01b3b84, master, ~/Work/Kenosis/adops)  <!-- status: DONE — 8 renames, committed 4ebbafb -->
    - [x] P2.6.f replicator-1-0 (dirty=2→baseline b92684e, feature branch phase-6.1-content-production)  <!-- status: DONE — 130 renames, 11-commit history, committed e8d6768 on the feature branch -->
    - [x] P2.6.g neo-stayman-assistant (operator-paused, dirty=1→baseline f7a8fc2, main)  <!-- status: DONE — 97 renames, 31-commit history, committed a5ef539 -->
    - [x] P2.6.h google-newsroom-intelligence-engine (active, dirty=5→baseline 00beff0, wip=1)  <!-- status: DONE — 92 renames; active wip m4-wp7c-lane-ruleset-drift-detector.md moved intact; committed 89ea32a -->
    - [x] P2.6.verify Cross-project sweep: all 9 on new layout, old dirs gone, backups removed, history preserved; gospelherald correctly UNTOUCHED (old layout, excluded per operator)  <!-- status: DONE -->
  - [x] verify-auto  <!-- status: DONE — migrate-doc-layout suite 35/35; check-structure.sh 420/0 (this repo unaffected by external migrations) -->
  - [x] verify-self  <!-- status: DONE — cross-project observation: all 9 targets on new layout, old gone, backups removed, history preserved; gospelherald correctly untouched. The tool's own 35/35 suite is the live-system evidence. -->
  - [x] verify-human  <!-- status: DONE (via P2.5 gate + 2 AskUserQuestion rounds + per-project operator decisions — the operator was deeply in-loop for the whole cross-project run; a separate verify-human pause would be redundant). Within THIS repo Phase 2 only adds isolated tools/migrate-doc-layout/; the large external effects were operator-gated at P2.5 and committed per-project with approval. -->
  - [x] verify-codify  <!-- status: DONE — the migration tool IS codified by tools/migrate-doc-layout/test/run-tests.sh (35 assertions, committed 26e9d5f). The Phase-15 structural lock (from Phase 1) already guards the layout convention in this repo. No new codify test needed — the highest-level test (the tool suite) already exists and is green. -->

- [x] Phase 3: WP3-M7 — Resync arch as-built + capture settled layout for the M12 return contract  <!-- status: COMPLETE — arch.md AS-BUILT added, Return Contract block written, verify loop done -->

  **Observable outcomes:**
  - CLI: `grep -c 'workflow-system/product\|workflow-system/state' workflow-system/product/arch.md` > 0 — AD-1 resynced to as-built (paths moved, migration strategy shipped).
  - CLI: a `## Return contract — M7 settled layout` (or equivalent) block exists in the WIP (or a designated doc) carrying the exact new `docs_list` glob paths (`workflow-system/product/*.md`, `workflow-system/state/wip/*.md`, `workflow-system/state/backlog.md`, `workflow-system/state/.session.md`) for WP8 to hand to Claudesk M11.
  - CLI: `bash tests/check-structure.sh` still exits 0 after the arch.md edit.
  - [x] P3.1 Resync `arch.md` AD-1 from decision → as-built — added an AS-BUILT subsection (final names, this-repo git mv, path-anchored 58-file sweep + 3 excluded false-positive classes, Phase-15 lock, tools/migrate-doc-layout/ + 9-project run, gospelherald excluded). Preserved category-B decision/back-loop text; the migration-mapping arrows are intentionally NOT rewritten.  <!-- status: DONE -->
  - [x] P3.2 Wrote the `## Return Contract — M7 settled layout` block in the WIP — exact old→new docs_list mapping + the required Claudesk M11 backend glob change, for WP8 to hand back.  <!-- status: DONE -->
  - [x] verify-auto  <!-- status: DONE — check-structure.sh 420/0 after arch.md edit; arch.md refs new roots (5); Return Contract block present -->
  - [x] verify-self  <!-- status: DONE — Observable outcomes confirmed live: arch.md grep>0, Return Contract block=1, check-structure green. Docs-only phase; no running-system surface beyond the grep-verifiable outcomes. -->
  - [x] verify-human  <!-- status: DONE — docs-only phase (arch resync + return-contract capture); no integration boundary; auto-skip gate clean (autopilot + verify-self all-PASS + no boundary + no consuming-surface outcome). Operator read-time veto retained via the committed arch.md + WIP. -->
  - [x] verify-codify  <!-- status: DONE — the arch as-built + return contract are documentation deliverables; check-structure.sh Phase 15 (already shipped) locks the layout convention. No behavioral test applies to a prose resync. -->

## Current Node
- **Path:** Feature > ship (COMPLETE) → review-quality
- **Active scope:** SHIPPED (local commits, not pushed — operator's call). Next: review-quality (F38).
- **Blocked:** none
- **Unvisited:** ship → review-quality → finalize.
- **Open discoveries:** (1) SURFACE-2026-07-21-MOVED-PRODUCT-DOCS-INTERNAL-PATH-REFS (medium — category-A live-prose in moved product docs; arch.md's own refs handled in P3.1, the rest is follow-up); (2) SURFACE-2026-07-21-SESSION-SCENARIO-S2-S12-FRAGILITY (low, independent); (3) operational learning: migrate-doc-layout should write its backup outside the repo (loop-ordering footgun).
- **ALL 3 PHASES COMPLETE + committed.** P1: 6fedeb5 sweep + b455657 lock + 0af97be codify. P2: 26e9d5f tool + e87e053 close; 8 external projects migrated. P3: arch AS-BUILT + Return Contract (this commit).

## Test Triage — session-suite S2 / S3 / S12 (verify-codify behavioral run)
Classification: Pre-existing scenario fragility (S2 routing-fork wobble, S12 not_contains_strict fragility), independent of this feature. S3 was flaky (passed on sonnet retry). NONE is a regression from the rename.
Confidence: high
Evidence — DEFINITIVE causal exoneration:
  (1) Feature is pure path-substitution; a rename cannot change WHICH transition ID the model emits.
  (2) S2/S3/S12 scenario blocks are BYTE-IDENTICAL pre-sweep (7210bf7) vs HEAD — sweep did not touch their assertions.
  (3) **The full `git diff 7210bf7 HEAD -- skills/session-start/SKILL.md` (the skill these scenarios exercise) is 100% path-string substitutions** (docs/product→workflow-system/product, workflow/x→workflow-system/state) — ZERO changes to routing logic, classification prose, pause-policy behavior, or the not_contains trigger phrases. The sweep provably cannot cause S2's misclassification or S12's auto-chain-phrase trip.
  (4) Haiku run: S2→S10, S3→S1, S12 strict-trip. Sonnet re-run: **S3 PASSED** (flaky confirmed), S2 still→S5 (routing wobble persists across models = genuine scenario ambiguity, docs/lessons/test-scenario-routing-forks.md), S12 still strict-trips on `/feature-verify-codify`+`auto-chain` (the documented not_contains_strict fragility — informational phrase in benign pause-explanation reasoning, docs/lessons/test-scenario-strict-mode.md).
Action: NOT fixed here (session-orchestrator scenario fragility is out of scope for a doc-layout rename) and does NOT block Phase-1 verify-codify. SURFACED to backlog as SURFACE-2026-07-21-SESSION-SCENARIO-S2-S12-FRAGILITY (task:plan, low) for independent follow-up. Do NOT auto-tag model:sonnet (S2/S12 fail on sonnet too — tagging would mask, not fix).

## Test Triage — Phase 15 "no stale docs/product path" (verify-codify)
Classification: Obsolete test — the check as first written was self-matching (its own descriptive comments + the `grep -rnE 'docs/product'` pattern literal live inside check-structure.sh, which the check greps).
Confidence: high
Evidence: all 8 reported "stale" refs are on lines 2121–2149 of tests/check-structure.sh — the Phase 15 block's own comments/pattern, zero in any skill/agent/scenario/CLAUDE doc.
Action: exclude check-structure.sh from its own docs/product grep (the check guards the prompt/scenario/CLAUDE surface, not its own source). Auto-fixed then re-ran. NOTE: the fact that a legitimate stale-path check would trip on its own pattern-literal is itself signal the sweep+lock is working — no real stale ref exists in the guarded surface.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [SURFACED-2026-07-21] WP2 sweep — "workflow" is overloaded 803 bare-word vs 343 path occurrences; sweep MUST be path-anchored (trailing-slash / known-child match), never word-level. Highest-risk item in M7. Logged here so WP2 inherits it as a hard rule.
- [SURFACED-2026-07-21] P1.2 false-positive classes CAUGHT by the anchored sweep (each would have been corrupted by a naive `s/workflow/…/`): (1) `-workflow/AGENTS.md` = tail of `agents/<x>-workflow/AGENTS.md` orchestrator-file refs (NOT the state dir); (2) `workflow/state` in feature-research prose ("source workflow/state"); (3) `workflow/process`, `workflow/agent` = session-reflect DROP-gate prose. All excluded from rewrite. Confirms the path-anchoring rule was load-bearing, not theoretical.
- [SHORTCUT-2026-07-21] P2.6 loop-ordering bug caught + fixed mid-run: the per-project migrate loop did `git add -A` (which staged the `cp -R` backup dir) → commit → `rm -rf backup`, so claudesk's migration commit captured the backup then showed 134 phantom `D` deletions. Fixed by moving `rm -rf backup` BEFORE the migration `git add -A`; claudesk amended to drop the backup from its commit (aacc687). areo (done manually first) was already clean. All 6 subsequent projects used the fixed ordering. **Operational learning for reflect:** the migrate tool's own backup (belt-and-suspenders in a git repo) is redundant with git and, if staged, pollutes the migration commit — either gitignore it or remove-before-commit. Candidate: teach the tool to write the backup OUTSIDE the repo (or to a gitignored path) rather than under `workflow-system/`.
- [SURFACED-2026-07-21] **SCOPE DISCOVERY (operator decision needed) — the MOVED dirs' own internal contents were NOT in the 58-file sweep** (they moved wholesale via git mv; only *external* references were rewritten). `workflow-system/state/` internal contents = 0 stale refs (clean). But `workflow-system/product/` has 6 docs with internal `docs/product/|workflow/` refs (transitions 11, arch 18, research 12, vision 4, roadmap 3) — a **MIX** requiring per-ref human judgment, NOT a mechanical sweep: (A) LIVE operational prose describing *current* behavior → SHOULD update (e.g. vision.md "state lives in `workflow/wip/`", transitions.md "log to `workflow/backlog.md`"); (B) HISTORICAL/subject-matter refs that MUST NOT be rewritten — rewriting falsifies the record (arch.md AD-1 migration mapping "`docs/product/*` → `workflow-system/product/`"; research.md Option-A/blast-radius table; roadmap M7 goal; the CLAUDESK-UNIFY SURFACE — all describe the OLD layout as the problem-being-solved). Autopilot deliberately did NOT auto-resolve this — paused to operator. See the two backlog SURFACEs.
- [SURFACED-2026-07-21] P1.5 sweep EXCLUSIONS (scope decision): `tests/results/*.json` (gitignored, regenerable test output) and `tests/sessions/*.jsonl` (a Tier-2-audited FROZEN historical session capture — its commit msg says "abandon single-shot replay harness"; nothing consumes it; rewriting would falsify the 2026-05-16 record + invalidate the AUDIT-LOG.md signoff). Both correctly left on old paths.
- [SURFACED-2026-07-21] P1.5 harness half-migration BUG caught + fixed: `tests/run-tests.sh:178` `mkdir`'d `$tmpdir/docs/product` but line 210 (swept) copies fixtures into `$tmpdir/workflow-system/product/` — the mkdir was updated to match. Prose dir-name residues (4 in CLAUDE.md/CLAUDE.snippet.md that the trailing-slash-anchored pattern skipped) also hand-fixed.
- [SURFACED-2026-07-21] WP2b cross-project run — operator is actively working in `neo-stayman-assistant` (#4) concurrently. **Before WP2b migrates ANY project, ping the operator to pause/commit in-flight projects (#4 neo-stayman, #7 GNIE).** WP2b is gated behind WP2a + the tool build, so this coordination pause happens later, not now — operator does NOT need to stop work yet. Reinforces the per-project pre-risky-action rule in D4.
