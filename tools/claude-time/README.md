# claude-time

Opt-in, hook-driven time-tracking for Claude Code. Logs timing-relevant events
to `~/.claude-time/events.sqlite` so you can answer "where did the last week of
session time actually go?"

**Status: under construction.** Phase 1 (DB bootstrap + Stop event only) is the
current state. Phases 2–4 will wire the remaining 9 hook events, ship the
`claude-time` reclassifier CLI, and add multi-instance verification.

## Installation

1. Run `./install.sh` from the repo root. This creates a symlink at
   `~/.claude/hooks/claude-time-hook.pl` pointing at `tools/claude-time/hook.pl`.

2. Add the following block to `~/.claude/settings.json` under the existing
   `hooks` key (merge with whatever's already there):

   ```json
   {
     "hooks": {
       "UserPromptSubmit":   [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
       "PreToolUse":         [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
       "PostToolUse":        [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
       "PostToolUseFailure": [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
       "Stop":               [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
       "Notification":       [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
       "SessionStart":       [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
       "SessionEnd":         [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
       "SubagentStart":      [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
       "SubagentStop":       [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}]
     }
   }
   ```

   (Currently only `Stop` is wired; the others are no-ops until Phase 2 ships. You
   can still add them now — they'll start logging once the script handles them.)

3. Set `CLAUDE_TIME_TRACKING=1` in `~/.claude/settings.json`'s `env` block:

   ```json
   { "env": { "CLAUDE_TIME_TRACKING": "1" } }
   ```

   Both steps are required. Setting only the env var (without the hooks wiring)
   does nothing; wiring the hooks without the env var leaves the script in
   fast-fail mode — also a no-op.

## Disabling

Either remove `CLAUDE_TIME_TRACKING` from `settings.json`, or remove the hook
wirings. The script does nothing when the env var is unset.

## Privacy

The script never writes prompt text, tool input, or tool output to the DB. It
records timestamps, event names, session ID, working directory, tool name,
agent type, and a `meta` JSON blob with structured fields like
`prompt_length_chars` (integer length only). See `hook.pl` for the source of truth.
