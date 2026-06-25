---
date: 2026-05-13
scope: global
type: Context Rule
session-ref: WP9.6 amazon-affiliate window-invisibility debug
---

# Anti-pattern: convention-based attribute lookup + silent default

## Summary
When a base class builds an attribute or key name from a runtime string and
looks it up with `hasattr`/`getattr` (or `.get(key, default)`), a lookup miss
in a subclass falls through to the default silently. If the default is wrong
for that subclass, the bug is invisible at the call site, the test site, and
the log site. The combination — string-built lookup + silent default — should
be treated as a known bug nursery in code review.

## Suggested change
CLAUDE.md rule (global): When a base class derives an attribute or key name
from a runtime string (e.g. `f"{self.source}_config"`) and looks it up
defensively, the lookup miss must be loud — either log a warning when the
attribute is absent, require subclasses to assert presence explicitly, or
fail fast when a default value would change observable behavior (e.g. headed
vs. headless). Silent defaults next to convention-based lookups encode bugs
where the most common failure mode (subclass naming drift) is invisible.

## Session-log excerpt (optional)
In WP9.6, `PlaywrightCollector._start_browser_async` looked up the per-collector
playwright config via `self.<source>_config` (computed from `source` by string
manipulation). For source `amazon_affiliate` it resolved to
`amazon_affiliate_config` — but the actual attribute on the subclass was
`amazon_config`. `hasattr` returned False, the lookup fell back to
`self.config.get('playwright', {})` (also empty), and `headless` defaulted to
True. The collector silently launched headless Chromium on a headed-required
node; Playwright reported every wire-level operation as successful (page
titles, screenshots, navigation all worked); only the operator's eye on the
iMac desktop saw "no window."
