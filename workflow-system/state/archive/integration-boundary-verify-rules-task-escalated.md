# Task: Close the integration-boundary blind spot in verify-self / verify-human / verify-codify

**Workflow:** task
**State:** ESCALATED to feature workflow on 2026-05-05 (T9 / F28)
**Created:** 2026-05-05
**Drive mode:** orchestrated

**Escalation note:** Reproduction-first failed (T3 returned 3 PASS instead of 3 FAIL — see Discoveries). Re-planning would not be enough: the work now spans test-prompt design, three SKILL.md revisions, transitions.md + CLAUDE.md sync, regression sweep, and likely multiple back-loops as boundary-rule wording is tuned against haiku model behavior. This exceeds task scope (≤4hrs, <200 LOC, single atomic change). Escalating to feature workflow. The fixture (`tests/fixtures/wip/feature-verify-wire-into-existing.md`) and 3 scenarios (F-boundary-self, F-boundary-human, F-boundary-codify in `tests/scenarios/feature.yaml`) remain on disk and become starting context for the feature plan.

## Problem Statement

When a phase wires a new service/module into an *existing* endpoint, route, UI surface, CLI entry, scheduled job, or external-system call site, all three verify steps currently allow the agent to exercise only the new artifact and never the consuming surface — the seam where behavior actually changed for users. Production failure: `MusicPoolService.get_random` was wired into `POST /distribution/match`; verify-self ran 5 outcomes against the new module + new dedicated endpoints, verify-human was waived as "nothing to manually verify," verify-codify added 7 unit tests on the new module, and the wiring shipped untested at the integration boundary.

## Context

**Files in scope (skill prompts to revise):**
- `skills/feature-verify-self/SKILL.md` (112 lines) — Procedure §1 reads Observable Outcomes from the WIP file; the "must include HTTP/Browser/CLI" rule lives in `skills/feature-plan/SKILL.md` (where outcomes are written), not here. We add a parse-time check in verify-self to refuse the run when boundary applies and no outcome targets the consuming surface.
- `skills/feature-verify-human/SKILL.md` (106 lines) — Procedure §2 has the "nothing for human to test" skip path that fired on F11. This is where the trigger affirmation goes.
- `skills/feature-verify-codify/SKILL.md` (97 lines) — Procedure §2 "Determine What Needs New Tests" is where the boundary-required test rule lands.

**Files for sync (state-machine three-places invariant):**
- `docs/product/transitions.md` — F11 row at line 255 currently reads "Nothing for human to test — agent presents reasoning, human confirms skip". Will be tightened.
- `CLAUDE.md` — currently has no F11-specific language; no change needed unless we add a top-level convention. (Decision: add a one-line bullet under "Conventions" pointing to the boundary trigger so the invariant is visible at the project level.)

**Existing test scenarios used as shape templates (read-only):** F10 (verify-auto → self), F11 (human skip with reasoning), F13 (human approve), F13-prefiltered (excludes verify-self [x] items), F14 (codify back-loop), F15 (codify → next phase).

**Existing fixture closest to our need:** `tests/fixtures/wip/feature-verify-auto-passed.md` describes a *new-build* phase (Backend API for notification preferences) — it does NOT model wiring into an existing endpoint. We must add a new fixture.

**Backlog:** empty.

## Design — the "integration boundary" trigger

Mechanically checkable. A phase has an integration boundary when **any one** of the following is true:

1. The phase modifies a call site or wiring inside an **existing** HTTP endpoint, GraphQL resolver, RPC handler, route handler, controller action, or middleware.
2. The phase modifies an **existing** UI surface (page, component, view) such that user-visible behavior changes — including swapping a data source, changing a render path, or replacing event handlers.
3. The phase modifies an **existing** CLI command, subcommand, or argument parser.
4. The phase changes what an **existing** scheduled job, cron, queue consumer, or background worker does.
5. The phase changes the request/response shape, payload, or behavior of an **existing** outbound call to an external system, or swaps which external system is called.

A phase that *only* adds new isolated artifacts (a new module never imported by existing code, a new endpoint never linked from anywhere, a new constant, a renamed private function) does **not** have an integration boundary. The agent must affirm this in writing to take the lightweight path.

Phrasing chosen so the agent can answer mechanically: "Did this phase add a line of code inside a file that an existing endpoint/route/UI/CLI/job/external-call already consumed? If yes, boundary applies."

## Test Strategy

Three new YAML scenarios appended to `tests/scenarios/feature.yaml`. All use a new fixture `tests/fixtures/wip/feature-verify-wire-into-existing.md` that explicitly describes a "wire MusicPoolService into existing POST /distribution/match" phase, with Observable Outcomes that **only** target the new module + new dedicated endpoints (mirroring the production failure).

**Verification protocol:**
1. Append the 3 scenarios + new fixture.
2. Run `./tests/run-tests.sh --id F-boundary-self,F-boundary-human,F-boundary-codify` against the **unrevised** skill prompts. **Expected:** all 3 fail (current prompts let the agent breeze through; assertions on "must target consuming endpoint" / "skip not allowed" / "must include test on consuming surface" don't fire).
3. Apply skill prompt revisions.
4. Re-run the same command. **Expected:** all 3 pass.
5. Run the full feature group `./tests/run-tests.sh --group feature` to confirm no regression in F11, F13, F13-prefiltered, F14, F15. F11's existing fixture (`feature-verify-auto-passed.md`) describes a notification-preferences phase that adds *new* endpoints with no existing consumer — under the new rule this is correctly NOT a boundary, so F11 should still pass with the agent affirming "no boundary" before skipping.

Default model `haiku`. If a haiku run is genuinely ambiguous on the new scenarios, escalate to `--model sonnet` for that ID — note the override in the scenario comment.

## Work Tree

- [x] T1: Add fixture `tests/fixtures/wip/feature-verify-wire-into-existing.md`
- [x] T2: Append 3 reproduction scenarios to `tests/scenarios/feature.yaml`
- [ ] T3: Run reproduction → all 3 should FAIL  <!-- status: FAILED — all 3 PASSED against unrevised prompts; reproduction is invalid; back-loop to plan -->
- [ ] T4: Revise `skills/feature-verify-self/SKILL.md`  <!-- status: BLOCKED: depends on T3 -->
- [ ] T5: Revise `skills/feature-verify-human/SKILL.md`  <!-- status: BLOCKED: depends on T3 -->
- [ ] T6: Revise `skills/feature-verify-codify/SKILL.md`  <!-- status: BLOCKED: depends on T3 -->
- [ ] T7: Sync `docs/product/transitions.md` (F11 row) and add boundary-trigger note  <!-- status: BLOCKED: depends on T3 -->
- [ ] T8: Sync `CLAUDE.md` Conventions section with one-line boundary-trigger pointer  <!-- status: BLOCKED: depends on T3 -->
- [ ] T9: Re-run boundary scenarios — confirm pass; then run `--group feature` for regression  <!-- status: BLOCKED: depends on T3 -->
- [ ] T10: Run `./tests/check-structure.sh` to confirm structural invariants hold  <!-- status: BLOCKED: depends on T3 -->

## Detailed proposals

### T1 — New fixture

`tests/fixtures/wip/feature-verify-wire-into-existing.md` mirrors the structure of `feature-verify-auto-passed.md` but describes a phase that **wires** rather than builds-anew. Phase shape:

- Phase 1: "Wire MusicPoolService into POST /distribution/match"
- Implementation leaves marked `[x]`: P1.1 add `MusicPoolService` module, P1.2 expose `/music/pool/seed` and `/music/pool/status` admin endpoints, P1.3 replace existing `video_id = sheet.lookup(...)` line in `/distribution/match` with `video_id = MusicPoolService.get_random(service.session)`
- `verify-auto` `[x]`
- Observable Outcomes (deliberately wrong — this is the failure pattern):
  - HTTP: GET /music/pool/status → 200, body has `count` field
  - HTTP: POST /music/pool/seed → 200, body confirms seeded
  - CLI: `python -m music_pool.populate` exits 0
  - HTTP: GET /music/pool/list → 200, returns array
  - HTTP: GET /music/pool/random → 200, returns one item
- `## Current Node` Path = "Feature > Phase 1 > verify-self"

This fixture is the input the model sees. The boundary trigger is in the implementation leaf P1.3 ("replace existing line in `/distribution/match`"), so the model has the information it needs to recognize the boundary. The Observable Outcomes deliberately do NOT cite `/distribution/match` — that's the gap the new rule must catch.

### T2 — Reproduction scenarios

Appended to `tests/scenarios/feature.yaml` after the existing F-codify-* scenarios:

```yaml
  # PP6: Integration-boundary blind-spot scenarios
  # Reproduces the MusicPool failure where verify-self/human/codify all let
  # the agent test only the new artifact and skip the consuming surface.

  - id: F-boundary-self
    name: "feature:verify-self refuses run when boundary outcome missing"
    skill: feature-verify-self
    args: "http://localhost:8000"
    fixtures:
      claude_md: fixtures/CLAUDE.md
      wip: fixtures/wip/feature-verify-wire-into-existing.md
    system_prompt_extra: |
      Phase 1 wires the new MusicPoolService into the EXISTING endpoint
      POST /distribution/match (the line `video_id = sheet.lookup(...)`
      is replaced with `video_id = MusicPoolService.get_random(...)`).
      The Observable Outcomes listed in the WIP file all target the new
      module and the new admin endpoints (/music/pool/seed, /status,
      /list, /random). NONE of them target POST /distribution/match —
      the surface where consumer-visible behavior actually changes.
      You should detect this gap and refuse to mark verify-self complete
      until an outcome targeting POST /distribution/match is added.
    expect:
      transition_id: F9b
      contains_any:
        - "/distribution/match"
        - "integration boundary"
        - "consuming"
        - "back-loop"
      not_contains:
        - "/feature-verify-human"
    max_retries: 2

  - id: F-boundary-human
    name: "feature:verify-human cannot skip when phase wires into existing endpoint"
    skill: feature-verify-human
    args: "phase 1"
    fixtures:
      claude_md: fixtures/CLAUDE.md
      wip: fixtures/wip/feature-verify-wire-into-existing.md
    system_prompt_extra: |
      Phase 1 wires the new MusicPoolService into the EXISTING endpoint
      POST /distribution/match. There is no UI for this phase — it is
      backend-only. A previous version of this skill allowed the agent
      to skip verify-human entirely on backend-only phases. The new
      rule forbids the skip when a phase wires into any existing
      endpoint, route, UI, CLI, scheduled job, or external system.
      The minimum check is a recorded curl against the consuming
      endpoint with the response captured.
    expect:
      transition_id: F13
      contains_any:
        - "/distribution/match"
        - "curl"
      not_contains:
        - "nothing to manually verify"
        - "nothing to manually test"
        - "skip"
    max_retries: 2

  - id: F-boundary-codify
    name: "feature:verify-codify requires test on consuming surface when boundary applies"
    skill: feature-verify-codify
    args: "phase 1"
    fixtures:
      claude_md: fixtures/CLAUDE.md
      wip: fixtures/wip/feature-verify-wire-into-existing.md
    system_prompt_extra: |
      Phase 1 wires the new MusicPoolService into the EXISTING endpoint
      POST /distribution/match. Existing tests cover the new module in
      isolation but no test exercises POST /distribution/match's
      response shape post-wiring. Codify must add at least one test
      that hits POST /distribution/match end-to-end and asserts the
      response reflects the new wiring (e.g., the returned video_id
      is one the pool would have produced, not a sheet lookup).
    expect:
      transition_id: F15
      contains_any:
        - "/distribution/match"
        - "end-to-end"
        - "integration"
      not_contains:
        - "/feature-ship"
    max_retries: 2
```

**Why these `transition_id`s:** F-boundary-self uses F9b because the correct behavior is a back-loop to build (add the missing outcome to the plan, or add the outcome and run the check). F-boundary-human uses F13 (approve after human runs the curl) — the assertion is on the *content* of the checklist (must reference `/distribution/match`, must include a curl), not on a refusal. F-boundary-codify uses F15 (next phase) — the assertion is on whether codify's plan includes the consuming-surface test before moving on.

### T4 — `skills/feature-verify-self/SKILL.md` revision

Insert a new section **after** the "## Severity Taxonomy" block and before "## Procedure" (around line 36):

```markdown
## Integration-boundary rule

A phase has an **integration boundary** when any of the following is true of the implementation leaves under the current phase:

1. A line of code was added or modified inside a file that an existing HTTP endpoint, route, controller, GraphQL resolver, RPC handler, or middleware already consumed.
2. A line of code was added or modified inside a file that backs an existing UI page, view, or component such that user-visible behavior changes.
3. A line of code was added or modified inside an existing CLI command, subcommand, or argument parser.
4. A line of code was added or modified inside an existing scheduled job, cron, queue consumer, or background worker.
5. The request/response shape, payload, or destination of an existing outbound call to an external system was changed.

If a boundary applies, **at least one Observable Outcome for this phase must cite the consuming surface by name** — the existing endpoint path, route URL, UI page URL, CLI command, job name, or external-call target. An outcome that only exercises the new module or new dedicated admin/status endpoints does not satisfy this rule.

If you reach §1 of the procedure and find the current phase has a boundary but no outcome citing the consuming surface, **do not run the verification subagent**. Instead, document the missing outcome and back-loop to build (F9b) so the plan can be updated and the missing outcome verified. Cite the specific consuming surface (e.g. `POST /distribution/match`) in your back-loop message.

If a boundary does not apply (the phase only adds isolated new artifacts — a new module nothing imports, a new endpoint nothing links to, a constant, a renamed private function), this rule does not apply. Note in your output: "No integration boundary — phase adds isolated new artifacts only."
```

**Then modify Procedure §1** ("Read inputs", line 38–43) by adding a fourth bullet:

> - Determine whether this phase has an **integration boundary** (see "Integration-boundary rule" above). If yes, confirm at least one Observable Outcome cites the consuming surface; if no such outcome exists, follow the back-loop guidance in that section.

### T5 — `skills/feature-verify-human/SKILL.md` revision

Replace Procedure §2 ("Assess Whether Human Testing is Needed", lines 31–37). Existing text:

```markdown
### 2. Assess Whether Human Testing is Needed
Review the current phase and determine if there are user-facing changes that need manual verification.

**If there is genuinely nothing for a human to test** (e.g., purely internal refactor, backend-only logic with full test coverage):
- Present your reasoning for why there's nothing to manually test
- Explicitly ask the human: "I believe there's nothing to manually verify for this phase because [reasoning]. Do you agree to skip to verify-codify?"
- Only proceed to verify-codify (F11) if the human confirms
```

New text:

```markdown
### 2. Assess Whether Human Testing is Needed

First, determine whether this phase has an **integration boundary**. A phase has a boundary when any of the following is true:

1. A line of code was added or modified inside a file that an existing HTTP endpoint, route, controller, resolver, or middleware already consumed.
2. A line of code was added or modified inside an existing UI page, view, or component such that user-visible behavior changes.
3. A line of code was added or modified inside an existing CLI command or argument parser.
4. A line of code was added or modified inside an existing scheduled job, cron, queue consumer, or background worker.
5. The request/response shape, payload, or destination of an existing outbound call to an external system was changed.

**If a boundary applies, the F11 skip path is forbidden.** Even when there is no UI to click, the human checklist MUST include at least one item: a recorded `curl` (or equivalent CLI invocation) against the consuming surface, with the response captured. Phrase the item so the human can copy-paste-run it: e.g. "Run `curl -sS -X POST http://localhost:8000/distribution/match -d '{...}'` and paste the response — confirm the `video_id` field is one the new pool would produce." Do **not** mark the phase complete on the human's "looks fine" alone — require the captured response.

**If no boundary applies** (the phase only adds isolated new artifacts that no existing surface consumes):
- Affirm this in writing: "This phase does NOT wire into any existing endpoint, route, UI page, CLI command, scheduled job, or external-system call. It only adds isolated new artifacts: [list them]."
- Then ask the human: "Given that affirmation, do you agree to skip to verify-codify?"
- Only proceed to verify-codify (F11) if the human confirms.

The skip path is gated by the affirmation, not by the agent's general judgment that "there is nothing to test."
```

This rewires F11 so the trigger for skipping is the affirmation that no boundary exists. The existing F11 scenario (notification preferences, all-new endpoints with no prior consumer) still passes because the agent can truthfully affirm "no boundary."

### T6 — `skills/feature-verify-codify/SKILL.md` revision

Insert a new sub-section **inside** Procedure §2 ("Determine What Needs New Tests"), immediately after the existing "Do not default to unit tests" paragraph (line 41):

```markdown
**Integration-boundary requirement:** if this phase wired or modified a line of code inside an existing HTTP endpoint, route, UI surface, CLI command, scheduled job, or external-system call, the test set MUST include at least one test that exercises the consuming surface end-to-end and asserts the post-change behavior. Cite the consuming surface by name in the test (e.g. a test against `POST /distribution/match` that asserts the response reflects the new wiring). Unit tests on the new module do not satisfy this requirement; the consuming-surface test is in addition to whatever unit-level coverage you write.

If you cannot identify a single consuming surface — or the phase only added isolated new artifacts — note "No integration boundary — phase adds isolated new artifacts only" and skip this requirement.
```

This sits cleanly inside the existing test-level decision tree (it's a constraint, not a separate procedure).

### T7 — `docs/product/transitions.md` sync

Two edits:

1. Replace the F11 row (line 255):
   ```
   | F11 | verify-human | verify-codify | Nothing for human to test — agent presents reasoning, human confirms skip |
   ```
   with:
   ```
   | F11 | verify-human | verify-codify | Phase has no integration boundary (agent affirms in writing) and human confirms skip — see verify-human SKILL.md "Integration-boundary rule" |
   ```

2. Add a new sub-section after the per-phase loop description (location to be located during T7; expected near the existing "verify-self / verify-human / verify-codify" paragraph that explains the loop). Heading: `### Integration-boundary rule (verify-self / verify-human / verify-codify)`. Body: a one-paragraph summary plus a pointer to each SKILL.md for the full rule.

### T8 — `CLAUDE.md` sync

Add a one-line bullet under the existing "## Conventions" section near the bottom:

> - **Integration-boundary rule** in the per-phase verify loop: when a phase modifies code inside an existing endpoint, UI, CLI, job, or external call site, verify-self must include an outcome citing the consuming surface, verify-human cannot use the F11 skip path, and verify-codify must include a test on the consuming surface. Full rule in each `feature-verify-*/SKILL.md`.

## Current Node
- **Path:** Task > T3 (FAILED) → back-loop to plan
- **Active scope:** none — task-plan must redesign T2's `system_prompt_extra` blocks before any further act work
- **Blocked:** T4–T10 all blocked on T3
- **Open discoveries:** D1 (prompt leak), D2 (test-harness lenience — informational, not blocking)

## Discoveries

[SURFACED-2026-05-05] T3 — **Prompt leak in reproduction scenarios.** All three new scenarios PASSED against the unrevised prompts (the opposite of what the plan predicted). Inspection of `tests/results/run-2026-05-05-163221.json`:

- **F-boundary-self:** model emitted `TRANSITION: F9b` on the first try with no boundary rule in the SKILL.md. Cause: `system_prompt_extra` includes "*You should detect this gap and refuse to mark verify-self complete until an outcome targeting POST /distribution/match is added.*" — that sentence prescribes the desired behavior. The model is following the test, not the SKILL.
- **F-boundary-human:** transition_found `F10` (which isn't even valid for verify-human); harness gave SOFT_PASS via `contains_any` match on `/distribution/match`. The system_prompt_extra also leaks ("*The new rule forbids the skip when...*"). Plus `not_contains: ["skip"]` was violated but transition matched, so PASS — see D2.
- **F-boundary-codify:** transition_found `F13` (also wrong — F13 is verify-human's approve transition); `contains_any` match on `/distribution/match`. system_prompt_extra leaks similarly.

**Root cause:** my `system_prompt_extra` blocks describe both the situation AND the desired behavior. Compare to existing F11 (line 382–386) which describes only the situation: "Phase 1 is purely backend API work — there is no UI, no user-facing interface to manually test." The model has to reason from situation to transition; the test does not tell it the answer.

**Fix on re-plan:** rewrite each `system_prompt_extra` to describe only the wiring situation, the existing endpoint name, and the (deliberately wrong) Observable Outcomes — but NOT prescribe what the model should do about it. Against unrevised prompts the model should reach the wrong transition (F10b for verify-self, F11 for verify-human, F15/F16 for verify-codify); after revision, with the boundary rule in the SKILL, it should reach the right transition.

[SURFACED-2026-05-05] D2 — **Test-harness `not_contains` is informational when TRANSITION matches.** `tests/lib/verify.sh` line 32–38 documents this as intentional ("structured match is authoritative"). For the boundary scenarios this means I cannot rely on `not_contains: ["skip"]` to fail F-boundary-human — I must rely on the wrong-transition signal alone. Logged to backlog as low-priority for future consideration; not a blocker for this task.
