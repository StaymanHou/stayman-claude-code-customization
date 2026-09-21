#!/usr/bin/env python3
"""render-session-transcript.py — Render prior turns of a captured session slice
into plain transcript TEXT suitable for `claude --append-system-prompt`.

This is the *instrument* half of the opus-5 F10b edge-pause investigation
(workflow-system/product/opus5-edge-pause-wbs.md, WP-A1). It exists because
context depth is the load-bearing variable in reproducing that bug class:
synthetic scenarios at ~26k context do not fail, while real failures sit at a
median ~445k tokens / ~1005 turns. Rendering a real session's prior turns back
into the model's system prompt reproduces the bug where a describe-only overlay
(the 2026-05-16 v1 attempt) did not.

WHAT THIS IS NOT
----------------
The output is *not* a byte-exact replay of what the API saw. Thinking blocks,
cache state, and the exact system prompt of the original run are not
recoverable from a session log. This renders "as close as possible" — enough
context depth and shape to put the model in the same disposition. Any
measurement built on it reports a RATE OVER N RUNS, never a single pass/fail.

REDACTION BOUNDARY (load-bearing — do not work around)
------------------------------------------------------
This tool consumes a *captured, redacted* slice produced by
`tools/capture-session-slice.sh` (13 audited Tier-1 patterns) and audited per
`tests/sessions/README.md`. It does NOT redact anything itself, by design:
duplicating redaction in two tools is how the two copies drift. Pointing
--source at a raw `~/.claude/projects/**.jsonl` is refused unless
--allow-unaudited is passed explicitly (for local throwaway probing whose
output is never committed).

TRUNCATION DEFAULTS
-------------------
  tool blocks (tool_use input, tool_result content) : 600 chars
  text blocks                                        : 3000 chars
  total budget                                       : 300,000 chars (~75k tokens)
  thinking blocks                                    : DROPPED (not recoverable)

Rationale: tool output is the bulk of a real log and is mostly noise for
disposition purposes, while assistant/human prose is what carries the
narrative cadence the bug is sensitive to — hence the 5x asymmetry. The
300k-char budget was validated empirically: a 242k-char system prompt passes
the CLI (ARG_MAX is 1MB on darwin) at ~$0.35/run on opus.

Turns are accumulated BACKWARD from --end-index so the context window ends
flush against the turn under study; the oldest turns are the ones dropped when
the budget binds.

Exit codes:
  0  — rendered successfully
  1  — argument error, missing/unreadable source, or unaudited source without
       --allow-unaudited
  2  — --end-index out of range for the source
  3  — no renderable turns in range (empty output would be a silent no-op)
"""

import argparse
import json
import os
import sys


class ArgParser(argparse.ArgumentParser):
    """argparse exits 2 on usage errors; this tool's contract says 1.

    Phase 8 of tests/check-structure.sh asserts exit 1 for the sibling
    capture-session-slice.sh on missing-arg and unknown-arg, and a two-tool
    family whose error codes disagree is a trap for any caller that checks
    them. Exit 2 is reserved here for --end-index range errors.
    """

    def error(self, message):
        self.print_usage(sys.stderr)
        sys.stderr.write("{}: error: {}\n".format(self.prog, message))
        sys.exit(1)

TOOL_CAP_DEFAULT = 600
TEXT_CAP_DEFAULT = 3000
BUDGET_DEFAULT = 300_000


def load(path):
    """Parse a .jsonl session log, skipping malformed lines.

    Session logs are append-only and can be truncated mid-write by a crash, so
    a bad final line is expected rather than exceptional.
    """
    out = []
    bad = 0
    with open(path, errors="replace") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                out.append(json.loads(line))
            except ValueError:
                bad += 1
    return out, bad


def render(recs, end_idx, budget_chars, tool_cap=TOOL_CAP_DEFAULT,
           text_cap=TEXT_CAP_DEFAULT):
    """Walk BACKWARD from end_idx accumulating turns until the budget is hit.

    Returns (text, chars_used, turns_rendered).
    """
    chunks = []
    used = 0
    for i in range(end_idx - 1, -1, -1):
        r = recs[i]
        if r.get("type") not in ("user", "assistant"):
            continue
        m = r.get("message") or {}
        role = m.get("role")
        if role not in ("user", "assistant"):
            continue
        c = m.get("content")
        blocks = c if isinstance(c, list) else [{"type": "text", "text": c}]
        parts = []
        for x in blocks:
            if not isinstance(x, dict):
                continue
            t = x.get("type")
            if t == "text":
                s = (x.get("text") or "").strip()
                if s:
                    parts.append(s[:text_cap]
                                 + ("\n…[truncated]" if len(s) > text_cap else ""))
            elif t == "tool_use":
                full = json.dumps(x.get("input") or {})
                parts.append("[tool_use: {}({}{})]".format(
                    x.get("name"), full[:tool_cap],
                    "…" if len(full) > tool_cap else ""))
            elif t == "tool_result":
                cc = x.get("content")
                s = cc if isinstance(cc, str) else json.dumps(cc)
                s = s or ""
                parts.append("[tool_result: {}{}]".format(
                    s[:tool_cap], "…" if len(s) > tool_cap else ""))
            # 'thinking' and any future block type: intentionally dropped.
        if not parts:
            continue
        label = "Human" if role == "user" else "Assistant"
        chunk = "### {}\n{}\n".format(label, "\n".join(parts))
        if used + len(chunk) > budget_chars:
            break
        chunks.append(chunk)
        used += len(chunk)
    chunks.reverse()
    return "".join(chunks), used, len(chunks)


def looks_unaudited(path):
    """True if --source points at a live harness log rather than a captured slice.

    Captured slices live in tests/sessions/ and carry an AUDIT-LOG.md signoff;
    anything under a projects/ log store has not been through Tier-1/Tier-2.
    """
    ap = os.path.abspath(path)
    return os.path.join(".claude", "projects") in ap


def main():
    ap = ArgParser(
        prog="render-session-transcript.py",
        description="Render a captured session slice into transcript text for "
                    "--append-system-prompt.",
        epilog="Consumes a REDACTED slice from tools/capture-session-slice.sh. "
               "See the module docstring for the redaction boundary and "
               "truncation rationale.")
    ap.add_argument("--source", required=True,
                    help="path to a captured slice (tests/sessions/<name>.jsonl)")
    ap.add_argument("--end-index", type=int, required=True,
                    help="RECORD index (0-based line in the .jsonl, NOT a turn "
                         "count) of the assistant turn to REPRODUCE, exclusive; "
                         "context accumulates backward from here. Logs interleave "
                         "attachment/mode/system records, so record index >> turn "
                         "count: passing a turn count silently renders far less "
                         "depth. Check the reported turn count in the output.")
    ap.add_argument("--budget-chars", type=int, default=BUDGET_DEFAULT,
                    help="total character budget (default: %(default)s)")
    ap.add_argument("--tool-cap", type=int, default=TOOL_CAP_DEFAULT,
                    help="per-block cap for tool_use/tool_result (default: %(default)s)")
    ap.add_argument("--text-cap", type=int, default=TEXT_CAP_DEFAULT,
                    help="per-block cap for text blocks (default: %(default)s)")
    ap.add_argument("--out", required=True, help="output path for rendered text")
    ap.add_argument("--allow-unaudited", action="store_true",
                    help="permit --source to be a raw harness log; for local "
                         "throwaway probing only — output must never be committed")
    a = ap.parse_args()

    if not os.path.isfile(a.source):
        sys.stderr.write("error: source not found: {}\n".format(a.source))
        return 1

    if looks_unaudited(a.source) and not a.allow_unaudited:
        sys.stderr.write(
            "error: --source looks like a raw harness log, not a captured slice:\n"
            "         {}\n"
            "       Capture it first via tools/capture-session-slice.sh (Tier-1\n"
            "       redaction + Tier-2 audit signoff), or pass --allow-unaudited\n"
            "       for local throwaway probing whose output is never committed.\n"
            .format(a.source))
        return 1

    if a.end_index < 1:
        sys.stderr.write("error: --end-index must be >= 1 (got {})\n".format(a.end_index))
        return 2

    recs, bad = load(a.source)
    if not recs:
        sys.stderr.write("error: no parseable records in {}\n".format(a.source))
        return 1
    if a.end_index > len(recs):
        sys.stderr.write(
            "error: --end-index {} out of range; source has {} records\n"
            .format(a.end_index, len(recs)))
        return 2

    body, used, n = render(recs, a.end_index, a.budget_chars,
                           tool_cap=a.tool_cap, text_cap=a.text_cap)
    if n == 0:
        sys.stderr.write(
            "error: rendered 0 turns from {} (end-index {}); refusing to write an "
            "empty transcript\n".format(a.source, a.end_index))
        return 3

    with open(a.out, "w") as fh:
        fh.write(body)

    if bad:
        sys.stderr.write("note: skipped {} malformed line(s)\n".format(bad))
    if used > a.budget_chars * 0.98:
        sys.stderr.write(
            "note: budget is binding ({:,} of {:,} chars) — oldest turns were "
            "dropped; raise --budget-chars for more depth\n"
            .format(used, a.budget_chars))
    print("rendered {} turns, {:,} chars (~{:,} tokens) -> {}"
          .format(n, used, used // 4, a.out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
