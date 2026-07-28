---
date: 2026-07-28
scope: global
type: Context Rule
session-ref: claudesk M10.9 WP1 (settings-surface + invite probe)
origin-session-log: ~/.claude/projects/-Users-stayman-Personal-projects-claudesk/6c014b4b-0427-48e2-9782-5d8885c579de.jsonl
origin-session-id: 6c014b4b-0427-48e2-9782-5d8885c579de
origin-session-span: 2026-07-28T18:22:31Z → 2026-07-28T20:10:10Z
origin-message-timestamp: 2026-07-28T19:21:50Z
ported-from: /Users/stayman/Personal/projects/claudesk/.claude/learnings/2026-07-28-mockup-artifact-for-uiux-decisions.md
ported-on: 2026-07-28
backlog-ref: SURFACE-2026-07-28-MOCKUP-ARTIFACT-FOR-UIUX-DECISIONS
---

> **Ported into mccc 2026-07-28** for conversion into workflow-system behavior, per the operator's
> hand-over instruction in the originating claudesk session. Tracked as
> `SURFACE-2026-07-28-MOCKUP-ARTIFACT-FOR-UIUX-DECISIONS` (TODO **P1 — tackle immediately next
> session**). **Before planning, read the raw origin log named in the frontmatter** — this document is
> a compression that keeps the *what* and drops settled *how* decisions (the three candidate layouts,
> why the middle option was included, the screenshot that inverted the verdict). Grep it on
> `user mock-up artifacts` or `iii-b`. See `docs/lessons/read-origin-session-log-before-planning.md`.

# Offer a lo-fi mockup artifact when a UI/UX decision competes with an existing screen

## Summary

At a UI-placement decision (where a new setting's control should live), code-reading produced the WRONG verdict and a single operator screenshot inverted it. Reading `ProjectPicker.tsx` / `appView.ts` / `app_menu/mod.rs` established that a settings strip existed and was picker-only-reachable; the screenshot established that it consumed ~1/4–1/3 of the modal above the project list. Those facts support opposite decisions: **files give structure, they don't give COST, and layout decisions are decided by cost.** The agent had framed the question as *"where does one boolean go?"* when the live question was *"has the collection outgrown its container?"* — a framing error that no amount of rigor inside the frame recovers.

The recovery that worked was a **lo-fi mockup artifact**: three candidate layouts rendered side-by-side in the product's OWN design tokens at true proportion, each measured on one axis (px above the fold / items visible), including the deliberately unappealing middle option so its trap was visible rather than argued away. The operator picked in one reply, and the reversed decision then propagated cleanly into the WBS.

## Suggested change

**CLAUDE.md rule (global) — CONDITIONAL, not always-do.** The operator's own scoping: *"really simple UI/UX choices won't need mockup."*

> When a UI/UX decision (a) has **≥3 candidate surfaces**, (b) involves a **spatial/layout tradeoff**, AND (c) **competes for room with an already-shipped screen**, build a lo-fi mockup artifact before presenting options. Four requirements are what made it work:
>
> 1. **Render in the PRODUCT'S real design tokens at true proportion** — so the operator judges the layout change, not the mockup's styling. A designed-looking mockup actively misleads here.
> 2. **Put ONE measurable axis on it** (px above the fold, items visible) instead of prose claims. **Label estimates as estimates** — never dress a mockup-derived figure as an instrumented measurement.
> 3. **Include the unappealing middle option** so its trap is visible rather than argued away.
> 4. **Ask for a screenshot of the running app** when the decision's host is an existing screen — the agent has the tool and should not wait for the operator to volunteer it.
>
> Below that bar (a 2-option choice, no spatial tradeoff, a greenfield surface), prose is enough and a mockup is over-ceremony.

**Candidate host skills:** `feature-spec` and `product-wbs` (decision presentation), plus `feature-verify-human` (where a correction of this shape actually lands).

**Related upstream note:** this is about the *elicitation medium* for a decision, which is distinct from the existing design-priors capture contract (that records a *resolved lean*). It is **not** a design prior — the operator explicitly declined prior-capture twice in the originating session.

## Session-log excerpt

Operator, after the mockup: *"iii-b looking good … At the meta level, I also really like the idea of user mock-up artifacts to convey the options for UI/UX decisions. We'd better capture this at the end of the session, and hand over to mccc to convert that to something meaningful that will recreate this behavior for future works/project when meeting a certain condition. (Like really simple UI/UX choices won't need mockup)"*
