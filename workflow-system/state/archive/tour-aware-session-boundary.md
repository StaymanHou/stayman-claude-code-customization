# Feature: Tour-aware session boundary — no mid-tour handoff offer (WP7m)

**Workflow:** feature
**State:** Completed 2026-07-27 (BUILT — verify-human acceptance DEFERRED+OWED, NOT accepted)
**Created:** 2026-07-27
**Drive mode:** autopilot
**WBS:** `workflow-system/product/wbs.md` → M11 / WP7m

## Problem Statement

When the onboarding tour drives its in-tour feature to a terminal close (`feature-finalize` →
`session-reflect` with nothing to persist), that close **correctly** presents as a clean workflow
boundary, and the modeled `S22` exit chain (`reflect → session-handoff`, AUTO in all four drive
modes) pulls toward writing a session handoff — **mid-tour, with Step 7 Scene 3 and all of Step 8
still unrun.** The operator's live walkthrough hit this: the agent recognized `S22`, noticed the tour
had beats left, and *offered a fork* ("Continue the tour" vs. "Hand off now"). Operator ruling:
**"It should just continue the tour without offering the hand off option."**

The root cause is a genuine ambiguity, not an agent error. Two different "boundary" notions coexist
inside a tour run: the tour's **own staged** boundary (Step 7 deliberately runs `/session-handoff` →
`/exit` → `/session-restore` as a teaching beat) and the state machine's **real** boundary (the
in-tour feature's terminal close). Neither `session-reflect` nor `session-handoff` has any
tour-awareness (`grep -i 'tour\|tutorial'` → 0 substantive hits), and the arms never state which
boundary wins. The agent's hedge-and-ask was a *reasonable* local read of a real ambiguity — so the
fix is to **remove the ambiguity**, not to correct a mistake.

**Verified origin evidence** (raw log `~/.claude/projects/-Users-stayman-Work-Tmp-mccc-tutorial-a/edf22b62-…jsonl`,
msg 45): the agent wrote *"Writing a handoff now would end the session mid-tour rather than at the
tour's own boundary… Tell me which you want: **Continue the tour** … **Hand off now**"*, emitted
`S22`, and stopped. The operator had to type **"continue the tour"** (msg 48) to proceed.

## Design decisions settled at plan time (7m.1)

**The guard lives in the tour arms, NOT in the general session skills.** This satisfies the WBS's
stated preference ("prefer keeping tour-specific knowledge **out of** the general session skills if
the cost is comparable") at *zero* cost, because:

1. Both arms **already** carry a terminal contract at exactly the right altitude — *"The tour ends
   here… there is nothing further to invoke and no transition to emit"* (greenfield SKILL.md ~:453,
   plus the `## Transitions` "None." block ~:470). What's missing is only the **mid-tour** analogue:
   "a close reached *inside* the tour is not the session's boundary."
2. Putting it here makes 7m.3 (general `S22`/`S23` unchanged for real work) true **by construction**
   rather than by testing — the general session skills are not edited at all, so there is no
   regression surface to protect.
3. The arms are already the authority the running agent has loaded when the misfire fires — the tour
   skill prompt is in context for the whole run, so a guard there is *read* at the moment it matters.

**Escalation clause (WBS WP7m): checked and NOT triggered.** No new transition ID, no new edge, no
modeled table row, no edits to the pause-policy tables in the 4 `agents/*/AGENTS.md`, no
`transitions.md` change. The `tutorial-*` family emits no transitions and that invariant is
preserved. Therefore `/feature-plan` (not `/feature-spec`) is correct, per the operator's ruling.

**Rejected alternatives, with reasons:**
- **(b) `session-reflect`/`session-handoff` gain a "hosted inside a tutorial run" precondition** —
  rejected. It puts tour knowledge into two general, heavily-used skills, creates a real regression
  surface for all non-tour work, and requires an in-tour detection signal those skills cannot read
  reliably (there is no on-disk in-tour marker, and inventing one is scope the ruling excludes).
- **(a) arms declare an in-tour marker the boundary chain consults** — rejected as over-built for the
  same reason: a new cross-skill artifact + a consult step in general skills, to solve what a prose
  precondition in the arm solves. Deferred as a possible future move if the prose guard proves weak.

## Work Tree

- [ ] Phase 1: Tour-arm boundary guard + staged/real boundary disambiguation  <!-- status: in-progress -->
  **Observable outcomes:**
  - CLI: `grep -Eic "not the session's boundary" skills/tutorial-{greenfield,brownfield}-workflow-tour/SKILL.md` → ≥1 each (the guard is present in BOTH arms). **Note the `-i`:** the heading reads `… is NOT the session's boundary` — a case-sensitive grep returns 0 on correct copy.
  - CLI: in each arm, the guard names the exit chain and both general skills — `grep -c 'S22'`, `'S23'`, `'session-reflect'`, `'session-handoff'` → ≥1 each
  - CLI: the guard states the rule imperatively — `grep -c 'do not take that exit, and do not offer it'` → 1 each; and scopes it to all gears — `grep -c 'holds in every drive mode'` → 1 each
  - CLI: staged-vs-real disambiguation present in both arms' Step 7 — `grep -c 'Two different'` → 1 each
  - CLI: the general session skills are UNCHANGED — `git diff --name-only -- skills/session-reflect skills/session-handoff skills/session-capture` → empty output (this is the 7m.3 regression guard, verified as a diff assertion)
  - CLI: `./tests/check-structure.sh` → exit 0 with no NEW failures vs. the known-baseline 472 PASS / 1 pre-existing settings-fixture FAIL
  - CLI: no bare `.claude/` introduced — `check-structure.sh` Phase 12 still passes (path-qualification mandate)
  - [x] P1.1 Greenfield arm: add the mid-tour boundary guard — a tour-hosted terminal close (`feature-finalize`/`task-close` → `reflect`) is NOT the session's boundary; continue the tour, do not offer or take `S22`/`S23`  <!-- status: complete -->
  - [x] P1.2 Greenfield arm Step 7: disambiguate the tour's own STAGED `/exit` boundary from the state machine's real boundary, so the two cannot be conflated (7m.4)  <!-- status: complete -->
  - [x] P1.3 Brownfield arm: mirror P1.1 + P1.2 (scope-symmetry — the arm also drives a real in-tour unit of work through a close)  <!-- status: complete -->
  - [x] P1.4 Confirm the general session skills are untouched and the `tutorial-*` no-transition invariant holds  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete — 4 scoped checks + suite at known baseline -->
  - [x] verify-self  <!-- status: complete — subagent 12/12 PASS (7 mechanical + 5 coherence) -->
  - [ ] verify-human  <!-- status: DEFERRED — boundary APPLIES, F11 skip forbidden; OWED via the operator's full hands-on tour run (operator 2026-07-27: "defer. I'll just do a full tour again after changes are done") -->
    - [ ] P1.verify-human.1 Guard answers the ruling — a mid-tour close continues the tour, no handoff offer  <!-- status: DEFERRED: owed at the full hands-on run -->
    - [ ] P1.verify-human.2 Step 7's own staged handoff is NOT suppressed — the distinction reads crisply  <!-- status: DEFERRED: owed at the full hands-on run -->
    - [ ] P1.verify-human.3 Copy fits the arms' voice; guard is findable where an agent reads it  <!-- status: DEFERRED: owed at the full hands-on run -->
    - [ ] P1.verify-human.4 Open design question answered — refuse-if-non-empty on every replay (WP7l carry-over)  <!-- status: DEFERRED: owed at the full hands-on run -->
  - [x] verify-codify  <!-- status: complete — 13 pins added to Phase 18, all mutation-verified; suite 472→485 -->

- [x] Phase 2: Reflect into the design contract  <!-- status: complete — all children [x] -->
  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — 7m.5 is an explicit WBS subtask; the spec is the family's design contract and WP7e pins against it
  - Requirements unchanged: yes — the guard shipped exactly as planned in Phase 1; nothing learned there altered Phase 2's scope
  - Solution still feasible: yes — additive revision section + two beat-row resyncs, no structural change
  - No superior alternative discovered: yes — the spec is the single durable contract; skipping it would leave WP7e pinning against an undocumented invariant
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: `grep -c 'WP7m' workflow-system/product/onboarding-flow-spec.md` → ≥1 (a `## Revision 2026-07-27` section records the guard as a family invariant)
  - CLI: the spec's §3 beat rows for BOTH arms reference the guard — `grep -c 'mid-tour' workflow-system/product/onboarding-flow-spec.md` → ≥1
  - CLI: `transitions.md` and all 4 `agents/*/AGENTS.md` are UNCHANGED — `git diff --name-only -- workflow-system/product/transitions.md agents/` → empty output (proves the escalation clause never fired)
  - CLI: `./tests/check-structure.sh` → exit 0, no new failures vs. baseline
  - [x] P2.1 Add a `## Revision 2026-07-27 (WP7m)` section to `onboarding-flow-spec.md` recording the guard + the settled placement rationale  <!-- status: complete -->
  - [x] P2.2 Resync the §3 beat rows for both arms (the WP7l/WP7n revision-header lesson: do not claim a resync that was not performed)  <!-- status: complete — VERIFIED per-row: lines 310 (greenfield) + 332 (brownfield) both carry the WP7m note, count=2 -->
  - [x] P2.3 Update `wbs.md` WP7m: check 7m.1–7m.5, record AS-BUILT  <!-- status: complete — also resynced the progress line + the M11-tail sequencing note so no stale "next step is WP7m" claim survives -->
  - [x] verify-auto  <!-- status: complete — frontmatter + table-integrity + observables; suite 485/1 unchanged -->
  - [x] verify-self  <!-- status: complete — subagent 9/9 PASS incl. claim-vs-reality audit; one overstated-precision claim self-corrected -->
  - [x] verify-human  <!-- status: complete — AUTO-SKIPPED (F11): no integration boundary (docs-only) + autopilot + verify-self 9/9; affirmation printed for read-time veto. NOTE: distinct from Phase 1, whose boundary APPLIED and whose gate is DEFERRED+OWED. -->
  - [x] verify-codify  <!-- status: complete — NO new pins by design (see rationale); suites re-run green: structural 485/1 baseline + scaffold 20/0 -->

## Integration boundary

**APPLIES.** This feature changes prose inside shipped, consumed skill prompts
(`skills/tutorial-{greenfield,brownfield}-workflow-tour/SKILL.md`) that a live tour run reads. Per the
integration-boundary rule: verify-self must cite the consuming surface (the arm prompt as the running
agent reads it), the F11 verify-human skip path is **forbidden**, and verify-codify must include a
check on the consuming surface.

**Consequence for this feature:** the operator's copy acceptance is **owed**, and it joins the already-
DEFERRED WP7l/WP7n greenfield-arm read — one single re-acceptance pass over the finished arm covering
all three fixes (operator: *"defer to when all the fixes are in place"*). WP7m is the last of the
three, so **this feature completes the set that unblocks that read.**

## Known-baseline note (do not mis-triage at verify-auto)

`./tests/check-structure.sh` is at **472 PASS / 1 FAIL** *before* this feature starts. The single FAIL
is a **pre-existing, unrelated** settings-fixture drift (`effortLevel: live=<missing>
fixture="xhigh"`), same class as the tracked `project_settings_fixture_claudesk_drift` memory. It
flipped PASS→FAIL between 2026-07-24 and 2026-07-25 with no settings file touched. **Treat 472/1 as
green for this feature**; a 2nd failure is a real regression.

## Current Node
- **Path:** Feature > finalize (ship + review-quality complete)
- **Active scope:** none — Phase 2 CLOSED `[x]`; Phase 1 complete except its DEFERRED human gate
- **Review-quality:** complete — 0 CRITICAL / 2 MAJOR / 4 MINOR; **4 fixed in-feature** (both MAJORs
  + 2 MINORs, all mutation-verified, suite 485 → 487), **2 MINORs backlogged** (1 routed to WP7e's
  copy-freeze, 1 test-harness ergonomics)
- **Blocked:** P1.verify-human.1–.4 — DEFERRED to the operator's full hands-on tour run; Phase 1's
  parent checkbox **cannot** close until they land (all-children-`[x]` rule is the enforcement)
- **Unvisited:** P2 verify-auto → verify-self → verify-human → verify-codify
- **Open discoveries:** none blocking (one method note + one verified non-finding recorded below)

## Test Triage — settings fixture in sync with live (modulo documented diffs)
Classification: Obsolete test — the fixture asserts an `effortLevel` key the live `~/.claude/settings.json` no longer carries; the assertion is stale with respect to the environment, not broken by this feature.
Confidence: high
Evidence: `effortLevel: live=<missing> fixture="xhigh"` — this feature touched only the two arm SKILL.mds, `tests/check-structure.sh` (additive pins), `runtimes.md`, `wbs.md`, and the WIP; **no settings file was modified** (`git status` confirms none staged/unstaged), and the failure predates this feature — it flipped PASS→FAIL between 2026-07-24 and 2026-07-25, already recorded in `runtimes.md` and the tracked `project_settings_fixture_claudesk_drift` memory.
Action: **No action taken — deliberately not fixed here.** Out of scope for WP7m: the fix is either updating `tests/fixtures/settings.json` or adding `effortLevel` to `INTENTIONAL_DIFFS`, both of which are host-environment drift maintenance unrelated to the tour-aware boundary guard. Fixing it inside this feature would silently bundle an unrelated change into a copy-freeze-sensitive commit. Left failing and reported as the known baseline (472/1 → 485/1, delta zero on this assertion). Already tracked; no new backlog entry needed.

## Verify-codify — Phase 1 (2026-07-27)

**Integration boundary APPLIES** → codify must cover the consuming surface. The consuming surface here
is the two arm `SKILL.md` prompts *as a running agent reads them*, so the highest-level reliable check
is a structural assertion against those real files (there is no HTTP/CLI surface to drive; the "test"
of a prompt is that the required instruction is present in the file the harness loads).

**13 pins added to `tests/check-structure.sh` [Phase 18]** — deliberately placed in the *existing*
`S22`/`S23` exit-chain phase rather than a new phase, because the guard is a narrow precondition on
that same chain. Suite **472 → 485 PASS** (+13, exactly the new pins), 1 pre-existing FAIL unchanged.

**Scoping decision (load-bearing — pins-lock-ACCEPTED-copy).** verify-human is **DEFERRED** for this
phase, so the pins are scoped to **copy-independent behavioral invariants only**:
- guard *present* in both arms (heading), names the `S22`/`S23` chain it suppresses, forbids **both**
  taking and offering, scopes to **all four** drive modes, and distinguishes staged-vs-real (5 × 2 arms)
- **3 regression pins:** `session-reflect` / `session-handoff` / `session-capture` carry **zero**
  tour-specific knowledge — this is what mechanically enforces "the guard lives in the arms," so a
  future migration into the general skills fails the suite and forces re-justification.

**Deliberately NOT pinned** (WP7e's charter, against operator-accepted copy): wording, ordering,
sentence counts, block membership. Pinning those now would freeze copy the operator has not read —
inverting the rule. Note also the `SURFACE-2026-07-25-WP7N-CLOSE-STRUCTURE-UNPINNED` caveat that a
naive sentence-count pin on tour prose is *flaky*; none was written.

**All 13 mutation-verified** (a green pin proves nothing until seen to fail — and per the
"mutation-testing validates SENSITIVITY, not RELEVANCE" convention, every mutation was applied to the
**real** shipped files with **no** env-var override or fixture redirection, i.e. the same files a live
tour loads):

| Mutation | Caught by |
|---|---|
| Delete the entire guard section from the greenfield arm | guard-heading + forbids-BOTH + all-drive-modes pins (3 FAILs) |
| Soften the imperative → "ask the user which they prefer" | forbids-BOTH pin |
| Remove/rename the staged-vs-real Step 7 blockquote | distinguishes-staged-vs-real pin |
| Migrate tour-awareness *into* `session-reflect` | the `session-reflect` no-tour-knowledge regression pin |

*Honest note on pin independence:* under Mutation 1 the `names-S22` pin did **not** fail, because
`S22` legitimately also appears in the Step 7 blockquote. That is correct — the two assertions are
independent by design and the heading pin is the deletion detector. Recorded so a future reader does
not mistake it for a weak pin. All mutations reverted; `session-reflect` verified byte-identical to
HEAD afterward.

## Verify-codify — Phase 2 (2026-07-27)

**No integration boundary** — Phase 2 edits product docs only; no endpoint/UI/CLI/job consumes them.

**Decision: NO new pins written, deliberately.** §2 requires checking existing coverage before writing,
and the check says don't:

1. **The behavior is already covered.** The thing that can regress is *the guard*, and Phase 1's 13
   mutation-verified Phase-18 pins cover it. The docs are the **record** of that behavior, not a second
   implementation — pinning them would duplicate covered behavior, which §2 explicitly excludes.
2. **`onboarding-flow-spec.md` has ZERO content pins by design** (`grep -c onboarding-flow-spec
   tests/check-structure.sh` → **0**). It is a *living design doc*; the standing WP5/WP6 precedent is
   **pin the shipped skill, not the living doc**.
3. **Precedent is direct and identical.** WP7l/WP7n's equivalent docs step (archived WIP → P2.5) added
   **no** pins for the same spec edits, for the same reason.
4. **Pinning now would invert the pins-lock-ACCEPTED-copy rule** — Phase 1's verify-human is DEFERRED,
   so spec prose describing unaccepted copy must not be frozen. That is WP7e's charter.

**Suites re-run (§3), both green:**
- `./tests/check-structure.sh` → **485 PASS / 1 FAIL** (the already-triaged pre-existing settings-fixture
  drift; no new triage entry needed — classification unchanged from the Phase-1 entry above)
- `skills/tutorial-greenfield-workflow-tour/scripts/test/run-tests.sh` → **20 passed / 0 failed**,
  confirming WP7m did not disturb WP7l's scaffold coverage (incl. the `--dest .` flat-stamp and
  refuse-non-empty-cwd assertions)

## Retrospect

- **What changed in our understanding:** The word "boundary" turned out to be overloaded in exactly
  the same shape as "pause" (WP5) and "research" (WP6) — **one word, two costs, and the agent picking
  by the word rather than by position.** A tour run contains *two* legitimate boundaries: the tour's
  own staged Step-7 teaching beat, and the state machine's real terminal close. The M11 tail has now
  produced a third instance of the same family of defect, which suggests the pattern is structural to
  this system rather than incidental to any one vocabulary.
- **Assumptions that held:**
  - The WBS's plan-first ruling was right — the escalation clause was checked and **never fired** (no
    new edge, no table rows, zero edits to `transitions.md` or the 4 `agents/*/AGENTS.md`).
  - The preference for keeping tour knowledge *out of* the general session skills turned out to cost
    **nothing**, and paid a bonus: it made "general `S22`/`S23` unchanged for real work" true *by
    construction* rather than by testing.
  - Reading the origin session's raw log before planning again paid off — the misfire was recovered
    **verbatim** (including that the operator had to type "continue the tour"), which is what made it
    obvious the agent's reasoning had been *sound* and the ambiguity was the real defect.
- **Assumptions that were wrong:**
  - **My own pins were the weakest part of the feature, not the guard.** I wrote them, mutation-verified
    them, reported 13/13 green — and the reviewer then found they **failed OPEN** on a renamed file and
    matched a vocabulary narrower than the invariant they advertised. Both verified real.
  - **"Mutation-verified" gave me false confidence — again.** This is the *second* time in the same
    WP-family (WP7l was the first) that a mutation test passed while testing the wrong thing. The
    mechanism is subtle: my mutation wrote the word `tutorial`, so the narrow pattern caught it; the
    mutation confirmed *sensitivity* and told me nothing about *coverage*. The repo's convention bullet
    already warns about exactly this and I still walked into it.
  - I assumed a case-sensitive grep would match my own heading. It didn't (`NOT` is emphasis-cased) —
    the 5th grep-on-prose false negative in this family, and the copy was right every time.
- **Approach delta:** Implementation matched the plan; the delta was all in *verification rigor*. Four
  review findings were fixed in-feature rather than backlogged, because each one corrupted the artifact
  **WP7e is chartered to pin against** — the same judgment WP7l made for the same reason. The one
  copy-shaped finding was deliberately **not** fixed, since it edits the region the operator's deferred
  acceptance read covers.

## Closure message

> **Feature complete (BUILT, acceptance owed):** WP7m — tour-aware session boundary — has landed. A
> terminal close reached *inside* an onboarding tour run no longer takes or offers the `S22`/`S23`
> session-handoff exit chain in any drive mode; the tour just continues, while the tour's own staged
> Step-7 handoff beat still runs untouched. To see it: run `/tutorial-greenfield-workflow-tour` and
> watch the in-tour feature's close — it should proceed straight into Step 7 with no "continue the tour
> vs. hand off?" fork. **Not yet accepted** — the copy read is deferred to your full hands-on tour run,
> which now covers WP7l + WP7n + WP7m together.

Requester = operator — closure notice for self-record.

## Code-Quality Review — tour-aware-session-boundary (WP7m)

Reviewer subagent against ship commit `18722aa`. **0 CRITICAL / 2 MAJOR / 4 MINOR.**
Every finding was **verified against the code before acting** (review-finding-actions-are-hypotheses
convention) — all six reproduced. Disposition below; **4 fixed in-feature, 2 backlogged.**

### Strengths (reviewer)
- Placement decision load-bearing and correctly argued — the guard in the arms makes "general
  `S22`/`S23` unchanged" true *by construction*, stronger than any test could prove.
- Over-fire protection engineered with **three independent mechanisms**, not one — the stated main
  regression risk is well covered.
- Arm scope-symmetry near-perfect (only correct arm-specific adaptations diverge).
- The 4th-tour-surface exemption **independently re-derived** by the reviewer, not taken on trust.
- The codify record's **self-reported pin weakness** (the `names-S22` pin not failing under Mutation 1)
  made the pins fast to calibrate — adverse disclosure is what made the record trustworthy.

### FIXED IN-FEATURE (4) — not backlogged, because each corrupts WP7e's inherited artifact
1. **MAJOR — block `(i)` pins failed OPEN on a missing/renamed file.** Verified: a synthetic
   `skills/session-DOESNOTEXIST/SKILL.md` **PASSED** the assertion (`2>/dev/null` + `||true` → empty
   count → `:-0` → 0 → pass). Not hypothetical — WP5/M9 renamed exactly these three skills, so a
   future rename would leave three permanently-green pins asserting nothing. **Fixed** with an explicit
   `[ -f ]` precondition that fails closed and names the rename case in its message.
   **Mutation-verified:** the renamed-skill simulation now FAILS with that message.
2. **MAJOR — block `(i)` vocabulary narrower than the invariant it advertised.** Matched only
   `tutorial|workflow tour`, so a leak worded "onboarding tour" / "the greenfield arm" passed clean
   (confirmed: 0 hits for `onboarding|greenfield|brownfield` in all three files → entirely unguarded).
   This is **the repo's own sensitivity-vs-relevance trap** — my mutation wrote the word `tutorial`, so
   it passed while coverage stayed partial. **Fixed** by widening the alternation (NOT loosening to bare
   `tour`, which false-positives on session-reflect:38 "unnecessary detours" — verified).
   **Mutation-verified** on both previously-missed vocabularies, with the `detours` control still PASS.
3. **MINOR — stale `~30 lines` in `wbs.md:423`.** The verify-self correction (~40 actual: 40 greenfield
   / 43 brownfield) landed in the WIP and the spec but **not** the WBS — the same doc-vs-reality class as
   WP7l's MAJOR, surviving in 1 of 3 copies. **Fixed**; all three copies now consistent. (The other
   `~30` at `wbs.md:498` is WP7n's unrelated pre-existing claim about the full-cycle tour — left alone.)
4. **MINOR — close enumeration missed `feature-refactor` (F21).** The guard listed
   `feature-finalize`/`task-close`, but the canonical exit chain (`transitions.md:132,136`) has **four**
   closes; an in-tour CRITICAL finding routes F40 → refactor → F21 → reflect → `S22`. Behavior was
   already correct (the rule binds on `S22`/`S23`, not on the enumeration), so this was a precision gap
   in **agent-facing** instruction → fixable now, not WP7e's. **Fixed in both arms.**

Suite after hardening: **485 → 487 PASS** / 1 pre-existing FAIL (the +2 is the heading assertion split
into a heading-anchor pin + a case-stable-substring pin).

### BACKLOGGED (2 MINOR) — routed, not fixed
5. **MINOR — the hand-rolled `grep -ciE` block in `(h)` duplicated `grep_check`'s body.** Partially
   addressed while fixing #1: verified a **case-stable** anchor exists (`the session's boundary` and
   `^### The tour hosts the workflow` each match exactly 1× per arm), so the block was replaced with two
   standard `grep_check` calls — which also fail *closed*. Recorded as resolved-in-passing; the residual
   note (whether `grep_check` should gain an optional `-i` flag for future callers) is backlogged low.
6. **MINOR — the Step-7 blockquote's closing sentence is unscoped.** *"If you find yourself about to
   write `.session.md` anywhere other than Step 7 Scene 1, you are following the wrong boundary"* reads
   absolutely, so it would also suppress an **explicitly operator-requested** mid-tour handoff ("I need
   to stop, write me a handoff") — which the global session-vocabulary convention treats as the
   legitimate expensive branch when explicitly named. The `## Category` bullet is correctly scoped ("on
   the strength of `S22`/`S23`"); this sentence is not. **Backlogged rather than fixed** because it edits
   **tour copy inside the region the operator's DEFERRED acceptance read covers**, and the fix wording
   ("…unless the user explicitly asks for one") is exactly the kind of copy WP7e must freeze against
   *accepted* text. Real but narrow hole; the auto-chain suppression it exists for works correctly.

### Assessment (reviewer, verbatim summary)
"Well-built for what it is… The strongest engineering judgment in the diff is the placement call —
locating the guard in the two arms rather than teaching tour-awareness to three heavily-used general
session skills converts the feature's main regression risk from 'something to test' into 'something that
cannot happen'… The debt that does exist is concentrated in the pins, not the guard." Both pin defects
are now closed in-feature.

### If you disagree
Dismiss any finding by editing this section and marking the line `[DISMISSED]` before
`feature-finalize` archives this WIP.

## Deferred human gate — Phase 1 (WP7m)

**Operator, 2026-07-27:** *"defer. I'll just do a full tour again after changes are done"* — the copy
read is deferred to a **full hands-on tour run**, not a diff read. Integration boundary APPLIES
(prose inside shipped, consumed skill prompts), so the F11 skip path was **forbidden** and the Mode-3
auto-skip gate correctly did **not** fire (gate (c) fails). These gates are **owed, not waived.**

**WP7m is the third and last of the three ratified greenfield fixes** (WP7l + WP7n + WP7m), so the
condition the operator set at the WP7l gate — *"defer to when all the fixes are in place"* — is now
met. The owed read is **one** hands-on greenfield-arm run covering all three fixes, not three passes.

**Checklist to re-present at that run (the WP7m-specific items; WP7l/WP7n's 6-item list lives in the
archived WIP `greenfield-tour-cwd-sample-and-close-restructure.md` → `## Deferred human gate`):**

1. **P1.verify-human.1** — mid-tour, the in-tour feature's close must just **continue the tour**: no
   `/session-handoff`, no `.session.md` write, and **no "continue the tour vs. hand off?" fork**. This
   is the exact misfire; watch for it at the in-tour close (Step 6→7 region).
2. **P1.verify-human.2** — **and yet** Step 7's *own* staged `/session-handoff` → `/exit` →
   `/session-restore` beat must still run normally. Both must hold simultaneously; the risk is the
   guard over-firing and killing the teaching beat.
3. **P1.verify-human.3** — the guard is agent-facing instruction (the user never sees it), so judge it
   by whether the *run behaves right*, not by on-screen copy.
4. **P1.verify-human.4 — the OPEN DESIGN QUESTION carried from WP7l, still unanswered.** "Sample lands
   flat in cwd, **refuse if non-empty**" means the empty-cwd guard fires on **every replay** (the user
   stands in the previous run's dir). Mitigated in copy (the Step-8 invite sends them to a new empty
   folder), so it should not bite — but it is genuinely rare only on *first* runs. The passed-over
   alternative — **ask + offer a `./onboarding-sample-todo/` subdir fallback** — is cheap **now** and
   **expensive after WP7e pins this copy**. A full hands-on replay is exactly the run that will expose
   it. **Answer owed before WP7e freezes.**

## Verify-self — Phase 1 (2026-07-27)

**Integration boundary: APPLIES** (prose changed inside shipped, consumed skill prompts) → the F11
verify-human skip path is **forbidden** for this phase. Outcomes cite the consuming surface by name
(both arm `SKILL.md` paths). No dev URL — no running app; the consuming surface *is* the prompt files.

Independent subagent (`feature-verify-self-runner`), CLI + coherence read: **12/12 PASS**, zero
BLOCKING, zero COSMETIC.

- **7 mechanical outcomes** — guard present in both arms (case-insensitive; see the NOTE below),
  names `S22`/`S23`/`session-reflect`/`session-handoff`, imperative no-take-no-offer phrasing,
  all-drive-modes scoping, staged-vs-real blockquote in both Step 7s, **both load-bearing empty-diff
  guards** (general session skills untouched; `transitions.md` + `agents/` untouched), and
  `check-structure.sh` at 472/1 with the sole FAIL being the known settings-fixture drift.
- **(a) Answers the ruling** — three separately-named prohibitions (don't invoke `/session-handoff`,
  don't write `.session.md` on the strength of `S22`/`S23`, don't present the fork) + "the answer is
  always 'continue.'" The "why" note concedes the agent's `S22` read was *sound*, which removes the
  incentive to re-derive.
- **(b) No over-fire onto Step 7's own staged handoff** — the reviewer independently identified three
  mechanisms that keep the guard from suppressing the tour's legitimate handoff: the Category guard
  carves Step 7 out by name; the Step 7 blockquote scopes suppression to the *close*; and the
  bright-line test is *positively* framed (it licenses Step 7 rather than banning writes). This was
  the main regression risk of the whole feature and it is covered.
- **(c) Arms substantively equivalent** — identical grep counts; only correct adaptations diverge.
- **(d) Factual claims verified against `transitions.md:481-482`** — `S22`/`S23` definitions and the
  "AUTO in all four drive modes" label match the guard's wording exactly; the guard explicitly
  disclaims introducing a transition, consistent with both arms' `## Transitions` = "None."
- **(e) Placement sane** — `## Category` is the 2nd heading (read every run before any beat); the
  Step 7 blockquote sits ~40 lines *above* the scripted `/session-handoff` in Scene 1 (measured
  40 greenfield / 43 brownfield — the reviewer caught my initial "~30" as overstated precision; the
  load-bearing invariant is "read before the action", which holds).

## Verify-auto — Phase 1 (2026-07-27)

Scoped to the two changed files (prose-only SKILL.md edits — no code, so syntax/import smoke is
frontmatter + repo-convention checks):

| Check | Result |
|---|---|
| YAML frontmatter parses, both arms (`name`/`description`/`argument-hint`) | **PASS** |
| Path-qualification mandate — no bare `.claude/` introduced (0 hits, both arms) | **PASS** |
| `tutorial-*` no-transition invariant — 0 TRANSITION-emit lines, both arms | **PASS** |
| `./tests/check-structure.sh` | **472 PASS / 1 FAIL — known baseline, 0 new** |

**The 1 FAIL is the pre-existing settings-fixture drift** (`effortLevel: live=<missing>
fixture="xhigh"`), unrelated: no settings file was touched by this feature. Phase 18's `S22`/`S23`
pins all still PASS, independently confirming the general exit chain is unmodified. Runtime 22.1s
(registry said 23s; `runtimes.md` updated).

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->

[NOTE-2026-07-27] P1.verify — **grep-on-prose was wrong again; the copy was right.** The plan's O1
assertion used a case-sensitive `grep -c "not the session.s boundary"` and returned **0** on both
arms, while the shipped heading correctly reads `… is **NOT** the session's boundary`. Diagnosed per
the repo convention (*"when a grep 'fails' on prose, suspect the grep before the copy"* —
`docs/lessons/verify-grep-blind-spots.md`) before editing anything; the fix was to the assertion
(`-i`), not the prose. This is the **5th** instance in the WP7-family sessions. No backlog entry —
the convention already exists and is being followed; recorded here only as a data point that the
blind-spot list should perhaps name **case-variance in emphasis words** (`NOT`, `MUST`) explicitly,
alongside the already-listed en-dash / bold-wrap / line-wrap cases.

[NOTE-2026-07-27] P1.verify-self — **4th tour surface checked for the same exposure: none. Verified,
not assumed.** The verify-self subagent observed that `skills/tutorial-product-cycle-tour/SKILL.md`
also runs `/session-handoff` (its own staged bookend) yet carries no guard, and correctly flagged the
scope question rather than scoring it a defect. Checked: that tour drives **only**
`product-vision → roadmap → research → arch → wbs` (grep of every skill it invokes) and reaches
**zero** terminal closes — `grep -Ei 'finalize|task-close|session-reflect'` → **0 hits**. With no
terminal close there is no `session-reflect`, so `S22`/`S23` can never fire and the exposure does not
exist. **Correctly out of WP7m's scope; no guard needed, no backlog entry** (padding the backlog with
a non-issue would cost WP7e a spurious pin target). Recorded here so a future reader doesn't re-open
it as an apparent scope-symmetry gap — the asymmetry is *load-bearing*, not an oversight.
