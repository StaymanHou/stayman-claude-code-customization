# Test-harness primitives need property-testing across the full input namespace

A primitive that has "always worked" may only have been exercised by one shape of input. Before introducing a new input shape to a harness primitive (a new TRANSITION token format in `tests/lib/verify.sh`, a new fixture shape in `tests/run-tests.sh`, a new scenario field, etc.), property-test the primitive against the full enumeration of input shapes — not just the one you're about to ship.

## Instance

Caught 2026-05-14 during the `debug-*` category feature: `tests/lib/verify.sh` regex had a `[A-Za-z0-9_]` character class that worked correctly for 131 alphanumeric scenario TRANSITION IDs but truncated the first hyphenated debug-class token (`DEBUG-BISECT-SKIP` → captured `DEBUG`). The fix added the property-test as a permanent `[Phase 3d]` check in `tests/check-structure.sh`.
