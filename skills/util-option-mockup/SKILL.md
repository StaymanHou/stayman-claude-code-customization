---
name: util-option-mockup
description: "Build a lo-fi side-by-side mockup artifact to decide between several concrete UI/UX options for one surface, when the difference is spatial and prose or ASCII would lose it. A decision tool, not a work package — the operator picks, then the build happens normally."
argument-hint: "<the decision being made, e.g. 'where the workflow-features toggle lives'>"
---

# Option Mockup

You are an expert product designer building a **decision instrument**: a lo-fi mockup that lets the operator choose between several concrete UI/UX options in one look, instead of arbitrating your prose.

## Category

**`util-*` — standalone user-triggered utility.** This skill is NOT part of any workflow state machine. It **emits no transition** (no F/I/T/P/S tokens, no `DEBUG-*` tokens). It does **not** return to a caller — there is no `RETURN-TO:` line, because `util-*` skills are entry points, not sidebars. The operator invokes it via `/util-option-mockup`, or a workflow skill *recommends* it and pauses for the operator to run it. See `workflow-system/product/arch.md` → Revision 2026-06-13 → `util-*` skill category.

## What it does

When an agent presents several UI/UX options **in prose**, it conveys *structure* but not the thing the decision usually turns on: **how much room each option takes, and what that costs**. Files give structure; they do not give cost. Layout decisions are decided by cost.

This skill produces three-or-so candidate layouts rendered **side by side in the product's own design tokens at true proportion**, sharing one reference line, each carrying one measured axis — so the operator judges the layout rather than your description of it.

**The failure this exists to prevent** is not sloppiness. It is a *framing error* that survives careful work: reading the right files, reasoning rigorously, and arriving at a confident verdict to the wrong question. In the originating instance the agent asked *"where does one boolean go?"* when the live question was *"has this collection outgrown its container?"* — and no amount of rigor inside the frame recovers it. A drawn comparison exposes the frame; prose hides it.

## When to use

Both clauses must hold:

- **(a) There are ≥2 concrete alternatives for a single element, widget, or component** — actual candidate arrangements you could describe, not an open-ended "how should this look?".
- **(b) The difference between them is spatial or visual, such that prose or ASCII loses it** — the options differ in how much room they take, what falls above the fold, or how the arrangement reads.

**The self-test for clause (b):** *can you state the difference in one sentence and be confident the operator pictures the same thing you do?* If yes, write the sentence. If no, build the mockup.

## When NOT to use

This skill does **not** fire for:

- **Copy, naming, or color-only choices** — no spatial dimension to draw.
- **Behavior choices with no layout change** — what a control *does*, versus where it sits.
- **A difference ASCII conveys fine** — "button on the left vs. the right" needs a sentence, not an artifact. Over-firing here is the main way this skill becomes ceremony. Really simple UI/UX choices don't need a mockup.
- **Milestone-level frontend prototypes** — see the discriminator below.

### Decision tool vs. WBS prototype — discriminate on WHAT VARIES

`product-wbs` → "Learning-Sequence Ordering" already sequences **UI mockups / frontend prototypes** as work packages. That is a different artifact from this one, and the discriminator is **what varies between the options — not how big the surface is**:

| | This skill (decision tool) | WBS prototype (work package) |
|---|---|---|
| What varies | **The same surface, rearranged** | **Different surfaces, or the flow between them** |
| Examples | 3 layouts of one modal · 2 placements of one control · sidebar vs. top-bar on one page | A 4-screen onboarding sequence · a nav restructure across sections |
| Purpose | Decide *now*, build later | Validate UX assumptions before building the backend |
| Lifecycle | Built to elicit a choice | Scheduled and built as a WP |

**The whole-screen edge case matters, so state it plainly:** three alternative layouts of a single screen are a **decision tool**, even though a whole screen is bigger than a widget. What makes it this skill's job is that the options are *rearrangements of one surface*. If the options are different *sets* of screens, or a different path between them, it is a WBS prototype.

## Procedure

### 1. Gate check

Confirm both `## When to use` clauses in writing before building anything:

> **Gate check.** (a) The candidate options are: `<list them>`. (b) The difference is spatial because `<one sentence>`. Self-test: I `<can / cannot>` state the difference in one sentence such that the operator pictures what I picture.

If either clause fails, **stop and say so** — present the options in prose instead. An unnecessary mockup costs the operator a review cycle and trains them to ignore the next one.

### 2. Gather what you need to draw honestly

- **The product's real design tokens** — background, panel, hairline, text, muted, accent. Read them from the codebase (CSS variables, theme file, Tailwind config). Do not invent a palette.
- **True geometry** — the real width of the container, the real row height, the real font stack.
- **Real content** — actual names, actual labels, actual list items from the project. Never lorem, never `Item 1 / Item 2`; fake content makes density judgments wrong.
- **A screenshot of the running surface, when the host already exists.** Ask for one — *"can you screenshot the current picker so I draw it at true proportion?"* You have the tool and the operator may not think to volunteer it. This is an input to your understanding, not the medium you present in.
- **Theme fidelity** — if the product is dark-only, draw it dark-only. A light variant of a dark-only product misrepresents it.

### 3. Build the artifact — five requirements

These are what made the technique work; dropping any one of them measurably weakens it.

1. **Render in the product's real design tokens at true proportion.** What the operator judges must be *the layout change*, not your styling of it. **A designed-looking mockup actively misleads here** — polish reads as quality and biases the choice. Lo-fi is the goal, fidelity-to-the-product is the constraint.

2. **Place the options side by side, sharing one reference line.** A common baseline — the fold, a viewport edge, a fixed container height — is what makes the comparison legible. Without a shared line the frames are three pictures, not a comparison.

3. **Put one measurable axis on it, and label estimates as estimates.** Pick the axis the decision actually turns on (px above the fold, items visible, clicks to reach, rows before scroll) and show it per option. **Never dress a mockup-derived figure as an instrumented measurement** — write `~148px (est. from mockup)`, not `148px`.

4. **Include the unappealing option.** If one candidate is a trap, draw it rather than arguing it away — its cost becomes visible instead of contested. In the originating instance the middle option was *"build the panel, leave the old controls in place, and settings live in four places"*; seeing it drawn is what made it obviously wrong.

5. **Annotate in a hue outside the product's palette.** Your commentary must never be mistakable for product UI. Pick one annotation color that does not appear in the app's tokens, and keep all labels, arrows, and measurements in it — outside the frames where possible.

**Medium is not mandated.** A published HTML artifact is the worked example, but any medium delivering true proportion + real tokens + a shared baseline + one measured axis qualifies. Consider loading the `artifact-design` skill before building an HTML artifact.

### 4. Present and let the operator decide

- Show the artifact, then state **your own reading and what changed it** — especially if the drawing reversed a verdict you previously argued. That reversal is the most useful thing you can report.
- Give the measured axis as a small table.
- Name any **load-bearing consequence** the drawing exposed (a scope change, a trap option, a knock-on decision).
- Then **stop and let the operator pick.** Do not proceed on your own preference.

## Lifecycle — decide now, build later

- **This is a decision instrument.** Producing it must **not** begin implementing the chosen option. Decide here; build in the normal phase or work package.
- **Record the verdict in prose** — in the WIP file, WBS, or spec — as soon as the operator picks.
- **Save the artifact** (e.g. under `docs/reference/`) rather than discarding it. It is useful if the decision is re-litigated later. Note that session scratchpad directories are swept; a file you want to keep must be written somewhere durable.
- **The recorded verdict governs.** If the saved artifact and the written verdict ever disagree, the verdict wins. The mockup is not a spec, and must not drift into being treated as one.

## Pitfalls

- **Over-firing.** The most likely failure is building an artifact for a decision a sentence would have settled. The self-test in §1 is the gate; use it honestly.
- **Making it look good.** Polish is the enemy here. A designed mockup biases toward whichever option you styled most carefully.
- **Fake content.** Placeholder text destroys exactly the density signal the operator is judging.
- **Unlabeled estimates.** A number that looks instrumented but was eyeballed from your own drawing is worse than no number — it launders a guess into evidence.
- **Only drawing the options you like.** Omitting the trap option means arguing about it instead of seeing it.
- **Annotation inside the chrome, in product colors.** The operator then cannot tell your commentary from the product.
- **Sliding into implementation.** "While I had it open I went ahead and built it" defeats decide-now/build-later and pre-empts the operator's choice.
- **Treating a screenshot as the presentation medium.** A screenshot shows what *exists*; it cannot show alternatives. It is an input to drawing, not a substitute for it.

## Transitions

This skill **emits no transition.** It is a `util-*` utility, outside the F/I/T/P/S namespace, and it does not return control to a caller workflow state. When it finishes, the operator holds the decision and resumes whatever they were doing — typically the workflow skill that recommended running it.
