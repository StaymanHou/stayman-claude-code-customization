"""Unit tests for tools/claude-time/viz_render.py.

Pinned regressions:
  - _strip_design_wrapper: tolerant to dash-count drift in the
    `/* ── Dashboard wrapper ── */` section marker; does NOT false-match
    on unrelated prose comments that happen to mention "Dashboard wrapper".

Run via:
  python3 -m unittest discover -s tools/claude-time/test -p 'test_viz_render*'
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

_HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE.parent))
import viz_render  # noqa: E402


class StripDesignWrapperTests(unittest.TestCase):
    """Regression coverage for the regex-tolerant marker matching.

    WP9 Phase 2 P2.disc.1 (2026-05-23): the prior implementation used a
    hardcoded-dash-count strict marker with a naive `find("Dashboard wrapper")`
    fallback. A new prose comment that mentioned "Dashboard wrapper" produced
    a false-first match and stripped the whole file body. Replaced with a
    regex that requires the surrounding `/* ── ... ── */` comment-block context
    AND tolerates any trailing-dash count >= 2. These tests pin that contract.
    """

    BODY = "const foo = 1;\nconst bar = 2;\n"
    MARKER_64_DASHES = "/* " + "\u2500" * 2 + " Dashboard wrapper " + "\u2500" * 64 + " */"
    MARKER_2_DASHES = "/* " + "\u2500" * 2 + " Dashboard wrapper " + "\u2500" * 2 + " */"
    MARKER_DRIFTED = "/* " + "\u2500" * 2 + " Dashboard wrapper " + "\u2500" * 33 + " */"

    def test_matches_short_dash_count(self):
        jsx = self.BODY + self.MARKER_2_DASHES + "\nfunction Dashboard() {}\n"
        out = viz_render._strip_design_wrapper(jsx)
        self.assertEqual(out, self.BODY)

    def test_matches_long_dash_count(self):
        jsx = self.BODY + self.MARKER_64_DASHES + "\nfunction Dashboard() {}\n"
        out = viz_render._strip_design_wrapper(jsx)
        self.assertEqual(out, self.BODY)

    def test_matches_drifted_dash_count(self):
        """The actual current source has ~33 trailing dashes (line 1647 of
        dashboard.jsx at WP9 ship time). Pin that this specific count works
        — historically this had drifted away from the hardcoded marker."""
        jsx = self.BODY + self.MARKER_DRIFTED + "\nfunction Dashboard() {}\n"
        out = viz_render._strip_design_wrapper(jsx)
        self.assertEqual(out, self.BODY)

    def test_does_not_false_match_on_prose_mention(self):
        """The exact regression that triggered P2.disc.1: a prose comment
        elsewhere in the file mentioned 'Dashboard wrapper'. The pre-fix
        fallback false-matched, stripping the whole body. Post-fix the
        regex requires the `/* ── ... ── */` comment-block context."""
        jsx_with_prose = (
            "// FilterContext is provided by the shipped Dashboard wrapper component.\n"
            + self.BODY
            + self.MARKER_DRIFTED
            + "\nfunction Dashboard() {}\n"
        )
        out = viz_render._strip_design_wrapper(jsx_with_prose)
        # The output must keep the prose-mention line (it's BEFORE the real marker).
        self.assertIn("FilterContext is provided", out)
        self.assertIn("const foo = 1;", out)
        # The output must NOT include the real marker or what follows.
        self.assertNotIn("\u2500" * 33, out)
        self.assertNotIn("function Dashboard()", out)

    def test_raises_when_marker_absent(self):
        jsx = self.BODY + "// no marker here\nfunction Dashboard() {}\n"
        with self.assertRaises(ValueError):
            viz_render._strip_design_wrapper(jsx)

    def test_real_source_still_strips(self):
        """End-to-end pin: the actual checked-in dashboard.jsx must still
        be strippable by _strip_design_wrapper. If a future edit moves or
        renames the section marker, this fails fast at codify time rather
        than at emit time."""
        jsx = (_HERE.parent / "viz" / "dashboard.jsx").read_text()
        out = viz_render._strip_design_wrapper(jsx)
        # The stripped output should be substantially shorter than the source
        # (the design-canvas Dashboard wrapper is a large block).
        self.assertLess(len(out), len(jsx))
        # Stripped output must still contain canonical pre-marker components.
        self.assertIn("function SegmentBar(", out)
        self.assertIn("function Toolbar(", out)


class RenderHtmlInitialPresetTests(unittest.TestCase):
    """WP11 Phase 1: `render_html(...)` accepts `initial_preset: str | None`
    and emits `window.CT_INITIAL_PRESET = <json-literal>;` into the template.

    Threads through:
      - None (default) → JS literal `null`, NOT the string `"null"`
      - "wow" / "today-vs-trailing" / "mom" / "custom" → JSON-quoted string
      - the template's `{{CT_INITIAL_PRESET}}` placeholder must be fully
        substituted with no leak into emit

    These tests use the real template.html + dashboard.jsx because the
    contract is end-to-end (template + transforms + emit). A unit-level
    string-substitution test would not catch the failure mode where the
    template's placeholder name drifts.
    """

    @classmethod
    def setUpClass(cls):
        viz_dir = _HERE.parent / "viz"
        cls.template_path = viz_dir / "template.html"
        cls.jsx_path = viz_dir / "dashboard.jsx"
        cls.data = {
            "today": {"label": "Today", "iso": "2026-05-26", "projects": [],
                      "hour_range": [6, 23]},
            "week": {"label": "Week", "days": [], "projects": []},
            "meta": {"snapshot": "10:00", "snapshot_iso": "2026-05-26T10:00:00"},
        }

    def test_default_initial_preset_is_null_literal(self):
        """When `initial_preset` is omitted, emit `window.CT_INITIAL_PRESET = null;`
        (JS null literal, not the string \"null\"). Default-elision must keep
        Compare-view state out of the hash on un-related emits."""
        html = viz_render.render_html(
            self.template_path, self.jsx_path, self.data,
        )
        self.assertIn("window.CT_INITIAL_PRESET = null;", html)
        self.assertNotIn('window.CT_INITIAL_PRESET = "null";', html)
        # Placeholder must be fully substituted.
        self.assertNotIn("{{CT_INITIAL_PRESET}}", html)

    def test_explicit_none_initial_preset_is_null_literal(self):
        """Passing initial_preset=None explicitly must produce the same null literal."""
        html = viz_render.render_html(
            self.template_path, self.jsx_path, self.data,
            initial_preset=None,
        )
        self.assertIn("window.CT_INITIAL_PRESET = null;", html)

    def test_string_preset_is_quoted_string_literal(self):
        """A non-None preset value must emit as a JSON-quoted string."""
        for preset in ("wow", "today-vs-trailing", "mom", "custom"):
            with self.subTest(preset=preset):
                html = viz_render.render_html(
                    self.template_path, self.jsx_path, self.data,
                    initial_preset=preset,
                )
                self.assertIn(f'window.CT_INITIAL_PRESET = "{preset}";', html)
                self.assertNotIn("{{CT_INITIAL_PRESET}}", html)

    def test_existing_initial_view_unaffected(self):
        """The new initial_preset parameter must not regress the existing
        initial_view placeholder substitution."""
        html = viz_render.render_html(
            self.template_path, self.jsx_path, self.data,
            initial_view="compare", initial_preset="wow",
        )
        self.assertIn('window.CT_INITIAL_VIEW = "compare";', html)
        self.assertIn('window.CT_INITIAL_PRESET = "wow";', html)
        self.assertNotIn("{{CT_INITIAL_VIEW}}", html)
        self.assertNotIn("{{CT_INITIAL_PRESET}}", html)


if __name__ == "__main__":
    unittest.main()
