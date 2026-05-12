# Backlog

## SURFACE-2026-05-12-STORE-LEARNING-WRONG-ITEM-SELECTED
- **Source:** user-observed (live use of `session-store-learning` after the global-scope/learnings split, 2026-05-12, ops-data-hub WP9.5 reflection)
- **Target level:** task:plan (likely small/simple — SKILL prose tightening + selection discipline)
- **Type:** bug (item-selection drift — user asks for X, skill operates on Y)
- **Summary:** During reflection of ops-data-hub WP9.5, `/session-reflect` listed 4 learnings: #1 Telegram MarkdownV1 (project), #2 waiting_human pause-aware timeouts (project), #3 verify-human catches external-system defects (global), #4 mock + structural-shape testing pattern (global). User asked: "store learning #2 only" (project-scope, waiting_human). `/session-store-learning` instead drafted **#4** (mock + structural-shape, global-scope) to `.claude/learnings/2026-05-12-mock-plus-structural-shape-test.md`. The classification reasoning was sound *for the item it analyzed* — it just analyzed the wrong item.
- **Plausible mechanism:** the reflection's "Recommendations for /session-store-learning" sub-section listed *only* the two global-scope learnings (#3 and #4) as candidates for store-learning, with the project ones marked "lower priority — embedded in codebase." The store-learning skill likely re-indexed within that recommendation block (so its "#2" = the second item in the global-only candidate list = #4 of the full list). User intent referenced the full reflection's numbering.
- **Suggested action (investigate, do not commit):**
  1. **Reproduce.** Set up a fixture reflection output with 4 learnings numbered 1–4, where the "Recommendations" sub-section at the end lists only a subset (e.g. items 3 and 4). Invoke `/session-store-learning` with an explicit number: "store learning #2 only" (where #2 in the full list is *not* in the Recommendations subset). Verify which learning the skill picks.
  2. **Tighten selection discipline in the SKILL.** Step §1 (Analyze) should: (a) explicitly state that "#N" refers to the full reflection's enumeration, not any sub-list like "Recommendations"; (b) if a "Recommendations" sub-section exists, ignore it for selection purposes — it's reflection's advice, not a renumbering. Alternative: require the user to paste the learning text, not just a number, when invoking outside an interactive selection menu.
- **Priority:** medium-high — silently subverts user intent (user asks for X, gets Y) without any prompt for confirmation. The skill's "4. Confirm" step at the end *did* show the drafted file path, so the user could in theory have caught it — but the bug primary is at item selection, which happens silently.
- **Status:** open

## SURFACE-2026-05-11-PER-PHASE-CHAINING-SCENARIO-COVERAGE
- **Source:** incident:codify (incident-orchestrated-spurious-pauses, 2026-05-11)
- **Target level:** task:plan
- **Type:** test-coverage (adjacent gap)
- **Summary:** S21 covers `build → verify-auto` chaining under Mode 2. The other per-phase chain points (`verify-auto → verify-self`, `verify-self → verify-human` PAUSE, `verify-human → verify-codify`, `verify-codify → ship`) lack equivalent scenarios. S7/S8/S12 cover *some* of these in lenient form but with weaker assertions (no strict `not_contains` on user-deferral phrases like "you'll need to run").
- **Context:** Codify for incident-orchestrated-spurious-pauses chose minimum viable coverage (one test that would have caught the specific incident). Adjacent gaps are logged here rather than written now. The same TRANSITION-emission mitigation applied to all five per-phase skills — so the bug class is fixed everywhere, but only the build→verify-auto transition has tight regression coverage.
- **Suggested action:** Add scenarios S22 (verify-auto→verify-self chaining), S23 (verify-codify→ship chaining), each with strict `not_contains` on user-deferral phrases. Optionally harden S7 and S8 with the same strict assertions S21 uses.
- **Priority:** low (mitigation applied across all 5 skills; this is defense-in-depth)
- **Status:** open

## SURFACE-2026-05-11-SESSION-START-SUGGEST-FROM-BACKLOG
- **Source:** user-initiated (session-start dispatch, 2026-05-11)
- **Target level:** feature:plan (small/simple — single skill, prose addition)
- **Type:** workflow-enhancement
- **Summary:** When `/session-start` finds no paused session and no active WIP, have it also check `workflow/backlog.md` and surface open items to the user as candidate work. Today step 1 only checks `workflow/.session.md`, `workflow/wip/`, and `docs/product/*.md` frontmatter. The backlog is the natural next place to look — open SURFACE items are exactly the "what could I work on?" list.
- **Context:** Observed live in this session — user asked "anything in the backlog?" after session-start said no active work. The skill could volunteer that.
- **Suggested action:** Update `skills/session-start/SKILL.md` step 1 to also read `workflow/backlog.md` (if present), parse open items (Status: open or no Status line), and present a short list as candidates *before* asking "What are you tackling?". Decide: show all open, or only top-N by priority? Probably top-3 by priority, with a "more" affordance.
- **Open questions:**
  - Should the suggestion appear only when nothing else is active, or always as a "by the way" footer?
  - How to rank — by priority field, by recency, by target level (task < feature)?
  - Does this risk overwhelming the user when the backlog is long? Probably not at current volume; revisit if backlog grows past ~20 items.
- **Priority:** medium (low cost, high relevance for daily use)
- **Status:** open

## SURFACE-2026-05-11-ENTRYPOINT-SKILLS-LOAD-PRODUCT-CONTEXT
- **Source:** user-initiated (session-start dispatch, 2026-05-11)
- **Target level:** feature:spec (touches multiple entry-point skills; needs design before implementation)
- **Type:** workflow-enhancement
- **Summary:** Entry-point skills (the ones run first in a workflow — `task-plan`, `feature-spec`, `feature-plan`, `feature-reproduce`, `incident-report`, `product-vision`) should optionally load relevant context files from `docs/product/` (e.g., `arch.md`, `wbs.md`, `vision.md`, `roadmap.md`, `context.md`) when present, so the planning step starts with strategic context rather than working from a blank slate.
- **Context:** Today, an entry skill knows nothing about the project's product docs unless the user pastes them in. For tasks/features that touch architectural decisions or relate to a WBS work package, this is wasteful — the docs already exist on disk. The user flagged this as needing debate: *which* file to load is non-obvious and varies by skill.
- **Open design questions (the "debate" the user called out):**
  - **Per-skill mapping.** Which docs are relevant for which entry skill? Sketch:
    - `task-plan` → maybe `context.md` only (lightweight); arch/wbs may be overkill for atomic tasks
    - `feature-spec` → `vision.md`, `arch.md`, `wbs.md`, `roadmap.md` (full strategic context)
    - `feature-plan` → `arch.md`, `wbs.md` (just enough to align with existing work and constraints)
    - `feature-reproduce` → minimal — maybe `context.md` (bug context is in the bug itself, not in product docs)
    - `incident-report` → `arch.md`, `context.md` (where in the system did this happen?)
    - `product-vision` → none (it WRITES vision.md; loading it would be backward)
  - **Load strategy.** Read full file every time? Or summarize on first load and cache? Full read is simpler; cost is context-window bloat for docs the planning step doesn't need.
  - **Optional vs required.** Some projects (like this one) skip `context.md` deliberately. Should the skill no-op silently when a file is absent, or warn?
  - **Mid-skill vs entry-time loading.** Load all relevant docs up front, or lazily when the skill's reasoning surfaces a question that needs them? Up-front is simpler; lazy is more context-efficient but harder to write into a skill prompt.
  - **Interaction with CLAUDE.md.** CLAUDE.md is already auto-loaded by the harness — it overlaps with `context.md`. Avoid double-loading.
- **Suggested action:** Open a feature-spec to design the mapping table and load strategy. Likely deliverable is a small shared snippet in `CLAUDE.snippet.md` ("Entry-point skills check `docs/product/<file>.md` for ...") plus per-skill prompt edits.
- **Priority:** medium (improves quality of every workflow's first step; worth designing carefully before implementing)
- **Status:** open

## SURFACE-2026-05-10-FINALIZE-RETROSPECT-LOST-IN-GIT-MV
- **Source:** feature:finalize (incident-codify feature, 2026-05-10)
- **Target level:** task:plan (skill wording fix)
- **Type:** workflow-gap (operational ordering)
- **Summary:** During `/feature-finalize`, the Retrospect and Communicate sections were edited into the WIP file *after* the ship commit, then the file was moved via `git mv workflow/wip/<file>.md workflow/archive/<file>.md`. The rename was staged but the unstaged content edits were lost from the rename commit — the archive landed with state line updated but missing the §3b artifact. Required a follow-up commit (d423123) to restore. The rename commit reported "0 insertions, 0 deletions" which was the warning sign.
- **Context:** The feature-finalize SKILL §3b says "Write a short retrospect in the WIP file before archiving it" but doesn't enforce or remind to `git add` the WIP file before `git mv`. The natural sequence — edit, then `git mv` — leaves edits unstaged because `git mv` operates on the index entry of the file, not on the working tree edits. A correct sequence would be: edit, `git add <wip-file>`, `git mv <wip-file> <archive-path>`, commit. Or: edit, commit the WIP file in place with retrospect, then `git mv`, then commit the rename.
- **Suggested action:** Update `skills/feature-finalize/SKILL.md` §3 (Archive) to either (a) add explicit guidance: "If you've edited the WIP file since the last commit (e.g., to add the §3b Retrospect), run `git add <wip-file>` *before* `git mv` so the edits are staged with the rename. Verify with `git diff --cached --stat` that the rename diff shows non-zero insertions." Or (b) reorder the procedure: write the retrospect and commit-in-place first, then archive in a second commit. The second framing is more robust against the operational mistake.
- **Priority:** medium (recurrence likely without a SKILL fix; cost is small but creates orphaned commits)
- **Status:** resolved — closed by per-project-changelog feature (2026-05-12, commit `dcd0d6b`). All 4 closing SKILLs now include an explicit "Operational sequence" block documenting append→`git add`→`git mv`→commit ordering. Adopts option (a) from the suggested-action list — explicit staging guidance rather than procedure-reorder.

## SURFACE-2026-05-11-STORE-LEARNING-NO-TRANSITION-ID
- **Source:** feature:verify-codify (reflect-store-local-only feature, Phase 1, 2026-05-11)
- **Target level:** Phase 3 of the same feature
- **Type:** gap (test infrastructure consistency)
- **Summary:** `session-store-learning` had no S-transition-ID and emitted no `TRANSITION:` line. Resolved 2026-05-11: added S20 to transitions.md and `TRANSITION: S20` emission in Step 3 of SKILL.md. S19 now PASSes strictly.
- **Status:** resolved (Phase 3, this feature)

## SURFACE-2026-05-10-I20-SCENARIO-MISSING
- **Source:** feature:verify-codify (incident-codify feature, Phase 3, 2026-05-10)
- **Target level:** task:plan
- **Type:** gap (test coverage)
- **Summary:** I20 (codify → investigate back-loop) has no test scenario. The other three codify transitions (I17, I18, I19) and the defer variant (I18-defer) all have scenarios. I20 is the rare "codify-time evidence reveals investigate's root-cause analysis was wrong" case — distinct from I19 ("mitigation didn't fix the bug, try a different fix").
- **Context:** I20 was approved in verify-human as part of the SKILL.md procedure (kept rather than folded into I19) but the plan's Phase 3 scenario list didn't include it. Without a scenario, the I20 path is documented but uncovered — a future regression on I20 emission would slip through the test sweep.
- **Suggested action:** Add an I20 scenario to `tests/scenarios/incident.yaml`. Fixture: `incident-codify-with-reproduce-artifact.md` (or a new fixture). Prompt should describe codify-time evidence that contradicts the prior investigation's root-cause conclusion (e.g., the failing test passes against the mitigated code, but a different failing condition exists that wasn't part of the original investigation). Expected transition: I20 → /incident-investigate.
- **Priority:** low (the path is rare in practice; cost of adding a scenario is small but not urgent)
- **Status:** open

## SURFACE-2026-05-10-CLAUDE-CODE-TIME-TRACKING
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
- **Priority:** low (exploration — no commitment, no deadline)
- **Status:** open — idea-only, no spec yet

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

- **SURFACE-2026-05-11-ORCHESTRATED-PAUSES-BETWEEN-PER-PHASE-STEPS** — RESOLVED 2026-05-11 (via incident workflow, archived as `incident-orchestrated-spurious-pauses.md`): Root cause was that 5 per-phase feature SKILLs (`feature-build`, `feature-verify-auto`, `feature-verify-self`, `feature-verify-human`, `feature-verify-codify`) did not instruct the model to emit canonical `TRANSITION: <id>` tokens — so the orchestrator had no machine signal to act on and fell back to honoring "Run /x" prose as a stop. Fix: added `### Emit Transition` sections to all 5 SKILLs enumerating valid transition IDs; added explicit anti-example to `session-start/SKILL.md` step 4 showing the exact buggy shape. Regression gate: new scenario `S21` in `tests/scenarios/session.yaml` (PASSes on haiku + sonnet, dual-identity `transition_id_any: [S21, F8, F10]` + strict `not_contains` on user-deferral phrases). Adjacent coverage gaps logged as `SURFACE-2026-05-11-PER-PHASE-CHAINING-SCENARIO-COVERAGE`.

- **SURFACE-2026-05-08-INCIDENT-CODIFY-EQUIVALENT** — RESOLVED 2026-05-10: Implemented `incident-codify` skill between mitigate and resolve. Added transitions I17 (mitigate→codify default), I18 (codify→resolve), I19 (codify→mitigate back-loop), I20 (codify→investigate back-loop); kept I9 as defer-with-SURFACE path. New SKILL adapts feature-verify-codify's highest-level test rule, integration-boundary check, and six-case triage table — with incident-context semantic flip ("code regression" → back-loop to mitigate, not auto-fix) and speed-aware paths (Path A reuses reproduce-artifact, Path B writes from scratch, defer path with SURFACE→task:plan). Wiring across `agents/incident-workflow/AGENTS.md` (skills frontmatter, diagram, states table, transition table, pause policy with conditional AUTO/PAUSE), `docs/product/transitions.md` (transition table, pause-policy table, new Codify-step paragraph), and three existing SKILLs (incident-mitigate, incident-resolve, incident-reproduce). New test fixtures (`incident-codify-with-reproduce-artifact.md`, `incident-codify-no-reproduce.md`) and scenarios (I17, I18 Path A, I18-defer, I19); existing I9 scenario rewritten to assert defer semantics. CLAUDE.md updated.
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
