---
feature: notification-preferences
drive_mode: autopilot
state: verify-self (all passed)
created: 2026-04-28
---

# Feature: User Notification Preferences — Phase 1 (Isolated Backend Helpers)

**Workflow:** feature
**State:** verify-self (all passed)
**Created:** 2026-04-28

## Problem Statement
Users cannot configure which notifications they receive. Phase 1 adds isolated new internal helpers — a new `preferences/` module with pure functions, a new `prefs_admin` CLI tool that no other code calls, and a new dedicated `/admin/preferences/status` endpoint nothing links to yet. The customer-facing UI wiring lands in a later phase.

## Work Tree

- [ ] Phase 1: Isolated backend helpers (no consumer wiring)  <!-- status: in-progress -->
  **Observable outcomes:**
  - CLI: `python -m preferences.helpers` exits 0 and prints a JSON dump of default categories (new module — nothing imports it yet)
  - HTTP: GET /admin/preferences/status → 200, body has `count` field (new dedicated admin endpoint, no UI link, no other code calls it)
  - CLI: `python -m prefs_admin --check` exits 0 (new standalone CLI tool, no existing entry point invokes it)
  - [x] P1.1 Create new `preferences/helpers.py` module with pure category-default functions
  - [x] P1.2 Create new admin endpoint `/admin/preferences/status` (no consumers yet)
  - [x] P1.3 Create new `prefs_admin` CLI tool as a standalone entry point
  - [x] verify-auto
  - [x] verify-self
    - [x] P1.verify-self.1 CLI: `python -m preferences.helpers` exits 0
    - [x] P1.verify-self.2 HTTP: GET /admin/preferences/status → 200, body has `count` field
    - [x] P1.verify-self.3 CLI: `python -m prefs_admin --check` exits 0
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: Wire helpers into existing /settings/notifications page  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - Browser: existing /settings/notifications page now reads from preferences.helpers
  - [ ] P2.1 Modify existing NotificationSettings component  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > verify-human
- **Active scope:** verify-human (verify-self passed all 3 outcomes; phase only added isolated new artifacts that no existing endpoint, UI page, CLI command, scheduled job, or external-system call consumes)
- **Blocked:** none
- **Unvisited:** Phase 2
- **Open discoveries:** none

## Discoveries
