# todo — a tiny command-line todo list

This is the throwaway sample the workflow-system tour builds one small thing on.
There is nothing real to lose here — edit freely.

## What it is

A minimal `todo` CLI over a plain-text store, split into a dispatcher plus one
small module per subcommand:

```
todo            # the dispatcher — routes add / list / done
lib/add.sh      # append a new item
lib/list.sh     # print the numbered list
lib/done.sh     # mark an item done
todos.txt       # the store — one item per line, "[ ] text" or "[x] text"
```

The store file *is* your state: the line number is the item's index, and the
`[ ]` / `[x]` prefix is whether it's done. Nothing hidden.

## What it does

```
./todo add "buy milk"
./todo list
```

**Expected output of `list` (exactly one line, for a fresh store):**

```
1. [ ] buy milk
```

That single, checkable line is the "observable outcome" — the thing the workflow
can actually *run and verify*, instead of just claiming it works. Marking it done
and listing again flips the box:

```
./todo done 1
./todo list        # -> 1. [x] buy milk
```

## TODO / known rough edges

- **`done` doesn't range-check the index.** `./todo done 99` on a two-item list
  reports success and changes nothing — there's no "no such item" error, because
  `done.sh` only checks the index is *numeric*, never that it's *within* the list.
  It's a small real bug. It's also exactly the kind of thing that's tempting to
  chase the moment you notice it — but it isn't what we set out to build. A good
  candidate to *write down and come back to* rather than derail on now.
