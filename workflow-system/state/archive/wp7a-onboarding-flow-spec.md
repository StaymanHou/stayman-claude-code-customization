# Feature: WP7a — Onboarding Flow Spec (M11)

**Workflow:** feature
**State:** finalize (complete) — archived
**Created:** 2026-07-22
**Completed:** 2026-07-22
**Ship commit:** 4a43713
**Entry:** spec (complex feature; cross-workflow handoff from product:wbs)
**Milestone:** 11
**drive_mode:** autopilot

## Work Tree

- [x] Phase 1: Author `onboarding-flow-spec.md` (promote brainstorm → durable spec)  <!-- status: complete -->

  **Observable outcomes:** (doc-authoring feature — no HTTP/Browser surface; all outcomes are CLI-verifiable greps against the produced file)
  - CLI: `test -f workflow-system/product/onboarding-flow-spec.md` exits 0 (the durable spec doc exists)
  - CLI: the file has valid frontmatter — `head -6` shows `stage: spec` (or `shape: onboarding-flow-spec`), `milestone: 11`, `state:`, `updated:`
  - CLI: **AC-1 per-path flow** — `grep -qi 'greenfield' && grep -qi 'brownfield'` both hit, AND both a greenfield step sequence and a brownfield step sequence are present (grep for two distinct `### Greenfield` / `### Brownfield` flow headings each followed by a numbered/step list)
  - CLI: **AC-2 disposition table** — the file contains a staged-vs-named table with the legend tokens `STAGED`, `BEAT`, `FRAME`, `NAMED`, `CUT` all present (`for t in STAGED BEAT FRAME NAMED CUT; do grep -q "$t" … ; done`), AND the "don't force it" rule naming the guaranteed-staged set
  - CLI: **AC-3 Claudesk surface contract** — a `## Claudesk Surface Contract` (or equivalent) section exists containing the three required elements: what Claudesk renders, when it points at the entry command, what it must NOT hardcode (grep for "must NOT hardcode" / "renders" / "points at")
  - CLI: **AC-4 name/category** — `grep -q 'workflow-tour'` hits AND `grep -qi 'util-\*\|util-star\|util- category'` (category stated) AND the fuzzy-matcher-collision check is present (`grep -qi 'fuzzy'`) AND the `util-`-prefix-divergence note is present (`grep -qi 'divergence'` / `'must NOT add a .util-.'`)
  - CLI: **AC-5 acceptEdits copy** — `grep -q 'acceptEdits'` hits AND `grep -qv` confirms it recommends acceptEdits over bypass (grep for both `acceptEdits` and a line stating NOT `bypassPermissions`) AND the reassurance one-liner is present
  - CLI: **AC-6 honest framing** — `grep -qi '10.15 min\|10–15\|narrated real run'` hits AND the no-5-minute-claim invariant is stated (`grep -qi 'no .5.min\|forbids.*5.min\|not a demo reel'`)
  - CLI: **AC-7 no-drift** — the spec names each settled brainstorm invariant (grep for: `greenfield` default/`not a funnel`, `two.*separate paths`, `runnable` scaffold, brownfield `BYO`/`no demo`, drive-modes `LAST`, handoff/restore `bookend`, `stepping`/`orchestrated` first-run)
  - CLI: `tests/check-structure.sh` still passes unchanged (this WP adds no skill/pin — pure product-doc authoring; the run confirms no accidental structural regression)
  - [x] P1.1 Write frontmatter + Problem/Audience + the two per-path flow sections (greenfield spine 8-step + brownfield `/init`→reverse-engineer→context-revise spine), each with aha beats mapped to steps (AC-1) — §1–§3  <!-- status: complete -->
  - [x] P1.2 Write the staged-vs-named disposition table (legend + all aha rows from the brainstorm) + the "don't force it" guaranteed-staged-set rule (AC-2, AC-7) — §7  <!-- status: complete -->
  - [x] P1.3 Write the Claudesk Surface Contract section — renders / when-it-points / must-NOT-hardcode (the M12 return-contract form) (AC-3) — §4  <!-- status: complete -->
  - [x] P1.4 Write the settled 7a.3 (name `workflow-tour` + `util-*` + no-transition + fuzzy-collision check + util-prefix-divergence note) and 7a.4 (acceptEdits recommendation + reassurance copy) decisions into the durable spec (AC-4, AC-5) — §5  <!-- status: complete -->
  - [x] P1.5 Write the honest-framing invariant (narrated real run, ~10–15 min, no "5-min" claim) as a load-bearing pinned constraint for WP7b/WP7e (AC-6); add a cross-links/handoff block (feeds WP7b–WP7e + WP8) + the AD-5 as-built-resync + util-prefix-divergence notes for finalize — §6, §8, §9  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; 16/16 AC content greps PASS + check-structure.sh 469/0 no-regression -->

  - [x] verify-self  <!-- status: complete; independent runner subagent re-verified all 9 AC outcome-groups PASS, 0 BLOCKING, 0 COSMETIC. No integration boundary (phase adds one isolated new product doc). No running system — CLI greps ARE the observable surface. -->

  - [x] verify-human  <!-- status: complete; AUTO-SKIP (F11) per drive_mode=autopilot — all 4 auto-skip gates clean (no integration boundary; isolated new product doc; verify-self all-PASS; no consuming-surface outcome). Affirmation printed as read-time veto. The doc's 2 decisions (name/category, acceptEdits) were operator-reviewed+corrected at the spec pause. -->

  - [x] verify-codify  <!-- status: complete; NO new check-structure.sh pin written in WP7a (deferred to WP7e per WBS + WP5/WP6 precedent — pins target the SHIPPED workflow-tour skill, not a living design doc). Pin-charter captured forward inside the spec (§5a/§6/§8/§9: what WP7e MUST pin + the no-util-prefix-pin MUST-NOT). Integration check: check-structure.sh 469/0, no regression. No test failed → no triage. -->


## Current Node
- **Path:** Feature > finalize (review-quality complete)
- **Active scope:** finalize (review-quality: 0 CRITICAL / 0 MAJOR / 3 MINOR auto-backlogged → F39; no refactor)
- **Blocked:** none
- **Unvisited:** none (single-phase feature — the spec is one coherent document)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
- none yet

---
## Spec (below — authored at spec state, decisions settled at spec-review pause)

## Problem Statement

M11 (new-user onboarding) is a **FULL BUILD** decomposed into WP7a–WP7e. WP7a is the
first sub-WP: author the **durable onboarding flow spec** that every downstream sub-WP
builds against, and that WP8 hands back to Claudesk as part of the M12 return contract.

The design is **already settled** by the operator co-design in
`workflow-system/product/onboarding-brainstorm.md` (2026-07-21). WP7a's job is **not** to
re-decide the shape — it is to (i) **promote** the brainstorm into a durable, precise flow
spec (per-path step sequences, aha-beat ordering, the staged-vs-named disposition table),
(ii) author the **Claudesk surface contract** (a return-contract artifact), (iii) **settle
the one genuine open decision the brainstorm deferred to this WP — the entry-skill name +
category** (so WP7b builds against a fixed name), and (iv) settle the **bypass-permissions
reassurance copy**.

This is a **no-runtime, doc-authoring feature**: the deliverable is a spec document
(markdown), not code. It touches no data models, no APIs, no state machine (the entry skill
introduced in WP7b will be a standalone entry point that emits no transition — decided in
7a.3 below).

## User Stories

- As a **brand-new workflow-system user invited via Claudesk** (a working developer,
  mildly skeptical, mostly on real/brownfield code), I want a single command that gives me
  an honest, high-fidelity first-run experience so that the value prop ("structure + durable
  state + human-in-the-loop makes my *real* work less chaotic") clicks without feeling like
  I was funneled through a toy.
- As the **builder of WP7b (entry skill)**, I want a fixed entry-skill name + category and a
  precise per-path flow so that I can implement against a stable contract without re-litigating
  the shape.
- As the **builder of WP7c (scaffold) / WP7d (beats-wiring)**, I want the staged-vs-named beat
  disposition and the scaffold's observable-outcome requirement stated precisely so that I know
  exactly which beats MUST be authentically stageable.
- As **WP8 (return contract to Claudesk)**, I want a Claudesk surface contract that says what
  Claudesk renders, when it points at the entry command, and what it must NOT hardcode, so that
  Claudesk's M11 can build against a stable, non-brittle interface.

## Acceptance Criteria

The spec is done when `workflow-system/product/onboarding-flow-spec.md` exists and contains:

- **AC-1 (7a.1) — Per-path flow.** Two explicit step sequences (greenfield spine + brownfield
  spine), each with its aha beats mapped to the specific step where they fire. The two paths
  **diverge at entry and stay diverged** (NOT branch-then-reconverge). Greenfield uses the
  8-step organic-weave spine from the brainstrom; brownfield uses its `/init` →
  reverse-engineer → `product-context`-revise spine.
- **AC-2 (7a.1) — Staged-vs-named disposition table.** A table reproducing the brainstorm's
  aha dispositions with the legend (STAGED / BEAT / FRAME / NAMED / CUT) and the **"don't force
  it" rule**: only A, B, greenfield-grounding (verify-self), greenfield-SURFACE,
  handoff/restore, and the drive-modes reveal are **guaranteed staged**; C-brownfield,
  grounding-brownfield, hierarchy-brownfield, and reflect/capture are named/opportunistic only.
- **AC-3 (7a.2) — Claudesk surface contract.** A section stating: (a) what Claudesk renders (the
  invite surface + a pointer to the single entry command); (b) *when* it points at the entry
  command (one-time evangelistic invite, gated behind Claudesk's opt-in per its M10.9); (c) what
  Claudesk **must NOT hardcode** (the entry-skill name is the only coupling; the flow, beats,
  and copy live in this repo's skill, not in Claudesk). This is the M12 return-contract form.
- **AC-4 (7a.3) — Entry-skill name + category settled.** A named skill (fixed) + its category
  (`util-*` / new / `session-*`) with the rationale, AND a fuzzy-matcher-collision check (WP5
  discipline: the harness fuzzy-matcher searches **descriptions**, not just names — the chosen
  name AND its description must not shadow `session-start` / `session-restore` / any sibling
  slash-command prefix). WP7b builds against this fixed name.
- **AC-5 (7a.4) — Permission-mode recommendation + reassurance copy.** The entry skill opens
  (universal, both paths) by recommending **`acceptEdits` mode** (Shift+Tab to `acceptEdits`) —
  **NOT** `bypassPermissions`. These are **two distinct Claude Code modes** (the brainstorm's
  "auto-accept / bypass-permissions" phrasing conflated them): `acceptEdits` auto-approves file
  edits + safe filesystem commands but **still gates arbitrary shell commands + network calls**;
  `bypassPermissions` skips **all** checks and is overkill for a tour (trains the wrong mental
  model). `acceptEdits` is the correct low-friction-but-safe fit for a guided tour that runs real
  skills. The AC includes the one-line "why it's safe" copy, written for a skeptical new user who
  sees "turn off my prompts" as alarming. (Ref: https://code.claude.com/docs/en/permission-modes.md)
- **AC-6 — Honest framing pinned.** The spec states the tour is a **narrated real run**
  (~10–15 min, real reasoning + real skills, per-beat pre-framing) and **explicitly forbids any
  "quick / 5-minute" claim** — this is a load-bearing invariant WP7b/WP7e must honor.
- **AC-7 — No design drift from the brainstorm.** Every settled brainstorm decision
  (greenfield-default-not-funnel, two-separate-paths, runnable-scaffold-for-verify-self,
  brownfield-BYO-no-demo, drive-modes-reveal-LAST, handoff/restore-emotional-peak-bookend,
  first-run-stays-stepping/orchestrated) is preserved verbatim-in-intent in the spec. The spec
  is a promotion, not a revision.

## Out of Scope

- **Building the entry skill** (WP7b), the **scaffold** (WP7c), the **beats wiring** (WP7d), or
  the **scenarios/pins** (WP7e). WP7a produces the *spec* only.
- **Authoring the full per-beat narration copy** — the brainstorm defers detailed per-beat
  pre-framing lines to WP7a/WP7d; WP7a settles the *bypass-permissions* copy (7a.4) and the
  *time-label* framing (AC-6) but the per-beat narration copy is a WP7d concern where the beats
  are wired. (WP7a fixes the framing *rules*; WP7d writes the scene-by-scene copy.)
- **Deciding the scaffold's concrete shape** (fixture dir vs. temp-dir scaffolder, the planted
  tangent's content, the runnable observable outcome) — that is **WP7c**. WP7a only states the
  *constraint* (scaffold MUST be runnable with ≥1 observable outcome so verify-self has something
  to check).
- **Delivering the return contract to Claudesk** — that is **WP8**. WP7a authors the surface
  *contract*; WP8 delivers it.
- **Any state-machine change.** The entry skill emits no transition (7a.3 decision) — no
  `transitions.md` edit, no new F/I/T/P/S ID. (If 7a.3 unexpectedly lands on a transition-bearing
  design, that flips to a three-places-in-sync obligation — but the recommendation is `util-*`,
  which is transition-free.)

## Technical Constraints

- **No 3rd-party dependency** (§2 probe check: N/A — this is a prompt/markdown-only repo; the
  onboarding drives existing local skills + the `claude` CLI, no external API/SDK).
- **No-runtime repo convention** — prompt/markdown/skill/scenario/pin edits only.
- **AD-5 envelope (arch.md Revision 2026-07-20).** The co-designed shape (dedicated skill +
  greenfield scaffold, no new runtime, no architectural surface) lands inside AD-5's envelope —
  this is a normal decomposition, **not a P8 arch back-loop**. AD-5 gets a light **as-built
  resync** (deferred→designed→built) at `/product-context` / finalize time, not its own WP.
- **Skill-category contract (arch.md Revision 2026-06-13).** Three categories exist: workflow
  skills (own a state node, emit F/I/T/P/S), `debug-*` sidebars (emit `DEBUG-*` + `RETURN-TO:`,
  pulled from a workflow state), `util-*` standalone (no state, no transition, no `RETURN-TO:`,
  minimal `name`/`description`/`argument-hint` frontmatter, an entry point itself, mode menus
  encouraged). **7a.3 decision:** the onboarding entry skill is a standalone user-invoked entry
  point that drives other skills but owns no state and emits no transition → **`util-*` category**.
- **WP5 fuzzy-matcher-collision discipline (CLAUDE.md, 2026-07-21).** The harness fuzzy-matcher
  ranks on `name` AND `description`. The chosen entry-skill name + description must not contain a
  substring that shadows an existing slash-command prefix (esp. `session-start` / `session-restore`
  / `session-*`). Checked in 7a.3.
- **install.sh is additive-only** (`SURFACE-2026-07-21-INSTALL-SH-NO-ORPHAN-PRUNE`). WP7b
  (which creates the new skill dir) must re-run `install.sh`; not a WP7a concern but noted for
  the chain.
- **Source of truth:** `workflow-system/product/onboarding-brainstorm.md`. **WBS:**
  `workflow-system/product/wbs.md` → WP7a. **`design-priors.md` absent** → consult is a
  silent no-op.

## Recommendation on the open decisions (7a.3, 7a.4) — for operator review

### 7a.3 — Entry-skill name + category — SETTLED

**Name: `workflow-tour`** (operator-decided 2026-07-22). **Category: `util-*`** — standalone
user-invoked entry point, owns no workflow state, emits **no transition** (the `util-*`
contract).

Rationale: it is a standalone entry point (Claudesk points at one command), owns no workflow
state, and emits no transition. It drives other skills inline (a `session-start`-like
experience) but is itself an entry point, not a workflow state or a pulled sidebar. The
mode-menu-encouraged util-* precedent (`util-prune-claude-md`) does NOT apply — the onboarding
tour deliberately runs in stepping/orchestrated (beat B must be visible), so `workflow-tour`
does **not** expose a drive-mode menu at entry.

**Deliberate divergence from the `util-` file-prefix convention (operator-accepted).** Existing
file-based util-* skills use the `util-` prefix (`util-prune-claude-md`, `util-backlog-paydown`);
`workflow-tour` is a `util-*`-category skill that does **not** carry the `util-` name prefix. This
is an intentional naming choice (the evocative, self-explaining name was preferred over the
prefix's self-documenting no-transition signal), analogous to the harness-builtin util-*
utilities (`init`, `review`, …) that are util-* by concept but keep their own names. **WP7e must
NOT add a `util-`-prefix structural pin** that would flag `workflow-tour`; the category is
doc-enforced (arch.md §util-* category), and this divergence should be noted in the as-built
arch resync so a future audit reads it as intentional, not drift.

**Fuzzy-matcher-collision check (WP5 discipline — the matcher ranks on name AND description):**
- `workflow-tour` / `tour` shares no ranking substring with `session-start`, `session-restore`,
  `session-handoff`, `session-capture`, `session-reflect`, `product-*`, `feature-*`, `task-*`,
  `incident-*`, or `util-*`.
- The **description** must avoid "start", "restore", "resume", "session" as ranking tokens — the
  draft below is written to that constraint.
- Draft `description:` — *"First-run guided tour of the workflow system for a brand-new user:
  pick greenfield (new project) or brownfield (your existing code) and walk one small real unit
  of work end-to-end. A narrated real run (~10–15 min), not a demo reel."* (No "start" / "restore"
  / "resume" / "session" tokens.)

**Alternatives considered:** `util-onboard` (viable — carries the `util-` prefix's
self-documenting no-transition signal — but the operator preferred the more evocative
`workflow-tour`); `session-onboard` (rejected — `session-` prefix invites fuzzy collision with
the session-* family the WP5 audit just disambiguated, and it is NOT a session meta-op).

### 7a.4 — Permission-mode recommendation + reassurance copy — SETTLED (corrected)

**Recommend `acceptEdits` mode — NOT `bypassPermissions`.** (Operator correction 2026-07-22:
these are two *distinct* modes; the brainstorm's "auto-accept / bypass-permissions" phrasing
conflated them.) Confirmed against the official docs
(https://code.claude.com/docs/en/permission-modes.md):

| Mode | File edits | Safe FS cmds | Arbitrary shell / network |
|---|---|---|---|
| `acceptEdits` | auto | auto | **still prompts** (gated) |
| `bypassPermissions` | auto | auto | auto (skips ALL checks — circuit-breakers only) |

`acceptEdits` is the correct fit for a guided tour: it removes edit-prompt friction while
**still gating arbitrary shell commands and network calls**, so the blast-radius claim ("stays
local") is *honestly true*. `bypassPermissions` skips all gates — overkill for a tour and it
trains the wrong mental model (the docs note it's meant for isolated containers/VMs). Toggle:
**Shift+Tab cycles modes**; land on `acceptEdits`.

**Recommended one-liner (universal open, both paths):** *"First, press Shift+Tab until Claude
Code shows 'accept edits' mode — that lets the tour make its file changes without a prompt on
every step, while still asking you before it runs any shell command or touches the network. It's
safe here: all work stays inside this one project directory, nothing is pushed or published, and
you keep the wheel (the workflow still pauses to ask you at the decisions that matter)."*

Ties the reassurance to (a) the accurate mode behavior (edits auto, shell/network still gated),
(b) blast-radius containment (one dir, no push/publish), and (c) the G advisory-framing beat
("you keep the wheel"), so it reinforces rather than undercuts the human-in-the-loop trust story.

## Open Questions

- [x] **7a.3 name/category — SETTLED (operator 2026-07-22):** name `workflow-tour`, category
      `util-*`, no transition, no drive-mode menu, deliberate divergence from the `util-` file
      prefix (noted for the as-built arch resync; WP7e must not pin a `util-`-prefix check).
- [x] **7a.4 permission-mode + copy — SETTLED (operator 2026-07-22, corrected):** recommend
      **`acceptEdits`** (not `bypassPermissions` — two distinct modes); drafted one-liner
      accepted with the corrected mode wording.

No open unknowns remain — both were **wording/naming confirmations, not research unknowns**, and
both are settled. The spec is clear → next transition is **F4 → plan** (no research needed).

## Code-Quality Review — wp7a-onboarding-flow-spec

Reviewer: `code-quality-reviewer` subagent, ship commit `4a43713`, drive_mode autopilot (Mode 3).
Result: **0 CRITICAL / 0 MAJOR / 3 MINOR** → Case C: 3 MINOR auto-backlogged to
`workflow-system/state/backlog-quality-findings.md` (`# wp7a-onboarding-flow-spec — 2026-07-22`),
pointer added to `workflow-system/state/backlog.md`. No refactor triggered → F39 to finalize.

### Strengths
- The one correction the promotion makes (§5b `acceptEdits` vs `bypassPermissions`) is explicitly flagged, ships with a comparison table, and traces to a real conflation in the brainstorm — "promote, don't silently revise."
- Every settled brainstorm decision maps forward: §3 flow tables and the §7 disposition table agree on all 11 beats; the "don't force it" guaranteed-staged set is identical to what §3 marks STAGED — no drift between the two representations WP7d/WP7e both read.
- The WP7e pin-charter is precise and correctly anti-directional (what to pin + what NOT to pin, grounded in actual arch.md state).
- The `util-` divergence is well-defended (harness-builtin analogy matches arch.md:344; fuzzy-matcher-collision check applies the WP5 description-token discipline).
- §4 Claudesk contract names the single stable coupling (`/workflow-tour`) + four must-NOT-hardcode clauses — a non-brittle cross-repo interface.

### Issues
**CRITICAL** — (none)
**MAJOR** — (none)
**MINOR**
- [`onboarding-flow-spec.md` §5b ~L215-218] permission-mode table's `acceptEdits` "safe filesystem cmds → auto" column is imprecise (blanket wording; the reassurance copy at ~L226-231 is already airtight). Tighten at WP7b copy time. → SURFACE-2026-07-22-QUALITY-ACCEPTEDITS-TABLE-MIDDLE-COLUMN
- [`onboarding-flow-spec.md` §3 step 2 / step 5 / §7] greenfield "grounding" split across probe-first (BEAT, step 2) + verify-self (STAGED, step 5); only verify-self in §7's staged set. Add a one-clause pointer at WP7d. → SURFACE-2026-07-22-QUALITY-SPLIT-GREENFIELD-GROUNDING
- [`onboarding-flow-spec.md` §3 ~L73] beat legend omits the STAGED/BEAT/FRAME/NAMED/CUT disposition tokens used by the flow tables + §7; add a cross-pointer. → SURFACE-2026-07-22-QUALITY-SECTION3-LEGEND-NO-DISPOSITION-TOKENS

### Assessment
A well-built design contract: fixes the shape without re-deciding it, flags its single deviation loudly, and front-loads the downstream-drift defenses (WP7e pin-charter, AD-5 as-built-resync note, §4 Claudesk coupling boundary). High internal consistency; no runtime, no state-machine change, no premature pin, and the codify-defer-to-WP7e decision is correctly reasoned + WP5/WP6-consistent. Only soft spots are the §5b table middle column + the split greenfield-grounding framing — both MINOR, both addressable at WP7b/WP7d copy time, no refactor pass warranted.

### If you disagree
Dismiss any finding by editing this section and marking the line `[DISMISSED]` before `feature-finalize` archives the WIP.

## Retrospect
- **What changed in our understanding:** The brainstorm's "auto-accept / bypass-permissions" phrasing was a factual conflation — `acceptEdits` and `bypassPermissions` are two distinct Claude Code modes with materially different blast radius (acceptEdits still gates arbitrary shell/network; bypass skips all checks). The operator flagged this at the spec pause; confirming it against the official docs surfaced that the correct guided-tour recommendation is `acceptEdits`, and that the reassurance-copy's "stays local" claim is only *honestly true* under `acceptEdits`. That correction is now the one deliberate deviation the spec makes from its source.
- **Assumptions that held:** The design was genuinely settled by the brainstorm — WP7a was a promotion, not a re-decision. The single-phase / doc-authoring shape was right (one coherent artifact; splitting into sibling phases would have fragmented it). CLI-grep observable outcomes were the correct verification surface for a no-runtime doc. Deferring structural pins to WP7e (pin the shipped skill, not a living design doc) matched WP5/WP6 precedent cleanly.
- **Assumptions that were wrong:** Only the entry-skill name — I recommended `util-onboard` (keeping the `util-` prefix's self-documenting signal); the operator preferred the more evocative `workflow-tour`, accepting a deliberate divergence from the `util-` file-prefix convention. Captured as a WP7e "do-not-pin" charter so the divergence doesn't later read as drift.
- **Approach delta:** Matched the plan. The only mid-flight work not in the plan was verifying the permission-mode distinction via the claude-code-guide subagent (triggered by the operator's correction) — a fact-check, not a scope change. Verify-human auto-skipped cleanly (no integration boundary; isolated new product doc). No back-loops.
