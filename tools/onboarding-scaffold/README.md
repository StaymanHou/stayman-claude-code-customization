# onboarding-scaffold

The small **greenfield sample project** the new-user tour builds one small thing on,
plus a scaffolder that stamps a fresh throwaway copy for each tour run.

Consumed by `skills/tutorial-greenfield-workflow-tour/SKILL.md` (M11 / WP7c; sample
redesigned to a todo CLI in WP7i). It is **tour content, not a test fixture** — that's
why it lives under `tools/` rather than `tests/fixtures/`.

## Layout

```
tools/onboarding-scaffold/
├── new-sample.sh     # stamp a fresh copy of sample/ into a throwaway dir
├── sample/           # the canonical, minimal sample project (git-tracked)
│   ├── todo          # dispatcher — routes add / list / done
│   ├── lib/
│   │   ├── add.sh    # append a new item
│   │   ├── list.sh   # print the numbered list
│   │   └── done.sh   # mark an item done (carries the planted tangent)
│   ├── todos.txt     # the plain-text store — one item per line
│   └── README.md     # states the observable + carries the TODO tangent
└── test/run-tests.sh # smoke test for the sample + the scaffolder
```

## Canonical invocations

```bash
# Stamp a fresh copy into a throwaway dir, print its path + a run hint:
tools/onboarding-scaffold/new-sample.sh

# Stamp into a specific (empty/new) dir:
tools/onboarding-scaffold/new-sample.sh --dest /path/to/todo

# Overwrite a non-empty dir on purpose:
tools/onboarding-scaffold/new-sample.sh --dest /path/to/todo --force
```

The tour always uses a **fresh copy** so the user's real edits, the SURFACE, and the
handoff/restore all happen against something disposable — never the shipped `sample/`.

## Why the sample is shaped the way it is

The sample is a small `todo` CLI — a dispatcher plus one module per subcommand
(`add` / `list` / `done`) over a plain-text store. It's deliberately bigger than a
one-liner: a couple of real modules and a visible data file give planning, verify-self,
and SURFACE something real to bite on (a hello-world was too shallow — WP7i). Two
properties are load-bearing for the tour's two staged beats (see
`workflow-system/product/onboarding-flow-spec.md` §3-greenfield steps 5–6 + §8):

1. **Runnable with ≥1 observable outcome** — `./todo add "buy milk" && ./todo list`
   prints exactly `1. [ ] buy milk` and exits 0. This gives the **verify-self /
   grounding** beat something *real* to observe: the agent runs it and reports PASS/FAIL
   against a concrete output, so the user watches the workflow *check reality instead of
   guessing*.

2. **A planted, authentic-feeling tangent** — `./todo done <index>` doesn't range-check
   the index, so `./todo done 99` on a short list reports success and changes nothing.
   It's flagged as a `TODO` in `sample/README.md` and in `lib/done.sh`. It is a *real*
   small bug (authentic, not a fake breadcrumb) that an agent would plausibly want to
   chase mid-task. This gives the **SURFACE** beat a reliable trigger: the agent
   recognizes the rabbit-hole, logs it to the backlog, and continues without losing the plot.

## Keep it minimal so it doesn't rot

This sample rides path/skill/layout changes over time (cf. M7, which moved every
folder in the repo). Keep it POSIX-shell + markdown + a plain-text store only, **no
runtime dependencies**, and no more moving parts than the staged beats require. If it
grows further, it becomes a maintenance liability that silently breaks the tour.

## Running the smoke test

```bash
tools/onboarding-scaffold/test/run-tests.sh
```

Asserts the sample's observable outcome, the `done`-persistence, the planted tangent, the
no-runtime property, and the scaffolder's fresh-copy / independence / no-clobber /
`--force` / `--help`-hygiene / arm-wiring behavior.
