# Plan-time downstream-contract-impacts grep — mechanical verification before sealing a phase boundary

When a phase modifies a contract that existing artifacts already assert against (test scenarios, fixtures, downstream skill SKILL.md transitions, AGENTS.md rows, CLAUDE.md docs, source files that own a payload shape, JSX selectors), flag those artifacts as affected in the **same phase that changes the contract** — not in a later test/docs phase. The verify-codify Test Triage gate is a safety net; the plan-time grep is the discipline that keeps the safety net from being load-bearing.

## Practical application — four-step grep at plan time, four-step grep at build time

Before sealing a phase's impl tasks, ask "what else asserts against the thing I'm changing here?" and run this enumeration:

1. **Key-name grep.** `grep -RF "<field-or-key-name>" ./tests ./src` — the baseline.
2. **Literal-payload-object grep.** When a phase adds a key to a payload-object passed to a function (`updateHash({...})`, `setState({...})`), tests grep the literal patch-object string. Pattern: `grep -RF "updateHash({ view: " ./tests`.
3. **Array-length-add grep.** When a phase extends an array of known cardinality (tile lists, route arrays, filter-kind enums, schema fields, status enums), tests assert `.length === N` or `.length >= N`. Pattern: `grep -RE "tileIds\.length\s*===\s*\d+" ./tests`.
4. **Literal function-signature / variable-binding grep.** When a phase adds a default-param or destructured-prop (`function NAME({ a, b }) → function NAME({ a, b, c = 0 })`) or renames a binding (`const overlaps = useOverlaps()` → `const ctx = useOverlaps()`), tests grep the LITERAL signature/binding. Patterns: `grep -RE "function HeadlineCard\(\{"` and `grep -RE "const \w+ = useOverlaps\(\)"`.

After each impl task that the plan declares **`[data-*]` selectors** against (typically JSX/HTML/template tasks), grep the just-edited file for each declared selector. Confirm count > 0 AND the attribute lands on the correct element (not a parent wrapper, not a stale path). Skipping shifts the verification cost to verify-self (F9b back-loop) or verify-human.

## Cross-layer sub-case — when *deleting* a code path

When deleting code that *attaches* fields to a shared payload, the contract those fields satisfy must migrate to the new layer that *owns the shape* — not silently disappear with the deleted code. At plan time:

(a) grep the deleted code for `<payload>["<field>"] = ` / `<payload>.<field> = ` attachment patterns;
(b) grep the codebase + tests for downstream **consumers** of those fields (including destructured reads — `const {field} = payload` — and sub-key reads — `payload.foo.field`);
(c) if any consumers remain, plan an explicit re-attachment step in the **same phase** that does the deletion, in whichever layer now owns the payload shape.

## Instances

Eight post-hoc observations of `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` across all sub-cases:

1. 2026-05-10 — `incident-codify` feature, scenario contract miss (key-name).
2. 2026-05-29 — v3 WP3 Phase 2 verify-codify, alias-key audit miss (key-name).
3. 2026-05-29 — v3 WP4 Phase 3 verify-codify, `comparison.{a,b}.metrics` regression (cross-layer).
4. 2026-06-03 — v3 WP5 P1.2, added `date:` key to `updateHash` dispatcher broke 4 of 5 literal-pin strings (literal-payload-object).
5. 2026-06-06 — v3 WP11 P2, added 4th `away` tile broke `tileIds.length === 3` (array-length-add).
6. 2026-06-06 — v3 WP12 P2, added 5th `parallel` tile, re-broke same shape (array-length-add).
7. 2026-06-06 — v3 WP12 P2.1, added `parallelMs = 0` to HeadlineCard destructure broke literal function-signature pin in `test_visualize_cli.sh:2832` (literal-function-signature).
8. 2026-06-06 — v3 WP12 P2.verify-human.2 F12 back-loop, `OverlapsContext` value gained `sessionToProject` map → 3 useOverlaps call sites unpacked via `const ctx = useOverlaps()`, breaking `const overlaps =` pin in `test_visualize_cli.sh:3018` (literal-variable-binding-name).

Build-time `[data-*]` selector misses surfaced 2026-06-06 during v3 WP11 P1 verify-self: SessionRow root div missing `data-session-row`; expanded-branch wrapper duplicated `data-project-row`. Cost: 1 F9b back-loop, ~30 min, two source edits — all preventable by a mechanical post-write grep.

The backlog item proposing to codify this into `feature-plan` SKILL.md as a mechanical step remains pending; until then, this lesson is the doc-side fallback.
