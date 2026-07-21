---
workflow: task
state: verify (complete)
created: 2026-06-13
docs-only: false
drive_mode: autopilot
---

# Task: Redirect feature-review-quality auto-backlog writes to dedicated file

**Workflow:** task
**State:** verify (complete)
**Created:** 2026-06-13

## Problem Statement
`feature-review-quality` auto-backlog writes (MAJOR Mode-3, MINOR Modes 2-3) currently land as individual `## SURFACE-<date>-QUALITY-<slug>` entries in `workflow/backlog.md`, accruing volume noise (5 entries per typical pass); redirect to `workflow/backlog-quality-findings.md` grouped by source feature with a single pointer entry in main `backlog.md`.

## Context
- **Write sites to change:** `skills/feature-review-quality/SKILL.md:161` (Case-B Mode-3 MAJOR) and `:164` (Case-C MINOR).
- **Informational reference to update:** `agents/code-quality-reviewer/AGENTS.md:18` ("or `workflow/backlog.md`" → also mention the dedicated file).
- **Canonical pointer-entry shape:** `workflow/backlog.md:9-13` (`## Code-quality findings — close-commit-discipline (2026-06-12)` block).
- **Canonical findings-file shape:** `workflow/backlog-quality-findings.md` (header paragraph + `# <feature-name> — <YYYY-MM-DD>` section per feature + N child `## SURFACE-<date>-QUALITY-<slug>` blocks per the reviewer's output).
- **File-already-exists handling:** the findings file already exists with the close-commit-discipline section; future runs must append a new `# <feature-name> — <date>` section, not replace.
- **No test pins assert the specific write path** — only transition emission is tested. Safe to change without scenario edits.

## Work Tree

- [x] T1 Edit `skills/feature-review-quality/SKILL.md:161` (Case-B Mode-3 MAJOR auto-backlog): redirected findings to `workflow/backlog-quality-findings.md` under `# <feature> — <date>` section, added pointer-entry contract for main `backlog.md`, included idempotency-on-re-run note.
- [x] T2 Edit `skills/feature-review-quality/SKILL.md:164` (Case-C MINOR auto-backlog, Modes 2-3): same redirect; chat-summary line extended to name destination file + pointer.
- [x] T3 Updated `agents/code-quality-reviewer/AGENTS.md:18` informational reference to name both files accurately.
- [x] T4 verify
  - [x] Re-read both edited SKILL.md case blocks — both reference findings file + pointer file; Case-B carries idempotency note (Case-C cross-references it)
  - [x] Re-read AGENTS.md informational line — names both files
  - [x] Ran `./tests/check-structure.sh` — 232 PASS / 2 FAIL; both FAILs are the known pre-existing baseline (P3's `SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX`); no new failures introduced
  - [x] Grep `backlog\.md` in `skills/feature-review-quality/` — only lines 161 + 164 (the pointer-entry references, by design — no other write sites)

## Current Node
- **Path:** Task > verify (complete)
- **Active scope:** all complete, ready for close
- **Blocked:** none
- **Open discoveries:** none

## Verification Observable

**Observable:** Both Case-B Mode-3 MAJOR auto-backlog and Case-C MINOR auto-backlog blocks in `skills/feature-review-quality/SKILL.md` route findings to `workflow/backlog-quality-findings.md` (grouped by source feature) AND append exactly one pointer entry to `workflow/backlog.md`. The Case-B block additionally documents idempotency on re-run. The AGENTS.md informational reference at `agents/code-quality-reviewer/AGENTS.md:18` names both files accurately.
**Verification command:** Four `grep` assertions (one per contract claim) — see Verification Result below for the exact commands and outputs.
**Expected result:** Each grep emits ≥1 matching line; combined `check-structure.sh` count remains 232 PASS / 2 known-baseline FAIL.

## Verification Result

**Status:** PASS
**Date:** 2026-06-13
**Evidence:**
- `Grep "workflow/backlog-quality-findings\.md" skills/feature-review-quality/SKILL.md --count` → **2** (Case-B line 161 + Case-C line 164) ✓
- `Grep "pointer entry to backlog\.md" skills/feature-review-quality/SKILL.md --count` → **2** (one per case-block) ✓
- `Grep "Idempotency on re-run" skills/feature-review-quality/SKILL.md` → matches lines 161 (Case-B explicit note) + 164 (Case-C cross-reference to Case-B) ✓
- `Grep "workflow/backlog-quality-findings\.md" agents/code-quality-reviewer/AGENTS.md` → matches line 18 ("Your findings flow forward into … or `workflow/backlog-quality-findings.md` …; the main `workflow/backlog.md` receives one pointer entry per feature") ✓
- `./tests/check-structure.sh` → 232 PASS / 2 FAIL; both FAILs are the pre-existing `SURFACE-2026-06-12-PHASE-3D-REGEX-TEST-MISSES-TR-PREFIX` baseline noise (P3 in the queue). No new failures.
**Notes:** Contract is end-to-end on the consuming surface (the harness loads SKILL.md prose at skill invocation; the prose is the runtime — "SKILL.md prose IS a runtime surface" per today's session lesson). All 4 contract claims confirmed by literal-string grep. The full end-to-end behavioral test (re-run `feature-review-quality` on a real feature and observe volume in main backlog == 1 entry) is the *bite-verify* path documented in the SURFACE, deferred to the next feature ship — but the structural verification here is sufficient evidence the contract prose now lands the writes correctly.

## Retrospect
- **What changed in our understanding:** Nothing material. The task was as expected — two prose edits in case-blocks + one informational reference fix. The canonical shape pre-existed (hand-built yesterday during the close-commit-discipline finalize hotfix), so wiring the auto-writes to it was straightforward.
- **Assumptions that held:** (a) Only two SKILL.md case-blocks touch backlog.md writes (verified by grep — 2 hits before, 2 hits after, different lines). (b) The agent file's reference is informational only (it emits text, the skill writes the file). (c) No test scenarios assert against the write *target* path — only against `TRANSITION:` emission — so no scenario edits needed.
- **Assumptions that were wrong:** None.
- **Approach delta:** None. Plan executed exactly as drafted. The idempotency-on-re-run clause was added at write-time as a natural extension (F40 back-loop after refactor re-runs review-quality on the same feature → need to append under existing section, not duplicate the pointer) — this surfaced naturally during prose composition and was not a re-plan.

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
