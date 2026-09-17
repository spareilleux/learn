"""Unit tests for the GA nodes, without ComfyUI, PyTorch or a GPU: import the classes and call their functions.

    python -m unittest discover -s code/comfyui/custom-nodes/ga/tests -v
    UPDATE=1 python -m unittest discover -s code/comfyui/custom-nodes/ga/tests    # rewrites expected/*.png
"""

import importlib
import json
import os
import sys
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

PACK = Path(__file__).resolve().parents[1]
EXPECTED = PACK / "expected"

# Import the pack the way ComfyUI does: as a package named after its folder.
sys.path.insert(0, str(PACK.parent))
ga = importlib.import_module(PACK.name)
theory = importlib.import_module(PACK.name + ".theory")
nodes = importlib.import_module(PACK.name + ".nodes")

SERIES = ("C", "G", "Am", "F", "D", "E7", "Cmaj7", "Dm7", "G7", "Bm7b5")


def check_image(test, name, batch):
    """Compare a node's IMAGE output with expected/<name>.png, pixel for pixel."""
    array = np.asarray(batch)
    test.assertEqual(array.dtype, np.float32)
    test.assertEqual(array.ndim, 4)
    test.assertEqual(array.shape[0], 1)
    test.assertEqual(array.shape[3], 3)
    pixels = np.clip(array[0] * 255.0 + 0.5, 0, 255).astype(np.uint8)
    path = EXPECTED / f"{name}.png"
    if os.environ.get("UPDATE") == "1":
        EXPECTED.mkdir(exist_ok=True)
        Image.fromarray(pixels, "RGB").save(path, optimize=True)
        return
    expected = np.asarray(Image.open(path).convert("RGB"))
    differing = int(np.count_nonzero(np.any(expected != pixels, axis=2)))
    test.assertEqual(differing, 0, f"{name}: {differing} pixels differ from {path.name}")


class TheoryTest(unittest.TestCase):
    def test_voicing_formats(self):
        self.assertEqual(theory.parse_voicing("x32010"), (None, 3, 2, 0, 1, 0))
        self.assertEqual(theory.parse_voicing("x-10-12-12-12-10"), (None, 10, 12, 12, 12, 10))
        for bad in ("x3201", "x32010x", "c major", "x-30-1-1-1-1"):
            with self.assertRaises(ValueError):
                theory.parse_voicing(bad)

    def test_ga_order_is_high_e_first(self):
        self.assertEqual(theory.ga_diagram(theory.parse_voicing("x32010")), "0-1-0-2-3-x")

    def test_every_shape_plays_its_symbol(self):
        for symbol, shape in theory.CHORD_SHAPES.items():
            with self.subTest(symbol=symbol):
                played = theory.pitch_classes(theory.parse_voicing(shape))
                self.assertEqual(played, theory.symbol_pitch_classes(symbol))

    def test_modes_are_spelled_with_one_letter_per_degree(self):
        self.assertEqual(theory.spell_mode("C", "Ionian"), ["C", "D", "E", "F", "G", "A", "B"])
        self.assertEqual(theory.spell_mode("D", "Dorian"), ["D", "E", "F", "G", "A", "B", "C"])
        self.assertEqual(theory.spell_mode("C", "Dorian"), ["C", "D", "Eb", "F", "G", "A", "Bb"])
        self.assertEqual(theory.spell_mode("F#", "Locrian"), ["F#", "G", "A", "B", "C", "D", "E"])
        self.assertEqual(theory.spell_mode("Eb", "Lydian"), ["Eb", "F", "G", "A", "Bb", "C", "D"])
        self.assertEqual(theory.spell_mode("E", "Phrygian"), ["E", "F", "G", "A", "B", "C", "D"])

    def test_scale_positions(self):
        positions = theory.scale_positions("A", "Aeolian", 5, 8)
        # string 6 (low E) from fret 5 to 8: A, Bb, B, C -> A B C are in A minor
        self.assertEqual([f for s, f in positions if s == 0], [5, 7, 8])


class NodesTest(unittest.TestCase):
    def test_mappings(self):
        self.assertEqual(sorted(ga.NODE_CLASS_MAPPINGS), ["GAChordDiagram", "GAFretboardControlMap", "GAScalePrompt"])
        for name, cls in ga.NODE_CLASS_MAPPINGS.items():
            with self.subTest(node=name):
                self.assertTrue(callable(getattr(cls(), cls.FUNCTION)))
                self.assertIn("required", cls.INPUT_TYPES())
                self.assertEqual(len(cls.RETURN_TYPES), len(cls.RETURN_NAMES))
                self.assertIn(name, ga.NODE_DISPLAY_NAME_MAPPINGS)

    def test_chord_diagrams(self):
        node = nodes.GAChordDiagram()
        for symbol in SERIES:
            with self.subTest(chord=symbol):
                image, diagram = node.draw(symbol, 256)
                self.assertEqual(diagram, theory.ga_diagram(theory.parse_voicing(theory.CHORD_SHAPES[symbol])))
                check_image(self, f"chord-{symbol}", image)
        image, diagram = node.draw("x-10-12-12-12-10", 256)
        self.assertEqual(diagram, "10-12-12-12-10-x")
        check_image(self, "chord-x-10-12-12-12-10", image)

    def test_unknown_chord(self):
        with self.assertRaisesRegex(ValueError, "unknown chord 'H7'"):
            nodes.GAChordDiagram().draw("H7", 256)

    def test_control_maps(self):
        node = nodes.GAFretboardControlMap()
        lines, depth, _ = node.draw("chord", "C", "C", "Ionian", 0, 5, 1024, 1024, 4)
        check_image(self, "map-chord-C-lines", lines)
        check_image(self, "map-chord-C-depth", depth)
        lines, depth, _ = node.draw("scale", "", "A", "Aeolian", 5, 12, 1024, 1024, 4)
        check_image(self, "map-scale-A-Aeolian-lines", lines)
        check_image(self, "map-scale-A-Aeolian-depth", depth)
        # the defaults of the optional inputs draw the same pixels
        lines, _, _ = node.draw("chord", "C", "C", "Ionian", 0, 5, 1024, 1024, 4, note_style="ring", inlays="show")
        check_image(self, "map-chord-C-lines", lines)

    def test_control_map_options(self):
        node = nodes.GAFretboardControlMap()
        lines, depth, _ = node.draw("chord", "C", "C", "Ionian", 0, 5, 1024, 1024, 4, note_style="filled")
        check_image(self, "map-chord-C-filled-lines", lines)
        check_image(self, "map-chord-C-depth", depth)  # the depth map has no note style
        lines, depth, layout = node.draw("chord", "C", "C", "Ionian", 0, 5, 1024, 1024, 4, inlays="hide")
        check_image(self, "map-chord-C-no-inlays-lines", lines)
        self.assertEqual(json.loads(layout)["inlays"], [])
        with self.assertRaises(ValueError):
            node.draw("chord", "C", "C", "Ionian", 0, 5, 1024, 1024, 4, note_style="square")
        with self.assertRaises(ValueError):
            node.draw("chord", "C", "C", "Ionian", 0, 5, 1024, 1024, 4, inlays="maybe")

    def test_empty_neck(self):
        # chord xxxxxx mutes every string: frets, strings and inlays, no note
        lines, depth, layout = nodes.GAFretboardControlMap().draw("chord", "xxxxxx", "C", "Ionian", 0, 12, 1344, 768, 4)
        check_image(self, "map-empty-0-12-lines", lines)
        layout = json.loads(layout)
        self.assertEqual(layout["notes"], [])
        self.assertEqual([m["fret"] for m in layout["inlays"]], [3, 5, 7, 9, 12, 12])

    def test_layout_matches_pixels(self):
        node = nodes.GAFretboardControlMap()
        for style in ("ring", "filled"):
            for args in (("chord", "C", "C", "Ionian", 0, 5, 1024, 1024, 4),
                         ("chord", "x-10-12-12-12-10", "C", "Ionian", 9, 15, 1344, 768, 4),
                         ("scale", "", "E", "Phrygian", 0, 7, 1024, 512, 3)):
                with self.subTest(style=style, args=args):
                    lines, depth, text = node.draw(*args, note_style=style)
                    layout = json.loads(text)
                    lines, depth = np.asarray(lines)[0], np.asarray(depth)[0]
                    self.assertEqual((layout["width"], layout["height"]), (lines.shape[1], lines.shape[0]))
                    self.assertTrue(layout["notes"])
                    for note in layout["notes"]:
                        x, y, r = note["x"], note["y"], note["r"]
                        self.assertEqual(note["string"], 6 - note["string_index"])
                        self.assertTrue((depth[y, x] == 1.0).all())
                        center = 0.0 if style == "ring" else 1.0  # a ring is black inside
                        self.assertTrue((lines[y, x] == center).all(), note)
                        self.assertTrue((lines[y, x - r + 1] == 1.0).all(), note)  # the outline or the disc
                    for marker in layout["inlays"]:
                        self.assertTrue((lines[marker["y"], marker["x"] - marker["r"]] == 1.0).all(), marker)
                    frets = [n["fret"] for n in layout["notes"]]
                    self.assertTrue(all(args[4] <= f <= args[5] for f in frets))

    def test_bad_fret_range(self):
        with self.assertRaises(ValueError):
            nodes.GAFretboardControlMap().draw("chord", "C", "C", "Ionian", 7, 7, 512, 512, 2)

    def test_scale_prompt(self):
        (prompt,) = nodes.GAScalePrompt().build("C", "Dorian", "abstract album cover")
        self.assertEqual(prompt, "abstract album cover, inspired by the C Dorian mode (C D Eb F G A Bb), "
                                 "minor with a raised sixth, warm mood")
        self.assertEqual(nodes.GAScalePrompt().build("G", "Mixolydian", " ")[0],
                         "inspired by the G Mixolydian mode (G A B C D E F), major with a lowered seventh, bluesy mood")


if __name__ == "__main__":
    unittest.main()
