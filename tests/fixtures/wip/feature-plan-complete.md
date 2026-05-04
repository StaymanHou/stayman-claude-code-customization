# Feature: WP3 — Input + Camera

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-05-04

## Problem Statement

The browser flight sim has no keyboard/mouse input handling and no camera system. Players cannot control the aircraft or change viewing angle. This feature adds an InputManager (frame-stable key/mouse state) and a CameraController (Chase and Cockpit modes).

## Work Tree

- [ ] Phase 1: Input system  <!-- status: NOT-STARTED -->
  **Observable outcomes:**
  - CLI: `npx vitest run src/engine/input.test.ts` exits 0, all 4 tests pass
  - Browser: opening http://localhost:5173 and pressing W shows "forward: true" in lil-gui "Keys held" panel
  - Browser: no JS console errors on page load
  - [ ] P1.1 Implement InputManager class with keydown/keyup listeners and flush()  <!-- status: NOT-STARTED -->
  - [ ] P1.2 Implement KeyMap with logical actions mapped to key codes  <!-- status: NOT-STARTED -->
  - [ ] P1.3 Wire InputManager into main.ts game loop with lil-gui debug readout  <!-- status: NOT-STARTED -->
  - [ ] P1.4 Write 4 Vitest unit tests (keydown/keyup state, wasPressed single-frame, mouseDelta)  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: Camera system  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - CLI: `npx vitest run src/engine/camera.test.ts` exits 0, all 3 tests pass
  - Browser: pressing V toggles lil-gui "Camera mode" between "Chase" and "Cockpit"
  - Browser: in Chase mode the camera follows the falling cube from behind; in Cockpit mode the view is fixed to the cube's orientation
  - [ ] P2.1 Implement CameraController with Chase and Cockpit modes  <!-- status: NOT-STARTED -->
  - [ ] P2.2 Chase: exponential-decay lerp toward offset-behind-target, lookAt each frame  <!-- status: NOT-STARTED -->
  - [ ] P2.3 Cockpit: rigid attach (position + quaternion copy, no lerp)  <!-- status: NOT-STARTED -->
  - [ ] P2.4 Wire V key to mode swap; add lil-gui "Camera mode" readout  <!-- status: NOT-STARTED -->
  - [ ] P2.5 Write 3 Vitest unit tests (lerp convergence, cockpit snap, mode switch)  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > P1.1
- **Active scope:** P1.1 (InputManager implementation)
- **Blocked:** none
- **Unvisited:** Phase 2
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
