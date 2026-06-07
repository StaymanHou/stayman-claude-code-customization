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

## Entry-skill product-context loading (GLOBAL)

Entry-point skills may consult `docs/product/*.md` at start to ground planning in strategic context. Each entry-point SKILL.md spells its own load points out concretely in a `## Step 0: Available product context` section — the snippet documents the *rules*, the SKILL.md documents the *concrete paths*.

### Per-skill mapping

| Skill | Load mode | Eager reads | Pointer-only mentions |
|-------|-----------|-------------|-----------------------|
| `task-plan` | conditional-read | `arch.md` *only if* the task touches a public API, data shape, cross-module boundary, or workflow state machine | `wbs.md`, `vision.md`, `roadmap.md` |
| `feature-spec` | eager-read | `arch.md`, `wbs.md` | `vision.md`, `roadmap.md`, `research.md` |
| `feature-plan` | eager-read with context-skip | `wbs.md` — **skipped if already in conversation context** (e.g., loaded earlier by `feature-spec`) | `arch.md`, `vision.md`, `roadmap.md`, `research.md` |
| `feature-reproduce` | pointer-only | (none) | All `docs/product/*.md` |
| `incident-report` | conditional-read | `arch.md` *only if* the incident involves cross-component or system-architecture-level effects | `wbs.md`, `vision.md`, `roadmap.md` |
| `product-vision` | excluded | (none — it writes `vision.md`) | (none) |

### Rules

1. **Pointer-default.** Step 0 always lists which `docs/product/*.md` files exist (one-line each). Absent files are silent no-ops — no warnings.
2. **Size guard: 300 lines.** Eager/conditional reads exceeding ~300 lines read first 100 lines + `^#+ ` headings only, and append `[SURFACED-<date>] <skill> — <doc>.md exceeds size guard (N lines)` to the WIP `## Discoveries`.
3. **No `context.md`.** Excluded everywhere — `CLAUDE.md` is the harness-loaded equivalent.

`tests/check-structure.sh` enforces that each entry-point SKILL.md has its `## Step 0` section.

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

## Long-running commands (GLOBAL)

**Before running a long command** — full test suite (`pytest`, `npm test` / `npx jest`, `cargo test`, `go test ./...`, `bundle exec rspec`, `mix test`, Playwright, etc.), full build (`npm run build`, `cargo build --release`, webpack/Vite production build), big migration, large codemod, or bulk data import — read the project's runtime registry (or estimate if absent) and pass an explicit `timeout` to the Bash tool. The default 2-min Bash timeout silently auto-backgrounds, producing a stale tool result that looks like a failure and tempts re-invocation in the foreground. The wrap-around is what causes the damage; the timeout decision is the prevention.

The rule has three parts:

- **Rule 1 — Consult the runtime registry; estimate only if absent; set `timeout` explicitly.** First, read `<proj-root>/runtimes.md` (see `### Runtime registry` below) for the tracked command's `**Use timeout:**` value and apply it directly. Only when the command is absent from the registry, estimate from scratch: for test suites, query the test count (`pytest --collect-only -q | tail -3`, `npx jest --listTests | wc -l`, `cargo test -- --list 2>/dev/null | tail -1`, `go test -list '.*' ./...`, `bundle exec rspec --dry-run`, etc.); for full builds, big migrations, and bulk operations, read the project `CLAUDE.md` for any prior-runtime notes. Apply `timeout ≥ expected * 1.5 + buffer` (Bash tool accepts ms, max 600000 = 10 min). After the command completes (or is killed), update the registry per the read+update discipline so future sessions inherit the measurement.
- **Rule 2 — Never start a second instance of a long-running command against a shared exclusive resource.** "Exclusive resource" includes: shared dev/test DB (`*_test` database, single SQLite file, shared schema), shared cache or artifact directory (`node_modules/.cache`, `target/`, `dist/`, `.next/`, Bazel/Turbo cache), port-bound process (dev server, test runner with fixed port), lock file (Cargo, Bundler, `package-lock.json` write, git index), single-writer file/object (S3 prefix upload, fixture-generating script). On auto-background, **wait for the `BashOutput` completion notification** (or `<task-notification>` with `<status>completed</status>`) — do not re-invoke. Two concurrent runs against the same backing store race on setup/teardown, cache invalidation, lock acquisition, or fixture lifecycle. The first run usually finishes fine; the second is the destructive case.
- **Rule 3 — When uncertain about runtime, run a small subset first.** A subset verifies health and gives a per-unit time estimate that feeds back into Rule 1's `timeout` calculation. Pick a subset appropriate to the runner: `pytest tests/<module>/`, `npx jest <path>`, `cargo test <module>::`, `go test ./pkg/...`, `bundle exec rspec spec/<area>/`. If the subset reveals an environmental problem (missing service, broken fixture, dependency drift), it surfaces in seconds rather than ten minutes into a foregrounded full run.

Rationale: this rule exists because of a real near-miss where two `docker compose exec app pytest` runs nearly raced on `Base.metadata.create_all` / `drop_all` against a shared `*_test` database — the second invocation was user-backgrounded before reaching conftest setup. The pattern is ecosystem-independent: two `cargo test` runs contending on the `target/` lock, two `npm test` runs hitting a fixed port, or two migration tools attempting to lock the same schema-version row would each fail the same way. The exclusive-resource damage is silent and surfaces as flakiness or destruction, not as a Bash error.

### Runtime registry

Each project that uses this workflow system maintains a per-project runtime registry at `<proj-root>/runtimes.md` — a human-readable markdown file that records the last-observed wall-clock runtime of each tracked long-running command, the timeout value to pass to the Bash tool next time, and an audit-trail history of past observations. This is the file Rule 1 reads on every invocation of a tracked command, and writes after each completion (or kill). The intent is that the second session never re-estimates from scratch what the first session already measured.

**Canonical shape:**

```markdown
---
shape: runtime-registry
updated: 2026-06-07
---

# Runtime Registry

## ./tests/check-structure.sh
- **Last:** 360s (2026-06-07)
- **Use timeout:** 600000
- **History:**
  - 360s — 2026-06-07
```

**Read+update discipline:**

- **Before invoking** a tracked command, `grep -A2 "^## <literal-command>" runtimes.md` and read the `**Use timeout:**` value (in milliseconds). Pass that value as the Bash tool's `timeout` parameter. If the command is absent from the registry, fall back to Rule 1's estimation path and append a new entry after completion.
- **After completion** (or after killing a stuck run — both count as observations), update the same entry: set `**Last:**` to the new wall-clock time + today's date, recompute `**Use timeout:**` via `ceil(observed_seconds * 1.5 + 60) * 1000` (clamped to 600000 ms, the Bash tool's max), prepend a new bullet to `**History:**` with `<Ns> — <YYYY-MM-DD>`, and touch the frontmatter's `updated:` line. Old history bullets remain — the file grows by one line per observation.
- **Tracked vs. untracked:** the registry is for commands that meaningfully exceed the 2-min Bash default and benefit from a recorded measurement (full test suites, full builds, big migrations, large codemods, bulk imports). Single-file edits, fast greps, one-off `ls` / `git status` calls, and similar sub-second commands are not tracked — the registry is not an activity log.
- **Per-project, not global.** `~/.claude/runtimes.md` would conflate measurements across hardware, CI/laptop, and project topology. Keep registries per-project so each set of measurements reflects the project's actual environment.

## Pre-risky-action checklist (GLOBAL)

**Before running any destructive-capable CLI** — scaffolders (`create-*`, `npm create *`), initializers (`*-init`, `yo *`), codegen tools that write to the working directory, or anything with an `--overwrite` / `--force` flag — run through this checklist:

1. **Git safety net.** If the directory is **not** a git repo, initialize one and commit the current state **before** running the tool: `git init && git add -A && git commit -m "pre-scaffold baseline"`. If it **is** a repo, confirm the working tree is clean (no uncommitted changes that could be destroyed) or `git stash` first.
2. **Read the flags.** If the tool has an `--overwrite`, `--force`, or similar flag and you haven't used it before, run `<tool> --help` first. Flag names lie — `--overwrite=ignore` in some tools means "silently replace existing files," not "skip them." One extra tool call is cheap.
3. **Treat all template/scaffold generators as destructive** until proven otherwise. Non-empty target directories are the danger zone.

Rationale: this rule exists because of a real incident where a scaffolder wiped strategic docs without warning. Only the conversation transcript saved the work. Don't rely on transcript survival.
