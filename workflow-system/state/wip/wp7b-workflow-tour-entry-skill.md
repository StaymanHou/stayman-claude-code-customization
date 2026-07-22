# Feature: WP7b — the `tutorial-*` onboarding skill family (M11 onboarding)

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-07-22
**drive_mode:** autopilot
**Milestone:** 11 (WP7b) — Claudesk Handoff Cycle
**Design contract:** `workflow-system/product/onboarding-flow-spec.md` (WP7a shipped 2026-07-22; **Revision 2026-07-22 (WP7b co-design)** — three-skill `tutorial-` family, applied below)

## Problem Statement

M11 needs a new-user onboarding entry experience. Per the settled spec + its 2026-07-22 WP7b-co-design revision, this is built as a **three-skill `tutorial-`-prefixed family** (not one skill with an internal fork — three files enforce spec §2's "diverge and stay diverged" structurally):
- **`tutorial-getting-started`** — the entry/dispatcher: recommends `acceptEdits`, presents the new-vs-existing fork (greenfield recommended-default / brownfield first-class peer), then invokes the chosen arm skill **inline**. This is the single command Claudesk points at (`/tutorial-getting-started`, spec §4).
- **`tutorial-greenfield-workflow-tour`** — the greenfield arm: a **narrated real run** on a tiny runnable scaffold (WP7c), staging the SURFACE + verify-self grounding beats.
- **`tutorial-brownfield-workflow-tour`** — the brownfield arm: bring-your-own real code, **`/init` OPTIONAL** (skip when a `CLAUDE.md` already exists), product-workflow reverse-engineers vision/roadmap/arch (the headline aha), `product-context` revises the generated `CLAUDE.md`, NO demo.

The audience is a brand-new, mildly-skeptical, real-developer user invited via Claudesk (spec §1). This feature builds **only the three skill files as prose** (WP7b); the runnable greenfield scaffold (WP7c) and the full scene-by-scene choreography for the handoff/restore bookend + drive-modes graduation reveal (WP7d) are downstream, and codify (WP7e) is last. WP7b **forward-declares** the WP7c scaffold and WP7d bookends as touchpoints (staged where spec §7 says STAGED) so the wiring drops in cleanly. Load-bearing correctness constraints: the **honest-framing invariant** (spec §6 — narrated *real* run, no "5-min" claim, honest ~10–15 min label, per-beat pre-framing) and the **"don't force it" rule** (spec §7 — only the 6 authentically-stageable beats are guaranteed staged; everything else NAMED/opportunistic). The three skills own no workflow state and **emit no transition** (no F/I/T/P/S, no `DEBUG-*`, no `RETURN-TO:`).

## Work Tree

- [x] Phase 1: `tutorial-getting-started` — entry/dispatcher skill (7b.1 + 7b.2)  <!-- status: [x] — all children complete -->
  **Observable outcomes:**
  - CLI: `test -f skills/tutorial-getting-started/SKILL.md` exits 0; frontmatter valid YAML with `name: tutorial-getting-started`, a `description:`, an `argument-hint:`, and NO `skills:` / NO `tools:` key. Check: `grep -qE '^name: tutorial-getting-started$' skills/tutorial-getting-started/SKILL.md && [ "$(grep -cE '^(skills|tools):' skills/tutorial-getting-started/SKILL.md)" = 0 ]`.
  - CLI: `description:` avoids the bare fuzzy-matcher tokens `restore`/`resume`/`session` and bare `start` (the compound `getting-started` in the NAME is fine per spec revision, but the description stays clean). Check: `sed -n '/^description:/p' skills/tutorial-getting-started/SKILL.md | grep -ivqE '\brestore\b|\bresume\b|\bsession\b'`.
  - CLI: opens the run (universal) recommending `acceptEdits` via Shift+Tab, NOT recommending `bypassPermissions`; reassurance one-liner present. Check: `grep -q 'acceptEdits' skills/tutorial-getting-started/SKILL.md && grep -q 'Shift+Tab' skills/tutorial-getting-started/SKILL.md` exits 0; `bypassPermissions` appears only in a contrast note if at all (verify-self judges intent).
  - CLI: presents the **new-vs-existing fork** with greenfield-recommended-default / brownfield-first-class-peer framing (a default, not a funnel), and **dispatches inline** to the two arm skills by name. Check: `grep -qi 'greenfield' … && grep -qi 'brownfield' …`; both arm-skill names (`tutorial-greenfield-workflow-tour`, `tutorial-brownfield-workflow-tour`) are referenced as the inline invocation targets.
  - CLI: honest ~10–15 min framing present, "5 min"/"5-minute" claim ABSENT (spec §6). Check: `grep -qE '10.?15' …` exits 0 AND `! grep -qiE '5.?min' …`.
  - CLI: `## Category` section documents the family is `tutorial-`-prefixed, owns no state, emits no transition (NOT `## Category Context` — that's the pinned debug-* heading; arch.md 2026-07-13 intentional-divergence). Check: `grep -qE '^## Category$' …`; body states no-transition.
  - CLI: **no drive-mode menu at entry** (spec §5a — the tour stays stepping/orchestrated so beat B is visible). verify-self confirms absence of a 1–4 mode-picker at entry.
  - [x] P1.1 Create `skills/tutorial-getting-started/SKILL.md` scaffold + frontmatter (7b.1): `name`/`description`/`argument-hint` (minimal shape, no skills:/tools:), path-qualified prose, collision-safe description  <!-- status: [x] -->
  - [x] P1.2 Write `## Category` (tutorial- family; no transition; owns no state; entry point that dispatches inline) + a top-of-skill "What this is / honest framing" intro carrying the ~10–15-min narrated-real-run label (no "5-min" claim)  <!-- status: [x] -->
  - [x] P1.3 Write entry + path-fork (7b.2): universal `acceptEdits` recommendation (Shift+Tab) + reassurance one-liner (spec §5b copy); new-vs-existing fork with greenfield-recommended-default / brownfield-first-class-peer framing; inline dispatch to the two named arm skills; NO drive-mode menu  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — scoped: frontmatter YAML valid, no bare .claude/, headings present, argument-hint non-empty -->
  - [x] verify-self  <!-- status: [x] — subagent read-through, all 8 content outcomes PASS (no BLOCKING/COSMETIC). No integration boundary (isolated new artifact). -->
  - [x] verify-human  <!-- status: [x] — operator reviewed the 3 load-bearing copy passages (honest-framing intro, acceptEdits reassurance, default-not-funnel fork), approved F13. -->
  - [x] verify-codify  <!-- status: [x] — full scenarios+pins deferred to WP7e (its charter); forward pin-spec recorded in Discoveries. No integration boundary, no runtime code, no tests run. -->

- [x] Phase 2: `tutorial-greenfield-workflow-tour` — greenfield arm skill (7b.3)  <!-- status: [x] — all children complete -->
  **Observable outcomes:**
  - CLI: `test -f skills/tutorial-greenfield-workflow-tour/SKILL.md` exits 0; util-family frontmatter shape (`name: tutorial-greenfield-workflow-tour`, description, argument-hint; no skills:/tools:); `## Category` present (no-transition). Check: `grep -qE '^name: tutorial-greenfield-workflow-tour$' …`.
  - CLI: scripts the spec §3-greenfield 8-step spine — top-of-hierarchy entry (`/product-vision` or `/session-start`) → one small real thing → Work Tree state file (beat A) → verify gate pause (beat B) → STAGED verify-self grounding on the WP7c scaffold → STAGED SURFACE on the planted tangent → handoff/restore bookend (WP7d touchpoint) → drive-modes graduation reveal (WP7d touchpoint). Check: `for t in product-vision verify-self SURFACE session-handoff session-restore; do grep -q "$t" skills/tutorial-greenfield-workflow-tour/SKILL.md || echo "MISSING $t"; done` prints nothing.
  - CLI: PRE-FRAMES the two staged beats (grounding + SURFACE) per spec §6 — the "watch, it's about to actually run it and check" style framing on verify-self and the "caught a rabbit-hole" framing on SURFACE. verify-self reads for this.
  - CLI: references the WP7c runnable scaffold as the environment (forward touchpoint) and marks verify-self + SURFACE STAGED (spec §7).
  - [x] P2.1 Create `skills/tutorial-greenfield-workflow-tour/SKILL.md`: frontmatter + `## Category` + honest-framing intro (inherits the family framing; may be brief since entry set it)  <!-- status: [x] -->
  - [x] P2.2 Write the greenfield spine (spec §3-greenfield 8 steps), each beat annotated with its disposition (A/B BEAT-natural; grounding/SURFACE STAGED; handoff/restore + drive-modes forward-declared as WP7d wiring touchpoints); reinforce beat G at the pause  <!-- status: [x] -->
  - [x] P2.3 Write per-beat pre-framing copy for the two greenfield STAGED beats (verify-self grounding; SURFACE tangent); scene-by-scene bookend/graduation narration is WP7d's concern — forward-declare those touchpoints without full copy  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — scoped: frontmatter YAML valid, headings present, no bare .claude/ -->
  - [x] verify-self  <!-- status: [x] — subagent read-through, all 8 content outcomes PASS. No integration boundary. -->
  - [x] verify-human  <!-- status: [x] — AUTO-SKIP (gate clean: autopilot + verify-self all-PASS + no boundary + no consuming-surface outcome). Family framing already operator-approved at Phase 1; arm is spec-faithful choreography, no new skeptic-facing decision. Affirmation printed as read-time veto. -->
  - [x] verify-codify  <!-- status: [x] — deferred to WP7e (family-wide scenarios+pins); forward pin-spec in ## Discoveries covers all 3 skills. No boundary, no runtime code, no tests. -->

- [x] Phase 3: `tutorial-brownfield-workflow-tour` arm + no-transition doc + install.sh (7b.4 + 7b.5)  <!-- status: [x] — all children complete -->
  **Observable outcomes:**
  - CLI: `test -f skills/tutorial-brownfield-workflow-tour/SKILL.md` exits 0; util-family frontmatter shape (`name: tutorial-brownfield-workflow-tour`); `## Category` present. Check: `grep -qE '^name: tutorial-brownfield-workflow-tour$' …`.
  - CLI: scripts the spec §3-brownfield 8-step spine WITH the revision's **optional `/init`** — detect existing `CLAUDE.md` → skip `/init` when already initialized, else run `/init` → product-workflow reverse-engineers vision/roadmap/arch (headline grounding aha) → `product-context` revises the generated `CLAUDE.md` (beat A) → one small real unit of work → verify gate (beat B) → grounding/SURFACE NAMED-opportunistic (NOT staged) → handoff/restore bookend (WP7d touchpoint) → drive-modes reveal (WP7d touchpoint). Check: `grep -q '/init' … && grep -q 'product-context' … && grep -qiE 'optional|already.{0,20}(init|CLAUDE)' skills/tutorial-brownfield-workflow-tour/SKILL.md` (the optional-init conditional is present).
  - CLI: brownfield arm marks C (SURFACE) and grounding as **NAMED/opportunistic, NOT staged** (spec §7); bring-your-own real code, NO demo. verify-self reads for named-not-staged framing.
  - CLI: all three skills explicitly document they emit **NO transition** (7b.5). Check: `for s in tutorial-getting-started tutorial-greenfield-workflow-tour tutorial-brownfield-workflow-tour; do grep -qiE 'no transition|emits no|does not emit' skills/$s/SKILL.md || echo "MISSING no-transition doc in $s"; done` prints nothing.
  - CLI (harness wiring): after `install.sh` re-run, all three `~/.claude/skills/tutorial-*` are symlinks resolving into this repo. Check: `for s in tutorial-getting-started tutorial-greenfield-workflow-tour tutorial-brownfield-workflow-tour; do readlink -f ~/.claude/skills/$s/SKILL.md | grep -q "$(pwd)/skills/$s/SKILL.md" || echo "NOT LINKED $s"; done` prints nothing. (verify-self drives this — the skills must be harness-invokable.)
  - [x] P3.1 Create `skills/tutorial-brownfield-workflow-tour/SKILL.md`: frontmatter + `## Category` + intro; write the brownfield spine (spec §3-brownfield) with **optional `/init`** conditional (skip when `CLAUDE.md` exists) → reverse-engineer (headline grounding, natural not staged) → `product-context` revise (beat A) → real work → verify gate (beat B) → grounding + SURFACE NAMED-only; handoff/restore + drive-modes forward-declared as WP7d touchpoints; reinforce G at pause  <!-- status: [x] -->
  - [x] P3.2 Add explicit "Transitions: none" documentation to all three skills (util-family meta-op — 7b.5): each owns no state, emits no transition; state-machine-in-three-places sync is N/A (no transition → no `transitions.md`/scenario edit for a transition; WP7e adds behavioral scenarios + the `tutorial-`-prefix pin separately)  <!-- status: [x] — all 3 skills carry `## Transitions` = None + Category-body no-transition statement -->
  - [x] P3.3 Re-run `install.sh` to symlink all three new `skills/tutorial-*/` dirs (7b.5); heed `SURFACE-2026-07-21-INSTALL-SH-NO-ORPHAN-PRUNE` (install.sh is additive-only — three brand-new dirs, no rename → no orphan to prune)  <!-- status: [x] — all 3 symlinks resolve into repo; verified via readlink; harness picked them up live this session (no bootstrap-skip) -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->
  - [x] verify-auto  <!-- status: [x] — scoped: brownfield frontmatter YAML valid, headings, no bare .claude/ -->
  - [x] verify-self  <!-- status: [x] — subagent read-through, all 8 outcomes PASS incl. 2 family-wide (no-transition doc + frontmatter shape across all 3 skills). No integration boundary. -->
  - [x] verify-human  <!-- status: [x] — AUTO-SKIP (gate clean). Family framing operator-approved at Phase 1; optional-/init refinement was operator-directed. Affirmation printed as read-time veto. -->
  - [x] verify-codify  <!-- status: [x] — deferred to WP7e (family-wide scenarios+pins); forward pin-spec in ## Discoveries. No boundary, no runtime code, no tests. -->

## Current Node
- **Path:** Feature > all phases complete → ship
- **Active scope:** none — Phase 1/2/3 all `[x]`; feature ready for `/feature-ship`
- **Blocked:** none
- **Unvisited:** (none)
- **Open discoveries:** none
- **Note carried to WP7e verify-codify:** the "no 5-min claim" pin must be (a) honest ~10–15-min framing PRESENT AND (b) no *promise* of a 5-min tour — NOT a naive `grep 5.?min`. Full forward pin-spec in `## Discoveries`.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
- [SPEC-REVISED-2026-07-22] onboarding-flow-spec.md — WP7b co-design revised the settled name/structure: three-skill `tutorial-` family (was single `workflow-tour`), `tutorial-` prefix pinned (was no-prefix, no-pin), Claudesk command `/tutorial-getting-started` (was `/workflow-tour`), brownfield `/init` optional. Recorded in the spec's "Revision 2026-07-22" block. Not a backlog SURFACE — an in-feature spec refinement before build.
- [CODIFY-DEFERRED-2026-07-22] Phase 1 verify-codify — Full behavioral scenarios + structural pins deferred to **WP7e** (its explicit charter: family-wide scenarios for path-fork/staged-beats + `check-structure.sh` pins incl. the `tutorial-`-prefix pin). Per-phase pins now would front-run WP7e, need rework once the arm skills exist (Phase 2/3), and hit harness-bootstrap-skip (edited check-structure.sh logic won't take effect mid-session). Mirrors WP5/WP6 codify precedent (pins target shipped skills at the end). No test suite run — no runtime code, no tests written this phase (prompt-authoring feature).

## Forward pin-spec for WP7e (codify charter — implement these against the 3 shipped skills)
When WP7e writes `check-structure.sh` pins + scenarios for the `tutorial-*` family, cover at minimum:
1. **`tutorial-`-prefix pin** — all three skill dirs (`tutorial-getting-started`, `tutorial-greenfield-workflow-tour`, `tutorial-brownfield-workflow-tour`) exist and their frontmatter `name:` matches the dir (spec Revision 2026-07-22 retired the old "no util-prefix pin" binding).
2. **util-family frontmatter shape** — each has `name`/`description`/`argument-hint`, and NEITHER `skills:` NOR `tools:` (they are not orchestrators or executable subagents).
3. **`## Category` heading present** (NOT `## Category Context` — that's the debug-* pinned heading; arch.md 2026-07-13 intentional-divergence rule). Body states no-transition.
4. **No-transition doc** — each skill's `## Transitions` (or Category body) states it emits no F/I/T/P/S token.
5. **Honest-framing "no 5-min claim" pin (get the assertion shape right):** assert BOTH (a) the honest ~10–15-min framing is PRESENT (`grep -qE '10.?15'`) AND (b) there is no *promise* of a quick 5-minute tour. Do **NOT** use a naive `grep 5.?min` as the violation check — it false-positives on "10-15 min" and on the deliberate prohibition sentence ("Never promise a 'quick 5-minute tour'"). The correct violation check targets a *promissory* construction (e.g. a line that both lacks a negation like "never"/"not" AND asserts a 5-minute duration as the tour length). Simpler robust form: pin the presence of the prohibition sentence + presence of the honest label, rather than trying to grep for the absence of a claim.
6. **acceptEdits-not-bypass** — entry skill recommends `accept edits` + `Shift+Tab`; `bypassPermissions` appears only as contrast (a placement-level pin: the recommendation verb attaches to accept-edits).
7. **Behavioral scenario(s)** for the entry skill's path-fork (new→greenfield arm, existing→brownfield arm) + the staged-vs-named beat invariants — use the established `transition_id`-absent + `contains_any`→SOFT_PASS prose-behavior shape (these skills emit no transition, so assert on output prose).
Also: the fuzzy-matcher-description-collision guard (WP5) — only `session-restore` may match "restor"; the tutorial names must not shadow session-* prefixes (spec Revision re-check already confirmed clean).

## Scope boundary (what WP7b does NOT do — downstream sub-WPs)
- **WP7c (scaffold):** the tiny RUNNABLE greenfield scaffold + planted authentic tangent. The greenfield arm *references* it as a forward touchpoint; not built here.
- **WP7d (beats-wiring):** the full scene-by-scene choreography copy for the handoff→restore bookend + drive-modes graduation reveal + verify-pause-visibility guard + named-at-close pointers. WP7b forward-declares these touchpoints in both arms; does not write their full narration.
- **WP7e (scenarios + pins):** behavioral scenarios + `check-structure.sh` structural pins, INCLUDING the **`tutorial-`-prefix pin** on all three skills (spec revision retired the old no-util-prefix binding). WP7b adds none.
- **AD-5 as-built resync:** deferred to `/product-finalize` on M11 completion (records the `tutorial-` family + the prefix decision). Not a WP7b step.
