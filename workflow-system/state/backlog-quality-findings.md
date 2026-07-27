# Backlog — Code-Quality Review Findings

This file holds MINOR findings auto-backlogged by `feature-review-quality` runs. The parent `workflow/backlog.md` keeps **one pointer entry per feature** referencing this file. Convention adopted 2026-06-12 to avoid backlog volume noise — see `SURFACE-2026-06-12-ADJUST-QUALITY-AGENT-USE-DEDICATED-FILE` in `backlog.md` for the agent-config followup that codifies this shape.

Items are grouped by source feature. Within each group, each finding keeps the full SURFACE block produced by the reviewer subagent.

---


# tour-state-survives-session-boundary — 2026-07-27

## SURFACE-2026-07-27-QUALITY-TOUR-STEP-FIELD-HAS-NO-READER
- **✅ DECIDED 2026-07-27 — option (b): DROP the field.** Operator ruling: *"drop it"*. `tour:` alone becomes the
  marker. Rationale matches the finding's own analysis — the arms already resume correctly by narrative
  position, so the field promises a step-addressed precision nothing implements; dropping it is cheaper, matches
  actual behavior, and removes a surface WP7e would otherwise have to freeze. Option (a) (wire step-addressed
  resume) is explicitly rejected, not deferred — revisit only if a tour ever needs to resume mid-scene.
- **Removal sites (10 live, verified 2026-07-27):** `skills/session-handoff/SKILL.md` (:66 prose, :92 schema
  block) · `skills/session-restore/SKILL.md` (:28) · `skills/tutorial-greenfield-workflow-tour/SKILL.md` (:375,
  :425 field table) · `skills/tutorial-brownfield-workflow-tour/SKILL.md` (:229, :282 field table) ·
  `docs/lessons/tutorial-tour-session-chain-flow.md` (:68) · `tests/fixtures/wip/tour-inner-work-finalized.md`
  (:4) · `tests/fixtures/session/tour-greenfield-stepping.md` (:9) · plus `wbs.md` (:516, :543) and
  `onboarding-flow-spec.md` (:48) as as-built records — **those two are history, not contract: annotate, do not
  rewrite.** Watch the S31/S34 fixtures: removing the field from a fixture changes what the scenario exercises.
- **Sequencing:** do this **inside WP7e**, alongside the sibling schema-of-record finding — both edit the same
  five prompt files WP7e freezes, and doing them together means one pass over that surface, not two.
- **Source:** `feature-review-quality` on ship `ccfedac` (WP7o), MAJOR
- **Priority:** medium
- **Finding:** `tour_step:` is **written by four files and documented in five, but read by none.**
  `session-restore` step 5 hands back to `resume_skill` unconditionally; neither arm branches on it to choose an
  entry step (they assume Step 8 by narrative position). The schema calls it "the step to resume **at**".
- **Why it matters:** a schema-mandated field with no consumer can drift to any value with no observable effect,
  and no test can catch the drift. It also implies a resume precision the implementation does not have.
- **Fix direction (two viable, pick one):** (a) wire the arms' re-entry to it, making resume genuinely
  step-addressed; or (b) drop it and let `tour:` alone be the marker. (b) is cheaper and matches current
  behavior; (a) is the better product if a tour ever needs to resume mid-scene.
- **Pickup shape:** settle inside **WP7e** — it touches the arm re-entry copy WP7e is chartered to freeze. Do
  not fix blind: the choice between (a) and (b) is a product call about how precise tour resume should be.

## SURFACE-2026-07-27-QUALITY-TOUR-SCHEMA-HAS-NO-CANONICAL-DEFINITION
- **Source:** `feature-review-quality` on ship `ccfedac` (WP7o), MAJOR
- **Priority:** medium
- **Finding:** the `tour:`/`tour_step:` contract is an **implicit schema spanning five prompt files with no
  canonical definition.** Block (i)'s positive pin is `grep_check ... 'tour:' 1` — a bare substring that passes
  on any incidental mention, so it pins the *word*, not the contract.
- **Observed drift, already present:** `session-handoff` states `drive_mode` is *required* on a tour pointer,
  while `session-restore` step 4.3 handles the "`tour:` pointer somehow has no `drive_mode`" case as a defect to
  report. Two files, two postures on the same field — and nothing that would flag a third reader adopting a
  third posture.
- **Fix direction:** name `session-handoff` §2 ("Tour-driven handoffs") the **schema of record** and have the
  other four files cite it — roughly one sentence each. Optionally add a structural pin that the citation exists.
- **Pickup shape:** cheap and mechanical, but it edits the same five files WP7e freezes → **fold into WP7e**.

## SURFACE-2026-07-27-QUALITY-RUNTIMES-FRONTMATTER-NOT-A-BARE-DATE
- **Source:** `feature-review-quality` on ship `ccfedac` (WP7o), MAJOR (lowest of the three)
- **Priority:** low
- **Finding:** `runtimes.md:3`'s frontmatter now reads `updated: 2026-07-27  <!-- WP7o Phase 4 verify-auto -->`.
  The canonical registry shape in `CLAUDE.snippet.md` is a **bare ISO date**; per-observation commentary belongs
  on the `**History:**` bullets (which this diff also does, correctly).
- **Why it matters:** nothing parses the field today, so it is not breaking — but it makes the one
  machine-shaped field in the file no longer a clean date, and invites a future parser to trip.
- **Fix direction:** strip the comment from the frontmatter value; the same text already lives on the History
  bullet. One-line change, no behavior depends on it.

## SURFACE-2026-07-27-QUALITY-PHASE-18B-SUBLETTERED-AND-UNDOCUMENTED
- **Source:** `feature-review-quality` on ship `ccfedac` (WP7o), MINOR
- **Priority:** low
- **Finding:** `[Phase 18b]` is the first **sub-lettered** phase in `check-structure.sh` (every other is
  integer-numbered) and is absent from `CLAUDE.md`'s phase inventory and `arch.md`.
- **Fix direction:** either renumber to `[Phase 19]` or add a one-line note to the conventions list explaining
  that a `Nb` phase is the self-test *of* phase `N`. The latter preserves the deliberate pairing.

## SURFACE-2026-07-27-QUALITY-TWO-PROBE-DESIGN-ENFORCED-ONLY-BY-COMMENT
- **Source:** `feature-review-quality` on ship `ccfedac` (WP7o), MINOR
- **Priority:** low
- **Finding:** the deliberate divergence between `$TOUR_NARRATION_PROBE` and session-capture's inline
  zero-vocabulary regex is explained at length in a comment but **enforced only by that comment**; it will read
  as an oversight to a maintainer who skims.
- **Fix direction:** the Phase-18b clean-tree case already proves consolidation would be safe; consider a pin
  asserting the two probes are intentionally distinct, or accept the comment as sufficient.

## SURFACE-2026-07-27-QUALITY-THIRD-DUPLICATED-BLOCK-ACROSS-ARMS
- **Source:** `feature-review-quality` on ship `ccfedac` (WP7o), MINOR
- **Priority:** low
- **Finding:** the "carry the run to its end from here" and "narrate, don't act on it" blocks are near-verbatim
  duplicates across the two arms — now the **third** duplicated block in this file pair (with the Scene-1 field
  table and the record-drive-mode paragraph). Consistent with the arms' existing style, so not a defect; but
  each duplication is a place the two arms can silently diverge.
- **Fix direction:** no action recommended standalone. If the count grows, consider whether the arms want a
  shared included fragment — a structural change that should be decided deliberately, not incrementally.

# tour-aware-session-boundary — 2026-07-27

## SURFACE-2026-07-27-QUALITY-GREPCHECK-NO-CASE-INSENSITIVE-OPTION
- **Source:** feature:review-quality (tour-aware-session-boundary / WP7m), ship `18722aa`
- **Severity:** MINOR
- **Location:** `tests/check-structure.sh` — the `grep_check()` helper (~line 32)
- **Finding:** `grep_check` is case-sensitive only. WP7m needed a case-insensitive match (the guard
  heading reads `... is **NOT** the session's boundary`, with `NOT` upper-cased for emphasis) and
  hand-rolled an 8-line `grep -ciE` block instead — the only place in a ~2400-line file that
  reimplements the helper's body. **Resolved in-feature for WP7m** by anchoring on a case-*stable*
  substring instead (`the session's boundary` + `^### The tour hosts the workflow`, each verified to
  match exactly 1× per arm), so the assertions moved back inside `grep_check` — which also fixed a
  fail-open-on-missing-file hazard the hand-rolled form had.
- **Residual (why this entry exists):** the *next* caller who genuinely needs case-insensitivity has
  no supported path and will hand-roll again, re-introducing the fail-open shape. Consider an optional
  4th/5th parameter or a `grep_check_i` variant.
- **Context:** related to the emphasis-word blind spot — `docs/lessons/verify-grep-blind-spots.md`
  lists en-dash / bold-wrap / line-wrap cases but not **case-variance in emphasis words**
  (`NOT`, `MUST`, `ONLY`), which cost a false-negative during WP7m's own verify-auto. Worth adding.
- **Suggested action:** add case-insensitive support to `grep_check` (keeping the fail-closed
  behavior), and add the case-variance case to the verify-grep-blind-spots lesson.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-27-QUALITY-STEP7-BRIGHTLINE-UNSCOPED
- **Source:** feature:review-quality (tour-aware-session-boundary / WP7m), ship `18722aa`
- **Severity:** MINOR
- **Location:** `skills/tutorial-greenfield-workflow-tour/SKILL.md` (Step-7 blockquote, ~:292) +
  `skills/tutorial-brownfield-workflow-tour/SKILL.md` (~:198) — the closing sentence
- **Finding:** the bright-line test — *"If you find yourself about to write `.session.md` anywhere
  other than Step 7 Scene 1, you are following the wrong boundary"* — is **absolute and unscoped**,
  unlike the `## Category` bullet, which correctly scopes its prohibition to writing "on the strength
  of `S22`/`S23`". Read literally, the sentence would also suppress an **explicitly
  operator-requested** mid-tour handoff ("I need to stop, write me a handoff"), which
  `CLAUDE.snippet.md` → `## Session vocabulary` treats as the legitimate expensive branch when
  explicitly named. Neither arm has any user-interrupt/abandon path to fall back on (grepped: none).
- **Context:** a real but narrow hole. The auto-chain suppression the guard exists for works
  correctly; this is only about an explicit user request during a tour. **Deliberately NOT fixed
  in-feature:** the fix edits **tour copy inside the exact region the operator's DEFERRED acceptance
  read covers**, and its wording is what WP7e must freeze against *accepted* text — fixing it blind
  would invert the pins-lock-accepted-copy rule.
- **Suggested action (hypothesis — verify against the code first):** add a scoping clause such as
  "…unless the user explicitly asks for a handoff" to the bright-line sentence in **both** arms, and
  settle it inside **WP7e's copy-freeze** alongside the other 4 user-facing copy MINORs already
  routed there from WP7l/WP7n.
- **Priority:** low
- **Status:** pending

# wp7k-full-product-cycle-tour — 2026-07-24

<!-- 1 MINOR finding from feature-review-quality, ship 8bbf5c1 (drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. The finding is INHERITED verbatim from the design §6 draft description (not introduced by the build) — verified: design doc line 221-222 uses the same 4-stage chain. Verify against the real code before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-24-QUALITY-WP7K-DESCRIPTION-STAGE-CHAIN-DROPS-RESEARCH
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 8bbf5c1)
- **Finding:** `skills/tutorial-product-cycle-tour/SKILL.md:3` — the frontmatter `description` lists the stage chain as `(vision → roadmap → arch → wbs)` (4 stages, drops `research`), while the body (line 13) and the design spine use the full 5-stage `vision → roadmap → research → arch → wbs` (research is a real Step 3, `/product-research`). Minor user-facing internal inconsistency. Verified INHERITED verbatim from the design contract's §6 draft description (`full-product-cycle-tour-design.md:221-222`), not introduced by the build.
- **Suggested action (HYPOTHESIS — verify against the code):** align the description's stage chain to the 5-stage body form (insert `research`), OR consciously keep the description terse (4-stage) if the shorter chain reads better in the skill picker. **Best folded into WP7e**, which freezes tutorial copy against the operator-accepted batch-walkthrough copy — the description may be re-touched there anyway. Cosmetic; no behavior.
- **Pickup shape:** trivial 1-word insert in one frontmatter line; fold into WP7e copy-freeze or a `/util-backlog-paydown` sweep.

---

# wp7i-richer-greenfield-sample — 2026-07-22

<!-- 3 MINOR findings from feature-review-quality, ship 5ca1723 (drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. Two of the three are explicitly "no change recommended" by the reviewer (todos.txt tracked-by-design; independence-test robustness nit). Verify each against the real code before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-22-QUALITY-WP7I-DONE-PREFIX-STRIP-OPAQUE
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 5ca1723)
- **Finding:** `tools/onboarding-scaffold/sample/lib/done.sh:30` flips the checkbox with `line="[x] ${line#??? }"` — a `?`-glob strip of exactly 4 leading chars. Correct (both `[ ] ` and `[x] ` prefixes are 4 chars) and verified (re-`done` preserves text + glob-char content), but the `??? ` idiom is opaque: a future maintainer changing the store prefix format has no in-code cue that `??? ` encodes "the 4-char status prefix."
- **Suggested action (HYPOTHESIS — verify against the code):** add a one-line comment naming the "4-char status prefix" assumption (or switch to an intent-revealing form like `${line#"[?] "}` if it round-trips both prefixes). Cosmetic; behavior is sound — do not change behavior.
- **Pickup shape:** trivial 1-line comment; fold into a `/util-backlog-paydown` sweep or any future touch of `done.sh` (e.g. if a later WP fixes the planted tangent).

## SURFACE-2026-07-22-QUALITY-WP7I-INDEPENDENCE-TEST-ASSUMES-COPY
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 5ca1723)
- **Finding:** `tools/onboarding-scaffold/test/run-tests.sh` group [5]'s independence check appends a marker to the copy's `todo` and greps the source `todo` — correct, but silently assumes the copy's `todo` is present/writable; if the scaffold ever stopped copying the extensionless `todo`, this would assert independence against a possibly-missing file rather than fail loudly. Low-likelihood (the earlier run-check in [5] already exercises the copied `todo`).
- **Suggested action (HYPOTHESIS — verify):** optionally add a `[ -f "$D/s/todo" ]` precondition assertion before the marker-append so a missing copied artifact fails loudly. Robustness nit only.
- **Pickup shape:** trivial; fold into a sweep or any future smoke edit.

## SURFACE-2026-07-22-QUALITY-WP7I-TODOS-TXT-TRACKED-EMPTY
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 5ca1723)
- **Finding:** `tools/onboarding-scaffold/sample/todos.txt` is a tracked 0-byte file; running the sample from the source tree with the default `TODO_STORE` writes into it (would dirty a tracked file). **Reviewer: no change recommended** — this is by design (the tour always stamps a fresh copy via `new-sample.sh`; the smoke isolates every store via `fresh_store()`) and the visible store IS the intended "the store is your state, nothing hidden" teaching surface.
- **Suggested action (HYPOTHESIS — likely NO CHANGE):** leave as-is; flagged only so the operator is aware a stray in-source run would dirty a tracked file. If ever a concern, a `.gitignore` on the store or a git pre-commit reset could guard it — but that undercuts the teaching surface. Likely close-as-wontfix.
- **Pickup shape:** likely wontfix; no action expected.

# wp7a-onboarding-flow-spec — 2026-07-22

<!-- 1 MINOR finding remaining (2 of the original 3 — SPLIT-GREENFIELD-GROUNDING + SECTION3-LEGEND-NO-DISPOSITION-TOKENS — RESOLVED by WP7d and deleted per delete-on-resolve; see CHANGELOG). The remaining one is copy-time polish on the §5b permission-mode table. Verify against the real doc text before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-22-QUALITY-ACCEPTEDITS-TABLE-MIDDLE-COLUMN
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 4a43713)
- **Finding:** `onboarding-flow-spec.md` §5b (~L215-218) permission-mode table's `acceptEdits` "Safe filesystem cmds → auto" column is imprecise. Per the Claude Code model, `acceptEdits` auto-accepts file *edits* plus a specific safe-filesystem-command set (`mkdir`/`touch`/`rm`/`mv`/`cp`/`sed`); it is not a blanket "safe filesystem commands auto-approve" tier. The load-bearing distinction the section makes (acceptEdits gates arbitrary shell/network; bypassPermissions doesn't) is CORRECT, and the reassurance copy (~L226-231) only claims accurate behavior — so this is a table-column overstatement in a precision-critical section, not a functional error.
- **Pickup shape:** tighten the middle column at **WP7b copy time** (where the skill copy is authored) so the correcting table is airtight — e.g. "safe FS cmds (mkdir/touch/rm/mv/cp/sed) auto; other shell prompts". Verify against docs (https://code.claude.com/docs/en/permission-modes.md) + the real doc text first.

---

_Resolved findings are **deleted** from this file on close (delete-on-resolve convention, 2026-07-15) — CHANGELOG.md is the canonical per-SURFACE-ID resolution record. Only open findings remain below, grouped by source feature._

# doc-layout-unification — 2026-07-21

<!-- 3 of the 4 original findings RESOLVED by the post-ship refactor (2026-07-21) and deleted per delete-on-resolve — see CHANGELOG: BACKUP-INSIDE-REPO-STAGED + TEST-MISSING-BACKUP-NOT-STAGED-ASSERTION (both MAJOR, backup now written outside the repo + test guard) and HELP-FLAG-UNIMPLEMENTED (MINOR, --help implemented). The one below remains open. -->

## SURFACE-2026-07-21-QUALITY-RUN-EVAL-QUOTING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship a791f6a)
- **Finding:** `tools/migrate-doc-layout/migrate-doc-layout.sh` `run() { ... eval "$*"; }` uses `eval` on a space-joined argument string, forcing every caller to pre-quote paths. Works because callers quote carefully, but a path with an embedded `"`/`$` would break. Inherited from the `tools/memory-link/` precedent (same pattern), not introduced by this feature.
- **Pickup shape:** consider a `"$@"`-based dispatch or a per-command `--dry-run` guard instead of `eval`. Low priority — not triggered by the known doc-path input set; would ideally be fixed in both tools together since it's a shared inherited pattern.

# wp6-research-cost-tier-disambiguation — 2026-07-21

## SURFACE-2026-07-21-QUALITY-QR2-PROMPT-ANSWERABLE-ANCHORS
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 17fe152)
- **Finding:** `tests/scenarios/research.yaml` QR2's `contains_any` includes `"80"` and `"443"` — the literal answer to "what port does HTTP/HTTPS use." Any model answering the question emits those regardless of whether the `quick-research` skill prose exists, so those two anchors provide near-zero signal that the *skill's* confidence-labeling / no-over-reach discipline fired (sibling to `docs/lessons/test-scenario-prompt-leakage.md`). The `"confidence"` / `"settled"` anchors are the load-bearing ones.
- **Pickup shape:** **cheap + safe** — drop `"80"`/`"443"` from QR2's `contains_any` (keep `"confidence"`, `"HIGH"`, `"settled"`), or replace with an anchor that only fires if the skill's over-reach-guard prose ran (e.g. `"no escalation"` / `"None load-bearing"`). Strong next-`/feature-refactor`-or-sweep pickup. **Verify against the code first (review-finding-actions-are-hypotheses).**

## SURFACE-2026-07-21-QUALITY-QR-DESCRIPTION-DENSITY
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 17fe152)
- **Finding:** `skills/quick-research/SKILL.md:2` `description` is a dense ~55-word sentence (tier + confidence-labels + known-unknowns + escalation-gate + ROI contrast). Reads unambiguously but is long for a `description:` field surfacing in skill-selection context; the four in-workflow siblings are terser.
- **Pickup shape:** cosmetic — optionally trim to the two load-bearing distinctions (light/fast web + confirm-before-deep). Disambiguation value is real, so low priority; do NOT lose the quick-vs-deep contrast.

## SURFACE-2026-07-21-QUALITY-CONFIRM-GATE-PLACEMENT-UNPINNED
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 17fe152)
- **Finding:** the "never auto-launch deep-research" confirm-gate clause lives in prose across three surfaces (`skills/quick-research/SKILL.md` §5 + both `agents/{feature,product}-workflow/AGENTS.md` subsections). check-structure.sh [Phase 16] pins the *phrase* exists but not its *co-location* with the escalation step, so a future edit could move the escalation instruction away from the "wait for human yes" clause without tripping a pin.
- **Pickup shape:** low — the skill emits no transition so the AUTO-exit machinery doesn't apply; if hardened, add a pin asserting the escalation-offer step and the "never auto-launch / wait" clause appear within N lines of each other in §5. Latent-drift guard, not a live bug.

# memory-location-symlink — 2026-07-03

## SURFACE-2026-07-03-QUALITY-DRYRUN-STRAY-CD-ERROR
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship d173bd7)
- **Finding:** `tools/memory-link/ensure-memory-link.sh:64` — under `--dry-run`, when the repo target dir does not yet exist (its `mkdir -p` was only echoed) and the harness path is already a symlink, the symlink-target comparison's RHS `cd "$REPO_MEM"` emits a stray `cd: No such file or directory` on stderr. Behavior is still correct (exits 0, correct verdict); non-dry-run always has REPO_MEM present by line 64. Diagnostic noise only.
- **Pickup shape:** guard the comparison's `cd` on `[ -d "$REPO_MEM" ]` in dry-run, or route the compare through the already-computed paths. ~2-line fix.

## SURFACE-2026-07-03-QUALITY-SCOPE-RULE-PROSE-ONLY
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship d173bd7)
- **Finding:** The migration scope rule ("any project with a `docs/product/` dir") is stated in prose only (`tools/memory-link/README.md` + `migrate-memory.sh` header); neither script enforces or checks it — `migrate-memory.sh` runs against any dir it's pointed at. Acceptable given the operator-confirmation gate (P2.2 hard checkpoint), but the prose implies a mechanical guard that doesn't exist.
- **Pickup shape:** either add an optional `--require-product-dir` guard to `migrate-memory.sh`, or soften the README prose to "scope is operator-enforced at the confirmation gate, not by the script." Prefer the prose fix (the enumeration/confirmation already lives in the workflow, not the tool).

# wp6-per-scenario-claude-md-fixture-and-neutral-consult — 2026-07-14

## SURFACE-2026-07-14-QUALITY-PROPTEST-MIRRORS-RUNNER
- **Source:** feature-review-quality (WP6 ship e2494f9)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** `tests/check-structure.sh` [Phase 3f]'s `_resolve_claude_md` is a hand-transcribed COPY of the runner's `claude_md` honor-else-fallback branch, not the runner logic itself. The two can drift independently; the grep_check drift-pins only assert the runner's source line still EXISTS, not that the copy still MATCHES it.
- **Context:** Shell can't easily source a mid-function fragment, so a mirror is a reasonable tradeoff — but the coupling is weak. A future runner-branch change that preserves the `if`-line text but alters fallback behavior would leave the property-test passing against stale semantics.
- **Suggested action:** Add a comment in Phase 3f noting the mirror must be updated in lockstep with run-tests.sh's branch. (Verify against the actual code before applying — per the "review-finding suggested-actions are hypotheses" Context Rule.) Cheap + safe.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-14-QUALITY-PROPTEST-LINE-NUMBER-ROT
- **Source:** feature-review-quality (WP6 ship e2494f9)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** Phase 3f comments cite `run-tests.sh:176-181` (claude_md) and `:236` (budget) for the mirrored one-liners; the reviewer flagged the claude_md branch as having shifted to ~183-187. Line-number references in comments rot on any edit above them.
- **Context:** A future reader chasing "the exact one-liners" lands on the wrong lines. NB: the specific line numbers the reviewer cited were read off a diff, not the committed file — VERIFY the actual current line numbers before editing (per the "review-finding suggested-actions are hypotheses" Context Rule; the fix is real regardless, the exact numbers are the hypothesis).
- **Suggested action:** Replace line-number refs in the Phase 3f comments with a stable string anchor (e.g. "the `fixture_claude_md` honor-else-fallback branch"). Cheap + safe.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-14-QUALITY-PROPTEST-GREP-UNANCHORED
- **Source:** feature-review-quality (WP6 ship e2494f9)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** Phase 3f's `_pt_claude` uses `grep -q "$want"` with an unanchored, unescaped pattern. Fine for the current all-caps marker strings (`NAMED-FIXTURE-MARKER`, `DEFAULT-FIXTURE-MARKER`), but a future `want` value containing a regex metacharacter would misfire silently.
- **Context:** Purely defensive hardening; no current bug.
- **Suggested action:** Change `grep -q` → `grep -qF` (fixed-string match) in `_pt_claude`. 1-char edit, cheap + safe.
- **Priority:** low
- **Status:** pending

# uninstall-sh — 2026-07-21

<!-- 1 MINOR remaining (auto-backlogged). The MAJOR + sibling MINOR (arg-parser --project flag-shaped/missing value) were FIXED in the post-ship refactor (2026-07-21) per operator's refactor-now choice — see CHANGELOG + the WIP ## Code-Quality Review section. -->

## SURFACE-2026-07-21-QUALITY-UNINSTALL-REMOVE-LINK-COMMENT-ORDER
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship d7e9075)
- **Finding:** `uninstall.sh` `remove_link` header comment enumerates outcomes in the order "not present → [ok] … symlink … real file", but the code body checks them in the reverse order (`-L` symlink → `-e` real file → fallthrough `[ok]`). Harmless — behavior is correct — but the comment ordering doesn't match read order and momentarily misleads a future reader.
- **Pickup shape:** trivial — reorder the comment's outcome list to match the code's check order (`-L` → `-e` → fallthrough). Bundle into the next `/util-backlog-paydown` sweep or a docs-only task.

# boundary-handoff-autochain-state-machine — 2026-07-21

## SURFACE-2026-07-21-QUALITY-SESSION-ID-GAP-UNDOCUMENTED
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 3104205)
- **Finding:** The `transitions.md` Session-transitions table now reads S17, S18, S20, S22, S23 — S19 and S21 are absent and undocumented. A future author adding a session edge cannot tell whether S19/S21 are retired-and-reserved or simply never used, risking accidental ID reuse in an append-only namespace.
- **Pickup shape:** trivial — add a one-line "S19/S21 unused" note near the Session-transitions table (mirroring how `F17` retired is called out elsewhere). Bundle into the next `/util-backlog-paydown` sweep or a docs task. **Verify against the code first** (review-finding-actions-are-hypotheses).

## SURFACE-2026-07-21-QUALITY-GUARD-BULLET-NESTING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 3104205)
- **Finding:** The new "pause-policy table is authoritative" bullet in the §Your-Role guard block is nested at 5-space indent (child of the "Agent-side guard is CONTEXTUAL" bullet) across all 4 orchestrator AGENTS.md, but it reads as a peer statement governing the whole boundary auto-chain decision, not only the CONTEXTUAL-guard sub-case. Cosmetic; identical across all 4 files.
- **Pickup shape:** trivial — promote the bullet to a 3-space peer of the two sibling guard bullets in all 4 AGENTS.md (keep them in sync). Bundle into the next sweep. **Verify the current indent against each file first.**

## SURFACE-2026-07-21-QUALITY-S29-INERT-NOT-CONTAINS
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 3104205)
- **Finding:** `tests/scenarios/session.yaml::S29` carries `not_contains: TRANSITION: S17`, but the real mis-fire (an unwanted handoff) surfaces as a written `.session.md` / "Handed off" string — already guarded by the sibling `not_contains` lines. The `TRANSITION: S17` guard is near-inert (session-handoff rarely emits a structured token in this prose-behavior path). Not wrong, just lower-signal than its prominence suggests.
- **Pickup shape:** optional — drop the `TRANSITION: S17` line from S29's `not_contains` (or replace with a stronger `.session.md`-side anchor). Low value; leave unless touching S29 for another reason. **Verify against the current S29 block first.**

---

# wp7j-replay-invite-brownfield-git-safety — 2026-07-23

<!-- 3 MINOR findings from feature-review-quality, ship f90446d (drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. All three are coherence/housekeeping seams, not behavior bugs. Verify each against the real code before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-23-QUALITY-WP7J-FLOWDOC-ARM-NARRATE-SEAM
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship f90446d)
- **Finding:** `docs/lessons/tutorial-tour-session-chain-flow.md` (declared authoritative) says the pedagogical point is that the user *actually crosses real session boundaries* "**not by narrating it**," and its session-table places handoff (B) / restore+graduate (C) / replay (D) as strictly separate real sessions. But both arms' Step 7 (`skills/tutorial-greenfield-workflow-tour/SKILL.md:265`, `skills/tutorial-brownfield-workflow-tour/SKILL.md:202`) explicitly permit the opposite as a fallback: "If they'd rather not break the tour flow, narrating the reset makes the point too." A future editor reconciling the two won't know which wins on that beat.
- **Suggested action (HYPOTHESIS — verify against the code):** add a one-line note to the flow doc acknowledging the in-place-narration fallback as a deliberate concession (or a note in the arm that it's a concession to the flow doc's do-for-real ideal). Prose-only; no behavior change.
- **Pickup shape:** trivial note; fold into WP7e (which codifies the tour) or a `/util-backlog-paydown` sweep. **This is the operator-facing "narrate vs do-for-real" tension — WP7e's codify charter may want to settle it explicitly.**

## SURFACE-2026-07-23-QUALITY-WP7J-WBS-STALE-CHECKBOXES
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship f90446d)
- **Finding:** `workflow-system/product/wbs.md:296-299` — WP7j checklist items 7j.3–7j.6 are still `[ ]` unchecked at the ship SHA, though 7j.5 (scaffold re-home) and 7j.6 (spec reflection) were completed *in the ship commit itself*. Stale planning-tracker checkboxes make the wbs unreliable as a progress record.
- **Suggested action (HYPOTHESIS — verify against the code):** tick 7j.3–7j.6 `[x]` (all shipped in f90446d). **Likely resolved at `/product-finalize` when the wbs is resynced on M11 completion — verify then and only backlog-carry if still stale.**
- **Pickup shape:** trivial checkbox ticks; natural fold-in at product-finalize's wbs resync, or WP7e.

## SURFACE-2026-07-23-QUALITY-WP7J-GITSAFETY-CONVERGENCE-EDGECASE
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship f90446d)
- **Finding:** `skills/tutorial-getting-started/SKILL.md:96-108` — the brownfield git-safety branch offers a "safe copy (`cp -r`/fresh clone)" or "different, less precious project" escape hatch, but the convergence line at ~L107 asserts "Both paths converge on the same next move: you'll `/exit` and relaunch in **this directory**." If the user took the safe-copy/different-project branch, "this directory" is no longer the tour target (they'd need to `cd` to their chosen alternative first).
- **Suggested action (HYPOTHESIS — verify against the code):** soften the convergence line (e.g. "relaunch in the directory you chose to work in") so it doesn't silently assume the user stayed in the original repo. Rare branch; trivial 1-line fix.
- **Pickup shape:** trivial 1-line copy tweak; fold into WP7e or the operator's hands-on run.

# greenfield-tour-cwd-sample-and-close-restructure — 2026-07-25

<!-- 5 MINOR findings from feature-review-quality, ship 783bdf2 (drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 2 MAJOR. **The 2 MAJORs were FIXED IN-FEATURE, not backlogged** (spec beat-table resync + a test assertion that bypassed the real store path) — both would have corrupted the artifact WP7e is chartered to pin against, so deferring them was not viable; see the WIP's `## Code-Quality Review` for the fix record. The 5 below are compression residue: pointers that inverted direction, a rule that doesn't account for the element it now contains, garden-path phrasing, a stale duplicate WIP line. Verify each against the real code before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-25-QUALITY-WP7N-BLOCK-MEMBERSHIP-AMBIGUOUS
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 783bdf2)
- **Finding:** `skills/tutorial-greenfield-workflow-tour/SKILL.md` — the `Next Step:` block's own rules say "**It is the last thing you emit.** No further prose, no sign-off paragraph" and "details go above it, options go in it", but the `Housekeeping:` cleanup offer sits *inside* the block after the last option and is neither an option nor a detail. A later line adds "The one exception is the cleanup offer: if they say yes, delete the sample, then stop," reintroducing a post-block action the rules just forbade. Individually correct, collectively ambiguous about block membership.
- **Why it matters:** this is the *same* structural ambiguity that made a sentence-counter falsely report 5/4 sentences where truth was 3/2 (recorded in the WIP verify-auto note). It will break a naive WP7e pin the same way.
- **Suggested action (HYPOTHESIS — verify against the code):** add one reconciling clause naming the cleanup offer as a distinct trailing element of the block (not an option), and state explicitly that acting on it is the only permitted post-block action. Prose-only.
- **Pickup shape:** trivial clause; **best folded into WP7e's copy-freeze** — settle it before pins freeze, don't just caveat it.

## SURFACE-2026-07-25-QUALITY-WP7N-MECHANICS-POINTER-INVERTED
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 783bdf2)
- **Finding:** `skills/tutorial-greenfield-workflow-tour/SKILL.md` — the block's mechanics note says the compressed mechanics "are the same mechanics spelled out above," but after the WP7n restructure they are no longer spelled out above: the narrative now only *names* them and points *forward* to the block as where they live. The pointer inverted direction during compression.
- **Why it matters:** an agent following "spelled out above" hunts for a fuller statement that no longer exists, and may re-expand the narrative the restructure deliberately compressed — undoing WP7n.
- **Suggested action (HYPOTHESIS — verify against the code):** reword to "these are the mechanics, compressed — the narrative above only names them" (or similar). One-line prose fix.
- **Pickup shape:** trivial; fold into WP7e's copy-freeze.

## SURFACE-2026-07-25-QUALITY-WP7L-GREENFIELD-EXIT-ORDER
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 783bdf2)
- **Finding:** `skills/tutorial-greenfield-workflow-tour/SKILL.md` — Branch A option 1 reads "`/exit`, `mkdir` a new empty folder and `cd` into it", but `/exit` terminates the session, so the two following commands can't run in the session where the instruction is being read. The brownfield equivalent sequences it correctly (`git stash` → `/exit` → run the arm).
- **Why it matters:** cosmetic ordering, but it is a first-run user's LAST on-screen instruction, and it currently reads as "exit, then do two things in the session you just exited."
- **Suggested action (HYPOTHESIS — verify against the code):** reorder to "`mkdir` a new empty folder, `cd` into it, then `/exit` and run the arm in a fresh session there" — matching brownfield's sequencing.
- **Pickup shape:** trivial reorder; fold into WP7e's copy-freeze (it is user-facing copy, so it should be operator-accepted before pins).

## SURFACE-2026-07-25-QUALITY-WP7L-GITSAFETY-RATIONALE-GARDEN-PATH
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 783bdf2)
- **Finding:** `skills/tutorial-getting-started/SKILL.md` — the strengthened greenfield-needs-no-git-safety rationale contains a self-contradictory clause as phrased: "in an **empty** directory it refuses to write into if anything is already there" — it cannot be both empty and already contain something. Intent (it refuses non-empty dirs, so it only ever writes into empty ones) is recoverable but needs a re-read.
- **Why it matters:** this is the exact sentence the DEFERRED verify-human checklist item 1 asks the operator to judge for firmness-without-bureaucracy. Worth fixing before that read rather than during it.
- **Suggested action (HYPOTHESIS — verify against the code):** split into two clauses — "it only ever writes into an empty directory; if anything is already there it refuses." One-line fix.
- **Pickup shape:** trivial; **fix before the deferred acceptance read** if convenient, else fold into WP7e.

## SURFACE-2026-07-25-QUALITY-WIP-DUPLICATE-OPEN-DISCOVERIES
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 783bdf2)
- **Finding:** `workflow-system/state/wip/greenfield-tour-cwd-sample-and-close-restructure.md` `## Current Node` carried two `- **Open discoveries:**` lines with divergent contents (one "3 entries", one "one `[SHORTCUT-...]` audit entry"). The Work Tree schema defines exactly one.
- **Why it matters:** Current Node is declared authoritative and read-first on every skill entry; a duplicated field with divergent counts leaves "which wins" undefined for the next reader. Same leaf-substitution-vs-insertion failure mode as the orphaned verify leaves already logged in this WIP's `## Discoveries`.
- **Suggested action (HYPOTHESIS — verify against the code):** delete the stale line, keep the accurate one. **Note: fixed in-feature at review time** — retained here only as the record that the WIP-editing failure mode recurred twice in one feature (a signal about long autopilot runs with many sequential WIP edits, worth watching rather than acting on).
- **Pickup shape:** already fixed; keep as a data point for whether a WIP-edit lint is worth building.
