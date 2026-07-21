---
stage: research
state: complete
updated: 2026-07-20
---

# Research

**Milestone Focus:** Milestone 7 (Unify the workflow-doc layout for new users) — the foundational milestone of the Claudesk Handoff Cycle. Also light scoping of M8 (uninstall) and M10 (research-skill collision) since they surfaced concrete facts during this pass.

---

## Milestone 7 — Doc-layout unification

### The decision framing (not a stack choice)
M7 is a **structural / doc-convention decision grounded in this repo's own path usage plus a hard cross-repo constraint**, not a library selection. The two candidate layout options:

- **Option A — Physical move / co-locate:** collapse `docs/product/*` (strategic) + `workflow/*` (operational) under a single new top-level root (e.g. `workflow-docs/` or similar).
- **Option B — Keep split, add a single indexed entry point:** leave the physical dirs where they are; add one top-level index/README (a "start here" map) that unifies the *mental model* without moving files.

### Grounded blast-radius measurement (this repo, today)
Measured via `grep -rl` over `skills/ agents/ tests/ CLAUDE.md CLAUDE.snippet.md`:

| Path family | Distinct files referencing it |
|---|---|
| `docs/product/` | 31 (21 skills, 5 agents, 5 tests) |
| `workflow/backlog` | 36 |
| `workflow/wip` | 34 |
| `workflow/.session` | 9 |
| `workflow/archive` | 8 |
| **EITHER family (union — the move blast radius)** | **59 distinct files** (38 skills, 14 tests, 5 agents, CLAUDE.md, CLAUDE.snippet.md) |

**Implication:** a physical move (Option A) is a **59-file refactor** touching nearly every skill and agent prompt, 14 test files, and both CLAUDE docs — plus the state-machine-lives-in-three-places sync rule (transitions.md / SKILL.md / scenarios). High blast radius, high regression surface. Option B (index-only) has near-zero code-path blast radius.

### Cross-repo constraint (HARD — Claudesk M11 `docs_list`)
Read from `/Users/stayman/Personal/projects/claudesk/docs/product/wbs.md`. Claudesk M11's Docs viewer auto-discovers **exactly** this set, in **workflow order** (not alphabetical):

```
vision → roadmap → wbs (+ glob *wbs*.md scratch) → workflow/wip/*.md → workflow/backlog.md → workflow/.session.md → (arch · research · context)
```

- `docs_list` backend command globs `docs/product/*.md` + `*wbs*.md` + `workflow/wip/*.md` + `workflow/backlog.md` + `workflow/.session.md`. Absent files are silent no-ops. **CHANGELOG.md deliberately excluded.**
- Auto-select-on-open relevance: `.session.md` → else active `workflow/wip/*.md` → else `roadmap.md`.
- **Timing (favorable):** Claudesk M11 is **paused / not yet shipped** (its `workflow/.session.md` shows M11 mid-WBS, unbuilt). So the layout is genuinely still settleable — Claudesk adapts its `docs_list` to whatever this repo decides. The handoff's execution order ("this repo first") is exactly to avoid M11 hardcoding a moving target.
- **Constraint takeaway:** whichever option is chosen, the settled layout MUST be expressible as a discoverable, workflow-ordered file set for M11's `docs_list`. Option B preserves the current paths (M11 needs no change). Option A requires shipping the new paths back to Claudesk so M11's globs follow.

### Recommendation (for arch to ratify)
**Lean Option B (index-only), or a minimal hybrid**, over a full physical move — pending arch confirmation. Rationale: the new-user pain the handoff describes is a *learning/orientation* cost ("two places to learn"), which an authoritative single index resolves directly, at ~zero blast radius and zero cross-repo churn. A 59-file physical move buys marginal additional clarity at large regression risk and forces a Claudesk `docs_list` change. This is a genuine tie-breaker call that belongs in `/product-arch` — flagged, not decided here.

---

## Milestone 8 — Standalone uninstall (scoping)

`install.sh` sets up (read directly), so `uninstall.sh` must reverse each:
1. **Skill symlinks** — `~/.claude/skills/<name>` → repo `skills/<name>` (per-skill `ln -s`).
2. **Agent symlinks** — `~/.claude/agents/<name>` → repo `agents/<name>`.
3. **Hook symlinks** — `~/.claude/hooks/*` for each file in repo `hooks/`.
4. **claude-time tool** — `~/.claude/hooks/claude-time-hook.pl` + CLI symlink into `~/.claude/bin/`.
5. **CLAUDE.md snippet injection** — `CLAUDE.snippet.md` block injected into `~/.claude/CLAUDE.md` (install makes timestamped backups via `cp` before editing).
6. **Per-project memory symlink** — `~/.claude/projects/<slug>/memory` → `<proj>/.claude/memory` (via `tools/memory-link/`).
7. **settings.json permissions** — install *prints* the needed `Read/Edit(~/.claude/**)` permissions (does not auto-write them); any hook *registration* in `~/.claude/settings.json` is the one mutation to reverse carefully.

**Uninstall risks to handle in arch/build:** only remove symlinks this repo created (verify link target points into this repo before `rm`); snippet removal must excise only the injected block (marker-delimited) and ideally restore from the backup; never delete the user's `~/.claude/CLAUDE.md` wholesale; memory symlink removal must not touch the real store the link points at.

---

## Milestone 10 — "research" collision (scoping — reshapes the milestone)

**Key finding: NOT a literal skill-name collision.**
- This repo's skills: `product-research`, `feature-research`.
- CC built-in: **`/deep-research`** (confirmed by web search AND present in this session's own available-skills list).
- The three identifiers are distinct — there is no name clash at the file/slug level.

**The real collision is semantic-routing.** Web search confirms CC skill activation is **semantic description-matching, not keyword matching** — Claude matches a natural request against each skill's `description`/trigger phrasing and makes a judgment call. So when the operator says "research," the risk is Claude semantically selecting `/deep-research` when the workflow's `product-research`/`feature-research` was intended (or vice versa).

**Implication for M10 scope:** the fix is most likely **description/trigger-phrase disambiguation + orchestrator wording** (make the workflow research skills' descriptions unambiguously workflow-scoped, and/or have the orchestrator disambiguate) — **NOT a rename** (a rename wouldn't resolve a semantic-match problem, and would incur the three-places-in-sync cost for little gain). This is a scope *refinement*, not a roadmap invalidation — M10 stays as a milestone; arch/spec should frame it as disambiguation-first, rename only if disambiguation proves insufficient.

---

### Recommended Stack
- **No new runtime dependencies.** All five milestones are prompt/convention/shell-script changes to this repo. M7 = doc-layout convention; M8 = a bash `uninstall.sh` mirroring `install.sh` (no deps); M9/M10 = SKILL.md/AGENTS.md prompt edits; M11 = a design doc (+ possibly a new SKILL.md).

### Trade-offs
- **M7 Option A (physical move)** — cleaner single-location mental model *vs* 59-file blast radius + forces a Claudesk `docs_list` change + three-places-in-sync regression surface.
- **M7 Option B (index-only)** — near-zero blast radius, no cross-repo churn, M11 unaffected *vs* files still physically live in two dirs (mitigated by the authoritative index).
- **M10 disambiguation** — low-cost, addresses the actual semantic-match failure *vs* rename (high sync cost, doesn't fix semantic matching).

### Risks
- **M7 physical move regression:** touching 59 files risks stale-path drift across the three state-machine locations; if chosen, needs the plan-time downstream-contract-impacts grep discipline and a full `check-structure.sh` sweep.
- **Cross-repo drift:** if M7 changes paths, Claudesk M11's `docs_list` must be told; the return contract (M12) is the mechanism, but a missed sync silently breaks M11's discovery.
- **M10 over-fix:** renaming when disambiguation would suffice adds churn without fixing the semantic-match root cause.
- **M11 (onboarding):** brainstorm-first, depends on M7/M8 settling first — not researchable further until those land; correctly sequenced last.

### References
- Claude Code built-in deep-research: https://code.claude.com/docs/en/skills , https://www.mindstudio.ai/blog/what-is-deep-research-command-claude-code
- Skill triggering is semantic description-matching (name-collision + activation semantics): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview , https://code.claude.com/docs/en/skills , https://scottspence.com/posts/claude-code-skills-dont-auto-activate
- Claudesk M11 discovery contract: `/Users/stayman/Personal/projects/claudesk/docs/product/wbs.md` (read directly, cross-repo)
- This repo's `install.sh` (M8 reverse-engineering source), `grep -rl` blast-radius measurement over `skills/ agents/ tests/` (M7)
