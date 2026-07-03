---
name: project-settings-fixture-claudesk-drift
description: check-structure.sh Phase 7 drift — live settings.json carries host-specific claudesk hooks the test fixture must exclude via INTENTIONAL_DIFFS
metadata: 
  node_type: memory
  type: project
  originSessionId: 926a4944-1299-4688-9e34-f68a5af60489
---

In `my-claude-code-customization`, the live `~/.claude/settings.json` carries host-specific **claudesk** hooks (the user's custom Claude Code wrapper app, `com.claudesk.app[.dev]`, which monitors busy/idle status per instance) on `Notification`/`Stop`/`UserPromptSubmit`. The test fixture `tests/fixtures/settings.json` cannot mirror them (absolute `~/Library` paths, mutate on claudesk's own schedule). As of 2026-06-24, `check-structure.sh` [Phase 7] **filters** claudesk out, rather than excluding whole events: a `strip_host_specific()` pass drops any hook GROUP whose command mentions `claudesk` from BOTH live and fixture before the diff. The harness must not police claudesk, and claudesk must not break the harness — they stay decoupled.

**Why filter, not exclude:** the earlier stopgap parked all three events in `INTENTIONAL_DIFFS`, which silently disabled drift detection on the repo-owned `claude-time` hook too (suite sat at 289/1 latent). Filtering claudesk leaves `claude-time` fully diffed: after stripping, `UserPromptSubmit` matches exactly on both sides and is drift-checked; only `Notification`/`Stop` stay in `INTENTIONAL_DIFFS` (fixture empties them so tests don't fire the notification hook).

**How to apply:** When editing live `settings.json`, expect Phase 7 to flag any delta on the repo-owned `claude-time` hook or other non-claudesk fields. claudesk changes are invisible to Phase 7 by design — don't try to mirror them into the fixture. For a genuinely new test-only override (a hook tests should NOT inherit), add it to both `INTENTIONAL_DIFFS` and the fixture's `_intentional_diffs_from_live`. Related: [[feedback-git-branch-main-default]].
