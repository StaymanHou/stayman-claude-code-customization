# Feature: Add per-user theme preference

**Workflow:** feature
**State:** verify-self (BLOCKING failure on the just-completed leaf — trivial extension fix)
**Created:** 2026-04-28

## Problem Statement
The settings page is missing a theme preference toggle.

## Work Tree

- [ ] Phase 1: Backend theme preference API  <!-- status: in-progress -->
  **Observable outcomes:**
  - HTTP: GET /api/user/theme → 200, body contains {"theme": "light"|"dark"}
  - HTTP: PUT /api/user/theme with {"theme": "dark"} → 200, persisted on re-fetch
  - [x] P1.1 Add theme column to users table (one-line ALTER + default "light")
  - [x] P1.2 Add GET /api/user/theme endpoint returning the column value
  - [x] verify-auto
  - [ ] verify-self  <!-- status: in-progress -->
    - [ ] P1.verify-self.1 HTTP: GET /api/user/theme → 200  <!-- status: FAILED: returns 200 but body is {"theme": null} — the default-value clause from P1.1 is missing the DEFAULT keyword; one-character SQL fix in the migration just written -->
    - [ ] P1.verify-self.2 HTTP: PUT /api/user/theme → 200  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > verify-self
- **Active scope:** P1.verify-self.1 (BLOCKING — one-character SQL fix to the migration written in P1.1)
- **Blocked:** none
- **Unvisited:** Phase 1 verify-human, verify-codify
- **Open discoveries:** none

## Discoveries
