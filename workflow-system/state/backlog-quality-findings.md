# Backlog — Code-Quality Review Findings

This file holds MINOR findings auto-backlogged by `feature-review-quality` runs. The parent `workflow/backlog.md` keeps **one pointer entry per feature** referencing this file. Convention adopted 2026-06-12 to avoid backlog volume noise — see `SURFACE-2026-06-12-ADJUST-QUALITY-AGENT-USE-DEDICATED-FILE` in `backlog.md` for the agent-config followup that codifies this shape.

Items are grouped by source feature. Within each group, each finding keeps the full SURFACE block produced by the reviewer subagent.

---

# wp7i-richer-greenfield-sample — 2026-07-22

<!-- 3 MINOR findings from feature-review-quality, ship 5ca1723 (drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. Two of the three are explicitly "no change recommended" by the reviewer (todos.txt tracked-by-design; independence-test robustness nit). Verify each against the real code before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-22-QUALITY-WP7I-DONE-PREFIX-STRIP-OPAQUE
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 5ca1723)
- **Finding:** `tools/onboarding-scaffold/sample/lib/done.sh:30` flips the checkbox with `line="[x] ${line#??? }"` — a `?`-glob strip of exactly 4 leading chars. Correct (both `[ ] ` and `[x] ` prefixes are 4 chars) and verified (re-`done` preserves text + glob-char content), but the `??? ` idiom is opaque: a future maintainer changing the store prefix format has no in-code cue that `??? ` encodes "the 4-char status prefix."
- **Suggested action (HYPOTHESIS — verify against the code):** add a one-line comment naming the "4-char status prefix" assumption (or switch to an intent-revealing form like `${line#"[?] "}` if it round-trips both prefixes). Cosmetic; behavior is sound — do not change behavior.
- **Pickup shape:** trivial 1-line comment; fold into a `/util-backlog-paydown` sweep or any future touch of `done.sh` (e.g. if a later WP fixes the planted tangent).

## SURFACE-2026-07-22-QUALITY-WP7I-INDEPENDENCE-TEST-ASSUMES-COPY
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 5ca1723)
- **Finding:** `tools/onboarding-scaffold/test/run-tests.sh` group [5]'s independence check appends a marker to the copy's `todo` and greps the source `todo` — correct, but silently assumes the copy's `todo` is present/writable; if the scaffold ever stopped copying the extensionless `todo`, this would assert independence against a possibly-missing file rather than fail loudly. Low-likelihood (the earlier run-check in [5] already exercises the copied `todo`).
- **Suggested action (HYPOTHESIS — verify):** optionally add a `[ -f "$D/s/todo" ]` precondition assertion before the marker-append so a missing copied artifact fails loudly. Robustness nit only.
- **Pickup shape:** trivial; fold into a sweep or any future smoke edit.

## SURFACE-2026-07-22-QUALITY-WP7I-TODOS-TXT-TRACKED-EMPTY
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 5ca1723)
- **Finding:** `tools/onboarding-scaffold/sample/todos.txt` is a tracked 0-byte file; running the sample from the source tree with the default `TODO_STORE` writes into it (would dirty a tracked file). **Reviewer: no change recommended** — this is by design (the tour always stamps a fresh copy via `new-sample.sh`; the smoke isolates every store via `fresh_store()`) and the visible store IS the intended "the store is your state, nothing hidden" teaching surface.
- **Suggested action (HYPOTHESIS — likely NO CHANGE):** leave as-is; flagged only so the operator is aware a stray in-source run would dirty a tracked file. If ever a concern, a `.gitignore` on the store or a git pre-commit reset could guard it — but that undercuts the teaching surface. Likely close-as-wontfix.
- **Pickup shape:** likely wontfix; no action expected.

# wp7g-tour-copy-corrections — 2026-07-22

<!-- 1 MINOR from feature-review-quality (baseline a1d4c2b, drive_mode=autopilot). The other 2 review MINORs (stale acceptEdits self-references at onboarding-flow-spec.md:15 & :36) were own-session drift and FIXED inline, not backlogged. Verify against the real code before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-22-QUALITY-WP7G-STEP0-AUTO-CAVEAT-ORDERING
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, baseline a1d4c2b)
- **Finding:** `skills/tutorial-getting-started/SKILL.md` Step-0's **brownfield** branch instructs the user to `/exit` and relaunch `claude --permission-mode auto` — but auto mode, its safety framing, and (load-bearingly) the "if auto mode isn't available" availability caveat are all introduced in **Step 1**, which the user only reaches *after* relaunching + re-running the tour. A user on an older model (no auto) is told to launch with `--permission-mode auto` before being told it may be unavailable. Forward-ref "(in auto mode — see the next step)" softens it; not a correctness bug (the caveat is hit on the second pass through Step 1).
- **Suggested action (HYPOTHESIS — verify against the code):** add a half-sentence to the Step-0 brownfield copy — e.g. "if auto isn't available to you, just launch `claude` normally; Step 1 explains" — so the availability caveat is surfaced at the point the user is first told to launch with `--permission-mode auto`. Verify the exact current Step-0 brownfield wording first.
- **Pickup shape:** trivial copy tweak to 1 file; natural fold-in with WP7i/WP7j (which also touch the tour arms) or the operator's eventual hands-on run. Low priority.

# wp7a-onboarding-flow-spec — 2026-07-22

<!-- 1 MINOR finding remaining (2 of the original 3 — SPLIT-GREENFIELD-GROUNDING + SECTION3-LEGEND-NO-DISPOSITION-TOKENS — RESOLVED by WP7d and deleted per delete-on-resolve; see CHANGELOG). The remaining one is copy-time polish on the §5b permission-mode table. Verify against the real doc text before applying (review-finding-actions-are-hypotheses). -->

## SURFACE-2026-07-22-QUALITY-ACCEPTEDITS-TABLE-MIDDLE-COLUMN
- **Priority:** low
- **Severity:** MINOR (feature-review-quality, ship 4a43713)
- **Finding:** `onboarding-flow-spec.md` §5b (~L215-218) permission-mode table's `acceptEdits` "Safe filesystem cmds → auto" column is imprecise. Per the Claude Code model, `acceptEdits` auto-accepts file *edits* plus a specific safe-filesystem-command set (`mkdir`/`touch`/`rm`/`mv`/`cp`/`sed`); it is not a blanket "safe filesystem commands auto-approve" tier. The load-bearing distinction the section makes (acceptEdits gates arbitrary shell/network; bypassPermissions doesn't) is CORRECT, and the reassurance copy (~L226-231) only claims accurate behavior — so this is a table-column overstatement in a precision-critical section, not a functional error.
- **Pickup shape:** tighten the middle column at **WP7b copy time** (where the skill copy is authored) so the correcting table is airtight — e.g. "safe FS cmds (mkdir/touch/rm/mv/cp/sed) auto; other shell prompts". Verify against docs (https://code.claude.com/docs/en/permission-modes.md) + the real doc text first.

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
