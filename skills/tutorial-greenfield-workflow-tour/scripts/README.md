# onboarding-scaffold (in-skill)

The small **greenfield sample project** the new-user tour builds one small thing on,
plus a scaffolder that stamps a fresh throwaway copy for each tour run.

Consumed by `skills/tutorial-greenfield-workflow-tour/SKILL.md` (M11 / WP7c; sample
redesigned to a todo CLI in WP7i). It is **tour content, not a test fixture**.

**Why it lives INSIDE the skill dir (`scripts/`), not under repo-root `tools/` (WP7j Phase 6).**
`install.sh` symlinks each skill's whole directory into `~/.claude/skills/` but does **not**
symlink repo-root `tools/`. Shipping the scaffold under `tools/` meant an installed user (the
Claudesk-invited target, WP8) got the greenfield arm skill but **not** the sample it needs —
the tour would break. Living beside the skill, the scaffold travels with the skill's whole-dir
symlink and resolves on any install. The scripts resolve their own sibling `sample/` from
`$0`'s directory, so they work from the repo checkout or a `~/.claude/` symlink alike.

## Layout

```
skills/tutorial-greenfield-workflow-tour/scripts/
├── new-sample.sh     # stamp a fresh copy of sample/ (tour: --dest . into the user's cwd)
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
# THE TOUR'S FORM — stamp flat into the user's current working directory.
# This is what the greenfield arm skill runs; the cwd must be empty (see below).
~/.claude/skills/tutorial-greenfield-workflow-tour/scripts/new-sample.sh --dest .

# Stamp into some other specific (empty/new) dir:
~/.claude/skills/tutorial-greenfield-workflow-tour/scripts/new-sample.sh --dest /path/to/todo

# Stamp into a throwaway temp dir and print its path (ad-hoc/manual use — NOT the tour's form):
~/.claude/skills/tutorial-greenfield-workflow-tour/scripts/new-sample.sh

# Overwrite a non-empty dir on purpose (the tour must NEVER do this):
~/.claude/skills/tutorial-greenfield-workflow-tour/scripts/new-sample.sh --dest /path/to/todo --force
```

The tour always uses a **fresh copy** so the user's real edits, the SURFACE, and the
handoff/restore all happen against something disposable — never the shipped `sample/`.

**The tour stamps into the user's own cwd, not a temp dir** (WP7l, 2026-07-25): the operator's live
walkthrough showed that a `$TMPDIR` path the agent `cd`s into leaves a brand-new user unsure where
their work lives, which undercuts the "your state is a real file you own" beat. The arm therefore
requires an **empty** cwd and relies on this script's no-clobber guard — a non-empty destination is
refused with nothing written, and the arm asks the user for an empty directory rather than passing
`--force`. See the arm's "## The environment" section for the user-facing copy.

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
skills/tutorial-greenfield-workflow-tour/scripts/test/run-tests.sh
```

Asserts the sample's observable outcome, the `done`-persistence, the planted tangent, the
no-runtime property, and the scaffolder's fresh-copy / independence / no-clobber /
`--force` / `--help`-hygiene / arm-wiring behavior.
