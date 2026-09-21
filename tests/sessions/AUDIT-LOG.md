# Session-Slice Audit Log

This file records human Tier-2 audit signoffs for every session log committed under `tests/sessions/`. Every `tests/sessions/*.jsonl` MUST have a matching signoff line below before it is `git add`-ed.

The audit procedure is described in `tests/sessions/README.md` (the canonical reference) and the convention is enforced by `tests/check-structure.sh`.

## Format

```
<YYYY-MM-DD> - <filename.jsonl> - audited by <name> - Tier-1 patterns matched: <N> - Tier-2 manual edits: <N>
```

## Signoffs

<!-- Entries below in chronological order (oldest first). Append new entries at the bottom. -->

2026-05-16 - 2026-05-16-autopilot-f8-pause.jsonl - audited by Stayman - Tier-1 patterns matched: 0 - Tier-2 manual edits: 0
<!-- opus5-edge-pause WP-A2 — captured 2026-09-21. Tier-1 ran clean (findings
     below); Tier-2 signoff is PENDING OPERATOR. These three slices are real
     work logs from two projects other than this repo, so the Tier-2 read is
     the actual gate — see the WP-A2 risk note in the WBS. Do NOT git add the
     .jsonl files until <your-name> replaces PENDING below. -->

2026-09-21 - 2026-09-21-opus5-f10b-stop-claudesk-a.jsonl - audited by PENDING - Tier-1 patterns matched: 1 - Tier-2 manual edits: PENDING
2026-09-21 - 2026-09-21-opus5-f10b-stop-claudesk-b.jsonl - audited by PENDING - Tier-1 patterns matched: 1 - Tier-2 manual edits: PENDING
2026-09-21 - 2026-09-21-opus5-f10b-stop-hermes-a.jsonl - audited by PENDING - Tier-1 patterns matched: 0 - Tier-2 manual edits: PENDING

### WP-A2 capture notes (agent-prepared input for the Tier-2 read)

| slice | source project | records | size | F10b stop turn | edge-pause language |
|---|---|---|---|---|---|
| `claudesk-a` | claudesk | 2193 | 3.5M | idx 2192 (terminator `4fcda261`) | **verbatim** — "Autopilot chains into verify-human, which is itself a PAUSE point — so this is where I stop" |
| `claudesk-b` | claudesk | 1063 | 2.6M | idx 1062 (terminator `3e9a6033`) | "F10b in **Autopilot** chains into `feature-verify-human` — which is itself a PAUSE point … so this is where the chain legitimately stops for you" |
| `hermes-a` | my-hermes-agent | 1866 | 2.6M | idx 1865 (terminator `056f62ca`) | "Autopilot pauses at verify-human. Everything is verified and ready for your review" |

All three hand-verified as genuine instances: model `claude-opus-5`, autopilot
active (no stepping/FSD), `TRANSITION: F10b` emitted, verify-human **never
invoked**, a hand-written human-check list written in its place. `claudesk-a`
is followed by the operator correction `invoke verify human`.

**Tier-1 finding — the FACEBOOK pattern false-positives on base64 image data.**
The 14 (claudesk-a) and 5 (claudesk-b) `[REDACTED-FACEBOOK]` substitutions are
NOT real tokens: the `EAAA…` pattern matches inside embedded base64 PNG
screenshots. Harmless (over-redaction inside image bytes, which the renderer
truncates anyway), but it means the "patterns matched" counts overstate real
secret exposure, and the redaction is corrupting image data rather than
protecting anything. Worth a backlog item against `capture-session-slice.sh`
rather than a fix inside this WP.

**Automated Tier-2 scan (agent-run, NOT a substitute for the human read).**
Scanned slice prose with base64 blobs stripped, for: emails, absolute home
paths, private URLs, IPs, bearer/token/password assignments, AWS ARNs, phone
numbers. No real secrets surfaced. Specifically:
  - "email" hits are npm package specifiers (`tauri-mcp-server@0.11.2`) and
    `noreply@anthropic.com` (the commit co-author trailer).
  - `bearer` hits are the bare English word "token", no assignment.
  - IPs are `127.0.0.1` / `0.0.0.0` only.
  - `/Users/stayman` appears 552 / 219 / 292 times — the operator's own
    username in absolute paths. Already present in the committed
    2026-05-16 slice; flagged for the Tier-2 decision, not silently kept.

**What the automated scan CANNOT judge, and why the human read is the gate:**
these are real work logs. `claudesk-a` and `claudesk-b` carry claudesk product
and UI design discussion plus 1 and 3 embedded screenshots respectively;
`hermes-a` carries a household/personal-assistant domain (household facts,
preferences, recipes) — the substantive content is the part a tool cannot
clear. Human turns per slice: 13 / 7 / 5.
