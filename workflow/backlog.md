# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention).

---

## TODO

## SURFACE-2026-06-12-DEBUG-TELEMETRY-INCONCLUSIVE-STRICT-PASS-NEEDED
- **Order:** P-followup (auto-backlogged 2026-06-12 from task `sonnet-hygiene-and-telemetry-inconclusive-scenario`)
- **Source:** task:act (sonnet-hygiene-and-telemetry-inconclusive-scenario, 2026-06-12) — surfaced after 3 bite-verify attempts to land DEBUG-TELEMETRY-INCONCLUSIVE as a strict PASS scenario.
- **Target level:** task:plan (small/simple — either skill-prose fix OR alternate fixture shape)
- **Type:** test-coverage gap / SOFT_PASS-on-sonnet
- **Summary:** The new DEBUG-TELEMETRY-INCONCLUSIVE scenario (`tests/scenarios/debug.yaml`) ships SOFT_PASS on sonnet (3 attempts: $0.07 + $0.09 + $0.09 = $0.25 total bite-verify spend). The model correctly classifies the bug as inconclusive (`contains_any` matches 'inconclusive' cleanly) but emits the `TRANSITION:` line in a shape that captures only the prefix `DEBUG` via the harness regex `s/.*TRANSITION:[*[:space:]]*\([A-Za-z0-9_-]*\).*/\1/p` — likely a markdown-decorated emit like `**TRANSITION: DEBUG**-TELEMETRY-INCONCLUSIVE` where the bold-span breaks the alnum-hyphen capture class. The fixture has been hardened with explicit emit-shape instructions ("plain text exactly, no markdown decoration, do NOT split the token across lines, do NOT bold-mark it") — sonnet still ignored these.
- **Context:** Original SURFACE-2026-06-10-DEBUG-TELEMETRY-INCONCLUSIVE-SCENARIO already warned: "the INCONCLUSIVE path is structurally hard to test from a fixture because it requires conveying 'the agent has already done 3 rounds of telemetry and none discriminated' without embedding telemetry results in the fixture itself, and the model tends to suggest more telemetry rounds rather than escalating from a fixture description." The describe-then-escalate path is genuinely fragile. The two F16-triage scenarios in the same task PASSed strict cleanly via `transition_id_any: [F16, F14]` — that's the right shape for dual-identity exits. The DEBUG-TELEMETRY-INCONCLUSIVE case has a different shape (single-id exit but markdown-decoration emit issue) and needs a different fix.
- **Suggested action:** Three candidate paths, pick one when scheduled: (a) **Skill-prose fix** — tighten `skills/debug-empirical-telemetry/SKILL.md` §7 with "TRANSITION line emission discipline" sub-instruction explicitly forbidding markdown decoration of the token, and add a sample emit block with NO markdown formatting; sonnet may then comply across all uses, not just this test. (b) **Harness regex broadening** — extend `tests/lib/verify.sh` line 39 regex's character class to also capture across `**` mid-token (currently `[*[:space:]]*` is the prefix-tolerance only). Heavier change; may have other-scenario side effects. (c) **Accept SOFT_PASS** — leave as-is; lenient coverage is the documented behavior of the harness's `contains_any` fallback. The current implementation IS option (c) until a future task picks (a) or (b).
- **Priority:** low — SOFT_PASS provides lenient coverage, which is harness-supported. Strict PASS would be nice-to-have but not blocking.
- **Status:** pending

---

## MAYBE

Parked items. Revisit after the TODO list is drained. Unordered.

## SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT
- **Priority:** MAYBE
- **Source:** task:act (codify-randomize-host-ports-test-coverage, 2026-06-06) — discovered during T5 bite-verification while trying to add a behavioral content-presence assertion (P10b).
- **Target level:** feature:spec (small/medium — adds a new assertion shape to the test harness; touches `tests/lib/verify.sh`, scenarios, and the doc-side `## Conventions` block).
- **Type:** harness limitation / missing primitive
- **Summary:** `tests/lib/verify.sh::verify_result` (lines 70-82) treats a matching `transition_id` as **authoritative PASS** and never re-examines `contains_any` once that match fires. `contains_any` is only consulted as a SOFT_PASS fallback when no `transition_id` match was found. Net effect: no scenario in the current harness can hard-assert content presence. If you write `transition_id: X` + `contains_any: [Y, Z]` intending "must contain Y or Z AND emit X," you actually get "emit X (Y and Z are checked only if X fails)." Confirmed by 2x bite-verification (2026-06-06): mutated SKILL.md to remove the randomize-host-ports bullet, ran the candidate P10b scenario with `contains_any` set to literal SKILL.md prose anchors (first weak: `ephemeral|49152|randomize`; then strong: `lsof -nP -iTCP|random.randint(49152, 65535)|58329:5173`) — both passed because the model still emitted `TRANSITION: P10` correctly, and the harness short-circuited.
- **Why it matters:** Several conventions in CLAUDE.md (e.g. the integration-boundary rule's "verify-codify must include a test on the consuming surface") presuppose that scenarios can test *content* of the surface, not just transitions. Today they can't — only structural `grep_check` pins in `tests/check-structure.sh` actually hard-assert content, and those don't exercise the model. The P10b case landed cleanly on the structural-pin side (see the same task), but a future feature whose only verifiable surface is "the model emits the right downstream prose under a real skill invocation" has no harness primitive available.
- **Suggested action:** Add a new `contains_required` (or `must_contain_all` / `contains_required_any`) field to the scenario schema. Semantics: when set, even on a `transition_id` match, ALL (or ANY) of the listed strings must appear in `result_text` or the scenario FAILs. Implementation is small: a new check between lines 71 and 82 of verify.sh. Update `## Conventions` block in `CLAUDE.md` (the bullet about `expect:` fields) to document the new field. Pilot use: re-introduce a P10b-equivalent scenario with `contains_required: [<SKILL.md-prose anchor>]` once the primitive lands.
- **Original priority:** medium — current workaround (structural `grep_check` pins) covers most prose-presence regressions, but the gap will bite the moment a feature ships prose that's only meaningful when the model is actually invoking the skill (not just whether the file contains it).
- **Status:** pending

## SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH
- **Priority:** MAYBE
- **Decision 2026-06-07:** No action needed on the rule itself — the current default behavior is already OK. But the LEARNING surfaced again twice unprompted in subsequent sessions, suggesting the *re-surfacing mechanism* may itself be the friction. Worth thinking about a way to suppress / dampen re-surfacing of "no-action" learnings so they don't keep rising to the top of the backlog. Possible angle: add a `**Status:** acknowledged — no action` marker that the session-reflect/store-learning skills recognize as "do not re-elevate" without fully resolving.
- **Source:** session:reflect → session:store-learning (post-WP5 / post-claude-time-test-containerization, 2026-05-22)
- **Target level:** workflow-system source repo (`my-claude-code-customization`) — port to global CLAUDE.md's "Executing actions with care" section, OR as a new "Workflow branch-off discipline" subsection
- **Type:** new-work / workflow-system rule (global)
- **Summary:** When a workflow branches off mid-execution (pausing one feature to ship a sibling, opening a parallel incident, any cross-feature pause/resume), make a WIP commit on the paused feature's state BEFORE starting the branch-off work. Commits are cheap. A `[wip] pausing for <reason>` commit on `main` is reversible later (`git reset --soft HEAD~1`, amend, `git rebase -i`) and prevents cross-feature dirty-tree contamination. Every additional dirty file is a destructive-operation hazard surface: `git checkout HEAD -- <file>` reverts whole files (not hunks), `git stash` saves all dirty state at once across features, and selective `git add` requires per-commit discipline that's easy to slip on.
- **Context:** Today's session paused WP5 mid-Phase-4 to ship a sibling containerization feature; both features had uncommitted edits to shared files (CLAUDE.md, dashboard.jsx, viz_render.py, test_visualize_cli.sh). At a finalize-time CLAUDE.md edit, `git checkout HEAD -- CLAUDE.md` was used to revert just the new edit but whole-file-reverted both features' changes, destroying ~60 lines of WP5's URL-hash convention section (recovered manually from conversation transcript — but git reflog/fsck couldn't help since the work was never committed).
- **Suggested action:** Port the draft to a permanent home. Add a new bullet under global CLAUDE.md's "Executing actions with care" section: "Commit before branching workflows. When pausing one feature to start another (or any cross-feature pause/resume), make a WIP commit on the paused feature's in-flight state first. Commits are cheap and reversible (`git reset --soft HEAD~1`, amend, or `git rebase -i` to clean up before the next ship)." Rule-of-thumb threshold: if a pause is expected to span more than ~10 minutes or another feature's full lifecycle, commit the in-flight state.
- **Reference:** Full learning draft at `.claude/learnings/2026-05-22-commit-often-at-cross-feature-branch.md` (gitignored — local-only until promoted to source repo by hand).
- **Original priority:** medium — the failure mode hit this session (lost work recovered only via transcript); the rule applies to every cross-feature pause/resume going forward.
- **Status:** acknowledged — no action on the rule; meta-question (re-surfacing dampener) open.

## SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE
- **Priority:** MAYBE
- **Source:** Comparative analysis of `obra/superpowers` workflow system (2026-06-02). Full report archived at `docs/product/archive/research/2026-06-02-superpowers-comparison.md`. Specific borrow: superpowers' test suite includes **behavioral pressure tests** that plant rationalization-shaped inputs (e.g. "the test is flaky, just claim it passes", planted SQL injection bugs in review fixtures) and assert the skill resists. Distinct from this repo's transition tests (which verify "given input X, skill emits TRANSITION Y") and structural tests (`tests/check-structure.sh`).
- **Target level:** harness / tests (`tests/run-tests.sh` augmentation or new `tests/pressure/` group).
- **Type:** test-coverage expansion
- **Summary:** Current tests in this repo verify (a) transitions fire correctly given clean inputs, and (b) structural conventions hold (frontmatter, required sections, byte-pins). Neither tests whether discipline-bearing skill language **survives pressure** — i.e., whether `feature-verify-codify` resists a fixture that says "tests are flaky just merge it", or whether `feature-build` resists "this is a simple change just do it, no plan needed". Behavioral pressure tests are a meaningfully different signal: they test the *rationalization-resistance* of skill prose, which is the property that matters most when the model is mid-task and under time pressure. **User stance (per conversation):** maybe — existing tests are largely working, but there's potential value in more rigorous coverage. Not a priority pickup; defer until either (a) a skill failure mode in the wild traces back to language that didn't resist pressure, or (b) a future cycle has scope for test-infrastructure investment.
- **Why it matters:** This repo's principle is "advisory enforcement over hard blocks." That principle is unfalsified without pressure tests — every claim that "the prose is strong enough" rests on author intuition rather than measured behavior. If/when the principle gets challenged (a real failure mode where advisory framing let discipline lapse), pressure tests would be the empirical instrument to either defend the framing or surface specific prose weaknesses.
- **Suggested action:** Light spec when picked up. Sketch: add `tests/scenarios/pressure/` directory; each scenario is a YAML with a rationalization-shaped fixture + an expected-behavior assertion (must contain escalation language, must not emit transition-to-complete, etc.). Run on sonnet (haiku won't expose the failure mode reliably). Start with 3-5 high-value targets — verify-codify (Test Triage gate under "flaky test" pressure), feature-build (under "this is small just do it" pressure), incident-mitigate (under "ship the fix it's prod" pressure). Don't try to cover all 35 skills.
- **Original priority:** low-medium — user-flagged as "maybe", not immediate; pickup signal is either a real wild failure tracing to weak prose, or a scoped test-infrastructure cycle.
- **Status:** open

---

## Buried

The following items were buried 2026-06-07. Full content preserved in [`workflow/backlog-deferred-2026-05.md`](backlog-deferred-2026-05.md).

- `SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER` — bulk-delete safety pattern (CLAUDE.md convention proposal).
- `SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING` — audit-method gap; destructuring patterns require their own grep.
- `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` — codify plan-time downstream-contract grep into `feature-plan` SKILL.md.
- `SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD` — `docs/product/wbs.md` exceeds 300-line size guard.
- `SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG` — `--db` silently overrides `$CLAUDE_TIME_DIR` for config lookup.
- `SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE` — `session_id[:8]` truncation can collide in synthetic test data.
- `SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL-DOESNT-REACH-REACT` — synthetic `WheelEvent` dispatch doesn't reach React's `onWheel`.
- `SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT` — structural check missing; frontmatter `name:` vs. parent dir.
