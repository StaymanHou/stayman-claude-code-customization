---
name: verify-self-and-review-quality-subagent-dispatch
workflow: feature
state: verify-codify (all phases complete)
created: 2026-06-12
entry: reproduce (bug-fix feature) → spec (F32, complex) → plan (F4) → build → ship next
drive_mode: autopilot
backlog_source: SURFACE-2026-06-11-VERIFY-SELF-AND-REVIEW-QUALITY-SUBAGENT-DISPATCH-UNVALIDATED
---

# Feature: verify-self-and-review-quality-subagent-dispatch

## Problem Statement

`skills/feature-verify-self/SKILL.md` §2 and `skills/feature-review-quality/SKILL.md` §2 both instruct the agent to "spawn an `Agent`" — a one-shot subagent that performs live-system observation (verify-self via Playwright) or code-quality review (review-quality via Read/Grep against ship-commit diff). Both skills declare `Agent` in their `allowed-tools` frontmatter. The design intent in `docs/product/arch.md` (Revision 2026-04-27, "verify-self runs as a subagent") is explicit: *"Playwright output (snapshots, console logs, network requests) stays in the subagent's context — parent context stays lean across multi-phase features."*

**Operator-flagged at code-quality-reviewer-subagent feature:reflect (2026-06-11):** "I actually don't think verify-self currently really spawns a subagent." The hypothesis: the SKILL.md prose says to spawn, but the executing agent reads the §2 procedure and runs the verification inline in the parent context — never invoking `Agent({...})`. Result: every multi-phase feature shipped since 2026-04-27 has silently bloated the parent context with verification output the design specifically intended to isolate. `feature-review-quality` inherits the same risk with a ~150-line reviewer prompt + full git-diff context.

**Expected vs observed.** Expected: every `/feature-verify-self <url>` invocation results in exactly one `Agent` tool call with the §2 prompt template baked in, and the verification result (PASS/FAIL block) bubbles back as the subagent's terminal output. Observed (per operator's hypothesis): some invocations have spawned the subagent (Playwright work in past WIPs cites "Playwright subagent"), some have not (recent WIPs cite "CLI-verifiable; no subagent needed"). The dispatch contract is non-deterministic — the agent chooses inline-vs-spawn based on whether the outcomes happen to need Playwright tools.

## Reproduction Attempt

**Surface chosen:** telemetry-only

**Rationale.** A failing unit/integration test cannot assert "when Claude reads this SKILL.md, it invokes the Agent tool" — that requires Claude to be in the loop. A manual repro recipe needs a live `<dev-url>` to verify against; running it would only sample *this* session's dispatch behavior (sample of one). The archive of 79 past feature WIPs is the historical telemetry — each WIP records whether the verify-self invocation cited a "Playwright subagent" or noted "no subagent needed; CLI-verifiable." Greppable, reproducible, dispositive.

**Outcome:** reproduced

**Artifact (audit results across `workflow/archive/`):**

Grep 1 — features that cite "Playwright subagent" in their verify-self leaves (positive evidence of subagent dispatch at least sometimes):

```
$ grep -lE "verify-self.*(via )?[Pp]laywright subagent" workflow/archive/
12 files:
  verify-self-in-place-fix-shortcut-policy.md
  wp4-legacy-flag-removal.md
  wp3-unified-window-flag.md
  wp2-emit-perf-probe.md
  claude-time-viz-wp11-comparison-view.md
  claude-time-viz-wp7-month-view.md
  claude-time-viz-wp8-custom-range.md
  claude-time-viz-wp9-filter-chips.md
  claude-time-viz-day-rename.md
  claude-time-test-containerization.md
  session-replay-harness.md
  telegram-notify-hook.md
```

Grep 2 — features that explicitly note "no subagent needed; CLI-verifiable" (positive evidence the dispatch was skipped):

```
$ grep -lE "verify-self.*(no subagent needed|CLI-verifiable)" workflow/archive/
3 files:
  code-quality-reviewer-subagent.md  ← shipped 2026-06-11, the feature that surfaced this gap
  wp4-legacy-flag-removal.md
  wp2-emit-perf-probe.md
```

Specifically in `code-quality-reviewer-subagent.md`:
- Phase 1 verify-self: *"all 5 Phase-1 observable outcomes PASS (CLI-verifiable; no subagent needed for docs-only phase)."*
- Phase 2 verify-self: *"all 9 Phase-2 observable outcomes PASS (CLI-verifiable; isolated new-artifacts phase, no subagent needed)."*
- Phase 3 verify-self: *"all 5 Phase-3 observable outcomes PASS"* (no subagent mention — same shape).

Grep 3 — feature-review-quality real-world invocations:

```
$ grep -lE "feature-review-quality|review-quality" workflow/archive/
1 file:
  code-quality-reviewer-subagent.md  ← only the feature that built it; never a real F38 invocation
```

**Determinism:** every-run, agent-dependent. The dispatch decision is made by Claude reading the §2 procedure prose. When the phase's Observable Outcomes can be verified via CLI (Read/Grep/Bash), Claude reads §2 and reasons that "spawn an Agent with these tools" is overkill — the outcomes don't need Playwright. When Playwright is genuinely needed (browser-visible behavior), the spawn happens. **The gap is in the SKILL.md prose: it says "spawn," but does not say "spawn unconditionally — even for CLI-verifiable phases — because the design property being preserved is parent context cleanliness, not Playwright availability."** The agent is making a local optimization (skip the subagent overhead when CLI suffices) that violates a global design property (keep parent context lean across phases).

**Notes:**

- **Severity is real but bounded.** The features that hit "no subagent needed; CLI-verifiable" tend to be docs-only or isolated-new-artifacts phases where the verification output is small (a few grep counts, a `bash -n` exit code). Those phases' inline verification probably costs the parent context ~200-500 tokens vs. a few thousand for a Playwright snapshot. Aggregate across N multi-phase features, this is meaningful but not catastrophic. The bigger risk is `feature-review-quality`'s ~150-line prompt + full git-diff context — that *would* be catastrophic in the parent if also dispatched inline.
- **feature-review-quality has never run for real.** The bootstrap-skip at code-quality-reviewer-subagent ship time (SURFACE-2026-06-11-SKILL-HARNESS-REGISTRY-LOADED-ONCE-AT-SESSION-START) means F38 has not yet fired in a real session. The dispatch gap that may exist in verify-self has not been empirically tested in review-quality. But by analogy — and because review-quality's §2 prose mirrors verify-self's "Spawn an `Agent` with the following information baked into the prompt" language — the same agent-reasoning that skipped the spawn in verify-self for CLI-verifiable phases will likely skip it in review-quality if the diff happens to be small enough to "just read inline."
- **The fix is non-trivial.** The current SKILL.md prose is unambiguous *in intent* ("Spawn an `Agent`") but ambiguous *in unconditional-ness* — it doesn't tell the agent "spawn even when you think you don't need to, because the design property is context isolation, not tool availability." The fix needs to: (1) strengthen the prose to make the unconditional-spawn requirement explicit, (2) add a structural pin so future SKILL.md edits can't drift back, (3) apply symmetrically to both verify-self and review-quality, (4) consider whether the same gap exists in any future subagent-dispatching skill.
- **Reproduction is dispositive, not exhaustive.** The grep evidence shows the gap exists in past runs. It does not enumerate every past run — but the pattern is established and the operator's hypothesis is confirmed: dispatch is non-deterministic and agent-judgment-dependent rather than the unconditional-spawn the design requires.

## Reproduction Refinement (operator catch, 2026-06-12)

The initial reproduction artifact above identified the *symptom* — non-deterministic dispatch in past archives — but missed the *root cause*. Operator-flagged mid-spec: **the two subagents being spawned don't exist as definitions in this repo.**

Today the `agents/` directory contains four entries: `feature-workflow/`, `incident-workflow/`, `product-workflow/`, `task-workflow/`. All four are **reference-only orchestrator-procedure documents** that `/session-start` reads to drive a workflow inline in the parent context — none of them are executable subagent definitions (no skill ever calls `Agent({subagent_type: 'feature-workflow'})`). This is by intent per the project's CLAUDE.md: *"these files are reference documents, not Agent-spawned subagents."*

So when `feature-verify-self/SKILL.md` §2 says *"Spawn an `Agent` with the following information baked into the prompt"*, there is no `subagent_type` named. The skill effectively says "spawn a subagent" without naming a target. The executing agent has two options: (1) fall back to the default `general-purpose` subagent with the prompt body as the spawn arg (which would work but lacks Playwright tool access — defeating verify-self's purpose), or (2) skip the spawn and do the work inline. The CLI-verifiable-inline-dispatch pattern caught by archive grep is option (2). The bug is not weak prose; it is **a missing dispatch target**.

The fix shape is therefore different from the original spec's option-tree:
- Original options (a) prose-and-pin / (b) orchestrator-dispatch redesign / (c) accept-and-update-arch all assumed the spawn target existed. None solve the missing-target problem.
- The actual fix is: **create the two missing subagent definitions, then wire both skills to invoke them by `subagent_type` name.** This adds the first two executable subagents to the repo (distinct from the 4 reference-only `*-workflow` agents).

## User Stories

- As a **workflow-system operator** running a multi-phase feature in autopilot, I want `feature-verify-self` to dispatch into a dedicated Playwright-equipped subagent, so that the parent context stays lean across phases AND the verification work happens with the right tool surface.
- As a **workflow-system operator** running `feature-review-quality` after ship, I want the reviewer to read the full git diff in a dedicated code-reviewer subagent, so that the ~150-line reviewer prompt + diff context lives in the subagent's context, not the parent's.
- As a **future skill author** introducing the Nth dispatch-based skill (after verify-self and review-quality), I want a clear convention for declaring a subagent target — including where its definition lives, how `install.sh` symlinks it, and how the skill names it via `subagent_type` — so my skill doesn't reinvent the wiring.

## Acceptance Criteria

The feature is done when **all six** hold:

1. **Two new executable subagent definitions exist** at `agents/feature-verify-self-runner/AGENTS.md` and `agents/code-quality-reviewer/AGENTS.md`. Each carries valid frontmatter (`name`, `description`, `tools`) and a body containing the prompt that was previously inline in the calling skill's §2.
2. **`install.sh` symlinks both new agent directories** into `~/.claude/agents/` on next run. The existing for-loop at install.sh:42-65 already handles this; no install.sh edit needed unless the new agents introduce a new requirement (e.g. per-agent files beyond AGENTS.md). Idempotent re-run leaves both as `[ok]`.
3. **`feature-verify-self/SKILL.md` §2 invokes its subagent by name.** The §2 prose is rewritten from *"Spawn an `Agent` with the following information baked into the prompt"* to an explicit `Agent({subagent_type: 'feature-verify-self-runner', prompt: <dynamic context>, ...})` shape, with the dynamic-context assembly clearly described. The literal `subagent_type: 'feature-verify-self-runner'` appears in the prose. Same for `feature-review-quality/SKILL.md` §2 with `subagent_type: 'code-quality-reviewer'`.
4. **Both subagents have the right tool surfaces.** `feature-verify-self-runner` has Playwright MCP tools + Bash + Read/Glob/Grep (per arch.md 2026-04-27's intent — the Playwright output stays in the subagent). `code-quality-reviewer` has Read + Glob + Grep + Bash only (observe-only; no Edit/Write — per `feature-review-quality/SKILL.md` §2's "do NOT grant Edit/Write to the subagent — it is observe-only").
5. **Structural pins in `tests/check-structure.sh` enforce the dispatch wiring.** New pins assert (a) both new agent AGENTS.md files exist with valid frontmatter; (b) both calling skills' §2 prose contains the literal `subagent_type: '<expected-name>'` string referencing the matching agent definition; (c) `install.sh` symlinks both new agent directories on a dry-run trace. Self-extending iteration preferred (e.g. iterate `agents/*/AGENTS.md` and assert any `tools:` frontmatter referenced from a SKILL.md actually exists).
6. **A behavioral test scenario codifies the dispatch contract** in `tests/scenarios/feature.yaml`. The scenario uses a fixture for a CLI-verifiable phase (the kind that historically tempted inline dispatch) and asserts the skill output references `subagent_type: 'feature-verify-self-runner'` literally. Sonnet tag acceptable only if haiku empirically fails per existing recon discipline.

## Out of Scope

- **Retroactive re-verification of past features.** Past archived features that hit "no subagent needed; CLI-verifiable" are not re-run. The pattern stands as historical evidence.
- **Audit of other skills that *might* benefit from a subagent dispatch.** Only `feature-verify-self` and `feature-review-quality` are in scope. If grep surfaces a third candidate skill during build (e.g., a future skill with `Agent` in `allowed-tools`), surface as a Discovery, not feature-scope expansion.
- **Tool-list curation beyond the obvious.** Each new subagent's `tools:` frontmatter starts with the minimal set documented in acceptance criterion #4. Refinement (adding/removing specific MCP tools, tuning timeouts) is a future task, not this feature's scope.
- **Reorganizing the existing 4 `*-workflow` reference agents.** Those stay as-is and remain reference-only. The new agents live alongside them in `agents/` with a different *kind* of contract (executable dispatch target), but no directory restructure or naming-convention change is in scope.
- **`subagent_type` discoverability harness.** Claude Code's `Agent` tool reads available subagents from `~/.claude/agents/`. The first real invocation in a fresh session after install.sh symlinks the new agents is when the dispatch will actually fire — same bootstrap-skip pattern as the harness's `Skill` registry (SURFACE-2026-06-11-SKILL-HARNESS-REGISTRY-LOADED-ONCE-AT-SESSION-START). Working around the bootstrap-skip is not in scope; this feature accepts that the first real F38 invocation happens in the *next* session after this one ships.
- **General "judgmental-subagent-prompt externalization" convention** (yesterday's L2 learning). Orthogonal — externalization is about *where the prompt lives*; this feature is about *whether the dispatch target exists*. Don't bundle.

## Technical Constraints

- **Claude Code subagent definitions live in `agents/<name>/AGENTS.md`** with frontmatter declaring `name`, `description`, and optionally `tools`. The harness reads `~/.claude/agents/` on session start to populate the available `subagent_type` values for the `Agent` tool. The 4 existing `*-workflow/AGENTS.md` files happen to carry `skills:` frontmatter (orchestrator-procedure metadata), but that field is reference-only — it does not turn them into executable subagents.
- **The new agents must use the executable-subagent frontmatter shape**, not the reference-document shape. Concrete: `name:`, `description:`, `tools:` (list of permitted tools). No `skills:` field (that would suggest orchestrator-procedure semantics, which is the wrong contract here).
- **`install.sh` lines 42-65** already symlink any directory under `agents/` into `~/.claude/agents/`. The existing for-loop is the integration surface; new directories under `agents/` are picked up automatically. No install.sh edit needed unless the spec discovers a needed change.
- **The bootstrap-skip from 2026-06-11** (SURFACE-2026-06-11-SKILL-HARNESS-REGISTRY-LOADED-ONCE-AT-SESSION-START) applies to *both* skills and subagents — they're both loaded once at session start. The first real F38 → review-quality invocation cannot happen in *this* feature's own ship → review-quality cycle (the new subagents won't exist in this session's registry yet). The feature will ship with the structural pins + behavioral scenario as the validation gate; the first real subagent dispatch is deferred to a future session.
- **No new state machine transitions.** F-IDs and pause-policy tables are unchanged. AGENTS.md (the *reference* orchestrator procedures, not the new executable agents) needs no F-table edit.
- **arch.md 2026-04-27 design property is preserved**, not retracted. The fix restores the property by giving the spawn a real target.
- **No 3rd-party dependencies.** Pure local agent definition files + skill prose edits + test additions.

## Open Questions

### OQ-1 — What `name:` values do the two new subagents get?

The `subagent_type` value the calling skill passes to `Agent({})` must match the agent definition's `name:` frontmatter exactly. Naming proposals:

- **`feature-verify-self-runner`** (preferred) — names the function clearly (runs the verify-self verification), namespaced by feature workflow.
- **`feature-verify-self-subagent`** — alternative; "subagent" suffix is redundant since all entries in `agents/` are subagent definitions when executable.
- **`verify-self-runner`** — drops the `feature-` prefix; cleaner but loses workflow-namespace cue.

For the code-quality reviewer:
- **`code-quality-reviewer`** (preferred) — names the function; no workflow prefix because code quality is workflow-agnostic in principle.
- **`feature-review-quality-runner`** — parallel to verify-self's preferred shape; pro: consistency, con: longer.

**Resolution at spec time:** **`feature-verify-self-runner` and `code-quality-reviewer`.** Rationale: verify-self-runner gets the workflow prefix because it's tightly bound to the feature workflow's per-phase verification loop; code-quality-reviewer is workflow-agnostic (it could conceivably be invoked from review of any commit, not just feature ships) so it gets a workflow-neutral name. Both directories under `agents/` follow `kebab-case` matching the existing convention.

### OQ-2 — Where does the reviewer-prompt template live: inline in `agents/code-quality-reviewer/AGENTS.md`, or stays at `skills/feature-review-quality/reviewer-prompt.md` (externalized yesterday)?

Yesterday's L2 learning externalized the reviewer prompt to `skills/feature-review-quality/reviewer-prompt.md` (148 lines, tuned with calibration examples). With this feature, the natural home for that prompt is the agent definition itself — the subagent's AGENTS.md *is* the prompt template.

- **(i) Move the prompt into `agents/code-quality-reviewer/AGENTS.md`.** The reviewer prompt becomes the body of the agent definition. Deletes `skills/feature-review-quality/reviewer-prompt.md`. The calling skill (`feature-review-quality/SKILL.md` §2) no longer reads a separate prompt file — it spawns the subagent and the subagent's own definition carries the prompt.
- **(ii) Keep the prompt at `skills/feature-review-quality/reviewer-prompt.md`** and have the skill read-then-spawn (current shape, just with `subagent_type` now named). The agent definition's body is minimal: "you are the code-quality reviewer; read your prompt from the dynamic-context input."

**Resolution at spec time:** **(i) move the prompt into the agent definition.** Rationale: the prompt *is* the agent's job description; splitting it from the agent definition introduces a synchronization surface (the skill must remember to read the right file and pass it as prompt content). Moving it into AGENTS.md aligns with how subagent definitions naturally work — the body IS the prompt the model sees. Yesterday's externalization was correct in spirit (separate the long judgmental prompt from the calling SKILL.md); this feature completes that move by relocating the prompt to the right home. Dynamic context (ship SHA, base SHA, commit history, diff stat) is still appended at spawn time per `feature-review-quality/SKILL.md` §2's existing assembly procedure.

Symmetrically for verify-self: the existing inline §2 prompt template moves into `agents/feature-verify-self-runner/AGENTS.md`. The skill's §2 prose becomes a much shorter "spawn this subagent with this dynamic context" block.

### OQ-3 — Does the existing `subagent_type: "Agent"` declaration in skill `allowed-tools` still suffice, or do skills need additional declarations to name specific subagents?

Today both skills declare `Agent` in `allowed-tools`. The Claude Code `Agent` tool accepts a `subagent_type` parameter. Is the existing `Agent` declaration sufficient, or does the skill need to also declare which subagent types it's permitted to invoke?

**Resolution at spec time:** **Existing `Agent` declaration suffices.** The `Agent` tool's `subagent_type` parameter is a runtime argument, not a permission declaration. As long as the skill is permitted to call `Agent`, it can pass any registered `subagent_type` value. The validation happens at spawn time (the harness rejects unknown subagent_type strings). No frontmatter change needed in either skill.

This is also confirmed by the Agent-tool docs in the system prompt: `subagent_type` is described as "the type of specialized agent to use for this task" — a runtime selector, not a per-skill permission.

### OQ-4 — What's the empirical validation step for this feature, given the bootstrap-skip problem?

The previous spec landed on (ii) test-harness behavioral assertion. With the corrected framing, the assertion is now stronger: the skill's output should contain the literal `subagent_type: 'feature-verify-self-runner'` string. But there's a snag — the test harness (`tests/run-tests.sh`) spawns its own `claude` subprocess per scenario, which loads the agent registry fresh. So the harness *can* validate the dispatch wiring works in a fresh session.

In *this* session, however, the bootstrap-skip applies: the new subagents won't be visible until the next session. Validation paths:

- **(i) Test-harness behavioral scenario** (acceptance criterion #6) — harness-spawned `claude` subprocess loads the new subagent definitions fresh, so dispatch evidence can be asserted in scenario output. This is the primary validation gate.
- **(ii) Live runtime trial in this session** — blocked by bootstrap-skip. Cannot be done as part of this feature.
- **(iii) Static checks** — structural pins assert the wiring exists in the files (subagent definitions present, skill prose references them, install.sh symlinks them).

**Resolution at spec time:** **(i) + (iii).** Static checks (iii) give immediate signal at verify-auto/verify-self time; behavioral scenario (i) gives end-to-end dispatch evidence in a fresh-session harness subprocess. (ii) is deferred to the first real F38 invocation in a future session — acceptable per the bootstrap-skip pattern documented yesterday.

### OQ-5 — Structural pin shape: where do pins live and what do they assert?

The pins must enforce:
(a) The two new agent definitions exist with valid frontmatter.
(b) The calling skills reference them by `subagent_type` name.
(c) install.sh symlinks them (verifiable via dry-run trace or by checking the existing for-loop handles new dirs — which it does).

**Resolution at spec time:** A new pin block in `tests/check-structure.sh` named "Subagent dispatch wiring" with the following assertions (in self-extending iterating-loop shape where possible):

1. For each directory under `agents/`, if its AGENTS.md frontmatter has a `tools:` field (the marker distinguishing executable subagents from reference-only orchestrator agents), assert: `name:` is present and matches the directory name; `description:` is present; `tools:` lists at least one tool.
2. For each executable subagent identified by (1), grep `skills/*/SKILL.md` for `subagent_type:\s*['"]<agent-name>['"]`. At least one skill must reference it (an executable subagent with no caller is dead code).
3. For each skill with `Agent` in `allowed-tools`, assert the skill's body contains exactly one `subagent_type:` reference. (A skill with `Agent` but no `subagent_type:` reference is the bug this feature fixes — the pin asserts no regression.)

This is self-extending: adding a third executable subagent in the future automatically picks up the pin coverage via the same iterating loop. Expected pin delta: ~6-8 new PASS (2 agents × 3 properties + 2 skill-side cross-references), 200 → ~206-208.

### OQ-6 — Do the new subagent AGENTS.md files need to surface `subagent_type` discoverability for `/agents` slash command?

Claude Code's `/agents` slash command lists available subagents. The 4 existing `*-workflow` AGENTS.md files appear in `~/.claude/agents/` and would also appear in `/agents` output — even though they're reference-only and not meant to be invoked directly. Adding 2 more entries (both executable) increases the list to 6.

**Resolution at spec time:** **Not in scope for this feature.** The `/agents` listing is a UI surface, not a contract surface. If the listing becomes confusing (mixing reference-only and executable subagents), that's a future UX cleanup task — possibly a SURFACE-IN to product workflow if the naming convention needs revisiting. For this feature, just add the two new subagents and accept they'll appear in `/agents` listings alongside the existing 4.

## Spec Resolution Summary

All 6 OQs resolved in-spec:

| OQ | Question | Resolution |
|----|----------|-----------|
| 1 | Subagent names? | **`feature-verify-self-runner`** + **`code-quality-reviewer`** |
| 2 | Where does the reviewer-prompt template live? | **Move into `agents/code-quality-reviewer/AGENTS.md`** (deletes `reviewer-prompt.md`); symmetric move for verify-self's §2 prompt template |
| 3 | Skill frontmatter changes? | **None** — existing `Agent` in `allowed-tools` suffices; `subagent_type` is a runtime arg |
| 4 | Empirical validation given bootstrap-skip? | **Harness behavioral scenario** (i) + **static pins** (iii); live runtime trial (ii) deferred to next session |
| 5 | Structural pin shape? | **New "Subagent dispatch wiring" block** in check-structure.sh, self-extending via `agents/*/AGENTS.md` with `tools:` marker |
| 6 | `/agents` listing UX? | **Out of scope** — accept mixed listing; future cleanup task if needed |

**No unknowns remain → F4 → plan.** No 3rd-party probes needed. No research spike needed.

## Work Tree

- [x] Phase 1: Create executable subagent definitions  <!-- 2026-06-12: all 7 children complete (P1.1-P1.3 impl + 4 verify-* leaves). Two new executable subagent definitions created (agents/feature-verify-self-runner/AGENTS.md 80 lines + agents/code-quality-reviewer/AGENTS.md 158 lines), both symlinked via install.sh for-loop. verify-auto 4/4 scoped checks PASS + check-structure baseline 200/200 PASS. verify-self all 6 Observable Outcomes PASS via spawned subagent (general-purpose fallback per Discovery on Agent-registry bootstrap-skip). verify-human auto-skipped (4 gates clean). verify-codify cross-phase deferred to Phase 3 with Test Triage artifact. 2 Discoveries surfaced + backlog updated. -->
  **Rationale:** The two new agent directories under `agents/` are the *spawn targets* the calling skills will reference in Phase 2. They must exist as installed symlinks before any skill prose change has anything to dispatch into. Existing 4 `*-workflow/AGENTS.md` files use `skills:` frontmatter (reference-only); these two new agents must use `tools:` frontmatter (executable) — that's the marker the Phase 3 structural pins use to distinguish executable subagents from reference ones.

  **Observable outcomes:**
  - CLI: `ls -la ~/.claude/agents/feature-verify-self-runner` resolves to a symlink pointing at `<repo>/agents/feature-verify-self-runner` (exit 0).
  - CLI: `ls -la ~/.claude/agents/code-quality-reviewer` resolves to a symlink pointing at `<repo>/agents/code-quality-reviewer` (exit 0).
  - CLI: `head -10 agents/feature-verify-self-runner/AGENTS.md` shows valid YAML frontmatter with `name: feature-verify-self-runner`, a `description:` line, and a `tools:` list including at least one `mcp__playwright__` entry, `Bash`, `Read`, `Glob`, `Grep`.
  - CLI: `head -10 agents/code-quality-reviewer/AGENTS.md` shows valid YAML frontmatter with `name: code-quality-reviewer`, a `description:` line, and a `tools:` list including exactly `Read`, `Glob`, `Grep`, `Bash` (observe-only — NO Edit, Write, Agent, or other mutating tools).
  - CLI: `./install.sh` exits 0 and prints `[new] agents/feature-verify-self-runner` and `[new] agents/code-quality-reviewer` on first run; `[ok]` on idempotent re-run.
  - CLI: `wc -l agents/feature-verify-self-runner/AGENTS.md` ≥ 50 (body contains the moved prompt template, not a stub) AND `wc -l agents/code-quality-reviewer/AGENTS.md` ≥ 140 (body contains the moved reviewer prompt; current `skills/feature-review-quality/reviewer-prompt.md` is 148 lines).

  - [x] P1.1 Create `agents/feature-verify-self-runner/AGENTS.md` — frontmatter (`name`, `description`, `tools:` list with Playwright MCP tools + Bash + Read/Glob/Grep) + body containing the prompt template currently inline at `skills/feature-verify-self/SKILL.md` §2 lines 101-132 (the "You are a QA verification agent..." block). The body should stand on its own as the agent's job description; dynamic context (dev URL, Observable Outcomes list, severity taxonomy) will be appended at spawn time by the calling skill in Phase 2.
  - [x] P1.2 Create `agents/code-quality-reviewer/AGENTS.md` — frontmatter (`name`, `description`, `tools:` list with Read/Glob/Grep/Bash ONLY — observe-only) + body containing the content of the current `skills/feature-review-quality/reviewer-prompt.md` (148 lines, including all sections: Scope, Codebase context, Review criteria, Output format, Calibration anchors, If you disagree). Three small preserved modifications from verbatim: (a) `## AGENTS.md prose` bullet under Codebase context updated to distinguish reference-only `*-workflow` agents (`skills:` frontmatter) from executable subagents like this one (`tools:` frontmatter) — anticipates Phase 3.4 CLAUDE.md update; (b) MINOR calibration-example path updated from `skills/feature-review-quality/reviewer-prompt.md:88` to `agents/code-quality-reviewer/AGENTS.md:88` (the original location is being deleted in Phase 2.3 — keeping stale path would be forward-incompatible); (c) Dynamic Context note updated from "skill's §2" to "caller skill's §2" for clarity from the agent's perspective.
  - [x] P1.3 Run `./install.sh` to symlink the new agent directories into `~/.claude/agents/`. Confirmed: first run = `[new] agents/code-quality-reviewer` + `[new] agents/feature-verify-self-runner`, no errors. Re-run = `[ok]` for both (idempotent).
  - [x] verify-auto  <!-- 2026-06-12: 4 scoped checks PASS — (1) YAML frontmatter parse OK both files (verify-self-runner: 11 tools incl. 7 Playwright MCP + Bash + Read/Glob/Grep; code-quality-reviewer: exactly 4 tools Read/Glob/Grep/Bash observe-only); (2) install.sh syntax OK (bash -n); (3) symlinks resolve to repo paths; (4) ./tests/check-structure.sh 200/200 PASS, no regression. Runtime registry updated: 31s observed → timeout 107000ms. -->
  - [x] verify-self  <!-- 2026-06-12: all 6 Observable Outcomes PASS via spawned subagent (general-purpose fallback — see Discovery on bootstrap-skip below). No integration boundary (Phase 1 adds isolated new artifacts only). Subagent dispatch fired empirically — the SKILL.md "Spawn an Agent" prose DOES cause the orchestrator to invoke the Agent tool when the spawn target is named. Bootstrap-skip on the intended subagent_type 'feature-verify-self-runner' surfaced as Discovery. -->
  - [x] verify-human  <!-- 2026-06-12: AUTO-SKIPPED per drive_mode=autopilot. All 4 gates clean: (a) drive_mode autopilot, (b) verify-self all-PASS, (c) no integration boundary — isolated new artifacts only (two new agents/ directories picked up by existing install.sh for-loop, no consuming surface modified), (d) no Observable Outcome cites a consuming surface (all outcomes are local-filesystem CLI checks). Affirmation block printed in chat for operator read-time veto. -->
  - [x] verify-codify  <!-- 2026-06-12: No new tests in Phase 1. Test coverage for Phase 1's deliverables (subagent definitions + dispatch wiring) is intentionally batched into Phase 3 (P3.1 structural pins + P3.2 behavioral scenario). Pre-emptive Test Triage artifact written under `## Test Triage — Phase 1 verify-codify cross-phase deferral` documenting the deferral. Integration-boundary: isolated new artifacts only. Structural-check baseline 200/200 PASS held. No test files modified. -->

- [x] Phase 2: Wire both calling skills to dispatch by `subagent_type` name  <!-- 2026-06-12: all 8 children complete (P2.1-P2.4 impl + 4 verify-* leaves). Both skills' §2 invoke their subagent by subagent_type name (feature-verify-self-runner, code-quality-reviewer) with unconditional-spawn prose + bootstrap-skip fallback. Orphan reviewer-prompt.md deleted. 4 live surfaces updated for the file move (SKILL.md cross-ref, CLAUDE.md, transitions.md, check-structure.sh comment+pins). 2 stale structural pins replaced 1:1 (no PASS count delta). verify-auto 6/6 PASS + check-structure 200/200. verify-self all 8 Observable Outcomes PASS via spawned subagent. verify-human approved 3 judgment-call leaves (file-size deviation + 3 Discoveries + forward-pointer shape). verify-codify cross-phase deferred with Test Triage artifact. 1 new Discovery surfaced (SKILL.md content also cached at session start). -->
  **Rationale:** With the spawn targets in place, the two calling skills can now invoke `Agent({subagent_type: '<name>', prompt: <dynamic context>, ...})` instead of the current unspecified "spawn an Agent" prose. The §2 prose in each skill shrinks (the prompt template body moves out to the agent definition); what stays is the dynamic-context assembly + the literal spawn-with-subagent_type invocation. This is also the phase that deletes the now-orphan `skills/feature-review-quality/reviewer-prompt.md` (its content lives at `agents/code-quality-reviewer/AGENTS.md` from Phase 1).

  **Integration-boundary note:** Phase 2 modifies code inside the existing `feature-verify-self` and `feature-review-quality` skills — both are entries in the active per-phase verify loop (verify-self) and the per-feature ship → review-quality → finalize chain (review-quality). The consuming surfaces are: (a) `/feature-verify-self` invocation via `/session-start` orchestration, (b) `/feature-review-quality` invocation via F38, (c) any test scenario in `tests/scenarios/feature.yaml` that runs either skill. Per CLAUDE.md "integration-boundary rule," at least one Observable Outcome below must cite the consuming surface by name — see the `feature-verify-self` and `feature-review-quality` outcomes below.

  **Observable outcomes:**
  - CLI: `grep -E "subagent_type:\s*['\"]feature-verify-self-runner['\"]" skills/feature-verify-self/SKILL.md` matches at least 1 line (the §2 spawn invocation references the new agent by name).
  - CLI: `grep -E "subagent_type:\s*['\"]code-quality-reviewer['\"]" skills/feature-review-quality/SKILL.md` matches at least 1 line.
  - CLI: `grep -c "You are a QA verification agent" skills/feature-verify-self/SKILL.md` returns 0 (prompt body has moved out to the agent definition).
  - CLI: `[ ! -f skills/feature-review-quality/reviewer-prompt.md ]` exits 0 (the orphan prompt file is deleted).
  - CLI: `grep -F "reviewer-prompt.md" skills/feature-review-quality/SKILL.md` returns no matches (no dangling reference to the deleted file).
  - CLI: `wc -l skills/feature-verify-self/SKILL.md` shows a *smaller* file than current (the prompt template moved out; net reduction expected ~25-30 lines).
  - CLI: `wc -l skills/feature-review-quality/SKILL.md` shows reduction; the ~150-line externalized prompt's loader logic is no longer needed.
  - CLI: `bash -n install.sh` exits 0 (no regression in install.sh syntax — Phase 1's new directories are picked up by the existing for-loop without script edits).

  - [x] P2.1 Edited `skills/feature-verify-self/SKILL.md` §2: replaced the inline "You are a QA verification agent..." prompt template (was lines ~101-132) with the `Agent({subagent_type: 'feature-verify-self-runner', ...})` invocation block. Dynamic-context assembly (dev URL + Observable Outcomes verbatim) kept; the standing instructions (severity taxonomy, procedure, output format, hard rules) now live in `agents/feature-verify-self-runner/AGENTS.md`. Prose explicitly names the design property being preserved (arch.md 2026-04-27) and asserts the spawn is unconditional. Plus a Bootstrap-skip fallback paragraph documenting the recovery path when the new subagent isn't yet in the registry (added per the verify-self of Phase 1 which empirically hit this case). Net delta: −13 lines.
  - [x] P2.2 Edited `skills/feature-review-quality/SKILL.md` §2: replaced the "read reviewer-prompt.md then append dynamic context" assembly with the `Agent({subagent_type: 'code-quality-reviewer', ...})` invocation block. The standing instructions now live in the agent definition; only the dynamic context (feature name, ship SHA, base SHA, commit history, diff stat, WIP path) is appended at spawn. Plus a Bootstrap-skip fallback paragraph paralleling the verify-self one. Net delta: +35 lines (NOT a reduction as the plan's Observable Outcome anticipated — the bootstrap-skip fallback prose is more than what was removed; documented in the WIP as a defensible deviation backed by Phase 1's empirical hit on the registry-bootstrap problem). Also updated SKILL.md §3 inline reference from "per the reviewer-prompt.md output format" to "per the output-format section of `agents/code-quality-reviewer/AGENTS.md`".
  - [x] P2.3 Deleted `skills/feature-review-quality/reviewer-prompt.md` via `git rm` (content moved to `agents/code-quality-reviewer/AGENTS.md` in Phase 1).
  - [x] P2.4 Audited stale references and updated all live surfaces: (a) `tests/check-structure.sh` — two stale `grep_check` pins (lines 207 + 210) that asserted against the deleted `reviewer-prompt.md` updated to assert against `agents/code-quality-reviewer/AGENTS.md` instead, plus the surrounding comment block; (b) `CLAUDE.md` bullet under "feature-review-quality per-feature code-quality reviewer" updated to point to the new location and note the 2026-06-12 move; (c) `docs/product/transitions.md` "Code-quality reviewer step (F38–F41)" prose updated similarly; (d) `skills/feature-review-quality/SKILL.md` §3 inline reference updated (covered in P2.2). Historical records (CHANGELOG.md, workflow/archive/code-quality-reviewer-subagent.md) deliberately NOT modified — those are audit-trail records of yesterday's shipped state and should preserve their original reference to where the file was at that time. No structural pins asserted against the old inline "You are a QA verification agent" phrase — clean removal.
  - [x] verify-auto  <!-- 2026-06-12: 6 scoped checks PASS — (1) feature-verify-self/SKILL.md frontmatter parses (name+allowed-tools intact); (2) feature-review-quality/SKILL.md frontmatter parses; (3) both skills contain literal subagent_type references (2 occurrences each — primary invocation + bootstrap-skip fallback prose); (4) live-surface dangling-ref grep: 3 forward-pointer references remain in CLAUDE.md/transitions.md/check-structure.sh comment (all explain the move; intentional) + 1 in .claude/learnings/ (gitignored operator-private content, out of scope); historical records (CHANGELOG.md, workflow/archive/) preserved verbatim by design; (5) bash -n install.sh + tests/check-structure.sh PASS; (6) ./tests/check-structure.sh full run = 200/200 PASS, no count delta (2 pins substituted 1:1). -->
  - [x] verify-self  <!-- 2026-06-12: all 8 Observable Outcomes PASS via spawned subagent (general-purpose fallback again — same bootstrap-skip on the new feature-verify-self-runner subagent). Integration boundary APPLIED — Phase 2 modifies skills/feature-verify-self/SKILL.md and skills/feature-review-quality/SKILL.md (consuming surfaces of the per-phase verify loop). Multiple Observable Outcomes cite the consuming surfaces by literal path (O1, O2). Notable observation: the harness loaded THIS skill's SKILL.md content at session start, so when I (the parent orchestrator) invoked /feature-verify-self, the OLD pre-Phase-2 procedure was served — Skill registry has the same bootstrap-skip as Agent registry. This is the FIRST observed instance of a Skill being re-invoked mid-session AFTER its SKILL.md was edited; the cached old content was used. Logged to backlog as extension to SURFACE-2026-06-11-SKILL-HARNESS-REGISTRY-LOADED-ONCE-AT-SESSION-START. Plan's "wc -l skills/feature-review-quality/SKILL.md shows reduction" outcome documented as defensible deviation; bootstrap-skip fallback prose is load-bearing. -->
  - [x] verify-human  <!-- 2026-06-12: all 3 judgment-call leaves approved by operator. Defensible plan deviation approved; Discoveries framings approved; forward-pointer shape approved. -->
    - [x] P2.verify-human.1 Defensible plan deviation on `feature-review-quality/SKILL.md` file-size outcome — operator approved. Bootstrap-skip fallback prose retained as load-bearing content.
    - [x] P2.verify-human.2 Three new Discoveries framings + backlog disposition — operator approved. P6 extension + new P7 entry stand as written.
    - [x] P2.verify-human.3 Forward-pointer shape (CLAUDE.md / transitions.md / check-structure.sh comment) — operator approved. Sentences explicitly naming the 2026-06-12 move + new location stand.
  - [x] verify-codify  <!-- 2026-06-12: No new tests in Phase 2. Test coverage for Phase 2's dispatch-wiring is intentionally batched into Phase 3 (P3.1 structural pins + P3.2 behavioral scenario — same cross-phase pattern as Phase 1). Integration boundary applies; satisfied by P3.1's planned consuming-surface pin assertion. Pre-emptive Test Triage artifact written under `## Test Triage — Phase 2 verify-codify cross-phase deferral` documenting downstream-contract grep results (8 existing scenarios are scoped to §3/§5 not §2; 0 scenarios reference the removed prose). Structural-check baseline 200/200 PASS held. No test files modified beyond P2.4's pin substitution (net 0 PASS count). -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [x] Phase 3: Structural pins + behavioral scenario codifying dispatch contract  <!-- 2026-06-12: all 8 children complete (P3.1-P3.4 impl + 4 verify-* leaves). Phase 10 "Subagent dispatch wiring" pin block added (10 new PASS; 200 → 210). Behavioral scenario F10b-dispatches-subagent-by-name added + PASSes strict on haiku (17s, $0.14). New fixture verify-self-cli-verifiable-phase.md created. CLAUDE.md Architecture section updated with reference-only-vs-executable agent distinction. Targeted 9-scenario sweep on haiku: 8 PASS + 1 historical SOFT_PASS (F-boundary-self, pre-existing fragility, not a regression). The dispatch contract is now codified at TWO surfaces: structural (the pin block) AND behavioral (the runtime-validated scenario). -->
  **Rationale:** Phase 1 + Phase 2 establish the dispatch wiring; Phase 3 codifies it as a regression-gated contract. Two artifact kinds: (i) static pins in `tests/check-structure.sh` asserting the wiring exists on disk (self-extending via the `tools:` frontmatter marker), and (ii) one behavioral scenario in `tests/scenarios/feature.yaml` that proves a fresh-session harness subprocess sees the dispatch wiring at runtime (acceptance criterion 6).

  **Integration-boundary note:** Phase 3 modifies code inside the existing `tests/check-structure.sh` (consumed by every CI-style structural check in the project) and `tests/scenarios/feature.yaml` (consumed by `tests/run-tests.sh` and `tests/run-all.sh`). The consuming surfaces are: (a) `./tests/check-structure.sh` full-run (must still exit 0 with the new pins passing), (b) `./tests/run-tests.sh --group feature` (the new scenario must PASS in fresh-harness subprocess), (c) `./tests/run-tests.sh --id <new-scenario-id>` (targeted invocation). At least one Observable Outcome below cites each consuming surface.

  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh 2>&1 | grep -E "(PASS|FAIL)" | tail -1` shows updated PASS count = current_count + delta (target +6 to +8 new pins). The script exits 0.
  - CLI: `grep -A3 "Subagent dispatch wiring" tests/check-structure.sh` returns the new pin block's header + first few `grep_check` lines (the block exists and is named per OQ-5).
  - CLI: `./tests/run-tests.sh --id <new-scenario-id>` produces a result row with `status: PASS` (the new scenario PASSes strict on first attempt; sonnet tag added only if haiku empirically fails).
  - CLI: `grep -E "subagent_type" tests/scenarios/feature.yaml` matches at least 1 line (the new scenario asserts the dispatch-wiring literal in skill output).
  - CLI: `bash -n tests/check-structure.sh` exits 0 (no syntax regression).
  - CLI: `yq '.scenarios | length' tests/scenarios/feature.yaml 2>/dev/null` or `grep -cE "^  - id:" tests/scenarios/feature.yaml` shows count = current_count + 1 (exactly one new scenario added).

  - [x] P3.1 Added Phase 10 "Subagent dispatch wiring" pin block to `tests/check-structure.sh`. Self-extending iteration over `agents/*/AGENTS.md`, selecting executable subagents by `tools:` frontmatter marker; per-subagent assertions: (a) name matches directory basename, (b) description present, (c) tools list non-empty (≥1 entry), (d) ≥1 skill references the subagent via `subagent_type: '<name>'`. Plus cross-skill assertion (e): every `skills/*/SKILL.md` with `Agent` in `allowed-tools` must reference ≥1 `subagent_type:` — catches the SURFACE-2026-06-11 dispatch-gap regression. Empirical: PASS count 200 → 210 (+10 = 2 agents × 4 + 2 cross-skill cross-references; close to plan's "+6 to +8" estimate). No FAILs. bash -n syntax OK. -->
  - [x] P3.2 Authored behavioral scenario `F10b-dispatches-subagent-by-name` in `tests/scenarios/feature.yaml` (inserted between F10b-shortcut and F11). Asserts `transition_id: F10b` + `contains_any: ["subagent_type: 'feature-verify-self-runner'", ...]`. Fixture: `tests/fixtures/wip/verify-self-cli-verifiable-phase.md` (created in P3.3). The system_prompt_extra explicitly asks the model to describe its spawn invocation shape before emitting transition — codifying the dispatch-wiring evidence even for CLI-verifiable phases. Started untagged (haiku); will recon if it FAILs empirically.
  - [x] P3.3 Created `tests/fixtures/wip/verify-self-cli-verifiable-phase.md` — minimal WIP file with frontmatter (drive_mode: autopilot), Problem Statement (docs-only prose update, no code paths, the kind of phase that historically tempted inline dispatch), Work Tree with one in-progress Phase whose 4 Observable Outcomes are all CLI: lines (no Browser:, no HTTP:). Current Node points to Phase 1 verify-self.
  - [x] P3.4 Updated CLAUDE.md `## Architecture > Two kinds of artifacts` section. The original "Agents" bullet stated all `agents/<name>/AGENTS.md` files were reference documents (correct pre-2026-06-12). New shape distinguishes two kinds by frontmatter marker: reference-only orchestrator agents (`skills:` frontmatter — the 4 *-workflow files) vs. executable subagents (`tools:` frontmatter — the 2 new ones: feature-verify-self-runner, code-quality-reviewer). The convention note explicitly cites the 2026-06-12 introduction date and the Phase 10 structural-pin enforcement surface. The earlier feature-review-quality bullet's forward-pointer update was already landed in P2.4 — no further edit needed.
  - [x] verify-auto  <!-- 2026-06-12: 5 scoped checks PASS — (1) bash -n on check-structure.sh; (2) tests/scenarios/feature.yaml YAML parses, scenario count 68 → 69 (+1 from P3.2); (3) new scenario selectable via --id (dry-run shows it); (4) fixture frontmatter parses (4 fields: feature, drive_mode, state, created); (5) ./tests/check-structure.sh full run = 210/210 PASS (was 200; +10 from Phase 10 pin block per plan estimate +6-8). BONUS empirical recon: ran ./tests/run-tests.sh --id F10b-dispatches-subagent-by-name --model haiku → **PASS strict, first attempt, 17s, $0.14**. The dispatch contract is empirically codified — the harness's fresh claude --print subprocess sees the Phase-2-edited SKILL.md prose, the model follows the unconditional-spawn instruction, references the literal subagent_type in output. Haiku tag is appropriate; no sonnet tag needed per the recon discipline. -->
  - [x] verify-self  <!-- 2026-06-12: all 6 Observable Outcomes PASS via spawned subagent (general-purpose fallback per ongoing Agent-registry bootstrap-skip). Integration boundary APPLIED — Phase 3 modifies tests/check-structure.sh and tests/scenarios/feature.yaml, both with active consuming surfaces (CI structure check + harness behavioral tests). Multiple Observable Outcomes cite the consuming surfaces by literal path. The behavioral scenario's empirical PASS on haiku at verify-auto-time is the runtime evidence the integration-boundary rule wants — the test exercises the new dispatch contract end-to-end and asserts post-change behavior. -->
  - [x] verify-human  <!-- 2026-06-12: all 3 light judgment-call leaves approved by operator ("approve"). -->
    - [x] P3.verify-human.1 +10 PASS delta in Phase 10 pin block — operator approved.
    - [x] P3.verify-human.2 Empirical haiku PASS completes acceptance criteria 5 + 6 — operator confirmed.
    - [x] P3.verify-human.3 New "Two kinds of agents" CLAUDE.md architectural distinction — operator approved.
  - [x] verify-codify  <!-- 2026-06-12: Phase 3 IS the test-coverage phase. P3.1 added the structural pin block (Phase 10 "Subagent dispatch wiring", +10 PASS — 210/210 total) and P3.2 added the behavioral scenario F10b-dispatches-subagent-by-name (PASS strict on haiku at verify-auto-time, 17s, $0.14). Verify-codify sweep of the 9 edited-skill scenarios (F9b, F9b-rerun, F10b, F10b-shortcut, F10b-dispatches-subagent-by-name, F39, F40, F41, F-boundary-self) on haiku: 8/9 PASS strict + 1 SOFT_PASS on F-boundary-self. SOFT_PASS confirmed as pre-existing scenario-design fragility (same SOFT_PASS in both prior recorded runs 2026-06-07 and 2026-06-09) — NOT a Phase 2/3 regression. Test Triage artifact documents the analysis. Total sweep: 137s, $0.53. Structural-check still 210/210 PASS. No test files modified beyond Phase 3's own P3.1 + P3.2 additions. -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > ship (all 3 phases complete; entering ship)
- **Active scope:** feature-ship
- **Blocked:** none
- **Unvisited:** ship → review-quality (or finalize direct via F17b if Mode 4) → finalize
- **Open discoveries:** 3 (all operator-approved at Phase 2 verify-human; backlog updates landed)

## Test Triage — Phase 1 verify-codify cross-phase deferral

**Classification:** N/A — pre-emptive deferral artifact, not a triage of a test failure.
**Confidence:** high.
**Evidence:** Phase 1 added 2 new agent definition files + 2 new symlinks via the existing install.sh for-loop. No existing test scenario or structural pin asserts against the new artifact names (`feature-verify-self-runner`, `code-quality-reviewer`) — grep across `tests/` returns one match in `tests/check-structure.sh:194`, which is a comment containing the substring "code-quality-reviewer" as part of the phrase "code-quality-reviewer-subagent" (yesterday's shipped feature name), not a real pin. No test regression possible from Phase 1 in isolation.
**Action:** Coverage for Phase 1's deliverables (new subagent definitions + dispatch wiring) is intentionally batched into Phase 3 (P3.1 = structural pin block "Subagent dispatch wiring" with self-extending `tools:`-frontmatter-iteration; P3.2 = behavioral scenario asserting `subagent_type` literal in skill output). This is the same cross-phase test-deferral pattern documented in `code-quality-reviewer-subagent.md` Phase 1 verify-codify (shipped 2026-06-11) and `task-workflow-needs-lite-verify.md`. Phase 1 verify-codify is structurally complete; the regression-coverage surface (`./tests/check-structure.sh`: 200/200 PASS at this Phase 1 verify-auto) remains green. No tests modified, no triage entry against a failure.

## Test Triage — F-boundary-self SOFT_PASS at Phase 3 verify-codify sweep

**Classification:** Pre-existing scenario-design fragility (NOT a regression from this feature).
**Confidence:** high.
**Evidence:** Targeted sweep of 9 scenarios touching the two edited skills (`./tests/run-tests.sh --id F9b,F9b-rerun,F10b,F10b-shortcut,F10b-dispatches-subagent-by-name,F39,F40,F41,F-boundary-self --filter-model default`) returned 8/9 PASS strict + 1 SOFT_PASS on F-boundary-self. SOFT_PASS detail: `Contains '/distribution/match' but also mentioned: /feature-verify-human`. Historical lookup in `tests/results/` shows F-boundary-self SOFT_PASSed on haiku in both prior recorded runs (2026-06-07, 2026-06-09) — this is the baseline behavior, not a Phase 2/3 regression. Root cause: the scenario's `not_contains: [/feature-verify-human]` is structurally fragile per CLAUDE.md's "Entry-state transitions need a different test shape than exit transitions" routing-fork pattern. When the skill refuses the run with F9b, the model legitimately reasons "instead of going to verify-human, back-loop to build" and the prose contains the negated path. Per `tests/lib/verify.sh:78`, lenient-mode SOFT_PASS = not a structural FAIL.
**Action:** None — pre-existing fragility surfaced by the sweep, but unrelated to this feature's changes. Could be fixed by relaxing the scenario's not_contains constraint per the existing CLAUDE.md guidance, but that's a separate scenario-design task. Not surfacing as a new backlog entry because the fragility is already documented as a known convention bullet in CLAUDE.md. All 9 of this feature's directly-edited scenarios PASS (8 strict + 1 historical SOFT_PASS).

## Test Triage — Phase 2 verify-codify cross-phase deferral

**Classification:** N/A — pre-emptive deferral artifact, not a triage of a test failure.
**Confidence:** high.
**Evidence:** Phase 2 modified `skills/feature-verify-self/SKILL.md` and `skills/feature-review-quality/SKILL.md` (§2 of each); deleted `skills/feature-review-quality/reviewer-prompt.md`; updated 2 structural pins in `tests/check-structure.sh` (pin count net 0); updated forward-pointer prose in `CLAUDE.md`, `docs/product/transitions.md`. Integration boundary applies — both skills are consumed by active workflow paths. Downstream-contract grep results:
- 8 existing behavioral scenarios reference `feature-verify-self` or `feature-review-quality` (scenarios.feature.yaml lines 263, 302, 342, 385, 793, 813, 834, 1324). All use `system_prompt_extra` to short-circuit the subagent spawn — they assert on TRANSITION emissions + §3/§5 procedure behavior, NOT on §2 inline prompt template content. Phase 2's edits to §2 are orthogonal to what those scenarios assert; no regression expected.
- No scenario or fixture references the removed inline phrase "You are a QA verification agent" or the path "reviewer-prompt.md" (`grep` across `tests/` returns 0 matches for both).
- `tests/check-structure.sh` 2 stale pins (lines 207+210 asserting against deleted `reviewer-prompt.md`) replaced with equivalents asserting against `agents/code-quality-reviewer/AGENTS.md`. Net pin count: unchanged (200/200 PASS at verify-auto + verify-self full re-confirmation).

**Action:** Same cross-phase deferral as Phase 1 — Phase 3 is the test-coverage phase by design:
- **P3.1** authoritative regression coverage for the dispatch contract: a "Subagent dispatch wiring" pin block iterating `agents/*/AGENTS.md` for `tools:` frontmatter (the executable-marker), asserting (a) `name:` matches dir, (b) `description:` present, (c) `tools:` non-empty, then cross-referencing `skills/*/SKILL.md` files with `Agent` in `allowed-tools` to assert each contains a `subagent_type:` reference. This pin **fully satisfies the integration-boundary rule** for verify-codify ("test exercises the consuming surface and asserts post-change behavior") — `skills/feature-verify-self/SKILL.md` and `skills/feature-review-quality/SKILL.md` are cited by literal path, and the assertion is against the exact change Phase 2 made (subagent_type literal present).
- **P3.2** behavioral scenario in `tests/scenarios/feature.yaml` asserting the harness sees the `subagent_type` literal in a fresh subprocess (which loads new SKILL.md content from disk, bypassing this-session cache).

Phase 2 verify-codify is structurally complete; regression-coverage surface remains 200/200 PASS. No test files modified beyond the pin substitution in Phase 2 itself, and that substitution was net 0 in PASS count (verified at verify-auto). No triage entry against a failure.

## Discoveries

- [SURFACED-2026-06-12] Phase 1 verify-self — Bootstrap-skip applies to the **Agent registry**, not only the Skill registry. Attempted `Agent({subagent_type: 'feature-verify-self-runner', ...})` from this skill invocation in the same session that created the symlink → harness returned `"Agent type 'feature-verify-self-runner' not found. Available agents: claude-code-guide, Explore, feature-workflow, general-purpose, incident-workflow, Plan, product-workflow, statusline-setup, task-workflow"`. Same root cause as SURFACE-2026-06-11-SKILL-HARNESS-REGISTRY-LOADED-ONCE-AT-SESSION-START — both registries are loaded once at session start. Fallback to `general-purpose` worked (Phase 1 outcomes were CLI-only so no Playwright tools needed). The dispatch itself fired empirically, which IS the meta-evidence for this feature: SKILL.md "Spawn an Agent" prose DOES cause the orchestrator to invoke the Agent tool when the spawn target is provided. The bootstrap-skip will affect this feature's own verify-self of Phase 2 (which wires the skills to invoke the new subagents by name) — the harness will not see the wiring until next session. Logged to backlog for visibility.

- [SURFACED-2026-06-12] Phase 1 verify-self — The 4 existing `*-workflow/AGENTS.md` files (feature-workflow, incident-workflow, product-workflow, task-workflow) ARE registered as invokable `subagent_type` values by the harness, despite being intended as reference-only per the project's CLAUDE.md ("these files are reference documents, not Agent-spawned subagents"). Observed in the harness's error message listing "Available agents: ... feature-workflow, ... incident-workflow, ... product-workflow, ... task-workflow". This is benign today (no skill invokes them), but means a careless future skill could `Agent({subagent_type: 'feature-workflow', ...})` and get an unexpected spawn. The distinguishing marker the harness uses is unclear — likely just the directory presence under `~/.claude/agents/`, regardless of frontmatter shape. Logged to backlog for documentation/discussion (could justify the new convention introduced by this feature: `tools:` frontmatter as the executable-vs-reference marker, with corresponding structural pin to forbid `subagent_type` references to reference-only agents).

- [SURFACED-2026-06-12] Phase 2 verify-self — **Skill SKILL.md content is cached at session start, NOT re-read per invocation.** When the parent orchestrator invoked `/feature-verify-self` AFTER Phase 2 edited `skills/feature-verify-self/SKILL.md`, the harness served the OLD pre-Phase-2 SKILL.md content (with the inline "You are a QA verification agent..." prompt template still inline) instead of the freshly-edited file on disk. This means SURFACE-2026-06-11-SKILL-HARNESS-REGISTRY-LOADED-ONCE-AT-SESSION-START is broader than originally understood — not just "new skills/subagents added mid-session aren't visible," but also "edited skills' SKILL.md content isn't refreshed mid-session." Working-around would require `/session-pause` + `/session-resume` (unverified) or a fresh session. Phase 3 will be the next test: when `/feature-build` is invoked for Phase 3, will it see the Phase-2-edited skill prose or the cached old prose? Updating backlog SURFACE-2026-06-11-SKILL-HARNESS-REGISTRY-LOADED-ONCE-AT-SESSION-START to extend its scope to mid-session edits (not just additions).
