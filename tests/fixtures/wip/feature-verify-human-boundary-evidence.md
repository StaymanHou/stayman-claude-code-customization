---
feature: music-pool-distribution
drive_mode: autopilot
state: verify-self (passed)
created: 2026-05-01
---

# Feature: Music Pool Distribution Source

**Workflow:** feature
**State:** verify-self (passed)
**Created:** 2026-05-01

## Problem Statement
The current distribution endpoint POST /distribution/match returns a `video_id`
sourced from a Google Sheet metadata lookup. We need to replace that source
with a curated, server-side music pool so distribution decisions no longer
depend on an external sheet.

## Work Tree

- [ ] Phase 1: Wire MusicPoolService into POST /distribution/match  <!-- status: in-progress -->
  **Observable outcomes:**
  - HTTP: GET /music/pool/status → 200, body has `count` field
  - HTTP: POST /music/pool/seed → 200, body confirms seeded
  - CLI: `python -m music_pool.populate` exits 0
  - HTTP: GET /music/pool/list → 200, returns array of pool entries
  - HTTP: GET /music/pool/random → 200, returns one pool entry
  - HTTP: POST /distribution/match → 200, response `video_id` is a music-pool entry (consuming surface)
  **Alignment questions:**
  - none
  - [x] P1.1 Add `music_pool` module with `MusicPoolService.get_random(session)`
  - [x] P1.2 Expose new admin endpoints `/music/pool/seed` and `/music/pool/status`
  - [x] P1.3 Replace `video_id = sheet.lookup(...)` with `video_id = MusicPoolService.get_random(service.session)` inside the existing POST /distribution/match handler
  - [x] verify-auto
  - [x] verify-self
    - [x] P1.verify-self.1 HTTP: GET /music/pool/status → 200, body has `count` — evidence: `curl -s localhost:8000/music/pool/status` → 200, `{"count": 42}`
    - [x] P1.verify-self.2 HTTP: POST /music/pool/seed → 200, body confirms seeded — evidence: `curl -s -X POST localhost:8000/music/pool/seed` → 200, `{"seeded": 42}`
    - [x] P1.verify-self.3 CLI: `python -m music_pool.populate` exits 0 — evidence: → exit 0, `populated 42 entries`
    - [x] P1.verify-self.4 HTTP: GET /music/pool/list and /music/pool/random → 200 — evidence: list → 200, 42 entries; random → 200, `{"video_id": "mp-017"}`
    - [x] P1.verify-self.5 HTTP: POST /distribution/match → 200, video_id from pool (consuming surface) — evidence: `curl -s -X POST localhost:8000/distribution/match -d '{"track":"t1"}'` → 200, `{"video_id": "mp-031"}` (mp-031 is in the pool list)
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

- [ ] Phase 2: Pool admin UI  <!-- status: NOT-STARTED; depends on Phase 1 -->
  **Observable outcomes:**
  - Browser: page at /admin/music-pool renders the current pool entries
  - Browser: clicking "Seed" triggers POST /music/pool/seed without page reload
  - [ ] P2.1 Add admin page  <!-- status: NOT-STARTED -->
  - [ ] P2.2 Wire admin actions to pool endpoints  <!-- status: NOT-STARTED -->
  - [ ] verify-auto  <!-- status: NOT-STARTED -->
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > verify-human
- **Active scope:** verify-human (verify-self passed; phase modified existing POST /distribution/match handler — integration boundary applies)
- **Blocked:** none
- **Unvisited:** Phase 2
- **Open discoveries:** none

## Discoveries
<!-- Format: [SURFACED-<date>] <target node> — <summary> -->
