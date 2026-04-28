# Feature: User Notification Preferences

**Workflow:** feature
**State:** verify-human (failed — scoped re-entry)
**Created:** 2026-04-12

## Problem Statement
Users cannot configure which notifications they receive.

## Work Tree

- [ ] Phase 1: Backend API  <!-- status: in-progress -->
  **Observable outcomes:**
  - HTTP: GET /api/notification-preferences → 200, body contains array of preference objects
  - HTTP: PUT /api/notification-preferences/:category with {"enabled": false} → 200, preference persisted
  - HTTP: POST /api/users (new user) → GET /api/notification-preferences returns default preferences
  - [x] P1.1 Add notification_preferences table and migration
  - [x] P1.2 Create CRUD endpoints for preferences
  - [x] P1.3 Add default preferences on user creation
  - [x] verify-auto
  - [x] verify-self
  - [ ] verify-human  <!-- status: in-progress -->
    - [ ] P1.verify-human.1 GET preferences returns correct shape  <!-- status: FAILED -->
    - [x] P1.verify-human.2 PUT preference persists across requests
    - [ ] P1.verify-human.3 New user gets default preferences  <!-- status: BLOCKED: depends on P1.verify-human.1 -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: Frontend Settings UI  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - Browser: page at /settings/notifications renders with a toggle for each notification category
  - [ ] P2.1 Create NotificationSettings component  <!-- status: NOT-STARTED -->
  - [ ] P2.2 Wire up to API endpoints  <!-- status: NOT-STARTED -->
  - [ ] P2.3 Add optimistic updates  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > verify-human > P1.verify-human.1
- **Active scope:** P1.verify-human.1 (re-entering build to fix this specific leaf only)
- **Blocked:** P1.verify-human.3 blocked by P1.verify-human.1
- **Unvisited:** Phase 2
- **Open discoveries:** none

## Discoveries
