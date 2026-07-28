---
stage: wbs
state: complete
updated: 2026-07-27
progress: 6/8 top-level WPs done (WP1, WP2, WP3-M7, WP4, WP5, WP6); M11 sub-WPs — WP7a ✅ WP7b ✅ WP7c ✅ WP7d ✅ WP7f ✅ WP7g ✅ WP7i ✅ WP7j ✅ WP7h DESIGN ✅ (build split → WP7k) WP7k ✅; **batch hands-on acceptance run #1 ✅ 2026-07-25** (3 of 4 surfaces PASS as-shipped; greenfield drew 3 fixes → WP7l/WP7m/WP7n); **greenfield re-acceptance run ✅ 2026-07-27** (reported 2 defects → WP7o); **FINAL hands-on greenfield acceptance run ✅ 2026-07-27 — ALL FOUR PASS.** WP7l ✅ SHIPPED + WP7n ✅ SHIPPED + WP7m ✅ SHIPPED + WP7o ✅ SHIPPED (all accepted 2026-07-27; §D accepted as built — the refuse-if-non-empty + offer-to-clear behavior read as correct to the operator). **WP7e ✅ SHIPPED 2026-07-27** (commits 9a524e5 + 175492a — 68 structural pins `[Phase 19]`/`[Phase 19b]` + `tests/scenarios/tutorial.yaml`, the first scenarios ever to target a `tutorial-*` skill; also dropped the dead `tour_step:` field and named `session-handoff` §2 the schema of record; suite 516 → 584). **M11 IS COMPLETE — 7/8 top-level WPs done. Remaining: WP8 (M12) ONLY.**
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

#### WP7a: Onboarding flow spec (the written per-path flow) ✅ SHIPPED 2026-07-22 (commit 4a43713)
**AS-BUILT (2026-07-22):** Promoted `onboarding-brainstorm.md` into the durable design contract `workflow-system/product/onboarding-flow-spec.md` (§1 audience · §2 structure · §3 two per-path flows w/ aha-beat mapping · §4 Claudesk surface contract · §5 settled decisions · §6 honest-framing invariant · §7 disposition table + "don't force it" · §8 build constraints · §9 cross-links). **Settled 7a.3:** entry skill = **`workflow-tour`**, category **`util-*`**, emits **no transition** (deliberate divergence from the `util-` file-prefix — WP7e must NOT pin a util-prefix check; noted for the AD-5 as-built resync); fuzzy-matcher-collision-checked per WP5. **Settled 7a.4 (corrected):** recommend **`acceptEdits`** (NOT `bypassPermissions` — two distinct modes; brainstorm conflated them), reassurance copy keeps "stays local" honestly true. Codify deferred pins to WP7e (target the shipped skill, not a living doc — WP5/WP6 precedent); pin-charter captured forward in the spec. Review-quality 0C/0MAJ/3 MINOR (copy-time polish, backlogged). check-structure.sh 469/0.
**Description:** Author the onboarding flow spec doc: per-path (greenfield / brownfield) first-run flow, the aha beats + their ordering, the "don't force it" staged-vs-named disposition table, and the **surface contract Claudesk renders against + when it points at the entry command**. This is simultaneously (i) the design contract WP7b–WP7d build against and (ii) the **M12 return-contract deliverable** (feeds WP8). Promote/refine `onboarding-brainstorm.md` into this durable spec.
**Milestone:** 11 · **Dependencies:** brainstorm complete (done) · **Size:** S–M
**Tasks:**
- [x] 7a.1 Write the per-path flow (greenfield spine + brownfield spine) with the aha beats mapped to each step
- [x] 7a.2 Write the Claudesk surface contract (what Claudesk shows, when it points at the entry command, what it must NOT hardcode)
- [x] 7a.3 Settle the entry-skill name + category (`session-*` vs new vs `util-*`) — decided here so WP7b builds against a fixed name → **`workflow-tour` / `util-*` / no-transition**
- [x] 7a.4 Settle the bypass-permissions reassurance copy (the one-line "why it's safe") → recommend **`acceptEdits`** (corrected from bypass)

#### WP7b: The entry skill (single entry → two separate paths) ✅ SHIPPED 2026-07-22 (commit 40ec14f)
**AS-BUILT (2026-07-22):** Built as a **three-skill `tutorial-` family** (co-design revision at build start — three files enforce the spec §2 "diverge and stay diverged" invariant *structurally* vs. prose discipline in one file): **`tutorial-getting-started`** (entry/dispatcher — recommends `acceptEdits` via Shift+Tab NOT bypassPermissions, presents the new-vs-existing fork with greenfield-recommended-default / brownfield-first-class-peer framing (a default, not a funnel), dispatches inline [SUPERSEDED 2026-07-23 by WP7j → getting-started points+`cd`s+`/exit`-hands-off across a session boundary; the arm is always entered directly. Authority: `docs/lessons/tutorial-tour-session-chain-flow.md`]; no drive-mode menu so beat B stays visible) + **`tutorial-greenfield-workflow-tour`** (narrated real run, 8-step spine, verify-self grounding + SURFACE STAGED w/ per-beat pre-framing, WP7c scaffold + WP7d bookend/graduation forward-declared) + **`tutorial-brownfield-workflow-tour`** (BYO real code no demo, **optional `/init`** (skip when CLAUDE.md exists), product-workflow reverse-engineers the strategic layer = headline grounding, `product-context` revise; SURFACE + grounding NAMED-only). All three util-family shape (no skills:/tools:), `## Category` (not the debug-* `## Category Context`), emit **no transition** (documented). **Co-design revised the WP7a spec** (recorded in `onboarding-flow-spec.md` Revision 2026-07-22): three-skill family (was single `workflow-tour`), `tutorial-` prefix now pinned by WP7e (was no-prefix/no-pin), Claudesk command `/tutorial-getting-started` (was `/workflow-tour`), brownfield `/init` optional. Honest-framing invariant honored (real ~10–15min, no 5-min promise). Review-quality 0C/0MAJ/3 MINOR (2 prose-tightenings backlogged → fold into WP7d; 1 WIP-housekeeping fixed in-place). Behavioral scenarios + `check-structure.sh` `tutorial-`-prefix pin deferred to WP7e by design (forward pin-spec captured in the archived WIP `## Discoveries`). `install.sh` re-run; 3 symlinks verified + picked up live this session.
**Description:** Build the dedicated onboarding entry skill (`skills/<name>/SKILL.md`): a single entry point that asks new-vs-existing, then runs the **greenfield** arm or the **brownfield** arm, each staging its own beats per the spec. Brownfield arm scripts the `/init` → product-workflow-reverse-engineer → `product-context`-revises-`CLAUDE.md` sequence against the user's real code. Greenfield arm drives top-of-hierarchy entry + the hierarchy taste. Opens with the universal bypass-permissions recommendation. Keeps the run in stepping/orchestrated so the human-pause beat is visible; ends with the drive-modes graduation reveal.
**Milestone:** 11 · **Dependencies:** WP7a (name + flow settled) · **Size:** M
**Tasks:**
- [x] 7b.1 SKILL.md scaffold + frontmatter (name/description per path-qualification + fuzzy-matcher-description-collision discipline from WP5)
- [x] 7b.2 Entry + path-fork (new-vs-existing) with **greenfield recommended-default / brownfield first-class peer** framing (a default, not a funnel) + universal `acceptEdits` recommendation (corrected from bypass) + reassurance copy + the honest ~10–15-min narrated-real-run expectation (no "5-min" claim)
- [x] 7b.3 Greenfield arm as a **narrated real run** (per-beat pre-framing): top-of-hierarchy entry, hierarchy taste, staged SURFACE beat + staged verify-self grounding beat driving the WP7c runnable scaffold, A/B/G beats
- [x] 7b.4 Brownfield arm (**optional** `/init` → reverse-engineer → `product-context` revise; A/B/G beats; SURFACE named-only)
- [x] 7b.5 Transition surface: emits **NO transition** (util-family meta-op) — documented explicitly in each skill (`## Transitions` = None + Category body); three-places-in-sync N/A (no transition). Re-ran `install.sh`.

#### WP7c: Greenfield scaffold (runnable) + planted authentic tangent ✅ SHIPPED 2026-07-22 (commit 287ff86)
**AS-BUILT (2026-07-22):** Delivery-shape decision (7c.1) = **BOTH** a shipped fixture dir + a scaffolder (not either/or): `tools/onboarding-scaffold/sample/` is the canonical git-tracked minimal content, and `tools/onboarding-scaffold/new-sample.sh` stamps a **fresh throwaway copy per tour run** (so real edits/SURFACE/handoff hit a disposable copy, never the source). Lives under `tools/` (user-facing tour content, not a test fixture → not `tests/fixtures/`; data a skill consumes → not `skills/`), mirroring the `tools/migrate-doc-layout/` shape (script + README + `test/`). **Runnable observable:** `sample/greet.sh World` → exit 0, stdout exactly `Hello, World!` (the verify-self grounding target). **Planted authentic tangent:** the no-arg path prints the ungrammatical `Hello, !`, flagged `TODO` in `sample/README.md` — a *real* small bug (not a fake breadcrumb) for the staged SURFACE beat. No-runtime (POSIX shell + markdown, zero deps) so it doesn't rot. Phase 2 wired the greenfield arm (`skills/tutorial-greenfield-workflow-tour/SKILL.md`): replaced the WP7c forward-declaration with the concrete `new-sample.sh` drop-in, and made Step 5 (grounding) + Step 6 (SURFACE) cite the real observable + real tangent (WP7d forward-declarations preserved). Codified via a 10-assertion CLI smoke (`tools/onboarding-scaffold/test/run-tests.sh`) incl. an arm↔scaffold wiring-contract pin; smoke 10/10, check-structure.sh 472/0. verify-human **deferred to the operator's hands-on `/tutorial-getting-started` run** (SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED) — verify-self confirmed the mechanical facts. Review-quality 0C/**1 MAJOR** (`new-sample.sh --help` leaks code — auto-backlogged medium) /2 MINOR, all auto-backlogged (Mode-3). Tour behavioral scenarios + `tutorial-`-prefix pins remain WP7e's job (deliberately not pulled forward).
**Description:** Build the tiny shipped greenfield scaffold the onboarding drops the user into (fixture dir copied in, or a scaffolder that seeds a temp dir — decide at plan time). Two hard constraints from the brainstorm: (1) it must contain a **planted, authentic-feeling tangent** so the **staged SURFACE beat fires reliably** without feeling fake; (2) it must be **RUNNABLE with at least one observable outcome** so the **staged verify-self grounding beat** has something real to observe (agent runs it, reports PASS/FAIL — user watches it *check* reality). Greenfield-only (brownfield is BYO real code — no scaffold). Must be maintainable (it rides path/skill/layout changes — keep it minimal so it doesn't rot; cf. M7 moved every folder). Balance minimal-so-it-doesn't-rot against runnable-enough-to-verify.
**Milestone:** 11 · **Dependencies:** WP7a (what the beats need) · **Size:** S–M
**Tasks:**
- [x] 7c.1 Decide scaffold delivery (shipped fixture dir vs. temp-dir scaffolder) + where it lives in-repo; decide the minimal runnable shape + its observable outcome (for verify-self) — BOTH: fixture dir `tools/onboarding-scaffold/sample/` + `new-sample.sh` scaffolder; observable = `greet.sh World`→`Hello, World!`
- [x] 7c.2 Author the minimal runnable scaffold content + the planted tangent that makes SURFACE authentic — `greet.sh` (happy path + no-arg `Hello, !` tangent) + `sample/README.md` (observable + TODO)
- [x] 7c.3 Wire WP7b's greenfield arm to drop the user into it + trigger the staged SURFACE beat AND the staged verify-self grounding beat — arm's environment section + Steps 5/6 now cite the concrete scaffold, observable, and tangent

#### WP7d: Staged-beats wiring (bookends + graduation) ✅ SHIPPED 2026-07-22 (commit ae733ab)
**AS-BUILT (2026-07-22):** Replaced the two `> **WP7d wiring touchpoint (forward-declared).**` placeholder blocks in BOTH arm skills with real scene-by-scene choreography + per-beat pre-framing copy (spec §3 bookend/graduation, §6 per-beat framing, §7 staged-set). **Step 7 handoff→restore bookend** (both arms): a 3-scene choreography (pre-frame + `/session-handoff` writes `.session.md` + WIP marker / enact-leave / `/session-restore` reads pointer off disk + reconstructs without replaying the conversation), grounded in the REAL skill mechanics, payoff tied back to beat A (greenfield: the Step-3 state file; brownfield: the Step-4 revised `CLAUDE.md` + the drift/forgetting pain). **Step 8 drive-modes graduation** (both arms): reveal LAST + explicitly un-pushed ("Not recommended yet."), no-live-demo, then NAMED-not-staged close (Hierarchy — light-taste greenfield / CUT brownfield — + Reflect/Capture). **Verify-pause visibility** already enforced structurally by WP7b (`tutorial-getting-started` Step 2 "Do NOT present a drive-mode menu here… default stepping/orchestrated" + both arms' cadence lines); WP7d added the Step-8 reinforcement + named-at-close half. Honest-framing §6 preserved (no "5-min" claim; prohibition kept). Also **consumed 4 review findings** in real prose (verified-against-code first): greenfield Step-2 "light taste, then pivot" bound (GREENFIELD-PRODUCT-ENTRY-UNBOUNDED), dispatcher divergence-semantics fix in Category + Step 3 both spots (DISPATCHER-CONTROL-RETURN-PHRASING), spec §3-greenfield-step2 grounding-not-staged clause (SPLIT-GREENFIELD-GROUNDING), spec §3-legend disposition-token cross-pointer (SECTION3-LEGEND-NO-DISPOSITION-TOKENS). Prose-only; no new skill dir (all 3 skills already symlinked live → install.sh not needed); no transition/state-machine change. Both phases through full build→verify-auto→verify-self→verify-human(Mode-3 auto-skip, no integration boundary)→verify-codify; independent verify-self subagent coherence reads all-PASS; check-structure.sh 472/0. Review-quality 0C/0MAJ/**2 MINOR** auto-backlogged (scope-symmetry: the dispatcher control-return fix not yet mirrored into the two arm Category blocks — cheap next-sweep pickup; + terminal-action-implicit-at-close). Behavioral scenarios + `tutorial-`-prefix pins remain **WP7e's** charter (deliberately not pulled forward). verify-human copy acceptance still deferred to the operator's hands-on run (SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED).
**Description:** Wire the beats that are choreography rather than plain skill invocations: the **handoff → restore emotional-peak bookend** (run `/session-handoff`, simulate/enact leave, `/session-restore` restores full context), the **drive-modes graduation reveal** (LAST, explicitly un-pushed — "not recommended yet"), and **verify-pause visibility** (ensure the onboarding run stays in stepping/orchestrated so beat B is seen, never autopilots past it). Also the **named-at-close** pointers (hierarchy, reflect-capture-learns-you).
**Milestone:** 11 · **Dependencies:** WP7b (arms exist to wire into) · **Size:** S
**Tasks:**
- [x] 7d.1 Handoff→restore bookend choreography (both paths) — 3-scene bookend in both arms, mechanics-faithful, payoff tied to beat A
- [x] 7d.2 Drive-modes graduation reveal at the end (un-pushed framing) — reveal LAST + "Not recommended yet." + no-live-demo, both arms
- [x] 7d.3 Verify-pause-visibility guard (stay stepping/orchestrated during the tour) + the named-at-close pointers — guard already enforced by WP7b Step-2 no-mode-menu; WP7d added Step-8 reinforcement + the named-at-close (Hierarchy/Reflect-Capture) pointers in both arms

#### WP7e: Behavioral scenarios + structural pins
**Description:** Cover the onboarding: behavioral scenario(s) for the entry skill's path-fork + the staged beats (using the established scenario shape — `transition_id` / `contains_any`→SOFT_PASS for prose-behavior beats), and `tests/check-structure.sh` structural pins for the new skill's required sections + the "don't force it" invariants + (if any) the transition surface. Mirror the WP5/WP6 codify shape.
**Milestone:** 11 · **Dependencies:** WP7b–WP7d, **WP7f/WP7g/WP7i/WP7j/WP7k (shipped)**, **WP7l/WP7m/WP7n (the 2026-07-25 acceptance fixes — pins lock accepted copy)** · **Size:** S–M
**Scope grew with the M11 expansion — WP7e now codifies FOUR tour surfaces** (both arms + the WP7g corrections + the WP7k full-cycle tour), against copy the operator has accepted. Carried-forward pin charter beyond 7e.1–7e.3 below: extend the `tutorial-`-prefix pin to the 4th skill (7k.4); honest-framing invariants (no "5-min" claim; ~30–45-min present on the full-cycle tour); the full-cycle tour's deliberate **no-replay / no-mode-menu** invariants; the WP7k `description` stage-chain MINOR (drops `research`); and the newly-accepted WP7l/WP7m/WP7n behaviors — greenfield sample-lands-in-cwd + refuse-if-non-empty, the offer-to-clean-up beat, the tour-aware boundary guard (no mid-tour handoff offer), and the terse `Next Step:` close block.
**Tasks:**
- [ ] 7e.1 Behavioral scenarios (path-fork; staged-beat presence; bypass-permissions-recommended; drive-modes-reveal-is-last)
- [ ] 7e.2 `check-structure.sh` structural pins (new skill sections; staged-vs-named invariants; three-places if a transition was added)
- [ ] 7e.3 Full-group behavioral run green (subject to the `--id` harness path — now fixed by the boundary-handoff Phase 3)

---

> ## ✅ RATIFIED — walkthrough-driven M11 expansion (recorded 2026-07-22, operator-ratified same session)
>
> **Provenance:** Operator's **live hands-on tour walkthrough** (Round-2 feedback in the now-consumed
> `tmp/wp7e-tour-walkthrough-feedback.md` lines 223–232, + Round-1 FB-1…FB-5). Verdict: *"the overarching
> flow feels solid, but all the details need to be addressed."* The scope grew materially — this is a
> **multi-WP expansion with the full product-cycle tour now IN M11 scope** (operator ruling). Kept in the
> WBS (not the backlog) by operator instruction. Ratified via `AskUserQuestion` 2026-07-22; per-item
> rulings recorded inline below.
>
> **Sequencing note (load-bearing):** the tour-copy/redesign corrections (WP7g, WP7i) must land **and be
> operator-accepted via a fresh hands-on run** BEFORE WP7e freezes pins/scenarios — pins lock *accepted*
> copy, not current copy. Revised M11 tail: **{WP7g ∥ WP7i ∥ WP7j} → hands-on acceptance → WP7e (codify)**.
> WP7f is done. WP7h (full product-cycle tour) is now in-scope and gates M11 completion alongside WP7e.
>
> **Sequencing note UPDATE 2026-07-25 (post-acceptance):** the batch acceptance run is **done** and passed
> three of four surfaces; the greenfield arm drew three fixes (**WP7l**, **WP7m**, **WP7n**). The same
> pins-lock-accepted-copy rule therefore applies once more: those three must land **and be re-accepted on
> the greenfield arm** before WP7e freezes. Current M11 tail: **{WP7l ∥ WP7n} → WP7m → greenfield
> re-acceptance → WP7e (codify)**. WP7l and WP7n are parallel-safe *except* at the arm's close, which both
> touch (WP7l.3 cleanup offer ∥ WP7n's `Next Step:` block) — 7n.3 owns merging them, so if built in
> parallel, land WP7l first or reconcile at 7n.3. WP7m is sequenced after them to avoid a third edit to the
> same Step-7/Step-8 region while its guard placement is still being settled.
>
> ### WP7f: `install.sh` recommends the tour (FB-1) ✅ SHIPPED 2026-07-22 (commit 63dc3e3, folded into the WP7g commit)
> **Description:** Make `install.sh` the real entry point — its closing output now recommends the new
> user run `/tutorial-getting-started` first, honest ~10–15-min framing (no "5-min" claim), §6-consistent.
> **Milestone:** 11 · **Dependencies:** WP7b · **Size:** XS
> **Status:** Applied this session (install.sh tail block). Not yet committed — folds into the WP7g commit.
> - [x] 7f.1 Add the "New here? Take the guided tour" block to install.sh's final echo
> - [x] 7f.2 README / snippet onboarding pointer — **RATIFIED YES** (operator): add a `/tutorial-getting-started` pointer to the README and/or CLAUDE.snippet onboarding surface
>
> ### WP7g: Tour-copy corrections before pins freeze (FB-3, FB-4, FB-5 + live items 0/6) — ✅ SHIPPED 2026-07-22 (commit 63dc3e3)
> **AS-BUILT (2026-07-22):** Three phases. **P1** dispatcher + spec §5a/§5b: permission mode → **`auto`** (availability caveat "if auto mode is available" + `claude --permission-mode auto` launch cmd; SUPERSEDES the acceptEdits recommendation the operator never endorsed — memory `reference_claude-code-permission-modes` updated), explicit imperative **stepping** drive mode (distinct from the `auto` permission mode — stated at every site), new **Step-0 pre-flight "where to run this"** (greenfield: tour stamps its OWN throwaway copy, do NOT cd-to-empty-dir; brownfield: /exit + cd repo-root + relaunch). **P2** both arms' Step-7 handoff→restore rewrite → **context-window-management headline** + explicit `/compact` contrast + check-usage→exit→restore→check-usage demonstrable beat (mechanics-faithful: pointer references on-disk files, restore re-reads fresh, does NOT copy the plan in; cross-session "close the laptop" demoted to secondary) + explicit stepping in both arms' cadence lines (+ swept stale accept-edits→auto in both Framings). **P3** folded the 2 WP7d MINORs (arm-Category scope-symmetry: literal "does not return control to the dispatcher" → "runs the tour to its close"; + explicit terminal-action at each arm close). verify-auto=check-structure.sh 472/0; verify-self 7/7 (P1) + 5/5 (P2, incl. load-bearing honesty read) all PASS; **verify-human SKIPPED by operator override** (copy accepted from the feedback loop, NOT a fresh hands-on run → the deferred acceptance SURFACE is accepted-without-live-run, left OPEN); verify-codify=structural pins hold (full scenarios+pins = WP7e). Review-quality 0C/0MAJ/**3 MINOR** (2 stale-self-ref MINORs fixed inline; 1 Step-0 auto-caveat-ordering MINOR auto-backlogged). Prose/spec-only; no transition/state-machine change. **Does NOT complete M11** (WP7i/WP7j/WP7h/WP7e still pending).
> **Description:** Operator-raised copy/spec corrections to the shipped `tutorial-*` copy, applied +
> accepted via a fresh hands-on run BEFORE WP7e codifies:
> - **Item 0 — permission mode → `auto` (SUPERSEDES acceptEdits).** The operator never endorsed
>   `acceptEdits` (a prior-session inference in WP7a §5b); the live run flagged it prompts on every step.
>   **Ruling: recommend `auto` mode** — classifier-gated so it's low-friction (no prompt on `greet.sh`
>   etc.) AND keeps the "stays safe/local" reassurance honestly true (unlike bypass). Rewrite dispatcher
>   Step 1 + spec §5b: recommend auto, **caveat "if auto mode is available"** (auto needs Opus 4.6+/
>   Sonnet 4.6+/Fable 5 + an allowing account/provider), and **provide the `claude --permission-mode auto`
>   launch command**. Update `reference_claude-code-permission-modes` memory (DONE this session).
> - **FB-3 / item 6 (the load-bearing one) — handoff value-prop rewrite.** Both arms' Step-7 bookend
>   headlines handoff→restore as cross-session "close the laptop." Real primary value: **freeing/resetting
>   the context window WITHOUT losing load-bearing strategic context** (roadmap/WBS/progress/obstacles/
>   relevant open backlog) — a curated, better-than-`/compact` alternative. Rewrite Step-7 pre-frame +
>   payoff in BOTH arms to lead with context-window management + explicit `/compact` contrast; cross-session
>   continuity becomes secondary. **Item 6 adds a concrete demonstrable beat:** have the user *check context
>   usage → exit → new session → `/session-restore` → check usage again*, and highlight on restore that
>   although the window was cleaned up, the WIP/WBS/big-picture details survived (agent didn't tunnel-vision).
>   **Mechanics-faithful (§6, VERIFIED this session):** `/session-handoff` writes `.session.md` (a pointer:
>   workflow/step/resume_skill/state_file/drive_mode + Last-completed/Next-action/Blockers/Notes) + a state-
>   file marker; the strategic context survives because the pointer references the on-disk state files (WBS,
>   WIP) that `/session-restore` re-reads fresh — NOT because it copies them into the pointer. Scope the copy
>   to that honest mechanism (don't claim it "saves the whole plan into the pointer").
> - **FB-4 / item 2 — explicit STEPPING mode.** The three skills say the ambiguous "stepping/orchestrated"
>   and never SET/NAME a mode; the live run confirmed G1–G6 auto-chained with no checkpoints. **Ruling: the
>   tour runs in STEPPING mode explicitly** — imperative in dispatcher Step-2 no-menu block + both arms'
>   cadence lines + spec §5a; WP7e pins it. (Beat B's visible pause depends on it.)
> - **FB-5 — pre-flight "where to run this" instruction.** Add one, branching by path: **brownfield** →
>   `/exit`, `cd` to repo root, relaunch, re-run the tour (+ item-4 git safety, see WP7j); **greenfield** →
>   **RESOLVED: clarify the disposable-copy mental model** (the tour stamps its OWN throwaway copy via
>   `new-sample.sh`) — do NOT tell the user to cd to an empty folder (that conflicts with WP7c's shipped
>   scaffold model). Pre-flight explains the tour makes its own scratch project.
> **Milestone:** 11 · **Dependencies:** WP7b–WP7d · **Size:** S–M (grew from item 0 + item 6 beat)
> **Gates:** WP7e (accepted copy before pins). **Prose/spec-only**, no transition.
> - [x] 7g.1 Item 0: permission mode → auto (dispatcher Step 1 + spec §5b; availability caveat + launch cmd)
> - [x] 7g.2 FB-3/item 6: handoff value-prop rewrite (both arms Step 7) — context-window-mgmt headline, `/compact` contrast, the check-usage→exit→restore→check-usage demonstrable beat; mechanics-faithful
> - [x] 7g.3 FB-4/item 2: make STEPPING mode explicit + imperative (dispatcher + both arms + spec §5a)
> - [x] 7g.4 FB-5: pre-flight "where to run this" (brownfield exit+cd+relaunch; greenfield clarify disposable-copy model)
> - [x] 7g.5 Fold the two open WP7d MINORs (**RATIFIED**): `SURFACE-2026-07-22-QUALITY-ARM-CATEGORY-CONTROL-RETURN-SCOPE-SYMMETRY` + `...-CLOSE-TERMINAL-ACTION-IMPLICIT` into this copy sweep
> - [ ] 7g.6 Operator fresh hands-on `/tutorial-getting-started` acceptance run — **SKIPPED by operator 2026-07-22** (copy accepted from the feedback loop, not a live run). The deferred acceptance SURFACE stays OPEN as accepted-without-live-run; a genuine hands-on run can still happen at any later WP or the operator's discretion.
>
> ### WP7h: Full product-cycle "full experience" tour + pointer (FB-2) — ✅ DESIGN COMPLETE 2026-07-24 (build split out → WP7k)
> **AS-DESIGNED (2026-07-24, operator co-design — design-only this session per operator ruling):** The
> greenfield tour keeps the product entry a deliberate *light taste*; FB-2 asked for the heavier
> counterpart. Design settled via 3 rounds of `AskUserQuestion` co-design and written to
> **`workflow-system/product/full-product-cycle-tour-design.md`**. Settled decisions: **headline aha =
> DECOMPOSITION** (fuzzy idea → milestone-ordered, dependency-mapped, feature-ready plan — "the workflow
> can carry a whole *initiative*"); **environment = a richer controlled subject, NOT BYO** (delivery
> shape — written product brief vs. richer sample dir — sketched with tradeoffs, settled at build-plan
> time; lean = written brief); **positioning = standalone 4th `tutorial-product-cycle-tour`, run
> directly, pointed-at from the greenfield arm's Step-8 close — NOT a 3rd first-timer fork option**
> (a full cycle is a poor cold-open first impression); **length honesty = honest ~30–45 min label +
> graduation-not-first-run** (audience self-selects; same never-fake-it §6; NO "5-min" claim, NO
> narrate-and-skip compression). **Spine (reshaped by operator):** entry (no mode menu, no replay
> question, run stepping) → vision → roadmap → research(light) → arch(grounding NAMED) → wbs
> (decomposition PAYOFF) → open strategic docs (**beat A at the strategic layer**, STAGED) →
> **handoff→restore bookend** (STAGED, lands harder — a whole plan to recover) → close. **The product
> cycle pauses at EACH step, and that recurring pause IS the trust beat** (not one engineered beat B).
> **No replay / no drive-mode menu / no mode-aware graduation** (those teach "pauses are tunable" — a
> lesson that doesn't apply to a cycle whose pauses are the point); close NAMES the FSD-for-rare-cases
> caveat (simple/clear/low-stakes/throwaway only) as an honest counterweight, not an invite. **Ends at
> a feature-ready WBS — does NOT drive an actual feature** (greenfield already showed feature execution).
> Grounding NAMED / SURFACE CUT (no runnable subject to stage them authentically). Name fuzzy-matcher-
> collision-checked. **Build DEFERRED to WP7k** (operator: "build should be a WP added to the WBS") so
> all four tour surfaces land + get accepted together before WP7e freezes pins. The WP7h.1 pointer note
> (wording settled in the design doc §7) also **rides WP7k**, so a live pointer never dangles at a
> not-yet-built skill.
> **Milestone:** 11 · **Dependencies:** WP7b (light-taste arm exists) · **Size:** design = S (done); build = WP7k
> - [x] 7h.1 Pointer-note wording settled (design doc §7); insertion **deferred to WP7k** (rides the build so it never dangles)
> - [x] 7h.2 Design the full product-cycle tour (name + flow + environment + dispositions) — DONE → `full-product-cycle-tour-design.md`
> - [→] 7h.3 Build the tour skill + wire it + codify — **SPLIT OUT to WP7k** (its own build-WP; sequenced BEFORE the batch acceptance run per operator 2026-07-24, so one walkthrough accepts all four surfaces)
>
> ### WP7k: Build the full product-cycle tour skill (deferred build of WP7h) — ✅ SHIPPED 2026-07-24 (commit 8bbf5c1)
> **AS-BUILT (2026-07-24):** Built `skills/tutorial-product-cycle-tour/SKILL.md` (the 4th `tutorial-*`
> skill) against the settled WP7h design. Two phases: P1 authored the skill + the written product
> brief (`scripts/brief.md` — the "Trailhead" fuzzy day-hike-planner idea); P2 wired the WP7h.1
> pointer into the greenfield arm's Step-8 close + re-ran `install.sh` (additive). **Environment
> delivery shape settled at plan time = Option A (written product brief)** — no verify-self grounding
> beat here needs runnable code, so a brief is the lower-rot choice (design §2 lean confirmed).
> 8-step spine per design §3: entry(stepping, no mode menu) → vision → roadmap → research(light) →
> arch(grounding NAMED) → wbs(**decomposition PAYOFF**) → open strategic docs (beat A at strategic
> layer) → handoff→restore bookend (reused from the greenfield arm's Step-7, scaled to a whole plan)
> → close (FSD-caveat NAMED, **NO graduation reveal**). Deliberately carries **NO replay / drive-mode
> menu / mode-aware graduation** (the recurring step-pause IS the trust beat), guarded by a "Why no
> replay / no mode menu (do not regress this)" prose section. Honest ~30–45 min label, no "5-min"
> claim. Emits no transition; all `tutorial-*` family invariants (path-qualification, no-runtime,
> scaffold-in-skill) hold. verify-auto/self green each phase (verify-self coherence read confirmed
> design-§3/§7 fidelity 8/8 + 5/5). **verify-human (Phase 2) copy read-through DEFERRED to the
> operator's batch hands-on acceptance run** (operator chose "defer — I'll verify at the full
> walkthrough"; SURFACE-2026-07-22-WP7C-...-DEFERRED spans WP7k). check-structure.sh 473/0.
> Review-quality 0C/0MAJ/**1 MINOR** (description stage-chain drops `research` — inherited verbatim
> from the design §6 draft; auto-backlogged low → best folded into WP7e). Tour behavioral scenarios +
> `tutorial-`-prefix pin (4th skill) remain WP7e's charter.
> **Description:** Build `skills/tutorial-product-cycle-tour/SKILL.md` against
> `workflow-system/product/full-product-cycle-tour-design.md` (the settled WP7h design). Its own
> `/feature-plan` (the design work — the "spec" — is already done, so plan-not-spec). At plan time,
> settle the environment delivery shape (design §2 Option A written product brief vs. Option B richer
> sample dir; lean = A). Add the WP7h.1 pointer note (design §7 wording) to the greenfield arm's Step-8
> close. Reuse (do NOT re-derive) the greenfield arm's Step-7 handoff→restore choreography. No transition
> (util-family / `tutorial-*`); prose/markdown-only (no-runtime); path-qualification mandate; re-run
> `install.sh` (additive-only) after the new skill dir; scaffold-in-skill if a subject file ships.
> **Milestone:** 11 · **Dependencies:** WP7h (design — done) · **Size:** M–L
> **Sequencing (operator, 2026-07-24): WP7k builds BEFORE the batch hands-on acceptance run** — so the
> operator's single acceptance walkthrough covers all FOUR tour surfaces (both arms + WP7g corrections +
> this new full-cycle tour) in one pass, rather than accept-then-build-then-re-accept. The batch
> acceptance SURFACE (`SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED`) is extended to
> cover WP7k's copy too; WP7e still codifies last, against the accepted copy.
> - [x] 7k.1 `/feature-plan` the build; settled environment delivery shape = Option A (written product brief)
> - [x] 7k.2 Build `tutorial-product-cycle-tour/SKILL.md` against the design (spine, beats, honest ~30–45 min label, FSD-caveat close) — DONE + `scripts/brief.md`
> - [x] 7k.3 Add the WP7h.1 pointer note to the greenfield arm Step-8 close (design §7 wording); re-run `install.sh` — DONE
> - [→] 7k.4 Codify with WP7e — extend the `tutorial-`-prefix pin to the 4th skill + honest-framing (no "5-min", ~30–45 min present) + no-replay/no-mode-menu invariants — **DEFERRED to WP7e by design** (codifies last against operator-accepted copy from the batch acceptance run; NOT a hidden gap — this task is WP7e's charter, not WP7k's)
>
> ### WP7i: Richer greenfield sample skeleton + upfront project framing (items 1, 3, 5) — ✅ SHIPPED 2026-07-22 (commit 5ca1723)
> **AS-BUILT (2026-07-22):** Redesigned the greenfield sample from the one-file hello-world greeter into a small **command-line `todo` list** (operator-chosen via AskUserQuestion): a `todo` dispatcher + `lib/{add,list,done}.sh` modules over a plain-text `todos.txt` store — richer surface so planning/verify-self/SURFACE land meaningfully, still no-runtime/no-deps (POSIX shell + markdown). **Observable:** `todo add "buy milk" && todo list` → exactly `1. [ ] buy milk`. **Planted authentic tangent** (re-instantiated from the retired greet.sh's no-arg bug): `todo done <index>` guards numeric but NOT in-range, so `todo done 99` on a short list reports success + no-ops silently — TODO-flagged in `sample/README.md` + `lib/done.sh` (WHY not WHAT, per the prior GREET-TODO ruling). Kept WP7c's copy-per-run stamper `new-sample.sh` (operator's "fixed skeleton the tutorial copies" model IS the current design). Three phases: P1 authored the sample + retired greet.sh; P2 updated the stamper + rewrote the 8-group smoke to the todo CLI (folded in + fixed the 2 in-blast-radius quality findings: `--help` code-leak via delimiter-anchored awk + mktemp multi-trailing-slash strip, both regression-pinned); P3 re-cited the greenfield arm (env section + Step 5 grounding + Step 6 SURFACE) + added the upfront "what this project is" framing before Step 1 (honest-framing §6 preserved, no "5-min" claim). verify-auto/self green each phase; **verify-human copy-judgment DEFERRED to the operator's 2nd hands-on walkthrough** (mechanical facts verify-self-confirmed; SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED now spans WP7c/WP7g/WP7i). Smoke 15/0, check-structure.sh 472/0. Review-quality 0C/0MAJ/**3 MINOR** (all low, 2 "no change recommended" — auto-backlogged). Tour behavioral scenarios + `tutorial-`-prefix pins remain WP7e's charter. Prose/scaffold-only; no transition/state-machine change.
> **Description:** The shipped hello-world scaffold (`tools/onboarding-scaffold/sample/` = one `greet.sh`
> + README) is **too shallow to demonstrate the workflow's value** (operator, live run). **Ruling: redesign
> the sample now.** Keep WP7c's copy-per-run stamper (`new-sample.sh`) — the mechanism is sound and matches
> the operator's "fixed pre-generated skeleton the tutorial copies after the vision step" idea — but replace
> the shallow skeleton with a **richer pre-generated project skeleton** with enough real surface (a couple
> of modules, a runnable observable, a planting-worthy authentic tangent) that planning / verify-self /
> SURFACE land meaningfully. Plus: **explain the vision/project info UPFRONT** in the tour output before G1
> ("here's what this sample project is / what we're building"). Plus the **replay invitation** (items 3/5):
> both arms CLOSE with a highlighted invitation to re-run from the same starting point in **autopilot/FSD** —
> greenfield "start over"; brownfield "stash/revert your changes, then retry." (Replay-invite tracked as its
> own sub-WP below, WP7j, since it also carries the brownfield git-safety piece; the sample-redesign +
> upfront-framing is WP7i proper.)
> **Milestone:** 11 · **Dependencies:** WP7c (scaffold), WP7b (greenfield arm) · **Size:** M (touches scaffold + tests + arm copy)
> - [x] 7i.1 Redesign the pre-generated skeleton (richer, still no-runtime/no-deps; keep copy-per-run stamper) — todo CLI (dispatcher + add/list/done + todos.txt store)
> - [x] 7i.2 Update `new-sample.sh` + its smoke to the new skeleton — stamper run-hint → todo CLI; smoke rewritten to 8 assertion groups (15 assertions); folded in + fixed the --help-leak + double-slash quality findings with regression pins
> - [x] 7i.3 Upfront "what this project is / what we're building" framing before G1 (greenfield arm) — new "### Say what the project is, upfront" block before Step 1
> - [x] 7i.4 Re-cite the real observable + real tangent in Step 5 (grounding) + Step 6 (SURFACE) for the new skeleton — Step 5 cites `todo add … && todo list`→`1. [ ] buy milk`; Step 6 cites `todo done 99` no-op
>
> ### WP7j: Replay invitation + brownfield git-safety + mode-aware close + scaffold re-home (items 3, 4, 5 + live-walkthrough-2 findings) — RATIFIED (own WP; grown S→M mid-flight)
> **Description:** Operator ruling: track the replay invitation as its **own WP** (not folded into
> WP7g, not a bare task). **Grown mid-build (2026-07-22, live walkthrough round 2)** from a copy-only S
> to a structural M when three coupled findings surfaced. Pieces:
> **(a)** both arms CLOSE (Step 8) with a highlighted invitation to re-run the tour in **autopilot/FSD**.
> **The replay is a full session-boundary crossing** (`/exit` → new session, echoing the handoff→restore
> beat the tour just taught) that **re-enters at the ARM skill directly** (`/tutorial-greenfield-workflow-tour`
> / `/tutorial-brownfield-workflow-tour`), NOT the dispatcher — the dispatcher re-forces stepping + re-asks
> the path fork, which the faster-gear replay moves past. Greenfield: the **arm auto-stamps a fresh copy**
> (agent runs the scaffolder, NEVER the human). Brownfield: user `git stash`/restores to clean baseline first.
> **(b)** brownfield **git-safety pre-flight** (item 4, in dispatcher Step-0 brownfield branch): if git present,
> check unstaged/uncommitted changes → recommend commit first (or safe copy / different repo) + warn of
> unexpected changes; if no git, recommend `git init`. (Complements WP7g FB-5 brownfield exit+cd.)
> **(c) CORRECTED 2026-07-23 — arm skill has ONE entry path (always direct) with TWO run modes.**
> *[The earlier "two entry paths: dispatched-in-stepping via `/tutorial-getting-started` AND
> entered-directly" framing was WRONG — it assumed getting-started dispatches the arm inline. Per the
> operator's session-chain flow (`docs/lessons/tutorial-tour-session-chain-flow.md`, the authority),
> the arm is **always entered directly** in its own fresh session; getting-started only points+exits.]*
> The arm has one entry path (direct) with two **run modes**: **first-run** (defaults to stepping,
> drive modes stay hidden until Step-8 graduation) and **replay** (the arm presents the 1–4 drive-mode
> menu and runs in the chosen faster gear). The arm distinguishes them by **asking one line on entry**.
> Two beats are mode-conditional: **(c1)** the **Step-8 graduation copy** must branch on the *current* drive
> mode — the hardcoded "the whole tour ran in stepping so you saw the pause" is factually wrong on a direct
> autopilot/FSD replay (it didn't pause the same way); when already in autopilot/FSD, acknowledge that + shift
> the framing (and don't invite them to "try" a gear they're already in). **(c2)** entered directly, the arm
> must NOT assume the dispatcher already ran (permission-mode, path fork) and must still self-stamp (greenfield).
> **(d) NEW — scaffold re-home (portability fix).** `tools/onboarding-scaffold/` (sample + `new-sample.sh` +
> test) lives at repo root, which `install.sh` does NOT symlink → an installed user (the Claudesk-invited
> target, WP8) gets the skill but NOT the sample it needs. Re-home the scaffold **into the greenfield arm skill
> dir** (`skills/tutorial-greenfield-workflow-tour/scripts/` or `examples/`) so it travels with the skill's
> directory symlink + resolves from `~/.claude/skills/…` on any install. Touches WP7c's shipped structure,
> the arm env-section path refs, `new-sample.sh`'s copy-source path, its test harness, and the WP8 return contract.
> **Milestone:** 11 · **Dependencies:** WP7b–WP7d (arms), WP7c (scaffold — (d) re-homes it), WP7g (stepping-mode explicit — the graduation reveal the replay extends) · **Size:** M (grown from S)
> **✅ SHIPPED 2026-07-23 (commit f90446d)** — grew S→L: the live walkthrough exposed a foundational premise error (getting-started was built to dispatch the arm inline; the operator's real flow is a CHAIN of session boundaries — authoritative doc `docs/lessons/tutorial-tour-session-chain-flow.md`), so WP7j was **re-planned to 6 phases**: (1) getting-started point+cd+/exit (kill dispatch-inline) + superseded pointers + discoverable flow doc; (2) arm first-run-vs-replay entry question + the mode-switch menu (the arm presents 1–4 on replay; teaches "mode is a menu not a command") + greenfield agent-auto-stamps; (3) Step-8 replay invites rebuilt on the corrected foundation; (4) brownfield git-safety pre-flight (resolves the WP7g caveat MINOR by restructure); (5) full mode-aware Step-8 graduation (Branch A first-run reveal / Branch B replay acknowledge); (6) scaffold re-home `tools/onboarding-scaffold/`→`skills/tutorial-greenfield-workflow-tour/scripts/` (self-contained-on-install, no install.sh change). All 6 phases through full build→verify loop, operator-approved; check-structure.sh 472/0 throughout; scaffold smoke 15/15 from new home. Review-quality 0C/0MAJ/**3 MINOR** (coherence/housekeeping, auto-backlogged). Operator's batch hands-on acceptance DEFERRED (SURFACE-...-ACCEPTANCE-DEFERRED, now spans WP7c/g/i/j). **Does NOT complete M11** — WP7h + WP7e still pending.
> - [x] 7j.1 Greenfield Step-8 replay invitation → new-session + direct arm-skill re-entry in autopilot/FSD (agent auto-stamps fresh copy)
> - [x] 7j.2 Brownfield Step-8 replay invitation → stash/restore-clean + new-session + direct arm-skill re-entry in autopilot/FSD
> - [x] 7j.3 Brownfield git-safety pre-flight (dispatcher Step-0: uncommitted-changes check + commit/safe-copy recommendation + warning; no-git → git init) + WP7g Step-0 auto-caveat-ordering MINOR resolved-by-restructure
> - [x] 7j.4 mode-aware Step-8 graduation: two-branch (Branch A first-run reveal / Branch B replay acknowledge-the-gear), replaced the interim guard; arm doesn't assume dispatcher ran when entered directly (both arms)
> - [x] 7j.5 scaffold re-home: `git mv tools/onboarding-scaffold/` → `skills/tutorial-greenfield-workflow-tour/scripts/`; path refs fixed (arm env-section + test harness wiring assertion; scripts were already $0-relative) + WP8-contract note; self-contained-on-install verified (no install.sh change needed)
> - [x] 7j.6 Spec reflection updated — replay = session-boundary/arm-direct/gear-from-arm-menu, mode-aware close, scaffold-in-skill (onboarding-flow-spec.md Revision 2026-07-23 + §3/§4d/§7/§8)
>
> ### WP7l: Greenfield sample lands in the user's own working directory (+ disposal at close) — ✅ SHIPPED 2026-07-27 (built 783bdf2; ACCEPTED in the 2026-07-27 hands-on greenfield run)
> **AS-BUILT (2026-07-25):** Built jointly with WP7n in one feature (both edit the arm's close; 7n.3 owned the merge). The arm now invokes `new-sample.sh --dest .`, stamping **flat into the user's cwd** — no `$TMPDIR` copy, no `cd` away, files `ls`-visible where the user is standing (which is what beat A depends on). Empty-cwd requirement + refuse-and-explain path (explicitly: never `--force`, never silently fall back to a temp dir — stop and ask). `tutorial-getting-started` Step-0 hardened from "an empty folder is ideal" to a stated **requirement** with its consequence, so the refusal stays a rare backstop. Swept 4 downstream staleness sites the change created (the WP7i upfront-framing "and `cd` in"; the replay-guard expectation at arm entry; the Step-8 replay invite's new-empty-folder instruction; the greenfield-needs-no-git-safety rationale, which had rested on "it works in a disposable throwaway copy"). **`new-sample.sh` itself UNCHANGED — verify-before-edit confirmed it already implemented `--dest` + the no-clobber guard; the bug was purely the arm's invocation.** Codify: scaffold suite 15 → 20 (new group 9 pins `--dest .` flat-stamp + runnable-on-its-OWN-`./todos.txt` + store-resolution + non-empty-cwd refusal via recursive tree compare; group 8 gained a `--dest` wiring assertion) — **all mutation-verified.** verify-self 8/8 + a fresh-subagent 5/5 on an in-place shortcut. Review-quality 0C / **2 MAJOR (both FIXED in-feature, not backlogged** — a spec beat-table resync my own revision header had falsely claimed, and a group-9 assertion that overrode `TODO_STORE` and so never tested the store the tour actually uses) / 5 MINOR auto-backlogged.
> **⚠️ NOT ✅ SHIPPED — the operator's verify-human copy acceptance is DEFERRED and OWED** (operator: *"defer to when all the fixes are in place"*), so this WP is **BUILT, not accepted**. Integration boundary applies (prose changed inside shipped, consumed skill prompts) → the F11-skip path was forbidden and the Mode-3 auto-skip gate correctly did NOT fire. Flip to `✅ SHIPPED` **only** after the greenfield-arm re-acceptance lands (after WP7m). **One OPEN DESIGN QUESTION owed with it:** the ratified "refuse if non-empty" means the guard fires on **every replay** — mitigated in copy, but if the operator dislikes it on reading, the passed-over ask-with-`./onboarding-sample-todo/`-subdir-fallback is cheap NOW and expensive after WP7e pins. Full record: archived WIP `greenfield-tour-cwd-sample-and-close-restructure.md` → `## Deferred human gate`.
> **Provenance:** Operator's **batch hands-on acceptance walkthrough** (2026-07-25), greenfield feedback
> item 1, verified against the origin session log
> (`~/.claude/projects/-Users-stayman-Work-Tmp-mccc-tutorial-a/b2828bad-….jsonl`). **What actually
> happened:** the arm ran `new-sample.sh` bare → the sample landed in `$TMPDIR/onboarding-sample.4FuWOA/todo`
> and the agent `cd`'d there. The operator had to *ask mid-tour*: **"Can you copy it over to the current
> directory?"** — the agent then ran `cp -R "$TMPDIR/…/todo/." ~/Work/Tmp/mccc-tutorial-a/`, **flat into
> the cwd**, which the operator accepted and ran the rest of the tour from. Operator's stated rationale:
> the user should *"easily know where the files are without having to cd into a temporary folder."*
> **This is a fix to the arm's behavior, NOT to `new-sample.sh`** — the script already supports
> `--dest DIR` (+ a `--force` no-clobber guard); the arm simply never passed it.
> **Note — the shipped dispatcher copy ALREADY promises this behavior**, so this is a
> copy/behavior *divergence*, not a design change: `tutorial-getting-started` Step 0 greenfield tells the
> user to `cd` into an empty folder because *"it'll create its own small throwaway sample project **there**"*
> (`skills/tutorial-getting-started/SKILL.md:72-81`). WP7l makes the arm honor the promise Step 0 makes.
> **Operator rulings (2026-07-25, `AskUserQuestion`):**
> - **Non-empty cwd → always flat, refuse if non-empty.** Stamp flat into the cwd when it's empty; if the
>   cwd is non-empty, **stop and tell the user to `cd` to an empty directory and re-run**. Chosen over
>   ask-with-subdir-fallback and always-subdir. ⚠️ **Build-time caveat (agent-flagged, operator-acknowledged):**
>   a hard refusal is a wall for a brand-new user who launches from a populated dir, so this WP must
>   **strengthen the Step-0 pre-flight copy** so the refusal is a rare backstop, not a common blocker
>   (Step 0 already says "empty folder is ideal" — make it unambiguous + state the consequence).
> - **Disposal → offer to clean up at close.** The tour currently has **NO teardown anywhere** (verified:
>   grep for `revert|rm -rf|cleanup|teardown` across all four `tutorial-*` skills + both design docs →
>   zero hits; the sample survives until the OS clears it). With the sample now in the user's *real* cwd
>   this matters more. At close, **offer** a one-line teardown the user accepts or declines (not
>   auto-remove — that would destroy the artifacts the close cites as proof; not silence).
>   **Copy-order constraint:** the close cites the artifacts as evidence *before* offering to remove them,
>   so the offer lands after the proof, never in place of it.
> **Description:** Make the greenfield arm stamp the sample **into the user's current working directory**
> (`new-sample.sh --dest .`-equivalent) instead of a `$TMPDIR` throwaway it `cd`s away into, with an
> empty-cwd precondition + refusal path, matching Step-0's existing promise; add the offer-to-clean-up
> beat at the arm's close. Touches: `skills/tutorial-greenfield-workflow-tour/SKILL.md` (env section
> ~L81-113 + the close), `skills/tutorial-getting-started/SKILL.md` Step-0 greenfield branch (strengthen),
> `scripts/new-sample.sh` **only if** the `--dest .` path needs a guard it lacks (verify before editing —
> the `--dest`/`--force` surface already exists), its `test/` smoke, and `onboarding-flow-spec.md` (§3
> greenfield env + §8 build constraints). **Also re-check the full-cycle tour** (`tutorial-product-cycle-tour`)
> — it ships `scripts/brief.md` as a written brief, so it likely needs no change, but confirm the
> where-do-files-land story stays consistent across the family.
> **Milestone:** 11 · **Dependencies:** WP7c/WP7i (the sample + stamper), WP7j (scaffold re-home — the
> arm's current invocation path) · **Size:** S–M
> **Gates:** WP7e (accepted copy before pins). Prose + small shell-guard; **no transition/state-machine change.**
> - [x] 7l.1 Arm stamps into the user's cwd (flat) via the existing `--dest` surface; empty-cwd precondition + refuse-and-explain path when non-empty
> - [x] 7l.2 Strengthen `tutorial-getting-started` Step-0 greenfield copy so the empty-dir requirement is unambiguous (and the refusal is a rare backstop)
> - [x] 7l.3 Offer-to-clean-up beat at the arm close, ordered *after* the artifacts-as-proof lines
> - [x] 7l.4 Verify/adjust `new-sample.sh` + its smoke for the `--dest .` path (verify-before-edit: the surface may already suffice); confirm family consistency incl. the full-cycle tour
> - [x] 7l.5 Reflect into `onboarding-flow-spec.md` (§3 greenfield env, §8 constraints)
>
> ### WP7m: Tour-aware session boundary — narrate an in-tour boundary, don't offer it — ✅ SHIPPED 2026-07-27 (built e7e682b, framing CORRECTED; ACCEPTED in the 2026-07-27 hands-on greenfield run)
> **AS-BUILT (2026-07-27):** Guard added to **both arms** (`### The tour hosts the workflow — a close
> inside the tour is NOT the session's boundary` under `## Category`, read early every run) + a
> staged-vs-real disambiguation blockquote at the head of **Step 7** in both arms (~40 lines *above*
> the scripted `/session-handoff`, so it is read before the action). The guard forbids **both** taking
> and offering the exit chain, names `S22`/`S23` explicitly, and scopes itself to **all four drive
> modes**. **7m.1 settled: the guard lives in the ARMS, not the general session skills** — this
> satisfies the stated "keep tour knowledge out of the general skills" preference at *zero* cost and
> makes 7m.3 (general `S22`/`S23` unchanged for real work) true **by construction**, since the general
> skills are not edited at all. Rejected: a "hosted inside a tutorial run" precondition in
> `session-reflect`/`session-handoff` (tour knowledge in two heavily-used general skills + a real
> regression surface + needs an in-tour detection signal that does not exist), and an on-disk in-tour
> marker (a new cross-skill artifact for what arm prose solves).
> **⚠️ ESCALATION CLAUSE CHECKED AND NEVER FIRED** — no new transition ID, no new edge, no modeled
> table row, **zero** edits to `transitions.md` or the 4 `agents/*/AGENTS.md` pause tables (both
> verified as empty-`git diff` assertions, now pinned). `/feature-plan`-first was correct.
> **Origin-log grounded:** the misfire was recovered verbatim from the origin session's raw log
> (`~/.claude/projects/-Users-stayman-Work-Tmp-mccc-tutorial-a/edf22b62-….jsonl` msg 45 → operator's
> "continue the tour" at msg 48) before planning, per the read-the-origin-session-log convention.
> **4th tour surface checked, no guard needed (verified not assumed):** `tutorial-product-cycle-tour`
> also runs a staged `/session-handoff` but drives only `product-vision → roadmap → research → arch →
> wbs` and reaches **zero** terminal closes (`grep -Ei 'finalize|task-close|session-reflect'` → 0
> hits), so `S22`/`S23` can never fire there. Asymmetry is load-bearing, not an oversight.
> Codify: **13 pins** in `check-structure.sh` **[Phase 18]** (the existing `S22`/`S23` phase — the
> guard is a precondition on that same chain), **all mutation-verified** across 4 mutation classes;
> suite **472 → 485 PASS** / 1 pre-existing settings-fixture FAIL (triaged as out-of-scope host drift,
> deliberately not bundled). Pins scoped to **copy-independent invariants only**; wording/ordering/
> sentence-count pins left to **WP7e** against accepted copy. verify-self 12/12 (7 mechanical + 5
> coherence, incl. an independent cross-check that the guard cannot over-fire onto Step 7's own beat).
> **⚠️ NOT ✅ SHIPPED — verify-human DEFERRED and OWED.** Integration boundary applies (prose inside
> shipped, consumed skill prompts) → F11-skip forbidden, Mode-3 auto-skip correctly did NOT fire.
> Operator 2026-07-27: *"defer. I'll just do a full tour again after changes are done."* **WP7m is the
> third and last of the three fixes**, so the condition set at the WP7l gate is now met: **ONE full
> hands-on greenfield run accepts WP7l + WP7n + WP7m together**, and must also answer the **still-open
> WP7l design question** (refuse-if-non-empty fires on every replay; the `./onboarding-sample-todo/`
> subdir fallback is cheap now, expensive after WP7e pins). Flip all three to ✅ SHIPPED only then.
>
> #### WP7m (original ratified scope)
> **Provenance:** Operator's batch acceptance walkthrough (2026-07-25), greenfield feedback item 2. The
> operator pasted the exact misfire: after the tour's in-tour feature reached `feature-finalize` →
> `session-reflect` with nothing to persist, the agent recognized the **`S22` clean-boundary auto-chain**
> and then *offered a fork* — "Continue the tour" vs. "Hand off now (`/session-handoff`)" — **in Session C of the designed chain, one step after the tour had already performed its staged Step-7 handoff**, with
> Step 7 Scene 3 and all of Step 8 still unrun. **Operator ruling:** *"It should just continue the tour
> without offering the hand off option."*
> **Root cause (verified, NOT merely copy):** `S22` (`reflect → session-handoff`, no-learning arm) is
> **modeled AUTO in all four drive modes** at a clean workflow boundary
> (`workflow-system/product/transitions.md:137,481` + the "Session-boundary exit chain" pause-policy block
> replicated in all 4 `agents/*/AGENTS.md`), and **neither `session-reflect` nor `session-handoff` has any
> tour-awareness** (grep for `tour|tutorial` in both SKILL.mds → zero hits). So the in-tour
> feature's close *correctly* presents as a clean boundary and pulls toward a handoff. Compounding it: the
> tour's **own** Step 7 Scene 2 legitimately instructs an `/exit` + fresh session, so two competing
> "boundary" notions coexist — the tour's staged one and the state machine's real one. The agent's
> hedge-and-ask was a *reasonable* local read of a genuine ambiguity; the fix is to remove the ambiguity.
> **Description:** Make the boundary rule tour-aware so a tour-hosted terminal close does not present or
> take the session-handoff exit chain, while leaving the general `S22`/`S23` behavior untouched for real
> work. **Design intent: a narrow guard clause on the existing edge — NOT a new transition ID** (the
> `tutorial-*` family already emits no transitions; adding one would contradict the family invariant).
> Settle at plan time *where* the guard lives — candidates: (a) the tour arms declare an in-tour marker the
> boundary chain consults, (b) `session-reflect`/`session-handoff` gain a "hosted inside a tutorial run"
> precondition, (c) the arms pre-empt it by instructing the orchestrator at the in-tour close. Prefer the
> option that keeps tour-specific knowledge **out of** the general session skills if the cost is comparable.
> Also make the tour's own Step-7 `/exit` boundary and the state machine's boundary explicitly distinct in
> the arm copy, so the two can't be conflated again.
> **Milestone:** 11 · **Dependencies:** WP7d/WP7g/WP7j (the Step-7 bookend + Step-8 close this interacts
> with) · **Size:** S–M
> **Scoping ruling (operator, 2026-07-25):** **own WP, `/feature-plan`-first** (not `/feature-spec`) — a
> narrow guard on an existing edge, no new transition IDs. ⚠️ If plan-time analysis shows the guard *does*
> require a new edge, a modeled table row, or edits to the pause-policy tables in all 4 `agents/*/AGENTS.md`,
> **stop and escalate to `/feature-spec`** (`F28`-style) rather than widening in place — that would be
> state-machine surface, and the three-places sync rule (`transitions.md` / `SKILL.md` / scenarios) applies.
> **Gates:** WP7e (accepted behavior before pins).
> - [x] 7m.1 Settle the guard's home at plan time (prefer keeping tour knowledge out of the general session skills); confirm no new transition ID is needed
> - [x] 7m.2 Implement the guard so a tour-hosted close neither offers nor takes the handoff exit chain
> - [x] 7m.3 Keep general `S22`/`S23` behavior unchanged for real (non-tour) work — verify explicitly, this is the regression risk
> - [x] 7m.4 Disambiguate the tour's staged Step-7 `/exit` boundary from the state machine's boundary in the arm copy
> - [x] 7m.5 Reflect into `onboarding-flow-spec.md` + (only if an edge/table changes) `transitions.md` + the 4 `agents/*/AGENTS.md`
>
> ### WP7o: Tour state survives the session boundary — ✅ SHIPPED 2026-07-27 (built ccfedac + 438d88e; ACCEPTED in the 2026-07-27 hands-on greenfield run) · **SUPERSEDES 7m.1**
> **Provenance:** the operator's 2026-07-27 greenfield **re-acceptance** run — the very run WP7l/WP7m/WP7n were
> waiting on. It reported two defects: (1) *"The mode defaulted to orchestrated for the first run!"* and
> (2) *"The 2nd boundary handoff offer still showing up. But at least better than previous walkthrough."*
> **Root cause (one gap, both defects):** the tour's state — that a tour is running, which step is next, which
> drive mode — lived **only in the conversation** and died at `/exit`. Nothing was written to disk, so nothing
> survived the boundary the tour is built around. Defect 1: the first-run branch wrote `drive_mode` **nowhere**
> (only the replay branch recorded it), so the handoff correctly omitted it and `/session-restore` fell through
> to its `orchestrated` default *and* showed the 1–4 menu. Defect 2: **`resume_skill` pointed at the inner
> workflow's next state** (`/feature-ship`), so Session C legitimately held two competing continuations.
> **Why this supersedes 7m.1.** WP7m settled the guard's home as *"in the ARMS, not the general session skills."*
> The raw Session-C log disproves that placement: the only skills loaded there were `/session-restore` →
> `feature-ship` → `feature-review-quality` → `feature-finalize` → `session-reflect`. **The arm is never
> re-invoked** — so an arms-only guard is *structurally unreachable* across a session boundary, which is why
> WP7m's copy fix softened the fork but could not remove it. WP7o adopts what 7m.1's own candidate list called
> option **(b)** (a precondition in `session-reflect`/`session-handoff`), which 7m.1 had *preferred to avoid* —
> correctly, on the information it had. **7m.1's spirit is preserved:** the arms own all tour *narration copy*;
> the general skills carry only a **mechanical `tour:` field read**. `check-structure.sh` [Phase 18] block (i)
> was rewritten to pin exactly that narrowed invariant (fail-closed `[ -f ]` precondition retained).
> **⚠️ PARTIALLY SUPERSEDED 2026-07-27 by WP7e:** the `tour_step:` field named in the AS-BUILT record below and
> in task 7o.1 was **DROPPED** — it was written by four files and read by none. `tour:` alone is the marker, and
> resume is **arm-addressed, not step-addressed**. The text below is preserved verbatim as the as-built record of
> what WP7o shipped on 2026-07-27; it is **history, not the current contract**. Current schema of record:
> `skills/session-handoff/SKILL.md` §2, "Tour-driven handoffs". Everything else in the record still holds.
>
> **AS-BUILT (2026-07-27, 4 phases):** **P1** — `.session.md` gains optional tour-only `tour:`/`tour_step:`;
> `session-restore` takes the mode from a tour pointer (cannot reach the `orchestrated` default) and
> **suppresses the 1–4 menu, naming no mode at all**; `session-reflect`/`session-handoff` narrate a tour-hosted
> boundary instead of chaining `S22`/`S23`. **P2** — both arms write the fields, record `drive_mode: stepping`
> silently on the first run (**recording ≠ revealing**), and set **`resume_skill` to the arm**, so Session C is
> one thread: the arm finishes the inner work, then plays Step 8. **P3** — §D resolved (below). **P4** — pins
> narrowed + docs resynced + behavioral scenarios.
> **No state-machine surface.** No new transition ID, no new edge, no pause-policy row; `S22`/`S23` unchanged for
> real work. Verified as an **empty diff** on `transitions.md` and all four `agents/*/AGENTS.md` at every phase.
> The 7m-style escalation clause was re-checked each phase and **never fired**.
> **§D ANSWERED (the open design question WP7l left owed).** Operator: *"refuse if non empty, offer to delete the
> content of the dir"* — the `./onboarding-sample-todo/` subdir fallback is **rejected**. Implemented with four
> hard rules (show the real `ls -A` listing **before** asking · **explicit** consent only, a bare
> "go"/"proceed"/"ok" is *not* consent · the different-folder option is an **equal peer** · never `--force`,
> never auto-delete, never a temp dir) and two absolute limits (**a git working tree is never cleared**, checked
> *before* the offer so a repo never sees it; deletion bounded to the cwd's own contents). Decline **or any
> ambiguity** → nothing touched. **Greenfield-only** (a real repo has nothing disposable).
> **⚠️ NOT ✅ SHIPPED — verify-human DEFERRED+OWED on all four phases** (integration boundary applies on each →
> F11-skip forbidden, Mode-3 auto-skip correctly never fired). **WP7l + WP7n + WP7m + WP7o now ride ONE
> acceptance run** — the operator's next hands-on greenfield walkthrough. 15 owed leaves recorded in the WIP.
> **Notable finds the coherence reads caught that no grep could:** the reader guards were **inert** at the moment
> they needed to fire (restore *deletes* the pointer, and no arm was writing `tour:` to the WIP — names matched
> while the value was absent at read time); and the §D git pre-check was *correctly worded but placed after* the
> copy-paste offer script, so an agent could have offered to delete a repo and retracted it. Both fixed in-phase.
> **Milestone:** 11 · **Dependencies:** WP7l/WP7m/WP7n (it corrects their acceptance run's findings) · **Size:** M
> **Gates:** WP7e (accepted behavior before pins) — **WP7e still codifies LAST**, against copy accepted across all
> four tour surfaces.
> - [x] 7o.1 Carry tour state in the session pointer (`tour:`/`tour_step:`, optional + inert when absent)
> - [x] 7o.2 First-run branch records `drive_mode: stepping` silently; restore honors it and suppresses the menu
> - [x] 7o.3 `resume_skill` → the ARM, so Session C reloads the arm and reads as one thread
> - [x] 7o.4 Narrow block (i) to "mechanical field read yes, narration copy no"; keep the fail-closed guard
> - [x] 7o.5 §D: refuse-if-non-empty **+ offer to clear**, with the destructive protocol (greenfield-only)
> - [x] 7o.6 Resync `onboarding-flow-spec.md` + `tutorial-tour-session-chain-flow.md` (invariants 7 + 8)
> - [x] 7o.7 Behavioral scenarios for the fix (the operator's mid-session scope correction)
> - [x] 7o.8 `[Phase 18b]` — property-test block (i)'s narration probe against its **own anchor set** (added at
>   verify-codify, hardened at refactor). The probe was mis-anchored twice in-feature and **both rounds shipped
>   green**: a pin can assert its *file* is clean but never that its *anchors* are right. Five directions
>   (liveness · sensitivity · specificity · clean-tree · case-stability), anchors held in a bash **array** with
>   the probe joined from it — one source of truth, no parser to fail open. Exhaustively mutation-verified: all
>   11 anchors deleted individually, every deletion yields ≥1 FAIL, **0 unguarded**. Suite 495 → 516.
>
> ### WP7n: Step-8 close restructure — terse decision block at the bottom — ✅ SHIPPED 2026-07-27 (built 783bdf2; ACCEPTED in the 2026-07-27 hands-on greenfield run)
> **AS-BUILT (2026-07-25):** Built jointly with WP7l. **Both arms'** closes restructured to narrative-first / decision-last: graduation-reveal (Branch A) or acknowledge-the-gear (Branch B) → replay **motivation** compressed to one line → "what we didn't demo" → **artifacts-as-proof** → **`Next Step:` block LAST**. Per-branch, ≤3 sentences/option (verified 8/8 options), options **named never auto-run**; Branch B carries **no replay option** (they're already in one). The full replay invitation is compressed into option 1 with its load-bearing mechanics **preserved, not dropped** — direct arm re-entry NOT the dispatcher · session-boundary crossing · gear from the arm's own on-entry menu · plus greenfield's new-empty-folder (WP7l) / brownfield's clean-baseline-first — each restated in a "Mechanics that must stay correct in the block" guard so future compression can't silently break them. WP7l's disposal ruling landed here: a cleanup **offer** (never auto-remove) as the block's last line, **after** the artifacts-as-proof so the tour never asks to remove the evidence before showing it — **greenfield only** (brownfield's no-cleanup-offer and no-deep-dive-pointer are stated as *prohibitions*, not omissions). **The full product-cycle tour's close was verified per-file and deliberately LEFT UNCHANGED** — already three numbered beats in a stated order (~30 lines) with the actionable beat in plain sight; a `Next Step:` block there would be ceremony and would rub against its ratified no-replay/no-mode-menu invariant. (Reviewer independently agreed, with the honest caveat that its actionable beat is #2-of-3 rather than last — recorded for operator override if strict cross-family symmetry is wanted.) verify-self 10/10 incl. machine-verified strict ordering in both arms and all 13 beats confirmed surviving the re-order.
> **⚠️ NOT ✅ SHIPPED — same DEFERRED-and-OWED verify-human acceptance as WP7l** (one read over the finished greenfield arm after WP7m). **Known gap, measured not assumed:** deleting BOTH `Next Step:` blocks still passes every existing check — the `tutorial-*` family has zero structural pins (`grep -c tutorial tests/check-structure.sh` = 0). Left to **WP7e** by its documented charter, logged as `SURFACE-2026-07-25-WP7N-CLOSE-STRUCTURE-UNPINNED` with the concrete pin list **and** the caveat that a naive sentence-count pin is flaky (it folds the trailing `Housekeeping:` line). 4 of the 5 backlogged MINORs are user-facing copy → settle them inside WP7e's copy-freeze, before pins lock.
> **Provenance:** Operator's batch acceptance walkthrough (2026-07-25), greenfield feedback item 3, on the
> pasted live close. Operator verdict: *"The drive mode option got buried with this large body of corpus.
> At the very bottom it should have a very clear and brief section saying `Next Step:` `Option 1: …`
> `Option 2: …`, each option no more than 3 sentences. The details can be provided above it, not at the
> bottom."*
> **Verified:** greenfield Step 8 is ~108 lines (`skills/tutorial-greenfield-workflow-tour/SKILL.md:286-394`)
> emitting, in order: graduation reveal → un-push → replay invitation → "what we didn't demo" → deep-dive
> pointer → close/artifacts. The actionable choice (replay in a faster gear vs. go build something real vs.
> the deep-dive tour) is genuinely interleaved with prose rather than presented as a decision.
> **Description:** Restructure the arm close so the narrative lands *first* and a short, scannable
> **`Next Step:`** block sits **last**, with each option ≤3 sentences. Keep every currently-shipped beat —
> this is a **re-ordering + compression** task, not a content cut: the graduation reveal, the deliberate
> un-push ("Not recommended yet."), the replay invitation's three load-bearing mechanics (direct arm
> re-entry / session-boundary crossing / gear from the arm's own menu), the named-not-staged
> "what we didn't demo", the WP7h.1 deep-dive pointer, and the artifacts-as-proof list all survive.
> **Interacts with WP7l.3** — the offer-to-clean-up beat also lands at the close, so the two must be
> sequenced/merged deliberately rather than each appending independently.
> **Apply to BOTH arms** (brownfield Step 8 has the same shape) and **re-check the full-cycle tour's close**
> for the same burial pattern — the operator marked the other three surfaces "good", so treat the
> brownfield/full-cycle edits as consistency work, applied only where the same burial actually exists
> (verify per-file before editing; do not assume symmetry).
> **Mode-awareness must survive:** the close is already two-branch (Branch A first-run reveal / Branch B
> replay acknowledge, WP7j.4). The `Next Step:` block therefore differs per branch — Branch B must not
> re-offer a replay it's already in.
> **Milestone:** 11 · **Dependencies:** WP7j (mode-aware two-branch close), WP7k (the deep-dive pointer in
> the close), WP7l (the cleanup offer shares this surface) · **Size:** S
> **Gates:** WP7e (accepted copy before pins). Prose-only; **no transition/state-machine change.**
> - [x] 7n.1 Greenfield Step-8: move narrative above, add the terse `Next Step:` block last (≤3 sentences/option), per-branch (A vs B)
> - [x] 7n.2 Preserve every shipped beat + the replay invitation's 3 mechanics (re-ordering, not cutting) — verify none lost
> - [x] 7n.3 Merge/sequence with WP7l.3's offer-to-clean-up so the close has one coherent tail
> - [x] 7n.4 Brownfield arm + full-cycle tour: apply the same restructure **only where the burial actually exists** (verify per file)
> - [x] 7n.5 Reflect into `onboarding-flow-spec.md` (§3 close shape / §6 honest framing) + `full-product-cycle-tour-design.md` if its close changed
>
> **Ratified rulings log (2026-07-22):** (i) permission mode = **auto** (not acceptEdits/bypass), with
> availability caveat + launch command; (ii) replay invite = **own small WP** (WP7j); (iii) sample =
> **redesign now**, richer skeleton, keep copy-per-run stamper; (iv) full product-cycle tour = **in M11
> scope** (WP7h part-b promoted); (v) README/snippet pointer = **yes** (WP7f.2); (vi) WP7d MINORs = **fold
> into WP7g** (7g.5). M11 no longer completes at WP7e alone — it completes when {WP7g, WP7h, WP7i, WP7j}
> land + are accepted + WP7e codifies. **UPDATE 2026-07-24:** WP7h split into **design (done) + build
> (WP7k)** per operator ("build should be a WP added to the WBS"); the WP7k build is sequenced **BEFORE**
> the batch hands-on acceptance run (operator, 2026-07-24) so the single acceptance walkthrough covers
> all four tour surfaces in one pass. M11 now completes when {…, WP7h-design ✅, WP7k-build} land →
> batch acceptance run → WP7e codifies against all four tour surfaces.
>
> **UPDATE 2026-07-25 — batch acceptance run DONE; 3 greenfield fixes ratified as WPs (P11 SURFACE-IN).**
> The operator ran the batch hands-on acceptance walkthrough and returned with feedback recorded in
> `tmp/wp7e-batch-acceptance-walkthrough.md` → `## Feedback`. **Verdict: the other three tour surfaces
> (brownfield arm · WP7g corrections · WP7k full-cycle tour) PASS as-shipped** ("everything else are
> good") — only the **greenfield arm** drew fixes. Per operator instruction ("plan each fix as a WP"),
> the three fixes are ratified as **WP7l** (sample in the user's own cwd + disposal offer), **WP7m**
> (tour-aware boundary — narrate an in-tour boundary rather than offering it), **WP7n** (Step-8 close restructure, terse
> `Next Step:` block last). All three **gate WP7e** — pins lock *accepted* copy, so WP7e still codifies
> last, now against all four surfaces including the WP7l/WP7m/WP7n changes. Each fix was
> **verified against the real code + the origin session log before being written up** (per the
> review-finding-actions-are-hypotheses discipline): WP7l's cause was the arm never passing the
> already-existing `--dest`, WP7m's was the modeled `S22` AUTO chain plus zero tour-awareness in the
> session skills — i.e. WP7m is a real behavior gap, not a copy tweak. **Operator's open question
> answered in-session:** the tour performs **no revert/teardown at all** today (grep-verified across all
> four skills + both design docs), which is what makes WP7l's disposal ruling necessary now that the
> sample lands in the user's real cwd. Ratified via `AskUserQuestion` 2026-07-25 (3 rulings: refuse-if-non-empty ·
> offer-to-clean-up · WP7m plan-first). Revised M11 tail: **{WP7l ∥ WP7n} → WP7m → re-accept the greenfield
> arm → WP7e (codify)**.

---

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
- **M11 internal critical path:** WP7a → WP7b → WP7e (WP7c and WP7d parallelize between WP7b and WP7e). **Walkthrough expansion (2026-07-22):** after WP7d, the corrections/redesign track {WP7g ∥ WP7h ∥ WP7i ∥ WP7j} runs, then a fresh operator hands-on acceptance run, then WP7e codifies against the *accepted* copy. **WP7h split (2026-07-24):** WP7h is now design-only-done; its build is **WP7k**, sequenced **BEFORE** the batch acceptance run (operator, 2026-07-24) so one walkthrough accepts all four surfaces. Revised M11 tail: {WP7g ✅ ∥ WP7h-design ✅ ∥ WP7i ✅ ∥ WP7j ✅} → **WP7k ✅ (2026-07-24, commit 8bbf5c1)** → **batch hands-on acceptance run** (all four surfaces, operator-owed) → **WP7e** (codify all four). M11 completes when that whole set lands — not at WP7e alone. **Now remaining in M11: the batch acceptance run → WP7e.**
- **Parallel track:** WP5 (pause) and WP6 (research collision) — DONE (both shipped 2026-07-21).
- **Operator pause points:** WP7.1 onboarding brainstorm — **DONE 2026-07-21** (co-design settled; `onboarding-brainstorm.md`). Remaining M11 pause points are the normal per-feature plan-review + verify-human gates as each sub-WP runs through the feature workflow. AD-1 Option A operator-ratified.

## Ordering rationale
- **M7 before everything** — the settled layout (Option A physical roots) is what every later WP and the return contract reference (AD-1). WP1 (decide) before WP2 (sweep) resolves the riskiest unknown (existing-project migration) cheaply before the wide mechanical change.
- **WP4 (uninstall) after M7** — uninstall must be written against the *settled* post-move layout, not the pre-move one.
- **WP4 before WP8** — the install/uninstall command copy is a return-contract deliverable.
- **WP5/WP6 unordered** — no learning or build dependency; smallest items, safe to interleave; do NOT block on M7. (Both DONE.)
- **M11 last-but-one** — brainstorm-first (DONE), depends on settled layout + install flow; now FULL BUILD, decomposed WP7a–WP7e. Internal order = spec-first (WP7a fixes the name/flow everything builds against), then the entry-skill spine (WP7b), then scaffold ∥ beats-wiring (WP7c/WP7d), then codify (WP7e). WP7a's spec feeds WP8.
  - **M11 tail after the 2026-07-25 batch acceptance run:** the walkthrough-driven expansion (WP7f–WP7n) is ordered by the **pins-lock-accepted-copy** rule, which is a *learning* dependency, not a build one — every copy/behavior correction must be operator-accepted before WP7e freezes pins, else the pins cement copy the operator would have changed. Current order: **{WP7l ∥ WP7n} → WP7m → greenfield re-acceptance → WP7e**. **STATUS 2026-07-27: WP7l + WP7n + WP7m are ALL BUILT (783bdf2 + WP7m 2026-07-27) but NOT accepted** — the operator deferred the verify-human copy read until all three fixes are in, WP7m has now landed, so the next step is **ONE full hands-on greenfield tour run** (operator 2026-07-27: *"defer. I'll just do a full tour again after changes are done"*) which accepts all three (flipping them to ✅ SHIPPED) and answers the open refuse-if-non-empty design question, then WP7e. WP7l/WP7n are parallel-safe apart from the arm's close, which both edit (7n.3 owns the merge); WP7m follows so its guard placement is settled against an already-restructured close rather than racing a third concurrent edit to the same region. WP7m is the only one of the three that can reach state-machine surface — if plan-time analysis shows it needs a new edge or the 4 `agents/*/AGENTS.md` pause tables, it escalates to `/feature-spec` instead of widening in place.
- **WP8 terminal** — aggregates deliverables back to Claudesk (**including the required M11 `docs_list` path change** + the onboarding flow spec from WP7a).
- No environment/Docker WP (this repo is host-based shell + prompt files, no services). No 3rd-party probe WPs (no external integrations). No orchestration/async WPs (none in scope). **No M11 probe WP** — the only unknown was the *design*, resolved by the brainstorm; the sub-WPs are all build. Deviations from the standard ordering sequence are all "N/A — no such surface in this cycle."
