---
shape: temporary-wbs
cycle: opus5-edge-pause
created: 2026-09-21
status: active
parent-backlog: SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS (superseded in part — see WP-A1)
---

# Temporary WBS — Opus-5 Edge-Pause + Long-Context Replay Harness

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

### WP-A1 · Promote the transcript renderer to a real tool `[impact: high · effort: low · risk: low]`

The renderer exists only as a scratchpad script and will be lost on the next scratchpad clear (it
already was once this session).

- Promote to `tools/render-session-transcript.py` with `--source`, `--end-index`, `--budget-chars`,
  `--out`; documented truncation defaults (tool 600 / text 3000 chars), `thinking` blocks dropped.
- Reuse `tools/capture-session-slice.sh` (13 Tier-1 redaction patterns, audited) — **do not
  re-implement redaction**. Renderer consumes a *captured, redacted* slice, never a raw log.
- `tests/check-structure.sh` Phase 8 already guards the capture tool's contract; extend it with the
  renderer's `--help`/exit-code contract.
- **Resolves the reusable half of** `SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS`.

### WP-A2 · Capture 3 additional opus-5 F10b stop slices `[impact: high · effort: low · risk: med]`

One session is an anecdote. 25 real opus-5 stops exist in the claudesk logs; 6 are recent.

- Capture ≥3 more via `capture-session-slice.sh`, each with its Tier-2 human audit signoff in
  `tests/sessions/AUDIT-LOG.md` (**the audit is the risk item — these are real work logs**).
- Also capture ≥2 *chained* (non-failing) F10b turns as **negative controls**.

### WP-A3 · Establish the baseline rate, n≥20 per slice `[impact: high · effort: med · risk: low]`

- Drive each slice n≥20 on opus; record edge-pause / chained / other.
- **Gate:** the pooled baseline must be **distinguishable from zero** with a reported CI. If the
  pooled rate is <2%, the harness is too insensitive to A/B a fix against — **STOP and re-scope**,
  do not proceed to Track B.
- Report ratios (`4/20`), never verdicts. Per `docs/lessons/green-tests-that-guard-nothing.md`
  (eighth mechanism): n≥6 is the floor for *any* claim; n≥20 is what a ~10%→~2% delta needs.
- Est. ~$70–100 total on opus across 4 slices.

### WP-A4 · Wire replay into `tests/run-tests.sh` as a scenario type `[impact: med · effort: med · risk: med]`

**Deliberately last in Track A, and optional.** The v1 attempt died partly by building the runner
integration before knowing what it should assert.

- New scenario field (`transcript_slice:` + `end_index:`), budget override, `model: opus` pinned.
- **Do not port v1's `session_slice` code path** — the archive says clean rebuild is preferred.
- **Do not add a scenario that asserts PASS on current code.** v1's S26 did exactly that and the
  archive calls the semantics "misleading". A replay scenario here asserts a *rate over n runs*,
  not a single pass/fail.

---

## Track B — The opus-5 F10b edge-pause (the bug)

**Every WP in Track B is BLOCKED on WP-A3 clearing its gate.**

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
