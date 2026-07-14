# Test Project (learning-assets source repo)

A sample project for workflow transition testing. This variant declares an
artifact-tracking override so global-scope learnings are committed, not parked.

## Tech Stack
- Python 3.12
- FastAPI
- PostgreSQL
- Docker Compose

## Development Conventions
- All commands must run inside Docker: `docker compose exec app <cmd>`
- Tests: `pytest`
- Linting: `ruff`

## Artifact tracking overrides

This project overrides the default artifact tracking MAP (`~/.claude/CLAUDE.md` →
`## Artifact tracking policy (GLOBAL)`). **This project IS the global
learning-assets / workflow-system source repo** — so artifacts that are throwaway
*drafts* in other projects are first-class tracked *content* here:

- **Track `<proj-dir>/.claude/learnings/`** — these are curated, durable lessons
  (the whole point of this repo), not drafts-to-port. They are committed, not
  parked. A global-scope learning written here is `git add`-ed and amended into
  HEAD, exactly as a project-scope artifact would be.

All other MAP defaults apply unchanged.
