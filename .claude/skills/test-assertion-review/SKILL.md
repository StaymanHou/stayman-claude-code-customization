---
name: test-assertion-review
description: "Review a test assertion in this repo's shell suites against six mechanisms by which an assertion PASSES while guarding nothing. Invoke BEFORE writing or modifying any assertion in tests/, tools/*/test/, or skills/*/scripts/test/ — and when a green suite feels too easy. Project-local to my-claude-code-customization."
argument-hint: "<the assertion(s) or file you are about to write/modify — e.g. 'a new [Phase 20] pin that session-* skills carry no tour vocabulary'>"
---

# Test Assertion Review

You are reviewing one or more **test assertions** in this repository against six
known mechanisms by which an assertion **passes while guarding nothing**.

## Category

**Project-local checklist skill.** This is NOT a workflow state and NOT a
`debug-*` sidebar. It owns no state node, emits **no transition token**
(no F/I/T/P/S, no `DEBUG-*`), and returns no `RETURN-TO:`. It is a review pass
the agent or operator invokes directly.

It lives in `<proj-dir>/.claude/skills/` — **project-local to this repo only,
deliberately not symlinked into `~/.claude/`**. `install.sh` globs
`<repo>/skills/*/` and never touches `<proj-dir>/.claude/skills/`, so this skill
stays scoped here by construction. Do not move it to the repo's top-level
`skills/` directory; that would make it global.

Worked instances (commits, measurements, full procedures) live in
[`docs/lessons/green-tests-that-guard-nothing.md`](../../../docs/lessons/green-tests-that-guard-nothing.md).
This skill is the **actionable checklist**; that doc is the **evidence**.

## When to use

Invoke when **any** of these hold:

- You are about to **write** a new assertion in `tests/`, `tools/*/test/`, or
  `skills/*/scripts/test/`.
- You are about to **modify** an existing assertion's pattern, anchor, or corpus.
- You just ran a **mutation sweep that passed 100%** and are about to call the
  work verified.
- A structural pin or scenario **went green on the first try** against a
  behavior you expected to be hard to pin.
- You are adding a **negative/absence** assertion ("file X must NOT contain Y").
- A suite is green but you cannot state, in one sentence, **what wrong input
  each assertion rejects**.

## When NOT to use

- The change is to test *fixtures* or *scaffolding* with no assertion semantics.
- You are reviewing **application** code, not test code → use `/code-review` or
  `feature-review-quality`.
- The assertion already went through this review **this session** and its
  pattern, anchor, and corpus are all unchanged.

## Why this exists

Every one of the six mechanisms below **shipped GREEN through a sweep designed
to catch it**, in this repo, within the M11 cycle. Each is invisible to the
technique that catches the others. Three of them were caught by
`code-quality-reviewer` at `feature-review-quality` — *after* a
mutation-verified run had already declared the work done. Two of them landed in
the very phase written to prevent inert pins, one commit after the convention
documenting them.

The lesson those repeats teach: **hand-verification checks the cases you think
to check.** This checklist is the set of cases you don't.

## Procedure

### Step 0 — Gate check

Restate in writing:

1. **What** assertion(s) are in scope (file + the pattern/anchor itself).
2. **Which** trigger from "When to use" fired.
3. **What behavior** each assertion is supposed to guard, in one sentence.

If (3) cannot be stated in one sentence without hedging, stop and resolve that
first — an assertion whose purpose is vague cannot be checked against the six.

If no trigger from "When to use" holds, say so and stop. Do not run the
checklist speculatively.

### Step 1 — Walk all six mechanisms

For **each** assertion in scope, answer every question. Answer **from the code
and from real runs**, not by inspection or plausibility — reasoning by
inspection is what produced every instance in the lesson doc.

#### 1. Sensitivity vs. RELEVANCE

> A mutation check proves the assertion *can* fail. It does not prove it
> exercises the path production uses.

- Does this assertion drive the **same entry point, arguments, and environment**
  the real caller drives?
- Does it set any **env var, flag, or fixture path the production caller does
  not set**? If yes: justify the divergence in a comment, or delete it.
- Is this a **test-hygiene habit copied from a context that needed it** into one
  that does not? (Isolation that is load-bearing in one group is actively wrong
  in another.)

**Prefer one assertion on the real default path over three on a synthetic one.**

#### 2. Destructive-tool `HOME` isolation

Only if the assertion exercises a script that removes or edits anything under
`~/.claude`:

- Is `HOME` scoped **per-invocation** (`env HOME="$SANDBOX" <script>`)?
- Is there **no** top-level `export HOME`? (The Bash-tool env persists across
  calls; a top-level export leaks into a later real invocation.)
- Is there an assertion that the **outer `$HOME` is unchanged** after the run?

#### 3. Does it fail OPEN?

- If the target **file does not exist**, does the assertion still pass?
  - Test this literally: point it at a synthetic nonexistent path and run it.
- Negative/absence assertions need an existence precondition that fails
  **CLOSED**:
  ```sh
  if [ ! -f "$f" ]; then
    check "$desc" "fail" "$f does not exist — a negative assertion cannot be satisfied vacuously"
  else
    …
  fi
  ```
- Does the failure message name the **rename** case? That is how it actually
  fires.
- **3b — unset variable, same vacuous pass:** is any corpus variable **read
  outside the guard that assigns it**? Under `set -euo pipefail` that makes
  `set -u` fire inside the `$( )`, the capture goes empty, and `0 -eq 0` passes.
  Every consumer must sit *inside* the assigning guard.
  **The `[ -f ]` guard does NOT cover this — separate obligations.**
- Is the anchor **case-STABLE**? Never anchor on emphasis-cased words
  (`**NOT**`, `**MUST**`, `**ONLY**`). If only `-i` would match, that is a
  signal to pick a different anchor, not to add `-i`.

#### 4. Anchor quality (for any grep/regex pin)

- Is each anchor a **phrase CLASS that already recurs in the real corpus** —
  not a generic procedure word (`Step [0-9]` hits 13 of 46 SKILL.md files), and
  not a verbatim one-off sentence (which matches nothing)?
- Are the anchors held in a **bash array**, with the probe **joined** from it?
  ```sh
  PROBE=$(IFS='|'; printf '%s' "${ANCHORS[*]}")
  ```
  One source of truth. Never keep the probe as a string and parse it back into
  anchors — a splitter mishandles `[...]` and escapes silently.
- Is the set **property-tested in five directions**? liveness · sensitivity
  (one case per anchor, each isolating **exactly one**) · specificity ·
  clean-tree · case-stability.
- **Have you deleted every anchor individually and confirmed each yields ≥1
  FAIL?** That sweep is the only thing proving *zero unguarded*.

#### 5. What does it REJECT?

> Sensitivity and specificity are independent. An assertion matching everything
> is sensitive *and* worthless.

- **Write down one concrete WRONG input that must FAIL. Confirm it does.**
  One line per assertion. This is the only technique that closes this gap, and
  a mutation sweep structurally cannot ask it.
- If the wrong input is **model output**, simulate it through the real verifier
  rather than reasoning about it:
  ```sh
  source tests/lib/verify.sh
  verify_result "<the bad output>" …   # then check the return code
  ```
- Is any count a **ratio over what happens to be present** (`live -eq present`)?
  Replace it with an **absolute expected count derived from the list**:
  ```sh
  set -- $ITEMS; expected=$#
  ```
  so it tracks additions instead of going stale.

#### 6. Naming a thing in order to FORBID it

- Does the corpus **legitimately mention** the forbidden term (e.g. copy that
  warns *"unlike `bypass-permissions` … do not substitute it"*)? If so, a pin on
  the bare term **fires on the correct answer** — the better the reply, the
  likelier it fails.
- Forbid the **recommendation verb** adjacent to the term instead:
  `recommend <term>` / `use <term>` / `launch with <term>`.
- Verify **both directions**: the corpus's own warning sentence must PASS; a
  real recommendation must FAIL.
- Is `model: sonnet` being reached for as a **flakiness remedy**? Do not. The
  repo's rule is "prove haiku noise → **confirm sonnet passes** → then tag," and
  that confirmation step is load-bearing: for assertions trippable by faithfully
  reproducing source copy, **model strength is anti-correlated with passing**.

### Step 2 — Report

Emit a table, one row per assertion × mechanism, marking each `OK` /
`AT-RISK` / `N/A`. `N/A` requires a reason (e.g. "not a negative assertion").

Then for every `AT-RISK`:

- Name the mechanism and the **specific** defect.
- State the fix.
- State how the fix will be **verified** — including the wrong-input case from
  mechanism 5.

Close with one of:

- **`CLEAR`** — every mechanism `OK` or justified `N/A`, and mechanism 5's
  wrong-input case is written down and confirmed for each assertion.
- **`AT-RISK`** — one or more defects found; list them ordered by blast radius
  (a pin that guards a *rename* of a load-bearing artifact outranks a cosmetic
  anchor).

## Pitfalls

- **Do not treat a passing mutation sweep as evidence for mechanisms 3, 4, or
  5.** It structurally cannot exercise them. This is the single most common way
  this review gets skipped in practice — the sweep feels like proof.
- **Do not check only the cases you thought of.** Mechanism 4's delete-each-anchor
  sweep and mechanism 5's wrong-input case exist precisely because
  hand-verification "in four directions" missed two defects in the same probe in
  the same feature.
- **Do not soften a failing assertion to make the suite green.** If a scenario
  is deliberately left failing to preserve evidence of a real gap (as
  `session.yaml::S33`/`S34` are), that is intentional — deleting the evidence is
  the failure mode, not the fix.
- **Do not run this on application code.** The six mechanisms are about
  assertion semantics; they say nothing useful about a feature's logic.
- **Mechanism 2 applies to ad-hoc Bash-tool runs too**, not just committed test
  files. The live `~/.claude` was wiped once by exactly that gap.

## Termination

This skill emits **no** `TRANSITION:` token and **no** `RETURN-TO:` line — it is
a project-local review pass, not a workflow state or a sidebar. It ends with the
`CLEAR` / `AT-RISK` verdict from Step 2.

If the verdict is `AT-RISK`, the caller applies the fixes and may re-invoke to
confirm — a re-review after a pattern/anchor/corpus change is expected, not
redundant.
