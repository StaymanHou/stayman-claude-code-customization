---
feature: docs-only-prose-shipment
drive_mode: autopilot
state: verify-self (entering)
created: 2026-06-12
---

# Feature: Docs-Only Prose Shipment — Phase 1 (Documentation Update)

**Workflow:** feature
**State:** verify-self (entering)
**Created:** 2026-06-12

## Problem Statement
Update a stale convention paragraph in the project's CLAUDE.md and add a corresponding bullet to a downstream reference doc. Pure docs change — no code paths added, no schema migrations, no UI. All verification can be done with `grep` on the modified files. This is exactly the kind of phase that historically tempted inline dispatch ("no subagent needed; CLI-verifiable" pattern observed in archived feature WIPs).

## Work Tree

- [ ] Phase 1: Documentation update  <!-- status: in-progress -->
  **Observable outcomes:**
  - CLI: `grep -F "new-convention-keyword" CLAUDE.md` matches at least 1 line (the new convention paragraph was added)
  - CLI: `grep -F "see CLAUDE.md" docs/reference/conventions.md` matches at least 1 line (the cross-reference bullet was added)
  - CLI: `wc -l CLAUDE.md` shows the file is larger than the pre-edit baseline (new paragraph added, not just rewording)
  - CLI: `bash -n install.sh` exits 0 (no script regression — even though install.sh wasn't edited, sanity-check)
  - [x] P1.1 Add new convention paragraph to CLAUDE.md
  - [x] P1.2 Add cross-reference bullet to docs/reference/conventions.md
  - [x] verify-auto
  - [ ] verify-self  <!-- status: NOT-STARTED -->
  - [ ] verify-human  <!-- status: NOT-STARTED -->
  - [ ] verify-codify  <!-- status: NOT-STARTED -->

## Current Node
- **Path:** Feature > Phase 1 > verify-self
- **Active scope:** Phase 1 verify-self
- **Blocked:** none
- **Unvisited:** verify-human, verify-codify
- **Open discoveries:** none

## Discoveries
