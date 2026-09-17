import os
import sys
import unittest

import numpy as np

# the portable build's embedded Python doesn't put the script's folder on sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import maps  # noqa: E402


class NormalMapTests(unittest.TestCase):
    def test_flat_image_points_straight_out(self):
        n = maps.normal_map(np.full((8, 8, 3), 0.5))
        self.assertTrue(np.allclose(n, [0.5, 0.5, 1.0]))

    def test_brighter_to_the_right_tilts_left(self):
        # height grows with x, so the surface faces towards -x: red below 0.5
        x = np.linspace(0, 1, 16, endpoint=False)
        rgb = np.repeat(np.tile(x, (16, 1))[..., None], 3, axis=-1)
        n = maps.normal_map(rgb, strength=4.0, blur=0)
        self.assertLess(n[8, 8, 0], 0.5)
        self.assertAlmostEqual(n[8, 8, 1], 0.5)

    def test_brighter_upwards_tilts_down_in_green(self):
        # rows grow downwards: brighter at the top means height grows upwards, green below 0.5
        y = np.linspace(1, 0, 16, endpoint=False)
        rgb = np.repeat(np.tile(y[:, None], (1, 16))[..., None], 3, axis=-1)
        n = maps.normal_map(rgb, strength=4.0, blur=0)
        self.assertLess(n[8, 8, 1], 0.5)

    def test_maps_of_a_shifted_texture_are_the_shifted_maps(self):
        # this is what makes the maps of a tileable texture tile
        rgb = maps.pattern(32)
        shifted = np.roll(rgb, (5, 11), axis=(0, 1))
        self.assertTrue(np.allclose(np.roll(maps.normal_map(rgb), (5, 11), axis=(0, 1)), maps.normal_map(shifted)))
        self.assertTrue(np.allclose(np.roll(maps.roughness_map(rgb), (5, 11), axis=(0, 1)), maps.roughness_map(shifted)))


class RoughnessAndSeamTests(unittest.TestCase):
    def test_roughness_spans_the_range(self):
        r = maps.roughness_map(maps.pattern(32), 0.45, 0.9)
        self.assertAlmostEqual(r.min(), 0.45)
        self.assertAlmostEqual(r.max(), 0.9)

    def test_the_pattern_tiles_and_its_offset_shows_no_seam_in_the_middle(self):
        report = maps.seam_report(maps.pattern(64))
        self.assertLess(report["wrap column"], report["typical column"] * 1.5)

    def test_a_hard_edge_shows_in_the_middle(self):
        rgb = np.zeros((16, 16, 3))
        rgb[:, 8:] = 1.0
        report = maps.seam_report(rgb)
        self.assertAlmostEqual(report["middle column"], 255.0)


if __name__ == "__main__":
    unittest.main()
