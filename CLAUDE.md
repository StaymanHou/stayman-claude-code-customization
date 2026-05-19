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

## Conventions

- `install.sh` is idempotent. Re-run after adding or renaming a skill/agent directory — it will create new symlinks and update any whose target has changed.
- Skill frontmatter fields: `name` (matches the directory), `description`, optional `argument-hint`.
- Agent frontmatter includes a `skills:` list — this must match the directories that exist under `skills/`.
- When the PR description references a transition, use the ID from `docs/product/transitions.md` (e.g. "Fixes F12 back-loop wording"), not the state names alone.
- **Orchestrator pause policy** has a dual location since the 2026-05-17 autopilot-pause-policy-recheck mitigation. The **canonical table** lives in `agents/feature-workflow/AGENTS.md` (single source of truth, full state-machine view). Each feature SKILL.md (`feature-spec`, `feature-research`, `feature-plan`, `feature-build`, `feature-verify-auto`, `feature-verify-self`, `feature-verify-human`, `feature-verify-codify`) also carries an `## Orchestrator Pause Policy (cheat-sheet)` block with **per-skill rows only** (just that skill's own exits) plus a `Hard rule for AUTO exits` imperative — this lives next to the transition emission so the orchestrator reads it at every Skill invocation, mitigating narrative-cadence drift from AGENTS.md being read once at session start. `TRANSITION: <id>` remains the machine signal; "Run `/x`" prose is advisory for single-step users only. The presence of the per-skill blocks is enforced by `tests/check-structure.sh` Phase 9 (24 assertions). Drift between AGENTS.md and the per-skill rows is *not* yet enforced — followup tracked as `SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT` (task:plan, medium).
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
- **A new skill category needs three structurally-enforced discoverability surfaces, not one.** When introducing a category-level convention (e.g. the `debug-*` category, or any future `<prefix>-*` family), the agent that ultimately invokes the skill reads only (a) its own SKILL.md, (b) the orchestrator's AGENTS.md, and (c) the caller-skill's prose. It does NOT read CLAUDE.md or `docs/product/transitions.md` at invocation time. So a category convention documented only in CLAUDE.md will not be discovered by the agent in practice. Structurally enforce all three surfaces: (1) caller-skill prose mentions in each caller's SKILL.md, (2) "<Category> techniques" subsection in each relevant orchestrator's AGENTS.md, (3) cross-level mechanism note in `transitions.md`. Codify the surfaces via `tests/check-structure.sh` so regression on any one is caught. The CLAUDE.md convention doc is the *author-facing* reference; the three structural surfaces are the *agent-facing* discoverability. Caught 2026-05-14 during the `debug-*` category feature.
- **Test-harness primitives need property-testing across the full input namespace.** A primitive that has "always worked" may only have been exercised by one shape of input. Before introducing a new input shape to a harness primitive (a new TRANSITION token format in `tests/lib/verify.sh`, a new fixture shape in `tests/run-tests.sh`, a new scenario field, etc.), property-test the primitive against the full enumeration of input shapes — not just the one you're about to ship. Caught 2026-05-14 during the `debug-*` category feature: `tests/lib/verify.sh` regex had a `[A-Za-z0-9_]` character class that worked correctly for 131 alphanumeric scenario TRANSITION IDs but truncated the first hyphenated debug-class token (`DEBUG-BISECT-SKIP` → captured `DEBUG`). The fix added the property-test as a permanent `[Phase 3d]` check in `tests/check-structure.sh`.
- **Scope-symmetry at mitigate time.** When applying a fix whose mechanism would also apply to symmetric places in the codebase (e.g., a structural fix to AUTO transitions in *one* part of the state machine), audit the full namespace before declaring scope. Practical application: before sealing a mitigation as "done", grep the canonical source (AGENTS.md, transitions.md, the state machine schema) for *every* place the same mechanism appears, and ask "does this fix uniformly apply, or am I about to ship a partial fix?" Caught 2026-05-17 during the autopilot-pause-policy-recheck-regression incident: per-phase mitigation was scope-extended mid-workflow when the user observed the same failure mode in `feature-spec` and `feature-plan` — the symmetric `feature-research`, `feature-spec`, `feature-plan` skills needed the same cheat-sheet block and were caught only because the user spoke up. Pre-mitigation audit would have caught it in one pass.
- **`not_contains_strict: true` is structurally fragile when the failing skill is not the skill under test.** Strict `not_contains` lists are catching "phrases that indicate the failure mode" — but the model can produce those phrases for benign in-context reasons (e.g., a session-orchestrator scenario producing "waiting for the dev URL" in a correct chain). When a scenario's `skill:` is one piece (e.g. `session-start`) and the `not_contains` patterns target failure shapes that originate elsewhere, strict mode raises noise-FAILs that look like regressions. Practical application: before tagging a scenario `not_contains_strict: true`, ask whether each `not_contains` phrase is a *failure proxy* (only appears when the failure mode is happening) or *informational* (could appear in benign in-context reasoning). Strict mode is for the former only. Caught 2026-05-17 when S25 FAILed on "waiting for" during the autopilot-pause-policy mitigation test sweep but PASSed on isolated re-run — pure model variance, not a regression.
- **Design-as-data: byte-pinned source + emit-time transforms (claude-time viz/ pattern).** The files in `tools/claude-time/viz/` (`dashboard.jsx`, `data.js`, `index.html`, `design-canvas.jsx`) are the **Claude Design extract**, treated as immutable source-of-truth for the dashboard's visual contract. They are **byte-pinned** by `tests/check-structure.sh` Phase 5c — any edit, even a single byte, fails structure-check. To produce the shipped `claude-time visualize` HTML, `tools/claude-time/viz_render.py` applies **emit-time text-replacement transforms** over the unmodified source (strips the DesignCanvas chrome, wires interactive state, adds the InterruptHairlines component, appends a new interactive Dashboard wrapper, substitutes `{{CT_DATA_JSON}}` and `{{CT_INITIAL_VIEW}}` placeholders into `viz/template.html`). The trade-off accepted: text-replace transforms are brittle to source edits, but the byte-pin enforces immutability so the brittleness can't bite. When the design itself genuinely needs to change (re-import from Claude Design), update the source files AND update the expected byte sizes in Phase 5c's `VIZ_FILES` array in lockstep. Don't try to "fix" the brittleness by editing the source — fix it by extending `viz_render.py`'s transforms. Caught 2026-05-19 during the claude-time-visualize feature.
