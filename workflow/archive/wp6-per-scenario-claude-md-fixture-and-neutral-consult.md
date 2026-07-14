# Feature: WP6 — per-scenario `claude_md:` fixture support + neutral DP-consult scenario rewrite

**Workflow:** feature
**State:** COMPLETED 2026-07-14 (ship e2494f9; finalize)
**Created:** 2026-07-14
**drive_mode:** autopilot
**Parent:** backlog-paydown-2026-07-13 sweep → WP6 (`docs/product/backlog-paydown-2026-07-13-wbs.md`)

## Problem Statement

WP6 is the one genuinely feature-sized item in the 2026-07-13 backlog-paydown sweep — sorts last because it touches `tests/run-tests.sh`, the runner every scenario depends on. Two paired SURFACEs (the second depends on the first):

1. **`SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE`** — the runner hardcodes `cp "$FIXTURES_DIR/CLAUDE.md"` at `run-tests.sh:171` and **ignores** the `fixtures.claude_md:` key. **Discovery at plan time:** 179 scenarios across all 7 scenario files *already declare* `claude_md: fixtures/CLAUDE.md`, but the runner never reads that key — the bug is latent only because every declaration happens to name the same fixed file. Making the runner *honor* the declared key unlocks per-scenario CLAUDE.md fixtures, needed to test scope/tracking behavior that depends on a project's `## Artifact tracking overrides`.

2. **`SURFACE-2026-06-26-QUALITY-CONSULT-SCENARIOS-PROMPT-LEAKAGE`** — the 4 `DP-consult-*` scenarios in `tests/scenarios/product.yaml` pre-state the answer in `system_prompt_extra` (they recite the consult rules and instruct the outcome — "apply the consult-weighting rules; disclose the firing prior", "per the over-infer guard, a prior only fires on the axis it governs"). That tests *obedience to the prompt*, not the loaded SKILL.md consult contract. Rewrite them to present the decision context **neutrally** (the open product-design question + that a `design-priors.md` exists in the fixture) so the SKILL.md prose drives the outcome — closing the weakness on the over-infer guard.

Re-examined on every back-loop entry; not static.

[Updated 2026-07-14 — F12 back-loop re-check] Problem statement unchanged in substance, understanding sharpened: the `S20-global-override-tracked` FLAKY observed at verify-self was NOT model nondeterminism (my initial verify-self hypothesis, retracted) but a **budget-ceiling collision** — attempt 1 returned `Error: Exceeded USD budget (0.2)` because the heavy `session-store-learning` full-policy-reasoning path costs >$0.20 on sonnet. Operator ruled (vh.2) the durable fix: add a per-scenario `budget:` key to the runner (P1.6) so expensive scenarios declare their own headroom, rather than trimming the scenario or accepting a knowingly-FLAKY result. Root problem (make the tracked-override key path verifiable end-to-end) is intact; P1.6 is the enabling harness support the fix needs.

## Work Tree

- [x] Phase 1: Runner honors `fixtures.claude_md`; add override fixture + tracked-scope scenario  <!-- status: DONE — all impl (P1.1-P1.6) + verify-auto/self/human/codify complete -->
  <!-- consumed SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE (fully) + SURFACE-2026-07-14-HARNESS-BUDGET-EXHAUSTION-LAUNDERED-AS-FLAKY (b-half: per-scenario budget key; a-half sentinel-labeling still open) -->
  **Observable outcomes:**
  - CLI: `grep -n 'fixture_claude_md=$(parse_scenario_nested' tests/run-tests.sh` → exits 0 (the key is now parsed).
  - CLI: `grep -n 'cp "$SCRIPT_DIR/$fixture_claude_md"' tests/run-tests.sh` → exits 0 (honored path; falls back to `$FIXTURES_DIR/CLAUDE.md` when the key is absent).
  - CLI: property-test script (`scratchpad/wp6-claude-md-proptest.sh`) enumerates the 4 input shapes and asserts the correct file lands in the temp project — exits 0. Shapes: (a) **present** → named fixture copied; (b) **absent** → default `fixtures/CLAUDE.md` copied; (c) **malformed** (empty/whitespace value) → treated as absent, default copied, no crash; (d) **nonexistent file** (`claude_md: fixtures/DOES-NOT-EXIST.md`) → runner does not crash and copies nothing/falls back (matching the `[ -f ... ]` guard idiom of the sibling fixture keys).
  - CLI: `test -f tests/fixtures/CLAUDE-with-tracking-override.md && grep -q '## Artifact tracking overrides' tests/fixtures/CLAUDE-with-tracking-override.md` → exits 0.
  - CLI: `./tests/run-tests.sh --id S20-global-override-tracked --model sonnet` → the scenario PASSes (the loaded `session-store-learning` proposes committing/amending the global-scope learning because the fixture CLAUDE.md declares `## Artifact tracking overrides` making `.claude/learnings/` a *tracked* path).
  - CLI: `./tests/check-structure.sh` → exits 0 (no structural pin regressed by the runner edit).
  - [x] P1.1 Add `fixture_claude_md` local via `parse_scenario_nested ... "fixtures" "claude_md"` alongside the other `fixture_*` locals (`run-tests.sh:128`).  <!-- status: DONE -->
  - [x] P1.2 Replaced the hardcoded `cp "$FIXTURES_DIR/CLAUDE.md"` with honor-key-else-fallback at `run-tests.sh:176-181`: honors `$fixture_claude_md` (resolved `$SCRIPT_DIR/$fixture_claude_md`, `[ -f ]`-guarded like sibling keys) when it names an existing file; else falls back to `$FIXTURES_DIR/CLAUDE.md`. `|| true` non-fatal behavior preserved.  <!-- status: DONE -->
  - [x] P1.3 Added `tests/fixtures/CLAUDE-with-tracking-override.md` declaring `## Artifact tracking overrides` that TRACKS `<proj-dir>/.claude/learnings/` (source-repo override case) → global-scope learning committed/amended.  <!-- status: DONE -->
  - [x] P1.4 Added scenario `S20-global-override-tracked` to `tests/scenarios/session.yaml` (after S20-global-canonical-path): `fixtures.claude_md: fixtures/CLAUDE-with-tracking-override.md`, global-scope args, `expect.transition_id: S20` + `contains_required: [.claude/learnings/]` + `contains_required_any: [git commit --amend, amend, git add]`. Started UNTAGGED (haiku) per recon discipline. session.yaml parses; 31 scenarios; new id present.  <!-- status: DONE -->
  - [x] P1.5 Wrote + ran `scratchpad/wp6-claude-md-proptest.sh` (4 input shapes: present/absent/malformed/nonexistent). **ALL 4 SHAPES PASS** — isolates the copy branch, asserts correct file lands per shape without spinning up the CLI. (NB: observable-outcome greps in the phase header used approximate quoting; the working greps are `grep -n 'fixture_claude_md' tests/run-tests.sh` → lines 128, 176, 177.)  <!-- status: DONE -->
  - [x] P1.6 Added per-scenario `budget:` key to `tests/run-tests.sh` (parse at `:111` via `parse_scenario_field ... "budget"`; used at `:236` as `--max-budget-usd "${scenario_budget:-$MAX_BUDGET}"` — falls back to global default when absent) and set `budget: "0.50"` on `S20-global-override-tracked`. **Re-verified end-to-end: scenario now PASSes CLEANLY (not FLAKY) — session PASS 1, FLAKY 0.** Consumes the (b) half of SURFACE-2026-07-14-HARNESS-BUDGET-EXHAUSTION-LAUNDERED-AS-FLAKY (the (a) budget-exhaustion-observability-labeling half remains open). Added at verify-human (F12 back-loop) — operator ruled the durable root-cause fix over trimming args.  <!-- status: DONE -->
    - [ ] P1.6 SURFACE — per-scenario budget key partially resolves SURFACE-2026-07-14-HARNESS-BUDGET-EXHAUSTION-LAUNDERED-AS-FLAKY; the (a) sentinel-detection/labeling half stays pending in backlog.  <!-- status: SURFACED: budget-key done, exhaustion-labeling deferred -->
  - [x] verify-auto  <!-- status: DONE (covers P1.1-P1.6) — bash -n OK; session.yaml parses (31 scenarios, budget:'0.50' present); property-test 4/4 PASS; scenario_budget parse@:111 + fallback@:236 confirmed. Re-run after P1.6 back-loop. -->
  - [x] verify-self  <!-- status: DONE (covers P1.1-P1.6) — end-to-end run proves the runner honors fixtures.claude_md AND the new per-scenario budget: key: S20-global-override-tracked now PASSes CLEANLY (session PASS 1, FLAKY 0) at budget 0.50, matching TRANSITION: S20 + content assertions first-try (only reachable if the override CLAUDE.md was copied+read). Root cause of the earlier FLAKY was BUDGET-CEILING, fixed durably by P1.6. Backward-compat fallback confirmed (S1/S2). Integration boundary (runner's CLAUDE.md copy path) satisfied. -->
  - [x] verify-human  <!-- status: DONE — vh.1 PASS (backcompat S1/S2); vh.2 APPROVED after operator-requested robustness batch (5/5 consecutive clean first-attempt PASSes, zero FLAKY, post budget-key fix) -->
    - [x] P1.verify-human.1 Backward-compat: existing scenarios still run identically after the runner edit  <!-- status: DONE — demoed S1 SOFT_PASS (pre-existing), S2 PASS; else-branch preserves the 179 declarations -->
    - [x] P1.verify-human.2 Disposition of S20 FLAKY — operator ruled budget-key fix (P1.6); operator pre-approved and requested a robustness batch. Result: 5/5 consecutive CLEAN first-attempt PASSes (103449 + robustA/B/C/D), zero FLAKY. Budget-ceiling diagnosis corroborated (5 straight clean passes would be improbable under real model nondeterminism). APPROVED.  <!-- status: DONE -->
  <!-- [SHORTCUT-2026-07-14] a mid-run truncated results file (105238.json) was a wrapper-timeout kill by the orchestrator, NOT a scenario failure; deleted so it can't be mistaken for a real observation. -->
  - [x] verify-codify  <!-- status: DONE — behavior 3 (S20 scenario) already permanent CI test (5/5 clean); behaviors 1&2 (runner fixture-key logic) newly codified as [Phase 3f] in check-structure.sh (4 grep_check drift-pins + 6 property-test shapes, all PASS). Full structural suite: 411 PASS / 0 FAIL (up from 401; +10 = Phase 3f). No triage needed. -->

- [x] Phase 2: Rewrite the 4 `DP-consult-*` scenarios to present decision context neutrally  <!-- status: DONE — all impl (P2.1-P2.4) + verify-auto/self/human/codify complete. Consumed SURFACE-2026-06-26-QUALITY-CONSULT-SCENARIOS-PROMPT-LEAKAGE. -->
  **Observable outcomes:**
  - CLI: `grep -c 'apply the consult-weighting rules\|per the over-infer guard\|Per the consult rules' tests/scenarios/product.yaml` → 0 (the answer-reciting instructions are gone from the 4 consult `system_prompt_extra` blocks).
  - CLI: each rewritten `system_prompt_extra` still names the open product-design question and (for the 3 fixture-present cases) that a `design-priors.md` exists — but does NOT state whether/how a prior should fire. Manual read-confirm each of the 4 blocks.
  - CLI: `./tests/run-tests.sh --id DP-consult-changes,DP-consult-nochange-overinfer,DP-consult-noprior-90pct,DP-consult-contradiction` → all 4 PASS. This is the load-bearing outcome: they must pass **driven by the loaded SKILL.md consult contract**, not the prompt. (If haiku is noisy on the now-neutral prompts, escalate the specific flaky one to `--model sonnet`, confirm deterministic PASS, then tag it — recon discipline.)
  - CLI: `./tests/check-structure.sh` → exits 0 (Phase-13 DP pins unaffected — they anchor on skill prose, not scenario prompts).
  - [x] P2.1 Rewrote `DP-consult-changes`: now states only the open question (multi-seat/agencies vs single-operator) + "design-priors.md is present". Dropped "SAME axis as P-FOCUS" + "apply the consult-weighting rules; disclose the firing prior". Assertions kept.  <!-- status: DONE -->
  - [x] P2.2 Rewrote `DP-consult-nochange-overinfer`: now poses only the copy-tone question + "design-priors.md is present". Dropped the recited over-infer guard + "do NOT cite or stretch". `not_contains: [PRIOR: P]` + strict + explanatory comment preserved.  <!-- status: DONE -->
  - [x] P2.3 Rewrote `DP-consult-noprior-90pct`: now poses an ordinary config question, no mention of design-priors at all (the roadmap-done fixture has none — absence is discovered via Step-0 ls, not stated, which itself would leak). Dropped "There is NO design-priors.md" + "Do not invent". `not_contains: [PRIOR:]` + strict preserved.  <!-- status: DONE -->
  - [x] P2.4 Rewrote `DP-consult-contradiction`: now presents the collaboration milestone as an appealing common-sense default + "design-priors.md is present". Dropped "recorded prior P-FOCUS says…" + "the 10% contradiction case" + "surface as a PROPOSAL / do NOT silently add/drop". Assertions kept.  <!-- status: DONE -->
  - [x] verify-auto  <!-- status: DONE — product.yaml parses (25 scenarios); all 4 DP-consult scenarios structurally intact; reciting-phrase count 0; 3 fixture-present scenarios mention design-priors.md. Behavioral check deferred to verify-self. -->
  - [x] verify-self  <!-- status: DONE — LOAD-BEARING result: all 4 neutrally-rewritten DP-consult scenarios PASS on HAIKU, attempts:1, no flaky (run-2026-07-14-112829.json): changes→P8, nochange-overinfer→P9, noprior-90pct→P7, contradiction→P3. Proves the loaded product-wbs/product-roadmap SKILL.md consult contract drives the outcome now that the prompts no longer recite the answer — closes the prompt-leakage weakness (SURFACE-2026-06-26). No sonnet escalation needed. No integration boundary (test-scenario data edits only). -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [x] verify-human  <!-- status: DONE (AUTO-SKIP F11) — no integration boundary (test-scenario data edits only), verify-self all-PASS, drive_mode=autopilot → all 4 auto-skip gates clean. Affirmation block printed for operator read-time veto. -->
  - [x] verify-codify  <!-- status: DONE — the 4 DP-consult-* scenarios ARE the permanent CI behavioral tests (no new test needed; rewrite improved their fidelity). No integration boundary (isolated test-scenario data). Re-ran structural suite after the product.yaml edit: 411 PASS / 0 FAIL — scenario-YAML-integrity + Phase-13 DP pins all green. No triage needed. -->

## Current Node
- **Path:** Feature > finalize
- **Active scope:** review-quality `[x]` — 0 CRITICAL / 0 MAJOR / 3 MINOR, all auto-backlogged (F39). Next: finalize.
- **Blocked:** none
- **Unvisited:** finalize; then fold-back-and-delete the temporary-WBS (WP6 is the last WP in the backlog-paydown-2026-07-13 sweep — see Fold-back-and-delete completion section in the WBS).
- **Relevance check (before Phase 2):** requester-needs=yes (paired half of WP6) · requirements-unchanged=yes · feasible=yes (Phase 1 runner support landed) · no-superior-alt=yes. **Verdict: proceed.**
- **Open discoveries:**
  - `[SURFACED-2026-07-14] Phase 1 — 179 scenarios already declare fixtures.claude_md but the runner ignores the key (latent bug, all name the same fixed file). Honoring the key is backward-compatible: existing declarations resolve to the same default. Logged to sweep parent, not re-surfaced to backlog (it IS SURFACE-2026-06-25).`

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
- [SURFACED-2026-07-14] Phase 1 — 179 scenarios across all 7 scenario files already declare `fixtures.claude_md: fixtures/CLAUDE.md`, but `run-tests.sh` never reads the key (always `cp "$FIXTURES_DIR/CLAUDE.md"`). The bug is latent because every declaration names the same fixed file. Honoring the key is fully backward-compatible — every existing `claude_md: fixtures/CLAUDE.md` resolves to the identical default. This IS `SURFACE-2026-06-25-PER-SCENARIO-CLAUDE-MD-FIXTURE`; not a new backlog entry.
- [SHORTCUT-2026-07-14] P1.4 — at verify-self the new `S20-global-override-tracked` scenario read FLAKY-passes-on-retry. Applied the in-place fix shortcut (3 gates held): (a) trivial extension of the just-written leaf — added `model: sonnet` tag + a diagnostic comment to the scenario; (b) fresh re-verification — re-ran the scenario through the REAL claude CLI (proving the runner honored `fixtures.claude_md` end-to-end: every completed attempt reached `TRANSITION: S20` + content assertions); (c) this audit-trail entry.
- [DIAGNOSIS-CORRECTION-2026-07-14] P1.verify-human.2 — my initial verify-self FLAKY hypothesis ("first-attempt model-noise on the TRANSITION token, upstream of the content bar") was WRONG — I asserted it without inspecting a failing attempt's raw output. Operator (vh.2) pushed for the actual root cause. Captured a raw first-attempt: it returned 32 bytes = `Error: Exceeded USD budget (0.2)`. Re-ran the SAME invocation at `--budget 0.50` → 3799-byte full response with `TRANSITION: S20` + `.claude/learnings/` (×4) + amend/git-add (×2). **Real cause = BUDGET-CEILING COLLISION, not model noise, not a skill/prompt defect.** The scenario's args ("classify global scope + propose destination AND what git handling applies") drive the full artifact-tracking-policy reasoning path, which on sonnet costs >$0.20 (the runner's global default `--max-budget-usd`). Attempt 1 dies on budget → generic FAIL → retry sometimes squeaks under → FLAKY. Layer verdict: SKILL/PROMPT = not the problem (completes correctly given budget); SCENARIO (mine) = contributing (over-heavy args); HARNESS = contributing + observability gap (budget-exhaustion silently laundered as FLAKY; no per-scenario budget key). Harness gap logged as SURFACE-2026-07-14-HARNESS-BUDGET-EXHAUSTION-LAUNDERED-AS-FLAKY (medium). Fix for the scenario itself pending operator decision (trim args vs other) — this is why verify-human did NOT auto-approve.
- [BACKCOMPAT-2026-07-14] P1.verify-human.1 — ran `--id S1,S2,S6` (existing scenarios declaring `claude_md: fixtures/CLAUDE.md`) on default model: S1 SOFT_PASS (its known pre-existing behavior), S2 PASS — behaving identically to pre-edit. Confirms the runner's else-branch fallback preserves the 179 existing declarations. Backward-compat demonstrated.

## Code-Quality Review — wp6-per-scenario-claude-md-fixture-and-neutral-consult

Reviewed against ship commit e2494f9 (base 7b59b10). Result: **0 CRITICAL, 0 MAJOR, 3 MINOR** → Case C, autopilot auto-backlog + F39.

### Strengths
- `fixtures.claude_md` honor-else-fallback mirrors the sibling-key `[ -n ] && [ -f ]` idiom; the 179 pre-existing declarations resolve identically → nothing regresses.
- Property-testing the new input shape across the full namespace (present/absent/whitespace/nonexistent) follows `test-harness-primitives.md`; dual-guard (grep_check drift-pins + executable semantics) is the right shape.
- `budget: "0.50"` + `model: sonnet` empirically grounded (raw 32-byte budget-error capture), not preemptive safety-blanketing.
- DP-consult rewrites genuinely close the leakage weakness; verify-self confirmed 4/4 haiku PASS driven by the SKILL.md prose.
- Clean SURFACE split: (b) budget-key consumed here, (a) sentinel-labeling left as scoped backlog entry.

### Issues
**CRITICAL** — (none)
**MAJOR** — (none)
**MINOR**
- [tests/check-structure.sh Phase 3f] `_resolve_claude_md` is a hand-transcribed COPY of the runner's branch, not the runner logic itself — the two can drift; the grep_check pins only assert the source line still exists, not that the copy matches it. Worth a comment noting the copy must be updated in lockstep.
- [tests/check-structure.sh Phase 3f comments] Comments cite `run-tests.sh:176-181`/`:236` for the mirrored one-liners; the actual claude_md branch shifted to ~183-187 after edits. Line-number refs in comments rot; prefer anchoring on a stable string.
- [tests/check-structure.sh `_pt_claude`] Uses `grep -q "$want"` (unanchored, unescaped) — fine for current all-caps markers, but a future `want` with a regex metachar would misfire silently; `grep -qF` is trivial hardening.

### Assessment
Well-built, appropriately-scoped test-harness feature; advances the codebase without accruing debt. Runner change is the smallest edit that unlocks per-scenario CLAUDE.md fixtures and generalizes to the sibling-key idiom. Verification story unusually strong (FLAKY retracted → budget-ceiling root-caused via raw capture → durable per-scenario budget key → 5/5 clean batch). Only real lever: the property-test mirrors rather than exercises the runner's actual branch — a reasonable shell tradeoff, mitigated by drift-pins, not worth a refactor pass.

### If you disagree
Dismiss any finding by editing this section and marking the line `[DISMISSED]` before finalize archives the WIP.

## Retrospect
- **What changed in our understanding:** Two discoveries. (1) The `fixtures.claude_md` key was already declared by 179 scenarios but silently ignored by the runner — the "add support" work was really "honor an existing-but-dead key," making it fully backward-compatible (every declaration named the same default). (2) The new S20 scenario's FLAKY was NOT model nondeterminism — a raw-attempt capture showed `Error: Exceeded USD budget (0.2)`. The heavy `session-store-learning` full-policy path costs >$0.20 on sonnet; the FLAKY was a budget-ceiling collision the harness silently laundered.
- **Assumptions that held:** The neutral DP-consult rewrite would still pass if the skill prose genuinely carried the consult contract — it did (4/4 haiku, attempts:1). The `[ -f ]`-guarded fallback would preserve backward-compat — it did (S1/S2 unchanged).
- **Assumptions that were wrong:** My first verify-self hypothesis ("FLAKY = first-attempt token-emission model-noise") was asserted WITHOUT inspecting a failing attempt — exactly the anti-pattern the recalled memory `feedback_odd_shape_findings_probe_more` + the just-shipped WP5 heuristic warn against. The operator's vh.2 push ("reason about which layer") forced the real diagnosis. Lesson reinforced: when a finding's shape is surprising, capture the raw evidence before naming the cause.
- **Approach delta:** Plan had 2 phases + 5 Phase-1 leaves. Actual added a 6th Phase-1 leaf (P1.6, per-scenario `budget:` key) via an F12 verify-human back-loop — the operator ruled the durable root-cause fix over trimming the scenario args. Also surfaced a new backlog item (the (a) budget-exhaustion-observability half) not anticipated at plan time. Everything else matched the plan.

## Closure message
**Feature complete:** WP6 (per-scenario `claude_md` fixture + neutral DP-consult rewrite) has shipped (commit e2494f9). `tests/run-tests.sh` now honors per-scenario `fixtures.claude_md` and `budget:` keys; a new `S20-global-override-tracked` scenario + `check-structure.sh` [Phase 3f] property-test lock the behavior; the 4 DP-consult scenarios were rewritten to test the loaded SKILL.md consult contract rather than prompt obedience. Verify via `./tests/check-structure.sh` (411/0) and `./tests/run-tests.sh --group product` (DP-consult 4/4). **Requester = operator — closure notice for self-record.** This was the final WP of the backlog-paydown-2026-07-13 sweep.

**Disposition (autopilot):** all 3 MINOR auto-backlogged to `workflow/backlog-quality-findings.md` under `# wp6-per-scenario-claude-md-fixture-and-neutral-consult — 2026-07-14`; pointer added to `workflow/backlog.md`. NB: MINOR #1 and #3 are cheap+safe (add lockstep-comment; `grep -q`→`grep -qF`); MINOR #2's line-number claim should be verified against the committed file before applying (per the "review-finding suggested-actions are hypotheses" Context Rule) — natural candidates for the next `/util-backlog-paydown` sweep.
