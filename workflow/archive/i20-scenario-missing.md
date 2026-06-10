---
drive_mode: full-autopilot
---

# Task: Add I20 (codify → investigate back-loop) scenario to tests/scenarios/incident.yaml

**Workflow:** task
**State:** act (complete)
**Created:** 2026-06-10

## Problem Statement
The I20 transition (codify → investigate back-loop, fires when codify-time evidence reveals the prior root-cause analysis was wrong) is documented across `transitions.md`, `incident-codify/SKILL.md`, and `agents/incident-workflow/AGENTS.md`, but has no test scenario — sibling transitions I17 / I18 / I18-defer / I19 are all covered, so a future regression on I20 emission would slip through the sweep.

## Context
- Backlog source: `SURFACE-2026-05-10-I20-SCENARIO-MISSING` (P3, `workflow/backlog.md:65-74`)
- Canonical I20 definition: `docs/product/transitions.md:385` — "codify → investigate. Back-loop: codify-time evidence reveals the root-cause analysis was wrong — re-investigate"
- SKILL.md handling: `skills/incident-codify/SKILL.md:18` (transition list), `skills/incident-codify/SKILL.md:88` (Test Triage row), `skills/incident-codify/SKILL.md:147-148` (procedure clause)
- Closest existing scenarios for shape reference: I19 (`tests/scenarios/incident.yaml:408-432`) and I18 (`tests/scenarios/incident.yaml:356-379`)
- Existing fixture to reuse: `tests/fixtures/wip/incident-codify-with-reproduce-artifact.md` (already used by I18 + I19 — `system_prompt_extra` overrides the failure semantics)
- Insertion point: directly after I19 (line 432) and before `F-CHGLOG-2` (line 436) — keeps the codify cluster (I17–I20) contiguous

## Semantic distinction from I19
- I19 = mitigation didn't fix the bug → the codify test fails because the original symptom is still present (root cause was right, fix was wrong)
- I20 = root-cause analysis itself was wrong → the codify test reveals the symptom returns under conditions the investigation didn't predict (e.g., a different code path also produces the NoneType, the failing field is not the one investigate identified)

This matters for fixture prompt design — the `system_prompt_extra` for I20 must describe codify-time evidence that contradicts the *investigation*, not just that the fix didn't work.

## Work Tree

- [x] T1 Insert I20 scenario in `tests/scenarios/incident.yaml` between I19 (ends line 432) and F-CHGLOG-2 comment (begins line 434). Schema mirrors I19: `skill: incident-codify`, `args: "api-500-errors"`, same fixtures, `transition_id: I20`, `contains_any: ["/incident-investigate", "back-loop", "root cause"]`, `not_contains: ["/incident-resolve", "/incident-mitigate"]`, `max_retries: 2`. `system_prompt_extra` describes codify-time evidence revealing the prior root-cause analysis was incomplete — e.g. mitigation passes the existing reproduce test, but codify-time exploration reveals a sibling failure path (different null field, or different request shape) that produces the same NoneType — investigation missed it.
- [x] T2 Verify: `./tests/run-tests.sh --id I20` → strict PASS on haiku in 64s (no SOFT, no FAIL, no retries). No sonnet recon needed.
- [x] T3 Verify: `./tests/check-structure.sh` → 139/139 PASS, FAIL: 0. 16s runtime.

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete — ready for /task-close
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->

## Retrospect
- **What changed in our understanding:** Nothing new. The task was exactly the shape the backlog entry predicted — single-file yaml insert, sibling-fixture reuse, semantic distinction from I19 captured via `system_prompt_extra`.
- **Assumptions that held:** (1) `incident-codify-with-reproduce-artifact.md` fixture is reusable for I20 by overriding semantics in `system_prompt_extra` — the same shape I18 + I19 already use. (2) Insert point between I19 and F-CHGLOG-2 keeps the codify cluster (I17–I20) contiguous. (3) The I20 semantic distinction (root-cause analysis was wrong, not just the fix) is sharp enough that the model can route correctly given the right prompt evidence — strict PASS on haiku confirmed this. (4) `contains_any: ["/incident-investigate", "back-loop", "root cause"]` + `not_contains: ["/incident-resolve", "/incident-mitigate"]` is the right assertion shape — mirrors I19's structure (which also targets a back-loop) with `root cause` substituted for `mitigation`.
- **Assumptions that were wrong:** None. Implementation matched the plan exactly. No SOFT_PASS, no haiku-noise, no recon needed.
- **Approach delta:** None. T1 (write scenario) → T2 (run scenario, PASS strict on haiku in 64s, $0.17) → T3 (check-structure 139/139 PASS, 16s). Three steps, three checkpoints, no deviation.

