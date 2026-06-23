# Bug: Keyboard shortcut ⌘K doesn't open the command palette on first attempt

**Workflow:** feature
**State:** build (fix attempt)
**Created:** 2026-06-23

## Problem Statement
Pressing ⌘K should open the command palette overlay. A user reported that on the first press after page load it sometimes does nothing; a second press works. The app is a web app I can drive in a browser with a real keyboard via Playwright.

## Hand-back history — only ONE attempt so far

I have looked at this **once**: I read the keydown handler and noticed the listener is attached in a `useEffect` that depends on a value that changes on mount, so the first-press handler may be bound to a stale closure. I have NOT yet attempted a fix or handed anything back — this is my first pass at the bug. The user reported it; I have one hypothesis from a single read.

## Drivable surface

The behavior IS drivable by me — it's a web app, ⌘K is a real `page.keyboard` press in a browser I control. Gate 1 would hold.

## Next Step

Gate 2 (≥2 hand-backs) **FAILS** — I have made only one attempt and have not handed anything back yet. The cheap path comes first: apply the targeted fix for the stale-closure hypothesis (a `useRef`-latest or a stable handler), then verify. The minimal-harness technique's cost is only justified once the hand-back loop has stalled (≥2 untested hand-backs on the same behavior). `/debug-minimal-harness` does not apply yet — try the obvious fix first.
