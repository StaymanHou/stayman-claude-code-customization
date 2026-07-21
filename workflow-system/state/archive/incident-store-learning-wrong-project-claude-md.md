# Incident: session-store-learning proposed wrong project-scope CLAUDE.md location

**Workflow:** incident
**State:** resolve
**Status:** Resolved
**Created:** 2026-06-30 19:20
**Severity:** P2
**Status:** Triaged

## Summary

While using this workflow system in a *different* project (G-NIE, `/Users/stayman/Work/Kenosis/google-newsroom-intelligence-engine`), `session-store-learning` correctly classified a code-contract learning as **PROJECT scope** but proposed writing it to the **wrong project-scope file**:

- **Proposed:** `<proj-dir>/.claude/CLAUDE.md` (the project-local *agent-rules / gotchas* file)
- **Correct:** `<proj-dir>/CLAUDE.md` (the project-**root** CLAUDE.md, which holds the project's `## Development Conventions` gotcha list)

The operator had to manually correct it ("save to `./CLAUDE.md` not `.claude/CLAUDE.md`"). The skill should have proposed the project-root CLAUDE.md for a code-contract/convention learning — or at minimum disambiguated between the two project-scope CLAUDE.md files (root vs `.claude/`) instead of silently picking `.claude/`.

This is a bug in `skills/session-store-learning/SKILL.md` in THIS repo (the source repo for the workflow system). Note this surfaced *across the boundary the skill itself warns about* — the path-qualification mandate (`~/.claude/` vs `<proj-dir>/.claude/`) covers home-vs-project, but this is a third axis the mandate does NOT disambiguate: **project-root `CLAUDE.md` vs project-local `.claude/CLAUDE.md`**, both of which are "project scope."

## Initial Observations

- The learning *type* was a code-contract convention (a two-axis-column invariant). That kind of content lives in the project-root `CLAUDE.md`'s `## Development Conventions` / gotcha sections in G-NIE — not in `<proj-dir>/.claude/CLAUDE.md`.
- Both files are legitimately "project scope," so the existing scope classifier (PROJECT vs GLOBAL) is not enough — there's an *unhandled second decision* (which project file) that the skill apparently resolves to `.claude/CLAUDE.md` by default or by faulty inference.
- The path-qualification mandate in this repo's CLAUDE.md disambiguates `~/.claude/` from `<proj-dir>/.claude/` but is silent on `<proj-dir>/CLAUDE.md` vs `<proj-dir>/.claude/CLAUDE.md`.
- G-NIE's own root CLAUDE.md (line 167) *routes* certain agent-gotchas to `.claude/CLAUDE.md` and keeps code-contract conventions in the root — so the correct destination is content-dependent, not a fixed file.

## Hypotheses

- **H1 (likely):** `session-store-learning`'s project-scope branch has a hard-coded or default-leaning target of `<proj-dir>/.claude/CLAUDE.md` (or `<proj-dir>/.claude/`) and never disambiguates against the project-**root** `CLAUDE.md`. (unverified — confirm by reading the SKILL.md)
- **H2:** The skill conflates "project-local agent config" (`.claude/`) with "project conventions doc" (root `CLAUDE.md`) because both are called "CLAUDE.md." (unverified)
- **H3:** The skill DOES describe a root-CLAUDE.md path but the prose is ambiguous enough that the model inferred `.claude/` at runtime — same failure class as the historical bare-`.claude/` non-determinism. (unverified)

## Triage Assessment (2026-06-30)

- **Severity: P2.** Wrong *proposal* (not a silent destructive write — skill proposes before writing), workaround exists (operator corrects manually). But affects any project with BOTH a root `CLAUDE.md` and a `.claude/CLAUDE.md` (the common mature-project case), and an inattentive accept scatters code-contract conventions into the wrong file where future sessions won't reliably find them.
- **User-facing impact:** operator must catch + correct each time; degrades the "store-learning just works" property.
- **Workaround:** manual location correction (as the operator did this session).
- **Not a duplicate** of any open incident.
- **Next step: I13 (reproduce first).** This is a skill prompt — reproducible locally via the test harness (`tests/run-tests.sh` drives the skill in a fresh subprocess against fixtures). A scenario asserting the correct project-scope destination is the natural regression anchor + mitigation gate. Defaulting to I3 was also valid, but a deterministic local recipe exists, so reproduce-first applies.

## Reproduction Attempt
**Surface chosen:** failing test (harness scenario) + source inspection
**Outcome:** could-not-reproduce-locally-but-source-inspection-confirms (I15-shaped)
**Artifact:** `tests/scenarios/session.yaml::S25-project-context-rule-root-claude-md` — asserts a project-scope code-contract Context Rule is proposed for the project-ROOT CLAUDE.md (`not_contains_strict: [".claude/CLAUDE.md"]`).
**Determinism:** once-observed live (this session, Opus, in the G-NIE project). The harness scenario PASSed on **sonnet** (`run-2026-06-30-193945.json`, 7s) — i.e. sonnet did NOT take the bad path for this input. The defect is therefore **model-and-context-dependent**, not deterministic-every-run.

**Root cause confirmed by source inspection — `skills/session-store-learning/SKILL.md` has contradictory prose:**
- **Line 33 (storage-type table, Context Rule row):** `Project: CLAUDE.md (root)` — CORRECT (root CLAUDE.md).
- **Line 26 (Scope bullet):** "store in `<proj-dir>/.claude/` (project root) as before" — WRONG/SELF-CONTRADICTORY: names the `.claude/` subdir but calls it "(project root)". Those are two different files.
- **Line 45 (Propose Storage example):** lists `<proj-dir>/.claude/CLAUDE.md` as the project-scope example for a Context Rule — WRONG (points at the agent-config file, not root).
- The table is right; the surrounding prose examples push toward `.claude/CLAUDE.md`. A model that follows the nearest concrete example (line 45) over the table (line 33) lands wrong. Opus did this session; sonnet didn't on the test input. Classic ambiguous-prose flake — exactly the failure class this repo treats as a real defect (cf. the path-qualification mandate's history).

**Why the existing `S20-amend-head` scenario missed it:** it feeds a project-scope Context Rule but only asserts the amend/`git add`/HEAD behavior — it never asserts WHICH CLAUDE.md, so the wrong-file path passed silently.

**Notes for investigate/mitigate:**
- The fix is prose-correction in SKILL.md lines 26, 33, 45 so all three agree: project-scope Context Rule → project-ROOT `<proj-dir>/CLAUDE.md`; `<proj-dir>/.claude/` is for memory/skills (and, per a project's own root-CLAUDE.md routing, agent-gotchas) — NOT the default for a Context Rule.
- Consider a one-line disambiguation: root `CLAUDE.md` = project conventions/Context Rules; `<proj-dir>/.claude/CLAUDE.md` = project-local agent-config (only if the project uses one).
- Honor the path-qualification mandate (`tests/check-structure.sh` Phase 12): every `.claude/` reference stays explicitly qualified.

## Investigation (2026-06-30) — forensic, from the G-NIE session log

Source: `~/.claude/projects/-Users-stayman-Work-Kenosis-google-newsroom-intelligence-engine/b35148ce-...jsonl` (the 19:20 session). Two compounding failure mechanisms:

### Mechanism 1 — contradictory SKILL.md prose (static)
`skills/session-store-learning/SKILL.md` disagrees with itself on the project-scope Context-Rule destination:
- **Line 33 (storage-type table):** `Project: CLAUDE.md (root)` — CORRECT.
- **Line 26 (Scope bullet):** "store in `<proj-dir>/.claude/` (project root) as before" — WRONG + self-contradictory (names `.claude/` but calls it "project root").
- **Line 45 (Propose Storage example):** `<proj-dir>/.claude/CLAUDE.md` as the project-scope example — WRONG.
The model followed the nearest concrete prose example over the table.

### Mechanism 2 — propose-without-reading (DEEPER; only visible in the log)
The skill emitted the full location proposal **and `TRANSITION: S20` without reading any file first.** Verbatim reasoning it gave (unverified inference):
> "the project-local `.claude/CLAUDE.md` already collects exactly this kind of 'agent gotcha' (e.g. the JSONB None→null rule). It belongs there…"

- It **never opened** `<proj-dir>/.claude/CLAUDE.md` to confirm it exists or holds gotchas.
- It **never read** the project-root `CLAUDE.md`, which already carries the matching convention ("Query-type is the first-class axis") under `## Development Conventions` — the obvious correct neighbor.
- First real file access happened only AFTER the user correction (grep at L646; Edit rejected at L654 with `File has not been read yet`; forced Read at L656). The proposal was pure imagination.

### Classification was correct; only the destination resolution was wrong
- Skill said: **Scope: PROJECT** ✓, **Type: Context Rule** ✓.
- It then resolved "Context Rule → root CLAUDE.md" to the *project-local* `.claude/CLAUDE.md`. Both mechanisms pushed the same wrong way.

### User correction (verbatim)
> `save to ./CLAUDE.md not .claude/CLAUDE.md`

Assistant's post-correction acknowledgment (L645) states the right model: the two-axis contract is "a first-class development convention (it belongs alongside 'Query-type is the first-class axis' in the root Development Conventions), not just an agent gotcha."

### Why existing coverage missed it
`S20-amend-head` feeds a project-scope Context Rule but asserts only the amend/HEAD behavior — never WHICH CLAUDE.md. The wrong-file path passed silently.

### Mitigation implication
Fixing only Mechanism 1 (prose) leaves Mechanism 2 (propose-from-imagination) intact — the skill would still route from an unverified claim. **Robust mitigation addresses both:**
1. Correct the contradictory prose (lines 26, 33, 45) so all agree: project-scope Context Rule → project-ROOT `<proj-dir>/CLAUDE.md`. Add a one-line disambiguation (root `CLAUDE.md` = conventions/Context Rules; `<proj-dir>/.claude/CLAUDE.md` = optional project-local agent-config — not the Context-Rule default).
2. Add a procedure step: **before proposing a project-scope location, READ the candidate destination file(s)** (root `CLAUDE.md`; `.claude/CLAUDE.md` if present) so the proposal is grounded in what exists, not inferred. No claim like "X already collects this kind of thing" without having opened X.
3. Keep `S25` as the fixed-state regression pin; honor the path-qualification mandate (check-structure Phase 12).

## Mitigation (2026-06-30)

**Fix (addresses both mechanisms), all in `skills/session-store-learning/SKILL.md`:**
1. **Mechanism 1 (contradictory prose) — corrected 4 sites** so all agree "project-scope Context Rule → project-ROOT `<proj-dir>/CLAUDE.md`":
   - frontmatter `description` (was "project-scope writes to `<proj-dir>/.claude/`")
   - `## Context` boundary paragraph
   - `### 2` Scope bullet (was the self-contradictory "`<proj-dir>/.claude/` (project root)") — now spells out the two distinct project-scope CLAUDE.md files and that they are NOT interchangeable
   - `### 2` storage-type table Context Rule row (made "root" explicit + "NOT `<proj-dir>/.claude/CLAUDE.md`")
   - `### 3` Propose-Storage location bullet (was the wrong `<proj-dir>/.claude/CLAUDE.md` example)
2. **Mechanism 2 (propose-without-reading) — new procedure gate** at the top of `### 3`: before naming a project-scope location, READ the root `<proj-dir>/CLAUDE.md` and check whether `<proj-dir>/.claude/CLAUDE.md` exists; a "file X already collects this kind of rule" claim is only allowed after opening X. "Never route a learning to a file you have not read."

**Verification:**
- `./tests/check-structure.sh`: **334 PASS / 1 FAIL**. The 1 FAIL is `settings fixture in sync` (`disableClaudeAiConnectors` live-vs-fixture drift) — **pre-existing environmental drift, unrelated** (my diff touches only `SKILL.md` + `session.yaml`; confirmed via `git diff --name-only`). Path-qualification Phase 12 (the relevant guard) PASSES. Surfaced separately below.
- Scenarios on sonnet (fresh subprocess):
  - **S25** (new regression pin) — was GREEN-on-sonnet pre-fix (bug is model/context-dependent). After the fix, the initial `not_contains_strict: .claude/CLAUDE.md` assertion FLIPPED to FAIL — because the corrected prose now legitimately *mentions* `.claude/CLAUDE.md` to warn against it. Per `docs/lessons/test-scenario-strict-mode.md`, strict not_contains is only for failure-PROXY phrases; `.claude/CLAUDE.md` became informational. **Reworked S25 to a POSITIVE assertion** (`contains_required_any: [root CLAUDE.md, project root, ...]`, deliberately excluding `/CLAUDE.md`/`./CLAUDE.md` which are substrings of `.claude/CLAUDE.md`). Re-run: **PASS** (`run-2026-06-30-200803.json`).
  - Regression: **S19, S20-amend-head, S20-global-canonical-path all PASS** (`run-2026-06-30-200049.json`) — the prose edits did not disturb the global-draft / amend-into-HEAD paths.

**Reversibility:** prose-only skill edit + one scenario. `git checkout skills/session-store-learning/SKILL.md tests/scenarios/session.yaml` fully reverts.

**Monitoring:** started 20:08. Nature of fix (prose + procedure gate in a skill prompt, covered by a green regression scenario) → short monitor; no runtime service to watch.

## Discoveries
- The `check-structure.sh` settings-fixture drift (`disableClaudeAiConnectors`) hit during mitigation verification is ALREADY logged as `SURFACE-2026-06-30-SETTINGS-FIXTURE-DISABLECLAUDEAICONNECTORS-DRIFT` in `workflow/backlog.md` (from today's util-backlog-paydown sweep). Not re-logged — no new SURFACE created. Confirms it is pre-existing and independent of this incident.

## Codify

- **Path:** B (new coverage written) — the reproduce artifact `S25` was *added during reproduce* and *reworked during mitigate*, so it counts as new coverage, not a pre-existing Path-A artifact. (Note the non-classic shape: the bug is model/context-dependent, so `S25` was green-on-sonnet even pre-fix; its regression value is **lock-in** against a *deterministic* reintroduction — e.g. reverting the storage-type table to `.claude/`.)
- **Test:** `tests/scenarios/session.yaml::S25-project-context-rule-root-claude-md` — asserts a project-scope code-contract Context Rule is PROPOSED for the project-ROOT CLAUDE.md (`contains_required_any: [root CLAUDE.md, project root, ...]`, `transition_id: S20`). Tagged `model: sonnet` (proven haiku-flaky + sonnet-clean, per the recon discipline).
- **Integration boundary:** the "consuming surface" of a skill-prompt fix is the skill's own behavioral output under the harness — exercised by name via `S25`. No code endpoint/UI/CLI involved. Regression siblings S19 / S20-amend-head / S20-global-canonical-path also exercise the store-learning surface and all PASS (confirm no collateral on the global/amend paths).
- **Full suite result:** passed — session group `run-2026-06-30-201504.json`: **0 FAIL** (11 PASS, 10 SOFT_PASS, 5 FLAKY-passed-on-retry; the SOFT/FLAKY are pre-existing orchestrator-chaining model-noise unrelated to this change). check-structure 334/1 (the 1 = unrelated settings-fixture drift). No new structure pins needed — behavioral fix, covered by S25.
- **No mitigation-regression / root-cause-misdiagnosis:** the mitigated skill behaves correctly (S25 PASS on sonnet); no test failed asserting the bug persists.

## Timeline
- 19:20 — Incident reported
- 19:20 — Triaged P2; route to reproduce (I13)
- 19:40 — Repro scenario S25 added; PASSed on sonnet (no live failure on that model). Root cause confirmed by SKILL.md source inspection. I15 → investigate.
- 19:45 — Investigation via G-NIE session log: TWO mechanisms — (1) contradictory prose, (2) propose-without-reading (skill emitted S20 + proposal having opened zero files; justified location with an unverified "`.claude/CLAUDE.md` already collects gotchas" claim). Mitigation must address both.
- 20:08 — Mitigation applied: 4 prose corrections + new read-before-propose gate in SKILL.md. S25 reworked to positive assertion, PASS. Regressions S19/S20-amend/S20-global PASS. check-structure 334/1 (1 = unrelated settings drift, surfaced). Status → Monitoring.
- 20:15 — Codify (Path B): full session group 0 FAIL; S25 tagged model:sonnet (proven haiku-flaky/sonnet-clean). Coverage in place. → resolve.
- 20:18 — Resolved. Complete fix (both mechanisms), not a partial mitigation — no I11/I12 follow-up SURFACE. Archived; CHANGELOG appended; committed locally (no push).
