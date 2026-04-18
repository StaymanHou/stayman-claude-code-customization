# Feature: Real-time Collaboration

**Workflow:** feature
**State:** spec
**Created:** 2026-04-12

## Problem Statement
Multiple users need to edit documents simultaneously.

## Open Questions
- [ ] Which real-time protocol? WebSocket vs SSE vs WebTransport?
- [ ] How to handle conflict resolution? OT vs CRDT?
- [ ] What latency is acceptable for cursor presence?
