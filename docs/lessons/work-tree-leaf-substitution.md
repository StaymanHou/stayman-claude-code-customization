# Verify-codify leaf substitution discipline — replace the existing `- [ ] verify-codify` line, don't append above it

When a phase completes its `verify-codify` step, the Work Tree update must **substitute** the `- [ ] verify-codify  <!-- status: NOT-STARTED -->` line with the completed form (e.g., `- [x] verify-codify  <!-- completion note -->`) — NOT append a new `[x]` line above the existing NOT-STARTED line. The same discipline applies to every other leaf substitution (verify-auto, verify-self, verify-human, build, impl tasks), but `verify-codify` is the load-bearing case caught empirically.

## Why it matters

Under the global Work-Tree-format rule ("a parent's checkbox may only be `[x]` when ALL children are `[x]`"), an appended-above-not-replaced pattern leaves two `verify-codify` children under one phase — one `[x]` (the completion note) AND one `[ ]` (the residual NOT-STARTED) — which technically means the phase is NOT cleanly closed even though its actual verification work succeeded.

The bite is a cosmetic audit-trail artifact in archived WIPs, not a correctness regression; but future readers grepping for `^- \[ \]` under closed phases (or finalize-time tree scans) see a contradiction.

## Practical application

At `verify-codify` completion time (and any other leaf-completion time): use `Edit` with `old_string` = the original NOT-STARTED line and `new_string` = the completed line. Never `Edit` to add a new line, and never `Write` a tree where the old NOT-STARTED line still exists alongside the new completion.

If picking this up as a structural pin later, scan WIP archives for `≥2 verify-codify lines under one Phase node`. Until then this is operator-grep discipline.

## Instance

Caught 2026-06-12 by the `code-quality-reviewer` subagent as MAJOR finding #1 against `workflow/wip/verify-self-and-review-quality-subagent-dispatch.md` — both Phase 2 and Phase 3 shipped with this exact duplicate-leaf pattern (lines 259-260 and 285-286 of the WIP at ship time).
