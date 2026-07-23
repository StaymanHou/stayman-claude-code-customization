# Verify greps have blind spots — the coherence read is the gate

When verifying tutorial/skill *prose* observables (SKILL.md / spec edits),
`grep` is a fast first pass, NOT the gate. It has systematic blind spots that
recur in this repo's prose-heavy skills:

- **En-dash / hyphen step-ranges** — `grep "Step 3"` misses `Steps 0–3`
  (a range containing "3", not the token "Step 3"). Bit the WP7j Step-renumber
  (a stale "runs Steps 0–3" survived a literal `grep "Step 3"` == 0 check).
- **Markdown-bold-wrapped phrases** — `grep "\.first\. time"` misses
  `**first** time`; a `.` metachar matches one char but not the `**` pair.
- **Line-wrapped phrases** — a target phrase split across two lines (especially
  with a `>` blockquote prefix on the continuation) fails a single-line grep even
  after `tr '\n' ' '`, because the `>` lands mid-phrase.

The **verify-self subagent's coherence READ** is what catches these — it caught
all three classes in the WP7j session (2026-07-23) that the objective greps
passed (the stale `Steps 0–3` range; the `**first**`/`**always**` metachar
mismatches; the blockquote-wrapped `not the > getting-started intro`). Treat a
green grep as necessary-not-sufficient for prose observables; the reader is the
gate.

## Mitigations (wrap/bold/blockquote-tolerant greps)

- wrap-tolerant:        `tr '\n' ' ' < f | grep ...`
- blockquote-tolerant:  `tr '\n' ' ' < f | sed 's/> //g' | grep ...`
- bold-tolerant:        `tr '\n' ' ' < f | sed 's/\*\*//g' | grep ...`

Combine as needed. But the durable lesson is the **order of trust**: coherence
read > tolerant grep > literal grep. When a grep "fails" on prose, suspect the
grep before the copy — in the WP7j session every apparent grep "FAIL" on prose
was a grep artifact, not a real defect, and the fix was always a more-tolerant
grep or the subagent's read, never a copy change.

## Why this matters for the verify loop

`feature-verify-self` spawns a subagent precisely so a *reader* (not just a
grep-runner) observes the artifact. On prose-heavy skills this is not just about
keeping Playwright output out of parent context (the arch.md rationale) — the
reader is the substantive gate, because the observables are prose and prose
greps are fragile. Author the observable-check greps as a first pass, and let
the subagent's coherence read be the thing that actually confirms the phase.
