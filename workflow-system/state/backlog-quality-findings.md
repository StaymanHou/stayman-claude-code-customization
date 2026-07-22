# Backlog — Code-Quality Review Findings

This file holds MINOR findings auto-backlogged by `feature-review-quality` runs. The parent `workflow/backlog.md` keeps **one pointer entry per feature** referencing this file. Convention adopted 2026-06-12 to avoid backlog volume noise — see `SURFACE-2026-06-12-ADJUST-QUALITY-AGENT-USE-DEDICATED-FILE` in `backlog.md` for the agent-config followup that codifies this shape.

Items are grouped by source feature. Within each group, each finding keeps the full SURFACE block produced by the reviewer subagent.

---

# wp7c-greenfield-onboarding-scaffold — 2026-07-22

<!-- 1 MAJOR + 2 MINOR findings from feature-review-quality, ship 287ff86 (drive_mode=autopilot; MAJOR auto-backlogged with prominent chat surface per Mode-3 policy, MINORs auto-backlogged). All three touch the WP7c scaffold; the MAJOR is a real, reproduced --help bug on a user-facing surface. Verify each against the real code before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-22-QUALITY-NEW-SAMPLE-HELP-LEAKS-CODE
- **Priority:** medium
- **Severity:** MAJOR (feature-review-quality, ship 287ff86)
- **Finding:** `tools/onboarding-scaffold/new-sample.sh` `usage()` extracts help via `sed -n '2,20p'`, but the header comment block ends at `# POSIX-ish bash, no dependencies.` (line 15). Lines 16–20 are a blank line, `set -euo pipefail`, another blank, and the `SCRIPT_DIR=`/`SRC=` assignments — so `--help` prints those verbatim as if they were help text (reproduced by the reviewer). Real user-facing defect on a tool the onboarding tour surfaces to a brand-new skeptical user; the hard-coded line range silently re-corrupts on any future header edit.
- **Suggested action (HYPOTHESIS — verify against the code):** replace the magic `sed -n '2,20p'` with a delimiter-anchored extraction — print the contiguous `#`-comment block that follows the shebang and stop at the first non-comment line (e.g. an `awk 'NR>1 && /^#/ {sub(/^# ?/,"");print} NR>1 && !/^#/ {exit}'`). Confirm the resulting `--help` shows only the usage prose and stops before `set -euo pipefail`.
- **Pickup shape:** small self-contained task/refactor against `new-sample.sh`; low blast radius (diagnostic path only). Worth doing before the tour goes live (operator's hands-on run — see SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED — will hit `--help` naturally).

## SURFACE-2026-07-22-QUALITY-GREET-TODO-RESTATES-WHAT
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 287ff86)
- **Finding:** `tools/onboarding-scaffold/sample/greet.sh:13-15` `TODO:` comment restates WHAT the no-arg path does (`Hello, !`), which the behavior already shows. Soft flag only — the comment is arguably load-bearing tour scaffolding (self-documents the planted tangent for the agent driving the SURFACE beat), and the WHY half ("Left as-is on purpose... Don't fix it inline mid-task") is genuinely useful and should stay.
- **Suggested action (HYPOTHESIS — verify):** likely NO CHANGE — the WHAT-restatement is intentional here (it's what makes the tangent self-documenting). Noted only so it isn't copied as a comment-style precedent into non-tour code. If touched at all, trim only the redundant WHAT clause, keep the WHY.
- **Pickup shape:** trivial / likely close-as-wontfix; do NOT "fix" the planted tangent itself.

## SURFACE-2026-07-22-QUALITY-NEW-SAMPLE-MKTEMP-DOUBLE-SLASH
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 287ff86)
- **Finding:** `tools/onboarding-scaffold/new-sample.sh` default `mktemp -d "${TMPDIR:-/tmp}/onboarding-sample.XXXXXX"` yields a double-slash path (`.../T//onboarding-sample...`) when `$TMPDIR` ends in `/` (macOS default), which propagates into the printed "Created fresh sample at:" / "Try it: cd ..." hints the user copies. Cosmetic — the path still resolves.
- **Suggested action (HYPOTHESIS — verify):** trim the trailing slash: `${TMPDIR:-/tmp}` → `"${TMPDIR:-/tmp}"` with a `%/` strip, e.g. `d="${TMPDIR:-/tmp}"; d="${d%/}"; mktemp -d "$d/onboarding-sample.XXXXXX"`. Confirm the printed hint has no `//`.
- **Pickup shape:** trivial cosmetic; fold in with the MAJOR `--help` fix if that task runs.

# wp7b-workflow-tour-entry-skill — 2026-07-22

<!-- 2 MINOR findings from feature-review-quality, ship 40ec14f (a 3rd MINOR — WIP verify-leaf duplication — was fixed in-place at review time, so not backlogged). Both remaining findings are prose-tightening the reviewer itself judged "land more naturally in the WP7d wiring pass than in a refactor." Verify each against the real skill text before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-22-QUALITY-DISPATCHER-CONTROL-RETURN-PHRASING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 40ec14f)
- **Finding:** `skills/tutorial-getting-started/SKILL.md` Step 3 says the dispatcher "hands off inline" and "control does not 'return' here," but a one-shot `Skill`-tool invocation does return to the caller when the invoked skill completes. The divergence intent is correct (the arm owns the rest of the run), but "control does not return" slightly overstates the tool mechanics — a cold reader could take it literally and wonder whether the dispatcher is expected to stay live after the arm finishes.
- **Pickup shape:** at **WP7d wiring time**, add a half-sentence clarifying "the arm runs to close; you don't resume the dispatcher afterward" so the divergence semantics read unambiguously. Verify against the real Step-3 prose first.

## SURFACE-2026-07-22-QUALITY-GREENFIELD-PRODUCT-ENTRY-UNBOUNDED
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 40ec14f)
- **Finding:** `skills/tutorial-greenfield-workflow-tour/SKILL.md` Step 2 tells the agent to "run `/product-vision` (or `/session-start`…)" then Step 3 pivots to "do one small real thing," but the arm never bounds how far the product lifecycle runs before the pivot. Spec §3-greenfield row 2 says "**light** product→feature lifecycle **taste**" — the bounding word ("taste") is doing work the arm prose doesn't fully carry, so a literal reading risks a full vision→roadmap→arch→wbs detour on a tiny sample before the first tangible beat (A/state-is-a-file).
- **Pickup shape:** at **WP7d wiring time**, add an explicit "keep the product entry to a light taste, then pivot to the small unit" bound to Step 2. Verify against the real Step-2 prose + spec §3 first.

---

# wp7a-onboarding-flow-spec — 2026-07-22

<!-- 3 MINOR findings from feature-review-quality, ship 4a43713. All copy-time polish on the new product doc workflow-system/product/onboarding-flow-spec.md — addressable at WP7b/WP7d authoring, none refactor-worthy. Verify each against the real doc text before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-22-QUALITY-ACCEPTEDITS-TABLE-MIDDLE-COLUMN
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 4a43713)
- **Finding:** `onboarding-flow-spec.md` §5b (~L215-218) permission-mode table's `acceptEdits` "Safe filesystem cmds → auto" column is imprecise. Per the Claude Code model, `acceptEdits` auto-accepts file *edits* plus a specific safe-filesystem-command set (`mkdir`/`touch`/`rm`/`mv`/`cp`/`sed`); it is not a blanket "safe filesystem commands auto-approve" tier. The load-bearing distinction the section makes (acceptEdits gates arbitrary shell/network; bypassPermissions doesn't) is CORRECT, and the reassurance copy (~L226-231) only claims accurate behavior — so this is a table-column overstatement in a precision-critical section, not a functional error.
- **Pickup shape:** tighten the middle column at **WP7b copy time** (where the skill copy is authored) so the correcting table is airtight — e.g. "safe FS cmds (mkdir/touch/rm/mv/cp/sed) auto; other shell prompts". Verify against docs (https://code.claude.com/docs/en/permission-modes.md) + the real doc text first.

## SURFACE-2026-07-22-QUALITY-SPLIT-GREENFIELD-GROUNDING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 4a43713)
- **Finding:** `onboarding-flow-spec.md` describes greenfield "grounding" across two surfaces — probe-first/plan-around-real-shapes at §3 greenfield step 2 (a natural BEAT) and verify-self-on-scaffold at step 5 (STAGED) — but only the verify-self surface appears in the §7 "don't force it" guaranteed-staged set. Internally consistent (probe-first is opportunistic, not staged), but a WP7d author wiring "the grounding beat" must reconcile the two surfaces themselves.
- **Pickup shape:** add a one-clause pointer at §3 greenfield step 2 ("probe-first grounding is a natural BEAT; only the verify-self surface is STAGED") at **WP7d** wiring time to remove the reconciliation burden. Verify against the real §3/§7 text first.

## SURFACE-2026-07-22-QUALITY-SECTION3-LEGEND-NO-DISPOSITION-TOKENS
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 4a43713)
- **Finding:** `onboarding-flow-spec.md` §3's beat-annotation legend (~L73) enumerates beat keys (A, B, C, G, Grounding, …) but omits the disposition tokens (STAGED/BEAT/FRAME/NAMED/CUT) that the §3 flow-table "Staged?" column and §7 actually use; the two legends live in different sections with no cross-pointer.
- **Pickup shape:** trivial — add a "see §7 for disposition tokens" cross-pointer at §3 so it is self-contained for a first-time reader. Bundle into the next `/util-backlog-paydown` sweep or WP7 authoring. Verify against the real doc first.

---

_Resolved findings are **deleted** from this file on close (delete-on-resolve convention, 2026-07-15) — CHANGELOG.md is the canonical per-SURFACE-ID resolution record. Only open findings remain below, grouped by source feature._

# doc-layout-unification — 2026-07-21

<!-- 3 of the 4 original findings RESOLVED by the post-ship refactor (2026-07-21) and deleted per delete-on-resolve — see CHANGELOG: BACKUP-INSIDE-REPO-STAGED + TEST-MISSING-BACKUP-NOT-STAGED-ASSERTION (both MAJOR, backup now written outside the repo + test guard) and HELP-FLAG-UNIMPLEMENTED (MINOR, --help implemented). The one below remains open. -->

## SURFACE-2026-07-21-QUALITY-RUN-EVAL-QUOTING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship a791f6a)
- **Finding:** `tools/migrate-doc-layout/migrate-doc-layout.sh` `run() { ... eval "$*"; }` uses `eval` on a space-joined argument string, forcing every caller to pre-quote paths. Works because callers quote carefully, but a path with an embedded `"`/`$` would break. Inherited from the `tools/memory-link/` precedent (same pattern), not introduced by this feature.
- **Pickup shape:** consider a `"$@"`-based dispatch or a per-command `--dry-run` guard instead of `eval`. Low priority — not triggered by the known doc-path input set; would ideally be fixed in both tools together since it's a shared inherited pattern.

# wp6-research-cost-tier-disambiguation — 2026-07-21

## SURFACE-2026-07-21-QUALITY-QR2-PROMPT-ANSWERABLE-ANCHORS
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 17fe152)
- **Finding:** `tests/scenarios/research.yaml` QR2's `contains_any` includes `"80"` and `"443"` — the literal answer to "what port does HTTP/HTTPS use." Any model answering the question emits those regardless of whether the `quick-research` skill prose exists, so those two anchors provide near-zero signal that the *skill's* confidence-labeling / no-over-reach discipline fired (sibling to `docs/lessons/test-scenario-prompt-leakage.md`). The `"confidence"` / `"settled"` anchors are the load-bearing ones.
- **Pickup shape:** **cheap + safe** — drop `"80"`/`"443"` from QR2's `contains_any` (keep `"confidence"`, `"HIGH"`, `"settled"`), or replace with an anchor that only fires if the skill's over-reach-guard prose ran (e.g. `"no escalation"` / `"None load-bearing"`). Strong next-`/feature-refactor`-or-sweep pickup. **Verify against the code first (review-finding-actions-are-hypotheses).**

## SURFACE-2026-07-21-QUALITY-QR-DESCRIPTION-DENSITY
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 17fe152)
- **Finding:** `skills/quick-research/SKILL.md:2` `description` is a dense ~55-word sentence (tier + confidence-labels + known-unknowns + escalation-gate + ROI contrast). Reads unambiguously but is long for a `description:` field surfacing in skill-selection context; the four in-workflow siblings are terser.
- **Pickup shape:** cosmetic — optionally trim to the two load-bearing distinctions (light/fast web + confirm-before-deep). Disambiguation value is real, so low priority; do NOT lose the quick-vs-deep contrast.

## SURFACE-2026-07-21-QUALITY-CONFIRM-GATE-PLACEMENT-UNPINNED
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 17fe152)
- **Finding:** the "never auto-launch deep-research" confirm-gate clause lives in prose across three surfaces (`skills/quick-research/SKILL.md` §5 + both `agents/{feature,product}-workflow/AGENTS.md` subsections). check-structure.sh [Phase 16] pins the *phrase* exists but not its *co-location* with the escalation step, so a future edit could move the escalation instruction away from the "wait for human yes" clause without tripping a pin.
- **Pickup shape:** low — the skill emits no transition so the AUTO-exit machinery doesn't apply; if hardened, add a pin asserting the escalation-offer step and the "never auto-launch / wait" clause appear within N lines of each other in §5. Latent-drift guard, not a live bug.

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

# uninstall-sh — 2026-07-21

<!-- 1 MINOR remaining (auto-backlogged). The MAJOR + sibling MINOR (arg-parser --project flag-shaped/missing value) were FIXED in the post-ship refactor (2026-07-21) per operator's refactor-now choice — see CHANGELOG + the WIP ## Code-Quality Review section. -->

## SURFACE-2026-07-21-QUALITY-UNINSTALL-REMOVE-LINK-COMMENT-ORDER
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship d7e9075)
- **Finding:** `uninstall.sh` `remove_link` header comment enumerates outcomes in the order "not present → [ok] … symlink … real file", but the code body checks them in the reverse order (`-L` symlink → `-e` real file → fallthrough `[ok]`). Harmless — behavior is correct — but the comment ordering doesn't match read order and momentarily misleads a future reader.
- **Pickup shape:** trivial — reorder the comment's outcome list to match the code's check order (`-L` → `-e` → fallthrough). Bundle into the next `/util-backlog-paydown` sweep or a docs-only task.

# boundary-handoff-autochain-state-machine — 2026-07-21

## SURFACE-2026-07-21-QUALITY-SESSION-ID-GAP-UNDOCUMENTED
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 3104205)
- **Finding:** The `transitions.md` Session-transitions table now reads S17, S18, S20, S22, S23 — S19 and S21 are absent and undocumented. A future author adding a session edge cannot tell whether S19/S21 are retired-and-reserved or simply never used, risking accidental ID reuse in an append-only namespace.
- **Pickup shape:** trivial — add a one-line "S19/S21 unused" note near the Session-transitions table (mirroring how `F17` retired is called out elsewhere). Bundle into the next `/util-backlog-paydown` sweep or a docs task. **Verify against the code first** (review-finding-actions-are-hypotheses).

## SURFACE-2026-07-21-QUALITY-GUARD-BULLET-NESTING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 3104205)
- **Finding:** The new "pause-policy table is authoritative" bullet in the §Your-Role guard block is nested at 5-space indent (child of the "Agent-side guard is CONTEXTUAL" bullet) across all 4 orchestrator AGENTS.md, but it reads as a peer statement governing the whole boundary auto-chain decision, not only the CONTEXTUAL-guard sub-case. Cosmetic; identical across all 4 files.
- **Pickup shape:** trivial — promote the bullet to a 3-space peer of the two sibling guard bullets in all 4 AGENTS.md (keep them in sync). Bundle into the next sweep. **Verify the current indent against each file first.**

## SURFACE-2026-07-21-QUALITY-S29-INERT-NOT-CONTAINS
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 3104205)
- **Finding:** `tests/scenarios/session.yaml::S29` carries `not_contains: TRANSITION: S17`, but the real mis-fire (an unwanted handoff) surfaces as a written `.session.md` / "Handed off" string — already guarded by the sibling `not_contains` lines. The `TRANSITION: S17` guard is near-inert (session-handoff rarely emits a structured token in this prose-behavior path). Not wrong, just lower-signal than its prominence suggests.
- **Pickup shape:** optional — drop the `TRANSITION: S17` line from S29's `not_contains` (or replace with a stronger `.session.md`-side anchor). Low value; leave unless touching S29 for another reason. **Verify against the current S29 block first.**
