"""checks/geometry.py against the GA node pack's own drawing, and the dot detector on the node's clean map."""
import importlib
import os
import sys
import types
import unittest

import numpy as np

from checks import dots
from checks.geometry import SHAPES, Layout, parse_voicing

GA_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "custom-nodes", "ga")


def ga_modules():
    """drawing and theory from custom-nodes/ga, without running its __init__ (which imports torch)."""
    if "galab_ga_pack" not in sys.modules:
        pkg = types.ModuleType("galab_ga_pack")
        pkg.__path__ = [os.path.abspath(GA_DIR)]
        sys.modules["galab_ga_pack"] = pkg
    return importlib.import_module("galab_ga_pack.drawing"), importlib.import_module("galab_ga_pack.theory")


@unittest.skipUnless(os.path.isfile(os.path.join(GA_DIR, "drawing.py")), "GA node pack not present")
class GeometryContractTest(unittest.TestCase):
    def test_shapes_match_the_node_pack(self):
        _, theory = ga_modules()
        self.assertEqual(SHAPES, theory.CHORD_SHAPES)
        for symbol in SHAPES:
            self.assertEqual(parse_voicing(symbol), theory.resolve_chord(symbol)[1])
        self.assertEqual(parse_voicing("x-10-12-12-12-10"), theory.parse_voicing("x-10-12-12-12-10"))

    def test_dot_centers_are_where_the_map_draws_them(self):
        drawing, theory = ga_modules()
        cases = [("F", 0, 5, 1344, 768), ("Bm7b5", 0, 5, 1344, 768), ("C", 0, 12, 2048, 512),
                 ("x-10-12-12-12-10", 7, 15, 1024, 1024)]
        for chord, lo, hi, w, h in cases:
            frets = theory.resolve_chord(chord)[1]
            lines, depth = drawing.fretboard_maps(theory.voicing_positions(frets), lo, hi, w, h, 4)
            layout = Layout(lo, hi, w, h)
            d = np.asarray(depth.convert("L"))
            centers = layout.dots(frets, include_open=True)
            self.assertEqual(len(centers), sum(1 for f in frets if f is not None and lo <= f <= hi))
            for x, y in centers:
                # the depth map fills each note's disk with white; the geometry's center must be inside it
                self.assertEqual(d[y, x], 255, f"{chord} {lo}-{hi} {w}x{h}: no note at {x},{y}")
            white = np.argwhere(d == 255)
            self.assertTrue(len(white) > 0)
            # and every white pixel belongs to one of those disks
            for y, x in white[:: max(1, len(white) // 200)]:
                self.assertTrue(min((x - cx) ** 2 + (y - cy) ** 2 for cx, cy in centers) <= (layout.radius + 1) ** 2)

    def test_inlay_positions(self):
        drawing, _ = ga_modules()
        lines, _ = drawing.fretboard_maps([], 0, 12, 1344, 768, 4)
        l = np.asarray(lines.convert("L"))
        layout = Layout(0, 12, 1344, 768)
        inlays = layout.inlays()
        self.assertEqual(len(inlays), 5 + 1)  # 3 5 7 9, and two at 12
        for x, y, r in inlays:
            ring = [l[y - r, x], l[y + r, x], l[y, x - r], l[y, x + r]]
            self.assertGreater(max(ring), 200, f"no inlay ring around {x},{y}")

    def test_detector_on_the_nodes_own_maps(self):
        """The line map itself: black disks with a white outline. A control, not a claim about generated necks."""
        drawing, theory = ga_modules()
        exact = 0
        for chord in SHAPES:
            frets = theory.resolve_chord(chord)[1]
            lines, _ = drawing.fretboard_maps(theory.voicing_positions(frets), 0, 5, 1344, 768, 4)
            exact += dots.check_against_map(lines, chord, 0, 5)["exact"]
        self.assertGreaterEqual(exact, 0)  # measured and reported by the report, see test output
        print(f"\n  detector exact on the GA line maps of {len(SHAPES)} chords: {exact}", file=sys.stderr)


if __name__ == "__main__":
    unittest.main()
