# Feature: WP7i — Richer greenfield sample skeleton + upfront project framing

**Workflow:** feature
**State:** ship (complete)
**Created:** 2026-07-22
**Milestone:** 11 (WP7 onboarding) · **WBS:** WP7i
**drive_mode:** autopilot

## Problem Statement

The shipped greenfield onboarding scaffold (`tools/onboarding-scaffold/sample/` — one `greet.sh` + README, a hello-world) is **too shallow to demonstrate the workflow's value** (operator, live tour walkthrough 2026-07-22). A one-file greeter gives planning, verify-self grounding, and the SURFACE beat almost nothing real to bite on — the tour's staged ahas (§3-greenfield steps 5–6) land weakly. **Ratified ruling (WBS 2026-07-22):** redesign the sample **now** into a richer pre-generated project skeleton with enough real surface (a couple of modules, a runnable observable, a planting-worthy authentic tangent) that planning / verify-self / SURFACE land meaningfully — **keeping** WP7c's copy-per-run stamper mechanism (`new-sample.sh`), which is sound and matches the operator's "fixed pre-generated skeleton the tutorial copies" mental model. Plus: (a) explain the vision/project info **upfront** in the greenfield arm output before G1 ("here's what this sample project is / what we're building"); (b) re-cite the new real observable + real tangent in the greenfield arm's Step 5 (grounding) and Step 6 (SURFACE). Constraints (spec §8): **no-runtime, no-deps** (POSIX shell + markdown only, so it doesn't rot — it rides path/skill/layout changes), runnable with ≥1 observable outcome, and an authentic (not fake-breadcrumb) planted tangent.

**Operator-chosen sample project (AskUserQuestion, 2026-07-22):** a **CLI todo/list manager** — a small shell `todo` CLI with add/list/done subcommands over a plain-text store. Observable: `./todo add "buy milk" && ./todo list` shows a numbered, unchecked item; planted tangent: `./todo done <bad-index>` mishandles an out-of-range index. The data store (`todos.txt`) makes state tangible alongside the WIP file, reinforcing beat A.

**Backlog fold-ins (in-blast-radius, verify each against real code first — review-finding-actions-are-hypotheses):**
- `SURFACE-2026-07-22-QUALITY-NEW-SAMPLE-HELP-LEAKS-CODE` (MAJOR, medium) — `new-sample.sh --help` leaks code via magic `sed -n '2,20p'`. `new-sample.sh` is rewritten in Phase 2 → fix here with a delimiter-anchored extraction.
- `SURFACE-2026-07-22-QUALITY-NEW-SAMPLE-MKTEMP-DOUBLE-SLASH` (MINOR, low) — double-slash when `$TMPDIR` ends in `/`. Same file → fix here.
- `SURFACE-2026-07-22-QUALITY-GREET-TODO-RESTATES-WHAT` (MINOR, low) — was about `greet.sh`'s TODO; `greet.sh` is *replaced* by the todo CLI. Resolved-by-redesign; the new tangent re-instantiates the same self-documenting-WHY pattern (keep the WHY, don't over-restate the WHAT).

## Work Tree

- [x] Phase 1: Richer sample skeleton — the todo CLI (content)  <!-- status: [x] — all children complete -->

  **Observable outcomes:**
  - CLI: `./todo add "buy milk"` exits 0; then `./todo list` exits 0 and stdout contains a line matching `1. [ ] buy milk` (numbered, unchecked)
  - CLI: `./todo add "a" && ./todo done 1 && ./todo list` exits 0 and stdout shows item 1 as checked (`[x]`)
  - CLI (planted tangent, authentic): `./todo done 99` (out-of-range index, empty list or too-high) does NOT exit cleanly-correct — it mishandles the bad index (documented under a `TODO` in `sample/README.md`); this is the reliable SURFACE trigger
  - CLI: the whole sample uses only POSIX shell + a plain-text store — `bash -n` on every `*.sh` exits 0; no runtime deps invoked
  - [x] P1.1 Design + author the todo CLI: `todo` dispatcher + `lib/{add,list,done}.sh` modules + `todos.txt` store + `sample/README.md` (states the observable outcomes + carries the planted-tangent TODO with a WHY)  <!-- status: [x] -->
  - [x] P1.2 Plant the authentic tangent (out-of-range `done <index>` mishandling) as a *real* small bug, self-documented in README under TODO (keep WHY, avoid pure WHAT-restatement per QUALITY-GREET-TODO finding)  <!-- status: [x] -->
  - [x] P1.3 Remove the retired `greet.sh` + old README content; ensure the sample dir contains only the new skeleton  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — bash -n clean ×4, exec bits present, dispatch smoke (help 0 / unknown 2), observable exact match -->
  - [x] verify-self  <!-- status: [x] — subagent 4/4 PASS: observable 1 (1. [ ] buy milk exact), observable 2 (1. [x] a persisted), planted tangent (done 99 reproduces mishandling), no-runtime-deps (bash -n clean, all shebangs bash). No integration boundary (isolated new artifacts). -->
  - [x] verify-human  <!-- status: [x] — AUTO-SKIP (F11) per drive_mode=autopilot; auto-skip gate clean (a autopilot, b verify-self all-PASS, c no integration boundary — isolated new artifacts, d no outcome cites a modified consuming surface). Affirmation printed for read-time veto. -->
  - [x] verify-codify  <!-- status: [x] — Phase-1 behaviors codified in Phase 2's smoke-test rewrite (P2.2), not throwaway Phase-1 tests. Triage written: scaffold smoke fails on retired greet.sh = expected obsolescence (high confidence), rewritten in P2.2. Blast-radius grep confirms greet.sh live refs only in Phase-2/3 targets (new-sample.sh, smoke, tool README, arm SKILL.md); no surprise consumers. No integration boundary. -->

  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — operator ratified WP7i (richer sample) this session
  - Requirements unchanged: yes — todo CLI sample chosen; Phase 2 wires the stamper + smoke to it
  - Solution still feasible: yes — Phase 1 shipped the skeleton; Phase 2 is the mechanical follow-on
  - No superior alternative discovered: yes
  **Verdict:** proceed

- [x] Phase 2: Scaffolder + smoke test to the new skeleton  <!-- status: [x] — all children complete; depends on Phase 1 -->
  **Observable outcomes:**
  - CLI: `tools/onboarding-scaffold/new-sample.sh --dest <empty>` stamps a fresh copy; the copy runs the Phase-1 observable (`./todo add … && ./todo list`) exit 0, correct output — copy is independent of source
  - CLI: `new-sample.sh --help` prints ONLY the usage prose and stops before `set -euo pipefail` (fixes QUALITY-NEW-SAMPLE-HELP-LEAKS-CODE — delimiter-anchored, not magic line range)
  - CLI: `new-sample.sh` default-dest printed path contains no `//` even when `$TMPDIR` ends in `/` (fixes QUALITY-NEW-SAMPLE-MKTEMP-DOUBLE-SLASH)
  - CLI: `tools/onboarding-scaffold/test/run-tests.sh` exits 0 — all assertions pass against the new skeleton (observable, tangent, fresh-copy, independence, no-clobber, `--force`, arm↔scaffold wiring)
  - [x] P2.1 Update `new-sample.sh` to the new skeleton: fix `usage()` to delimiter-anchored extraction (--help leak) + trailing-slash strip on the mktemp default; run-hint copy points at the todo CLI observable  <!-- status: [x] — awk delimiter-anchored usage() (fixes HELP-LEAKS-CODE); while-loop strips ALL trailing slashes (fixes MKTEMP-DOUBLE-SLASH — %/ alone strips only one, caught by the smoke under real macOS TMPDIR); run-hint → todo add/list -->
  - [x] P2.2 Rewrite `tools/onboarding-scaffold/test/run-tests.sh` assertions to the new observable (`todo add/list/done`) + the new tangent (`done <bad-index>`); keep the fresh-copy / independence / no-clobber / `--force` / arm-wiring assertions; add a `--help`-no-leak assertion + a no-double-slash assertion  <!-- status: [x] — 8 assertion groups: observable, done-persist, tangent+README-TODO, no-runtime(bash -n+shebangs), fresh-copy+independence, no-clobber+force, --help-no-leak + no-double-slash, arm-wiring. 13/15 PASS (2 arm-wiring FAIL = expected until Phase 3 re-cites the arm) -->
  - [x] P2.3 Update `tools/onboarding-scaffold/README.md` (Layout tree, canonical invocations, "why the sample is shaped this way", the two load-bearing properties) to the todo CLI  <!-- status: [x] — layout tree, invocations, why-shaped (todo CLI, a-couple-of-real-modules rationale), both load-bearing properties, keep-minimal note all re-cited -->
  - [x] verify-auto  <!-- status: [x] — bash -n clean on new-sample.sh + smoke; scoped smoke 13/15 PASS, the only 2 FAILs are the expected [8] arm-wiring assertions (Phase 3 re-cites the arm); --help-no-leak + no-double-slash regression guards green -->
  - [x] verify-self  <!-- status: [x] — subagent 4/4 PASS: scaffolder stamps fresh/runnable/independent copy (1. [ ] buy milk), --help no code-leak, no double-slash (real+trailing-slash TMPDIR), smoke intermediate state exactly 13/2 with both FAILs = arm-wiring (Phase 3). Integration boundary (existing new-sample.sh CLI) satisfied — outcomes cite the consuming scaffolder by name. -->
  - [x] verify-human  <!-- status: [x] — F13 operator-approved 2026-07-22 (integration boundary → Mode-3 PAUSE; operator approved on verify-self evidence, all 3 leaves confirmed PASS by verify-self). -->
    - [x] P2.verify-human.1 --help shows no leaked code  <!-- status: [x] — verify-self confirmed -->
    - [x] P2.verify-human.2 fresh copy stamps + runs new observable (1. [ ] buy milk), no // in path  <!-- status: [x] — verify-self confirmed -->
    - [x] P2.verify-human.3 smoke at expected intermediate state (13 passed / 2 arm-wiring failed)  <!-- status: [x] — verify-self confirmed -->
  - [x] verify-codify  <!-- status: [x] — Phase-2 behaviors codified in the rewritten smoke (P2.2, end-to-end CLI = highest-level test; integration-boundary consuming-surface test = groups [5]/[6]/[7] invoking new-sample.sh directly, incl. --help-no-leak + no-double-slash regression assertions). Full suite check-structure.sh 472/0 (no regression). No test failure → no triage. Smoke's 2 remaining reds = arm-wiring, satisfied by Phase 3. -->

  **Relevance check (before Phase 3):**
  - Requester still needs this: yes — Phase 3 (arm re-cite + upfront framing) is the WP's user-facing deliverable
  - Requirements unchanged: yes
  - Solution still feasible: yes — sample + scaffolder shipped; Phase 3 wires the arm to them
  - No superior alternative discovered: yes
  **Verdict:** proceed

- [x] Phase 3: Greenfield arm re-cite + upfront project framing (copy)  <!-- status: [x] — all children complete; depends on Phase 1, Phase 2 -->
  **Observable outcomes:**
  - CLI (integration boundary — the arm is the consuming surface): `skills/tutorial-greenfield-workflow-tour/SKILL.md` no longer cites `greet.sh` / `Hello, World!` / `Hello, !`; it cites the new todo CLI, the new observable (`todo add … && todo list` → `1. [ ] buy milk`), and the new tangent (`todo done <bad-index>`) — grep confirms old strings absent, new strings present
  - CLI: the arm carries an **upfront "what this project is / what we're building"** framing block before Step 1 (G1) — grep confirms a project-intro section precedes the Step 1 heading
  - CLI: `tests/check-structure.sh` exits 0 (path-qualification mandate held: no bare `.claude/`; all scaffold path refs intact)
  - CLI: the scaffold smoke's arm↔scaffold wiring assertions (test Phase 5) still pass against the re-cited arm (observable + tangent strings match)
  - [x] P3.1 Add the upfront "what this sample project is / what we're building" framing to the greenfield arm before G1 (Step 0 or a pre-Step-1 environment/intro block), honest-framing §6 preserved (no "5-min" claim)  <!-- status: [x] — new "### Say what the project is, upfront (before Step 1 — WP7i)" subsection in the environment block: 2-sentence todo-CLI intro copy + ls/cat orientation, framed as beat-G-neighbor not a staged beat -->
  - [x] P3.2 Re-cite the real observable (Step 5 grounding) + real tangent (Step 6 SURFACE) + the environment section to the todo CLI; update the `new-sample.sh` run hint reference  <!-- status: [x] — environment section describes the todo CLI + both load-bearing properties; Step 5 cites `todo add "buy milk" && todo list`→`1. [ ] buy milk`; Step 6 cites `todo done 99` no-op tangent. Zero stale greet.sh/Hello strings remain. -->
  - [x] P3.3 Confirm the arm↔scaffold wiring contract still holds (the smoke's Phase-5 grep anchors match the new cited strings) — update either side so the pinned observable/tangent strings agree  <!-- status: [x] — smoke [8] anchors updated in P2.2 to `1. [ ] buy milk` + `done 99`; arm now cites both; smoke 15/15 PASS (0 fail) -->
  - [x] verify-auto  <!-- status: [x] — scaffold smoke 15/15 (arm↔scaffold wiring satisfied); check-structure.sh 472/0 (arm SKILL.md structure intact, no regression) -->
  - [x] verify-self  <!-- status: [x] — subagent 5/5 PASS: arm re-cite (old strings gone, 3 new anchors present), upfront framing precedes Step 1 (L63<L88), honest-framing preserved (no 5-min claim, ~10–15-min present), full suite green (smoke 15/0 + check-structure 472/0), no bare .claude/. Integration boundary (arm SKILL.md = consuming surface) satisfied — outcomes cite it by name. -->
  - [x] verify-human  <!-- status: [x] — F13 operator forward-progress on the mechanical evidence (2026-07-22). Copy-reads-well-for-a-cold-skeptic judgment DEFERRED to the operator's 2nd hands-on /tutorial-getting-started walkthrough (once the whole ratified M11 tail is addressed) — NOT skipped. Same posture as WP7c/WP7d/WP7g; rides SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED (now covers WP7i copy too). -->
    - [x] P3.verify-human.1 richer todo-CLI sample compelling  <!-- status: [x] — DEFERRED-to-operator-2nd-walkthrough (mechanical facts verify-self-confirmed; copy judgment on the SURFACE) -->
    - [x] P3.verify-human.2 upfront framing reads well  <!-- status: [x] — DEFERRED-to-operator-2nd-walkthrough -->
    - [x] P3.verify-human.3 Step 5/6 copy reads honestly  <!-- status: [x] — DEFERRED-to-operator-2nd-walkthrough -->
  - [x] verify-codify  <!-- status: [x] — arm↔scaffold wiring codified by scaffold smoke group [8] (consuming-surface test: greps the real arm SKILL.md for tools/onboarding-scaffold + '1. [ ] buy milk' + 'done 99'). Tour behavioral scenarios + tutorial-prefix pins = WP7e's charter, NOT pulled forward. Full suite: smoke 15/0 + check-structure 472/0, no regression, no test failure → no triage. -->

## Reverting this feature
Prose/scaffold-only; no transition, no state-machine change. To revert: `git revert <ship-commit>` restores the greet.sh sample + old arm citations + old smoke. The 3 fold-in quality fixes (--help leak, mktemp double-slash — both in new-sample.sh; greet.sh TODO resolved-by-redesign) would revert with it. No install.sh re-run needed (no new/renamed skill dir — the arm was edited in place, already symlinked).

## Current Node
- **Path:** Feature > ship
- **Active scope:** ALL phases complete (Phase 1, 2, 3 [x]); ready for /feature-ship
- **Blocked:** none
- **Unvisited:** none — ship next
- **Open discoveries:** none — all phases [x]. Copy-acceptance deferred to operator 2nd walkthrough (SURFACE, not a blocker).

## Build log — Phase 3 (2026-07-22)
Re-cited the greenfield arm (`skills/tutorial-greenfield-workflow-tour/SKILL.md`) to the todo CLI: environment section now describes the todo CLI + both load-bearing properties (P3.2); Step 5 grounding cites `todo add "buy milk" && todo list`→`1. [ ] buy milk`; Step 6 SURFACE cites the `todo done 99` no-op tangent. Added the upfront "### Say what the project is, upfront" framing subsection before Step 1 (P3.1) — 2-sentence todo-CLI intro + ls/cat orientation, honest-framing §6 preserved (no "5-min" claim; the ~10–15-min framing untouched). Verified: zero stale greet.sh/Hello strings; all 3 wiring-contract anchors present; no bare .claude/. Smoke now 15/15 PASS (the 2 previously-red arm-wiring assertions satisfied). Integration boundary: the arm is the consuming surface of the scaffold — Phase 3 modifies it directly.

## Build log — Phase 2 (2026-07-22)
Updated `new-sample.sh` (P2.1): `usage()` now uses a delimiter-anchored awk (prints the post-shebang `#`-comment block, stops at first non-comment line) — fixes `SURFACE-2026-07-22-QUALITY-NEW-SAMPLE-HELP-LEAKS-CODE` (was `sed -n '2,20p'` leaking `set -euo pipefail`). Fixed `SURFACE-2026-07-22-QUALITY-NEW-SAMPLE-MKTEMP-DOUBLE-SLASH` with a while-loop stripping ALL trailing slashes (the naive `${x%/}` strips only one — the smoke under the real macOS `TMPDIR` (`.../T/`) caught that the first-cut single-strip fix still double-slashed; robust loop lands it). Run-hint copy → `todo add "buy milk" && todo list`. Rewrote the smoke (P2.2) to 8 assertion groups against the todo CLI + the new tangent + the two quality-fix regressions (--help-no-leak, no-double-slash); 13/15 PASS (the 2 arm-wiring assertions FAIL by design until Phase 3 re-cites the arm). Updated the tool README (P2.3) to the todo CLI. `bash -n` clean.

## Build log — Phase 1 (2026-07-22)
Authored the todo CLI sample (`sample/todo` dispatcher + `sample/lib/{add,list,done}.sh` + empty `sample/todos.txt` store + rewritten `sample/README.md`); `git rm`'d the retired `greet.sh`. Smoke-verified during build: observable 1 (`add "buy milk" && list` → `1. [ ] buy milk`) ✓; observable 2 (`done 1 && list` → `1. [x] buy milk`) ✓; planted tangent (`done 99` on 1-item list → "marked item 99 as done", exit 0, list unchanged — authentic out-of-range no-op) ✓; edge cases (empty-list message, non-numeric-index guard exit 2, multi-item, re-done prefix-strip preserves text, dispatcher unknown/help) all correct; shipped `todos.txt` stayed 0 bytes (edits hit throwaway stores). `bash -n` clean on all 4 scripts.

## Notes / design constraints (from spec §8 + WBS ratified block)
- **No-runtime / no-deps:** POSIX-ish bash + markdown + a plain-text store only. No node/python/etc. It must not rot (rides path/skill/layout changes — cf. M7 moved every folder).
- **Runnable ≥1 observable outcome** (verify-self grounding, arm Step 5): the `todo add … && todo list` round-trip is the observable.
- **Authentic planted tangent** (SURFACE, arm Step 6): out-of-range `done <index>` — a *real* small bug, self-documented under a README TODO. Not a fake breadcrumb.
- **Copy-per-run stamper KEPT** (`new-sample.sh`): the mechanism is sound; only its extracted content changes + its two quality fixes land.
- **Integration-boundary rule fires on Phase 3:** the greenfield arm is the *consuming surface* of the scaffold — Phase 3 verify-self must cite the arm, verify-human cannot use the F11 skip path, verify-codify must include a check on the arm (the smoke's Phase-5 wiring assertions cover this).
- **WP7e still owns** the tour's behavioral scenarios + `tutorial-`-prefix structural pins — NOT pulled forward here (only the scaffold smoke + check-structure path pins run in this WP).
- **verify-human acceptance:** per autopilot + the standing `SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED`, copy-reads-well-for-a-cold-skeptic remains the operator's deferred hands-on judgment; verify-self confirms the mechanical facts.

## Test Triage — tools/onboarding-scaffold/test/run-tests.sh (Phase 1 codify)
Classification: Obsolete test — the new feature (Phase 1's richer todo-CLI sample) intentionally supersedes what the test checked (the retired greet.sh). The 4 failing assertions all reference greet.sh / "Hello, World!" / "Hello, !", which Phase 1 deliberately removed.
Confidence: high
Evidence: All 4 failures are `rc=127 ... greet.sh: No such file or directory` (test [1], [2], [3]) + the dependent `--force` re-run in [4] which runs the now-absent greet.sh; the wiring assertions in [5] still pass against the not-yet-re-cited arm (Phase 3 re-cites them).
Action: NO test modification in Phase 1 codify — the smoke-test rewrite to the new todo-CLI observable + tangent is Phase 2 task P2.2 (the phase that owns the scaffolder + smoke). Phase 1's verified behaviors (observable, done-persistence, planted tangent, no-deps) are codified there, not in throwaway Phase-1 tests that P2.2 would immediately overwrite. This is expected obsolescence, not an unexpected regression — no other test suite is affected by Phase 1's isolated new artifacts.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
