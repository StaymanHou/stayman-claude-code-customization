---
shape: lesson
created: 2026-06-30
status: candidate-for-handback
target-repo: my-claude-code-customization (the workflow-system source repo, symlinked into Claudesk at _ref/claude-customization/)
origin-session: claudesk 2026-06-30 — between-M8-and-M9 debt-paydown sweep
---

# Lesson: The Between-Milestone Debt-Paydown Sweep

> **This doc is a HAND-OFF artifact.** It was authored in the **Claudesk** project but is meant to be
> **processed by the `my-claude-code-customization` workflow-system project** (the repo that owns the
> skills/orchestrators; symlinked into Claudesk at `_ref/claude-customization/`). Claudesk does NOT
> codify the skill or run the cross-validation itself — those are the workflow-system project's job.
> Claudesk's only role was to capture this pattern the first time it was run here with an explicit
> rule set.
>
> **Hand-back directive (for a CC session working IN the `my-claude-code-customization` repo):**
> This pattern — a hand-authored *temporary WBS* to clear a non-roadmap backlog between milestones,
> with a deliberate disposition rule set — is a **candidate to codify as a skill** (candidate name:
> `product-debt-paydown` or `product-sweep`) or as a documented variant of a `temporary-wbs` shape.
> **Before codifying:**
> 1. **Find the OTHER instance for cross-validation.** The operator (Stayman) ran a *similar*
>    backlog-sweep process **in a DIFFERENT project on this same machine** (NOT Claudesk — he does
>    not recall which project). That other session is the **second test case** for these rules.
>    Locating it is **the workflow-system project's job** — search across the operator's projects on
>    this machine (other `docs/product/*-wbs.md` temporary-WBS files, session transcripts mentioning a
>    "sweep" / "backlog cleanup" / "debt paydown" / a hand-authored non-milestone WBS). Do NOT assume
>    it's a Claudesk artifact.
>    - *(Note: Claudesk itself ALSO has a prior temporary-WBS instance — the 2026-06-24 QoL/lifecycle
>      sweep, `docs/product/qol-wbs.md`, commit `c9f70ab`, retired at M6. But that one was a
>      FEATURE/BUG collection, not a code-quality/debt sweep — see "Two distinct uses of the vehicle"
>      below. It is a useful contrast case but is NOT the cross-validation session the operator meant.)*
> 2. **Cross-validate the rules below against that other-project session** — apply this doc's
>    disposition model to the items that session actually included/excluded; check whether the model
>    *predicts* the operator's real choices. Where it diverges, the model is wrong or incomplete —
>    refine it.
> 3. **Then double-check with the operator** before codifying — he asked for exactly this
>    cross-validation step. The two sessions (this one + the other-project one) are the regression
>    suite for the skill.

---

## What this is

A **between-milestone debt-paydown sweep**: a focused pass that clears accumulated code-quality
findings + small hygiene/decision items from the backlog, run as a **temporary WBS that is NOT a
roadmap milestone** and is **deleted on completion** (fold-back-and-delete).

It is distinct from:
- **`/feature-refactor`** — per-feature, cleanup-only, scoped to one shipped feature's diff. The
  sweep *batches* many features' deferred refactor-findings into one deliberate cycle.
- **A roadmap milestone** — the sweep reserves no permanent roadmap slot; milestone numbering is
  untouched. It's scratch work between milestones.
- **`/product-finalize`'s backlog sweep** — finalize *records dispositions* at a cycle boundary but
  doesn't *do the work*; the debt-paydown sweep is where the deferred work actually gets done.

## When to trigger it

- A clean cycle boundary (a milestone just closed, nothing in flight) — low switching cost.
- The standing code-quality backlog has grown across several milestones (every cycle-close kept
  rolling a "future `/feature-refactor` batch" forward without ever running it).
- Before a milestone that will *read* a lot of the affected code (cleaner surface helps), or before
  an open-source / release push (the backlog clutter + stale docs are visible).
- Operator explicitly asks to "address some of the backlog / code-quality findings."

## The disposition model (the core reusable artifact)

Score every backlog item on **three axes**, assign **one of five actions**.

### Three axes
- **Impact** = feature value **+** maintainability value, where
  **maintainability = code-quality × P(foreseeable future-touch or future-feature-friction)**.
  *Low-quality code that is isolated, frozen, or soon-to-be-replaced has ~0 maintainability impact.*
- **Effort** = benchmarked against the **living docs** (roadmap milestones + recently-archived WBS
  WPs + recently-archived WIP): **milestone-sized → Large; WP-sized → Medium; smaller → Small/XS.**
  *Most backlog findings land at Small/XS — intentional; see "why" below.*
- **Risk** = P(the change breaks something the **regression suite won't catch**). Relative to test
  coverage; a fix that *adds* the missing test lowers its own risk.

### Five actions
| Action | Meaning | Trigger |
|--------|---------|---------|
| **Sweep** | Fix now, in this WBS | **Rule 1:** low-effort + low-risk → ALWAYS include. **Rule 2:** high-impact + low/med-effort → include. |
| **Discuss** | Surface to operator; do not auto-decide | high-effort + high-impact; **OR** high-risk + any-impact. |
| **Defer** | Keep in backlog, anchored to a future milestone/pass | net-new feature; release-gated; high-effort routed to a dedicated pass. |
| **Bury** | Move to an **archived** backlog we'll likely never revisit; remove from active | low-impact + medium-effort + low-risk (the "meh" zone). |
| **Delete** | Remove entirely | no longer relevant, or already resolved-along-the-way. |

### Rules & their *why* (the why is the transferable part)
1. **Rule 1 (cheap + safe → always Sweep) has NO exception.** Even if the code looks doomed/about-to-
   be-replaced — *you can never truly know when code dies* (the ~5% survivor), and **closing the item
   de-clutters the backlog, which is itself an impact term.** A long backlog has carrying cost; closing
   an entry has value independent of the fix's value. → *Withdrawn during the 2026-06-30 session: an
   earlier "carve out an exception for imminently-changing code" proposal was rejected for exactly
   this reason.*
2. **Tiebreak: Rule 1 beats the impact calc.** Cheap + safe wins even at low value.
3. **Severity (MAJOR/MINOR) is an INPUT to impact, not a parallel sort key.** A reviewer's MAJOR
   usually means high impact (silent-regression vector) — but a MAJOR on frozen, isolated code scores
   low on maintainability. *Translate severity into the impact term; don't auto-prioritize by it.*
4. **Effort is the IMPLEMENTER's time, benchmarked against real archived units** — not abstract
   complexity. A 50-file mechanical rename is low-effort (fast for an agent); a 10-line change needing
   a live cross-the-MCP-bridge repro may be Medium. Benchmarking against *actual archived WPs/WIP*
   (not a felt sense) keeps the scale honest and explains why almost everything is Small/XS: a WP is
   already a sizable unit, and these are sub-WP findings. **That's the point** — it means Rule 1
   catches most of the backlog and only a handful escape to a real decision.
5. **Risk is suite-relative.** Well-covered ⇒ low-risk even if structurally large. A fix that adds the
   missing test is doubly good (raises maintainability impact AND lowers its own risk).
6. **The messy middle is explicit, not improvised:**
   - high-effort + high-impact → **Discuss** (don't auto-include/defer).
   - high-risk + any-impact → **Discuss** (the risk needs a plan — repro/test-first — before it's even
     an effort estimate).
   - low-impact + medium-effort + low-risk → **Bury** (the "meh" zone).

### Ordering rules (sort the already-Swept set; precedence top-down)
1. **Deletions before modifications** — pure subtraction can only shrink surface; lowest risk.
2. **Low-risk before high-risk** — bank safe wins; an interrupted sweep leaves nothing half-applied.
3. **Within a risk tier: high-impact before low-impact** — front-load value.
4. **Co-location adjacency** — WPs touching the same files run adjacent (cheaper re-reads, less churn).
5. **Effort is NOT an ordering key** — it gates inclusion, doesn't sort. (Avoids "do all the trivial
   stuff first, run out of steam before the items that mattered.")
   - **Tension resolved: risk outranks impact in ordering.** That's why deletions (often low-impact)
     still sort *first* — they're the lowest-risk thing there is, so the risk key fires before impact.
     (Operator was indifferent on the exact tiebreak — "as long as we have a rule set, follow it.")

## The process (end-to-end)

1. **Inventory.** Read the full backlog + any consolidated findings file (Claudesk keeps
   `workflow/backlog-quality-findings.md` — 62 sections of code-review findings). Dedup and **group
   the MINORs into themes** — ~50 individual findings collapse into ~9 repeated mistakes across many
   files. *Fix the theme once, not the instance N times.* (A subagent is good for this fan-out read —
   keeps the raw finding-dump out of the planning context.)
2. **Score & dispose.** Apply the model above → a table of (item, impact, effort, risk, action).
3. **Surface the Discuss items to the operator** with *grounded* detail — read the actual code, don't
   trust the backlog summary (in 2026-06-30, the backlog *overstated* one MAJOR: the editor-shell
   leaf-symlink hole was narrower than written — the parent IS canonicalized, only the leaf isn't).
   For each Discuss item, the lowest-risk option is usually **"make the code honest"** (delete the dead
   path / fix the lying doc / honor a stated demote-plan); the higher-effort option is "build the thing
   the dead code gestured at." Present both; let the operator rule.
4. **Author the temporary WBS** (`shape: temporary-wbs`, priority/risk-ordered WPs, an explicit
   "what's NOT swept — anchors intact" scope section, a fold-back-and-delete completion section).
5. **Build** — each WP through the normal `/feature-refactor` or `/task-*` loop so finalize/close
   auto-resolves the findings + appends to CHANGELOG.
6. **Fold back & delete** — confirm RESOLVED, execute the Bury/Delete actions, delete the WBS file.

## What's Claudesk-specific vs. universally reusable

*(The operator explicitly asked "what might differ for this particular project." Split it out so the
hand-back is portable.)*

**Universal (lift directly into the skill):**
- The 3-axis model + 5-action vocabulary + the rule set + their *why*.
- The ordering rules.
- The temporary-WBS vehicle + fold-back-and-delete lifecycle.
- "Theme over instance" for MINOR batches.
- "Read the real code before deciding a Discuss item — backlog summaries drift/overstate."
- "Make the code honest" as the default low-risk option for dead/lying-doc findings.
- Trigger conditions (clean cycle boundary, accrued rolled-forward refactor batch, pre-release).

**Claudesk-specific (parameterize or note as project-dependent):**
- The **consolidated `workflow/backlog-quality-findings.md`** file — Claudesk separates terse backlog
  *pointers* from full review findings. A project without this split inventories from the backlog +
  per-WIP `## Code-Quality Review` sections instead.
- The **MCP-bridge verify-self tier** (`mcp__tauri__*`, dev-only, 127.0.0.1:9223) — Claudesk's way to
  agent-drive live verify-self on a native Tauri app. A web project uses the browser driver; a CLI
  project uses stdout assertions. The *principle* ("push correctness into unit/snapshot tests; reserve
  a full-UI driver for the sparse end-to-end gate") is universal; the specific driver is not.
- The **Rust + TypeScript two-language drift theme** (Theme H: a predicate/id/union encoded in both
  languages with only-prose linkage) — sharp in a Tauri app; a single-language project won't have it.
- **`tooling/demo/` dev-only nits** — Claudesk has a dev-only demo-asset pipeline; its findings are
  near-zero maintainability impact (regenerable, isolated) yet still Sweep under Rule 1.
- **Effort benchmark units** — "WP-sized = Medium" presumes this project's WBS granularity. Another
  project's WP may be larger/smaller; benchmark against *that* project's archived units.
- The **release-gate DEFERRED-TO-RELEASE** cluster — Claudesk verifies installed-`.app` behavior at a
  manual `/release` gate (unsigned Homebrew tap). A project with CI-verified releases disposes those
  differently.

## Two distinct uses of the temporary-WBS vehicle (a distinction the codified skill must resolve)

The *vehicle* (a hand-authored `shape: temporary-wbs`, priority-ordered WPs, fold-back-and-delete, no
roadmap slot) has been used for **two different KINDS of sweep** — the workflow-system project should
decide whether they are one skill (two modes) or two skills:

1. **Feature/bug collection sweep** — clears net-new capability gaps + bugs between milestones (e.g.
   Claudesk's 2026-06-24 QoL sweep: close-a-workspace, a status bug, fs-watcher). The disposition
   model in THIS doc would route most of those to a *milestone/Defer*, not a sweep — so the 3-axis
   model is **NOT tuned for this kind.** A feature-collection sweep is closer to a mini-roadmap.
2. **Code-quality / debt-paydown sweep** — pays down review findings on *already-shipped* code (this
   2026-06-30 session). The 3-axis model is tuned for exactly this.

A telling relationship between the two: a feature sweep that *explicitly defers its code-quality tail*
("handled separately via `/feature-refactor`") is what *creates* the backlog a later debt sweep pays
down. So the two kinds are sequential, not competing — and the model's "a feature sweep shouldn't
absorb the code-quality tail" lean is consistent with how both ran.

## Refinements the cross-validation should test for (open questions for the codifier)

When the workflow-system project locates the operator's **other-project sweep session** (directive #1
at the top) and applies these rules to it, watch specifically for:
- **One skill or two?** Does the other session look like a feature-collection sweep or a debt sweep —
  and does that argue for a mode switch vs. two skills?
- **Operator veto as a first-class trigger.** In practice the operator sometimes *vetoes* an item
  outright ("not wanted" / "not a problem in practice") — a Delete/Defer that bypasses axis-scoring.
  The 3-axis model doesn't name this; decide whether to add "operator veto" as an explicit trigger or
  treat it as just a Discuss outcome.
- **Effort-benchmark portability.** This doc benchmarks effort against *Claudesk's* WBS/WIP units. The
  other project's units differ — confirm the "milestone=Large / WP=Medium / smaller=Small-XS" scale
  still produces sane scores when re-anchored to that project's archived work.
- **Does the model PREDICT the operator's real includes/excludes** in the other session? Where it
  does, it's sound; where it diverges, the model is incomplete — refine before codifying.
