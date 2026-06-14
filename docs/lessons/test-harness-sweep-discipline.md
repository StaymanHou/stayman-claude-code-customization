# Verify-codify full-group sweep discipline — use `--filter-model default` to avoid haiku-on-sonnet retry storms

When running `./tests/run-tests.sh --group <group> --model haiku` during a feature's verify-codify, sonnet-tagged scenarios in that group will burn `max_retries + 1 = 3` attempts each on haiku before being scored. With ~6 sonnet-tagged scenarios in the feature group (see `SURFACE-2026-05-13-VERIFY-CODIFY-SCENARIOS-NEED-SONNET-TAG`), this can blow a 5-min budget to 30+ minutes.

## Practical application

Split the sweep:

```
./tests/run-tests.sh --group <group> --filter-model default     # haiku partition
./tests/run-tests.sh --filter-model sonnet --model sonnet       # sonnet partition
```

The existing `tests/run-all.sh` two-pass wrapper does this automatically when working — but per `SURFACE-2026-06-06-RUN-ALL-UNBOUND-FORWARD-ARGS` it crashes on empty FORWARD_ARGS, so the manual two-invocation pattern is the current workaround.

## Instance

Observed 2026-06-07 during `verify-human-auto-skip-when-no-integration-boundary` Phase 2: full feature-group sweep was killed at 30+ min after F32 retries hung. Targeted re-run of the new scenarios alone (45s) + partial sweep through 55+/60 (naturally completed) gave sufficient signal.
