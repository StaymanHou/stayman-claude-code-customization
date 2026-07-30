---
stage: arch
state: complete
updated: 2026-07-28
---

# Architecture

**Phase:** Phase 1 (Problem Tree & Structured Verification) + Phase 2 (Agent Self-Verification)

This system has no runtime, no services, and no database. The "architecture" is entirely: file schemas that skills read and write, and skill prompt contracts that enforce behavior. Every decision here is a format decision or a skill contract decision.

---

## Dev Environment

**Host-based (opt-out).**

**Rationale:** This repo contains only markdown files and shell scripts. There are no services, no language runtimes to isolate, no dependency graphs. The only runtime dependency is the `claude` CLI itself, which runs on the host. Docker would add friction with zero benefit — there is nothing to containerize.

---

## Tech Stack

- **Format:** Markdown — established convention for all existing skills, WIP files, and fixtures. No change.
- **Structured metadata within markdown:** Inline HTML comments `<!-- status: X -->` — chosen over YAML frontmatter (too high token cost for inline node annotation) and JSON embedding (breaks human readability). HTML comments are invisible in rendered markdown, machine-readable by LLM, and zero overhead.
- **Position pointer:** A `## Current Node` section in every WIP file — a compact human-readable summary of where in the tree the agent currently is, what is in scope, and what is blocked. Eliminates full-tree re-parse on every skill entry.
- **Playwright MCP:** `mcp__playwright__` tool namespace — for live-system self-verification. Tools declared in skill `allowed-tools` frontmatter, invoked as direct tool calls (not bash).

---

## File Schema: Work Tree WIP Format

This replaces the current flat-checklist WIP format. All feature and task WIP files adopt this schema.

### Full annotated example

```markdown
# Feature: <Name>

**Workflow:** feature
**State:** <current skill state>
**Created:** <YYYY-MM-DD>

## Problem Statement
<One paragraph. Re-examined on every back-loop entry — not static.>

## Work Tree
<!-- Rules:
  - Max 4 levels: Feature > Phase > Verification-group > Leaf
  - Every non-complete node carries a status tag
  - A parent's checkbox can only be [x] when ALL children are [x]
  - Discoveries attach as SURFACED leaf nodes under the relevant parent
-->

- [ ] Phase 1: <name>  <!-- status: complete -->  ← use [x] when done
  **Observable outcomes:**
  - Browser: <declarative outcome>
  - HTTP: <declarative outcome>
  - CLI: <declarative outcome>
  - [x] P1.1 <impl task>
  - [x] P1.2 <impl task>
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete -->
    - [x] <check item>
    - [x] <check item>
  - [x] verify-codify  <!-- status: complete -->

- [ ] Phase 2: <name>  <!-- status: in-progress -->
  **Observable outcomes:**
  - Browser: page at /login renders with input[name=email], input[name=password], button[type=submit]
  - Browser: no JS errors in console on page load
  - HTTP: POST /api/login with valid creds → 200 + Set-Cookie header
  - [ ] P2.1 <impl task>  <!-- status: in-progress -->
  - [ ] P2.2 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 3: <name>  <!-- status: NOT-STARTED; depends on Phase 2 -->
  **Observable outcomes:**
  - <...>

## Current Node
- **Path:** Feature > Phase 2 > P2.1
- **Active scope:** P2.1 (currently implementing)
- **Blocked:** verify-human > check-C (blocked by check-A resolution)
- **Unvisited:** Phase 3
- **Open discoveries:** none

## Discoveries
<!-- Surfaced items that don't belong to the current phase.
     Each entry is also logged to workflow-system/state/backlog.md.
     Format: [SURFACED-<date>] <target node> — <summary> -->
```

### Status vocabulary

| Tag | Meaning |
|-----|---------|
| `NOT-STARTED` | Node exists in plan, not yet reached |
| `in-progress` | Agent is actively working this node |
| `FAILED` | Human or agent reported failure; must be resolved before parent advances |
| `BLOCKED: depends on <node>` | Cannot be tested/executed until named node is resolved |
| `SURFACED: <summary>` | Discovery attached here; agent logged it to backlog |
| `[x]` checkbox (no tag) | Complete — all children also complete |

### Depth rule

Four levels maximum: **Feature > Phase > Verification-group > Leaf item**. If a phase becomes too complex, split into two phases (siblings) rather than adding a 5th level.

---

## File Schema: Task WIP Format (lighter variant)

Tasks are simpler — no per-phase verification loop, no observable outcomes section. But they gain the same Current Node pointer and discovery attachment.

```markdown
# Task: <Name>

**Workflow:** task
**State:** <current skill state>
**Created:** <YYYY-MM-DD>

## Problem Statement
<One sentence. Re-examined on back-loop entry.>

## Work Tree
- [ ] T1 <step>  <!-- status: in-progress -->
- [ ] T2 <step>  <!-- status: NOT-STARTED -->
- [ ] T3 <step>  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Task > T1
- **Active scope:** T1
- **Open discoveries:** none

## Discoveries
```

---

## File Schema: Design Priors Format (`workflow-system/product/design-priors.md`)

A per-project, durable product doc recording the operator's **design priors** — terse, transferable statements of how the operator resolves recurring *product-design* tradeoffs for this project, each paired with its *why*. Planning skills **consult** it to fill product-design gaps the operator's way; capture-checkpoint skills **propose** new priors (operator reviews before write). Priors are **directional and overridable**, never decisive — see "Design priors (GLOBAL)" in `CLAUDE.snippet.md` for the consult-weighting rules and capture discriminant.

**This doc lives in *consuming* projects, never in this repo's own `workflow-system/product/`** — the skill repo ships the schema + skill contracts (behavior), not state (vision.md §6). Absent file = silent no-op at consult time. Created lazily on the first approved capture.

```markdown
---
stage: design-priors
state: in-progress        # priors accrete over time; rarely "complete"
updated: <YYYY-MM-DD>
---

# Design Priors — <project>

<!-- Each prior is terse (a few lines). Fields:
  - slug:          short kebab-case ID, e.g. P-FOCUS (used in [PRIOR: <slug>] disclosures)
  - axis:          the tradeoff axis OR an identity/non-goal/anti-persona statement
  - lean:          the direction the operator leans on that axis, for THIS project
  - inferred-why:  the why CC could infer from the operator's choice alone
  - corrected-why: the operator's true why — PRESERVED as a distinct field WHEN it differs
                   from inferred-why (the gap is the signal this feature exists to capture).
                   Omit only when operator confirms inferred-why is already correct.
  - date:          capture date (YYYY-MM-DD)
-->

## P-FOCUS — audience breadth
- **axis:** laser-focus on one use-case vs. broad applicability
- **lean:** focus — solo founders only; resist breadth toward agencies/teams
- **inferred-why:** operator rejected the agency generalization
- **corrected-why:** the product's bet is depth-for-one-demographic; breadth dilutes the wedge
- **date:** 2026-06-26
```

**Size guard:** consistent with the 300-line product-doc rule (consult-load reads first 100 lines + `^#+ ` headings if exceeded). Priors are terse precisely so this is rarely hit.

---

## Skill Contract Changes

### Skills that write the Work Tree

| Skill | Change |
|-------|--------|
| `feature-plan` | Emits Work Tree format with Phase nodes, Observable Outcomes per phase, all verification group nodes pre-populated as `NOT-STARTED` |
| `task-plan` | Emits lighter Work Tree format with step nodes and Current Node |

### Skills that read + update the Work Tree

| Skill | Entry action | Exit action |
|-------|-------------|-------------|
| `feature-build` | Read Current Node for scope. If scoped args present (failed leaf IDs), restrict work to those leaves only. Attach discoveries to correct phase node. | Update leaf statuses. Update Current Node. Verify no parent has all-complete children without being marked complete itself. |
| `feature-verify-auto` | Read current phase's Observable Outcomes. Run live-system checks (Playwright/curl/CLI) against them. Classify failures as blocking/cosmetic. | Write results as leaf nodes under `verify-auto` node. Update `verify-auto` status. Update Current Node. |
| `feature-verify-human` | Read current phase's `verify-human` node. Expand into leaf items if empty (first run). Present only items not yet `[x]`. Note BLOCKED items explicitly. | Update each leaf's status individually. If any `FAILED`, update Current Node with failed leaf IDs as active scope for re-entry to build. Only mark `verify-human` complete when ALL leaves are `[x]`. |
| `feature-verify-codify` | Read phase node to confirm verify-human is complete before proceeding. | Update `verify-codify` status. If all phases complete, update feature-level status. |
| `task-act` | Read Current Node for scope. Attach discoveries to correct task node. | Update node statuses. Update Current Node. |

### Skills that add Playwright tools

| Skill | New allowed-tools additions |
|-------|----------------------------|
| `feature-verify-auto` | `mcp__playwright__browser_navigate`, `mcp__playwright__browser_snapshot`, `mcp__playwright__browser_console_messages`, `mcp__playwright__browser_take_screenshot` |
| `feature-build` (re-verify gate) | Same as above — needed for re-verify after fix |

---

## Key Decisions

- **HTML comments for status, not YAML frontmatter:** Inline node metadata must live next to the node, not in a separate section. YAML frontmatter can only appear once per file. HTML comments survive markdown rendering, are invisible to humans reading rendered output, and are reliably parsed by LLMs. Alternative (inline emoji badges like `🔴`) was rejected — ambiguous, not machine-readable by convention.

- **`## Current Node` as position pointer, not derived from tree parse:** The LLM should not have to re-traverse the full tree on every skill entry to find its position. Current Node is a first-class section, written on skill exit, read on skill entry. It is the authoritative answer to "where are we and what's in scope." If it ever diverges from the tree (bug), the tree wins and Current Node is rewritten.

- **Observable outcomes written at plan time, not verify time:** At plan time, the agent understands intent. At verify time, it understands implementation. Outcomes written at verify time are post-hoc and biased toward what was built. Outcomes written at plan time define the target and catch cases where what was built doesn't match what was intended.

- **`feature-verify-auto` gains live-system observation, not just test runner:** The self-verification step runs Playwright/curl against Observable Outcomes before handing to human. This is not a replacement for the test suite — both run. The test suite catches unit-level regressions; the live-system check catches integration failures, environment issues, and UX-visible breakage that tests don't exercise.

- **Re-verify gate lives in `feature-build`, not `feature-verify-auto`:** When build re-enters after a human rejection, it must self-verify before handing back. This gate belongs at build exit, not verify-auto entry — because the agent doing the fix knows exactly what it changed and should immediately verify the specific failed items, not re-run the full suite.

- **Playwright MCP falls back gracefully:** Skills check whether Playwright MCP is available. If not, they fall back to curl for HTTP checks and note which browser checks could not be completed. The human checklist for those items is annotated "agent could not verify — check manually." No hard failure if MCP is absent.

---

## What Does NOT Change

- The state machine in `workflow-system/product/transitions.md` — no new states, no new transitions for Phases 1–2. The tree format changes what lives inside WIP files; it does not change the state machine.
- The `feature-spec`, `feature-research`, `feature-ship`, `feature-finalize`, `feature-refactor` skills — they don't touch the Work Tree during Phase 1.
- Product-workflow skills (`product-*`) — unaffected by Phases 1–2.
- Incident-workflow skills — unaffected.
- `session-*` skills — unaffected. The Work Tree is carried transparently through pause/resume because it lives in the WIP file.
- `install.sh` — no new files, no new symlinks needed for Phases 1–2.

## Revision 2026-07-20

### Claudesk Handoff Cycle — architectural decisions (Milestones 7–12)

Inbound from `HANDOFF-from-claudesk-2026-07-20.md`. This repo owns the *mechanics* of making the workflow system pleasant for a new, non-workflow secondary user (the *audience-stance* vision refinement lives on the Claudesk side, not here). This cycle adds **no new runtime dependencies** and **no new state-machine transitions** — all changes are doc-convention, prompt, and shell-script. The decisions below are the ratified inputs to `/product-wbs`. Sources: `docs/product/roadmap.md` (Milestones 7–12), `docs/product/research.md`.

#### AD-1 (Milestone 7) — Doc-layout unification: **Option A (physical unification under one root)** — operator-ratified 2026-07-20

> **Superseded the initial Option-B lean.** This decision was first recorded as Option B (index-only, no move). The operator overrode it (see **P8 back-loop below**): the two-folder split is *itself* the confusion for any newcomer unfamiliar with this customization — an index leaves the split in place and does not remove the confusing thing. Option A removes it. The original Option-B rationale is preserved in the back-loop note for the record.

- **Decision:** **Physically unify** the two doc locations under **one top-level folder with two clearly-named subfolders** (working names, finalizable in build):
  - `docs/product/*` → **`workflow-system/product/`** (strategic: vision, roadmap, research, arch, wbs, context, `archive/`)
  - `workflow/*` → **`workflow-system/state/`** (operational: `wip/`, `backlog.md`, `backlog-*.md`, `.session.md`, `archive/`)
  - Result: **one folder a newcomer must learn** (`workflow-system/`); the strategic-vs-operational distinction survives as legible substructure.
- **Rationale (operator):** The pain is not merely orientation — the **existence of two separate top-level folders is the confusion** for any user not already fluent in this customization. A single top-level home directly removes it; an index only describes it.
- **Accepted cost:** the **~59-file path sweep** (38 skills, 14 tests, 5 agents, `CLAUDE.md`, `CLAUDE.snippet.md`) plus the three-places-in-sync regression surface (`transitions.md` / `SKILL.md` / scenarios), and a **required Claudesk `docs_list` change** (M11 discovers the old paths). These are accepted deliberately — the newcomer-clarity payoff justifies the blast radius. Timing is favorable: Claudesk M11 is **paused/unshipped**, so its `docs_list` can be pointed at the new layout before it ships (the M12 return contract carries the new paths).
- **Migration safety:** paths appear in prompt *prose* (not just code), so the sweep is a text-substitution across `skills/ agents/ tests/ CLAUDE*.md` with a full `check-structure.sh` + `run-tests.sh` verification gate. `git mv` preserves history for the moved dirs. The per-project nature matters: **this is a convention change for all consuming projects**, not just this repo — the skills emit the new paths, so every project that adopts an updated skill starts writing to `workflow-system/`. A migration story for *existing* consuming projects (old `docs/product/` + `workflow/` already on disk) must be decided in WBS (skills tolerate both during transition, or a one-time migration helper — parallels the `memory-link` migration precedent).
- **Cross-repo consequence:** Claudesk M11's `docs_list` **must** be updated to glob the new roots (`workflow-system/product/*.md` + `workflow-system/state/...`). This is an explicit M12 return-contract deliverable, not an optional note.

**P8 back-loop (2026-07-20):** WBS→arch reversal of AD-1. The initial Option-B lean (index-only) was ratified in the first pass of this revision on cost grounds — a 59-file move to solve what was framed as an *orientation* cost, plus avoiding a Claudesk `docs_list` change. The operator reframed the problem at WBS review: the two-folder split is the confusion itself, not a describable-around orientation gap, so an index under-solves. Reversed to Option A; the 59-file sweep + Claudesk coordination are accepted. `docs/product/research.md`'s blast-radius measurement stands and now scopes the *accepted* work rather than arguing against it.

> **AS-BUILT (2026-07-21, WP3-M7 resync — the `doc-layout-unification` feature shipped).** AD-1 is implemented. Notes below reflect what actually happened; the decision/back-loop text above is preserved as the record.
>
> - **Final names (confirmed, unchanged from the working names):** `docs/product/*` → `workflow-system/product/`, `workflow/*` → `workflow-system/state/`.
> - **This repo's own move:** done via plain `git mv` in the feature's Phase 1 (`6fedeb5`) — 133 renames, history preserved. Path references rewritten across **58** source files (the ~59-file estimate held). The sweep was **path-anchored**, not word-level — the token "workflow" is overloaded (803 bare concept-word occurrences vs 343 path refs), so a naive substitution would have corrupted every conceptual mention. Three false-positive classes were caught and excluded (`-workflow/AGENTS.md` orchestrator-file tails, `workflow/state`/`workflow/process` prose). Two intentional non-targets left on old paths: `tests/sessions/*.jsonl` (frozen audited historical captures) and `tests/results/*.json` (gitignored output).
> - **Regression lock:** `tests/check-structure.sh` **Phase 15** (4 pins) asserts no stale `docs/product/`|`workflow/<child>` path reappears + both unified roots stay referenced (420/0).
> - **Existing-project migration:** the "one-time migration helper" option was chosen (not skills-tolerate-both). Built as **`tools/migrate-doc-layout/`** (`26e9d5f`), mirroring `tools/memory-link/`: idempotent, `--dry-run`, `--date`, timestamped reversible backup, drift-keep-both, `git mv` history preservation, 35-assertion test suite, README. Ran across **9 projects** (this repo + 8 others under `~/Personal/projects` + `~/Work/Kenosis`); **`gospelherald.com.hk` deliberately excluded** (carrying over its 2026-07-03 memory-link exclusion). All migrated with history preserved.
> - **Known-scope note (SURFACE-2026-07-21-MOVED-PRODUCT-DOCS-INTERNAL-PATH-REFS):** the *moved* product docs' own internal path refs are a mix of live-operational-prose (updated) and historical/subject-matter (preserved — e.g. the migration mapping in this very AD-1, which must NOT be rewritten). This as-built note itself is category-B: the "`docs/product/*` → `workflow-system/product/`" arrows above are the migration record and are intentionally not rewritten.

#### AD-2 (Milestone 8) — `uninstall.sh` mirrors `install.sh`, symmetric + defensive

- **Decision:** A standalone `uninstall.sh` (pure bash, zero Claudesk dependency) that reverses each thing `install.sh` sets up, using the **same idempotency + safety contract** install already uses:
  1. **Symlinks** (skills, agents, hooks, plus the legacy `claude-time` hook.pl + CLI bin — retired from this repo 2026-07-29, so install no longer creates them but uninstall still removes them **unconditionally** to avoid stranding pre-retirement installs) — `rm` **only** when the link exists AND its resolved target points *into this repo* (mirror install's "exists but not a symlink → skip, manual resolution needed" guard; never remove a non-symlink or a foreign-target link). The into-repo test has a raw-`readlink` fallback, which is what lets it still reclaim a **dangling** legacy link whose target was deleted with the tool.
  2. **CLAUDE.md snippet block** — excise **only** the marker-delimited block between `<!-- BEGIN claude-workflow-system -->` and `<!-- END claude-workflow-system -->` via the same `awk` block-delete install uses for replacement; **never** delete `~/.claude/CLAUDE.md` wholesale; back up before editing (mirror install's `.bak` discipline).
  3. **Per-project memory symlink** — remove the `~/.claude/projects/<slug>/memory` *symlink* only; **never** touch the real store it points at (`<proj>/.claude/memory`). Reuse `tools/memory-link/lib-slug.sh` for realpath-safe slug derivation (the documented footgun).
  4. **settings.json perms** — install only *prints* these (does not auto-write), so uninstall correspondingly only *prints* a reminder of what to remove; it does not edit `settings.json` unless a later install revision starts auto-writing a hook registration (then reverse exactly that block).
- **Rationale:** an unclean uninstall (leftover symlinks, a half-excised snippet, a clobbered CLAUDE.md, or a deleted memory store) is exactly the "residue" the try-and-back-out story must avoid. Symmetry with `install.sh` keeps the two in lockstep as the single source of truth.
- **Verification target (for WBS):** `install → uninstall → re-install` round-trips clean and idempotent.

#### AD-3 (Milestone 10) — "research" collision: **disambiguation-first, rename-as-fallback**

- **Decision:** Treat the collision as a **semantic description-matching routing risk**, not a name clash. First-line fix: sharpen the `description`/trigger phrasing of `product-research` + `feature-research` so they read as **unambiguously workflow-scoped** (they run *inside* a workflow state, not "research the web"), plus orchestrator-prompt disambiguation. A **rename is a fallback only** if disambiguation proves insufficient in practice.
- **Rationale:** research + web-search confirmed there is **no literal identifier collision** — CC's built-in is `/deep-research`; this repo has `product-research`/`feature-research`. CC skill activation is *semantic* (matches the request against skill descriptions), so a rename would not fix the semantic-match problem and would incur the full three-places-in-sync cost (transitions IDs, SKILL.md, scenarios, CLAUDE.md) for little gain. Disambiguation attacks the actual failure mode at low cost.

#### AD-4 (Milestone 9) — "pause" disambiguation: pure prompt-convention

- No architectural surface beyond *which prompts change*: the orchestrator AGENTS.md files + relevant SKILL.md prose. The convention (reserve bare "pause" for course-correction; require explicit `/session-pause` or a distinct phrase for the skill; confirm intent when ambiguous) is a prompt edit + behavioral scenario, no state-machine change. Detailed decomposition deferred to WBS.

##### AD-4 addendum (as-built 2026-07-21) — boundary-handoff auto-chain promoted into the state machine + capture-gate conditional drop

The WP5/M9 disambiguation shipped the "auto-chain the session handoff at a clean workflow boundary, even in autopilot/FSD; confirm only on mid-workflow ambiguity" rule as **advisory prose only** (in `session-handoff/SKILL.md`, the 4 orchestrator `AGENTS.md`, and `CLAUDE.snippet.md`). A follow-up feature (`boundary-handoff-autochain-state-machine`, from `SURFACE-2026-07-21-BOUNDARY-HANDOFF-AUTOCHAIN-NOT-IN-STATE-MACHINE`) **promoted that rule from prose into the state machine** — closing the same drift class as the P1 autopilot-pause incidents (a chaining decision asserted in prose the orchestrator reads inconsistently, with no transition ID or pause-policy row). Two decisions, both as-built:

- **D1 — no `finalize → handoff` shortcut.** The full exit chain is always `finalize/refactor/close/resolve → reflect → [capture] → handoff`. `reflect` is never skipped — it is the only step that can judge "nothing to persist," and it is the once-per-session learning-filter + design-prior-capture backstop. The fork happens *at* reflect: **no-learning arm** auto-chains straight to `session-handoff` (edge **S22**); **learning-found arm** runs `session-capture`, then after the save lands auto-chains to `session-handoff` (edge **S23**).
- **D2 — meta-op edges, not first-class states.** `session-handoff`, `reflect`, and `session-capture` remain *meta-operations* (the transitions.md "not a state-machine state" declaration is preserved). The chain is modeled as **modeled edges (`S22`/`S23`) + pause-policy rows**, not by promoting any meta-op to a dispatched workflow state. The new **"Session-boundary exit chain"** pause-policy block in `transitions.md` "Drive modes" AND in all 4 canonical `agents/*/AGENTS.md` cheat-sheet tables is the **authoritative** source for the chaining decision; the guard prose is re-pointed to say so ("read the table row, not this bullet"). Three-places-in-sync (transitions.md / the 4 AGENTS.md / `tests/scenarios/session.yaml`) is enforced by `tests/check-structure.sh` [Phase 18].

- **Bundled behavior change — AC-6 capture-gate conditional drop.** The *one* genuine behavior change (everything else models already-shipped behavior): `session-capture`'s §4 confirmation gate is now **drive-mode-conditional**. In autopilot/FSD, a **`[PROJECT]`-scope** learning **auto-writes** (no STOP-and-ask) and is **surfaced in chat as a read-time veto** (path + content + scope printed *before* the `git amend`, so the operator can `git reset`); a **`[GLOBAL]`-scope** learning **keeps the confirm gate** even in autopilot/FSD (higher blast radius — every logged `session-reflect` scope-correction was `[GLOBAL]`→`[PROJECT]`). Modes 1/2 are unchanged (always confirm). This streamlines the unattended exit for the common project-scope case without a blind global write. Behavioral coverage: `tests/scenarios/session.yaml::S28`/`S29`/`S30`.

This addendum records the state-machine change as-built; the canonical convention text lives in `CLAUDE.snippet.md` → "Session vocabulary — turn vs. session boundary (GLOBAL)".

#### AD-5 (Milestone 11) — onboarding: **deferred / designed later (brainstorm-first)**

- Explicitly **not architected now.** It is a design activity co-owned with the operator, dependent on the settled AD-1 index layout and the AD-2 install/uninstall flow. Arch acknowledges it exists and is sequenced last; its shape (a dedicated onboarding SKILL.md and/or a throwaway tutorial project) is a WBS/brainstorm output, not an arch decision. WBS should carve it as a design-spike work package, not an implementation WP.

##### AD-5 addendum (as-built 2026-07-28) — onboarding went deferred → designed → **BUILT**; the prediction held

AD-5's deferral was **correct and is now discharged.** It predicted that onboarding's shape would be "a WBS/brainstorm output, not an arch decision," and that is exactly what happened: the 2026-07-21 co-design brainstorm settled the shape, the operator chose FULL BUILD (not spec-only), and M11 delivered it across sub-WPs WP7a–WP7o **entirely inside AD-5's envelope** — so this was a normal decomposition and **never a P8 arch back-loop**.

**What was actually built** (the arch-visible surface, not the flow internals):

- **A four-skill `tutorial-*` family** — `tutorial-getting-started` (entry/dispatcher) + `tutorial-greenfield-workflow-tour` and `tutorial-brownfield-workflow-tour` (the two arms) + `tutorial-product-cycle-tour` (the deep-dive graduation tour). Three files rather than one enforce the spec's "diverge and stay diverged" invariant **structurally** instead of by prose discipline.
- **A new skill category.** `tutorial-*` joins `debug-*` and `util-*` as a non-state category: these skills own **no state-machine node**, appear in **no** orchestrator `skills:` frontmatter, and **emit no transition**. Note the deliberate divergence from the `util-`/`debug-` file-prefix convention — the prefix is `tutorial-`, and WP7e's pins deliberately do **not** assert a `util-` prefix.
- **No new runtime and no new architectural element.** No new transition ID, no new edge, zero changed lines in `transitions.md` or the four `agents/*/AGENTS.md` pause tables across all of M11. The tour *hosts* a real feature/task workflow rather than adding one.
- **Skill-local runnable content.** The greenfield sample + scaffolder live in `skills/tutorial-greenfield-workflow-tour/scripts/`, **not** repo-root `tools/`. This is load-bearing, not cosmetic: `install.sh` symlinks each skill's *whole directory* but does not symlink `tools/`, so an invited user gets the sample automatically with **no `install.sh` change and no separate fetch step**.
- **The tour is a CHAIN of real session boundaries**, not one dispatched session — the entry skill points the user at an arm and hands off across `/exit`. Authoritative flow: `docs/lessons/tutorial-tour-session-chain-flow.md`.

**One published external interface now exists** (the only genuinely arch-level consequence): `workflow-system/product/onboarding-flow-spec.md` **§4 "Claudesk Surface Contract"** is a **cross-repo contract** that Claudesk builds against, and the command name **`/tutorial-getting-started` is a published interface** — the sole stable coupling Claudesk may depend on. Renaming it is a return-contract change, not a local refactor. This is why the spec is treated as **durable, not cycle-scoped**, and why WP7e pins the name structurally. Delivered to Claudesk by WP8/M12 (2026-07-28).

**Design-prior capture check:** still no new `design-priors.md` prior. M11's decisions were pedagogy/mechanics (staged-vs-named beats, what the tour hosts, where scripts live) — technical/operational, which the arch-boundary exclusion keeps in *this* file. The product-design lean in this space (audience/anti-persona gating) remains Claudesk's per the handoff. `design-priors.md` stays absent here (silent no-op).

### Design-prior capture check (this cycle)

No new `design-priors.md` prior proposed. The candidate lean — "favor low-blast-radius/orientation fixes over large refactors for the new-user audience" (AD-1) — is a **technical/operational tradeoff** (blast-radius vs. clarity), which the arch-boundary exclusion keeps in *this* file, not `design-priors.md`. The genuinely *product*-design lean in this space (audience/anti-persona gating for the non-workflow user) is being captured on the **Claudesk** side per the handoff, not duplicated here. `design-priors.md` remains absent in this repo (silent no-op).

## Revision 2026-06-26

### Design priors — learned product-design decision principles (`workflow-system/product/design-priors.md`)

A new durable product-doc schema (see "File Schema: Design Priors Format" above) plus a capture/consult skill contract. Planning skills (`product-roadmap`, `product-wbs`, `feature-spec`) **consult** the doc at their `## Step 0` product-context load to fill product-design gaps the operator's way; capture-checkpoint skills (`product-vision`, `product-roadmap`, `product-arch`, `product-wbs`, `feature-spec`, `feature-verify-human`) and the `session-reflect` backstop **propose** new priors (operator reviews the why before write). Priors are directional/overridable, never decisive — the consult-weighting rules, capture discriminant, arch-boundary exclusion (technical/stack tradeoffs stay in *this* file, not design-priors), and the `[PRIOR: <slug>] leaning <x> — flag if wrong` disclosure form are documented in `CLAUDE.snippet.md` → "Design priors (GLOBAL)". **No new transition IDs** — this is behavior within existing states. Shipped by the `design-priors` feature, 2026-06-26.

## Revision 2026-06-13

Architecturally significant additions since the 2026-05-02 revision. Each subsection points to the authoritative source rather than restating procedure — `workflow-system/product/transitions.md` is the canonical state-machine reference, `CLAUDE.md` is the convention-doc home.

### Drive modes (1–4) — orchestrator pause-policy contract

The orchestrator now exposes four drive modes that control pause aggression: **Stepping**, **Orchestrated**, **Autopilot**, **FSD**. The selected mode is recorded as `drive_mode:` in the WIP frontmatter at first skill entry, honored across `/session-handoff` + `/session-restore` (renamed from `/session-pause` + `/session-resume` in WP5/M9), and re-checked after every Skill-tool return. Mode 3 (autopilot) auto-skips `verify-human` when no integration boundary is touched AND verify-self is all-PASS. Mode 4 (fsd) skips verify-human entirely. Canonical pause-policy tables live in `workflow-system/product/transitions.md` → "Drive modes". The `TRANSITION: <id>` token at skill exit is the only machine signal — `"Run /x"` prose and `**STOP**` directives in skill output are advisory for single-step users only.

### Executable subagents vs reference-only orchestrator agents (`tools:` frontmatter marker)

`agents/<name>/AGENTS.md` files split into two structural kinds, distinguished by frontmatter shape:
- **Reference-only orchestrators** (frontmatter has `skills:`) — one per workflow group (product, feature, task, incident). Hold the state-machine view + Orchestration Procedure. NOT meant to be spawned via `Agent({subagent_type: ...})`.
- **Executable subagents** (frontmatter has `tools:`) — spawned by skills that name them. Currently `feature-verify-self-runner` (spawned by `feature-verify-self`) and `code-quality-reviewer` (spawned by `feature-review-quality`). The `tools:` field declares the subagent's tool surface.

The frontmatter shape is the structural marker, not documentation. `tests/check-structure.sh` Phase 10 ("Subagent dispatch wiring") enforces both directions: every `tools:`-bearing agent must be referenced by exactly one skill's `Agent({subagent_type: ...})` call, and every such skill call must point to a `tools:`-marked agent. Introduced 2026-06-12 by the `verify-self-and-review-quality-subagent-dispatch` feature.

### `debug-*` skill category — agent-pulled sidebars, not workflow states

A new skill category for ad-hoc debugging techniques that the orchestrator (or user) reaches for when standard debugging stalls inside an existing workflow state. Distinguishing properties:
- Own no state node; emit descriptive `DEBUG-<TECHNIQUE>-<OUTCOME>` tokens **outside** the F/I/T/P/S transition namespace.
- Always emit a `RETURN-TO: <caller-skill>` line so the caller workflow state resumes without consuming a transition ID.
- Required SKILL.md sections enforced by `tests/check-structure.sh` Phase 3b: `## Category Context`, `## When to use`, `## When NOT to use`, `## Procedure` (with `### 1. Gate Check` as the first subheading), `## Pitfalls`, `## Termination`.
- Three discoverability surfaces enforced by Phase 3c: caller-skill prose mentions, orchestrator AGENTS.md "Debug techniques" subsections, `transitions.md` "Sidebar skills" note.

Current sidebars: `debug-bisect-known-good` (codified 2026-05-13), `debug-empirical-telemetry` (shipped 2026-06-10), `debug-minimal-harness` (shipped 2026-06-23 — build a minimal self-driven reproduction and drive it with real input when a behavioral fix has been handed back ≥2× and is drivable in a surface you control). Full category convention in `CLAUDE.md` → Architecture → "`debug-*` Skill Category".

### `util-*` skill category — standalone user-triggered utilities

A third skill category for standalone utilities that the operator invokes manually outside any workflow. Distinguishing properties (vs workflow skills and `debug-*` sidebars):

- **Own no state node** and emit **no transitions** — neither workflow F/I/T/P/S tokens nor `DEBUG-*` tokens. The skill runs, does its work, and ends.
- **No `RETURN-TO:`** — unlike `debug-*` sidebars, util-* skills are not pulled by another workflow; they are entry points themselves.
- **No `tools:` frontmatter** — they are not executable subagents spawned via `Agent()`; they are plain skills invoked via slash command.
- **No `skills:` list** in frontmatter — they are not orchestrators.
- **Frontmatter shape:** `name`, `description`, `argument-hint`. Same minimal shape as a workflow skill, minus all workflow integration.
- **Mode menus are encouraged** for utilities that span an aggression spectrum (Stepping ↔ Autopilot). `util-prune-claude-md` mirrors the workflow drive-mode 1–4 spectrum at skill entry; the operator picks per-invocation rather than a persistent `drive_mode:` (no WIP file to persist into).

Current util-* skills: `util-prune-claude-md` (shipped 2026-06-13 — compacts the project-root `CLAUDE.md` against the 40k-char harness threshold by extracting bulky bullets to `docs/lessons/<topic>.md` or `workflow-system/product/arch.md`); `util-backlog-paydown` (shipped 2026-06-30 — between-milestone backlog-paydown sweep: scores the standing backlog on a 3-axis disposition model and emits a priority/risk-ordered `shape: temporary-wbs` to pay down deferred code-quality/debt; fold-back-and-delete on completion; see `docs/lessons/between-milestone-debt-paydown-sweep.md`); `util-option-mockup` (shipped 2026-07-28 — builds a lo-fi side-by-side mockup artifact to decide between several concrete UI/UX options for **one surface**, when the difference is spatial and prose or ASCII would lose it. Conjunctive trigger: ≥2 concrete alternatives for a single element/widget/component **and** a spatial/visual difference; clause (b) gated by a one-sentence self-test ("can you state the difference in one sentence and be confident the operator pictures the same thing you do?") so it does not over-fire on ordinary UI choices. Distinguished from `product-wbs`'s milestone-level "UI mockups / frontend prototypes" by **what varies** — the same surface rearranged is a decision tool, different screens or a different flow is a prototype WP. **Recommended-and-paused, never agent-pulled**: `util-*` forbids `RETURN-TO:`, so `feature-spec` §1 names it and waits rather than invoking it as a sidebar); `util-grill-me` (shipped 2026-07-29 — a relentless-but-gated elicitation interview that hardens a plan/spec/decision before it is built, adapted from Matt Pocock's `grilling` primitive and Vlad Gusinov's `grill-me` fork. **Three-clause conjunctive gate**: ask only when a decision is (a) **not discoverable** from the environment, (b) **the operator's** to make, and (c) **expensive to reverse**. Clause (c) is a deliberate **departure from the source technique**, which is relentless because it is standalone — this workflow has three verification gates behind spec, so relentlessness would spend the operator's attention on decisions those gates already catch. **Budget-as-filter, not budget-as-cap**: zero questions is a correct outcome for a well-specified request. Terminates in an **Asked / Assumed** disclosure — the `Assumed` list is what keeps ordinary document review a real backstop for the questions *not* asked. Silent on AUTO exits by the pre-existing "Hard rule for AUTO exits", not a new rule. **No mode menu** — a deliberate divergence from the mode-menus-are-encouraged guidance above, because the three-clause gate already regulates aggression and a menu would add a decision to a skill whose purpose is reducing them. **Two hosts, deliberately asymmetric**: `feature-spec` §1 carries an **inlined** block scoped to the problem-definition sections only (not Technical Constraints); `product-vision` §3 carries a **hand-off fork** instead — offered after `vision.md` is written, both arms exiting `P2`, silent in Mode 4 only. The asymmetry is load-bearing, not drift: an inlined interview in `product-vision` asked one state to pause for a human **and** emit its terminal transition in the same turn, which a single non-interactive turn cannot satisfy — it suppressed §2b's design-prior capture and survived five prose fixes before the structural move resolved it. `feature-spec` absorbed the identical block only because it has the structural capacity (nine F3/F4 restatements, a cheat-sheet table, an AUTO hard-rule block). `product-vision` also gained its own `### 4. Emit Transition` section in the same feature, closing a repo-wide gap — **no** `product-*` skill had one. Pinned by `[Phase 21]`: both host pointers section-scoped, the util-family shape, and four negative pins that `task-plan` / `feature-plan` / `product-wbs` / `product-arch` stay excluded). The pre-existing Claude-Code-builtin utilities `init`, `review`, `security-review`, `update-config`, `simplify`, `loop`, `keybindings-help`, `statusline-setup`, `claude-api`, `fewer-permission-prompts` are retroactively considered part of the util-* concept but are NOT renamed (they ship with the Claude Code harness, not from this repo's `skills/` directory). File-based util-* skills authored in this repo use the `util-` prefix; harness-builtin utilities keep their original names.

The category convention was originally forward-looking and doc-enforced only (via this section + the `util-` prefix). It is now **partially pinned**, per-skill rather than by globbing `skills/util-*/`:

- **[Phase 19]** pins the full util-family *shape* (`## Category` heading — NOT `debug-*`'s `## Category Context`; emits-no-transition as *claim AND behavior*; frontmatter carrying neither `skills:` nor `tools:`) — but **only for the `tutorial-*` family**, whose skill list it hardcodes.
- **[Phase 20]** pins `util-option-mockup`'s **host pointers** rather than its shape — the two consuming surfaces (`feature-spec` §1, `product-wbs` §3) plus a negative pin that `feature-verify-human` stays excluded (D8). The choice of target is deliberate and was measured: deleting both pointers left the suite fully green, because *the pointers, not the skill file, are the load-bearing artifact* — an undiscoverable skill is inert.
- **[Phase 21]** pins `util-grill-me`'s **host pointers AND its shape** — the first util-* skill to get both. Pointers: `feature-spec` §1 and `product-vision` **§3** (not §1 — the fork lives at hand-off), each section-scoped with **independent fail-closed preconditions on the start heading, the end heading, and file existence**. Shape: `## Category`, no `skills:`/`tools:` frontmatter, and emits-no-transition as claim AND behavior. Plus **four negative pins** (`task-plan`, `feature-plan`, `product-wbs`, `product-arch`), each with its own fail-closed existence guard. 18 assertions; 13/13 mutations caught, including both end-boundary renames and the remove-the-file vacuous-pass case.
  - **One reusable finding from its `/test-assertion-review` pass:** `[Phase 19]`'s emits-no-transition anchor, applied **file-wide**, matches 11 of 48 SKILL.md files — including `feature-spec` and `product-vision`, which *do* emit transitions, because their grilling blocks describe *grilling's* property and a file-wide grep cannot tell whose property is meant. `[Phase 21]` therefore scopes the claim to the skill's **own `## Transitions` section**, which narrows it to 2 (the util-family) and scores 0 on all seven wrong-corpus files. Any future util-family shape pin should adopt the section-scoped form, not the file-wide one.
- `util-prune-claude-md` and `util-backlog-paydown` remain **doc-enforced only**.

Pins are added per-skill as each becomes load-bearing, mirroring the `debug-*` discipline at Phase 3b/3c.

**Heading convention (intentional divergence from `debug-*`):** util-* SKILL.md files open their category-statement section with `## Category` — deliberately distinct from `debug-*` skills' `## Category Context` (which is a *pinned* debug-* structural requirement, enforced at `tests/check-structure.sh` Phase 3b). A grep-across-categories audit will therefore see two heading shapes; this is by design, not drift — util-* is a separate category with no pinned heading requirement, so the divergence is intentional and should not be "normalized" away.

### Per-phase verify loop extended with `verify-self`

The feature per-phase loop is now: **build → verify-auto → verify-self → verify-human → verify-codify**. `verify-self` (agent live-system observation) sits between automated checks and human review. Added in WP7 to close the gap where agents handed off to humans without ever observing the running system. Severity taxonomy: BLOCKING (back-loop to build, F9b) vs COSMETIC (forward to verify-human, F10b). In-place fix shortcut formalized 2026-06-09 in `skills/feature-verify-self/SKILL.md` §3 — narrow exception when three gates hold (trivial extension + fresh model invocation + audit-trail entry).

### `task-verify` single-step gate (T5a / T5b / T5c)

Every `task-act` now exits to `task-verify`, not directly to `task-close`. `task-verify` writes an observable into the WIP, runs the verification, and routes T5b (PASS → close) or T5c (FAIL → back-loop to act). Pure-docs tasks may declare `docs-only: true` in WIP frontmatter at plan time to auto-skip the gate. Mirrors `feature-verify-self`'s in-place fix shortcut shape. Shipped 2026-06-11 from `SURFACE-2026-06-09-TASK-WORKFLOW-NEEDS-LITE-VERIFY`. Full procedure in `skills/task-verify/SKILL.md`; transitions in `workflow-system/product/transitions.md` → Task Workflow.

### `feature-review-quality` — post-ship code-quality reviewer subagent

A new state between `feature-ship` and `feature-finalize` invokes a one-shot `code-quality-reviewer` Agent subagent against the ship commit baseline. Severity-tier action matrix (advisory by default, operator-veto via WIP read):
- **CRITICAL** → auto-invokes `feature-refactor` (F40, Modes 2–3)
- **MAJOR** → Mode 2 pause-and-ask (F41) or Mode 3 auto-backlog (F39)
- **MINOR** → auto-backlog (F39)
- **Mode 4** (fsd) skips the skill entirely; `feature-ship` emits F17b directly to finalize when `drive_mode: fsd`

Transitions: F38 (ship→review-quality), F39 (clean/MINOR/Mode-3-MAJOR forward), F40 (CRITICAL→refactor), F41 (Mode-2-MAJOR forward after pause), F17b (Mode-4 SKIP). F17 retired. Reviewer prompt body lives at `agents/code-quality-reviewer/AGENTS.md` (an executable subagent definition, ~150 lines, tuned to this codebase's SKILL.md/AGENTS.md/scenario-YAML/structural-pin patterns; tripartite output: Strengths / Issues by severity / Assessment). The skill spawns it via `Agent({subagent_type: 'code-quality-reviewer', ...})`. The reviewer is **observe-only** (no Edit/Write tools); findings flow forward into refactor or backlog (auto-backlogged findings collect in `workflow-system/state/backlog-quality-findings.md`, not the main backlog). Operator's read-time veto: edit the `## Code-Quality Review` section in the WIP and mark findings `[DISMISSED]` before finalize archives the file. Diverges from `obra/superpowers`' per-task "all findings block" model — post-ship placement makes back-loops on shipped commits expensive, so advisory-default + read-time veto is the recovery surface. Shipped 2026-06-11; subagent-dispatch wiring landed 2026-06-12.

### `incident-codify` — incident-side regression coverage (I19)

Incident workflow gains its own regression-securing step between mitigate and resolve: **mitigate → codify → resolve**. Adapts feature-verify-codify's discipline (highest-level test, integration-boundary check, six-case triage table) with two incident-context flips:
1. A codify-time test failure means the mitigation didn't fix the bug → back-loop to mitigate (I19), not auto-fix the test.
2. Speed-aware paths — Path A reuses an existing reproduce-artifact; Path B writes from scratch; a defer path (I9, with SURFACE→task:plan audit trail) is available when active incident pressure makes writing coverage now infeasible.

Full procedure in `skills/incident-codify/SKILL.md`; transitions in `workflow-system/product/transitions.md` → Incident Workflow.

### `feature-reproduce` — red-green pre-spec/plan step (S18)

Bug-shape features (user describes undesirable behavior — bug, regression, broken state, wrong output) route through `feature-reproduce` *before* spec/plan. The skill produces a failing test or a documented reason local reproduction is infeasible, then hands off to spec or plan. `/session-start` classification step adds bug-shape detection as the first axis of feature classification; ambiguous cases default to skipping reproduce (user can explicitly invoke `/feature-reproduce` if needed).

### Close-commit discipline (workflow-system convention)

The four terminal-close skills (`feature-finalize`, `task-close`, `incident-resolve`, `product-finalize`) commit locally and **never** auto-`git push` — pushing is the operator's call (review window for squash/amend/follow-up-learning before publishing). `session-capture` (renamed from `session-store-learning` in WP5/M9 to avoid the `/re**stor**e` fuzzy-match collision) project-scope writes additionally `git add` + `git commit --amend --no-edit` after writing the learning file, folding the artifact into HEAD (typically the just-completed close commit per the post-reflect cadence). The amend prevents "uncommitted learning file lost in destructive git ops during the next cross-feature pause" (closed `SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH`).

**Global-scope writes follow the artifact tracking policy, NOT gitignore inspection** (corrected 2026-06-25 by the artifact-tracking-policy feature, which **superseded** the earlier "global drafts are always gitignored, opt out of the amend" rule): if the project IGNORES `<proj-dir>/.claude/learnings/` (the MAP default) the draft is left uncommitted for hand-porting; if the project OVERRIDES to TRACK it (as this workflow-system source repo does), it is amended into HEAD like a project-scope write. The discriminator is the policy + the project's declared overrides — see `CLAUDE.snippet.md` → `## Artifact tracking policy (GLOBAL)`.

Enforced by `tests/check-structure.sh` Phase 11 — 6 `grep_check` pins (4 no-push + 2 amend) + behavioral scenarios `F19`/`T10`/`I10`/`P13`-no-auto-push + `S20`-amend-head. Codifies pre-existing behavior as a load-bearing contract so future drift cannot silently reintroduce auto-push. Shipped 2026-06-12.

### `CHANGELOG.md` convention — terminal-close auto-append contract

Every project that uses this workflow system maintains a human-readable `CHANGELOG.md` at its root. The four terminal-close skills auto-append one-line entries on close with fixed entry-kind vocabulary: `**Feature shipped:**`, `**Task closed:**`, `**Incident resolved:**`, `**Backlog resolved:**`, `**Milestone:**`, `**Product cycle complete:**`. ISO-8601 `## YYYY-MM-DD` date headings, reverse-chronological across days, chronological within a day. Append must happen **before** `git mv` of the WIP file so both stage in the same commit (mitigates `SURFACE-2026-05-10-FINALIZE-RETROSPECT-LOST-IN-GIT-MV` — rename commits dropping unstaged content edits).

Canonical procedure in `CLAUDE.snippet.md` → "CHANGELOG.md convention", injected into `~/.claude/CLAUDE.md` by `install.sh`. **Delete-on-resolve (added 2026-07-15, `SURFACE-2026-07-14-RESOLVED-ENTRY-AUDIT-TRAIL-CLUTTER`):** CHANGELOG is the *sole* resolved-item record — a close **deletes** the resolved entry from `workflow-system/state/backlog.md` (and the coupled full body + stub in `workflow-system/state/backlog-quality-findings.md`) in the *same commit* as the `**Backlog resolved:**` append, under a CHANGELOG-then-delete hard invariant. The backlog files carry only open work; they never retain a `Status: resolved` line or a `## Resolved` section. Only fully-resolved items are deleted (partial resolutions are rewritten to remaining open work); buried/deferred items are a different lifecycle and are never deleted by this rule.

### Human-in-the-loop alerting (no longer wired)

There is **no notification hook** in the system. An earlier `notify-human` skill (model-driven, unreliable — the model frequently forgot to invoke it) was replaced 2026-05-06 by a deterministic `hooks/notify-telegram.sh` harness hook on `Notification`/`Stop` events; that hook was then removed entirely on 2026-06-24 as no longer needed. Human-input moments (verify-human, triage severity, plan review) still pause the conversation; the operator is simply expected to be watching the session rather than alerted out-of-band. Migration history in `workflow-system/product/transitions.md` change-log.

### Session orchestration runs in the parent conversation, not via Agent spawn

`/session-start` classifies, presents the drive-mode menu, then **drives the workflow in the current conversation** by reading the matching `agents/<workflow>-workflow/AGENTS.md` Orchestration Procedure and invoking each skill via the Skill tool. It does NOT spawn an Agent subagent. Rationale: the Agent tool is one-shot — a subagent that pauses for human input can't be resumed, which would force each human pause to respawn a fresh subagent and lose mid-step state. Keeps user dialogue continuous. Experimental subagent-per-step design parked in `workflow-system/product/transitions.md` → "Experiment: Subagent-Per-Step Orchestration" for future revisit if context growth becomes a problem.

---

## Revision 2026-05-02

Two behavioral additions from the v2 cycle (PP4 + PP5):

### Orchestrator AUTO/PAUSE pause policy

The feature-workflow Orchestration Procedure in `agents/feature-workflow/AGENTS.md` now carries an explicit pause-policy table. Every step is annotated `AUTO` (orchestrator chains immediately) or `PAUSE` (orchestrator waits for human input). The `TRANSITION: <id>` token in skill output is the machine signal; prose "Run `/x`" is for single-step users only.

AUTO steps: build, verify-auto, verify-self, verify-codify, ship, refactor, all back-loops.
PAUSE steps: spec, research, plan, verify-human, finalize, REDIRECT (F22), SURFACE F26.

This is an orchestrator-layer concern only — individual skill SKILL.md files remain agnostic about whether they're running in orchestrated or single-step mode.

### verify-codify test failure triage protocol

`feature-verify-codify/SKILL.md` now requires a mandatory triage step before any action on a failing test. Six cases:

| Classification | Confidence | Action |
|---|---|---|
| Code regression | High | Auto-fix code |
| Code regression | Low/ambiguous | Pause for human |
| Obsolete test | High | Auto-update/delete test |
| Obsolete test | Low/ambiguous | Pause for human |
| Contract conflict (both sides valid) | Any | Always pause |
| Flaky test | — | Re-run 3 total; then pause |

A `## Test Triage` artifact is written to the WIP file before any file is modified. No test file may be modified or deleted without a completed triage entry. "High confidence" = the failure has exactly one plausible explanation, stateable in one sentence without hedging.

## Revision 2026-04-27

Three design decisions revised after WBS completion:

### verify-self runs as a subagent (not in parent context)

`feature-verify-self` spawns a one-shot `Agent` with Playwright/curl tools. Playwright output (snapshots, console logs, network requests) stays in the subagent's context — parent context stays lean across multi-phase features. Trade-off accepted: the subagent is one-shot and cannot ask the user questions mid-verify. All inputs (dev URL, Observable Outcomes, severity taxonomy) must be baked into the spawn prompt. The dev URL is supplied by the user as an argument when invoking `/feature-verify-self <url>` — no magic derivation.

### Work Tree has no depth cap — recursive as needed

The 4-level maximum is removed. The tree can nest as deeply as the feature requires. The practical guidance ("prefer splitting wide phases into siblings over deep nesting") remains, but it is advisory, not enforced. This aligns with the task workflow peer model: tasks no longer map to a "lighter" variant — they use the same tree format, just without Observable Outcomes and the verify loop.

### Task workflow is a peer entry point, not a sub-workflow

The feature workflow no longer spawns tasks. Task is an independent entry point like incident. Escalation is one-way upward only (task → feature when scope grows). The feature workflow's previous ability to hand work down to tasks is removed — if work belongs at task scope, the user starts a task directly. This simplifies the cross-level mechanism: SURFACE and ESCALATE still exist, but no downward delegation.

### Tree grammar lives in CLAUDE.snippet.md (global)

The Work Tree format spec (schema, status vocabulary, rules) is defined once in `CLAUDE.snippet.md`, injected into `~/.claude/CLAUDE.md` at install time. Individual skill SKILL.md files do not duplicate the spec — they reference it by behavior (e.g., "update Current Node on exit"). This is the single source of truth for all sessions across all projects.
