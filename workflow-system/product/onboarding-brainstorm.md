---
stage: brainstorm
state: in-progress
milestone: 11
updated: 2026-07-21
---

# WP7 / M11 — New-user Onboarding & "Aha" Design (co-design brainstorm)

> **Status:** brainstorm-first co-design output. NOT yet a spec. This file captures the
> operator-settled shape so the downstream skill (`/product-vision` or `/feature-spec`) can
> plan against a fixed target. Origin: `SURFACE-2026-07-20-CLAUDESK-ONBOARDING-DESIGN`,
> roadmap Milestone 11, `HANDOFF-from-claudesk-2026-07-20.md` item #5.

## The audience (fixed)

A plain Claude Code user, invited via **Claudesk**, who has **never seen the workflow system**
and is mildly skeptical ("is this worth changing how I work?"). Critically: **already a working
developer with real projects** — they did not come to learn a toy; someone claimed this makes
their *actual* work better. The core value prop onboarding sells is therefore explicitly about
**real work**: *structure + durable state + human-in-the-loop discipline makes your real
software work less chaotic.*

## Settled structure

- **Single entry point** — likely a dedicated skill (name TBD; e.g. `/session-onboard` or
  `/workflow-tour`). Claudesk renders the invite surface and points at this one command.
- **Two fully separate paths right after entry** (they diverge and stay diverged — NOT
  branch-then-reconverge):
  - **Greenfield** — starting something new / empty dir.
  - **Brownfield** — an existing codebase.
- **Entry recommends GREENFIELD as the default for a true first-timer, with BROWNFIELD as a
  first-class peer choice** (operator decision 2026-07-21). A **default, not a funnel** — greenfield
  is the controlled path where every staged beat fires reliably (scaffold-hosted), so it's the
  high-fidelity first impression; but brownfield is offered as a one-keystroke peer, NOT gated
  behind the tutorial ("already have a project? point it there instead"). This defuses the
  skeptic-bounce (the mostly-brownfield real-developer audience must not feel funneled through a
  toy tutorial) while still guiding the first-timer to the reliable path. Consistent with the
  advisory / "you keep the wheel" framing (G).
- **The greenfield tour is a NARRATED REAL RUN, honestly labeled** (operator decision 2026-07-21).
  It drives *real* skills with *real* reasoning — NOT a faked/scripted demo reel — because the
  headline ahas (grounding / verify-self / SURFACE) lose all value if canned; faking "it actually
  went and looked" is lying about the one thing the skeptic cares most about, and a user who later
  realizes it was faked trusts the system *less*. To keep the real run from feeling like dead time,
  **each beat is pre-framed** so the user knows what they're watching and why ("watch — it's about
  to actually run the scaffold and check the output; this is the grounding moment"). **Drop any
  "quick / 5-minute" claim** — that's false advertising for a real agent run (realistically
  ~10–15 min + real token spend). Label it honestly: *"a guided ~10–15 min run on a sample — real,
  so you watch it actually work."* (Cheap beats like A/open-the-file and G/framing are near-instant;
  the real-time investment is in the beats that MUST be authentic.)
- **Walkthrough opens by recommending the user switch CC to auto-accept / bypass-permissions**
  — **universally, at the start**, regardless of path (operator decision). Include a one-line
  reassurance about why it's safe so the "turn off my prompts" optic doesn't alarm the
  skeptical new user.

## The two paths

### Greenfield — "structure on a blank page"
- **Pain removed:** *"I have an idea but I always devolve into unstructured vibe-coding and lose
  the plot."*
- **Entry:** top of the hierarchy — fuzzy idea → `/product-vision` → roadmap → …, or `/session-start`
  classifying a new feature for something smaller.
- **Includes a hierarchy taste** (product → feature) — this is the one path where a light
  product→feature lifecycle sample belongs (cut from brownfield).
- **Environment:** **one tiny shipped greenfield scaffold** (empty-ish; low cost). This is the
  single place SURFACE (C) is a **guaranteed staged beat** — the scaffold plants an authentic
  small mess to catch. Nothing real to lose here, so a seed doesn't undercut the value prop.

### Brownfield — "it read MY real code and reconstructed what I never wrote down"
- **Pain removed:** *"I'm deep in a real codebase and Claude keeps drifting / forgetting context /
  half-finishing things across sessions."*
- **Entry (operator-corrected):** **`/init` first** → then the **product workflow
  reverse-engineers** vision / roadmap / arch from the existing code → then **`product-context`
  revises the `CLAUDE.md` that `/init` generated.** The aha: *"it read my actual code and
  reconstructed the strategic layer I never wrote down."*
- **Environment:** **bring-your-own real code — NO demo.** This aha is *strongest on the user's
  real repo* and *weakest on a seed* (a brownfield demo would reduce it to a parlor trick and
  actively weaken the strongest brownfield moment). At the vision/arch stage the work is
  read-heavy + additive (low blast radius), so BYO + bypass-permissions is acceptable.
- **SURFACE (C)** here is **opportunistic / named-only** (not staged): *"when you hit a tangent,
  here's what SURFACE does."*

## Aha moments — dispositions

Legend: **STAGED** = guaranteed engineered beat · **BEAT** = occurs naturally along the work
thread, ensure we don't skip it · **FRAME** = one-line framing, not a scene · **NAMED** =
mention/point-at, never staged · **CUT** = out of first run.

| Aha | Disposition | Notes |
|-----|-------------|-------|
| **Structured approach (the two paths)** | STAGED (both paths) | The core family; greenfield=structure-on-blank, brownfield=discipline-on-real. |
| **A — State is a file you can open** | BEAT (both) | Foundational (Core Principle #1); nearly free — the WIP/state file already exists after any step. Makes handoff/restore believable. |
| **B — Human-in-the-loop pause** (verify-human / plan review) | BEAT (both) | The trust beat + honest counterweight to drive-modes. **Keep onboarding in stepping/orchestrated so this is VISIBLE** (don't autopilot past it — would be ironic). |
| **C — SURFACE (rabbit-hole caught)** | STAGED greenfield-only; NAMED brownfield | Operator promoted C to guaranteed. Authentic staging needs controlled code → greenfield scaffold. Brownfield keeps it real → C reverts to named/opportunistic there. |
| **G — Advisory / you keep the wheel** | FRAME (both) | Anxiety-reducer for the skeptical invitee. One line in entry + reinforced at the pause ("it paused to ask — and even here you can redirect"). |
| **Grounding — the workflow checks reality instead of guessing** | STAGED greenfield (verify-self); NAMED brownfield | **Distinct aha (added 2026-07-21): epistemic honesty**, not structure/state/discipline. Three surfaces: probe-first roadmap/WBS (plans around *documented* real API shapes, not assumed — strategic grounding); **verify-self** (agent *observes the running system* before claiming done — implementation grounding); brownfield `/init`→reverse-engineer (reconstructs strategy from *real code* — already the brownfield headline). For a skeptic burned by agents declaring broken code "done," *"it actually went and looked"* may be the strongest trust beat — the antidote to the #1 agent fear. **Greenfield:** stage a **verify-self beat** — agent observes the scaffold, reports PASS/FAIL vs an observable outcome, user watches it CHECK (**⇒ the greenfield scaffold MUST be runnable** — a WP7c constraint). **Brownfield:** probe-first + verify-self are named/opportunistic (fire naturally when real work has integrations / runnable surfaces); `/init`→reverse-engineer carries the grounding headline there. |
| **Session handoff → restore** (context survival) | STAGED bookend | Deliberate staged beat; likely the **emotional peak**. Save for near the end so there's real state to lose-and-recover. Run `/session-handoff` → "leave" → `/session-restore`. |
| **Drive modes / autopilot / FSD** | STAGED graduation reveal, LAST | Operator: **NOT the first-run recommendation.** First walkthrough runs in stepping/orchestrated so pauses are visible and trust is built → THEN reveal modes ("autopilot chains safe steps; FSD skips even verify-human — here's when appropriate. Not recommended yet"). Showing autopilot first would hide beat B. |
| **Hierarchy (product→feature→task) as one record** | Greenfield: light taste; Brownfield: CUT | Too big to *feel* in run one; greenfield users are already at the top so a light taste lands there. Point at the full lifecycle otherwise. |
| **Reflect / capture — system learns you** | NAMED at close | Delayed-gratification (value shows next session). Great "here's what keeps getting better" closing note; wrong as a staged beat. |
| **Backlog as durable idea-catcher** | FOLD into C | Flip side of SURFACE, not a separate aha. |

## The organic weave (don't force it)

Most ahas are **beats along one thread of real work**, not separate scenes. The walkthrough
does *one small real unit of work end-to-end* per path; the same spine, different content:

1. **Entry** → recommend bypass-permissions (universal) → pick path → framing line (G: "you keep the wheel").
2. **Do one small real thing** → plan becomes a Work Tree → **A** (open the file — it's yours) lands ~free.
3. **Hit a verify gate** → **B** (it pauses and asks) — the trust beat. Onboarding stays in stepping/orchestrated so this is visible.
4. **Grounding** → greenfield stages a **verify-self** beat (agent observes the runnable scaffold, reports PASS/FAIL vs an observable outcome — user watches it *check* reality); brownfield NAMES it (probe-first + verify-self fire opportunistically; `/init`→reverse-engineer already carried the grounding headline at entry).
5. **SURFACE** → **C** STAGED in greenfield (planted tangent); NAMED in brownfield.
6. **Bookend 1 — the boundary:** `/session-handoff` → "leave" → `/session-restore` → context-survival aha (emotional peak, near the end).
7. **Bookend 2 — the graduation:** reveal drive modes (autopilot/FSD), deliberately last, deliberately un-pushed.
8. **Close:** point at what we did NOT demo — hierarchy + reflect/capture-learns-you — "here's what's here when you're ready." Nothing forced.

**"Don't force it" in practice:** C (brownfield), grounding (brownfield), hierarchy (brownfield),
reflect/capture are NEVER staged — named or opportunistic only. Only A, B, greenfield-grounding
(verify-self), greenfield-SURFACE, handoff/restore, and the drive-modes reveal are guaranteed
staged beats, because those can be staged *authentically*. **New constraint from the grounding
beat:** the greenfield scaffold (WP7c) MUST be *runnable* so verify-self has an observable
outcome to check.

## Settled at milestone level (2026-07-21 co-design)

- [x] **M11 deliverable scope** — **FULL BUILD** (not spec-only). WBS carves it into WP7a–WP7e
      (spec → entry skill → runnable scaffold → beats-wiring → codify). See `wbs.md`.
- [x] **Entry default** — **greenfield recommended (default for first-timer), brownfield a
      first-class peer** — a default, not a funnel.
- [x] **Tour authenticity** — **narrated real run, honestly labeled** (~10–15 min, real; NOT a
      faked demo reel). No "5-min" claim.
- [x] **Grounding aha** — added; greenfield stages verify-self, brownfield names it. Forces the
      **greenfield scaffold to be RUNNABLE** (WP7c constraint).

## Open specifics (deferred to the per-WP feature-workflow sessions — NOT this session)

> This session is **vision + high-level spec only** — the items below are per-WP concerns settled
> when each sub-WP runs through its own feature workflow. Listed here so they aren't lost.

- [ ] **Entry skill name + category** — dedicated skill confirmed; exact name TBD
      (`/session-onboard`? `/workflow-tour`? `/onboard`?) and category (`session-*` / new / `util-*`).
      → **WP7a task 7a.3** (settled there so WP7b builds against a fixed name; heed the WP5
      fuzzy-matcher-searches-descriptions collision discipline).
- [ ] **Greenfield scaffold specifics** — fixture dir vs. temp-dir scaffolder; the minimal
      *runnable* shape + its observable outcome (for the verify-self beat); the planted tangent
      (for SURFACE). → **WP7c**.
- [ ] **Per-beat narration copy** — the pre-framing lines for each staged beat (grounding,
      SURFACE, handoff/restore, drive-modes reveal) + the honest time label. → **WP7a/WP7d**.
- [ ] **Bypass-permissions reassurance copy** — the one-line "why it's safe". → **WP7a task 7a.4**.
- [ ] **Claudesk surface contract** — what Claudesk shows + when it points at the entry command;
      the M12 return-contract form. → **WP7a task 7a.2**, delivered by **WP8**.
