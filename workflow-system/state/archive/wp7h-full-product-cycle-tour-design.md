---
shape: design-brainstorm
wp: WP7h
milestone: 11
state: complete
drive_mode: autopilot
updated: 2026-07-24
---

> **CLOSED 2026-07-24 (design-only).** Design settled + written to
> `workflow-system/product/full-product-cycle-tour-design.md`; build split out to **WP7k** in the WBS.
> No code, no transition. Archived.

# WP7h — Full product-cycle "full experience" tour (DESIGN-ONLY this session)

**Operator direction (2026-07-24, this session):**
1. **Brainstorm the design with the operator first** (like the WP7.1 onboarding brainstorm), then produce a settled design.
2. **Design-only this session.** The *build* is deferred → **a new build-WP added to the WBS** (so it lands after the batch hands-on acceptance run, alongside the other tour surfaces before WP7e freezes pins).

**FB-2 origin (grounded, `tmp/wp7e-tour-walkthrough-feedback.md` lines 44-65):**
> Operator: re the greenfield "light taste, not a full lifecycle" — *"We will then need a pointer note and a corresponding **'full experience' tour** for the product cycle."*

The light-taste greenfield Step-2 (deliberately bounded product→feature entry, then pivots to the small unit) **implies a heavier counterpart** — a full product-cycle tour walking vision → roadmap → research → arch → wbs → features — and the light tour should **name/point at it**. Name is open (`tutorial-product-cycle-tour`?).

**Deliverables this session:**
- A settled design (a `full-product-cycle-tour-design.md` doc, or a §-addition to `onboarding-flow-spec.md`) — name, flow, staged-vs-named beats, honest-framing, relationship to the light-taste arm, environment (scaffold? BYO? which?).
- 7h.1 pointer note wording (rides once the name is settled).
- A **new build-WP** appended to `wbs.md` for the actual skill build (deferred past acceptance).

**NOT this session:** the skill build itself (7h.2-build / 7h.3). That is the new WBS WP.

## Brainstorm log

### Round 1 — four anchoring decisions (operator via AskUserQuestion, 2026-07-24)

1. **Headline aha = Decomposition: fuzzy idea → structured plan.** The star is watching a vague
   idea become vision → roadmap → arch → wbs — a shapeless want turns into a milestone-ordered,
   dependency-mapped, feature-ready plan you can execute. The aha the light-taste greenfield arm
   only *hints* at: "the workflow can carry a whole **initiative**, not just one unit of work."
2. **Environment = a richer shipped scaffold / written product brief.** Controlled (staged beats
   fire reliably, honest-framing preserved, no real-repo risk), mirroring greenfield's
   shipped-scaffold discipline at a larger scale. Exact delivery shape (a bigger sample dir vs. a
   written product-brief paragraph the tour drives vision→wbs against) is **sketched with tradeoffs
   in the design doc, settled at build-plan time** (the WP7c "delivery shape decided at plan time"
   precedent). NOT BYO — BYO overlaps brownfield + can't guarantee staged beats + unbounded length.
3. **Positioning = standalone 4th `tutorial-product-cycle-*` tour, run directly.** The greenfield
   arm's **Step-8 close points at it** ("this was a taste; for the whole lifecycle, run X"). It is a
   **graduation destination**, NOT a third option in the `tutorial-getting-started` first-timer fork
   (a full product cycle is a poor FIRST impression for a cold skeptic — conflicts with "greenfield
   is the reliable high-fidelity first impression" invariant). Matches FB-2's "pointer note +
   corresponding tour." "Diverge and stay diverged" structural invariant preserved (new skill file).
4. **Length honesty = honest long label + graduation-not-first-run.** Label it truthfully
   ("~30–45 min, the full lifecycle, real — for when you're ready to go deep"), positioned AFTER the
   ~10–15 min greenfield tour. The audience self-selects: they already trust the system, so length
   is a **feature, not a bounce-risk**. Same never-fake-it honest-framing invariant (§6); NO
   "5-min"-style claim; NO narrate-and-skip compression (would brush the never-fake-it line — that's
   the WP7j finding-#1 reconciliation seam, kept out of scope here).

### Round 2 — spine, pauses, and the no-replay reshape (operator, 2026-07-24)

5. **Pauses at EACH step — the step-pause IS the recurring trust beat.** The product cycle pauses
   between each product skill/stage (vision → roadmap → research → arch → wbs). For all drive modes
   except FSD, that between-stage pause is **essentially always enforced** — steering strategic
   decisions at each stage is the point. So beat **B is NOT one engineered pause** here; instead the
   **recurring step-by-step pause is narrated as the "you steer, it keeps the plot" story** at every
   stage. This is a *stronger* human-in-the-loop story than a single staged beat.
6. **NO replay / no faster-gear machinery.** Because the pauses aren't meant to be skipped, this
   tour does **NOT** carry the arms' first-run/replay entry question, the 1–4 drive-mode menu, the
   mode-aware graduation, or the replay invitation. Those existed to teach "pauses are tunable → try
   a faster gear"; that lesson **does not apply** to a cycle whose pauses are the point.
7. **Entry = run in stepping; NO entry menu, NO first-run/replay question.** The tour just runs,
   pausing at each stage (matching the real product-cycle cadence). At **close**, briefly **NAME**
   that FSD-through-a-whole-product-cycle exists but is **only for rare cases** — simple/clear
   vision, low-stakes / experimental / throwaway projects — an honest counterweight, **not** an
   invite to try it.
8. **Drop the drive-modes graduation close.** No "here are the faster gears" reveal (there's no
   replay, and the pauses aren't meant to be skipped). Close instead = the FSD-for-rare-cases caveat
   (7 above) + point-at-real-work ("go run your own product cycle") + what-wasn't-demoed.

### Round 3 — spine endpoints (operator, 2026-07-24)

9. **End at a feature-ready WBS — do NOT drive an actual feature.** The tour's payoff is the
   completed decomposition (the thing greenfield's light-taste deliberately skips); executing a
   feature is what the greenfield arm already showed. Ends at the feature-ready WBS + the strategic
   docs on disk.
10. **Keep the handoff → restore bookend** near the end. It lands *harder* here than in the arms —
    there is a whole roadmap + WBS to lose and recover — and it's mode-independent, so the no-replay
    change doesn't touch it.

### SETTLED SPINE (design-doc target)

| # | Step | Product skill(s) | Beat / disposition |
|---|------|------------------|--------------------|
| 0 | Entry — honest long label (~30–45 min, real, graduation-not-first-run); NO mode menu, NO replay question; run stepping | — | FRAME (honest long label) |
| 1 | Fuzzy idea → **vision**; pause + narrate the steer | `/product-vision` | **Decomposition beat #1** (STAGED — headline starts) + step-pause trust beat |
| 2 | Vision → **roadmap** (milestones + ordering); pause + narrate the steer | `/product-roadmap` | Decomposition continues + step-pause trust beat |
| 3 | *(light)* research scout — narrated, not a full spike | `/product-research` | NAMED / light; step-pause |
| 4 | **arch** — system design; grounding named (plans around real shapes); step-pause | `/product-arch` | **Grounding** (NAMED) + step-pause trust beat |
| 5 | **wbs** — decompose into WPs | `/product-wbs` | **Decomposition PAYOFF** (STAGED — fuzzy idea is now a dependency-mapped, feature-ready WP list) |
| 6 | Open the docs — vision.md / roadmap.md / arch.md / wbs.md are real files | — | **A — state-is-a-file AT THE STRATEGIC LAYER** (STAGED — durable-strategic-memory aha) |
| 7 | Bookend — handoff → restore (context of the WHOLE plan survives) | `/session-handoff` → `/session-restore` | **Handoff/Restore** (STAGED bookend — lands harder: a whole roadmap/WBS to recover) |
| 8 | Close — FSD-for-rare-cases caveat (NAMED, not an invite) + point-at-real-work + what-wasn't-demoed | — | Close (NO drive-modes graduation reveal) |

**Recurring across steps 1–4:** the between-stage pause narrated as "you steer, it keeps the plot"
(the recurring trust beat, replacing a single engineered beat B).

## Discoveries
