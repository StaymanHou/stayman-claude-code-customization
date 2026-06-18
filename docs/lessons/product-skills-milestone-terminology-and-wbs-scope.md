---
scope: project
status: draft
created: 2026-06-18
target_skills:
  - product-roadmap
  - product-wbs
  - session-start
related_global_docs:
  - ~/.claude/CLAUDE.md  # "Work Tree Format (GLOBAL)" uses "Phase" heavily — affected if these rules are promoted globally
source: surfaced during AlphaFun product-workflow run (turn-based-ai-test-proto-1)
note: project-local capture; these are global-skill improvements — promote to ~/.claude/ skill edits when curated
---

# Learning: Roadmap "milestone" terminology, flat numbering, and WBS-scope-of-one-milestone

Two related corrections to the **product workflow** skills, surfaced by the repo owner during a live `product-roadmap` / `product-wbs` run. Captured here as a draft for the user to curate into the actual skill files (and possibly the global `~/.claude/CLAUDE.md`).

## Rule 1 — Prefer "milestone" over "phase" in the roadmap (with backward-compat alias)

**What:** The roadmap (and downstream references) should use the term **"milestone"** for the primary unit of roadmap decomposition, **not "phase."**

**Why:** The repo owner finds "phase" overloaded/ambiguous and prefers "milestone" as the roadmap's atomic deliverable unit. This is a durable terminology preference, not a one-off.

**How to apply:**
- `product-roadmap` should emit `### Milestone <N>: <name>` rather than `### Phase <N>:`.
- **Backward compatibility is required.** Existing docs and skills that say "Phase" must keep working — treat "phase" as a recognized alias for "milestone" when *reading*. Do not break:
  - The global Work Tree Format in `~/.claude/CLAUDE.md`, which uses `Phase 1`, `Phase 2`, … heavily for **feature** WIP files. NOTE: that is the *feature* work tree, a different artifact from the *roadmap*. The cleanest split is: **roadmap → "milestone"; feature work-tree → keep "Phase"** (or migrate both, but only with an explicit alias-on-read so old files still parse). Decide deliberately — don't blanket-rename and break the feature work-tree schema.
  - `transitions.md` pause-policy tables and any skill prose that references "phase."
- When in doubt, *write* "milestone" for new roadmap content, *read* both.

## Rule 2 — Roadmap produces FLAT milestones; "group" is for cosmetic grouping only

**What:** `product-roadmap` should **almost always emit flat, singly-numbered milestones** (`Milestone 1`, `Milestone 2`, …), **not** dotted hierarchical numbering (`1.1`, `1.2`, `2.1`, …).

**Why:** The owner wants a flat sequence-of-execution list; dotted sub-numbering implies a hierarchy the roadmap shouldn't impose and becomes a confabulation/ordering hazard.

**How to apply:**
- Default to flat numbering for milestones.
- Use **"Group"** headings (e.g. `## Group A — Chess`) purely as **cosmetic/visual organization** over the flat milestone list. Groups carry no numbering semantics and no dependency semantics — they just cluster related milestones for readability.
- Reserve any nesting/dotted numbering for genuinely hierarchical artifacts (e.g. the feature Work Tree's `P1.1` impl tasks), not the roadmap.

## Rule 3 — WBS decomposes ONLY the immediate next milestone, not the whole roadmap

**What:** `product-wbs` should produce a detailed Work Breakdown Structure for **only the immediate next milestone** in the roadmap — not the entire roadmap.

**Why:** Decomposing all future milestones up front is wasted/speculative work: later milestones are contingent (gates, pivot-on-failure), depend on knowledge that doesn't exist yet, and re-planning is cheap precisely because you *didn't* over-commit. The owner explicitly does not want the whole roadmap decomposed into WPs.

**How to apply:**
- `product-wbs` details WPs for the next milestone only (e.g. its probe + build WPs, with tasks).
- Future milestones are **already tracked by the roadmap** — the WBS should NOT re-list them as decomposed WPs. At most keep a single-line pointer ("future milestones tracked in roadmap.md"), and only if a stub is genuinely useful.
- This aligns with the existing learning-sequence-ordering guidance (resolve riskiest unknowns first, cheaply) — extend it to "and don't decompose what you're not about to build."
- On milestone completion, the workflow loops back to `product-wbs` (or directly to the next feature) to decompose the *next* milestone then — just-in-time, not all-at-once.

## Curation note for the user
These three are coherent and low-risk to apply to `product-roadmap` and `product-wbs`. The only thing needing a real decision is Rule 1's backward-compat boundary: whether to rename "Phase" in the **feature Work Tree** too, or keep that schema as-is and only switch the **roadmap** to "milestone." Recommendation: switch the roadmap, keep the feature Work Tree's "Phase" (with alias-on-read), to avoid touching the load-bearing global Work Tree Format schema.
