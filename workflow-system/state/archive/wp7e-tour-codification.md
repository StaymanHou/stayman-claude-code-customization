---
workflow: feature
state: complete
drive_mode: fsd
created: 2026-07-27
wbs_ref: "WP7e (Milestone 11)"
---

# Feature: WP7e — Tour codification (behavioral scenarios + `tutorial-` structural pins)

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-07-27
**Entry:** spec (complex feature)

## Problem Statement

M11 built four user-facing tour surfaces — `tutorial-getting-started`, the two arms
(`tutorial-greenfield-workflow-tour`, `tutorial-brownfield-workflow-tour`), and the full-cycle
`tutorial-product-cycle-tour` — across ten WPs (WP7a–WP7d, WP7f–WP7o). **None of that copy is
pinned.** The tour family is ~1,657 lines of prompt prose carrying load-bearing behavioral
invariants (path-fork framing, honest-framing time claims, drive-modes-reveal-is-last, the
no-replay/no-mode-menu rule on the full-cycle tour, staged-vs-named beat dispositions) and a
handful of structural properties (the `tutorial-` prefix itself, required sections, the
util-family shape). A reword anywhere in that surface currently ships green.

WP7e was **deliberately sequenced last** and blocked on operator acceptance, because its own WBS
entry states the governing rule: **pins lock *accepted* copy, not current copy.** That block
cleared on 2026-07-27 when the operator's final hands-on greenfield run accepted the arm — all
four surfaces are now operator-accepted, and zero WPs carry ACCEPTANCE OWED. WP7e is the only
remaining M11 work.

Two code-quality MAJORs from the WP7o review edit **the same five prompt files WP7e is chartered
to freeze**, so they fold in here rather than becoming a second pass over the same surface:

1. **`tour_step:` has no reader** (`SURFACE-2026-07-27-QUALITY-TOUR-STEP-FIELD-HAS-NO-READER`).
   The field is written by four files and documented in five, but read by none —
   `session-restore` step 5 hands back to `resume_skill` unconditionally, and neither arm branches
   on it. It promises a step-addressed resume precision nothing implements. **Operator ruling:
   drop it** (option (b)); option (a) — wiring step-addressed resume — is explicitly rejected, not
   deferred.
2. **The tour-pointer schema has no canonical definition**
   (`SURFACE-2026-07-27-QUALITY-TOUR-SCHEMA-HAS-NO-CANONICAL-DEFINITION`). The `tour:` contract is
   an implicit schema spanning five prompt files, with observed drift already present
   (`session-handoff` says `drive_mode` is *required* on a tour pointer; `session-restore` step 4.3
   treats its absence as a defect to report — two files, two postures). **Fix: name
   `session-handoff` §2 the schema of record; the other four files cite it.**

**[Problem-statement re-check — 2026-07-27, F9b back-loop from Phase-3 verify-self]** *Problem statement
unchanged, but SHARPENED by what the back-loop taught.* The stated problem ("a reword anywhere in that
surface currently ships green") is still exactly right — verify-self did not contradict it. What shifted
is the understanding of **what makes a pin actually guard**. Phase 3 shipped 47 green pins, mutation-tested
in 12 directions, and one of them was **inert**: the `no-transition` anchor matched 24 of 46 SKILL.md files
including skills that *do* emit transitions, so it passed on the very regression it existed to catch. The
root cause is not carelessness — it is that **deletion-sensitivity and specificity are INDEPENDENT
properties**. My sweep proved every pin FAILS when its property is deleted; it never asked whether an
anchor also MATCHES things it must reject. A pin can be perfectly sensitive and still guard nothing. That
is a sharper statement of the same problem this feature exists to solve — the surface ships green — now
turned on the pins themselves. No change to scope or acceptance criteria; the fix is one tightened anchor
plus the missing self-test that would have caught it.

## User Stories

- As a **maintainer** rewording tour copy six months from now, I want the load-bearing behavioral
  invariants pinned so an accidental regression fails the suite instead of shipping green.
- As a **maintainer** renaming or adding a `tutorial-*` skill, I want the structural pins to fail
  **closed** — telling me the pin needs updating — rather than silently guarding nothing.
- As the **operator**, I want the accepted tour experience frozen at exactly the copy I accepted,
  not at whatever the file says at some later date.
- As a **future reader** of `.session.md`, I want one canonical definition of the tour-pointer
  schema, so a fifth reader can't adopt a third posture on the same field.

## Acceptance Criteria

### AC-1 — Behavioral scenarios (task 7e.1)
- [ ] Scenarios covering the four charter beats: **path-fork** (new-vs-existing routing with
      greenfield-recommended-default / brownfield-first-class-peer framing), **staged-beat
      presence**, **permission-mode recommendation** (`acceptEdits` via Shift+Tab — *not*
      `bypassPermissions`; the two are distinct modes and WP7a corrected this), and
      **drive-modes-reveal-is-last**.
- [ ] Scenarios live in the established shape: `transition_id` where a token exists;
      `contains_any` → SOFT_PASS for prose-behavior beats (the tour skills emit **no transition**,
      so several assertions are necessarily prose-shaped).
- [ ] **No prompt leakage** — per `docs/lessons/test-scenario-prompt-leakage.md`, a scenario's
      `system_prompt_extra` / `args` must present the decision context neutrally and must NOT
      recite the expected answer. A scenario that would pass with the prose deleted is invalid.
- [ ] New fixtures added where a scenario needs one; existing fixtures reused where they fit.

### AC-2 — Structural pins (task 7e.2)
- [ ] `tests/check-structure.sh` gains a phase pinning: the `tutorial-` **prefix** across all four
      skills; each skill's required sections; the util-family shape (no `skills:` / no `tools:`
      frontmatter; `## Category` — *not* the debug-`## Category Context`); the documented
      **no-transition** surface.
- [ ] **Honest-framing invariants** pinned: `~10–15 min` on the three entry/arm surfaces,
      `~30–45 min` on the full-cycle tour, and the **absence** of any "5-minute" claim on all four.
- [ ] The full-cycle tour's deliberate **no-replay / no-mode-menu** invariants pinned.
- [ ] **Every negative/absence assertion carries an explicit existence precondition that fails
      CLOSED** (`if [ ! -f "$f" ]; then check … "fail" …`), and **every case that reads a corpus
      variable sits inside the guard that assigns it.** Both vacuous-pass mechanisms from the root
      `CLAUDE.md` conventions — missing file, and unset variable under `set -u` — are excluded by
      construction.
- [ ] Anchors are **phrase CLASSES held in a bash array**, with the probe joined from the array
      (`PROBE=$(IFS='|'; printf '%s' "${ANCHORS[*]}")`) — never a generic procedure word, never a
      verbatim one-off sentence, never a string that gets parsed back into anchors.
- [ ] Anchors are **case-STABLE substrings**, not emphasis-cased words.
- [ ] The anchor set is **property-tested in five directions** — liveness, sensitivity
      (one leak case per anchor, each isolating **exactly one** anchor), specificity, clean-tree,
      case-stability — and verified by **deleting every anchor individually and confirming each
      yields ≥1 FAIL**.

### AC-3 — Drop `tour_step:` (folded decision 1)
- [ ] The field is removed from all **8 live contract sites**: `skills/session-handoff/SKILL.md`
      (:66 prose, :92 schema block), `skills/session-restore/SKILL.md` (:28),
      `skills/tutorial-greenfield-workflow-tour/SKILL.md` (:375, :425 field table),
      `skills/tutorial-brownfield-workflow-tour/SKILL.md` (:229, :282 field table),
      `docs/lessons/tutorial-tour-session-chain-flow.md` (:68).
- [ ] The **2 fixture sites** are handled deliberately, not mechanically:
      `tests/fixtures/wip/tour-inner-work-finalized.md` (:4) and
      `tests/fixtures/session/tour-greenfield-stepping.md` (:9). **Removing the field changes what
      S31/S33/S34 exercise** — the change must be reasoned about per-scenario, not applied blind.
- [ ] The **2 as-built history sites** — `workflow-system/product/wbs.md` (:516, :543) and
      `workflow-system/product/onboarding-flow-spec.md` (:48) — are **annotated, NOT rewritten.**
      They record what was built at the time; rewriting history is out of scope.
- [ ] `tour:` alone is the marker afterward, and the existing `tour:`-field pins still pass.

### AC-4 — Canonical tour-pointer schema (folded decision 2)
- [ ] `session-handoff` §2 ("Tour-driven handoffs") is explicitly named **the schema of record**.
- [ ] The other four files carry a one-sentence citation pointing at it.
- [ ] The **observed `drive_mode`-required drift is resolved** — one posture, stated once in the
      schema of record, with the other files deferring rather than restating.
- [ ] A structural pin asserts the citation exists in each of the four citing files.

### AC-5 — Full-group behavioral run (task 7e.3)
- [ ] The session scenario group runs, and the result is recorded.
- [ ] **The 2-failure floor is recorded as EXPECTED.** `S33` and `S34` are **known-failing by
      design**, backed by `SURFACE-2026-07-27-TOUR-MARKER-NOT-READ-WHEN-POINTER-DELETED`, which
      carries the preferred restore-side fix direction and records why the state-machine-surface
      option was explicitly rejected. "Full group green" for 7e.3 means **"green except the two
      documented known-failures"** — it can never mean zero failures.
- [ ] The floor is recorded **in a place a future reader hits before acting** — not only in this
      WIP, which gets archived. Otherwise someone reads 7e.3 literally, "fixes" S33/S34 by
      softening the assertions, and **deletes the evidence they exist to preserve.**
- [ ] `./tests/check-structure.sh` passes at its known baseline (516 PASS / 1 FAIL — the FAIL is
      the pre-existing, out-of-scope settings-fixture drift, same class as the tracked
      `project_settings_fixture_claudesk_drift` memory; **not a regression**). Timeout **96000**
      per `runtimes.md`.

### AC-6 — Settle the routed copy MINORs BEFORE pinning (added at plan time)
Five user-facing copy MINORs are routed to WP7e by the backlog with the explicit reasoning that
they must be settled before pins lock. **Each was verified against the real code at plan time**
(per the review-findings-are-hypotheses convention) — one had already been fixed by a later WP:

- [ ] `WP7N-BLOCK-MEMBERSHIP-AMBIGUOUS` — **LIVE** (greenfield :574 vs :594/:607/:630). The
      `Next Step:` block's rules say it is the last thing emitted, but the `Housekeeping:` cleanup
      offer sits inside it and :630 reintroduces a post-block action. **Highest-value of the five:
      it is the one that would break a naive pin.**
- [ ] `WP7N-MECHANICS-POINTER-INVERTED` — **LIVE** (greenfield :610, "the same mechanics spelled
      out above"). After the WP7n restructure the narrative only *names* them and points forward.
- [ ] `WP7L-GREENFIELD-EXIT-ORDER` — **LIVE** (greenfield :583, "`/exit`, `mkdir` … and `cd`").
      Instructs two commands in the session just exited; brownfield sequences it correctly.
- [ ] `WP7L-GITSAFETY-RATIONALE-GARDEN-PATH` — **LIVE** (`tutorial-getting-started` :116, "in an
      **empty** directory it refuses to write into if anything is already there").
- [ ] `WP7K-DESCRIPTION-STAGE-CHAIN-DROPS-RESEARCH` — **LIVE** (`tutorial-product-cycle-tour` :3,
      4-stage chain vs the body's 5-stage). Operator choice: insert `research` or keep terse.
- [ ] `STEP7-BRIGHTLINE-UNSCOPED` — **ALREADY RESOLVED, no edit.** The sentence it describes
      (*"you are following the wrong boundary"*) does not exist anywhere in `skills/` — verified by
      `grep -rn "wrong boundary" skills/` returning zero. A later WP removed it. Close the finding
      as already-resolved rather than editing; do **not** invent the sentence to fix it.

## Out of Scope

- **Rewording accepted tour copy for taste.** WP7e freezes what the operator accepted. If a pin
  can't be anchored without a copy change, the pin gets a different anchor — the copy does not move.
  A *stylistic* defect discovered here is a SURFACE, not an in-scope fix.
  **CORRECTED AT PLAN TIME — the narrow exception (now AC-6):** the backlog explicitly routes five
  user-facing copy MINORs *into* WP7e's "copy-freeze" with the stated reasoning that they must be
  settled **before** pins lock, and one of them
  (`SURFACE-2026-07-25-QUALITY-WP7N-BLOCK-MEMBERSHIP-AMBIGUOUS`) warns it *"will break a naive WP7e
  pin the same way"* it already broke a sentence-counter. Freezing a known-ambiguous artifact
  defeats the purpose of freezing it. So the five routed MINORs are **in scope**, as a pre-pin
  phase — and nothing beyond them.
- **Wiring step-addressed tour resume** (option (a) of the `tour_step` finding) — explicitly
  rejected by the operator, not deferred.
- **Fixing S33/S34.** The restore-side fix direction is recorded in the backlog and is a separate
  pickup. Softening the assertions is *forbidden* — it deletes the evidence.
- **Any state-machine surface change.** No new transition IDs, no `transitions.md` edit, no
  `agents/*/AGENTS.md` table change. WP7o deliberately held an empty diff there across four
  phases, and reopening it would make WP7e freeze pins against a design the operator hasn't seen
  run. The tour skills emit **no transition** — that is the pinned property, not a gap to fill.
- **`SURFACE-2026-07-27-QUALITY-RUNTIMES-FRONTMATTER-NOT-A-BARE-DATE`** — the third WP7o MAJOR. A
  one-line independent fix touching no WP7e file. Not folded in.
- **The root `CLAUDE.md` prune** (`SURFACE-2026-07-27-CLAUDE-MD-PRUNE-AFTER-WBS`). Operator-ruled
  to wait until the entire WBS is wrapped, at the `/product-finalize` boundary. WP7e *adds* to that
  file, so pruning first means pruning twice.
- **WP8** (M12 return contract to Claudesk) — the next WP, not this one.

## Technical Constraints

- **No runtime.** Prompt/markdown/scenario-YAML/shell-pin edits only. No new dependencies.
- **Reuse `[Phase 18b]` as the template — do not reinvent it.** It is the in-repo reference
  implementation of the anchors-in-an-array pattern plus the five-direction property test, and it
  carries inline commentary on the exact shapes that were rejected and why.
- **Both new root-`CLAUDE.md` test-authoring conventions bind this WP directly** — they were
  written *for* it, one commit earlier: (a) a pin's anchors need their own property test and must
  be phrase classes; (b) the vacuous-pass class covers a missing file **and** an unset variable
  under `set -u`.
- **Path-qualification mandate** — every `.claude/` reference in prompt prose must be `~/.claude/`
  or `<proj-dir>/.claude/`, never bare. Enforced by Phase 12.
- **No `install.sh` re-run needed** — no new skill directories; all four tour skills are already
  symlinked.
- **Known-failing scenarios must stay known-failing.** Any change that makes S33/S34 pass without
  the restore-side fix is a regression in evidence, not a win.
- **`grep` blind spots on prose observables** (`docs/lessons/verify-grep-blind-spots.md`): en-dash
  step-ranges, markdown-bold-wrapped phrases, line-wrapped and blockquote-prefixed text. Order of
  trust: coherence read > wrap/bold-tolerant grep > literal grep. When a grep "fails" on prose,
  suspect the grep before the copy. **This is acute here** — the honest-framing invariants use
  en-dashes (`~10–15`, `~30–45`) and the surrounding copy is heavily bolded.
- **Never `git add -A` in this repo** — the untracked `my-claude-code-customization` entry at the
  repo root is a self-referential symlink and is not gitignored.
- **`design-priors.md` is absent** → the consult contract is a silent no-op.

## Open Questions

None blocking. Three items are **plan-time decisions**, not research unknowns — each has a clear
default and is settled by reading files already in hand:

- [ ] Whether the new pins land as a **new phase** or extend `[Phase 18b]`. Default: a new phase,
      since 18b is specifically the *narration-probe property test* and WP7e's charter is broader.
      (`SURFACE-2026-07-27-PHASE-18B-SUBLETTERED` notes the phase inventory is due a tidy — worth
      settling while here, but not a blocker.)
- [ ] Per-scenario handling of the two `tour_step:` **fixture** sites, decided by reading what
      S31/S33/S34 actually assert. Not an unknown — a required per-scenario reasoning step.
- [ ] Where the 2-failure floor is recorded durably (candidates: an inline comment block above
      S33/S34 in `session.yaml` — which already carries a ⚠️ warning — and/or the new pin phase's
      header commentary). Default: **both**, since the WIP gets archived.

No 3rd-party dependency → probe check N/A. No architectural decision required → no `arch.md`
back-loop.

## Work Tree

> **Phase ordering rationale.** Copy settles FIRST (Phase 1), because pins freeze whatever the copy
> says and one routed MINOR is documented to break a naive pin. The `tour_step:` removal and schema
> citation (Phase 2) also change pinnable text, so they precede pins too. Pins land only once the
> surface is final (Phase 3), and the behavioral scenarios (Phase 4) come last because they are the
> slowest to run and the most sensitive to copy. **Phases 1–2 are prompt-copy edits; Phase 3 is
> shell; Phase 4 is YAML** — three different artifact kinds, three independent verify loops.

- [x] Phase 1: Settle the routed copy MINORs (AC-6) — the pre-pin copy freeze  <!-- status: complete 2026-07-27 — all 6 impl leaves + all 4 verify leaves [x]. 5 surgical copy fixes landed + 1 finding closed as already-resolved without an edit. Operator approved all 4 verify-human leaves. The tour copy is now operator-ACCEPTED and pin-eligible, which is the precondition Phase 3 was sequenced to wait for. -->
  **Observable outcomes:**
  - CLI: `grep -c 'spelled out above' skills/tutorial-greenfield-workflow-tour/SKILL.md` → `0`
    (the inverted pointer is gone)
  - CLI: `grep -c 'refuses to write into if anything is already there' skills/tutorial-getting-started/SKILL.md` → `0`
    (the garden-path clause is split)
  - CLI: the greenfield Branch-A replay option no longer orders `/exit` before `mkdir`/`cd` —
    `sed -n '583p'` (or the line's post-edit equivalent) shows `mkdir` … `cd` … *then* `/exit`
  - CLI: the `Next Step:` block carries one reconciling clause naming the cleanup offer as a
    trailing non-option element — `grep -cE 'cleanup offer is (a |the )?(distinct )?trailing' skills/tutorial-greenfield-workflow-tour/SKILL.md` ≥ 1
  - CLI: `head -3 skills/tutorial-product-cycle-tour/SKILL.md | grep -c 'research'` → `1`
    (stage chain aligned) — *or* an explicit WIP note recording the operator's terse-description choice
  - CLI: `./tests/check-structure.sh` → 516 PASS / 1 FAIL (the known settings-fixture drift only —
    no new failures)
  - [x] P1.1 Fix `WP7N-BLOCK-MEMBERSHIP-AMBIGUOUS` — reconcile the block's last-thing-emitted rule with the cleanup offer + the :630 exception  <!-- status: complete — added a 5th block rule naming the cleanup offer as a distinct TRAILING element (part of the block, not an option, not numbered among them) and declaring acting on it the ONLY permitted post-block action. This sanctions the pre-existing :630 exception instead of contradicting it; :630 now reads as a restatement of the rule rather than a violation of it. Deliberately did NOT move the offer out of the block — it renders inside the blockquote in both branches, so relocating it would change accepted user-facing copy rather than the rule that describes it. -->
  - [x] P1.2 Fix `WP7N-MECHANICS-POINTER-INVERTED` — reword the forward/backward pointer at :610  <!-- status: complete — "they are the same mechanics spelled out above" → "these are the mechanics, compressed — the narrative above only names them, so this is where they live". Direction now matches post-WP7n reality; an agent no longer hunts above for a fuller statement that does not exist (which risked re-expanding the narrative WP7n compressed). -->
  - [x] P1.3 Fix `WP7L-GREENFIELD-EXIT-ORDER` — reorder to match brownfield's correct sequencing  <!-- status: complete — "`/exit`, `mkdir` a new empty folder and `cd` into it, then run…" → "`mkdir` a new empty folder and `cd` into it, then `/exit` and run … in a fresh session there". Read brownfield first (:437, prep-then-`/exit`) and matched its shape rather than inventing one. Prep now happens in the live session; `/exit` is last. -->
  - [x] P1.4 Fix `WP7L-GITSAFETY-RATIONALE-GARDEN-PATH` — split the self-contradictory clause  <!-- status: complete — "in an **empty** directory it refuses to write into if anything is already there" → "it only ever writes into an **empty** directory — if anything is already there, it refuses." Two clauses, no garden path. This is the exact sentence the deferred verify-human checklist item 1 asks the operator to judge. -->
  - [x] P1.5 Settle `WP7K-DESCRIPTION-STAGE-CHAIN-DROPS-RESEARCH` (insert `research`, or record the terse choice)  <!-- status: complete — chose ALIGN over terse: inserted `research` into the frontmatter chain (now `vision → roadmap → research → arch → wbs`, matching body :13). Rationale: `research` is a real executed Step 3 (`/product-research`), so the 4-stage form was inaccurate rather than merely terse — a description that omits a stage the tour actually runs misleads at the skill-picker surface. -->
  - [x] P1.6 Close `STEP7-BRIGHTLINE-UNSCOPED` as already-resolved — verify absence, do NOT re-add the sentence  <!-- status: complete — NO EDIT MADE, by design. Verified absent across SIX phrasings (`wrong boundary`, `following the wrong`, `bright.line`, `brightline`, `anywhere other than Step 7`, `Scene 1, you are`) over skills/ + docs/, case-insensitive: zero hits. A later WP removed the sentence. Applying the finding's suggested fix blind would have meant re-inserting the sentence in order to scope it — the review-findings-are-hypotheses convention caught this. Finding closes as already-resolved at finalize. -->
  - [x] verify-auto  <!-- status: complete — 4 scoped checks on the 3 changed files. (1) YAML frontmatter parses for all 3 (exactly the 3 expected files changed; no collateral). (2) All 7 Phase-1 observables PASS. (3) Accepted invariants intact — ~10–15 framing ×2 in each arm/entry, ~30–45 ×3 in the full-cycle tour, Next Step: block structure intact. (4) All 3 symlinks live → edits take effect. check-structure.sh 516 PASS / 1 FAIL = documented baseline, FAIL is the pre-existing settings-fixture effortLevel drift (not a regression, not chased). TWO greps initially reported false negatives and BOTH were the grep's fault, not the copy's (verify-grep-blind-spots.md order-of-trust applied): a line-wrapped clause needed tr '\n' ' ', and the "5-minute" probe needed the claim-vs-prohibition distinction. Both logged to ## Discoveries as Phase-3 pin-design constraints. -->
  - [x] verify-self  <!-- status: complete — feature-verify-self-runner subagent, 13/13 PASS (6 mechanical observables + 5 coherence reads + 2 regression sweeps), 0 BLOCKING, 0 COSMETIC. Coherence reads confirmed: (a) the new 5th block rule and the pre-existing ~:630 exception RECONCILE on all four axes a reader would test (membership / counting / what-may-follow / ordering) — a pin counting numbered options correctly gets 3; (b) the reworded mechanics pointer is corroborated by the narrative's OWN self-description at ~:530/:544 ("they are compressed there, not dropped"), so the old "spelled out above" was demonstrably false; (c) mkdir → cd → /exit is executable in order and matches both the brownfield model and the dispatcher's twice-stated "before they /exit" convention; (d) the split git-safety clause reads clean as continuous wrapped prose and its behavioral claim is consistent with the greenfield mechanics note; (e) `research` is a genuinely executed Step 3 (/product-research at :149), so the description became more ACCURATE not merely longer. Regression sweep: exactly 3 files / 5 hunks / +13-8, one-to-one with the 5 named defects, zero unrelated hunks; honest-framing strings untouched; all four 5-minute occurrences still prohibitions. Runner honored observe-only (read-only git). Also SURFACED a Phase-3 pin refinement (brownfield's governing "never" sits on the wrapped prior line). -->
  - [x] verify-human  <!-- status: complete — operator APPROVED all 4 leaves 2026-07-27. INTEGRATION BOUNDARY APPLIED (condition 2, and condition 3 by analogy): the three edited tutorial-* SKILL.md files are symlinked live into ~/.claude/skills/ and ARE the user-facing product surface — every edit changes on-screen copy a first-run user reads. Gate (d) also failed: the Observable Outcomes name each edited skill, all pre-existing consuming surfaces this phase MODIFIES. The F11 skip path was therefore FORBIDDEN and autopilot auto-skip correctly did NOT fire; this was a real operator read, not an auto-skip. verify-self's 13 PASSes excluded per the pre-filter. -->
    - [x] P1.verify-human.1 — Branch-A replay instruction reads correctly as a first-run user's LAST on-screen line  <!-- status: complete — APPROVED. mkdir → cd → /exit is executable in order; /exit no longer precedes the commands it would kill. -->
    - [x] P1.verify-human.2 — git-safety reassurance is clear on one read (no garden path)  <!-- status: complete — APPROVED. This is the same sentence the deferred verify-human checklist item 1 flagged for firmness-without-bureaucracy; now operator-accepted in its split two-clause form. -->
    - [x] P1.verify-human.3 — full-cycle tour description stage chain (skill-picker surface)  <!-- status: complete — APPROVED. Flagged to the operator as the one item where the call could defensibly have gone the other way (accurate-5-stage vs terse-for-the-picker); operator ratified ALIGN. The 5-stage chain is now operator-accepted copy and is what Phase 3 pins against. -->
    - [x] P1.verify-human.4 — cleanup-offer block rule + mechanics pointer (agent-facing, shapes emitted output)  <!-- status: complete — APPROVED, including the deliberate decision NOT to relocate the cleanup offer (it renders inside the blockquote in both branches; the rule describing it was changed instead of the accepted user-facing copy). The block-membership rule is now unambiguous, which is the precondition Phase 3's option-counting pin depends on. -->
  - [x] verify-codify  <!-- status: complete — NO NEW TESTS WRITTEN, by design (see the §Coverage deferral note below the Work Tree). Regression run only: check-structure.sh 516 PASS / 1 FAIL (known settings-fixture effortLevel drift, unchanged, not chased) + greenfield arm script suite 31/31 (baseline). Integration boundary APPLIES, and the boundary rule's consuming-surface test is satisfied INSIDE this feature at Phase 3/4 — one phase later, not omitted. Writing pins here would have created two competing pin sets over one corpus. Phase 1's copy is now operator-ACCEPTED and therefore pin-eligible, which is the precondition Phase 3 was sequenced to wait for. -->

- [x] Phase 2: Drop `tour_step:` + name the canonical tour-pointer schema (AC-3, AC-4)  <!-- status: complete 2026-07-27 — all 5 impl leaves + all 4 verify leaves [x]. tour_step: removed from 8 contract sites + 2 fixtures; 2 as-built history sites annotated (not rewritten); session-handoff §2 is now the schema of record with 4 citations and the drive_mode drift resolved to one posture. Operator ratified both the DROP and the annotate-adjacent supersede pattern. -->

  **Relevance check (before Phase 2):**
  - Requester still needs this: **yes** — the operator ruled *"drop it"* on `tour_step:` this session, and both this and the sibling schema-of-record finding are explicitly routed into WP7e by the backlog.
  - Requirements unchanged: **yes** — Phase 1 edited tour *copy* only; it did not touch the pointer schema, the fixtures, or either session skill.
  - Solution still feasible: **yes** — Phase 1 confirmed these are editable prose surfaces and surfaced no new constraint against the removal.
  - No superior alternative discovered: **yes** — option (a) (wire step-addressed resume) was explicitly *rejected* by the operator, not deferred; nothing in Phase 1 reopened it.
  **Verdict:** proceed

  **Observable outcomes:**
  - CLI: `grep -rn 'tour_step' skills/ docs/ tests/fixtures/` → **zero matches** (all 8 contract
    sites + both fixtures cleared)
  - CLI: `grep -rn 'tour_step' workflow-system/product/` → still matches `wbs.md` +
    `onboarding-flow-spec.md` (as-built history preserved), each now carrying an annotation marking
    the field superseded
  - CLI: `grep -c 'tour:' skills/session-handoff/SKILL.md` ≥ 1 and the same for `session-restore`
    (the surviving marker is untouched; existing `[Phase 18]` block-(i) `tour:` pins still PASS)
  - CLI: `session-handoff` §2 contains an explicit schema-of-record declaration —
    `grep -cE 'schema of record' skills/session-handoff/SKILL.md` ≥ 1
  - CLI: each of the 4 citing files (`session-restore`, both arms, the flow-doc lesson) contains a
    citation pointing at it — `grep -lE 'schema of record' <each>` returns the file
  - CLI: `python3 -c "import yaml,sys; [yaml.safe_load(open(f).read().split('---')[1]) for f in ['tests/fixtures/session/tour-greenfield-stepping.md','tests/fixtures/wip/tour-inner-work-finalized.md']]"` exits 0
    (both fixtures still parse as valid frontmatter after field removal)
  - CLI: `./tests/check-structure.sh` → 516 PASS / 1 FAIL (no new failures)
  - [x] P2.1 Remove `tour_step:` from the 5 prompt/doc contract sites (handoff ×2, restore ×1, both arms ×2 each, flow-doc ×1)  <!-- status: complete — all 8 declarations removed. Re-grepped rather than trusting plan-time line numbers (they held; Phase 1's edits fell below the greenfield sites). Both arms' field tables went "four fields" → "three fields". The only surviving `tour_step` strings in skills/docs are three DELIBERATE NEGATIVE references ("there is deliberately no `tour_step:` field", "was dropped in WP7e for having no reader") — zero declarations remain. -->
  - [x] P2.2 Remove `tour_step:` from both fixtures; confirm no scenario assertion read it  <!-- status: complete — removed from both; `tour: greenfield` SURVIVES in each (the marker S34 exists to test). HARD CONSTRAINT VERIFIED BY EXECUTION, not assumption: S33 still FAILs emitting `TRANSITION: S22`, S34 still FAILs emitting `S17` — the identical two cold-model failure modes named in SURFACE-2026-07-27-TOUR-MARKER-NOT-READ-WHEN-POINTER-DELETED. The field was inert, so removing it changed nothing they exercise. Evidence preserved. Kept the pointer fixture's body line "pick the run back up at step 8" — narrative prose, and the honest form of what the field falsely promised. -->
  - [x] P2.3 Annotate (do NOT rewrite) the 2 as-built history sites in `wbs.md` + `onboarding-flow-spec.md`  <!-- status: complete — both records preserved VERBATIM with a SUPERSEDED blockquote adjacent. wbs.md: one annotation above the WP7o AS-BUILT block covers both its hits (:516 record + :543 task 7o.1). onboarding-flow-spec.md: annotation directly under the §5 bullet. Each names WP7e, the operator ruling, the arm-addressed replacement, and points at the new schema of record. `tour_step` deliberately still appears 3× in each file — that is the history being preserved. -->
  - [x] P2.4 Name `session-handoff` §2 the schema of record; resolve the `drive_mode`-required drift to one posture  <!-- status: complete — §2 "Tour-driven handoffs" is now explicitly THE SCHEMA OF RECORD, naming its four citing files and instructing a hypothetical fifth reader to cite rather than re-describe. Drift resolved to ONE posture: `drive_mode` is REQUIRED, and a tour pointer reaching a reader without it is a DEFECT IN THE WRITING SKILL to report, never to default over. Note: session-restore step 4.3 already held this same posture, so there was no contradiction to break — the drift was that two files each stated it independently; now one states it and the other cites. Rules went 2 → 3 (added the arm-addressed-not-step-addressed rule, which records WHY there is no step field so it cannot be reintroduced blind). -->
  - [x] P2.5 Add the one-sentence citation to each of the 4 citing files  <!-- status: complete — `session-restore` :28, both arms' field-table preambles, and docs/lessons/tutorial-tour-session-chain-flow.md :68. Verified: "schema of record" appears in exactly 5 files = 1 canonical + 4 citations. Each citation also carries the arm-addressed-not-step-addressed fact, so a reader who lands mid-file still learns there is no step field. -->
  - [x] verify-auto  <!-- status: complete — 6 scoped checks on the 11 changed files. (1) BOTH fixtures round-trip through yaml.safe_load with `tour_step` absent and `tour: greenfield` intact — asserted programmatically, since a malformed fixture would silently change what every tour scenario exercises. (2) All 4 edited SKILL.md frontmatter still parses. (3) ZERO `tour_step:` DECLARATIONS remain — checked for table-row and YAML-position forms specifically, not by naive substring count. (4) All 3 surviving mentions verified as genuinely NEGATED prose ("there is deliberately no…", "was dropped in WP7e…"), wrap-tolerant match, 1 each. (5) schema-of-record wiring = 1 canonical (`THE SCHEMA OF RECORD` in session-handoff) + exactly 4 citations. (6) Both arm field tables now read "three fields", zero "four fields". Regression: check-structure.sh 516 PASS / 1 FAIL (known settings-fixture drift only); [Phase 18] block-(i) `tour:` pins PASS; narration probe still IGNORES the mechanical read. S33/S34 re-confirmed still-failing during build with identical S22/S17 signatures. -->
  - [x] verify-self  <!-- status: complete — feature-verify-self-runner subagent, 12/12 PASS (6 mechanical + 6 coherence reads), 0 BLOCKING, 0 COSMETIC. (a) §2 IS self-contained — a fifth reader can implement from it alone; the one out-of-block fact (the arms' belt-and-braces WIP `tour:` stamp) is a reader-side survivability guard, not part of the pointer schema §2 scopes itself to. (b) Drift RESOLVED to one posture: session-handoff rule 2 legislates ("this is the one posture, stated once, here"); session-restore states only local BEHAVIOR and its :28 entry explicitly defers. (c) All 4 citations load-bearing — each names file + section anchor resolving to a real heading, and each carries the arm-addressed fact inline so following it deepens rather than merely redirects. (d) Both arms "three fields" = exactly 3 table rows; the nearby "the two rules in this blockquote" was verified to be the blockquote's two BEHAVIORAL rules (counted), not a field count — and greenfield:616's "all four of its constraints" belongs to the replay option, unrelated. (e) Both history annotations preserve the original verbatim, sit adjacent, name the operator ruling + SURFACE ID, and bound the supersession ("Everything else in the record still holds"). (f) ZERO dangling references — swept for "the step to resume", "both fields", "two further/extra fields", "these fields", "the tour ones", "four fields" across skills/ docs/ workflow-system/product/; every hit is an intentional negation, an unrelated subject, or the superseded-history annotations. Singular agreement carried through consistently ("One further field — `tour:` — is written… It is absent"; "The field is inert"). Runner honored observe-only; working tree unchanged. -->
  - [x] verify-human  <!-- status: complete — operator APPROVED both leaves 2026-07-27. INTEGRATION BOUNDARY APPLIED, assessed FRESH (not inherited from Phase 1) and the case is STRONGER here: condition 3 is near-literal (`/session-handoff` and `/session-restore` are live slash commands, and this phase changed the SCHEMA of the `.session.md` artifact they write and read — the interchange format between two commands, the prompt-system analogue of condition 5's request/response shape change); both arms are live symlinked surfaces whose user-facing field tables changed. Gate (d) fails independently — the Observable Outcomes name session-handoff, session-restore, both arms, and both fixtures, all pre-existing surfaces this phase MODIFIES. F11 forbidden; autopilot auto-skip does not apply. Checklist is deliberately NARROW: verify-self exhaustively confirmed all mechanical properties (self-containment, drift resolution, citation usefulness, field counts, history preservation, zero dangling refs), so those are excluded per the pre-filter. Only two genuine judgment calls remain. -->
    - [x] P2.verify-human.1 — ratify the DROP as the right product call, now that it is real  <!-- status: complete — APPROVED 2026-07-27. The operator's earlier "drop it" ruling was against a FINDING; this ratifies the actual shipped prose, including the two additions made at build time: the rule now RECORDS WHY the field was dropped (so a future reader cannot reintroduce it casually) and names the condition under which reintroducing would be legitimate ("Do not reintroduce it without also building a reader for it") — a deliberate open door, not a wall. -->
    - [x] P2.verify-human.2 — ratify annotate-adjacent as this repo's supersede-a-shipped-record pattern (sets precedent)  <!-- status: complete — APPROVED 2026-07-27. **This ruling has reach beyond WP7e** — it is the pattern the next supersession copies. Alternatives considered and rejected at build time: editing the record in place (destroys the audit trail) and strike-through (ambiguous about what remains true). Accepted tradeoff: a little file bloat, and `grep tour_step` still hits wbs.md — worth it against a WBS that would otherwise lie about what July shipped. The scoping clause "Everything else in the record still holds" is load-bearing: without it a reader might discount the entire AS-BUILT block rather than the one superseded field. -->
  - [x] verify-codify  <!-- status: complete — NO NEW TESTS WRITTEN, same rationale as Phase 1 (see §Coverage deferral): this corpus's coverage IS Phase 3/4, immediately next; ad-hoc pins here would create two competing pin sets. Integration boundary applies and its consuming-surface obligation is carried to Phase 3/4 within this feature. Regression run: check-structure.sh 516 PASS / 1 FAIL (known settings-fixture drift only) + greenfield arm script suite 31/31. No triage needed. CODIFY OUTPUT = forwarding the contract: three NEW pin targets recorded in §"Phase 2 → Phase 3 pin targets", including a REAL pin-design hazard (a naive `grep -c tour_step → 0` pin fires on its own deliberate negative references, and the natural "fix" deletes the guardrail against reintroducing the field — the second instance of this failure shape in one feature, after the 5-minute one). S33/S34 not re-run here: already confirmed still-failing at build with identical S22/S17 signatures, and a re-run costs ~$0.22/58s for a recorded result. -->

- [x] Phase 3: `[Phase 19]` structural pins + grep-able phase headers (AC-2)  <!-- status: complete 2026-07-27 — all impl leaves + all 4 verify leaves [x]. 68 pins live ([Phase 19]=47 tour-surface + [Phase 19b]=21 prose-anchor property test); 4 missing `# ── Phase` headers added (28/28 grep-able). Suite 516 → 584. Took THREE verify-self runs: run 1 caught a too-generic no-transition anchor (matched 24/46 SKILL.md incl. real emitters; a tour skill with `TRANSITION: F1` appended still PASSED) → F9b; run 2 caught zero-iteration heredoc loops silently dropping 10 of 19 cases → in-place fix under the shortcut; run 3 (fresh subagent) satisfied gate 2. verify-human SKIPPED per fsd with both pending judgment calls agent-decided and flagged for operator review. -->

  **Relevance check (before Phase 3):**
  - Requester still needs this: **yes** — AC-2 is WP7e's core deliverable. The four tour surfaces still have no structural pins of their own; `SURFACE-2026-07-25-WP7N-CLOSE-STRUCTURE-UNPINNED` proved it empirically (deleting BOTH `Next Step:` blocks left every suite green).
  - Requirements unchanged: **yes** — and Phases 1–2 are precisely what makes this phase correct now: the copy is operator-ACCEPTED and the contract is settled, so pins freeze accepted text rather than in-flight text.
  - Solution still feasible: **yes** — `[Phase 18b]` is a working in-repo template for the anchors-in-an-array + five-direction property-test shape. Phases 1–2 surfaced two absence-assertion hazards, both with recorded workarounds, not blockers.
  - No superior alternative discovered: **yes** — extending `[Phase 18b]` was considered and rejected at plan time (different charter; editing the one mutation-verified part of this surface adds risk for no gain).
  **Verdict:** proceed

  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` emits a `[Phase 19]` section and exits with the baseline
    1 FAIL (settings-fixture drift only); total PASS count strictly greater than 516
  - CLI: the four `tutorial-*` skills are each pinned for prefix + required sections + util-family
    shape (no `skills:`/`tools:` frontmatter, `## Category` not `## Category Context`) + documented
    no-transition surface
  - CLI: honest-framing pinned — `~10–15` present on the 3 entry/arm surfaces, `~30–45` on the
    full-cycle tour, and a **fail-closed** negative assertion that no "5-minute" claim exists in any
    of the four
  - CLI: full-cycle tour's no-replay/no-mode-menu invariants pinned
  - CLI: **anchor property-test passes in all five directions** — liveness, sensitivity,
    specificity, clean-tree, case-stability
  - CLI: **deleting any single anchor from the array yields ≥1 FAIL** — verified by sweeping every
    anchor individually (this is the zero-unguarded proof; a `pass` on any deletion is a defect)
  - CLI: **every negative assertion fails CLOSED** — verified by pointing each at a synthetic
    nonexistent path and confirming FAIL, not PASS
  - CLI: ~~`grep -c '^# \[Phase' tests/check-structure.sh` ≥ 18 (headers now grep-able; was 1)~~
    **[CORRECTED at Phase-3 verify-auto]** — this observable measured the WRONG PATTERN. `^# [Phase` was
    never the house convention; the real form is `^# ── Phase`, which already covered 23 of 27 phases at
    plan time (so the plan's "was 1" premise was also wrong). Correct observable, verified:
    `grep -cE '^# ── Phase' tests/check-structure.sh` equals the echo-header count (**28 = 28**) with
    **zero uncovered phases**.
  - [x] P3.1 Make phase headers grep-able (drive-by; mechanical, do first so `[Phase 19]` lands consistent)  <!-- status: complete — SCOPE WAS NARROWER THAN PLANNED. The plan-time premise ("only 1 grep-able header") was based on the wrong pattern: a `# ── Phase N: ...` comment convention ALREADY existed and covered 23 of 27 phases. Only 4 were missing (11, 13, 14, 18b — 18b already flagged by SURFACE-2026-07-27-QUALITY-PHASE-18B-SUBLETTERED). Added those 4 in the existing house style rather than inventing a new one. Now 27/27. -->
  - [x] P3.2 Write `[Phase 19]` positive pins — prefix, required sections, util shape, no-transition  <!-- status: complete — per-skill × 4 tour skills: exists-under-tutorial-prefix, `^## Category$` (util shape, NOT debug-*'s `## Category Context`), `^## Transitions`, emits-NO-transition (wrap-tolerant), frontmatter-extractable precondition, and no `skills:`/`tools:` frontmatter key. -->
  - [x] P3.3 Write the honest-framing + no-replay/no-mode-menu pins, each negative one fail-closed  <!-- status: complete — BOTH recorded hazards handled as specified, neither rediscovered. Hazard 1: the 5-minute invariant is pinned as the POSITIVE presence of the prohibition (`never|FORBIDDEN … 5-minute`) plus the honest duration, matched against a NEWLINE-FLATTENED copy so brownfield's wrapped governing `never` is caught — never as an absence assertion. Deliberately did NOT partition durations per-file: the full-cycle tour legitimately cites the arms' ~10–15, so a per-file duration map would be wrong. Hazard 2: `tour_step:` pinned on DECLARATION FORMS only (`^tour_step:` YAML position, or a `| \`tour_step:\` |` table row), PLUS a paired positive pin that the guardrail prose survives — that pairing is what stops someone "fixing" a failing absence pin by deleting the sentences that prevent reintroduction. Full-cycle no-replay/no-mode-menu + its do-not-regress rationale pinned. -->
  - [x] P3.4 Build the anchor array + join the probe from it; anchors are phrase CLASSES, case-stable  <!-- status: complete — DELIBERATE DESIGN DEVIATION, recorded rather than silently skipped: [Phase 19] does NOT use a joined multi-anchor probe, because it is not that shape of pin. [Phase 18b]'s array+join exists because block (i) needs ONE probe matching ANY of N leak forms across a shared corpus. [Phase 19]'s assertions are each a DISTINCT named property against a DISTINCT file (does THIS skill have `## Category`; does THAT file cite the schema of record), so there is no multi-anchor probe to join and no second copy to drift — the property the array pattern exists to guarantee is satisfied structurally by construction. Applying it anyway would add a parser with nothing to parse. The array pattern's ACTUAL requirements were honored: every anchor is a phrase CLASS or a structural form (never a verbatim one-off sentence, never a generic procedure word), and every anchor is case-STABLE (verified — no `-i` anywhere in the phase except the deliberately case-insensitive no-transition prose check, which matches "no"/"No"/"NOT" variants by design). -->
  - [x] P3.5 Write the five-direction property test (sensitivity cases isolate exactly ONE anchor each)  <!-- status: complete — all five directions exercised, adapted to this phase's shape: LIVENESS (all 47 pins PASS against the real corpus — no dead anchors); SENSITIVITY (12 mutations, each isolating exactly one property); SPECIFICITY (the 2 hazard cases — 3 live negative `tour_step` refs do NOT trip the declaration pin; legitimate prose does not false-positive); CLEAN-TREE (tree verified restored after every mutation, and audited hunk-by-hunk mid-run to confirm no residue); CASE-STABILITY (all anchors are case-stable substrings or structural forms). -->
  - [x] P3.6 Run the delete-each-anchor sweep + the synthetic-path fail-closed sweep; fix any anchor that survives  <!-- status: complete — THE PROOF STEP, and it earned its place: it caught TWO REAL DEFECTS that shipped green. (1) `set -euo pipefail` ABORT — a bare `if ... grep -q` inside the per-skill loop killed the entire script mid-loop on the FIRST skill; the run printed 4 PASSes and then simply stopped, with NO summary and NO failure. Every conditional now captures a count with `|| true`. (2) VACUOUS PASS — the frontmatter extraction (`sed -n '1,/^---$/{...}' | sed -n '2,$p'`) returned an EMPTY string, so both the `skills:` and `tools:` forbidden-key checks were matching against nothing and passing vacuously; replaced with explicit line-range extraction PLUS a fail-closed precondition that FAILs if extraction comes back empty. That is the exact vacuous-pass class root CLAUDE.md codifies — hit again inside the phase written to avoid it, which is now noted in the phase's own comments. SWEEPS: 5 fail-closed rename tests (renamed tour skill / schema canonical / guardrail file / full-cycle tour / citing file) — every one FAILs, zero vacuous passes. 12 sensitivity mutations — every one produces ≥1 FAIL, including both `tour_step:` DECLARATION FORMS (table row AND YAML-position in a fixture) and a real field-table ROW deletion. 2 specificity tests — the strongest being a simulated REAL regression on brownfield (prohibition replaced with an actual "quick 5-minute tour" claim, literal string still present so a naive absence pin would still pass) which the positive pin correctly FAILED. Tree verified restored, `check-structure.sh` byte-identical to its pre-mutation copy. -->
  - [x] verify-auto  <!-- status: complete (RE-RUN 2026-07-27 after the F9b fix) — 4 scoped checks on tests/check-structure.sh, the only file changed by the fix. (1) `bash -n` clean. (2) Suite 582 PASS / 1 FAIL (563→582), pin counts [Phase 19]=47 + [Phase 19b]=19 = 66, `=== Summary ===` reached (set -e regression check). Sole FAIL is the pre-existing settings-fixture drift. (3) ANCHOR DISCRIMINATION re-verified INDEPENDENTLY — the anchor was SOURCED FROM THE SCRIPT (grep + sed off `^TOUR_NOTRANSITION_ANCHOR=`) rather than retyped, so the real shipped value was tested: 4/4 tour skills matched, 0 false positives across six emitters — three of which (feature-plan, incident-mitigate, product-roadmap) are deliberately NOT in [Phase 19b]'s own reject list, so the check is not circular. (4) THE REGRESSION PROOF: restoring the original over-broad anchor makes [Phase 19b] emit 10 FAILs naming the exact emitters it wrongly matched; file then restored and confirmed BYTE-IDENTICAL by sha256 (be7d6d88…), not merely by `diff`. Tree clean: only intended WP7e files modified; the 3 residue-marker files (CLAUDE.md + 2 archived WIPs) confirmed UNMODIFIED via per-file `git status --porcelain`, i.e. prior sessions' own mutation-test documentation, not this session's leftovers. --
       PRIOR RUN (pre-F9b, retained for the audit trail): 4 scoped checks on the one changed file (tests/check-structure.sh). (1) `bash -n` clean. (2) Phase-header convention: 28 echo-headers / 28 `# ── Phase` comments / ZERO uncovered — and this CORRECTS THE PLAN'S STALE OBSERVABLE: the plan specified `grep -c '^# \[Phase' >= 18`, which returns 2, because that was never the house convention; the real form is `^# ── Phase` and coverage is now 28/28. The plan's number was measuring the wrong pattern, not a shortfall. (3) Suite 563 PASS / 1 FAIL (>516 as required), 47 [Phase 19] pins, and the `=== Summary ===` block IS reached — that last check is the direct regression test for the `set -e` mid-loop abort the build discovered and fixed. Sole FAIL is the pre-existing settings-fixture drift. (4) No mutation residue: git status shows only intended WP7e targets; `tour_step` declarations = 0 with the 3 deliberate negative refs intact. A residue-marker sweep hit 3 files (CLAUDE.md + 2 archived WIPs) — verified UNMODIFIED and pre-existing: they are PRIOR sessions documenting their own `session-DOESNOTEXIST` mutation tests, the same technique, not this session's leftovers. -->
  - [x] verify-self  <!-- status: complete 2026-07-27 — CLOSED after a THIRD, fresh runner satisfied gate 2 of the in-place-fix shortcut. History: run 1 found 1 BLOCKING defect ((a)+(b), the same pin twice: too-generic no-transition anchor + no self-test); both were FIXED under F9b; run 2 found a SECOND BLOCKING defect (zero-iteration heredoc loops silently dropping 10 of 19 [Phase 19b] cases with bash -n clean and a healthy-looking 572/1) which was fixed IN-PLACE under the verify-self in-place-fix shortcut; run 3 (fresh subagent — gate 2) confirmed the guard works and is not itself vacuous. FINAL: 584 PASS / 1 FAIL (sole FAIL = pre-existing settings-fixture effortLevel drift, out of scope), [Phase 19]=47 + [Phase 19b]=21 = 68 pins, bash -n clean, summary block reached. THE LOAD-BEARING PROOF: emptying both heredoc BODIES now yields 3 FAILs naming `ran 0 of 4` and `ran 0 of 6`, where it previously dropped 10 cases silently; file restored sha256-byte-identical (dee20c3d…caa), git status matches the pre-verification snapshot. Guard non-vacuity verified structurally: both counters initialized at top level immediately before their loops, assigned once, read in the same scope (no set -u exposure, no pipeline subshell), increment AFTER the `[ -z ] && continue` so it counts checks-emitted not lines-read. 0 BLOCKING remain; 1 COSMETIC (heredoc DELIMITER-typo inverts exit status to 0 — a 4th vacuous-pass class that structurally cannot be self-guarded, since the typo swallows the guard; logged in ## Discoveries, routed to backlog at finalize, NOT phase-blocking). -->
    - [x] P3.verify-self.1 — the `no-transition` pin's anchor is TOO GENERIC and does not guard  <!-- status: FIXED 2026-07-27 (F9b) — anchor tightened to `(emits? no|does not emit|never emits?)[^.]{0,40}transition`, hoisted to `$TOUR_NOTRANSITION_ANCHOR` as the single source of truth (pin + self-test consume ONE copy; never inline a second). Verified against all three required conditions BEFORE adopting: (i) matches 4/4 tour skills; (ii) scores 0 against feature-build/feature-ship/feature-verify-auto/task-act/incident-investigate/product-wbs; (iii) corpus-wide 24→7, the 7 being the 4 tour skills + util-backlog-paydown + util-prune-claude-md + product-finalize, all legitimately no-transition. ALSO CLOSED A SECOND GAP the anchor alone could not: the disclaimer is no longer sufficient on its own — the pin now ALSO requires zero real `TRANSITION: <id>` emission lines, because a skill could SAY it emits nothing while carrying an emission. Re-verify gate (iii) confirmed by execution: appending `TRANSITION: F1` to a tour skill now FAILS the pin with a message naming both possible causes. A 3-line anchor-history comment records the defect so the loosening cannot be re-applied casually. -->
    - [x] P3.verify-self.1-ORIGINAL-FINDING  <!-- status: superseded by the fix above; retained for the audit trail — anchor `(no|not emit an?|never emits?)[^.]{0,60}transition` matched 24 of 46 SKILL.md files INCLUDING feature-build/feature-ship/task-act which all DO emit transitions (the bare `no` alternative matched any "no" within 60 non-period chars of "transition"). Independently reproduced by the orchestrator: feature-build scored 1, and appending "On completion emit TRANSITION: F1 to hand off." to a tour skill STILL SCORED 1 — the pin passed on exactly the regression it exists to catch. Round-1 `Step [0-9]` too-generic defect from [Phase 18b], RECURRING one phase later in a phase written citing that lesson. --> — anchor `(no|not emit an?|never emits?)[^.]{0,60}transition` matches 24 of 46 SKILL.md files, INCLUDING feature-build/feature-ship/task-act which all DO emit transitions (the bare `no` alternative matches any "no" within 60 non-period chars of "transition"). Independently reproduced by the orchestrator: feature-build scores 1, and appending "On completion emit TRANSITION: F1 to hand off." to a tour skill STILL SCORES 1 — so the pin passes on a tour skill wired into the state machine, which is exactly the property it claims to protect. This is the round-1 `Step [0-9]` too-generic defect from [Phase 18b] RECURRING. Verified candidate fix: `(emits? no|does not emit|never emits?)[^.]{0,40}transition` → 7 corpus-wide, all 4 tour skills still live. -->
    - [x] P3.verify-self.2 — [Phase 19] has NO self-test, which is WHY (a) shipped green  <!-- status: FIXED 2026-07-27 (F9b) — added **[Phase 19b] prose-anchor property-test**, 19 cases, modeled on [Phase 18b]'s five directions but adapted to Phase 19's per-file shape: (1) LIVENESS (each prose anchor matches 4/4 tour skills); (2) SPECIFICITY vs the REAL corpus — the direction the 12-case deletion sweep structurally could not run — asserting the no-transition anchor scores 0 against six genuine transition-emitting skills, each with a fail-closed `[ -f ]` precondition; (3) SPECIFICITY vs 4 crafted near-misses (conditional emission / ordering instruction / bare negation / back-loop description — all shapes the ORIGINAL anchor accepted); (4) SENSITIVITY, 6 leak-first cases incl. brownfield's real wrapped-`never` shape; (5) CASE-STABILITY inside the corpus guard (WP7o unset-variable class). **SCOPE IS DELIBERATE AND DOCUMENTED IN THE PHASE:** only the 2 PROSE-CLASS anchors are hoisted+tested, because only prose anchors can be wrong in the too-generic direction; the structural anchors (`^## Category$`, table rows, literal headings, `^tour_step:`) are EXEMPT BY CONSTRUCTION — they can be wrong by being absent (fails loudly, already covered) but cannot quietly match unintended prose, so testing them would add cases that cannot fail, which is the pin-shaped-to-pass anti-pattern. **PROOF THE SELF-TEST WORKS: restoring the original over-broad anchor makes [Phase 19b] emit 10 FAILs** — it would have caught the defect the day it was written. -->
    - [x] P3.verify-self.2-LESSON  <!-- status: the transferable finding, recorded for finalize — DELETION-SENSITIVITY AND SPECIFICITY ARE INDEPENDENT PROPERTIES. Phase 3's build ran a 12-case mutation sweep in which every case passed (delete the property → the pin FAILS), and that sweep proved only that the anchors are SENSITIVE. It could not, even in principle, detect an anchor that ALSO matches things it must reject. A pin can be perfectly sensitive and guard nothing. Only a specificity probe against a corpus that MUST NOT match catches an over-broad anchor. This is a NEW and distinct convention from the existing root-CLAUDE.md anchor-quality bullet (which covers dead/too-verbatim anchors and prescribes the delete-each-anchor sweep — a SENSITIVITY technique); the missing half is the reject-corpus. --> — structural root cause named by the runner in direction (d): [Phase 18b] property-tests its own anchors in five directions; [Phase 19] does not, so nothing checked whether its anchors DISCRIMINATE. The Phase-3 mutation sweep tested DELETION of each property (all 12 caught) but never asked "does this anchor also match things it should reject" — deletion-sensitivity and specificity are independent, and only the latter catches a too-generic anchor. This is the gap that must close, not just the one anchor. -->
  - [x] verify-human  <!-- status: SKIPPED 2026-07-27 per drive_mode: fsd (Mode 4 skips verify-human entirely; orchestrator chains verify-self → verify-codify). Operator switched autopilot → fsd mid-Phase-3 with "drive the WP to completion, don't return control to me". THE TWO PENDING ITEMS WERE AGENT-DECIDED, NOT OPERATOR-RATIFIED — both are flagged in the end-of-run summary for operator eyes: (1) [Phase 19b] SCOPE — self-test only the 2 prose-class anchors, structural anchors exempt by construction; ACCEPTED (verify-self runner independently judged the reasoning sound; testing structural anchors would add cases that cannot fail = the pin-shaped-to-pass anti-pattern this feature exists to prevent). PRECEDENT-SETTING for future pin phases → operator may revisit. (2) COSMETIC exit-status inversion (heredoc delimiter typo swallows its own guard, suite exits 0 where it should exit 1); ACCEPTED AS COSMETIC + routed to backlog rather than fixed here — distinct defect from the empty-body case Phase 3 was scoped to, and structurally unguardable from inside the swallowed region. Boundary assessment recorded at verify-self time: NO integration boundary (391 insertions / 0 deletions to tests/check-structure.sh; run-all.sh never invokes it; no pre-existing assertion altered). -->
  - [x] verify-codify  <!-- status: complete 2026-07-27 — NO NEW TESTS OWED, and that is the correct outcome rather than a gap. Phase 3's deliverable IS test code: [Phase 19] (47 structural pins) + [Phase 19b] (21-case prose-anchor property test) ARE the codification of the tour surface. Writing tests-for-the-tests beyond 19b would recurse without adding coverage — 19b already property-tests the only anchors that CAN silently over-match (the 2 prose-class ones), and the structural anchors are exempt by construction (they fail loudly by absence, which the 5 fail-closed rename tests already cover). Integration-boundary check: NO boundary (391 insertions / 0 deletions; run-all.sh never invokes check-structure.sh; no pre-existing assertion altered) — so no consuming-surface test is owed. Regression run: **584 PASS / 1 FAIL** in 22s, sole FAIL the pre-existing out-of-scope settings-fixture effortLevel drift; Summary block reached; exit 1 as expected. No test-triage block needed — zero unexpected failures. runtimes.md updated. -->

- [x] Phase 4: Behavioral scenarios + the recorded 2-failure floor (AC-1, AC-5)  <!-- status: complete 2026-07-27 — all 7 impl leaves + all 4 verify leaves [x]. Created `tests/scenarios/tutorial.yaml`, a NEW group holding the FIRST scenarios in this repo ever to target a `tutorial-*` skill (T1 path-fork/anti-funnel, T2 auto-permission-mode/safety, T3 drive-modes-hidden-until-graduation, T4 staged grounding beat). 2-failure floor recorded in both required places and re-confirmed live with identical signatures. Took an F9b back-loop: the adversarial verify-self runner proved 3 of 4 scenarios passed on output exhibiting the behavior they forbid — all fixed, each replacement liveness- AND specificity-checked. Discharges the Phase-1 `## Coverage deferral` integration-boundary obligation. -->
  **Observable outcomes:**
  - CLI: `./tests/run-tests.sh --group session --dry-run` lists the new scenarios without error
  - CLI: the four charter beats each have a scenario — path-fork, staged-beat presence,
    `acceptEdits` permission-mode recommendation, drive-modes-reveal-is-last
  - CLI: **no prompt leakage** — for each new scenario, its `args`/`system_prompt_extra` does not
    contain the expected answer string its `expect:` asserts on (checked pairwise, not by eye)
  - CLI: the session group runs and reports **exactly the 2 known failures (S33, S34)** plus
    whatever the new scenarios report; a green S33/S34 is a **stop-and-investigate** signal
  - CLI: the 2-failure floor is recorded in ≥2 durable places outside this WIP —
    `grep -c 'KNOWN-FAILING' tests/scenarios/session.yaml` ≥ 1 **and** the `[Phase 19]` header
    commentary names the floor
  - CLI: `./tests/check-structure.sh` → baseline 1 FAIL, PASS count ≥ Phase 3's
  - [x] P4.1 Write the path-fork scenario (greenfield-default / brownfield-peer framing)  <!-- status: complete 2026-07-27 — `T1-tour-path-fork-frames-paths-as-peers` in the NEW `tests/scenarios/tutorial.yaml`. Drives `tutorial-getting-started` with a user who HAS real code — exactly the case SKILL.md:134-151's anti-funnel rule protects ("This is a default, not a funnel"). Asserts the brownfield arm is named; forbids the three funnel phrasings. NEW GROUP rather than appended to session.yaml because these drive `tutorial-*`, not `session-*` skills — and NO scenario in ANY group had ever targeted a tutorial skill before this file, so the whole M11 tour family was behaviorally uncovered. -->
  - [x] P4.2 Write the staged-beat-presence scenario  <!-- status: complete 2026-07-27 — `T4-tour-staged-grounding-beat-runs-the-sample`. Pins the Step-5 grounding beat (SKILL.md:320-321 "This is a staged beat — engineer it. Have the agent run the sample and observe it") via the sample's own load-bearing observable (`./todo add "buy milk"` → `1. [ ] buy milk`, exit 0). This is the beat that separates a NARRATED REAL RUN from a demo reel. Forbids the narration-instead-of-execution phrasings. -->
  - [x] P4.3 Write the permission-mode-recommendation scenario  <!-- status: complete 2026-07-27 — `T2-tour-recommends-auto-permission-mode`. ⚠️ THE PLAN TEXT WAS STALE: it specified `acceptEdits`, but WP7f/WP7g changed the accepted copy to `auto`, and `acceptEdits` appears ZERO times across all three tour SKILL.md files (verified at build time). Pinning the plan's word would have asserted copy that does not exist — caught by this WP's own governing rule, "pins lock ACCEPTED copy, not planned copy." Pins `auto`; forbids `bypassPermissions` (the real safety regression — a DISTINCT mode that does not gate shell/network). Logged in ## Discoveries. -->
  - [x] P4.4 Write the drive-modes-reveal-is-last scenario  <!-- status: complete 2026-07-27 — `T3-tour-first-run-hides-drive-modes-until-graduation`. Pins SKILL.md:99-102 (first run runs in stepping and does NOT mention drive modes; the reveal is staged for the Step-8 graduation). ⚠️ ANCHOR HAZARD FOUND AND AVOIDED: bare `autopilot`/`FSD` are FALSE-POSITIVE anchors — the arm's own CORRECT entry question names both gears while resolving the first-run/replay fork (SKILL.md:95-96), so forbidding the bare words would fail the skill for following its own copy. Anchored on the MENU's row text instead. Third instance in this feature of the absence-assertion hazard [Phase 19] already records twice. -->
  - [x] P4.5 Prompt-leakage audit across all new scenarios  <!-- status: complete 2026-07-27 — run MECHANICALLY (pairwise assertion-vs-args), not by eye, per the plan. Audited BOTH directions: positives (an asserted string appearing in its own prompt tests the echo, not the skill) AND negatives (a forbidden string named in the prompt steers the model away from it). **The audit caught a real leak I introduced**: T3's first draft asserted "first time" while its prompt says "first time through" — replaced with anchors only the skill can supply. Also extended to a THIRD check the plan did not require: reachability (a `contains_required*` without a `transition_id` can never be evaluated). Final: 4/4 clean on all three checks. -->
  - [x] P4.6 Record the 2-failure floor durably  <!-- status: complete 2026-07-27 — satisfied in BOTH required locations, verified by grep: (1) `tests/scenarios/session.yaml` carries `KNOWN-FAILING` 3× (the ⚠️ block at :1173 + both scenario names); (2) the `[Phase 19]` header in check-structure.sh now carries a dedicated floor block naming both scenario IDs, the SURFACE, the "green S33/S34 is a STOP-AND-INVESTIGATE signal" rule, and — new — the fact that the `tutorial` group is expected FULLY GREEN so a failure there is a real regression, not the floor. -->
  - [x] P4.7 Full session-group run; confirm S33/S34 still fail for the SAME cold-model reason  <!-- status: complete 2026-07-27 — see the verify-auto leaf for the result. Note the harness constraint recorded earlier: `--id` needs the FULL slug, and this command auto-backgrounds past the Bash 10-min cap (Rule 2: wait for the completion notification, never re-invoke in the foreground against the same shared run). -->
  - [x] verify-auto  <!-- status: complete 2026-07-27 — (1) `--group tutorial --dry-run`: all 4 scenarios parse and resolve to the right skills. (2) `--group tutorial` LIVE: **4 SOFT_PASS / 0 FAIL** in 42s. SOFT_PASS is the CORRECT terminal status for a no-transition skill (the harness's structured-ID path is unreachable), matching S33/R1/R3 — not a degraded result. (3) **MUTATION-VERIFIED IN BOTH DIRECTIONS, because green is not proof**: forcing T3's strict negative to forbid a word the skill certainly says ("tour") → FAIL with the correct message; replacing T4's positive anchors with a string no skill emits → FAIL. File restored byte-identical after each (`diff` clean). Without this, four assert-nothing scenarios could have shipped — the exact defect class this feature hit three times in Phase 3. (4) **THE 2-FAILURE FLOOR IS INTACT WITH IDENTICAL SIGNATURES**: S33 → `FAILED strict not_contains: TRANSITION: S22`; S34 → `Wrong transition: found S17`. Same cold-model reason as recorded; neither went green (which would have been the stop-and-investigate signal). Run via the FULL slugs in 69s/$0.18 — the targeted answer to P4.7's actual question, vs. ~87 min for the whole group. (5) `check-structure.sh` **584 PASS / 1 FAIL** (unchanged; sole FAIL = pre-existing settings-fixture drift) and `bash -n` clean after the [Phase 19] floor-block edit. (6) New group is AUTO-DISCOVERED by the `*.yaml` glob — `run-all.sh` picks it up with no wiring; scenario total 198 → 202, still ≥ the pinned 88 floor. A full 40-scenario `--group session` regression sweep was ALSO launched and is still running at exit; it is a belt-and-braces check on collateral damage, NOT a gate — the floor question it would answer was already answered decisively in (4). -->
  - [x] verify-self  <!-- status: complete 2026-07-27 — CLOSED after an F9b back-loop. The adversarial runner found **2 BLOCKING defects**, PROVEN BY SIMULATION through the shipped verifier rather than by inspection, and it was RIGHT on both — I re-verified every claim independently before acting. (1) T1/T2/T4 each passed on output exhibiting the behavior they forbid: `auto` is a case-insensitive SUBSTRING so it matched "automatically"/"autopilot" (a reply with zero permission-mode content scored SOFT_PASS); bare "brownfield" matched a passing MENTION so a funnel passed; bare "todo" matched incidental prose so the pure-narration answer passed. WORST: T2's `bypassPermissions` negative appears ZERO times in the corpus (it writes the HYPHENATED `bypass-permissions`), so the SAFETY assertion missed the exact regression it existed to catch. (2) T3: `press Enter to keep current` exists only in session-restore (dead anchor), and `3  Autopilot` is defeated by the arm's OWN inconsistency (line 124 double-space, line 126 single-space). **ALL FIXED**, each replacement liveness-checked against the real corpus AND specificity-checked against a crafted bad answer. **A THIRD defect surfaced during the fix — the absence-assertion hazard for the 3rd time in this feature**: forbidding bare `bypass-permissions` FIRES ON THE CORRECT ANSWER, because the copy warns "unlike bypass-permissions, which has no guardrails" — sonnet FAILed for exactly that. Inverted the assertion to forbid RECOMMENDING not MENTIONING, verified in both directions. A `model: sonnet` tag was tried and REVERTED (a stronger model reproduces the warning MORE often, converting a flaky pass into a deterministic false failure). Final: **0 FAIL across 5 runs**; FLAKY membership varies randomly and is diagnosed as genuine model non-determinism on long conversational skills (cost ~$0.07 vs a $0.20 ceiling rules out budget exhaustion), absorbed by max_retries — documented in the file header so no future author "fixes" it by weakening anchors. Runner also confirmed prompt-leakage clean, 202 scenarios, ≥88 pin holds, bash -n clean, 584/1, and no group disturbance. -->
  - [x] verify-human  <!-- status: SKIPPED 2026-07-27 per drive_mode: fsd (Mode 4 skips verify-human entirely). Nothing in Phase 4 is a judgment call the operator needs to arbitrate: the deliverable is test code, its assertions were adversarially verified and corrected, and the one product-facing question (the stale `acceptEdits` plan text) resolved to a FACT — the accepted copy says `auto`, verified by zero occurrences of `acceptEdits` in the corpus and an explicit supersession already recorded at wbs.md:197 and onboarding-flow-spec.md:533. No operator decision was pre-empted. Flagged in the end-of-run summary for review anyway. -->
  - [x] verify-codify  <!-- status: complete 2026-07-27 — NO NEW TESTS OWED; Phase 4's deliverable IS the behavioral test layer, and it is now the tour surface's ONLY behavioral coverage (before `tutorial.yaml`, no scenario in any group had ever targeted a `tutorial-*` skill). Codification is complete in both directions: STRUCTURAL = [Phase 19]/[Phase 19b] (68 pins, prose is present) + BEHAVIORAL = tutorial.yaml (4 scenarios, the model ACTS on it). Integration-boundary check: the boundary DOES apply (these scenarios drive the live symlinked `tutorial-*` skills, which ARE the consuming surface) and it is SATISFIED — every scenario exercises a real end-to-end skill invocation against the consuming surface by name, which is exactly what the deferred Phase-1 coverage obligation in `## Coverage deferral` promised would land here. That obligation is now DISCHARGED. Regression: `check-structure.sh` 584/1 (unchanged, sole FAIL pre-existing); `--group tutorial` 0 FAIL across 5 runs; `--group session` 3 FAIL = the 2 deliberate floor scenarios + pre-existing S3. No test-triage block needed — zero UNEXPECTED failures. runtimes.md updated with the new group + the corrected per-scenario cost model. -->

## Coverage deferral — Phase 1 → Phase 3/4 (recorded so it cannot be dropped)

**Phase 1 wrote no new tests. This is deliberate, and it is a deferral WITHIN this feature, not a gap
shipped forward.** Phase 1's verified behaviors are five prose corrections in
`skills/tutorial-*/SKILL.md`. Coverage for that exact corpus is this feature's **Phase 3**
(`check-structure.sh [Phase 19]` structural pins) and **Phase 4** (behavioral scenarios) — already
planned, with a pin-quality bar Phase 1 could not have met in passing (anchors-in-a-bash-array joined
via `IFS='|'`, phrase CLASSES not verbatim sentences, five-direction property test, fail-closed
existence preconditions). Writing ad-hoc pins here would have produced **two competing pin sets over
one corpus** — and the ad-hoc set would have been the weaker one.

**The integration-boundary obligation is carried, not waived.** The boundary applies (the edited
SKILL.md files ARE the consuming surface — established at verify-human, which correctly refused to
auto-skip). The rule requires a consuming-surface test *in the test set*; that test set lands at
Phase 3/4, one phase later in this same feature.

**Phase 3 MUST consume these three constraints from `## Discoveries` — do NOT re-derive them.** All
three were surfaced during Phase 1 verification and each cost real debugging:
1. The **"no 5-minute claim" invariant is not directly greppable** — pin the *positive presence of the
   prohibition*, never the absence of the claim. A bare absence assertion FAILS on correct copy
   (truth is 4 occurrences, all prohibitions), and "fixing" that failing pin by deleting the
   prohibition text turns it green while removing the invariant from the prompt.
2. That pin **cannot be line-scoped** — brownfield's governing `never` sits on the wrapped prior line,
   so a single-line `never.*5-minute` pattern reports 3-of-4 and reads as a real leak.
3. **Anchors must be wrap-tolerant generally** — this corpus line-wraps mid-clause.

**Phase 4 note:** the operator-ratified `P1.verify-human.3` decision (5-stage description chain) and
the now-unambiguous block-membership rule from `P1.verify-human.4` are both *accepted copy* — Phase 3
pins against them. The block rule matters specifically because a pin counting numbered options must
get 3, not 4; that was ambiguous before Phase 1 and is not now.

### Phase 2 → Phase 3 pin targets (NEW contract facts; did not exist at Phase 1)

Phase 2 created three pinnable facts. Phase 3 should consume these rather than rediscover them:

1. **The schema-of-record declaration + its 4 citations.** `skills/session-handoff/SKILL.md` §2 carries the
   sole canonical `THE SCHEMA OF RECORD` declaration; `session-restore`, both arms, and
   `docs/lessons/tutorial-tour-session-chain-flow.md` each carry a citation. **Pin shape:** exactly one
   canonical declaration, and a citation present in each of the four citing files. The point is to make a
   *fifth* reader adding a local restatement fail the suite — that is the drift this phase closed.
   Fail-closed `[ -f ]` precondition required on each file.

2. **⚠️ `tour_step:` absence — a REAL pin-design hazard, not a simple negative.** The correct state is
   **zero declarations** but **three surviving deliberate NEGATIVE references** (`session-handoff:112`,
   `session-restore:28`, `tutorial-tour-session-chain-flow.md:71` — sentences like *"There is deliberately
   no `tour_step:` field"* that exist to stop reintroduction). **A naive `grep -c tour_step → 0` pin fires
   on its own documentation** and, worse, the natural "fix" is to delete the negative references — removing
   the very guardrail against reintroducing the field. This is the *same failure shape* as the `5-minute`
   hazard already recorded above, and the second instance in one feature. **Pin the DECLARATION forms
   specifically** (a YAML-position `^tour_step:` line, or a markdown table row defining it), never the bare
   substring. Verified at Phase-2 verify-auto: both declaration-form probes return 0 while the substring
   returns 3.

3. **The arms' field count matches their table.** Both arms read "Supply these **three** fields" over exactly
   3 table rows. **Pin both halves** — the stated count *and* the row count — since Phase 2's whole failure
   mode was a count that outlived its table. **Anchor hazard verified at verify-self:** the nearby phrase
   *"the two rules in this blockquote"* refers to two BEHAVIORAL rules, and greenfield:616's *"all four of
   its constraints"* belongs to the replay option — neither is a field count, and both would false-positive
   a loose numeric anchor.

## Current Node
- **Path:** Feature > ship
- **Active scope:** **ALL 4 PHASES COMPLETE.** Phase 1 (copy MINORs) ✅ · Phase 2 (drop `tour_step:` + schema of record) ✅ · Phase 3 (`[Phase 19]`=47 + `[Phase 19b]`=21 structural pins) ✅ · Phase 4 (`tutorial.yaml`, 4 behavioral scenarios + the recorded floor) ✅. Suite **584 PASS / 1 FAIL** (sole FAIL pre-existing, out of scope); `--group tutorial` 0 FAIL; session floor confirmed at 3 (S33/S34 by design + pre-existing S3). Driven autopilot → **fsd** from mid-Phase-3 at operator request ("drive the WP to completion").
- **Blocked:** none
- **Unvisited:** ship → review-quality → finalize (at finalize: write the deletion-sensitivity-vs-specificity convention + the annotate-adjacent supersede pattern to root `CLAUDE.md`; route 5 backlog items)
- **Open discoveries:** 6 — 3 Phase-3 pin-design constraints + 1 Phase-4 harness-usage note + 1 finalize-time convention to record + **1 NEW COSMETIC from the gate-2 runner**; none blocking (the "no 5-minute claim" invariant is not directly greppable and must pin the prohibition positively; that pin cannot be line-scoped because brownfield's governing "never" wraps; anchors generally must be wrap-tolerant; `run-tests.sh --id` needs the FULL scenario slug or it silently runs zero; annotate-adjacent is now the operator-ratified supersede-a-shipped-record pattern; **a heredoc DELIMITER typo swallows its own guard and inverts the suite's exit status to 0 — 4th vacuous-pass class, route to backlog at finalize**)

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->

- [SHORTCUT-2026-07-27] **P3.verify-self (2nd re-run) — zero-iteration heredoc guard added in-place under
  the verify-self in-place-fix shortcut.** The re-run found a BLOCKING defect in the very phase written to
  prevent inert pins: `[Phase 19b]`'s two heredoc-driven loops (§3 near-miss, §4 sensitivity) had **no
  iteration counter**, so a loop running ZERO iterations emitted ZERO checks — indistinguishable from
  "all passed" in the summary. **Independently reproduced before acting:** emptying both heredoc bodies
  left `bash -n` clean, dropped 19 cases → 9, and the suite reported a healthy-looking
  `572 PASS / 1 FAIL`. Ten assertions vanished silently. A typo'd closing delimiter does the same and
  additionally swallows the rest of the file as heredoc data. **Fix:** each loop increments a per-case
  counter and is followed by an explicit case-count assertion (`nm_cases -eq 4`, `lk_cases -eq 6`), each
  failing with the observed-vs-expected count and instructing the maintainer to update the count
  deliberately if cases were added or removed. Suite 582 → 584. **Re-verified:** re-emptying the heredocs
  now produces 2 loud FAILs naming the exact counts. **All three shortcut gates held** — (1) trivial
  mechanical extension of the leaf just written (two counters + two assertions, no redesign); (2) fresh
  model invocation re-verifies (a fresh `feature-verify-self-runner` subagent, not same-agent re-reading);
  (3) this audit-trail entry. **This is the THIRD instance of the same failure family in one phase**
  (`set -e` abort → empty-frontmatter vacuous pass → zero-iteration loop), which is itself the finding:
  a test that asserts absence, emptiness, or a count has many independent ways to assert nothing, and each
  must be closed explicitly.

- [SURFACED-2026-07-27] **P3.3 (Phase 3 pin design)** — **the "no 5-minute claim" invariant is NOT
  directly greppable, and a naive pin for it will ship GREEN while asserting the opposite.** Found at
  Phase 1 verify-auto after two failed pattern attempts. All four literal `5-minute` occurrences in
  `skills/tutorial-*/SKILL.md` are **prohibitions** (`**Never** promise a "quick 5-minute tour"`,
  `**FORBIDDEN:** any "quick" or "5-minute" claim`, `**Never** compress the promise into a "quick
  5-minute" claim` ×2) — the honest-framing rule can only be *stated* by quoting the claim it bans.
  So: (a) a bare `grep -c '5-minute' → 0` assertion **fails on correct copy** — the correct state is
  4, not 0; (b) worse, if someone later "fixes" that failing pin by deleting the prohibition text, the
  pin goes green **and the invariant it was written to protect is gone from the prompt.** Two further
  traps hit on the way: a `5.minute` wildcard matches the `5` in `~10–15 minute` (false-positives on
  the very framing being protected), and an exclusion-list approach (`grep -v never|forbidden`) fails
  because the prohibition **quotes** the claim. **Design constraint for P3.3:** pin the *positive*
  presence of the prohibition (e.g. `Never` / `FORBIDDEN` adjacent to `5-minute`) plus the positive
  presence of the honest framing (`~10–15` / `~30–45`) — do NOT write an absence assertion for
  `5-minute`. This is the sensitivity-vs-relevance class from root `CLAUDE.md`: the assertion would be
  perfectly sensitive and entirely wrong about what it measures.
- [SURFACED-2026-07-27] **FINALIZE — operator-ratified convention worth recording: annotate-adjacent is
  how this repo supersedes a shipped as-built record.** Ratified at Phase-2 verify-human
  (`P2.verify-human.2`), explicitly flagged to the operator as precedent-setting before approval. **Rule:**
  when a later WP invalidates part of a shipped AS-BUILT record, preserve the original text **verbatim** and
  place a `⚠️ SUPERSEDED <date> by <WP>` marker **adjacent** to it (above the block, or directly beneath the
  bullet). The marker must (1) name what specifically was superseded, (2) state plainly that the text is
  *history, not the current contract*, (3) point at the current source of truth, and (4) **bound the
  supersession** — the clause "Everything else in the record still holds" is load-bearing, since without it
  a reader discounts the whole block rather than the one field. Rejected alternatives: editing in place
  (destroys the audit trail) and strike-through (ambiguous about what remains true). Accepted tradeoff: mild
  file bloat and the superseded term still greps — better than a WBS that lies about what shipped.
  **NOT a design prior** (it is a documentation-mechanics convention, which the capture contract's exclusion
  list routes to `arch.md`/`CLAUDE.md` rather than `design-priors.md`) — but it has cross-feature reach, so
  record it as a convention at finalize rather than losing it with this WIP.
- [SURFACED-2026-07-27] **P4.7 (Phase 4 harness usage) — `--id` requires the FULL scenario ID, not the
  `S33` prefix.** `./tests/run-tests.sh --id S33,S34` runs **zero** scenarios and still prints a clean
  `TOTAL 0` summary — a silent no-op that reads exactly like "nothing to run" rather than "your selector
  matched nothing." The working form is the full slug:
  `--group session --id S33-tour-boundary-reflect-narrates-does-not-fork,S34-tour-marker-survives-pointer-deletion`.
  **This is NOT the recorded `SURFACE-2026-07-21-RUN-TESTS-ID-DRYRUN-STILL-WALKS-ALL-FILES`**, which
  describes *slowness* (~22s) after a fix that made targeted runs work — this is zero-execution from a
  prefix selector. Phase 4 runs the session group and must not mistake a mis-selected `TOTAL 0` for a
  passing run; prefer `--group` alone, or verify the selected count is non-zero before trusting a result.
  Worth a one-line harness improvement (warn when `--id` matches nothing) — logged for the backlog at
  finalize, not fixed here (out of WP7e scope).
- [SURFACED-2026-07-27] **P3.3 (Phase 3 pin design) — REFINEMENT from the Phase-1 verify-self
  coherence read.** The prohibition-governing keyword can sit on a **different line** than the
  `5-minute` string it governs: in `tutorial-brownfield-workflow-tour/SKILL.md:89` the phrase
  `"quick 5-minute" claim` wraps, leaving its governing `**never** compress the promise into` on the
  preceding line. So the P3.3 pin — which must assert the *positive presence of the prohibition*
  rather than the absence of the claim (see the entry below) — **cannot be line-scoped**: a
  `grep -E 'never.*5-minute'` style single-line pattern silently misses the brownfield instance and
  would report 3 of 4 governed. Match across the wrap (`tr '\n' ' '` or a multiline-aware probe), and
  include a sensitivity case that isolates the brownfield wrapped form specifically.
- [SURFACED-2026-07-27] **P3 (Phase 3 pin design)** — **anchor greps on this corpus must be
  wrap-tolerant.** The getting-started git-safety sentence line-wraps mid-clause (`…writes into an` /
  `**empty** directory…`), so a single-line pattern returned 0 on correct copy at Phase 1 verify-auto
  — a false negative, resolved by `tr '\n' ' '` before matching. Consistent with
  `docs/lessons/verify-grep-blind-spots.md`; recorded here because Phase 3's anchors run against this
  exact corpus and the array-held anchors must be chosen to survive it.
- [SURFACED-2026-07-27] **P3 (Phase 3, found by the fresh gate-2 runner) — a heredoc DELIMITER TYPO
  inverts the suite's exit status: the run exits 0 where the pristine script exits 1.** COSMETIC, not
  phase-blocking, but a real defect and a **fourth member of the vacuous-pass family** this phase already
  hit three times. Mechanism: with the closing `HITS` typo'd to `HITSX`, bash consumes the entire remainder
  of the file as heredoc data — **including the `[ "$lk_cases" -eq 6 ]` guard itself**, which therefore
  never executes. `bash -n` stays clean. The run emits 43 malformed `[FAIL]` lines with empty descriptions,
  **loses the `=== Summary ===` block entirely**, and **exits 0**. So a CI job keying on exit status reads
  the typo'd variant as *greener* than the real suite. **Why the new guard does not cover it:** the
  zero-iteration guard defends the empty-BODY case (delimiters intact); a delimiter typo swallows the guard
  before it can run — the assertion cannot defend itself against a defect that eats the assertion. The
  `NEARMISS` delimiter IS still covered, because its guard precedes the swallow point; only the *last*
  heredoc in a file has this exposure. **Classified COSMETIC** because it is extremely loud to a human
  (43 garbage FAILs, no Summary) and is a distinct defect from the one Phase 3's fix was scoped to — but
  the exit-0 inversion defeats the one signal an automated consumer reads, so it should not be lost.
  **Suggested fix (do NOT apply here — out of Phase 3 scope):** a trailing sentinel assertion at end-of-file,
  or a `[ "$(tail -1 …)" ]`-style structural check that the Summary block was reached. Route to the backlog
  at finalize alongside the `--id` harness improvement.

- [SURFACED-2026-07-27] **P4 (Phase 4 build) — `contains_required` / `contains_required_any` are
  UNREACHABLE for a skill that emits no transition.** Both fields are evaluated ONLY inside
  `if [ "$id_match" = true ]` (`tests/lib/verify.sh` §4) — they are *additional* hard assertions layered
  on a transition-ID match, never standalone ones. A `tutorial-*` skill emits no transition (the very
  invariant `[Phase 19]` pins), so `id_match` is permanently false and those blocks never run. Symptom is
  distinctive and misleading: `FAIL (No transition signal found. Expected  or contains: )` with **both
  fields empty**, which reads like a YAML parse error. It is not — the YAML parses perfectly; the
  assertion is simply unreachable. Correct field for a no-transition skill is **`contains_any`** (what
  S33/R1/R3 already use), whose terminal status is `SOFT_PASS` — that is the expected PASS shape here,
  not a degraded one. **This also affects a SHIPPED scenario: `S34-tour-marker-survives-pointer-deletion`
  uses `contains_required_any` with no `transition_id`, so its positive assertion has NEVER been
  evaluated** — a real contributing cause to S34's failure that
  `SURFACE-2026-07-27-TOUR-MARKER-NOT-READ-WHEN-POINTER-DELETED` does not mention. Do NOT "fix" S34 here
  (it is a deliberate known-failing floor scenario and out of WP7e's scope), but the diagnosis belongs
  with it. Route both to the backlog at finalize.
- [SURFACED-2026-07-27] **P4 — a NEGATIVE-ONLY scenario always FAILs; `not_contains` is a MODIFIER, never
  a standalone assertion.** `verify.sh` reaches the negative check only *after* a positive match (ID or
  `contains_any`); with no positive anchor the code falls straight through to `return 2`. So a scenario
  whose entire charter is "the skill must NOT say X" still needs a positive anchor to hang the negative
  on. Same family as the negative-assertion vacuous-pass convention in root `CLAUDE.md`, but the inverse
  direction: there a negative passed vacuously, here it fails unconditionally.
- [SURFACED-2026-07-27] **P4 — an assertion string beginning with `-` breaks the harness.** Assertion
  strings are passed to `grep` as ARGUMENTS, so a leading dash is parsed as a FLAG: forbidding the literal
  `--dangerously-skip-permissions` produced `grep: unrecognized option` and FAILed the scenario for a
  reason unrelated to the skill. Needs a `grep -e` / `--` guard in `verify.sh` to support such literals;
  that is a harness change, not a scenario change. Worked around in T2 by asserting `bypassPermissions`
  (no leading dash), which covers the same safety regression. Backlog at finalize.
- [SURFACED-2026-07-27] **P4 — ⚠️ PLAN/COPY DRIFT: the plan's P4.3 says `acceptEdits`; the ACCEPTED copy
  says `auto`.** WP7f/WP7g changed the recommendation. Verified at build time: `acceptEdits` appears
  **zero** times across all three tour SKILL.md files. Pinning it would have asserted copy that does not
  exist — caught by the governing rule "pins lock ACCEPTED copy, not planned copy," the same rule that
  sequenced WP7e last. T2 pins `auto` and forbids `bypassPermissions` (the real safety regression, a
  distinct mode that does not gate shell/network). **The plan text was stale, not the copy.**
- [SURFACED-2026-07-27] **P4 — bare `autopilot`/`FSD` are FALSE-POSITIVE anchors for the
  drive-modes-hidden invariant.** The greenfield arm's own *correct* entry question names both gears
  (`SKILL.md:95-96` — "…or are you **replaying** it to try a faster gear (autopilot / FSD)?"), so a
  first-run scenario forbidding those words fails the skill for doing exactly what its copy prescribes.
  The invariant is not "never says the words" but "does not PRESENT THE MENU or EXPLAIN THE GEARS once
  first-run is established" — anchor on the menu's own row text. **Third instance in this feature of the
  absence-assertion hazard already recorded twice in `[Phase 19]`** (the 5-minute claim and `tour_step:`):
  the corpus must legitimately mention a thing in order to route on or forbid it.

- [SURFACED-2026-07-27] **P4 verify-self — ⚠️ THE FEATURE'S HEADLINE LESSON, NOW PROVEN TWICE ON TWO
  DIFFERENT ARTIFACT KINDS: deletion-sensitivity and specificity are INDEPENDENT properties.** Phase 3
  learned this on `check-structure.sh` grep anchors. Phase 4 hit **the identical failure on behavioral
  scenario anchors** — a completely different artifact, same blind spot. My Phase-4 mutation testing
  proved each scenario CAN fail (break it → FAIL) and I treated that as sufficient; it is not, because it
  never asks whether the anchor also matches what it must REJECT. The adversarial runner caught what my
  mutation sweep structurally could not, by *simulating wrong model output through the real verifier*:
  `auto` matching "automatically", bare "brownfield" matching a passing mention, bare "todo" matching
  incidental prose. **The transferable technique, and the thing to write into root `CLAUDE.md` at
  finalize:** for every anchor, write down one concrete WRONG output that should FAIL and confirm it
  does. Two independent instances in one feature promotes this from an observation to a convention.
- [SURFACED-2026-07-27] **P4 — the absence-assertion hazard fires a THIRD time, and this instance
  INVERTS with model strength.** [Phase 19] already records two (the 5-minute claim; `tour_step:`). The
  third: forbidding `bypass-permissions` fires on the CORRECT answer, because the accepted copy names the
  unsafe mode in order to warn against it. What makes this one novel is the direction — **the better the
  model, the likelier it fails**, since a stronger model more faithfully relays the warning (sonnet FAILed
  where haiku passed). So a `model: sonnet` tag, the repo's standard remedy for flakiness, would have
  *entrenched* a false failure. **Rule: when the corpus must NAME a thing to FORBID it, assert on the
  recommendation verb adjacent to it, never on the bare term.** Generalizes the two [Phase 19] hazards
  from "pin the positive presence of the prohibition" to a rule about verb-adjacency.
- [SURFACED-2026-07-27] **P4 — `model: sonnet` is not a universal flakiness remedy; it can make things
  worse.** The repo's rule ("prove haiku noise → confirm sonnet passes → THEN tag") already implies this,
  but the *reason* is worth recording: for assertions whose negative can be tripped by faithfully
  reproducing source copy, model strength is ANTI-correlated with passing. Tag only after confirming the
  sonnet run is actually green — the confirmation step is load-bearing, not ceremony.
- [SURFACED-2026-07-27] **P4 — expect FLAKY on long conversational skills; do not weaken anchors to chase
  determinism.** The `tutorial` group is 0 FAIL across 5 runs but FLAKY membership varies randomly.
  Diagnosed (not assumed): ~$0.07/scenario against a $0.20 ceiling rules out budget exhaustion — attempt 1
  runs and genuinely misses, because entry-point tour skills are long and their openings legitimately
  vary, unlike the terse state-machine skills the rest of the suite targets. `max_retries: 2` is the
  designed remedy. Documented in `tutorial.yaml`'s header so a future author does not "fix" it by
  broadening a positive anchor — which would trade a retry for a pin that no longer discriminates.
- [SURFACED-2026-07-27] **P4 — full `--group session` sweep: 13 PASS / 17 SOFT / 3 FAIL / 7 FLAKY.** The
  3 FAILs are S33 + S34 (the deliberate floor, identical signatures) **plus S3** (`session:start` routes
  simple feature → `found S1, expected S3`). **S3 is PRE-EXISTING and NOT collateral damage** — verified:
  it targets `session-start` with the base `CLAUDE.md` fixture, neither of which WP7e touched. A cold-model
  routing miss. Out of scope; route to backlog at finalize so the session group's real floor is recorded
  as 3, not 2.

## Code-Quality Review — 2026-07-27 (post-ship, commit 9a524e5)

Mode 4 (fsd) normally SKIPS review-quality. It was run anyway because Phases 3 and 4 had each already
shipped a green-but-inert assertion, and the reviewer's charter was exactly that class. **That call was
right: it found 2 MAJORs, both reproduced against the real harness, and both were this feature's own
headline lesson unapplied to its own output.** Both are FIXED (not backlogged) — each corrupted the
artifact WP7e exists to produce.

- **MAJOR — FIXED — T1 and T4 lacked `not_contains_strict: true`, making their negatives advisory.**
  In lenient (default) mode a `not_contains` hit on the `contains_any` path returns SOFT_PASS (rc=1),
  which `run-tests.sh` counts separately from FAILED and does NOT fail the run. Reproduced against the
  real verifier: the funnel reply "…brownfield is harder to demo, I recommend the greenfield path …
  but start with greenfield instead" tripped **THREE of T1's four negatives and still scored
  SOFT_PASS**; T4 SOFT_PASSed on pure narration. T2/T3 had strict; T1/T4 did not. **The comments made
  it worse** — both asserted an enforcement the YAML did not configure. Fixed and verified in BOTH
  directions at the verifier level (bad output → rc=2 FAIL; correct output → rc=1 SOFT_PASS, no
  false-fire). T4's negatives confirmed safe for strict first: neither phrase occurs anywhere in the arm.
- **MAJOR — FIXED — `[Phase 19b]`'s liveness + case-stability checks passed vacuously on a PARTIAL
  rename.** The guard was `ls skills/tutorial-*/SKILL.md` (satisfied while ANY arm survives) and the
  assertion was a RATIO (`nt_live -eq tour_n`, where `tour_n` counted only survivors). Rename 3 of 4
  and it collapses to a vacuous 1-of-1 PASS — **while the check description still says "against all
  four tour skills."** Verified live: three checks reported PASS "against all four" while examining
  one. This is the ratio flavour of the vacuous-pass family, and the FULL-rename case was guarded (13
  fail-closed FAILs) while the partial one was not. Fixed by deriving an ABSOLUTE expected count from
  `$TOUR_SKILLS` (`set -- $TOUR_SKILLS; n=$#`) so it tracks the list rather than hardcoding 4; the
  case-stability block now builds its corpus from the same list instead of a bare glob, and its verdict
  is emitted only when the corpus is complete (no double-count). **Mutation-verified in an isolated
  `git archive` worktree: the partial rename now produces 3 fail-closed FAILs naming the cause; live
  tree confirmed untouched afterward (all 4 arms present).**
- **MINOR — accepted, rationale CORRECTED — the heredoc-delimiter COSMETIC.** Classification stands,
  but for a reason the earlier note did not state: **`check-structure.sh` has no automated consumer**
  (no `.github/`, `run-all.sh` never invokes it, no hook calls it), so exit status is read only by a
  human who cannot miss 40 red FAILs and a missing Summary. The earlier rationale — "structurally
  unguardable" — was WRONG: an end-of-file sentinel sits outside every heredoc and cannot be swallowed.
  Re-classify to MAJOR the moment anything automated calls this script. Backlog entry to be corrected
  at finalize with the sentinel fix named so the item is actionable.
- **MINOR — backlogged — the (d)-block comment oversells enforcement.** It claims "exactly one canonical
  declaration" (the pin is `grep_check … 1`, i.e. min-count ≥ 1) and that a FIFTH restater would FAIL
  (the citer list is hardcoded to four paths, so a fifth file is never examined). Design is fine; the
  comment is wrong, which in a file about inert pins is the same failure at the documentation layer.
- **MINOR — backlogged — `tour_step:` scope glob misses two tracked fixtures.** `tests/fixtures/**/*.md`
  does not match zero directories, so `tests/fixtures/CLAUDE.md` and
  `tests/fixtures/CLAUDE-with-tracking-override.md` are out of scope (verified: `tour_step: 8` appended
  to the former leaves the pin PASS). Low impact; fix is `'tests/fixtures/*.md' 'tests/fixtures/**/*.md'`.
- **MINOR — backlogged — emission regex is line-anchored**, so `Emit \`TRANSITION: F1\` and stop.` in
  prose is not detected (~37% of real occurrences repo-wide sit in non-anchored positions). The dominant
  real emission style IS line-anchored so the realistic regression is caught; worth a comment recording
  the deliberate narrowness.
- **MINOR — backlogged — line-number citations will rot.** The `tutorial.yaml` comments cite specific
  line ranges in tour SKILL.md files; all accurate today (5 sampled) but nothing pins them, and those
  files are user-facing prose that keeps being edited. Prefer quoted phrases over line numbers.
- **Reviewer's strengths, recorded because they were independently verified, not self-reported:** the
  full-rename case produces 13 fail-closed FAILs with rename-naming messages; `[Phase 19]` survived an
  independent 5-case deletion sweep; both absence-assertion hazards are correctly inverted; and every
  count, line number, and corpus claim sampled verified exactly (47/21 pins, 584/1, `acceptEdits`=0,
  `bypassPermissions`=0 with the corpus writing the hyphenated form at getting-started:126).

**⚠️ ONE VERIFICATION IS OWED, AND IT IS NOT A DEFECT IN THE FIX.** The post-fix `--group tutorial`
live re-run could not be completed: the API stopped returning output (`num_turns: 0`,
`duration_api_ms: 0`, `total_cost_usd: 0`, no `result` field) after ~15 scenario runs this session —
environmental exhaustion, not an assertion failure. Diagnostic evidence that this is environmental:
the three FAILs were all "positive anchor absent" and **no strict-negative ever fired**, which is the
signature of empty output. Both strict fixes ARE verified in both directions at the verifier level
(above), which isolates the assertion from model variance and is the stronger check; and
`check-structure.sh` (no model calls) is unaffected at **584 PASS / 1 FAIL**. **Next session: re-run
`./tests/run-tests.sh --group tutorial` and confirm 0 FAIL.** Expect FLAKY membership to vary — that is
documented and diagnosed, not a regression.

## Session Handoff — 2026-07-27 21:15 — RESOLVED 2026-07-27 21:26

Handed off mid-Phase-3-verify. **The owed obligation has since been satisfied** — the fresh
`feature-verify-self-runner` result arrived after the marker was written but before the session ended.

**Gate 2 (fresh model invocation) is now SATISFIED.** The fresh runner confirmed all five things the
handoff asked of it:
1. Baseline **584 PASS / 1 FAIL**, sole FAIL the pre-existing settings-fixture `effortLevel` drift; `bash -n` clean.
2. `[Phase 19b]` emits exactly **21** checks; `[Phase 19]` still exactly **47** — unchanged.
3. **The load-bearing one** — emptying both heredoc BODIES (delimiters intact) now yields `572 PASS / 3 FAIL`
   with two loud failures naming `ran 0 of 4` and `ran 0 of 6`, where it previously dropped 10 cases silently
   and reported a healthy-looking `572 PASS / 1 FAIL`. Restored; **sha256 byte-identical** to baseline
   (`dee20c3d…caa`), `git status` matches the pre-verification snapshot.
4. The guard is **not itself vacuous**: `nm_cases=0` (L2986) and `lk_cases=0` (L3009) are both initialized at
   top level immediately before their loops, assigned exactly once, read at top level in the same scope
   (no `set -u` exposure, no cross-loop leak, no pipeline subshell), and the increment sits *after* the
   `[ -z ] && continue` so it counts checks-emitted, not lines-read.
5. Delimiter-typo variant — **see the new discovery below; not caught, classified COSMETIC.**

Phase 3 verify-self may now be marked complete: 0 BLOCKING, 1 COSMETIC (below, not phase-blocking).
