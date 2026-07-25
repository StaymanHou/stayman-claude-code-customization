---
workflow: feature
state: ship (complete)
drive_mode: autopilot
ship_commit: 783bdf2
created: 2026-07-25
wbs_ref: "workflow-system/product/wbs.md → M11 ratified block → WP7l + WP7n"
---

# Feature: Greenfield tour — sample lands in the user's cwd + Step-8 close restructure (WP7l + WP7n)

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-07-25

## Problem Statement

The operator's batch hands-on acceptance walkthrough (2026-07-25) passed three of the four tour
surfaces and returned three fixes against the **greenfield arm**. Two of them are built here together
because they edit the same region — the arm's Step-8 close (WP7n's `Next Step:` block and WP7l's
offer-to-clean-up beat both land there; WP7l/WP7n task 7n.3 owns the merge). The third fix (WP7m,
tour-aware session boundary) is sequenced **after** this feature so its guard placement is settled
against an already-restructured close rather than racing a third concurrent edit to the same lines.

**WP7l — the sample lands in the wrong place.** The arm runs `new-sample.sh` bare, so the sample is
stamped into a `$TMPDIR` throwaway that the agent then `cd`s into. On the live run the operator had to
interrupt and ask *"Can you copy it over to the current directory?"*, after which the agent copied it
**flat into the cwd** — which the operator accepted and ran the rest of the tour from. The shipped
dispatcher copy **already promises this behavior** (`tutorial-getting-started` Step 0 tells the user to
`cd` into an empty folder because *"it'll create its own small throwaway sample project **there**"*),
so this is a behavior/copy divergence, not a design change. Operator rulings: stamp **flat into the
cwd**; if the cwd is **non-empty, refuse and tell the user to `cd` to an empty directory and re-run**;
and since the tour performs **no teardown at all** today (grep-verified) and the sample now lands in
the user's real cwd, **offer** a cleanup at close (not auto-remove — that would destroy the artifacts
the close cites as proof; not silence).

**WP7n — the close buries the decision.** Greenfield Step 8 is ~108 lines emitting graduation reveal →
un-push → replay invitation → "what we didn't demo" → deep-dive pointer → artifacts, so the actionable
choice is interleaved with prose. Operator ruling: narrative above, and a short scannable
**`Next Step:`** block last with each option ≤3 sentences.

**Verify-before-edit findings (review-finding-actions-are-hypotheses discipline).** Two premises in the
WP text were checked against the code before planning, and one is now known to be a no-op:
- `new-sample.sh` **already** implements exactly the ruled behavior — `--dest DIR` ("must be empty or
  nonexistent"), a `--force` override, and a no-clobber guard that writes nothing on refusal. Its smoke
  suite **already** covers both (group 5 `--dest` fresh copy; group 6 non-empty refusal writes nothing).
  **So task 7l.4's "adjust the script" half is expected to be a no-op** — the fix is the arm's
  *invocation*, not the script. Phase 1 confirms this rather than assuming it.
- Brownfield Step 8 is **118 lines** with the same two-branch shape → 7n.4 genuinely applies there.
  Full-cycle Step 8 is **54 lines** with no replay/graduation/mode-menu → likely a light check only.
  Per WP7n, apply only where the burial actually exists; do not assume symmetry.

## Work Tree

- [ ] Phase 1: WP7l — sample lands flat in the user's cwd (+ pre-flight copy)  <!-- status: NOT-STARTED -->
  **Observable outcomes:**
  - CLI: `skills/tutorial-greenfield-workflow-tour/scripts/test/run-tests.sh` exits 0 with all groups PASS (regression guard — the script surface must be unchanged or still green)
  - CLI: in an empty dir, `new-sample.sh --dest .` exits 0 and `ls` shows `todo`, `lib/`, `todos.txt`, `README.md` at the top level of that dir (flat, no nested `todo/` wrapper)
  - CLI: in a non-empty dir, `new-sample.sh --dest .` exits non-zero, prints a message naming the non-empty destination, and writes no files (`ls` unchanged before/after)
  - CLI: `grep -c 'new-sample.sh' skills/tutorial-greenfield-workflow-tour/SKILL.md` ≥ 1 and the arm's invocation line passes a `--dest`-style flag (no bare invocation remains as the instruction)
  - CLI: `grep -n 'empty' skills/tutorial-getting-started/SKILL.md` matches in the Step-0 greenfield branch (strengthened empty-dir requirement present)
  - CLI: `./tests/check-structure.sh` shows no NEW failure vs. the 2026-07-25 baseline (472 PASS / 1 pre-existing settings-fixture FAIL; total 473 assertions)
  - [x] P1.1 Verify `new-sample.sh`'s `--dest`/no-clobber surface against the ruling; change the script ONLY if a real gap is found (expected: no change)  <!-- status: done — CONFIRMED NO CHANGE NEEDED. Empirically tested all three ruled behaviors: `--dest .` in an empty dir → exit 0, stamps FLAT (todo, lib/, todos.txt, README.md at top level, no nested wrapper); non-empty dir → exit 1, message names the destination, wrote nothing (ls identical before/after); flat copy is runnable (`todo add "buy milk" && todo list` → exactly `1. [ ] buy milk`). The WP's "adjust the script" half was indeed a no-op — the fix is the arm's INVOCATION. Script left untouched (git-confirmed). -->
  - [x] P1.2 Arm env section: stamp flat into the user's cwd via `--dest`; drop the `cd`-into-`$TMPDIR` instruction; add the empty-cwd precondition + refuse-and-explain path  <!-- status: done — invocation → `new-sample.sh --dest .`; added the "stamp into the cwd, do NOT cd away" rule + why (beat A: files they can see in a dir they chose); empty-cwd requirement + refuse-and-explain copy (explicitly: do NOT --force, do NOT fall back to a temp dir, stop and wait); "no cd needed after a successful stamp". Swept 3 downstream staleness sites the change created: (a) the WP7i upfront-framing "and `cd` in" → removed + now says "right here in this folder"; (b) the replay note at the entry section → documents that the empty-cwd guard WILL normally fire on a replay (user stands in last run's dir) and that this is expected, never --force; (c) Step-8 replay invite → now tells the user to start the replay from a NEW empty folder (without it, every replay would hit the guard with no warning). -->
  - [x] P1.3 Strengthen `tutorial-getting-started` Step-0 greenfield copy so the empty-dir requirement is unambiguous and states the consequence (refusal is a rare backstop, not a common wall)  <!-- status: done — "empty folder is ideal" → "must be standing in an empty directory — a REQUIREMENT, not a preference", states the mechanism (arm stamps into the session's cwd; scaffolder refuses non-empty) and the consequence (a non-empty dir stops the tour before it begins), plus an agent-side `ls` pre-check when the user names an existing dir. Also corrected the greenfield-needs-no-git-safety rationale, which had rested on "it works in a disposable throwaway copy" — now correctly rests on empty-dir + refuse-to-overwrite. -->
  - [x] P1.4 Extend the scaffold smoke only if P1.1 changed the script; otherwise record that groups 5/6 already cover it  <!-- status: done — no extension needed: P1.1 changed nothing in the script, and the existing suite already pins both ruled behaviors (group 5 `--dest` fresh+independent+runnable copy; group 6 non-empty refusal writes nothing, + --force override). Group 8 (arm↔scaffold wiring contract) was the real regression risk from P1.2's invocation edit — it still PASSES. Suite: 15/15. -->
  - [x] verify-auto  <!-- status: done — scaffold smoke 15/15 PASS (incl. group 8 wiring contract, the pin most at risk from the invocation change). check-structure.sh 472 PASS / 1 FAIL, byte-identical to the pre-phase baseline: the single failure is the pre-existing settings-fixture drift (`effortLevel: live=<missing> fixture="xhigh"`), unrelated to this phase (no settings file touched). NO NEW FAILURE. -->
  - [x] Phase-1 grep observables  <!-- status: done — arm invocation carries `--dest` (L104); no bare `new-sample.sh` instruction remains; `empty` present 8× in the dispatcher Step-0 greenfield branch. -->
  - [x] verify-self  <!-- status: done — spawned feature-verify-self-runner (unconditional spawn per arch.md 2026-04-27; no dev URL — prose feature, outcomes are CLI/grep + coherence read). **8/8 PASS, 0 BLOCKING, 0 COSMETIC-fail.** Empirically confirmed: flat stamp into empty cwd (exit 0, no nested wrapper, `file ./todo` = script not dir), non-empty refusal (exit 1, names destination, recursive `find` before/after IDENTICAL = zero writes incl. no partial), flat copy runnable (byte-exact `1. [ ] buy milk` via `cat -e`), arm's sole fenced invocation carries `--dest`, dispatcher states the requirement + consequence. Both coherence reads PASS: (7) where-files-land story internally consistent across both files, old `cd`-into-printed-path fully removed, surviving "throwaway/disposable" wording is about expendability not location, downstream Step-3/Step-7 beats reinforce rather than contradict; refuse path reads as a calm rare backstop with actionable next step. (8) BOTH replay surfaces covered — arm entry section normalizes the guard firing on replay + forbids `--force`; Step-8 invite tells the user to start from a new empty folder. Two non-BLOCKING items surfaced outside the outcome set were fixed in-place under the §3 shortcut (all 3 gates met; fresh subagent re-verified 5/5) — see `[SHORTCUT-2026-07-25]` in `## Discoveries`. -->
  - [~] verify-human  <!-- status: DEFERRED-2026-07-25 — integration boundary APPLIES (prose changed inside two shipped, consumed skill prompts), so the F11 skip path is forbidden and the Mode-3 auto-skip gate fails at condition (c). NOT auto-skipped, NOT approved. Checklist was presented (6 leaves: 3 copy reads, 2 live-run checks, 1 informational shortcut note); operator elected to DEFER the copy judgment until ALL greenfield fixes are in place (WP7l + WP7n + WP7m), so the re-acceptance is ONE read over the finished arm rather than three partial ones. This is consistent with the pins-lock-accepted-copy sequencing rule and with the standing batch-acceptance pattern (SURFACE-2026-07-22-...-ACCEPTANCE-DEFERRED). Turn-level deferral of the gate — NOT a session handoff; no .session.md written. Phase 1 proceeds to verify-codify on verify-self evidence (8/8 PASS + fresh-subagent 5/5 re-verify). THE GATE IS OWED, NOT WAIVED — see `## Deferred human gate` below. -->
  - [x] verify-codify  <!-- status: done — INTEGRATION BOUNDARY APPLIES (prose changed inside two shipped, consumed skill prompts), so codify includes consuming-surface coverage, not just isolated-artifact checks. **Coverage assessment first (no duplication):** groups 5/6 already cover `--dest <nonexistent-nested-dir>` + non-empty refusal, so those were NOT re-written. Found TWO REAL GAPS: (a) nothing exercised `--dest .` executed from *inside* the target dir — the tour's actual new invocation form, and a distinct code path (`.` always exists so the "nonexistent dest" branch never fires; emptiness is judged on the cwd itself); (b) group 8's wiring pin did not assert the `--dest` invocation form, so a silent revert to the bare (temp-dir) invocation would have passed. **Added:** new group 9 (`--dest .` flat stamp into cwd + flat copy still runnable at the grounding observable + non-empty-cwd refusal with a full recursive `find` before/after tree comparison — the replay case) + one group-8 wiring assertion pinning `new-sample.sh --dest` in the arm. Suite 15 → **19 passed, 0 failed**. **MUTATION-VERIFIED (a passing test proves nothing until it can fail):** removing `--dest` from the arm's invocation → the new wiring pin FAILS with the WP7l-regression message (18/1); making the scaffolder nest into `dest/todo/` → the flat-stamp + runnable assertions FAIL (15/4). Both mutations reverted; `new-sample.sh` git-confirmed unmodified. check-structure.sh 472 PASS / 1 pre-existing settings-fixture FAIL (unchanged baseline). No test failed → no §3b triage artifact required. **Scope discipline:** stayed inside group 8's stated charter (wiring contract + CLI behavior); the tour's behavioral scenarios + `tutorial-`-prefix/invariant structural pins remain WP7e's job and must freeze against operator-ACCEPTED copy — deliberately not pulled forward, especially since verify-human is deferred here. -->

- [ ] Phase 2: WP7n — Step-8 close restructure + WP7l cleanup-offer merge  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - CLI: `grep -n 'Next Step' skills/tutorial-greenfield-workflow-tour/SKILL.md` matches inside Step 8, and the match's line number is greater than the line numbers of the graduation-reveal, replay-invitation, "didn't demo", and deep-dive-pointer blocks (decision block is LAST)
  - CLI: the greenfield close still contains all shipped beats — `grep` finds "Not recommended yet", the direct-arm-re-entry mechanic (`tutorial-greenfield-workflow-tour` named in the replay invite), the session-boundary `/exit` framing, the arm's own mode-menu mechanic, and `/tutorial-product-cycle-tour` (re-ordering preserved content, nothing cut)
  - CLI: both Branch A and Branch B carry their own `Next Step:` block, and Branch B's does NOT re-offer a replay (`grep` Branch B region for the replay-invite phrasing → absent)
  - CLI: the cleanup offer appears in the close AFTER the artifacts-as-proof list (line number of the cleanup-offer text > line number of the artifacts list)
  - CLI: brownfield arm — same assertions for `Next Step:` present and last within its Step 8 (its close is 118 lines with the same two-branch shape)
  - CLI: `./tests/check-structure.sh` shows no NEW failure vs. the 2026-07-25 baseline
  - [x] P2.1 Greenfield Step 8: move narrative above; add a terse per-branch `Next Step:` block last (each option ≤3 sentences), Branch A vs Branch B differentiated  <!-- status: done — new order: graduation reveal (Branch A) / acknowledge-the-gear (Branch B) → replay MOTIVATION compressed to one line → "what we didn't demo" → **artifacts-as-proof** → `Next Step:` LAST. Branch A block = 3 options (replay in a faster gear / point it at your own code / go deep on the planning layer) + cleanup offer; Branch B = 2 options (no replay option — they're already in one) + cleanup offer. Added a "Mechanics that must stay correct in the block" note so compression can't silently break the replay/deep-dive constraints. Also swept 3 now-stale internal pointers the restructure created ("extend the replay invitation below" ×1 greenfield, the Branch-B "skip straight to" routing line, and the tail commentary that named the deep-dive pointer as the last thing). -->
  - [x] P2.2 Verify no shipped beat was lost in the re-order (explicit checklist against the pre-edit content, incl. the replay invitation's 3 mechanics)  <!-- status: done — checked against the B1–B17 baseline inventory captured BEFORE editing (see `## P2.2 baseline` below). 17/17 beats present + 3 new (Next Step block, cleanup offer, offer-not-action guard). One apparent MISS (B7 replay invitation) was a GREP ARTIFACT, not a lost beat — my pattern assumed unwrapped literal wording; the invitation is present at L357-368 in compressed form (verified by reading, per the verify-grep-blind-spots order-of-trust: coherence read > wrap-tolerant grep > literal grep). Machine-verified ordering in BOTH arms: graduation < didn't-demo < artifacts < Next-Step (ORDER ok: True). -->
  - [x] P2.3 Merge WP7l's offer-to-clean-up into the restructured tail so the close reads as one coherent ending, ordered after the artifacts-as-proof lines  <!-- status: done — the cleanup offer is the last line INSIDE the `Next Step:` block (both greenfield branches), i.e. after the artifacts-as-proof list, with an explicit "it is an offer, not an action" guard: ask, never delete unless the user says yes, and on decline/no-answer leave everything in place (the files are the proof just shown, and the user chose the directory). Greenfield only — brownfield deliberately has NO cleanup offer (real repo, nothing disposable; `git stash`/`restore` is the user's own undo path). -->
  - [x] P2.4 Brownfield arm: apply the same restructure (burial confirmed — 118-line close, two-branch); full-cycle tour: verify-then-decide (54-line close, no replay/graduation — light check, edit only if the burial actually exists)  <!-- status: done — BROWNFIELD: burial confirmed by reading (same beat order, same mid-close full replay invitation), so the same restructure applied, with its own mechanics: option 1 = replay with **clean-baseline-first** (`git stash`/`git restore .` — why the Step-0 git-safety pre-flight is load-bearing), option 2 = "just start working" via `/session-start`; Branch B = 1 option. Explicit guards added that this arm has **no cleanup offer** and **no deep-dive pointer** (the latter pairs with greenfield's hierarchy taste per WP7k). FULL-CYCLE: **verified and deliberately NOT changed** — its close is already 3 explicitly-numbered beats in a stated order (~30 lines) with the actionable "point at real work" beat in plain sight; there is no burial to fix, and adding a `Next Step:` block would be uniformity-for-its-own-sake AND would rub against its ratified no-replay/no-mode-menu invariant. Verify-per-file honored; symmetry NOT assumed. -->
  - [x] P2.5 Reflect into `onboarding-flow-spec.md` (§3 greenfield env + close shape, §8 build constraints) and `full-product-cycle-tour-design.md` only if its close changed  <!-- status: done — added `## Revision 2026-07-25 (WP7l + WP7n — post-acceptance greenfield corrections)` to `onboarding-flow-spec.md` (frontmatter `updated:` bumped to 2026-07-25), following the doc's existing revision-log convention: WP7l (cwd landing + empty-cwd requirement + replay-guard note + "new-sample.sh itself NOT changed"), WP7n (close restructure + compressed-not-dropped mechanics + cleanup-offer placement), the deliberate full-cycle NON-change with its rationale, and the still-owed deferred verify-human + the open refuse-vs-subdir design question gating WP7e. `full-product-cycle-tour-design.md` deliberately NOT touched — its close did not change. -->
  - [x] verify-auto  <!-- status: done — scoped checks on the 3 changed prose files: YAML frontmatter parses (all 3), path-qualification mandate clean (no bare `.claude/`), **the operator's ≤3-sentence constraint verified 8/8 options across both arms**, cleanup-offer placement correct (greenfield 2 branches / brownfield 0 — by design), honest-framing `~30–45 min` label survives the compression (3×), full-cycle tour + its design doc git-confirmed untouched. NOTE: first sentence-count run FALSELY flagged 2 greenfield options as 5/4 sentences — the counter was folding the separate trailing italic `Housekeeping:` line into the preceding option; reading the copy showed 3 and 2. Re-ran with proper delimiting → 8/8. (4th mechanical false-signal on prose this feature — relevant to WP7e: a naive sentence-count pin on this block would be flaky.) -->
  - [x] verify-self  <!-- status: done — spawned feature-verify-self-runner (integration boundary APPLIES: prose changed inside two shipped, consumed skill prompts; both consuming surfaces cited by name). **10/10 PASS, 0 BLOCKING, 0 COSMETIC — no in-place shortcut needed.** Machine-verified strict ordering in BOTH arms (greenfield 326<367<380<388<409<427; brownfield 234<277<291<302<315<328) → `Next Step:` is LAST. **Zero blockquoted user-facing copy follows either block** (only authoring commentary) — the block is genuinely terminal. **Beat preservation: all 13 greenfield beats + all brownfield analogues survive with line cites — re-order, not a cut.** Brownfield's distinct clean-baseline mechanic present in all 4 required places and tied to the Step-0 git-safety pre-flight twice; brownfield correctly has NO cleanup offer (affirmatively forbidden) and NO deep-dive pointer (affirmatively forbidden). Branch B carries no replay option in either arm. Coherence read PASS on all four sub-questions: closes end in a clean unburied decision; **no stale internal pointers** (every "(below)" resolves forward; the subagent independently checked brownfield L65's "see Step 8's replay invite" cross-reference still resolves); the "I'll put the how at the end" promise IS discharged by option 1 in both arms; cleanup offer lands after artifacts-as-proof (L422 vs L388) with the rule stated explicitly. Regression: scaffold 19/19, check-structure 472/1 (the one FAIL is exactly the pre-existing settings-fixture drift, confirmed not new). -->
  - [~] verify-human  <!-- status: DEFERRED-2026-07-25 — same operator ruling as Phase 1 ("defer to when all the fixes are in place"). Integration boundary APPLIES → F11-skip forbidden, Mode-3 auto-skip gate correctly does NOT fire. The copy judgment for BOTH phases is folded into ONE greenfield-arm re-acceptance read after WP7m lands. OWED, NOT WAIVED — checklist in `## Deferred human gate`. Phase proceeds to verify-codify on verify-self evidence (10/10 PASS). -->
  - [x] verify-codify  <!-- status: done — **NO new tests written, deliberately, with the gap MEASURED and recorded (not assumed).** Coverage assessment: Phase 2's deliverable is *tour structure* (close ordering / beat survival), and `grep -c tutorial tests/check-structure.sh` = 0 → the family has no structural pins at all. I empirically proved the gap rather than reasoning about it: **deleting BOTH `Next Step:` blocks outright still passed the scaffold suite (19/19) AND check-structure.sh (472/1, unchanged)**; file restored clean (2 blocks back, git-verified). Three reasons not to pin it here: (1) the scaffold suite's group-8 comment states its own boundary verbatim ("pins the consuming-surface wiring only; the tour's behavioral scenarios + structural pins are WP7e's job — deliberately NOT duplicated here") and close-ordering is tour structure, not scaffold wiring; (2) **verify-human is DEFERRED**, so pinning now would freeze un-accepted copy — the exact inversion of the pins-lock-accepted-copy rule this whole M11 tail is sequenced around; (3) WP7e would rewrite them. Contrast with Phase 1, where coverage WAS added in-feature (group 9 + a group-8 `--dest` assertion, both mutation-verified) because that change genuinely WAS scaffold wiring — the boundary was applied, not used as a dodge. Gap logged twice so it cannot die with this WIP: `[SURFACED-2026-07-25]` in `## Discoveries` + durable `SURFACE-2026-07-25-WP7N-CLOSE-STRUCTURE-UNPINNED` in `workflow-system/state/backlog.md`, both carrying the concrete pin list AND the flaky-sentence-counter caveat. Full suites green: scaffold 19/19, check-structure 472 PASS / 1 pre-existing settings-fixture FAIL (not new). No test failed → no §3b triage artifact required. -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** finalize (ship `783bdf2` complete; review-quality complete — 0C/2MAJ-fixed-in-feature/5MIN-backlogged)
- **Blocked:** none
- **Unvisited:** ship → review-quality → finalize; then — outside this feature — **WP7m**, after which the DEFERRED verify-human acceptance is re-presented across all three greenfield fixes at once, then **WP7e** codifies pins against the accepted copy
- **Phase parents deliberately NOT `[x]`:** both Phase 1 and Phase 2 retain `[ ]` because their `verify-human` leaves are `[~]` DEFERRED, not `[x]`. This is correct under the all-children-`[x]` rule and is the tree honestly representing an owed gate — do NOT "tidy" them to `[x]` at ship/finalize. They close when the operator's re-acceptance lands.
- **Open discoveries:** 3 entries — one `[SHORTCUT-2026-07-25]` (Phase 1 in-place fixes, fresh-subagent re-verified), one leaf-substitution defect (found + fixed at exit-time parent scan), one **measured coverage gap** on the WP7n close structure (WP7e's charter; also logged durably as `SURFACE-2026-07-25-WP7N-CLOSE-STRUCTURE-UNPINNED`). Plus one **OPEN DESIGN QUESTION** owed an answer before WP7e freezes — see `## Deferred human gate`.

## Deferred human gate (owed, not waived) — operator ruling 2026-07-25

The operator deferred the **verify-human copy judgment** for BOTH phases until **all three greenfield
fixes are in place** (WP7l = this feature's Phase 1, WP7n = Phase 2, **WP7m = the separate follow-on
WP**), so the re-acceptance is a single read over the finished greenfield arm. Phases proceed to
verify-codify on verify-self evidence; the gate is **owed**.

**What is owed, concretely** — the checklist presented at the Phase-1 gate, to be re-presented (merged
with Phase 2's) once WP7m lands:
1. `tutorial-getting-started` Step-0 greenfield branch — does the empty-dir *requirement* read firm
   without reading bureaucratic?
2. Arm "## The environment" refuse-and-explain copy — does it read as a **calm, rare backstop** with an
   obvious next step, rather than an error/wall? *(the operator's own flagged risk)*
3. Arm upfront framing — does "right here in the folder you're standing in" deliver the improvement the
   operator asked for (know where the files are, no path to memorize)?
4. Live run in an empty dir → flat stamp + runnable (`1. [ ] buy milk`).
5. Live re-run in the now-non-empty dir → is the scaffolder's raw refusal message
   (`destination '.' exists and is not empty (use --force to overwrite)`) **good enough to hand a
   brand-new user**, or should the arm's copy do more of the explaining?
6. (informational) the `[SHORTCUT-2026-07-25]` in-place fixes.

**Minor observation from the Phase-2 verify-self subagent (informational, no action taken).** It
independently agreed that leaving the **full product-cycle tour's** close unchanged is defensible (three
short numbered beats, <30 lines, no multi-option decision to bury, and the actionable "point at real
work" beat is in plain sight), but noted one honest caveat: in that tour the actionable beat is **#2 of
3, not last**, so the literal "the decision is the last thing on screen" property does not hold there —
it holds only in the two arms. Its judgment, which I share: adding a `Next Step:` block to a three-beat
close with no options to choose between would be ceremony, and it would rub against that tour's ratified
no-replay/no-mode-menu invariant. Recorded here so the operator can overrule at the deferred acceptance
if they want strict cross-family symmetry; **no change made.**

**OPEN DESIGN QUESTION flagged to the operator at the gate, still unanswered — resolve at the deferred
acceptance, BEFORE WP7e freezes pins.** The ruling was "always flat, refuse if non-empty". Implemented
faithfully, but: **on a replay the guard fires every time** (the user stands in their previous run's
dir). Mitigated in copy (arm entry normalizes it; Step-8 invite pre-empts it by sending them to a new
empty folder), so it should not bite — but the "rare backstop" is genuinely rare only on *first* runs.
If the operator dislikes that on reading items 2/5, the passed-over alternative — **ask + offer a
`./onboarding-sample-todo/` subdir fallback** — remains a one-WP change and is cheap *now*, expensive
after WP7e pins this copy. Do not let WP7e freeze without an explicit answer here.

## P2.2 baseline — beat inventory of the pre-restructure close (captured BEFORE editing)

Recorded at P2.1 start so the no-loss check is verifiable, not asserted. Greenfield Step 8 pre-edit =
lines 314–425. Every item below must still be present (possibly relocated/compressed) after P2.1:

| # | Beat | Branch | Pre-edit anchor |
|---|---|---|---|
| B1 | Mode-aware branch instruction ("deliver exactly one") | both | 316-317 |
| B2 | Graduation reveal — "that pause is a setting, not a law", autopilot + FSD named | A | 325-328 |
| B3 | **Un-push — "Not recommended yet."** | A | 332-334 |
| B4 | No-live-demo guard (don't demonstrate autopilot/FSD here) | A | 336-338 |
| B5 | Replay acknowledge-the-gear copy (+ autopilot/FSD conditional halves) | B | 346-351 |
| B6 | Branch-B explicitly NO un-push / NO replay invite | B | 342-343, 353-355 |
| B7 | Replay invitation (the highlighted ▶ block) | A | 364-376 |
| B8 | Replay mechanic 1 — re-enter at the ARM skill directly, NOT the dispatcher | A | 380-382 |
| B9 | Replay mechanic 2 — session-boundary crossing (`/exit` → new session) | A | 383-385 |
| B10 | Replay mechanic 3 — gear from the arm's own on-entry menu; human never runs the scaffolder | A | 385-388 |
| B11 | **Empty-folder instruction for the replay** (added by P1.2 — load-bearing, see below) | A | 370-372 |
| B12 | "What we didn't demo" — hierarchy + it-learns-you, NAMED not staged | both | 390-399 |
| B13 | "That's the tour… go build something real" + point-at-your-own-repo | both | 400-401 |
| B14 | Deep-dive pointer `/tutorial-product-cycle-tour` + ~30–45 min + run-directly | both | 403-413 |
| B15 | Deep-dive mechanics guard (named-not-demo; NOT via getting-started; holds on replay) | both | 415-419 |
| B16 | Beat-G reinforcement + "the tour ends here", no transition to emit | both | 421-425 |
| B17 | Artifacts-as-proof list (the files-you-own evidence) | both | see note |

**B17 note:** the artifacts list the operator saw in the live close ("workflow-system/state/archive/…,
backlog.md, CHANGELOG.md, tests/…") is *generated at runtime* from the actual run — the SKILL.md
prescribes it via B13's "it's all sitting in files you own" rather than hardcoding paths. P2.3's
cleanup offer must land **after** that runtime list, so the ordering constraint is expressed in the
prose instruction, not by pinning literal paths.

## Note for Phase 2 (P2.1/P2.3 — carried forward from P1.2)

P1.2 made a **minimal correctness fix** to the Step-8 replay invitation (added "start the replay from a
new empty folder", without which every replay hits the empty-cwd guard unwarned). That block is inside
the region P2.1 restructures — so P2.1 must **preserve that empty-folder instruction** when it rewrites
the close, and P2.2's no-beat-lost checklist should include it. Presentation of it is P2.1's call; the
*instruction* is load-bearing and must survive.

## Scope guards (carried from the WBS)

- **No transition / state-machine change.** Both WPs are prose + (possibly) a small shell guard. The
  `tutorial-*` family emits no transitions; adding one would contradict the family invariant.
- **WP7m is NOT in this feature.** The mid-tour handoff-offer guard is a separate WP, sequenced after
  this one. If Phase 2 work makes the tour-vs-state-machine boundary confusion worse or tempting to
  fix inline, SURFACE it — do not absorb it.
- **Pins are WP7e's charter, not this feature's.** Codify here means the scaffold smoke + no-new-
  failure on `check-structure.sh`; the `tutorial-`-prefix and invariant pins freeze in WP7e against
  operator-accepted copy. This feature's output must be **re-accepted by the operator** (greenfield
  arm only) before WP7e freezes.
- **Authoritative docs before editing any `tutorial-*` skill:**
  `docs/lessons/tutorial-tour-session-chain-flow.md` (family flow — getting-started NEVER dispatches
  the arm inline), `workflow-system/product/onboarding-flow-spec.md` (family invariants),
  `workflow-system/product/full-product-cycle-tour-design.md` (WP7k design contract).
- **Honest-framing invariant holds:** no "5-min" claim anywhere; greenfield stays ~10–15 min,
  full-cycle stays ~30–45 min.
- **Path-qualification mandate:** every `.claude/` reference in prompt prose stays explicitly
  qualified (`~/.claude/` or `<proj-dir>/.claude/`); bare `.claude/` is forbidden and pinned by
  `check-structure.sh` Phase 12.
- **Verify greps have blind spots on prose observables** — the coherence read is the gate
  (`docs/lessons/verify-grep-blind-spots.md`). Order of trust: coherence read > wrap/bold-tolerant
  grep > literal grep. When a grep "fails" on prose, suspect the grep before the copy.

## Retrospect

- **What changed in our understanding:** Two of the three "fixes" turned out to be *different kinds of
  thing* than the WP text implied, and both only surfaced because they were checked against the code
  first. (a) WP7l read like a scaffolder change; it was **purely an arm-invocation change** —
  `new-sample.sh` already implemented `--dest` + the no-clobber guard, so the shipped dispatcher copy
  had been *promising* the correct behavior all along while the arm quietly did something else. The bug
  was a **copy/behavior divergence**, not a missing capability. (b) WP7m (planned separately) looked like
  copy but is a **real state-machine gap** — `S22` is modeled AUTO in all four drive modes and neither
  `session-reflect` nor `session-handoff` has any tour-awareness, so mid-tour the in-tour feature's close
  *correctly* presents as a clean boundary. The agent's hedge-and-ask in the operator's live run was a
  reasonable read of a genuine ambiguity, not a misbehavior.
- **Assumptions that held:** Building WP7l and WP7n as one feature was right — they both edit the arm's
  close, and 7n.3's merge-ownership prevented two conflicting edits. The verify-before-edit discipline
  paid for itself twice. The pins-lock-accepted-copy sequencing held: refusing to write close-structure
  pins while verify-human was deferred avoided cementing copy the operator hasn't read.
- **Assumptions that were wrong:**
  1. **"Mutation-verified" ≠ "verifies the right thing."** I mutation-tested group 9's runnable assertion
     and it failed-on-mutation, which felt like proof. The reviewer showed it was proof the assertion
     *could* fail — not that it tested the path the tour uses. It overrode `TODO_STORE` to an external
     temp file while the tour's Step-5 beat runs bare `./todo add … && ./todo list` against the stamped
     `./todos.txt`. **The lesson: mutation-testing validates sensitivity, not relevance.**
  2. **A revision header can lie without anyone noticing.** I wrote "§3 both arms, §7 rows" in the spec
     revision and never edited those rows — the beat tables kept describing the superseded close. Worst
     possible location, since WP7e is chartered to pin against exactly those tables. Caught only by the
     reviewer.
  3. **Grep-on-prose was wrong four separate times** (en-dash/bold/wrap/blockquote, plus a sentence
     counter folding a trailing italic line into the preceding option). Every single time the copy was
     correct and the check was wrong. `verify-grep-blind-spots.md` predicted this; the frequency across
     one feature is the new datum.
  4. **A documented lesson does not prevent its own recurrence.** The Work-Tree leaf-substitution defect
     (inserting a new status line above the old one instead of substituting) hit twice in this feature
     despite `docs/lessons/work-tree-leaf-substitution.md` existing — orphaned verify leaves that would
     have made Phase 1 un-closeable, and a duplicate `Open discoveries:` field. Long autopilot runs with
     many sequential WIP edits reproduce it easily.
- **Approach delta:** Plan said 2 phases / 10 tasks; delivered exactly that. Three deltas, all
  discipline-driven rather than scope drift: (1) task 7l.4's "adjust the script" half became a verified
  **no-op** instead of an edit; (2) **no close-structure tests were written** — a documented charter
  boundary plus the deferred gate made pinning wrong here, so the gap was *measured* (deleting both
  `Next Step:` blocks still passes everything) and logged with a concrete pin list rather than papered
  over; (3) both review MAJORs were **fixed in-feature instead of auto-backlogged** — Mode 3's default is
  backlog, but both corrupted the artifact WP7e pins against, so deferring them would have guaranteed
  WP7e pins the wrong shape. The full-cycle tour was also verified-then-left-alone rather than edited for
  symmetry.

## Code-Quality Review — greenfield-tour-cwd-sample-and-close-restructure (WP7l + WP7n)

Reviewer: `code-quality-reviewer` subagent, ship commit `783bdf2` (single-commit feature; window
`783bdf2^..783bdf2`). Counts: **0 CRITICAL / 2 MAJOR / 5 MINOR** → Case B, `drive_mode: autopilot`
(Mode 3) → auto-backlog + prominent chat surface → `TRANSITION: F39`.

### Strengths (reviewer's words, condensed)
- Verify-before-edit was **honored, not claimed** — `new-sample.sh` git-confirmed unchanged because the
  `--dest`/no-clobber surface already existed.
- The coverage gap was **measured, not assumed** (deleting both `Next Step:` blocks and re-running both
  suites to *prove* zero coverage) — "a materially better artifact than 'codify deferred to WP7e'."
- Both new test pins mutation-verified, and the group-9 refusal assertion is **non-vacuous by
  construction** (if the first stamp fails, `$C` stays empty and the second invocation legitimately
  succeeds → the `bad` branch fires; it degrades loudly, not silently).
- Group 9 pins a **genuinely distinct code path** rather than duplicating groups 5/6.
- The brownfield asymmetries are **prohibitions, not omissions** — a future editor "restoring symmetry"
  has to override an explicit rule.

### Issues

**CRITICAL** — none.

**MAJOR — both VERIFIED against the code and FIXED IN-FEATURE (not backlogged).** Mode 3's default is
auto-backlog, but both findings corrupt the artifact **WP7e is chartered to pin against**, so deferring
them would have guaranteed WP7e pins the wrong shape. Fixing was cheap and immediate:

1. **[`onboarding-flow-spec.md`] The WP7n revision header claimed `§3 both arms, §7 rows` — but those
   rows were never edited**, so the spec's step-8 beat tables still described the *superseded* close
   (mid-close replay invitation, no `Next Step:` block, no artifacts-as-proof, no cleanup offer). My
   error, and the worst possible place for it: WP7e pins against those tables. **FIXED** — greenfield
   row 8, brownfield row 8, and the `§7` replay-invitation row all resynced with explicit
   `REVISED 2026-07-25 (WP7n)` clauses recording the narrative-first/decision-last order, the
   compressed-not-dropped mechanics, the cleanup-offer placement, and the brownfield prohibitions.
2. **[`scripts/test/run-tests.sh` group 9] The runnable assertion overrode `TODO_STORE` to an external
   temp file**, so it never exercised the flat-stamped `./todos.txt` — which is exactly the store the
   tour's Step-5 grounding beat uses (it runs bare `./todo add … && ./todo list`, no override). The
   assertion claimed "the grounding observable still holds from the cwd" while testing a path the tour
   never uses; a `SCRIPT_DIR`-resolution or stamped-file-permission regression would have sailed
   through. Isolation bought nothing here since `$C` is already a `mktemp -d`. **FIXED** — override
   dropped (with a comment explaining why groups 1–3 need it and group 9 must not), plus a new
   assertion that the flat-stamped `./todos.txt` **is** the store written. **Mutation-verified:**
   pointing the dispatcher's default store away from `SCRIPT_DIR` now fails it. Suite **19 → 20**.

**MINOR — 5, all auto-backlogged** (Mode 3) to
`workflow-system/state/backlog-quality-findings.md` → `# greenfield-tour-cwd-sample-and-close-restructure — 2026-07-25`,
with a single pointer entry in `workflow-system/state/backlog.md`:
1. `Next Step:` block-membership rule is ambiguous about the `Housekeeping:` cleanup offer (the *same*
   ambiguity that made a sentence-counter falsely report 5/4 where truth was 3/2 — it will break a naive
   WP7e pin the same way).
2. The mechanics note says mechanics are "spelled out above," but compression inverted that pointer.
3. Greenfield Branch A option 1 says "`/exit`, `mkdir` … `cd`" — commands after `/exit` can't run in the
   session being read; brownfield sequences it correctly.
4. The git-safety rationale's new clause is self-contradictory as phrased ("in an **empty** directory it
   refuses to write into if anything is already there").
5. Duplicate `- **Open discoveries:**` line in this WIP's `## Current Node` — **fixed at review time**
   (retained in the backlog only as a data point that the WIP-edit failure mode recurred twice here).

Four of the five are **user-facing tour copy**, so they should be settled inside WP7e's copy-freeze
*before* pins lock — and two of them (#1, #4) directly affect the DEFERRED verify-human read still owed.

### Assessment (reviewer, verbatim conclusion)
> "This is careful, well-disciplined work on the axes this repo cares most about. The verification story
> is the standout: mutation-verified pins, a measured-not-assumed coverage gap, the correct refusal to
> pin un-accepted copy, and an honest `[~] DEFERRED` leaf with parent checkboxes deliberately left open
> rather than tidied — the WIP is more trustworthy than most shipped ones here. … The debt this accrues
> is concentrated in one place: the spec's beat tables were not resynced despite the revision header
> claiming they were, which matters more than usual because WP7e is chartered to pin against exactly
> those tables."

The reviewer was right on both MAJORs; both are now fixed, so the concentrated debt it named is closed.

### If you disagree
Dismiss any finding by editing this section and marking the line `[DISMISSED]` before
`feature-finalize` archives this WIP.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->

[SURFACED-2026-07-25] Phase 2 verify-codify — **Work-Tree leaf-substitution defect in MY OWN edit, caught
by the parent-completion scan and fixed.** When marking Phase 1's `verify-self` and `verify-human` leaves,
I *inserted* new status lines above the originals instead of substituting in place, leaving two orphaned
`- [ ] verify-self` / `- [ ] verify-human  <!-- status: NOT-STARTED -->` duplicates at Phase 1. Under the
all-children-`[x]` rule those orphans would have made **Phase 1 permanently un-closeable**, and a later
reader would have seen contradictory statuses for the same leaf. This is a textbook recurrence of
`docs/lessons/work-tree-leaf-substitution.md` ("substitute the existing line in place — never append a new
`[x]` above the existing NOT-STARTED line"), which this repo already documents — the lesson exists and I
still hit it, which is itself the signal that the failure mode is easy to reproduce under long
autopilot runs with many sequential WIP edits. Fixed: orphans deleted, leaf order restored to the canonical
`verify-auto → verify-self → verify-human → verify-codify`. Both phase parents correctly remain `[ ]`
because the deferred `[~] verify-human` is legitimately not `[x]`. **No process change proposed** — the
lesson is already written; this entry is the audit trail that the exit-time parent-completion scan is what
caught it, i.e. the existing guard worked.

[SURFACED-2026-07-25] Phase 2 verify-codify — **MEASURED coverage gap on the WP7n close structure; WP7e's
charter, recorded so it cannot be silently dropped.** Phase 2's deliverable is *tour structure* (the
`Next Step:` block being last, per-branch, ≤3 sentences/option, with all beats surviving the re-order).
I empirically confirmed nothing currently guards it: **deleting BOTH `Next Step:` blocks outright — total
loss of WP7n's deliverable — still passes the scaffold suite (19/19) AND `check-structure.sh` (472/1,
unchanged).** `grep -c tutorial tests/check-structure.sh` = **0**, so the tour has no structural pins at
all yet. I deliberately did NOT add them here, for three reasons: (1) the scaffold suite's group-8 comment
states its own boundary verbatim — *"This pins the consuming-surface wiring only; the tour's behavioral
scenarios + structural pins are WP7e's job — deliberately NOT duplicated here"* — and close-ordering is
tour structure, not scaffold wiring; (2) **verify-human is DEFERRED**, so any pin written now would freeze
copy the operator has not accepted — the exact inversion of the load-bearing pins-lock-*accepted*-copy
rule; (3) WP7e would rewrite them. **What WP7e must pin (concrete, carried forward):** `Next Step:`
present and LAST in both arms (line-order assertion, the shape verify-self used); per-branch blocks with
Branch B carrying NO replay option; the ≤3-sentence-per-option constraint; beat survival (the 13-beat
greenfield list + brownfield analogues, incl. the replay invitation's 4 mechanics); greenfield-only
cleanup offer placed AFTER the artifacts-as-proof; brownfield having NO cleanup offer and NO deep-dive
pointer. **Pin-authoring caveat:** a naive sentence-count check on this block IS FLAKY — it folds the
trailing italic `Housekeeping:` line into the preceding option (bit me at Phase-2 verify-auto; false 5/4
where truth was 3/2). Delimit on the `Housekeeping:` line, or assert per-option line spans instead.

[SHORTCUT-2026-07-25] P1.2 — Applied the verify-self in-place fix shortcut for two non-BLOCKING
coherence items the Phase-1 verify-self subagent surfaced outside its outcome set (it returned 8/8 PASS
and did not fail them, but both were real). **(a)** `scripts/README.md` "## Canonical invocations" listed
the bare temp-dir form FIRST and did not list the tour's `--dest .` form at all, while the arm skill
points readers to that file for "canonical invocations" — so an agent following the pointer saw the
non-tour invocation lead. Fixed: `--dest .` now leads and is labeled as what the arm runs; the temp-dir
form is retained but marked ad-hoc/manual-and-NOT-the-tour's-form; `--force` is marked as something the
tour must never do; and a WP7l rationale note was added (why cwd-not-temp + the empty-cwd/no-`--force`
contract) with a cross-pointer to the arm's "## The environment" section. **(b)** A 21-char orphan wrap
line ("Two properties of the") left by my own insertion in the arm SKILL.md — re-wrapped to one
102-char line, in-band with the file's ~100-char neighbors. **Gate check:** (1) trivial — both are
one-line consequences of P1.2's own edit, no redesign, no new abstraction; (2) fresh model invocation
re-verified — a NEW `feature-verify-self-runner` subagent (not a self-re-read) returned **5/5 PASS**
incl. a three-file consistency coherence read and the 15/15 scaffold regression with group 8 (arm↔scaffold
wiring) green and `new-sample.sh` git-confirmed unmodified; (3) this entry is the audit trail. That fresh
pass surfaced one further residual of the same class — `scripts/README.md:21`'s location-bearing layout
comment still read "into a throwaway dir" — which was then also corrected to name the tour's `--dest .`
form. No F9b back-loop was taken because no BLOCKING outcome failed at any point.
