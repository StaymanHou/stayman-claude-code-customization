---
name: util-prune-claude-md
description: "Compact the project-root CLAUDE.md by extracting bulky bullets to docs/lessons/<topic>.md or workflow-system/product/arch.md. User-triggered when the Claude Code harness warns at session start that CLAUDE.md exceeds 40k chars."
argument-hint: "<optional mode: 1=Step-by-step | 2=Batch-approve | 3=Autopilot | 4=Dry-run>"
---

# Prune CLAUDE.md

You are an expert documentation editor compacting the project-root `CLAUDE.md` against Claude Code's 40k-char harness performance threshold.

## Category

**`util-*` — standalone user-triggered utility.** This skill is NOT part of any workflow state machine. It does not emit workflow transitions (no F/I/T/P/S tokens). It does not return to a caller (no `RETURN-TO:`). The operator invokes it manually via `/util-prune-claude-md` when the Claude Code harness warns at session start that `CLAUDE.md` exceeds 40k chars. See `workflow-system/product/arch.md` → Revision 2026-06-13 → `util-*` skill category for the convention.

## What it does

`CLAUDE.md` is loaded into every Claude Code conversation's context. Anthropic's docs (and the harness's session-start warning) flag files over 40k chars as a performance + adherence problem — the model's recall and instruction-following both degrade as token count grows.

This skill inventories the bullets/sections in the project-root `CLAUDE.md`, ranks them by char count, and proposes one of three compaction actions per candidate:

- **DEDUP** — bullet content is already covered by `workflow-system/product/arch.md` → replace bullet with a one-line pointer.
- **EXTERNALIZE** — bullet is content-bearing (lesson, incident history, multi-paragraph recipe) → extract to `docs/lessons/<topic>.md` and leave a one-line pointer.
- **DELETE** — bullet is explicitly self-marked HISTORICAL/retired/superseded → remove entirely (no replacement needed).

The operator picks a mode at entry that controls how aggressively the skill applies the proposals.

## Scope guard (hard)

**This skill edits the project-root `CLAUDE.md` ONLY.** It MUST NOT modify the global `~/.claude/CLAUDE.md` — that file is managed under a different lifecycle (sourced from `CLAUDE.snippet.md`, injected by `install.sh`).

Before any edit, confirm the target path is `<git-rev-parse-show-toplevel>/CLAUDE.md`. If invoked outside a git repo, ask the operator to confirm the target path explicitly before proceeding.

## When to use

- The Claude Code harness emitted `⚠ Large CLAUDE.md will impact performance (Xk chars > 40.0k)` at session start.
- The project-root `CLAUDE.md` has visibly grown (multi-paragraph bullets accumulated across recent ship cycles).
- After a sweep of feature ships where `CLAUDE.md` gained convention bullets — even if the warning hasn't fired yet, proactive pruning when bullets are still fresh is cheaper than later.

## When NOT to use

- The warning is firing on the **global** `~/.claude/CLAUDE.md` — out of scope for this skill.
- The project has no `CLAUDE.md` at the root — skill no-ops with a clear message.
- The project's `CLAUDE.md` is intentionally large (e.g., it's the only documentation file and the project doesn't use `docs/`) — operator judgment; this skill assumes the externalization pattern is acceptable.

## Modes

The operator picks a mode at skill entry. Modes mirror the workflow drive modes (1–4) in aggression spectrum:

| Mode | Name | Behavior |
|---|---|---|
| **1** | **Step-by-step** | Present one candidate at a time with the proposed action and rationale. Operator approves / skips / revises per-bullet. Apply on approval. Most control, slowest. |
| **2** | **Batch-approve** | Surface ALL candidates in a single proposal block (one entry per candidate with verdict + rationale). Operator approves the batch (or specifies individual rejects/revises). Apply the approved set. Default-recommended for routine compaction. |
| **3** | **Autopilot** | Apply only "obvious" candidates — DELETE for bullets self-marked HISTORICAL/retired/superseded, DEDUP for bullets where arch.md has an exact-name parallel subsection. Skip ambiguous EXTERNALIZE candidates (those require operator judgment about lesson scope/title/bundling). Report what was applied. Useful when the warning fired mid-session and the operator wants a quick partial pass. |
| **4** | **Dry-run** | Surface all candidates with suggested actions, change NOTHING. Useful for scope-checking before committing — operator can re-invoke in Mode 1/2/3 if they like the proposal. |

**Mode menu at entry:**

```
Mode menu — pick how aggressively to compact:
  1  Step-by-step   one candidate at a time, approve/skip/revise per bullet
  2  Batch-approve  all candidates at once, approve the batch
  3  Autopilot      apply only obvious candidates (HISTORICAL/exact-parallel), report what was done
  4  Dry-run        surface candidates only, change nothing
```

If `{{args}}` contains a digit 1–4, use it directly (no menu prompt). Otherwise present the menu and wait for the operator's choice.

## Procedure

### 1. Measure baseline

- `bytes=$(wc -c < "$(git rev-parse --show-toplevel)/CLAUDE.md")`
- Report: current size, distance from 40k threshold, distance from 35k (5k headroom recommended).
- If already ≤ 35,000: surface this and ask if the operator still wants to proceed (proactive pruning may still be useful, but the harness warning won't fire).

### 2. Inventory bullets

- Read the project-root `CLAUDE.md`.
- Locate the `## Conventions` section (or whatever heading holds the bulky bullets — usually obvious from the file structure).
- For each top-level bullet, compute its char count (the bullet plus any nested sub-bullets up to the next sibling).
- Sort descending by char count.
- The top ~10 are the candidate set; smaller bullets are excluded from triage (compaction value too low).

### 3. Triage each candidate

For each candidate, classify into one of three verdicts:

- **DEDUP** — Check `workflow-system/product/arch.md` for a subsection whose heading semantically matches the bullet's leading bold phrase. If found, verdict is DEDUP — propose replacing the bullet with a one-line pointer (`- **<short name>** — see \`workflow-system/product/arch.md\` → "<section name>".`).
- **EXTERNALIZE** — If the bullet is multi-paragraph, contains empirical anchors (dates, SURFACE-IDs, incident references), or describes a reusable recipe/lesson, propose extracting to `docs/lessons/<topic>.md`. Propose a slug for the new file (snake-case, descriptive of the lesson's gravitational center). The bullet gets replaced with a one-line pointer (`- **<title>** — see \`docs/lessons/<slug>.md\`.`). Precedent shape: existing `docs/lessons/*.md` files use `# <Title>` first-line h1, no YAML frontmatter, 10–50 lines typical.
- **DELETE** — If the bullet is explicitly self-marked HISTORICAL, retired, superseded, deprecated, or describes a feature/pattern that no longer exists in the codebase, propose deletion entirely (no replacement). Verify by grepping the codebase for the bullet's key identifiers before recommending DELETE.
- **KEEP** — If the bullet is already one line, an operational fact (not a lesson), or already a pointer to an external doc, leave it alone. Excluded from the proposal.

For DEDUP and EXTERNALIZE, the proposed pointer line should be ≤ 200 chars to ensure a meaningful net char-count reduction.

### 4. Apply by mode

**Mode 1 (Step-by-step):** Present candidates one at a time. For each:
- Show the bullet's leading prefix (~100 chars), char count, verdict, proposed pointer/replacement, and rationale.
- Wait for operator response: `approve` → apply; `skip` → leave bullet untouched; `revise <revised verdict or pointer>` → apply revised; `quit` → stop processing remaining candidates.

**Mode 2 (Batch-approve):** Present all candidates in a single proposal block:
- Numbered list of all candidates with verdict + proposed action + char delta.
- Show total proposed char reduction.
- Wait for operator response: `approve` → apply all; `approve except <numbers>` → apply all except the excluded; `revise <number> <revised verdict>` for individual revisions (operator can chain multiple revises); `reject` → apply none.

**Mode 3 (Autopilot):** Apply only obvious candidates:
- DELETE candidates: only if the bullet contains the literal string `HISTORICAL`, `retired`, `superseded`, or `deprecated` in its first ~200 chars AND a grep for the bullet's primary identifier (function/feature name) in the codebase returns 0 hits.
- DEDUP candidates: only if `workflow-system/product/arch.md` has a `###` heading whose text matches the bullet's leading bold phrase exactly (no fuzzy match — if the operator's rename created drift, fall through to skip).
- Skip EXTERNALIZE candidates entirely — those require operator judgment on slug/title/bundling.
- After applying, report: number applied, char delta, list of skipped (with reasons), and recommend Mode 1 or 2 for the remainder.

**Mode 4 (Dry-run):** Present the same proposal as Mode 2 but do NOT apply. Add a closing line: "No changes applied. Re-invoke with `/util-prune-claude-md 1` (Step-by-step), `2` (Batch-approve), or `3` (Autopilot) to act on this proposal."

### 5. Apply mechanically

When applying changes:

- Use `Edit` (not `Write`) on `CLAUDE.md` — preserves git blame and avoids whitespace drift on unrelated sections.
- For EXTERNALIZE: `Write` the new `docs/lessons/<slug>.md` first, then `Edit` `CLAUDE.md` to replace the bullet with the pointer.
- For DEDUP: just `Edit` `CLAUDE.md` to replace the bullet with the pointer (arch.md is unchanged).
- For DELETE: `Edit` `CLAUDE.md` to remove the bullet (no replacement).
- Never batch multiple `Edit` calls with conflicting `old_string` overlaps — process one bullet per `Edit` invocation.

### 6. Re-measure and report

After applying:

- `bytes=$(wc -c < "$(git rev-parse --show-toplevel)/CLAUDE.md")`
- Report: new size, char delta from baseline, current distance from 40k threshold and 35k headroom target.
- List files modified (one bullet per file: CLAUDE.md, plus any new lesson files in docs/lessons/).
- Recommend whether the operator should commit + push (typical for a successful compaction), or whether a follow-up invocation would help (e.g., "still over 40k — consider Mode 1 for the EXTERNALIZE candidates that Autopilot skipped").

## Output format

Always end your output with:

```
util-prune-claude-md complete.
  Baseline: <N1> chars
  Current:  <N2> chars
  Delta:    <N1 - N2> chars (<percent>% reduction)
  Threshold: <N2 ≤ 40000 ? "✓ under 40k" : "✗ still over 40k by Xk chars">
  Files modified: <list>
```

No `TRANSITION:` token, no `RETURN-TO:` — this is a standalone utility, not a workflow skill or sidebar.

## Pitfalls

- **The arch.md / lesson destinations must already accept the externalized content.** If `arch.md` is also over its size guard (300 lines), be deliberate about expanding within existing Revision subsections rather than appending new ones. If `docs/lessons/` doesn't exist yet, create it on the first EXTERNALIZE.
- **Don't EXTERNALIZE without an empirical anchor.** A lesson doc needs a date, a SURFACE-ID, or an incident reference to be useful. A bullet that's just opinionated prose without an anchor should KEEP or DELETE, not EXTERNALIZE.
- **Don't DEDUP across mismatched semantic scope.** A CLAUDE.md bullet may overlap with an arch.md subsection in topic but include operational details (file paths, exact commands) that arch.md intentionally omits. If the bullet's load-bearing content is the operational detail, treat as KEEP, not DEDUP.
- **Re-running the skill is cheap.** If the first pass leaves CLAUDE.md still over 40k, just re-invoke. The triage step is idempotent — already-pointered bullets fall into KEEP automatically.
