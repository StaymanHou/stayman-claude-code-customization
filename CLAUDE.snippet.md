## Environment & Infrastructure (GLOBAL)

- **Docker Hard-Blocker — daemon-down vs. container-down.** This hard-blocker applies *only* when the Docker **daemon** is unreachable. Before assuming a block, check the daemon and the containers separately:
  - **Daemon unreachable** (`docker ps` errors / cannot connect) in a project that requires Docker: STOP and ask the user to start it. Never run project-standard commands (migrations, tests, CLI tools, REPLs) on the host OS as a fallback.
  - **Daemon reachable but the project's containers are down** (`docker ps` exits 0 but the service you need isn't running): do **not** pause and do **not** ask. Start the container(s) yourself (`docker compose up -d`, or `up --build` if images need building), wait until healthy, then resume the task. `docker` / `docker compose` commands run on the host are explicitly allowed (alongside `git` and read-only ops) — starting containers is the correct unblock, not a host-OS fallback. Read the trigger word literally: an **unreachable daemon** justifies a pause; a **stopped container** does not.

- **Git Branch Policy — work on `main` by default; never auto-branch.** For this user's repos, the default branch (`main`/`master`) IS the working branch. Commit directly to it. Do **not** create or switch to a feature/topic branch on your own initiative — not before a commit, not "for safety," not because a change feels large or hard to reverse. This **overrides** any default harness guidance to "branch first when on the default branch." Create or switch branches **only** when the user explicitly asks for one (e.g., "make a branch", "open a PR", "work on a branch for this"). If you believe a branch is genuinely warranted (e.g., a risky multi-step migration), *ask first* and let the user decide — never branch silently. Committing/pushing still follows the normal rule: only when the user asks.

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
| `feature-spec` | eager-read | `arch.md`, `wbs.md`, `design-priors.md` | `vision.md`, `roadmap.md`, `research.md` |
| `feature-plan` | eager-read with context-skip | `wbs.md` — **skipped if already in conversation context** (e.g., loaded earlier by `feature-spec`) | `arch.md`, `vision.md`, `roadmap.md`, `research.md`, `design-priors.md` (already applied by `feature-spec`) |
| `feature-reproduce` | pointer-only | (none) | All `docs/product/*.md` |
| `incident-report` | conditional-read | `arch.md` *only if* the incident involves cross-component or system-architecture-level effects | `wbs.md`, `vision.md`, `roadmap.md` |
| `product-roadmap` | eager-read | `design-priors.md` (consult for milestone-level product-design leans) | `vision.md` |
| `product-wbs` | eager-read | `design-priors.md` (consult for WP-level product-design leans) | `wbs.md`, `roadmap.md`, `vision.md` |
| `product-vision` | excluded for consult; **capture-only** | (none — it writes `vision.md`; it may *propose* identity/anti-persona priors) | (none) |

`design-priors.md` is consulted by the three planning skills that make product-design tradeoffs (`product-roadmap`, `product-wbs`, `feature-spec`) and proposed-to by the capture checkpoints — see "Design priors (GLOBAL)" below for the full capture/consult contract.

### Rules

1. **Pointer-default.** Step 0 always lists which `docs/product/*.md` files exist (one-line each). Absent files are silent no-ops — no warnings.
2. **Size guard: 300 lines.** Eager/conditional reads exceeding ~300 lines read first 100 lines + `^#+ ` headings only, and append `[SURFACED-<date>] <skill> — <doc>.md exceeds size guard (N lines)` to the WIP `## Discoveries`.
3. **No `context.md`.** Excluded everywhere — `CLAUDE.md` is the harness-loaded equivalent.

`tests/check-structure.sh` enforces that each entry-point SKILL.md has its `## Step 0` section.

## Design priors (GLOBAL)

**Design priors** are terse, transferable, *per-project* statements of how the operator resolves recurring **product-design** tradeoffs (focus-vs-breadth, perf-vs-ship, opinionated-defaults-vs-config, an anti-persona, etc.), each paired with its *why*. They live in `docs/product/design-priors.md` (schema in `arch.md` → "File Schema: Design Priors Format"). The operator deliberately leaves product-design gaps and lets CC fill them; ~90% of the time common sense is right. Design priors capture the remaining ~10% — the project-specific lean — so CC fills *those* the operator's way without being re-taught each feature. **They are directional and overridable, never decisive.** This doc is per-project state (lives in the consuming project, not the skill repo).

### Consult contract (planning skills: `product-roadmap`, `product-wbs`, `feature-spec`)

When filling a product-design gap the operator left open, load `design-priors.md` (absent file = silent no-op) and apply these **weighting rules** — they exist to keep the 90% common-sense path untouched and to prevent over-inference:

1. **No prior governs the decision → fill from common sense.** (The 90% path — untouched. Do NOT invent a prior.)
2. **A prior *agrees* with the common-sense default → take it, higher confidence,** with a brief note.
3. **A prior breaks a *genuine tie* between defensible options → lean the prior + disclose.**
4. **A clear common-sense default *contradicts* a strong prior → the 10% case → surface as a proposal; never silently steer** (neither auto-adopt the prior nor auto-ignore it).
5. **A prior only fires on the axis it is actually about** (the **over-infer guard**) — never stretch a prior to a decision it does not govern. *Tone of an error message* is not governed by a prior about *option-count*.

**Disclosure form** when a prior fires (rules 3/4): `[PRIOR: <slug>] leaning <x> — flag if wrong`, emitted into the roadmap/WBS/spec output.

**Overridability:** when strong common-sense evidence says a recorded prior does not apply here, fill from common sense and **disclose the override** — do not blindly obey the prior. (Tunable over time.)

### Capture contract (checkpoints: `product-vision`, `product-roadmap`, `product-arch`, `product-wbs`, `feature-spec`, `feature-verify-human`; backstop: `session-reflect`)

**Capture discriminant** — propose a prior only when BOTH hold:
- the operator **made or corrected a *product-design* tradeoff** (or stated an identity / non-goal / anti-persona), AND
- a **transferable why** is stated or implied (a why that will recur on future decisions of that kind).

**On fire:** CC **proposes** the prior (inferred lean + inferred why) → the operator **reviews, corrects, and enriches the why** (and may reject) → only then is it written. **Propose, never auto-write.** Preserve the *gap* between inferred-why and the operator's corrected-why as distinct fields when they differ (the gap is the learning signal). Before proposing, **read existing priors and dedup/conflict-check**: a duplicate is not re-added; a *contradicting* new prior is surfaced as a conflict, not silently appended.

**Exclusions (NOT design priors):**
- **Technical/architecture tradeoffs** (stack choice, operational mechanics) → these belong in `arch.md`, NOT `design-priors.md`. (Low per-project frequency; avoids over-infer risk. Revisitable.)
- **Bare one-off preferences, label/copy fixes, pure scope additions, dependency-driven sequencing** → FACT/NOTHING; session-reflect / WIP territory, not a prior.

**Reversal probe (optional):** a decision reversal with no stated why may trigger at most one probe ("is there a principle behind this?"); a "no" captures nothing.

**Backstop:** `session-reflect` asks once per session whether any decision revealed a durable design prior, catching the less-likely checkpoints.

`tests/check-structure.sh` (Phase 13) pins the consult block in the planning skills, the capture move in the checkpoint skills, the schema in `arch.md`, and this mapping.

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

## Artifact tracking policy (GLOBAL)

Workflow skills produce many artifacts (learnings, memories, session pointers, WIP files, product docs). Which of these git-tracks vs. ignores — and **where each is written** — must be deterministic, not inferred at runtime. This section is the authoritative answer. Skills **follow** this policy; they do not re-derive it by inspecting `.gitignore` state.

### The rule: track by default

**Track by default. Ignore a path only if it (a) contains secrets/PII, or (b) is machine-local or trivially regenerable.** Everything a future session or another developer would want — learnings, lessons, product docs, changelog, runtime registry, backlog — is tracked. The ignore list is the *exception* list, and every entry on it earns its place by one of the two reasons above.

### Canonical MAP (per-project defaults)

All paths are project-local (`<proj-dir>/`) unless noted. "Default" is overridable per §Override below.

| Artifact | Default | Reason |
|---|---|---|
| `<proj-dir>/docs/lessons/`, `<proj-dir>/docs/product/` (+ `archive/`), `<proj-dir>/docs/case-studies/` | **track** | shared project knowledge |
| `<proj-dir>/CHANGELOG.md`, `<proj-dir>/runtimes.md` | **track** | shared narrative / measurements |
| `<proj-dir>/workflow/backlog*.md`, `workflow/archive/`, `workflow/wip/` | **track** | shared work state & history |
| `<proj-dir>/.claude/memory/`, `<proj-dir>/.claude/memory/MEMORY.md` | **track + PII-audit** | tracked by default; any skill that writes a memory MUST audit the file for secrets/PII after writing — **redact in place** if redaction preserves the memory's usefulness, else **add that specific file to `.gitignore`** (expected rare) |
| `<proj-dir>/.claude/learnings/` | **ignore** (overridable) | global-scope learning *drafts* parked for hand-porting to a source repo; a project that IS the learning-assets repo overrides this to **track** (see §Override) |
| `<proj-dir>/.claude/settings.local.json` | **ignore** | machine-local permission allowlist (usually also covered by `~/.config/git/ignore`) |
| `<proj-dir>/workflow/.session.md` | **ignore** | transient single-file session pointer, deleted on resume |
| `<proj-dir>/tests/results/`, `.playwright-mcp/`, `tmp/`, generated screenshots, `__pycache__/`, `*.pyc`, `.DS_Store` | **ignore** | machine-local / trivially regenerable |

### The `.claude/` default is TRACK — deterministic, not per-session judgment

The single most common ambiguity is **whether a new project's `.claude/` directory is git-tracked**. The answer is fixed, not a per-session call: **`.claude/` is TRACKED by default.** Only a short, named exception set is ignored:

- `<proj-dir>/.claude/settings.local.json` — machine-local permission allowlist
- `<proj-dir>/.claude/learnings/` — global-scope drafts, **unless the project IS a learning-assets/source repo** (then tracked; declared via `## Artifact tracking overrides`)

Everything else under `<proj-dir>/.claude/` — `memory/` (+ `MEMORY.md`), `skills/`, `agents/`, `settings.json` — is **tracked**. This is a direct consequence of the track-by-default rule above; it is spelled out separately only because the `.claude/`-tracking decision was historically made inconsistently across projects (the enforcement gap: only `product-context` reconciled `.gitignore`, so task/feature-only projects drifted). Both `product-context` (§2b) **and** `session-start` (the once-per-session ensure-link check) now reconcile `<proj-dir>/.claude/` to this posture, so every project — product-workflow or not — converges on it. Never ignore `<proj-dir>/.claude/` wholesale.

### Override (per-project exceptions)

A project's root `CLAUDE.md` may declare a `## Artifact tracking overrides` section naming exceptions to the MAP defaults. The most common case: a repo that **is** the global learning-assets / workflow-system source repo tracks `<proj-dir>/.claude/learnings/` (and possibly `<proj-dir>/.claude/memory/`) first-class instead of ignoring them. An override flips the default for the named paths only. (How a project's `.gitignore` is reconciled to the MAP + its overrides is a workflow-system implementation concern — see the `product-context` skill — not part of this policy.)

## Project-memory location — harness symlink (GLOBAL)

Project memories written by `session-store-learning` (and by the harness's own auto-memory mechanism) must be **both** git-tracked (durable, coupled to the code they describe, portable) **and** auto-loaded by the harness at session start. Those two properties used to live in two different directories:

- **Repo store** `<proj-dir>/.claude/memory/` — git-tracked, but the harness does NOT auto-load it.
- **Harness store** `~/.claude/projects/<slug>/memory/` — auto-loaded at session start (this is where `MEMORY.md` is read from), but machine-local, untracked, and keyed on a path-derived slug.

**The convention: one physical store, symlinked.** The repo dir `<proj-dir>/.claude/memory/` is the single real, git-tracked store. The harness path `~/.claude/projects/<slug>/memory` is a **symlink** pointing at it. Result: memories are version-controlled AND auto-loaded from one physical copy, with no drift. Confirmed viable empirically (the harness writer follows the link without clobbering; reads and session-start auto-load both resolve through it).

**Slug rule (the footgun):** `<slug>` is derived from the **physical (symlink-resolved) absolute path** of the project dir — `realpath(proj-dir)` (`pwd -P`) with every `/` and `.` replaced by `-`. NOT the raw `$PWD`. On macOS `/tmp` → `/private/tmp`, so a project at `/tmp/foo` has slug `-private-tmp-foo`. Any code that computes the slug MUST resolve the realpath first.

**Tooling + wiring:** the reusable link/migration primitive lives in the workflow-system source repo at `tools/memory-link/` (`ensure-memory-link.sh`, `migrate-memory.sh`, sourced `lib-slug.sh`). The idempotent "ensure the link exists" check is invoked from two hosts so every project converges regardless of workflow: **`product-context`** (product-path projects, alongside its `.gitignore` reconciliation) and **`session-start`** (the once-per-session non-product path — task/feature-only projects never hit `product-context`). `install.sh` is NOT the vehicle — it links THIS source repo's skills into `~/.claude/`, whereas the memory link is per-consuming-project and created at project onset, not machine setup.

**Destination rule (unchanged, now reinforced):** a project-scope Memory is written to `<proj-dir>/.claude/memory/` — which, being symlinked, IS the harness store. Never write a project memory as a raw path under `~/.claude/projects/...`. Under the symlink the repo path and the harness path resolve to the same files, so the historical `type:`-based location split is moot.

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
