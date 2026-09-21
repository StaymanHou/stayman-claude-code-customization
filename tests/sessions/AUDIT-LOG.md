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

**CORRECTION (same session).** An earlier version of this note reported "2
`REDACTED-AT-REST`" substitutions in `hermes-a`. That was a measurement error
of mine, not a tool finding: a `grep -o 'REDACTED-[A-Z-]*'` matched the
substring inside the *literal backlog title*
`SURFACE-2026-07-28-USER-PROMPTS-STORED-UN`**`REDACTED-AT-REST`** quoted in the
captured session. `AT-REST` is not one of the 13 Tier-1 kinds. Real
substitutions carry brackets (`[REDACTED-<KIND>]`); verified counts are
**claudesk-a 14, claudesk-b 5, hermes-a 0, claudesk-c 4, hermes-b 15**, all
`FACEBOOK_TOKEN` and all inside base64 image data. `hermes-a` has **no real
redactions at all**.

**What the automated scan CANNOT judge, and why the human read is the gate:**
these are real work logs. `claudesk-a` and `claudesk-b` carry claudesk product
and UI design discussion plus 1 and 3 embedded screenshots respectively;
`hermes-a` carries a household/personal-assistant domain (household facts,
preferences, recipes) — the substantive content is the part a tool cannot
clear. Human turns per slice: 13 / 7 / 5.

<!-- opus5-edge-pause WP-A2, part 2 — NEGATIVE CONTROLS, captured 2026-09-21.
     Same PENDING-operator Tier-2 gate as the three stop slices above. -->

2026-09-21 - 2026-09-21-opus5-f10b-chained-claudesk-c.jsonl - audited by PENDING - Tier-1 patterns matched: 4 - Tier-2 manual edits: PENDING
2026-09-21 - 2026-09-21-opus5-f10b-chained-hermes-b.jsonl - audited by PENDING - Tier-1 patterns matched: 15 - Tier-2 manual edits: PENDING

### WP-A2 negative controls — why these two

WP-A2 requires ≥2 **chained** (non-failing) F10b turns. Without them WP-A3
cannot distinguish "the harness reproduces the bug" from "the harness makes the
model stop regardless of context" — a replay surface that stops on every slice
measures the harness, not the model.

| slice | project | records | F10b turn | outcome |
|---|---|---|---|---|
| `chained-claudesk-c` | claudesk | 1903 | idx 1902 (term. `2a5fc686`) | `Skill(feature-verify-human)` invoked on the **next turn** |
| `chained-hermes-b` | my-hermes-agent | 2034 | idx 2033 (term. `2dbcb326`) | same, with args passed |

Both hand-verified: `claude-opus-5`, autopilot active (0 stepping), depth
comparable to the stop slices (1902 and 2033 vs 2192 / 1062 / 1865), and
**no human turn between the F10b emission and the invocation** — the chain was
autonomous, not operator-pushed. That last check is what makes them controls
rather than just "sessions that eventually reached verify-human."

**`chained-hermes-b` is the minimal contrast pair, and is the most valuable
slice in the set.** It emits the same opening clause as the failures —

> "Autopilot chains into verify-human, **which evaluates its own auto-skip
> gate**." → invokes the skill

versus `stop-claudesk-a`:

> "Autopilot chains into verify-human, **which is itself a PAUSE point — so
> this is where I stop**." → writes the checklist by hand, invokes nothing

Same premise, opposite completion. The divergence is in what the model believes
verify-human's pause *means* — whether the pause belongs to the state (enter it,
let it decide) or to the edge into it (stop before entering). Any mitigation
measured in WP-B1 should move `stop-*` behaviour toward `chained-*` behaviour
without suppressing the pause itself.

**Detector note (method, not a finding).** A first pass reported only 1 chained
turn at depth, which contradicted the measured 8.2% stop rate and was a defect
in my detector, not a property of the logs: it searched for "verify-human" in
tool-input blobs and missed the ordinary `Skill` invocation shape. Corrected
count is **265** autonomous chained turns. Both errors so far have inflated the
apparent failure rate — treat any rate this detector produces as unverified
until hand-checked.

### Tier-2 pre-scan findings (agent-run, 2026-09-21) — ONE REAL SECRET FOUND AND REDACTED

Scanned all five slices against the five Tier-2 categories in
`tests/sessions/README.md`. **One genuine secret, in `stop-claudesk-b`:**

```
CLAUDE_CODE_MESSAGING_TOKEN=be1f…  (32 hex, live value, 2 occurrences)
```

**No Tier-1 pattern covers this shape.** That slice's Tier-1 count was 5 — all
base64 false positives — so Tier-1 gave no signal at all on the one real
exposure in the corpus. Redacted in place to
`[REDACTED-CLAUDE_CODE_MESSAGING_TOKEN]`; slice re-verified as 1063/1063
parseable lines and rendering an unchanged 594 turns / 262,632 chars.

This is the concrete argument for Tier-2 being a human gate rather than a
longer regex list, and it is now the worked example in README.md §3.

**Correctly left alone:** `DISCORD_HOME_CHANNEL=123456789012345678` in
`stop-hermes-a` — sequential digits, a placeholder. Redacting placeholders
would train the next reader to skim the diff.

**Counting caveat that nearly hid it:** `grep -c` reported **1** occurrence of
the token; there were **2**. grep counts matching *lines*, and both occurrences
sat on one long JSON line. The redaction asserted an expected count before and
after, which is what surfaced the discrepancy. Any future audit should count
occurrences, not lines.

**Verified Tier-1 substitution counts** (bracketed placeholders only —
the earlier `AT-REST` figure was a grep artifact, see the CORRECTION above):

| slice | Tier-1 real | all `FACEBOOK_TOKEN` in base64? | Tier-2 edits |
|---|---|---|---|
| `stop-claudesk-a` | 14 | yes | 0 |
| `stop-claudesk-b` | 5 | yes | **2** (the token) |
| `stop-hermes-a` | 0 | — (no screenshots) | 0 |
| `chained-claudesk-c` | 4 | yes | 0 |
| `chained-hermes-b` | 15 | yes | 0 |

**What remains PENDING and is not delegable.** The pre-scan covers categories
1, 3, 4 mechanically and found nothing else. **Category 2 (proprietary
content) and category 5 (third-party content) still need your read** — these
are claudesk product/UI work and hermes household/personal-assistant domain,
and no scan can judge whether that content is shareable as a committed test
fixture. Human turns per slice: 13 / 7 / 5 / (claudesk-c) / (hermes-b).
