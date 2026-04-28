# Task: Add loading spinner to login button

**Workflow:** task
**State:** plan (complete)
**Created:** 2026-04-12

## Problem Statement
The login button shows no feedback while the auth request is in flight, causing users to double-click and submit multiple times.

## Context
- Login form: `src/components/LoginForm.tsx`
- Auth request: `src/hooks/useAuth.ts` — returns `{ loading, error, login }`
- Button component: `src/components/Button.tsx` — accepts `disabled` and `loading` props

## Work Tree

- [ ] T1 Add `disabled={loading}` and `loading={loading}` props to login Button  <!-- status: NOT-STARTED -->
- [ ] T2 Import and wire `useAuth` loading state into LoginForm  <!-- status: NOT-STARTED -->
- [ ] T3 Verify spinner renders during auth request in dev  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Task > T1
- **Active scope:** T1 (first step)
- **Blocked:** none
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary>
     Each entry is also logged to workflow/backlog.md -->
