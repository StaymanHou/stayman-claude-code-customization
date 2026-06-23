# Bug: Hardware scanner emits a phantom second barcode read intermittently

**Workflow:** feature
**State:** build (fix attempt)
**Created:** 2026-06-23

## Problem Statement
The warehouse handheld scanner (a physical Zebra device on the floor) occasionally registers a single physical barcode scan as two reads, creating a duplicate line item. The behavior only manifests on the real device under real warehouse RF/lighting conditions — it depends on the scanner's own firmware debounce and the physical trigger pull.

## Hand-back history (≥2)

I have handed this back to the operator **three** times — each time after a firmware-config or debounce-threshold guess, asking the warehouse staff to test on the real device. Each time it still intermittently double-reads.

## Drivable surface — NONE I control

There is no surface I can drive myself that faithfully reproduces this:
- The duplicate originates in the **physical scanner hardware + its firmware debounce**, triggered by a real trigger-pull against a real barcode under real ambient conditions.
- There is no DOM/browser/CLI/HTTP analogue I can drive — the device is a closed third-party peripheral I cannot invoke programmatically, and the timing depends on physical actuation and RF environment.
- Simulating "a scan" in software would not exercise the firmware debounce path where the bug lives — any software stand-in would be a synthetic stand-in that false-passes.

## Next Step

Gate 1 (drivable surface) **FAILS** — the behavior is genuinely undrivable by me; it lives in physical hardware + closed firmware with no faithful surface I can control. Building a software "reproduction" would be exactly the synthetic-pass trap the technique warns against. Human verification on the real device, or vendor-side firmware investigation, is the path — `/debug-minimal-harness` does not apply.
