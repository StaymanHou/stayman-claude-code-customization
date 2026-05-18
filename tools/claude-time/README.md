# claude-time

Opt-in, hook-driven time-tracking for Claude Code.

`claude-time` answers questions like:

- Where did this week's session time actually go? (reading output vs typing prompts vs waiting on tests vs away)
- How much time am I spending in each tool? (`Bash`, `Edit`, `Read`, …)
- When running two Claude Code instances side-by-side, was instance B really "idle" or was I just busy in instance A?

It logs timing-relevant hook events to a local SQLite database (`~/.claude-time/events.sqlite`) and ships a small Python CLI (`claude-time report`) that buckets the data into readable summaries.

The tool is fully opt-in (env var + manual `settings.json` edit), uses only macOS/Linux-bundled interpreters (Perl 5, Python 3, SQLite 3), writes no network traffic, and never records prompt text or tool input/output content.

## Installation

### 1. Run `install.sh`

From the repo root:

```bash
./install.sh
```

This creates two symlinks:
- `~/.claude/hooks/claude-time-hook.pl` → `tools/claude-time/hook.pl`
- `~/.claude/bin/claude-time` → `tools/claude-time/claude-time`

The CLI lives under `~/.claude/bin/` — add that to your `PATH` if you want to invoke `claude-time` without the full path:

```bash
# in ~/.zshrc or ~/.bashrc:
export PATH="$HOME/.claude/bin:$PATH"
```

### 2. Wire the hooks in `~/.claude/settings.json`

Add this block under your existing `hooks` key (merge with whatever's already there):

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

### 3. Enable tracking via env var

Add to `~/.claude/settings.json`'s `env` block:

```json
{
  "env": {
    "CLAUDE_TIME_TRACKING": "1"
  }
}
```

### Two-step opt-in (deliberate)

Both steps 2 and 3 are required. The two-step gate exists so neither half alone does anything:

- Hooks wired but env var unset → hook fast-fails in ~3ms, writes nothing
- Env var set but hooks not wired → hook never invoked

This makes "I want to try it for a week" cleanly reversible: unset the env var to pause without unwiring, or remove the hooks block to disable entirely.

## Usage

```bash
# Today's report (default)
claude-time report

# Last 7 days
claude-time report --weekly

# A specific day
claude-time report --date 2026-05-15

# Filter to one session
claude-time report --session <session_uuid>

# Filter to one working directory
claude-time report --cwd /Users/me/projects/my-thing

# Inspect a non-default DB (e.g. during testing)
claude-time report --db /tmp/test.sqlite
```

Combine filters freely. For example, "last week's time in my work project":

```bash
claude-time report --weekly --cwd /Users/me/work
```

### Example output

```
claude-time report — today (2026-05-18)
sessions: 2   events: 47

── Tool time (Pre→Post wall-clock, summed) ──
  Bash      4m12s
  Edit      48s
  Read      23s
  WebFetch  12s

── Subagent time (Start→Stop wall-clock, summed) ──
  Explore   2m30s
  Plan      1m05s

── Active session time (UserPromptSubmit → Stop windows) ──
  total across 2 session(s):  1h12m

── Reclassified gap buckets (per session) ──
  thresholds: reading ≤ 120s,  thinking ≤ 300s,  away > 300s
  typing debit: 6.0 chars/sec

  session         reading    thinking    away
  abc12345…           8m         3m       0ms
  def67890…           5m       1m20s      0ms

  TOTAL              13m       4m20s     0ms
```

## Tuning

`~/.claude-time/config.json` (created by hand, optional) overrides reclassifier defaults:

```json
{
  "chars_per_sec": 6.0,
  "reading_threshold_sec": 120,
  "thinking_threshold_sec": 300
}
```

Field meanings:

- **`chars_per_sec`** (default `6.0`): assumed typing speed when computing how much of a gap to attribute to "user was typing the next prompt." 6 cps ≈ 30 wpm. Bump up if you type fast; bump down if you tend to paste long prompts.
- **`reading_threshold_sec`** (default `120`): gaps ≤ this duration (after typing-debit subtraction) are classified as `reading`.
- **`thinking_threshold_sec`** (default `300`): gaps ≤ this (and > reading_threshold) are `thinking`. Gaps over this threshold are `away`.

## How it works

### What gets logged

The hook script (`hook.pl`) runs once per Claude Code event, parses the event payload from stdin, and appends a row to `~/.claude-time/events.sqlite`. The schema:

```sql
CREATE TABLE events (
  ts          INTEGER NOT NULL,    -- unix milliseconds
  session_id  TEXT NOT NULL,
  cwd         TEXT NOT NULL,
  event       TEXT NOT NULL,       -- e.g. "UserPromptSubmit", "Stop"
  tool_name   TEXT,                -- for PreToolUse/PostToolUse/PostToolUseFailure
  agent_type  TEXT,                -- for SubagentStart/SubagentStop
  meta        TEXT                 -- JSON blob, per-event payload
);
```

Per-event `meta` payloads:

| Event | meta keys |
|---|---|
| `UserPromptSubmit` | `prompt_length_chars` (integer only — no prompt text) |
| `PreToolUse` / `PostToolUse` / `PostToolUseFailure` | `tool_use_id` (pairs Pre with Post) |
| `SessionStart` | `source` (`startup` / `resume` / `clear` / `compact`) |
| `Notification` | `message` (truncated to 200 chars) |
| `Stop` / `SessionEnd` / `SubagentStart` / `SubagentStop` | NULL |

### Privacy

The hook is allergic to user content:

- **Prompts:** only `prompt_length_chars` is logged. The text itself is never read into a variable that reaches the INSERT.
- **Tool inputs / outputs:** the hook reads `tool_name` and `tool_use_id` and ignores `tool_input` / `tool_result` entirely.
- **No network:** the hook never makes an outbound call. Data stays on disk under `~/.claude-time/`.

A standalone test (`test/privacy_check.sh`) verifies this every structural-check run by seeding a known marker into payload fields and asserting the marker is absent from the DB binary.

### Reclassifier algorithm

For each `Stop` → next `UserPromptSubmit` pair within a session:

```
gap_wall_clock = next_ups.ts - stop.ts
typing_debit   = next_ups.prompt_length_chars / chars_per_sec
cross_session  = sum of typing_debits for UserPromptSubmit events in
                 OTHER sessions where stop.ts ≤ event.ts ≤ next_ups.ts
effective_gap  = max(0, gap_wall_clock - typing_debit - cross_session)

if effective_gap ≤ reading_threshold:        bucket = "reading"
elif effective_gap ≤ thinking_threshold:     bucket = "thinking"
else:                                        bucket = "away"
```

Why subtract `cross_session` typing time: if you were typing in instance B while instance A's gap was running, that gap shouldn't count A as "away." Point-event subtraction is conservative — it only credits the *typing* portion of B's activity, not the time you spent thinking in B between B's prompts. Future versions may use a more sophisticated overlap model.

### Multi-instance safety

The hook writes via SQLite in WAL mode (`PRAGMA journal_mode=WAL`) with a 2-second busy timeout. Concurrent writes from multiple Claude Code instances are handled by SQLite's WAL machinery — no inter-process coordination needed at write time.

## Disabling

Two reversible ways to disable tracking:

```bash
# Soft pause (keeps hooks wired, just stops writing):
#   remove or set to empty in ~/.claude/settings.json's env block:
#   "CLAUDE_TIME_TRACKING": ""

# Hard disable (unwire the hooks):
#   remove the hooks block added in step 2 above
```

To purge the DB entirely:

```bash
rm -rf ~/.claude-time
```

## Performance

Measured on this dev machine (macOS, /usr/bin/perl 5.34, sqlite3 3.51) via `test/bench.sh`, 100 invocations per scenario:

| Scenario | Total | Per-call |
|---|---|---|
| Fast-fail (`CLAUDE_TIME_TRACKING` unset) | 370ms | ~4ms |
| Set-path Stop event ×100 | 1391ms | ~14ms |
| Set-path mixed events (10 of each, all 10 event names) | 1376ms | ~14ms |

Linux should be ~5× faster (GNU `date` supports millisecond precision natively, avoiding a fallback). The spec's amended performance contract budgets < 20ms/call on macOS and < 5ms on Linux.

**The hook never blocks an upstream tool call.** Any write failure (read-only DB, missing `sqlite3` binary, locked file, malformed JSON, etc.) results in `exit 0` with no output.

**Concurrent writers are supported** via SQLite WAL mode. `test/stress_concurrent.sh` spawns 50 parallel hook invocations against the same DB — all 50 rows persist with no overwrites and no `database is locked` errors.

Run the bench yourself:

```bash
tools/claude-time/test/bench.sh           # measure + assert budget
tools/claude-time/test/bench.sh --no-fail # measure only, don't fail on slow hardware
tools/claude-time/test/stress_concurrent.sh
tools/claude-time/test/multi_instance.sh  # 2-session cross-session reattribution
```

## Files

```
tools/claude-time/
  hook.pl                  # Perl hook script (event-dispatch)
  reclassify.py            # Pure reclassification functions (stdlib only)
  claude-time              # Python CLI (argparse + sqlite3 reader + table renderer)
  README.md                # This file
  test/
    test_hook.sh           # Behavioral test for hook.pl (17 assertions)
    test_reclassify.py     # Unit tests for reclassify.py (24 assertions)
    test_cli.sh            # End-to-end test for claude-time CLI (10 assertions)
    privacy_check.sh       # Single-purpose privacy regression check
    bench.sh               # Performance benchmark + budget assertion
    multi_instance.sh      # Two-session cross-session reattribution scenario
    stress_concurrent.sh   # 50-parallel-writer concurrency stress test
```
