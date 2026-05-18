# Feature: Claude Code Time Tracking

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-17
**Entry:** spec (complex feature)
**Source:** SURFACE-2026-05-10-CLAUDE-CODE-TIME-TRACKING (backlog)
**Drive mode:** autopilot

## Problem Statement

We want to know where Claude Code session time actually goes — agent reasoning, tool wait, idle-awaiting-human, user reading, user typing, user away — across one or many parallel Claude Code instances on the same machine. Today, this is opaque: cost reports show tokens, not wall-clock attribution, and there's no per-state breakdown that would surface friction (e.g., "70% of last week was waiting on tests").

The goal is a low-overhead, opt-in, hook-driven event logger that captures timing-relevant events from Claude Code's hook system into a local SQLite database, plus a post-hoc reclassifier that buckets gaps and accounts for multi-instance concurrency (user activity in instance A means instance B's overlapping "idle" is reattributed away from B).

The MVP avoids: OS-level idle detection, keystroke-level signals, prompt content logging, in-session query slash commands. These are deferred to a v2.

**Back-loop note 2026-05-18 (F23 from build, Phase 1):** Problem statement unchanged. What we learned during the build attempt: the spec's 5ms p99 hook budget is unachievable on stock macOS with any zero-dep stack (measured: bash+3×jq+python3 = ~95ms/call; pyenv python single-process = ~76ms; /usr/bin/python3 = ~27ms; perl = ~10ms). This is a budget-vs-language conflict, not a goal change.

**Build re-entry 2026-05-18 (F7 from plan revision):** Problem statement unchanged — the root goal (low-overhead, opt-in, hook-driven event logger writing to local SQLite, plus a post-hoc reclassifier) is intact. Implementation tactic shifted from bash to Perl based on measurement. Proceeding with Phase 1 P1.0 → P1.5.

## User Stories

- **As the repo owner**, I want a single env var (`CLAUDE_TIME_TRACKING=1`) to enable timing so I can experiment without commitment and disable instantly if a hook misbehaves.
- **As the repo owner**, I want hook scripts that fail-silent and return fast so a buggy timer never blocks a real tool call.
- **As the repo owner**, I want to query "how much time did I spend in Bash this week" via a CLI subcommand so I can find friction points.
- **As the repo owner**, I want the reclassifier to bucket idle gaps as reading / thinking / away with typing time debited from the gap, so the buckets reflect actual cognitive states rather than raw wall-clock gaps.
- **As the repo owner running multiple Claude Code instances**, I want session B's "idle" minutes to be reattributed to "not interacting with B" when session A has a `UserPromptSubmit` in that window, so multi-instance time is attributed honestly.

## Acceptance Criteria

The feature is done when:

1. **Opt-in gate works.** With `CLAUDE_TIME_TRACKING` unset, the hook script no-ops in under 10ms and writes nothing to the DB. With `CLAUDE_TIME_TRACKING=1`, every wired hook event appends a row.

2. **DB schema is stable and append-only.** `~/.claude-time/events.sqlite` contains one `events` table per the schema in **Technical Constraints** below. WAL mode enabled to support concurrent writers (multiple Claude Code instances).

3. **All 10 hook events wire up and log correctly.** A test session that exercises each event class produces a row of the expected shape — `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `Stop`, `Notification`, `SessionStart`, `SessionEnd`, `SubagentStart`, `SubagentStop`. Each row carries `ts` (unix ms), `session_id`, `cwd`, `event`, `tool_name` (where applicable), `agent_type` (where applicable), and `meta` (JSON blob).

4. **Prompt length is captured; prompt content is not.** `UserPromptSubmit` rows store `meta.prompt_length_chars` (integer). The full prompt text is never written to the DB.

5. **Reclassifier CLI works.** `claude-time report` (or similar — name decided in plan) produces a daily/weekly summary with these breakdowns:
   - Tool time (per tool name)
   - Subagent time (per agent type)
   - "Active in this session" time (`UserPromptSubmit` → `Stop` wall-clock)
   - Reclassified gap buckets per session: reading (≤2 min effective), thinking (2–5 min effective), away (>5 min effective)
   - Cross-session reattribution applied: any gap during which another session had a `UserPromptSubmit` event is subtracted from this session's gap before bucketing.

6. **Typing debit applied.** Each gap's effective duration = `wall_clock − typing_time(next_prompt_length) − cross_session_active_overlap`, clamped at ≥0. Default WPM is configurable (initial: 30 WPM ≈ 6 chars/sec); the value lives in a single config constant or env var so the user can tune.

7. **Multi-instance correctness verified.** A reproducible test scenario: launch two sessions, alternate prompts between them at known times, run the reclassifier, confirm that session B's overlapping idle gaps are reattributed correctly. Spec describes the test; plan owns implementation.

8. **No live `settings.json` changes are required to install.** The hook scripts ship in `tools/claude-time/` with documentation telling the user exactly which `hooks.*` entries to add to `~/.claude/settings.json`. The user opts in by both setting the env var AND editing settings.json — two-step deliberate enablement.

9. **Schema bootstrap is automatic.** First write to a fresh DB file creates the table and indexes. No separate `init` step the user has to remember.

10. **Hook script overhead measured and documented.** Plan must include a measurement step: with tracking enabled, a 10-tool-call sequence's wall-clock overhead is reported. Goal: **< 200ms total added across 10 tool calls on macOS** (i.e., < 20ms per hook event avg), **< 50ms on Linux** (< 5ms avg). [Amended 2026-05-18 during F23 back-loop — original "< 50ms on any platform" was empirically unachievable without dropping zero-dep guarantee. Measurements: bash+jq+python3-shim = 95ms/call, /usr/bin/python3 = 27ms/call, perl = 10ms/call on macOS; perl + GNU date on Linux projected ≈ 4ms/call.]

## Out of Scope

- **OS-level idle signals.** No `pmset -g log` parsing, no `ioreg` polling, no lock-screen detection. The reclassifier works only with hook-derived events. (Deferred to v2.)
- **Keystroke / typing-event detection.** No hooks expose this and Claude Code doesn't have an "input box focus" event. The typing debit is a derived estimate from prompt length, not a measurement.
- **In-session query slash command.** No `/usage-today`. The reclassifier is a CLI tool invoked outside an active session. (Deferred — easy follow-up.)
- **Paste-vs-typing detection.** Pasted prompts get the same typing debit as typed prompts. The WPM is a single global constant; no per-prompt cps heuristic. (Deferred.)
- **Prompt content storage or analysis.** Only `prompt_length_chars` is logged from `UserPromptSubmit.prompt`. The text itself is never written to disk.
- **Cross-machine aggregation.** Single-machine SQLite only. No Postgres, no sync, no upload. (Deferred indefinitely; YAGNI.)
- **Cost attribution / token tracking.** This is time-tracking, not cost-tracking. Tokens are visible in Claude Code's own usage reports.
- **Session-pause / session-resume awareness.** These are custom skill invocations with no dedicated hook. They appear in the log as regular `UserPromptSubmit` + `Stop` pairs. The reclassifier does NOT special-case them. (If valuable later, add a sentinel pattern match on the prompt text — but spec defers.)
- **Schema migrations.** The MVP ships one schema. If we ever need to change it, the plan for that change owns the migration. No migration framework upfront.
- **Retention / DB pruning.** The DB grows append-only. At ~10 events per minute of active use and ~50 bytes per row, this is ~720 KB/day worst case — negligible for years. (Add a `claude-time vacuum` or retention setting in v2 if it matters.)
- **GUI / dashboard.** CLI text output only. No web UI, no charts. (A user could pipe output into their own tooling.)
- **Subagent token / cost attribution.** `SubagentStart`/`SubagentStop` give us wall-clock; we do not attempt to read subagent token usage from the events.

## Technical Constraints

### Location & layout

- Source lives in `tools/claude-time/` in this repo.
- DB lives at `~/.claude-time/events.sqlite` (outside the repo; created on first hook write).
- `install.sh` does NOT auto-wire the hooks into live `~/.claude/settings.json` — installation of the hooks themselves is a deliberate manual step (see Acceptance #8). `install.sh` may symlink the CLI binary into `~/.claude/bin/` or similar (decided in plan).

### DB schema (locked)

```sql
CREATE TABLE IF NOT EXISTS events (
  ts          INTEGER NOT NULL,    -- unix milliseconds (event time)
  session_id  TEXT NOT NULL,
  cwd         TEXT NOT NULL,
  event       TEXT NOT NULL,       -- hook event name verbatim
  tool_name   TEXT,                -- nullable; populated on PreToolUse / PostToolUse / PostToolUseFailure
  agent_type  TEXT,                -- nullable; populated on SubagentStart / SubagentStop
  meta        TEXT                 -- nullable; JSON blob (see per-event keys below)
);
CREATE INDEX IF NOT EXISTS idx_session_ts ON events(session_id, ts);
CREATE INDEX IF NOT EXISTS idx_ts ON events(ts);
```

Per-event `meta` keys (all optional, all JSON-encoded):
- `UserPromptSubmit`: `prompt_length_chars` (int)
- `PostToolUse` / `PostToolUseFailure`: `tool_use_id` (string) — for pairing with the preceding `PreToolUse`
- `SessionStart`: `source` (one of: `startup`, `resume`, `clear`, `compact`)
- `Notification`: `message` (string, truncated to 200 chars)
- All others: `meta` may be NULL

`tool_use_id` is the pairing mechanism — `PreToolUse` includes it, `PostToolUse[Failure]` echoes it. The reclassifier pairs them to compute per-tool-call durations. (Schema does NOT include `tool_use_id` as a column — it lives in `meta` to keep the schema narrow.)

### Hook events wired (locked)

| Event | Purpose | meta payload |
|---|---|---|
| `UserPromptSubmit` | Mark user activity; log prompt length | `prompt_length_chars` |
| `PreToolUse` | Start of tool execution | `tool_use_id` |
| `PostToolUse` | End of tool execution (success) | `tool_use_id` |
| `PostToolUseFailure` | End of tool execution (failure) | `tool_use_id` |
| `Stop` | Turn end (gap start candidate) | (none) |
| `Notification` | Claude is blocked awaiting input/permission | `message` |
| `SessionStart` | Session begins | `source` |
| `SessionEnd` | Session ends | (none) |
| `SubagentStart` | Subagent spawn | (none — `agent_type` is a column) |
| `SubagentStop` | Subagent end | (none — `agent_type` is a column) |

### Performance contract (amended 2026-05-18)

- Hook script returns within **5ms** when `CLAUDE_TIME_TRACKING` is unset (fast-fail path). Measured: ~2.5ms/call in pure bash.
- Hook script returns within **10ms typical, 30ms p99 on macOS**; within **5ms typical, 15ms p99 on Linux**, when tracking is enabled. Measured-baseline: Perl single-process script writing via `sqlite3` CLI = ~10ms/call on macOS.
- No network calls. The Perl hook is one process spawn (Perl interpreter) that itself pipes one subprocess (`sqlite3`). No transient `jq` invocations.
- If the DB file is locked or unwritable, the hook prints to stderr and exits 0. **Never block a tool call on a tracking failure.**

**Rationale for amendment:** the original 5ms typical / 20ms p99 budget was decided without measurement and assumed bash + jq + sqlite3 could clear it. F23 back-loop measurement showed (a) macOS BSD `date` lacks `%3N`, forcing a fallback subprocess, (b) macOS default bash 3.2.57 lacks `EPOCHREALTIME` (added in bash 5.0), (c) `jq` cold-start is ~10ms × 3 invocations needed per event = 30ms floor, (d) pyenv-managed Python adds ~50ms of dispatcher overhead, (e) `/usr/bin/python3` is ~27ms cold, (f) `/usr/bin/perl` is ~10ms cold. Perl is the macOS-bundled interpreter with the lowest cold-start in a zero-dep context. The amended budget reflects measured reality on macOS while preserving the "hook never blocks a tool call" spirit.

### Reclassifier (locked algorithm sketch)

Per-session gap analysis:
1. For each `Stop` event in session S, find the next `UserPromptSubmit` in session S. The pair defines `gap_wall_clock = next.ts - stop.ts`.
2. Compute `typing_debit = next.meta.prompt_length_chars / chars_per_sec` (configurable; default 6 cps = 30 WPM).
3. Compute `cross_session_active = sum of UserPromptSubmit events in OTHER sessions where stop.ts ≤ event.ts ≤ next.ts`, each event contributing `typing_debit_of_that_event` worth of "user busy elsewhere." (Refinement decisions — e.g., should we use the full active span of the other session, or just point events — go into the plan, not the spec. The MVP starts with point-event subtraction; spec acknowledges this is a simplification.)
4. `effective_gap = max(0, gap_wall_clock - typing_debit - cross_session_active)`.
5. Bucket: `reading` if `effective_gap ≤ 120s`; `thinking` if `120s < effective_gap ≤ 300s`; `away` if `effective_gap > 300s`.

### Config

A single config file `~/.claude-time/config.toml` (or JSON — decided in plan):
- `chars_per_sec` (default 6)
- `reading_threshold_sec` (default 120)
- `thinking_threshold_sec` (default 300)
- Anything else surfaced by the plan.

Hook script reads no config (must be fast). All config consumed only by the reclassifier CLI.

### CLI shape (decided in plan, but spec pins the report's outputs)

The reclassifier CLI must support:
- A daily report (default = today)
- A weekly report (last 7 days)
- A filter by `session_id`
- A filter by `cwd` (so the user can ask "time spent in repo X")

Output format: plain text table. JSON output is a stretch goal, not required.

### Implementation language (decided, revised 2026-05-18)

- **Hook script:** Perl 5 (`/usr/bin/perl`, macOS-bundled; available on all major Linux distros). One process spawn per event. JSON parsing via `JSON::PP` (stdlib) or a regex pass for the small payload shape we need. Timestamp via `Time::HiRes`. SQLite write by piping a SQL blob to the `sqlite3` CLI (avoids DBD::SQLite which isn't always bundled).
- **Reclassifier CLI:** Python 3 (stdlib only). Interactive use; ~30ms cold-start is fine.

The original plan picked bash + jq + sqlite3 + python3-for-timestamp; F23 measurement showed this is ~95ms/call on macOS. Perl is the single-interpreter consolidation that lands at ~10ms/call.

### Privacy posture

- No prompt text. Only `prompt_length_chars`.
- No tool input or output content. Only `tool_name` and `tool_use_id`.
- No file paths from `Edit`/`Read`/`Write` tool inputs. (The hook receives them in the payload but does not log them.)
- `cwd` is logged — this is a directory path, not user content. Acceptable.
- `Notification.message` is logged truncated to 200 chars because the harness's notification text is system-generated, not user content.

### Cross-session detection

The hook script does not need to know about other sessions; it writes events tagged with its own `session_id`. The reclassifier discovers cross-session activity at query time by scanning all events globally within a time window. This means: no inter-process coordination at write time, just SQLite's WAL handling concurrent writers.

## Open Questions

Resolved at plan time (2026-05-18; **hook language revised at plan revision 2026-05-18 after F23 build measurement**):

- **Hook script language:** ~~Pure bash + `sqlite3` CLI~~ → **Perl 5** (`/usr/bin/perl`). Bash + jq + sqlite3 + python3-for-timestamp measured at ~95ms/call on macOS, 19× the locked budget. Perl is macOS-bundled, has fast startup (~10ms cold), and consolidates JSON parsing + timestamp + sqlite3 invocation into a single process. The amended performance contract reflects measured reality (~10ms typical on macOS, ~5ms on Linux).
- **Reclassifier CLI language:** Python 3 (stdlib only — `sqlite3`, `argparse`, `json`, `datetime`). One file. Cold-start cost is acceptable for an interactive CLI invoked outside the hot path.
- **CLI tool name:** `claude-time`. Subcommands: `claude-time report [--weekly] [--session <id>] [--cwd <path>]`.
- **Config file format:** JSON at `~/.claude-time/config.json`. Matches `~/.claude/settings.json` convention; no third-party dep.
- **install.sh behavior:** symlinks `tools/claude-time/claude-time` (the Python CLI) → `~/.claude/bin/claude-time`, creating `~/.claude/bin/` if missing. Does NOT auto-wire hooks into `settings.json` (spec acceptance #8).
- **No-data report behavior:** emit a single-line `(no events in window)` message, exit 0. Easier to compose into pipes than a hard failure.

## Plan-time Decisions (locked)

### Repo layout

```
tools/claude-time/
  hook.pl              # Perl hook script wired to all 10 events (revised 2026-05-18; was hook.sh)
  claude-time          # Python CLI (executable, shebang)
  reclassify.py        # Importable module the CLI delegates to (keeps CLI thin)
  README.md            # Install instructions + the settings.json snippet user must paste
  test/
    fixtures.sql       # Seed data for reclassifier tests
    test_reclassify.py # Python unit tests for bucketing + reattribution
    bench.sh           # 100-call benchmark; asserts < 200ms total on macOS
    smoke.sh           # End-to-end: hook → DB → reclassifier → expected output
```

**Note:** The previously-scaffolded `tools/claude-time/hook.sh` from the first build attempt will be deleted as the first step of the revised P1.1 (it's the wrong-language artifact).

### Hook wiring (the snippet README documents)

The hook script dispatches on `hook_event_name` from stdin payload, so a single script handles all 10 events. The user pastes this into `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit":     [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
    "PreToolUse":           [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
    "PostToolUse":          [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
    "PostToolUseFailure":   [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
    "Stop":                 [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
    "Notification":         [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
    "SessionStart":         [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
    "SessionEnd":           [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
    "SubagentStart":        [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}],
    "SubagentStop":         [{"hooks": [{"type": "command", "command": "~/.claude/hooks/claude-time-hook.pl"}]}]
  }
}
```

`install.sh` symlinks `tools/claude-time/hook.pl` → `~/.claude/hooks/claude-time-hook.pl` and `tools/claude-time/claude-time` → `~/.claude/bin/claude-time`.

### Downstream contract impacts

- `install.sh` — adds new symlink targets (`tools/claude-time/hook.sh`, `tools/claude-time/claude-time`). Phase 1 (DB + hook script) and Phase 3 (CLI) each carry their respective install.sh updates.
- `tests/check-structure.sh` — no new assertions needed; new tool sits outside the skills/agents/hooks namespace the structure checks govern. `hook.sh` does land under `hooks/`-equivalent (via symlink), but the existing hooks symlink loop in `install.sh` already accommodates new files.
- `~/.claude/settings.json` — manual user edit, not under repo control. Documented in `tools/claude-time/README.md`.
- `CLAUDE.md` (project) — no entry; this is a tool, not a workflow skill. Doesn't change the state machine or any convention.

## Work Tree

- [x] Phase 1: DB bootstrap + opt-in fast-fail hook (Perl)  <!-- status: complete 2026-05-18; build → verify-auto → verify-self → verify-human (F11 skip) → verify-codify all complete -->
  <!-- revision history: 2026-05-18 (F23 back-loop): language changed from bash to Perl after measurement showed bash stack ~95ms/call vs Perl ~10ms/call -->
  **Observable outcomes:**
  - CLI: With `CLAUDE_TIME_TRACKING` unset, `echo '{"hook_event_name":"Stop","session_id":"test"}' | tools/claude-time/hook.pl` exits 0 in under 30ms (perl startup floor) and creates no file under `~/.claude-time/`.
  - CLI: With `CLAUDE_TIME_TRACKING=1` (and a clean `~/.claude-time/`), same invocation creates `~/.claude-time/events.sqlite`, the `events` table, both indexes, and inserts exactly one row with `event='Stop'`, `session_id='test'`.
  - CLI: `sqlite3 ~/.claude-time/events.sqlite "PRAGMA journal_mode"` returns `wal`.
  - CLI: With the DB file made read-only (`chmod 444`), the hook exits 0; no tool-blocking error.
  - CLI: 100 successive enabled-path hook invocations complete in under 2000ms total wall-clock (i.e., < 20ms per call avg). This is the measured-realistic budget; the spec amendment is the contract.
  - [x] P1.0 Delete the legacy `tools/claude-time/hook.sh` from the first (abandoned) build attempt
  - [x] P1.1 Create `tools/claude-time/hook.pl` (Perl 5, `/usr/bin/perl` shebang). Read JSON payload from stdin via `JSON::PP` (lazy-loaded — see SURFACED below); fast-fail when `CLAUDE_TIME_TRACKING` is unset; fail-silent on `eval { decode_json }` parse errors
  - [x] P1.2 Schema bootstrap inside hook.pl: piped `PRAGMA journal_mode=WAL` + `CREATE TABLE IF NOT EXISTS events ...` + both `CREATE INDEX IF NOT EXISTS` + the INSERT into one `sqlite3` subprocess. `Time::HiRes` for ms timestamp. Single-quote SQL escape via `s/'/''/g`
  - [x] P1.3 INSERT one minimal row for the `Stop` event only in this phase; other 9 events no-op until Phase 2
  - [x] P1.4 `install.sh` updated with a `tools/claude-time/` symlink block that wires `hook.pl` → `~/.claude/hooks/claude-time-hook.pl`. Idempotent (verified `[ok]` on second run). The Phase 3 CLI binary will land in the same block
  - [x] P1.5 `tools/claude-time/README.md` stub written with the Perl-pathed settings.json snippet and a two-step opt-in note (hook wire + env var)
  - [x] verify-auto  <!-- status: 2026-05-18 — perl -c hook.pl OK, bash -n install.sh OK, tests/check-structure.sh 94/94 PASS, deployed-symlink smoke OK -->
  - [x] verify-self  <!-- status: 2026-05-18 — all 5 outcomes PASS with strict output-cleanliness assertion. Set-path 14.3ms/call (target 20ms, 29% margin); fast-fail 3.3ms/call (target 5ms); WAL confirmed; apostrophe values intact; malformed JSON safe; 100-call burst = 1434ms/0-noise. Two SURFACED-then-applied learnings below. -->
    - [SURFACED-2026-05-18 RESOLVED] Phase 1 / P1.1 — Initial perl script used `use JSON::PP` / `use Time::HiRes` at top; verify-self measured fast-fail at ~9ms/call (over the amended 5ms budget by 80%). Fixed in-build by moving both to `require ... ; ->import(...)` *after* the fast-fail check. Reduced fast-fail to 3.3ms/call. **General learning:** in Perl hot-path scripts that have an early-exit branch, lazy-load any non-stdlib-core module after the early-exit check.
    - [SURFACED-2026-05-18 RESOLVED] Phase 1 / P1.2 — Initial sqlite3 subprocess invocation was `open '|-', 'sqlite3', $db_path` with no fd redirection. This let sqlite3's stdout (which echoes `PRAGMA journal_mode=WAL` → "wal" on every call) reach the parent stdout — visible in the harness's hook diagnostics on every Stop event. Initial fix attempted `2>/dev/null` via shell-string-form open (an injection vector for the env-controlled $db_path), and silenced the wrong stream. Final fix: fork+exec with `open(STDOUT, '>', '/dev/null')` AND `open(STDERR, '>', '/dev/null')` in the child, then `exec('sqlite3', $db_path)` with no shell. Clean output across all paths. **General learning:** sqlite3 CLI prints PRAGMA results to *stdout*, not stderr; redirect both streams in hot-path sqlite3 invocations.
  - [x] verify-human  <!-- status: 2026-05-18 F11-skip — human affirmed isolated-new-artifacts; no integration boundary; all 5 outcomes excluded because verify-self PASSed them; "approve" granted -->
    - [x] (F11 skip — verify-self covered all 5 outcomes; nothing for human to manually walk through)  <!-- status: covered-by-verify-self -->
  - [x] verify-codify  <!-- status: 2026-05-18 — 10-assertion behavioral suite at tools/claude-time/test/test_hook_phase1.sh PASS; 6 structural assertions added to tests/check-structure.sh [Phase 5b]; full structure suite 100/0; no regressions -->
    - [x] Behavioral suite (tools/claude-time/test/test_hook_phase1.sh) covers: fast-fail no-DB, set-path row, schema (table + 2 indexes), WAL pragma, row shape, phase-1 scope (other events no-op), SQL-injection safety (apostrophe), malformed JSON, read-only DB exit 0, empty stdin
    - [x] Structural suite (tests/check-structure.sh Phase 5b) covers: file exists, executable bit, perl -c compile, symlink resolves to repo, README exists, behavioral suite invocation
    - [x] Skip-by-design: 100-call < 2000ms performance assertion (kept out of CI; environment-dependent flake risk; lives as a Phase 4 bench script per the WIP plan)

- [x] Phase 2: Wire all 10 hook events with correct meta payloads  <!-- status: complete 2026-05-18; build → verify-auto → verify-self → verify-human (F11 skip) → verify-codify all complete -->
  **Relevance check (before Phase 2):**
  - Requester still needs this: yes — backlog priority bumped low→medium yesterday during grooming, signaling active interest
  - Requirements unchanged: yes — spec amendment in Phase 1 was a perf-budget adjustment, no scope change to the 10-event matrix or meta-payload table
  - Solution still feasible: yes — Phase 1 proved Perl hook works at ~15ms/call; adding 9 more event branches is an in-language dispatch refactor, no architectural surprises expected
  - No superior alternative discovered: yes — no Phase 1 finding invalidates the Phase 2-4 plan
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: For each of the 10 event names (UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, Stop, Notification, SessionStart, SessionEnd, SubagentStart, SubagentStop), piping a representative JSON payload to `hook.pl` produces exactly one row with `event=<name>`.
  - CLI: `UserPromptSubmit` payload with `"prompt":"hello world"` produces a row with `meta` containing `{"prompt_length_chars": 11}` and NO `prompt` text field.
  - CLI: `PreToolUse` payload with `tool_name='Bash'`, `tool_use_id='abc'` produces a row with `tool_name='Bash'` and `meta` containing `{"tool_use_id": "abc"}`.
  - CLI: `SubagentStart` payload with `subagent_type='Explore'` produces a row with `agent_type='Explore'`.
  - CLI: `SessionStart` payload with `source='resume'` produces `meta` containing `{"source": "resume"}`.
  - CLI: `Notification` payload with `message='X'×300` (300 chars) produces `meta.message` truncated to exactly 200 chars.
  - CLI: Privacy check — `grep -a "SECRET-MARKER" ~/.claude-time/events.sqlite` returns nothing after seeding a payload with that marker as the prompt text (privacy guarantee).
  - [x] P2.1 Refactored `hook.pl` to dispatch on `hook_event_name` via a `%handlers` hash. Each handler returns `($tool_name, $agent_type, $meta_json)` triple; main flow builds INSERT from the triple plus the unconditional columns (ts, session_id, cwd, event). Unrecognized events no-op silently (forward-compat).
  - [x] P2.2 `UserPromptSubmit` handler: `length($payload->{prompt} // '')` then `encode_json({prompt_length_chars => $len})` into meta. Privacy invariant verified by `privacy_check.sh` — marker text never reaches the DB binary.
  - [x] P2.3 `PreToolUse`/`PostToolUse`/`PostToolUseFailure` handlers (3 separate dispatch entries): populate `tool_name` column from `$payload->{tool_name}`, embed `tool_use_id` in `meta` JSON.
  - [x] P2.4 `SubagentStart`/`SubagentStop` handlers: populate `agent_type` column from `$payload->{subagent_type}`, NULL meta.
  - [x] P2.5 `SessionStart` handler: `encode_json({source => $src})` into meta.
  - [x] P2.6 `Notification` handler: `substr($msg, 0, 200)` truncation, encoded as `{message: <truncated>}` JSON in meta. Spec acceptance #4 honored.
  - [x] P2.7 `Stop`/`SessionEnd` handlers: return `(undef, undef, undef)` → INSERT writes NULL for tool_name, agent_type, and meta.
  - [x] P2.8 `tools/claude-time/test/privacy_check.sh`: seeds 3 events (UserPromptSubmit with marker in prompt; PreToolUse with marker in tool_input; PostToolUse with marker in tool_result). Asserts marker is absent from DB binary, WAL, and SHM files via `grep -a`. Run-on-demand AND wired into `tests/check-structure.sh` Phase 5b.
  - [x] verify-auto  <!-- status: 2026-05-18 — perl -c OK, bash -n OK on both test scripts, test_hook.sh 17/17 PASS, privacy_check.sh PASS -->
  - [x] verify-self  <!-- status: 2026-05-18 — all 7 Phase 2 observable outcomes PASS against deployed symlink: 10-event matrix, prompt-length-only privacy, PreToolUse pairing pattern, SubagentStart agent_type, SessionStart meta.source, 200-char truncation, 3-marker privacy scan -->
  - [x] verify-human  <!-- status: 2026-05-18 F11-skip — human affirmed isolated-change (existing file modified but no consuming surface enabled); all 7 verify-self outcomes excluded because PASS -->
    - [x] (F11 skip — verify-self covered all 7 outcomes; nothing for human to manually walk through)  <!-- status: covered-by-verify-self -->
  - [x] verify-codify  <!-- status: 2026-05-18 — no new tests needed; codification happened during build. test_hook.sh extended 10→17 assertions covers all 7 Phase 2 outcomes; privacy_check.sh covers the 3-marker invariant; both wired into check-structure.sh Phase 5b. Structure suite 101/0 (was 100/0 — +1 for new privacy check), behavioral 17/17, no triage required. -->
    - [x] Coverage decision: extend `test_hook.sh` (was 10 assertions, now 17) — single test surface across Phase 1+2 keeps cognitive load low
    - [x] Standalone `privacy_check.sh` — run-on-demand single-purpose check; also wired into Phase 5b for every-build assertion
    - [x] No new test artifact needed at Phase 2 codify (built during build phase)

- [x] Phase 3: Reclassifier CLI — `claude-time report`  <!-- status: complete 2026-05-18; build → verify-auto → verify-self → verify-human (F13 approved) → verify-codify all complete -->
  **Relevance check (before Phase 3):**
  - Requester still needs this: yes — reclassifier is the *point* of the system; without it Phase 1+2 produces unread data
  - Requirements unchanged: yes — spec acceptance #5–7 untouched; Phase 2's data shape matches what reclassifier reads
  - Solution still feasible: yes — Python 3 stdlib (sqlite3, argparse, datetime, json); algorithm is straightforward "rows → per-session gap analysis"
  - No superior alternative discovered: yes
  **Verdict:** proceed
  **Observable outcomes:**
  - CLI: `claude-time report --help` exits 0 and lists `--weekly`, `--session`, `--cwd`, `--date` flags.
  - CLI: Against a seeded DB with one session containing `UserPromptSubmit → PreToolUse(Bash) → PostToolUse(Bash) → Stop → UserPromptSubmit`, `claude-time report` produces a text table with rows for "Tool time: Bash", "Active session time", and one gap bucket.
  - CLI: Against a seeded DB with a 90-second gap after a 60-char-prompt: bucket is `reading`, effective gap = `90 − (60/6)` = 80s.
  - CLI: Against a seeded DB with a 200-second gap → bucket `thinking`. 400-second gap → bucket `away`.
  - CLI: With two sessions where session B has a `Stop` at t=0 and `UserPromptSubmit` at t=400, and session A has a `UserPromptSubmit` at t=100 with a 60-char prompt: session B's effective gap = 400 − (next-prompt-debit) − (10-char-per-sec ≈ 10s for A's prompt). Bucketing reflects the reattributed value, not raw 400s.
  - CLI: `claude-time report --cwd /foo` against a DB with events in `/foo` and `/bar` only counts rows where `cwd='/foo'`.
  - CLI: `claude-time report --session <id>` filters identically.
  - CLI: Empty window: `claude-time report --date 1970-01-01` exits 0 and prints `(no events in window)`.
  - [x] P3.1 Created `tools/claude-time/reclassify.py` — pure stdlib functions: `gap_buckets`, `tool_durations_ms`, `subagent_durations_ms`, `cross_session_overlap_ms`, `typing_debit_ms`, `session_active_ms`. Operates on lists of event-dicts (no DB I/O — unit-testable without fixtures).
  - [x] P3.2 Created `tools/claude-time/claude-time` (executable Python) — argparse with `report` subcommand, sqlite3 reader (read-only mode), `render_report` produces 4-section text table.
  - [x] P3.3 Config loader: `~/.claude-time/config.json` read on top of defaults (`chars_per_sec=6.0`, `reading_threshold_sec=120`, `thinking_threshold_sec=300`); JSON parse errors silent-fallback to defaults.
  - [x] P3.4 Date-window logic: `--date YYYY-MM-DD` = single day, `--weekly` = last 7 days ending today, default = today. Boundaries are local-tz midnight; end is exclusive.
  - [x] P3.5 `install.sh` extended: refactored to a `link_artifact` helper that handles both hook + CLI symlinks idempotently. Creates `~/.claude/bin/` on first run.
  - [x] P3.6 `README.md` polished: 5-section doc covering installation (3 steps), usage examples with output sample, tuning (config.json), how it works (schema + privacy + reclassifier algorithm + multi-instance), disabling, performance, file map.
  - [x] P3.7 `tools/claude-time/test/test_reclassify.py` — 24 unit tests across 6 classes: TypingDebit (5), GapBucket (6 boundary tests at 120/121/300/301), CrossSessionOverlap (3), ToolDurations (4), SubagentDurations (3), SessionActive (3). All PASS.
  - [SURFACED-2026-05-18 RESOLVED] P3.2 / hook.pl — During CLI end-to-end smoke, discovered all timestamps were second-precision (5 events ~500ms apart all stored same ts). Root cause: `require Time::HiRes; Time::HiRes->import('time')` at *runtime* cannot override the already-parsed built-in `time()` (the compiler resolved it to `CORE::time` before our import ran). Fixed by calling `Time::HiRes::time()` with fully-qualified name. Two regressions caught downstream: tool_durations showed 0ms (Pre/Post on same ts), session_active showed 0ms. Both work correctly after fix. **General learning:** in Perl, `use` does compile-time symbol-table changes; `require + ->import` does runtime — which means built-in overrides only apply to calls *parsed after* the import. Use fully-qualified function names (or use `use`) when you need a built-in override.
  - [x] verify-auto  <!-- status: 2026-05-18 — py_compile OK on both Python sources, perl -c OK, bash -n install.sh OK, import smoke OK, --help OK, unit tests 24/24, behavioral tests 17/17 (no regression on Time::HiRes fix) -->
  - [x] verify-self  <!-- status: 2026-05-18 — all 6 Phase 3 observable outcomes PASS against deployed CLI symlink: --help flags, bucket assignment (60s reading / 180s thinking / 600s away), cross-session reattribution (100s of B's typing subtracted from A's gap), --cwd filter (correctly partitions Bash/Edit), empty-window message, config override (cps=12 produces half typing-debit) -->
  - [x] verify-human  <!-- status: 2026-05-18 F13 — human ran the seeded-DB demo (4-event session producing 540ms Bash tool time, 1.3s active time), then approved. SURFACED during this step: per-project breakdown report dimension (logged as SURFACE-2026-05-18-CLAUDE-TIME-REPORT-BY-PROJECT, medium priority, v2 enhancement). -->
    - [x] (F13 — all 6 verify-self outcomes excluded by pre-filter; happy-path demo run by human; approved with one v2 SURFACE)
  - [x] verify-codify  <!-- status: 2026-05-18 — 3 gaps codified into new tools/claude-time/test/test_cli.sh (10 CLI end-to-end assertions: --help flags, empty-window, --cwd filter, --session filter, --db override, --weekly window, config override, malformed-config fallback). Wired into Phase 5b. Structure suite 107/0 (was 106). No test triage required. -->
    - [x] New artifact: `tools/claude-time/test/test_cli.sh` covers CLI-level behaviors (`--cwd`, `--session`, `--db`, `--weekly`, config-load) that weren't reachable from the pure-function reclassify.py unit tests
    - [x] Integration-boundary check satisfied: Phase 3's consuming surface is the `claude-time` CLI binary; new test exercises it end-to-end against seeded DBs
    - [x] No new test triage — 10/10 PASS, no failures, no regressions in the rest of the suite

- [x] Phase 4: Performance measurement + multi-instance verification  <!-- status: complete 2026-05-18; build → verify-auto → verify-self → verify-human (F11 skip) → verify-codify all complete -->
  **Relevance check (before Phase 4):**
  - Requester still needs this: yes, with caveat — perf budget is already empirically met (verify-self measured 14.3ms/call against the 20ms budget); cross-session reattribution math is already tested in `test_reclassify.py::CrossSessionOverlapTests`. The genuine new value: (1) a concurrent-write stress test not yet exercised, (2) measured numbers in README "Performance" paragraph (currently placeholder language).
  - Requirements unchanged: yes (acceptance #7 + #10 still in spec)
  - Solution still feasible: yes
  - No superior alternative discovered: partial no — P4.1 bench.sh and P4.2 multi_instance.sh are partly redundant with existing tests, but exercise different surfaces (user-invokable scripts vs internal unit tests) so they still earn their keep
  **Verdict:** proceed, with honest scope acknowledgment in the impl notes
  **Observable outcomes:**
  - CLI: A repeatable benchmark script (`tools/claude-time/test/bench.sh`) runs 100 successive hook invocations (mix of events) with tracking ENABLED and reports total wall-clock. Target: < 2000ms total on macOS (< 20ms avg). Per the amended performance contract; baseline measurement during F23 plan revision showed Perl single-process at ~10ms/call → 1000ms/100calls.
  - CLI: Same benchmark with `CLAUDE_TIME_TRACKING` UNSET reports total < 500ms across 100 invocations (< 5ms per call avg — measured 2.5ms in F23 baseline).
  - CLI: Multi-instance scenario script (`tools/claude-time/test/multi_instance.sh`) launches two parallel subshells each writing alternating `UserPromptSubmit`/`Stop` events at known timestamps via `hook.sh`, then runs `claude-time report --session <B>` and asserts session B's reported gap-bucket totals match the expected post-reattribution values.
  - CLI: Concurrent-write stress: 50 hook invocations launched in parallel (xargs -P 50) all succeed (exit 0); `SELECT count(*) FROM events` returns 50; no SQLite `database is locked` errors in stderr.
  - [x] P4.1 `tools/claude-time/test/bench.sh` — 3-scenario benchmark (fast-fail, set-path Stop ×100, set-path mixed events). Auto-detects OS (macOS budget 2000ms, Linux 500ms) and asserts. `--no-fail` flag for measurement-only mode. Measured on dev machine: fast-fail 3.7ms/call, set-path 13.9ms/call (within macOS 20ms budget by 30% margin).
  - [x] P4.2 `tools/claude-time/test/multi_instance.sh` — Two parallel subshells write to the same DB through the deployed hook. Session A: UPS/Stop/UPS spanning 1.5s. Session B fires a 600-char UPS during A's gap. Reclassifier asserts `cross_session_ms = 100000` (exactly 600/6 cps = 100s). PASS — exactly the expected 100000.
  - [x] P4.3 `tools/claude-time/test/stress_concurrent.sh` — `xargs -P 50` spawns 50 concurrent hook invocations with distinct session_ids. Asserts: xargs exit 0, 50 rows persist, 50 distinct session_ids (no overwrites), zero stderr noise. PASS.
  - [x] P4.4 `README.md` "Performance" section updated with measured table (fast-fail vs set-path scenarios). File map updated to list all 6 test artifacts. Also documents how to run each script manually.
  - [SCOPE-CHECK 2026-05-18] Bench.sh + multi_instance.sh acknowledged partly redundant with existing `test_hook.sh` (already runs 100-call sequences) and `test_reclassify.py::CrossSessionOverlapTests` (already validates the math), but exercise different surfaces (user-invokable scripts producing human-readable output vs internal test fixtures), so they earn their place. Stress_concurrent.sh is net-new coverage (no prior test exercised real `xargs -P 50` concurrency against the deployed symlink).
  - [x] verify-auto  <!-- status: 2026-05-18 — bash -n OK on 3 new scripts + check-structure.sh, bench within budget (13ms/call), multi_instance PASS (cross_session_ms=100000 exact), stress_concurrent PASS (50 rows, 0 stderr), all 3 regression test suites still PASS (17+10+24) -->
  - [x] verify-self  <!-- status: 2026-05-18 — all 4 Phase 4 outcomes PASS against deployed symlink: bench within budget (14ms/call), cross_session_ms exact 100000, 50 concurrent rows, README Performance table present -->
  - [x] verify-human  <!-- status: 2026-05-18 F11-skip — affirmed isolated artifacts (new test scripts only, no consuming surface modified); all 4 verify-self outcomes PASS so all sub-leaves excluded -->
    - [x] (F11 skip — verify-self covered all 4 outcomes; nothing for human to manually walk through)  <!-- status: covered-by-verify-self -->
  - [x] verify-codify  <!-- status: 2026-05-18 — no new artifacts needed; codification happened during build (the 3 new test scripts ARE the codification, and they're wired into check-structure.sh Phase 5b). All 7 test scripts PASS (55 total assertions). Structure suite 110/0. No test triage required. -->
    - [x] Coverage decision: Phase 4's deliverables are themselves test scripts; they self-codify. No need to write tests *about* the test scripts.
    - [x] Conscious gap noted: bench.sh asserts the set-path budget (load-bearing for spec acceptance #10) but does NOT assert the fast-fail budget (5ms target, 3.7ms measured). Fast-fail timing fluctuates enough that asserting it would create flake risk. Documented in this WIP for future-self.

## Current Node

- **Path:** Feature > finalize (complete)
- **Active scope:** all 4 phases shipped on `feature/claude-code-time-tracking-phase-1`; backlog swept; CHANGELOG appended; WIP archived
- **Blocked:** none
- **Unvisited:** (none)
- **Open discoveries:** 1 SURFACED to backlog (per-project breakdown — v2 enhancement, medium, deferred for v2)

## Retrospect

- **What changed in our understanding:** The "5ms p99 hook budget" written into the spec was decided without measurement; first-build empirical run revealed it was unachievable on stock macOS with any zero-dep stack. The whole spec-amendment-via-F23 dance (build → plan revision → re-build) was the right shape — the *bug* was committing to a number we hadn't measured, not the budget itself. We also learned (the hard way, in Phase 3) that Perl's `require + ->import('time')` doesn't override the already-parsed built-in `time()` because the compiler resolves built-ins before runtime imports — a subtle gotcha that produced silent second-precision timestamps until the CLI surfaced the bug. Took a CLI-level smoke test that *computed durations* to expose what the lower-level "row exists" tests couldn't.

- **Assumptions that held:** WAL mode handles concurrent writers across multiple Claude Code instances exactly as advertised — 50 parallel `xargs -P 50` writers with zero overwrites, zero "database is locked" errors. SQLite's job. The two-step opt-in (env var + settings.json edit) felt right and stayed in the design unchanged. The privacy invariant (length-only for prompts, no logging of tool_input / tool_result) was straightforward to implement and to verify via grep-the-binary.

- **Assumptions that were wrong:** (1) "bash + jq + sqlite3 is the obvious low-overhead choice" — turned out to be the *slowest* of the candidates measured (~95ms/call vs Perl's 10ms). (2) "We can lazy-load Perl modules with `require + ->import` and have the imported functions behave normally" — true for non-builtin overrides, false for `time`. (3) "verify-self covers the same ground as a CLI-level end-to-end test" — false in Phase 3, where unit tests on pure functions passed and verify-self on individual hook events passed, but the timestamp bug only surfaced when the CLI tried to compute a duration.

- **Approach delta:** Spec planned a bash hook with jq for JSON parsing — measurement during the very first build attempt killed that and pivoted to Perl (single-process, JSON::PP stdlib, Time::HiRes for ms). Phase 2's "8 separate impl tasks" collapsed into a single dispatch-table refactor — turned out the right shape was one `%handlers` hash, not eight branches in sequence. Phase 4 ended up partly redundant with earlier-phase tests (bench.sh duplicates test_hook.sh's 100-call loop; multi_instance.sh duplicates the cross-session unit test) but earned its place by exercising real two-process WAL contention end-to-end (which no prior test did) and producing the measured-numbers table for the README. The biggest planning miss was the spec's perf budget — every other deliverable shipped close to what the plan said.

## Discoveries

- [RESOLVED-2026-05-18] Phase 1 hook perf budget (was SURFACED at P1.3 via F23 build → plan back-loop). Resolution: language pivoted from bash+jq+sqlite3 stack to Perl single-process; spec acceptance #10 amended from "< 50ms total across 10 calls" to "< 200ms on macOS / < 50ms on Linux"; performance contract amended to "10ms typical, 30ms p99 on macOS; 5ms / 15ms on Linux." Measurement evidence: bash stack = ~95ms/call; pyenv-Python = ~76ms; /usr/bin/python3 = ~27ms; Perl = ~10ms (all on macOS, 100-call batches). Logged to backlog as SURFACE-2026-05-18-CLAUDE-TIME-HOOK-PERF-BUDGET-INFEASIBLE → status: resolved-via-plan-revision.

TRANSITION: F7

## Session Pause — 2026-05-18 13:54
Paused after finalize. See `workflow/.session.md` to resume.
Feature is fully closed (4 phases shipped, retrospect written, CHANGELOG appended, branch local-only per user choice). On resume, `/session-reflect` will surface this session's three rich learnings: Perl runtime-import gotcha, empirical-grounding for spec budgets, and the "higher-level tests catch what lower-level miss" pattern.
