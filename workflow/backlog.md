# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention). **Code-quality findings** auto-backlogged by `feature-review-quality` are pointer-collapsed here — full content lives in `workflow/backlog-quality-findings.md`, grouped by source feature.

---

## TODO

## Code-quality findings — close-commit-discipline (2026-06-12)
- **Pointer:** 5 MINOR findings auto-backlogged from the `feature-review-quality` post-ship pass. Full content in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md) → `# close-commit-discipline — 2026-06-12` section. Findings: 4-way prose duplication, product-finalize format asymmetry, loose grep pattern, redundant S20 anchor, no-family-marker scenario comment.
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** one combined task sweeping all 5 (~30 min) when convenient, or skip until the underlying SKILL.md prose is next touched.

## Code-quality findings — verify-sh-contains-required (2026-06-13)
- **Pointer:** 3 MINOR findings auto-backlogged from the `feature-review-quality` post-ship pass. Full content in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md) → `# verify-sh-contains-required — 2026-06-13` section. Findings: Phase 3e header case-range stale (G-K should be G-M), `_csv` arg suffix misleading (pipe-separated), CLAUDE.md grep pin alternation overspecified.
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** one combined task sweeping all 3 (~10 min) when convenient. Each is a single-line edit; none load-bearing.

## MAYBE

_(empty — both prior MAYBE items promoted to TODO 2026-06-12; SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE buried same day)_

---

## Buried

The following items were buried by user decision. Full content preserved in [`workflow/backlog-deferred-2026-05.md`](backlog-deferred-2026-05.md).

Buried 2026-06-07:
- `SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER` — bulk-delete safety pattern (CLAUDE.md convention proposal).
- `SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING` — audit-method gap; destructuring patterns require their own grep.
- `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` — codify plan-time downstream-contract grep into `feature-plan` SKILL.md.
- `SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD` — `docs/product/wbs.md` exceeds 300-line size guard.
- `SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG` — `--db` silently overrides `$CLAUDE_TIME_DIR` for config lookup.
- `SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE` — `session_id[:8]` truncation can collide in synthetic test data.
- `SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL-DOESNT-REACH-REACT` — synthetic `WheelEvent` dispatch doesn't reach React's `onWheel`.
- `SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT` — structural check missing; frontmatter `name:` vs. parent dir.

Buried 2026-06-12:
- `SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE` — borrow obra/superpowers' behavioral pressure tests for skill rationalization-resistance.

