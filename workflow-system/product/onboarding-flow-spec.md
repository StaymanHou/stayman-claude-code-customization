---
shape: onboarding-flow-spec
stage: spec
milestone: 11
state: complete
updated: 2026-07-22
---

# Onboarding Flow Spec — the `workflow-tour` first-run experience (M11 / WP7a)

> **What this is.** The durable design contract for the new-user onboarding experience. It
> promotes the operator co-design in [`onboarding-brainstorm.md`](onboarding-brainstorm.md)
> (2026-07-21) into a precise, buildable spec. **This is a promotion, not a revision** — every
> settled brainstorm decision is preserved in intent; where this doc corrects the brainstorm it
> is called out explicitly (only one place: the `acceptEdits` vs `bypassPermissions`
> distinction in §5).
>
> **Who reads it.** WP7b (entry skill) / WP7c (scaffold) / WP7d (beats-wiring) / WP7e
> (scenarios + pins) build against this contract. **WP8** hands the Claudesk-facing part (§4)
> back to Claudesk as the M12 return-contract deliverable.
>
> **Origin:** `SURFACE-2026-07-20-CLAUDESK-ONBOARDING-DESIGN`, roadmap Milestone 11,
> `HANDOFF-from-claudesk-2026-07-20.md` item #5.

---

## Revision 2026-07-22 (WP7b co-design — structure + naming)

State: `complete` → back to `in-progress` for this revision, then `complete`. At the start of the
WP7b build, the operator refined the settled structure and naming. These changes **supersede** the
corresponding parts of §2, §4, §5a, and §3-brownfield below where they conflict; the superseded
prose is left in place for provenance with an inline pointer to this revision.

1. **Three-skill family, not one skill with an internal fork.** The single-entry `workflow-tour`
   skill is replaced by a **family of three `tutorial-`-prefixed skills**:
   - **`tutorial-getting-started`** — the entry/dispatcher. Recommends `acceptEdits`, presents the
     new-vs-existing fork (greenfield recommended-default / brownfield first-class peer), then
     **invokes the chosen arm skill inline**. This is the single command Claudesk points at.
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
  two arm skills. Claudesk renders the invite surface and points at this one command.
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
- **The walkthrough opens (both paths) by recommending `acceptEdits` mode** with a one-line "why
  it's safe" — see §5 (7a.4). Universal, at the start, regardless of path.
- **The first run stays in stepping/orchestrated** so the human-pause beat (B) is **visible** —
  drive modes are revealed only at the very end as a graduation (see §3 beat 7, §6).

---

## 3. The two per-path flows (AC-1)

Both paths do **one small real unit of work end-to-end**. Most ahas are **beats along that one
thread** of real work — not separate scenes (the "organic weave"). The two paths share a spine
shape but never reconverge.

### Legend for the beat annotations
Beats are keyed to the disposition table in §7 (`A`, `B`, `C`, `G`, `Grounding`, `Handoff/Restore`,
`Drive-modes`, `Hierarchy`, `Reflect/Capture`).

### Greenfield flow — "structure on a blank page"

**Pain removed:** *"I have an idea but I always devolve into unstructured vibe-coding and lose the
plot."*

**Environment:** one tiny **shipped, RUNNABLE greenfield scaffold** (WP7c) — empty-ish, low cost,
nothing real to lose. This is the single place SURFACE (C) and verify-self grounding are
**guaranteed staged** beats (the scaffold plants an authentic small mess + has ≥1 observable
outcome to check).

| # | Step | Beats fired | Staged? |
|---|------|-------------|---------|
| 1 | **Entry** → recommend `acceptEdits` (universal) → pick path → framing line ("you keep the wheel") | **G** (FRAME) | framing |
| 2 | **Enter top-of-hierarchy:** fuzzy idea → `/product-vision` → roadmap → … (or `/session-start` classifying a smaller new feature). Light **product→feature lifecycle taste** lands here (greenfield-only). | **Hierarchy** (light taste), **Grounding**: probe-first/plan-around-real-shapes named as it occurs | taste |
| 3 | **Do one small real thing** → plan becomes a **Work Tree** → open the state file: **A — it's a file you can open, and it's yours** (~free; the WIP already exists after any step). | **A** (BEAT) | natural |
| 4 | **Hit a verify gate** → **B — it pauses and asks** (verify-human / plan review). The trust beat. Onboarding stays in stepping/orchestrated so this is visible; reinforce G here ("it paused to ask — and even here you can redirect"). | **B** (BEAT), **G** reinforce | natural (kept visible) |
| 5 | **Grounding (STAGED):** agent runs the runnable scaffold, **observes** it via `verify-self`, reports **PASS/FAIL** vs an observable outcome — the user watches it **CHECK reality** instead of guessing. Pre-framed ("watch — it's about to actually run it and check the output; this is the grounding moment"). | **Grounding** (STAGED — verify-self) | **STAGED** |
| 6 | **SURFACE (STAGED):** agent hits the planted authentic tangent → runs SURFACE → logs to backlog → continues without losing the plot. **C** = the rabbit-hole caught; backlog is C's flip side (folded in, not a separate aha). | **C** (STAGED greenfield), backlog folded into C | **STAGED** |
| 7 | **Bookend 1 — the boundary (STAGED):** `/session-handoff` → "leave" → `/session-restore` → full context survives. The **emotional peak**; placed near the end so there's real state to lose-and-recover. | **Handoff/Restore** (STAGED bookend) | **STAGED** |
| 8 | **Bookend 2 — the graduation (STAGED, LAST):** reveal drive modes (autopilot/FSD) — deliberately last, deliberately **un-pushed** ("autopilot chains safe steps; FSD skips even verify-human — here's when appropriate. Not recommended yet"). Then **Close:** point at what we did NOT demo — full **Hierarchy** + **Reflect/Capture-learns-you** — "here's what's here when you're ready." | **Drive-modes** (STAGED reveal, LAST), **Hierarchy**/**Reflect** (NAMED at close) | **STAGED** reveal + NAMED close |

### Brownfield flow — "it read MY real code and reconstructed what I never wrote down"

**Pain removed:** *"I'm deep in a real codebase and Claude keeps drifting / forgetting context /
half-finishing things across sessions."*

**Environment:** **bring-your-own real code — NO demo.** This path's headline aha is *strongest on
the user's real repo* and *weakest on a seed* — a brownfield demo would reduce it to a parlor
trick and actively weaken the strongest brownfield moment. At the vision/arch stage the work is
read-heavy + additive (low blast radius), so BYO + `acceptEdits` is acceptable.

| # | Step | Beats fired | Staged? |
|---|------|-------------|---------|
| 1 | **Entry** → recommend `acceptEdits` (universal) → pick path → framing line (G). | **G** (FRAME) | framing |
| 2 | **`/init` first** → generates a first-cut `CLAUDE.md` from the existing code. | (setup) | — |
| 3 | **Product workflow reverse-engineers** vision / roadmap / arch from the existing code. **The headline aha:** *"it read my actual code and reconstructed the strategic layer I never wrote down."* This IS the brownfield grounding beat (reconstructs strategy from real code). | **Grounding** (brownfield headline — `/init`→reverse-engineer) | natural (the headline) |
| 4 | **`product-context` revises** the `CLAUDE.md` that `/init` generated → durable project context now reflects the reconstructed strategy. Open the file: **A — state is a file you can open** lands here. | **A** (BEAT) | natural |
| 5 | **Do one small real unit of work** on the real repo → plan → Work Tree → **hit a verify gate → B** (it pauses and asks). Trust beat, kept visible (stepping/orchestrated). Reinforce G. | **B** (BEAT), **G** reinforce | natural (kept visible) |
| 6 | **Grounding + SURFACE = NAMED/opportunistic here** (not staged): probe-first and verify-self **fire naturally** if the real work touches an integration or a runnable surface; SURFACE is pointed-at when a tangent occurs ("when you hit a tangent, here's what SURFACE does"). | **Grounding** (NAMED), **C** (NAMED) | NAMED / opportunistic |
| 7 | **Bookend 1 — the boundary (STAGED):** `/session-handoff` → "leave" → `/session-restore` → context survives on the real repo. Emotional peak. | **Handoff/Restore** (STAGED bookend) | **STAGED** |
| 8 | **Bookend 2 — the graduation (STAGED, LAST):** reveal drive modes, un-pushed. **Close:** point at what we did NOT demo — **Hierarchy** (CUT on brownfield — too big to feel in run one) + **Reflect/Capture-learns-you** — "here's what's here when you're ready." | **Drive-modes** (STAGED reveal, LAST), **Hierarchy** (CUT/named), **Reflect** (NAMED at close) | **STAGED** reveal + NAMED close |

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
  skill dispatches inline to the greenfield or brownfield arm).

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
- **Must NOT** hardcode the **permission-mode instruction** — `acceptEdits` guidance is delivered by
  the skill (§5), not by Claudesk's invite copy (so a future mode-guidance change is a one-repo
  edit).
- **The ONLY stable coupling Claudesk may depend on is the command name `/tutorial-getting-started`.**
  (Updated 2026-07-22 — was `/workflow-tour`; WP8's M12 return contract communicates this name.) If
  that name ever changes, it is a return-contract change communicated back through the same channel — so
  the name is treated as a published interface (this is why §5 pins it and WP7e guards it).

### 4d. Return-contract delivery note (for WP8)
WP8 delivers §4a–§4c to Claudesk either as a reciprocal handoff doc or a backlog SURFACE in the
Claudesk repo, bundled with the other two M12 deliverables (install/uninstall command copy from
WP4.5; the settled `workflow-system/product/*` + `workflow-system/state/*` doc layout + the required
`docs_list` glob change from M7 WP3-M7).

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
does **not** apply here: the tour deliberately runs in **stepping/orchestrated** so beat B (the
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

### 5b. Permission-mode recommendation + reassurance copy (7a.4) — SETTLED (operator 2026-07-22, corrected)

**Recommend `acceptEdits` mode — NOT `bypassPermissions`.** These are **two distinct Claude Code
modes**; the brainstorm's "auto-accept / bypass-permissions" phrasing conflated them (operator
correction). Confirmed against the official docs (https://code.claude.com/docs/en/permission-modes.md):

| Mode | File edits | Safe filesystem cmds | Arbitrary shell / network |
|---|---|---|---|
| **`acceptEdits`** | auto | auto | **still prompts** (gated) |
| **`bypassPermissions`** | auto | auto | auto — skips **all** checks (circuit-breakers only) |

`acceptEdits` is the correct fit for a guided tour: it removes edit-prompt friction while **still
gating arbitrary shell commands and network calls**, so the blast-radius claim ("stays local") is
*honestly true*. `bypassPermissions` skips all gates — overkill for a tour, and it trains the wrong
mental model (the docs note it's meant for isolated containers/VMs). **Toggle: Shift+Tab cycles
modes; land on `acceptEdits`.**

**Reassurance one-liner (universal open, both paths):**
> *"First, press Shift+Tab until Claude Code shows 'accept edits' mode — that lets the tour make
> its file changes without a prompt on every step, while still asking you before it runs any shell
> command or touches the network. It's safe here: all work stays inside this one project
> directory, nothing is pushed or published, and you keep the wheel (the workflow still pauses to
> ask you at the decisions that matter)."*

The copy ties reassurance to (a) the **accurate** mode behavior (edits auto; shell/network still
gated), (b) blast-radius containment (one dir, no push/publish), and (c) the **G** advisory-framing
beat ("you keep the wheel") — so it reinforces the human-in-the-loop trust story rather than
undercutting it.

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
| **B — Human-in-the-loop pause** (verify-human / plan review) | BEAT (both) | The trust beat + honest counterweight to drive-modes. **Keep onboarding in stepping/orchestrated so this is VISIBLE** (don't autopilot past it — would be ironic). |
| **C — SURFACE (rabbit-hole caught)** | STAGED greenfield-only; NAMED brownfield | Authentic staging needs controlled code → the greenfield scaffold. Brownfield keeps it real → C reverts to named/opportunistic there. |
| **G — Advisory / you keep the wheel** | FRAME (both) | Anxiety-reducer for the skeptical invitee. One line in entry + reinforced at the pause. |
| **Grounding — the workflow checks reality instead of guessing** | STAGED greenfield (verify-self); NAMED brownfield | **Epistemic-honesty aha.** Three surfaces: probe-first roadmap/WBS (plan around *documented* real API shapes); **verify-self** (agent *observes the running system* before claiming done); brownfield `/init`→reverse-engineer (reconstructs strategy from *real code*). For a skeptic burned by agents declaring broken code "done," *"it actually went and looked"* may be the strongest trust beat. **Greenfield:** stage a verify-self beat ⇒ **the scaffold MUST be runnable** (WP7c constraint). **Brownfield:** probe-first + verify-self named/opportunistic; `/init`→reverse-engineer carries the grounding headline. |
| **Session handoff → restore** (context survival) | STAGED bookend (both) | The **emotional peak.** Near the end so there's real state to lose-and-recover. `/session-handoff` → "leave" → `/session-restore`. |
| **Drive modes / autopilot / FSD** | STAGED graduation reveal, **LAST** | **NOT the first-run recommendation.** First walkthrough runs stepping/orchestrated so pauses are visible → THEN reveal modes, deliberately un-pushed ("not recommended yet"). Showing autopilot first would hide beat B. |
| **Hierarchy (product→feature→task) as one record** | Greenfield: light taste; Brownfield: CUT | Too big to *feel* in run one; greenfield users are already at the top so a light taste lands there. Named otherwise. |
| **Reflect / capture — system learns you** | NAMED at close (both) | Delayed-gratification (value shows next session). Great closing note; wrong as a staged beat. |
| **Backlog as durable idea-catcher** | FOLD into C | Flip side of SURFACE, not a separate aha. |

### The "don't force it" rule (the invariant WP7b/WP7c/WP7d/WP7e must honor)

Only these beats are **GUARANTEED STAGED**, because only these can be staged **authentically**:
1. **A** — state-is-a-file (both paths; ~free)
2. **B** — human-in-the-loop pause (both paths; kept visible by staying stepping/orchestrated)
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
