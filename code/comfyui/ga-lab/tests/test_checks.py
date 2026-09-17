"""The measures: SVG rasterizing, bracelet readback, seams, pixel differences, palettes, rank correlation, dots."""
import os
import tempfile
import unittest

import numpy as np
from PIL import Image, ImageDraw

from checks import dots, images, synth
from checks.geometry import Layout
from runner import svg_raster
from runner.experiment import Experiment
from runner.prepare import prepare

LAB = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRACELET = os.path.join(LAB, "..", "..", "..", "src", "assets", "music-theory-ga", "l2-bracelet-major.svg")


class ImageChecksTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()

    def tearDown(self):
        self.tmp.cleanup()

    def path(self, name):
        return os.path.join(self.tmp.name, name)

    @unittest.skipUnless(os.path.isfile(BRACELET), "music theory course assets not present")
    def test_bracelet_rasterizes_and_reads_back(self):
        image = svg_raster.rasterize(BRACELET, 460)
        self.assertEqual(image.size, (460, 460))
        a = np.asarray(image)
        # position 0 (filled, accent #3b2d99) at (115, 45) and position 1 (empty, white) at (150, 54.38), scale 2
        self.assertLess(int(a[90, 230].sum()), 300)
        self.assertGreater(int(a[109, 300].sum()), 700)
        image.save(self.path("b.png"))
        circles = svg_raster.circles(BRACELET)
        self.assertEqual(sum(1 for c in circles if c[2] < 12 and c[3]), 7)
        r = images.bracelet_readback(self.path("b.png"), circles, 230)
        self.assertTrue(r["exact"], r)
        self.assertEqual(r["polarity"], "dark")
        # the same image inverted still reads back, as bright positions
        Image.fromarray(255 - a).save(self.path("inv.png"))
        r = images.bracelet_readback(self.path("inv.png"), circles, 230)
        self.assertTrue(r["exact"], r)
        self.assertEqual(r["polarity"], "bright")

    def test_unsupported_svg_fails_loudly(self):
        with open(self.path("p.svg"), "w") as f:
            f.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><path d="M0 0"/></svg>')
        with self.assertRaises(ValueError):
            svg_raster.rasterize(self.path("p.svg"), 32)

    def test_seam_ratio(self):
        rng = np.random.default_rng(1)
        x = np.linspace(0, 2 * np.pi, 256, endpoint=False)
        wave = (127 + 100 * np.sin(x))[None, :, None] * np.ones((256, 1, 3))  # wraps exactly
        Image.fromarray((wave + rng.normal(0, 2, wave.shape)).clip(0, 255).astype(np.uint8)).save(self.path("t.png"))
        ramp = np.linspace(0, 255, 256)[None, :, None] * np.ones((256, 1, 3))  # jumps from 255 back to 0
        Image.fromarray(ramp.astype(np.uint8)).save(self.path("r.png"))
        tile, jump = images.seam_ratio(self.path("t.png")), images.seam_ratio(self.path("r.png"))
        self.assertLess(tile["seam_ratio_x"], 1.5)
        self.assertGreater(jump["seam_ratio_x"], 50)

    def test_pixel_diff_and_palette(self):
        a = Image.new("RGB", (100, 100), (10, 10, 10))
        b = a.copy()
        ImageDraw.Draw(b).rectangle([0, 0, 49, 99], fill=(30, 10, 10))
        a.save(self.path("a.png"))
        b.save(self.path("b.png"))
        d = images.pixel_diff(self.path("a.png"), self.path("b.png"))
        self.assertEqual(d["share_above"], 0.5)
        self.assertEqual(images.palette_size(self.path("a.png"))["palette_size"], 1)
        self.assertEqual(images.palette_size(self.path("b.png"))["palette_size"], 2)

    def test_spearman(self):
        self.assertAlmostEqual(images.spearman([1, 2, 3, 4], [10, 20, 30, 40]), 1.0)
        self.assertAlmostEqual(images.spearman([1, 2, 3, 4], [4, 3, 2, 1]), -1.0)
        self.assertAlmostEqual(images.spearman([1, 2, 3], [5, 5, 6]), 0.866, places=3)

    def test_inlay_mask_matches_geometry(self):
        exp_path = self.path("e.json")
        with open(exp_path, "w") as f:
            f.write('{"id": "m", "title": "t", "written": "2026-09-16", "hypothesis": "h", "prediction": "p",'
                    ' "workflow": "w.json", "seeds": [1], "seed_paths": []}')
        exp = Experiment(exp_path)
        out = prepare(exp, {"name": "inlays", "kind": "inlay_mask", "fret_start": 0, "fret_end": 12,
                            "width": 1344, "height": 768}, self.tmp.name)
        with Image.open(out) as im:
            mask = np.asarray(im.convert("L"))
        layout = Layout(0, 12, 1344, 768)
        for x, y, _ in layout.inlays():
            self.assertEqual(mask[y, x], 255)
        self.assertEqual(mask[layout.string_y(0), round(layout.wire_x(1)) - 10], 0)
        self.assertLess((mask > 0).mean(), 0.05)


class DotsTest(unittest.TestCase):
    def test_match_is_one_to_one(self):
        pairs, missed, extra = dots.match([(0, 0), (10, 0)], [(1, 0, 1.0), (2, 0, 1.0), (50, 50, 1.0)], 5)
        self.assertEqual(len(pairs), 1)
        self.assertEqual(missed, [(10, 0)])
        self.assertEqual(len(extra), 2)

    def test_white_dots_on_a_clean_neck(self):
        layout = Layout(0, 5, 768, 432)
        image = Image.new("RGB", (768, 432), (60, 38, 25))
        draw = ImageDraw.Draw(image)
        for f in range(1, 6):
            x = round(layout.wire_x(f))
            draw.rectangle([x - 1, layout.top, x + 1, layout.bottom], fill=(180, 180, 175))
        for s in range(6):
            y = layout.string_y(s)
            draw.line([layout.left, y, layout.right, y], fill=(200, 200, 190), width=2)
        expected = layout.dots("133211")
        for x, y in expected:
            r = layout.radius
            draw.ellipse([x - r, y - r, x + r, y + r], fill=(245, 245, 240))
        result = dots.check_against_map(image, "F", 0, 5)
        self.assertTrue(result["exact"], result)

    def test_synthetic_sample_is_deterministic(self):
        a, b = synth.sample(5, "combined"), synth.sample(5, "combined")
        self.assertEqual(a["expected"], b["expected"])
        self.assertTrue(np.array_equal(np.asarray(a["image"]), np.asarray(b["image"])))


if __name__ == "__main__":
    unittest.main()
