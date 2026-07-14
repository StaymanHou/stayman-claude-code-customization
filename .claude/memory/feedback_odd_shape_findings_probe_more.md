---
name: feedback-odd-shape-findings-probe-more
description: "Odd-shape verify-self / review-quality findings are a probe-more signal, not a ship signal — invest one more curiosity cycle before shipping"
metadata:
  node_type: memory
  type: feedback
---

**Odd-shape findings are a probe-more signal, not a ship signal.**

When a verify-self / review-quality finding has a shape that **diverges from the standard idiom for that class of system** — e.g. a TUI needing two keystrokes to exit when one is the norm, an endpoint that passes tests but returns surprisingly empty bodies when siblings return populated ones, an assertion satisfied by a side-effect rather than the behavior actually under test — treat the divergence as a signal to invest **one more curiosity cycle** before shipping.

**The self-applicable heuristic:** try to finish the sentence *"this is the shape because…"*
- …a **load-bearing reason** (raw mode, a deliberate API choice, documented behavior) → ship.
- …*"I don't know, that's just what we observed"* → **probe more** before passing the outcome.

**Why:** Surfaced from the claudesk WP2 PTY-probe incident (2026-06-16). The original finding "CC requires Ctrl+D twice to exit; `/exit\n` doesn't work" was correct as far as it went but missed the load-bearing root cause — raw-mode **CR vs LF** (`\r` is Enter, not `\n`). The autopilot objective gates passed because the verify-self assertion was technically satisfied; the operator caught it only *post-finalize* by gut-check ("just don't feel that should be difficult"), after the ship commit and CHANGELOG entry already existed. In Mode 3/4 (autopilot) the operator's veto is a post-hoc recovery, not a pre-ship gate — so the agent self-applying this heuristic *before* passing an outcome is what closes the gap. This generalizes to any autopilot run: a technically-passing-but-idiom-diverging observation is exactly where a silently-wrong root cause hides.

**How to apply:** Before reporting PASS on a verify-self or review-quality outcome — especially under Mode 3/Mode 4 — run the "this is the shape because…" test on any finding whose shape is unusual for its system class. If the sentence ends in a hedge, probe one more cycle (or surface the hedge into the verify-human checklist) rather than passing it forward.

**Deferred (WP5, 2026-07-13, operator ruling):** the sibling proposal to bake this into the `feature-verify-self-runner` subagent prompt (have it ask "is this the shape you'd expect from a system of this class?" and emit a `severity: COSMETIC` hedge into the verify-human checklist) was **intentionally not done** — this memory-only version is the chosen implementation. Do **not** re-propose the runner-prompt augmentation unless the memory-only version proves insufficient in practice. Full origin: `.claude/learnings/2026-06-16-odd-shape-findings-deserve-one-more-cycle.md`; backlog `SURFACE-2026-06-16-ODD-SHAPE-FINDINGS-PROBE-MORE-HEURISTIC`.
