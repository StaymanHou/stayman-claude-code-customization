# Backlog

## SURFACE-2026-05-22-CLAUDE-MD-MISSING-CLAUDE-TIME-CONTAINER-NOTE
- **Source:** feature:finalize (claude-time-test-containerization, 2026-05-22)
- **Target level:** task:plan (small/simple — single paragraph append)
- **Type:** doc-gap
- **Summary:** Project root `CLAUDE.md` doesn't mention that `tools/claude-time/` tests now run inside a Docker container via `tools/claude-time/test/run-in-container.sh`. The README under `tools/claude-time/` covers it fully, but a contributor reading the project-root CLAUDE.md sees only the workflow-system test invocations and would assume host-side tests are supported.
- **Context:** During finalize of `claude-time-test-containerization`, a brief paragraph was drafted to add under `## Commands` in CLAUDE.md but had to be reverted because of an operator mistake (`git checkout HEAD -- CLAUDE.md` while the file had cross-feature dirty state from WP5 — see lesson logged in retrospect of `claude-time-test-containerization`). Re-adding the paragraph would only collide with WP5's still-uncommitted CLAUDE.md edits; deferring to a clean window.
- **Suggested action:** After WP5 of `claude-time-visualize-v2` ships and CLAUDE.md is clean again, append a paragraph under `## Commands` (right after the workflow-system test runner block) explaining: container is the canonical test path for `tools/claude-time/`; lifecycle wrapper at `tools/claude-time/test/run-in-container.sh` (start/stop/status/exec/restart/logs/help); bundles Python 3.12 + Perl + sqlite3 + jq + Node + Playwright + Chromium; project root bind-mounts at `/work` rw; see `tools/claude-time/README.md` → "Running tests" for canonical invocations. ~3 sentences, single hunk.
- **Priority:** low — discoverable from `tools/claude-time/README.md` already; CLAUDE.md note is a nice signal for project-root readers but not a blocker.
- **Status:** open

## SURFACE-2026-05-19-CLAUDE-TIME-VIZ-NOW-LABEL-OVERLAPS-RULER-TICK
- **Source:** feature:verify-human (claude-time-visualize-v2 WP2 NOW marker, 2026-05-19)
- **Target level:** task:plan (small/simple — single component, label-placement logic)
- **Type:** polish / cosmetic
- **Summary:** When the wall-clock time falls within roughly 10 minutes of a top-of-hour ruler tick (e.g., 11:52 with the next tick at 12:00), the `NOW · HH:MM` label rendered to the right of the NOW vertical line visually overlaps the next-hour ruler tick label. Marker placement is geometrically correct; only the text overlays.
- **Context:** Surfaced and human-accepted at WP2 verify-human (2026-05-19). User explicitly chose to accept the cosmetic and ship without a fix to keep WP2 scope tight. The condition happens for ~10 minutes per hour, ~1/6 of the time.
- **Suggested action:** Modify `HourRuler` in `viz/dashboard.jsx` to flip the `NOW · HH:MM` label to the left of the NOW line when `nowMin` is within ~10 minutes of a top-of-hour ruler tick (i.e., `nowMin % 60 >= 50` or `nowMin % 60 < 10`). Alternative: render the label below the line instead of beside it. Either is single-file scope.
- **Priority:** low — cosmetic-only, marker correctness is intact, human accepted as-is.
- **Status:** RESOLVED 2026-05-22 in claude-time-visualize-v2 WP5 Phase 2 (P2.7 opportunistic fold-in). Mechanical 3-line change inside HourRuler's adaptive-density refactor: `flipNowLeft = nowMin != null && (nowMin % intervalMin) >= (intervalMin - 10)` — when true, the `NOW · HH:MM` label gets `right: 4` instead of `left: 4`. Adapts to adaptive tick density: the 10-minute threshold uses the current `intervalMin` as reference so the fix works at any zoom level. CHANGELOG entry at finalize.

## SURFACE-2026-05-22-CLAUDE-TIME-VIZ-DAY-VIEW-MULTI-DAY-DATA-WINDOW
- **Source:** feature:verify-human (claude-time-visualize-v2 WP5 Phase 2 and 3, 2026-05-22)
- **Target level:** feature:plan (resolves into a new dedicated WP — see Decision below)
- **Type:** new-work / UX refinement uncovered during Phase 2 verify-human
- **Summary:** User wants to pan the Day-view timeline beyond the current day (both past AND future) and see actual data, not empty time. Currently `_cmd_visualize` calls `build_day_data(date)` and emits only that day's events. The viewport math (WP5) lets you pan past the day boundary, but there's no data there.
- **Context:** Surfaced at Phase 2 verify-human ("is it normal that it doesn't show data yet when I drag beyond yesterday?" → direct: "I want to be able to drag and pan beyond the current day (both past AND future)"). Re-discussed at Phase 3 verify-human pause: user emphasized "this feature really matters to me!" and clarified that this is NOT the same as WP8 (Custom-range, which is a *user-picked* start+end with a date-picker UI) and NOT the same as WP7 (Month, which is a different *aggregation* concern).
- **Decision (2026-05-22):** Promote to a dedicated WP (working name **WP5b: Multi-day data window for Day view**). Slot after WP5 in the WBS to keep WP6..WP13 numbering stable. WP7 stays as planned (Month = high-level aggregated stats, like Week view but at month granularity — genuinely different concern). WP8 stays as planned (Custom-range = user-picked start+end via UI tab — distinct from "Day view extends its window automatically").
- **Suggested WP5b plan (recorded now; WBS edit happens at WP5-finalize boundary):**
  - **Description:** Day view loads trailing+leading context days into the data window. Current day is default-viewport center; pan reveals neighbors.
  - **Phase:** 2 (sits with view-modes phase as a Day-view extension)
  - **Dependencies:** WP3 (range-aware data layer — shipped), WP5 (viewport mechanic + URL hash — current WP)
  - **Size:** S–M (data plumbing + label formatter; risk surface = extending `pickTickInterval`'s scale set to support day-level ticks for zoom-out across 21 days, otherwise ruler tick density blows past the 8–30 band)
  - **Defaults (locked):** `viz_context_days_prior = 14`, `viz_context_days_after = 7`. Per-invocation override via CLI flags `--context-days-prior N` + `--context-days-after M` (or compact `--context PRIOR:AFTER`). Both CLI flags AND `~/.claude-time/config.json` config keys supported; CLI overrides config; config overrides defaults.
  - **Tasks:**
    1. Wire `_cmd_visualize` to call `build_range_data` with `[date − N_prior, date + N_after]` when context days > 0.
    2. New CLI flags + config keys.
    3. ISO-day-aware label formatter: `MMM DD HH:MM` when viewport crosses midnight; `HH:MM` within a single day (no regression on current default-hash demo).
    4. Extend `pickTickInterval` scale set to include `[1440 (day), 360 (6h)]` for zoom-out across multi-day data windows. Adaptive ruler picks day-level ticks when viewport spans ≥ ~2 days.
    5. Initial viewport stays centered on the requested day (no behavior change on default-hash path — WP5 verify-human regression-pinned).
    6. Test: extend `test_visualize_cli.sh` to seed multi-day events and assert emitted CT_DATA + ruler tick density across day boundaries.
- **Priority:** medium-high — directly user-prioritized ("this feature really matters to me!"). Bumped from medium. Picks up after WP5 (current) ships and finalizes.
- **Status:** open — will become `RESOLVED` when WP5b ships and is logged to CHANGELOG.

## SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME
- **Source:** feature:verify-codify (claude-time-report-by-project Phase 1, 2026-05-18)
- **Target level:** task:plan (small/simple — fixture update or INTENTIONAL_DIFFS allow-list)
- **Type:** test-infra / gap (test fixture out of sync with documented install end-state)
- **Summary:** `tests/check-structure.sh` Phase 7 (settings-drift check) fails with 9 drift lines — all of them claude-time hook entries (UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, SessionStart, SessionEnd, SubagentStart, SubagentStop) plus the `CLAUDE_TIME_TRACKING` env var. These are present in the user's live `~/.claude/settings.json` because the user followed the install instructions in `tools/claude-time/README.md` steps 2 and 3 (the shipped previous feature documents this as the required install state). The fixture `tests/fixtures/settings.json` doesn't know about them.
- **Context:** Surfaced during Phase 1 verify-codify of the `--by` grouping feature. The drift is pre-existing relative to that feature — none of the `--by` feature's changes touched fixtures, install.sh, or settings. It's the previous claude-time feature's install state being correctly applied to the user's machine.
- **Suggested action:** Choose one of (a) extend `tests/fixtures/settings.json` to include the claude-time hooks block + env (treating them as documented standard install state for this repo), or (b) add the relevant keys to `INTENTIONAL_DIFFS` in `tests/check-structure.sh` (treating them as per-machine opt-in state that varies legitimately). (a) is preferable if the repo wants the structure check to assert "claude-time is wired up correctly for any contributor"; (b) is preferable if opting in is intentionally per-machine. Probably (b) since the README explicitly frames the install as opt-in.
- **Priority:** medium — structural check currently fails on a clean run, which obscures real regressions.
- **Status:** open

## SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT
- **Source:** incident:resolve (autopilot-pause-policy-recheck-regression, 2026-05-17)
- **Target level:** task:plan (small/simple — single bash/python pass parsing two source files)
- **Type:** gap (test coverage — structural-only check doesn't catch behavioral drift)
- **Summary:** `tests/check-structure.sh` Phase 9 asserts each of the 8 affected feature SKILL.md files contains an `## Orchestrator Pause Policy (cheat-sheet)` block with the `Hard rule for AUTO exits` anchor + 4-mode table row, but does NOT assert that the per-skill table rows *match* the canonical pause-policy table in `agents/feature-workflow/AGENTS.md`. If AGENTS.md changes (e.g. a transition flips PAUSE↔AUTO for a drive mode), the per-skill cheat-sheets could silently drift and continue claiming the old policy.
- **Context:** Phase 9 was added by `incident-codify` as the structural substitute for behavioral red→green coverage (which was unavailable because reproduction was abandoned per `SURFACE-2026-05-17-CLAUDE-PRINT-AGENTIC-LOOP-SUPPRESSES-PAUSE-DECISION`). The structural check catches outright deletion or imperative weakening; the drift case is uncovered.
- **Suggested action:** Extend Phase 9 (or add Phase 10) that:
  1. Parses the pause-policy table from `agents/feature-workflow/AGENTS.md` into a `{skill_or_transition_key: {mode: AUTO|PAUSE|SKIP}}` dict.
  2. For each of the 8 affected SKILL.md files, parses its cheat-sheet table.
  3. Asserts every per-skill row matches the corresponding row in the canonical table.
  Likely 30–60 lines of bash + a small awk/python helper. Single source of truth: AGENTS.md.
- **Priority:** medium (not blocking; the regression mode (drift) is plausible but lower-probability than the regression mode Phase 9 already catches (prose removal/softening)).
- **Status:** pending

## SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT
- **Source:** feature:verify-codify (debug-skills-category-and-bisect-known-good Phase 1, 2026-05-13)
- **Target level:** task:plan (small/simple — single bash loop added to `tests/check-structure.sh`)
- **Type:** gap (test coverage)
- **Summary:** No structural check asserts that each `skills/<name>/SKILL.md`'s frontmatter `name:` field matches its parent directory name. If they diverge (e.g. someone renames the dir without updating frontmatter), the skill may stop being invokable via its slash command and the discovery is silent — `install.sh` only checks the directory, and the harness only reads frontmatter. Caught while reasoning about what to codify in the debug-bisect-known-good Phase 1, but the gap applies project-wide to all 35 skills.
- **Suggested action:** Add to `tests/check-structure.sh` a Phase that iterates `skills/*/SKILL.md`, extracts the `name:` field from frontmatter, and asserts it equals `basename "$(dirname "$f")"`. Should be <10 lines of bash. Likely all current skills pass already; the check is a regression guard.
- **Priority:** low (no current regression; defensive)
- **Status:** open

## SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG
- **Source:** feature:verify-codify (finalize-before-ship-order-flip Phase 3 regression slice, 2026-05-13)
- **Target level:** task:plan
- **Type:** test-infra (recon discipline pending)
- **Summary:** 6 verify-codify scenarios SOFT_PASS on haiku but should be tagged `model: sonnet` per the recon discipline documented in CLAUDE.md. F-boundary-codify confirmed: SOFT_PASS on haiku (`/feature-ship` leaks in non-`/feature-ship` scenario), PASS strictly on sonnet (verified 2026-05-13). Other 5 SOFT_PASSes (F14, F15, F16-triage-ambiguous, F16-triage-flaky, F16-triage-regression) fail on output-shape issues (missing TRANSITION line, prose-leak family) — same haiku-noise class. **Extension (2026-05-13 full-sweep):** F13-prefiltered also FAILs on haiku with the "no structured TRANSITION line" pattern — likely same class. Include in the sonnet-tag recon pass.
- **Suggested action:** Apply the documented recon discipline (`see haiku failure → run on sonnet → confirm PASS → tag`). For each of the 6, run on sonnet; for those that PASS strictly, add `model: sonnet` to the scenario in `tests/scenarios/feature.yaml` and a one-line comment citing the haiku flake pattern. Likely all 6 fall into this category given the failure shapes.
- **Priority:** medium (only matters when running the haiku-only partition; current Phase 3 work was unblocked by recon on the most concerning case)
- **Status:** open

## SURFACE-2026-05-10-I20-SCENARIO-MISSING
- **Source:** feature:verify-codify (incident-codify feature, Phase 3, 2026-05-10)
- **Target level:** task:plan
- **Type:** gap (test coverage)
- **Summary:** I20 (codify → investigate back-loop) has no test scenario. The other three codify transitions (I17, I18, I19) and the defer variant (I18-defer) all have scenarios. I20 is the rare "codify-time evidence reveals investigate's root-cause analysis was wrong" case — distinct from I19 ("mitigation didn't fix the bug, try a different fix").
- **Context:** I20 was approved in verify-human as part of the SKILL.md procedure (kept rather than folded into I19) but the plan's Phase 3 scenario list didn't include it. Without a scenario, the I20 path is documented but uncovered — a future regression on I20 emission would slip through the test sweep.
- **Suggested action:** Add an I20 scenario to `tests/scenarios/incident.yaml`. Fixture: `incident-codify-with-reproduce-artifact.md` (or a new fixture). Prompt should describe codify-time evidence that contradicts the prior investigation's root-cause conclusion (e.g., the failing test passes against the mitigated code, but a different failing condition exists that wasn't part of the original investigation). Expected transition: I20 → /incident-investigate.
- **Priority:** low (the path is rare in practice; cost of adding a scenario is small but not urgent)
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

## SURFACE-2026-05-22-DEBUG-EMPIRICAL-TELEMETRY-SKILL
- **Source:** user request (2026-05-22)
- **Target level:** feature:spec (new `debug-*` sidebar skill — non-trivial design surface: trigger gate, instrumentation playbook, cleanup discipline)
- **Type:** new-work / new debug skill in the agent-pulled sidebar category
- **Summary:** Add a `debug-*` sidebar skill (working name: `debug-empirical-telemetry` or `debug-observe-runtime`) that forces a shift from static-analysis debugging ("read the code, reason about what it does, propose a fix") to empirical observation of the running system ("add logging/timing/counters, run, read the telemetry, then decide"). Triggered after N failed static-reasoning attempts on the same bug, or whenever the bug-shape involves runtime values the agent cannot derive from code alone (DB query plans/timing, race conditions, intermittent failures, perf regressions, "this variable is somehow the wrong value at this line").
- **Context:** Agents (this one included) default to static analysis as the first and often only debugging mode — read code, build a mental model, propose a fix. Real debugging frequently requires runtime evidence: insert prints/logs, add timing instrumentation, dump intermediate state, capture a stack at the failure point, run EXPLAIN on a query, sample a hot loop. Without an explicit prompt to switch modes, the agent loops on the static approach even after it has demonstrably failed. A sidebar skill in the `debug-*` family is the right shape: agent-pulled when stalled, runs to completion, returns to caller. Parallels `debug-bisect-known-good` (also a stall-recovery technique) but with a different mechanism (observation vs. bisection).
- **Suggested action:** Author `skills/debug-empirical-telemetry/SKILL.md` following the `debug-*` category convention (mandatory sections: `## Category Context`, `## When to use`, `## When NOT to use`, `## Procedure` with Gate Check, `## Pitfalls`, `## Termination` with `DEBUG-TELEMETRY-*` tokens + `RETURN-TO:` line). Gate suggestions: (a) ≥2–3 failed static-analysis fix attempts on the same bug, AND (b) the bug involves runtime values the agent cannot derive from code (timing, DB stats, env-dependent state, intermittency, perf). Procedure should walk: pick the smallest observable that would discriminate between current hypotheses → instrument (logging, timing, counter, EXPLAIN, etc.) → run → read telemetry → iterate or hand back a concrete cause. Include a cleanup-discipline step (remove or guard the instrumentation before exit) since stray prints in committed code is a real failure mode. Also: discoverability surfaces per the "new skill category needs three surfaces" lesson — caller-skill prose mentions in `feature-build`/`incident-investigate`/`task-act`, "Debug techniques" subsection rows in each relevant orchestrator AGENTS.md, note in `docs/product/transitions.md` sidebar section. Worth speccing rather than planning directly — the trigger gate and the instrumentation playbook both have non-obvious failure modes (over-instrumenting, leaving prints in code, instrumenting too late after the bug has been "guessed-fixed", picking the wrong observable).
- **Priority:** medium — real recurring agent-behavior gap that costs wall-clock time when it bites, but no active bug forcing it now; pick up after WP5 of claude-time-visualize-v2 or interleave when next debugging an empirical-shaped bug.
- **Status:** open
