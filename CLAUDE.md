# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

This is the **source** repository for a Claude Code workflow system — a collection of skills and orchestrator agents that implement a state-machine-driven workflow hierarchy (Product → Feature → Task, plus Incident and Session meta-operations).

The skills and agents here are **symlinked into `~/.claude/`** by `install.sh`. Editing a file here immediately affects the live Claude Code configuration on this machine — there is no build step. Conversely, the repo is not self-contained software: the skills only run when invoked through Claude Code.

## Commands

```bash
./install.sh                          # Idempotent — creates per-skill and per-agent symlinks from this repo to ~/.claude/
./tests/run-all.sh                    # Two-pass sweep: haiku for untagged scenarios, sonnet for those tagged `model: sonnet`
./tests/run-tests.sh                  # Single-pass primitive — runs whichever model is configured
./tests/run-tests.sh --group task     # Run one workflow group (task|feature|product|incident|session)
./tests/run-tests.sh --id T2,T3,F9    # Run specific transitions by ID
./tests/run-tests.sh --dry-run        # List scenarios without executing
./tests/run-tests.sh --model sonnet   # Force sonnet for ALL scenarios (overrides per-scenario `model:` tags)
./tests/run-tests.sh --filter-model X # Only run scenarios with `model: X` (or `default` for untagged)
./tests/check-structure.sh            # Structural checks: argument-hints, CLAUDE.md content, symlinks, YAML validity
```

**New tests start untagged (haiku).** Per-scenario `model: sonnet` is reserved for scenarios where haiku has been *proven* to produce model-noise — the recon discipline is: see a haiku failure, run the same scenario on sonnet, confirm it PASSes deterministically, *then* tag it. Don't tag preemptively for "safety" — the cost differential is real and haiku coverage is meaningful signal for prompt clarity.

Test runner requires `claude` CLI, `jq`, and `bc` on PATH. Results are written to `tests/results/run-<timestamp>.json` (gitignored). Each test spins up a temp project directory, copies `tests/fixtures/` into it, runs the skill in `--print` mode with a system prompt that forces the model to emit `TRANSITION: <id>` at the end, then verifies the output.

**`tools/claude-time/` tests run in a Docker container, not on the host.** The container is the canonical test path for the `claude-time` subproject; lifecycle is managed by `tools/claude-time/test/run-in-container.sh` (subcommands: `start`, `stop`, `restart`, `status`, `exec <cmd>`, `logs`, `help`). The image bundles Python 3.12 + Perl + sqlite3 + jq + Node + Playwright + Chromium, and the repo root bind-mounts at `/work` rw so edits on the host are visible inside the container immediately. See `tools/claude-time/README.md` → "Running tests" for canonical invocations.

## Architecture

### Two kinds of artifacts

- **Skills** (`skills/<name>/SKILL.md`) — one per workflow step. Each skill's prompt encodes the **valid transitions** out of the corresponding state. The model is expected to pick a transition at the end of the skill and tell the user which slash command to invoke next.
- **Agents** (`agents/<name>/AGENTS.md`) — one orchestrator per workflow group (product, feature, task, incident). Each agent holds the full state-machine view and an **Orchestration Procedure** section that `/session-start` reads as an instruction set. These files are reference documents, not Agent-spawned subagents.

### Two invocation paths — single-step vs end-to-end

- **Direct slash command** (e.g., `/product-vision`) — runs exactly one skill, then tells the user the next slash command. Single-step, no chaining. Use when you want to invoke a specific state or resume work.
- **`/session-start`** — classifies the work, gets one confirmation, then **drives the workflow in the current conversation** by loading the matching orchestrator's Orchestration Procedure and invoking each skill via the Skill tool. Pauses only at human-input points defined by the procedure. Use when you want to drive a full workflow end-to-end.

Why in-context and not via Agent spawn: the `Agent` tool is one-shot — a subagent that pauses for human input can't be resumed, which forced each human pause to respawn a fresh subagent and lose mid-step state. Running orchestration in the parent keeps the user dialogue continuous. An experimental subagent-per-step design is documented in `docs/product/transitions.md` → "Experiment: Subagent-Per-Step Orchestration" if context growth ever becomes a problem.

Keep both paths working: never bake auto-chain logic into individual skill prompts (that would break single-step invocation). Orchestration behavior lives in the orchestrator AGENTS.md files, invoked by reference from `/session-start`.

### The state machine lives in three places — keep them in sync

1. `docs/product/transitions.md` — authoritative definition (IDs like `P1`, `F8`, `T2`, `I3`) plus architecture narrative and cross-level mechanism docs.
2. Per-skill `SKILL.md` — each skill lists the transitions *out of its state* in prose, referencing the same IDs.
3. `tests/scenarios/*.yaml` — scenarios assert a specific transition ID fires for a given input.

If you add, remove, or reword a transition, update all three. The tests use the IDs as the source of truth for pass/fail.

The feature per-phase loop is: `build → verify-auto → verify-self → verify-human → verify-codify`. Note that `verify-self` (agent live-system observation) sits between automated checks and human review — it was added in WP7 to close the gap where agents handed off to humans without ever observing the running system.

The incident workflow has its own regression-securing step: `mitigate → codify → resolve`. `incident-codify` adapts feature-verify-codify's discipline (highest-level test, integration-boundary check, six-case triage table) with two incident-context flips: (1) a codify-time test failure means the mitigation didn't fix the bug → back-loop to mitigate (I19), not auto-fix; (2) speed-aware paths — Path A reuses an existing reproduce-artifact, Path B writes from scratch, and a defer path (I9, with SURFACE→task:plan audit trail) is available when active incident pressure makes writing coverage now infeasible.

### Work Tree Format

WIP files use the **Work Tree format** — a recursive tree with status-tagged nodes, `## Current Node` pointer, and `## Discoveries` section. The canonical schema and status vocabulary (`NOT-STARTED`, `in-progress`, `FAILED`, `BLOCKED`, `SURFACED`) live in `CLAUDE.snippet.md`, which `install.sh` injects into `~/.claude/CLAUDE.md`.

Work Tree status vocabulary: `NOT-STARTED` → `in-progress` → `[x]` (complete); failure states: `FAILED`, `BLOCKED: depends on <node>`, `SURFACED: <summary>`. A parent node may only be checked `[x]` when ALL children are `[x]`.

Key conventions:
- **Observable Outcomes** are written at plan time (in `feature-plan`), not at verify time. Each outcome must be mechanically verifiable — an HTTP status, a Playwright selector, or a CLI exit code. Prose outcomes ("looks correct") are not acceptable.
- **Severity taxonomy** for `feature-verify-self` failures: `BLOCKING` (ship-blocking — blank page, broken endpoint, crash) triggers a back-loop to build; `COSMETIC` (visual misalignment, non-critical) is noted but does not block forward progress to `verify-human`. Full taxonomy in `skills/feature-verify-self/SKILL.md`.
- **Scoped re-entry:** when `feature-verify-human` rejects a phase, it passes specific failed leaf IDs (e.g. `P1.verify-human.1`) to `feature-build`. Build restricts work to those leaves only — does not re-implement the whole phase.

### State persistence is per-project, not here

Skills read and write state **in whatever project the user is currently in** — not in this repo. This repo's own `workflow/` directory holds no WIP files.

Two locations, different purposes:

- **`docs/product/`** — strategic product docs. Flat layout, one file per product-workflow stage: `vision.md`, `roadmap.md`, `research.md`, `arch.md`, `wbs.md`, `context.md`. Each file carries YAML frontmatter with `stage`, `state` (`in-progress` / `complete`), and `updated`. **Assume one product per codebase.** When a WBS cycle completes, cycle-scoped docs (`wbs.md`, `research.md`, and any diagnostic/scratch docs) are archived to `docs/product/archive/<cycle-name>/` by `/product-finalize`. Durable docs (`vision.md`, `arch.md`, `transitions.md`, `roadmap.md`) remain in place across cycles.
- **`workflow/`** — transient execution state for feature/task/incident workflows.
  - `workflow/wip/<item>.md` — the active work item for a feature, task, or incident
  - `workflow/backlog.md` — SURFACE discoveries
  - `workflow/archive/` — completed feature/task/incident items
  - `workflow/.session.md` — single-file session pointer written by `/session-pause` and read by `/session-resume`. Only one active pause per repo; overwritten by subsequent pauses.

Back-loops in the product workflow (P4, P6, P8) edit an earlier stage's file in place — bump `updated:`, set `state: in-progress`, append a `## Revision <date>` section. Files are not deleted on back-loops.

This repo itself dogfoods the system: `docs/product/vision.md` is the vision for the workflow system. The repo's own `workflow/` directory holds no WIP files — all strategic and architectural docs live in `docs/product/`.

### Enforcement model

State transitions are **advisory**, not hard-blocked. The skill prompts tell the model what the valid next states are; there are no hooks that prevent invalid transitions. This is intentional — see `docs/product/transitions.md` → "Design Principles" for rationale. Back-loops (`type: back-loop`) require the model to document *what changed and why* before re-entering an earlier state.

### Cross-level mechanisms

Three ways one workflow interacts with another — understand the distinction before editing transitions:

- **SURFACE** (lower → higher): discovery is logged to `workflow/backlog.md`. Mode is either `note-and-continue` (non-blocker) or `pause-and-escalate` (blocker).
- **ESCALATE** (task → feature, etc.): current item is closed/archived; work is absorbed into a higher-level item. No resume.
- **REDIRECT** (e.g., `build → research`): current workflow pauses, other workflow runs, original resumes — possibly with re-planning.

### `debug-*` Skill Category

Not all skills are workflow states. `debug-*` skills are **agent-pulled sidebars** — ad-hoc debugging/troubleshooting techniques that the orchestrator (or the user) reaches for when standard debugging stalls inside an existing workflow state. They are tools, not states.

**How `debug-*` differs from workflow skills:**

| | Workflow skill (e.g. `feature-build`, `incident-investigate`) | Debug skill (`debug-*`) |
|---|---|---|
| State machine | Owns a state node in F/I/T/P/S | None — no state, no entry/exit transitions |
| Listed in `agents/*/AGENTS.md` `skills:` frontmatter | Yes | **No** |
| Transition tokens | `F8`, `I6`, `T2`, etc. (numbered, integer namespace) | `DEBUG-<TECHNIQUE>-<OUTCOME>` (descriptive, namespaced prefix) |
| Returns to caller | Workflow advances to next state | Yes — emits `RETURN-TO: <caller-skill>` to resume |
| Invocation | By orchestrator or user, per state-machine rules | Pulled by orchestrator from within a workflow state, OR directly by user via slash command |
| Pause policy table entry | Yes | **No** — sidebars don't appear in pause-policy tables |

**Required SKILL.md sections** (every `debug-*` skill must have these):
- `## Category Context` — brief paragraph confirming "this is a sidebar, not a workflow state" and naming the caller skills that may invoke it
- `## When to use` — conjunctive trigger preconditions (the gate boundary)
- `## When NOT to use` — explicit non-applicability conditions
- `## Procedure` — first step is a **Gate Check** that re-confirms the preconditions in writing and emits a `DEBUG-<TECHNIQUE>-SKIP` token + `RETURN-TO:` if the gates don't hold
- `## Pitfalls` — load-bearing failure modes of the technique
- `## Termination` — table of TRANSITION tokens the skill emits, with the `RETURN-TO: <caller>` convention

The `## When to use` and `## When NOT to use` sections are checked by `tests/check-structure.sh` (Phase 3b) — removing them is a regression.

**Caller-skill prose only.** Workflow skills that may benefit from a `debug-*` sidebar (`feature-build`, `incident-investigate`, `task-act`) mention the option in prose under their procedure section. No transition table edits, no new F/I/T IDs — the sidebar returns to the same workflow state, so the state machine is unchanged.

**Where to find the list of available techniques.** Each orchestrator AGENTS.md has a "Debug techniques (agent-pulled sidebars)" subsection naming the available `debug-*` skills and the states from which they may be invoked. See also: `docs/product/transitions.md` → "Sidebar skills (`debug-*` category)" under Cross-level mechanisms.

### Telegram notifications

Telegram notifications are wired via a Claude Code hook (`hooks/notify-telegram.sh`, symlinked into `~/.claude/hooks/` by `install.sh`) configured under `hooks.Notification` and `hooks.Stop` in `~/.claude/settings.json`. The harness fires the script on every Notification event (Claude is blocked, awaiting input/permission) and Stop event (turn ended) — deterministic, no model involvement. Requires `CLAUDE_TELEGRAM_BOT_TOKEN` and `CLAUDE_TELEGRAM_CHAT_ID` in `~/.claude/settings.json` env; the hook no-ops silently if either is unset. This replaced an earlier `notify-human` skill that relied on the model remembering to invoke it before each question — see `docs/product/transitions.md` change-log for the migration.

## Product Workflow Notes

This repo dogfoods the product workflow but **skips `/product-context`** — the project already has a hand-maintained `CLAUDE.md` (this file) that serves the same purpose. The product workflow is considered complete after `/product-wbs` and `/product-finalize`.

## Current Phase

**Active cycle:** Workflow System v2 — PP4 + PP5
**WBS:** WP14–WP17 complete (see `docs/product/wbs.md`)

- **WP14** ✅ — AUTO/PAUSE policy table in `agents/feature-workflow/AGENTS.md`; back-loops and ship are AUTO
- **WP15** ✅ — Test triage gate in `feature-verify-codify/SKILL.md` (six-case table, triage artifact, flaky detection)
- **WP16** ✅ — Triage test scenarios F16-triage-{regression,ambiguous,flaky,contract}
- **WP17** ✅ — Hardening: transitions.md updated, CLAUDE.md updated, structure checks pass

## Claude-time visualize URL-hash state

The `claude-time visualize` dashboard persists view state in the URL fragment so reloads survive and links are shareable. Introduced in WP5 Phase 3 of the `claude-time-visualize-v2` cycle. **This convention applies only to the visualize dashboard; it is not a project-wide URL pattern.** Downstream WP6 (Day rename), WP7 (Month view), WP8 (Custom-range), WP9 (Filter chips), WP13 (Collapsible projects) all extend this same hash schema rather than inventing a new one.

### Key shape

```
#viewport=480:1320;view=day;filters=active,subagent;expanded=projectA,projectB
```

- **Separator between pairs:** `;` (semicolon).
- **Key/value separator:** `=`.
- **Values are URL-encoded** via `encodeURIComponent`. Keys are URL-decoded on read but should stay alphanumeric in practice.
- **Order is not significant.** The hash is a set of key=value pairs, not a sequence.
- **No leading `#` in stored state** — the leading `#` is the URL fragment indicator only.

### Merge semantics

Each consumer owns one or more keys. Read and write go through shared helpers in `viz/dashboard.jsx`:

- `parseHash(): {key: value}` — reads `window.location.hash`, returns decoded key/value object. Missing hash → empty object.
- `updateHash(patch)` — applies `patch` to the current hash, preserving other keys, then calls `history.replaceState(null, '', '#<serialized>')`. **Values of `null` or `undefined` in `patch` delete the key entirely** (this is how default-elision is implemented).
- `serializeHash(obj): string` — produces the `key=value;key=value` form, skipping null/empty values.

Writes never `pushState` — viewport mutations are continuous (drag, wheel, key-repeat), so adding browser-history entries would be noisy. Always `replaceState`.

### Reload behavior

On Dashboard initial mount (`React.useEffect([])`), each consumer reads its own keys, parses, validates, and applies via the relevant `useState` initializer. Malformed values are ignored — the consumer falls back to its default. Round-trip stability is required: `parseHash(serializeHash(state))` ≡ `state` for every consumer's slice.

### Default-elision rule

When a consumer's current value equals its component-default (e.g., viewport equals "fit data window"; view equals `"day"`; filters is the empty/all-on set), the key is **omitted** from the hash. This keeps URLs short for the common "haven't customized anything" case. Each consumer is responsible for its own default-comparison: pass `null` to `updateHash({key: null})` when value equals default.

### Per-consumer key reservations (one-line examples)

| Consumer WP | Key | Example value | Default-elision when |
|---|---|---|---|
| WP5 (viewport) | `viewport` | `480:1320` (integer-minute pair, decimal, colon-separated) | viewport equals data-derived `_initialViewport()` |
| v3 WP5 (day iso) | `date` | `2026-05-29` (YYYY-MM-DD) | `dayIso === window.CT_DATA.window.end` (the most-recent pre-rendered day; the default landing) |
| v3 WP6 (week monday) | `week` | `2026-05-25` (YYYY-MM-DD, Monday-anchored) | `mondayIso === current_week_monday` (the Monday of the ISO-week containing `window.CT_DATA.window.end`) |
| WP6 (view tab) | `view` | `day` \| `week` \| `month` \| `custom` | `view == 'day'` (default) |
| WP7 (month) | `month` | `2026-05` (YYYY-MM) | view ≠ `month` |
| WP8 (custom range) | `range` | `2026-05-01:2026-05-07` (start:end ISO) | view ≠ `custom` |
| WP9 (filter chips) | `filters` | `active,subagent` (comma-separated kind names) | all kinds enabled (default) |
| WP10 (metrics card) | `metrics` | `expanded` (the only non-default value) | card is collapsed (default) |
| WP11 (compare preset) | `preset` | `wow` \| `today-vs-trailing` \| `mom` \| `custom` | view ≠ `compare` |
| WP11 (compare custom ranges) | `ranges` | `2026-05-13:2026-05-19,2026-05-20:2026-05-26` (two `:`-joined ISO pairs, comma-separated) | preset ≠ `custom` (and view ≠ `compare`) |
| WP13 (expanded projects) | `expanded` | `my-thing,om-design` (comma-separated project aliases) | default collapsed-state matches user pref |

### Round-trip example

```
#viewport=480:1320;view=month;month=2026-05;filters=active,subagent
↓ parseHash
{viewport: "480:1320", view: "month", month: "2026-05", filters: "active,subagent"}
↓ each consumer reads its own keys
WP5 viewport: { visible_start_min: 480, visible_end_min: 1320 }
WP6 view:     "month"
WP7 month:    "2026-05"
WP9 filters:  { active: true, subagent: true, reading: false, thinking: false, away: false }
```

### When to extend

Future WPs that need to persist state in the URL must (a) reserve a key in the table above with a one-line PR to this section, (b) implement read+write via `parseHash`/`updateHash`, (c) define their default-elision condition explicitly. Do not introduce alternate serializers (no JSON-in-fragment, no query-string `&` separators).

## Conventions

- `install.sh` is idempotent. Re-run after adding or renaming a skill/agent directory — it will create new symlinks and update any whose target has changed.
- Skill frontmatter fields: `name` (matches the directory), `description`, optional `argument-hint`.
- Agent frontmatter includes a `skills:` list — this must match the directories that exist under `skills/`.
- When the PR description references a transition, use the ID from `docs/product/transitions.md` (e.g. "Fixes F12 back-loop wording"), not the state names alone.
- **Orchestrator pause policy** has a dual location since the 2026-05-17 autopilot-pause-policy-recheck mitigation. The **canonical table** lives in `agents/feature-workflow/AGENTS.md` (single source of truth, full state-machine view). Each feature SKILL.md (`feature-spec`, `feature-research`, `feature-plan`, `feature-build`, `feature-verify-auto`, `feature-verify-self`, `feature-verify-human`, `feature-verify-codify`) also carries an `## Orchestrator Pause Policy (cheat-sheet)` block with **per-skill rows only** (just that skill's own exits) plus a `Hard rule for AUTO exits` imperative — this lives next to the transition emission so the orchestrator reads it at every Skill invocation, mitigating narrative-cadence drift from AGENTS.md being read once at session start. `TRANSITION: <id>` remains the machine signal; "Run `/x`" prose is advisory for single-step users only. The presence of the per-skill blocks is enforced by `tests/check-structure.sh` Phase 9 (24 assertions). Drift between AGENTS.md and the per-skill rows is *not* yet enforced — followup tracked as `SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT` (task:plan, medium).
- **task-verify single-step gate (task workflow).** Every `task-act` now exits to `task-verify` (T5a), not directly to `task-close`. task-verify writes an observable into the WIP, runs the verification, and emits T5b (PASS → close) or T5c (FAIL → back-loop to act). Pure-docs tasks may declare `docs-only: true` in the WIP frontmatter at plan time to auto-skip the gate. Mirrors `feature-verify-self`'s in-place fix shortcut shape (three gates: trivial extension + fresh re-verification + audit-trail `[SHORTCUT-<YYYY-MM-DD>]` entry) for SURFACED-sibling-bug handling at §4b. See `skills/task-verify/SKILL.md` for the full procedure. Shipped 2026-06-11 from SURFACE-2026-06-09-TASK-WORKFLOW-NEEDS-LITE-VERIFY.
- **feature-review-quality per-feature code-quality reviewer (feature workflow).** A new state sits between `feature-ship` and `feature-finalize` invoking a one-shot Agent reviewer subagent against the ship commit baseline. Severity-tier action matrix is advisory by default with operator-veto: **CRITICAL** → auto-invokes `feature-refactor` (F40, Modes 2-3); **MAJOR** → Mode 2 pause-and-ask (F41) or Mode 3 auto-backlog with prominent chat surface (F39, preserves "verify-human is the ONLY autopilot pause" invariant); **MINOR** → auto-backlog (F39). **Mode 4** (full-autopilot) skips the skill entirely — `feature-ship` emits F17b directly to finalize when WIP frontmatter shows `drive_mode: full-autopilot`. Transition surface: F38 (ship → review-quality), F39 (review-quality → finalize, clean/MINOR/Mode-3 MAJOR), F40 (review-quality → refactor, CRITICAL), F41 (review-quality → finalize, Mode-2 MAJOR after pause-and-ask), F17b (ship → finalize direct, Mode-4 SKIP). F17 retired. Reviewer prompt is **externalized** at `skills/feature-review-quality/reviewer-prompt.md` (~150-line template tuned to this codebase's SKILL.md/AGENTS.md/scenario-YAML/structural-pin patterns; tripartite output: Strengths / Issues by severity / Assessment). The reviewer is observe-only (no Edit/Write tools); findings flow forward into refactor or backlog. Operator's read-time veto: edit `## Code-Quality Review` section in WIP and mark findings `[DISMISSED]` before finalize archives the file. Diverges from `obra/superpowers`' per-task "all findings block" model — post-ship placement makes back-loops on shipped commits expensive, so advisory-default + read-time veto is the recovery surface. See `skills/feature-review-quality/SKILL.md` for the full procedure. Shipped 2026-06-11 from SURFACE-2026-06-02-CODE-QUALITY-REVIEWER-SUBAGENT.
- **Test triage at verify-codify:** any test failure requires a `## Test Triage — <name>` block in the WIP file before any file is modified. Six cases: code regression (high/low), obsolete test (high/low), contract conflict (always pause), flaky (re-run 3x then pause). High confidence = failure has exactly one plausible explanation, stateable in one sentence without hedging.
- **Integration-boundary rule** in the per-phase verify loop: when a phase modifies code inside an existing endpoint, UI, CLI, job, or external call site, verify-self must include an outcome citing the consuming surface, verify-human cannot use the F11 skip path, and verify-codify must include a test on the consuming surface. Full rule in each `feature-verify-*/SKILL.md`.
- **Test scenario `expect:` fields** — `transition_id` (single match) is the standard. Use `transition_id_any: [A, B, C]` when a scenario has dual identity (e.g., a session-orchestrator step that is genuinely emitting an F-ID of the workflow it's driving). Use `not_contains_strict: true` when content-mismatch is a real behavior bug (e.g., "auto-chain" appearing in autopilot mode); the default lenient mode treats `not_contains` hits as warnings only.
- **Test scenario design — routing-fork patterns:**
  - **Variant routing needs dedicated fixtures.** When testing "branch A vs branch B from the same parent state" (e.g., I3/I13/I4 all exit from triage), each scenario needs its own fixture framing the parent state with the specific branch's signal — not a shared fixture. Sharing makes the model's choice noisy. Observed in I13 SOFT_PASS (2026-05-09): shared `incident-report-filed.md` caused the model to default to `TRANSITION: I2` instead of I13.
  - **Entry-state transitions need a different test shape than exit transitions.** `transition_id: <X>` + `not_contains: [<downstream paths>]` is structurally fragile when the skill stays *in* a state — the model describes what it won't do, mentioning downstream paths in negation (prose-leak family of S12, F31). Use `transition_id_any: [<entry>, <fallback-exit>]` and avoid aggressive `not_contains` constraints for entry-state scenarios.
  - **"Default-skip on ambiguous" rules need unambiguous inputs.** A scenario asserting "this should fire X" must pick an input where X is the clearly correct answer, not a borderline case. Borderline inputs test calibration, not existence — they will SOFT_PASS or FAIL when the model picks the simpler path. Observed in S18 redesign (2026-05-09): order-flip-bug input was bug-shape AND small/simple → model correctly chose small/simple path. Redesigned input to be unambiguously complex (multiple components, requires investigation) → PASS strictly.
- **Plan-level "downstream contract impacts" pass.** When a feature phase modifies a contract that existing artifacts already assert against (test scenarios, fixtures, downstream skill SKILL.md transitions, AGENTS.md rows, CLAUDE.md docs), flag those artifacts as affected in the **same phase that changes the contract** — not in a later test/docs phase. The Test Triage gate at verify-codify is a safety net, not a planning substitute. Triage caught the I9 scenario contract change during the incident-codify feature (2026-05-10) but the plan should have surfaced it as a Phase 2 deliverable, not deferred it to Phase 3. Practical application: when drafting a phase's impl tasks, ask "what else asserts against the thing I'm changing here?" before sealing the phase boundary.
- **Per-project `CHANGELOG.md` convention.** Every project that uses this workflow system maintains a human-readable `CHANGELOG.md` at its root. The four terminal-close skills (`feature-finalize`, `task-close`, `incident-resolve`, `product-finalize`) auto-append one-line entries on close (`**Feature shipped:**`, `**Task closed:**`, `**Incident resolved:**`, `**Backlog resolved:**`, `**Milestone:**`, `**Product cycle complete:**`). The canonical procedure — file shape, heading case, same-day grouping, append-before-`git mv` discipline — lives in `CLAUDE.snippet.md` under `## CHANGELOG.md convention` and is injected globally into `~/.claude/CLAUDE.md` by `install.sh`. Each closing SKILL references the snippet rather than inlining the rules. Resolved backlog items belong in CHANGELOG, not in a `## Resolved` section inside `workflow/backlog.md`.
- **`debug-*` skill category convention.** `debug-*` skills are agent-pulled sidebars (not workflow states). They emit descriptive `DEBUG-<TECHNIQUE>-<OUTCOME>` tokens (outside the F/I/T/P/S namespace) plus a `RETURN-TO: <caller>` line, run to completion, and return to the caller workflow state without consuming any transition ID. Required SKILL.md sections (`## When to use`, `## When NOT to use`, `## Procedure` with Gate Check, `## Pitfalls`, `## Termination`) are enforced by `tests/check-structure.sh` Phase 3b. Caller-skill prose mentions + orchestrator AGENTS.md "Debug techniques" subsections + `transitions.md` "Sidebar skills" note give the agent the discoverability surfaces it needs; these are also enforced (Phase 3c). Full category convention lives in this file's Architecture section under "`debug-*` Skill Category".
- **Adding a new `debug-*` sibling skill — reusable template.** Validated by `debug-empirical-telemetry-skill` shipped 2026-06-10 (the second `debug-*` skill after `debug-bisect-known-good` codified 2026-05-13). When adding the third, fourth, Nth `debug-*` skill, mirror the precedent's shape across four artifact kinds: (1) **SKILL.md scaffold** — frontmatter (`name`, `description`, `argument-hint`) + 6 required sections in order (`## Category Context`, `## When to use` with conjunctive gates marked "AND, not OR", `## When NOT to use` with explicit non-applicability conditions, `## Procedure` with `### 1. Gate Check` as the first subheading, `## Pitfalls (load-bearing — read before <verb>)` with parenthetical-suffix heading convention, `## Termination` table with `DEBUG-<TECHNIQUE>-<OUTCOME>` tokens + `RETURN-TO: <caller>` convention on every termination). (2) **3 fixtures under `tests/fixtures/wip/`** — one gates-met (clearly hits both conjunctive gates) + one per gate-fail variant (e.g. `gate1-fails.md` for the first gate's SKIP path, `gate2-fails.md` for the second gate's SKIP path). (3) **3 scenarios in `tests/scenarios/debug.yaml`** — entry-state `<TECHNIQUE>-GATE-MET` asserting `transition_id: DEBUG-<TECHNIQUE>-START` + `contains_any` for procedure-anchor phrases AND NO aggressive `not_contains` (per the existing "Entry-state transitions need a different test shape than exit transitions" guidance in this file); 2 SKIP-exit scenarios asserting `transition_id: DEBUG-<TECHNIQUE>-SKIP` + `contains_any` for the failing-gate phrase + `not_contains: [DEBUG-<TECHNIQUE>-START, DEBUG-<TECHNIQUE>-COMPLETE]`. (4) **`tests/check-structure.sh` Phase 3c extension** — 7 new `grep_check` calls (3 caller-prose pins in `skills/feature-build|incident-investigate|task-act/SKILL.md` + 3 orchestrator-row pins in `agents/feature-workflow|incident-workflow|task-workflow/AGENTS.md` + 1 mention in `docs/product/transitions.md`). Caller-prose mentions are sibling paragraphs added inside each caller skill's existing `### Xb. Debug-technique Sidebar (optional)` section, not new sections. Phase 3b's iterating `for debug_skill in skills/debug-*/SKILL.md` loop auto-adds 2 PASSes per new skill (the gate-boundary headings `## When to use` + `## When NOT to use`), so post-feature PASS count delta = +2 (auto-iterate) + 7 (Phase 3c explicit pins) = **+9 PASS per new debug-* skill** — useful for projecting post-ship structural-test counts at plan time.
- **A new skill category needs three structurally-enforced discoverability surfaces, not one.** When introducing a category-level convention (e.g. the `debug-*` category, or any future `<prefix>-*` family), the agent that ultimately invokes the skill reads only (a) its own SKILL.md, (b) the orchestrator's AGENTS.md, and (c) the caller-skill's prose. It does NOT read CLAUDE.md or `docs/product/transitions.md` at invocation time. So a category convention documented only in CLAUDE.md will not be discovered by the agent in practice. Structurally enforce all three surfaces: (1) caller-skill prose mentions in each caller's SKILL.md, (2) "<Category> techniques" subsection in each relevant orchestrator's AGENTS.md, (3) cross-level mechanism note in `transitions.md`. Codify the surfaces via `tests/check-structure.sh` so regression on any one is caught. The CLAUDE.md convention doc is the *author-facing* reference; the three structural surfaces are the *agent-facing* discoverability. Caught 2026-05-14 during the `debug-*` category feature.
- **Test-harness primitives need property-testing across the full input namespace.** Before introducing a new input shape to a harness primitive (TRANSITION token format, fixture shape, scenario field), property-test the primitive against the full enumeration of input shapes. See `docs/lessons/test-harness-primitives.md`.
- **Scope-symmetry at mitigate time.** Before sealing a mitigation, grep the canonical source for every place the same mechanism appears and confirm the fix applies uniformly. See `docs/lessons/scope-symmetry.md`.
- **`not_contains_strict: true` is structurally fragile when the failing skill is not the skill under test.** Strict mode is only for *failure-proxy* phrases (appear only when the failure mode is happening), not *informational* ones that can appear in benign reasoning. See `docs/lessons/test-scenario-strict-mode.md`.
- **`build_metrics` empty-window contract (claude-time / viz_data.py).** When wrapping `build_metrics` from a coordinator that knows the window bounds, always pass real window dts even on empty events — otherwise `window.start/end → ""` and `day_count → 0`. Inline comment at `tools/claude-time/viz_data.py:1046`.
- **Design-as-data byte-pin / v3 sub-payload routing (claude-time viz history).** Historical context for the byte-pin → editable-files transition, design-canvas/InteractiveToolbar collapse, and v2-alias-fallback useMemo pattern (retired 2026-06-03). See `tools/claude-time/docs/design-extract-history.md`.
- **Calendar-anchored vs rolling-N-days defaults for time-range CLI flags (claude-time visualize pattern).** When the default value of a time-range flag flows into a payload whose sub-views are *grouped by calendar boundaries* (month, week, quarter), pick a **calendar-anchored** default — not rolling-N-days. Rationale: rolling-N from-today produces a partial-period leading slice that looks broken in the consuming UI. Concrete instance: v3 WP3 (2026-05-29) changed `claude-time visualize`'s default `--window` from rolling-90 to `MTD-2` (current calendar month + 2 priors, ending today) because rolling-90 from late May produces a near-empty Feb 28 in the Month-view payload — a UX surprise invisible at the data layer but load-bearing in the consumer UI. The day-count then varies (59–92 days across the calendar for `MTD-2`) — that's expected and fine; WP2 perf measurements showed cost is approximately flat across 30→120-day windows, so the variance is free. Apply this when: (1) the flag's default will be the most-frequently-emitted value, (2) at least one consumer groups by calendar period, (3) the consumer's "empty leading period" rendering is visible to the user. Skip when: the consumer treats the window as a flat list of days with no calendar grouping (e.g. raw event dump, line-chart-over-N-days).
- **Cross-layer contract migration on architectural-boundary moves.** When deleting a code path that *attaches* fields to a shared payload (e.g. v2's `_cmd_visualize._metrics_for_window` attachment to `comparison.{a,b}.metrics` in the claude-time visualize emit), the contract those fields satisfy must migrate to the new layer that *owns the shape* (e.g. `build_window_data` in `viz_data.py`) — not silently disappear with the deleted code. This is the cross-layer sub-case of the "Plan-level downstream contract impacts pass" bullet above. **Practical application:** when a phase deletes code that touches a shared payload, at plan time (a) grep the deleted code for `<payload>["<field>"] = ` / `<payload>.<field> = ` attachment patterns; (b) grep the codebase + tests for downstream **consumers** of those fields (including destructured reads — `const {field} = payload` — and sub-key reads — `payload.foo.field`); (c) if any consumers remain, plan an explicit re-attachment step in the **same phase** that does the deletion, in whichever layer now owns the payload shape. The verify-codify Test Triage gate is a safety net for this; the plan-time grep is the discipline that keeps the safety net from being load-bearing. Three instances of this pattern firing post-hoc: 2026-05-10 incident-codify scenario contract miss, 2026-05-29 WP3 Phase 2 verify-codify alias-key audit miss, 2026-05-29 WP4 Phase 3 verify-codify `comparison.{a,b}.metrics` regression. Each was caught at verify-codify rather than plan-time; the pattern is real and worth surfacing at plan-time grep, especially when the work involves crossing CLI/data-layer boundaries.
- **Plan-time downstream-contract-impacts grep must include literal-payload-object assertions, array-length assertions, literal function-signature strings, AND literal variable-binding-name strings — not just key-name greps.** Sub-case of the "Plan-level downstream contract impacts pass" + "Cross-layer contract migration" bullets above. When a phase changes ANY shape that tests grep against, key-name grep alone is insufficient — there are 4 known fragile subcases. **Sub-case A — literal-payload-object (function-call form).** When a phase adds a new key to a payload-object passed to a function (e.g. `updateHash({...})`, `setState({...})`), tests grepping the literal patch-object string break. Pattern: `grep -F "updateHash({ view: " ./tests`. Caught 2026-06-03 during v3 WP5 P1.2 (added `date:` key to 5-branch `updateHash` dispatcher; broke 4 of 5 literal pin strings). **Sub-case B — array-length-add.** When a phase extends an array of known cardinality (tile lists, route arrays, filter-kind enums, schema fields, status enums), tests asserting `.length === N` or `.length >= N` break. Pattern: `grep -RE "tileIds\.length\s*===\s*\d+" ./tests`. Caught 2026-06-06 during v3 WP11 P2 (added 4th `away` tile broke `tileIds.length === 3` — relaxed to `>= 3`) and again at WP12 P2 (adding 5th `parallel` tile — relaxed `=== 4` to `>= 4` + slice-equals on first 4). **Sub-case C — literal-function-signature.** When a phase adds a default-param or destructured-prop to an existing function (`function NAME({ a, b }) → function NAME({ a, b, c = 0 })`), tests grepping the LITERAL function signature break. Pattern: `grep -RE "function (HeadlineCard|MyComponent|...)\(\{" ./tests`. Caught 2026-06-06 during v3 WP12 P2.1: added `parallelMs = 0` to HeadlineCard's destructure; `test_visualize_cli.sh:2832` grep-pinned the pre-WP12 literal signature — relaxed to regex `function HeadlineCard\(\{ metrics, expanded, onToggleExpanded, awayMs = 0` (tolerant of trailing params). **Sub-case D — literal-variable-binding-name.** When a phase changes a variable-binding name (`const overlaps = useOverlaps()` → `const ctx = useOverlaps()` because the hook now returns a wider shape requiring unpacking), tests grepping the literal binding break. Pattern: `grep -RE "const \w+ = useOverlaps\(\)" ./tests`. Caught 2026-06-06 during WP12 P2.verify-human.2 F12 back-loop: the OverlapsContext value gained a `sessionToProject` map, so all 3 useOverlaps call sites unpacked via `const ctx = useOverlaps()` — `test_visualize_cli.sh:3018` pin on `const overlaps =` broke. Relaxed to count-based `≥3 'const ctx = useOverlaps()'`. **8 observed instances of `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS`** across all 4 subcases (1st = 2026-05-10 incident-codify [key-name], 2nd = 2026-05-29 WP3 P2 [key-name], 3rd = 2026-05-29 WP4 P3 [cross-layer], 4th = 2026-06-03 WP5 P1.2 [subcase A], 5th = 2026-06-06 WP11 P2 [subcase B], 6th = 2026-06-06 WP12 P2 [subcase B], 7th = 2026-06-06 WP12 P2 [subcase C], 8th = 2026-06-06 WP12 P2 F12 back-loop [subcase D]). Pattern is now well-established; the backlog item proposing to codify this into `feature-plan` SKILL.md as a mechanical step remains pending — until then, this convention is the doc-side fallback. **All subcases share the same prevention mechanism:** before sealing a phase's impl tasks, grep tests + downstream consumers for ANY assertion against the shape being changed — including literal function-signature strings AND literal variable-binding-name strings when changing function parameters or hook return shapes.
- **v3 sub-payload routing pattern: useMemo with v2-alias fallback (claude-time visualize WP5–WP9 transition convention — HISTORICAL, retired 2026-06-03).** *Status:* Retired at WP9 Phase 2 (v3 cycle close). The v2 alias keys (`today`, `week`, `comparison`, `months`, `meta`) have been stripped from the CLI emit; each useMemo is now primary-only (e.g. `dayPayload = dayPayloadsByIso[dayIso] || <empty Day-like shape>`). Custom view's `customPayload` useMemo (the bridging case) now returns an empty Day-like payload for out-of-window ranges and `onRangeChange` surfaces a reload-redirect toast. *Pattern history (kept for context):* `viz_render.py::_interactive_dashboard` reads data sources keyed by view (Day/Week/Month/Compare/Custom). v3 routes each view's data through its sub-payload map (`day_payloads_by_iso`, `week_payloads_by_monday`, `month_payloads_by_iso`, `compare_payloads_by_preset`). During WP5–WP9-P1 the useMemo had a v2-alias fallback (`return today;` etc.) to let shared render code paths (like `isDayLike` which Day + Custom share) stay un-forked while WPs migrated their consumer surfaces one at a time. The fallback turned out to be the correctness mechanism for Custom-view coexistence; WP9 Phase 1 made `customPayload` (the cross-day union over `day_payloads_by_iso`) the load-bearing primary path, and WP9 Phase 2 stripped the alias keys + pruned the now-dead fallbacks. *Applied to 5 of 5 sub-payload views (Day/Week/Month/Compare/Custom).* Future WPs in any new transition cycle can copy this approach — bridging useMemo + per-WP migration + cycle-close strip — as a template for safely retiring a contract surface.
- **Build-time selector-emission discipline: when the plan declares a `[data-*]` selector in observable outcomes, grep the source after writing each impl task to confirm the literal attribute emits.** Sibling principle to the "Plan-time downstream-contract-impacts grep" + "Cross-layer contract migration" + cross-file edit-time-transform anchor disciplines (all three are facets of: plan-time contract declarations need build-time mechanical verification, not visual cross-check). When a phase's Observable Outcomes cite a `[data-foo]` selector (Browser:/Console: lines in the WIP tree), the selector is an aspirational contract — the source must emit the literal attribute on the rendering element for verify-self to PASS. **Practical grep at build time:** after each impl task that the plan declares observable selectors against (typically tasks that write JSX / HTML / template code), run `Grep` against the just-edited file for each declared selector, confirm count > 0 AND the attribute lands on the correct element (not a parent wrapper, not a stale code path). Skipping this step shifts the verification cost to verify-self (F9b back-loop) or — worse — to verify-human if the selector is only used by tests that haven't been written yet. Caught 2026-06-06 during v3 WP11 P1 verify-self: two source-side selector gaps slipped through Phase 1 build (P1.4-extension: SessionRow root div missing `data-session-row` despite the plan declaring it as an observable affordance; P1.7-extension: expanded-branch wrapper `<div data-project-row data-expanded="true">` duplicated `data-project-row` with the inner ProjectHeaderRow, inflating document.querySelectorAll counts). Cost: 1 F9b back-loop, ~30 min investigation, 2 source edits. Both were trivial to fix once located; the cost was the location step. A mechanical post-write grep would have caught both at build time and shortened the cycle by one verify-loop iteration.
- **Verify-codify full-group sweep discipline — use `--filter-model default` to avoid haiku-on-sonnet retry storms.** When running `./tests/run-tests.sh --group <group> --model haiku` during a feature's verify-codify, sonnet-tagged scenarios in that group will burn `max_retries + 1 = 3` attempts each on haiku before being scored. With ~6 sonnet-tagged scenarios in the feature group (see `SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG`), this can blow a 5-min budget to 30+ minutes. Practical rule: split the sweep — `./tests/run-tests.sh --group <group> --filter-model default` for the haiku partition, then `./tests/run-tests.sh --filter-model sonnet --model sonnet` for the sonnet partition. Observed 2026-06-07 during verify-human-auto-skip-when-no-integration-boundary Phase 2: full feature-group sweep was killed at 30+ min after F32 retries hung; targeted re-run of the new scenarios alone (45s) + partial sweep through 55+/60 (naturally completed) gave sufficient signal. The existing `tests/run-all.sh` two-pass wrapper does this automatically when working — but per `SURFACE-2026-06-06-RUN-ALL-UNBOUND-FORWARD-ARGS` it crashes on empty FORWARD_ARGS, so the manual two-invocation pattern is the current workaround.
- **Verify-self in-place fix shortcut — formalized 2026-06-09 in `skills/feature-verify-self/SKILL.md` §3 → "In-place fix shortcut (BLOCKING-fail handling — narrow exception)".** Rule of three was reached 2026-06-07 (v3 WP3 Phase 2 on 2026-05-29, v3 WP11 Phase 1 on 2026-06-06, verify-human-auto-skip-when-no-integration-boundary Phase 2 on 2026-06-07 — all three ad-hoc, user-approved at verify-human). The codified clause permits a narrow in-place fix when **all three gates** hold: (a) trivial extension of the just-completed leaf, (b) fresh model invocation re-verifies (fresh subagent or fresh skill invocation — same-agent re-reading does NOT count), (c) audit-trail entry `[SHORTCUT-<date>] <leaf-id> — <what+how>` appended to the WIP `## Discoveries`. The SKILL.md clause is the authoritative procedure; this note exists as the convention-doc pointer.
