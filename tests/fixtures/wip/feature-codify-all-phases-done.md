# Feature: User Notification Preferences

**Workflow:** feature
**State:** verify-codify (all phases complete)
**Created:** 2026-04-12

## Problem Statement
Users cannot configure which notifications they receive.

## Work Tree

- [x] Phase 1: Backend API
  **Observable outcomes:**
  - HTTP: GET /api/notification-preferences → 200, body contains array with `category` and `enabled` fields
  - HTTP: PUT /api/notification-preferences/:category with {"enabled": false} → 200, preference persisted on re-fetch
  - HTTP: POST /api/users (new user) → GET /api/notification-preferences returns defaults for all categories
  - [x] P1.1 Add notification_preferences table and migration
  - [x] P1.2 Create CRUD endpoints for preferences
  - [x] P1.3 Add default preferences on user creation
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [x] verify-codify

- [x] Phase 2: Frontend Settings UI
  **Observable outcomes:**
  - Browser: page at /settings/notifications renders with a toggle for each notification category
  - Browser: no JS errors in console on page load
  - Browser: toggling a category sends PUT request and updates toggle state without page reload
  - [x] P2.1 Create NotificationSettings component
  - [x] P2.2 Wire up to API endpoints
  - [x] P2.3 Add optimistic updates
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [x] verify-codify

## Current Node
- **Path:** Feature > ship
- **Active scope:** all phases complete, ready to ship
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries
