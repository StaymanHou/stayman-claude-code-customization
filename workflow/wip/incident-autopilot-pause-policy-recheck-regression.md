# Incident: Autopilot Mode 3 regression — agent paused after build despite F8 being AUTO

**Workflow:** incident
**State:** mitigate (pivot 2026-05-17 — reproduction abandoned; structural prompt fix is the path forward)
**Created:** 2026-05-16
**Severity:** P1
**Status:** Active — awaiting `/session-resume` then `/incident-mitigate`
**Path:** I15 closed (reproduction abandoned). Direct to I6 (investigate → mitigate, ungated). Structural fix already selected: move pause-policy from `agents/feature-workflow/AGENTS.md` into per-skill `SKILL.md` files (option (a) of the three structural candidates listed below).

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
