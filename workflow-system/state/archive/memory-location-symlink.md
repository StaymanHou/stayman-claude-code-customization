# Feature: Project-memory location symlink

**Workflow:** feature
**State:** COMPLETED 2026-07-03 (shipped d173bd7, finalized)
**Created:** 2026-07-03
**Entry:** spec (complex feature)
**drive_mode:** autopilot
**Source:** SURFACE-2026-07-03-MEMORY-LOCATION-SYMLINK (workflow/backlog.md); full design + rejected alternatives in `tmp/temp-wbs-reflect-memory.md`
**Sibling:** Feature 2 of the reflect/store split (Feature 1 = reflect-store-filter-rules, shipped 2026-07-03 @ 090f5ba). Deliberately decoupled — F1 was prompt-only/low-risk; F2 is an environment change, spike-gated.

## Problem Statement

Project memories written by `session-store-learning` are split across two physical directories, and neither location alone gives both durability and auto-load:

- **Repo store** `<proj-dir>/.claude/memory/` — git-tracked, coupled to the code it describes, survives machine changes. But the harness does **not** auto-load it at session start.
- **Harness store** `~/.claude/projects/<slug>/memory/` — auto-loaded into context at every session start (this is where `MEMORY.md` comes from). But it is machine-local, untracked, and keyed on a brittle path-derived project slug.

An audit found **81 memory files** sitting in the harness store across 10 projects (provenance-confirmed as `session-store-learning` outputs via `originSessionId` frontmatter) — durable knowledge that is invisible to git and lost on machine migration or slug drift.

The proposed fix (**Direction A**): make the repo dir the single real, git-tracked store, and turn the harness store path into a **symlink** pointing at it. One physical copy → version-controlled *and* auto-loaded, no drift. This is contingent on the harness tolerating a symlinked memory directory — hence the spike gate.

## User Stories

- As the operator, I want project memories written by `session-store-learning` to be **both** git-tracked (durable, reviewable, portable) **and** auto-loaded by the harness at session start, so I stop losing captured learnings to the untracked harness store.
- As a future session in any project, I want to read the same memory files the last session wrote, regardless of which physical path the harness or the skill used, so knowledge accumulates instead of forking.
- As the operator, I want existing memories currently stranded in the harness store (81 files, 10 projects) migrated into the tracked repo store without losing or silently overwriting drifted duplicates.
- As a brand-new project (that may never run the product workflow), I want the memory symlink to get created without me having to remember a manual step.

## Acceptance Criteria

The feature is done when:

- **(Spike, gating)** It is empirically confirmed on a throwaway project whether the harness tolerates `~/.claude/projects/<slug>/memory` being a symlink to a real directory — specifically that (a) an auto-memory / `session-store-learning` write **follows the link** (lands in the target dir; does not clobber, atomic-rename-replace, or recreate the symlink as a real dir), and (b) a session-start **read** loads memories through the link. The spike PASS/FAIL is recorded in the WIP with the exact commands run and observed behavior.
- **(Design fork resolved)** If the spike PASSES → Direction A proceeds. If it FAILS → the feature back-loops and re-plans around a fallback (split-by-type or dual-write), documented before any migration runs.
- **(Migration, Direction-A path)** A one-time system-wide sweep merges each project's harness-store files into its repo `<proj-dir>/.claude/memory/`, dedupes drifted duplicates per a stated conflict rule, rebuilds each `MEMORY.md` index, and replaces the harness dir with a symlink to the repo dir. The sweep is idempotent and reversible (a backup of moved files is retained until the operator confirms). **Scope = any project with a `docs/product/` dir** (operator-decided 2026-07-03); the concrete resolved list is **confirmed with the operator before any migration write** (hard checkpoint, not autopilot).
- **(Future-project wiring)** New projects get the symlink created automatically: link-creation is added to `product-context` (which already owns `.claude/` scaffolding + gitignore reconciliation), **plus** an idempotent "ensure memory link exists" check reachable from non-product entry points (task/`feature-plan` projects that never hit `product-context`).
- **(Destination rules codified)** `session-store-learning` documents that a project memory is written to the repo dir (symlinked), never raw to `~/.claude/projects/...`; this survives the structural-check + CLAUDE.md sync discipline.
- **(No regression)** Existing structural checks pass; the harness auto-memory mechanism itself is unchanged (we relocate the store target, we do not alter the mechanism).

## Research

### WP1 SPIKE — harness symlink tolerance: **PASS** (2026-07-03)

Ran on a throwaway project (`/tmp/claude-spike-symlink-<rand>`, dot-free per replay-harness convention). Set up `~/.claude/projects/<resolved-slug>/memory` as a **symlink** → a real repo-side dir seeded with `seed.md`, then drove real `claude --print` invocations to write + read + auto-load memories.

**All three required properties confirmed:**

1. **Write follows the link (no clobber).** A `claude` memory write (`spike-probe-two.md` + regenerated `MEMORY.md`) landed **in the real target dir**; the symlink was **still a symlink** afterward (`lrwxr-xr-x ... -> ...`) — the writer did NOT atomic-rename-replace or recreate the directory. Pre-existing `seed.md` + `spike-probe.md` survived untouched.
2. **Read follows the link.** A subsequent `claude` invocation read the pre-existing `spike-probe` memory's content + frontmatter through the symlink.
3. **Session-start auto-load follows the link (the decisive property).** A canary memory (`canary.md` + a `MEMORY.md` index line, magic word `XYZZY-SPIKE-9417`) placed in the real target was **auto-injected into a fresh session's context** — a new `claude --print` correctly answered the magic word with tools disabled and no file reads, citing "my loaded memory index." This proves Direction A delivers *both* durability (git-tracked repo dir) *and* auto-load (harness path resolves through the link) from **one physical copy**.

**Verdict:** Direction A is viable. No back-loop to split-by-type / dual-write. Spec holds.

### Critical finding — slug is computed from the **realpath** of cwd

First spike attempt mis-fired: I created the symlink under the *unresolved* cwd slug (`-tmp-claude-spike-...`), but the harness wrote to `-private-tmp-claude-spike-...`. On macOS `/tmp` → `/private/tmp`, and **the harness resolves cwd to its physical realpath before deriving the slug**. Slug rule confirmed: `realpath(cwd)` with every `/` and `.` replaced by `-`, leading `-` retained.

**Impact on design:** WP2 (migration) and WP3 (ensure-link check) MUST compute the slug via `pwd -P` / `realpath`, not the raw `$PWD`, or they target the wrong `~/.claude/projects/<slug>` dir. This closes the open "portable slug computation" question — and it's a real footgun, not a theoretical one (it bit the spike on the first try).

### Migration shape validated as a side effect

The spike incidentally exercised the exact WP2 migration move: harness-written `memory/` dir → merge files into the repo-side dir → `rm -rf` the harness `memory/` → replace with `ln -s <repo-dir> <harness>/memory`. It worked cleanly and subsequent writes/reads/auto-loads all flowed through. WP2's core mechanic is de-risked.

### `type:`-split question — **RESOLVED: moot under Direction A**

The prior session's open fork was "project/reference → repo vs user/feedback → harness store." Under Direction A both paths resolve to the **same physical files** via the symlink, so there is no split to make — a `type: feedback` memory and a `type: project` memory both live in the repo dir and both auto-load. The `type:` field remains useful as recall metadata (as today) but no longer drives a *location* decision. Closed — no separate handling needed.

### Plan-time framing correction — where the 81 files actually came from

Inspecting `skills/session-store-learning/SKILL.md`: it **already** writes project memories to `<proj-dir>/.claude/memory/` (the correct repo location) and explicitly forbids `~/.claude/projects/*/memory/`. So the 81 mislocated files did **not** come from this skill mis-writing — they came from the **harness's own auto-memory mechanism**, which resolves "store a memory" to its native home `~/.claude/projects/<slug>/memory/`. This sharpens the plan:

- **WP4 is mostly reinforcement, not a bug-fix.** `session-store-learning`'s destination is already right; under Direction A the harness path and the repo path become the **same physical dir** via symlink, so the harness auto-memory writes *also* land in the repo — the split dissolves without changing either writer. WP4 documents this convergence + adds structural pins; it does not re-route the skill.
- The durable win is the **symlink + migration**, which makes the harness's *existing* behavior land in a tracked location. That's WP2+WP3.

### Open decisions still to resolve at plan time

- **Migration conflict rule** for drifted duplicates (same filename, different content, in both stores): the spike used `cp -n` (no-clobber, harness-loses) but a real drift needs an explicit rule — candidates: newest-mtime-wins, keep-both-with-`-harness`-suffix + operator-adjudicate, or diff-and-pause. Lean: **keep-both-with-suffix + surface the diff** (never silently lose a divergent memory). Decide in plan.
- **Migration scope** — already operator-resolved: any project with a `docs/product/` dir; concrete list confirmed with operator before writes (hard checkpoint).
- **Ensure-link idempotency + reachability** — WP3 needs the check to (a) compute the realpath slug, (b) no-op if the link already exists and points correctly, (c) repair if the harness dir is a real (non-symlink) dir [migration-not-yet-run case], (d) be reachable from `product-context` AND a non-product entry point (candidates: `session-start`, `task-plan`, `feature-plan`). Decide the exact host(s) in plan.

## Out of Scope

- Changing the harness auto-memory **mechanism** itself — F2 changes where `session-store-learning` writes project memories and where the harness store *points*, not how the harness loads memory.
- The `session-reflect` proposal filter / scoping / 3-tier presentation — that was Feature 1, already shipped.
- The `session-store-learning` **global-draft** path to `<proj-dir>/.claude/learnings/` — stays as-is.
- The artifact-tracking policy and this repo's track-`.claude/` override — stays as-is.
- `install.sh` — explicitly **not** the vehicle: wrong scope (it links *this* repo's skills into `~/.claude/`; the memory link is per-*consuming*-project) and wrong trigger (machine setup, not new-project creation).
- The harness's own auto-memory home for non-project use — untouched.

## Technical Constraints

- **No 3rd-party dependency** — 3rd-party probe check skipped (this is a filesystem/symlink + skill-prose feature; no external service/API/SDK).
- **Environment change, not prose-only** — unlike Feature 1, this alters the on-disk layout of the harness memory store on the operator's machine and across ~10 existing projects. Higher risk class; migration must be reversible.
- **Slug brittleness** — the harness store path derives the `<slug>` from the project's absolute path (e.g. `-Users-stayman-Personal-projects-my-claude-code-customization`). The symlink target and any ensure-link check must compute the same slug the harness uses.
- **`product-context` is the scaffolding owner** but is only reachable via the product workflow; task/feature-only projects never hit it — hence the separate idempotent ensure-link check (a real gap, not redundancy).
- **Symlink-in-git caveat** — under Direction A the repo dir is the real dir (tracked normally); the symlink lives under `~/.claude/projects/...` which is outside any repo, so git never sees a symlink. (This is exactly why Direction B — repo *is* the link → harness — was rejected: it would commit a useless home-dir-absolute symlink and still not version content.)
- **This-repo dogfood note** — mccc's own memory currently lives at `~/.claude/projects/-Users-stayman-Personal-projects-my-claude-code-customization/memory/` (the harness store) AND the repo tracks `<proj-dir>/.claude/memory/` per the artifact-tracking override. Migration must reconcile these two for this very repo.

## Open Questions

- [x] **(BLOCKING GATE — spike)** Does the harness tolerate a symlinked `~/.claude/projects/<slug>/memory`? **RESOLVED: PASS (2026-07-03).** Writer follows the link, no clobber; read + session-start auto-load both follow the link. See `## Research → WP1 SPIKE`. Direction A viable.
- [ ] Migration **conflict rule** for drifted duplicates — carried to plan (lean: keep-both-with-suffix + surface diff; see Research → Open decisions).
- [x] Migration **scope**: **RESOLVED (operator, 2026-07-03)** — migrate any project that has a `docs/product/` dir (i.e. a real workflow-convention project). This principled boundary naturally excludes scratch/copy dirs (test-proj, yitang-copy, gospelherald) and answers the temp-WBS "active-only vs all" open question. **HARD CHECKPOINT:** the concrete resolved project list MUST be confirmed with the operator before any migration write runs — not an autopilot step.
- [x] Does the `type:`-split question still matter under symlink? **RESOLVED: moot under Direction A** (both paths → same physical files; `type:` stays recall metadata, not a location driver). See Research.
- [x] Portable slug computation? **RESOLVED: realpath-derived** (`pwd -P` with `/` and `.` → `-`). See Research → Critical finding. Which entry point(s) host the ensure-link check → carried to plan.

## Work Tree

- [x] Phase 1: Ensure-link primitive + migration script (the core mechanic)  <!-- status: complete -->
  **Rationale:** Build the reusable, idempotent, realpath-based link primitive FIRST, tested standalone. Both WP2 (migration) and WP3 (wiring) depend on the exact same slug-computation + link-creation logic — factoring it once avoids the realpath footgun being re-implemented (and re-broken) in two places. Ship it as a committed shell script in the repo (`tools/memory-link/`) that later phases invoke and skills reference.
  **Observable outcomes:**
  - CLI: `tools/memory-link/ensure-memory-link.sh <proj-dir>` on a project whose harness dir does NOT exist → creates `~/.claude/projects/<realpath-slug>/memory` as a symlink → `<proj-dir>/.claude/memory` (created if absent); exits 0; `readlink` of the harness path resolves to the repo dir.
  - CLI: re-running the same command (idempotency) → exits 0, no change, prints an "already linked" line; `readlink` unchanged.
  - CLI: slug is computed via `pwd -P`/`realpath` — a project reached through a symlinked path (e.g. `/tmp` → `/private/tmp`) resolves to the `-private-...` slug, NOT the raw-`$PWD` slug (regression guard for the spike footgun; assert via a test that passes a symlinked path and greps the created harness dir name).
  - CLI: the migration script `tools/memory-link/migrate-memory.sh <proj-dir>` on a project with a REAL (non-symlink) harness `memory/` dir containing files → merges files into repo `<proj-dir>/.claude/memory/`, applies the conflict rule for drift, rebuilds `MEMORY.md`, backs up moved files under `<proj-dir>/.claude/memory/.migration-backup-<date>/`, then replaces the harness dir with the symlink; exits 0; idempotent on re-run.
  - CLI: conflict rule — given a same-named file with DIFFERENT content in both stores, the script keeps BOTH (repo original + harness copy renamed `<name>.harness.md`) and prints a `DRIFT:` line naming the file; never silently overwrites (assert via a seeded-drift fixture).
  - [x] P1.1 Write `tools/memory-link/ensure-memory-link.sh` — realpath slug computation (`pwd -P`, `/`+`.`→`-`, leading `-`), idempotent symlink creation, repair path (harness dir exists as real dir → defer to migrate; harness is a wrong-target symlink → re-point), dry-run flag. **Slug logic factored into `lib-slug.sh` (sourced by both scripts).**  <!-- status: complete -->
  - [x] P1.2 Write `tools/memory-link/migrate-memory.sh` — merge harness→repo, drift conflict rule (keep-both `.harness.md` + `DRIFT:` surface), `MEMORY.md` rebuild, timestamped backup, reversible, idempotent  <!-- status: complete -->
  - [x] P1.3 Add `tools/memory-link/README.md` — what the scripts do, the realpath-slug footgun called out prominently, reversal instructions  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete — bash -n clean; 10/10 scoped CLI outcome checks pass (fresh link, idempotency, realpath guard, drift keep-both, backup, MEMORY.md rebuild, migration idempotency, NEEDS-MIGRATION exit 3); no stray harness dirs leaked. Full check-structure.sh deferred to Phase 3 (this phase adds no skill/pin structure). -->
  - [x] verify-self  <!-- status: complete — subagent verified all 6 CLI observable outcomes PASS against real filesystem state (fresh link, idempotency, realpath-slug guard, migration merge+backup+MEMORY.md rebuild, drift keep-both, migration idempotency); cleanup confirmed, no harness-store pollution. No integration boundary (isolated new artifacts under tools/). -->
  - [x] verify-human  <!-- status: complete — AUTO-SKIP (F11) per drive_mode=autopilot; auto-skip gate clean (no integration boundary, isolated new artifacts under tools/, verify-self 6/6 PASS). Affirmation block printed in chat with read-time veto offer (Phase 2 will run these scripts against real memories). -->
  - [x] verify-codify  <!-- status: complete — permanent E2E test `tools/memory-link/test/run-tests.sh` (22 assertions) covers fresh link, idempotency, realpath-slug footgun regression guard, migration merge/drift-keep-both/backup/MEMORY.md-rebuild, migration idempotency, NEEDS-MIGRATION exit 3, no-clobber, dry-run. 22/22 pass, trap-cleaned (no harness pollution). No integration boundary. No test failures → no triage. -->

- [x] Phase 2: System-wide migration sweep (operator-gated execution)  <!-- status: complete -->
  **Rationale:** Run the Phase-1 migration script across the real projects. Scope = any project with a `docs/product/` dir (operator-decided). HARD CHECKPOINT: enumerate the concrete list and confirm with the operator BEFORE any write. This phase mutates ~real projects on the machine, so it is the highest-risk phase and its verify-human is non-skippable.
  **Observable outcomes:**
  - CLI: a discovery command lists every candidate project = those with a `docs/product/` dir under the known project roots; the list is printed for operator confirmation (HARD CHECKPOINT — no write before confirm).
  - CLI: after the sweep, for EACH confirmed project: `readlink ~/.claude/projects/<realpath-slug>/memory` resolves to that project's `<proj-dir>/.claude/memory`; the repo dir contains the union of both prior stores; a `.migration-backup-<date>/` exists.
  - CLI: `git status` in each migrated repo shows the newly-merged memory files as tracked additions (durability win realized); no file count regression vs the pre-migration union.
  - CLI: re-running the sweep is a no-op (idempotent) — every already-linked project prints "already linked", exits 0.
  - [x] P2.1 Discovery + enumerate candidate projects (has `docs/product/`); print list  <!-- status: complete — 9 candidates found (all git repos). -->
  - [x] P2.2 **HARD CHECKPOINT** — present concrete list to operator, get explicit confirm before any write  <!-- status: complete — operator confirmed 2026-07-03: migrate ALL EXCEPT gospelherald.com.hk (8 projects). gospelherald excluded (0 repo-mem; its 5 harness files are the only copy — operator opted out of tracking them). -->
  - [x] P2.3 Run migration per confirmed project (8: areo-test-proty-1, claudesk, mccc, neo-stayman, replicator-1-0, turn-based, google-newsroom, ops-data-hub); retain backups  <!-- status: complete — all 8 migrated (incl. THIS repo reconciling its own two stores). Backups retained under each .migration-backup-2026-07-03/. Mid-sweep found+FIXED the MEMORY.md-as-index defect (see Discoveries + [FIX-2026-07-03]); repaired the 4 pre-fix projects. gospelherald excluded per operator. -->
  - [x] P2.4 Rebuild each `MEMORY.md`; spot-check auto-load in one migrated project via a fresh `claude --print` canary  <!-- status: complete — indexes rebuilt cleanly. Canary on THIS repo: fresh claude --print auto-loaded all 8 index entries THROUGH the new symlink; durability + auto-load both confirmed live. -->
  - [x] verify-auto  <!-- status: complete — bash -n clean; 27/27 permanent suite; 32/32 LIVE final-state assertions across all 8 migrated projects (symlink correct + points to repo mem + no junk file + no junk index). -->
  - [x] verify-self  <!-- status: complete — subagent verified 3/4 outcomes PASS (all 8 symlinks correct + point to repo dir; no junk MEMORY.harness.md anywhere; LIVE auto-load canary: fresh claude --print returned all 8 repo MEMORY.md entries THROUGH the symlink). The 4th "each file-bearing project retains a backup" was a FALSE BLOCKING: the 2 flagged projects (areo-test-proty-1, ops-data-hub) were LINK-ONLY (0 harness files → nothing to back up); migrate-memory.sh correctly took the ensure-link path and made no backup. Correct behavior; the outcome wording was over-universal. No integration defect. See [VERIFY-2026-07-03] in Discoveries. -->
  - [x] verify-human  <!-- status: complete — operator engaged at this pause (2026-07-03): (1) confirmed the migration list decision (gospelherald excluded); (2) raised NEW directive to fold the ".claude/ gitignore is random for new projects" convention into this feature. Operator confirmed: TRACK .claude/ by default + deterministic ignore-exception list, enforced in BOTH session-start ensure-link check AND product-context. This EXPANDS Phase 3 (see revised Phase 3 leaves P3.6–P3.8). Migration behavior itself approved. -->
  - [x] verify-codify  <!-- status: complete — NO new permanent test needed: Phase 2 was a one-time migration EXECUTION; its regression-worthy logic (merge/drift/backup/MEMORY.md-index) is already covered by tools/memory-link/test/run-tests.sh (27 assertions incl. 5 MEMORY.md-index guards). No integration boundary in the codify sense. Full structure check: 340 PASS / 1 FAIL — the 1 FAIL is PRE-EXISTING host settings-fixture drift (SURFACE-2026-06-26/06-30), unrelated to this feature (never touched tests/fixtures/settings.json). Triaged: not-a-regression, already backlogged. runtimes.md updated. -->

- [x] Phase 3: Future-project wiring + docs + structural pins  <!-- status: complete -->
  **Rationale:** Wire the Phase-1 ensure-link primitive into the workflow so new projects get the link automatically, then codify the convention. `product-context` §2b (already the `.gitignore`-reconciliation owner) is the product-path host; `session-start` is the non-product host (every workflow passes through it, it already reads `.session.md`). WP4 destination-rule reinforcement + CLAUDE.md/snippet sync + check-structure pins land here. **EXPANDED (operator directive 2026-07-03):** also codify the deterministic `.claude/` gitignore convention (currently random for new projects) — TRACK `.claude/` by default + a small deterministic ignore-exception list; enforce it in BOTH the session-start ensure-link check AND product-context §2b. This closes the enforcement gap: the GLOBAL artifact-tracking policy already says track-by-default, but only product-context fires it today, so task/feature-only projects drift.
  **Observable outcomes:**
  - CLI: `grep` confirms `skills/product-context/SKILL.md` invokes/references `tools/memory-link/ensure-memory-link.sh` in its scaffolding step (§2b neighborhood).
  - CLI: `grep` confirms `skills/session-start/SKILL.md` runs the idempotent ensure-link check at session entry (the non-product reachability path), guarded to no-op when already linked.
  - CLI: `grep` confirms `skills/session-store-learning/SKILL.md` documents that the project-memory dir is symlinked to the harness store (convergence note) and still forbids raw `~/.claude/projects/...` writes.
  - CLI: `grep` confirms `CLAUDE.snippet.md` (global convention) + repo `CLAUDE.md` `## Conventions` carry the memory-symlink convention; path-qualification rule respected (no bare `.claude/`).
  - CLI: `grep` confirms the deterministic `.claude/` gitignore convention is codified: `session-start` + `product-context` both reconcile `.claude/` to TRACK-by-default with the ignore-exception set (`settings.local.json`, `.session.md`, `.migration-backup-*/`, and `.claude/learnings/` for non-source-repos); the ensure-link script or a sibling helper adds `.migration-backup-*/` to the project `.gitignore`.
  - CLI: `./tests/check-structure.sh` passes with NEW pins asserting (a) product-context ensure-link ref, (b) session-start ensure-link ref, (c) store-learning convergence note, (d) snippet memory-symlink convention, (e) the gitignore-track-by-default convention present in both hosts; prints `<N>/0`.
  - [x] P3.1 Add ensure-link invocation to `skills/product-context/SKILL.md` (new §2c scaffolding step; realpath-safe, idempotent, NEEDS-MIGRATION→migrate handling)  <!-- status: complete -->
  - [x] P3.2 Add idempotent ensure-link check to `skills/session-start/SKILL.md` step 1 (non-product host); no-op when linked; surfaces NEEDS-MIGRATION without auto-migrating  <!-- status: complete -->
  - [x] P3.3 Reinforce destination rules + convergence note in `skills/session-store-learning/SKILL.md` (project Memory → repo dir which is symlinked; never raw ~/.claude/projects; type-split moot)  <!-- status: complete -->
  - [x] P3.4 Sync `CLAUDE.snippet.md` — new `## Project-memory location — harness symlink (GLOBAL)` section (convention + slug footgun + tooling/wiring + destination rule)  <!-- status: complete -->
  - [x] P3.6 **[gitignore convention]** Codified TRACK-`.claude/`-by-default + named ignore-exception subsection in `CLAUDE.snippet.md` artifact-tracking policy. **CORRECTED per operator (2026-07-03):** the transient `.migration-backup-*/` is NOT added to any permanent ignore set (would occupy every session's context) — migration is finalized in-session (backups deleted) instead. Exception set = settings.local.json + learnings/ (non-source-repos) only.  <!-- status: complete -->
  - [x] P3.7 **[gitignore convention]** BOTH hosts reconcile TRACK-by-default: `product-context` §2b canonical block gained a "`.claude/` is tracked by default; this block is the complete `.claude/` ignore set; never blanket-ignore" note; `session-start` step 1 gained a light gitignore-posture check alongside the ensure-link call. **CORRECTED:** dropped the "ensure-link appends backup-dir ignore" sub-task (backups are transient, deleted in-session).  <!-- status: complete -->
  - [x] P3.8 **[gitignore convention]** repo `CLAUDE.md` `## Conventions` bullet — DONE together with P3.4 sync (see below, one combined bullet covering memory-symlink + gitignore-track-default)  <!-- status: complete -->
  - [x] P3.4b Repo `CLAUDE.md` `## Conventions` bullet (memory-symlink + track-`.claude/`-default convention) — the repo-local sync half of P3.4/P3.8  <!-- status: complete -->
  - [x] P3.5 Add structural pins to `tests/check-structure.sh` [Phase 14] — 13 checks: primitive files exist + executable + test suite (6), realpath-slug footgun guard (1), snippet convention section + realpath + track-.claude-default (3), both hosts wire ensure-link (2), store-learning convergence note (1)  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete — bash -n clean on check-structure.sh; 3 edited SKILL.md frontmatters parse as valid YAML; full structure check 353/1 (Phase 12 path-qualification PASS after self-regression fix; all 13 Phase 14 pins PASS; the 1 FAIL = pre-existing settings-fixture drift, unrelated). No new regression. -->
  - [x] verify-self  <!-- status: complete — subagent verified all 7 outcomes PASS: both wiring hosts (product-context §2c + session-start step 1) reference ensure-memory-link.sh; store-learning convergence note + raw-path forbiddance present; snippet has the memory-symlink section + track-.claude/-default posture + realpath footgun; CLAUDE.md convention bullet present; structure check 353/1 (only pre-existing settings drift; Phase 12 + all 13 Phase 14 PASS); memory-link primitive suite still 27/27 (Phase 3 didn't break it). Integration boundary = edited existing skill prompts; outcomes cite the consuming surfaces by name. -->
  - [x] verify-human  <!-- status: complete — operator APPROVED (2026-07-03, F13) at the final-feature gate. Integration boundary applied (edited existing skill prompts) → F11 auto-skip correctly forbidden; presented 3 judgment-call checks (live no-op wiring behavior, gitignore-convention wording, GLOBAL-policy blast-radius scope). Operator approved + asked for per-project migration-backup recap (provided in chat: 6 backup dirs created-then-deleted-in-session per finalize directive; per-project merge/link breakdown given). -->
  - [x] verify-codify  <!-- status: complete — Integration boundary (edited existing skill prompts); consuming-surface coverage = the 13 [Phase 14] check-structure.sh pins written in Phase 3 impl (assert wiring/convention contracts present in live skill/snippet/doc files) — no NEW test needed per §2 (already-covered). Regression gate: memory-link suite 27/27 + structure check 353/1. The 1 FAIL triaged = pre-existing host settings-fixture drift (SURFACE-2026-06-26/06-30), not a regression, not this feature's responsibility. ALL 3 PHASES COMPLETE → F16 ship. -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** review-quality complete. 0 CRITICAL / 2 MAJOR (both fixed in-place, amended into ship commit d181353→d173bd7) / 2 MINOR (auto-backlogged per Mode 3). Ship commit is now d173bd7. Ready for `/feature-finalize`.
- **Blocked:** none
- **Unvisited:** none
- **Ship state:** this repo d173bd7 (local, not pushed); 7 external migrated-project memory commits (local, not pushed): claudesk eaac579, neo-stayman f21733c, replicator-1-0 4535039, turn-based 57df6a0, google-newsroom ccb32da, areo-test-proty-1 0a620fd (+gitignore fix), ops-data-hub 6966d3e (+gitignore fix).
- **Blocked:** none
- **Unvisited:** none — Phase 3 is the last phase.
- **Note:** self-introduced Phase-12 path-qualification regression (2 bare .claude/ in new snippet prose) caught + fixed during impl. Structure check 353/1 (the 1 = pre-existing settings drift).
- **Gitignore-convention decision (operator-confirmed 2026-07-03):** TRACK `.claude/` by default + deterministic ignore-exception list (`settings.local.json`, `.session.md`, `.migration-backup-*/`, non-source-repo `.claude/learnings/`); enforce in BOTH session-start ensure-link check AND product-context §2b. Folded into Phase 3.
- **Blocked:** none
- **Unvisited:** Phase 3 (wiring + docs + pins — depends on Phase 1)
- **Open discoveries:** MEMORY.md-as-index defect (RESOLVED in-build, see [FIX-2026-07-03]); `viz-render-marker-collision.md` in this repo lacks a `description:` frontmatter field → "(no description)" in index (pre-existing memory-quality issue, NOT a migration defect; out of scope — could backlog).

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
- [SURFACED-2026-07-03] P2.3 (BLOCKING, found mid-sweep) — `migrate-memory.sh` treated `MEMORY.md` as a generic memory file: (1) it went through the drift/keep-both path → a junk `MEMORY.harness.md` created AND indexed as a bogus memory entry; (2) rebuilt index replaced repo's hand-curated hooks with auto-pulled `description:` frontmatter. Manifested only at Phase-2 scale (real MEMORY.md present); Phase-1 fixtures had no pre-existing repo MEMORY.md.
- [SURFACED-2026-07-03] P3 → RESOLVED in-session (operator directive) — The `.migration-backup-<date>/` dirs were untracked and would get committed. Initially I added `.claude/memory/.migration-backup-*/` to the CLAUDE.snippet.md + product-context canonical ignore set. OPERATOR CORRECTION: don't put transient-migration mechanics into CLAUDE.snippet.md (it occupies every session's context) — finalize the migration THIS session instead. Reverted both snippet + product-context ignore additions; deleted all 6 backup dirs after a byte-safety check (every backed-up memory confirmed present in its repo dir). README updated to say the backup is transient (delete once confirmed; no permanent gitignore rule). Migration is now a completed in-session op, not a standing convention.
- [VERIFY-2026-07-03] P2 verify-self — Subagent flagged a BLOCKING FAIL on "each file-bearing project retains a backup" for areo-test-proty-1 + ops-data-hub. Reclassified as FALSE BLOCKING (not back-looped): both were LINK-ONLY projects (no harness memory files existed → migrate-memory.sh correctly took the "no harness store; ensuring link only" path and created no backup — there was nothing to back up). The outcome wording assumed every project had harness files to migrate. Correct behavior; no defect. The 3 load-bearing outcomes (symlink correctness, no-junk, live auto-load) all PASS.
- [FIX-2026-07-03] P2.3 — Fixed `migrate-memory.sh`: MEMORY.md is now backed-up-then-skipped in the merge loop (never merged, no MEMORY.harness.md created); rebuild excludes both `MEMORY.md` and any stale `MEMORY.harness.md`. Added 5 regression-guard assertions to `tools/memory-link/test/run-tests.sh` (group 3b) → 27/27 pass. Repaired the 4 pre-fix projects (claudesk, neo-stayman, replicator-1-0, turn-based): deleted junk MEMORY.harness.md (verified byte-identical to the retained backup first), rebuilt indexes. Handled in-build (within Phase 2's "run migration correctly" scope) rather than F23 back-loop — the fix is a mechanical extension of the just-run migration, re-verified by the fresh permanent-suite run + a full 7-project final-state sweep.
- [SURFACED-2026-07-03] P1.1/P2/P3 — Harness slug is realpath-derived (`pwd -P`, `/`+`.`→`-`), NOT raw `$PWD`. Bit the WP1 spike on first attempt. Every slug computation in every phase must use realpath. (Logged from research.)
- [SURFACED-2026-07-03] P3.3 — `session-store-learning` ALREADY writes project memories to the correct `<proj-dir>/.claude/memory/`; the 81 mislocated files came from the harness's own auto-memory mechanism, not this skill. WP4 is reinforcement + convergence-note, not a re-route. (Logged from research.)

## Retrospect
- **What changed in our understanding:** (1) The harness derives the memory-store slug from the **realpath** of cwd, not raw `$PWD` — a footgun that bit the WP1 spike on the first attempt and shaped every phase. (2) `session-store-learning` was ALREADY writing project memories to the correct repo dir; the 81 stranded files came from the *harness's own* auto-memory mechanism, so the fix was a symlink + migration, not a skill re-route. (3) `MEMORY.md` is an index, not a memory — the migration script had to special-case it (found mid-sweep at Phase-2 scale, invisible in Phase-1 fixtures).
- **Assumptions that held:** Direction A (symlink) was viable — the WP1 spike confirmed the harness follows the link on write/read/session-start-auto-load without clobbering. The three-phase decomposition (primitive → migration → wiring) held; each phase looped independently.
- **Assumptions that were wrong:** (1) The "each file-bearing project retains a backup" observable was over-universal — link-only projects (no harness files) correctly make no backup (false-BLOCKING in verify-self, reclassified). (2) I initially put transient migration-backup gitignore rules into the GLOBAL snippet — operator corrected: finalize the migration in-session instead (don't pollute every session's context with one-time cruft).
- **Approach delta:** Front-loaded the reusable primitive as Phase 1 (the temp-WBS had migration first) so the realpath footgun was solved once, not re-implemented in two places. Mid-Phase-2 the MEMORY.md-index defect was fixed in-build (not F23) as a mechanical extension. review-quality's 2 MAJORs (both prose) were fixed in-place + amended rather than auto-backlogged, because #2 contradicted a same-session operator directive. Scope expanded mid-feature per operator: the `.claude/`-track-by-default gitignore convention folded in (Phase 3 P3.6-P3.8) + applied to 2 real blanket-ignore projects.

## Code-Quality Review — memory-location-symlink

Reviewer subagent against ship commit d181353 (drive_mode autopilot / Mode 3). 0 CRITICAL, 2 MAJOR, 2 MINOR.

### Strengths
- Realpath-slug footgun documented once in `lib-slug.sh`, DRY-sourced by both scripts, guarded 3 layers (comment + group-2 test + `pwd -P` structural pin).
- `ensure-memory-link.sh` enumerates all 5 harness-path states with distinct exit codes; conservative refuse-to-touch fallback.
- Migration safety: back-up-before-touch, keep-both drift rule, MEMORY.md-as-index special-case with its own regression guard, documented reversal.
- 27-assertion E2E suite against throwaway projects with per-slug cleanup that never touches a pre-existing store.
- Real, verified idempotency (re-run no-op, dry-run zero-change).

### Issues
**CRITICAL** — (none)

**MAJOR** — both RESOLVED in-place (see below)
- [skills/session-start/SKILL.md:76] `<workflow-system-repo>` placeholder had NO runtime resolution guidance → the non-product ensure-link check (the feature's convergence guarantee) might silently never run. **RESOLVED [REVIEW-FIX-2026-07-03]:** added resolution guidance (resolve via `git rev-parse --show-toplevel` of the symlink-resolved skill path) + a silent-skip fallback when the source repo isn't checked out.
- [skills/session-start/SKILL.md:79] gitignore prose still listed `.claude/memory/.migration-backup-*/` as ignored — CONTRADICTED the same-feature operator revert (Discoveries §180, "migration is a completed in-session op, not a standing convention") and drifted from the canonical ignore set in snippet + product-context. **RESOLVED [REVIEW-FIX-2026-07-03]:** removed the backup-dir from the session-start ignore prose; canonical set now consistently `settings.local.json` + (non-source) `learnings/` across all three surfaces.
- Both fixes amended into the ship commit (d181353 → d173bd7); structure check 353/1 holds (Phase 12 path-qualification + Phase 14 all PASS). Handled in-place rather than F40-refactor because both were trivial prose corrections and MAJOR #2 was a self-introduced contradiction of an explicit same-session operator directive (leaving it would re-seed the reverted cruft).

**MINOR** — auto-backlogged per Mode 3
- [ensure-memory-link.sh:64] Under `--dry-run` when repo target dir doesn't exist yet + harness already a symlink, comparison RHS emits a stray `cd: No such file` on stderr. Diagnostic noise only; verdict/exit correct.
- [README.md:59-63 / migrate-memory.sh:5] The "any project with a `docs/product/` dir" scope rule is prose-only; neither script enforces it. Acceptable given the operator-confirmation gate, but prose implies a guard that isn't in code.

### Assessment
Well-built systems-shell work; the load-bearing scripts are careful, DRY, regression-guarded. The realpath footgun (the one genuinely-easy-to-get-wrong thing) is defended in three layers. The debt was in the wiring prose, not the primitive — both MAJOR findings were prose-layer and are now fixed. Net: the mechanism closes a real durability/auto-load fork and advances the codebase.

### If you disagree
Dismiss any finding by editing this section and marking the line `[DISMISSED]` before finalize archives the WIP. (Both MAJORs already fixed; the 2 MINORs are backlogged — dismiss those by marking them here if you disagree.)

## Next step

Plan complete — 3 phases, each independently loopable through build → verify-auto → verify-self → verify-human → verify-codify. Phase 1 builds the reusable link/migration primitive (de-risks the realpath footgun once); Phase 2 is the operator-gated system-wide sweep (hard checkpoint before writes); Phase 3 wires future projects + codifies the convention.

Routes to **F7 → `/feature-build`** (Phase 1).

TRANSITION: F7
