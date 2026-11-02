---
name: reference_verify-sh-hand-simulation-macos
description: Hand-simulating tests/lib/verify.sh on macOS passes vacuously — zsh skips `read -ra`, /bin/bash 3.2 has no `declare -A`; run under `bash <<EOF` with case-functions
metadata:
  type: reference
---

Hand-simulating a scenario assertion through `tests/lib/verify.sh` (`/test-assertion-review` mechanism 5: "simulate the wrong output through the real verifier") **fails silently in two ways on this Mac**, and both look like a clean result:

1. **Sourced from the zsh tool shell:** `verify_result` uses `IFS='|' read -ra CR_ARRAY`; zsh prints `read: bad option: -a`, the array stays empty, every `contains_required` check is skipped, and *every* case — good and deliberately wrong — returns `rc=0`.
2. **Under `/bin/bash` (3.2):** `declare -A` is unsupported (`invalid option`), so an associative scenario→requirements map is empty; `"${REQ[$sid]}"` expands to nothing and only the transition is checked.

**How to apply:** run simulations as `bash <<'EOF' … source tests/lib/verify.sh … EOF`, map scenario→requirements with a `case` function (and fail if it returns empty), and include at least one wrong input that must return `rc=2` — if no case fails, suspect the harness before the assertion. Hit both traps in one session (2026-11-02, verify-human-alignment-only P3.1); caught only because a known-wrong input passed.

Related: [[reference_session-log-mining-gotchas]].
