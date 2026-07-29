---
name: feature-spec
description: "Feature workflow: define requirements and specification for a complex feature"
argument-hint: <feature request or description>
---

# Feature Spec

You are an expert Product Engineer defining the specification for a complex feature.

## State Machine Context

You are in the **feature** workflow at the **spec** state.

This state is the entry point for **complex** features — those that fail the small/simple criteria:
1. Requires new data models or API endpoints
2. Requires architectural decisions
3. Cannot be described in ≤ 4 sentences
4. Estimated ≥ 4 hours of agent work
5. Estimated > ~200 lines of new/changed code

**Valid transitions from here:**
- **F3 → research:** Unknowns exist that need investigation
- **F4 → plan:** No unknowns, spec is clear → tell user to run `/feature-plan`

**Bug-fix discoverability:** If `{{args}}` describes an undesirable behavior (bug, regression, broken state, wrong output) and you have not been entered via F32/F34 from `feature-reproduce`, surface a one-line suggestion to the user: "If this describes a bug-fix or regression and you haven't run reproduction, consider running `/feature-reproduce` first to capture a failing test before specifying the fix." Then proceed with spec — this is a soft pointer, not a gate.

## Orchestrator Pause Policy (cheat-sheet)

When invoked by `/session-start` in orchestrated mode, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause. Per-skill rows for spec's exits:

| Transition | Mode 1 — Stepping | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — FSD |
|---|---|---|---|---|
| Skill invocation (entry — spec review point) | PAUSE | **PAUSE** | **PAUSE** | AUTO |
| F3 (spec → research, unknowns exist) | PAUSE | (pause already taken at entry) | (pause already taken at entry) | AUTO |
| F4 (spec → plan, spec is clear) | PAUSE | (pause already taken at entry) | (pause already taken at entry) | AUTO |

**Hard rule for AUTO exits.** In Mode 4 (FSD), spec is AUTO — when this skill's emitted transition is `F3` or `F4` in Mode 4, the orchestrator **must immediately invoke the next skill** (`feature-research` or `feature-plan`) **via the `Skill` tool**. It must **NOT** return control to the user. Emitting a clean `TRANSITION: F4` followed by a polite narrative summary ("Spec complete; ready to run plan") in Mode 4 is the regression mode this block exists to prevent (P1 incident, 2026-05-16, scope-extended 2026-05-17): the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. **This explicitly includes the `AskUserQuestion` tool (and any other user-input/confirmation prompt): invoking it on an AUTO transition IS "returning control to the user" and is the same regression class as the narrative-summary stop above — do NOT call it to "just confirm" the handoff. The only thing that pauses an AUTO transition is the human-input points the active drive mode's pause policy explicitly marks PAUSE.**

In Modes 1–3 the user reviews the spec before plan — that pause is taken at skill *entry* (the spec presentation is the pause). After the user's response, exits F3/F4 then chain forward without a second pause. See `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## Step 0: Available product context

Before eliciting requirements, ground the spec in current strategic context. Run `ls workflow-system/product/` to see which docs exist. The docs you may find:

- `workflow-system/product/arch.md` — architectural decisions and system design
- `workflow-system/product/wbs.md` — active work breakdown structure (current cycle)
- `workflow-system/product/design-priors.md` — the operator's product-design decision leans
- `workflow-system/product/vision.md` — high-level product vision
- `workflow-system/product/roadmap.md` — strategic roadmap
- `workflow-system/product/research.md` — cycle-scoped research findings

**Eager read — `arch.md`, `wbs.md`, AND `design-priors.md`:** spec is the most upstream complex-feature decision point, and divergence from architecture or the active WBS cycle is expensive to unwind downstream. Read all three (when present) at the start of step 1 below.

**Consult `design-priors.md` (product-design gaps):** when the spec leaves a product-design tradeoff open (focus-vs-breadth, perf-vs-ship, defaults-vs-config, anti-persona, …), apply the consult-weighting rules: (1) no prior governs → common sense untouched; (2) prior agrees → take it, higher confidence; (3) prior breaks a genuine tie → lean + disclose; (4) clear default *contradicts* a strong prior → surface as a proposal, never silently steer; (5) a prior only fires on the axis it is actually about (**over-infer guard**). Disclose a firing prior with `[PRIOR: <slug>] leaning <x> — flag if wrong`; priors are overridable by strong common-sense evidence (disclose the override).

**Capture a design prior (if the operator reveals one):** spec elicitation is also a capture checkpoint — operator answers about scope/persona/tradeoffs often reveal a transferable product-design lean. If the operator's input meets the **capture discriminant** (product-design tradeoff or identity/non-goal/anti-persona + a *transferable why*), **propose** recording it to `design-priors.md` (propose-never-auto-write; operator reviews/enriches the why; dedup/conflict-check first). **Exclusions:** technical/stack tradeoffs → `arch.md`; bare preferences / scope-adds → not a prior. See `CLAUDE.snippet.md` → "Design priors (GLOBAL)".

**Size guard:** if `arch.md`, `wbs.md`, or `design-priors.md` exceeds ~300 lines, read only the first 100 lines of that file (via the `Read` tool's `limit:` parameter) plus a `Grep` for `^#+ ` headings to capture structure. Append one line to the WIP file's `## Discoveries` section: `[SURFACED-<date>] feature-spec — <doc>.md exceeds size guard (N lines), truncated to first 100. Consider summarizing.`

**`vision.md`, `roadmap.md`, `research.md`:** pointer-only. These are too high-level (vision/roadmap) or too cycle-scoped (research) to mechanically constrain a spec. If your reasoning surfaces a question they'd answer, read them on your own initiative.

**Absent files:** silent no-op. No warning, no prompt. Many projects deliberately skip product docs.

See `CLAUDE.snippet.md` → "Entry-skill product-context loading (GLOBAL)" for the canonical mapping these rules follow.

## Procedure

### 1. Elicit Requirements
- Ask the user questions to clarify scope, user persona, and success criteria
- Identify technical and business constraints
- If this came from a SURFACE-IN (F28: task escalated to feature), read the source task's WIP file for context

**Elicitation discipline — grill the problem, one question at a time.** The operator cannot evaluate a spec's *silences*: reading a finished spec they check what is on the page, not the decision you quietly defaulted. So surface the consequential defaults as questions instead of burying them. Scope this to the **problem-definition** sections of the §3 template — Problem Statement, User Stories, Acceptance Criteria, Out of Scope — **not** Technical Constraints (technical/architectural choices are a different shape of question; they want synthesize-then-confirm-the-seams, not an interview).

Ask a question **only when all three clauses hold** — this is a conjunction, not a checklist:

- **(a) Not discoverable** — the answer cannot be found by reading the codebase, running a tool, or checking a doc. If it can, **look it up instead of asking**. Facts are yours to find; decisions are the operator's to make.
- **(b) The operator's to decide** — a genuine judgment call about intent, priority, or acceptable tradeoff, not a detail you are competent to settle.
- **(c) Expensive to reverse** — a wrong guess costs real rework later. If it is cheap to correct once someone notices, **do not ask**: take the sensible default and record it as an assumption.

Clause (c) is what keeps this from becoming friction. A name, a label, an ordering, or a message's wording passes (a) and (b) but fails (c) — and three verification gates downstream (`verify-auto`, `verify-self`, `verify-human`) already catch cheap mistakes.

Mechanics: **one question per turn** (never batch — several at once produces shallow answers to all of them); **attach your recommended answer** to each so the operator can confirm in one word and see where *your* model is wrong; **order by dependency** (settle the upstream decision first). Then close with both lists:

- **Asked** — the questions put to the operator, and their answers.
- **Assumed** — every default taken *without* asking, each stated explicitly. **This list is not optional**: it is what keeps ordinary spec review a real backstop for the questions you chose not to ask.

**The budget is a filter, not a cap.** Do not target a question count. **Zero questions is a correct and common outcome** for a well-specified request; a genuinely fuzzy one may earn several. A short `Asked` list with a well-populated `Assumed` list is the target shape, not a shortfall.

**Drive-mode behavior — the existing rule, not a new one.** Grilling is a user-input prompt, so the **Hard rule for AUTO exits** above already governs it: invoking a user-input or confirmation prompt on an AUTO transition *is* returning control to the user. Consequently, in **Mode 4 (FSD)** — where spec is AUTO — **grilling does not fire at all**; state your assumptions and proceed. In Modes 1–3 the spec pause is taken at skill *entry*, so grilling **reshapes a pause that already exists** rather than adding one. **No pause-policy row is added for grilling** — it emits no transition and schedules nothing. Full discipline: `skills/util-grill-me/SKILL.md` (also reachable standalone as `/util-grill-me`).

**Before presenting UI/UX options in prose, check the mockup trigger.** When you are about to lay out several candidate designs for the operator to choose between, and **both** of these hold:

- **(a)** there are **≥2 concrete alternatives for a single element, widget, or component**, and
- **(b)** the difference between them is **spatial or visual, such that prose or ASCII loses it**,

then prose is the wrong medium — recommend `/util-option-mockup` and pause for the operator to run it. **The self-test for clause (b):** *can you state the difference in one sentence and be confident the operator pictures the same thing you do?* If yes, write the sentence. If no, clause (b) holds.

Why this is a gate and not a nicety: files give **structure**, they do not give **cost**, and layout decisions are decided by cost. A confident verdict reached by careful file-reading can still answer the wrong question — the failure mode is a framing error, which no amount of rigor *inside* the frame recovers.

Do **not** fire on copy/naming/color-only choices, behavior choices with no layout change, or a difference ASCII conveys fine. Really simple UI/UX choices don't need a mockup. Full trigger, the does-not-fire list, and the construction requirements live in `skills/util-option-mockup/SKILL.md`.

### 2. 3rd-Party Probe Check

Before writing the spec, check whether this feature depends on any 3rd-party service, external API, or SDK (e.g. Stripe, Twilio, SendGrid, AWS, Google Maps, an OAuth provider, any API you don't own).

**If a 3rd-party dependency is present:**
1. Check `workflow-system/product/wbs.md` (if it exists) for a completed Probe WP covering that integration.
2. If no probe WP exists or none is marked complete — this is a **known unknown**. Flag it explicitly:

> ⚠️ **Known unknown — probe required before planning**
> This feature depends on [service/API name], but no completed probe WP exists for it. The API's request/response shapes, auth model, rate limits, and error codes are unverified assumptions.
> **Recommended action:** Run a spike task first to document the integration's I/O shapes. Then return to `/feature-spec` with that knowledge in hand.
> If you want to proceed anyway, note that the plan may need significant revision once the probe is complete.

3. If a completed probe WP exists — note it in the spec under **Technical Constraints** and proceed.

**If no 3rd-party dependency is present:** skip this step and continue.

### 3. Create Specification
Create `workflow-system/state/wip/<feature-name>.md` with this structure:

```markdown
# Feature: <title>

**Workflow:** feature
**State:** spec
**Created:** <YYYY-MM-DD>
**Entry:** spec (complex feature)

## Problem Statement
What are we solving?

## User Stories
- As a <role>, I want <feature> so that <value>

## Acceptance Criteria
- The feature is done when...

## Out of Scope
- What we are NOT doing

## Technical Constraints
- Known constraints and dependencies

## Open Questions
- [ ] Any unknowns that need research
```

### 4. Evaluate Next Step
- If there are open questions or unknowns → recommend `/feature-research` (F3)
- If the spec is clear and complete → recommend `/feature-plan` (F4)

**Single-step mode only:** STOP after creating the spec — do NOT start planning or implementing. In orchestrated/autopilot/fsd modes the orchestrator decides whether to pause or chain per the **Orchestrator Pause Policy (cheat-sheet)** block at the top of this SKILL. The hard rule for AUTO exits applies — see that block.

**User Request:** {{args}}
