# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention). **Code-quality findings** auto-backlogged by `feature-review-quality` are pointer-collapsed here — full content lives in `workflow/backlog-quality-findings.md`, grouped by source feature.

---

## TODO

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

## SURFACE-2026-07-15-RUN-TESTS-ID-FILTER-PARSES-ALL-SCENARIOS-FIRST
- **Source:** feature:build (delete-on-resolve-backlog-convention Phase 3 P3.3)
- **Target level:** task:plan (test-harness perf/UX)
- **Type:** tech-debt
- **Summary:** `tests/run-tests.sh --id <ids>` parses **every** scenario in all group YAMLs before applying the `--id` filter, so even a `--dry-run` of 4 targeted IDs exceeds 60s (never printed within the timeout). The filter is applied post-parse (run-tests.sh:~155-164), so targeting a tiny subset gets no speedup over a full parse.
- **Context:** Discovered while confirming the 4 delete-on-resolve scenarios. The real (model-executing) run of 4 scenarios took 105s and worked fine — the slowness is purely the parse-before-filter in `--dry-run` / setup. Low-value to fix (the real run works; dry-run is a convenience), but a short-circuit (skip parsing a scenario's body when its `id` doesn't match `--id`) would make `--dry-run --id` and small `--id` batches near-instant.
- **Suggested action:** `/task-plan` — move the `--id` match to a cheap pre-parse `id:`-line scan so non-matching scenarios are skipped before full parse. Property-check against `--id` single/multi/none + `--group`.
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

> These five SURFACEs were handed over by the **Claudesk** project (`/Users/stayman/Personal/projects/claudesk`) as this repo's part of the "secondary non-workflow user" work — see [`HANDOFF-from-claudesk-2026-07-20.md`](../HANDOFF-from-claudesk-2026-07-20.md) at this repo's root for full context, the cross-repo split, suggested sequencing, and the return contract. Claudesk gates all its workflow-coupled UI behind an opt-in with a one-time evangelistic invite + onboarding; that made these skill-system-owned items load-bearing. **Claudesk's M10.9 (gate + rich invite) is scheduled AFTER this repo ships these** — so triage + address them, then send the canonical install copy / settled folder layout / onboarding flow back to Claudesk. Suggested order (refine at your next `/product-roadmap`): #2 folder-unify → #1 install/uninstall → #3/#4 disambiguation → #5 onboarding.

## SURFACE-2026-07-20-CLAUDESK-STANDALONE-UNINSTALL
- **Source:** Claudesk handoff 2026-07-20 (secondary-non-workflow-user gate design).
- **Target level:** product:roadmap / task (install tooling).
- **Type:** gap (missing standalone uninstall; install must be single source of truth).
- **Summary:** Add a standalone `uninstall.sh` (works with **zero** Claudesk dependency) that cleanly reverses everything `install.sh` sets up — the skill/agent symlinks into `~/.claude/`, the `~/.claude/settings.json` hook registration, the per-project memory symlink. Keep `install.sh` as the canonical single source of truth for the install steps (Claudesk's invite will *display* these, not hardcode them).
- **Context:** Claudesk offers a one-click *disable* (its own UI flip) + an evangelistic invite to install this workflow system. De-frictioning "try the workflow system + Claudesk together, then cleanly remove it if not for me" needs a real standalone uninstall — the skill system must be removable without Claudesk in the loop, leaving no residue.
- **Priority:** medium (unblocks Claudesk's invite + the try-and-back-out story).
- **Status:** pending (inbound; not yet ordered).

## SURFACE-2026-07-20-CLAUDESK-UNIFY-DOC-FOLDERS
- **Source:** Claudesk handoff 2026-07-20.
- **Target level:** product:roadmap (a doc-convention change touching every workflow skill that reads/writes these paths).
- **Type:** new-work / refactor (new-user ergonomics).
- **Summary:** Unify the split workflow-doc layout (`docs/product/*.md` strategic + `workflow/*` operational) into a friendlier single top-level layout for users **new** to the workflow — one place to learn, not two. Layout name/shape TBD (co-locate or a single indexed root).
- **Context:** The split is second nature to the author but a two-location learning cost for a new user Claudesk is inviting in. **⚠️ Cross-repo coupling:** Claudesk M11's Docs viewer auto-discovers this exact doc set (`docs/product/*.md` incl. `*wbs*`, `workflow/wip/*.md`, `workflow/backlog.md`, `workflow/.session.md`) — if this layout changes, the settled layout must be sent back to Claudesk so its `docs_list` discovery follows (see the handoff's return contract). Decide the layout here; Claudesk adapts to it.
- **Priority:** medium (foundational — everything else references the layout; do first).
- **Status:** pending (inbound; not yet ordered).

## SURFACE-2026-07-20-CLAUDESK-PAUSE-AMBIGUITY
- **Source:** Claudesk handoff 2026-07-20 (operator-observed).
- **Target level:** skill/orchestrator prompts.
- **Type:** ambiguity / correctness (wrong-intent risk).
- **Summary:** The bare word "pause" is overloaded: sometimes the operator means *interrupt/course-correct the current work mid-flight*, other times *invoke the `session-pause` skill*. Disambiguate in the orchestrator/skill prompts — e.g. reserve bare "pause" for course-correction and require explicit `/session-pause` (or a distinct phrase) for the skill, or have the orchestrator confirm intent when the word is ambiguous.
- **Context:** A misfire either drops a session-pause the operator wanted, or writes a `.session.md` when they only meant "stop and reconsider." Lives in this repo's prompts, not Claudesk.
- **Priority:** medium (small, independent; can run in parallel).
- **Status:** pending (inbound; not yet ordered).

## SURFACE-2026-07-20-CLAUDESK-RESEARCH-SKILL-COLLISION
- **Source:** Claudesk handoff 2026-07-20 (operator-observed).
- **Target level:** skill naming / orchestrator prompts.
- **Type:** naming collision (wrong-skill-fires risk).
- **Summary:** Claude Code shipped a built-in **deep-research** skill/capability; this repo has `product-research` + `feature-research`. "research" now overlaps and can fire the wrong one. Rename/namespace this repo's research skills, or add orchestrator disambiguation, so the workflow research skills don't collide with CC's built-in deep-research.
- **Context:** Operator says "research" → risk of the built-in deep-research firing instead of the workflow's product/feature research (or vice versa). Independent of the other items.
- **Priority:** medium (small, independent; can run in parallel).
- **Status:** pending (inbound; not yet ordered).

## SURFACE-2026-07-20-CLAUDESK-ONBOARDING-DESIGN
- **Source:** Claudesk handoff 2026-07-20.
- **Target level:** product:vision / product:roadmap (a new-user on-ramp for the workflow system).
- **Type:** new-work (onboarding UX; brainstorm-first).
- **Summary:** Design the new-user onboarding + "aha" moments for someone brand-new to the workflow system (whom Claudesk will invite in). What does a first-time user do first? What's the fastest moment the workflow's value clicks? Does it need a **dedicated onboarding skill** and/or a **throwaway tutorial project** to practice on? **Explicitly brainstorm-first — not yet specced;** the operator wants to brainstorm this together.
- **Context:** Claudesk will *render* the onboarding surface but the *content + flow* is this repo's — it's a property of the workflow system, not the app. Depends on the settled folder layout (#2) + install flow (#1) to build a coherent first-run story, so likely sequenced last. The onboarding flow spec is part of the return contract to Claudesk.
- **Priority:** medium (the payoff of inviting users at all; do after layout + install settle).
- **Status:** pending (inbound; brainstorm-first; not yet ordered).
