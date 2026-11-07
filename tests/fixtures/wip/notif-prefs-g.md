# Feature: User Notification Preferences

**Workflow:** feature
**State:** verify-human (approved)
**Created:** 2026-04-12

## Problem Statement
Users cannot configure which notifications they receive.

## Work Tree

- [x] Phase 1: Backend API
  **Observable outcomes:**
  - HTTP: GET /api/notification-preferences → 200, body contains array with `category` and `enabled` fields
  - HTTP: PUT /api/notification-preferences/:category with {"enabled": false} → 200, preference persisted on re-fetch
  - HTTP: POST /api/users (new user) → GET /api/notification-preferences returns defaults for all categories
  - [x] P1.1 Add notification_preferences table and migration (`app/models/preferences.py`, `migrations/0042_notification_preferences.py`)
  - [x] P1.2 Create CRUD endpoints for preferences (`app/api/preferences.py`, tests in `tests/api/test_preferences.py`)
  - [x] P1.3 Add default preferences on user creation (`app/services/user_service.py`, tests in `tests/services/test_user_service.py`)
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
    - [x] P1.verify-human.1 GET preferences returns correct defaults for new users
    - [x] P1.verify-human.2 PUT preference updates correctly and persists
    - [x] P1.verify-human.3 Invalid category returns 400
  - [x] verify-codify

- [ ] Phase 2: Frontend Settings UI  <!-- status: in-progress -->
  **Observable outcomes:**
  - Browser: page at /settings/notifications renders with a toggle for each notification category
  - Browser: no JS errors in console on page load
  - Browser: toggling a category sends PUT request and updates toggle state without page reload
  - [x] P2.1 Create NotificationSettings component (`web/src/settings/NotificationSettings.tsx`)
  - [x] P2.2 Wire up to API endpoints (`web/src/api/preferences.ts`)
  - [x] P2.3 Add optimistic updates
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 2 > verify-codify
- **Active scope:** verify-codify (human approved, writing comprehensive tests)
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries
