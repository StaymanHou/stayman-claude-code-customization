# Backlog

## SURFACE-2026-05-26-CLAUDE-TIME-VIZ-V3-PIVOT-UNIFIED-TIME-RANGE
- **Source:** WP11 Phase 2.A verify-human (2026-05-26) — surfaced when user noticed the 3 compare preset sub-tabs (WoW, Today-vs-trailing, MoM) all show the same content because the data layer emits only ONE pre-computed comparison window per CLI invocation.
- **Target level:** product:vision + product:wbs — this is a new product cycle that supersedes WP12 + WP13 of the current claude-time-visualize-v2 cycle.
- **Type:** architectural pivot
- **Summary:** The current claude-time visualize emit model is "one CLI invocation = one window (Day/Week/Month/Custom/Compare-preset)." This creates known UX surprises: preset switches don't refresh content; Day/Week tab switches stale on emit-time window; custom-range pickers can't materialize without re-emit. The v3 pivot: emit a **default 90-day window (MTD + last 2 months)** with all sub-payloads pre-rendered, then let the frontend handle every Day/Week/Month/Compare slice as client-side state swaps over the shared dataset. The `--compare`, `--month`, `--range`, `--week`, `--date` flags collapse into either (a) a unified time-range arg or (b) become deprecated entirely (the frontend handles all sub-views).
- **Trade-offs:** +~500ms emit time (62-day → 90-day SQLite load), +~200-400KB emit size, but unlocks: instant Day/Week/Month/Compare-preset nav, accurate hash-restore for shareable URLs, no more "content didn't change" surprise when clicking preset tabs.
- **Folds in:** WP12 (multi-instance overlap viz) + WP13 (collapsible project rows + away total + pills) — their *visualization concerns* are independent of the emit model and roll into the v3 spec.
- **Folds in (continued):** the Phase 2.A content-not-refreshing limitation (P2A.verify-human.3 PARTIAL) — resolved by the v3 emit model.
- **Suggested action:** Close the current claude-time-visualize-v2 cycle after WP11 ships. Then `/product-wbs` generates the v3 WBS in the next session (2026-05-26 session pauses after the WBS skill emits the cycle scaffold).
- **Priority:** **high** — this is the immediate next cycle; user-confirmed pivot.
- **Status:** RESOLVED 2026-05-26 — v2 cycle closed (WP11 shipped, WP12+WP13 superseded), v3 WBS generated at `docs/product/wbs.md` (10 WPs across 4 phases), v2 wbs.md archived to `docs/product/archive/claude-time-visualize-v2/wbs.md`. The pivot decision is now operationalized as the v3 cycle scope.

## SURFACE-2026-05-26-SESSION-PAUSE-MARKER-LEAK-INTO-DURABLE-DOCS
- **Source:** harness-level repeating issue — first surfaced by Replicator's WP5b-ui-finalize (2026-05-26, learning at `.claude/learnings/2026-05-26-session-pause-marker-leak.md`); confirmed in this repo at WP11 session-resume on 2026-05-26 (`/session-resume` had to excise a stale `## Session Pause — 2026-05-26 09:58` block from `docs/product/wbs.md` before continuing — see Resume context-recovery section of the WIP file)
- **Target level:** task:plan or feature:plan — modifies the `session-pause` and/or `session-resume` skills
- **Type:** harness bug / cleanup-tax
- **Summary:** `session-pause` appends a `## Session Pause — <timestamp>` block to durable product docs (observed on `docs/product/wbs.md` in multiple projects). `session-resume` correctly consumes and deletes `workflow/.session.md` but does NOT sweep these companion blocks. The stale block lingers across subsequent features and risks being committed as part of unrelated work if not noticed. **Now confirmed repeating** across at least two projects (Replicator + this repo) — harness-level, not project-specific.
- **Suggested action:** Prefer option (a) from the learning — stop `session-pause` from writing to durable product docs entirely. The `workflow/.session.md` pointer is sufficient on its own; duplicating a `## Session Pause` block into `wbs.md` provides no resume signal the pointer doesn't already carry. Option (b) (sweep on resume) adds surface area to fix a leak that shouldn't exist. The fix touches `skills/session-pause/SKILL.md` (stop writing) and possibly `skills/session-resume/SKILL.md` (defensive sweep as a transitional safety net).
- **Priority:** **high** — repeating cleanup tax; risks dirty commits in unrelated WIP; harness-level so affects every project using these skills.
- **Status:** open

## SURFACE-2026-05-26-CLAUDE-TIME-VIZ-DAY-VIEW-ROW-DENSITY
- **Source:** user observation during WP11 Phase 2 verify-human (2026-05-26)
- **Target level:** feature:plan or feature:spec — likely Phase 4 (post-WBS) UX work on the `claude-time-visualize-v2` cycle, or its own follow-on WP
- **Type:** new-work / UX
- **Summary:** After ~1 week of tracking with the dashboard, the Day view has accumulated too many project rows to comfortably read on a single screen. The row-per-project default works for the first few days of usage, but at the steady-state of multi-week activity history it becomes a visual scan-bottleneck. Likely intersects with WP13 (collapsible project rows, default-collapsed) — but WP13 was planned around the per-project chevron-expand-for-detail pattern, NOT the higher-level "too many rows" problem the user is observing now.
- **Suggested action:** Revisit at cycle finalization (`/product-finalize`) once the planned WBS is complete. Options to consider:
  - **(a)** Tighten WP13's default — not just collapsed-by-default but also hide rows with no activity in the visible viewport (data-driven filtering, not just chevron-toggle).
  - **(b)** Add a min-activity-threshold filter chip (e.g., "show only projects with >15m active") so the long-tail of one-segment projects falls out of the lane.
  - **(c)** Auto-sort rows by recent activity descending so the top of the list is always the projects the user cares about today.
  - **(d)** Pagination / row-virtualization if (a)/(b)/(c) don't suffice.
- **Priority:** medium — directly user-reported; affects daily usability; not blocking ship of WP11–WP13 (those are independent UI/visualization concerns) but should be addressed before declaring the v2 cycle complete or at the next finalize point.
- **Status:** open — defer until v2 cycle WBS is complete (WP11–WP13 ship first), then evaluate at `/product-finalize` whether to tackle in this cycle or roll into a v3 cycle.

## SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD
- **Source:** feature:spec (claude-time-viz-wp7-month-view, 2026-05-24)
- **Target level:** task:plan (small/simple — doc-only)
- **Type:** documentation hygiene
- **Summary:** `docs/product/wbs.md` is 313 lines, exceeding the global ~300-line size guard that entry-skill product-context loading enforces. `feature-spec` truncated the eager-read to first 100 lines + headings on first read and then needed targeted offset/limit re-reads to locate the WP7 section. The WBS is cycle-scoped and will be archived by `/product-finalize` at cycle close, so this is a transient excess — but for the duration of the cycle, subsequent `feature-spec` / `feature-plan` invocations will hit the same truncation.
- **Suggested action:** Two options: (a) tighten the file at finalize-time of an upcoming WP (e.g., compact already-shipped WP descriptions — keep the SHIPPED line + commit + 1-line outcome, drop the per-task `[x]` lists since those are findable in archive WIPs); (b) raise the size guard to ~500 lines for `wbs.md` specifically (it's an active reference doc, not a one-shot read). Lean: (a) — preserves the size-guard's general signal while addressing the specific cycle.
- **Priority:** low — workaround (offset/limit re-read) is cheap; impact is +1 tool call per future entry-skill invocation, not a blocker.
- **Status:** open

## SURFACE-2026-05-24-CLAUDE-TIME-VIZ-AGGREGATE-METRICS-PANEL
- **Source:** ad-hoc user analysis (2026-05-24) — user asked for weekly usage metrics; computed via `/tmp/usage_analysis_v3.py` against `~/.claude-time/events.sqlite`, generated insights that revealed the dashboard is missing aggregate quantitative summaries.
- **Target level:** feature:plan or feature:spec — multi-metric panel touching `viz_data.py` (new aggregator), `viz/dashboard.jsx` (new panel component), and likely a new view-mode or sidebar slot.
- **Type:** new-work / dashboard feature for `claude-time-visualize` v2+
- **Summary:** The current dashboard renders the segment-model (timeline view) but exposes no aggregate quantitative summaries. Users (incl. the project owner) ask the same shape of question repeatedly: "how much time did I spend / how much agent activity / how much parallelism / where is time going". Add a metrics panel that computes and displays these in wall-clock vs effort-time columns over the current view-mode's window (Day, Week, Month, custom range).
- **Terminology to adopt (canonical, must be consistent across panel + tooltips + docs):**
  - **Wall-clock** = real elapsed time. Overlapping activities collapse via interval merge.
  - **Effort-time** = plain sum of all durations. 2 parallel activities for 1h = 2h.
  - **Parallelism multiplier** = effort-time ÷ wall-clock.
- **Metrics to surface (verified useful via 2026-05-24 analysis):**
  1. **Engaged session duration** (wall-clock + effort-time + multiplier). Engaged = burst-spanning windows with `away`-classified gaps EXCLUDED. Critical: the existing `_build_viz_sessions` treats away gaps as inside-session (sensible for rendering, NOT for time accounting) — the metrics layer must subtract them.
  2. **AI agent activity** (wall-clock + effort-time + multiplier). Sum/merge of UPS→Stop bursts across sessions.
     - Sub-row: **subagent time** (same pair of columns).
  3. **Tool call duration** (wall-clock + effort-time + multiplier). Sum/merge of PreToolUse→PostToolUse pairs.
     - Optional drill: top 5 tools by effort-time with per-tool wall-clock + effort-time + multiplier (revealed WebSearch at 1.80× while Bash at 1.04× — parallelism varies by tool kind).
  4. **Human active duration** (wall-clock only — single human, no parallelism; effort-time column shows = wall-clock for symmetry but is 1.00× by construction).
     - Sub-rows: typing (from `gap_buckets`'s typing_debit_ms), reading (effective_ms where bucket=reading), thinking (effective_ms where bucket=thinking).
  5. **Concurrency stratification** of engaged sessions: wall-clock × {1, 2, 3, 4+} engaged-sessions-open, with effort-time column = wall-clock × concurrency-count. Sum across rows reconciles to engaged-session wall-clock (left col) and engaged-session effort-time (right col).
  6. **Blocking metrics** (wall-clock): human-blocking-agent (sum of reading+thinking effective gaps), agent-blocking-human (burst wall-clock). Reveals waiting asymmetry.
- **Why this matters (insights surfaced in the 2026-05-24 run):**
  - The `session_id`-spanning window in `_build_viz_sessions` INCLUDES away gaps, inflating "session duration" to implausible totals (116h in a 168h week for this user). The metrics panel MUST use the engaged definition or be misleading. This is the load-bearing definitional point.
  - Tool parallelism is the strongest weak signal: 1.12× multiplier vs agent 1.40× tells the user that parallel sessions tend to be in different phases (one thinking, one tooling), not both tooling. This insight is only visible when wall-clock and effort-time are shown side-by-side.
  - Thinking gaps (5h/wk for this user) dominate human active time over typing+reading combined. Surfacing this in the panel makes the "compress the loop" optimization concrete.
  - 4+ session concurrency is essentially zero (46 seconds/week for this user). Surfacing the stratification kills the "I need to optimize for high parallelism" intuition before it becomes a wasted feature.
- **Suggested implementation outline (not a spec — feature:plan should refine):**
  - **New aggregator in `viz_data.py`:** `build_metrics(events, day_start_dt, day_end_dt) -> dict` returning the metric tree. Exposes both wall-clock (merged-interval sum) and effort-time (plain sum) for each metric. Reuses `reclassify.active_bursts`, `reclassify.gap_buckets`, `reclassify.tool_durations_ms` (the latter currently returns effort-time only — extend it or add a sibling that returns intervals so wall-clock can be computed).
  - **Wire into Day/Week/Month/range payloads:** add `metrics` key alongside existing `projects` / `hour_range` / etc. Range-mode aggregation: same shape, computed over the range's events.
  - **New React component:** `MetricsPanel` in `viz/dashboard.jsx`. Two-column table per metric (Wall-clock | Effort-time | ×Multiplier). Top-5-tools subsection. Concurrency stratification as a 4-row sub-table.
  - **Reference helper script:** `/tmp/usage_analysis_v3.py` (one-off, not in repo) computed all these correctly. The metric definitions and interval-merge logic there should be the implementation reference — particularly the away-gap exclusion in the engaged-session interval construction (lines 64-86 of that script).
- **Open design questions for feature:spec:**
  - Where does the panel live? Persistent sidebar? Toggle? New view-mode tab? (User has WP6 "Day" tab, WP7 "Month" tab, WP8 "custom range" — a "Stats" view-mode peer might be natural.)
  - Default window? "Current view's date range" is the obvious default but Day view's single-day window may be too narrow to show meaningful parallelism multipliers — week is the natural unit for these metrics.
  - Tooltips for each metric explaining wall-clock vs effort-time inline? Or a one-time legend at panel header?
  - Per-project breakdown (a "same metrics sliced by cwd alias" view)? User explicitly declined this in the 2026-05-24 ad-hoc but may want it as a drill-down later.
- **Priority:** medium — useful, well-scoped, no existing user blocked. Slot after current WBS cycle's open WPs.
- **Status:** RESOLVED 2026-05-24 by WP10 ship (commit fc4fe2a). Bundled with WP10 at feature-spec (the headline-card + metrics-panel design covered both work items). Shipped: HeadlineCard above timeline (3 numbers + chevron toggle + date-range indicator), MetricsPanel (6 sections: engaged_session, ai_agent, tool_call, human, concurrency, blocking) with wall-clock/effort-time/×multiplier columns, top-5 tools sub-table, concurrency stratification k=1/2/3/4+, engaged-session definition excludes away-gaps (metrics-layer only), trailing-7-day window view-mode-independent. CHANGELOG entry at finalize. Per-project breakdown out-of-scope per Q7 — defer to follow-up.

## SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG
- **Source:** feature:verify-human (claude-time-viz-day-multi-day-window WP5b Phase 1, 2026-05-23)
- **Target level:** task:plan (small/simple — one-line resolver split or doc-clarify)
- **Type:** latent CLI-precedence quirk (pre-existing, not WP5b-introduced)
- **Summary:** In `claude-time` main(), `--db <path>` sets `claude_time_dir = db_path.parent`, which means `load_config(claude_time_dir)` reads `config.json` from the DB's parent directory — silently overriding `$CLAUDE_TIME_DIR` for the config lookup too. Result: `CLAUDE_TIME_DIR=/tmp/x --db ~/.claude-time/events.sqlite` reads config from `~/.claude-time/config.json`, NOT from `/tmp/x/config.json`. Most users won't combine these flags so impact is near-zero, but the precedence is non-obvious and silently wrong if a contributor tries to test config behavior with a borrowed DB.
- **Context:** Surfaced during Phase 1 verify-human P1.verify-human.4 — initial attempt to test custom config used `CLAUDE_TIME_DIR=$tmp_dir --db ~/.claude-time/events.sqlite` (because borrowing the user's real DB into a sandbox tmpdir hit a macOS sqlite3 RO open failure). The custom config was silently ignored. Retest by editing `~/.claude-time/config.json` in place confirmed the wiring is correct; the resolver was just looking in the wrong place.
- **Suggested action:** Either (a) split the resolver: `--db` overrides only `db_path`, `CLAUDE_TIME_DIR` env still resolves `claude_time_dir` independently. Or (b) document the current behavior in `--db`'s help-string ("also overrides config-dir lookup to db's parent directory"). Lean: (a) — silent overrides on independent flags violate least-surprise.
- **Priority:** low — pre-existing behavior, no active impact on shipped functionality; hits only when a contributor combines `--db` with a custom `CLAUDE_TIME_DIR`.
- **Status:** open

## SURFACE-2026-05-22-LEARNING-VERIFY-SELF-SUBAGENT-JIT-FALSE-FAIL
- **Source:** session:reflect → session:store-learning (claude-time-visualize-v2 WP5 Phase 3 verify-self, 2026-05-22)
- **Target level:** workflow-system source repo (`my-claude-code-customization`) — port to `skills/feature-verify-self/SKILL.md` severity-taxonomy section, OR add as a global CLAUDE.md "Verify-self discipline" rule
- **Type:** new-work / workflow-system rule (global)
- **Summary:** When a verify-self subagent reports a single BLOCKING FAIL that conflicts with a coherent set of subagent PASSes that mechanically imply the failing outcome must hold, the orchestrator should re-verify directly with the same MCP tools before back-looping. Subagent regex/snapshot timing on JIT-compiled / async-rendered pages (Babel-standalone in-browser, lazy-mount React, async data fetches before initial render) produces noise that looks like real failures.
- **Context:** Surfaced at WP5 Phase 3 verify-self — Playwright subagent reported 7 PASS + 1 BLOCKING FAIL on `#viewport=720:780` hash-restore; orchestrator re-verified directly with same Playwright MCP and confirmed the outcome actually PASSed (tick_count=12, first_tick="12:00", last_tick="12:55", minimap visible-rect at correct percentages). Subagent's regex `/^\d\d:\d\d$/` apparently ran before Babel JIT-compiled the JSX.
- **Suggested action:** Port the draft to a permanent home in the workflow-system source repo. Specifically: add a "Subagent re-verification heuristic" note to `skills/feature-verify-self/SKILL.md` under the Severity Taxonomy section. Practical text-rule: "If N-1 of N outcomes PASS and the Nth FAIL is mechanically implied by the PASSes, suspect snapshot timing before back-looping; re-run the same Playwright assertions directly from the orchestrator before invoking `/feature-build` with scoped leaves."
- **Reference:** Full learning draft at `.claude/learnings/2026-05-22-verify-self-subagent-jit-false-fail.md` (gitignored — local-only until promoted to source repo by hand).
- **Priority:** medium → **medium-high** as of 2026-05-24: WP7 Phase 2 verify-self was the **third instance** of this pattern recurring. Pre-back-loop verify-self spawned a subagent that reported click-day + nav-arrow BLOCKING fails on the JIT-Babel `--month` page; orchestrator re-verified via React-fiber `reactProps[fiberKey].onClick()` direct invocation, all behaviors actually worked. Same fix as WP5 Phase 3 + WP8 Phase 2 + now WP7 Phase 2. The "after third instance, definitely promote" gate from the 2026-05-22 entry has been met. Promotion to `skills/feature-verify-self/SKILL.md` is now overdue.
- **Status:** RESOLVED 2026-05-26 by task `verify-self-subagent-jit-heuristic` — added new `## Subagent Re-Verification Heuristic` section to `skills/feature-verify-self/SKILL.md` (between Severity Taxonomy and Integration-boundary rule) with rule statement, trigger pattern (3 conjunctive conditions: PASSes in same run, mechanical implication, JIT/lazy/async page), procedure (don't mark FAILED yet, re-run from orchestrator via `browser_wait_for` + React-fiber `reactProps[fiberKey].onClick()` direct invocation, then PASS-branch records re-verification note and proceeds F10b, FAIL-branch back-loops F9b normally), and explicit "what this heuristic is not" guard against override-on-inconvenience. Also added a pointer from §3 (Parse subagent results) to the new section so the gate is read at result-parse time. Structure check 122/0 PASS post-edit.

## SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH
- **Source:** session:reflect → session:store-learning (post-WP5 / post-claude-time-test-containerization, 2026-05-22)
- **Target level:** workflow-system source repo (`my-claude-code-customization`) — port to global CLAUDE.md's "Executing actions with care" section, OR as a new "Workflow branch-off discipline" subsection
- **Type:** new-work / workflow-system rule (global)
- **Summary:** When a workflow branches off mid-execution (pausing one feature to ship a sibling, opening a parallel incident, any cross-feature pause/resume), make a WIP commit on the paused feature's state BEFORE starting the branch-off work. Commits are cheap. A `[wip] pausing for <reason>` commit on `main` is reversible later (`git reset --soft HEAD~1`, amend, `git rebase -i`) and prevents cross-feature dirty-tree contamination. Every additional dirty file is a destructive-operation hazard surface: `git checkout HEAD -- <file>` reverts whole files (not hunks), `git stash` saves all dirty state at once across features, and selective `git add` requires per-commit discipline that's easy to slip on.
- **Context:** Today's session paused WP5 mid-Phase-4 to ship a sibling containerization feature; both features had uncommitted edits to shared files (CLAUDE.md, dashboard.jsx, viz_render.py, test_visualize_cli.sh). At a finalize-time CLAUDE.md edit, `git checkout HEAD -- CLAUDE.md` was used to revert just the new edit but whole-file-reverted both features' changes, destroying ~60 lines of WP5's URL-hash convention section (recovered manually from conversation transcript — but git reflog/fsck couldn't help since the work was never committed).
- **Suggested action:** Port the draft to a permanent home. Add a new bullet under global CLAUDE.md's "Executing actions with care" section: "Commit before branching workflows. When pausing one feature to start another (or any cross-feature pause/resume), make a WIP commit on the paused feature's in-flight state first. Commits are cheap and reversible (`git reset --soft HEAD~1`, amend, or `git rebase -i` to clean up before the next ship)." Rule-of-thumb threshold: if a pause is expected to span more than ~10 minutes or another feature's full lifecycle, commit the in-flight state.
- **Reference:** Full learning draft at `.claude/learnings/2026-05-22-commit-often-at-cross-feature-branch.md` (gitignored — local-only until promoted to source repo by hand).
- **Priority:** medium — the failure mode hit this session (lost work recovered only via transcript); the rule applies to every cross-feature pause/resume going forward.
- **Status:** open

## SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE
- **Source:** feature:verify-self (claude-time-visualize-v2 WP5 Phase 4 P4.2, 2026-05-22)
- **Target level:** task:plan (small/simple — single line in viz_data.py + decision on display-truncation policy)
- **Type:** latent bug / cosmetic
- **Summary:** `tools/claude-time/viz_data.py` line 288 truncates `session_id[:8]` for the emitted `id` field. When two or more sessions share their first 8 characters of session_id (e.g. test fixtures that prefix with a date, or real-world hash collisions), React fires a duplicate-key warning in DayTimeline and the dashboard may render incorrectly (sessions duplicated or omitted, per React's "behavior is unsupported and could change" warning). Real production session_ids are 32-char hex UUIDs that statistically never collide at 8 chars — practical impact for users is near-zero — but the latent issue is real.
- **Context:** Surfaced at WP5 Phase 4 verify-self when the `seed_perf_dataset.py`-generated dataset used session_ids like `perf-2026-05-23-{0,1,2}` (all colliding at the 8-char prefix `perf-202`). React emitted: `Warning: Encountered two children with the same key, 'perf-202'. ... at DayTimeline`. Worked around by changing the seeder to use a globally-unique counter prefix; the fix lives in the *test fixture*, not in viz_data.py. The underlying truncation remains.
- **Suggested action:** Two options to consider when next touching `viz_data.py`:
  - (a) Increase the truncation to `[:12]` or `[:16]` — practical collision probability becomes negligible (1 in trillions for 8 → 1 in quintillions for 12). Cheap; doesn't change display surface much since the truncated form was only used for `id`, not for any visible label.
  - (b) Use the full `session_id` as the React key, but track a separate `display_id` field for any UI surface that wants the short form. Cleaner separation of concerns; one extra field in the data layer.
  - Lean: (a) — minimum-viable fix; matches the existing display-policy intent.
- **Priority:** low — real session_ids don't collide; only synthetic test data triggers it; seeder fix already in place; production users unaffected.
- **Status:** open. **Update 2026-05-23 (WP5b):** Render-side symptom mitigated via `SessionRow key={s.day_iso ? \`${s.day_iso}:${s.id}\` : s.id}` for the multi-day Day view (resolves the cross-day union case where the same session_id appears in N≥2 days). Root cause — 8-char `session_id[:8]` truncation in `viz_data.py:288` — is untouched and can still bite (a) Week view aggregation if it ever cross-day-unions, (b) Month view (WP7) similarly, (c) any tests using prefix-colliding synthetic IDs. Don't close this item until viz_data.py is also fixed.

## SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL-DOESNT-REACH-REACT
- **Source:** feature:build (claude-time-visualize-v2 WP5 Phase 4 P4.2, 2026-05-22)
- **Target level:** task:plan (small/simple — test-infra workaround)
- **Type:** test-infra / gap
- **Summary:** `test_visualize_interactive.js` cannot reliably exercise wheel-zoom behavior because synthetic `WheelEvent` dispatched via `page.evaluate(... el.dispatchEvent(new WheelEvent(...)))` does NOT reach React's `onWheel` handler. React's synthetic event system intercepts native browser events but the JS-dispatched ones don't always cross that boundary. The P4.2 test SKIPs the wheel assertion with a documented comment; keyboard `+` covers the same `scheduleSet` cursor-anchor math path so behavioral coverage is preserved overall, but wheel-specific behavior (ctrlKey detection, trackpad pinch convention via wheel+ctrlKey) is not directly asserted.
- **Context:** Surfaced during Phase 4 build (2026-05-22). Plan didn't anticipate this — assumed Playwright's `page.mouse.wheel()` API would route through React. It does not, on the dispatched-WheelEvent path used in the test.
- **Suggested action:** Two options to evaluate when next touching `test_visualize_interactive.js`:
  - (a) Use Playwright's `page.mouse.wheel(deltaX, deltaY)` API instead of synthesized DOM-event dispatch. Modifier keys (ctrlKey for zoom) can be set via `page.keyboard.down('Control'); page.mouse.wheel(...); page.keyboard.up('Control')`. This routes through the browser's native event path which React's synthetic event system DOES observe.
  - (b) Add a small test-only debug hook in `useTimelineGestures` that exposes `__simulateWheel({deltaY, ctrlKey, clientX, clientY})` on `window`. The test calls it directly; production path no-ops. Avoids the synthetic-event uncertainty entirely.
  - Lean: (a) — uses the existing Playwright API surface, no production-code debug hook needed.
- **Priority:** low — keyboard-zoom path covers the same math; this is hardening for completeness.
- **Status:** open

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
- **Status:** RESOLVED 2026-05-23 by WP5b ship (commit 02d6237). Day view now loads ±21 days of context (defaults `prior=14, after=7`); CLI flags + config keys + ISO-day-aware labels + extended `pickTickInterval` scale set + day-offset segment math all in place. CHANGELOG entry at finalize.

## SURFACE-2026-05-18-SETTINGS-FIXTURE-DRIFT-CLAUDE-TIME
- **Source:** feature:verify-codify (claude-time-report-by-project Phase 1, 2026-05-18)
- **Target level:** task:plan (small/simple — fixture update or INTENTIONAL_DIFFS allow-list)
- **Type:** test-infra / gap (test fixture out of sync with documented install end-state)
- **Summary:** `tests/check-structure.sh` Phase 7 (settings-drift check) fails with 9 drift lines — all of them claude-time hook entries (UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, SessionStart, SessionEnd, SubagentStart, SubagentStop) plus the `CLAUDE_TIME_TRACKING` env var. These are present in the user's live `~/.claude/settings.json` because the user followed the install instructions in `tools/claude-time/README.md` steps 2 and 3 (the shipped previous feature documents this as the required install state). The fixture `tests/fixtures/settings.json` doesn't know about them.
- **Context:** Surfaced during Phase 1 verify-codify of the `--by` grouping feature. The drift is pre-existing relative to that feature — none of the `--by` feature's changes touched fixtures, install.sh, or settings. It's the previous claude-time feature's install state being correctly applied to the user's machine.
- **Suggested action:** Choose one of (a) extend `tests/fixtures/settings.json` to include the claude-time hooks block + env (treating them as documented standard install state for this repo), or (b) add the relevant keys to `INTENTIONAL_DIFFS` in `tests/check-structure.sh` (treating them as per-machine opt-in state that varies legitimately). (a) is preferable if the repo wants the structure check to assert "claude-time is wired up correctly for any contributor"; (b) is preferable if opting in is intentionally per-machine. Probably (b) since the README explicitly frames the install as opt-in.
- **Priority:** medium — structural check currently fails on a clean run, which obscures real regressions.
- **Status:** RESOLVED 2026-05-24 via option (a): added the 8 claude-time hook entries (UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, SessionStart, SessionEnd, SubagentStart, SubagentStop, each invoking `~/.claude/hooks/claude-time-hook.pl`) + `env.CLAUDE_TIME_TRACKING: "1"` + root `fileCheckpointingEnabled: false` to `tests/fixtures/settings.json`. `tests/check-structure.sh` now reports 122/0 on a clean working tree.

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
