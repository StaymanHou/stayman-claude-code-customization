# Feature: WP7k — Build the full product-cycle tour skill

**Workflow:** feature
**State:** COMPLETED
**Created:** 2026-07-24
**Completed:** 2026-07-24
**Ship commit:** 8bbf5c1 (local; not pushed per close-commit discipline)
**Milestone:** 11 (M11 / WP7k — deferred build of WP7h)
**drive_mode:** autopilot

## Problem Statement

The M11 onboarding family has three `tutorial-*` skills (`tutorial-getting-started` + the greenfield
and brownfield arms). The greenfield arm gives a **light taste** of the top of the hierarchy and
deliberately stops there; FB-2 (operator's live walkthrough) asked for the heavier counterpart — a
**full product-cycle tour** that walks a graduated user through the *whole* product lifecycle
(vision → roadmap → research → arch → wbs) so they *feel* the workflow carry an entire **initiative**,
not one unit of work. The design is already settled (WP7h, `full-product-cycle-tour-design.md`); this
WP **builds** it: a fourth standalone `tutorial-product-cycle-tour` skill, run directly, pointed-at
from the greenfield arm's Step-8 close. Headline aha = **DECOMPOSITION** (fuzzy idea → milestone-
ordered, dependency-mapped, feature-ready WBS). It **ends at a feature-ready WBS — does NOT drive an
actual feature** (greenfield already showed feature execution). No transition, no runtime, `tutorial-*`
family invariants bind.

## Plan-time decisions settled (design §2 open decision + reuse directives)

- **Environment delivery shape (design §2, Option A vs B) → OPTION A: written product brief.**
  Rationale (from design §2 lean, now confirmed at plan time): the full-cycle tour's ahas are all in
  *planning* (decomposition, strategic docs, handoff of a whole plan); there is **no verify-self
  grounding beat** here (design §3 cuts it — no runnable subject required), so Option B's only real
  advantage (concrete code to cite) buys nothing while costing maintenance + rot risk (rides
  path/layout changes, cf. M7). A brief is the lower-rot, natural-input choice for a *planning* tour.
  **Delivery:** ship the brief as `skills/tutorial-product-cycle-tour/scripts/brief.md` (scaffold-in-
  skill per design §2/§8, so it travels with the skill's whole-directory symlink — no `install.sh`
  change for it). **Operator veto surface:** if the operator prefers Option B (richer sample dir) at
  plan review, P1 re-scopes to author a sample dir instead; nothing downstream assumes runnable code.
- **Reuse, do NOT re-derive, the handoff→restore choreography** (design §3 Step 7 / §8) from the
  greenfield arm's Step 7 (`skills/tutorial-greenfield-workflow-tour/SKILL.md:222-284`). Adapt for
  *scale* (a whole roadmap + WBS to lose/recover, lands harder) — keep the proven three-scene copy
  pattern + context-window-management framing; do not invent a new one.
- **Backlog awareness:** `SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED` (medium) —
  the batch hands-on acceptance run extends to WP7k's copy; runs AFTER this WP lands, gates WP7e.
  `SURFACE-2026-07-21-INSTALL-SH-NO-ORPHAN-PRUNE` (medium) — heed when re-running `install.sh` (it's
  additive-only; the new dir links cleanly, no orphan created by an *add*).

## Work Tree

- [x] Phase 1: Build the tour skill + brief subject  <!-- status: [x] — all impl (P1.1–P1.4) + all 4 verify nodes complete 2026-07-24 -->
  <!-- Relevance check (before Phase 2): requester-still-needs=yes (pointer is the WP7h.1 deliverable); requirements-unchanged=yes; solution-feasible=yes (arm Step-8 close exists, add pointer + re-run install.sh); no-superior-alt=yes. Verdict: proceed. -->
  **Observable outcomes:**
  - CLI: `skills/tutorial-product-cycle-tour/SKILL.md` exists; frontmatter has `name:
    tutorial-product-cycle-tour`, a `description:` that leads with "Guided tour of the full product
    lifecycle" (NOT a bare `product`-verb phrasing — design §6 collision guard), and an
    `argument-hint:`; no `skills:` key, no `tools:` key (grep confirms absence).
  - CLI: `skills/tutorial-product-cycle-tour/scripts/brief.md` exists and is non-empty (the written
    product brief — the controlled subject the tour drives vision→wbs against).
  - CLI: `grep -c "TRANSITION\|RETURN-TO\|^- \*\*F[0-9]\|DEBUG-" skills/tutorial-product-cycle-tour/SKILL.md`
    → 0 for emitted-transition patterns (the skill emits NO transition; a `## Transitions` section
    stating "None." is present).
  - CLI: `grep -iE "5.?min|five.?minute|quick.{0,4}(5|five)" skills/tutorial-product-cycle-tour/SKILL.md`
    → 0 matches (FORBIDDEN "quick/5-minute" claim absent — design §5 / spec §6).
  - CLI: `grep -iE "30.?.?45|~?30|thirty.{0,4}(to|-).{0,4}forty" skills/tutorial-product-cycle-tour/SKILL.md`
    → ≥1 match (honest ~30–45 min label PRESENT — design §5).
  - CLI: `grep -nE "(^|[^~/.a-zA-Z])\.claude/" skills/tutorial-product-cycle-tour/SKILL.md` → 0
    matches (path-qualification mandate: no bare `.claude/`; every ref is `~/.claude/` or
    `<proj-dir>/.claude/`).
  - CLI: `grep -c "tutorial-product-cycle-tour" skills/tutorial-product-cycle-tour/SKILL.md` → skill
    self-refers by its full compound name (for the replay-free, direct-run framing).
  - [x] P1.1 Create `skills/tutorial-product-cycle-tour/scripts/brief.md` — a short, fictional-but-
        plausible product brief (a paragraph or two) describing an initiative the tour drives
        vision→wbs against. Concrete enough to decompose meaningfully; generic enough not to rot.  <!-- status: [x] — "Trailhead" day-hike-planner brief; fuzzy idea + per-stage decompose notes -->
  - [x] P1.2 Write `skills/tutorial-product-cycle-tour/SKILL.md` against design §3 spine (8 steps:
        entry → vision → roadmap → research(light) → arch(grounding NAMED) → wbs(decomposition
        PAYOFF) → open strategic docs (beat A at strategic layer, STAGED) → handoff→restore bookend
        (STAGED, adapted-for-scale) → close (FSD-for-rare-cases caveat NAMED, NO graduation reveal)).
        Frontmatter per design §6 (name + collision-safe description + argument-hint; no skills/tools
        keys).  <!-- status: [x] — 8-step spine written; frontmatter collision-safe (desc leads "Guided tour of the full product lifecycle") -->
  - [x] P1.3 Wire the required family invariants into the prose: honest ~30–45 min label (design §5,
        no "5-min"/no narrate-and-skip); `## Category` section (tutorial-* family, no state, no
        transition); Flow-authority pointer note (reuse the arms' top-of-file note, adapted: this
        tour does NOT carry replay/mode-menu machinery — say so explicitly per design §3); `##
        Transitions` = "None."; path-qualification on every `.claude/` ref.  <!-- status: [x] — honest label + FORBIDDEN-5min callout + "Why no replay/no mode menu" section + Transitions=None + all .claude/ refs qualified -->
  - [x] P1.4 Adapt (reuse) the greenfield arm's Step-7 handoff→restore three-scene choreography for
        the whole-plan scale (design §3 Step 7). Do NOT re-derive the mechanics.  <!-- status: [x] — 3-scene choreography reused; scaled to whole-plan (roadmap+WBS to lose/recover); context-window-mgmt framing preserved -->
  - [SHORTCUT-2026-07-24] P1.2 verify greps flagged 3 apparent fails — all confirmed grep false-positives (documentary `RETURN-TO:` refs, the FORBIDDEN-5min prohibition + honest "45 min" labels, `-A1`-truncated Transitions read); precise re-greps all pass. Cf. docs/lessons/verify-grep-blind-spots.md.
  - [x] verify-auto  <!-- status: [x] — 2026-07-24: scoped structural checks on the 2 changed md files: YAML frontmatter parses (name/description/argument-hint only, no skills/tools), all family sections + 8 steps present, brief.md well-formed, no conflict markers/placeholders. No-runtime repo → static checks are the right scope. -->
  - [x] verify-self  <!-- status: [x] — 2026-07-24: feature-verify-self-runner subagent, 8/8 PASS, 0 BLOCKING/0 COSMETIC. No integration boundary (isolated new artifacts). 7 CLI outcomes + the coherence read (the real gate for a prose skill) all PASS: 8-step spine matches design §3, decomposition staged w/ Step-5 payoff, "why no replay/mode menu" correct, grounding NAMED / SURFACE CUT, Step-7 three-scene reuse faithful at whole-plan scale, Step-8 close no-graduation + FSD-caveat-as-counterweight. Sub-noise-floor nit (hyphen vs en-dash in ~30-45) correctly not raised — matches design draft. -->
  - [x] verify-human  <!-- status: [x] — 2026-07-24: AUTO-SKIPPED per drive_mode=autopilot. All 4 auto-skip gates clean: (a) autopilot, (b) verify-self 8/8 PASS, (c) no integration boundary (isolated new skill dir + brief.md), (d) no outcome cites a modified consuming surface. Affirmation printed in chat for read-time veto. Copy read-through judgment deferred to the operator's batch hands-on acceptance run (SURFACE-2026-07-22-WP7C-...-DEFERRED, extends to WP7k) → gates WP7e. -->
  - [x] verify-codify  <!-- status: [x] — 2026-07-24: No integration boundary (isolated new artifacts). Full check-structure.sh suite 473/0 (rose 472→473: new skill dir auto-covered by dynamic per-skill phases; no regression). NO new tour-specific pins written here — the tutorial-prefix pin + honest-framing/no-replay/no-mode-menu behavioral pins are WP7e's charter (codifies last, against operator-accepted copy per design §6; pinning now would duplicate + freeze un-accepted copy). No test failures → no triage. Runtime registry updated. -->

- [x] Phase 2: Wire the pointer + install  <!-- status: [x] — all impl (P2.1, P2.2) + all 4 verify nodes complete 2026-07-24 -->
  <!-- Relevance check recorded on Phase-1 completion above: all four signals yes → proceed. -->
  **Observable outcomes:**
  - CLI: `skills/tutorial-greenfield-workflow-tour/SKILL.md` Step-8 close contains a pointer to
    `/tutorial-product-cycle-tour` with the design §7 wording ("light taste" → "whole product
    lifecycle" → "run `/tutorial-product-cycle-tour` in a fresh session … ~30–45 min … save it for
    when you want to go deep"). `grep -c "tutorial-product-cycle-tour" skills/tutorial-greenfield-workflow-tour/SKILL.md`
    → ≥1.
  - CLI: `grep -c "tutorial-product-cycle-tour" skills/tutorial-brownfield-workflow-tour/SKILL.md`
    → 0 (design §7: brownfield needs NO such pointer — different entry).
  - CLI: after `./install.sh`, `~/.claude/skills/tutorial-product-cycle-tour` exists as a symlink
    into this repo (`readlink` resolves to `skills/tutorial-product-cycle-tour`), and the three
    existing tutorial-* symlinks are unchanged (no orphan created by the add).
  - [x] P2.1 Add the WP7h.1 pointer note (design §7 exact wording) to the greenfield arm's Step-8
        "what we did NOT demo" close.  <!-- status: [x] — pointer added after the close block as a named one-paragraph invitation (light taste → whole product lifecycle → run /tutorial-product-cycle-tour in a fresh session, ~30–45 min); mechanics note (direct-run, not via getting-started; named not live; holds on replay). Design §7 wording. -->
  - [x] P2.2 Re-run `./install.sh` (additive-only) to symlink the new skill dir into `~/.claude/`;
        confirm the new symlink resolves and the three existing tutorial-* links are intact.  <!-- status: [x] — install.sh exit 0, "[ok] skills/tutorial-product-cycle-tour (already linked)". All 4 tutorial-* symlinks resolve into the repo; 3 pre-existing intact. Additive add → no orphan. -->
  - [x] verify-auto  <!-- status: [x] — 2026-07-24: scoped checks on the Phase-2 changes (greenfield-arm edit + symlink): frontmatter still valid YAML, no bare .claude/ introduced, no conflict markers, pointer block well-formed, arm still emits no transition, both symlinks resolve. -->
  - [x] verify-self  <!-- status: [x] — 2026-07-24: feature-verify-self-runner subagent, 5/5 PASS, 0 BLOCKING/0 COSMETIC. INTEGRATION BOUNDARY (edit to existing consuming surface = greenfield arm close) — outcome 1 cites it by name, rule satisfied. Coherence read confirmed design-§7 fidelity: (a) natural follow-on after the "what we did NOT demo" block, existing close intact; (b) direct-run mechanics correct (NOT via getting-started fork), named-pointer-not-live-demo; (c) replay-holds stated; (d) verbatim §7 wording, no contradictions. Brownfield correctly has 0 pointer. All 4 symlinks resolve. -->
  - [x] verify-human  <!-- status: [x] — 2026-07-24: operator PAUSED here, chose "defer — I'll verify at the full walkthrough". Approved forward on the mechanical/coherence evidence (verify-self 5/5 PASS + suite green); the copy-in-context read-through is routed to the operator's batch hands-on acceptance run (SURFACE-2026-07-22-WP7C-...-DEFERRED, spans WP7k). NOT a session handoff — a mid-workflow defer of the check items. F13 approval path. -->
    - [x] P2.verify-human.1 <!-- status: [x] — pointer placement/tone: approved-pending-batch (deferred to full walkthrough) -->
    - [x] P2.verify-human.2 <!-- status: [x] — deep-dive tour copy: approved-pending-batch (deferred to full walkthrough) -->
  - [x] verify-codify  <!-- status: [x] — 2026-07-24: full check-structure.sh suite 473/0 (Phase-2 greenfield-arm edit + new tour skill together = no regression). NO new tour-specific pins written here — tutorial-prefix (4th skill) + honest-framing/no-replay/no-mode-menu behavioral pins are WP7e's charter (codifies last against operator-accepted copy). No test failures → no triage. -->

  <!-- Parent-completion: Phase 2 all impl (P2.1, P2.2) + all 4 verify nodes [x]. -->
  <!-- verify-codify decision: all phases (1 + 2) complete → F16 to ship. Name only /feature-ship as next (SURFACE-2026-05-06-FINALIZE-BEFORE-SHIP-ORDER-FLIP). -->

## Current Node
- **Path:** Feature > finalize (COMPLETE — feature closed 2026-07-24, finalize commit e1bfa61)
- **Active scope:** none — WP7k done; F19 → reflect. No tech debt. WBS incomplete (WP7e + acceptance run + WP8 remain) → F19 not F30.
- **Blocked:** none
- **Unvisited:** none (all phases done; ship + review-quality complete)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->

## Code-Quality Review — wp7k-full-product-cycle-tour

_(feature-review-quality, ship 8bbf5c1, drive_mode=autopilot → 0 CRITICAL / 0 MAJOR / 1 MINOR auto-backlogged. F39 to finalize.)_

### Strengths
- High-fidelity conformance to the settled design contract: every design-doc disposition (Decomposition STAGED at Steps 1-2+5, beat-A-at-strategic-layer, handoff→restore bookend, grounding NAMED, SURFACE CUT, no-replay/no-mode-menu, honest ~30-45 min label, FSD-caveat-as-counterweight-not-invite) landed exactly as §3/§4/§5 specified.
- Family invariants all preserved: `## Category` heading matches the three sibling skills (correctly NOT `## Category Context`, which is debug-* only), path-qualification clean (both `.claude/` refs are `~/.claude/`), minimal frontmatter, no transition emitted, `## Transitions` section explicitly restates the no-transition contract.
- The "Why no replay / no mode menu (do not regress this)" section is a genuinely valuable defensive-prose move — encodes the WHY for a deliberate divergence from the arms so a future editor can't "helpfully" add the missing machinery back.
- Step 7 correctly reuses the greenfield arm's proven three-scene handoff→restore choreography rather than re-deriving it, scaled to whole-plan framing — the "reuse, don't re-derive" constraint from design §8.
- Wiring invariants correct on both sides: pointer lives only in the greenfield arm's Step-8 close; getting-started untouched (product-cycle tour is not a first-timer fork option); brownfield carries no pointer per §7.

### Issues
**CRITICAL** — (none)
**MAJOR** — (none)
**MINOR**
- [skills/tutorial-product-cycle-tour/SKILL.md:3] Frontmatter `description` uses the 4-stage chain `(vision → roadmap → arch → wbs)` while the body (line 13) + design spine use the 5-stage `vision → roadmap → research → arch → wbs`. — Verified INHERITED verbatim from the design §6 draft description (`full-product-cycle-tour-design.md:221-222`), not introduced by the build. Auto-backlogged (low) → `SURFACE-2026-07-24-QUALITY-WP7K-DESCRIPTION-STAGE-CHAIN-DROPS-RESEARCH`; best folded into WP7e's copy-freeze.

### Assessment
Well-built, disciplined addition. As a prose SKILL.md its quality bar is fidelity + family-consistency + coherence, and it clears all three. Encodes its own most important divergence (no replay/mode-menu machinery) as guarded WHY-prose so it resists accidental regression. Advances the codebase with no debt beyond the single cosmetic arrow-chain mismatch inherited from the design draft. The one load-bearing quality dimension left open (does the *copy* read well to a real new user) is correctly deferred to the operator's batch hands-on acceptance run + WP7e — right sequencing, not a gap.

### If you disagree
Dismiss the MINOR by marking it `[DISMISSED]` in this section before `feature-finalize` archives the WIP.

## Retrospect
- **What changed in our understanding:** Nothing material — the design contract (`full-product-cycle-tour-design.md`) was thorough enough that the build was near-mechanical. The plan-time "open decision" (environment shape A vs. B) resolved cleanly to A on the airtight reasoning the design already recorded (no verify-self beat → no runnable-code need). This is the payoff of the WP7h design-first split: a build with almost no discovered unknowns.
- **Assumptions that held:** (1) Reusing the greenfield arm's Step-7 handoff→restore choreography verbatim-then-scaled worked exactly as design §8 intended — no re-derivation needed. (2) The `tutorial-*` family invariants (no-transition, path-qualification, scaffold-in-skill, honest-framing) transferred directly. (3) The `check-structure.sh` dynamic per-skill phases auto-covered the new skill dir (472→473) without needing new pins — pins are genuinely WP7e's charter.
- **Assumptions that were wrong:** None. The two verify-self grep "failures" in Phase 1 were the known prose-grep-blind-spot pattern (documentary tokens, FORBIDDEN-prohibition text, `-A1`-truncated read), not real defects — caught by the precise re-grep + coherence read, exactly as `docs/lessons/verify-grep-blind-spots.md` predicts.
- **Approach delta:** Implementation matched the plan exactly. Two phases as planned; the only nuance was Phase 2's verify-human — it did NOT auto-skip (correct: the edit modifies an existing shipped skill's user-facing copy → auto-skip gate (d) fires), so it paused, and the operator chose to defer the copy read-through to the batch walkthrough (the designed path). The one MINOR review finding was inherited verbatim from the design draft, not introduced.

## Notes on codify (WP7e coupling — do NOT pin here)
The `tutorial-`-prefix structural pin + honest-framing pins for this 4th skill are **WP7e's charter**
(codifies last, against operator-accepted copy per the batch acceptance run). verify-codify in *this*
WP writes only the minimal in-WP behavioral/structural check that this build is coherent; the durable
`check-structure.sh` pins + `tests/scenarios/` behavioral scenarios for the tour surface land in WP7e.
Design §6 records the WP7e pin extends the tutorial-prefix check to four skills (not three) + pins the
no-"5-min" / ~30–45-min-present / no-replay / no-mode-menu invariants.
