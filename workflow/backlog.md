# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention). **Code-quality findings** auto-backlogged by `feature-review-quality` are pointer-collapsed here — full content lives in `workflow/backlog-quality-findings.md`, grouped by source feature.

---

## TODO

## SURFACE-2026-07-13-STEP0-PREAMBLE-VS-PROCEDURE-RENUMBER
- **Source:** operator observation during backlog-paydown WP4 (2026-07-13)
- **Target level:** task:plan (prose-only skill-structure cleanup; sizing TBD — may touch several skills)
- **Type:** tech-debt (doc-structure clarity)
- **Summary:** Several skills use a `## Step 0: <name>` **top-level** heading as a pre-procedure preamble, then a *separate* `### 1. / ### 2. …` numbered list under `## Procedure`. The dual numbering scheme (a "Step 0" that isn't part of the `### 1/2/3` sequence) reads awkwardly and confuses "is Step 0 the first procedure step or a preamble?". Renumber/reframe so the step scheme is coherent — e.g. make the preamble un-numbered ("## Preamble: …" or "## Before you start") OR fold it into a `### 0.`/`### 1.` that's actually part of the procedure sequence.
- **Context:** Surfaced while doing WP4 (which only renames the design-priors consult *suffix* to disambiguate from the pinned entry-point `## Step 0: Available product context` convention — it does NOT touch the numbering). The renumber is a broader, separate cleanup: it likely spans all skills carrying a `## Step 0` (the 6 entry-point skills + the 2 renamed by WP4), and must stay consistent with the Phase-3 structural pins that assert the literal `## Step 0: Available product context` string for entry-point skills — so any rename of the entry-point heading requires a matching Phase-3 pin update (tripartite-sync discipline). Do NOT bundle into WP4.
- **Suggested action:** `/task-plan` — decide the coherent scheme, apply across all `## Step 0`-bearing skills, update the Phase-3 pins to match. Property-check the pin strings after.
- **Priority:** low
- **Status:** open

## Code-quality findings — memory-location-symlink (2026-07-03)
- **Pointer:** 2 MINOR findings auto-backlogged by feature-review-quality against ship commit d173bd7 — (1) `ensure-memory-link.sh` dry-run emits a stray `cd: No such file` on stderr when repo target dir doesn't exist yet + harness already symlinked (diagnostic noise, verdict correct); (2) the "any project with docs/product/" migration scope rule is prose-only, not script-enforced (acceptable given the P2.2 operator-confirmation gate). The 2 MAJOR findings from the same review were fixed in-place (amended into the ship commit) — see the WIP `## Code-Quality Review` section. Full bodies in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** small task — (1) is a ~2-line dry-run guard; (2) is a one-line README prose softening. Bundle into a `/task-plan` or the next `/util-backlog-paydown` sweep.

## Code-quality findings — design-priors (2026-06-26)
- **Pointer:** 5 findings auto-backlogged by feature-review-quality against ship commit 6542e57 — 2 MAJOR (consult scenarios encode the answer in `system_prompt_extra` → test obedience > skill-prose-driven behavior, esp. the over-infer guard; `## Step 0` added to non-entry-point product-roadmap/wbs overloads the convention + transitions.md/snippet mapping mismatch) + 3 MINOR (loose `propose` pin, stale corpus Open-questions, fixture uses "Phase" alias). Full content in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** medium (2 MAJOR), low (3 MINOR)
- **Status:** pending
- **Pickup shape:** small task — the 2 MAJOR (scenario-neutrality + Step-0-heading) pair with `SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE`; the 3 MINOR are 1-line edits bundlable into a check-structure/doc polish task.

## Code-quality findings — debug-minimal-harness (2026-06-23)
- **Pointer:** 2 MINOR findings auto-backlogged by feature-review-quality against ship commit efba0ca — (1) GATE-MET scenario uses `transition_id_any` while sibling GATE-MET scenarios assert strict single-START (idiom divergence), (2) SKILL.md "5+ rounds" traceability note vs "≥3 rounds" inconclusive threshold (cosmetic). Full content in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** small task — each is a 1-line edit; bundle into a single `/task-plan` when picked up.

## Code-quality findings — docker-daemon-vs-container-distinction (2026-06-19)
- **Pointer:** 1 MINOR finding auto-backlogged by feature-review-quality against ship commit aef35a2 — the container-down structural pin (`tests/check-structure.sh:176`) uses an over-broad `docker compose up` OR-branch that could match unrelated template prose; tighten to a more distinctive anchor. Full content in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low
- **Status:** pending
- **Pickup shape:** small task — 1-line edit to the grep_check pattern; can be bundled with other check-structure.sh pin polish.

## Code-quality findings — claude-md-compaction (2026-06-13)
- **Pointer:** 4 MINOR findings auto-backlogged by feature-review-quality against ship commit a96384a — heading drift on util-* skill `## Category` vs precedent `## Category Context`, lesson-file schema ambiguity (9 files / 3 heading shapes), redundant inline HTML comment in arch.md, and a placement-detail addendum for the YAML-parse-pin SURFACE. Full content in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Order:** P3
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** small task — each finding is a 1-line edit; bundle into a single `/task-plan` invocation when picked up.

## SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN
- **Source:** feature:build (claude-md-compaction Phase 4 verify-auto)
- **Order:** P1
- **Target level:** product:wbs (small task — likely a single check-structure.sh phase addition)
- **Type:** gap
- **Summary:** `tests/check-structure.sh` does not validate that every SKILL.md / AGENTS.md frontmatter is parseable YAML. An invalid `argument-hint:` value (unquoted inner-colon string) in `skills/util-prune-claude-md/SKILL.md` slipped through the structural sweep (PASS 251/0) and would have broken the harness's skill registry at next session load. Caught manually by `python3 yaml.safe_load` during verify-auto, fixed in-line.
- **Context:** Skill frontmatter is the harness's contract surface — an invalid frontmatter renders the skill non-invokable, but the failure mode is silent until the next session start. Mechanically pin-able: iterate `skills/*/SKILL.md` + `agents/*/AGENTS.md`, extract frontmatter (between `---` markers), pipe through `python3 -c "import sys, yaml; yaml.safe_load(sys.stdin.read())"`, fail the structural check on any non-zero exit.
- **Suggested action:** Add a new Phase to `tests/check-structure.sh` ("[Phase N] Frontmatter YAML parseability") that runs the above check across all SKILL.md and AGENTS.md files. Estimated 10-line addition.
- **Priority:** medium (silent failure mode + low fix cost)
- **Status:** resolved 2026-07-13 (backlog-paydown WP3). Added `[Phase 3a] Frontmatter YAML parseability` (placed between Phase 3 and 3b per the folded placement-note) — iterates all 47 SKILL.md/AGENTS.md, awk-extracts frontmatter, `yaml.safe_load`, reports per file. Property-tested against good+bad input (scratchpad, not committed). **On first run it caught a REAL latent bug:** `skills/feature-build/SKILL.md` had exactly this unquoted-inner-colon `argument-hint:` failure — fixed in-place by quoting. Suite 400/1 → 401/0.

## SURFACE-2026-06-16-ODD-SHAPE-FINDINGS-PROBE-MORE-HEURISTIC
- **Source:** cross-project learning (claudesk WP2 PTY probe), captured at `.claude/learnings/2026-06-16-odd-shape-findings-deserve-one-more-cycle.md`
- **Order:** P4
- **Target level:** product:wbs (judgment-shaped — either a CLAUDE.md memory addition or a verify-self-runner prompt enhancement; sizing TBD at pickup)
- **Type:** gap (autopilot quality gate)
- **Summary:** When a verify-self / review-quality finding has a shape that diverges from the standard idiom for that class of system (e.g., "TUI requires Ctrl+D twice to exit" when `/exit + Enter` is the norm), the divergence is a signal to invest one more curiosity cycle before shipping. In autopilot modes (Mode 3, Mode 4) the objective gates can't catch this — the operator's gut-check fires post-finalize when the ship commit + CHANGELOG entry already exist. Real instance: claudesk WP2 originally accepted "Ctrl+D twice exits" as the observed behavior; operator probed further and discovered the load-bearing root cause was raw-mode CR-vs-LF (`\r` is Enter, not `\n`) — a finding that would have made WP7's `send_slash_command` silently broken.
- **Context:** Two candidate landing surfaces — (a) **CLAUDE.md memory addition**: add the "odd-shape findings are a probe-more signal" heuristic as a global feedback-style rule the agent reads at session start; (b) **verify-self-runner prompt enhancement**: have the subagent ask itself "is this the shape you'd expect from a system of this class?" before reporting PASS, and surface any hedge as a `severity: COSMETIC` note into the verify-human checklist. The heuristic is judgment-shaped (definition of "odd" is not codifiable), so a hard gate is out — the pickup is choosing between memory-only vs. prompt-augmentation vs. both.
- **Suggested action:** Read the full learning at `.claude/learnings/2026-06-16-odd-shape-findings-deserve-one-more-cycle.md`. Decide between (a)/(b)/(a+b) at pickup time; implement under `/task-plan` if memory-only, `/feature-plan` if it touches `agents/feature-verify-self-runner/AGENTS.md`.
- **Priority:** medium (autopilot quality gate; cost of miss is silently-shipped misdiagnosis)
- **Status:** open

## MAYBE

_(no open items)_

---

## Buried

The following items were buried by user decision. Full content preserved in [`workflow/backlog-deferred-2026-05.md`](backlog-deferred-2026-05.md).

Buried 2026-06-07:
- `SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER` — bulk-delete safety pattern (CLAUDE.md convention proposal).
- `SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING` — audit-method gap; destructuring patterns require their own grep.
- `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` — codify plan-time downstream-contract grep into `feature-plan` SKILL.md.
- `SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD` — `docs/product/wbs.md` exceeds 300-line size guard.
- `SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG` — `--db` silently overrides `$CLAUDE_TIME_DIR` for config lookup.
- `SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE` — `session_id[:8]` truncation can collide in synthetic test data.
- `SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL-DOESNT-REACH-REACT` — synthetic `WheelEvent` dispatch doesn't reach React's `onWheel`.
- `SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT` — structural check missing; frontmatter `name:` vs. parent dir.

Buried 2026-06-12:
- `SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE` — borrow obra/superpowers' behavioral pressure tests for skill rationalization-resistance.


## SURFACE-2026-06-26-SETTINGS-FIXTURE-DRIFT-DISABLECLAUDEAICONNECTORS
- **Source:** feature:build (design-priors Phase 4 verify-auto)
- **Target level:** task:plan (small — extend strip_host_specific or add INTENTIONAL_DIFFS)
- **Type:** tech-debt
- **Summary:** `tests/check-structure.sh` Phase 7 "settings fixture in sync with live" FAILs because the live `~/.claude/settings.json` carries a `disableClaudeAiConnectors: true` key (a machine-local Claude Code connector toggle set outside this repo) that `tests/fixtures/settings.json` doesn't model. Same class as the resolved SURFACE-2026-06-23-SETTINGS-FIXTURE-DRIFT-CLAUDESK-HOOK — a host-specific live key the `strip_host_specific()` filter doesn't yet strip. Pre-existing/environmental, NOT caused by the design-priors feature (which did not touch the settings fixture).
- **Context:** `strip_host_specific()` (added 2026-06-25, commit 93677f0) strips claudesk hooks before diffing but does not strip top-level machine-local connector/UI keys like `disableClaudeAiConnectors`. As more such keys appear in the live global settings, the fixture-drift check will keep flagging them.
- **Suggested action:** Extend `strip_host_specific()` to also drop a small allowlist of known machine-local top-level keys (`disableClaudeAiConnectors`, and any future connector/UI toggles) from BOTH sides before diffing — same pattern as the claudesk-hook strip. Keep repo-owned keys fully drift-checked.
- **Priority:** low
- **Status:** resolved 2026-07-13 (backlog-paydown WP2). Extended `strip_host_specific()` with a `HOST_LOCAL_KEYS` path-allowlist (`disableClaudeAiConnectors`, `tui`, `cleanupPeriodDays`, `statusLine.padding`, `env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`) deleted from both sides before `walk()` — path-specific (not whole-key) so repo-owned siblings under env/statusLine stay drift-checked. Negative-tested: corrupting `env.CLAUDE_TIME_TRACKING` still FAILs. Suite 353/1 → 354/0.

## SURFACE-2026-06-25-AUDIT-PROMPT-LATITUDE-NEWER-CLIENT-MODEL
- **Source:** incident:resolve (incident-autopilot-askuserquestion-pauses)
- **Target level:** task:plan
- **Type:** tech-debt
- **Summary:** The AskUserQuestion-on-AUTO regression and the earlier auto-branching regression (commit 73e97e2) are two instances of one class: a newer client / Opus 4.8 acting on latitude the prompts never explicitly closed. Each was fixed reactively after biting. A proactive audit of the instruction surface (SKILL.md + AGENTS.md + CLAUDE.snippet.md) for other "implicitly-forbidden-but-never-named" behaviors a more capable/agentic model might reach for (e.g. unrequested branching, spawning subagents, web fetches, file deletions on AUTO paths) would close the class instead of waiting for the next instance.
- **Context:** See `workflow/archive/incident-autopilot-askuserquestion-pauses.md` (Root Cause + F5) — two data points established the class.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE
- **Source:** feature:refactor (artifact-tracking-policy review-quality MAJOR #2)
- **Target level:** task:plan (test-harness enhancement)
- **Type:** gap (test coverage)
- **Summary:** `session-store-learning`'s NEW override→track→`git commit --amend` branch (the one governing repos that track `<proj-dir>/.claude/learnings/`, like THIS repo) has zero behavioral coverage. The existing scenario `S20-global-canonical-path` only exercises the default no-override→leave-uncommitted branch. Per the routing-fork convention, variant routing needs a dedicated fixture per branch — but the test runner (`tests/run-tests.sh:171`) hard-copies `fixtures/CLAUDE.md` for every scenario and does NOT parse the `claude_md:` scenario key, so there's no way today to give one scenario an override-declaring CLAUDE.md. Adding that support is test-harness *new functionality* (out of refactor scope), hence backlogged.
- **Context:** Reviewer finding on ship commit 2596c87. Fix requires: (a) make `run-tests.sh` honor a per-scenario `claude_md:` fixture key (copy the named fixture instead of the fixed default); (b) add `tests/fixtures/CLAUDE-with-tracking-override.md` declaring `## Artifact tracking overrides`; (c) add scenario `S20-global-override-tracked` asserting the proposal mentions commit/amend (tracked branch). NB: property-test the new fixture-key path per the test-harness-primitives lesson.
- **Priority:** medium
- **Status:** pending

## Code-quality findings — util-backlog-paydown (2026-06-30)
- **Pointer:** 3 findings from feature-review-quality (ship aa5c831). 1 MAJOR **RESOLVED 2026-06-30** (missing Bury scenario → `UTIL-PAYDOWN-MEH-BURY` added). 2 MINOR still pending (Rule-1 parenthetical grammar `An`→`A`; ordering-rules nesting clarity). Full bodies in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (the 2 remaining MINOR)
- **Status:** pending
- **Pickup shape:** the MAJOR is a ~5-min one-scenario add (`UTIL-PAYDOWN-MEH-BURY` over the existing MEH-1 fixture item); the MINORs are one-word/structure edits. Natural candidates for the next `/util-backlog-paydown` dogfood pass or a small `/task-plan`.
