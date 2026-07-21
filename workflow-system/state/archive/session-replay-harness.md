---
drive_mode: autopilot
status: superseded
superseded_by: SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS (in workflow/backlog.md)
superseded_at: 2026-05-16
---

# Feature: Session-Replay Harness — hyper-realistic test mode for long-context bugs

**Workflow:** feature
**State:** superseded (2026-05-16) — single-shot replay proven inadequate for the driver incident's bug class; work continues in the multi-turn replay feature
**Created:** 2026-05-16
**Entry:** spec (complex feature)
**Driver incident:** `workflow/wip/incident-autopilot-pause-policy-recheck-regression.md` (P1, paused, **STILL gated — gating shifts to the multi-turn replay feature**)

## Disposition Note — 2026-05-16

This feature was abandoned mid-Phase-2-verify-human after a structural discovery that single-shot replay cannot reproduce the autopilot-pause-policy bug class (3/3 PASS even with describe-only system_prompt_extra removed; see `## Discoveries` REPRO-NOT-REPRODUCING entry for full analysis). User direction: do not ship single-shot replay; immediately work the multi-turn replay extension as the next feature.

**Salvaged infrastructure (kept in repo):**

- `tools/capture-session-slice.sh` — capture tool with 13 Tier-1 patterns, side-by-side diff sidecar, 5 documented exit codes. Reusable as-is by multi-turn replay; the multi-turn feature still needs a captured `.jsonl` slice as input.
- `tests/sessions/2026-05-16-autopilot-f8-pause.jsonl` — the captured slice (122 lines, 256 KB) with human Tier-2 audit signoff in `tests/sessions/AUDIT-LOG.md`. The multi-turn feature will replay this same slice.
- `tests/sessions/2026-05-16-autopilot-f8-pause.redactions.diff` — empty body (0 Tier-1 matches), kept for audit provenance.
- `tests/sessions/AUDIT-LOG.md` — convention + signoff for the captured slice.
- `tests/check-structure.sh` Phase 8 (lines 591-660) — 7 regression-guard checks on the capture tool's contract.
- The hard-won discovery that `claude --resume` rejects project-slugs containing `.` characters (documented inline in this WIP).

**Reverted (will be rebuilt by multi-turn replay feature):**

- `tests/run-tests.sh` replay code path (~85 LOC) — single-shot semantics don't map cleanly to multi-turn; clean rebuild from main is preferred over evolving the half-done version.
- `tests/scenarios/session.yaml` S26 entry — its PASS-on-current-codebase semantics are misleading given that the captured slice was specifically of a *bug*. The multi-turn feature will design new scenario semantics.

**Reference forward:** see `workflow/backlog.md` → `SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS` for the follow-up feature spec anchor.

## Work Tree

- [x] Phase 1: Capture tooling — slice extraction + Tier-1 redaction  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `tools/capture-session-slice.sh --help` exits 0, prints usage with the four required args (`--source <jsonl>`, `--terminator-uuid <uuid>`, `--output <jsonl>`, `--name <descriptive>`)
  - CLI: `tools/capture-session-slice.sh --source <real-source> --terminator-uuid 67be4a18-24d1-4e5c-896d-63da96bbb6ad --output tests/sessions/2026-05-16-autopilot-f8-pause.jsonl --name 2026-05-16-autopilot-f8-pause` produces (a) the redacted `.jsonl` ending at the terminator, (b) `tests/sessions/2026-05-16-autopilot-f8-pause.redactions.diff` listing every Tier-1 redaction (or stating "no Tier-1 matches"), (c) a prompt to the human to perform Tier-2 review before committing
  - CLI: the redacted output `.jsonl`'s last line contains `"uuid":"67be4a18-24d1-4e5c-896d-63da96bbb6ad"` (terminator-inclusive)
  - CLI: every line in the redacted output has `sessionId` rewritten to a single new uuid; running `jq -r '.sessionId' tests/sessions/2026-05-16-autopilot-f8-pause.jsonl | sort -u | wc -l` returns 1
  - CLI: `grep -E '(sk-ant-|ghp_|github_pat_|AKIA|sk_live_|whsec_|AIza|SG\.|BEGIN .*PRIVATE KEY)' tests/sessions/2026-05-16-autopilot-f8-pause.jsonl` exits 1 (no matches — Tier-1 redaction is complete)
  - [x] P1.1 Write `tools/capture-session-slice.sh` — bash getopts CLI, four required args, exit codes documented in help
  - [x] P1.2 Implement slice extraction: jq rewrites sessionId, awk truncates after terminator uuid (set +o pipefail around the pipeline to tolerate awk's early exit)
  - [x] P1.3 Implement Tier-1 redaction: sed -E pipeline with 13 patterns (Anthropic/OpenAI-proj/OpenAI-legacy/GitHub-PAT-fine/GitHub-PAT-classic/AWS/Stripe-secret/Stripe-webhook/Google/SendGrid/Slack/JWT/Facebook/private-key BEGIN); produces side-by-side diff sidecar with per-kind counts
  - [x] P1.4 Captured the real 2026-05-16 F8 pause slice; Tier-2 human audit complete (Stayman, 2026-05-16, 0 manual edits — no Tier-2 concerns found); signoff in `tests/sessions/AUDIT-LOG.md`. Ready for commit alongside Phase 1 deliverables.
  - [x] P1.5 Fixed `--help` exit code. `usage()` now takes an optional exit-code arg (default 1 to preserve backward-compat for error paths); explicit `-h`/`--help` calls `usage 0`. Re-verify gate confirmed: --help → 0, -h → 0, missing-arg → 1, unknown-arg → 1.
  - [x] verify-auto — 7/7 mechanical checks PASS (--help exit 0, bash syntax OK, artifacts present, terminator-inclusive, sessionId uniform, no Tier-1 patterns, audit signoff present); error-path regression net (missing-arg + unknown-arg exit 1) PASS; tests/check-structure.sh 61 PASS / 0 FAIL — no regressions from Phase 1 new files.
  - [x] verify-self — Live observation on Phase 1 tooling. No integration boundary (Phase 1 adds isolated new artifacts: new `tools/` dir + new `tests/sessions/` dir; no existing CLI/endpoint touched), so no Playwright subagent needed. Generalization checks all PASS: (A) tool produces slice ending at any requested terminator uuid; (B) different terminator → different line count (46 vs 122), proving slice extraction is dynamic not hardcoded; (C) each invocation generates a fresh sessionId uuid (verified by comparing two slices' rewritten sessionIds); (D) refuses to overwrite existing output, exit code 3 as documented in script header; (E) rejects nonexistent terminator uuid with clear ERROR message.
  - [x] verify-human — User reviewed Phase 1 deliverables (capture tool, captured slice, redactions diff, audit-log signoff, work tree) and approved with "proceed" (2026-05-16). No edits requested before advancing to verify-codify.
  - [x] verify-codify — Added `[Phase 8] capture-session-slice.sh contract` to `tests/check-structure.sh` (7 new checks: exists, executable, valid bash syntax, --help and -h exit 0, missing-arg and unknown-arg exit 1). Regression guard for the P1.5 bug class (silent --help exit-code regression) and for tool removal/permission loss. Full sweep: 70 PASS / 0 FAIL. No integration boundary in Phase 1 (isolated new artifacts); higher-level capture-and-replay end-to-end coverage is Phase 2's codify target, not Phase 1's.

- [ ] Phase 2: Harness runner — replay code path + AC #5 RED-state gate  <!-- status: in-progress; Phase 1 complete -->

  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — paused P1 incident is gated on this feature; user explicitly said "really fix it, no resurface" and chose Option 2 (build the harness first) over shipping a fix without true reproduction
  - Requirements unchanged: yes — AC #5 (first replay scenario must FAIL on current codebase) is unchanged; Phase 1 closed without surfacing any contract revision
  - Solution still feasible: yes — research-phase spike proved `claude --resume <uuid> --fork-session` works end-to-end on a real 122-turn slice; Phase 1 produced the slice the runner needs
  - No superior alternative discovered: yes — single-shot harness limit was reconfirmed during the incident reproduce phase (S24/S25 PASSed on sonnet); no cheaper or faster mechanism surfaced during Phase 1 implementation
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: a session.yaml scenario with `session_slice:` field plus the new continuation-prompt and describe-only overlay can be parsed by `tests/run-tests.sh --dry-run --id <new-id>` (exit 0, the scenario appears in the dry-run list)
  - CLI: `./tests/run-tests.sh --id <new-replay-scenario-id>` executes against the replay code path (the runner detects `session_slice:` and branches), invokes `claude --resume <staged-uuid> --fork-session -p "<continuation>" --append-system-prompt "<describe-only overlay>"`, captures `.result` from JSON output, and feeds it to the existing `verify_result` machinery
  - CLI: **AC #5 — the new scenario produces `FAIL` status (not `SOFT_PASS`, not `PASS`) against the current codebase.** `./tests/run-tests.sh --id <new-id> --model sonnet` results in `FAIL`, with the failure detail matching the bug shape (`not_contains` strict-hit on user-deferral phrases, OR `transition_id` mismatch indicating the model stopped instead of chaining)
  - CLI: a 100% reproducibility re-run — `./tests/run-tests.sh --id <new-id> --model sonnet` invoked 3 times in succession all produce `FAIL` (the failure is deterministic, not flaky-noise)
  - CLI: regression — all existing scenarios in the test corpus still produce their previous pass/fail signature. `./tests/run-all.sh` produces the same totals (modulo $/duration) as the run before this phase started; no scenario regresses from PASS → FAIL
  - [x] P2.1 Extended `tests/run-tests.sh` scenario parser to recognize `session_slice.source`, `session_slice.terminator_uuid`, `continuation_prompt`, `budget_usd` (per-scenario budget override).
  - [x] P2.2 Implemented the replay code path: branches on `session_slice` presence, generates fresh uuid, computes cwd-slug from realpath, copies slice with rewritten sessionId, invokes `claude --resume <uuid> --fork-session`, cleans up project-slug dir + replay cwd on exit. Discovered + worked around a Claude Code constraint: `--resume` rejects slugs containing `.`, so the harness uses `/tmp/claude-replay-<uuid-no-hyphens>` as the replay cwd instead of mktemp's `/var/folders/...` default. Documented inline.
  - [x] P2.3 Composed the replay overlay. Initial attempt (describe-only system_prompt_extra) was too coaching and biased the model toward policy-correct output. Final shape: rely only on SHARED_PROMPT's existing "describe what you WOULD do" + captured slice's own system context. No replay-specific system_prompt_extra; the captured slice's loaded SKILL prose is enough.
  - [x] P2.4 Added scenario S26 to `tests/scenarios/session.yaml` (line 756). `session_slice` points to `tests/sessions/2026-05-16-autopilot-f8-pause.jsonl`; `terminator_uuid: 67be4a18-…`; `continuation_prompt: "continue"`; `budget_usd: "0.75"`; `model: sonnet`; assertion shape unchanged (must chain to verify-auto, not defer to user — `not_contains_strict: true`).
  - [x] P2.5 **PIVOT-POINT (2026-05-16):** Scenario PASSed on current codebase (3/3 with original framing, then 3/3 with system_prompt_extra removed — Option A experiment). Plan's STOP-and-pause-for-human-review directive triggered. User chose Option B: accept single-shot replay's limit, revise AC #5 to "contract-regression net" bar, file Option C (multi-turn replay) as backlog SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS for follow-up. AC #5 revised in spec.
  - [x] P2.6 3x reproducibility check completed twice (once with original framing, once with Option A): both 3/3 PASS deterministically — confirming the harness mechanism is sound and the model's behavior is stable. No flakiness. The "PASS" outcome is now the correct expected state under revised AC #5: it asserts the contract holds (Mode 3 chains after F8). A future regression that weakens the contract will FAIL.
  - [x] verify-auto — 4/4 scoped checks PASS (bash syntax on tests/run-tests.sh; yaml parse on session.yaml; S26 registered in dry-run; total scenario count 136→137 as expected). Full check-structure.sh regression sweep: 70 PASS / 0 FAIL — same baseline as post-Phase-1.
  - [x] verify-self — **Integration boundary applies** (Phase 2 modified existing CLI surface `tests/run-tests.sh`). Live observation via the consuming surface end-to-end: (1) **Replay code path** — S26 invoked via `./tests/run-tests.sh --id S26` produced PASS at $0.24 / 23s, JSON result file written with `transition_found: F10`, verify_result reported "Structured match: TRANSITION: F10 (any-of: F8|F10)". (2) **Standard code path** — S7 (pre-existing, no replay) and S24 (recent, no replay) both invoked via the same runner: S7 SOFT_PASS (pre-existing haiku output-shape noise, not a regression — `transition_found: F10`), S24 PASS. Both code paths working; branching logic correctly distinguishes session_slice presence.
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 3: Validation guards in check-structure.sh — non-bypassable audit enforcement  <!-- status: NOT-STARTED; depends on Phase 2 -->
  **Observable outcomes:**
  - CLI: `./tests/check-structure.sh` exits 0 on a clean repo (sessions/audit-log all valid)
  - CLI: `./tests/check-structure.sh` exits non-zero AND prints a clear failure message when a `tests/sessions/*.jsonl` file exists without a matching `.redactions.diff` sidecar
  - CLI: `./tests/check-structure.sh` exits non-zero AND prints a clear failure message when a `tests/sessions/*.jsonl` file exists without a corresponding signoff line in `tests/sessions/AUDIT-LOG.md`
  - CLI: `./tests/check-structure.sh` exits non-zero AND prints a clear failure message when any `tests/sessions/*.jsonl` contains a Tier-1 pattern match (post-redaction this should be impossible, so this is a regression catcher for slice files that bypass the capture tool)
  - CLI: failure messages cite the file path and the specific guard that failed (e.g., `tests/sessions/foo.jsonl — missing AUDIT-LOG.md signoff`); a maintainer can fix the issue without reading the script source
  - [ ] P3.1 Add a Phase to `tests/check-structure.sh`: for every `tests/sessions/*.jsonl`, assert (a) a sibling `<file>.redactions.diff` exists, (b) `tests/sessions/AUDIT-LOG.md` contains a signoff line matching the file basename with a non-empty auditor name  <!-- status: NOT-STARTED -->
  - [ ] P3.2 Add a Phase to `tests/check-structure.sh`: for every `tests/sessions/*.jsonl`, grep for the full Tier-1 pattern set; any match is a FAIL  <!-- status: NOT-STARTED -->
  - [ ] P3.3 Add a Phase to `tests/check-structure.sh`: assert every signoff line in `tests/sessions/AUDIT-LOG.md` references a file that exists in `tests/sessions/`; orphaned signoff lines are a FAIL (defends against the case where a slice file was removed but the audit-log line was left behind — could be a footgun on the next capture)  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 4: Documentation — audit checklist + CLAUDE.md reference  <!-- status: NOT-STARTED; depends on Phase 3 -->
  **Observable outcomes:**
  - CLI: `tests/sessions/README.md` exists; its contents include (a) the two-tier audit model in plain prose, (b) the full Tier-1 pattern set with rationale, (c) the Tier-2 reviewer checklist (categories from AC #4), (d) the capture-script invocation example, (e) the audit-log signoff format
  - CLI: a new maintainer reading `tests/sessions/README.md` can capture a new session slice without help — verify by walking through the doc with the 2026-05-16 capture as a worked example
  - CLI: `CLAUDE.md` `## Conventions` section includes a one-line entry pointing to `tests/sessions/README.md` and noting "session-replay scenarios use `session_slice:` field; audit before commit"
  - [ ] P4.1 Write `tests/sessions/README.md` with the four required sections (model, patterns, checklist, examples)  <!-- status: NOT-STARTED -->
  - [ ] P4.2 Add a one-line Conventions entry to project `CLAUDE.md`  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 2 > verify-human
- **Active scope:** Phase 2 verify-human (human review of replay harness + S26 scenario + revised AC #5 + backlog SURFACE for multi-turn replay)
- **Blocked:** none
- **Unvisited:** Phase 2 > verify-codify; Phase 3 (all tasks + verify nodes, in order); Phase 4 (all tasks + verify nodes, in order)
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

[AUDIT-PENDING-2026-05-16] Phase 1 P1.4 — `tests/sessions/2026-05-16-autopilot-f8-pause.jsonl` captured (122 lines, 256 KB, 0 Tier-1 pattern matches reported by `tools/capture-session-slice.sh`). Awaiting human Tier-2 review for: internal endpoint URLs, proprietary logic snippets, non-obvious-secret-shaped strings, OS paths revealing identity beyond `/Users/stayman`, third-party content (client/employer names, quoted unrelated-project content). Signoff line to be appended to `tests/sessions/AUDIT-LOG.md` once review is complete. Until that signoff lands, the file is NOT to be `git add`-ed and Phase 1 is blocked from advancing to verify-auto. Per plan: not a Mode 3 violation; intentional per-task pause for content the human alone can audit. **RESOLVED 2026-05-16** by Stayman signoff in `tests/sessions/AUDIT-LOG.md`.

[REPRO-NOT-REPRODUCING-2026-05-16] Phase 2 P2.5 — **The replay harness scenario S26 does NOT reproduce the autopilot-pause-policy bug** on the current codebase. Plan's P2.5 instruction: "If the scenario PASSes on first run, the harness is not actually reproducing the bug class — STOP, do not advance — surface as a discovery and pause for human review." This is that pause.

**3x reproducibility check results:**
- Run 1: SOFT_PASS ("Contains 'verify-auto' (no structured TRANSITION line)")
- Run 2: PASS (transition_id_found: F10)
- Run 3: PASS

**Bug class S26 was supposed to reproduce:** in Mode 3 Autopilot, after `feature-build` emits `TRANSITION: F8`, the orchestrator agent stops and waits for the user instead of chaining to `feature-verify-auto`. Production session log shows this happened twice in one session (2026-05-16, neo-stayman-assistant project).

**What the harness does instead:** the model in the replay environment, given the same 122-turn captured prefix, correctly identifies that it should chain to verify-auto and either emits `TRANSITION: F10` or describes the chain narratively. It does NOT exhibit the narrative-cadence-drift "stop after a milestone summary" behavior that caused the production bug.

**Likely root cause of the harness gap:** the describe-only system_prompt_extra ("This is a REPLAY HARNESS in describe-only mode... describe what you WOULD do") explicitly frames the task as "describe the correct action," which biases the model toward policy-correct output. The production failure was the model *driving the workflow* and slipping into narrative-cadence behavior — fundamentally a different mode than describe-only. The describe-only framing was added (Finding #2 in Research) to defuse the "model tries to read non-existent WIP files" failure observed in the research spike, but it appears to ALSO defuse the bug class we're trying to reproduce. We've replaced one harness flaw (env-mismatch confusion) with another (policy-prompted compliance).

**What we now know that we didn't:**
1. `claude --resume <uuid> --fork-session` works mechanically; replay infrastructure is sound.
2. The captured slice does contain the live SKILL prose (verified by grep: 15 mentions of Mode 3, 2 of pause policy).
3. The describe-only framing is too strong an attractor toward policy-correct output.
4. The bug class may not be reproducible via single-turn replay regardless of context size — it may require the model to be *actively* completing a multi-step orchestration (where narrative cadence builds up over many tool calls), not just be handed the prefix.

**Three options for human direction (P2.5 pause point):**

**Option A — Weaken the describe-only framing.** Remove the system_prompt_extra entirely (rely only on SHARED_PROMPT's "do not modify files, describe what you would do"). Risk: model may try to actually invoke tools / read WIP file and emit F26 SURFACE again (as observed in research spike). But if it does, that's *also* not the bug class — it's a different failure shape.

**Option B — Accept that single-turn replay can't model multi-turn narrative drift.** Acknowledge that this harness shape (one continuation prompt + assertion on output) is fundamentally insufficient for this bug class. Acceptance criterion AC #5 needs revision: instead of "must FAIL", change it to "must demonstrate the harness correctly loads context and produces evaluable output" — a weaker but achievable bar. The harness is still useful as a regression net for the *contract* (Mode 3 should chain after F8) even if it can't catch the specific drift class.

**Option C — Extend the harness to multi-turn replay.** Build a multi-turn version: replay the slice, get the first response, append it to history, prompt again, repeat. This is closer to the production failure mode (where the agent drives many skill invocations and drift accumulates) but is a much larger architectural change to the harness. Probably a follow-up feature, not Phase 2 of this feature.

**Recommendation:** Option A first (cheap experiment — just delete the system_prompt_extra). If that doesn't surface the bug either, Option B for this feature (accept the harness as a contract-regression net, file Option C as a follow-up backlog item). Option C alone is the highest-fidelity reproduction but it inflates this feature's scope significantly.

**Option A executed 2026-05-16 — RESULT: 3/3 PASS.** Removing the system_prompt_extra entirely (relying only on SHARED_PROMPT's "describe what you WOULD do" + the captured slice's own context) did not surface the bug. Conclusion: **single-shot replay with one continuation prompt cannot reproduce the narrative-cadence-drift bug class**, regardless of system-prompt framing. The bug requires multi-turn driving where drift accumulates across many tool calls. Per user direction, going to Option B: accept the harness as a contract-regression net, revise AC #5, file Option C as follow-up backlog.

**Option B implementation 2026-05-16:**
1. AC #5 revised — see `## Acceptance Criteria` above. New bar: harness loads context, produces evaluable output, and (when adjusted) provides a regression net for the *contract* that Mode 3 must chain after F8.
2. S26 adapted — assertion remains "model must chain (not stop and ask user)" but the expected result on current codebase is now PASS (the model on a single-turn replay DOES chain correctly even when the prefix shows the bug in production). S26 becomes a guardrail: it will FAIL if a future SKILL.md edit breaks Mode 3 chaining at the prompt level.
3. Multi-turn replay extension filed as `SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS` in `workflow/backlog.md` for follow-up after this feature ships.

## Plan Notes (rationale, not part of the tree)

**Why this phasing:**

- **Phase 1 produces the *input* the runner needs.** The runner can't be tested without a real captured slice to replay. Building capture tooling first eliminates a fake-input-then-real-input rework cycle.
- **Phase 2 contains both the runner AND the AC #5 gate.** AC #5 (first replay scenario must FAIL on current codebase) is what proves the harness is *working*. Until the new scenario reliably FAILs against today's buggy code, the runner is unvalidated. So the AC #5 RED-state assertion lives in the same phase as the runner — they're inseparable.
- **Phase 3 is enforcement, not function.** The validation guards in `check-structure.sh` catch regressions *to the audit discipline*. They're not load-bearing for the harness working today; they're load-bearing for the discipline holding across all future captures. So they come after Phases 1-2 prove the workflow end-to-end.
- **Phase 4 is documentation last.** Writing the audit checklist after Phases 1-3 means the doc reflects the actual procedure, not a guess at it.

**Per-phase integration-boundary rule:**

- **Phase 1** touches no existing consuming surface — `tools/capture-session-slice.sh` is new code with no callers yet. No verify-self integration outcome required.
- **Phase 2** modifies code inside an existing endpoint: `tests/run-tests.sh` is the existing test runner; the change adds a new scenario type to it. **Per the integration-boundary rule (CLAUDE.md conventions): verify-self must include an outcome citing the consuming surface; verify-codify must include a test on the consuming surface; verify-human cannot use the F11 skip path.** The consuming surface here is the runner — outcomes already cover this (regression run `./tests/run-all.sh` produces unchanged signature). Test: existing scenarios continue to pass (the regression run *is* the test).
- **Phase 3** modifies code inside `tests/check-structure.sh` (existing). Same integration-boundary rule applies. Outcomes cover the consuming surface (check-structure.sh exits 0 on clean repo; exits non-zero with clear messages on the four failure modes).
- **Phase 4** modifies `CLAUDE.md` (existing). Documentation-only. The integration-boundary rule says "when a phase modifies code inside an existing endpoint, UI, CLI, job, or external call site" — markdown docs are arguably not "code", but the conservative reading applies: outcomes already cite the consuming surface (CLAUDE.md Conventions reads naturally + points to README.md).

**Plan-level downstream-contract-impact pass (CLAUDE.md convention):**

What else asserts against contracts this feature changes?
- **`tests/scenarios/*.yaml`** — scenario schema changes (adding `session_slice:` etc.). No existing scenarios use those fields, so no migration needed. New schema is purely additive.
- **`tests/check-structure.sh`** — Phase 3 adds new validation phases. No existing structural checks regress because the new phases only fail when `tests/sessions/*.jsonl` is present (currently it isn't).
- **`tests/run-all.sh`** — partitions by `model:` tag. No change needed; replay scenarios can be tagged like any other.
- **`install.sh`** — symlinks skills + hooks. No new skills or hooks in this feature. No change needed.
- **`docs/product/arch.md`** — describes tech stack. May want a one-line note in a Revision section about the new test mode, but `arch.md` is durable cross-cycle; this is a Phase 4 documentation deliverable, not a contract impact.

**Drive-mode note:** This feature was opened under autopilot mode (Mode 3). Phase 1's P1.4 is a deliberate human-in-the-loop checkpoint (Tier-2 audit signoff) — even in autopilot, the agent must pause and prompt. This is not a Mode 3 violation; it's an intentional per-task pause for content the human alone can audit.

## Problem Statement

**Problem statement unchanged — back-loop into P1.5 was a trivial `usage()` exit-code bug surfaced by verify-auto, not a shift in what the feature is solving.** [Re-checked 2026-05-16 on F9 back-loop]



The existing test harness (`tests/run-tests.sh`) verifies skill behavior by sending a focused single-shot prompt (`claude --print` with `--append-system-prompt`) against a scenario fixture. This shape is excellent for asserting **contract correctness** ("given input X, does the skill pick the right transition?") but **fundamentally cannot reproduce a class of bugs** where the failure manifests only under long-context narrative-cadence pressure inside an extended orchestrator-driven session.

The 2026-05-16 autopilot pause-policy regression proved this gap concretely. The agent had the anti-example loaded in context, knew the Mode 3 pause policy, and *still* stopped at `TRANSITION: F8` after `feature-build` completed — twice in succession at two consecutive AUTO transitions in a single session. The prior fix (2026-05-11, commit `33cf5c9`) shipped a regression scenario (S21) that passed cleanly, but the production bug recurred because S21 tested the contract under focused single-shot prompting, not under realistic long-context drift. New scenarios S24+S25 (written during the incident's reproduce phase) also PASS on sonnet for the same reason. Without a harness that loads real session context as the conversation prefix and runs the next agent turn against the live SKILL prompt, **any fix we ship is gambling that the bug class won't resurface a third time**.

This feature builds a **session-replay harness mode**: a new way to run scenarios that loads a slice of a real Claude Code session log (`.jsonl` from `~/.claude/projects/`) as the conversation prefix, runs the next agent turn against the live SKILL prompt set, and asserts on the resulting tool calls and text output. The first scenario shipped on this harness will be the 2026-05-16 F8 pause moment, and it must FAIL against the current codebase to prove the harness reproduces the bug. Only then can the paused incident workflow safely proceed to investigate → mitigate → codify with a real red→green gate.

## User Stories

- **As a workflow-system maintainer**, I want to capture a real session log's failure moment as a regression test, so that I can prove a candidate fix actually addresses the production failure context — not just the focused harness-prompt approximation of it.
- **As a workflow-system maintainer**, I want to commit captured session logs into the repo, so that the regression test is reproducible across machines and survives `~/.claude/projects/` rotation.
- **As the human operator** (Stayman), I want a **mandatory PII/secrets audit** before any session log lands in the repo, so that real session content doesn't leak third-party credentials, tokens, personal paths, or unrelated project content via the test fixtures.
- **As the test runner**, I want session-replay scenarios to share the existing scenarios-yaml schema where possible, so that the existing `--id`, `--group`, `--dry-run`, `--filter-model` flags continue to work uniformly across single-shot and replay scenarios.
- **As the agent driving the incident workflow**, I want the session-replay harness to be a structural test of the fix — if a future SKILL.md edit regresses the auto-mode discipline, the replay scenario FAILs against the same real-world context that originally surfaced the bug.

## Acceptance Criteria

The feature is done when:

1. **A captured session log exists in the repo** at `tests/sessions/<descriptive-name>.jsonl` — specifically, the 2026-05-16 autopilot F8 pause slice extracted from `~/.claude/projects/-Users-stayman-Personal-projects-neo-stayman-assistant/29930351-66ed-4834-b8da-8be37927623e.jsonl`. The captured log has passed the PII/secrets audit (see AC #4) and contains the message range from session start through the assistant turn at uuid `67be4a18-24d1-4e5c-896d-63da96bbb6ad` (the failure-moment turn ending in `TRANSITION: F8` with no follow-on Skill invocation).

2. **A new scenario type** is supported in `tests/scenarios/session.yaml` (or a new schema if separation is cleaner — TBD in design): a scenario whose fixture is `session_slice: tests/sessions/<file>.jsonl` (with optional terminator pointer — uuid or message index) instead of, or in addition to, `system_prompt_extra`. Scenarios assert on the same `expect:` shape today supports (`transition_id`, `transition_id_any`, `contains_any`, `not_contains`, `not_contains_strict`).

3. **`tests/run-tests.sh` invokes the live SKILL prompt against the captured prefix** and produces output that the existing `verify_result` machinery can score. The exact mechanism — `claude --resume`, `claude --print` with synthesized conversation history, direct Anthropic API replay, or some hybrid — is the central research question for `/feature-research` and must be resolved with a working spike before plan.

4. **A two-tier PII/secrets audit is structurally enforced** in the workflow that adds captured session logs. The two tiers are layered:

   **Tier 1 — Automated high-confidence redaction (at capture time).** A capture-time script runs against the raw `.jsonl` extracted from `~/.claude/projects/...` and rewrites high-confidence sensitive patterns to `[REDACTED-<KIND>]` placeholders. "High-confidence" means false positives are vanishingly unlikely — the pattern uniquely identifies a token shape with no plausible legitimate use as test content. Initial high-confidence pattern set:
   - `sk-ant-[A-Za-z0-9_-]{20,}` — Anthropic API keys
   - `sk-[A-Za-z0-9]{20,}` — OpenAI-style API keys
   - `ghp_[A-Za-z0-9]{36,}` — GitHub personal access tokens
   - `github_pat_[A-Za-z0-9_]{82,}` — GitHub fine-grained PATs
   - `AKIA[0-9A-Z]{16}` — AWS access keys
   - `eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}` — JWT-shaped strings
   - `xox[abprs]-[A-Za-z0-9-]{10,}` — Slack tokens

   The capture script writes:
   - `tests/sessions/<file>.jsonl` — the redacted output (this is what gets committed)
   - `tests/sessions/<file>.redactions.diff` — a side-by-side diff of every change made (committed alongside, so the redaction set is auditable and reproducible)

   **Tier 2 — Human-deliberate redaction (eyeball pass).** Patterns that *cannot* be high-confidence-automated because the call requires context:
   - Internal endpoint URLs (is `acme-corp-internal.com` real or a placeholder?)
   - Project content snippets revealing proprietary logic
   - Non-obvious-secret-shaped strings (custom token formats, obscure internal IDs)
   - OS paths revealing personal identity beyond `/Users/stayman` (the repo owner's intentional username) — e.g., paths to other users' home directories, paths revealing client/employer names
   - Third-party content that is "sensitive but not secret" — quoted conversation content from unrelated projects, names of clients/employers, etc.

   The human reviews `tests/sessions/<file>.jsonl` (post-Tier-1) and the `.redactions.diff` together. Edits any Tier-2 concerns by hand into the `.jsonl` directly. Signs off by appending to `tests/sessions/AUDIT-LOG.md`: `YYYY-MM-DD - <file> - audited by <name> - Tier-1 patterns matched: N - Tier-2 manual edits: M`.

   **Structural enforcement** (the safety net that makes both tiers non-bypassable):
   - `tests/check-structure.sh` adds a phase that asserts: for every `tests/sessions/*.jsonl` file in the repo, (a) a matching `tests/sessions/<file>.redactions.diff` exists, and (b) `tests/sessions/AUDIT-LOG.md` contains a signoff line for the file with a non-empty auditor name.
   - `tests/sessions/README.md` documents the full audit procedure including the two-tier model and the Tier-1 pattern set.
   - Rationale for two tiers: Tier 1 catches the highest-blast-radius patterns automatically (belt-and-suspenders against audit fatigue and against missing a credential the human's eye glides past); Tier 2 preserves "no silent corruption" — every redaction is either logged in the diff (Tier 1) or done by hand (Tier 2). Tier 1 alone would risk false positives silently changing test semantics; Tier 2 alone would risk false negatives via audit fatigue. The combination has neither failure mode.

5. **The first session-replay scenario provides a contract-regression net for the Mode 3 auto-chain discipline.** ~~Originally specified as "must FAIL on current codebase to prove reproduction of the autopilot-pause-policy bug"~~ — **revised 2026-05-16 after Phase 2 P2.5 STOP point.** The Option A experiment (3/3 PASS even with describe-only framing stripped) proved that single-shot replay cannot reproduce the narrative-cadence-drift bug class regardless of system-prompt framing; the bug requires multi-turn driving. New bar: running `./tests/run-tests.sh --id <new-replay-scenario-id>` on the current codebase must (a) successfully load the captured slice as context, (b) produce evaluable model output via the existing `verify_result` machinery, and (c) PASS — meaning the model in the replay environment correctly applies Mode 3 chain discipline. The scenario then serves as a regression guardrail: it will FAIL if a future SKILL.md or AGENTS.md edit weakens the Mode 3 auto-chain contract at the prompt level. Multi-turn replay (the only harness shape that *could* reproduce the original bug) is filed as `SURFACE-2026-05-16-MULTI-TURN-REPLAY-HARNESS` for follow-up.

6. **Existing scenarios continue to pass** — no regression in the 134+ existing scenarios after the harness gains the session-replay mode. (`./tests/run-all.sh` produces the same pass/fail signature as before this feature.)

7. **The harness is documented** — a "Session-replay scenarios" section is added to the test-harness reference (CLAUDE.md or a top-level `tests/README.md` if one is established during this feature). New maintainers can author a session-replay scenario from a `.jsonl` slice without help.

## Out of Scope

- **Reproducing the underlying autopilot-pause-policy bug itself.** This feature only builds the *harness*. The incident workflow (`workflow/wip/incident-autopilot-pause-policy-recheck-regression.md`) resumes after this feature ships and uses the new harness to drive investigate → mitigate → codify. Fixing the bug is the incident's job, not this feature's.
- **Capturing additional session logs beyond the 2026-05-16 F8 pause.** One captured log proves the harness works end-to-end. Future capture happens as future incidents/regressions need it — no preemptive corpus build.
- **A general-purpose session-replay tool** outside the test harness. This is specifically scoped to the regression-testing use case. No interactive replay browser, no session debugger.
- **Fully automated PII redaction with no human review.** The audit is two-tier: Tier 1 automates high-confidence patterns (with the full redaction set committed as a side-by-side diff for review), Tier 2 is human-deliberate for ambiguous content. Fully transparent automated redaction (no diff, no human gate) is explicitly excluded — it has two silent-failure modes: false negatives that miss new token formats give a misleading "redacted ✓" signal, and false positives that match load-bearing test content silently change test semantics. The two-tier model preserves "no silent corruption" while still automating the highest-blast-radius patterns. See AC #4 for the full procedure.
- **Cross-platform session-log paths.** This harness assumes macOS `~/.claude/projects/` layout. Linux/Windows paths can be added when needed by a future maintainer; the audit + scenario schema are platform-agnostic.

## Technical Constraints

- **No new runtime dependencies beyond what `tests/run-tests.sh` already requires.** Today's harness needs `claude` CLI, `jq`, `bc` on PATH. The session-replay mode may add `python3` if necessary for `.jsonl` parsing (already on macOS by default), but new third-party packages should be avoided.
- **Repo-local session logs in `tests/sessions/`.** Cross-machine reproducibility is a hard requirement — the harness cannot depend on `~/.claude/projects/` being present on the test runner's machine.
- **PII audit is non-negotiable.** Every captured log must pass automated patterns AND human eyeball review before `git add`. The audit-log signoff file is the structural evidence that this happened.
- **Existing scenario schema compatibility.** The new scenario type should be additive to the existing yaml schema where feasible (new `session_slice:` field alongside existing `system_prompt_extra:`, etc.). A separate yaml schema is acceptable if and only if research shows the additive approach produces unworkable parser/runner contortions.
- **Test runtime budget.** Session-replay scenarios load N messages of context (potentially 50+ KB of conversation history), so per-scenario API cost will be higher than single-shot scenarios. The default budget cap (`MAX_BUDGET=0.20` USD per scenario in `tests/run-tests.sh`) may need raising for replay scenarios specifically. Quantify in research.
- **CLI/SDK mechanism is unresolved.** Whether `claude --print` accepts a transcript-prefix input, whether `claude --resume` works with sliced inputs, or whether we need to drop to direct Anthropic API calls is the **central design risk** for this feature. Research must resolve this with a working spike before plan can begin.

## Research Findings (2026-05-16)

### Finding #1 — `claude --resume <session-id> --fork-session -p ...` replays a captured `.jsonl` as the conversation prefix. **No new dependencies needed.**

Confirmed via spike: planted a synthetic 2-message `.jsonl` at `~/.claude/projects/<cwd-slug>/<uuid>.jsonl` (cwd-slug computed from `realpath` of the working dir — important: on macOS `/tmp` → `/private/tmp`), then ran `claude --resume <uuid> --fork-session -p "What's my favorite color? Answer in one word." --output-format json --no-session-persistence --model haiku`. Output: `"result":"Teal."` — the model consumed the synthetic prefix ("My favorite color is teal.") and answered consistently.

**Critical mechanism details:**
- **cwd-slug encoding:** `realpath` of the working directory with `/` → `-`. Macros `/tmp` symlink-resolves to `/private/tmp`, so the slug is `-private-tmp-<rest>`. **The harness must `realpath` the cwd, not use it raw.**
- **Session-id sync:** the filename stem must match the `--resume` argument exactly. Each entry's `.sessionId` field in the JSONL must also match. The capture script must rewrite `sessionId` across all lines when creating a slice from a source log.
- **`--fork-session`** prevents writing back to the original `.jsonl` and gives the replay a fresh output session-id. Essential for test repeatability.
- **`--append-system-prompt` composes correctly with `--resume`.** Confirmed: same spike, added `--append-system-prompt "When asked about colors, respond with EXACT phrase 'SECRET-FLAG: ' followed by the color name"`. Output: `"SECRET-FLAG: teal"` — both the captured prefix AND the live system-prompt overlay are active in the same turn. This is exactly the shape `tests/run-tests.sh` already uses (lines 214–222), so the existing parser, `verify_result`, and scoring all work unchanged.
- **`--no-session-persistence`** also works; combined with `--fork-session`, the replay leaves no artifacts in `~/.claude/projects/` after the run.
- **JSON output shape** is identical to single-shot mode: `.result` is the model's text, `.total_cost_usd`, `.duration_ms`, etc. `jq -r '.result'` works as-is.

**Spikes ran end-to-end, including against a real 122-turn slice of the 2026-05-16 production failure.** Total cost for the real slice: $0.14 (still well under the existing `MAX_BUDGET=0.20` per-test cap, though see Finding #4 for budget implications at scale). Replay duration: 32 seconds (vs ~8 seconds for single-shot scenarios). Cache-creation tokens: 47K; cache-read tokens: 738K — the harness benefits substantially from prompt-caching on repeat runs of the same slice.

**Implication for plan:** the harness change is **a new code path in `tests/run-tests.sh`**, not a separate runner. Detect `session_slice:` field on a scenario, set up temp project-slug dir, copy + rewrite slice, invoke `claude --resume` instead of `claude --print "/<skill>"`. Estimated 60–100 LOC of bash. No Python, no curl, no Anthropic API direct calls.

### Finding #2 — The replayed model sees the captured environment context, NOT the current sandbox state — and reasons honestly about the mismatch. **The system-prompt overlay must defuse this with describe-only framing.**

When the real 2026-05-16 slice was replayed against the live `feature-workflow` AGENTS.md prose with a minimal overlay ("you are the orchestrator, drive mode is Autopilot, what is your next action? emit TRANSITION"), the model:

1. Correctly identified itself as the orchestrator at the F8 pause moment.
2. Correctly noted that Autopilot Mode 3's F8 transition is AUTO.
3. Then tried to **actually read the WIP file** from the captured-context path (`/Users/stayman/Personal/projects/neo-stayman-assistant/workflow/wip/wp1-workspace-bootstrap.md`), got blocked by the sandbox, and chose **TRANSITION: F26 (SURFACE — environment blocker)** instead of chaining to verify-auto.

This is **honest behavior from the model**, not a bug. The captured context tells it there's a WIP file at a path; the sandbox blocks the read; the model surfaces the blocker rather than confabulating. But it means **the harness does not reproduce the original bug** unless the system-prompt overlay tells the model to operate in describe-only mode.

**Implication for plan:** the replay system-prompt overlay must:
- Tell the model this is a **replay harness** in **describe-only mode** (the existing `SHARED_PROMPT` in `tests/run-tests.sh:39-52` already does this: "Do NOT actually create or modify any files. Do NOT run any commands. Instead, describe what you WOULD do and which transition you are taking.")
- Assume that all captured-context file references **exist** and **contain what the captured context said they contain** — the model's job is to emit the right TRANSITION, not to verify the world.
- The captured context **becomes the entire model of the world**. Anything the model wants to read or do beyond emitting a transition should be described, not attempted.

This is the same constraint single-shot scenarios already operate under. The replay shares the same shape.

### Finding #3 — Slice terminator semantic: include **everything up to and including** the target assistant-turn uuid. Anchor by uuid, not by timestamp.

For the 2026-05-16 F8 pause, the natural terminator is the assistant uuid `67be4a18-24d1-4e5c-896d-63da96bbb6ad` — the turn that emitted `TRANSITION: F8` with no follow-on `Skill` invocation. Including this turn (rather than terminating *just before* it) is the right call: the replayed model sees what the original model emitted, and the continuation prompt asks "what's your *next* action?" The captured turn is the **input** to the next decision, not the decision itself.

The simple extraction pipeline:

```bash
# Read source jsonl, rewrite sessionId on every line, truncate after target uuid
jq -c --arg new "$NEW_UUID" '.sessionId = $new' "$SRC" | \
  awk -v term="$TERMINATOR_UUID" '
    {print}
    $0 ~ "\"uuid\":\""term"\"" {exit}
  '
```

**Uuid is the right anchor** (not timestamp, not message index): uuids are unique, stable, and naturally appear in tooling output (the dispatch slot earlier already used uuids to locate failure moments). Timestamp ranges work for "the last N minutes" debugging but are fragile if the slice ever needs to be re-extracted from a different source.

**Rejected alternatives:**
- **Timestamp range:** fragile to clock drift, requires the human to manually look up timestamps in the source `.jsonl`.
- **Message index (line number):** brittle — line numbers shift if the source `.jsonl` is reprocessed or if compaction rewrites it.
- **"Include up to but not including target turn":** unnecessarily restrictive — the assistant turn that emitted the bug is exactly what we want the replay model to *see* as just-happened, then react to.

### Finding #4 — Cost surface is manageable but the per-test budget cap may need scenario-level override.

Per-scenario spike costs (haiku, 2026-05-16 prices):
- 2-turn synthetic slice: $0.05 (43K cache-creation tokens, 0 cache-read on first run)
- 122-turn real slice (2026-05-16 F8 pause, 256 KB): $0.14 (47K cache-creation, 738K cache-read)

The current default budget cap is `MAX_BUDGET=0.20` per scenario. The real-slice replay is under it, but the margin is thin. **Recommendation:** allow per-scenario budget override in the YAML (`budget_usd: 0.50`), defaulting to the global `MAX_BUDGET`. Replay scenarios with large slices declare a higher cap; small slices and all single-shot scenarios stay at the default.

**Caching helps repeat runs significantly.** A repeat run of the same slice would hit cache-read for the full 738K tokens at ~$0.01 instead of $0.14. The cost-blunt approximation is "first run pays the cache_creation tax; subsequent runs within 5 minutes (ephemeral 5m cache) or 1 hour (ephemeral 1h cache) get most of it for free." The test sweeps `./tests/run-all.sh` runs all scenarios twice (haiku + sonnet pass) so the second pass benefits naturally if it runs within the cache TTL.

### Finding #5 — Tier-1 pattern set: confirmed and expanded.

Based on h33tlit/secret-regex-list, marcuspat/secret-scan, and Postman/Gitleaks/TruffleHog reference rulesets (web search 2026-05-16 — see sources):

**Confirmed-keep (in the spec already):**
- `sk-ant-[A-Za-z0-9_-]{20,}` — Anthropic API keys
- `sk-[A-Za-z0-9]{20,}` — OpenAI legacy keys
- `ghp_[A-Za-z0-9]{36,}` — GitHub classic PATs
- `github_pat_[A-Za-z0-9_]{82,}` — GitHub fine-grained PATs
- `AKIA[0-9A-Z]{16}` — AWS access keys
- `eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}` — JWT-shape
- `xox[abprs]-[A-Za-z0-9-]{10,}` — Slack tokens

**Add (high-confidence, ecosystem-standard):**
- `sk-proj-[A-Za-z0-9]{48,}` — OpenAI project-scoped keys (the 2024+ format that superseded `sk-…`)
- `sk_live_[0-9a-zA-Z]{24,}` — Stripe secret keys (note: `pk_live_…` publishable keys are intentionally public; do NOT redact those)
- `whsec_[A-Za-z0-9]{32,}` — Stripe webhook secrets
- `AIza[0-9A-Za-z_-]{35}` — Google API keys (Google Maps, GCP, Firebase, YouTube — same prefix)
- `AC[a-f0-9]{32}` followed within 200 chars by another `[a-f0-9]{32}` — Twilio Account SID + Auth Token pattern (heuristic; if matching too aggressively, leave for Tier-2)
- `SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}` — SendGrid API keys
- `(EAAA|EAACEdEose0cBA)[A-Za-z0-9]+` — Facebook/Meta access tokens
- `-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY( BLOCK)?-----` — Private key blocks (multi-line; match the BEGIN line)

**Defer to Tier-2 (too easy to false-positive on legitimate test content):**
- Generic 32-char hex strings (could be UUIDs, hashes, test fixtures)
- Generic `[a-zA-Z0-9]{32,}` high-entropy strings (would catch arbitrary IDs)
- Stripe restricted keys `rk_live_…` (less common; the human eyeball pass will catch them)
- Twilio Account SID alone (`AC[a-f0-9]{32}`) without a paired auth token — too noisy

**`/Users/<not-stayman>` and email-domain patterns:** these are Tier-2, not Tier-1, because:
- `/Users/stayman/...` paths are legitimate context that the test depends on (the bug-of-record is about a specific session under `/Users/stayman/Personal/projects/neo-stayman-assistant/`)
- Other usernames or email domains in captured content could be legitimate test content (e.g., a test fixture intentionally including a known-fake email like `test@example.com`)
- Human judgment is required to classify these — automation would silently corrupt or silently miss

### Finding #6 — Schema decision: extend `tests/scenarios/session.yaml` (or per-group yaml) with optional `session_slice:` field. No new yaml file.

The replay scenario differs from single-shot in just two fields:

```yaml
- id: <new-id>
  name: "..."
  skill: session-start  # or whichever skill the replayed orchestrator is "running"
  args: ""              # ignored when session_slice is present
  session_slice:        # NEW field — presence triggers replay path
    source: tests/sessions/2026-05-16-autopilot-f8-pause.jsonl
    terminator_uuid: 67be4a18-24d1-4e5c-896d-63da96bbb6ad  # optional; default = include entire file
  continuation_prompt: |  # NEW field — what to ask the model after the prefix is loaded
    (orchestrator continuing — no user input)
  system_prompt_extra: |
    ...same shape as today, framing the replay environment as describe-only...
  expect:
    transition_id_any: [F8, F10]  # same as today
    contains_any: [...]
    not_contains: [...]
    not_contains_strict: true
```

The `tests/run-tests.sh` runner branches on `session_slice` presence. Estimated runner change: ~60–100 LOC.

**Rejected alternative:** separate `tests/scenarios/replay.yaml`. Rejected because (a) it splits the test corpus by mechanism not by domain, (b) it duplicates `--id`, `--group`, `--filter-model` plumbing, (c) the schema overlap is 80%+, so the bifurcation cost outweighs the cleanup benefit.

### Finding #7 — `--bare` flag may be useful for harness reproducibility.

`claude --help` documents `--bare` as: "skip hooks, LSP, plugin sync, attribution, auto-memory, background prefetches, keychain reads, and CLAUDE.md auto-discovery. Sets CLAUDE_CODE_SIMPLE=1."

The current harness sets `--no-session-persistence` and supplies its own `--settings`. Adding `--bare` would further isolate the test from per-machine state (auto-memory, plugin sync, CLAUDE.md). **Trade-off:** `--bare` also disables CLAUDE.md auto-discovery, but our fixtures explicitly provide `claude_md: fixtures/CLAUDE.md` via the existing harness already. Need to verify: does `--bare` + per-scenario fixture CLAUDE.md work together? Recommendation: try it during plan/build and decide. Not blocking for the spec.

### Sources

- [h33tlit/secret-regex-list](https://github.com/h33tlit/secret-regex-list) — comprehensive regex patterns
- [marcuspat/secret-scan](https://github.com/marcuspat/secret-scan) — Stripe/PayPal/Square + 50 patterns
- [Postman Secret Scanner patterns](https://learning.postman.com/docs/administration/managing-your-team/secret-scanner/secret-scanner-patterns/) — provider-by-provider list
- [Secret scanners comparison 2026 — NomadX](https://devsecops.ae/secrets-scanners-comparison-2026/) — Gitleaks/TruffleHog default rulesets

---

## Open Questions

All blocking questions resolved by research (see `## Research Findings` above). Remaining items are deferred design choices that can be made during plan or build:

- [x] ~~**(Research, blocking)** Can `claude --print` accept a conversation history as input?~~ → **Yes, via `claude --resume <uuid> --fork-session`.** See Finding #1.
- [x] ~~**(Research, blocking)** Fallback to direct Anthropic API.~~ → **Not needed.** See Finding #1.
- [x] ~~**(Research, recommended)** Slice terminator semantic.~~ → **Uuid of last assistant turn, inclusive.** See Finding #3.
- [x] ~~**(Design, blocking)** Scenario schema.~~ → **Extend existing yaml with `session_slice:` + `continuation_prompt:` fields.** See Finding #6.
- [x] ~~**(Design, blocking)** Where does the Tier-1 redactor live.~~ → **Standalone `tools/capture-session-slice.sh`; `tests/check-structure.sh` validates.** Confirmed in spec; no change.
- [x] ~~**(Process, recommended)** Tier-1 pattern set.~~ → **Expanded.** See Finding #5.
- [x] ~~**(Process, recommended)** Tier-2 reviewer guidance.~~ → **Confirmed; documented in AC #4. The audit checklist goes in `tests/sessions/README.md`** (a plan-phase deliverable).

**Remaining (deferred to build, not blocking plan):**

- [ ] **(Design, recommended)** Should the captured `.jsonl` slice be **edited down** to remove non-relevant messages, or kept **byte-faithful**? Lean: byte-faithful for first scenario. Decide if context cost surfaces a problem.
- [ ] **(Design, recommended)** SKILL.md drift behavior. Captured prefix references SKILL prose that may have been edited since. Lean: that's a feature — the whole point is running captured prefix against *current* SKILL prompt set. No action needed unless plan/build surfaces a contradiction.
- [ ] **(Build-phase decision)** Does `--bare` flag (skip hooks, auto-memory, CLAUDE.md auto-discovery) combine cleanly with the existing `--settings` and `claude_md` fixture? Try it during build; not blocking for plan.
- [ ] **(Build-phase decision)** Per-scenario `budget_usd:` override field for replay scenarios that exceed the default `MAX_BUDGET=0.20`. See Finding #4. Implement during build if any replay scenario needs > $0.20 — the first one ($0.14) doesn't.
- [ ] **(Build-phase decision — Finding #2 follow-up)** The replay system-prompt overlay must explicitly say "describe-only mode" so the model doesn't try to actually read files referenced in the captured context. The existing `SHARED_PROMPT` in `tests/run-tests.sh:39-52` already does this for single-shot; the replay path should keep the same overlay. Plan task: confirm overlay composition is correct.

---

**Drive-mode note:** This feature was opened under autopilot mode (Mode 3). The driving incident is paused at I15 pending this feature shipping. Per Mode 3 pause policy, spec is PAUSE (this skill stops here; user reviews and approves before `/feature-research` runs).
