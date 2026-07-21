# Feature: Telegram Notify Hook (replace notify-human skill)

**Workflow:** feature
**State:** finalize (complete)
**Completed:** 2026-05-06
**Created:** 2026-05-06
**drive_mode:** full-autopilot (switched from autopilot at end of P2.verify-self per user request)

## Problem Statement

The `notify-human` skill relies on the model remembering a global rule to invoke it before any human-input moment. The model drifts — notifications get missed when the user has stepped away from the CLI. Replace the skill with a deterministic Claude Code hook that fires on the harness's `Notification` (input/permission needed) and `Stop` (turn ended) events, sending a simple Telegram message that names the project and includes the notification payload. After the hook is wired and proven, remove the skill and strip every reference to it from CLAUDE.md, agent docs, and other skills.

## Work Tree

- [x] Phase 1: Implement and wire the hook
  **Observable outcomes:**
  - CLI: `bash hooks/notify-telegram.sh` with a synthetic JSON payload on stdin and `hook_event_name=Notification` in the JSON exits 0 and a Telegram message arrives in the configured chat containing the project name and the notification text.
  - CLI: same script with `hook_event_name=Stop` exits 0 and a Telegram message arrives mentioning the project and indicating turn-end.
  - CLI: `./install.sh` run from a clean state creates `~/.claude/hooks/notify-telegram.sh` as a symlink pointing into this repo; re-running it is idempotent (no errors, no duplicate links).
  - CLI: `~/.claude/settings.json` parses as valid JSON and contains `hooks.Notification` and `hooks.Stop` entries that invoke the symlinked script.
  - CLI: with `CLAUDE_TELEGRAM_BOT_TOKEN` unset, the script exits 0 silently (does not break the harness) and emits no curl errors to stderr.
  - [x] P1.1 Create `hooks/notify-telegram.sh` — reads stdin JSON, derives project name from `cwd` field (fallback to `$PWD`), composes a single-line Telegram message including project name and event-type-specific payload (notification text for Notification events; "turn ended" or session id for Stop events), POSTs to Telegram via curl, exits 0 even on send failure or missing env vars.
  - [x] P1.2 Update `install.sh` to symlink `hooks/<file>` into `~/.claude/hooks/<file>` using the same idempotent pattern as skills and agents. Mirror the existing `[ok]/[update]/[new]/[skip]` log lines.
  - [x] P1.3 Add `hooks.Notification` and `hooks.Stop` entries to `~/.claude/settings.json` invoking `~/.claude/hooks/notify-telegram.sh`. Use timeout 10 seconds. Preserve existing settings.
  - [x] P1.4 Run `./install.sh` to materialize the symlink. Manually trigger the hook with synthetic payloads to verify both event types deliver to Telegram. Three test invocations all exited 0; idempotent re-run confirmed `[ok] hooks/notify-telegram.sh (already linked)`.
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [x] verify-codify

- [x] Phase 2: Remove the notify-human skill and references
  **Observable outcomes:**
  - CLI: `ls skills/notify-human` exits non-zero (directory does not exist).
  - CLI: `ls ~/.claude/skills/notify-human` exits non-zero AFTER `./install.sh` is re-run (stale symlink should be cleaned by install or by hand — install.sh currently only adds, so clean this up explicitly).
  - CLI: `grep -rn "notify-human" /Users/stayman/Personal/projects/my-claude-code-customization --include="*.md"` returns only historical references in `workflow/backlog.md` and `workflow/archive/` and `docs/product/transitions.md` change-log/journal entries; no live instructions, agent procedures, or skill steps reference invoking it.
  - CLI: `grep -n "notify-human\|notify_human" CLAUDE.snippet.md CLAUDE.md` returns nothing in active guidance sections (the global Telegram-notify-human guidance section is removed). CLAUDE.md keeps a single historical-mention line under "Telegram notifications".
  - CLI: `grep -n "notify-human" ~/.claude/CLAUDE.md` after `./install.sh` re-run returns nothing — the snippet-managed block no longer carries the rule.
  - [x] P2.1 Delete `skills/notify-human/` directory.
  - [x] P2.2 Strip the "Telegram notify-human (GLOBAL)" section from `CLAUDE.snippet.md` so the global `~/.claude/CLAUDE.md` no longer mandates the skill on next install. Per user feedback during Phase 2, the section was removed entirely (not replaced with a hook-explainer).
  - [x] P2.3 Edit project `CLAUDE.md` — replaced the "### Telegram notify-human" section with a "### Telegram notifications" section describing the hook; kept one historical-mention sentence noting the prior skill was replaced.
  - [x] P2.4 Edited all 4 agent files (`agents/{product,feature,task,incident}-workflow/AGENTS.md`) and 4 skills (`session-start`, `feature-verify-human`, `incident-triage`, `session-store-learning`) — removed every "invoke /notify-human" step, replaced with a parenthetical noting Telegram is handled by the harness hook automatically.
  - [x] P2.5 Updated `README.md` (skills count 32→31, added Hooks row, replaced Cross-cutting bullet, refreshed install.sh description, refreshed Key Design Decisions bullet) and `docs/product/vision.md` (refreshed two notify-human mentions to describe the hook).
  - [x] P2.6 Added a Change Log section to `docs/product/transitions.md` with a 2026-05-06 migration entry. Also refreshed two pre-existing inline references (PAUSE definition + experimental-orchestration pseudocode).
  - [x] P2.7 Removed the stale `~/.claude/skills/notify-human` symlink (`rm -f`); re-ran `./install.sh` — refreshed the CLAUDE.md snippet block.
  - [x] P2.8 Removed the orphaned `Bash(ln -sf ... skills/notify-human ...)` permission entry from `~/.claude/settings.json` allowlist; settings.json validates as JSON.
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human (skipped — Mode 4 Full-autopilot; verify-self acceptance gate stood in)
  - [x] verify-codify

## Current Node
- **Path:** Feature > finalize
- **Active scope:** finalize
- **Blocked:** none
- **Unvisited (in execution order):** finalize
- **Open discoveries:** none

## Ship Record
- **Commit:** `013a30e` on `main`
- **Pushed:** `8aa6e65..013a30e` to `origin/main`
- **Date:** 2026-05-06
- **Test state at ship:** 28/28 structural checks pass

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->

## Retrospect

- **What changed in our understanding:** Confirmed empirically that bot-to-private-chat outgoing messages do not appear in `getUpdates` — initial verify-self interpreted empty `getUpdates` as failed delivery, but a direct verbose curl showed `ok: true, message_id: 91`. Worth remembering: the only reliable way to confirm Telegram delivery from automation is the API response body, not polling.
- **Assumptions that held:** the hook fires deterministically before the model gets control; users see notifications without any model involvement; Phase 1 verifications carried directly to Phase 2 (the doc-corpus changes did not break orchestration coherence).
- **Assumptions that were wrong:** initial Phase 2 plan (P2.2) intended to *replace* the `## Telegram notify-human (GLOBAL)` section in `CLAUDE.snippet.md` with a hook-explainer; user redirected mid-flight to remove it entirely. The "global mandate" framing was outdated — when behavior is a deterministic hook, it doesn't need to be reasserted in the model's prompt at all. Same logic applied to the `(Telegram notifications fire automatically...)` parentheticals across the 4 AGENTS.md files: they leaked transport detail into orchestration procedure that should be transport-agnostic.
- **Approach delta:** Plan was 2 phases, executed as 2 phases. The verify-self subagent path in the existing `feature-verify-self/SKILL.md` is Playwright-/HTTP-shaped and didn't fit a CLI-shaped feature; we ran the live-system observations as direct curl + bash invocations instead of spawning a Playwright subagent. No back-loops were needed — both phases verified clean on first pass. Two mid-feature user redirects shaped the final result: format change at verify-human (project name as first line), and removal of all transport-mention parentheticals across AGENTS.md.

## Communicate

> **Feature complete:** `notify-telegram.sh` Claude Code hook has shipped (commit `013a30e`, pushed to `origin/main`). It replaces the `notify-human` skill — Telegram notifications now fire deterministically on every `Notification` (Claude is blocked) and `Stop` (turn ended) event via `~/.claude/hooks/notify-telegram.sh`, with no model involvement. To verify in action: trigger any `/feature-*` skill that pauses for input; a Telegram message should arrive immediately with the project name on its own line and a one-line status.

Requester = operator — closure notice for self-record.

## Notes

**Integration-boundary rule applies to Phase 2.** Removing notify-human invocations from session-start, feature-verify-human, incident-triage, and session-store-learning modifies code inside existing skills that are consumed by the orchestrator and by direct slash-command invocation. verify-self for Phase 2 must observe that those skills still produce sensible output without the now-deleted skill, and verify-codify must include a structural check that no remaining file references `notify-human` in active guidance.

**Why Stop event is included.** Original ask was Notification only, then expanded to both. Stop event payloads typically contain `session_id` and `cwd`; useful for "Claude finished a long autonomous run while I was away" but noisy for short turns. Worth re-evaluating noise level after a day of real use — log a backlog item if Stop noise dominates and consider matcher-filtering or dropping it.

**No new env vars.** Reuse `CLAUDE_TELEGRAM_BOT_TOKEN` and `CLAUDE_TELEGRAM_CHAT_ID` already present in settings.json. Hook must no-op silently when either is unset (don't break the harness on a fresh machine that hasn't been configured yet).
