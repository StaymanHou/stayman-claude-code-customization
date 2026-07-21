---
workflow: task
state: act (complete)
drive_mode: autopilot
created: 2026-06-10
surface: SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT
---

# Task: Phase 9b — cheat-sheet vs AGENTS.md drift check

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-06-10

## Problem Statement

`tests/check-structure.sh` Phase 9 asserts the per-skill cheat-sheet block exists (heading + `Hard rule for AUTO exits` + 4-mode header row) in each of 8 feature SKILL.md files, but does NOT assert that the per-skill table **values** match the canonical pause-policy table in `agents/feature-workflow/AGENTS.md`. If AGENTS.md flips a transition's policy (e.g. PAUSE→AUTO in Mode 3), the 8 cheat-sheets can silently keep claiming the old value.

## Context

- **Canonical table:** `agents/feature-workflow/AGENTS.md` lines 146–166 (the `### Pause policy by drive mode` markdown table).
- **8 per-skill cheat-sheets** (already pinned by Phase 9):
  `skills/feature-{spec,research,plan,build,verify-auto,verify-self,verify-human,verify-codify}/SKILL.md`
- **Existing Phase 9 pin** at `tests/check-structure.sh:1098–1141` — 24 PASSes today (8 files × 3 grep assertions). This task adds a 4th assertion per file (= +8 PASSes) for a total of 32 PASSes from Phase 9 after this task ships.
- **Parser quirks to handle:**
  - Some rows in AGENTS.md use `**PAUSE**` (markdown-bold) where the per-skill rows use plain `PAUSE` — the comparison must strip `**` decoration before matching.
  - Some rows append parenthetical commentary: `AUTO (chain into verify-human, which itself PAUSEs)`, `AUTO — **skip verify-human entirely**, chain directly to ...`, `PAUSE (await human) — or AUTO-SKIP when ...`. The parser must extract the **first policy token** (`AUTO|PAUSE|SKIP|AUTO-SKIP`) from each cell — everything after the first whitespace/punctuation is commentary.
  - The `Mode 3` cell of verify-human's entry row uses `**PAUSE** (await human) — or **AUTO-SKIP** when` — both AGENTS.md and the SKILL.md state this same dual-value. The parser must accept either single token OR a `PAUSE/AUTO-SKIP` pair as a single canonical value.
  - Per-skill rows are keyed by transition (e.g. `F8 (build → verify-auto)`); AGENTS.md rows are keyed by **skill name OR transition family** (e.g. `feature-build`, `Back-loops (F6, F9, F9b, F12, F14, F23, F24)`, `SURFACE F25 (note-and-continue)`). The mapping is many-to-one in places — multiple per-skill transition rows can map to one AGENTS.md row (e.g. all 4 back-loop transitions in build map to AGENTS.md's `Back-loops` row).
- **Mapping table (per-skill row → AGENTS.md row):**
  | SKILL.md (caller, transition prefix) | AGENTS.md row key |
  |---|---|
  | feature-spec / F4 (forward), F3 | `feature-spec` |
  | feature-research / F5, F6 | `feature-research`; F6 → `Back-loops` |
  | feature-plan / F7 | `feature-plan` |
  | feature-build / F8 | `feature-build` |
  | feature-build / F9b, F23 | `Back-loops` |
  | feature-build / F22 | `REDIRECT (F22)` |
  | feature-build / F25 | `SURFACE F25 (note-and-continue)` |
  | feature-build / F26 | `SURFACE F26 (pause-and-escalate)` |
  | feature-build / F27 | (NOT in AGENTS.md table — interrupt; skip from comparison) |
  | feature-verify-auto / F10 | `feature-verify-auto` |
  | feature-verify-auto / F9 | `Back-loops` |
  | feature-verify-self / F10b | `feature-verify-self` |
  | feature-verify-self / F9b | `Back-loops` |
  | feature-verify-human / (entry / Skill invocation) | `feature-verify-human` |
  | feature-verify-human / F13, F11 | `feature-verify-human` |
  | feature-verify-human / F12 | `Back-loops` |
  | feature-verify-codify / F14 | `Back-loops` |
  | feature-verify-codify / F15, F16 | `feature-verify-codify` |
- **Implementation approach:** Single Python heredoc inside `tests/check-structure.sh` Phase 9 (after the existing 3 grep_check assertions per file). Python reads both source files, parses the markdown tables, normalizes values (strip `**`, take first policy token), and emits one `check ... pass|fail` line per per-skill row that has a canonical counterpart. Bash captures Python output and feeds it through the existing `check` helper.
  - **Why Python, not awk:** the value normalization (strip bold + strip parenthetical commentary + handle dual-PAUSE/AUTO-SKIP) is awkward in awk. Python is already used elsewhere in this script (Phase 1, Phase 7) so the dependency is established.
  - **Where to insert:** end of the existing `for f in PAUSE_POLICY_FILES` loop (after the 3 grep_checks), OR as a single block after the loop. Single block is cleaner — runs once, prints N PASS/FAIL lines.
- **Acceptance:** Running `./tests/run-tests.sh ...` wait that's the behavioral suite. The acceptance check for THIS task is `./tests/check-structure.sh` — it should grow from 150 PASS to 158+ PASS (depending on exact mapping coverage). FAIL count must remain 0.

## Work Tree

- [x] T1 Author the Python parser inside `tests/check-structure.sh` Phase 9: parses AGENTS.md's pause-policy table into a dict keyed by row name; parses each of 8 SKILL.md cheat-sheet tables; emits `PASS\t<desc>` or `FAIL\t<desc>\t<detail>` lines on stdout. Includes the per-skill-row → AGENTS.md-row mapping from the Context table above as a static dict literal in the Python block. Skip rows that have no canonical counterpart (e.g. F27 incident interrupt) without emitting any PASS/FAIL.
- [x] T2 Wire the Python output into the bash `check` helper: read line-by-line, dispatch each `PASS` / `FAIL` through the existing `check "$desc" "pass|fail" "$detail"` function so PASS/FAIL counts update correctly and the summary section formats consistently.
- [x] T3 Run `./tests/check-structure.sh` end-to-end. Confirm PASS count grew (was 150 at last observation per `.session.md`); confirm FAIL = 0; eyeball the new PASS lines for sensible row names. **Result:** 175 PASS / 0 FAIL (+25 from baseline of 150 — 1 parse-PASS + 24 per-row matches across 8 SKILL files).
- [x] T4 Drift bite-test: temporarily edit `agents/feature-workflow/AGENTS.md` to flip ONE policy value (e.g. change Mode 3 for `feature-plan` from `AUTO` to `**PAUSE**`); re-run `./tests/check-structure.sh`; confirm exactly the expected SKILL.md row's check FAILs with a useful detail message (names which row in which file, expected vs actual); revert the AGENTS.md edit; re-run; confirm back to all-PASS. **Result:** flipping `feature-plan` Mode 3 AUTO→PAUSE in AGENTS.md surfaced 2 FAILs (exactly the 2 feature-plan rows, both naming Mode 3, "expected 'pause' (from AGENTS.md), got 'auto' (from SKILL.md)"); revert returned to 175/175 PASS.
- [x] T5 Update the Phase 9 section-header comment in `tests/check-structure.sh` (line 1078–1097) to describe the new drift assertion alongside the existing 3 presence assertions.

## Current Node

- **Path:** Task > all complete
- **Active scope:** all complete
- **Blocked:** none
- **Open discoveries:** 1 — non-blocker; logged below

## Discoveries

<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[SURFACED-2026-06-10] T1 — Plan-time row-label inspection should include literal-string capture, not just key-name extraction. The plan's row-mapping table guessed plain skill names (`feature-spec`) as the AGENTS.md row keys, but the actual keys are backtick-wrapped (`` `feature-spec` ``). The first run of check-structure.sh surfaced 16 FAILs for "AGENTS.md has no row 'feature-spec'", trivially fixed by inspecting the parsed dict output once. Non-blocker — caught at T3 with a 1-minute fix-and-re-run loop. Worth noting as another instance of the "plan-time grep needs literal-string capture" family of misses (analogous to the literal-payload-object / array-length-add / function-signature subcases in CLAUDE.md's plan-time downstream-contract-impacts grep convention).

## Retrospect

- **What changed in our understanding:** The verify-human cheat-sheet has a structural asymmetry vs. the other 7 SKILL files — its exit-transition rows (F13, F11-confirmed, F11-AUTO-SKIP) describe orchestrator behavior AFTER the human has already responded to the entry pause; AGENTS.md has no canonical row that maps to these. The clean resolution is to skip them from comparison (mark `None` in the mapping) rather than try to wedge them into the skill-invocation row's values. The other 7 files don't have this issue because their exit rows either (a) use the `(pause already taken at entry)` sentinel that semantically equals PAUSE, or (b) describe a transition whose canonical value coincidentally matches the skill's invocation value.
- **Assumptions that held:** Plan's expected PASS-count delta range ("150 → 158+") was conservative; actual was +25 (175). The static row-mapping dict was the right shape — many-to-one mapping for back-loops + SURFACE + REDIRECT worked first try once the row-key string was corrected.
- **Assumptions that were wrong:** (1) Plan assumed AGENTS.md skill-row keys are plain `feature-spec`; actual is backtick-wrapped `` `feature-spec` ``. Caught in 1 minute by dumping the parsed dict. Logged as a discovery — same family as the "plan-time downstream-contract-impacts grep needs literal-string capture" convention in CLAUDE.md. (2) Plan assumed verify-human's exit rows would map cleanly to the same canonical row as its entry; reality is the exit rows describe a different semantic level (post-pause chaining) with no AGENTS.md counterpart. Resolved by marking those rows `None` in the mapping with a comment explaining why.
- **Approach delta:** Implementation matched plan's intent exactly — Python heredoc inside Phase 9, bash dispatch via existing `check` helper. Plan's T1+T2 collapsed into a single edit (the Python block and the bash loop are inseparable). T3 surfaced both assumption misses, both fixed in 2 edits totaling ~10 minutes of investigation+fix. T4 bite-test passed first try with a useful failure detail ("Mode 3", "expected 'pause'", "got 'auto'", names both files). T5 was the planned single-paragraph comment update.
