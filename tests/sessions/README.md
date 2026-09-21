# Session slices — capture and audit procedure

Real Claude Code session logs, captured as test fixtures for the long-context
replay harness. Because they are **real work logs**, every slice passes a
two-tier audit before it is committed.

This file is the canonical reference for that audit. It is cited by
`tools/capture-session-slice.sh` (step 2 of its next-steps output),
`tools/render-session-transcript.py`, and `AUDIT-LOG.md`.

> **Written 2026-09-21.** The 2026-05-16 `session-replay-harness` feature planned
> this file as deliverable `P4.1` but was abandoned at Phase 4, so it never
> existed — while four live files pointed at it as canonical. If you are reading
> a reference to a Tier-2 checklist that seems to predate this file, that is why.

## What these slices are for

The scenario harness in `tests/run-tests.sh` drives at ~26k context. Some
behavioral failures only appear at production depth (~445k tokens / ~1005
turns). A slice plus `tools/render-session-transcript.py` reconstructs that
depth so a bug that cannot appear in a synthetic scenario can be measured.

Background, defaults, and footguns:
[`docs/lessons/long-context-replay-harness.md`](../../docs/lessons/long-context-replay-harness.md).

## The two-tier model

| | Tier 1 | Tier 2 |
|---|---|---|
| **Who** | `capture-session-slice.sh` | a human |
| **What** | 13 fixed regex patterns for known secret formats | everything a regex cannot recognise |
| **Output** | `<name>.jsonl` + `<name>.redactions.diff` | manual edits + a signoff line |
| **Guarantee** | catches *known shapes* | catches *this corpus's actual content* |

**Tier 1 is necessary and not sufficient.** It knows what an AWS key looks
like. It does not know whether a session discusses an unreleased product, or
whether a custom env var holds a live token. That is the entire reason Tier 2
is a human step and not a longer regex list.

## Tier-1 patterns (13)

`sk-ant-*` · `sk-proj-*` · `sk-*` (legacy OpenAI) · `github_pat_*` · `ghp_*` ·
`AKIA*` · `sk_live_*` · `whsec_*` · `AIza*` · `SG.*.*` · `xox[abprs]-*` ·
`eyJ*.*.*` (JWT) · `(EAAA|EAACEdEose0cBA)*` (Facebook/Meta) ·
`-----BEGIN * PRIVATE KEY-----`

The pattern table lives in `tools/capture-session-slice.sh`. Each substitution
becomes `[REDACTED-<KIND>]` and is recorded line-by-line in the
`.redactions.diff` sidecar.

**Known Tier-1 defect (2026-09-21):** the Facebook pattern false-positives on
embedded base64 PNG/JPEG data. Across the five WP-A2 captures its observed
precision was **0/38** — every hit was image bytes. So a high "Tier-1 patterns
matched" count is weak evidence of real exposure, and a **0 is not evidence of
safety**. Tracked as
`SURFACE-2026-09-21-CAPTURE-SLICE-FACEBOOK-PATTERN-FALSE-POSITIVE`.

## Capture

```sh
tools/capture-session-slice.sh \
  --source ~/.claude/projects/<slug>/<session>.jsonl \
  --terminator-uuid <uuid of the last record to INCLUDE> \
  --output tests/sessions/<descriptive-name>.jsonl \
  --name <descriptive-name>
```

The terminator is **inclusive**. For a replay fixture, make the terminator the
turn you want the model to *reproduce*, so the slice contains the ground truth
and `--end-index` excludes it at render time.

Exit codes: `0` ok · `1` arg/source error · `2` terminator uuid not found in
source · `3` output already exists (refuses to clobber an audited file).

## Tier-2 audit — the checklist

Read the slice and its `.redactions.diff` side by side. Search for each
category below and edit the `.jsonl` in place. The five categories come from
`capture-session-slice.sh`'s own next-steps output; the notes are what the
2026-09-21 audit learned.

### 1. Internal or proprietary endpoint URLs
Real hostnames for internal services, staging, or anything shaped like a
private API. Public documentation and vendor URLs are fine.

### 2. Project content revealing proprietary logic
Unreleased product detail, business rules, credentials-adjacent config,
customer data. **This is the category a tool cannot help with** — it needs
someone who knows what is and is not shareable.

### 3. Non-obvious-secret-shaped strings
Custom token formats Tier 1 does not know. **Scan for `NAME=<value>`
assignments**, and unescape JSON string escapes first (`\n`, `\"`) — an env
dump inside a `tool_result` is one long JSON line, so a line-oriented grep
walks straight past it.

> **Worked example — the 2026-09-21 catch.** `stop-claudesk-b` contained
> `CLAUDE_CODE_MESSAGING_TOKEN=be1f…` (32 hex, live). **No Tier-1 pattern
> covers it**, its Tier-1 count was 5 (all base64 false positives), and the
> first scan that found it was looking for exactly this shape. Redacted to
> `[REDACTED-CLAUDE_CODE_MESSAGING_TOKEN]`, 2 occurrences.
>
> Two lessons from that catch, both about counting:
> - **`grep -c` counts LINES, not occurrences.** It reported 1; there were 2.
>   Count with `s.count(tok)` and assert the expected number before and after.
> - **Distinguish placeholders from live values.** The same sweep flagged
>   `DISCORD_HOME_CHANNEL=123456789012345678` — sequential digits, obviously a
>   placeholder, correctly left alone. Redacting placeholders trains the next
>   reader to ignore the diff.

### 4. OS paths revealing identity beyond `/Users/stayman`
Other usernames, other machines' home directories. `/Users/stayman` itself is
already present in committed slices; a *different* person's path is not.

### 5. Third-party content
Names of clients or employers, quoted conversation from unrelated projects,
anything belonging to someone who did not consent to it being a test fixture.

## Signoff

Append one line per slice to `AUDIT-LOG.md`:

```
<YYYY-MM-DD> - <filename.jsonl> - audited by <name> - Tier-1 patterns matched: <N> - Tier-2 manual edits: <N>
```

Then, and **only** then, stage the files:

```sh
git add tests/sessions/<name>.jsonl tests/sessions/<name>.redactions.diff tests/sessions/AUDIT-LOG.md
```

Report `Tier-2 manual edits: 0` when the read genuinely found nothing — that is
a real and common outcome. Do not leave the field as `PENDING`; an unresolved
placeholder is indistinguishable from an audit that was never done.

## After editing a slice

Three things to re-check, because a hand edit to a 3MB JSONL file is easy to
get wrong:

```sh
# 1. every line still parses
python3 -c "import json,sys; [json.loads(l) for l in open(sys.argv[1]) if l.strip()]" <slice>

# 2. the secret is actually gone (count, don't grep -c)
python3 -c "import sys; print(open(sys.argv[1]).read().count('<value>'))" <slice>

# 3. it still renders
tools/render-session-transcript.py --source <slice> --end-index <N> --out /tmp/x.txt
```

A corrupted slice fails loudly at render time, but a slice that renders a
*different* turn count than before is the quiet failure — compare against the
count you recorded when you captured it.
