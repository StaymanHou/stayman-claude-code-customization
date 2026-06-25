---
date: 2026-06-25
scope: global
type: Context Rule
session-ref: claudesk roadmap — inserting the M7 workflow-docs markdown viewer
---

# Infer the developer's intent one level past the literal ask — then design on their behalf

## Summary

When the operator hands down a feature/scope ask, don't stop at the literal request. Dig **one level deeper** to the *underlying intent* — the problem they're actually solving, the scarce resource they're actually economizing — and let that intent guide the design choices you make on their behalf (defaults, scope cuts, follow-on questions, adjacent-feature connections). The literal ask says *what*; the intent says *why these specific choices*, and the *why* is what lets you fill gaps correctly without round-tripping every decision.

The tell that you've found the real intent: it **explains the scope choices the operator already made** (including the deletions and the odd inclusions) as a coherent set, rather than as a list of arbitrary preferences. If your inferred intent makes the operator's own choices look obvious in hindsight, you've probably got it. If it doesn't, you've stopped one level too shallow.

This is distinct from gold-plating. You are not adding scope — you are reading the existing scope correctly so the choices you DO make (the recommended default, the open question you carry to WBS, the cross-link to an adjacent feature) align with what the operator was actually reaching for.

## The technique

1. **Restate the literal ask.** ("A read-only markdown viewer for the conventional product/workflow docs.")
2. **Ask: what problem does this actually solve, and what scarce resource does it protect?** Ground this in the project's stated philosophy/vision, not generic best practice. (Claudesk's scarce resource is *operator attention across 20+ rotating projects* — so most features are attention-routing in disguise. The "viewer" is really a *re-orientation* feature: "where was I in the workflow, what's next?")
3. **Find the tells — the scope choices that confirm or refute the inferred intent.** Look especially at what the operator *included that's surprising* and *excluded that's expected*:
   - Included `.session.md` (the literal pause bookmark = "what to do next") → confirms re-orientation, not documentation-reading.
   - Globbed `*wbs*.md` instead of hardcoding `wbs.md` → wants *current live state*, including scratch/temporary files, not a canonical filename.
   - Dropped CHANGELOG (the *past*) → the panel is about *current position + next step*, not history.
   - Three independent choices all point the same way → the intent read is solid.
4. **Connect to the larger arc.** A correctly-read intent usually reveals the feature is one step in a longer trajectory the vision already names. (M7 docs-viewer = the read-side counterpart to the M6 workflow-doc-hierarchy watcher, and the first concrete step toward the "workflow-state-aware, not just process-aware" Future Possibility.) Surface that connection in the artifact (cross-link the milestones) so the next decision inherits it.
5. **Convert intent into design leverage:**
   - **Defaults:** recommend the option the intent implies (read-only, auto-discover, per-workspace).
   - **Open questions worth carrying forward:** the intent generates *new* good questions the operator didn't ask (e.g. "should the panel auto-select the active WIP / `.session.md` on open, rather than just listing files? — the re-orientation intent says the operator wants the right doc already open, not to hunt for it"). Carry these to the WBS/spec, don't silently decide them.
   - **Anti-scope:** the intent also tells you what NOT to build (editing belongs in the editor/CC, not here).

## Suggested change

A CLAUDE.md rule (global), under a Planning / scope-reading section — or folded into the entry-point planning skills (`feature-spec`, `feature-plan`, `task-plan`, `product-wbs`) as a pre-planning move:

> **Infer intent one level past the literal ask.** Before planning a feature/scope ask, restate it, then dig one level deeper to the *underlying intent* — the problem it solves and the scarce resource it protects, grounded in the project's vision/philosophy (not generic best practice). Validate the read against the operator's own scope choices: a correct intent makes the surprising inclusions and the expected-but-omitted exclusions look obvious as a coherent set. Then use the intent to (a) pick defaults, (b) generate the good follow-on questions the operator didn't ask and carry them to the spec/WBS rather than silently deciding, (c) name the anti-scope, and (d) cross-link the feature to the larger arc the vision already implies. This is reading existing scope correctly, NOT adding scope — do not gold-plate.

## Why this is worth a rule

It changes the agent's posture from *order-taker* (build exactly the words) to *intent-aligned collaborator* (build what the words are reaching for) — without crossing into *autonomous scope-creep*. The guardrail against creep is step 3: the intent must be *evidenced by the operator's own choices*, so the agent is decoding the operator, not substituting its own taste. When that decode is right, the agent can make dozens of small design choices on the dev's behalf that all land correctly, and the operator stops having to spell out every default.

## Session-log excerpt (optional)

Operator: "add a milestone between M6 and M7 — a markdown viewer for the conventional product/workflow docs." After scoping questions, the operator's answers (include `.session.md`; glob `*wbs*.md`; drop CHANGELOG) were read not as three preferences but as one intent: **this is a per-project re-orientation surface, not a doc reader** — the scarce resource is operator attention re-entering a cold project. That read (a) confirmed read-only as correct, (b) generated the unasked "auto-select the active doc on open?" question now parked for the M7 WBS, and (c) surfaced the M6-watcher / "workflow-state-aware" arc connection, which got cross-linked in the roadmap. Operator response to the intent read: "very good read." Then: capture the *technique* as portable guidance.
