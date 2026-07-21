---
workflow: feature
state: ship (complete)
created: 2026-06-09
drive_mode: autopilot
---

# Feature: check-structure-sigterm-propagation

**Workflow:** feature
**State:** ship (complete) 2026-06-09 — both phases shipped; runtime 240s → 16s; orphan-child surface eliminated; 4 regression pins added
**Created:** 2026-06-09

## Problem Statement

`tests/check-structure.sh` Phase 1 invokes `./tests/run-tests.sh --dry-run` (line 795) inside command substitution `total=$(./tests/run-tests.sh --dry-run | ...)` just to count scenarios for the "Scenario count ≥ 88" assertion. This invocation has two costs: (1) it takes ~240s — the bulk of `check-structure.sh`'s 4-minute runtime — exceeding the Bash tool's default 2-min timeout, which makes the script unsafe to invoke without an explicit `timeout: 408000` parameter; (2) the subshell that runs the substitution is a sibling, not a descendant, of `check-structure.sh`, so when the parent script is killed (user cancel, harness timeout, SIGTERM), no trap inside the script can reliably reach the `run-tests.sh` process tree — the children orphan, race against subsequent re-invocations on shared `tests/results/` state, and produce the silent indefinite-hang pattern observed 2026-06-07 (required `pkill -f run-tests.sh` to clear).

**Two prior build attempts** (described in `## Discoveries`) tried to fix this via trap-based propagation — both failed because the process tree topology makes `pgrep -P $$`-style discipline structurally incapable of reaching the orphan siblings.

**Research spike (2026-06-09)** validated a strictly better fix: replace the `run-tests.sh --dry-run` subprocess invocation entirely with a ~10-line inlined Python block that walks `tests/scenarios/*.yaml` and counts scenarios directly. This eliminates both costs at once — the ~240s collapses to ~50ms (the run is bounded by file I/O), and the orphan-child surface disappears (no subprocess = no PID to manage). Verified that the count matches: `run-tests.sh` increments `TOTAL` once per scenario after filters (line 148); with no flags, every scenario passes filters; total = sum across the 6 YAMLs = 139.

**Filename caveat:** The feature is named `check-structure-sigterm-propagation` from the original P2 entry. The revised approach makes SIGTERM-propagation *unnecessary* rather than implementing it. Keeping the filename to preserve git/WIP-archive history continuity; the actual scope is "eliminate the orphan-child surface AND drop runtime from 240s to <30s by removing the dry-run subprocess invocation."

## Work Tree

- [x] Phase 1: Replace dry-run subprocess with inlined Python YAML count + remove dead trap
  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` exits 0 on a clean run with the same overall pass-count summary as before (no regression to other Phase checks)
  - CLI: `./tests/check-structure.sh` output contains exactly the line `  [PASS] Scenario count ≥ 88 (139 registered)` (or whatever the live total is, ≥88 — the equivalent line from before, just sourced from Python instead of the subprocess)
  - CLI: `time ./tests/check-structure.sh` real-time completes in under 30s wall-clock (down from ~240s baseline)
  - CLI: starting `./tests/check-structure.sh` in the background and concurrently `pgrep -f 'run-tests.sh'` returns no results at any sample point during the run — no subprocess is spawned at all
  - CLI: `grep -c '_kill_descendants' tests/check-structure.sh` returns 0 — the dead recursive-walker function is removed
  - CLI: `grep -c '^trap ' tests/check-structure.sh` returns 0 — the dead trap is removed (no trap needed in a no-subprocess world)
  - [x] P1.1 Replaced line 780 of `tests/check-structure.sh` (the `total=$(./tests/run-tests.sh --dry-run | ...)` command substitution) with an inlined `python3 - <<'PYEOF'` block reading `tests/scenarios/*.yaml`, summing `len(data.get('scenarios', []))`, printing the total. Bash captures via command-substitution; `|| echo 0` preserves the original fallback shape. Verified: returns 139 in isolation, ≥88. Expanded the surrounding comment block to record WHY (subprocess invocation took ~240s, see backlog SURFACE-ID) and to record the counting-semantics-equivalence proof (`TOTAL` increments per-scenario-after-filtering in run-tests.sh:148; with no flags, every scenario passes filtering).
  - [x] P1.2 Removed the `_kill_descendants()` function and `trap '_kill_descendants $$' EXIT INT TERM` line installed during the prior failed builds. Left `set -euo pipefail` intact. Single coherent edit alongside P1.1.
  - [x] verify-auto
  - [x] verify-self  <!-- PASS — all 6 outcomes confirmed 2026-06-09: (1) 134 PASS / 1 FAIL where the FAIL is pre-existing P4 settings-drift (unchanged), (2) `[PASS] Scenario count ≥ 88 (139 registered)` line present, (3) `time` shows 16.0s wall-clock (well under 30s target, down from ~240s baseline), (4) `pgrep -f 'run-tests.sh'` empty throughout the run, (5) 0 _kill_descendants references, (6) 0 ^trap directives -->
  - [x] verify-human  <!-- approved 2026-06-09 (autopilot, 3 judgment leaves all [x]): P1.verify-human.1 code-review of python YAML block, P1.verify-human.2 ack pre-existing P4 settings-drift FAIL remains, P1.verify-human.3 dead-trap removal acceptable -->
    - [x] P1.verify-human.1 spot-check inlined python YAML block at lines 779-802 — approved
    - [x] P1.verify-human.2 ack pre-existing P4 settings-fixture FAIL remains (P4 deferred to own item) — approved
    - [x] P1.verify-human.3 dead _kill_descendants + trap removal acceptable — approved
  - [x] verify-codify  <!-- 3 negative+positive pins added to tests/check-structure.sh Phase 1: forbid the dry-run-subprocess form (with [s] char-class regex trick to avoid self-match), forbid the failed walker helper, require the inlined python3 heredoc. All 3 sanity-checked bidirectionally: pin n=0 in clean source, n=1 in regression-mutated source. Full sweep: 137 PASS / 1 FAIL (only pre-existing P4 settings drift). Hit 2 triage entries during pin design (both HIGH-confidence Obsolete-test, auto-fixed): self-matching regex bug + pipefail interaction with `grep -c ... || echo 0`. See ## Test Triage. -->

- [x] Phase 2: Update runtimes.md to reflect the new fast runtime
  **Observable outcomes:**
  - CLI: `grep -A2 '^## ./tests/check-structure.sh' runtimes.md` shows `**Last:** <Ns> (2026-06-09)` where N is the new measured runtime (~5–30s) and `**Use timeout:** <NEW-VAL>` where NEW-VAL is `ceil(N * 1.5 + 60) * 1000`, clamped to 600000
  - CLI: `runtimes.md` `**History:**` section preserves the prior `240s — 2026-06-07` entry and prepends the new observation
  - CLI: `runtimes.md` frontmatter `updated:` line is `2026-06-09`
  - [x] P2.1 Edited runtimes.md: bumped `Last: ~16s (2026-06-09)`, recomputed `Use timeout: 84000` (ceil(16*1.5+60)*1000), prepended `History:` bullet with `post-dry-run-bypass` comment, frontmatter `updated:` already 2026-06-09. Runtime measurement source: Phase 1 verify-self wall-clock measurement (16.0s real time via `time ./tests/check-structure.sh`).
  - [x] verify-auto  <!-- PASS: YAML frontmatter parses; new entry has correct **Last:** ~16s, **Use timeout:** 84000, and prepended History bullet -->
  - [x] verify-self  <!-- PASS: 3 outcomes confirmed — Last line + Use timeout 84000 (= ceil(16*1.5+60)*1000, well under 600000 cap); History preserves both prior 232s and 360s orphan-hang entries; frontmatter updated: 2026-06-09 -->
  - [x] verify-human  <!-- AUTO-SKIPPED 2026-06-09 (Mode 3 auto-skip gate clean): (a) drive_mode=autopilot, (b) Phase 2 verify-self all-PASS, (c) no integration boundary (runtimes.md is an isolated tracking doc), (d) no Observable Outcome cites an external consuming surface — runtimes.md is the artifact itself, consumed by a discipline (global Long-running-commands rule), not by a named system component. F11 emitted with no human prompt. -->
  - [x] verify-codify  <!-- PASS: added 1 new pin to tests/check-structure.sh — `runtimes.md has at least one **Use timeout:** entry` (the load-bearing field). Caught a duplicate-check mistake during pin write (the shape: frontmatter pin already existed at Phase 3 line ~114, removed the duplicate). Pin sanity-checked: 2 in clean state, 0 in mutated state. Full sweep: 138 PASS / 1 FAIL (pre-existing P4 settings drift only). -->

## Current Node
- **Path:** Feature > ship
- **Active scope:** ship (all 2 phases complete; verify-codify added 1 new pin to check-structure.sh for runtimes.md `**Use timeout:**` field)
- **Blocked:** none
- **Unvisited:** finalize
- **Open discoveries:** P4 settings-fixture-drift fail is pre-existing and unchanged (not introduced by this feature)

## Test Triage — new negative pins (verify-codify, 2026-06-09)

Both new negative pins (`does NOT invoke run-tests.sh --dry-run` and `does NOT define _kill_descendants`) FAILed on first run because the pin implementation itself contains the literal string being grepped for. The grep counts its own lines.

### "does NOT invoke './tests/run-tests.sh --dry-run' as subprocess"
- **Classification:** Obsolete test (HIGH confidence — the test's regex matches its own implementation lines, not a code regression)
- **Confidence:** high
- **Evidence:** The line `non_comment_dryrun=$(grep -cE '^[[:space:]]*[^#[:space:]].*run-tests\.sh --dry-run' tests/check-structure.sh ...)` contains the literal `run-tests.sh --dry-run` in the grep pattern string. The regex `[^#[:space:]].*run-tests\.sh --dry-run` matches this line because the first non-whitespace char is `n` (in `non_comment_dryrun`), not `#`.
- **Action:** Refine the regex to exclude lines where the literal pattern appears inside single-quoted strings (which are the grep's own arguments). Simpler approach: anchor to the *invocation form* (`./tests/run-tests.sh --dry-run` with the leading `./`), not the bare name, since the actual problematic code form is `total=$(./tests/run-tests.sh --dry-run ...)`. The string `./tests/run-tests.sh --dry-run` (with leading `./`) is no longer present in the file after the fix — confirmed by grep.

### "does NOT define _kill_descendants helper"
- **Classification:** Obsolete test (HIGH confidence — same root cause)
- **Confidence:** high
- **Evidence:** Pin implementation contains the literal `_kill_descendants` in 3 places: the bash variable name `kill_descendants_refs`, the check description string, and the FAIL detail message string. `grep -c '_kill_descendants'` counts all 3.
- **Action:** Refine to `grep -cE '_kill_descendants[[:space:]]*\(' tests/check-structure.sh` — only matches actual function calls/definitions (`name(`), not bare references in strings or variable names.

Auto-fixing both per HIGH-confidence Obsolete-test classification.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-06-09] Phase 1 verify-self → P1.1 (plan) — `pkill -P $$` only kills DIRECT children, but `run-tests.sh --dry-run` spawns a multi-level process tree (run-tests.sh itself plus its own subshell descendants). Parent SIGTERM did NOT clean up the deeper descendants — Outcome 2 FAILED-BLOCKING with 3 surviving processes after SIGTERM + 2s wait. The plan's trade-off ("narrow form, fewer collateral-damage surfaces, sufficient for the orphan child case") was based on a wrong assumption about process-tree depth.

[SURFACED-2026-06-09] Phase 1 verify-self (re-verify after F9b) → P1.1 (plan, deeper revision) — recursive walker `_kill_descendants $$` was ALSO insufficient. Root cause: in bash command substitution `total=$(./tests/run-tests.sh ...)`, the subshell forked to run the substitution becomes a child of the WRAPPER bash (the parent of our script), NOT a child of our script. So `pgrep -P $$` returns nothing — there are zero direct descendants of the trap's PID. All run-tests.sh processes are siblings of our script under a shared PGID. Diagnostic confirmed: script PID 37304 had PPID 37302, while the command-substitution subshell (PID 43298) ALSO had PPID 37302 — they're siblings, not parent/child. Recursive walking from `$$` therefore can't reach them.

[SURFACED-2026-06-09] Phase 1 research spike → recommendation: **Design B (bypass entirely) is strictly better than Design A (trap-based)**. Design A (background-PID + pkill fallback) was verified to work in sandbox. Design B (Python YAML scenario count) was verified to work AND dramatically simpler: replaces a 240s subprocess invocation with a ~50ms file walk, eliminates the orphan-child surface entirely, fewer LoC, simpler mental model. The P2 backlog entry's "Optional: profile run-tests.sh --dry-run to find why scenario enumeration takes >5 min — if it's reading every fixture for each scenario, an index file would cut the cost" — Design B IS that optional-cost-fix. The revised plan implements Design B in Phase 1.

## Retrospect

- **What changed in our understanding:** Bash command-substitution subshells are *siblings* of the invoking script (under the same wrapper bash PPID), not *descendants*. This means no trap walking from `$$` — neither `pkill -P $$` nor a recursive `_kill_descendants $$` — can ever reach the subshell or its children. The orphan-child problem we set out to fix was structurally unfixable by the original plan's approach. Required two failed builds to learn empirically.

- **Assumptions that held:**
  - The orphan-process pattern was real and worth fixing (the 2026-06-07 incident burned ~10 min).
  - `run-tests.sh --dry-run` was a slow subprocess invocation (~240s) that didn't need to run from `check-structure.sh` — the YAML files are parseable in ~50ms.
  - The runtime registry (`runtimes.md`) was the right home for the new runtime measurement.

- **Assumptions that were wrong:**
  - **First wrong assumption:** That `pkill -P $$` would catch the dry-run process tree (it doesn't — the tree is multi-level *and* not a descendant of `$$`).
  - **Second wrong assumption:** That a recursive walker (`_kill_descendants $$`) would catch it (same root cause — wrong about the process-tree topology).
  - **Third wrong assumption (caught in research, not build):** That a simple background-PID + `pkill -f` would be the clean fix. Research showed Design B (bypass entirely) was strictly better — drops runtime AND eliminates the orphan-child surface in one move.

- **Approach delta:** The first plan said "one trap line + a comment in `check-structure.sh`." Reality required: 1 plan revision (F23), 1 research spike (F22-from-plan-as-redirect), a new 2-phase plan that REPLACES the subprocess invocation rather than managing its side effects, and 4 regression pins. The user's intervention at "tackle P2 in autopilot" → option-3 redirect to research was load-bearing — without it, this would have been a 3rd-iteration trap-tweaking exercise rather than a strict improvement.

- **Codify-time triage entries:** 2 caught during Phase 1 verify-codify (both HIGH-confidence Obsolete-test): self-matching regex bug in negative pin, `grep -c ... || echo 0` interaction with `pipefail`. 1 mistake during Phase 2 verify-codify: duplicate `runtimes.md` shape pin (already existed at Phase 3 line ~114). All caught and fixed in-state without back-loops.

## Downstream contract impacts

- **`tests/check-structure.sh`** is invoked by `feature-verify-codify` and `feature-ship` skill procedures. The change does NOT alter exit-code semantics (still exits 0 on pass, 1 on fail) or output shape (the `[PASS]/[FAIL]` summary lines for each Phase are unchanged). The "Scenario count" line text is identical except for sourcing the count from Python instead of subprocess output. No downstream skill/test contracts assert against the script's internals.
- **`runtimes.md`** is the canonical destination for the runtime change — Phase 2 edits it. The global Long-running-commands rule reads this file before invoking tracked commands; updating it is the contract-migration that keeps that rule honest for the new fast runtime.
- **Project CLAUDE.md** — no edit needed. The Commands section already describes `./tests/check-structure.sh` at a contract level ("Structural checks: argument-hints, CLAUDE.md content, symlinks, YAML validity"); the Python-vs-subprocess implementation choice is below that contract.
- **`tests/run-tests.sh`** — unchanged. The `--dry-run` mode itself is preserved (still useful for human debugging via `./tests/run-tests.sh --dry-run | less`), just not called from `check-structure.sh` anymore.
- **No test scenarios in `tests/scenarios/*.yaml` assert against this behavior** — confirmed via grep. The change is internal to `check-structure.sh`.
- **The recursive-walker function** (`_kill_descendants` + the `trap` line, lines 11–22 of the currently-modified `check-structure.sh`) is dead code from the failed builds; Phase 1's P1.2 removes it. No external code references it.
