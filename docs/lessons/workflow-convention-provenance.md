# Workflow-convention provenance

Detail for five workflow conventions whose **rules** live in the root `CLAUDE.md`
(or in `CLAUDE.snippet.md`, where noted) as one-line pointers. This doc holds the
mechanics, the enforcement surfaces, and the evidence that produced each one.

---

## 1. Design priors — consult + capture

`workflow-system/product/design-priors.md` is a per-project, deterministically-loaded
record of the operator's **product-design decision leans** (focus-vs-breadth,
perf-vs-ship, anti-persona, …), each paired with an inferred-why **and** a
corrected-why — the gap between them preserved as the learning signal.

It exists to fill the ~10% of product-design gaps where the operator's
project-specific lean differs from the "average" common-sense fill, without
re-teaching it every feature. **The 90% common-sense path is untouched.**

**Consult** — three planning skills at Step 0: `product-roadmap`, `product-wbs`,
`feature-spec`. Five weighting rules govern it; the two load-bearing ones are the
**over-infer guard** (a prior only fires on the axis it actually governs — never
stretch it) and **contradiction → propose, never steer**.

**Capture** — six checkpoints plus a `session-reflect` backstop, all
**propose-never-auto-write**: the operator reviews and enriches the why, and new
priors are dedup/conflict-checked first. Technical and stack tradeoffs are
**excluded** — those stay in `arch.md`.

**Disclosure form** when a prior fires: `[PRIOR: <slug>] leaning <x> — flag if
wrong`. Priors are directional and overridable, never decisive.

- Canonical contract: `CLAUDE.snippet.md` → `## Design priors (GLOBAL)`
- Schema: `arch.md` → File Schema: Design Priors
- Enforcement: `tests/check-structure.sh` [Phase 13] + behavioral scenarios
  `tests/scenarios/product.yaml::DP-*` (consult-changes / over-infer-NOCHANGE /
  no-prior-90%-path / contradiction / capture-fires / capture-skips-fact /
  capture-skips-arch)

**Reverting:** git tag `pre-design-priors` for a full rollback, or
`grep -rl "design prior\|design-priors\|\[PRIOR:" skills/ docs/ CLAUDE.snippet.md tests/`
for surgical removal — see the feature's archived WIP → `## Reverting this
feature`. This is behavioral/prose-only and was flagged at build time as
carrying over-noise risk, hence the easy-revert net.

Shipped 2026-06-26 from the `infer-dev-intent-one-level-deeper` learning.

---

## 2. `util-backlog-paydown` — the between-milestone debt sweep

A `util-*` standalone operator-triggered skill
(`skills/util-backlog-paydown/SKILL.md`) that runs a focused pass at a clean
cycle boundary to clear the accumulated code-quality/debt backlog — the
rolled-forward `/feature-refactor` batch.

**3-axis disposition model:**

- **Impact** = feature-value + maintainability, where maintainability =
  quality × P(future-touch)
- **Effort** — benchmarked against *the consuming project's own* archived
  WBS/WIP units
- **Risk** — suite-relative

**5 actions:** Sweep / Discuss / Defer / Bury / Delete.

**Load-bearing rule: cheap + safe → ALWAYS Sweep, no exception.** De-cluttering
the backlog is itself an impact term.

**Operator-veto is first-class** — a "not wanted / out-of-scope / gated" ruling
bypasses axis-scoring entirely and goes direct to Delete/Defer.

Supports dual scoring fidelity: a full table for a raw backlog, light-touch
prose+size for a pre-groomed bucket.

**Output** is a `shape: temporary-wbs` — explicitly NOT a roadmap milestone —
carrying a "what's NOT swept — anchors intact" scope section and a
**fold-back-and-delete** completion section. The operator then drives each WP
through `/feature-refactor` or `/task-*`.

As a `util-*` skill it emits **no transition** and is **not** wired into any
orchestrator (see `arch.md` → `util-*` category; no new `check-structure.sh` pin,
per the documented util-* status quo). `product-finalize` §4 carries an
**advisory**, non-chaining pointer to it.

Behavioral coverage: `tests/scenarios/util.yaml` — disposition cases
generalized/redacted from two real regression sessions (Claudesk 2026-06-30 debt
sweep; replicator-1-0 2026-06-20 sweep family), which are the model's regression
suite.

Full pattern + provenance + cross-validation:
`docs/lessons/between-milestone-debt-paydown-sweep.md`. Shipped 2026-06-30.

---

## 3. Review-finding suggested-actions are hypotheses, not specs

When executing a sweep (`/util-backlog-paydown` output) or a
`/feature-refactor` driven by code-quality review findings, treat each finding's
**suggested action as a hypothesis to verify against the code** — not a spec to
apply. **This holds for cheap+safe Sweep items too, not just Discuss items.**

At plan/act time, grep/read to confirm the suggested fix's *target actually
exists* and its *assumption holds* before writing the edit.

**Evidence — backlog-paydown-2026-07-13, three findings whose prescribed fixes
were wrong on contact:**

1. A suggested `## Category` → `## Category Context` rename would have **erased**
   the intentional util-*/debug-* category distinction. `## Category Context` is
   a *pinned* debug-* requirement; util-* has no pinned heading. Correct fix:
   document the divergence in `arch.md`.
2. A suggested pin anchor `start the container(s) yourself` **didn't literally
   exist** (the actual clause is capital-S), and a uniform
   `propose-never-auto-write` pin would have **failed** on `product-vision`'s
   comma-form "Propose, never auto-write."
3. A finding predicted "update the Phase-13 pins to match" — unnecessary, since
   those pins anchor on the `design-priors.md` substring rather than the heading —
   and its example heading name would have **mislabeled** a dual-purpose block.

**Distinct from** the `util-backlog-paydown` pitfall *"read the real code before
ruling a **Discuss** item — summaries overstate **scope**"*. That one is
summary-overstated *scope* on *Discuss* items. This one is the suggested *fix*
being wrong on *Sweep* items — the ones you dispositioned as trivial and would
otherwise apply unchecked.

---

## 4. Project-memory location — harness symlink + `.claude/` tracked-by-default

Shipped 2026-07-03 by the `memory-location-symlink` feature.

Project memories need to be **both** git-tracked and harness-auto-loaded. Those
used to be two different directories:

| Store | Tracked? | Auto-loaded? |
|---|---|---|
| repo `<proj-dir>/.claude/memory/` | yes | **no** |
| harness `~/.claude/projects/<slug>/memory/` | **no** | yes |

**Fix (Direction A):** the repo dir is the single real store; the harness path is
a **symlink** to it. One physical copy, tracked AND auto-loaded, no drift.

**Reusable primitive** at `tools/memory-link/`:

- `ensure-memory-link.sh` — idempotent link creation
- `migrate-memory.sh` — one-time merge / drift-keep-both / backup /
  `MEMORY.md`-rebuild
- `lib-slug.sh` — sourced slug computation
- 27-assertion suite at `tools/memory-link/test/run-tests.sh`

**The slug footgun.** `<slug>` = `realpath(proj-dir)` (`pwd -P`) with `/` and `.`
replaced by `-` — **NOT** raw `$PWD`. On macOS `/tmp` → `/private/tmp`, so any
code computing the slug must resolve the realpath first.

**Wired into two hosts** so every project converges regardless of workflow:
`product-context` §2c (product path) + `session-start` step 1 (the non-product
path — task/feature-only projects never reach `product-context`).

The one-time migration ran 2026-07-03 across 8 `workflow-system/product/`-bearing
projects (gospelherald excluded per operator). Backups were finalized and deleted
in-session — deliberately **not** a standing gitignore rule, per the operator:
don't put migration cruft in `CLAUDE.snippet.md`.

**Also codified:** `.claude/` is **TRACKED by default** — ignore only
`settings.local.json` plus, for non-source-repos, `.claude/learnings/`. Never
blanket-ignore `.claude/`. This closed the enforcement gap where only
`product-context` reconciled gitignore.

- Canonical: `CLAUDE.snippet.md` →
  `## Project-memory location — harness symlink (GLOBAL)` and
  `## Artifact tracking policy (GLOBAL)` → "The `.claude/` default is TRACK"
- Structural pins: `tests/check-structure.sh` [Phase 14]

---

## 5. Delete-on-resolve backlog convention

Shipped 2026-07-15 by the `delete-on-resolve-backlog-convention` feature.

When a terminal-close skill resolves a backlog item it **deletes** that item's
entry from `workflow-system/state/backlog.md` — rather than marking it
`Status: resolved` and leaving it in place. For a `feature-review-quality`
code-quality finding the two files are **coupled**: delete the full body in
`workflow-system/state/backlog-quality-findings.md` **and** its pointer-collapsed
stub in `backlog.md`.

The backlog files thus carry **only open work**; `CHANGELOG.md` is the **sole**
resolved-item record.

**CHANGELOG-then-delete hard invariant.** No backlog delete is permitted unless
the corresponding `**Backlog resolved:**` line lands in `CHANGELOG.md` in the
*same commit*. Write the CHANGELOG record first, then delete the backlog block,
then stage both together — the same discipline as append-before-`git mv`.

**Partial-resolution carve-out.** Only a *fully-resolved* item is deleted. A
partial resolution **rewrites** the entry down to the remaining open work; the
resolved sub-part still emits its `**Backlog resolved:**` line.

**Buried/deferred are untouched.** The `## Buried` section and
`workflow-system/state/backlog-deferred-*.md` are a different lifecycle —
delete-on-resolve fires only on *resolution*, never on deferring or burying.

This closed the gap where resolved-entry clutter regenerated after every
`/util-backlog-paydown` sweep and duplicated the CHANGELOG trail (origin
`SURFACE-2026-07-14-RESOLVED-ENTRY-AUDIT-TRAIL-CLUTTER`).

Behavior-within-existing-close-states — **no `transitions.md` change**, following
the close-commit-discipline precedent.

- Canonical convention: `CLAUDE.snippet.md` → `## CHANGELOG.md convention` →
  `### Append discipline`
- Enforcement: `tests/check-structure.sh` [Phase 11] delete-on-resolve
  `grep_check` pins (4 close skills + 1 snippet) + behavioral scenarios
  `tests/scenarios/{feature,task,incident,product}.yaml::*-delete-on-resolve`
  (mirroring the `F19-no-auto-push` side-effect shape)

`util-backlog-paydown` needed no functional change — its `Delete` disposition
already covers "already resolved"; a one-line note records that the clutter
should no longer accumulate upstream.
