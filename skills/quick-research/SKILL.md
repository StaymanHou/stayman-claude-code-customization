---
name: quick-research
description: "Fast, light web research: a quick WebSearch/WebFetch pass that returns confidence-labeled findings plus an explicit known-unknowns list — and offers to escalate to the heavyweight deep-research harness (only on your confirmation) when load-bearing gaps remain. The cheap default when you want a good-enough answer, NOT a multi-source verified report."
argument-hint: "<the question or topic to look up>"
---

# Quick Research

You are an expert researcher doing a **fast, light** web pass — the cheap tier of research. Your job is to get a **good-enough answer quickly** and be **honest about what you could not resolve**, so the operator can decide whether the question warrants the far more expensive `deep-research` harness.

## Category

**Standalone user-triggered research utility.** This skill is NOT part of any workflow state machine. It emits **no workflow transitions** (no F/I/T/P/S tokens) and **no `RETURN-TO:`** — it is not a state reached by a transition, and it is not a `debug-*` sidebar. The operator invokes it directly via `/quick-research`, OR a workflow skill may reach for it inline when it needs a fast external lookup (a workflow that needs an in-codebase spike uses `feature-research`; one scouting solutions for the next milestone uses `product-research` — see "The four research tiers" below). Like the `util-*` skills, it runs to completion and simply returns its findings; it does not advance any state machine.

## The four research tiers (read this to know you are the right skill)

"Research" spans a **cost spectrum**. Four skills sit on it — pick by *cost + surface*, not by the word "research":

| Skill | Tier / cost | Surface | Use when |
|---|---|---|---|
| **`quick-research`** (this skill) | **Light — fast, cheap** | The web (WebSearch/WebFetch) | You want a good-enough answer from a quick online look; a single-pass lookup will likely settle it. **The default for ad-hoc "look this up."** |
| `deep-research` (harness built-in) | **Heavy — slow, high token cost** | The web, many sources | You need a multi-source, adversarially-verified, **cited** report and the ROI justifies the cost (see "When deep-research is justified"). **Never the reflexive default.** |
| `feature-research` | In-workflow | This codebase + local data | A bounded technical **spike** inside a running feature to unblock the current phase. |
| `product-research` | In-workflow | Solutions/libraries for a milestone | Scouting technical options for the **next** development milestone, inside the product flow. |

If the request is a general "look something up online" — you are the right skill. If it is clearly one of the other three surfaces, say so and point the operator at that skill instead of proceeding.

## When to use

- The operator (or a workflow) wants a **quick factual answer, orientation, or precedent** from the web — "is X possible", "how do people usually do Y", "what does the doc say about Z", "did someone already open-source W".
- A single fast pass of a few good sources is *likely* enough to settle it, or at least to tell you whether a deeper pass is warranted.
- You are unsure whether the question justifies `deep-research` — **start here.** Quick-research is the cheap probe that either answers the question or surfaces exactly which gaps a deep pass would need to close.

## When NOT to use

- The answer must come from **this codebase or its local data** → use `feature-research` (in-feature spike).
- The task is **selecting a library/framework/approach for the next milestone** inside the product workflow → use `product-research`.
- You already know the question is **high-stakes, decision-reversing, or needs cross-source verification with citations** — and the operator has confirmed the cost is worth it → go straight to `deep-research` (do not do a throwaway light pass first just to be seen doing one).
- The question is not web-researchable at all (pure opinion, a decision only the operator can make) → just discuss it.

## Procedure

### 1. Frame the question
Restate what you are actually trying to answer in one line. If the request bundles several questions, list them — you will label confidence and known-unknowns per question, and a partial answer across several sub-questions is a normal and useful outcome.

### 2. Do the light pass
- Use `WebSearch` to find a handful of relevant, credible sources; use `WebFetch` to read the most promising one or two. **Keep it light** — this is a fast pass, not an exhaustive sweep. A few good sources, not dozens.
- Prefer primary/authoritative sources (official docs, the actual repo, the standard) over aggregators — but do not spend deep-research effort verifying; that is the escalation's job, not yours.
- If the codebase is the real source of a sub-question, note it and defer that part to `feature-research` rather than guessing from the web.

### 3. Report findings — with per-claim confidence labels (REQUIRED)
Present the findings as concise claims. **Every claim carries a confidence label and its source.** This is the non-negotiable output discipline of quick-research — a light pass is only safe to default to because it is honest about how much to trust each piece.

Use this shape:

```
Findings:
- [HIGH · <source>] <claim well-supported by an authoritative source>
- [MED · <source>]  <claim from one decent source / some inference>
- [LOW · <source|inference>] <weakly-supported, single-source, or extrapolated claim>
```

Confidence rubric:
- **HIGH** — stated directly by a primary/authoritative source (official doc, the standard, the actual code/repo), or corroborated by two independent credible sources.
- **MED** — one decent source, or a reasonable inference from adjacent facts; plausibly right but not nailed down.
- **LOW** — single weak source, community anecdote, or your own extrapolation; flag it as such.

Do not launder a LOW claim into prose that reads as settled. If you are inferring, the label is LOW and the source is `inference`.

### 4. List the known unknowns (REQUIRED)
After the findings, list **what the light pass could NOT resolve** — the gaps a deeper pass would need to close:

```
Known unknowns:
- <question the light pass left open, or a claim only reached LOW confidence>
- <a conflict between sources you did not adjudicate>
- <a sub-question that needs primary-source verification / cross-checking>
```

If there are genuinely no load-bearing unknowns — the light pass fully and confidently answered the question — say so explicitly (`Known unknowns: none load-bearing — the HIGH-confidence findings above settle the question`). An empty or hand-waved unknowns list on a question that clearly is not settled is the failure mode this section exists to prevent.

### 5. Offer escalation to deep-research — GATED ON HUMAN CONFIRMATION (never auto-launch)
Look at the known-unknowns list. **If load-bearing unknowns remain** (i.e., the operator's decision or next step actually depends on closing them), offer the escalation — do NOT start it:

> These N unknowns are unresolved by the light pass: `<list>`. The `deep-research` harness (multi-source fan-out + adversarial verification + a cited report) would close them, at a meaningfully higher time and token cost. **Want me to run deep-research on this?** (yes / no)

Then **stop and wait for the operator's answer.** This is a hard rule:

- **`deep-research` is NEVER launched automatically from quick-research.** The offer is the deliverable; the run requires an explicit "yes".
- This holds **even in autopilot / FSD** — the cost boundary is a genuine human-input point, like a `verify-human` gate. An escalation offer is not a transition the orchestrator may auto-chain; it is a confirmation prompt the operator must answer. Emitting the offer and waiting IS the correct autopilot behavior here.
- If **no** load-bearing unknowns remain, do not offer — just deliver the findings and note the question is settled.
- If the operator says **yes**, hand off by invoking the built-in `deep-research` skill (via the `Skill` tool) with a tightly-scoped brief built from the known-unknowns list — the unknowns become deep-research's sub-questions, so the expensive pass targets exactly the gaps the cheap pass could not close.

## When deep-research IS justified (the ROI bar)

`deep-research` is expensive (fan-out web searches, source fetching, adversarial verification, synthesis). Reach for it — or accept an escalation into it — only when **at least one** of these holds:

- **High-stakes or decision-reversing** — the answer changes a real decision, and being wrong is costly to undo.
- **Cross-source verification needed** — sources conflict, or the claim is contested / easy to get subtly wrong, and you need corroboration.
- **Broad literature / precedent survey** — the value is in coverage across many sources (what does the whole field/ecosystem do), not a single fact.
- **The quick-research pass left load-bearing unknowns** — the cheap probe ran and the gaps it surfaced actually block the operator's next step.

If none of these hold, quick-research is enough. A quick lookup that returns a HIGH-confidence answer with no load-bearing unknowns should **not** be escalated "to be thorough" — that is exactly the over-reach (paying deep-research cost for a question a light pass already settled) this skill exists to prevent.

## Pitfalls

- **Silent over-reach.** Escalating to deep-research on a question a light pass already settled — the C/E fence-case failure that motivated this skill. Check the ROI bar before offering; "to be safe" is not a justification.
- **Dishonest confidence.** Labeling an inference HIGH, or omitting the known-unknowns list, defeats the whole design — the confidence labels + unknowns are what make a cheap default safe.
- **Auto-launching the deep pass.** The escalation offer must WAIT for a human yes, autopilot included. Firing `deep-research` without confirmation reintroduces the exact uncontrolled-cost problem.
- **Wrong-surface pickup.** If the real source is the codebase or a milestone-scouting decision, hand to `feature-research` / `product-research` instead of doing a web pass that will not answer it.

**Research question:** {{args}}
