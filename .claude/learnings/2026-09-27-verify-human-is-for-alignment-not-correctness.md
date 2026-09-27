---
date: 2026-09-27
scope: global
type: Skill
session-ref: light-bot-remastered M6 WP2 (schema and migrations)
---

# Verify-human is for alignment, not correctness

## Summary
In M6 WP2 the agent put correctness checks it could have run itself on the operator's verify-human
checklist: "run `npm run check` and paste the tail", "run `migrations apply` and paste", and "run
`create-class` in a real terminal and confirm the PIN doesn't echo". Two of them repeated checks
that verify-auto or verify-self had ALREADY run. Only after handing the TTY check to the operator
did the agent try to drive it through a `script` pty, which is the same mistake at the wrong stage.
The operator's rule: *"if something is self-drivable by you, you should drive it during verify-self
or verify-auto. Never surface a leaf like this unless the output / behavior is to be verified by
human not for correctness, but for alignment of the expectation and spec."*

## Suggested change
Skills (global), four edits:

1. **Ownership, `feature-verify-auto` vs `feature-verify-self`:** a correctness check belongs to the
   cheapest stage that can observe it.
   - **verify-auto** owns deterministic checks of the *changed code and config*, fast and scoped:
     type checks, lint, a targeted test file, import smoke. That **includes the consuming config
     surface** when the change is to config, e.g. `npm run check` after editing a tsconfig it
     reads.
   - **verify-self** owns behaviour of the *running system* against the Observable Outcomes: a CLI
     under real argv, stdin and a TTY; a `curl` against the consuming endpoint; a migration applied
     through the real tool; a Playwright interaction.
   - **verify-human never re-asks for a check either stage already ran.** It cites the captured
     result (command, exit code, key output line) as evidence alongside an alignment question.
2. **`feature-verify-human` §2/§3:** a leaf is admissible only if its answer is a judgment of
   *alignment* ("is this the behaviour, wording, format or tradeoff you meant?"). Any leaf whose
   answer is a pass/fail fact the agent can observe is **inadmissible**. It moves to verify-auto or
   verify-self per item 1, and verify-human shows the captured evidence as context. **Replace** the
   rule "integration boundary ⇒ the HUMAN runs a captured curl" with "integration boundary ⇒
   **verify-self** captures a run against the consuming surface; verify-human may show it and ask
   whether it matches the operator's intent".
3. **`feature-verify-self` / `feature-verify-self-runner`:** "not Playwright-shaped" is never a
   reason to defer to a human. Drive TTY prompts through a pty (`script -qec`), and type each input
   only after its prompt appears so the check measures no-echo, not buffered input. Drive
   interactive CLIs, real network calls and captured command output too. A behaviour becomes
   `UNVERIFIED → human` only when it genuinely can't be driven (physical hardware, a real
   classroom, the operator's own account).
4. **`feature-plan`:** write every correctness outcome so the agent can drive it, including the
   awkward ones (TTY, interactive, real network). Keep human-judgment items apart from Observable
   Outcomes, labelled as alignment questions.

## Session-log excerpt (optional)
The operator rejected a `script`-wrapped pty run submitted after the checklist had already gone to
them, pasted their own terminal output, then gave the rule above. The TTY path was then codified as
a Vitest test on a real pty (util-linux `script` in the dev image, each PIN typed only after its
prompt), and 4/4 mutants were killed (echo, asterisk mask, no raw mode, asked once). Project-scope
copy: `light-bot-remastered/.claude/memory/verify-human-is-for-alignment-not-correctness.md`.
