---
workflow: feature
state: ship (complete)
created: 2026-06-11
drive_mode: autopilot
entry: spec (complex feature)
origin: SURFACE-2026-06-09-TASK-WORKFLOW-NEEDS-LITE-VERIFY
shipped_commit: 7073fde
shipped_date: 2026-06-11
---

# Feature: task-workflow-needs-lite-verify

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-06-11
**Entry:** spec (complex feature)

## Problem Statement

The task workflow (`plan → act → close`) has no verify gate. The implicit assumption that "task = atomic = no verify needed" is empirically wrong — on 2026-06-09, task `run-all-unbound-forward-args` planned as a 2-line shell fix shipped through `task-act → task-close` cleanly even though the script still didn't run end-to-end. A masked sibling `set -o pipefail` + SIGPIPE bug at lines 43+50 only surfaced because the user mid-act over-rode the plan's narrow `--dry-run` verification with "make sure the test still works after the change before closing." Without that operator override, a still-broken script would have shipped with a passing close.

This is a structural gap, not an operator failure. The workflow currently depends on the user catching the right moment with the right directive. A workflow-level fix removes that dependency — and removes the latent risk for every task in every project using this workflow harness.

## User Stories

- **As the operator running tasks in autopilot mode**, I want the task workflow to verify the fix actually works before close, so I don't have to mid-stream the right directive at the right moment.
- **As a future-me reviewing a closed task**, I want the WIP's archive record to contain an observable + verification result, so I can grep "what evidence existed that this task fixed the bug?" without re-reading the CHANGELOG or the commit.
- **As an agent driving the task workflow**, I want a verify state that asks me one question in writing ("what observable confirms this?") before running anything, so I commit to a verification surface instead of defaulting to a proxy (`--dry-run`, compile-check, "looks right to me").

## Acceptance Criteria

The feature is done when:

1. A new skill `skills/task-verify/SKILL.md` exists with the canonical SKILL.md shape (frontmatter `name`/`description`/`argument-hint`; sections for State Machine Context, Orchestrator Pause Policy cheat-sheet, Procedure, Termination/Emit Transition).
2. The task workflow state machine has three new transitions in `docs/product/transitions.md`:
   - **T5a:** `act → verify` (replaces the old `T5: act → close`; act always exits to verify)
   - **T5b:** `verify → close` (PASS — verification confirmed the fix)
   - **T5c:** `verify → act` (FAIL — scope-restricted back-loop, analogous to F9b)
   - Old **T5** (`act → close`) is retired; the row in transitions.md is rewritten, not duplicated.
3. The task workflow pause-policy table in `docs/product/transitions.md` § "Pause policy by mode — task workflow" gains a `verify` row with PAUSE/AUTO entries per mode (proposed: PAUSE/AUTO/AUTO/AUTO mirroring `verify-self` policy).
4. `skills/task-act/SKILL.md` is updated: its "Valid transitions from here" lists T5a (→ verify) instead of T5 (→ close); its §7 "Completion" tells the user to run `/task-verify` instead of `/task-close`.
5. `skills/task-close/SKILL.md` is updated: §1 "Find Active Plan" gains an entry precondition check — task-verify must have completed PASS before close proceeds (advisory note in skill prose; not a hard block).
6. `agents/task-workflow/AGENTS.md` is updated: `skills:` frontmatter list gains `task-verify`; the orchestration procedure adds task-verify between act and close.
7. `tests/scenarios/task.yaml` gains at least:
   - **T5a scenario**: act fixture → asserts `transition_id: T5a` and contains `/task-verify`.
   - **T5b scenario**: verify fixture (observable + PASS evidence) → asserts `transition_id: T5b` and contains `/task-close`.
   - **T5c scenario**: verify fixture (FAIL evidence) → asserts `transition_id: T5c` and contains `/task-act` with scope-restriction language.
8. `tests/check-structure.sh` gains structural pins on the new skill: SKILL.md presence, frontmatter fields, required sections (State Machine Context, Orchestrator Pause Policy cheat-sheet, Procedure, emit-transition discipline). Expected PASS-count delta: +5 to +8 pins.
9. `tests/fixtures/wip/` gains three new fixtures backing the three new scenarios (act-complete-needs-verify, verify-pass, verify-fail).
10. CLAUDE.md's `## Conventions` section gets a one-line pointer noting task-verify exists and points to the SKILL.md for full procedure.
11. `./tests/run-tests.sh --group task` PASSes strictly on all task scenarios (old + new) on the new skill's default model (haiku unless empirically proven to need sonnet per the standard recon protocol).
12. `./tests/check-structure.sh` PASSes (current 178 PASS expected to rise by the +5 to +8 from item 8).

## Out of Scope

- **No re-architecting of `task-act` or `task-close`.** This is an additive state; existing skills are minimally updated (transitions list + completion-hand-off prose only).
- **No new debug-* sidebar.** task-verify is a workflow state, not a debug technique. It runs every act → close path; it is not agent-pulled.
- **No 5-leaf verification chain.** This is the explicit non-goal called out in the learning draft — tasks are atomic; the full `verify-auto → verify-self → verify-human → verify-codify` ceremony is overhead, not signal. task-verify is a single step.
- **No Observable Outcomes at plan time.** The observable is declared at verify time, inline. (See Open Question 3 — plan-time vs verify-time. Resolution: verify-time; see rationale in Technical Constraints.)
- **No retroactive update of archived tasks.** Existing archived task WIP files retain their old T5 history; the new transitions only apply to tasks plan-or-started on/after this feature ships.
- **No incident-workflow or product-workflow changes.** The verify gap is task-specific; incident-codify and feature-verify-codify already exist as the parallel mechanisms at their levels.
- **No verify-codify-equivalent at task scope.** Test-coverage codification is a feature-level concern; tasks that need regression coverage should escalate via T9 → feature:spec.

## Technical Constraints

- **State-machine peer rule (arch.md Revision 2026-04-27 §3):** "Task workflow is a peer entry point, not a sub-workflow." This feature extends the task workflow internally — it does not delegate downward or create cross-level dependencies. SURFACE/ESCALATE remain one-way upward.
- **Advisory-enforcement convention (transitions.md §Design Principles):** State transitions are advisory, not hard-blocked. task-verify's entry precondition for task-close is documented in prose, not enforced by a hook.
- **Work Tree format (CLAUDE.snippet.md / arch.md File Schema):** task-verify reads + updates Work Tree nodes via the same conventions as task-act. The new skill must read `## Current Node` first, attach SURFACED discoveries correctly, and update Current Node on exit.
- **Plan-time observable declaration was tested and found wanting** (per learning draft Open Question 3): the 2026-06-09 task's plan *did* state a verification, but stated it too narrowly. So plan-time declaration is not the bottleneck — verify-time commitment-to-observable forces the planner to face the question with full implementation context. **Resolution: verify-time, not plan-time.**
- **In-place fix shortcut precedent (`skills/feature-verify-self/SKILL.md` §3 "In-place fix shortcut"):** SURFACED-sibling-bug handling at task-verify must mirror this shape — trivial extension + fresh re-verification + audit-trail entry. Don't re-invent the policy.
- **CHANGELOG convention (CLAUDE.snippet.md):** the close skill (not the verify skill) owns CHANGELOG append. task-verify writes verification evidence into the WIP file; task-close reads it and includes it in the closure entry if relevant.
- **No 3rd-party probe required.** This feature touches no external APIs — pure workflow-state-machine extension.

## Open Questions

These were enumerated in the learning draft; the spec resolves the load-bearing ones and surfaces the rest for planning.

- [ ] **OQ-1 (resolved here):** Should task-verify support an auto-skip path when the task is a pure-docs edit (no code changes, nothing to run)?

  **Resolution:** **Yes, with explicit gate.** Add a `docs-only: true` declaration at plan time (in `task-plan` SKILL.md output). When task-verify sees this declaration in the WIP frontmatter, it emits a special PASS transition (proposed: T5b with a "docs-only auto-skip" annotation in the verification block) without running any verification. Rationale: even docs edits have a verification ("markdown renders, link resolves"), but in autopilot Mode 3 the ceremony cost exceeds the bite probability. The explicit gate (`docs-only: true` must be declared at plan time, not inferred at verify time) prevents accidental auto-skip on code tasks. The gate is the discipline; the auto-skip is the convenience.

- [ ] **OQ-2 (resolved here):** How does task-verify interact with T7/T8 SURFACE? If verify surfaces something bigger than the task scope, does it escalate via T9 or just SURFACE-to-backlog and continue?

  **Resolution:** **SURFACE-to-backlog and continue is the default.** task-verify is a verification gate, not a re-planning step. If it surfaces a sibling-bug that's a trivial in-scope extension (per the in-place-fix-shortcut shape), it auto-absorbs. If it surfaces something out of scope, it SURFACEs to backlog (analogous to T7 from act) and proceeds with the verification of the original observable. **Exception:** if the sibling-bug invalidates the task's own observable (the verification can no longer be performed at all), escalate via T9 → feature:spec. This is the rare case; the default is SURFACE+continue.

- [ ] **OQ-3 (resolved here):** Plan-time vs verify-time observable declaration?

  **Resolution:** **Verify-time.** Empirically, plan-time declaration didn't prevent the 2026-06-09 failure mode — the plan stated a verification, just too narrowly. The bottleneck is *commitment to an observable with full implementation context*, which only exists after task-act runs. Verify-time is also lower ceremony (the planner doesn't have to predict the right observable; they just have to commit to one when they get there). The verify skill's first procedure step writes the observable into the WIP file before running anything — this forces the commitment.

- [ ] **OQ-4 (deferred to planning):** Drive-mode pause-policy for task-verify — proposed PAUSE/AUTO/AUTO/AUTO (mirroring `feature-verify-self`)?

  **Why deferred:** The proposal mirrors the closest analog (verify-self), but task-verify is a single-step skill (not in a 5-leaf chain), so the pause-policy semantics differ slightly. Resolve at plan time by drafting the exact pause-policy table row and checking against the existing task-workflow row's tone (today: plan PAUSE/PAUSE/AUTO/AUTO, act PAUSE/AUTO/AUTO/AUTO, close PAUSE/PAUSE/AUTO/AUTO). The verify row should probably follow act's pattern (PAUSE/AUTO/AUTO/AUTO) because verify is reading + writing the same WIP, not asking for human review.

- [ ] **OQ-5 (deferred to planning):** Scope-restriction shape for T5c (verify → act FAIL back-loop). Does T5c pass a "failed observable" identifier (like F9b passes leaf IDs)?

  **Why deferred:** Tasks don't have leaf IDs in the same way feature phases do — task Work Trees are flatter (T1, T2, ... at one level). The T5c back-loop probably passes the observable text itself ("verify the script runs end-to-end against `./tests/run-all.sh --group debug`") as the scope marker, not an ID. Resolve at plan time by reading 2-3 archived task WIPs to confirm the Work Tree shape and the right scope-marker form.

- [ ] **OQ-6 (deferred to planning):** What is the relationship between task-verify's observable-statement and feature-verify-self's "live-system observation"? Does task-verify spawn a subagent like verify-self does, or does the parent run the verification inline?

  **Why deferred:** task-verify is a single-step skill at task scope; it probably doesn't need Playwright. Most task verifications are CLI invocations or simple HTTP curl checks. The parent running the verification inline is simpler and avoids the one-shot subagent's `argument-hint: <dev-url>` requirement. Resolve at plan time — propose parent-inline by default with optional Playwright fallback declared via `allowed-tools` if a task needs browser verification.

## Plan-time resolutions for deferred OQs

The three deferred OQs (OQ-4/5/6) are resolved here at plan time, per orchestrator direction. No further deferrals to build.

- **OQ-4 (pause policy for task-verify):** **PAUSE/AUTO/AUTO/AUTO** — same row shape as `task-act`. Rationale: verify reads + writes the WIP file without asking for human review; it's a verification gate, not a confirmation gate. Mirror's act's pause policy (not close's), because close already pauses in Mode 2 and adding another pause there would double-pause the workflow end. The row goes into `docs/product/transitions.md` § "Pause policy by mode — task workflow" between act and close.

- **OQ-5 (T5c scope-restriction marker):** **The failed observable text itself.** Tasks have flat Work Trees (T1/T2/...) — no per-leaf-ID semantics like feature phases. There's one observable per verify run. The T5c back-loop message names the observable explicitly: `"Verify failed: <observable text>. Back-loop to /task-act to fix the underlying issue before re-running verify."` task-act then scope-restricts its work to the observable's failure mode, the same way F9b scope-restricts to leaf IDs.

- **OQ-6 (parent-inline vs subagent verification):** **Parent-inline by default.** Most task verifications are CLI invocations (`./tests/foo.sh`, `make test`, `python -m mymodule`) or simple HTTP curl checks. The parent can run these directly via Bash. Skill `allowed-tools` will be `Read, Bash, Edit, Grep, Glob` — no Playwright. Tasks that genuinely need browser verification almost certainly belong at feature scope (T9 ESCALATE is the right route for that). Trade-off accepted: task-verify can't verify browser-only behavior; the workflow-system signal is "if you need that, this isn't a task."

## Work Tree

- [x] Phase 1: New skill + state-machine docs  <!-- status: complete (all impl + 4 verify nodes [x]) -->
  **Observable outcomes:**
  - CLI: `ls skills/task-verify/SKILL.md` returns the file (exit 0).
  - CLI: `head -5 skills/task-verify/SKILL.md` shows YAML frontmatter with `name: task-verify`, `description:` containing "verify", `argument-hint:` non-empty, `allowed-tools:` list including `Bash`.
  - CLI: `grep -c "^## " skills/task-verify/SKILL.md` returns ≥ 5 (State Machine Context, Orchestrator Pause Policy cheat-sheet, Procedure, Termination, plus the canonical Step-0-free body — task skills don't require Step 0 per the existing task-act/task-close pattern).
  - CLI: `grep -E "^\| T5[abc] " docs/product/transitions.md | wc -l` returns 3 (three new transitions).
  - CLI: `grep "^| T5 " docs/product/transitions.md | wc -l` returns 0 (old T5 retired, not duplicated).
  - CLI: `grep -A1 "task-verify (T5b/T5c gate)" docs/product/transitions.md` shows PAUSE/AUTO/AUTO/AUTO pattern in the task workflow pause-policy table.
  - CLI: `grep "task-verify" agents/task-workflow/AGENTS.md | wc -l` returns ≥ 3 (skills frontmatter list + state table row + pause-policy table row).
  - [x] P1.1 Write `skills/task-verify/SKILL.md` (single-step verify skill ~120 LOC). Sections: frontmatter (name/description/argument-hint/allowed-tools), State Machine Context (T5b/T5c transitions out), Orchestrator Pause Policy cheat-sheet (mirrors task-act's row shape), Procedure (§1 Read WIP + Current Node; §2 State observable in writing; §3 Run verification; §4 Classify PASS/FAIL/SURFACED-sibling-bug; §4b In-place fix shortcut sub-clause [mirror feature-verify-self §3 three-gate shape: trivial extension + fresh re-verification + audit-trail `[SHORTCUT-<YYYY-MM-DD>]` entry]; §5 Update WIP tree; §6 Decide transition; §7 Emit Transition).
  - [x] P1.2 Update `docs/product/transitions.md` § Task workflow Transition Table: replace T5 row (`act → close`) with three new rows: T5a (`act → verify`, Always), T5b (`verify → close`, Verification PASS), T5c (`verify → act`, Verification FAIL, back-loop). Also retire references to T5 in narrative prose (search-and-replace where they appear in cross-level mechanism sections).
  - [x] P1.3 Update `docs/product/transitions.md` § "Pause policy by mode — task workflow": add new row `task-verify (T5b/T5c gate) | PAUSE | AUTO | AUTO | AUTO` between the `act` and `close` rows.
  - [x] P1.4 Update `agents/task-workflow/AGENTS.md`: add `task-verify` to the `skills:` frontmatter list; update state diagram (`Entry → plan → act → verify → close → Exit`); add row to states-and-skills table; replace T5 row in transitions table with T5a/T5b/T5c rows; add `task-verify` row to the orchestrator's pause-policy table; update Mode counts (Mode 2 happy-path pauses: now 2 → still 2 — task-verify is AUTO in Mode 2, doesn't add a pause).
  - [x] verify-auto  <!-- PASS: check-structure 178/178, task YAML dry-run 15/15 parse -->
  - [x] verify-self  <!-- PASS: all 7 observables verified inline (parent-context, no Playwright — workflow-doc feature has no live-system surface) -->
  - [x] verify-human  <!-- PASS: user approved all 7 judgment-level leaves ("all code changes look good") 2026-06-11 -->
  - [x] verify-codify  <!-- PASS: test coverage for Phase 1 deliverables is structurally placed in Phase 3 (scenarios T5a/T5b/T5c + check-structure pins P3.7). No Phase-1-specific test gap exists outside Phase 3's planned set. Codifying here would duplicate or pre-empt Phase 3 work. -->

- [x] Phase 2: Caller-skill updates + CLAUDE.md note  <!-- status: complete (all 4 impl + 4 verify [x]) -->
  **Observable outcomes:**
  - CLI: `grep "T5a" skills/task-act/SKILL.md | wc -l` returns ≥ 1 (act's Valid transitions list cites T5a, not T5).
  - CLI: `grep "T5 → close" skills/task-act/SKILL.md | wc -l` returns 0 (old T5 retired in act's prose too).
  - CLI: `grep "/task-verify" skills/task-act/SKILL.md | wc -l` returns ≥ 1 (act's §7 Completion tells user to run `/task-verify`).
  - CLI: `grep "task-verify PASSed" skills/task-close/SKILL.md | wc -l` returns ≥ 1 (close's §1 precondition prose mentions task-verify must have PASSed; advisory).
  - CLI: `grep "docs-only:" skills/task-plan/SKILL.md | wc -l` returns ≥ 1 (task-plan supports the `docs-only: true` plan-time gate for OQ-1 auto-skip).
  - CLI: `grep "task-verify" CLAUDE.md | wc -l` returns ≥ 1 (Conventions block has the new bullet).
  - [x] P2.1 Update `skills/task-act/SKILL.md`: replace T5 row in Valid transitions list with T5a (act → verify). Update §7 "Completion" to tell user to run `/task-verify` instead of `/task-close`. Bonus: added TRANSITION: discipline (was missing). (~12 LOC delta.)
  - [x] P2.2 Update `skills/task-close/SKILL.md` §1 "Find Active Plan": add advisory precondition note ("task-verify should have PASSed before close runs — if you're here directly from /task-act, the workflow is mid-stream; recommend running /task-verify first"). Added T5b context to State Machine Context. (~4 LOC delta.)
  - [x] P2.3 Update `skills/task-plan/SKILL.md`: add `docs-only:` plan-time gate documentation. Added to the WIP template a `docs-only: false` frontmatter line under YAML, with prose explaining that `true` enables task-verify auto-skip for pure-docs tasks. (~12 LOC delta.)
  - [x] P2.4 Update `CLAUDE.md` `## Conventions` section: added one bullet citing task-verify, the T5a/T5b/T5c transitions, docs-only gate, and feature-verify-self mirror reference. (~3 LOC delta.)
  - [x] verify-auto  <!-- PASS: check-structure 178/178, task YAML dry-run 15/15 parse -->
  - [x] verify-self  <!-- PASS: all 6 observables verified inline (parent-context, no Playwright — workflow-doc feature has no live-system surface) -->
  - [x] verify-human  <!-- PASS: user approved all 5 judgment-level leaves ("all pass") 2026-06-11 -->
  - [x] verify-codify  <!-- PASS: test coverage for Phase 2 caller-skill behaviors is structurally placed in Phase 3 (P3.1 T5→T5a rename + P3.7 CLAUDE.md citation pin). No Phase-2-specific gap outside Phase 3's planned set. -->

- [x] Phase 3: Test coverage (scenarios + fixtures + structural pins)  <!-- status: complete (all 8 impl + 4 verify [x]) -->
  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` exits 0, PASS count = previous 178 + new pins (expected +5 to +8, target 183-186).
  - CLI: `./tests/run-tests.sh --group task --dry-run` lists all task scenarios including new T5a/T5b/T5c rows.
  - CLI: `./tests/run-tests.sh --group task --id T5a` PASSes strictly (act fixture with all-complete WIP → emits TRANSITION: T5a + mentions /task-verify).
  - CLI: `./tests/run-tests.sh --group task --id T5b` PASSes strictly (verify fixture with observable + PASS evidence → emits TRANSITION: T5b + mentions /task-close).
  - CLI: `./tests/run-tests.sh --group task --id T5c` PASSes strictly (verify fixture with FAIL evidence → emits TRANSITION: T5c + mentions /task-act + scope-restriction language).
  - CLI: `./tests/run-tests.sh --group task` PASSes the full suite (all existing scenarios still pass after T5 → T5a rewrite).
  - CLI: `ls tests/fixtures/wip/task-act-complete-needs-verify.md tests/fixtures/wip/task-verify-pass.md tests/fixtures/wip/task-verify-fail.md` returns all 3 files.
  - [x] P3.1 Rewrite existing T5 scenario in `tests/scenarios/task.yaml`: renamed id `T5` → `T5a`; assertion `transition_id: T5a`; `contains_any: [/task-verify]`. T5a PASSed strictly in real run.
  - [x] P3.2 Added new T5b scenario: skill `task-verify`, fixture `task-verify-pass.md`, expect `transition_id: T5b` + `contains_any: [/task-close]`. PASSed strictly.
  - [x] P3.3 Added new T5c scenario: skill `task-verify`, fixture `task-verify-fail.md`, expect `transition_id: T5c` + `contains_any: [/task-act]`. PASSed strictly.
  - [x] P3.4 Existing fixture `task-act-complete.md` unchanged — T5a scenario uses it correctly (verified via real run).
  - [x] P3.5 Created `tests/fixtures/wip/task-verify-pass.md`: WIP in `state: verify` with Observable + PASS Verification Result sections.
  - [x] P3.6 Created `tests/fixtures/wip/task-verify-fail.md`: WIP in `state: verify` with Observable + FAIL Verification Result sections.
  - [x] P3.7 Added 7 structural pins to check-structure.sh covering: SKILL.md existence + frontmatter, State Machine Context section, T5b/T5c citation, Orchestrator Pause Policy cheat-sheet section, SHORTCUT-token convention, CLAUDE.md citation, task-act TRANSITION: T5a emission. **178 → 185 PASS (+7), 0 FAIL.**
  - [x] P3.8 End-to-end test sweep: `check-structure.sh` 185/185 PASS; `run-tests.sh --group task --filter-model default` 11 PASS / 4 SOFT_PASS / 1 FAIL / 1 FLAKY / 17 total. **All 3 new scenarios PASSed strictly.** T2 FAIL triaged → high-confidence code-regression of EXISTING marginal scenario → sonnet-tagged per CLAUDE.md convention → confirmed PASSing on sonnet (FLAKY → PASS on retry, matches historical). The 4 SOFT_PASS + 1 FLAKY are pre-existing haiku-noise on marginal scenarios (already in scope of SURFACE-2026-06-09-F16-TRIAGE-AMBIGUOUS-FLAKY-SOFT-PASS-ON-SONNET); not regressions of new work.
  - [x] verify-auto  <!-- PASS: check-structure 185/185 (178 + 7 new pins), task --dry-run 17 scenarios enumerate, real-run T5a/T5b/T5c all PASS strict -->
  - [x] verify-self  <!-- PASS: all 7 observables verified inline; T5a/T5b/T5c strict-PASS confirmed in JSON (haiku, 1 attempt each, ~32s total). 3 fixtures exist. No regressions of new work. -->
  - [x] verify-human  <!-- PASS: user approved all 5 judgment-level leaves including the T2 sonnet-tag triage decision ("all pass") 2026-06-11 -->
  - [x] verify-codify  <!-- PASS: Phase 3 IS the codification phase — all behaviors covered by T5a/T5b/T5c scenarios (strict-PASS in build P3.8) + 7 check-structure pins (185/185). T2 already triaged + resolved. No additional tests needed. All phases complete. -->

## Retrospect

- **What changed in our understanding:** Plan-time documentation prose can be load-bearing for *test classification*, not just for *agent procedure*. The Phase 2 P2.3 addition to task-plan/SKILL.md (the ~14-line `docs-only:` documentation block) didn't change the skill's procedure for the loading-spinner input — but it changed haiku's classification of that input from T2 → T3 by adding prominent prose that competed with the small/simple-task routing signal. Test triage caught it; CLAUDE.md's "haiku-marginal classification call → sonnet-tag" convention resolved it. **The convention is more load-bearing than I'd realized.**

- **Assumptions that held:**
  - Three-phase boundary (state-machine docs → caller-skills → tests) was correct — no phase-boundary regrets.
  - Verify-time observable declaration (OQ-3 resolution) is the right call — the new task-verify SKILL.md's §2 "State the observable in writing" reads naturally and the T5b/T5c fixtures demonstrate the discipline well.
  - Mirroring `feature-verify-self` §3 in-place fix shortcut for SURFACED-sibling-bug handling — three-gate pattern transferred cleanly to task scope.
  - Parent-inline verification (OQ-6 resolution) — no Playwright needed; all 3 new scenarios PASSed on haiku via simple CLI fixtures.
  - LOC estimate (~330-450) matched actual (+333) within 10%.

- **Assumptions that were wrong:**
  - **Adding documentation prose doesn't break tests** — wrong. The P2.3 `docs-only:` documentation introduction broke T2 on haiku. CLAUDE.md's "Plan-time downstream-contract-impacts grep" convention focuses on contract changes; this was a *prose-change-as-contract-change* failure mode the convention doesn't explicitly call out. Worth filing if it happens again (rule-of-two not yet reached, but the pattern is real).
  - **All 3 phases would be smooth** — wrong. Phase 3 hit a real test triage event mid-stream. Triage flow worked exactly as designed (classify → high-confidence → resolve), but it was the first real test-triage-of-existing-scenario event in this session's autopilot runs.

- **Approach delta:**
  - Plan said "3 phases, ~3 fixtures." Actually 3 phases, 3 fixtures (1 existing + 2 new), 1 sonnet-tag addition on T2. The sonnet-tag was unplanned but in-scope (it's part of the same Phase 3 test-coverage work).
  - Plan resolved OQ-4/5/6 inline at plan time per user direction. All 3 resolutions held through implementation — no re-litigation, no surprises.
  - Zero F12/F22/F23/F9b back-loops. Zero F26 escalations. One F11 auto-skip evaluation per phase (3 total) — all 3 phases had integration boundary, so 0 actual auto-skips fired.
  - Six human-pause points (3 verify-human, 1 spec review for chain-confirm, 1 mid-Phase-3 triage decision implicit in "all pass") — all approved on first review without rework.

## Test Triage — T2 (task:plan → act when plan is clear)
Classification: Code regression — caller-skill prose change (task-plan SKILL.md template addition in P2.3) shifted haiku's classification of the loading-spinner args from T2 → T3.
Confidence: high — failure has exactly one plausible explanation, stateable in one sentence: the new `docs-only:` frontmatter line + ~12-line prose block in task-plan SKILL.md competes for attention with the small/simple-task routing signal, pushing haiku toward ESCALATE on a borderline-sized input.
Evidence: T2 strictly PASSed pre-feature (2026-06-09). Post-Phase-2 edits, T2 on haiku FAILed in full-sweep (attempts 1+2 both T3 not T2) AND in standalone re-run (same FAIL). T2 on sonnet: FLAKY once, then PASS strictly — historical marginal-on-haiku pattern.
Action: Sonnet-tagged T2 in `tests/scenarios/task.yaml` per CLAUDE.md "haiku-marginal classification call" convention (precedent: 6 of 8 scenarios sonnet-tagged in the verify-codify-scenarios-need-sonnet-tag task, 2026-06-09). The task-plan documentation is load-bearing for OQ-1 docs-only gate; should not be diluted to satisfy a test that needs sonnet anyway. Confirmed: T2 sonnet PASSes (FLAKY → PASS on retry, run 2026-06-11 19:15).

## Current Node
- **Path:** Feature > ship (all phases complete)
- **Active scope:** All 3 phases complete (all 16 impl tasks + 12 verify nodes [x]); ready for ship
- **Blocked:** none
- **Unvisited:** ship → finalize
- **Open discoveries:** T2 triaged + sonnet-tagged (see ## Test Triage section); pre-existing SOFT_PASS items in F16-triage backlog item already covered.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Plan-time downstream-contract-impacts pass

Per CLAUDE.md's "Plan-time downstream-contract-impacts grep must include literal-payload-object assertions..." convention. Before sealing the plan, greppable contracts that change in this feature:

1. **`T5` as a transition ID** (key-name grep) — replaced by T5a/T5b/T5c. Audited via grep:
   - `docs/product/transitions.md`: 1 occurrence (line 353) — replaced in P1.2 (transitions table) + P1.3 (pause-policy table).
   - `skills/task-act/SKILL.md`: ≥1 occurrence (Valid transitions list) — replaced in P2.1.
   - `agents/task-workflow/AGENTS.md`: ≥1 occurrence (state machine diagram + transitions table) — replaced in P1.4.
   - `tests/scenarios/task.yaml`: 1 occurrence (id: T5 at line 105) — renamed in P3.1.
   - `CLAUDE.md`: 0 occurrences from manual review; the new task-verify convention bullet (P2.4) is additive, not a rewrite.
   - `tests/fixtures/wip/task-act-complete.md`: state field is `act (complete)`, no T-ID reference — no change needed.
2. **`act → close` narrative path** (literal phrase grep) — replaced by `act → verify → close`. Affected files: `agents/task-workflow/AGENTS.md` state diagram (P1.4), `docs/product/transitions.md` if any prose mentions the path (P1.2).
3. **Mode-2 happy-path pause count** (numeric assertion). `agents/task-workflow/AGENTS.md` line 88 says "Mode 2 happy-path pauses: plan confirm + close confirm (2 total)" — task-verify is AUTO in Mode 2, so count stays at 2. No change needed; verified in P1.4.
4. **Test scenario `id: T5` references** — only the scenarios YAML; no fixture filename uses `T5` as a substring (all fixtures use task-act-complete / task-plan-clear / task-plan-worktree shape).
5. **`/task-close` recommendation in act** (literal string grep). `skills/task-act/SKILL.md` § 7 line 99 — replaced with `/task-verify` in P2.1.

No literal-payload-object, array-length, or function-signature contract patterns apply here (this is a workflow-doc feature, not a code feature with shared payloads).

## Notes for build

- **Phase 1 is the heaviest** — new SKILL.md is the biggest single artifact (~120 LOC of templated skill). Use `feature-verify-self/SKILL.md` §3 (in-place fix shortcut) as the closest pattern reference for the SURFACED-sibling-bug sub-clause.
- **Phase 2 is mechanical** — small surgical edits to 3 existing skills + 1 CLAUDE.md bullet.
- **Phase 3 has the most files but lowest LOC density** — scenario YAML + fixtures + 5-8 structural pins.
- **Integration boundary?** YES — task-act and task-close are existing consuming surfaces of T5. The build phases must verify that those skills' transition emissions still work correctly after T5 → T5a rewrite. Phase 2's verify-self CLI checks include this.
- **Don't deviate from feature-verify-self's three-gate shortcut shape.** The convention is established and tested at feature scope; reuse it verbatim (modulo task-vs-feature wording) in task-verify §4b.
- **Estimated total LOC delta:** ~330-450 lines across 11 files (1 new skill ~120 LOC + 10 existing files ~20-35 LOC each).
