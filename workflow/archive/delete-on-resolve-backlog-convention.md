# Feature: Delete-on-resolve backlog convention

**Workflow:** feature
**State:** COMPLETED
**Created:** 2026-07-15
**Completed:** 2026-07-15
**Entry:** spec (complex feature)
**drive_mode:** autopilot

## Problem Statement

Resolved backlog items keep a `Status: resolved …` line in `workflow/backlog.md` and `workflow/backlog-quality-findings.md` rather than being deleted, so a resolved SURFACE still renders as a `## SURFACE` heading in the active backlog. This has two bad consequences: (1) the same resolved-entry clutter that a backlog-paydown sweep deletes at its start keeps **regenerating** (≈13 resolved-status entries were sitting in the two files immediately after the 2026-07-13 sweep wrapped), and (2) it **duplicates** the `CHANGELOG.md` paper trail — the CHANGELOG convention already declares CHANGELOG *the* canonical resolved-item record ("Resolved backlog items belong in CHANGELOG, not in a `## Resolved` section inside `workflow/backlog.md`", arch.md §CHANGELOG convention), yet the backlog files retain a parallel resolved trail.

The fix closes the loop the existing convention left open: closing skills already *append* the resolved record to CHANGELOG but only *mark* (never delete) the backlog entry. Make the resolve operation **delete the backlog entry**, gated by a **CHANGELOG-then-delete hard invariant** so the paper trail is never lost. Origin: `SURFACE-2026-07-14-RESOLVED-ENTRY-AUDIT-TRAIL-CLUTTER`.

## User Stories

- As the operator, when a feature/task/incident/product-cycle closes and resolves a backlog item, I want the resolved `## SURFACE` block **deleted** from the backlog file (not marked) so `workflow/backlog.md` shows only open work and I never re-read a done item.
- As the operator, I want a guarantee that **no backlog entry is deleted without its `**Backlog resolved:**` line landing in `CHANGELOG.md` in the same commit**, so the resolved paper trail is never silently lost.
- As the operator, I want the ≈13 already-resolved entries currently cluttering the two backlog files **cleaned up as part of this change** (each verified to have a CHANGELOG record first), so I'm not left running a manual sweep afterward.
- As a future session, I want the delete-on-resolve behavior **structurally pinned and behaviorally tested** so it can't silently drift back to mark-and-retain (per this repo's tripartite-sync discipline).

## Acceptance Criteria

The feature is done when:

1. **CLAUDE.snippet.md convention updated.** The `## CHANGELOG.md convention` → `### Append discipline (write-side rules for closing skills)` section carries a new **delete-on-resolve** write-side rule: on resolving a backlog item, the closing skill appends the `**Backlog resolved:**` CHANGELOG line **and deletes** the corresponding `## SURFACE-<ID>` block from `workflow/backlog.md` (and, for a code-quality finding, the full body from `workflow/backlog-quality-findings.md` plus its pointer-collapsed stub in `backlog.md`), staging both files in the **same commit** as the close. The **CHANGELOG-then-delete hard invariant** is stated explicitly: no backlog delete is permitted without the `**Backlog resolved:**` line landing in the same commit (parallel to the existing "Append before `git mv`" rule). The stale statement "Resolved backlog items belong in CHANGELOG, not in a `## Resolved` section" is upgraded to reflect delete-on-resolve (backlog carries **no** resolved trail at all — not even transiently).
2. **Four terminal-close skills updated.** `feature-finalize`, `task-close`, `incident-resolve`, `product-finalize` each have their "Backlog Review/Sweep" step changed from *mark status resolved* to *delete the resolved entry* (both files where applicable), and their "Append to CHANGELOG" step references the CHANGELOG-then-delete invariant. `incident-resolve`'s fast-close paths (I4 false-alarm, I7 duplicate) rarely resolve backlog items, but **if** they do, the delete fires there too (the §4b CHANGELOG append already fires on every resolve path).
3. **Partial-resolution rule honored.** An entry that is only **partially** resolved (open work remains — e.g. the current `SURFACE-2026-07-14-HARNESS-BUDGET-EXHAUSTION-LAUNDERED-AS-FLAKY` where sub-fix (b) landed but (a) is pending, and the util-backlog-paydown finding with 1 MAJOR resolved + 2 MINOR pending) is **NOT deleted** — only fully-resolved entries are deleted. The convention and skills state this explicitly. A partially-resolved entry is rewritten to describe only the remaining open work (the resolved sub-part's record lives in CHANGELOG).
4. **Buried/deferred lifecycle untouched.** The `## Buried` section of `backlog.md` and `workflow/backlog-deferred-2026-05.md` are a **different** (deferred/buried, not resolved) lifecycle and are explicitly out of scope — the delete-on-resolve rule fires only on *resolution*, never on defer/bury.
5. **Migration complete.** The ≈13 fully-resolved entries currently in `backlog.md` (4 fully-resolved SURFACEs) and `backlog-quality-findings.md` (≈11 resolved findings) are deleted, each first verified to have a corresponding `**Backlog resolved:**` (or equivalent close) record in `CHANGELOG.md`. Partially-resolved entries are rewritten (not deleted) per criterion 3. `backlog.md` post-migration contains only open TODO/MAYBE items + the Buried pointer section. `backlog-quality-findings.md` post-migration contains only pending findings (+ its header note).
6. **util-backlog-paydown scope clarified.** The skill's `Delete` disposition already covers "already resolved-along-the-way"; confirm no *codified* WP0 resolved-clutter step exists to retire (there isn't one — the "WP0 deletes clutter" was an operator-driven sweep pattern, not a skill step). The skill's disposition model needs **no functional edit**; optionally add a one-line note that with delete-on-resolve upstream, resolved-clutter should no longer accumulate for a sweep to clean. (Decide edit-vs-no-edit at plan time.)
7. **Structural pins + behavioral scenarios.** `tests/check-structure.sh` gains pins asserting each of the 4 close skills carries the delete-on-resolve instruction and the snippet carries the invariant (parallel to the existing Phase 11 close-commit `grep_check` pins). At least one behavioral scenario per applicable close workflow asserts the delete-on-resolve behavior fires (a resolved SURFACE block is deleted, CHANGELOG line present). Full structural suite passes (`./tests/check-structure.sh`).
8. **Project CLAUDE.md convention bullet.** A `## Conventions` bullet documents the delete-on-resolve convention, its origin SURFACE, the hard invariant, and the enforcement locations (mirrors the existing CHANGELOG-convention bullet style).
9. **arch.md resync.** The `### CHANGELOG.md convention — terminal-close auto-append contract` section (arch.md:319) is updated so its closing line reflects delete-on-resolve rather than the mark-and-retain-implied phrasing.

## Out of Scope

- The `## Buried` section lifecycle and `backlog-deferred-*.md` (deferred items are not resolved items — criterion 4).
- Changing the CHANGELOG entry-kind vocabulary or format (the `**Backlog resolved:**` line shape is unchanged; only the paired *delete* is added).
- The `SURFACE-2026-07-14-HARNESS-BUDGET-EXHAUSTION` (a) observability half or `SURFACE-2026-06-25-AUDIT-PROMPT-LATITUDE` proactive audit — unrelated open backlog items, not touched.
- Any change to *how items are surfaced/logged* to the backlog (the SURFACE-in side); this feature only changes the *resolve-out* side.
- Retroactively editing already-archived WIP files.

## Technical Constraints

- **No 3rd-party dependency.** Pure markdown-convention + skill-prompt + shell-structural-check change. 3rd-party probe check: N/A.
- **Tripartite-sync discipline (this repo).** A behavior change to a skill contract must land in all three: the skill prose (`SKILL.md`), the structural pins (`tests/check-structure.sh`), and the behavioral scenarios (`tests/scenarios/*.yaml`). The state machine (`transitions.md`) is **not** touched — no transitions are added/removed/reworded (this is behavior-within-existing-close-states, like the close-commit-discipline feature that added Phase-11 pins without new transitions).
- **Enforcement precedent.** The close-commit-discipline feature (shipped 2026-06-12) is the direct structural precedent: it codified pre-existing close-skill behavior as Phase-11 `grep_check` pins + `F19/T10/I10/P13` behavioral scenarios *without* new transitions. This feature follows the same shape.
- **Migration safety.** The migration phase must **verify each entry's CHANGELOG record before deleting** — the CHANGELOG uses IDs like `SURFACE-2026-06-13-QUALITY-CATEGORY-HEADING-DRIFT` that may not string-match the backlog file's section heading verbatim, so matching is by resolution *substance*, not blind grep. Any entry lacking a CHANGELOG record gets one written first (honoring the invariant) — do not delete blind.
- **Two backlog files are coupled.** A resolved code-quality finding lives as a full body in `backlog-quality-findings.md` AND a pointer-collapsed stub in `backlog.md`; resolving one means removing both.
- **Structural check runtime.** `./tests/check-structure.sh` is a tracked long-running command — consult `runtimes.md` for the timeout before running (per the Long-running-commands rule).

## Open Questions

- [ ] None blocking — the design was resolved in the pre-spec discussion (delete-on-resolve + CHANGELOG-then-delete hard invariant + migrate-existing, all operator-confirmed). Remaining choices (exact scenario shapes, whether util-backlog-paydown gets a one-line note or no edit, exact pin anchors) are **plan-time** decisions, resolved below.

## Plan-time decisions (resolved)

- **Phase order:** convention text first (source of truth) → close skills consume it → enforcement pins it → migration applies it last. This lets each later phase verify against the settled convention, and puts the highest-risk phase (migration, which deletes real content) last, after the convention is pinned.
- **util-backlog-paydown (criterion 6):** **no functional edit.** Confirmed no codified WP0 step exists to retire; the `Delete` disposition already covers "already resolved-along-the-way". Add a **one-line note** in the skill that with delete-on-resolve upstream, resolved-clutter should no longer accumulate for a sweep to clean (documents the intent so a future reader doesn't re-add a WP0-cleanup step). Folded into Phase 2 (skill edits).
- **Structural pins (criterion 7):** **extend Phase 11** (`Close-commit discipline`) with delete-on-resolve `grep_check` pins rather than a new phase — same close-skill family, same 4-skill fan-out, keeps the PASS-count sequence and Phase-12 block undisturbed (mirrors the WP-of-2026-07-13 discipline that avoided tail-phase placement). Rename the Phase 11 echo to reflect the added dimension.
- **Behavioral scenarios (criterion 7):** mirror the `F19-no-auto-push` side-effect shape — same close fixture, `system_prompt_extra` describing a *resolved backlog item present in the fixture* **neutrally** (do NOT recite "delete it" — that would test obedience not skill prose, per the prompt-leakage Context Rule), `contains_any` asserting delete-on-resolve prose ("delete", "remove the entry", "no longer in the backlog"). One scenario per applicable close workflow (F/T/I/P). Fixtures need a resolved backlog item to act on.
- **transitions.md:** NOT touched — behavior-within-existing-close-states (spec Technical Constraints).

## Work Tree

- [x] Phase 1: Convention text — CLAUDE.snippet.md + arch.md + project CLAUDE.md  <!-- status: complete -->

  **Observable outcomes:**
  - CLI: `grep -c "delete-on-resolve\|delete the.*backlog entry\|CHANGELOG-then-delete" CLAUDE.snippet.md` ≥ 1 — the new write-side rule + hard invariant are present in the `### Append discipline` section
  - CLI: `grep "CHANGELOG-then-delete\|delete the resolved" CLAUDE.snippet.md` returns the invariant statement (no backlog delete without the CHANGELOG line in the same commit)
  - CLI: `grep -c "Resolved backlog items belong in CHANGELOG" CLAUDE.snippet.md` — the stale mark-and-retain-implied phrasing is upgraded (either removed or rewritten to state backlog carries no resolved trail)
  - CLI: `grep "delete-on-resolve\|deleted on resolve" docs/product/arch.md` — §CHANGELOG convention closing line resynced
  - CLI: `grep "delete-on-resolve\|Delete-on-resolve" CLAUDE.md` — project CLAUDE.md `## Conventions` bullet present with origin SURFACE + invariant + enforcement locations
  - [x] P1.1 Add the delete-on-resolve write-side rule + CHANGELOG-then-delete hard invariant to `CLAUDE.snippet.md` → `## CHANGELOG.md convention` → `### Append discipline`; state the partial-resolution carve-out (only fully-resolved entries deleted); state both-files coupling (quality-findings body + backlog.md pointer stub); upgrade the stale "belongs in CHANGELOG, not a `## Resolved` section" line to "backlog carries no resolved trail — deleted on resolve"  <!-- status: complete -->
  - [x] P1.2 Resync `docs/product/arch.md` §CHANGELOG.md convention (line ~319-323) closing line to reflect delete-on-resolve  <!-- status: complete -->
  - [x] P1.3 Add a `## Conventions` bullet to project `CLAUDE.md` documenting the convention, `SURFACE-2026-07-14-RESOLVED-ENTRY-AUDIT-TRAIL-CLUTTER` origin, the hard invariant, partial-resolution carve-out, and enforcement locations (Phase 11 pins + F/T/I/P-delete-on-resolve scenarios)  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete: structural suite 411/0 (no regression), Phase-1 grep outcomes hold, 0 bare .claude/ introduced -->
  - [x] verify-self  <!-- status: complete: subagent reported 5/5 outcomes PASS + self-consistency PASS; no integration boundary (doc-only); in-place-fix shortcut reconciled a stale sibling sentence in project CLAUDE.md (see Discoveries [SHORTCUT-2026-07-15]) -->
  - [x] verify-human  <!-- status: complete: operator approved all 6 review items (CHANGELOG-then-delete ordering, partial-resolution carve-out, buried/deferred exclusion, two-coupled-files rule, transitions.md-untouched + util-no-edit scope, and the in-place-fix reconciliation) on 2026-07-15 -->
    - [x] P1.verify-human.1 CHANGELOG-then-delete ordering confirmed  <!-- status: complete -->
    - [x] P1.verify-human.2 partial-resolution carve-out confirmed  <!-- status: complete -->
    - [x] P1.verify-human.3 buried/deferred exclusion confirmed  <!-- status: complete -->
    - [x] P1.verify-human.4 two-coupled-files rule confirmed  <!-- status: complete -->
    - [x] P1.verify-human.5 scope (transitions.md untouched + util no-edit) confirmed  <!-- status: complete -->
    - [x] P1.verify-human.6 in-place-fix stale-sentence reconciliation confirmed  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete: no integration boundary (doc-only). Durable regression coverage for the convention is DEFERRED-BY-DESIGN to the dedicated Phase 3 (Enforcement): structural pins (P3.1, 4 close skills + snippet) + behavioral scenarios (P3.2, delete-on-resolve fires). Writing a premature Phase-1 pin would duplicate P3.1 and assert against text not yet consumed by any skill. No tests ran/failed → §3b triage N/A. Existing suite green (411/0) post-edit. -->

- [x] Phase 2: Four terminal-close skills — mark→delete + invariant + partial rule  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -l "delete\|remove the.*entry" skills/{feature-finalize,task-close,incident-resolve,product-finalize}/SKILL.md` — all 4 skills carry the delete-on-resolve instruction in their Backlog Review/Sweep step
  - CLI: each of the 4 skills references the CHANGELOG-then-delete invariant near its "Append to CHANGELOG" step (`grep -A20 "Append to CHANGELOG" <skill>` mentions delete + same-commit)
  - CLI: `grep "partial\|partially resolved" skills/{feature-finalize,task-close,incident-resolve,product-finalize}/SKILL.md` — the partial-resolution carve-out (rewrite, don't delete) is stated where relevant
  - CLI: `grep -A5 "fast-close\|I4\|I7" skills/incident-resolve/SKILL.md` — fast-close paths note the delete fires there too if a backlog item was resolved
  - CLI: `grep "delete-on-resolve\|no longer accumulate\|should not accumulate" skills/util-backlog-paydown/SKILL.md` — one-line note added (no functional disposition edit)
  - [x] P2.1 `feature-finalize` §2 Full Backlog Review: change "Update status of items resolved" → "delete the resolved item's block from `workflow/backlog.md` (+ quality-findings body & stub if a code-quality finding)"; §3c: add the CHANGELOG-then-delete invariant to the operational sequence (delete staged in the same commit as the CHANGELOG append + archive move); state the partial-resolution carve-out  <!-- status: complete -->
  - [x] P2.2 `task-close` §3 Full Backlog Review + §5 CHANGELOG: same mark→delete + invariant + partial-rule edits  <!-- status: complete -->
  - [x] P2.3 `incident-resolve` §4b CHANGELOG + resolve-path handling: same edits; explicitly note the fast-close paths (I4/I7) delete too if they resolved a backlog item (rare, but the §4b append already fires on every path)  <!-- status: complete -->
  - [x] P2.4 `product-finalize` §4 Backlog Sweep: change the "Resolved — update status" outcome to "Resolved — delete the entry"; §6b CHANGELOG: add the invariant; keep Deferred/Escalated outcomes unchanged (buried/deferred lifecycle untouched)  <!-- status: complete -->
  - [x] P2.5 `util-backlog-paydown` SKILL.md: add the one-line delete-on-resolve-upstream note (Delete disposition context); no functional change  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete: structural suite 411/0 (no regression in Phase 9/11/12), Phase-2 grep outcomes hold, 0 bare .claude/ introduced -->
  - [x] verify-self  <!-- status: complete: subagent 6/6 PASS incl. cross-skill consistency assessment — all 5 sources (4 close skills + snippet) AGREE on (a) CHANGELOG-then-delete ordering, (b) same-commit staging incl. backlog files, (c) partial→rewrite, (d) buried/deferred untouched, (e) two-coupled-files. No code integration boundary (prose contract edits). No BLOCKING. -->
  - [x] verify-human  <!-- status: complete: operator approved all 5 close-skill behavior-review items on 2026-07-15 -->
    - [x] P2.verify-human.1 feature-finalize & task-close delete+same-commit staging confirmed  <!-- status: complete -->
    - [x] P2.verify-human.2 product-finalize sweep three-outcome split (resolved=delete, deferred/escalated unchanged) confirmed  <!-- status: complete -->
    - [x] P2.verify-human.3 incident-resolve delete on every resolve path incl. fast-close, no-op if no backlog item confirmed  <!-- status: complete -->
    - [x] P2.verify-human.4 util-backlog-paydown one-line note only (no functional change) confirmed  <!-- status: complete -->
    - [x] P2.verify-human.5 CHANGELOG-then-delete ordering baked into each skill confirmed  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete: no integration boundary (prose contract edits). Durable regression coverage for the close-skill delete-on-resolve behavior DEFERRED-BY-DESIGN to Phase 3 (Enforcement): structural pins (P3.1, 4 close skills + snippet) + behavioral scenarios (P3.2, delete-on-resolve fires). Premature per-phase pin would duplicate P3.1 + hit the harness-bootstrap-skip (edited skill prose not reliably exercised mid-session). No tests ran/failed → §3b triage N/A. Suite green 411/0. -->

- [x] Phase 3: Enforcement — structural pins (Phase 11) + behavioral scenarios  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` exits 0, full suite passes (new delete-on-resolve pins included in the count)
  - CLI: `grep -c "delete-on-resolve\|delete the resolved" tests/check-structure.sh` — 4 new close-skill pins + 1 snippet pin present in the Phase 11 block
  - CLI: `grep "delete-on-resolve\|delete.*resolved backlog" tests/scenarios/{feature,task,incident,product}.yaml` — one behavioral scenario per applicable close workflow
  - CLI: the 4 new scenarios PASS via `./tests/run-tests.sh --id <new-ids>` (fresh-subprocess execution — honors the harness-bootstrap-skip caveat for edited SKILL.md content)
  - [x] P3.1 Extend `tests/check-structure.sh` Phase 11: add 4 `grep_check` pins (one per close skill, asserting the delete-on-resolve instruction, anchored on the verified string `Delete-on-resolve (CHANGELOG-then-delete`) + 1 pin on `CLAUDE.snippet.md` (anchor `CHANGELOG-then-delete hard invariant`). Renamed Phase 11 echo + header comment. All 5 pins PASS; suite 411→416/0. Anchors grep-verified to exist before pinning (hypotheses-not-specs rule).  <!-- status: complete -->
  - [x] P3.2 Add behavioral scenarios `F19-delete-on-resolve`, `T10-delete-on-resolve`, `I10-delete-on-resolve`, `P13-delete-on-resolve` mirroring the `F19/T10/I10/P13-no-auto-push` side-effect shape (neutral `system_prompt_extra` — resolved item present in fixture, NOT reciting the delete instruction, per the prompt-leakage rule; `contains_any` on delete-on-resolve prose). Added fixture `tests/fixtures/backlog/with-one-resolvable.md` (1 resolved + 1 untouched-open item). Scenario YAML integrity PASS (structural Phase 1).  <!-- status: complete -->
  - [x] P3.3 Ran `./tests/run-tests.sh --id F19,T10,I10,P13-delete-on-resolve` (fresh subprocess, haiku, 105s). Result: **3 PASS + 1 SOFT_PASS, 0 FAIL, 0 FLAKY**. The SOFT_PASS (I10-delete-on-resolve) matched the `contains_any` 'delete' assertion but haiku didn't emit a structured `TRANSITION: I10` — the documented+acceptable prose-behavior side-effect shape (same class as reflect R1/R2/R3). SOFT_PASS is a pass, not a failure → NO sonnet-tag warranted (tagging discipline: tag only on a proven haiku *failure*; haiku coverage is meaningful signal). Skill-prose behavior confirmed on freshly-edited skills.  <!-- status: complete -->
    - Note: `--dry-run` was abandoned — the runner parses ALL scenarios before applying `--id`, so even a dry-run exceeds 60s (pre-existing runner cost, not a scenario defect). Went straight to real execution.  <!-- status: note -->
    - Discovery candidate: run-tests.sh `--id` filter is applied post-parse → slow even for dry-run; potential SURFACE (runner could short-circuit parse on `--id` mismatch).  <!-- status: SURFACED: run-tests.sh --id parses all scenarios before filtering -->

  - [x] verify-auto  <!-- status: complete: structural suite 416/0 (+5 delete-on-resolve pins all PASS), scenarios 3P+1SP/0F, 0 bare .claude/ in Phase-3 test files -->
  - [x] verify-self  <!-- status: complete: subagent 5/5 outcomes PASS — check-structure 416/0 exit-0, 5 Phase-11 pins present, 4 scenarios present in group YAMLs, fixture correct, scenario-run results 3P+1SP/0F confirmed. I10 SOFT_PASS (transition_found I18) = documented prose-behavior shape, not BLOCKING. No code integration boundary (test artifacts). -->
  - [x] verify-human  <!-- status: complete: operator approved all 3 enforcement-review items on 2026-07-15 (pin adequacy, I10 SOFT_PASS untagged-haiku call, prompt-leakage neutrality) -->
    - [x] P3.verify-human.1 pin adequacy (5 pins, heading-anchor sufficient) confirmed  <!-- status: complete -->
    - [x] P3.verify-human.2 I10 SOFT_PASS acceptable + untagged-haiku call confirmed  <!-- status: complete -->
    - [x] P3.verify-human.3 scenario prompt-leakage neutrality confirmed  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete: Phase 3 IS the codification phase — the pins (P3.1) + scenarios (P3.2) ARE the codified tests; already written + passing. No new tests (would be codifying the codification). No integration boundary. Final regression check: structural suite 416/0 exit-0. Scenarios 3P+1SP/0F (from P3.3, re-confirmed at verify-self). No failures → §3b triage N/A. -->

- [x] Phase 4: Migration — delete the ~13 existing resolved entries (verify-against-CHANGELOG-first)  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -c "Status:.*resolved\|Status:.*RESOLVED" workflow/backlog.md` — 0 fully-resolved entries remain (partially-resolved entries rewritten to open work only, so no bare "resolved" status line remains)
  - CLI: `grep -c "resolved 2026\|RESOLVED 2026" workflow/backlog-quality-findings.md` — 0 (all resolved findings deleted; file contains only pending findings + header note)
  - CLI: for every deleted entry, a corresponding `**Backlog resolved:**` (or equivalent close) line exists in `CHANGELOG.md` (verified before deletion — the migration writes a CHANGELOG line for any straggler first)
  - CLI: `backlog.md` still contains the open TODO items (SURFACE-2026-07-13-STEP0-PREAMBLE, AUDIT-PROMPT-LATITUDE, etc.), the `## Buried` pointer section, and the 2 rewritten partials — nothing open lost
  - [x] P4.1 Audit complete. ALL 17 resolved entries have exactly 1 CHANGELOG record (grep-confirmed count=1 each). backlog.md fully-resolved: YAML-PARSE-PIN, ODD-SHAPE, SETTINGS-FIXTURE-DRIFT-DISABLE, PER-SCENARIO-CLAUDE-MD-FIXTURE + the `util-backlog-paydown` pointer (its 1 MAJOR + 2 MINOR ALL now resolved → the pointer's `Status: pending` is stale → DELETE, not rewrite). backlog-quality-findings.md: 11 resolved QUALITY entries → DELETE all. PARTIAL (rewrite, keep open work): SURFACE-...-HARNESS-BUDGET-EXHAUSTION (keep (a) observability half). KEEP untouched: all pending/open (incl. 3 PROPTEST + wp6 pointer), Buried, deferred.  <!-- status: complete -->
  - [x] P4.2 No-op — audit found ZERO entries missing a CHANGELOG record (all 17 recorded during the 2026-07-13/14 sweep). The CHANGELOG-then-delete invariant is already satisfied for every migrated entry; no CHANGELOG line needs writing.  <!-- status: complete -->
  - [x] P4.3 DELETED 5 blocks from backlog.md (YAML-PARSE-PIN, ODD-SHAPE, SETTINGS-FIXTURE-DRIFT-DISABLE, PER-SCENARIO-CLAUDE-MD-FIXTURE, util-backlog-paydown pointer) + 13 resolved QUALITY blocks from backlog-quality-findings.md (all CHANGELOG-confirmed). REWROTE HARNESS-BUDGET-EXHAUSTION to open (a)-only. Cleanup exposed + fixed a pre-existing mislabel: the `# claude-md-compaction` group heading in quality-findings sat above the 2026-07-03 memory-symlink findings → relabeled `# memory-location-symlink — 2026-07-03`; replaced the stale "empty — all resolved" header note with the delete-on-resolve convention note. Outcomes: 0 resolved-status lines in both files, 5 open QUALITY findings + all open backlog items + Buried section preserved, no orphaned fragments.  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete: structural suite 416/0 exit-0 (migration is backlog-data-only, no pin change, no regression); 0 resolved-status lines both files; Buried + 5 open QUALITY findings preserved -->
  - [x] verify-self  <!-- status: complete: subagent 6/6 PASS incl. the two load-bearing checks — SAFETY INVARIANT (all 7 spot-checked deleted IDs have a surviving CHANGELOG record) + NOTHING-OPEN-LOST (all open SURFACEs/pointers/Buried 8+1/5 open QUALITY preserved; HARNESS-BUDGET rewritten to open (a); group-heading mislabel fixed). Both files well-formed, no orphaned fragments. No code integration boundary. -->
  - [x] verify-human  <!-- status: complete: operator approved all 4 migration-review items on 2026-07-15 (deletion set, util-paydown-pointer delete call, partial rewrite, mislabel fix) -->
    - [x] P4.verify-human.1 deletion set correct (18 blocks, all CHANGELOG-confirmed) confirmed  <!-- status: complete -->
    - [x] P4.verify-human.2 util-backlog-paydown pointer full-delete call (stale pending status) confirmed  <!-- status: complete -->
    - [x] P4.verify-human.3 HARNESS-BUDGET partial rewrite (open (a)-only) confirmed  <!-- status: complete -->
    - [x] P4.verify-human.4 group-heading mislabel fix (→ memory-location-symlink) confirmed  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete: no integration boundary (backlog-data migration). A one-time data cleanup has no standalone regression surface — the go-forward re-accumulation-prevention is already codified by Phase 3's pins+scenarios. No new test needed. Final regression gate: structural suite 416/0 exit-0. No failures → §3b triage N/A. ALL PHASES COMPLETE → ship (F16). -->


## Current Node
- **Path:** Feature > review-quality COMPLETE > finalize
- **Active scope:** shipped (commit 449df1c, amended); review-quality found 1 MAJOR (orphaned pointer stubs) → FIXED in-place per operator, amended into ship commit; ready for /feature-finalize (F39)
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** SURFACE-2026-07-15-RUN-TESTS-ID-FILTER-PARSES-ALL-SCENARIOS-FIRST logged to backlog (low)
- **Review-quality outcome:** 1 MAJOR (migration left 4 orphaned coupled-pointer stubs — a violation of the feature's own two-coupled-files rule) fixed in-place (operator chose fix-now-amend); MINOR dissolved with the fix. No CRITICAL. No new backlog findings from this feature.

## Retrospect
- **What changed in our understanding:** The migration (Phase 4) turned out to be the riskiest part, not the convention design. Two things surfaced only at migration/review time that the plan didn't foresee: (1) a **partial-resolution** case (HARNESS-BUDGET, where (b) shipped but (a) is open) that needed *rewrite* not delete — caught at spec time and carved out; and (2) **orphaned coupled-pointer stubs** — 4 `Code-quality findings` pointers in backlog.md whose bodies had *already* been swept in the 2026-07-13 sweep, so they weren't in my body-driven deletion set but were still marked `pending`. The review-quality reviewer caught (2); the plan's audit only looked at bodies *present* in the quality file, not stubs whose bodies were already gone.
- **Assumptions that held:** The core design (CHANGELOG-as-sole-record + CHANGELOG-then-delete hard invariant) was right and needed no revision. The close-commit-discipline precedent (behavior-within-close-states, Phase-11 pins + F/T/I/P scenarios, no transitions.md change) fit exactly. The prompt-leakage-neutral scenario shape worked (3 PASS + 1 acceptable SOFT_PASS on haiku, no re-tag needed).
- **Assumptions that were wrong:** "The ~13 resolved entries" undercounted — the quality file had 13 resolved blocks (not ~11), and there were 4 *additional* orphaned stubs in backlog.md whose bodies were pre-swept. The real migration touched more than the spec's estimate. Also: a one-directional verify-self check (nothing-open-lost) can't catch nothing-resolved-*retained* — the inverse invariant. The coupling (pointer↔body) is unpinned, so green structural + green scenarios + green verify-self all passed while 4 stale stubs survived.
- **Approach delta:** Matched the plan's 4-phase shape exactly. One in-place-fix shortcut fired at Phase-1 verify-self (reconciled a stale sibling CLAUDE.md sentence). One review-quality MAJOR fixed-in-place (operator chose fix-now-amend over Mode-3 auto-backlog, because it violated the feature's OWN convention on the ship commit). Feature dogfoods itself at finalize: its origin SURFACE is the first entry ever deleted-on-resolve by the new convention.

## Communicate
> **Feature complete:** Delete-on-resolve backlog convention has shipped. Terminal-close skills now delete a resolved backlog entry on resolve (gated by a CHANGELOG-then-delete hard invariant) rather than marking it `Status: resolved`, so `workflow/backlog.md` stays open-work-only and CHANGELOG.md is the sole resolved-item record. Verify via the delete-on-resolve pins in `tests/check-structure.sh` [Phase 11] and the `*-delete-on-resolve` scenarios; the ~18-entry migration + this feature's own origin-SURFACE deletion are the first live exercises.
> Requester = operator — closure notice for self-record.

## Code-Quality Review — delete-on-resolve-backlog-convention

Reviewed against ship commit 0e9115e (drive_mode autopilot / Mode 3). Reviewer subagent output:

### Strengths
- Convention layer exemplary: snippet `### Append discipline` states the CHANGELOG-then-delete invariant + partial carve-out + two-coupled-files rule + buried/deferred exclusion, each with its why, cross-referenced from arch.md + project CLAUDE.md + all 4 skills without drift.
- Tripartite sync complete + lockstep: 5 Phase-11 pins (anchors exist exactly once) + 4 behavioral scenarios land in the same commit as the prose.
- Scenario design follows house conventions: neutral `system_prompt_extra` (tests prose not obedience), two-item fixture (selectivity), `contains_any`→SOFT_PASS for prose-behavior.
- 4 skills' operational-sequence edits internally consistent (CHANGELOG-first, backlog files in same `git add`, delete after CHANGELOG write).
- transitions.md correctly untouched (close-commit-discipline precedent); util note honestly reframes its Delete trigger as now-rare.

### Issues
**CRITICAL** — (none)

**MAJOR**
- [workflow/backlog.md] Migration deleted the *bodies* of 4 fully-resolved code-quality finding groups from backlog-quality-findings.md (design-priors, debug-minimal-harness, docker-daemon-vs-container-distinction, claude-md-compaction) but left their coupled *pointer stubs* in backlog.md — each still `Status: pending`, each still pointing at now-deleted content. Violates this feature's own two-coupled-files rule. VERIFIED: all 4 groups' bodies absent from quality-findings.md; findings confirmed resolved in CHANGELOG (design-priors 5/5, docker-daemon 1/1, claude-md-compaction 4/4); debug-minimal-harness has 1 resolved (round-threshold, CHANGELOG) + 1 BURIED (GATE-MET-idiom, in backlog-deferred-2026-05.md). Recovery = delete the 4 stale stubs from backlog.md. — Reviewer classified MAJOR (advisory); operator-surfaced (see below) because it's a violation of the feature's OWN rule caught on the ship commit, not ordinary debt.

**MINOR**
- [workflow/backlog.md] Once the 4 stale stubs are removed, the wp6 pointer (correctly retained, 3 open PROPTEST) is the only remaining code-quality pointer and whole-file coupling is consistent again. Dissolves with the MAJOR fix.

### Assessment
Well-built convention feature — sound design (CHANGELOG-as-sole-record + commit-atomicity invariant), clear prose propagated across 5 docs + 4 skills, enforcement landed atomically following every house convention. The one blemish is in the *migration*, not the mechanism: the coupled-pointer-delete rule was applied to bodies but overlooked for 4 pointer stubs whose bodies had already been swept on 2026-07-13. Green verification missed it because coupling is unpinned and the verify-self check was one-directional (nothing-open-lost, never nothing-resolved-retained). Cheap fix.

### If you disagree
Operator: dismiss a finding by editing this section and marking the line `[DISMISSED]` before finalize archives the WIP.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
[SURFACED-2026-07-15] feature-spec — docs/product/arch.md exceeds size guard (381 lines), read first 100 lines + headings per the 300-line guard. Relevant section (§CHANGELOG.md convention, line 319) read in full for grounding.
[SHORTCUT-2026-07-15] P1.3 — verify-self subagent surfaced that the pre-existing project-CLAUDE.md "Per-project CHANGELOG.md convention" bullet (line 237) still carried the OLD stale closing sentence ("Resolved backlog items belong in CHANGELOG, not in a `## Resolved` section") describing the mark-and-retain posture my new bullet supersedes. Applied in-place fix (in-place-fix-shortcut §3): trivial one-sentence reconciliation in the same file/section as the just-written P1.3 bullet → rewrote it to state delete-on-resolve (backlog carries only open work, no Status:resolved line). Re-verified via fresh grep (old sentence count 0, reconciled phrasing present) + structural suite 411/0. Same-file self-consistency, not a new scope.
