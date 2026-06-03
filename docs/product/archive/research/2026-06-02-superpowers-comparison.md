---
stage: research
state: complete
updated: 2026-06-02
type: comparative-analysis
---

# Superpowers vs. This Workflow System — Comparative Analysis

**Subject:** [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent / Prime Radiant
**Compared against:** This repo (`my-claude-code-customization`) — a state-machine-driven Claude Code workflow system
**Analysis date:** 2026-06-02
**Prepared by:** Claude (Opus 4.7, 1M context)

> **Bias disclosure (read first).** I have deep working context on *this* repo — its CLAUDE.md, vision, transitions, current cycle. I read superpowers fresh today from a single deep pass. That asymmetry means I will be sharper on weaknesses in superpowers than in this repo, and I am more likely to read superpowers' design choices as "different from the obvious answer" when in fact they may be the considered answer to a problem I haven't experienced. Every section marked **⚠ Bias flag** is a place where I noticed myself preferring this-repo's framing and want the reader to discount accordingly. I'll also flag claims I'm relying on superpowers' own marketing (README, RELEASE-NOTES) for, where I have no independent verification.

---

## TL;DR — One screen

Both systems share the same diagnosis: **AI coding agents skip discipline under pressure**. They differ sharply on the prescription.

| Axis | Superpowers | This repo |
|---|---|---|
| **Mental model** | A *methodology*: a senior engineer's playbook injected into the agent | A *state machine*: explicit workflow phases with named transitions |
| **Unit of structure** | Composable skills, mostly flat, linearly chained at runtime | Skills + orchestrator agents; skills bound to states in 4 workflow groups |
| **Enforcement posture** | Coercive — "you do not have a choice. you MUST use it" | Advisory — "transitions are encoded in prompts, not enforced by hooks" |
| **Persistence story** | Mostly stateless between sessions; plans + design docs are artifacts | Workflow state is a file on disk (`workflow/wip/`, `.session.md`) by design |
| **Multi-harness** | First-class — Claude Code, Codex, Cursor, OpenCode, Gemini, Copilot CLI, Factory Droid | Claude-Code only; project files (CLAUDE.md, hooks) are Claude-shaped |
| **Verification** | "Iron Law" — no completion claim without fresh evidence; one general skill | Per-phase `verify-auto / -self / -human / -codify` loop, with Test Triage gate |
| **Subagent strategy** | Subagent-driven development (SDD) is the default execution model | Subagents used for parallel research/exploration; main work runs in parent context |
| **Human gates** | Design approval; plan approval; merge/PR choice | Spec review; plan review; verify-human; triage-severity; back-loop decisions |
| **Audience** | Solo + team developers across many harnesses | The author's own multi-project Claude Code use (per `vision.md`) |

Both are sharp pieces of work. The interesting borrows for this repo are around **rationalization-resistance language**, **per-task spec/code dual review**, **TDD-as-a-skill** structure, and **multi-harness portability discipline**. The interesting things this repo has that superpowers doesn't are **per-phase verify loops with severity taxonomy**, **explicit cross-level mechanisms (SURFACE/ESCALATE/REDIRECT)**, **on-disk workflow state**, and the **debug-* sidebar category**.

---

## 1. Problem Framing (highest priority)

### What superpowers thinks the problem is

Direct from `CLAUDE.md` (the agent guidelines file at superpowers' root):

> "This repo has a 94% PR rejection rate. Almost every rejected PR was submitted by an agent that didn't read or didn't follow these guidelines… Submitting a low-quality PR doesn't help [your human partner] — it wastes the maintainers' time, burns your human partner's reputation, and the PR will be closed anyway. That is not being helpful. That is being a tool of embarrassment."

From the README's "How it works":

> "As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do."

From `using-superpowers/SKILL.md`:

> "IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT. This is not negotiable. This is not optional."

**Synthesized worldview:** Agents *will* skip design, jump to code, claim success without verification, and rationalize away discipline under any time pressure. The fix is to make the *correct senior-engineer process* the path of least resistance, and to name every rationalization explicitly so it can't sneak through. The framing is "agent self-discipline cannot be trusted; encode the discipline."

A telling quote — the *target reader* of a plan, per `writing-plans/SKILL.md`:

> "an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing"

That's not how superpowers thinks about *the user's collaborator*. That's how it thinks about *itself* when it's about to execute the plan. The whole system is built around dropping the agent's autonomy floor: a plan must be detailed enough that even a bad agent following it produces good output.

### What this repo thinks the problem is

From `docs/product/vision.md`:

> "Agent-assisted software work drifts. Without structure, a single conversation can oscillate between planning, implementation, research, and debugging — losing context at each pivot, producing half-finished artifacts, and leaving no durable record of *why* a decision was made. Existing agent tooling optimizes for single-turn competence; it does not impose the discipline of a *development lifecycle*."

And from the Core Principles:

> "State is a file, not a memory… Advisory enforcement over hard blocks. Encode the state machine in prompts so agents can exercise judgment at edges."

**Synthesized worldview:** The problem isn't that agents are *undisciplined* — it's that they're *adrift*. Each turn is competent in isolation; what's missing is a legible **lifecycle** with named states, persistent context, and a way to absorb the discoveries that real work generates (SURFACE/ESCALATE/REDIRECT). Agents *can* make good judgment calls at edges, but they need a map. Build the map. Trust the agent's reading of it.

### Where they agree

Both systems explicitly diagnose:
- Agents skip the planning-before-coding step
- Agents claim work done without verifying
- Agents lose the "why" between sessions
- Process discipline beats vibes
- The author of these tools is solving a problem they personally hit

Both treat **process as code** — composable, version-controlled, tested-against-the-model.

### Where they diverge

Superpowers' diagnosis is **agent-centric**: the agent is the unreliable component. The system's job is to constrain it.

This repo's diagnosis is **work-shape-centric**: real software work has a known shape (product → feature → task, plus incident, plus session), and the agent's competence is wasted if there's no map of that shape. The system's job is to draw the map.

This is a real philosophical split. It explains every downstream design difference.

⚠ **Bias flag:** I find the work-shape framing more compelling — but I would, because it's the framing I've been steeped in for this entire conversation. Superpowers' agent-centric framing has the harder evidence behind it (their RED-phase pressure-testing of skills actually measures agent failure modes in the wild). I haven't seen this repo's principles tested with the same rigor.

---

## 2. Workflow Philosophy

### Shape of work

**Superpowers** is a mostly-linear pipeline with loops:

```
brainstorming → (using-git-worktrees) → writing-plans → subagent-driven-development
                                                        → test-driven-development (inside)
                                                        → requesting-code-review (between tasks)
                                                        → finishing-a-development-branch
```

Two cross-cutting disciplines (`verification-before-completion`, `systematic-debugging`) are available throughout. Two meta-skills (`writing-skills`, `using-superpowers`) live one level up. **It's one workflow with one happy path.** Variation comes from "subagent-driven vs. inline execution" of the same plan.

**This repo** is a state machine across **four workflow groups**:

- **Product** (vision → roadmap → research → arch → wbs → context) — strategic decomposition
- **Feature** (spec/plan → build → verify-auto/self/human/codify per phase → ship → finalize)
- **Task** (plan → act → close) — atomic changes
- **Incident** (report → triage → investigate → mitigate → codify → resolve)

Plus a **Session** meta-layer (`session-start`, `-pause`, `-resume`, `-reflect`, `-store-learning`) for cross-workflow continuity. 35 skills, 4 orchestrator agents, 63 transitions.

This is **fundamentally more granular**. Superpowers has one shape of work ("a development task"). This repo has four shapes, because in the author's experience real work *isn't* one shape — fixing a production incident, sketching a product vision, and implementing a feature phase each need different state and different exits.

### Enforcement posture (the sharpest contrast)

Superpowers, `using-superpowers/SKILL.md`:
> "IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT. This is not negotiable. This is not optional."

This repo, `vision.md`:
> "Advisory enforcement over hard blocks. Encode the state machine in prompts so agents can exercise judgment at edges. Hooks are reserved for truly dangerous actions, not for process conformance."

These are not the same philosophy. They are opposing answers to the same question: *should the system second-guess the agent?*

Superpowers' answer: **yes, always.** The "Red Flags" tables in every skill name specific rationalizations ("I'm tired", "Just this once", "This is too simple to need a design") and forbid them by name.

This repo's answer: **no, but be legible.** A skill announces its valid exits and trusts the agent to pick. The TRANSITION token at the end is machine-readable but advisory.

⚠ **Bias flag:** I want to be careful here. The "advisory" framing is a load-bearing principle in *this* repo's vision; superpowers' coercive framing is empirically grounded in the author's pressure-testing of failure modes. The tradeoff isn't free. I'll come back to this in §5.

### Subagent strategy

**Superpowers' subagent-driven-development (SDD) is the headline feature.** Per `subagent-driven-development/SKILL.md`:

For every task in the plan, the controller dispatches:
1. **Implementer subagent** — fresh, gets the full task text + context, implements, self-reviews, commits
2. **Spec compliance reviewer subagent** — separate agent, checks: did the implementer match the spec?
3. **Code quality reviewer subagent** — third agent, checks: is the code well-built?

If either reviewer rejects, the implementer fixes and gets re-reviewed. Move to next task only when both pass. **No human pause between tasks** — the controller runs continuously until the plan is done or it hits a `BLOCKED` status.

This is a real engineering pattern: fresh-context-per-task to avoid pollution, two separate reviewer personas to force two different lenses, parent-as-orchestrator to keep coordination state out of subagent context.

**This repo's subagent posture is much more conservative.** Subagents are used:
- For *parallel research* (e.g., the Explore agent I just used to read superpowers)
- For *isolated experiments* (worktree-isolated agents in `session-start` routing)
- Almost never for the main implementation loop

The main feature/task work runs in the **parent context**. Per `CLAUDE.md`:

> "Why in-context and not via Agent spawn: the `Agent` tool is one-shot — a subagent that pauses for human input can't be resumed, which forced each human pause to respawn a fresh subagent and lose mid-step state. Running orchestration in the parent keeps the user dialogue continuous."

That's a real, considered tradeoff documented in this repo's history. It's at odds with superpowers' choice.

### Verification

**Superpowers** has one general-purpose verification skill (`verification-before-completion`) and one debugging skill (`systematic-debugging`). The Iron Law:

> "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE"

Every claim of "done" must be backed by a verification command run *in this message* (not "I ran it earlier" — that's explicitly forbidden as a rationalization).

**This repo** has a **per-phase four-step verify loop**:

```
build → verify-auto → verify-self → verify-human → verify-codify
```

- `verify-auto` — automated tests + lints
- `verify-self` — agent observes the running system (added in WP7 to close the "ship without ever observing it" gap)
- `verify-human` — human walks through the observable outcomes the plan declared up-front
- `verify-codify` — write the codified regression test, with a Test Triage gate (six-case table) if a test fails

Plus a severity taxonomy (`BLOCKING` vs `COSMETIC` in verify-self) that determines whether to back-loop to build or note-and-continue.

These are different shapes of the same instinct. Superpowers has **one absolute rule** ("verify before claiming"); this repo has **a layered loop with named failure modes**. Superpowers' approach is simpler. This repo's is more discriminating — it answers questions like "what counts as verified?", "what to do if a test fails post-implementation?", "what if the agent verified but the human disagrees?".

### Persistence

**Superpowers is largely stateless across sessions.** Plans and designs are markdown artifacts the user holds onto. There's no equivalent of `workflow/.session.md` or `workflow/wip/<feature>.md`. If you pause mid-plan and come back tomorrow, you re-prime the agent by pointing it at the plan file. The agent's *workflow state* (which task is in progress, which phases are done) lives in the plan checkboxes and git commits.

**This repo treats workflow state as a first-class file.** From `vision.md`:

> "State is a file, not a memory. The canonical record of any in-progress work is a markdown file on disk — inspectable, diffable, git-trackable, recoverable. If it only exists in conversation context, it does not exist."

The Work Tree format (recursive tree of phases/leaves with `NOT-STARTED`/`in-progress`/`FAILED`/`BLOCKED`/`SURFACED`/`[x]` status), `## Current Node` pointer, `## Discoveries` section — that's a structured workflow state representation that superpowers doesn't have an equivalent of.

This is one of the most substantive divergences. It maps directly to the philosophical split: superpowers trusts the plan-as-artifact + agent-context-at-runtime; this repo distrusts conversation context and externalizes everything to disk.

### Handling discoveries (the SURFACE/ESCALATE/REDIRECT mechanism)

**This repo has explicit, named cross-level mechanisms** for the discoveries real work generates:
- **SURFACE** (lower → higher): log to `workflow/backlog.md`, optionally pause-and-escalate
- **ESCALATE** (task → feature): absorb the work into a higher-level item
- **REDIRECT** (build → research): pause current workflow, run sideways workflow, resume

**Superpowers has no equivalent.** A discovery during plan execution gets handled by... going back to the user? The skill prompts don't formalize this. The closest analog is that an implementer subagent can return `NEEDS_CONTEXT` or `BLOCKED`, but those bounce up one level to the SDD controller, not across workflows.

This is a real gap in superpowers, in my read. ⚠ **But:** their answer might be "real work has one shape, so cross-level mechanisms are over-engineering." That's defensible.

---

## 3. Concrete Primitives

### Skill inventory comparison

| Concept | Superpowers (15) | This repo (35) |
|---|---|---|
| Design / spec | `brainstorming` | `feature-spec`, `product-vision`, `product-arch` |
| Planning | `writing-plans` | `feature-plan`, `task-plan`, `product-roadmap`, `product-wbs` |
| Implementation | `executing-plans`, `subagent-driven-development` | `feature-build`, `task-act` |
| Verification | `verification-before-completion`, `test-driven-development` | `feature-verify-auto/-self/-human/-codify` |
| Debugging | `systematic-debugging` | `debug-bisect-known-good` + caller-skill prose |
| Code review | `requesting-code-review`, `receiving-code-review` | (Implicit in `verify-human` + `feature-finalize`) |
| Worktrees / isolation | `using-git-worktrees` | (Harness-native; mentioned in CLAUDE.md) |
| Finishing | `finishing-a-development-branch` | `feature-ship`, `feature-finalize`, `task-close` |
| Parallelism | `dispatching-parallel-agents` | (Implicit; Agent tool docs cover it) |
| Meta / writing skills | `writing-skills`, `using-superpowers` | (No skill — convention lives in CLAUDE.md + check-structure.sh) |
| Sessions | (none) | `session-start/-pause/-resume/-reflect/-store-learning` |
| Incidents | (none) | `incident-report/-triage/-investigate/-mitigate/-codify/-resolve` |
| Product strategy | (none) | `product-vision/-roadmap/-research/-arch/-wbs/-context/-finalize` |
| Reproduction discipline | (none) | `feature-reproduce`, `incident-reproduce` |
| Research | (none) | `feature-research`, `product-research` |
| Refactor | (none) | `feature-refactor` |

The pattern: **superpowers' skill set is narrow and deep on the feature/development arc; this repo's is wide and tries to cover the whole lifecycle of a software project.** Superpowers has *more polish per skill*; this repo has *more skills*.

### Hooks

**Superpowers** has *one hook*: `SessionStart`. It reads the `using-superpowers` skill content and injects it into context. That's it. Harness detection is dynamic (it reads env vars for Claude Code, Cursor, Copilot CLI, etc., and emits the right JSON shape per harness).

**This repo** has *one hook*: `notify-telegram.sh`, wired to `Notification` and `Stop` events. It pings Telegram when the agent is blocked or a turn ends. Process orchestration is *not* hook-driven.

Both authors made the same call: **don't hook process conformance**. (Even superpowers, despite its coercive language, doesn't use hooks to enforce anything — it relies on the agent reading the bootstrap and respecting it.)

### Slash commands

**Superpowers:** essentially none in the plugin itself (Claude Code's native skills auto-trigger on context match).

**This repo:** every workflow state has a slash command (e.g., `/feature-spec`, `/incident-investigate`). The entry-point pattern (`/session-start` for orchestration, individual commands for single-step invocation) is a primary user surface.

This is a real ergonomic difference. Superpowers expects the agent to discover the right skill from context; this repo lets the user (or `/session-start`) be explicit.

### Multi-harness

**Superpowers' multi-harness story is genuinely impressive.** Per the report:

- `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`, `.opencode/`, `gemini-extension.json`
- A single SessionStart hook that detects the harness at runtime and emits the right JSON shape
- Sync script (`scripts/sync-to-codex-plugin.sh`) that mirrors the canonical version to OpenAI's plugin marketplace
- A `tests/codex-plugin-sync/` directory verifying the sync works

The skill content itself is harness-agnostic (markdown + frontmatter). All the harness-specific logic is concentrated in the bootstrap hook + plugin manifests.

**This repo is single-harness.** It installs via `install.sh` symlinks into `~/.claude/`. The skills, hooks, and orchestrator agents all assume Claude Code's specific affordances (the Skill tool, the Agent tool, the slash-command system, the per-skill SKILL.md format).

Re-platforming this repo to support Codex/Cursor/Gemini would be a significant project — not just because of the file layout but because some skills lean on Claude Code's specific Agent tool semantics (parent context preservation through pauses, etc.).

⚠ **Bias flag:** I want to be careful not to frame this as "superpowers wins on multi-harness." This repo's vision explicitly targets *the author's own Claude Code use*. Single-harness isn't a bug; it's a scope decision. The criticism only lands if you're trying to use this repo on multiple harnesses.

### Tests

**Superpowers** has three test levels per the deep-read:
- Skill unit tests (verify skill content + load + completeness)
- Integration tests (real test project + full SDD execution)
- Behavioral pressure tests (plant SQL injection bugs, verify reviewer catches them)

The tests literally invoke `claude` headlessly and assert against the output. Discipline-checking-discipline.

**This repo** has structural tests (`tests/check-structure.sh`: YAML validity, frontmatter conventions, required sections per category, byte-pinned design canvas, etc.) + transition tests (`tests/run-tests.sh`: scenarios assert "given input X, skill emits TRANSITION Y", run on haiku for cheap signal, escalate to sonnet only when haiku produces model-noise).

These are different things. Superpowers tests *behavior under pressure*; this repo tests *transitions fire correctly and structure is well-formed*. The deep-read on superpowers reports "tests verify subagent behavior, code quality, regression prevention." This repo's tests don't reach that level of behavioral assertion — they verify the *machine signal*, not the *quality of work that comes out*.

### File layout

**Superpowers' source tree:**
```
skills/<skill-name>/SKILL.md   # + occasional supporting files like prompts
hooks/session-start             # one bash script
.claude-plugin/, .codex-plugin/, … # per-harness plugin manifests
scripts/                        # sync + version bump
tests/<feature>/                # per-feature test groups
docs/, CLAUDE.md, RELEASE-NOTES.md
```

**This repo's source tree:**
```
skills/<skill-name>/SKILL.md   # one per state
agents/<workflow>-workflow/AGENTS.md  # orchestrator per workflow group
hooks/notify-telegram.sh
install.sh                     # symlink installer
tests/check-structure.sh       # structural lint
tests/run-tests.sh             # transition tests
tests/scenarios/*.yaml         # scenario definitions
docs/product/                  # vision.md, roadmap.md, arch.md, wbs.md, etc.
workflow/                      # WIP, backlog, archive, session pointer
CLAUDE.snippet.md              # global injected into ~/.claude/CLAUDE.md
```

The biggest structural difference is the **orchestrator agents** — `agents/<workflow>-workflow/AGENTS.md` files that hold the full state-machine view and an Orchestration Procedure that `/session-start` reads. Superpowers has no analog; its closest move is the `using-superpowers` skill's "skills override default behavior" framing, which is much lighter-weight.

---

## 4. Pros and Cons Per Side

### Superpowers — strengths

1. **Rationalization-resistance language is in a different league.** The Red Flags tables in `test-driven-development`, `verification-before-completion`, `systematic-debugging` are specific to a degree this repo isn't. They name "I'm tired and wanting work over", "Just this once", "Partial check is enough" — exact phrases the model has been observed to use. This is pressure-tested wording.

2. **TDD-as-a-skill structure.** `writing-skills/SKILL.md` literally applies Red-Green-Refactor to skill authorship: write pressure scenarios, baseline failure, write skill, verify compliance, refactor to close loopholes. This repo's skill authorship convention is "follow the patterns" + check-structure.sh — much less rigorous.

3. **Subagent-driven development is a coherent, named pattern.** Whether or not you adopt it, it's worth knowing. Two-stage review (spec compliance ≠ code quality) is a real insight.

4. **Multi-harness from day one.** Same content, harness-specific manifests, runtime detection. A real engineering achievement.

5. **Behavioral testing of skills.** Planting real bugs and verifying reviewer catches them is meaningfully stronger than asserting "transition X fires."

6. **Single coherent narrative.** A user can read superpowers' README in 5 minutes and know what they're getting. This repo's vision is sharper but the surface area is wider, harder to onboard a stranger to.

### Superpowers — weaknesses

1. **Waterfall rigidity.** Design → spec → plan → execute is strictly sequential. No formal mechanism for "execution revealed the spec is wrong; back-loop to brainstorming." The system expects specs to be comprehensive upfront — which they often aren't.

2. **No workflow state on disk.** Pause mid-plan, come back next week, you re-establish context by manually pointing the agent at the plan. No `.session.md`, no `## Current Node`. The Work Tree concept is missing.

3. **No cross-level mechanisms.** A discovery during plan execution doesn't have a formal home. It bounces back to the user as `BLOCKED` or `NEEDS_CONTEXT`.

4. **One workflow shape.** No special handling for incidents (which need investigate-before-fix discipline), no product-strategy layer (vision/roadmap/wbs), no atomic-change "task" workflow for one-line bug fixes. Everything is a "development task."

5. **The coercive framing has costs.** "YOU DO NOT HAVE A CHOICE" works for the failure modes it names, but it also pre-commits the agent to a workflow even when the user wants something simpler. A 5-line config tweak doesn't need brainstorming → spec → plan → SDD. ⚠ Bias flag: I'm reading this from a single skim, not from operating the system in anger.

6. **Subagent cost.** SDD is 3+ subagent invocations per task (implementer + 2 reviewers). For a 10-task plan, that's 30+ subagent dispatches. The system claims this catches issues early, but I see no break-even analysis in the docs.

7. **Verification-fatigue at scale.** "Iron Law: no completion claim without fresh verification evidence" is absolutist. It catches real failure modes but creates real friction in long sessions.

### This repo — strengths

1. **Workflow state externalized to files.** The Work Tree format + `.session.md` + `workflow/wip/` is a real architecture for cross-session continuity. Superpowers doesn't have this.

2. **Four workflows that match real work shapes.** Product strategy, feature implementation, atomic tasks, incident response — each has its own machine. Same conceptual basis as superpowers but more honest about variety.

3. **Per-phase verify loop is more discriminating than one Iron Law.** `verify-auto/-self/-human/-codify` with severity taxonomy (BLOCKING vs COSMETIC) gives the agent more nuanced handling than "did you run the command? prove it."

4. **Cross-level mechanisms (SURFACE/ESCALATE/REDIRECT) are formalized.** Real work generates work; the system has named primitives for routing it.

5. **Test Triage gate at `verify-codify`.** The six-case triage table (regression high/low, obsolete-test high/low, contract conflict, flaky) is a discrimination superpowers doesn't have — it forces the agent to *classify* a test failure before fixing it.

6. **The `debug-*` sidebar category.** Recognizing that some skills are *agent-pulled tools* (not workflow states) is a real conceptual move. Three structurally-enforced discoverability surfaces (caller-skill prose, AGENTS.md subsection, transitions.md note) is a thoughtful pattern.

7. **Advisory enforcement preserves agent judgment.** When the agent encounters an edge case the state machine didn't anticipate, it can make a call. Superpowers' coercive framing makes this harder.

8. **Dogfooded.** This repo uses its own workflow system on itself — `docs/product/vision.md` *is* the vision *for* the workflow system. There's a feedback loop superpowers doesn't have in the same way.

### This repo — weaknesses

1. **Surface area is large.** 35 skills, 4 agents, 63 transitions. Onboarding a stranger (or future-you) is harder than superpowers' 15-skill flat library.

2. **Single-harness.** Claude Code only. Re-platforming would be substantial.

3. **No behavioral pressure tests of skill language.** Tests verify transitions fire and structure is well-formed; they don't verify "if you say 'I'm tired' to the agent, does the skill actually resist?" Superpowers does this.

4. **Rationalization-resistance language is less specific.** This repo's skill prose tends toward declarative ("write observable outcomes at plan time") rather than naming the exact rationalizations the model makes. Superpowers' Red Flags tables are sharper.

5. **No equivalent of `writing-skills/SKILL.md`'s TDD methodology.** Adding/modifying a skill in this repo means reading CLAUDE.md and following the patterns. Superpowers makes skill authorship itself a skill, with its own RED-GREEN-REFACTOR.

6. **No formal code-review skills.** `verify-human` covers some of this, but the dedicated `requesting-code-review` and `receiving-code-review` skills in superpowers (with explicit rules like "NEVER say 'You're absolutely right!'") are useful primitives that don't have a clear home here.

7. **The advisory-vs-coercive bet hasn't been pressure-tested.** This repo asserts "agents can exercise judgment at edges." Superpowers asserts they can't. Both can't be right in all cases. Without behavioral pressure tests of this repo's skills, the bet is unfalsified.

---

## 5. Recommendations — What to Borrow

Listed in rough order of expected ROI, weighted toward things that *don't conflict with this repo's existing principles*.

### High-ROI borrows

#### 5.1. Red Flags tables in discipline-enforcing skills

**Take from:** `superpowers/skills/test-driven-development/SKILL.md`, `verification-before-completion/SKILL.md`, `systematic-debugging/SKILL.md`.

**Apply to:** `feature-verify-auto`, `feature-verify-self`, `feature-verify-human`, `feature-verify-codify`, `incident-codify`. Possibly `task-act` and `feature-build`.

**Why:** This is the single sharpest piece of language work in superpowers. Naming specific rationalizations ("I'm tired and wanting work over", "Should pass means probably does", "Just this once is enough", "Partial check is enough") and explicitly forbidding them is a different intervention than declarative skill prose. It catches the agent's self-talk at the moment of failure.

**How to apply without breaking this repo's principles:** Frame the Red Flags as *advisory escalation triggers*, not coercive blocks. Something like: "If you notice yourself thinking any of the following, pause and tell the human: …" That preserves the "agents can exercise judgment at edges" principle while importing the language sharpness.

**Cost:** Mostly prose-writing. A few hours per skill to draft, then pressure-test against the model.

#### 5.2. Behavioral pressure tests of skill language

**Take from:** `superpowers/tests/skill-triggering/`, `tests/subagent-driven-dev/`, and the testing methodology in `writing-skills/SKILL.md`.

**Apply to:** Augment `tests/run-tests.sh` with a new scenario class: *pressure scenarios*. Given an input that includes a rationalization-shaped fixture ("It's late, the test is flaky, just claim it passes"), assert the skill resists.

**Why:** This repo's current tests verify transitions fire, not that the skill *survives pressure*. Without that, every claim about skill language quality is unfalsified. Superpowers' approach makes "is this skill actually working?" a testable question.

**How:** Add a `tests/scenarios/pressure/` directory. Each scenario is a YAML file with a fixture containing rationalization-shaped input + an expected behavior assertion (e.g., "must contain 'STOP' or 'verify' or escalation language"). Run on sonnet (haiku won't show the failure mode reliably enough).

**Cost:** Real engineering effort. Probably one WBS work package.

#### 5.3. Two-stage review (spec compliance ≠ code quality)

**Take from:** `superpowers/skills/subagent-driven-development/SKILL.md`'s two-reviewer model.

**Apply to:** `feature-verify-human` and/or `feature-finalize`. Currently `verify-human` mixes "did it do what the plan said?" with "is it well-built?" — those are different questions that benefit from different lenses.

**Why:** Spec compliance is binary. Code quality is judgment. Mixing them in one review means the spec-compliance failure mode ("you implemented the wrong thing") gets confused with the code-quality failure mode ("the implementation is ugly"). Separating them clarifies what to fix.

**How:** Split `feature-verify-human` into two passes (could be the same human, two checklists): spec-compliance pass first, then code-quality pass. Or: split into `feature-verify-spec-compliance` + `feature-verify-code-quality` as two leaves under verify-human.

**Cost:** Moderate. One feature cycle.

#### 5.4. A `writing-skills` skill of our own

**Take from:** `superpowers/skills/writing-skills/SKILL.md` — the RED-GREEN-REFACTOR methodology for skill authorship.

**Apply to:** This repo currently captures skill-authorship convention in CLAUDE.md + check-structure.sh. That's good for structural conformance but poor for *behavioral conformance*. A dedicated `writing-skills` skill (or `meta-writing-skills`, to avoid namespace collision) that applies RED-GREEN-REFACTOR to skill authorship would tie 5.2 to a concrete workflow.

**Why:** If skill language is to be tested under pressure (5.2), there should be a skill that *makes* the test the gate for shipping. Otherwise it's optional and gets skipped.

**How:** Mirror superpowers' structure: pressure-test the baseline → write minimal skill → verify under same pressure → refactor for loopholes. Wire it into the contributing convention.

**Cost:** Moderate. Builds on 5.2.

### Medium-ROI borrows

#### 5.5. Worktree-isolation skill

**Take from:** `superpowers/skills/using-git-worktrees/SKILL.md`.

**Apply to:** Add a `task-isolate` or `feature-isolate` skill, or integrate into `task-plan` / `feature-plan`. Currently this repo's worktree story is "use the harness affordance" — there's no skill that ensures it's actually used or that auto-detects existing isolation.

**Why:** Genuinely independent work benefits from isolation. The skill's specific value is in the *detection logic* — "is the harness already isolating us? Then don't double-isolate. Is the directory in `.gitignore`? Verify before creating." Edge cases superpowers has thought through.

**Cost:** Low if borrowed mostly verbatim. The skill is portable.

#### 5.6. Reviewer subagent prompts as artifacts

**Take from:** `superpowers/skills/requesting-code-review/` and `receiving-code-review/`'s use of `code-reviewer.md`-style prompt templates.

**Apply to:** When this repo spawns subagents (Explore, Plan, general-purpose), the prompts are constructed at call site. Superpowers' pattern is to store reviewer/implementer prompts as separate files and reference them. That separation lets you pressure-test the prompt independently of the calling skill.

**Why:** Subagent prompts are load-bearing and currently invisible — they live in skill prose, not separate files. Externalizing them is a small change with real readability and testability benefits.

**Cost:** Low. Refactor.

#### 5.7. Multi-harness *thinking*, even if not multi-harness *shipping*

**Take from:** Superpowers' separation between *skill content (harness-agnostic)* and *bootstrap mechanism (harness-specific)*.

**Apply to:** This repo's skills lean on Claude-Code-specific affordances (the Skill tool, slash commands, the Agent tool semantics). The skill *content* could be more harness-agnostic — describing intent and procedure, with harness-specific tool names abstracted. Even if shipping to other harnesses isn't a goal, doing the abstraction makes the skills *more legible to humans reading them* and *less brittle to Claude Code changes*.

**Why:** Future-proofing. Also: clarity. Right now skills mix "what the agent should do" with "which Claude Code tool to use." Separating these makes the *what* sharper.

**Cost:** Moderate. Touches many files. ⚠ **Bias flag:** I might be over-valuing this. Single-harness is a deliberate scope decision in `vision.md`. Don't take this borrow on if it dilutes the focus.

### Low-ROI / context-dependent

#### 5.8. Subagent-driven development as an alternate execution mode

**Take from:** `superpowers/skills/subagent-driven-development/SKILL.md`.

**Why this is risky:** This repo *deliberately* runs the main work in parent context, citing "the Agent tool is one-shot — a subagent that pauses for human input can't be resumed." That's not a small consideration. SDD-as-primary would force a redesign of how `verify-human` interacts with execution.

But there's a narrower borrow: **SDD-as-an-option for long, well-specified, low-uncertainty phases.** If a phase has clear observable outcomes, no ambiguity, and 5+ leaves, dispatching to a subagent (with two-stage review) might be net-positive. This would be opt-in, not default.

**Cost:** High. A new mode is a new state machine wing.

#### 5.9. Continuous-execution-with-explicit-blockers framing

**Take from:** Superpowers' SDD principle: "Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete."

**Apply to:** This repo's `feature-build` already runs through phase leaves without pausing. But the *language* in superpowers is sharper: it pre-commits the agent to a stance ("don't pause unless blocked"), which is more resistant to over-checking-in than this repo's prose.

**Why narrow:** This is a small prose update, not an architectural change. Could be a paragraph in `feature-build/SKILL.md`.

**Cost:** Trivial.

### Don't borrow

#### "YOU DO NOT HAVE A CHOICE" coercive framing.

This is incompatible with this repo's "advisory enforcement" principle. Importing it would break the worldview, not just the prose. If anything, pressure-test the advisory framing (5.2) and decide whether to stay with it on evidence.

#### One-workflow shape.

Superpowers' flat methodology works because it stays narrow. This repo's variety (product/feature/task/incident) is a deliberate scope choice that reflects actual work shapes. Compressing back to one would lose what this repo is for.

#### Stateless-across-sessions.

This repo's `.session.md` and Work Tree are core differentiators. Don't trade them for plan-as-artifact alone.

---

## 6. The honest assessment

⚠ **Final bias flag:** I've spent the whole turn in this repo's frame. My analysis is more sympathetic to *this* repo than is strictly warranted by an outside reader who knows neither system. Specifically:

- I'm undervaluing **superpowers' empirical grounding**. Their RELEASE-NOTES.md describes pressure-testing with measured outcomes ("regression testing across 5 versions with 5 trials each showed identical quality scores regardless of whether the review loop ran"). This repo's principles are stated; superpowers' are tested.
- I'm overvaluing **the breadth of this repo's workflow taxonomy** without asking whether all four workflows are *used* with equal frequency. Maybe 80% of real use is feature/task; product and incident are scaffolding for a 20% case. If so, the "wide vs. deep" framing tilts back toward superpowers.
- I'm framing **superpowers' coercive language as a "philosophical choice"** when it might just be *what works against the model's actual failure modes*. The author has more direct evidence on this than I do.

If I had to summarize honestly: **superpowers is more empirically-grounded, has sharper language, ships to more harnesses, and is easier to onboard. This repo has a more accurate model of the shape of real work, persistent workflow state, and a cleaner separation between state-machine workflows and agent-pulled sidebars.** Both authors made the right calls for the audience they were building for.

The biggest single thing this repo could borrow is the **pressure-testing methodology** (5.2 + 5.4). It would force the "advisory enforcement" principle to either survive empirical contact or get sharpened. Either outcome is healthy.

---

## Appendix — Pointers to the source material

- Superpowers repo (cloned to `/tmp/superpowers-analysis/superpowers/`)
- Superpowers README → `/tmp/superpowers-analysis/superpowers/README.md`
- Superpowers agent-guidelines → `/tmp/superpowers-analysis/superpowers/CLAUDE.md`
- Bootstrap skill → `/tmp/superpowers-analysis/superpowers/skills/using-superpowers/SKILL.md`
- TDD discipline reference → `/tmp/superpowers-analysis/superpowers/skills/test-driven-development/SKILL.md`
- Iron Law of verification → `/tmp/superpowers-analysis/superpowers/skills/verification-before-completion/SKILL.md`
- Subagent-driven model → `/tmp/superpowers-analysis/superpowers/skills/subagent-driven-development/SKILL.md`
- Skill authorship as TDD → `/tmp/superpowers-analysis/superpowers/skills/writing-skills/SKILL.md`
- Pressure-test methodology → `/tmp/superpowers-analysis/superpowers/tests/skill-triggering/` and `tests/subagent-driven-dev/`
- Multi-harness mechanism → `/tmp/superpowers-analysis/superpowers/hooks/session-start` + per-harness `.{harness}-plugin/plugin.json`
- This repo's vision → `docs/product/vision.md`
- This repo's CLAUDE.md (state-machine architecture) → `CLAUDE.md`
- This repo's Work Tree format → `CLAUDE.snippet.md` / global `CLAUDE.md` snippet
