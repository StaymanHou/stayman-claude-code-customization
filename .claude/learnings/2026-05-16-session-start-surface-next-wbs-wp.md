---
date: 2026-05-16
scope: global
type: Skill
session-ref: neo-stayman 2026-05-16 session-start (post-WP1)
---

# /session-start should surface next ready WBS work package alongside backlog

## Summary
In WBS-driven projects, `/session-start` step 1 currently surfaces only `workflow/backlog.md` items when no active WIP exists. This gives an incomplete starting menu: backlog items are *deferred discoveries from past work*, while `docs/product/wbs.md` is the *canonical sequencing document for planned forward work*. After WP1 finalized in NeoStayman with empty WIP and a non-empty backlog, the skill offered only backlog items; the user had to redirect with "next WP in WBS" to get the obvious WP2 candidate. The forward-motion signal should not require user prompting.

## Suggested change

Skill (global): edit `~/.claude/skills/session-start/SKILL.md` step 1 ("Check for active work") to surface WBS candidates alongside backlog items.

**Behavior to add (when no active WIP, no `.session.md`, no in-progress product doc, and no `{{args}}`):**

1. Check `docs/product/wbs.md` for the next-ready WP. A WP is "ready" if:
   - Its top-level checkbox is `[ ]` (not started or in-progress)
   - All of its `Dependencies:` resolve to WPs whose checkbox is `[x]`
2. If a ready WP exists, surface it as a labeled section **above** the backlog section:

   > **Next WP from WBS** — WP<N>: <name>
   > <first sentence of WP description>
   > *(Size: <S/M/L>, Phase: <phase>)*
   >
   > **Backlog has these open items —**
   > 1. SURFACE-… …
   > 2. SURFACE-… …
   > 3. SURFACE-… …
   >
   > …Or describe new work below.

3. The user can reply with: `next WP` / `wbs` / `WP<N>` to pick the WBS candidate, a backlog index/SURFACE-ID for a backlog item, "more backlog" to expand, or free-form for new work.
4. Step 2 classification: a "next WP" reply resolves to the WP's title + description as classification input (same pattern as backlog-ID resolution).

**Silent no-ops:**
- No `docs/product/wbs.md` file → skip the WBS section entirely; behave as today.
- File exists but no ready WP (all `[x]` or all blocked) → skip the WBS section; behave as today.

**Rationale to include as a comment in the SKILL.md edit:** Backlog items are deferred discoveries; the WBS is the plan for forward motion. A "what's next?" menu that only reads one of them gives a half-picture in projects that use both.

## Session-log excerpt
> Agent: "By the way, the backlog has these open items — 1. SURFACE-2026-05-15-WP3-SCOPE-REDUCED-BY-WP1 …"
> User: "Next wp in wbs"
> Agent: [reads wbs.md, identifies WP2 as the next-ready WP, classifies as feature:spec]

The user's redirect proves the forward-motion candidate was the right offer to make unprompted.
