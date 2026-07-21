---
stage: roadmap
state: complete
updated: 2026-07-21
---

# Roadmap — Claude Code Workflow System

## Phase 1: Problem Tree & Structured Verification (Core Loop Integrity)

**Goal:** Make the build→verify→fix loop structurally sound. The WIP file becomes a persisted tree with node-level status. Verification produces persistent leaf nodes, not a flat checklist. Re-entry from any back-loop carries scoped context (which nodes failed, which are blocked). A parent node cannot advance until all children are complete.

**Motivation:** This is the most foundational gap. Pain Points 1 and 2 both root here — the flat WIP format is why the agent forgets B/C/D after fixing A, and why discoveries made on A.1 have nowhere to attach for B. Framework Gaps F1 and F2 (root problem re-identification per iteration, test-as-learning) both require the tree to exist before they can be addressed.

**Milestones:**
- [x] 1.1 Define the Work Tree node format — status values, parent-child notation, dependency-blocked status, surface-attached discoveries — and update the WIP file template
- [x] 1.2 Update `feature-plan` to emit the plan as a Work Tree, not prose phases
- [x] 1.3 Update `feature-verify-human` to expand phase verification into leaf nodes, record pass/fail per leaf, pass failed-leaf IDs as scoped args to `feature-build`
- [x] 1.4 Update `feature-build` to accept scoped args (specific failed leaves), attach in-flight discoveries to the correct tree node, and re-evaluate parent readiness before transitioning out
- [x] 1.5 Update `task-plan` / `task-act` with the same tree-scoped re-entry pattern (lighter version)
- [x] 1.6 Update transition test scenarios to cover: partial verify-human failure, scoped re-entry, cross-node discovery attachment

**Exit Criteria:**
- A verify-human rejection for item A does not cause B/C/D to be skipped or treated as implicitly done
- A discovery made while fixing A.1 appears as an explicit child node of B before the agent ever reaches B
- Re-entry to `feature-build` from a rejection carries the specific failed leaf IDs, not just "phase N"
- All Phase 1 transition tests pass on haiku

---

## Phase 2: Agent Self-Verification Before Human Handoff

**Goal:** The agent must observe the running system — in a browser, via curl, via CLI with real data — before handing off to the human. The human only sees issues the agent genuinely cannot verify itself. A re-verify gate exists after every agent-initiated fix. Failures are triaged into blocking vs. cosmetic before escalation.

**Motivation:** Pain Point 2. The current `feature-verify-auto` is a test-runner gate. It has no mandate to start the application and observe it. Framework Gap F6 (unknown-unknown detection) is also addressed here — behavioral definitions of done force the agent to state observable outcomes before building, which surfaces unknown-unknowns cheaply.

**Milestones:**
- [x] 2.1 Observable Outcomes format defined and embedded in `feature-plan/SKILL.md`; format uses `Browser:`, `HTTP:`, `CLI:` prefixes; rule "written at plan time" is explicit
- [x] 2.2 Severity taxonomy (BLOCKING/COSMETIC) inline in `feature-verify-self/SKILL.md` with concrete examples
- [x] 2.3 Created `feature-verify-self` skill: reads Observable Outcomes, runs Playwright/curl checks, classifies failures by severity; F9b (blocking → build) and F10b (cosmetic-only → verify-human) transitions
- [x] 2.4 Re-verify gate added to `feature-build/SKILL.md`: on re-entry from verify-self back-loop, agent re-runs failed behavioral checks before transitioning to verify-auto
- [x] 2.5 `feature-verify-human` pre-filter strengthened: EXCLUDED table, UNVERIFIED annotation, cosmetic failures as low-priority notes
- [x] 2.6 All Phase 2 scenarios pass on haiku (F9b, F9b-rerun, F10b, F10-clarified, F8-reverify, F13-prefiltered, F7-observable-outcomes, F7-worktree)

**Exit Criteria:**
- Agent never hands a blank page or JS console error to the human — it catches and fixes those itself
- After a human rejection and agent fix, the agent re-runs its own observable checks before handing back
- Human verification checklist contains only items that require human judgment, not items the agent could have checked with Playwright or curl

---

## Phase 3: WBS Decomposition by Learning Sequence

**Goal:** The WBS orders work by risk and learning dependencies, not build dependencies. A "spike/probe" class of work package exists. 3rd-party API unknowns become explicit blockers on downstream WPs. The standard phase sequence is: (0) Docker env, (1) 3rd-party probes, (2) frontend mockups, (3) backend without orchestration, (4) orchestration as refactor.

**Motivation:** Pain Point 3. Framework Gaps F3 (explicit prioritization) and F6 (unknown-unknown detection at the WBS level) are addressed here.

**Milestones:**
- [ ] 3.1 Define the "spike/probe" work package class — distinct from "build" WPs, with explicit learning objectives, timebox, and success criterion (what do we now know that we didn't before)
- [ ] 3.2 Update `product-wbs` prompt to require learning-sequence ordering: assert the standard phase pattern (Docker → probes → UI mockups → backend → orchestration), allow deviation only with written rationale
- [ ] 3.3 Update `product-wbs` prompt to require explicit prioritization rationale per phase — not just dependency arrows, but "why this before that" in terms of risk reduction
- [ ] 3.4 Update `product-wbs` prompt to classify 3rd-party integrations as blockers on downstream WPs until a probe has been completed and its I/O shapes documented
- [ ] 3.5 Add a `feature-spec` / `feature-plan` check: if the feature depends on a 3rd-party integration with no completed probe, flag it as a known unknown and recommend a spike before planning

**Exit Criteria:**
- A WBS for a project with 3rd-party API integrations always includes a probe WP before any WP that assumes known API shapes
- Orchestration layers (queues, workers, async infrastructure) always appear in a later phase than the synchronous path they will eventually wrap
- Every phase ordering has a written "why this before that" rationale, not just dependency arrows

---

## Phase 4: Framework Alignment — Iterative Re-identification and Exit Conditions

**Goal:** Close the remaining framework gaps: root problem re-identification between iterations, per-iteration relevance checks, and mandatory retrospect + communicate at cycle close.

**Motivation:** Framework Gaps F1, F4, F5. These are lower urgency because they don't cause the acute failures described in the pain points, but they are responsible for the longer-tail drift (solving the wrong problem, continuing irrelevant work, not closing the loop with stakeholders).

**Milestones:**
- [ ] 4.1 Add a "problem statement check" prompt to `feature-build` and `task-act` back-loop entries: before re-planning, ask "has our understanding of the root problem changed based on what we just learned?"
- [ ] 4.2 Add a relevance gate to `feature-plan` and phase-advance logic: before starting a new phase, check the relevance signals checklist (requester still needs it, requirements unchanged, solution still feasible, no superior alternative discovered)
- [ ] 4.3 Update `task-close` and `feature-finalize` to require both a retrospect artifact (what changed in our understanding) and a communicate step (confirmation that the requester knows the work is done and what it does) — these are separate prompts, not conflated
- [ ] 4.4 Update transition test scenarios for the new prompts

**Exit Criteria:**
- Back-loop re-entries to `feature-plan` or `task-plan` always include a problem-statement re-check artifact in the WIP file
- Phase-advance transitions include a relevance check before proceeding
- `task-close` and `feature-finalize` produce two distinct outputs: a retrospect note and a communicate confirmation

---

## Phase 5: Hardening — Tests, Polish, Secondary Audience

**Goal:** All new behavior from Phases 1–4 is covered by transition tests. `install.sh`, documentation, and onboarding experience are updated to reflect the new WIP format and skill behaviors. Secondary audience (other Claude Code users) can adopt the system without needing to read the source.

**Milestones:**
- [ ] 5.1 Full transition test coverage for all new scenarios introduced in Phases 1–4
- [ ] 5.2 Update `CLAUDE.md`, skill `argument-hint` fields, and any user-facing documentation to reflect the Work Tree format and new skill behaviors
- [ ] 5.3 Validate that `install.sh` is still idempotent and that new file templates are included correctly
- [ ] 5.4 Optionally: publish a `USAGE.md` or README section targeting secondary audience adoption

**Exit Criteria:**
- `tests/run-tests.sh` passes clean on haiku for all groups
- A user who has never seen the system can read `CLAUDE.md` + one skill file and understand the Work Tree format
- `install.sh` runs clean on a fresh machine with no prior symlinks

---

## Phase 6: Orchestration Loop Integrity (v2 cycle — PP5 + PP4)

**Goal:** Close two gaps diagnosed in `workflow-pain-points-2.md`: (1) the orchestrator stops after every step even when no human decision is required, and (2) the agent silently triages test failures at verify-codify without a decision procedure or audit trail.

**Milestones:**
- [x] 6.1 (WP14) AUTO/PAUSE policy table in `agents/feature-workflow/AGENTS.md`; back-loops and ship are AUTO; TRANSITION token clarified as machine signal
- [x] 6.2 (WP15) Six-case test triage protocol in `feature-verify-codify/SKILL.md` with mandatory WIP artifact and hard rule against test modification without triage
- [x] 6.3 (WP16) Triage test scenarios F16-triage-{regression,ambiguous,flaky,contract}
- [x] 6.4 (WP17) transitions.md AUTO/PAUSE section, CLAUDE.md conventions updated, structure checks pass

**Exit Criteria:**
- In orchestrated mode, clean-pass steps chain without user prompting; verify-human and finalize remain PAUSE
- verify-codify always writes a triage artifact before acting on any test failure
- 95 transition scenarios pass on haiku

## Group — Claudesk Handoff Cycle (secondary non-workflow-user readiness)

<!-- New cycle, 2026-07-20. Inbound from HANDOFF-from-claudesk-2026-07-20.md. These 5
     milestones are properties of the skills/workflow system itself (the seam test:
     "does it require Claudesk to run?" → No → this repo owns it). This repo ships FIRST;
     Claudesk then builds the gate (their M10.9) + Docs viewer (their M11) that CONSUME
     these deliverables. A cross-repo return contract to /Users/stayman/Personal/projects/claudesk
     closes the loop (see Milestone 12). Milestone numbering continues the flat list;
     groups are cosmetic only. -->

### Milestone 7: Unify the workflow-doc layout for new users ✅ COMPLETE 2026-07-21
**Origin:** SURFACE-2026-07-20-CLAUDESK-UNIFY-DOC-FOLDERS (resolved)
**Shipped as:** the `doc-layout-unification` feature (Option A physical unification) — `docs/product/*` → `workflow-system/product/`, `workflow/*` → `workflow-system/state/`. 58-file path-anchored sweep + `tools/migrate-doc-layout/` migration primitive (9 consuming projects migrated, gospelherald excluded) + `check-structure.sh` Phase-15 anti-regression lock. Settled layout + Claudesk M11 `docs_list` change captured for the M12 return contract (WP8).
**Goal:** Reduce the two-location learning cost (`docs/product/*` strategic + `workflow/*` operational) to a single friendlier top-level layout — or a clearly-indexed single entry point — for users new to the workflow. This is foundational: every other milestone and the Claudesk return contract reference the settled layout.
**Deliverables:**
- A decided doc-folder layout (co-located single root, or a top-level index that unifies the two locations) with the rename/move plan
- All workflow skills/agents that read or write these paths updated to the new layout (this touches many `skills/*/SKILL.md` and `agents/*/AGENTS.md` — a doc-convention change, not a one-file edit)
- `CLAUDE.md` / `CLAUDE.snippet.md` and `workflow-system/product/arch.md` resynced to the new layout
- Structure-check pins (`tests/check-structure.sh`) updated to the new paths
**Exit Criteria:**
- A new user can find both strategic and operational workflow state from one obvious place
- No skill references a stale path; `tests/check-structure.sh` passes
- The settled layout (exact paths Claudesk M11's `docs_list` must discover) is written down for the return contract

### Milestone 8: Standalone `uninstall.sh` + `install.sh` as single source of truth ✅ COMPLETE 2026-07-21
**Origin:** SURFACE-2026-07-20-CLAUDESK-STANDALONE-UNINSTALL
**Shipped as:** the `uninstall-sh` feature (WP4, commit 74cbb7c) — a standalone, defensive `uninstall.sh` reversing every install action (into-repo-guarded symlink removal, block-only CLAUDE.md excise with backup, `--project`-gated memory-symlink removal, print-only settings reminder). 45-assertion E2E harness (`tools/uninstall/test/run-tests.sh`, env-HOME-per-call isolation) incl. the install→uninstall→re-install round-trip; 6 dry-run-only `check-structure.sh` pins. M12 install/uninstall command copy captured in the archived WIP return-contract section. Note: install.sh only *prints* the settings.json perms (no hook registration in settings.json), so uninstall symmetrically only prints — the "hook registration" deliverable wording was reconciled to install.sh's actual behavior (AD-2).
**Goal:** Make the skill system cleanly installable AND removable with **zero** Claudesk dependency, so a curious user can try the workflow and back out leaving no residue.
**Deliverables:**
- A standalone `uninstall.sh` that reverses everything `install.sh` sets up: the skill/agent symlinks into `~/.claude/`, the `~/.claude/settings.json` hook registration, and the per-project memory symlink
- `install.sh` confirmed/kept as the canonical single source of truth for install steps (idempotent; the copy Claudesk's invite will *display*, not hardcode)
- Verification that install → uninstall → re-install is clean and idempotent
**Exit Criteria:**
- `uninstall.sh` run on a fresh install leaves `~/.claude/` and the project with no workflow-system residue
- Works invoked directly from a shell with Claudesk not present
- Canonical install-instruction copy + commands captured for the return contract

### Milestone 9: Disambiguate "pause" (course-correct vs. `/session-pause`) ✅ SHIPPED 2026-07-21 (WP5, commit f532b4d)
**Origin:** SURFACE-2026-07-20-CLAUDESK-PAUSE-AMBIGUITY (resolved)
**Goal:** Remove the overloaded meaning of the bare word "pause" so the orchestrator never drops a wanted `session-pause` nor writes a `.session.md` when the operator only meant "stop and reconsider."
**Deliverables:**
- Orchestrator/skill prompt updates that reserve bare "pause" for course-correction and require explicit `/session-pause` (or a distinct phrase) for the skill — or an intent-confirm when the word is ambiguous
- Behavioral test scenario(s) covering the ambiguous-input case
**Exit Criteria:**
- Ambiguous "pause" no longer silently invokes `session-pause`; intent is confirmed or the word is reserved as decided
- Scenario coverage passes

### Milestone 10: Resolve the "research" skill naming collision
**Origin:** SURFACE-2026-07-20-CLAUDESK-RESEARCH-SKILL-COLLISION
**Goal:** Prevent this repo's `product-research` / `feature-research` skills from colliding with Claude Code's built-in **deep-research** capability so "research" doesn't fire the wrong skill.
**Deliverables:**
- Decision + implementation: rename/namespace this repo's research skills, or add orchestrator disambiguation
- All references updated (skills, agents, `transitions.md`, scenarios, `CLAUDE.md`) if a rename is chosen
**Exit Criteria:**
- Saying "research" in a workflow context no longer risks firing CC's built-in deep-research (or vice versa)
- All three state-machine locations stay in sync if IDs/names change

### Milestone 11: New-user onboarding + "aha" design (brainstorm-first)
**Origin:** SURFACE-2026-07-20-CLAUDESK-ONBOARDING-DESIGN
**Goal:** Design the deliberate first-run path a brand-new user takes when Claudesk invites them in — the fastest "aha" (the moment the workflow's value clicks) — and decide whether it needs a dedicated onboarding skill and/or a throwaway tutorial project.
**Deliverables:**
- An onboarding flow spec (what a new user does first, the aha moment, the surface Claudesk should render + when)
- A decision on a dedicated onboarding skill and/or tutorial project
**Exit Criteria:**
- A written onboarding flow spec Claudesk can render against
- ⚠️ **Brainstorm-first / co-design:** this milestone is explicitly designed *with* the operator — depends on the settled Milestone 7 layout + Milestone 8 install flow; not auto-generated

### Milestone 12: Cross-repo return contract to Claudesk
**Origin:** Handoff return contract (HANDOFF-from-claudesk-2026-07-20.md → "What Claudesk needs back from you")
**Goal:** Close the loop so Claudesk's M10.9 + M11 can build against settled, non-moving deliverables.
**Deliverables:**
- A "here's what changed + here's the copy/paths for Claudesk" note back to `/Users/stayman/Personal/projects/claudesk` (reciprocal handoff or a backlog SURFACE there) carrying: (1) canonical install-instruction copy + install/uninstall commands, (2) the settled doc-folder layout (so M11's `docs_list` discovery matches), (3) the onboarding flow spec
**Exit Criteria:**
- Claudesk has received the three deliverables in a form it can consume without hardcoding workflow internals

## Revision 2026-07-20 — Claudesk Handoff Cycle

**What changed:** Reopened the roadmap (`state: complete` → `in-progress`) to add a new cycle (Milestones 7–12) sequencing the five inbound items from `HANDOFF-from-claudesk-2026-07-20.md`, plus a cross-repo return-contract milestone. These are properties of the skills/workflow system itself (not Claudesk-coupled runtime), so this repo owns them and ships first.

**Sequencing rationale:**
- **M7 (doc-folder unify) first** — foundational; it's the layout every other milestone and the Claudesk return contract reference, and the thing Claudesk M11's Docs viewer must discover. Dependency-driven ordering, not a product-design lean.
- **M8 (install/uninstall) second** — unblocks Claudesk's invite + the "try-and-back-out" story; standalone, but naturally after the layout settles since uninstall must clean up whatever paths M7 establishes.
- **M9 (pause) + M10 (research collision)** — small, independent, prompt-level; could run in parallel/either order. Placed after the foundational pair for a clean linear drive, no hard dependency.
- **M11 (onboarding) last** — brainstorm-first, co-designed with the operator; depends on the settled M7 layout + M8 install flow to build a coherent first-run story.
- **M12 (return contract) terminal** — aggregates M7/M8/M11 deliverables back to Claudesk.

**Assumptions:** This cycle does NOT reopen this repo's `vision.md` Target Audience section — the audience-stance refinement (adding a non-workflow secondary user) is assigned to the *Claudesk* side per the handoff; this repo delivers the mechanics only. `docs/product/design-priors.md` is absent in this repo, so no design-prior consult applied (silent no-op).
