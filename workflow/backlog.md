# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention). **Code-quality findings** auto-backlogged by `feature-review-quality` are pointer-collapsed here — full content lives in `workflow/backlog-quality-findings.md`, grouped by source feature.

---

## TODO

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
- **Status:** open

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

## SURFACE-2026-06-18-PRODUCT-SKILLS-MILESTONE-TERMINOLOGY-AND-WBS-SCOPE
- **Source:** repo-owner learning captured during AlphaFun product-workflow run (turn-based-ai-test-proto-1), 2026-06-18
- **Order:** P5
- **Target level:** feature (touches `product-roadmap` + `product-wbs` SKILL.md prose, possibly `transitions.md` and global `~/.claude/CLAUDE.md`)
- **Type:** enhancement (durable terminology + scoping preferences for the product workflow)
- **Summary:** Three coherent corrections to the product workflow skills: (1) roadmap should use **"milestone"** not "phase" as its primary decomposition unit, with "phase" kept as a read-time alias and the feature Work Tree's "Phase" schema left intact; (2) `product-roadmap` should emit **flat singly-numbered milestones** with "Group" headings used only for cosmetic clustering (no dotted hierarchical numbering); (3) `product-wbs` should decompose **only the immediate next milestone**, not the whole roadmap — future milestones stay tracked in roadmap.md and are decomposed just-in-time on milestone completion.
- **Context:** Full draft (with How-to-apply detail per rule and a curation note on the Rule 1 backward-compat boundary) copied verbatim to [`docs/lessons/product-skills-milestone-terminology-and-wbs-scope.md`](../docs/lessons/product-skills-milestone-terminology-and-wbs-scope.md). The only real decision is whether to rename "Phase" in the feature Work Tree too or keep that load-bearing global schema as-is (recommendation in the doc: keep it, switch only the roadmap, alias-on-read).
- **Suggested action:** Curate the draft into `product-roadmap`/`product-wbs` SKILL.md edits (and decide on the global Work Tree boundary) via a small feature or task.
- **Priority:** medium
- **Status:** resolved 2026-06-18 by feature `milestone-terminology-and-wbs-scope` (commit ab5f7a2). All 3 rules applied across 9 product-workflow files + transitions.md tripartite-sync; feature Work Tree "Phase" kept with disambiguation note; +13 structural pins.

## MAYBE

_(empty — both prior MAYBE items promoted to TODO 2026-06-12; SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE buried same day)_

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


## SURFACE-2026-06-23-SETTINGS-FIXTURE-DRIFT-CLAUDESK-HOOK
- **Source:** feature:build (debug-minimal-harness Phase 1 verify-auto)
- **Target level:** product:wbs (small task — fixture update or INTENTIONAL_DIFFS entry)
- **Type:** tech-debt
- **Summary:** `tests/check-structure.sh` "settings fixture in sync with live" check FAILs because the live `~/.claude/settings.json` carries a `hooks.UserPromptSubmit` entry installed by the **claudesk app** (an external project), which `tests/fixtures/settings.json` doesn't model. Pre-existing drift, unrelated to the feature being built.
- **Context:** The claudesk app installs `CLAUDESK_HOOK_SOCK=... perl .../claudesk-hook.pl` as a `UserPromptSubmit` hook in the user-global settings. The structural check compares live settings to the fixture and flags any non-INTENTIONAL_DIFFS delta. This is a cross-project pollution of the global settings file, not a regression in this repo.
- **Suggested action:** Either (a) add the claudesk `UserPromptSubmit` hook to `INTENTIONAL_DIFFS` in `tests/check-structure.sh` so the check tolerates externally-installed hooks, or (b) update `tests/fixtures/settings.json` to model it. Prefer (a) — the fixture shouldn't have to track every other app's hooks.
- **Priority:** low
- **Status:** resolved 2026-06-25 by commit 93677f0 — Phase 7 now strips host-specific claudesk hooks from both live and fixture via `strip_host_specific()` before diffing (cleaner than the proposed INTENTIONAL_DIFFS approach: the repo-owned claude-time hook stays fully drift-checked). check-structure 290/0.

## SURFACE-2026-06-26-SETTINGS-FIXTURE-DRIFT-DISABLECLAUDEAICONNECTORS
- **Source:** feature:build (design-priors Phase 4 verify-auto)
- **Target level:** task:plan (small — extend strip_host_specific or add INTENTIONAL_DIFFS)
- **Type:** tech-debt
- **Summary:** `tests/check-structure.sh` Phase 7 "settings fixture in sync with live" FAILs because the live `~/.claude/settings.json` carries a `disableClaudeAiConnectors: true` key (a machine-local Claude Code connector toggle set outside this repo) that `tests/fixtures/settings.json` doesn't model. Same class as the resolved SURFACE-2026-06-23-SETTINGS-FIXTURE-DRIFT-CLAUDESK-HOOK — a host-specific live key the `strip_host_specific()` filter doesn't yet strip. Pre-existing/environmental, NOT caused by the design-priors feature (which did not touch the settings fixture).
- **Context:** `strip_host_specific()` (added 2026-06-25, commit 93677f0) strips claudesk hooks before diffing but does not strip top-level machine-local connector/UI keys like `disableClaudeAiConnectors`. As more such keys appear in the live global settings, the fixture-drift check will keep flagging them.
- **Suggested action:** Extend `strip_host_specific()` to also drop a small allowlist of known machine-local top-level keys (`disableClaudeAiConnectors`, and any future connector/UI toggles) from BOTH sides before diffing — same pattern as the claudesk-hook strip. Keep repo-owned keys fully drift-checked.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-06-25-AUDIT-PROMPT-LATITUDE-NEWER-CLIENT-MODEL
- **Source:** incident:resolve (incident-autopilot-askuserquestion-pauses)
- **Target level:** task:plan
- **Type:** tech-debt
- **Summary:** The AskUserQuestion-on-AUTO regression and the earlier auto-branching regression (commit 73e97e2) are two instances of one class: a newer client / Opus 4.8 acting on latitude the prompts never explicitly closed. Each was fixed reactively after biting. A proactive audit of the instruction surface (SKILL.md + AGENTS.md + CLAUDE.snippet.md) for other "implicitly-forbidden-but-never-named" behaviors a more capable/agentic model might reach for (e.g. unrequested branching, spawning subagents, web fetches, file deletions on AUTO paths) would close the class instead of waiting for the next instance.
- **Context:** See `workflow/archive/incident-autopilot-askuserquestion-pauses.md` (Root Cause + F5) — two data points established the class.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-06-25-TRACK-CLAUDE-DIR-AND-LEARNINGS-MEMORIES-CONVENTIONS
- **Source:** operator directive (incident-resolve session, 2026-06-25)
- **Target level:** feature:spec (touches skill prose across multiple close/learning skills + a global convention doc; sizing TBD at pickup — could be a task if it stays prose-only)
- **Type:** enhancement (durable convention)
- **Summary:** Two related conventions to codify: (1) **`.gitignore` policy — default to tracking, ignore only sensitive/PII files.** `.claude/` should be tracked, not gitignored. The general rule: ignore a file *only* if it contains sensitive information (secrets, credentials) or PII — everything else (including `.claude/learnings/`, project-local config, etc.) is tracked by default. (2) **Explicit folder/file conventions for learnings and memories** — define canonical locations + naming for learning artifacts (currently `.claude/learnings/<date>-<slug>.md` for global drafts vs `docs/lessons/<topic>.md` for curated project lessons — the split is real but under-documented) and for the auto-memory store, so the agent stops guessing destinations (cf. the two-step file-copy confusion earlier this session where the destination directory had to be asked).
- **Context:** Triggered when the operator un-ignored `.claude/` mid-session and stated the policy: "`.claude` should be tracked; we should only ignore files that contain sensitive information or PII." The learnings/memories destination ambiguity surfaced earlier the same session (a learning copy required an AskUserQuestion to disambiguate `.claude/learnings/` vs `docs/learnings/` vs the repo's own `.claude/learnings/`). Candidate landing surfaces: `CLAUDE.snippet.md` (global convention, injected by install.sh) for the gitignore policy + the folder/file map; possibly `session-store-learning` SKILL.md (which already branches global-scope `.claude/learnings/` gitignored vs project-scope — note that branch ASSUMES `.claude/` is gitignored, which now conflicts with the new track-by-default policy and must be reconciled).
- **Suggested action:** At pickup, reconcile `session-store-learning`'s "global-scope writes to gitignored `.claude/learnings/`" assumption with the new track-`.claude/`-by-default policy (these now conflict — the gitignore-based global/project scope split needs a new discriminator). Then document the gitignore policy + the learnings/memories folder map as a global convention. Likely `/feature-spec`.
- **Priority:** medium
- **Status:** resolved 2026-06-25 by feature `artifact-tracking-policy` (commits 2596c87 + 90a1b83). Codified `## Artifact tracking policy (GLOBAL)` (rule+MAP+override) in CLAUDE.snippet.md; reconciled session-store-learning to policy-follower (discriminator = CLAUDE.md override, not gitignore); path-qualification mandate + this-repo override declaration; session-reflect leading scope label. +13 Phase-12 pins, 303/0.

## SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE
- **Source:** feature:refactor (artifact-tracking-policy review-quality MAJOR #2)
- **Target level:** task:plan (test-harness enhancement)
- **Type:** gap (test coverage)
- **Summary:** `session-store-learning`'s NEW override→track→`git commit --amend` branch (the one governing repos that track `<proj-dir>/.claude/learnings/`, like THIS repo) has zero behavioral coverage. The existing scenario `S20-global-canonical-path` only exercises the default no-override→leave-uncommitted branch. Per the routing-fork convention, variant routing needs a dedicated fixture per branch — but the test runner (`tests/run-tests.sh:171`) hard-copies `fixtures/CLAUDE.md` for every scenario and does NOT parse the `claude_md:` scenario key, so there's no way today to give one scenario an override-declaring CLAUDE.md. Adding that support is test-harness *new functionality* (out of refactor scope), hence backlogged.
- **Context:** Reviewer finding on ship commit 2596c87. Fix requires: (a) make `run-tests.sh` honor a per-scenario `claude_md:` fixture key (copy the named fixture instead of the fixed default); (b) add `tests/fixtures/CLAUDE-with-tracking-override.md` declaring `## Artifact tracking overrides`; (c) add scenario `S20-global-override-tracked` asserting the proposal mentions commit/amend (tracked branch). NB: property-test the new fixture-key path per the test-harness-primitives lesson.
- **Priority:** medium
- **Status:** pending
