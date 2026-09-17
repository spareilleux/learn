"""The checks that must hold on every machine, without a printer and without a slicer.

Run them with ``python -m unittest discover -s tests -t .`` from the prototype's folder.
"""

from __future__ import annotations

import math
import sys
import unittest
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "mesh"))

from bracelet import HEIGHT, INNER_R, OUTER_R, Bracelet, position_angle  # noqa: E402
from measure import fit, overhangs, topology, walls  # noqa: E402
from sets import by_id, resolve, spell  # noqa: E402

POSITIONS_DEG = [math.degrees(position_angle(pc)) % 360.0 for pc in range(12)]


class PitchClassOrder(unittest.TestCase):
    """The bracelet must read the way GA and the rest of the site read it, or it is jewellery and not a diagram."""

    def test_positions_match_prototype_2(self):
        # code/ga-protos/p2-chord-universe/src/app/scene.ts, beadPosition: angle = pi/2 - pc * pi/6
        for pc in range(12):
            self.assertAlmostEqual(position_angle(pc), math.pi / 2 - pc * math.pi / 6, places=12)

    def test_c_is_at_the_top_and_the_order_is_clockwise(self):
        self.assertAlmostEqual(POSITIONS_DEG[0], 90.0)
        self.assertAlmostEqual(POSITIONS_DEG[3], 0.0)      # D# a quarter turn clockwise
        self.assertAlmostEqual(POSITIONS_DEG[6], 270.0)    # F# opposite C, a tritone away
        self.assertAlmostEqual(POSITIONS_DEG[9], 180.0)

    def test_every_position_is_thirty_degrees_from_the_next(self):
        for pc in range(12):
            gap = (POSITIONS_DEG[pc] - POSITIONS_DEG[(pc + 1) % 12]) % 360.0
            self.assertAlmostEqual(gap, 30.0)


class GaSets(unittest.TestCase):
    def test_the_catalog_is_there(self):
        self.assertGreater(len(by_id()), 50)

    def test_a_few_sets_gas_own_way(self):
        self.assertEqual(resolve("C major-triad"), (0, 4, 7))
        self.assertEqual(resolve("C diminished-7"), (0, 3, 6, 9))
        self.assertEqual(resolve("C half-diminished-7"), (0, 3, 6, 10))
        self.assertEqual(resolve("C Major"), (0, 2, 4, 5, 7, 9, 11))
        self.assertEqual(resolve("A Minor.Natural"), (0, 2, 4, 5, 7, 9, 11))
        self.assertEqual(spell(resolve("C major-7")), "C E G B")

    def test_transposition_keeps_the_shape(self):
        for root in ("C", "F#", "Bb", "Eb"):
            pcs = resolve(f"{root} dominant-7")
            gaps = sorted((b - a) % 12 for a, b in zip(pcs, pcs[1:] + pcs[:1]))
            self.assertEqual(gaps, sorted((4, 3, 3, 2)))


class MeshValidity(unittest.TestCase):
    """The prototype's whole claim: the union is one closed solid a slicer can read."""

    @classmethod
    def setUpClass(cls):
        cls.solid = Bracelet("C major-triad", resolve("C major-triad"), "cone").solid()
        cls.parts = Bracelet("C major-triad", resolve("C major-triad"), "cone").naive()

    def test_the_union_is_one_closed_solid(self):
        t = topology(self.solid)
        self.assertTrue(t.watertight)
        self.assertTrue(t.winding_consistent)
        self.assertTrue(t.is_volume)
        self.assertEqual(t.bodies, 1)
        self.assertEqual(t.euler_number, 0)     # a bangle is a torus: genus 1
        self.assertEqual(t.manifold3d_status, "NoError")

    def test_the_parts_merely_stacked_are_not_one_solid(self):
        t = topology(self.parts)
        self.assertEqual(t.bodies, 14)          # the band, twelve positions, the keel
        self.assertGreater(self.parts.volume, self.solid.volume)

    def test_the_bore_is_not_eaten_into(self):
        f = fit(self.solid)
        self.assertGreaterEqual(f.inner_diameter_mm, 64.98)
        self.assertLess(f.faceting_loss_mm, 0.02)
        self.assertAlmostEqual(f.height_mm, HEIGHT, places=6)

    def test_the_band_keeps_its_two_millimetres(self):
        w = walls(self.solid, POSITIONS_DEG, rays=600)
        self.assertEqual(w.misses, 0)
        self.assertGreater(w.min_mm, 1.99)
        self.assertAlmostEqual(w.min_away_from_features_mm, 2.0, delta=0.01)

    def test_nothing_hangs_over_nothing(self):
        o = overhangs(self.solid)
        self.assertEqual(o.steep_area_cm2, 0.0)
        self.assertGreaterEqual(o.min_slope_deg, 45.0)


class Readability(unittest.TestCase):
    """A bead where GA puts a note, a rib where it does not, and the keel on C, measured on the mesh itself."""

    @classmethod
    def setUpClass(cls):
        cls.pcs = resolve("C dominant-7")
        cls.solid = Bracelet("C dominant-7", cls.pcs, "cone").solid()

    def outer_radius_at(self, degrees: float, z: float) -> float:
        """How far the surface reaches at one angle: a ray from the axis outwards, last hit."""
        a = math.radians(degrees)
        origin = np.array([[0.0, 0.0, z]])
        direction = np.array([[math.cos(a), math.sin(a), 0.0]])
        hits, _, _ = self.solid.ray.intersects_location(origin, direction, multiple_hits=True)
        return float(np.hypot(hits[:, 0], hits[:, 1]).max())

    def test_a_bead_stands_where_the_chord_has_a_note(self):
        for pc in range(12):
            r = self.outer_radius_at(POSITIONS_DEG[pc], HEIGHT / 2)
            if pc in self.pcs:
                self.assertGreater(r, OUTER_R + 2.0, f"no bead on pitch class {pc}")
            else:
                self.assertLess(r, OUTER_R + 1.0, f"something stands on pitch class {pc}, which is not in the chord")

    def test_the_keel_marks_c_over_the_whole_height(self):
        # Away from mid-height, where the beads are, only the keel still sticks out more than a rib -- and it does so
        # at 1 mm from the bed as well as at mid-height, which is exactly what the 45 degree ramp used to spoil.
        for z in (0.5, 1.0, 2.0, HEIGHT - 2.0, HEIGHT - 0.5):
            tall = [pc for pc in range(12) if self.outer_radius_at(POSITIONS_DEG[pc], z) > OUTER_R + 1.0]
            self.assertEqual(tall, [0], f"at z = {z} mm the keel is not the only tall feature")

    def test_the_bore_is_smooth(self):
        for pc in range(12):
            a = math.radians(POSITIONS_DEG[pc])
            origin = np.array([[0.0, 0.0, HEIGHT / 2]])
            direction = np.array([[math.cos(a), math.sin(a), 0.0]])
            hits, _, _ = self.solid.ray.intersects_location(origin, direction, multiple_hits=True)
            self.assertAlmostEqual(float(np.hypot(hits[:, 0], hits[:, 1]).min()), INNER_R, delta=0.01)


if __name__ == "__main__":
    unittest.main()
