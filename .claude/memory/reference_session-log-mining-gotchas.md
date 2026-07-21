---
name: session-log-mining-gotchas
description: Mining the machine-wide session-log corpus (~/.claude/projects/*/*.jsonl) — absolute-path/`--` guards + how to count real skill invocations vs system-prompt noise
metadata:
  type: reference
---

Mining the machine session-log corpus at `~/.claude/projects/<slug>/*.jsonl` (each project's harness transcript) has two non-obvious footguns, both learned the hard way during the WP6 research-collision audit (2026-07-21):

1. **Leading-`-` filenames break unguarded shell commands.** Project slug dirs start with `-` (e.g. `-Users-stayman-...`), so `grep`/`ls`/`head`/`wc` parse the path as a flag and **silently fail-empty** — looks like "no matches," is actually "broken invocation." Always use absolute paths passed after a `--` guard (`jq ... -- "$f"`), or drive with `find … -print0 | xargs -0`. This is why per-file loops using the relative `-Users-…` path returned 0 while the identical query on an absolute path worked.

2. **`product-research`/`feature-research`/`deep-research` string-greps are ~435-per-session ambient noise.** All three skill names appear together in the standard skill-listing that rides in *every* session's system prompt, so a raw `grep -l "product-research"` matches ~every session (~435), NOT invocations. **Real skill invocations must be counted from assistant `tool_use` Skill calls**, e.g.:
   `jq -rc 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Skill") | .input.command' -- "$f"`
   (note: some session files encode the skill name under a different input field than `.input.command` — the 602-log/8-invocation audit had to fall back to reading the actual `tool_use` block, not just one field.)

Both are general to any introspection of the harness log corpus from this repo. See [[project_pain_points.md]] for the kind of workflow-diagnosis work that triggers this.
