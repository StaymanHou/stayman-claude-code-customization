# Feature: WP6 — Research Cost-Tier Disambiguation

**Workflow:** feature
**State:** Completed 2026-07-21 — shipped 17fe152, finalized; WP6/M10 done
**Created:** 2026-07-21
**Milestone:** 10 (WP6 of the Claudesk Handoff Cycle)
**drive_mode:** autopilot

## Problem Statement

The word "research" spans a **cost spectrum** — from a single web lookup to the heavyweight built-in `deep-research` harness (fan-out + adversarial verification + cited report, high time/token cost). A 14-day audit of all real research-skill invocations across the machine (602 session logs, 8 real invocations) showed the three workflow-vs-web names (`product-research`, `feature-research`, built-in `deep-research`) **never misroute by topic** — the model disambiguates cleanly by *workflow layer/position* (an in-flight `F3`/product-flow transition vs. a standalone request). **The bite is a cost-tier jump, not topic confusion:** in the two fence cases (turn-based-ai chess-RL literature question; claudesk Homebrew-updater question) the operator wanted a *quick online lookup* but the model escalated to the full `deep-research` harness with no cost checkpoint — the operator let it ride out of curiosity, not because the ROI justified it. The missing pieces: (1) a **named, discoverable light-research path** so the cheap tier is visible instead of the model reaching for the nearest heavyweight; (2) that light path must be **honest about its own shallowness** — per-claim/per-source confidence labels + an explicit known-unknowns list; (3) a **human-confirmed escalation gate** — the known-unknowns *trigger an offer* to run `deep-research`, but it never auto-launches; (4) **sharpened `description:` frontmatter** on the two in-workflow research skills so all four research names read unambiguously (disambiguation-first per AD-3; no rename — the logs proved no topic misfire). Scope: fix the operator's observed fence-case friction first; keep wording non-confusing but defer onboarding-grade polish to WP7.

## Constraints & Grounding
- **`deep-research` is a harness built-in, NOT a file in this repo** — its `description:` and internals cannot be edited here. The confirm-gate + ROI criteria + light path must live in surfaces this repo controls: the new `quick-research` SKILL.md, orchestrator `agents/*/AGENTS.md`, and the globally-injected `CLAUDE.snippet.md`.
- **`quick-research` is a standalone user-triggered skill** — reachable directly by the operator OR by a workflow that needs a light web pass. It emits **NO workflow transition** (no F/I/T/P/S token) — like `util-*`/`debug-*` in that it is not a state node. It is NOT a `util-*` skill (those are internal-maintenance ops); its own category framing is "standalone research utility."
- **`install.sh` auto-discovers `skills/*/`** — a new `skills/quick-research/` symlinks on the next `./install.sh` run with no install.sh edit.
- **Path-qualification mandate** — every `.claude/` reference in new prompt prose must be explicitly `~/.claude/` or `<proj-dir>/.claude/` (Phase 12 pin).
- **`CLAUDE.snippet.md` content discipline** — the global rule added must be a *durable convention* (cost-tier discipline is durable), not transient mechanics.
- **Four-name disambiguation** — adding `quick-research` puts a 4th research skill into the collision set; `quick-research` vs `deep-research` is the pair that must read most distinctly (the cost axis). This is the sharpening the description edits must nail.
- **No `transitions.md` change** — this is behavior within/around existing states + a new standalone (non-state) skill. The three-places sync rule does not fire (no F/I/T/P transition added or reworded).

## Work Tree

- [x] Phase 1: New `quick-research` standalone skill  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `test -f skills/quick-research/SKILL.md && head -1 skills/quick-research/SKILL.md` → exits 0, file starts with `---` (valid frontmatter opener)
  - CLI: `awk '/^---$/{n++} n==1&&/^name:/{print} n==2{exit}' skills/quick-research/SKILL.md` → prints `name: quick-research` (frontmatter `name` matches dir)
  - CLI: frontmatter carries a `description:` line AND an `argument-hint:` line (`grep -cE '^(description|argument-hint):' skills/quick-research/SKILL.md` → 2)
  - CLI: SKILL.md body contains all four required behavior anchors — a light-web-pass instruction, `confidence` labeling, `known unknown(s)` list, and a deep-research **escalation offer gated on human confirmation** (`grep -ciE 'confidence' `, `grep -ciE 'known.unknown'`, `grep -ciE 'deep-research'`, `grep -ciE 'confirm|ask|your go|do NOT auto'` each → ≥1)
  - CLI: `./install.sh` run → `ls -l ~/.claude/skills/quick-research` resolves to a symlink pointing into this repo (exit 0); re-run is idempotent (`[ok] ... already linked`)
  - CLI: `./tests/check-structure.sh` → still green (no regression from the new dir; YAML/frontmatter validity phase passes for the new skill)
  - [x] P1.1 Write `skills/quick-research/SKILL.md` — frontmatter (`name`, `description` sharpened to read as the LIGHT/fast tier distinct from deep-research, `argument-hint`) + `## Category` (standalone research utility, emits no transition) + `## When to use` / `## When NOT to use` (light vs. escalate-to-deep boundary) + `## Procedure` (fast WebSearch/WebFetch pass → findings with per-claim/per-source confidence labels → known-unknowns list → human-confirmed offer to escalate to deep-research when load-bearing unknowns remain, NEVER auto-launch) + `## When deep-research IS justified` (the ROI bar) + path-qualified prose  <!-- status: complete -->
  - [x] P1.2 Run `./install.sh`; confirm the symlink is created + idempotent on re-run — `[new]` then `[ok] already linked`, symlink resolves into repo  <!-- status: complete -->
  - [x] verify-auto — scoped checks green: frontmatter valid (name==dir), description+argument-hint present, 4 behavior anchors present, no bare .claude/ (path-qualification clean), YAML parses, standalone (absent from orchestrator skills: frontmatter)  <!-- status: complete -->
  - [x] verify-self — fresh runner subagent read the shipped SKILL.md: 4/4 outcomes PASS, 0 BLOCKING, 0 COSMETIC. Confirmed (structural) valid frontmatter; (anchors) all 4 behaviors present as executable instructions; (coherence) NO path auto-launches deep-research — both branches present, autopilot clause closes the auto-chain loophole, ROI bar + over-reach guard present; (disambiguation) 4-tier table legible. No integration boundary (isolated new artifact).  <!-- status: complete -->
  - [x] verify-human — F11 AUTO-SKIP (drive_mode=autopilot, verify-self all-PASS, no integration boundary, no outcome cites a consuming surface). Affirmation printed in chat + shipped SKILL.md surfaced for operator read-time veto (decision-artifact-flavored per the Known-limitation note).  <!-- status: complete -->
  - [x] verify-codify — No integration boundary. Phase 1 structural behaviors (frontmatter validity, name==dir, symlink wiring, path-qualification) ALREADY codified by check-structure.sh's dynamic per-skill phases (auto-cover the new skills/quick-research/ dir — confirmed by 427 green incl. the symlink-count check). Content-specific pins (4 behavior anchors as a named grep_check group) correctly DEFER to P2.5 to join the snippet-rule + sharpened-description pins as one coherent group. Surfaced + fixed a PRE-EXISTING Phase-15 failure inline (see Test Triage above); suite 427 PASS / 0 FAIL.  <!-- status: complete -->

- [x] Phase 2: Disambiguation surfaces + reinforcement prose + tests  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `product-research` + `feature-research` `description:` lines each still start with their workflow prefix AND now carry an in-workflow-scoping clarifier distinguishing them from web/deep research (`grep '^description:' skills/product-research/SKILL.md skills/feature-research/SKILL.md` → both lines contain a workflow-scope signal; manually confirmed to read unambiguously vs. quick/deep)
  - CLI: `CLAUDE.snippet.md` contains a new durable cost-tier rule block (`grep -ciE 'quick-research|cost.tier|light.*research|confirm before deep' CLAUDE.snippet.md` → ≥1) naming the light-first default + confidence-labels/known-unknowns + confirm-before-deep-research
  - CLI: at least one orchestrator `agents/*/AGENTS.md` carries the confirm-before-deep-research + ROI-criteria reinforcement (`grep -rilE 'quick-research|confirm before deep|deep-research.*confirm' agents/` → ≥1 file)
  - CLI: new behavioral scenario file/entries exist and are valid YAML (`grep -rl 'quick-research' tests/scenarios/` → ≥1; the scenario runner parses it without error in `--dry-run`)
  - CLI: `./tests/check-structure.sh` → green, with the NEW structural pins present and passing (assertion count rises by the number of new `grep_check` pins; run confirms all pass)
  - CLI (behavioral): the fence-case escalation-gate scenario run emits the confirm-before-deep-research prose (`contains_any` SOFT_PASS, per the util.yaml no-transition pattern)
  - [x] P2.1 Sharpen `description:` frontmatter on `skills/product-research/SKILL.md` + `skills/feature-research/SKILL.md` — both now read "…-workflow state (runs INSIDE the … state machine…) … NOT general web research — for a fast web lookup use quick-research; for a cited multi-source report use the built-in deep-research." No rename, no body change. Harness picked up both new descriptions.  <!-- status: complete -->
  - [x] P2.2 Added `## Research cost tiers (GLOBAL)` to `CLAUDE.snippet.md` (4-tier table + light-first default + confidence-labels/known-unknowns + confirm-before-deep-research gate + ROI bar). `./install.sh` re-injected the block into `~/.claude/CLAUDE.md` ([update] confirmed); section present in the live global file; path-qualification clean.  <!-- status: complete -->
  - [x] P2.3 Added a "Research tiers — workflow-research vs. web-research, and confirm before deep-research" subsection to BOTH `agents/feature-workflow/AGENTS.md` (after Debug-techniques) and `agents/product-workflow/AGENTS.md` (after pause-policy). Prose only, no transition-table edits; both note quick-research is not a workflow state.  <!-- status: complete -->
  - [x] P2.4 Added `tests/scenarios/research.yaml` (new auto-discovered group) with 2 scenarios: QR1 (fence-case → light pass + human-gated deep-research offer) + QR2 (settled fact → no over-reach). No-transition skill → `contains_any` SOFT_PASS per util.yaml. Neutral prompts (no recital of the confirm/label/unknowns rule) per the prompt-leakage lesson. Run at verify-auto.  <!-- status: complete -->
  - [x] P2.5 Added `[Phase 16]` to `tests/check-structure.sh` — 11 grep_check pins across the 4 surfaces (quick-research anchors, snippet rule, 2 sharpened descriptions, 2 orchestrator reinforcements). All anchors grep-verified present before pinning (review-finding-is-hypothesis discipline). Run at verify-auto.  <!-- status: complete -->
  - [x] verify-auto — research.yaml valid + runner discovers `research` group (2 scenarios, skill=/quick-research); check-structure.sh 438 PASS / 0 FAIL (all 11 Phase-16 pins green, no brackets warning, +11 from 427 as expected, no regression).  <!-- status: complete -->
  - [x] verify-self — runner subagent ran BOTH research.yaml scenarios LIVE (WebSearch/WebFetch available, real sources cited) + read the prose surfaces: 3/3 PASS, 0 BLOCKING. QR1 fence-case: light tier → confidence labels + 3-item known-unknowns → judged non-load-bearing → correctly did NOT offer escalation and did NOT auto-launch deep-research (§5 settled-at-light branch). QR2 settled fact: answered w/ HIGH labels, "no escalation needed" → over-reach guard held. Both descriptions read workflow-scoped + redirect web needs; global rule in snippet + injected copy. NOTE: the offer-and-WAIT branch was verified STRUCTURALLY (present+correct in §5) not behaviorally-fired — neither live question was unresolvable enough to trigger it; honest observation limit, not a skill gap.  <!-- status: complete -->
  - [x] verify-human — F13 human APPROVED all 4 judgment items (operator "all good", autopilot PAUSED here — did NOT auto-skip because Phase 2 changed routing behavior on EXISTING consumed surfaces, gate (d) tripwire). Items reviewed: P2.vh.1 four-tier newcomer-legibility, P2.vh.2 confirm-before-deep gate wording, P2.vh.3 confidence-labels + known-unknowns discipline, P2.vh.4 global-rule placement. Offer-and-wait branch offered-live-check; operator accepted structural verification. No design-prior (acceptance, not a corrective).  <!-- status: complete -->
  - [x] verify-codify — No running-code integration boundary (prompt/convention edits + new skill). Coverage sufficient, NO new tests needed: the 11 Phase-16 structural pins are the regression guards (confirm-gate anchor, sharpened descriptions, snippet rule, orchestrator reinforcement) + research.yaml 2 behavioral scenarios codify the light-tier/gated-offer/no-over-reach contract — both green. Final full suite: 438 PASS / 0 FAIL, no regression, no brackets warning. Carry-forward nuance: offer-and-wait branch is pinned+scenario-present but not behaviorally-fired live (branch existence pinned). ALL PHASES COMPLETE.  <!-- status: complete -->

## Current Node
- **Path:** Feature > review-quality COMPLETE > ready for finalize
- **Active scope:** none — shipped 17fe152, review-quality done (0 CRITICAL / 0 MAJOR / 3 MINOR auto-backlogged, F39); ready for /feature-finalize
- **Blocked:** none
- **Unvisited:** none (Phase 1 + Phase 2 complete; review-quality complete)
- **Open discoveries:** Phase-15 pre-existing failure resolved inline (see Test Triage); 3 MINOR quality findings auto-backlogged (QR2 anchors = cheap+safe next pickup); offer-and-wait branch verified structurally not behaviorally

## Retrospect
- **What changed in our understanding:** The operator-first log review (before any planning) inverted the framing. The WBS stub assumed a *topic* collision fixable by sharpening descriptions or renaming. The 14-day audit (602 logs, 8 real invocations) showed the three names never misroute by topic — the model disambiguates by workflow layer. Then the operator's correction on the two "correct-routing" fence cases (C/E) revealed the actual defect: a *cost-tier jump* (light-lookup intent → heavyweight deep-research harness, no cost checkpoint). The deliverable became a new light tier + a confirm gate, not a rename.
- **Assumptions that held:** No rename needed (logs confirmed). The `contains_any`→SOFT_PASS pattern for a no-transition skill (util.yaml precedent) worked cleanly. install.sh auto-discovers the new skill dir (no install.sh edit). The confirm-before-deep gate maps naturally onto the existing "verify-human is the only autopilot pause" invariant rather than needing a new pause class.
- **Assumptions that were wrong:** (1) Expected the WBS-stub disambiguation to BE the work; it was the smaller half — the light tier was the real deliverable. (2) Did not anticipate surfacing a *pre-existing* Phase-15 failure (CLAUDE.md:150 migration-mapping prose) at Phase 1 verify-codify — an orthogonal contract-conflict fixed inline with operator approval. (3) The operator's Q1 note (confidence-labels + known-unknowns as the escalation *trigger*) was a sharper mechanism than the menu options I offered — it made the cheap default *safe* by construction.
- **Approach delta:** Two phases (new skill, then disambiguation surfaces) executed as planned. The unplanned work was the inline Phase-15 fix (paused for operator judgment → option (a) → narrow mapping-prose exclusion + a latent BSD-grep warning fix). Live verify-self exercised the settled-at-light branch but not the offer-and-wait branch (no test question was unresolvable enough) — verified structurally instead; honest coverage nuance carried forward as a MINOR backlog item.

## Code-Quality Review — wp6-research-cost-tier-disambiguation

Reviewer subagent, ship commit 17fe152, Mode 3 (autopilot). **0 CRITICAL, 0 MAJOR, 3 MINOR** → Case C (MINOR-only auto-backlog, F39).

### Strengths
- Evidence-driven scoping (14-day audit → light-tier + confirm-gate, NOT a rename).
- Confirm-before-deep gate anchored to the existing "verify-human is the only autopilot pause" invariant rather than a new pause class.
- quick-research self-honesty (HIGH/MED/LOW labels + REQUIRED known-unknowns) as the hygiene that makes a cheap default safe.
- Category framing convention-correct (`## Category`, not debug-*'s `## Category Context`; not util-*).
- Pre-existing Phase-15 failure triaged (contract-conflict → paused → operator-approved inline fix) with a narrow mapping-prose exclusion that still catches live stale paths.

### Issues
**CRITICAL** — (none)
**MAJOR** — (none)
**MINOR**
- [tests/scenarios/research.yaml QR2] `contains_any` includes `"80"`/`"443"` — prompt-answerable regardless of the skill prose, so those two anchors dilute the assertion toward prompt-answerability (sibling to the prompt-leakage lesson). The `"confidence"`/`"settled"` anchors are the load-bearing ones. **CHEAP+SAFE fix candidate — strong next-refactor/sweep pickup.**
- [skills/quick-research/SKILL.md:2] `description` is a dense ~55-word sentence, longer than the four in-workflow siblings. Cosmetic; disambiguation value is real.
- [skills/quick-research/SKILL.md §5] the "never auto-launch" confirm-gate clause lives in prose across three surfaces (SKILL §5, both AGENTS.md) with no placement-level structural pin (Phase-16 pins the phrase, not its co-location with the escalation step). Low severity — the skill emits no transition, so AUTO-exit machinery doesn't apply.

### Assessment
Well-built, tightly-scoped, evidence-driven; strong convention adherence; pre-existing Phase-15 failure correctly triaged + narrowly fixed. Only real debt is test-signal quality (QR2 port anchors) + the confirm-gate's prose-only placement. Neither blocking.

### If you disagree
Dismiss any finding by editing this section + marking the line `[DISMISSED]` before finalize archives the WIP.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
- Context: resolves `SURFACE-2026-07-20-CLAUDESK-RESEARCH-SKILL-COLLISION` (backlog line ~136) — to be deleted-on-resolve at feature-finalize per the delete-on-resolve convention.
- [SURFACED-2026-07-21] Phase 1 verify-codify — PRE-EXISTING Phase-15 failure surfaced (NOT a WP6 regression): `CLAUDE.md:150` "Current Phase" bullet describes the M7 migration as `` `docs/product/*` → `workflow-system/product/` ``, which Phase 15's path-anchored check counts as 1 stale `docs/product` ref. The string is a legitimate historical migration-mapping (category-B "MUST NOT rewrite" per SURFACE-2026-07-21-MOVED-PRODUCT-DOCS-INTERNAL-PATH-REFS). Committed in HEAD d8ee644 (M8 finalize wrote the bullet); CLAUDE.md untouched this session. See `## Test Triage` below.

## Test Triage — check-structure.sh Phase 15 (stale docs/product ref, CLAUDE.md:150)
**Classification:** Contract conflict — Phase 15's path-anchored rule ("any `docs/product` occurrence is stale") vs. the legitimate need to describe the old→new M7 migration mapping in prose (`docs/product/* → workflow-system/product/`). Rewriting the left-hand side to `workflow-system/product/*` would make the sentence nonsense (category-B, falsifies the record).
**Confidence:** high (that it IS a contract conflict) — the triage table routes contract conflicts to always-pause regardless of confidence.
**Evidence:** `CLAUDE.md:150` committed in HEAD d8ee644 (M8 finalize), on a line untouched this session (`git status` clean for CLAUDE.md); Phase 15 self-excludes `check-structure.sh` but not `CLAUDE.md`. The new WP6 artifact `skills/quick-research/SKILL.md` has ZERO stale refs (grep-confirmed) — this failure is orthogonal to WP6.
**Action:** PAUSED for operator judgment → operator chose **option (a), fix inline now**. RESOLVED: added a shared category-B mapping-prose exclusion `mapping_prose='→.*workflow-system/(product|state)'` to BOTH Phase-15 stale-path filters (docs/product AND workflow/<child>). Validated NARROW: excludes the real CLAUDE.md:150 mapping line + a synthetic `workflow/* → state` mapping, but STILL catches a live bare `docs/product/wbs.md` path and a bare `workflow/wip/` ref (no arrow). Also fixed a latent BSD-grep "brackets not balanced" warning (the initial raw-newline `[^\n]` char class → `.*`, safe because grep is line-oriented). Suite now **427 PASS / 0 FAIL**, no warning. This also effectively closes the CLAUDE.md-prose slice of SURFACE-2026-07-21-MOVED-PRODUCT-DOCS-INTERNAL-PATH-REFS (the check no longer false-positives on migration-history prose).

## Evidence — the 14-day invocation audit (grounding for the root cause)
| # | Project | Skill fired | Routing verdict | Note |
|---|---|---|---|---|
| A | mccc | product-research | CORRECT | product-flow entry, milestone M7 |
| D | newsroom | feature-research | CORRECT | in-feature spike (F3) |
| E | claudesk | deep-research | CORRECT routing / WRONG vs intent | operator wanted quick lookup; workflow was PAUSED — fence case |
| F | claudesk | feature-research | CORRECT | in-feature spike, local dev DB |
| G | claudesk | feature-research | CORRECT | in-feature spike (SessionEnd hook) |
| H | claudesk | product-research | CORRECT | product-flow entry, milestone M10 |
| B | turn-based-ai | deep-research | CORRECT (operator named it) | chess-RL literature |
| C | turn-based-ai | deep-research | CORRECT routing / WRONG vs intent | operator wanted quick web precedent survey — fence case |

8/8 routed to a defensible skill by *workflow layer*; the defect is C/E escalating to the heavyweight tier without a cost checkpoint. This feature adds the missing light tier + confirm gate.
