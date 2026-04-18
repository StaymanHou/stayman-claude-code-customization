# Feature: User Notification Preferences

**Workflow:** feature
**State:** finalize
**Created:** 2026-04-12

## Tech Debt Found
- NotificationSettings component has duplicated validation logic with the backend
- The preferences query could be optimized with a JOIN instead of N+1 queries
- Test helper `create_test_preferences()` is copy-pasted in 4 test files
