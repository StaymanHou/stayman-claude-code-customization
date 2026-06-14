# Bootstrap-skip is broader than registry — also covers edited Skill SKILL.md content

`SURFACE-2026-06-11-SKILL-HARNESS-REGISTRY-LOADED-ONCE-AT-SESSION-START` originally captured "new skills/agents added mid-session aren't visible until next session." 2026-06-12 (Phase 2 verify-self of `verify-self-and-review-quality-subagent-dispatch`) confirmed the limitation is broader: when a feature edits an existing `skills/<name>/SKILL.md` and then re-invokes that skill mid-session via `/<name>` or the Skill tool, the harness serves the **OLD pre-edit prose**, not the freshly-edited file on disk.

The bootstrap-skip is BOTH new-artifact-invisibility AND edited-artifact-content-staleness.

## Practical impact

Features that edit a Skill being executed in the same session cannot empirically validate the new prose via in-session dispatch — only via:

- `tests/run-tests.sh` (which spawns a fresh `claude --print` subprocess that loads from disk), OR
- re-invocation in a future session.

## Discipline at plan time

When planning a feature that edits an existing skill, schedule the empirical validation either via:

1. A behavioral test scenario in `tests/scenarios/*.yaml` (harness fresh-subprocess), OR
2. Accept the bootstrap-skip-defer pattern (real validation deferred to next session).

Do NOT assume in-session re-invocation validates skill prose edits.
