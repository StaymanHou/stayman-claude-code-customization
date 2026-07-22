# Feature: WP7c — Greenfield onboarding scaffold (runnable) + planted authentic tangent

**Workflow:** feature
**State:** COMPLETED 2026-07-22 (shipped 287ff86; finalized — archived)
**Created:** 2026-07-22
**Completed:** 2026-07-22
**Milestone:** 11 (M11 onboarding) · **WBS:** WP7c
**drive_mode:** autopilot

## Problem Statement

`tutorial-greenfield-workflow-tour` (WP7b) forward-declares a "tiny, shipped, runnable sample project" it drops the new user into, but the scaffold does not exist yet — the arm's Steps 5 (verify-self grounding) and 6 (SURFACE) both depend on it and currently reference a non-existent target. WP7c builds that scaffold under two hard constraints from `onboarding-flow-spec.md` §3-greenfield steps 5–6 + §8: (1) it must be **runnable with ≥1 observable outcome** so the staged verify-self grounding beat has something real to observe (agent runs it, reports PASS/FAIL); (2) it must contain a **planted, authentic-feeling tangent** so the staged SURFACE beat fires reliably without feeling manufactured. It must stay **minimal so it doesn't rot** (it rides path/skill/layout changes — cf. M7 moved every folder) and honor the **no-runtime repo convention** (no new deps — pure POSIX shell + markdown). Greenfield-only (brownfield is BYO real code — no scaffold). Then WP7b's greenfield arm must be **wired** to drop the user into a fresh copy of the scaffold and trigger the two staged beats against concrete, named targets.

## Design decisions (settled at plan time — 7c.1)

- **Delivery shape:** a **shipped fixture dir** (`tools/onboarding-scaffold/sample/` — the canonical, git-tracked, minimal content) **+ a tiny copy-into-a-fresh-dir scaffolder** (`tools/onboarding-scaffold/new-sample.sh`) that stamps a throwaway working copy per tour run. Rationale: the tour makes *real* edits + a SURFACE + a handoff/restore against the sample, so it must run against a **fresh throwaway copy** ("nothing real to lose" — spec §3), never the shipped source. Mirrors the `tools/migrate-doc-layout/` shape (script + README + test dir) and the test-harness copy-fixtures-into-temp pattern. Lives under `tools/` (not `tests/fixtures/` — it is user-facing tour content, not a test fixture; not `skills/` — it is data the skill consumes, not a skill).
- **Runnable content + observable outcome (constraint 1):** `sample/greet.sh` — a self-contained POSIX-shell "greeter" (no deps). **Primary observable:** `./greet.sh World` → exit 0, stdout **exactly** `Hello, World!`. This is the concrete outcome verify-self checks (agent runs it, diffs stdout, reports PASS/FAIL). A one-line README in the sample states the intended behavior so the observable is documented, not invented at verify time.
- **Planted authentic tangent (constraint 2):** `greet.sh` handles the happy path correctly but its **no-argument path** prints a subtly-wrong/ungrammatical fallback (`Hello, !` — the kind of small real bug an agent plausibly wants to chase), and the sample README carries a visible `TODO:` about it. That is the rabbit-hole: mid-task, the agent recognizes it, runs SURFACE to log it to the backlog, and continues without losing the plot — exactly the beat, and it is a *real* defect (authentic), not a fake breadcrumb.
- **Scaffolder discipline (mirrors `tools/migrate-doc-layout/`):** idempotent-safe (never overwrites a non-empty target without `--force`), `--dest <dir>` (default: a `mktemp -d` throwaway), prints the created path + the observable-outcome hint on success, POSIX/bash only. A short README with canonical invocations. Minimal test coverage under `tools/onboarding-scaffold/test/`.

## Work Tree

- [x] Phase 1: Build the runnable sample + scaffolder  <!-- status: complete -->
  **Observable outcomes:**
  - CLI (sample runnable — the verify-self grounding target): `tools/onboarding-scaffold/sample/greet.sh World` exits 0 and stdout is exactly `Hello, World!`
  - CLI (planted tangent is real + authentic): `tools/onboarding-scaffold/sample/greet.sh` (no arg) exits 0 and stdout contains the ungrammatical `Hello, !`, and `grep -q 'TODO' tools/onboarding-scaffold/sample/README.md` exits 0
  - CLI (scaffolder produces a fresh runnable copy): `D=$(mktemp -d); tools/onboarding-scaffold/new-sample.sh --dest "$D/s" >/dev/null && "$D/s/greet.sh" World` exits 0 with stdout exactly `Hello, World!`; the copy is independent of the source (editing the copy does not touch `tools/onboarding-scaffold/sample/`)
  - CLI (scaffolder refuses to clobber): `tools/onboarding-scaffold/new-sample.sh --dest <non-empty-existing-dir>` (no `--force`) exits non-zero and writes nothing
  - [x] P1.1 Create `tools/onboarding-scaffold/sample/` — `greet.sh` (executable, POSIX, correct happy path + planted no-arg tangent) + `README.md` (states the observable behavior + carries the `TODO:` about the no-arg case)  <!-- status: complete -->
  - [x] P1.2 Create `tools/onboarding-scaffold/new-sample.sh` — copy-into-fresh-dir scaffolder (`--dest`, default mktemp; no-clobber guard + `--force`; prints created path + observable hint; `chmod +x` preserved)  <!-- status: complete -->
  - [x] P1.3 Write `tools/onboarding-scaffold/README.md` — what the scaffold is, canonical invocations, the observable outcome + the planted-tangent's role, the "keep it minimal so it doesn't rot" note  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete — bash -n parse OK on both scripts; +x bits present; happy-path run smoke prints Hello, World! -->
  - [x] verify-self  <!-- status: complete — subagent verified all 4 CLI outcomes PASS (exact Hello, World! byte-check; planted tangent Hello,!+README TODO; scaffolder fresh independent copy; no-clobber refusal writes nothing). No integration boundary (isolated new artifacts). No BLOCKING/COSMETIC. -->
  - [x] verify-human  <!-- status: complete — F11 AUTO-SKIP (drive_mode=autopilot; verify-self all-PASS; no integration boundary; no outcome cites a consuming surface). Isolated new artifacts only. Affirmation printed for read-time veto. -->
  - [x] verify-codify  <!-- status: complete — wrote tools/onboarding-scaffold/test/run-tests.sh (7-assertion CLI smoke, no deps): all 4 observables codified. 7/7 pass. Full check-structure.sh 472/0 no regression. No integration boundary (isolated artifacts). No test failures → no triage. -->

- [x] Phase 2: Wire WP7b's greenfield arm to the scaffold  <!-- status: complete -->
  **Observable outcomes:**
  - CLI (arm names the concrete scaffold + drop-in): `grep -q 'tools/onboarding-scaffold' skills/tutorial-greenfield-workflow-tour/SKILL.md` exits 0, and the "The environment" section no longer calls the scaffold a "forward touchpoint / wire the drop-in when that scaffold lands" (grep for that stale forward-declaration language returns nothing)
  - CLI (Step 5 grounding cites the real observable): the arm's Step 5 references running `greet.sh` and checking stdout `Hello, World!` — `grep -q 'greet.sh' skills/tutorial-greenfield-workflow-tour/SKILL.md` exits 0 and the verify-self beat names a concrete PASS/FAIL check against it
  - CLI (Step 6 SURFACE cites the real planted tangent): the arm's Step 6 references the no-arg `Hello, !` / `TODO` tangent as the thing SURFACE catches — grep confirms the concrete tangent is named, not left abstract
  - CLI (path-qualification mandate holds): `tests/check-structure.sh` Phase 12 (`no bare .claude/`) still passes for the edited SKILL.md — no bare `.claude/` introduced
  - [x] P2.1 Rewrite the arm's "The environment — a tiny runnable sample (from WP7c)" section: replace the forward-declaration with the concrete drop-in (run `tools/onboarding-scaffold/new-sample.sh` to get a fresh copy; cite the observable + the planted tangent)  <!-- status: complete -->
  - [x] P2.2 Make Step 5 (grounding/verify-self) cite the concrete observable (`greet.sh World` → `Hello, World!`) as the PASS/FAIL check  <!-- status: complete -->
  - [x] P2.3 Make Step 6 (SURFACE) cite the concrete planted tangent (no-arg `Hello, !` + the README `TODO`) as the rabbit-hole caught  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete — arm SKILL.md: YAML valid (name matches dir), all section markers present (## Category / ## The environment / ## The walkthrough / ## Transitions), no bare .claude/, code fences balanced. -->
  - [x] verify-self  <!-- status: complete — subagent verified all 4 outcomes PASS: concrete scaffold path named + stale WP7c forward-decl gone (WP7d forward-decls correctly preserved); Step 5 cites greet.sh World→Hello, World! as the verify-self observable; Step 6 names the no-arg Hello,! + README TODO tangent SURFACE catches; no bare .claude/. Integration boundary (edits an existing SKILL.md the dispatcher invokes) — satisfied: all outcomes cite that consuming surface by name. No BLOCKING/COSMETIC. -->
  - [x] verify-human  <!-- status: complete — operator DEFERRED the manual copy read-through (2026-07-22): approved forward-progress on the verify-self evidence, with a hands-on run of /tutorial-getting-started as the real acceptance test to follow. Turn-level "proceed now, verify later" (confirmed via AskUserQuestion) — NOT a session handoff. Leaves below marked DEFERRED (not agent-walked). Feedback returns as a follow-up task/SURFACE, not a back-loop. -->
    - [x] P2.verify-human.1 Read the wired arm SKILL.md end-to-end — does the greenfield tour still read as one coherent narrated real run?  <!-- status: DEFERRED-to-operator-hands-on-run -->
    - [x] P2.verify-human.2 Environment section: is the "run new-sample.sh → drop into a fresh copy" instruction clear + honest?  <!-- status: DEFERRED-to-operator-hands-on-run -->
    - [x] P2.verify-human.3 Step 5 grounding: does citing greet.sh World→Hello, World! land the "it checks reality" beat?  <!-- status: DEFERRED-to-operator-hands-on-run -->
    - [x] P2.verify-human.4 Step 6 SURFACE: does the no-arg Hello,! tangent read as an authentic rabbit-hole (not a fake breadcrumb)?  <!-- status: DEFERRED-to-operator-hands-on-run -->
  - [x] verify-codify  <!-- status: complete — added §5 wiring-contract assertions (3) to tools/onboarding-scaffold/test/run-tests.sh pinning arm↔scaffold linkage (scaffold path + both observables). Smoke 10/10 pass. Full check-structure.sh 472/0 no regression. Integration boundary satisfied (consuming-surface = arm SKILL.md referencing the scaffold, now asserted). Tour behavioral scenarios + structural pins deliberately deferred to WP7e per WBS. No test failures → no triage. -->

## Current Node
- **Path:** Feature > review-quality (complete) > finalize
- **Active scope:** none — shipped 287ff86; review-quality done (0C/1MAJ/2MIN, all auto-backlogged, Mode-3 F39); ready for /feature-finalize
- **Blocked:** none
- **Unvisited:** none (both phases complete; finalize next)
- **Open discoveries:** SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED (operator hands-on acceptance — non-blocking follow-up) + 3 code-quality findings auto-backlogged (1 MAJOR --help bug + 2 MINOR)

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
[SURFACED-2026-07-22] Phase 2 verify-human — Operator DEFERRED the manual copy read-through; will run /tutorial-getting-started hands-on once usable and give feedback then (the real acceptance test). Logged to backlog as SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED. Feedback returns as a follow-up task/SURFACE, not a back-loop on this shipped gate.

## Code-Quality Review — wp7c-greenfield-onboarding-scaffold

*(feature-review-quality, ship 287ff86, 2026-07-22 — drive_mode=autopilot. 0 CRITICAL / 1 MAJOR / 2 MINOR. Per Mode-3 policy: MAJOR auto-backlogged with prominent chat surface, MINORs auto-backlogged; F39 → finalize. Operator read-time veto: mark a finding `[DISMISSED]` here before finalize archives this file.)*

### Strengths
- Two load-bearing sample properties (runnable observable + planted authentic tangent) documented consistently across sample header comments, `sample/README.md`, and the wired arm SKILL.md — same exact `Hello, World!` / `Hello, !` strings; smoke §5 pins the arm↔scaffold linkage so drift is caught mechanically.
- `new-sample.sh` disciplined: `set -euo pipefail`, genuine no-clobber guard (verifies non-empty before refusing), `--force` escape hatch, `cp -R "$SRC"/.` preserves +x, source-missing preflight; mirrors the established `tools/migrate-doc-layout/` shape.
- Smoke test asserts behaviors honestly (independence check actually mutates the copy + greps the source; no-clobber check verifies "wrote nothing", not just non-zero exit).
- Delivery-shape rationale (`tools/` not `tests/fixtures/` — user-facing tour content; not `skills/` — data a skill consumes) captured in WIP + tool README.
- Deferred-acceptance handling clean: verify-human deferral logged as a well-formed SURFACE with "returns as follow-up, NOT a back-loop" disposition.

### Issues
**CRITICAL**
- (none)

**MAJOR**
- [`tools/onboarding-scaffold/new-sample.sh` `usage()` `sed -n '2,20p'`] `--help` output leaks script code. The header comment block ends at `# POSIX-ish bash, no dependencies.` (line 15) but `sed -n '2,20p'` reads through line 20, so `--help` prints a trailing blank line, `set -euo pipefail`, and the `SCRIPT_DIR=`/`SRC=` assignments verbatim as if they were help text (reproduced). Real defect on a user-facing tool the tour surfaces to a brand-new skeptical user; hard-coded line-range is fragile. Fix: delimiter-anchored extraction (print the contiguous `#`-comment block after the shebang, stop at first non-comment line), not a magic `20`. → auto-backlogged (Mode 3).

**MINOR**
- [`tools/onboarding-scaffold/sample/greet.sh:13-15`] The `TODO:` comment restates WHAT (the no-arg `Hello, !`) which the behavior already shows; but it's arguably load-bearing tour scaffolding (self-documents the planted tangent for the agent driving Step 6). Soft flag — the WHY ("Left as-is on purpose... Don't fix it inline mid-task") is the useful half and should stay. → auto-backlogged (Mode 3).
- [`tools/onboarding-scaffold/new-sample.sh` mktemp default] `mktemp -d "${TMPDIR:-/tmp}/onboarding-sample.XXXXXX"` produces a double-slash path on systems where `$TMPDIR` ends in `/` (macOS default), which propagates into the printed "Created fresh sample at:"/"Try it: cd ..." hints the user copies. Cosmetic; path still resolves. Fix: `${TMPDIR%/}` trim. → auto-backlogged (Mode 3).

### Assessment
Well-built, appropriately-scoped feature that does exactly what its plan said and stops cleanly at the WP7c boundary (WP7d/WP7e forward-declarations preserved, not pulled forward); no-runtime convention honored. Strong discipline: scaffolder mirrors an existing primitive, smoke test asserts behaviors not incantations, tripartite documentation keeps arm+scaffold from drifting. Accrues essentially no debt beyond the one `--help` extraction bug, which is contained to a diagnostic path but touches the exact user-facing surface this WP exists to polish — worth resolving before the tour goes live.

### If you disagree
Dismiss any finding by editing this section in the WIP and marking the line `[DISMISSED]` before `feature-finalize` archives the WIP.

## Retrospect
- **What changed in our understanding:** The delivery-shape question ("fixture dir vs. scaffolder") turned out to be a false either/or — the right answer was **both**: a shipped canonical fixture + a per-run copier. The tour's "drop into a fresh copy, nothing real to lose" requirement forces the copier; the "shipped, reviewable, minimal" requirement forces the fixture. Neither alone satisfies both.
- **Assumptions that held:** No-runtime (POSIX shell + markdown) was sufficient for a runnable observable AND an authentic tangent — no need for a real language/runtime. The `tools/migrate-doc-layout/` shape (script + README + test/) transferred cleanly. verify-self on a CLI observable worked exactly like the web-app case (the subagent spawn is about parent-context cleanliness, not Playwright).
- **Assumptions that were wrong:** The plan under-specified the scaffolder's `--help`; the review caught a real `sed` line-range bug (`--help` leaks code) that the observable-outcomes didn't exercise — a reminder that "runnable + observable" doesn't cover every user-facing path (the diagnostic path escaped the plan's outcomes).
- **Approach delta:** Matched the plan closely. One deliberate deviation: verify-human was **deferred** (not walked) at the operator's request — the operator will do the real acceptance test by running the tour hands-on; recorded honestly as DEFERRED + a tracked follow-up SURFACE, not marked as approved copy. Also added a §5 wiring-contract assertion to the smoke test at codify (beyond the plan's 4 observables) to guard arm↔scaffold drift without pulling WP7e pins forward.

## Notes
- **No-runtime convention:** POSIX shell + markdown only. No new deps — this is what keeps the scaffold from rotting and honors §8.
- **Codify anchor (WP7e boundary):** WP7c's own verify-codify covers the *scaffold's runnability + scaffolder behavior* (CLI observables above). The *tour-behavior* scenarios + the `tutorial-`-prefix structural pin are **WP7e's** job (deferred by M11 design). Do NOT pull WP7e pins forward here.
- **Path-qualification mandate:** any `.claude/` reference added to the arm SKILL.md in Phase 2 must be explicitly `~/.claude/` or `<proj-dir>/.claude/` (Phase 12 pin). The scaffold's own paths are `tools/`-relative (no `.claude/` involved).
