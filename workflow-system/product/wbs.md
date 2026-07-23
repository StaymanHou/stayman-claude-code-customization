---
stage: wbs
state: complete
updated: 2026-07-23
progress: 6/8 top-level WPs done (WP1, WP2, WP3-M7, WP4, WP5, WP6); M11 sub-WPs — WP7a ✅ WP7b ✅ WP7c ✅ WP7d ✅ WP7f ✅ WP7g ✅ WP7i ✅ (2026-07-22) WP7j ✅ (2026-07-23, grew S→L: session-chain flow correction + replay + git-safety + mode-aware close + scaffold re-home); M11 tail remaining → WP7h (full product-cycle tour) + WP7e (codify, last); WP8 pending
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
**Milestone:** 11 · **Dependencies:** WP7b–WP7d · **Size:** S–M
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
> ### WP7h: Full product-cycle "full experience" tour + pointer (FB-2) — RATIFIED IN-SCOPE
> **Description:** The greenfield tour keeps the product entry a deliberate *light taste*; that implies a
> heavier counterpart. **Operator ruling: the full product-flow tour IS in M11 scope** (not a deferred
> follow-on). Two parts: **(a)** add a **pointer note** in the greenfield arm (Step 2 and/or Step-8
> named-at-close) to the full product-cycle tour; **(b)** design + build a new `tutorial-product-cycle-*`
> (name TBD) tour that walks the full product lifecycle (vision → roadmap → research → arch → wbs →
> features), honest-framing §6 preserved (this is the heavier, longer counterpart). Part (a) rides WP7g;
> part (b) is its own sizeable build within M11.
> **Milestone:** 11 · **Dependencies:** WP7b (light-taste arm exists) · **Size:** XS (pointer) + M–L (full tour)
> - [ ] 7h.1 Pointer note in greenfield arm → the full-cycle tour (rides WP7g)
> - [ ] 7h.2 Design the full product-cycle tour (name + flow + spec update) — its own `/feature-spec` or `/feature-plan`
> - [ ] 7h.3 Build the full product-cycle tour skill + wire it; codify (scenarios + pins) with WP7e or its own codify
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
> **Ratified rulings log (2026-07-22):** (i) permission mode = **auto** (not acceptEdits/bypass), with
> availability caveat + launch command; (ii) replay invite = **own small WP** (WP7j); (iii) sample =
> **redesign now**, richer skeleton, keep copy-per-run stamper; (iv) full product-cycle tour = **in M11
> scope** (WP7h part-b promoted); (v) README/snippet pointer = **yes** (WP7f.2); (vi) WP7d MINORs = **fold
> into WP7g** (7g.5). M11 no longer completes at WP7e alone — it completes when {WP7g, WP7h, WP7i, WP7j}
> land + are accepted + WP7e codifies.

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
- **M11 internal critical path:** WP7a → WP7b → WP7e (WP7c and WP7d parallelize between WP7b and WP7e). **Walkthrough expansion (2026-07-22):** after WP7d, the corrections/redesign track {WP7g ∥ WP7h ∥ WP7i ∥ WP7j} runs, then a fresh operator hands-on acceptance run, then WP7e codifies against the *accepted* copy. M11 completes when that whole set lands — not at WP7e alone.
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
