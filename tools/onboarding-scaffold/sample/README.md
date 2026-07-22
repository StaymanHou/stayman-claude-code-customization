# greeter — a tiny sample project

This is the throwaway sample the workflow-system tour builds one small thing on.
There is nothing real to lose here — edit freely.

## What it does

`greet.sh` prints a greeting.

```
./greet.sh World
```

**Expected output (exactly one line):**

```
Hello, World!
```

That single, checkable line is the "observable outcome" — the thing the workflow
can actually *run and verify*, instead of just claiming it works.

## TODO / known rough edges

- **No-argument case is wrong.** `./greet.sh` with no name prints `Hello, !`
  (empty name, stray comma-space-bang) instead of something sensible like
  `Hello, there!`. It's a small real bug — the kind of thing that's tempting to
  chase right now but isn't what we're here to build. Good candidate to *write
  down and come back to*.
