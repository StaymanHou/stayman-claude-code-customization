# Backlog

## SURFACE-2026-05-08-INCIDENT-CODIFY-EQUIVALENT
- **Source:** feature:build (reproduce-step feature, 2026-05-08) — Phase 4 backlog spinout
- **Target level:** feature:spec
- **Type:** workflow-gap
- **Summary:** The incident workflow has no regression-securing step analogous to `feature-verify-codify`. After `incident-mitigate` applies a fix and `incident-resolve` confirms monitoring passes, there is no formal step that writes/extends test coverage to prevent recurrence. The new `incident-reproduce` step (when invoked) front-loads a failing test as the verify gate, but for incidents that bypass reproduce (telemetry-only, prod-data-only) — and even for ones that do go through reproduce — there's no codify-equivalent that ensures the regression test is permanently added to the suite alongside any adjacent coverage discoveries.
- **Context:** Without an incident-codify step, the regression test from incident-reproduce may live only in the WIP/archive and never enter the regular CI test suite. Mitigate's fix may not have a corresponding permanent test. This mirrors the gap that motivated feature-verify-codify in the first place.
- **Suggested action:** Design an `incident-codify` skill that runs between `incident-mitigate` and `incident-resolve`. Adapt the feature-verify-codify procedure (highest-level test, integration-boundary check, triage gate) for incident context — speed-aware, since incidents are time-sensitive. Add transitions, AGENTS.md row, pause policy.
- **Priority:** medium
- **Status:** open

## SURFACE-2026-05-08-REPRODUCE-AS-REDIRECT-FROM-BUILD
- **Source:** feature:build (reproduce-step feature, 2026-05-08) — Phase 4 backlog spinout
- **Target level:** feature:spec
- **Type:** workflow-enhancement
- **Summary:** When `feature-build` hits an "I cannot tell if my fix actually worked because I never confirmed the bug" moment, allow REDIRECT into `feature-reproduce` (similar to F22 redirect to research). Currently reproduce is only an entry transition (F31) and post-spec/plan suggestion — there's no path FROM build INTO reproduce.
- **Context:** Useful for bug-fix features that didn't go through reproduce upfront but discover during build that they need a failing-test anchor. Without this transition, the agent has to either (a) continue without confirmation, or (b) abandon and restart at reproduce. A redirect would preserve build state and let reproduce run, then resume.
- **Suggested action:** Add Fnew → build → reproduce REDIRECT transition. Update feature-build SKILL.md to surface this as a valid exit when "could not confirm fix worked" condition holds. Update reproduce SKILL.md to recognize REDIRECT entry and hand back to build.
- **Priority:** low (deferred — wait until we observe the need in practice)
- **Status:** open

## SURFACE-2026-05-06-FINALIZE-BEFORE-SHIP-ORDER-FLIP
- **Source:** observed in a real feature run (canva-permission-warmup, replicator-1-0 project, 2026-05-06)
- **Target level:** feature:spec (skills + orchestrator wording)
- **Type:** bug (model-execution drift, not a state-machine bug)
- **Summary:** After verify-codify on the final phase, the agent wrote a closing message that said "Ready for **feature-finalize → feature-ship**" — order inverted — and the user said "yes, proceed", which ran `/feature-finalize` first, then the agent finished with "Run `/feature-ship` to open the PR". The state machine is correct (F16 verify-codify→ship, F17 ship→finalize); the skills are correct (verify-codify/SKILL.md:18 says `/feature-ship` next; ship/SKILL.md:16 says `/feature-finalize` next). The bug was in the agent's *own next-step prose* between skill invocations.
- **Evidence:**
  - `agents/feature-workflow/AGENTS.md:38` diagram: `... ship → finalize → [refactor] → Exit`
  - `agents/feature-workflow/AGENTS.md:90-91`: F16 verify-codify→ship, F17 ship→finalize
  - `skills/feature-verify-codify/SKILL.md:96-97`: F16 path tells user `/feature-ship`
  - `skills/feature-ship/SKILL.md:16`: F17 path tells user `/feature-finalize`
  - The agent wrote `Unvisited: feature-finalize, feature-ship` in the WIP file's Current Node — listing finalize *before* ship. The Work Tree format docs don't specify whether `Unvisited:` is ordered by sequence-of-execution. The agent then read its own "Unvisited" list as a sequence and acted on it that way.
- **Likely root cause hypotheses (need investigation, not yet confirmed):**
  1. **`Unvisited:` field semantics undefined.** Work Tree spec in `CLAUDE.snippet.md` describes it as "phases not yet started" but doesn't say whether order matters. Agent may have written it in order-of-thought rather than order-of-execution. If the field is supposed to be ordered, the spec should say so; if it's a set, it shouldn't be read as a sequence.
  2. **Single-step invocation prose drift.** When the agent runs in single-step mode (not `/session-start` orchestration), it owns the "what's next" message between skills. Nothing forces it to re-read `agents/feature-workflow/AGENTS.md` at that handoff. The skill it just ran (verify-codify) said "/feature-ship" but the agent's *summary message* added "feature-finalize → feature-ship" — a confabulation past the skill's directive.
  3. **No assertion at skill entry.** When `/feature-finalize` ran, nothing checked "did ship happen first?" The skill executed cleanly even though the prerequisite F17 transition hadn't fired. Finalize's preconditions don't reference ship state.
- **Side effects observed in the bad run:**
  - Finalize wrote a "Feature complete: ... has shipped" closure message and updated `docs/product/roadmap.md` to mark the milestone done — *before* shipping. Roadmap is now claiming a shipped feature that hasn't been pushed.
  - WIP file was archived (`mv` to `workflow/archive/`) — `/feature-ship` now has no WIP file to read state from.
  - Backlog was scanned and the canva-permission-warmup-UX item was marked "resolved 2026-05-06" pre-ship.
- **Suggested action (when picked up):**
  1. Tighten `Unvisited:` spec — either make it explicitly "ordered, sequence of execution" or rename it. Lean toward ordered.
  2. Add an explicit "Order of operations" line to `agents/feature-workflow/AGENTS.md` near the diagram: "After verify-codify F16 → ship → finalize. Never finalize before ship — finalize archives the WIP file that ship reads from."
  3. Consider adding a check at the top of `feature-finalize/SKILL.md`: "If the WIP file's `Current Node` shows verify-codify just completed (not ship), STOP and tell user to run `/feature-ship` first."
  4. Investigation question: did the *closing prose of feature-verify-codify* in the bad run contradict the skill's stated F16 → `/feature-ship` directive? If the agent went off-script there, the bug is upstream of finalize. Worth replaying the run's verify-codify output if available.
- **Why this hurts:** the bug is silent. The state machine never errored; both skills ran cleanly; the WIP file was archived. The only signal that the order was wrong was the user noticing the closure message claimed "shipped" before any push. With auto-archival, recovering requires un-archiving the WIP file and rolling back roadmap edits.
- **Priority:** medium — has not recurred in tests (this is a real-run observation, not a transition-test failure), but blast radius is high when it happens (false roadmap claims, missing artifact for ship).
- **Status:** open — diagnosis only; no fix attempted.

## SURFACE-2026-05-06-S12-AUTOCHAIN-LEAK-IN-AUTOPILOT
- **Source:** feature:verify-auto (full-autopilot dual-identity + strict feature, S12 strict assertion)
- **Target level:** feature:spec
- **Type:** bug
- **Summary:** S12 ("session:autopilot (mode 3) pauses at verify-human") FAILs strict mode because the model emits "auto-chain" in its prose despite Mode 3 explicitly stating verify-human is the only pause point. The structured TRANSITION emission is correct (S12); the prose is contradicting the assertion. Discovered when `not_contains_strict: true` was added to surface this kind of contradiction.
- **Context:** run-2026-05-06-143839-combined.json. The model output structurally matches but text-content-leaks "auto-chain" while describing the autopilot pause. Likely the model is reasoning about what it WOULDN'T do and the negation slips. session-start/SKILL.md "Drive modes" section may need wording that suppresses prose mention of auto-chain when discussing pause points.
- **Suggested action:** Investigate session-start/SKILL.md "Mode 3" guidance. Consider adding "When describing Mode 3's behavior, do not use 'auto-chain' even in negation — say 'pauses at verify-human' affirmatively." Test with `--id S12` after edit.
- **Priority:** medium
- **Status:** pending — discovered by strict-mode harness; surfaces a wording/clarity issue, not a structural one.

---

## Resolved (chronological log)

- **SURFACE-2026-05-06-FEATURE-WORKFLOW-MISSING-REPRO-STEP** — RESOLVED 2026-05-09: Implemented option 1 (new `feature-reproduce` and `incident-reproduce` skills). Feature workflow gained F31–F35 transitions; incident workflow gained I13–I16 transitions; session-start gained S18 routing for bug-shape language. Backlog spinouts: SURFACE-2026-05-08-INCIDENT-CODIFY-EQUIVALENT (incident codify gap, medium) and SURFACE-2026-05-08-REPRODUCE-AS-REDIRECT-FROM-BUILD (low, deferred). Open known issues: F31 prose-leak (SOFT_PASS, same family as S12 leak); I13 wrong-transition-emission (SOFT_PASS, model emits I2 instead of I13 — test-design / SKILL clarity tradeoff). Both logged as Test Triage blocks in `workflow/wip/reproduce-step.md`.
- **SURFACE-2026-05-08-SETTINGS-JSON-ALLOWLIST-CRUFT** — RESOLVED 2026-05-08: deleted four token-hardcoded GET allowlist entries (getUpdates x3, getWebhookInfo); kept POST pattern as generic fallback. Hook smoke-tested.
- **SURFACE-2026-05-06-S9-S11-S14-DUAL-IDENTITY** — RESOLVED 2026-05-06: `transition_id_any` added to `tests/lib/verify.sh`; S9/S11/S12/S13/S14 updated. S9 PASSes via S9|F19 union. (S12 strict-mode regression spun out as SURFACE-2026-05-06-S12-AUTOCHAIN-LEAK-IN-AUTOPILOT, still open above.)
- **SURFACE-2026-05-06-S10-S13-ROUTING-OVERRIDES-DRIVE-MODE** — RESOLVED 2026-05-06: `transition_id_any: [S10, S3]` and `[S13, F8]` applied. Some haiku-noise SOFT_PASS shape remains.
- **SURFACE-2026-05-05-D2** — RESOLVED 2026-05-06: `not_contains_strict` opt-in added to `tests/lib/verify.sh`. Strict mode applied to S12 and S14; caught a real prose-leak bug in S12 (logged separately).
- **SURFACE-2026-05-05-HIDDEN-FAIL-F4** — RESOLVED 2026-05-06: `model: sonnet` added; PASSes via tests/run-all.sh sonnet pass.
- **SURFACE-2026-05-05-HIDDEN-FAIL-S3** — RESOLVED 2026-05-06: Valid transitions section added to session-start/SKILL.md; S3 also tagged `model: sonnet`. Sonnet PASSes consistently.
- **SURFACE-2026-05-05-HIDDEN-FAIL-S6** — RESOLVED 2026-05-06: Valid transitions section added to session-resume/SKILL.md; S6 PASSes on haiku.
- **SURFACE-2026-05-05-F22-FLAKY-REGRESSED-TO-FAIL** — RESOLVED 2026-05-06: `model: sonnet` added; PASSes via tests/run-all.sh sonnet pass.
- **SURFACE-2026-05-05-HIDDEN-FAIL-S10** — RESOLVED 2026-05-06: `transition_id_any: [S10, S3]` applied (see ROUTING-OVERRIDES-DRIVE-MODE entry above).
- **SURFACE-2026-05-05-HIDDEN-FAIL-S13** — RESOLVED 2026-05-06: `transition_id_any: [S13, F8]` applied (see ROUTING-OVERRIDES-DRIVE-MODE entry above).
