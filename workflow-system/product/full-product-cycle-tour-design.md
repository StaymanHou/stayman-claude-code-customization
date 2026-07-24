---
shape: tour-design
stage: design
milestone: 11
wp: WP7h
state: complete
updated: 2026-07-24
---

# Full product-cycle "full experience" tour — DESIGN (WP7h)

> **What this is.** The settled design for the **full product-cycle tour** — a fourth `tutorial-*`
> skill that walks a brand-new user through the *whole* product lifecycle (vision → roadmap →
> research → arch → wbs), so they *feel* the workflow carry an entire **initiative**, not just one
> unit of work. This is the heavier counterpart the light-taste greenfield arm deliberately points
> at (FB-2).
>
> **Status: DESIGN-ONLY.** This session settled the design (operator co-design, 2026-07-24). The
> **build is deferred** to its own WBS work-package (**WP7k**, added to `wbs.md`) so it lands *after*
> the operator's batch hands-on acceptance run — all four tour surfaces get accepted together before
> WP7e freezes pins.
>
> **Who reads it.** The build-WP (WP7k) builds against this. It extends
> [`onboarding-flow-spec.md`](onboarding-flow-spec.md) — same family, same invariants (honest-framing
> §6, "don't force it" §7, path-qualification, no-runtime, no-transition). Read the
> [session-chain flow doc](../../docs/lessons/tutorial-tour-session-chain-flow.md) and
> `onboarding-flow-spec.md` first; this doc only records what is *different* about the full-cycle tour.
>
> **Origin:** FB-2 (operator's live walkthrough, `tmp/wp7e-tour-walkthrough-feedback.md` lines 44–65):
> *"We will then need a pointer note and a corresponding 'full experience' tour for the product cycle."*

---

## 1. Audience & positioning

Same audience as the rest of the family (§1 of `onboarding-flow-spec.md`): a plain Claude Code user,
invited via Claudesk, mildly skeptical, **already a working developer**. But the full-cycle tour is
**not a first impression** — it is a **graduation destination**:

- It is a **standalone 4th tour** (`tutorial-product-cycle-tour`, name settled below), run **directly**
  in its own session like the arms.
- It is **NOT** a third option in the `tutorial-getting-started` first-timer fork. A full product
  cycle is a poor *first* impression for a cold skeptic — that would conflict with the invariant that
  **greenfield is the reliable high-fidelity first impression** (`onboarding-flow-spec.md` §2). The
  cold open stays greenfield-recommended / brownfield-peer.
- It is reached by a **pointer from the greenfield arm's Step-8 close**: *"this was a light taste of
  the top of the hierarchy; when you're ready to feel the whole product lifecycle, run
  `/tutorial-product-cycle-tour`."* (This pointer is the WP7h.1 deliverable — see §7.)
- The audience **self-selects** into it: they have already taken the ~10–15 min greenfield tour and
  trust the system, so the tour's real length (§5) is a **feature, not a bounce-risk**.

**Value prop / headline aha — DECOMPOSITION.** The star of this tour is watching a **fuzzy idea become
a structured plan**: a shapeless want turns into a milestone-ordered, dependency-mapped,
feature-ready WBS. The aha the light-taste greenfield arm only *hints* at:
*"the workflow can carry a whole **initiative**, not just one small unit of work."*

**Pain removed:** *"I have a big idea but I never turn it into a real plan — I just start coding and
lose the shape of the whole thing."* (Compare greenfield's per-unit *"I devolve into vibe-coding on
one thing"* — this tour is the initiative-scale version.)

---

## 2. Environment — a richer controlled subject (NOT BYO)

A full product cycle needs a meatier subject than the todo-CLI greenfield sample. The tour runs on a
**richer shipped, controlled subject** — mirroring greenfield's shipped-scaffold discipline at a
larger scale:

- **Controlled** ⇒ the staged beats (decomposition, A-at-strategic-layer, handoff/restore) fire
  reliably, the honest-framing invariant is preserved, and there is **no real-repo risk**.
- **NOT BYO.** Bringing the user's own real product idea was considered and rejected: it overlaps the
  brownfield arm's BYO model, cannot guarantee the staged beats, and makes length unbounded.

**Delivery shape — SKETCHED, settled at build-plan time** (the WP7c "delivery shape decided at plan
time" precedent). Two candidates, with tradeoffs for WP7k to weigh:

| Option | What ships | Pros | Cons |
|---|---|---|---|
| **A — Written product brief** | A short paragraph (in the skill, or a `scripts/brief.md`) describing a fictional-but-plausible product the tour drives `vision`→`wbs` against | Lightest to author + maintain; nothing to run so it can't rot; the cycle is about *planning*, not code, so a brief is a natural input | No runnable observable (but this tour has no verify-self grounding beat — see §3, so that's acceptable) |
| **B — Richer sample dir** | A slightly bigger sample project (a few modules) the tour reasons about while decomposing | More concrete "real code to plan around"; a grounding-named moment could cite it | Heavier to maintain; rides path/layout changes (cf. M7 moved every folder); risks rot |

**Lean (non-binding):** Option A (written product brief). The full-cycle tour's ahas are all in the
*planning* (decomposition, strategic docs, handoff of a whole plan) — none of them need a *runnable*
subject the way greenfield's verify-self beat did. A brief is the lower-maintenance, lower-rot choice
and fits the "it's about carrying an initiative" headline. WP7k confirms at plan time.

**Scaffold-in-skill (if Option B, or if the brief ships as a file):** per WP7j Phase 6 / spec §4d,
any shipped subject lives **inside the tour skill's own directory**
(`skills/tutorial-product-cycle-tour/scripts/`), NOT under repo-root `tools/`, so it travels with the
skill's whole-directory symlink on a Claudesk-invited install (no `install.sh` change).

---

## 3. The flow (the settled spine)

**Character of this tour (the reshape that makes it different from the arms):** the product cycle
**pauses at *each* step**, and that recurring pause **IS the human-in-the-loop trust beat** — narrated
at every stage as *"you steer, it keeps the plot."* There is no single engineered "beat B"; the
step-by-step pausing is the whole human-in-the-loop story, which is *stronger* here than one staged
pause. For every drive mode except FSD, the between-stage pause is essentially always enforced.

**Consequences of the step-paused character (what this tour does NOT carry):**
- **NO first-run/replay entry question**, **NO 1–4 drive-mode menu**, **NO mode-aware graduation**,
  **NO replay invitation.** All of that machinery (in the greenfield/brownfield arms) exists to teach
  *"pauses are tunable → go try a faster gear."* That lesson **does not apply** to a cycle whose
  pauses are the point and are not meant to be skipped.
- **NO staged verify-self grounding beat** and **NO staged SURFACE beat.** Those are greenfield-only
  (they need a runnable scaffold + a planted tangent). Grounding here is **NAMED** at the arch stage
  (planning around real/documented shapes), not staged.

### The settled spine

| # | Step | Skill(s) | Beat / disposition |
|---|------|----------|--------------------|
| 0 | **Entry** — honest long label (§5): *"the full product lifecycle, ~30–45 min, real — for when you're ready to go deep."* NO mode menu, NO replay question. Run in **stepping**. | — | FRAME (honest long label) |
| 1 | **Fuzzy idea → vision.** Pause; narrate the steer. | `/product-vision` | **Decomposition beat #1** (STAGED — the headline starts) + recurring step-pause trust beat |
| 2 | **Vision → roadmap** (milestones + ordering). Pause; narrate the steer. | `/product-roadmap` | Decomposition continues + step-pause trust beat |
| 3 | **Research scout** — light, narrated (not a full spike). | `/product-research` | NAMED / light + step-pause |
| 4 | **arch** — system design. Grounding NAMED ("planning around real shapes, not inventing them"). Pause. | `/product-arch` | **Grounding** (NAMED) + step-pause trust beat |
| 5 | **wbs** — decompose into work packages. | `/product-wbs` | **Decomposition PAYOFF** (STAGED — the fuzzy idea is now a dependency-mapped, feature-ready WP list) |
| 6 | **Open the strategic docs** — `vision.md` / `roadmap.md` / `arch.md` / `wbs.md` are real files on disk. | — | **A — state-is-a-file AT THE STRATEGIC LAYER** (STAGED — the durable-strategic-memory payoff) |
| 7 | **Bookend — handoff → restore** (the context of the WHOLE plan survives). | `/session-handoff` → `/session-restore` | **Handoff/Restore** (STAGED bookend — lands *harder* here: a whole roadmap + WBS to lose-and-recover) |
| 8 | **Close** — FSD-for-rare-cases caveat (NAMED, not an invite) + point-at-real-work + what-wasn't-demoed. **NO drive-modes graduation reveal.** | — | Close |

**Ends at a feature-ready WBS — does NOT drive an actual feature.** The payoff is the completed
decomposition (the thing greenfield's light-taste deliberately skips). Executing a feature is what
the greenfield arm already showed; repeating it here would only add length.

### Step 6 — A at the strategic layer (the extension of beat A)

Greenfield stages beat A on a single WIP file. Here beat A lands on the **strategic docs**: open
`vision.md`, `roadmap.md`, `arch.md`, `wbs.md` and show the user *"the whole plan for your initiative
is four plain files you own — not locked in a tool, not in the model's head."* This is the
**durable-strategic-memory** aha, and it is what makes Step 7 (handoff/restore of the whole plan)
believable.

### Step 7 — handoff/restore of a whole plan

Mechanically identical to the arms' Step 7 (see the greenfield arm's Step 7 for the faithful
`/session-handoff`→`/session-restore` choreography and the context-window-management framing). The
difference is **scale**: there is a whole roadmap + WBS to lose and recover, so the "reset the window,
nothing important is lost" payoff lands harder. Reuse the arms' proven copy pattern; do not re-derive
the mechanics.

### Step 8 — close (NO graduation reveal)

Because there is no replay and the pauses are not meant to be skipped, the close **drops the
drive-modes graduation reveal** the arms carry. Instead:

1. **FSD-for-rare-cases caveat (NAMED, honest counterweight — NOT an invite).** *"One note on speed:
   there is an FSD mode that runs a whole product cycle with no stops. It's genuinely only for the
   rare case — a simple, clear vision on a low-stakes, experimental, or throwaway project. For real
   work you want the stops you just saw: steering the plan at each stage is the whole value. Don't
   reach for FSD here yet."*
2. **Point at real work.** *"Now go run your own product cycle — start with `/product-vision` (or
   `/session-start`) on a real initiative of yours."*
3. **What wasn't demoed** (NAMED, delayed-gratification): the feature/task levels of the hierarchy
   (which this WBS now feeds into), and reflect/capture-learns-you.

---

## 4. Aha dispositions (delta from `onboarding-flow-spec.md` §7)

| Aha | Disposition here | Note |
|-----|------------------|------|
| **Decomposition (fuzzy idea → structured plan)** | **STAGED (the headline)** | New to this tour — the light-taste arm only hints at it. Steps 1–2 + payoff at Step 5. |
| **A — state-is-a-file** | **STAGED at the strategic layer** (Step 6) | Extends beat A to `vision/roadmap/arch/wbs.md`. |
| **B — human-in-the-loop pause** | **Recurring, narrated at each step-pause** (NOT one engineered beat) | The step-paused character IS the trust story. |
| **Grounding** | **NAMED** at arch (Step 4) | No staged verify-self here (no runnable-scaffold requirement — §3). |
| **SURFACE (C)** | **CUT** | Greenfield-only; needs a planted tangent this tour doesn't have. |
| **Handoff → restore** | **STAGED bookend** (Step 7) | Lands harder (whole plan). |
| **Drive-modes / replay** | **CUT** (only the FSD-for-rare-cases caveat is NAMED at close) | No replay machinery; pauses are the point. |
| **Hierarchy (product→feature→task)** | **Partially delivered** — the product level IS the tour; feature/task NAMED at close | This tour *is* the hierarchy's top level end-to-end. |
| **Reflect / capture** | **NAMED at close** | Same as the arms. |
| **G — advisory / you keep the wheel** | **FRAME + reinforced at every step-pause** | The recurring pause reinforces G naturally. |

**"Don't force it" (§7 invariant) still binds:** the only GUARANTEED-STAGED beats here are
**Decomposition** (steps 1–2 + 5 payoff), **A-at-strategic-layer** (step 6), and **handoff→restore**
(step 7). Everything else is NAMED or recurring-natural. Staging grounding/SURFACE here (which can't
be staged authentically without a runnable subject) would cost trust — so they are CUT/NAMED.

---

## 5. Honest-framing for a LONG tour (§6 invariant, applied)

Same never-fake-it invariant as `onboarding-flow-spec.md` §6, applied to a genuinely long run:

- **Honest long label — REQUIRED.** *"The full product lifecycle on a sample — real skills, real
  reasoning, roughly ~30–45 minutes. This is the deep-dive; take it when you're ready to go deep."*
  The label is a **filter**, not a warning: the audience has already taken the short tour and
  self-selects into the long one.
- **FORBIDDEN:** any "quick" / "5-minute" claim (same as the arms). WP7k must not write one; WP7e
  pins its absence + the presence of the honest ~30–45 min framing (mirror the arms' `5-min`-absence
  pin, with the longer number).
- **NO narrate-and-skip compression.** Do NOT "run wbs but summarize the output to save time" — that
  brushes the never-fake-it line (it is the WP7j finding-#1 reconciliation seam, kept explicitly out
  of scope). Run the real skills; the honest long label is what makes the length acceptable, not
  faking speed.
- **Per-step pre-framing:** each stage is introduced so a real product-skill run doesn't read as dead
  time — same discipline as the arms' per-beat pre-framing.

---

## 6. Name + fuzzy-matcher collision check

**Name: `tutorial-product-cycle-tour`.** (Matches FB-2's suggested `tutorial-product-cycle-*` and the
family's long-explicit-arm-name convention.) Category: `tutorial-*` family — owns no workflow state,
emits **no transition** (like the other three).

**Fuzzy-matcher collision re-check (WP5 discipline — the harness matcher ranks on `name` AND
`description`):**
- `tutorial-product-cycle-tour` shares the `tutorial-` prefix and `tour` with the arms (intended —
  same family). Against the workflow skills: `product-cycle` contains `product`, which ranks toward
  the `product-*` skills (`product-vision`, `product-roadmap`, …). **This is acceptable and even
  correct** — the tour *is about* the product cycle, and it is invoked by its full compound name, not
  a bare `product`. But the **`description:` MUST avoid** leading with a bare `product` workflow-verb
  phrasing that could out-rank `/product-vision` etc. Frame the description as *"guided tour of the
  full product lifecycle for a new user,"* not *"run the product cycle."*
- No collision with the `session-*` family (no `start`/`restore`/`resume`/`session` substring).
- **Draft `description:`** — *"Guided tour of the full product lifecycle for a brand-new user: watch
  a fuzzy idea become a milestone-ordered, dependency-mapped, feature-ready plan (vision → roadmap →
  arch → wbs). The deep-dive graduation tour (~30–45 min, real), reached from the greenfield tour's
  close. Run directly in a fresh session."*

**WP7e pin:** the `tutorial-`-prefix structural pin WP7e already plans for the three current skills
**extends to this fourth skill** — WP7e SHALL include `tutorial-product-cycle-tour` in the prefix
check (four skills, not three).

---

## 7. WP7h.1 — the pointer note (rides now; wording settled here)

The greenfield arm's Step-8 **"what we did NOT demo" close** already names the full hierarchy. WP7h.1
adds a **concrete pointer** to this tour there (and/or at the Step-2 light-taste boundary). Settled
wording (to be inserted when WP7h.1 lands — see §9 for the "now vs. deferred" split):

> *"You just got a **light taste** of the top of the hierarchy — enough to feel it exists. When
> you're ready to feel the *whole* product lifecycle — a fuzzy idea decomposed all the way into a
> feature-ready plan — there's a deep-dive tour for exactly that: run
> **`/tutorial-product-cycle-tour`** in a fresh session. It's longer (~30–45 min) and it's real, so
> save it for when you want to go deep."*

The brownfield arm needs **no** such pointer (its Step-2 is `/init`→reverse-engineer, a different
entry; the product-cycle tour is a greenfield-flavored graduation).

---

## 8. Constraints carried into the build-WP (WP7k)

Same as `onboarding-flow-spec.md` §8, plus:
- **No-runtime repo convention** — prompt/markdown/skill edits only (a written product brief, if
  chosen, is markdown).
- **Emits NO transition** → no `transitions.md` change, no new F/I/T/P/S ID.
- **Path-qualification mandate** — every `.claude/` reference explicitly `~/.claude/` or
  `<proj-dir>/.claude/`.
- **install.sh additive-only** — WP7k creates a new skill dir → re-run `install.sh` after (heed the
  orphan-prune caveat, `SURFACE-2026-07-21-INSTALL-SH-NO-ORPHAN-PRUNE`).
- **Scaffold-in-skill** (if a subject file ships) — inside `skills/tutorial-product-cycle-tour/`, per
  §2 / spec §4d.
- **Reuse, don't re-derive, the handoff→restore choreography** from the greenfield arm's Step 7
  (§3 above).

---

## 9. "Now vs. deferred" split + WBS impact

**This session (design-only):**
- ✅ This design doc (settled name, flow, environment, dispositions, honest-framing, pointer wording).
- ✅ **WP7h.1 pointer note** — MAY land now (it's XS copy in the greenfield arm), OR ride with WP7k.
  **Decision:** defer the pointer to WP7k too, so the pointer and the tour it points at land + get
  accepted **together** (a live pointer to a not-yet-built skill would be a broken reference in the
  interim). Recorded as WP7k task 1.

**Deferred to a new WBS work-package — WP7k (`build the full product-cycle tour`):**
- Build `skills/tutorial-product-cycle-tour/SKILL.md` against this design.
- Settle the environment delivery shape (§2 Option A vs. B) at plan time.
- Add the WP7h.1 pointer to the greenfield arm.
- Sequenced **before** the operator's batch hands-on acceptance run (operator, 2026-07-24) — so the
  single acceptance walkthrough covers **all four** tour surfaces (both arms + WP7g corrections + this
  new full-cycle tour) in one pass, rather than accept-then-build-then-re-accept. The batch acceptance
  SURFACE (`SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED`) extends to cover WP7k's
  copy; WP7e still codifies last, against the accepted copy.
- WP7e's `tutorial-`-prefix pin extends to the fourth skill (§6).

**Cross-links:** extends `onboarding-flow-spec.md` (same family/invariants); feeds WP8's M12 return
contract (a fourth tour surface Claudesk's onboarding may eventually point at — though the stable
coupling stays the single `/tutorial-getting-started` command; the product-cycle tour is reached
*from within* the family, not a new Claudesk coupling); AD-5 as-built resync notes the fourth skill.
