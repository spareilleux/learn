"""What can be measured on a mesh without owning a printer.

Everything here answers a question a slicer would otherwise answer, or a question the slicer never asks and the wearer
does: is the solid closed, how much plastic is in it, how thin is the thinnest wall, does the wrist still fit, and how
much of the surface hangs over nothing.
"""

from __future__ import annotations

import math
from dataclasses import asdict, dataclass

import numpy as np
import trimesh

from bracelet import HEIGHT, INNER_R, pla_mass_g, radii


@dataclass
class Topology:
    watertight: bool
    winding_consistent: bool
    is_volume: bool
    bodies: int
    euler_number: int
    genus: float | None
    vertices: int
    faces: int
    degenerate_faces: int
    duplicate_faces: int
    manifold3d_status: str


@dataclass
class Solidity:
    volume_cm3: float
    area_cm2: float
    pla_mass_g: float
    bbox_mm: list[float]


@dataclass
class Fit:
    min_vertex_radius_mm: float
    min_surface_radius_mm: float
    inner_diameter_mm: float
    faceting_loss_mm: float
    height_mm: float


@dataclass
class Walls:
    rays: int
    misses: int
    min_mm: float
    p5_mm: float
    median_mm: float
    min_away_from_features_mm: float


@dataclass
class Overhangs:
    total_area_cm2: float
    bed_area_cm2: float
    steep_area_cm2: float
    steep_fraction: float
    min_slope_deg: float
    threshold_deg: float


def topology(mesh: trimesh.Trimesh) -> Topology:
    bodies = len(mesh.split(only_watertight=False))
    euler = int(mesh.euler_number)
    genus = (2 - euler / max(bodies, 1)) / 2 if mesh.is_watertight else None
    status = _manifold_status(mesh)
    areas = mesh.area_faces
    unique = len({tuple(sorted(face)) for face in mesh.faces})
    return Topology(
        watertight=bool(mesh.is_watertight),
        winding_consistent=bool(mesh.is_winding_consistent),
        is_volume=bool(mesh.is_volume),
        bodies=bodies,
        euler_number=euler,
        genus=genus,
        vertices=len(mesh.vertices),
        faces=len(mesh.faces),
        degenerate_faces=int(np.count_nonzero(areas <= 1e-12)),
        duplicate_faces=len(mesh.faces) - unique,
        manifold3d_status=status,
    )


def _manifold_status(mesh: trimesh.Trimesh) -> str:
    """manifold3d refuses a mesh a 3D printer would refuse; its verdict is stricter than trimesh's."""
    try:
        import manifold3d
    except ImportError:  # pragma: no cover - manifold3d is a hard dependency of this prototype
        return "manifold3d missing"
    try:
        m = manifold3d.Manifold(
            manifold3d.Mesh(
                vert_properties=np.asarray(mesh.vertices, dtype=np.float32),
                tri_verts=np.asarray(mesh.faces, dtype=np.uint32),
            )
        )
    except Exception as exc:  # noqa: BLE001 - the message is the measurement
        return f"rejected: {type(exc).__name__}"
    return "NoError" if m.num_tri() > 0 and not m.is_empty() else "empty"


def solidity(mesh: trimesh.Trimesh) -> Solidity:
    volume = float(mesh.volume)
    return Solidity(
        volume_cm3=round(volume / 1000.0, 4),
        area_cm2=round(float(mesh.area) / 100.0, 4),
        pla_mass_g=round(pla_mass_g(volume), 3),
        bbox_mm=[round(float(v), 3) for v in mesh.extents],
    )


def fit(mesh: trimesh.Trimesh) -> Fit:
    """How much of the 65 mm the wrist actually gets, once the circle is a 192-sided polygon."""
    r = radii(mesh)
    min_vertex = float(r.min())
    # The surface of a polygonal cylinder is closest to the axis at the middle of an edge, never at a vertex.
    edges = mesh.vertices[mesh.edges_unique]
    mid = edges.mean(axis=1)
    min_surface = float(np.hypot(mid[:, 0], mid[:, 1]).min())
    return Fit(
        min_vertex_radius_mm=round(min_vertex, 4),
        min_surface_radius_mm=round(min_surface, 4),
        inner_diameter_mm=round(2 * min_surface, 4),
        faceting_loss_mm=round(INNER_R - min_surface, 5),
        height_mm=round(float(mesh.bounds[1][2] - mesh.bounds[0][2]), 4),
    )


def walls(mesh: trimesh.Trimesh, positions_deg: list[float], rays: int = 2000, seed: int = 5) -> Walls:
    """Fire rays outwards from inside the wall and see where they leave the solid: that distance is the thickness."""
    rng = np.random.default_rng(seed)
    theta = rng.uniform(0.0, 2 * math.pi, rays)
    z = rng.uniform(0.5, HEIGHT - 0.5, rays)
    start_r = INNER_R + 0.01
    origins = np.column_stack([start_r * np.cos(theta), start_r * np.sin(theta), z])
    directions = np.column_stack([np.cos(theta), np.sin(theta), np.zeros(rays)])
    locations, index_ray, _ = mesh.ray.intersects_location(origins, directions, multiple_hits=False)
    hit_r = np.hypot(locations[:, 0], locations[:, 1])
    thickness = hit_r - INNER_R
    order = np.argsort(index_ray)
    thickness, hit_rays = thickness[order], index_ray[order]
    # A ray that leaves through a bead or a rib measures more than the band: keep the band-only rays apart.
    angles = np.degrees(theta[hit_rays]) % 360.0
    away = np.ones(len(hit_rays), dtype=bool)
    for p in positions_deg:
        delta = np.abs((angles - p + 180.0) % 360.0 - 180.0)
        away &= delta > 6.0
    return Walls(
        rays=rays,
        misses=rays - len(hit_rays),
        min_mm=round(float(thickness.min()), 4),
        p5_mm=round(float(np.percentile(thickness, 5)), 4),
        median_mm=round(float(np.median(thickness)), 4),
        min_away_from_features_mm=round(float(thickness[away].min()), 4) if away.any() else float("nan"),
    )


def overhangs(mesh: trimesh.Trimesh, threshold_deg: float = 45.0, bed_eps: float = 0.01) -> Overhangs:
    """Downward-facing area, bed contact excluded.

    The angle reported is the *slope* of a face, which is PrusaSlicer's convention for its support threshold: the angle
    between the face and the horizontal plane, equal to the angle between the face's normal and -Z. A vertical wall is
    90 degrees and needs nothing; a ceiling facing the bed is 0 degrees and needs everything. Faces below the threshold
    are the ones a slicer would support, and ``min_slope_deg`` is the worst overhang anywhere on the object.
    """
    normals = mesh.face_normals
    areas = mesh.area_faces
    angle = np.degrees(np.arccos(np.clip(-normals[:, 2], -1.0, 1.0)))
    z = mesh.vertices[mesh.faces][:, :, 2]
    on_bed = z.max(axis=1) <= mesh.bounds[0][2] + bed_eps
    steep = (angle < threshold_deg) & ~on_bed
    return Overhangs(
        total_area_cm2=round(float(areas.sum()) / 100.0, 4),
        bed_area_cm2=round(float(areas[on_bed].sum()) / 100.0, 4),
        steep_area_cm2=round(float(areas[steep].sum()) / 100.0, 4),
        steep_fraction=round(float(areas[steep].sum() / areas.sum()), 6),
        min_slope_deg=round(float(angle[~on_bed].min()), 3) if (~on_bed).any() else float("nan"),
        threshold_deg=threshold_deg,
    )


def measure_all(mesh: trimesh.Trimesh, positions_deg: list[float]) -> dict:
    out = {"topology": asdict(topology(mesh)), "solidity": asdict(solidity(mesh)), "fit": asdict(fit(mesh))}
    if mesh.is_watertight:
        out["walls"] = asdict(walls(mesh, positions_deg))
    out["overhangs"] = asdict(overhangs(mesh))
    return out


__all__ = ["measure_all", "topology", "solidity", "fit", "walls", "overhangs"]
