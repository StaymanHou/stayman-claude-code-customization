# Backlog

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
