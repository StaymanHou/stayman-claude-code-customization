# Green tests that guard nothing

Six mechanisms by which an assertion in this repo's shell suites
(`tests/`, `tools/*/test/`, `skills/*/scripts/test/`) can pass while asserting
nothing about anything real. They are siblings, not variants — each one is
invisible to the technique that catches the others, and **every one of them
shipped GREEN through a sweep that was designed to catch it**.

The rules for all six are stated inline in the root `CLAUDE.md` (kept there
deliberately — this convention family exists *because* detail got lost once, so
the rule-statements stay in the context-loaded file and only the worked
instances live here). This doc holds the evidence: the concrete commits, the
measurements, and the procedures too long for a bullet.

---

## 1. Mutation-testing validates SENSITIVITY, not RELEVANCE

A mutation check ("break the behavior, confirm the assertion fails") proves an
assertion *can* fail. It does not prove the assertion exercises the path
production actually uses. Two independent questions; a green mutation test reads
deceptively like proof of both.

The high-risk shape is **a test-hygiene habit copied into a context that
doesn't need it** — env-var overrides, fixture redirection, or isolation flags
that are load-bearing in one test group and actively wrong in another.

**Worked instance (WP7l/WP7n, 2026-07-25, commit `fbebd02`).** The new group-9
assertion in `skills/tutorial-greenfield-workflow-tour/scripts/test/run-tests.sh`
overrode `TODO_STORE` to an external `mktemp` file — correct and required in
groups 1–3, which must protect the shipped `sample/`. But the greenfield tour's
Step-5 grounding beat runs the **bare** `./todo add "buy milk" && ./todo list`
against the **flat-stamped `./todos.txt`**. So the assertion claimed "the
grounding observable holds from the cwd" while testing a store no user path
touches. It passed its own mutation check. A `SCRIPT_DIR`-resolution or
stamped-file-permission regression would have sailed straight through into the
live tour.

The isolation also bought nothing there — the target dir was already a
throwaway `mktemp -d`. Caught by `code-quality-reviewer` at
`feature-review-quality`, not by the mutation test. Fixed by dropping the
override and adding a store-resolution assertion (*the flat-stamped
`./todos.txt` IS the store that was written*), itself mutation-verified.

---

## 2. Destructive-tool test-HOME isolation

Rationale for the per-invocation `env HOME=` rule: the Bash-tool environment
persists across calls, so a top-level `export HOME=<sandbox>` leaks into a later
real-script invocation and points it at the *actual* `$HOME`.

**Worked instance (2026-07-21, `uninstall-sh` feature).** This wiped the live
`~/.claude` mid-build — 41 skill symlinks + 6 agent symlinks + the `CLAUDE.md`
workflow block — recovered only because `install.sh` is idempotent. Origin:
`SURFACE-2026-07-21-UNINSTALL-TEST-HOME-EXPORT-HAZARD` (resolved in-cycle).

The shipped `tools/uninstall/test/run-tests.sh` encodes the pattern: per-call
`env HOME`, `mktemp` + `trap` cleanup, and a dedicated SAFETY assertion that the
outer `$HOME` is unchanged and the live install is still populated.

---

## 3. A negative assertion fails OPEN on a missing file

The failing shape:

```sh
count=$( (grep -cE "$pat" "$f" 2>/dev/null || true) | head -1 )
[ "${count:-0}" -eq 0 ]
```

When `$f` does not exist: `2>/dev/null` swallows grep's "No such file",
`|| true` suppresses the exit status, the capture is empty, and `${count:-0}`
turns that into `0` — which equals the expected `0`.

**Invisible to mutation testing by construction.** A mutation test proves the
assertion can fail by making the forbidden content *appear*, which requires the
file to exist. The vacuous-pass branch is never exercised.

The guard, which must fail CLOSED:

```sh
if [ ! -f "$f" ]; then
  check "$desc" "fail" "$f does not exist — a negative assertion cannot be satisfied vacuously"
else
  …
fi
```

Its failure message should name the **rename** case, because that is how it
actually fires.

**Worked instance (WP7m, 2026-07-27, commit `e7e682b`).** Three
`check-structure.sh` [Phase 18] pins asserted that
`session-reflect`/`session-handoff`/`session-capture` carry **zero**
tour-specific vocabulary — the mechanism enforcing "the WP7m tour guard lives in
the arms, not the general session skills." All three passed against a synthetic
`skills/session-DOESNOTEXIST/SKILL.md`. Not hypothetical: **WP5/M9 renamed
exactly those three skills** (`session-pause`→`session-handoff`,
`session-store-learning`→`session-capture`), so the next rename would have left
three permanently-green pins guarding nothing. Caught by
`code-quality-reviewer`, not by the 13/13 mutation-verified run that preceded it.

### 3b. Same vacuous pass, different mechanism — an UNSET VARIABLE

**Worked instance (WP7o, 2026-07-27, commit `438d88e`).** Under
`set -euo pipefail`, a variable assigned inside a guarded branch but read
*outside* it makes `set -u` fire **inside** the `$( )` subshell: the capture is
empty, `${n:-0}` turns it into `0`, and `0 -eq 0` PASSes with exit 0 while
asserting nothing.

`[Phase 18b]`'s case-stability check read `arm_corpus` at top level while case
(1) assigned it inside `if ls skills/tutorial-*/SKILL.md`. Renaming the tour arms
would have left the pin permanently green — in the very phase written to prevent
inert pins, one commit after the convention landed.

Every case that reads a corpus variable must sit *inside* the guard that assigns
it: one guard, opened once, closed after the last consumer. The `[ -f ]` fix
above does **not** cover this — file-existence and variable-scope are separate
obligations.

---

## 4. A structural pin's ANCHORS need their own property-test

A pin can assert its *file* is clean; it can never assert its *anchors* are the
right ones. Both failure directions ship green.

**Too generic.** `Step [0-9]` and `beat [A-G]` are house idioms — `Step [0-9]`
appears in **13 of 46** SKILL.md files, and `session-capture` itself carries
"The write (Step 5) then follows…". They caught no real leak while arming a
false FAIL for anyone later routing a third file onto the probe.

**Too specific.** Verbatim one-off sentences (`greet.sh`, `drive modes you`,
`finished the greenfield tour`, `the tour, narrate`) matched **nothing anywhere
in `skills/`** — four of nine anchors dead on arrival, while all **23** real
`graduat*` lines in the tour arms sailed straight through.

Both defects hit the *same* probe in the *same* feature (WP7o, 2026-07-27,
`ccfedac`/`438d88e`), and hand-verifying it "in four directions" missed both —
hand-verification checks the cases you think to check.

### The five-direction property test

Hold the anchors in a bash array and **join** the probe from it:

```sh
PROBE=$(IFS='|'; printf '%s' "${ANCHORS[*]}")
```

One source of truth. An earlier draft kept the probe as a string and *parsed* it
back into anchors; that splitter mishandled `[...]` and escapes, so a broken
fragment was silently counted live. Joining deletes the parser and the whole
failure mode.

Then test the set in five directions:

1. **Liveness** — every anchor matches the real corpus.
2. **Sensitivity** — one leak case per anchor, each isolating **exactly one**
   anchor. Otherwise a deleted anchor hides behind a sibling and the case proves
   nothing.
3. **Specificity** — real legitimate prose must not trip it.
4. **Clean-tree** — no FAIL on an unmodified checkout.
5. **Case-stability** — sensitive and insensitive runs must agree. Reach for a
   different anchor, never `-i`.

**Verify by deleting every anchor individually and confirming each yields ≥1
FAIL.** That sweep is the only thing that proves *zero unguarded*, and it found
four anchors with no sensitivity case at all after the set already looked
complete. Shipped as `tests/check-structure.sh` [Phase 18b].

Distinct from `test-harness-primitives.md`, which says *whether* to
property-test a primitive, not what makes an anchor good.

---

## 5. Deletion-sensitivity and specificity are INDEPENDENT

Breaking a behavior and confirming the assertion fails proves it is
**sensitive**. It says nothing about whether the assertion also matches things
it must **reject** — and an assertion that matches everything is sensitive *and*
worthless. Only one of those two questions a mutation sweep can ask.

Where the wrong input is model output, simulate it through the real verifier
(`source tests/lib/verify.sh; verify_result "<bad output>" …` and check the
return code) rather than reasoning by inspection. Reasoning by inspection is
what produced every instance below.

**Three instances in ONE feature (WP7e, 2026-07-27, `9a524e5`/`175492a`), on
three different artifact kinds, each after its own sweep passed clean:**

1. **Grep anchor.** `(no|not emit an?|never emits?)[^.]{0,60}transition` matched
   **24 of 46** SKILL.md files including `feature-build`/`feature-ship`/`task-act`,
   which all *do* emit transitions. A tour skill with `TRANSITION: F1` appended
   **still PASSED** the pin written to forbid exactly that. The 12-case deletion
   sweep caught none of it, because deletion was never the failure mode.

2. **Behavioral scenario anchors.** `auto` is a case-insensitive *substring*, so
   it matched "automatically" and "autopilot" — a reply with zero
   permission-mode content passed the *safety* scenario. Bare `brownfield`
   matched a passing **mention** where the assertion needed a **route**, so a
   textbook funnel passed while tripping three of four negatives. And the safety
   negative anchored on `bypassPermissions` when the corpus writes the
   hyphenated `bypass-permissions` — dead on arrival against the very regression
   it existed to catch.

3. **The property test's own liveness guard.** It compared a **ratio over
   survivors** (`live -eq present`) behind a glob guard satisfied by any
   survivor. Renaming three of four target files collapsed it to a vacuous
   `1 of 1` PASS *while printing "against all four."*

**Corollary — assert an ABSOLUTE expected count, never a ratio over what
happens to be present**, and derive it from the list (`set -- $ITEMS;
expected=$#`) so it tracks additions instead of hardcoding a number that
silently goes stale.

---

## 6. When the corpus must NAME a thing to FORBID it, assert on the VERB

A third instance of the absence-assertion hazard already recorded twice in
`[Phase 19]` (the 5-minute claim; `tour_step:`), and the one that generalizes
them.

Accepted copy warns *"unlike `bypass-permissions`, which has no guardrails — do
not substitute it"*. So a scenario forbidding the bare string
`bypass-permissions` **fires on the correct answer**: the better the reply, the
likelier it fails.

**What makes this instance worth its own entry: it inverts with model
strength.** A stronger model relays the warning more faithfully, so
`model: sonnet` — this repo's standard remedy for a flaky scenario — was tried
and **reverted**, because it converted a flaky pass into a *deterministic false
failure*.

Two rules follow:

- **(a)** Forbid `recommend <term>` / `use <term>` / `launch with <term>` —
  verb-adjacent forms that cannot appear in a correct warning. Verify in both
  directions: the copy's own warning sentence must pass; a real recommendation
  must fail.
- **(b)** `model: sonnet` is **not** a universal flakiness remedy. The repo's
  rule already says "prove haiku noise → *confirm sonnet passes* → then tag,"
  and the confirmation step is load-bearing, not ceremony — because for
  assertions trippable by faithfully reproducing source copy, model strength is
  *anti*-correlated with passing.
