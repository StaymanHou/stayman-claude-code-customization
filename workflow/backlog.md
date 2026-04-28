
## SURFACE-2026-04-27
- **Source:** feature:build (Phase 7 — test fixture work)
- **Target level:** product:wbs
- **Type:** tech-debt
- **Summary:** Default test budget $0.05 is too low — tests fail with "No output" due to budget exceeded
- **Context:** Adding the Work Tree Format section to CLAUDE.snippet.md increased global context size. All tests now cost ~$0.05–0.08 per run on haiku. The $0.05 default causes silent failures that look like runner errors.
- **Suggested action:** Bump default MAX_BUDGET in run-tests.sh to $0.10, or add a note in CLAUDE.md about using --budget 0.10
- **Priority:** medium
- **Status:** pending
