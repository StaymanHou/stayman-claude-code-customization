---
drive_mode: stepping
tour: greenfield
---

# Feature: add a `done` command to the sample todo CLI

**Workflow:** feature
**State:** finalize (complete)
**Created:** 2026-07-27

## Problem Statement

The sample CLI could add and list items but had no way to mark one complete.

## Work Tree

- [x] Phase 1: implement `done <n>` and persist the checkbox flip  <!-- status: complete -->
  **Observable outcomes:**
  - CLI: `./todo done 1 && ./todo list` prints `1. [x] buy milk` and exits 0
  - [x] P1.1 parse the index argument  <!-- status: complete -->
  - [x] P1.2 flip the checkbox in the store  <!-- status: complete -->
  - [x] verify-auto  <!-- status: complete -->
  - [x] verify-self  <!-- status: complete -->
  - [x] verify-human  <!-- status: complete -->
  - [x] verify-codify  <!-- status: complete -->

## Current Node
- **Path:** Feature > complete
- **Active scope:** none — finalize done, WIP archived
- **Blocked:** none
- **Unvisited:** none
- **Open discoveries:** none

## Discoveries

- [SURFACED-2026-07-27] P1.2 — the no-argument path prints an ungrammatical line; logged to the backlog.
