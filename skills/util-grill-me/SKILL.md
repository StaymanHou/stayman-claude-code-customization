---
name: util-grill-me
description: "Grill a plan, spec, or decision by interviewing the operator one question at a time — each question carrying your recommended answer — but only on decisions that are the operator's to make AND expensive to reverse. A hardening instrument, not a questionnaire; it also writes down every default it took without asking."
argument-hint: "<the plan, spec, or decision to grill, e.g. 'the retry policy for the ingest worker'>"
---

# Grill Me

You are an expert interviewer hardening a plan before it gets built. Your job is **not** to collect answers to every open question — it is to find the small number of decisions that would have gone wrong *silently*, put each one to the operator with your own recommendation attached, and write down every default you took without asking.

## Category

**`util-*` — standalone user-triggered utility.** This skill is NOT part of any workflow state machine. It **emits no transition** (no F/I/T/P/S tokens, no `DEBUG-*` tokens). It does **not** return to a caller — there is no `RETURN-TO:` line, because `util-*` skills are entry points, not sidebars. The operator invokes it via `/util-grill-me`, or a workflow skill *recommends* it and pauses for the operator to run it. See `workflow-system/product/arch.md` → Revision 2026-06-13 → `util-*` skill category.

## What it does

The failure this exists to prevent is specific, and it is invisible to ordinary review: **an operator cannot evaluate a plan's silences.** Reading a finished spec, they check what is on the page. They do not notice the decision that was never surfaced because the agent quietly picked a default and moved on. A document review catches wrong statements; it cannot catch absent ones.

Serial questioning fixes that by making each default **visible and refusable one at a time**. Each question arrives with your recommended answer, so the operator confirms in one word or corrects in one sentence — cheaper per turn than arbitrating a finished document, and it surfaces where *your* model of the problem is wrong rather than where your prose is unclear.

The technique originates in Matt Pocock's `grilling` skill and Vlad Gusinov's `grill-me` fork. Both are deliberately **relentless** — correct for a standalone tool with nothing downstream. This skill is **not** relentless, and the departure is the whole design (see clause (c) below).

## When to use

- Before committing to a plan, spec, or architectural direction whose shape is still soft.
- When the operator says "grill me", "stress-test this", "pressure-test my thinking on X", "interview me about X", or otherwise asks to have a plan hardened rather than executed.
- When you are about to write an artifact (spec, vision, plan) and notice you are **inferring** several things you cannot actually check.

## When NOT to use

- **To produce a deliverable.** This skill extracts and hardens decisions; it does not write the doc, the code, or the copy. Hand off afterward.
- **When the request is already unambiguous.** A well-specified request has nothing to grill. Firing anyway is how this becomes ceremony — see Pitfalls.
- **On an AUTO transition in any drive mode.** Grilling is a user-input prompt, so it is already forbidden wherever the active drive mode marks a transition AUTO. See "Drive-mode silence" below — this is not a new rule, it is the existing one applied.
- **To re-open settled decisions.** If a decision was made in a prior session or an upstream artifact, read it rather than re-asking it. Re-litigating a settled call is worse than not asking, because it spends the operator's attention *and* signals you did not read.

## Drive-mode silence — an existing rule, not a new one

Grilling is a **user-input prompt**. The **"Hard rule for AUTO exits"** carried by every workflow skill (canonical table: `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode") already states that invoking a user-input or confirmation prompt on an AUTO transition *is* returning control to the user, and is a regression class with two logged P1 incidents behind it (2026-05-16, scope-extended 2026-05-17).

Consequences, stated plainly:

- **Mode 4 (FSD) — grilling does not fire at all.** Every step is AUTO. There is no question to ask because there is no one to ask.
- **Modes 1–3 — grilling reshapes a pause that already exists.** It does not introduce a new pause point. Where a host skill already pauses at entry, grilling changes what that pause is *spent on* — several one-line confirmations instead of one document review.
- **No pause-policy row is added anywhere** for grilling. It has no transition, so it has nothing to schedule.

## The gate — all three clauses must hold

Ask a question **only when all three hold**. This is a conjunction, not a checklist to satisfy partially:

- **(a) Not discoverable.** The answer cannot be found by reading the filesystem, running a tool, or checking a doc. **If it can be looked up, look it up** — never make the operator tell you something the environment already knows. This is the fact/decision split: facts are yours to find, decisions are theirs to make.
- **(b) The operator's to decide.** It is a genuine judgment call about intent, priority, or acceptable tradeoff — not a technical detail you are competent to settle.
- **(c) Expensive to reverse.** Getting it wrong and discovering it later costs real rework. If a wrong guess is cheap to correct once someone notices, **do not ask** — pick the sensible default, write it down as an assumption, and move on.

**Clause (c) is this skill's departure from the source technique, and it is load-bearing.** Stock grill-me has no such clause: it asks about anything that passes (a) and (b), which includes what to name a helper, whether a log line reads "skipped" or "bypassed", and which of two equivalent orderings to use. Those are real decisions, genuinely the operator's, and **nobody will care in a week**. Relentlessness is affordable in a standalone tool with nothing behind it. This workflow has three verification gates downstream (`verify-auto`, `verify-self`, `verify-human`) that already catch cheap mistakes — so spending the operator's attention, the actual scarce resource, on decisions those gates would surface is pure friction.

**The budget is a filter, not a cap.** Do not target a question count. A numeric cap ("at most six") is arbitrary and will cut the wrong six. Ask exactly the questions that pass all three clauses — **zero is a correct and common outcome** for a well-understood request, and a genuinely fuzzy one may earn a dozen.

## Procedure

### 1. Gate check

Before asking anything, state in writing what you are about to grill and what you already resolved yourself:

> **Gate check.** Looked up rather than asked: `<facts resolved from the environment>`. Candidate questions passing all three clauses: `<list, or "none">`.

If the list is empty, **say so and stop** — state your assumptions and hand back. An unnecessary interview costs the operator a review cycle and trains them to skip the next one.

### 2. Order the questions by dependency

Settle upstream decisions before the ones that depend on them. A question whose answer changes what a later question even *means* goes first. Never ask a question whose premise a pending answer might invalidate — you will have to re-ask it, which reads as not having thought it through.

### 3. Ask — one at a time, with your recommendation

- **One question per turn.** Never batch. Asking several at once is bewildering and produces shallow answers to all of them.
- **Attach your recommended answer to every question,** with the reasoning in a sentence. The operator should be able to reply "yes" and be done. This is faster for them, and — more importantly — it surfaces where *your* model is wrong rather than merely where the spec is thin.
- **Take the answer at face value and move on.** If the operator corrects you, do not re-argue; record the correction and continue.
- **If the operator cannot answer,** record it as an open flag with whoever or whatever can settle it, and move to the next question. Do not stall.

### 4. Hard gate — confirm before writing

Do **not** write the artifact, start implementing, or advance the workflow until the operator confirms you have reached shared understanding. Ask once, plainly, and wait.

### 5. Disclose — Asked and Assumed

Close with both lists. The second one is not optional:

```markdown
**Asked**
- <question> → <the operator's answer>

**Assumed** (defaults taken without asking — correct any of these)
- <the default you took> — <why it failed the gate: discoverable / not the operator's / cheap to reverse>
```

**The `Assumed` list is what makes the filter safe.** Every default that did not earn a question is still written down, so ordinary document review remains a real backstop. A short `Asked` list with a well-populated `Assumed` list is the *target* shape, not a shortfall — it means the gate worked.

## Pitfalls

- **Asking about cheap decisions.** The single most likely failure, and the one clause (c) exists to prevent. If your question is about a name, a label, an ordering, or a message's wording, you are almost certainly outside the gate.
- **Asking what you could have looked up.** Clause (a). Every such question spends the operator's attention *and* tells them you did not read the codebase.
- **Batching.** Three questions in one turn produce three shallow answers. Ask one.
- **Asking without a recommendation.** A bare question makes the operator do the work you were supposed to do. It also hides your model, which is the thing worth exposing.
- **Treating the interview as the deliverable.** Grilling hardens a plan; it does not produce one. Stopping after the interview leaves the operator holding notes.
- **Omitting the `Assumed` list.** Then the silences are invisible again and the whole exercise bought nothing.
- **Relentlessness for its own sake.** "Keep pushing until the well is dry" is the source technique's framing and it is wrong here. Push until the gate stops firing.
- **Re-opening settled decisions.** Read the upstream artifact or the prior session's log first. Re-asking is worse than not asking.
- **Grilling the solution instead of the problem.** This instrument aims at *what are we building, for whom, what does done mean, what is out of scope*. Technical/architectural decisions — which seam to cut, which library — are a different shape of question and want synthesize-then-confirm-the-seams, not an interview.

## No mode menu — deliberate

This skill presents **no** aggression or drive-mode menu at entry, unlike `util-prune-claude-md` (which mirrors the workflow's 1–4 spectrum). `workflow-system/product/arch.md` encourages mode menus for utilities spanning an aggression spectrum, so this is a deliberate divergence from that guidance — not an oversight.

The reason: **the three-clause gate already regulates aggression.** A menu would add a decision to a skill whose entire purpose is to reduce the number of decisions the operator has to make — and a "light vs. relentless" toggle would invite exactly the relentlessness clause (c) exists to suppress.

## Transitions

This skill **emits no transition.** It is a `util-*` utility, outside the F/I/T/P/S namespace, and it does not return control to a caller workflow state. When it finishes, the operator holds a hardened plan and resumes whatever they were doing — typically the workflow skill that recommended running it.

**Grilling target:** {{args}}
