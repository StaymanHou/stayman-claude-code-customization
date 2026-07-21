---
feature: docker-init-randomize-host-ports
state: ship (complete)
drive_mode: autopilot
created: 2026-06-06
shipped: 2026-06-06
ship_commit: 5872554
source: SURFACE-2026-06-06-DOCKER-INIT-RANDOMIZE-HOST-PORTS
---

# Feature: Docker init — randomize host ports + verify-self environment-misrouting clause

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-06

## Problem Statement

[Updated 2026-06-06: scope narrowed and placement revised after verify-human rejection — see Plan revision request below for full reasoning.]

When `skills/product-context` generates a project's `CLAUDE.md` from the Docker Mandate variant (Variant A in `skills/product-context/SKILL.md`), the generated dev-environment guidance should instruct the operator to **randomize host-side ports from the ephemeral range (49152-65535) rather than using well-known defaults** for each `host:container` mapping in `docker-compose.yml`. The container-internal port stays canonical (postgres 5432, redis 6379, vite 5173, etc.); only the `host:container` left side is randomized. This prevents the failure mode observed in Replicator-1.0 on 2026-06-06 where a `5173:5173` mapping collided with another local Vite project bound to the same host port and verify-self landed in the wrong app — reporting BLOCKING fails for every UI outcome with the root cause being environmental, not code. The guidance lives in `product-context` because dev-compose-init is a per-project, near-one-time event (once at project init; rarely revisited unless arch changes), so the right home is the skill that runs at project init and writes the CLAUDE.md that future skills read. The detection-layer concern (verify-self misrouting suspicion) was originally bundled here but is dropped from this feature — the existing Subagent Re-Verification Heuristic already covers snapshot-timing artifacts; an environment-misrouting `debug-*` sidebar is the right shape if the pattern recurs, but that defers until we observe the recurrence.

**Problem updated** because the original framing put the rule in the wrong namespace (global snippet — read by every skill in every conversation, ~60 lines burned on per-project init) and attached detection logic to the wrong skill (verify-self is observe-only). Per the project's convention "A new skill category needs three structurally-enforced discoverability surfaces, not one," I was also overweighting *discoverability* — but the rule's *target reader* is whoever generates the project CLAUDE.md, and that reader is naturally inside product-context.

## Work Tree

- [x] Phase 1: Place randomize-ports guidance in product-context Variant A; revert prior misplaced edits
  **Observable outcomes:**
  - CLI: `grep -c "^## Docker dev-environment ports" CLAUDE.snippet.md` returns `0` (prior edit fully reverted)
  - CLI: `grep -c "Environment-misrouting suspicion" skills/feature-verify-self/SKILL.md` returns `0` (prior edit fully reverted)
  - CLI: `grep -c "served page title" skills/feature-verify-self/SKILL.md` returns `0` (prior edit fully reverted)
  - CLI: `grep -c "ephemeral range" skills/product-context/SKILL.md` returns ≥ `1` (new guidance landed)
  - CLI: `grep -c "49152" skills/product-context/SKILL.md` returns ≥ `1` (new guidance landed)
  - CLI: `grep -c "Randomize host ports" skills/product-context/SKILL.md` returns ≥ `1` (new bullet exists)
  - CLI: New guidance placed inside Variant A block (between "First-run bootstrap" and "Rule for agents and humans alike") — verified by `awk '/^### Variant A/,/^### Variant B/' skills/product-context/SKILL.md | grep -c "ephemeral range"` returning ≥ `1`
  - CLI: `./tests/check-structure.sh` exits 0 (no structural regressions)
  - CLI: `./install.sh` exits 0 (idempotent re-install succeeds; symlinks valid)
  - [x] P1.1 Revert `## Docker dev-environment ports (GLOBAL)` section from `CLAUDE.snippet.md` (removed; original heading flow restored)
  - [x] P1.2 Revert `### 3a. Environment-misrouting suspicion clause` from `skills/feature-verify-self/SKILL.md` (removed; original `### 3 → ### 4` flow restored)
  - [x] P1.3 Add short randomize-ports guidance to `skills/product-context/SKILL.md` Variant A block (added as new "Randomize host ports" bullet between "First-run bootstrap" and "Rule for agents and humans alike"; ~5 lines including example)
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human  <!-- F11: human-confirmed skip; no integration boundary; isolated additive prose to product-context Variant A + two reverts -->
  - [x] verify-codify  <!-- no new tests needed (pure prose, no executable behavior); existing suite passes with 1 pre-existing unrelated fixture drift surfaced to backlog -->

## Current Node
- **Path:** Feature > Phase 1 (complete — all phases complete; ready to ship)
- **Active scope:** ship
- **Blocked:** none
- **Unvisited:** (none — single-phase feature complete)
- **Open discoveries:** none (one pre-existing unrelated drift surfaced to backlog)

## Verify-auto (post-F23) note
- 2026-06-06: Markdown heading flow restored on both reverted files. Product-context new bullet sits inside Variant A. No orphan cross-document references to removed sections. Structural sweep + install.sh both exit 0 (unchanged from pre-edit baseline, modulo the pre-existing fixture drift).

## Verify-self (post-F23) note
- 2026-06-06: No integration boundary (all three file changes are additive-or-revert prose). All 9 CLI observable outcomes PASS. The 1 check-structure.sh FAIL is the pre-existing unrelated settings-fixture drift (already surfaced as SURFACE-2026-06-06-SETTINGS-FIXTURE-MODEL-DRIFT in the prior verify-self pass).

## Retrospect

- **What changed in our understanding:** The original SURFACE entry proposed two harness rules (a global CLAUDE.snippet rule + a verify-self detection clause). Initial plan implemented both verbatim. User feedback at verify-human reframed both placements: (1) per-project init guidance does not belong in the global snippet — global is read every conversation, per-project init is one-time; (2) verify-self is contractually observe-only and detection logic doesn't belong there; if the symptom recurs, a `debug-*` sidebar is the right shape. The lesson: when a backlog item proposes a placement, that placement is a *candidate*, not a contract — re-evaluate at plan-time against the cost/benefit of the actual reader of the rule.
- **Assumptions that held:** (a) the underlying rule (randomize host ports from the ephemeral range) was correct and worth adding; (b) the rule's prose was short enough to fit in one tight bullet — final version is ~5 lines, well within "tight" budget; (c) the existing `skills/product-context/SKILL.md` Variant A structure had a natural slot for the new bullet (between "First-run bootstrap" and "Rule for agents and humans alike") — no structural surgery needed.
- **Assumptions that were wrong:** (a) that detection-when-prevention-was-skipped warranted its own clause in verify-self — turns out the existing Subagent Re-Verification Heuristic already covers snapshot-timing, and "observe wrong app" is a different failure class better served by a yet-to-be-written `debug-*` sidebar; (b) that the global CLAUDE.snippet was the right place for *any* of the prevention text — it's the wrong namespace for per-project init rules.
- **Approach delta:** Implementation took one F12→F23 back-loop to relocate scope. Build-1 implemented the original plan (snippet + verify-self). Verify-human rejected both placements. Plan revision reduced the work to one tight additive bullet in product-context Variant A plus two reverts; build-2 executed cleanly and verify-self / verify-human passed without further pushback. Net cost: ~one extra build pass and one extra plan pass — the F23 mechanism kept the cycle bounded.

## Communicate

**Feature complete:** `docker-init-randomize-host-ports` has shipped (commit 5872554). It adds a "Randomize host ports" guidance bullet to `skills/product-context/SKILL.md` Variant A, telling future project-init runs to randomize every host-side `host:container` port from the ephemeral range (49152-65535) so multiple project checkouts on one host don't collide on well-known defaults like 5173 or 5432. To see it in action: next time `/product-context` runs against a Docker-Mandate project, the generated `CLAUDE.md` should reflect the randomization guidance under its Dev Environment section.

Requester = operator — closure notice for self-record.

## Build log
- 2026-06-06 P1.1 (post-F23): Reverted CLAUDE.snippet.md addition. grep confirms count=0.
- 2026-06-06 P1.2 (post-F23): Reverted skills/feature-verify-self/SKILL.md addition. grep confirms count=0 for both "Environment-misrouting suspicion" and "served page title".
- 2026-06-06 P1.3 (post-F23): Added "Randomize host ports" bullet (~5 lines) inside Variant A block in skills/product-context/SKILL.md. Placement verified — `awk` over the Variant A range finds the new content.
- 2026-06-06 Smoke: All 9 grep/CLI outcomes PASS. `tests/check-structure.sh` exit 0 (124 PASS, 1 pre-existing unrelated fixture drift). `./install.sh` exit 0.

## Build re-entry log
- 2026-06-06 (F12→F23): Scoped leaves both classified as plan-placement issues, not build-bug. No build implementation performed. Problem Statement updated with revised scope/placement reasoning. Emitting F23 to back-loop to plan.

## Plan revision request (2026-06-06)

User rejected both edits at verify-human with two specific feedback points:

**1. CLAUDE.snippet.md placement is wrong.** Docker dev-compose init is a per-project, near-one-time event (once at project init; maybe again at major arch changes). The global snippet is read by every skill in every conversation — burning ~60 lines on a per-project init rule is the wrong cost/benefit. **Correct home:** `skills/product-context/SKILL.md`. Product-context already has a "Dev Environment" section with a Docker Mandate variant (Variant A); the randomize-host-ports rule slots naturally there as guidance for whoever generates the project's `CLAUDE.md` from the variant.

**2. verify-self placement is wrong.** verify-self is contractually observe-only; its job is to report what the subagent saw. Layering detection logic for environment-misrouting bloats the skill and overlaps the existing Subagent Re-Verification Heuristic. The Replicator incident was prevention-layer: the compose file should have had a random host port. Detection-when-prevention-was-skipped is a candidate `debug-*` sidebar (e.g. `debug-environment-misrouting`), pulled when an operator stalls — but defer until the pattern recurs. For this feature, **drop the verify-self change entirely.**

**Replan target:**
- Move the (significantly shortened) randomize-host-ports rule into `skills/product-context/SKILL.md`'s Variant A section.
- Revert the verify-self SKILL.md edit entirely.
- Revert the CLAUDE.snippet.md addition entirely.

## Verify-self note
- 2026-06-06: No integration boundary (additive prose to docs/skill files; consuming surfaces `install.sh` and `check-structure.sh` cited in outcomes and PASS). No dev URL applicable (docs-only feature, zero UI/HTTP/Browser outcomes). All 8 CLI observable outcomes re-verified PASS. The 1 `check-structure.sh` reported FAIL is a pre-existing unrelated fixture drift (`model: live=<missing> fixture="opus[1m]"`) — present before this feature, unchanged by it; surfaced as backlog item below.

## Build log
- 2026-06-06 P1.1: Added new `## Docker dev-environment ports (GLOBAL)` section to `CLAUDE.snippet.md` between "Entry-skill product-context loading" and "Pre-risky-action checklist". Four-part rule + collision-prone defaults list + cross-reference to verify-self companion clause.
- 2026-06-06 P1.2: Added `### 3a. Environment-misrouting suspicion clause` to `skills/feature-verify-self/SKILL.md` between § 3 (subagent results parsing) and § 4 (WIP tree update). Trigger pattern + four-step procedure + calibration note distinguishing from Subagent Re-Verification Heuristic.
- 2026-06-06 Smoke: All 6 grep outcomes pass. `tests/check-structure.sh` exit 0 (124 PASS, 1 pre-existing settings-fixture drift unrelated to this feature — `model: live=<missing> fixture="opus[1m]"`). `./install.sh` exit 0 (idempotent re-install re-injected snippet into `~/.claude/CLAUDE.md`).

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
[SURFACED-2026-06-06] verify-self — settings fixture drift unrelated to this feature; logged as SURFACE-2026-06-06-SETTINGS-FIXTURE-MODEL-DRIFT in workflow/backlog.md

## Test Triage — settings fixture model drift
Classification: Obsolete test — fixture asserts a `model` field (`opus[1m]`) that the live `~/.claude/settings.json` no longer has; live shows `<missing>` for that key.
Confidence: high
Evidence: The failure was present at the **start** of this feature's first verify-self pass (before any edit) and is unchanged across all three verify-self runs in this session. It is not caused by anything this feature touched (this feature only edits markdown in CLAUDE.snippet.md, two SKILL.md files, and the WIP). The fixture vs live divergence is a pre-existing harness/fixture drift.
Action: Surfaced to backlog (SURFACE-2026-06-06-SETTINGS-FIXTURE-MODEL-DRIFT) for a separate task-plan to either update `tests/fixtures/settings.json` or add the field to `INTENTIONAL_DIFFS` in `tests/check-structure.sh`. Not auto-fixing here — out of scope for this feature, and the right tradeoff (drop the field vs add to INTENTIONAL_DIFFS) needs a decision separate from this feature's scope.

## Downstream contract impacts (plan-time grep)

Per project CLAUDE.md "Plan-level downstream contract impacts pass": revised plan touches three files — two reverts (CLAUDE.snippet.md, feature-verify-self SKILL.md) and one additive (product-context SKILL.md Variant A). All three are pure-prose markdown; no existing keys, function signatures, payload shapes, or test fixtures change. `tests/check-structure.sh` does not assert anything about Variant A body content. The reverts restore each file to its pre-feature state, which the test harness was happy with before this feature began. No alias-key, array-length, function-signature, or variable-binding-name patterns apply. Subcases A-D from CLAUDE.md all check out negative.
