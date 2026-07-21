---
drive_mode: autopilot
---

# Task: Cleanup stale Telegram allowlist entries

**Workflow:** task
**State:** Completed
**Created:** 2026-05-08
**Completed:** 2026-05-08

## Problem Statement
Five stale full-URL Telegram allowlist entries in `~/.claude/settings.json` hardcode the bot token and reference the removed `notify-human` skill — only the POST pattern is still needed by the hook.

## Context
- `~/.claude/settings.json` lines 19–25 — five Telegram allowlist entries
  - Line 19: `Bash(curl -s -X POST https://api.telegram.org/*)` — POST pattern, covers what's still in use (KEEP)
  - Lines 21, 23, 24, 25: four GET entries with hardcoded bot token (`getUpdates`, `getWebhookInfo`) — leftover from `notify-human` skill (DELETE)
- `hooks/notify-telegram.sh` — only Telegram caller now; uses `curl -sS -X POST .../sendMessage`. Note: hooks bypass the permission allowlist, so the POST entry is technically only needed if a future in-conversation script reuses that shape. Keep it as a fallback rather than delete it.
- Backlog item: `SURFACE-2026-05-06-SETTINGS-JSON-ALLOWLIST-CRUFT` (low priority)

## Work Tree

- [x] T1 Delete the four hardcoded-token GET entries from `~/.claude/settings.json` `permissions.allow` (lines 21, 23, 24, 25)
- [x] T2 Verify settings.json is still valid JSON after edit (`jq . ~/.claude/settings.json`)
- [x] T3 Smoke-test the hook by running `notify-telegram.sh` with a synthetic Notification payload; confirm it exits 0 and a Telegram message arrives
- [x] T4 Update backlog entry status to RESOLVED

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
None.

## Retrospect
- **What changed in our understanding:** Confirmed (by reading the hook) that hooks bypass the permission allowlist entirely — the POST pattern entry is technically redundant for the hook's needs. Kept it as a generic fallback for any future in-conversation Telegram POSTs.
- **Assumptions that held:** The four GET entries were unused after the `notify-human` skill was retired; the POST pattern entry could safely stay as a catch-all.
- **Assumptions that were wrong:** None.
- **Approach delta:** None — implementation matched plan exactly (4 deletes, 1 keep, JSON-validate, hook smoke-test, mark backlog resolved).

## Closure notice
Allowlist cleanup is complete. Removed four stale token-hardcoded `Bash(curl ... api.telegram.org ...)` GET entries from `~/.claude/settings.json`; kept the generic POST pattern. Hook smoke-tested post-edit (exit 0, Telegram delivered). Verify by inspecting `~/.claude/settings.json` `permissions.allow` — only one Telegram entry remains. Requester = operator — closure notice for self-record.
