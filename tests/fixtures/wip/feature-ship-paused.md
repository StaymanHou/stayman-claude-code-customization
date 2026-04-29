# Feature: User Notification Preferences

**Workflow:** feature
**State:** ship (pending — full test suite not yet run)
**Created:** 2026-04-28

## Problem Statement
Users cannot configure which notifications they receive.

## Work Tree

- [x] Phase 1: Backend API  <!-- status: complete -->
  **Observable outcomes:**
  - HTTP: GET /api/notification-preferences → 200
  - HTTP: PUT /api/notification-preferences/:category → 200
  - [x] P1.1 Add notification_preferences table and migration
  - [x] P1.2 Create CRUD endpoints for preferences
  - [x] verify-auto
  - [x] verify-self
  - [x] verify-human
  - [x] verify-codify

## Current Node
- **Path:** Feature > SHIP
- **Active scope:** ship step
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none
