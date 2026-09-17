"""checks/geometry.py reads the GA pack's layout: the contract is that its coordinates match the pack's pixels."""
import json
import os
import sys
import tempfile
import unittest

import numpy as np

from checks import dots
from runner import analyze
from checks.geometry import GA_DIR, Layout, ga_pack, parse_voicing

SYMBOLS = ("C", "D", "E", "F", "G", "A", "Am", "Dm", "Em", "E7", "G7", "Cmaj7", "Dm7", "Bm7b5")


@unittest.skipUnless(os.path.isfile(os.path.join(GA_DIR, "drawing.py")), "GA node pack not present")
class GeometryContractTest(unittest.TestCase):
    def test_voicings_come_from_the_pack(self):
        _, theory = ga_pack()
        for symbol in SYMBOLS:
            self.assertEqual(parse_voicing(symbol), theory.resolve_chord(symbol)[1])
        self.assertEqual(parse_voicing("x-10-12-12-12-10"), (None, 10, 12, 12, 12, 10))

    def test_layout_json_round_trip(self):
        drawing, theory = ga_pack()
        data = drawing.fretboard_layout(theory.voicing_positions(parse_voicing("F")), 0, 5, 1344, 768, "show")
        a = Layout(json.dumps(data, sort_keys=True))
        b = Layout.compute("F", 0, 5, 1344, 768)
        self.assertEqual(a.dots(), b.dots())
        self.assertEqual(len(a.dots()), 6)

    def test_note_centers_are_where_the_map_draws_them(self):
        drawing, theory = ga_pack()
        cases = [("F", 0, 5, 1344, 768), ("Bm7b5", 0, 5, 1344, 768), ("C", 0, 12, 2048, 512),
                 ("x-10-12-12-12-10", 7, 15, 1024, 1024)]
        for chord, lo, hi, w, h in cases:
            frets = theory.resolve_chord(chord)[1]
            positions = theory.voicing_positions(frets)
            _, depth = drawing.fretboard_maps(positions, lo, hi, w, h, 4)
            layout = Layout.compute(chord, lo, hi, w, h)
            d = np.asarray(depth.convert("L"))
            centers = layout.dots(include_open=True)
            self.assertEqual(len(centers), sum(1 for f in frets if f is not None and lo <= f <= hi))
            for x, y in centers:
                self.assertEqual(d[y, x], 255, f"{chord} {lo}-{hi} {w}x{h}: no note at {x},{y}")
            white = np.argwhere(d == 255)
            for y, x in white[:: max(1, len(white) // 200)]:
                self.assertTrue(min((x - cx) ** 2 + (y - cy) ** 2 for cx, cy in centers) <= (layout.radius + 1) ** 2)

    def test_inlay_positions_shown_and_hidden(self):
        drawing, _ = ga_pack()
        lines, _ = drawing.fretboard_maps([], 0, 12, 1344, 768, 4)
        l = np.asarray(lines.convert("L"))
        shown = Layout.compute("xxxxxx", 0, 12, 1344, 768, "show")
        hidden = Layout.compute("xxxxxx", 0, 12, 1344, 768, "hide")
        self.assertEqual(len(shown.inlays()), 6)  # 3 5 7 9, and two at 12
        self.assertEqual(hidden.inlays(), [])
        self.assertEqual(hidden.inlay_positions(), shown.inlays())
        for x, y, r in shown.inlays():
            self.assertGreater(max(l[y - r, x], l[y + r, x], l[y, x - r], l[y, x + r]), 200)

    def test_detector_on_the_pack_maps(self):
        """Controls, not claims about generated necks: ring maps (the default) and filled maps, inlays hidden."""
        drawing, theory = ga_pack()
        counts = {}
        for style in ("ring", "filled"):
            exact = 0
            for chord in SYMBOLS:
                positions = theory.voicing_positions(theory.resolve_chord(chord)[1])
                lines, _ = drawing.fretboard_maps(positions, 0, 5, 1344, 768, 4, style, "hide")
                exact += dots.check_against_map(lines, chord, 0, 5, inlays="hide")["exact"]
            counts[style] = exact
        print(f"\n  detector exact on GA line maps, 14 chords: {counts}", file=sys.stderr)
        self.assertEqual(counts["filled"], len(SYMBOLS))

    def test_analyze_reads_the_recorded_layout(self):
        """runner analyze on experiment 1: the layout text PreviewAny recorded wins over the chord in the params."""
        drawing, theory = ga_pack()
        exp = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "experiments",
                           "01-chord-neck.yaml")
        with tempfile.TemporaryDirectory() as out:
            data = drawing.fretboard_layout(theory.voicing_positions(parse_voicing("F")), 0, 5, 1344, 768, "hide")
            lines, _ = drawing.fretboard_maps(theory.voicing_positions(parse_voicing("F")), 0, 5, 1344, 768, 4,
                                              "filled", "hide")
            lines.save(os.path.join(out, "f.png"))
            params = {"18.chord": "C", "18.fret_start": 0, "18.fret_end": 5, "18.inlays": "hide"}  # C on purpose
            items = [{"key": "k1", "status": "done", "labels": {"chord": "F"}, "seed": 42, "params": params,
                      "outputs": [{"node": "9", "file": "f.png", "sha256": "0"}], "texts": {"23": [json.dumps(data)]}},
                     {"key": "k2", "status": "done", "labels": {"chord": "C"}, "seed": 42, "params": params,
                      "outputs": [{"node": "9", "file": "f.png", "sha256": "0"}], "texts": {}}]
            with open(os.path.join(out, "results.json"), "w", encoding="utf-8") as f:
                json.dump({"items": items}, f)
            rows = analyze.analyze(exp, out)[1]["analyses"][0]["rows"]
        self.assertEqual((rows[0]["layout_from"], rows[0]["exact"]), ("node", True))
        self.assertEqual((rows[1]["layout_from"], rows[1]["exact"]), ("recomputed", False))


if __name__ == "__main__":
    unittest.main()
