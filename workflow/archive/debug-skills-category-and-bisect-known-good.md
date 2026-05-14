# Feature: `debug-*` skill category + first member `debug-bisect-known-good`

**Workflow:** feature
**State:** ship (complete)
**Ship commit:** c11f0b3 (pushed to origin/main 2026-05-14)
**Created:** 2026-05-13
**Entry:** spec (complex feature)
**Drive mode:** autopilot

## Problem Statement

The existing skill set covers **workflow states** (each skill is a node in a state machine — feature/incident/task/product/session). When the agent is mid-workflow and gets stuck on a hard debugging problem — straight-line "remove a suspect, retest" has failed several times — there is no codified technique to reach for. The agent either keeps thrashing or escalates to the human prematurely.

The 2026-05-13 learning (`.claude/learnings/2026-05-13-known-good-bisect.md`) captured one such technique that actually worked: when a bug reproduces on path A but not on a structurally similar path B in the same environment, clone B as a sibling runner and add A's distinguishing variables one at a time until the symptom flips. In a real run this isolated a silent attribute-lookup miss in ~12 minutes after ~2 hours of straight-line debugging had failed to converge.

This feature does two things at once:
1. **Introduces a new skill category** — `debug-*` — for agent-pulled, ad-hoc debugging techniques that are NOT workflow states. They are tools the orchestrator (or the user) reaches for when standard debugging stalls inside an existing workflow state, and they return control to the caller when done.
2. **Delivers the first member** — `debug-bisect-known-good` — codifying the bisection technique with clear trigger boundaries so the orchestrator only invokes it in fitting scenarios.

Getting the **category boundary** right matters more than the first skill itself; future siblings (`debug-rubber-duck`, `debug-binary-search-history`, `debug-minimal-repro`, etc.) will inherit the pattern.

## Resolved Open Questions (from spec)

| # | Question | Resolution | Rationale |
|---|----------|-----------|-----------|
| 1 | TRANSITION token namespace for debug skills | **Use `DEBUG-BISECT-*` prefix** (option a) | Descriptive; grep-able; namespace-separated from F/I/T/P/S workflow IDs. The orchestrator never reads these as state-machine signals; they exist for the test harness and human readability. |
| 2 | Test scenario file location | **New file `tests/scenarios/debug.yaml`** (option b) | Confirmed via reading `tests/run-tests.sh`: `*.yaml` is globbed from `tests/scenarios/`, group name is the filename stem. Adding a new file is zero-config — no runner edits needed. Matches the category structure cleanly. |
| 3 | Single shared category doc vs per-skill structure | **Required sections documented in CLAUDE.md** (option a) | The first skill is the de facto template; future contributors copy it. A separate `TEMPLATE.md` would be unused indirection at category-size-of-one. |
| 4 | Skill argument-hint shape | **Free-form description** (option a) | The procedure's first step (Gate Check) identifies and confirms the two runners regardless. Structured paths would also force the user to know paths upfront, which is hostile to ad-hoc invocation. |
| 5 | Sidebar WIP record | **In-conversation by default; soft suggestion for long runs** | The bisect technique completes in minutes (real run was 12). Mandating a WIP file adds cleanup burden. Keep it as a one-line suggestion in the skill: "for long bisects, consider notes in `workflow/wip/debug-<slug>.md`." |

## Work Tree

- [x] Phase 1: Skill body + gate logic (`debug-bisect-known-good/SKILL.md`)
  **Observable outcomes:**
  - CLI: `ls ~/.claude/skills/debug-bisect-known-good/SKILL.md` returns the file (after `./install.sh` runs)
  - CLI: `awk '/^---$/{c++} c==2{exit} {print}' skills/debug-bisect-known-good/SKILL.md | grep -E '^name: debug-bisect-known-good$'` exits 0 (frontmatter `name` matches dir)
  - CLI: `grep -c '^## When to use$' skills/debug-bisect-known-good/SKILL.md` returns ≥1 (required section present)
  - CLI: `grep -c '^## When NOT to use$' skills/debug-bisect-known-good/SKILL.md` returns ≥1
  - CLI: `grep -cE '^### [0-9]+\. Gate Check|^## Gate Check' skills/debug-bisect-known-good/SKILL.md` returns ≥1 (gate-check step exists; numbered-step convention matches the repo's other SKILL.md files)
  - CLI: `grep -E 'DEBUG-BISECT-(START|SKIP|COMPLETE|NO-CONVERGE)' skills/debug-bisect-known-good/SKILL.md` returns ≥4 distinct tokens
  - CLI: `./tests/check-structure.sh` exits 0 (no new failures introduced)
  - CLI: `./install.sh` exits 0 and `readlink ~/.claude/skills/debug-bisect-known-good` resolves to `<repo>/skills/debug-bisect-known-good`
  - [x] P1.1 Create `skills/debug-bisect-known-good/` directory with `SKILL.md`
  - [x] P1.2 Write frontmatter (`name`, `description`, `argument-hint: <short description of the broken-vs-working pair>`)
  - [x] P1.3 Write `## When to use` section listing both gates as conjunctive preconditions (known-good present AND ≥3 failed straight-line attempts)
  - [x] P1.4 Write `## When NOT to use` section (paths nearly identical, flaky bug, expensive iteration)
  - [x] P1.5 Write `## Procedure` with: §1 Gate Check (writes both gate confirmations explicitly; on fail emits `TRANSITION: DEBUG-BISECT-SKIP` + RETURN-TO and exits); §2 Backup broken runner; §3 Build B0 clone + sanity-verify B0 reproduces working behavior; §4 Enumerate differences; §5 Iterate one variable per step with per-step sub-procedure (sync env, restart process, trigger, observe, Y/N eye-check); §6 First reproduce = cause, stop; §7 No-converge escalation (wrap real broken class)
  - [x] P1.6 Write `## Pitfalls` section (observation-window-must-fire-on-every-path, wire-success-masks-symptom, restart-between-iterations, one-variable-per-step, cause-may-not-be-on-suspect-list)
  - [x] P1.7 Write `## Termination` section listing the 4 transition tokens + the `RETURN-TO: <caller-skill>` line convention
  - [x] P1.8 Ran `./install.sh` — symlink `~/.claude/skills/debug-bisect-known-good` lands and resolves to repo. Ran `./tests/check-structure.sh` — exits with 33 PASS / 1 FAIL, where the 1 FAIL is the pre-existing `effortLevel` drift logged as SURFACE-2026-05-13-SETTINGS-FIXTURE-EFFORTLEVEL-DRIFT, unrelated to this feature. Zero new failures introduced.
  - [x] verify-auto  <!-- all 8 observable outcomes PASS; check-structure 33/34 (1 pre-existing FAIL unrelated to this feature) -->
  - [x] verify-self  <!-- symlink round-trip bit-identical (sha match); frontmatter parseable; 6/6 required sections + 5/5 token kinds present in live copy; skill discoverable at ~/.claude/skills/debug-bisect-known-good/SKILL.md; no integration boundary in this phase -->
  - [x] verify-human  <!-- approved 2026-05-13 -->
  - [x] verify-codify  <!-- added [Phase 3b] to tests/check-structure.sh asserting `## When to use` + `## When NOT to use` present in any skills/debug-*/SKILL.md (catches gate-boundary removal regression). 35 PASS / 1 FAIL (pre-existing effortLevel drift, unrelated). Scenario count 131 unchanged. DEBUG-BISECT-* tokens deferred to Phase 3's debug.yaml scenarios (not duplicating). Frontmatter-name-vs-dir gap logged as SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT (project-wide concern, not Phase 1 scope). -->

- [x] Phase 2: Category documentation + downstream-contract callouts
  **Observable outcomes:**
  - CLI: `grep -nE '^### \x60debug-\*\x60 Skill Category' CLAUDE.md` returns ≥1 (new section exists; placed at H3 under the existing "Architecture" section, alongside "Cross-level mechanisms")
  - CLI: `grep -c 'Debug techniques (agent-pulled sidebars)' agents/feature-workflow/AGENTS.md agents/incident-workflow/AGENTS.md agents/task-workflow/AGENTS.md` returns 3 (one match per orchestrator)
  - CLI: `grep -c '/debug-bisect-known-good' skills/feature-build/SKILL.md skills/incident-investigate/SKILL.md skills/task-act/SKILL.md` returns 3 (one prose mention per caller skill)
  - CLI: `grep -c 'Sidebar skills' docs/product/transitions.md` returns ≥1 (cross-level mechanism note added)
  - CLI: `grep -c '^| F[0-9]\+ |' agents/feature-workflow/AGENTS.md` is unchanged from pre-edit (no new transition IDs added to feature transition table — assert as a delta check)
  - Browser: N/A (docs-only phase)
  - HTTP: N/A
  - [x] P2.1 Added `### \`debug-*\` Skill Category` section (H3 under Architecture) to `CLAUDE.md` — convention table, required SKILL.md sections, namespace rules
  - [x] P2.2 Added "Debug techniques (agent-pulled sidebars)" subsection to `agents/feature-workflow/AGENTS.md` — table lists `/debug-bisect-known-good`, caller state `feature-build`, trigger summary
  - [x] P2.3 Same subsection added to `agents/incident-workflow/AGENTS.md` — caller state `incident-investigate`
  - [x] P2.4 Same subsection added to `agents/task-workflow/AGENTS.md` — caller state `task-act`
  - [x] P2.5 Added §4b "Debug-technique Sidebar (optional)" prose to `skills/feature-build/SKILL.md` — no transition table change
  - [x] P2.6 Added §3b same prose to `skills/incident-investigate/SKILL.md` (initial placement was wrong; fixed 2026-05-13 via F9b back-loop — §3b now sits between §3 Investigate and §4 Update Report; sequence is 1, 2, 3, 3b, 4, 5, 6)
  - [x] P2.7 Added §3b same prose to `skills/task-act/SKILL.md`
  - [x] P2.8 Added "Sidebar skills (`debug-*` category)" subsection to `docs/product/transitions.md` under Cross-level mechanisms — full sidebar-vs-REDIRECT comparison table
  - [x] P2.9 Added 2026-05-13 entry to `docs/product/transitions.md` Change Log section
  - [x] verify-auto  <!-- 5/5 Phase 2 outcomes PASS initially; re-ran post-F9b fix on P2.6 — all checks PASS including section-ordering on incident-investigate (1, 2, 3, 3b, 4, 5, 6); check-structure unchanged 35/36 -->
  - [x] verify-self  <!-- consuming-surface re-verify PASSED post-F9b: symlinks bit-identical on all 6 edited files, frontmatter intact on 3 SKILLs + 3 AGENTS.md, section ordering coherent on all 3 caller SKILLs (incident-investigate now 1, 2, 3, 3b, 4, 5, 6), RETURN-TO self-references clean (1/1/1, no cross-contamination) -->
  - [x] verify-human  <!-- approved 2026-05-13 -->
  - [x] verify-codify  <!-- added [Phase 3c] to tests/check-structure.sh codifying the 3 discoverability surfaces: 3 caller-skill prose mentions, 3 AGENTS.md subsections, 1 transitions.md note. 7 new PASSes. No-new-F-IDs invariant deliberately NOT codified (brittle false-positive when workflow grows). check-structure now 42/43 PASS (1 pre-existing effortLevel FAIL, unrelated). -->

- [x] Phase 3: Test scenarios + fixtures (`tests/scenarios/debug.yaml`) + harness regex fix
  **Observable outcomes:**
  - CLI: `ls tests/scenarios/debug.yaml` returns the file
  - CLI: `./tests/run-tests.sh --group debug --dry-run` lists ≥3 scenarios
  - CLI: `./tests/run-tests.sh --group debug` (haiku) returns 3 PASS or SOFT_PASS (no FAIL); strict PASS preferred but SOFT_PASS acceptable if recon discipline confirms haiku-noise pattern
  - CLI: `./tests/run-tests.sh` (full sweep) shows no regression in other groups (pre/post diff: same PASS count, no new FAILures)
  - CLI: `grep -c '^scenarios:$\|^- id:' tests/scenarios/debug.yaml` returns ≥4 (header + ≥3 scenarios)
  - [x] P3.1 Created `tests/fixtures/wip/debug-bisect-gates-met.md` (Playwright window-invisibility, amazon vs ebay worker, 4 failed attempts)
  - [x] P3.2 Created `tests/fixtures/wip/debug-bisect-no-known-good.md` (acme-corp single-tenant bulk-export, no sibling path)
  - [x] P3.3 Created `tests/fixtures/wip/debug-bisect-insufficient-attempts.md` (premium-plan digest fail, sibling exists but only 1 attempt)
  - [x] P3.4 Created `tests/scenarios/debug.yaml` with 3 scenarios — runner globs the file zero-config; dropped `not_contains` on GATE-MET per CLAUDE.md entry-state-scenario guidance
  - [x] P3.5 Ran `./tests/run-tests.sh --group debug` on haiku — initially 3 SOFT_PASS due to harness regex bug (didn't handle hyphens or markdown bold). Fixed `tests/lib/verify.sh` regex inline (same-phase dependency, see Discoveries log). Final result: 3/3 strict PASS on haiku. No sonnet tagging needed.
  - [x] P3.6 Ran full haiku partition sweep (`--filter-model default`): 78 PASS / 42 SOFT / 3 FAIL / 8 FLAKY out of 131 scenarios. 3 FAILs (F3, S10, T8) triaged as pre-existing or pre-feature flaky — see `## Test Triage` block below. No regression caused by Phase 3 changes.
  - [x] verify-auto  <!-- 6/6 outcomes PASS; debug group 3/3 strict PASS on haiku (consistent across 2 runs); check-structure 42/43 (scenario count now 134, Phase 3b+3c checks all PASS, same pre-existing effortLevel FAIL) -->
  - [x] verify-self  <!-- regex property-test PASS 21/21 across full ID namespace (alphanumeric, b-suffix, compound, hyphenated debug-*, with markdown bold/italic, with arrow decoration); 3/3 negative cases correctly no-match; empirical full haiku sweep 78/42/3/8 with 3 FAILs triaged as pre-feature; regex change strictly additive -->
  - [x] verify-human  <!-- approved 2026-05-14 -->
  - [x] verify-codify  <!-- added [Phase 3d] to tests/check-structure.sh: re-derives the TRANSITION regex from verify.sh and runs 9 positive + 2 negative cases covering full ID namespace (alphanumeric, b-suffix, compound legacy, hyphenated debug-*, markdown bold). 12 new PASSes. Final check-structure: 54/55 PASS (1 pre-existing effortLevel FAIL). Skill behavior itself is codified by the 3 debug.yaml scenarios. -->

## Current Node
- **Path:** Feature > finalize (next)
- **Active scope:** Ship complete (commit c11f0b3 pushed to origin/main); awaiting `/feature-finalize`
- **Blocked:** none
- **Unvisited:** finalize
- **Open discoveries:** SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT (low), SURFACE-2026-05-13-DEFAULT-DRIVE-MODE-AUTOPILOT (high) — both logged to backlog

## Retrospect

- **What changed in our understanding:**
  - The harness's TRANSITION-line regex was load-bearing-but-untested infrastructure. It quietly worked for 131 scenarios because every existing TRANSITION ID happened to start with an alphanumeric character — the truncation behavior never manifested. Introducing the first hyphenated-token TRANSITION (`DEBUG-BISECT-*`) surfaced it immediately. This is a useful general lesson: any test-harness primitive that has only ever been exercised by one shape of input is implicitly fragile, even if it appears battle-tested by call-count.
  - Markdown-bold formatting (`**TRANSITION:**`) on the canonical signal line is more common than expected — haiku reaches for it spontaneously when summarizing structured output. Worth tolerating in the parser rather than fighting it in skill prose.

- **Assumptions that held:**
  - The `debug-*` category design (agent-pulled sidebar, returns to caller, no new transition IDs) cleanly fits the existing state machine without requiring any F/I/T-ID changes. The "same-state round-trip" framing under transitions.md "Cross-level mechanisms" reads coherently next to SURFACE/ESCALATE/REDIRECT.
  - The Phase 1 verify-codify decision to codify only `## When to use` / `## When NOT to use` (and defer `DEBUG-BISECT-*` token coverage to Phase 3 scenarios) turned out right — Phase 3's scenarios catch token regressions naturally, no duplicate structural check needed.
  - The spec's "skip frontmatter-name-vs-dir codification — project-wide concern, not this feature's scope" call held: the surface was logged to backlog with a clean action plan, didn't bloat this feature.

- **Assumptions that were wrong:**
  - Plan estimated 3 phases would land cleanly. Phase 2 needed an F9b back-loop (incident-investigate §3b placed between §4 and §5 instead of §3 and §4 — sequence sanity check caught it). One real defect caught in verify-self; scoped fix was a single Edit. The back-loop machinery worked as designed.
  - Did NOT anticipate the harness regex bug. The spec assumed the test harness was a stable primitive; Phase 3 discovered it wasn't. Handled inline (same-phase dependency) rather than as a back-loop or out-of-scope SURFACE, which was the right call given the fix was a one-line change unblocking the phase's own deliverable.

- **Approach delta:**
  - Spec → plan: 5 open questions, all resolved per recommendations. Zero re-spec needed.
  - Plan → build: Phase 2 added one back-loop iteration on P2.6 (section misplacement). Phase 3 added one inline scope expansion (verify.sh regex fix).
  - Phase 1 verify-codify codified gate-boundary sections (3b); Phase 2 verify-codify codified discoverability surfaces (3c); Phase 3 verify-codify codified regex correctness (3d). Final check-structure: 54 PASS / 1 pre-existing FAIL — went from 33 PASS at feature start to 54 PASS at ship (+21 new structural assertions across 3 verify-codify cycles).
  - All three phases were Mode 3 (autopilot) — total of 3 human-input pauses (one per phase at verify-human). No cross-phase back-loops needed.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
[SURFACED-2026-05-13] Phase 1 verify-codify — no project-wide check asserts that SKILL.md frontmatter `name:` matches its parent directory. Logged as SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT (priority: low; project-wide regression guard).

[SURFACED-2026-05-14] Phase 3 build — Test harness's TRANSITION-line regex in `tests/lib/verify.sh` (1) did NOT include `-` in the captured ID character class and (2) did NOT tolerate markdown bold-mark (`**TRANSITION:**`) between the colon and the ID. Fixed inline as a same-phase dependency (not surfaced as backlog) since the fix was load-bearing for Phase 3's own deliverable. Change: regex went from `[[:space:]]*\([A-Za-z0-9_]*\)` to `[*[:space:]]*\([A-Za-z0-9_-]*\)`. Smoke-tested against 5 input shapes (plain, with-arrow-parens, bold-with-arrow-parens, double-space) — all parse correctly. Existing scenario IDs are unaffected (workflow IDs are alphanumeric+`_`; the change is additive).

## Test Triage — full-sweep FAILs (Phase 3 P3.6)

Three FAILs in the post-Phase-3 haiku sweep (78/42/3/8 PASS/SOFT/FAIL/FLAKY out of 131). None caused by this feature:

### Test Triage — F3 (feature:spec → research when unknowns exist)
Classification: Flaky test
Confidence: high
Evidence: F3 PASS in prior full-sweep runs (run-2026-05-05-183932 — PASS strict; run-2026-05-13-144740 — PASS lenient). The single haiku attempt this sweep failed to emit any TRANSITION line. Same fixture, same args, same model — variability is in haiku's output discipline, not in the scenario or the harness.
Action: No action this phase. Already known to be one of the haiku-flaky candidates per SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG (which lists 6+ haiku-flaky scenarios including F-boundary, F14/F15, F16-triage-*, F13-prefiltered). F3 may merit inclusion in that recon pass — but that's the existing backlog item's job, not this feature's.

### Test Triage — S10 (session:start regression — stops after plan when user says 'drive it end-to-end')
Classification: Pre-existing test failure
Confidence: high
Evidence: S10 FAIL with identical "found F8, expected S10" shape in run-2026-05-05-183932 (prior full sweep). Phase 3 changes touched only debug.yaml scenarios + verify.sh regex; neither could affect S10's behavior.
Action: No action this phase. Pre-existing scenario design issue — should be picked up in a separate backlog item if not already.

### Test Triage — T8 (task:act surfaces to product:wbs on new work item)
Classification: Pre-existing flaky test
Confidence: high
Evidence: T8 was already FLAKY in run-2026-05-05-183932 (status FLAKY with similar SURFACE-vs-ESCALATE confusion). This sweep happened to land on a failing attempt rather than a passing one.
Action: No action this phase. Pre-existing flakiness; should be debug-* sidebar-applicable when investigated (known-good = SURFACE scenarios that PASS, broken = T8 SURFACE).

## Notes for build

**Phase boundaries are explicit.** Phase 1 = the skill itself, standalone, with passing structural checks. Phase 2 = surrounding docs/caller-prose so the skill is discoverable. Phase 3 = test coverage. Each phase has its own verify loop.

**Integration-boundary rule applies in Phase 2:** P2.5/P2.6/P2.7 edit existing skills (`feature-build`, `incident-investigate`, `task-act`). Per the rule documented in CLAUDE.md, the verify-self and verify-codify steps for Phase 2 must include a check against the consuming surface (the caller SKILL.md files) — which the observable outcomes above already do via grep assertions.

**No new state-machine transition IDs.** Sidebars return to the same state. The transition table for feature/incident/task workflows is unchanged. P2.8 is the only entry in `transitions.md` that mentions the category, and it lives under "Cross-level mechanisms" as a descriptive note — not as a numbered transition.

**Drive mode is autopilot (Mode 3).** Per `agents/feature-workflow/AGENTS.md` pause-policy: `feature-plan` PAUSES, then all build/verify-auto/verify-self steps AUTO-chain, verify-human PAUSES per phase, verify-codify and ship AUTO. Three verify-human pauses expected (one per phase) plus finalize AUTO in Mode 3.

TRANSITION: F7
