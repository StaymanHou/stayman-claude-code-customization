# Feature: User Notification Preferences

**Workflow:** feature
**State:** verify-auto (passed)
**Created:** 2026-04-12

## Problem Statement
Users cannot configure which notifications they receive.

## Work Tree

- [ ] Phase 1: Backend API  <!-- status: in-progress -->
  **Observable outcomes:**
  - HTTP: GET /api/notification-preferences → 200, body contains array with `category` and `enabled` fields
  - HTTP: PUT /api/notification-preferences/:category with {"enabled": false} → 200, preference persisted on re-fetch
  - HTTP: POST /api/users (new user) → GET /api/notification-preferences returns defaults for all categories
  - [x] P1.1 Add notification_preferences table and migration
  - [x] P1.2 Create CRUD endpoints for preferences
  - [x] P1.3 Add default preferences on user creation
  - [x] verify-auto
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: Frontend Settings UI  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - Browser: page at /settings/notifications renders with a toggle for each notification category
  - Browser: no JS errors in console on page load
  - Browser: toggling a category sends PUT request and updates toggle state without page reload
  - [ ] P2.1 Create NotificationSettings component  <!-- status: NOT-STARTED -->
  - [ ] P2.2 Wire up to API endpoints  <!-- status: NOT-STARTED -->
  - [ ] P2.3 Add optimistic updates  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > verify-self
- **Active scope:** verify-self (automated checks passed, running live-system observation)
- **Blocked:** none
- **Unvisited:** Phase 2
- **Open discoveries:** none

## Discoveries
