---
shape: temporary-wbs
cycle: backlog-paydown-2026-07-13
created: 2026-07-13
status: in-progress (WP0-WP5 done; WP6 deferred to next session)
parent-backlog: workflow/backlog.md + workflow/backlog-quality-findings.md
---

# Backlog-Paydown Sweep — 2026-07-13

> **PROGRESS (2026-07-13):** WP0 ✅ (44f4343) · WP1 ✅ (b89a120) · WP2 ✅ (16f61d6) ·
> WP3 ✅ (e61e4bb — caught+fixed a live feature-build frontmatter bug) · WP4 ✅ (f7450b5) ·
> WP5 ✅ (dc45c2d). **WP6 NOT STARTED — deferred to next session per operator.**
> Final verify: `./tests/check-structure.sh` = **401/0**; targeted behavioral check of the
> 4 DP-consult scenarios (WP4-edited skills) = **4/4 PASS**. Fold-back-and-delete happens
> only after WP6 completes — do NOT delete this file yet.

> **THIS IS NOT A ROADMAP MILESTONE.** It reserves no permanent roadmap slot and
> milestone numbering is untouched. It is a **temporary WBS** produced by
> `/util-backlog-paydown` (Mode 2, Batch-approve). On completion the operator
> executes the **fold-back-and-delete** section at the bottom and **deletes this file**.
>
> Drive each WP through the normal `/feature-refactor` (cleanup) or `/task-plan`
> (atomic) loop so finalize/close auto-resolves the SURFACE(s) and appends to
> `CHANGELOG.md`. WPs are **priority/risk-ordered** — run top-to-bottom so an
> interrupted sweep leaves nothing half-applied (deletions → low-risk → high-risk).

## Disposition model (applied)

Scored on **Impact** (feature-value + maintainability=quality×P(future-touch)),
**Effort** (this-project-relative: Large=full WBS cycle · Medium=`/feature-*` · Small=`/task-plan` bundle · XS=1-line), **Risk** (P(breaks something the suite won't catch)). Five actions: Sweep / Discuss / Defer / Bury / Delete. **Rule 1 (cheap+safe → always Sweep, no exception)** carried most of the backlog; five items went to Discuss and were ruled by the operator on 2026-07-13.

Full model + provenance: `docs/lessons/between-milestone-debt-paydown-sweep.md`.

---

## WPs (priority/risk-ordered — run in order)

### WP0 — Delete resolved/duplicate clutter  `[impact: low(declutter) · effort: XS · risk: none]`
Pure subtraction; run first (ordering rule 1). Remove already-resolved and
duplicate SURFACE blocks from the active backlog. No code touched.

Resolves / removes:
- `SURFACE-2026-06-18-PRODUCT-SKILLS-MILESTONE-TERMINOLOGY-AND-WBS-SCOPE` — resolved 2026-06-18 (ab5f7a2), still sitting in TODO.
- `SURFACE-2026-07-03-MEMORY-LOCATION-SYMLINK` — resolved 2026-07-03 (d173bd7), still in MAYBE.
- `SURFACE-2026-06-23-SETTINGS-FIXTURE-DRIFT-CLAUDESK-HOOK` — resolved 2026-06-25 (93677f0).
- `SURFACE-2026-06-25-TRACK-CLAUDE-DIR-AND-LEARNINGS-MEMORIES-CONVENTIONS` — resolved 2026-06-25 (artifact-tracking-policy).
- `SURFACE-2026-06-30-QUALITY-UTIL-PAYDOWN-BURY-SCENARIO-MISSING` — resolved 2026-06-30 (in quality-findings file).
- `SURFACE-2026-06-30-SETTINGS-FIXTURE-DISABLECLAUDEAICONNECTORS-DRIFT` — **duplicate** of `SURFACE-2026-06-26-SETTINGS-FIXTURE-DRIFT-DISABLECLAUDEAICONNECTORS` (same `disableClaudeAiConnectors` drift). Collapse to the 06-26 entry (kept, becomes WP2).

**Shape:** `/task-plan` (docs-only edit to `workflow/backlog.md` + `workflow/backlog-quality-findings.md`). Or hand-edit + note in CHANGELOG. `docs-only: true`.

---

### WP1 — check-structure.sh docs/skill polish (co-located edits)  `[impact: low · effort: XS · risk: low]`
All edits to `docs/lessons/`, `docs/product/arch.md`, and a handful of SKILL.md
prose lines — no logic, no scenarios. Co-located (ordering rule 4). Low risk:
prose only; structural suite will confirm nothing pinned was broken.

Resolves:
- `SURFACE-2026-06-13-QUALITY-CATEGORY-HEADING-DRIFT` — rename `## Category` → `## Category Context` in `skills/util-prune-claude-md/SKILL.md:11`. **Scope-symmetry (see `docs/lessons/scope-symmetry.md`):** `skills/util-backlog-paydown/SKILL.md:13` ALSO uses `## Category` — fix both, OR consciously decide util-* keeps `## Category` distinct from debug-*'s `## Category Context` and document that in `arch.md`'s util-* subsection instead. **Decide at pickup; don't fix one and leave the sibling.**
- `SURFACE-2026-06-13-QUALITY-LESSON-FILE-SCHEMA-AMBIGUOUS` — write `docs/lessons/README.md` with a one-line open-schema statement ("h1 title + topical sections, no YAML frontmatter, no strict schema").
- `SURFACE-2026-06-13-QUALITY-ARCH-INLINE-COMMENT-REDUNDANT` — delete the redundant same-day-edit HTML comment at `docs/product/arch.md:6`.
- `SURFACE-2026-06-26-QUALITY-CORPUS-OPEN-QUESTIONS-STALE` — mark Q1/Q2 RESOLVED inline in `docs/lessons/design-priors-corpus.md`.
- `SURFACE-2026-06-30-QUALITY-UTIL-PAYDOWN-GRAMMAR-AN-A` — `An` → `A` in `skills/util-backlog-paydown/SKILL.md` Rule-1 parenthetical.
- `SURFACE-2026-06-30-QUALITY-UTIL-PAYDOWN-ORDERING-NESTING` — promote the "Risk outranks impact in ordering" clarification out from under ordering-rule 5 to a top-level note, in BOTH `skills/util-backlog-paydown/SKILL.md` and `docs/lessons/between-milestone-debt-paydown-sweep.md`.
- `SURFACE-2026-06-23-QUALITY-MINHARNESS-ROUND-THRESHOLD-NOTE` — one-line clarify in `skills/debug-minimal-harness/SKILL.md` that 3-round = inconclusive-escalation, 5-round = optional traceability note.
- `SURFACE-2026-06-26-QUALITY-FIXTURE-USES-PHASE-ALIAS` — rename "Phase 1/2/3" → "Milestone 1/2/3" in `tests/fixtures/product/design-priors-consult/roadmap.md`.

**Shape:** `/task-plan` (docs+prose bundle). Run `./tests/check-structure.sh` after (registry: `./tests/check-structure.sh` timeout 600000ms).

---

### WP2 — check-structure.sh pin tightening + settings-fixture strip  `[impact: med · effort: Small · risk: low]`
Structural-test edits. Low risk: each is grep_check pattern/allowlist logic
covered by the structural suite itself (self-verifying — the suite re-runs green).

Resolves:
- `SURFACE-2026-06-19-QUALITY-CONTAINER-DOWN-PIN-OVER-BROAD` — tighten the container-down pin (`tests/check-structure.sh:~178`) from `containers are down|docker compose up` to a distinctive anchor tied to the new clause (e.g. `start the container\(s\) yourself`).
- `SURFACE-2026-06-26-QUALITY-PROPOSE-PIN-TOO-LOOSE` — change the 6 Phase-13 `propose` pins (`tests/check-structure.sh:1929`) from bare `propose` → `propose-never-auto-write` (the actual contract phrase).
- `SURFACE-2026-06-26-SETTINGS-FIXTURE-DRIFT-DISABLECLAUDEAICONNECTORS` (dedup'd with the WP0-deleted 06-30 twin) — extend `strip_host_specific()` (`tests/check-structure.sh:~1099`) to also drop a small allowlist of known machine-local **top-level** keys (`disableClaudeAiConnectors`, future connector/UI toggles) from BOTH live and fixture before diffing. Same pattern as the claudesk-hook strip; keeps repo-owned keys fully drift-checked. **Unblocks a currently-FAILing Phase-7 check.**

**Shape:** `/task-plan`. Run `./tests/check-structure.sh` after — it MUST return 0 (esp. Phase 7 now passing).

---

### WP3 — Add frontmatter-YAML-parseability structural phase  `[impact: med · effort: Small · risk: low]`
New structural check. Silent-failure vector (invalid frontmatter → non-invokable
skill, silent until next session start). Low risk: additive check, self-verifying.

Resolves:
- `SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN` (Order P1) — add a phase to `tests/check-structure.sh` that iterates `skills/*/SKILL.md` + `agents/*/AGENTS.md`, extracts frontmatter between `---` markers, pipes through `python3 -c "import sys,yaml; yaml.safe_load(sys.stdin.read())"`, and fails on any non-zero exit.
  - **Placement (from folded-in `SURFACE-2026-06-13-QUALITY-YAML-PIN-PLACEMENT-NOTE`):** land it as a **Phase 3a** addition to the existing frontmatter-validation pass — NOT a tail phase — so it doesn't visually orphan the close-commit Phase-11 block or disturb the PASS-count sequence.

**Shape:** `/task-plan`. Run `./tests/check-structure.sh` after; property-test the new check against a deliberately-broken fixture frontmatter per `docs/lessons/test-harness-primitives.md` (confirm it FAILs on bad YAML, PASSes on good).

---

### WP4 — DISC1: rename design-priors consult heading  `[impact: med · effort: Small · risk: low]`
Convention cleanup ruled by operator (rename, not broaden). "Step 0" stays
reserved for the 6 entry-point product-context-load skills.

Resolves:
- `SURFACE-2026-06-26-QUALITY-STEP0-ON-NON-ENTRY-SKILLS` — rename the design-priors consult block heading in `skills/product-roadmap/SKILL.md:21` and `skills/product-wbs/SKILL.md:36` from `## Step 0: Available product context` to a distinct heading (e.g. `## Design-priors consult`). Update the Phase-13 pins (`tests/check-structure.sh:1916-1917`) to match the new heading if they anchor on it (they currently pin the `design-priors\.md` substring, so likely no pin change — verify). Confirm `transitions.md:232` entry-point list and `CLAUDE.snippet.md` per-skill mapping read consistently after (transitions.md:238 already describes the consult as `## Step 0` — update that phrasing to the new heading).

**Shape:** `/task-plan`. Run `./tests/check-structure.sh` after — Phases 3 + 13 must stay green.

---

### WP5 — DISC3: odd-shape-findings-probe-more heuristic → CLAUDE.md memory  `[impact: med · effort: XS · risk: none]`
Operator ruled: land as the cheaper of the two options (memory addition, not
verify-self-runner prompt change). Judgment-shaped heuristic; a hard gate is out.

Resolves:
- `SURFACE-2026-06-16-ODD-SHAPE-FINDINGS-PROBE-MORE-HEURISTIC` (Order P4) — add a `feedback`-type memory (`<proj-dir>/.claude/memory/`) capturing: "When a verify-self / review-quality finding diverges from the standard idiom for its class of system, treat the divergence as a signal to invest one more curiosity cycle before shipping — autopilot objective gates can't catch it." Read the full learning at `.claude/learnings/2026-06-16-odd-shape-findings-deserve-one-more-cycle.md` first. Add the MEMORY.md index pointer. (The verify-self-runner prompt-augmentation half is explicitly NOT done — deferred by operator ruling; note that in the memory body so it isn't re-proposed.)

**Shape:** `/task-plan` (memory write + MEMORY.md pointer). `docs-only: true`-adjacent (no code/test surface). Per artifact-tracking policy, PII-audit the memory file after writing.

---

### WP6 — DISC2: per-scenario `claude_md:` fixture support + neutral consult-scenario rewrite  `[impact: med-high · effort: Medium (WP-sized) · risk: MEDIUM — sorts LAST]`
**The one genuine high-effort escapee.** Operator ruled "Sweep it anyway."
Sorts last: highest effort + highest risk in the batch (touches the test runner
that every other scenario depends on). Run only after WP0–WP5 are banked.

Resolves (these two pair — the second depends on the first):
- `SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE` — make `tests/run-tests.sh` honor a per-scenario `claude_md:` key: (a) parse the key; (b) copy the named fixture instead of the fixed `fixtures/CLAUDE.md` at `run-tests.sh:171`; (c) add `tests/fixtures/CLAUDE-with-tracking-override.md` declaring `## Artifact tracking overrides`; (d) add scenario `S20-global-override-tracked` asserting the proposal mentions commit/amend (tracked branch). **Property-test the new fixture-key path** per `docs/lessons/test-harness-primitives.md` (full input-shape enumeration: key present/absent/malformed/nonexistent-file).
- `SURFACE-2026-06-26-QUALITY-CONSULT-SCENARIOS-PROMPT-LEAKAGE` — rewrite the DP-consult-* scenarios in `tests/scenarios/product.yaml` to present the decision context **neutrally** (state the open product-design question + that a `design-priors.md` exists, WITHOUT pre-stating in `system_prompt_extra` whether/how a prior should fire) so the loaded SKILL.md consult contract drives the outcome — closing the "tests obedience > tests the skill prose" weakness on the over-infer guard.

**Shape:** `/feature-plan` (small feature — new harness functionality + scenario rewrites + property-test; fails the ≤200-line/atomic bar for a task). Run `./tests/run-tests.sh --group product` + a property-test pass after. This is the WP most likely to need its own verify loop — treat it as a real feature, not a mechanical edit.

---

## Scope — what's NOT swept (anchors intact)

| Item | Action | Reason | Anchor |
|------|--------|--------|--------|
| `SURFACE-2026-06-25-AUDIT-PROMPT-LATITUDE-NEWER-CLIENT-MODEL` | **Defer** | Open-ended proactive audit of the whole instruction surface (SKILL.md + AGENTS.md + CLAUDE.snippet.md) for implicitly-forbidden-but-never-named behaviors a more agentic model might reach for. High-effort + high-impact investigation, not a mechanical edit. Operator ruled Defer. | Future dedicated `/feature-spec` (instruction-surface audit). Stays in `workflow/backlog.md`, priority medium. |
| DISC3 verify-self-runner prompt-augmentation half | **Defer** (partial) | The odd-shape heuristic's memory half is swept in WP5; the verify-self-runner prompt-augmentation half (`agents/feature-verify-self-runner/AGENTS.md`) is deferred per operator ruling ("Sweep DISC3 only" = memory only). | Revisit if the memory-only version proves insufficient in a future autopilot run. Noted inside the WP5 memory body. |
| `SURFACE-2026-06-23-QUALITY-MINHARNESS-GATEMET-IDIOM-DIVERGENCE` | **Bury** | Low-impact idiom divergence; the inline comment already safeguards it; the finding self-describes "leave-as-is acceptable." Operator ruled Bury. | Moved to `workflow/backlog-deferred-2026-05.md` (Buried 2026-07-13). Removed from active backlog. |

**Also intact (never in scope):** all durable product docs (`vision.md`, `arch.md` narrative, `transitions.md` state machine, `roadmap.md`), the feature Work Tree "Phase" schema, and the buried-2026-05/2026-06 items in `workflow/backlog-deferred-2026-05.md`.

---

## Fold-back-and-delete completion

When all WPs above are driven to done (via `/feature-refactor` / `/task-*` / `/feature-plan`), the finalize/close skills will have auto-resolved each SURFACE and appended `**Backlog resolved:**` lines to `CHANGELOG.md`. Then execute:

1. **Confirm RESOLVED:** grep `workflow/backlog.md` + `workflow/backlog-quality-findings.md` — every SURFACE-ID listed in WP0–WP6 should now be gone (deleted in WP0) or marked resolved by its closing skill. Any straggler still `pending`/`open` → its WP isn't actually done.
2. **Execute Bury (from Scope table):** move `SURFACE-2026-06-23-QUALITY-MINHARNESS-GATEMET-IDIOM-DIVERGENCE` full content to `workflow/backlog-deferred-2026-05.md` under a `Buried 2026-07-13:` heading; remove from `workflow/backlog-quality-findings.md`.
3. **Confirm Defer anchors:** `SURFACE-2026-06-25-AUDIT-PROMPT-LATITUDE-NEWER-CLIENT-MODEL` remains in `workflow/backlog.md` (priority medium, anchored to a future `/feature-spec`). Do NOT delete it.
4. **Delete this file:** `git rm docs/product/backlog-paydown-2026-07-13-wbs.md`. It reserves no roadmap slot; it is done.
5. **Verify:** `./tests/check-structure.sh` returns 0 and `./tests/run-tests.sh --group product` passes (WP6 touched the runner).
