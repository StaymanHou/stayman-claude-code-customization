## Workflow System

This machine has a state-machine-driven workflow system installed (skills + orchestrator agents). Projects that use it keep transient state in `workflow/` and strategic product docs in `docs/product/`.

**Four workflows with entry-point slash commands:**

- **Product** — `/product-vision` (new initiative) → roadmap → research → arch → wbs → context → [features] → `/product-finalize` (cycle close)
- **Feature** — `/feature-spec` (complex) or `/feature-plan` (small/simple) → build/verify loop → ship → finalize
- **Task** — `/task-plan` → act → close (atomic changes, bug fixes)
- **Incident** — `/incident-report` → triage → investigate → mitigate → resolve

Or `/session-start` to get routed, `/session-pause` and `/session-resume` for cross-session continuity.

**Orchestrator procedures** (`agents/<workflow>-workflow/AGENTS.md`) describe how to drive each workflow end-to-end — happy path, back-loops, and which moments require a human pause. `/session-start` reads the matching orchestrator file and runs the workflow **in the current conversation** (not via a subagent spawn), invoking each skill via the Skill tool and pausing only at real decision points (spec/plan review, verify-human, back-loops, triage severity, etc.).

Running an entry-point slash command directly (e.g., `/product-vision`) stays single-step — no auto-chain. Use `/session-start` when you want end-to-end orchestration.

**Per-project layout** (not shared between projects):
```
docs/product/                        # vision.md, roadmap.md, research.md, arch.md, wbs.md, context.md
docs/product/archive/<cycle-name>/   # cycle-scoped docs archived by /product-finalize on WBS completion
workflow/wip/                        # active feature/task/incident items
workflow/backlog.md                  # SURFACE discoveries
workflow/archive/                    # completed feature/task/incident items
workflow/.session.md                 # single-file pause pointer
```

When a WBS cycle completes, `/product-finalize` resyncs durable docs (`arch.md`, `roadmap.md`), sweeps the backlog, then moves cycle-scoped docs (`wbs.md`, `research.md`, diagnostics) to `docs/product/archive/<cycle-name>/`. Durable docs (`vision.md`, `arch.md`, `transitions.md`, `roadmap.md`) stay in place.

## Work Tree Format (GLOBAL)

Every feature WIP file uses the Work Tree format. All skills that read or write WIP files must understand and maintain this structure.

### Schema

```markdown
## Work Tree
- [ ] Phase 1: <name>  <!-- status: in-progress -->
  **Observable outcomes:**
  - Browser: <declarative outcome>
  - HTTP: <declarative outcome>
  - CLI: <declarative outcome>
  - [ ] P1.1 <impl task>  <!-- status: in-progress -->
  - [ ] P1.2 <impl task>  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
    - [ ] <check item>  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: <name>  <!-- status: NOT-STARTED; depends on Phase 1 -->
  ...

## Current Node
- **Path:** <Feature > Phase > specific node>
- **Active scope:** <node IDs currently in focus>
- **Blocked:** <node IDs blocked and why>
- **Unvisited:** <phases not yet started, listed in the order the workflow will execute them — sequence-of-execution>
- **Open discoveries:** <none | summary>

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
```

### Status vocabulary

| Tag | Meaning |
|-----|---------|
| `NOT-STARTED` | Planned, not yet reached |
| `in-progress` | Agent actively working this node |
| `FAILED` | Failure reported; must resolve before parent advances |
| `BLOCKED: depends on <node>` | Cannot proceed until named node resolves |
| `SURFACED: <summary>` | Discovery attached here; also logged to backlog |
| `[x]` (no tag) | Complete — all children also `[x]` |

### Rules
- **No depth cap** — nest as needed, but prefer splitting wide phases into sibling phases over nesting deeper than Feature > Phase > Verification group > Leaf
- **Parent completion** — a parent's checkbox may only be `[x]` when ALL children are `[x]`
- **Current Node is authoritative** — written on every skill exit, read first on every skill entry; if it diverges from the tree, the tree wins and Current Node is rewritten
- **Observable outcomes at plan time** — written by `feature-plan`, read by `feature-verify-self`; never written post-hoc
- **Tree update on every exit** — every skill that touches a WIP file must update leaf statuses AND Current Node before handing off
- **`Unvisited:` is ordered, sequence-of-execution** — list remaining phases/steps in the order the workflow will actually execute them, not alphabetically or in order-of-thought. When skills read this field later they may treat it as a sequence; an out-of-order list is a confabulation channel (see SURFACE-2026-05-06-FINALIZE-BEFORE-SHIP-ORDER-FLIP)

## CHANGELOG.md convention (GLOBAL)

Every project that uses this workflow system maintains a human-readable `CHANGELOG.md` at the project root (`<proj_root>/CHANGELOG.md`). It is the narrative record of what shipped, closed, or resolved — and it is the canonical destination for the kind of one-line closure notes that used to live in `workflow/backlog.md`'s "Resolved" section.

The four terminal-close skills append to it automatically:

| Skill | Emits on close |
|-------|---------------|
| `feature-finalize` | one `**Feature shipped:**` line + zero-or-more `**Backlog resolved:**` lines + zero-or-one `**Milestone:**` line (if this feature completes a WBS WP) |
| `task-close` | one `**Task closed:**` line + zero-or-more `**Backlog resolved:**` lines |
| `incident-resolve` | one `**Incident resolved:**` line + zero-or-more `**Backlog resolved:**` lines (fires on every resolve path, including fast-close I4/I7) |
| `product-finalize` | one `**Product cycle complete:**` summary line + zero-or-more `**Backlog resolved:**` lines (for items closed during the §4 Backlog Sweep) |

### File shape

```markdown
# Changelog

## 2026-05-12

- **Feature shipped:** <one-sentence summary>
- **Backlog resolved:** <SURFACE-ID> — <one-sentence what closed it>
- **Milestone:** <WP name from wbs.md>

## 2026-05-11

- **Incident resolved:** <one-sentence summary>
- **Task closed:** <one-sentence summary>
```

### Rules

1. **Heading case.** Top-level heading is `# Changelog` (cased, not SHOUT-case).
2. **Date headings as `## YYYY-MM-DD`.** ISO-8601, sortable, no version numbers, no `[v1.2.3]` Keep-a-Changelog-style anchors. Closing skills always use **today's date** (the date the skill runs) — never the WIP file's creation date or any commit date.
3. **Reverse chronological across days; chronological within a day.** Newest day at the top of the file (under `# Changelog`); new same-day entries are appended to the **bottom** of that day's bullet list (so a day's bullets read top-to-bottom in execution order).
4. **Entry-kind vocabulary is fixed.** Each bullet starts with one of: `**Feature shipped:**`, `**Task closed:**`, `**Incident resolved:**`, `**Backlog resolved:**`, `**Milestone:**`, `**Product cycle complete:**`. No other prefixes. Closing skills do not invent new ones.
5. **One sentence per entry.** A reader six months later should understand the entry without opening any archive file. Don't paste archive paths or SURFACE prose — the entry stands alone.
6. **First-write file shape.** If `CHANGELOG.md` doesn't exist at append time, create it as:
   ```
   # Changelog

   ## <today YYYY-MM-DD>

   - <first entry>
   ```
   No preamble paragraph. No "this file is auto-generated" note.
7. **Same-day grouping.** If `## <today>` already exists at the top of the file, append the new bullet(s) to the bottom of that day's bullet list. If it doesn't, insert a new `## <today>` section above the previous newest day, with a blank line separator on either side.
8. **One bullet per resolved backlog item.** A close that resolves multiple SURFACE items emits one `**Backlog resolved:**` bullet per SURFACE ID. Do not aggregate into "Resolved 5 backlog items" — each SURFACE ID should be grep-able.

### Append discipline (write-side rules for closing skills)

- **Append before `git mv`.** When the closing skill archives the WIP file (`git mv workflow/wip/<f>.md workflow/archive/`), the CHANGELOG append must happen *before* the move, and both files must be staged together in the same commit. Sequence: edit CHANGELOG.md → `git add CHANGELOG.md <wip-file>` → `git mv <wip-file> <archive-path>` → commit. This avoids the failure mode logged as SURFACE-2026-05-10-FINALIZE-RETROSPECT-LOST-IN-GIT-MV (rename commits dropping unstaged content edits).
- **Idempotency by archival.** Re-running a closing skill on a WIP path that is already inside `workflow/archive/` is a no-op for the append step. The skill detects this and skips. Re-running on an active WIP that has not yet been archived appends normally.
- **Deterministic line composition.** The skill composes the entry line from data already in the WIP file (title, completion type) plus today's date. The model does not invent wording — it follows the entry-kind vocabulary and writes one sentence drawn from the WIP's problem statement or closure message.
- **Project root detection.** "Project root" = `git rev-parse --show-toplevel` if the working dir is in a git repo; otherwise the current working directory.
- **No backdating.** The skill always writes today's date, regardless of when the WIP was created or when work actually finished.

## Pre-risky-action checklist (GLOBAL)

**Before running any destructive-capable CLI** — scaffolders (`create-*`, `npm create *`), initializers (`*-init`, `yo *`), codegen tools that write to the working directory, or anything with an `--overwrite` / `--force` flag — run through this checklist:

1. **Git safety net.** If the directory is **not** a git repo, initialize one and commit the current state **before** running the tool: `git init && git add -A && git commit -m "pre-scaffold baseline"`. If it **is** a repo, confirm the working tree is clean (no uncommitted changes that could be destroyed) or `git stash` first.
2. **Read the flags.** If the tool has an `--overwrite`, `--force`, or similar flag and you haven't used it before, run `<tool> --help` first. Flag names lie — `--overwrite=ignore` in some tools means "silently replace existing files," not "skip them." One extra tool call is cheap.
3. **Treat all template/scaffold generators as destructive** until proven otherwise. Non-empty target directories are the danger zone.

Rationale: this rule exists because of a real incident where a scaffolder wiped strategic docs without warning. Only the conversation transcript saved the work. Don't rely on transcript survival.
