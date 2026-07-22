---
name: reference_claude-code-permission-modes
description: Claude Code acceptEdits vs bypassPermissions are DISTINCT modes — acceptEdits still gates shell/network; recommend it (not bypass) for guided/onboarding flows
metadata:
  type: reference
---

Claude Code's **`acceptEdits`** and **`bypassPermissions`** are **two distinct permission modes** — do NOT conflate them:

- **`acceptEdits`** — auto-accepts file *edits* + a safe filesystem-command set (`mkdir`/`touch`/`rm`/`mv`/`cp`/`sed`), but **still prompts for arbitrary shell commands and network calls**. Work stays gated at the risky boundary.
- **`bypassPermissions`** — skips **all** permission checks (only hard circuit-breakers like `rm -rf /` and `rm -rf ~` remain). Meant for isolated containers/VMs.

**For a low-friction-but-safe guided / onboarding flow, recommend `acceptEdits` (via Shift+Tab), NOT `bypassPermissions`.** The "all work stays local / nothing pushed or published" reassurance is only *honestly true* under `acceptEdits` — `bypassPermissions` would let unattended shell/network run, so the reassurance would be false advertising. Toggle: **Shift+Tab cycles modes**.

Applies whenever a skill or doc in this repo recommends a permission mode. First surfaced in the M11 onboarding work: the `onboarding-brainstorm.md` phrasing "auto-accept / bypass-permissions" conflated the two; corrected in [[../../workflow-system/product/onboarding-flow-spec.md]] §5b (WP7a, 2026-07-22). WP7b (the `workflow-tour` entry skill) will re-touch this when it authors the actual opening copy.

Ref: https://code.claude.com/docs/en/permission-modes.md
