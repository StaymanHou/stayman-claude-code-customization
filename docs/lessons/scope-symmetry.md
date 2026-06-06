# Scope-symmetry at mitigate time

When applying a fix whose mechanism would also apply to symmetric places in the codebase (e.g., a structural fix to AUTO transitions in *one* part of the state machine), audit the full namespace before declaring scope.

## Practical application

Before sealing a mitigation as "done", grep the canonical source (AGENTS.md, transitions.md, the state machine schema) for *every* place the same mechanism appears, and ask "does this fix uniformly apply, or am I about to ship a partial fix?"

## Instance

Caught 2026-05-17 during the autopilot-pause-policy-recheck-regression incident: per-phase mitigation was scope-extended mid-workflow when the user observed the same failure mode in `feature-spec` and `feature-plan` — the symmetric `feature-research`, `feature-spec`, `feature-plan` skills needed the same cheat-sheet block and were caught only because the user spoke up. Pre-mitigation audit would have caught it in one pass.
