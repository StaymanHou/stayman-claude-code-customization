# Backlog — standing items at the M-close boundary

<!-- Fixture for util-backlog-paydown scenarios. Items are GENERALIZED/REDACTED from two
     real sweep sessions (a debt sweep + a sweep family) — no real file paths, component
     names, SURFACE IDs, or project identifiers. Each item is shaped to exercise one
     disposition path of the 3-axis model. -->

## Code-quality findings (deferred /feature-refactor batch)

- **CQ-1 — unused dependency + stale comments.** A library dependency is declared but has zero
  non-comment references; the build config comments describe a contract the code no longer implements.
  Verified dead. Removal is pure subtraction. `[impact: low-med · effort: XS · risk: XS]`

- **CQ-2 — silent-failure seam in a data-display path.** A status value is sent by the backend on
  every event but dropped by the consumer, so a useful indicator never renders. Wiring it through is a
  small, well-covered change. `[impact: high · effort: small · risk: low]`

- **CQ-3 — cross-language id contract has only prose linkage.** A set of identifiers is encoded in two
  languages with no enforcing check; a one-character drift would ship green and silently break a feature.
  Fix = add a string-grep pin test. `[impact: high · effort: small · risk: low]`

- **CQ-4 — repeated stale-count / docstring-drift across ~9 files.** The same comment-vs-reality drift
  recurs in many files (one theme, many instances). Comment/docstring-only; no production code change.
  `[impact: low · effort: XS each · risk: XS]`

## Decision / judgment items

- **DEC-1 — auth-boundary hardening for a privileged shell.** A privileged path canonicalizes its parent
  but not the leaf; the doc-comments claim a stronger guarantee than the code gives. Two options: make the
  code honest (fix the docs now, XS) vs. build the full boundary hardening (medium-risk auth change).
  `[impact: high · effort: high (for the full fix) · risk: high]`

## Net-new / gated

- **NEW-1 — absorb an upstream capability as a feature.** Net-new feature work slated for the next milestone.
  `[impact: high · effort: large · risk: med]`

- **GATE-1 — deprecate a legacy source pipeline.** Blocked on operator precondition: the replacement pipeline
  must run in real production for several weeks before the legacy one can be removed. `[gated]`

## Hygiene / out-of-scope

- **OOS-1 — host-only build failure.** A build step fails on the host because of a host-specific native
  binding gap. The project is containerized-by-design; running on the host is explicitly unsupported.

- **SUP-1 — superseded UX request.** A keystroke-ergonomics request that a later redesign already made moot.
  Marked SUPERSEDED.

- **MEH-1 — component test-infra build-out.** Adding a missing component-test harness. Low feature value,
  medium effort to stand up, low risk. Not cheap enough to be free; not valuable enough to prioritize.
  `[impact: low · effort: medium · risk: low]`
