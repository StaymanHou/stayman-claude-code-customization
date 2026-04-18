# Feature: User Notification Preferences

**Workflow:** feature
**State:** build (phase 1 complete)
**Created:** 2026-04-12

## Implementation Phases

### Phase 1: Backend API
- [x] Add notification_preferences table
- [x] Create CRUD endpoints for preferences
- [x] Add default preferences on user creation

### Phase 2: Frontend Settings UI
- [ ] Create NotificationSettings component
- [ ] Wire up to API endpoints
- [ ] Add optimistic updates

## Verification
- Run: `pytest tests/test_notifications.py`
