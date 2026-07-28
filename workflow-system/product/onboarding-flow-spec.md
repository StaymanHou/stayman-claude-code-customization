---
shape: onboarding-flow-spec
stage: spec
milestone: 11
state: complete
updated: 2026-07-27
---

# Onboarding Flow Spec — the `workflow-tour` first-run experience (M11 / WP7a)

> **What this is.** The durable design contract for the new-user onboarding experience. It
> promotes the operator co-design in [`onboarding-brainstorm.md`](onboarding-brainstorm.md)
> (2026-07-21) into a precise, buildable spec. **This is a promotion, not a revision** — every
> settled brainstorm decision is preserved in intent; where this doc corrects the brainstorm it
> is called out explicitly (the permission-mode distinction in §5 — originally `acceptEdits`
> vs `bypassPermissions`, further revised to `auto` in WP7g; see §5b).
>
> **Who reads it.** WP7b (entry skill) / WP7c (scaffold) / WP7d (beats-wiring) / WP7e
> (scenarios + pins) build against this contract. **WP8** hands the Claudesk-facing part (§4)
> back to Claudesk as the M12 return-contract deliverable.
>
> **Origin:** `SURFACE-2026-07-20-CLAUDESK-ONBOARDING-DESIGN`, roadmap Milestone 11,
> `HANDOFF-from-claudesk-2026-07-20.md` item #5.

---

## Revision 2026-07-27 (WP7o — tour state survives the session boundary; SUPERSEDES WP7m's 7m.1 placement)

Same day as the WP7m revision below, and it **supersedes that revision's placement decision** on the strength
of evidence WP7m did not have: the raw log of the operator's own greenfield run.

**Two defects, one root cause.** The operator's 2026-07-27 re-acceptance run reported (1) a first-run tour
coming back as **Orchestrated** instead of stepping, with the 1–4 drive-mode menu shown — leaking the Step-8
graduation reveal early; and (2) the second-boundary handoff **fork still appearing** (*"better than previous
walkthrough"* but still a fork). Both trace to one gap: **the tour's state existed only in the conversation and
died at `/exit`.** Nothing was written to disk, so nothing survived the boundary the tour is built around.

**Why WP7m's placement could not have worked (7m.1 superseded).** WP7m decided the boundary guard belongs *in
the arms, not the general session skills*. The Session-C log settles it: the only skills loaded there were
`/session-restore` → `feature-ship` → `feature-review-quality` → `feature-finalize` → `session-reflect`. **The
arm is never re-invoked.** So at the moment the boundary fired, the guard prose was not in context at all — an
arms-only guard is structurally unreachable across a session boundary. That is why WP7m's copy-only fix could
soften the fork but not remove it.

**The mechanism (operator-chosen, option 1 of 3): the pointer carries tour state.**

- `workflow-system/state/.session.md` gains two **optional, tour-only** fields — `tour: greenfield|brownfield`
  and `tour_step: <n>` — written **only** when a `tutorial-*` skill drives the handoff as one of its own beats.
  Absent from every ordinary handoff; when absent, every downstream reader takes its existing path unchanged.
  > **SUPERSEDED 2026-07-27 (WP7e) — `tour_step:` was DROPPED; `tour:` alone is the marker.** The paragraph
  > above is retained as the **as-built record of what WP7o shipped**, not as the current contract. `tour_step:`
  > was written by four files and read by none, promising a step-addressed resume precision nothing implemented;
  > resume is **arm-addressed**. Current schema of record: `skills/session-handoff/SKILL.md` §2, "Tour-driven
  > handoffs". Operator ruling recorded in `SURFACE-2026-07-27-QUALITY-TOUR-STEP-FIELD-HAS-NO-READER`.
- **`drive_mode` becomes required on a tour pointer.** The first-run branch now records `drive_mode: stepping`
  to the tour WIP (it previously wrote nothing, which is what let restore default to orchestrated).
  **Recording ≠ revealing** — the write is to disk; the modes-stay-hidden prohibition is untouched.
- **`resume_skill` points at the ARM**, not the inner workflow's next state. This is the load-bearing half:
  Session C reloads the arm, so the arm's own guard prose *is* in context at the later boundary, and the fork
  cannot recur by construction. Pointing it at the inner workflow instead is what left Session C holding two
  competing continuations (finish the feature, or play Step 8?) with nothing in context that knew the answer.
  `state_file` still points at the inner WIP so the work content stays reachable.
- The arms also stamp `tour:` into the **in-tour WIP frontmatter**, because `/session-restore` *deletes* the
  pointer once consumed — the WIP copy is what survives to a later boundary.

**The invariant is restated, not abandoned.** 7m.1's *spirit* holds: **the arms own all tour narration copy;
the general session skills carry only a mechanical `tour:` field read.** `tests/check-structure.sh` [Phase 18]
block (i) was rewritten to pin exactly that distinction (positive: the field read is present; negative: no tour
*content* — no sample data, numbered beats, or tour dialogue), keeping its fail-closed `[ -f ]` precondition.
`session-capture` keeps the original zero-vocabulary rule — it sits on the `S23` arm but never evaluates a
boundary.

**No state-machine change.** No new transition ID, no new edge, no pause-policy row; `S22`/`S23` are unchanged
for real non-tour work. Verified as an empty diff on `transitions.md` and all four `agents/*/AGENTS.md` at every
phase. The escalation clause was checked at plan time and each phase, and never fired.

**§D resolved (the open design question WP7l left).** The operator's answer: **keep refuse-if-non-empty, and add
an offer to clear the directory** — *not* the passed-over `./onboarding-sample-todo/` subdir fallback. Because
that offer is destructive and governed only by prose, it carries four hard rules (**show** the real `ls -A`
listing *before* asking · **explicit** consent only — a bare "go"/"proceed"/"ok" is *not* consent · the
different-folder option is an **equal peer**, not a fallback · never `--force`, never auto-delete, never a temp
dir) plus two absolute limits (**a git working tree is never cleared** — checked *before* the offer is made, so a
repo never sees it; and deletion is bounded to the cwd's own contents, expressible only as *"remove the entries
`ls -A` just listed, in this directory"*). Declining — or any ambiguity — leaves every file untouched.
**Greenfield-only**: a real repo has nothing disposable, so the brownfield arm gets no such offer.

## Revision 2026-07-27 (WP7m — tour-aware session boundary; completes the 2026-07-25 fix set)

The third and last of the three greenfield fixes ratified from the operator's 2026-07-25 batch
acceptance walkthrough (WP7l + WP7n landed 2026-07-25; the prior revision noted "WP7m is a separate
follow-on WP" — **this closes that loop**).

> **⚠️ FRAMING CORRECTED 2026-07-27 (same day, after the operator re-read the walkthrough doc).** The
> first draft of this section — and the first build of the guard — got the diagnosis wrong in three
> ways, all now fixed here and in both arms. It (a) claimed the misfire was **mid-tour**, (b) asserted
> the in-tour close is **"NOT the session's boundary"**, and (c) quoted an **operator ruling that does
> not exist in any session log** (*"It should just continue the tour without offering the hand off
> option"* — traced to an assistant turn in session `a1fd9223`, then re-quoted as the operator's words
> through a handoff). The operator's **only** statement on this is two words — **"continue the tour"**
> (`mccc-tutorial-a/edf22b62`, line 48, 2026-07-24) — typed as an *answer to a fork that should not have
> been shown.* The corrected reading is below. Lesson recorded: a quoted operator ruling inherited from
> a handoff must be re-grounded in the raw log before it is propagated into a durable doc.

**The defect (corrected).** Per the designed chain
([`docs/lessons/tutorial-tour-session-chain-flow.md`](../../docs/lessons/tutorial-tour-session-chain-flow.md)),
**Session B ends with `/session-handoff`** — that staged Step-7 bookend *is* the tour's handoff, and the
designed sequence contains **no separate "feature close" beat.** In the live run the arm performed that
handoff, the user `/exit`ed, and `/session-restore` opened **Session C**. *Then* the real in-tour
feature's workflow reached `feature-finalize → session-reflect` **inside Session C** — a second, genuine
clean boundary the designed sequence never anticipated, sitting **between Step 7 and Step 8** (not
mid-tour). The state machine read it correctly: the exit chain **`S22`** (no-learning arm) / **`S23`**
(after a `session-capture` save) is **AUTO in all four drive modes** (`transitions.md:481-482` + the
"Session-boundary exit chain" pause-policy block). The agent surfaced it as a fork — "Continue the tour"
vs. "Hand off now" — and the operator answered *"continue the tour."*

**The root cause is the FRAMING, not the mechanism.** The boundary was real and the `S22` reading was
right. What was wrong was handing the user a **decision** about a mechanism the tour had *just
demonstrated one step earlier* — the Step-7 beat was already spent. Neither `session-reflect` nor
`session-handoff` has any tour-awareness (`grep -i 'tour|tutorial'` → 0 substantive hits), so nothing
told the agent that this boundary was a **teaching moment rather than a choice**.

**Settled family invariant (new — binds both arms):**

> **A clean boundary inside a tour run is REAL — narrate it, don't offer it.** Do not deny the boundary
> (it is genuine, and `S22`/`S23` read it correctly), and do not take or offer the handoff either. On
> reaching `session-reflect` from an in-tour close: run reflect normally; **say in one or two sentences
> what the boundary means** — that in the user's *own* project this is exactly where the chain writes
> the handoff by itself, so the next session starts with the plot intact; then **continue to the next
> tour step.** Do **not** invoke `/session-handoff`, do **not** write `.session.md`, and do **not**
> present a "continue the tour, or hand off now?" choice — there is one sensible answer mid-run, so a
> fork is friction, not service. **This holds in every drive mode, including autopilot and FSD.** The
> **only** handoff a tour performs is its own **staged Step-7 bookend** — the tour writes `.session.md`
> **exactly once**, there; anywhere else it *talks about* the boundary rather than acting on it.

**Where the guard lives (settled at plan time — 7m.1).** In the **tour arms**, not the general session
skills. Both arms gain a `### A clean boundary inside the tour is real — narrate it, don't offer it`
subsection under `## Category` (read early on every run) plus a write-once/authority blockquote at the
head of Step 7 (~40 lines *before* the scripted `/session-handoff`, so it is read before the action).
Rationale: it satisfies the WBS preference for keeping
tour-specific knowledge **out of** the general session skills at *zero* cost, and it makes
"general `S22`/`S23` unchanged for real work" true **by construction** — the general skills are not
edited at all, so there is no regression surface. Rejected: a "hosted inside a tutorial run"
precondition inside `session-reflect`/`session-handoff` (tour knowledge in two heavily-used general
skills + a real regression surface + needs an in-tour detection signal that does not exist), and an
on-disk in-tour marker the boundary chain consults (a new cross-skill artifact to solve what a prose
precondition in the arm solves).

**Explicitly NOT changed** (the WP7m escalation clause was checked and never fired): no new transition
ID, no new edge, no modeled table row, no edits to `transitions.md`, and no edits to the pause-policy
tables in the 4 `agents/*/AGENTS.md`. The `tutorial-*` family still emits **no** transition. Both
empty-diff facts are pinned as regression assertions.

**Fourth tour surface — no guard needed, verified not assumed.** `tutorial-product-cycle-tour` also
runs its own staged `/session-handoff`, but drives **only** `product-vision → roadmap → research →
arch → wbs` and reaches **zero** terminal closes (`grep -Ei 'finalize|task-close|session-reflect'` →
0 hits), so `session-reflect` never fires and `S22`/`S23` cannot trigger there. The asymmetry is
**load-bearing, not an oversight** — recorded here so it is not later re-opened as a scope-symmetry gap.

**Codified:** pins in `tests/check-structure.sh` **[Phase 18]** (placed in the existing `S22`/`S23`
exit-chain phase, since the guard is a precondition on that same chain), all **mutation-verified**;
suite 472 → **493 PASS**. Scoped to **copy-independent behavioral invariants only** — guard presence,
the named chain, the **narrate-not-suppress** verb, the both-take-and-offer prohibition,
all-four-drive-mode scoping, the write-`.session.md`-**once** rule, the designed-chain citation, and
**3 regression pins** asserting `session-reflect`/`session-handoff`/`session-capture` carry **zero**
tour knowledge. **One pin exists specifically to prevent regressing to the wrong framing**: it asserts
the guard affirms the boundary **is genuine**, so a future edit cannot restore the "NOT the session's
boundary" claim (mutation-verified — reverting the old heading + framing trips three pins).
Wording/ordering/sentence-count pins are deliberately left to **WP7e** against operator-**accepted**
copy (verify-human is DEFERRED here — pinning wording now would invert the pins-lock-accepted-copy
rule).

**⚠️ Acceptance owed.** Integration boundary applies (prose inside shipped, consumed skill prompts) →
F11-skip forbidden, Mode-3 auto-skip correctly did not fire. Operator deferred the read to a **full
hands-on tour run** ("defer. I'll just do a full tour again after changes are done"). WP7m being the
last of the three fixes, that single run now accepts **WP7l + WP7n + WP7m** together — and must also
answer the **still-open WP7l design question** (refuse-if-non-empty fires on every replay; the
passed-over `./onboarding-sample-todo/` subdir fallback is cheap now, expensive after WP7e pins).

---

## Revision 2026-07-25 (WP7l + WP7n — post-acceptance greenfield corrections)

From the operator's **batch hands-on acceptance walkthrough** (2026-07-25). Three of the four tour
surfaces passed as-shipped (brownfield · WP7g corrections · WP7k full-cycle); the **greenfield arm** drew
three fixes, ratified as WP7l / WP7m / WP7n. Two land here (WP7m is a separate follow-on WP).

**WP7l — the greenfield sample lands in the user's own cwd (§3-greenfield env, §8).** The arm previously
ran `new-sample.sh` bare, stamping into a `$TMPDIR` copy it then `cd`'d into; on the live run the operator
had to interrupt and ask *"Can you copy it over to the current directory?"*, and the accepted answer was
**flat into the cwd**. The arm now invokes `new-sample.sh --dest .`, so the files land where the user is
standing (`ls`-visible, no path to memorize) — this is what beat **A** ("your state is a real file you
own") actually depends on. **The cwd must be empty**; the scaffolder refuses a non-empty destination and
writes nothing, and the arm must **ask the user for an empty directory rather than passing `--force`** or
silently falling back to a temp dir. The dispatcher's Step-0 greenfield pre-flight is correspondingly
hardened from "an empty folder is ideal" to a stated **requirement** with its consequence, so the refusal
stays a rare backstop. **Replay note:** the guard fires on essentially every replay (the user stands in
their previous run's directory) — that is the normal case, handled by the arm's entry section and by the
`Next Step:` replay option telling the user to start from a new empty folder. *`new-sample.sh` itself was
NOT changed — it already implemented `--dest` + the no-clobber guard.*

**WP7n — the close ends with a terse `Next Step:` block (§3 both arms, §7 rows).** The operator's verdict
on the live close: the actionable choice *"got buried with this large body of corpus… at the very bottom
it should have a very clear and brief section saying `Next Step:` … each option no more than 3 sentences.
The details can be provided above it, not at the bottom."* Both arms' Step-8 closes are restructured:
narrative first (graduation/acknowledge → replay *motivation* in one line → "what we didn't demo" →
**artifacts-as-proof**), then a compact **per-branch `Next Step:` block as the last thing on screen**,
≤3 sentences per option, options **named never auto-run**. The full replay invitation is compressed into
option 1 — its load-bearing mechanics (direct arm re-entry NOT the dispatcher · session-boundary crossing ·
gear from the arm's own on-entry menu · greenfield's new-empty-folder / brownfield's clean-baseline-first)
are **compressed, not dropped**, and are restated in a mechanics note beneath each block. Branch B (replay)
carries no replay option. **WP7l's disposal ruling also lands here:** an **offer** to delete the throwaway
sample (never auto-remove, never silence), placed **after** the artifacts-as-proof list so the tour never
asks to remove the evidence before showing it — greenfield only, since brownfield runs on the user's real
repo and has nothing disposable.

**Deliberately NOT changed — the full product-cycle tour's close.** Verified per-file rather than assumed
symmetric: its close is already three explicitly-numbered beats in a stated order (~30 lines) with the
actionable "point at real work" beat in plain sight — no burial to fix. Adding a `Next Step:` block there
would be uniformity for its own sake and would rub against its ratified **no-replay / no-mode-menu**
invariant.

**Still owed:** the operator's **verify-human copy acceptance is DEFERRED** until WP7m also lands, so the
greenfield arm is judged once as a finished whole. **WP7e must freeze pins against that accepted copy, not
against this copy.** One open design question is recorded there too — whether "refuse if non-empty" should
soften to ask-with-subdir-fallback, given the guard fires on every replay.

---

## Revision 2026-07-23 (WP7j — session-chain flow correction; SUPERSEDES the dispatch-inline model)

State: `complete` → `in-progress` for this revision, then `complete`. The operator's specified tour
flow (origin session `fd4a9b17`, 2026-07-22) is a **chain of real session boundaries**, NOT a single
dispatched session. This **corrects a wrong architectural premise** that ran through this spec (§2,
§4, §5, §7) and the shipped skills: that `tutorial-getting-started` **dispatches the arm skill
inline**. It does not.

> **AUTHORITATIVE FLOW: [`../../docs/lessons/tutorial-tour-session-chain-flow.md`](../../docs/lessons/tutorial-tour-session-chain-flow.md).**
> That doc is the single source of truth for the tour flow — read it before editing any `tutorial-*`
> skill or this spec. Everywhere below that still describes "dispatches inline to the arm" is
> **SUPERSEDED** by it (inline pointers are left at those spots for provenance).

The corrected flow in one paragraph: **`tutorial-getting-started` (session A)** recommends `auto`
permission mode, asks the new-vs-existing fork, **`cd`s the user to the target working directory,
points them to the matching arm skill, and hands them off across a `/exit` → new session** — it does
**not** invoke the arm inline. The **arm skill is always entered directly** in its own fresh session.
The discriminator is **first-run vs. replay**, resolved by the arm **asking one line on entry**:
first run → **stepping**, and drive modes are **never mentioned** until the Step-8 graduation; replay
→ the arm **presents the 1–4 drive-mode menu itself** (drive mode is a numbered menu the workflow
shows, not a slash command — and since the replay bypasses `/session-start` and `/session-restore`,
the arm must present it). Greenfield: the **agent auto-stamps** the throwaway sample (the human never
runs the scaffolder). The full chain: getting-started → exit → new session (arm, stepping) →
walkthrough → handoff → exit → new session (restore → graduate → clean up) → exit → new session (arm,
autopilot/FSD) → whole thing again.

Sections corrected by this revision: **§2** (structure — point+exit, not dispatch-inline), **§4**
(Claudesk points at `/tutorial-getting-started`, which hands off across a session boundary), **§5**
(settled decisions), **§7** (dispositions — arm entry-question, mode-menu-on-replay, agent-stamp).
The superseded prose is left in place with inline `[SUPERSEDED 2026-07-23 → see flow doc]` pointers.

## Revision 2026-07-22 (WP7b co-design — structure + naming)

State: `complete` → back to `in-progress` for this revision, then `complete`. At the start of the
WP7b build, the operator refined the settled structure and naming. These changes **supersede** the
corresponding parts of §2, §4, §5a, and §3-brownfield below where they conflict; the superseded
prose is left in place for provenance with an inline pointer to this revision.

1. **Three-skill family, not one skill with an internal fork.** The single-entry `workflow-tour`
   skill is replaced by a **family of three `tutorial-`-prefixed skills**:
   - **`tutorial-getting-started`** — the entry/dispatcher. Recommends `auto` mode (revised from
     `acceptEdits` in WP7g — see §5b), presents the
     new-vs-existing fork (greenfield recommended-default / brownfield first-class peer), then
     **invokes the chosen arm skill inline** *[SUPERSEDED 2026-07-23 (WP7j) → getting-started
     `cd`s the user + points them to the arm skill + hands off across a `/exit`→new session; it does
     NOT invoke inline — see the flow doc named in the Revision 2026-07-23 note]*. This is the single
     command Claudesk points at.
   - **`tutorial-greenfield-workflow-tour`** — the greenfield narrated-real-run arm.
   - **`tutorial-brownfield-workflow-tour`** — the brownfield BYO-real-code arm.
   **Why:** three separate skill files enforce §2's "diverge and stay diverged (NOT
   branch-then-reconverge)" **structurally** instead of by prose discipline inside one file. The
   long arm names are deliberate (max explicitness for a cold reader scanning the skill list;
   these are rarely invoked, so length is acceptable).

2. **`tutorial-` prefix (reverses the §5a no-prefix decision AND its "no util-prefix pin"
   binding).** §5a settled `workflow-tour` with a deliberate no-`util-`-prefix divergence and a
   binding note telling WP7e **not** to pin a prefix check. This revision reverses both: all three
   skills carry the **`tutorial-` prefix**, which restores a self-documenting signal, and **WP7e
   SHALL pin a `tutorial-` prefix check** on the three skills. (The tour is a `tutorial-` *family*,
   its own concept — it is no longer described as a `util-*` skill for categorization purposes; it
   is still true that these skills own no workflow state and emit no transition. The category
   nuance is recorded in the AD-5 as-built resync.)

3. **Claudesk stable coupling command changes: `/workflow-tour` → `/tutorial-getting-started`**
   (updates §4a/§4c). The published-interface command name Claudesk points at is now
   `/tutorial-getting-started`; the two arm skills are internal (Claudesk never names them). WP8's
   M12 return contract communicates this name.

4. **Brownfield `/init` is OPTIONAL (refines §3-brownfield step 2).** Many real repos are already
   `/init`-ed. The brownfield arm **detects an existing `CLAUDE.md`** (or asks) and **skips `/init`
   when already initialized**, going straight to the product-workflow reverse-engineer. `/init`
   is run only when no project context exists yet. The headline aha is the reverse-engineering of
   the strategic layer, not `/init` itself — so making `/init` conditional strengthens, not
   weakens, the brownfield headline.

**Fuzzy-matcher collision re-check (WP5 discipline) for the new names:** `tutorial-getting-started`,
`tutorial-greenfield-workflow-tour`, `tutorial-brownfield-workflow-tour` — the `tutorial-` prefix
and the words `getting-started` / `greenfield` / `brownfield` / `workflow` / `tour` share **no**
ranking substring with the session-* family (`start`/`restore`/`resume`/`session`). Note
`getting-**started**` contains the substring `start` — acceptable because the full token is
`getting-started` (a distinct compound) and it ranks against `session-start` far more weakly than a
bare `start`; the entry skill's `description:` must still avoid the bare tokens `start`/`restore`/
`resume`/`session` per §5a to keep ranking clean.

Everything else in the spec (§3 flows, §6 honest-framing invariant, §7 "don't force it" staged set,
§8 build constraints except the retired no-util-prefix-pin line) is unchanged.

---

## 1. Audience & value prop (fixed)

A **plain Claude Code user, invited via Claudesk**, who has **never seen the workflow system**
and is **mildly skeptical** ("is this worth changing how I work?"). Critically: **already a
working developer with real projects** — they did not come to learn a toy; someone claimed this
makes their *actual* work better.

**The value prop onboarding sells is explicitly about real work:** *structure + durable state +
human-in-the-loop discipline makes your real software work less chaotic.*

Design consequence: the mostly-brownfield, real-developer audience **must not feel funneled
through a toy tutorial** — that is the skeptic-bounce this spec is engineered to defuse.

---

## 2. Settled structure (the shape every sub-WP binds to)

- **Single entry point:** the **`tutorial-getting-started`** skill (name updated by the 2026-07-22
  revision above — superseding the `workflow-tour` name; see §5a). It dispatches inline to one of
  two arm skills *[SUPERSEDED 2026-07-23 (WP7j) → it points the user to one of two arm skills, which
  they run **directly in a fresh session** after `/exit`; getting-started does NOT invoke the arm
  inline. See the Revision 2026-07-23 note + the authoritative flow doc]*. Claudesk renders the
  invite surface and points at this one command.
- **Two fully separate paths right after entry** — they **diverge and stay diverged** (NOT
  branch-then-reconverge):
  - **Greenfield** — starting something new / an empty dir.
  - **Brownfield** — an existing codebase.
- **Entry recommends GREENFIELD as the default for a true first-timer, with BROWNFIELD as a
  first-class peer.** A **default, not a funnel:** greenfield is the controlled path where every
  staged beat fires reliably (scaffold-hosted), so it's the high-fidelity first impression; but
  brownfield is offered as a **one-keystroke peer, NOT gated behind the tutorial** ("already have
  a project? point it there instead"). Consistent with the advisory / "you keep the wheel"
  framing (aha G).
- **The greenfield tour is a NARRATED REAL RUN, honestly labeled** — see §6 (the honest-framing
  invariant). It drives *real* skills with *real* reasoning; it is **not** a faked/scripted demo
  reel. Each beat is **pre-framed** so the user knows what they're watching and why.
- **The walkthrough opens (both paths) by recommending `auto` mode (if available)** with a one-line
  "why it's safe" — see §5b (revised 2026-07-22). Universal, at the start, regardless of path.
- **The first run stays in stepping** so the human-pause beat (B) is **visible** —
  drive modes are revealed only at the very end as a graduation (see §3 beat 7, §6).

---

## 3. The two per-path flows (AC-1)

Both paths do **one small real unit of work end-to-end**. Most ahas are **beats along that one
thread** of real work — not separate scenes (the "organic weave"). The two paths share a spine
shape but never reconverge.

### Legend for the beat annotations
Beats are keyed to the disposition table in §7 (`A`, `B`, `C`, `G`, `Grounding`, `Handoff/Restore`,
`Drive-modes`, `Hierarchy`, `Reflect/Capture`). The **disposition tokens** used in the "Staged?"
column and throughout the flow tables below (**STAGED** / **BEAT** / **FRAME** / **NAMED** / **CUT**)
are defined in **§7** — see the §7 legend for what each means.

### Greenfield flow — "structure on a blank page"

**Pain removed:** *"I have an idea but I always devolve into unstructured vibe-coding and lose the
plot."*

**Environment:** one tiny **shipped, RUNNABLE greenfield scaffold** (WP7c) — empty-ish, low cost,
nothing real to lose. This is the single place SURFACE (C) and verify-self grounding are
**guaranteed staged** beats (the scaffold plants an authentic small mess + has ≥1 observable
outcome to check).

| # | Step | Beats fired | Staged? |
|---|------|-------------|---------|
| 1 | **Entry** → recommend `auto` mode, if available (universal; see §5b) → pick path → framing line ("you keep the wheel") | **G** (FRAME) | framing |
| 2 | **Enter top-of-hierarchy:** fuzzy idea → `/product-vision` → roadmap → … (or `/session-start` classifying a smaller new feature). Light **product→feature lifecycle taste** lands here (greenfield-only). | **Hierarchy** (light taste), **Grounding**: probe-first/plan-around-real-shapes named as it occurs — *this probe-first surface is a natural **BEAT/NAMED**, NOT staged; only the verify-self surface at step 5 is the **STAGED** grounding beat (§7)* | taste |
| 3 | **Do one small real thing** → plan becomes a **Work Tree** → open the state file: **A — it's a file you can open, and it's yours** (~free; the WIP already exists after any step). | **A** (BEAT) | natural |
| 4 | **Hit a verify gate** → **B — it pauses and asks** (verify-human / plan review). The trust beat. Onboarding stays in stepping so this is visible; reinforce G here ("it paused to ask — and even here you can redirect"). | **B** (BEAT), **G** reinforce | natural (kept visible) |
| 5 | **Grounding (STAGED):** agent runs the runnable scaffold, **observes** it via `verify-self`, reports **PASS/FAIL** vs an observable outcome — the user watches it **CHECK reality** instead of guessing. Pre-framed ("watch — it's about to actually run it and check the output; this is the grounding moment"). | **Grounding** (STAGED — verify-self) | **STAGED** |
| 6 | **SURFACE (STAGED):** agent hits the planted authentic tangent → runs SURFACE → logs to backlog → continues without losing the plot. **C** = the rabbit-hole caught; backlog is C's flip side (folded in, not a separate aha). | **C** (STAGED greenfield), backlog folded into C | **STAGED** |
| 7 | **Bookend 1 — the boundary (STAGED):** `/session-handoff` → "leave" → `/session-restore` → full context survives. **REVISED 2026-07-27 (WP7m):** this staged bookend is the **only** handoff the tour performs, and the arm now says so explicitly — a later clean boundary in the chain (`feature-finalize` → `session-reflect`, typically in Session C) must **not** take or offer the `S22`/`S23` exit chain in any drive mode; it runs reflect and continues to the next tour step. A blockquote at the head of Step 7 draws the staged-vs-real boundary distinction so the guard cannot over-fire onto this beat. The **emotional peak**; placed near the end so there's real state to lose-and-recover. | **Handoff/Restore** (STAGED bookend) | **STAGED** |
| 8 | **Bookend 2 — the graduation (STAGED, LAST):** reveal drive modes (autopilot/FSD) — deliberately last, deliberately **un-pushed** ("autopilot chains safe steps; FSD skips even verify-human — here's when appropriate. Not recommended yet"). Then a **replay invitation** (WP7j): invite the user to re-run this same tour in autopilot/FSD by **crossing a fresh session boundary** (`/exit` → new session) and **re-entering at the arm skill directly** — `/tutorial-greenfield-workflow-tour`, NOT the dispatcher (the dispatcher would re-force stepping + re-ask the path fork, both of which the faster-gear replay moves past). **Greenfield: the arm stamps a fresh `new-sample.sh` copy automatically** (the agent runs it, not the human; nothing carries over). A *named* invite, not a live demo (a live autopilot run would hide beat B). **REVISED 2026-07-25 (WP7n) — the close is now narrative-first, decision-last:** the replay invitation is compressed to a one-line *motivation* here, and its mechanics move into the terse `Next Step:` block; the close order is graduation-reveal → replay-motivation → **Close:** point at what we did NOT demo (full **Hierarchy** + **Reflect/Capture-learns-you**) → **artifacts-as-proof** (the real files this run produced) → **`Next Step:` block LAST** (per-branch, ≤3 sentences/option, options named-never-auto-run; Branch A = replay / own-code / deep-dive, Branch B = no replay option). **WP7l:** the greenfield block's cleanup **offer** (delete the throwaway sample — offer, never auto-remove) is the block's last line, deliberately *after* the artifacts-as-proof so the tour never asks to remove the evidence before showing it. | **Drive-modes** (STAGED reveal, LAST), **Replay-invite** (NAMED, compressed into `Next Step:` opt 1), **Hierarchy**/**Reflect** (NAMED at close), **`Next Step:` decision block** (LAST), **cleanup offer** (greenfield only) | **STAGED** reveal + NAMED close |

### Brownfield flow — "it read MY real code and reconstructed what I never wrote down"

**Pain removed:** *"I'm deep in a real codebase and Claude keeps drifting / forgetting context /
half-finishing things across sessions."*

**Environment:** **bring-your-own real code — NO demo.** This path's headline aha is *strongest on
the user's real repo* and *weakest on a seed* — a brownfield demo would reduce it to a parlor
trick and actively weaken the strongest brownfield moment. At the vision/arch stage the work is
read-heavy + additive (low blast radius), so BYO + `auto` mode (classifier-gated) is acceptable.

| # | Step | Beats fired | Staged? |
|---|------|-------------|---------|
| 0 | **Where-to-run pre-flight** (dispatcher Step 0, brownfield branch): `cd` into the real repo root, THEN a **git-safety pre-flight** (WP7j) before crossing the session boundary — the tour makes real edits. *If git repo:* `git status --short`; uncommitted changes → recommend commit-first (or `git stash`, or a safe copy / a different less-precious project) + warn; clean → note `git diff`/`git stash` are the undo path. *If not a git repo:* recommend `git init` + one commit so there's an undo path. (Greenfield needs none — it works in a disposable throwaway copy.) This is what makes the Step-8 replay's "`git stash` back to clean baseline" safe. | (pre-flight) | — |
| 1 | **Entry** → recommend `auto` mode, if available (universal; see §5b) → pick path → framing line (G). | **G** (FRAME) | framing |
| 2 | **`/init` first** → generates a first-cut `CLAUDE.md` from the existing code. | (setup) | — |
| 3 | **Product workflow reverse-engineers** vision / roadmap / arch from the existing code. **The headline aha:** *"it read my actual code and reconstructed the strategic layer I never wrote down."* This IS the brownfield grounding beat (reconstructs strategy from real code). | **Grounding** (brownfield headline — `/init`→reverse-engineer) | natural (the headline) |
| 4 | **`product-context` revises** the `CLAUDE.md` that `/init` generated → durable project context now reflects the reconstructed strategy. Open the file: **A — state is a file you can open** lands here. | **A** (BEAT) | natural |
| 5 | **Do one small real unit of work** on the real repo → plan → Work Tree → **hit a verify gate → B** (it pauses and asks). Trust beat, kept visible (stepping). Reinforce G. | **B** (BEAT), **G** reinforce | natural (kept visible) |
| 6 | **Grounding + SURFACE = NAMED/opportunistic here** (not staged): probe-first and verify-self **fire naturally** if the real work touches an integration or a runnable surface; SURFACE is pointed-at when a tangent occurs ("when you hit a tangent, here's what SURFACE does"). | **Grounding** (NAMED), **C** (NAMED) | NAMED / opportunistic |
| 7 | **Bookend 1 — the boundary (STAGED):** `/session-handoff` → "leave" → `/session-restore` → context survives on the real repo. Emotional peak. **REVISED 2026-07-27 (WP7m):** same guard as greenfield, mirrored here — this staged bookend is the **only** handoff the tour performs; a later clean boundary must **not** be taken or offered — it is **narrated** (say what a real project would do), then the tour continues, and a staged-vs-real blockquote at the head of Step 7 keeps the guard from over-firing onto this beat. | **Handoff/Restore** (STAGED bookend) | **STAGED** |
| 8 | **Bookend 2 — the graduation (STAGED, LAST):** reveal drive modes, un-pushed. Then a **replay invitation** (WP7j): invite the user to re-run this same tour in autopilot/FSD — **brownfield: `git stash`/restore back to the clean baseline first, then cross a fresh session boundary** (`/exit` → new session in the same repo) and **re-enter at the arm skill directly** — `/tutorial-brownfield-workflow-tour`, NOT the dispatcher (same reason as greenfield: the dispatcher re-forces stepping + re-asks the fork). Undoing the tour's real-repo edits first is why the Step-0 git-safety pre-flight matters. A *named* invite, not a live demo. **REVISED 2026-07-25 (WP7n) — narrative-first, decision-last (same shape as greenfield):** the replay invitation is compressed to a one-line *motivation* here and its mechanics (clean-baseline-first included) move into the terse `Next Step:` block; order is graduation-reveal → replay-motivation → **Close:** point at what we did NOT demo (**Hierarchy** CUT on brownfield — too big to feel in run one — + **Reflect/Capture-learns-you**) → **artifacts-as-proof** (the real files this run touched on their repo) → **`Next Step:` block LAST** (Branch A = replay-from-clean-baseline / just-start-working via `/session-start`; Branch B = one option, no replay). **Deliberate brownfield asymmetries, stated as prohibitions:** NO cleanup offer (real repo, nothing disposable — `git stash`/`restore` is the user's own undo path) and NO deep-dive pointer (`/tutorial-product-cycle-tour` is pointed at from the *greenfield* close, pairing with its hierarchy taste). | **Drive-modes** (STAGED reveal, LAST), **Replay-invite** (NAMED, compressed into `Next Step:` opt 1), **Hierarchy** (CUT/named), **Reflect** (NAMED at close), **`Next Step:` decision block** (LAST) | **STAGED** reveal + NAMED close |

**Why the paths never reconverge:** the two headline ahas are different (greenfield = structure on
a blank page; brownfield = discipline + reconstruction on real code), the environments are
different (shipped scaffold vs. BYO real repo), and the staged-beat sets differ (see §7). Merging
them would dilute both headlines.

---

## 4. Claudesk Surface Contract (AC-3 — the M12 return-contract form)

> This section is the artifact **WP8** hands back to Claudesk (`/Users/stayman/Personal/projects/claudesk`)
> as part of the M12 return contract. It defines the interface between Claudesk (which *renders*
> the invite) and this repo (which *owns* the flow + content). Claudesk builds its M11/M10.9
> against **this contract**, not against the flow internals.

### 4a. What Claudesk renders
- A **one-time evangelistic invite surface** for the workflow system, shown to a user who has
  opted in (gated behind Claudesk's own opt-in per its M10.9).
- **A pointer to the single entry command: `/tutorial-getting-started`.** (Command name updated by
  the 2026-07-22 revision — was `/workflow-tour`.) That's the whole coupling — Claudesk points the
  user at one slash command; everything after that is owned by this repo's skill family (the entry
  skill points the user to the greenfield or brownfield arm, which they run directly in a fresh session
  *[SUPERSEDED 2026-07-23 (WP7j) — was "dispatches inline to the greenfield or brownfield arm";
  corrected to the session-chain flow. Claudesk's coupling is unchanged: it still points at the one
  `/tutorial-getting-started` command. See the Revision 2026-07-23 note + flow doc]*).

### 4b. When Claudesk points at the entry command
- **Once, as a one-time invite** — not a persistent nag. After the user has run (or explicitly
  dismissed) `/tutorial-getting-started`, Claudesk does not re-surface the invite.
- The invite fires **only when Claudesk's workflow-coupled UI opt-in is active** (Claudesk gates
  all workflow-coupled behavior behind an opt-in with a one-time evangelistic invite — that is what
  made these skill-system-owned items load-bearing; see the Claudesk handoff).

### 4c. What Claudesk must NOT hardcode (the anti-brittleness clause)
- **Must NOT** hardcode the tour's **flow, steps, beats, or copy** — those live in this repo's
  `tutorial-*` skill family and evolve independently. Claudesk renders an invite and a command
  pointer, nothing more.
- **Must NOT** hardcode the **greenfield/brownfield path choice** — the path fork happens *inside*
  `tutorial-getting-started`, after entry (it dispatches to the arm skill). Claudesk does not
  pre-select a path.
- **Must NOT** hardcode the **permission-mode instruction** — permission-mode guidance (`auto`; see
  §5b) is delivered by the skill (§5), not by Claudesk's invite copy, so a future mode-guidance change
  is a one-repo edit. (Proven by the WP7g `acceptEdits`→`auto` change: it landed entirely in this repo,
  no Claudesk change needed.)
- **The ONLY stable coupling Claudesk may depend on is the command name `/tutorial-getting-started`.**
  (Updated 2026-07-22 — was `/workflow-tour`; WP8's M12 return contract communicates this name.) If
  that name ever changes, it is a return-contract change communicated back through the same channel — so
  the name is treated as a published interface (this is why §5 pins it and WP7e guards it).

### 4d. Return-contract delivery note (for WP8)
WP8 delivers §4a–§4c to Claudesk either as a reciprocal handoff doc or a backlog SURFACE in the
Claudesk repo, bundled with the other two M12 deliverables (install/uninstall command copy from
WP4.5; the settled `workflow-system/product/*` + `workflow-system/state/*` doc layout + the required
`docs_list` glob change from M7 WP3-M7).

**Self-contained-on-install (WP7j Phase 6).** The greenfield tour's runnable sample + scaffolder ship
**inside the greenfield arm skill's own directory** (`skills/tutorial-greenfield-workflow-tour/scripts/`),
NOT under repo-root `tools/`. This is load-bearing for the Claudesk-invited install: `install.sh`
symlinks each skill's *whole directory* into `~/.claude/skills/` but does **not** symlink repo-root
`tools/` — so a user who installs the skills gets the greenfield sample automatically (it rides the
skill's whole-dir symlink), with no separate step and no `install.sh` change. WP8 must state this to
Claudesk: the onboarding tour is self-contained in the skill install; there is no extra sample-fetch
step to document.

---

## 5. Settled decisions (7a.3 name/category · 7a.4 permission mode)

### 5a. Entry-skill name + category (7a.3) — SETTLED (operator 2026-07-22)

> **⚠️ SUPERSEDED by the 2026-07-22 WP7b-co-design revision at the top of this doc.** The name is
> now a three-skill `tutorial-`-prefixed family (`tutorial-getting-started` entry +
> `tutorial-greenfield-workflow-tour` / `tutorial-brownfield-workflow-tour` arms), the `tutorial-`
> prefix is pinned by WP7e, and it is no longer categorized as `util-*`. The text below is retained
> for provenance; read the revision block for the current decision.

**Name: `workflow-tour`. Category: `util-*`** — a standalone user-invoked entry point that owns no
workflow state and emits **no transition** (the `util-*` contract: no F/I/T/P/S token, no
`DEBUG-*` token, no `RETURN-TO:`, minimal `name`/`description`/`argument-hint` frontmatter, an
entry point itself). It drives other skills inline (a `session-start`-like experience) but is
itself the entry point, not a workflow state or a pulled sidebar.

**No drive-mode menu at entry.** The mode-menu-encouraged util-* precedent (`util-prune-claude-md`)
does **not** apply here: the tour deliberately runs in **stepping** so beat B (the
human pause) is visible. Exposing a drive-mode menu at entry would invite the user to autopilot
past the very beat the tour is built to show.

**Deliberate divergence from the `util-` file-prefix convention (operator-accepted).** Existing
file-based util-* skills carry the `util-` name prefix (`util-prune-claude-md`,
`util-backlog-paydown`); `workflow-tour` is a `util-*`-category skill that does **not** carry that
prefix. This is intentional — the evocative, self-explaining name was preferred over the prefix's
self-documenting no-transition signal, analogous to the harness-builtin util-* utilities (`init`,
`review`, …) that are util-* by concept but keep their own names.
> **Binding note for WP7e:** do **NOT** add a `util-`-prefix structural pin that would flag
> `workflow-tour`. The util-* category is doc-enforced (arch.md → `util-*` skill category), not
> prefix-pinned. This divergence must be recorded in the AD-5 as-built arch resync so a future
> grep-audit reads it as intentional, not drift.

**Fuzzy-matcher-collision check (WP5 discipline — the harness matcher ranks on `name` AND
`description`):**
- `workflow-tour` / `tour` shares **no** ranking substring with `session-start`,
  `session-restore`, `session-handoff`, `session-capture`, `session-reflect`, `product-*`,
  `feature-*`, `task-*`, `incident-*`, or the `util-*` names. No collision.
- The **`description:` must avoid** the tokens `start`, `restore`, `resume`, `session` (they rank
  toward the session-* family the WP5/M9 audit just disambiguated).
- **Draft `description:`** — *"First-run guided tour of the workflow system for a brand-new user:
  pick greenfield (new project) or brownfield (your existing code) and walk one small real unit of
  work end-to-end. A narrated real run (~10–15 min), not a demo reel."* (Contains none of the
  forbidden ranking tokens.)

**Alternatives considered:** `util-onboard` (viable — carries the `util-` prefix's self-documenting
signal — but the operator preferred the more evocative `workflow-tour`); `session-onboard`
(**rejected** — the `session-` prefix invites the exact fuzzy collision with the session-* family
that WP5 spent a milestone disambiguating, and onboarding is NOT a session meta-op).

### 5b. Permission-mode recommendation + reassurance copy (7a.4) — REVISED (operator 2026-07-22, WP7g)

> **⚠️ REVISED by the operator's live-walkthrough ruling (WP7g, 2026-07-22): recommend `auto`, NOT
> `acceptEdits`.** The `acceptEdits` recommendation below was a prior-session inference the operator
> **never endorsed**; during the hands-on tour run the operator flagged that `acceptEdits` "doesn't
> give enough permission" — it still prompts on every shell command, so the tour (which really *runs*
> the sample, hands off, restores) gets a prompt on nearly every beat, drowning the moments the tour
> exists to show. **Current decision: recommend `auto`.** The superseded `acceptEdits` text is
> retained below the revision for provenance.

**Recommend `auto` mode (if available) — NOT `acceptEdits`, NOT `bypassPermissions`.** Confirmed
against the official docs (https://code.claude.com/docs/en/permission-modes.md):

| Mode | File edits | Safe fs cmds | Arbitrary shell / network | Guardrails |
|---|---|---|---|---|
| `acceptEdits` | auto | auto | **still prompts** (gated) | — (prompts do the gating) |
| **`auto`** | auto | auto | **auto** | **classifier reviews each action**, blocks escalations (curl\|bash, force-push, prod deploy, mass delete, secret exfil, destructive resets) |
| `bypassPermissions` | auto | auto | auto | **none** (only `rm -rf /`\|`~` circuit-breaker) |

`auto` is the right fit for a guided tour: it removes the **routine**-prompt friction on shell/network
(which `acceptEdits` does NOT — that mode prompts on every `greet.sh` etc.) **while a classifier keeps
the "stays safe/local" reassurance honestly true** (unlike `bypassPermissions`, which has no
guardrails at all and trains the wrong mental model). **Availability caveat — MUST be in the copy:**
`auto` requires a recent model (Opus 4.6+/Sonnet 4.6+/Fable 5) and an account/provider that allows it;
if unavailable, the user takes the tour in whatever mode they have (it just prompts more often) — do
**not** fall back to `bypassPermissions`. **Launch:** `claude --permission-mode auto` (or
`defaultMode:"auto"` in `~/.claude/settings.json`, ignored from project settings; or Shift+Tab if
`auto` is in the cycle).

**Reassurance one-liner (universal open, both paths):**
> *"First, let's put Claude Code in **auto** mode so the tour can actually run — execute the sample,
> write files, hand off and restore — without stopping to ask you on every single step. Auto mode
> isn't a free-for-all: a safety classifier still checks each action and blocks anything genuinely
> dangerous (nothing gets force-pushed, deployed, or deleted out from under you). It's safe here —
> all work stays inside this one project directory — and you keep the wheel: the workflow itself
> still pauses to ask you at the decisions that matter."*

The copy ties reassurance to (a) the **accurate** `auto` behavior (routine actions auto; a classifier
blocks the dangerous ones), (b) blast-radius containment (one dir), and (c) the **G** advisory-framing
beat ("you keep the wheel") — so it reinforces the human-in-the-loop trust story rather than
undercutting it. The availability caveat keeps the copy honest for users on older models.

<details><summary>Superseded (2026-07-22): the earlier <code>acceptEdits</code> recommendation</summary>

**Recommend `acceptEdits` mode — NOT `bypassPermissions`.** [Superseded — the operator never
endorsed this and the live run rejected it for prompting on every shell command. `acceptEdits` auto-
accepts file edits + safe fs cmds but **still prompts for arbitrary shell/network**, so the blast-
radius claim was honestly true but the friction was too high for a tour that really runs things.
Retained for provenance only; the current decision is `auto` above.]

</details>

---

## 6. The honest-framing invariant (AC-6 — load-bearing, binds WP7b & WP7e)

**The greenfield tour is a NARRATED REAL RUN.** It drives real skills with real reasoning and real
token spend — **NOT** a faked/scripted demo reel.

- **Why it must be real:** the headline ahas (grounding / verify-self / SURFACE) lose all value if
  canned. Faking "it actually went and looked" is lying about the one thing the skeptic cares most
  about; a user who later realizes it was faked trusts the system **less**. Canning the
  grounding/verify-self/SURFACE beats would defeat the exact ahas that convert the skeptic.
- **Honest time label — REQUIRED.** Label it *"a guided ~10–15 min run on a sample — real, so you
  watch it actually work."* Cheap beats (A/open-the-file, G/framing) are near-instant; the
  real-time investment is in the beats that MUST be authentic.
- **FORBIDDEN:** any **"quick / 5-minute"** claim. That is false advertising for a real agent run.
  **WP7b** must not write a "5-min" claim into the skill; **WP7e** should pin the absence of a
  "5 min"/"5-minute" claim and the presence of the honest ~10–15 min framing.
- **Per-beat pre-framing:** each staged beat is introduced so the user knows what they're watching
  and why (keeps a real run from feeling like dead time). Detailed per-beat narration copy is a
  **WP7d** concern (where the beats are wired); WP7a fixes the framing *rules*, WP7d writes the
  scene-by-scene copy.

---

## 7. Aha-moment dispositions + the "don't force it" rule (AC-2, AC-7)

**Legend:** **STAGED** = guaranteed engineered beat · **BEAT** = occurs naturally along the work
thread, ensure we don't skip it · **FRAME** = one-line framing, not a scene · **NAMED** =
mention/point-at, never staged · **CUT** = out of first run.

| Aha | Disposition | Notes |
|-----|-------------|-------|
| **Structured approach (the two paths)** | STAGED (both paths) | The core family; greenfield = structure-on-blank, brownfield = discipline-on-real. |
| **A — State is a file you can open** | BEAT (both) | Foundational (Core Principle #1); nearly free — the WIP/state file already exists after any step. Makes handoff/restore believable. |
| **B — Human-in-the-loop pause** (verify-human / plan review) | BEAT (both) | The trust beat + honest counterweight to drive-modes. **Keep onboarding in stepping so this is VISIBLE** (don't autopilot past it — would be ironic). |
| **C — SURFACE (rabbit-hole caught)** | STAGED greenfield-only; NAMED brownfield | Authentic staging needs controlled code → the greenfield scaffold. Brownfield keeps it real → C reverts to named/opportunistic there. |
| **G — Advisory / you keep the wheel** | FRAME (both) | Anxiety-reducer for the skeptical invitee. One line in entry + reinforced at the pause. |
| **Grounding — the workflow checks reality instead of guessing** | STAGED greenfield (verify-self); NAMED brownfield | **Epistemic-honesty aha.** Three surfaces: probe-first roadmap/WBS (plan around *documented* real API shapes); **verify-self** (agent *observes the running system* before claiming done); brownfield `/init`→reverse-engineer (reconstructs strategy from *real code*). For a skeptic burned by agents declaring broken code "done," *"it actually went and looked"* may be the strongest trust beat. **Greenfield:** stage a verify-self beat ⇒ **the scaffold MUST be runnable** (WP7c constraint). **Brownfield:** probe-first + verify-self named/opportunistic; `/init`→reverse-engineer carries the grounding headline. |
| **Session handoff → restore** (context survival) | STAGED bookend (both) | The **emotional peak.** Near the end so there's real state to lose-and-recover. `/session-handoff` → "leave" → `/session-restore`. |
| **Arm entry-question — first-run vs. replay** (WP7j) | MECHANIC (both arms, on entry) | Because the arm is **always entered directly** (never dispatched inline), it must establish which run this is BEFORE driving a beat, by **asking one line on entry** ("first time through, or replaying to try a faster gear?"). **First run →** silently drive **stepping**, and do NOT mention drive modes exist until the Step-8 graduation (naming faster gears early spoils beat B). **Replay →** the arm **presents the 1–4 drive-mode menu itself** (Stepping/Orchestrated/Autopilot/FSD; default Autopilot) — drive mode is a *numbered menu the workflow shows, not a slash command*, and since the replay bypasses `/session-start` + `/session-restore` (the two canonical menu points), the arm is the one that must show it — then runs the tour in the chosen gear. Greenfield: the **agent auto-stamps** the fresh sample on both runs (human never runs `new-sample.sh`). |
| **Drive modes / autopilot / FSD** | STAGED graduation reveal, **LAST** | **NOT the first-run recommendation.** First walkthrough runs stepping so pauses are visible → THEN reveal modes, deliberately un-pushed ("not recommended yet"). Showing autopilot first would hide beat B. **Mode-switch mechanic (WP7j):** the graduation reveals modes *exist*; the user *acts* on that by replaying and picking a gear from the arm's on-entry menu (see the Arm entry-question row) — so "how do I switch modes" is answered concretely, not left abstract. **The Step-8 graduation is MODE-AWARE (WP7j Phase 5) — two mutually-exclusive branches:** **Branch A (first run / stepping)** = reveal the faster gears + un-push + replay invite (as above); **Branch B (replay / already in a faster gear)** = do NOT re-reveal or re-invite (the user knows and is already replaying) — instead *acknowledge the gear they just felt* ("same tour, this time in autopilot — notice it chained the routine steps and kept only the verify stop; FSD skips even that"), then close. Both branches converge on the "what we did NOT demo" close. This replaced an interim first-run-only guard so the graduation is never factually wrong on a replay. |
| **Replay invitation — re-run the tour in a faster gear** (WP7j) | NAMED at close (both) | The honest companion to the drive-modes reveal: don't demo autopilot *live* (that hides beat B) — instead invite the user to *feel* it by re-running the same tour in autopilot/FSD. **The replay is itself a session-boundary crossing** (`/exit` → new session, echoing the handoff→restore beat the tour just taught) that **re-enters at the arm skill directly** (`/tutorial-greenfield-workflow-tour` / `/tutorial-brownfield-workflow-tour`), NOT the dispatcher — the dispatcher re-forces stepping + re-asks the path fork, which a faster-gear replay is moving past. **The gear is chosen from the arm's OWN on-entry menu** (WP7j Phase 2): the replay invite does NOT tell the user to pre-set a mode or to "skip the intro and keep going" — there is no dispatcher in the replay session; the invite says "run the arm skill directly; it'll ask if you're replaying and then show you the 1–4 gear menu." **Greenfield:** the arm stamps a fresh `new-sample.sh` copy automatically (the *agent* runs it, never the human; nothing carries over). **Brownfield:** the user `git stash`/restores to the clean baseline first (undo the tour's real-repo edits), which is why the Step-0 git-safety pre-flight is load-bearing. A *named* invite the user drives themselves — never a staged autopilot run. **REVISED 2026-07-25 (WP7n) — the invitation is now SPLIT:** a one-line *motivation* stays in the close narrative ("if you want to feel the difference…", plus an explicit "I'll put the how at the end" promise), and the *actionable* form with all its mechanics becomes **option 1 of the terse `Next Step:` block** that ends the close. Every mechanic above is **compressed, not dropped**, and is restated in a "Mechanics that must stay correct in the block" note beneath each block — plus, from WP7l, **greenfield's replay must start from a NEW empty folder** (the scaffolder refuses a non-empty cwd, so without this every replay trips the guard). Branch B (already replaying) carries **no replay option at all**. |
| **Hierarchy (product→feature→task) as one record** | Greenfield: light taste; Brownfield: CUT | Too big to *feel* in run one; greenfield users are already at the top so a light taste lands there. Named otherwise. |
| **Reflect / capture — system learns you** | NAMED at close (both) | Delayed-gratification (value shows next session). Great closing note; wrong as a staged beat. |
| **Backlog as durable idea-catcher** | FOLD into C | Flip side of SURFACE, not a separate aha. |

### The "don't force it" rule (the invariant WP7b/WP7c/WP7d/WP7e must honor)

Only these beats are **GUARANTEED STAGED**, because only these can be staged **authentically**:
1. **A** — state-is-a-file (both paths; ~free)
2. **B** — human-in-the-loop pause (both paths; kept visible by staying stepping)
3. **Greenfield-grounding** — verify-self on the runnable scaffold (greenfield only)
4. **Greenfield-SURFACE** — the planted authentic tangent (greenfield only)
5. **Handoff → restore** — the emotional-peak bookend (both paths)
6. **Drive-modes reveal** — the graduation, LAST + un-pushed (both paths)

Everything else is **NAMED or opportunistic only, NEVER staged:** C-brownfield,
grounding-brownfield (except the `/init`→reverse-engineer headline, which is natural not staged),
hierarchy-brownfield, and reflect/capture (both paths). Staging any of these would make the run
feel fake — which for this skeptical audience costs *more* trust than the aha earns.

---

## 8. Constraints carried into the build sub-WPs (WP7b–WP7e)

- **No-runtime repo convention** — prompt/markdown/skill/scenario/pin edits only.
- **`workflow-tour` emits NO transition** → **no `transitions.md` change**, no new F/I/T/P/S ID.
  (The state machine stays as-is; this is a `util-*` entry point.)
- **Path-qualification mandate** — every `.claude/` reference in the skill prose is explicitly
  `~/.claude/` or `<proj-dir>/.claude/`, never bare.
- **install.sh is additive-only** (`SURFACE-2026-07-21-INSTALL-SH-NO-ORPHAN-PRUNE`) — WP7b creates
  a new skill dir, so re-run `install.sh` after (and heed the orphan-prune caveat).
- **WP7c runnable-scaffold constraint** — the greenfield scaffold MUST be runnable with ≥1
  observable outcome, so the staged verify-self grounding beat (§3 greenfield step 5) has something
  real to check. It must also contain a **planted, authentic-feeling tangent** so the staged
  SURFACE beat (§3 greenfield step 6) fires reliably without feeling fake. Keep it minimal so it
  doesn't rot (it rides path/skill/layout changes — cf. M7 moved every folder).
- **Scaffold-in-skill, not repo-root (WP7j Phase 6)** — the greenfield scaffold ships **inside the
  greenfield arm skill dir** (`skills/tutorial-greenfield-workflow-tour/scripts/`), NOT under repo-root
  `tools/`. `install.sh` symlinks whole skill dirs but not `tools/`, so scaffold-in-skill is what makes
  the tour self-contained on a Claudesk-invited install (see §4d). The scaffolder + its smoke test
  resolve their own sibling `sample/` from `$0`'s dir, so they work from the repo checkout or a
  `~/.claude/` symlink. **No `install.sh` change was needed** (whole-dir symlink already carries
  `scripts/`). The agent (not the human) runs the scaffolder on both first-run and replay.
- ~~**WP7e must NOT pin a `util-`-prefix check** against `workflow-tour` (§5a divergence).~~
  **RETIRED by the 2026-07-22 revision:** WP7e SHALL pin a **`tutorial-`-prefix check** on the
  three `tutorial-` family skills (the prefix is now the self-documenting signal).

---

## 9. Cross-links & sub-WP handoff (feeds WP7b–WP7e + WP8; notes for finalize)

- **WP7b** (entry skill) builds against **§3** (per-path flow), **§5** (fixed name/category + copy),
  **§6** (honest-framing invariant), **§7** ("don't force it" staged set).
- **WP7c** (scaffold) builds against **§3 greenfield steps 5–6** + **§8** (runnable + planted
  tangent constraints).
- **WP7d** (beats-wiring) builds against **§3** (bookend + graduation choreography) + **§6**
  (per-beat pre-framing copy) + **§7** (which beats are staged).
- **WP7e** (scenarios + pins) codifies **§5a** (name; **no util-prefix pin**), **§6** (no "5-min"
  claim + honest framing present), **§7** ("don't force it" staged-vs-named invariants), and the
  path-fork.
- **WP8** (M12 return contract) delivers **§4** (Claudesk Surface Contract) bundled with the WP4.5
  install/uninstall copy + the M7 doc-layout + `docs_list` change.
- **AD-5 as-built resync (for `/product-context` / finalize):** onboarding shipped as a dedicated
  `util-*` skill (`workflow-tour`) + a runnable greenfield scaffold, **no new runtime, no
  transition, no architectural surface** — lands inside AD-5's envelope (deferred → designed →
  built). Record the **`util-`-prefix divergence** (§5a) here so it reads as intentional, not drift.
