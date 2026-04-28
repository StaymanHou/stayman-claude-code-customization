# Task: Add loading spinner to login button

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-04-15

## Problem Statement
The login button shows no feedback while the auth request is in flight, causing users to double-click and submit multiple times.

## Context
- Login component: `src/components/LoginForm.tsx`
- Auth service: `src/services/auth.ts` — returns `{ loading, error, login }`
- Button component: `src/components/Button.tsx` — accepts `disabled` and `loading` props

## Work Tree

- [ ] T1 Add loading state wiring — pass `disabled={loading}` and `loading={loading}` to Button  <!-- status: NOT-STARTED -->
- [ ] T2 Show spinner in Button when `loading` prop is true  <!-- status: NOT-STARTED -->
- [ ] T3 Disable button during loading to prevent double-submit  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Task > T1
- **Active scope:** T1 (first step)
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
