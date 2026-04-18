# Task: Add loading spinner to login button

**Workflow:** task
**State:** plan
**Created:** 2026-04-15

## Requirements
- Show a spinner on the login button while the auth request is in flight
- Disable the button during loading to prevent double-submit

## Context
- Login component: `src/components/LoginForm.tsx`
- Auth service: `src/services/auth.ts`

## Implementation Plan
- [ ] Add loading state to LoginForm
- [ ] Show spinner component when loading
- [ ] Disable button during loading

## Verification
- Run: `pytest tests/test_login.py`
