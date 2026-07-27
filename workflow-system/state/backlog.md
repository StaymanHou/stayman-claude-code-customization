# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention). **Code-quality findings** auto-backlogged by `feature-review-quality` are pointer-collapsed here — full content lives in `workflow/backlog-quality-findings.md`, grouped by source feature.

---

## TODO

## SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED
- **Source:** feature:verify-human (wp7c-greenfield-onboarding-scaffold, Phase 2)
- **Target level:** feature (follow-up task)
- **Type:** gap (deferred acceptance test)
- **Summary:** The operator's hands-on copy read-through of the greenfield tour was DEFERRED (2026-07-22). The operator will run `/tutorial-getting-started` → greenfield arm hands-on once the ratified M11 tail is addressed (a **2nd walkthrough** — the 1st drove the WP7g/WP7i corrections) and give feedback then. That hands-on run is the real acceptance test for the wired greenfield arm (environment drop-in, upfront project framing, Step 5 grounding cite, Step 6 SURFACE tangent, the richer todo-CLI sample) — verify-self only confirmed the mechanical facts (paths named, strings present/absent, ordering, suite green, no bare .claude/). **Scope now spans WP7c + WP7g + WP7i + WP7j + WP7k copy** (WP7j 2026-07-23 shipped the session-chain flow correction, arm entry-question + mode-switch menu, corrected replay invites, brownfield git-safety pre-flight, mode-aware Step-8 graduation, and the scaffold re-home; the operator explicitly deferred WP7j's own hands-on copy-paste check "after all load-bearing WPs are done" — same batch). **UPDATE 2026-07-24:** WP7h design settled + build split to **WP7k** (the new full product-cycle tour), and the operator sequenced **WP7k BEFORE this acceptance run** — so this single batch walkthrough now covers **all four tour surfaces** (both arms + WP7g corrections + the new WP7k full-cycle tour). The run happens once WP7k lands (the last load-bearing M11 WP before WP7e).
- **Context:** Autopilot forward-progress was approved on verify-self evidence across WP7c/WP7g/WP7i/WP7j; the prose-reads-well-for-a-cold-skeptic judgment is inherently human and was deferred, not skipped. Each WP ships/finalizes now; feedback returns HERE as a follow-up, NOT as a back-loop on the shipped gates.
- **✅ PARTIALLY RESOLVED 2026-07-25 — the batch walkthrough RAN.** Operator verdict: **3 of 4 surfaces PASS as-shipped** — brownfield arm, WP7g corrections, and the WP7k full-cycle tour are **accepted** ("everything else are good"). Those three sub-scopes are closed and need no further acceptance. **Remaining open scope: the greenfield arm only**, which drew three fixes now ratified into the WBS as **WP7l** (sample lands flat in the user's own cwd + refuse-if-non-empty + offer-to-clean-up at close), **WP7m** (tour-aware boundary guard — a tour-hosted close must not offer/take the `S22` session-handoff chain), **WP7n** (Step-8 close restructure — narrative above, terse `Next Step:` block ≤3 sentences/option at the bottom). Feedback recorded in `tmp/wp7e-batch-acceptance-walkthrough.md` → `## Feedback`; each fix was verified against the real code + the origin session log (`~/.claude/projects/-Users-stayman-Work-Tmp-mccc-tutorial-a/`) before write-up. Per the **partial-resolution carve-out** (delete-on-resolve convention) this entry is **rewritten, not deleted** — the resolved 3-surface part is recorded in `CHANGELOG.md` at the next close.
- **✅ BUILD HALF NOW COMPLETE (2026-07-27) — all three fixes are BUILT; only the acceptance run remains.** WP7m (tour-aware boundary guard, commit `e7e682b`) was the last of the three, joining WP7l + WP7n (`783bdf2`). **This entry is NOT resolved and NOT deleted** — its own suggested action requires "build all three **then run a re-acceptance pass**," and that pass has not happened. Per the partial-resolution carve-out the entry is **rewritten** to the remaining open work: **one full hands-on greenfield tour run** (operator 2026-07-27: *"defer. I'll just do a full tour again after changes are done"*), which accepts WP7l + WP7n + WP7m together, flips all three from 🔨 BUILT to ✅ SHIPPED, and **must also answer the open refuse-if-non-empty design question** below. No `**Backlog resolved:**` CHANGELOG line was emitted for this item, since nothing is resolved yet.
- **Suggested action (remaining):** Run the **one full hands-on greenfield tour run** described above (all three fixes are already built — see `wbs.md` M11). The WP7m-specific things to watch: at the in-tour feature's close the agent must **just continue the tour** (no `/session-handoff`, no `.session.md`, **no "continue vs. hand off?" fork**), while Step 7's *own* staged handoff→restore beat must still run normally — both must hold simultaneously. Then **WP7e** codifies pins against the accepted copy across all four surfaces, and this SURFACE is fully resolved (delete then, per delete-on-resolve). Superseded original action: Build **WP7l / WP7m / WP7n** (see `wbs.md` M11 ratified block), then run a **greenfield-arm-only re-acceptance** pass — a full 4-surface re-walkthrough is NOT needed, the other three are accepted. Once the greenfield arm is re-accepted, **WP7e** codifies pins against the accepted copy across all four surfaces, and this SURFACE is fully resolved (delete then, per delete-on-resolve).
- **UPDATE 2026-07-25 (in-flight) — the per-phase verify-human gates are DEFERRED into this same re-acceptance.** WP7l shipped its build+verify-auto+verify-self clean (8/8 PASS + a fresh-subagent 5/5 shortcut re-verify), but the operator deferred the **copy judgment** at verify-human until **all three greenfield fixes are in place** (operator: *"defer to when all the fixes are in place"*) — so the acceptance is ONE read over the finished arm, not three partial ones. Integration boundary APPLIES on these phases (prose changed inside shipped, consumed skill prompts), so F11-skip was forbidden and the Mode-3 auto-skip gate correctly did NOT fire — the gates are **owed, not waived**. The concrete owed checklist lives in the feature WIP (`workflow-system/state/wip/greenfield-tour-cwd-sample-and-close-restructure.md` → `## Deferred human gate`) and must be re-presented after WP7m lands.
- **⚠️ OPEN DESIGN QUESTION gating WP7e (do not let pins freeze without an answer):** the ratified "always flat, **refuse if non-empty**" rule means the empty-cwd guard **fires on every replay** (the user is standing in their previous run's directory). It is mitigated in copy (the arm normalizes it; the Step-8 invite pre-empts it by sending the user to a new empty folder), so it should not bite — but the "rare backstop" is genuinely rare only on *first* runs. The passed-over alternative (**ask + offer a `./onboarding-sample-todo/` subdir fallback**) is a one-WP change that is cheap **now** and expensive after WP7e pins this copy. Raised to the operator at the WP7l verify-human gate; answer owed at the deferred acceptance.
- **Priority:** medium
- **Status:** partially-resolved — **build half DONE (all 3 fixes BUILT 2026-07-27); remaining open work = the one full hands-on greenfield acceptance run → then WP7e**

## Code-quality findings — tour-aware-session-boundary (2026-07-27)
- **Pointer:** 2 MINOR findings (0 CRITICAL / 2 MAJOR) from `feature-review-quality` on ship `18722aa` — the 2 MAJORs and 2 of the 4 MINORs were **FIXED IN-FEATURE** (see below); these 2 remain: (1) `grep_check` has no case-insensitive option, so the next caller needing one will hand-roll and re-introduce the fail-open shape WP7m just closed; (2) the Step-7 bright-line sentence is unscoped and would also suppress an *explicitly operator-requested* mid-tour handoff. Full bodies: [`workflow-system/state/backlog-quality-findings.md`](backlog-quality-findings.md) → `# tour-aware-session-boundary — 2026-07-27`.
- **The 2 MAJORs + 2 MINORs were FIXED IN-FEATURE, not backlogged** — all four corrupted the artifact **WP7e is chartered to pin against**, so deferring was not viable: (1) the three block-`(i)` regression pins **failed OPEN** on a missing/renamed file (verified against a synthetic path — and WP5/M9 already renamed exactly these three skills once), now fail closed via an `[ -f ]` precondition; (2) their vocabulary matched only `tutorial|workflow tour`, so leaks worded "onboarding tour"/"greenfield arm" passed clean (the repo's own sensitivity-vs-relevance trap — the mutation used the word `tutorial`), now widened without loosening to bare `tour` (which false-positives on "detours"); (3) a stale `~30 lines` claim survived in `wbs.md` after the correction landed in the WIP + spec (WP7l's doc-vs-reality class, 1 of 3 copies); (4) the guard's close enumeration missed `feature-refactor` (F21) vs. the canonical 4-close table. All fixes **mutation-verified**; suite 485 → 487.
- **Priority:** low (both remaining)
- **Status:** pending
- **Pickup shape:** finding (2) is **user-facing tour copy in the exact region the operator's DEFERRED acceptance read covers** → settle it inside **WP7e's copy-freeze**, alongside the 4 copy MINORs already routed there from WP7l/WP7n; do NOT fix it blind. Finding (1) is a test-harness ergonomics improvement, independent of the tour — pair it with adding **case-variance in emphasis words** (`NOT`/`MUST`/`ONLY`) to `docs/lessons/verify-grep-blind-spots.md`, which currently lists only en-dash / bold-wrap / line-wrap.

## Code-quality findings — greenfield-tour-cwd-sample-and-close-restructure (2026-07-25)
- **Pointer:** 5 MINOR findings (0 CRITICAL / 2 MAJOR) from `feature-review-quality` on ship `783bdf2` — compression residue from the WP7n close restructure: an ambiguous `Next Step:` block-membership rule (the same ambiguity that broke a sentence-counter), a mechanics pointer that inverted direction during compression, a greenfield `/exit`-before-`mkdir` ordering slip in the user's LAST on-screen instruction, a garden-path clause in the git-safety rationale, and a duplicate `Open discoveries:` WIP line. Full bodies: [`workflow-system/state/backlog-quality-findings.md`](backlog-quality-findings.md) → `# greenfield-tour-cwd-sample-and-close-restructure — 2026-07-25`.
- **The 2 MAJORs were FIXED IN-FEATURE, not backlogged** — (1) the spec revision header claimed it resynced `§3` both-arm step-8 rows + `§7` rows but had not, leaving the beat tables describing the *superseded* close; (2) the new group-9 runnable assertion overrode `TODO_STORE` to an external temp file, so it never exercised the flat-stamped `./todos.txt` the tour's Step-5 grounding beat actually uses. Both would have corrupted the artifact **WP7e is chartered to pin against**, so deferring them was not viable. Fixes verified: spec rows resynced; assertion rewritten to use the real default store + a new store-resolution assertion, **mutation-verified** (breaking `SCRIPT_DIR` resolution now fails it). Suite 19 → 20.
- **Priority:** low (all 5 remaining)
- **Status:** pending
- **Pickup shape:** all five are trivial prose/one-line fixes. **Four are user-facing tour copy → best folded into WP7e's copy-freeze so they are settled BEFORE pins lock accepted copy** (two of them — the block-membership ambiguity and the garden-path git-safety clause — directly affect the DEFERRED verify-human read the operator still owes). The fifth is already fixed and retained only as a data point on the recurring WIP-edit failure mode.

## SURFACE-2026-07-25-WP7N-CLOSE-STRUCTURE-UNPINNED
- **Source:** feature:verify-codify (greenfield-tour-cwd-sample-and-close-restructure, Phase 2 / WP7n)
- **Target level:** feature (WP7e charter — already-planned work, recorded so it cannot be dropped)
- **Type:** gap (measured coverage gap)
- **Summary:** WP7n's deliverable — the restructured tour closes (`Next Step:` block LAST, per-branch, ≤3 sentences/option, all beats surviving the re-order) — has **zero automated coverage**, confirmed empirically rather than assumed: **deleting BOTH `Next Step:` blocks outright still passes the scaffold suite (19/19) and `check-structure.sh` (472/1, unchanged)**. `grep -c tutorial tests/check-structure.sh` = 0 — the `tutorial-*` family has no structural pins at all yet.
- **Context:** Deliberately NOT fixed in-feature, for three reasons: (1) the scaffold suite's group-8 comment states its own boundary verbatim — *"This pins the consuming-surface wiring only; the tour's behavioral scenarios + structural pins are WP7e's job — deliberately NOT duplicated here"* — and close-ordering is tour structure, not scaffold wiring; (2) **verify-human is DEFERRED** for both phases, so a pin written now would freeze copy the operator has not accepted, inverting the load-bearing pins-lock-*accepted*-copy rule; (3) WP7e would rewrite them anyway. Phase 1's coverage WAS added in-feature (new group 9 + a group-8 `--dest` assertion, both mutation-verified) precisely because its change genuinely was scaffold wiring — the boundary was applied, not dodged.
- **Suggested action:** WP7e pins, against operator-ACCEPTED copy: `Next Step:` present and LAST in both arms (line-order assertion — the shape Phase-2 verify-self used); per-branch blocks with Branch B carrying NO replay option; ≤3-sentences-per-option; beat survival (the 13-beat greenfield list + brownfield analogues incl. the replay invitation's 4 mechanics); greenfield-only cleanup offer placed AFTER artifacts-as-proof; brownfield having NO cleanup offer and NO deep-dive pointer. **Pin-authoring caveat (learned the hard way):** a naive sentence-count check on this block IS FLAKY — it folds the trailing italic `Housekeeping:` line into the preceding option (produced a false 5/4 where truth was 3/2). Delimit on the `Housekeeping:` line or assert per-option line spans.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-07-21-INSTALL-SH-NO-ORPHAN-PRUNE
- **Source:** feature:build (wp5-disambiguate-pause, Phase 1)
- **Target level:** product:wbs
- **Type:** gap
- **Summary:** `install.sh` is additive-only — after a skill/agent directory is renamed (`git mv skills/session-pause skills/session-handoff`), install.sh creates the new-name symlink but leaves the old-name symlink dangling in `~/.claude/skills/`. A dangling `/session-pause` symlink still surfaces as an "available skill" to the harness but resolves to a non-existent dir. WP5 hit this THREE times in one feature (session-pause, session-resume, session-store-learning renames) and removed each orphan manually (defensive: symlink + dangling + target-in-repo guard) — a clear signal the prune belongs in install.sh.
- **Context:** Any future skill rename hits this. Bites silently — the new skill works, so the stale link is easy to miss. `uninstall.sh` already has the "symlink + target-into-repo" removal primitive; install.sh could reuse it to prune symlinks in `~/.claude/skills/` (and `~/.claude/agents/`) whose target no longer exists.
- **Suggested action:** Add an orphan-prune pass to `install.sh` — after linking, iterate `~/.claude/{skills,agents}/*`, and for each symlink that (a) points into this repo AND (b) is dangling, remove it. Mirror uninstall.sh's defensive guard. Small task.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-07-21-MOVED-PRODUCT-DOCS-INTERNAL-PATH-REFS
- **Source:** feature:verify-codify (doc-layout-unification M7 WP2a)
- **Target level:** task:plan (or fold into M7 WP3-M7 arch-resync — operator's call)
- **Type:** gap (scope completion)
- **Summary:** The M7 source sweep rewrote *external* references to the moved dirs but NOT the moved dirs' own internal contents (they moved wholesale via `git mv`). `workflow-system/state/` internals = 0 stale refs (clean). `workflow-system/product/` has 6 docs with internal `docs/product/|workflow/` refs (transitions 11, arch 18, research 12, vision 4, roadmap 3) that are a **MIX requiring per-ref human judgment**, NOT a mechanical sweep.
- **Context:** Two categories: **(A) LIVE operational prose** describing *current* system behavior → should update to new paths (e.g. `vision.md` "state lives in `workflow/wip/`… `docs/product/`", `transitions.md` "log to `workflow/backlog.md`", "persist to `workflow/.session.md`", "archived to `docs/product/archive/`"). **(B) HISTORICAL/subject-matter refs that MUST NOT be rewritten** — rewriting falsifies the record: `arch.md` AD-1 migration mapping ("`docs/product/*` → `workflow-system/product/`" — rewriting the left side is nonsense), `arch.md` P8 back-loop, `research.md` Option-A + blast-radius table, `roadmap.md` M7 goal, and `SURFACE-2026-07-20-CLAUDESK-UNIFY-DOC-FOLDERS` in this very backlog (all describe the OLD layout as the problem being solved). The Phase-15 anti-regression check deliberately does NOT scan the moved dirs' internals precisely because of category (B).
- **Suggested action:** operator decides category-A refs to update (a small, careful per-ref pass — natural fit for WP3-M7's arch-resync, which already edits `arch.md`) and confirms category-B stays as-is. Do NOT mechanically sweep. **Verify the suggested split against the real doc text before editing** (review-finding-actions-are-hypotheses discipline).
- **Priority:** medium (part of completing M7 cleanly; not a correctness blocker — the *emitted*/prompt paths are all correct)
- **Status:** open

## SURFACE-2026-07-21-SESSION-SCENARIO-S2-S12-FRAGILITY
- **Source:** feature:verify-codify (doc-layout-unification M7 WP2a behavioral run)
- **Target level:** task:plan (test-scenario robustness)
- **Type:** tech-debt (pre-existing, surfaced-not-caused by the rename)
- **Summary:** Two session-orchestrator scenarios fail independent of any code change: **S2** (`session:start routes complex feature → feature:spec`) misclassifies the "real-time collaborative editing" prompt (haiku→S10, sonnet→S5 — a genuine routing-fork ambiguity, not fixed by the stronger model); **S12** (`session:autopilot pauses at verify-human`) trips `not_contains_strict` on `/feature-verify-codify`+`auto-chain` when the model benignly *mentions* verify-codify while explaining the pause (the documented `not_contains_strict` fragility). S3 was merely flaky (passed on sonnet retry).
- **Context:** Surfaced during M7 WP2a verify-codify. PROVEN independent of the rename: the S2/S3/S12 scenario blocks are byte-identical pre/post-sweep, and the full `session-start/SKILL.md` diff is 100% path-string substitutions (zero routing/pause-logic changes). Matches two known lessons: `docs/lessons/test-scenario-routing-forks.md` (S2) and `docs/lessons/test-scenario-strict-mode.md` (S12 — strict mode is only for failure-proxy phrases, not informational ones in benign reasoning).
- **Suggested action:** `/task-plan` — for S12, reconsider whether `/feature-verify-codify` belongs in the strict `not_contains` set (mentioning the next step while pausing is benign); for S2, either sharpen the complex-vs-simple routing signal or accept it as a genuine judgment-call scenario. **Verify against the real scenario+skill before editing** (the suggested fix is a hypothesis).
- **Priority:** low
- **Status:** open

## SURFACE-2026-07-15-BACKLOG-POINTER-BODY-COUPLING-UNPINNED
- **Source:** feature:review-quality (delete-on-resolve-backlog-convention MAJOR)
- **Target level:** task:plan (test-harness / structural-check enhancement)
- **Type:** gap
- **Summary:** The `backlog.md` pointer-stub ↔ `backlog-quality-findings.md` body coupling has NO structural check. The delete-on-resolve feature's migration left 4 orphaned pointer stubs (bodies already swept) that green structural (416/0) + green scenarios + green verify-self all missed — only the review-quality reviewer caught them. A `check-structure.sh` pin asserting "every `## Code-quality findings — <feat>` pointer in backlog.md has a matching `# <feat>` group in backlog-quality-findings.md, and vice-versa" would catch this class mechanically.
- **Context:** Also relevant: verify-self's nothing-open-lost check is one-directional; the inverse (nothing-resolved-retained) has no automated guard. The pointer↔body pin is the higher-value, more-mechanizable half.
- **Suggested action:** `/task-plan` — add a structural check pinning bidirectional pointer↔body coupling for the two backlog files. Verify against the current 2 legit pointers (memory-location-symlink, wp6) before pinning.
- **Priority:** low
- **Status:** open

## SURFACE-2026-07-21-RUN-TESTS-ID-DRYRUN-STILL-WALKS-ALL-FILES
- **Source:** feature:build (boundary-handoff-autochain Phase 3 P3.2)
- **Target level:** task:plan (test-harness perf, minor)
- **Type:** tech-debt
- **Summary:** After the P3.1 `--id` pre-parse fix, a targeted `--id`/`--group` run is no longer slow (22× fewer parses) but still **walks every group file** parsing each scenario's `id` (~22s for a single-id `--dry-run` across all 8 groups / ~194 scenarios). The hang is gone; near-instant is still possible.
- **Context:** The remaining cost is one cheap `id` parse per scenario in every file, even for a `--group session --id X` run that only needs one file. A per-file `id`-prescan (grep the `id:` lines once per file instead of per-scenario python spawns), or skipping non-`--group` files entirely when `--group` is set, would cut targeted runs to near-instant.
- **Suggested action:** `/task-plan` — (a) when `--group` is set, skip non-matching group files before the per-scenario loop; (b) optionally replace the per-scenario `id` python-parse with a single grep-based `id:`-line prescan per file. Low priority — the blocking bug is already fixed.
- **Priority:** low
- **Status:** open

## SURFACE-2026-07-13-STEP0-PREAMBLE-VS-PROCEDURE-RENUMBER
- **Source:** operator observation during backlog-paydown WP4 (2026-07-13)
- **Target level:** task:plan (prose-only skill-structure cleanup; sizing TBD — may touch several skills)
- **Type:** tech-debt (doc-structure clarity)
- **Summary:** Several skills use a `## Step 0: <name>` **top-level** heading as a pre-procedure preamble, then a *separate* `### 1. / ### 2. …` numbered list under `## Procedure`. The dual numbering scheme (a "Step 0" that isn't part of the `### 1/2/3` sequence) reads awkwardly and confuses "is Step 0 the first procedure step or a preamble?". Renumber/reframe so the step scheme is coherent — e.g. make the preamble un-numbered ("## Preamble: …" or "## Before you start") OR fold it into a `### 0.`/`### 1.` that's actually part of the procedure sequence.
- **Context:** Surfaced while doing WP4 (which only renames the design-priors consult *suffix* to disambiguate from the pinned entry-point `## Step 0: Available product context` convention — it does NOT touch the numbering). The renumber is a broader, separate cleanup: it likely spans all skills carrying a `## Step 0` (the 6 entry-point skills + the 2 renamed by WP4), and must stay consistent with the Phase-3 structural pins that assert the literal `## Step 0: Available product context` string for entry-point skills — so any rename of the entry-point heading requires a matching Phase-3 pin update (tripartite-sync discipline). Do NOT bundle into WP4.
- **Suggested action:** `/task-plan` — decide the coherent scheme, apply across all `## Step 0`-bearing skills, update the Phase-3 pins to match. Property-check the pin strings after.
- **Priority:** low
- **Status:** open

## Code-quality findings — wp7k-full-product-cycle-tour (2026-07-24)
- **Pointer:** 1 MINOR finding (feature-review-quality, ship 8bbf5c1, drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. The frontmatter `description` stage-chain `(vision → roadmap → arch → wbs)` drops `research` vs. the 5-stage body/spine form — a minor user-facing inconsistency, **verified inherited verbatim from the design §6 draft description** (not introduced by the build). Full body in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low
- **Status:** pending
- **Pickup shape:** trivial 1-word frontmatter insert; **best folded into WP7e** (the copy-freeze pass against operator-accepted batch-walkthrough copy — the description may be re-touched there anyway), or a `/util-backlog-paydown` sweep. **Verify against the real code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — wp7j-replay-invite-brownfield-git-safety (2026-07-23)
- **Pointer:** 3 MINOR findings (feature-review-quality, ship f90446d, drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. (1) flow-doc says "cross real session boundaries, NOT by narrating," but both arms' Step 7 permit an in-place-narration fallback — a reconciliation seam a future editor should settle (WP7e territory); (2) wbs 7j.3–7j.6 checkboxes stale `[ ]` at ship though shipped in the commit — likely auto-resolved at product-finalize wbs resync; (3) Step-0 brownfield git-safety convergence line says "relaunch in **this directory**" but the safe-copy/different-project escape branch means it may not be this directory. Full bodies in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** all trivial coherence/housekeeping; #1 fold into WP7e (the narrate-vs-do-for-real tension is a codify decision), #2 verify at product-finalize (likely already fixed), #3 trivial 1-line copy tweak. **Verify each against the real code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — wp7i-richer-greenfield-sample (2026-07-22)
- **Pointer:** 3 MINOR findings (feature-review-quality, ship 5ca1723, drive_mode=autopilot → auto-backlogged). 0 CRITICAL / 0 MAJOR. (1) `lib/done.sh:30` opaque `${line#??? }` 4-char-prefix strip — a naming comment would help (cosmetic); (2) smoke group [5] independence check assumes the copied `todo` is present (robustness nit); (3) `sample/todos.txt` tracked 0-byte store — a stray in-source run dirties it, but **reviewer: no change recommended** (tour always stamps a fresh copy; it's the intended teaching surface). Full bodies in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** all trivial; fold into a `/util-backlog-paydown` sweep or any future touch of the scaffold/smoke. #3 is likely close-as-wontfix. **Verify each against the real code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — wp7a-onboarding-flow-spec (2026-07-22)
- **Pointer:** 1 MINOR finding remaining (2 of the original 3 RESOLVED by WP7d — SPLIT-GREENFIELD-GROUNDING + SECTION3-LEGEND-NO-DISPOSITION-TOKENS, see CHANGELOG). Remaining: §5b permission-mode table's `acceptEdits` middle column overstates "safe FS cmds auto" (precision nit in the one correcting section — the reassurance copy is already airtight; tighten when the §5b table is next touched). Full body in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low
- **Status:** pending
- **Pickup shape:** trivial precision edit to the §5b table middle column; verify against the Claude Code permission-modes docs + the real doc text first (review-finding-actions-are-hypotheses). Bundle into the next `/util-backlog-paydown` sweep.

## Code-quality findings — boundary-handoff-autochain-state-machine (2026-07-21)
- **Pointer:** 3 MINOR findings (feature-review-quality, ship 3104205), all cosmetic/docs: (1) `transitions.md` S-ID gap (S19/S21 unused) undocumented; (2) the "table is authoritative" guard bullet nested at 5-space instead of 3-space peer across the 4 AGENTS.md; (3) S29's `not_contains: TRANSITION: S17` is near-inert. Full bodies in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** all trivial docs/test-nit edits — bundle into the next `/util-backlog-paydown` sweep. **Verify each against the code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — doc-layout-unification (2026-07-21)
- **Pointer:** 1 MINOR finding remaining (3 of the original 4 RESOLVED by the 2026-07-21 post-ship refactor — see CHANGELOG). Remaining: `run()` uses `eval "$*"` (quoting fragility inherited from `tools/memory-link/`; a path with embedded `"`/`$` would break — not triggered by the known doc-path input set). Full body in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low
- **Status:** pending
- **Pickup shape:** small — swap `eval "$*"` for a `"$@"`-based dispatch in `migrate-doc-layout.sh`; ideally fixed together with the identical pattern in `tools/memory-link/` since it's a shared inherited smell. Not urgent (no known-input trigger). **Verify against the code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — wp6-research-cost-tier-disambiguation (2026-07-21)
- **Pointer:** 3 MINOR findings (feature-review-quality, ship 17fe152). (1) QR2 scenario `contains_any` includes prompt-answerable `"80"`/`"443"` anchors that dilute the assertion — **cheap+safe fix**; (2) quick-research `description` is dense (~55 words) — cosmetic; (3) the "never auto-launch" confirm-gate clause is prose-only across 3 surfaces with no placement-level pin — latent-drift guard. Full bodies in [`workflow-system/state/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** finding (1) is the strong next-`/feature-refactor`-or-sweep pickup (drop the two port-number anchors from QR2, keep `"confidence"`/`"settled"`); (2)+(3) are optional polish. **Verify against the code first (review-finding-actions-are-hypotheses).**

## Code-quality findings — memory-location-symlink (2026-07-03)
- **Pointer:** 2 MINOR findings auto-backlogged by feature-review-quality against ship commit d173bd7 — (1) `ensure-memory-link.sh` dry-run emits a stray `cd: No such file` on stderr when repo target dir doesn't exist yet + harness already symlinked (diagnostic noise, verdict correct); (2) the "any project with docs/product/" migration scope rule is prose-only, not script-enforced (acceptable given the P2.2 operator-confirmation gate). The 2 MAJOR findings from the same review were fixed in-place (amended into the ship commit) — see the WIP `## Code-Quality Review` section. Full bodies in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** small task — (1) is a ~2-line dry-run guard; (2) is a one-line README prose softening. Bundle into a `/task-plan` or the next `/util-backlog-paydown` sweep.

## MAYBE

_(no open items)_

---

## Buried

The following items were buried by user decision. Full content preserved in [`workflow/backlog-deferred-2026-05.md`](backlog-deferred-2026-05.md).

Buried 2026-06-07:
- `SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER` — bulk-delete safety pattern (CLAUDE.md convention proposal).
- `SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING` — audit-method gap; destructuring patterns require their own grep.
- `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` — codify plan-time downstream-contract grep into `feature-plan` SKILL.md.
- `SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD` — `docs/product/wbs.md` exceeds 300-line size guard.
- `SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG` — `--db` silently overrides `$CLAUDE_TIME_DIR` for config lookup.
- `SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE` — `session_id[:8]` truncation can collide in synthetic test data.
- `SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL-DOESNT-REACH-REACT` — synthetic `WheelEvent` dispatch doesn't reach React's `onWheel`.
- `SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT` — structural check missing; frontmatter `name:` vs. parent dir.

Buried 2026-06-12:
- `SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE` — borrow obra/superpowers' behavioral pressure tests for skill rationalization-resistance.


## SURFACE-2026-06-25-AUDIT-PROMPT-LATITUDE-NEWER-CLIENT-MODEL
- **Source:** incident:resolve (incident-autopilot-askuserquestion-pauses)
- **Target level:** task:plan
- **Type:** tech-debt
- **Summary:** The AskUserQuestion-on-AUTO regression and the earlier auto-branching regression (commit 73e97e2) are two instances of one class: a newer client / Opus 4.8 acting on latitude the prompts never explicitly closed. Each was fixed reactively after biting. A proactive audit of the instruction surface (SKILL.md + AGENTS.md + CLAUDE.snippet.md) for other "implicitly-forbidden-but-never-named" behaviors a more capable/agentic model might reach for (e.g. unrequested branching, spawning subagents, web fetches, file deletions on AUTO paths) would close the class instead of waiting for the next instance.
- **Context:** See `workflow/archive/incident-autopilot-askuserquestion-pauses.md` (Root Cause + F5) — two data points established the class.
- **Priority:** medium
- **Status:** pending

## SURFACE-2026-07-14-HARNESS-BUDGET-EXHAUSTION-LAUNDERED-AS-FLAKY
- **Source:** feature:verify-self (WP6 of backlog-paydown-2026-07-13)
- **Target level:** task:plan (test-harness observability)
- **Type:** gap
- **Summary:** `tests/run-tests.sh` silently launders a per-attempt `Error: Exceeded USD budget` into a generic FAIL→retry→FLAKY, so the operator cannot distinguish "model is nondeterministic" (real FLAKY) from "scenario hit the budget ceiling" (a cost/config issue). The runner already computes the string `"possibly budget exceeded or error"` (run-tests.sh:~245) but only for *totally empty* output, and never surfaces it in the FLAKY list or results JSON.
- **Context:** The per-scenario `budget:` key (the original (b) half) shipped in WP6 of backlog-paydown-2026-07-13 (see CHANGELOG). This entry now tracks only the remaining (a) half — the observability fix. Affects any expensive scenario (session-store-learning full-policy-reasoning, product-* decomposition, etc.) on sonnet.
- **Suggested action:** Detect the `Error: Exceeded USD budget` sentinel in `result_text` and label it distinctly in the FLAKY/FAIL detail + results JSON (e.g. status `BUDGET_EXCEEDED` or a `budget_exceeded: true` field), so a budget-driven retry-pass is visibly different from a nondeterminism-driven one. Cheap, high-value.
- **Priority:** medium
- **Status:** open (remaining (a) observability half; the (b) per-scenario budget key already shipped — recorded in CHANGELOG)

## Code-quality findings — wp6-per-scenario-claude-md-fixture-and-neutral-consult (2026-07-14)
- **Pointer:** 3 MINOR findings from feature-review-quality (WP6 ship e2494f9), all on the check-structure.sh [Phase 3f] property-test: (1) `_resolve_claude_md` mirrors the runner branch rather than exercising it — add lockstep-comment; (2) line-number refs in Phase 3f comments rot — anchor on a stable string; (3) `_pt_claude` `grep -q`→`grep -qF` hardening. Full bodies in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** all 3 are cheap+safe 1-line edits (#1/#3 apply directly; #2's exact line numbers need verifying against the committed file first per the "review-finding suggested-actions are hypotheses" Context Rule). Natural candidates for the next `/util-backlog-paydown` sweep or a small `/task-plan`.


---

## Inbound from Claudesk (handoff 2026-07-20 — not yet triaged into TODO order)

> These five SURFACEs were handed over by the **Claudesk** project (`/Users/stayman/Personal/projects/claudesk`) as this repo's part of the "secondary non-workflow user" work — see [`HANDOFF-from-claudesk-2026-07-20.md`](../HANDOFF-from-claudesk-2026-07-20.md) at this repo's root for full context, the cross-repo split, suggested sequencing, and the return contract. Claudesk gates all its workflow-coupled UI behind an opt-in with a one-time evangelistic invite + onboarding; that made these skill-system-owned items load-bearing. **Claudesk's M10.9 (gate + rich invite) is scheduled AFTER this repo ships these** — so triage + address them, then send the canonical install copy / settled folder layout / onboarding flow back to Claudesk. Suggested order (refine at your next `/product-roadmap`): #2 folder-unify → #1 install/uninstall → #3/#4 disambiguation → #5 onboarding. **UPDATE 2026-07-21: #2 folder-unify (Milestone 7) + #1 uninstall (Milestone 8) + #3/#4 research-collision (Milestone 10) + #? pause-disambiguation (Milestone 9, WP5) SHIPPED** — their SURFACEs (CLAUDESK-UNIFY-DOC-FOLDERS, CLAUDESK-STANDALONE-UNINSTALL, CLAUDESK-RESEARCH-SKILL-COLLISION, CLAUDESK-PAUSE-AMBIGUITY) are resolved + deleted per delete-on-resolve; see CHANGELOG. The remaining 1 (onboarding = WP7/M11) is still open below.

## SURFACE-2026-07-20-CLAUDESK-ONBOARDING-DESIGN
- **Source:** Claudesk handoff 2026-07-20.
- **Target level:** product:vision / product:roadmap (a new-user on-ramp for the workflow system).
- **Type:** new-work (onboarding UX; brainstorm-first).
- **Summary:** Design the new-user onboarding + "aha" moments for someone brand-new to the workflow system (whom Claudesk will invite in). What does a first-time user do first? What's the fastest moment the workflow's value clicks? Does it need a **dedicated onboarding skill** and/or a **throwaway tutorial project** to practice on? **Explicitly brainstorm-first — not yet specced;** the operator wants to brainstorm this together.
- **Context:** Claudesk will *render* the onboarding surface but the *content + flow* is this repo's — it's a property of the workflow system, not the app. Depends on the settled folder layout (#2) + install flow (#1) to build a coherent first-run story, so likely sequenced last. The onboarding flow spec is part of the return contract to Claudesk.
- **Priority:** medium (the payoff of inviting users at all; do after layout + install settle).
- **Status:** pending (inbound; brainstorm-first; not yet ordered).

## Code-quality findings — uninstall-sh (2026-07-21)
- **Pointer:** 1 MINOR finding auto-backlogged by feature-review-quality against ship commit d7e9075 — `remove_link` header comment lists outcome cases in reverse of the code's check order (harmless doc/read-order polish). The MAJOR (arg-parser `--project` flag-shaped-value → real uninstall) + its sibling MINOR (missing `--project` value → silent exit 1) were FIXED in the post-ship refactor per operator's refactor-now choice. Full body in [`backlog-quality-findings.md`](backlog-quality-findings.md).
- **Priority:** low
- **Status:** pending
- **Pickup shape:** trivial — reorder the comment; bundle into next `/util-backlog-paydown` or a docs-only task. **Verify against the code first (review-finding-actions-are-hypotheses).**
