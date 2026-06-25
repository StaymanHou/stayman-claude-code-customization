---
date: 2026-05-12
scope: global
type: Context Rule
session-ref: session-start-suggest-from-backlog feature, verify-auto + verify-self phases
---

# Verify-auto and verify-self playbooks for prose-only SKILL.md changes

## Summary
The verify-auto SKILL prescribes syntax/lint/import-smoke/type-check — all assume executable code. For markdown-only edits to a SKILL.md (or CLAUDE.md, AGENTS.md, transitions.md), none apply. Practical cheap substitutes: frontmatter validity grep, ### section-count comparison (before vs after the edit), and `tests/check-structure.sh` if the project has one. Verify-self for SKILL changes has no dev URL and no browser surface — the "live system" is the SKILL prose itself reading fixture project state. Best done by spawning a subagent that (a) reads the modified SKILL.md, (b) walks through its procedure against a set of fixture project directories (created under `mktemp`), and (c) reports per-outcome PASS/FAIL with BLOCKING/COSMETIC severity. Quote SKILL.md line numbers in the subagent's evidence to ground the verdict.

## Suggested change
Either (a) update `skills/feature-verify-auto/SKILL.md` to add a "Prose-only changes" sub-section listing the substitute checks, OR (b) add a `## Conventions` bullet to CLAUDE.md (in `my-claude-code-customization`):

> **Verify-auto/verify-self playbook for prose-only changes:** When the build phase modifies only SKILL.md, CLAUDE.md, AGENTS.md, or other prose docs, verify-auto's executable-code checks don't apply. Substitutes: frontmatter grep, ### section-count comparison, `tests/check-structure.sh`. For verify-self, spawn a subagent (general-purpose) that reads the modified prose and walks through it against fixture project directories created under `mktemp`. The subagent reports per-outcome PASS/FAIL/severity, citing SKILL.md line numbers as evidence.

## Session-log excerpt
verify-auto for this feature ran `check-structure.sh` (34/34 PASS), frontmatter+section-count grep, and dry-ran 20 session scenarios — all PASSed. Verify-self spawned a general-purpose subagent that read SKILL.md and walked through three fixture project dirs (backlog-only, no-backlog, active-wip-with-backlog), reporting all 4 Observable outcomes PASS with SKILL.md line-number citations (lines 73, 77, 79, 80) for evidence.
