# Handoff — `install.sh` still installs the deprecated `claude-time` tool

**From:** the **Claudesk** project (`/Users/stayman/Personal/projects/claudesk`)
**To:** this repo — **`my-claude-code-customization`** (the custom CC workflow system)
**Date:** 2026-07-29
**Author:** a Claudesk M10.9 WP3.5 planning session (operator: Stayman)

**Scope:** ONE actionable item. This is a small, surgical ask — not a five-item batch like [`HANDOFF-from-claudesk-2026-07-20.md`](HANDOFF-from-claudesk-2026-07-20.md).

**Blocking:** yes, mildly. Claudesk's M10.9 **WP3.5a** (install wizard) is paused on this. See §"Why this blocks Claudesk" — the operator's decision was to fix it here rather than paper over it in Claudesk's consent copy.

---

## The ask, in one paragraph

`install.sh` symlinks the **`tools/claude-time/`** tool into the user's `~/.claude/`:

```bash
link_artifact "$CLAUDE_TIME_DIR/hook.pl"     "$TARGET_DIR/hooks/claude-time-hook.pl"  "hooks/claude-time-hook.pl"
link_artifact "$CLAUDE_TIME_DIR/claude-time" "$TARGET_DIR/bin/claude-time"            "bin/claude-time"
```

**Claudesk deprecated that tool on 2026-07-16** (its Milestone 9 absorbed the whole capability natively). So a fresh `install.sh` run installs a **redundant second time-tracker** — including a **second time-tracking hook** registered in the user's `~/.claude/hooks/`. Please **drop the `claude-time` linking from `install.sh`** (or gate it behind an explicit opt-in flag), and decide what happens to `tools/claude-time/` itself.

---

## Background — what Claudesk's M9 actually did

Claudesk **Milestone 9 (Time-analytics panel — absorb `claude-time`)** completed and closed 2026-07-16. It did not wrap or shell out to `claude-time`; it **re-derived the capability natively**:

| Concern | Was (`claude-time`) | Now (Claudesk, native) |
|---|---|---|
| Event capture | `tools/claude-time/hook.pl` | Claudesk's own `claudesk-hook.pl` (10 CC lifecycle events) |
| Store | claude-time's own store | per-identity `time-analytics.sqlite`, write-gated OFF by default |
| Classification | `reclassify.py` (inferred human states from hook-stream gaps) | Rust `reclassify` module — **measures** human states from Claudesk's native focus/keystroke signals |
| Presentation | `viz_*.py` | in-app dark dashboard tab (day/week/month/metrics/compare) |

Claudesk's WP7 closer verified **zero runtime dependency** on `claude-time-hook.pl` and recorded the tool as deprecated in its `arch.md`.

**Why nothing was deleted from *this* repo at the time.** Claudesk's WP7 was deliberately **docs-only**, and its recorded posture was **"stop depending, do NOT delete."** That was the right call for the *user's machine* — Claudesk's `hook_install` additively merges its hook and **deliberately preserves** a co-resident `claude-time` hook rather than removing it (pinned by its `merge_is_additive_and_preserves_existing_hooks` test). Claudesk should not delete a hook it did not install.

But that posture was about **not removing what's already there.** It never addressed **`install.sh` continuing to newly install it** — which is this repo's call, not Claudesk's. Hence this note.

## Current state in this repo (as observed 2026-07-29)

- `tools/claude-time/` is fully present: `hook.pl`, the `claude-time` CLI, `reclassify.py`, `viz_data.py`, `viz_render.py`, `README.md`, `docs/`, `test/`.
- **No deprecation notice anywhere in it** — not in the README, not in a header comment. A reader of this repo has no way to know it was superseded.
- `install.sh` links it unconditionally (guarded only by `if [ -d "$CLAUDE_TIME_DIR" ]`).
- `uninstall.sh` **correctly removes both symlinks** — it mirrors install. **The back-out path is already clean; the problem is only on the way in.**

## Why this blocks Claudesk

Claudesk M10.9 WP3.5a is building an **install wizard**: Claudesk itself clones this repo and runs `./install.sh` for a user who opts into the workflow layer. The wizard shows a **consent screen naming every side effect** before it runs anything (the symlinks, the `~/.claude/CLAUDE.md` marker block + its `.bak`, the printed-not-applied `permissions.allow` entries).

That consent screen would have to say, in effect:

> …and installs `claude-time`, a time-tracking tool that duplicates Claudesk's own built-in time analytics and registers a second tracking hook. You probably don't want it.

The operator's decision (2026-07-29) was that **Claudesk should not ship an install wizard that knowingly installs dead weight and then apologizes for it in the copy.** Fixing it at the source is one edit here versus a permanent paragraph of explanation in Claudesk's UI — and every non-Claudesk user running `install.sh` by hand benefits too.

## Suggested resolution (your call)

Roughly in order of preference, but the shape is yours:

1. **Drop the `claude-time` block from `install.sh`.** Smallest change; the tool stays in the repo for anyone who wants it manually. If you take this, consider also adding a short deprecation header to `tools/claude-time/README.md` explaining that Claudesk absorbed it — otherwise the next reader re-discovers this puzzle.
2. **Gate it behind an opt-in** — e.g. `./install.sh --with-claude-time`, default off. Right if you still use the standalone CLI on machines without Claudesk.
3. **Retire `tools/claude-time/` from this repo entirely** (git history keeps it). Cleanest end state, biggest step — and only correct if you're confident nothing else depends on it. Note `install.sh`'s `link_artifact` helper and the `CLAUDE_TIME_DIR` block would go with it.

**Please also consider** whether `uninstall.sh` should keep removing the two claude-time symlinks after the change. Claudesk's read is **yes, keep it** — it cleans up installs made by *earlier* versions of `install.sh`, and its into-repo-only guard means it can only ever remove links that point back here. Removing that cleanup would strand old installs.

## What Claudesk does once you've settled it

Claudesk re-reads `install.sh` and finalizes WP3.5a's consent copy against whatever it actually does. **No Claudesk code depends on the outcome** — the wizard runs the script and surfaces its real output rather than re-implementing its logic, so this only affects the disclosure text. If you choose (2) the gated flag, Claudesk will simply not pass the flag.

**Ping the operator when this lands** and Claudesk's WP3.5a resumes from its spec step.

---

## Reference — where this is recorded on Claudesk's side

- `workflow-system/product/wbs.md` → **WP3.5** → "⚠️ Script findings" → **finding 1b** (the full analysis)
- `workflow-system/product/wbs.md` → **WP3.5a** → task **3.5.4c** (the blocked decision)
- Claudesk's M9 record: `workflow-system/product/arch.md` → "Milestone 9 architecture"; `workflow-system/product/archive/milestone-9-time-analytics/wbs.md` → WP7
