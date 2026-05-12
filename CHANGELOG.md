# Changelog

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
