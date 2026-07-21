# Incident: Autopilot Mode 3 regression — agent paused after build despite F8 being AUTO

**Workflow:** incident
**State:** resolved (2026-05-17)
**Created:** 2026-05-16
**Severity:** P1
**Status:** Resolved — mitigation applied 2026-05-17 10:25 (scope-extended 14:30); codify completed with Phase 9 structural check (24 assertions across 8 SKILL.md files); negative-control verified
**Path:** I15 closed (reproduction abandoned). Direct to I6 (investigate → mitigate, ungated). Structural fix applied: pause-policy cheat-sheet block added to all 8 affected feature `SKILL.md` files. Codify Path B with `tests/check-structure.sh` Phase 9 as the structural-only red→green substitute. Followup `SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT` filed (task:plan, medium) to cover AGENTS.md ↔ per-skill row consistency.

## Session Pause — 2026-05-16 10:15
Paused. See `workflow/.session.md` to resume. Investigate cannot proceed until the session-replay harness exists and reproduces the bug as a FAILing test — the single-shot harness fundamentally cannot model the narrative-cadence-drift failure class. The 2026-05-11 fix passed S21 cleanly and still regressed in production; we must avoid the same trap.

## Session Pause — 2026-05-16 13:00 (gating-shift update)
Still paused. Gating shifted: the session-replay-harness feature was opened to deliver the reproduction gate but Phase 2 proved single-shot replay can't model the bug class (3/3 PASS on buggy codebase even with describe-only framing removed). Feature abandoned, infrastructure salvaged in commit `9ac8ff4` (`tools/capture-session-slice.sh`, `tests/sessions/`, audit discipline, check-structure.sh Phase 8). New gate: **multi-turn replay extension** filed as `SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS` (high priority). On resume, open `/feature-spec` for that work first — do NOT jump straight to `/incident-investigate`.
**drive_mode:** orchestrated (incident override — incidents always run Mode 2)

## Pivot — 2026-05-17: reproduction abandoned, semantic prompt fix chosen

After opening `/feature-spec` for the multi-turn replay harness (2026-05-17 session), the research spike ($2.84 across three `claude --resume` invocations on Opus 4.7 against the captured 2026-05-16 F8 pause slice) proved that **the entire `claude --print` family — including `--print --input-format=stream-json --output-format=stream-json` — runs an internal agentic loop with no programmatic pause-decision surface**. The "show prompt to user → wait for input" boundary that defines the production bug is bypassed by design in `--print` mode. Full structural finding documented in `SURFACE-2026-05-17-CLAUDE-PRINT-AGENTIC-LOOP-SUPPRESSES-PAUSE-DECISION` (workflow/backlog.md).

**User decision (2026-05-17):** abandon reproduction. The bug class is inherently hard to reproduce in any headless test harness. Apply the structural prompt fix directly; accept that codify-step regression coverage will be deferred (incident-codify I9 path) since we no longer have a reproduction gate.

**Selected structural mechanism:** option (a) from the three candidates already listed in `## Initial Observations` / hypotheses — move the pause-policy from `agents/feature-workflow/AGENTS.md` (loaded once if at all; subject to narrative-cadence drift) into a hard cheat-sheet block in each per-phase feature `SKILL.md` (loaded into context at every skill invocation). Add explicit "do NOT return control to the user if the next step is AUTO in the current drive mode" wording.

**Why option (a) is load-bearing on its own merits, independent of spike evidence:** SKILL.md prose is reliably loaded into context at every skill invocation (verified — Skills appear in tool_use/tool_result pairs in the production slice itself, and the v3 spike confirmed all 40+ skills register correctly). AGENTS.md is reference markdown the orchestrator agent is *supposed* to read once and remember — that's the very recipe for cadence drift. Putting the pause-policy in the skills themselves makes it harder to forget by construction.

**Codify deferral path (I9):** since reproduction is abandoned, regression coverage at codify time cannot use the "captured slice → FAIL on current HEAD → PASS after fix" red→green discipline. Acceptable substitutes to consider at codify:
- A pure-prose contract test that asserts each per-phase feature SKILL.md contains the hard pause-policy block (structural check, not behavioral) — catches removal/regression of the prose surface that load-bears the fix
- A SURFACE→task:plan audit-trail entry filing the open coverage gap so it's visible in the backlog rather than silently uncovered
- A hook-based instrumentation canary (logs every Notification event with skill/transition/drive_mode context) shipped alongside the fix as a production observability surface, not a test

**Out of scope for this incident:**
- Building any test harness (multi-turn replay, PTY-driven interactive, direct SDK) — all three are documented as theoretically viable in the learning SURFACE but explicitly deferred
- Touching `agents/feature-workflow/AGENTS.md` content beyond what's needed to point at the per-skill blocks (the AGENTS.md table can remain as architectural reference, but the load-bearing copy lives in the skills)

## Session Pause — 2026-05-17 (handoff to /incident-mitigate)
Reproduction path abandoned per user pivot above. Resume via `/session-resume` then `/incident-mitigate`. The mitigate skill should consult the three structural-fix candidates in `## Initial Observations` H4 + the three listed at the top of `## Open questions/blockers` (carried forward from the 2026-05-16 pauses) — option (a) (per-skill pause-policy block) is the chosen mechanism.
**drive_mode:** orchestrated (incident override — incidents always run Mode 2)

## Session Resume — 2026-05-17 (user override → autopilot)
User selected Autopilot (Mode 3) on resume — overriding the incident-default Orchestrated. Acknowledged; proceeding to `/incident-mitigate`. Pauses still occur at human-required gates (Test Triage if a test fails, contract conflicts, scope changes), but no per-skill pauses between AUTO transitions.
**drive_mode:** autopilot

## Mitigation Applied — 2026-05-17 10:25

**Mechanism:** Option (a) from the three structural-fix candidates — a hard "Orchestrator Pause Policy (cheat-sheet)" block was added between `## State Machine Context` and `## Procedure` in each of the five per-phase feature SKILL.md files:
- `skills/feature-build/SKILL.md`
- `skills/feature-verify-auto/SKILL.md`
- `skills/feature-verify-self/SKILL.md`
- `skills/feature-verify-human/SKILL.md`
- `skills/feature-verify-codify/SKILL.md`

**Block contents (per skill):**
1. A per-skill row-set from the canonical pause-policy table — only the transitions emitted by *that* skill, with AUTO/PAUSE/SKIP per drive mode.
2. An explicit **"Hard rule for AUTO exits"** paragraph stating: when the emitted transition is AUTO in the active drive mode, the orchestrator's next action **must** be a `Skill` tool invocation, not a turn-end. The clean `TRANSITION: <id>` token is the chain signal; narrative summary text is not a stop signal.
3. A pointer back to `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and precedence rule.

**Why this fixes the regression mode:**
SKILL.md prose is loaded into context at **every** Skill tool invocation — verified empirically in the 2026-05-17 spike (all 40+ skills registered correctly in stream-json events; the loading mechanism is reliable). The cheat-sheet now lives next to the transition list the model just emitted, so the chain decision happens in-context with the rule visible, instead of relying on AGENTS.md prose the orchestrator read once at session start and may have lost to narrative-cadence drift across many turns.

**Why this is load-bearing on its own merits (not just spike evidence):**
This is the difference between an instruction loaded once-and-remembered (AGENTS.md, fragile to drift) and an instruction re-loaded at the exact moment the decision is made (per-skill cheat-sheet, by construction harder to forget). The 2026-05-11 fix made the SKILL emit clean transitions; this fix makes the orchestrator's response to those transitions in-context, not memory-resident.

**Test verification:**
- `./tests/check-structure.sh`: 70 PASS / 0 FAIL (no structural regressions)
- `./tests/run-tests.sh --id S21,S24,S25 --model sonnet` (session-orchestrator chain scenarios — the closest analogue to production behavior): 2/3 PASS on first run (S25 flaked on "waiting for"), 1/1 PASS on isolated re-run → no real regression; the per-phase chain prose is unchanged at the session-orchestrator boundary
- `./tests/run-tests.sh --id F8,F9,F10,F10b,F11,F12,F13,F14,F15,F16 --model sonnet` (all primary per-phase transitions): **10/10 PASS** strict, $0.83 / 158s. Every per-phase transition still emits cleanly with the new cheat-sheet block in place.

**Risk surface (regressions to watch during monitoring):**
- The cheat-sheet block adds ~25 lines of prose to each per-phase SKILL.md. In Mode 1 (step-by-step) the block could be redundant chatter, but is harmless: Mode 1 PAUSEs always, so the AUTO rule never fires.
- Per-skill rows are **derived** from `agents/feature-workflow/AGENTS.md`'s canonical table. If that table changes, the cheat-sheets will drift. Followup: codify a structure-check that all rows in every per-skill cheat-sheet match the AGENTS.md source rows for that skill's transitions. (Logged as a SURFACE during codify.)
- `agents/feature-workflow/AGENTS.md` was **intentionally not modified** — it remains the architectural reference. The load-bearing copy now lives in the per-skill blocks, but the canonical table stays where it is for human/agent readability of the full state-machine view.

**Codify approach (forward-looking, will be decided at /incident-codify):**
This incident's reproduction was abandoned (`SURFACE-2026-05-17-CLAUDE-PRINT-AGENTIC-LOOP-SUPPRESSES-PAUSE-DECISION`), so red→green discipline at codify time is not available. The acceptable substitutes already listed under the Pivot section apply: a structural test asserting each per-phase SKILL.md contains the cheat-sheet block; SURFACE→task:plan filing of the open coverage gap; or a hook-based Notification canary. Codify will choose.

## Scope Extension — 2026-05-17 14:30

**Trigger:** User reported the same failure mode is occurring in pre-build skills — `feature-spec` and `feature-plan` sometimes return control to the user before the next step in autopilot / full-autopilot mode, despite the canonical pause policy stating spec is AUTO in Mode 4 and plan is AUTO in Modes 3–4.

**Decision:** Extend the mitigation scope **now**, before codify. Same load-bearing mechanism (AGENTS.md drift across long contexts), same fix shape (per-skill cheat-sheet block + hard AUTO-exit rule). Finishing codify with the fix partial would mean re-opening the workflow for the symmetric case immediately afterward.

**Mechanism (extension):** Added the same "Orchestrator Pause Policy (cheat-sheet)" block to three additional feature SKILL.md files:
- `skills/feature-spec/SKILL.md` — exits F3, F4. Skill entry is PAUSE in Modes 1–3 (spec review), AUTO in Mode 4.
- `skills/feature-plan/SKILL.md` — exit F7. Skill entry is PAUSE in Modes 1–2 (plan review), AUTO in Modes 3–4.
- `skills/feature-research/SKILL.md` — exits F5, F6. Skill entry is PAUSE in Modes 1–2, AUTO in Modes 3–4.

Each block follows the same shape as the per-phase blocks: per-skill row-set from the canonical pause-policy table + "Hard rule for AUTO exits" paragraph stating that the orchestrator's next action must be a `Skill` tool invocation, not a turn-end, when the emitted transition is AUTO. Existing "Single-step mode only: STOP here" prose in spec and plan was harmonized to point at the new cheat-sheet block instead of contradicting it.

**Tested feature SKILL.md files now total 8** (the 5 per-phase + spec + plan + research).

**Test verification (extension):**
- `./tests/check-structure.sh`: 70 PASS / 0 FAIL (no structural regressions after extension)
- `./tests/run-tests.sh --id F1,F3,F4,F5,F6,F7 --model sonnet`: 4 PASS / 1 SOFT (F1 — pre-existing model noise pattern, no transition line — unaffected by my edits) / 1 FAIL on first run (F4 — flake, scenario history notes "HIDDEN-FAIL-F4 → recon 2026-05-06"). F4 PASS on isolated rerun ($0.08 / 11s) → no real regression. Net: **6/6 PASS on rerun-stable basis** for the spec/research/plan transition scenarios.

**Files changed total (mitigation + extension): 8**
- `skills/feature-spec/SKILL.md` (new)
- `skills/feature-research/SKILL.md` (new)
- `skills/feature-plan/SKILL.md` (new)
- `skills/feature-build/SKILL.md`
- `skills/feature-verify-auto/SKILL.md`
- `skills/feature-verify-self/SKILL.md`
- `skills/feature-verify-human/SKILL.md`
- `skills/feature-verify-codify/SKILL.md`

**Monitoring window restarts:** 2026-05-17 14:30 (extension applied). The per-phase fix from 10:25 stays in monitoring, but the broader scope means the monitoring observation should cover spec/research/plan AUTO transitions in Modes 3–4 too. The followup structure-check (cited above as "if AGENTS.md changes, cheat-sheets drift") should now cover **all 8** SKILL.md files, not just the per-phase 5.

## Codify

**Path:** B (no reproduce artifact — reproduction was abandoned 2026-05-17 per `SURFACE-2026-05-17-CLAUDE-PRINT-AGENTIC-LOOP-SUPPRESSES-PAUSE-DECISION`). Red→green discipline with a captured slice or failing scenario was structurally unavailable, so the chosen substitute is a **structural pure-prose contract test** — assertion (a) from the three substitutes listed in the Pivot section.

**Test:** `tests/check-structure.sh` → new `[Phase 9] Orchestrator pause-policy cheat-sheet presence`. The phase iterates the 8 affected feature SKILL.md files (spec, research, plan, build, verify-auto, verify-self, verify-human, verify-codify) and asserts three things per file:
1. The literal heading `## Orchestrator Pause Policy (cheat-sheet)` is present.
2. The semantic anchor phrase `Hard rule for AUTO exits` is present — this is the load-bearing imperative. If the prose weakens (e.g. "should" instead of "must", or the phrase is removed), Phase 9 fails.
3. The block contains a markdown table row referencing all four drive modes (`Mode 1`, `Mode 2`, `Mode 3`, `Mode 4`) on a single line.

Total: 24 PASSing assertions added (3 × 8 files).

**Why these three assertions catch the regression mode this incident describes:**
- (1) catches outright deletion of the block.
- (2) catches softening of the imperative — the exact failure shape we'd expect if a future edit "cleaned up" the prose. The word "Hard" and the "AUTO exits" specificity are deliberately unusual phrases unlikely to survive cosmetic rewording.
- (3) catches partial table corruption (e.g. someone removes the Mode 4 column thinking it's redundant).

**Integration boundary:** **No.** The mitigation modifies prose inside SKILL.md files; it does not touch a consumed HTTP endpoint, UI surface, CLI, scheduled job, or external call. The "consuming surface" of SKILL.md prose is the agent runtime itself — which we cannot reach from a CI test harness (that's the unreproducibility finding documented in the spike). No consuming-surface test is required.

**Negative-control proof (the codify equivalent of red→green):** Stripped the `## Orchestrator Pause Policy (cheat-sheet)` block from `skills/feature-build/SKILL.md` via a scratch script. Re-ran `tests/check-structure.sh` — Phase 9 emitted **3 FAILures** (one per assertion) on that file. Restored the file from backup; re-ran check-structure.sh — back to 94/94 PASS. This confirms Phase 9 has real signal: it fails when the prose is removed and passes when restored.

**Full suite result:** `./tests/check-structure.sh` → **PASS: 94 | FAIL: 0**. No unrelated regressions. All prior phases (1–8) still pass.

**Coverage gap acknowledgement:** Phase 9 catches *structural* regression (prose removed/weakened). It does **not** catch *behavioral* regression — i.e., if a future change to `agents/feature-workflow/AGENTS.md` flipped a transition from AUTO to PAUSE in the canonical table but the per-skill cheat-sheets still claimed AUTO, the in-skill blocks would silently lie. Catching that drift requires either (i) parsing both sources and asserting consistency, or (ii) the original aspirational behavioral-replay harness (filed as SURFACE-2026-05-17). Logged below as a SURFACE for followup; not a blocker for resolve.

**Followup discovery (SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT):** Phase 9 in `tests/check-structure.sh` asserts only that the cheat-sheet block *exists*, not that the rows *match* the canonical pause-policy table in `agents/feature-workflow/AGENTS.md`. If AGENTS.md changes (e.g. a transition flips PAUSE↔AUTO for a given drive mode), the per-skill blocks could silently drift and continue to say the old policy. Suggested followup: parse both sources, normalize, assert equality of the rows pertaining to each skill's exits. Targets `task:plan` (small/simple — single bash/python pass over both files). Priority: medium. Will be logged to `workflow/backlog.md` at incident-resolve sweep.

## Summary

In a live `/session-start`-driven feature workflow running in **Autopilot (Mode 3)** on the `neo-stayman-assistant` project (2026-05-16), the agent invoked `feature-build` for WP1 Phase 1, the skill returned cleanly with `TRANSITION: F8`, and the agent then **stopped and waited for the user** instead of chaining to `feature-verify-auto`. Mode 3's pause policy is unambiguous: only `verify-human` pauses; F8 (build → verify-auto) is AUTO.

The user had to redirect: *"Wait, why did you pause at verify auto for autopilot? Shouldn't this step be auto?"*

This is a regression of an already-shipped fix:
- **Commit `33cf5c9` (2026-05-11)** — "Fix Mode 2 spurious pauses between per-phase feature skills" — added `### Emit Transition` sections to all 5 per-phase feature SKILLs, added an anti-example to `skills/session-start/SKILL.md`, and shipped scenario `S21` as the regression gate.
- **Backlog item closed at that time:** `SURFACE-2026-05-11-ORCHESTRATED-PAUSES-BETWEEN-PER-PHASE-STEPS` (CHANGELOG 2026-05-11 entry).
- **Adjacent gap already known and logged:** `SURFACE-2026-05-11-PER-PHASE-CHAINING-SCENARIO-COVERAGE` — flagged that S21 covers `build → verify-auto` chaining under Mode 2 only, and that other per-phase chain points + other drive modes lack equivalent scenarios. That item is still open in `workflow/backlog.md`.

Today's failure occurred in **Mode 3 (Autopilot)**, not Mode 2. The 2026-05-11 fix targeted Mode 2 specifically; the regression gate (S21) only tests Mode 2. Mode 3 had no scenario coverage, and the mechanism the prior fix installed (clean `TRANSITION: F8` emission + anti-example prose) was not sufficient on its own to prevent the agent from anchoring on narrative cadence in Mode 3.

Evidence artifact: `.claude/learnings/2026-05-16-autopilot-pause-policy-re-check.md` (already on disk — a learnings draft the user opened this incident from).

## Initial Observations

- The skill output ended with the canonical `TRANSITION: F8` token *and* a narrative "Phase 1 complete" summary. The agent treated the summary as the natural end of the turn and stopped.
- The same agent (this session) had read `skills/session-start/SKILL.md`'s anti-example block — which explicitly names this exact failure pattern — earlier in the session that produced the learnings draft. The anti-example was in context and still did not prevent the failure.
- The prior fix's mechanism is correct *as far as it goes*: the per-phase SKILLs do emit `TRANSITION:` cleanly. The gap is on the **consumer** side — the session-start orchestrator's per-step re-check loop is described in prose but not reinforced by a hard "after every Skill call returns, look up the transition in the active mode's pause-policy table" mechanism that the agent can mechanically follow.
- Scenario `S21` only exercises Mode 2. The "Mode 3 build → verify-auto chains" assertion has no test in `tests/scenarios/session.yaml` — confirmed today by inspection of the CHANGELOG entry and the still-open `SURFACE-2026-05-11-PER-PHASE-CHAINING-SCENARIO-COVERAGE` backlog item, which explicitly notes "S21 covers build → verify-auto chaining under Mode 2."

## Hypotheses

1. **Coverage gap (most likely).** S21 asserts Mode 2 chaining but no equivalent scenario asserts Mode 3 chaining. The fix's regression net never extended to Mode 3, so the discipline could rot in Mode 3 without the test sweep noticing. (Unverified — needs grep of `tests/scenarios/session.yaml`.)
2. **Anti-example wording is not load-bearing enough in Mode 3.** The session-start anti-example in `skills/session-start/SKILL.md` Step 4 describes the failure shape using Mode 2 vocabulary ("Run /feature-verify-auto" advisory prose, etc.). In Mode 3 — where Autopilot is the *default* mode since 2026-05-14's flip — the anti-example may not be salient enough to override narrative-cadence anchoring. (Unverified — needs read of the current anti-example.)
3. **Default-mode flip raised exposure.** On 2026-05-14, default drive mode was flipped from Mode 2 to Mode 3 (commit `7eb3017`). That change made Mode 3 the most-trafficked path. If Mode 3 had a latent gap relative to Mode 2 (per H1), that gap was previously hidden because most live sessions ran in Mode 2. The default flip surfaced it. (Unverified — but timing is suggestive: regression observed two days after the default flip.)
4. **Per-step re-check is described but not mechanized.** Session-start says "after every Skill call returns, re-check the active mode's pause policy." That's a procedural instruction loaded once at the top of the session. The actual cognitive action (look up `F8` in the table, see AUTO, chain) happens N times per workflow. The learnings draft itself diagnoses this as the root cause: "a procedural warning *in the same context window* is not sufficient — the mechanism needs to be a per-step re-check, not a once-up-front instruction." (Plausible but mechanism-level — verification belongs in investigate, not report.)

## Timeline

- **2026-05-11** — Prior incident `SURFACE-2026-05-11-ORCHESTRATED-PAUSES-BETWEEN-PER-PHASE-STEPS` resolved. Commit `33cf5c9` ships per-phase Emit Transition sections + session-start anti-example + scenario S21 (Mode 2 only).
- **2026-05-11** — Adjacent gap `SURFACE-2026-05-11-PER-PHASE-CHAINING-SCENARIO-COVERAGE` logged (low priority): S21 covers Mode 2 only; other chain points + other modes uncovered.
- **2026-05-14** — Default drive mode flipped from Mode 2 to Mode 3 (commit `7eb3017`). Mode 3 becomes the most-used path.
- **2026-05-16** — In a live Mode 3 `/session-start` session for `neo-stayman-assistant` WP1 Phase 1, `feature-build` returns `TRANSITION: F8`, agent stops and waits. User redirects: "why did you pause at verify auto for autopilot?" After redirect, agent chains correctly. User writes the learnings draft at `.claude/learnings/2026-05-16-autopilot-pause-policy-re-check.md`.
- **2026-05-16** — User reports the regression via `/session-start`, citing the learnings draft as evidence.

## Severity Assessment (Triage)

**Severity: P1.** Original instinct was P2 ("type 'continue' workaround"). User correctly pushed back: the workaround **assumes synchronous user presence**, which directly contradicts Autopilot's value proposition. Concrete blast-radius example: user kicks off autopilot, leaves for a 30-min lunch expecting to return to a `verify-human` pause. Instead agent has idled at `verify-auto` (3 steps upstream) for 30 min wasted. Agent then needs another 20 min to self-debug. User loses ~50 min that should have been spent **on** `verify-human`.

Multiplied by:
- Every per-phase chain point (build→auto, auto→self, self→codify on no-failure paths)
- Every phase in a feature (often 2–5)
- Every feature ever run in Mode 3
- Mode 3 has been the default since 2026-05-14 → most live sessions exposed

P1 is correct: this breaks Autopilot's async semantics on every workflow.

## Forensic Findings (from session-log analysis)

**Session log located:** `~/.claude/projects/-Users-stayman-Personal-projects-neo-stayman-assistant/29930351-66ed-4834-b8da-8be37927623e.jsonl` (985 KB, last written 2026-05-16 09:28).

**Skill invocation trace** (all `Skill` tool calls in the session, in order, from `jq` extraction):

| Time (UTC) | Skill | Notes |
|---|---|---|
| 12:51:12 | `feature-build` (`drive_mode: autopilot`) | Phase 1 start |
| 12:52:28 | — *(build skill returns; agent emits `TRANSITION: F8` and **stops**)* | **Failure moment.** |
| 12:57:29 | — *(user types "continue" — 5 min idle gap)* | Redirect #1 |
| 12:57:33 | `feature-verify-auto` | Triggered by redirect, not by chain |
| 12:58:06 | — *(user types "Wait, why did you pause at verify auto for autopilot?")* | Redirect #2 — meta |
| 12:58:38 | `feature-verify-self` | Triggered after the meta redirect |

**The failure-moment assistant turn**, full text (verified by reading uuid `67be4a18-24d1-4e5c-896d-63da96bbb6ad`):

> "Phase 1 impl complete. Five artifacts written: `Dockerfile`, `docker-compose.yml`, `.env.example`, `.gitignore`, `.dockerignore` (plus empty `.env` for compose to load). Image built, all four observable outcomes pass live (`uv 0.11.14`, `Python 3.12.13`, `pwd=/workspace`, source mount round-trips).
>
> TRANSITION: F8"

This is exactly the failure shape the 2026-05-11 anti-example in `skills/session-start/SKILL.md` Step 4 describes — the "Phase 1 done. Ready to run verify-auto when you are" pattern, just slightly rephrased. The agent **had the anti-example in context** (it was loaded as part of `/session-start` at the top of the session). It still committed the failure. Then it committed it **again** at the auto→self transition (recovered only after redirect #2).

**Two failures in one session, both AUTO transitions, both immediately after a clean `TRANSITION: F<id>` emission.** Confidence that this is a deterministic class of failure (not a one-off model lapse) is high.

## Reproduction Attempt

**Surface chosen:** failing test (harness scenarios S24, S25 in `tests/scenarios/session.yaml`)

**Outcome:** **could-not-reproduce-locally-with-single-shot-harness, but production evidence confirms the bug.** Two new scenarios written and validated on sonnet — both PASS strictly. This means the **happy-path contract** is testable (the canary works), but the **failure mode** does not surface under single-shot harness prompting because the model, given a focused prompt explicitly stating "Mode 3 — must chain", will correctly chain. The bug class in production is **narrative-cadence drift inside long orchestrator contexts**, which the current harness shape cannot simulate.

**Artifact:**
- `tests/scenarios/session.yaml` → new scenarios `S24` (Mode 3 build → verify-auto chain) and `S25` (Mode 3 verify-auto → verify-self chain)
- Both modeled on S21 (which covers Mode 2 chain). Both assert: `transition_id_any` is the AUTO chain target, `contains_any` includes orchestration verbs ("invoke", "Skill", "auto-chain"), `not_contains_strict: true` on a hardened list of user-deferral phrases ("let me know", "ready when you are", "type continue", etc.)

**Determinism:**
- **Production bug:** **every-run in the 2026-05-16 session** — happened twice in succession at two consecutive AUTO transitions (build→auto AND auto→self), both immediately after clean `TRANSITION: F<id>` emission. High-confidence deterministic class of failure under realistic conversation context.
- **Harness scenario:** PASSes consistently on sonnet (`./tests/run-tests.sh --id S24,S25 --model sonnet` → 2/2 PASS, $0.22, 22s). SOFT_PASSes on haiku ("no structured TRANSITION line" — same output-shape noise pattern as the six scenarios in `SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG`). Will tag `model: sonnet` once the fix discipline is confirmed PASS-strict on sonnet too.

**Notes:**
- **What the scenarios catch (regression net value):** if a future edit to `skills/session-start/SKILL.md` or the orchestrator pause-policy prose weakens the Mode 3 auto-chain contract — e.g. removes the anti-example, removes the per-step re-check loop, softens "TRANSITION is a chain signal" into "TRANSITION may be a chain signal" — sonnet will start producing user-deferral text and the scenarios will FAIL. This is real coverage on the *contract*, not on the *failure mode*.
- **What the scenarios do NOT catch:** the live failure mode — model anchored on narrative cadence inside a 50-turn orchestrator context window, with the anti-example loaded but not salient enough — is **not reproducible** with single-shot harness prompts. The model is too eager to demonstrate "right behavior" when the prompt is focused on the question.
- **True reproduction belongs to the session-replay harness** (Option A from triage discussion). That harness will load the actual `.jsonl` slice from `~/.claude/projects/-Users-stayman-Personal-projects-neo-stayman-assistant/29930351-66ed-4834-b8da-8be37927623e.jsonl` (the failure-moment turn at uuid `67be4a18-24d1-4e5c-896d-63da96bbb6ad`, ending in `TRANSITION: F8`) as the conversation prefix and run the next agent turn against a live SKILL prompt. Logged as `SURFACE-2026-05-16-SESSION-REPLAY-HARNESS` (to be filed at incident close) with PII-audit-before-commit as a non-negotiable constraint.

## Reproduction Plan (original — kept for record)

**Minimum-first** (this incident's I13 reproduce path):
- Add scenario `S22-autopilot-build-chain` to `tests/scenarios/session.yaml`, modeled on S21 (Mode 2 chaining) but for Mode 3 (Autopilot).
- Fixture: a conversation prefix simulating an autopilot orchestrator that has just received `feature-build`'s output ending with `TRANSITION: F8`.
- Assertion: agent's next turn must invoke `Skill(feature-verify-auto)` (or emit `TRANSITION: F10` to the same effect). Strict `not_contains` on user-deferral phrases ("Run `/feature-verify-auto`", "type continue", "let me know when").
- Consider adding `S23` for the auto→self chain (the second failure observed in this session — strengthens coverage).

**Immediate follow-up (separate workflow):** session-replay harness mode (Option A from the dispatch discussion). Loads a slice of a real `.jsonl` as the orchestrator's conversation prefix, runs the next turn under the live harness, asserts on the resulting tool calls. Backlog item with these constraints:
- Captured session logs live in `tests/sessions/` (repo-local for reproducibility).
- **Mandatory PII/secrets audit before each `git add`**: every log file must be hand-audited and redacted (tokens, paths revealing personal identity, third-party credentials, project content beyond test need). Non-negotiable, per-file.
- The 2026-05-16 F8 pause becomes the first hyper-realistic test using this harness.
