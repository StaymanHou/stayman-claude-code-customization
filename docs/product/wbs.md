---
stage: wbs
state: complete
updated: 2026-04-27
---

# Work Breakdown Structure — Claude Code Workflow System

## Dependency Map (Critical Path)

```
WP1 (Work Tree Format)
  └─► WP2 (feature-plan)
  └─► WP3 (feature-verify-human)
        └─► WP4 (feature-build + re-verify gate)
  └─► WP5 (task-plan / task-act)
  └─► WP6 (Behavioral DoD format)
        └─► WP7 (feature-verify-auto live observation)
              └─► WP4 (re-verify gate depends on DoD + auto)
WP6 ──► WP8 (severity taxonomy)
              └─► WP7

WP9 (fixture updates) — depends on WP1–WP5
WP10 (product-wbs learning-sequence) — independent, Phase 3
WP11 (feature-plan/spec probe check) — depends on WP10
WP12 (framework alignment back-loops) — independent, Phase 4
WP13 (hardening + docs) — depends on all prior WPs
```

**Parallel tracks:**
- WP1–WP5 (tree format + skill contracts) can progress independently of WP6–WP8 (DoD + severity)
- WP10–WP11 (Phase 3 WBS fixes) are fully independent of Phases 1–2
- WP12 (Phase 4 framework alignment) is independent of Phases 1–3

---

## Phase 1: Problem Tree & Structured Verification

### WP1: Work Tree Node Format
**Description:** Define and document the canonical Work Tree format. The grammar (status vocabulary, schema, rules) lives in `CLAUDE.snippet.md` (injected globally). Individual skill SKILL.md files reference behavior, not spec. No depth cap — tree is recursive as needed.
**Phase:** 1
**Dependencies:** None — foundational
**Size:** S
**Tasks:**
- [x] 1.1 Write the Work Tree grammar into `CLAUDE.snippet.md` as a new `## Work Tree Format (GLOBAL)` section — status vocabulary, `## Current Node` schema, `## Discoveries` section, HTML comment convention, parent-completion rule, tree-update-on-exit rule
- [x] 1.2 Update `tests/fixtures/wip/` — create one canonical Work Tree fixture file (e.g., `feature-plan-worktree.md`) that all Phase 1 skill tests can reference
- [x] 1.3 Update the WIP file template embedded in `feature-plan`'s SKILL.md to emit Work Tree format (do not update the skill's behavior yet — that is WP2)
- [x] 1.4 Re-run `./install.sh` to inject updated CLAUDE.snippet.md into `~/.claude/CLAUDE.md`

---

### WP2: Update `feature-plan` — Emit Work Tree
**Description:** Modify `feature-plan` to produce a WIP file in Work Tree format instead of flat prose phases. It must also emit Observable Outcomes per phase node at plan time.
**Phase:** 1
**Dependencies:** WP1
**Size:** M
**Tasks:**
- [x] 2.1 Update `skills/feature-plan/SKILL.md`: replace flat-checklist WIP template with Work Tree template; add instruction to write Observable Outcomes per phase at plan time
- [x] 2.2 Add instruction: verification group nodes (`verify-auto`, `verify-self`, `verify-human`, `verify-codify`) must be pre-populated as `NOT-STARTED` leaf nodes under each phase
- [x] 2.3 Add instruction: `## Current Node` section must be initialized pointing to Phase 1, first impl task
- [x] 2.4 Update `tests/scenarios/` — added F7-worktree scenario

---

### WP3: Update `feature-verify-human` — Leaf-Level Pass/Fail
**Description:** Modify `feature-verify-human` to expand verification into persistent leaf nodes in the Work Tree, record individual pass/fail per leaf, and pass failed leaf IDs as scoped args when sending back to `feature-build`.
**Phase:** 1
**Dependencies:** WP1
**Size:** M
**Tasks:**
- [x] 3.1 Update `skills/feature-verify-human/SKILL.md`: on first run for a phase, expand `verify-human` node into leaf items (one per check); write each leaf with a status tag
- [x] 3.2 Add instruction: on subsequent runs (re-entry from build), present only the leaves that are `FAILED` or `BLOCKED` — skip `[x]` leaves
- [x] 3.3 Add instruction: mark `BLOCKED` leaves explicitly with `BLOCKED: depends on <node>` — do not silently skip them
- [x] 3.4 Add instruction: when handing back to `feature-build`, pass the specific failed leaf IDs — not just "phase N failed"
- [x] 3.5 Add instruction: `verify-human` node status may only be set to complete when ALL leaf items are `[x]`
- [x] 3.6 Update `## Current Node` on exit with failed leaf IDs in `Active scope`
- [x] 3.7 Added F12-scoped and F12-blocked scenarios

---

### WP4: Update `feature-build` — Scoped Re-Entry + Re-Verify Gate
**Description:** Modify `feature-build` to accept scoped args (specific failed leaf IDs), restrict work to those leaves, attach discoveries to the correct tree node, re-evaluate parent readiness before transitioning, and run a re-verify gate before handing back to `verify-human`.
**Phase:** 1 (scoped re-entry); Phase 2 (re-verify gate — added here because re-verify lives at build exit)
**Dependencies:** WP1, WP3 (for scoped args format); WP6, WP7 (for re-verify gate behavioral checks)
**Size:** L
**Tasks:**
- [x] 4.1 Update `skills/feature-build/SKILL.md`: on entry, read `## Current Node` first; if scoped args present, restrict work to named leaf IDs only
- [x] 4.2 Add instruction: discoveries attach to correct parent phase node as `SURFACED` children (and also to backlog)
- [x] 4.3 Add instruction: parent completion enforcement before exit
- [ ] 4.4 Add re-verify gate (Phase 2 — after WP7): before transitioning back to `verify-self`, re-run Observable Outcome checks for fixed leaves
- [ ] 4.5 Add Playwright MCP tools to `allowed-tools` (for re-verify gate)
- [x] 4.6 Update `## Current Node` on exit
- [x] 4.7 Added F8-scoped scenario

---

### WP5: Update `task-plan` / `task-act` — Lighter Work Tree
**Description:** Apply the lighter Task Work Tree format to `task-plan` and `task-act` — Current Node pointer, discovery attachment, parent completion check. No Observable Outcomes or verification group nodes (tasks don't have the full verify loop).
**Phase:** 1
**Dependencies:** WP1
**Size:** S
**Tasks:**
- [x] 5.1 Update `skills/task-plan/SKILL.md`: emit Task Work Tree format with step nodes, `## Current Node`, `## Discoveries`
- [x] 5.2 Update `skills/task-act/SKILL.md`: on entry, read `## Current Node`; attach discoveries to correct step node; update node statuses and Current Node on exit
- [x] 5.3 Add instruction to `task-act`: parent completion enforcement before exit
- [x] 5.4 Added T2-worktree and T7-worktree scenarios

---

### WP9: Update Test Fixtures (Phase 1)
**Description:** Update all 14 existing WIP test fixtures to the Work Tree format, and add new fixtures for Phase 1 scenarios. This is a blocking dependency for all Phase 1 test scenarios.
**Phase:** 1
**Dependencies:** WP1 (format spec must be final)
**Size:** M
**Tasks:**
- [x] 9.1 Audit `tests/fixtures/wip/` — audited 17 fixtures, identified references
- [x] 9.2 Convert each fixture to Work Tree format (preserved scenario intent)
- [x] 9.3 Added `feature-verify-human-partial-failure.md`, `feature-build-scoped-reentry.md`, `task-plan-worktree.md`, `feature-plan-worktree.md`
- [x] 9.4 7/7 new Work Tree scenarios pass on haiku (--budget 0.10)

---

## Phase 2: Agent Self-Verification Before Human Handoff

### WP6: Behavioral Definition of Done Format
**Description:** Define the "behavioral definition of done" format — observable outcomes per phase node — and establish where it lives in the Work Tree. This is the schema that `feature-verify-auto` reads.
**Phase:** 2
**Dependencies:** WP1 (Work Tree format must exist)
**Size:** XS
**Tasks:**
- [ ] 6.1 Document the Observable Outcomes format in `docs/product/wip-format.md` (or equivalent reference): one entry per observable, prefixed with verification method (`Browser:`, `HTTP:`, `CLI:`, `Console:`)
- [ ] 6.2 Confirm that WP2 (feature-plan) already includes Observable Outcomes at plan time — no additional skill change needed here, just validation
- [ ] 6.3 Document the rule: Observable Outcomes are written at plan time (not verify time) — rationale in arch.md already; ensure it is surfaced in the skill prompt

---

### WP7: Create `feature-verify-self` skill — Live-System Observation via Subagent
**Description:** New skill and state between verify-auto and verify-human. The skill reads Observable Outcomes from the WIP tree, then spawns a one-shot subagent with Playwright/curl tools to observe the running system. Parent parses results, updates the tree, and decides: blocking failure → back to build; all clear → forward to verify-human.
**Phase:** 2
**Dependencies:** WP6 (DoD format), WP8 (severity taxonomy)
**Size:** L
**Tasks:**
- [ ] 7.1 Create `skills/feature-verify-self/SKILL.md` with subagent spawn pattern: bake dev URL (from args), Observable Outcomes, and severity taxonomy into spawn prompt; parse `result` block back from subagent output
- [ ] 7.2 Define subagent allowed-tools: `mcp__playwright__browser_navigate`, `mcp__playwright__browser_snapshot`, `mcp__playwright__browser_console_messages`, `mcp__playwright__browser_take_screenshot`, `mcp__playwright__browser_click`, `mcp__playwright__browser_fill_form`, `mcp__playwright__browser_evaluate`, `Bash`
- [ ] 7.3 Add Playwright unavailability handling: if subagent errors on Playwright tools, fall back to curl for HTTP outcomes; annotate browser outcomes as `UNVERIFIED` — these appear in verify-human checklist
- [ ] 7.4 Add severity classification in subagent prompt: BLOCKING vs COSMETIC per taxonomy (WP8); blocking failures route back to build; cosmetic failures noted but don't block handoff
- [ ] 7.5 Update WIP tree on exit: mark verify-self leaf statuses, update Current Node; pre-filter verify-human checklist (agent-confirmed items excluded)
- [ ] 7.6 Update `docs/product/transitions.md`: add F10 (verify-auto → verify-self), F10b (verify-self → verify-human), F9b (verify-self → build back-loop)
- [ ] 7.7 Update `feature-verify-auto` SKILL.md: F10 now points to verify-self, not verify-human
- [ ] 7.8 Update `feature-verify-human` SKILL.md: note pre-filtering from verify-self results

### WP7b: Update `install.sh` for new skill symlink
**Description:** `install.sh` must pick up the new `feature-verify-self` skill directory and create its symlink.
**Phase:** 2
**Dependencies:** WP7
**Size:** XS
**Tasks:**
- [ ] 7b.1 Run `./install.sh` and confirm `~/.claude/skills/feature-verify-self` symlink is created
- [ ] 7b.2 Confirm skill appears in available skills list in Claude Code

---

### WP8: Severity Taxonomy
**Description:** Define the blocking/cosmetic severity taxonomy for observable failures, and document it in a shared conventions file that `feature-verify-auto` and `feature-build` both reference.
**Phase:** 2
**Dependencies:** None (prerequisite for WP7)
**Size:** XS
**Tasks:**
- [ ] 8.1 Write severity taxonomy to `docs/product/severity-taxonomy.md`: **blocking** = blank page, JS console error, crash, data loss, auth bypass, broken navigation; **cosmetic** = spacing, color, copy, minor layout deviation
- [ ] 8.2 Add a "gray area" section: items that may be blocking or cosmetic depending on context (e.g., missing image — cosmetic if decorative, blocking if it's a required UI affordance)
- [ ] 8.3 Reference the taxonomy in `feature-verify-auto` SKILL.md (link or inline the categories)
- [ ] 8.4 Reference the taxonomy in `feature-build` SKILL.md (for re-verify gate classification)

---

### WP14: Update Test Fixtures (Phase 2)
**Description:** Add new test fixtures and scenarios for Phase 2 behaviors.
**Phase:** 2
**Dependencies:** WP6, WP7, WP8
**Size:** S
**Tasks:**
- [ ] 14.1 Add fixture: `feature-verify-auto-with-dod.md` — WIP file with Observable Outcomes defined; scenario asserts agent runs live checks
- [ ] 14.2 Add scenario: agent self-catches blocking failure (blank page) — transition stays in verify-auto, not escalated to verify-human
- [ ] 14.3 Add scenario: re-verify gate fires after build fix — agent re-runs Observable Outcome checks before returning to verify-human
- [ ] 14.4 Run `tests/run-tests.sh --group feature` — all Phase 2 scenarios pass on haiku

---

## Phase 3: WBS Decomposition by Learning Sequence

### WP10: Update `product-wbs` — Learning-Sequence Ordering
**Description:** Update the `product-wbs` skill to require learning-sequence ordering with written rationale per phase, probe WPs for 3rd-party integrations, and the standard phase pattern.
**Phase:** 3
**Dependencies:** None (independent of Phases 1–2)
**Size:** M
**Tasks:**
- [ ] 10.1 Update `skills/product-wbs/SKILL.md`: add requirement for learning-sequence ordering — assert the standard pattern (Docker → probes → UI mockups → backend → orchestration); require written rationale per phase ("why this before that in terms of risk reduction")
- [ ] 10.2 Add "spike/probe" work package class to the WBS template: define distinct format fields (`Learning objective:`, `Timebox:`, `Success criterion: what do we now know?`); contrast with "build" WPs
- [ ] 10.3 Add instruction: 3rd-party integrations must be classified as blockers on downstream WPs until a probe has completed and its I/O shapes are documented; if no probe WP exists, one must be created
- [ ] 10.4 Add instruction: orchestration layers (queues, workers, async) must appear in a later phase than the synchronous path they will wrap — deviations require written rationale
- [ ] 10.5 Update/add test scenario: WBS for a project with 3rd-party API includes a probe WP before any WP that assumes known API shapes

---

### WP11: Update `feature-spec` / `feature-plan` — Probe Check
**Description:** Add a check to `feature-spec` and `feature-plan`: if the feature depends on a 3rd-party integration with no completed probe WP, flag it as a known unknown and recommend a spike before planning.
**Phase:** 3
**Dependencies:** WP10 (probe WP class must be defined first)
**Size:** S
**Tasks:**
- [ ] 11.1 Update `skills/feature-spec/SKILL.md`: add a pre-planning check — does this feature reference a 3rd-party integration? If yes, is there a completed probe WP in the WBS? If no probe, flag as known unknown and recommend REDIRECT to a spike
- [ ] 11.2 Apply same check to `skills/feature-plan/SKILL.md`
- [ ] 11.3 Add test scenario: feature plan for 3rd-party dependent feature with no probe → output contains the known-unknown flag and spike recommendation

---

## Phase 4: Framework Alignment

### WP12: Framework Alignment — Iterative Re-Identification + Exit Conditions
**Description:** Close Framework Gaps F1, F4, F5: problem re-identification on back-loop re-entry, per-iteration relevance check, and mandatory retrospect + communicate at cycle close.
**Phase:** 4
**Dependencies:** None (independent; but benefits from WP3/WP4 back-loop machinery being in place)
**Size:** M
**Tasks:**
- [ ] 12.1 Add "problem statement re-check" prompt to `feature-build` SKILL.md back-loop entry: before re-planning, agent must answer "has the root problem changed based on what we learned?" and record the answer in the WIP file
- [ ] 12.2 Apply same re-check to `task-act` back-loop entry
- [ ] 12.3 Add relevance gate to `feature-plan` phase-advance logic: before starting each new phase, check the relevance signals checklist (requester still needs it, requirements unchanged, solution still feasible, no superior alternative discovered) — record the check in the WIP file
- [ ] 12.4 Update `task-close` SKILL.md: require both a retrospect artifact ("what changed in our understanding") and a communicate step ("confirmation that the requester knows the work is done and what it does") — these are two separate prompts, not one
- [ ] 12.5 Apply same dual-output requirement to `feature-finalize` SKILL.md
- [ ] 12.6 Update/add test scenarios for back-loop re-entry (problem re-check present), phase advance (relevance check present), task-close (both retrospect and communicate in output)

---

## Phase 5: Hardening

### WP13: Hardening — Tests, Polish, Documentation
**Description:** Full transition test coverage for all new Phase 1–4 behaviors; update CLAUDE.md, skill argument-hints, and user-facing docs to reflect Work Tree format; validate install.sh idempotence.
**Phase:** 5
**Dependencies:** All prior WPs
**Size:** L
**Tasks:**
- [ ] 13.1 Audit all new scenarios added in WPs 2–12 against `tests/scenarios/` — identify any gaps in transition test coverage
- [ ] 13.2 Write missing test scenarios until `tests/run-tests.sh` passes clean on haiku for all groups
- [ ] 13.3 Update `CLAUDE.md` (project): document Work Tree format, new skill behaviors, Observable Outcomes convention, severity taxonomy reference
- [ ] 13.4 Update each modified skill's `argument-hint` field to reflect new args (e.g., `feature-build` now accepts scoped leaf IDs)
- [ ] 13.5 Run `./install.sh` on this machine and verify all symlinks are correct and idempotent — no new files need symlinking for Phases 1–4, but confirm
- [ ] 13.6 Optional: write `USAGE.md` section targeting secondary audience adoption (Work Tree format explanation, what each skill now does, how to read a WIP file)

---

## Summary

| WP | Name | Phase | Size | Depends on |
|----|------|-------|------|------------|
| WP1 | Work Tree Node Format (+ CLAUDE.snippet.md) | 1 | S | — |
| WP2 | feature-plan: Emit Work Tree | 1 | M | WP1 |
| WP3 | feature-verify-human: Leaf-Level Pass/Fail + pre-filter | 1+2 | M | WP1, WP7 |
| WP4 | feature-build: Scoped Re-Entry + Re-Verify Gate | 1+2 | L | WP1, WP3, WP6, WP7 |
| WP5 | task-plan / task-act: Work Tree (peer model) | 1 | S | WP1 |
| WP6 | Behavioral DoD Format | 2 | XS | WP1 |
| WP7 | feature-verify-self: New skill + subagent | 2 | L | WP6, WP8 |
| WP7b | install.sh: symlink for feature-verify-self | 2 | XS | WP7 |
| WP8 | Severity Taxonomy | 2 | XS | — |
| WP9 | Test Fixtures (Phase 1) | 1 | M | WP1 |
| WP10 | product-wbs: Learning-Sequence Ordering | 3 | M | — |
| WP11 | feature-spec/plan: Probe Check | 3 | S | WP10 |
| WP12 | Framework Alignment (F1, F4, F5) | 4 | M | — |
| WP13 | Hardening — Tests, Polish, Docs | 5 | L | All |
| WP14 | Test Fixtures (Phase 2) | 2 | S | WP6, WP7, WP8 |

**Recommended build order (respecting dependencies + learning sequence):**
1. WP1 → WP8 → WP6 (foundational specs, no dependencies; WP1 includes CLAUDE.snippet.md update + install.sh re-run)
2. WP2, WP5 in parallel (depend only on WP1; note task workflow is now peer model — no lighter variant, same tree format)
3. WP7 → WP7b (new verify-self skill + install symlink; depends on WP6 + WP8)
4. WP3 (pre-filter logic depends on WP7 being defined)
5. WP4 (depends on WP1, WP3, WP6, WP7 — the last to close)
6. WP9, WP14 (fixtures — run after skill changes settle)
7. WP10, WP11, WP12 in parallel (all independent of Phases 1–2)
8. WP13 (hardening — last)
