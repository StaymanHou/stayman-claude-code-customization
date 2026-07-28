# Session vocabulary — turn vs. session boundary (WP5/M9 + the exit-chain follow-on)

Two features, one story: WP5/M9 disambiguated the overloaded word **"pause"** and
renamed three skills; the `boundary-handoff-autochain` feature then promoted
WP5's chaining rule from advisory prose into the state machine.

The **canonical contract** is `CLAUDE.snippet.md` →
`## Session vocabulary — turn vs. session boundary (GLOBAL)` (injected into every
session), and the authoritative chaining decision is the **pause-policy table**
in `workflow-system/product/transitions.md` → "Drive modes" plus all four
`agents/*/AGENTS.md` cheat-sheets. This doc is the provenance: what was decided,
what it cost to learn, and the enforcement surfaces.

---

## Part 1 — WP5/M9: the disambiguation and the renames (2026-07-21)

**The core split.** Bare **"pause"/"stop"/"hold"** = a *turn-level interrupt* —
no skill, no artifact, nothing written. The *session-boundary* handoff is the
expensive branch that writes `workflow-system/state/.session.md`.

**Three renames:**

| Before | After | Why |
|---|---|---|
| `session-pause` | `session-handoff` | bare "pause" now means turn-level |
| `session-resume` | `session-restore` | avoids the built-in `/resume` collision; matched-pair verb with `handoff` |
| `session-store-learning` | `session-capture` | "store" fuzzy-collided with `/re**stor**e` |

`/project-handoff` was reserved for the cross-repo analogue (shipped as WP8/M12).

### The load-bearing lesson: the fuzzy-matcher searches DESCRIPTIONS, not just names

A skill whose *description* contains a competing prefix's substring shadows the
intended target of that prefix. WP5 found `incident-mitigate`'s "restore
service" out-ranking `/session-restore` — and reframed it plus two other
descriptions. This is why the collision guard checks both fields.

WP5 hit naming collisions **three ways** in one feature (two name collisions +
one description collision), which is what promoted this from an observation to a
rule.

### Grounding

A **387-turn / 11-project raw-log audit** (`tmp/pause-terminology-audit.md`,
gitignored) established the ambiguity was real and frequent. It also proved the
WP6-style *"one word, two costs, confirm-before-expensive"* pattern transfers
across domains — the same shape as the research cost-tier disambiguation.

### The guard is CONTEXTUAL, not universal (operator correction)

The first cut was a blanket "never write `.session.md` unless intent is explicit
or confirmed." The operator corrected it to key on **workflow position**:

- **Clean workflow boundary** (post finalize/close/resolve → reflect, or post
  `session-capture`) → the handoff **auto-chains, no confirm** — even in
  autopilot/FSD. Demanding "are you sure?" here is friction, not safety.
- **Mid-workflow ambiguity** → **ask one line** first.

The over-reach is **bidirectional**: an adjacent "defer"/"wrap up" can pull
toward an unwanted handoff with no "pause" utterance at all. A real misfire cost
a stray `.session.md` and an `rm` — an agent read "defer that check" mid-verify
as a session handoff.

### `/resume` ≠ `/session-restore` — the exact conflation to avoid

`/resume` (harness built-in) continues **this turn** after a turn-level hold.
`/session-restore` restores a **written handoff** across sessions. So the
going-offline family — *"I need to go"*, *"I'll `/resume` later"*, *"hold, I'm
shutting down"* — is turn-level **HOLD, not a handoff cue**. A second live
misfire pinned this one.

### Enforcement + fallout

`tests/check-structure.sh` [Phase 17] — 14 pins, including a mechanical
`/restore` name+description collision guard, the contextual-guard pins, and the
`/resume`-is-turn-level anti-trigger. Behavioral scenarios:
`tests/scenarios/session.yaml::{S26-handoff-guard-turn-level-pause,
S27-handoff-guard-going-offline-is-turn-level}`.

Renamed skill dirs required re-running `install.sh`, which is **additive-only** —
orphan old-name symlinks were pruned by hand.
`SURFACE-2026-07-21-INSTALL-SH-NO-ORPHAN-PRUNE` tracks adding a prune pass.

Resolves `SURFACE-2026-07-20-CLAUDESK-PAUSE-AMBIGUITY`.

---

## Part 2 — Modeling the exit chain in the state machine (2026-07-21)

WP5 shipped its chaining rule as **advisory prose only**. The state machine
didn't model it: reflect was the terminus, `session-handoff` was declared "not a
state" with no edge, and the drive-mode pause tables had **zero rows** for it.

That is the **same drift class as the P1 autopilot-pause incidents** — a
chaining decision asserted in prose with no transition ID and no table row. So
this feature promoted the full `finalize → reflect → [capture] → handoff` exit
chain from prose into the state machine.

### Two design decisions

**D1 — no `finalize → handoff` shortcut.** Reflect is always run: it is the only
step that can judge "nothing to persist," and it is the once-per-session
learning backstop. The fork happens *at* reflect:

- **no-learning arm** → `S22` (reflect → session-handoff)
- **learning-found arm** → `session-capture` → `S23` (capture → session-handoff),
  after the save lands

**D2 — meta-op edges + pause-policy rows, NOT first-class dispatched states.**
The `transitions.md:438` "not a state" declaration is preserved. This is
consistent with reflect and capture already being meta-ops.

Both edges are AUTO in all drive modes at a clean boundary; the
mid-workflow-ambiguity CONFIRM is the narrow exception. The guard prose was
re-pointed to *"read the table row, not this bullet."*

### The one real behavior change: AC-6 capture-gate conditional drop

Everything else models already-shipped behavior. This doesn't.
`session-capture` §4's confirmation gate is now drive-mode-conditional:

| Drive mode | `[PROJECT]` scope | `[GLOBAL]` scope |
|---|---|---|
| autopilot / FSD | **auto-write** | **still confirms** |
| 1 / 2 | confirms | confirms |

The auto-write is surfaced as a **read-time veto** — path, content, and scope
printed before the `git amend`, so a `git reset` is the operator's veto.

`[GLOBAL]` keeps its gate because the blast radius is higher, and because
**every one of the 15 logged reflect scope-corrections was `[GLOBAL]`→`[PROJECT]`,
none the other way.**

This conditional is what lets the boundary exit chain auto-run all the way to
the handoff for the common project-scope case without ever making a blind global
write.

### Enforcement

`tests/check-structure.sh` [Phase 18] — S22/S23 edges, the exit-chain block in
`transitions.md` + all 4 AGENTS.md, the guard re-point, the capture
conditional-gate clauses, and the snippet re-point. Behavioral scenarios:
`tests/scenarios/session.yaml::{S28-boundary-reflect-nothing-autochains-handoff,
S29-boundary-guard-mid-workflow-defer-confirms,
S30-capture-gate-project-autowrites-global-confirms}`.

> **Note the two "S" namespaces.** Scenario IDs S28–S30 are DISTINCT from the
> transition IDs S22/S23.

As-built architecture: `arch.md` → AD-4 addendum. Resolves
`SURFACE-2026-07-21-BOUNDARY-HANDOFF-AUTOCHAIN-NOT-IN-STATE-MACHINE`.
