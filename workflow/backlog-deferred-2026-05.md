# Backlog — Deferred (2026-05)

Items buried from `workflow/backlog.md` on 2026-06-07 by user decision. Still pending — not resolved. May be revisited later. Each item is preserved in full below; the parent `backlog.md` keeps only a one-line pointer to this file.

---

## SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER
- **Source:** v3 WP4 Phase 1 build P1.4 (2026-05-29) — deleted six "v2 helper functions" by line-range (502-777). The range accidentally included `_parse_window_arg`, a WP3 helper sandwiched between `_parse_range_flag` (line 583-697, v2) and `_compare_window_bounds` (line 699-740, v2). The spatial proximity misled the scope check; the named-function callers grep ran against the six **named** v2 helpers but not against the **range** being deleted. Caught at first smoke test (`--window 30d` → `NameError: _parse_window_arg`). Recovered from git HEAD; reinserted before `_cmd_visualize`.
- **Target level:** documentation / convention (CLAUDE.md)
- **Type:** bulk-delete safety pattern
- **Summary:** When deleting a "block of related functions" by line-range, the function-by-function caller grep alone is insufficient — the range may include unrelated functions sandwiched between the named ones. Before bulk-deleting a line-range, list EVERY function-def inside the range (e.g. `grep -n "^def " <file> | awk '$1 > start && $1 < end'`) and confirm each by name belongs to the deletion set. The function-name-driven scope check at planning time catches this if it's done; the line-range execution at build time can lose that fidelity if the deletions get batched.
- **Proposed fix:** Add to project CLAUDE.md a one-line bulk-delete discipline: "Before deleting a line-range that spans multiple functions, enumerate every `def` inside the range and confirm each by name. Spatial proximity is not the same as semantic membership." Alternatively, prefer per-function Edit deletions for clusters smaller than ~10 functions — slower but safer.
- **Priority:** low-medium — caught immediately by smoke test (no production impact); but the same pattern would bite harder on a code path with weaker test coverage.
- **Status:** pending (deferred)

## SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING
- **Source:** v3 WP3 Phase 2 verify-self (2026-05-29) — alias-key audit at build P2.4 used `grep CT_DATA\.` to enumerate what the v2 frontend reads off `window.CT_DATA`. The grep caught direct property access but missed `const {today, week} = window.CT_DATA` destructuring at `viz_render.py::_interactive_dashboard:69` + `viz/dashboard.jsx:3198`. Result: `week` alias key was not populated; Dashboard crashed on mount with `TypeError: Cannot read properties of undefined (reading 'projects')`. 3 BLOCKING fails at first browser-load attempt; fixed in-place during verify-self.
- **Target level:** documentation / convention
- **Type:** audit-method gap
- **Summary:** When auditing what a downstream consumer reads off a producer-shape object, `grep <obj>\.` only catches direct property access. Destructuring patterns (`const {a, b} = <obj>`) and rest spreads (`const {...rest} = <obj>`) require their own grep. For JS/JSX bundles in particular: `grep "= window\.CT_DATA"` finds the destructuring assignments; combine with the direct-access grep for full coverage.
- **Why it matters:** The whole point of the alias-key block in WP3 Phase 2 was to preserve the v2-frontend coexistence contract during the WP5–WP9 transition. An incomplete audit ships a broken dashboard.
- **Proposed fix:** Add a one-line convention to project CLAUDE.md under the existing "Claude-time visualize URL-hash state" section (or a new "consumer-shape audit" subsection): "When auditing downstream consumers of a shape, grep BOTH `<obj>\.` (direct access) AND `= <obj>` (destructuring/rebinding). Either pattern alone misses half the contract." Alternatively codify as a structure-check pin if cheap (probably not — too project-specific).
- **Priority:** medium — affects future WP9 verify-codify (where the alias keys get removed and the same audit logic applies in reverse) and any future cycle that bridges v2/v3-shape coexistence.
- **Status:** pending (deferred)

## SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS
- **Source:** v3 WP3 Phase 2 verify-codify (2026-05-29) — Test Triage gate caught 25 FAILs in `test_visualize_cli.sh` after Phase 2's `_cmd_visualize` integration silently no-op'd the v2 flags. 24 of those failures were obsolete v2-flag test scenarios; 1 was a code regression in error-message wording. Triage classified them HIGH-confidence obsolete + HIGH-confidence regression, but the surprise should not have happened — WP3's plan never surfaced "Phase 2 will obsolete ~24 v2-flag test scenarios" as a Phase 2 deliverable. The project's CLAUDE.md "Plan-level downstream contract impacts pass" rule was missed in planning.
- **Target level:** documentation / convention reinforcement
- **Type:** planning gap
- **Summary:** The "downstream contract impacts" pass at plan-time (CLAUDE.md convention introduced 2026-05-10 after a similar incident-codify scenario miss) is not being applied consistently. WP3's plan deferred test-codification to Phase 3 without checking what existing test contracts the Phase 2 architectural change would invalidate. The Test Triage gate at verify-codify caught the miss, but planning should have surfaced it earlier — and the cleanup work (~250 lines, 33 scenarios deleted, 6 source-HTML rerouted) effectively became a third deliverable mid-Phase-2-verify-codify.
- **Why it matters:** Plan-level misses on contract impacts compound: they widen scope mid-flight, blur phase boundaries, and stress the Test Triage safety net. The CLAUDE.md convention exists precisely to prevent this; not following it consistently weakens the convention itself.
- **Proposed fix:** Add a `feature-plan` SKILL.md sub-step under §4 ("Create Phased Plan"): "Before sealing each phase's impl tasks, do a downstream-contract-impacts grep: for each public-surface change in the phase (CLI flag, endpoint signature, payload shape, config key, file path), grep the codebase + test suite for existing assertions or consumers. List the affected artifacts as phase deliverables. The Test Triage gate at verify-codify is a safety net, not a planning substitute." Could also be enforced structurally via a `tests/check-structure.sh` pin asserting that feature-plan SKILL.md contains the downstream-contract-impacts step (similar to the Step 0 product-context check at Phase 3a).
- **Priority:** medium — the convention exists in CLAUDE.md but has now been missed FIVE TIMES (incident-codify 2026-05-10, WP3 Phase 2 2026-05-29, WP4 Phase 3 2026-05-29, WP5 2026-06-03, WP11 P2 2026-06-06). Worth codifying into `feature-plan` SKILL.md to lift it from "doc users should read" to "step the skill executes."
- **Updates:**
  - 2026-06-06 (WP11 P2 codify): 5th observed instance. Subcase: **array-length-add** — adding a 4th `away` tile to HeadlineCard's `tiles` array broke `test_visualize_interactive.js`'s `tileIds.length === 3` assertion (`WP10-P2 behavioral: HeadlineCard renders w/ 3 tiles`). The CLAUDE.md bullet already covers literal-payload-object key-adds (the 4th instance subcase from WP5 P1.2); this is the array-length variant of the same family. Plan-time grep needs to include `.length === N` and `.length >= N` assertions against arrays the phase is extending — not just key-name and literal-object-string greps. The triage caught it cleanly (high-confidence obsolete-test auto-fix), but the pattern is firmly established and the convention should mention array-length assertions explicitly.
- **Status:** pending (deferred)

## SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD
- **Source:** feature:spec (claude-time-viz-wp7-month-view, 2026-05-24)
- **Target level:** task:plan (small/simple — doc-only)
- **Type:** documentation hygiene
- **Summary:** `docs/product/wbs.md` is 313 lines, exceeding the global ~300-line size guard that entry-skill product-context loading enforces. `feature-spec` truncated the eager-read to first 100 lines + headings on first read and then needed targeted offset/limit re-reads to locate the WP7 section. The WBS is cycle-scoped and will be archived by `/product-finalize` at cycle close, so this is a transient excess — but for the duration of the cycle, subsequent `feature-spec` / `feature-plan` invocations will hit the same truncation.
- **Suggested action:** Two options: (a) tighten the file at finalize-time of an upcoming WP (e.g., compact already-shipped WP descriptions — keep the SHIPPED line + commit + 1-line outcome, drop the per-task `[x]` lists since those are findable in archive WIPs); (b) raise the size guard to ~500 lines for `wbs.md` specifically (it's an active reference doc, not a one-shot read). Lean: (a) — preserves the size-guard's general signal while addressing the specific cycle.
- **Priority:** low — workaround (offset/limit re-read) is cheap; impact is +1 tool call per future entry-skill invocation, not a blocker.
- **Status:** open (deferred)

## SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG
- **Source:** feature:verify-human (claude-time-viz-day-multi-day-window WP5b Phase 1, 2026-05-23)
- **Target level:** task:plan (small/simple — one-line resolver split or doc-clarify)
- **Type:** latent CLI-precedence quirk (pre-existing, not WP5b-introduced)
- **Summary:** In `claude-time` main(), `--db <path>` sets `claude_time_dir = db_path.parent`, which means `load_config(claude_time_dir)` reads `config.json` from the DB's parent directory — silently overriding `$CLAUDE_TIME_DIR` for the config lookup too. Result: `CLAUDE_TIME_DIR=/tmp/x --db ~/.claude-time/events.sqlite` reads config from `~/.claude-time/config.json`, NOT from `/tmp/x/config.json`. Most users won't combine these flags so impact is near-zero, but the precedence is non-obvious and silently wrong if a contributor tries to test config behavior with a borrowed DB.
- **Context:** Surfaced during Phase 1 verify-human P1.verify-human.4 — initial attempt to test custom config used `CLAUDE_TIME_DIR=$tmp_dir --db ~/.claude-time/events.sqlite` (because borrowing the user's real DB into a sandbox tmpdir hit a macOS sqlite3 RO open failure). The custom config was silently ignored. Retest by editing `~/.claude-time/config.json` in place confirmed the wiring is correct; the resolver was just looking in the wrong place.
- **Suggested action:** Either (a) split the resolver: `--db` overrides only `db_path`, `CLAUDE_TIME_DIR` env still resolves `claude_time_dir` independently. Or (b) document the current behavior in `--db`'s help-string ("also overrides config-dir lookup to db's parent directory"). Lean: (a) — silent overrides on independent flags violate least-surprise.
- **Priority:** low — pre-existing behavior, no active impact on shipped functionality; hits only when a contributor combines `--db` with a custom `CLAUDE_TIME_DIR`.
- **Status:** open (deferred)

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
- **Status:** open (deferred). **Update 2026-05-23 (WP5b):** Render-side symptom mitigated via `SessionRow key={s.day_iso ? \`${s.day_iso}:${s.id}\` : s.id}` for the multi-day Day view (resolves the cross-day union case where the same session_id appears in N≥2 days). Root cause — 8-char `session_id[:8]` truncation in `viz_data.py:288` — is untouched and can still bite (a) Week view aggregation if it ever cross-day-unions, (b) Month view (WP7) similarly, (c) any tests using prefix-colliding synthetic IDs. Don't close this item until viz_data.py is also fixed.

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
- **Status:** open (deferred)

## SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT
- **Source:** feature:verify-codify (debug-skills-category-and-bisect-known-good Phase 1, 2026-05-13)
- **Target level:** task:plan (small/simple — single bash loop added to `tests/check-structure.sh`)
- **Type:** gap (test coverage)
- **Summary:** No structural check asserts that each `skills/<name>/SKILL.md`'s frontmatter `name:` field matches its parent directory name. If they diverge (e.g. someone renames the dir without updating frontmatter), the skill may stop being invokable via its slash command and the discovery is silent — `install.sh` only checks the directory, and the harness only reads frontmatter. Caught while reasoning about what to codify in the debug-bisect-known-good Phase 1, but the gap applies project-wide to all 35 skills.
- **Suggested action:** Add to `tests/check-structure.sh` a Phase that iterates `skills/*/SKILL.md`, extracts the `name:` field from frontmatter, and asserts it equals `basename "$(dirname "$f")"`. Should be <10 lines of bash. Likely all current skills pass already; the check is a regression guard.
- **Priority:** low (no current regression; defensive)
- **Status:** open (deferred)
