"""Geometry of a pitch-class bracelet.

The bracelet is a bangle: a band whose twelve positions carry the pitch classes, with a bead where the set has a note,
a thin rib where it has none, and a keel on pitch class 0 so the wearer can find C without counting. The positions use
the same convention as the bracelet of prototype 2 (``code/ga-protos/p2-chord-universe/src/app/scene.ts``, method
``beadPosition``): pitch class 0 at the top, clockwise seen from the front, ``angle = pi/2 - pc * pi/6``.

Nothing here decides which pitch classes are in the set: that comes from GA, through ``data/ga-sets.json``.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np
import trimesh

# --- the design, in millimetres -------------------------------------------------------------------------------------

INNER_DIAMETER = 65.0
WALL = 2.0
HEIGHT = 12.0
SEGMENTS = 192

INNER_R = INNER_DIAMETER / 2.0
OUTER_R = INNER_R + WALL

BEAD_R = 3.0
BEAD_EMBED = 0.4          # how far the cone's base plane sits inside the wall, so its rim is in the solid
RIB_WIDTH = 1.2
RIB_OUT = 0.8
RIB_EMBED = 0.6
KEEL_WIDTH = 2.5
KEEL_OUT = 1.6
KEEL_EMBED = 0.6
# The keel's ramp at each end, in millimetres of height. Zero, in the end: a vertical feature on a vertical wall,
# printed with the bangle's axis up, hangs over nothing at all, so the ramp only cost readability. Lesson 5 measures
# 1.6 (a 36 degree overhang, which the slicer would support), 2.2 (45 degrees) and 0.
KEEL_CHAMFER = 0.0

BEAD_SHAPES = ("sphere", "cone")


def position_angle(pc: int) -> float:
    """The angle of a pitch class on the bracelet, in radians. Same formula as P2's ``beadPosition``."""
    return math.pi / 2.0 - pc * math.pi / 6.0


def _place(mesh: trimesh.Trimesh, angle: float) -> trimesh.Trimesh:
    """Rotate a feature built along +X onto its position on the band."""
    mesh.apply_transform(trimesh.transformations.rotation_matrix(angle, [0, 0, 1]))
    return mesh


def _band() -> trimesh.Trimesh:
    band = trimesh.creation.annulus(r_min=INNER_R, r_max=OUTER_R, height=HEIGHT, sections=SEGMENTS)
    band.apply_translation([0, 0, HEIGHT / 2.0])
    return band


def _bead(shape: str) -> trimesh.Trimesh:
    if shape == "sphere":
        # Centred on the outer surface: half of it sticks out, and its lower half is an overhang.
        bead = trimesh.creation.icosphere(subdivisions=3, radius=BEAD_R)
        bead.apply_translation([OUTER_R, 0, HEIGHT / 2.0])
        return bead
    if shape == "cone":
        # Equal height and base radius, so every face of the cone is at 45 degrees: self-supporting.
        bead = trimesh.creation.cone(radius=BEAD_R, height=BEAD_R, sections=64)
        bead.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2.0, [0, 1, 0]))
        bead.apply_translation([OUTER_R - BEAD_EMBED, 0, HEIGHT / 2.0])
        return bead
    raise ValueError(f"unknown bead shape {shape!r}")


def _rib() -> trimesh.Trimesh:
    depth = RIB_EMBED + RIB_OUT
    rib = trimesh.creation.box(extents=[depth, RIB_WIDTH, HEIGHT])
    rib.apply_translation([OUTER_R - RIB_EMBED + depth / 2.0, 0, HEIGHT / 2.0])
    return rib


def _keel() -> trimesh.Trimesh:
    """A vertical wedge on pitch class 0, chamfered at 45 degrees top and bottom so it needs no support."""
    from shapely.geometry import Polygon

    x0 = OUTER_R - KEEL_EMBED
    x1 = OUTER_R + KEEL_OUT
    chamfer = min(KEEL_CHAMFER, HEIGHT / 2.0)
    profile = Polygon([(x0, 0.0), (x1, chamfer), (x1, HEIGHT - chamfer), (x0, HEIGHT)]) if chamfer > 0 else \
        Polygon([(x0, 0.0), (x1, 0.0), (x1, HEIGHT), (x0, HEIGHT)])
    keel = trimesh.creation.extrude_polygon(profile, height=KEEL_WIDTH)
    # extrude_polygon works in the XY plane and extrudes along Z; turn (x, z) into (x, y, z)
    keel.apply_transform(trimesh.transformations.rotation_matrix(math.pi / 2.0, [1, 0, 0]))
    keel.apply_translation([0, KEEL_WIDTH / 2.0, 0])
    return keel


@dataclass
class Bracelet:
    """One bracelet: a pitch-class set, a bead shape, and the meshes built from them."""

    name: str
    pitch_classes: tuple[int, ...]
    bead_shape: str = "cone"
    parts: list[trimesh.Trimesh] = field(default_factory=list)

    def __post_init__(self) -> None:
        if self.bead_shape not in BEAD_SHAPES:
            raise ValueError(f"unknown bead shape {self.bead_shape!r}")
        if not self.pitch_classes or any(pc < 0 or pc > 11 for pc in self.pitch_classes):
            raise ValueError(f"bad pitch classes {self.pitch_classes!r}")
        members = set(self.pitch_classes)
        self.parts = [_band()]
        for pc in range(12):
            feature = _bead(self.bead_shape) if pc in members else _rib()
            self.parts.append(_place(feature, position_angle(pc)))
        self.parts.append(_place(_keel(), position_angle(0)))

    def naive(self) -> trimesh.Trimesh:
        """Every part in one file, with no boolean at all: what a script without a CSG engine writes."""
        return trimesh.util.concatenate([p.copy() for p in self.parts])

    def solid(self) -> trimesh.Trimesh:
        """The boolean union, computed by manifold3d."""
        return trimesh.boolean.union([p.copy() for p in self.parts], engine="manifold")


def pla_mass_g(volume_mm3: float, density_g_cm3: float = 1.24) -> float:
    """Mass of a solid print, from the mesh volume. 1.24 g/cm3 is the usual figure for PLA."""
    return volume_mm3 / 1000.0 * density_g_cm3


def radii(mesh: trimesh.Trimesh) -> np.ndarray:
    """Distance of every vertex from the bracelet's axis."""
    return np.hypot(mesh.vertices[:, 0], mesh.vertices[:, 1])
