#!/usr/bin/perl
# claude-time hook.pl — Claude Code hook that appends timing events to a local SQLite DB.
#
# Wire this into ~/.claude/settings.json under hooks.* events (see README.md).
# Gated by CLAUDE_TIME_TRACKING env var; reads JSON event payload from stdin.
# Exits 0 unconditionally — never blocks a tool call on a tracking failure.
#
# Why Perl: /usr/bin/perl is bundled on macOS and standard on Linux. Single-process
# (no jq subprocess), JSON::PP + Time::HiRes are stdlib. Measured ~15ms/call on
# macOS — the lowest zero-dep cold-start of the candidates evaluated during the
# F23 plan revision (vs ~95ms for bash+jq+python3, ~27ms for /usr/bin/python3).

use strict;
use warnings;

# ---- Fast-fail path: env var unset → exit 0 immediately. ----
# Bail before any `require` so the unset-env code path stays under ~6ms/call on
# macOS. JSON::PP is ~4ms of compile-time cost we don't want when tracking is off.
exit 0 unless $ENV{CLAUDE_TIME_TRACKING};

# From here on, tracking is enabled — load the modules we need.
require JSON::PP;     JSON::PP->import('decode_json', 'encode_json');
require Time::HiRes;  Time::HiRes->import('time');

# Drain stdin. Some Claude Code hook invocations may have no payload (manual test).
my $raw = '';
if (!-t STDIN) {
    local $/;
    $raw = <STDIN> // '';
}

# Parse JSON. Silently no-op on parse error rather than crash the hook.
my $payload = {};
if ($raw ne '') {
    my $parsed = eval { decode_json($raw) };
    $payload = $parsed if ref($parsed) eq 'HASH';
}

my $event_name = $payload->{hook_event_name} // '';
exit 0 if $event_name eq '';

# ---- Per-event handlers. Each returns ($tool_name, $agent_type, $meta_or_undef). ----
# Privacy invariant: the only place we touch $payload->{prompt} is to read its
# length. No handler may embed the prompt text itself in $tool_name, $agent_type,
# or $meta. The privacy_check.sh test asserts this externally.
my %handlers = (
    'UserPromptSubmit' => sub {
        my $len = length($payload->{prompt} // '');
        return (undef, undef, encode_json({ prompt_length_chars => $len + 0 }));
    },
    'PreToolUse' => sub {
        my $tool = $payload->{tool_name};
        my $tuid = $payload->{tool_use_id};
        my $meta = defined $tuid ? encode_json({ tool_use_id => "$tuid" }) : undef;
        return ($tool, undef, $meta);
    },
    'PostToolUse' => sub {
        my $tool = $payload->{tool_name};
        my $tuid = $payload->{tool_use_id};
        my $meta = defined $tuid ? encode_json({ tool_use_id => "$tuid" }) : undef;
        return ($tool, undef, $meta);
    },
    'PostToolUseFailure' => sub {
        my $tool = $payload->{tool_name};
        my $tuid = $payload->{tool_use_id};
        my $meta = defined $tuid ? encode_json({ tool_use_id => "$tuid" }) : undef;
        return ($tool, undef, $meta);
    },
    'SubagentStart' => sub {
        my $type = $payload->{subagent_type};
        return (undef, $type, undef);
    },
    'SubagentStop' => sub {
        my $type = $payload->{subagent_type};
        return (undef, $type, undef);
    },
    'SessionStart' => sub {
        my $src = $payload->{source};
        my $meta = defined $src ? encode_json({ source => "$src" }) : undef;
        return (undef, undef, $meta);
    },
    'SessionEnd' => sub { return (undef, undef, undef); },
    'Stop'       => sub { return (undef, undef, undef); },
    'Notification' => sub {
        my $msg = $payload->{message};
        return (undef, undef, undef) unless defined $msg;
        # Truncate to 200 chars — spec acceptance #4 / Technical Constraints
        $msg = substr($msg, 0, 200);
        return (undef, undef, encode_json({ message => $msg }));
    },
);

# Unrecognized event names no-op silently (forward-compat for new hook events).
exit 0 unless exists $handlers{$event_name};

my ($tool_name, $agent_type, $meta_json) = $handlers{$event_name}->();

my $session_id = $payload->{session_id} // 'unknown';
my $cwd        = $payload->{cwd} // '';
my $ts_ms      = int(time() * 1000);

# ---- DB location. Tests override via CLAUDE_TIME_DIR. ----
my $db_dir = $ENV{CLAUDE_TIME_DIR} // "$ENV{HOME}/.claude-time";
unless (-d $db_dir) {
    mkdir $db_dir or exit 0;  # bail silently if we can't create dir
}
my $db_path = "$db_dir/events.sqlite";

# ---- SQL-quote helper. Doubles single quotes per SQL standard. ----
# Returns either a quoted SQL string literal or the bare token NULL for undef.
sub sql_q {
    my $s = shift;
    return 'NULL' unless defined $s;
    $s =~ s/'/''/g;
    return "'$s'";
}

my $sid_sql  = sql_q($session_id);
my $cwd_sql  = sql_q($cwd);
my $evt_sql  = sql_q($event_name);
my $tool_sql = sql_q($tool_name);
my $type_sql = sql_q($agent_type);
my $meta_sql = sql_q($meta_json);

# ---- Schema bootstrap + INSERT in one sqlite3 subprocess. ----
# IF NOT EXISTS makes this idempotent. PRAGMA journal_mode=WAL is also idempotent
# (no-op when already WAL). .timeout protects against concurrent-write contention
# from multi-instance Claude Code (acceptance #2).
my $sql = <<"SQL";
.timeout 2000
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS events (
  ts          INTEGER NOT NULL,
  session_id  TEXT NOT NULL,
  cwd         TEXT NOT NULL,
  event       TEXT NOT NULL,
  tool_name   TEXT,
  agent_type  TEXT,
  meta        TEXT
);
CREATE INDEX IF NOT EXISTS idx_session_ts ON events(session_id, ts);
CREATE INDEX IF NOT EXISTS idx_ts ON events(ts);
INSERT INTO events (ts, session_id, cwd, event, tool_name, agent_type, meta)
VALUES ($ts_ms, $sid_sql, $cwd_sql, $evt_sql, $tool_sql, $type_sql, $meta_sql);
SQL

# Pipe to sqlite3. If sqlite3 isn't on PATH or the DB is read-only, the pipe open
# may fail or the process may exit non-zero — either way, we exit 0 to never
# block the upstream tool call.
#
# Both stdout and stderr from the sqlite3 child are silenced:
# - stdout: PRAGMA journal_mode=WAL echoes "wal" on every call (noisy)
# - stderr: read-only DB or lock contention errors are expected and load-bearing
#   information lives in row counts, not stderr
#
# Uses list-form fork+exec to avoid shell interpolation of $db_path (which comes
# from user-controlled env vars CLAUDE_TIME_DIR / HOME).
my $pid = open(my $sq, '|-');
if (defined $pid) {
    if ($pid == 0) {
        # Child: silence both streams, then exec sqlite3 with no shell.
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>', '/dev/null');
        exec('sqlite3', $db_path) or exit 0;
    }
    print $sq $sql;
    close($sq);
}

exit 0;
