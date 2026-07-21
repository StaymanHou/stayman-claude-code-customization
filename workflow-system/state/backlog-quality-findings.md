# Backlog — Code-Quality Review Findings

This file holds MINOR findings auto-backlogged by `feature-review-quality` runs. The parent `workflow/backlog.md` keeps **one pointer entry per feature** referencing this file. Convention adopted 2026-06-12 to avoid backlog volume noise — see `SURFACE-2026-06-12-ADJUST-QUALITY-AGENT-USE-DEDICATED-FILE` in `backlog.md` for the agent-config followup that codifies this shape.

Items are grouped by source feature. Within each group, each finding keeps the full SURFACE block produced by the reviewer subagent.

---

_Resolved findings are **deleted** from this file on close (delete-on-resolve convention, 2026-07-15) — CHANGELOG.md is the canonical per-SURFACE-ID resolution record. Only open findings remain below, grouped by source feature._

# doc-layout-unification — 2026-07-21

## SURFACE-2026-07-21-QUALITY-BACKUP-INSIDE-REPO-STAGED
- **Priority:** medium
- **Severity:** MAJOR (feature-review-quality, ship a791f6a)
- **Finding:** `tools/migrate-doc-layout/migrate-doc-layout.sh` writes its reversible backup *inside* the migration destination (`<proj>/workflow-system/.migration-backup-<date>/`); the tool neither adds it to the project's `.gitignore` nor warns that a subsequent `git add -A` will stage it. This is the exact footgun that hit the claudesk migration mid-run (backup staged into the migration commit → 134 phantom `D` deletions → required amend). The mitigation currently lives ONLY in the operator's per-project loop discipline (remove-backup-before-commit), NOT in the tool — a future run by anyone following the README's "review + commit" step reproduces the bug.
- **Pickup shape:** teach the tool to write the backup OUTSIDE the repo (e.g. `$TMPDIR/migrate-doc-layout-backup-<date>/` or a sibling of the project dir), OR append the backup dir to the project's `.gitignore` on creation, OR (weakest) print a loud warning + the exact `git rm -r --cached`/exclude command. Prefer writing outside the repo — matches the "backup is redundant with git in a committed repo" reality. **VERIFY the suggested fix against the code before applying (review-finding-actions-are-hypotheses); the drift-sidecar path logic also references the backup location.** ~10-line fix + a new test assertion (see the paired finding below).

## SURFACE-2026-07-21-QUALITY-TEST-MISSING-BACKUP-NOT-STAGED-ASSERTION
- **Priority:** medium
- **Severity:** MAJOR (feature-review-quality, ship a791f6a)
- **Finding:** `tools/migrate-doc-layout/test/run-tests.sh` git-history test group (group 5) covers only the happy path (clean move → renames → `git log --follow`). There is NO assertion that the `.migration-backup-<date>/` dir is absent from — or not staged in — the resulting git status. That is the one behavior that actually failed in the production run (claudesk). Paired with the finding above: the coverage gap is exactly why the pin didn't catch the footgun.
- **Pickup shape:** add an assertion to the git test group: after a real migration in a git repo, `git -C "$P" status --short | grep -c migration-backup` is 0 (once the backup-location fix lands), OR the backup path is gitignored. Land together with the backup-location fix so the assertion guards the fix.

## SURFACE-2026-07-21-QUALITY-RUN-EVAL-QUOTING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship a791f6a)
- **Finding:** `tools/migrate-doc-layout/migrate-doc-layout.sh` `run() { ... eval "$*"; }` uses `eval` on a space-joined argument string, forcing every caller to pre-quote paths. Works because callers quote carefully, but a path with an embedded `"`/`$` would break. Inherited from the `tools/memory-link/` precedent (same pattern), not introduced by this feature.
- **Pickup shape:** consider a `"$@"`-based dispatch or a per-command `--dry-run` guard instead of `eval`. Low priority — not triggered by the known doc-path input set; would ideally be fixed in both tools together since it's a shared inherited pattern.

## SURFACE-2026-07-21-QUALITY-HELP-FLAG-UNIMPLEMENTED
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship a791f6a)
- **Finding:** `tools/migrate-doc-layout/README.md` (and the WIP Phase-2 observable outcome) advertise a `--help`/`-h` surface (`migrate-doc-layout.sh --help exits 0 and documents <proj-dir>, --dry-run, --date`), but the arg-parse loop has no `--help`/`-h` case — such an arg falls through to the `*)` branch and is treated as `$PROJ`. The header comment block is the only usage doc.
- **Pickup shape:** either add a `--help|-h)` case that prints the usage block and exits 0, OR soften the README to not claim a `--help` flag. Prefer implementing `--help` (cheap, matches the advertised contract). **VERIFY the arg-parse loop shape before editing.**

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
