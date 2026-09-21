# Opus 5 ends its turn at a workflow state boundary ~3.8× more often than Opus 4.8 (measured, n=928)

**Draft for filing at https://github.com/anthropics/claude-code/issues — not yet submitted.**

## Summary

In a skill-driven workflow where one skill is expected to invoke the next, Opus 5
ends its turn and hands control back to the operator **~3.8× more often** than
Opus 4.8 at the same transition, in the same codebase, under the same drive mode.

Measured over **928 live transition turns** from my own session logs:

| model | transition turns | handed back | rate | 95% CI |
|---|---|---|---|---|
| opus-4-8 | 452 | 9 | **2.0%** | 1.1–3.7% |
| opus-5 | 278 | 21 | **7.6%** | 5.0–11.3% |

**Fisher exact p = 3.8×10⁻⁴.** Risk ratio ≈ 3.8×.

Only turns in **autopilot/FSD drive mode** are counted — the modes where
auto-chaining is the specified behaviour. Turns where the operator intervened
before the next assistant turn are excluded as unclean observations.

## What the failure looks like

My setup is a state-machine workflow of skills. At the `verify-self → verify-human`
transition, the agent should emit its transition token and then **invoke** the
next skill. The skill it is supposed to invoke contains a human-review pause
*inside* its own procedure.

The failure: the model reads that downstream pause **one state too early**,
stops at the *edge into* the state rather than entering it, and then writes the
next skill's output **itself** — a phase summary and a hand-written review
checklist — so the skill's actual procedure (its auto-skip gate, its
integration-boundary check, its structured leaf construction) never runs.

The operator sees something that looks like correct output, which is what makes
it expensive: the checks were described, not performed.

Verbatim from one occurrence:

> `TRANSITION: F10b`
>
> Autopilot chains into verify-human, which is itself a PAUSE point — so this is
> where I stop.

Followed by a hand-written checklist and zero skill invocations. The operator's
next message was `invoke verify human`.

A near-identical turn from the **same model, same mode**, that behaves correctly:

> `TRANSITION: F10b`
>
> Autopilot chains into verify-human, **which evaluates its own auto-skip gate.**

→ invokes the skill.

Same premise, opposite completion. The divergence is in what the model takes the
downstream pause to *mean*: does it belong to the state (enter it, let it
decide), or to the edge into it (stop before entering)?

## Why I think this is worth a data point

Anthropic's own [Prompting Claude Opus 5 guide] documents both the over-literal
instruction reading and — pointedly — that *"legacy harness scaffolding that adds
separate verification steps"* can cause over-verification on Opus 5. That matches
what I see, and my read is that the model is being *conservative* rather than
malfunctioning: it sees a pause and declines to blow through it.

The existing public reports (#87491 "treats direct instructions as negotiable",
#82872 "ignores loaded project rules" in long sessions) describe the same
disposition **qualitatively**. I could not find anything with a per-model rate,
so this is offered as the quantitative version rather than a new complaint.

## Context depth matters

Real failures cluster deep: median ~445k tokens / ~1005 turns into a session. I
could not reproduce this at all in short synthetic scenarios — at ~26k context
the behaviour was clean 4/4 on Opus 5, and a purpose-built scenario was
non-discriminating on two smaller model tiers.

## A replay attempt that did NOT work — reported so nobody repeats it

I built a harness that renders a real session's prior ~500 turns back into a
fresh run via `--append-system-prompt` (~295k chars), then asks the model to
produce the next turn. **It produces edge-pauses at depth, but it does not
discriminate**, and I would not want this cited as a reproduction recipe:

| | hand-back rate |
|---|---|
| slices where production **stopped** | 14/60 = 23.3% |
| slices where production **chained** (negative controls) | 23/40 = 57.5% |

**Fisher p = 0.001 — the controls fire MORE than the real failures.** So the
harness measures something about replay framing, not the bug.

Two things I can say about why, from n=100:

1. **It is not simply model nondeterminism.** χ² for homogeneity across the five
   slices is p = 1.9×10⁻⁴ — the slices do not share a single rate, so something
   slice-specific drives it.
2. **The cause, found after this table was first written — it is my own harness
   bug, not a model behaviour.** My runner passed `--permission-mode dontAsk`,
   which **blocks the `Skill` tool outright** (*"Permission to use Skill has been
   denied because Claude Code is running in don't ask mode"*). So the model could
   not chain in *any* of the 100 runs, in either arm — "hand back" was the only
   permitted action. That is a hard floor under stops and controls alike and is
   sufficient to explain the controls firing higher. **The harness was measuring
   its own permission configuration.** I am re-running with the mode flipped and
   classification moved from prose to `tool_use` blocks; until that lands, treat
   the replay numbers above as void rather than as evidence about Opus 5.

The **production** measurement at the top does not depend on this harness. It is
a direct count over real session logs.

## Environment

- Claude Code CLI, macOS (darwin 25.6.0)
- Models: `claude-opus-5`, `claude-opus-4-8`, `claude-opus-4-7`
- Workflow: ~48 skills, state-machine transitions, `Skill()` invocation between states
- Logs: `~/.claude/projects/*/*.jsonl`, 5 projects, autopilot/FSD turns only

## What would help

1. Is this a known disposition change in Opus 5 around **instruction-shaped
   content in a downstream prompt** the model can see but has not entered yet?
2. Is there a recommended way to express "this state contains a pause, but you
   must **enter** it to reach that pause" that Opus 5 reads reliably?
3. Is the guide's "remove legacy verification scaffolding" advice meant to apply
   to workflow scaffolding like this? For my use case the scaffolding *is* the
   product, so removing it is not available — but I would rather know that than
   keep prompt-patching.

## Caveats, stated plainly

- Single operator, single workflow system, own logs. Not a controlled experiment
  — model choice across sessions was not randomised, so confounding by task type
  is possible. The 3.8× gap and p-value should be read with that in mind.
- The classifier is structural (was the next skill invoked?) plus a drive-mode
  gate. An earlier keyword-based version of it over-reported by ~2× by counting
  legitimate pauses — single-step mode telling the user to run the next command,
  genuine design questions, one case of correctly declining to override a
  recorded instruction. Every figure here uses the structural classifier.
- `opus-4-7` is in my logs at a much higher apparent rate (15.2%, n=198), which
  I could **not** reconcile with an earlier pass that put it near 1.8%. I have
  left it out of the headline comparison rather than publish a number I cannot
  reproduce. The opus-5 vs opus-4-8 comparison reproduced independently on a
  fresh derivation and is the only claim I am making.
