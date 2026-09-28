# Handoff — Claudesk "secondary non-workflow user" work → this repo's part

**From:** the **Claudesk** project (`/Users/stayman/Personal/projects/claudesk`)
**To:** this repo — **`my-claude-code-customization`** (the custom CC workflow system)
**Date:** 2026-07-20
**Author:** a Claudesk product-planning session (operator: Stayman)

---

## Why you're getting this

Claudesk is being made pleasant for a **secondary user who does NOT run this workflow system** (a plain Claude Code user who installs Claudesk from Homebrew). The settled design gates *all* workflow-coupled Claudesk UI behind a single opt-in (`workflow_features_enabled`, default OFF), with a **one-time evangelistic invite** that pitches + explains how to install *this* workflow system, plus an **onboarding** experience for people brand-new to the workflow.

That decision surfaced a set of items that are **this repo's responsibility, not Claudesk's** — because they're properties of the *skills/workflow system itself*, independent of Claudesk. This doc hands them over with full context. **Execution order (operator decision 2026-07-20): this repo ships its part FIRST, then Claudesk builds the gate + rich invite that consumes your deliverables (Claudesk Milestone 10.9), then Claudesk Milestone 11.** Claudesk's invite/onboarding would hardcode against a moving target if built before you settle these — so you go first.

## The division of labor (the seam)

The test that splits every item: **"does it require Claudesk to run?"**
- **No → this repo owns it** (it's a property of the skills / install / docs convention).
- Claudesk **presents** surfaces; this repo **authors content + provides mechanics.** Claudesk never hardcodes workflow internals — it renders/points at what you produce.

**Claudesk owns (for reference — NOT your work):** the `workflow_features_enabled` gate setting, the OFF=byte-identical invariant, the Settings toggle, the invite *dialog UI*, the onboarding *surface* (where it renders in-app), the soft `~/.claude/skills/` presence check, and M11's doc-discovery *following whatever folder layout you settle on*.

## Your items (each also filed as a SURFACE in this repo's `workflow/backlog.md`)

1. **Standalone `uninstall.sh` (works without Claudesk) + canonical `install.sh` as the single source of truth.**
   Claudesk's invite will *display* your install instructions (not hardcode them) and offers a one-click *disable* (Claudesk-side UI flip). But the actual **install/uninstall of the skill system** must be a clean, standalone, Claudesk-independent operation so a curious user can try it and back out with zero residue. `install.sh` exists; a matching `uninstall.sh` (reverse the symlinks/registrations `install.sh` makes, incl. the `~/.claude/settings.json` hook registration + the memory symlink) is the gap. This is what de-frictions "let me try the workflow system, and cleanly remove it if it's not for me."

2. **Unify the workflow doc folders (`docs/product/` + `workflow/`) into a friendlier single layout for new users.**
   Right now workflow state is split across `docs/product/*.md` (strategic: vision/roadmap/arch/wbs) and `workflow/*` (operational: backlog/wip/.session.md). For *you* that split is second nature; for a **new user** it's two places to learn. Consider a single top-level folder (name TBD) that co-locates or clearly indexes both. **⚠️ Cross-repo coupling:** Claudesk M11's Docs viewer auto-discovers this exact doc set — **if you change the layout, tell Claudesk** so its `docs_list` discovery follows. Decide the layout here; Claudesk adapts.

3. **Disambiguate "pause"** (course-correct mid-flight vs. invoke the `session-pause` skill).
   The operator says "pause" both to *interrupt/redirect* the current work AND to mean *"run `/session-pause`"*. The orchestrator/skill prompts should disambiguate — e.g. reserve the bare word for course-correction and require the explicit `/session-pause` (or a distinct phrase) for the skill, or have the orchestrator confirm intent when ambiguous. Lives in this repo's skill/orchestrator prompts.

4. **Resolve the "research" naming collision.**
   Claude Code shipped a built-in **deep-research** skill/capability; this repo has `product-research` + `feature-research` skills. The term now overlaps and can misfire (operator says "research" → wrong skill fires). Rename/namespace this repo's research skills, or add disambiguation in the orchestrator, so the workflow's research skills don't collide with CC's built-in one.

5. **Design the new-user onboarding + "aha" moments (brainstorm pending) — possibly a dedicated skill and/or a tutorial project.**
   Since Claudesk will *invite* new users to adopt the workflow, this repo needs a deliberate onboarding path: what does a brand-new user do first, what's the fastest "aha" (the moment the workflow's value clicks), and does that need a dedicated **onboarding skill** and/or a **throwaway tutorial project** to practice on? **This is explicitly a brainstorm-first item — not yet specced.** Claudesk will render whatever onboarding surface you design; the *content + flow* is yours. The operator wants to brainstorm this together.

## Suggested sequencing within this repo

Rough dependency order (your call to refine via `/product-roadmap` or `/session-start`):
1. **Doc-folder unification (#2)** first — it's the layout everything else references, and it's the thing Claudesk M11 must know.
2. **Install/uninstall (#1)** — standalone, unblocks Claudesk's invite + the "try-and-back-out" story.
3. **"pause" (#3) + "research" (#4) disambiguation** — independent, small, can run anytime/parallel.
4. **Onboarding design (#5)** — brainstorm-first; likely last (depends on the settled folder layout + install flow to build a coherent first-run story), and co-designed with the operator.

## Where to look for more detail (Claudesk side)

Claudesk's project root: **`/Users/stayman/Personal/projects/claudesk`**. Relevant files:
- **`docs/product/roadmap.md` → "Revision 2026-07-20"** + **"Milestone 10.9: Workflow-features opt-in gate"** — the full gate design, the cross-repo split, and the execution order.
- **`docs/product/vision.md` → §Target Audience** — the audience-stance refinement (from "no concession for non-workflow users" → a two-tier "lite-IDE core for any CC user + opt-in gated workflow layer") lands here.
- **`docs/product/wbs.md`** — Claudesk M11 (Docs viewer) WBS; shows exactly which doc paths M11 auto-discovers (the thing #2's folder-unification must coordinate with).
- **`docs/product/design-priors.md`** — the design prior this decision proposes (audience/anti-persona gating), for cross-reference.

When you need to confirm a Claudesk-side detail (e.g. "what exactly does Claudesk's invite display?", "what folder paths does M11 discover?"), read those files directly — this handoff is the summary, those are the source of truth.

## What Claudesk needs back from you (the return contract)

When you ship your part, Claudesk's M10.9 WBS needs:
- The **canonical install-instruction copy** (what the invite should display) + the **install/uninstall command(s)**.
- The **settled doc-folder layout** (so M11's `docs_list` discovery matches).
- The **onboarding flow spec** (so Claudesk knows what surface to render + when).

A short "here's what changed + here's the copy/paths for Claudesk" note back to `/Users/stayman/Personal/projects/claudesk` (e.g. a reciprocal handoff or a backlog SURFACE there) closes the loop.
