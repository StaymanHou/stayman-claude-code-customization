---
name: feature-review-quality
description: "Feature workflow: per-feature code-quality review subagent invoked between ship and finalize. Advisory by default; CRITICAL findings auto-invoke refactor (Modes 2-3); MAJOR pause-and-ask (Mode 2) or auto-backlog (Mode 3); MINOR auto-backlog. Mode 4 skips entirely."
argument-hint: <optional feature name> (the skill reads the WIP file and ship commit SHA from git; no required args)
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Edit
  - Agent
---

# Feature Review — Code Quality

You are an expert Code Reviewer running a per-feature code-quality review pass between `feature-ship` and `feature-finalize`. The ship commit creates a green-tests-known-good baseline; this skill dispatches a fresh-context subagent to read the feature's diff against that baseline and emit a tripartite review output (Strengths / Issues / Assessment) with CRITICAL/MAJOR/MINOR severity per finding.

## State Machine Context

You are in the **feature** workflow at the **review-quality** state.

**Entered from:**
- **F38** — `feature-ship` exit (default path in Modes 1, 2, 3, or missing drive_mode)

**Valid transitions from here:**
- **F39 → finalize:** Review clean — no findings, MINOR-only auto-backlogged, or Mode-3 MAJOR auto-backlogged → tell user to run `/feature-finalize`
- **F40 → refactor:** Review surfaced CRITICAL finding → auto-invoke `feature-refactor` (Modes 2-3) → tell user to run `/feature-refactor`
- **F41 → finalize:** Mode-2 MAJOR finding after operator pause-and-ask, operator chose backlog or defer-refactor → tell user to run `/feature-finalize`

**Mode 4 (full-autopilot) does NOT invoke this skill** — `feature-ship` emits F17b directly to `feature-finalize` when `drive_mode: full-autopilot` is set in the WIP frontmatter.

## Orchestrator Pause Policy (cheat-sheet)

When invoked by `/session-start` in orchestrated mode, the orchestrator reads `TRANSITION: <id>` and uses this table to decide whether to chain or pause. Per-skill rows for review-quality's exits:

| Transition | Mode 1 — Step-by-step | Mode 2 — Orchestrated | Mode 3 — Autopilot | Mode 4 — Full-autopilot |
|---|---|---|---|---|
| Skill invocation (entry) | PAUSE | AUTO | AUTO | **SKIP** (entire skill — ship emits F17b direct to finalize) |
| F39 (clean / MINOR / Mode-3 MAJOR auto-backlogged → finalize) | PAUSE | AUTO | AUTO | n/a (skipped) |
| F40 (CRITICAL → auto-invoke refactor) | PAUSE | AUTO | AUTO | n/a (skipped) |
| F41 (Mode-2 MAJOR — pause-and-ask, then forward to finalize) | PAUSE | **PAUSE** | n/a (Mode 3 auto-backlogs via F39) | n/a (skipped) |

**Hard rule for AUTO exits.** When this skill's emitted transition is `AUTO` in the current drive mode, the orchestrator **must immediately invoke the next skill via the `Skill` tool**. It must **NOT** return control to the user. Emitting a clean `TRANSITION: F39` followed by a polite narrative summary ("Review clean; ready to run finalize") in an AUTO mode is the regression mode this block exists to prevent (P1 incident, 2026-05-16): the `TRANSITION` token is the chain signal; the summary text is not a stop signal. If the transition you just emitted is AUTO in the active drive mode, your next action is a `Skill` invocation, not a turn-end. See `agents/feature-workflow/AGENTS.md` → "Pause policy by drive mode" for the canonical table and the precedence rule.

## Severity Taxonomy

Use these definitions consistently. They are also embedded in the reviewer subagent's prompt.

| Severity | Definition | Per-mode action |
|----------|------------|-----------------|
| **CRITICAL** | Security issue, broken abstraction that will rot fast, wrong-shape implementation that breaks downstream invariants, fundamentally incorrect pattern. Grave enough that shipping it leaves the codebase materially worse. | Mode 1: pause-and-ask. **Modes 2-3: auto-invoke `feature-refactor`** before finalize (F40). Mode 4: skill skipped entirely. |
| **MAJOR** | Judgment call worth attention: duplication, missing abstraction opportunity, testability concern, naming that obscures intent, structural smell that costs future readers. | Mode 1: pause-and-ask. **Mode 2: pause-and-ask** (operator decides: refactor now or backlog) → F41. **Mode 3: auto-backlog with prominent chat surface** (preserves "verify-human is the ONLY autopilot pause" invariant) → F39. Mode 4: skill skipped entirely. |
| **MINOR** | Style, naming nits, micro-optimization, low-effort polish that doesn't affect correctness or future-reader cost. | Mode 1: pause-and-ask. **Modes 2-3: auto-backlog**, no prompt, persist in WIP. Mode 4: skill skipped entirely. |

**Decision rule for severity classification:** When in doubt, classify down (MAJOR > CRITICAL when borderline; MINOR > MAJOR when borderline). This is **advisory work on a shipped commit** — false-positive CRITICALs cost an unplanned refactor pass on already-merged code; false-positive MINORs are essentially free. Diverges from `feature-verify-self`'s "when in doubt, classify as BLOCKING" rule because the cost asymmetry is inverted: verify-self protects against shipping bugs; this skill protects against refactor-thrash.

**Escape hatch (any tier).** If the operator disagrees with a finding on read, they may dismiss it by editing the `## Code-Quality Review` section in the WIP file and marking the finding `[DISMISSED]` before `feature-finalize` archives the file. This is the read-time veto pattern — codified in the reviewer prompt so the operator knows the recovery path.

## Procedure

### 1. Read inputs

- **Read the WIP file** in `workflow/wip/`. Identify the feature name (filename), `drive_mode` (frontmatter), `## Problem Statement`, `## Work Tree` (for phase structure and Observable Outcomes context), and any prior `## Code-Quality Review` section (re-runs should not duplicate; if already present, skip — this skill is idempotent on re-invocation).
- **Identify the ship commit SHA.** Run `git log -1 --format=%H` to get the most recent commit (the ship commit, assuming the standard sequence ship → review-quality). Capture it as `SHIP_SHA`.
- **Identify the feature's earliest commit.** Run `git log --reverse --format=%H main..HEAD 2>/dev/null | head -1` to find the first commit of this feature branch; if that returns empty (feature is on `main`), find the earliest commit referencing this feature's WIP file: `git log --format=%H --reverse -- workflow/wip/<feature-name>.md workflow/archive/<feature-name>.md 2>/dev/null | head -1`. Capture as `BASE_SHA`.
- **Generate the diff context for the subagent.** Run `git log --format="%h %s" $BASE_SHA^..$SHIP_SHA 2>/dev/null | head -30` to get the feature's commit history. Run `git diff --stat $BASE_SHA^..$SHIP_SHA 2>/dev/null` to get the file-change summary. The full diff is **not** baked into the subagent prompt — instead, the subagent reads the files directly via Read/Grep tools (the diff is too large to inline and the subagent benefits from seeing surrounding context).

### 2. Spawn the code-quality reviewer subagent

Spawn an `Agent` with the externalized prompt template at `skills/feature-review-quality/reviewer-prompt.md` as the prompt body, plus the dynamic context (ship SHA, base SHA, feature name, commit history, diff stat, WIP file path) appended. The subagent is one-shot — all context must be baked into the spawn prompt.

**Prompt assembly:**

1. Read `skills/feature-review-quality/reviewer-prompt.md` (the template).
2. Append a `## Dynamic Context` section with:
   - **Feature:** `<feature name from WIP filename>`
   - **Ship commit SHA:** `<SHIP_SHA>`
   - **Base commit SHA:** `<BASE_SHA>`
   - **WIP file path:** `workflow/wip/<feature-name>.md`
   - **Commit history (feature):** the output of `git log --format="%h %s" $BASE_SHA^..$SHIP_SHA | head -30`
   - **Diff stat:** the output of `git diff --stat $BASE_SHA^..$SHIP_SHA`
3. Append the explicit instruction: "Output the result block per the format in §3 of the template. Do not modify any files."

Allowed tools for the subagent: `Read`, `Glob`, `Grep`, `Bash` (for `git show`, `git diff`, file inspection only — no file edits). Do NOT grant Edit/Write to the subagent — it is observe-only.

### 3. Parse subagent results

Read the structured result block from the subagent's output. The expected shape (per the reviewer-prompt.md output format):

```
## Code-Quality Review — <feature name>

### Strengths
- <strength 1>
- <strength 2>
...

### Issues
**CRITICAL**
- [<file>:<line> or <abstraction location>] <finding> — <why it matters>
...
**MAJOR**
- [<location>] <finding> — <why it matters>
...
**MINOR**
- [<location>] <finding> — <why it matters>
...

### Assessment
<one paragraph: overall judgment on the implementation>

### If you disagree
<one-line reminder of the escape-hatch: edit this section in the WIP and mark a finding [DISMISSED]>
```

Count findings per severity:
- `n_critical` = number of CRITICAL findings (zero or more)
- `n_major` = number of MAJOR findings
- `n_minor` = number of MINOR findings

### 4. Write `## Code-Quality Review` section to the WIP file

Append the subagent's full result block as a top-level `## Code-Quality Review` section to the WIP file. Position: immediately before `## Retrospect` (if present) or before the final section. Do NOT overwrite an existing `## Code-Quality Review` section — append `### Re-run <YYYY-MM-DD>` if one already exists (idempotency edge case).

### 5. Decide transition by severity + mode

Read `drive_mode` from the WIP frontmatter.

**Case A — `n_critical >= 1`:**
- All modes: print the CRITICAL findings prominently in chat with one line per finding.
- Modes 2-3: emit `TRANSITION: F40`. Tell user to run `/feature-refactor` to address the CRITICAL findings, then re-run finalize after refactor completes.
- Mode 1: print the same and ask the operator: "CRITICAL findings present. Invoke refactor now (recommended), or backlog and continue to finalize?" Wait for response. Emit F40 if "refactor now"; emit F39 if "backlog and continue" (and append MAJOR-style backlog entries for each CRITICAL with explicit `[BACKLOGGED-OVERRIDE]` markers).

**Case B — `n_critical == 0` AND `n_major >= 1`:**
- Mode 1: print the MAJOR findings; ask the operator: "MAJOR findings present. Refactor now, backlog, or dismiss any?" Wait for response. Emit F40 (refactor), F39 (backlog all/dismiss), or F41 (mixed; same forward exit as F39 but distinct ID for orchestrator audit).
- **Mode 2: pause-and-ask.** Print the MAJOR findings; ask the operator: "MAJOR findings present. (a) refactor now → /feature-refactor; (b) backlog all and continue → /feature-finalize; (c) some dismissed, some backlogged → /feature-finalize." Wait for response. Emit F40 if (a); F41 if (b) or (c) (F41 is the Mode-2 MAJOR pause-and-ask completion path).
- **Mode 3: auto-backlog with prominent chat surface.** Append each MAJOR finding to `workflow/backlog.md` as a new `## SURFACE-<date>-QUALITY-<short-slug>` entry (priority: medium). Print the findings in chat (one line each) with the heading: "MAJOR findings auto-backlogged per drive_mode=autopilot. To address now, run `/feature-refactor`; to dismiss, edit the WIP's `## Code-Quality Review` section and mark with `[DISMISSED]`." Emit `TRANSITION: F39`.

**Case C — `n_critical == 0` AND `n_major == 0` AND `n_minor >= 1`:**
- Modes 2-3: auto-backlog each MINOR finding to `workflow/backlog.md` (priority: low). No prompt. Print a one-line summary in chat: "N MINOR findings auto-backlogged. Review section persisted in WIP." Emit `TRANSITION: F39`.
- Mode 1: print and ask whether to backlog or dismiss any.

**Case D — all clean (`n_critical == 0` AND `n_major == 0` AND `n_minor == 0`):**
- All modes: print the Assessment paragraph in chat. Emit `TRANSITION: F39`.

### 6. Update Current Node + Work Tree

- Mark `feature-review-quality` complete in `## Current Node` (the orchestrator state record). Update Path to point to `feature-finalize` (next state) or `feature-refactor` (if F40).
- This skill does NOT participate in the per-phase verify loop. There are no verify-* leaves to mark.

### 7. Emit Transition

End your output with the canonical transition token so the orchestrator can act on it (the orchestrator reads `TRANSITION: <id>`; the bare slash-command prose above is advisory for single-step users only):

- `TRANSITION: F39` — review clean (no findings), MINOR-only auto-backlogged, or Mode-3 MAJOR auto-backlogged → finalize
- `TRANSITION: F40` — CRITICAL found in Modes 2-3 (or Mode-1 with operator choosing "refactor now") → auto-invoke refactor before finalize
- `TRANSITION: F41` — Mode-2 MAJOR after operator pause-and-ask, operator chose backlog or defer-refactor → finalize

**Scope:** {{args}}
