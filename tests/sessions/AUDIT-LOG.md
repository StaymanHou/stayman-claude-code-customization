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