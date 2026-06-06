# `not_contains_strict: true` is structurally fragile when the failing skill is not the skill under test

Strict `not_contains` lists are catching "phrases that indicate the failure mode" — but the model can produce those phrases for benign in-context reasons (e.g., a session-orchestrator scenario producing "waiting for the dev URL" in a correct chain). When a scenario's `skill:` is one piece (e.g. `session-start`) and the `not_contains` patterns target failure shapes that originate elsewhere, strict mode raises noise-FAILs that look like regressions.

## Practical application

Before tagging a scenario `not_contains_strict: true`, ask whether each `not_contains` phrase is a *failure proxy* (only appears when the failure mode is happening) or *informational* (could appear in benign in-context reasoning). Strict mode is for the former only.

## Instance

Caught 2026-05-17 when S25 FAILed on "waiting for" during the autopilot-pause-policy mitigation test sweep but PASSed on isolated re-run — pure model variance, not a regression.
