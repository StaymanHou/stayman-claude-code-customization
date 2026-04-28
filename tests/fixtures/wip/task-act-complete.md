# Task: Add loading spinner to login button

**Workflow:** task
**State:** act (complete)
**Created:** 2026-04-15

## Problem Statement
The login button shows no feedback while the auth request is in flight.

## Context
- Login component: `src/components/LoginForm.tsx`
- Auth service: `src/services/auth.ts`

## Work Tree

- [x] T1 Add loading state wiring — pass `disabled={loading}` and `loading={loading}` to Button
- [x] T2 Show spinner in Button when `loading` prop is true
- [x] T3 Disable button during loading to prevent double-submit

## Current Node
- **Path:** Task > complete
- **Active scope:** all steps complete
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
