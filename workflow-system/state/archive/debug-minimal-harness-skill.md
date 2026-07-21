# Feature: `debug-minimal-harness` — a self-driven-reproduction debug sidebar skill

**Workflow:** feature
**State:** ship (complete) — committed efba0ca on main, not pushed
**Created:** 2026-06-23
**Entry:** spec (complex feature — new skill subsystem across 4 artifact kinds, category-level decisions made, >200 lines)
**drive_mode:** autopilot

## Problem Statement

When fixing a **behavioral** bug (interactive UI gesture, CLI under real argv/stdin, HTTP under a real client, a race under real concurrency), agents repeatedly **hand the fix back to the human untested** — rationalizing "the shipping target is native, only the human can verify." This wastes hand-back cycles and lets plausible-but-wrong fixes survive. The transferable technique (origin: claudesk M4 WP3 drag-reorder, `.claude/learnings/2026-06-23-test-it-yourself-first-interactive-fixes.md`) is: when the behavior is **drivable in a surface the agent controls** AND the agent has **already handed back ≥2×**, stop handing back — build a **minimal standalone reproduction** and **drive it with REAL input/I-O** until it works, before re-presenting. The sharpest sub-discipline: **real I/O, not synthetic dispatch/mocks**, because synthetic dispatch *false-passes* by masking pointer-capture / focus / hit-test / re-render-during-gesture bugs.

No existing skill captures this. The two sibling `debug-*` skills key on different stalls:
- `debug-bisect-known-good` — a structurally similar **known-good path** exists; isolate by addition.
- `debug-empirical-telemetry` — no known-good; **observe the running system** via instrumentation.
- **This skill** keys on **repeated hand-back + self-drivability** — neither sibling's trigger.

## User Stories

- As an **orchestrator/agent** stuck handing an interactive fix back to the human a 3rd time, I want a sidebar that tells me to build a minimal self-driven repro and drive it with real input, so I find the root cause myself instead of burning another hand-back cycle.
- As the **operator**, I want the agent to self-verify drivable behavioral fixes before re-presenting, so I'm not the agent's manual test harness for bugs it could have reproduced itself.
- As a **skill author**, I want the new sidebar to follow the established `debug-*` recipe (4 artifact kinds, three discoverability surfaces, structural pins) so it's discoverable and regression-protected like its siblings.

## Acceptance Criteria

The feature is done when:

1. **`skills/debug-minimal-harness/SKILL.md`** exists with the six required `debug-*` sections in order: `## Category Context`, `## When to use` (two conjunctive gates, "AND not OR"), `## When NOT to use`, `## Procedure` (first subheading `### 1. Gate Check`), `## Pitfalls (load-bearing — read before <verb>)`, `## Termination` (token table). Frontmatter: `name`, `description`, `argument-hint`.
2. **Two conjunctive gates** are spelled out:
   - **Gate 1 — self-drivable surface:** the behavior runs in a surface the agent can drive itself (browser/DOM, CLI under real argv/stdin, HTTP under a real client, a race under real concurrency) — *even when the shipping target is native* (Tauri WKWebView, Electron) that the agent cannot attach to, the underlying logic is often drivable in a surface it can.
   - **Gate 2 — repeated hand-back:** the agent has already failed or handed the fix back **≥2×** on the **same** behavior.
3. **Tokens:** `DEBUG-MINHARNESS-START` (both gates pass), `DEBUG-MINHARNESS-SKIP` (either gate fails / gate no longer holds mid-procedure), `DEBUG-MINHARNESS-COMPLETE` (root cause found + repro driven green + cleanup done), `DEBUG-MINHARNESS-INCONCLUSIVE` (repro built but ≥3 rounds did not converge). Every termination carries a `RETURN-TO: <caller>` line.
4. **Load-bearing pitfall** documented: real I/O not synthetic dispatch — synthetic `PointerEvent`/`KeyboardEvent` dispatch (or mocked argv / mocked HTTP client / serialized "concurrency") can FALSE-PASS while the real component stays broken. Worked example: the claudesk pointer-capture-dropped-on-re-render root cause that a synthetic-dispatch hello-world passed but a real `page.mouse` drag reproduced.
5. **3 fixtures** under `tests/fixtures/wip/`: one gates-met, one gate1-fails (not self-drivable), one gate2-fails (<2 hand-backs).
6. **3 scenarios** in `tests/scenarios/debug.yaml`: one `MINHARNESS-GATE-MET` (asserts `DEBUG-MINHARNESS-START` + `contains_any` procedure-anchor phrases, no aggressive `not_contains`), two SKIP-exit scenarios (assert `DEBUG-MINHARNESS-SKIP` + failing-gate phrase + `not_contains: [DEBUG-MINHARNESS-START, DEBUG-MINHARNESS-COMPLETE]`).
7. **`tests/check-structure.sh` Phase 3c extension** — the 7 explicit pins for this skill: 3 caller-prose mentions (`feature-build`, `incident-investigate`, `task-act`), 3 orchestrator "Debug-techniques" table rows (`feature-workflow`, `incident-workflow`, `task-workflow` AGENTS.md), 1 `transitions.md` "Sidebar skills" mention.
8. **Discoverability wiring** (the actual prose/rows the Phase 3c pins assert): caller-skill `### Xb. Debug-technique Sidebar` prose in the 3 caller skills, the 3 orchestrator AGENTS.md table rows, and the `transitions.md` sidebar note.
9. **`./tests/check-structure.sh` passes** with the projected **+16 PASS** delta (9 auto-iterated by Phase 3b's `for debug_skill` loop + 7 explicit Phase 3c pins). No prior assertions regress.
10. **`./tests/run-tests.sh --group <debug group>`** (the 3 new scenarios) passes on a fresh subprocess (avoids the harness bootstrap-skip — the skill file is new, so no stale-prose risk, but run via fresh subprocess per `docs/lessons/harness-bootstrap-skip.md`).
11. **`install.sh`** re-run so the new skill directory is symlinked into `~/.claude/skills/`.
12. **Durable-doc sync** (finalize): `arch.md:222` "Current sidebars" list + `CLAUDE.md` Architecture `debug-*` section gain the third skill; `docs/lessons/debug-skill-template.md` count references stay accurate.

## Out of Scope

- **No changes to the two existing `debug-*` skills** — additive only.
- **No new F/I/T/P/S transition IDs** — sidebars are outside that namespace (the skill emits only `DEBUG-MINHARNESS-*` + `RETURN-TO:`).
- **No pause-policy-table rows** — sidebars never appear in pause-policy tables (they're not states).
- **No changes to `feature-reproduce` / `incident-reproduce`** — those own red-green workflow-state reproduction; this is a *sidebar technique* pulled mid-state, deliberately kept separate (Scope-C collision was rejected).
- **Not auto-invoked by the orchestrator** — like its siblings, it is agent-pulled / user-invoked when the trigger conditions are met; no skill auto-chains into it.

## Technical Constraints

- **Follow the established `debug-*` recipe verbatim** — `docs/lessons/debug-skill-template.md` (mechanical recipe + the two discipline notes) and the canonical shape of `skills/debug-empirical-telemetry/SKILL.md`.
- **Three structurally-enforced discoverability surfaces** (Discipline 1): the agent reads only its own SKILL.md, the orchestrator AGENTS.md, and caller-skill prose at invocation — NOT `CLAUDE.md`/`transitions.md`. All three agent-facing surfaces must be wired and pinned.
- **Scenario shapes** per `docs/lessons/test-scenario-routing-forks.md`: entry-state GATE-MET scenario uses `transition_id` + `contains_any`, NO aggressive `not_contains`; SKIP scenarios may use `not_contains` on START/COMPLETE because those are genuine failure-proxy tokens here.
- **No 3rd-party dependencies.** Pure prompt-authoring + bash structural checks + YAML scenarios.
- **arch.md exceeds the 300-line size guard (339 lines)** — read first 100 + headings only at spec time (done); logged below.

## Open Questions

- [x] Scope (A/B/C) — **resolved before spec:** Scope B (any self-drivable behavioral bug, interactive UI as primary worked example).
- [x] Name — **resolved before spec:** `debug-minimal-harness`.
- [x] Gate shape — **resolved before spec:** drivable-surface AND ≥2 hand-backs.
- [x] Token names — **resolved:** `DEBUG-MINHARNESS-{START,SKIP,COMPLETE,INCONCLUSIVE}`.

No remaining unknowns → spec is clear, route to plan (F4). No research needed.

## Work Tree

- [x] Phase 1: Skill core — SKILL.md + fixtures + scenarios  <!-- status: done; all impl + all 4 verify nodes [x] -->

  **What:** The self-contained, independently-testable core of the skill: the `debug-minimal-harness/SKILL.md` (6 required sections, 2 conjunctive gates, 4 `DEBUG-MINHARNESS-*` tokens, the real-I/O-not-synthetic pitfall), the 3 WIP fixtures, and the 3 debug.yaml scenarios. `install.sh` is re-run here so the new skill is symlinked and the scenarios resolve against a live skill. This phase deliberately EXCLUDES the discoverability wiring + structural pins (Phase 2) — the skill is functionally complete and testable in isolation first.
  **Observable outcomes:**
  - CLI: `test -L ~/.claude/skills/debug-minimal-harness` exits 0 (install.sh symlinks the skill DIRECTORY, not the SKILL.md file — corrected at P1.4 build).
  - CLI: `head -5 skills/debug-minimal-harness/SKILL.md | python3 -c "import sys,yaml; yaml.safe_load(sys.stdin.read().split('---')[1])"` exits 0 (frontmatter is valid YAML — defends the open backlog item's failure mode).
  - CLI: `grep -c '^## ' skills/debug-minimal-harness/SKILL.md` ≥ 6 (Category Context, When to use, When NOT to use, Procedure, Pitfalls, Termination all present); `grep -q '### 1. Gate Check' skills/debug-minimal-harness/SKILL.md` exits 0.
  - CLI: `grep -oE 'DEBUG-MINHARNESS-(START|SKIP|COMPLETE|INCONCLUSIVE)' skills/debug-minimal-harness/SKILL.md | sort -u | wc -l` == 4 (all four tokens defined).
  - CLI: `ls tests/fixtures/wip/debug-minharness-*.md | wc -l` == 3 (gates-met, gate1-fails, gate2-fails fixtures exist).
  - CLI: `grep -c 'MINHARNESS' tests/scenarios/debug.yaml` ≥ 3 (three scenarios added); `./tests/run-tests.sh --group debug --dry-run` lists the 3 new scenario IDs.
  - [x] P1.1 Write `skills/debug-minimal-harness/SKILL.md` — mirror `skills/debug-empirical-telemetry/SKILL.md` shape. Frontmatter (`name`, `description`, `argument-hint`). 6 sections in order. Gate Check first subheading of Procedure, emitting `DEBUG-MINHARNESS-SKIP` + `RETURN-TO:` on either-gate-NO. Gate 1 = self-drivable surface (browser/DOM, CLI argv/stdin, HTTP client, real concurrency — even when shipping target is native); Gate 2 = ≥2 hand-backs on same behavior. Procedure: build minimal standalone repro → drive with REAL input → iterate → cleanup. Pitfalls lead with real-I/O-not-synthetic (false-pass), with the claudesk pointer-capture worked example. Termination table: 4 tokens + RETURN-TO convention. Distinguish from both siblings in Category Context.  <!-- status: done -->
  - [x] P1.2 Write 3 fixtures under `tests/fixtures/wip/`: `debug-minharness-gates-met.md` (drag bug, 2 prior hand-backs, Vite-drivable), `debug-minharness-gate1-fails.md` (physical scanner hardware — undrivable, Gate 1 NO), `debug-minharness-gate2-fails.md` (⌘K web app, drivable but only 1 attempt — Gate 2 NO). Mirror existing `debug-empirical-telemetry-*` fixture shape.  <!-- status: done -->
  - [x] P1.3 Add 3 scenarios to `tests/scenarios/debug.yaml`: `DEBUG-MINHARNESS-GATE-MET` (transition_id DEBUG-MINHARNESS-START + contains_any, NO aggressive not_contains); `DEBUG-MINHARNESS-NOT-DRIVABLE` (DEBUG-MINHARNESS-SKIP + gate-1 phrase + not_contains [START, COMPLETE]); `DEBUG-MINHARNESS-INSUFFICIENT-HANDBACKS` (DEBUG-MINHARNESS-SKIP + gate-2 phrase + same not_contains). Routing-fork discipline followed.  <!-- status: done -->
  - [x] P1.4 Ran `./install.sh` — symlinked `skills/debug-minimal-harness` dir into `~/.claude/skills/` ([new] reported). NOTE: install symlinks the DIRECTORY, so the verify check is `test -L ~/.claude/skills/debug-minimal-harness` (not the SKILL.md path).  <!-- status: done -->
  - [x] verify-auto  <!-- status: done; check-structure.sh PASS (1 pre-existing unrelated FAIL = settings-fixture drift from claudesk external hook, logged SURFACE); scoped artifact checks PASS (frontmatter YAML valid, 6 sections, gate-check first, 4 tokens, 3 fixtures, 3 scenarios); 3 debug scenarios 3/0/0 on haiku after transition_id_any [START,COMPLETE] fix -->
  - [x] verify-self  <!-- status: done; feature-verify-self-runner subagent observed all 6 CLI Observable Outcomes PASS (symlink resolves, frontmatter YAML valid, 6 sections + gate-check-first, 4 tokens, 3 fixtures, 3 scenarios collect); no integration boundary (Phase 1 adds isolated new artifacts only); scenario green-run treated as already-observed (3/0 haiku) -->
  - [x] verify-human  <!-- status: done; AUTO-SKIP (F11) — autopilot + verify-self all-PASS + no integration boundary (isolated new artifacts only) + no consuming-surface outcome. Affirmation printed for operator read-time veto. -->
  - [x] verify-codify  <!-- status: done; permanent coverage exists by construction — Phase 3b for-loop auto-asserts the new skill's 6 sections+argument-hint+gate-check-first+≥4 tokens (confirmed it iterates skills/debug-*/SKILL.md); 3 debug.yaml scenarios are the permanent behavioral tests. Full debug group 7 PASS / 3 SOFT / 0 FAIL — GATE-MET SOFT_PASS on haiku matches sibling DEBUG-TELEMETRY-GATE-MET (entry-state prose-leak, expected, transition_id_any handles it). No regressions, no triage needed. 7 Phase-3c pins deferred to Phase 2 per plan. -->

- [x] Phase 2: Discoverability wiring + structural pins + durable-doc sync  <!-- status: done; all 5 impl + all 4 verify nodes [x]; depends on Phase 1 -->
  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — user explicitly directed the full feature cycle.
  - Requirements unchanged: yes — Phase 1 landed exactly as specced; no scope drift.
  - Solution still feasible: yes — wiring targets surveyed at plan time, all present and unchanged.
  - No superior alternative discovered: yes — the recipe's 3-surface + 7-pin approach is the established pattern.
  **Verdict:** proceed
  **What:** Make the skill discoverable on all three agent-facing surfaces (Discipline 1) and regression-protected (Phase 3c pins), then sync durable docs. Adds the sibling-paragraph prose in the 3 caller skills, the 3 orchestrator AGENTS.md "Debug techniques" table rows, the transitions.md sidebar mention + a change-log entry, the 7 Phase 3c `grep_check` pins, and the arch.md/CLAUDE.md/lesson-doc count updates.
  **Observable outcomes:**
  - CLI: `grep -c '/debug-minimal-harness' skills/feature-build/SKILL.md skills/incident-investigate/SKILL.md skills/task-act/SKILL.md` == 1 each (caller-prose mention added to each existing Debug-technique Sidebar section).
  - CLI: `grep -c 'debug-minimal-harness' agents/feature-workflow/AGENTS.md agents/incident-workflow/AGENTS.md agents/task-workflow/AGENTS.md` ≥ 1 each (orchestrator Debug-techniques table row added).
  - CLI: `grep -q 'debug-minimal-harness' docs/product/transitions.md` exits 0 (Sidebar-skills mention).
  - CLI: `tests/check-structure.sh` executes exactly 7 explicit Phase 3c pins for debug-minimal-harness (3 caller + 3 orchestrator + 1 transitions.md), all PASS. [Corrected at P2 verify-self: the literal `grep -c 'debug-minimal-harness' tests/check-structure.sh` returns **5 source lines**, not 7 — two of the lines sit inside `for`-loops that expand 3× each at runtime (3 caller + 3 orchestrator = 6 from 2 looped lines, + 1 transitions.md = 7 logical pins). The runtime pin count is the load-bearing fact and it's 7; the source-line count is an authoring detail.]
  - CLI: `./tests/check-structure.sh` exits 0 with PASS count increased by +16 vs the pre-feature baseline (9 auto-iterated Phase 3b + 7 Phase 3c), 0 failures.
  - CLI: `grep -q 'debug-minimal-harness' docs/product/arch.md && grep -q 'debug-minimal-harness' CLAUDE.md` exits 0 (durable-doc sync — done at finalize, but pinned here as the target).
  - [x] P2.1 Added `/debug-minimal-harness` sibling paragraph to all 3 caller Debug-technique Sidebar sections: feature-build §4b, task-act §3b, incident-investigate §3b. Trigger = ≥2 hand-backs on a self-drivable behavioral bug → minimal repro + real input; RETURN-TO each respective caller.  <!-- status: done -->
  - [x] P2.2 Added `/debug-minimal-harness` row to the "Debug techniques (agent-pulled sidebars)" table in all 3 orchestrator AGENTS.md (feature-workflow, incident-workflow, task-workflow).  <!-- status: done -->
  - [x] P2.3 Added `/debug-minimal-harness` to transitions.md "Sidebar skills" examples list (codified 2026-06-23) + a dated Change Log entry at the top.  <!-- status: done -->
  - [x] P2.4 Extended check-structure.sh Phase 3c with exactly 7 grep_check pins: 3 caller-prose (new loop) + 3 orchestrator-row (added to existing orch loop) + 1 transitions.md mention.  <!-- status: done -->
  - [x] P2.5 Durable-doc sync: updated arch.md "Current sidebars" to name the third skill. CLAUDE.md needs NO per-skill edit (it points to AGENTS.md for the list, already updated) — verified, not assumed. docs/lessons/debug-skill-template.md "third, fourth, Nth" phrasing + "+16 PASS" projection stay accurate (this IS the third) — verified.  <!-- status: done -->
  - [x] verify-auto  <!-- status: done; check-structure.sh PASS 297/1 (the 1 FAIL = pre-existing claudesk settings-drift, unrelated). All 16 new pins green: 9 Phase-3b auto-iterated (sections+argument-hint+gate-check-first+≥4 tokens) + 7 Phase-3c explicit (3 caller-prose + 3 orchestrator-row + 1 transitions.md). +16 vs pre-feature baseline 281 — matches recipe projection. -->
  - [x] verify-self  <!-- status: done; subagent observed all 5 Phase-2 Observable Outcomes — outcomes 1/2/3/5 PASS; outcome 4 substance PASS (full check 297/1, sole FAIL = unrelated settings drift, 0 debug-minimal-harness pins in failure list, all 7 runtime pins green) — the only miss was the plan's imprecise `grep -c == 7` wording (returns 5 source lines; loops expand to 7 runtime pins), corrected in the observable-outcome text. Integration boundary APPLIES (edited 3 caller SKILL.md + 3 orchestrator AGENTS.md + check-structure.sh); outcomes cite each consuming surface by name. -->
  - [x] verify-human  <!-- status: done; operator approved all 4 leaves 2026-06-23 ("all pass") — integration boundary applied (F11 skip forbidden), genuine Mode-3 pause -->
    - [x] P2.verify-human.1 Caller-skill prose reads sensibly in all 3 existing Debug-technique Sidebar sections — PASS  <!-- status: done -->
    - [x] P2.verify-human.2 Orchestrator table rows read sensibly in all 3 AGENTS.md — PASS  <!-- status: done -->
    - [x] P2.verify-human.3 transitions.md examples-list + Change Log entry are accurate — PASS  <!-- status: done -->
    - [x] P2.verify-human.4 check-structure.sh PASS 297/1 (sole FAIL pre-existing & unrelated); all 16 debug-minimal-harness pins green — PASS  <!-- status: done -->
  - [x] verify-codify  <!-- status: done; permanent coverage = the 7 Phase-3c pins added in P2.4 (they ARE the regression tests for every consuming-surface edit, pinning each by name — integration-boundary coverage requirement satisfied). No new tests needed (duplicating would violate the don't-duplicate rule). Full structural suite PASS 297/1 — sole FAIL is pre-existing unrelated claudesk settings drift (not introduced by this feature, confirmed via git status; no triage artifact required for pre-existing env drift). All phases complete → F16. -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** finalize (shipped efba0ca; review-quality clean — 0 CRITICAL / 0 MAJOR / 2 MINOR auto-backlogged)
- **Blocked:** none
- **Unvisited:** finalize
- **Open discoveries:** arch.md size-guard note; install symlinks the skill DIRECTORY (P1.4); GATE-MET scenario needed transition_id_any [START,COMPLETE] (sonnet runs the whole technique → COMPLETE); pre-existing settings-fixture drift unrelated to feature (SURFACE, backlogged)

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
[SURFACED-2026-06-23] feature-spec — arch.md exceeds size guard (339 lines), read first 100 lines + headings only. Consider summarizing at next finalize.
[SURFACED-2026-06-23] P1.4 — install.sh symlinks the skill DIRECTORY into ~/.claude/skills/, not the SKILL.md file. Verify check is `test -L ~/.claude/skills/debug-minimal-harness` (corrected the plan's observable outcome).
[SURFACED-2026-06-23] P1 verify-auto — GATE-MET scenario: on sonnet the model runs the full technique on a gates-met fixture and emits the terminal DEBUG-MINHARNESS-COMPLETE (not the §1 informational START); harness keys on the last TRANSITION. Fixed scenario to `transition_id_any: [START, COMPLETE]` (both prove activation), matching the feature.yaml F16/F14 + session.yaml S9/F19 idiom. NOT a SKILL or model defect — scenario-design fix, stays on haiku.
[SURFACED-2026-06-23] P1 verify-auto — check-structure.sh has 1 pre-existing FAIL unrelated to this feature: settings-fixture drift (tests/fixtures/settings.json) from the claudesk app's externally-installed hooks.UserPromptSubmit entry. Logged to backlog. Not blocking.

## Code-Quality Review — debug-minimal-harness

### Strengths
- SKILL.md is a faithful structural clone of its two siblings (`debug-empirical-telemetry`, `debug-bisect-known-good`): same six canonical sections, same Gate-Check-first procedure shape, same four-token termination table, same sidebar-discipline closing paragraph.
- All three discoverability surfaces are wired atomically in the same commit (caller-prose in 3 SKILL.md, orchestrator rows in 3 AGENTS.md, transitions.md Sidebar-skills entry + Change Log) and each is pinned by a new Phase 3c `grep_check` — no silent drift gap.
- The §3 "drive with REAL input, never synthetic dispatch" core is genuinely load-bearing and concrete (per-surface examples for UI/CLI/HTTP/concurrency + false-pass rationale), not generic prose.
- Fixtures are well-targeted: each isolates exactly one failing gate; the gates-met fixture mirrors the real claudesk drag-reorder origin.
- The GATE-MET scenario stays untagged (haiku) and widens the assertion to `transition_id_any: [START, COMPLETE]` with an inline rationale rather than reaching for a preemptive `model: sonnet` tag — correct application of the empirical-tagging discipline.

### Issues
**CRITICAL**
- (none)

**MAJOR**
- (none)

**MINOR**
- [tests/scenarios/debug.yaml — GATE-MET] Uses `transition_id_any: [START, COMPLETE]` while both sibling GATE-MET scenarios assert a strict single `*-START`. The widening is justified and commented, but it is a divergence from the established sibling idiom; a future maintainer normalizing the three GATE-MET scenarios may not notice this one is intentionally looser. Inline comment mitigates.
- [skills/debug-minimal-harness/SKILL.md — Termination "5+ rounds" note] The optional-WIP-notes paragraph says "5+ rounds" while §6/inconclusive keys on "≥3 rounds" — internally consistent with the sibling precedent (telemetry uses the same 3-vs-5 split) but a reader may briefly trip on the differing thresholds. Cosmetic; matches sibling precedent.

### Assessment
Well-built, low-risk prose feature that adds the third debug-* sidebar by closely tracking the recipe and the two siblings. Advances the codebase rather than accruing debt: state machine untouched (no F/I/T/P/S ID), discoverability wiring complete and pin-enforced, the one substantive new idea (real-input-not-synthetic-dispatch) concrete and well-motivated. The pre-existing settings-fixture FAIL is unrelated and properly scoped out. No CRITICAL or MAJOR; two MINOR notes are idiom-divergence observations, not defects.

### If you disagree
Operator: dismiss any finding by editing this section in the WIP and marking the line `[DISMISSED]` before `feature-finalize` archives the WIP.

### Disposition (Mode 3 — autopilot)
Both MINOR findings auto-backlogged to `workflow/backlog-quality-findings.md` (pointer in `workflow/backlog.md`); no refactor invoked. F39 → finalize.

## Retrospect
- **What changed in our understanding:** The scope debate (A/B/C) before spec was the load-bearing decision, not the implementation. Generalizing from the literal learning (interactive UI only) to Scope B (any self-drivable behavioral bug) made the skill earn its place as a third sibling — keyed on *repeated hand-back + self-drivability*, a trigger neither existing debug-* skill owns. The mechanical build was almost entirely a faithful clone of the recipe.
- **Assumptions that held:** The `docs/lessons/debug-skill-template.md` "+16 PASS" projection was exact (9 Phase-3b auto-iterated + 7 Phase-3c explicit; baseline 281 → 297). The 4-artifact-kind recipe + 3-discoverability-surface discipline applied without surprise. CLAUDE.md correctly needed no per-skill edit (it points to AGENTS.md for the list).
- **Assumptions that were wrong:** Two small ones, both caught by verification, neither a defect: (1) the plan's observable outcome `test -L ...SKILL.md` was wrong — install symlinks the skill DIRECTORY, not the file (corrected at P1.4); (2) the GATE-MET scenario's `transition_id: START` was too strict — a capable model (sonnet) runs the whole technique to COMPLETE on a gates-met fixture, so it needed `transition_id_any: [START, COMPLETE]` (matching the established feature.yaml F16/F14 + session.yaml S9/F19 idiom). The latter is the one genuinely interesting find — it surfaced only because I ran the scenario on sonnet per the test-tagging discipline.
- **Approach delta:** Matched the plan's 2-phase structure exactly (Phase 1 = testable skill core; Phase 2 = wiring + pins + doc sync). The one process note: a reboot mid-Phase-1-verify-auto interrupted the scenario run; resumed cleanly from the WIP state with no lost work.

## Closure
**Feature complete:** `debug-minimal-harness` has shipped (commit efba0ca on main, not pushed). It's a `debug-*` sidebar that, when a behavioral fix has been handed back untested ≥2× and the behavior is drivable in a surface the agent controls, has the agent build a minimal standalone reproduction and drive it with real input (not synthetic dispatch) before re-presenting to the human. Verify via `/debug-minimal-harness <stalled-bug>` or see it listed in any orchestrator's "Debug techniques" table; structural coverage is the 16 check-structure.sh pins (PASS 297/1) + 3 debug.yaml scenarios. Requester = operator — closure notice for self-record.
