# docs/lessons/ — curated project lessons

Durable, curated lessons extracted from real sessions — the transferable "how we do it here" knowledge that outlives any one feature. Referenced from the project-root `CLAUDE.md` bullets and from skill/agent prose.

## Schema

**There is no strict schema.** Each lesson file is: an `# h1` title + topical `##`/`###` sections, no YAML frontmatter. Section headings are chosen to fit the lesson's content (e.g. `## Practical application`, `## Mechanical recipe`, `## 1. …`) — the shape follows the material, not a fixed template. A reader should be able to open any file and understand it standalone.

## Distinct from `.claude/learnings/`

`docs/lessons/` holds **curated, tracked project lessons** (first-class content in this repo). `<proj-dir>/.claude/learnings/` holds global-scope learning *drafts* parked for hand-porting — in this repo those are tracked first-class too (see the root `CLAUDE.md` → "Artifact tracking overrides"), but the two directories serve different roles: lessons are the polished, project-scoped record; learnings are the raw/global-scoped drafts.
