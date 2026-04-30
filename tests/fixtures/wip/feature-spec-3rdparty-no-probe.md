# Feature: Stripe Subscription Billing

**Workflow:** feature
**State:** spec
**Created:** 2026-04-30

## Problem Statement

Users need to upgrade to a paid plan. Implement Stripe subscription billing:
create a PaymentIntent when a user selects a plan, handle webhook events for
subscription lifecycle (created, updated, canceled), and gate premium features
behind an active subscription status stored in the database.

## Open Questions
- [ ] Which Stripe products to use — Subscriptions API or Payment Links?
- [ ] How to handle failed payments and retry logic?
- [ ] How should the subscription status be propagated to the feature-gate middleware?
