---
shape: temporary-wbs
cycle: opus5-edge-pause
created: 2026-09-21
status: gate-failed-pending-rescope
parent-backlog: SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS (superseded in part — see WP-A1)
---

# Temporary WBS — Opus-5 Edge-Pause + Long-Context Replay Harness

> ## ⛔ WP-A3 GATE FAILED — 2026-09-21. Track B is NOT unblocked.
>
> The full matrix ran (5 slices × n=20 = 100 runs on opus). The harness produces
> edge-pauses at depth, but it **does not discriminate**: the negative controls
> fired at **57.5%** against **23.3%** for the real stop slices — Fisher exact
> **p = 0.001, in the wrong direction.**
>
> Per this WBS's own gate that is a **STOP-AND-RE-SCOPE**, not a proceed.
> **WP-B1/B2 remain blocked.** The live route forward is **WP-B3** (upstream
> filing), which never depended on the instrument: the production measurement
> stands on its own (979 turns, 8.2% vs 1.6%, p = 4.1×10⁻⁶).
>
> Nondeterminism is *not* the explanation — χ² across slices p = 1.9×10⁻⁴
> rejects a single shared rate. One real confound (16/100 runs never emitted
> F10b) and one post-hoc hypothesis (terminal-turn content) are written up in
> `docs/lessons/long-context-replay-harness.md` → "WP-A3 result".
>
> **The negative controls are the only reason this was caught.** The first gate
> checked solely "pooled rate distinguishable from zero" and returned **PASS**
> on this same run. Sensitivity is not specificity.


**This is NOT a roadmap milestone.** It reserves no milestone number and is **deleted on
completion** (fold-back-and-delete, §Completion below). Two tracks are scoped here:

- **Track A — Long-context replay harness** (the *instrument*)
- **Track B — The opus-5 F10b edge-pause** (the *bug*)

The tracks are **coupled in one direction**: B cannot be verified without A. That coupling is the
whole reason this WBS exists as one file rather than two.

---

## Background — what is already established

**The bug (Track B).** At `TRANSITION: F10b` (verify-self → verify-human) in autopilot, the model
ends its turn and hands control back instead of invoking `Skill(feature-verify-human)`. It writes
verify-human's *own* output (the phase-ready summary, the what-to-check list) itself, so the skill's
procedure — auto-skip gate, integration-boundary check, leaf construction — never runs.

Measured over 979 F10b turns of live session logs:

| model | F10b turns | stopped | rate |
|---|---|---|---|
| opus-4-7 | 110 | 2 | 1.8% |
| opus-4-8 | 578 | 9 | **1.6%** |
| **opus-5** | 291 | 24 | **8.2%** |

Fisher exact **p = 4.1×10⁻⁶**. Per-session (≥3 F10b turns, single-model): 4% of opus-4-8 sessions
had ≥1 misfire vs **31%** of opus-5 sessions. 43% of stopped turns *cite verify-human's own PAUSE as
the reason for stopping* — they read the pause one state early, at the **edge into** verify-human
rather than inside it. Corroborated by operator corrections in-session (`invoke verify human` ×3,
`auto chain it!!!`, `so? not autopiloting?`).

**Externally corroborated.** Anthropic's [Prompting Claude Opus 5] guide documents both the
over-literal instruction reading and — pointedly — that *"legacy harness scaffolding that adds
separate verification steps"* causes over-verification on Opus 5. Community reports (#87491, #82872)
describe the same disposition ("treats direct instructions as negotiable", "ignores loaded project
rules" in long sessions).

**Two candidate mitigations, neither measured:**
- **M-prose** — disambiguate the F10b cheat-sheet row + add an edge-pause prohibition. *Built and
  reverted this session; structural pins were mutation-proven 6/6 but behavioural effect unknown.*
- **M-actdontask** — the Product Compass "Act. Don't Ask" block (operator's stated lean): a
  **timing rule** ("do not ask for permission between steps of a task") rather than another
  per-transition prohibition.

**The instrument (Track A).** A 2026-05-16 attempt (`workflow-system/state/archive/session-replay-harness.md`)
built capture tooling, then abandoned the runner: `claude --resume` + one continuation prompt gave
**3/3 PASS on the buggy codebase even with framing stripped**. Its conclusion — *"single-shot replay
cannot reproduce this bug class"* — **is now known to be too strong.** It diagnosed its own cause
correctly (a describe-only overlay biased the model toward policy-correct output) but generalised
from one replay *shape* to replay in general.

**Breakthrough (2026-09-21, this session).** Rendering the prior 513 turns of a real opus-5 stop
session into plain transcript text (`### Human` / `### Assistant` + `[tool_use: …]` / `[tool_result: …]`,
per-block truncated) and passing it via `--append-system-prompt` **reproduced the bug: 1 edge-pause
in 5 opus runs**, emitting the production sentence verbatim —

> `TRANSITION: F10b (verify-self → verify-human)`
> *"Autopilot chains into verify-human, which is itself a PAUSE point — so this is your review."*

— followed by a hand-written checklist and **zero** skill invocations. This is the first
reproduction of this bug class in any harness. Mechanics: 242k-char system prompt passes the CLI
(`ARG_MAX` 1MB), ~$0.35/run on opus.

**Why the earlier probes failed to reproduce it** (both this session): a synthetic single-skill
scenario at ~26k context went 4/4 clean on opus, and the same scenario showed **zero
discrimination** on haiku (5 PASS/1 FAIL clean vs 5 PASS/1 FLAKY stripped) and sonnet (4 PASS/2
FLAKY *both* arms). Real failures sit at a median **445k tokens, ~1005 turns**. Context depth is
the load-bearing variable.

---

## Disposition model

Standard three axes — **Impact · Effort · Risk** — with this WBS's governing rule:

> **An unverifiable fix is not cheap.** Shipping a mitigation with no way to measure it is how this
> work already burned one cycle. Any WP that *changes behaviour* is gated behind a WP that can
> *measure* behaviour.

---

## Track A — Long-context replay harness (the instrument)

### WP-A1 · Promote the transcript renderer to a real tool `[DONE 2026-09-21 — 025a870]`

The renderer exists only as a scratchpad script and will be lost on the next scratchpad clear (it
already was once this session).

- Promote to `tools/render-session-transcript.py` with `--source`, `--end-index`, `--budget-chars`,
  `--out`; documented truncation defaults (tool 600 / text 3000 chars), `thinking` blocks dropped.
- Reuse `tools/capture-session-slice.sh` (13 Tier-1 redaction patterns, audited) — **do not
  re-implement redaction**. Renderer consumes a *captured, redacted* slice, never a raw log.
- `tests/check-structure.sh` Phase 8 already guards the capture tool's contract; extend it with the
  renderer's `--help`/exit-code contract.
- **Resolves the reusable half of** `SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS`.

### WP-A2 · Capture 3 additional opus-5 F10b stop slices `[DONE 2026-09-21 — ad60d1e; 3 stops + 2 controls, operator-audited]`

One session is an anecdote. 25 real opus-5 stops exist in the claudesk logs; 6 are recent.

- Capture ≥3 more via `capture-session-slice.sh`, each with its Tier-2 human audit signoff in
  `tests/sessions/AUDIT-LOG.md` (**the audit is the risk item — these are real work logs**).
- Also capture ≥2 *chained* (non-failing) F10b turns as **negative controls**.

### WP-A3 · Establish the baseline rate, n≥20 per slice `[RUN 2026-09-21 — a14b578; GATE FAILED, see banner]`

- Drive each slice n≥20 on opus; record edge-pause / chained / other.
- **Gate:** the pooled baseline must be **distinguishable from zero** with a reported CI. If the
  pooled rate is <2%, the harness is too insensitive to A/B a fix against — **STOP and re-scope**,
  do not proceed to Track B.
- Report ratios (`4/20`), never verdicts. Per `docs/lessons/green-tests-that-guard-nothing.md`
  (eighth mechanism): n≥6 is the floor for *any* claim; n≥20 is what a ~10%→~2% delta needs.
- Est. ~$70–100 total on opus across 4 slices.

### WP-A4 · Wire replay into `tests/run-tests.sh` as a scenario type `[DO NOT START — blocked by A3's failed gate]`

**Deliberately last in Track A, and optional.** The v1 attempt died partly by building the runner
integration before knowing what it should assert.

- New scenario field (`transcript_slice:` + `end_index:`), budget override, `model: opus` pinned.
- **Do not port v1's `session_slice` code path** — the archive says clean rebuild is preferred.
- **Do not add a scenario that asserts PASS on current code.** v1's S26 did exactly that and the
  archive calls the semantics "misleading". A replay scenario here asserts a *rate over n runs*,
  not a single pass/fail.

---

## Track B — The opus-5 F10b edge-pause (the bug)

**Every WP in Track B is BLOCKED on WP-A3 clearing its gate — and as of 2026-09-21 it
DID NOT.** WP-B1/B2 are therefore **not startable**. **WP-B3 is the live route**: it
rests on the production measurement, not on the replay instrument.

### WP-B1 · A/B the two mitigations against baseline `[impact: high · effort: med · risk: low]`

- Three arms — **control** (current prose) · **M-prose** · **M-actdontask** — same slices, same n≥20,
  same rendered context. Only the SKILL.md/CLAUDE.md prose differs.
- Both arms of each mitigation measured at **equal depth** against a baseline measured at equal
  depth. Report the ratio and CI.
- **Pre-register the success bar before running:** a mitigation "works" only if its CI excludes the
  control's point estimate. Deciding this after seeing the numbers is how a null result gets
  narrated into a win.
- M-prose is recoverable from this session's reverted diff (mutation-proven pins included).

### WP-B2 · Ship the winning mitigation `[impact: high · effort: low · risk: low]`

- Ship **only** if WP-B1 shows a real effect. A null result is a legitimate outcome → go to WP-B3.
- Include the structural pins (section-scoped, fail-closed on both boundaries, 6/6 mutants) and the
  measured before/after in the commit message.

### WP-B3 · If no mitigation wins: escalate upstream `[impact: med · effort: low · risk: low]`

- File a Claude Code issue with the measurement — 979 turns, per-model rates, Fisher p, the
  reproduction recipe, the verbatim failure sentence. Nothing in the public issues carries data at
  this resolution; #87491 and #82872 are qualitative.
- Consider the **subtraction** experiment Anthropic's guide implies: does *removing* verification
  scaffolding reduce the edge-pause? Uncomfortable to test on a system whose value is that
  scaffolding — which is exactly why it needs measuring rather than assuming.

---

## Scope — what's NOT swept (anchors intact)

- **Multi-turn drive-loop replay** (v1's Option C) — **Buried.** The transcript-as-prompt approach
  reproduces the bug at ~$0.35/run with no orchestration loop; the drive loop is strictly more
  expensive for no demonstrated gain. Anchor: revisit only if WP-A3 fails its <2% gate.
  **⚠️ THIS ANCHOR HAS NOW FIRED (2026-09-21).** WP-A3 failed — not on the <2% arm, but on
  discrimination, which is the stronger failure. The un-bury argument is also stronger than
  the anchor anticipated: in single-turn replay the model **cannot actually invoke a skill**,
  so "hand back" may be the only coherent action available to it in many contexts, which
  would put a floor under *both* arms and is a candidate explanation for controls firing at
  57.5%. A drive loop lets the model actually call the tool, making "did it chain?" a real
  observation instead of a declared intention. **This is the leading re-scope candidate** —
  but it is a hypothesis for the re-scope to test, not a decision taken here.
- **Opus 4.7 model pinning** (memory `feedback_replay_harness_research_conditions`) —
  **Deferred/superseded for this WBS.** That memory pins 4.7 to mirror the *2026-05-16* bug's
  conditions; the bug here is opus-5-specific, so **opus-5 is the correct pin**. The memory's own
  "How to apply" allows a per-scenario opt-out. **Operator should confirm** — this WBS overrides a
  recorded preference, and it is flagged rather than silently applied.
- **The wider "Opus 5 ignores process instructions" class** (#82872 et al.) — out of scope. This
  WBS measures *one* transition with a known base rate.
- **`tests/scenarios/feature.yaml` edge-pause scenario** — **Deleted**, not deferred. Measured
  non-discriminating on both tiers; the negative result belongs in WP-A4's design notes.
- **The pre-existing `effortLevel` settings-fixture drift** (1 FAIL in check-structure) — untouched,
  tracked since 2026-07-25.

---

## Completion — fold-back-and-delete

On completion: confirm each WP resolved; fold WP-A1/A2's durable artifacts into
`tools/` + `tests/sessions/` + `check-structure.sh`; resolve or rewrite
`SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS` per the delete-on-resolve rule (CHANGELOG entry
lands in the *same commit* as the backlog deletion); record the measured rates in
`docs/lessons/`; then **delete this file**.

### Disposition 2026-09-21 — NOT deleted, deliberately

**The delete clause does not fire, because this cycle did not complete — it failed a gate.**
Fold-back-and-delete assumes the work resolved and its durable half landed elsewhere. Here
**WP-B1/B2 were never started** and a live re-scope question is open, so deleting this file
would destroy the only record of *what to re-scope and why*. Deleting on a failed gate would
also quietly convert "we measured this and it did not work" into "this was never tried" — the
precise erasure that let three prior attempts at this bug class repeat each other.

**What DID fold back (the durable half is safe independent of this file):**

| artifact | home |
|---|---|
| transcript renderer | `tools/render-session-transcript.py` + `[Phase 8b]` (8 assertions) |
| baseline runner | `tools/replay-baseline.sh` (resumable; discrimination gate) |
| derivation script | `tools/analysis/measure-f10b-handback-rate.py` |
| 5 audited slices | `tests/sessions/` + `AUDIT-LOG.md` signoffs |
| audit procedure | `tests/sessions/README.md` (written this cycle; had never existed) |
| the n=100 result | `docs/lessons/long-context-replay-harness.md` → "WP-A3 result" |
| raw ledger | `tests/results/wp-a3-baseline.jsonl` (100 runs, committed) |
| upstream filing | `docs/upstream/opus5-f10b-edge-pause-issue.md` (drafted, NOT filed) |
| validity-gate rule | root `CLAUDE.md` → `## Conventions` |

**Delete this file when** either (a) WP-B3 is filed and the re-scope is formally declined —
at which point the durable artifacts above carry everything and this file is redundant; or
(b) a re-scoped Track A supersedes it, in which case the successor WBS cites it and this one
goes. **Do not delete it merely because the cycle stopped being active.**
