# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-07. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention).

---

## TODO

## SURFACE-2026-06-09-GREP-CHECK-HELPER-PIPEFAIL-INTERACTION
- **Order:** P-NEW (pending user re-ordering)
- **Source:** feature:verify-codify (check-structure-sigterm-propagation, 2026-06-09) — surfaced as pre-existing tech debt during the design of 2 new negative pins. Same root cause hit me twice during this feature's verify-codify.
- **Target level:** task:plan (small/simple — fix the helper's count-capture pattern + one-line audit of existing call sites)
- **Type:** tech-debt / latent bug
- **Summary:** `tests/check-structure.sh` line 38 (`grep_check` helper) uses `count=$(grep -cE "$pattern" "$file" 2>/dev/null || echo 0)`. Under the script's `set -euo pipefail`: when grep finds 0 matches, it exits 1 — so the `|| echo 0` ALSO fires, AND the original grep's stdout (`0\n`) is also captured. Result: `count="0\n0"` (literal 3-char string with embedded newline), not `0`. The subsequent `[ "$count" -ge "$min_count" ]` then fails with "integer expression expected" — except inside the helper, the failure is silently absorbed because the helper itself isn't `|| true`-protected... actually it might propagate via `set -e`. Confirmed empirically during the feature: my own initial pin code used the same `|| echo 0` pattern and produced `n="0\n0"`, causing `[ "$n" = "0" ]` to evaluate false and the pin to FAIL even with no matches. Fixed in my new pins via `n=$( (grep ... || true) | head -1 )`; the existing helper has NOT been audited or fixed.
- **Context:** Every existing `grep_check` call in `tests/check-structure.sh` could in principle hit this when its pattern matches 0 lines. The reason it hasn't broken catastrophically is that `grep_check` is mostly used for positive pins (expected ≥1 match, so `count` rarely starts at 0). The bug bites the rare case where a `grep_check` is used to verify "this file exists with at least N entries" and the entry count drops to 0 — instead of getting a clean FAIL message, the script may abort early per `set -e`. Latent, not currently triggering.
- **Suggested action:** Update the helper's count-capture to: `count=$( (grep -cE "$pattern" "$file" 2>/dev/null || true) | head -1 )` followed by `count="${count:-0}"`. Then audit any callers that pass `min_count=0` (allowed-form pins) — none expected since most pins are `≥1`. Single ~3-line change.
- **Priority:** low — latent bug, not currently triggering; would surface only if a future pin's matched-count drops to 0.
- **Status:** pending

## SURFACE-2026-05-29-VERIFY-SELF-IN-PLACE-FIX-SHORTCUT-POLICY
- **Order:** P1
- **Source:** v3 WP3 Phase 2 verify-self (2026-05-29) — `feature-verify-self` is contractually observe-only with BLOCKING fails going through F9b back-loop to `feature-build`. When the alias-key audit miss surfaced (P2.4), I shortcut that to in-place fix within verify-self because the bug was a one-line extension of the just-completed leaf AND the re-verification went through a fresh Playwright subagent (same audit-trail artifact as a formal back-loop would produce). User approved the shortcut at verify-human ack but acknowledged it as a procedure deviation.
- **Target level:** harness / skill (`skills/feature-verify-self/SKILL.md`)
- **Type:** policy clarification / workflow refinement
- **Summary:** verify-self's "observe-only" rule produces friction when the fix is genuinely trivial (one-line extension of just-built code) and the re-verification artifact is equivalent to what a F9b back-loop would produce. Formal back-loop in those cases costs 3 extra Skill invocations (build → verify-auto → verify-self) for the same outcome. Worth codifying either: (a) verify-self may fix-in-place when the fix is a trivial extension of the just-completed leaf AND re-verification goes through a fresh subagent, with explicit `## Discoveries` audit-trail entry; OR (b) keep the strict observe-only rule but make F9b → F8 chain auto-fast for trivial-fix back-loops.
- **Why it matters:** Drive-mode AUTOPILOT amplifies this — every back-loop is 3 Skill invocations of overhead. As the workflow system matures, observed friction patterns warrant explicit policy rather than ad-hoc deviations.
- **Proposed fix:** Update `skills/feature-verify-self/SKILL.md` §3 with an explicit "in-place fix" sub-clause OR add a "Same-state quick-fix" entry to the `debug-*` skill category. Either route, the audit-trail discipline (entry in `## Discoveries` describing what was fixed + how it was re-verified) becomes the gate.
- **Priority:** low-medium — a real but bounded friction; rule-of-three reached 2026-06-07 (v3 WP3 Phase 2, v3 WP11 Phase 1, verify-human-auto-skip-when-no-integration-boundary Phase 2). Project CLAUDE.md line 240 says "ready to formalize."
- **Status:** resolved 2026-06-09 — feature `verify-self-in-place-fix-shortcut-policy` shipped (commit b097ac0). Option (a) chosen: explicit triple-gated "In-place fix shortcut" sub-clause in `skills/feature-verify-self/SKILL.md` §3 + structural-check pins + F10b-shortcut behavioral scenario.

## SURFACE-2026-06-07-CHECK-STRUCTURE-DRY-RUN-CONCURRENCY-FRAGILE
- **Order:** P2
- **Source:** feature:build — long-cmd-timeout-and-exclusive-resource-concurrency Phase 1 P1.4 (2026-06-07).
- **Target level:** project (tests/check-structure.sh + project CLAUDE.md prior-runtime note)
- **Type:** tech-debt / concurrency-fragility
- **Summary:** `tests/check-structure.sh` Phase 1 invokes `./tests/run-tests.sh --dry-run` (line 762) which on this machine takes >5 min — exceeding the harness's 5-min hard Bash cap. Auto-background + the buffered `| tail -30` pipe means the output file stays empty until completion, masking progress. When the parent `check-structure.sh` is killed (e.g. user cancel or harness-timeout), its child `run-tests.sh --dry-run` does NOT receive SIGTERM and continues running. Subsequent re-invocations stack concurrent dry-runs against `tests/results/` and fixture state — the exact failure mode the new global Long-running-commands rule was just written to prevent. Today's build required `pkill -f run-tests.sh` to clear state before the third invocation could proceed cleanly.
- **Context:** Bites every feature finalize and every shipping pass (`./tests/check-structure.sh` is run before every commit by the verify-codify and ship skills). Today's session burned ~10 min on this concurrency-stacking before the orphaned-child pattern was recognized. The pattern is silent — no error, just an indefinite hang on Phase 1.
- **Suggested action:** Two small fixes: (1) Add a `trap 'pkill -P $$' EXIT` or `exec` discipline in `tests/check-structure.sh` so killing the parent propagates to children; (2) Document `tests/check-structure.sh` runtime ≥ 5 min in project CLAUDE.md under a "Tier-1 dev command runtimes" subsection so future Bash invocations set `timeout: 600000` explicitly. Optionally: profile `run-tests.sh --dry-run` to find why scenario enumeration takes >5 min — if it's reading every fixture for each scenario, an index file would cut the cost.
- **Priority:** medium — bites every finalize/ship run; pattern is the canonical exclusive-resource failure mode in this very repo.
- **Status:** resolved 2026-06-09 — feature `check-structure-sigterm-propagation` shipped (commit d1cd105). Took the "Optional" path from the suggested action (bypass the subprocess entirely) rather than fixes (1) or (2). The recursive-walker trap approach was tried first and failed verify-self twice — bash command-substitution subshells are siblings of the script, not descendants, so no trap walking from `$$` can reach them. Switched to an inlined Python YAML scenario count (replacing line 795's `total=$(./tests/run-tests.sh --dry-run | ...)`), which eliminates the subprocess invocation entirely. Net effect: runtime ~240s → ~16s, orphan-child surface gone, and 4 structural pins in `check-structure.sh` forbid the regressed forms from returning. The (2) doc-note action was already addressed by the global Long-running-commands runtime-registry pattern (runtimes.md updated with new ~16s entry).

## SURFACE-2026-06-06-RUN-ALL-UNBOUND-FORWARD-ARGS
- **Order:** P3
- **Source:** task:act (codify-randomize-host-ports-test-coverage, 2026-06-06) — surfaced while running `./tests/run-all.sh` for T4. Pre-existing harness bug, not introduced by this task.
- **Target level:** task:plan (small/simple — one-line shell fix).
- **Type:** test-infra / harness bug
- **Summary:** `tests/run-all.sh:42` (and `:49`) expand `"${FORWARD_ARGS[@]}"` while `set -u` is on. When `FORWARD_ARGS` is empty (the common case when invoked with no args), expansion fails with `FORWARD_ARGS[@]: unbound variable` and the whole two-pass sweep aborts before Pass 1 runs. The combined-result JSON merge at line 56 never executes, so there's no run-* file produced and exit code is 1. Net effect: `./tests/run-all.sh` (no args) is completely broken on this machine's bash. Repro: `./tests/run-all.sh` → fails immediately. Workaround: use `./tests/run-tests.sh --model haiku --filter-model default` then `./tests/run-tests.sh --model sonnet --filter-model sonnet` manually.
- **Why pre-existing:** the bug is in `set -euo pipefail` + empty-array expansion semantics; it would have fired the moment the script was ever run with no args. Likely the script was only ever validated with `--group <x>` arguments (which populate FORWARD_ARGS). Confirmed by `git log -p tests/run-all.sh` showing the file unchanged across recent commits.
- **Suggested action:** Replace `"${FORWARD_ARGS[@]}"` with `${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}` on both lines (the conditional-expansion idiom that is safe under `set -u` for empty arrays on bash 3.2+). Verify with both `./tests/run-all.sh` (no args) and `./tests/run-all.sh --group product`.
- **Priority:** medium — the wrapper script is the documented end-to-end harness invocation in CLAUDE.md ("two-pass sweep: haiku for untagged, sonnet for those tagged"); the workaround works but defeats the purpose of the wrapper. Any user following the documented flow will hit this.
- **Status:** resolved 2026-06-09 — task `run-all-unbound-forward-args` closed. Applied the suggested `${FORWARD_ARGS[@]+"${FORWARD_ARGS[@]}"}` idiom on lines 42 + 49 (T1) and additionally fixed a sibling `set -o pipefail` + `head`-induced-SIGPIPE bug at lines 43 + 50 (T1b — `P1_FILE=$(ls ... | grep ... | head -1)` propagated exit 141 to `set -e`, killing the script between Pass 1 and Pass 2). The pipefail issue was a pre-existing sibling bug exposed only after T1 let the script reach line 43 for the first time; absorbed into the same task since same file + same bug-family. Verified end-to-end via real `./tests/run-all.sh --group debug` run (exit 0, both passes, combined merge), plus populated-args `--dry-run` regression check (exit 0), plus isolated `set -u` empty-array idiom test.

## SURFACE-2026-06-06-SETTINGS-FIXTURE-MODEL-DRIFT
- **Order:** P4
- **Source:** feature:verify-self (docker-init-randomize-host-ports, 2026-06-06) — pre-existing failure surfaced during structural sweep, not introduced by this feature.
- **Target level:** task:plan (small/simple — one-line fixture update or `INTENTIONAL_DIFFS` entry).
- **Type:** test-infra / fixture drift
- **Summary:** `tests/check-structure.sh` reports 1 FAIL: `settings fixture in sync with live (modulo documented diffs): drift detected — model: live=<missing> fixture="opus[1m]"`. The live `~/.claude/settings.json` no longer has a `model` field (or it's been removed/renamed), but the fixture at `tests/fixtures/settings.json` still asserts `model: "opus[1m]"`. Net effect: structural sweep always shows 124/125, masking real future fixture regressions.
- **Suggested action:** Two options: (a) update `tests/fixtures/settings.json` to drop the `model` field (match live); (b) add the field to `INTENTIONAL_DIFFS` in `tests/check-structure.sh` if the difference is intentionally tolerated. Lean: (a) — the fixture should track live unless there's a reason to pin a specific model harness fingerprint.
- **Priority:** low — masks no real signal today, but every additional drifted field weakens the fixture's value as a regression net.
- **Status:** open

## SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG
- **Order:** P5
- **Source:** feature:verify-codify (finalize-before-ship-order-flip Phase 3 regression slice, 2026-05-13)
- **Target level:** task:plan
- **Type:** test-infra (recon discipline pending)
- **Summary:** 6 verify-codify scenarios SOFT_PASS on haiku but should be tagged `model: sonnet` per the recon discipline documented in CLAUDE.md. F-boundary-codify confirmed: SOFT_PASS on haiku (`/feature-ship` leaks in non-`/feature-ship` scenario), PASS strictly on sonnet (verified 2026-05-13). Other 5 SOFT_PASSes (F14, F15, F16-triage-ambiguous, F16-triage-flaky, F16-triage-regression) fail on output-shape issues (missing TRANSITION line, prose-leak family) — same haiku-noise class. **Extension (2026-05-13 full-sweep):** F13-prefiltered also FAILs on haiku with the "no structured TRANSITION line" pattern — likely same class. Include in the sonnet-tag recon pass.
- **Suggested action:** Apply the documented recon discipline (`see haiku failure → run on sonnet → confirm PASS → tag`). For each of the 6, run on sonnet; for those that PASS strictly, add `model: sonnet` to the scenario in `tests/scenarios/feature.yaml` and a one-line comment citing the haiku flake pattern. Likely all 6 fall into this category given the failure shapes.
- **Priority:** medium (only matters when running the haiku-only partition; current Phase 3 work was unblocked by recon on the most concerning case)
- **Status:** open

## SURFACE-2026-05-10-I20-SCENARIO-MISSING
- **Order:** P6
- **Source:** feature:verify-codify (incident-codify feature, Phase 3, 2026-05-10)
- **Target level:** task:plan
- **Type:** gap (test coverage)
- **Summary:** I20 (codify → investigate back-loop) has no test scenario. The other three codify transitions (I17, I18, I19) and the defer variant (I18-defer) all have scenarios. I20 is the rare "codify-time evidence reveals investigate's root-cause analysis was wrong" case — distinct from I19 ("mitigation didn't fix the bug, try a different fix").
- **Context:** I20 was approved in verify-human as part of the SKILL.md procedure (kept rather than folded into I19) but the plan's Phase 3 scenario list didn't include it. Without a scenario, the I20 path is documented but uncovered — a future regression on I20 emission would slip through the test sweep.
- **Suggested action:** Add an I20 scenario to `tests/scenarios/incident.yaml`. Fixture: `incident-codify-with-reproduce-artifact.md` (or a new fixture). Prompt should describe codify-time evidence that contradicts the prior investigation's root-cause conclusion (e.g., the failing test passes against the mitigated code, but a different failing condition exists that wasn't part of the original investigation). Expected transition: I20 → /incident-investigate.
- **Priority:** low (the path is rare in practice; cost of adding a scenario is small but not urgent)
- **Status:** open

## SURFACE-2026-06-07-SESSION-RESUME-LEAVES-PAUSE-FOOTER
- **Order:** P7
- **Source:** Cross-project learning from NeoStayman WP30 finalize / session-reflect (2026-06-07). Full learning doc at `/Users/stayman/Personal/projects/neo-stayman-assistant/.claude/learnings/2026-06-07-session-resume-strip-stale-pause-footer.md`. NeoStayman backlog reference: `SURFACE-2026-05-16-SESSION-RESUME-LEAVES-PAUSE-MARKER`.
- **Target level:** harness / skill — `~/.claude/skills/session-resume/SKILL.md` (which is symlinked from this repo's `skills/session-resume/SKILL.md`).
- **Type:** behavioral gap in skill — orphan-footer cleanup miss
- **Summary:** `/session-pause` appends a `## Session Pause — <timestamp>\nPaused. See workflow/.session.md to resume.` block at the END of `state_file` (typically `docs/product/wbs.md` or a WIP file). `/session-resume` deletes `workflow/.session.md` (its current §7) but does NOT strip the orphan footer block from the `state_file` body. Result: every finalize on a paused-then-resumed item incurs a recurring cleanup tax. 18 confirmed recurrences in one project alone (NeoStayman WP4 → WP30); 7 consecutive WPs since WP21 each spending 10–30s scrubbing the footer at finalize time. Cumulative cleanup cost has crossed the skill-patch cost (~5 min) by ~5×.
- **Suggested action:** Patch `~/.claude/skills/session-resume/SKILL.md` to add a step between current §6 (backlog check) and §7 (delete `.session.md`):
  > **6b. Strip the stale Pause footer from `state_file`.** The `## Session Pause — <timestamp>\nPaused. See …` block that `/session-pause` injected must be removed from the `state_file` body. Idempotent — no-op if the marker isn't there. Match pattern: trailing `## Session Pause — ` heading + body up to EOF (current `/session-pause` behavior is always-append). If a future `/session-pause` variant inserts mid-document, extend the match to "until next `## ` heading or EOF."
- **Why it matters:** the cumulative cleanup cost is increasing linearly with the number of pause/resume cycles in any project. Multiple recent observations of this very repo also dirty `workflow/archive/<wip>.md` with pause footers post-resume (see this session's `verify-human-auto-skip-when-no-integration-boundary.md` archive diff). The footer is mechanically removable; only the skill's read-side doesn't currently know to remove it on resume.
- **Risk:** Low. The match pattern is unambiguous (`## Session Pause — ` is unique to the inject path) and the Edit is reversible (preserved in git).
- **Priority:** medium-high — 18+ observed recurrences in one project (rule-of-three is far exceeded); fix is small and reversible; addresses a paper cut that touches every paused workflow.
- **Status:** pending

## SURFACE-2026-05-29-FEATURE-FINALIZE-MISSES-WBS-TASK-CHECKBOXES
- **Order:** P8
- **Source:** v3 WP3 session-resume (2026-05-29) — user observed that v3 WP1 and WP2 task checkboxes in `docs/product/wbs.md` were still `[ ]` despite both WPs being shipped, finalized, and committed (commits `4dd8d6d`, `8d9fc94`, `64fb865`, `c387829`). `feature-finalize` correctly tagged each WP heading with `✅ SHIPPED <date> (commit <sha>)` at the WP level but did not tick the per-task checkboxes (1.1–1.7, 2.1–2.3) underneath. Resume had to do it manually for both WPs.
- **Target level:** harness / skill — `skills/feature-finalize/SKILL.md` WBS-update step.
- **Type:** behavioral gap in close-skill
- **Summary:** `feature-finalize` updates `docs/product/wbs.md` to mark WP-level shipped status but does not propagate completion down to the WP's task list. This is a deterministic miss — every WP finalize since at least v3 cycle start has produced an inconsistency between heading state (✅ SHIPPED) and task-checkbox state (`[ ]` × N).
- **Why it matters:** WBS becomes a partially-trustworthy state surface. Future planning skills (`feature-spec` for downstream WPs, `/product-finalize` cycle-close sweep) read WBS to determine what's actually done. Unticked checkboxes under a ✅ SHIPPED heading muddle the source of truth — and visually suggest "in progress" even when the WP is fully shipped.
- **Proposed fix:** Update `skills/feature-finalize/SKILL.md` WBS-update step: after appending the `✅ SHIPPED <date> (commit <sha>)` tag to the WP heading, ALSO walk the WP's task list and convert each `- [ ]` to `- [x]` (the WP being shipped means by definition all its tasks landed — they're not partial-credit). One-line procedure: "For the WP being finalized, `replace_all` `- [ ]` → `- [x]` *within that WP's section only*." Add a structure-check pin if cheap.
- **Risk:** Low. Tasks that genuinely didn't ship would be ones the WP was descoped on — in which case the WP should be RE-SCOPED in WBS at finalize time, not silently shipped with hidden gaps. The fix surfaces this discipline.
- **Priority:** medium — accumulates technical debt across every WP finalize but isn't a blocker.
- **Updates:**
  - 2026-06-06 (WP11 finalize): **12th consecutive WP affected**. Pre-ticked 11.1-11.6 manually before the auto-ship-marker tag this finalize cycle. Pattern is now overwhelmingly established (12-of-12 WPs since v3 cycle start); the harness fix should be the next available cycle's first task.
- **Status:** pending

## SURFACE-2026-05-22-CLAUDE-MD-MISSING-CLAUDE-TIME-CONTAINER-NOTE
- **Order:** P9
- **Note (2026-06-07):** User flagged "we are already v3, should double check." Verified: project CLAUDE.md still has no mention of `tools/claude-time/test/run-in-container.sh` or the container test path. The doc-gap remains regardless of v3 status. WP5 has long since shipped, so the original "WP5 dirty-tree blocker" no longer applies — the paragraph can be appended cleanly now.
- **Source:** feature:finalize (claude-time-test-containerization, 2026-05-22)
- **Target level:** task:plan (small/simple — single paragraph append)
- **Type:** doc-gap
- **Summary:** Project root `CLAUDE.md` doesn't mention that `tools/claude-time/` tests now run inside a Docker container via `tools/claude-time/test/run-in-container.sh`. The README under `tools/claude-time/` covers it fully, but a contributor reading the project-root CLAUDE.md sees only the workflow-system test invocations and would assume host-side tests are supported.
- **Context:** During finalize of `claude-time-test-containerization`, a brief paragraph was drafted to add under `## Commands` in CLAUDE.md but had to be reverted because of an operator mistake (`git checkout HEAD -- CLAUDE.md` while the file had cross-feature dirty state from WP5 — see lesson logged in retrospect of `claude-time-test-containerization`). Re-adding the paragraph would only collide with WP5's still-uncommitted CLAUDE.md edits; deferring to a clean window.
- **Suggested action:** Append a paragraph under `## Commands` (right after the workflow-system test runner block) explaining: container is the canonical test path for `tools/claude-time/`; lifecycle wrapper at `tools/claude-time/test/run-in-container.sh` (start/stop/status/exec/restart/logs/help); bundles Python 3.12 + Perl + sqlite3 + jq + Node + Playwright + Chromium; project root bind-mounts at `/work` rw; see `tools/claude-time/README.md` → "Running tests" for canonical invocations. ~3 sentences, single hunk.
- **Priority:** low — discoverable from `tools/claude-time/README.md` already; CLAUDE.md note is a nice signal for project-root readers but not a blocker.
- **Status:** open

## SURFACE-2026-05-22-DEBUG-EMPIRICAL-TELEMETRY-SKILL
- **Order:** P10
- **Source:** user request (2026-05-22)
- **Target level:** feature:spec (new `debug-*` sidebar skill — non-trivial design surface: trigger gate, instrumentation playbook, cleanup discipline)
- **Type:** new-work / new debug skill in the agent-pulled sidebar category
- **Summary:** Add a `debug-*` sidebar skill (working name: `debug-empirical-telemetry` or `debug-observe-runtime`) that forces a shift from static-analysis debugging ("read the code, reason about what it does, propose a fix") to empirical observation of the running system ("add logging/timing/counters, run, read the telemetry, then decide"). Triggered after N failed static-reasoning attempts on the same bug, or whenever the bug-shape involves runtime values the agent cannot derive from code alone (DB query plans/timing, race conditions, intermittent failures, perf regressions, "this variable is somehow the wrong value at this line").
- **Context:** Agents (this one included) default to static analysis as the first and often only debugging mode — read code, build a mental model, propose a fix. Real debugging frequently requires runtime evidence: insert prints/logs, add timing instrumentation, dump intermediate state, capture a stack at the failure point, run EXPLAIN on a query, sample a hot loop. Without an explicit prompt to switch modes, the agent loops on the static approach even after it has demonstrably failed. A sidebar skill in the `debug-*` family is the right shape: agent-pulled when stalled, runs to completion, returns to caller. Parallels `debug-bisect-known-good` (also a stall-recovery technique) but with a different mechanism (observation vs. bisection).
- **Suggested action:** Author `skills/debug-empirical-telemetry/SKILL.md` following the `debug-*` category convention (mandatory sections: `## Category Context`, `## When to use`, `## When NOT to use`, `## Procedure` with Gate Check, `## Pitfalls`, `## Termination` with `DEBUG-TELEMETRY-*` tokens + `RETURN-TO:` line). Gate suggestions: (a) ≥2–3 failed static-analysis fix attempts on the same bug, AND (b) the bug involves runtime values the agent cannot derive from code (timing, DB stats, env-dependent state, intermittency, perf). Procedure should walk: pick the smallest observable that would discriminate between current hypotheses → instrument (logging, timing, counter, EXPLAIN, etc.) → run → read telemetry → iterate or hand back a concrete cause. Include a cleanup-discipline step (remove or guard the instrumentation before exit) since stray prints in committed code is a real failure mode. Also: discoverability surfaces per the "new skill category needs three surfaces" lesson — caller-skill prose mentions in `feature-build`/`incident-investigate`/`task-act`, "Debug techniques" subsection rows in each relevant orchestrator AGENTS.md, note in `docs/product/transitions.md` sidebar section. Worth speccing rather than planning directly — the trigger gate and the instrumentation playbook both have non-obvious failure modes (over-instrumenting, leaving prints in code, instrumenting too late after the bug has been "guessed-fixed", picking the wrong observable).
- **Priority:** medium — real recurring agent-behavior gap that costs wall-clock time when it bites, but no active bug forcing it now; pick up after WP5 of claude-time-visualize-v2 or interleave when next debugging an empirical-shaped bug.
- **Status:** open

## SURFACE-2026-06-02-CODE-QUALITY-REVIEWER-SUBAGENT
- **Order:** P11
- **Source:** Comparative analysis of `obra/superpowers` workflow system (2026-06-02). Full report archived at `docs/product/archive/research/2026-06-02-superpowers-comparison.md`. Specific borrow: superpowers' subagent-driven-development pattern dispatches a **code-quality-reviewer subagent** (distinct from a spec-compliance reviewer) on each completed task. Code-quality reviewer reads the implementation against quality criteria (good patterns, appropriate abstractions, testability) — separate from "did it match the spec?" which is a different lens.
- **Target level:** harness / skill — likely a new dedicated review skill, or augmentation of `feature-verify-human` / `feature-finalize`.
- **Type:** new skill or skill augmentation
- **Summary:** This repo currently has no code-quality review pass distinct from spec-compliance verification. `feature-verify-human` mixes "did it do what the plan said?" (binary spec compliance) with "is it well-built?" (judgment-based code quality) — two different questions that benefit from different lenses. Superpowers' separation forces the agent through two distinct passes with different checklists. Worth importing as either: (a) a dedicated reviewer subagent invoked after `feature-verify-human` (or after `feature-build` on a phase) with a curated prompt template (their pattern: store reviewer prompts as separate files referenced from the skill), OR (b) a new leaf in the per-phase verify loop between `verify-human` and `verify-codify` — `verify-code-quality`. Subagent route preserves parent context and matches this repo's "use subagents for isolated review tasks" posture; new-leaf route slots into the existing state machine more naturally.
- **Why it matters:** Current verify loop catches "wrong thing built" (verify-human against observable outcomes) and "regression coverage missing" (verify-codify). The middle question — "is the implementation well-built? are the abstractions right? is it testable? are there obvious smells?" — is currently implicit in human review and inconsistently applied. A dedicated pass with a curated prompt would surface code-quality issues that get missed when the human is checking observable outcomes.
- **Suggested action:** Spec'able feature (not direct plan) — both the placement (new skill vs. augment existing) and the prompt template need design. Open questions: (1) parent-context review vs. subagent dispatch — parent context preserves continuity but pollutes; subagent is fresh-eyes but costs an Agent invocation. (2) Scope — per phase or per feature? Per phase is more granular but more friction. (3) Prompt template — what does a code-quality reviewer for *this* codebase actually check for? Superpowers' `code-quality-reviewer-prompt.md` is a starting point but their patterns may not all transfer.
- **Priority:** medium — real gap in the current verify loop, no active blocker, worth speccing when a feature cycle has space.
- **Status:** open

## SURFACE-2026-05-17-CHEAT-SHEET-AGENTS-DRIFT
- **Order:** P12
- **Source:** incident:resolve (autopilot-pause-policy-recheck-regression, 2026-05-17)
- **Target level:** task:plan (small/simple — single bash/python pass parsing two source files)
- **Type:** gap (test coverage — structural-only check doesn't catch behavioral drift)
- **Summary:** `tests/check-structure.sh` Phase 9 asserts each of the 8 affected feature SKILL.md files contains an `## Orchestrator Pause Policy (cheat-sheet)` block with the `Hard rule for AUTO exits` anchor + 4-mode table row, but does NOT assert that the per-skill table rows *match* the canonical pause-policy table in `agents/feature-workflow/AGENTS.md`. If AGENTS.md changes (e.g. a transition flips PAUSE↔AUTO for a drive mode), the per-skill cheat-sheets could silently drift and continue claiming the old policy.
- **Context:** Phase 9 was added by `incident-codify` as the structural substitute for behavioral red→green coverage (which was unavailable because reproduction was abandoned per `SURFACE-2026-05-17-CLAUDE-PRINT-AGENTIC-LOOP-SUPPRESSES-PAUSE-DECISION`). The structural check catches outright deletion or imperative weakening; the drift case is uncovered.
- **Suggested action:** Extend Phase 9 (or add Phase 10) that:
  1. Parses the pause-policy table from `agents/feature-workflow/AGENTS.md` into a `{skill_or_transition_key: {mode: AUTO|PAUSE|SKIP}}` dict.
  2. For each of the 8 affected SKILL.md files, parses its cheat-sheet table.
  3. Asserts every per-skill row matches the corresponding row in the canonical table.
  Likely 30–60 lines of bash + a small awk/python helper. Single source of truth: AGENTS.md.
- **Priority:** medium (not blocking; the regression mode (drift) is plausible but lower-probability than the regression mode Phase 9 already catches (prose removal/softening)).
- **Status:** pending

## SURFACE-2026-05-08-REPRODUCE-AS-REDIRECT-FROM-BUILD
- **Order:** P13
- **Source:** feature:build (reproduce-step feature, 2026-05-08) — Phase 4 backlog spinout
- **Target level:** feature:spec
- **Type:** workflow-enhancement
- **Summary:** When `feature-build` hits an "I cannot tell if my fix actually worked because I never confirmed the bug" moment, allow REDIRECT into `feature-reproduce` (similar to F22 redirect to research). Currently reproduce is only an entry transition (F31) and post-spec/plan suggestion — there's no path FROM build INTO reproduce.
- **Context:** Useful for bug-fix features that didn't go through reproduce upfront but discover during build that they need a failing-test anchor. Without this transition, the agent has to either (a) continue without confirmation, or (b) abandon and restart at reproduce. A redirect would preserve build state and let reproduce run, then resume.
- **Suggested action:** Add Fnew → build → reproduce REDIRECT transition. Update feature-build SKILL.md to surface this as a valid exit when "could not confirm fix worked" condition holds. Update reproduce SKILL.md to recognize REDIRECT entry and hand back to build.
- **Priority:** low (deferred — wait until we observe the need in practice)
- **Status:** open

---

## MAYBE

Parked items. Revisit after the TODO list is drained. Unordered.

## SURFACE-2026-06-06-VERIFY-SH-NO-HARD-CONTENT-ASSERT
- **Priority:** MAYBE
- **Source:** task:act (codify-randomize-host-ports-test-coverage, 2026-06-06) — discovered during T5 bite-verification while trying to add a behavioral content-presence assertion (P10b).
- **Target level:** feature:spec (small/medium — adds a new assertion shape to the test harness; touches `tests/lib/verify.sh`, scenarios, and the doc-side `## Conventions` block).
- **Type:** harness limitation / missing primitive
- **Summary:** `tests/lib/verify.sh::verify_result` (lines 70-82) treats a matching `transition_id` as **authoritative PASS** and never re-examines `contains_any` once that match fires. `contains_any` is only consulted as a SOFT_PASS fallback when no `transition_id` match was found. Net effect: no scenario in the current harness can hard-assert content presence. If you write `transition_id: X` + `contains_any: [Y, Z]` intending "must contain Y or Z AND emit X," you actually get "emit X (Y and Z are checked only if X fails)." Confirmed by 2x bite-verification (2026-06-06): mutated SKILL.md to remove the randomize-host-ports bullet, ran the candidate P10b scenario with `contains_any` set to literal SKILL.md prose anchors (first weak: `ephemeral|49152|randomize`; then strong: `lsof -nP -iTCP|random.randint(49152, 65535)|58329:5173`) — both passed because the model still emitted `TRANSITION: P10` correctly, and the harness short-circuited.
- **Why it matters:** Several conventions in CLAUDE.md (e.g. the integration-boundary rule's "verify-codify must include a test on the consuming surface") presuppose that scenarios can test *content* of the surface, not just transitions. Today they can't — only structural `grep_check` pins in `tests/check-structure.sh` actually hard-assert content, and those don't exercise the model. The P10b case landed cleanly on the structural-pin side (see the same task), but a future feature whose only verifiable surface is "the model emits the right downstream prose under a real skill invocation" has no harness primitive available.
- **Suggested action:** Add a new `contains_required` (or `must_contain_all` / `contains_required_any`) field to the scenario schema. Semantics: when set, even on a `transition_id` match, ALL (or ANY) of the listed strings must appear in `result_text` or the scenario FAILs. Implementation is small: a new check between lines 71 and 82 of verify.sh. Update `## Conventions` block in `CLAUDE.md` (the bullet about `expect:` fields) to document the new field. Pilot use: re-introduce a P10b-equivalent scenario with `contains_required: [<SKILL.md-prose anchor>]` once the primitive lands.
- **Original priority:** medium — current workaround (structural `grep_check` pins) covers most prose-presence regressions, but the gap will bite the moment a feature ships prose that's only meaningful when the model is actually invoking the skill (not just whether the file contains it).
- **Status:** pending

## SURFACE-2026-05-22-LEARNING-COMMIT-OFTEN-AT-CROSS-FEATURE-BRANCH
- **Priority:** MAYBE
- **Decision 2026-06-07:** No action needed on the rule itself — the current default behavior is already OK. But the LEARNING surfaced again twice unprompted in subsequent sessions, suggesting the *re-surfacing mechanism* may itself be the friction. Worth thinking about a way to suppress / dampen re-surfacing of "no-action" learnings so they don't keep rising to the top of the backlog. Possible angle: add a `**Status:** acknowledged — no action` marker that the session-reflect/store-learning skills recognize as "do not re-elevate" without fully resolving.
- **Source:** session:reflect → session:store-learning (post-WP5 / post-claude-time-test-containerization, 2026-05-22)
- **Target level:** workflow-system source repo (`my-claude-code-customization`) — port to global CLAUDE.md's "Executing actions with care" section, OR as a new "Workflow branch-off discipline" subsection
- **Type:** new-work / workflow-system rule (global)
- **Summary:** When a workflow branches off mid-execution (pausing one feature to ship a sibling, opening a parallel incident, any cross-feature pause/resume), make a WIP commit on the paused feature's state BEFORE starting the branch-off work. Commits are cheap. A `[wip] pausing for <reason>` commit on `main` is reversible later (`git reset --soft HEAD~1`, amend, `git rebase -i`) and prevents cross-feature dirty-tree contamination. Every additional dirty file is a destructive-operation hazard surface: `git checkout HEAD -- <file>` reverts whole files (not hunks), `git stash` saves all dirty state at once across features, and selective `git add` requires per-commit discipline that's easy to slip on.
- **Context:** Today's session paused WP5 mid-Phase-4 to ship a sibling containerization feature; both features had uncommitted edits to shared files (CLAUDE.md, dashboard.jsx, viz_render.py, test_visualize_cli.sh). At a finalize-time CLAUDE.md edit, `git checkout HEAD -- CLAUDE.md` was used to revert just the new edit but whole-file-reverted both features' changes, destroying ~60 lines of WP5's URL-hash convention section (recovered manually from conversation transcript — but git reflog/fsck couldn't help since the work was never committed).
- **Suggested action:** Port the draft to a permanent home. Add a new bullet under global CLAUDE.md's "Executing actions with care" section: "Commit before branching workflows. When pausing one feature to start another (or any cross-feature pause/resume), make a WIP commit on the paused feature's in-flight state first. Commits are cheap and reversible (`git reset --soft HEAD~1`, amend, or `git rebase -i` to clean up before the next ship)." Rule-of-thumb threshold: if a pause is expected to span more than ~10 minutes or another feature's full lifecycle, commit the in-flight state.
- **Reference:** Full learning draft at `.claude/learnings/2026-05-22-commit-often-at-cross-feature-branch.md` (gitignored — local-only until promoted to source repo by hand).
- **Original priority:** medium — the failure mode hit this session (lost work recovered only via transcript); the rule applies to every cross-feature pause/resume going forward.
- **Status:** acknowledged — no action on the rule; meta-question (re-surfacing dampener) open.

## SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE
- **Priority:** MAYBE
- **Source:** Comparative analysis of `obra/superpowers` workflow system (2026-06-02). Full report archived at `docs/product/archive/research/2026-06-02-superpowers-comparison.md`. Specific borrow: superpowers' test suite includes **behavioral pressure tests** that plant rationalization-shaped inputs (e.g. "the test is flaky, just claim it passes", planted SQL injection bugs in review fixtures) and assert the skill resists. Distinct from this repo's transition tests (which verify "given input X, skill emits TRANSITION Y") and structural tests (`tests/check-structure.sh`).
- **Target level:** harness / tests (`tests/run-tests.sh` augmentation or new `tests/pressure/` group).
- **Type:** test-coverage expansion
- **Summary:** Current tests in this repo verify (a) transitions fire correctly given clean inputs, and (b) structural conventions hold (frontmatter, required sections, byte-pins). Neither tests whether discipline-bearing skill language **survives pressure** — i.e., whether `feature-verify-codify` resists a fixture that says "tests are flaky just merge it", or whether `feature-build` resists "this is a simple change just do it, no plan needed". Behavioral pressure tests are a meaningfully different signal: they test the *rationalization-resistance* of skill prose, which is the property that matters most when the model is mid-task and under time pressure. **User stance (per conversation):** maybe — existing tests are largely working, but there's potential value in more rigorous coverage. Not a priority pickup; defer until either (a) a skill failure mode in the wild traces back to language that didn't resist pressure, or (b) a future cycle has scope for test-infrastructure investment.
- **Why it matters:** This repo's principle is "advisory enforcement over hard blocks." That principle is unfalsified without pressure tests — every claim that "the prose is strong enough" rests on author intuition rather than measured behavior. If/when the principle gets challenged (a real failure mode where advisory framing let discipline lapse), pressure tests would be the empirical instrument to either defend the framing or surface specific prose weaknesses.
- **Suggested action:** Light spec when picked up. Sketch: add `tests/scenarios/pressure/` directory; each scenario is a YAML with a rationalization-shaped fixture + an expected-behavior assertion (must contain escalation language, must not emit transition-to-complete, etc.). Run on sonnet (haiku won't expose the failure mode reliably). Start with 3-5 high-value targets — verify-codify (Test Triage gate under "flaky test" pressure), feature-build (under "this is small just do it" pressure), incident-mitigate (under "ship the fix it's prod" pressure). Don't try to cover all 35 skills.
- **Original priority:** low-medium — user-flagged as "maybe", not immediate; pickup signal is either a real wild failure tracing to weak prose, or a scoped test-infrastructure cycle.
- **Status:** open

---

## Buried

The following items were buried 2026-06-07. Full content preserved in [`workflow/backlog-deferred-2026-05.md`](backlog-deferred-2026-05.md).

- `SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER` — bulk-delete safety pattern (CLAUDE.md convention proposal).
- `SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING` — audit-method gap; destructuring patterns require their own grep.
- `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` — codify plan-time downstream-contract grep into `feature-plan` SKILL.md.
- `SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD` — `docs/product/wbs.md` exceeds 300-line size guard.
- `SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG` — `--db` silently overrides `$CLAUDE_TIME_DIR` for config lookup.
- `SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE` — `session_id[:8]` truncation can collide in synthetic test data.
- `SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL-DOESNT-REACH-REACT` — synthetic `WheelEvent` dispatch doesn't reach React's `onWheel`.
- `SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT` — structural check missing; frontmatter `name:` vs. parent dir.
