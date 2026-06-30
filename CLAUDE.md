# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

This is the **source** repository for a Claude Code workflow system — a collection of skills and orchestrator agents that implement a state-machine-driven workflow hierarchy (Product → Feature → Task, plus Incident and Session meta-operations).

The skills and agents here are **symlinked into `~/.claude/`** by `install.sh`. Editing a file here immediately affects the live Claude Code configuration on this machine — there is no build step. Conversely, the repo is not self-contained software: the skills only run when invoked through Claude Code.

## Artifact tracking overrides

This repo overrides the default artifact tracking MAP (`~/.claude/CLAUDE.md` → `## Artifact tracking policy (GLOBAL)`). **This repo IS the global learning-assets / workflow-system source repo** — so artifacts that are throwaway *drafts* in other projects are first-class tracked *content* here:

- **Track `<proj-dir>/.claude/learnings/`** — these are curated, durable lessons (the whole point of this repo), not drafts-to-port. They are committed, not parked.
- **Track `<proj-dir>/.claude/memory/`** (+ `MEMORY.md`) — the auto-memory store is versioned here. Per the policy's PII clause, any individual memory carrying secrets/PII is redacted in place or added to `.gitignore` file-by-file (expected rare); the directory itself is tracked.

All other MAP defaults apply unchanged (e.g. `<proj-dir>/.claude/settings.local.json` and `workflow/.session.md` stay ignored).

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
- **Agents** (`agents/<name>/AGENTS.md`) — two kinds, distinguished by frontmatter shape:
  - **Reference-only orchestrator agents** (frontmatter has `skills:`): one per workflow group (product, feature, task, incident). Hold the full state-machine view and an **Orchestration Procedure** section that `/session-start` reads as an instruction set. NOT meant to be spawned via `Agent({subagent_type: ...})` — they are reference documents.
  - **Executable subagents** (frontmatter has `tools:`): spawned by skills that name them via `Agent({subagent_type: '<name>', ...})`. Currently: `feature-verify-self-runner` (spawned by `feature-verify-self`) and `code-quality-reviewer` (spawned by `feature-review-quality`). The `tools:` frontmatter declares the subagent's tool surface and is the structural marker that distinguishes these from reference-only agents (enforced by `tests/check-structure.sh` Phase 10 "Subagent dispatch wiring"). Introduced 2026-06-12 by the verify-self-and-review-quality-subagent-dispatch feature.

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

**"Phase" vs. "Milestone" — two different artifacts, do not conflate.** The feature **Work Tree** uses **"Phase"** (`Phase 1`, `P1.1`) for the per-feature build-loop units — that schema is load-bearing and stays. The product **roadmap** uses **"Milestone"** (flat, singly-numbered) for its strategic decomposition unit; product-workflow skills treat "phase" as a backward-compat **read-alias** for "milestone" when reading older roadmaps. Renaming the roadmap unit to "Milestone" (shipped 2026-06-18, `docs/lessons/product-skills-milestone-terminology-and-wbs-scope.md`) deliberately did **not** touch the feature Work Tree's "Phase."

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
- **feature-review-quality per-feature code-quality reviewer (feature workflow).** A new state sits between `feature-ship` and `feature-finalize` invoking a one-shot Agent reviewer subagent against the ship commit baseline. Severity-tier action matrix is advisory by default with operator-veto: **CRITICAL** → auto-invokes `feature-refactor` (F40, Modes 2-3); **MAJOR** → Mode 2 pause-and-ask (F41) or Mode 3 auto-backlog with prominent chat surface (F39, preserves "verify-human is the ONLY autopilot pause" invariant); **MINOR** → auto-backlog (F39). **Mode 4** (fsd) skips the skill entirely — `feature-ship` emits F17b directly to finalize when WIP frontmatter shows `drive_mode: fsd`. Transition surface: F38 (ship → review-quality), F39 (review-quality → finalize, clean/MINOR/Mode-3 MAJOR), F40 (review-quality → refactor, CRITICAL), F41 (review-quality → finalize, Mode-2 MAJOR after pause-and-ask), F17b (ship → finalize direct, Mode-4 SKIP). F17 retired. Reviewer prompt body lives at `agents/code-quality-reviewer/AGENTS.md` — an executable subagent definition (~150 lines, tuned to this codebase's SKILL.md/AGENTS.md/scenario-YAML/structural-pin patterns; tripartite output: Strengths / Issues by severity / Assessment). The skill invokes it via `Agent({subagent_type: 'code-quality-reviewer', ...})` per the verify-self-and-review-quality-subagent-dispatch feature (2026-06-12 — moved from `skills/feature-review-quality/reviewer-prompt.md` into the agent definition so the spawn has a real target). The reviewer is observe-only (no Edit/Write tools); findings flow forward into refactor or backlog. Operator's read-time veto: edit `## Code-Quality Review` section in WIP and mark findings `[DISMISSED]` before finalize archives the file. Diverges from `obra/superpowers`' per-task "all findings block" model — post-ship placement makes back-loops on shipped commits expensive, so advisory-default + read-time veto is the recovery surface. See `skills/feature-review-quality/SKILL.md` for the full procedure. Shipped 2026-06-11 from SURFACE-2026-06-02-CODE-QUALITY-REVIEWER-SUBAGENT.
- **Close-commit discipline (workflow-system convention).** The four terminal-close skills (`feature-finalize`, `task-close`, `incident-resolve`, `product-finalize`) commit locally and DO NOT auto-`git push` — pushing is the operator's call (review window for squash/amend/follow-up-learning before publishing). This codifies pre-existing behavior as a load-bearing contract so future drift cannot reintroduce auto-push. **`session-store-learning`** project-scope writes additionally `git add` + `git commit --amend --no-edit` after writing the learning file, folding the artifact into HEAD (typically the just-completed close commit per the post-reflect cadence). The amend prevents "uncommitted learning file lost in destructive git ops during the next cross-feature pause" (closed SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH). Global-scope writes follow the artifact tracking policy (see `## Artifact tracking policy (GLOBAL)` in `CLAUDE.snippet.md` + this repo's `## Artifact tracking overrides` below): if the project IGNORES `<proj-dir>/.claude/learnings/` (the default), the draft is left uncommitted for hand-porting; if the project OVERRIDES to TRACK it (as this repo does), it is amended into HEAD like a project-scope write. The discriminator is the policy/override, NOT gitignore inspection (artifact-tracking-policy feature, 2026-06-25 — superseded the earlier "global drafts are always gitignored, opt out of amend" rule). Enforced by `tests/check-structure.sh` [Phase 11] — 6 `grep_check` pins (4 no-push + 2 amend). Behavioral signal at `tests/scenarios/{feature,task,incident,product,session}.yaml::{F19,T10,I10,P13}-no-auto-push + S20-amend-head`. Shipped 2026-06-12.
- **Test triage at verify-codify:** any test failure requires a `## Test Triage — <name>` block in the WIP file before any file is modified. Six cases: code regression (high/low), obsolete test (high/low), contract conflict (always pause), flaky (re-run 3x then pause). High confidence = failure has exactly one plausible explanation, stateable in one sentence without hedging.
- **Integration-boundary rule** in the per-phase verify loop: when a phase modifies code inside an existing endpoint, UI, CLI, job, or external call site, verify-self must include an outcome citing the consuming surface, verify-human cannot use the F11 skip path, and verify-codify must include a test on the consuming surface. Full rule in each `feature-verify-*/SKILL.md`.
- **Test scenario `expect:` fields** — `transition_id` (single match) is the standard. Use `transition_id_any: [A, B, C]` when a scenario has dual identity (e.g., a session-orchestrator step that is genuinely emitting an F-ID of the workflow it's driving). Use `not_contains_strict: true` when content-mismatch is a real behavior bug (e.g., "auto-chain" appearing in autopilot mode); the default lenient mode treats `not_contains` hits as warnings only. Use `contains_required: [X, Y, Z]` to hard-assert that ALL listed strings appear in `result_text` (AND-fanout); `contains_required_any: [X, Y, Z]` to hard-assert that AT LEAST ONE appears (OR-fanout). Both fields enforce content presence even on a `transition_id` match — unlike `contains_any`, which only fires as a SOFT_PASS fallback when the structured ID is absent. Use these when the verifiable surface is "the model emits the right downstream prose" and a structural `grep_check` in `check-structure.sh` cannot exercise the model. First pilot use: `P10b` in `tests/scenarios/product.yaml` (added 2026-06-13 by the `verify-sh-contains-required` feature).
- **Test scenario design — routing-fork patterns.** Three sub-patterns when scenarios test branch-choice from the same parent state: variant routing needs dedicated fixtures; entry-state transitions need a different shape than exit transitions (`transition_id_any`, avoid aggressive `not_contains`); default-skip-on-ambiguous rules need unambiguous inputs. See `docs/lessons/test-scenario-routing-forks.md`.
- **Plan-time downstream-contract-impacts grep.** When a phase modifies a contract that existing artifacts already assert against, flag affected artifacts in the same phase — not later. Covers key-name greps, literal-payload-object, array-length, function-signature, variable-binding subcases, the cross-layer attachment-migration sub-case, and `[data-*]` selector-emission. See `docs/lessons/downstream-contract-impacts.md`.
- **Per-project `CHANGELOG.md` convention.** Every project that uses this workflow system maintains a human-readable `CHANGELOG.md` at its root. The four terminal-close skills (`feature-finalize`, `task-close`, `incident-resolve`, `product-finalize`) auto-append one-line entries on close (`**Feature shipped:**`, `**Task closed:**`, `**Incident resolved:**`, `**Backlog resolved:**`, `**Milestone:**`, `**Product cycle complete:**`). The canonical procedure — file shape, heading case, same-day grouping, append-before-`git mv` discipline — lives in `CLAUDE.snippet.md` under `## CHANGELOG.md convention` and is injected globally into `~/.claude/CLAUDE.md` by `install.sh`. Each closing SKILL references the snippet rather than inlining the rules. Resolved backlog items belong in CHANGELOG, not in a `## Resolved` section inside `workflow/backlog.md`.
- **`debug-*` skill category convention.** `debug-*` skills are agent-pulled sidebars (not workflow states). They emit descriptive `DEBUG-<TECHNIQUE>-<OUTCOME>` tokens (outside the F/I/T/P/S namespace) plus a `RETURN-TO: <caller>` line, run to completion, and return to the caller workflow state without consuming any transition ID. Required SKILL.md sections (`## When to use`, `## When NOT to use`, `## Procedure` with Gate Check, `## Pitfalls`, `## Termination`) are enforced by `tests/check-structure.sh` Phase 3b. Caller-skill prose mentions + orchestrator AGENTS.md "Debug techniques" subsections + `transitions.md` "Sidebar skills" note give the agent the discoverability surfaces it needs; these are also enforced (Phase 3c). Full category convention lives in this file's Architecture section under "`debug-*` Skill Category".
- **Adding a new `debug-*` skill / introducing any category-level convention.** Recipe (4 artifact kinds: SKILL.md scaffold, 3 fixtures, 3 scenarios, Phase 3c structural pins; +16 PASS projection per new debug-* skill) plus two underlying disciplines (three structurally-enforced discoverability surfaces; harness-visible structural marker, not just a doc marker). See `docs/lessons/debug-skill-template.md`.
- **Test-harness primitives need property-testing across the full input namespace.** Before introducing a new input shape to a harness primitive (TRANSITION token format, fixture shape, scenario field), property-test the primitive against the full enumeration of input shapes. See `docs/lessons/test-harness-primitives.md`.
- **Scope-symmetry at mitigate time.** Before sealing a mitigation, grep the canonical source for every place the same mechanism appears and confirm the fix applies uniformly. See `docs/lessons/scope-symmetry.md`.
- **`not_contains_strict: true` is structurally fragile when the failing skill is not the skill under test.** Strict mode is only for *failure-proxy* phrases (appear only when the failure mode is happening), not *informational* ones that can appear in benign reasoning. See `docs/lessons/test-scenario-strict-mode.md`.
- **`build_metrics` empty-window contract (claude-time / viz_data.py).** When wrapping `build_metrics` from a coordinator that knows the window bounds, always pass real window dts even on empty events — otherwise `window.start/end → ""` and `day_count → 0`. Inline comment at `tools/claude-time/viz_data.py:1046`.
- **Design-as-data byte-pin / v3 sub-payload routing (claude-time viz history).** Historical context for the byte-pin → editable-files transition, design-canvas/InteractiveToolbar collapse, and v2-alias-fallback useMemo pattern (retired 2026-06-03). See `tools/claude-time/docs/design-extract-history.md`.
- **Calendar-anchored vs rolling-N-days defaults for time-range CLI flags (claude-time visualize pattern).** When the default value of a time-range flag flows into a payload whose sub-views are *grouped by calendar boundaries* (month, week, quarter), pick a **calendar-anchored** default — not rolling-N-days. Rationale: rolling-N from-today produces a partial-period leading slice that looks broken in the consuming UI. Concrete instance: v3 WP3 (2026-05-29) changed `claude-time visualize`'s default `--window` from rolling-90 to `MTD-2` (current calendar month + 2 priors, ending today) because rolling-90 from late May produces a near-empty Feb 28 in the Month-view payload — a UX surprise invisible at the data layer but load-bearing in the consumer UI. The day-count then varies (59–92 days across the calendar for `MTD-2`) — that's expected and fine; WP2 perf measurements showed cost is approximately flat across 30→120-day windows, so the variance is free. Apply this when: (1) the flag's default will be the most-frequently-emitted value, (2) at least one consumer groups by calendar period, (3) the consumer's "empty leading period" rendering is visible to the user. Skip when: the consumer treats the window as a flat list of days with no calendar grouping (e.g. raw event dump, line-chart-over-N-days).
- **Verify-codify full-group sweep discipline.** Split haiku-vs-sonnet sweeps with `--filter-model default` and `--filter-model sonnet --model sonnet` to avoid haiku-on-sonnet retry storms. See `docs/lessons/test-harness-sweep-discipline.md`.
- **Verify-self in-place fix shortcut — formalized 2026-06-09 in `skills/feature-verify-self/SKILL.md` §3 → "In-place fix shortcut (BLOCKING-fail handling — narrow exception)".** Rule of three was reached 2026-06-07 (v3 WP3 Phase 2 on 2026-05-29, v3 WP11 Phase 1 on 2026-06-06, verify-human-auto-skip-when-no-integration-boundary Phase 2 on 2026-06-07 — all three ad-hoc, user-approved at verify-human). The codified clause permits a narrow in-place fix when **all three gates** hold: (a) trivial extension of the just-completed leaf, (b) fresh model invocation re-verifies (fresh subagent or fresh skill invocation — same-agent re-reading does NOT count), (c) audit-trail entry `[SHORTCUT-<date>] <leaf-id> — <what+how>` appended to the WIP `## Discoveries`. The SKILL.md clause is the authoritative procedure; this note exists as the convention-doc pointer.
- **Bootstrap-skip covers edited Skill SKILL.md content, not just new artifacts.** When a feature edits an existing `skills/<name>/SKILL.md` and re-invokes that skill mid-session, the harness serves OLD pre-edit prose, not the freshly-edited file on disk. Validate via `tests/run-tests.sh` (fresh subprocess) or accept bootstrap-skip-defer to a future session. See `docs/lessons/harness-bootstrap-skip.md`.
- **Verify-codify leaf substitution discipline.** When marking any Work-Tree verify-* leaf complete, substitute the existing `- [ ] ...` line in place — never append a new `[x]` line above the existing NOT-STARTED line (leaves the parent un-closeable under the all-children-`[x]` rule). See `docs/lessons/work-tree-leaf-substitution.md`.
- **Path-qualification mandate (skill/agent prompt authoring).** Every `.claude/` reference in a `skills/*/SKILL.md` or `agents/*/AGENTS.md` prompt MUST be explicitly qualified: `~/.claude/` (the home/global Claude Code config dir, shared across all projects on the machine) or `<proj-dir>/.claude/` (the current project's own `.claude/` dir). **Bare `.claude/` is forbidden in prompt prose** — unqualified, the agent must infer home-vs-project at read time and infers inconsistently across sessions (this was the root cause of the non-deterministic learning-destination bug fixed by the artifact-tracking-policy feature, 2026-06-25). Allowed exceptions: literal `.gitignore` patterns inside ``` fenced code blocks (gitignore patterns are repo-relative and bare by necessity) and the backtick-quoted generic token `` `.claude/` `` used when discussing the notation itself. Enforced by `tests/check-structure.sh` Phase 12 (`no bare .claude/ in skills/ agents/ CLAUDE.snippet.md`). This is a this-repo authoring convention — the cross-project *policy* (track-by-default + canonical MAP + override) lives in `CLAUDE.snippet.md` → `## Artifact tracking policy (GLOBAL)`; the qualification *rule* is about authoring these prompts and stays here.
- **Design priors convention (consult + capture).** `docs/product/design-priors.md` is a per-project, deterministically-loaded record of the operator's **product-design decision leans** (focus-vs-breadth, perf-vs-ship, anti-persona, …), each paired with an inferred-why + corrected-why (the gap preserved as the learning signal). It exists to fill the ~10% of product-design gaps where the operator's project-specific lean differs from the "average" common-sense fill, without re-teaching it each feature. Three planning skills **consult** it at Step 0 (`product-roadmap`, `product-wbs`, `feature-spec`) under five weighting rules — the load-bearing one being the **over-infer guard** (a prior only fires on the axis it governs; never stretch it) and **contradiction → propose-never-steer**. Six checkpoints + a `session-reflect` backstop **capture** new priors **propose-never-auto-write** (operator reviews/enriches the why; dedup/conflict-checked; technical/stack tradeoffs excluded → they stay in `arch.md`). Disclosure form when a prior fires: `[PRIOR: <slug>] leaning <x> — flag if wrong`. Priors are directional + overridable, never decisive — the 90% common-sense path is untouched. Canonical contract: `CLAUDE.snippet.md` → `## Design priors (GLOBAL)`; schema: `arch.md` → File Schema: Design Priors; enforced by `tests/check-structure.sh` [Phase 13] + behavioral scenarios `tests/scenarios/product.yaml::DP-*` (consult-changes / over-infer-NOCHANGE / no-prior-90%-path / contradiction / capture-fires / capture-skips-fact / capture-skips-arch). **Reverting:** git tag `pre-design-priors` (full rollback) + `grep -rl "design prior\|design-priors\|\[PRIOR:" skills/ docs/ CLAUDE.snippet.md tests/` (surgical removal) — see the feature's archived WIP `## Reverting this feature`. Behavioral/prose-only; flagged at build time as carrying over-noise risk, hence the easy-revert net. Shipped 2026-06-26 from the `infer-dev-intent-one-level-deeper` learning.
- **`util-backlog-paydown` skill (between-milestone backlog-paydown sweep).** A `util-*` standalone operator-triggered skill (`skills/util-backlog-paydown/SKILL.md`) that runs a focused pass at a clean cycle boundary to clear the accumulated code-quality/debt backlog (the rolled-forward `/feature-refactor` batch). It scores every backlog item on a **3-axis disposition model** — Impact (= feature-value + maintainability, where maintainability = quality × P(future-touch)), Effort (benchmarked against *the consuming project's own* archived WBS/WIP units), Risk (suite-relative) — and assigns one of **5 actions**: Sweep / Discuss / Defer / Bury / Delete. Load-bearing rule: **cheap+safe → ALWAYS Sweep, no exception** (de-cluttering the backlog is itself an impact term). **Operator-veto is first-class** (a "not wanted / out-of-scope / gated" ruling bypasses axis-scoring → direct Delete/Defer). Supports dual scoring fidelity (full table for a raw backlog; light-touch prose+size for a pre-groomed bucket). Emits a `shape: temporary-wbs` (NOT a roadmap milestone) with a "what's NOT swept — anchors intact" scope section + a **fold-back-and-delete** completion section; the operator then drives each WP through `/feature-refactor` or `/task-*`. As a `util-*` skill it emits **no transition** and is **not** wired into any orchestrator (see `arch.md` → util-* category; no new `check-structure.sh` pin per the documented util-* status quo). `product-finalize` §4 carries an **advisory** (non-chaining) pointer here. Behavioral coverage: `tests/scenarios/util.yaml` — disposition cases generalized/redacted from two real regression sessions (Claudesk 2026-06-30 debt sweep; replicator-1-0 2026-06-20 sweep family), which are the model's regression suite. Full pattern + provenance + cross-validation: `docs/lessons/between-milestone-debt-paydown-sweep.md`. Shipped 2026-06-30.
