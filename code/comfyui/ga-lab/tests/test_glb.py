"""The .glb reader on boxes built in Python: counts, bounding box, materials, and the topology measures."""
import io
import json
import os
import struct
import tempfile
import unittest

import numpy as np
from PIL import Image

from runner import glb

FIXTURE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures", "cube.glb")


def fixture_bytes():
    """tests/fixtures/cube.glb: a 2 x 1 x 0.5 box with split vertices (24, as exporters write hard edges) and a
    material, the file L2's Blender pipeline can also read. Written by: python -m tests.test_glb write-fixture"""
    positions, triangles = glb.cube((2.0, 1.0, 0.5), welded=False)
    return glb.build_glb(positions, triangles, material=True)


class GlbReaderTest(unittest.TestCase):
    def test_fixture_is_the_generated_cube(self):
        with open(FIXTURE, "rb") as f:
            self.assertEqual(f.read(), fixture_bytes())

    def test_closed_box(self):
        r = glb.inspect(FIXTURE)
        self.assertEqual((r["triangles"], r["vertices"], r["primitives"], r["materials"]), (12, 24, 1, 1))
        self.assertEqual((r["textures"], r["images"]), (0, 0))
        self.assertEqual(r["bbox"]["extents"], [2.0, 1.0, 0.5])
        self.assertEqual(r["bbox"]["sorted_ratios"], [1.0, 0.5, 0.25])
        t = r["topology"]
        self.assertEqual(t["welded_vertices"], 8)  # 24 split corners weld to 8
        self.assertEqual((t["edges"], t["boundary_edges"], t["nonmanifold_edges"]), (18, 0, 0))
        self.assertTrue(t["watertight"])
        self.assertEqual((t["components"], t["euler"], t["inconsistent_edges"], t["degenerate"]), (1, 2, 0, 0))

    def test_open_box_has_a_boundary(self):
        positions, triangles = glb.cube()
        t = glb.inspect_bytes(glb.build_glb(positions, triangles[:2] + triangles[4:]))["topology"]
        self.assertFalse(t["watertight"])
        self.assertEqual((t["boundary_edges"], t["euler"]), (4, 1))

    def test_flipped_triangle_and_extra_fin(self):
        positions, triangles = glb.cube()
        flipped = [triangles[0][::-1]] + triangles[1:]
        t = glb.inspect_bytes(glb.build_glb(positions, flipped))["topology"]
        self.assertTrue(t["watertight"])  # still closed, but three edges walked twice the same way
        self.assertEqual(t["inconsistent_edges"], 3)
        fin = glb.inspect_bytes(glb.build_glb(positions + [(0.0, 0.0, 3.0)], triangles + [(0, 1, 8)]))["topology"]
        self.assertEqual(fin["nonmanifold_edges"], 1)
        self.assertFalse(fin["watertight"])

    def test_two_boxes_are_two_components_and_uint16_indices(self):
        p1, t1 = glb.cube()
        p2 = [(x + 5, y, z) for x, y, z in p1]
        t2 = [(a + 8, b + 8, c + 8) for a, b, c in t1]
        r = glb.inspect_bytes(glb.build_glb(p1 + p2, t1 + t2, index_type=5123))
        self.assertEqual(r["topology"]["components"], 2)
        self.assertEqual(r["bbox"]["extents"], [6.0, 1.0, 1.0])

    def test_texture_and_vertex_colors(self):
        buf = io.BytesIO()
        Image.new("RGB", (4, 4), (180, 120, 60)).save(buf, "PNG")
        positions, triangles = glb.cube()
        r = glb.inspect_bytes(glb.build_glb(positions, triangles, texture_png=buf.getvalue(), colors=[(1, 0, 0)] * 8))
        self.assertEqual((r["materials"], r["textures"], r["images"]), (1, 1, 1))
        self.assertTrue(r["has_vertex_colors"])
        self.assertIn("COLOR_0", r["attributes"])

    def test_node_transform_is_applied(self):
        positions, triangles = glb.cube()
        data = bytearray(glb.build_glb(positions, triangles))
        size = struct.unpack_from("<I", data, 12)[0]
        doc = json.loads(bytes(data[20:20 + size]))
        doc["nodes"][0]["scale"] = [3.0, 1.0, 1.0]
        doc["nodes"][0]["rotation"] = [0.0, 0.0, 0.7071068, 0.7071068]  # 90 degrees about Z: x becomes y
        text = json.dumps(doc, separators=(",", ":")).encode()
        text += b" " * (-len(text) % 4)
        rest = bytes(data[20 + size:])
        rebuilt = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(text) + len(rest)) + \
            struct.pack("<II", len(text), glb.JSON_CHUNK) + text + rest
        self.assertEqual(glb.inspect_bytes(rebuilt)["bbox"]["extents"], [1.0, 3.0, 1.0])

    def test_not_a_glb(self):
        with self.assertRaises(glb.GlbError):
            glb.inspect_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 32)
        with self.assertRaises(glb.GlbError):
            glb.inspect_bytes(fixture_bytes()[:40])

    def test_components_match_a_plain_union_find(self):
        rng = np.random.default_rng(3)
        for _ in range(20):
            n = int(rng.integers(2, 200))
            edges = rng.integers(0, n, (int(rng.integers(0, 250)), 2))
            parent = list(range(n))

            def find(a):
                while parent[a] != a:
                    parent[a] = parent[parent[a]]
                    a = parent[a]
                return a

            for a, b in edges.tolist():
                parent[find(a)] = find(b)
            self.assertEqual(len(np.unique(glb.components_labels(n, edges))), len({find(v) for v in range(n)}))

    def test_preview_is_a_webp(self):
        with tempfile.TemporaryDirectory() as tmp:
            dst = glb.preview(fixture_bytes(), os.path.join(tmp, "cube.webp"))
            with Image.open(dst) as image:
                self.assertEqual((image.format, image.size), ("WEBP", (256, 256)))
                self.assertGreater(len(image.convert("L").getcolors()), 3)  # shaded faces, not a blank square


if __name__ == "__main__":
    import sys
    if sys.argv[1:] == ["write-fixture"]:
        os.makedirs(os.path.dirname(FIXTURE), exist_ok=True)
        with open(FIXTURE, "wb") as f:
            f.write(fixture_bytes())
        print(FIXTURE)
    else:
        unittest.main()
