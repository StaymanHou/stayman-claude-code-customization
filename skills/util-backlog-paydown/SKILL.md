---
name: util-backlog-paydown
description: "Between-milestone backlog-paydown sweep: inventory the standing backlog + code-quality findings at a clean cycle boundary, score each item on a 3-axis disposition model, surface the judgment calls, and emit a priority/risk-ordered temporary-wbs that pays the deferred work down. Operator-triggered standalone utility."
argument-hint: "<optional mode: 1=Step-by-step | 2=Batch-approve | 3=Autopilot | 4=Dry-run> — defaults to 2"
---

# Backlog-Paydown Sweep

You are an expert Technical Lead running a **between-milestone backlog-paydown sweep** — a focused pass that
clears accumulated code-quality findings + small hygiene/decision items from the standing backlog, run as a
**temporary WBS that is NOT a roadmap milestone** and is **deleted on completion** (fold-back-and-delete).

## Category

**`util-*` — standalone user-triggered utility.** This skill is NOT part of any workflow state machine. It
emits **no workflow transitions** (no F/I/T/P/S tokens) and **no `RETURN-TO:`** — it is not a state reached by
a transition, and it is not a `debug-*` sidebar pulled by another workflow. The operator invokes it manually
via `/util-backlog-paydown` at a clean cycle boundary. It produces a `shape: temporary-wbs` file that the
operator then drives through the normal `/feature-*` and `/task-*` workflows. See `workflow-system/product/arch.md` →
Revision 2026-06-13 → `util-*` skill category for the convention, and
`docs/lessons/between-milestone-debt-paydown-sweep.md` for the full pattern + its provenance.

## What it does

Over several milestones a project accumulates a standing backlog of deferred code-quality findings (every
cycle-close keeps rolling a "future `/feature-refactor` batch" forward), small hygiene SURFACEs, and the odd
decision item. This skill clears that pile in one deliberate pass:

1. **Inventory** the backlog + any consolidated findings file; dedup; group repeated MINORs into themes.
2. **Score** every item on three axes and assign one of five actions.
3. **Surface** the judgment-call items to the operator with grounded detail.
4. **Emit** a priority/risk-ordered `shape: temporary-wbs` file with an explicit "what's NOT swept" scope
   section and a fold-back-and-delete completion section.
5. The operator drives each WP through the normal `/feature-refactor` or `/task-*` loop, then **folds back
   and deletes** the temporary WBS.

It is distinct from:
- **`/feature-refactor`** — per-feature, cleanup-only, scoped to one shipped feature's diff. This sweep
  *batches* many features' deferred refactor-findings into one cycle.
- **A roadmap milestone** — the sweep reserves no permanent roadmap slot; milestone numbering is untouched.
- **`/product-finalize`'s backlog sweep** — finalize *records dispositions* at a cycle boundary but does not
  *do the work*; this sweep is where the deferred work actually gets done. (`product-finalize` carries an
  advisory pointer here.)

## When to use

- A **clean cycle boundary** — a milestone just closed, nothing in flight → low switching cost.
- The **standing code-quality backlog has grown** across several milestones (the deferred `/feature-refactor`
  batch was rolled forward every cycle-close without ever running).
- **Before a milestone that will read a lot of the affected code** (cleaner surface helps), or **before an
  open-source / release push** (backlog clutter + stale docs are visible).
- The operator explicitly asks to "address some of the backlog / code-quality findings."

## When NOT to use

- **Mid-flight** — there is an active feature/incident in `workflow-system/state/wip/`. Finish or pause it first; a sweep
  mutates many small surfaces and races with in-flight work.
- **The backlog is net-new feature work, not debt.** A pile of capability gaps + bugs is a mini-roadmap, not
  a debt sweep — most of it scores to Defer/milestone under the model below. (The disposition model still
  *routes* such items correctly; it just means few will Sweep. If almost everything Defers, you wanted
  roadmap/WBS planning, not this.)
- **A single finding** — just run `/feature-refactor` or `/task-plan` directly. The sweep's value is batching.

## Mode menu (pick at entry)

Modes mirror the workflow drive modes (1–4) in aggression spectrum. Default is **Mode 2**.

| Mode | Name | Behavior |
|---|---|---|
| **1** | **Step-by-step** | Present one scored item at a time with its disposition + rationale; operator approves / revises / vetoes per item. Apply on approval. Most control, slowest. |
| **2** | **Batch-approve** (default) | Score the whole inventory, surface ONE disposition table (item · impact · effort · risk · action) plus the grounded Discuss items; operator approves the batch (or names individual revises/vetoes); then emit the temporary-wbs. |
| **3** | **Autopilot** | Auto-apply the unambiguous dispositions — every Rule-1 Sweep, every Delete of an explicitly-superseded item — and **only** pause to surface the Discuss items (which by definition need a ruling). Emit the temporary-wbs with the Discuss outcomes folded in once ruled. |
| **4** | **Dry-run** | Score + surface the full disposition table and the would-be temporary-wbs; write NOTHING. Operator re-invokes in 1/2/3 if they like it. |

```
Mode menu — pick how the sweep runs:
  1  Step-by-step   one scored item at a time, approve/revise/veto per item
  2  Batch-approve  one disposition table + grounded Discuss items, approve the batch   ← default
  3  Autopilot      auto-apply the unambiguous dispositions, pause only on Discuss items
  4  Dry-run        score + show the table and the proposed WBS, change nothing
```

## The disposition model

Score every backlog item on **three axes**, assign **one of five actions**. This model is the load-bearing
artifact — the rules ARE the contract, and the *why* of each rule is the transferable part. (Canonical
statement: `docs/lessons/between-milestone-debt-paydown-sweep.md`.)

### Three axes

- **Impact** = feature value **+** maintainability value, where
  **maintainability = code-quality × P(foreseeable future-touch or future-feature-friction)**.
  Low-quality code that is isolated, frozen, or soon-to-be-replaced has **~0 maintainability impact** —
  refactoring it is near-worthless.
- **Effort** = benchmarked against **the consuming project's own living docs** (its roadmap milestones +
  recently-archived WBS WPs + recently-archived WIP): **milestone-sized → Large; WP-sized → Medium; smaller
  → Small/XS.** *Read this project's recently-archived units first to anchor the scale — do not import another
  project's calibration.* By this scale almost every backlog finding is Small/XS — **intentional**: a WP is
  already a sizable unit and these are sub-WP findings, so Rule 1 catches most of the backlog and only a
  handful escape to a real decision.
- **Risk** = P(the change breaks something the **regression suite won't catch**). Risk is **relative to test
  coverage** — a well-covered change is low-risk even if structurally large, and a fix that *adds* the missing
  test lowers its own risk.

### Five actions

| Action | Meaning | Trigger |
|--------|---------|---------|
| **Sweep** | Fix now, in this WBS | **Rule 1:** low-effort + low-risk → ALWAYS include. **Rule 2:** high-impact + low/med-effort → include. |
| **Discuss** | Surface to operator; do not auto-decide | high-effort + high-impact; **OR** high-risk + any-impact. |
| **Defer** | Keep in backlog, anchored to a future milestone/pass | net-new feature; release-gated; high-effort routed to a dedicated pass. |
| **Bury** | Move to an **archived** backlog we'll likely never revisit; remove from active | low-impact + medium-effort + low-risk (the "meh" zone). |
| **Delete** | Remove entirely | no longer relevant, or already resolved-along-the-way. |

> **Note (delete-on-resolve, 2026-07-15):** the "already resolved-along-the-way" Delete trigger should now be **rare** — the four terminal-close skills delete a backlog entry *on resolve* (see `CLAUDE.snippet.md` → `## CHANGELOG.md convention` → `### Append discipline`), so resolved clutter no longer accumulates for a sweep to clean. If you find a pile of stale `Status: resolved` entries here, that's a signal a close skill skipped the delete — Delete them and note the gap; don't treat it as normal backlog state.

### Rules & their *why* (the why is the transferable part)

1. **Rule 1 (cheap + safe → always Sweep) has NO exception.** Even if the code looks doomed/about-to-be-
   replaced — *you can never truly know when code dies* (the ~5% survivor) — and **closing the item de-clutters
   the backlog, which is itself an impact term.** A long backlog has carrying cost; closing an entry has value
   independent of the fix's value. (A "carve out an exception for imminently-changing code" proposal was
   explicitly rejected for exactly this reason.)
2. **Tiebreak: Rule 1 beats the impact calc.** Cheap + safe wins even at low value (de-clutter).
3. **Severity (MAJOR/MINOR) is an INPUT to impact, not a parallel sort key.** A reviewer's MAJOR usually
   means high impact (silent-regression vector) — but a MAJOR on frozen, isolated code scores low on
   maintainability. Translate severity into the impact term; don't auto-prioritize by it.
4. **Effort is the IMPLEMENTER's time, benchmarked against real archived units** — not abstract complexity.
   A 50-file mechanical rename is low-effort (fast for an agent); a 10-line change needing a live cross-the-
   bridge repro may be Medium. Benchmarking against *actual archived WPs/WIP* keeps the scale honest.
5. **Risk is suite-relative.** Well-covered ⇒ low-risk even if structurally large. A fix that adds the missing
   test is doubly good (raises maintainability impact AND lowers its own risk).
6. **The messy middle is explicit, not improvised:**
   - high-effort + high-impact → **Discuss** (don't auto-include/defer).
   - high-risk + any-impact → **Discuss** (the risk needs a plan — repro/test-first — before it's even an
     effort estimate).
   - low-impact + medium-effort + low-risk → **Bury** (the "meh" zone).

### Operator veto (first-class trigger)

The operator may **veto** any item outright — "not wanted", "out of scope by design", "gated on a precondition
that hasn't been met" — **independent of the axis scores**. A veto is a first-class disposition, not a Discuss
outcome: record it directly as **Delete** (no longer wanted / out of scope) or **Defer** (gated; anchored to
the unmet precondition), with the operator's stated reason. Do NOT force a vetoed item back through axis
scoring. *(In practice this fires often — e.g. "delete: this is out of scope by the project's Docker-first
design"; "defer: gated until the new pipeline soaks in prod for a few weeks".)*

### Scoring fidelity — two paths

- **Full tabulation** (raw/messy backlog): produce the complete `(item, impact, effort, risk, action)` table.
  Use when the backlog is ungroomed and the scores are not obvious.
- **Light-touch prose** (pre-groomed bucket): when the operator has already groomed items into a bucket and
  confirmed them cheap+safe, a one-line prose rationale + a size estimate per item is sufficient — do not force
  a full matrix for items already known to Sweep. (Both real precedent sessions used this for their easy-wins
  buckets.)

### Ordering rules (sort the already-Swept set; precedence top-down)

1. **Deletions before modifications** — pure subtraction can only shrink surface; lowest risk.
2. **Low-risk before high-risk** — bank safe wins; an interrupted sweep leaves nothing half-applied.
3. **Within a risk tier: high-impact before low-impact** — front-load value.
4. **Co-location adjacency** — WPs touching the same files run adjacent (cheaper re-reads, less churn).
5. **Effort is NOT an ordering key** — it gates inclusion, doesn't sort (avoids "do all the trivial stuff
   first, run out of steam before the items that mattered").

**Cross-cutting note — risk outranks impact in ordering.** This is why deletions (often low-impact) still
sort *first*: they are the lowest-risk thing there is, so the risk key (rule 2) fires before the impact key
(rule 3). The precedence is risk → impact, not impact → risk.

## Procedure

### 1. Pick mode + confirm the boundary

Read the mode argument (default 2). Confirm a clean cycle boundary — check `workflow-system/state/wip/` is empty (or that
the operator has consciously chosen to sweep alongside in-flight work). If a feature/incident is active, say so
and recommend finishing/pausing it first (see "When NOT to use").

### 2. Inventory

Read the full backlog (`workflow-system/state/backlog.md`) plus any consolidated findings file the project keeps (some
projects split terse backlog *pointers* from full review findings into e.g. `workflow-system/state/backlog-quality-findings.md`;
a project without that split inventories from the backlog + per-WIP `## Code-Quality Review` sections instead).
**Dedup, and group repeated MINORs into themes** — ~50 individual findings often collapse into ~9 repeated
mistakes across many files; *fix the theme once, not the instance N times.* A subagent is good for this
fan-out read — it keeps the raw finding-dump out of the planning context.

Then **benchmark effort**: read this project's recently-archived WBS WPs + WIP to anchor the Large/Medium/Small
scale to *this* project's granularity before scoring.

### 3. Score & dispose

Apply the disposition model → a table of `(item, impact, effort, risk, action)` (full tabulation), or a
light-touch prose disposition for any pre-groomed bucket. Apply operator vetoes as first-class Delete/Defer.

### 4. Surface the Discuss items — grounded

For each **Discuss** item, **read the actual code — do not trust the backlog summary** (backlog summaries
drift and overstate; in a real session the backlog overstated a MAJOR's blast radius). For each Discuss item,
the lowest-risk option is usually **"make the code honest"** — delete the dead path / fix the lying doc /
honor a stated demote-plan; the higher-effort option is "build the thing the dead code gestured at." Present
both, let the operator rule. Fold the rulings back into the disposition set.

(Mode 2: surface the whole table + Discuss items in one block. Mode 1: one item at a time. Mode 3: auto-apply
the unambiguous dispositions, surface only the Discuss items. Mode 4: surface everything, write nothing.)

### 5. Author the temporary WBS

Write `workflow-system/product/<sweep-name>-wbs.md` (or the project's WBS location) with:
- Frontmatter: `shape: temporary-wbs`, `cycle:` / `created:`, `status:`, `parent-backlog:` pointer.
- A header stating this is **NOT a roadmap milestone** and will be **deleted on completion**.
- The disposition model (reproduced or referenced) so the build sessions apply the rules consistently.
- **Priority/risk-ordered WPs** (per the ordering rules) — each WP names its `[impact · effort · risk]` and the
  backlog finding(s) it resolves.
- An explicit **"Scope — what's NOT swept (anchors intact)"** section listing every Defer/Bury/Delete with its
  reason + anchor (which future milestone/pass/release-gate it's anchored to).
- A **fold-back-and-delete completion** section: on completion, confirm each finding RESOLVED, execute the
  Bury/Delete actions, and delete this WBS file.

### 6. Hand off

Tell the operator to drive each WP through the normal `/feature-refactor` (cleanup) or `/task-plan` (atomic)
loop so finalize/close auto-resolves the findings + appends to `CHANGELOG.md`. When all WPs are done, the
operator (or a later sweep) executes the fold-back-and-delete.

This skill **emits no transition token** — it ends here. The operator drives the emitted WBS via the normal
workflows.

## Pitfalls (load-bearing — read before sweeping)

- **Do not paraphrase Rule 1's exception away.** "Cheap + safe → always Sweep, *no exception*" is the rule;
  the de-clutter-is-impact *why* is what makes it hold even for doomed code. Softening it ("...unless the code
  is about to be replaced") reintroduces the rejected exception.
- **Effort is consuming-project-relative.** Anchor to *this* project's archived units, never a fixed LOC count
  or another project's calibration.
- **Read the real code before ruling a Discuss item.** Backlog summaries overstate; the honest fix is often
  smaller (or different) than the summary implies.
- **A feature-collection backlog is not a debt sweep.** If almost everything scores to Defer/milestone, stop —
  the operator wanted roadmap/WBS planning, not a paydown.
- **The temporary WBS self-deletes.** It reserves no roadmap slot and is folded-back-and-deleted on completion
  — do not leave it as a permanent doc or treat it as a milestone.
