# Backlog — Code-Quality Review Findings

This file holds MINOR findings auto-backlogged by `feature-review-quality` runs. The parent `workflow/backlog.md` keeps **one pointer entry per feature** referencing this file. Convention adopted 2026-06-12 to avoid backlog volume noise — see `SURFACE-2026-06-12-ADJUST-QUALITY-AGENT-USE-DEDICATED-FILE` in `backlog.md` for the agent-config followup that codifies this shape.

Items are grouped by source feature. Within each group, each finding keeps the full SURFACE block produced by the reviewer subagent.

---

_Resolved findings are **deleted** from this file on close (delete-on-resolve convention, 2026-07-15) — CHANGELOG.md is the canonical per-SURFACE-ID resolution record. Only open findings remain below, grouped by source feature._

# doc-layout-unification — 2026-07-21

<!-- 3 of the 4 original findings RESOLVED by the post-ship refactor (2026-07-21) and deleted per delete-on-resolve — see CHANGELOG: BACKUP-INSIDE-REPO-STAGED + TEST-MISSING-BACKUP-NOT-STAGED-ASSERTION (both MAJOR, backup now written outside the repo + test guard) and HELP-FLAG-UNIMPLEMENTED (MINOR, --help implemented). The one below remains open. -->

## SURFACE-2026-07-21-QUALITY-RUN-EVAL-QUOTING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship a791f6a)
- **Finding:** `tools/migrate-doc-layout/migrate-doc-layout.sh` `run() { ... eval "$*"; }` uses `eval` on a space-joined argument string, forcing every caller to pre-quote paths. Works because callers quote carefully, but a path with an embedded `"`/`$` would break. Inherited from the `tools/memory-link/` precedent (same pattern), not introduced by this feature.
- **Pickup shape:** consider a `"$@"`-based dispatch or a per-command `--dry-run` guard instead of `eval`. Low priority — not triggered by the known doc-path input set; would ideally be fixed in both tools together since it's a shared inherited pattern.

# memory-location-symlink — 2026-07-03

## SURFACE-2026-07-03-QUALITY-DRYRUN-STRAY-CD-ERROR
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship d173bd7)
- **Finding:** `tools/memory-link/ensure-memory-link.sh:64` — under `--dry-run`, when the repo target dir does not yet exist (its `mkdir -p` was only echoed) and the harness path is already a symlink, the symlink-target comparison's RHS `cd "$REPO_MEM"` emits a stray `cd: No such file or directory` on stderr. Behavior is still correct (exits 0, correct verdict); non-dry-run always has REPO_MEM present by line 64. Diagnostic noise only.
- **Pickup shape:** guard the comparison's `cd` on `[ -d "$REPO_MEM" ]` in dry-run, or route the compare through the already-computed paths. ~2-line fix.

## SURFACE-2026-07-03-QUALITY-SCOPE-RULE-PROSE-ONLY
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship d173bd7)
- **Finding:** The migration scope rule ("any project with a `docs/product/` dir") is stated in prose only (`tools/memory-link/README.md` + `migrate-memory.sh` header); neither script enforces or checks it — `migrate-memory.sh` runs against any dir it's pointed at. Acceptable given the operator-confirmation gate (P2.2 hard checkpoint), but the prose implies a mechanical guard that doesn't exist.
- **Pickup shape:** either add an optional `--require-product-dir` guard to `migrate-memory.sh`, or soften the README prose to "scope is operator-enforced at the confirmation gate, not by the script." Prefer the prose fix (the enumeration/confirmation already lives in the workflow, not the tool).

# wp6-per-scenario-claude-md-fixture-and-neutral-consult — 2026-07-14

## SURFACE-2026-07-14-QUALITY-PROPTEST-MIRRORS-RUNNER
- **Source:** feature-review-quality (WP6 ship e2494f9)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** `tests/check-structure.sh` [Phase 3f]'s `_resolve_claude_md` is a hand-transcribed COPY of the runner's `claude_md` honor-else-fallback branch, not the runner logic itself. The two can drift independently; the grep_check drift-pins only assert the runner's source line still EXISTS, not that the copy still MATCHES it.
- **Context:** Shell can't easily source a mid-function fragment, so a mirror is a reasonable tradeoff — but the coupling is weak. A future runner-branch change that preserves the `if`-line text but alters fallback behavior would leave the property-test passing against stale semantics.
- **Suggested action:** Add a comment in Phase 3f noting the mirror must be updated in lockstep with run-tests.sh's branch. (Verify against the actual code before applying — per the "review-finding suggested-actions are hypotheses" Context Rule.) Cheap + safe.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-14-QUALITY-PROPTEST-LINE-NUMBER-ROT
- **Source:** feature-review-quality (WP6 ship e2494f9)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** Phase 3f comments cite `run-tests.sh:176-181` (claude_md) and `:236` (budget) for the mirrored one-liners; the reviewer flagged the claude_md branch as having shifted to ~183-187. Line-number references in comments rot on any edit above them.
- **Context:** A future reader chasing "the exact one-liners" lands on the wrong lines. NB: the specific line numbers the reviewer cited were read off a diff, not the committed file — VERIFY the actual current line numbers before editing (per the "review-finding suggested-actions are hypotheses" Context Rule; the fix is real regardless, the exact numbers are the hypothesis).
- **Suggested action:** Replace line-number refs in the Phase 3f comments with a stable string anchor (e.g. "the `fixture_claude_md` honor-else-fallback branch"). Cheap + safe.
- **Priority:** low
- **Status:** pending

## SURFACE-2026-07-14-QUALITY-PROPTEST-GREP-UNANCHORED
- **Source:** feature-review-quality (WP6 ship e2494f9)
- **Target level:** workflow:task
- **Type:** tech-debt
- **Summary:** Phase 3f's `_pt_claude` uses `grep -q "$want"` with an unanchored, unescaped pattern. Fine for the current all-caps marker strings (`NAMED-FIXTURE-MARKER`, `DEFAULT-FIXTURE-MARKER`), but a future `want` value containing a regex metacharacter would misfire silently.
- **Context:** Purely defensive hardening; no current bug.
- **Suggested action:** Change `grep -q` → `grep -qF` (fixed-string match) in `_pt_claude`. 1-char edit, cheap + safe.
- **Priority:** low
- **Status:** pending
