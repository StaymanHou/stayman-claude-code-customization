---
date: 2026-05-12
scope: global
type: Context Rule
session-ref: session-start backlog-surfacing feature (defense against SURFACE-2026-05-12-STORE-LEARNING-WRONG-ITEM-SELECTED bug class)
---

# Canonical-ID-anchored numbering for user-pickable lists

## Summary
When a skill surfaces a user-pickable list (numbered candidates, options, search results), the local 1./2./3. index can silently re-anchor to a *sub-list* (e.g., a "Recommendations" subset of a larger enumeration) and cause the system to pick the wrong item when the user references "#N". Defense: always display the canonical identifier alongside any local 1./2./3. index, treat both as valid user references, and have the system confirm the picked item by canonical ID before acting. The numbering must anchor to the displayed list only — never to a hidden full enumeration. This bug class was observed live in `session-store-learning` (SURFACE-2026-05-12-STORE-LEARNING-WRONG-ITEM-SELECTED) and pre-emptively defended against in the session-start backlog-surfacing feature.

## Suggested change
CLAUDE.md rule (in `my-claude-code-customization`, under `## Conventions`):

> **Canonical-ID-anchored numbering for pickable lists.** Any SKILL.md procedure that surfaces a list and accepts a user pick by index must (a) display a canonical identifier (SURFACE-ID, UUID, file path, etc.) alongside the local 1./2./3. index, (b) accept either as a valid user reference, (c) anchor numbering to the displayed list only — never to a hidden full enumeration or sub-list, and (d) confirm the picked item by canonical ID ("Picked up <canonical-id>") before acting. Defends against the sub-list reindexing bug class first observed in `session-store-learning` (see SURFACE-2026-05-12-STORE-LEARNING-WRONG-ITEM-SELECTED).

Also worth applying preemptively to: `session-resume` (if it ever surfaces multiple pause points), any future skill that ranks candidates, the `feature-reproduce` skill's reproduction-attempt list if it grows.

## Session-log excerpt
The session-start backlog-surfacing SKILL prose explicitly states: "Both the local index and the SURFACE-ID are valid references for the user's reply. The numbering anchors to the displayed top-3 only — never to a hidden full-backlog enumeration." Step 2 also says: "**confirm the match by SURFACE-ID** ('Picked up SURFACE-…') before classifying, so the user can catch a wrong-item selection (see SURFACE-2026-05-12-STORE-LEARNING-WRONG-ITEM-SELECTED for the failure mode this defends against)."
