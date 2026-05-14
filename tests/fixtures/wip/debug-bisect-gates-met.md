# Bug: Playwright window invisible on amazon-affiliate worker path

**Workflow:** feature
**State:** build (Phase 2 — fix attempt)
**Created:** 2026-05-13

## Problem Statement
The amazon-affiliate worker spawns a Playwright browser session in headless=false mode but the window never appears on the desktop. The same code path on the ebay-affiliate worker (which inherits from the same base class) shows the window correctly. Both workers run in the same Docker container, on the same host, with the same Playwright version and the same chromium binary.

## Investigation State

Straight-line debug attempts so far (≥3 — all failed to converge):
1. Removed the amazon-affiliate's custom `init_session` override → window still invisible
2. Swapped the user-data-dir argument to match ebay-affiliate's → window still invisible
3. Disabled the amazon-specific cookie pre-loading step → window still invisible
4. Re-checked the headless flag is literally `False` in both — confirmed identical

No converging hypothesis. The remaining differences between amazon and ebay paths include: a custom retry decorator, a different base-class attribute lookup convention, the proxy-pool selection logic, and the affiliate-tag-injection middleware. Too many variables to diff by eye.

## Known-good pair

- **Broken runner:** `affiliates/amazon/worker.py` — invokes `AmazonWorker.run()`
- **Known-good runner:** `affiliates/ebay/worker.py` — invokes `EbayWorker.run()`
- **Same environment:** both jobs run inside the same Docker container, scheduled by the same job-runner, on the same host, with the same Playwright + chromium build, against the same proxy pool.
- **Symptom:** Playwright window visible on ebay (eye-check confirms a browser window pops up). Invisible on amazon (no window appears, no error in logs, the worker proceeds as if everything is fine).

The bug reproduces deterministically — every amazon-worker run, no window; every ebay-worker run, window appears. Each iteration is cheap (~30s spin-up).

## Next Step

This matches the bisect-known-good trigger profile: structurally similar paths, known-good sibling exists in the same environment, ≥3 failed straight-line attempts. Consider `/debug-bisect-known-good`.
