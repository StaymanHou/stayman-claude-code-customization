# Backlog

## SURFACE-2026-05-18-CLAUDE-TIME-TOTAL-COL-ROW
- **Source:** feature:verify-human (claude-time-report-by-project Phase 2, 2026-05-18)
- **Target level:** feature:plan (small/simple — adds derived columns + reuses existing TOTAL row pattern)
- **Type:** new-work / ergonomics
- **Summary:** Add a total column (sum of tool + active + reading + thinking + away per row) to `claude-time report --by <dim>` grouped output. The TOTAL row already exists at the bottom; this is the orthogonal complement — per-row total at the right. Together they give the user an instant "where's the time" cross-pivot without mental math.
- **Context:** Surfaced during Phase 2 verify-human acceptance. User accepted the project_names + auto-alias work and immediately requested this as the **next feature** ("That should be the next feature we work on"). High signal: real ergonomic gap observed while actually using the grouped report on real data.
- **Suggested action:** Extend `render_grouped` in `tools/claude-time/claude-time`: add a `TOTAL` column header to the column row in the grouped table (rightmost), compute per-row totals as `tool_ms + active_ms + reading_ms + thinking_ms + away_ms`, render in the same fmt_ms format as other cells. The existing bottom TOTAL row gets a corresponding rightmost cell = sum of all per-row totals (which should equal the sum-down of any single column, useful as a sanity check). One impl task; one new observable outcome; verify-codify gets a new assertion that the per-row total = sum of the other 5 cells.
- **Priority:** high — user explicitly designated this as the next feature.
- **Status:** open

## SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME
- **Source:** feature:verify-codify (claude-time-report-by-project Phase 1, 2026-05-18)
- **Target level:** task:plan (small/simple — fixture update or INTENTIONAL_DIFFS allow-list)
- **Type:** test-infra / gap (test fixture out of sync with documented install end-state)
- **Summary:** `tests/check-structure.sh` Phase 7 (settings-drift check) fails with 9 drift lines — all of them claude-time hook entries (UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, SessionStart, SessionEnd, SubagentStart, SubagentStop) plus the `CLAUDE_TIME_TRACKING` env var. These are present in the user's live `~/.claude/settings.json` because the user followed the install instructions in `tools/claude-time/README.md` steps 2 and 3 (the shipped previous feature documents this as the required install state). The fixture `tests/fixtures/settings.json` doesn't know about them.
- **Context:** Surfaced during Phase 1 verify-codify of the `--by` grouping feature. The drift is pre-existing relative to that feature — none of the `--by` feature's changes touched fixtures, install.sh, or settings. It's the previous claude-time feature's install state being correctly applied to the user's machine.
- **Suggested action:** Choose one of (a) extend `tests/fixtures/settings.json` to include the claude-time hooks block + env (treating them as documented standard install state for this repo), or (b) add the relevant keys to `INTENTIONAL_DIFFS` in `tests/check-structure.sh` (treating them as per-machine opt-in state that varies legitimately). (a) is preferable if the repo wants the structure check to assert "claude-time is wired up correctly for any contributor"; (b) is preferable if opting in is intentionally per-machine. Probably (b) since the README explicitly frames the install as opt-in.
- **Priority:** medium — structural check currently fails on a clean run, which obscures real regressions.
- **Status:** open

## SURFACE-2026-05-18-CLAUDE-TIME-REPORT-BY-PROJECT
- **Source:** feature:verify-human (claude-code-time-tracking Phase 3, 2026-05-18)
- **Target level:** feature:spec (v2 enhancement)
- **Type:** new-work
- **Summary:** `--cwd` works as a *filter* in v1 (verified in Phase 3 verify-self outcome 4); add a *grouping dimension* (`--by cwd` or `report projects`) that shows one row per distinct cwd with tool / active / gap-bucket totals side-by-side. The data is already captured (`cwd` is a column on every event row in the existing schema), so this is CLI-side only — no schema migration.
- **Context:** User asked during Phase 3 verify-human review whether the system supports per-project breakdown. Today the answer is "filter to one project at a time"; what the user actually wants is "show me all projects side by side." The spec listed `--cwd` only as a filter (acceptance #5), not as a grouping dimension. Hits the "self-awareness of where time goes" use case from the original problem statement more directly than per-session view.
- **Suggested action:** Add a `--by <dim>` flag to `claude-time report` where `<dim>` is one of `cwd | session | day`. Render a grouped table: each row is one value of the chosen dimension, columns are the existing totals (tool time, active time, gap buckets). Optional follow-up: `~/.claude-time/config.json` `project_names` map for human-readable `cwd → name` aliasing (e.g., `{"my-thing": ["/Users/me/repo", "/Users/me/repo-worktree"]}`) so a logical project that lives in two cwds (worktree + main) shows as one row.
- **Priority:** medium — real user request observed in real verify-human flow; not blocking v1 ship; the captured data already supports it so v2 cost is bounded.
- **Status:** open

## SURFACE-2026-05-18-CLAUDE-TIME-HOOK-PERF-BUDGET-INFEASIBLE
- **Source:** feature:build (claude-code-time-tracking Phase 1, P1.3, 2026-05-18)
- **Target level:** feature:plan (back-loop F23 — already taken in this session)
- **Type:** spec/plan conflict surfaced by empirical measurement
- **Summary:** Spec acceptance #10 ("Hook script overhead < 50ms total across 10 tool calls = < 5ms per hook average") plus the locked tech contract ("5ms typical, 20ms p99 when enabled") are unachievable on stock macOS with the plan-time language choice (bash + jq + sqlite3 + python3-for-ms-timestamp). Measured ~110ms per hook call (5-call mean, single Stop event, warm DB). Breakdown: bash ~3ms + 3× jq ~30ms + python3 for ms timestamp ~80ms + sqlite3 ~5ms. macOS BSD `date` lacks `%3N`; macOS default bash 3.2.57 lacks `EPOCHREALTIME` (added in bash 5). Even with perl substituted for python3 (~18ms cold), the 3× jq floor keeps total ~35-40ms.
- **Context:** Surfaced during the very first Phase 1 build attempt (acceptance #10 specifically called out measurement as a plan deliverable — measuring at build time caught the conflict early, exactly as intended).
- **Suggested action:** During the F23 plan revision: pick ONE of (a) consolidate to single Python script (one cold start ~80ms, then no jq), (b) consolidate to single Perl script (one cold start ~18ms, then no jq), (c) keep bash but use one jq pass extracting all fields (saves ~20ms), (d) relax the spec's 5ms budget to a measured-realistic number. Combine with whichever language gives the best Linux performance too (Linux GNU date supports `%3N` so bash stays viable there).
- **Priority:** high (blocked Phase 1 completion)
- **Status:** resolved-via-plan-revision (2026-05-18). Plan pivoted to Perl single-process hook (~10ms/call measured); spec acceptance #10 + performance contract amended in workflow/wip/claude-code-time-tracking.md. CHANGELOG entry will be emitted at feature-finalize per the convention (resolved during feature-active work — not feature-shipped yet).

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

## SURFACE-2026-05-10-CLAUDE-CODE-TIME-TRACKING  (RESOLVED 2026-05-18)
- **Source:** user-initiated (exploration idea, 2026-05-10 — logged during incident-codify feature work)
- **Target level:** feature:spec (likely complex — multi-component, persistent storage, cross-session)
- **Type:** new-work
- **Summary:** Automatically log and time Claude Code usage to a centralized database. Track time distribution across agent states (reasoning, waiting on commands like tests/npm install, idle awaiting human input, offline) AND human-side time (writing prompts, reading output, reasoning, context-switching between multiple CC instances, away). Goal: usage analytics + self-awareness of where time actually goes.
- **Context:** Useful for cost/usage analysis, identifying friction points (e.g., am I spending more time waiting on tests than coding?), and quantifying value across multiple parallel CC sessions. The "real offline vs idle" distinction is non-trivial — see "Suggested action" §3.
- **Suggested action — exploration outline (not a plan):**
  1. **Storage:** centralized DB — local SQLite is the cheap default; consider Postgres if cross-machine aggregation is wanted later. Schema sketch: `sessions(id, project, started_at, ended_at)`, `events(session_id, ts, kind, duration_ms, meta)`. Kinds: `agent_reasoning`, `tool_running`, `idle_awaiting_human`, `human_typing`, `human_reading`, `away`, `session_paused`, `session_ended`.
  2. **Agent-side instrumentation:** hooks are the natural surface. `PreToolUse` / `PostToolUse` for command timing; `Notification` for idle-awaiting-human start; `Stop` for turn end. Reasoning time = wall-clock between user submit and first assistant tool/text, minus tool wait time. Storage write should be async/append-only to avoid blocking the harness.
  3. **The offline-vs-idle problem:** core ambiguity. When the harness is open but the user has stepped away, the agent and harness can't easily tell the difference between "user is reading slowly" and "user has gone to bed." Options to explore:
     - **OS-level signals:** macOS idle time (`ioreg -c IOHIDSystem`), lock-screen events, sleep/wake events from `pmset -g log`. Treat OS sleep as authoritative "offline."
     - **Heuristic timeout:** anything > N minutes (e.g., 15) without keystroke → reclassify as "away" retroactively. Cheap, model-agnostic, but always lossy at the boundary.
     - **Explicit ritual:** opt-in `/away` and `/back` slash commands. Loses the "going to bed without thinking" goal but is unambiguous.
     - **Hybrid:** OS sleep = offline (authoritative); else timeout heuristic for away; manual `/away` overrides both. Recommend this as the starting point.
     - **Key constraint user stated:** "going to bed with or without Claude Code sessions terminated should mean the same thing" → the system must not punish leaving sessions open overnight. The hybrid above satisfies this — OS sleep retroactively reclassifies any pending "idle" time as "offline."
  4. **Human-side time tracking:** harder. The harness can detect typing-vs-not via the input box state (if exposed via hooks/APIs — unclear). Reading-vs-reasoning is essentially unobservable without eye tracking; best approximation is "time between last assistant output and next user submit, capped by idle threshold." Context-switching between multiple CC instances → would need either a shared parent process tracker or each instance writing to the same DB with a session-foreground signal.
  5. **Multi-instance handling:** if logging into one DB from multiple sessions concurrently, schema needs a session-foreground/background bit. macOS has frontmost-app APIs but not "frontmost terminal tab" without deeper integration.
  6. **Privacy/storage hygiene:** decide whether prompt content is stored or only timing metadata. Recommend timing-only to start — easier to reason about and avoids accidentally piping sensitive prompts into a long-lived DB.
- **Known unknowns to surface in spec:**
  - Whether Claude Code's hook system exposes input-box-focus / typing events (PreToolUse and Stop are confirmed; the rest may not exist)
  - Whether session correlation across `/clear`, `/session-pause`, `/session-resume` is feasible with current hook payloads
  - Whether the centralized DB should be queryable in-session (slash command `/usage-today`) or only via external dashboard
- **Priority:** medium (bumped from low 2026-05-17 — user re-evaluation during backlog grooming)
- **Status:** RESOLVED 2026-05-18 — shipped as `tools/claude-time/` on branch `feature/claude-code-time-tracking-phase-1`. 4 phases delivered: opt-in Perl hook + 10-event logging + Python reclassifier CLI + perf/multi-instance verification. v1 scope per spec; v2 enhancement (per-project grouping) logged as SURFACE-2026-05-18-CLAUDE-TIME-REPORT-BY-PROJECT. Two of the six "Suggested action" sub-items in the original SURFACE became spec acceptance criteria (storage in §1, agent-side instrumentation in §2); the offline-vs-idle hybrid (§3) was deferred to v2 (spec's "Out of Scope" → OS-level idle signals).

## SURFACE-2026-05-08-REPRODUCE-AS-REDIRECT-FROM-BUILD
- **Source:** feature:build (reproduce-step feature, 2026-05-08) — Phase 4 backlog spinout
- **Target level:** feature:spec
- **Type:** workflow-enhancement
- **Summary:** When `feature-build` hits an "I cannot tell if my fix actually worked because I never confirmed the bug" moment, allow REDIRECT into `feature-reproduce` (similar to F22 redirect to research). Currently reproduce is only an entry transition (F31) and post-spec/plan suggestion — there's no path FROM build INTO reproduce.
- **Context:** Useful for bug-fix features that didn't go through reproduce upfront but discover during build that they need a failing-test anchor. Without this transition, the agent has to either (a) continue without confirmation, or (b) abandon and restart at reproduce. A redirect would preserve build state and let reproduce run, then resume.
- **Suggested action:** Add Fnew → build → reproduce REDIRECT transition. Update feature-build SKILL.md to surface this as a valid exit when "could not confirm fix worked" condition holds. Update reproduce SKILL.md to recognize REDIRECT entry and hand back to build.
- **Priority:** low (deferred — wait until we observe the need in practice)
- **Status:** open
