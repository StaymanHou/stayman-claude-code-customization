# Memory Index

- [feedback_git_branch_main_default.md](feedback_git_branch_main_default.md) — User wants work on main by default; never auto-create git branches unless explicitly asked
- [feedback_milestone_vs_phase_terminology.md](feedback_milestone_vs_phase_terminology.md) — "User prefers \"milestone\" over \"phase\" for roadmap units; keep feature Work Tree \"Phase\" with alias-on-read"
- [feedback_replay_harness_research_conditions.md](feedback_replay_harness_research_conditions.md) — When spiking the multi-turn session-replay harness, research/spike runs use Opus 4.7 + dot-free /tmp/claude-replay-<uuid> cwd to mirror real bug conditions rather than a cheap proxy
- [feedback_odd_shape_findings_probe_more.md](feedback_odd_shape_findings_probe_more.md) — Odd-shape verify-self/review-quality findings are a probe-more signal not a ship signal; self-apply the "this is the shape because…" test before passing an outcome, esp. in autopilot
- [project_pain_points.md](project_pain_points.md) — Three diagnosed pain points in the current workflow system, with root causes — input for upcoming skill improvements
- [project_settings_fixture_claudesk_drift.md](project_settings_fixture_claudesk_drift.md) — check-structure.sh Phase 7 drift — live settings.json carries host-specific claudesk hooks the test fixture must exclude via INTENTIONAL_DIFFS
- [project_ship_process.md](project_ship_process.md) — Standard shipping process for the my-claude-code-customization repo
- [triage-pause-decisive-users.md](triage-pause-decisive-users.md) — Workflow note — verify-codify triage pause is fast (1 message) when user has strong design opinions; friction only when user is also ambiguous
- [viz-render-marker-collision.md](viz-render-marker-collision.md) — (no description)
- [reference_session-log-mining-gotchas.md](reference_session-log-mining-gotchas.md) — Mining ~/.claude/projects/*/*.jsonl: use absolute-path/`--` guards (leading-`-` slugs break unguarded grep/ls); count real skill invocations from assistant tool_use, not raw greps (skill-listing = ~435/session noise)
