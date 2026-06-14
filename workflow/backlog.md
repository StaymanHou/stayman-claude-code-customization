# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention). **Code-quality findings** auto-backlogged by `feature-review-quality` are pointer-collapsed here — full content lives in `workflow/backlog-quality-findings.md`, grouped by source feature.

---

## TODO

## SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN
- **Source:** feature:build (claude-md-compaction Phase 4 verify-auto)
- **Order:** P1
- **Target level:** product:wbs (small task — likely a single check-structure.sh phase addition)
- **Type:** gap
- **Summary:** `tests/check-structure.sh` does not validate that every SKILL.md / AGENTS.md frontmatter is parseable YAML. An invalid `argument-hint:` value (unquoted inner-colon string) in `skills/util-prune-claude-md/SKILL.md` slipped through the structural sweep (PASS 251/0) and would have broken the harness's skill registry at next session load. Caught manually by `python3 yaml.safe_load` during verify-auto, fixed in-line.
- **Context:** Skill frontmatter is the harness's contract surface — an invalid frontmatter renders the skill non-invokable, but the failure mode is silent until the next session start. Mechanically pin-able: iterate `skills/*/SKILL.md` + `agents/*/AGENTS.md`, extract frontmatter (between `---` markers), pipe through `python3 -c "import sys, yaml; yaml.safe_load(sys.stdin.read())"`, fail the structural check on any non-zero exit.
- **Suggested action:** Add a new Phase to `tests/check-structure.sh` ("[Phase N] Frontmatter YAML parseability") that runs the above check across all SKILL.md and AGENTS.md files. Estimated 10-line addition.
- **Priority:** medium (silent failure mode + low fix cost)
- **Status:** open

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

