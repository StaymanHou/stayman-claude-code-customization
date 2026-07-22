# Feature: WP7g — Tour-copy corrections before WP7e pins freeze

**Workflow:** feature
**State:** COMPLETED 2026-07-22
**Created:** 2026-07-22
**drive_mode:** autopilot

## Problem Statement
The operator ran the shipped `tutorial-*` onboarding tour by hand and produced Round-1 (FB-1…FB-5) + live Round-2 (items 0–6) feedback. Five operator-ratified corrections must land in the shipped tour copy **and be accepted via a fresh hands-on run** BEFORE WP7e freezes its structural pins/scenarios (pins must lock *accepted* copy, not current copy). The corrections: (1) recommend **`auto`** permission mode — SUPERSEDING the `acceptEdits` recommendation the operator never endorsed and which prompts on every shell step; (2) rewrite both arms' handoff→restore bookend to lead with **context-window management** (a curated, better-than-`/compact` alternative that frees the window without losing load-bearing strategic context) + a concrete check-usage→exit→restore→check-usage demonstrable beat — mechanics-faithful to what `/session-handoff` actually preserves; (3) make **stepping** mode explicit + imperative (the graduation reveal depends on the pause being visible); (4) add a pre-flight "where to run this" instruction branching greenfield (clarify disposable-copy model) vs brownfield (exit + cd + relaunch); (5) fold the two open WP7d MINORs (Category scope-symmetry + close terminal-action) into this copy sweep. Prose/spec-only — **no** transition, no state-machine change. This is a `tutorial-*` family edit (three skills) + `onboarding-flow-spec.md` §5a/§5b. Verify-human here IS the operator's real hands-on acceptance run — driven to verify-self this session, then STOP and reconvene for the fresh acceptance run (separate session).

## Verified mechanics (for phase 2 / FB-3 honesty — done at plan time)
`/session-handoff` writes `workflow-system/state/.session.md` (a pointer: `workflow`/`step`/`resume_skill`/`state_file`/`drive_mode` + a handoff note: Last-completed / Next-action / Open-blockers / Notes) and appends a one-line `## Session Handoff` marker to the state file. The strategic context (roadmap/WBS/progress/blockers/open backlog) survives **because the pointer references the on-disk state files and `/session-restore` re-reads them fresh** — NOT because the pointer copies the plan into itself. So the honest FB-3 headline is: handoff frees the context window while the load-bearing plan stays on disk, rediscoverable by a fresh context (unlike `/compact`, which summarizes and can lose exactly that). Do not claim the pointer "saves the whole plan."

## Auto-mode facts (for phase 1 — from official docs, verified this session)
`auto` mode: runs shell + network + edits without routine prompts, but a classifier reviews each action and blocks escalations (curl|bash, force-push, prod deploy, mass delete, secret exfil, `git reset --hard`, `rm -rf` of unnamed targets, …). Low-friction AND keeps "stays safe/local" honestly true. **Requires** Opus 4.6+/Sonnet 4.6+/Fable 5 + an allowing account/provider → copy MUST say "if auto mode is available." Launch: `claude --permission-mode auto` (or `defaultMode:"auto"` in `~/.claude/settings.json`, ignored from project settings; or Shift+Tab if available).

## Work Tree

- [x] Phase 1: Permission mode → `auto` + explicit stepping + pre-flight where-to-run (dispatcher + spec §5a/§5b)  <!-- status: [x] -->>
  **Observable outcomes:**
  - CLI: `grep -c "auto" skills/tutorial-getting-started/SKILL.md` ≥ 1 AND `grep -qi "permission-mode auto\|--permission-mode auto" skills/tutorial-getting-started/SKILL.md` exits 0 (launch command present)
  - CLI: `grep -qi "if auto mode is available\|auto mode.*available\|available" skills/tutorial-getting-started/SKILL.md` exits 0 (availability caveat present)
  - CLI: dispatcher Step 2 no-menu block names **stepping** explicitly and imperatively — `grep -qi "stepping mode" skills/tutorial-getting-started/SKILL.md` exits 0, and the ambiguous bare "stepping/orchestrated" is replaced
  - CLI: a pre-flight "where to run this" instruction exists in the dispatcher — `grep -qi "where to run\|before you start\|/exit\|cd " skills/tutorial-getting-started/SKILL.md` exits 0
  - CLI: spec §5b updated — `grep -qi "auto" workflow-system/product/onboarding-flow-spec.md` in §5b region AND the acceptEdits recommendation marked superseded
  - CLI: `./tests/check-structure.sh` exits 0 (no structural regression)
  - [x] P1.1 Rewrite dispatcher Step 1 → recommend `auto` (availability caveat + `claude --permission-mode auto` launch command); update the frontmatter `description:` (drop "accept-edits")  <!-- status: [x] -->
  - [x] P1.2 Rewrite dispatcher Step 2 no-menu block → explicit imperative **stepping** mode (replace bare "stepping/orchestrated")  <!-- status: [x] -->
  - [x] P1.3 Add dispatcher pre-flight "where to run this" instruction (branch: brownfield exit+cd+relaunch; greenfield clarify disposable-copy model — do NOT say cd-to-empty-dir)  <!-- status: [x] -->
  - [x] P1.4 Update spec §5b (permission mode → auto, mark acceptEdits superseded) + §5a (explicit stepping)  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x]; check-structure.sh 472/0 (25s) 2026-07-22 -->
  - [x] verify-self  <!-- status: [x]; subagent 7/7 PASS incl. coherence/honesty read — no over-claim, stepping-vs-auto distinction explicit, caveat honest. No integration boundary requiring a running app (prose/spec). 2026-07-22 -->
  - [x] verify-human  <!-- status: [x] SKIPPED by operator override 2026-07-22 — copy accepted without a fresh-session hands-on run -->
  - [x] verify-codify  <!-- status: [x]; codify = check-structure.sh 472/0 (structural pins hold). Full behavioral scenarios + tutorial-prefix pins are WP7e's charter, deliberately not pulled into WP7g. 2026-07-22 -->

- [x] Phase 2: Handoff value-prop rewrite (both arms Step 7) + explicit stepping in both arms' cadence lines  <!-- status: [x] -->
  **Observable outcomes:**
  - CLI: greenfield Step 7 leads with context-window management — `grep -qi "context window\|context-window" skills/tutorial-greenfield-workflow-tour/SKILL.md` exits 0
  - CLI: greenfield Step 7 contrasts with `/compact` — `grep -qi "compact" skills/tutorial-greenfield-workflow-tour/SKILL.md` exits 0
  - CLI: brownfield Step 7 leads with context-window management AND `/compact` contrast — both greps exit 0 on the brownfield file
  - CLI: the demonstrable beat present in at least the greenfield arm — `grep -qi "context usage\|check.*usage\|token" skills/tutorial-greenfield-workflow-tour/SKILL.md` exits 0
  - CLI: both arms' cadence lines say **stepping** explicitly (not bare "stepping/orchestrated") — `grep -qi "stepping mode" skills/tutorial-greenfield-workflow-tour/SKILL.md` AND same on brownfield exit 0
  - CLI: `./tests/check-structure.sh` exits 0
  - [x] P2.1 Greenfield Step 7 rewrite → context-window-mgmt headline + `/compact` contrast + check-usage→exit→restore→check-usage demonstrable beat; keep cross-session as secondary; mechanics-faithful  <!-- status: [x] -->
  - [x] P2.2 Brownfield Step 7 rewrite → same headline + `/compact` contrast + demonstrable beat; mechanics-faithful  <!-- status: [x] -->
  - [x] P2.3 Both arms' cadence lines → explicit imperative **stepping** (replaced bare "stepping/orchestrated" everywhere in both arms; also swept stale accept-edits→auto in both arms' Framing)  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x]; check-structure.sh 472/0 2026-07-22 -->
  - [x] verify-self  <!-- status: [x]; grep observable-outcomes all PASS + subagent 5/5 PASS incl. load-bearing honesty read (context-window headline + /compact contrast + demonstrable beat both arms; explicit stepping both arms; no bare stepping/orchestrated; no stale accept-edits; mechanics-faithful, no over-claim). 2026-07-22 -->
  - [x] verify-human  <!-- status: [x] SKIPPED by operator override 2026-07-22 — copy accepted without a fresh-session hands-on run -->
  - [x] verify-codify  <!-- status: [x]; codify = check-structure.sh 472/0. Behavioral scenarios + pins = WP7e. 2026-07-22 -->

- [x] Phase 3: Fold the two WP7d MINORs (Category scope-symmetry + close terminal-action) into the copy sweep  <!-- status: [x] -->
  **Observable outcomes:**
  - CLI: both arms' Category sections no longer carry the literal-mechanics overstatement "does not return control to the dispatcher" verbatim (or it's corrected to the dispatcher-fix phrasing) — `grep -c "does not return control to the dispatcher" skills/tutorial-greenfield-workflow-tour/SKILL.md skills/tutorial-brownfield-workflow-tour/SKILL.md` reflects the fix
  - CLI: both arms' close paragraphs (Step 8) state the terminal action explicitly (not only in `## Transitions`) — `grep -qi "ends\|the tour is over\|nothing further\|run is complete\|hands the user back" ` near the close in each arm
  - CLI: `./tests/check-structure.sh` exits 0
  - [x] P3.1 Fix scope-symmetry: mirror the WP7d dispatcher control-return phrasing fix into BOTH arm Category blocks (SURFACE-2026-07-22-QUALITY-ARM-CATEGORY-CONTROL-RETURN-SCOPE-SYMMETRY) — verified finding accurate against real text first; replaced literal "does not return control" with "runs the tour to its close / dispatcher not resumed"  <!-- status: [x] -->
  - [x] P3.2 Fix terminal-action-implicit: state the terminal action at each arm's close paragraph, not only in `## Transitions` (SURFACE-2026-07-22-QUALITY-ARM-CLOSE-TERMINAL-ACTION-IMPLICIT) — added "The tour ends here — nothing further to invoke, no transition to emit" to both closes  <!-- status: [x] -->
  - [x] verify-auto  <!-- status: [x]; check-structure.sh 472/0 2026-07-22 -->
  - [x] verify-self  <!-- status: [x]; grep observable-outcomes all PASS (0 literal-overstatement occurrences; both arms softened phrasing + explicit terminal action). 2026-07-22 -->
  - [x] verify-human  <!-- status: [x] SKIPPED by operator override 2026-07-22 — copy accepted without a fresh-session hands-on run -->
  - [x] verify-codify  <!-- status: [x]; codify = check-structure.sh 472/0. Behavioral scenarios + pins = WP7e. 2026-07-22 -->

## Current Node
- **Path:** Feature > review-quality COMPLETE (0C/0MAJ/3MIN — 2 fixed inline, 1 backlogged) > feature-finalize
- **Active scope:** ship ✅ + review-quality ✅. Next: feature-finalize (commit WP7g locally, CHANGELOG entry, archive WIP; NO push per close-commit discipline), then STOP + reconvene (operator's instruction) before WP7i/WP7j/WP7h.
- **Blocked:** none
- **Unvisited:** (post-WP7g) WP7i richer sample, WP7j replay+git-safety, WP7h full product-cycle tour, WP7e scenarios+pins.
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow-system/state/backlog.md -->

## Code-Quality Review — wp7g-tour-copy-corrections

Reviewer subagent (`code-quality-reviewer`), baseline HEAD a1d4c2b, drive_mode=autopilot (Mode 3). **0 CRITICAL / 0 MAJOR / 3 MINOR.**

### Strengths
- `auto`-mode rewrite factually airtight, matches the verified permission-modes reference (caveat + launch cmd + bypass contrast), no over-promise.
- Handoff→restore rewrite scrupulously mechanics-faithful ("one tiny pointer… doesn't copy your whole plan into itself; it points at the files on disk").
- `stepping` (drive mode) vs `auto` (permission mode) distinction stated crisply and repeated at each site — pre-empts the conflation risk.
- Provenance discipline: superseded `acceptEdits` §5b text retained in a `<details>` block with an honest "operator never endorsed this" note.
- Scope-symmetry clean across all three skills + spec (stepping / Framing-auto / Category-scope / terminal-action swept in lockstep).

### Issues
**CRITICAL** — (none)
**MAJOR** — (none)
**MINOR**
- [onboarding-flow-spec.md:15] intro's "only one place: acceptEdits vs bypassPermissions" self-description was stale post-WP7g. **→ FIXED inline this session** (now "permission-mode distinction… further revised to `auto` in WP7g").
- [onboarding-flow-spec.md:36] WP7b-revision narrative said dispatcher "Recommends `acceptEdits`" as a live claim, contradicting shipped Step-1. **→ FIXED inline this session** (now "Recommends `auto` mode (revised from acceptEdits in WP7g — see §5b)").
- [tutorial-getting-started/SKILL.md Step-0 brownfield] tells the user to relaunch `claude --permission-mode auto` before Step 1 introduces auto + its availability caveat; forward-ref "(see the next step)" softens it but a user on an older model is told to launch with `--permission-mode auto` before being told it may be unavailable. **→ BACKLOGGED** (`SURFACE-2026-07-22-QUALITY-WP7G-STEP0-AUTO-CAVEAT-ORDERING`) — copy-design nit better validated at a real tour run; cheap half-sentence fix candidate for WP7i/WP7j or the operator's eventual hands-on run.

### Assessment
A disciplined copy sweep; a model example of prose/spec corrections in this repo. Every operator-flagged load-bearing risk handled correctly and consistently across all four in-scope files. Advances the codebase (supersedes an un-endorsed inference with a documented ruling, preserves provenance, state-machine surface untouched). Two of the three MINORs were stale self-references introduced this session → fixed inline; the third is a minor ordering seam → backlogged. Nothing warrants a refactor pass.

### Disposition (operator read-time veto available)
2 MINORs fixed inline (own-drift cleanup, cheap+safe); 1 MINOR backlogged. To dismiss/re-open any, edit this section and mark `[DISMISSED]` before finalize archives the file.

## Retrospect
- **What changed in our understanding:** The acceptEdits recommendation shipped in WP7a/WP7b was a *prior-session inference the operator never endorsed* — surfaced only when the operator ran the tour by hand and hit the prompt-on-every-shell-command friction. The correct fit is `auto` mode (classifier-gated: low-friction AND honestly-safe), which wasn't even in the earlier reference memory. Also confirmed at plan time exactly what `/session-handoff` preserves (a pointer + on-disk re-read, NOT a copied-in plan) so the FB-3 rewrite could be mechanics-faithful rather than over-claiming.
- **Assumptions that held:** WP7g is genuinely prose/spec-only — no transition, no state-machine change, check-structure.sh stayed 472/0 throughout. The three-skill family structure made scope-symmetry (dispatcher + both arms + spec) a clean parallel sweep. The §8 build-constraint (permission-mode guidance lives in the skill, not Claudesk's invite) was *proven* by this change landing entirely in-repo.
- **Assumptions that were wrong:** I initially recorded acceptEdits as a "settled" decision in a prior session; the operator corrected that it was never theirs. Lesson reinforced: a "settled" tag in a spec/memory is only as good as an actual operator endorsement — verify against the origin, don't inherit a prior agent's inference as fact.
- **Approach delta:** Planned to drive build→verify-self then STOP before verify-human for a fresh-session acceptance run; the operator instead said "skip verify-human," so the fresh-run acceptance didn't happen (recorded honestly as accepted-without-live-run). Review-quality found 2 stale self-references I'd introduced this session — fixed inline rather than backlogged (own-drift, cheap+safe), a small deviation from the Mode-3 auto-backlog default, disclosed in the review section.

## Notes
- **verify-human SKIPPED by operator override (2026-07-22).** The operator accepted the corrected copy without a fresh-session hands-on run. **Consequence for the paper trail:** `SURFACE-2026-07-22-WP7C-OPERATOR-HANDS-ON-ACCEPTANCE-DEFERRED` is **accepted-without-live-run**, NOT resolved-by-run — the operator judged the copy acceptable from the diff/feedback loop rather than a live tour. finalize should record this honestly (accepted, not run) rather than claiming a hands-on acceptance happened.
- **No transition / no state-machine change** — `tutorial-*` skills emit no transition; WP7g is prose/spec-only. No `transitions.md` edit.
- **Bootstrap-skip caveat:** editing a live-symlinked `skills/*/SKILL.md` means the harness may serve OLD prose if these skills are re-invoked mid-session. Real validation of behavioral effect is the operator's fresh-session acceptance run (which is exactly verify-human here). No mid-session re-invocation of the edited skills is needed for verify-self (verify-self here is grep/structural, not a live tour run).
- **Downstream:** WP7j depends on Phase 1's explicit-stepping change (its replay invite extends the graduation reveal). WP7e pins this accepted copy. WP7h part-a (greenfield pointer) rides after.
