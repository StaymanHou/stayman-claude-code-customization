# Long-context replay harness — reproducing a deep-context behavioral bug

**Added 2026-09-21** (opus5-edge-pause WP-A1/A2/A3). Companion to the temporary
WBS at `workflow-system/product/opus5-edge-pause-wbs.md`, which is
**deleted on completion** — this doc is the durable half.

## The capacity, in one line

`tools/render-session-transcript.py` renders a **captured, redacted** session
slice back into plain transcript text, which `--append-system-prompt` feeds to
a fresh `claude --print` run. It reaches a context depth no synthetic scenario
in `tests/scenarios/` can.

> **Read the WP-A3 result below before building on this.** The instrument works
> mechanically and produces edge-pauses at depth — but measured against negative
> controls it **does not discriminate** the bug from ordinary replay behaviour
> (controls 57.5% vs stops 23.3%, p = 0.001, backwards). It is not currently a
> valid surface for A/B-ing a mitigation.

## Why it exists: context depth is the load-bearing variable

The harness in `tests/run-tests.sh` drives scenarios at roughly 26k context.
The opus-5 F10b edge-pause — where the model emits `TRANSITION: F10b`, then
hands control back instead of invoking `feature-verify-human`, writing that
skill's own output itself — sits at a **measured 8.2% rate** in production
(vs 1.6% on opus-4-8, Fisher p = 4.1×10⁻⁶ over 979 turns). Real failures sit at
a median **~445k tokens / ~1005 turns**.

Three attempts failed to reproduce it before this one, all for the same reason:

1. **2026-05-16 single-shot replay** — `claude --resume` + one continuation
   prompt: 3/3 PASS on the buggy codebase even with framing stripped.
2. **A synthetic scenario** at ~26k context — measured **non-discriminating on
   both tiers** (haiku 5 PASS/1 FAIL clean vs 5 PASS/1 FLAKY stripped; sonnet
   4 PASS/2 FLAKY in *both* arms). Deleted.
3. **Opus at ~26k context** — 4/4 clean.

**A fix cannot be evaluated on a surface that cannot fail.** That is the whole
argument for this tool, and it generalizes: before A/B-ing any behavioral
mitigation, establish that the measurement surface reproduces the failure at a
rate distinguishable from zero. The 2026-05-16 archive
(`workflow-system/state/archive/session-replay-harness.md`) concluded
*"single-shot replay cannot reproduce this bug class"* — it diagnosed its own
cause correctly (a describe-only overlay biased the model toward policy-correct
output) but **generalized from one replay *shape* to replay in general.**

## How to use it

```sh
# 1. Capture + redact a slice (Tier-1 automated, Tier-2 human audit REQUIRED)
tools/capture-session-slice.sh \
  --source ~/.claude/projects/<slug>/<session>.jsonl \
  --terminator-uuid <uuid of the turn to reproduce> \
  --output tests/sessions/<name>.jsonl --name <name>

# 2. Render the prior turns (terminator EXCLUDED — it is what the model must produce)
tools/render-session-transcript.py \
  --source tests/sessions/<name>.jsonl \
  --end-index <record index of the turn to reproduce> \
  --out ctx.txt

# 3. Drive it
claude --print "continue" --model opus --no-session-persistence \
  --append-system-prompt "$(cat ctx.txt)
<your test framing>"
```

Mechanics: a 242k-char system prompt passes the CLI (`ARG_MAX` is 1MB on
darwin), ~**$0.35/run** on opus.

### `--end-index` is a RECORD index, not a turn count

The single easiest way to silently ruin a run. A session log interleaves
`attachment`, `mode`, `system` and other record types with the
`user`/`assistant` turns — in the reference slice, **2413 records hold only
~1005 renderable turns**. Passing a turn count where a record index belongs
renders roughly **half** the intended depth, prints a cheerful success line,
and quietly under-powers the experiment on the one variable that governs
whether the bug can appear at all.

This bit us directly: a handoff note recorded "513 turns", and 513 read as an
index renders 249 turns / 117k chars instead of 513 turns / 240k chars. The
correct index was 1004. **Always confirm the render's reported turn count and
char total against what you expect** — the tool prints both, and warns when the
budget binds.

## Defaults and why

| Knob | Default | Rationale |
|---|---|---|
| `--tool-cap` | 600 chars | tool output is the bulk of a real log and mostly noise for disposition purposes |
| `--text-cap` | 3000 chars | assistant/human prose carries the narrative cadence the bug is sensitive to — hence the 5× asymmetry |
| `--budget-chars` | 300,000 | ~75k tokens; validated empirically at 242k against `ARG_MAX` |
| `thinking` blocks | dropped | not recoverable from a session log |

Turns accumulate **backward** from `--end-index`, so the window ends flush
against the turn under study and the *oldest* turns drop when the budget binds.

## The redaction boundary — do not work around it

The renderer **does not redact anything.** It consumes a slice already through
`capture-session-slice.sh`'s 13 Tier-1 patterns plus a Tier-2 human audit, and
**refuses** a raw `.claude/projects` path unless `--allow-unaudited` is passed
(local throwaway probing only; output must never be committed).

Duplicating redaction across two tools is how the two copies drift. If the
renderer ever needs to read something the capture tool cannot produce, fix the
capture tool.

**Tier-2 is a human gate, and it is the real one.** These are real work logs.
The automated scan clears secrets; it cannot judge whether a session's product
discussion, screenshots, or personal-domain content are shareable. Known Tier-1
defect as of 2026-09-21: the FACEBOOK pattern false-positives on embedded base64
PNG data, inflating the "patterns matched" count
(`SURFACE-2026-09-21-CAPTURE-SLICE-FACEBOOK-PATTERN-FALSE-POSITIVE`).

## Silent degradation is this tool's real risk

It does not break; it **degrades quietly**. A dropped range check or redaction
guard still prints a success line — it just renders a shallower context or reads
an unredacted log. Both corrupt a *measurement* rather than failing a build,
which is why half of `[Phase 8b]`'s 8 assertions in `tests/check-structure.sh`
drive error paths rather than liveness, and why the exit codes are distinct
(`0` ok · `1` arg/source incl. unaudited refusal · `2` end-index out of range ·
`3` zero renderable turns) rather than a single non-zero.

Usage errors exit **1, not argparse's default 2**, to match the sibling
`capture-session-slice.sh`; the `ArgParser.error` override exists solely to hold
that line.

## A detector that finds candidates is not a detector that measures a rate

Worth its own heading, because the failure was live and instructive.

A first pass at classifying F10b turns across all project logs reported
**17.8% stopped (58/326)** against the WBS's measured **8.2%**. The WBS number
was right. Two independent defects:

1. **`TRANSITION:\s*F10b?` matches bare `F10`** — a different transition
   (verify-auto → verify-self). The `b?` made the `b` optional.
2. **Legitimate pauses counted as the bug** — stepping mode (where pausing is
   *correct*), genuine design questions put to the operator, and one case of
   the model correctly declining to override a recorded deferral instruction.

Both inflated the numerator. The lesson is not "write a better regex" — it is
that **the edge-pause is defined by drive mode plus the absence of a legitimate
blocker**, which is a judgment a keyword classifier cannot make. Use the
detector to *find* candidates; **hand-verify every one** before it enters a
measurement. Report ratios, never verdicts.

Positive confirmation criteria for a genuine instance:

- model is `opus-5`, and drive mode is **autopilot or FSD** (never stepping)
- `TRANSITION: F10b` emitted
- `feature-verify-human` **never invoked** in that turn or the next assistant turn
- a hand-written human-check list appears **in place of** the skill's output
- no legitimate blocker (open design question, recorded deferral, operator instruction)

## Anchors — what is deliberately NOT here

- **Multi-turn drive-loop replay** — buried. Transcript-as-prompt reproduces the
  bug at ~$0.35/run with no orchestration loop.
- **A scenario asserting PASS on current code** — the 2026-05-16 attempt's `S26`
  did exactly that, and the archive itself calls the semantics "misleading." A
  replay assertion states a **rate over n runs**.
- **Model pinning to opus-4.7** — memory
  `feedback_replay_harness_research_conditions` defaults replay work to 4.7 to
  mirror the *2026-05-16* bug's conditions. For an **opus-5-specific** bug that
  is the wrong instrument; operator ratified the per-scenario opt-out
  2026-09-21. The dot-free `/tmp` cwd rule is unaffected.

## WP-A3 result: the harness does not discriminate (2026-09-21, n=100)

Full matrix: 5 slices × n=20 on opus, ~19s/run, 0 unclassifiable.

| slice | edge-pause | expected |
|---|---|---|
| `chained-hermes-b` | 13/20 = 65% | chained — **control** |
| `stop-claudesk-a` | 10/20 = 50% | stop |
| `chained-claudesk-c` | 10/20 = 50% | chained — **control** |
| `stop-claudesk-b` | 2/20 = 10% | stop |
| `stop-hermes-a` | 2/20 = 10% | stop |

**Stops 14/60 = 23.3% · controls 23/40 = 57.5% · Fisher p = 0.001, controls
HIGHER.** The gate fails: a surface whose negative controls fire more than its
positives cannot A/B a mitigation.

### Is it just LLM nondeterminism?

The obvious reading — "LLMs are stochastic, we can't control this" — is
**testable, and the data rejects it.** If one global coin governed every run,
all five slices would sit near the pooled 37% and the spread would be sampling
noise. Chi-square for homogeneity across the five slices: **X² = 22.1, df = 4,
p = 1.9×10⁻⁴.** The slices do not share a rate. Something slice-specific is
driving the outcome; nondeterminism is the *noise*, not the *signal*.

Two more specific factors came out of the post-hoc analysis:

**1. A confound: 16 of 100 runs never emitted F10b at all.** Those runs never
reached the transition under study, so they cannot exhibit the bug — yet they
landed in the edge-pause bucket at 88% (vs 27% for runs that did emit F10b,
Fisher p = 9.3×10⁻⁶). They were measuring "the model did something else
entirely." **Restricting to the 84 valid runs narrows the gap but does not
close it: stops 17.0%, controls 45.2%, p = 0.010, still backwards.** So the
confound is real and worth fixing, and it is not the whole story.

**2. A hypothesis, explicitly not a finding.** The two 10% slices are the two
whose rendered context ends on a `tool_result` stating the verify-self work is
complete *and recorded* (one carries a commit hash). The three 50%+ slices end
on vaguer terminal content — a bare `ok`, an unchecked checklist. A plausible
mechanism is that an unambiguous "this step is finished and written down"
signal is what licenses the model to continue, and its absence invites a
hand-back regardless of what the production run did. **This is a post-hoc
pattern over five points. It needs a pre-registered test on fresh slices
before anyone treats it as true.**

### What this costs, and what survives

Track B stays blocked; this routes to **WP-B3** (upstream filing). The
production measurement is unaffected and stands on its own — 979 real turns,
8.2% opus-5 vs 1.6% opus-4-8, Fisher p = 4.1×10⁻⁶. What failed is the *replay
instrument*, not the observation.

**The gate itself was also defective and is now fixed.** It originally checked
only that the pooled rate was distinguishable from zero — which this trivially
is (CI lower bound 14.4%) — and returned **PASS**. Sensitivity is not
specificity: a harness that fires often is not a harness that fires
*correctly*. Without the negative controls this run would have been recorded as
a success and WP-B1 would have A/B'd a mitigation against prompt framing.
`replay-baseline.sh --report` now requires controls near zero and returns FAIL
when they fire at or above the stop slices.

**The controls were the whole experiment.** They were also the part of WP-A2 I
originally skipped and had to be told to go back for.

### If this is re-scoped, the open questions are

1. **Drop runs that never emit F10b** — they are not observations of this bug.
   Either filter them or make the framing reliably reach the transition.
2. **Test the terminal-turn hypothesis** on fresh slices, pre-registered.
3. **Ask whether single-turn replay can work at all.** The model cannot
   actually invoke a skill in this harness, so "hand back" may be the only
   coherent action in many contexts — which would put a floor under *both*
   arms. That points back at the multi-turn drive loop the WBS buried, and is
   the strongest argument for un-burying it.

   **Partly tested 2026-09-21, and the floor hypothesis is NOT the explanation.**
   A re-scope probe proposed that the runner's `--permission-mode dontAsk`
   (which *does* block the `Skill` tool: *"Permission to use Skill has been
   denied…"*, verified as a clean `dontAsk`/`bypassPermissions` pair) had made
   chaining impossible in all 100 runs. **The ledger refutes that:**

   - **0/100** responses hit a permission denial on `Skill`.
   - **100/100** emitted the required `NEXT-ACTION:` line, and **63 declared
     `INVOKE`.**

   The harness never asked the model to *call* the skill — `PROMPT` asks it to
   **declare** its next action on a machine-readable line, explicitly as a dry
   run. So `dontAsk` is inert for the decision under study, the model was never
   prevented from expressing "chain", and it expressed it in a clear majority of
   runs. **The floor-under-both-arms hypothesis is dead as stated**, and with it
   the strongest argument the WBS recorded for un-burying the drive loop.

   **What the probe did establish, and it is narrow:** `dontAsk` blocks `Read`
   and `Bash` too, and **1 of 100 runs** edge-paused *because of that* —
   > *"Both Read and Bash are denied — the session is in don't-ask mode with no
   > tool access, so I can't expand the checklist leaves… I'll stop rather than
   > work around it."*

   That is a real contaminant worth removing (it manufactures a hand-back for a
   harness-configuration reason), but it is **~1% of outcomes, not the 57.5%
   control rate.** The discrimination failure remains unexplained: restricting
   to the 84 runs that emitted F10b still gives stops **9/53 = 17.0%** vs
   controls **14/31 = 45.2%** — backwards.

   **Methodological note, recorded because it nearly shipped as a finding.** The
   probe's premise came from reading the runner's `claude --print` invocation and
   reasoning about what the model *could* do, without checking what it *did*.
   The 100-run ledger with full responses was already committed and answered the
   question in one query. **Read the recorded evidence before theorising about
   the instrument that produced it** — and note that an intermediate check
   ("could the CLI resolve/call the skill from this cwd?") returned a true
   answer that was *irrelevant to the actual configuration*, which is what made
   it convincing.

## The reversal is partly a CLASSIFIER defect, not only an environment effect (2026-09-21)

Reading the raw responses in `tests/results/wp-a3-baseline.jsonl` — which had never been
done; the WP-A3 analysis worked entirely off the `outcome` column — found that
`NEXT-ACTION: HAND-BACK-TO-OPERATOR` **conflates two opposite behaviours**:

| what the turn did | correct? | classifier |
|---|---|---|
| ran verify-human's procedure (auto-skip gate, integration boundary, `P<n>.verify-human.<k>` leaves) then handed to the human | **correct — that is how verify-human ENDS** | `edge-pause` 🐛 |
| skipped the procedure and narrated a checklist itself | **the bug** | `edge-pause` 🐛 |

Both end in a human pause, so both emit the same mandated line. The binary the prompt
forces cannot separate "paused *because I did the work*" from "paused *instead of* doing
the work" — and the second is the entire bug.

**This is what put the ranking backwards.** All **13/13** of `chained-hermes-b`'s
edge-pauses score 3/3 on procedure signals — every one *performed* verify-human and handed
back correctly. That single slice supplies **13 of the 23** control "failures" and is why
it topped the chart at 65%. Conversely the two slices the harness almost never flags
(`stop-claudesk-b`, `stop-hermes-a`) score **0/3** on their edge-pauses — no procedure,
just a stop. The real bug shape is where the harness is *quietest*.

**Re-tallying with the category split** (`edge-pause` AND <2 procedure signals = bug):

| | as classified | procedure-split |
|---|---|---|
| stops | 23.3% | **13.3%** |
| controls | **57.5%** | **20.0%** |
| valid-only stops | 17.0% | **9.4%** |
| valid-only controls | **45.2%** | **25.8%** |

So the defect accounts for **most of the reversal but not all of it** — controls still come
out higher. Two effects, not one; the environment effect is real but much smaller than
WP-A3 reported.

**⚠️ The split above is NOT trustworthy enough to act on, and must not be quoted as a
result.** `did_work()` is three prose regexes written in the same session — *prose-keyword
classification*, the exact failure this project has logged repeatedly (root `CLAUDE.md`:
classify structurally, never on prose keywords). Hand-reading one `stop-hermes-a` run that
it scored 0 showed a genuinely ambiguous turn: a detailed verify-self summary followed by a
handback, with no verify-human procedure. Whether that is "the bug" or "a reasonable
summary before stopping" is a **judgment call the regexes silently made.** Treat the numbers
as *evidence that a category defect exists*, not as a measurement of its size.

**What a real fix needs** (none of it done):
1. A **structural** discriminator, not keywords — e.g. require the turn to emit the Work-Tree
   leaf lines verify-human is specified to write, and check for *those*; or split the mandated
   line into three options (`INVOKE` / `HAND-BACK-AFTER-RUNNING-<skill>` /
   `HAND-BACK-WITHOUT-RUNNING-<skill>`) so the model declares the distinction itself.
2. **Hand-label a sample first** to establish ground truth, then measure the discriminator
   against it. n≥6 per arm minimum.
3. Re-run only after 1 and 2. The existing 100 runs can be **re-scored offline for free** —
   full response bodies are in the ledger — so the discriminator can be validated before any
   new spend.

### Two process failures worth more than the finding

**1. Nobody read the raw output.** The ledger was committed *with full response bodies* and
the entire WP-A3 conclusion ("the harness does not discriminate"), its gate rewrite, and a
re-scope proposal were built from the aggregate `outcome` column. The defect was visible in
the first response anyone opened. **Read the raw output before theorising about the aggregate.**

**2. A structural-looking signal is not a structural signal.** `classify()` was carefully
built to avoid keyword matching (its `edge` prose annotation is deliberately *unused*), and
the `NEXT-ACTION:` line genuinely is mechanical. But mechanical *form* is not correct
*categories*: the line is a faithful reading of a distinction that was itself wrong. The
earlier keyword fix moved the defect up a level rather than removing it.
