# Feature: Canva Permission Warmup

**Workflow:** feature
**State:** verify-codify (all phases complete)
**Created:** 2026-05-04

## Problem Statement
Canva permission prompts fire mid-flow, breaking UX. Pre-warm permissions on session start.

## Work Tree

- [x] Phase 1: Pre-warm permissions on session boot
  - [x] P1.1 Add CanvaPermissionWarmer service
  - [x] P1.2 Wire into session bootstrap
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [x] verify-codify

- [x] Phase 2: Cache warm-state across sessions
  - [x] P2.1 Add persistent cache layer
  - [x] P2.2 Stale-detection logic
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [x] verify-codify

## Current Node
- **Path:** Feature > verify-codify (Phase 2 — all done)
- **Active scope:** all phases complete, ready to wrap up
- **Blocked:** none
- **Unvisited:** feature-finalize, feature-ship
- **Open discoveries:** none

## Discoveries
