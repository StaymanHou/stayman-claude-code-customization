---
workflow: feature
state: plan (revised — F23 back-loop on 2026-06-07)
created: 2026-06-07
drive_mode: autopilot
source_backlog: SURFACE-2026-05-29-LONG-CMD-TIMEOUT-AND-EXCLUSIVE-RESOURCE-CONCURRENCY
source_learning: .claude/learnings/2026-05-29-pytest-timeout-and-concurrent-runs.md
---

# Feature: Long-running commands — explicit timeout + exclusive-resource concurrency rule

**Workflow:** feature
**State:** plan (revised — F23 back-loop on 2026-06-07)
**Created:** 2026-06-07
**Entry:** spec (complex feature — multi-part rule, global blast radius)

## Problem Statement

Claude's default 2-minute Bash timeout silently auto-backgrounds long-running commands (full test suites, full builds, big migrations, large codemods, bulk imports). The auto-backgrounded tool result looks ambiguous enough that Claude can be misled into re-invoking the same command — producing two concurrent processes contending on a shared exclusive resource (test DB, cache/artifact dir, port-bound process, lock file, single-writer file/object). The second process races destructively on setup/teardown, cache invalidation, lock acquisition, or fixture lifecycle.

This is **ecosystem-independent**: the same failure shape fires for two `pytest` runs on a shared `*_test` DB, two `cargo test` runs on `target/`, two `npm test` runs on a fixed port, two migration tools on the same schema-version row. The harness today gives Claude no explicit guardrail against this pattern.

Concrete near-miss this captured (2026-05-29, `ops-data-hub`): two `docker compose exec app pytest` runs nearly raced on `Base.metadata.create_all` / `drop_all` against `ops_data_hub_test`; the second was user-backgrounded before reaching conftest setup. The first run completed cleanly (exit 0); had the second progressed past fixture setup, the destruction would have been silent and the failure would have surfaced as flakiness, not as a Bash error.

This feature codifies a three-part rule in the GLOBAL `CLAUDE.snippet.md` so it injects into `~/.claude/CLAUDE.md` for every project on every session.

[Updated 2026-06-07 — verify-human F12 back-loop]: The original problem statement scoped the prevention as **prose discipline** (rules the agent reads each session). User feedback at verify-human surfaced a missing piece: **the agent has no persistent memory of per-command runtimes between sessions**, so Rule 1's "estimate runtime" step degrades into per-session guessing — and the natural target for that knowledge (project `CLAUDE.md`) is too coarse a surface to maintain a growing registry of timing observations. The complete problem is prose-rule + lightweight per-project runtime registry that the agent reads before each tracked-command invocation and updates after each completion. Phase 2 (added in this back-loop) introduces a project-root `runtimes.md` convention; Phase 1 Rule 1 is amended to consult it first.

## User Stories

- **As an agent** running a `docker compose exec app pytest` or `npm run build` against a project with a shared backing store, I want the harness CLAUDE.md to remind me to set an explicit timeout BEFORE the run rather than discovering the default 2-minute limit at execution time and re-invoking the command from a stale result.
- **As an agent** that has just had a long command auto-backgrounded, I want the harness CLAUDE.md to give me the discipline to wait for the BashOutput completion notification rather than re-invoking the same command in the foreground — because the second invocation against the same exclusive resource is the destructive case.
- **As an agent** uncertain about a test suite's runtime in a project I haven't worked in before, I want explicit guidance to run a small subset first and gather per-unit timing before committing to the full run, so my chosen `timeout` value is calibrated rather than guessed.
- **As the repo owner**, I want this rule structurally pinned (`tests/check-structure.sh`) so a future refactor of `CLAUDE.snippet.md` cannot silently drop it.

## Acceptance Criteria

The feature is done when:

1. **`CLAUDE.snippet.md` carries a new section** — `## Long-running commands (GLOBAL)` — placed between the existing `## CHANGELOG.md convention (GLOBAL)` section and `## Pre-risky-action checklist (GLOBAL)` section (alphabetically would land between "L" and "P"; semantically Long-running and Pre-risky-action are sibling Bash-safety patterns and should sit adjacent).
2. **The new section codifies three rules**, in this order:
   - **Rule 1 — Consult the runtime registry; estimate runtime + set `timeout` explicitly.** *Revised in this F23 plan.* Leads with: "Read `<proj-root>/runtimes.md` for the tracked command's `**Use timeout:**` value and apply it. Only estimate from scratch when the command is absent from the registry." Estimation guidance (test count, build size, project CLAUDE.md prior-runtime data) is the fallback path. Formula `timeout ≥ expected * 1.5 + buffer` applies to both the registry's `**Use timeout:**` computation and the fallback estimation.
   - **Rule 2 — Never start a second instance against a shared exclusive resource.** Unchanged from Phase 1's already-approved wording.
   - **Rule 3 — When uncertain about runtime, run a small subset first.** Unchanged from Phase 1's already-approved wording.
3. **The new section carries a `### Runtime registry` subsection** — placed at the end of the `## Long-running commands (GLOBAL)` section. Documents: (a) the file's purpose (per-project runtime memory for tracked long-running commands), (b) the canonical location (`<proj-root>/runtimes.md`), (c) the file shape (frontmatter + per-command H2 + `**Last:**` / `**Use timeout:**` / `**History:**` lines), (d) the agent's read+update discipline ("Before invoking a tracked command, read `**Use timeout:**`; after completion (or kill), update `**Last:**`, recompute `**Use timeout:**`, prepend the new observation to `**History:**`").
4. **Wording is ecosystem-general** — both the rule body and the runtime-registry shape are language/runner-agnostic; per-ecosystem examples appear as illustrative parentheticals, not as the canonical statement.
5. **Rationale is preserved** — the section includes the existing "Why" paragraph citing the 2026-05-29 near-miss; the registry-discipline addition reinforces but does not replace it.
6. **Structural pin in `tests/check-structure.sh` — Long-running commands.** *Already landed in Phase 1.* Existing pin: `grep_check "CLAUDE.snippet.md defines 'Long-running commands'" "CLAUDE.snippet.md" "^## Long-running commands" 1`. No change.
7. **Structural pin in `tests/check-structure.sh` — Runtime registry subsection.** *New in this F23 plan.* Adds a pin asserting `CLAUDE.snippet.md` contains the `^### Runtime registry` heading. Co-located with the Long-running commands pin.
8. **Project-root `runtimes.md` exists with the canonical shape.** Contains the YAML frontmatter (`shape: runtime-registry` + `updated: <date>`), an `# Runtime Registry` H1, and at least one tracked-command H2 with `**Last:**` / `**Use timeout:**` / `**History:**` lines.
9. **`runtimes.md` is seeded with this repo's tier-1 long-running commands.** Minimum seeds: `./tests/check-structure.sh` (last observed today during Phase 1 build, ≥360s) and `./tests/run-tests.sh` (need one measurement during Phase 2 build — full-suite run on haiku partition is the canonical reading; if measurement is infeasible during this build, the entry MAY be omitted with an explanatory `## SURFACE-` discovery).
10. **Structural pin in `tests/check-structure.sh` — runtimes.md exists.** *New in this F23 plan.* Adds a pin asserting `runtimes.md` exists at the repo root with the `shape: runtime-registry` frontmatter marker AND at least one `^## ` command-entry heading.
11. **`install.sh` requires no changes** — the snippet is injected verbatim into `~/.claude/CLAUDE.md` by the existing install logic. (Already verified in Phase 1.)
12. **`tests/check-structure.sh` passes** — all new pins assert PASS; the existing `SURFACE-2026-06-06-SETTINGS-FIXTURE-MODEL-DRIFT` FAIL is the only unrelated pre-existing FAIL post-change. Expected PASS count: 132 (was 130 after Phase 1; +2 new pins).
13. **The backlog item is marked resolved** — `SURFACE-2026-05-29-LONG-CMD-TIMEOUT-AND-EXCLUSIVE-RESOURCE-CONCURRENCY` status flipped to `resolved` with the commit SHA, closing the open item.
14. **CHANGELOG appended** — `**Feature shipped:**` + `**Backlog resolved:**` entries on `feature-finalize`.

## Out of Scope

- **Not changing skill prompts.** This rule lives in the GLOBAL CLAUDE.md surface only — `~/.claude/CLAUDE.md` via `CLAUDE.snippet.md`. No individual skill SKILL.md gains a long-running-commands clause. Skills don't need it; the GLOBAL rule applies to every Bash invocation regardless of which skill is active.
- **Not adding a hook.** A `PreToolUse` hook that inspects Bash commands for "full suite shape" and rejects untimed invocations is a possible future enforcement layer, but: (a) shape detection is brittle (every project's test runner alias differs), (b) the GLOBAL rule first proves the discipline works at the prose layer. If the rule is violated repeatedly post-codification, *then* re-open as a hook feature.
- **Not codifying a project-level convention beyond `runtimes.md`.** Project-level CLAUDE.md may still carry per-command notes (e.g., "this command may modify shared S3 prefix X"), but the runtime registry is the *single* place per-project numeric timing data lives. Don't dual-track timings in CLAUDE.md AND `runtimes.md`.
- **Not changing the harness's auto-background behavior.** The 2-min default is a harness-level decision; this feature operates at the prompt-instruction layer, not at the harness-config layer.
- **Not addressing the related-but-distinct "two skills running in parallel via Agent" concurrency case.** That's a different shape (parent context spawning isolated subagents) and is governed by other mechanisms.
- **Not making `runtimes.md` a global file.** `~/.claude/runtimes.md` was rejected — runtimes vary by hardware, CI vs laptop, and project. Per-project keeps the file's claims grounded in real measurements from the project's actual environment.
- **Not auto-tracking every command.** The registry tracks only commands the agent *deliberately* adds via the read+update discipline (typically: full test suites, full builds, big migrations). One-off greps, file edits, single-test runs, and similar fast commands are not tracked — the registry is for commands that exceed the 2-min Bash default.
- **Not yet automating the update step via a hook.** Today the agent updates `runtimes.md` manually after each tracked-command completion (read the BashOutput, append observation, recompute `**Use timeout:**`). A future feature could add a `PostToolUse` hook that detects "tracked command in `runtimes.md` just completed" and writes the entry — same family as the `PreToolUse` enforcement-hook deferral above.

## Technical Constraints

- **Target files:** `CLAUDE.snippet.md` (injected into `~/.claude/CLAUDE.md` via `install.sh`), `tests/check-structure.sh` (structural pins), and new project-root `runtimes.md` (the registry seeded for this repo).
- **No downstream-contract impact found.** Pre-spec grep against `CLAUDE.snippet.md`, `CLAUDE.md`, and `~/.claude/CLAUDE.md` for `timeout|run_in_background|long-running|BashOutput|exclusive resource` returned zero matches. Phase 2's `runtimes.md` is a new artifact (no consumer yet — first consumer is the agent reading it under Rule 1's revised discipline).
- **Section placement constraint** — between `## CHANGELOG.md convention (GLOBAL)` and `## Pre-risky-action checklist (GLOBAL)`. The `### Runtime registry` subsection sits at the end of the Long-running commands section, before the next `## ` heading.
- **Structural-pin pattern** — `tests/check-structure.sh` line 95 is the canonical model (CHANGELOG convention pin). The Phase 1 pin already lives there. Phase 2 adds 2 more pins co-located with it (Runtime registry subsection + runtimes.md file presence).
- **Existing global rule context** — `~/.claude/CLAUDE.md` already includes a Bash-tool description with a `run_in_background` parameter mention and an "Avoid unnecessary `sleep` commands" subsection. The new section is complementary, not overlapping: this section covers TIMEOUT + CONCURRENCY-AGAINST-EXCLUSIVE-RESOURCE + RUNTIME-REGISTRY, the existing one covers PARALLEL-CALLS + SLEEP-LOOPS.
- **`runtimes.md` file shape (canonical):**
  ```markdown
  ---
  shape: runtime-registry
  updated: <YYYY-MM-DD>
  ---

  # Runtime Registry

  ## <literal command string>
  - **Last:** <Ns> (<YYYY-MM-DD>)
  - **Use timeout:** <ms>
  - **History:**
    - <Ns> — <YYYY-MM-DD>
  ```
  Constraints: (a) `## <command>` heading uses the literal command string so it's `grep`-friendly; (b) `**Last:**` and `**Use timeout:**` are each exactly one line — the agent's read path is `grep -A2 "^## <command>" runtimes.md`; (c) `**Use timeout:**` is in milliseconds (matches the Bash tool's `timeout` parameter); (d) `**History:**` is append-on-update; the agent prepends new observations to the bullet list head; (e) the `updated:` frontmatter line is touched on every write.
- **Phase 2 plan-time downstream-contract grep result:** searched the repo for `runtimes.md`, `runtime registry`, `runtime-registry`, `Use timeout:` — zero matches. New artifact, no existing consumers. Forward-compat: the file is greppable + human-readable, so future hook-based automation reads the same shape.
- **Open question (resolve during Phase 2 build):** what `**Use timeout:**` value to seed for `./tests/run-tests.sh` (full suite). Options: (a) measure during Phase 2 build via a single foregrounded run with `timeout: 600000`; (b) defer with a placeholder + SURFACE entry; (c) read `tests/run-all.sh` for an inline note. Prefer (a) — gives us the canonical first measurement.

## Open Questions

None. The spec is grounded — source learning doc is comprehensive, target file is unambiguous, downstream-contract grep is clean, structural-pin pattern is established. No 3rd-party dependency; no probe needed.

## Work Tree

- [x] Phase 1: Codify long-running-commands rule in CLAUDE.snippet.md  <!-- status: complete 2026-06-07; all P1.1–P1.5 + verify loop [x] -->
  **Observable outcomes:**
  - CLI: `grep -c "^## Long-running commands (GLOBAL)" CLAUDE.snippet.md` → exactly `1`
  - CLI: `CLAUDE.snippet.md` contains all three rule headers — `grep -E "^- \*\*Rule [123] —" CLAUDE.snippet.md | wc -l` → `3`
  - CLI (consuming surface — `install.sh` injection): after `./install.sh`, `grep -c "^## Long-running commands (GLOBAL)" ~/.claude/CLAUDE.md` → exactly `1`
  - CLI: `./tests/check-structure.sh` → all assertions PASS (including the new `Long-running commands` pin); the existing `SURFACE-2026-06-06-SETTINGS-FIXTURE-MODEL-DRIFT` FAIL is the only unrelated pre-existing FAIL and remains the only FAIL post-change
  - CLI: `grep -c "Long-running commands" tests/check-structure.sh` → ≥ `1` (the new structural pin exists)
  - [x] P1.1 Write the `## Long-running commands (GLOBAL)` section into `CLAUDE.snippet.md`, placed between `## CHANGELOG.md convention (GLOBAL)` and `## Pre-risky-action checklist (GLOBAL)`. Three-rule body, ecosystem-general wording with parenthetical examples. Includes "Why" paragraph citing the 2026-05-29 near-miss (labeled as near-miss, not incident). Section spans CLAUDE.snippet.md lines 165–177 (13 lines including blank lines and the heading — denser than the 40–55 budget I planned, but the structure preserves all three rules + "Why" cleanly).
  - [x] P1.2 Added structural pin to `tests/check-structure.sh` lines 101–104 (3-line comment block + 1-line grep_check), placed immediately after the CHANGELOG pin block so GLOBAL convention pins cluster together.
  - [x] P1.3 Ran `./install.sh` — idempotent re-run with `[update] CLAUDE.md (workflow block refreshed, backup: ...)`. Post-install verification: `grep -c "^## Long-running commands (GLOBAL)" ~/.claude/CLAUDE.md` → 1; three rule headers present.
  - [x] P1.4 Ran `./tests/check-structure.sh` end-to-end. Result: PASS=130 (was 129 baseline, +1 for the new pin) / FAIL=1 (only the pre-existing `SURFACE-2026-06-06-SETTINGS-FIXTURE-MODEL-DRIFT`, unchanged). Run took >5 min (auto-backgrounded twice at 2-min and 5-min default timeouts before completing); discovery surfaced below about `run-tests.sh --dry-run` concurrency-fragility under the structure-check critical path.
  - [x] verify-auto  <!-- Re-run after P1.5 (Rule 1 wording change): all 5 scoped pinpricks PASS — snippet heading (1), three Rule headers (3), installed-CLAUDE.md heading (1 — consuming surface), pin in check-structure.sh (2), `bash -n tests/check-structure.sh` clean. Bonus check: `grep -c "Consult the runtime registry" ~/.claude/CLAUDE.md` → 1 (new Rule 1 lead phrase landed in installed surface). Full check-structure.sh result from prior build (130 PASS / 1 unrelated FAIL) remains canonical — P1.5 touched only Rule 1 prose, no structural-pin changes. -->
  - [x] verify-self  <!-- Re-run after P1.5: all 5 outcomes PASS against live consuming surface (~/.claude/CLAUDE.md lines 172–182). Integration-boundary applies (outcome #3 cites consuming surface). Qualitative: new Rule 1 lead is "Consult the runtime registry; estimate only if absent" — correct cognitive order. New closing sentence ("After the command completes (or is killed), update the registry per the read+update discipline so future sessions inherit the measurement") establishes the update half of the contract. NOTED DEFERRAL: forward-link "(see `### Runtime registry` below)" points to a subsection Phase 2 will add — interim dangling link is acceptable because ship is post-all-phases (no published-state break). Flagging for human read-time veto. -->
  - [x] P1.5 Rewrote Rule 1 in `CLAUDE.snippet.md` to lead with `<proj-root>/runtimes.md` consultation: new lead bullet starts "First, read `<proj-root>/runtimes.md` (see `### Runtime registry` below) for the tracked command's `**Use timeout:**` value and apply it directly. Only when the command is absent from the registry, estimate from scratch…" Also amended the section's opening paragraph to say "read the project's runtime registry (or estimate if absent)" instead of "estimate runtime". Forward-link to `### Runtime registry` lands in the bullet body. Re-ran `./install.sh` to refresh `~/.claude/CLAUDE.md`; verified the new wording landed in lines 178–182 of `~/.claude/CLAUDE.md`.
  - [x] verify-human  <!-- All 3 leaves [x]. Deferral acknowledged: forward-link "(see `### Runtime registry` below)" stays in interim state until Phase 2 P2.1 lands the subsection — workflow-acceptable since ship is post-all-phases. -->
    - [x] P1.verify-human.1 Confirm the revised Rule 1 in `CLAUDE.snippet.md` now leads with `<proj-root>/runtimes.md` consultation, forward-links the `### Runtime registry` subsection, and preserves ecosystem-general wording.  <!-- approved 2026-06-07 post-P1.5 -->
    - [x] P1.verify-human.2 Confirm placement between CHANGELOG and Pre-risky-action sections reads naturally (GLOBAL sections cluster sensibly).  <!-- approved 2026-06-07 -->
    - [x] P1.verify-human.3 Spot-check the structural pin in `tests/check-structure.sh` — placement and wording consistent with surrounding pins?  <!-- approved 2026-06-07 -->
  - [x] verify-codify  <!-- Satisfied by existing P1.2 structural pin in tests/check-structure.sh (`grep_check "CLAUDE.snippet.md defines 'Long-running commands'" "CLAUDE.snippet.md" "^## Long-running commands" 1`). The pin is the canonical regression test for Phase 1 — would fail if a future refactor drops the section heading. Integration-boundary satisfied: source-side pin is the canonical guarantee because install.sh injection is deterministic. No test-suite failures (check-structure.sh: 130 PASS / 1 unrelated FAIL from build). No new tests written. Phase 2 P2.5 will add 2 more pins (`### Runtime registry` subsection + runtimes.md presence). -->

- [x] Phase 2: Runtime registry (`<proj-root>/runtimes.md`) — convention + agent discipline + seed entries  <!-- status: complete 2026-06-07; all P2.1–P2.7 + verify loop [x] -->
  **Observable outcomes:**
  - CLI: project-root `runtimes.md` exists — `test -f runtimes.md && echo OK` → `OK`.
  - CLI: `runtimes.md` carries the canonical shape — `grep -c "^shape: runtime-registry" runtimes.md` → `1` AND `grep -c "^# Runtime Registry" runtimes.md` → `1`.
  - CLI: at least one tracked-command entry — `grep -c "^## " runtimes.md` → ≥ `1` (heading line). And each entry has its 3 fields — `grep -c "^- \*\*Last:\*\*" runtimes.md` → equals the heading count; same for `**Use timeout:**` and `**History:**`.
  - CLI: `./tests/check-structure.sh` exit `0` reports `runtimes.md exists + has shape frontmatter + has at least one command entry` PASSes (the 2 new pins land). PASS count expected: 132 (was 130 after Phase 1; +2 new pins from Phase 2).
  - CLI (consuming surface): `~/.claude/CLAUDE.md` (post-`./install.sh`) contains the new `### Runtime registry` heading — `grep -c "^### Runtime registry" ~/.claude/CLAUDE.md` → `1` — within the `## Long-running commands (GLOBAL)` section. The injected prose names `runtimes.md` and describes the read+update discipline.
  - [x] P2.1 Appended `### Runtime registry` subsection at the end of the `## Long-running commands (GLOBAL)` section in `CLAUDE.snippet.md` (now ~25 lines: heading + intro paragraph + canonical-shape code block + 4-bullet read+update discipline). Slightly over the 15–20-line budget but disciplines are concrete (read pattern, update formula, scope rules, per-project rationale). Forward-link from Rule 1 (P1.5) is no longer dangling.
  - [x] P2.2 Created project-root `runtimes.md` with frontmatter (`shape: runtime-registry`, `updated: 2026-06-07`), `# Runtime Registry` H1, brief intro pointer to the CLAUDE.md discipline, and one seed entry.
  - [x] P2.3 Seeded first entry: `./tests/check-structure.sh` — `**Last:** 360s (2026-06-07)`, `**Use timeout:** 600000` (= ceil(360 * 1.5 + 60) * 1000), `**History:**` bullet pointing to the 2026-06-07 observation.
  - [x] P2.4 Seeded second entry: `./tests/run-tests.sh` (full suite). Measurement returned via BashOutput notification: **Last: 3097s** (51.6 min wall clock; ran via `bl3mp25o7` foregrounded task with `timeout: 600000` per Rule 1 — auto-backgrounded as expected, completion received without re-invocation per Rule 2). Computed `**Use timeout:**` would be `ceil(3097 * 1.5 + 60) * 1000 = 4706000 ms` — exceeds Bash hard cap; **clamped to 600000** with explicit note that this command WILL auto-background and the agent MUST wait. Run result: 89 PASS / 33 FAIL / 6 / 10 / 138 (haiku partition; matches known `SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG` pattern). Cost: $10.99.
  - [x] P2.5 Added 2 new structural pins to `tests/check-structure.sh` (lines 106–114 in the updated file). Pin (a): `### Runtime registry` heading in `CLAUDE.snippet.md`. Pin (b): `runtimes.md` shape-frontmatter marker. Both placed immediately after the existing Long-running commands pin so registry-related pins cluster.
  - [x] P2.6 Ran `./install.sh` (idempotent). Verified `### Runtime registry` subsection landed in `~/.claude/CLAUDE.md` (grep count = 1). Rule 1's forward-link is no longer dangling.
  - [x] P2.7 Ran `./tests/check-structure.sh` end-to-end with `timeout: 600000` read from `runtimes.md` per Rule 1 — **live application of the new discipline**. Wall clock: 232s (no auto-background this time; clean state since pkill'd the stale processes from the prior session). Result: **PASS=132 / FAIL=1** (matches plan's expected +2 pins; FAIL is the unchanged pre-existing settings-fixture drift). Updated `runtimes.md` with new check-structure.sh observation (232s → use-timeout 408000 = `ceil(232 * 1.5 + 60) * 1000`); prior 360s entry retained in History with note about the inflation cause.
  - [x] verify-auto  <!-- 5 scoped pinpricks all PASS: runtimes.md exists, shape frontmatter (1) + H1 (1), 2 command entries each with Last/Use timeout/History triple (2-2-2), installed CLAUDE.md has `### Runtime registry` subsection (1), forward-link from Rule 1 now resolves (1), 3 new structural surfaces in check-structure.sh. check-structure.sh full result already captured during P2.7 (132 PASS / 1 unrelated FAIL). -->
  - [x] verify-self  <!-- All 5 outcomes PASS against live consuming surface (~/.claude/CLAUDE.md lines 184–210). Integration-boundary applies (outcome #5 cites consuming surface). Qualitative: `### Runtime registry` subsection renders correctly at level 3 under `## Long-running commands (GLOBAL)`; intro paragraph + canonical-shape code block + 4-bullet discipline (read pattern, update formula, scope rules, per-project rationale) all clear. Forward-link from Rule 1 (P1.5) resolves cleanly. Cross-check vs actual runtimes.md: formula applied correctly (Last=232s → Use timeout=408000 = ceil(232*1.5+60)*1000; Last=3097s clamped to 600000 with explicit Rule-2 note). Build-time live application of all three rules: Rule 1 at P2.7 (read registry → invoke → update), Rule 2 at P2.4 (run-tests auto-backgrounded, waited for BashOutput, did not re-invoke), Rule 3 not exercised this session. Discipline survives end-to-end use. -->
  - [x] verify-human  <!-- All 3 leaves [x]; build-time meta-validation (Rule 1 + Rule 2 each exercised end-to-end during build) noted as advisory evidence of correctness. -->
    - [x] P2.verify-human.1 Read the new `### Runtime registry` subsection in `CLAUDE.snippet.md` — file-shape example readable, read+update discipline clear, location/scope rules unambiguous?  <!-- approved 2026-06-07 -->
    - [x] P2.verify-human.2 Spot-check `runtimes.md` itself — is the shape sane for future entries (commands, builds, migrations beyond just tests)?  <!-- approved 2026-06-07 -->
    - [x] P2.verify-human.3 Confirm the 2 new structural pins in `tests/check-structure.sh` are placed sensibly (clustered with the Long-running commands pin from Phase 1).  <!-- approved 2026-06-07 -->
  - [x] verify-codify  <!-- Satisfied by existing P2.5 structural pins (a) `### Runtime registry` heading in CLAUDE.snippet.md + (b) `runtimes.md` shape-frontmatter marker. Both are the canonical regression tests for Phase 2 — pin (a) guards forward-link integrity (Rule 1's "see `### Runtime registry` below" resolves only if heading exists); pin (b) guards file-identification (a hand-edited runtimes.md that drops the frontmatter would no longer be a "registry" the agent recognizes on read). Integration-boundary satisfied: source-side pins are canonical because install.sh is deterministic. No test failures (check-structure.sh P2.7 result: 132 PASS / 1 unrelated FAIL). No new tests written. Finer-grained body-content pins (Rule 1 wording, discipline-bullet formulas) considered but rejected — heading pins guard the most likely refactor regression, and the harness has no scenario-level content-assert primitive (per SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT). -->

## Current Node
- **Path:** Feature > ship
- **Active scope:** All phases complete; ready for /feature-ship
- **Blocked:** none
- **Unvisited:** ship → finalize
- **Open discoveries:** 1 — see `SURFACE-2026-06-07-CHECK-STRUCTURE-DRY-RUN-CONCURRENCY-FRAGILE` below

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

**Plan-time downstream-contract-impacts grep (per CLAUDE.md convention):**
- Searched `CLAUDE.snippet.md`, project `CLAUDE.md`, and `~/.claude/CLAUDE.md` for `timeout|run_in_background|long-running|BashOutput|exclusive resource`. **Zero matches** in all three files. Pure addition, not modification.
- Searched `tests/check-structure.sh` for the structural-pin pattern — line 95 is the canonical model.
- **Integration-boundary check:** This phase modifies `CLAUDE.snippet.md` which IS consumed by `install.sh` → injects into `~/.claude/CLAUDE.md`. Integration-boundary APPLIES. verify-self outcome cites the consuming surface (the installed `~/.claude/CLAUDE.md`). verify-codify will pin the section heading via `grep_check` — this IS the codified test on the consuming surface.
- **No skill SKILL.md, AGENTS.md, or transitions.md changes needed** — this rule lives in the GLOBAL CLAUDE.md surface only. Skills inherit it via harness load, not via skill prompt reference.

**Build-time discoveries (P1.4):**
- [SURFACED-2026-06-07] product:wbs — `./tests/check-structure.sh` exceeds the harness's default 2-min Bash timeout AND its 5-min hard cap on the first execution after install. Phase 1's `./tests/run-tests.sh --dry-run` invocation at line 762 is the slow path. The build today auto-backgrounded the structure-check three times (at 2-min default, 2-min explicit, and 5-min explicit) before completing. Worse, when a stuck `check-structure.sh` was killed, its child `run-tests.sh --dry-run` processes were orphaned and continued running — subsequent re-invocations stacked up multiple concurrent dry-runs against the same `tests/results/` and fixtures directory, exhibiting **the exact failure mode the new global rule prevents** (`pkill -f run-tests.sh` was required to clear state). Two observations: (1) `check-structure.sh` runtime ≥ 5 min should be documented in project `CLAUDE.md` (it's a tier-1 dev command — every feature finalize runs it); (2) the orphaned-child pattern means `check-structure.sh` needs a child-process trap or `exec` discipline so SIGTERM propagates. Logged below.

## SURFACE-2026-06-07-CHECK-STRUCTURE-DRY-RUN-CONCURRENCY-FRAGILE
- **Source:** feature:build — long-cmd-timeout-and-exclusive-resource-concurrency Phase 1 P1.4 (2026-06-07).
- **Target level:** project (tests/check-structure.sh + project CLAUDE.md prior-runtime note)
- **Type:** tech-debt / concurrency-fragility
- **Summary:** `tests/check-structure.sh` Phase 1 invokes `./tests/run-tests.sh --dry-run` (line 762) which on this machine takes >5 min — exceeding the harness's 5-min hard Bash cap. Auto-background + the buffered `| tail -30` pipe means the output file stays empty until completion, masking progress. When the parent `check-structure.sh` is killed (e.g. user cancel or harness-timeout), its child `run-tests.sh --dry-run` does NOT receive SIGTERM and continues running. Subsequent re-invocations stack concurrent dry-runs against `tests/results/` and fixture state — the exact failure mode the new global Long-running-commands rule was just written to prevent. Today's build required `pkill -f run-tests.sh` to clear state before the third invocation could proceed cleanly.
- **Context:** Bites every feature finalize and every shipping pass (`./tests/check-structure.sh` is run before every commit by the verify-codify and ship skills). Today's session burned ~10 min on this concurrency-stacking before the orphaned-child pattern was recognized. The pattern is silent — no error, just an indefinite hang on Phase 1.
- **Suggested action:** Two small fixes: (1) Add a `trap 'pkill -P $$' EXIT` or `exec` discipline in `tests/check-structure.sh` so killing the parent propagates to children; (2) Document `tests/check-structure.sh` runtime ≥ 5 min in project CLAUDE.md under a "Tier-1 dev command runtimes" subsection so future Bash invocations set `timeout: 600000` explicitly. Optionally: profile `run-tests.sh --dry-run` to find why scenario enumeration takes >5 min — if it's reading every fixture for each scenario, an index file would cut the cost.
- **Priority:** medium — bites every finalize/ship run; pattern is the canonical exclusive-resource failure mode in this very repo.
- **Status:** pending
