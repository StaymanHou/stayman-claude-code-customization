---
date: 2026-05-29
scope: global
type: Context Rule
session-ref: incident-email-ads-zero-in-daily-report — codify step
---

# Estimate runtime + serialize: long-running commands against exclusive resources

## Summary

When running a long command — full test suite (`pytest`, `npm test`, `cargo test`,
`go test ./...`, `bundle exec rspec`, `mix test`, Playwright, etc.), full build
(`npm run build`, `cargo build --release`, webpack/Vite production build), big
migration, large codemod, bulk data import — the default 2-minute Bash timeout
is often insufficient. The harness auto-backgrounds the command and surfaces a
task ID, which can mislead Claude into re-invoking the same command in the
foreground. That produces two concurrent processes. If both processes contend
on a shared exclusive resource, the second run is the hazard.

"Exclusive resource" is broader than just a database. Any of these qualify:
- Single shared dev/test DB (`*_test` database, single SQLite file, shared schema).
- Single shared cache or artifact directory (`node_modules/.cache`, `target/`,
  `dist/`, `.next/`, Bazel/Turbo cache).
- Port-bound process (dev server, test runner with a fixed port).
- Lock file (Cargo, Bundler, `package-lock.json` write, git index lock).
- Single-writer file/object (S3 prefix upload, fixture-generating script).

The first run usually finishes fine; the second is the one that races on schema
setup/teardown, cache invalidation, lock acquisition, or fixture lifecycle.

## Suggested change

CLAUDE.md rule (global), under "Using your tools" or a new "Long-running commands" section:

> **Before running long commands, estimate runtime and set the Bash `timeout`
> explicitly.** This applies to any full test suite, full build, big migration,
> or bulk operation — not just one ecosystem. For test suites, query the test
> count (`pytest --collect-only -q | tail -3`, `npx jest --listTests | wc -l`,
> `cargo test -- --list 2>/dev/null | tail -1`, etc.) or read the project
> CLAUDE.md for prior runtime data; set `timeout` = `expected * 1.5 + buffer`.
> The default 2-min timeout silently auto-backgrounds, which produces a stale
> tool result that looks like a failure.
>
> **Never start a second instance of a long-running command against a shared
> exclusive resource.** "Exclusive resource" includes: shared dev/test DB,
> shared cache or artifact dir, port-bound process, lock file, single-writer
> file/object. If a command is auto-backgrounded, wait for its completion
> notification (`BashOutput` / `<task-notification>` with
> `<status>completed</status>`) — do not re-invoke. Two concurrent suites
> against the same backing store will race on setup/teardown and produce flaky
> or destructive failures (concrete example: pytest's
> `Base.metadata.create_all` / `drop_all` against a shared `*_test` database;
> equivalent failure modes exist for `cargo test`'s `target/` lock,
> `npm test`'s port-bound runner, etc.).
>
> **When uncertain about runtime**, run a small subset first to verify health
> and gather a per-test time estimate before committing to the full suite —
> the exact subset command depends on the runner (e.g., `pytest
> tests/integration/<module>/`, `npx jest <path>`, `cargo test <module>::`,
> `go test ./pkg/...`).

## Session-log excerpt (concrete instance — pytest near-miss)

> [Claude] ran `docker compose exec app pytest` with the default 2-min Bash
> timeout. It auto-backgrounded as task `bfm2kxy2w`. Claude then re-invoked the
> same command in the foreground with a 600s timeout — which the user manually
> backgrounded because the first run was still in flight. The first run
> ultimately completed cleanly (exit 0), but if the second had progressed past
> conftest fixture setup, the two pytest processes would have raced on
> `Base.metadata.create_all` / `drop_all` against `ops_data_hub_test`.

The pattern is ecosystem-independent: the same shape would fire with two
concurrent `npm test` runs hitting a fixed port, two `cargo test` runs
contending on the `target/` lock, or two migration tools attempting to lock
the same schema-version row.
