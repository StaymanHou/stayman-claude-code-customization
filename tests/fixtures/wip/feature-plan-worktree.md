# Feature: User Notification Preferences

**Workflow:** feature
**State:** plan (complete)
**Created:** 2026-04-12

## Problem Statement
Users cannot configure which notifications they receive. All notifications are sent regardless of preference, leading to notification fatigue. We need CRUD endpoints and a settings UI so users can opt in/out per category.

## Work Tree

- [ ] Phase 1: Backend API  <!-- status: in-progress -->
  **Observable outcomes:**
  - HTTP: GET /api/notification-preferences → 200, body contains array of preference objects with `category`, `enabled` fields
  - HTTP: PUT /api/notification-preferences/:category with `{"enabled": false}` → 200, preference persisted
  - HTTP: POST /api/users (new user) → GET /api/notification-preferences returns default preferences for all categories
  - [ ] P1.1 Add notification_preferences table and migration  <!-- status: in-progress -->
  - [ ] P1.2 Create CRUD endpoints for preferences  <!-- status: NOT-STARTED -->
  - [ ] P1.3 Add default preferences on user creation  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
    - [ ] P1.verify-human.1 GET preferences returns correct shape  <!-- status: NOT-STARTED -->
    - [ ] P1.verify-human.2 PUT preference persists across requests  <!-- status: NOT-STARTED -->
    - [ ] P1.verify-human.3 New user gets default preferences  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: Frontend Settings UI  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - Browser: page at /settings/notifications renders with a toggle for each notification category
  - Browser: no JS errors in console on page load
  - Browser: toggling a category sends PUT request and updates toggle state without page reload
  - Browser: page reload after toggle shows persisted state
  - [ ] P2.1 Create NotificationSettings component  <!-- status: NOT-STARTED -->
  - [ ] P2.2 Wire up to API endpoints  <!-- status: NOT-STARTED -->
  - [ ] P2.3 Add optimistic updates  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > P1.1
- **Active scope:** P1.1 (currently implementing)
- **Blocked:** none
- **Unvisited:** Phase 2
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
