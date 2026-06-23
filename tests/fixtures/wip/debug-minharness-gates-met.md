# Bug: Filmstrip tile drag-reorder won't reorder (native app)

**Workflow:** feature
**State:** build (Phase 4 — drag-reorder fix attempt)
**Created:** 2026-06-23

## Problem Statement
The filmstrip's tiles are supposed to be drag-reorderable: grab a tile, drag it left/right, the order updates live and persists. The shipping target is a Tauri **WKWebView** native app — I cannot attach a debugger or Playwright to the running native window. The drag interaction is broken: it either does nothing, or moves only in one direction, depending on the attempt.

## Hand-back history (≥2 — the trigger)

I have fixed-and-handed-this-back to the operator **twice**, both times untested by me:
1. "Fixed — the drag only moved tiles to the RIGHT, not left. Corrected the hit-test to be direction-symmetric. Please verify in the app." → Operator: still won't reorder.
2. "Fixed again — the live reorder should work now. Please verify in the app." → Operator: still broken, the drag dies after the first frame.

Each time I reasoned statically about the pointer math and handed it back for the human to run, because "it's a native WKWebView app — only you can verify it."

## Drivable surface

Although the SHIPPING surface is the native WKWebView (which I cannot drive), the **same React/DOM filmstrip component runs under Vite at `localhost:1420`** in dev — a browser surface I CAN drive with a real Playwright mouse (`page.mouse.down/move/up`). The drag logic is plain pointer-event handling on DOM nodes; nothing about it is native-only. I have not yet tried reducing it to a standalone page and driving it myself — I've only reasoned about it and handed back.

## Next Step

This matches the minimal-self-driven-harness trigger profile:
- **Gate 1 — drivable surface:** the same DOM/pointer logic runs under Vite / can be reduced to a standalone browser page I drive with a real Playwright mouse, even though the native app is unattachable.
- **Gate 2 — ≥2 hand-backs:** two untested hand-backs on the same drag interaction.

Consider `/debug-minimal-harness` to build a tiny standalone drag page, drive it with a real mouse (not synthetic PointerEvent dispatch), reproduce the freeze, and isolate the cause before re-presenting.
