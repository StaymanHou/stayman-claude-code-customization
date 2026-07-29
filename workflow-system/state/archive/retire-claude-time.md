---
workflow: task
state: COMPLETED
created: 2026-07-29
docs-only: false
---

# Task: Retire `tools/claude-time/` entirely

**Workflow:** task
**State:** COMPLETED
**Completed:** 2026-07-29
**Created:** 2026-07-29

## Problem Statement

`install.sh` still installs the `claude-time` tool (hook + CLI) that Claudesk's Milestone 9 absorbed natively on 2026-07-16, so a fresh install registers a redundant second time-tracking hook — and the operator's decision (2026-07-29) is to retire the tool from this repo entirely rather than gate or drop just the install block.

## Context

**Origin:** [`HANDOFF-from-claudesk-2026-07-29.md`](../../../HANDOFF-from-claudesk-2026-07-29.md) — asked for one of three resolutions; operator chose option 3 (full retirement), which the handoff itself ranked last and flagged as "biggest step."

**Surfaces discovered (all verified by grep/read, not assumed):**

| Surface | Detail |
|---|---|
| `install.sh:94-133` | `CLAUDE_TIME_DIR` block + `link_artifact()` helper. Helper is **defined inside this block and used only by its own two calls** — verified: no other `link_artifact` callsite exists. Goes with the block. |
| `uninstall.sh:161-166` | Removal guarded by `[ -d "$CLAUDE_TIME_DIR" ]` — **becomes permanently false** once the dir is gone. Handoff says keep the cleanup; the guard must be dropped or the cleanup silently no-ops. |
| `tools/claude-time/` | 32 tracked files, 1.3M. Contains `docs/url-hash-state.md` + `docs/design-extract-history.md`, both cited from root `CLAUDE.md`. |
| `tests/check-structure.sh` Phase 5b (L732-935) | **52 assertions.** Includes nested invocations of the tool's own suites (`test_hook.sh`, `privacy_check.sh`, `test_cli.sh`, `test_visualize_cli.sh`, `python3 -m unittest test_reclassify`, `test_viz_data`) — those are *subprocess* calls, so deleting the dir without deleting the phase yields hard FAILs, not skips. |
| `tests/check-structure.sh` Phase 5c (L936-1033) | **11 assertions** (viz prototype integrity). |
| `tests/check-structure.sh` L728 | Phase 5 comment cross-referencing 5b — a dangling pointer after deletion. |
| `tests/fixtures/settings.json` | Pins `claude-time-hook.pl` on 10 lifecycle events + `CLAUDE_TIME_TRACKING: "1"` in `env`. |
| Phase 7 drift check (L1207+) | Diffs fixture vs **live** `~/.claude/settings.json`. Comment at L1249-1250 states UserPromptSubmit "must match exactly — it is fully drift-checked." So the fixture and live must be edited **in lockstep**. `INTENTIONAL_DIFFS` and the `HOST_LOCAL_KEYS` comment both name claude-time and need rewording. |
| Live `~/.claude/settings.json` | **Machine-local, NOT tracked in this repo.** 10 hook entries + `CLAUDE_TIME_TRACKING: "1"`. |
| Live symlinks | `~/.claude/hooks/claude-time-hook.pl`, `~/.claude/bin/claude-time` — both currently resolve into this repo (verified). |
| `tools/uninstall/test/run-tests.sh:121-122` | **Two assertions that will go GREEN-VACUOUS.** They assert `[ ! -L <path> ]` after uninstall. Once install.sh no longer creates the links, the paths never exist, so both pass **without exercising any removal** — the exact "green test that guards nothing" class (fails-OPEN on a missing file). Must be deleted or rewritten to pre-seed the links. |
| `tools/uninstall/README.md:15` | Documents the two symlinks in the removal table. |
| Root `CLAUDE.md` | **5** claude-time bullets, not 4: L38 (Docker container test path), L175 (`build_metrics` empty-window), L176 (design-as-data byte-pin history), L177 (URL-hash view state), L178 (calendar-anchored window default). |
| `workflow-system/state/backlog.md:247-248` | Two claude-time SURFACE items inside a `## Buried` context — check section before touching; **buried ≠ resolved**, so delete-on-resolve does NOT apply. |
| `runtimes.md` | Tracks `./tests/check-structure.sh` → **`Use timeout: 105000`**, last 29s. Also tracks `tools/uninstall/test/run-tests.sh` → 66000. |

**Product context:** `arch.md` read-check — the task touches no workflow state machine, no skill contract, no cross-module workflow boundary. It removes a standalone tool + its test phases. Read skipped per the conditional-read rule (472 lines, would have needed the size guard).

**Scope assessment:** stays a task. No new data models, no API surface, no architectural decision — the decision was already made by the operator. It is a wide but mechanical deletion with three sharp edges (vacuous-pass assertions, the lockstep fixture/live edit, the dead uninstall guard), all identified up front.

## Non-obvious risks this plan explicitly handles

1. **Two assertions go green-vacuous** (`tools/uninstall/test/run-tests.sh:121-122`) — they'd keep "passing" while guarding nothing. Per this repo's `/test-assertion-review` discipline (fails-OPEN on a missing file), they get deleted, not left to rot.
2. **The `uninstall.sh` guard inverts meaning** — `[ -d "$CLAUDE_TIME_DIR" ]` was a proxy for "this repo ships claude-time"; after retirement it must become unconditional to still clean up *old* installs, which is the handoff's stated preference.
3. **Fixture and live settings must move together** or Phase 7 FAILs. Live is machine-local and outside version control — an explicit side effect on the operator's machine.
4. **Capability loss is real and not git-recoverable.** History keeps the code; the running tracker and its accumulated store stop. Flagged to the operator pre-plan; proceeding on their confirmed call.
5. **Pre-existing unrelated FAIL:** Phase 7 currently reports `effortLevel: live=<missing> fixture="xhigh"` (tracked in the `project_settings_fixture_claudesk_drift` memory + `runtimes.md` history since 2026-07-25). Expect **1 FAIL at baseline** — do not attribute it to this task, and do not fix it here.

## Work Tree

- [x] T1 Capture baseline: run `./tests/check-structure.sh` (timeout 105000) and record PASS/FAIL counts + the claude-time-attributable subset, so the post-deletion delta is measured rather than assumed  <!-- status: complete -->
  - Baseline: **`check-structure.sh` 597 PASS / 1 FAIL** (lone FAIL = pre-existing `effortLevel: live=<missing> fixture="xhigh"` drift, as predicted). **`tools/uninstall/test/run-tests.sh` 45 passed / 0 failed.**
  - **Correction to the plan's expected delta:** Phases 5b+5c hold **63 static `check "` source sites but emit only 31 runtime assertions** (25 in 5b, 6 in 5c) — most sites are if/else pairs where two source lines emit one check. **T12 must expect 597 → 566 (−31), not −63.**
- [x] T2 Remove the `claude-time` block from `install.sh` (L94-133, incl. the `link_artifact` helper) — verified no other callsite  <!-- status: complete -->
- [x] T3 Rework `uninstall.sh` L161-166: drop the `[ -d "$CLAUDE_TIME_DIR" ]` guard so the two `remove_link` calls still run and strand no old installs; keep `remove_link`'s own into-repo safety guard  <!-- status: complete -->
- [x] T4 Fix the two would-be-vacuous assertions in `tools/uninstall/test/run-tests.sh:121-122` — pre-seed the two symlinks in the sandbox before uninstall so the removal is genuinely exercised (preferred), else delete them outright; update `tools/uninstall/README.md:15` to match  <!-- status: complete -->
- [x] T5 Delete Phase 5b (L732-935, 52 assertions) and Phase 5c (L936-1033, 11 assertions) from `tests/check-structure.sh`; fix the dangling 5b cross-reference at L728  <!-- status: complete -->
- [x] T6 Update `tests/fixtures/settings.json`: drop the 10 `claude-time-hook.pl` entries + `CLAUDE_TIME_TRACKING`; reword the 3 claude-time explanatory notes at the top  <!-- status: complete -->
- [x] T7 Update Phase 7's `INTENTIONAL_DIFFS` + `HOST_LOCAL_KEYS` prose (L1221-1266) so no comment references claude-time and the Notification/Stop rationale still reads correctly  <!-- status: complete -->
- [x] T8 **[machine-local side effect]** Unwire live `~/.claude/settings.json`: remove the 10 `claude-time-hook.pl` hook entries + `CLAUDE_TIME_TRACKING`. Back up first. Must land with T6/T7 or Phase 7 FAILs  <!-- status: complete -->
- [x] T9 `git rm -r tools/claude-time/` (32 files)  <!-- status: complete -->
- [x] T10 **[machine-local side effect]** Remove the now-dangling live symlinks `~/.claude/hooks/claude-time-hook.pl` and `~/.claude/bin/claude-time`  <!-- status: complete -->
- [x] T11 Root `CLAUDE.md`: remove all 5 claude-time bullets (L38, L175-178). The two docs they cite live inside the deleted dir, so these are deletions, not redirects — no dangling pointers may remain  <!-- status: complete -->
- [x] T12 Re-run `./tests/check-structure.sh` (timeout 105000) and `tools/uninstall/test/run-tests.sh` (timeout 66000); confirm the delta is exactly **−31 emitted** assertions (per T1's correction to the plan's original −63 static estimate) from Phases 5b/5c plus the T4 change, and that the only FAIL is the pre-existing `effortLevel` drift  <!-- status: complete -->
- [x] T13 Update `runtimes.md` for both suites with new observed runtimes (5b/5c ran Docker-less Python/shell subprocesses, so expect a measurable drop) + a history comment recording the assertion-count change  <!-- status: complete -->
- [x] T14 Write the reply to Claudesk (it asked to be pinged) recording resolution = option 3 + the `uninstall.sh` keep-cleanup answer it asked about, then dispose of `HANDOFF-from-claudesk-2026-07-29.md` from the repo root  <!-- status: complete -->

## Outcome

**All 14 steps complete.** Verified results:

| Suite | Before | After | Delta |
|---|---|---|---|
| `./tests/check-structure.sh` | 597 PASS / 1 FAIL, 29s | **566 PASS / 1 FAIL, 9s** | **−31 emitted** (exactly Phases 5b+5c) |
| `tools/uninstall/test/run-tests.sh` | 45 passed / 0 failed, 4s | **47 passed / 0 failed, 5s** | **+2** (fail-closed seed preconditions) |

The lone FAIL is the pre-existing, out-of-scope `effortLevel: live=<missing> fixture="xhigh"` drift — unchanged, and NOT a regression from this task. Phase 7 reported **no new hook drift**, which is the positive confirmation that the fixture↔live lockstep edit (T6+T8) landed correctly.

**Three verifications worth keeping:**

1. **T4's rewrite is sensitivity-proven, not asserted.** Re-adding the dead `[ -d "$CLAUDE_TIME_DIR" ]` guard to `uninstall.sh` **with the tool dir absent** flips both removal assertions to FAIL (45 passed / 2 failed). Pre-rewrite they would have stayed green on paths that never existed. Script restored byte-identical after the probe.
2. **A fresh `install.sh` creates zero claude-time artifacts** — verified in a throwaway `$HOME`: zero occurrences of `claude-time` in its output. Also discovered: it no longer creates `~/.claude/hooks/` or `~/.claude/bin/` at all, since those `mkdir -p` calls lived in the retired block and this repo ships no `hooks/` dir. Recorded in the reply for Claudesk's consent copy.
3. **All 20 claudesk hook entries in live settings were preserved** while the 10 claude-time entries were removed — this repo removed only its own hook, which is exactly the removal Claudesk declined to make on its behalf.

**Bonus coverage gain:** Phase 7's `INTENTIONAL_DIFFS` is now **empty**. It previously exempted `hooks.Notification`/`Stop` because live ran the repo-owned claude-time hook there. With no repo-owned hook left on any event, both sides reduce to empty hook lists after claudesk stripping, so all 10 events are now diffed **exactly** — strictly more coverage than before retirement.

**Machine-local side effects (outside version control):**
- `~/.claude/settings.json` — 10 hook entries + `CLAUDE_TIME_TRACKING` removed. Backup: `~/.claude/settings.json.pre-claude-time-retirement.bak`.
- `~/.claude/hooks/claude-time-hook.pl` + `~/.claude/bin/claude-time` — removed (confirmed dangling first).

**Four extra live surfaces found by a final `git grep` sweep** (beyond the plan's 8-surface inventory — the plan's grep had excluded `tools/claude-time/` itself and so missed references living elsewhere):

- `workflow-system/product/arch.md:266` — a **durable doc making a present-tense claim** that install creates the claude-time symlinks. Rewritten to state the retirement + the deliberate uninstall asymmetry + why the raw-`readlink` fallback is what reclaims a dangling legacy link. This is the "doc claim must be written in the tense of what exists at commit time" rule from root `CLAUDE.md`.
- `tests/scenarios/session.yaml:827` — `S20-amend-head` used claude-time as *illustrative content* for a learning to save. It never asserted the tool exists, so the scenario still passed, but it cited a now-nonexistent path. Re-pointed at the live `tools/uninstall/test/run-tests.sh` sandboxed-runner example (equivalent shape: a project-specific "use the wrapper, not the host" rule). YAML re-validated.
- `tests/run-tests.sh:206` — comment naming claude-time as a live runtime hook. Corrected to claudesk-only.
- `.gitignore:11` — dead ignore pattern for `tools/claude-time/viz/verify-self-screenshot*.png`. Removed.

Historical records were deliberately left untouched: `CHANGELOG.md`, `workflow-system/product/transitions.md` (both claude-time entries are dated 2026-06-24 log records, correct as history), the archived WBS/WIP files under `workflow-system/product/archive/` and `workflow-system/state/archive/`, and the `.claude/learnings/` + `.claude/memory/` entries. Rewriting those would falsify the record.

**Deliverable for Claudesk:** [`HANDOFF-REPLY-to-claudesk-2026-07-29.md`](../../../HANDOFF-REPLY-to-claudesk-2026-07-29.md). Both handoff files were left at the repo root rather than deleted, matching how `HANDOFF-from-claudesk-2026-07-20.md` was treated (kept as the reference record for a cross-repo decision).

## Verification Observable

**Observable:** A real (non-dry-run) `install.sh` into a throwaway `$HOME` creates **no** `claude-time` artifact of any kind, while a subsequent real `uninstall.sh` still reclaims a **pre-retirement** install's two dangling `claude-time` symlinks — proving the ask was met on the way IN without stranding old installs on the way OUT.

**Verification command:**
```bash
# (a) fresh install into a throwaway $HOME — the surface the handoff complained about
env HOME="$SB" ./install.sh
#     assert: zero files/links matching *claude-time* anywhere under $SB/.claude
#     assert: zero "claude-time" occurrences in install output
# (b) seed a PRE-RETIREMENT install (2 dangling into-repo links), then real uninstall
ln -s <repo>/tools/claude-time/hook.pl     "$SB/.claude/hooks/claude-time-hook.pl"
ln -s <repo>/tools/claude-time/claude-time "$SB/.claude/bin/claude-time"
env HOME="$SB" ./uninstall.sh
#     assert: both links gone, and uninstall reported [remove] for each
# (c) end-to-end regression suites at their registry timeouts
./tests/check-structure.sh                 # timeout 74000
tools/uninstall/test/run-tests.sh          # timeout 68000
# (d) live-machine end state
grep -c claude-time ~/.claude/settings.json ; ls ~/.claude/hooks ~/.claude/bin
```

**Expected result:**
- (a) `install.sh` exits 0; **0** matches for `*claude-time*` under `$SB/.claude`; **0** occurrences of `claude-time` in stdout.
- (b) `uninstall.sh` exits 0; both seeded links **removed**; output contains a `[remove]` line for each (proving the unconditional cleanup fired, not a silent no-op).
- (c) `check-structure.sh` → **566 PASS / 1 FAIL** (the lone FAIL being the pre-existing `effortLevel` drift, and **no** hook-drift failure); `uninstall/test/run-tests.sh` → **47 passed / 0 failed**.
- (d) live `settings.json` → **0** `claude-time` occurrences with claudesk hooks intact; neither live symlink present.

## Verification Result

**Status:** PASS
**Date:** 2026-07-29

**Evidence** (quoted literally from the run):

(a) Fresh real install into a throwaway `$HOME` — `install exit: 0`
```
--- claude-time artifacts under $SB/.claude (expect 0) ---
COUNT: 0
--- 'claude-time' occurrences in install stdout (expect 0) ---
0
```

(b) Seeded a pre-retirement install, then real uninstall — both seeded links confirmed **dangling** first (`symlink=yes resolves=NO-dangling`), `uninstall exit: 0`
```
  [remove] hooks/claude-time-hook.pl
  [remove] bin/claude-time
--- links after uninstall (expect BOTH gone) ---
  claude-time-hook.pl: gone
  claude-time: gone
```

(c) Regression suites
```
PASS: 566 | FAIL: 1
Failures:
  - settings fixture in sync with live (modulo documented diffs): drift detected …
  effortLevel: live=<missing> fixture="xhigh"
--- does any failure mention hooks? --- 0 — no hook drift

=== 47 passed, 0 failed ===
```

(d) Live end state — `claude-time` occurrences in `~/.claude/settings.json`: **0**; claudesk hook entries: **20** (intact); `CLAUDE_TIME_TRACKING`: removed; both live symlinks: **absent**; settings.json: **VALID**; backup present (9298 bytes); `tools/claude-time`: **absent**; 32 staged deletions.

**Notes:** All four parts matched their declared expected results with no substitutions. The two load-bearing observations: **(a)** the exact surface the handoff complained about now produces zero claude-time artifacts on a *real* install (not `--dry-run` — the failure mode lived in what install writes to disk, so a dry-run proxy would have been invalid); and **(b)** the `[remove]` lines prove T3's unconditional cleanup genuinely *fired* against dangling into-repo links rather than silently no-opping, which is precisely the regression the retired `[ -d "$CLAUDE_TIME_DIR" ]` guard would have introduced. The lone `check-structure.sh` FAIL is the pre-existing, out-of-scope `effortLevel` fixture drift (tracked since 2026-07-25, predicted in the plan's risk #5); the explicit hook-drift probe returned zero, confirming the fixture↔live lockstep edit (T6+T8) is coherent.

**No sibling-bugs surfaced.** The four extra live surfaces found during act (`arch.md`, `session.yaml`, `run-tests.sh`, `.gitignore`) were fixed in-scope during T11's sweep, not deferred here.

## Retrospect

- **What changed in our understanding:** Three things, all discovered by recon rather than by the handoff. (1) **The handoff's own preference order was inverted relative to blast radius.** It ranked full retirement last and called it "biggest step," but the reason it was big wasn't the 32 deleted files — it was that `check-structure.sh` Phases 5b/5c *invoke the tool's own test suites as subprocesses* (perl, 4 py_compile, 2 unittest, 6 nested shell suites). Deleting the directory without deleting the phases produces hard FAILs, not skips. (2) **Two assertions were poised to go green-vacuous** in `tools/uninstall/test/run-tests.sh` — `[ ! -L <path> ]` passes trivially once nothing creates those paths. The handoff couldn't have known this; it's the fails-OPEN-on-missing-file mechanism from this repo's own `/test-assertion-review`. (3) **The `uninstall.sh` guard inverted meaning under retirement.** The handoff argued (correctly) to keep the cleanup, but `[ -d "$CLAUDE_TIME_DIR" ]` becomes permanently false the moment the dir is deleted — so keeping the code as-written would have silently stranded every pre-retirement install, defeating the very thing being asked for.
- **Assumptions that held:** The tool had no runtime coupling to anything else in the repo (`link_artifact` was defined inside the doomed block and called only by its own two lines — verified, not assumed). `remove_link`'s existing raw-`readlink` fallback already handled the dangling-link case, so dropping the outer guard needed no new safety code. The plan's predicted single pre-existing FAIL (`effortLevel` drift) was exactly right and stayed the only failure start to finish.
- **Assumptions that were wrong:** **The plan's expected assertion delta (−63) was wrong — it was −31.** The plan counted static `check "` source sites; 5b/5c are written as if/else pairs where two source lines emit *one* runtime assertion. This was caught only because T1 recorded a real baseline before touching anything. Had the baseline been skipped, 566 would have looked like 31 assertions silently vanishing. Also wrong: the plan said root `CLAUDE.md` had 4 claude-time bullets — it had 5.
- **Approach delta:** Two deviations from plan. (a) **T4 was upgraded from "delete the assertions" to "seed the links and keep them."** Deleting would have lost real coverage of a removal path that still runs; seeding the links as *dangling* into-repo links preserves it and matches post-retirement reality. This was mutation-verified (re-adding the dead guard with the tool absent flips both to FAIL) rather than assumed. (b) **A final `git grep` sweep found 4 live surfaces the plan's inventory missed** — the plan's grep had excluded `tools/claude-time/` and so never saw references living elsewhere. The consequential one was `arch.md:266`, a durable doc asserting in present tense that install creates those symlinks — the exact "doc claim must match what exists at commit time" failure this repo's own CLAUDE.md warns about. Unplanned bonus: Phase 7's `INTENTIONAL_DIFFS` went **empty**, so all 10 hook events are now diffed exactly — strictly *more* drift coverage than before retirement.

## Closure Notice

**Requester = Claudesk (a sibling repo), relayed by the operator.** Formal reply written to [`HANDOFF-REPLY-to-claudesk-2026-07-29.md`](../../../HANDOFF-REPLY-to-claudesk-2026-07-29.md) — Claudesk explicitly asked to be pinged when this landed.

> **Closure notice:** The `claude-time` retirement is complete. `tools/claude-time/` is deleted from this repo (32 files) and `install.sh` no longer installs it in any form, so a fresh install registers no second time-tracking hook. Verify by running `./install.sh` against a throwaway `$HOME` — zero `claude-time` artifacts are created; `uninstall.sh` still reclaims pre-retirement installs' dangling links, so old installs are not stranded. Claudesk's WP3.5a can resume from its spec step.

## Current Node
- **Path:** Task > close (complete)
- **Active scope:** COMPLETED — archived
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->

(none — no new work surfaced. The two claude-time SURFACE items at `workflow-system/state/backlog.md:247-248` sit in the `## Buried` section and were deliberately left untouched: buried is a different lifecycle from resolved, so the delete-on-resolve rule does not fire on them.)
