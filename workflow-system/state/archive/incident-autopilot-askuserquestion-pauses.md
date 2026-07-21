# Incident: Autopilot transition checkpoints intermittently pause with AskUserQuestion after Opus 4.8 upgrade

**Workflow:** incident
**State:** codify
**Created:** 2026-06-23 11:46
**Severity:** P1 — major feature (autopilot unattended chaining) effectively broken
**Status:** Resolved

## Summary
Since upgrading the Claude Code client and switching to Opus 4.8, transition points / checkpoints that would typically auto-chain in autopilot mode started getting intermittent pauses where the agent invokes the `AskUserQuestion` tool. Previously these AUTO transitions chained without stopping; now they intermittently halt for user input.

## Initial Observations
- The behavior is **intermittent** ("from time to time"), not deterministic — points to model-judgment drift rather than a hard config/code change.
- The regression correlates with two simultaneous changes: (1) Claude Code client upgrade, (2) model switch to Opus 4.8. Either or both could be causal — confound not yet separated.
- The pause mechanism is specifically `AskUserQuestion` tool invocation, which is a *newer* harness tool. Prior pause policy was written around the invariant "verify-human is the ONLY autopilot pause" — the canonical pause-policy table lives in `agents/feature-workflow/AGENTS.md` with per-skill cheat-sheet blocks in each feature SKILL.md (`Hard rule for AUTO exits`).
- The orchestration procedure (`/session-start`) instructs the model to pause "only at human-input points defined by the procedure." A more capable / more cautious model may be reading ambiguity at AUTO exits and reaching for `AskUserQuestion` where the prose intended silent chaining.

## Hypotheses
- **H1 (prompt-vs-model drift):** Opus 4.8 interprets the AUTO-exit cheat-sheet language more conservatively and elects to confirm via `AskUserQuestion` at transition points the prose meant to be silent. The "Hard rule for AUTO exits" wording may not be strong enough to suppress a tool the model now reaches for by default. (unverified)
- **H2 (new-tool availability):** `AskUserQuestion` is a deferred/available tool the model now favors for any decision-shaped moment; the pause-policy prose predates this tool and never explicitly forbids it, so AUTO exits have no instruction naming it. (unverified)
- **H3 (client-behavior change):** The client upgrade changed how/when `AskUserQuestion` is surfaced or how orchestration prose is delivered (e.g., context-window summarization dropping the pause-policy cheat-sheet), independent of the model. (unverified)
- **H4 (confound — model alone):** Reverting to the prior model would restore behavior, isolating Opus 4.8 as the cause vs. the client. (unverified)

## Impact Assessment (triage)
- **Severity:** P1. Autopilot's value proposition is unattended end-to-end chaining; intermittent `AskUserQuestion` pauses defeat it and force the operator to babysit, so a major feature is effectively broken.
- **Affected:** all autopilot/`/session-start`-driven runs in this repo since the client+model upgrade.
- **Workaround:** answer the prompt to let it continue — friction, not a hard block. (Why not P2: the broken capability *is* unattended operation, so a manual-answer workaround doesn't restore the feature.)
- **Not a duplicate** of a known incident.
- **Reproducibility decision (I13):** operator believes a deterministic trigger exists. Test harness can exercise this deterministically — a scenario can assert an AUTO transition emits `TRANSITION: <id>` without an `AskUserQuestion` invocation. Reproduce first; that failing scenario becomes the regression gate for the mitigation.

## Reproduction Attempt
**Surface chosen:** manual recipe (static-analysis of the instruction surface) — fastest faithful reproducer; a harness scenario is deferred to codify as the regression gate.
**Outcome:** reproduced — the causal gap is confirmed by inspection of the canonical pause-policy artifacts.
**Determinism:** once-observed in the field as intermittent (model-judgment), but the *root gap* is deterministic and present on every read of the policy prose.

**Artifact / recipe:**
1. `grep -rln "AskUserQuestion" .` over the whole repo → the ONLY hits are a test fixture (`tests/sessions/2026-05-16-autopilot-f8-pause.jsonl`) and this incident WIP. **No skill, agent, or snippet instruction names `AskUserQuestion` at all.**
2. Read the canonical pause table — `agents/feature-workflow/AGENTS.md` "Pause policy by drive mode" (lines ~161–193). It is rich and explicit about *which* transitions are AUTO vs PAUSE per drive mode, and it states the invariant "verify-human is the ONLY autopilot pause."
3. Read the per-skill cheat-sheet "Hard rule for AUTO exits" (e.g. `skills/feature-build/SKILL.md:40`). It says: on an AUTO transition the orchestrator **must immediately invoke the next skill via the `Skill` tool** and **must NOT return control to the user**; it explicitly names the *narrative-summary* regression mode (P1, 2026-05-16) as the thing it prevents.
4. **The gap:** the Hard rule was written against ONE failure mode — emitting `TRANSITION` then a polite summary turn-end (a passive stop). It does **not** name the *active* stop mode: invoking `AskUserQuestion` (a tool that did not exist / was not in play when the rule was authored). A newer client + Opus 4.8 reaches for `AskUserQuestion` at decision-shaped AUTO moments; the prose forbids "return control to the user" but a model can rationalize that an `AskUserQuestion` mid-turn is "just confirming," not "returning control" — so the existing wording does not deterministically suppress it.

**Expected:** at any AUTO transition (e.g. F8, F38, back-loops) in autopilot/full-autopilot, the orchestrator emits `TRANSITION: <id>` and immediately calls the next `Skill` — zero `AskUserQuestion` invocations.
**Observed (field):** intermittent `AskUserQuestion` invocations at AUTO transition points, halting the chain for operator input.

**Notes for investigate/mitigate:**
- Mitigation is almost certainly a prose hardening: extend the "Hard rule for AUTO exits" (per-skill blocks + canonical AGENTS.md table) to *explicitly forbid* `AskUserQuestion` (and any user-input tool) on AUTO transitions, naming the tool the way the 2026-05-16 fix named the narrative-summary mode.
- This is the SAME phenomenon as the auto-branching sibling issue (already fixed, commit 73e97e2): a newer client/model acting on latitude the prompts never explicitly closed.
- **Regression gate for codify (deferred test):** a scenario asserting an AUTO transition (candidate: F8 in autopilot) emits the right `transition_id` AND does not invoke `AskUserQuestion`. Harness vocabulary fit: `not_contains` / `not_contains_strict` is the natural assertion — but note `not_contains_strict` is "structurally fragile when the failing skill is not the skill under test" (docs/lessons/test-scenario-strict-mode.md); since `AskUserQuestion` is a *failure-proxy* phrase here (appears only when the bug fires), strict mode is appropriate. Confirm at codify.

## Codify — 2026-06-23 12:36

**Path:** B (new coverage from scratch). The reproduce artifact was a manual recipe + live probe, not a CI test — cannot serve as a CI regression gate, so coverage is written fresh.

**Test level decision — structural pin is the PRIMARY gate (not a behavioral scenario).** The defect is a *prompt-level prohibition*. The harness only inspects final `.result` text and does NOT disallow `AskUserQuestion`, so a behavioral scenario cannot reliably observe a real interactive pause (per docs/lessons/harness-bootstrap-skip.md + test-scenario-strict-mode.md). The robust, deterministic regression risk is "someone removes the clause from a Hard-rule block." That is caught structurally.

**Coverage written:**
1. **PRIMARY — `tests/check-structure.sh` Phase 9:**
   - (4) per-skill: every "Hard rule for AUTO exits" block in the 9 `PAUSE_POLICY_FILES` must contain `AskUserQuestion`. 9 new PASS.
   - (3b) orchestrators: all 4 `agents/*-workflow/AGENTS.md` must carry the AUTO-exit AskUserQuestion rule. 4 new PASS.
   - Result: **281 PASS / 1 FAIL** (the 1 FAIL is the pre-existing unrelated live-`settings.json` claudesk-hook drift — confirmed not touched by this incident).
2. **SECONDARY — behavioral scenario** `F8-autopilot-no-askuser` in `tests/scenarios/feature.yaml`: autopilot F8 handoff, `not_contains_strict: ["AskUserQuestion"]` (failure-proxy phrase — strict mode appropriate). Dedicated fixture `tests/fixtures/wip/feature-build-phase1-done-autopilot.md` (routing-fork lesson: variant routing needs a dedicated fixture; reused `feature-autopilot-active.md` pointed at Phase 2, which would muddy the assertion). Run result: **SOFT_PASS** — matched `verify-auto`, no `AskUserQuestion` (the negative assertion held); soft because the model didn't emit a structured `TRANSITION:` line on that run. Acceptable: the scenario's purpose is the negative assertion, which passed. Honest limitation documented inline in the YAML comment.

**Integration boundary:** the mitigation edited instruction prose in SKILL.md/AGENTS.md (the orchestrator's "consuming surface" is the model reading them). The structural pins ARE the consuming-surface coverage — they assert the prose the orchestrator reads still carries the rule. No code endpoint/CLI/UI boundary applies.

**Full suite result:** structural — 281 PASS / 1 unrelated baseline FAIL. Behavioral — F8 PASS (control), F8-autopilot-no-askuser SOFT_PASS. No regressions introduced. → I18 to resolve.

## Mitigation — 2026-06-23 12:20

**Fix:** explicit prohibition of `AskUserQuestion` (and any user-input/confirmation tool) on AUTO transitions, applied uniformly across both tiers.

**Tier-1 (11 per-skill "Hard rule for AUTO exits" cheat-sheets):** appended a clause after the shared anchor sentence ("…your next action is a `Skill` invocation, not a turn-end.") stating that invoking `AskUserQuestion` on an AUTO transition IS "returning control to the user" — the same regression class as the narrative-summary stop the 2026-05-16 fix named. Files: `skills/{feature-build,feature-plan,feature-spec,feature-research,feature-verify-auto,feature-verify-self,feature-verify-human,feature-verify-codify,feature-reproduce,feature-review-quality,task-verify}/SKILL.md`.
  - **Not touched:** `agents/code-quality-reviewer/AGENTS.md` — its "Hard rule" mentions are a *reviewer checklist describing* the rule, not an instance of it. Correctly excluded.

**Tier-2 (canonical pause-policy section):** added a dedicated paragraph "AUTO transitions may not invoke any user-input tool" to the Precedence rule in `agents/feature-workflow/AGENTS.md` (single source). Cross-referenced from `agents/{task,product,incident}-workflow/AGENTS.md` (one line each, pointing at the canonical statement — DRY, no full duplication).

**Scope-symmetry check (docs/lessons/scope-symmetry.md):** re-grepped after editing — 11/11 Tier-1 carry the clause exactly once; 4/4 orchestrators carry the rule. Uniform.

**No snippet/install.sh change needed:** edits are to SKILL.md + AGENTS.md, already symlinked into `~/.claude/` — a fresh process reads them immediately (verified symlink + clause present in `~/.claude/skills/feature-build/SKILL.md`).

**Verification (post-fix probe — same fixture/conditions as Live Reproduction):** PASS. 4/4 runs invoked `AskUserQuestion` **0** times (string absent entirely) and emitted a clean AUTO transition each (F8 ×3, F10 ×1 — both valid AUTO handoffs, no pause). Clean red→green vs. pre-fix 2-of-3 invocation rate. check-structure.sh: 268 PASS / 1 FAIL (the 1 FAIL is a pre-existing, unrelated live-`settings.json` claudesk-hook drift — not touched by this mitigation).

**Status:** Monitoring (fix applied + verified). Monitoring start: 2026-06-23 12:23.

**Regression coverage:** deferred to codify (I17) — a harness scenario asserting an AUTO transition emits its `transition_id` AND `not_contains_strict: ["AskUserQuestion"]`.

## Live Reproduction — 2026-06-23 12:14 (operator requested real red-before-green)

**Surface:** `claude --print` harness against Opus 4.8, `feature-build` on an autopilot WIP with build work done (natural next action = AUTO `TRANSITION: F8`). `--permission-mode dontAsk` + `--disallowed-tools Edit,Write` (so an `AskUserQuestion` *attempt* gets denied and is narrated in `.result` — the observable that makes the otherwise-interactive pause visible in `--print`).

**Result across corrected runs (the first 3x batch used a wrong jq path and counted nothing — discarded):**
- Single clean run: emitted `TRANSITION: F8`, explicitly "AUTO transition — hand off directly", **0** AskUserQuestion. (correct behavior)
- Batch of 3 (probe-b-1..3): **2 of 3 runs actually invoked `AskUserQuestion`** (denied by dontAsk, model narrated: *"I tried to ask you how to route this … via `AskUserQuestion` — denied (don't-ask mode)"*); **1 of 3** did not. → intermittency reproduced (~2/3 in this setup).

**Verdict: REPRODUCED LIVE.** Genuine tool *invocation* (not prose mention) confirmed in probe-b-1.json:3 and probe-b-2.json:14. The `dontAsk` block is what surfaces it here; in a real interactive session there is no block, so the attempt succeeds and the operator gets the pause.

**Honest caveat:** in these runs the fixture also left routing slightly ambiguous (no-code "pass-through vs back-loop"), which contributed to the model reaching for the tool — so this is not a *pure* AUTO-F8-handoff pause. But it still demonstrates the core defect: at a decision-shaped moment under autopilot, the model reaches for `AskUserQuestion` and nothing in the AUTO-exit rule forbids it. Strengthens (does not change) the static-analysis root cause below.

**Determinism update:** flaky — ~2 of 3 in the probe setup. Confirms field "from time to time."

## Investigation — 2026-06-23 11:50

### Observed Facts
- **F1.** `AskUserQuestion` appears in NO instruction artifact. Repo-wide grep hits only `tests/sessions/2026-05-16-autopilot-f8-pause.jsonl` (a fixture) and this WIP. No skill/agent/snippet forbids or even mentions it. (evidence: §Reproduction Attempt step 1)
- **F2.** The AUTO-exit rule exists in TWO structural tiers, both of which only contemplate the *passive* turn-end failure mode:
  - **Tier 1 — per-skill cheat-sheets** ("Hard rule for AUTO exits"): 11 SKILL.md files + `agents/code-quality-reviewer/AGENTS.md`. Wording (e.g. `skills/feature-build/SKILL.md:40`): "must immediately invoke the next skill via the `Skill` tool … must NOT return control to the user. Emitting a clean `TRANSITION` followed by a polite narrative summary … is the regression mode this block exists to prevent (P1 incident, 2026-05-16)." → It names ONLY the narrative-summary mode.
  - **Tier 2 — canonical pause tables** in all four orchestrators (`agents/{feature,task,product,incident}-workflow/AGENTS.md`). These enumerate AUTO-vs-PAUSE per transition but say nothing about *which tools* an AUTO exit may use.
- **F3.** `agents/feature-workflow/AGENTS.md` "Precedence rule": "After every `Skill` tool call returns, immediately re-check the active mode's pause policy before deciding whether to chain or wait." — Defines chain-vs-wait but does not enumerate `AskUserQuestion` as a wait-equivalent action that is forbidden on AUTO.
- **F4.** Incidents always run Mode 2 (`agents/incident-workflow/AGENTS.md:84`) — so this incident's own workflow is unaffected; the bug bites feature/task autopilot (Modes 3-4) and `/session-start` orchestration.
- **F5.** The auto-branching sibling issue (commit 73e97e2) had the identical shape: a newer client/Opus-4.8 acting on latitude the prose never explicitly closed. Two data points → this is a *class* of regression, not a one-off.

### Hypotheses
- **H1 (prompt-vs-model drift)** — Status: **CONFIRMED.** The Hard rule forbids "returning control to the user" but a model can frame an inline `AskUserQuestion` as "confirming, not returning control." The 2026-05-16 fix closed the passive stop; the active stop (`AskUserQuestion`) was never named because the tool wasn't a factor then.
- **H2 (new-tool availability)** — Status: **CONFIRMED (mechanism).** `AskUserQuestion` is now a readily-reached tool; no AUTO-exit instruction names it, so there is no instruction to suppress it.
- **H3 (client-behavior / context-drop)** — Status: **rejected as primary.** No evidence the cheat-sheets are being dropped from context; they are inline in each SKILL.md and read at every Skill invocation by design. The gap is content, not delivery.
- **H4 (model-vs-client confound)** — Status: **moot for mitigation.** Whether it's the client or Opus 4.8, the fix is the same prose hardening; isolating the confound is not required to mitigate. (Noted, not pursued — speed discipline.)

### Root Cause
The AUTO-exit invariant was authored (2026-05-16 P1 fix) against a single failure mode — emit `TRANSITION` then a polite summary turn-end (a **passive** stop). It forbids "returning control to the user" but never enumerates the **active** stop now available to a more capable client/model: invoking `AskUserQuestion` (or any user-input tool) mid-turn at an AUTO transition. With no instruction naming that tool, the model treats an inline confirmation as compatible with "don't return control," and intermittently pauses AUTO transitions. The defect is an **incomplete prohibition**, present uniformly across Tier-1 cheat-sheets and Tier-2 pause tables.

### Resolution Plan (for mitigate — do NOT apply here)
1. **Harden Tier-1** ("Hard rule for AUTO exits") in all 12 artifacts: add an explicit clause — on an AUTO transition the orchestrator must NOT invoke `AskUserQuestion` (or any user-input/confirmation tool); an inline question IS "returning control" and is the same regression class as the narrative-summary stop. Mirror the 2026-05-16 naming style.
2. **Harden Tier-2** — add one line to the canonical pause-policy section of `agents/feature-workflow/AGENTS.md` (the single-source table) stating the AUTO ⇒ no-user-input-tool rule, and reference it from the other three orchestrators (or add the same line if they carry standalone tables).
3. **Scope-symmetry check** (per docs/lessons/scope-symmetry.md): after editing, re-grep "Hard rule for AUTO" and confirm every hit carries the new clause uniformly.
4. **Regression gate** belongs to codify: scenario asserting an AUTO transition (candidate F8, autopilot) emits its `transition_id` AND `not_contains_strict: ["AskUserQuestion"]` (failure-proxy phrase ⇒ strict mode appropriate).
5. **install.sh** propagation only needed if the snippet (`CLAUDE.snippet.md`) is also touched; current plan edits SKILL.md/AGENTS.md (symlinked) so no snippet change unless we also add a global note.

Status: **Investigating → root cause found.**

## Session Pause — 2026-06-24 16:05
Paused at `codify` → next is `/incident-resolve` (I18). See `workflow/.session.md` to resume. Note: the "1 unrelated baseline FAIL (claudesk drift)" cited above was fixed + pushed 2026-06-24 (commit 93677f0); the suite is now 290/0 — that caveat is stale.

## Timeline
- 11:46 — Incident reported
- 11:46 — Triaged: P1, route to reproduce (I13)
- 11:47 — Paused to file a second incident first (auto-branching — resolved as a config fix, commit 73e97e2)
- 11:48 — Resumed; proceeding to reproduce (I13)
- 11:49 — Reproduced via static-analysis recipe: confirmed no instruction anywhere forbids `AskUserQuestion` on AUTO exits → I14 to investigate
- 11:50 — Investigated: root cause = incomplete prohibition (AUTO-exit rule names the passive narrative-summary stop but not the active `AskUserQuestion` stop). Scope = 11 Tier-1 cheat-sheets + Tier-2 pause tables. → I6 to mitigate
- 12:14 — Live repro (operator-requested): 2/3 runs invoked AskUserQuestion at the AUTO transition
- 12:20 — Mitigated: AskUserQuestion-on-AUTO prohibition added to 11 SKILL.md + 4 orchestrator AGENTS.md; scope-symmetry confirmed
- 12:23 — Verified: post-fix probe 0/4 invocations; check-structure 268 PASS (1 unrelated pre-existing FAIL). Monitoring. → I17 to codify
- 12:36 — Codified (Path B): 13 structural pins (9 skills + 4 orchestrators) + behavioral scenario F8-autopilot-no-askuser. check-structure 281 PASS / 1 unrelated FAIL; scenario PASS+SOFT_PASS. → I18 to resolve
- 2026-06-24 16:05 — Paused at codify → resolve
- 2026-06-25 — Resumed and resolved (I18): re-ran check-structure.sh → 290 PASS / 0 FAIL (the stale "1 FAIL" claudesk-drift caveat was fixed + pushed 2026-06-24 in commit 93677f0). Resolution verified, status → Resolved, archived. Root cause (incomplete AUTO-exit prohibition) was the same class as the auto-branching sibling (commit 73e97e2) and the broader "newer client/model acts on latitude the prose never closed" pattern → SURFACE to task:plan (I11) for a proactive audit.
