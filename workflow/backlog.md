# Backlog

## SURFACE-2026-05-06-FEATURE-WORKFLOW-MISSING-REPRO-STEP
- **Source:** session-start (this conversation, 2026-05-06) — classifying the order-flip incident as a feature
- **Target level:** product:wbs (or feature:spec for a self-contained workflow change)
- **Type:** workflow-design
- **Summary:** The feature workflow has no first-class step for "reproduce the bug / observe the failure" before spec or plan. For bug-fix features (and likely some refactor / regression-style features) reproduction is the single most important early step — without it, spec is guessing at what's broken and plan is guessing at what to fix. The current workflow forces reproduction to be either smuggled into `feature-spec` (as it was here, under "Open Questions") or deferred to `feature-research`, neither of which is a clean fit. Spec is supposed to define *what* the feature does, not *whether the bug exists*; research is supposed to investigate unknowns about *the solution*, not confirm the *problem*.
- **Why this matters:** Bug-fix features without confirmed repro are a known antipattern — the "fix" can land against a misdiagnosed cause, the repro conditions are lost (so regression tests can't be written tightly), and verify-self/verify-human have nothing to compare "fixed" against. The workflow currently allows this antipattern to pass through without friction.
- **Observed in this session:** when classifying the order-flip incident, the user explicitly said "First step should be reproducing the issue." There's no skill or transition that names this. Closest fits are (a) treating `feature-research` as repro (semantically off — research is for solution unknowns), (b) packing repro into `feature-spec` (what we did, but uncomfortably), or (c) routing through the incident workflow (overkill — this isn't a production incident). None are clean.
- **Possible directions (need design discussion, not yet committed):**
  1. **Add a `feature-reproduce` step** before `feature-spec` for bug-fix features — entry transition picks reproduce vs. spec based on whether the user describes a bug or a new capability. Repro produces an artifact (failing test, manual repro path with deterministic result, or "could not reproduce — preventive fix only" finding) that spec/plan reference.
  2. **Add a "reproduction" requirement inside `feature-spec`** for any feature whose problem statement describes a bug — make it a section of the spec template with mandatory content (steps, observed behavior, expected behavior, repro determinism). Lighter weight than a new step; doesn't address the "spec is the wrong place" complaint.
  3. **Generalize `feature-research` to cover problem-confirmation as well as solution-investigation** — split it into two flavors or just broaden the description so repro fits without contortion.
  4. **Route bug-fixes through incident workflow even when not production-impacting** — incident has triage→investigate which is closer in spirit. Probably overkill but worth considering.
- **Suggested action:** Pick this up after the order-flip fix lands (so we have one fresh data point on how repro-as-spec-section actually felt). Likely a small product:research → arch decision rather than a full feature spec.
- **Priority:** medium — current workflow works (we're shipping the order-flip fix through it), but the friction is real and will recur for every bug-fix feature.
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
