---
stage: wbs
state: complete
updated: 2026-04-30
---

# Work Breakdown Structure — API Documentation Generator

## Phase 1: Core Parser

### WP1: AST Parser
**Description:** Parse Python source files using the ast module to extract functions, classes, and docstrings.
**Phase:** 1
**Dependencies:** None
**Size:** M
**Tasks:**
- [x] 1.1 Implement function and class visitor
- [x] 1.2 Extract docstrings and type annotations
- [x] 1.3 Write unit tests

### WP2: Markdown Renderer
**Description:** Convert parsed AST data into Markdown documentation.
**Phase:** 1
**Dependencies:** WP1
**Size:** S
**Tasks:**
- [x] 2.1 Implement Markdown template
- [x] 2.2 Handle nested classes and methods
- [x] 2.3 Write rendering tests

## Phase 2: CLI and Watch Mode

### WP3: CLI Interface
**Description:** Click-based CLI to run the doc generator on a file or directory.
**Phase:** 2
**Dependencies:** WP1, WP2
**Size:** S
**Tasks:**
- [x] 3.1 Implement `docgen generate` command
- [x] 3.2 Add `--output` flag
- [x] 3.3 Write CLI integration tests

### WP4: Watch Mode
**Description:** File watcher that regenerates docs on source change.
**Phase:** 2
**Dependencies:** WP3
**Size:** S
**Tasks:**
- [x] 4.1 Integrate watchdog library
- [x] 4.2 Debounce rapid changes
- [x] 4.3 Write watch mode smoke test
