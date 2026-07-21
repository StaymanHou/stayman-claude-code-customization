# Feature: Boundary-handoff auto-chain — promote from prose into the state machine

**Workflow:** feature
**State:** COMPLETED 2026-07-21
**Created:** 2026-07-21
**Entry:** spec (complex feature)
**Source:** SURFACE-2026-07-21-BOUNDARY-HANDOFF-AUTOCHAIN-NOT-IN-STATE-MACHINE
**drive_mode:** autopilot
**Ship commit:** 3104205 · **Finalized:** 2026-07-21 (local, not pushed)

## Problem Statement

WP5/M9 (session-vocabulary-disambiguation) established a **CONTEXTUAL agent-side guard** with a load-bearing behavioral claim:

> *At a clean workflow boundary — after a terminal-close (`finalize`/`refactor`/`close`/`resolve`) → `session-reflect` with nothing to persist, or after `session-capture` once a learning is confirmed-saved — a session handoff is the natural, expected next step: **auto-chain it, no confirm — even in autopilot/FSD**. Only mid-workflow ambiguity fires the confirm-first guard.*

**Behavioral weighting (operator, from the WP5 origin session, 2026-07-21):** the auto-chain at a boundary is the **norm** — "*it's almost always an auto-chained session handoff*." The confirm-first guard is the **narrow exception** reserved for mid-workflow ambiguity, not the default posture. The modes where "does the machine actually authorize this auto-chain?" matters most are **autopilot and FSD** (no human present to catch a wrong read) — that is exactly why a table row / transition ID is needed rather than prose.

**The post-reflect path FORKS — two arms, both converging on the handoff (operator refinement, this session):**

```
terminal-close (finalize/refactor/close/resolve) → EXIT→reflect
                                                       │
                        ┌──────────────────────────────┴───────────────────────────┐
                   (no learning)                                          (learning found)
                        │                                                            │
                        │                                          session-capture (write + confirm "save")
                        │                                                            │
                        └──────────────────► session-handoff ◄───────────────────────┘
                                          (clean boundary, AUTO all modes)
```

- **Arm 1 — `reflect → session-handoff`:** reflect yields nothing to persist ("no learning") → auto-chain straight to the handoff.
- **Arm 2 — `session-capture → session-handoff`:** reflect surfaced a learning → `session-capture` writes it, and **once the operator confirms the save**, auto-chain to the handoff. The handoff rides *after* capture's existing human-confirm step — it does not fire the moment capture is invoked.

Both arms are AUTO at a clean boundary in all four drive modes; the mid-workflow ambiguous "pause/defer/wrap up" case is the narrow CONFIRM exception.

This behavior currently lives **only in advisory prose**, in three prose surfaces:
- `session-handoff/SKILL.md` (intent-disambiguation section)
- all 4 orchestrator `agents/*/AGENTS.md` (§Your-Role guard bullet)
- `CLAUDE.snippet.md` → `## Session vocabulary — turn vs. session boundary (GLOBAL)` (rule 2)

But **the state machine (`transitions.md`) does not model it**:

- **(a) No `reflect → session-handoff` edge AND no `session-capture → session-handoff` edge.** Every terminal-close transition exits `finalize/refactor/close/resolve → EXIT→reflect` (`F19`, `F21`, `T11`, `I10`), and `reflect` is the terminus — there is no modeled edge onward to a handoff on *either* arm of the fork. Reflect's meta-op Behavior text (transitions.md:433) and `session-capture`/`S20` (transitions.md:460) both say nothing about a post-boundary handoff auto-chain.
- **(b) `session-handoff` is explicitly "NOT a state-machine state"** (transitions.md:438). Its only ID `S17` is a **test-harness output label** ("Write `drive_mode` into `.session.md`") — not a transition *target* anything can chain *to*.
- **(c) The drive-mode pause-policy tables have zero rows for a post-reflect handoff.** Neither the canonical `transitions.md` "Drive modes" tables (feature/task/product/incident) nor the 4 `agents/*/AGENTS.md` cheat-sheet tables carry any row for a session-ops handoff, let alone the "AUTO in autopilot/FSD" claim.

**Why this is a real gap, not cosmetics:** the "auto-chain the handoff even in autopilot/FSD" claim is *exactly* the class of chaining decision the pause-policy tables exist to make authoritative. Asserting a chaining behavior in prose without a transition ID or a table row is the **same drift class** as the P1 autopilot-pause incidents (chaining behavior living in prose the orchestrator reads inconsistently). It works today only because the orchestrator happens to read the prose; the machine formally stops one step short of the behavior the prose assumes. This is a **consistency/correctness gap in a dogfooding repo whose product IS the state machine** — the three-places-in-sync rule (`transitions.md` / `SKILL.md` / scenarios) is currently violated for this behavior.

## User Stories

- As **the orchestrator driving in autopilot/FSD**, I want a modeled transition (with an ID) and a pause-policy row for the post-reflect boundary handoff, so I chain it deterministically from the table — not from prose I might read inconsistently.
- As **a maintainer editing the state machine**, I want the boundary-handoff behavior to satisfy the three-places-in-sync rule (transition table + skill prose + scenario), so future edits can't silently drift it.
- As **a test author**, I want a behavioral scenario asserting the boundary auto-chain fires (and that mid-workflow ambiguity still confirms), so the two halves of the WP5 contextual guard are both regression-covered.
- As **the operator**, I want the human-readable prose to stay legible while the *table* becomes the authoritative source, so I don't lose the plain-English statement of the rule.

## Scope: the FULL post-terminal chain (operator decision, this session)

The feature models the **entire `finalize → reflect → [capture] → handoff` exit sequence**, not just the two new handoff edges. The whole chain is currently a run of meta-op hops that are "declared auto" (or not modeled at all) but **absent from every drive-mode pause-policy table** — reflect and session-capture are meta-ops in the "Session Operations (Cross-Cutting)" table with **zero rows** in the 4 Drive-mode tables, and `finalize → reflect` (F19/F21/T11/I10) is itself "declared auto" yet reflect has no pause-policy row. Modeling only the two handoff edges would move the same drift one hop upstream; the operator chose to close the chain end-to-end.

**Two design decisions resolved (this session — do NOT re-open at plan time):**

- **D1 — NO `finalize → handoff` shortcut.** The chain is always `finalize → reflect`; the fork happens *at* reflect. Reflect is the only step that can judge "nothing to learn," it is cheap, and it is the once-per-session backstop (learning-filter + design-prior capture). A trivial close still runs `finalize → reflect → handoff` fast — there is no edge that skips reflect. *(Rationale in full in the Q1 discussion; the asymmetry is: the "no-learning → handoff" arm is honest only because reflect decided it, not because finalize guessed.)*

- **D2 — Modeling: meta-op edges (not first-class states).** `session-handoff`, `reflect`, and `session-capture` stay meta-operations (transitions.md:438 declaration preserved). The chain is modeled as **modeled edges + pause-policy rows**, consistent with how reflect/capture are already meta-ops — NOT by promoting any of them to a dispatched workflow state. This was effectively settled in the WP5 origin session (reading (b): "add a post-terminal transition `S22: reflect → session-handoff` + a pause-policy row").

## Acceptance Criteria

The feature is done when:

**Modeling the two-arm fork (the new handoff edges):**
1. **Arm-1 edge `S22: reflect → session-handoff`** is modeled in `transitions.md` — condition "clean boundary + reflect yielded nothing to persist (no learning)", type forward, **AUTO in all four drive modes**.
2. **Arm-2 edge `S23: session-capture → session-handoff`** is modeled in `transitions.md` — condition "clean boundary + learning captured AND save landed", type forward, **AUTO in all four drive modes**. Gated *after* capture's write step (rides after the save, not on capture invocation).
3. **Reflect's fork is explicit** — reflect's meta-op Behavior text (transitions.md:433) names the two-arm fork: no-learning → `S22` handoff; learning-found → `session-capture` → `S23` handoff. Reflect is no longer presented as an unconditional terminus.

**The full chain's pause-policy rows (three-places-in-sync at the TABLE level):**
4. **A "Session-boundary exit chain" pause-policy block** is added to `transitions.md` "Drive modes" **AND** to all 4 canonical `agents/*/AGENTS.md` cheat-sheet tables, with rows for every hop: `finalize/refactor/close/resolve → reflect` (declared-auto made explicit), `reflect → handoff` (S22, AUTO all modes), `reflect → capture` (learning found), `capture → handoff` (S23, AUTO all modes). Each row states its per-mode AUTO/PAUSE/CONFIRM behavior.
5. **The mid-workflow-ambiguity CONFIRM case is represented** as the narrow exception (a condition note on the boundary rows, per the resolved design: the confirm is the *absence* of the auto-chain, gated on ambiguity — not its own transition target). Preserves the WP5 bidirectional guard; the boundary auto-chain is the NORM, confirm is the exception.

**The bundled capture-gate refinement (operator decision Q2 — conditional drop):**
6. **`session-capture/SKILL.md` §4 confirmation gate becomes drive-mode-conditional:** in **autopilot/FSD**, a **`[PROJECT]`-scope** capture **skips the STOP-and-ask and auto-writes**, but fully **surfaces path + content + scope in chat as a read-time veto** (mirroring `feature-review-quality` Mode-3 auto-backlog + `feature-verify-human` auto-skip affirmation blocks). A **`[GLOBAL]`-scope** capture **keeps the confirm gate even in autopilot/FSD** (higher blast radius; every logged reflect scope-correction was `[GLOBAL]`→`[PROJECT]`). **Modes 1/2 keep the gate unconditional (unchanged).** The auto-write path still honors the existing §5 amend-into-HEAD + artifact-tracking-policy git rules.
7. **`S20` (session-capture terminal) is updated** to reflect the conditional gate + that it can now auto-chain onward to `S23` handoff at a clean boundary.

**Verification, sync, and docs:**
8. **Behavioral scenarios** in `tests/scenarios/session.yaml` (next free IDs after S27): at minimum (a) boundary auto-chain fires at a clean boundary in autopilot on the no-learning arm; (b) the mid-workflow ambiguous case still CONFIRMs; ideally (c) the capture-gate conditional drop — `[PROJECT]` auto-writes vs `[GLOBAL]` confirms in autopilot. Uses the established session-scenario shape (`transition_id` / `transition_id_any` / `contains_any`→SOFT_PASS for prose-behavior).
9. **`tests/check-structure.sh` structural pins** assert the new `S22`/`S23` IDs + the session-boundary-exit-chain pause-policy rows are present in `transitions.md` AND the 4 AGENTS.md tables (mechanical three-places coverage) + the capture-gate conditional-drop clause is pinned in `session-capture/SKILL.md`, consistent with how WP5 [Phase 17] pinned the guard prose. (Likely extend [Phase 17] or add a new phase.)
10. **`arch.md` is resynced** with a short as-built subsection recording (a) the boundary-handoff auto-chain promoted from prose into the state machine (full chain, meta-op-edge modeling per D2), and (b) the capture-gate conditional drop. May be an addendum to AD-4.
11. **The WP5 prose is preserved** as the human-readable statement (kept, not deleted) but re-pointed so the table is authoritative — no contradiction between prose and table. `CLAUDE.snippet.md` § Session-vocabulary rule 2 gets the "table is now authoritative" re-point + the capture-gate note.
12. **`check-structure.sh` passes green** (no regressions) and the WP5 [Phase 17] pins still hold.
13. **The SURFACE is resolved + deleted** per delete-on-resolve on finalize, with a `**Backlog resolved:**` CHANGELOG line.

## Out of Scope

- **Handoff/reflect auto-chain: no NEW orchestrator runtime behavior.** The orchestrator already auto-chains the handoff at a clean boundary and confirms mid-workflow (WP5 shipped that). Modeling it (edges + rows) makes the *machine match the shipped behavior* — a consistency fix, not new behavior. If planning reveals the prose and the desired behavior actually disagree, that's a back-loop to spec, not silent scope expansion.
- **The capture-gate conditional drop IS a deliberate behavior change (in scope, bundled).** Unlike the handoff edges (which only model existing behavior), AC-6 changes what `session-capture` *does* in autopilot/FSD (`[PROJECT]`-scope auto-writes instead of stopping). This is an intentional, operator-approved bundle to streamline the exit — flagged explicitly so it is not mistaken for scope creep. It is the ONE genuine behavior change in the feature.
- **No change to the turn-level "pause"/"stop"/"hold" semantics** (WP5 settled those — bare pause = turn-level interrupt, no artifact). This feature only concerns the *session-boundary exit chain*.
- **No change to `session-restore` or `session-reflect`'s internal procedures** beyond the minimal edge/description wording needed to model the fork. (`session-capture` §4 *is* changed — see AC-6.)
- **Not making `session-start`, `session-handoff`, `reflect`, or `session-capture` first-class dispatched states** — D2 keeps them meta-ops; we add modeled edges + rows only.
- **No new runtime, no code** — prompt/markdown/table/scenario/pin editing only (consistent with this repo's no-runtime architecture, arch.md:11).
- **`/project-handoff`** (the WP8 cross-repo analogue) is untouched — this is purely the intra-session boundary exit chain.

## Technical Constraints

- **No 3rd-party dependency** — skipped the 3rd-party probe check (prompt/markdown edits only).
- **State-machine-lives-in-three-places sync rule** (CLAUDE.md → Architecture): any transition add/reword must update `transitions.md` + the per-skill/agent prose + `tests/scenarios/*.yaml`. This feature is *explicitly about honoring* that rule for the boundary handoff, so all three must land together.
- **Path-qualification mandate** (CLAUDE.md): every `.claude/` reference in edited prompt prose stays explicitly `~/.claude/` or `<proj-dir>/.claude/`. Enforced by check-structure.sh Phase 12.
- **WP5 [Phase 17] pins must not regress** — the contextual-guard prose pins + the `/restore` collision guard + the `/resume`-is-turn-level anti-trigger all stay green.
- **Meta-op identity preserved (D2):** transitions.md:438 declares session entry skills (incl. `session-handoff`) are "dispatchers and meta-operations, not state-machine states." The added `S22`/`S23` edges are modeled edges in the "Session Operations (Cross-Cutting)" section + pause rows — they do NOT reclassify any meta-op as a dispatched state, keeping internal consistency with how `reflect` and `session-capture` are already modeled.
- **Two ID namespaces — don't conflate them.** (1) **Transition/edge IDs** `S22` (reflect→handoff) and `S23` (capture→handoff) are new *transition* IDs added to the Session-transitions table. (2) **Scenario IDs** in `tests/scenarios/session.yaml` are a *separate* namespace (last used S26/S27 by WP5); new scenarios pick the next free scenario IDs (S28+). A scenario ID and a transition ID sharing the "S" prefix is pre-existing convention noise — the plan must be explicit which is which to avoid a collision.
- **Known harness limitation:** `tests/run-tests.sh --id <ids>` parses ALL scenarios before applying the `--id` filter (SURFACE-2026-07-15, medium) — this materially blocked WP5's S26/S27 behavioral execution (2-scenario run hung >5min). New session scenarios may hit the same wall on a targeted run; plan should account for this (full-group sweep, or accept deferred execution as WP5 did). **Known dependency risk to call out at plan time**, not fixed here.
- **`session-capture` amend-into-HEAD interaction:** AC-6's autopilot auto-write path still runs §5's `git commit --amend --no-edit` (project-scope) / artifact-tracking git rules. The plan must ensure the read-time-veto surface prints *before or with* the amend so the operator can `git reset` if they disagree — auto-write must not mean silently-amended-and-gone.

## Open Questions

- [x] **RESOLVED (D1): no `finalize → handoff` shortcut.** Always `finalize → reflect`; fork at reflect. (Operator, this session.)
- [x] **RESOLVED (D2): meta-op edges, not first-class states.** `S22`/`S23` are modeled edges + rows; no meta-op is reclassified as a dispatched state. (Operator this session + WP5 origin-session reading (b).)
- [x] **RESOLVED (scope): full chain.** Model the entire `finalize → reflect → [capture] → handoff` sequence, not just the two handoff edges. (Operator, this session.)
- [x] **RESOLVED (Q2 bundle): capture-gate conditional drop.** Autopilot/FSD `[PROJECT]` auto-writes (read-time veto); `[GLOBAL]` keeps the gate; Modes 1/2 unchanged. Bundled into this feature. (Operator, this session.)
- [x] **RESOLVED (mid-workflow confirm): condition note, not a separate transition ID.** The confirm is the *absence* of the auto-chain (a guard gated on ambiguity), so it is a condition note on the boundary rows — not its own edge ID.
- [ ] **No unknowns requiring `/feature-research`.** All affected files (transitions.md, 4 AGENTS.md, session-capture/SKILL.md, session.yaml, check-structure.sh, arch.md, CLAUDE.snippet.md) are read and mapped. → **F4 → plan.**

## Notes for planning

- **Blast radius (mapped, full-chain scope):**
  - `transitions.md` — Session-Operations table (`reflect` + `store-learning`/`capture` Behavior rows) · Session-transitions table (+`S22`, +`S23`; update `S17`/`S20`) · the 4 Drive-mode pause tables (+ a "Session-boundary exit chain" block in each — but note the incident table is "all modes Mode-2"; the chain rows still apply post-`I10`).
  - 4× `agents/{feature,task,product,incident}-workflow/AGENTS.md` — cheat-sheet tables (+ exit-chain rows) + the §Your-Role guard bullet re-point ("table is authoritative").
  - `skills/session-capture/SKILL.md` — §4 gate → drive-mode-conditional; §5/§6 read-time-veto surface + amend-ordering note; §S20 terminal note.
  - `skills/session-reflect/SKILL.md` — name the two-arm fork onward (light; reflect already prompts capture — add the "→ handoff at clean boundary" onward step).
  - `tests/scenarios/session.yaml` — +2–3 scenarios (next free IDs **S28+**; NOT S22/S23 which are transition IDs).
  - `tests/check-structure.sh` — + pins (extend [Phase 17] or new phase): S22/S23 present; exit-chain rows in transitions.md + 4 AGENTS.md; capture-gate conditional clause.
  - `arch.md` — as-built resync (addendum to AD-4 or new subsection).
  - `CLAUDE.snippet.md` — § Session-vocabulary rule 2 re-point + capture-gate note.
  - `CLAUDE.md` — pointer bullet (optional).
- **Likely 2 phases** (Phase 1: model the full chain — transitions.md edges/rows + 4 AGENTS.md + reflect/capture SKILL.md prose + capture-gate behavior change; Phase 2: scenarios + check-structure.sh pins + arch/snippet resync). The capture-gate behavior change (AC-6) is the one leaf that has a real *behavioral* verify surface (does `[PROJECT]` auto-write & `[GLOBAL]` confirm in autopilot?) — everything else is structural/prose.
- **Verify-self surface:** mostly a docs/prompt feature — verify leans on `check-structure.sh` (structural) + `run-tests.sh` session scenarios (subject to the known `--id` parse-all limitation). The AC-6 capture-gate is the one genuinely behavioral leaf and should get a real behavioral scenario.
- **Integration-boundary note:** AC-6 modifies `session-capture` which is *consumed* by the reflect→capture handoff prose and by `session-start`'s orchestration — verify-self/human/codify should cite the capture skill's own behavior as the consuming surface per the integration-boundary rule.

## Work Tree

- [x] Phase 1: Model the full exit chain + capture-gate behavior change  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `grep -c '^| S22 ' workflow-system/product/transitions.md` ≥ 1 AND `grep -c '^| S23 ' workflow-system/product/transitions.md` ≥ 1 (the two new transition-table rows exist).
  - CLI: `grep -q 'reflect → session-handoff' workflow-system/product/transitions.md` exits 0 AND `grep -q 'session-capture → session-handoff' workflow-system/product/transitions.md` exits 0 (both fork arms named).
  - CLI: `grep -lc 'Session-boundary exit chain' agents/feature-workflow/AGENTS.md agents/task-workflow/AGENTS.md agents/product-workflow/AGENTS.md agents/incident-workflow/AGENTS.md` returns 4 files (exit-chain block in all 4 canonical tables).
  - CLI: reflect's Behavior text in transitions.md names both arms — `grep -A2 '| \`reflect\`' workflow-system/product/transitions.md` mentions the no-learning → handoff (S22) and learning → capture → handoff (S23) fork.
  - CLI: `session-capture/SKILL.md` §4 carries the drive-mode-conditional gate — `grep -qE 'autopilot|fsd' skills/session-capture/SKILL.md` in the §4 region AND both `[PROJECT]`-auto-write and `[GLOBAL]`-keeps-gate clauses present (`grep -q 'read-time veto' skills/session-capture/SKILL.md` exits 0).
  - CLI: no bare `.claude/` regression — `tests/check-structure.sh` Phase 12 stays green after the capture SKILL edits (path-qualification mandate).
  - [x] P1.1 `transitions.md` — add `S22: reflect → session-handoff` + `S23: session-capture → session-handoff` to the Session-transitions table; update `S17` (handoff is now a chain target) + `S20` (capture can auto-chain onward) notes. Add the two-arm fork to the `reflect` Behavior row (transitions.md:433) + the `store-learning`/capture Behavior row (:434). Preserve the transitions.md:438 "meta-op, not a state" declaration (D2).  <!-- status: complete -->
  - [x] P1.2 `transitions.md` "Drive modes" — add a "Session-boundary exit chain" pause-policy block (rows: `finalize/refactor/close/resolve → reflect` declared-auto; `reflect → handoff` S22 AUTO-all-modes; `reflect → capture` learning-found; `capture → handoff` S23 AUTO-all-modes) + the mid-workflow-ambiguity CONFIRM condition note (the narrow exception; auto-chain is the norm). Note the incident table's all-modes-Mode-2 caveat still applies post-I10.  <!-- status: complete -->
  - [x] P1.3 4× `agents/{feature,task,product,incident}-workflow/AGENTS.md` — add the matching "Session-boundary exit chain" rows to each cheat-sheet table (three-places-in-sync at table level) + re-point the §Your-Role guard bullet to "the pause-policy table is authoritative; prose is the human-readable statement."  <!-- status: complete -->
  - [x] P1.4 `skills/session-capture/SKILL.md` — §4 gate → drive-mode-conditional (AC-6): autopilot/FSD + `[PROJECT]` scope → skip STOP-and-ask, auto-write, surface path+content+scope as read-time veto; `[GLOBAL]` scope → keep confirm gate even in autopilot/FSD; Modes 1/2 → unchanged. §5/§6 — ensure the read-time-veto surface prints before/with the `git commit --amend` so the operator can `git reset`. Update the §S20 terminal note (can now auto-chain to S23 handoff).  <!-- status: complete -->
  - [x] P1.5 `skills/session-reflect/SKILL.md` — add the onward "→ handoff at clean boundary" step to the two-arm fork (no-learning → S22 handoff; learning → capture → S23 handoff). Light: reflect already prompts capture; add the boundary-handoff continuation.  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; check-structure.sh 452/0, no regression (WP5 [Phase 17] pins all green) -->
  - [x] verify-self  <!-- status: complete; subagent OC1–OC7 all PASS (S22/S23 rows, 4× exit-chain blocks, reflect fork, capture conditional gate + read-time veto, no bare .claude/ regression). Integration boundary: session-capture own behavior — cited by OC5. -->
  - [x] verify-human  <!-- status: complete; operator approved all 4 leaves "all good" 2026-07-21 -->
    - [x] P1.verify-human.1 Two-arm fork reads correctly in transitions.md (reflect Behavior row + S22/S23 rows)  <!-- status: complete -->
    - [x] P1.verify-human.2 AC-6 capture gate: [PROJECT] auto-writes / [GLOBAL] confirms / Modes 1-2 unchanged — reads as intended  <!-- status: complete -->
    - [x] P1.verify-human.3 "table is authoritative, prose is human-readable" re-point reads right in the 4 AGENTS.md  <!-- status: complete -->
    - [x] P1.verify-human.4 No-finalize→handoff-shortcut (D1) + mid-workflow-ambiguity-CONFIRM exception both preserved  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete; no existing test broke (452/0, six-case triage not triggered). Integration-boundary consuming-surface test (AC-6 capture-gate) confirmed routed to Phase 2 P2.2 (scenario S30) — not duplicated here. New Phase-1 coverage IS Phase 2's deliverable (P2.1 pins + P2.2 scenarios) by design. -->

- [x] Phase 2: Codify — scenarios, structural pins, arch/snippet resync  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `tests/check-structure.sh` exits 0 (all pins green, no WP5 [Phase 17] regression). New pins present: `grep -c 'S22\|S23' tests/check-structure.sh` ≥ 2 and a "Session-boundary exit chain" pin fires against transitions.md + the 4 AGENTS.md + capture-gate clause.
  - CLI: `tests/scenarios/session.yaml` parses (valid YAML) and contains ≥2 new scenarios with descriptive IDs `S28+` (NOT S22/S23) — `grep -cE '^\s+- id: S2[89]|^\s+- id: S3[0-9]' tests/scenarios/session.yaml` ≥ 2.
  - CLI: behavioral run of the new session scenarios (or the full session group) shows PASS/SOFT_PASS — subject to the known `--id` parse-all limitation (may require full-group sweep or deferred execution as WP5 did; documented, not a blocker).
  - CLI: `arch.md` carries an as-built entry — `grep -qi 'boundary.*handoff.*state machine\|exit chain' workflow-system/product/arch.md` exits 0.
  - CLI: `CLAUDE.snippet.md` § Session-vocabulary rule 2 re-pointed — `grep -q 'table is.*authoritative\|pause-policy table' CLAUDE.snippet.md` exits 0 AND the capture-gate note present.
  - [x] P2.1 `tests/check-structure.sh` — added new [Phase 18] block (17 pins): S22/S23 edges in transitions.md; "Session-boundary exit chain" block in transitions.md + all 4 AGENTS.md; guard re-point in 4 AGENTS.md; capture §4 conditional-gate + [PROJECT]-auto-write + [GLOBAL]-confirm + read-time-veto clauses; snippet re-point. WP5 [Phase 17] pins untouched. 469/0.  <!-- status: complete -->
  - [x] P2.2 `tests/scenarios/session.yaml` — added S28 (boundary reflect no-learning → auto-chain handoff), S29 (mid-workflow defer/wrap-up still CONFIRMs — counterpart to S28), S30 (capture-gate [PROJECT] auto-write vs [GLOBAL] confirm in autopilot). Non-echoing tokens; reused fixtures feature-finalized-no-debt.md + feature-autopilot-active.md. YAML parses.  <!-- status: complete -->
  - [x] P2.3 `workflow-system/product/arch.md` — added AD-4 addendum (as-built 2026-07-21): boundary-handoff promoted into state machine (D1 no-shortcut, D2 meta-op-edges) + AC-6 capture-gate conditional drop. Bumped `updated: 2026-07-21`.  <!-- status: complete -->
  - [x] P2.4 `CLAUDE.snippet.md` § Session-vocabulary rule 2 — added "table is authoritative" re-point sub-bullet + capture-gate conditional-drop note; `CLAUDE.md` convention bullet added after the WP5 session-vocab bullet.  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete; check-structure.sh 469/0 (17 new [Phase 18] pins green, no regression); session.yaml parses valid -->
  - [x] verify-self  <!-- status: complete; subagent OC1–OC5 all PASS (469/0 with 17 [Phase 18] PASS lines; S28-S30 parse + valid fixtures/skills; arch AD-4 addendum + date; snippet re-point + capture-gate note; WP5 [Phase 17] 0 FAIL). CAVEAT surfaced: S28-S30 BEHAVIORAL execution UNVERIFIED (blocked by SURFACE-2026-07-15 --id parse-all harness bug — same as WP5 S26/S27); structurally verified only. -->
  - [x] verify-human  <!-- status: complete; operator approved vh.2 + vh.3; vh.1 resolved by ADDING Phase 3 (fix harness bug + run scenarios) rather than accepting execution-deferral -->
    - [x] P2.verify-human.1 S28–S30 scenarios: operator REJECTED the execution-deferral — directed to fix the --id harness bug (SURFACE-2026-07-15) and actually run the scenarios. Resolved by adding Phase 3 (not a defect in the scenarios themselves — their intent was approved).  <!-- status: complete -->
    - [x] P2.verify-human.2 [Phase 18] pins are the right codification (right anchors, three-places coverage) — approved  <!-- status: complete -->
    - [x] P2.verify-human.3 arch.md AD-4 addendum + CLAUDE.snippet.md/CLAUDE.md re-points read accurately — approved  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete; Phase 2 codify artifacts are the coverage themselves — no NEW tests to write here (the scenarios+pins ARE Phase 2's output). No existing test broke (469/0). BEHAVIORAL run of S28-S30 is now scheduled as Phase 3 (P3.3) per the operator's vh.1 decision, not deferred. -->

- [x] Phase 3: Fix the `--id` parse-all harness bug + run the session scenarios behaviorally  <!-- status: complete; added mid-feature per operator vh.1 (2026-07-21) -->
  **Why (added mid-feature):** operator rejected deferring S28–S30 behavioral execution (vh.1). The blocker is `SURFACE-2026-07-15-RUN-TESTS-ID-FILTER-PARSES-ALL-SCENARIOS-FIRST`: `tests/run-tests.sh --id <ids>` parses ALL scenarios before applying the `--id` filter, so a targeted 2–3 scenario run hangs >5 min. Fixing it unblocks behavioral verification of THIS feature's scenarios (S28–S30) AND retroactively WP5's S26/S27 — and resolves that SURFACE.
  **Observable outcomes:**
  - CLI: a targeted `tests/run-tests.sh --id S28-...,S29-...,S30-... --dry-run` returns in **< 30s** (was: never printed within 60s / hung >5min) — the pre-parse `id`-scan skips non-matching scenarios before the expensive `parse_scenario_*` shell-outs.
  - CLI: `tests/run-tests.sh --id <one existing id> --dry-run` lists exactly that 1 scenario (single-id correctness); `--id A,B` lists exactly 2 (multi-id); `--group session --dry-run` still lists the full session group (group path unaffected). Property-check across single/multi/none/group.
  - CLI: a real (model-executing) run of S28/S29/S30 (+ S26/S27) completes and reports PASS/SOFT_PASS (no FAIL) — the actual behavioral verification vh.1 asked for. (Subject to model nondeterminism; `max_retries: 2` per scenario. Uses the runtimes.md `run-tests.sh --id` estimator for timeout.)
  - CLI: `tests/check-structure.sh` still 469/0 (the run-tests.sh change touches no structural pins; confirm no regression).
  - [x] P3.1 `tests/run-tests.sh` — hoisted a cheap `id`-only pre-parse gate to the TOP of `run_test()` (before the ~22 expensive parse shell-outs); applies `--id` AND `--filter-model` there and `return`s early on non-match. Removed the now-redundant post-parse filter block. Root cause confirmed: each `parse_scenario_field`/`parse_scenario_nested` spawns a fresh python3 that re-parses the whole YAML, so the old parse-then-filter cost ~22 full-file parses per non-matching scenario (the >5min hang). `--group`/no-filter paths behavior-identical.  <!-- status: complete -->
  - [x] P3.2 Property-checked the filter: `--id` single (1 selected, 22.5s vs prior >5min hang), multi (3), bad-id (0), `--group session` (36 = full group, unaffected), `--group`+`--id` combined (1 = intersection). All correct across the input namespace; targeted path fast. `bash -n` clean. No new structural pin — this is a shell-internal control-flow fix; the property matrix + the behavioral run (P3.3) are the coverage.  <!-- status: complete -->
  - [x] P3.3 Ran S26,S27,S28,S29,S30 behaviorally (haiku, via the now-fast `--id` path): **session 0 PASS / 5 SOFT_PASS / 0 FAIL / 0 FLAKY** in 35s, $0.29 (run-2026-07-21-191313.json). SOFT_PASS is the CORRECT shape — these are prose-behavior guard scenarios that emit no structured TRANSITION token, so the harness matches `contains_any` → SOFT_PASS (same shape as the R1–R3 reflect scenarios). Each matched its intended non-echoing token: S26/S27/S29 → `turn-level`, S28 → `session-handoff` (boundary auto-chain fires), S30 → `auto-write` (AC-6 [PROJECT] auto-write). No FAIL → no triage needed. Phase-2 verify-self "UNVERIFIED-by-execution" caveat is now **VERIFIED** — and this also executed WP5's S26/S27 which WP5 had to defer.  <!-- status: complete -->
    - [SURFACED-2026-07-21] P3.2 — `--id`/`--group` dry-runs still walk all 8 groups' `id` parses (~22s), not just the targeted group. The hang is fixed (22× fewer parses), but a further optimization (skip whole non-`--group` files, or a per-file id-prescan) could make targeted runs near-instant. Minor; logged, not addressed here.  <!-- status: SURFACED: further --id speedup possible (skip non-target files) -->

  - [x] verify-auto  <!-- status: complete; bash -n run-tests.sh clean; check-structure.sh 469/0 (harness change touches no structural pins, no regression) -->
  - [x] verify-self  <!-- status: complete; subagent OC1–OC4 all PASS: fast targeted run (22s, 1 selected — was >5min hang); filter correctness 3/0/1; behavioral 5 SOFT_PASS/0 FAIL (from results JSON); 469/0 + syntax clean. -->
  - [x] verify-human  <!-- status: complete; operator approved P3.verify-human.1 "approve" 2026-07-21 -->
    - [x] P3.verify-human.1 The --id fix + the now-passing S26–S30 run satisfies the vh.1 ask (scenarios actually verified, not deferred); fix approach acceptable — approved  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete; coverage already exists (S26-S30 now RUN = 5 SOFT_PASS end-to-end through the fixed harness + P3.2 property matrix) — no NEW test needed for a shell control-flow reorder. No existing test broke (469/0); six-case triage not triggered. Integration-boundary consuming-surface (the harness) exercised by the behavioral run. -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** review-quality COMPLETE (0 CRITICAL / 0 MAJOR / 3 MINOR — all auto-backlogged, F39); next: finalize
- **Ship:** commit 3104205, local, not pushed (21 ahead)
- **Blocked:** none
- **Unvisited:** ship → review-quality → finalize
- **Open discoveries:** SURFACE-2026-07-21-RUN-TESTS-ID-DRYRUN-STILL-WALKS-ALL-FILES (low; further `--id` speedup — logged to backlog, not addressed here)
- **ALL PHASES COMPLETE:** Phase 1 (model full exit chain + AC-6 capture gate), Phase 2 (codify — pins/scenarios/arch/snippet, 469/0), Phase 3 (fix `--id` harness bug + S26–S30 behavioral 5 SOFT_PASS). Resolves SURFACE-2026-07-15 + SURFACE-2026-07-21-BOUNDARY-HANDOFF-AUTOCHAIN-NOT-IN-STATE-MACHINE. Ready to ship.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
- (none yet)

## Code-Quality Review — boundary-handoff-autochain-state-machine

Reviewed against ship commit 3104205 (Mode 3 autopilot). **0 CRITICAL, 0 MAJOR, 3 MINOR** → clean (MINOR auto-backlogged, F39 → finalize).

### Strengths
- Three-places-in-sync executed cleanly: S22/S23 in transitions.md (both tables) + 4 AGENTS.md + Phase-18 pins — no layer left behind.
- `run-tests.sh` filter-hoist correct + well-documented: old post-parse filter fully removed (no dead code), both `--id`/`--filter-model` gates moved above the ~20 expensive parses, no-filter/`--group` fall-through provably unchanged.
- AC-6 tightly scoped + honestly labeled as the ONE behavior change; `[GLOBAL]`-confirm / `[PROJECT]`-auto-write split grounded in logged-scope-correction evidence; print-before-amend ordering is a hard requirement.
- §4 rewrite forbids any user-input tool on the auto-write path (same regression class as an AUTO-transition AskUserQuestion) — pre-empts the exact chain-defeating failure.
- D2 (meta-op edges, not dispatched states) preserves the "not a state machine" declaration; surface grows by two labeled edges, not two states.

### Issues
**CRITICAL** — (none)
**MAJOR** — (none)
**MINOR**
- [transitions.md Session-transitions table] S-ID sequence reads S17,S18,S20,S22,S23 — S19/S21 absent + undocumented; a one-line "S19/S21 unused" note (mirroring how F17-retired is called out) would prevent accidental reuse. → backlogged.
- [4× AGENTS.md guard bullet] The new "pause-policy table is authoritative" bullet is nested at 5-space under the CONTEXTUAL-guard bullet but reads as a peer statement about the whole chaining decision; cosmetic, identical across all 4. → backlogged.
- [session.yaml S29] `not_contains: TRANSITION: S17` is near-inert (the `.session.md`/`Handed off` string guards already cover the real mis-fire); low-weight assertion, not wrong. → backlogged.

### Assessment
Well-built, disciplined "promote prose into the state machine" change: two labeled meta-op edges + one authoritative Drive-modes block replicated verbatim-consistent across 4 orchestrators + matching pins, preserving the meta-op invariant rather than over-modeling. The one behavior change (AC-6) is isolated, evidence-grounded, and defended against the obvious regression. The bundled `run-tests.sh` fix is a clean reorder with no unfiltered path and no count-semantics drift. Advances the codebase (retires a known prose-vs-machine drift); accrues no meaningful debt; only findings are cosmetic.

### If you disagree
Dismiss any finding by editing this section and marking the line `[DISMISSED]` before finalize archives the WIP.

## Retrospect
- **What changed in our understanding:** The gap was deeper than the SURFACE first framed it. What began as "add a `reflect → session-handoff` edge" grew — via operator input — into modeling the **whole** `finalize → reflect → [capture] → handoff` exit chain (the drift wasn't at one hop, it ran the length of the meta-op chain), a **two-arm fork** at reflect (no-learning → S22; learning → capture → S23), and a bundled **behavior change** (AC-6 capture-gate conditional drop) that the modeling exposed as a natural streamlining. Reading the WP5 origin session's raw log was decisive — the operator's turn-13 "does the state machine authorize this in autopilot/FSD?" and the assistant's own reading-(b) recommendation had effectively pre-decided the modeling shape, so the initial AskUserQuestion re-litigated a settled call.
- **Assumptions that held:** D2 (meta-op edges, not first-class states) was the right, least-invasive modeling — consistent with reflect/capture already being meta-ops. The three-places-in-sync discipline held across a wide blast radius (transitions.md + 4 AGENTS.md + scenarios + pins) with no drift (review-quality confirmed verbatim-consistency across the 4 exit-chain blocks).
- **Assumptions that were wrong:** (a) I initially under-modeled the fork as a single edge; the operator's "if reflect yielded no learning then handoff, else capture then handoff" correction made it two edges. (b) I planned to *accept* deferring the S28–S30 behavioral execution (WP5 precedent); the operator rejected that and directed fixing the `--id` harness bug instead — which turned a deferred-verification into a real 5-SOFT_PASS run AND resolved a second SURFACE. The mid-feature Phase 3 add was the right call.
- **Approach delta:** Plan was 2 phases; became 3 (Phase 3 added at Phase-2 verify-human per the operator's vh.1 decision — a scope-add, not a back-loop). Everything else matched the plan. The `--id` fix root cause (each parse_scenario_* spawns a fresh python re-parsing the whole YAML → ~22 full parses per non-matching scenario) was exactly as the SURFACE predicted.

## Communicate
> **Feature complete:** boundary-handoff-autochain-state-machine has shipped. It promotes the WP5 "auto-chain the session handoff at a clean workflow boundary" rule from advisory prose into the state machine — the full `finalize → reflect → [capture] → handoff` exit chain is now modeled as meta-op edges (S22/S23) + a "Session-boundary exit chain" pause-policy block replicated across transitions.md and all 4 orchestrator AGENTS.md — plus the AC-6 capture-gate conditional drop (autopilot/FSD `[PROJECT]` learnings auto-write as a read-time veto; `[GLOBAL]` still confirms). Verify: `tests/check-structure.sh` (469/0, incl. [Phase 18]) and `tests/run-tests.sh --id S26-...,...,S30-...` (5 SOFT_PASS — now fast after the bundled `--id` harness fix).
> Requester = operator — closure notice for self-record.

## Reverting this feature

Behavioral/prose + one real behavior change (AC-6 capture gate). If it needs backing out:
- **Full rollback:** `git revert <ship-commit>` (or reset to the pre-feature commit) — restores prose-only handoff modeling + the unconditional capture gate.
- **Surgical:** the S22/S23 rows + "Session-boundary exit chain" blocks in transitions.md + 4 AGENTS.md are additive (remove them to revert the modeling); the capture-gate change is localized to `session-capture/SKILL.md` §4 (restore the unconditional `**STOP**` to revert AC-6 alone).
- **Pins:** the new check-structure.sh [Phase 18] pins are what would fail if a partial revert leaves a dangling reference — remove them together with the modeling they pin.
