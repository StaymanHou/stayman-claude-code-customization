# Changelog

## 2026-05-14

- **Feature shipped:** `debug-*` skill category introduced as a new namespace for agent-pulled sidebar techniques that workflow states (`feature-build`, `incident-investigate`, `task-act`) can invoke when standard debugging stalls; first member `debug-bisect-known-good` codifies the known-good-bisection technique with two conjunctive gates (known-good sibling present AND ≥3 failed straight-line attempts) enforced at SKILL entry, returns to the caller without consuming a workflow transition ID.
- **Task closed:** Default drive mode in `/session-start` flipped from Orchestrated (Mode 2) to Autopilot (Mode 3) — Enter / blank / "yes" now maps to Mode 3 in both `skills/session-start/SKILL.md` and `docs/product/transitions.md`; the stale 3-mode prompt example in transitions.md was refreshed to the live 4-mode menu in the same pass.
- **Backlog resolved:** SURFACE-2026-05-13-DEFAULT-DRIVE-MODE-AUTOPILOT — closed by the default-flip task above; no test scenarios needed updating since S10's substring check on "Orchestrated" still holds and S22 didn't reference the default.
- **Feature shipped:** Entry-skill product-context loading — 6 entry-point skills (`task-plan`, `feature-spec`, `feature-plan`, `feature-reproduce`, `incident-report`, `product-vision`) now consult `docs/product/*.md` per a load-discipline convention defined in `CLAUDE.snippet.md` (pointer-default for all, eager-read for spec+plan, conditional-read for task-plan+incident-report on trigger phrases, 300-line size guard, no `context.md` anywhere), with per-skill `## Step 0: Available product context` sections and 8 new `grep_check` assertions in `tests/check-structure.sh` guarding the contract.
- **Backlog resolved:** SURFACE-2026-05-11-ENTRYPOINT-SKILLS-LOAD-PRODUCT-CONTEXT — closed by the entry-skill product-context loading feature above; canonical mapping landed in `CLAUDE.snippet.md`, cross-level note in `docs/product/transitions.md`, per-skill Step 0 sections in all 6 entry-point SKILL.md files, regression-gated by 8 `grep_check` assertions in `tests/check-structure.sh`.
- **Backlog resolved:** SURFACE-2026-05-13-SETTINGS-FIXTURE-EFFORTLEVEL-DRIFT — closed as side-effect of the entry-skill product-context loading feature; root cause was an inadvertent drop of `effortLevel` from `~/.claude/settings.json` during effort-mode switching, fixed by re-adding `"effortLevel": "xhigh"` to live settings (the fixture asserts the user's actual default).

## 2026-05-13

- **Feature shipped:** Three-layer defense against the finalize-before-ship order-flip bug — `Unvisited:` field tightened to ordered/sequence-of-execution semantics, `agents/feature-workflow/AGENTS.md` pins the post-verify-codify ship→finalize order, `skills/feature-finalize/SKILL.md` gains a §0 precondition guard that refuses to run when ship has not happened, and `skills/feature-verify-codify/SKILL.md` F16 prose forbids enumerating downstream steps.
- **Backlog resolved:** SURFACE-2026-05-06-FINALIZE-BEFORE-SHIP-ORDER-FLIP — closed by the three-layer defense above; regression-gated by new scenario `F16-order-flip` in `tests/scenarios/feature.yaml` using the reproduction fixture from the bug's confirmed reproduction.

## 2026-05-12

- **Feature shipped:** Per-project `CHANGELOG.md` auto-populated by terminal-close skills — `feature-finalize`, `task-close`, `incident-resolve`, and `product-finalize` now append one-line entries on close, per the `## CHANGELOG.md convention` section of `CLAUDE.snippet.md`.
- **Backlog resolved:** SURFACE-2026-05-10-FINALIZE-RETROSPECT-LOST-IN-GIT-MV — closed by per-project-changelog feature; all four closing SKILLs now document the append-before-`git mv` operational sequence.
- **Feature shipped:** `/session-start` now surfaces the top-3 open backlog items as candidate work when no paused session, active WIP, in-progress product doc, or `{{args}}` is present — ranked by priority tier then SURFACE date descending, with a "more backlog" affordance and SURFACE-ID-anchored numbering to defend against sub-list reindexing bugs.
- **Backlog resolved:** SURFACE-2026-05-11-SESSION-START-SUGGEST-FROM-BACKLOG — closed by the session-start backlog-surfacing feature; step 1 of `skills/session-start/SKILL.md` now reads `workflow/backlog.md` when no other active work is found, and step 2 resolves backlog references back to the matching entry.

## 2026-05-11

- **Backlog resolved:** SURFACE-2026-05-11-ORCHESTRATED-PAUSES-BETWEEN-PER-PHASE-STEPS — fixed via incident workflow: added `### Emit Transition` sections to all 5 per-phase feature SKILLs so the orchestrator has a canonical `TRANSITION: <id>` signal instead of falling back to "Run /x" prose; added anti-example to `session-start/SKILL.md`; regression-gated by new scenario `S21`.

## 2026-05-10

- **Backlog resolved:** SURFACE-2026-05-08-INCIDENT-CODIFY-EQUIVALENT — implemented `incident-codify` skill between mitigate and resolve, with transitions I17–I20 and speed-aware paths (reuse-reproduce, write-from-scratch, defer); wired across incident-workflow AGENTS.md, transitions.md, three existing SKILLs, and new test scenarios.

## 2026-05-09

- **Backlog resolved:** SURFACE-2026-05-06-FEATURE-WORKFLOW-MISSING-REPRO-STEP — implemented new `feature-reproduce` and `incident-reproduce` skills with red-green discipline; feature workflow gained F31–F35, incident workflow gained I13–I16, session-start gained S18 routing for bug-shape language.

## 2026-05-08

- **Backlog resolved:** SURFACE-2026-05-08-SETTINGS-JSON-ALLOWLIST-CRUFT — deleted four token-hardcoded GET allowlist entries (getUpdates x3, getWebhookInfo); kept the generic POST pattern as fallback.

## 2026-05-06

- **Backlog resolved:** SURFACE-2026-05-06-S9-S11-S14-DUAL-IDENTITY — added `transition_id_any` support to `tests/lib/verify.sh`; S9/S11/S12/S13/S14 updated to use the union form, S9 now PASSes via S9|F19.
- **Backlog resolved:** SURFACE-2026-05-06-S10-S13-ROUTING-OVERRIDES-DRIVE-MODE — applied `transition_id_any: [S10, S3]` and `[S13, F8]` to the affected scenarios; residual haiku-noise SOFT_PASS shape remains.
- **Backlog resolved:** SURFACE-2026-05-05-D2 — added `not_contains_strict` opt-in to `tests/lib/verify.sh`; strict mode applied to S12 and S14, surfaced a real S12 prose-leak (spun out as a separate open SURFACE).
- **Backlog resolved:** SURFACE-2026-05-05-HIDDEN-FAIL-F4 — tagged scenario `model: sonnet`; PASSes via `tests/run-all.sh` sonnet pass.
- **Backlog resolved:** SURFACE-2026-05-05-HIDDEN-FAIL-S3 — added Valid transitions section to `session-start/SKILL.md` and tagged S3 `model: sonnet`; sonnet PASSes consistently.
- **Backlog resolved:** SURFACE-2026-05-05-HIDDEN-FAIL-S6 — added Valid transitions section to `session-resume/SKILL.md`; S6 PASSes on haiku.
- **Backlog resolved:** SURFACE-2026-05-05-F22-FLAKY-REGRESSED-TO-FAIL — tagged scenario `model: sonnet`; PASSes via `tests/run-all.sh` sonnet pass.
- **Backlog resolved:** SURFACE-2026-05-05-HIDDEN-FAIL-S10 — applied `transition_id_any: [S10, S3]` (see ROUTING-OVERRIDES-DRIVE-MODE).
- **Backlog resolved:** SURFACE-2026-05-05-HIDDEN-FAIL-S13 — applied `transition_id_any: [S13, F8]` (see ROUTING-OVERRIDES-DRIVE-MODE).
