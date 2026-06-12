---
name: incident-resolve
description: "Incident workflow: finalize the incident — verify resolution, archive, surface follow-up work"
argument-hint: <incident file name or ID>
---

# Incident Resolve

You are finalizing the incident lifecycle.

## State Machine Context

You are in the **incident** workflow at the **resolve** state.
This is the **terminal state** of the incident workflow.

**How this state is reached:**
- **I18 from codify (default):** Regression coverage in place (Path A reproduce-artifact verified, Path B new test written, or defer-with-SURFACE acknowledged)
- **I9 from mitigate (defer path):** Codify explicitly deferred — `## Codify — Deferred` section in WIP file + SURFACE entry in backlog
- **I4 from triage / I7 from investigate (fast-close):** False alarm or duplicate — no mitigation, no codify

**Valid transitions from here:**
- **I10 → EXIT + reflect:** Always auto-trigger reflect
- **I11 → SURFACE to task:plan:** Root cause needs a proper fix (small) — note-and-continue
- **I12 → SURFACE to feature:spec:** Root cause needs architectural fix (large) — note-and-continue

## Procedure

### 1. Verify Resolution
- Confirm with the user that the issue is fully fixed
- Ensure the incident was in `Monitoring` status with no regressions before closing
- If coming from fast-close (I4 or I7), confirm the reason
- If coming from codify (I18): confirm the `## Codify` section in the WIP file documents which path was taken (Path A artifact, Path B new test, or deferred) and the consuming-surface test if an integration boundary applied
- If coming from defer (I9): confirm the `## Codify — Deferred` section is present with reasoning and that the SURFACE→task:plan entry is in `workflow/backlog.md`

### 2. Data Correction (if needed)
- If the incident corrupted data, propose and execute a correction plan
- Get user confirmation before modifying production data

### 3. Finalize Report
- Clean up the incident report (formatting, timestamps)
- Ensure all sections are complete
- Update Status to `Resolved`

### 4. Archive
- Move the incident report to `workflow/archive/`
- Update any incident index if one exists

### 4b. Append to CHANGELOG (required)

Append closure entries to `<proj_root>/CHANGELOG.md` per the **CHANGELOG.md convention** in `~/.claude/CLAUDE.md` (injected from `CLAUDE.snippet.md`). Read that section for the canonical rules — file shape, heading case, same-day grouping, entry-kind vocabulary, append-before-`git mv` discipline.

This step fires on **every** resolve path — I10 default, I4 false-alarm fast-close, I7 duplicate fast-close, I9 defer-with-SURFACE. The fast-close paths still appended `**Incident resolved:**` because the incident *did* close.

For this skill, the entries to emit under today's `## YYYY-MM-DD` heading are:

1. **One `**Incident resolved:**` bullet** — composed from the incident's title and one-sentence outcome (e.g. for fast-close: "false alarm — root cause was external service hiccup"; for normal resolve: one sentence summarizing the mitigation).
2. **Zero or more `**Backlog resolved:**` bullets** — one per backlog item that prior steps closed. (Incidents rarely resolve backlog items, but if step 5 below escalates to I11/I12, those create *new* SURFACE entries — not resolutions, so they do NOT emit `**Backlog resolved:**`.)

**Operational sequence (mirrors feature-finalize to avoid the SURFACE-2026-05-10-FINALIZE-RETROSPECT-LOST-IN-GIT-MV failure mode):**

§4 above lists the archive move; carry it out as the last on-disk action:

1. Edit `<proj_root>/CHANGELOG.md` per the convention above.
2. `git add CHANGELOG.md <incident-file>` — stage CHANGELOG + the finalized incident report together.
3. `git mv <incident-file> workflow/archive/<incident-file>` — perform the §4 move now.
4. Single commit captures the report's final edits + CHANGELOG append + archive move.
5. **Do NOT `git push`.** The resolve commit lands locally only. Pushing is the operator's call — they may want to review, squash with sibling work, or amend a follow-up learning (via `/session-store-learning`) before publishing. Auto-pushing here forecloses those options. If the operator explicitly requests a push, do it then; otherwise leave HEAD local.

**Idempotency:** if the incident file is already inside `workflow/archive/`, skip the append (re-running resolve on an already-archived incident is a no-op).

### 5. Surface Follow-Up Work
Evaluate whether the root cause needs a proper fix beyond the mitigation:

**Small fix needed (I11):**
Log to `workflow/backlog.md` targeting `task:plan`:
```markdown
## SURFACE-<timestamp>
- **Source:** incident:resolve
- **Target level:** task:plan
- **Type:** bug
- **Summary:** <proper fix needed for incident root cause>
- **Context:** <reference incident report>
- **Priority:** <based on severity>
- **Status:** pending
```

**Architectural fix needed (I12):**
Log to `workflow/backlog.md` targeting `feature:spec` with similar format.

### 6. Trigger Reflect
Incidents always trigger reflection:
- Tell user: "Incident resolved. Run `/session-reflect` to capture learnings from this incident."

**Incident:** {{args}}
