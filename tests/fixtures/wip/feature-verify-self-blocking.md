# Feature: User Notification Preferences

**Workflow:** feature
**State:** verify-self (blocking failure)
**Created:** 2026-04-28

## Problem Statement
Users cannot configure which notifications they receive.

## Work Tree

- [ ] Phase 1: Backend API  <!-- status: in-progress -->
  **Observable outcomes:**
  - HTTP: GET /api/notification-preferences → 200, body contains array with `category` and `enabled` fields
  - HTTP: PUT /api/notification-preferences/:category with {"enabled": false} → 200, preference persisted on re-fetch
  - Browser: /settings/notifications page loads without JS console errors
  - [x] P1.1 Add notification_preferences table and migration
  - [x] P1.2 Create CRUD endpoints for preferences
  - [x] P1.3 Add default preferences on user creation
  - [x] verify-auto
  - [ ] verify-self  <!-- status: in-progress -->
    - [ ] P1.verify-self.1 HTTP: GET /api/notification-preferences → 200  <!-- status: FAILED: returns 500 Internal Server Error — missing DB migration -->
    - [ ] P1.verify-self.2 HTTP: PUT /api/notification-preferences/:category → 200  <!-- status: BLOCKED: depends on P1.verify-self.1 -->
    - [ ] P1.verify-self.3 Browser: /settings/notifications no JS console errors  <!-- status: FAILED-cosmetic: spacing misalignment on toggle row, no console errors -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: Frontend Settings UI  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - Browser: page at /settings/notifications renders with a toggle for each notification category
  - Browser: no JS errors in console on page load
  - [ ] P2.1 Create NotificationSettings component  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > verify-self
- **Active scope:** P1.verify-self.1 (BLOCKING failure — 500 on GET endpoint)
- **Blocked:** P1.verify-self.2 depends on P1.verify-self.1
- **Unvisited:** Phase 2
- **Open discoveries:** none

## Discoveries
