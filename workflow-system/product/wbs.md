---
stage: wbs
state: complete
updated: 2026-07-21
---

# WBS — Claudesk Handoff Cycle (Milestones 7–12)

**Roadmap:** `docs/product/roadmap.md` → "Group — Claudesk Handoff Cycle" (Milestones 7–12).
**Arch:** `docs/product/arch.md` → Revision 2026-07-20 (AD-1 … AD-5).
**Research:** `docs/product/research.md`.

## Scope note — deliberate deviation from "decompose only the immediate next milestone"

The standard rule details WPs for the **next milestone only**, because later milestones are usually contingent, knowledge-blocked, and cheap to re-plan. **This cycle is a justified exception, applied narrowly:**

- All six milestones are **small, non-contingent, and knowledge-complete** — prompt/convention/shell changes with **no new runtime deps, no external-API integrations (so no 3rd-party probe WPs), and no async/orchestration layers**. The riskiest-unknown-first ordering rule has little to bite on.
- M7–M12 form **one coherent operator-scoped package** (the Claudesk handoff); forcing five more full WBS passes is process overhead disproportionate to the work.

**How the deviation is bounded:** Milestone 7 (WP1, WP2, WP3-M7) and Milestone 8 (WP4) — the sequential foundation, next-up — are **fully detailed**. WP5–WP8 (Milestones 9, 10, 11, 12 — independent or deferred) are **lightweight stubs** with clear scope but task-level detail deferred to their own feature/task planning. M11 stays a **design spike** (knowledge output), correctly NOT implementation-decomposed. This keeps the anti-speculation intent intact where it matters (M11's shape genuinely isn't known yet) while not manufacturing ceremony for the trivially-clear items.

**⚠️ M7 is now Option A (physical move), so it is materially larger** than when this scope note was first drafted (index-only): M7 grew from 2 small WPs to 3 WPs including an **L-sized 59-file sweep** (WP2). M7 alone may warrant its own `/feature-spec` rather than `/feature-plan` given the blast radius.

`design-priors.md` absent → consult is a silent no-op.

---

## Milestone 7 — Doc-layout unification (Option A: physical unification under one root)

> **AD-1 operator-ratified Option A** (2026-07-20 P8 back-loop): physically unify the two folders under one top-level root — `docs/product/*` → `workflow-system/product/`, `workflow/*` → `workflow-system/state/`. Working names; finalizable in WP1.1. The ~59-file path sweep + a required Claudesk `docs_list` change are accepted. **This is the materially larger decomposition** (vs. the superseded index-only Option B). It is a **convention change for all consuming projects**, not just this repo.

### WP1: Decide the target layout + migration strategy for existing consuming projects ✅ SHIPPED 2026-07-21 (commit 3000801)
**Type:** probe (decision output — settles the rename map + migration approach before the mechanical sweep)
**Milestone:** 7
**Dependencies:** none (first WP of the cycle)
**Size:** S
**Learning objective:** (a) Final folder/subfolder names (`workflow-system/product/` + `workflow-system/state/` proposed — confirm or adjust). (b) The exhaustive old→new rename map. (c) Does this repo's OWN `docs/product/` + `workflow/` move too (dogfooding), and is that part of the sweep or a follow-on?
**Migration is IN SCOPE (operator-confirmed 2026-07-20):** existing projects on this machine already using the workflow system WILL be migrated — not clean-break. **Reference precedent: `tools/memory-link/`** (2026-07-03 memory-location-symlink feature) — a proven template for exactly this "reusable primitive + one-time cross-project migration" shape. WP2 builds a `tools/migrate-doc-layout/` mirroring its structure and disciplines: **idempotent** (re-run = no-op), **`--dry-run`**, **timestamped reversible backup** before any move, **drift/conflict rule** (never silently overwrite), **`--date` param** for deterministic test naming (the harness-shell date footgun), a **test suite** under `tools/migrate-doc-layout/test/`, and a **README** with canonical invocations. The one-time run across the machine's existing projects mirrors memory-link's 8-project run.
**Success criterion:** a written rename map (old path → new path, exhaustive) + confirmed "migrate existing projects via a memory-link-style helper" approach, recorded in `arch.md` (as-built) before WP2 touches any file.
**Tasks:**
- [x] 1.1 Confirm/finalize folder + subfolder names; produce the exhaustive old→new rename map
- [x] 1.2 Read `tools/memory-link/` (`migrate-memory.sh` + `ensure-*.sh` + `test/` + README) as the template; enumerate the existing on-machine projects to migrate (like memory-link's project sweep) — 10 found, 9 migrated (gospelherald excluded)
- [x] 1.3 Decide whether/when this repo dogfoods the move on its own docs (and whether the migrate helper handles that too) — repo moved via plain git mv in Phase 1; helper for other projects

### WP2: Execute the path sweep across skills, agents, tests, CLAUDE docs ✅ SHIPPED 2026-07-21 (commits 6fedeb5 sweep + b455657 lock + 26e9d5f tool + e87e053 run; split into WP2a source-sweep + WP2b migration-tool as recommended)
**Description:** The mechanical heart of M7, in two parts: **(i) the source sweep** — `git mv` the directories (preserving history), then rewrite every path reference across the ~59-file blast radius (38 skills, 14 tests, 5 agents, `CLAUDE.md`, `CLAUDE.snippet.md`) to the new roots; and **(ii) the migration tool** — build `tools/migrate-doc-layout/` (mirroring `tools/memory-link/`) that moves an existing consuming project's `docs/product/` + `workflow/` to the new layout, then run it once across the machine's existing projects (WP1.2 enumeration). Honor the **state-machine-lives-in-three-places** sync rule (`transitions.md` / `SKILL.md` / scenarios) and the **path-qualification mandate** (every path reference stays explicitly qualified). Update `tests/check-structure.sh` path pins.
**Milestone:** 7
**Dependencies:** WP1 (needs the settled rename map + project enumeration)
**Size:** L (or split into WP2a source-sweep + WP2b migration-tool at feature-plan time — recommended given size)
**Tasks:**
- [x] 2.1 `git mv docs/product → workflow-system/product` and `workflow → workflow-system/state` in THIS repo (per WP1.3 dogfood decision) — 133 renames, history preserved
- [x] 2.2 Sweep path references in `skills/` (38 files) — grep-driven, per the downstream-contract-impacts discipline — path-anchored (never bare-word)
- [x] 2.3 Sweep `agents/` (5 files) + `CLAUDE.md` + `CLAUDE.snippet.md`
- [x] 2.4 Sweep `tests/` (scenarios, run-tests.sh incl. mkdir fixture-fix, check-structure.sh 12 path pins); EXCLUDED tests/results/*.json (gitignored) + tests/sessions/*.jsonl (frozen audited capture)
- [x] 2.5 Build `tools/migrate-doc-layout/` from the `tools/memory-link/` template (script + `--dry-run` + `--date` + timestamped backup + drift rule + 35-assertion `test/` suite + README)
- [x] 2.6 Run the migration tool (`--dry-run` first) across the enumerated existing on-machine projects (9 migrated, gospelherald excluded); verify each — all history preserved
- [x] 2.7 Run `tests/check-structure.sh` (420/0) + behavioral session-suite (fresh-subprocess); + added Phase-15 anti-regression lock. 3 session fails proven independent of the rename + SURFACED

### WP3-M7: Resync arch as-built + capture settled layout for the return contract ✅ SHIPPED 2026-07-21 (commit 88e8243)
**Description:** After the sweep is green, resync `arch.md` (as-built: the layout moved; new paths; migration strategy shipped) and record the settled layout + exact new discovery paths in a form the M12 return contract (WP7) can hand to Claudesk's M11.
**Milestone:** 7
**Dependencies:** WP2
**Size:** XS–S
**Tasks:**
- [x] m7.1 Resync `arch.md` AD-1 to as-built (paths moved, migration strategy chosen) — AS-BUILT subsection appended; category-B decision/mapping text preserved
- [x] m7.2 Write the settled layout + new `docs_list` glob paths for the WP7 return contract — `## Return Contract — M7 settled layout` block in the archived WIP (old→new docs_list mapping for Claudesk M11)

**WP1 → WP2 → WP3-M7 rationale:** settle the rename map + migration strategy (cheap, reversible decision) **before** the 59-file mechanical sweep (expensive, wide) — resolving the riskiest unknown (existing-project migration) first, exactly the learning-sequence discipline. Resync/capture only after the sweep is verified green.

---

## Milestone 8 — Standalone `uninstall.sh`

### WP4: `uninstall.sh` — symmetric, defensive reversal of `install.sh` ✅ SHIPPED 2026-07-21 (commit 74cbb7c)
**Description:** Per AD-2, a standalone bash `uninstall.sh` (zero Claudesk dependency) reversing each of install.sh's setup actions, reusing the same `SOURCE_DIR`/`TARGET_DIR="$HOME/.claude"` derivation and idempotency/safety contract. Defensive invariants: only `rm` a symlink when it exists AND its resolved target points *into this repo* (mirror install's "exists but not a symlink → skip" guard); excise only the marker-delimited CLAUDE.md block via the same `awk` block-delete install uses (back up first; never delete `~/.claude/CLAUDE.md` wholesale); remove the per-project memory *symlink* only (never the real store it points at — reuse `tools/memory-link/lib-slug.sh` for realpath-safe slug); only *print* the settings.json perms reminder (install only prints them, so uninstall symmetrically only prints).
**Milestone:** 8
**Dependencies:** sequence after M7 (WP1–WP3-M7) so uninstall is written against the *settled* layout — if the M7 move changes any path install.sh references (or the migrate tool adds anything to reverse), uninstall reverses the final shape, not the pre-move one
**Size:** M
**Tasks:**
- [x] 4.1 Reverse the 4 symlink kinds (skills, agents, hooks, claude-time hook.pl + CLI bin) with the target-points-into-this-repo guard
- [x] 4.2 Excise the marker-delimited `<!-- BEGIN/END claude-workflow-system -->` block from `~/.claude/CLAUDE.md` (backup first; leave the rest of the file intact; handle "file has only the block" vs "block among other content")
- [x] 4.3 Remove the per-project memory symlink safely (symlink-only, realpath-safe slug, never touch `<proj>/.claude/memory`) — `--project`-gated
- [x] 4.4 Print (do not auto-edit) the settings.json perms the user may want to remove
- [x] 4.5 Verify: `install → uninstall → re-install` round-trips clean and idempotent (the AD-2 verification target); capture canonical install/uninstall command copy for M12 — round-trip in test group 7; command copy in archived WIP `## Return Contract — M12 command copy`

**WP4 verification is load-bearing for M12:** the exact install/uninstall command copy captured in 4.5 is a deliverable in the return contract (WP8).

---

## Milestones 9–12 — lightweight stubs (task-level detail deferred to own planning)

### WP5: Disambiguate "pause" (Milestone 9)
**Description:** AD-4 — pure prompt-convention. Reserve bare "pause" for course-correction; require explicit `/session-pause` (or a distinct phrase) for the skill; orchestrator confirms intent when ambiguous. Edit the relevant orchestrator `agents/*/AGENTS.md` + `session-pause`/`session-resume` SKILL.md prose; add a behavioral scenario for the ambiguous-input case. Honor the state-machine-in-three-places sync rule only if any transition prose changes (expected: none — behavior within existing states).
**Milestone:** 9 · **Dependencies:** none (independent) · **Size:** S
**Likely shape:** a small feature or a task. Detailed at its own `/feature-plan` or `/task-plan`.

### WP6: Resolve "research" skill collision (Milestone 10)
**Description:** AD-3 — disambiguation-first. Sharpen `product-research` + `feature-research` `description:` frontmatter to read unambiguously workflow-scoped (they run *inside* a workflow state, not "research the web"); add orchestrator disambiguation prose. Rename is fallback-only (if renamed, the three-places sync + scenarios + CLAUDE.md all update — flagged, not planned unless disambiguation proves insufficient).
**Milestone:** 10 · **Dependencies:** none (independent) · **Size:** XS–S
**Likely shape:** a task (description-wording edit + orchestrator prose). Detailed at its own `/task-plan`.

### WP7: Probe — new-user onboarding + "aha" design (Milestone 11)
**Type:** probe (design spike — knowledge output, NOT software)
**Milestone:** 11 · **Dependencies:** M7 (settled layout: WP1–WP3-M7) + WP4 (settled install/uninstall flow) · **Size:** M
**Learning objective:** What is the fastest "aha" for a brand-new workflow user, what first-run path produces it, and does it need a dedicated onboarding SKILL.md and/or a throwaway tutorial project?
**Timebox:** co-design session with the operator (brainstorm-first — explicitly NOT auto-generated).
**Success criterion:** a written onboarding flow spec Claudesk can render against (what the user does first, the aha moment, the surface + when), plus a go/no-go decision on a dedicated onboarding skill and/or tutorial project.
**Tasks:**
- [ ] 7.1 Operator co-design/brainstorm session (pause point — do not auto-produce)
- [ ] 7.2 Write the onboarding flow spec (feeds M12 return contract)
- [ ] 7.3 Decide: dedicated onboarding skill? tutorial project? (if yes → spawns its own feature WP in a later WBS pass)

### WP8: Cross-repo return contract to Claudesk (Milestone 12)
**Description:** M12 — send back the three deliverables Claudesk's M10.9/M11 need: (1) canonical install-instruction copy + install/uninstall commands (from WP4.5), (2) the settled doc-folder layout (from M7 WP3-M7 — **now Option A: the new roots `workflow-system/product/*.md` + `workflow-system/state/...`; Claudesk M11's `docs_list` MUST be updated to glob these** — a required change, not an optional note), (3) the onboarding flow spec (from WP7.2). Delivered as a reciprocal handoff doc or a backlog SURFACE in `/Users/stayman/Personal/projects/claudesk`.
**Milestone:** 12 · **Dependencies:** M7 + WP4 + WP7 (aggregates their deliverables) · **Size:** S
**Likely shape:** a task (authoring + delivering the note). Detailed at its own `/task-plan`.

---

## Dependency Map & Critical Path

```
M7: WP1 (decide layout+migration) → WP2 (sweep + migrate tool + run) → WP3-M7 (resync/capture)
                                                                          → WP4 (uninstall) → ... → WP8 (return contract)
                                        ┌→ WP5 (pause)      [parallel, independent]
                                        ├→ WP6 (research)   [parallel, independent]
                                        └→ WP7 (onboarding spike) → feeds WP8
```

- **Critical path:** WP1 → WP2 → WP3-M7 → WP4 → WP7 → WP8. (WP7 gates WP8 on the onboarding-spec deliverable; WP4 gates WP8 on the install-copy deliverable; M7 gates WP8 on the settled-layout deliverable.)
- **Parallel track:** WP5 (pause) and WP6 (research collision) are fully independent — can run any time after the cycle starts, in either order, without blocking the critical path.
- **Operator pause points:** WP7.1 (onboarding brainstorm — mandatory human co-design). AD-1 Option A is now operator-ratified (no longer a veto point). WP1's rename map + migration strategy is a natural review checkpoint before the L-sized WP2 sweep runs.

## Ordering rationale
- **M7 before everything** — the settled layout (Option A physical roots) is what every later WP and the return contract reference (AD-1). WP1 (decide) before WP2 (sweep) resolves the riskiest unknown (existing-project migration) cheaply before the wide mechanical change.
- **WP4 (uninstall) after M7** — uninstall must be written against the *settled* post-move layout, not the pre-move one.
- **WP4 before WP8** — the install/uninstall command copy is a return-contract deliverable.
- **WP5/WP6 unordered** — no learning or build dependency; smallest items, safe to interleave; do NOT block on M7.
- **WP7 last-but-one** — brainstorm-first, depends on settled layout + install flow; its spec feeds WP8.
- **WP8 terminal** — aggregates deliverables back to Claudesk (**including the required M11 `docs_list` path change**).
- No environment/Docker WP (this repo is host-based shell + prompt files, no services). No 3rd-party probe WPs (no external integrations). No orchestration/async WPs (none in scope). Deviations from the standard ordering sequence are all "N/A — no such surface in this cycle."
