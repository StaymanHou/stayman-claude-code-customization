# tools/claude-time/viz_render.py — emit-time-transform marker fragility

## When this matters
Touching `tools/claude-time/viz/dashboard.jsx` source — adding new JSX comments, new function/component names, or new string literals in the JSX tree.

## The fragility
`viz_render.py` applies text-replace transforms over `dashboard.jsx` at emit time:
- `_strip_design_wrapper` — strips the design-canvas Dashboard prototype at file bottom. Its primary marker is a specific Unicode-dash comment block; if that fails to match exactly, it falls back to a substring search for `"Dashboard wrapper"` and truncates at the first occurrence.
- `_wire_bar_click` — looks for the exact string `function SegmentBar({ seg, selected = false }) {` to inject an `onClick` prop. Also: `function SessionRow(`, `function DayTimeline(`.
- `_add_interrupt_hairlines` — appends an `InterruptHairlines` component definition.

Any JSX comment, doc-comment, or string literal in `dashboard.jsx` containing these substrings risks tripping the fallback markers — truncating the JSX at the wrong line and breaking downstream transforms with confusing "X signature not found" errors.

## Substrings to avoid in dashboard.jsx comments + literals
- `"Dashboard wrapper"` (trips `_strip_design_wrapper` fallback)
- `"function SegmentBar"`, `"function SessionRow"`, `"function DayTimeline"`
- `"InterruptHairlines"`

## Caught at
WP5 Phase 1 build (2026-05-22) — a JSX comment containing "from the Dashboard wrapper through" tripped the fallback marker; `_strip_design_wrapper` truncated mid-file; `_wire_bar_click` failed with "SegmentBar signature not found." Fixed by rephrasing the comment.

## Future workflow lesson
The byte-pin relaxation in v2 cycle (allowing direct edits to `dashboard.jsx`) was correct, but this transform-fragility persists. When future v2-cycle phases (WP5b, WP6, WP7, WP8, WP9, WP10, WP11, WP12, WP13) touch `dashboard.jsx`, agents should grep for transform-marker substrings in their new comments/strings before assuming a build is clean. Consider promoting to a `viz_render.py` module docstring warning or `tools/claude-time/README.md` author note when next maintaining that surface.
