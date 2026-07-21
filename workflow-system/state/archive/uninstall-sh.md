# Feature: Standalone uninstall.sh (WP4 / Milestone 8)

**Workflow:** feature
**State:** COMPLETED 2026-07-21 — shipped (74cbb7c), reviewed, refactored, finalized
**Completion date:** 2026-07-21
**Created:** 2026-07-21
**drive_mode:** autopilot
**WBS:** WP4 — Milestone 8 (Claudesk Handoff Cycle). Resolves `SURFACE-2026-07-20-CLAUDESK-STANDALONE-UNINSTALL`.

## Problem Statement

`install.sh` is the canonical, idempotent setup for this workflow system — it symlinks skills/agents/hooks/claude-time artifacts into `~/.claude/` and injects a marker-delimited block into `~/.claude/CLAUDE.md`. There is **no reversal**. Per Claudesk's handoff (`SURFACE-2026-07-20-CLAUDESK-STANDALONE-UNINSTALL`), the "try the workflow system + Claudesk together, then cleanly back out" story requires a **standalone** `uninstall.sh` that works with **zero Claudesk dependency** and leaves **no residue**. Per WBS AD-2: a bash `uninstall.sh` that symmetrically and *defensively* reverses each install action, reusing install's `SOURCE_DIR`/`TARGET_DIR` derivation and idempotency/safety contract. Defensive invariants: only `rm` a symlink when it exists AND resolves *into this repo*; excise only the marker-delimited CLAUDE.md block via the same `awk` block-delete (back up first; never delete the file wholesale); remove the per-project memory *symlink* only (never the real store — reuse `tools/memory-link/lib-slug.sh`); only *print* the settings.json perms reminder (install only prints, so uninstall symmetrically only prints). WP4.5's `install → uninstall → re-install` round-trip is the AD-2 verification target and captures the install/uninstall command copy the M12 return contract (WP8) needs.

**Note on the SURFACE wording vs. WBS:** the SURFACE says "reverses ... the settings.json hook registration," but `install.sh` never registers hooks in settings.json — it only *prints* a perms reminder. The WBS (AD-2, more recent + authoritative) resolves this: uninstall symmetrically only *prints*. We follow the WBS.

## Reversal map (install action → uninstall action)

| install.sh action | uninstall.sh reversal | Defensive guard |
|---|---|---|
| `ln -s` each `skills/<name>` → `~/.claude/skills/<name>` | `rm` the link | link exists AND `readlink -f` resolves under `$SOURCE_DIR` |
| `ln -s` each `agents/<name>` → `~/.claude/agents/<name>` | `rm` the link | same into-repo guard |
| `ln -s` each `hooks/<file>` → `~/.claude/hooks/<file>` | `rm` the link | same into-repo guard |
| `ln -s` `tools/claude-time/hook.pl` → `~/.claude/hooks/claude-time-hook.pl` | `rm` the link | same into-repo guard |
| `ln -s` `tools/claude-time/claude-time` → `~/.claude/bin/claude-time` | `rm` the link | same into-repo guard |
| inject marker block into `~/.claude/CLAUDE.md` | `awk` block-delete the `<!-- BEGIN/END claude-workflow-system -->` block; back up to `.bak` first | file exists AND contains BEGIN marker; if file becomes empty after delete, leave an empty file (don't `rm` — user may re-add content) |
| (per-project, NOT by install.sh) memory symlink `~/.claude/projects/<slug>/memory` → `<proj>/.claude/memory` | `rm` the symlink only | path is a symlink (`-L`) AND resolves to `<proj>/.claude/memory`; NEVER touch the real store |
| *print* settings.json perms reminder | *print* the same perms as "you may want to remove these" | print-only — never edit settings.json |

## Work Tree

- [x] Phase 1: Core script — symlink reversal + CLAUDE.md block excise  <!-- status: [x] -->
  **Observable outcomes:**
  - CLI: `bash -n uninstall.sh` exits 0 (syntax valid); `uninstall.sh --help` exits 0 and stdout documents `--dry-run` and `<proj-dir>`.
  - CLI: `uninstall.sh --dry-run` against a fake-`$HOME` sandbox (install.sh already run into it) exits 0 and prints planned `[remove]` lines for every skill/agent/hook/claude-time link, changing NOTHING on disk (links still present after).
  - CLI: a real `uninstall.sh` run against a fake-`$HOME` sandbox removes every into-repo symlink under `~/.claude/{skills,agents,hooks,bin}` AND deletes only the marker-delimited block from `~/.claude/CLAUDE.md` (a pre-existing non-block line survives; a `.bak` backup is written).
  - CLI: the into-repo guard holds — a foreign symlink under `~/.claude/skills/` (resolving OUTSIDE the repo) is left untouched (printed `[skip]`), and a real (non-symlink) file at a link path is left untouched (`[skip]`).
  - [x] P1.1 Scaffold `uninstall.sh`: shebang, `set -euo pipefail`, `SOURCE_DIR`/`TARGET_DIR` derivation identical to install.sh, arg-parse (`--dry-run`, `-h/--help`, usage()) mirroring migrate-doc-layout.sh's shape  <!-- status: [x] -->
  - [x] P1.2 Implement the into-repo symlink-removal helper (`remove_link`): `-L` check → `readlink -f` resolves under `$SOURCE_DIR` → `[remove]`/dry-run print; else `[skip]` (foreign link or real file). Apply across skills, agents, hooks loops + the 2 claude-time artifacts  <!-- status: [x] -->
  - [x] P1.3 Implement CLAUDE.md block excise: guard (file exists + BEGIN marker present) → `cp` to `.bak` → `awk` block-delete (same BEGIN/END markers install uses) → write back; dry-run prints intent only  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — bash -n clean, executable, --help exits 0 + documents flags -->
  - [x] verify-self  <!-- status: [x] — subagent: 4/4 Observable Outcomes PASS (no integration boundary); guard fired skip-count=2 -->
  - [x] verify-human  <!-- status: [x] — AUTO-SKIP (autopilot + no boundary + verify-self all-PASS); isolated new artifact uninstall.sh only -->
  - [x] verify-codify  <!-- status: [x] — no integration boundary; full check-structure.sh suite 420/0 (no regression from adding uninstall.sh); dedicated E2E harness deferred to P3.1 (whole-feature test home per WBS) -->

- [x] Phase 2: Per-project memory symlink reversal + print-only settings reminder  <!-- status: [x]; depends on Phase 1 -->
  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — WP4.3/4.4 are explicit AD-2 deliverables; SURFACE-2026-07-20-CLAUDESK-STANDALONE-UNINSTALL names "per-project memory symlink" + "no residue" directly.
  - Requirements unchanged: yes — reversal map in this WIP is unchanged; Phase 1 confirmed install.sh's setup surface.
  - Solution still feasible: yes — `tools/memory-link/lib-slug.sh` provides the realpath-safe slug helpers Phase 2 needs; sourcing pattern proven.
  - No superior alternative discovered: yes — sourcing lib-slug.sh is the established convention (memory-link feature); no reason to reimplement.
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: with a fake project whose `~/.claude/projects/<slug>/memory` is a symlink into `<proj>/.claude/memory`, a real uninstall run (passed the project dir) removes ONLY the symlink; the real store `<proj>/.claude/memory` and its files still exist afterward.
  - CLI: the memory guard holds — if `~/.claude/projects/<slug>/memory` is a *real directory* (not a symlink), it is left untouched and `[skip]` is printed; slug is realpath-derived via sourced `lib-slug.sh` (macOS `/private/tmp` footgun).
  - CLI: uninstall stdout contains a "settings.json — you may want to remove these permissions" section listing the same 4 perms install prints, and settings.json (if present in the sandbox) is byte-identical before/after (print-only, never edited).
  - [x] P2.1 Source `tools/memory-link/lib-slug.sh`; add memory-symlink reversal: compute `mlink_harness_memory_path <proj>`, `-L` guard + resolves-to-`mlink_repo_memory_path` guard → `rm` symlink only; `[skip]` otherwise. Memory reversal is per-project → gated behind an explicit project-dir argument (default: skip with a note that memory links are per-project)  <!-- status: [x] — --project gated; lib-slug.sh sourced lazily; readlink -f on both sides handles /private realpath -->
  - [x] P2.2 Add the print-only settings.json reminder block (symmetric to install.sh's closing echo) — phrased as "remove" instead of "ensure"; never touches the file  <!-- status: [x] — settings.json byte-identical confirmed (T6) -->
  - [x] verify-auto  <!-- status: [x] — bash -n clean, --help documents --project, lib-slug.sh sources+callable under set -euo pipefail, missing-project degrades to [skip] -->
  - [x] verify-self  <!-- status: [x] — subagent: 3/3 outcomes PASS + SAFETY PASS (outer HOME unchanged, real skills=41 untouched; env HOME=<sandbox> per-call, no export leak) -->
  - [x] verify-human  <!-- status: [x] — AUTO-SKIP (autopilot + no boundary + verify-self all-PASS); extends isolated uninstall.sh only. HOME-export hazard flagged for operator awareness. -->
  - [x] verify-codify  <!-- status: [x] — no integration boundary; check-structure.sh 420/0 (no regression + install.sh idempotence confirms live recovery); dedicated E2E harness codifying P1+P2 behaviors is P3.1 -->

- [x] Phase 3: Test suite + structural pin + WP4.5 round-trip & M12 command-copy capture  <!-- status: [x]; depends on Phase 2 -->
  **Relevance check (before Phase 3):**
  - Requester still needs this: yes — WP4.5 round-trip is the AD-2 verification target + a load-bearing M12 return-contract deliverable; the E2E harness + structural pin are the codify home for P1+P2.
  - Requirements unchanged: yes — plus a NEW hard constraint surfaced in Phase 1/2: the harness MUST scope HOME per-invocation (SURFACE-2026-07-21-UNINSTALL-TEST-HOME-EXPORT-HAZARD). This sharpens P3.1, doesn't change its intent.
  - Solution still feasible: yes — migrate-doc-layout's test/run-tests.sh is the proven template; add the env-HOME-per-call discipline.
  - No superior alternative discovered: yes — a real-script E2E harness against a fake-HOME sandbox is the right highest-level test; structural pin stays dry-run-only.
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: `tools/... test/run-tests.sh` (uninstall test harness) exits 0 with all assertions PASS, driving the REAL `uninstall.sh` against fake-`$HOME` sandboxes (mktemp isolation + trap cleanup + `--date`-style determinism, mirroring migrate-doc-layout's harness).
  - CLI: `tests/check-structure.sh` exits 0/0 with a NEW pin that `uninstall.sh` exists, is executable, passes `bash -n`, and `uninstall.sh --dry-run` exits 0 — and the pin NEVER performs a live (non-dry-run) uninstall inside check-structure (it would tear down the live `~/.claude/` symlinks).
  - CLI: the WP4.5 round-trip — install → uninstall → re-install against a fake-`$HOME` sandbox — leaves the sandbox in a state byte-equivalent to the first post-install state (idempotent, no residue), verified as a test-harness assertion.
  - [x] P3.1 Write `tools/uninstall/test/run-tests.sh` mirroring migrate-doc-layout's harness: fake-`$HOME` sandbox, run install.sh into it, assert uninstall behaviors (remove/skip/guard/dry-run/help/block-excise/memory-symlink/round-trip). TOOL-DIR DECISION: `uninstall.sh` stays at repo root (peer of install.sh, so check-structure Phase 4 idiom applies); test harness + README live in `tools/uninstall/`. 40/40 assertions PASS incl. SAFETY (env HOME per-call, outer $HOME unchanged)  <!-- status: [x] -->
  - [x] P3.2 Add the `check-structure.sh` structural pin (exists + executable + `bash -n` + `--help` exit 0 + `--dry-run` exit 0 + live-install-intact-after-dry-run; DRY-RUN ONLY). Placed after Phase 4 (install.sh) block for symmetry. 6 new pins, suite 420→426  <!-- status: [x] -->
  - [x] P3.3 WP4.5: install → uninstall → re-install round-trip verified (test group 7: 41→41 skills, 6→6 agents, 1 block); captured canonical install + uninstall command copy into `## Return Contract — M12 command copy`  <!-- status: [x] -->
  - [x] P3.4 Wrote `tools/uninstall/README.md` (usage, full safety-contract table, reversal map, exit codes, test-harness HOME-safety note)  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x] — harness + check-structure.sh parse clean; harness executable, README not; harness 40/40 + structure 426/0 confirmed at build -->
  - [x] verify-self  <!-- status: [x] — subagent: 3/3 PASS + SAFETY (harness 40/40, check-structure 426/0 w/ 6 uninstall pins, WP4.5 round-trip all PASS, live install 41 skills untouched) -->
  - [x] verify-human  <!-- status: [x] — human ran ./uninstall.sh --dry-run, inspected full output, approved "all good"; integration boundary (check-structure.sh 426/0) covered by verify-self -->
    - [x] P3.verify-human.1 integration-boundary: `./tests/check-structure.sh` runs green with the 6 new uninstall pins  <!-- status: [x] — 426/0 confirmed by verify-self subagent; human approved -->
    - [x] P3.verify-human.2 eyeball actual uninstall behavior via `--dry-run`  <!-- status: [x] — human ran it, output correct, approved -->
      <!-- Operator-observed copy nit during this eyeball: dry-run final line said "have been removed"; fixed in-place to a dry-run-accurate message (SHORTCUT below) -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->
  - [x] verify-codify  <!-- status: [x] — no test failures (no triage); integration boundary (check-structure.sh) covered; full suite check-structure 426/0 + uninstall harness 40/40; runtime registered -->

## Current Node
- **Path:** Feature > refactor (complete) > finalize
- **Active scope:** none — MAJOR + sibling MINOR fixed + re-verified (harness 45/45, check-structure 426/0); comment-ordering MINOR backlogged
- **Blocked:** none
- **Unvisited:** none — next is /feature-finalize
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->
- [SHORTCUT-2026-07-21] P1.2 — build-smoke confirmed the into-repo guard fires correctly for BOTH a foreign symlink at a real skill path ([skip] "points outside this repo") and a real dir at a real skill path ([skip] "not a symlink"); into-repo links removed, foreign+real preserved, CLAUDE.md block excised with .bak backup, personal content survived, idempotent re-run clean. Formal verification handled by verify-auto/self.
- [SHORTCUT-2026-07-21] P2.1/P2.2 — build-smoke 6/6: memory symlink removed only when it resolves to `<proj>/.claude/memory` (real store intact); guards skip a real-dir harness path and a foreign-target symlink; `readlink -f` on both sides correctly matches `/var` vs `/private/var` (macOS realpath footgun); no-`--project` skips memory entirely; settings.json byte-identical (print-only). Formal verification handled by verify-self.
- [SURFACED-2026-07-21] Phase 3 / P3.1 — SURFACE-2026-07-21-UNINSTALL-TEST-HOME-EXPORT-HAZARD (high): a build-smoke test's top-level `export HOME=<sandbox>` + real uninstall.sh run DAMAGED the live ~/.claude (41 skill + 6 agent links removed, CLAUDE.md block excised); recovered via idempotent install.sh re-run. The Phase-3 harness MUST scope HOME per-invocation (subshell+trap or `env HOME=... script`), NEVER export at top level, and assert outer $HOME unchanged. Logged to backlog.md. [RESOLVED IN-CYCLE: the shipped tools/uninstall/test/run-tests.sh uses `env HOME=<sandbox>` per-call + a SAFETY assertion that outer $HOME + live install are untouched.]
- [SHORTCUT-2026-07-21] P3.verify-human.2 — dry-run final line said "Workflow symlinks and the CLAUDE.md block have been removed" even in --dry-run (operator-observed at the verify-human eyeball). Fixed in-place to a DRY_RUN-conditional accurate message. Re-verified: `./uninstall.sh --dry-run | tail -1` shows the new wording, `bash -n` clean, harness re-run still 40/40. Trivial extension of the just-approved leaf; operator was looking at it.

## Return Contract — M12 command copy
<!-- Filled at P3.3 (WP4.5). Feeds WP8 (Milestone 12) return contract to Claudesk. -->

Canonical install/uninstall command copy for Claudesk's M10.9 invite + M11 onboarding
(WP8 aggregates this with the M7 settled-layout mapping + WP7 onboarding spec). `install.sh`
stays the single source of truth; Claudesk's invite *displays* these, never hardcodes them.

**Install (from the cloned repo root):**
```bash
./install.sh
```
- Idempotent — re-run any time to repair or refresh symlinks + the CLAUDE.md block.
- Sets up: per-skill + per-agent symlinks into `~/.claude/`, the claude-time hook.pl + CLI bin symlinks, and injects the marker-delimited workflow block into `~/.claude/CLAUDE.md`.
- Prints (does not edit) the `~/.claude/settings.json` permissions to add.

**Uninstall (from the cloned repo root):**
```bash
./uninstall.sh              # preview first with:  ./uninstall.sh --dry-run
```
- Reverses every install action defensively (into-repo-guarded symlink removal, block-only CLAUDE.md excise with backup, print-only settings reminder). Idempotent, zero Claudesk dependency, no residue.
- Optional per-project memory-symlink cleanup: `./uninstall.sh --project /path/to/consuming/project` (removes only the harness memory *symlink*, never the real store).

**Round-trip verified (WP4.5 / test group 7):** `install → uninstall → re-install` restores 41 skill links + 6 agent links + exactly 1 CLAUDE.md block — clean, idempotent, no residue.

**Docs:** `tools/uninstall/README.md` (usage, full safety contract, reversal map).

## Code-Quality Review — uninstall-sh

### Strengths
- Symmetry with `install.sh` is exact and deliberate — into-repo guard, marker-block handling, print-only settings.json posture each mirror a specific install action; header comment maps every reversal to its install counterpart.
- The into-repo guard (`remove_link`) is genuinely defensive: removes a symlink only when `readlink -f` resolves under `$SOURCE_DIR`, handles dangling-into-repo-link via raw-`readlink` fallback; foreign links + real files `[skip]`'d.
- Test harness drives the REAL install.sh+uninstall.sh against `env HOME=<sandbox>` per-call sandboxes + a dedicated outer-`$HOME`-unchanged assertion — encoded response to SURFACE-2026-07-21-UNINSTALL-TEST-HOME-EXPORT-HAZARD.
- Structural pins correctly scoped dry-run-only (a live uninstall inside check-structure would tear down Phase-4's just-verified symlinks) + post-dry-run "live install intact" assertion.
- Memory reversal reuses `tools/memory-link/lib-slug.sh` (realpath-safe slug), gated behind explicit `--project` opt-in.

### Issues
**CRITICAL**
- (none)

**MAJOR**
- [uninstall.sh:69-76] Naive arg parser `--project) PROJECT_DIR="${2:-}"; shift 2` with no validation that `$2` is a value vs the next flag. `./uninstall.sh --project --dry-run` assigns `PROJECT_DIR="--dry-run"`, leaves `DRY_RUN=0`, and performs a REAL unguarded uninstall (confirmed live: 45 `[remove]` lines, exit 0). A user reordering flags expecting a preview tears down their live install — the exact destructive outcome the safety contract exists to prevent. Harness misses it: every `--project` test passes a real path as the following token, so flag-order permutations are unexercised. — *Fix: treat a flag-shaped `--project` value as a usage error (exit 2).*

**MINOR**
- [uninstall.sh:72] `./uninstall.sh --project` with no following arg hits `shift 2` on one-element `$@`, exits 1 with NO diagnostic — inconsistent with the unknown-arg path (clear error + usage, exit 2). Missing `--project` value should get the same treatment.
- [uninstall.sh:90-120 vs 84-89] `remove_link` header comment enumerates outcomes "not present → [ok] … symlink … real file" but the code checks `-L` → `-e` → fallthrough `[ok]` (reverse). Harmless; comment ordering doesn't match read order.

### Assessment
Well-built, disciplined shell work advancing the M8 standalone-handoff goal. Install/uninstall symmetry is faithful, guards correct, HOME-isolation discipline turns a real near-miss into an encoded asserted invariant. The one blemish: the arg parser's naive `shift 2` undercuts the safety story at its most sensitive point (`--project --dry-run` silently escalates preview → real uninstall) and the test suite's fixed flag-ordering masks it — worth a small refactor rather than a defer. Everything else is minor polish.

### Disposition (Mode 3 / autopilot) — RESOLVED via refactor (F40)
Operator chose **refactor-now** for the MAJOR (confirmed live safety bug in a destructive tool).
- **MAJOR [FIXED]** uninstall.sh arg parser now rejects a missing OR flag-shaped `--project` value with a clear error + usage → exit 2 (mirrors the unknown-arg path). `./uninstall.sh --project --dry-run` now exits 2 with 0 `[remove]` lines (was: real uninstall). Verified live + harness.
- **MINOR (sibling, same arg surface) [FIXED]** `--project` with no value now exits 2 with a diagnostic (was: silent exit 1). Folded into the same guard.
- **MINOR (remove_link comment ordering) [BACKLOGGED]** → SURFACE-2026-07-21-QUALITY-UNINSTALL-REMOVE-LINK-COMMENT-ORDER in backlog-quality-findings.md (out of refactor scope; trivial doc polish).
- **Regression coverage:** harness +5 arg-safety assertions (40→45); `--project --dry-run` exit-2/no-removal + `--project` missing-value exit-2 now pinned. check-structure stays 426/0.

### If you disagree
Edit this section and mark a finding `[DISMISSED]` before `feature-finalize` archives the WIP.

## Retrospect
- **What changed in our understanding:** The single biggest surprise was a *test-method* hazard, not an implementation one — running the real `uninstall.sh` from a Bash-tool call that `export HOME=<sandbox>` at the top level briefly wiped the LIVE `~/.claude` (recovered via idempotent `install.sh`). This reframed the Phase-3 harness's load-bearing property from "test the reversal" to "test the reversal WITHOUT ever letting a HOME leak reach the real home" — encoded as `env HOME=<sandbox>` per-call + an outer-`$HOME`-unchanged assertion. Also confirmed: install.sh does NOT register hooks in settings.json (only prints perms), so the SURFACE's "settings.json hook registration" wording was reconciled to print-only per AD-2.
- **Assumptions that held:** install.sh's structure (skills/agents/hooks/claude-time loops + marker-block awk) mapped cleanly to a symmetric reversal; `tools/memory-link/lib-slug.sh` was the right realpath-safe slug source; the migrate-doc-layout test harness was a faithful template; the into-repo guard (`readlink -f` under `$SOURCE_DIR`) behaved exactly as designed for foreign links + real files.
- **Assumptions that were wrong:** (1) that build-smoke against a fake HOME was safe as written — the top-level `export HOME` leak was the counterexample. (2) that the arg parser's `--project) shift 2` was fine — the code-quality reviewer caught that `--project --dry-run` silently escalates a preview into a real uninstall (a confirmed-live safety bug in a *destructive* tool), fixed at refactor per operator's refactor-now call.
- **Approach delta:** 3-phase plan executed as designed (core script → memory/settings → tests+pin+M12). The two deltas were both quality-driven, not scope-driven: the in-cycle HOME-hazard SURFACE (resolved by the shipped harness) and the post-review refactor of the arg parser (+5 harness assertions). No phase was re-planned; no scope expanded.

## Closure
**Requester = operator** — closure notice for self-record.
**Feature complete:** the standalone `uninstall.sh` has shipped (WP4 / Milestone 8). It defensively reverses everything `install.sh` sets up — into-repo-guarded symlink removal, block-only `~/.claude/CLAUDE.md` excise (backup first), `--project`-gated memory-*symlink* removal (never the real store), and a print-only settings.json reminder — with zero Claudesk dependency and no residue. Verify: `./uninstall.sh --dry-run` (preview) then `./uninstall.sh`; the `install → uninstall → re-install` round-trip is asserted green in `tools/uninstall/test/run-tests.sh` (45/45).
