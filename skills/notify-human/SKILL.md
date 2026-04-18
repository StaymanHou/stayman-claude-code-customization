---
name: notify-human
description: GLOBAL — Send a Telegram notification to the user before requesting human input. MUST be invoked before asking any substantive question in ANY context (workflow, coding, research, reviews, etc).
argument-hint: <what you need from the human>
allowed-tools:
  - Bash
---

# Notify Human via Telegram

You are about to request human input. Before doing so, send a Telegram notification so the user knows to check the CLI.

**Compose the message with these three lines:**

1. **Project:** The current project name (derive from the working directory or CLAUDE.md)
2. **Done:** One-liner summary of what has been accomplished since the last human input
3. **Need:** One-liner of what you need from the human right now

**Send the notification:**

```bash
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{
    "chat_id": "'"${TELEGRAM_CHAT_ID}"'",
    "text": "🔔 Claude Code needs you\n\nProject: <project>\nDone: <done summary>\nNeed: <what is needed>",
    "parse_mode": "HTML"
  }'
```

Replace `<project>`, `<done summary>`, and `<what is needed>` with the actual values. Keep each line under 100 characters.

**After sending**, proceed with your question to the user. Do NOT wait for a response from Telegram.

**Do NOT invoke this skill for:**
- Trivial confirmations (e.g., "proceed? y/n" during routine steps)
- Permission prompts (Claude Code handles those natively)

**DO invoke this skill for:**
- ANY substantive question or decision point in ANY context
- Code review requests
- Design/architecture questions
- verify-human checklists
- Triage severity assessment
- Any situation where the user might have walked away from the terminal
- store-learning confirmation
- Escalation decisions
- Asking for clarification on requirements
- Presenting options that need user choice
