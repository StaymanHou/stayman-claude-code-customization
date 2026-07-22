---
stage: wbs
state: complete
updated: 2026-07-21
progress: 6/8 top-level WPs done (WP1, WP2, WP3-M7, WP4, WP5, WP6); WP7 now decomposed into M11 sub-WPs (WP7a–WP7e); WP8 pending
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

> **⚠️ REFRAME 2026-07-21 (operator):** WP5 and WP6 are **NOT quick wins** despite small implementation surfaces. Both are fundamentally **terminology-design** work — the *word* we settle on ("pause" vs. course-correct; "research" vs. deep-research) is the deliverable, and it must be agreed with the operator AND legible to a **brand-new user who has none of the nuance we carry**. So both are **brainstorm-first / align-on-terminology-then-implement** (closer to WP7's shape than to a mechanical task). Do NOT start either with `/feature-plan` or `/task-plan` directly — open a terminology-alignment discussion first, agree the vocabulary, THEN plan the (likely small) edit. Sizes below refer to the *implementation* only; the design conversation is the real cost.

### WP5: Disambiguate "pause" (Milestone 9) ✅ SHIPPED 2026-07-21 (commit f532b4d)
**AS-BUILT (2026-07-21):** The terminology-alignment discussion (grounded in a 387-turn / 11-project raw-log audit → the two "pause" intents, plus two live misfires caught during the feature itself) settled the vocabulary and delivered beyond the original disambiguation-first stub. **Renamed 3 session skills** (history-preserving `git mv`, S-IDs unchanged): `session-pause`→`session-handoff`, `session-resume`→`session-restore` (kills the built-in `/resume` collision), `session-store-learning`→`session-capture` (kills the `/re**stor**e` fuzzy-collision). Added a turn-vs-session-boundary disambiguation table + a **CONTEXTUAL agent-side guard** (auto-chain the handoff at a clean workflow boundary; confirm only on mid-workflow ambiguity — keyed on workflow position, not a universal confirm) to `session-handoff/SKILL.md`, all 4 orchestrator AGENTS.md, and a new `## Session vocabulary — turn vs. session boundary (GLOBAL)` rule in `CLAUDE.snippet.md` (+ a `CLAUDE.md` pointer). Load-bearing lesson pinned: **the harness fuzzy-matcher searches DESCRIPTIONS, not just names** (reframed incident-mitigate/session-handoff/session-reflect descriptions so only `session-restore` matches "restor"). Also codified the `/resume`-is-turn-level anti-trigger (going-offline family) after a live misfire. `/project-handoff` reserved for the cross-repo analogue. `tests/check-structure.sh` [Phase 17] (14 pins, 452/0) + 2 behavioral scenarios (S26/S27, execution deferred on the known `--id` harness bug). 3 SURFACEs logged (install.sh orphan-prune ×; `--id` parse-all escalated). Resolves `SURFACE-2026-07-20-CLAUDESK-PAUSE-AMBIGUITY`.
**Description:** AD-4 — pure prompt-convention. Reserve bare "pause" for course-correction; require explicit `/session-pause` (or a distinct phrase) for the skill; orchestrator confirms intent when ambiguous. Edit the relevant orchestrator `agents/*/AGENTS.md` + `session-pause`/`session-resume` SKILL.md prose; add a behavioral scenario for the ambiguous-input case. Honor the state-machine-in-three-places sync rule only if any transition prose changes (expected: none — behavior within existing states).
**Milestone:** 9 · **Dependencies:** none (independent) · **Size:** S (implementation) — **terminology-alignment discussion required first (see REFRAME above)**
**Likely shape:** terminology-alignment discussion → then a small feature or task. The vocabulary (and how it reads to a new user) must be agreed before planning.

### WP6: Resolve "research" skill collision (Milestone 10) ✅ SHIPPED 2026-07-21 (commit 17fe152)
**AS-BUILT (2026-07-21):** The terminology-alignment discussion (grounded in a 14-day audit of all 602 machine session logs → 8 real research invocations) reframed the problem: the three names never misroute by *topic* (the model disambiguates by workflow layer), so **no rename** was needed. The real bite is a **cost-tier jump** — an ambiguous "do some research" silently escalating to the heavyweight built-in `deep-research` harness when a quick web lookup was wanted (operator's C/E fence cases). Delivered beyond the original disambiguation-first stub: a **new standalone `quick-research` skill** (light web pass + per-claim confidence labels + known-unknowns list + human-confirmed escalation gate that NEVER auto-launches deep-research, even in autopilot), a global `## Research cost tiers (GLOBAL)` rule in `CLAUDE.snippet.md`, orchestrator reinforcement in both `agents/{feature,product}-workflow/AGENTS.md`, sharpened (not renamed) `product-research`/`feature-research` descriptions, `tests/scenarios/research.yaml` (2 behavioral scenarios) + `check-structure.sh` [Phase 16] (11 pins). 438/0. Also fixed a pre-existing [Phase 15] failure inline. 3 MINOR quality findings backlogged.
**Description:** AD-3 — disambiguation-first. Sharpen `product-research` + `feature-research` `description:` frontmatter to read unambiguously workflow-scoped (they run *inside* a workflow state, not "research the web"); add orchestrator disambiguation prose. Rename is fallback-only (if renamed, the three-places sync + scenarios + CLAUDE.md all update — flagged, not planned unless disambiguation proves insufficient).
**Milestone:** 10 · **Dependencies:** none (independent) · **Size:** XS–S (implementation) — **terminology-alignment discussion required first (see REFRAME above)**
**Likely shape:** terminology-alignment discussion → then a task (description-wording edit + orchestrator prose). The naming (and its legibility to a new user unaware of the workflow-vs-CC-deep-research nuance) must be agreed before planning.

### WP7 → Milestone 11: New-user onboarding — DECOMPOSED (co-design complete 2026-07-21)

> **WP7 grew from a design-spike stub into a full milestone.** The WP7.1 brainstorm (the mandatory operator co-design pause point) is **DONE** — settled shape in `workflow-system/product/onboarding-brainstorm.md` + roadmap M11 "Revision 2026-07-21". The operator chose **FULL BUILD** (not spec-only): the WBS below carves M11 into build-WPs WP7a–WP7e. AD-5 predicted exactly this ("onboarding shape is a WBS/brainstorm output, not an arch decision") and the co-designed shape (a dedicated skill + a greenfield scaffold, no new runtime, no architectural surface) lands **inside AD-5's envelope** — so this is a normal decomposition, **not a P8 arch back-loop**. AD-5 gets a light as-built resync at `/product-context` / finalize time (deferred→designed→built).
>
> **Design invariants carried from the brainstorm (bind every sub-WP):** single entry point → **two fully-separate paths** (greenfield / brownfield, diverge and stay diverged); **entry recommends greenfield as the first-timer DEFAULT with brownfield a first-class PEER** (a default, not a funnel — greenfield is the reliable high-fidelity path, brownfield is one keystroke away, never gated behind the tutorial); the **greenfield tour is a NARRATED REAL RUN, honestly labeled** (~10–15 min, real reasoning + real skills, each beat pre-framed — NOT a faked/scripted demo reel; canning the grounding/verify-self/SURFACE beats would defeat the exact ahas the skeptic cares most about; **no "5-min" claim**); **greenfield ships a tiny RUNNABLE scaffold** hosting the **staged SURFACE beat** AND the **staged verify-self grounding beat** (runnable so verify-self has an observable outcome to check); **brownfield is bring-your-own real code** (`/init` → product-workflow reverse-engineers vision/roadmap/arch → `product-context` revises the generated `CLAUDE.md`), **NO demo**; walkthrough **opens recommending bypass-permissions universally** (+ reassurance copy); **first run stays stepping/orchestrated so the human-pause beat is visible**; **drive-modes are the LAST, un-pushed graduation reveal**; **handoff→restore is the staged emotional-peak bookend**; **grounding** ("the workflow checks reality instead of guessing" — probe-first/verify-self/`init`-reverse-engineer) is **staged greenfield (verify-self) / named brownfield**; **"don't force it"** — only authentically-stageable beats (A state-is-a-file, B human-pause, greenfield-verify-self-grounding, greenfield-SURFACE, handoff/restore, drive-modes reveal) are guaranteed staged; C-brownfield / grounding-brownfield / hierarchy-brownfield / reflect-capture are named/opportunistic.
>
> **Repo conventions binding all sub-WPs:** no-runtime (prompt/markdown/skill/scenario/pin edits only); **state-machine-in-three-places sync** (`transitions.md` / SKILL.md / scenarios) for any transition the entry skill introduces; **path-qualification mandate** (`~/.claude/` vs `<proj-dir>/.claude/`, never bare); re-run `install.sh` after any new skill dir (and note `SURFACE-2026-07-21-INSTALL-SH-NO-ORPHAN-PRUNE` — install.sh is additive-only).

#### WP7a: Onboarding flow spec (the written per-path flow)
**Description:** Author the onboarding flow spec doc: per-path (greenfield / brownfield) first-run flow, the aha beats + their ordering, the "don't force it" staged-vs-named disposition table, and the **surface contract Claudesk renders against + when it points at the entry command**. This is simultaneously (i) the design contract WP7b–WP7d build against and (ii) the **M12 return-contract deliverable** (feeds WP8). Promote/refine `onboarding-brainstorm.md` into this durable spec.
**Milestone:** 11 · **Dependencies:** brainstorm complete (done) · **Size:** S–M
**Tasks:**
- [ ] 7a.1 Write the per-path flow (greenfield spine + brownfield spine) with the aha beats mapped to each step
- [ ] 7a.2 Write the Claudesk surface contract (what Claudesk shows, when it points at the entry command, what it must NOT hardcode)
- [ ] 7a.3 Settle the entry-skill name + category (`session-*` vs new vs `util-*`) — decided here so WP7b builds against a fixed name
- [ ] 7a.4 Settle the bypass-permissions reassurance copy (the one-line "why it's safe")

#### WP7b: The entry skill (single entry → two separate paths)
**Description:** Build the dedicated onboarding entry skill (`skills/<name>/SKILL.md`): a single entry point that asks new-vs-existing, then runs the **greenfield** arm or the **brownfield** arm, each staging its own beats per the spec. Brownfield arm scripts the `/init` → product-workflow-reverse-engineer → `product-context`-revises-`CLAUDE.md` sequence against the user's real code. Greenfield arm drives top-of-hierarchy entry + the hierarchy taste. Opens with the universal bypass-permissions recommendation. Keeps the run in stepping/orchestrated so the human-pause beat is visible; ends with the drive-modes graduation reveal.
**Milestone:** 11 · **Dependencies:** WP7a (name + flow settled) · **Size:** M
**Tasks:**
- [ ] 7b.1 SKILL.md scaffold + frontmatter (name/description per path-qualification + fuzzy-matcher-description-collision discipline from WP5)
- [ ] 7b.2 Entry + path-fork (new-vs-existing) with **greenfield recommended-default / brownfield first-class peer** framing (a default, not a funnel) + universal bypass-permissions recommendation + reassurance copy + the honest ~10–15-min narrated-real-run expectation (no "5-min" claim)
- [ ] 7b.3 Greenfield arm as a **narrated real run** (per-beat pre-framing): top-of-hierarchy entry, hierarchy taste, staged SURFACE beat + staged verify-self grounding beat driving the WP7c runnable scaffold, A/B/G beats
- [ ] 7b.4 Brownfield arm (`/init` → reverse-engineer → `product-context` revise; A/B/G beats; SURFACE named-only)
- [ ] 7b.5 Any transition surface the skill introduces → three-places-in-sync (`transitions.md` + SKILL.md + scenarios); if it emits no transition (util-*/session-* meta-op), document that explicitly. Re-run `install.sh`.

#### WP7c: Greenfield scaffold (runnable) + planted authentic tangent
**Description:** Build the tiny shipped greenfield scaffold the onboarding drops the user into (fixture dir copied in, or a scaffolder that seeds a temp dir — decide at plan time). Two hard constraints from the brainstorm: (1) it must contain a **planted, authentic-feeling tangent** so the **staged SURFACE beat fires reliably** without feeling fake; (2) it must be **RUNNABLE with at least one observable outcome** so the **staged verify-self grounding beat** has something real to observe (agent runs it, reports PASS/FAIL — user watches it *check* reality). Greenfield-only (brownfield is BYO real code — no scaffold). Must be maintainable (it rides path/skill/layout changes — keep it minimal so it doesn't rot; cf. M7 moved every folder). Balance minimal-so-it-doesn't-rot against runnable-enough-to-verify.
**Milestone:** 11 · **Dependencies:** WP7a (what the beats need) · **Size:** S–M
**Tasks:**
- [ ] 7c.1 Decide scaffold delivery (shipped fixture dir vs. temp-dir scaffolder) + where it lives in-repo; decide the minimal runnable shape + its observable outcome (for verify-self)
- [ ] 7c.2 Author the minimal runnable scaffold content + the planted tangent that makes SURFACE authentic
- [ ] 7c.3 Wire WP7b's greenfield arm to drop the user into it + trigger the staged SURFACE beat AND the staged verify-self grounding beat

#### WP7d: Staged-beats wiring (bookends + graduation)
**Description:** Wire the beats that are choreography rather than plain skill invocations: the **handoff → restore emotional-peak bookend** (run `/session-handoff`, simulate/enact leave, `/session-restore` restores full context), the **drive-modes graduation reveal** (LAST, explicitly un-pushed — "not recommended yet"), and **verify-pause visibility** (ensure the onboarding run stays in stepping/orchestrated so beat B is seen, never autopilots past it). Also the **named-at-close** pointers (hierarchy, reflect-capture-learns-you).
**Milestone:** 11 · **Dependencies:** WP7b (arms exist to wire into) · **Size:** S
**Tasks:**
- [ ] 7d.1 Handoff→restore bookend choreography (both paths)
- [ ] 7d.2 Drive-modes graduation reveal at the end (un-pushed framing)
- [ ] 7d.3 Verify-pause-visibility guard (stay stepping/orchestrated during the tour) + the named-at-close pointers

#### WP7e: Behavioral scenarios + structural pins
**Description:** Cover the onboarding: behavioral scenario(s) for the entry skill's path-fork + the staged beats (using the established scenario shape — `transition_id` / `contains_any`→SOFT_PASS for prose-behavior beats), and `tests/check-structure.sh` structural pins for the new skill's required sections + the "don't force it" invariants + (if any) the transition surface. Mirror the WP5/WP6 codify shape.
**Milestone:** 11 · **Dependencies:** WP7b–WP7d · **Size:** S–M
**Tasks:**
- [ ] 7e.1 Behavioral scenarios (path-fork; staged-beat presence; bypass-permissions-recommended; drive-modes-reveal-is-last)
- [ ] 7e.2 `check-structure.sh` structural pins (new skill sections; staged-vs-named invariants; three-places if a transition was added)
- [ ] 7e.3 Full-group behavioral run green (subject to the `--id` harness path — now fixed by the boundary-handoff Phase 3)

**M11 sub-WP ordering (WP7a → WP7b → {WP7c ∥ WP7d} → WP7e):** spec first (WP7a fixes the name + flow every other sub-WP builds against — resolves the cheapest-to-change unknown first); then the entry skill (WP7b, the spine); WP7c (scaffold) and WP7d (bookend/graduation wiring) can proceed in parallel once the arms exist; WP7e codifies last. No probe WP (no external integration, no unknown API shapes — the "unknown" was the *design*, resolved by the brainstorm). No environment/orchestration WPs (no such surface). **AD-5 as-built resync** (deferred→built) happens at `/product-context` or finalize, not as its own WP.

### WP8: Cross-repo return contract to Claudesk (Milestone 12)
**Description:** M12 — send back the three deliverables Claudesk's M10.9/M11 need: (1) canonical install-instruction copy + install/uninstall commands (from WP4.5), (2) the settled doc-folder layout (from M7 WP3-M7 — **now Option A: the new roots `workflow-system/product/*.md` + `workflow-system/state/...`; Claudesk M11's `docs_list` MUST be updated to glob these** — a required change, not an optional note), (3) the onboarding flow spec (from WP7.2). Delivered as a reciprocal handoff doc or a backlog SURFACE in `/Users/stayman/Personal/projects/claudesk`.
**Milestone:** 12 · **Dependencies:** M7 + WP4 + WP7 (aggregates their deliverables) · **Size:** S
**Likely shape:** a task (authoring + delivering the note). Detailed at its own `/task-plan`.

---

## Dependency Map & Critical Path

```
M7: WP1 (decide layout+migration) → WP2 (sweep + migrate tool + run) → WP3-M7 (resync/capture)
                                                                          → WP4 (uninstall) → ... → WP8 (return contract)
                                        ┌→ WP5 (pause)      [DONE]
                                        ├→ WP6 (research)   [DONE]
                                        └→ M11 (onboarding — brainstorm DONE, now FULL BUILD):
                                             WP7a (flow spec) → WP7b (entry skill) → {WP7c scaffold ∥ WP7d beats-wiring} → WP7e (scenarios+pins)
                                             WP7a's spec feeds WP8
```

- **Critical path:** WP1 → WP2 → WP3-M7 → WP4 → **WP7a → WP7b → WP7c/WP7d → WP7e** → WP8. (WP7a's onboarding-spec gates WP8; WP4 gates WP8 on the install-copy deliverable; M7 gates WP8 on the settled-layout deliverable.)
- **M11 internal critical path:** WP7a → WP7b → WP7e (WP7c and WP7d parallelize between WP7b and WP7e).
- **Parallel track:** WP5 (pause) and WP6 (research collision) — DONE (both shipped 2026-07-21).
- **Operator pause points:** WP7.1 onboarding brainstorm — **DONE 2026-07-21** (co-design settled; `onboarding-brainstorm.md`). Remaining M11 pause points are the normal per-feature plan-review + verify-human gates as each sub-WP runs through the feature workflow. AD-1 Option A operator-ratified.

## Ordering rationale
- **M7 before everything** — the settled layout (Option A physical roots) is what every later WP and the return contract reference (AD-1). WP1 (decide) before WP2 (sweep) resolves the riskiest unknown (existing-project migration) cheaply before the wide mechanical change.
- **WP4 (uninstall) after M7** — uninstall must be written against the *settled* post-move layout, not the pre-move one.
- **WP4 before WP8** — the install/uninstall command copy is a return-contract deliverable.
- **WP5/WP6 unordered** — no learning or build dependency; smallest items, safe to interleave; do NOT block on M7. (Both DONE.)
- **M11 last-but-one** — brainstorm-first (DONE), depends on settled layout + install flow; now FULL BUILD, decomposed WP7a–WP7e. Internal order = spec-first (WP7a fixes the name/flow everything builds against), then the entry-skill spine (WP7b), then scaffold ∥ beats-wiring (WP7c/WP7d), then codify (WP7e). WP7a's spec feeds WP8.
- **WP8 terminal** — aggregates deliverables back to Claudesk (**including the required M11 `docs_list` path change** + the onboarding flow spec from WP7a).
- No environment/Docker WP (this repo is host-based shell + prompt files, no services). No 3rd-party probe WPs (no external integrations). No orchestration/async WPs (none in scope). **No M11 probe WP** — the only unknown was the *design*, resolved by the brainstorm; the sub-WPs are all build. Deviations from the standard ordering sequence are all "N/A — no such surface in this cycle."

## Session Handoff — 2026-07-21 23:30
Handed off. See `workflow-system/state/.session.md` to restore.
