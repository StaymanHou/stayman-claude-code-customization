# Backlog

> **Reading order:** Items in the **TODO** section below carry an `**Order:**` line (P1, P2, …) reflecting the priority sequence confirmed by Stayman on 2026-06-11. Address them in that order — `**Order:**` is the user-confirmed pickup sequence; the `**Priority:**` line beneath it preserves the original triage-time priority for context. Items in the **MAYBE** section are parked — revisit after the TODO list is drained. Buried items live in `workflow/backlog-deferred-2026-05.md` (full content) and `CHANGELOG.md` (resolved items, per project convention). **Code-quality findings** auto-backlogged by `feature-review-quality` are pointer-collapsed here — full content lives in `workflow/backlog-quality-findings.md`, grouped by source feature.

---

## TODO

## Code-quality findings — claude-md-compaction (2026-06-13)
- **Pointer:** 4 MINOR findings auto-backlogged by feature-review-quality against ship commit a96384a — heading drift on util-* skill `## Category` vs precedent `## Category Context`, lesson-file schema ambiguity (9 files / 3 heading shapes), redundant inline HTML comment in arch.md, and a placement-detail addendum for the YAML-parse-pin SURFACE. Full content in [`workflow/backlog-quality-findings.md`](backlog-quality-findings.md).
- **Order:** P3
- **Priority:** low (all)
- **Status:** pending
- **Pickup shape:** small task — each finding is a 1-line edit; bundle into a single `/task-plan` invocation when picked up.

## SURFACE-2026-06-13-CHECK-STRUCTURE-MISSING-YAML-PARSE-PIN
- **Source:** feature:build (claude-md-compaction Phase 4 verify-auto)
- **Order:** P1
- **Target level:** product:wbs (small task — likely a single check-structure.sh phase addition)
- **Type:** gap
- **Summary:** `tests/check-structure.sh` does not validate that every SKILL.md / AGENTS.md frontmatter is parseable YAML. An invalid `argument-hint:` value (unquoted inner-colon string) in `skills/util-prune-claude-md/SKILL.md` slipped through the structural sweep (PASS 251/0) and would have broken the harness's skill registry at next session load. Caught manually by `python3 yaml.safe_load` during verify-auto, fixed in-line.
- **Context:** Skill frontmatter is the harness's contract surface — an invalid frontmatter renders the skill non-invokable, but the failure mode is silent until the next session start. Mechanically pin-able: iterate `skills/*/SKILL.md` + `agents/*/AGENTS.md`, extract frontmatter (between `---` markers), pipe through `python3 -c "import sys, yaml; yaml.safe_load(sys.stdin.read())"`, fail the structural check on any non-zero exit.
- **Suggested action:** Add a new Phase to `tests/check-structure.sh` ("[Phase N] Frontmatter YAML parseability") that runs the above check across all SKILL.md and AGENTS.md files. Estimated 10-line addition.
- **Priority:** medium (silent failure mode + low fix cost)
- **Status:** open

## SURFACE-2026-06-16-ODD-SHAPE-FINDINGS-PROBE-MORE-HEURISTIC
- **Source:** cross-project learning (claudesk WP2 PTY probe), captured at `.claude/learnings/2026-06-16-odd-shape-findings-deserve-one-more-cycle.md`
- **Order:** P4
- **Target level:** product:wbs (judgment-shaped — either a CLAUDE.md memory addition or a verify-self-runner prompt enhancement; sizing TBD at pickup)
- **Type:** gap (autopilot quality gate)
- **Summary:** When a verify-self / review-quality finding has a shape that diverges from the standard idiom for that class of system (e.g., "TUI requires Ctrl+D twice to exit" when `/exit + Enter` is the norm), the divergence is a signal to invest one more curiosity cycle before shipping. In autopilot modes (Mode 3, Mode 4) the objective gates can't catch this — the operator's gut-check fires post-finalize when the ship commit + CHANGELOG entry already exist. Real instance: claudesk WP2 originally accepted "Ctrl+D twice exits" as the observed behavior; operator probed further and discovered the load-bearing root cause was raw-mode CR-vs-LF (`\r` is Enter, not `\n`) — a finding that would have made WP7's `send_slash_command` silently broken.
- **Context:** Two candidate landing surfaces — (a) **CLAUDE.md memory addition**: add the "odd-shape findings are a probe-more signal" heuristic as a global feedback-style rule the agent reads at session start; (b) **verify-self-runner prompt enhancement**: have the subagent ask itself "is this the shape you'd expect from a system of this class?" before reporting PASS, and surface any hedge as a `severity: COSMETIC` note into the verify-human checklist. The heuristic is judgment-shaped (definition of "odd" is not codifiable), so a hard gate is out — the pickup is choosing between memory-only vs. prompt-augmentation vs. both.
- **Suggested action:** Read the full learning at `.claude/learnings/2026-06-16-odd-shape-findings-deserve-one-more-cycle.md`. Decide between (a)/(b)/(a+b) at pickup time; implement under `/task-plan` if memory-only, `/feature-plan` if it touches `agents/feature-verify-self-runner/AGENTS.md`.
- **Priority:** medium (autopilot quality gate; cost of miss is silently-shipped misdiagnosis)
- **Status:** open

## SURFACE-2026-06-16-TELEGRAM-NOTIFY-FIRES-ON-BACKGROUND-AUTOBACKGROUND
- **Source:** operator observation (2026-06-16)
- **Order:** P5
- **Target level:** task:plan (likely a `hooks/notify-telegram.sh` filter — single file edit)
- **Type:** regression (after recent Claude Code harness update)
- **Summary:** Since a recent Claude Code update, the agent now auto-backgrounds long-running commands and returns control to the user immediately. The harness fires a `Notification` (or `Stop`) event at that handoff point, which `hooks/notify-telegram.sh` translates into a Telegram ping. That defeats the purpose of the notification (which is meant to fire when the operator's attention is actually required) — auto-background is exactly the case where attention is NOT required.
- **Context:** `hooks/notify-telegram.sh` currently sends on every `Notification` and `Stop` event without inspecting payload semantics. The auto-background case appears to surface as one of these events; the fix likely involves inspecting the event payload (`message_field`, or a new `reason`/`subtype` field if the harness emits one) and skipping the Telegram send when the trigger is "command auto-backgrounded, control returned" rather than "blocked, awaiting input". Need to first capture a sample payload from a real auto-background event to identify the discriminator field, then add a `case` filter in the `Notification`/`Stop` branches.
- **Suggested action:** (1) Trigger an auto-background scenario and log the raw stdin payload the hook receives (temporarily add `printf '%s' "$payload" >> /tmp/telegram-hook-debug.log` near the top of the script). (2) Identify the discriminator field. (3) Add a filter — skip the curl POST when the event is auto-background. (4) Remove the debug log line.
- **Priority:** medium (notification fatigue erodes the signal; user-reported)
- **Status:** open

## SURFACE-2026-06-18-PRODUCT-SKILLS-MILESTONE-TERMINOLOGY-AND-WBS-SCOPE
- **Source:** repo-owner learning captured during AlphaFun product-workflow run (turn-based-ai-test-proto-1), 2026-06-18
- **Order:** P5
- **Target level:** feature (touches `product-roadmap` + `product-wbs` SKILL.md prose, possibly `transitions.md` and global `~/.claude/CLAUDE.md`)
- **Type:** enhancement (durable terminology + scoping preferences for the product workflow)
- **Summary:** Three coherent corrections to the product workflow skills: (1) roadmap should use **"milestone"** not "phase" as its primary decomposition unit, with "phase" kept as a read-time alias and the feature Work Tree's "Phase" schema left intact; (2) `product-roadmap` should emit **flat singly-numbered milestones** with "Group" headings used only for cosmetic clustering (no dotted hierarchical numbering); (3) `product-wbs` should decompose **only the immediate next milestone**, not the whole roadmap — future milestones stay tracked in roadmap.md and are decomposed just-in-time on milestone completion.
- **Context:** Full draft (with How-to-apply detail per rule and a curation note on the Rule 1 backward-compat boundary) copied verbatim to [`docs/lessons/product-skills-milestone-terminology-and-wbs-scope.md`](../docs/lessons/product-skills-milestone-terminology-and-wbs-scope.md). The only real decision is whether to rename "Phase" in the feature Work Tree too or keep that load-bearing global schema as-is (recommendation in the doc: keep it, switch only the roadmap, alias-on-read).
- **Suggested action:** Curate the draft into `product-roadmap`/`product-wbs` SKILL.md edits (and decide on the global Work Tree boundary) via a small feature or task.
- **Priority:** medium
- **Status:** resolved 2026-06-18 by feature `milestone-terminology-and-wbs-scope` (commit ab5f7a2). All 3 rules applied across 9 product-workflow files + transitions.md tripartite-sync; feature Work Tree "Phase" kept with disambiguation note; +13 structural pins.

## MAYBE

_(empty — both prior MAYBE items promoted to TODO 2026-06-12; SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE buried same day)_

---

## Buried

The following items were buried by user decision. Full content preserved in [`workflow/backlog-deferred-2026-05.md`](backlog-deferred-2026-05.md).

Buried 2026-06-07:
- `SURFACE-2026-05-29-BULK-DELETE-MISSED-HELPER-IN-CLUSTER` — bulk-delete safety pattern (CLAUDE.md convention proposal).
- `SURFACE-2026-05-29-ALIAS-KEY-AUDIT-METHOD-MISSES-DESTRUCTURING` — audit-method gap; destructuring patterns require their own grep.
- `SURFACE-2026-05-29-WP3-PLAN-DOWNSTREAM-CONTRACT-MISS` — codify plan-time downstream-contract grep into `feature-plan` SKILL.md.
- `SURFACE-2026-05-24-WBS-EXCEEDS-300-LINE-SIZE-GUARD` — `docs/product/wbs.md` exceeds 300-line size guard.
- `SURFACE-2026-05-23-CLAUDE-TIME-DB-FLAG-OVERRIDES-CLAUDE-TIME-DIR-FOR-CONFIG` — `--db` silently overrides `$CLAUDE_TIME_DIR` for config lookup.
- `SURFACE-2026-05-22-VIZ-DATA-SESSION-ID-TRUNCATION-CAN-COLLIDE` — `session_id[:8]` truncation can collide in synthetic test data.
- `SURFACE-2026-05-22-PLAYWRIGHT-SYNTHETIC-WHEEL-DOESNT-REACH-REACT` — synthetic `WheelEvent` dispatch doesn't reach React's `onWheel`.
- `SURFACE-2026-05-13-FRONTMATTER-NAME-VS-DIR-DRIFT` — structural check missing; frontmatter `name:` vs. parent dir.

Buried 2026-06-12:
- `SURFACE-2026-06-02-BEHAVIORAL-PRESSURE-TESTS-FOR-SKILL-LANGUAGE` — borrow obra/superpowers' behavioral pressure tests for skill rationalization-resistance.

