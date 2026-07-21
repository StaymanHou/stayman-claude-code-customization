# Task: Prefix Telegram env vars with CLAUDE_

**Workflow:** task
**State:** Completed
**Created:** 2026-05-04
**Completed:** 2026-05-04

## Problem Statement
`TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` can collide with project-level env vars that serve a different Telegram integration, causing the notify-human skill to send to the wrong chat.

## Context
- `skills/notify-human/SKILL.md` — curl command references both vars
- `~/.claude/settings.json` — env section holds the actual values under the old names
- `CLAUDE.md` (project) — documents the env var names
- `CLAUDE.snippet.md` — injected into global CLAUDE.md, also documents names
- `README.md` — setup instructions reference the names
- `install.sh` — post-install echo references the names

## Work Tree

- [x] T1 Update `skills/notify-human/SKILL.md` — rename vars in curl command
- [x] T2 Update `~/.claude/settings.json` — rename env keys (keep values identical)
- [x] T3 Update `CLAUDE.md` — rename vars in documentation
- [x] T4 Update `CLAUDE.snippet.md` — rename vars in documentation
- [x] T5 Update `README.md` — rename vars in setup instructions
- [x] T6 Update `install.sh` — rename vars in post-install message
- [x] T7 Update `~/.claude/CLAUDE.md` (live injected copy) — rename vars

## Current Node
- **Path:** Task > all complete
- **Active scope:** all complete
- **Blocked:** none
- **Open discoveries:** none

## Discoveries

## Retrospect
- **What changed in our understanding:** Discovered that `~/.claude/CLAUDE.md` (the live injected copy) also needed updating in addition to the 6 planned files — it was not in the original scope but caught during implementation via a grep check.
- **Assumptions that held:** All references were in exactly the places identified during planning. No unexpected files held references (conversation logs excluded).
- **Assumptions that were wrong:** The plan listed 6 files; there were actually 7 (the live injected copy of the snippet in `~/.claude/CLAUDE.md`).
- **Approach delta:** Added T7 on the fly — minor scope expansion but still within task boundaries.
