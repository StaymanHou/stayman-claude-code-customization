# Bug: Email digest send is failing for premium-plan users only

**Workflow:** feature
**State:** build (Phase 1 — initial investigation)
**Created:** 2026-05-13

## Problem Statement
The daily email digest is failing to send for users on the premium plan, with a stack trace pointing at `digest_renderer.render_premium_section()`. Users on the free plan and the team plan are receiving their digests correctly. The same renderer code runs for all plan tiers — but the failure is isolated to premium.

## Investigation State

Straight-line debug attempts so far:
1. Read the stack trace once — points at line 142 of `digest_renderer.py`, a dictionary key access for `user.premium_features`. The key may not exist on all users.

That's it — only **one** straight-line debug attempt so far. Have not yet tried: checking whether `user.premium_features` is None vs absent vs malformed; looking at how the free/team renderers handle the equivalent attribute; running a manual repro with a known premium user record.

## Known-good pair

- **Broken runner:** premium-plan digest send — fails on `digest_renderer.render_premium_section()`
- **Known-good runner:** free-plan or team-plan digest send — succeeds with `digest_renderer.render_free_section()` / `render_team_section()`
- Both run in the same scheduler, same Python runtime, same digest-renderer module.

A known-good sibling exists, but **straight-line debugging has not been attempted ≥3 times yet** — only one stack-trace read. The natural next step is to attempt a few targeted straight-line debug iterations before considering bisection: check the attribute presence, compare the three render-section functions, try a manual repro. Bisection is overhead-heavy and reserved for the case where hypothesis-poor thrashing has already happened.

## Next Step

Continue straight-line debug for at least two more iterations before considering `/debug-bisect-known-good`.
