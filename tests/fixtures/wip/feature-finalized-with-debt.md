# Feature: User Notification Preferences

**Workflow:** feature
**State:** finalize
**Created:** 2026-04-12

## Problem Statement
Users cannot configure which notifications they receive.

## Work Tree

- [x] Phase 1: Backend API
  **Observable outcomes:**
  - HTTP: GET /api/notification-preferences → 200, body contains array with `category` and `enabled` fields
  - HTTP: PUT /api/notification-preferences/:category → 200, preference persisted
  - [x] P1.1 Add notification_preferences table and migration
  - [x] P1.2 Create CRUD endpoints for preferences
  - [x] P1.3 Add default preferences on user creation
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [x] verify-codify

- [x] Phase 2: Frontend Settings UI
  **Observable outcomes:**
  - Browser: page at /settings/notifications renders with toggles
  - Browser: toggling sends PUT and updates state without reload
  - [x] P2.1 Create NotificationSettings component
  - [x] P2.2 Wire up to API endpoints
  - [x] P2.3 Add optimistic updates
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [x] verify-codify

## Current Node
- **Path:** Feature > finalize
- **Active scope:** finalize (tech debt review)
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries
- [ ] Duplicated validation logic between NotificationSettings and backend  <!-- status: SURFACED: tech debt — validation logic is copy-pasted frontend/backend -->
- [ ] N+1 query in preferences fetch — could be optimized with JOIN  <!-- status: SURFACED: tech debt — performance -->
- [ ] test helper create_test_preferences() copy-pasted in 4 test files  <!-- status: SURFACED: tech debt — test duplication -->
