---
name: reference_claude-code-permission-modes
description: "Claude Code permission modes (default/acceptEdits/plan/auto/dontAsk/bypassPermissions) — for guided/onboarding flows recommend AUTO (classifier-gated, low-friction AND safe), NOT acceptEdits (prompts on every shell cmd) or bypass (no guardrails)"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 1b0ffc22-6820-40ef-94bd-212bd88ee0d9
  modified: 2026-07-22T17:49:19.799Z
---

Claude Code has **six** permission modes (full docs: https://code.claude.com/docs/en/permission-modes.md). What each auto-approves without a prompt:

| Mode | Runs without asking | Launch |
|---|---|---|
| `default` (aka **Manual**) | reads only | `claude` |
| `acceptEdits` | reads + file edits + a safe fs-cmd set (`mkdir`/`touch`/`rm`/`mv`/`cp`/`sed`); **still prompts for arbitrary shell + network** | `claude --permission-mode acceptEdits` / Shift+Tab |
| `plan` | reads only (proposes, doesn't edit) | `claude --permission-mode plan` / Shift+Tab |
| **`auto`** | **everything, with a classifier reviewing each action** and blocking escalations (curl\|bash, force-push, prod deploy, mass delete, secret exfil, `git reset --hard`, `rm -rf` of unnamed targets, …) | `claude --permission-mode auto`, or `defaultMode:"auto"` in `~/.claude/settings.json` (ignored from project settings), or Shift+Tab if available |
| `dontAsk` | only pre-approved (`allow`-rule) tools; auto-denies everything else | `claude --permission-mode dontAsk` |
| `bypassPermissions` | **everything, zero checks** (only `rm -rf /`/`~` circuit-breaker) | `claude --permission-mode bypassPermissions` / `--dangerously-skip-permissions` |

**For a low-friction-but-safe guided / onboarding flow, recommend `auto`** — it eliminates the routine-prompt fatigue (so a tour that runs `greet.sh` etc. doesn't prompt on every shell command, which `acceptEdits` DOES) while a classifier keeps the "stays safe/local, nothing pushed or published" reassurance *honestly true*. Contrast the two wrong choices: **`acceptEdits`** still prompts on every shell/network call (kills tour flow); **`bypassPermissions`** has no guardrails at all (unsafe, and the safety reassurance would be false). Caveat the tour copy MUST include: **auto mode requires Opus 4.6+/Sonnet 4.6+/Fable 5 and an account/provider that allows it** — so say "if auto mode is available" and give the `claude --permission-mode auto` launch command.

**History (operator correction 2026-07-22, WP7g):** the M11 `onboarding-brainstorm.md` originally said "auto-accept / bypass-permissions" (conflated); WP7a "corrected" that to **`acceptEdits`** in [[../../workflow-system/product/onboarding-flow-spec.md]] §5b — but the operator **never endorsed acceptEdits** (it was a prior-session inference), and during the live tour walkthrough flagged that it gives too little permission (prompts on every step). Operator ruling: **use `auto`**. So the acceptEdits recommendation is SUPERSEDED — WP7g rewrites the dispatcher Step 1 + spec §5b to recommend auto (with the availability caveat + launch command). Applies whenever a skill or doc in this repo recommends a permission mode.

Ref: https://code.claude.com/docs/en/permission-modes.md
