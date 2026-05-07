#!/usr/bin/env bash
# notify-telegram.sh — Claude Code hook that pings Telegram on Notification and Stop events.
#
# Wired in ~/.claude/settings.json under hooks.Notification and hooks.Stop.
# Reuses CLAUDE_TELEGRAM_BOT_TOKEN and CLAUDE_TELEGRAM_CHAT_ID from settings env.
# Receives the event payload as JSON on stdin. The hook event name is provided via
# the hook_event_name field in that payload (Claude Code convention).
#
# Exits 0 unconditionally — never block the harness on a missing token, missing
# command, or failed Telegram delivery. Send failures go to stderr only.

set -u

# Read stdin (event payload). Accept empty payload for manual testing.
payload=""
if [ ! -t 0 ]; then
  payload="$(cat)"
fi

# Silent no-op when not configured. Fresh machines / users without Telegram set up
# should not see hook errors.
if [ -z "${CLAUDE_TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${CLAUDE_TELEGRAM_CHAT_ID:-}" ]; then
  exit 0
fi

# jq is required for safe JSON parsing of the payload. If unavailable, fall back
# to a no-op rather than emit a malformed message.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

extract() {
  local field="$1"
  if [ -z "$payload" ]; then
    printf ''
    return
  fi
  printf '%s' "$payload" | jq -r --arg f "$field" '.[$f] // empty' 2>/dev/null || printf ''
}

event="$(extract hook_event_name)"
cwd_field="$(extract cwd)"
message_field="$(extract message)"
session_id="$(extract session_id)"

# Project name = basename of cwd from payload, falling back to $PWD's basename.
project_dir="${cwd_field:-${PWD:-}}"
if [ -n "$project_dir" ]; then
  project_name="$(basename "$project_dir")"
else
  project_name="(unknown project)"
fi

# Compose a single short line per event type.
case "$event" in
  Notification)
    # Notification event — Claude is blocked, awaiting input or permission.
    if [ -n "$message_field" ]; then
      text="${project_name}
🔔 Blocked: ${message_field}"
    else
      text="${project_name}
🔔 Blocked — awaiting input"
    fi
    ;;
  Stop)
    # Stop event — turn ended.
    if [ -n "$session_id" ]; then
      text="${project_name}
✅ Turn ended (session ${session_id:0:8})"
    else
      text="${project_name}
✅ Turn ended"
    fi
    ;;
  *)
    # Unknown event — still send something useful for debugging hook wiring.
    text="${project_name}
ℹ️ ${event:-event}"
    ;;
esac

# POST to Telegram. Suppress stdout (we don't want hook noise in the transcript)
# and route any errors to stderr without failing the script.
curl -sS --max-time 5 \
  -X POST "https://api.telegram.org/bot${CLAUDE_TELEGRAM_BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${CLAUDE_TELEGRAM_CHAT_ID}" \
  --data-urlencode "text=${text}" \
  >/dev/null 2>&1 || true

exit 0
