# `session-reflect` candidate filter, scope-default, and 3-tier presentation

Shipped 2026-07-03 by the `reflect-store-filter-rules` feature.

`session-reflect` used to present *every* candidate learning for a store
decision, which meant the operator pruned the list ~3–4× by hand every session.
It now **pre-filters and pre-scopes**.

Derived from an audit of **all 145 real `session-reflect` invocations across 8
projects** (`tmp/reflect-learnings-audit.md`, gitignored).

All three rules are *behavior-within-state*: no new transition, reflect still
emits no token, and it still prompts `/session-capture` for survivors.

---

## Rule 1 — DROP gates (§2a)

Suppress:

- **workflow/process commentary** — unless it independently clears the
  `[GLOBAL]` gate below
- **single-observation generalizations** — one sighting is not a pattern
- **self-documenting restatements** — a "learning" that just re-says what the
  artifact already says

## Rule 2 — the already-persisted tier (§2a)

A learning already captured somewhere a future session would see it is surfaced
**with a cited location**, and is NOT offered for storage.

**Fail-safe:** no citation → it stays a store candidate. Never silently dropped
on an uncited claim of "already covered."

## Rule 3 — scope-default `[PROJECT]` (§2b)

Default every store candidate to `[PROJECT]`. Promote to `[GLOBAL]` only when
**all three** hold:

1. It is about the workflow/agent-operation itself — not a codebase's domain or
   stack.
2. It would change behavior in an unrelated, different-stack project.
3. It names the specific cross-project mechanism.

**The evidence for defaulting this direction:** every one of the **15 logged
operator scope-corrections was `[GLOBAL]`→`[PROJECT]`** — none went the other
way.

### The mccc carve-out

In **this** repo the workflow system *is* the domain. So `[GLOBAL]`-flavored
workflow-mechanism learnings are legitimately common here and are tracked
first-class — the scope-default is a prior, not a ceiling.

---

## Presentation — three tiers

1. **Store candidates** — labeled, decision-bearing.
2. **Already-persisted** — cited location, no decision asked.
3. **"Considered and dropped"** — one-line collapsed, so the veto stays
   auditable rather than invisible.

## Downstream intake note

`session-capture` §1 gained a matching note: respect the incoming scope label,
do **not** re-run the reflect filter, and tier-2/tier-3 items are never routed
here.

## Enforcement

- Structural: `tests/check-structure.sh` [Phase 12] — 6 `grep_check` pins.
- Behavioral: `tests/scenarios/session.yaml::R1-reflect-scope-default-project`
  (a REAL logged STORE-DIFFERENT-SCOPE case, replicator `eeb4d4c3`),
  `R2-reflect-already-persisted-cited`,
  `R3-reflect-process-commentary-dropped`.

Reflect emits no transition, so all three assert on output prose via
`contains_any` → SOFT_PASS.

## Decoupled sibling

Feature 2 of the same planning batch — the project-memory location symlink — was
kept separate and spike-gated. See `tmp/temp-wbs-reflect-memory.md` and the root
`CLAUDE.md` project-memory bullet.
