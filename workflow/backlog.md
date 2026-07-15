# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention). **Code-quality findings** auto-backlogged by `feature-review-quality` are pointer-collapsed here — full content lives in `workflow/backlog-quality-findings.md`, grouped by source feature.

---

## TODO

## SURFACE-2026-07-15-RUN-TESTS-ID-FILTER-PARSES-ALL-SCENARIOS-FIRST
- **Source:** feature:build (delete-on-resolve-backlog-convention Phase 3 P3.3)
- **Target level:** task:plan (test-harness perf/UX)
- **Type:** tech-debt
- **Summary:** `tests/run-tests.sh --id <ids>` parses **every** scenario in all group YAMLs before applying the `--id` filter, so even a `--dry-run` of 4 targeted IDs exceeds 60s (never printed within the timeout). The filter is applied post-parse (run-tests.sh:~155-164), so targeting a tiny subset gets no speedup over a full parse.
- **Context:** Discovered while confirming the 4 delete-on-resolve scenarios. The real (model-executing) run of 4 scenarios took 105s and worked fine — the slowness is purely the parse-before-filter in `--dry-run` / setup. Low-value to fix (the real run works; dry-run is a convenience), but a short-circuit (skip parsing a scenario's body when its `id` doesn't match `--id`) would make `--dry-run --id` and small `--id` batches near-instant.
- **Suggested action:** `/task-plan` — move the `--id` match to a cheap pre-parse `id:`-line scan so non-matching scenarios are skipped before full parse. Property-check against `--id` single/multi/none + `--group`.
- **Priority:** low
- **Status:** open

## SURFACE-2026-07-13-STEP0-PREAMBLE-VS-PROCEDURE-RENUMBER
- **Source:** operator observation during backlog-paydown WP4 (2026-07-13)
- **Target level:** task:plan (prose-only skill-structure cleanup; sizing TBD — may touch several skills)
- **Type:** tech-debt (doc-structure clarity)
- **Summary:** Several skills use a `## Step 0: <name>` **top-level** heading as a pre-procedure preamble, then a *separate* `### 1. / ### 2. …` numbered list under `## Procedure`. The dual numbering scheme (a "Step 0" that isn't part of the `### 1/2/3` sequence) reads awkwardly and confuses "is Step 0 the first procedure step or a preamble?". Renumber/reframe so the step scheme is coherent — e.g. make the preamble un-numbered ("## Preamble: …" or "## Before you start") OR fold it into a `### 0.`/`### 1.` that's actually part of the procedure sequence.
- **Context:** Surfaced while doing WP4 (which only renames the design-priors consult *suffix* to disambiguate from the pinned entry-point `## Step 0: Available product context` convention — it does NOT touch the numbering). The renumber is a broader, separate cleanup: it likely spans all skills carrying a `## Step 0` (the 6 entry-point skills + the 2 renamed by WP4), and must stay consistent with the Phase-3 structural pins that assert the literal `## Step 0: Available product context` string for entry-point skills — so any rename of the entry-point heading requires a matching Phase-3 pin update (tripartite-sync discipline). Do NOT bundle into WP4.
- **Suggested action:** `/task-plan` — decide the coherent scheme, apply across all `## Step 0`-bearing skills, update the Phase-3 pins to match. Property-check the pin strings after.
- **Priority:** low
- **Status:** open

## Code-quality findings — memory-location-symlink (2026-07-03)
- **Pointer:** 2 MINOR findings auto-backlogged by feature-review-quality against ship commit d173bd7 — (1) `ensure-memory-link.sh` dry-run emits a stray `cd: No such file` on stderr when repo target dir doesn't exist yet + harness already symlinked (diagnostic noise, verdict correct); (2) the "any project with docs/product/" migration scope rule is prose-only, not script-enforced (acceptable given the P2.2 operator-confirmation gate). The 2 MAJOR findings from the same review were fixed in-place (amended into the ship commit) — see the WIP `## Code-Quality Review` section. Full bodies in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** small task — (1) is a ~2-line dry-run guard; (2) is a one-line README prose softening. Bundle into a `/task-plan` or the next `/util-backlog-paydown` sweep.

## MAYBE

_(no open items)_

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


## SURFACE-2026-06-25-AUDIT-PROMPT-LATITUDE-NEWER-CLIENT-MODEL
- **Source:** incident:resolve (incident-autopilot-askuserquestion-pauses)
- **Target level:** task:plan
- **Type:** tech-debt
- **Summary:** The AskUserQuestion-on-AUTO regression and the earlier auto-branching regression (commit 73e97e2) are two instances of one class: a newer client / Opus 4.8 acting on latitude the prompts never explicitly closed. Each was fixed reactively after biting. A proactive audit of the instruction surface (SKILL.md + AGENTS.md + CLAUDE.snippet.md) for other "implicitly-forbidden-but-never-named" behaviors a more capable/agentic model might reach for (e.g. unrequested branching, spawning subagents, web fetches, file deletions on AUTO paths) would close the class instead of waiting for the next instance.
- **Context:** See `workflow/archive/incident-autopilot-askuserquestion-pauses.md` (Root Cause + F5) — two data points established the class.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-07-14-HARNESS-BUDGET-EXHAUSTION-LAUNDERED-AS-FLAKY
- **Source:** feature:verify-self (WP6 of backlog-paydown-2026-07-13)
- **Target level:** task:plan (test-harness observability)
- **Type:** gap
- **Summary:** `tests/run-tests.sh` silently launders a per-attempt `Error: Exceeded USD budget` into a generic FAIL→retry→FLAKY, so the operator cannot distinguish "model is nondeterministic" (real FLAKY) from "scenario hit the budget ceiling" (a cost/config issue). The runner already computes the string `"possibly budget exceeded or error"` (run-tests.sh:~245) but only for *totally empty* output, and never surfaces it in the FLAKY list or results JSON.
- **Context:** The per-scenario `budget:` key (the original (b) half) shipped in WP6 of backlog-paydown-2026-07-13 (see CHANGELOG). This entry now tracks only the remaining (a) half — the observability fix. Affects any expensive scenario (session-store-learning full-policy-reasoning, product-* decomposition, etc.) on sonnet.
- **Suggested action:** Detect the `Error: Exceeded USD budget` sentinel in `result_text` and label it distinctly in the FLAKY/FAIL detail + results JSON (e.g. status `BUDGET_EXCEEDED` or a `budget_exceeded: true` field), so a budget-driven retry-pass is visibly different from a nondeterminism-driven one. Cheap, high-value.
- **Priority:** medium
- **Status:** open (remaining (a) observability half; the (b) per-scenario budget key already shipped — recorded in CHANGELOG)

## Code-quality findings — wp6-per-scenario-claude-md-fixture-and-neutral-consult (2026-07-14)
- **Pointer:** 3 MINOR findings from feature-review-quality (WP6 ship e2494f9), all on the check-structure.sh [Phase 3f] property-test: (1) `_resolve_claude_md` mirrors the runner branch rather than exercising it — add lockstep-comment; (2) line-number refs in Phase 3f comments rot — anchor on a stable string; (3) `_pt_claude` `grep -q`→`grep -qF` hardening. Full bodies in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** all 3 are cheap+safe 1-line edits (#1/#3 apply directly; #2's exact line numbers need verifying against the committed file first per the "review-finding suggested-actions are hypotheses" Context Rule). Natural candidates for the next `/util-backlog-paydown` sweep or a small `/task-plan`.

