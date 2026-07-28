# Backlog

## Session Handoff — 2026-07-28 19:26
Handed off at a clean boundary (no active WIP). See `workflow-system/state/.session.md` to restore (`/session-restore`).

> **Cycle-boundary sweep — `/product-finalize`, 2026-07-28 (Claudesk Handoff Cycle, M7–M12).**
> Every open item was audited at the cycle close. **Nothing was resolved by this cycle that is not
> already deleted** — the cycle's own origin SURFACEs (doc-layout unify, standalone uninstall,
> pause ambiguity, research collision, onboarding design) were each resolved-and-deleted as their WP
> shipped, per delete-on-resolve, so their record lives in `CHANGELOG.md` alone. Every remaining item
> is therefore **deferred — carried to the next cycle**, not silently dropped.
> One audit correction worth reading: `SURFACE-2026-07-25-WP7N-CLOSE-STRUCTURE-UNPINNED` **names WP7e
> as its resolver but was NOT resolved by it** — `[Phase 19]` cites the SURFACE in a comment without
> ever pinning `Next Step:` present-and-LAST. It is annotated in place and carried forward.
> **⚠️ The standing debt load is now sizable** — **20 open SURFACEs** (18 at the cycle close; the
> `util-option-mockup` feature added the mockup-artifact hand-over and **resolved-and-deleted** it the
> same day, surfaced 3 new items of its own, and then **resolved-and-deleted** one of those — the stray
> self-symlink — leaving shape-unpinned and the WIP-template drive_mode gap open) + **14 code-quality
> clusters** here, and **31 finding bodies** in `backlog-quality-findings.md`. This is a clean
> cycle boundary, which is exactly the condition `/util-backlog-paydown` exists for. Running it is the
> **operator's call** — `product-finalize` records dispositions; it does not pay the debt down.

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention). **Code-quality findings** auto-backlogged by `feature-review-quality` are pointer-collapsed here — full content lives in `workflow/backlog-quality-findings.md`, grouped by source feature.

---

## TODO

## SURFACE-2026-07-28-UTIL-OPTION-MOCKUP-SHAPE-UNPINNED

- **Source:** feature:verify-codify (mockup-artifact-for-uiux-decisions, Phase 2)
- **Target level:** task
- **Type:** tech-debt (test coverage gap, deliberate)
- **Summary:** `tests/check-structure.sh` [Phase 20] pins `util-option-mockup`'s **host pointers** but NOT its **util-family shape** (`## Category` heading vs `debug-*`'s `## Category Context`; emits-no-transition as claim AND behavior; frontmatter carrying neither `skills:` nor `tools:`). [Phase 19] pins that shape for the four `tutorial-*` skills; `util-option-mockup`, `util-prune-claude-md`, and `util-backlog-paydown` are shape-unpinned.
- **Context:** Descoped deliberately, not forgotten. A sensitivity probe measured that deleting both host pointers left the suite fully green — so the pointers are the load-bearing artifact (an undiscoverable skill is inert) while the shape is comparatively safe (nothing breaks silently if a heading drifts; the skill just reads oddly). Pinning the shape first would have guarded the wrong thing.
- **Suggested action (hypothesis — verify before writing):** generalize [Phase 19]'s util-family shape block into a helper that takes a skill list, then feed it `tutorial-*` + the three `util-*` skills. Note `arch.md` records the `## Category` vs `## Category Context` divergence as **intentional** — the helper must not normalize it. Run `/test-assertion-review` first; [Phase 19b] exists because the no-transition anchor shipped green while matching 24 of 46 SKILL.md files.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-28-WIP-TEMPLATE-OMITS-DRIVE-MODE-FRONTMATTER

- **Source:** feature:verify-human (mockup-artifact-for-uiux-decisions, Phase 1)
- **Target level:** task
- **Type:** gap (two skills disagree about a file's shape)
- **Summary:** `feature-plan`'s WIP template (`skills/feature-plan/SKILL.md` §4) creates the WIP file with **no YAML frontmatter block at all** — it opens with `# Feature: <Name>` and uses `**Key:** value` lines. But `feature-verify-human`'s auto-skip gate (a) reads `drive_mode` **from YAML frontmatter**, and specifies: *"If frontmatter has no `drive_mode` field, treat as Mode 2 (orchestrated) and do NOT auto-skip."*
- **Context:** The operator selects a drive mode at `/session-start` (or `/session-restore`), but nothing writes it into the WIP file. Every feature therefore reaches verify-human with gate (a) failing, and **an operator who explicitly chose autopilot is silently downgraded to Mode 2** for the rest of the feature. Observed live 2026-07-28: operator selected `autopilot`, WIP had no frontmatter, the gate would have prompted for a manual skip-confirmation it was designed to elide. Worked around in-flight by hand-adding `drive_mode: autopilot`.
- **Why it is invisible:** the failure mode is *extra friction*, not an error. Nothing breaks; the workflow just quietly asks for confirmations the operator already opted out of. Easy to misread as "autopilot doesn't do much."
- **Suggested action (hypothesis — verify against the skills before writing):** have `feature-plan` §4 (and `feature-spec` §3, which creates the WIP on the complex path) stamp a YAML frontmatter block containing `drive_mode:` at file creation, sourced from the active session mode. Check whether `task-plan` / `incident-report` have the same split before fixing only the feature path. Consider a structural pin that the WIP template and the auto-skip gate agree on the field's location.
- **Priority:** medium (affects every feature in every project using this workflow system; degrades an operator-selected setting)
- **Status:** pending

## SURFACE-2026-07-27-VERIFY-SELF-RUNNER-MUTATED-WORKING-TREE
- **Source:** feature:verify-self (tour-state-survives-session-boundary / WP7o, Phase 4)
- **Target level:** task
- **Type:** gap (contract violation — observed once, self-reported, no data lost)
- **Priority:** medium
- **What happened:** a `feature-verify-self-runner` subagent, which is contractually **observe-only**, ran
  `git stash push` as an investigative probe. This briefly cleared the entire working tree — 14 modified + 5
  untracked paths, none of it committed. The subagent caught it immediately, ran `git stash pop`, restored
  everything verbatim, and **self-reported the violation** in its result block. The tree was independently
  verified intact afterwards (19 entries, 0 stashes).
- **Why it matters:** the near-miss was total. Had the pop failed, or had the agent not noticed, an entire
  uncommitted feature would have been sitting in a stash with no record of it in the parent's context. The
  runner's own agent definition establishes it as observe-only, but the **tool surface does not enforce it** —
  `Bash` is granted (correctly; it needs `curl`, `grep`, test runners), and nothing distinguishes a read probe
  from a destructive one.
- **Cheap fix direction:** add an explicit prohibition to `agents/feature-verify-self-runner/AGENTS.md` — no
  `git stash`/`checkout`/`reset`/`clean`, no writes of any kind; to compare against a hypothetical, pipe a
  string to the matcher (`echo "..." | grep -cE '...'`) rather than mutating a file. The same clause likely
  belongs in `agents/code-quality-reviewer/AGENTS.md`, which is also observe-only but *does* have `Bash`.
  Worth checking whether a structural pin can assert the prohibition text in both.
- **Note:** the parent skill (`feature-verify-self`) already tells the *orchestrator* the subagent is
  observe-only; the gap is that the instruction is not restated **inside the subagent's own definition**, which
  is the only prompt the subagent actually reads.

## SURFACE-2026-07-27-TOUR-MARKER-NOT-READ-WHEN-POINTER-DELETED
- **Source:** feature:verify-codify (tour-state-survives-session-boundary / WP7o, Phase 4 — found by the behavioral scenarios the operator asked for mid-session)
- **Target level:** feature (follow-up; may need `/feature-spec` if the cheap option below doesn't hold)
- **Type:** gap (measured — a defense-in-depth layer that does not bind)
- **Summary:** When `workflow-system/state/.session.md` is **absent**, a cold model does **not** consult the WIP frontmatter for a `tour:` field — so the tour-aware guards in `session-reflect` and `session-handoff` never fire. Measured, not inferred: `tests/scenarios/session.yaml::S33` emits `TRANSITION: S22` (the auto-chain the guard must suppress) and `::S34` emits `TRANSITION: S17` (a second `.session.md` actually written) against a fixture where only the WIP carries `tour:`. Both scenarios are **deliberately left FAILING** so the suite keeps reporting this.
- **Context:** The guards' condition is written pointer-first — *"If `workflow-system/state/.session.md` carries a `tour:` field (or the WIP for this run does …)"* — and a model that finds no pointer treats the whole condition as unmet and never opens the WIP. This matters because `/session-restore` **deletes** the pointer at its step 7 once consumed, so at any later in-tour boundary the WIP copy is the *only* surviving carrier. **Not ship-blocking:** these guards are defense-in-depth. WP7o's load-bearing fix is `resume_skill` → the arm, which makes Session C reload the arm so the *arm's* own prose governs that boundary — confirmed by `S31`/`S32` passing plus three independent fresh-subagent coherence reads. **Three prose fixes were already attempted and none bound a cold model:** Phase 2's shortcut widened both guards' lookups to name the WIP and `archive/` explicitly, and Phase 4 added a clause at `session-handoff` step 1 (the point where the skill actually opens the WIP) stating that a missing pointer is not evidence no tour is running. At three attempts the *approach* is wrong rather than the wording — the same conclusion that ended this feature's five-attempt `--force` pin.
- **Suggested action:** Prefer the **restore-side** angle, which nobody has costed yet and which needs no state-machine surface: instead of asking every downstream reader to remember a second lookup location, have `/session-restore` **not lose the marker when it consumes the pointer** (e.g. it already edits `state_file` at step 6b — it could carry the tour fields into the WIP frontmatter there, or defer deleting the pointer while `tour:` is present and `tour_step` is unfinished). That keeps the trigger in **one** place the readers already check. **Explicitly NOT recommended:** making the general session skills mechanically consult WIP frontmatter via an orchestrator-evaluated precondition — that is state-machine surface, and WP7o deliberately held an empty diff on `transitions.md` + all four `agents/*/AGENTS.md` across four phases with the escalation clause re-checked each time. Reopening it to harden a layer redundant with a working primary mechanism inverts the feature's cost-benefit, and would make WP7e freeze pins against a design the operator has not seen run. Also **do NOT** soften `S33`/`S34` to make the suite green — that deletes the evidence, the exact failure mode this feature hit twice with inert pins.
- **Priority:** medium
- **Status:** pending

## Code-quality findings — mockup-artifact-for-uiux-decisions (2026-07-28)
- **Pointer:** 3 MINOR findings (0 CRITICAL / 2 MAJOR / 3 MINOR) from `feature-review-quality` on ship `6dcd525`. **Both MAJORs were FIXED IN-FEATURE** (see below); only the 3 MINORs remain: (1) `docs/reference/` exemplar is unlabeled and unlinked, so it becomes an orphan once the WIP is archived; (2) mixed `grep -c` BRE / `grep -cE` ERE inside one function; (3) `check_pointer()` reads `POINTER_TARGET` from enclosing scope. Full bodies: [`workflow-system/state/backlog-quality-findings.md`](backlog-quality-findings.md) → `# mockup-artifact-for-uiux-decisions — 2026-07-28`.
- **Both MAJORs were fixed in-feature, not backlogged** — MAJOR-1: `check_pointer()` guarded the section START heading but gave the END boundary **no precondition**, so renaming the end heading let `awk`'s `f` flag run to EOF and the section-scoped pin **silently degraded to a file-wide grep** — accepting the pointer-moved-out-of-section regression that the phase's own inline comment claims to catch. Independently reproduced before acting (pointer at EOF, pin PASSed). **The mutation sweep could not have caught it**: it mutated the pointer and the start heading, never the end boundary — sensitivity to the inputs you thought to mutate is not evidence about the ones you did not. MAJOR-2: nothing pinned the three statements of the trigger contract against each other, on a surface that had **already drifted once** during development. Both closed with +4 assertions (592→596 PASS).
- **Priority:** low (all 3)
- **Status:** pending
- **Pickup shape:** all three are small, independent hygiene edits with no ordering between them. (1) is the only one with real decay risk — it becomes an orphaned file the moment the WIP archives, so it is worth doing before the next cycle boundary; (2) and (3) are one-liners that can ride along with any future edit to `[Phase 20]`.

## Code-quality findings — tour-state-survives-session-boundary (2026-07-27)
- **Pointer:** 6 findings (1 CRITICAL / 3 MAJOR / 3 MINOR) from `feature-review-quality` on ship `ccfedac`. The **CRITICAL was FIXED IN-FEATURE via `/feature-refactor`** (see below); of the rest, the 3 MINORs and 3 MAJORs remain here. Full bodies: [`workflow-system/state/backlog-quality-findings.md`](backlog-quality-findings.md) → `# tour-state-survives-session-boundary — 2026-07-27`.
- **The CRITICAL was fixed in-feature, not backlogged** — `check-structure.sh` case (5) CASE-STABILITY read `arm_corpus` **outside the branch that assigns it**, so a rename of the tour arms would make `set -u` fire inside both `$( )` subshells, capture empty, evaluate `0 -eq 0`, and report **PASS while asserting nothing**. Independently reproduced before acting. This is the vacuous-negative-assertion class `CLAUDE.md:259` codifies — inside the very phase written to enforce anchor integrity, one commit after the convention landed. Deferring a pin that reports green while guarding nothing was not viable.
- **Priority:** medium (3 MAJOR) / low (3 MINOR)
- **Status:** pending
- **Pickup shape:** ⚠️ **PARTIALLY RESOLVED 2026-07-27 by WP7e** — the two MAJORs that edited the five prompt files WP7e was chartered to freeze (`TOUR-STEP-FIELD-HAS-NO-READER`, `TOUR-SCHEMA-HAS-NO-CANONICAL-DEFINITION`) are **RESOLVED and deleted** (see CHANGELOG 2026-07-27). **Remaining open:** the third MAJOR (`RUNTIMES-FRONTMATTER-NOT-A-BARE-DATE`, a one-line independent fix) and the MINORs, all low-stakes hygiene; `PHASE-18B-SUBLETTERED` is worth settling whenever the phase inventory is next touched.

## Code-quality findings — tour-aware-session-boundary (2026-07-27)
- **Pointer:** 2 MINOR findings (0 CRITICAL / 2 MAJOR) from `feature-review-quality` on ship `18722aa` — the 2 MAJORs and 2 of the 4 MINORs were **FIXED IN-FEATURE** (see below); these 2 remain: (1) `grep_check` has no case-insensitive option, so the next caller needing one will hand-roll and re-introduce the fail-open shape WP7m just closed; (2) the Step-7 bright-line sentence is unscoped and would also suppress an *explicitly operator-requested* mid-tour handoff. Full bodies: [`workflow-system/state/backlog-quality-findings.md`](backlog-quality-findings.md) → `# tour-aware-session-boundary — 2026-07-27`.
- **The 2 MAJORs + 2 MINORs were FIXED IN-FEATURE, not backlogged** — all four corrupted the artifact **WP7e is chartered to pin against**, so deferring was not viable: (1) the three block-`(i)` regression pins **failed OPEN** on a missing/renamed file (verified against a synthetic path — and WP5/M9 already renamed exactly these three skills once), now fail closed via an `[ -f ]` precondition; (2) their vocabulary matched only `tutorial|workflow tour`, so leaks worded "onboarding tour"/"greenfield arm" passed clean (the repo's own sensitivity-vs-relevance trap — the mutation used the word `tutorial`), now widened without loosening to bare `tour` (which false-positives on "detours"); (3) a stale `~30 lines` claim survived in `wbs.md` after the correction landed in the WIP + spec (WP7l's doc-vs-reality class, 1 of 3 copies); (4) the guard's close enumeration missed `feature-refactor` (F21) vs. the canonical 4-close table. All fixes **mutation-verified**; suite 485 → 487.
- **Priority:** low (both remaining)
- **Status:** pending
- **Pickup shape:** finding (2) is **user-facing tour copy in the exact region the operator's DEFERRED acceptance read covers** → settle it inside **WP7e's copy-freeze**, alongside the 4 copy MINORs already routed there from WP7l/WP7n; do NOT fix it blind. Finding (1) is a test-harness ergonomics improvement, independent of the tour — pair it with adding **case-variance in emphasis words** (`NOT`/`MUST`/`ONLY`) to `docs/lessons/verify-grep-blind-spots.md`, which currently lists only en-dash / bold-wrap / line-wrap.

## Code-quality findings — greenfield-tour-cwd-sample-and-close-restructure (2026-07-25)
- **Pointer:** 5 MINOR findings (0 CRITICAL / 2 MAJOR) from `feature-review-quality` on ship `783bdf2` — compression residue from the WP7n close restructure: an ambiguous `Next Step:` block-membership rule (the same ambiguity that broke a sentence-counter), a mechanics pointer that inverted direction during compression, a greenfield `/exit`-before-`mkdir` ordering slip in the user's LAST on-screen instruction, a garden-path clause in the git-safety rationale, and a duplicate `Open discoveries:` WIP line. Full bodies: [`workflow-system/state/backlog-quality-findings.md`](backlog-quality-findings.md) → `# greenfield-tour-cwd-sample-and-close-restructure — 2026-07-25`.
- **The 2 MAJORs were FIXED IN-FEATURE, not backlogged** — (1) the spec revision header claimed it resynced `§3` both-arm step-8 rows + `§7` rows but had not, leaving the beat tables describing the *superseded* close; (2) the new group-9 runnable assertion overrode `TODO_STORE` to an external temp file, so it never exercised the flat-stamped `./todos.txt` the tour's Step-5 grounding beat actually uses. Both would have corrupted the artifact **WP7e is chartered to pin against**, so deferring them was not viable. Fixes verified: spec rows resynced; assertion rewritten to use the real default store + a new store-resolution assertion, **mutation-verified** (breaking `SCRIPT_DIR` resolution now fails it). Suite 19 → 20.
- **Priority:** low (all 5 remaining)
- **Status:** pending
- **Pickup shape:** all five are trivial prose/one-line fixes. **Four are user-facing tour copy → best folded into WP7e's copy-freeze so they are settled BEFORE pins lock accepted copy** (two of them — the block-membership ambiguity and the garden-path git-safety clause — directly affect the DEFERRED verify-human read the operator still owes). The fifth is already fixed and retained only as a data point on the recurring WIP-edit failure mode.

## SURFACE-2026-07-25-WP7N-CLOSE-STRUCTURE-UNPINNED
- **Source:** feature:verify-codify (greenfield-tour-cwd-sample-and-close-restructure, Phase 2 / WP7n)
- **Target level:** feature (WP7e charter — already-planned work, recorded so it cannot be dropped)
- **Type:** gap (measured coverage gap)
- **Summary:** WP7n's deliverable — the restructured tour closes (`Next Step:` block LAST, per-branch, ≤3 sentences/option, all beats surviving the re-order) — has **zero automated coverage**, confirmed empirically rather than assumed: **deleting BOTH `Next Step:` blocks outright still passes the scaffold suite (19/19) and `check-structure.sh` (472/1, unchanged)**. `grep -c tutorial tests/check-structure.sh` = 0 — the `tutorial-*` family has no structural pins at all yet.
- **Context:** Deliberately NOT fixed in-feature, for three reasons: (1) the scaffold suite's group-8 comment states its own boundary verbatim — *"This pins the consuming-surface wiring only; the tour's behavioral scenarios + structural pins are WP7e's job — deliberately NOT duplicated here"* — and close-ordering is tour structure, not scaffold wiring; (2) **verify-human is DEFERRED** for both phases, so a pin written now would freeze copy the operator has not accepted, inverting the load-bearing pins-lock-*accepted*-copy rule; (3) WP7e would rewrite them anyway. Phase 1's coverage WAS added in-feature (new group 9 + a group-8 `--dest` assertion, both mutation-verified) precisely because its change genuinely was scaffold wiring — the boundary was applied, not dodged.
- **Suggested action:** WP7e pins, against operator-ACCEPTED copy: `Next Step:` present and LAST in both arms (line-order assertion — the shape Phase-2 verify-self used); per-branch blocks with Branch B carrying NO replay option; ≤3-sentences-per-option; beat survival (the 13-beat greenfield list + brownfield analogues incl. the replay invitation's 4 mechanics); greenfield-only cleanup offer placed AFTER artifacts-as-proof; brownfield having NO cleanup offer and NO deep-dive pointer. **Pin-authoring caveat (learned the hard way):** a naive sentence-count check on this block IS FLAKY — it folds the trailing italic `Housekeeping:` line into the preceding option (produced a false 5/4 where truth was 3/2). Delimit on the `Housekeeping:` line or assert per-option line spans.
- **Priority:** medium
- **Status:** pending — ⚠️ **NOT resolved by WP7e, despite naming it as the resolver.** Audited at `/product-finalize` 2026-07-28: `[Phase 19]` pins the tour surface broadly (47 pins) and its header *cites* this SURFACE, but **no pin asserts `Next Step:` present-and-LAST** — the only `Next Step` occurrence in `check-structure.sh` is that comment. The line-order assertion this entry asked for was never written. **Carried forward, not closed** — closing it on the strength of WP7e's name would have retired a real coverage gap on a citation rather than an implementation. The suggested action below stands unchanged and is now cheap: the copy is operator-accepted and frozen, and `[Phase 19]`/`[Phase 19b]` are the obvious host.

## SURFACE-2026-07-21-INSTALL-SH-NO-ORPHAN-PRUNE
- **Source:** feature:build (wp5-disambiguate-pause, Phase 1)
- **Target level:** product:wbs
- **Type:** gap
- **Summary:** `install.sh` is additive-only — after a skill/agent directory is renamed (`git mv skills/session-pause skills/session-handoff`), install.sh creates the new-name symlink but leaves the old-name symlink dangling in `~/.claude/skills/`. A dangling `/session-pause` symlink still surfaces as an "available skill" to the harness but resolves to a non-existent dir. WP5 hit this THREE times in one feature (session-pause, session-resume, session-store-learning renames) and removed each orphan manually (defensive: symlink + dangling + target-in-repo guard) — a clear signal the prune belongs in install.sh.
- **Context:** Any future skill rename hits this. Bites silently — the new skill works, so the stale link is easy to miss. `uninstall.sh` already has the "symlink + target-into-repo" removal primitive; install.sh could reuse it to prune symlinks in `~/.claude/skills/` (and `~/.claude/agents/`) whose target no longer exists.
- **Suggested action:** Add an orphan-prune pass to `install.sh` — after linking, iterate `~/.claude/{skills,agents}/*`, and for each symlink that (a) points into this repo AND (b) is dangling, remove it. Mirror uninstall.sh's defensive guard. Small task.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-07-21-MOVED-PRODUCT-DOCS-INTERNAL-PATH-REFS
- **Source:** feature:verify-codify (doc-layout-unification M7 WP2a)
- **Target level:** task:plan (or fold into M7 WP3-M7 arch-resync — operator's call)
- **Type:** gap (scope completion)
- **Summary:** The M7 source sweep rewrote *external* references to the moved dirs but NOT the moved dirs' own internal contents (they moved wholesale via `git mv`). `workflow-system/state/` internals = 0 stale refs (clean). `workflow-system/product/` has 6 docs with internal `docs/product/|workflow/` refs (transitions 11, arch 18, research 12, vision 4, roadmap 3) that are a **MIX requiring per-ref human judgment**, NOT a mechanical sweep.
- **Context:** Two categories: **(A) LIVE operational prose** describing *current* system behavior → should update to new paths (e.g. `vision.md` "state lives in `workflow/wip/`… `docs/product/`", `transitions.md` "log to `workflow/backlog.md`", "persist to `workflow/.session.md`", "archived to `docs/product/archive/`"). **(B) HISTORICAL/subject-matter refs that MUST NOT be rewritten** — rewriting falsifies the record: `arch.md` AD-1 migration mapping ("`docs/product/*` → `workflow-system/product/`" — rewriting the left side is nonsense), `arch.md` P8 back-loop, `research.md` Option-A + blast-radius table, `roadmap.md` M7 goal, and `SURFACE-2026-07-20-CLAUDESK-UNIFY-DOC-FOLDERS` in this very backlog (all describe the OLD layout as the problem being solved). The Phase-15 anti-regression check deliberately does NOT scan the moved dirs' internals precisely because of category (B).
- **Suggested action:** operator decides category-A refs to update (a small, careful per-ref pass — natural fit for WP3-M7's arch-resync, which already edits `arch.md`) and confirms category-B stays as-is. Do NOT mechanically sweep. **Verify the suggested split against the real doc text before editing** (review-finding-actions-are-hypotheses discipline).
- **Priority:** medium (part of completing M7 cleanly; not a correctness blocker — the *emitted*/prompt paths are all correct)
- **Status:** open

## SURFACE-2026-07-21-SESSION-SCENARIO-S2-S12-FRAGILITY
- **Source:** feature:verify-codify (doc-layout-unification M7 WP2a behavioral run)
- **Target level:** task:plan (test-scenario robustness)
- **Type:** tech-debt (pre-existing, surfaced-not-caused by the rename)
- **Summary:** Two session-orchestrator scenarios fail independent of any code change: **S2** (`session:start routes complex feature → feature:spec`) misclassifies the "real-time collaborative editing" prompt (haiku→S10, sonnet→S5 — a genuine routing-fork ambiguity, not fixed by the stronger model); **S12** (`session:autopilot pauses at verify-human`) trips `not_contains_strict` on `/feature-verify-codify`+`auto-chain` when the model benignly *mentions* verify-codify while explaining the pause (the documented `not_contains_strict` fragility). S3 was merely flaky (passed on sonnet retry).
- **Context:** Surfaced during M7 WP2a verify-codify. PROVEN independent of the rename: the S2/S3/S12 scenario blocks are byte-identical pre/post-sweep, and the full `session-start/SKILL.md` diff is 100% path-string substitutions (zero routing/pause-logic changes). Matches two known lessons: `docs/lessons/test-scenario-routing-forks.md` (S2) and `docs/lessons/test-scenario-strict-mode.md` (S12 — strict mode is only for failure-proxy phrases, not informational ones in benign reasoning).
- **Suggested action:** `/task-plan` — for S12, reconsider whether `/feature-verify-codify` belongs in the strict `not_contains` set (mentioning the next step while pausing is benign); for S2, either sharpen the complex-vs-simple routing signal or accept it as a genuine judgment-call scenario. **Verify against the real scenario+skill before editing** (the suggested fix is a hypothesis).
- **Priority:** low
- **Status:** open

## SURFACE-2026-07-15-BACKLOG-POINTER-BODY-COUPLING-UNPINNED
- **Source:** feature:review-quality (delete-on-resolve-backlog-convention MAJOR)
- **Target level:** task:plan (test-harness / structural-check enhancement)
- **Type:** gap
- **Summary:** The `backlog.md` pointer-stub ↔ `backlog-quality-findings.md` body coupling has NO structural check. The delete-on-resolve feature's migration left 4 orphaned pointer stubs (bodies already swept) that green structural (416/0) + green scenarios + green verify-self all missed — only the review-quality reviewer caught them. A `check-structure.sh` pin asserting "every `## Code-quality findings — <feat>` pointer in backlog.md has a matching `# <feat>` group in backlog-quality-findings.md, and vice-versa" would catch this class mechanically.
- **Context:** Also relevant: verify-self's nothing-open-lost check is one-directional; the inverse (nothing-resolved-retained) has no automated guard. The pointer↔body pin is the higher-value, more-mechanizable half.
- **Suggested action:** `/task-plan` — add a structural check pinning bidirectional pointer↔body coupling for the two backlog files. Verify against the current 2 legit pointers (memory-location-symlink, wp6) before pinning.
- **Priority:** low
- **Status:** open

## SURFACE-2026-07-21-RUN-TESTS-ID-DRYRUN-STILL-WALKS-ALL-FILES
- **Source:** feature:build (boundary-handoff-autochain Phase 3 P3.2)
- **Target level:** task:plan (test-harness perf, minor)
- **Type:** tech-debt
- **Summary:** After the P3.1 `--id` pre-parse fix, a targeted `--id`/`--group` run is no longer slow (22× fewer parses) but still **walks every group file** parsing each scenario's `id` (~22s for a single-id `--dry-run` across all 8 groups / ~194 scenarios). The hang is gone; near-instant is still possible.
- **Context:** The remaining cost is one cheap `id` parse per scenario in every file, even for a `--group session --id X` run that only needs one file. A per-file `id`-prescan (grep the `id:` lines once per file instead of per-scenario python spawns), or skipping non-`--group` files entirely when `--group` is set, would cut targeted runs to near-instant.
- **Suggested action:** `/task-plan` — (a) when `--group` is set, skip non-matching group files before the per-scenario loop; (b) optionally replace the per-scenario `id` python-parse with a single grep-based `id:`-line prescan per file. Low priority — the blocking bug is already fixed.
- **Priority:** low
- **Status:** open

## SURFACE-2026-07-13-STEP0-PREAMBLE-VS-PROCEDURE-RENUMBER
- **Source:** operator observation during backlog-paydown WP4 (2026-07-13)
- **Target level:** task:plan (prose-only skill-structure cleanup; sizing TBD — may touch several skills)
- **Type:** tech-debt (doc-structure clarity)
- **Summary:** Several skills use a `## Step 0: <name>` **top-level** heading as a pre-procedure preamble, then a *separate* `### 1. / ### 2. …` numbered list under `## Procedure`. The dual numbering scheme (a "Step 0" that isn't part of the `### 1/2/3` sequence) reads awkwardly and confuses "is Step 0 the first procedure step or a preamble?". Renumber/reframe so the step scheme is coherent — e.g. make the preamble un-numbered ("## Preamble: …" or "## Before you start") OR fold it into a `### 0.`/`### 1.` that's actually part of the procedure sequence.
- **Context:** Surfaced while doing WP4 (which only renames the design-priors consult *suffix* to disambiguate from the pinned entry-point `## Step 0: Available product context` convention — it does NOT touch the numbering). The renumber is a broader, separate cleanup: it likely spans all skills carrying a `## Step 0` (the 6 entry-point skills + the 2 renamed by WP4), and must stay consistent with the Phase-3 structural pins that assert the literal `## Step 0: Available product context` string for entry-point skills — so any rename of the entry-point heading requires a matching Phase-3 pin update (tripartite-sync discipline). Do NOT bundle into WP4.
- **Suggested action:** `/task-plan` — decide the coherent scheme, apply across all `## Step 0`-bearing skills, update the Phase-3 pins to match. Property-check the pin strings after.
- **Priority:** low
- **Status:** open

## Code-quality findings — wp7k-full-product-cycle-tour (2026-07-24)
- **Pointer:** 1 MINOR finding (feature-review-quality, ship 8bbf5c1, drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. The frontmatter `description` stage-chain `(vision → roadmap → arch → wbs)` drops `research` vs. the 5-stage body/spine form — a minor user-facing inconsistency, **verified inherited verbatim from the design §6 draft description** (not introduced by the build). Full body in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low
- **Status:** pending
- **Pickup shape:** trivial 1-word frontmatter insert; **best folded into WP7e** (the copy-freeze pass against operator-accepted batch-walkthrough copy — the description may be re-touched there anyway), or a `/util-backlog-paydown` sweep. **Verify against the real code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — wp7j-replay-invite-brownfield-git-safety (2026-07-23)
- **Pointer:** 3 MINOR findings (feature-review-quality, ship f90446d, drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. (1) flow-doc says "cross real session boundaries, NOT by narrating," but both arms' Step 7 permit an in-place-narration fallback — a reconciliation seam a future editor should settle (WP7e territory); (2) wbs 7j.3–7j.6 checkboxes stale `[ ]` at ship though shipped in the commit — likely auto-resolved at product-finalize wbs resync; (3) Step-0 brownfield git-safety convergence line says "relaunch in **this directory**" but the safe-copy/different-project escape branch means it may not be this directory. Full bodies in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** all trivial coherence/housekeeping; #1 fold into WP7e (the narrate-vs-do-for-real tension is a codify decision), #2 verify at product-finalize (likely already fixed), #3 trivial 1-line copy tweak. **Verify each against the real code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — wp7i-richer-greenfield-sample (2026-07-22)
- **Pointer:** 3 MINOR findings (feature-review-quality, ship 5ca1723, drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. (1) `lib/done.sh:30` opaque `${line#??? }` 4-char-prefix strip — a naming comment would help (cosmetic); (2) smoke group [5] independence check assumes the copied `todo` is present (robustness nit); (3) `sample/todos.txt` tracked 0-byte store — a stray in-source run dirties it, but **reviewer: no change recommended** (tour always stamps a fresh copy; it's the intended teaching surface). Full bodies in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** all trivial; fold into a `/util-backlog-paydown` sweep or any future touch of the scaffold/smoke. #3 is likely close-as-wontfix. **Verify each against the real code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — wp7a-onboarding-flow-spec (2026-07-22)
- **Pointer:** 1 MINOR finding remaining (2 of the original 3 RESOLVED by WP7d — SPLIT-GREENFIELD-GROUNDING + SECTION3-LEGEND-NO-DISPOSITION-TOKENS, see CHANGELOG). Remaining: §5b permission-mode table's `acceptEdits` middle column overstates "safe FS cmds auto" (precision nit in the one correcting section — the reassurance copy is already airtight; tighten when the §5b table is next touched). Full body in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low
- **Status:** pending
- **Pickup shape:** trivial precision edit to the §5b table middle column; verify against the Claude Code permission-modes docs + the real doc text first (review-finding-actions-are-hypotheses). Bundle into the next `/util-backlog-paydown` sweep.

## Code-quality findings — boundary-handoff-autochain-state-machine (2026-07-21)
- **Pointer:** 3 MINOR findings (feature-review-quality, ship 3104205), all cosmetic/docs: (1) `transitions.md` S-ID gap (S19/S21 unused) undocumented; (2) the "table is authoritative" guard bullet nested at 5-space instead of 3-space peer across the 4 AGENTS.md; (3) S29's `not_contains: TRANSITION: S17` is near-inert. Full bodies in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** all trivial docs/test-nit edits — bundle into the next `/util-backlog-paydown` sweep. **Verify each against the code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — doc-layout-unification (2026-07-21)
- **Pointer:** 1 MINOR finding remaining (3 of the original 4 RESOLVED by the 2026-07-21 post-ship refactor — see CHANGELOG). Remaining: `run()` uses `eval "$*"` (quoting fragility inherited from `tools/memory-link/`; a path with embedded `"`/`$` would break — not triggered by the known doc-path input set). Full body in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low
- **Status:** pending
- **Pickup shape:** small — swap `eval "$*"` for a `"$@"`-based dispatch in `migrate-doc-layout.sh`; ideally fixed together with the identical pattern in `tools/memory-link/` since it's a shared inherited smell. Not urgent (no known-input trigger). **Verify against the code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — wp6-research-cost-tier-disambiguation (2026-07-21)
- **Pointer:** 3 MINOR findings (feature-review-quality, ship 17fe152). (1) QR2 scenario `contains_any` includes prompt-answerable `"80"`/`"443"` anchors that dilute the assertion — **cheap+safe fix**; (2) quick-research `description` is dense (~55 words) — cosmetic; (3) the "never auto-launch" confirm-gate clause is prose-only across 3 surfaces with no placement-level pin — latent-drift guard. Full bodies in [`workflow-system/state/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** finding (1) is the strong next-`/feature-refactor`-or-sweep pickup (drop the two port-number anchors from QR2, keep `"confidence"`/`"settled"`); (2)+(3) are optional polish. **Verify against the code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — memory-location-symlink (2026-07-03)
- **Pointer:** 2 MINOR findings auto-backlogged by feature-review-quality against ship commit d173bd7 — (1) `ensure-memory-link.sh` dry-run emits a stray `cd: No such file` on stderr when repo target dir doesn't exist yet + harness already symlinked (diagnostic noise, verdict correct); (2) the "any project with docs/product/" migration scope rule is prose-only, not script-enforced (acceptable given the P2.2 operator-confirmation gate). The 2 MAJOR findings from the same review were fixed in-place (amended into the ship commit) — see the WIP `## Code-Quality Review` section. Full bodies in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** small task — (1) is a ~2-line dry-run guard; (2) is a one-line README prose softening. Bundle into a `/task-plan` or the next `/util-backlog-paydown` sweep.

## MAYBE

_(no open items)_

---

## Buried

The following items were buried by user decision. Full content preserved in [`workflow/backlog-deferred-2026-05.md`](backlog-deferred-2026-05.md).

Buried 2026-06-07:
- `SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER` — bulk-delete safety pattern (CLAUDE.md convention proposal).
- `SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING` — audit-method gap; destructuring patterns require their own grep.
- `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` — codify plan-time downstream-contract grep into `feature-plan` SKILL.md.
- `SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD` — `docs/product/wbs.md` exceeds 300-line size guard.
- `SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG` — `--db` silently overrides `$CLAUDE_TIME_DIR` for config lookup.
- `SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE` — `session_id[:8]` truncation can collide in synthetic test data.
- `SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL-DOESNT-REACH-REACT` — synthetic `WheelEvent` dispatch doesn't reach React's `onWheel`.
- `SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT` — structural check missing; frontmatter `name:` vs. parent dir.

Buried 2026-06-12:
- `SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE` — borrow obra/superpowers' behavioral pressure tests for skill rationalization-resistance.


## SURFACE-2026-06-25-AUDIT-PROMPT-LATITUDE-NEWER-CLIENT-MODEL
- **Source:** incident:resolve (incident-autopilot-askuserquestion-pauses)
- **Target level:** task:plan
- **Type:** tech-debt
- **Summary:** The AskUserQuestion-on-AUTO regression and the earlier auto-branching regression (commit 73e97e2) are two instances of one class: a newer client / Opus 4.8 acting on latitude the prompts never explicitly closed. Each was fixed reactively after biting. A proactive audit of the instruction surface (SKILL.md + AGENTS.md + CLAUDE.snippet.md) for other "implicitly-forbidden-but-never-named" behaviors a more capable/agentic model might reach for (e.g. unrequested branching, spawning subagents, web fetches, file deletions on AUTO paths) would close the class instead of waiting for the next instance.
- **Context:** See `workflow/archive/incident-autopilot-askuserquestion-pauses.md` (Root Cause + F5) — two data points established the class.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-07-14-HARNESS-BUDGET-EXHAUSTION-LAUNDERED-AS-FLAKY
- **Source:** feature:verify-self (WP6 of backlog-paydown-2026-07-13)
- **Target level:** task:plan (test-harness observability)
- **Type:** gap
- **Summary:** `tests/run-tests.sh` silently launders a per-attempt `Error: Exceeded USD budget` into a generic FAIL→retry→FLAKY, so the operator cannot distinguish "model is nondeterministic" (real FLAKY) from "scenario hit the budget ceiling" (a cost/config issue). The runner already computes the string `"possibly budget exceeded or error"` (run-tests.sh:~245) but only for *totally empty* output, and never surfaces it in the FLAKY list or results JSON.
- **Context:** The per-scenario `budget:` key (the original (b) half) shipped in WP6 of backlog-paydown-2026-07-13 (see CHANGELOG). This entry now tracks only the remaining (a) half — the observability fix. Affects any expensive scenario (session-store-learning full-policy-reasoning, product-* decomposition, etc.) on sonnet.
- **Suggested action:** Detect the `Error: Exceeded USD budget` sentinel in `result_text` and label it distinctly in the FLAKY/FAIL detail + results JSON (e.g. status `BUDGET_EXCEEDED` or a `budget_exceeded: true` field), so a budget-driven retry-pass is visibly different from a nondeterminism-driven one. Cheap, high-value.
- **Priority:** medium
- **Status:** open (remaining (a) observability half; the (b) per-scenario budget key already shipped — recorded in CHANGELOG)

## Code-quality findings — wp6-per-scenario-claude-md-fixture-and-neutral-consult (2026-07-14)
- **Pointer:** 3 MINOR findings from feature-review-quality (WP6 ship e2494f9), all on the check-structure.sh [Phase 3f] property-test: (1) `_resolve_claude_md` mirrors the runner branch rather than exercising it — add lockstep-comment; (2) line-number refs in Phase 3f comments rot — anchor on a stable string; (3) `_pt_claude` `grep -q`→`grep -qF` hardening. Full bodies in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** all 3 are cheap+safe 1-line edits (#1/#3 apply directly; #2's exact line numbers need verifying against the committed file first per the "review-finding suggested-actions are hypotheses" Context Rule). Natural candidates for the next `/util-backlog-paydown` sweep or a small `/task-plan`.


---

## Inbound from Claudesk (handoff 2026-07-20 — ✅ ALL FIVE ADDRESSED; return contract closed 2026-07-28)

> These five SURFACEs were handed over by the **Claudesk** project (`/Users/stayman/Personal/projects/claudesk`) as this repo's part of the "secondary non-workflow user" work — see [`HANDOFF-from-claudesk-2026-07-20.md`](../HANDOFF-from-claudesk-2026-07-20.md) at this repo's root for full context, the cross-repo split, suggested sequencing, and the return contract. Claudesk gates all its workflow-coupled UI behind an opt-in with a one-time evangelistic invite + onboarding; that made these skill-system-owned items load-bearing. **Claudesk's M10.9 (gate + rich invite) is scheduled AFTER this repo ships these** — so triage + address them, then send the canonical install copy / settled folder layout / onboarding flow back to Claudesk. Suggested order (refine at your next `/product-roadmap`): #2 folder-unify → #1 install/uninstall → #3/#4 disambiguation → #5 onboarding. **UPDATE 2026-07-21: #2 folder-unify (Milestone 7) + #1 uninstall (Milestone 8) + #3/#4 research-collision (Milestone 10) + #? pause-disambiguation (Milestone 9, WP5) SHIPPED** — their SURFACEs (CLAUDESK-UNIFY-DOC-FOLDERS, CLAUDESK-STANDALONE-UNINSTALL, CLAUDESK-RESEARCH-SKILL-COLLISION, CLAUDESK-PAUSE-AMBIGUITY) are resolved + deleted per delete-on-resolve; see CHANGELOG. **UPDATE 2026-07-28: ALL FIVE ARE NOW SHIPPED.** The last one (onboarding = WP7/M11) shipped 2026-07-27 — built, not merely designed — and its SURFACE is resolved + deleted per delete-on-resolve. **WP8/M12 closed the loop the same day:** the reciprocal handoff `HANDOFF-from-mccc-2026-07-28.md` was delivered to Claudesk's root with all three return-contract deliverables, plus a SURFACE there (`SURFACE-2026-07-28-M11-DOCS-LIST-PATHS-STALE`) for the one actionable item — Claudesk's own M11 `wbs.md:60` still globs the pre-migration doc paths. **This section is now history; nothing here is open.**

## Code-quality findings — uninstall-sh (2026-07-21)
- **Pointer:** 1 MINOR finding auto-backlogged by feature-review-quality against ship commit d7e9075 — `remove_link` header comment lists outcome cases in reverse of the code's check order (harmless doc/read-order polish). The MAJOR (arg-parser `--project` flag-shaped-value → real uninstall) + its sibling MINOR (missing `--project` value → silent exit 1) were FIXED in the post-ship refactor per operator's refactor-now choice. Full body in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low
- **Status:** pending
- **Pickup shape:** trivial — reorder the comment; bundle into next `/util-backlog-paydown` or a docs-only task. **Verify against the code first (review-finding-actions-are-hypotheses).**

## SURFACE-2026-07-27-CHECK-STRUCTURE-HEREDOC-DELIMITER-INVERTS-EXIT-STATUS
- **Source:** feature:verify-self (WP7e Phase 3, fresh gate-2 runner) + feature:review-quality
- **Target level:** task:plan
- **Type:** tech-debt
- **Summary:** A heredoc **delimiter** typo in `tests/check-structure.sh` (e.g. closing `HITS` → `HITSX`) makes bash consume the rest of the file as heredoc data — **including the guard assertion that would catch it**. The run emits ~40 malformed `[FAIL]` lines, **loses the `=== Summary ===` block entirely**, and **exits 0 where the pristine script exits 1**. `bash -n` stays clean.
- **Context:** The zero-iteration guards added in WP7e defend the empty-BODY case (delimiters intact); a delimiter typo swallows the guard before it runs, so only the *last* heredoc in the file has this exposure. Classified COSMETIC and deferred **because `check-structure.sh` currently has no automated consumer** — no `.github/`, `run-all.sh` never invokes it, no hook calls it — so exit status is read only by a human who cannot miss 40 red FAILs and a missing Summary.
- **Suggested action:** Add an **end-of-file sentinel** — a `check "script reached the summary" "pass"` immediately before the summary block, or a `trap` on EXIT asserting a completion flag. It sits outside every heredoc and cannot be swallowed, removing the whole class. ⚠️ The earlier note claiming this is "structurally unguardable" was **wrong** and is corrected here.
- **Priority:** low — **but re-classify to MAJOR the moment anything automated (CI, a hook, a pre-commit) starts reading this script's exit status.**
- **Status:** pending

## SURFACE-2026-07-27-VERIFY-SH-REQUIRED-FIELDS-UNREACHABLE-WITHOUT-TRANSITION-ID
- **Source:** feature:build (WP7e Phase 4)
- **Target level:** task:plan
- **Type:** bug
- **Summary:** `contains_required` and `contains_required_any` are evaluated **only inside `if [ "$id_match" = true ]`** (`tests/lib/verify.sh` §4), so for a skill that emits no transition they are **unreachable** — the assertion silently never runs. Symptom is misleading: `FAIL (No transition signal found. Expected  or contains: )` with **both fields empty**, which reads like a YAML parse error when the YAML is fine.
- **Context:** **This affects a SHIPPED scenario:** `session.yaml::S34-tour-marker-survives-pointer-deletion` uses `contains_required_any` with no `transition_id`, so its positive assertion **has never once been evaluated**. S34 currently fails on its strict `TRANSITION: S17` negative only — the floor is intact, but for a narrower reason than recorded. If the S17 defect were fixed, S34 would have **no reachable positive assertion at all**. Repo-wide, S34 is the only such scenario (10 use `contains_required*`; 9 have a transition_id).
- **Suggested action:** Either make the required-* fields evaluate on the `contains_any` path too, or have the harness **warn loudly** when a scenario declares `contains_required*` without a `transition_id`. Then fix S34 to use `contains_any`. Do NOT soften S34's assertions — it is a deliberate known-failing floor scenario.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-07-27-RUN-TESTS-LEADING-DASH-ASSERTION-BREAKS-GREP
- **Source:** feature:build (WP7e Phase 4)
- **Target level:** task:plan
- **Type:** bug
- **Summary:** Assertion strings are passed to `grep` as **arguments**, so a string beginning with `-` is parsed as a **flag**. Forbidding the literal `--dangerously-skip-permissions` produced `grep: unrecognized option` and FAILed the scenario for a reason unrelated to the skill.
- **Context:** Worked around in `tutorial.yaml::T2` by asserting a dash-free stem, which covers the same safety regression. But the constraint is invisible until you hit it, and the failure looks like a scenario bug rather than a harness one.
- **Suggested action:** Use `grep -e "$pat"` or `grep -- "$pat"` in `verify.sh`'s matcher loops. One-line fix; add a scenario asserting a leading-dash literal to pin it.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-27-RUN-TESTS-ID-PREFIX-SILENTLY-RUNS-ZERO
- **Source:** feature:build (WP7e Phase 4)
- **Target level:** task:plan
- **Type:** tech-debt
- **Summary:** `--id` requires the **FULL scenario slug**. A prefix (`--id S33,S34`) matches nothing, runs **zero** scenarios, and still prints a clean `TOTAL 0` summary — a silent no-op that reads exactly like "nothing to run" rather than "your selector matched nothing."
- **Context:** Distinct from `SURFACE-2026-07-21-RUN-TESTS-ID-DRYRUN-STILL-WALKS-ALL-FILES`, which is about *slowness* after a fix that made targeted runs work. This is zero-execution from a mis-typed selector, and it can be mistaken for a passing run.
- **Suggested action:** Warn (or exit non-zero) when `--id` matches no scenario. Also recorded in `runtimes.md` under the run-tests entry.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-27-PHASE19-COMMENT-OVERSELLS-ENFORCEMENT
- **Source:** feature:review-quality (WP7e)
- **Target level:** task:plan
- **Type:** tech-debt
- **Summary:** Two enforcement claims in `[Phase 19]`'s (d) block are not implemented: "exactly one canonical declaration" (the pin is `grep_check … 1`, i.e. **min-count ≥ 1** — two declarations pass) and "makes a FIFTH reader adding a local restatement FAIL" (the citer list is **hardcoded to four paths**, so a fifth file is never examined and cannot fail).
- **Context:** The design is fine; the comment oversells it. In a phase whose entire subject is "a pin can assert its file is clean but never that its anchors are right," a comment claiming enforcement that does not exist is the same failure at the documentation layer.
- **Suggested action:** Either make the canonical pin exact (capture the count, assert `-eq 1`), or reword to "at least one canonical declaration, and each of the four known citers cites rather than restates — a fifth reader is not mechanically detectable."
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-27-PHASE19-SCOPE-AND-ANCHOR-GAPS
- **Source:** feature:review-quality (WP7e)
- **Target level:** task:plan
- **Type:** tech-debt
- **Summary:** Three narrow-scope gaps, all low impact: (1) the `tour_step:` scope glob `tests/fixtures/**/*.md` **does not match zero directories**, so `tests/fixtures/CLAUDE.md` and `tests/fixtures/CLAUDE-with-tracking-override.md` are out of scope (verified: `tour_step: 8` appended to the former leaves the pin PASS); (2) the emission-detection regex is **line-anchored**, so a prose form like ``Emit `TRANSITION: F1` and stop.`` is not detected — ~37% of real occurrences repo-wide sit in non-anchored positions, though the dominant real emission style *is* line-anchored so the realistic regression is caught; (3) `tutorial.yaml`'s comments cite specific **line numbers** in tour SKILL.md files, which will rot as that user-facing prose is edited.
- **Suggested action:** (1) `'tests/fixtures/*.md' 'tests/fixtures/**/*.md'` plus a note that archives are deliberately out of scope; (2) add a comment recording the deliberate narrowness, since the surrounding prose presents the paired check as complete; (3) prefer quoted phrases over line ranges.
- **Priority:** low
- **Status:** pending
