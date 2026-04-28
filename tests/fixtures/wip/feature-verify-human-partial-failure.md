# Feature: User Notification Preferences

**Workflow:** feature
**State:** verify-self (complete)
**Created:** 2026-04-12

## Problem Statement
Users cannot configure which notifications they receive.

## Work Tree

- [ ] Phase 1: Backend API  <!-- status: in-progress -->
  **Observable outcomes:**
  - HTTP: GET /api/notification-preferences → 200, body contains array of preference objects
  - HTTP: PUT /api/notification-preferences/:category with {"enabled": false} → 200, preference persisted
  - HTTP: POST /api/users (new user) → GET /api/notification-preferences returns default preferences
  - [ ] P1.1 Add notification_preferences table and migration  <!-- status: complete -->
  - [ ] P1.2 Create CRUD endpoints for preferences  <!-- status: complete -->
  - [ ] P1.3 Add default preferences on user creation  <!-- status: complete -->
  - [x] verify-auto
  - [x] verify-self
  - [ ] verify-human  <!-- status: in-progress -->
    - [ ] P1.verify-human.1 GET preferences returns correct shape  <!-- status: FAILED -->
    - [ ] P1.verify-human.2 PUT preference persists across requests  <!-- status: NOT-STARTED; BLOCKED: depends on P1.verify-human.1 -->
    - [ ] P1.verify-human.3 New user gets default preferences  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: Frontend Settings UI  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - Browser: page at /settings/notifications renders with a toggle for each notification category
  - Browser: toggling a category sends PUT request and updates toggle state without page reload
  - [ ] P2.1 Create NotificationSettings component  <!-- status: NOT-STARTED -->
  - [ ] P2.2 Wire up to API endpoints  <!-- status: NOT-STARTED -->
  - [ ] P2.3 Add optimistic updates  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > verify-human
- **Active scope:** P1.verify-human.1 (FAILED), P1.verify-human.2 (BLOCKED by P1.verify-human.1)
- **Blocked:** P1.verify-human.2 blocked by P1.verify-human.1
- **Unvisited:** Phase 2
- **Open discoveries:** none

## Discoveries
