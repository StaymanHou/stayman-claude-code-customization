---
stage: roadmap
state: complete
updated: 2026-11-16
---

# Roadmap — Claude Code Workflow System

## Status: complete and frozen (2026-11-16)

All 12 milestones across three product cycles have shipped. No cycle is active and none is
planned. The operator is using the system as it stands rather than extending it.

- **Open work is parked, not dropped.** It lives in `workflow-system/state/backlog.md`. Nothing there
  blocks day-to-day use.
- **To reopen:** run `/product-vision`, then `/product-roadmap`. New milestones continue the numbering
  below (Milestone 13 onward) under a new `## Group` heading.
- **Detail lives elsewhere.** `CHANGELOG.md` is the narrative record of what shipped. Each cycle's WBS
  is archived under `workflow-system/product/archive/<cycle>/`.

## Group — v1 cycle: core loop integrity (closed 2026-05-01)

Source: the three pain points in `archive/workflow-system-v1/workflow-pain-points.md`. WBS archived at
`archive/workflow-system-v1/wbs.md`.

### Milestone 1: Problem tree and structured verification ✅
The WIP file became a Work Tree with a status on every node. A verify-human rejection sends the
specific failed leaf IDs back to build, and a parent node cannot complete until all of its children do.

### Milestone 2: Agent self-verification before human handoff ✅
`feature-verify-self` observes the running system against Observable Outcomes written at plan time,
and sorts failures into BLOCKING (back to build) and COSMETIC (noted). The operator no longer
receives anything the agent could have checked itself.

### Milestone 3: WBS ordered by learning sequence ✅
`product-wbs` orders work by risk and learning, not by build dependency. It has a spike/probe work
package class, and a 3rd-party integration blocks downstream work until it has been probed.
`feature-spec` and `feature-plan` flag an integration that has no probe.

### Milestone 4: Framework alignment ✅
Every back-loop re-checks the problem statement, every phase advance passes a relevance gate, and
every close writes a retrospect and a communicate step as separate outputs.

### Milestone 5: Hardening ✅
Milestones 1–4 got scenario coverage, the project docs and argument-hints were brought up to date,
and `install.sh` was made idempotent.

## Group — v2 cycle: orchestration loop integrity (closed 2026-05-02)

Source: `archive/workflow-system-v2/workflow-pain-points-2.md`. WBS archived at
`archive/workflow-system-v2/wbs.md`.

### Milestone 6: Orchestration auto-advance and test triage ✅
An AUTO/PAUSE policy table lets clean steps chain without the operator. `feature-verify-codify`
must write a six-case triage record before it acts on any test failure.

## Group — Claudesk handoff cycle (2026-07-20 → 2026-07-28)

Source: five items Claudesk handed over on 2026-07-20, to make the system usable by someone new to
the workflow. WBS archived at `archive/claudesk-handoff-cycle/wbs.md`.

### Milestone 7: One workflow-doc layout ✅
Strategic and operational state now both live under `workflow-system/` (`product/` and `state/`). A
migration tool moved nine consuming projects to the new layout.

### Milestone 8: Standalone uninstall ✅
`uninstall.sh` reverses everything `install.sh` sets up, needs no Claudesk to run, and an
install → uninstall → re-install round trip leaves no residue.

### Milestone 9: Turn-level vs. session-boundary vocabulary ✅
A bare "pause", "stop" or "hold" is a turn-level interrupt. The session handoff has to be named
explicitly (`/session-handoff` ↔ `/session-restore`).

### Milestone 10: Research cost tiers ✅
`quick-research` is the cheap default for web lookups. The heavyweight `deep-research` needs the
operator's confirmation before it runs.

### Milestone 11: New-user onboarding ✅
The `tutorial-*` skills give a first-run tour on two paths: greenfield, which uses a tiny sample
project, and brownfield, which uses the user's own code. The operator accepted it in a hands-on run.

### Milestone 12: Return contract to Claudesk ✅
Claudesk received the install copy, the doc layout and the onboarding spec, in a form it can build
against.

## After the last cycle

Later work shipped as standalone features and tasks rather than milestones. `CHANGELOG.md` has the
detail. In brief:

- **2026-07:** `/util-grill-me`, a gated interview that hardens a plan before it is built.
- **2026-09:** the Opus-5 edge-pause investigation. It ran from a temporary WBS
  (`archive/opus5-edge-pause/`) and shipped the m-prose mitigation. Its replay harness was recorded
  as a negative result: as built, it cannot measure that bug.
- **2026-09:** the cross-workspace inbox (`workflow-system/inbox/`).
- **2026-11:** verify-human became an alignment-only gate. Claudesk's live drive mode now decides
  the mode at session start and restore. Codify runs only nearby tests on the non-final phases of a
  long suite.
