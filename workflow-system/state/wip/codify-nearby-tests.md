---
drive_mode: autopilot
---

# Feature: Codify runs nearby tests per phase, full suite once at the last phase

**Workflow:** feature
**State:** ship (complete)
**Created:** 2026-11-06
**Entry:** spec (complex feature)
**Source:** inbox `workflow-system/inbox/2026-11-06-claudesk-codify-nearby-tests.md` (Claudesk feature-request; Claudesk-side record `SURFACE-2026-11-06-CODIFY-RUNS-THE-FULL-SUITE-EVERY-PHASE`)

## Problem Statement

`skills/feature-verify-codify/SKILL.md` §3 says "Run the full test suite (not just new tests)". That runs at the end of **every** phase. `feature-verify-auto` is already scoped ("Do NOT run the full test suite here"), so codify is the only per-phase full run. In a project with a slow suite, this costs the full runtime on every phase of every feature. Then `feature-ship` §2 runs the full suite "one last time" again. This repo works around it with a local root-`CLAUDE.md` override ("Full scenario sweep only at a feature's LAST-phase codify (this repo)", ~100-min `run-all.sh`). The operator wants that behavior made general:

> "for workspaces/projects where the full test suite takes long, the codify step should just run the 'nearby' tests, the full suite then just need to be run during the codify step of the last phase."

Problem statement unchanged (2026-11-07, F9b re-entry) — the ask is still the scope rule; verify-self exposed that the rule must also decide "last phase?" from the Work Tree and default to full when unconfirmed, which is part of the same problem (no long-suite feature ships without one full run).

Problem statement unchanged (2026-11-07, Phase 2 F9b re-entry) — ship reuse is still the goal; verify-self showed ship must treat an unseen `Test scope:` line as missing (run the suite), the same fail-safe direction codify Step A already takes.

## User Stories

- As an operator on a project with a slow suite, I want non-final phases' codify to run only the tests near the change, so a 4-phase feature doesn't pay the full-suite runtime 4–5 times.
- As an operator, I want the full suite to run unconditionally at the last phase's codify, so nothing ships without one full regression run.
- As an operator on a project with a fast suite (or no runtime data), I want nothing to change.
- As an operator, I want a regression that an earlier phase caused, surfacing only at the last-phase full run, to be routed predictably rather than improvised.

## Acceptance Criteria

1. **Scope rule in codify §3.** `feature-verify-codify` §3 decides **test scope** before running anything:
   - **Last phase** (this codify will emit F16; no other phase in the Work Tree is un-`[x]`) → **full suite, unconditionally**, regardless of suite length.
   - **Non-final phase + long suite** → **nearby** tests only.
   - **Non-final phase + not long** (or "long" undeterminable) → **full suite** (today's behavior).
   - Single-phase features are always "last phase" → full suite (unchanged).
2. **"Long" criterion, in precedence order:**
   1. An explicit declaration in the project's root `CLAUDE.md` (e.g. a line stating the full suite is long / codify runs nearby tests on non-final phases, or the opposite to opt out) **wins**.
   2. Otherwise, the project's `runtimes.md` registry: the full-suite command(s)' `**Last:**` runtime **≥ 300s** → long.
   3. Neither present → **not long** (today's behavior).
3. **"Nearby" defined as a rule, with ecosystem examples, not an exhaustive list:** (a) the tests this codify wrote or changed; (b) existing tests covering the files the phase touched, via the runner's related-tests feature where one exists (`vitest related`, `jest --findRelatedTests`, `pytest <paths>`, `cargo test <module>::`, `go test ./<pkg>/...`, `rspec spec/<area>/`) or by path/name mapping; (c) the project's fast whole-repo checks (lint, typecheck, structural checks) when they are short. **Fail-safe:** if nearby tests can't be identified with confidence, run the full suite.
4. **Scope is recorded.** Codify writes one line to the WIP for the phase, naming the scope and its evidence (e.g. `Test scope: nearby — long suite (runtimes.md: run-all.sh 6000s)` / `Test scope: full — last phase`), so ship and later readers can see what ran.
5. **Late-regression routing written down (§3b).** At the last-phase full run, a failing test may have been broken by an **earlier, already-`[x]` phase**. The six-case triage table applies unchanged (high-confidence code regression → auto-fix in this codify; low/ambiguous → triage artifact + pause). Additionally: the fix lands **in the current (last) phase**. The earlier phase is **not** reopened or un-checked, and **no new transition ID** is added. Codify appends `[LATE-REGRESSION-<date>] Phase <N> — <test> — <one-line cause>` to `## Discoveries`.
6. **Ship doesn't repeat the run.** `feature-ship` §2 reuses the last-phase codify's full-suite result (cites it) when nothing but ship's own cleanup changed since; it reruns the full suite only if source changed after that run or the recorded scope wasn't `full`. Fast-suite projects: ship behaves as today.
7. **This repo's local override is reconciled.** The root-`CLAUDE.md` bullet "Full scenario sweep only at a feature's LAST-phase codify (this repo)" is rewritten as an **instance** of the general rule. It keeps this repo's specifics (non-final phases run that phase's own scenarios n≥3 plus the discrimination arm against the pre-change skill, plus `./tests/check-structure.sh`; harness changes are not a reason to sweep early) and serves as this repo's explicit "long" declaration.
8. **`arch.md`** gets a `## Revision 2026-11-06` entry recording the scope rule, the "long" precedence, and the late-regression routing.
9. **Tests.** Scenarios assert the routing against the codify skill (long + non-final → nearby, F15; long + last → full, F16; no runtime data → full, F15), each discrimination-tested against the pre-change skill (`git show HEAD:skills/feature-verify-codify/SKILL.md`), with neutral fixture names and the fixture path named in `system_prompt_extra`. Plus a `check-structure.sh` pin that the last-phase full-suite instruction survives in codify §3 (section-scoped, both boundaries fail-closed).

## Out of Scope

- `incident-codify` (single-shot; it has no per-phase loop to scope).
- `feature-verify-auto` (already scoped).
- Changing the `runtimes.md` format or adding a new registry field.
- Teaching any tool to compute test↔file mappings; the agent chooses nearby tests per the rule.
- Reopening an earlier phase / new back-loop transition for late regressions (see AC 5).

## Technical Constraints

- No 3rd-party dependency; no probe needed.
- State machine unchanged: F15/F16/F14 keep their meaning; no transitions.md / AGENTS.md table edits.
- `/test-assertion-review` before writing the check-structure pin; scenario design per `docs/lessons/test-scenario-prompt-leakage.md` and the fixture-path/neutral-name rule (check `test -e` before naming a fixture).
- Per this repo's own rule, non-final phases skip the full `run-all.sh` sweep; the last phase's codify runs it.
- `arch.md` is 506 lines (over the size guard); read via headings + targeted sections.

## Open Questions

(none — all defaults are listed under **Assumed** below)

## Elicitation

**Asked:** none. Each open decision is cheap to reverse (a skill-prose edit), so per the grill gate's clause (c) it was taken as a default and listed here for spec review.

**Assumed:**
- **"Long" threshold = 300s** of recorded full-suite runtime. An explicit project `CLAUDE.md` declaration overrides the registry in either direction. No data → today's behavior.
- **"Nearby" = rule + examples**, not a mandated per-ecosystem command table; unidentifiable → full suite (fail-safe).
- **Late regressions are fixed in the last phase**, earlier phase stays `[x]`, logged as a `[LATE-REGRESSION-…]` discovery; no new transition.
- **`feature-ship` dedup is in scope** (AC 6). The ask says the full suite "just need[s] to be run during the codify step of the last phase", and ship's unconditional re-run would double the longest run. This is the one scope addition beyond the inbox message's literal text.
- **Fast whole-repo checks** (lint/typecheck/structure) are part of "nearby" when they're short.
- **Scope line recorded in the WIP** so ship can decide reuse vs re-run.
- `[PRIOR]` check: `P-LIVE-SETTING` is about live host settings vs recorded snapshots; it does not govern this axis (over-infer guard), so it doesn't fire.

## Work Tree

- [x] Phase 1: Codify scope rule — nearby on non-final phases of a long suite, full at the last phase
  **Observable outcomes:**
  - CLI: `grep -n` on `skills/feature-verify-codify/SKILL.md` §3 (between `### 3.` and `### 3b.`) finds all of: the last-phase-full-unconditionally rule, the "long" precedence (project `CLAUDE.md` declaration > `runtimes.md` `**Last:**` ≥ 300s > neither → not long), the nearby definition with ecosystem examples + fail-safe-to-full, and the `Test scope:` WIP line format.
  - CLI: `grep -n` on §3b finds the late-regression routing (fix in the current/last phase, earlier phase not reopened, `[LATE-REGRESSION-<date>]` discovery, no new transition).
  - CLI: `./tests/run-tests.sh --id <new nearby scenario>` on the new skill → PASS ≥3/3 with `Test scope: nearby` hard-asserted; the same scenario against `git show HEAD:skills/feature-verify-codify/SKILL.md` → FAIL ≥3/3 (discrimination arm).
  - CLI: the two control scenarios (long suite + last phase → `Test scope: full`, F16; no runtime data/declaration + non-final → `Test scope: full`, F15) → PASS ≥3/3 on the new skill; a mutation rewriting the last-phase row to `| Last phase | long | **nearby** |` flips the last-phase control to FAIL. [Revised 2026-11-07 at F9b: deleting the row did not discriminate (1/3 vs 1/3) — with no row the model can still infer full, so the row-deletion arm cannot show the control follows the table; flipping the row can.]
  - CLI: `./tests/check-structure.sh` → new pin PASS; the pin FAILs when the last-phase full-suite sentence is removed from §3, when it is moved below `### 3b.`, and when the `### 3b.` end heading is renamed (fail-closed on both boundaries); no other new FAILs vs baseline.
  - CLI: existing codify scenarios `F15`, `F16`, `F16-triage-*`, `F16-codify-*` → no regression vs a pre-change baseline at equal n.
  **Alignment questions:**
  - "Long" = 300s recorded runtime, with a project `CLAUDE.md` line overriding either way (spec Assumed #1) — now that you see it as §3 prose, still what you want?
  - Late regressions fixed in the last phase, earlier phase left `[x]`, logged as `[LATE-REGRESSION-…]` (spec Assumed #3) — now that you see it in §3b, still what you want?
  - [x] P1.1 Rewrite codify §3 "Run All Tests" → scope decision (last-phase / long / nearby / fail-safe) + `Test scope:` WIP line
  - [x] P1.2 Add late-regression routing paragraph to §3b (no table change, no new transition)
  - [x] P1.3 Fixtures (neutral names — `test -e` before naming; pool `notif-prefs-f`+) + 3 scenarios in `tests/scenarios/feature.yaml` (nearby, last-phase control, no-data control), fixture path named in `system_prompt_extra`, runtime facts stated neutrally (no answer recited)
  - [x] P1.4 `/test-assertion-review`, then `check-structure.sh` pin on codify §3 last-phase-full instruction (section-scoped, `sec_start` + `sec_end` fail-closed)
  - [x] verify-auto
    — evidence: `bash -n tests/check-structure.sh` → exit 0
    — evidence: `python3 -c yaml.safe_load(tests/scenarios/feature.yaml)` (PYENV_VERSION=3.12.11) → exit 0, 79 scenarios
    — evidence: `./tests/check-structure.sh` → 619 PASS / 1 FAIL vs stashed baseline 618 PASS / 1 FAIL; +1 = [Phase 26] PASS; the lone FAIL is the pre-existing settings-fixture drift (identical on baseline)
    — evidence: `./tests/run-tests.sh --dry-run --id F15-codify-scope-nearby,F16-codify-scope-last-phase-full,F15-codify-scope-no-data-full` → all 3 listed, matchers parsed as `Test scope:[* ]*<scope>`
    — evidence (F9b re-entry): yaml.safe_load(feature.yaml) → exit 0, 79 scenarios; `./tests/check-structure.sh` → 619 PASS / 1 FAIL (unchanged; [Phase 26] PASS, lone FAIL = pre-existing settings drift); `awk §3 | grep -c "treat this as the last phase"` → 1
  - [x] verify-self
    - [x] V1 §3 text (last-phase rule, long precedence, nearby + fail-safe, Test scope formats, Step A from Work Tree / unconfirmed → last) — evidence: re-run grep → L68 Step A, L71–72 rungs, L79 row, L83 nearby + fallback, L86–89 formats; §3 = L64–96
    - [x] V2 §3b late-regression routing — evidence: awk §3b → L116–121
    - [x] V3 F15-codify-scope-nearby ≥3/3 + HEAD 0/3 — evidence (re-run after F9b): new 3/3 PASS (run-2026-11-07-094439/094533/094623), HEAD sha 5bed9c68 3/3 FAIL "required-any content missing — none of: Test scope:[* ]*nearby" (095313/095359/095545). First run: new 2/3, HEAD 0/3.
    - [x] V4 controls ≥3/3 + row-flip mutation — evidence (re-run after F9b): last-phase-full 3/3 (094718/094818/094919), no-data-full 3/3 (095022/095113/095207); mutant (`| Last phase | long | **nearby** |`, sha b5d7bb7c) FAIL 2/3 (095640 FAIL, 095735 PASS, 095838 FAIL) — partial sensitivity: the Step A "unconfirmed → last" sentence still pulls toward full when only the row is flipped (redundant safety in the prose, not an inert control). First run: last-phase-full 1/3.
    - [x] V5 check-structure [Phase 26] — evidence: 619 PASS / 1 FAIL (pre-existing settings drift); 3 mutations each FAIL, end-boundary fails closed
    - [x] V6 existing codify scenarios no regression — evidence: n=1/arm default retries: new 5 PASS + 3 SOFT, HEAD 4 PASS + 4 SOFT, 0 FAIL either arm (full sweep at last phase)
    - [x] align: "Long" = 300s + CLAUDE.md override — evidence: §3 Step B L70–73 quoted by runner (CAPTURED)
    - [x] align: late-regression routing — evidence: §3b L116–121 quoted; model line `Test scope: nearby — long suite (runtimes.md "docker compose exec app pytest", Last 1420s)` (CAPTURED)
  - [x] verify-human
    - [x] P1.verify-human.1 "Long" = 300s recorded runtime; project CLAUDE.md line overrides either way — still what you want? — operator: approved ("all good", 2026-11-07)
    - [x] P1.verify-human.2 Late regressions fixed in the last phase; earlier phase stays [x]; logged as [LATE-REGRESSION-…] — still what you want? — operator: approved ("all good", 2026-11-07)
    - [x] P1.verify-human.3 (decision) Unconfirmed "another phase remains" → treat as last phase → full run (added at F9b; spec silent) — operator: approved ("all good", 2026-11-07)
  - [x] verify-codify
    Test scope: nearby — long suite (root CLAUDE.md: "Full scenario sweep only at a feature's LAST-phase codify (this repo)"; runtimes.md run-all.sh ~100 min)
    — evidence: new tests: scenario F16-codify-late-regression (new 3/3, HEAD 0/3 — discriminates); [Phase 26] +§3 fail-safe anchor, +§3b late-regression window (2 anchors). /test-assertion-review CLEAR: 6 mutations (fail-safe deleted, fail-safe inverted, reopen-rule rewritten, tag removed, window start renamed, window end renamed) each FAIL; verify.sh: "fixed, no tag" → FAIL, wrong transition → FAIL.
    — evidence: nearby run: scope scenarios at n=3 from verify-self re-run on the identical skill text (nearby 3/3 + HEAD 0/3; last-phase-full 3/3; no-data-full 3/3); F16-codify-late-regression 3/3; `./tests/check-structure.sh` → 620 PASS / 1 FAIL (lone FAIL = pre-existing settings-fixture drift). No integration-boundary gap: consuming surface = codify skill driven via run-tests.sh.

- [x] Phase 2: Ship reuses the last-phase full run; repo rule + arch reconciled
  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — Claudesk inbox ask + operator "tackle the one today"; Phase 1 alone leaves ship re-running the suite Phase 1 just ran once
  - Requirements unchanged: yes — operator approved spec incl. ship dedup (Assumed #4) and all Phase 1 leaves
  - Solution still feasible: yes — Phase 1 now writes the `Test scope:` line ship needs to read
  - No superior alternative discovered: yes — none surfaced in Phase 1
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: `grep -n` on `skills/feature-ship/SKILL.md` §2 finds the reuse rule: cite the last-phase codify `Test scope: full` run when no source changed since; re-run the full suite if source changed or the recorded scope is not `full`; fast-suite projects unchanged.
  - CLI: new ship scenario (WIP fixture whose last phase records `Test scope: full — last phase`, nothing changed since) → PASS ≥3/3 citing the codify run instead of re-running; HEAD `feature-ship` → FAIL (discrimination). Control (recorded scope `nearby`) → re-runs the full suite, PASS ≥3/3.
  - CLI: root `CLAUDE.md` "Full scenario sweep only at a feature's LAST-phase codify (this repo)" bullet is rewritten as an instance of the general rule (explicit long-suite declaration + repo specifics kept); `wc -c CLAUDE.md` does not grow (backlog `SURFACE-2026-07-29-CLAUDE-MD-OVER-40K-THRESHOLD`).
  - CLI: `grep -n '^## Revision 2026-11-06' workflow-system/product/arch.md` → 1 match describing the scope rule, "long" precedence, late-regression routing, ship reuse.
  - CLI: last-phase codify runs the full `./tests/run-all.sh` sweep (registry timeout, ~100 min) → no new FAILs vs the known pre-existing set (`SURFACE-2026-11-03-SCENARIO-SWEEP-PREEXISTING-FAILURES`); `./tests/check-structure.sh` no new FAILs.
  **Alignment questions:**
  - Ship citing the last-phase codify run instead of re-running (spec Assumed #4, the scope addition) — now that you see it in `feature-ship` §2, still what you want?
  - [x] P2.1 Rewrite `feature-ship` §2 "Final Verification" with the reuse rule
  - [x] P2.2 Ship fixture(s) + 2 scenarios (reuse, re-run control)
  - [x] P2.3 Rewrite root `CLAUDE.md` local-override bullet as an instance of the general rule (no net growth)
  - [x] P2.4 `arch.md` `## Revision 2026-11-06` entry
  - [x] verify-auto
    — evidence: `yaml.safe_load(tests/scenarios/feature.yaml)` (PYENV_VERSION=3.12.11) → exit 0, 82 scenarios
    — evidence: `./tests/run-tests.sh --dry-run --id F38-ship-reuses-codify-full-run,F38-ship-reruns-after-code-change` → both listed
    — evidence: `./tests/check-structure.sh` → 620 PASS / 1 FAIL (unchanged from Phase 1 close; all CLAUDE.md content checks PASS after the bullet rewrite; lone FAIL = pre-existing settings drift)
    — evidence: `grep -c "^## Revision 2026-11-07$" arch.md` → 1; `awk ship §2 | grep -c "Test scope: full"` → 1
    — evidence (F9b re-entry): yaml.safe_load → 82 scenarios; `./tests/check-structure.sh` → 620 PASS / 1 FAIL (unchanged); `awk ship §2 | grep -c "counts as missing"` → 1
  - [x] verify-self
    - [x] W1 ship §2 reuse rule text + unread-line fail-safe — evidence: §2 L30 reuse + citation template, L31 re-run triggers + "A line you have not actually read counts as missing", L32 linters always
    - [x] W2 F38-ship-reuses-codify-full-run ≥3/3 + HEAD 0/3 — evidence (re-run after F9b): new 3/3 (run-2026-11-07-103252/103341/103432), HEAD sha 1bd4a7e8 0/3 — model chose to re-run (103801/103858/103942). First run: new 1/3.
    - [x] W3 F38-ship-reruns-after-code-change ≥3/3 — evidence: first run 3/3 (101942/102038/102132); re-run after F9b 3/3, no strict-negative hits ("I would not reuse the last codify run. The `print()` removal changed source after that run")
    - [x] W4 root CLAUDE.md bullet — evidence: L177 new bullet with repo specifics; old bullet count 0; wc -c 58961→58935
    - [x] W5 arch.md Revision 2026-11-07 — evidence: L234; [Phase 26] at check-structure L3674/3692; all 6 scenario ids present once
    - [x] W6 check-structure — evidence: 620 PASS / 1 FAIL (pre-existing settings drift)
    - [x] align: ship reuse (Assumed #4) — evidence: §2 text; real citation (re-run 1): `Full suite: reused the last-phase codify run (Test scope: full — last phase, exit 0, 412 passed in 1388s)` (CAPTURED)
  - [x] verify-human
    - [x] P2.verify-human.1 Ship cites the last-phase codify full run instead of re-running (Assumed #4) — still what you want? — operator: approved ("approve all", 2026-11-07)
    - [x] P2.verify-human.2 (decision) An unread `Test scope:` line counts as missing → ship runs the suite (added at F9b; spec silent) — operator: approved ("approve all", 2026-11-07)
  - [x] verify-codify
    Test scope: full — last phase
    — evidence: new test: [Phase 26] ship §2 pin (reuse condition + unread-line fail-safe; the fail-safe had no scenario guard). /test-assertion-review CLEAR: 6 mutations (reuse condition deleted, reuse widened to `nearby`, fail-safe deleted, fail-safe inverted, window start renamed, window end renamed) each FAIL; clean PASS; file restored sha-identical. `./tests/check-structure.sh` → 621 PASS / 1 FAIL (pre-existing settings drift).
    — evidence: full sweep `PYENV_VERSION=3.12.11 ./tests/run-all.sh` → 6751s, haiku 154 PASS / 42 SOFT / 11 FAIL / 1 FLAKY (208), sonnet 15 PASS / 1 FAIL / 1 FLAKY (17). All 12 FAILs are in the known pre-existing set (see ## Test Triage). All 6 new scenarios + every other codify/ship scenario PASS except F16-order-flip (pre-existing, A/B below).

## Current Node
- **Path:** Feature > ship
- **Active scope:** ship
- **Blocked:** none
- **Unvisited:** ship → review-quality → finalize
- **Open discoveries:** none

## Plan Notes
- **Backlog check:** no high-priority conflicts. Related: `SURFACE-2026-11-03-SCENARIO-SWEEP-PREEXISTING-FAILURES` (baseline for the Phase 2 sweep), `SURFACE-2026-09-29-SONNET-NARRATES-INSTEAD-OF-READING-FIXTURE` (name fixture paths in `system_prompt_extra`), `SURFACE-2026-07-29-CLAUDE-MD-OVER-40K-THRESHOLD` (no net growth of root `CLAUDE.md`).
- **Harness constraint:** `tests/run-tests.sh` has no `runtimes.md` fixture key (only `claude_md`, `wip`, `product_dir`, `session`, `backlog`). Runtime facts go in `system_prompt_extra` as neutral environment facts, or in a `fixtures.claude_md` variant for the declaration path. Adding a harness key is out of scope.
- **Discrimination design:** only the nearby scenario can discriminate against HEAD (HEAD runs full every phase, so both controls pass behaviorally on HEAD). The controls are the **specificity** arm: they must stay `full` on the new skill, and a mutation of the last-phase clause must flip the last-phase control.
- **3rd-party:** none. **wbs.md:** absent (no active cycle).

## Test Triage — last-phase full sweep (2026-11-07), 12 FAILs
Classification: Flaky test / pre-existing failure — unrelated to this feature's changes (11 of 12); F16-order-flip confirmed pre-existing by A/B
Confidence: high
Evidence: every failing ID is already recorded in SURFACE-2026-11-03-SCENARIO-SWEEP-PREEXISTING-FAILURES (F-boundary-human, F-verify-human-boundary-digest-advances, S14, T3-tour-first-run-hides-drive-modes-until-graduation, F16-order-flip, S22, S3 [sonnet]; DP-consult-changes flaky; S12 0/3 on HEAD; F-verify-human-auto-skip-fires ambiguous) or is deliberately-failing evidence (S33, S34). Only F16-order-flip exercises a skill this feature changed (feature-verify-codify): A/B n=3 → new 0/3, HEAD 0/3, identical failure ("FAILED strict not_contains: /feature-finalize").
Action: none — no code or test modified; failures stay tracked under the existing backlog SURFACE.

## Discoveries
- [SHIP-2026-11-07] Full suite: reused the last-phase codify run (Test scope: full — last phase; run-all.sh 6751s, 12 FAIL all pre-existing per ## Test Triage). Only WIP + runtimes.md changed since. check-structure 621/1 (pre-existing settings drift).
- [F9b-2026-11-07] Phase 2 — P2.1: ship §2 now says an unread `Test scope:` line counts as missing → run the suite. P2.2: reuse scenario states the recorded scope line as an environment fact. A widened matcher (`reus[a-z]* that run`) was tried and REVERTED: verify.sh showed it accepts a re-run reply that merely mentions reuse ("Could reuse that run? No…" → rc=0), weakening M5. Re-verify gate: reuse 3/3, control 3/3 (`--retry 1` ×3 each); before fix reuse 1/3.
- [VERIFY-SELF-2026-11-07] Phase 2 — W2 root cause mirrors Phase 1 V3/V4: under --print the model does not read the fixture, so it cannot see the `Test scope:` line and hedges conditionally. Skill gap: ship §2 says nothing about an UNSEEN line (the safe reading is "treat as missing → run the suite", symmetric with codify Step A). Fix: P2.1 add that fail-safe; P2.2 state the recorded scope line as an environment fact (expected action still unstated) + accept "reuse that run" phrasing.
- [BUILD-2026-11-07] P2.2 — plan deviation: control is "full run recorded, but §1 removed debug code from a source file → re-run", not "recorded scope `nearby`" (a last-phase `nearby` cannot occur under the new rule; the code-changed case is the realistic risk). Both scenarios share fixture notif-prefs-h.md. /test-assertion-review: AT-RISK → CLEAR — control's strict negative only matched the `Full suite: reused` format, so a paraphrased reuse PASSED the control (verify.sh rc=0); widened to past-tense `reused the last.phase codify run` + line-leading `Reusing …`; both correct phrasings ("can't reuse", "instead of reusing") still PASS.
- [BUILD-2026-11-07] P2.3/P2.4 — root CLAUDE.md bullet rewritten as the Step B declaration (706→679 chars; file −26 bytes). arch.md revision is dated `## Revision 2026-11-07` (the date written), not the plan's `2026-11-06`; `updated:` bumped.
- [F9b-2026-11-07] P1.1 — Step A now decided from the Work Tree; unconfirmed "another phase remains" → last phase → full. P1.3 — scope scenarios state phase status as environment facts (expected scope unstated). Re-verify gate (build §6): F15-codify-scope-nearby 3/3, F16-codify-scope-last-phase-full 3/3 (`--retry 1` ×3 each, PYENV_VERSION=3.12.11); before fix 2/3 and 1/3.
- [VERIFY-SELF-2026-11-07] Phase 1 — root cause of V3/V4: in a --print scenario the model treated codify as a dry run and never read the fixture WIP, then resolved Step A ("last phase?") to "not last" by GUESS. That is a real skill gap, not just scenario noise: §3 has a fail-safe for an unidentifiable nearby set but none for undeterminable last-phase status, and the guess went the UNSAFE way (nearby). Fix: Step A decided from the Work Tree; unconfirmed → last phase → full. Scenarios: state phase facts as environment facts (as existing F15/F16 do), expected scope still unstated.
- [BUILD-2026-11-07] P1.4 — /test-assertion-review: CLEAR after fix. Phase 26 pin sweep 9/9 as designed: clean PASS; nearby-swap, `any`→`long`, row moved below `### 3b.`, record line deleted, end heading renamed, start heading renamed, file missing → FAIL each; bold dropped → PASS (intended tolerance). Each mutation sha-verified to apply; file restored sha-identical. Cosmetic: shared helper's missing-file message names "[Phase 23]".
- [BUILD-2026-11-07] P1.3 — verify.sh simulation caught `Test scope:** nearby` as an invalid BRE (grep -qi): the CORRECT bold output FAILed. Matchers now `Test scope:[* ]*<scope>`; 8 simulated outputs (right/wrong per scenario) behave as designed. Known gap: a full-control reply that picks nearby but also mentions the full line passes with a warning (lenient not_contains, deliberate per M6).
- [SURFACED-2026-11-07] harness env — `tests/run-tests.sh` dies with `ModuleNotFoundError: yaml` when pyenv `system` resolves to Homebrew python3 (no PyYAML). Worked around per-command with `PYENV_VERSION=3.12.11`. Logged to backlog.
- [SURFACED-2026-11-06] feature-spec — arch.md exceeds size guard (506 lines), read via headings + first 31 lines. Consider summarizing.
